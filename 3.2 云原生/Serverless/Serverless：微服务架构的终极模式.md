- [Serverless：微服务架构的终极模式](https://mp.weixin.qq.com/s/OIkMY7sBLpj00MGJgD7mVQ)

## 微服务面临的挑战

微服务的粒度影响服务的交付速度及扩展性，微服务的开发引入治理组件，增加了开发的难度，以容器为基础的微服务基础设施在弹性等方面仍有不足，而微服务增加带来的基础设施成本也是微服务实施的新挑战。

### 1．微服务的粒度仍然比较大

当前微服务划分主要遵循单一职责的原则，比如将用户管理的功能作为一个单独的微服务。如图所示，用户管理微服务提供了 API 注册、登录、登出功能。通常，从提升用户体验的角度来看，浏览器会保留用户的会话，除非用户主动登出，否则不会请求登出  API。所以，登出和注册的 QPS 差距较大，对扩展的诉求完全不同。而且，注册 API 和登出 API  的变更频率也可能不同。进一步拆分可以带来扩展性等便利，但整个微服务的数量也会提升一个量级，给基础设施的管理带来负担，那么如何做好架构权衡，既能够拥有架构上的高可扩展性，又不用增加基础设施管理成本呢？

![图片](https://mmbiz.qpic.cn/mmbiz_png/qFG6mghhA4YsoZZzUkO1rKTGPzjvoXrsPiamtuastdRCr4mJ4u6gCYcO3qkkwdKibhibEd1xwMq1jlGlq9rgG83fw/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

### 2．微服务开发仍有较高门槛

如图所示，Java 微服务开发的软件栈要求开发者掌握以下技能。

![图片](https://mmbiz.qpic.cn/mmbiz_png/qFG6mghhA4YsoZZzUkO1rKTGPzjvoXrsxzuLtic7xX1Y1b8AemvQTOJckW0Q1H82NLiaRiceic2VdUOp18rWiaLNF2A/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)Java微服务开发技术栈

相比于单体应用开发，微服务开发效率得到提升的部分来自服务粒度减少及开发框架的改进，例如，从复杂的 SpringMVC 演进到  SpringBoot，框架更加轻量化。但在其他方面（并发处理等）并没有什么改变，同时在微服务治理、分布式事务等方面的开发难度反而增加了。服务网格的出现，让开发人员可以不用关心服务治理的内容，但这样会带来服务性能的下降和维护的复杂性，其使用的范围也存在局限。是否存在一种新的编程模型及开发框架，让开发者在了解基本的语言特性和编程模型后，便可上手开发业务逻辑，而不用关心网络、并发、服务治理等问题？

### 3．微服务基础设施管理、高可用和弹性仍然很难保证

容器和 Kubernetes  工具的使用，提升了应用部署及基础设施运维自动化的能力，但保证基础设施高可用、可扩展对运维人员的能力要求很高。如图所示，服务上云后，基础设施团队可以不用再关心服务器、交换机等硬件的运维，但仍然需要关心虚拟机的维护，如安全补丁、基础镜像的更新升级、扩容等。

![图片](https://mmbiz.qpic.cn/mmbiz_png/qFG6mghhA4YsoZZzUkO1rKTGPzjvoXrsOSxSJrhMf1XDnQEBI6YgTnQU232T50DZmjt6nJ6yicvsZ7CZBGicwDuQ/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)基础设施团队依然需要管理虚拟机

从 On-Premise 到公有云，实际上虚拟机的可用性在降低，比如云服务商提供的单虚拟机的可用性可能只有 95%。运维人员需要借助云侧的工具来保证基础设施的高可用，难度仍然存在，而且很依赖运维人员的能力。

集群及其他云原生工具的维护也带来额外的挑战。以 Kubernetes 集群为例，维护和管理 Kubernetes  集群需要专业的技能。同理，维护云原生的监控、日志服务的高可用性也有不小的难度。所以，基础设施管理的难度仍然存在，只是从虚拟机转移到容器集群，从  Rsyslog 转移到 ElasticSearch。

对于服务层面的扩展性，当前的策略也比较简单，例如，设定最少和最多使用的虚拟机数量，或者想办法改善根据  CPU/内存使用率来伸缩或扩容的延迟。但是，由于总体资源量不会超过策略设定的虚拟机极限数量，因此一旦请求超过最大资源能承载的范围，可能会影响用户的使用体验甚至会服务中断。以容器为单位的扩容，从虚拟机性能的分钟级减少到 30s  左右，但当面对突发流量时依然会出现响应不及时、用户体验差的情况。是否存在全托管的基础设施及监控运维服务，能提供更好的弹性，从而让开发者无须关心所有底层和集群的维护工作，不再依赖高级运维人员来保证基础设施的可用性？

### 4．基础设施的成本依然较高

微服务会增加基础设施的成本。每个微服务都要考虑冗余，保证高可用。随着微服务数量的增加，基础设施的数量会呈现指数级增长，但云服务的基础设施收费方式没有改变，依然采用按照资源大小及以小时为单位（或包年）计费的方式。闲时和忙时的收费相同，对企业来说存在成本的浪费。是否存在一种新的基础设施服务，能按照“用多少付多少”的方式收费，从而降低基础设施成本？

微服务面临的这些新问题，是否可以通过新的基础设施服务及开发模式来解决呢？

## 什么是 Serverless

2012 年，时任 Iron.io 的副总裁 Ken 提出了 Serverless 的概念，他认为未来的软件和应用都应该是 Serverless  的：“即使云计算兴起，世界仍然围绕着服务器运转。不过，这不会持续下去。云应用程序正在进入无服务器世界，这将对软件和应用程序的创建和分发产生重大影响。”

2014 年，AWS 推出 Lambda 函数计算服务，提供简化的编程模型及函数的运行环境全托管，并且计费方式更加接近实际的使用情况（请求次数和每  100ms 使用的内存资源）。2015 年，AWS 推出 API Gateway（全托管的网关服务），正式将 Serverless  这个概念推广开来。近年来，大部分的云提供商也提供了各种形态的 Serverless 服务，用于支持更多应用的开发和运行。下图为 AWS  Serverless 全景图。

![图片](https://mmbiz.qpic.cn/mmbiz_png/qFG6mghhA4YsoZZzUkO1rKTGPzjvoXrsvUlbNx3PGkAibjjH5cgvOdzH5MVId2coswia3Yib2wKibyaUicYbBtKy1nw/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)AWS Serverless全景图

Google 在 Serverless 上的投入和发展节奏也很快。为了扩大在移动应用开发领域的优势，同时为 Google 云引流，Google 在 2011 年就收购了 Firebase，2016 年将其作为 mBaaS（移动后端即服务）的 Serverless  解决方案推出，以及安卓应用开发的主流云服务。除此之外，Google 也推出了其他 Serverless  服务，以提供跨平台（Android、Web、iOS 等）能力，支持移动、Web 等应用开发，下图为 Google Serverless 全景图。

![图片](https://mmbiz.qpic.cn/mmbiz_png/qFG6mghhA4YsoZZzUkO1rKTGPzjvoXrsGB5Esg7IOicwzvA6ALibyzia4tE7WzbRfiaQiaFfkzfRXPLPXcuwTqbCceQ/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)Google Serverless全景图

华为终端云服务以多年为超过百万移动应用开发者提供服务为基础，结合多年在 Serverless 领域的技术积累，推出了 Serverless  行业解决方案，包含构建类（云函数、认证、云存储、云数据库等）、增长类（推送服务、远程配置等）、质量和分析类（性能服务、崩溃服务等），提供面向移动应用开发的 Serverless 服务。2021 年，云函数、云数据库等核心构建类服务已面向全球 HMS 生态的开发者开放，下图为 HUAWEI  AppGallery Connect Serverless 全景图。

![图片](https://mmbiz.qpic.cn/mmbiz_png/qFG6mghhA4YsoZZzUkO1rKTGPzjvoXrsGhlSCUVF6WG7oXtPPMxDkdjibzXK5JeL86ZvEZury7Xict4S5UNtq7wQ/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)HUAWEI AppGallery Connect Serverless全景图

### Serverless 的定义

那么 Serverless 到底是什么呢？维基百科将 Serverless 定义为一种云计算执行模型。

- 云服务商按需分配计算机资源，开发者无须运维这些资源，不用关心容器、虚拟机或物理服务器的容量规划、配置、管理、维护、操作和扩展。
- Serverless 计算无状态，可在短时间内完成计算，其结果保存在外部存储中。
- 当不使用某个应用时，不向其分配计算资源。
- 计费基于应用消耗的实际资源来度量。

CNCF（Cloud Native Computing Foundation，云原生计算基金会）认为 Serverless  旨在构建和运行不需要服务器管理的应用程序，二者的不同之处在于它描述了一个更细粒度的部署模型，能够以一个或多个函数的形式将应用打包并上传到平台执行，并且按需执行、自动扩展和计费。

Serverless 并不意味着不需要服务器来托管和运行代码，也不意味着不再需要运维工程师。Serverless  是指开发者不再需要将时间和资源花费在服务器调配、维护、更新、扩展和容量规划上，这些任务都由 Serverless  平台处理，开发者只需要专注于编写应用程序的业务逻辑，运维工程师能够将精力放在业务运维上。综合维基百科和 CNCF 的定义，可以认为  Serverless 是一种云计算执行、部署和计费模型，Serverless  服务按请求为应用分配资源，按照使用计费，基础设施全托管（无须关心维护、扩容等）。

目前，Serverless 服务主要分为 FaaS 和 BaaS。

- 函数即服务（Function as a  Service，FaaS）：开发者实现的服务器端应用逻辑（微服务甚至粒度更小的服务）以事件驱动的方式运行在无状态的临时容器中，这些容器和计算资源完全由云提供商管理。如图 1-7 所示，从开发者角度来看，FaaS 和 IaaS/PaaS  相比，其扩容的维度从应用级别降低到函数级别，开发者只需关心和维护业务层面的正常运行，其他部分如运行时、容器、操作系统、硬件等，都由云提供商来解决。

![图片](https://mmbiz.qpic.cn/mmbiz_png/qFG6mghhA4YsoZZzUkO1rKTGPzjvoXrs74D6X3hDsQwSkq581J5cF1iauC7zoasQjueJVuhlWia2nc5QDMk9IjDQ/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)FaaS与IaaS、PaaS的区别

- 后端即服务（Backend as a Service，BaaS）：基于 API 的三方服务，用来取代应用程序中功能的核心子集。由于这些 API  是作为自动扩展和透明运行的服务提供的，因此从开发者和运维工程师的角度来看似乎是无服务器的。非计算类的全托管服务，如消息队列等中间件、NoSQL  数据库服务、身份验证服务等，都可以认为是 BaaS 服务。

FaaS 通常是承载业务逻辑代码的服务，开发者会更为关心，它也是本书重点介绍的内容。

### Serverless 关键技术

下图是典型的 Serverless 系统架构，从中可以看到一些 Serverless 的常用概念。

![图片](https://mmbiz.qpic.cn/mmbiz_png/qFG6mghhA4YsoZZzUkO1rKTGPzjvoXrsEhq3vhAhQiapI2cYXZfQoXD77GT02g9O5Yr9Ploa0163YZKgicMggAwg/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)典型的Serverless架构

- 事件源（Event Sources）：事件的生产者，可能是 HTTP 请求、消息队列的事件等，通过同步或异步的方式去触发函数。
- 触发器（Trigger）：函数的 REST 呈现，通常是 RESTful URL。当事件源将事件推/拉到触发器时，FaaS 平台会查找触发器和函数的映射关系，从而启动该函数实例，以响应被推/拉到触发器的事件。
- FaaS 控制器（FaaS Controller）：FaaS 平台的核心组件，管理函数的生命周期、扩容和缩容等。可以将函数实例缩容为 0，同时在收到对函数的请求时迅速启动新的函数实例。
- 函数实例（Function Instance）：执行函数的环境，包含函数代码、函数运行环境（如  JRE、Node.js）、上下文信息（如函数运行的配置，通常以环境变量注入）。一个函数实例可以同时处理 1 个或 N  个事件（取决于平台的具体实现）。函数实例通常内置可观测性，将日志和监控信息上报到对应的日志和监控服务中。
- 函数编程模型（Programming Model）：通常表现为函数的编码规范，如签名、入口的方法名等。函数的编程模型一般会提供同步/异步/异常处理机制，开发者只需要处理输入（事件、上下文），并返回结果即可。
- BaaS 平台：函数通常是无状态的，其状态一般存储在 BaaS 服务中，如 NoSQL 数据库等。函数可以基于 REST API 或 BaaS 服务提供的 SDK 来访问 BaaS 服务，而不用关心这些服务的扩容和缩容问题。

结合上图中典型 Serverless 架构的架构元素，从 Serverless 系统的实现来看，其关键技术需求包括以下几点。

- 函数编程模型：提供友好的编程模型，使开发者可以聚焦于业务逻辑，为开发者屏蔽编码中最困难的部分，如并发编程等。同时，需要原生支持函数的编排，尽量减少开发者的学习成本。
- 快速扩容：传统的基础设施通常都是从 1 到 n 扩容的，而 Serverless 平台需要支持从 0 到 n  扩容，以更快的扩容速度应对流量的变化。同时，传统基础设施基于资源的扩容决策周期（监控周期）过长，而 Serverless  平台可达到秒级甚至毫秒级的扩容速度。
- 快速启动：函数被请求时才会创建实例，该准备过程会消耗较长的时间，影响函数的启动性能。同理，对于新到达的并发请求，会产生并发的冷启动问题。Serverless 平台需要降低冷启动时延，以满足应用对性能的诉求。
- 高效连接：函数需要将状态或数据存放在后端 BaaS 服务中，而对接这些服务往往需要繁杂的  API，造成开发人员的学习负担。如果能提供统一的后端访问接口，则可以降低开发和迁移成本。另外，Serverless  平台的函数实例生命周期通常较短，对于如 RDS  数据库等后端服务无法保持长连接。然而，在并发冷启动场景下，大量函数实例会同时创建与数据库的连接，可能会导致数据库负载增加而访问失败。为此，Serverless 平台需要为函数提供完备、高效、可靠的 BaaS 服务连接/访问接口。
- 安全隔离：Serverless  是逻辑多租的服务，租户的函数代码可能运行在同一台服务器上。基于容器的方式，一旦单个租户的函数遭受攻击，造成容器逃逸，会影响服务器上所有租户的函数安全。所以，通常 Serverless  平台会采用安全容器的方式，引入轻量级虚拟化技术来保证隔离性，但这同时会引入额外的性能（启动）和资源开销等问题。因此，Serverless  平台需要兼顾极致性能和安全隔离。

虽然业界涌现的各种 Serverless 系统在实现上可能有所不同（如本节介绍的多个函数计算平台），但基本的概念、原理和关键技术是相通的，各个系统在实现时都需要应对以上所述的技术挑战。

## Serverless 带来的核心变化

从开发者或商业的角度看来，Serverless 的价值在于全托管及创新的计费模式。但从技术的角度看，Serverless 从架构、开发模式、基础设施等层面都有不同程度的创新。

### Serverless 的技术创新

Serverless 基于事件驱动的架构，它的编程模型和运行模式简化了开发模式，融入了不可变基础设施的最佳实践。

#### **1．Serverless 是事件驱动架构的延伸**

Serverless  更容易实现事件驱动的应用。在分布式系统中，请求/响应的方式和事件驱动的方式都存在。请求/响应是指客户端会发出一个请求并等待一个响应，该过程允许同步或异步方式。虽然请求者可以允许该响应异步到达，但对响应到达的预期本身就在一个响应和另一个响应之间建立了直接的依赖关系。事件驱动的架构是指在松耦合系统中通过生产和消费事件来互相交换信息。相比请求/响应的方式，事件的方式更解耦，并且更加自治。例如，在图片上传后进行转换处理的场景，以往需要一个长时运行的服务去轮询是否有新图片产生，而在 Serverless  下，用户不需要进行编码轮询，只需要通过配置将对象存储服务中的上传事件对接到函数即可，文件上传后会自动触发函数进行图片转换。

Serverless 架构的基本单元从微服务变为函数。微服务的每个 API  的非功能属性有差异，比如对性能、扩展性、部署频率的要求并不相同，进一步拆分的确有助于系统的持续演进，但相应会带来指数级的服务数量增长，导致微服务的基础设施和运维体系难以支撑。Serverless  架构可以将微服务的粒度进一步降低到函数级，同时不会对基础设施和运维产生新的负担，只是增加了少量的函数管理成本，相比其带来的收益这是完全可以接受的。

基于 Serverless 更容易构建 3-Tier 架构应用。3-Tier 是指将应用分为 3  层，即展示层、业务层及数据层，并且会部署在不同的物理位置。如 Web  应用，其展示层和业务层在物理层面往往会在一起部署。以下图中的宠物商店应用为例，在基于微服务的部署视图中，其业务层和展示层在一起部署；而在基于  Serverless 的部署视图中，展示层可以托管在对象存储服务中，业务层由 FaaS 托管，数据层由云数据库托管，实现了 3-Tier  在物理上的独立部署。同时，各层独立扩展，技术独自演进。

![图片](https://mmbiz.qpic.cn/mmbiz_png/qFG6mghhA4YsoZZzUkO1rKTGPzjvoXrsiaNLtjCo4WibxWTjicLTxCyr6MML7j1ZmPZIiaagt9Q8LNe8jRHn3MpoYQ/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)通过Serverless构建三层架构的宠物商店应用

#### **2．Serverless 简化了开发模式**

微服务提供了丰富的框架，方便开发者进行开发，但同时也增加了开发者的认知负担，同样是使用 Java，基于 Serverless 开发服务，开发者只需掌握 Java 的基础特性、函数编程框架及 BaaS 的 SDK 即可，如下图所示。

![图片](https://mmbiz.qpic.cn/mmbiz_png/qFG6mghhA4YsoZZzUkO1rKTGPzjvoXrsJFfmXKlZZ45559P5TPc2SMnHxwyiaS9yAOWTk0zZT2zpgQZy7FJNbbA/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)基于Java的微服务开发和函数开发差异

函数的编程框架相比 Spring/SpringBoot 要简单很多，开发者只需了解输入输出处理（通常为  JSON）及如何处理业务逻辑。如下图所示，Serverless 系统可以是 1∶1  的触发模型，每个请求被一个单独的函数实例处理，每个实例可以被视为一个单独的线程，系统自动根据请求数量扩展函数实例，开发者不用理解 Java  的并发编程也可以轻松实现对高并发应用的支持。

![图片](https://mmbiz.qpic.cn/mmbiz_png/qFG6mghhA4YsoZZzUkO1rKTGPzjvoXrsLLfyDIBN4YzB50qfuVspB8oIbURKMszoKu4fYjGotNib0TI1u1RDWJA/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)Serverless支持应用的高并发

基于函数的编程模型，可以继续对数据进行抽象操作。例如，Azure Function 提供的 Data Binding 功能，允许开发者用一套配置和一种编程模型操作不同存储服务的数据，让开发服务变得更加简单，降低开发人员的认知负担，进而提升开发效率。

#### **3．Serverless 是不可变基础设施的最佳实践**

Serverless  直接以代码方式部署，开发者不用再考虑容器镜像打包、镜像维护等问题。系统通常在部署时重新创建函数实例，在不使用时回收实例，每次处理用户请求的可能都是全新的实例，降低了因为环境变化出错的风险。而这些部署及变更的过程，对用户来说只是更新代码，其复杂度相比使用容器及 Kubernetes 大大降低。Serverless 在扩展性方面也具有优势。FaaS 和 BaaS  对开发人员来说没有“预先计划容量”的概念，也不需要配置“自动扩展”触发器或规则。缩放由 Serverless  平台自动发生，无须开发人员干预。请求处理完成后，Serverless 平台会自动压缩计算资源，当面对突发流量时，Serverless  可以做到毫秒级扩容，保证及时响应。

基于 Serverless 的服务治理也更简单。例如，通过 API 网关服务可以对函数进行 SLA（服务水平协议）设置限流，函数请求出错后会自动重试，直至进入死信队列，开发者可以针对死信队列进行重放，最终保证请求得到处理。

Serverless 平台默认对接了监控、日志、调用链系统，开发者无须再费力单独维护运维的基础设施。虽然当前 Serverless  的监控指标并不如传统的监控指标丰富，但是其更关注的是应用的黄金指标，如延迟、流量、错误和饱和度。这样可以减少复杂的干扰信息，使开发者专注在用户体验相关的指标上。

### Serverless 的其他优点

除了以上的技术创新，Serverless 还有一些额外的优点。

- 加快交付的速度：函数的代码规模、测试规模相比微服务又降低了一个量级，可以更快地开发、验证及通过持续交付流水线发布。
- 全功能团队构建更加容易：微服务实施的关键之一在于全功能团队。全功能团队通常由不同角色（前后端开发人员、DevOps  等）组成。如果一段时间内前端开发任务较多，可能会出现前端开发人员不足导致交付延期的情况，反之亦然。采用全栈工程师是一个有效的解决方案，但这样的工程师比较稀缺，培养周期较长。Serverless 让前后端技术栈统一变得更简单，比如使用 Node.js、Swift、Flutter  等统一前后端技术，开发者从而可以使用一门技术实现前后端业务的开发，最终使团队效率倍增。

### Serverless 和微服务的差异

为了说明 Severless 开发与微服务开发的区别，表 1-1 对比了整个软件开发流程中微服务和 Serverless  在每个阶段的活动，从设计、开发、上线到持续服务，Serverless  相比微服务在开发难度及工作量上大幅降低，最终体现为更少的业务上线时间和更稳定的运行质量。

![图片](https://mmbiz.qpic.cn/mmbiz_png/qFG6mghhA4YsoZZzUkO1rKTGPzjvoXrsTrIkjWl1QM5J5byjXzCia9Pff9naB3RVprMaaGhNR8Y9nGGyzFwI5mQ/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)微服务和Serverless开发的差异