- [Hadoop Ha + Hbase + Spark高可用集群搭建手册_花信風-Ling的博客-CSDN博客_hadoop spark 高可用](https://blog.csdn.net/czladamling/article/details/121282315)

- [Docker本地搭建Hadoop高可用,Hbase,Spark,Flink,Zookeeper集群_小满锅lock的博客-CSDN博客_docker hadoop hbase kafka zookeeper spark](https://blog.csdn.net/weixin_43272605/article/details/105257394)

- [hadoop3.3.4+flink1.15.2+hbase2.5.0集群搭建当前最新大宝and小宝的博客-CSDN博客_hbase 集群安装](https://blog.csdn.net/hailishen/article/details/127303209)

- [Hadoop搭建高可用集群（保姆级教程）_万家林的博客-CSDN博客_hadoop高可用集群](https://blog.csdn.net/weixin_44911081/article/details/121141778)

- [七、Hadoop3.3.1 HA 高可用集群QJM （基于Zookeeper，NameNode高可用+Yarn高可用） - 李好秀 - 博客园 (cnblogs.com)](https://www.cnblogs.com/lehoso/p/15591387.html)
- [大数据完全分布式集群安装搭建hadoop、hbase、hive、spark、flink（二） - 掘金 (juejin.cn)](https://juejin.cn/post/7143227416096276510)
- [Docker（ for Windows） 搭建hadoop集群 - 简书 (jianshu.com)](https://www.jianshu.com/p/648cc55149cf)





## 1 HA集群搭建

| 节点  | Nn   | Rm   | DFSZK | Dn   | Nm   | Jn   | Zoo  | spark | Hm   | Hr   |
| ----- | ---- | ---- | ----- | ---- | ---- | ---- | ---- | ----- | ---- | ---- |
| node1 | √    | √    | √     |      |      |      |      | √     | √    |      |
| node2 | √    | √    | √     |      |      |      |      | √     |      |      |
| node3 |      |      |       | √    | √    | √    | √    | √     |      | √    |
| node4 |      |      |       | √    | √    | √    | √    | √     |      | √    |
| node5 |      |      |       | √    | √    | √    | √    | √     |      | √    |
| node6 |      |      |       | √    | √    |      |      | √     |      | √    |

| 集群                        | 版本号 | 端口  |
| --------------------------- | ------ | ----- |
| Hadoop                      | 3.2.2  | 9870  |
| Yarn                        | 3.2.2  | 8088  |
| MapReduce JobHistory Server | 3.2.2  | 19888 |
| Spark-master                | 3.1.2  | 8080  |
| Spark-histoory              | 3.1.2  | 4000  |
| hbase                       | 2.2.7  | 16010 |
| Zookeeper                   | 3.4.6  | 2181  |

| 缩写  | 全称                    | 作用                        |
| ----- | ----------------------- | --------------------------- |
| Nm    | Namenode                | 元数据节点                  |
| Rm    | ResourceManager         | yarn资源管理节点            |
| DFSZK | DFSZKFailoverController | zookeeper监控节点,Ha配置    |
| Dn    | Datanode                | 数据节点                    |
| Nm    | NodeManager             | yarn单节点管理,与Rm通信     |
| Jn    | JournalNode             | 同步NameNode之间数据,Ha配置 |
| Zoo   | Zookeeper               | zookeeper集群               |
| Hm    | HMaster                 | Hbase主节点                 |
| Hr    | HRegionServer           | Hbase从节点                 |



## 2 生产集群

### 2.1 集群规划1

| 1                          | 2                             | 3                                                            | 4                          | 5                           |
| -------------------------- | ----------------------------- | ------------------------------------------------------------ | -------------------------- | --------------------------- |
| DataNode（50075改为57775） | DataNode                      | DataNode                                                     | DataNode                   | DataNode                    |
| NodeManager                | NodeManager                   | NodeManager                                                  | NodeManager                | NodeManager                 |
|                            |                               | ResourceManager（active/8088）                               | ResourceManager（standby） |                             |
| NameNode（standby）        | NameNode（active/9870/19888） |                                                              |                            |                             |
|                            |                               | Zookeeper（master）                                          | Zookeeper                  | Zookeeper                   |
|                            |                               | Kafka                                                        | Kafka                      | Kafka                       |
|                            |                               | Flume                                                        | Flume                      | Flume                       |
|                            |                               | Hbase（active）                                              | Hbase（standby）           | Hbase                       |
|                            |                               | Phoenix                                                      | Phoenix                    | Phoenix                     |
|                            |                               |                                                              |                            |                             |
| Hive（灾备）               |                               |                                                              |                            | Hive（hiveservices2/10000） |
| Mysql（灾备）              |                               |                                                              |                            | Mysql（端口号改为3506）     |
| Spark（灾备）              |                               |                                                              |                            | Spark                       |
|                            |                               |                                                              |                            |                             |
|                            |                               | Solr                                                         | Solr                       | Solr（web/8983）            |
|                            |                               |                                                              |                            | Atlas（web/21000）          |
|                            |                               |                                                              |                            | Sqoop/Datax                 |
| Node Exporter（9100）      | Node Exporter（9100）         | Prometheus（web/9090）Grafana（web/3000）Node Exporter（9100） | Node Exporter（9100）      | Node Exporter（9100）       |
|                            |                               |                                                              |                            |                             |
|                            |                               |                                                              |                            | flink                       |
|                            |                               | Dolphin-worker                                               | worker                     | worker-master（12345）      |

### 2.2 集群规划2

|  节点  |  ZK  |  NN  |  DN  |  RM  | JN   |  NM  |  HM  | HRS  | 节点监控 | 内存 | 硬盘 | 核数 |
| :----: | :--: | :--: | :--: | :--: | ---- | :--: | :--: | :--: | :------: | :--: | ---- | ---- |
| node1  |      |  Y   |      |  Y   |      |      |  Y   |      |    Y     | 128G | 2T   | 16   |
| node2  |      |  Y   |      |  Y   |      |      |  Y   |      |    Y     | 128G | 2T   | 16   |
| node3  |  Y   |      |  Y   |      | Y    |  Y   |      |  Y   |    Y     | 128G | 5T   | 16   |
| node4  |  Y   |      |  Y   |      | Y    |  Y   |      |  Y   |    Y     | 128G | 5T   | 16   |
| node5  |  Y   |      |  Y   |      | Y    |  Y   |      |  Y   |    Y     | 128G | 5T   | 16   |
| node6  |      |      |  Y   |      |      |  Y   |      |  Y   |    Y     | 128G | 5T   | 16   |
| node7  |      |      |  Y   |      |      |  Y   |      |  Y   |    Y     | 128G | 5T   | 16   |
| node8  |      |      |  Y   |      |      |  Y   |      |  Y   |    Y     | 128G | 5T   | 16   |
| node9  |      |      |  Y   |      |      |  Y   |      |  Y   |    Y     | 128G | 5T   | 16   |
| node10 |      |      |  Y   |      |      |  Y   |      |  Y   |    Y     | 128G | 5T   | 16   |

| 节点   | Prometheus+Grafna | 节点监控 | 内存 | 硬盘 |
| ------ | ----------------- | -------- | ---- | ---- |
| node11 | Y                 | Y        | 16G  | 200G |



- ZK：Zookeeper（分布式协调系统，用来协调服务）
- NN：Hadoop NameNode（负责协调集群上的数据存储）
- DN：Hadoop DataNode（**NodeManager** 和 **DataNode** 角色主要用于计算和存储，为了获得更好的性能，通常将 NodeManager 和 DataNode 部署在一起）
- RM：Hadoop ResourceManager（负责协调计算分析）
- NM：Hadoop NodeManager（负责启动和管理节点上的容器）
- HM：HBase HMaster（Master维护 Table 和 Region 的元数据信息，负载很低）
- HRS：HBase RegionServer（主要负责响应用户I/O请求。向HDFS中读写数据（读写数据和Master没关系））
- JN：Hadoop JournalNode（解决了数据的同步的问题）

存储规划：目前一年55T估算，每个机器80%的存储计算，则一年数据总共大概需要68.75T约等于70T。

数据格式，建议使用parquet，其压缩算法整体要优于JSON和CSV格式。根据实际情况选择合适的压缩算法。

**1.对 NameNode、ResourceManager 及其 Standby NameNode 节点硬件配置**

对于 **CPU**，可根据资金预算，选择 8 核、10 核或者 12 核。

对于**内存**，常用的计算公式是集群中 100 万个块（HDFS blocks）对应 NameNode 需要 1GB 内存，如果你的集群规模在 100 台以内，NameNode 服务器的内存配置一般选择 128GB 即可。

由于 NameNode 以及 Standby NameNode 两个节点需要存储 HDFS 的元数据，所以需要配置**数据盘**，数据盘建议至少配置 4 块，每两块做 raid1，做两组 raid1；然后将元数据分别镜像存储到这两个 raid1 磁盘组中。而对于 ResourceManager，由于不需要存储重要数据，因而，数据盘可不配置。

**2.对 NodeManager、DataNode 节点服务器硬件配置**

由于 NodeManager、DataNode 主要用于计算和存储，所以对 **CPU** 性能要求会比较高。

**内存**方面，如果分布式计算中涉及 Spark、HBase 组件，那么建议配置大内存。

**磁盘**方面，DataNode 节点主要用来存储数据，所以需要配置大量磁盘。

