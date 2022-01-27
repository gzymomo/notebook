- [MongoDB使用实践：妈妈帮平台技术架构](https://mp.weixin.qq.com/s/0pWzLGSj3q3objAMPGnKEw)

> 在2017年3月12日下午于阿里巴巴西溪园区举行的MongoDB杭州用户交流会上，来自妈妈帮平台的开发总监胡兴邦给我们带来了《妈妈帮平台技术架构及MongoDB使用实践 》的分享，在演讲中他对比传统的关系型数据库，分析并总结出了MongoDB的优势和不足，以及实际使用中应注意的问题。

此次演讲的内容主要分为四个方面：

- 选择并使用Mongo的经历 
- MongoDB与关系数据型数据库的对比 
- MongoDB对开发和架构带来的影响 
- MongoDB的数据模型设计。

以下是本次演讲的整理内容：

## **一．早期对MySQL的使用**

![图片](https://mmbiz.qpic.cn/mmbiz_png/icNyEYk3VqGkn8fsz7GpZwZOIQfmf9IGC0Y6J0IvvKvABQ8OqGpibzrRSvXb0PINxSC6ibl7jcHbZCT4M1ddiaOH2g/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

早在2012年圣诞节上线的新系统中我们就开始全线使用Mongodb的数据库，而在那之前我们使用的数据库是传统的MySQL，因为它比较开源，性能稳定。在使用MySQL的几年中，我们针对使用过程中出现问题提出了一些解决方案：如利用分库分表解决数据量问题，利用“一主多从”的模式缓解访问压力等等。同时我们也研究了amoeba和mysql-proxy等中间件产品。尽管如此，使用MySQL运维的成本仍相对较大，因为在12年之前云产品还不是很丰富，很多中间件和MySQL的运维工作都需要自己去做，并且运行在自己的IDC上，无形之中增加了不少的成本。

## **二．现在的MongoDB集群架构**

![图片](https://mmbiz.qpic.cn/mmbiz_png/icNyEYk3VqGkn8fsz7GpZwZOIQfmf9IGCFzt9kcRolpqluAwUkW6pj7VIyfcQdvYcZD1OgeGn5qYB9aWGFQUgyw/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

从2012年使用MongoDB以来，目前部署的MongogDB集群的架构图如上：

- 左侧可用区B区：目前B区用来为MongoDB、整个IDC机房以及其他资源上云这个过程服务，其中最重要的一个环节就是MongoDB的上云。因为不像其他的应用服务器，如Python，Java等，这些资源都是对等、无状态的，所以比较容易上云，而在MongoDB上云的过程中我们则必须保障服务不被中断，否则后果严重。

- 右侧可用区A区：A区是现在主要的架构，为了缓解读写压力而采用了“一主四从”的模式。另一种“一主两从”的模式则主要用于线上业务，其中“一从”是供大数据分析部门做数据抽取使用， “另一从”则充当延时的节点，以防止数据被误删的情况。同时一些数据节点可以采用多台机器共用一个物理机方式以节约成本。

## **三．使用MongoDB的历史**

![图片](https://mmbiz.qpic.cn/mmbiz_png/icNyEYk3VqGkn8fsz7GpZwZOIQfmf9IGCL3EQHOeA6QoIhiaIBdkvGH8pRt6ibX4PTwY7gicOYibhljGJdTCxxaYRiaA/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)



使用MongoDB的历史大致可分为如下四个阶段：

- 早期使用MongoDB的过程比较简单，所有应用程序和数据库都运行在同一台机器上面。
- 紧接着随着应用量不断增加，出于成本的考虑我们做了主从。因为如果做复制集的话至少需要2N+1个节点，这在早期对资源和成本会带来不小的压力。
- 后面我们做了多组的主从和多组的复制集。这样做是迫于在早期版本的MongoDB中锁结构的性能相当不尽人意，它因为锁库会对数据库中表，比如回帖和发帖的表，进行频繁的数据读写。为了缓解这个库的读写压力以及锁的压力，我们按照业务逻辑对数据进行切分，例如我们会将某个话题库里面的回帖单独地抽取出来作为一个独立的组，然后再对组进行相应的操作。
- 之后在15年底我们做了Sharding。Sharding适用于处理数据量巨大的表，利用Sharding我们能够处理数据库中的回帖表，这个表中包含了接近3亿条回帖。目前我们一共部署了五个复制集群，其中只有回帖部分做了Sharding，其他部分都没有做Sharding。

## **四．青睐MongoDB理由**

![图片](https://mmbiz.qpic.cn/mmbiz_png/icNyEYk3VqGkn8fsz7GpZwZOIQfmf9IGC5xEtu0W3Hh2UGspUIuR4T1c2lCiaRCSn2hKib5T4V63jd8cqC8MlbVbQ/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)



选择MongoDB的理由很简单，而且也不完全是技术原因：

- 跳出关系型数据库很酷：这个想法由来已久，我们最早接触的非关系型数据库日本一个Key/Value数据库。那时它的数据结构相当简单，类型上没有Redis这么丰富，虽然运行效率还不错，但是对开发来说还有点变扭。不过它至少让我们第一次接触到了非关系型数据库。
- 很互联网：MongoDB的互联网基因很强，适合互联网公司。
- 设计基因里就考虑到分布式架构：不同于传统的关系型数据库如MySQL，MongoDB在设计的时候就考虑到了分布式，对于创业型公司来说这样的考虑可能可以降低一点后期的运维成本。

## **五．MongoDB与关系数据的优缺点对比**

![图片](https://mmbiz.qpic.cn/mmbiz_png/icNyEYk3VqGkn8fsz7GpZwZOIQfmf9IGCibkXOPvOVPvpSP10omFUXsfEmPRYxGUhyHvMXmq4ibnOo7HGOricTtGzA/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)



MongoDB和关系数据库的对比主要集中在MongoDB和MySQL的对比上，并且可以从schema、事务、稳定性、分布式和运维五大方面进行对比：

- schema：众所周知，MongoDB是非关系型数据库，里面基本不存在schema；而关系型数据库MySQL在这一方面则非常强。
- 事务：MongoDB的事务性相对比较弱，尽管有final-modify可以保证某些事务的一致性，但很难保证其他复杂事务的一致性；相比之下，MySQL比较完善一点。
- 稳定性：早期版本的MongoDB相当的不稳定，这一点MongoDB不如成熟的MySQL。
- 分布式：Mongo“天生骄傲”，从设计之初就考虑了分布式，而MySQL则折腾比较多。
- 运维：相对于MySQL，MongoDB的优势体现在它的便利性。在IDC上搭建MySQL往往费时费力。

## **六．无schema是一把双刃剑**

![图片](https://mmbiz.qpic.cn/mmbiz_png/icNyEYk3VqGkn8fsz7GpZwZOIQfmf9IGCmS2Sy7nXNTufPEGOeKG4tGkQ4BicT2RadOQds9bUyOLWoGnGLUHGC1Q/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

无Schema对开发的影响主要集中在以下四点：

- 对数据库、表、字段的添加极为方便：虽然它对于字段的添加、数据库或者数据表的创建非常开放，但与此同时，如果任何一个开发者不能合理地控制这一个过程的话，那么表的增长在后期将变得不可控。这个问题在开发的过程中显得尤为棘手，特别是出现当一个开发人员无意中添加了一个字段，而另外一个开发人员发现这个字段很好用却没有加索引这种严重的情况。这会对后期的运维造成一定的压力，这也是在程序设计中经常会面对的挑战。
- 数据模型设计随意性大：因为MongoDB没有schema。
- 给db运维带来了风险：基于前面两个原因，MongoDB有时会给运维带来一定的风险。
- 数据结构使用选择纠结：对一个刚刚接触MongoDB，对MongoDB不太熟悉的程序员来说，对数据的选择往往令人迷茫。例如，在MongoDb里面，bjson可以嵌套多层，可以嵌套数组，也可以嵌套对象，这样无疑使数据的选择变得更加宽泛，这对后期的整体架构会带来很多的坏处。

## **七．事务问题**

![图片](https://mmbiz.qpic.cn/mmbiz_png/icNyEYk3VqGkn8fsz7GpZwZOIQfmf9IGCCToA8KdXvF0EDZdz4qTiaSIjSvhRpqAdEwZbfdAmJzc8fWUBeuibz2Zg/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

以我们在实际使用中遇到的问题为例，社区虽然对事务性方面要求不是太高，但在某些场景下，确实需要关注对事务的处理：比如一个用户在某个话题下发了一个回帖，由于这个发帖的操作在后台可能涉及数据库，也可能跨复制集，所以不能完全保证事务一定成功。并且即使用户成功地回帖了，但也不能保证其个人中心页面下显示回帖总量被正确地更新。这里牵涉到事务处理的问题。

上述事务问题可以采用 1.后台定时修正 2.队列 3.二阶段提交  这三种解决方案。而我们大体上是基于后台定时修正这种方案来保障计数这个功能或是其他的事务。虽然后面两种技术方案目前都比较成熟，但从开发人员的对事务的理解以及对代码的维护性等角度来说过于复杂。因为有些事务和业务高度耦合，后两种方案往往不利于维护这些代码；而在后台定时修正这个方案中，它通过将所有代码都集中在这一块来简化修正这个过程，同时也允许选择性地修正对事务要求较高的那一部分，以尽量地避免事情发生。

## **八．事务问题中仍存在的不足之处**

![图片](https://mmbiz.qpic.cn/mmbiz_png/icNyEYk3VqGkn8fsz7GpZwZOIQfmf9IGCJpM7FVAhdeSTqalFpmcoaX28qoAjqjtBRJClw7hcrvG9OsfVd4A6uw/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

上述解决方案虽然在一定程度上能解决一些问题，但仍不够“完美”，这主要体现在：

- 与业务的耦合性高，很多业务点的保证是基于业务方的需求来做的。
- 代码重用和维护性都差。
- 对开发的要求高且增加复杂度和bug出现的几率。

## **九．MongoDB的稳定性问题**

MongoDB的稳定性问题主要集中在内存性能和系统升级这两方面：

内存不足时性能极其不稳定：在3.0版本之前MongoDB的性能都十分不稳定，特别是在开启内存文件映射引擎之后，一旦数据量和内存容量差不多的时候，这时系统中的数据会变得十分不稳定，产生的false非常多，队列读写操作也会变得异常，并且同时也会让排查错误这个过程在一定程度上变得更加困难。

一路升级：以我们在实际使用中升级MongoDB为例，因为使用得比较早，所以一路要升级。在2月底的时候，我们刚把MongoDB从2.6全线升级到了3.2.12，这次升级最大的变化就是config-server的升级，它的数据结构发生了改变，并且在运行的时候要对其进行数据的初始化。这个server以前是单镜像的，而现在官方希望实现复制集以保证多个镜像，但这么做缺点是如果有一个节点出现问题，那么config-server所拥有的写功能将不被允许，这就意味这用户只拥有读的功能，却不能做chunk的迁移，以及相关的balance的操作，所以说这个升级是相当的痛苦。2.2到2.6的版本升级对客户端的升级也是比较大的，其中2.6主要涉及一些在客户端命令方面的改动。而2.6到3.2的版本升级中最重要的升级是对WiredTiger引擎的升级，一般来说升级普通的组件还是比较容易，因为只需要升级相应的bin文件就可以了，但如果要升级它的WiredTiger引擎的话，那么所有数据都必须重新录入一遍的。在这个升级中我们一共花了两个周末的时间，前一个周末升级了一部分的集群，后一个周末升级了另外一个集群。

## **十．关于MongoDB分布式的总结**

![图片](https://mmbiz.qpic.cn/mmbiz_png/icNyEYk3VqGkn8fsz7GpZwZOIQfmf9IGCGc8FxTicibaP35m6BXoTAjBxiaJs1wCMSyQZicxc3HCRg0OYHvZFOMbCgg/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

关于MongoDB在分布式环境下的总结：

- 利用复制集解决单点的问题：这样无论任何一台机器宕机，也不会影响系统的整体性能。它可以支持MySQL所不具备的自动选主的功能。
- 使用Sharding解决数据容量的问题：当我们数据库表中保存的帖子总量超过两亿之后 ，一般的方法在这个查询方面显得尤为吃力，在实际使用中我们认为Sharding的性能还是比较令人满意的。

## **十一．片键选择很关键**

![图片](https://mmbiz.qpic.cn/mmbiz_png/icNyEYk3VqGkn8fsz7GpZwZOIQfmf9IGCh9Fq6cEHtFnMS2bSZOs6eD3P8TFfeiczurOZ5SCbabEP9NxZHmI8mtw/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

从开发的角度来看选片键十分重要，如果片键选得不好，那么这对之后的数据重新切分是很被动的，同时也会耗用大量运维的时间。片键选择的重要性体现在如下四个方面：

- 满足业务场景：在一般业务场景下，大部分的query都应当有对应的query-key。缺少query-key会导致的一个问题就是对mongos造成极大的压力。举个例子：我们当时就是因为上线时没有用好share-key而被迫放弃了一个业务，这个业务在上线时造成mongos出现流量异常的情况，流量非常大，甚至超过一个G，这导致了整个内网的瘫痪。最后追查下来发现是因为有个开发人员在查询的时候没有借助share-key，导致mongos要在各个sharding进行数据查询并汇总，最终导致对mongos产生巨大的压力。所以建议在业务场景尽量保证集中使用share-key。
- 避免负载不均匀：分片有两种，一种基于hash的，另一种基于range。有些场景不太适合range分片，比如在一条帖子后面追加发贴，这会给后面的sharding带来持续增长的压力。而如果基于hash分片的话，这样所有的压力都会被均匀地分摊到多个sharding上面去，从而减小了系统的负担。目前我们的发帖采用的正是hash这种方式，因为基于用户的角度来看，发帖不需要太多连续性的属性。
- 避免hash的稀疏导致chunk过大：比如说如果按照性别来进行hash，这是不太合理的。
- 官方推荐的做法：可以根据官方的文档考虑share-key的选择，并且结合自身的业务逻辑来判断是否负责自己的场景，并选择出最合理的方案。

## **十二．关于MongoDB运维的思考**



![图片](https://mmbiz.qpic.cn/mmbiz_png/icNyEYk3VqGkn8fsz7GpZwZOIQfmf9IGCcBiaDicONjXQ3VictXVZ9h7V0cicMej8XyefnC4sFfck7rjaFLlgHhYReA/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

针对运维自动化方面的不足，我们主要在以下五个方面进行优化：

- 基于rockmongo优化了权限控制：因为之前没有验证这一部分，所以给开发造成一定的不便，而尽管后面增加了验证部分，但权限控制的力度仍然不够，这使得我们有时在运维开发中不得不去线上query这些数据。针对这一问题我们基于rockmongo做了二次开发，集中优化了权限控制这一部分，使其基本上能控制collection这一级别。
- 监控数据库和表的增长：由于开发环境中不存在schema，所以有可能导致数据库表或是connection的增长不可控，为此我们做了实现了一个监控服务，这个服务能时刻监视client下面数据的增长。举个例子：一个业务的数据量原本被设计为每天增长十万，但突然间这个业务发展迅猛，数据量猛增到了一千万，这时就要快速发现并确定采用是采用sharding的技术还是通过应用层分库分表来缓解数据库压力，避免因为数据的增长而导致内存耗尽，给运维带来不稳定性。因此通过监控这些数据，我们能迅速发现异常的数据表或是connection，并且会与业务方及时沟通，然后进行优化。
- 大表加索引：不同于background这种做法，  当超过100万时我们会采用官方的滚动加索引的方式，只对在线用户需要用到的表加索引，并且白天时间是不加索引的。采用Background这种方式加索引固然有它的好处，它可以不影响业务，并且保持这台机器不下线，但缺点是在加索引的过程中不能高效地利用内存资源。相反，如果使用滚动加索引，我们可以在复制集中暂停一台机器，让它全心全意地加索引，这样处理效率比较高，能很快地保证索引加完，并且时间比较可控，比如可以在晚上加索引，然后立马进行上线，最后挂载到复制集下面去。因此在超过100万数据时，我们不会业务线上是对其加索引。
- 兼容性的总结：包括对客户端的总结，其中有很多对业务影响比较大的改动。
- 费机器：以复制集为例，一个复制集往往需要2N+1台机器来支撑，并且这些机器最好是对等的，以支持业务的发展。我们每次增加机器至少都是三台，因为这些业务对内存的需求特别大。所以我们在创业的时候，架构也在相应地不断变迁，从主从到复制集，到复制集，然后到sharding。这也是处于成本的考虑。 

## **十三．数据模型设计**

![图片](https://mmbiz.qpic.cn/mmbiz_png/icNyEYk3VqGkn8fsz7GpZwZOIQfmf9IGC6tgFCEdmluH1O9aPZpqE34DqXryh9B8b7QUSefgyt33YUKNP7E1mFQ/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

### One-to-one

关系型数据库总结起来主要包括一对一、一对多和多对多等关系型数据模型。在one to one  关系中如果有id、name以及其他的附属信息需要处理时，一般关系型数据库的做法是设计成左边的两张表，而非关系型数据库则设计成右边的一个Document。如果设计成左边的两张，那么当更新数据时必须要更新这两张表，此时如果发生一个表更新操作成功而另一表可失败的情况，这就会造成数据的不一致，如果发生了数据不一致，是否采取回滚还涉及到事务的问题。遇到这种情况相对来讲可以比较容易地解决，例如让用户进行重试，但对于某些复杂的操作来说，实现回滚是比较困难的。所以如果按照右边的方案设计一个document，并且在里面建索引，这种情况能到到有效缓解。

![图片](https://mmbiz.qpic.cn/mmbiz_png/icNyEYk3VqGkn8fsz7GpZwZOIQfmf9IGCWMkOdwreKY89Ug2xUGr3iaMCEUBZcnv6RoaCSKSw0Liapw8x9Nvnb5nQ/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

### One-to-many

在one to many关系中，关系型数据库可以设计成利用主键来关联两个表，而右边的非关系数据库则是采用数组来进行存放，但当数据中元素比较多时，还是不建议这样做，因为它在后期容易使得对数据库的各种操作变得复杂。

## **十四．数据模型设计**

![图片](https://mmbiz.qpic.cn/mmbiz_png/icNyEYk3VqGkn8fsz7GpZwZOIQfmf9IGCcgpibx8h6Q4Z8WU7tSTE43icKar6ub6MJxaEZjDx6R6KYOP4TSz1cghw/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

个人关于数据模型的三条总结：

- 优先使用单一的Document来进行存储：尽量保证数据是在一个Document里面的存储，这样一来能减轻了很多事务方面的问题。
- 灵活选择常规的collectoin或是滚动的collection：因为在有些业务场景中确实是不需要长时间地保存业务数据，比如记录管理员的操作或是用户的操作行为，这些并不需要被一直保留，我们可以把一百万或是一千万条数据临时保留三个月就可以了，在这之后我们对些数据也不会追查这么久。
- 借助数组、字典等数据类型：这些数据结构往往能够解决许多业务场景中出现的比较特殊的情况，这些都是MongoDB中用到的比较优秀的特性。

## **十五．最后的建议**

![图片](https://mmbiz.qpic.cn/mmbiz_png/icNyEYk3VqGkn8fsz7GpZwZOIQfmf9IGCCc2N0xgJyRnaKmLFTfWr0jT3FYxIZIDAnICd27QHGBl5nrXGqbKtww/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

用了这么多年的mongo，我想给那些准备或是将来打算使用MongoDB的程序员提一些建议：

- 如果对事务要求确实比较严格的话，建议慎用MongoDB：比如如果通过一个zone-keeper搭建一个分布事务，使用MongoDB在运维方面可能会让人感觉起来比较费力，同时开发起来也比较费劲。因此在事务要求比较多的情况下还是建议使用传统的数据库，当然也可以选择现有的云存储或是阿里RDS，目前这些产品都比较成熟了。
- 后期难以和传统的数据库互相转换：我们在开发的后期阶段有一段时间是想把MongoDB转化为MySQL的，之后再转换到阿里云的RDS上面去，但后来这个想法直接被放弃了。原因很简单：因为数据库转换十分复杂麻烦，它可能会涉及到嵌套的问题，可能包括是一对多的关系，这样分离起来比较麻烦。
- 提前考虑，避免无schema带来的混乱问题：如果你想使用Mongodb或是想避免schema的话，最好在数据的前期对你的model进行严格的限制。比如在前期有一个数据bjson对象，或是一个数组，那么在前期一定要仔细验证这个数据结构，避免后期出现结构数据方面的异常，因为在对数据类型比较严格环境中，对于这些数据访问的可能会产生一些异常。因此如果前期考虑不足，这会使后面开发和数据校验以及修复的过程复杂化。
- 多看官方文档，积极升级：相对于其他来源的文档，官方文档写得还是十分详实的，包括一些数据升级、数据加索引以及各个方面的内容官方都提供了详细的操作文档，所以目前我们基本上所有的操作也都是基于官方的文档。另外积极升级也很重要，举个例子，通过升级2.6到3.2wired-Tiger引擎，我们内存的使用情况和数据压缩情况都大大得到了缓解，而在升级之前我们是用的内存映射引擎，这比较消耗内存，所以当时我们的机器都配置了196G的内存。