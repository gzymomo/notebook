- [InfluxDB 通识篇](https://juejin.cn/post/6947575345570643981)

# 一、为什么需要时序数据库？

随着物联网和大数据时代的到来，全球每天产生的数据量大到令人难以想象。这些数据受到业务场景的限制分为不同的种类，每个种类对存储都有不同的要求。单凭传统的 RDBMS 很难完成各种复杂场景下的数据存储。

这时我们就需要根据不同的数据特性和业务场景的要求，选择不同的数据库。

一般选择使用哪个数据库，要从低响应时间（Low Response Time）、高可用性（High Availability）、高并发（High Concurrency）、海量数据（Big Data）和可承担成本（Affordable Cost）五个维度去权衡。

数据库的种类非常繁多，举几个常见的类型来对比一下各自的特点。

关系型数据库主流代表有 MySQL、Oracle 等，优点是具有 ACID 的特性，各方面能力都比较均衡。缺点是查询、插入和修改的性能都很一般。

KV 数据库主流带代表有 Redis、Memcached 等，优点是存储简单、读写性能极高。缺点是存储成本非常高，不适合海量数据存储。

文档型数据库最流行的是 MongoDB，相比 MySQL，数据结构灵活、更擅长存储海量数据，在海量数据的场景下读写性能很强。缺点是占用空间会很大。

搜索引擎数据库最流行的是 ElasticSearch，非常擅长全文检索和复杂查询，性能极强，并且天生集群。缺点是写入性能低、字段类型无法修改、硬件资源消耗严重。

而时序数据库，最初诞生的目的很大程度上是在对标 MongoDB，因为在时序数据库出现之前，存储时序数据这项领域一直被 MongoDB 所占据。

时序数据库一哥 InfluxDB 的公司 InfluxData，曾在 2018 年发表了一篇关于 [InfluxDB vs MongoDB 的博客](https://link.juejin.cn?target=https%3A%2F%2Fwww.influxdata.com%2Fblog%2Finfluxdb-is-27x-faster-vs-mongodb-for-time-series-workloads%2F)。

文中使用 InfluxDB v1.7.2 和 MongoDB v4.0.4 做对比，得出 InfluxDB 比 MongoDB 快 2.4 倍的结论。当然可信度有待考量。

总之，时序数据库的特点是：持续高性能写入、高性能查询、低存储成本、支持海量时间线、弹性。

# 二、InfluxDB 简介

InfluxDB 是 InfluxData 公司在 2013 年开源的数据库，是为了存储物联网设备、DevOps 运维这类场景下大量带有时间戳数据而设计的。

InfluxDB 源码采用 Go 语言编写，在 InfluxDB OSS 的版本中，部署方式上又分为两个版本，单机版和集群版。单机版开源，目前在 [github](https://link.juejin.cn?target=https%3A%2F%2Fgithub.com%2Finfluxdata%2Finfluxdb) 上有 21k+ star。

<font color='red'>集群版闭源，走商业路线。</font>

个人认为单机版的 InfluxDB 比较鸡肋。因为一旦选择使 InfluxDB，那么数据量肯定一定达到了某个很高的程度。这时候必须使用集群版。而在数据量不够高的情况下，InfluxDB 并不会比 MongoDB 或者 ElasticSearch 有更明显的优势。

