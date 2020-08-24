[TOC]

Nignx是一种集中式的负载均衡器。
何为集中式呢？简单理解就是将所有请求都集中起来，然后再进行负载均衡。如下图。
![](https://segmentfault.com/img/remote/1460000022470035)

Nginx是接收了所有的请求进行负载均衡的，而对于Ribbon来说它是在消费者端进行的负载均衡。如下图。
![](https://segmentfault.com/img/remote/1460000022470036)

> 请注意Request的位置，在Nginx中请求是先进入负载均衡器，而在Ribbon中是先在客户端进行负载均衡才进行请求的。