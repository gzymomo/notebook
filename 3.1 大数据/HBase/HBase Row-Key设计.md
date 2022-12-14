## 1 HBase表热点

### 1.1 什么是热点

- 检索habse的记录首先要通过row key来定位数据行。
- 当大量的client访问hbase集群的一个或少数几个节点，造成少数region server的读/写请求过多、负载过大，而其他region server负载却很小，就造成了“热点”现象。

### 1.2 热点现象产生

HBase中的行是按照Rowkey的字典顺序排序的，这种设计优化了scan操作，可以将相关的行以及会被一起读取的行存取在临近位置，便于scan。

然而糟糕的Rowkey设计是热点的源头。 热点发生在大量的client直接访问集群的一个或极少数个节点（访问可能是读，写或者其他操作）。

大量访问会使热点region所在的单个机器超出自身承受能力，引起性能下降甚至region不可用，这也会影响同一个RegionServer上的其他region，由于主机无法服务其他region的请求，这样就造成 数据热点现象。 （这一点其实和数据倾斜类似）

所以我们在向HBase中插入数据的时候，应优化RowKey的设计，使数据被写入集群的多个region，而不是一个。尽量均衡地把记录分散到不同的Region中去，平衡每个Region的压力。

### 1.3 热点的解决方案

#### 1.3.1 预分区

- 预分区的目的让表的数据可以均衡的分散在集群中，而不是默认只有一个region分布在集群的一个节点上。

默认情况下，在创建HBase表的时候会自动创建一个region分区。这个region的rowkey是没有边界的，即没有startkey和endkey，在数据写入时，所有数据都会写入这个默认的region，随着数据量的不断增加，此region已经不能承受不断增长的数据量，会进行split，分成2个region。

在此过程中，会产生两个问题：

1. 数据往一个region上写,会有写热点问题。造成单机负载压力大，影响业务的正常读写。
2. region split会消耗宝贵的集群I/O资源。

一种可以加快批量写入速度的方法是通过预先创建一些空的regions，这样当数据写入HBase时，会按照region分区情况，在集群内做数据的负载均衡。

示例：

```bash
# create table with specific split points
hbase>create 'table1','f1',SPLITS => ['\x10\x00', '\x20\x00', '\x30\x00','\x40\x00']
# create table with four regions based on random bytes keys
hbase>create 'table2','f1', { NUMREGIONS => 8 , SPLITALGO => 'UniformSplit' }
# create table with five regions based on hex keys
hbase>create 'table3','f1', { NUMREGIONS => 10, SPLITALGO => 'HexStringSplit' }
```

#### 1.3.2 加盐

- 这里所说的加盐不是密码学中的加盐，而是在rowkey的前面增加随机数，具体就是给rowkey分配一个随机前缀以使得它和之前的rowkey的开头不同

#### 1.3.3 哈希

- 哈希会使同一行永远用一个前缀加盐。哈希也可以使负载分散到整个集群，但是读却是可以预测的。使用确定的哈希可以让客户端重构完整的rowkey，可以使用get操作准确获取某一个行数据。

```ini
rowkey=MD5(username).subString(0,10)+时间戳	
```

#### 1.3.4 反转

- 反转固定长度或者数字格式的rowkey。这样可以使得rowkey中经常改变的部分（最没有意义的部分）放在前面。
- 这样可以有效的随机rowkey，但是牺牲了rowkey的有序性。

```shell
电信公司：
移动-----------> 136xxxx9301  ----->1039xxxx631
				   136xxxx1234  
				   136xxxx2341 
电信
联通

user表
rowkey    name    age   sex    address
          lisi1   21     m      beijing
          lisi2   22     m      beijing
	  lisi3   25     m      beijing
	  lisi4   30     m      beijing
	  lisi5   40     f      shanghai
	  lisi6   50     f      tianjin
	          
需求：后期想经常按照居住地和年龄进行查询？	
rowkey= address+age+随机数
        beijing21+随机数
        beijing22+随机数
        beijing25+随机数
        beijing30+随机数
   
rowkey= address+age+随机数
```

#### 1.3.5 时间戳反转

一个常见的数据处理问题是快速获取数据的最近版本，使用反转的时间戳作为rowkey的一部分对这个问题十分有用，可以用 Long.Max_Value - timestamp 追加到key的末尾，例如 [key] [reverse_timestamp] , [key] 的最新值可以通过scan [key]获得[key]的第一条记录，因为HBase中rowkey是有序的，第一条记录是最后录入的数据。比如需要保存一个用户的操作记录，按照操作时间倒序排序，在设计rowkey的时候，可以这样设计。

[userId反转] [Long.Max_Value - timestamp]，在查询用户的所有操作记录数据的时候，直接指定反转后的userId，startRow是[userId反转] [000000000000],stopRow是[userId反转] [Long.Max_Value -timestamp]

如果需要查询某段时间的操作记录，startRow是[user反转] [Long.Max_Value - 起始时间]，stopRow是[userId反转] [Long.Max_Value - 结束时间] [Long.Max_Value - 结束时间]。

电话号码，身份证，纯数字的类型，都可以使用这个方式。

## 2 RowKey概念

HBase中RowKey可以唯一标识一行记录，在HBase查询的时候有以下几种方式：

1.通过get方式，指定RowKey获取唯一一条记录

2.通过scan方式，设置startRow和stopRow参数进行范围匹配

3.全表扫描，即直接扫描整张表中所有行记录

从字面意思来看，RowKey就是行键的意思，在曾删改查的过程中充当了主键的作用。它可以是 任意字符串，在HBase内部RowKey保存为字节数组。

HBase中的数据是按照Rowkey的ASCII字典顺序进行全局排序的，有伙伴可能对ASCII字典序印象不够深刻，下面举例说明：

**假如有5个Rowkey：“012”, “0”, “123”, “234”, “3”，按ASCII字典排序后的结果为：“0”, “012”,“123”, “234”, “3”。**

因此我们设计RowKey时，需要充分利用排序存储这个特性，将经常一起读取的行存储放到一起，要避免做全表扫描，因为效率特别低。

### 2.1 RowKey在查询中的作用

HBase中RowKey可以唯一标识一行记录，在HBase中检索数据有以下三种方式：

1. 通过 get 方式，指定 RowKey 获取唯一一条记录

2. 通过 scan 方式，设置 startRow 和 stopRow 参数进行范围匹配

3. 全表扫描，即直接扫描整张表中所有行记录

### 2.2 RowKey设计技巧

#### 2.2.1 越高频的查询字段排列越靠左

下面根据一个例子分别介绍下根据RowKey进行查询的时候支持的情况。

如果我们RowKey设计为`uid`+`phone`+`name`，那么这种设计可以很好的支持一下的场景:

```delphi
uid= 873969725 AND phone=18900000000 AND name=zhangsan
uid= 873969725 AND phone=18900000000
uid= 873969725 AND phone=189?
uid= 873969725
```

难以支持的场景：

```delphi
phone=18900000000 AND name = zhangsan
phone=18900000000 
name=zhangsan
```

从上面的例子中可以看出，在进行查询的时候，根据RowKey从前向后匹配，所以我们在设计RowKey的时候选择好字段之后，还应该结合我们的实际的高频的查询场景来组合选择的字段，**越高频的查询字段排列越靠左**。

## 3 Rowkey 设计

- [HBase-3rowkey的设计 - hanease - 博客园 (cnblogs.com)](https://www.cnblogs.com/hanease/p/16217205.html)

### 3.1 rowkey长度原则

- rowkey是一个二进制码流，可以是任意字符串，最大长度64kb，实际应用中一般为10-100bytes，以byte[]形式保存，一般设计成定长，建议越短越好，不要超过16个字节。

- 建议尽可能短；但是也不能太短，否则rowkey前缀重复的概率增大
- 设计过长会降低memstore内存的利用率和HFile存储数据的效率。

在HBase的底层存储HFile中，RowKey是KeyValue结构中的一个域。假设RowKey长度100B，那么1000万条数据中，光RowKey就占用掉 100*1000w=10亿个字节 将近1G空间，这样会极大影响HFile的存储效率。

我们目前使用的服务器操作系统都是64位系统，内存是按照8B对齐的，因此设计RowKey时一般做成8B的整数倍，如16B或者24B，可以提高寻址效率。

同样地，列族、列名的命名在保证可读的情况下也应尽量短。value永远和它的key一起传输的。当具体的值在系统间传输时，它的RowKey，列名，时间戳也会一起传输（因此实际上列族命名几乎都用一个字母，比如‘c’或‘f’）。如果你的RowKey和列名和值相比较很大，那么你将会遇到一些有趣的问题。Hfile中的索引最终占据了HBase分配的大量内存。

### 3.2 rowkey散列原则

- 建议将rowkey的高位作为**散列字段**，这样将提高数据均衡分布在每个RegionServer，以实现负载均衡的几率。
- 如果没有散列字段，首字段直接是时间信息。所有的数据都会集中在一个RegionServer上，这样在数据检索的时候负载会集中在个别的RegionServer上，造成热点问题，会降低查询效率。

比如设计RowKey的时候，当Rowkey 是按时间戳的方式递增，就不要将时间放在二进制码的前面，可以将 Rowkey 的高位作为散列字段，由程序循环生成，可以在低位放时间字段，这样就可以提高数据均衡分布在每个Regionserver实现负载均衡的几率。

结合前面分析的热点现象的起因思考： 如果没有散列字段，首字段只有时间信息，那就会出现所有新数据都在一个RegionServer上堆积的热点现象，这样在做数据检索的时候负载将会集中在个别RegionServer上，降低查询效率。

### 3.3 rowkey唯一原则

- 必须在设计上保证其唯一性，rowkey是按照字典顺序排序存储的
- 因此，设计rowkey的时候，要充分利用这个排序的特点，可以将经常读取的数据存储到一块，将最近可能会被访问的数据放到一块

**需要注意：由于HBase中数据存储的格式是Key-Value对格式，所以如果向HBase中同一张表插入相同RowKey的数据，则原先存在的数据会被新的数据给覆盖掉（和HashMap效果相同）。**

### 3.4 排序原则

RowKey是按照字典顺序排序存储的，因此，设计RowKey的时候，要充分利用这个排序的特点，将经常读取的数据存储到一块，将最近可能会被访问的数据放到一块。

一个常见的数据处理问题是快速获取数据的最近版本，使用反转的时间戳作为RowKey的一部分对这个问题十分有用，可以用 Long.Max_Value-timestamp追加到key的末尾。

例如 [key][reverse_timestamp] , [key]的最新值可以通过scan [key]获得[key]的第一条记录，因为HBase中RowKey是有序的，第一条记录是最后录入的数据。

## 4 表设计

### 4.1 列簇设计

追求的原则是：在合理范围内能尽量少的减少列簇就尽量减少列簇。

最优设计是：将所有相关性很强的key-value都放在同一个列簇下，这样既能做到查询效率最高，也能保持尽可能少的访问不同的磁盘文件

以用户信息为例，可以将必须的基本信息存放在一个列族，而一些附加的额外信息可以放在另一列族hbase的列簇越少越好！尽量就是1个

## 5 问题考虑

- 问题一：Rowkey是唯一的吗？

  相同的Rowkey在HBase中认为是同一条数据的多个版本，查询时默认返回最新版本的数据，所以通常Rowkey都需要保证唯一，除非用到多版本特性。

  最佳设计示例：Rowkey相当于数据库的主键。Rowkey表示一条记录。Rowkey可以是一个字段也可以是多个字段接起来。Rowkey为[userid]表示每个用户只有一条记录， Rowkey为[userid][orderid]表示每个用户有多条记录。

- 问题二：满足哪种查询场景？

  Rowkey的设计限制了数据的查询方式，HBase有两种查询方式。

  - 根据完整的Rowkey查询（get方式），例如

    ```
    SELECT * FROM table WHERE Rowkey = ‘abcde’
    ```

    说明 get方式需要知道完整的Rowkey，即组成Rowkey所有字段的值都是确定的。

  - 根据Rowkey的范围查询（scan方式），例如

    ```
    SELECT * FROM table WHERE ‘abc’ < Rowkey <’abcx’
    ```

    说明 scan方式需要知道Rowkey左边的值，例如您使用英文字典查询pre开头的所有单词，也可以查询prefi开头的所有单词，不能查询中间或结尾为prefi的单词。

  最佳设计示例：在有限的查询方式下如何实现复杂查询？以下方法可以帮您实现。

  - 再新建一张表作为索引表。

  - 使用Filter在服务端过滤不需要的数据。

  - 使用二级索引。

  - 使用反向scan方法实现倒序（将新数据排在前面），

    ```
    scan.setReverse(true)
    ```

    说明 反向scan的性能比正常scan性能差，如果大部分是倒序场景可以体现在Rowkey设计上，例如`[hostname][log-event][timestamp] => [hostname][log-event][Long.MAX_VALUE – timestamp]`。

- 问题三：数据足够分散，会存在堆积的热点现象吗？

  散列的目的是将数据分散到不同的分区，不至于产生热点使某一台服务器终止，其他服务器空闲，充分发挥分布式和并发的优势。

  最佳设计示例：

  - 设计md5散列算法：`[userId][orderid] => [md5(userid).subStr(0,4)][userId][orderid] `。
  - 设计反转：`[userId][orderid] => [reverse(userid)][orderid]`。
  - 设计取模：`[timestamp][hostname][log-event] => [bucket][timestamp][hostname][log-event]; long bucket = timestamp % numBuckets`。
  - 增加随机数：`[userId][orderid] => [userId][orderid][random(100)]`。

- 问题四：Rowkey可以再短点吗？

  短的Rowkey可以减少数据量，提高数据查询和数据写入效率。

  最佳设计示例：

  - 使用Long或Int代替String，例如`'2015122410' => Long(2015122410) `。
  - 使用编码代替名称，例如`’淘宝‘ => tb`。

- 问题五：使用scan方式会查询出不需要的数据吗？

  会的。场景举例：table1的Rowkey为`column1+ column2+ column3`，如果您需要查询`column1= host1`的所有数据，使用`scan 'table1',{startkey=> 'host1',endkey=> 'host2'}`语句。如果有一条记录为`column1=host12`，那么此记录也会查询出来。

  最佳设计示例：

  - 设计字段定长，`[column1][column2] => [rpad(column1,'x',20)][column2]`。
  - 添加分隔符，`[column1][column2] => [column1][_][column2]`。

## 6 常见设计实例

- 日志类、时间序列数据。列举出三个场景设计Rowkey。
  - 查询某台机器某个指标某段时间内的数据，Rowkey设计为`[hostname][log-event][timestamp]`。
  - 查询某台机器某个指标最新的几条数据，Rowkey设计为`timestamp = Long.MAX_VALUE – timestamp; [hostname][log-event][timestamp]`。
  - 查询的数据存在只有时间一个维度或某一个维度数据量巨大的情况，Rowkey设计为`long bucket = timestamp % numBuckets; [bucket][timestamp][hostname][log-event]`。
- 交易类数据。列举出四个场景设计Rowkey。
  - 查询某个卖家某段时间内的交易记录，Rowkey设计为`[seller id][timestmap][order number]`。
  - 查询某个买家某段时间内的交易记录，Rowkey设计为`[buyer id][timestmap][order number]`。
  - 根据订单号查询，Rowkey设计为`[order number]`。
  - 查询中同时满足三张表，一张买家维度表Rowkey设计为`[buyer id][timestmap][order number]`。一张卖家维度表Rowkey设计为`[seller id][timestmap][order number]`。一张订单索引表Rowkey设计为`[order number]`。