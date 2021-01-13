[TOC]

# 一、Docker是干什么的？
docker 是一个开源的应用容器引擎（基于Go语言开发），让开发者可以打包他们的应用以及依赖包到一个可移植的容器中，然后发布到任何流行的Linux机器上，也可以实现虚拟化，容器是完全使用沙箱机制，相互之间不会有任何接口。简言之，就是可以在Linux上镜像使用的这么一个容器。

Docker可以在容器内部快速自动化部署应用，并可以通过内核虚拟化技术（namespaces及cgroups等）来提供容器的资源隔离与安全保障等。

Docker的思想来自于集装箱，集装箱解决了什么问题？在一艘大船上，可以把货物规整的摆放起来。并且各种各样的货物被集装箱标准化了，集装箱和集装箱之间不会互相影响。那么我就不需要专门运送水果的船和专门运送化学品的船了。只要这些货物在集装箱里封装的好好的，那我就可以用一艘大船把他们都运走。

1. 不同的应用程序可能会有不同的应用环境，比如.net开发的网站和php开发的网站依赖的软件就不一样，如果把他们依赖的软件都安装在一个服务器上就要调试很久，而且很麻烦，还会造成一些冲突。比如IIS和Apache访问端口冲突。这个时候你就要隔离.net开发的网站和php开发的网站。常规来讲，我们可以在服务器上创建不同的虚拟机在不同的虚拟机上放置不同的应用，但是虚拟机开销比较高。docker可以实现虚拟机隔离应用环境的功能，并且开销比虚拟机小。

当你需要在容器内运行自己的应用（当然可以是任何应用），Docker 都提供了一个基础系统镜像作为运行应用时的基础系统。也就是说，只要是 Linux 系统上的应用都可以运行在 Docker 中。

可以在 Docker 里面运行数据库吗？当然可以。
可以在 Docker 里面运行 Node.js 网站服务器吗？当然可以。
可以在 Docker 里面运行 API 服务器吗？当然可以。

Docker 并不在乎你的应用程序是什么、做什么，Docker 提供了一组应用打包、传输和部署的方法，以便你能更好地在容器内运行任何应用。



## 1.1 **容器**

容器=cgroup+namespace+rootfs+容器引擎（用户态工具）

- Cgroup：资源控制。
- Namespace：访问隔离。
- rootfs：文件系统隔离。
- 容器引擎：生命周期控制。



## 1.2 **容器两个核心技术**

**NameSpace**
Namespace又称为命名空间（也可翻译为名字空间），它是将内核的全局资源做封装，使得每个Namespace都有一份独立的资源，因此不同的进程在各自的Namespace内对同一种资源的使用不会互相干扰。

- IPC：隔离System V IPC和POSIX消息队列。
- Network：隔离网络资源。
- Mount：隔离文件系统挂载点。
- PID：隔离进程ID。
- UTS：隔离主机名和域名。
- User：隔离用户ID和组ID。



**Cgroup**
Cgroup是control group的简写，属于Linux内核提供的一个特性，用于限制和隔离一组进程对系统资源的使用，也就是做资源QoS，这些资源主要包括CPU、内存、block I/O和网络带宽。

- devices：设备权限控制。
- cpuset：分配指定的CPU和内存节点。
- cpu：控制CPU占用率。
- cpuacct：统计CPU使用情况。
- memory：限制内存的使用上限。
- freezer：冻结（暂停）Cgroup中的进程。
- net_cls：配合tc（traffic controller）限制网络带宽。
- net_prio：设置进程的网络流量优先级。
- huge_tlb：限制HugeTLB的使用。
- perf_event：允许Perf工具基于Cgroup分组做性能监测。




# 二、Docker的核心：镜像、容器、仓库
镜像是一个可执行包，包含运行应用程序所需的所有内容——代码、运行时、库、环境变量和配置文件。

**容器：**

- 容器是通过运行镜像启动容器，是镜像的运行时实例。镜像实际上就是一个容器的模板，通过这个模板可以创建很多相同的容器。
- 容器就是一个认为只有其本身在运行状态的linux程序，只服从用户指定的命令。（容器程序有自己的IP地址；一个可访问网络的独立设备）



通过Java去类比理解Docker的一些概念：
![](https://img-blog.csdnimg.cn/20200128042708714.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L0V2YW5fTGV1bmc=,size_16,color_FFFFFF,t_70)

- Class文件 - 相当于Docker镜像，定义了类的一些所需要的信息
- 对象 - 相当于容器，通过Class文件创建出来的实例
- JVM - 相当于Docker引擎，可以让Docker容器屏蔽底层复杂逻辑，实现跨平台操作

## 2.1 容器与虚拟机的区别
**容器在Linux上本地运行，并与其他容器共享主机的内核。它运行一个独立的进程，不占用比其他任何可执行程序更多的内存，使其轻量级。**

虚拟机(VM) 运行一个成熟的“游客”操作系统，通过虚拟机监控程序对主机资源进行虚拟访问。通常，vm提供的资源比大多数应用程序所需的要多。
![](https://img-blog.csdnimg.cn/20200128042721539.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L0V2YW5fTGV1bmc=,size_16,color_FFFFFF,t_70)

总的来说，容器不需要依赖操作系统，减少了很多系统资源开销，使得容器可以更关注应用的需求，而虚拟机可以为每个应用灵活提供不同的操作系统。

## 2.2 仓库
存放镜像的地方，和git类似。

![](https://img-blog.csdnimg.cn/20190131193142244.png)

简单来说就是，不同的应用程序所依赖的环境不一样，如果把他们依赖的软件都安装在一个服务器上，不仅需要调试很久，而且可能会有冲突。
如果想把两个应用程序隔离起来，可以在服务器上创建不同的虚拟机，不同的虚拟机放不同的应用，但是虚拟机的开销比较高。docker作为轻量级的虚拟机，是一个很好的工具。

![](https://img-blog.csdnimg.cn/20190131155147837.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FzYmJs,size_16,color_FFFFFF,t_70)

# 三、Docker的五种网络

**None**
不为容器配置任何网络功能。

**Container**
与另一个运行中的容器共享NetworkNamespace，共享相同的网络视图。

**Host**
与主机共享Root Network Namespace，容器有完整的权限可以操纵主机的协议栈、路由表和防火墙等，所以被认为是不安全的。

**Bridge**
Docker设计的NAT网络模型。
Docker网络的初始化动作包括：创建docker0网桥、为docker0网桥新建子网及路由、创建相应的iptables规则等。
![Docker关键知识点儿汇总](https://minminmsn.com/images/docker/bridge.jpg)
在桥接模式下，Docker容器与Internet的通信，以及不同容器之间的通信，都是通过iptables规则控制的。
**Overlay**
Docker原生的跨主机多子网模型。
overlay网络模型比较复杂，底层需要类似consul或etcd的KV存储系统进行消息同步，核心是通过Linux网桥与vxlan隧道实现跨主机划分子网。
![Docker关键知识点儿汇总](https://minminmsn.com/images/docker/overlay.jpg)



# 四、Docker的使用

[Docker及其使用思维导图](https://blog.csdn.net/An1090239782/article/details/85127030)