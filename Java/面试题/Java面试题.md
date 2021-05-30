# MyBatis 面试题

    什么是 Mybatis？
    Mybaits 的优点：
    MyBatis 框架的缺点：
    MyBatis 框架适用场合：
    MyBatis与Hibernate有哪些不同？
    #{}和${}的区别是什么？
    当实体类中的属性名和表中的字段名不一样 ，怎么办 ？
    模糊查询 like 语句该怎么写?
    通常一个 Xml 映射文件，都会写一个 Dao 接口与之对应，请问，这个 Dao 接口的工作原理是什么？Dao 接口里的方法，参数不同时，方法能重载吗？
    Mybatis 是如何进行分页的？分页插件的原理是什么？
    Mybatis是如何将sql执行结果封装为目标对象并返回的？都有哪些映射形式？
    如何执行批量插入?
    如何获取自动生成的(主)键值?
    在 mapper 中如何传递多个参数?
    Mybatis 动态 sql 有什么用？执行原理？有哪些动态 sql？
    Xml 映射文件中，除了常见的 select、insert、updae、delete 标签之外，还有哪些标签？
    Mybatis 的 Xml 映射文件中，不同的 Xml 映射文件，id 是否可以重复？
    为什么说 Mybatis 是半自动 ORM 映射工具？它与全自动的区别在哪里？
    一对一、一对多的关联查询 ？
    MyBatis 实现一对一有几种方式?具体怎么操作的？
    MyBatis 实现一对多有几种方式,怎么操作的？
    Mybatis 是否支持延迟加载？如果支持，它的实现原理是什么？
    Mybatis 的一级、二级缓存
    什么是 MyBatis 的接口绑定？有哪些实现方式？
    使用 MyBatis 的 mapper 接口调用时有哪些要求？
    Mapper 编写有哪几种方式？
    简述 Mybatis 的插件运行原理，以及如何编写一个插件。

# ZooKeeper 面试题

    ZooKeeper 面试题？
    ZooKeeper 提供了什么？
    Zookeeper 文件系统
    ZAB 协议？
    四种类型的数据节点 Znode
    Zookeeper Watcher 机制 – 数据变更通知
    客户端注册 Watcher 实现
    服务端处理 Watcher 实现
    客户端回调 Watcher
    ACL 权限控制机制
    Chroot 特性
    会话管理
    服务器角色
    Zookeeper 下 Server 工作状态
    数据同步
    zookeeper 是如何保证事务的顺序一致性的？
    分布式集群中为什么会有 Master？
    zk 节点宕机如何处理？
    zookeeper 负载均衡和 nginx 负载均衡区别
    Zookeeper 有哪几种几种部署模式？
    集群最少要几台机器，集群规则是怎样的?
    集群支持动态添加机器吗？
    Zookeeper 对节点的 watch监听通知是永久的吗？为什么不是永久的?
    Zookeeper 的 java 客户端都有哪些？
    chubby 是什么，和 zookeeper 比你怎么看？
    说几个 zookeeper 常用的命令。
    ZAB 和 Paxos 算法的联系与区别？
    Zookeeper 的典型应用场景

# Dubbo 面试题

    为什么要用 Dubbo？
    Dubbo 的整体架构设计有哪些分层?
    默认使用的是什么通信框架，还有别的选择吗?
    服务调用是阻塞的吗？
    一般使用什么注册中心？还有别的选择吗？
    默认使用什么序列化框架，你知道的还有哪些？
    服务提供者能实现失效踢出是什么原理？
    服务上线怎么不影响旧版本？
    如何解决服务调用链过长的问题？
    说说核心的配置有哪些？
    Dubbo 推荐用什么协议？
    同一个服务多个注册的情况下可以直连某一个服务吗？
    画一画服务注册与发现的流程图？
    Dubbo 集群容错有几种方案？
    Dubbo 服务降级，失败重试怎么做？
    Dubbo 使用过程中都遇到了些什么问题？
    Dubbo Monitor 实现原理？
    Dubbo 用到哪些设计模式？
    Dubbo 配置文件是如何加载到 Spring 中的？
    Dubbo SPI 和 Java SPI 区别？
    Dubbo 支持分布式事务吗？
    Dubbo 可以对结果进行缓存吗？
    服务上线怎么兼容旧版本？
    Dubbo 必须依赖的包有哪些？
    Dubbo telnet 命令能做什么？
    Dubbo 支持服务降级吗？
    Dubbo 如何优雅停机？
    Dubbo 和 Dubbox 之间的区别？
    Dubbo 和 Spring Cloud 的区别？
    你还了解别的分布式框架吗？

# Elasticsearch 面试题

    elasticsearch 了解多少，说说你们公司 es 的集群架构，索引数据大小，分片有多少，以及一些调优手段 。
    elasticsearch 的倒排索引是什么
    elasticsearch 索引数据多了怎么办，如何调优，部署
    elasticsearch 是如何实现 master 选举的
    详细描述一下 Elasticsearch 索引文档的过程
    详细描述一下 Elasticsearch 搜索的过程？
    Elasticsearch 在部署时，对 Linux 的设置有哪些优化方法
    lucence 内部结构是什么？
    Elasticsearch 是如何实现 Master 选举的？
    Elasticsearch 中的节点（比如共 20 个），其中的 10 个选了一个 master，另外 10 个选了另一个 master，怎么办？
    客户端在和集群连接时，如何选择特定的节点执行请求的？
    详细描述一下 Elasticsearch 索引文档的过程。
    详细描述一下 Elasticsearch 更新和删除文档的过程。
    详细描述一下 Elasticsearch 搜索的过程
    在 Elasticsearch 中，是怎么根据一个词找到对应的倒排索引的？
    Elasticsearch 在部署时，对 Linux 的设置有哪些优化方法？
    对于 GC 方面，在使用 Elasticsearch 时要注意什么？
    Elasticsearch 对于大数据量（上亿量级）的聚合如何实现？
    在并发情况下，Elasticsearch 如果保证读写一致？
    如何监控 Elasticsearch 集群状态？
    介绍下你们电商搜索的整体技术架构
    介绍一下你们的个性化搜索方案？
    是否了解字典树？
    拼写纠错是如何实现的？

# Memcached 面试题

    Memcached 是什么，有什么作用？
    Memcached服务分布式集群如何实现？
    Memcached服务特点及工作原理是什么？
    简述Memcached内存管理机制原理？
    memcached是怎么工作的？
    memcached最大的优势是什么？
    memcached和MySQL的query
    memcached 和服务器的 local cache（比如 PHP 的 APC、mmap 文件等）相比，有什么优缺点？
    memcached的cache机制是怎样的？
    memcached如何实现冗余机制？
    memcached如何处理容错的？
    如何将memcached中item批量导入导出？
    如果缓存数据在导出导入之间过期了，您又怎么处理这些数据呢？
    memcached是如何做身份验证的？
    memcached的多线程是什么？如何使用它们？
    memcached能接受的key的最大长度是多少？
    memcached最大能存储多大的单个item？
    memcached能够更有效地使用内存吗？
    什么是二进制协议，我该关注吗？
    memcached 的内存分配器是如何工作的？为什么不适用 malloc/free！？为何要使用 slabs？
    memcached 是原子的吗？
    如何实现集群中的 session 共享存储？
    memcached 与 redis 的区别？

# Redis 面试题

    什么是 Redis?
    Redis 的数据类型？
    使用 Redis 有哪些好处？
    Redis 相比 Memcached 有哪些优势？
    Memcache 与 Redis 的区别都有哪些？
    Redis 是单进程单线程的？
    一个字符串类型的值能存储最大容量是多少？
    Redis 的持久化机制是什么？各自的优缺点？
    Redis 常见性能问题和解决方案：
    redis 过期键的删除策略？
    Redis 的回收策略（淘汰策略）?
    为什么 edis 需要把所有数据放到内存中？
    Redis 的同步机制了解么？
    Pipeline 有什么好处，为什么要用 pipeline？
    是否使用过 Redis 集群，集群的原理是什么？
    Redis 集群方案什么情况下会导致整个集群不可用？
    Redis 支持的 Java 客户端都有哪些？官方推荐用哪个？
    Jedis 与 Redisson 对比有什么优缺点？
    Redis 如何设置密码及验证密码？
    说说 Redis 哈希槽的概念？
    Redis 集群的主从复制模型是怎样的？
    Redis 集群会有写操作丢失吗？为什么？
    Redis 集群之间是如何复制的？
    Redis 集群最大节点个数是多少？
    Redis 集群如何选择数据库？
    怎么测试 Redis 的连通性？
    怎么理解 Redis 事务？
    Redis 事务相关的命令有哪几个？
    Redis key 的过期时间和永久有效分别怎么设置？
    Redis 如何做内存优化？
    Redis 回收进程如何工作的？
    都有哪些办法可以降低 Redis 的内存使用情况呢？
    Redis 的内存用完了会发生什么？
    一个 Redis 实例最多能存放多少的 keys？List、Set、Sorted Set 他们最多能存放多少元素？
    MySQL 里有 2000w 数据，redis 中只存 20w 的数据，如何保证 redis 中的数据都是热点数据？
    Redis 最适合的场景？
    假如 Redis 里面有 1 亿个 key，其中有 10w 个 key 是以某个固定的已知的前缀开头的，如果将它们全部找出来？
    如果有大量的 key 需要设置同一时间过期，一般需要注意什么？
    使用过 Redis 做异步队列么，你是怎么用的？
    使用过 Redis 分布式锁么，它是什么回事？

# MySQL 面试题

    MySQL 中有哪几种锁？
    MySQL 中有哪些不同的表格？
    简述在 MySQL 数据库中 MyISAM 和 InnoDB 的区别
    MySQL 中 InnoDB 支持的四种事务隔离级别名称，以及逐级之间的区别？
    CHAR 和 VARCHAR 的区别？
    主键和候选键有什么区别？
    myisamchk 是用来做什么的？
    如果一个表有一列定义为 TIMESTAMP，将发生什么？
    你怎么看到为表格定义的所有索引？
    LIKE 声明中的％和_是什么意思？
    列对比运算符是什么？
    BLOB 和 TEXT 有什么区别？
    MySQL_fetch_array 和 MySQL_fetch_object 的区别是什么？
    MyISAM 表格将在哪里存储，并且还提供其存储格式？
    MySQL 如何优化 DISTINCT？
    如何显示前 50 行？
    可以使用多少列创建索引？
    NOW() 和 CURRENT_DATE() 有什么区别？
    什么是非标准字符串类型？
    什么是通用 SQL 函数？
    MySQL 支持事务吗？
    MySQL 里记录货币用什么字段类型好
    MySQL 有关权限的表都有哪几个？
    列的字符串类型可以是什么？
    MySQL 数据库作发布系统的存储，一天五万条以上的增量，预计运维三年，怎么优化？
    锁的优化策略
    索引的底层实现原理和优化
    什么情况下设置了索引但无法使用
    实践中如何优化 MySQL
    优化数据库的方法
    简单描述 MySQL 中，索引，主键，唯一索引，联合索引的区别，对数据库的性能有什么影响（从读写两方面）
    数据库中的事务是什么?
    SQL 注入漏洞产生的原因？如何防止？
    为表中得字段选择合适得数据类型
    存储时期
    对于关系型数据库而言，索引是相当重要的概念，请回答有关索引的几个问题：
    解释 MySQL 外连接、内连接与自连接的区别
    Myql 中的事务回滚机制概述
    SQL 语言包括哪几部分？每部分都有哪些操作关键字？
    完整性约束包括哪些？
    什么是锁？
    什么叫视图？游标是什么？
    什么是存储过程？用什么来调用？
    如何通俗地理解三个范式？
    什么是基本表？什么是视图？
    试述视图的优点？
    NULL 是什么意思
    主键、外键和索引的区别？
    你可以用什么来确保表格里的字段只接受特定范围里的值?
    说说对 SQL 语句优化有哪些方法？（选择几条）

# Java 并发编程（一）

    在java中守护线程和本地线程区别？
    线程与进程的区别？
    什么是多线程中的上下文切换？
    死锁与活锁的区别，死锁与饥饿的区别？
    Java中用到的线程调度算法是什么？
    什么是线程组，为什么在Java中不推荐使用？
    为什么使用Executor框架？
    在Java中Executor和Executors的区别？
    如何在Windows和Linux上查找哪个线程使用的CPU时间最长？
    什么是原子操作？在 Java Concurrency API 中有哪些原子类(atomic classes)？
    Java Concurrency API 中的 Lock 接口(Lock interface)是什么？对比同步它有什么优势？
    什么是 Executors 框架？
    什么是阻塞队列？阻塞队列的实现原理是什么？如何使用阻塞队列来实现生产者-消费者模型？
    什么是 Callable 和 Future?
    什么是 FutureTask?使用 ExecutorService 启动任务。
    什么是并发容器的实现？
    多线程同步和互斥有几种实现方法，都是什么？
    什么是竞争条件？你怎样发现和解决竞争？
    你将如何使用thread dump？你将如何分析Thread dump？
    为什么我们调用start()方法时会执行run()方法，为什么我们不能直接调用run()方法？
    Java中你怎样唤醒一个阻塞的线程？
    在Java中CycliBarriar和CountdownLatch有什么区别？
    什么是不可变对象，它对写并发应用有什么帮助？
    什么是多线程中的上下文切换？
    Java中用到的线程调度算法是什么？
    什么是线程组，为什么在Java中不推荐使用？
    为什么使用Executor框架比使用应用创建和管理线程好？
    java中有几种方法可以实现一个线程？
    如何停止一个正在运行的线程？
    notify()和notifyAll()有什么区别？
    什么是Daemon线程？它有什么意义？
    java如何实现多线程之间的通讯和协作？
    什么是可重入锁（ReentrantLock）？
    当一个线程进入某个对象的一个 synchronized 的实例方法后，其它线程是否可进入此对象的其它方法？
    乐观锁和悲观锁的理解及如何实现，有哪些实现方式？
    SynchronizedMap和ConcurrentHashMap有什么区别？
    CopyOnWriteArrayList可以用于什么应用场景？
    什么叫线程安全？servlet是线程安全吗?
    volatile有什么用？能否用一句话说明下volatile的应用场景？
    为什么代码会重排序？
    在java中wait和sleep方法的不同？
    用Java实现阻塞队列
    一个线程运行时发生异常会怎样？
    如何在两个线程间共享数据？
    Java中notify 和 notifyAll有什么区别？
    为什么wait, notify 和 notifyAll这些方法不在thread类里面？
    什么是ThreadLocal变量？
    Java中interrupted 和 isInterrupted方法的区别？
    为什么wait和notify方法要在同步块中调用？
    为什么你应该在循环中检查等待条件?
    Java中的同步集合与并发集合有什么区别？
    什么是线程池？ 为什么要使用它？
    怎么检测一个线程是否拥有锁？
    你如何在Java中获取线程堆栈？
    JVM 中哪个参数是用来控制线程的栈堆栈小的?
    Thread类中的yield方法有什么作用？
    Java中ConcurrentHashMap的并发度是什么？
    Java中Semaphore是什么？
    Java线程池中submit() 和 execute()方法有什么区别？
    什么是阻塞式方法？
    Java中的ReadWriteLock是什么？
    volatile 变量和 atomic 变量有什么不同？
    可以直接调用Thread类的run ()方法么？
    如何让正在运行的线程暂停一段时间？
    你对线程优先级的理解是什么？
    什么是线程调度器(Thread Scheduler)和时间分片(Time Slicing )？
    你如何确保main()方法所在的线程是Java 程序最后结束的线程？
    线程之间是如何通信的？
    为什么线程通信的方法 wait()，notify()和 notifyAll()被定义在 Object 类里？
    为什么 wait()，notify()和 notifyAll ()必须在同步方法或者同步块中被调用？
    为什么 Thread 类的 sleep()和 yield ()方法是静态的？
    如何确保线程安全？
    同步方法和同步块，哪个是更好的选择？
    如何创建守护线程？
    什么是 Java Timer 类？如何创建一个有特定时间间隔的任务？

# Java 并发编程（二）

    并发编程三要素？
    实现可见性的方法有哪些？
    多线程的价值？
    创建线程的有哪些方式？
    创建线程的三种方式的对比？
    线程的状态流转图
    Java线程具有五中基本状态
    什么是线程池？有哪几种创建方式？
    四种线程池的创建：
    线程池的优点？
    常用的并发工具类有哪些？
    CyclicBarrier和CountDownLatch的区别
    synchronized的作用？
    volatile关键字的作用
    什么是CAS
    CAS的问题
    什么是Future？
    什么是AQS
    AQS支持两种同步方式：
    ReadWriteLock是什么
    FutureTask是什么
    synchronized和ReentrantLock的区别
    什么是乐观锁和悲观锁
    线程B怎么知道线程A修改了变量
    synchronized、volatile、CAS比较
    sleep方法和wait方法有什么区别?
    ThreadLocal是什么？有什么用？
    为什么 wait()方法和 notify()/notifyAll()方法要在同步块中被调用
    多线程同步有哪几种方法？
    线程的调度策略
    ConcurrentHashMap的并发度是什么
    Linux环境下如何查找哪个线程使用CPU最长
    Java死锁以及如何避免？
    死锁的原因
    怎么唤醒一个阻塞的线程
    不可变对象对多线程有什么帮助
    什么是多线程的上下文切换
    如果你提交任务时，线程池队列已满，这时会发生什么
    Java中用到的线程调度算法是什么
    什么是线程调度器(Thread Scheduler)和时间分片(Time Slicing)？
    什么是自旋
    Java Concurrency API中的Lock接口(Lock interface)是什么
    单例模式的线程安全性
    Semaphore有什么作用
    Executors类是什么？
    线程类的构造方法、静态块是被哪个线程调用的
    同步方法和同步块，哪个是更好的选择?
    Java线程数过多会造成什么异常？

# Java 面试题（一）

    面向对象的特征有哪些方面？
    访问修饰符 public，private，protected，以及不写（默认）时的区别？
    String 是最基本的数据类型吗？
    float f=3.4;是否正确？
    short s1 = 1; s1 = s1 + 1;有错吗?short s1 = 1; s1 += 1;有错吗？
    Java 有没有 goto？
    int 和 Integer 有什么区别？
    &和&&的区别？
    解释内存中的栈(stack)、堆(heap)和方法区(method area)的用法。
    Math.round(11.5) 等于多少？Math.round(-11.5)等于多少？
    switch 是否能作用在 byte 上，是否能作用在 long 上，是否能作用在 String 上？
    用最有效率的方法计算2乘以8？
    数组有没有length()方法？String有没有length()方法？
    在Java中，如何跳出当前的多重嵌套循环？
    构造器（constructor）是否可被重写（override）？
    两个对象值相同(x.equals(y) == true)，但却可有不同的 hash code，这句话对不对？
    是否可以继承 String 类？
    当一个对象被当作参数传递到一个方法后，此方法可改变这个对象的属性，并可返回变化后的结果，那么这里到底是值传递还是引用传递？
    String和StringBuilder、StringBuffer的区别？
    重载（Overload）和重写（Override）的区别。重载的方法能否根据返回类型进行区分？
    描述一下JVM加载class文件的原理机制？
    char 型变量中能不能存贮一个中文汉字，为什么？
    抽象类（abstract class）和接口（interface）有什么异同？
    静态嵌套类(Static Nested Class)和内部类（Inner Class）的不同？
    Java 中会存在内存泄漏吗，请简单描述。
    抽象的（abstract）方法是否可同时是静态的（static），是否可同时是本地方法（native），是否可同时被 synchronized修饰？
    阐述静态变量和实例变量的区别。
    是否可以从一个静态（static）方法内部发出对非静态（non-static）方法的调用？
    如何实现对象克隆？
    GC是什么？为什么要有GC？
    String s = new String(“xyz”);创建了几个字符串对象？
    接口是否可继承（extends）接口？抽象类是否可实现（implements）接口？抽象类是否可继承具体类（concrete class）？
    一个”.java”源文件中是否可以包含多个类（不是内部类）？有什么限制？
    Anonymous Inner Class(匿名内部类)是否可以继承其它类？是否可以实现接口？
    内部类可以引用它的包含类（外部类）的成员吗？有没有什么限制？
    Java 中的final关键字有哪些用法？
    指出下面程序的运行结果
    数据类型之间的转换：
    如何实现字符串的反转及替换？
    怎样将GB2312编码的字符串转换为ISO-8859-1编码的字符串？
    日期和时间：
    打印昨天的当前时刻。
    比较一下Java和JavaSciprt。
    什么时候用断言（assert）？
    Error和Exception有什么区别？
    try{}里有一个 return 语句，那么紧跟在这个 try 后的finally{}里的代码会不会被执行，什么时候被执行，在 return 前还是后?
    Java 语言如何进行异常处理，关键字：throws、throw、try、catch、finally 分别如何使用？
    运行时异常与受检异常有何异同？
    列出一些你常见的运行时异常？
    阐述final、finally、finalize的区别。
    类ExampleA继承Exception，类ExampleB继承ExampleA。
    List、Set、Map是否继承自Collection接口？
    阐述ArrayList、Vector、LinkedList的存储性能和特性。
    Collection和Collections的区别？
    List、Map、Set三个接口存取元素时，各有什么特点？
    TreeMap 和 TreeSet 在排序时如何比较元素？Collections 工具类中的 sort()方法如何比较元素？
    Thread 类的 sleep()方法和对象的 wait()方法都可以让线程暂停执行，它们有什么区别?
    线程的 sleep()方法和 yield()方法有什么区别？
    当一个线程进入一个对象的 synchronized 方法 A 之后，其它线程是否可进入此对象的 synchronized 方法 B？
    请说出与线程同步以及线程调度相关的方法。
    编写多线程程序有几种实现方式？
    synchronized关键字的用法？
    举例说明同步和异步。
    启动一个线程是调用run()还是start()方法？
    什么是线程池（thread pool）？
    线程的基本状态以及状态之间的关系？
    简述synchronized 和java.util.concurrent.locks.Lock
    Java中如何实现序列化，有什么意义？
    Java中有几种类型的流？
    写一个方法，输入一个文件名和一个字符串，统计这个字符串在这个文件中出现的次数。
    如何用Java代码列出一个目录下所有的文件？
    用Java的套接字编程实现一个多线程的回显（echo）服务器。
    XML文档定义有几种形式？它们之间有何本质区别？解析XML文档有哪几种方式？
    你在项目中哪些地方用到了XML？
    阐述JDBC操作数据库的步骤。
    Statement和PreparedStatement有什么区别？哪个性能更好？
    使用JDBC操作数据库时，如何提升读取数据的性能？如何提升更新数据的性能？
    在进行数据库编程时，连接池有什么作用？
    什么是DAO模式？
    事务的ACID是指什么？
    JDBC 中如何进行事务处理？
    JDBC能否处理Blob和Clob？
    简述正则表达式及其用途。
    Java中是如何支持正则表达式操作的？
    获得一个类的类对象有哪些方式？
    如何通过反射创建对象？
    如何通过反射获取和设置对象私有字段的值？
    如何通过反射调用对象的方法？
    简述一下面向对象的”六原则一法则”。
    简述一下你了解的设计模式。
    用 Java 写一个单例类。
    什么是UML？
    UML中有哪些常用的图？
    用 Java 写一个冒泡排序。
    用 Java 写一个折半查找。

# Java 面试题（二）

下面列出这份 Java 面试问题列表包含的主题

    多线程，并发及线程基础
    数据类型转换的基本原则
    垃圾回收（GC）
    Java 集合框架
    数组
    字符串
    GOF 设计模式
    SOLID
    抽象类与接口
    Java 基础，如 equals 和 hashcode
    泛型与枚举
    Java IO 与 NIO
    常用网络协议
    Java 中的数据结构和算法
    正则表达式
    JVM 底层
    Java 最佳实践
    JDBC
    Date, Time 与 Calendar
    Java 处理 XML
    JUnit
    编程

总计133个问题，由于篇幅问题就不把问题一一列出来了，这里就展示一些截图。

# Spring 面试题（一）

## ①一般问题

    不同版本的 Spring Framework 有哪些主要功能？
    什么是 Spring Framework？
    列举 Spring Framework 的优点。
    Spring Framework 有哪些不同的功能？
    Spring Framework 中有多少个模块，它们分别是什么？
    什么是 Spring 配置文件？
    Spring 应用程序有哪些不同组件？
    使用 Spring 有哪些方式？

## ②依赖注入（Ioc）

    什么是 Spring IOC 容器？
    什么是依赖注入？
    可以通过多少种方式完成依赖注入？
    区分构造函数注入和 setter 注入。
    spring 中有多少种 IOC 容器？
    区分 BeanFactory 和 ApplicationContext。
    列举 IoC 的一些好处。
    Spring IoC 的实现机制。

## ③Beans

    什么是 spring bean？
    spring 提供了哪些配置方式？
    spring 支持集中 bean scope？
    spring bean 容器的生命周期是什么样的？
    什么是 spring 的内部 bean？
    什么是 spring 装配
    自动装配有哪些方式？
    自动装配有什么局限？

## ④注解

    什么是基于注解的容器配置
    如何在 spring 中启动注解装配？
    @Component，@Controller，@Repository，@Service 有何区别？
    @Required 注解有什么用？
    @Autowired 注解有什么用？
    @Qualifier 注解有什么用？
    @RequestMapping 注解有什么用？

## ⑤数据访问

    spring DAO 有什么用？
    列举 Spring DAO 抛出的异常。
    spring JDBC API 中存在哪些类？
    使用 Spring 访问 Hibernate 的方法有哪些？
    列举 spring 支持的事务管理类型
    spring 支持哪些 ORM 框架

## ⑥AOP

    什么是 AOP？
    什么是 Aspect？
    什么是切点（JoinPoint）
    什么是通知（Advice）？
    有哪些类型的通知（Advice）？
    指出在 spring aop 中 concern 和 cross-cutting concern 的不同之处。
    AOP 有哪些实现方式？
    Spring AOP and AspectJ AOP 有什么区别？
    如何理解 Spring 中的代理？
    什么是编织（Weaving）？

## ⑦MVC

    Spring MVC 框架有什么用？
    描述一下 DispatcherServlet 的工作流程
    介绍一下 WebApplicationContext

# Spring 面试题（二）

    什么是 spring?
    使用 Spring 框架的好处是什么？
    Spring 由哪些模块组成?
    核心容器（应用上下文) 模块。
    BeanFactory – BeanFactory 实现举例。
    XMLBeanFactory
    解释 AOP 模块
    解释 JDBC 抽象和 DAO 模块。
    解释对象/关系映射集成模块。
    解释 WEB 模块。
    Spring 配置文件
    什么是 Spring IOC 容器？
    IOC 的优点是什么？
    ApplicationContext 通常的实现是什么?
    Bean 工厂和 Application contexts 有什么区别？
    一个 Spring 的应用看起来象什么？

## ①依赖注入

    什么是 Spring 的依赖注入？
    有哪些不同类型的 IOC（依赖注入）方式？
    哪种依赖注入方式你建议使用，构造器注入，还是 Setter 方法注入？

## ②Spring Beans

    什么是 Spring beans?
    一个 Spring Bean 定义 包含什么？
    如何给 Spring 容器提供配置元数据?
    你怎样定义类的作用域?
    解释 Spring 支持的几种 bean 的作用域。
    Spring 框架中的单例 bean 是线程安全的吗?
    解释 Spring 框架中 bean 的生命周期。
    哪些是重要的 bean 生命周期方法？你能重载它们吗？
    什么是 Spring 的内部 bean？
    在 Spring 中如何注入一个 java 集合？
    什么是 bean 装配?
    什么是 bean 的自动装配？
    解释不同方式的自动装配 。
    自动装配有哪些局限性 ?
    你可以在 Spring 中注入一个 null 和一个空字符串吗？

## ③Spring 注解

    什么是基于 Java 的 Spring 注解配置? 给一些注解的例子.
    什么是基于注解的容器配置?
    怎样开启注解装配？
    @Required 注解
    @Autowired 注解
    @Qualifier 注解

## ④Spring 数据访问

    在 Spring 框架中如何更有效地使用 JDBC?
    JdbcTemplate
    Spring 对 DAO 的支持
    使用 Spring 通过什么方式访问 Hibernate?
    Spring 支持的 ORM
    如何通过HibernateDaoSupport将Spring和Hibernate结合起来？
    Spring 支持的事务管理类型
    Spring 框架的事务管理有哪些优点？
    你更倾向用那种事务管理类型？

## ⑤Spring 面向切面编程（AOP）

    解释 AOP
    Aspect 切面
    在 Spring AOP 中，关注点和横切关注的区别是什么？
    连接点
    通知
    切点
    什么是引入?
    什么是目标对象?
    什么是代理?
    有几种不同类型的自动代理？
    什么是织入。什么是织入应用的不同点？
    解释基于 XML Schema 方式的切面实现。
    解释基于注解的切面实现

## ⑥Spring 的 MVC

    什么是 Spring 的 MVC 框架？
    DispatcherServlet
    WebApplicationContext
    什么是 Spring MVC 框架的控制器？
    @Controller 注解
    @RequestMapping 注解

# 微服务 面试题

    您对微服务有何了解？
    微服务架构有哪些优势？
    微服务有哪些特点？
    设计微服务的最佳实践是什么？
    微服务架构如何运作？
    微服务架构的优缺点是什么？
    单片，SOA 和微服务架构有什么区别？
    在使用微服务架构时，您面临哪些挑战？
    SOA 和微服务架构之间的主要区别是什么？
    微服务有什么特点？
    什么是领域驱动设计？
    为什么需要域驱动设计（DDD）？
    什么是无所不在的语言？
    什么是凝聚力？
    什么是耦合？
    什么是 REST / RESTful 以及它的用途是什么？
    你对 Spring Boot 有什么了解？
    什么是 Spring 引导的执行器？
    什么是 Spring Cloud？
    Spring Cloud 解决了哪些问题？
    在 Spring MVC 应用程序中使用 WebMvcTest 注释有什么用处？
    你能否给出关于休息和微服务的要点？
    什么是不同类型的微服务测试？
    您对 Distributed Transaction 有何了解？
    什么是 Idempotence 以及它在哪里使用？
    什么是有界上下文？
    什么是双因素身份验证？
    双因素身份验证的凭据类型有哪些？
    什么是客户证书？
    PACT 在微服务架构中的用途是什么？
    什么是 OAuth？
    康威定律是什么？
    合同测试你懂什么？
    什么是端到端微服务测试？
    Container 在微服务中的用途是什么？
    什么是微服务架构中的 DRY？
    什么是消费者驱动的合同（CDC）？
    Web，RESTful API 在微服务中的作用是什么？
    您对微服务架构中的语义监控有何了解？
    我们如何进行跨功能测试？
    我们如何在测试中消除非决定论？
    Mock 或 Stub 有什么区别？
    您对 Mike Cohn 的测试金字塔了解多少？
    Docker 的目的是什么？
    什么是金丝雀释放？
    什么是持续集成（CI）？
    什么是持续监测？
    架构师在微服务架构中的角色是什么？
    我们可以用微服务创建状态机吗？
    什么是微服务中的反应性扩展？

# Linux 面试题

    绝对路径用什么符号表示？当前目录、上层目录用什么表示？主目录用什么表示? 切换目录用什么命令？
    怎么查看当前进程？怎么执行退出？怎么查看当前路径？
    怎么清屏？怎么退出当前命令？怎么执行睡眠？怎么查看当前用户 id？查看指定帮助用什么命令？
    Ls 命令执行什么功能？ 可以带哪些参数，有什么区别？
    建立软链接(快捷方式)，以及硬链接的命令。
    目录创建用什么命令？创建文件用什么命令？复制文件用什么命令？
    查看文件内容有哪些命令可以使用？
    随意写文件命令？怎么向屏幕输出带空格的字符串，比如”hello world”?
    终端是哪个文件夹下的哪个文件？黑洞文件是哪个文件夹下的哪个命令？
    移动文件用哪个命令？改名用哪个命令？
    复制文件用哪个命令？如果需要连同文件夹一块复制呢？如果需要有提示功能呢？
    删除文件用哪个命令？如果需要连目录及目录下文件一块删除呢？删除空文件夹用什么命令？
    Linux 下命令有哪几种可使用的通配符？分别代表什么含义?
    用什么命令对一个文件的内容进行统计？(行号、单词数、字节数)
    Grep 命令有什么用？ 如何忽略大小写？ 如何查找不含该串的行?
    Linux 中进程有哪几种状态？在 ps 显示出来的信息中，分别用什么符号表示的？
    怎么使一个命令在后台运行?
    利用 ps 怎么显示所有的进程? 怎么利用 ps 查看指定进程的信息？
    哪个命令专门用来查看后台任务?
    把后台任务调到前台执行使用什么命令?把停下的后台任务在后台执行起来用什么命令?
    终止进程用什么命令? 带什么参数?
    怎么查看系统支持的所有信号？
    搜索文件用什么命令? 格式是怎么样的?
    查看当前谁在使用该主机用什么命令? 查找自己所在的终端信息用什么命令?
    使用什么命令查看用过的命令列表?
    使用什么命令查看磁盘使用空间？ 空闲空间呢?
    使用什么命令查看网络是否连通?
    使用什么命令查看 ip 地址及接口信息？
    查看各类环境变量用什么命令?
    通过什么命令指定命令提示符?
    查找命令的可执行文件是去哪查找的? 怎么对其进行设置及添加?
    通过什么命令查找执行命令?
    怎么对命令进行取别名？
    du 和 df 的定义，以及区别？
    awk 详解。
    当你需要给命令绑定一个宏或者按键的时候，应该怎么做呢？
    如果一个linux新手想要知道当前系统支持的所有命令的列表，他需要怎么做？
    如果你的助手想要打印出当前的目录栈，你会建议他怎么做？
    你的系统目前有许多正在运行的任务，在不重启机器的条件下，有什么方法可以把所有正在运行的进程移除呢？
    bash shell 中的hash 命令有什么作用？
    哪一个bash内置命令能够进行数学运算。
    怎样一页一页地查看一个大文件的内容呢？
    数据字典属于哪一个用户的？
    怎样查看一个 linux 命令的概要与用法？假设你在/bin 目录中偶然看到一个你从没见过的的命令，怎样才能知道它的作用和用法呢？
    使用哪一个命令可以查看自己文件系统的磁盘空间配额呢？

# Spring Boot 面试题

    什么是 Spring Boot？
    Spring Boot 有哪些优点？
    什么是 JavaConfig？
    如何重新加载 Spring Boot 上的更改，而无需重新启动服务器？
    Spring Boot 中的监视器是什么？
    如何在 Spring Boot 中禁用 Actuator 端点安全性？
    如何在自定义端口上运行 Spring Boot 应用程序？
    什么是 YAML？
    如何实现 Spring Boot 应用程序的安全性？
    如何集成 Spring Boot 和 ActiveMQ？
    如何使用 Spring Boot 实现分页和排序？
    什么是 Swagger？你用 Spring Boot 实现了它吗？
    什么是 Spring Profiles？
    什么是 Spring Batch？
    什么是 FreeMarker 模板？
    如何使用 Spring Boot 实现异常处理？
    您使用了哪些 starter maven 依赖项？
    什么是 CSRF 攻击？
    什么是 WebSockets？
    什么是 AOP？
    什么是 Apache Kafka？
    我们如何监视所有 Spring Boot 微服务？

# Spring Cloud 面试题

    什么是 Spring Cloud？
    使用 Spring Cloud 有什么优势？
    服务注册和发现是什么意思？Spring Cloud 如何实现？
    负载平衡的意义什么？
    什么是 Hystrix？它如何实现容错？
    什么是 Hystrix 断路器？我们需要它吗？
    什么是 Netflix Feign？它的优点是什么？
    什么是 Spring Cloud Bus？我们需要它吗？

# RabbitMQ 面试题

    什么是 rabbitmq
    为什么要使用 rabbitmq
    使用 rabbitmq 的场景
    如何确保消息正确地发送至 RabbitMQ？ 如何确保消息接收方消费了消息？
    如何避免消息重复投递或重复消费？
    消息基于什么传输？
    消息如何分发？
    消息怎么路由？
    如何确保消息不丢失？
    使用 RabbitMQ 有什么好处？
    RabbitMQ 的集群
    mq 的缺点

# kafka 面试题

    如何获取 topic 主题的列表
    生产者和消费者的命令行是什么？
    consumer是推还是拉？
    讲讲kafka维护消费状态跟踪的方法
    讲一下主从同步
    为什么需要消息系统，mysql 不能满足需求吗？
    Zookeeper 对于 Kafka 的作用是什么？
    数据传输的事务定义有哪三种？
    Kafka 判断一个节点是否还活着有那两个条件？
    Kafka 与传统 MQ 消息系统之间有三个关键区别
    讲一讲 kafka 的 ack 的三种机制
    消费者如何不自动提交偏移量，由应用提交？
    消费者故障，出现活锁问题如何解决？
    如何控制消费的位置
    kafka分布式（不是单机）的情况下，如何保证消息的顺序消费?
    kafka的高可用机制是什么？
    kafka如何减少数据丢失
    kafka如何不消费重复数据？比如扣款，我们不能重复的扣。