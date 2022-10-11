- [DataX 全系列之四 —— DataX 核心数据结构 - 掘金 (juejin.cn)](https://juejin.cn/post/7007616850745884708)

# 1. JobContainer

## 1.1 基本介绍

  JobContainer 的 job 实例运行在 jobContainer 容器中，它是所有任务的 master，负责初始化、拆分、调度、运行、回收、监控和汇报。

## 1.2 核心成员及及介绍

![image.png](https://p9-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/26322c4dbb2f40e29a0d9d0e364de95e~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

## 1.3 核心成员变量

![image.png](https://p1-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/a737a9dd021744518721061483ba1278~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

## 1.4 核心方法源码

### 1.4.1 init方法

```kotlin
/**
 * reader和writer的初始化
 */
private void init() {
    this.jobId = this.configuration.getLong(
            CoreConstant.DATAX_CORE_CONTAINER_JOB_ID, -1);

    if (this.jobId < 0) {
        LOG.info("Set jobId = 0");
        this.jobId = 0;
        this.configuration.set(CoreConstant.DATAX_CORE_CONTAINER_JOB_ID,
                this.jobId);
    }

    Thread.currentThread().setName("job-" + this.jobId);

    JobPluginCollector jobPluginCollector = new DefaultJobPluginCollector(
            this.getContainerCommunicator());
    //必须先Reader ，后Writer
    this.jobReader = this.initJobReader(jobPluginCollector);
    this.jobWriter = this.initJobWriter(jobPluginCollector);
}
复制代码
```

### 1.4.2 split方法

```ini
/**
 * 执行reader和writer最细粒度的切分，需要注意的是，writer的切分结果要参照reader的切分结果，
 * 达到切分后数目相等，才能满足1：1的通道模型，所以这里可以将reader和writer的配置整合到一起，
 * 然后，为避免顺序给读写端带来长尾影响，将整合的结果shuffler掉
 */
private int split() {
    this.adjustChannelNumber();

    if (this.needChannelNumber <= 0) {
        this.needChannelNumber = 1;
    }

    List<Configuration> readerTaskConfigs = this
            .doReaderSplit(this.needChannelNumber);
    int taskNumber = readerTaskConfigs.size();
    List<Configuration> writerTaskConfigs = this
            .doWriterSplit(taskNumber);

    List<Configuration> transformerList = this.configuration.getListConfiguration(CoreConstant.DATAX_JOB_CONTENT_TRANSFORMER);

    LOG.debug("transformer configuration: "+ JSON.toJSONString(transformerList));
    /**
     * 输入是reader和writer的parameter list，输出是content下面元素的list
     */
    List<Configuration> contentConfig = mergeReaderAndWriterTaskConfigs(
            readerTaskConfigs, writerTaskConfigs, transformerList);


    LOG.debug("contentConfig configuration: "+ JSON.toJSONString(contentConfig));

    this.configuration.set(CoreConstant.DATAX_JOB_CONTENT, contentConfig);

    return contentConfig.size();
}
复制代码
```

### 1.4.3 Schedule 方法定义调度类并启动**

```java
/**
 * schedule首先完成的工作是把上一步reader和writer split的结果整合到具体taskGroupContainer中,
 * 同时不同的执行模式调用不同的调度策略，将所有任务调度起来
 */
private void schedule() {
    /**
     * 这里的全局speed和每个channel的速度设置为B/s
     */
    int channelsPerTaskGroup = this.configuration.getInt(
            CoreConstant.DATAX_CORE_CONTAINER_TASKGROUP_CHANNEL, 5);
    int taskNumber = this.configuration.getList(
            CoreConstant.DATAX_JOB_CONTENT).size();

    this.needChannelNumber = Math.min(this.needChannelNumber, taskNumber);
    PerfTrace.getInstance().setChannelNumber(needChannelNumber);

    /**
     * 通过获取配置信息得到每个taskGroup需要运行哪些tasks任务
     */

    List<Configuration> taskGroupConfigs = JobAssignUtil.assignFairly(this.configuration,
            this.needChannelNumber, channelsPerTaskGroup);

    LOG.info("Scheduler starts [{}] taskGroups.", taskGroupConfigs.size());

    ExecuteMode executeMode = null;
    AbstractScheduler scheduler;
    try {
       executeMode = ExecuteMode.STANDALONE;
        scheduler = initStandaloneScheduler(this.configuration);

        //设置 executeMode
        for (Configuration taskGroupConfig : taskGroupConfigs) {
            taskGroupConfig.set(CoreConstant.DATAX_CORE_CONTAINER_JOB_MODE, executeMode.getValue());
        }

        if (executeMode == ExecuteMode.LOCAL || executeMode == ExecuteMode.DISTRIBUTE) {
            if (this.jobId <= 0) {
                throw DataXException.asDataXException(FrameworkErrorCode.RUNTIME_ERROR,
                        "在[ local | distribute ]模式下必须设置jobId，并且其值 > 0 .");
            }
        }

        LOG.info("Running by {} Mode.", executeMode);

        this.startTransferTimeStamp = System.currentTimeMillis();

        scheduler.schedule(taskGroupConfigs);

        this.endTransferTimeStamp = System.currentTimeMillis();
    } catch (Exception e) {
        LOG.error("运行scheduler 模式[{}]出错.", executeMode);
        this.endTransferTimeStamp = System.currentTimeMillis();
        throw DataXException.asDataXException(
                FrameworkErrorCode.RUNTIME_ERROR, e);
    }

    /**
     * 检查任务执行情况
     */
    this.checkLimit();
}
```

## 1.5. 继承关系

  JobContainer和TaskGroupContainer均继承于AbstrctContainer

![image.png](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/96580de738bd46bda8fcffe2abac56a7~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

## 2. ProcessInnerScheduler和StandAloneScheuler

### 2.1 基本介绍：

  JobContainer 执行完 init 和 split 方法之后，会正式开 始就行任务的调度和执行，这时候就需要调度器进行动态任务的分配，调用，监控和处理。

### 2.2 核心成员方法，成员变量及介绍

![image.png](https://p1-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/49cb2d8aa2434869a3689cfeda3bfde3~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

### 2.3 核心方法源码

  启动所有的TaskGruop，其实就是建立了一个线程池进行统一管理

```java
public void startAllTaskGroup(List<Configuration> configurations) {
    this.taskGroupContainerExecutorService = Executors
            .newFixedThreadPool(configurations.size());

    for (Configuration taskGroupConfiguration : configurations) {
        TaskGroupContainerRunner taskGroupContainerRunner = newTaskGroupContainerRunner(taskGroupConfiguration);
        this.taskGroupContainerExecutorService.execute(taskGroupContainerRunner);
    }

    this.taskGroupContainerExecutorService.shutdown();
}
```

  建立TaskGroup线程

```java
private TaskGroupContainerRunner newTaskGroupContainerRunner(
        Configuration configuration) {
    TaskGroupContainer taskGroupContainer = new TaskGroupContainer(configuration);

    return new TaskGroupContainerRunner(taskGroupContainer);
}

```

## 2.4 继承关系

![image.png](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/bf3be12077dd4f95afa046be8ba28e78~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

# 3.TaskGroupContainerRunner

## 3.1 基本介绍

  包含 TaskGroup 的具体线程的运行内容。

## 3.2 成员方法及变量

![image.png](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/0d6c0516cbe744bf98576f9a9324d4ad~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

# 4. TaskGroupContainer

## 4.1 基本介绍

  调度器启动的 TaskGroupContainerRunner 线程会调用任务组容器 TaskGroupContainer 的 start 方法，正式启动 askGroupContainer， TaskGroupContainer 主要负责 TaskGruop 的管理，是任务组运行的容器， 负责监控，运行任务，对任务统一管理等。

  TaskGroupContainer 启动主要执行两个部分:初始化 task 执行相关的 状态信息，分别是 taskId 与其对应的 Congifuration 的 map 映射集合、待 运行的任务队列 taskQueue、运行失败任务 taskFailedExecutorMap、正在执行的任务集合 runTasks 等。进入循环，循环判断各个任务执行的状态。

1. 判断是否有失败的 task，如果有则放入 taskFailedExecutorMap 中， 并查看当前的执行是否支持重跑和 failOver，如果支持则重新放回执行队 列中;如果没有失败，则标记任务执行成功，并从状态轮询 map 中移除。
2. 如果发现有失败的任务，则向容器汇报状态，抛出异常。
3. 查看当前执行队列的长度，如果发现执行队列还有通道，则构建 TaskExecutor 加入执行队列，并从待运行移除。
4. 检查执行队列和所有的任务状态，如果所有的任务都执行成功，则 汇报 taskGroup 的状态并从循环中退出。
5. 检查当前时间是否超过汇报时间，如果超过了，就需要向全局汇报 当前状态。
6. 所有任务成功之后，向全局汇报当前的任务状态。

## 4.2 核心成员方法及介绍

![image.png](https://p6-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/9b3386191de142b0817a1397980e3810~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

## 4.3 核心成员变量

![image.png](https://p9-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/99af954b07e94533b3219452d0613445~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

## 4.4 继承关系

  和 JobContainer 继承自同一父类。

![image.png](https://p1-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/a517285032a74696b7e26a5acc26adea~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

## 4.5 核心方法源码

  启动TaskGroupContainer，循环判断各个任务执行的状态。对各个任务进行调度和管理

```scss
public void start() {
    try {
        /**
         * 状态check时间间隔，较短，可以把任务及时分发到对应channel中
         */
        int sleepIntervalInMillSec = this.configuration.getInt(
                CoreConstant.DATAX_CORE_CONTAINER_TASKGROUP_SLEEPINTERVAL, 100);
        /**
         * 状态汇报时间间隔，稍长，避免大量汇报
         */
        long reportIntervalInMillSec = this.configuration.getLong(
                CoreConstant.DATAX_CORE_CONTAINER_TASKGROUP_REPORTINTERVAL,
                10000);
        /**
         * 2分钟汇报一次性能统计
         */

        // 获取channel数目
        int channelNumber = this.configuration.getInt(
                CoreConstant.DATAX_CORE_CONTAINER_TASKGROUP_CHANNEL);

        int taskMaxRetryTimes = this.configuration.getInt(
                CoreConstant.DATAX_CORE_CONTAINER_TASK_FAILOVER_MAXRETRYTIMES, 1);

        long taskRetryIntervalInMsec = this.configuration.getLong(
                CoreConstant.DATAX_CORE_CONTAINER_TASK_FAILOVER_RETRYINTERVALINMSEC, 10000);

        long taskMaxWaitInMsec = this.configuration.getLong(CoreConstant.DATAX_CORE_CONTAINER_TASK_FAILOVER_MAXWAITINMSEC, 60000);
        
        List<Configuration> taskConfigs = this.configuration
                .getListConfiguration(CoreConstant.DATAX_JOB_CONTENT);

        if(LOG.isDebugEnabled()) {
            LOG.debug("taskGroup[{}]'s task configs[{}]", this.taskGroupId,
                    JSON.toJSONString(taskConfigs));
        }
        
        int taskCountInThisTaskGroup = taskConfigs.size();
        LOG.info(String.format(
                "taskGroupId=[%d] start [%d] channels for [%d] tasks.",
                this.taskGroupId, channelNumber, taskCountInThisTaskGroup));
        
        this.containerCommunicator.registerCommunication(taskConfigs);

        Map<Integer, Configuration> taskConfigMap = buildTaskConfigMap(taskConfigs); //taskId与task配置
        List<Configuration> taskQueue = buildRemainTasks(taskConfigs); //待运行task列表
        Map<Integer, TaskExecutor> taskFailedExecutorMap = new HashMap<Integer, TaskExecutor>(); //taskId与上次失败实例
        List<TaskExecutor> runTasks = new ArrayList<TaskExecutor>(channelNumber); //正在运行task
        Map<Integer, Long> taskStartTimeMap = new HashMap<Integer, Long>(); //任务开始时间

        long lastReportTimeStamp = 0;
        Communication lastTaskGroupContainerCommunication = new Communication();

        while (true) {
           //1.判断task状态
           boolean failedOrKilled = false;
           Map<Integer, Communication> communicationMap = containerCommunicator.getCommunicationMap();
           for(Map.Entry<Integer, Communication> entry : communicationMap.entrySet()){
              Integer taskId = entry.getKey();
              Communication taskCommunication = entry.getValue();
                if(!taskCommunication.isFinished()){
                    continue;
                }
                TaskExecutor taskExecutor = removeTask(runTasks, taskId);

                //上面从runTasks里移除了，因此对应在monitor里移除
                taskMonitor.removeTask(taskId);

                //失败，看task是否支持failover，重试次数未超过最大限制
              if(taskCommunication.getState() == State.FAILED){
                    taskFailedExecutorMap.put(taskId, taskExecutor);
                 if(taskExecutor.supportFailOver() && taskExecutor.getAttemptCount() < taskMaxRetryTimes){
                        taskExecutor.shutdown(); //关闭老的executor
                        containerCommunicator.resetCommunication(taskId); //将task的状态重置
                    Configuration taskConfig = taskConfigMap.get(taskId);
                    taskQueue.add(taskConfig); //重新加入任务列表
                 }else{
                    failedOrKilled = true;
                     break;
                 }
              }else if(taskCommunication.getState() == State.KILLED){
                 failedOrKilled = true;
                 break;
              }else if(taskCommunication.getState() == State.SUCCEEDED){
                    Long taskStartTime = taskStartTimeMap.get(taskId);
                    if(taskStartTime != null){
                        Long usedTime = System.currentTimeMillis() - taskStartTime;
                        LOG.info("taskGroup[{}] taskId[{}] is successed, used[{}]ms",
                                this.taskGroupId, taskId, usedTime);
                        //usedTime*1000*1000 转换成PerfRecord记录的ns，这里主要是简单登记，进行最长任务的打印。因此增加特定静态方法
                        PerfRecord.addPerfRecord(taskGroupId, taskId, PerfRecord.PHASE.TASK_TOTAL,taskStartTime, usedTime * 1000L * 1000L);
                        taskStartTimeMap.remove(taskId);
                        taskConfigMap.remove(taskId);
                    }
                }
           }
           
            // 2.发现该taskGroup下taskExecutor的总状态失败则汇报错误
            if (failedOrKilled) {
                //...此处省略部分代码
            }
            
            //3.有任务未执行，且正在运行的任务数小于最大通道限制
            Iterator<Configuration> iterator = taskQueue.iterator();
            while(iterator.hasNext() && runTasks.size() < channelNumber){
                Configuration taskConfig = iterator.next();
                Integer taskId = taskConfig.getInt(CoreConstant.TASK_ID);
                int attemptCount = 1;
                TaskExecutor lastExecutor = taskFailedExecutorMap.get(taskId);
                if(lastExecutor!=null){
                    attemptCount = lastExecutor.getAttemptCount() + 1;
                    long now = System.currentTimeMillis();
                    long failedTime = lastExecutor.getTimeStamp();
                    if(now - failedTime < taskRetryIntervalInMsec){  //未到等待时间，继续留在队列
                        continue;
                    }
                    if(!lastExecutor.isShutdown()){ //上次失败的task仍未结束
                        if(now - failedTime > taskMaxWaitInMsec){
                            markCommunicationFailed(taskId);
                            reportTaskGroupCommunication(lastTaskGroupContainerCommunication, taskCountInThisTaskGroup);
                            throw DataXException.asDataXException(CommonErrorCode.WAIT_TIME_EXCEED, "task failover等待超时");
                        }else{
                            lastExecutor.shutdown(); //再次尝试关闭
                            continue;
                        }
                    }else{
                        LOG.info("taskGroup[{}] taskId[{}] attemptCount[{}] has already shutdown",
                                this.taskGroupId, taskId, lastExecutor.getAttemptCount());
                    }
                }
                Configuration taskConfigForRun = taskMaxRetryTimes > 1 ? taskConfig.clone() : taskConfig;
               TaskExecutor taskExecutor = new TaskExecutor(taskConfigForRun, attemptCount);
                taskStartTimeMap.put(taskId, System.currentTimeMillis());
               taskExecutor.doStart();

                iterator.remove();
                runTasks.add(taskExecutor);

                //上面，增加task到runTasks列表，因此在monitor里注册。
                taskMonitor.registerTask(taskId, this.containerCommunicator.getCommunication(taskId));

                taskFailedExecutorMap.remove(taskId);
                LOG.info("taskGroup[{}] taskId[{}] attemptCount[{}] is started",
                        this.taskGroupId, taskId, attemptCount);
            }

            //4.任务列表为空，executor已结束, 搜集状态为success--->成功
            if (taskQueue.isEmpty() && isAllTaskDone(runTasks) && containerCommunicator.collectState() == State.SUCCEEDED) {
               // 成功的情况下，也需要汇报一次。否则在任务结束非常快的情况下，采集的信息将会不准确
              //...省略部分代码
            }

            // 5.如果当前时间已经超出汇报时间的interval，那么我们需要马上汇报
            long now = System.currentTimeMillis();
            if (now - lastReportTimeStamp > reportIntervalInMillSec) {
                lastTaskGroupContainerCommunication = reportTaskGroupCommunication(
                        lastTaskGroupContainerCommunication, taskCountInThisTaskGroup);

                lastReportTimeStamp = now;

                //taskMonitor对于正在运行的task，每reportIntervalInMillSec进行检查
                for(TaskExecutor taskExecutor:runTasks){
                    taskMonitor.report(taskExecutor.getTaskId(),this.containerCommunicator.getCommunication(taskExecutor.getTaskId()));
                }

            }

            Thread.sleep(sleepIntervalInMillSec);
        }

        //6.最后还要汇报一次
        reportTaskGroupCommunication(lastTaskGroupContainerCommunication, taskCountInThisTaskGroup);


    } catch (Throwable e) {
        //...省略部分代码
    }finally {
        //...省略部分代码
        
    }
}
复制代码
```

# 5. AbstractContainer

## 5.1 基本介绍

  JobContainer 和 TaskGroupContainer 的抽象类，持有该容器的全局配置 Configuration 。

## 5.2 核心成员方法及介绍

![image.png](https://p6-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/21a2bdb749424253a9c2203b22727125~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

# 6. TaskExecutor

## 6.1 基本介绍

  TaskExecutor 为 TaskGroupContainer 的内部类，负责单 个任务(task)的管理和启动。会启动读写线程，并定义一些中间传输类， 进行传输和监控。

## 6.2 核心成员方法及变量的介绍

![image.png](https://p6-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/5bf97b4917cf48a396ba9f3dab0d3c51~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

## 6.3 核心方法源码

  启动方法：

```kotlin
public void doStart() {
    this.writerThread.start();

    // reader没有起来，writer不可能结束
    if (!this.writerThread.isAlive() || this.taskCommunication.getState() == State.FAILED) {
        throw DataXException.asDataXException(
                FrameworkErrorCode.RUNTIME_ERROR,
                this.taskCommunication.getThrowable());
    }

    this.readerThread.start();

    // 这里reader可能很快结束
    if (!this.readerThread.isAlive() && this.taskCommunication.getState() == State.FAILED) {
        // 这里有可能出现Reader线上启动即挂情况 对于这类情况 需要立刻抛出异常
        throw DataXException.asDataXException(
                FrameworkErrorCode.RUNTIME_ERROR,
                this.taskCommunication.getThrowable());
    }

}
复制代码
```

  初始化插件（写插件的初始化和他类似，代码过长，此处省略）

![image.png](https://p1-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/e492279806224f4db3fe39349181151c~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

# 7. Record

## 7.1 基本介绍

  Record 主要有 DefaultRecord 和 TerminateRecord 的内 部类，是两边数据源，也就是读写线程之间传递的基本单位，代表了数据库中的一条记录。

## 7.2 核心成员方法及介绍

![image.png](https://p9-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/6a99496432da4a8499b79679360ded01~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

## 7.3 继承关系

![image.png](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/d112f34e517141c18e642cec33fdf7e1~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

# 8.其余数据结构

## 8.1 Channel

  是一次task中，数据源进行读写操作的数据中转和存储中心类

![image.png](https://p1-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/9dcaaecd58c644ffb9ac252a3da51e65~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

## 8.2 mysqlWriter 和 mysqlReader

  负责 mysql 的读写，内含有 init 初始化 方法，split 个性化分割任务，以及 task 内部类中 startRead 和 startWrite 方法(jdbc 获取数据库数据存放到 Record)。继承于抽象类 Reader 和 Writer。

  他们的方法会在读写线程中被调用，具体会在后续插件开发指南中提到。

![image.png](https://p9-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/b8ce66872dd64203b1aa308637fd2632~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

![image.png](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/72045f3674da4d048ee5e2fca7befeb1~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

## 8.3 Configuration

  Configuration 类负责存储 Json 配置文件全部信息，提供多级 JSON 配置信息无损存储。  核心成员方法，主要用于修改数据和获取数据：

![image.png](https://p9-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/e827302133ae438580b108e418680b9a~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

![image.png](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/0451aabb799d4ec783e16128594be5fd~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

  核心成员变量主要是root变量，将整个Json文件通过Json格式解析，变成了一个Object类。

![image.png](https://p9-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/c32fdba38ea44f74ad28688435f0e8e8~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)