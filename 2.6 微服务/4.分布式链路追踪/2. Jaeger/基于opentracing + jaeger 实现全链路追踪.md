- [基于opentracing + jaeger 实现全链路追踪](https://www.jianshu.com/p/fbedfcdea606)
- [Jaeger开发入门(java版)](https://www.cnblogs.com/bolingcavalry/p/15700712.html)
- [Java应用日志如何与Jaeger的trace关联](https://www.cnblogs.com/bolingcavalry/p/15709398.html)

## 链路追踪

当代互联网服务，通常都是用复杂，大规模分布式集群来实现，微服务化，这些软件模块分布在不同的机器，不同的数据中心，由不同团队，语言开发而成。因此，需要工具帮助理解，分析这些系统、定位问题，做到追踪每一个请求的完整调用链路，收集性能数据，反馈到服务治理中，链路追踪系统应运而生。

现有大部分 APM(**Application Performance Management**) 理论模型大多借鉴 [google dapper](https://links.jianshu.com/go?to=https%3A%2F%2Fstorage.googleapis.com%2Fpub-tools-public-publication-data%2Fpdf%2F36356.pdf) 论文，Twitter的zipkin，Uber的 jaeger，淘宝的鹰眼，大众的cat，京东的Hydra等。

微服务问题：

1. 故障定位难
2. 链路梳理难
3. 容量预估难

举个例子，一个场景下，一个请求进来，入口服务是 serviceA， serviceA 接到请求后访问数据库读取用户数据，然后向 serviceB 发起 rpc，serviceB 收到 rpc 请求时同时向后端服务 serviceC 和 serviceD 发起请求，等待请求回复后再返回 serviceA 的 rpc 调用。如果我们发现发起的请求失败，或者请求的时延很大，我们该如何去定位呢？

基于这个需求，我们将服务介入追踪系统。

分布式追踪系统发展很快，种类繁多，但核心步骤一般有三个：**代码埋点，数据存储、查询展示**

在数据采集过程，需要侵入用户代码做埋点，不同系统的API不兼容会导致切换追踪系统需要做很大的改动。为了解决这个问题，诞生了[**opentracing**](https://links.jianshu.com/go?to=https%3A%2F%2Fopentracing.io%2F) 规范。

```json
   +-------------+  +---------+  +----------+  +------------+
   | Application |  | Library |  |   OSS    |  |  RPC/IPC   |
   |    Code     |  |  Code   |  | Services |  | Frameworks |
   +-------------+  +---------+  +----------+  +------------+
          |              |             |             |
          |              |             |             |
          v              v             v             v
     +-----------------------------------------------------+
     | · · · · · · · · · · OpenTracing · · · · · · · · · · |
     +-----------------------------------------------------+
       |               |                |               |
       |               |                |               |
       v               v                v               v
 +-----------+  +-------------+  +-------------+  +-----------+
 |  Tracing  |  |   Logging   |  |   Metrics   |  |  Tracing  |
 | System A  |  | Framework B |  | Framework C |  | System D  |
 +-----------+  +-------------+  +-------------+  +-----------+
```

## OpenTracing

[opentracing](https://links.jianshu.com/go?to=https%3A%2F%2Fopentracing.io%2Fspecification%2F) ([中文](https://links.jianshu.com/go?to=https%3A%2F%2Fwu-sheng.gitbooks.io%2Fopentracing-io%2Fcontent%2Fpages%2Finstrumentation%2Fcommon-use-cases.html))是一套分布式追踪协议，与平台，语言无关，统一接口，方便开发接入不同的分布式追踪系统。

- [语义规范](https://links.jianshu.com/go?to=https%3A%2F%2Fsegmentfault.com%2Fa%2F1190000008895129) : 描述定义的数据模型 Tracer，Sapn 和 SpanContext 等；
- [语义惯例](https://links.jianshu.com/go?to=https%3A%2F%2Fopentracing-contrib.github.io%2Fopentracing-specification-zh%2Fsemantic_conventions.html) : 罗列出 tag 和 logging 操作时，标准的key值；

### Trace 和 sapn

opentracing 中的 Trace（调用链）通过归属此链的 Span 来隐性定义。一条 Trace 可以认为一个有多个 Span 组成的有向无环图（DAG图），Span 是一个逻辑执行单元，Span 与 Span 的因果关系命名为 References。

opentracing 定义两种关系：

- Childof：如下例子中， SpanC 是 childof SpanA
- FollowsFrom：如下例子中，SpanG 是 followsFrom SpanF

例子 Trace 包含 8个 Span，

```json
 [Span A]  ←←←(the root span)
            |
     +------+------+
     |             |
 [Span B]      [Span C] ←←←(Span C is a `ChildOf` Span A)
     |             |
 [Span D]      +---+-------+
               |           |
           [Span E]    [Span F] >>> [Span G] >>> [Span H]
                                       ↑
                                       ↑
                                       ↑
                         (Span G `FollowsFrom` Span F)
```

通过时间轴显示一个 Tracer 更加直观，

```json
––|–––––––|–––––––|–––––––|–––––––|–––––––|–––––––|–––––––|–> time

 [Span A···················································]
   [Span B··············································]
      [Span D··········································]
    [Span C········································]
         [Span E·······]        [Span F··] [Span G··] [Span H··]
```

每个**Span**封装了如下状态:

- 操作名称
- 开始时间戳
- 结束时间戳
- 一组零或多个键:值结构的 **Span标签** (Tags)。键必须是字符串。值可以是字符串，布尔或数值类型.
- 一组零或多个 **Span日志** (Logs)，其中每个都是一个键:值映射并与一个时间戳配对。键必须是字符串，值可以是任何类型。 并非所有的 OpenTracing 实现都必须支持每种值类型。
- 一个 **SpanContext** (见下文)
- 零或多个因果相关的 **Span** 间的 **References**  (通过那些相关的 **Span** 的 **SpanContext** )

每个 **SpanContext** 封装了如下状态:

- 任何需要跟跨进程 **Span** 关联的，依赖于 OpenTracing 实现的状态(例如 Trace 和 Span 的 id)
- 键:值结构的跨进程的 **Baggage Items**（区别于 span tag，baggage 是全局范围，在 span 间保持传递，而tag 是 span 内部，不会被子 span 继承使用。）

### **Inject** 和 **Extract** 操作

跨进程，机器通讯，通过传递 Spancontext 来提供足够的信息建立 span 间的关系。SpanContext 通过 **Inject** 操作向 **Carrier** 中增加，传递后通过 **Extracted** 从 **Carrier** 中取出。

[关于inject 和 extract](https://links.jianshu.com/go?to=https%3A%2F%2Fwu-sheng.gitbooks.io%2Fopentracing-io%2Fcontent%2Fpages%2Fapi%2Fcross-process-tracing.html)

### **Sampling**,采样

OpenTracing API 不强调采样的概念，但是大多数追踪系统通过不同方式实现采样。有些情况下，应用系统需要通知追踪程序，这条特定的调用需要被记录，即使根据默认采样规则，它不需要被记录。sampling.priority tag 提供这样的方式。追踪系统不保证一定采纳这个参数，但是会尽可能的保留这条调用。
 sampling.priority - integer

- 如果大于 0, 追踪系统尽可能保存这条调用链
- 等于 0, 追踪系统不保存这条调用链
- 如果此tag没有提供，追踪系统使用自己的默认采样规则

### [OpenTracing 多语言支持](https://links.jianshu.com/go?to=https%3A%2F%2Fwu-sheng.gitbooks.io%2Fopentracing-io%2Fcontent%2Fpages%2Fapi%2Fapi-implementations.html)

提供不同语言的 API，用于在自己的应用程序中执行链路记录。

## Jaeger

[Jaeger](https://links.jianshu.com/go?to=https%3A%2F%2Fwww.jaegertracing.io%2F) (ˈyā-gər) 是Uber开发的一套分布式追踪系统，受启发于 dapper 和 OpenZipkin，兼容 OpenTracing 标准，CNCF的开源项目。

### 系统框架

![img](https://upload-images.jianshu.io/upload_images/2191371-920937cc7dd6929c.png?imageMogr2/auto-orient/strip|imageView2/2/w/1200)

- Jaeger Client - 为不同语言实现了符合 OpenTracing 标准的 SDK。应用程序通过 API 写入数据，client library 把 trace 信息按照应用程序指定的采样策略传递给 jaeger-agent。
- Agent - 是一个监听在 UDP 端口上接收 span 数据的网络守护进程，它会将数据批量发送给 collector。它被设计成一个基础组件，推荐部署到所有的宿主机上。Agent 将 client library 和 collector 解耦，为 client library 屏蔽了路由和发现 collector 的细节。
- Collector - 接收 jaeger-agent 发送来的数据，然后将数据写入后端存储。Collector 被设计成无状态的组件，因此您可以同时运行任意数量的 jaeger-collector。
- Data Store - 后端存储被设计成一个可插拔的组件，支持将数据写入 cassandra、elastic search。
- Query - 接收查询请求，然后从后端存储系统中检索 trace 并通过 UI 进行展示。Query 是无状态的，您可以启动多个实例，把它们部署在 nginx 这样的负载均衡器后面。

官方释放部署的镜像到 dockerhub，所以部署 jaeger 非常方便，如果是本地测试，可以直接用 jaeger 提供的 all-in-one 镜像部署。

### 快速搭建，[all-in-one](https://links.jianshu.com/go?to=https%3A%2F%2Fwww.jaegertracing.io%2Fdocs%2F1.12%2Fgetting-started%2F)

执行一下命令，可以在本机拉起一个 jaeger 环境，上报的链路数据保存在本地内存，所以只能用于测试。

```bash
$ docker run -d --name jaeger \
  -e COLLECTOR_ZIPKIN_HTTP_PORT=9411 \
  -p 5775:5775/udp \kaixiao
  -p 6831:6831/udp \
  -p 6832:6832/udp \
  -p 5778:5778 \
  -p 16686:16686 \
  -p 14268:14268 \
  -p 9411:9411 \
  jaegertracing/all-in-one:latest
```

通过 [http://localhost](https://links.jianshu.com/go?to=http%3A%2F%2Flocalhost%2F):16686 可以在浏览器查看 Jaeger UI

[官方提供的一个例子: HotROD](https://links.jianshu.com/go?to=https%3A%2F%2Fwww.jaegertracing.io%2Fdocs%2F1.12%2Fgetting-started%2F)

### 采样速率

生产环境系统性能很重要，所以对于所有的请求都开启 Trace 显然会带来比较大的压力，另外，大量的数据也会带来很大存储压力。为此，jaeger 支持设置采样速率，根据系统实际情况设置合适的采样频率。

> Jaeger 官方提供了多种采集策略，使用者可以按需选择使用

1. const，全量采集，采样率设置0,1 分别对应打开和关闭
2. probabilistic ，概率采集，默认万份之一，0~1之间取值，
3. rateLimiting ，限速采集，每秒只能采集一定量的数据
4. remote ，一种动态采集策略，根据当前系统的访问量调节采集策略