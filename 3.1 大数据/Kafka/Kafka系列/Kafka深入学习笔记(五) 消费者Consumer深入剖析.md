# 一、 消费方式

Consumer采用**Pull(拉)**模式从**broke**中读取数据。

**Push(推)**模式**很难适应消费速率不同的消费者**，因为消息发送速率是由 broker 决定的。 它的目标是**尽可能以最快速度传递消息**，但是这样**很容易造成 consumer 来不及处理消息**，典型的表现就是拒绝服务以及网络拥塞。而 **Pull** 模式则**可以根据 consumer 的消费能力以适当的速率消费消息**。

**Pull(拉)** 模式不足之处是，**如果 kafka 没有数据，消费者可能会陷入循环中，一直返回空数据**。针对这一点，Kafka 的消费者在消费数据时会传入一个**时长参数 timeout**，如果当前没有 数据可供消费，consumer 会等待一段时间之后再返回，这段时长即为 timeout。

---

# 二、 分区分配策略

一个 consumer group 中有多个 consumer，一个 topic 有多个 partition，所以必然会涉及 到 partition 的分配问题，即确定那个 partition 由哪个 consumer 来消费。

Kafka 有两种**分配策略**，一是 RoundRobin，一是 Range。

> 1. **RoundRobin** **轮询调度** 针对**消费组**
> 
> 2. **Range**  针对**Topic**

![](https://img-blog.csdnimg.cn/20210518151903982.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3BhbmppYW5sb25nV1VIQU4=,size_16,color_FFFFFF,t_70)

## 1. RoundRobin

![](https://img-blog.csdnimg.cn/20210518102646271.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3BhbmppYW5sb25nV1VIQU4=,size_16,color_FFFFFF,t_70)

## 2. Range

![](https://img-blog.csdnimg.cn/20210518151837168.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3BhbmppYW5sb25nV1VIQU4=,size_16,color_FFFFFF,t_70)

---

# 三、offset维护

由于 consumer 在消费过程中可能会出现**断电宕机等故障**，**consumer恢复后，需要从故障前的位置的继续消费**，所以 **consumer需要实时记录自己消费到了哪个offset，以便故障恢复后继续消费**。

从 0.9 版本开始， consumer 默认将 **offset** 保存在 **Kafka 一个内置的 topic 中**，该 topic 为**__consumer_offsets**

![](https://img-blog.csdnimg.cn/20210518152234678.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3BhbmppYW5sb25nV1VIQU4=,size_16,color_FFFFFF,t_70)

消费时会按照 **消费组GroupName + TopicName + Partition** 来进行记录

![](https://img-blog.csdnimg.cn/20210518111416195.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3BhbmppYW5sb25nV1VIQU4=,size_16,color_FFFFFF,t_70)
