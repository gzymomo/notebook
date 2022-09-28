- [Seatunnel-国产开源数据集成平台-Apache全票通过孵化器项目 - 掘金 (juejin.cn)](https://juejin.cn/post/7048058543290712071)

![SeaTunnelEng.jpg](https://p1-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/ff56374b9cc5465cb13039b002581c2e~tplv-k3u1fbpfcp-zoom-in-crop-mark:3024:0:0:0.awebp?)



SeaTunnel 是一个非常易用、高性能、支持实时流式和离线批处理的海量数据集成平台，架构于 Apache Spark 和 Apache Flink 之上，支持海量数据的实时同步与转换

- 使用 Spark、Flink 作为底层数据同步引擎使其具备分布式执行能力，提高数据同步的吞吐性能
- 集成多种能力缩减 Spark、Flink 应用到生产环境的周期与复杂度
- 利用可插拔的插件体系支持超过 100 种数据源
- 引入管理与调度能力做到自动化的数据同步任务管理
- 特定场景做端到端的优化提升数据同步的数据一致性
- 开放插件化与 API 集成能力帮助企业实现快速定制与集成

```css
                     工作流程：Input[数据源输入] -> Filter[数据处理] -> Output[结果输出]
```

# 应用场景

- 海量数据同步
- 海量数据集成
- 海量数据的 ETL
- 海量数据聚合
- 多源数据处理

# 生产应用案例

- [微博](https://link.juejin.cn?target=https%3A%2F%2Fgitee.com%2Flink%3Ftarget%3Dhttps%3A%2F%2Fweibo.com), 增值业务部数据平台 微博某业务有数百个实时流式计算任务使用内部定制版 SeaTunnel，以及其子项目[Guardian](https://link.juejin.cn?target=https%3A%2F%2Fgitee.com%2Flink%3Ftarget%3Dhttps%3A%2F%2Fgithub.com%2FInterestingLab%2Fguardian) 做 seatunnel On Yarn 的任务监控。
- [新浪](https://link.juejin.cn?target=https%3A%2F%2Fgitee.com%2Flink%3Ftarget%3Dhttp%3A%2F%2Fwww.sina.com.cn%2F), 大数据运维分析平台 新浪运维数据分析平台使用 SeaTunnel 为新浪新闻，CDN 等服务做运维大数据的实时和离线分析，并写入 Clickhouse。
- [搜狗](https://link.juejin.cn?target=https%3A%2F%2Fgitee.com%2Flink%3Ftarget%3Dhttp%3A%2F%2Fsogou.com%2F) ，搜狗奇点系统 搜狗奇点系统使用 SeaTunnel 作为 ETL 工具, 帮助建立实时数仓体系
- [趣头条](https://link.juejin.cn?target=https%3A%2F%2Fgitee.com%2Flink%3Ftarget%3Dhttps%3A%2F%2Fwww.qutoutiao.net%2F) ，趣头条数据中心 趣头条数据中心，使用 SeaTunnel 支撑 mysql to hive 的离线 ETL 任务、实时 hive to clickhouse 的 backfill 技术支撑，很好的 cover 离线、实时大部分任务场景。
- [一下科技](https://link.juejin.cn?target=https%3A%2F%2Fgitee.com%2Flink%3Ftarget%3Dhttps%3A%2F%2Fwww.yixia.com%2F), 一直播数据平台
- 永辉超市子公司-永辉云创，会员电商数据分析平台 SeaTunnel 为永辉云创旗下新零售品牌永辉生活提供电商用户行为数据实时流式与离线 SQL 计算。
- 水滴筹, 数据平台 水滴筹在 Yarn 上使用 SeaTunnel 做实时流式以及定时的离线批处理，每天处理 3～4T 的数据量，最终将数据写入 Clickhouse。