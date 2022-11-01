- [【Hadoop】Hadoop集群组件默认端口 - DBArtist - 博客园 (cnblogs.com)](https://www.cnblogs.com/DBArtist/p/15628117.html)

这里包含使用到的组件：HDFS, YARN, HBase, Hive, ZooKeeper:

| 组件      | 节点              | 默认端口    | 配置                                                         | 用途说明                                                     |
| --------- | ----------------- | ----------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| HDFS      | DataNode          | 50010       | dfs.datanode.address                                         | datanode服务端口，用于数据传输                               |
| HDFS      | DataNode          | 50075       | dfs.datanode.http.address                                    | http服务的端口                                               |
| HDFS      | DataNode          | 50475       | dfs.datanode.https.address                                   | https服务的端口                                              |
| HDFS      | DataNode          | 50020       | dfs.datanode.ipc.address                                     | ipc服务的端口                                                |
| HDFS      | NameNode          | 50070       | dfs.namenode.http-address                                    | http服务的端口                                               |
| HDFS      | NameNode          | 50470       | dfs.namenode.https-address                                   | https服务的端口                                              |
| HDFS      | NameNode          | 8020        | fs.defaultFS                                                 | 接收Client连接的RPC端口，用于获取文件系统metadata信息。      |
| HDFS      | journalnode       | 8485        | dfs.journalnode.rpc-address                                  | RPC服务                                                      |
| HDFS      | journalnode       | 8480        | dfs.journalnode.http-address                                 | HTTP服务                                                     |
| HDFS      | ZKFC              | 8019        | dfs.ha.zkfc.port                                             | ZooKeeper FailoverController，用于NN HA                      |
| YARN      | ResourceManager   | 8032        | yarn.resourcemanager.address                                 | RM的applications manager(ASM)端口                            |
| YARN      | ResourceManager   | 8030        | yarn.resourcemanager.scheduler.address                       | scheduler组件的IPC端口                                       |
| YARN      | ResourceManager   | 8031        | yarn.resourcemanager.resource-tracker.address                | IPC                                                          |
| YARN      | ResourceManager   | 8033        | yarn.resourcemanager.admin.address                           | IPC                                                          |
| YARN      | ResourceManager   | 8088        | yarn.resourcemanager.webapp.address                          | http服务端口                                                 |
| YARN      | NodeManager       | 8040        | yarn.nodemanager.localizer.address                           | localizer IPC                                                |
| YARN      | NodeManager       | 8042        | yarn.nodemanager.webapp.address                              | http服务端口                                                 |
| YARN      | NodeManager       | 8041        | yarn.nodemanager.address                                     | NM中container manager的端口                                  |
| YARN      | JobHistory Server | 10020       | mapreduce.jobhistory.address                                 | IPC                                                          |
| YARN      | JobHistory Server | 19888       | mapreduce.jobhistory.webapp.address                          | http服务端口                                                 |
| HBase     | Master            | 60000/16000 | hbase.master.port                                            | IPC                                                          |
| HBase     | Master            | 60010/16010 | hbase.master.info.port                                       | http服务端口                                                 |
| HBase     | RegionServer      | 60020/16020 | hbase.regionserver.port                                      | IPC                                                          |
| HBase     | RegionServer      | 60030/16030 | hbase.regionserver.info.port                                 | http服务端口                                                 |
| HBase     | HQuorumPeer       | 2181        | hbase.zookeeper.property.clientPort                          | HBase-managed ZK mode，使用独立的ZooKeeper集群则不会启用该端口。 |
| HBase     | HQuorumPeer       | 2888        | hbase.zookeeper.peerport                                     | HBase-managed ZK mode，使用独立的ZooKeeper集群则不会启用该端口。 |
| HBase     | HQuorumPeer       | 3888        | hbase.zookeeper.leaderport                                   | HBase-managed ZK mode，使用独立的ZooKeeper集群则不会启用该端口。 |
| Hive      | Metastore         | 9083        | /etc/default/hive-metastore中export PORT=来更新默认端口      |                                                              |
| Hive      | HiveServer        | 10000       | /etc/hive/conf/hive-env.sh中export HIVE_SERVER2_THRIFT_PORT=来更新默认端口 |                                                              |
| ZooKeeper | Server            | 2181        | /etc/zookeeper/conf/zoo.cfg中clientPort=                     | 对客户端提供服务的端口                                       |
| ZooKeeper | Server            | 2888        | /etc/zookeeper/conf/zoo.cfg中server.x=[hostname]:nnnnn[:nnnnn]，标蓝部分 | follower用来连接到leader，只在leader上监听该端口。           |
| ZooKeeper | Server            | 3888        | /etc/zookeeper/conf/zoo.cfg中server.x=[hostname]:nnnnn[:nnnnn]，标蓝部分 | 用于leader选举的。只在electionAlg是1,2或3(默认)时需要。      |