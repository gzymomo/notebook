- [Java线上问题排查神器Arthas实战分析](https://www.cnblogs.com/itxiaoshen/p/15854197.html)

## 1 概述

## 2 背景

是不是在实际开发工作当中经常碰到自己写的代码在开发、测试环境行云流水稳得一笔，可一到线上就经常不是缺这个就是少那个反正就是一顿报错抽风似的，线上调试代码又很麻烦，让人头疼得抓狂；而且debug不一定是最高效的方法，遇到线上问题不能debug了怎么办。原先我们Java中我们常用分析问题一般是使用JDK自带或第三方的分析工具如jstat、jmap、jstack、 jconsole、visualvm、Java Mission  Control、MAT等。但此刻的你没有看错，还有一款神器Arthas工具着实让人吃惊，可帮助程序员解决很多繁琐的问题，使得加班解决线上问题成为过去的可能性大大提高。

## 3 定义

Arthas是一个Java诊断工具，由阿里巴巴中间件团队开源，目前已在Java开发人员中被广泛采用。Arthas能够分析，诊断，定位Java应用问题，例如：JVM信息，线程信息，搜索类中的方法，跟踪代码执行，观测方法的入参和返回参数等等。并能在不修改应用代码的情况下，对业务问题进行诊断，包括查看方法的出入参，异常，监测方法执行耗时，类加载信息等，大大提升线上问题排查效率。简单的话：就是再不重启应用的情况下达到排查问题的目的。

## 4 特性

- 仪表盘实时查看系统的运行状态。
- OGNL表达式查看参数和返回值/例外，查看方法参数、返回值和异常。
- 通过jad/sc/redefine实现在线热插拔。
- 快速解决类冲突问题，定位类加载路径。
- 快速定位应用热点和生成火焰图。
- 支持在线诊断WebConsole。
- Arthas对应用程序没有侵入(但对宿主机jvm有侵入)，代码或项目中不需要引入jar包或依赖，因为是通过attach的机制实现的，我们的应用的程序和arthas都是独立的进程，arthas是通过和jvm底层交互来获取运行在其上的应用程序实时数据的，灵活查看运行时的值，这个和hickwall,jprofiler等监控软件的区别(JPofiler也有这样的功能,但是是收费的)动态增加aop代理和监控日志功能，无需重启服务，而且关闭arthas客户端后会还原所有增强过的类，原则上是不会影响现有业务逻辑的。
- 对应用程序所在的服务器性能的影响，个别命令使用不当的话，可能会撑爆jvm内存或导致应用程序响应变慢，命令的输出太多，接口调用太频繁会记录过多的数据变量到内存里，比如tt指令，建议加 -n 参数 限制输出次数，sc *  通配符的使用不当，范围过大，使用异步任务时，请勿同时开启过多的后台异步命令，以免对目标JVM性能造成影响，一把双刃剑(它甚至可以修改jdk里的原生类)，所以在线上运行肯定是需要权限和流程控制的。

## 5 使用场景

在日常开发中，当我们发现应用的某个接口响应比较慢，这个时候想想要分析一下原因，找到代码中耗时的部分，比较容易想到的是在接口链路的 IO  操作上下游打印时间日志，再根据几个时间点的日志算出耗时长的 IO  操作。这种方式没有问题，但是加日志需要发布，既繁琐又低效，这个时候可以引入一些线上 debug 的工具，arthas  就是很好的一种，除了分析耗时，还可以打印调用栈、方法入参及返回，类加载情况，线程池状态，系统参数等等，其实现原理是解析 JVM  在操作系统中的文件，大部分操作是只读的，对服务进程没有侵入性，因此可以放心使用。

## 6 安装与使用

### 6.1 推荐方式

```shell
# 下载`arthas-boot.jar`这种也是官方推荐的方式
curl -O https://arthas.aliyun.com/arthas-boot.jar
# 启动arthas-boot.jar，必须启动至少一个 java程序，否则会自动退出。运行此命令会自动发现 java进程，输入需要 attach 进程对应的序列号，例如，输入1按回车则会监听该进程。
java -jar arthas-boot.jar
# 比如输入JVM （jvm实时运行状态，内存使用情况等）
```

![image-20220125102432593](https://img-blog.csdnimg.cn/img_convert/2d085ebe673c932b6a0cd70813f65f9b.png)

## 7 实战

### 7.1 CPU占用高示例

创建一个springboot项目并打包成arthas-demo-1.0.jar，启动arthas-demo-1.0.jar

代码示例如下

```java
package cn.itxs;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import java.util.UUID;
import java.util.concurrent.TimeUnit;

@SpringBootApplication
public class App 
{
    public static void main(String[] args) {
        SpringApplication.run(App.class,args);
        new Thread( () -> {
            while (true) {
                String str = UUID.randomUUID().toString().replaceAll("-", "");
            }
        },"cpu demo thread").start();

        new Thread( () -> {
            while (true) {
                String str = UUID.randomUUID().toString().replaceAll("-", "");
                try {
                    TimeUnit.MILLISECONDS.sleep(10);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        },"cpu with sleep thread").start();
    }
}
```

### 7.2 CPU占用高示例

```java
package cn.itxs.controller;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.concurrent.TimeUnit;

@RestController
@RequestMapping("/thread")
public class ThreadController {
    private Object obj1 = new Object();
    private Object obj2 = new Object();

    @RequestMapping("/test")
    @ResponseBody
    public String test(){
        new Thread(() -> {
            synchronized (obj1){
                try {
                    TimeUnit.SECONDS.sleep(10);
                } catch (InterruptedException e) {
                    synchronized (obj2){
                        System.out.printf("thread 1执行到此");
                    }
                }
            }
        },"thread 1").start();

        new Thread(() -> {
            synchronized (obj2) {
                synchronized (obj1){
                    System.out.printf("thread 2执行到此");
                }
            }
        },"thread 2").start();
        return "thread test";
    }
}
```

SpringBoot启动类

```java
package cn.itxs;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class App 
{
    public static void main(String[] args) {
        SpringApplication.run(App.class,args);
    }
}
# 访问页面http://192.168.50.100:8080/cpu/test
# 仪表盘命令，通过上面我们可以发现线程ID为29也即是线程名称为“cpu demo thread”占用的cpu较高
dashboard
```

![image-20220126123754249](https://img-blog.csdnimg.cn/img_convert/16739f16cd554ef763e9a1d55aa5b7df.png)

- 第一部分时显示JVM中运行的所有线程：所在线程组，优先级，线程的状态，CPU的占有率，是否是后台进程等。
- 第二部分显示的JVM内存的使用情况和GC的信息。
- 第三部分是操作系统的一些信息和 Java版本号。

```shell
# 当前最忙的前N个线程 thread -b, ##找出当前阻塞其他线程的线程 thread -n 5 -i 1000 #间隔一定时间后展示，本例中可以看到最忙CPU线程为id=45，代码行数为19
thread -n 5 
# jad查看反编译的代码
jad cn.itxs.controller.CpuController
```

![image-20220126123948798](https://img-blog.csdnimg.cn/img_convert/01ed95eadc87b245e0947845421ba5e1.png)

![image-20220126124323603](https://img-blog.csdnimg.cn/img_convert/05520bd634ac8ad5e06882ddf3591a66.png)

### 7.3 线程死锁示例

```java
package cn.itxs.controller;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.RestController;
import java.util.concurrent.TimeUnit;

@RestController
@RequestMapping("/thread")
public class ThreadController {
    private Object obj1 = new Object();
    private Object obj2 = new Object();

    @RequestMapping("/test")
    @ResponseBody
    public String test(){
        new Thread(() -> {
            synchronized (obj1){
                try {
                    TimeUnit.SECONDS.sleep(10);
                } catch (InterruptedException e) {
                }
                synchronized (obj2){
                    System.out.println("thread 1执行到此");
                }
            }
        },"thread 1").start();
        try {
            TimeUnit.SECONDS.sleep(2);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        new Thread(() -> {
            synchronized (obj2) {
                synchronized (obj1){
                    System.out.println("thread 2执行到此");
                }
            }
        },"thread 2").start();
        return "thread test";
    }
}
# 启动SpringBoot演示程序，访问页面http://192.168.50.100:8080/thread/test
# 运行arthas，查看线程
thread
```

![image-20220126134413467](https://img-blog.csdnimg.cn/img_convert/26ab7cd0ecf9fd5c35111438061308a4.png)

```shell
# 查看阻塞线程
thread -b
# jad反编译查看代码
jad --source-only cn.itxs.controller.ThreadController
```

![image-20220126135921777](https://img-blog.csdnimg.cn/img_convert/37cb6b7579598b86f8ac4defcbd89ceb.png)

![image-20220126140105959](https://img-blog.csdnimg.cn/img_convert/c4923bd1eb7fb28405f99a9cf4174eb8.png)

### 7.4 线上修复热部署

准备一个有问题的java类

```java
package cn.itxs.controller;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;
import java.util.concurrent.TimeUnit;

@RestController
@RequestMapping("/hot")
public class HotController {

    @RequestMapping("/test")
    @ResponseBody
    public String test(){
        boolean flag = true;
        if (flag) {
            System.out.println("开始处理逻辑");
            throw new RuntimeException("出异常了");
        }
        System.out.println("结束流程");
        return "hot test";
    }
}
```

启动Spring Boot程序，访问页面http://192.168.50.94:8080/hot/test发现报错，当我们分析到这段程序出异常后，我们分析异常后进行线上代码修改不停机不重新发包的情况下的热更新，操作流程如下：

```shell
# 第一步：`jad命令` 将需要更改的文件先进行反编译，保存下来 ，编译器修改,-c 指定这个类的classloader的哈希值，–source-only只显示源码，最后是文件反编译之后的存放路径
jad --source-only cn.itxs.controller.HotController > /home/commons/arthas/data/HotController.java
# 我们将HotController.java中的throw new RuntimeException("出异常了")代码删掉，修改完后需要将类重新加载到JVM
# 第二步：`SC命令` 查找当前类是哪个classLoader加载的，首先，使用sc命令找到要修改的类.sc全称-search class， -d表示detail,主要是为了获取classLoader的hash值
sc -d *HotController | grep classLoader
classLoaderHash   6267c3bb #类加载器  编号    
# 第三步：`MC命令` 用指定的classloader重新将类在内存中编译
mc -c 6267c3bb /home/commons/arthas/data/HotController.java -d /home/commons/arthas/class
# 第四步：`redefine命令` 将编译后的类加载到JVM，参数是编译后的.class文件地址
redefine /home/commons/arthas/class/cn/itxs/controller/HotController.class  
```

以上操作后再次访问一下页面http://192.168.50.94:8080/hot/test，发现异常没有了程序已经是我们修改正确后的，class文件替换成功，功能确实很强大。

![image-20220126152459248](https://img-blog.csdnimg.cn/img_convert/88238b0cd0feed4ed784705d224826e3.png)

上面我们是手工一步步执行，当然我们可以使用shell脚本串起来简单操作。

此外还可以安装Alibaba Cloud Toolkit热部署组件（一键retransform），热部署组件支持一键将编辑器中修改的  Java 源码快速编译，并更新到远端应用服务中，免去手动 dump、mc 的过程。此外，也可以一键还原 retransform 的类文件。

![image-20220126154240294](https://img-blog.csdnimg.cn/img_convert/4a552632c1922d605a0471133af02c15.png)

由于Arthas命令还是较复杂，Arthas-idea插件（部分命令可视化）是一个帮助生成命令的IDEA插件，使用文档：https://www.yuque.com/arthas-idea-plugin；

安装基于Arthas实现的简单好用的热部署插件ArthasHotSwap可以一键生成热部署命令，提高我们线上维护的效率。

![image-20220126154348013](https://img-blog.csdnimg.cn/img_convert/331b0ae8d0e169e128d7eac567a56687.png)

### 7.5 线上问题常见定位

#### 7.5.1 watch（方法执行数据观测）

```java
package cn.itxs.controller;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.ArrayList;
import java.util.List;
import java.util.Random;

@RestController
@RequestMapping("/watch")
public class WatchController {
    private static Random random = new Random();
    private int illegalArgumentCount = 0;

    @RequestMapping("/test")
    @ResponseBody
    public String test(){
        String res = null;
        try {
            int number = random.nextInt() / 10000;
            List<Integer> idStrs = this.getIdStr(number);
            res = printList(number, idStrs);
        }
        catch (Exception e) {
            System.out.println(String.format("illegalArgumentCount:%3d, ", this.illegalArgumentCount) + e.getMessage());
        }
        return res;
    }

    private List<Integer> getIdStr(int number) {
        if (number < 5) {
            ++this.illegalArgumentCount;
            throw new IllegalArgumentException("number is: " + number + ", need >= 5");
        }
        ArrayList<Integer> result = new ArrayList<Integer>();
        int count = 2;
        while (count <= number) {
            if (number % count == 0) {
                result.add(count);
                number /= count;
                count = 2;
                continue;
            }
            ++count;
        }
        return result;
    }

    private String printList(int number, List<Integer> primeFactors) {
        StringBuffer sb = new StringBuffer(number + "=");
        for (int factor : primeFactors) {
            sb.append(factor).append('*');
        }
        if (sb.charAt(sb.length() - 1) == '*') {
            sb.deleteCharAt(sb.length() - 1);
        }
        System.out.println(sb);
        return sb.toString();
    }
}
```

启动Spring Boot程序，通过Jmeter每秒访问一次http://192.168.50.100:8080/watch/test

![image-20220127093907292](https://img-blog.csdnimg.cn/img_convert/efd9bb5291ad1b5b50505b282c57bcbf.png)

```shell
# Arthas中的**watch**命令可以让我们能方便的观察到指定方法的调用情况，可以观察到返回值，入参，以及变量等。
# watch 全路径类名 方法名 观察表达式 -x 3  ，观察表达式匹配ognl表达式，观察的维度也比较多。
# 比如：watch cn.itxs.controller.WatchController printList "{params,returnObj}" -x 3
# 查看printList方法的入参和出参，-x表示的是遍历结果深度默认1，只会打印对象的堆地址，看不到具体的属性值,-x 2会打印结果的属性值的信息 -x 3会输出入参属性值和结果属性值
# -n 1只抓紧一次，由于我们这里是模拟一直请求的
watch cn.itxs.controller.WatchController printList '{params}' -n 1
# -x 表示的是遍历结果深度默认3
watch cn.itxs.controller.WatchController printList '{params}' -n 1 -x 3
# params[0]代表第一个参数
watch cn.itxs.controller.WatchController printList '{params[0]}' -n 1 -x 3
```

![image-20220127094326927](https://img-blog.csdnimg.cn/img_convert/50a42d1b1d103d81c42979666c97d866.png)

```shell
# 方法的返回值
watch cn.itxs.controller.WatchController getIdStr '{returnObj}' -n 1 -x 3
# 方法参数和返回值
watch cn.itxs.controller.WatchController getIdStr '{params,returnObj}' -n 1 -x 3
```

![image-20220127094944423](https://img-blog.csdnimg.cn/img_convert/8c4f38d637b3366a920b54d469478f78.png)

```shell
# 观察方法执行前后当前对象属性值
watch cn.itxs.controller.WatchController getIdStr 'target.illegalArgumentCount'
```

![image-20220127095305635](https://img-blog.csdnimg.cn/img_convert/de820547277faa2c2de35fe4f9229afe.png)

```shell
# 观察异常信息，观察表达式里增加throwExp就好了。如果增加-e 参数就能过滤掉非异常的监听了。
```

![image-20220127095616406](https://img-blog.csdnimg.cn/img_convert/0f36f8ce3c6321b5000a87df7b23b552.png)

```shell
# 在观察表达式后面，我们可以增加条件表达式，例如按时间过滤：#cost>0.5,单位是毫秒，那么控制台输出来的都是耗时在0.5毫秒以上的方法调用
watch cn.itxs.controller.WatchController getIdStr '{params}' '#cost>0.5'
```

![image-20220127101715104](https://img-blog.csdnimg.cn/img_convert/e4e026ac1a7c00c7a76148eaf279b796.png)

```shell
# 按条件过滤观察params[1].size>4:这里支持ognl表达式。下面例子的意思是：第二个参数（也就是List primeFactors），的size大于4的时候才观察入参。watch cn.itxs.controller.WatchController printList '{params}' 'params[1].size>4' -x 3
```

![image-20220127102139872](https://img-blog.csdnimg.cn/img_convert/16c976b4f35fa00f5eaffabc1f04017e.png)

#### 7.5.2 monitor（方法执行监控）

monitor结果包括如下

- timestamp：时间戳
- class：Java类
- method：方法（构造方法、普通方法）
- total：调用次数
- success：成功次数
- fail：失败次数
- rt：平均RT
- fail-rate：失败率

```shell
# -c ：统计周期，默认值为10秒
monitor -c 10 cn.itxs.controller.WatchController getIdStr
# 在方法调用之前计算condition-express,方法后可带表达式
monitor -b -c 10 cn.itxs.controller.WatchController getIdStr
```

![image-20220127134451812](https://img-blog.csdnimg.cn/img_convert/88e95aaa09b51e1ebeb6bf94728d71e3.png)

![image-20220127145246950](https://img-blog.csdnimg.cn/img_convert/40de520a1b68a601f605c19731daff0f.png)

#### 7.5.3 trace

```shell
# trace:方法内部调用路径，并输出方法路径上的每个节点上耗时
trace cn.itxs.controller.WatchController test -n 2
#包含jdk的函数--skipJDKMethod <value>  skip jdk method trace, default value true.默认情况下，trace不会包含jdk里的函数调用，如果希望trace jdk里的函数，需要显式设置--skipJDKMethod false。
trace --skipJDKMethod false cn.itxs.controller.WatchController test -n 2
# 调用耗时过滤，只会展示耗时大于10ms的调用路径，有助于在排查问题的时候，只关注异常情况
trace cn.itxs.controller.WatchController test '#cost > 1'
```

![image-20220127151509432](https://img-blog.csdnimg.cn/img_convert/39ddb274b569ef377269e934d2a9cb2e.png)

#### 7.5.4 stack

```shell
# 输出当前方法被调用的调用路径，getIdStr是从test方法调用进来的
stack cn.itxs.controller.WatchController getIdStr -n 1
# 输出当前方法被调用的调用路径，条件表达过滤，第0个参数小于0，也可以根据执行时间来过滤，'#cost>1'
stack cn.itxs.controller.WatchController getIdStr 'params[0]<0' -n 1
```

![image-20220127153509867](https://img-blog.csdnimg.cn/img_convert/562439d79167e64494e3ea787d30750f.png)

![image-20220127153830484](https://img-blog.csdnimg.cn/img_convert/e5bedc4d6f3b7c48aad27dddaee6f667.png)

#### 7.5.5 tt

tt(TimeTunnel):方法执行数据的时空隧道，记录下指定方法每次调用的入参和返回信息，并能对这些不同的时间下调用进行观测。对于一个最基本的使用来说，就是记录下当前方法的每次调用环境现场。

```shell
# 记录指定方法的每次调用环境现场
tt -t cn.itxs.controller.WatchController getIdStr 
# 列出所有调用记录
tt -l cn.itxs.controller.WatchController getIdStr
```

![image-20220127173744410](https://img-blog.csdnimg.cn/img_convert/cc29d9c084b2922154a47827b48f3590.png)

```shell
# 筛选调用记录
tt -s 'method.name=="getIdStr"'
# 查看调用信息
tt -i 1001
```

![image-20220127173952423](https://img-blog.csdnimg.cn/img_convert/5252a25a9012bc58721080ee8ab00e30.png)

```shell
# 重新发起一次调用
tt -i 1001 -p
```

![image-20220127174134029](https://img-blog.csdnimg.cn/img_convert/4956b9defbd8f7f1846e0d32a41b5a32.png)

### 7.6 Web Console

```shell
# 启动时指定Linux的ip
java -jar arthas-boot.jar --target-ip 192.168.50.94
```

![image-20220127180139880](https://img-blog.csdnimg.cn/img_convert/40994ae0896044498fe01cb98528ab25.png)

### 7.7 profiler

`profiler` 命令支持生成应用热点的火焰图。本质上是通过不断的采样，然后把收集到的采样结果生成火焰图。一般分析性能可以先通过Arthas profiler命令生成`jfr`文件；在本地通过`jprofiler`来分析`jfr`文件，定位谁在调用我。

```shell
# 启动profiler 默认情况下，生成的是cpu的火焰图，即event为cpu。可以用--event参数来指定
profiler start
# 获取已采集的sample的数量
profiler getSamples
# 查看profiler状态
profiler status
# 停止profiler 生成html格式结果，默认情况下，结果文件是html格式，也可以用--format参数指定；或者在--file参数里用文件名指名格式。比如--file /tmp/result.html
profiler stop --format html
```

![image-20220128135703780](https://img-blog.csdnimg.cn/img_convert/ea0b6fee6b21fcfddd0561038ffc0e21.png)

通过浏览器查看arthas-output下面的profiler结果，http://192.168.50.100:3658/arthas-output/

```shell
# profiler支持的events
profiler list
```

![image-20220128140054680](https://img-blog.csdnimg.cn/img_convert/74ff2148f93ea5d6b7b60d87282ccb12.png)

```shell
# 可以用--event参数指定要采样的事件，比如对alloc事件进入采样：
profiler start --event alloc
# 使用execute来执行复杂的命令
profiler execute 'start,framebuf=5000000'
# 生成 jfr格式结果；注意，jfr只支持在 start时配置。如果是在stop时指定，则不会生效。
profiler start --file /tmp/test.jfr
# 配置 include/exclude 来过滤数据
profiler start --include 'java/*' --include 'demo/*' --exclude '*Unsafe.park*'
# profiler执行 300 秒自动结束，可以用 -d/--duration 参数指定
profiler start --duration 300
```

![image-20220128141024676](https://img-blog.csdnimg.cn/img_convert/60482b32e9cb42590ea37ddbcd20ead2.png)

### 7.8 其他功能

- 提供Http API可以提供结构化的数据，支持更复杂的交互功能，比如特定应用场景的一系列诊断操作。Http API接口地址为：`http://ip:port/api`，必须使用POST方式提交请求参数。如POST `http://127.0.0.1:8563/api`

```json
{
  "action": "exec",
  "requestId": "req112",
  "sessionId": "94766d3c-8b39-42d3-8596-98aee3ccbefb",
  "consumerId": "955dbd1325334a84972b0f3ac19de4f7_2",
  "command": "version",
  "execTimeout": "10000"
}
```

- docker使用，很多时候，应用在docker里出现arthas无法工作的问题，是因为应用没有安装 JDK ，而是安装了 JRE  。如果只安装了  JRE，则会缺少很多JAVA的命令行工具和类库，Arthas也没办法正常工作，可以使用公开的JDK镜像和包管理软件来安装这两种方式在Docker里使用JDK。

  ```shell
  # 选择需要监控应用的进程编号，回车后Arthas会attach到目标进程上，并输出日志：
  docker exec -it arthas-demo /bin/sh -c "java -jar /opt/arthas/arthas-boot.jar"
  # 甚至我们可以直接把arthas放到容器镜像文件中：
  ```

- Arthas Spring Boot Starter:应用启动后，spring会启动arthas，并且attach自身进程。

  ```xml
  <dependency>
      <groupId>com.taobao.arthas</groupId>
      <artifactId>arthas-spring-boot-starter</artifactId>
      <version>${arthas.version}</version>
  </dependency>
  ```

- 非spring boot应用使用方式

```xml
<dependency>
    <groupId>com.taobao.arthas</groupId>
    <artifactId>arthas-agent-attach</artifactId>
    <version>${arthas.version}</version>
</dependency>
<dependency>
    <groupId>com.taobao.arthas</groupId>
    <artifactId>arthas-packaging</artifactId>
    <version>${arthas.version}</version>
</dependency>
```

```java
import com.taobao.arthas.agent.attach.ArthasAgent;
 
public class ArthasAttachExample {
	
	public static void main(String[] args) {
		ArthasAgent.attach();
	}
}
```
