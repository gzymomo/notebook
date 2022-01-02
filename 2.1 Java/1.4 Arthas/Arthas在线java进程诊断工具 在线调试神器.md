- [Arthas在线java进程诊断工具 在线调试神器](https://www.cnblogs.com/TopGear/p/15508284.html)

`Arthas` 是 Alibaba 开源的Java诊断工具，深受开发者喜爱。

官网文档：https://arthas.aliyun.com/doc/

当你遇到以下类似问题而束手无策时，`Arthas`可以帮助你解决：

1. 这个类从哪个 jar 包加载的？为什么会报各种类相关的 Exception？
2. 我改的代码为什么没有执行到？难道是我没 commit？分支搞错了？
3. 遇到问题无法在线上 debug，难道只能通过加日志再重新发布吗？
4. 线上遇到某个用户的数据处理有问题，但线上同样无法 debug，线下无法重现！
5. 是否有一个全局视角来查看系统的运行状况？
6. 有什么办法可以监控到JVM的实时运行状态？
7. 怎么快速定位应用的热点，生成火焰图？
8. 怎样直接从JVM内查找某个类的实例？

`Arthas`支持JDK 6+，支持Linux/Mac/Windows，采用命令行交互模式，同时提供丰富的 `Tab` 自动补全功能，进一步方便进行问题的定位和诊断。

下载`arthas-boot.jar`，然后用`java -jar`的方式启动：

# 一、安装

## 1.1 快速安装

### 1.1.1 使用arthas-boot（推荐）

```
curl -O https://arthas.aliyun.com/arthas-boot.jar
java -jar arthas-boot.jar
```

打印帮助信息：

```
java -jar arthas-boot.jar -h
```

> 如果下载速度比较慢，可以使用aliyun的镜像：

> ```
> java -jar arthas-boot.jar --repo-mirror aliyun --use-http
> ```

### 1.1.2 使用as.sh方式安装

Arthas 支持在 Linux/Unix/Mac 等平台上一键安装，请复制以下内容，并粘贴到命令行中，敲 `回车` 执行即可：

```
curl -L https://arthas.aliyun.com/install.sh | sh
```

上述命令会下载启动脚本文件 `as.sh` 到当前目录，你可以放在任何地方或将其加入到 `$PATH` 中。

直接在shell下面执行`./as.sh`，就会进入交互界面。

也可以执行`./as.sh -h`来获取更多参数信息。

## 1.2 全量安装

```
# java -jar arthas-boot.jar
[INFO] arthas-boot version: 3.5.3
[INFO] Found existing java process, please choose one and input the serial number of the process, eg : 1. Then hit ENTER.
* [1]: 24438 org.elasticsearch.bootstrap.Elasticsearch
1
[ERROR] Can not read arthas version from: https://arthas.aliyun.com/api/latest_version
[ERROR] Can not find Arthas under local: /root/.arthas/lib and remote repo mirror: aliyun
[ERROR] Unable to download arthas from remote server, please download the full package according to wiki: https://github.com/alibaba/arthas
```

当使用快速安装方式在线上环境进行连接Java服务的时候，很有可能因为线上环境无外部网络访问权限，导致Arthas无法获取 arthas-core 等jar包，无法运行。

这时候就需要全量安装Arthas包。

*安装方法* ： ( 包大小13MB )

```
#### 获取 arthas 全量包
curl -Lo arthas-packaging-latest-bin.zip  'https://arthas.aliyun.com/download/latest_version?mirror=aliyun'
unzip -d arthas-latest-bin arthas-packaging-latest-bin.zip

#### 开始运行
java -jar ahthas-boot.jar
[INFO] arthas-boot version: 3.5.4
[INFO] Found existing java process, please choose one and input the serial number of the process, eg : 1. Then hit ENTER.
* [1]: 27878 /data/tsf/tsf-oss/tsf-ratelimit/tsf-ratelimit-1.29.1/lib/tsf-ratelimit-1.29.1.jar
1
[INFO] arthas home: /root
[INFO] Try to attach process 27878
[INFO] Attach process 27878 success.
[INFO] arthas-client connect 127.0.0.1 3658
  ,---.  ,------. ,--------.,--.  ,--.  ,---.   ,---.  
 /  O  \ |  .--. ''--.  .--'|  '--'  | /  O  \ '   .-' 
|  .-.  ||  '--'.'   |  |   |  .--.  ||  .-.  |`.  `-. 
|  | |  ||  |\  \    |  |   |  |  |  ||  | |  |.-'    |
`--' `--'`--' '--'   `--'   `--'  `--'`--' `--'`-----' 
                                                       

wiki       https://arthas.aliyun.com/doc
tutorials  https://arthas.aliyun.com/doc/arthas-tutorials.html
version    3.5.4
main_class
pid        27878
time       2021-09-07 19:31:47
```

## 1.3 通过rpm/deb安装

这部分见官方文档：

`arthas` 需要使用到 jps 命令，所以要保证 `openjdk-devel` 包已经安装。

## 1.4 快速入门

```
jps || yum -y install java-1.8.0-openjdk-devel
```

运行 arthas：

```
# java -jar arthas-boot.jar
[INFO] arthas-boot version: 3.5.3
[INFO] Process 5201 already using port 3658
[INFO] Process 5201 already using port 8563
[INFO] Found existing java process, please choose one and input the serial number of the process, eg : 1. Then hit ENTER.
* [1]: 5201 cloud-access-auth-1.18.1.jar
  [2]: 14419 tsf-stack-base-1.0.0.jar
  [3]: 27862 cloud-access-gateway-1.18.1.jar
  [4]: 6550 tsfmanager-operation-1.29.1.jar
```

> 提示1：当 arthas 给出的进程列表不能确定进程信息的时候，我们可以通过在命令行输入`jps -lmv` 查看详细的 java 进程信息，来确定我们要查看的 java 进程号。
>
> 提示2：当提示如下信息时：

> ```
> Arthas script version: 3.0.4
> Calculating attach execution time...
> Attaching to 24110 using version 3.0.4...
> Start arthas failed, exception stack trace:
> java.lang.InternalError: instrument library is missing in target VM
> 	at sun.tools.attach.HotSpotVirtualMachine.loadAgent(HotSpotVirtualMachine.java:105)
> 	at com.taobao.arthas.core.Arthas.attachAgent(Arthas.java:84)
> 	at com.taobao.arthas.core.Arthas.<init>(Arthas.java:25)
> 	at com.taobao.arthas.core.Arthas.main(Arthas.java:96)
> Caused by: com.sun.tools.attach.AgentLoadException: Failed to load agent library
> 	at sun.tools.attach.LinuxVirtualMachine.execute(LinuxVirtualMachine.java:224)
> 	at sun.tools.attach.HotSpotVirtualMachine.loadAgentLibrary(HotSpotVirtualMachine.java:58)
> 	at sun.tools.attach.HotSpotVirtualMachine.loadAgentLibrary(HotSpotVirtualMachine.java:79)
> 	at sun.tools.attach.HotSpotVirtualMachine.loadAgent(HotSpotVirtualMachine.java:103)
> 	... 3 more
> attach to target jvm (24110) failed, check /root/logs/arthas/arthas.log or stderr of target jvm for any exceptions.
> ```
>
> 我们需要重新启动一下该进程，然后再运行 arthas ，连接到后台 java 进程即可。

下面的 java 进程编号即当前主机已经运行的 java 服务，输入**编号**即可进入 arthas 的交互式界面。

```
[INFO] Found existing java process, please choose one and input the serial number of the process, eg : 1. Then hit ENTER.
* [1]: 5201 cloud-access-auth-1.18.1.jar
  [2]: 14419 tsf-stack-base-1.0.0.jar
  [3]: 27862 cloud-access-gateway-1.18.1.jar
  [4]: 6550 tsfmanager-operation-1.29.1.jar
1
[INFO] local lastest version: 3.5.3, remote lastest version: 3.5.4, try to download from remote.
[INFO] Start download arthas from remote server: https://arthas.aliyun.com/download/3.5.4?mirror=aliyun
[INFO] Download arthas success.
[INFO] arthas home: /root/.arthas/lib/3.5.4/arthas
[INFO] The target process already listen port 3658, skip attach.
[INFO] arthas-client connect 127.0.0.1 3658
  ,---.  ,------. ,--------.,--.  ,--.  ,---.   ,---.  
 /  O  \ |  .--. ''--.  .--'|  '--'  | /  O  \ '   .-' 
|  .-.  ||  '--'.'   |  |   |  .--.  ||  .-.  |`.  `-. 
|  | |  ||  |\  \    |  |   |  |  |  ||  | |  |.-'    |
`--' `--'`--' '--'   `--'   `--'  `--'`--' `--'`-----' 
                                                       

wiki       https://arthas.aliyun.com/doc
tutorials  https://arthas.aliyun.com/doc/arthas-tutorials.html
version    3.5.3
main_class
pid        5201
time       2021-09-03 09:55:42

[arthas@5201]$
```

当出现上述彩条 ARTHAS 字符提示的时候，就表示已经正常连接到指定的 Java 进程，随即进入到下面的 `arthas@PID` 命令提示符。

# 二、功能使用

## 2.1 dashboard指令 --总览JVM信息

在 arthas 命令提示符下键入`dashboard`  回车，会展示当前进程的信息，按`q` 退出。
 [![img](https://img2020.cnblogs.com/blog/1628996/202111/1628996-20211104151314409-1555603880.png)](https://img2020.cnblogs.com/blog/1628996/202111/1628996-20211104151314409-1555603880.png)

dashboard 会实时输出该java进程的JVM信息，包括线程、进程、内存、堆栈、以及当前系统运行时信息。

```
[arthas@5201]$ dashboard -h
 USAGE:       
   dashboard [-h] [-i <value>] [-n <value>]

 SUMMARY:  
   Overview of target jvm's thread, memory, gc, vm, tomcat info.
   
 EXAMPLES:  
   dashboard
   dashboard -n 10
   dashboard -i 2000
           
 WIKI:           
   https://arthas.aliyun.com/doc/dashboard

 OPTIONS:          
 -h, --help                                this help
 -i, --interval <value>                    The interval (in ms) between two executions, default is 5000 ms.
 -n, --number-of-execution <value>         The number of times this command will be executed.
```

## 2.2 help指令

该指令用以列出所有 arthas 交互式界面支持的 **子命令** 列表。

```
[arthas@5201]$ help
 NAME         DESCRIPTION
 help         Display Arthas Help
 auth         Authenticates the current session
 keymap       Display all the available keymap for the specified connection.
 sc           Search all the classes loaded by JVM
 sm           Search the method of classes loaded by JVM
 classloader  Show classloader info
 jad          Decompile class
 getstatic    Show the static field of a class
 monitor      Monitor method execution statistics, e.g. total/success/failure count, average rt, fail rate, etc.
 stack        Display the stack trace for the specified class and method
 thread       Display thread info, thread stack
 trace        Trace the execution time of specified method invocation.
 watch        Display the input/output parameter, return object, and thrown exception of specified method invocation
 tt           Time Tunnel
 jvm          Display the target JVM information
 perfcounter  Display the perf counter information.
 ognl         Execute ognl expression.
 mc           Memory compiler, compiles java files into bytecode and class files in memory.
 redefine     Redefine classes. @see Instrumentation#redefineClasses(ClassDefinition...)
 retransform  Retransform classes. @see Instrumentation#retransformClasses(Class...)
 dashboard    Overview of target jvm's thread, memory, gc, vm, tomcat info.
 dump         Dump class byte array from JVM
 heapdump     Heap dump
 options      View and change various Arthas options
 cls          Clear the screen
 reset        Reset all the enhanced classes
 version      Display Arthas version
 session      Display current session information
 sysprop      Display, and change the system properties.
 sysenv       Display the system env.
 vmoption     Display, and update the vm diagnostic options.
 logger       Print logger info, and update the logger level
 history      Display command history
 cat          Concatenate and print files
 base64       Encode and decode using Base64 representation
 echo         write arguments to the standard output
 pwd          Return working directory name
 mbean        Display the mbean information
 grep         grep command for pipes.
 tee          tee command for pipes.
 profiler     Async Profiler. https://github.com/jvm-profiling-tools/async-profiler
 vmtool       jvm tool
 stop         Stop/Shutdown Arthas server and exit the console.
```

每个子命令，都可以跟上 `-h` 来进一步获取帮助用法信息。

## 2.3 thread指令

```
[arthas@5201]$ thread -h
 USAGE:   
   thread [--all] [-h] [-b] [--lockedMonitors] [--lockedSynchronizers] [-i <value>] [--state <value>] [-n <value>] [id]

 SUMMARY:     
   Display thread info, thread stack
                                                                                                                                                                                                                 
 EXAMPLES: 
   thread
   thread 51
   thread -n -1
   thread -n 5
   thread -b
   thread -i 2000
   thread --state BLOCKED
   
 WIKI:                             
   https://arthas.aliyun.com/doc/thread

 OPTIONS:  
     --all                                                  Display all thread results instead of the first page
 -h, --help                                                 this help
 -b, --include-blocking-thread                              Find the thread who is holding a lock that blocks the most number of threads.
     --lockedMonitors                                       Find the thread info with lockedMonitors flag, default value is false.
     --lockedSynchronizers                                  Find the thread info with lockedSynchronizers flag, default value is false.
 -i, --sample-interval <value>                              Specify the sampling interval (in ms) when calculating cpu usage.
     --state <value>                                        Display the thead filter by the state. NEW, RUNNABLE, TIMED_WAITING, WAITING, BLOCKED, TERMINATED is optional.
 -n, --top-n-threads <value>                                The number of thread(s) to show, ordered by cpu utilization, -1 to show all.
 <id>                                                       Show thread stack
```

```
$ thread -i 5000
## 获取时间跨度为5s的计算汇总数据

$ thread -n 3
## 根据 CPU 使用率排序，获取从高到低的 3 个线程堆栈信息

$ thread -b
## 仅查看死锁线程的堆栈信息

$ thread --lockedSynchronizers
## 仅查看同步器死锁的线程堆栈信息
```

## 2.4 stop/exit 停止和离开

`stop`: 停止和退出 Arthas consol ，正常退出步骤。

`exit`: 仅离开 Arthas consol，但是绑定到 Java 进程的 arthas 任务不会退出。

```
[SHELL]# java -jar arthas-boot.jar
[INFO] arthas-boot version: 3.5.3
[INFO] Found existing java process, please choose one and input the serial number of the process, eg : 1. Then hit ENTER.
* [1]: 5201 cloud-access-auth-1.18.1.jar
  [2]: 14419 tsf-stack-base-1.0.0.jar
  [3]: 27862 cloud-access-gateway-1.18.1.jar
  [4]: 6550 tsfmanager-operation-1.29.1.jar
1
[INFO] arthas home: /root/.arthas/lib/3.5.4/arthas
[INFO] Try to attach process 5201
[INFO] Attach process 5201 success.
[INFO] arthas-client connect 127.0.0.1 3658
  ,---.  ,------. ,--------.,--.  ,--.  ,---.   ,---.  
 /  O  \ |  .--. ''--.  .--'|  '--'  | /  O  \ '   .-' 
|  .-.  ||  '--'.'   |  |   |  .--.  ||  .-.  |`.  `-. 
|  | |  ||  |\  \    |  |   |  |  |  ||  | |  |.-'    |
`--' `--'`--' '--'   `--'   `--'  `--'`--' `--'`-----' 
                                                       

wiki       https://arthas.aliyun.com/doc
tutorials  https://arthas.aliyun.com/doc/arthas-tutorials.html
version    3.5.4
main_class
pid        5201
time       2021-09-03 13:05:51

[arthas@5201]$ exit


[SHELL]# java -jar arthas-boot.jar
[INFO] arthas-boot version: 3.5.3
[INFO] Process 5201 already using port 3658				## 由于上次并没有 shutdown 关闭arthas与java进程的绑定，所以Arthas重新启动的时候，检测到仍然绑定到 5201 进程上面的。
[INFO] Process 5201 already using port 8563
[INFO] Found existing java process, please choose one and input the serial number of the process, eg : 1. Then hit ENTER.
* [1]: 5201 cloud-access-auth-1.18.1.jar
  [2]: 14419 tsf-stack-base-1.0.0.jar
  [3]: 27862 cloud-access-gateway-1.18.1.jar
  [4]: 6550 tsfmanager-operation-1.29.1.jar
```

我们通过 jstack -l 5201 来证实这一点

```
[root@VM-0-4-centos ~]# jstack -l 5201 | more
2021-09-03 13:08:16
Full thread dump OpenJDK 64-Bit Server VM (25.302-b08 mixed mode):

"arthas-NettyHttpTelnetBootstrap-3-3" #169 daemon prio=5 os_prio=0 tid=0x00007f314000b800 nid=0x5632 runnable [0x00007f30cb51a000]
   java.lang.Thread.State: RUNNABLE
	at sun.nio.ch.EPollArrayWrapper.epollWait(Native Method)
	at sun.nio.ch.EPollArrayWrapper.poll(EPollArrayWrapper.java:269)
	at sun.nio.ch.EPollSelectorImpl.doSelect(EPollSelectorImpl.java:93)
	at sun.nio.ch.SelectorImpl.lockAndDoSelect(SelectorImpl.java:86)
	- locked <0x00000000e8cafb00> (a com.alibaba.arthas.deps.io.netty.channel.nio.SelectedSelectionKeySet)
	- locked <0x00000000e8caf8a8> (a java.util.Collections$UnmodifiableSet)
	- locked <0x00000000e8caf790> (a sun.nio.ch.EPollSelectorImpl)
	at sun.nio.ch.SelectorImpl.select(SelectorImpl.java:97)
	at sun.nio.ch.SelectorImpl.select(SelectorImpl.java:101)
	at com.alibaba.arthas.deps.io.netty.channel.nio.SelectedSelectionKeySetSelector.select(SelectedSelectionKeySetSelector.java:68)
	at com.alibaba.arthas.deps.io.netty.channel.nio.NioEventLoop.select(NioEventLoop.java:810)
	at com.alibaba.arthas.deps.io.netty.channel.nio.NioEventLoop.run(NioEventLoop.java:457)
	at com.alibaba.arthas.deps.io.netty.util.concurrent.SingleThreadEventExecutor$4.run(SingleThreadEventExecutor.java:989)
	at com.alibaba.arthas.deps.io.netty.util.internal.ThreadExecutorMap$2.run(ThreadExecutorMap.java:74)
	at com.alibaba.arthas.deps.io.netty.util.concurrent.FastThreadLocalRunnable.run(FastThreadLocalRunnable.java:30)
	at java.lang.Thread.run(Thread.java:748)

   Locked ownable synchronizers:
	- None

"arthas-NettyHttpTelnetBootstrap-3-2" #168 daemon prio=5 os_prio=0 tid=0x00007f314000a000 nid=0x51ce runnable [0x00007f30d09f9000]
   java.lang.Thread.State: RUNNABLE
	at sun.nio.ch.EPollArrayWrapper.epollWait(Native Method)
	at sun.nio.ch.EPollArrayWrapper.poll(EPollArrayWrapper.java:269)
	at sun.nio.ch.EPollSelectorImpl.doSelect(EPollSelectorImpl.java:93)
	at sun.nio.ch.SelectorImpl.lockAndDoSelect(SelectorImpl.java:86)
	- locked <0x00000000e8cac058> (a com.alibaba.arthas.deps.io.netty.channel.nio.SelectedSelectionKeySet)
	- locked <0x00000000e8cabe00> (a java.util.Collections$UnmodifiableSet)
	- locked <0x00000000e8cabce8> (a sun.nio.ch.EPollSelectorImpl)
	at sun.nio.ch.SelectorImpl.select(SelectorImpl.java:97)
	at sun.nio.ch.SelectorImpl.select(SelectorImpl.java:101)
	at com.alibaba.arthas.deps.io.netty.channel.nio.SelectedSelectionKeySetSelector.select(SelectedSelectionKeySetSelector.java:68)
```

我们可以看到 5201 进程的java堆栈信息，有 arthas 的线程正在运行中。

正常退出步骤：

```
[arthas@5201]$ stop
Resetting all enhanced classes ...
Affect(class count: 0 , method count: 0) cost in 0 ms, listenerId: 0
Arthas Server is going to shutdown...
[arthas@5201]$ session (f0151617-7fd2-4b4b-b79f-31d366a72fc5) is closed because server is going to shutdown.
[SHELL]# jstack -l 5201 | more
2021-09-03 13:10:16
Full thread dump OpenJDK 64-Bit Server VM (25.302-b08 mixed mode):
"Abandoned connection cleanup thread" #51 daemon prio=5 os_prio=0 tid=0x00007f30e0246000 nid=0x1d86 in Object.wait() [0x00007f3120393000]
   java.lang.Thread.State: TIMED_WAITING (on object monitor)
	at java.lang.Object.wait(Native Method)
	at java.lang.ref.ReferenceQueue.remove(ReferenceQueue.java:144)
	- locked <0x00000000e3280300> (a java.lang.ref.ReferenceQueue$Lock)
	at com.mysql.jdbc.AbandonedConnectionCleanupThread.run(AbandonedConnectionCleanupThread.java:64)
	at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149)
	at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624)
	at java.lang.Thread.run(Thread.java:748)
   Locked ownable synchronizers:
	- <0x00000000e3280390> (a java.util.concurrent.ThreadPoolExecutor$Worker)
"Tomcat JDBC Pool Cleaner[1450495309:1630634377161]" #50 daemon prio=5 os_prio=0 tid=0x00007f30e01e4800 nid=0x1d85 in Object.wait() [0x00007f3120494000]
   java.lang.Thread.State: TIMED_WAITING (on object monitor)
	at java.lang.Object.wait(Native Method)
	at java.util.TimerThread.mainLoop(Timer.java:552)
	- locked <0x00000000e3280540> (a java.util.TaskQueue)
	at java.util.TimerThread.run(Timer.java:505)
   Locked ownable synchronizers:
	- None
```

可以看到，使用 `stop` 指令关闭arthas诊断程序后，java 进程上面的arthas线程绑定也一并退出了。

## 2.5 watch指令 --* 方法执行数据观测

`watch`指令算是 Arthas 中最常用的指令之一了，它能够获取指定`包.类.方法`的`入参`、`自身类方法体内部对象`以及`返回对象值`。

```
[arthas@5201]$ watch -h
 USAGE:  
   watch [-b] [-e] [--exclude-class-pattern <value>] [-x <value>] [-f] [-h] [-n <value>] [--listenerId <value>] [-E] [-M <value>] [-s] [-v] class-pattern method-pattern [express] [condition-express]

 SUMMARY:  
   Display the input/output parameter, return object, and thrown exception of specified method invocation
   The express may be one of the following expression (evaluated dynamically):
           target : the object
            clazz : the object's class
           method : the constructor or method
           params : the parameters array of method
     params[0..n] : the element of parameters array
        returnObj : the returned object of method
         throwExp : the throw exception of method
         isReturn : the method ended by return
          isThrow : the method ended by throwing exception
            #cost : the execution time in ms of method invocation
 Examples:     
   watch org.apache.commons.lang.StringUtils isBlank
   watch org.apache.commons.lang.StringUtils isBlank '{params, target, returnObj, throwExp}' -x 2
   watch *StringUtils isBlank params[0] params[0].length==1
   watch *StringUtils isBlank params '#cost>100'
   watch -f *StringUtils isBlank params
   watch *StringUtils isBlank params[0]
   watch -E -b org\.apache\.commons\.lang\.StringUtils isBlank params[0]
   watch javax.servlet.Filter * --exclude-class-pattern com.demo.TestFilter
                                                                                                                                                                                                                 
 WIKI:                                      
   https://arthas.aliyun.com/doc/watch

 OPTIONS:  
 -b, --before                                                          Watch before invocation
 -e, --exception                                                       Watch after throw exception
     --exclude-class-pattern <value>                                   exclude class name pattern, use either '.' or '/' as separator
 -x, --expand <value>                                                  Expand level of object (1 by default)
 -f, --finish                                                          Watch after invocation, enable by default
 -h, --help                                                            this help
 -n, --limits <value>                                                  Threshold of execution times
     --listenerId <value>                                              The special listenerId
 -E, --regex                                                           Enable regular expression to match (wildcard matching by default)
 -M, --sizeLimit <value>                                               Upper size limit in bytes for the result (10 * 1024 * 1024 by default)
 -s, --success                                                         Watch after successful invocation
 -v, --verbose                                                         Enables print verbose information, default value false.
 <class-pattern>                                                       The full qualified class name you want to watch
 <method-pattern>                                                      The method name you want to watch
 <express>                                                             The content you want to watch, written by ognl. Default value is '{params, target, returnObj}'
                                                                       Examples:
                                                                         params
                                                                         params[0]
                                                                         'params[0]+params[1]'
                                                                         '{params[0], target, returnObj}'
                                                                         returnObj
                                                                         throwExp
                                                                         target
                                                                         clazz
                                                                         method

 <condition-express>                                                   Conditional expression in ognl style, for example:
                                                                         TRUE  : 1==1
                                                                         TRUE  : true
                                                                         FALSE : false
                                                                         TRUE  : 'params.length>=0'
                                                                         FALSE : 1==2
                                                                         '#cost>100'
```

### 2.5.1 参数说明

watch 的参数比较多，主要是因为它能在 4 个不同的场景观察对象

| 参数名称            | 参数说明                                          |
| ------------------- | ------------------------------------------------- |
| *class-pattern*     | 类名表达式匹配                                    |
| *method-pattern*    | 方法名表达式匹配                                  |
| *express*           | 观察表达式，默认值：`{params, target, returnObj}` |
| *condition-express* | 条件表达式                                        |
| [b]                 | 在**方法调用之前**观察                            |
| [e]                 | 在**方法异常之后**观察                            |
| [s]                 | 在**方法返回之后**观察                            |
| [f]                 | 在**方法结束之后**(正常返回和异常返回)观察        |
| [E]                 | 开启正则表达式匹配，默认为通配符匹配              |
| [x:]                | 指定输出结果的属性遍历深度，默认为 1              |

这里重点要说明的是观察表达式，观察表达式的构成主要由 [`#OGNL`](https://commons.apache.org/proper/commons-ognl/language-guide.html) 表达式组成，所以你可以这样写`"{params,returnObj}"`，只要是一个合法的 ognl 表达式，都能被正常支持。

观察的维度也比较多，主要体现在参数 `advice` 的数据结构上。`Advice` 参数最主要是封装了通知节点的所有信息。请参考[表达式核心变量](https://arthas.aliyun.com/doc/advice-class.html)中关于该节点的描述。

### 2.5.2 使用举例

我需要观察`cloud-access-auth-1.18.1.jar`进程在处理登录信息时的登录方法信息，日志如下：

```
13:42:54.205 INFO  [http-nio-7001-exec-4] c.t.c.access.sso.service.impl.AuthenticateService - [Access Auth] account login parameter. accountName:qcloudAdmin ,password:******
```

得到指定类名为`AuthenticateService`。

我们带到 Arthas 中进行 watch：

```
### 报名在日志文件中是简写，所以我这里使用通配符方式匹配类名，第二个参数方法名我也用*代替，全部匹配
[arthas@5201]$ watch *AuthenticateService *
Press Q or Ctrl+C to abort.
Affect(class count: 2 , method count: 6) cost in 130 ms, listenerId: 16
### 从输出信息得知，在这个 Java 进程所有代码中匹配到有两个类，一共6个方法
```

我们来点击页面登录按钮，看看 watch 中能观察到哪些动作：

```
[arthas@5201]$ watch *AuthenticateService *
Press Q or Ctrl+C to abort.
Affect(class count: 2 , method count: 6) cost in 130 ms, listenerId: 16
    
#### 第一个方法开始执行 Begin
method=com.tencent.cloud.access.sso.service.impl.AuthenticateService.login location=AtExit
ts=2021-09-03 13:51:25; [cost=2.217281ms] result=@ArrayList[
    @Object[][isEmpty=false;size=3],
    @AuthenticateService[com.tencent.cloud.access.sso.service.impl.AuthenticateService@f5cadbf],
    @AccessAuthPrincipal[com.tencent.cloud.access.sso.model.AccessAuthPrincipal@72f71bf6],
]
#### 第一个方法执行结束 End
    
#### 第二个方法开始执行 Begin
method=com.tencent.cloud.access.sso.service.impl.AuthenticateService.updateSession location=AtExit
ts=2021-09-03 13:51:25; [cost=0.956478ms] result=@ArrayList[
    @Object[][isEmpty=false;size=2],
    @AuthenticateService[com.tencent.cloud.access.sso.service.impl.AuthenticateService@f5cadbf],
    @AuthenticationResponse[com.tencent.cloud.access.sso.model.AuthenticationResponse@6b2bae10],
]
#### 第二个方法执行退出 End
..............
```

在输出信息中我们可以看到，第一行有完整的`方法路径`，以及获取的退出状态`location`。

> - AtExit：表示正常退出。
> - AtExceptionExit：表示异常退出。

第二行有方法执行的`开始时间戳`以及`cost 开销` ，最后一个为watch的结果。

这里`result`的 ArrayList 数组是 `watch` 指令的强大之处，它默认包含三个对象：

- **`params`**: 入参，通常为数组，这里为 `@Object` 对象
- **`target`**: 运行中当前 this 对象，也就是这个类对象本身，这里为`@AuthenticateService`实体类对象
- **`returnObj`**: 返回对象值，这里为返回的`@AccessAuthPrincipal`对象

我们重新执行一次 watch 指令，这次咱们精确指定类名和方法名，以及加一个`-x`解析深度参数：

```
[arthas@5201]$ watch com.tencent.cloud.access.sso.service.impl.AuthenticateService login -x 2
Press Q or Ctrl+C to abort.
Affect(class count: 1 , method count: 2) cost in 74 ms, listenerId: 17
method=com.tencent.cloud.access.sso.service.impl.AuthenticateService.login location=AtExit
ts=2021-09-03 14:10:15; [cost=3.289679ms] result=@ArrayList[
    @Object[][
        @String[qcloudAdmin],
        @String[Bgi8c0yC+IAvRLkuQRy6kLQ6T2J/9PNrL6G/+KX9ppE=],
        @String[127.0.0.1],
    ],
    @AuthenticateService[
        log=@Logger[Logger[com.tencent.cloud.access.sso.service.impl.AuthenticateService]],
        sessionDAO=@RedisSessionDAO[com.tencent.cloud.access.sso.shiro.RedisSessionDAO@61813e98],
        accountSessionService=@AccountSessionService[com.tencent.cloud.access.account.service.impl.AccountSessionService@30e815ac],
        accessAuthRealm=@AccessAuthRealm[com.tencent.cloud.access.sso.shiro.AccessAuthRealm@1faea5],
        accountService=@AccountService[com.tencent.cloud.access.account.service.impl.AccountService@197459d8],
        ssoProperties=@SsoProperties[com.tencent.cloud.access.sso.config.SsoProperties@461879b2],
        securityManager=@DefaultSecurityManager[org.apache.shiro.mgt.DefaultSecurityManager@3b0f92f0],
        ssoService=@QCloudSsoService[com.tencent.cloud.access.sso.service.impl.QCloudSsoService@4f8704f5],
        userService=@UserService[com.tencent.cloud.access.user.service.impl.UserService@5e69da74],
    ],
    @AccessAuthPrincipal[
        serialVersionUID=@Long[-2856270666386831504],
        accountName=@String[qcloudAdmin],
        userId=null,
        accountId=@String[account-96a79v5b],
        password=@String[VYUQeJrC5EJq21t/f9rb1Djm+4+eanqXY3ZkW2oiiwA=],
        serviceCode=null,
        isAdmin=null,
        loginName=null,
        serialVersionUID=@Long[8229738167949958388],
        token=@String[54158a08d8104de57a855249eb6ffe06],
        serialVersionUID=@Long[-4556824360581761962],
        appId=null,
        subAccountUin=null,
        uin=null,
        requestId=null,
        region=null,
        kv=null,
    ],
]
    
method=com.tencent.cloud.access.sso.service.impl.AuthenticateService.login location=AtExit
ts=2021-09-03 14:10:15; [cost=9.571541ms] result=@ArrayList[
    @Object[][
        @LoginRequest[com.tencent.cloud.access.sso.model.LoginRequest@3dd2bbb0],
    ],
    @AuthenticateService[
        log=@Logger[Logger[com.tencent.cloud.access.sso.service.impl.AuthenticateService]],
        sessionDAO=@RedisSessionDAO[com.tencent.cloud.access.sso.shiro.RedisSessionDAO@61813e98],
        accountSessionService=@AccountSessionService[com.tencent.cloud.access.account.service.impl.AccountSessionService@30e815ac],
        accessAuthRealm=@AccessAuthRealm[com.tencent.cloud.access.sso.shiro.AccessAuthRealm@1faea5],
        accountService=@AccountService[com.tencent.cloud.access.account.service.impl.AccountService@197459d8],
        ssoProperties=@SsoProperties[com.tencent.cloud.access.sso.config.SsoProperties@461879b2],
        securityManager=@DefaultSecurityManager[org.apache.shiro.mgt.DefaultSecurityManager@3b0f92f0],
        ssoService=@QCloudSsoService[com.tencent.cloud.access.sso.service.impl.QCloudSsoService@4f8704f5],
        userService=@UserService[com.tencent.cloud.access.user.service.impl.UserService@5e69da74],
    ],
    @AuthenticationResponse[
        serialVersionUID=@Long[-6134589862066278677],
        token=@String[54158a08d8104de57a855249eb6ffe06],
        accountId=@String[account-96a79v5b],
        changePwd=@String[N],
        users=@ArrayList[isEmpty=false;size=1],
    ],
]
..............
```

`watch` 指令的`-x`选项表示解析三个阶段的对象深度，**默认值为 1**，也就是只解析到对象层，不解析对象的下一级属性等信息。

通过上述指令，我们获取到了更加详细的入参、this对象、返回值的信息，依次解析如下：

*params 方法入参：*

- @String[qcloudAdmin]: 参数一，用户名
- @String[Bgi8c0yC+IAvRLkuQRy6kLQ6T2J/9PNrL6G/+KX9ppE=]: 密码加密串
- @String[127.0.0.1]: 来源主机信息

`this`方法体内部对象：

- log=@Logger: 定义 Logger 对象
- sessionDAO=@RedisSessionDAO: 会话session数据入口，为 RedisSessionDAO 对象
- accountSessionService=@AccountSessionService: 私有对象
- ........

`returnObj` 返回值对象，这里为`@AccessAuthPrincipal`对象：

- serialVersionUID: 用户UID
- accountName: 登录用户名
- password: 用户密码加密串
- token: token串
- ........

### 2.5.3 条件表达式过滤

```
[arthas@5201]$ watch com.tencent.cloud.access.sso.service.impl.AuthenticateService login '{params[0]=qcloudAdmin,returnObj}' -x 2
```

诊断返回信息包含`params[0]`和`returnObj对象`，而且仅获取入参`params[0] == "qcloudAdmin"`的方法调用，最后解析深度为 2。

只有满足条件的调用，才会被 Arthas 捕获到。

### 2.5.4 观察异常信息

```
[arthas@5201]$ watch com.tencent.cloud.access.sso.service.impl.AuthenticateService login '{params[0],throwExp}' -e -x 2
```

- -e: 表示在抛出异常之后观察
- express观察表达式第二个参数`throwExp`: 表示异常信息的变量是`throwExp`

### 2.5.5 按方法执行耗时进行过滤

```
[arthas@5201]$ watch com.tencent.cloud.access.sso.service.impl.AuthenticateService login '{params[0],returnObj}' '#cost>200' -x 2
```

- `watch`指令的第四个参数 *condition-express* 为**`#cost>200`**，表示诊断处理耗时大于 200ms 才会被捕获输出。
- `-x 2`: 解析深度为 2。

### 2.5.6 仅观察当前对象的属性

```
[arthas@5201]$ watch com.tencent.cloud.access.sso.service.impl.AuthenticateService login 'target' -x 3
Press Q or Ctrl+C to abort.
Affect(class count: 1 , method count: 2) cost in 76 ms, listenerId: 23
method=com.tencent.cloud.access.sso.service.impl.AuthenticateService.login location=AtExit
ts=2021-09-03 14:48:33; [cost=3.189525ms] result=@AuthenticateService[
    log=@Logger[
        serialVersionUID=@Long[5454405123156820674],
        FQCN=@String[ch.qos.logback.classic.Logger],
        name=@String[com.tencent.cloud.access.sso.service.impl.AuthenticateService],
        level=null,
        effectiveLevelInt=@Integer[20000],
        parent=@Logger[
            serialVersionUID=@Long[5454405123156820674],
            FQCN=@String[ch.qos.logback.classic.Logger],
            name=@String[com.tencent.cloud.access.sso.service.impl],
            level=null,
            effectiveLevelInt=@Integer[20000],
            parent=@Logger[Logger[com.tencent.cloud.access.sso.service]],
            childrenList=@CopyOnWriteArrayList[isEmpty=false;size=2],
            aai=null,
            additive=@Boolean[true],
            loggerContext=@LoggerContext[ch.qos.logback.classic.LoggerContext[default]],
        ],
        childrenList=null,
        aai=null,
        additive=@Boolean[true],
        loggerContext=@LoggerContext[
            DEFAULT_PACKAGING_DATA=@Boolean[false],
            root=@Logger[Logger[ROOT]],
            size=@Integer[501],
            noAppenderWarning=@Integer[0],
            loggerContextListenerList=@ArrayList[isEmpty=false;size=1],
            loggerCache=@ConcurrentHashMap[isEmpty=false;size=501],
            loggerContextRemoteView=@LoggerContextVO[LoggerContextVO{name='default', propertyMap={}, birthTime=1630634095948}],
            turboFilterList=@TurboFilterList[isEmpty=true;size=0],
            packagingDataEnabled=@Boolean[false],
            maxCallerDataDepth=@Integer[8],
            resetCount=@Integer[2],
            frameworkPackages=@ArrayList[isEmpty=true;size=0],
            birthTime=@Long[1630634095948],
            name=@String[default],
            sm=@BasicStatusManager[ch.qos.logback.core.BasicStatusManager@612c57fb],
            propertyMap=@HashMap[isEmpty=true;size=0],
            objectMap=@HashMap[isEmpty=false;size=6],
            configurationLock=@LogbackLock[ch.qos.logback.core.spi.LogbackLock@36566db5],
            scheduledExecutorService=null,
            scheduledFutures=@ArrayList[isEmpty=true;size=0],
            lifeCycleManager=@LifeCycleManager[ch.qos.logback.core.LifeCycleManager@44477e6],
            started=@Boolean[false],
        ],
    ],
    sessionDAO=@RedisSessionDAO[
      .............
```

扩展思维，我们可以直接透过一次调用，观察到底层连接 jdbc 的信息：

```
[arthas@5201]$ watch com.tencent.cloud.access.sso.service.impl.AuthenticateService login 'target.userService.userDao.jdbcTemplate.dataSource.pool.poolProperties.url' -x 2
Press Q or Ctrl+C to abort.
Affect(class count: 1 , method count: 2) cost in 69 ms, listenerId: 34
method=com.tencent.cloud.access.sso.service.impl.AuthenticateService.login location=AtExit
ts=2021-09-03 15:09:55; [cost=2.682966ms] result=@String[jdbc:mysql://*.*.*.*:3306/access_auth?useSSL=false&characterEncoding=utf8]
                                                         
method=com.tencent.cloud.access.sso.service.impl.AuthenticateService.login location=AtExit
ts=2021-09-03 15:09:55; [cost=21.373065ms] result=@String[jdbc:mysql://*.*.*.*:3306/access_auth?useSSL=false&characterEncoding=utf8]
```

这里就从顶层往下，获取到了该次调用，涉及到查库的 jdbc `dataSource` 连接配置信息。

`result`返回的是一个 `String` 类型对象，值为 `jdbc:mysql://*.*.*.*:3306/access_auth?useSSL=false&characterEncoding=utf8`。

### 2.5.7 排除指定的类

```
[arthas@5201]$ watch com.tencent.cloud.access.sso.service.impl.* * 'target' -x 1 --exclude-class-pattern AuthorizeService | grep --color AuthorizeService
Press Q or Ctrl+C to abort.
```

- `--exclude-class-pattern`：排除指定的类

## 2.6 Trace指令 *

方法内部调用路径，并输出方法路径上的每个节点上耗时

`trace` 命令能主动搜索 `class-pattern`／`method-pattern` 对应的方法调用路径，渲染和统计整个调用链路上的所有性能开销和追踪调用链路。

### 2.6.1 参数说明

| 参数名称            | 参数说明                             |
| ------------------- | ------------------------------------ |
| *class-pattern*     | 类名表达式匹配                       |
| *method-pattern*    | 方法名表达式匹配                     |
| *condition-express* | 条件表达式                           |
| [E]                 | 开启正则表达式匹配，默认为通配符匹配 |
| `[n:]`              | 命令执行次数                         |
| `#cost`             | 方法执行耗时                         |

这里重点要说明的是观察表达式，观察表达式的构成主要由 [`#OGNL`](https://commons.apache.org/proper/commons-ognl/language-guide.html) 表达式组成，所以你可以这样写`"{params,returnObj}"`，只要是一个合法的 ognl 表达式，都能被正常支持。

观察的维度也比较多，主要体现在参数 `advice` 的数据结构上。`Advice` 参数最主要是封装了通知节点的所有信息。

请参考[表达式核心变量](https://arthas.aliyun.com/doc/advice-class.html)中关于该节点的描述。

- 特殊用法请参考：https://github.com/alibaba/arthas/issues/71
- OGNL表达式官网：https://commons.apache.org/proper/commons-ognl/language-guide.html

很多时候我们只想看到某个方法的rt大于某个时间之后的trace结果，现在Arthas可以按照方法执行的耗时来进行过滤了，例如`trace *StringUtils isBlank '#cost>100'`表示当执行时间超过100ms的时候，才会输出trace的结果。

> watch/stack/trace这个三个命令都支持`#cost`

### 2.6.2 使用举例

```
[arthas@5201]$ trace com.tencent.cloud.access.sso.service.impl.AuthenticateService login
Press Q or Ctrl+C to abort.
Affect(class count: 1 , method count: 2) cost in 114 ms, listenerId: 49
`---ts=2021-09-03 15:37:52;thread_name=http-nio-7001-exec-5;id=18;is_daemon=true;priority=5;TCCL=org.springframework.boot.context.embedded.tomcat.TomcatEmbeddedWebappClassLoader@1cfd053
    `---[6.69059ms] com.tencent.cloud.access.sso.service.impl.AuthenticateService:login()
        +---[0.045058ms] com.tencent.cloud.access.sso.model.LoginRequest:getOpt() #87
        +---[0.011503ms] com.tencent.cloud.access.sso.constant.LoginType:getType() #88
        +---[0.004858ms] com.tencent.cloud.access.sso.constant.LoginType:getType() #89
        +---[0.005082ms] com.tencent.cloud.access.sso.model.LoginRequest:getAccountName() #93
        +---[0.005074ms] com.tencent.cloud.access.sso.model.LoginRequest:getPassword() #94
        +---[min=0.002257ms,max=0.010395ms,total=0.012652ms,count=2] org.springframework.util.StringUtils:isEmpty() #95
        +---[0.008128ms] com.tencent.cloud.access.sso.config.SsoProperties:isPasswordTextPrintable() #100
        +---[0.084201ms] org.slf4j.Logger:info() #99
        +---[0.00653ms] com.tencent.cloud.access.sso.model.AuthenticationResponse:<init>() #101
        +---[0.004871ms] com.tencent.cloud.access.sso.model.LoginRequest:getRemoteHost() #102
        +---[3.317607ms] com.tencent.cloud.access.sso.service.impl.AuthenticateService:login() #102
        |   `---[3.285177ms] com.tencent.cloud.access.sso.service.impl.AuthenticateService:login()
        |       +---[0.008045ms] org.apache.shiro.authc.UsernamePasswordToken:<init>() #139
        |       +---[0.011232ms] org.apache.shiro.subject.SimplePrincipalCollection:<init>() #141
        |       +---[0.00843ms] org.apache.shiro.subject.support.DelegatingSubject:<init>() #142
        |       +---[0.015667ms] org.apache.shiro.util.ThreadContext:bind() #143
        |       +---[1.051658ms] org.apache.shiro.subject.support.DelegatingSubject:login() #144
        |       +---[0.988623ms] org.apache.shiro.subject.support.DelegatingSubject:getSession() #145
        |       +---[0.015629ms] org.apache.shiro.session.Session:getId() #146
        |       +---[0.323618ms] org.apache.shiro.subject.support.DelegatingSubject:getPrincipal() #147
        |       +---[0.009258ms] com.tencent.cloud.access.sso.model.AccessAuthPrincipal:setToken() #149
        |       +---[0.007608ms] com.tencent.cloud.access.sso.model.AccessAuthPrincipal:setAccountName() #150
        |       +---[0.429798ms] org.apache.shiro.session.Session:setAttribute() #151
        |       `---[0.207347ms] com.tencent.cloud.access.account.service.IAccountSessionService:bind() #152
        +---[0.010654ms] com.tencent.cloud.access.account.Account:<init>() #103
        +---[0.824315ms] com.tencent.cloud.access.account.service.IAccountService:find() #103
        +---[0.006474ms] com.tencent.cloud.access.account.Account:getLock() #104
        +---[0.004144ms] com.tencent.cloud.access.account.Account:getChangePassword() #107
        +---[0.005663ms] com.tencent.cloud.access.sso.model.AuthenticationResponse:setChangePwd() #107
        +---[0.004683ms] com.tencent.cloud.access.sso.model.AccessAuthPrincipal:getToken() #108
        +---[0.00414ms] com.tencent.cloud.access.sso.model.AuthenticationResponse:setToken() #108
        +---[0.003733ms] com.tencent.cloud.access.account.Account:getAccountId() #109
        +---[0.005164ms] com.tencent.cloud.access.sso.model.AuthenticationResponse:setAccountId() #109
        +---[0.002866ms] com.tencent.cloud.access.sso.model.AccessAuthPrincipal:setAccountName() #110
        +---[0.00399ms] com.tencent.cloud.access.sso.model.AccessAuthPrincipal:getAccountId() #112
        +---[0.014922ms] com.tencent.cloud.access.user.User:<init>() #112
        +---[0.004781ms] com.tencent.cloud.access.user.User:setAppIsolate() #113
        +---[0.83272ms] com.tencent.cloud.access.user.service.IUserService:findAccountList() #114
        +---[0.006398ms] com.tencent.cloud.access.user.User:getUserId() #116
        +---[0.005214ms] com.tencent.cloud.access.sso.model.AccessAuthPrincipal:setUserId() #116
        +---[0.00349ms] com.tencent.cloud.access.sso.model.AccessAuthPrincipal:getToken() #118
        +---[0.002987ms] com.tencent.cloud.access.user.User:getUserId() #118
        +---[0.887095ms] com.tencent.cloud.access.sso.service.impl.AuthenticateService:updateSession() #118
        `---[0.004734ms] com.tencent.cloud.access.sso.model.AuthenticationResponse:setUsers() #120
`---ts=2021-09-03 15:37:52;thread_name=http-nio-7001-exec-1;id=14;is_daemon=true;priority=5;TCCL=org.springframework.boot.context.embedded.tomcat.TomcatEmbeddedWebappClassLoader@1cfd053
    `---[1.28437ms] com.tencent.cloud.access.sso.service.impl.AuthenticateService:login()
        +---[0.003596ms] com.tencent.cloud.access.sso.model.LoginRequest:getOpt() #87
        +---[0.006076ms] com.tencent.cloud.access.sso.constant.LoginType:getType() #88
        +---[0.002865ms] com.tencent.cloud.access.sso.constant.LoginType:getType() #89
        +---[0.010558ms] com.tencent.cloud.access.sso.model.LoginRequest:getAccessToken() #123
        +---[0.003959ms] com.tencent.cloud.access.sso.model.LoginRequest:getUid() #124
        +---[0.003368ms] org.springframework.util.StringUtils:isEmpty() #125
        +---[0.002671ms] org.springframework.util.StringUtils:isEmpty() #128
        `---[1.166953ms] com.tencent.cloud.access.sso.service.impl.AuthenticateService:updateSession() #131
```

### 2.6.3 耗时过滤诊断

```
[arthas@5201]$ trace com.tencent.cloud.access.sso.service.impl.AuthenticateService login '#cost > 2000'
```

- `#cost > 2000`: 仅捕获开销时间大于 2000ms 的路径。

### 2.6.4 仅过滤方法一次调用

```
[arthas@5201]$ trace com.tencent.cloud.access.sso.service.impl.AuthenticateService login -n 1
```

仅捕获一次指定方法的调用，然后退出任务。

## 2.7 sysprop指令 -- 获取/设置进程系统属性

sysprop 主要用来查看、设置当前进程的系统属性信息。

查看当前java进程的系统属性

### 2.7.1 使用举例

```
[arthas@27878]$ sysprop
 KEY                                                   VALUE
-------------------------------------------------------------------------
 awt.toolkit                                           sun.awt.X11.XToolkit
 file.encoding.pkg                                     sun.io
 java.specification.version                            1.8
 sun.cpu.isalist
 sun.jnu.encoding                                      UTF-8
 java.class.path                                       /data/tsf/tsf-oss/tsf-ratelimit/tsf-ratelimit-1.29.1/lib/tsf-ratelimit-1.29.1.jar
 java.vm.vendor                                        Tencent
 sun.arch.data.model                                   64
 java.vendor.url                                       http://jdk.oa.com/
 catalina.useNaming                                    false
 user.timezone                                         Asia/Shanghai
 org.jboss.logging.provider                            slf4j
 os.name                                               Linux
 java.vm.specification.version                         1.8
 @appId                                                tsf-ratelimit
 user.country                                          US
 sun.java.launcher                                     SUN_STANDARD
 sun.boot.library.path                                 /data/TencentKona-8.0.2-252/jre/lib/amd64
 sun.java.command                                      /data/tsf/tsf-oss/tsf-ratelimit/tsf-ratelimit-1.29.1/lib/tsf-ratelimit-1.29.1.jar
 sun.cpu.endian                                        little
 user.home                                             /root
 user.language                                         en
 java.specification.vendor                             Oracle Corporation
 java.home                                             /data/TencentKona-8.0.2-252/jre
 file.separator                                        /
 line.separator

 java.vm.specification.vendor                          Oracle Corporation
 java.specification.name                               Java Platform API Specification
 java.awt.graphicsenv                                  sun.awt.X11GraphicsEnvironment
 java.awt.headless                                     true
 LOG_LEVEL_PATTERN                                     %5p [bootstrap,%X{X-B3-TraceId:-},%X{X-B3-SpanId:-},%X{X-Span-Export:-}]
 sun.boot.class.path                                   /data/TencentKona-8.0.2-252/jre/lib/resources.jar:/data/TencentKona-8.0.2-252/jre/lib/rt.jar:/data/TencentKona-8.0.2-252/jre/lib/sunrsasign.jar:/data/TencentKona-8.0.2-252/jre/lib/jsse.jar:/data/TencentKona-8.0.2-2
                                                       52/jre/lib/jce.jar:/data/TencentKona-8.0.2-252/jre/lib/charsets.jar:/data/TencentKona-8.0.2-252/jre/lib/jfr.jar:/data/TencentKona-8.0.2-252/jre/classes
 java.protocol.handler.pkgs                            org.springframework.boot.loader
 sun.management.compiler                               HotSpot 64-Bit Tiered Compilers
 java.runtime.version                                  1.8.0_252-b1
 java.net.preferIPv4Stack                              true
 user.name                                             root
 path.separator                                        :
 os.version                                            3.10.0-1127.19.1.el7.x86_64
 java.endorsed.dirs                                    /data/TencentKona-8.0.2-252/jre/lib/endorsed
 java.runtime.name                                     OpenJDK Runtime Environment
 file.encoding                                         UTF-8
 spring.beaninfo.ignore                                true
 sun.nio.ch.bugLevel
 java.vm.name                                          OpenJDK 64-Bit Server VM
 LOG_FILE                                              /var/log/tsf-oss/tsf-ratelimit/tsf-ratelimit
 java.vendor.url.bug                                   http://ce.oa.com/bia
 java.io.tmpdir                                        /tmp
 catalina.home                                         /tmp/tomcat.8220305148167761737.23000
 java.version                                          1.8.0_252
 user.dir                                              /data/tsf/tsf-oss/tsf-ratelimit/tsf-ratelimit-1.29.1
 os.arch                                               amd64
 PID                                                   27878
 java.vm.specification.name                            Java Virtual Machine Specification
 java.awt.printerjob                                   sun.print.PSPrinterJob
 sun.os.patch.level                                    unknown
 catalina.base                                         /tmp/tomcat.8220305148167761737.23000
 loader.path                                           /data/tsf/tsf-oss/tsf-ratelimit/tsf-ratelimit-1.29.1/config
 java.library.path                                     /data/tsf/tsf-oss/tsf-ratelimit/tsf-ratelimit-1.29.1/lib::/usr/java/packages/lib/amd64:/usr/lib64:/lib64:/lib:/usr/lib
 java.vm.info                                          mixed mode, sharing
 java.vendor                                           Tencent
 java.vm.version                                       25.252-b1
 java.ext.dirs                                         /data/TencentKona-8.0.2-252/jre/lib/ext:/usr/java/packages/lib/ext
 sun.io.unicode.encoding                               UnicodeLittle
 java.class.version                                    52.0
```

临时设置当前进程的系统属性

```
[arthas@29749]$ sysprop java.class.path /data/jdk/latest
Successfully changed the system property.
 KEY                                                   VALUE
-----------------------------------------------------------------------------------
 java.class.path                                       /data/jdk/latest
```

## 2.8 logger指令 -- *查看or设置logger

### 2.8.1 参数说明

```
[arthas@29749]$ logger -h
 USAGE:      
   logger [-c <value>] [--classLoaderClass <value>] [-h] [--include-no-appender] [-l <value>] [-n <value>]

 SUMMARY:    
   Print logger info, and update the logger level
                                                                                                                               
 Examples:    
   logger
   logger -c 327a647b
   logger -c 327a647b --name ROOT --level debug
   logger --include-no-appender
                                                               
 WIKI:         
   https://arthas.aliyun.com/doc/logger

 OPTIONS: 
 -c, --classloader <value>                       classLoader hashcode, if no value is set, default value is SystemClassLoader
     --classLoaderClass <value>                  The class name of the special class's classLoader.
 -h, --help                                      this help
     --include-no-appender                       include the loggers which don't have appenders, default value false
 -l, --level <value>                             set logger level
 -n, --name <value>                              logger name
```

### 2.8.2 使用举例

设置 logger 的 ROOT appender 的日志级别

```
##### 获取 logger 类信息
[arthas@29749]$ logger
 name                                         ROOT
 class                                        ch.qos.logback.classic.Logger
 classLoader                                  org.springframework.boot.loader.LaunchedURLClassLoader@5674cd4d
 classLoaderHash                              5674cd4d
 level                                        INFO
 effectiveLevel                               INFO
 ......................

##### 设置 ROOT 名称日志级别为 DEBUG
[arthas@29749]$ logger -c 5674cd4d -n ROOT -l DEBUG
```

## 2.9 heapdump指令--堆转储

### 2.9.1 参数说明

```
[arthas@29749]$ heapdump -h
 USAGE:     
   heapdump [-h] [-l] [file]

 SUMMARY:   
   Heap dump
              
 Examples:    
   heapdump           ## hprof 文件保存到当前目录下
   heapdump --live    ## 活跃对象
   heapdump --live /tmp/dump.hprof
                                                                                                                       
 WIKI:   
   https://arthas.aliyun.com/doc/heapdump

 OPTIONS:     
 -h, --help                                          this help
 -l, --live                                          Dump only live objects; if not specified, all objects in the heap are dumped.
 <file>                                              Output file
```

## 2.10 src指令 -- 获取已加载列表

### 2.10.1 参数说明

```
[arthas@29749]$  sc -h
 USAGE: 
   sc [-c <value>] [--classLoaderClass <value>] [-d] [-x <value>] [-f] [-h] [-n <value>] [-E] class-pattern

 SUMMARY:  
   Search all the classes loaded by JVM
                                   
 EXAMPLES:  
   sc -d org.apache.commons.lang.StringUtils
   sc -d org/apache/commons/lang/StringUtils
   sc -d *StringUtils
   sc -d -f org.apache.commons.lang.StringUtils
   sc -E org\\.apache\\.commons\\.lang\\.StringUtils
        
 WIKI:     
   https://arthas.aliyun.com/doc/sc

 OPTIONS:    
 -c, --classloader <value>                             The hash code of the special class's classLoader
     --classLoaderClass <value>                        The class name of the special class's classLoader.
 -d, --details                                         Display the details of class
 -x, --expand <value>                                  Expand level of object (0 by default)
 -f, --field                                           Display all the member variables
 -h, --help                                            this help
 -n, --limits <value>                                  Maximum number of matching classes with details (100 by default)
 -E, --regex                                           Enable regular expression to match (wildcard matching by default)
 <class-pattern>                                       Class name pattern, use either '.' or '/' as separator
```

### 2.10.2 使用举例

```
#### 根据通配符获取已加载的包名类名列表
[arthas@29749]$ sc com.tencent.tsf.*
com.sun.proxy.$Proxy132
com.sun.proxy.$Proxy143
com.tencent.tsf.TsfApplicationStarter
com.tencent.tsf.TsfApplicationStarter$$EnhancerBySpringCGLIB$$e6e6d3dc
com.tencent.tsf.common.TsfBaseEntity
com.tencent.tsf.common.TsfPage
com.tencent.tsf.common.TsfPageQuery
com.tencent.tsf.common.aop.ControllerCommonLog
..............
```

`-d` 参数获取具体类的基础信息：

```
[arthas@29749]$ sc com.tencent.tsf.TsfApplicationStarter -d
 class-info        com.tencent.tsf.TsfApplicationStarter
 code-source       file:/data/tsf/tsf-oss/tsf-ratelimit/tsf-ratelimit-1.29.1/lib/tsf-ratelimit-1.29.1.jar!/BOOT-INF/lib/tsf-common-1.29.1.jar!/
 name              com.tencent.tsf.TsfApplicationStarter
 isInterface       false
 isAnnotation      false
 isEnum            false
 isAnonymousClass  false
 isArray           false
 isLocalClass      false
 isMemberClass     false
 isPrimitive       false
 isSynthetic       false
 simple-name       TsfApplicationStarter
 modifier          public
 annotation        org.springframework.boot.autoconfigure.SpringBootApplication,org.springframework.cloud.client.discovery.EnableDiscoveryClient,org.springframework.cloud.netflix.feign.EnableFeignClients,org.springframework.transaction.annotation.EnableTransactionManag
                   ement,org.springframework.scheduling.annotation.EnableScheduling,org.springframework.context.annotation.EnableAspectJAutoProxy
 interfaces
 super-class       +-java.lang.Object
 class-loader      +-org.springframework.boot.loader.LaunchedURLClassLoader@5674cd4d
                     +-sun.misc.Launcher$AppClassLoader@70dea4e
                       +-sun.misc.Launcher$ExtClassLoader@65e2dbf3
 classLoaderHash   5674cd4d

 class-info        com.tencent.tsf.TsfApplicationStarter$$EnhancerBySpringCGLIB$$e6e6d3dc
 code-source       file:/data/tsf/tsf-oss/tsf-ratelimit/tsf-ratelimit-1.29.1/lib/tsf-ratelimit-1.29.1.jar!/BOOT-INF/lib/tsf-common-1.29.1.jar!/
 name              com.tencent.tsf.TsfApplicationStarter$$EnhancerBySpringCGLIB$$e6e6d3dc
 isInterface       false
 isAnnotation      false
 isEnum            false
 isAnonymousClass  false
 isArray           false
 isLocalClass      false
 isMemberClass     false
 isPrimitive       false
 isSynthetic       false
 simple-name       TsfApplicationStarter$$EnhancerBySpringCGLIB$$e6e6d3dc
 modifier          public
 annotation
 interfaces        org.springframework.context.annotation.ConfigurationClassEnhancer$EnhancedConfiguration
 super-class       +-com.tencent.tsf.TsfApplicationStarter
                     +-java.lang.Object
 class-loader      +-org.springframework.boot.loader.LaunchedURLClassLoader@5674cd4d
                     +-sun.misc.Launcher$AppClassLoader@70dea4e
                       +-sun.misc.Launcher$ExtClassLoader@65e2dbf3
 classLoaderHash   5674cd4d

Affect(row-cnt:2) cost in 17 ms.
```

## 2.11 sm指令 -- 获取指定类的method信息

该指令参数与 sc 指令参数类似。

### 2.11.1 使用举例

```
##  获取 com.tencent.tsf.common.TsfPageQuery 类的所有方法列表
[arthas@29749]$ sm com.tencent.tsf.common.TsfPageQuery *
com.tencent.tsf.ratelimit.domain.Ratelimit <init>(Lcom/tencent/tsf/ratelimit/domain/Ratelimit;)V
com.tencent.tsf.ratelimit.domain.Ratelimit <init>()V
com.tencent.tsf.ratelimit.domain.Ratelimit toString()Ljava/lang/String;
com.tencent.tsf.ratelimit.domain.Ratelimit getRules()Ljava/util/List;
com.tencent.tsf.ratelimit.domain.Ratelimit lambda$containsIn$0(Lcom/tencent/tsf/ratelimit/domain/Ratelimit$Rule;Lcom/tencent/tsf/ratelimit/domain/Ratelimit$Rule;)Z
com.tencent.tsf.ratelimit.domain.Ratelimit setRules(Ljava/util/List;)V
com.tencent.tsf.ratelimit.domain.Ratelimit isValidRequest(Z)Z
com.tencent.tsf.ratelimit.domain.Ratelimit getRequestIdentity()Ljava/lang/String;
com.tencent.tsf.ratelimit.domain.Ratelimit setNamespaceId(Ljava/lang/String;)V
com.tencent.tsf.ratelimit.domain.Ratelimit containsIn(Ljava/util/List;)Z
com.tencent.tsf.ratelimit.domain.Ratelimit isDimensionConflict(Ljava/util/List;)Z
com.tencent.tsf.ratelimit.domain.Ratelimit getNamespaceId()Ljava/lang/String;
com.tencent.tsf.ratelimit.domain.Ratelimit getServiceName()Ljava/lang/String;
com.tencent.tsf.ratelimit.domain.Ratelimit setServiceName(Ljava/lang/String;)V
com.tencent.tsf.common.proxy.Application <init>()V
com.tencent.tsf.common.proxy.Application setApplicationId(Ljava/lang/String;)V
com.tencent.tsf.common.proxy.Application getMicroserviceType()Ljava/lang/String;
com.tencent.tsf.common.proxy.Application setMicroserviceType(Ljava/lang/String;)V
com.tencent.tsf.common.proxy.Application getApplicationId()Ljava/lang/String;
com.tencent.tsf.ratelimit.proxy.Microservice <init>()V
com.tencent.tsf.ratelimit.proxy.Microservice setMicroserviceName(Ljava/lang/String;)V
com.tencent.tsf.ratelimit.proxy.Microservice setNamespaceId(Ljava/lang/String;)V
com.tencent.tsf.ratelimit.proxy.Microservice getMicroserviceName()Ljava/lang/String;
com.tencent.tsf.ratelimit.proxy.Microservice getNamespaceId()Ljava/lang/String;
com.tencent.tsf.ratelimit.proxy.Microservice getMicroserviceId()Ljava/lang/String;
com.tencent.tsf.ratelimit.proxy.Microservice setMicroserviceId(Ljava/lang/String;)V
com.tencent.tsf.common.TsfPageQuery <init>()V
com.tencent.tsf.common.TsfPageQuery clear()V
com.tencent.tsf.common.TsfPageQuery getOffset()Ljava/lang/Integer;
com.tencent.tsf.common.TsfPageQuery setOffset(Ljava/lang/Integer;)V
com.tencent.tsf.common.TsfPageQuery initDefault()V
com.tencent.tsf.common.TsfPageQuery setSearchWord(Ljava/lang/String;)V
com.tencent.tsf.common.TsfPageQuery getOrderType()Ljava/lang/Integer;
com.tencent.tsf.common.TsfPageQuery getOrderTypeStr()Ljava/lang/String;
com.tencent.tsf.common.TsfPageQuery setOrderType(Ljava/lang/Integer;)V
com.tencent.tsf.common.TsfPageQuery getOrderBy()Ljava/lang/String;
com.tencent.tsf.common.TsfPageQuery setOrderBy(Ljava/lang/String;)V
com.tencent.tsf.common.TsfPageQuery getRealPage()I
com.tencent.tsf.common.TsfPageQuery transerPageQuery(Lcom/tencent/tsf/common/TsfPageQuery;)V
com.tencent.tsf.common.TsfPageQuery getSearchWordLikeStr()Ljava/lang/String;
com.tencent.tsf.common.TsfPageQuery getLimit()Ljava/lang/Integer;
com.tencent.tsf.common.TsfPageQuery setLimit(Ljava/lang/Integer;)V
com.tencent.tsf.common.TsfPageQuery getSearchWord()Ljava/lang/String;
Affect(row-cnt:43) cost in 12 ms.
```

## 2.12 monitor指令 -- 方法执行监控

该指令为非实时返回指令，默认 120s 返回一次统计值。

统计区间时间段内，方法执行的总数、成功次数、失败次数、平均执行率、失败比例 等信息。

### 2.12.1 参数说明

```
[arthas@8738]$ monitor -h
 USAGE:    
   monitor [-b] [-c <value>] [--exclude-class-pattern <value>] [-h] [-n <value>] [--listenerId <value>] [-E <value>] [-v] class-pattern method-pattern [condition-express]

 SUMMARY:  
   Monitor method execution statistics, e.g. total/success/failure count, average rt, fail rate, etc.
                                                                          
 Examples:    
   monitor org.apache.commons.lang.StringUtils isBlank
   monitor org.apache.commons.lang.StringUtils isBlank -c 5
   monitor org.apache.commons.lang.StringUtils isBlank params[0]!=null
   monitor -b org.apache.commons.lang.StringUtils isBlank params[0]!=null
   monitor -E org\.apache\.commons\.lang\.StringUtils isBlank
        
 WIKI:     
   https://arthas.aliyun.com/doc/monitor

 OPTIONS:   
 -b, --before                                           Evaluate the condition-express before method invoke
 -c, --cycle <value>                                    The monitor interval (in seconds), 60 seconds by default
     --exclude-class-pattern <value>                    exclude class name pattern, use either '.' or '/' as separator
 -h, --help                                             this help
 -n, --limits <value>                                   Threshold of execution times
     --listenerId <value>                               The special listenerId
 -E, --regex <value>                                    Enable regular expression to match (wildcard matching by default)
 -v, --verbose                                          Enables print verbose information, default value false.
 <class-pattern>                                        Path and classname of Pattern Matching
 <method-pattern>                                       Method of Pattern Matching
 <condition-express>                                    Conditional expression in ognl style, for example:
                                                           TRUE  : 1==1
                                                           TRUE  : true
                                                           FALSE : false
                                                           TRUE  : 'params.length>=0'
                                                           FALSE : 1==2
                                                           '#cost>100'
```

### 2.12.2 使用举例

```
[arthas@8738]$ monitor com.tencent.tsf.resource.ns.dao.NamespaceDao *
Press Q or Ctrl+C to abort.
Affect(class count: 1 , method count: 15) cost in 104 ms, listenerId: 6
 timestamp                 class                                         method            total      success  fail   avg-rt(ms)   fail-rate
----------------------------------------------------------------------------------------------------------------------------------------------------
 2021-09-09 18:26:58     com.tencent.tsf.resource.ns.dao.NamespaceDao   countList          12          12      0     1.08              0.00%
 2021-09-09 18:26:58     com.tencent.tsf.resource.ns.dao.NamespaceDao   getAuthWhereClause 28          28      0     0.18              0.00%
 2021-09-09 18:26:58     com.tencent.tsf.resource.ns.dao.NamespaceDao   findList           2           2       0     1.09              0.00%
```