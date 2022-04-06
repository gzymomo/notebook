# 一、Kafka高效读写

## 1.顺序写磁盘

Kafka 的 producer 生产数据，要写入到log文件中，**写的过程是一直追加到文件末端**， 为**顺序写**。官网有数据表明，同样的磁盘**顺序写**能到 **600M/s**，而**随机写**只有 **100K/s**。这与磁盘的机械机构有关，顺序写之所以快，是因为其**省去了大量磁头寻址的时间**。

## 2.零复制技术

![](https://img-blog.csdnimg.cn/20210518153206129.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3BhbmppYW5sb25nV1VIQU4=,size_16,color_FFFFFF,t_70)

---

# 二、Zookeeper 在 Kafka 中的作用

Kafka 集群中有**一个 broker** 会被**选举为 Controller**，负责**管理集群 broker 的上下线**，**所有 topic 的分区副本分配**和 **leader 选举**等工作。

Controller 的管理工作都是依赖于 Zookeeper 的。 以下为 partition 的 leader 选举过程

![](https://img-blog.csdnimg.cn/20210518153419325.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3BhbmppYW5sb25nV1VIQU4=,size_16,color_FFFFFF,t_70)

---

# 三、Kafka事务

Kafka 从 0.11 版本开始引入了事务支持。**事务可以保证 Kafka 在 Exactly Once 语义的基础上**，**生产和消费可以跨分区和会话**，**要么全部成功，要么全部失败**。

## 1. Producer事务

为了实现跨分区跨会话的事务，需要引入一个**全局唯一**的 **Transaction ID**，并**将 Producer 获得的 PID 和 Transaction ID 绑定**。这样当 **Producer 重启后**就可以**通过正在进行的 Transaction ID 获得原来的 PID**。

为了管理 Transaction，Kafka 引入了一个**新的组件 Transaction Coordinator**。**Producer 就是通过和 Transaction Coordinator 交互获得 Transaction ID 对应的任务状态**。Transaction Coordinator 还负责**将事务所有写入 Kafka 的一个内部 Topic，这样即使整个服务重启，由于事务状态得到保存，进行中的事务状态可以得到恢复，从而继续进行**。

## 2.Consumer事务

对于 Consumer 而言，事务的保证就会相对较弱，**尤其时无法保证 Commit 的信息被精确消费**。这是由于 **Consumer 可以通过 offset 访 问任意信息**，而且不同的 Segment File 生命周期不同，同一事务的消息可能会出现重启后被删除的情况。
