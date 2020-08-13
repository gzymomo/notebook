[TOC]

[博客园：独行侠梦：一次容器化springboot程序OOM问题探险](https://www.cnblogs.com/hyq0823/p/11564168.html)

# 1、背景
通过Docker发布SpringBoot应用程序，线上环境突然出现OOM的情况，因为容器内基于的jdk是自己搞的精简jdk，没有过多JVM命令，需要想办法分析问题。

第一次直接进入容器：`docker exec -it containerId /bin/sh ` ，进入后，调用jvm分析命令，发现都不存在：
```bash
bash: jstack: command not found
bash: jmap: command not found
bash: jps: command not found
bash: jstat: command not found
```

# 2、解决办法
在宿主机安装一个完整的jdk1.8，然后将其拷贝到容器内部：
```bash
docker cp jdk1.8/ containerId:/root
```

# 3、分析JVM情况
## 3.1 jstat查看gc情况
` bin/jstat -gcutil 1 1s `
![](https://img2018.cnblogs.com/blog/894494/201909/894494-20190921190257694-1281262630.jpg)

## 3.2 jmap查看对象占用情况
看一下对象的占用情况，由于是容器内部，进程号为1，执行如下命令：
`  bin/jmap -histo 1 |more  `

![](https://img2018.cnblogs.com/blog/894494/201909/894494-20190921190257968-1636367859.jpg)

jmap -histo显示的对象含义：

- [C 代表  char[]
- [S 代表 short[]
- [I 代表 int[]
- [B 代表 byte[]
- [[I 代表 int[][]

## 3.3 jstack查看线程快照
```bash
 bin/jstack -l 1 > thread.txt
```

下载快照，这里推荐一个在线的线程快照分析网站。
> https://gceasy.io

## 3.4 jconsole来观察线程和内存情况
为了更好的观察，启动时指定jmx端口，使用jconsole来观察线程和内存情况,代码如下：
```bash
nohup java -jar -Djava.rmi.server.hostname=ip 
 -Dcom.sun.management.jmxremote.port=18099
 -Dcom.sun.management.jmxremote.rmi.port=18099
 -Dcom.sun.management.jmxremote.ssl=false
 -Dcom.sun.management.jmxremote.authenticate=false -jar
 com.hyq.kafkaMultipleProducer-1.0.0.jar   2>&1 &
```

连接jconsole后观察，发现线程数一直增长，使用内存也在逐渐增加,具体情况如下图：
![](https://img2018.cnblogs.com/blog/894494/201909/894494-20190921190258848-604033991.jpg)


可能尽快触发Full GC的几种方式

- 1) System.gc();或者Runtime.getRuntime().gc();
- 2 ) jmap -histo:live或者jmap -dump:live。    这个命令执行，JVM会先触发gc，然后再统计信息。
- 3） 老生代内存不足的时候