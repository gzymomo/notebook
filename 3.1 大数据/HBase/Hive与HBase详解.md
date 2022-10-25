- [图解大数据 | Hive与HBase详解@海量数据库查询-阿里云开发者社区 (aliyun.com)](https://developer.aliyun.com/article/891395)

## 1.大数据与数据库

### 1）从Hadoop到数据库

大家知道在计算机领域，关系数据库大量用于数据存储和维护的场景。大数据的出现后，很多公司转而选择像 Hadoop/Spark 的大数据解决方案。

Hadoop使用分布式文件系统，用于存储大数据，并使用MapReduce来处理。Hadoop擅长于存储各种格式的庞大的数据，任意的格式甚至非结构化的处理。

### 2）Hadoop的限制

Hadoop非常适合批量处理任务，但它只以顺序方式访问数据。这意味着如果要查询，必须搜索整个数据集，即使是最简单的搜索工作。

当处理结果在另一个庞大的数据集，也是按顺序处理一个巨大的数据集。在这一点上，一个新的解决方案，需要访问数据中的任何点（随机访问）单元。

### 3）HBase与大数据数据库

**HBase是建立在Hadoop文件系统之上的分布式面向列的数据库**。

HBase是一个数据模型，类似于谷歌的Bigtable设计，可以提供快速随机访问海量结构化数据。它利用了Hadoop的文件系统（HDFS）提供的容错能力。

它是Hadoop的生态系统，提供对数据的随机实时读/写访问，是Hadoop文件系统的一部分。我们可以直接或通过HBase的存储HDFS数据。使用HBase在HDFS读取消费/随机访问数据。 HBase在Hadoop的文件系统之上，并提供了读写访问。

## 2.BigTable与HBase

要提到HBase，就要顺带提到google的**Bigtable**。**HBase**是在谷歌**BigTable**的基础之上进行开源实现的，是一个高可靠、高性能、面向列、可伸缩的分布式数据库，可以用来存储非结构化和半结构化的稀疏数据。

### 1）结构化数据和非结构化数据

BigTable和HBase存储的都是非结构化数据。

![海量数据库与查询; Hive与HBase详解; BigTable与HBase; 结构化数据&非结构化数据; 6-1](https://img-blog.csdnimg.cn/img_convert/0c5e7d3ba217141534a0d72b9c918b30.png)

### 2）BigTable简介

BigTable是一个用于管理结构化数据的分布式存储系统，构建在GFS、Chubby、SSTable等google技术之上。本质上说，BigTable是一个稀疏的、分布式的、持久化的、多维的、排序的键值（key-value）映射。

![海量数据库与查询; Hive与HBase详解; BigTable与HBase; BigTable简介; 6-2](https://img-blog.csdnimg.cn/img_convert/7c96baffffe9c26cbe17ca6570eb48fa.png)

### 3）HBase简介

- HBase是一个高可靠、高性能、面向列、可伸缩的分布式数据库，是谷歌BigTable的开源实现。
- HBase主要用来存储非结构化和半结构化的松散数据，目标是处理非常庞大的表，可以通过水平扩展的方式，利用廉价计算机集群处理由超过10亿行数据和数百万列元素组成的数据表。

![海量数据库与查询; Hive与HBase详解; BigTable与HBase; HBase简介; 6-3](https://img-blog.csdnimg.cn/img_convert/49c6e15bdddffe07d564da60bea44fd7.png)

### 4）HBase在大数据生态环境中的位置

HBase在大数据生态环境中的位置如下图所示，它建立在Hadoop HDFS之上的分布式面向列的数据库。

![海量数据库与查询; Hive与HBase详解; BigTable与HBase; HBase在大数据生态环境中的位置; 6-4](https://img-blog.csdnimg.cn/img_convert/996dfcea7d1cdc275efc9d8dbcb6ac1a.png)

### 5）HBase的特点

如下图所示，HBase有以下特点：

![海量数据库与查询; Hive与HBase详解; BigTable与HBase; HBase的特点; 6-5](https://img-blog.csdnimg.cn/img_convert/77a2638642ae5bbd870947dbae0d6052.png)

- **大**：一个表可以有上亿行，上百万列。
- **面向列**：面向列表(簇)的存储和权限控制，列(簇)独立检索。
- **稀疏**：对于为空(NULL)的列，并不占用存储空间，因此，表可以设计的非常稀疏。
- **无模式**：每一行都有一个可以排序的主键和任意多的列，列可以根据需要动态增加，同一张表中不同的行可以有截然不同的列。
- **数据多版本**：每个单元的数据有多个版本，默认情况下，版本号是单元格插入时的时间戳。
- **数据类型单一**：HBase中的数据都是字符串，没有类型。　

### 6）HBase的访问接口

| 类型            | 特点                                         | 场合                                          |
| :-------------- | :------------------------------------------- | :-------------------------------------------- |
| Native Java API | 最常规和高效的访问方式                       | 适合Hadoop MapReduce作业并行批处理HBase表数据 |
| HBase Shell     | HBase的命令行工具 最简单的接口               | 适合HBase管理使用                             |
| Thrift Gateway  | 利用Thrift序列化技术 支持C++、PHP、Python等  | 适合其他异构系统在线访问HBase表数据           |
| REST Gateway    | 解除了语言限制                               | 支持REST风格的Http API访问HBase               |
| Pig             | 使用Pig Latin流式编程语言来处理HBase中的数据 | 适合做数据统计                                |
| Hive            | 简单                                         | 当需要以类似SQL语言方式来访问HBase的时候      |

## 3.HBase数据模型

### 1）逻辑存储模型

| 组件                     | 描述                                                         |
| :----------------------- | :----------------------------------------------------------- |
| 表 Table                 | HBase采用表来组织数据，表由行和列组成，列划分为若干个列族    |
| 行 Row                   | 每个HBase表都由若干行组成，每个行由行键（row key）来标识     |
| 列族 Column Family       | 一个HBase表被分组成许多“列族”（Column Family）的集合         |
| 列限定符Column Qualifier | 列族里的数据通过列限定符（或列）来定位                       |
| 单元格 Cell              | 通过行、列族和列限定符确定一个单元格，单元格中存储的数据都视为byte |
| 时间戳 Times tamp        | 同一份数据的多个版本，时间戳用于索引数据版本                 |

HBase中需要根据行键、列族、列限定符和时间戳来确定一个单元格。因此，可以视为一个“四维坐标”，即 `[行键, 列族, 列限定符, 时间戳]` 。

![海量数据库与查询; Hive与HBase详解; HBase数据模型; 逻辑存储模型; 6-6](https://img-blog.csdnimg.cn/img_convert/c3ccb6da75b473546a5a0efbe3a39b8e.png)

### 2）物理存储模型

Table在行的方向上分割为多个Region，每个Region分散在不同的RegionServer中。

![海量数据库与查询; Hive与HBase详解; HBase数据模型; 物理存储模型; 6-7](https://img-blog.csdnimg.cn/img_convert/7732c45816142580cffbc513eb68a6eb.png)

每个HRegion由多个Store构成，每个Store由一个MemStore和0或多个StoreFile组成，每个Store保存一个Columns Family。StoreFile以HFile格式存储在HDFS中。

![海量数据库与查询; Hive与HBase详解; HBase数据模型; 物理存储模型; 6-8](https://img-blog.csdnimg.cn/img_convert/776c67cedf5c6cf23ea7d7b83f20ac59.png)

## 4.HBase系统架构

### 1）HBase架构组件

HBase包含以下三个组件：

- Region Server：提供数据的读写服务，当客户端访问数据时，直接和Region Server通信。
- HBase Master：Region的分配，DDL操作(创建表，删除表)。
- ZooKeeper：是HDFS的一部分，维护一个活跃的集群状态。

![海量数据库与查询; Hive与HBase详解; HBase系统架构; HBase架构组件; 6-9](https://img-blog.csdnimg.cn/img_convert/f1f4c8fa45dd6ffab4fee0fcd2ddad23.png)

### 2）Region组件

HBase Tables 通过行健的范围(row key range)被水平切分成多个Region。一个Region包含了所有的在Region开始键(startKey)和结束键(endKey)之内的行。
Regions被分配到集群的节点上，成为Region Servers，提供数据的读写服务；一个Region Server可以服务1000个Region。

![海量数据库与查询; Hive与HBase详解; HBase系统架构; HBase架构组件; Region; 6-10](https://img-blog.csdnimg.cn/img_convert/f1534230351830bbca572c733386d72d.png)

### 3）HMaster组件

![海量数据库与查询; Hive与HBase详解; HBase系统架构; HBase架构组件; HMaster; 6-11](https://img-blog.csdnimg.cn/img_convert/cb2667c28c13e2425dbd5bcfcf523c6c.png)

- 分配Region，DDL操作(创建表， 删除表)。
- 协调各个Reion Server：在启动时分配Region、在恢复或是负载均衡时重新分配Region；监控所有集群当中的Region Server实例，从ZooKeeper中监听通知。
- 提供创建、删除、更新表的接口。

### 4）ZooKeeper组件

![海量数据库与查询; Hive与HBase详解; HBase系统架构; HBase架构组件; ZooKeeper; 6-12](https://img-blog.csdnimg.cn/img_convert/6ab56575d1e5ea348ec653fbdeb70b7f.png)

- HBase使用ZooKeeper作为分布式协调服务，来维护集群中的Server状态。
- ZooKeeper维护着哪些Server是活跃或是可用的，提供Server 失败时的通知。
- Zookeeper使用一致性机制来保证公共的共享状态，注意，需要使用奇数的三台或五台机器，保证一致。

## 5.Hive介绍

### 1）Hive简介

Hive是基于Hadoop的一个数据仓库工具，用于结构化数据的查询、分析和汇总。Hive提供类SQL查询功能，它将SQL转换为MapReduce程序。

Hive不支持OLTP，Hive无法提供实时查询。

### 2）Hive在大数据生态环境中的位置

![海量数据库与查询; Hive与HBase详解; Hive介绍; Hive在大数据; 生态环境中的位置; 6-13](https://img-blog.csdnimg.cn/img_convert/8a60a92bf1a6a26a3db1906e208374bc.png)

### 3）Hive特点

**Hive的优点**

- 简单容易上手：提供了类SQL查询语言HQL。
- 可扩展：一般情况下不需要重启服务Hive可以自由的扩展集群的规模。
- 提供统一的元数据管理。
- 延展性：Hive支持用户自定义函数，用户可以根据自己的需求来实现自己的函数。
- 容错：良好的容错性，节点出现问题SQL仍可完成执行。

![海量数据库与查询; Hive与HBase详解; Hive介绍; Hive特点; 6-14](https://img-blog.csdnimg.cn/img_convert/62dd258c2952bf981f79486612c7da41.png)

**Hive的缺点(局限性)**

- Hive的HQL表达能力有限：迭代式算法无法表达，比如pagerank；数据挖掘方面，比如kmeans。
- Hive的效率比较低：Hive自动生成的MapReduce作业，不够智能化；Hive调优比较困难，粒度较粗；Hive可控性差。

### 4）Hive与传统数据库对比

![海量数据库与查询; Hive与HBase详解; Hive介绍; Hive VS 传统数据库; 6-15](https://img-blog.csdnimg.cn/img_convert/26c6110854d492e76050eb6188c44eca.png)

### 5）Hive的体系架构

![海量数据库与查询; Hive与HBase详解; Hive介绍; Hive的体系架构; 6-16](https://img-blog.csdnimg.cn/img_convert/28a9600e4a63e081d5bd26bba523ed79.png)

- client 三种访问方式：CLI、JDBC/ODBC、WEBUI。
- Meta store 元数据：表名、表所属数据库、表拥有者、列、分区字段、表类型、表数据所在的目录等，默认存储在自带的derby数据库中。
- Driver：解析器、编译器、优化器、执行器。

### 6）Hive中的数据模型

![海量数据库与查询; Hive与HBase详解; Hive介绍; Hive中的数据模型; 6-17](https://img-blog.csdnimg.cn/img_convert/1353ff5b237cbd428a89b71d6173c348.png)

Hive 中所有的数据都存储在 HDFS 中Hive 中包含以下数据模型：

- 表(Table)
- 外部表(External Table)
- 分区(Partition)
- 桶(Bucket)

## 6.SQL介绍与Hive应用场景

### 1）数据库操作和表操作

| 作用                 | HiveQL                                                       |
| :------------------- | :----------------------------------------------------------- |
| 查看所有数据库       | SHOW DATABASES;                                              |
| 使用指定的数据库     | USE database_name;                                           |
| 创建指定名称的数据库 | CREATE DATABASE database_name;                               |
| 删除数据库           | DROP DATABASE database_name;                                 |
| 创建表               | CREATE TABLE pokes (foo INT, bar STRING)                     |
| 查看所有的表         | SHOW TABLES                                                  |
| 支持模糊查询         | SHOW TABLES 'TMP'                                            |
| 查看表有哪些分区     | SHOW PARTITIONS TMP_TABLE                                    |
| 查看表结构           | DESCRIBE TMP_TABLE                                           |
| 创建表并创建索引ds   | CREATE TABLE invites (foo INT, bar STRING) PARTITIONED BY (ds STRING) |
| 复制一个空表         | CREATE TABLE empty_key_value_store LIKE key_value_store      |
| 表添加一列           | ALTER TABLE pokes ADD COLUMNS (new_col INT)                  |
| 更改表名             | ALTER TABLE events RENAME TO 3koobecaf                       |

### 2）查询语句

| 作用               | HiveQL                                                       |
| :----------------- | :----------------------------------------------------------- |
| 检索信息           | SELECT from_columns FROM table WHERE conditions;             |
| 选择所有的数据     | SELECT * FROM table;                                         |
| 行筛选             | SELECT * FROM table WHERE rec_name = "value";                |
| 多个限制条件       | SELECT * FROM TABLE WHERE rec1 = "value1" AND rec2 = "value2"; |
| 选择多个特定的列   | SELECT column_name FROM table;                               |
| 检索unique输出记录 | SELECT DISTINCT column_name FROM table;                      |
| 排序               | SELECT col1, col2 FROM table ORDER BY col2;                  |
| 逆序               | SELECT col1, col2 FROM table ORDER BY col2 DESC;             |
| 统计行数           | SELECT COUNT(*) FROM table;                                  |
| 分组统计           | SELECT owner, COUNT(*) FROM table GROUP BY owner;            |
| 求某一列最大值     | SELECT MAX(col_name) AS label FROM table;                    |
| 从多个表中检索信息 | SELECT pet.name, comment FROM pet JOIN event ON (pet.name = event.name); |

### 3）Hive的应用场景

Hive并不适合需要低延迟的应用，适合于大数据集的批处理作业：

- 日志分析：大部分互联网公司使用hive进行日志分析，包括百度、淘宝等。例如，统计网站一个时间段内的pv、uv，多维度数据分析等。
- 海量结构化数据离线分析。

### 4）Hive和HBase的区别与联系

![海量数据库与查询; Hive与HBase详解; SQL介绍&Hive应用; Hive VS HBase; 6-18](https://img-blog.csdnimg.cn/img_convert/06e15dc2a4ea30c268209c0fb17b3a2b.png)

## 参考资料

- Lars George 著，代志远 / 刘佳 / 蒋杰 译，《 HBase权威指南》，东南大学出版社，2012
- Edward Capriolo / Dean Wampler)/ Jason Rutherglen 著，曹坤 译，《Hive编程指南》，人民邮电出版社，2013
- 深入了解HBase架构： https://blog.csdn.net/Lic_LiveTime/article/details/79818695
- APACHE HIVE TM：http://hive.apache.org/
- Apache HBase ™ Reference Guide：http://hbase.apache.org/book.html