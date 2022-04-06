- [使用docker-compose部署Kafka集群 - 没有星星的夏季 - 博客园 (cnblogs.com)](https://www.cnblogs.com/shanfeng1000/p/14638455.html)

- [docker-compose部署kafka集群_xujingyiss的博客-CSDN博客](https://blog.csdn.net/xujingyiss/article/details/119249048)

- [基于docker的高可用kafka集群部署 - Ethan_x - 博客园 (cnblogs.com)](https://www.cnblogs.com/ethanxzw/p/14954641.html)



# 前提准备

需要提前安装好 docker 和 docker-compose

# 下载镜像

众所周知，[kafka](https://so.csdn.net/so/search?q=kafka&spm=1001.2101.3001.7020) 依赖于 zookeeper，所以需要还安装 zookeeper，这里将 zookeeper 和 kafka 镜像都拉取下来。

```bash
version: '3'
services:
  zookeeper:
    image: zookeeper
    ports:
      - 2182:2181
    restart: always
```

wurstmeister/kafka 镜像的 dockerhub 地址：https://hub.docker.com/r/wurstmeister/kafka。这里也有简易的教程可以参考，不过是英文的。

# 目录结构

> /data/docker-compose  
>     docker-compose.yml  
>     | kafka  
>         | broker1/logs  
>         | broker2/logs  
>         | broker3/logs

# 部署 zookeeper

部署 zookeeper 极其简单（这里就不部署集群了），配置如下：

```vbnet
version: '3'services:  zookeeper:    image: zookeeper    ports:      - 2182:2181    restart: always
```

然后执行 docker-compose up -d --build zookeeper，就启动了 zookeeper。

zookeeper 地址为：10.68.4.1:2182

# 编写 docker-compose.yml

> **我希望集群中有3个borker，topic 的分区数为3，每个分区有2个副本**

## 参数规则

通过 docker-compose 和 wurstmeister/kafka 镜像部署 kafka 时，最重要的就是 environment 参数的配置。

如果是直接在宿主机上部署 kafka，那我们直接在配置文件中修改对应的参数就行了，但是这里有一些不同。

下面是参数规则的说明：

![](https://img-blog.csdnimg.cn/20210730154958992.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3h1amluZ3lpc3M=,size_16,color_FFFFFF,t_70)

从红框中的内容可以看出，要配置一个 kafka 参数，那在 docker-compose.yml 的 environment 中，需要在参数前加上 "KAFKA_" 前缀，并把 kafka 参数转大写，然后将 "." 替换成 "_"  

例如参数 zookeeper.connect ，在 docker-compose 中就是：KAFKA_ZOOKEEPER_CONNECT

## 最终配置

所以 docker-compose-yml 中配置了3个服务：kafka1，kafka2，kafka3。各自在宿主机上的端口分别为 9093，9094，9095。

```javascript
version: '3'
services:
  zookeeper:
    image: zookeeper
    ports:
      - 2182:2181
    restart: always
  
  kafka1:
    image: wurstmeister/kafka
    container_name: kafka1
    ports:
      - "9093:9092"
    environment:
      KAFKA_BROKER_ID: 0
      KAFKA_NUM_PARTITIONS: 3
      KAFKA_DEFAULT_REPLICATION_FACTOR: 2
      KAFKA_ZOOKEEPER_CONNECT: 10.68.4.1:2182
      KAFKA_LISTENERS: PLAINTEXT://0.0.0.0:9092
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://10.68.4.1:9093
    volumes:
      - /data/docker-compose/kafka/broker1/logs:/opt/kafka/logs
      - /var/run/docker.sock:/var/run/docker.sock
    restart: always
 
  kafka2:
    image: wurstmeister/kafka
    container_name: kafka2
    ports:
      - "9094:9092"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_NUM_PARTITIONS: 3
      KAFKA_DEFAULT_REPLICATION_FACTOR: 2
      KAFKA_ZOOKEEPER_CONNECT: 10.68.4.1:2182
      KAFKA_LISTENERS: PLAINTEXT://0.0.0.0:9092
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://10.68.4.1:9094
    volumes:
      - /data/docker-compose/kafka/broker2/logs:/opt/kafka/logs
      - /var/run/docker.sock:/var/run/docker.sock
    restart: always
  
  kafka3:
    image: wurstmeister/kafka
    container_name: kafka3
    ports:
      - "9095:9092"
    environment:
      KAFKA_BROKER_ID: 2
      KAFKA_NUM_PARTITIONS: 3
      KAFKA_DEFAULT_REPLICATION_FACTOR: 2
      KAFKA_ZOOKEEPER_CONNECT: 10.68.4.1:2182
      KAFKA_LISTENERS: PLAINTEXT://0.0.0.0:9092
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://10.68.4.1:9095
    volumes:
      - /data/docker-compose/kafka/broker3/logs:/opt/kafka/logs
      - /var/run/docker.sock:/var/run/docker.sock
    restart: always
```

| 服务名       | 地址        | 端口   |
| --------- | --------- | ---- |
| zookeeper | 10.68.4.1 | 2182 |
| kafka1    | 10.68.4.1 | 9093 |
| kafka2    | 10.68.4.1 | 9094 |
| kafka3    | 10.68.4.1 | 9095 |

## 参数说明

> KAFKA_BROKER_ID: 0  
> KAFKA_NUM_PARTITIONS：topic的分区数  
> KAFKA_DEFAULT_REPLICATION_FACTOR：分区的副本数  
> KAFKA_ZOOKEEPER_CONNECT：zookeeper地址  
> KAFKA_LISTENERS：容器内访问的地址  
> KAFKA_ADVERTISED_LISTENERS：容器外访问的地址

# 启动/停止 kafka 服务

```haskell
# 创建 kafka 容器并启动
docker-compose up -d --build kafka1
docker-compose up -d --build kafka2
docker-compose up -d --build kafka3
 
# 停止 kafka 容器
docker-compose stop kafka1
docker-compose stop kafka2
docker-compose stop kafka3
```

docker-compose ps 确认是否部署成功，可以看到3个容器都启动成功了。

# ![](https://img-blog.csdnimg.cn/20210730163655377.png)

# Springboot集成kafka

## pom.xml 配置

```xml
<dependency>
  <groupId>org.springframework.kafka</groupId>
  <artifactId>spring-kafka</artifactId>
</dependency>
```

## application.yml 配置

```vbnet
spring:
  kafka:
    bootstrap-servers: 10.68.4.1:9093,10.68.4.1:9094,10.68.4.1:9095
    listener:
      missing-topics-fatal: false
    producer:
      retries: 0
      batch-size: 16384
      buffer-memory: 33554432
      key-serializer: org.apache.kafka.common.serialization.StringSerializer
      value-serializer: org.apache.kafka.common.serialization.StringSerializer
    consumer:
      group-id: demo-group
      auto-commit-interval: 100
      enable-auto-commit: true
      auto-offset-reset: earliest
      key-deserializer: org.apache.kafka.common.serialization.StringDeserializer
      value-deserializer: org.apache.kafka.common.serialization.StringDeserializer
```

## producer

```typescript
@RestController
@RequestMapping("/kafka")
public class KafkaProducer {
    @Autowired
    private KafkaTemplate<String, Object> kafkaTemplate;
 
    @GetMapping("/msg/{message}")
    public void sendMessage(@PathVariable("message") String normalMessage) {
        log.info("message received : " + normalMessage);
        kafkaTemplate.send("messages", normalMessage);
        log.info("Kafka message [" + normalMessage + "] send success!");
    }
}
```

## consumer

```csharp
@Component
public class KafkaConsumer {
    // 消费监听
    @KafkaListener(topics = {"messages"})
    public void receiveMessages(ConsumerRecord<?, ?> record){
        // 消费的哪个topic、partition的消息,打印出消息内容
        log.info("简单消费：" + record.topic() + "-" + record.partition() + "-" + record.value());
    }
}
```

## 测试

发送http请求 localhost:8091/kafka/msg/Hello_Wrold 后，可以成功发送kafka消息，并自动消费，并打印对于日志
