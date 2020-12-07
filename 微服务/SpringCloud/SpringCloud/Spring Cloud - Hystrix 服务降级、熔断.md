[TOC]

# 1、HyStrix概述
Hystrix 是一个用于处理分布式系统的延迟和容错的开源库，在分布式系统里，许多依赖不可避免的会调用失败，比如超时、异常等，Hystrix 能够保证在一个依赖出问题的情况下，不会导致整体服务失败，避免级联故障，以提高分布式系统的弹性。

「断路器」本身是一种开关装置，当某个服务单元发生故障之后，通过断路器的故障监控(类似熔断保险丝)，向调用方返回一个符合预期的、可处理的备选响应（FallBack），而不是长时间的等待或者抛出调用方无法处理的异常，这样就保证了服务调用方的线程不会被长时间、不必要地占用，从而避免了故障在分布式系统中的蔓延，乃至雪崩。

什么是 熔断和降级 呢？再举个例子，此时我们整个微服务系统是这样的。服务A调用了服务B，服务B再调用了服务C，但是因为某些原因，服务C顶不住了，这个时候大量请求会在服务C阻塞。
![](https://segmentfault.com/img/remote/1460000022470037)

服务C阻塞了还好，毕竟只是一个系统崩溃了。但是请注意这个时候因为服务C不能返回响应，那么服务B调用服务C的的请求就会阻塞，同理服务B阻塞了，那么服务A也会阻塞崩溃。

请注意，为什么阻塞会崩溃。因为这些请求会消耗占用系统的线程、IO 等资源，消耗完你这个系统服务器不就崩了么。
![](https://segmentfault.com/img/remote/1460000022470038)

所谓熔断就是服务雪崩的一种有效解决方案。当指定时间窗内的请求失败率达到设定阈值时，系统将通过断路器直接将此请求链路断开。

也就是我们上面服务B调用服务C在指定时间窗内，调用的失败率到达了一定的值，那么[Hystrix]则会自动将 服务B与C 之间的请求都断了，以免导致服务雪崩现象。

其实这里所讲的熔断就是指的[Hystrix]中的断路器模式，你可以使用简单的@[Hystrix]Command注解来标注某个方法，这样[Hystrix]就会使用断路器来“包装”这个方法，每当调用时间超过指定时间时(默认为1000ms)，断路器将会中断对这个方法的调用。


# 2、HyStrix几个概念
## 2.1 服务降级
不让客户端等待，并立即返回一个友好的提示（服务器忙，请稍后再试）

🎃 哪些情况会发生服务降级：
- 程序运行异常
- 超时
- 服务熔断引起服务降级
- 线程池/信号量打满也会导致服务降级

## 2.2 服务熔断
类似保险丝，电流过大时，直接熔断断电。

熔断机制是应对雪崩效应的一种微服务链路保护机制，当扇出链路的某个微服务出错不可用或者响应时间太长时，会进行服务的降级，进而熔断该节点微服务的调用，快速返回错误的响应信息，当检测到该节点微服务调用响应正常后，恢复调用链路。

服务降级 → 服务熔断 → 恢复调用链路。

## 2,3 服务限流
对于高并发的操作，限制单次访问数量。

# 3、服务降级的用法与分析
超时导致服务器变慢：超时不再等待； 出错（宕机或程序运行出错）：要有备选方案
- 服务提供者超时了，调用者不能一直卡死等待，必须要服务降级
- 服务提供者宕机了，调用者不能一直卡死等待，必须要服务降级
- 服务提供者没问题，调用者自己出现故障或者有自我要求（自己的等待时间必须小于服务提供者）

## 3.1 给服务提供方设置服务降级
1. 在需要服务降级的方法上标注注解，fallbackMethod 代表回退方法，需要自己定义，@HystrixProperty 中设置的是该方法的超时时间，如果超过该事件则自动降级
当运行超时或服务内部出错都会调用回退方法：
```java
@HystrixCommand(
    fallbackMethod = "timeoutHandler", 
    commandProperties = {
    @HystrixProperty(name = "execution.isolation.thread.timeoutInMilliseconds", value = "3000")
})
public String timeout(Long id) {
    int time = 3000;
    try {
        TimeUnit.MILLISECONDS.sleep(time);
    } catch (InterruptedException e) {
        e.printStackTrace();
    }
    //模拟异常
    //int i = 10 / 0;
    return "线程：" + Thread.currentThread().getName();
}
```
2. 在启动类上添加注解，开启降级
` @EnableCircuitBreaker `

## 3.2 给服务消费方设置服务降级
1. 添加配置
```yml
# 在feign中开启hystrix
feign:
  hystrix:
    enabled: true
```
```java
@HystrixCommand(
    fallbackMethod = "timeoutHandler", 
    commandProperties = {
    @HystrixProperty(name = "execution.isolation.thread.timeoutInMilliseconds", value = "1500")
})
public String timeout(@PathVariable("id") Long id) {
    int i = 1/0;
    return hystrixService.timeout(id);
}
```

2. 在启动类上添加注解
` @EnableHystrix `

## 3.3 问题
以上配置方式存在的问题：

每个业务方法对应一个回退方法，代码膨胀
每个业务方法上都配置相同的处理，代码冗余
🎉 解决方式1：在类上配置一个全局回退方法，相当于是一个通用处理，当此回退方法能满足你的需求，就无需在方法上指定其它回退方法，如果需要使用特定的处理方法可以再在业务方法上定义
`  @DefaultProperties(defaultFallback = "globalFallbackMethod")   `
🎉 解决方式2：但此时处理代码和依然和业务代码混合在一起，我们还可以使用另一种方式：编写一个类实现 Feign 的调用接口，并重写其方法作为回退方法，然后在 @FeignClient 注解上添加 fallback 属性，值为前面的类。

# 4、服务熔断的用法与分析
在SpringCloud中，熔断机制通过 Hystrix 实现。Hystrix 监控微服务间的调用状况，当失败的调用到一定阈值，默认 5 秒内 20 次调用失败就会启动熔断机制。熔断机制的注解是 @HystrixCommand。
```java
@HystrixCommand(
    fallbackMethod = "paymentCircuitBreakerFallback", 
    commandProperties = {
        @HystrixProperty(name = "circuitBreaker.enabled", value = "true"), //是否开启断路器
        @HystrixProperty(name = "circuitBreaker.requestVolumeThreshold", value = "10"), //请求次数
        @HystrixProperty(name = "circuitBreaker.sleepWindowInMilliseconds", value = "10000"), //时间窗口期
        @HystrixProperty(name = "circuitBreaker.errorThresholdPercentage", value = "60") //失败率达到多少后跳闸
})
public String circuitBreaker(Long id) {
    if (id < 0) {
        throw new RuntimeException("id 不能为负数");
    }
    return Thread.currentThread().getName() + "\t" + "调用成功，流水号：" + IdUtil.simpleUUID();
}

public String circuitBreakerFallback(Long id) {
    return "id 不能为负数，你的id = " + id;
}
```

@HystrixProperty 中的配置可以参考 com.netflix.hystrix.HystrixCommandProperties 类
详见官方文档：https://github.com/Netflix/Hystrix/wiki/Configuration
也有雷锋同志做了翻译：https://www.jianshu.com/p/39763a0bd9b8

🎨 **熔断类型**

熔断打开：请求不再调用当前服务，内部设置时钟一般为MTTR（平均故障处理时间），当打开时长达到所设时钟则进入半熔断状态。
熔断半开：部分请求根据规则调用服务，如果请求成功且符合规则，则关闭熔断。
熔断关闭：不会对服务进行熔断。
🎨 **断路器什么时候起作用**？

根据上面配置的参数，有三个重要的影响断路器的参数

快照时间窗：回路被打开、拒绝请求到再尝试请求并决定回路是否继续打开的时间范围，默认是 5 秒
请求总数阈值：在一个滚动窗口中，打开断路器需要的最少请求数，默认是 20 次（就算前 19 次都失败了，断路器也不会被打开）
错误百分比阈值：错误请求数在总请求数所占的比例，达到设定值才会触发，默认是 50%
🎨 **断路器开启或关闭的条件**

当请求达到一定阈值时（默认 20 次）
当错误率达到一定阈值时（默认 50%）
达到以上条件断路器开启
当开启的时候，所有请求都不会转发
当断路器开启一段时间后（默认 5 秒）进入半开状态，并让其中一个请求进行转发，如果成功断路器关闭，如果失败继续开启，重复第 4 和 5 步
🎨 **断路器开启之后会发生什么**？

再有请求调用时，不再调用主逻辑，而是调用降级 fallback。
断路器开启之后，Hytrix 会启动一个休眠时间窗，在此时间内，fallback 会临时称为主逻辑，当休眠期到了之后，断路器进入半开状态，释放一个请求到原来的主逻辑上，如果请求成功返回，则断路器关闭，如果请求失败，则继续进入打开状态，休眠时间窗重新计时。

# 5、Hystrix服务熔断的工作流程
![](https://gitee.com/songjilong/FigureBed/raw/master/img/20200424225855.png)

# 6、Hystrix DashBoard上手
## 6.1 搭建
1. maven依赖
```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-netflix-hystrix-dashboard</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```
2. 添加配置
```yml
server:
  port: 9001
```
3. 开启Hystrix DashBoard
```java
@SpringBootApplication
@EnableHystrixDashboard
public class ConsumerHystrixDashBoard9001 {
    public static void main(String[] args){
        SpringApplication.run(ConsumerHystrixDashBoard9001.class, args);
    }
}
```
浏览器输入 http://localhost:9001/hystrix，出现以下界面即启动成功:
![](https://gitee.com/songjilong/FigureBed/raw/master/img/20200424231413.png)

# 7、使用
注意：想要被 Hystrix DashBoard 监控的服务必须导入此依赖
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```
在被监控服务的主启动类里添加如下代码，否则某些旧版本可能报错 Unable to connect to Command Metric Stream.
```java
/**
 * 此配置是为了服务监控而配置，与服务容错本身无关,SpringCloud升级后的坑
 * ServletRegistrationBean因为springboot的默认路径不是"/hystrix.stream"，
 * 只要在自己的项目里配置上下面的servlet就可以了
 */
@Bean
public ServletRegistrationBean getServlet(){
    HystrixMetricsStreamServlet streamServlet = new HystrixMetricsStreamServlet();
    ServletRegistrationBean registrationBean = new ServletRegistrationBean(streamServlet);
    registrationBean.setLoadOnStartup(1);
    registrationBean.addUrlMappings("/hystrix.stream");
    registrationBean.setName("HystrixMetricsStreamServlet");
    return registrationBean;
}
```
在 Hystrix DashBoard 页面输入基本信息，进入仪表盘界面。

![](https://gitee.com/songjilong/FigureBed/raw/master/img/20200424234247.png)

大致情况如下所示：
![](https://gitee.com/songjilong/FigureBed/raw/master/img/20200424234642.png)

操作界面分析：
![](https://gitee.com/songjilong/FigureBed/raw/master/img/20200424233620.png)