- [Prometheus的高可用方案](https://www.jianshu.com/p/bccfc58bcbcd)

## 一、现实可用的小规模高可用方案

  关于Prometheus的高可用，官方文档中只提供了一个解决方案，具体实现方式如下：

![img](https:////upload-images.jianshu.io/upload_images/23600246-b6f50a3b30f2adf6.png?imageMogr2/auto-orient/strip|imageView2/2/w/554)

  使用两个Prometheus主机监控同样的目标，然后有告警出现，也会发送同样的告警给Alertmanager，然后使用Alertmanager自身的去重告警功能，只发出一条告警出来。从而实现了prometheus高可用的一个架构。
  基于此架构，我们还可以使用keepalived做双机热备，通过VIP与grafana相连。实现一个完整的带web界面展示告警的高可用Prometheus监控架构。

![img](https:////upload-images.jianshu.io/upload_images/23600246-319cd575d7d08e8d.png?imageMogr2/auto-orient/strip|imageView2/2/w/557)

  根据查找的资料，可知Prometheus的监控数量和Prometheus主机的内存和磁盘大小的关系表。

![img](https:////upload-images.jianshu.io/upload_images/23600246-e66a18eec17da500.png?imageMogr2/auto-orient/strip|imageView2/2/w/554)



![img](https:////upload-images.jianshu.io/upload_images/23600246-de2b4ea7b7e33a3e.png?imageMogr2/auto-orient/strip|imageView2/2/w/554)

  根据表格中数据，我们可以用两台8G内存，磁盘大小为100G的Prometheus主机做主备架构，进行500个节点以下的基础架构的监控，然后由于抓取间隔和数据留存时间的设定是直接关乎内存和磁盘空间的使用率，所以我们可以通过调整这两点，来调整内存和磁盘空间到合适的值。

## 二、大规模监控的高可用方案

  根据官方文档，Prometheus有一个面向于大规模目标监控的功能**FEDERATION**联邦机制，是指从其它Prometheus主机上抓取特定的数据到一个汇总的Prometheus主机中，既然是从其它Prometheus主机汇总而来，那么数据量会很大，难以长久储存在主机本地，所以我们需要使用Prometheus的远程读写数据库的功能，来远程保存至第三方数据库。
  而这个用于汇总的Prometheus主机，我们也使用主备两台主机做高可用处理，不过与第三方数据库之间需要用一个adapter工具，来做主备数据库传输切换。如下图所示。

![img](https:////upload-images.jianshu.io/upload_images/23600246-43dd9a668657b5da.png?imageMogr2/auto-orient/strip|imageView2/2/w/554)


  在这里第三方存储是使用的PostgreSQL + TimescaleDB，而adapter是用的官方开发的Prometheus-postgresql-adpter自带leader切换的功能，当设置好Prometheus和adapter后，如果adapter长时间没有收到对应的Prometheus的数据，那么它会自动锁定然后切换到备用adapter，备用adpter会将自己所对应的Prometheus主机的数据发往第三方存储。
  也就是说，这两台Prometheus主机都是会实时接收其它相同Prometheus主机的数据，然后只有其中一方的数据会被标识为leader的adapter发送到第三方存储中。完整架构图如下。

![img](https:////upload-images.jianshu.io/upload_images/23600246-400c6c7f09244186.png?imageMogr2/auto-orient/strip|imageView2/2/w/546)

## 三、总结

  不管是第一章的小规模监控高可用方案还是第二章的大规模监控高可以方案，主要应用的还是Prometheus官方文档提到高可用方法和Prometheus的联邦机制机远程读写存储的功能。而主备切换的工具keepalive和Prometheus-postgresql-adpter，以及远程数据库PostgreSQL+TimescaleDB，这些都可以替换成Nginx proxy、服务注册工具consul，远程存储Thanos，我们可以根据实际需求做测试，再决定使用哪些第三方工具。