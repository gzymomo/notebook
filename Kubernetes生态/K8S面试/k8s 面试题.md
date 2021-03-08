一个目标：[容器](http://mp.weixin.qq.com/s?__biz=MzI0MDQ4MTM5NQ==&mid=2247499520&idx=2&sn=2e4079c35f786fc29dd3971802cfd531&chksm=e9189a1cde6f130a3cb23b15e7e66ee0fe9af838f4bfe60096141b9db75c23c870e3c9e3885d&scene=21#wechat_redirect)操作；两地三中心；四层服务发现；五种 Pod 共享资源；六个 CNI 常用插件；七层负载均衡；八种隔离维度；九个网络模型原则；十类 IP 地址；百级产品线；千级物理机；万级容器；相如无亿，[k8s ](http://mp.weixin.qq.com/s?__biz=MzI0MDQ4MTM5NQ==&mid=2247502359&idx=1&sn=8c16100c9731359b9864403183f44233&chksm=e918af0bde6f261da9f4960c0ed43e1552eeed9ff3ad0ba06bcfef75e3ba9e9d097e1c87a51c&scene=21#wechat_redirect)有亿：亿级日服务人次。

## 一个目标：容器操作

Kubernetes（k8s）是自动化容器操作的开源平台。这些容器操作包括：部署、调度和节点集群间扩展。

###### 具体功能：

- 自动化容器部署和复制。
- 实时弹性收缩容器规模。
- 容器编排成组，并提供容器间的负载均衡。
- 调度：容器在哪个机器上运行。

###### 组成：

- kubectl：客户端命令行工具，作为整个系统的操作入口。
- kube-apiserver：以 REST API 服务形式提供接口，作为整个系统的控制入口。
- kube-controller-manager：执行整个系统的后台任务，包括节点状态状况、Pod 个数、Pods 和Service 的关联等。
- kube-scheduler：负责节点资源管理，接收来自 kube-apiserver 创建 Pods 任务，并分配到某个节点。
- etcd：负责节点间的服务发现和配置共享。
- kube-proxy：运行在每个计算节点上，负责 Pod 网络代理。定时从 etcd 获取到 service 信息来做相应的策略。
- kubelet：运行在每个计算节点上，作为 agent，接收分配该节点的 Pods 任务及管理容器，周期性获取容器状态，反馈给 kube-apiserver。
- DNS：一个可选的 DNS 服务，用于为每个 Service 对象创建 DNS 记录，这样所有的 Pod 就可以通过 DNS 访问服务了。

下面是 [k8s ](http://mp.weixin.qq.com/s?__biz=MzI0MDQ4MTM5NQ==&mid=2247499493&idx=3&sn=4453fb452640045f0b7a2b020a4de61a&chksm=e9189bf9de6f12ef78a70fd575f1e76b377fd454539e94b9e869270a99fb08f48278154be2fa&scene=21#wechat_redirect)的架构拓扑图：

![图片](https://mmbiz.qpic.cn/mmbiz_jpg/tuSaKc6SfPrKlbeTibSGltnocHLVyyUKMzT5GicReNHLbod9BDe1m0ZibMPocHCm9zewhvra5Qjsv5IxgJPpwo28g/640?wx_fmt=jpeg&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

## 两地三中心 

两地三中心包括本地生产中心、本地灾备中心、异地灾备中心。

![图片](data:image/gif;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQImWNgYGBgAAAABQABh6FO1AAAAABJRU5ErkJggg==)

两地三中心要解决的一个重要问题就是数据一致性问题。

k8s 使用 [etcd](http://mp.weixin.qq.com/s?__biz=MzI0MDQ4MTM5NQ==&mid=2247495317&idx=2&sn=abcc140a4d9997051891d659098e3724&chksm=e9188b89de6f029f2fdb912823ce9682318a4464135ade79b12d3c927fae4d3d21367a24817d&scene=21#wechat_redirect) 组件作为一个高可用、强一致性的服务发现存储仓库。用于配置共享和服务发现。

它作为一个受到 [Zookeeper](http://mp.weixin.qq.com/s?__biz=MzI0MDQ4MTM5NQ==&mid=2247505631&idx=2&sn=11159cc9e0142f3faafb35678540eaab&chksm=e918b3c3de6f3ad57f2b4a08bb7028c479b1ca3c02422bcd545f6e8818a1448c387cd6314165&scene=21#wechat_redirect) 和 doozer 启发而催生的项目。除了拥有他们的所有功能之外，还拥有以下 4 个特点：

- 简单：基于 HTTP+JSON 的 API 让你用 curl 命令就可以轻松使用。
- 安全：可选 SSL 客户认证机制。
- 快速：每个实例每秒支持一千次写操作。
- 可信：使用 Raft 算法充分实现了分布式。

## 四层服务发现

先一张图解释一下[网络七层](http://mp.weixin.qq.com/s?__biz=MzI0MDQ4MTM5NQ==&mid=2247505452&idx=2&sn=0f50c8087960b13c0b7762a6611c3a96&chksm=e918b330de6f3a26e46d7bb8e96b8da7b0daf1c2761cac76117118406ee8a82aa8e2d8fbbbd1&scene=21#wechat_redirect)协议：

![图片](data:image/gif;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQImWNgYGBgAAAABQABh6FO1AAAAABJRU5ErkJggg==)

k8s 提供了两种方式进行服务发现：

- 环境变量：当创建一个 Pod 的时候，kubelet 会在该 Pod 中注入集群内所有 Service 的相关环境变量。需要注意的是，要想一个 Pod 中注入某个  Service 的环境变量，则必须 Service 要先比该 Pod 创建。这一点，几乎使得这种方式进行服务发现不可用。 比如，一个 ServiceName 为 redis-master 的 Service，对应的 ClusterIP:Port 为  10.0.0.11:6379，则对应的环境变量为：

![图片](data:image/gif;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQImWNgYGBgAAAABQABh6FO1AAAAABJRU5ErkJggg==)

- DNS：可以通过 cluster add-on 的方式轻松的创建 KubeDNS 来对集群内的 Service 进行服务发现。

以上两种方式，一个是基于 TCP，DNS 基于 UDP，它们都是建立在四层协议之上。

## 五种 Pod 共享资源

Pod 是 k8s 最基本的操作单元，包含一个或多个紧密相关的容器。

一个 Pod 可以被一个容器化的环境看作应用层的“逻辑宿主机”；一个 Pod 中的多个容器应用通常是紧密耦合的，Pod 在 Node  上被创建、启动或者销毁；每个 Pod 里运行着一个特殊的被称之为 Volume  挂载卷，因此他们之间通信和数据交换更为高效。在设计时我们可以充分利用这一特性将一组密切相关的服务进程放入同一个 Pod 中。

![图片](data:image/gif;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQImWNgYGBgAAAABQABh6FO1AAAAABJRU5ErkJggg==)

同一个 Pod 里的[容器](http://mp.weixin.qq.com/s?__biz=MzI0MDQ4MTM5NQ==&mid=2247500702&idx=2&sn=0fb77cd1830fe7f637bb6e4f3da2b13b&chksm=e918a682de6f2f9417f49d9d64253e12d38822df6f28458b502c2be8eddb5177d5b76153cdac&scene=21#wechat_redirect)之间仅需通过 localhost 就能互相通信。

一个 Pod 中的应用容器共享五种资源：

- PID 命名空间：Pod 中的不同应用程序可以看到其他应用程序的进程 ID。
- 网络命名空间：Pod 中的多个容器能够访问同一个IP和端口范围。
- IPC 命名空间：Pod 中的多个容器能够使用 SystemV IPC 或 POSIX 消息队列进行通信。
- UTS 命名空间：Pod 中的多个容器共享一个主机名。
- Volumes（共享存储卷）：Pod 中的各个容器可以访问在 Pod 级别定义的 Volumes。

Pod 的生命周期通过 Replication Controller 来管理；通过模板进行定义，然后分配到一个 Node 上运行，在 Pod 所包含容器运行结束后，Pod 结束。

Kubernetes 为 Pod 设计了一套独特的网络配置，包括为每个 Pod 分配一个IP地址，使用 Pod 名作为容器间通信的主机名等。

## 六个 CNI 常用插件

CNI（Container Network Interface）容器网络接口是 Linux  容器网络配置的一组标准和库，用户需要根据这些标准和库来开发自己的容器网络插件。CNI  只专注解决容器网络连接和容器销毁时的资源释放，提供一套框架。所以 CNI 可以支持大量不同的网络模式，并且容易实现。

下面用一张图表示六个 CNI 常用插件：

![图片](data:image/gif;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQImWNgYGBgAAAABQABh6FO1AAAAABJRU5ErkJggg==)

## 七层负载均衡 

提负载均衡就不得不先提服务器之间的通信。

IDC（Internet Data Center）也可称数据中心、机房，用来放置服务器。IDC 网络是服务器间通信的桥梁。

![图片](data:image/gif;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQImWNgYGBgAAAABQABh6FO1AAAAABJRU5ErkJggg==)

上图里画了很多网络设备，它们都是干啥用的呢？

路由器、交换机、MGW/NAT 都是网络设备，按照性能、内外网划分不同的角色。

- 内网接入交换机：也称为 TOR（top of rack），是服务器接入网络的设备。每台内网接入交换机下联 40-48 台服务器，使用一个掩码为 /24 的网段作为服务器内网网段。
- 内网核心交换机：负责 IDC 内各内网接入交换机的流量转发及跨 IDC 流量转发。
- MGW/NAT：MGW 即 LVS 用来做负载均衡，NAT 用于内网设备访问外网时做地址转换。
- 外网核心路由器：通过静态互联运营商或 BGP 互联美团统一外网平台。

先说说各层负载均衡：

- 二层负载均衡：基于 MAC 地址的二层负载均衡。
- 三层负载均衡：基于 IP 地址的负载均衡。
- 四层负载均衡：基于 IP+端口 的负载均衡。
- 七层负载均衡：基于 URL 等应用层信息的负载均衡。

这里用一张图来说说四层和七层负载均衡的区别：

![图片](data:image/gif;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQImWNgYGBgAAAABQABh6FO1AAAAABJRU5ErkJggg==)

上面四层服务发现讲的主要是 k8s 原生的 kube-proxy 方式。k8s 关于服务的暴露主要是通过 NodePort 方式，通过绑定 minion 主机的某个端口，然后进行 Pod 的请求转发和负载均衡，但这种方式有下面的缺陷：

- Service 可能有很多个，如果每个都绑定一个 Node 主机端口的话，主机需要开放外围的端口进行服务调用，管理混乱。
- 无法应用很多公司要求的防火墙规则。

理想的方式是通过一个外部的负载均衡器，绑定固定的端口，比如 80；然后根据域名或者服务名向后面的 Service IP 转发。

Nginx 很好的解决了这个需求，但问题是如果有的新的服务加入，如何去修改并且加载这些 [Nginx 配置](http://mp.weixin.qq.com/s?__biz=MzI0MDQ4MTM5NQ==&mid=2247495416&idx=1&sn=bada1264baa5cc387cc2790fb87d5fc3&chksm=e9188be4de6f02f2a79586c60d1071132b8b70a83ab268808cb08139efc21b142790195383f5&scene=21#wechat_redirect)？

[Kubernetes](http://mp.weixin.qq.com/s?__biz=MzI0MDQ4MTM5NQ==&mid=2247507390&idx=2&sn=5887ec3021ce80e44a4c62e2253560a8&chksm=e918b8a2de6f31b45a71be736919c2a99f4ed2f77b48c10c7482bada97198f9a35682962e683&scene=21#wechat_redirect) 给出的方案就是 Ingress。这是一个基于七层的方案。

## 八种隔离维度

![图片](data:image/gif;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQImWNgYGBgAAAABQABh6FO1AAAAABJRU5ErkJggg==)

k8s 集群调度这边需要对上面从上到下、从粗粒度到细粒度的隔离做相应的调度策略。

## 九个网络模型原则

k8s 网络模型要符合四个基础原则、三个网络要求原则、一个架构原则、一个 IP 原则。

每个 Pod 都拥有一个独立的 IP 地址，而且假定所有 Pod 都在一个可以直接连通的、扁平的网络空间中，不管是否运行在同一 Node 上都可以通过 Pod 的 IP 来访问。

k8s 中的 Pod 的 IP 是最小粒度 IP。同一个 Pod 内所有的容器共享一个网络堆栈，该模型称为 IP-per-Pod 模型。

- Pod 由 docker0 实际分配的 IP。
- Pod 内部看到的 IP 地址和端口与外部保持一致。
- 同一个 Pod 内的不同容器共享网络，可以通过localhost来访问对方的端口，类似同一个虚拟机内不同的进程。

IP-per-Pod 模型从端口分配、域名解析、服务发现、负载均衡、应用配置等角度看，Pod 可以看做是一台独立的虚拟机或物理机。

- 所有容器都可以不用 NAT 的方式同别的容器通信。
- 所有节点都可以在不同 NAT 方式下同所有容器通信，反之亦然。
- 容器的地址和别人看到的地址是同一个地址。

要符合下面的架构：

![图片](https://mmbiz.qpic.cn/mmbiz_jpg/tuSaKc6SfPrKlbeTibSGltnocHLVyyUKMPwb6NL68n5lR1wic4d7GtfIyiajhp3Ubm9LnibfnK14KwlI6cYXk4Epicg/640?wx_fmt=jpeg&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

由上图架构引申出来 IP 概念从集群外部到集群内部：

![图片](https://mmbiz.qpic.cn/mmbiz_jpg/tuSaKc6SfPrKlbeTibSGltnocHLVyyUKMrwcAOqxjZAOfHeWicClbO0XXrK1QmMSDa6yiaU5OxxeTkBic43EM5UVEg/640?wx_fmt=jpeg&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

## 十类IP地址 

大家都知道 IP 地址分为 ABCDE 类，另外还有五类特殊用途的 IP。

第一类

```
A 类：1.0.0.0-1226.255.255.255，默认子网掩码/8，即255.0.0.0。
B 类：128.0.0.0-191.255.255.255，默认子网掩码/16，即255.255.0.0。
C 类：192.0.0.0-223.255.255.255，默认子网掩码/24，即255.255.255.0。
D 类：224.0.0.0-239.255.255.255，一般用于组播。
E 类：240.0.0.0-255.255.255.255(其中255.255.255.255为全网广播地址)。E 类地址一般用于研究用途。
```

第二类

```
0.0.0.0
严格来说，0.0.0.0 已经不是一个真正意义上的 IP 地址了。它表示的是这样一个集合：所有不清楚的主机和目的网络。这里的不清楚是指在本机的路由表里没有特定条目指明如何到达。作为缺省路由。
127.0.0.1 本机地址。
```

第三类

```
224.0.0.1 组播地址。
如果你的主机开启了IRDP（internet路由发现，使用组播功能），那么你的主机路由表中应该有这样一条路由。
```

第四类

```
169.254.x.x
使用了 DHCP 功能自动获取了 IP 的主机，DHCP 服务器发生故障，或响应时间太长而超出了一个系统规定的时间，系统会为你分配这样一个 IP，代表网络不能正常运行。
```

第五类

```
10.xxx、172.16.x.x~172.31.x.x、192.168.x.x 私有地址。
大量用于企业内部。保留这样的地址是为了避免亦或是哪个接入公网时引起地址混乱。
```