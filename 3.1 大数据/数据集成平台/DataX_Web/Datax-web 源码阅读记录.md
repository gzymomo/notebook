- [Datax-web 源码阅读记录_终回首的博客-CSDN博客](https://blog.csdn.net/qq_39945938/article/details/118972382)

# 一、Datax-web简介

DataX Web是在DataX之上开发的开源分布式数据同步工具，提供简单易用的 操作界面，降低用户使用DataX的学习成本，缩短任务配置时间，避免配置过程中出错。

Datax Web基于xxl-job；Datax Web核心是拼接Datax的json、执行Datax脚本部分代码。

## 项目地址

Datax-web https://gitee.com/WeiYe-Jing/datax-web

Datax-web https://github.com/alibaba/DataX

## 软件版本：

Datax 3.0

Datax-web 2.1.2

commit信息

```git
commit f0aac36b6f3c5c6182b8985bd0bcf1470201e92f (HEAD -> master, origin/master, origin/HEAD)
Author: WeiYe <33245094+WeiYe-Jing@users.noreply.github.com>
Date:   Tue Mar 23 21:42:58 2021 +0800

    Update README.md
```

## 框架版本：

Spring Boot 2.1.4.RELEASE

Mybatis Plus 3.3.1

# 二、源码阅读

按照调用顺序阅读

## 1 datax-admin（调度中心）启动 执行流程

### 1.1 调度中心启动类 DataXAdminApplication.main()

```java
    public static void main(String[] args) throws UnknownHostException {
        Environment env = new SpringApplication(DataXAdminApplication.class).run(args).getEnvironment();
        String envPort = env.getProperty("server.port");
        String envContext = env.getProperty("server.contextPath");
        // 配置文件，默认端口是8080
        String port = envPort == null ? "8080" : envPort;
        String context = envContext == null ? "" : envContext;
        String path = port + "" + context + "/doc.html";
        String externalAPI = InetAddress.getLocalHost().getHostAddress();
        // 打印3个url，第一个和第二个我这里打开是一样的都是swagger接口文档，第三个是页面的访问地址
        logger.info(
                "Access URLs:\n----------------------------------------------------------\n\t"
                        + "Local-API: \t\thttp://127.0.0.1:{}\n\t"
                        + "External-API: \thttp://{}:{}\n\t"
                        + "web-URL: \t\thttp://127.0.0.1:{}/index.html\n\t----------------------------------------------------------",
                path, externalAPI, path, port);
    }
```

### 1.2 配置类 JobAdminConfig.afterPropertiesSet()

读取配置文件，初始化bean时会自动调用afterPropertiesSet()初始化JobScheduler类。InitializingBean接口为bean提供了初始化方法的方式，它只包括afterPropertiesSet方法，凡是继承该接口的类，在初始化bean的时候会自动执行该方法。这个方法里初始化JobScheduler对象，同时调用init方法

```java
	@Override
    public void afterPropertiesSet() throws Exception {
        adminConfig = this;

        xxlJobScheduler = new JobScheduler();
        // 初始化任务调度器
        xxlJobScheduler.init();
    }
```

### 1.3 调度器初始化 JobScheduler.init()

```java
public void init() throws Exception {
        // 1 初始化页面国际化的工具
        initI18n();

        // 2 启动注册监控线程
        JobRegistryMonitorHelper.getInstance().start();

        // 3 启动失败监控线程
        JobFailMonitorHelper.getInstance().start();

        // 4 初始化触发线程池，创建快慢线程池
        JobTriggerPoolHelper.toStart();

        // 5 启动日志线程
        JobLogReportHelper.getInstance().start();

        // 6 启动作业调度器，这个类是主要逻辑.启动一个死循环，不断的遍历任务触发执行。为避免cpu飙升，隔一会睡一会(这里是重点)
        JobScheduleHelper.getInstance().start();

        logger.info(">>>>>>>>> init datax-web admin success.");
    }
```

### 1.5 调度器真正初始化 JobScheduleHelper.getInstance().start()

```java
public void start() {

        // 启动一个调度线程
        scheduleThread = new Thread(new Runnable() {
            @Override
            public void run() {

                try {
                	// 睡大约4秒
                    TimeUnit.MILLISECONDS.sleep(5000 - System.currentTimeMillis() % 1000);
                } catch (InterruptedException e) {
                    if (!scheduleThreadToStop) {
                        logger.error(e.getMessage(), e);
                    }
                }
                logger.info(">>>>>>>>> init datax-web admin scheduler success.");

                // 预读取数量，等于快线程池大小加慢线程池大小的和再乘以20，默认的话是（200+100）*20 = 6000
                int preReadCount = (JobAdminConfig.getAdminConfig().getTriggerPoolFastMax() + JobAdminConfig.getAdminConfig().getTriggerPoolSlowMax()) * 20;
				//死循环，进程退出时修改变量为true
                while (!scheduleThreadToStop) {

                    // 从数据库查询job
                    long start = System.currentTimeMillis();

                    Connection conn = null;
                    Boolean connAutoCommit = null;
                    PreparedStatement preparedStatement = null;

                    boolean preReadSuc = true;
                    try {

                        conn = JobAdminConfig.getAdminConfig().getDataSource().getConnection();
                        connAutoCommit = conn.getAutoCommit();
                        conn.setAutoCommit(false);
						// 获取一个悲观锁
                        preparedStatement = conn.prepareStatement("select * from job_lock where lock_name = 'schedule_lock' for update");
                        preparedStatement.execute();

                        // tx start

                        // 1、pre read
                        long nowTime = System.currentTimeMillis();
                        // 查询要执行的任务，如何判断要执行呢，即下次执行时间小于等于当前时间+5s
                        List<JobInfo> scheduleList = JobAdminConfig.getAdminConfig().getJobInfoMapper().scheduleJobQuery(nowTime + PRE_READ_MS, preReadCount);
                        if (scheduleList != null && scheduleList.size() > 0) {
                            // 2、push time-ring
                            for (JobInfo jobInfo : scheduleList) {

                                // 判断下次执行时间是否小于（nowTime-5s），如果为true说明任务还没到执行时间跳过此次执行，刷新下次执行时间
                                if (nowTime > jobInfo.getTriggerNextTime() + PRE_READ_MS) {
                                    // 2.1、trigger-expire > 5s：pass && make next-trigger-time
                                    logger.warn(">>>>>>>>>>> datax-web, schedule misfire, jobId = " + jobInfo.getId());

                                    // fresh next
                                    refreshNextValidTime(jobInfo, new Date());
								// 判断下次执行时间是否刚过去5s内，如果是，将任务添加到触发执行线程池，刷新下次执行时间；计算执行秒数；将秒和任务id添加到ringData；刷新下次执行时间
                                } else if (nowTime > jobInfo.getTriggerNextTime()) {
                                    // 2.2、trigger-expire < 5s：direct-trigger && make next-trigger-time

                                    // 触发任务
                                    JobTriggerPoolHelper.trigger(jobInfo.getId(), TriggerTypeEnum.CRON, -1, null, null);
                                    logger.debug(">>>>>>>>>>> datax-web, schedule push trigger : jobId = " + jobInfo.getId());

                                    // 刷新下次执行时间
                                    refreshNextValidTime(jobInfo, new Date());

                                    // next-trigger-time in 5s, pre-read again
                                    if (jobInfo.getTriggerStatus() == 1 && nowTime + PRE_READ_MS > jobInfo.getTriggerNextTime()) {

                                        // 1、make ring second
                                        int ringSecond = (int) ((jobInfo.getTriggerNextTime() / 1000) % 60);

                                        // 2、push time ring
                                        pushTimeRing(ringSecond, jobInfo.getId());

                                        // 3、fresh next
                                        refreshNextValidTime(jobInfo, new Date(jobInfo.getTriggerNextTime()));

                                    }

                                } else {
                                    // 2.3、trigger-pre-read：time-ring trigger && make next-trigger-time

                                    // 1、make ring second
                                    int ringSecond = (int) ((jobInfo.getTriggerNextTime() / 1000) % 60);

                                    // 2、push time ring
                                    pushTimeRing(ringSecond, jobInfo.getId());

                                    // 3、fresh next
                                    refreshNextValidTime(jobInfo, new Date(jobInfo.getTriggerNextTime()));

                                }

                            }

                            // 3、update trigger info
                            for (JobInfo jobInfo : scheduleList) {
                                JobAdminConfig.getAdminConfig().getJobInfoMapper().scheduleUpdate(jobInfo);
                            }

                        } else {
                            preReadSuc = false;
                        }

                        // tx stop


                    } catch (Exception e) {
                        if (!scheduleThreadToStop) {
                            logger.error(">>>>>>>>>>> datax-web, JobScheduleHelper#scheduleThread error:{}", e);
                        }
                    } finally {

                        // 手动提交修改，关闭连接
                        if (conn != null) {
                            try {
                                conn.commit();
                            } catch (SQLException e) {
                                if (!scheduleThreadToStop) {
                                    logger.error(e.getMessage(), e);
                                }
                            }
                            try {
                                conn.setAutoCommit(connAutoCommit);
                            } catch (SQLException e) {
                                if (!scheduleThreadToStop) {
                                    logger.error(e.getMessage(), e);
                                }
                            }
                            try {
                                conn.close();
                            } catch (SQLException e) {
                                if (!scheduleThreadToStop) {
                                    logger.error(e.getMessage(), e);
                                }
                            }
                        }

                        // close PreparedStatement
                        if (null != preparedStatement) {
                            try {
                                preparedStatement.close();
                            } catch (SQLException e) {
                                if (!scheduleThreadToStop) {
                                    logger.error(e.getMessage(), e);
                                }
                            }
                        }
                    }
                    long cost = System.currentTimeMillis() - start;


                    // Wait seconds, align second
                    if (cost < 1000) {  // 扫描时间超过1秒就不sleep，小于1秒才sleep
                        try {
                            // 如果前面预读成功，睡1秒，预读失败睡大约4秒
                            TimeUnit.MILLISECONDS.sleep((preReadSuc ? 1000 : PRE_READ_MS) - System.currentTimeMillis() % 1000);
                        } catch (InterruptedException e) {
                            if (!scheduleThreadToStop) {
                                logger.error(e.getMessage(), e);
                            }
                        }
                    }

                }

                logger.info(">>>>>>>>>>> datax-web, JobScheduleHelper#scheduleThread stop");
            }
        });
        // 设置守护进程
        scheduleThread.setDaemon(true);
        scheduleThread.setName("datax-web, admin JobScheduleHelper#scheduleThread");
        scheduleThread.start();


        // 启动处理之前加入到ringData中数据的线程（前面只是保存到ringData，这里是真正开始触发执行）
        ringThread = new Thread(() -> {

            // align second
            try {
            	// 睡(0~1)秒
                TimeUnit.MILLISECONDS.sleep(1000 - System.currentTimeMillis() % 1000);
            } catch (InterruptedException e) {
                if (!ringThreadToStop) {
                    logger.error(e.getMessage(), e);
                }
            }
			// 死循环，只有程序退出时才修改标志为true
            while (!ringThreadToStop) {

                try {
                    // second data
                    List<Integer> ringItemData = new ArrayList<>();
                    int nowSecond = Calendar.getInstance().get(Calendar.SECOND);   // 避免处理耗时太长，跨过刻度，向前校验一个刻度；
                    // 这里就是处理之前添加到ringData里的任务；前面存ringData时，key是秒（从1到60），value是由jobid组成的list；每次从ringData里取2秒的数据。
                    for (int i = 0; i < 2; i++) {
                        List<Integer> tmpData = ringData.remove((nowSecond + 60 - i) % 60);
                        if (tmpData != null) {
                            ringItemData.addAll(tmpData);
                        }
                    }

                    // ring trigger
                    logger.debug(">>>>>>>>>>> datax-web, time-ring beat : " + nowSecond + " = " + Arrays.asList(ringItemData));
                    if (ringItemData.size() > 0) {
                        // do trigger
                        for (int jobId : ringItemData) {
                            // 依次调用JobTriggerPoolHelper.trigger()触发任务
                            JobTriggerPoolHelper.trigger(jobId, TriggerTypeEnum.CRON, -1, null, null);
                        }
                        // 执行完后清空列表
                        ringItemData.clear();
                    }
                } catch (Exception e) {
                	// 打印非停止状态下的异常
                    if (!ringThreadToStop) {
                        logger.error(">>>>>>>>>>> datax-web, JobScheduleHelper#ringThread error:{}", e);
                    }
                }

                // 睡(0-1)秒
                try {
                    TimeUnit.MILLISECONDS.sleep(1000 - System.currentTimeMillis() % 1000);
                } catch (InterruptedException e) {
                    if (!ringThreadToStop) {
                        logger.error(e.getMessage(), e);
                    }
                }
            }
            logger.info(">>>>>>>>>>> datax-web, JobScheduleHelper#ringThread stop");
        });
        ringThread.setDaemon(true);
        ringThread.setName("datax-web, admin JobScheduleHelper#ringThread");
        ringThread.start();
    }
```

到这里调度中心就启动成功了，下面再看执行器的执行流程

## 2 datax-executor（执行器）启动 执行流程

### 2.1 启动类 DataXExecutorApplication

```java
package com.wugui.datax.executor;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * @author xuxueli 2018-10-28 00:38:13
 */
@SpringBootApplication
public class DataXExecutorApplication {

	public static void main(String[] args) {
        SpringApplication.run(DataXExecutorApplication.class, args);
	}

}
```

### 2.2 JobSpringExecutor.afterSingletonsInstantiated()

实现SmartInitializingSingleton的接口后，当所有单例 bean 都初始化完成以后， Spring的IOC容器会回调该接口的 afterSingletonsInstantiated()方法。afterSingletonsInstantiated里调用了父类JobExecutor的start方法

```java
// start
    @Override
    public void afterSingletonsInstantiated() {

        // 遍历所有添加了@JobHandler注解的class，将这些class添加到名为jobHandlerRepository的ConcurrentMap中
        initJobHandlerRepository(applicationContext);

        // 兼容spring-glue
        GlueFactory.refreshInstance(1);


        // 调用父类的start()
        try {
            super.start();
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
```

### 2.3 启动任务执行器 JobExecutor.start()

```java
public void start() throws Exception {

        // 1.初始化日志。创建执行器日志和glue日志
        JobFileAppender.initLogPath(logPath);

        // 2.将调度中心的ip、端口、accessToken封装成AdminBizClient对象；有几个ip，就封装几个AdminBizClient对象，然后把这些对象都放到adminBizList中
        initAdminBizList(adminAddresses, accessToken);


        // 3.启动清理日志线程。默认删除30天以前的日志，隔一天执行一次
        JobLogFileCleanThread.getInstance().start(logRetentionDays);

        // 4.初始化回调线程。从队列callBackQueue中获取回调对象HandleCallbackParam；callBackQueue是LinkedBlockingQueue，获取对象的方法是take，所以没有对象时会一直阻塞；当获取到回调对象后，调用doCallback方法；
        TriggerCallbackThread.getInstance().start();

        // 5.这里处理过程和4很像，不同的地方在于多了一些关于processId的处理
        ProcessCallbackThread.getInstance().start();

        // 6. 获取当前的ip和配置的执行器注册端口，然后以此端口和类中的方法发布为TCP服务端；创建完服务后，往所有调度中心发送注册服务的http请求（注册接口是 api/registry）；参数内容包括：执行器名称、当前TCP服务端的ip和端口；当系统关闭时，还会往所有调度中心发送移除注册的http请求（移除接口是	   		api/registryRemove）；这个方法执行完执行器端就启动完成了
        port = port > 0 ? port : NetUtil.findAvailablePort(9999);
        ip = (ip != null && ip.trim().length() > 0) ? ip : IpUtil.getIp();
        initRpcProvider(ip, port, appName, accessToken);
    }
```

## 4 任务运行 执行流程

### 4.1 定时执行

定时执行的任务，要从创建任务说起。创建好的任务就有一个字段是cron表达式，调度中心有一个类JobScheduleHelper会启动一个线程死循环不断去扫描任务表，满足执行条件的任务就会调用JobTriggerPoolHelper.trigger()方法去执行。

以上这一段在datax-admin（调度中心）启动 源码执行流程部分已经分析过，这里就不重复分析了。

因为定时执行调用方法和手动执行都是调用的JobTriggerPoolHelper.trigger()方法，所以就放在下面一起说了

### 4.2 手动执行

1.页面点击运行任务

2.请求后台接口对应的是JobInfoController.triggerJob()方法，这个方法又调用了JobTriggerPoolHelper.trigger()方法。

```java
@PostMapping(value = "/trigger")
    @ApiOperation("触发任务")
    public ReturnT<String> triggerJob(@RequestBody TriggerJobDto dto) {
        // force cover job param
        String executorParam=dto.getExecutorParam();
        if (executorParam == null) {
            executorParam = "";
        }
        JobTriggerPoolHelper.trigger(dto.getJobId(), TriggerTypeEnum.MANUAL, -1, null, executorParam);
        return ReturnT.SUCCESS;
    }
```

#### 4.2.1 JobTriggerPoolHelper.trigger()

前面初始化的时候创建了1快1慢两个线程池，这里就排上用场了所有任务开始时都放到快线程池里执行，1分钟内执行超过500毫秒的请求大于10次的任务放入慢线程池处理，线程池中调用JobTrigger.trigger()

```java
public void addTrigger(final int jobId, final TriggerTypeEnum triggerType, final int failRetryCount, final String executorShardingParam, final String executorParam) {

        // choose thread pool
        ThreadPoolExecutor triggerPool_ = fastTriggerPool;
        AtomicInteger jobTimeoutCount = jobTimeoutCountMap.get(jobId);
        if (jobTimeoutCount != null && jobTimeoutCount.get() > 10) {      // job-timeout 10 times in 1 min
            triggerPool_ = slowTriggerPool;
        }
        // trigger
        triggerPool_.execute(() -> {
            long start = System.currentTimeMillis();
            try {
                // do trigger
                JobTrigger.trigger(jobId, triggerType, failRetryCount, executorShardingParam, executorParam);
            } catch (Exception e) {
                logger.error(e.getMessage(), e);
            } finally {
                // check timeout-count-map
                long minTim_now = System.currentTimeMillis() / 60000;
                if (minTim != minTim_now) {
                    minTim = minTim_now;
                    jobTimeoutCountMap.clear();
                }
                // incr timeout-count-map
                long cost = System.currentTimeMillis() - start;
                if (cost > 500) {       // ob-timeout threshold 500ms
                    AtomicInteger timeoutCount = jobTimeoutCountMap.putIfAbsent(jobId, new AtomicInteger(1));
                    if (timeoutCount != null) {
                        timeoutCount.incrementAndGet();
                    }
                }
            }
        });
    }
```

#### 4.2.2 JobTrigger.trigger()

```java
public static void trigger(int jobId, TriggerTypeEnum triggerType, int failRetryCount, String executorShardingParam, String executorParam) {
		// 根据任务id查询到任务信息
        JobInfo jobInfo = JobAdminConfig.getAdminConfig().getJobInfoMapper().loadById(jobId);
        if (jobInfo == null) {
            logger.warn(">>>>>>>>>>>> trigger fail, jobId invalid，jobId={}", jobId);
            return;
        }
        // 解密账号密码
        if (GlueTypeEnum.BEAN.getDesc().equals(jobInfo.getGlueType())) {
            //解密账密
            String json = JSONUtils.changeJson(jobInfo.getJobJson(), JSONUtils.decrypt);
            jobInfo.setJobJson(json);
        }
        // 设置执行参数
        if (StringUtils.isNotBlank(executorParam)) {
            jobInfo.setExecutorParam(executorParam);
        }
        // 重试次数，如果有值就用该值，否则就用默认值
        int finalFailRetryCount = failRetryCount >= 0 ? failRetryCount : jobInfo.getExecutorFailRetryCount();
        // 获取执行器信息
        JobGroup group = JobAdminConfig.getAdminConfig().getJobGroupMapper().load(jobInfo.getJobGroup());

        // 处理分片参数
        int[] shardingParam = null;
        if (executorShardingParam != null) {
            String[] shardingArr = executorShardingParam.split("/");
            if (shardingArr.length == 2 && isNumeric(shardingArr[0]) && isNumeric(shardingArr[1])) {
                shardingParam = new int[2];
                shardingParam[0] = Integer.valueOf(shardingArr[0]);
                shardingParam[1] = Integer.valueOf(shardingArr[1]);
            }
        }
        // 循环执行器配置的服务地址列表,调用JobTrigger.processTrigger()
        if (ExecutorRouteStrategyEnum.SHARDING_BROADCAST == ExecutorRouteStrategyEnum.match(jobInfo.getExecutorRouteStrategy(), null)
                && group.getRegistryList() != null && !group.getRegistryList().isEmpty()
                && shardingParam == null) {
            for (int i = 0; i < group.getRegistryList().size(); i++) {
                processTrigger(group, jobInfo, finalFailRetryCount, triggerType, i, group.getRegistryList().size());
            }
        } else {
        // 非广播模式调用JobTrigger.processTrigger()
            if (shardingParam == null) {
                shardingParam = new int[]{0, 1};
            }
            processTrigger(group, jobInfo, finalFailRetryCount, triggerType, shardingParam[0], shardingParam[1]);
        }

    }
```

#### 4.2.3 JobTrigger.processTrigger()

```java
private static void processTrigger(JobGroup group, JobInfo jobInfo, int finalFailRetryCount, TriggerTypeEnum triggerType, int index, int total) {

        TriggerParam triggerParam = new TriggerParam();

        // 设置阻塞策略、路由策略、分片参数
        ExecutorBlockStrategyEnum blockStrategy = ExecutorBlockStrategyEnum.match(jobInfo.getExecutorBlockStrategy(), ExecutorBlockStrategyEnum.SERIAL_EXECUTION);  // block strategy
        ExecutorRouteStrategyEnum executorRouteStrategyEnum = ExecutorRouteStrategyEnum.match(jobInfo.getExecutorRouteStrategy(), null);    // route strategy
        String shardingParam = (ExecutorRouteStrategyEnum.SHARDING_BROADCAST == executorRouteStrategyEnum) ? String.valueOf(index).concat("/").concat(String.valueOf(total)) : null;

        // 1 保存任务id
        Calendar calendar = Calendar.getInstance();
        calendar.setTime(new Date());
        calendar.set(Calendar.MILLISECOND, 0);
        Date triggerTime = calendar.getTime();
        JobLog jobLog = new JobLog();
        jobLog.setJobGroup(jobInfo.getJobGroup());
        jobLog.setJobId(jobInfo.getId());
        jobLog.setTriggerTime(triggerTime);
        jobLog.setJobDesc(jobInfo.getJobDesc());

        JobAdminConfig.getAdminConfig().getJobLogMapper().save(jobLog);
        logger.debug(">>>>>>>>>>> datax-web trigger start, jobId:{}", jobLog.getId());

        // 2、初始化触发参数
        triggerParam.setJobId(jobInfo.getId());
        triggerParam.setExecutorHandler(jobInfo.getExecutorHandler());
        triggerParam.setExecutorParams(jobInfo.getExecutorParam());
        triggerParam.setExecutorBlockStrategy(jobInfo.getExecutorBlockStrategy());
        triggerParam.setExecutorTimeout(jobInfo.getExecutorTimeout());
        triggerParam.setLogId(jobLog.getId());
        triggerParam.setLogDateTime(jobLog.getTriggerTime().getTime());
        triggerParam.setGlueType(jobInfo.getGlueType());
        triggerParam.setGlueSource(jobInfo.getGlueSource());
        triggerParam.setGlueUpdatetime(jobInfo.getGlueUpdatetime().getTime());
        triggerParam.setBroadcastIndex(index);
        triggerParam.setBroadcastTotal(total);
        triggerParam.setJobJson(jobInfo.getJobJson());

        // 设置增量参数，id或者时间
        Integer incrementType = jobInfo.getIncrementType();
        if (incrementType != null) {
            triggerParam.setIncrementType(incrementType);
            if (IncrementTypeEnum.ID.getCode() == incrementType) {
                long maxId = getMaxId(jobInfo);
                jobLog.setMaxId(maxId);
                triggerParam.setEndId(maxId);
                triggerParam.setStartId(jobInfo.getIncStartId());
            } else if (IncrementTypeEnum.TIME.getCode() == incrementType) {
                triggerParam.setStartTime(jobInfo.getIncStartTime());
                triggerParam.setTriggerTime(triggerTime);
                triggerParam.setReplaceParamType(jobInfo.getReplaceParamType());
            } else if (IncrementTypeEnum.PARTITION.getCode() == incrementType) {
                triggerParam.setPartitionInfo(jobInfo.getPartitionInfo());
            }
            triggerParam.setReplaceParam(jobInfo.getReplaceParam());
        }
        //jvm参数
        triggerParam.setJvmParam(jobInfo.getJvmParam());

        // 3、设置执行器服务地址
        String address = null;
        ReturnT<String> routeAddressResult = null;
        if (group.getRegistryList() != null && !group.getRegistryList().isEmpty()) {
            if (ExecutorRouteStrategyEnum.SHARDING_BROADCAST == executorRouteStrategyEnum) {
                if (index < group.getRegistryList().size()) {
                    address = group.getRegistryList().get(index);
                } else {
                    address = group.getRegistryList().get(0);
                }
            } else {
                routeAddressResult = executorRouteStrategyEnum.getRouter().route(triggerParam, group.getRegistryList());
                if (routeAddressResult.getCode() == ReturnT.SUCCESS_CODE) {
                    address = routeAddressResult.getContent();
                }
            }
        } else {
            routeAddressResult = new ReturnT<String>(ReturnT.FAIL_CODE, I18nUtil.getString("jobconf_trigger_address_empty"));
        }

        // 4 调用JobTrigger.runExecutor()方法触发远程执行器执行
        ReturnT<String> triggerResult = null;
        if (address != null) {
            triggerResult = runExecutor(triggerParam, address);
        } else {
            triggerResult = new ReturnT<String>(ReturnT.FAIL_CODE, null);
        }

        // 5 搜集触发信息
        StringBuffer triggerMsgSb = new StringBuffer();
        triggerMsgSb.append(I18nUtil.getString("jobconf_trigger_type")).append("：").append(triggerType.getTitle());
        triggerMsgSb.append("<br>").append(I18nUtil.getString("jobconf_trigger_admin_adress")).append("：").append(IpUtil.getIp());
        triggerMsgSb.append("<br>").append(I18nUtil.getString("jobconf_trigger_exe_regtype")).append("：")
                .append((group.getAddressType() == 0) ? I18nUtil.getString("jobgroup_field_addressType_0") : I18nUtil.getString("jobgroup_field_addressType_1"));
        triggerMsgSb.append("<br>").append(I18nUtil.getString("jobconf_trigger_exe_regaddress")).append("：").append(group.getRegistryList());
        triggerMsgSb.append("<br>").append(I18nUtil.getString("jobinfo_field_executorRouteStrategy")).append("：").append(executorRouteStrategyEnum.getTitle());
        if (shardingParam != null) {
            triggerMsgSb.append("(" + shardingParam + ")");
        }
        triggerMsgSb.append("<br>").append(I18nUtil.getString("jobinfo_field_executorBlockStrategy")).append("：").append(blockStrategy.getTitle());
        triggerMsgSb.append("<br>").append(I18nUtil.getString("jobinfo_field_timeout")).append("：").append(jobInfo.getExecutorTimeout());
        triggerMsgSb.append("<br>").append(I18nUtil.getString("jobinfo_field_executorFailRetryCount")).append("：").append(finalFailRetryCount);

        triggerMsgSb.append("<br><br><span style=\"color:#00c0ef;\" > >>>>>>>>>>>" + I18nUtil.getString("jobconf_trigger_run") + "<<<<<<<<<<< </span><br>")
                .append((routeAddressResult != null && routeAddressResult.getMsg() != null) ? routeAddressResult.getMsg() + "<br><br>" : "").append(triggerResult.getMsg() != null ? triggerResult.getMsg() : "");

        // 6 保存日志到日志表
        jobLog.setExecutorAddress(address);
        jobLog.setExecutorHandler(jobInfo.getExecutorHandler());
        jobLog.setExecutorParam(jobInfo.getExecutorParam());
        jobLog.setExecutorShardingParam(shardingParam);
        jobLog.setExecutorFailRetryCount(finalFailRetryCount);
        jobLog.setTriggerCode(triggerResult.getCode());
        jobLog.setTriggerMsg(triggerMsgSb.toString());
        JobAdminConfig.getAdminConfig().getJobLogMapper().updateTriggerInfo(jobLog);

        logger.debug(">>>>>>>>>>> datax-web trigger end, jobId:{}", jobLog.getId());
    }
```

#### 4.2.4 JobTrigger.runExecutor()

```java
public static ReturnT<String> runExecutor(TriggerParam triggerParam, String address) {
        ReturnT<String> runResult = null;
        try {
        	// 根据地址创建代理类ExecutorBiz实例
            ExecutorBiz executorBiz = JobScheduler.getExecutorBiz(address);
            // 调用代理类的ExecutorBiz.run()方法
            runResult = executorBiz.run(triggerParam);
        } catch (Exception e) {
            logger.error(">>>>>>>>>>> datax-web trigger error, please check if the executor[{}] is running.", address, e);
            runResult = new ReturnT<String>(ReturnT.FAIL_CODE, ThrowableUtil.toString(e));
        }

        StringBuffer runResultSB = new StringBuffer(I18nUtil.getString("jobconf_trigger_run") + "：");
        runResultSB.append("<br>address：").append(address);
        runResultSB.append("<br>code：").append(runResult.getCode());
        runResultSB.append("<br>msg：").append(runResult.getMsg());

        runResult.setMsg(runResultSB.toString());
        return runResult;
    }
```

#### 4.2.5 ExecutorBiz.run()

这里是调用的执行器启动时发布的http服务，也就是执行器端ExecutorBiz的实现类的ExecutorBizImpl.run()方法

#### 4.2.6 ExecutorBizImpl.run()

```java
@Override
public ReturnT<String> run(TriggerParam triggerParam) {
        // load old：jobHandler + jobThread
        JobThread jobThread = JobExecutor.loadJobThread(triggerParam.getJobId());
        IJobHandler jobHandler = jobThread != null ? jobThread.getHandler() : null;
        String removeOldReason = null;

        // valid：jobHandler + jobThread
        GlueTypeEnum glueTypeEnum = GlueTypeEnum.match(triggerParam.getGlueType());
        // datax-web调用data使用的是BEAN模式。根据任务参数里executorHandler从ConcurrentMap缓存里获取对应的类。
        if (GlueTypeEnum.BEAN == glueTypeEnum) {

            // new jobhandler
            IJobHandler newJobHandler = JobExecutor.loadJobHandler(triggerParam.getExecutorHandler());

            // valid old jobThread
            if (jobThread != null && jobHandler != newJobHandler) {
                // change handler, need kill old thread
                removeOldReason = "change jobhandler or glue type, and terminate the old job thread.";

                jobThread = null;
                jobHandler = null;
            }

            // valid handler
            if (jobHandler == null) {
                jobHandler = newJobHandler;
                if (jobHandler == null) {
                    return new ReturnT<>(ReturnT.FAIL_CODE, "job handler [" + triggerParam.getExecutorHandler() + "] not found.");
                }
            }

        } else if (GlueTypeEnum.GLUE_GROOVY == glueTypeEnum) {

            // valid old jobThread
            if (jobThread != null &&
                    !(jobThread.getHandler() instanceof GlueJobHandler
                            && ((GlueJobHandler) jobThread.getHandler()).getGlueUpdatetime() == triggerParam.getGlueUpdatetime())) {
                // change handler or gluesource updated, need kill old thread
                removeOldReason = "change job source or glue type, and terminate the old job thread.";

                jobThread = null;
                jobHandler = null;
            }

            // valid handler
            if (jobHandler == null) {
                try {
                    IJobHandler originJobHandler = GlueFactory.getInstance().loadNewInstance(triggerParam.getGlueSource());
                    jobHandler = new GlueJobHandler(originJobHandler, triggerParam.getGlueUpdatetime());
                } catch (Exception e) {
                    logger.error(e.getMessage(), e);
                    return new ReturnT<String>(ReturnT.FAIL_CODE, e.getMessage());
                }
            }
        } else if (glueTypeEnum != null && glueTypeEnum.isScript()) {

            // valid old jobThread
            if (jobThread != null &&
                    !(jobThread.getHandler() instanceof ScriptJobHandler
                            && ((ScriptJobHandler) jobThread.getHandler()).getGlueUpdatetime() == triggerParam.getGlueUpdatetime())) {
                // change script or gluesource updated, need kill old thread
                removeOldReason = "change job source or glue type, and terminate the old job thread.";

                jobThread = null;
                jobHandler = null;
            }

            // valid handler
            if (jobHandler == null) {
                jobHandler = new ScriptJobHandler(triggerParam.getJobId(), triggerParam.getGlueUpdatetime(), triggerParam.getGlueSource(), GlueTypeEnum.match(triggerParam.getGlueType()));
            }
        } else {
            return new ReturnT<>(ReturnT.FAIL_CODE, "glueType[" + triggerParam.getGlueType() + "] is not valid.");
        }

        // executor block strategy
        if (jobThread != null) {
            ExecutorBlockStrategyEnum blockStrategy = ExecutorBlockStrategyEnum.match(triggerParam.getExecutorBlockStrategy(), null);
            if (ExecutorBlockStrategyEnum.DISCARD_LATER == blockStrategy) {
                // discard when running
                if (jobThread.isRunningOrHasQueue()) {
                    return new ReturnT<>(ReturnT.FAIL_CODE, "block strategy effect：" + ExecutorBlockStrategyEnum.DISCARD_LATER.getTitle());
                }
            } else if (ExecutorBlockStrategyEnum.COVER_EARLY == blockStrategy) {
                // kill running jobThread
                if (jobThread.isRunningOrHasQueue()) {
                    removeOldReason = "block strategy effect：" + ExecutorBlockStrategyEnum.COVER_EARLY.getTitle();

                    jobThread = null;
                }
            } else {
                // just queue trigger
            }
        }

        // 注册新线程取代旧线程
        if (jobThread == null) {
            jobThread = JobExecutor.registJobThread(triggerParam.getJobId(), jobHandler, removeOldReason);
        }

        // push data to queue
        ReturnT<String> pushResult = jobThread.pushTriggerQueue(triggerParam);
        return pushResult;
    }
```

#### 4.2.7 JobExecutor.registJobThread()

注册任务线程

```java
public static JobThread registJobThread(int jobId, IJobHandler handler, String removeOldReason) {
		// 根据任务id和handler创建任务线程
        JobThread newJobThread = new JobThread(jobId, handler);
        // 启动任务线程
        newJobThread.start();
        logger.info(">>>>>>>>>>> datax-web regist JobThread success, jobId:{}, handler:{}", new Object[]{jobId, handler});

        JobThread oldJobThread = jobThreadRepository.put(jobId, newJobThread);    // putIfAbsent | oh my god, map's put method return the old value!!!
        if (oldJobThread != null) {
            oldJobThread.toStop(removeOldReason);
            oldJobThread.interrupt();
        }

        return newJobThread;
    }
```

#### 4.2.8 JobThread.run()

```java
@Override
public void run() {

        // init
        try {
            handler.init();
        } catch (Throwable e) {
            logger.error(e.getMessage(), e);
        }

        // execute
        while (!toStop) {
            running = false;
            idleTimes++;

            TriggerParam tgParam = null;
            ReturnT<String> executeResult = null;
            try {
                // to check toStop signal, we need cycle, so wo cannot use queue.take(), instand of poll(timeout)
                tgParam = triggerQueue.poll(3L, TimeUnit.SECONDS);
                if (tgParam != null) {
                    running = true;
                    idleTimes = 0;
                    triggerLogIdSet.remove(tgParam.getLogId());

                    // log filename, like "logPath/yyyy-MM-dd/9999.log"
                    String logFileName = JobFileAppender.makeLogFileName(new Date(tgParam.getLogDateTime()), tgParam.getLogId());
                    JobFileAppender.contextHolder.set(logFileName);
                    ShardingUtil.setShardingVo(new ShardingUtil.ShardingVO(tgParam.getBroadcastIndex(), tgParam.getBroadcastTotal()));

                    // 执行任务
                    JobLogger.log("<br>----------- datax-web job execute start -----------<br>----------- Param:" + tgParam.getExecutorParams());

                    if (tgParam.getExecutorTimeout() > 0) {
                        // limit timeout
                        Thread futureThread = null;
                        try {
                            final TriggerParam tgParamT = tgParam;
                            // 如果是datax-web任务，这里调用的就是ExecutorJobHandler.execute()如果是其他类的任务调用的是创建任务时指定的JobHandler.execute()
                            FutureTask<ReturnT<String>> futureTask = new FutureTask<>(() -> handler.execute(tgParamT));
                            futureThread = new Thread(futureTask);
                            futureThread.start();

                            executeResult = futureTask.get(tgParam.getExecutorTimeout(), TimeUnit.MINUTES);
                        } catch (TimeoutException e) {

                            JobLogger.log("<br>----------- datax-web job execute timeout");
                            JobLogger.log(e);

                            executeResult = new ReturnT<>(IJobHandler.FAIL_TIMEOUT.getCode(), "job execute timeout ");
                        } finally {
                            futureThread.interrupt();
                        }
                    } else {
                        // just execute
                        executeResult = handler.execute(tgParam);
                    }

                    if (executeResult == null) {
                        executeResult = IJobHandler.FAIL;
                    } else {
                        executeResult.setMsg(
                                (executeResult != null && executeResult.getMsg() != null && executeResult.getMsg().length() > 50000)
                                        ? executeResult.getMsg().substring(0, 50000).concat("...")
                                        : executeResult.getMsg());
                        executeResult.setContent(null);    // limit obj size
                    }
                    JobLogger.log("<br>----------- datax-web job execute end(finish) -----------<br>----------- ReturnT:" + executeResult);

                } else {
                    if (idleTimes > 30) {
                        if (triggerQueue.size() == 0) {    // avoid concurrent trigger causes jobId-lost
                            JobExecutor.removeJobThread(jobId, "executor idel times over limit.");
                        }
                    }
                }
            } catch (Throwable e) {
                if (toStop) {
                    JobLogger.log("<br>----------- JobThread toStop, stopReason:" + stopReason);
                }

                StringWriter stringWriter = new StringWriter();
                e.printStackTrace(new PrintWriter(stringWriter));
                String errorMsg = stringWriter.toString();
                executeResult = new ReturnT<>(ReturnT.FAIL_CODE, errorMsg);

                JobLogger.log("<br>----------- JobThread Exception:" + errorMsg + "<br>----------- datax-web job execute end(error) -----------");
            } finally {
                // 终止操作暂不监控状态
                if (tgParam != null && tgParam.getJobId() != -1) {
                    // callback handler info
                    if (!toStop) {
                        // commonm
                        TriggerCallbackThread.pushCallBack(new HandleCallbackParam(tgParam.getLogId(), tgParam.getLogDateTime(), executeResult));
                    } else {
                        // is killed
                        ReturnT<String> stopResult = new ReturnT<String>(ReturnT.FAIL_CODE, stopReason + " [job running, killed]");
                        TriggerCallbackThread.pushCallBack(new HandleCallbackParam(tgParam.getLogId(), tgParam.getLogDateTime(), stopResult));
                    }
                }
            }
        }

        // callback trigger request in queue
        while (triggerQueue != null && triggerQueue.size() > 0) {
            TriggerParam triggerParam = triggerQueue.poll();
            if (triggerParam != null) {
                // is killed
                ReturnT<String> stopResult = new ReturnT<String>(ReturnT.FAIL_CODE, stopReason + " [job not executed, in the job queue, killed.]");
                TriggerCallbackThread.pushCallBack(new HandleCallbackParam(triggerParam.getLogId(), triggerParam.getLogDateTime(), stopResult));
            }
        }

        // destroy
        try {
            handler.destroy();
        } catch (Throwable e) {
            logger.error(e.getMessage(), e);
        }

        logger.info(">>>>>>>>>>> datax-web JobThread stoped, hashCode:{}", Thread.currentThread());
    }
```

#### 4.2.9 ExecutorJobHandler.execute()

```java
@Override
public ReturnT<String> execute(TriggerParam trigger) {

        int exitValue = -1;
        Thread errThread = null;
        String tmpFilePath;
        LogStatistics logStatistics = null;
        //生成json临时文件
        tmpFilePath = generateTemJsonFile(trigger.getJobJson());

        try {
        	// 构建执行命令
            String[] cmdarrayFinal = buildDataXExecutorCmd(trigger, tmpFilePath,dataXPyPath);
            // 执行datax任务
            final Process process = Runtime.getRuntime().exec(cmdarrayFinal);
            String prcsId = ProcessUtil.getProcessId(process);
            JobLogger.log("------------------DataX process id: " + prcsId);
            jobTmpFiles.put(prcsId, tmpFilePath);
            //update datax process id
            HandleProcessCallbackParam prcs = new HandleProcessCallbackParam(trigger.getLogId(), trigger.getLogDateTime(), prcsId);
            ProcessCallbackThread.pushCallBack(prcs);
            // log-thread
            Thread futureThread = null;
            FutureTask<LogStatistics> futureTask = new FutureTask<>(() -> analysisStatisticsLog(new BufferedInputStream(process.getInputStream())));
            futureThread = new Thread(futureTask);
            futureThread.start();

            errThread = new Thread(() -> {
                try {
                    analysisStatisticsLog(new BufferedInputStream(process.getErrorStream()));
                } catch (IOException e) {
                    JobLogger.log(e);
                }
            });

            logStatistics = futureTask.get();
            errThread.start();
            // process-wait
            exitValue = process.waitFor();      // exit code: 0=success, 1=error
            // log-thread join
            errThread.join();
        } catch (Exception e) {
            JobLogger.log(e);
        } finally {
            if (errThread != null && errThread.isAlive()) {
                errThread.interrupt();
            }
            //  删除临时文件
            if (FileUtil.exist(tmpFilePath)) {
                FileUtil.del(new File(tmpFilePath));
            }
        }
        if (exitValue == 0) {
            return new ReturnT<>(200, logStatistics.toString());
        } else {
            return new ReturnT<>(IJobHandler.FAIL.getCode(), "command exit value(" + exitValue + ") is failed");
        }
    }
```

## 5 查看执行日志执行流程

页面点击日志查看按钮，请求的api是/api/log/logDetailCat 对应的是JobLogController.logDetailCat()

### 5.1 JobLogController.logDetailCat()

```java
@RequestMapping(value = "/logDetailCat", method = RequestMethod.GET)
    @ApiOperation("运行日志详情")
    public ReturnT<LogResult> logDetailCat(String executorAddress, long triggerTime, long logId, int fromLineNum) {
        try {
        	// 根据指定地址获取远程服务代理类ExecutorBiz的实例ExecutorBizImpl
            ExecutorBiz executorBiz = JobScheduler.getExecutorBiz(executorAddress);
            // 调用ExecutorBizImpl.log()
            ReturnT<LogResult> logResult = executorBiz.log(triggerTime, logId, fromLineNum);

            // is end
            if (logResult.getContent() != null && fromLineNum > logResult.getContent().getToLineNum()) {
                JobLog jobLog = jobLogMapper.load(logId);
                if (jobLog.getHandleCode() > 0) {
                    logResult.getContent().setEnd(true);
                }
            }

            return logResult;
        } catch (Exception e) {
            logger.error(e.getMessage(), e);
            return new ReturnT<>(ReturnT.FAIL_CODE, e.getMessage());
        }
    }
```

### 5.2 ExecutorBizImpl.log()

```java
@Override
    public ReturnT<LogResult> log(long logDateTim, long logId, int fromLineNum) {
        // log filename: logPath/yyyy-MM-dd/9999.log
        // 生成日志文件名
        String logFileName = JobFileAppender.makeLogFileName(new Date(logDateTim), logId);
		// 调用JobFileAppender.readLog() 一行一行读取文件
        LogResult logResult = JobFileAppender.readLog(logFileName, fromLineNum);
        return new ReturnT<>(logResult);
    }
```

## 6 任务增删改查

JobInfoController

```java
	//添加
    JobInfoController.add()
    //查询
    JobInfoController.list()
    //修改
    JobInfoController.update()
    //删除
    JobInfoController.remove()
```

# 参考资料

datax-web swagger接口文档（接口文档需要启动服务才可以看到）
[http://127.0.0.1:8381/doc.html#/default/%E4%BB%BB%E5%8A%A1%E9%85%8D%E7%BD%AE%E6%8E%A5%E5%8F%A3/addUsingPOST](http://127.0.0.1:8381/doc.html#/default/任务配置接口/addUsingPOST)

xxl-job 参考文档
https://www.xuxueli.com/xxl-job/

xxl-job 原理系列博客
https://www.jianshu.com/p/d70b78a704e5

xxl-job 任务执行流程博客
https://blog.csdn.net/god_86/article/details/114650439