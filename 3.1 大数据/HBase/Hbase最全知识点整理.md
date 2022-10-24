- [【万字长文】Hbase最全知识点整理（建议收藏） - 腾讯云开发者社区-腾讯云 (tencent.com)](https://cloud.tencent.com/developer/article/2005289)

# **1、Hbase是什么**

1. Hbase一个分布式的基于列式存储的数据库,基于Hadoop的hdfs存储，zookeeper进行管理。
2. Hbase适合存储半结构化或非结构化数据，对于数据结构字段不够确定或者杂乱无章很难按一个概念去抽取的数据。
3. Hbase为null的记录不会被存储.
4. 基于的表包含rowkey，时间戳，和列族。新写入数据时，时间戳更新，同时可以查询到以前的版本.
5. hbase是主从架构。Master作为主节点，Regionserver作为从节点。

# **2、Hbase架构**

**Hbase架构图：**

![img](https://ask.qcloudimg.com/http-save/yehe-5196357/395291232129c52483879467f1dd6b5b.png?imageView2/2/w/1620)

**Zookeeper：** Master 的高可用、RegionServer 的监控、元数据的入口以及集群配置的维护等

**HDFS：** 提供底层数据支撑

**Master**

1. 监控RegionServer，进行负载均衡
2. RegionServer故障转移
3. 处理元数据变更
4. 处理region的分配或分裂
5. 处理增删改查请求

**RegionServer**

1. 负责存储HBase的实际数据
2. 管理分配给它的Region
3. 刷新缓存到HDFS
4. 维护Hlog
5. 执行压缩
6. 负责处理Region分片

**Region：** 实际存储数据，HBase表会根据RowKey值被切分成不同的region存储在RegionServer中，在一个RegionServer中可以有多个不同的region

**Hlog：** 预写日志，用于记录HBase的修改记录，写数据时，数据会首先写入内存经MemStore排序后才能刷写到StoreFile，有可能引起数据丢失，为了解决这个问题，数据会先写入Hlog，然后再写入内存。在系统故障时，数据可以Hlog重建。

**Store：** StoreFile存储在Store中，一个Store对应HBase表中的一个列族。

**MemStore：** 写缓存，由于StoreFile中的数据要求是有序的，所以数据是先存储在MemStore中，排好序后，等到达刷写时机才会刷写到StoreFile，每次刷写都会形成一个新的StoreFile。StoreFile过多会影响性能，此时可进行compact操作

**StoreFile：** 这是在磁盘上保存原始数据的实际的物理文件，是实际的存储文件。StoreFile是以Hfile的形式存储在HDFS的。每个 Store 会有一个或多个StoreFile，数据在每个 StoreFile 中都是有序的（按照Rowkey的字典顺序排序）。

# **3、Hbase数据模型**

**数据模型图：**

![img](https://ask.qcloudimg.com/http-save/yehe-5196357/6ea0939f07c797077d8ea3adf6c3087b.png?imageView2/2/w/1620)

**物理模型图：**

![img](https://ask.qcloudimg.com/http-save/yehe-5196357/7b227006d92aa0dc8427e4622fd68472.png?imageView2/2/w/1620)

- **Name Space命名空间**

类似于关系型数据库的 DatabBase 概念，每个命名空间下有多个表。HBase有两个自带的命名空间，分别是 hbase 和 default，hbase 中存放的是 HBase 内置的表，default 表是用户默认使用的命名空间。

- **Row**

HBase 表中的每行数据都由一个 RowKey 和多个 Column（列）组成，数据是按照 RowKey的字典顺序存储的，并且查询数据时只能根据 RowKey 进行检索，所以 RowKey 的设计十分重要。

- **Column**

HBase 表中的每行数据都由一个 RowKey 和多个 Column（列）组成，数据是按照 RowKey的字典顺序存储的，并且查询数据时只能根据 RowKey 进行检索，所以 RowKey 的设计十分重要。

- **Time Stamp**

用于标识数据的不同版本（version），每条数据写入时，如果不指定时间戳，系统会自动为其加上该字段，其值为写入 HBase 的时间。

- **Cell**

HBase 中通过 row 和 columns 确定的为一个存贮单元称为 cell。由{rowkey, 列族：列, time Stamp} 唯一确定的单元。cell 中的数据是没有类型的，全部是字节码形式存贮（byte[]数组）。

# **4、Hbase和hive的区别**

Hbase和Hive在大数据架构中处在不同位置，Hbase主要解决实时数据查询问题，Hive主要解决海量数据处理和计算问题，一般是配合使用。

Hbase：Hadoop database 的简称，也就是基于Hadoop数据库，是一种NoSQL数据库，主要适用于海量明细数据（十亿、百亿）的随机实时查询，如日志明细、交易清单、轨迹行为等。

Hive：Hive是Hadoop数据仓库，严格来说，不是数据库，主要是让开发人员能够通过SQL来计算和处理HDFS上的结构化数据，适用于离线的批量数据计算。

# **5、Hbase特点**

1. **大：** 一个表可以有数十亿行，上百万列；
2. **无模式：** 每行都有一个可排序的主键和任意多的列，列可以根据需要动态的增加，同一 张表中不同的行可以有截然不同的列；
3. **面向列：** 面向列（族）的存储和权限控制，列（族）独立检索；
4. **稀疏：** 空（null）列并不占用存储空间，表可以设计的非常稀疏；
5. **数据多版本：** 每个单元中的数据可以有多个版本，默认情况下版本号自动分配，是单元 格插入时的时间戳；
6. **数据类型单一：** Hbase 中的数据都是二进制存储，没有类型。

# **6、数据同样存在HDFS，为什么HBase支持在线查询，且效率比Hive快很多**

1. KV存储，rowkey查询，
2. blockCache读缓存
3. [数据存储](https://cloud.tencent.com/product/cdcs?from=10680)按照rowkey字典排序，使用插值查找
4. 布隆过滤器改进查找次数

# **7、Hbase适用场景**

1. 写密集型应用，每天写入量巨大，而相对读数量较小的应用，比如微信的历史消息，游戏日志等等
2. 不需要复杂查询条件且有快速随机访问的需求。HBase只支持基于rowkey的查询，对于HBase来说，单条记录或者小范围的查询是可以接受的，大范围的查询由于分布式的原因，可能在性能上有点影响，而对于像SQL的join等查询，HBase无法支持。
3. 对性能和可靠性要求非常高的应用，由于HBase本身没有单点故障，可用性非常高。数据量较大，而且增长量无法预估的应用，HBase支持在线扩展，即使在一段时间内数据量呈井喷式增长，也可以通过HBase横向扩展来满足功能。
4. 结构化和半结构化的数据，基于Hbase动态列，稀疏存的特性。Hbase支持同一列簇下的列动态扩展，无需提前定义好所有的数据列，并且采用稀疏存的方式方式，在列数据为空的情况下不占用存储空间。
5. 网络安全业务数据带有连续性，一个完整的攻击链往往由N多次攻击事件构成，在hive中，一次攻击即为一条数据，无法体现数据的连续性。在Hbase里面，由于其多版本特性，对于任何一个字段，当数据更新后，其旧版本数据仍可访问。所以一次攻击事件可以存储为一条数据，将多次攻击日志叠加更新至此，大大减轻了业务开发人员的取数效率。

# **8、RowKey的设计原则**

1. **唯一性原则**

rowkey在设计上保证其唯一性。rowkey是按照字典顺序排序存储的，因此，设计rowkey的时候，要充分利用这个排序的特点，将经常读取的数据存储到一块，将最近可能会被访问的数据放到一块。

2. **长度原则**

rowkey是一个二进制码流，可以是任意字符串，最大长度 64kb ，实际应用中一般为10-100bytes，以byte[] 形式保存，一般设计成定长。建议越短越好，不要超过16个字节，原因如下：数据的持久化文件HFile中是按照KeyValue存储的，如果rowkey过长，比如超过100字节，1000w行数据，光rowkey就要占用100*1000w=10亿个字节，将近1G数据，这样会极大影响HFile的存储效率；MemStore将缓存部分数据到内存，如果rowkey字段过长，内存的有效利用率就会降低，系统不能缓存更多的数据，这样会降低检索效率。目前操作系统都是64位系统，内存8字节对齐，控制在16个字节，8字节的整数倍利用了操作系统的最佳特性。

3. **散列原则**

如果rowkey按照时间戳的方式递增，不要将时间放在二进制码的前面，建议将rowkey的高位作为散列字段，由程序随机生成，低位放时间字段，这样将提高数据均衡分布在每个RegionServer，以实现负载均衡的几率。如果没有散列字段，首字段直接是时间信息，所有的数据都会集中在一个RegionServer上，这样在数据检索的时候负载会集中在个别的RegionServer上，造成热点问题，会降低查询效率。

4. **就近原则**

rowkey是按照字典序存储，设计rowkey时可以将经常一起读取的数据rowkey相邻，在物理存储时可以落在同一个region中，避免读写多个Region。

# **9、HBase中scan和get的功能以及实现的异同？**

**scan 方法：按指定的条件获取一批记录**

- setCaching 与 setBatch 方法提高速度（以空间换时间）。
- setStartRow 与 setEndRow 来限定范围([start， end]start 是闭区间， end 是开区间)。范围越小，性能越高。
- setFilter方法添加过滤器，这也是分页、多条件查询的基础。

**get方法：按指定RowKey 获取唯一一条记录。Get 的方法处理分两种：**

- 设置了 ClosestRowBefore 和没有设置的 rowlock，主要是用来保证行的事务性，即每个 get 是以一个 row 来标记的，一个 row 中可以有很多 family 和 column。
- 获取当前rowkey下指定version的数据。

# **10、Scan的setCache和setBatch**

## **setCache**

- 在默认情况下，如果你需要从hbase中查询数据，在获取结果ResultScanner时，hbase会在你每次调用ResultScanner.next（）操作时对返回的每个Row执行一次RPC操作。
- 即使你使用ResultScanner.next(int nbRows)时也只是在客户端循环调用RsultScanner.next()操作，你可以理解为hbase将执行查询请求以迭代器的模式设计，在执行next（）操作时才会真正的执行查询操作，而对每个Row都会执行一次RPC操作。
- 因此显而易见的就会想如果我对多个Row返回查询结果才执行一次RPC调用，那么就会减少实际的通讯开销。
- 这个就是hbase配置属性“hbase.client.scanner.caching”的由来，设置cache可以在hbase配置文件中显示静态的配置，也可以在程序动态的设置。
- cache值得设置并不是越大越好，需要做一个平衡。
- cache的值越大，则查询的性能就越高，但是与此同时，每一次调用next（）操作都需要花费更长的时间，因为获取的数据更多并且数据量大了传输到客户端需要的时间就越长，一旦你超过了maximum heap the client process 拥有的值，就会报outofmemoryException异常。
- 当传输rows数据到客户端的时候，如果花费时间过长，则会抛出ScannerTimeOutException异常。

## **setBatch**

- 在cache的情况下，我们一般讨论的是相对比较小的row，那么如果一个Row特别大的时候应该怎么处理呢？要知道cache的值增加，那么在client process 占用的内存就会随着row的增大而增大。
- 在HBase中同样为解决这种情况提供了类似的操作：Batch。
- 可以这么理解，cache是面向行的优化处理，batch是面向列的优化处理。
- 它用来控制每次调用next（）操作时会返回多少列，比如你设置setBatch（5），那么每一个Result实例就会返回5列，如果你的列数为17的话，那么就会获得四个Result实例，分别含有5,5,5,2个列。

# **11、HBase 写流程**

1. Client 先访问 zookeeper，找到 Meta 表，并获取 Meta 表元数据。
2. 确定当前将要写入的数据所对应的 Region 和 RegionServer 服务器。
3. Client 向该 RegionServer 服务器发起写入数据请求，然后 RegionServer 收到请求 并响应。
4. Client 先把数据写入到 HLog，以防止数据丢失。
5. 然后将数据写入到 Memstore，在memstore中会对 rowkey进行排序。
6. 如果 HLog 和 Memstore 均写入成功，则这条数据写入成功
7. 如果 Memstore 达到阈值，会把 Memstore 中的数据 flush 到 Storefile 中。
8. 当 Storefile 越来越多，会触发 Compact 合并操作，把过多的 Storefile 合并成一个大 的 Storefile。
9. 当 Storefile 越来越大，Region 也会越来越大，达到阈值后，会触发 Split 操作，将 Region 一分为二。

# **12、HBase 读流程**

1. RegionServer 保存着 meta 表以及表数据，要访问表数据，首先 Client 先去访问zookeeper，从 zookeeper 里面获取 meta 表所在的位置信息，即找到这个 meta 表在哪个RegionServer 上保存着。
2. 接着 Client 通过刚才获取到的 RegionServer 的 IP 来访问 Meta 表所在的RegionServer，从而读取到 Meta，进而获取到 Meta 表中存放的元数据。
3. Client 通过元数据中存储的信息，访问对应的 RegionServer，然后扫描所在RegionServer 的 Memstore 和 Storefile 来查询数据。
4. 最后 RegionServer 把查询到的数据响应给 Client。

# **13、HBase中Zookeeper的作用**

1. hbase regionserver向zookeeper注册，提供hbase regionserver状态信息（是否在线）。
2. 存放Master管理的表的META元数据信息；表名、列名、key区间等。
3. Client访问用户数据之前需要首先访问zookeeper中的META.表，根据META表找到用户数据的位置去访问，中间需要多次网络操作，不过client端会做cache缓存。
4. Master没有单点问题，HBase中可以启动多个Master，通过Zookeeper的事件处理确保整个集群只有一个正在运行的Master。
5. 当RegionServer意外终止后，Master会通过Zookeeper感知到。

# **14、StoreFile（HFile）合并**

在HBase中，每当memstore的数据flush到磁盘后，就形成一个storefile，当storefile的数量越来越大时，会严重影响HBase的读性能 ，HBase内部的compact处理流程是为了解决MemStore Flush之后，storefile数太多，导致读数据性能大大下降的一种自我调节手段，它会将文件按照策略进行合并，提升HBase的数据读性能。

## **作用**

1. 合并文件
2. 清除删除、过期、多余版本的数据
3. 提高读写数据的效率

HBase中实现了两种compaction的方式：

## **minor（小合并）**

Minor操作只用来做部分文件的合并操作以及超过生存时间TTL的数据，删除标记数据、多版本数据不进行清除。

**触发条件：**

把所有的文件都遍历一遍之后每一个文件都去考虑。符合条件而进入待合并列表的文件由新的条件判断：该文件 < (所有文件大小总和 - 该文件大小) * hbase.store.compaction.ratio比例因子。

## **major（大合并）**

Major操作是对Region下的Store下的所有StoreFile执行合并操作，顺序重写全部数据，重写过程中会略过做了删除标记的数据，最终合并出一个HFile文件，并将原来的小文件删除。会占用大量IO资源。

**触发条件:**

Major是Minor升级而来的。如果本次Minor Compaction包含所有文件，且达到了足够的时间间隔，则会被升级为Major Compaction。判断时间间隔根据以下两个配置项：

hbase.hregion.majorcompaction：major Compaction发生的周期，单位是毫秒，默认值是7天。

hbase.hregion.majorcompaction.jitter majorCompaction：周期抖动参数，0~1.0的一个指数。调整这个参数可以让Major Compaction的发生时间更灵活，默认值是0.5。

> 虽然有以上机制控制Major Compaction的发生时机，但是由于Major Compaction时对系统的压力还是很大的，所以建议关闭自动Major Compaction，采用手动触发的方式。

**合并流程**

1. 获取需要合并的HFile列表。
2. 由列表创建出StoreFileScanner。HRegion会创建出一个Scanner，用这个Scanner来读取本次要合并 的所有StoreFile上的数据。
3. 把数据从这些HFile中读出，并放到tmp目录（临时文件 夹）。HBase会在临时目录中创建新的HFile，并使用之前建立的Scanner 从旧HFile上读取数据，放入新HFile。以下两种数据不会被读取出来：1）如果数据过期了（达到TTL所规定的时间），那么这些数据不会 被读取出来。2）如果是majorCompaction，那么数据带了墓碑标记也不会被读取 出来。
4. 用合并后的HFile来替换合并前的那些HFile。最后用临时文件夹内合并后的新HFile来替换掉之前的那些HFile文 件。过期的数据由于没有被读取出来，所以就永远地消失了。如果本次 合并是Major Compaction，那么带有墓碑标记的文件也因为没有被读取 出来，就真正地被删除掉了。

# **15、Hbase协处理器**

Hbase 作为列族数据库最经常被人诟病的特性包括：无法轻易建立“二级索引”，难以执行求和、计数、排序等操作。比如，在0.92版本前，统计总行数需要使用Counter方法，执行一次MapReduce Job才能得到。虽然 HBase 在数据存储层中集成 了 MapReduce，能够有效用于数据表的分布式计算。然而在很多情况下，做一些简单的相加或者聚合计算的时候，如果直接将计算过程放置在regionServer端，能够减少通讯开销，从而获得很好的性能提升。于是，HBase在0.92之后引入了协处理器(coprocessors)，能够轻易建立二次索引、复杂过滤器、求和、计数以及访问控制等。协处理器包括observer和endpoint

## **observer**

类似于传统数据库中的触发器，当数据写入的时候会调用此类协处理器中的逻辑。主要的作用是当执行被监听的一个操作的时候，可以触发另一个我们需要的操作，比如说监听数据库数据的增删过程，我们可以在hbase数据库插入数据或者删除数据之前或之后进行一系列的操作。二级索引基于此触发器构建。

## **Endpoint**

类似传统数据库中的存储过程，客户端可以调用Endpoint执行一段 Server 端代码，并将 Server 端代码的结果返回给客户端进一步处理，常用于Hbase的聚合操作。min、max、avg、sum、distinct、group by

## **协处理加载方式**

协处理器的加载方式有两种，我们称之为静态加载方式(Static Load)和动态加载方式 (Dynamic Load)。静态加载的协处理器称之为 System Coprocessor，动态加载的协处理器称 之为 Table Coprocessor

**静态加载：**通过修改 hbase-site.xml 这个文件来实现，启动全局 aggregation，能过操纵所有的表上的数据。只需要添加如下代码:

```javascript
<property>
    <name>hbase.coprocessor.user.region.classes</name>
  <value>org.apache.hadoop.hbase.coprocessor.AggregateImplementation</value>
</property>
```

复制

为所有 table 加载了一个 cp class，可以用”,”分割加载多个 class**注意：** 该方法因为是全局的，所以在实际应用中并不是很多，而另一种方法用的会更多一些

**动态加载**启用表 aggregation，只对特定的表生效。通过 HBase Shell 来实现。

①disable 指定表。hbase> disable ‘table名’；

②添加 aggregation

```javascript
hbase> alter 'mytable', METHOD => 'table_att','coprocessor'=>
'|org.apache.Hadoop.hbase.coprocessor.AggregateImplementation||' 
```

复制

③重启指定表 hbase> enable ‘table名’

# **16、WAL机制**

数据在写入HBase的时候，先写WAL，再写入缓存。通常情况下写缓存延迟很低，WAL机制一方面是为了确保数据即使写入缓存后数据丢失也可以通过WAL恢复，另一方面是为了集群之间的复制。默认WAL机制是开启的，并且使用的是同步机制写WAL。

如果业务不特别关心异常情况下部分数据的丢失，而更关心数据写入吞吐量，可考虑关闭WAL写，这样可以提升2~3倍数据写入的吞吐量。

如果业务不能接受不写WAL，但是可以接受WAL异步写入，这样可以带了1~2倍性能提升。

HBase中可以通过设置WAL的持久化等级决定是否开启WAL机制、以及HLog的落盘方式。

WAL的持久化等级分为如下四个等级：

- SKIP_WAL：只写缓存，不写HLog日志。这种方式因为只写内存，因此可以极大的提升写入性能，但是数据有丢失的风险。在实际应用过程中并不建议设置此等级，除非确认不要求数据的可靠性。
- ASYNC_WAL：异步将数据写入HLog日志中。
- SYNC_WAL：同步将数据写入日志文件中，需要注意的是数据只是被写入文件系统中，并没有真正落盘，默认。
- FSYNC_WAL：同步将数据写入日志文件并强制落盘。最严格的日志写入等级，可以保证数据不会丢失，但是性能相对比较差。

除了在创建表的时候直接设置WAL存储级别，也可以通过客户端设置WAL持久化等级，代码：put.setDurability(Durability.SYNC_WAL);

# **17、Memstore**

hbase为了保证随机读取的性能，所以storefile的数据按照rowkey的字典序存储。当客户端的请求在到达regionserver之后，为了保证写入rowkey的有序性，不能将数据立刻写入到hfile中，而是将每个变更操作保存在内存中，也就是memstore中。memstore能够保证内部数据有序。当某个memstore达到阈值后，会将Region的所有memstore都flush到hfile中（Flush操作为Region级别），这样能充分利用hadoop写入大文件的性能优势，提高写入性能。

由于memstore是存放在内存中，如果regionserver宕机，会导致内存中数据丢失。所有为了保证数据不丢失，hbase将更新操作在写入memstore之前会写入到一个WAL中。WAL文件是追加、顺序写入的，WAL每个regionserver只有一个，同一个regionserver上所有region写入同一个的WAL文件。这样当某个regionserver失败时，可以通过WAL文件，将所有的操作顺序重新加载到memstore中。

## **主要作用：**

- 更新数据存储在 MemStore 中，使用 LSM（Log-Structured Merge Tree）数据结构存储，在内存内进行排序整合。即保证写入数据有序（HFile中数据都按照RowKey进行排序），同时可以极大地提升HBase的写入性能。
- 作为内存缓存，读取数据时会优先检查 MemStore，根据局部性原理，新写入的数据被访问的概率更大。
- 在持久化写入前可以做某些优化，例如：保留数据的版本设置为1，持久化只需写入最新版本。

如果一个 HRegion 中 MemStore 过多（Column family 设置过多），每次 flush 的开销必然会很大，并且生成大量的 HFile 影响后续的各项操作，因此建议在进行表设计的时候尽量减少 Column family 的个数。

用户可以通过shell命令分别对一个 Table 或者一个 Region 进行 flush：

```javascript
hbase> flush 'TABLENAME'
hbase> flush 'REGIONNAME'
```

复制

## **相关配置**

**hbase.hregion.memstore.flush.size**

默认值：128M MemStore 最大尺寸，当 Region 中任意一个 MemStore 的大小（压缩后的大小）达到了设定值，会触发 MemStore flush。

**hbase.hregion.memstore.block.multiplier**

默认值：2 Region 级别限制，当 Region 中所有 MemStore 的大小总和达到了设定值（hbase.hregion.memstore.block.multiplier * hbase.hregion.memstore.flush.size，默认 2* 128M = 256M），会触发 MemStore flush。

**hbase.regionserver.global.memstore.upperLimit**

默认值：0.4 Region Server 级别限制，当一个 Region Server 中所有 MemStore 的大小总和达到了设定值（hbase.regionserver.global.memstore.upperLimit * hbase_heapsize，默认 0.4 * RS堆内存大小），会触发Region Server级别的MemStore flush。

**hbase.regionserver.global.memstore.lowerLimit**

默认值：0.38 与 hbase.regionserver.global.memstore.upperLimit 类似，区别是：当一个 Region Server 中所有 MemStore 的大小总和达到了设定值（hbase.regionserver.global.memstore.lowerLimit * hbase_heapsize，默认 0.38 * RS堆内存大小），会触发部分 MemStore flush。

Flush 顺序是按照 Region 的总 MemStore 大小，由大到小执行，先操作 MemStore 最大的 Region，再操作剩余中最大的 Region，直至总体 MemStore 的内存使用量低于设定值（hbase.regionserver.global.memstore.lowerLimit ＊ hbase_heapsize）。

**hbase.regionserver.maxlogs**

默认值：32 当一个 Region Server 中 HLog 数量达到设定值，系统会选取最早的一个 HLog 对应的一个或多个 Region 进行 flush。

当增加 MemStore 的大小以及调整其他的 MemStore 的设置项时，也需要去调整 HLog 的配置项。否则，WAL的大小限制可能会首先被触发。因而，将利用不到其他专门为Memstore而设计的优化。

需要关注的 HLog 配置是 HLog 文件大小，由参数 hbase.regionserver.hlog.blocksize 设置（默认512M），HLog 大小达到上限，或生成一个新的 HLog

通过WAL限制来触发Memstore的flush并非最佳方式，这样做可能会会一次flush很多Region，尽管“写数据”是很好的分布于整个集群，进而很有可能会引发flush“大风暴”。

**hbase.regionserver.optionalcacheflushinterval**

默认值：3600000 HBase 定期刷新 MemStore，默认周期为1小时，确保 MemStore 不会长时间没有持久化。为避免所有的 MemStore 在同一时间都进行 flush，定期的 flush 操作有 20000 左右的随机延时。

## **Memstore Flush**

为了减少 flush 过程对读写的影响，HBase 采用了类似于两阶段提交的方式，将整个 flush 过程分为三个阶段：

- prepare 阶段：遍历当前 Region 中的所有 MemStore，将 MemStore 中当前数据集 kvset 做一个快照 snapshot，然后再新建一个新的 kvset，后期的所有写入操作都会写入新的 kvset 中。整个 flush 阶段读操作读 MemStore 的部分，会分别遍历新的 kvset 和 snapshot。prepare 阶段需要加一把 updateLock 对写请求阻塞，结束之后会释放该锁。因为此阶段没有任何费时操作，因此持锁时间很短。
- flush 阶段：遍历所有 MemStore，将 prepare 阶段生成的 snapshot 持久化为临时文件，临时文件会统一放到目录.tmp下。这个过程因为涉及到磁盘IO操作，因此相对比较耗时。
- commit 阶段：遍历所有的 MemStore，将 flush 阶段生成的临时文件移到指定的 Column family 目录下，生成对应的 Storefile（HFile） 和 Reader，把 Storefile 添加到 Store 的 Storefiles 列表中，最后再清空 prepare 阶段生成的 snapshot。

# **18、BloomFilter**

布隆过滤器是hbase中的高级功能，它能够减少特定访问模式（get/scan）下的查询时间。不过由于这种模式增加了内存和存储的负担，所以被默认为关闭状态。

hbase支持如下类型的布隆过滤器：

1. ROW           行键使用布隆过滤器
2. ROWCOL    行加列使用布隆过滤器，粒度更细。

如果用户随机查找一个rowkey，位于某个region中两个开始rowkey之间的位置。对于hbase来说，它判断这个行键是否真实存在的唯一方法就是加载这个region，并且扫描它是否包含这个键。当我们get数据时，hbase会加载很多块文件。

采用布隆过滤器后，它能够准确判断该StoreFile的所有数据块中，是否含有我们查询的数据，从而减少不必要的块加载，增加hbase集群的吞吐率。

**1、布隆过滤器的存储在哪**

开启布隆后，HBase会在生成StoreFile时包含一份布隆过滤器结构的数据，称其为MetaBlock；MetaBlock与DataBlock（真实的KeyValue数据）一起由LRUBlockCache维护。所以，开启bloomfilter会有一定的存储及内存cache开销。大多数情况下，这些负担相对于布隆过滤器带来的好处是可以接受的。

**2、采用布隆过滤器后，如何get数据**

在读取数据时，hbase会首先在布隆过滤器中查询，根据布隆过滤器的结果，再在MemStore中查询，最后再在对应的HFile中查询。

**3、采用ROW还是ROWCOL**

- 如果用户只做行扫描，使用ROW即可，使用更加细粒度的ROWCOL会增加内存的消耗。
- 如果大多数随机查询使用行加列作为查询条件，Bloomfilter需要设置为ROWCOL。
- 如果不确定业务查询类型，设置为row。

# **19、BlockCache读缓存**

一个RegionServer只有一个BlockCache。用来优化读取性能，不是数据存储的必须组成部分。

BlockCache名称中的Block指的是HBase的Block。BlockCache的工作原理跟其他缓存一样：读请求到HBase之后先尝试查询BlockCache，如果获取不到就去StoreFile和 Memstore中去获取。如果获取到了则在返回数据的同时把Block块缓存到BlockCache中。BlockCache默认是开启的。BlockCache的实现方案有以下几种：

## **LRUBlock Cache：**

近期最少使用算法。读出来的block会被放到BlockCache中待 下次查询使用。当缓存满了的时候，会根据LRU的算法来淘汰block。

## **SlabCache**

这是一种堆外内存的解决方案。不属于JVM管理的内存范围，说白了，就是原始的内存区域了。回收堆外内存的时候JVM几乎不会停顿，可以避免GC过程中遇见的系统卡顿与异常。

## **Bucket Cache**

BucketCache借鉴SlabCache也用上了堆外内存。不过它以下自己的特点：

- 相比起只有2个区域的SlabeCache，BucketCache一上来就分配了 14种区域。这 14种区域分别放的是大小为4KB、8KB、16KB、32KB、40KB、 48KB、56KB、64KB、96KB、128KB、192KB、256KB、384KB、 512KB的Block。而且这个种类列表还是可以手动通过设置 hbase.bucketcache.bucket.sizes属性来定义
- BucketCache的存储不一定要使用堆外内存，是可以自由在3种存 储介质直接选择：堆（heap）、堆外（offheap）、文件 （file）。通过设置hbase.bucketcache.ioengine为heap、 offfheap或者file来配置。
- 每个Bucket的大小上限为最大尺寸的block * 4，比如可以容纳 的最大的Block类型是512KB，那么每个Bucket的大小就是512KB * 4 = 2048KB。
- 系统一启动BucketCache就会把可用的存储空间按照每个Bucket 的大小上限均分为多个Bucket。如果划分完的数量比你的种类还 少，比如比14（默认的种类数量）少，就会直接报错，因为每一 种类型的Bucket至少要有一个Bucket。

## **组合模式**

把不同类型的Block分别放到 LRUCache和BucketCache中。Index Block和Bloom Block会被放到LRUCache中。Data Block被直接放到BucketCache中，所以数据会去LRUCache查询一下，然后再去 BucketCache中查询真正的数据。其实这种实现是一种更合理的二级缓存，数据从一级缓存到二级缓存最后到硬盘，从小到大，存储介质也由快到慢。考虑到成本和性能的组合，比较合理的介质是：LRUCache使用内存->BuckectCache使用SSD->HFile使用机械硬盘。

## **BlockCache 压缩**

在开启此功能后，数据块会以它们on-disk的形式缓存到BlockCache。与默认的模式不同点在于：默认情况下，在缓存一个数据块时，会先解压缩然后存入缓存。而lazy BlockCache decompression 直接将压缩的数据块存入缓存。

如果一个RegionServer存储的数据过多，无法适当的将大部分数据放入缓存，则开启这个功能后，可以提升50%的吞吐量，30%的平均延迟上升，增加80%垃圾回收，以及2%的整体CPU负载。

压缩默认关闭，若要开启，可以在hbase-site.xml文件里设置 hbase.block.data.cachecompressed 为 true

# **20、Region拆分**

一个Region就是一个表的一段Rowkey的数据集合。一旦 Region 的负载过大或者超过阈值时，它就会被分裂成两个新的 Region。Region的拆分分为自动拆分和手动拆分。自动拆分可以采用不同的策略。

## **拆分流程**

![img](https://ask.qcloudimg.com/http-save/yehe-5196357/3603bda460e99c6f11fea22e0156414a.png?imageView2/2/w/1620)

在这里插入图片描述

这个过程是由 RegionServer 完成的，其拆分流程如下。

1. 将需要拆分的 Region下线，阻止所有对该 Region 的客户端请求，Master 会检测到 Region 的状态为 SPLITTING。
2. 将一个 Region 拆分成两个子 Region，先在父 Region下建立两个引用文件，分别指向 Region 的首行和末行，这时两个引用文件并不会从父 Region 中复制数据。
3. 之后在 HDFS 上建立两个子 Region 的目录，分别复制上一步建立的引用文件，每个子 Region 分别占父 Region 的一半数据。复制登录完成后删除两个引用文件。
4. 完成子 Region 创建后，向 Meta 表发送新产生的 Region 的元数据信息。
5. 将 Region 的拆分信息更新到 HMaster，并且每个 Region 进入可用状态。

## **自动拆分**

Region的自动拆分主要根据拆分策略进行，主要有以下几种拆分策略：

- ConstantSizeRegionSplitPolicy 0.94版本前唯一拆分策略，按照固定大小来拆分Region。Region 中的最大Store大于设置阈值（hbase.hregion.max.filesize：默认10GB）触发拆分。拆分点为最大Store的rowkey的顺序中间值。**弊端：** 切分策略对于大表和小表没有明显的区分。阈值(hbase.hregion.max.filesize)设置较大对大表友好，但小表有可能不会触发分裂，极端情况下可能就1个。如果设置较小则对小表友好，但大表就会在整个集群产生大量的region，占用集群资源。
- IncreasingToUpperBoundRegionSplitPolicy 0.94版本~2.0版本默认切分策略。切分策略稍微有点复杂，基于ConstantSizeRegionSplitPolicy思路，一个region大小大于设置阈值就会触发切分。但是这个阈值并不是固定值，而是会在一定条件下不断调整，调整规则和region所属表在当前regionserver上的region个数有关系.
- KeyPrefixRegionSplitPolicy 在IncreasingToUpperBoundRegionSplitPolicy的基础上增加了对拆分点（splitPoint，拆分点就是Region被拆分处的rowkey）的自定义，可以将rowKey的前多少位作为前缀。保证相同前缀的rowkey拆分至同一个region中。
- DelimitedKeyPrefixRegionSplitPolicy KeyPrefixRegionSplitPolicy根据rowkey的固定前几位来进行判 断，而DelimitedKeyPrefixRegionSplitPolicy是根据分隔符来判断的。比如你定义了前缀分隔符为_，那么host1_001和host12_999的前缀 就分别是host1和host12。
- SteppingSplitPolicy 2.0版本默认切分策略，相比 IncreasingToUpperBoundRegionSplitPolicy 简化，基于当前表的region个数进行规划，对于大集群中的大表、小表会比 IncreasingToUpperBoundRegionSplitPolicy更加友好，小表不会再产生大量的小region，而是适可而止。
- BusyRegionSplitPolicy 此前的拆分策略都没有考虑热点问题。热点问题就是数据库中的Region被访问的频率并不一样，某些Region在短时间内被访问的很频繁，承载了很大的压力，这些Region就是热点Region。它会通过拆分热点Region来缓解热点Region压力，但也会带来很多不确定性因素，因为无法确定下一个被拆分的Region是哪个。
- DisabledRegionSplitPolicy 关闭策略，手动拆分。可控制拆分时间，选择集群空闲时间

## **手动拆分**

调用hbase shell的 split方法，split的调用方式如下：

```javascript
split 'regionName' # format: 'tableName,startKey,id'
```

复制

比如：

```javascript
split 'test_table1,c,1476406588669.96dd8c68396fda69'
```

复制

这个就是把test_table1,c,1476406588669.96dd8c68396fda69这个 Region从新的拆分点999处拆成2个Region。

# **21、Region合并**

如果有很多Region，则MemStore也过多，数据频繁从内存Flush到HFile，影响用户请求，可能阻塞该Region服务器上的更新操作。过多的 Region 会增加服务器资源的负担。当删了大量的数据，或Region拆分过程中产生了过多小Region，这时可以Region合并，减轻RegionServer资源负担。

## **合并过程**

1. 客户端发起 Region 合并处理，并发送 Region 合并请求给 Master。
2. Master 在 Region 服务器上把 Region 移到一起，并发起一个 Region 合并操作的请求。
3. Region 服务器将准备合并的 Region下线，然后进行合并。
4. 从 Meta 表删除被合并的 Region 元数据，新的合并了的 Region 的元数据被更新写入 Meta 表中。
5. 合并的 Region 被设置为上线状态并接受访问，同时更新 Region 信息到 Master。

## **Merger类手动合并**

合并通过使用org.apache.hadoop.hbase.util.Merge类来实现。例如把以下两个Region合并：

```javascript
test_table1,b,1476406588669.39eecae03539ba0a63264c24130c2cb1. 
test_table1,c,1476406588669.96dd8c68396fda694ab9b0423a60a4d9.
```

复制

就需要在Linux下（不需要进入hbase shell）执行以下命令：

```javascript
hbase  org.apache.hadoop.hbase.util.Merge test_table1
test_table1,b,1476406588669.39eecae03539ba0a63264c24130c2cb1. 
test_table1,c,1476406588669.96dd8c68396fda694ab9b0423a60a4d9.
```

复制

此方式需要**停止整个Hbase集群**，所以后来又增加了online_merge（热合并）。

## **热合并**

hbase shell提供了一个命令叫online_merge，通过这个方法可以进行热合并，无需停止整个Hbase集群。

假设要合并以下两个Region：

```javascript
test_table1,a,1476406588669.d1f84781ec2b93224528cbb79107ce12. 
test_table1,b,1476408648520.d129fb5306f604b850ee4dc7aa2eed36.
```

复制

online_merge的传参是Region的hash值。只需在hbase shell 中执行以下命令：

```javascript
merge_region
'd1f84781ec2b93224528cbb79107ce12', 'd129fb5306f604b850ee4dc7aa2eed36'
```

复制

# **22、Region 负载均衡**

当 Region 分裂之后，Region 服务器之间的 Region 数量差距变大时，Master 便会执行负载均衡来调整部分 Region 的位置，使每个 Region 服务器的 Region 数量保持在合理范围之内，负载均衡会引起 Region 的重新定位，使涉及的 Region 不具备数据本地性。

Region 的负载均衡由 Master 来完成，Master 有一个内置的负载均衡器，在默认情况下，均衡器每 5 分钟运行一次，用户可以配置。负载均衡操作分为两步进行：首先生成负载均衡计划表， 然后按照计划表执行 Region 的分配。

执行负载均衡前要明确，在以下几种情况时，Master 是不会执行负载均衡的。

- 均衡负载开关关闭。
- Master 没有初始化。
- 当前有 Region 处于拆分状态。
- 当前集群中有 Region 服务器出现故障。

Master 内部使用一套集群负载评分的算法，来评估 HBase 某一个表的 Region 是否需要进行重新分配。这套算法分别从 Region 服务器中 Region 的数目、表的 Region 数、MenStore 大小、 StoreFile 大小、数据本地性等几个维度来对集群进行评分，评分越低代表集群的负载越合理。

确定需要负载均衡后，再根据不同策略选择 Region 进行分配，负载均衡策略有三种，如下表所示。

| 策略                | 原理                                                         |
| :------------------ | :----------------------------------------------------------- |
| RandomRegionPicker  | 随机选出两个 Region 服务器下的 Region 进行交换               |
| LoadPicker          | 获取 Region 数目最多或最少的两个 Region 服务器，使两个 Region 服务器最终的 Region 数目更加平均 |
| LocalityBasedPicker | 选择本地性最强的 Region                                      |

根据上述策略选择分配 Region 后再继续对整个表的所有 Region 进行评分，如果依然未达到标准，循环执行上述操作直至整个集群达到负载均衡的状态。

# **23、Region预分区**

Hbase建表时默认单region，所有数据都会写入此region，超过阈值（hbase.Region.max.filesize，默认10G）会此region会进行拆分，分成2个region。在此过程中，会产生三个问题：

1. 拆分后如果数据往一个region上写，会造成热点问题。
2. 拆分过程中会消耗大量的IO资源。
3. 拆分过程中当前region会下线，影响访问服务。

基于此我们可以在建表时进行预分区，创建多个空region，减少由于split带来的资源消耗，从而提高HBase的性能。预分区时会确定每个region的起始和终止rowky，rowkey设计时确保均匀的命中各个region，就不会存在写热点问题。当然随着数据量的不断增长，该split的还是要进行split。

# **24、一张表中定义多少个 Column Family 最合适**

Column Family划分标准一般根据数据访问频度，如一张表里有些列访问相对频繁，而另一些列访问很少，这时可以把这张表划分成两个列族，分开存储，提高访问效率。

# **25、为什么不建议在 HBase 中使用过多的列族**

HBase 中每张表的列族个数建议设在1~3之间，列族数过多可能会产生以下影响：

**对Flush的影响**在 HBase 中，数据首先写入memStore 的，每个列族都对应一个store，store中包含一个MemStore。列族过多将会导致内存中存在越多的MemStore；而MemStore在达到阈值后会进行Flush操作在磁盘生产一个hFile文件。列族越多导致HFile越多。

由于Flush操作是Region 级别的，即Region中某个MemStore被Flush，同一个Region的其他MemStore也会进行Flush操作。当列族之间数据不均匀，比如一个列族有100W行，一个列族只有10行，会产生很多很多小文件，而且每次 Flush 操作也涉及到一定的 IO 操作。  此外列族数过多可能会触发RegionServer级别的Flush操作；这将会阻塞RegionServer上的更新操作，且时间可能会达到分钟级别。

**对Split的影响**当HBase表中某个Region过大会触发split拆分操作。如果有多个列族，且列族间数据量相差较大，这样在Region Spli时会导致原本数据量很小的HFil文件进一步被拆分，从而产生更多的小文件。

**对 Compaction 的影响**目前HBase的Compaction操作也是Region级别的，过多的列族且列族间数据量相差较大，也会产生不必要的 IO。

**对HDFS的影响**HDFS 其实对一个目录下的文件数有限制的。列族数过多，文件数可能会超出HDFS的限制。小文件问题也同样会出现。

**对RegionServer内存的影响**一个列族在RegionServer中对应于一个 MemStore。每个MemStore默认占用128MB的buffer。如果列族过多，MemStore会占用RegionServer大量内存。

# **26、直接将时间戳作为行健，在写入单个region时会发生热点问题，为什么**

region 中的 rowkey 是有序存储，若时间比较集中。就会存储到一个 region 中，这样一个 region 的数据变多，其它的 region 数据很少，加载数据就会很慢，直到 region 分裂，此问题才会得到缓解。

# **27、HBase中region太小和region太大的影响**

hbase.hregion.max.filesize：此参数定义了单个region的最大数据量。

1. 当region太小，触发split的机率增加，split过程中region会下线，影响访问服务。
2. 当region太大，由于长期得不到split，会发生多次compaction，将数据读一遍并重写一遍到 hdfs 上，占用IO。降低系统的稳定性与吞吐量。

hbase数据会首先写入MemStore，超过配置后会flush到磁盘成为StoreFile，当StoreFile的数量超过配置之后，会启动compaction，将他们合并为一个大的StoreFile。

当合并后的Store大于max.filesize时，会触发分隔动作，将它切分为两个region。hbase.hregion.max.filesize不宜过大或过小，经过实战， 生产高并发运行下，最佳大小5-10GB！

推荐关闭某些重要场景的hbase表的major_compact！在非高峰期的时候再去调用major_compact，这样可以减少split的同时，显著提供集群的性能，吞吐量、非常有用。

# **28、每天百亿数据如何写入Hbase**

1. 百亿数据：证明数据量非常大；
2. 存入HBase：证明是跟HBase的写入数据有关；
3. 保证数据的正确：要设计正确的数据结构保证正确性；
4. 在规定时间内完成：对存入速度是有要求的。

**解决思路：**

1. 假设一整天60x60x24 = 86400秒都在写入数据，那么每秒的写入条数高达100万条，HBase当然是支持不了每秒百万条数据的， 所以这百亿条数据可能不是通过实时地写入，而是批量地导入。批量导入推荐使用BulkLoad方式，性能是普通写入方式几倍以上；
2. 存入HBase：普通写入是用JavaAPI put来实现，批量导入推荐使用BulkLoad；
3. 保证数据的正确：这里需要考虑RowKey的设计、预建分区和列族设计等问题；
4. 还有region热点的问题，如果你的hbase数据不是那种每天增量的数据，建议跑个mapreduce对你的数据进行各评判，看看如何能将数据尽可能均匀的分配到每个region中，当然这需要预先分配region

# **29、HBase集群安装注意事项？**

1. HBase需要HDFS的支持，因此安装HBase前确保Hadoop集群安装完成；
2. HBase需要ZooKeeper集群的支持，因此安装HBase前确保ZooKeeper集群安装完成；
3. 注意HBase与Hadoop的版本兼容性；
4. 注意hbase-env.sh配置文件和hbase-site.xml配置文件的正确配置；
5. 注意regionservers配置文件的修改；
6. 注意集群中的各个节点的时间必须同步，否则启动HBase集群将会报错。

# **30、Hbase数据热点问题**

**一、出现热点问题原因**

1. hbase的中的数据是按照字典序排序的，当大量连续的rowkey集中写在个别的region，各个region之间数据分布不均衡；
2. 创建表时没有提前预分区，创建的表默认只有一个region，大量的数据写入当前region；
3. 创建表已经提前预分区，但是设计的rowkey没有规律可循

**二、如何解决热点问题**

1. 随机数+业务主键，如果想让最近的数据快速get到，可以将时间戳加上
2. Rowkey设计越短越好，不要超过10-100个字节
3. 映射regionNo，这样既可以让数据均匀分布到各个region中，同时可以根据startKey和endKey可以get到同一批数据。

# **31、HBase宕机恢复流程**

宕机分为 Master 宕机和 regionServer 宕机

## **Master 宕机恢复**

1、Master主要负责实现集群的负载均衡和读写调度，没有单点问题，所以集群中可以存在多个Master节点。2、通过热备方式实现Master高可用，并在zookeeper上进行注册 3、active master会接管整个系统的元数据管理任务，zk以及meta表中的元数据，相应用户的管理指令，创建、删除、修改，merge region等

## **regionServer宕机恢复**

集群中一台RegionServer宕机并不会导致已经写入的数据丢失，HBase采用WAL机制保证，即使意外宕机导致Memstore缓存数据没有落盘,也可以通过HLog日志恢复。RegionServer宕机一定程度上会影响业务方的读写请求，因为zookeeper感知到RegionServer宕机事件是需要一定时间的,这段时间默认会有3min。

引起RegionServer宕机的原因各种各样，Full GC、网络异常、官方Bug导致（close wait端口未关闭）等。

一旦RegionServer发生宕机，Zookeeper感知后会通知Master，Master首先会将这台RegionServer上所有Region移到其他RegionServer上，再将HLog分发给其他RegionServer进行回放，完成之后再修改路由，业务方的读写才会恢复正常。整个过程都是自动完成的，并不需要人工介入。

![img](https://ask.qcloudimg.com/http-save/yehe-5196357/1c83229841d6271910fc4e10972c1a84.png?imageView2/2/w/1620)

**宕机原因**1、Full Gc引起长时间停顿超过心跳时间 2、HBase对Jvm堆内存管理不善，未合理使用堆外内存 3、Jvm启动参数配置不合理 4、业务写入或吞吐量太大 5、网络异常导致超时或RegionServer断开集群连接

**宕机检测**通过Zookeeper实现， 正常情况下RegionServer会周期性向Zookeeper发送心跳，一旦发生宕机，心跳就会停止，超过一定时间（SessionTimeout）Zookeeper就会认为RegionServer宕机离线，并将该消息通知给Master。

**具体流程**

1. master通过zk实现对RegionServer的宕机检测。RegionServer会周期性的向zk发送心跳，超过一定时间，zk会认为RegionServer离线，发送消息给master。
2. master重新分配宕机regionserver上的所有region,regionserver宕机后，所有region处于不可用状态，所有路由到这些region上的请求都会返回异常。异常情况比较短暂，master会将这些region分配到其它regionserver上。
3. 将HLog日志分分配至其他regionserver中，回放HLog日志补救数据。
4. 恢复完成后修改路由，对外提供读写服务。

# **32、HBase性能优化**

## **HDFS调优**

Hbase基于HDFS存储，首先需要进行HDFS的相关优化。优化内容详见《大数据面试题整理-HDFS篇》

## **集群性能优化**

1. **高可用：** 在 HBase 中 Master 负责监控 RegionServer 的生命周期，均衡 RegionServer 的负载，如果 Master 挂掉了，那么整个 HBase 集群将陷入不健康的状态，并且此时的工作状态并不会维持太久。生产环境推荐开启高可用。
2. **hbase.regionserver.handler.count**：rpc请求的线程数量，默认值是10，生产环境建议使用100。
3. **hbase.master.distributed.log.splitting**：默认值为true，建议设为false。关闭hbase的分布式日志切割，在log需要replay时，由master来负责重放
4. **hbase.snapshot.enabled**：快照功能，默认是false(不开启)，某些关键的表建议设为true。
5. **hbase.hregion.memstore.flush.size**：默认值128M，单位字节，一旦有memstore超过该值将被flush，如果regionserver的jvm内存比较充足(16G以上)，可以调整为256M。
6. **hbase.regionserver.lease.period**：默认值60000(60s)，客户端连接regionserver的租约超时时间，客户端必须在这个时间内汇报，否则则认为客户端已死掉。这个最好根据实际业务情况进行调整
7. **hfile.block.cache.size**：默认值0.25，regionserver的block cache的内存大小限制，在偏向读的业务中，可以适当调大该值。

## **表层面优化**

1. **预分区：** 在建表时进行预分区，创建多个空region，减少由于split带来的资源消耗，从而提高HBase的性能。确定每个region的起始和终止rowky，rowkey设计时确保均匀的命中各个region，降低热点问题发生的概率。
2. **RowKey 设计：** 唯一性原则、长度原则、散列原则、就近原则。
3. **列族不可过多：** 一般1-3个最好
4. **关闭自动Major：** 在非高峰期的时候再去调用major_compact，这样可以减少split的同时，显著提供集群的性能，吞吐量、非常有用。
5. **合并小Region：**  过多的 Region 会增加服务器资源的负担。可以定期合并小Region，减轻RegionServer资源负担。
6. **设置最大版本：** 创建表的时候，可根据需求设置表中数据的最大版本，如果只需要保存最新版本的数据，那么可以设置setMaxVersions(1)。
7. **设置过期时间TTL：** 创建表的时候，可以设置表中数据的存储生命期，过期数据将自动标记删除，例如如果只需要存储最近两天的数据，那么可以设置setTimeToLive(2 * 24 * 60 * 60)。
8. **小表可以放进内存：** 创建表的时候，高频率访问的小表可以通过HColumnDescriptor.setInMemory(true)将表放到RegionServer的缓存中。
9. **调整blocksize：** 配置HFile中block块的大小，默认64KB。blocksize影响HBase读写数据的效率。1）blocksize越大，配置压缩算法，压缩的效率就越好，有利于提升写入性能；2）但是由于读数据以block块为单位，所以越大的block块，随机读的性能较差。3）如果要提升写入的性能，一般扩大到128kb或者256kb，可以提升写数据的效率，也不会太大影响随机读性能。

## **读优化**

1. **开启 Bloomfilter：** 提升随机读写性能，任何业务都应该设置Bloomfilter，通常设置为row就可以，除非确认业务随机查询类型为row+cf，可以设置为rowcol
2. **合理规划BlockCache：**1）对于注重读响应时间的系统，可以将 BlockCache设大些，加大缓存的命中率。2）开启BolckCache压缩。3）采用组合模式把不同类型的Block分别放到 LRUCache和BucketCache中，其中IndexBloom Block放到LRUCache中。Data Block放到BucketCache中，LRUCache使用内存->BuckectCache使用SSD->HFile使用机械硬盘。
3. **异构存储：** 可以将热点表存储在SSD中
4. **开启Short-CircuitLocal Read：** Short Circuit策略允许客户端绕过DataNode直接读取本地数据
5. **开启HedgedRead功能：** 客户端发起一个本地读，一旦一段时间之后还没有返回，客户端将会向其他DataNode发送相同数据的请求。哪一个请求先返回，另一个就会被丢弃。
6. **批量读：** 通过调用HTable.get(List)方法可以根据一个指定的row key列表，批量获取多行记录，这样做的好处是批量执行，只需要一次网络I/O开销，这对于对数据实时性要求高而且网络传输RTT高的情景下可能带来明显的性能提升。
7. **指定列族：** scan时指定需要的列族，可以减少网络传输数据量，否则默认scan操作会返回整行所有Column Family的数据。
8. **多线程并发读：** 在客户端开启多个HTable读线程，每个读线程负责通过HTable对象进行get操作。
9. **限定扫描范围：** 指定列簇或者指定要查询的列，指定startRow和endRow
10. **scan批量缓存** hbase.client.scanner.caching默认为1，scan一次从服务端抓取的数据条数，通过将其设置成一个合理的值，可以减少scan过程中next()的时间开销，避免占用过多的客户端内存，一般1000以内合理。

## **写优化**

1. **批量写：** 采用批量写，可以减少客户端到RegionServer之间的RPC的次数，提高写入性能。批量写请求要么全部成功返回，要么抛出异常。
2. **异步批量提交：** 用户提交写请求之后，数据会先写入客户端缓存，并返回用户写入成功，当缓存达到阈值（默认2M，可通过hbase.client.write.buffer配置）时才会批量提交给RegionServer。客户端异常缓存数据有可能丢失。

```javascript
HTable.setWriteBufferSize(writeBufferSize); // 设置缓存大小
HTable.setAutoFlush(false);//关闭自动提交
```

复制

1. **多线程并发写:** 客户端开启多个HTable写线程，每个写线程负责一个HTable对象的flush操作，这样结合定时flush和写buffer，可以即保证在数据量小的时候，数据可以在较短时间内被flush，同时又保证在数据量大的时候，写buffer一满就即使进行flush。
2. **使用BulkLoad写入：** 在HBase中数据都是以HFile形式保存在HDFS中的，当有大量数据需要写入到HBase的时候，可以采用BulkLoad方式完成。通过使用MapReduce或者Spark直接生成HFile格式的数据文件，然后再通过RegionServer将HFile数据文件移动到相应的Region上去。
3. **合理设置WAL：**  写HBase时，数据需要先写入WAL保障数据不丢失。如果业务不特别关心异常情况下部分数据的丢失，而更关心数据写入吞吐量，可开启WAL异步写入或考虑关闭WAL写。