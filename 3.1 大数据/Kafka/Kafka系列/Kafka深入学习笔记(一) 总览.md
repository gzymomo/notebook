[Kafka深入学习笔记(一) 总览](https://blog.csdn.net/panjianlongWUHAN/article/details/116937236)

[Kafka深入学习笔记(二) Kafka常用命令](https://blog.csdn.net/panjianlongWUHAN/article/details/116939053)

[Kafka深入学习笔记(三) Kafka工作流程](https://blog.csdn.net/panjianlongWUHAN/article/details/116939549)

[Kafka深入学习笔记(四) 生产者Producer深入剖析](https://blog.csdn.net/panjianlongWUHAN/article/details/116941713)

[Kafka深入学习笔记(五) 消费者Consumer深入剖析](https://blog.csdn.net/panjianlongWUHAN/article/details/116978492)

[Kafka深入学习笔记(六) Kafka高效读写 & Zookeeper & 事务](https://blog.csdn.net/panjianlongWUHAN/article/details/116991132)

[Kafka深入学习笔记(七) Kafka监控系统Eagle](https://blog.csdn.net/panjianlongWUHAN/article/details/116993495)

# 一、定义

Kafka 是一个**分布式**的基于**发布/订阅模式**的**消息队列**(Message Queue)，主要应用于**大数据实时处理**领域。

# 二、消息队列

![](https://img-blog.csdnimg.cn/20210517161407633.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3BhbmppYW5sb25nV1VIQU4=,size_16,color_FFFFFF,t_70)

## 1. 使用消息队列的好处

> （1）**解耦** 允许你独立的扩展或修改两边的处理过程，只要确保它们遵守同样的接口约束。
> 
> （2）**可恢复性**  系统的一部分组件失效时，不会影响到整个系统。消息队列**降低了进程间的耦合度**，所以即使一个处理消息的进程挂掉，加入队列中的消息仍然可以**在系统恢复后被处理**。
> 
> （3）**缓冲** 有助于**控制和优化数据流经过系统的速度**，解决生产消息和消费消息的处理速度不一致 的情况。
> 
> （4）**灵活性** & **峰值处理能力** 在**访问量剧增**的情况下，应用仍然需要继续发挥作用，但是这样的突发流量并不常见。如果为以能处理这类峰值访问为标准来投入资源随时待命无疑是巨大的浪费。使用消息队列 能够使**关键组件顶住突发的访问压力**，而不会因为突发的超负荷的请求而完全崩溃。
> 
> （5）**异步通信** 很多时候，用户不想也不需要立即处理消息。消息队列提供了异步处理机制，**允许用户把一个消息放入队列，但并不立即处理它**。想向队列中放入多少消息就放多少，然后在需要 的时候再去处理它们。

## 2. 消息队列的两种模式

### (1) 点对点模式

**(一对一，消费者主动拉取数据，消息收到后消息清除)**

> 1.消息生产者生产消息发送到 Queue 中，然后消息消费者从 Queue 中取出并且消费消息。
> 
> 2.消息被消费以后，**queue 中不再有存储**，所以消息消费者**不可能消费到已经被消费的消息**。
> 
> 3.Queue 支持存在多个消费者，但是对一个消息而言，**只会有一个消费者可以消费**。

![](https://img-blog.csdnimg.cn/20210517162303822.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3BhbmppYW5sb25nV1VIQU4=,size_16,color_FFFFFF,t_70)

### (2) 发布/订阅模式

**(****一对多****，消费者消费数据之后不会清除消息)**

> 1.消息生产者(发布)将消息发布到 topic 中
> 
> 2.**同时有多个消息消费者**(订阅)消费该消息。
> 
> 3.和点对点方式不同，发布到 topic 的消息会**被所有订阅者消费**。

![](https://img-blog.csdnimg.cn/20210517162511807.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3BhbmppYW5sb25nV1VIQU4=,size_16,color_FFFFFF,t_70)

---

# 三、Kafka基础架构

![](https://img-blog.csdnimg.cn/2021051716261793.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3BhbmppYW5sb25nV1VIQU4=,size_16,color_FFFFFF,t_70)

## 1.Producer: 消息生产者

> 向 kafka broker **发消息**的客户端

## 2.Consumer: 消息消费者

> kafka broker **取消息**的客户端

## 3.Consumer Group (CG): 消费者组

> 1.由**多个 consumer 组成**
> 
> 2.消费者组内**每个消费者**负责**消费不同分区的数据**，一个分区只能由一个组内消费者消费, **消费者组之间互不影响**
> 
> 3.所有的消费者都属于某个消费者组，即**消费者组是逻辑上的一个订阅者**

## 4.Broker: 一台 kafka 服务器就是一个 broker

> 一个集群由多个 broker 组成, 一个 broker 可以容纳多个 topic。

## 5.Topic: 一个队列

> 可以理解为一个队列，**生产者和消费者面向的都是一个 topic**

## 6.Partition: 分区

> 为了实现扩展性，一个非常大的 topic 可以**分布到多个** broker(即服务器)上， 一个 topic 可以分为多个 partition，**每个 partition 是一个有序的队列**

## 7.Replica: 副本

> 为保证集群中的某个节点发生**故障时**，该节点上的 **partition 数据不丢失**，且 kafka 仍然能够继续工作，kafka 提供了**副本**机制，一个 topic 的**每个分区都有若干个副本**， **一个 leader 和若干个 follower**

## 8.Leader: 主分区

> 每个分区多个副本的“主”，生产者发送数据的对象，以及消费者消费数据的对象都是 leader。

## 9.Follower: 从分区

> 每个分区多个副本中的“从”，**实时从 leader 中同步数据**，保持和 leader **数据 的同步**。**leader 发生故障时，某个 follower 会成为新的 leader**
