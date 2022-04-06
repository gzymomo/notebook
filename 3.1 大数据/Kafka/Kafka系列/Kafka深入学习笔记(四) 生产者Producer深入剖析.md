# 一、分区策略

## 1.分区的原因

> 1.**方便在集群中扩展**  每个 Partition可以通过调整以适应它所在的机器，而一个 topic又可以有多个 Partition 组成，因此**整个集群就可以适应任意大小的数据**了
> 
> 2.**可以提高并发**  可以以 Partition 为单位进行读写

## 2.分区的原则

我们需要将producer**发送的的数据****封装成**一个**ProducerRecord对象**

![](https://img-blog.csdnimg.cn/20210517174818280.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3BhbmppYW5sb25nV1VIQU4=,size_16,color_FFFFFF,t_70)

(1)指明 partition 的情况下，直接将指明的值直接作为 partiton 值;

(2)**没有指明** partition 值但**有 key** 的情况下，将key的hash值与topic 的partition 数**进行取余**得到 partition 值;

(3)**既没有 partition 值又没有 key 值**的情况下，第一次调用时随机生成一个整数(后 面每次调用在这个整数上自增)，将这个值与 topic 可用的 partition 总数取余得到 partition 值，也就是常说的 **round-robin** 算法

---

# 二、数据的可靠性保证

为保证 producer 发送的数据，能**可靠的发送到**指定的 topic，topic 的每个 partition **收到 producer 发送的数据后**，都需要**向 producer 发送 ack**(acknowledgement 确认收到)，如果 producer 收到 ack，就会进行下一轮的发送，**否则重新发送数据**。

![](https://img-blog.csdnimg.cn/20210517175129621.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3BhbmppYW5sb25nV1VIQU4=,size_16,color_FFFFFF,t_70)

## 1.副本数据同步策略

| 方案                | 优点                                        | 缺点                                         |
| ----------------- | ----------------------------------------- | ------------------------------------------ |
| 半数以上完成同步，就发 送 ack | 延迟低                                       | 选举新的 leader 时，**容忍 n 台节点的故障，需要 2n+1 个副 本** |
| 全部完成同步，才发送ack     | 选举新的 leader 时，**容忍 n 台节点的故障，需要 n+1 个副 本** | 延迟高                                        |

Kafka 选择了**第二种方案**，原因如下:

> 1.同样为了容忍 n 台节点的故障，第一种方案需要 2n+1 个副本，而第二种方案只需要 n+1 个副本，而 Kafka 的每个分区都有大量的数据，**第一种方案会造成大量数据的冗余**。
> 
> 2.虽然第二种方案的网络延迟会比较高，但网络延迟对 Kafka 的影响较小。

## 2.ISR (in-sync replica set)

采用第二种方案之后，设想以下情景: leader 收到数据，所有 follower 都开始同步数据， 但有一个 follower，因为某种故障，迟迟不能与 leader 进行同步，那 leader 就要一直等下去， 直到它完成同步，才能发送 ack。**这个问题怎么解决呢?**

Leader 维护了一个动态的 in-[sync](https://so.csdn.net/so/search?q=sync&spm=1001.2101.3001.7020) replica set (ISR)，意为**和 leader 保持同步的 follower 集合**。**当 ISR 中的 follower 完成数据的同步之后，leader 就会给 follower 发送 ack**。**如果 follower 长时间未向 leader 同步数据，则该 follower 将被踢出 ISR**，该时间阈值由**replica.lag.time.max.ms** 参数设定。**Leader 发生故障之后，就会从 ISR 中选举新的 leader**。

## 3.ack应答机制

对于某些不太重要的数据，对数据的可靠性要求不是很高，能够容忍数据的少量丢失，所以没必要等 ISR 中的 follower 全部接收成功。2                                                                                          所以 Kafka 为用户提供了三种可靠性级别，用户根据对可靠性和延迟的要求进行权衡， 选择以下的配置。

| 配置编号 | 描述                                                                              | 存在的问题                                                             |
| ---- | ------------------------------------------------------------------------------- | ----------------------------------------------------------------- |
| 0    | producer **不等待 broker 的 ack**，这一操作提供了一个**最低的延迟**，broker 一接收到还 没有写入磁盘就已经返回       | 当 broker 故障时有**可能丢失数据**                                           |
| 1    | producer **等待 broker 的 ack**，partition 的 **leader 落盘成功后返回 ack**                 | 如果在 **follower 同步成功之前 leader 故障**，那么将会**丢失数据**                    |
| -1   | producer **等待 broker 的 ack**，partition 的 **leader 和 follower 全部落盘成功后才 返回 ack**。 | 如果在 **follower 同步完成后，broker 发送 ack 之前，leader 发生故障**，那么会造成**数据重复** |

**acks =** **1** **数据****丢失****案例**

![](https://img-blog.csdnimg.cn/20210518095705652.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3BhbmppYW5sb25nV1VIQU4=,size_16,color_FFFFFF,t_70)

**acks =** **-1** **数据****重复****案例**

![](https://img-blog.csdnimg.cn/20210518095819739.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3BhbmppYW5sb25nV1VIQU4=,size_16,color_FFFFFF,t_70)

## 4.故障处理细节

> **HW**(High Watermark) 所有副本中最小的LEO
> 
> **LEO**(Log End Offset) 每个副本的最后一个offset

 ![](https://img-blog.csdnimg.cn/20210518100321201.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3BhbmppYW5sb25nV1VIQU4=,size_16,color_FFFFFF,t_70)

### (1)Follower故障

follower 发生故障后会**被临时踢出 ISR**，待该 follower 恢复后，follower 会**读取本地磁盘记录的上次的 HW**，并**将 log 文件高于 HW 的部分截取掉**，**从 HW 开始向 leader 进行同步**。 **等该 follower 的 LEO 大于等于该 Partition 的 HW，即 follower 追上 leader 之后，就可以重 新加入 ISR 了**

### **(2)Leader故障**

leader 发生故障之后，会**从 ISR 中选出一个新的 leader**，之后为保证多个副本之间的数据一致性，**其余的 follower 会先将各自的 log 文件高于 HW 的部分截掉**，然后**从新的 leader 同步数据**。

```html
注意:这只能保证副本之间的数据一致性，并不能保证数据不丢失或者不重复
```

---

# 三、Exactly Once

> At **Least** Once 将服务器的 ACK 级别设置为**-1**，可以保证 Producer 到 Server 之间**不会丢失数据，****但是不能保证数据不重复**
> 
> At **Most** Once 将服务器 ACK 级别设置为 **0**，可以保证**生产者每条消息只会被发送一次，****但是不能保证数据不丢失**

对于一些非常重要的信息，比如说交易数据，下游数据消费者**要求数据既不重复也不丢失**，即 **Exactly Once** 语义

0.11 版本的 Kafka，引入了一项重大特性:**幂等性**。所谓的幂等性就是指 **Producer 不论向 Server 发送多少次重复数据，Server 端都只会持久化一条**。幂等性结合 At Least Once 语 义，就构成了 Kafka 的 Exactly Once 语义。

> **At Least Once + 幂等性 = Exactly Once**

要启用幂等性，只需要将 Producer 的参数中 **enable.idompotence** 设置为 **true** 即可。Kafka的幂等性实现其实就是将原来**下游需要做的去重放在了数据上游**。开启幂等性的 Producer 在 初始化的时候会被分配一个 **PID**，发往同一 Partition 的消息会附带 **Sequence Number**。而 Broker 端会对**<PID, Partition, SeqNumber>**做缓存，当具有**相同主键的消息提交时，Broker 只 会持久化一条**。但是 PID 重启就会变化，同时不同的 Partition 也具有不同主键，所以幂等性无法保证跨 分区跨会话的 Exactly Once。

---

# 四、消息发送流程

Kafka 的 Producer 发送消息采用的是**异步发送**的方式。在消息发送的过程中，涉及到了**两个线程——main 线程和 Sender 线程**，以及**一个线程共享变量——RecordAccumulator**。 **main 线程将消息发送给 RecordAccumulator**，**Sender 线程不断从 RecordAccumulator 中拉取 消息发送到 Kafka broker**。

相关参数

> **batch.size** : 只有**数据积累到 batch.size** 之后，**sender 才会发送数据**
> 
> **linger.ms** : 如果**数据迟迟未达到 batch.size**，**sender 等待 linger.time 之后就会发送数据**。

![](https://img-blog.csdnimg.cn/20210518154218498.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3BhbmppYW5sb25nV1VIQU4=,size_16,color_FFFFFF,t_70)
