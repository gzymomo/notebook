[Kafka深入学习笔记(一) 总览](https://blog.csdn.net/panjianlongWUHAN/article/details/116937236)

[Kafka深入学习笔记(二) Kafka常用命令](https://blog.csdn.net/panjianlongWUHAN/article/details/116939053)

[Kafka深入学习笔记(三) Kafka工作流程](https://blog.csdn.net/panjianlongWUHAN/article/details/116939549)

[Kafka深入学习笔记(四) 生产者Producer深入剖析](https://blog.csdn.net/panjianlongWUHAN/article/details/116941713)

[Kafka深入学习笔记(五) 消费者Consumer深入剖析](https://blog.csdn.net/panjianlongWUHAN/article/details/116978492)

[Kafka深入学习笔记(六) Kafka高效读写 & Zookeeper & 事务](https://blog.csdn.net/panjianlongWUHAN/article/details/116991132)

[Kafka深入学习笔记(七) Kafka监控系统Eagle](https://blog.csdn.net/panjianlongWUHAN/article/details/116993495)



# 一、工作流程图

![](https://img-blog.csdnimg.cn/20210517165840386.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3BhbmppYW5sb25nV1VIQU4=,size_16,color_FFFFFF,t_70)

Kafka 中消息是以 **topic** **进行分类**的，生产者生产消息，消费者消费消息，都是**面向 topic** 的。

**topic** 是**逻辑上**的概念，而 **partition** 是**物理上**的概念，**每个 partition 对应于一个 log 文件，该 log 文件中存储的就是 producer 生产的数据**。Producer 生产的数据会被**不断追加到该 log 文件末端**，且**每条数据都有自己的 offset**。消费者组中的每个消费者，都会实时记录自己消费到了哪个 offset，以便出错恢复时，从上次的位置继续消费。

---

# 二、Kafka文件存储机制

![](https://img-blog.csdnimg.cn/20210517172245511.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3BhbmppYW5sb25nV1VIQU4=,size_16,color_FFFFFF,t_70)

由于生产者生产的消息会不断追加到 log 文件末尾，为防止 log 文件过大导致数据定位效率低下，Kafka 采取了**分片**和**索引**机制，将**每个 partition 分为多个 segment**。每个 segment 对应两个文件——**“.index”文件**和**“.log”文件**。

这些文件位于一个文件夹下，该文件夹的命名 规则为:topic 名称+分区序号。例如，first 这个 topic 有三个分区，则其对应的文件夹为 first- 0,first-1,first-2。

> ```html
> 00000000000000000000.index
> 00000000000000000000.log
> 00000000000000170410.index
> 00000000000000170410.log
> 00000000000000239430.index
> 00000000000000239430.log
> ```

 index 和 log 文件以当前 segment 的第一条消息的 offset 命名。下图为 index 文件和 log 文件的结构示意图。**“.index”文件存储大量的索引信息**，**“.log”文件存储大量的数据**，索引文件中的元 数据指向对应数据文件中 message 的物理偏移地址。

![](https://img-blog.csdnimg.cn/20210517172513790.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3BhbmppYW5sb25nV1VIQU4=,size_16,color_FFFFFF,t_70)
