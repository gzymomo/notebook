- [DataX 全系列之三 —— DataX 源码运行流程分析 - 掘金 (juejin.cn)](https://juejin.cn/post/7006619232641220616)

# 1 程序入口类Engine

  任务执行的入口类为Engine

```java
public static void main(String[] args) throws Exception {
        int exitCode = 0;
        try {
            //调用内部的entry方法
            Engine.entry(args);
        } catch (Throwable e) {
         ///...省略其他代码
        }
        System.exit(exitCode);
    }
复制代码
```

  Engine类内部的entry方法主要功能是：

1. 解析命令行参数-mode， -jobid ，-job ，分别获取执行模式，jobid, 和job配置文件路径。
2. 解析用户自己编辑的json文件配置，解析json文件封装到一个Configuration类中（如何解析后续补充），新建一个Engine类调用start方法启动。

```java
    public static void entry(final String[] args) throws Throwable {
        //定义命令行参数-mode，-jobid，-job
        Options options = new Options();
        options.addOption("job", true, "Job config.");
        options.addOption("jobid", true, "Job unique id.");
        options.addOption("mode", true, "Job runtime mode.");

        BasicParser parser = new BasicParser();
        CommandLine cl = parser.parse(options, args);//解析命令行参数

        String jobPath = cl.getOptionValue("job");

        // 如果用户没有明确指定jobid, 则 datax.py 会指定 jobid 默认值为-1
        String jobIdString = cl.getOptionValue("jobid");
        RUNTIME_MODE = cl.getOptionValue("mode");
        //指定Job配置路径，ConfigParser会解析Job、Plugin、Core全部信息，并以Configuration返回
        Configuration configuration = ConfigParser.parse(jobPath);//configuration中拥有配置文件的全部信息，贯穿整个datax程序
        
        ///...省略其他代码
        
        Engine engine = new Engine();
        engine.start(configuration);//启动引擎
    }
复制代码
```

  ConfigParser.parse方法如何解析暂时省略，可以直接使用

  Engine的start方法主要完成了:

1. 首先是往配置类中继续绑定一些信息，如ColumnCast的转换信息。
2. 初始化PluginLoader（插件加载器），用来获取各种插件配置（为后续热加载的方式做好准备）。
3. 创建JobContainer ,并且启动，JobContainer将是一次数据同步job的运行容器。

```java
    /* check job model (job/task) first */
    public void start(Configuration allConf) {

        // 绑定column转换信息
        ColumnCast.bind(allConf);

        /**
         * 初始化PluginLoader，可以获取各种插件配置
         */
        LoadUtil.bind(allConf);

        boolean isJob = !("taskGroup".equalsIgnoreCase(allConf
                .getString(CoreConstant.DATAX_CORE_CONTAINER_MODEL)));
        //JobContainer会在schedule后再行进行设置和调整值
        int channelNumber =0;
        AbstractContainer container;
        long instanceId;
        int taskGroupId = -1;
        //基本上都是job模式
        if (isJob) {
            allConf.set(CoreConstant.DATAX_CORE_CONTAINER_JOB_MODE, RUNTIME_MODE);
            //JobContainer初始化，传入全局的配置参数
            container = new JobContainer(allConf);
            instanceId = allConf.getLong(
                    CoreConstant.DATAX_CORE_CONTAINER_JOB_ID, 0);

        } else {
            ///...此处代码省略，几乎用不到
        }

        //缺省打开perfTrace
        boolean traceEnable = allConf.getBool(CoreConstant.DATAX_CORE_CONTAINER_TRACE_ENABLE, true);
        boolean perfReportEnable = allConf.getBool(CoreConstant.DATAX_CORE_REPORT_DATAX_PERFLOG, true);

        //standlone模式的datax shell任务不进行汇报
        if(instanceId == -1){
            perfReportEnable = false;
        }
        //此处代码未理解
        int priority = 0;
        try {
            priority = Integer.parseInt(System.getenv("SKYNET_PRIORITY"));
        }catch (NumberFormatException e){
            LOG.warn("prioriy set to 0, because NumberFormatException, the value is: "+System.getProperty("PROIORY"));
        }
        //从总配置文件中提取出跟一个job有关的配置
        Configuration jobInfoConfig = allConf.getConfiguration(CoreConstant.DATAX_JOB_JOBINFO);
        //初始化PerfTrace
        PerfTrace perfTrace = PerfTrace.getInstance(isJob, instanceId, taskGroupId, priority, traceEnable);
        perfTrace.setJobInfo(jobInfoConfig,perfReportEnable,channelNumber);
        //启动JobContainer，启动类介绍完毕，进入JobContainner
        container.start()

    }
复制代码
```

# 2 JobContainer

   job实例运行在jobContainer容器中，它是所有任务的master，负责初始化、拆分、调度、运行、回收、监控和汇报，但它并不做实际的数据同步操作。

  **start方法**

1. jobContainer主要负责的工作全部在start()里面，包括init、prepare、split、scheduler
2. init方法负责Reader和Writer的初始化和加载
3. prepare方法做一些前置准备
4. split方法根据配置的并发参数，对job进行切分，切分为多个task
5. scheduler是则是真正的调度任务调度与运行。

```java
    @Override
    public void start() {
        LOG.info("DataX jobContainer starts job.");
        boolean hasException = false;
        boolean isDryRun = false;
        try {
            this.startTimeStamp = System.currentTimeMillis();
            isDryRun = configuration.getBool(CoreConstant.DATAX_JOB_SETTING_DRYRUN, false);
            if(isDryRun) {
                ///...省略，几乎用不到
            } else {
                //clone一份配置，因为要做修改
                userConf = configuration.clone();
                //前置处理
                this.preHandle();
                //初始化read和write插件
                this.init();
                //进行插件的前置操作，有些插件不需要，例如mysqlreader
                this.prepare();
                //切分任务，为并发做准备
                this.totalStage = this.split();
                //任务调度，启动任务
                this.schedule();
                //任务后置处理
                this.post();
                //任务后置处理
                this.postHandle();
                //触发勾子？没看懂
                this.invokeHooks();
            }
        } catch (Throwable e) {
            ///...省略其他代码
        } finally {
            ///...省略其他代码
        }
    }
复制代码
```

  **init方法** 
  init方法用于初始化read和writer插件，其中包括通过类加载器加载指定插件，将配置文件的内容赋值到read和write插件的内部变量，方便后续的调用。该过程会对配置文件中的表，列等进行一个判断。初始化之后容器中的读写变量就是具体插件了。

```java
private void init() {
        //从配置中获取job
        this.jobId = this.configuration.getLong(
                CoreConstant.DATAX_CORE_CONTAINER_JOB_ID, -1);

        if (this.jobId < 0) {
            LOG.info("Set jobId = 0");
            this.jobId = 0;
            //配置信息中加入jobId信息
            this.configuration.set(CoreConstant.DATAX_CORE_CONTAINER_JOB_ID,
                    this.jobId);
        }

        Thread.currentThread().setName("job-" + this.jobId);
        //这个暂时没有看懂
        JobPluginCollector jobPluginCollector = new DefaultJobPluginCollector(
                this.getContainerCommunicator());
        //必须先Reader ，后Writer，因为Writer的配置依赖于Reader
        this.jobReader = this.initJobReader(jobPluginCollector);
        this.jobWriter = this.initJobWriter(jobPluginCollector);
    }
复制代码
```

  initJobReader方法主要是利用了URLClassLoader对插件进行了一个类加载，可以找到指定目录下的插件进行一个加载。加载到后会调用插件自己内部的init方法进行个性初始化。

```java
private Reader.Job initJobReader(
        JobPluginCollector jobPluginCollector) {
    //获取读插件名称
    this.readerPluginName = this.configuration.getString(
            CoreConstant.DATAX_JOB_CONTENT_READER_NAME);    //job.content[0].reader.name
    //根据读插件类名称,加载插件的lib包加载到jvm中
    classLoaderSwapper.setCurrentThreadClassLoader(LoadUtil.getJarLoader(
            PluginType.READER, this.readerPluginName)); //重置插件jar classLoader
    //创建一个读对象
    Reader.Job jobReader = (Reader.Job) LoadUtil.loadJobPlugin(
            PluginType.READER, this.readerPluginName);
    // 设置reader的jobConfig
    jobReader.setPluginJobConf(this.configuration.getConfiguration(
            CoreConstant.DATAX_JOB_CONTENT_READER_PARAMETER));
    // 设置reader的readerConfig
    jobReader.setPeerPluginJobConf(this.configuration.getConfiguration(
            CoreConstant.DATAX_JOB_CONTENT_WRITER_PARAMETER));
    jobReader.setJobPluginCollector(jobPluginCollector);
    jobReader.init();   //加载到具体插件后，执行对应
    //重置回归原classLoader
    classLoaderSwapper.restoreCurrentThreadClassLoader();
    return jobReader;
}
复制代码
```

  以MysqlReader插件的初始化为例

```java
@Override
        public void init() {
            this.originalConfig = super.getPluginJobConf();

            Integer userConfigedFetchSize = this.originalConfig.getInt(Constant.FETCH_SIZE);
            if (userConfigedFetchSize != null) {
                LOG.warn("对 mysqlreader 不需要配置 fetchSize, mysqlreader 将会忽略这项配置. 如果您不想再看到此警告,请去除fetchSize 配置.");
            }

            this.originalConfig.set(Constant.FETCH_SIZE, Integer.MIN_VALUE);

            this.commonRdbmsReaderJob = new CommonRdbmsReader.Job(DATABASE_TYPE);
            this.commonRdbmsReaderJob.init(this.originalConfig);
        }
复制代码
```

  **prepare方法**
  此处暂时省略，不是所有的插件都需要用到该方法，很多插件内部该方法为空。

# JobContainer任务切分方法：split

经过init方法和prepare方法后进入到任务执行前最重要的一个步骤，也就是任务的切分。

1. split主要是根据needChannelNumber对Reader和Writer进行拆分，每个reader和writer插件都有自己的split方法。
2. JobContainer中前面已经初始化的jobReader，会根据配置和自身条件,拆分内部配置好的Configuration(前面赋值了的对应配置文件，内包含需要同步的数据的全部信息）
3. 拆分之后会返回一个Configuration的List，每个Configuration代表原先总配置文件中需要同步的数据的一部分。并加入到总配置文件存储，为后续调用提供配置的支持。
4. 注意必须先切分Reader，因为Writer是根据Reader切分后的数目进行切分的。

```java
    private int split() {
        this.adjustChannelNumber();
        //获取切分参考数，设置管道数量
        if (this.needChannelNumber <= 0) {
            this.needChannelNumber = 1;
        }
        //切分读插件，返回包含各个切分后的读插件配置列表，后续一个服务使用一个
        List<Configuration> readerTaskConfigs = this
                .doReaderSplit(this.needChannelNumber);
        //读插件切分个数
        int taskNumber = readerTaskConfigs.size();
        //根据读插件的切分个数切分写插件，返回包含各个切分后的写入配置列表
        List<Configuration> writerTaskConfigs = this
                .doWriterSplit(taskNumber);
        //获取job.content[0].transformer的配置，不懂是啥，传输配置？
        List<Configuration> transformerList = this.configuration.getListConfiguration(CoreConstant.DATAX_JOB_CONTENT_TRANSFORMER);

        LOG.debug("transformer configuration: "+ JSON.toJSONString(transformerList));
        //合并读任务配置、写任务配置、transformer配置
        List<Configuration> contentConfig = mergeReaderAndWriterTaskConfigs(
                readerTaskConfigs, writerTaskConfigs, transformerList);
        //将配置后的列表赋值给总配置文件this.configuration，方便后续调用。
        this.configuration.set(CoreConstant.DATAX_JOB_CONTENT, contentConfig);

        return contentConfig.size();
    }
复制代码
```

此处以mysql的Reader为例

```java
@Override
        public List<Configuration> split(int adviceNumber) {
            return this.commonRdbmsReaderJob.split(this.originalConfig, adviceNumber);
        }
复制代码
```

mysqlReader调用的其实是commonRdbmsReaderJob的split方法，也就是框架本身通用的方法。具体看下方代码注释

```java
    public static List<Configuration> doSplit(
            Configuration originalSliceConfig, int adviceNumber) {
        boolean isTableMode = originalSliceConfig.getBool(Constant.IS_TABLE_MODE).booleanValue();
        int eachTableShouldSplittedNumber = -1;
        if (isTableMode) {
            // adviceNumber这里是channel数量大小, 即datax并发task数量
            // eachTableShouldSplittedNumber是单表应该切分的份数, 向上取整可能和adviceNumber没有比例关系了已经
            eachTableShouldSplittedNumber = calculateEachTableShouldSplittedNumber(
                    adviceNumber, originalSliceConfig.getInt(Constant.TABLE_NUMBER_MARK));
        }
        //获取配置文件中列的信息
        String column = originalSliceConfig.getString(Key.COLUMN);
        //获取配置文件中where的配置
        String where = originalSliceConfig.getString(Key.WHERE, null);
        //获取配置文件中所有连接
        List<Object> conns = originalSliceConfig.getList(Constant.CONN_MARK, Object.class);

        List<Configuration> splittedConfigs = new ArrayList<Configuration>();
        //遍历所有连接
        for (int i = 0, len = conns.size(); i < len; i++) {
            Configuration sliceConfig = originalSliceConfig.clone();
            //获取对应连接的配置
            Configuration connConf = Configuration.from(conns.get(i).toString());
            String jdbcUrl = connConf.getString(Key.JDBC_URL);
            sliceConfig.set(Key.JDBC_URL, jdbcUrl);

            // 抽取 jdbcUrl 中的 ip/port 进行资源使用的打标，以提供给 core 做有意义的 shuffle 操作
            sliceConfig.set(CommonConstant.LOAD_BALANCE_RESOURCE_MARK, DataBaseType.parseIpFromJdbcUrl(jdbcUrl));

            sliceConfig.remove(Constant.CONN_MARK);

            Configuration tempSlice;

            // 说明是配置的 table 方式
            if (isTableMode) {
                // 已在之前进行了扩展和`处理，可以直接使用
                List<String> tables = connConf.getList(Key.TABLE, String.class);

                Validate.isTrue(null != tables && !tables.isEmpty(), "您读取数据库表配置错误.");

                String splitPk = originalSliceConfig.getString(Key.SPLIT_PK, null);

                //最终切分份数不一定等于 eachTableShouldSplittedNumber
                boolean needSplitTable = eachTableShouldSplittedNumber > 1
                        && StringUtils.isNotBlank(splitPk);
                if (needSplitTable) {
                    if (tables.size() == 1) {
                        //原来:如果是单表的，主键切分num=num*2+1
                        // splitPk is null这类的情况的数据量本身就比真实数据量少很多, 和channel大小比率关系时，不建议考虑
                        //eachTableShouldSplittedNumber = eachTableShouldSplittedNumber * 2 + 1;// 不应该加1导致长尾
                        
                        //考虑其他比率数字?(splitPk is null, 忽略此长尾)
                        //eachTableShouldSplittedNumber = eachTableShouldSplittedNumber * 5;

                        //为避免导入hive小文件 默认基数为5，可以通过 splitFactor 配置基数
                        // 最终task数为(channel/tableNum)向上取整*splitFactor
                        Integer splitFactor = originalSliceConfig.getInt(Key.SPLIT_FACTOR, Constant.SPLIT_FACTOR);
                        eachTableShouldSplittedNumber = eachTableShouldSplittedNumber * splitFactor;
                    }
                    // 尝试对每个表，切分为eachTableShouldSplittedNumber 份
                    for (String table : tables) {
                        tempSlice = sliceConfig.clone();
                        tempSlice.set(Key.TABLE, table);
                        //最关键的单表拆分，其实是根据splitpk(主键)添加where条件，如果没有配置splitpk则不必进行单表拆分
                        List<Configuration> splittedSlices = SingleTableSplitUtil
                                .splitSingleTable(tempSlice, eachTableShouldSplittedNumber);

                        splittedConfigs.addAll(splittedSlices);
                    }
                } else {//
                    for (String table : tables) {
                        tempSlice = sliceConfig.clone();
                        tempSlice.set(Key.TABLE, table);
                        String queryColumn = HintUtil.buildQueryColumn(jdbcUrl, table, column);
                        tempSlice.set(Key.QUERY_SQL, SingleTableSplitUtil.buildQuerySql(queryColumn, table, where));
                        splittedConfigs.add(tempSlice);
                    }
                }
            } else {
                // 说明是配置的 querySql 方式，如果是sql模式，则比较简单，几句sql，几个分割
                List<String> sqls = connConf.getList(Key.QUERY_SQL, String.class);

                // TODO 是否check 配置为多条语句？？
                for (String querySql : sqls) {
                    tempSlice = sliceConfig.clone();
                    tempSlice.set(Key.QUERY_SQL, querySql);
                    splittedConfigs.add(tempSlice);
                }
            }

        }

        return splittedConfigs;
    }
复制代码
```

从上方程序中和注解中不难发现，split方法内部会判断是否需要进行单表切分，当满足并发数要求较高，并且配置了splitPk(表分割的主键)参数时，则要求进行单表拆分，拆分个数前面已经经过计算得出，不然就是几张表开启几个并发，下方是单表拆分源码：主要是通过主键，表名，列名，where条件，组合成一句sql后，再通过往sql后加where条件，划分主键范围，再把分割后的sql传给对应配置文件类Configuration并形成列表，作为每个划分出来的任务的配置依据。

```java
public static List<Configuration> splitSingleTable(
            Configuration configuration, int adviceNum) {
        List<Configuration> pluginParams = new ArrayList<Configuration>();
        List<String> rangeList;
        String splitPkName = configuration.getString(Key.SPLIT_PK);
        String column = configuration.getString(Key.COLUMN);
        String table = configuration.getString(Key.TABLE);
        String where = configuration.getString(Key.WHERE, null);
        boolean hasWhere = StringUtils.isNotBlank(where);
        
        if (DATABASE_TYPE == DataBaseType.Oracle) {
            rangeList = genSplitSqlForOracle(splitPkName, table, where,
                    configuration, adviceNum);
        } else {
            Pair<Object, Object> minMaxPK = getPkRange(configuration);
            if (null == minMaxPK) {
                throw DataXException.asDataXException(DBUtilErrorCode.ILLEGAL_SPLIT_PK,
                        "根据切分主键切分表失败. DataX 仅支持切分主键为一个,并且类型为整数或者字符串类型. 请尝试使用其他的切分主键或者联系 DBA 进行处理.");
            }

            configuration.set(Key.QUERY_SQL, buildQuerySql(column, table, where));
            if (null == minMaxPK.getLeft() || null == minMaxPK.getRight()) {
                // 切分后获取到的start/end 有 Null 的情况
                pluginParams.add(configuration);
                return pluginParams;
            }

            boolean isStringType = Constant.PK_TYPE_STRING.equals(configuration
                    .getString(Constant.PK_TYPE));
            boolean isLongType = Constant.PK_TYPE_LONG.equals(configuration
                    .getString(Constant.PK_TYPE));

            //进行逐渐切分，找到临界值
            if (isStringType) {
                rangeList = RdbmsRangeSplitWrap.splitAndWrap(
                        String.valueOf(minMaxPK.getLeft()),
                        String.valueOf(minMaxPK.getRight()), adviceNum,
                        splitPkName, "'", DATABASE_TYPE);
            } else if (isLongType) {
                rangeList = RdbmsRangeSplitWrap.splitAndWrap(
                        new BigInteger(minMaxPK.getLeft().toString()),
                        new BigInteger(minMaxPK.getRight().toString()),
                        adviceNum, splitPkName);
            } else {
                throw DataXException.asDataXException(DBUtilErrorCode.ILLEGAL_SPLIT_PK,
                        "您配置的切分主键(splitPk) 类型 DataX 不支持. DataX 仅支持切分主键为一个,并且类型为整数或者字符串类型. 请尝试使用其他的切分主键或者联系 DBA 进行处理.");
            }
        }
        String tempQuerySql;
        //存放切分后的所有sql，所有sql整合在一起是一张表的全部数据
        List<String> allQuerySql = new ArrayList<String>();

        if (null != rangeList && !rangeList.isEmpty()) {
            for (String range : rangeList) {
                Configuration tempConfig = configuration.clone();
                //此处进行主键切分获得range，并把范围添加到where条件后，组成新的sql
                tempQuerySql = buildQuerySql(column, table, where)
                        + (hasWhere ? " and " : " where ") + range;

                allQuerySql.add(tempQuerySql);
                tempConfig.set(Key.QUERY_SQL, tempQuerySql);
                pluginParams.add(tempConfig);
            }
        } else {
            Configuration tempConfig = configuration.clone();
            tempQuerySql = buildQuerySql(column, table, where)
                    + (hasWhere ? " and " : " where ")
                    + String.format(" %s IS NOT NULL", splitPkName);
            //添加到sql集合中
            allQuerySql.add(tempQuerySql);
            tempConfig.set(Key.QUERY_SQL, tempQuerySql);
            pluginParams.add(tempConfig);
        }
        Configuration tempConfig = configuration.clone();
        tempQuerySql = buildQuerySql(column, table, where)
                + (hasWhere ? " and " : " where ")
                + String.format(" %s IS NULL", splitPkName);
        //添加到sql集合中
        allQuerySql.add(tempQuerySql);

        tempConfig.set(Key.QUERY_SQL, tempQuerySql);
        pluginParams.add(tempConfig);
        
        return pluginParams;
    }
```

总结：

1. table模式 ：当没有配置splitPk时，任务数量与table数量一样.比如table配置了2个(table1, table2) ，则至少开启两个任务，分别负责table1和table2。
2. table模式 ：配置splitPk时，配合channel一起使用。任务数 = (向上取整)(channel/table数量) ,当任务数 > 1 时会重新切分任务，最终任务数 = 任务数 * 5 + 1 。配置的splitPk会被整合进入Configuration中的querySql中，例如配置了id，querySql中会加上id>1 and id<5这样的条件，做到分割的效果。
3. querySql模式 ：有几条querySql ， 生成相同数量的任务配置。
4. **writer与Reader类似，writer只有table模式，单表时，保证任务数目与Reader相同，多表时任务数等于表数，此时不一定与Reader的任务数目相同，因此可能会报错**
5. **提醒：上方是mysql的切分策略，适用于支持sql语句的数据库，不代表所有数据源的切分策略**

# 3 JobContainer任务调度方法：schedule

  进入schedule方法，在执行任务前首先先要获取，task任务的数量（也就是前面切分出来的list的size），接着获取每个taskgroup运行的task数以及需要的taskgroup的数量。

```java
        //每个taskgroup运行的task数量
        int channelsPerTaskGroup = this.configuration.getInt(
                CoreConstant.DATAX_CORE_CONTAINER_TASKGROUP_CHANNEL, 5);
        //task总数
        int taskNumber = this.configuration.getList(
                CoreConstant.DATAX_JOB_CONTENT).size();
        //taskgroup数量
        this.needChannelNumber = Math.min(this.needChannelNumber, taskNumber);
复制代码
```

  接着通过获取配置信息得到每个taskGroup需要运行哪些tasks任务，确定数量之后，平均分配具体的task到具体的taskGroup，创建任务执行器，并执行任务。

```java
        //平均分配具体的task到具体的taskGroup。
        List<Configuration> taskGroupConfigs = JobAssignUtil.assignFairly(this.configuration,
                this.needChannelNumber, channelsPerTaskGroup);

        LOG.info("Scheduler starts [{}] taskGroups.", taskGroupConfigs.size());

        ExecuteMode executeMode = null;
        AbstractScheduler scheduler;
        try {
            //创建执行器，用于监控啥的
        	executeMode = ExecuteMode.STANDALONE;
            scheduler = initStandaloneScheduler(this.configuration);

            //设置 executeMode
            for (Configuration taskGroupConfig : taskGroupConfigs) {
                taskGroupConfig.set(CoreConstant.DATAX_CORE_CONTAINER_JOB_MODE, executeMode.getValue());
            }
            
            //...省略其他代码
            
            //启动任务
            scheduler.schedule(taskGroupConfigs);
        } catch (Exception e) {
            //...省略其他代码
        }
```

  接下来配置完一定参数和异常排除检查后，scheduler.schedule方法会调用父类AbstractScheduler的startAllTaskGroup方法，启动所有的taskgroup。

```java
    public void startAllTaskGroup(List<Configuration> configurations) {
        //启动一个线程池，大小为taskGroup的数量
        this.taskGroupContainerExecutorService = Executors
                .newFixedThreadPool(configurations.size());

        for (Configuration taskGroupConfiguration : configurations) {
            //建立一个TaskGroupContainerRunner线程，
            TaskGroupContainerRunner taskGroupContainerRunner = newTaskGroupContainerRunner(taskGroupConfiguration);
            //开启线程运行taskgroup
            this.taskGroupContainerExecutorService.execute(taskGroupContainerRunner);
        }

        this.taskGroupContainerExecutorService.shutdown();
    }
```

  线程启动后，会启动TaskGroupContainer来运行一个taskgroup里的全部任务

```java
	@Override
	public void run() {
		try {
		    //设置线程名字
            Thread.currentThread().setName(
                    String.format("taskGroup-%d", this.taskGroupContainer.getTaskGroupId()));
            //启动TaskGroupContainer
            this.taskGroupContainer.start();
			this.state = State.SUCCEEDED;
		} catch (Throwable e) {
			this.state = State.FAILED;
			throw DataXException.asDataXException(
					FrameworkErrorCode.RUNTIME_ERROR, e);
		}
	}
```

# 4 TaskGroupContainer

  接着TaskGroupContainer启动，TaskGroupContainer启动主要执行两个部分：

1. 初始化task执行相关的状态信息，分别是taskId与其对应的Congifuration的map映射集合、待运行的任务队列taskQueue、运行失败任务taskFailedExecutorMap、正在执行的任务集合runTasks等
2. 进入循环，循环判断各个任务执行的状态。

- 判断是否有失败的task，如果有则放入taskFailedExecutorMap中，并查看当前的执行是否支持重跑和failOver，如果支持则重新放回执行队列中；如果没有失败，则标记任务执行成功，并从状态轮询map中移除
- 如果发现有失败的任务，则向容器汇报状态，抛出异常
- 查看当前执行队列的长度，如果发现执行队列还有通道，则构建TaskExecutor加入执行队列，并从待运行移除
- 检查执行队列和所有的任务状态，如果所有的任务都执行成功，则汇报taskGroup的状态并从循环中退出
- 检查当前时间是否超过汇报时间，如果超过了，就需要向全局汇报当前状态
- 所有任务成功之后，向全局汇报当前的任务状态。

  具体看下方源码注解。

```java
public class TaskGroupContainer extends AbstractContainer {
    private static final Logger LOG = LoggerFactory
            .getLogger(TaskGroupContainer.class);
    //当前taskGroup所属jobId
    private long jobId;
    //当前taskGroupId
    private int taskGroupId;
    //使用的channel类
    private String channelClazz;
    //task收集器使用的类
    private String taskCollectorClass;

    private TaskMonitor taskMonitor = TaskMonitor.getInstance();

    public TaskGroupContainer(Configuration configuration) {
        super(configuration);
        initCommunicator(configuration);    //初始化通信器
        this.jobId = this.configuration.getLong(
                CoreConstant.DATAX_CORE_CONTAINER_JOB_ID);
        //core.container.taskGroup.id 任务组id
        this.taskGroupId = this.configuration.getInt(
                CoreConstant.DATAX_CORE_CONTAINER_TASKGROUP_ID);
        //管道实现类 core.transport.channel.class
        this.channelClazz = this.configuration.getString(
                CoreConstant.DATAX_CORE_TRANSPORT_CHANNEL_CLASS);
        //任务收集器 core.statistics.collector.plugin.taskClass
        this.taskCollectorClass = this.configuration.getString(
                CoreConstant.DATAX_CORE_STATISTICS_COLLECTOR_PLUGIN_TASKCLASS);
    }
    //...
    @Override
    public void start() {
        try {
            /**
             * 状态check时间间隔，较短，可以把任务及时分发到对应channel中
             * core.container.taskGroup.sleepInterval
             */
            int sleepIntervalInMillSec = this.configuration.getInt(
                    CoreConstant.DATAX_CORE_CONTAINER_TASKGROUP_SLEEPINTERVAL, 100);
            /**
             * 状态汇报时间间隔，稍长，避免大量汇报
             * core.container.taskGroup.reportInterval
             */
            long reportIntervalInMillSec = this.configuration.getLong(
                    CoreConstant.DATAX_CORE_CONTAINER_TASKGROUP_REPORTINTERVAL,
                    10000);
            /**
             * 2分钟汇报一次性能统计
             */
            //core.container.taskGroup.channel
            // 获取channel数目
            int channelNumber = this.configuration.getInt(
                    CoreConstant.DATAX_CORE_CONTAINER_TASKGROUP_CHANNEL);
            //最大重试次数 core.container.task.failOver.maxRetryTimes 默认1次
            int taskMaxRetryTimes = this.configuration.getInt(
                    CoreConstant.DATAX_CORE_CONTAINER_TASK_FAILOVER_MAXRETRYTIMES, 1);
            //任务组重试间隔时间 core.container.task.failOver.retryIntervalInMsec
            long taskRetryIntervalInMsec = this.configuration.getLong(
                    CoreConstant.DATAX_CORE_CONTAINER_TASK_FAILOVER_RETRYINTERVALINMSEC, 10000);
            //core.container.task.failOver.maxWaitInMsec
            long taskMaxWaitInMsec = this.configuration.getLong(CoreConstant.DATAX_CORE_CONTAINER_TASK_FAILOVER_MAXWAITINMSEC, 60000);
            //获取当前任务组所有任务配置
            List<Configuration> taskConfigs = this.configuration
                    .getListConfiguration(CoreConstant.DATAX_JOB_CONTENT);
            int taskCountInThisTaskGroup = taskConfigs.size();
            LOG.info(String.format(
                    "taskGroupId=[%d] start [%d] channels for [%d] tasks.",
                    this.taskGroupId, channelNumber, taskCountInThisTaskGroup));
            //任务组注册通信器
            this.containerCommunicator.registerCommunication(taskConfigs);
            //taskId与task配置
            Map<Integer, Configuration> taskConfigMap = buildTaskConfigMap(taskConfigs);
            List<Configuration> taskQueue = buildRemainTasks(taskConfigs); //待运行task列表
            Map<Integer, TaskExecutor> taskFailedExecutorMap = new HashMap<Integer, TaskExecutor>();            //taskId与上次失败实例
            List<TaskExecutor> runTasks = new ArrayList<TaskExecutor>(channelNumber); //正在运行task
            Map<Integer, Long> taskStartTimeMap = new HashMap<Integer, Long>(); //任务开始时间
            long lastReportTimeStamp = 0;
            Communication lastTaskGroupContainerCommunication = new Communication();
           //这里开始进入循环作业
            while (true) {
               //1.判断task状态
               boolean failedOrKilled = false;
               Map<Integer, Communication> communicationMap = containerCommunicator.getCommunicationMap();  //任务id对应通信器,用来收集任务作业情况
               for(Map.Entry<Integer, Communication> entry : communicationMap.entrySet()){
                  Integer taskId = entry.getKey();
                  Communication taskCommunication = entry.getValue();
                    if(!taskCommunication.isFinished()){
                        continue;   //当前任务未结束,继续执行
                    }
                    //已经结束的任务,从正在运行的任务集合中移除
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
                    lastTaskGroupContainerCommunication = reportTaskGroupCommunication(
                            lastTaskGroupContainerCommunication, taskCountInThisTaskGroup);

                    throw DataXException.asDataXException(
                            FrameworkErrorCode.PLUGIN_RUNTIME_ERROR, lastTaskGroupContainerCommunication.getThrowable());
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
                    runTasks.add(taskExecutor); //继续添加到运行的任务集合
                    //上面，增加task到runTasks列表，因此在monitor里注册。
                    taskMonitor.registerTask(taskId, this.containerCommunicator.getCommunication(taskId));
                  //刚刚已经添加了task，这里把任务id从失败map移除
                    taskFailedExecutorMap.remove(taskId);
                    LOG.info("taskGroup[{}] taskId[{}] attemptCount[{}] is started",
                            this.taskGroupId, taskId, attemptCount);
                }

                //4.任务列表为空，executor已结束, 搜集状态为success--->成功
                if (taskQueue.isEmpty() && isAllTaskDone(runTasks) && containerCommunicator.collectState() == State.SUCCEEDED) {
                   // 成功的情况下，也需要汇报一次。否则在任务结束非常快的情况下，采集的信息将会不准确
                    lastTaskGroupContainerCommunication = reportTaskGroupCommunication(
                            lastTaskGroupContainerCommunication, taskCountInThisTaskGroup);
                    LOG.info("taskGroup[{}] completed it's tasks.", this.taskGroupId);
                    break;
                }
                // 5.如果当前时间已经超出汇报时间的interval，那么我们需要马上汇报
                long now = System.currentTimeMillis();
                if (now - lastReportTimeStamp > reportIntervalInMillSec) {
                    lastTaskGroupContainerCommunication = reportTaskGroupCommunication(
                            lastTaskGroupContainerCommunication, taskCountInThisTaskGroup);
                    lastReportTimeStamp = now;
                    //taskMonitor对于正在运行的task，每reportIntervalInMillSec进行检查
                    for(TaskExecutor taskExecutor:runTasks){   taskMonitor.report(taskExecutor.getTaskId(),this.containerCommunicator.getCommunication(taskExecutor.getTaskId()));
                    }

                }
                Thread.sleep(sleepIntervalInMillSec);
            }

            //6.最后还要汇报一次
            reportTaskGroupCommunication(lastTaskGroupContainerCommunication, taskCountInThisTaskGroup);
        } catch (Throwable e) {
            Communication nowTaskGroupContainerCommunication = this.containerCommunicator.collect();
            if (nowTaskGroupContainerCommunication.getThrowable() == null) {
                nowTaskGroupContainerCommunication.setThrowable(e);
            }
            nowTaskGroupContainerCommunication.setState(State.FAILED);
            this.containerCommunicator.report(nowTaskGroupContainerCommunication);
            throw DataXException.asDataXException(
                    FrameworkErrorCode.RUNTIME_ERROR, e);
        }finally {
            if(!PerfTrace.getInstance().isJob()){
                //最后打印cpu的平均消耗，GC的统计
                VMInfo vmInfo = VMInfo.getVmInfo();
                if (vmInfo != null) {
                    vmInfo.getDelta(false);
                    LOG.info(vmInfo.totalString());
                }
                LOG.info(PerfTrace.getInstance().summarizeNoException());
            }
        }
    }
    
}
```

# 5 TaskExecute

  TaskExecute是TaskGroupContainer的内部类，是一个基本单位task的具体执行管理的地方。

1. 初始化一些信息，比如初始化读写线程，实例化存储读数据的管道，获取transformer的参数等。
2. 初始化之后开启读写线程，正式开始单个task（一部分数据同步任务）正式启动。
3. 读操作（ReaderRunner）利用jdbc，把从数据库中读出来的每条数据封装为一个个Record放入Channel中,当数据读完时，结束的时候会写入一个TerminateRecord标识。
4. 写操作（WriterRunner）不断从Channel中读取Record，直到读到TerminateRecord标识数据以取完，把数据全部读入数据库中

```java
class TaskExecutor {
    private Configuration taskConfig;   //当前任务配置项
    private Channel channel;    //管道 用于缓存读出来的数据
    private Thread readerThread;    //读线程
    private Thread writerThread;    //写线程
    private ReaderRunner readerRunner;
    private WriterRunner writerRunner;

    /**
     * 该处的taskCommunication在多处用到：
     * 1. channel
     * 2. readerRunner和writerRunner
     * 3. reader和writer的taskPluginCollector
     */
    private Communication taskCommunication;

    public TaskExecutor(Configuration taskConf, int attemptCount) {
        // 获取该taskExecutor的配置
        this.taskConfig = taskConf;
        //...
        /**
         * 由taskId得到该taskExecutor的Communication
         * 要传给readerRunner和writerRunner，同时要传给channel作统计用
         */
        this.taskCommunication = containerCommunicator
                .getCommunication(taskId);
        //实例化存储读数据的管道
        this.channel = ClassUtil.instantiate(channelClazz,
                Channel.class, configuration);
        this.channel.setCommunication(this.taskCommunication);
        /**
         * 获取transformer的参数
         */
        List<TransformerExecution> transformerInfoExecs = TransformerUtil.buildTransformerInfo(taskConfig);
        /**
         * 生成writerThread
         */
        writerRunner = (WriterRunner) generateRunner(PluginType.WRITER);
        this.writerThread = new Thread(writerRunner,
                String.format("%d-%d-%d-writer",
                        jobId, taskGroupId, this.taskId));
        //通过设置thread的contextClassLoader，即可实现同步和主程序不通的加载器
        this.writerThread.setContextClassLoader(LoadUtil.getJarLoader(
                PluginType.WRITER, this.taskConfig.getString(
                        CoreConstant.JOB_WRITER_NAME)));
        /**
         * 生成readerThread
         */
        readerRunner = (ReaderRunner) generateRunner(PluginType.READER,transformerInfoExecs);
        this.readerThread = new Thread(readerRunner,
                String.format("%d-%d-%d-reader",
                        jobId, taskGroupId, this.taskId));
        /**
         * 通过设置thread的contextClassLoader，即可实现同步和主程序不通的加载器
         */
        this.readerThread.setContextClassLoader(LoadUtil.getJarLoader(
                PluginType.READER, this.taskConfig.getString(
                        CoreConstant.JOB_READER_NAME)));
    }

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
}
```

   **ReaderRunner（WriterRunner类似）**

1. ReaderRunner由Taskexcute的generateRunner进行初始化。
2. ReaderRunner的主要是从调用对应的plugin的task内部类，调用各个插件各自的init，prepare和startRead方法，开始进行数据库数据的读入。

```java
public void run() {
        assert null != this.recordSender;

        Reader.Task taskReader = (Reader.Task) this.getPlugin();

        //统计waitWriterTime，并且在finally才end。
        PerfRecord channelWaitWrite = new PerfRecord(getTaskGroupId(), getTaskId(), PerfRecord.PHASE.WAIT_WRITE_TIME);
        try {
            channelWaitWrite.start();

            LOG.debug("task reader starts to do init ...");
            PerfRecord initPerfRecord = new PerfRecord(getTaskGroupId(), getTaskId(), PerfRecord.PHASE.READ_TASK_INIT);
            initPerfRecord.start();
            taskReader.init();
            initPerfRecord.end();

            LOG.debug("task reader starts to do prepare ...");
            PerfRecord preparePerfRecord = new PerfRecord(getTaskGroupId(), getTaskId(), PerfRecord.PHASE.READ_TASK_PREPARE);
            preparePerfRecord.start();
            taskReader.prepare();
            preparePerfRecord.end();

            LOG.debug("task reader starts to read ...");
            PerfRecord dataPerfRecord = new PerfRecord(getTaskGroupId(), getTaskId(), PerfRecord.PHASE.READ_TASK_DATA);
            dataPerfRecord.start();
            taskReader.startRead(recordSender);
            recordSender.terminate();

            dataPerfRecord.addCount(CommunicationTool.getTotalReadRecords(super.getRunnerCommunication()));
            dataPerfRecord.addSize(CommunicationTool.getTotalReadBytes(super.getRunnerCommunication()));
            dataPerfRecord.end();

            LOG.debug("task reader starts to do post ...");
            PerfRecord postPerfRecord = new PerfRecord(getTaskGroupId(), getTaskId(), PerfRecord.PHASE.READ_TASK_POST);
            postPerfRecord.start();
            taskReader.post();
            postPerfRecord.end();
            // automatic flush
            // super.markSuccess(); 这里不能标记为成功，成功的标志由 writerRunner 来标志（否则可能导致 reader 先结束，而 writer 还没有结束的严重 bug）
        } catch (Throwable e) {
            LOG.error("Reader runner Received Exceptions:", e);
            super.markFail(e);
        } finally {
            LOG.debug("task reader starts to do destroy ...");
            PerfRecord desPerfRecord = new PerfRecord(getTaskGroupId(), getTaskId(), PerfRecord.PHASE.READ_TASK_DESTROY);
            desPerfRecord.start();
            super.destroy();
            desPerfRecord.end();

            channelWaitWrite.end(super.getRunnerCommunication().getLongCounter(CommunicationTool.WAIT_WRITER_TIME));

            long transformerUsedTime = super.getRunnerCommunication().getLongCounter(CommunicationTool.TRANSFORMER_USED_TIME);
            if (transformerUsedTime > 0) {
                PerfRecord transformerRecord = new PerfRecord(getTaskGroupId(), getTaskId(), PerfRecord.PHASE.TRANSFORMER_TIME);
                transformerRecord.start();
                transformerRecord.end(transformerUsedTime);
            }
        }
    }
```

  以mysql为例子，mysqlReader会通过jdbc读取数据，并通过senderRecord以Record的形式通过Channel转发给对应的Writer，代码如下

```java
public void startRead(Configuration readerSliceConfig, RecordSender recordSender, TaskPluginCollector taskPluginCollector, int fetchSize) {
            String querySql = readerSliceConfig.getString("querySql");
            String table = readerSliceConfig.getString("table");
            PerfTrace.getInstance().addTaskDetails(this.taskId, table + "," + this.basicMsg);
            LOG.info("Begin to read record by Sql: [{}\n] {}.", querySql, this.basicMsg);
            PerfRecord queryPerfRecord = new PerfRecord(this.taskGroupId, this.taskId, PHASE.SQL_QUERY);
            queryPerfRecord.start();
            Connection conn = DBUtil.getConnection(this.dataBaseType, this.jdbcUrl, this.username, this.password);
            DBUtil.dealWithSessionConfig(conn, readerSliceConfig, this.dataBaseType, this.basicMsg);
            int columnNumber = false;
            ResultSet rs = null;

            try {
                rs = DBUtil.query(conn, querySql, fetchSize);
                queryPerfRecord.end();
                ResultSetMetaData metaData = rs.getMetaData();
                int columnNumber = metaData.getColumnCount();
                PerfRecord allResultPerfRecord = new PerfRecord(this.taskGroupId, this.taskId, PHASE.RESULT_NEXT_ALL);
                allResultPerfRecord.start();
                long rsNextUsedTime = 0L;

                for(long lastTime = System.nanoTime(); rs.next(); lastTime = System.nanoTime()) {
                    rsNextUsedTime += System.nanoTime() - lastTime;
                    //把记录通过recordSender传输给channel
                    this.transportOneRecord(recordSender, rs, metaData, columnNumber, this.mandatoryEncoding, taskPluginCollector);
                }

                allResultPerfRecord.end(rsNextUsedTime);
                LOG.info("Finished read record by Sql: [{}\n] {}.", querySql, this.basicMsg);
            } catch (Exception var20) {
                throw RdbmsException.asQueryException(this.dataBaseType, var20, querySql, table, this.username);
            } finally {
                DBUtil.closeDBResources((Statement)null, conn);
            }
        }
```

  Writer会往Channel里获取Record存入目标数据库中。