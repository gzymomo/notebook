- [Kafka消费者](https://blog.51cto.com/u_15491030/4987441)

**对Kafka消费者的封装**。

## 0x1. kafka消费者应该怎么划分

之前对工程产生一些合理划分包的思考——关于Kafka消费者这个包应该放哪里的问题。

在一开始，kafka包是放在各个业务领域包里面的，只作用于当前业务领域。

但是仔细一想：**作为kafka消费者，会接收生产者发送的消息，然后作用到不同的业务领域进行消费。**

举个例子：

![Kafka消费者这样写，一年节省10,000行代码_代码_02](https://s6.51cto.com/images/blog/202202/07134353_6200b199f37a134072.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)

财务中心（以下简称fms）消费订单中心（以下简称oms）推送过来的支付成功消息OrderPayMessage，一开始fms只需要根据支付成功消息生成支付流水（属于商家账单bbill商家账单），kafka包被划分到bbill包下，消费者需要调用bbill下的Service实现类来生成支付流水；

后续产品加了需求，fms还需要根据这条消息创建返现记录（属于activitysettlement活动结算），那这时候怎么办？

显然bbill.kafka.consumer包下面的消费者调用
activitysettlement.service包是不合理的，之所以通过包来划分业务领域，就是想要解耦，方便后续每个子业务领域拆分。

那么，**由于业务场景的扩充，实际的代码就需要加以调整**。

kafka应该在业务领域包之外，至少是同级关系，于是我把kafka包移到了最外层：

![Kafka消费者这样写，一年节省10,000行代码_代码_03](https://s6.51cto.com/images/blog/202202/07134353_6200b199eeca21727.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)

这只是一个例子，以kafka包划分作为切入口，考虑包划分的合理性，其它也是同理的。

**但这样就合理了吗？不！**

再细一层思考，kafka包移到了最外层，变成了kafka依赖其它业务领域包，万一其它包独立出去了呢？kafka包还是要跟着调整。

而且kafka本来就属于中间件，应该是属于某些业务领域下程序的entry point，比如Controller是前端的入口，KafkaListener是kafka消息的入口。

我们应该再解耦一次，把依赖关系倒置过来。



------



## 0x2. 引入中间层解耦

说到大家熟悉的依赖倒置，第一个想到什么？没错，这是Spring的特性。

**解耦常用的方法就是引入一层中间层**，就像Spring引入了Bean容器一样，kafka与业务领域之间也可以引入一层中间层。

于是我写了一层中间层TopicConsumer，放到common包下面，作为存放KafkaTopic与各个业务实现之间关系与逻辑的容器。

**国际惯例，设计先行：**

![Kafka消费者这样写，一年节省10,000行代码_代码_04](https://s8.51cto.com/images/blog/202202/07134354_6200b19a1497c32110.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)

画得比较抽象，咱们还是看代码吧。

**"Talk is low, show me the code!"**

先建个topicconsumer包，方便以后移植到架构组。

![Kafka消费者这样写，一年节省10,000行代码_kafka_05](https://s6.51cto.com/images/blog/202202/07134354_6200b19a15ffc85344.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)

**TopicConsumer注解**

不多解释，看代码注释。

![Kafka消费者这样写，一年节省10,000行代码_spring_06](https://s7.51cto.com/images/blog/202202/07134353_6200b199ee0d243867.jpg?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)

TopicConsumer.java

```
package com.xxx.fms.common.topicconsumer;

import org.springframework.core.annotation.AliasFor;

import java.lang.annotation.*;
import java.util.concurrent.TimeUnit;

/**
 * Topic消费者
 * 配合Topic执行器使用，通过TopicExecutor.exec执行一批被@TopicConsumer注解的方法
 * 默认定义topic即可反序列化解析到第一个对象参数，无参不解析
 *
 * @author Jensen 公众号：架构师修行录
 */
@Documented
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
public @interface TopicConsumer {
    // 本地主题
    @AliasFor("value")
    String topic() default "DEFAULT";

    // 本地主题
    @AliasFor("topic")
    String value() default "DEFAULT";

    /**
     * 是否异步执行，默认：异步
     *
     * @return
     */
    boolean async() default true;

    /**
     * 是否允许重复，根据Topic+MD5(value)判断是否重复，默认：不允许重复
     */
    boolean allowRepeat() default false;

    /**
     * 防重失效时间，默认：15天
     *
     * @return
     */
    long timeout() default 15L;

    /**
     * 防重失效时间单位，默认：天
     *
     * @return
     */
    TimeUnit timeUnit() default TimeUnit.DAYS;

    /**
     * 反序列化器
     *
     * @return
     */
    Class deserializer() default JsonStringDeserializer.class;
}
```

**Topic执行器**

TopicExecutor.java

```
package com.xxx.fms.common.topicconsumer;

import com.xxx.boot.starter.redis.utils.RedisUtils;
import com.xxx.pub.utils.SpringContext;
import com.xxx.pub.utils.text.HashUtils;
import lombok.Builder;
import lombok.Getter;
import lombok.Setter;
import lombok.extern.slf4j.Slf4j;
import org.apache.logging.log4j.util.Strings;
import org.springframework.beans.BeansException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.beans.factory.config.BeanPostProcessor;
import org.springframework.boot.autoconfigure.task.TaskExecutionAutoConfiguration;
import org.springframework.context.ApplicationContext;
import org.springframework.context.ApplicationContextAware;
import org.springframework.core.annotation.AnnotationUtils;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;
import org.springframework.stereotype.Component;
import org.springframework.util.ReflectionUtils;

import java.lang.reflect.Method;
import java.nio.charset.StandardCharsets;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Topic执行器
 *
 * @author Jensen 公众号：架构师修行录
 */
@Component
@Slf4j
public class TopicExecutor implements BeanPostProcessor, ApplicationContextAware {
    /**
     * Topic消费者容器
     */
    private static final Map<String, List<Consumer>> consumersMap = new ConcurrentHashMap<>();

    /**
     * 由@KafkaListener获取topic列表进行监听
     *
     * @return
     */
    public String getTopics() {
        return Strings.join(consumersMap.keySet(), ',');
    }

    /**
     * 执行topic
     *
     * @param topic 主题
     * @param json  待解析的Json
     */
    public static void exec(String topic, String json) {
        List<Consumer> consumers = consumersMap.get(topic);
        if (consumers == null || consumers.isEmpty()) return;
        for (Consumer consumer : consumers) {
            // 重复消息则跳过
            if (whenRepeat(json, consumer))
                continue;
            if (consumer.getTopicConsumer().async()) {
                execAsync(consumer, json);
            } else {
                exec(consumer, json);
            }
        }
    }

    @Override
    public Object postProcessAfterInitialization(Object bean, String beanName) throws BeansException {
        // 获取所有被@TopicConsumer注解的方法
        Method[] methods = ReflectionUtils.getDeclaredMethods(bean.getClass());
        for (Method method : methods) {
            TopicConsumer topicConsumer = AnnotationUtils.findAnnotation(method, TopicConsumer.class);
            if (topicConsumer == null) continue;
            // 放入Topic消费者容器
            TopicExecutor.put(topicConsumer.topic(), Consumer.builder().id(UUID.randomUUID().toString()).topicConsumer(topicConsumer).jdkConsumer(json -> {
                Object proxyBean = applicationContext.getBean(bean.getClass());
                // 实际执行的地方
                if (method.getParameters().length == 0) {
                    // 方法无参，不传参调用
                    ReflectionUtils.invokeMethod(method, proxyBean);
                } else if (json != null && json.length() != 0) {
                    // 根据第一个参数类型解析Json
                    try {
                        Class<StringDeserializer> deserializer = topicConsumer.deserializer();
                        Object arg = deserializer.newInstance().deserialize(json, method.getParameters()[0].getType());
                        if (arg != null)
                            ReflectionUtils.invokeMethod(method, proxyBean, arg);
                    } catch (Exception e) {
                    }
                }
            }).build());
        }
        return bean;
    }

    private static void put(String topic, Consumer consumer) {
        List<Consumer> consumers = consumersMap.computeIfAbsent(topic, k -> new ArrayList<>());
        consumers.add(consumer);
    }

    private static boolean whenRepeat(String json, Consumer consumer) {
        if (consumer.getTopicConsumer().allowRepeat()) return false;
        String uniKey = getUniKey(consumer.getTopicConsumer().topic(), consumer.getId(), json);
        long size = RedisUtils.increment(uniKey);
        if (!Objects.equals(size, 1L)) {
            log.warn("Repeat Consume! topic: {} value: {}", consumer.getTopicConsumer().topic(), json);
            return true;
        }
        //kafka消息堆积有效时间
        RedisUtils.expire(uniKey, consumer.getTopicConsumer().timeout(), consumer.getTopicConsumer().timeUnit());
        return false;
    }

    /**
     * 消息唯一签名
     */
    private static String MSG_UNI;

    @Value("${spring.application.name}")
    public void setAppName(String appName) {
        this.MSG_UNI = appName + ":msg:uni:%s:%s:%s";
    }

    private static String getUniKey(String topic, String id, String value) {
        return String.format(MSG_UNI, topic, id, HashUtils.md5ToString(value.getBytes(StandardCharsets.UTF_8)));
    }

    /**
     * 异步执行
     *
     * @param consumer
     * @param json
     */
    private static void execAsync(Consumer consumer, String json) {
        getTaskExecutor().execute(() -> exec(consumer, json));
    }

    /**
     * 同步执行
     *
     * @param consumer
     * @param json
     */
    private static void exec(Consumer consumer, String json) {
        try {
            consumer.getJdkConsumer().accept(json);
        } catch (Exception e) {
            // 异常释放UniKey
            evictUniKey(consumer.getTopicConsumer().topic(), consumer.getId(), json);
        }
    }

    /**
     * 失效Key
     *
     * @param topic
     * @param id
     * @param value
     */
    private static void evictUniKey(String topic, String id, String value) {
        RedisUtils.delete(getUniKey(topic, id, value));
    }

    private static final String APPLICATION_TASK_EXECUTOR_BEAN_NAME = TaskExecutionAutoConfiguration.APPLICATION_TASK_EXECUTOR_BEAN_NAME;
    private static ThreadPoolTaskExecutor taskExecutor;

    private static ThreadPoolTaskExecutor getTaskExecutor() {
        if (Objects.isNull(taskExecutor)) {
            taskExecutor = SpringContext.getApplicationContext().getBean(APPLICATION_TASK_EXECUTOR_BEAN_NAME, ThreadPoolTaskExecutor.class);
        }
        return taskExecutor;
    }

    private static ApplicationContext applicationContext;

    @Override
    public void setApplicationContext(ApplicationContext applicationContext) throws BeansException {
        this.applicationContext = applicationContext;
    }
}


@Setter
@Getter
@Builder
class Consumer {
    private String id;
    private java.util.function.Consumer<String> jdkConsumer;
    private TopicConsumer topicConsumer;
}
```

**字符串反序列化器接口**

定义解析Kafka消息的消息内容，主要是为了可以扩展定义字符串反序列化器。

StringDeserializer.java

```
package com.xxx.fms.common.topicconsumer;

public interface StringDeserializer {

    <T> T deserialize(String src, Class<T> dist) throws Exception;

}
```

**Json字符串反序列化器**

实现StringDeserializer类，作为@TopicConsumer注解类的默认反序列化器。

JsonStringDeserializer.java

```
package com.xxx.fms.common.topicconsumer;

import com.xxx.pub.utils.JsonUtils;
import org.apache.commons.lang3.StringUtils;

public class JsonStringDeserializer implements StringDeserializer {

    @Override
    public <T> T deserialize(String src, Class<T> dist) throws Exception {
        if (StringUtils.isEmpty(src)) {
            return null;
        }
        return JsonUtils.fromJson(src, dist);
    }
}
```

**通用Kafka消费者**

kafka包只需要定义常量和通用的Kafka消费者即可，新增消息不需要新增XxxKafkaConsumer了：

![Kafka消费者这样写，一年节省10,000行代码_代码_07](https://s3.51cto.com/images/blog/202202/07134354_6200b19a59a8f68795.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)

CommonKafkaConsumer.java

```
package com.xxx.fms.kafka.consumer;

import com.xxx.fms.common.topicconsumer.TopicExecutor;
import lombok.extern.slf4j.Slf4j;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

/**
 * 通用Kafka消费者
 *
 * @Author: Jensen 公众号：架构师修行录
 * @Date: 2021/11/11 11:11
 */
@Component
@Slf4j
public class CommonKafkaConsumer {

    @KafkaListener(topics = "#{topicExecutor.getTopics().split(',')}")
    public void consumeTopics(ConsumerRecord<String, String> consumerRecord) {
        log.info("接受kafka消息,topic:{},message:{}", consumerRecord.topic(), consumerRecord.value());
        TopicExecutor.exec(consumerRecord.topic(), consumerRecord.value());
    }
}
```

**最后看看怎么使用这个TopicConsumer**

注意，这里@TopicConsumer需要标到Bean类上，因为是使用反射机制获取被注解的方法。

PaymentFlowBizServiceImpl.java

```
@Service
public class PaymentFlowBizServiceImpl implements PaymentFlowBizService {

    /**
    * 支付成功消息
    * @TopicConsumer用法：
    * 自动解析到第一个参数OrderPayMessageDTO.class，无参不解析
    * 默认异步执行，async = false可设为同步执行
    * allowRepeat = false表示允许当前方法重复消费，由Redis锁实现，默认锁15天，可改
    * deserializer = JsonDeserializer.class表示消息由JsonDeserializer解析到OrderPayMessageDTO.class
    **/
    @TopicConsumer(topic = KafkaTopic.ORDER_PAY, async = false, allowRepeat = false, deserializer = JsonDeserializer.class)
    public void orderPaySuccess(OrderPayMessageDTO messageDTO) {
      // 解析成功，写业务代码
    }
}
```

## 0x3.总结一下

这里涉及到以下几个知识点：

1. 自定义注解
2. 反射
3. 容器映射
4. Jdk8的Consumer
5. Redis锁
6. 依赖倒置
7. 反序列化

这个TopicConsumer解决了什么痛点呢？

1. 作为中间层解耦kafka与业务领域包，反转依赖
2. 简化开发，封装消费防重、反解析、异步执行

我们利用这一套组合拳，外加一个AOP，可以实现很多功能。