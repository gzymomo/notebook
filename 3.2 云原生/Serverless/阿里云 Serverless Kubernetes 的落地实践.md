- [阿里云 Serverless Kubernetes 的落地实践](https://mp.weixin.qq.com/s/EOroL7-0PwSRS-yMnLEC0Q)

## 导读

Kubernetes 作为当今云原生业界标准，具备良好的生态以及跨云厂商能力。Kubernetes 很好的抽象了 IaaS  资源交付标准，使得云资源交付变的更简单，与此同时越来越多的用户期望能够聚焦于业务自身，做到面向应用交付，Serverless 理念也因此而生。

那么如何通过原生 Kubernetes 提供 Serverless 能力？如何借力丰富的云原生社区生态？本文给大家介绍一下我们在 Serverless Kubernetes 上的落地实践。本文将从以下 3 个方面展开介绍：

- 为什么要做Serverless Kubernetes
- 如何实现Serverless Kubernetes
- Serverless Kubernetes 落地实践

## Serverless Kubernetes 初衷

### 1、 Kubernetes

众所周知，Kubernetes 是一款开源容器化编排系统，用户使用 Kubernetes 可以做到降低运维成本、提高运维效率，并且提供标准化  API，某种意义就是避免被云厂商绑定，进而形成了以 Kubernetes 为核心的云原生生态。可以说 Kubernetes  已然成为了云原生业界事实标准。

![image-20211224210747841](https://gitee.com/er-huomeng/img/raw/master/img/image-20211224210747841.png)



### 2、Serverless 与 Kubernetes

那么我们回到 Serverless 上面来，**Serverless 的核心理念在于让开发者更聚焦业务逻辑，减少对基础设施的关注。**那么我们如何在云原生业界标准之上做 Serverless，Kubernetes 是否也能做到更专注于应用业务逻辑。

![image-20211224210800879](https://gitee.com/er-huomeng/img/raw/master/img/image-20211224210800879.png)

![image-20211224210812556](https://gitee.com/er-huomeng/img/raw/master/img/image-20211224210812556.png)

### 3、Kubernetes 做 Serverless 的优势

在看一下 Kubernetes 做 Serverless 有什么优势前，我们先来看一下 Kubernetes 特性包括哪些：

- 容器化
- 统一 IaaS 资源交付
- CI/CD 持续集成部署
- 跨云厂商
- 丰富的生态
- 面向应用管理

对应于 Serverless 来说：

- 事件驱动：Kubernetes 支持 job 类型、并围绕 Kubernetes 提供丰富的事件源
- 按需使用：Kubernetes 本身支持 hpa 弹性能力
- 免运维、高可用：Kubernetes 可以通过容器化、统一资源交付很好的支持。

结合这些来看 Kubernetes 实现 serverless，具备天然优势。

![image-20211224210834134](https://gitee.com/er-huomeng/img/raw/master/img/image-20211224210834134.png)



## 如何实现 Serverless Kubernetes

在 Kubernetes 上实现 Serverless 主要做到一下两点：

- 向下如何让用户减少对基础设施的关注；
- 向上如何更聚焦业务应用。

![image-20211224210848539](https://gitee.com/er-huomeng/img/raw/master/img/image-20211224210848539.png)

这里我们通过 Serverless Framework ，聚焦业务应用，进一步抽象 Kubernetes 资源，提供按需使用自动弹性的能力。通过 IaaS 资源免运维，减少对基础设施的关注，做到节点免运维。

那么 IaaS 资源免运维，我们又是如何做的呢？

### 1、减少对基础设置的关注：IaaS 免运维

原生的 Kubernetes  节点资源需要用户自行维护，为了降低用户维护节点成本，我们提供了托管节点池，帮助用户维护节点的生命周期，但用户还是需要对托管节点池策略进行维护，更近一步在 Serverless Kubernetes 中通过虚拟节点结合弹性容器实例 ECI，让用户彻底摆脱对 IaaS 的运维。

![image-20211224210905373](https://gitee.com/er-huomeng/img/raw/master/img/image-20211224210905373.png)

Serverless Kubernetes IaaS 资源免运维包括：

- 基于容器，安全隔离、高移植
- 无服务器管理：无需容量规划，对服务器免运维
- 弹性扩容：秒级扩容，无限容器
- 按需付费，更高资源利用率

![image-20211224210914468](https://gitee.com/er-huomeng/img/raw/master/img/image-20211224210914468.png)

向下我们通过虚拟节点结合 ECI 实现了 IaaS 资源免运维，那么向上如何聚焦业务逻辑呢？其实就是以应用为核心。

### 2、聚焦业务逻辑：以应用为核心

围绕应用来看，无非我们要解这些问题：

- 应用部署
- 灰度发布
- 流量管理
- 自动弹性
- 可观测性以及应用的多版本管理

那么有开箱即用的方案去解吗？答案是 Knative。

![image-20211224210930987](https://gitee.com/er-huomeng/img/raw/master/img/image-20211224210930987.png)

### 3、Knative 是什么

Knative 是基于 Kubernetes 之上提供的一款开源 Serverless 应用框架，帮助用户部署和管理现代化的 Serverless 工作负载，打造企业级 Serverless 平台。

Knative 具备如下优势：

- 在几秒钟内建立可扩展、安全、无状态的服务。
- 具有更高级别 Kubernetes 应用抽象的 API。
- 可插拔组件，让您可以使用自己的日志记录和监控、网络和服务网格。
- 在 Kubernetes 运行的任何地方都可以运行 Knative，无需担心供应商锁定。
- 开发者无缝体验，支持 GitOps、DockerOps、ManualOps 等。
- 支持常用工具和框架，例如 Django、Ruby on Rails、Spring 等。

Knative 主要包括 2 大核心模块：Serving 和 Eventing

Serving 提供了 Service 应用模型，支持基于流量的灰度发布、版本管理、缩容到 0 以及自动弹性。

Eventing 提供事件驱动能力。支持丰富的事件源，以及用于事件流转、过滤的 Broker/Trigger 模型。

![image-20211224210948891](https://gitee.com/er-huomeng/img/raw/master/img/image-20211224210948891.png)

### 4、为什么是 Knative

那么我们为什么选择 Knative 呢？

![image-20211224211000510](https://gitee.com/er-huomeng/img/raw/master/img/image-20211224211000510.png)



根据 CNCF 2020 中国云原生调查报告，Knative 已经成为 Kubernetes 上最广泛安装的无服务器。

另外 Knative 社区近期也发起了一项统计：当前哪些云厂商或企业在提供或者使用 Knative。我们可以看到，几乎所有的大厂都支持或者集成  Knative, 如阿里云、谷歌云、IBM、Red Hat  等，并且大部分都提供了生产级别能力（Production），这些迹象表明越来越多的用户拥抱 Knative。

此外近期 Knative 已申请成为 CNCF 孵化项目，这无疑让 Knative 开发者为之兴奋。

### 5、Knative 落地挑战、应对与效果

从开源到产品化落地，必然会面对一些挑战。Knative 产品化落地主要面对如下挑战：

- 管控组件多，运维复杂
- 0 到 1 冷启动问题
- 流量请求 1 对 1 分发

那么我们如何来应对呢？

我们提供组件托管，帮助用户节省资源及运维成本；当请求为 0 时，缩容到低规格保留实例，实现请求 0 到 1 免冷启动，做到成本可控；提供自研事件网关，做到流量的精准控制。

![image-20211224211015277](https://gitee.com/er-huomeng/img/raw/master/img/image-20211224211015277.png)

## Serverless Kubernetes 落地实践

### 1、落地方案

结合上述介绍，向上通过 Serverless Framewok Knative 更聚焦业务应用，向下通过虚拟节点减少对基础设施的关注。这就是我们Serverless  Kubernetes 落地方案：围绕 Kubernetes api, 下线集成云产品的能力，包括消息事件、弹性容器实例以及日志监控等。向上通过  Knative 围绕应用为核心，提供事件驱动、自动弹性等能力等。

![image-20211224211031544](https://gitee.com/er-huomeng/img/raw/master/img/image-20211224211031544.png)

### 2、典型应用场景

最后我们来看一下目前有哪些落地场景，典型的应用场景及行业领域如图：

![image-20211224211049102](https://gitee.com/er-huomeng/img/raw/master/img/image-20211224211049102.png)



### 3、落地实践：异构资源，按需使用 

#### (1) 客户痛点

用户希望通过 Serverless 技术按需使用资源，节省资源使用成本，简化运维部署 。另外有 GPU 的业务诉求。希望使用容器化的 Serverless  ，支持使用 GPU 资源，同时简化应用运维部署（尽可能少的操作 Kubernetes  deployment/svc/ingress/hpa等资源），IaaS 资源免运维。

#### (2) 解决方案

使用 Knative + ASK 作为 Serverless 架构。数据采集之后，通过服务网关访问数据处理服务，数据处理服务根据请求量按需自动扩缩容。

![image-20211224211106007](https://gitee.com/er-huomeng/img/raw/master/img/image-20211224211106007.png)



### 4、落地实践：事件驱动，精准分发

某客户直播系统支持用户在线互动。消息数据的处理主要有以下技术挑战：

- 业务弹性波动，消息并发高。
- 互动实时响应，低延迟。

客户选择阿里云的 Knative 服务进行数据的弹性处理。应用实例数随着业务波峰波谷实时扩容和缩容，真正做到了按需使用，实时弹性的云计算能力。整个过程完全自动化，极大的减少了业务开发人员在基础设施上的心智负担。

![image-20211224211123893](https://gitee.com/er-huomeng/img/raw/master/img/image-20211224211123893.png)

## 总结

我们回顾一下本文介绍的主要内容：

首先介绍了为什么在 Kubernetes 提供 Serverless：

- Kubernetes 已成为云原生业界标准
- 面向标准 Kubernetes API 进行 Serverless 编程

然后我们如何实现 Serverless  Kubernetes：

- IaaS 节点免运维
- Serverless Framework (Knative)

最后介绍了 2 个落地实践场景：

- 异构资源，按需使用
- 事件驱动，精准分发

一句话：Serverless Kubernetes 基于 Kubernetes 之上，提供按需使用、节点免运维的 Serverless 能力，让开发者真正实现通过 Kubernetes 标准化 API 进行 Serverless 应用编程，值得关注。