# 背景 

对很多人来说，未知、不确定、不在掌控的东西，会有潜意识的逃避。当我第一次接触 Prometheus 的时候也有类似的感觉。对初学者来说， Prometheus 包含的概念太多了，门槛也太高了。

> 概念：Instance、Job、Metric、Metric Name、Metric Label、Metric Value、Metric Type（Counter、Gauge、Histogram、Summary）、DataType（Instant Vector、Range Vector、Scalar、String）、Operator、Function

马云说：“虽然阿里巴巴是全球最大的零售平台，但阿里不是零售公司，是一家数据公司”。Prometheus 也是一样，本质来说是一个基于数据的监控系统。

# 日常监控

假设需要监控 WebServerA 每个API的请求量为例，需要监控的维度包括：服务名（job）、实例IP（instance）、API名（handler）、方法（method）、返回码(code)、请求量（value）。

![img](https://mmbiz.qpic.cn/mmbiz_png/JdLkEI9sZff6g91Tpu8esnrLn2SMCkyHenx6P0VrpC6xRr913YWghX2X5SOsyWXziakWEE0tpmbM3xk5ABeiabhg/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)promql

如果以SQL为例，演示常见的查询操作：

1. 查询 method=put 且 code=200 的请求量(红框)

   > SELECT * from http_requests_total WHERE code=”200” AND method=”put” AND created_at BETWEEN 1495435700 AND 1495435710;

2. 查询 handler=prometheus 且 method=post 的请求量(绿框)

   > SELECT * from http_requests_total WHERE handler=”prometheus” AND method=”post” AND created_at BETWEEN 1495435700 AND 1495435710;

3. 查询 instance=10.59.8.110 且 handler 以 query 开头 的请求量(绿框)

   > SELECT * from http_requests_total WHERE handler=”query” AND instance=”10.59.8.110” AND created_at BETWEEN 1495435700 AND 1495435710;

通过以上示例可以看出，在常用查询和统计方面，日常监控多用于根据监控的维度进行查询与时间进行组合查询。**如果监控100个服务，平均每个服务部署10个实例，每个服务有20个API，4个方法，30秒收集一次数据，保留60天。那么总数据条数为：100(服务)\* 10（实例）\* 20（API）\* 4（方法）\* 86400（1天秒数）\* 60(天) / 30（秒）= 138.24 亿条数据，写入、存储、查询如此量级的数据是不可能在Mysql类的关系数据库上完成的**。因此 Prometheus 使用 TSDB 作为 存储引擎

# 存储引擎

TSDB 作为 Prometheus 的存储引擎完美契合了监控数据的应用场景

- 存储的数据量级十分庞大
- 大部分时间都是写入操作
- 写入操作几乎是顺序添加，大多数时候数据到达后都以时间排序
- 写操作很少写入很久之前的数据，也很少更新数据。大多数情况在数据被采集到数秒或者数分钟后就会被写入数据库
- 删除操作一般为区块删除，选定开始的历史时间并指定后续的区块。很少单独删除某个时间或者分开的随机时间的数据
- 基本数据大，一般超过内存大小。一般选取的只是其一小部分且没有规律，缓存几乎不起任何作用
- 读操作是十分典型的升序或者降序的顺序读
- 高并发的读操作十分常见

那么 TSDB 是怎么实现以上功能的呢？

```
"labels": [{
 "latency":        "500"
}]
"samples":[{
 "timestamp": 1473305798,
 "value": 0.9
}]
```

原始数据分为两部分 label, samples。前者记录监控的维度（标签:标签值），指标名称和标签的可选键值对唯一确定一条时间序列（使用 series_id 代表）；后者包含包含了时间戳（timestamp）和指标值（value）。

```
series
^
│. . . . . . . . . . . .   server{latency="500"}
│. . . . . . . . . . . .   server{latency="300"}
│. . . . . . . . . .   .   server{}
│. . . . . . . . . . . .
v
<-------- time ---------->
```

TSDB 使用 timeseries:doc:: 为 key 存储 value。为了加速常见查询查询操作：label 和 时间范围结合。TSDB 额外构建了三种索引：`Series`, `Label Index` 和 `Time Index`。

以标签 `latency` 为例：

- Series

  > 存储两部分数据。一部分是按照字典序的排列的所有标签键值对序列（series）；另外一部分是时间线到数据文件的索引，按照时间窗口切割存储数据块记录的具体位置信息，因此在查询时可以快速跳过大量非查询窗口的记录数据

- Label Index

  > 每对 label 为会以 index:label: 为 key，存储该标签所有值的列表，并通过引用指向 `Series` 该值的起始位置。

- Time Index

  > 数据会以 index:timeseries:: 为 key，指向对应时间段的数据文件

# 数据计算

强大的存储引擎为数据计算提供了完美的助力，使得 Prometheus 与其他监控服务完全不同。Prometheus 可以查询出不同的数据序列，然后再加上基础的运算符，以及强大的函数，就可以执行 `metric series` 的矩阵运算（见下图）。

![img](https://mmbiz.qpic.cn/mmbiz_png/JdLkEI9sZff6g91Tpu8esnrLn2SMCkyHHxpXibG4ib6S7EwIJoOPwAGXImUCsib0yfxv9DQhXnOdmPSxR8qydPywQ/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)time series matrix

如此，Promtheus体系的能力不弱于监控界的“数据仓库”+“计算平台”。因此，在大数据的开始在业界得到应用，就能明白，这就是监控未来的方向。

# 一次计算，处处查询

当然，如此强大的计算能力，消耗的资源也是挺恐怖的。因此，查询预计算结果通常比每次需要原始表达式都要快得多，尤其是在仪表盘和告警规则的适用场景中，仪表盘每次刷新都需要重复查询相同的表达式，告警规则每次运算也是如此。因此，Prometheus提供了 Recoding rules，可以预先计算经常需要或者计算量大的表达式，并将其结果保存为一组新的时间序列， 达到 一次计算，多次查询 的目的