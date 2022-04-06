[Kafka深入学习笔记(一) 总览](https://blog.csdn.net/panjianlongWUHAN/article/details/116937236)

[Kafka深入学习笔记(二) Kafka常用命令](https://blog.csdn.net/panjianlongWUHAN/article/details/116939053)

[Kafka深入学习笔记(三) Kafka工作流程](https://blog.csdn.net/panjianlongWUHAN/article/details/116939549)

[Kafka深入学习笔记(四) 生产者Producer深入剖析](https://blog.csdn.net/panjianlongWUHAN/article/details/116941713)

[Kafka深入学习笔记(五) 消费者Consumer深入剖析](https://blog.csdn.net/panjianlongWUHAN/article/details/116978492)

[Kafka深入学习笔记(六) Kafka高效读写 & Zookeeper & 事务](https://blog.csdn.net/panjianlongWUHAN/article/details/116991132)

[Kafka深入学习笔记(七) Kafka监控系统Eagle](https://blog.csdn.net/panjianlongWUHAN/article/details/116993495)

## 1.查看当前服务器中的所有 topic

```python
bin/kafka-topics.sh --zookeeper hadoop102:2181 --list
```

## 2.创建 topic

```python
bin/kafka-topics.sh --zookeeper hadoop102:2181 --create --replication-factor 3 --partitions 1 -- topic first
```

选项说明:

--topic 定义 topic 名

--replication-factor **定义副本数**

--partitions **定义分区数**

## **3.删除topic**

```javascript
bin/kafka-topics.sh --zookeeper hadoop102:2181 --delete --topic first
```

需要 server.properties 中设置 **delete.topic.enable=true,**否则只是标记删除

## 4.发送消息

```javascript
bin/kafka-console-producer.sh --broker- list hadoop102:9092 --topic first
>hello world
>atguigu atguigu
```

## 5.消费消息

```javascript
bin/kafka-console-consumer.sh --zookeeper hadoop102:2181 --topic firstbin/kafka-console-consumer.sh --bootstrap-server hadoop102:9092 --from-beginning --topic first
```

## 6.查看某个 Topic 的详情

```python
bin/kafka-topics.sh --zookeeper hadoop102:2181 --describe --topic first
```

## 7.修改分区数

```python
bin/kafka-topics.sh --zookeeper hadoop102:2181 --alter --topic first --partitions 6
```
