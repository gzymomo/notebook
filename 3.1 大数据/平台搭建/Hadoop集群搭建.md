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

| 节点   |      |      |      |      |      |      |      |      |      |      |
| ------ | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- |
| node1  |      |      |      |      |      |      |      |      |      |      |
| node2  |      |      |      |      |      |      |      |      |      |      |
| node3  |      |      |      |      |      |      |      |      |      |      |
| node4  |      |      |      |      |      |      |      |      |      |      |
| node5  |      |      |      |      |      |      |      |      |      |      |
| node6  |      |      |      |      |      |      |      |      |      |      |
| node7  |      |      |      |      |      |      |      |      |      |      |
| node8  |      |      |      |      |      |      |      |      |      |      |
| node9  |      |      |      |      |      |      |      |      |      |      |
| node10 |      |      |      |      |      |      |      |      |      |      |
| node11 |      |      |      |      |      |      |      |      |      |      |

