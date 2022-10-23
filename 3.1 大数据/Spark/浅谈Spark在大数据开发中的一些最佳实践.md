- [浅谈Spark在大数据开发中的一些最佳实践 - 腾讯云开发者社区-腾讯云 (tencent.com)](https://cloud.tencent.com/developer/article/2134948)

**1**

**前  言**

**eBay 智能营销部门**致力于打造数据驱动的业务智能中台，以支持业务部门快速开展营销活动。目前在我们正在构建一个基于eBay站外营销的业务全渠道漏斗分析指标，涉及近十个营销渠道、数十张数据源表，每天处理的数据达到上百TB。由于业务复杂、数据源异构、指标计算逻辑频繁变更、数据体量巨大，如何快速完成数据处理开发任务是一个巨大的挑战。**在长时间的生产实践中，我们总结了一套基于Scala开发Spark任务的可行规范，来帮助我们写出高可读性、高可维护性和高质量的代码，提升整体开发效率**。

**2**

**基本开发规范**

**一、字段名规范**‍

- 字段名应足够简洁清晰，使阅读者能快速理解字段内容。
- 相似字段名应加上数据源、级别名、细分属性加以区分，例如我们有 Google 的 click数据和内部的click数据，那么就应该使用 **PARTNER_CLICK, INTERNAL_CLICK** 来命名不同的点击数据。

**二、业务字典**

- 对于公司已有统一命名的专业术语，应采用此命名方式，例如 GMB。
- 对于公司级别命名并未统一的专业术语，在 domain 或 team 内部应有统一的命名规范。比如你的ETL任务中用到了多个系统的数据，对于用户ID，系统A里面叫user_id，系统B里面叫u_id，系统C里面叫mapped_id，当经过我们数据清洗流程后我们应该将这些字段统一成同个概念，比如USER_ID。
- 数据 schema 中字段名应用下划线分割，而代码变量仍旧应该采用驼峰命名法，字段与变量应该有默认对应关系。
- 建议维护一个业务名词库用来统一定义专业概念和术语，注明是公司级别的术语或是 domain/team 级别的术语，级别名称应在字段名上体现。

**三、幂等性**

- **一个spark任务应该是幂等的，这个任务在有同样的输入时被执行多次输出是恒定的，不应该产生副作用。**

**四、数值类型**

在分析计算需求的时候，需要先对数值类型进行分类，不同的数值类型的计算方式也会不同。

- **原始数值指标：**由事件带出的数值指标，在定比数据级别（ratio level)，可以直接进行算数运算 **🚩 示例**：Clicks，GMB，Spend，Watch Count等 🚩 对于一个广告系列中，我们可以直接将广告系列中的产品的GMB直接相加得到总GMB
- **衍生数值指标：**由原始数值指标进行衍生计算而获得的指标，适用于固定场景。根据衍生计算逻辑，不一定能直接进行算数运算。因而，在计算涉及衍生数值指标时，需考虑该逻辑的影响。 **🚩 示例**：CPC(每次点击成本=广告费用/点击量)，ROAS(支出回报率=广告收入/广告费用) 🚩 对于一个广告系列，我们不能直接将广告系列中的CPC相加得到总CPC
- **定类数据 (Nominal level)** 定类数据不作为数值指标，不可进行算数计算。

**3**

**基本编码规范**

**一、建议将建表DDL和写数据分离，并且不要在编码中使用drop+create来覆写表数据**

- 当使用drop table再重建table的方式刷新表数据时，会有一定的风险。**因为 drop table 和 create table 是非原子性操作，**如果drop table完成后，重建的sql因为某些不可抗原因失败了，会直接导致数据丢失，而这个表也变成不可用状态。  如下sql，如果create table失败，table将处于不可用状态：

![img](https://ask.qcloudimg.com/http-save/yehe-2039230/7f5a4c96b5be70c426b326d0143211a6.png?imageView2/2/w/1620)

- **更佳的方式应该如下：**

![img](https://ask.qcloudimg.com/http-save/yehe-2039230/8e7dfad8317b6bef24a6dbee49dd70b1.png?imageView2/2/w/1620)

当数据重新生成完以后只需要使用原子操作更新hive的location即可，这样就可以保证每次写入数据时不影响表的使用。

**二、特殊的逻辑应该要有注释，比如   ，应该说明这个字段和对应的值的作用，或者定义一个常量来语义化这个魔法值，**比如：

![img](https://ask.qcloudimg.com/http-save/yehe-2039230/60a43d594cc6b16f822c71020e51861a.png?imageView2/2/w/1620)

**三、在hive中没有布尔值，禁止使用true/false，它在hive中会变成字符串‘true’/’false’，所以请使用数值类型代替布尔类型。**

**四、若使用Spark SQL编写代码，那么最好不要将核心的SQL逻辑拆分成片段，这样会使可读性下降。对于有多段逻辑的Job，需要让代码更多的暴露出表操作的核心逻辑。**

以下是一个反例的伪代码，**过度的函数分装会使代码可读性下降，从而无法快速直观的了解表操作的逻辑，**那么就需要添加相关的注释方便阅读：

![img](https://ask.qcloudimg.com/http-save/yehe-2039230/dbad573a63372116b546ac0d59299310.png?imageView2/2/w/1620)

稍微修改一下，以下是伪代码， 我们可以将表操作的逻辑暴露出来，而把非核心逻辑封装起来，这样我们可以轻松理解这段代码到底是在做什么：

![img](https://ask.qcloudimg.com/http-save/yehe-2039230/ec1539149fd50e1ff13f1a1eed3b0ffc.png?imageView2/2/w/1620)

**4**

**Spark开发最佳实践**

**一、使用Spark cache时，需要考虑它能否带来计算时间上的提升。Spark cache是使用给定的存储级别来缓存表的内容或查询的输出内容，常用于未来查询中复用原始文件的场景。**

Cache的存储级别分为以下几种：

- NONE：不进行缓存
- DISK_ONLY：只在磁盘中缓存
- DISKONLY_2：只在磁盘中缓存并进行2次备份
- MEMORY_ONLY：只在内存中缓存
- MEMORY_ONLY_2：只在内存中缓存并进行2次备份
- MEMORY_ONLY_SER：只在内存中缓存并进行序列化
- MEMORY_ONLY_SER_2：只在内存中缓存并进行序列化和2次备份
- MEMORY_AND_DISK：在内存中缓存，如果内存不足将写入磁盘 （默认缓存级别）
- MEMORY_AND_DISK_2 ：在内存中缓存并进行2次备份，如果内存不足将写入磁盘
- MEMORY_AND_DISK_SER：在内存中缓存并序列化，如果内存不足将写入磁盘
- MEMORY_AND_DISK_SER_2 ：在内存中缓存并序列化和2次备份，如果内存不足将写入磁盘
- OFF_HEAP：使用堆外内缓存

如果所需要 cache的数据集过大，使用 MEMORY_ONLY 容易导致OOM；而使用默认的MEMORY_AND_DISK，当内存不适合写入时则会写入磁盘，这时I/O会占用大量时间，并且由于内存减少导致频繁GC，反而使效率下降。在使用 cache 的时候需要平衡好数据 I/O 的开销和计算资源的使用。如果一个数据集cache消耗的I/O时间不是明显小于直接重计算消耗的时间，不建议使用cache。

以下是一个例子，可以看到这里  被使用了两次，那么对于这种场景我们需要权衡通过join计算和cache所消耗的I/O的代价。  **是由一张小表 join大表生成的，**如果在join完后我们添加了cache，数据量仍旧非常大，**cache数据时会产生额外的磁盘写入开销；而考虑到这个 join 操作本身所需要的计算时间并不多，如果从时间性能的角度考虑，这个case我们就不应该使用cache**。

![img](https://ask.qcloudimg.com/http-save/yehe-2039230/ab7bfcb22507a089b759797868427611.png?imageView2/2/w/1620)

**二、DataFrame的 API 和Spark SQL中的 union 行为是不一致的**，DataFrame中union默认不会进行去重，Spark SQL union 默认会进行去重。

**三、两个DataFrame来源于同一个数据源，如果直接将它们join则会报以下错：**

*Detected implicit cartesian product for LEFT(INNER/RIGHT) OUTER join between logical plans* 

由于来自同一个数据源的DataFrame join很容易产生笛卡尔积，所以Spark默认禁止这种行为。但是在一些业务场景中的确有这种join的情况，解决方案有两种：

- 在join前将[数据存储](https://cloud.tencent.com/product/cdcs?from=10680)到临时目录(一般是HDFS)，再重新加载进来，用来截断血缘。
- 添加spark配置：spark.sql.crossJoin.enabled=true 但是不建议这么做，这样会导致其他可能有隐患的join也被忽略了

**四、写入分区表时，Spark会默认覆盖所有分区，**如果只是想覆盖当前DataFrame中有数据的分区，需要配置如下参数开启动态分区，动态分区会在有数据需要写入分区时才会将当前分区清空。需要注意的是开启动态分区会导致写入效率下降：

![img](https://ask.qcloudimg.com/http-save/yehe-2039230/7e454d9ad20ae8623d8707ef989e162f.png?imageView2/2/w/1620)

**五、DataFrame中使用udf时，需要注意udf的参数如果是基础类型则必须不为空，否则不会被执行。**

示例：如下代码，一个简单根据int值生成对应的flag，但是如果norb是null的话，那么这段udf不会被执行，对应的norbFlag为null。对于这种由于null值导致的逻辑不一样问题，可以借助DataFrameNaFunctions 来协助处理null值情况。

![img](https://ask.qcloudimg.com/http-save/yehe-2039230/fa91f9ed082b7dc6b16836e9d1ee9b86.png?imageView2/2/w/1620)

**六、Spark原生不支持数据更改，所以对一些非分区表更新数据是有挑战的。**这里我们可以借鉴一个类似delta lake的upsert方案「1」：取出历史数据，按照唯一键将需要upsert的数据挖去，再和待添加的数据做union，可以实现更新有唯一键的表的功能。以下是示例代码:

![img](https://ask.qcloudimg.com/http-save/yehe-2039230/28fe21012418efb3d31cfc97a40191cd.png?imageView2/2/w/1620)

**5**

**后  记**

使用 Spark 开发[大数据](https://cloud.tencent.com/solution/bigdata?from=10680) ETL 已经成为业界的主流方案。**此篇文章总结了我们在使用 Spark 过程中所遇到的挑战和技术案例，希望能够抛砖引玉，引出更多更好的实践方案。**最后，也要感谢**杨青波**对此文章的贡献，以及**刘炼**和**刘轶**的审稿。

**参考**

「1」https://github.com/delta-io/delta/blob/73ca6fcea0a25f302ee655f9849f86832bbe5f23/examples/scala/src/main/scala/example/QuickstartSQL.scala