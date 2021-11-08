- [基于 Istio 的全链路灰度方案探索和实践](https://www.cnblogs.com/alisystemsoftware/p/15518944.html)

# 背景

微服务软件架构下，业务新功能上线前搭建完整的一套测试系统进行验证是相当费人费时的事，随着所拆分出微服务数量的不断增大其难度也愈大。这一整套测试系统所需付出的机器成本往往也不低，为了保证应用新版本上线前的功能正确性验证效率，这套系统还必须一直单独维护好。当业务变得庞大且复杂时，往往还得准备多套，这是整个行业共同面临且难解的成本和效率挑战。如果能在同一套生产系统中完成新版本上线前的功能验证的话，所节约的人力和财力是相当可观的。

除了开发阶段的功能验证，生产环境中引入灰度发布才能更好地控制新版本软件上线的风险和爆炸半径。灰度发布是将具有一定特征或者比例的生产流量分配到需要被验证的服务版本中，以观察新版本上线后的运行状态是否符合预期。

阿里云 ASM Pro（相关链接请见文末）基于 Service Mesh 所构建的全链路灰度方案，能很好帮助解决以上两个场景的问题。

ASM Pro 产品功能架构图：

![1.png](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/bc34227715634cfca7ae4ece81a4386c~tplv-k3u1fbpfcp-zoom-1.image)

核心能力使用的就是上图扩展的流量打标和按标路由以及流量 Fallback 的能力，下面详细介绍说明。

# 场景说明

全链路灰度发布的常见场景如下：

![2.png](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/20da98e0b1db43019051908e8e915b25~tplv-k3u1fbpfcp-zoom-1.image)

以 Bookinfo 为例，入口流量会带上期望的 tag 分组，sidecar 通过获取请求上下文（Header 或 Context)  中的期望 tag，将流量路由分发到对应 tag 分组，若对应 tag 分组不存在，默认会 fallback 路由到 base 分组，具体  fallback 策略可配置。接下来详细描述具体的实现细节。

入口流量的 tag 标签，一般是在网关层面基于类似 tag 插件的方式，将请求流量进行打标。 比如将 userid 处于一定范围的打上代表灰度的 tag，考虑到实际环境网关的选择和实现的多样性，网关这块实现不在本文讨论的范围内。

下面我们着重讨论基于 ASM Pro 如何做到全链路流量打标和实现全链路灰度。

# 实现原理

![3.png](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/afad4ac551844b589df65f5df5b743d6~tplv-k3u1fbpfcp-zoom-1.image)

Inbound 是指请求发到 App 的入口流量，Outbond 是指 App 向外发起请求的出口流量。

上图是一个业务应用在开启 mesh 后典型流量路径：业务 App 接收到一个外部请求   p1，接着调用背后所依赖的另一个服务的接口。此时，请求的流量路径是 p1->p2->p3->p4，其中 p2 是  Sidecar 对 p1 的转发，p4 是 Sidecar 对 p3 的转发。为了实现全链路灰度，p3 和 p4 都需要获取到 p1  进来的流量标签，才能将请求路由到标签所对应的后端服务实例，且 p3 和 p4  也要带上同样的标签。关键在于，如何让标签的传递对于应用完全无感，从而实现全链路的标签透传，这是全链路灰度的关键技术。ASM Pro  的实现是基于分布式链路追踪技术（比如，OpenTracing、OpenTelemetry 等）中的 traceId 来实现这一功能。

在分布式链路追踪技术中，traceId  被用于唯一地标识一个完整的调用链，链路上的每一个应用所发出的扇出（fanout）调用，都会通过分布式链路追踪的 SDK 将源头的 traceId 给带上。ASM Pro 全链路灰度解决方案的实现正是建立在这一分布式应用架构所广泛采纳的实践之上的。

上图中，Sidecar 本来所看到的 inbound 和 outbound 流量是完全独立的，无法感知两者的对应关系，也不清楚一个  inbound 请求是否导致了多个 outbound 请求的发生。换句话说，图中 p1 和 p3 两个请求之间是否有对应关系 Sidecar  并不知情。

在 ASM Pro 全链路灰度解决方案中，通过 traceId 将 p1 和 p3 两个请求做关联，具体说来依赖了 Sidecar 中的  x-request-id 这个 trace header。Sidecar 内部维护了一张映射表，其中记录了 traceId 和标签的对应关系。当 Sidecar 收到 p1 请求时，将请求中的 traceId 和标签存储到这张表中。当收到 p3 请求时，从映射表中查询获得 traceId 所对应的标签并将这一标签加入到 p4 请求中，从而实现全链路的打标和按标路由。下图大致示例了这一实现原理。

![4.png](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/3a461a10645f4fa7ad50f18b139a6471~tplv-k3u1fbpfcp-zoom-1.image)

换句话说，ASM Pro  的全链路灰度功能需要应用使用分布式链路追踪技术。如果想运用这一技术的应用没有使用分布式链路追踪技术的话不可避免地涉及到一定的改造工作。对于  Java 应用来说，仍可以考虑采用 Java Agent 以 AOP 的方式让业务无需改造地实现 traceId 在 inbound 和  outbound 之间透传。

# 实现流量打标

ASM Pro 中引入了全新的 TrafficLabel CRD 用于定义 Sidecar 所需透传的流量标签从哪里获取。下面所例举的  YAML 文件中，定义了流量标签来源和需要将标签存储 OpenTracing 中（具体是 x-trace 头）。其中流量标的名为  trafficLabel，取值依次从 $getContext(x-request-id) 到最后从本地环境的$(localLabel)中获取。

```
apiVersion: istio.alibabacloud.com/v1beta1
kind: TrafficLabel
metadata:
  name: default
spec:
  rules:
  - labels:
      - name: trafficLabel
        valueFrom:
        - $getContext(x-request-id)  //若使用aliyun arms,对应为x-b3-traceid
        - $(localLabel)
    attachTo:
    - opentracing
    # 表示生效的协议，空为都不生效，*为都生效
    protocols: "*"
```

CR 定义包含两块，即标签的获取和存储。

- 获取逻辑：先根据协议上下文或者头（Header 部分）中的定义的字段获取流量标签，如果没有，会根据 traceId 通过 Sidecar 本地记录的 map 获取, 该 map 表中保存了 traceId 对应流量标识的映射。若 map  表中找到对应映射，会将该流量打上对应的流量标，若获取不到，会将流量标取值为本地部署对应环境的 localLabel。localLabel  对应本地部署的关联 label，label 名为 ASM_TRAFFIC_TAG。

本地部署对应环境的标签名为"ASM_TRAFFIC_TAG"，实际部署可以结合 CI/CD 系统来关联。

![5.png](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/fc42eded4f6447369c25cb99032e3b5f~tplv-k3u1fbpfcp-zoom-1.image)

- 存储逻辑：attachTo 指定存储在协议上下文的对应字段，比如 HTTP 对应 Header 字段，Dubbo 对应 rpc context 部分，具体存储到哪一个字段中可配置。

有了TrafficLabel 的定义，我们知道如何将流量打标和传递标签，但光有这个还不足以做到全链路灰度，我们还需要一个可以基于  trafficLabel 流量标识来做路由的功能，也就是“按标路由”，以及路由 fallback  等逻辑，以便当路由的目的地不存在时，可以实现降级的功能。

# 按流量标签路由

这一功能的实现扩展了 Istio 的 VirtualService 和 DestinationRule。

### 在 DestinationRule 中定义 Subset

自定义分组 subset 对应的是 trafficLabel 的 value

```
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: myapp
spec:
  host: myapp/*
  subsets:
  - name: myproject            # 项目环境
    labels:
      env: abc
  - name: isolation            # 隔离环境
    labels:
      env: xxx                 # 机器分组
  - name: testing-trunk        # 主干环境
    labels:
      env: yyy
  - name: testing              # 日常环境
    labels:
      env: zzz
---
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: myapp
spec:
  hosts: 
        - myapp/*
  ports:
  - number: 12200
    name: http
    protocol: HTTP
    endpoints:
      - address: 0.0.0.0
        labels:
            env: abc
      - address: 1.1.1.1
        labels:
            env: xxx
      - address: 2.2.2.2
        labels:
            env: zzz
      - address: 3.3.3.3
        labels:
            env: yyy
```

Subset 支持两种指定形式：

- labels 用于匹配应用中带特定标记的节点（endpoint）；
- 通过 ServiceEntry 用于指定属于特定 subset 的 IP  地址，注意这种方式与labels指定逻辑不同，它们可以不是从注册中心（K8s 或者其他）拿到的地址，直接通过配置的方式指定。适用于 Mock  环境，这个环境下的节点并没有向服务注册中心注册。

### 在 VirtualService 中基于 subset

#### 1）全局默认配置

- route 部分可以按顺序指定多个 destination，多个 destination 之间按照 weight 值的比例来分配流量。
- 每个 destination 下可以指定 fallback 策略，case 标识在什么情况下执行  fallback，取值：noinstances（无服务资源）、noavailabled（有服务资源但是服务不可用），target 指定  fallback 的目标环境。如果不指定 fallback，则强制在该 destination 的环境下执行。
- 按标路由逻辑，我们通过改造 VirtualService，让 subset 支持占位符  $trafficLabel, 该占位符 $trafficLabel 表示从请求流量标中获取目标环境， 对应 TrafficLabel CR 中的定义。

全局默认模式对应泳道，也就是单个环境内封闭，同时指定了环境级别的 fallback 策略。自定义分组 subset 对应的是 trafficLabel 的 value

配置样例如下：

```
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: default-route
spec:
  hosts:                     # 对所有应用生效
  - */*
  http:
  - name: default-route
    route:
    - destination:
        subset: $trafficLabel
      weight: 100
      fallback:
         case: noinstances
         target: testing-trunk
    - destination:
            host: */*
        subset: testing-trunk    # 主干环境
      weight: 0
      fallback:
        case: noavailabled
        target: testing
    - destination:
        subset: testing          # 日常环境
      weight: 0
      fallback:
        case: noavailabled
        target: mock
    - destination:
            host: */*
        subset: mock             # Mock中心
       weight: 0
```

#### 2）个人开发环境定制

- 先打到日常环境，当日常环境没有服务资源时，再打到主干环境。

```
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: projectx-route
spec:
  hosts:                   # 只对myapp生效
  - myapp/*
  http:
  - name: dev-x-route
    match:
      trafficLabel:
      - exact: dev-x       # dev环境: x
    route:
    - destination:
            host: myapp/*
        subset: testing          # 日常环境
      weight: 100
      fallback:
        case: noinstances
        target: testing-trunk
    - destination:
            host: myapp/*
        subset: testing-trunk    # 主干环境
      weight: 0
```

#### 3） 支持权重配置

将打了主干环境标并且本机环境是 dev-x 的流量，80% 打到主干环境，20% 打到日常环境。当主干环境没有可用的服务资源时，流量打到日常。

sourceLabels 为本地 workload 对应的 label

```
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: dev-x-route
spec:
  hosts:                   # 对哪些应用生效（不支持多应用配置）
  - myapp/*
  http:
  - name: dev-x-route
    match:
      trafficLabel:
      - exact: testing-trunk # 主干环境标
      sourceLabels:
      - exact: dev-x  # 流量来自某个项目环境
    route:
    - destination:
            host: myapp/*
        subset: testing-trunk # 80%流量打向主干环境
      weight: 80
      fallback:
        case: noavailabled
        target: testing
    - destination：
            host: myapp/*
        subset: testing       # 20%流量打向日常环境
      weight: 20
```

# 按（环境）标路由

该方案依赖业务部署应用时带上相关标识（例子中对应 label 为 ASM_TRAFFIC_TAG: xxx），常见为环境标识，标识可以理解是服务部署的相关元信息，这个依赖上游部署系统 CI/CD 系统的串联，大概示意图如下：

- K8s 场景，通过业务部署时自动带上对应环境/分组 label 标识即可，也就是采用K8s 本身作为元数据管理中心。
- 非 K8s 场景，可以通过微服务已集成的服务注册中心或者元数据配置管理服务（metadata server）来集成实现。

![6.png](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/7e6a1236e01e42ca955195684486b3c8~tplv-k3u1fbpfcp-zoom-1.image)

注：ASM Pro 自研开发了ServiceDiretory 组件（可以参看 ASM Pro 产品功能架构图），实现了多注册中心对接以及部署元信息的动态获取；

# 应用场景延伸

下面是典型的一个基于流量打标和按标路由实现的多套开发环境治理功能；每个开发者对应的 Dev X  环境只需部署有版本更新的服务即可；如果需要和其他开发者联调，可以通过配置 fallback 将服务请求 fallback  流转到对应开发环境即可。如下图的 Dev Y 环境的B -> Dev X 环境的 C。

同理，将 Dev X 环境等同于线上灰度版本环境也是可以的，对应可以解决线上环境的全链路灰度发布问题。

![7.png](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/52cc3dc0d1434dad9c958ccd9ec47e77~tplv-k3u1fbpfcp-zoom-1.image)

# 总结

本文介绍的基于“流量打标”和“按标路由” 能力是一个通用方案，基于此可以较好地解决测试环境治理、线上全链路灰度发布等相关问题，基于服务网格技术做到与开发语言无关。同时，该方案适应于不同的7层协议，当前已支持 HTTP/gRpc 和 Dubbo 协议。

对应全链路灰度，其他厂商也有一些方案，对比其他方案 ASM Pro 的解决方案的优点是：

- 支持多语言、多协议。
- 统一配置模板 TrafficLabel， 配置简单且灵活，支持多级别的配置（全局、namespace 、pod 级别）。
- 支持路由 fallback 实现降级。

基于“流量打标” 和 “按标路由”能力还可以用于其他相关场景：

- 大促前的性能压测。在线上压测的场景中，为了让压测数据和正式的线上数据实现隔离，常用的方法是对于消息队列，缓存，数据库使用影子的方式。这就需要流量打标的技术，通过 tag 区分请求是测试流量还是生产流量。当然，这需要 Sidecar 对中间件比如 Redis、RocketMQ 等进行支持。
- 单元化路由。常见的单元化路由场景，可能是需要根据请求流量中的某些元信息比如  uid，然后通过配置得出对应所属的单元。在这个场景中，我们可以通过扩展 TrafficLabel  定义获取“单元标”的函数来给流量打上“单元标”，然后基于“单元标”将流量路由到对应的服务单元。