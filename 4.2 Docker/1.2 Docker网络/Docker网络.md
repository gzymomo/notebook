- [Docker容器间网络互联原理](https://www.cnblogs.com/ZhuChangwu/p/15512039.html)

# 一、Docker的五种网络

## 1.1 None

不为容器配置任何网络功能。

## 1.2 Container

与另一个运行中的容器共享NetworkNamespace，共享相同的网络视图。

## 1.3 Host

与主机共享Root Network Namespace，容器有完整的权限可以操纵主机的协议栈、路由表和防火墙等，所以被认为是不安全的。

## 1.4 Bridge

Docker设计的NAT网络模型。
Docker网络的初始化动作包括：创建docker0网桥、为docker0网桥新建子网及路由、创建相应的iptables规则等。

![Docker关键知识点儿汇总](https://minminmsn.com/images/docker/bridge.jpg)
在桥接模式下，Docker容器与Internet的通信，以及不同容器之间的通信，都是通过iptables规则控制的。

## 1.5 Overlay

Docker原生的跨主机多子网模型。
overlay网络模型比较复杂，底层需要类似consul或etcd的KV存储系统进行消息同步，核心是通过Linux网桥与vxlan隧道实现跨主机划分子网。
![Docker关键知识点儿汇总](https://minminmsn.com/images/docker/overlay.jpg)

# 二、Docker网络探究

![img](https://img-blog.csdnimg.cn/20211031220624974.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzQxOTczNjc3,size_16,color_FFFFFF,t_70)

如上红字所描述：同一个宿主机上的不同容器之间的网络如何互通的？？？

## 2.1 前置网络知识

### 2.1.1 docker默认为我们创建的网络

我们安装完docker之后，docker daemon会为我们自动创建3个网络，如下：

```bash
Copy~]# docker network ls
NETWORK ID     NAME                DRIVER    SCOPE
e71575e3722a   bridge              bridge    local
ab8e3d45575c   host                host      local
0c9b7c1134ff   none                null      local
```

其实docker有4种网络通信模型，分别是：bridge、host、none、container。

默认的使用的网络模型是bridge，也是我们生产上会使用到的网络模型。

下文中跟大家分享docker容器互通原理到时候呢，用到的也是bridge网络模型。

### 2.1.2 怎么理解docker0网桥

另外，当我们安装完docker之后，docker会为我们创建一个叫docker0的网络设备

通过`ifconfig`命令可以查看到它，看起来它貌似和eth0网络地位相当，像是一张网卡。然而并不是，docker0其实是一个Linux网桥

```bash
Copy[root@vip ~]# ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
       
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 00:0c:29:b4:97:ee brd ff:ff:ff:ff:ff:ff
    inet 10.4.7.99/24 brd 10.4.7.255 scope global noprefixroute eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::20c:29ff:feb4:97ee/64 scope link
       valid_lft forever preferred_lft forever
       
3: docker0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 02:42:db:fe:ff:db brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0
       valid_lft forever preferred_lft forever
    inet6 fe80::42:dbff:fefe:ffdb/64 scope link
       valid_lft forever preferred_lft forever
```

何以见得？可以通过下面的命令查看操作系统上的网桥信息

```bash
 ~]# yum install bridge-utils
 ~]# brctl show
bridge		 name				bridge id		STP enabled			interfaces
docker0		8000.0242f0a8c0be	no				veth86e2ef2			vethf0a8bc
```

那大家怎么理解Linux网桥的概念呢？

其实大家可以把docker0理解成一台虚拟的交换机！然后像下面这样类比着理解，就会豁然开朗

![img](https://img-blog.csdnimg.cn/20211031220625838.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzQxOTczNjc3,size_16,color_FFFFFF,t_70)

1、它好比是大学在机房上课时，老师旁边的那个大大的交换机设备。

2、把机房里的电脑都连接在交换机上，类比成docker 容器作为一台设备都连接着宿主机上的docker0。

3、把交换机和机房中的机器的ip在同一个网段，类比成docker0、和你启动的docker容器的ip也同属于172网段。

```bash
Copy# docker0 ip是：
 ~]# ifconfig
3: docker0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 02:42:db:fe:ff:db brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0
       valid_lft forever preferred_lft forever
    inet6 fe80::42:dbff:fefe:ffdb/64 scope link
       valid_lft forever preferred_lft forever
       

# 进入容器中查看ip是：
/# ifconfig
eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 172.17.0.2  netmask 255.255.0.0  broadcast 172.17.255.255
        ether 02:42:ac:11:00:02  txqueuelen 0  (Ethernet)
        RX packets 13  bytes 1102 (1.0 KiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 0  bytes 0 (0.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

类比成这样：

![img](https://img-blog.csdnimg.cn/20211031220626416.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzQxOTczNjc3,size_16,color_FFFFFF,t_70)

------

## 2.2 什么是veth-pair技术？

我们刚才做类比理解docker0的时候说：把机房里的电脑都连接在交换机上，类比成docker 容器作为一台设备都连接着宿主机上的docker0。那具体的实现落地实现用的是啥技术呢？

答案是：`veth pair`

veth pair的全称是：virtual ethernet，就是虚拟的以太网卡。

说到以太网卡大家都不陌生呀，不就是我们常见的那种叫eth0或者是ens的网络设备吗？

那这个veth pair是怎么玩的呢？有啥用呢？大家可以看下面这张图

![img](https://img-blog.csdnimg.cn/2021103122062798.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzQxOTczNjc3,size_16,color_FFFFFF,t_70)

veth-pair设备总是会成对的出现，用于连接两个不同network-namespace.

就上图来说，从network-namespace1的veth0中发送的数据会出现在 network-namespace2的veth1设备中。

虽然这种特性很好，但是如果出现有多个容器，你就会发现组织架构会越来越复杂，越来越乱

![img](https://img-blog.csdnimg.cn/20211031220627777.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzQxOTczNjc3,size_16,color_FFFFFF,t_70)

不过好在我们已经循序渐进的了解Linux网桥（docker0），以及这里的veth-pair设备，于是我们可以把整体的架构图重新绘制成下面这样

![img](https://img-blog.csdnimg.cn/20211031220628613.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzQxOTczNjc3,size_16,color_FFFFFF,t_70)

因为不同容器有自己隔离后的network-namespace所以他们都有自己的网络协议栈

那我们能不能找到容器里面的网卡和物理机上的哪张卡是一对网络vethpair设备呢？

如下：

```bash
Copy# 进入容器
~]# docker exec -ti 545ed62d3abf /bin/bash

/# apt-get install ethtool
/# ethtool -S eth0
NIC statistics:
     peer_ifindex: 55
```

回到宿主机

```bash
Copy~]# ip addr
	...
55: vethf0a8bcb@if54: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master docker0 state UP group default
    link/ether ae:eb:5c:2f:7d:c3 brd ff:ff:ff:ff:ff:ff link-netnsid 10
    inet6 fe80::aceb:5cff:fe2f:7dc3/64 scope link
       valid_lft forever preferred_lft forever
```

意思是就是说，容器`545ed62d3abf`的`eth0`网卡和宿主机通过`ip addr`命令查看的网络设备标号55的设备组成一对vethpair设备，彼此流量互通！

## 2.3 同一个局域网中不同主机的互联原理

先看个简单的，同一个局域网中的不同主机A、B之间是如何互联交换数据的。如下图

![img](https://img-blog.csdnimg.cn/20211031220631520.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzQxOTczNjc3,size_16,color_FFFFFF,t_70)

那，既然是同一个局域网中，说明A、B的ip地址在同一个网段，如上图就假设它们都在`192.168.1.0`网段。

还得再看下面这张OSI 7层网络模型图。

主机A向主机B发送数据，对主机A来说数据会从最上层的应用层一路往下层传递。比如应用层使用的http协议、传输层使用的TCP协议，那数据在往下层传递的过程中，会根据该层的协议添加上不同的协议头等信息。

![img](https://img-blog.csdnimg.cn/20211031220634778.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzQxOTczNjc3,size_16,color_FFFFFF,t_70)

根据OSI7层网络模型的设定，对于接受数据的主机B来说，它会接收到很多数据包！这些数据包会从最下层的物理层依次往上层传递，依次根据每一层的网络协议进行拆包。一直到应用层取出主机A发送给他的数据。

那么问题来了，主机B怎么判断它收到的数据包是否是发送给自己的呢？万一有人发错了呢？

答案是：根据MAC地址，逻辑如下。

```bash
Copyif 收到的数据包.MAC地址 == 自己的MAC地址{
  // 接收数据
  // 处理数据包
}else{
 // 丢弃
}
```

那对于主机A来说，它想发送给主机B数据包，还不能让主机B把这个数据包扔掉，它只能中规中矩的按以太网网络协议要求封装将要发送出去的数据包，往下传递到数据链路层（这一层传输的数据要求，必须要有目标mac地址，因为数据链路层是基于mac地址做数据传输的）。

那数据包中都需要哪些字段呢？如下：

```bash
Copysrc ip = 192.168.1.2  //源ip地址，交换机
dst ip = 192.168.1.3  //目标ip地址
//本机的mac地址（保证从主机B回来的包正常送达主机A，且主机A能正常处理它）
src mac = 主机A的mac地址
dst mac = 主机B的mac地址//目标mac地址
```

其中的`dst ip`好说，我们可以直接固定写，或者通过DNS解析域名得到目标ip。

那`dst mac`怎么获取呢？

这就不得不说`ARP`协议了! `ARP`其实是一种地址解析协议，它的作用就是：以目标ip为线索，找到目的ip所在机器的mac地址。也就是帮我们找到`dst mac`地址！大概的过程如下几个step

![img](https://img-blog.csdnimg.cn/20211031220636484.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzQxOTczNjc3,size_16,color_FFFFFF,t_70)

简述这个过程：主机A想给主机B发包，那需要知道主机B的mac地址。

1. 主机A查询本地的arp 高速缓存中是否已经存在`dst ip`和`dst mac`地址的映射关系了，如果已存在，那就直接用。
2. 本地arp高速缓存中不存在`dst ip`和`dst mac`地址的映射关系的话那就只能广播arp请求包，同一网段的所有机器都能收到arp请求包。
3. 收到arp请求包的机器会对比arp包中的`src ip`是否是自己的ip，如果不是则直接丢弃该arp包。如果是的话就将自己的mac地址写到arp响应包中。并且它会把请求包中`src ip`和`src mac`的映射关系存储在自己的本地。

> 补充：
>
> 交换机本身也有学习能力，他会记录mac地址和交换机端口的映射关系。比如：mac=a，端口为1。
>
> 那当它接收到数据包，并发现mac=a时，它会直接将数据扔向端口1。

嗯，在arp协议的帮助下，主机A顺利拿到了主机B的mac地址。于是数据包从网络层流转到数据链路层时已经被封装成了下面的样子：

```bash
Copysrc ip = 192.168.1.2
src mac = 主机A的mac地址
dst ip = 192.168.1.3
dst mac = 主机B的mac地址
```

> 网络层基于ip地址做数据做转发
>
> 数据链路基于mac地址做数据转发

根据OIS7层网络模型，我们都知道数据包经过物理层发送到机器B，机器B接收到数据包后，再将数据包向上流转，拆包。流转到主机B的数据链路层。

那主机B是如何判断这个在数据链路层的包是否是发给自己的呢？

答案前面说了，根据目的mac地址判断。

```bash
Copy// 主机B
if 收到的数据包.MAC地址 == 自己的MAC地址{
  if dst ip == 本机ip{
    // 本地处理数据包
  }else{
    // 查询路由表，根据路由表的规则，将数据包转某个某卡、或者默认网关
  }
}else{
 // 直接丢弃
}
```

这个例子比较简单，`dst ip`就是`主机B的本机ip` 所以它自己会处理这个数据包。

那数据包处理完之后是需要给主机A一个响应包，那问题又来了，响应包该封装成什么样子呢？对主机B来说响应包也需要`src ip`、`src mac`、`dst ip`、`dst mac`

```bash
Copysrc ip = 192.168.1.3
src mac = 主机B的mac地址
dst ip = 192.168.1.2
src mac = 主机A的mac地址 （之前通过arp记录在自己的arp高速缓存中了，所以，这次直接用）
```

同样的道理，响应包也会按照如下的逻辑被主机A接受，处理。

```bash
Copy// 主机A
if 收到的数据包.MAC地址 == 自己的MAC地址{
  if dst ip == 本机ip{
    // 本地处理数据包
  }else{
    // 查询路由表，根据路由表的规则，将数据包转某个某卡、或者默认网关
  }
}else{
 // 直接丢弃
}
```

## 2.4 容器网络互通原理

有了上面那些知识储备呢？再看我们今天要探究的问题，就不难了。

如下红字部分：同一个宿主机上的不同容器是如何互通的？

![img](https://img-blog.csdnimg.cn/20211031220637292.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzQxOTczNjc3,size_16,color_FFFFFF,t_70)

那我们先分别登陆容器记录下他们的ip

```bash
Copy9001的ip是：172.17.0.2
9002的ip是：172.17.0.3
```

先看实验效果：在9001上curl9002

```bash
Copy/# curl 172.7.88.3
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
...
```

实验结果是网络互通！

我们再完善一下上面的图，把docker0、以及两个容器的ip补充上去，如下图：

![img](https://img-blog.csdnimg.cn/20211031220638297.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzQxOTczNjc3,size_16,color_FFFFFF,t_70)

那两台机器之前要通信是要遵循OSI网络模型、和以太网协议的。

我们管`172.17.0.2`叫做容器2

我们管`172.17.0.3`叫做容器3

比如我们现在是从：容器2上curl 容器3，那么容器2也必须按照以太网协议将数据包封装好，如下

```bash
Copysrc ip = 172.17.0.2
src mac = 容器2的mac地址
dst ip = 172.17.0.3
dst mac = 容器3的mac地址 ？？？
```

那现在的问题是容器3的mac地址是多少？

> 删掉所有容器，重新启动，方便实验抓包

容器2会先查自己的本地缓存，如果之前没有访问过，那么缓存中也没有任何记录！

```bash
Copy:/# arp -n
```

不过没关系，还有arp机制兜底，于是容器2会发送arp请求包，大概如下

```bash
Copy1、这是一个arp请求包
2、我的ip地址是：172.17.0.2
3、我的mac地址是：容器2的mac地址
4、请问：ip地址为：172.17.0.3的机器，你的mac地址是多少？
```

容器2会查询自己的路由表，将这个arp请求从自己的gateway发送出去

```bash
Copy/# route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         172.7.88.1      0.0.0.0         UG    0      0        0 eth0
172.7.88.0      0.0.0.0         255.255.255.0   U     0      0        0 eth0
```

我们发现容器2的网关对应的网络设备的ip就是docker0的ip地址，并且经由eth0发送出去！

哎？eth0不就是我们之前说的veth-pair设备吗？

并且我们通过下面的命令可以知道它的另一端对应着宿主机上的哪个网络设备：

```bash
Copy/# ethtool -S eth0
NIC statistics:
     peer_ifindex: 53
```

**而且我们可以下面的小实验，验证上面的观点是否正确**

```bash
Copy# 在容器中ping百度
~]# ping 220.181.38.148

# 在宿主机上抓包
~]# yum install tcpdump -y
~]# tcpdump -i ${vethpair宿主机侧的接口名} host 220.181.38.148

...
```

所以说从容器2的eth0出去的arp请求报文会同等的出现在宿主机的第53个网络设备上。

通过下面的这张图，你也知道第53个网络设备其实就是下图中的veth0-1

![img](https://img-blog.csdnimg.cn/20211031220639530.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzQxOTczNjc3,size_16,color_FFFFFF,t_70)

所以这个arp请求包会被发送到docker0上，由docker0拿到这个arp包发现，目标ip是`172.17.0.3`并不是自己，所以docker0会进一步将这个arp请求报文广播出去，所有在`172.17.0.0`网段的容器都能收到这个报文！其中就包含了容器3！

那容器3收到这个arp报文后，会判断，哦！目标ip就是自己的ip，于是它将自己的mac地址填充到arp报文中返回给docker0！

同样的我们可以通过抓包验证，在宿主机上

```bash
Copy# 在172.17.0.2容器上ping172.17.0.3
/# ping 172.17.0.3

~]# tcpdump -i vethdb0d222
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on vethdb0d222, link-type EN10MB (Ethernet), capture size 262144 bytes

17:25:30.218640 ARP, Request who-has 172.17.0.3 tell 172.17.0.2, length 28
17:25:30.218683 ARP, Reply 172.17.0.3 is-at 02:42:ac:11:00:03 (oui Unknown), length 28
17:25:30.218686 IP 172.17.0.2.54014 > 172.17.0.3.http: Flags [S], seq 3496600258, win 29200, options [mss 1460,sackOK,TS val 4503202 ecr 0,nop,wscale 7], length 0
```

于是容器2就拿到了容器3的mac地址，以太网数据包需要的信息也就齐全了！如下：

```bash
Copysrc ip = 172.17.0.2
src mac = 容器2的mac地址
dst ip = 172.17.0.3
dst mac = 容器3的mac地址
```

再之后容器2就可以和容器3正常互联了！

容器3会收到很多数据包，那它怎么知道哪些包是发给自己的，那些不是呢？可以参考如下的判断逻辑

```bash
Copyif 响应包.mac == 自己的mac{
 // 说明这是发给自己包，所以不能丢弃
  if 响应包.ip == 自己的ip{
    // 向上转发到osi7层网络模型的上层
  }else{
    // 查自己的route表，找下一跳
  }
}else{
 // 直接丢弃
}
```

## 2.5 实验环境

```bash
Copy# 下载
 ~]# docker pull registry.cn-hangzhou.aliyuncs.com/changwu/nginx:1.7.9-nettools
 
# 先启动1个容器
 ~]# docker run --name mynginx1 -i -t -d -p 9001:80 nginx-1.7.9-nettools:latest
eb569b938c07e95ccccbfc654c1fee6364eea55b20f5394382ff42b4ccf96312

~]# docker run --name mynginx2 -i -t -d -p 9002:80 nginx-1.7.9-nettools:latest
545ed62d3abfd63aa9c3ae196e9d7fe6f59bbd2e9ae4e6f2bd378f23587496b7

# 验证
~]# curl 127.0.0.1:9001
```

# 三、推荐阅读

[1、白日梦的Docker网络入门笔记](https://mp.weixin.qq.com/s/W8TIdjs3RrqFA92X79yyKw)

[2、这一次，让我在百度告诉你，当你请求www.baidu.com时都发生了什么？](https://mp.weixin.qq.com/s/YiC-WHmn-DQwUzGsN3TXrg)

[3、白日梦的网络笔记：iptables、防火墙](https://mp.weixin.qq.com/s/bwK_ECwmL6OAjKHkiqGNpA)

[4、白日梦的DNS笔记](https://mp.weixin.qq.com/s/Pe4OOSoiqIx0I3OfKznFzA)
