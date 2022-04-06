- [SpringBoot整合MQTT( EMQ) - Forever丶随风 - 博客园 (cnblogs.com)](https://www.cnblogs.com/Forever-wind/p/14894597.html)
- [SpringBoot 集成 MQTT - 云天 - 博客园 (cnblogs.com)](https://www.cnblogs.com/tqlin/p/14566458.html)
- [Springboot中使用MQTT的详细教程 | w3c笔记 (w3cschool.cn)](https://www.w3cschool.cn/article/6048135.html)
- [SpringBoot 集成MQTT配置 ](https://www.cnblogs.com/itdragon/p/12463050.html)

## 1 SpringBoot集成MQTT配置

### 1.1 MQTT连接配置文件

```properties
# MQTT Config
mqtt.server=tcp://x.x.x.x:1883
mqtt.username=xxx
mqtt.password=xxx
mqtt.client-id=clientID
mqtt.cache-number=100
mqtt.message.topic=itDragon/tags/cov
```

### 1.2 配置MQTT订阅者

[Inbound 入站消息适配器](https://www.cnblogs.com/itdragon/)

第一步：配置MQTT客户端工厂类DefaultMqttPahoClientFactory

第二步：配置MQTT入站消息适配器MqttPahoMessageDrivenChannelAdapter

第三步：定义MQTT入站消息通道MessageChannel

第四步：声明MQTT入站消息处理器MessageHandler

**以下有些配置是冲突或者重复的，主要是体现一些重要配置。**

```java
package com.itdragon.server.config

import com.itdragon.server.message.ITDragonMQTTMessageHandler
import org.eclipse.paho.client.mqttv3.MqttConnectOptions
import org.springframework.beans.factory.annotation.Value
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.integration.annotation.ServiceActivator
import org.springframework.integration.channel.DirectChannel
import org.springframework.integration.core.MessageProducer
import org.springframework.integration.mqtt.core.DefaultMqttPahoClientFactory
import org.springframework.integration.mqtt.core.MqttPahoClientFactory
import org.springframework.integration.mqtt.inbound.MqttPahoMessageDrivenChannelAdapter
import org.springframework.integration.mqtt.support.DefaultPahoMessageConverter
import org.springframework.messaging.MessageChannel
import org.springframework.messaging.MessageHandler
import java.time.Instant

@Configuration
class MQTTConfig {

    @Value("\${mqtt.server}")
    lateinit var mqttServer: String
    @Value("\${mqtt.user-name}")
    lateinit var mqttUserName: String
    @Value("\${mqtt.password}")
    lateinit var mqttUserPassword: String
    @Value("\${mqtt.client-id}")
    lateinit var clientID: String
    @Value("\${mqtt.cache-number}")
    lateinit var maxMessageInFlight: String
    @Value("\${mqtt.message.topic}")
    lateinit var messageTopic: String

    /**
     * 配置DefaultMqttPahoClientFactory
     * 1. 配置基本的链接信息
     * 2. 配置maxInflight，在mqtt消息量比较大的情况下将值设大
     */
    fun mqttClientFactory(): MqttPahoClientFactory {
        val mqttConnectOptions = MqttConnectOptions()
        // 配置mqtt服务端地址,登录账号和密码
        mqttConnectOptions.serverURIs = arrayOf(mqttServer)
        mqttConnectOptions.userName = mqttUserName
        mqttConnectOptions.password = mqttUserPassword.toCharArray()
        // 配置最大不确定接收消息数量，默认值10，qos!=0 时生效
        mqttConnectOptions.maxInflight = maxMessageInFlight.toInt()
        val factory = DefaultMqttPahoClientFactory()
        factory.connectionOptions = mqttConnectOptions
        return factory
    }

    /**
     * 配置Inbound入站，消费者基本连接配置
     * 1. 通过DefaultMqttPahoClientFactory 初始化入站通道适配器
     * 2. 配置超时时长，默认30000毫秒
     * 3. 配置Paho消息转换器
     * 4. 配置发送数据的服务质量 0~2
     * 5. 配置订阅通道
     */
    @Bean
    fun itDragonMqttInbound(): MessageProducer {
        // 初始化入站通道适配器，使用的是Eclipse Paho MQTT客户端库
        val adapter = MqttPahoMessageDrivenChannelAdapter(clientID + Instant.now().toEpochMilli(), mqttClientFactory(), messageTopic)
        // 设置连接超时时长(默认30000毫秒)
        adapter.setCompletionTimeout(30000)
        // 配置默认Paho消息转换器(qos=0, retain=false, charset=UTF-8)
        adapter.setConverter(DefaultPahoMessageConverter())
        // 设置服务质量
        // 0 最多一次，数据可能丢失;
        // 1 至少一次，数据可能重复;
        // 2 只有一次，有且只有一次;最耗性能
        adapter.setQos(0)
        // 设置订阅通道
        adapter.outputChannel = itDragonMqttInputChannel()
        return adapter
    }

    /**
     * 配置Inbound入站，消费者订阅的消息通道
     */
    @Bean
    fun itDragonMqttInputChannel(): MessageChannel {
        return DirectChannel()
    }

    /**
     * 配置Inbound入站，消费者的消息处理器
     * 1. 使用@ServiceActivator注解，表明所修饰的方法用于消息处理
     * 2. 使用inputChannel值，表明从指定通道中取值
     * 3. 利用函数式编程的思路，解耦MessageHandler的业务逻辑
     */
    @Bean
    @ServiceActivator(inputChannel = "itDragonMqttInputChannel")
    fun commandDataHandler(): MessageHandler {
        /*return MessageHandler { message ->
            println(message.payload)
        }*/
        return ITDragonMQTTMessageHandler()
    }

}
```

注意：

- 1）MQTT的客户端ID要唯一。
- 2）MQTT在消息量大的情况下会出现消息丢失的情况。
- 3）MessageHandler注意解耦问题。

### 1.3 配置MQTT发布者

[Outbound 出站消息适配器](https://www.cnblogs.com/itdragon/)

第一步：配置Outbound出站，出站通道适配器

第二步：配置Outbound出站，发布者发送的消息通道

第三步：对外提供推送消息的接口

在原有的MQTTConfig配置类的集成上补充以下内容

```java
/**
     * 配置Outbound出站，出站通道适配器
     * 1. 通过MqttPahoMessageHandler 初始化出站通道适配器
     * 2. 配置异步发送
     * 3. 配置默认的服务质量
     */
@Bean
@ServiceActivator(inputChannel = "itDragonMqttOutputChannel")
fun itDragonMqttOutbound(): MqttPahoMessageHandler {
    // 初始化出站通道适配器，使用的是Eclipse Paho MQTT客户端库
    val messageHandler = MqttPahoMessageHandler(clientID + Instant.now().toEpochMilli() + "_set", mqttClientFactory())
        // 设置异步发送，默认是false(发送时阻塞)
        messageHandler.setAsync(true)
        // 设置默认的服务质量
        messageHandler.setDefaultQos(0)
        return messageHandler
}

/**
     * 配置Outbound出站，发布者发送的消息通道
     */
@Bean
fun itDragonMqttOutputChannel(): MessageChannel {
    return DirectChannel()
}

/**
     * 对外提供推送消息的接口
     * 1. 使用@MessagingGateway注解，配置MQTTMessageGateway消息推送接口
     * 2. 使用defaultRequestChannel值，调用时将向其发送消息的默认通道
     * 3. 配置灵活的topic主题
     */
@MessagingGateway(defaultRequestChannel = "itDragonMqttOutputChannel")
interface MQTTMessageGateway {
    fun sendToMqtt(data: String, @Header(MqttHeaders.TOPIC) topic: String)
        fun sendToMqtt(data: String, @Header(MqttHeaders.QOS) qos: Int, @Header(MqttHeaders.TOPIC) topic: String)
}
```

注册MessageHandler

```java
package com.itdragon.server.message

    import org.slf4j.LoggerFactory
    import org.springframework.beans.factory.annotation.Autowired
    import org.springframework.stereotype.Service
    import javax.annotation.PostConstruct

    @Service
    class ITDragonMessageDispatcher {

        private val logger = LoggerFactory.getLogger(ITDragonMessageDispatcher::class.java)

            @Autowired
            lateinit var itDragonMQTTMessageHandler: ITDragonMQTTMessageHandler

                @PostConstruct
                fun init() {
                itDragonMQTTMessageHandler.registerHandler { itDragonMsgHandler(it) }
            }

        fun itDragonMsgHandler(message: String) {
            logger.info("itdragon mqtt receive message: $message")
                try {
                    // todo
                }catch (ex: Exception) {
                    ex.printStackTrace()
                }
        }

    }
```

#### 1.3.1 消息发送

注入MQTT的MessageGateway，然后推送消息。

```java
@Autowired
lateinit var mqttGateway: MQTTConfig.MQTTMessageGateway

    @Scheduled(fixedDelay = 10*1000)
    fun sendMessage() {
    mqttGateway.sendToMqtt("Hello ITDragon ${Instant.now()}", "itDragon/tags/cov/set")
}
```

## 开发常见问题

### 1 MQTT每次重连失败都会增长线程数

项目上线一段时间后，客户的服务器严重卡顿。原因是客户服务断网后，MQTT在每次尝试重连的过程中一直在创建新的线程，导致一个Java服务创建了上万个线程。解决方案是更新了org.eclipse.paho.client.mqttv3的版本，也是 "3.1 导入mqtt库" 中提到的。后续就没有出现这个问题了。

### 2 MQTT消息量大存在消息丢失的情况

MQTT的消息量大的情况下，既要保障数据的完整，又要保障性能的稳定。光从MQTT本身上来说，很难做到鱼和熊掌不可兼得。[ITDragon龙](https://www.cnblogs.com/itdragon/) 先要理清需求：

- 1）数据的完整性，主要用于能耗的统计、报警的分析
- 2）性能的稳定性，服务器不挂

在消息量大的情况下，[ITDragon龙](https://www.cnblogs.com/itdragon/) 可以将服务质量设置成0（最多一次）以减少消息确认的开销，用来保证系统的稳定性。

将消息的服务质量设置成0后，会让消息的丢失可能性变得更大，如何保证数据的完整性？其实[ITDragon龙](https://www.cnblogs.com/itdragon/) 可以在往MQTT通道推送消息之前，先将底层驱动采集的数据先异步保存到[Inflxudb数据库](https://www.cnblogs.com/itdragon/p/11897185.html)中。

还有就是每次发送消息量不能太大，太大也会导致消息丢失。最直接的就是后端报错，比如：`java.io.EOFException` 和 `too large message: xxx bytes` 。但是有的场景后端没有报错，前端订阅的mqtt也没收到消息。最麻烦的是mqttbox工具因为数据量太大直接卡死。一时间真不知道把锅甩给谁。其实[我们](https://www.cnblogs.com/itdragon/) 可以将消息拆包一批批发送。可以缓解这个问题。

其实采集的数据消息，若在这一批推送过程中丢失。也会在下一批推送过程中补上。命令下发也是一样，如果下发失败，再重写下发一次。毕竟消息的丢失并不是必现的情况。也是小概率事件，系统的稳定性才是最重要的。
