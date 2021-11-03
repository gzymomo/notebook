# Apache拯救世界之数据质量监控工具 - Apache Griffin

#### **概述**

Apache Griffin定位为大数据的数据质量监控工具，支持批处理数据源hive、text文件、avro文件和实时数据源kafka，而一些以关系型[数据库](https://cloud.tencent.com/solution/database?from=10680)如[mysql](https://cloud.tencent.com/product/cdb?from=10680)、oracle为存储的项目也同样需要可配置化的数据质量监控工具，所以扩展griffin的mysql数据源就可以为项目的数据质量监控提供多一种选择。

Griffin是属于模型驱动的方案，基于目标数据集合或者源数据集(基准数据)，用户可以选择不同的数据质量维度来执行目标数据质量的验证。支持两种类型的数据源：

- batch数据：通过数据连接器从Hadoop平台收集数据
- streaming数据：可以连接到诸如Kafka之类的消息系统来做近似实时数据分析

#### **特性**

- 度量：精确度、完整性、及时性、唯一性、有效性、一致性。
- 异常监测：利用预先设定的规则，检测出不符合预期的数据，提供不符合规则数据的下载。
- 异常告警：通过邮件或门户报告数据质量问题。
- 可视化监测：利用控制面板来展现数据质量的状态。
- 实时性：可以实时进行数据质量检测，能够及时发现问题。
- 可扩展性：可用于多个数据系统仓库的数据校验。
- 可伸缩性：工作在大数据量的环境中，目前运行的数据量约1.2PB(eBay环境)。
- 自助服务：Griffin提供了一个简洁易用的用户界面，可以管理数据资产和数据质量规则；同时用户可以通过控制面板查看数据质量结果和自定义显示内容。

#### **Griffin的系统架构**

在Griffin的架构中，主要分为Define、Measure和Analyze三个部分，如下图所示：

![img](https://ask.qcloudimg.com/http-save/yehe-4933406/sw7myu4vwp.png?imageView2/2/w/1620)

各部分的职责如下：

- Define：主要负责定义数据质量统计的维度，比如数据质量统计的时间跨度、统计的目标（源端和目标端的数据数量是否一致，数据源里某一字段的非空的数量、不重复值的数量、最大值、最小值、top5的值数量等）
- Measure：主要负责执行统计任务，生成统计结果
- Analyze：主要负责保存与展示统计结果

Griffin 系统主要分为：数据收集处理层（Data Collection&Processing Layer）、后端服务层（Backend Service Layer）和用户界面（User Interface），如图：

![img](https://ask.qcloudimg.com/http-save/yehe-4933406/udsgbnql4r.png?imageView2/2/w/1620)

系统数据处理分层结构图：

![img](https://ask.qcloudimg.com/http-save/yehe-4933406/1wr1w1m585.png?imageView2/2/w/1620)

系统处理流程图：

![img](https://ask.qcloudimg.com/http-save/yehe-4933406/u233dmsgdf.png?imageView2/2/w/1620)

基于以上功能，大数据平台可以考虑引入Griffin作为数据质量解决方案，实现数据一致性检查、空值统计等功能。Apache Giffin目前的数据源包括HIVE, CUSTOM, AVRO, KAFKA。Mysql和其他[关系型数据库](https://cloud.tencent.com/product/cdb-overview?from=10680)的扩展根据需要进行扩展。

#### **安装部署**

Griffin的安装和部署需要以下环境：

- JDK (1.8 or later versions)
- MySQL(version 5.6及以上)
- Hadoop (2.6.0 or later)
- Hive (version 2.x)
- Spark (version 2.2.1)
- Livy（livy-0.5.0-incubating）
- ElasticSearch (5.0 or later versions)

具体的安装步骤可以参考官网：http://griffin.apache.org/docs/quickstart-cn.html

在这里我使用源码编译打包的方式来部署Griffin，Griffin的源码地址是：https://github.com/apache/griffin.git 这里我使用的源码tag是griffin-0.4.0，下载完成在idea中导入并展开源码的结构图如下：

![img](https://ask.qcloudimg.com/http-save/yehe-4933406/p4qrjtlvq7.png?imageView2/2/w/1620)

Griffin的源码结构很清晰，主要包括griffin-doc、measure、service和ui四个模块，其中griffin-doc负责存放Griffin的文档，measure负责与spark交互，执行统计任务，service使用spring boot作为服务实现，负责给ui模块提供交互所需的restful api，保存统计任务，展示统计结果。

#### **Hello Griffin！**

这里我们用官网的一个案例入门：

**首先**在hive里创建表demo_src和demo_tgt：

```javascript
--create hive tables here. hql script
--Note: replace hdfs location with your own path
CREATE EXTERNAL TABLE `demo_src`(
  `id` bigint,
  `age` int,
  `desc` string) 
PARTITIONED BY (
  `dt` string,
  `hour` string)
ROW FORMAT DELIMITED
  FIELDS TERMINATED BY '|'
LOCATION
  'hdfs:///griffin/data/batch/demo_src';

--Note: replace hdfs location with your own path
CREATE EXTERNAL TABLE `demo_tgt`(
  `id` bigint,
  `age` int,
  `desc` string) 
PARTITIONED BY (
  `dt` string,
  `hour` string)
ROW FORMAT DELIMITED
  FIELDS TERMINATED BY '|'
LOCATION
  'hdfs:///griffin/data/batch/demo_tgt';
```

**然后**生成测试数据：

从http://griffin.apache.org/data/batch/ 地址下载所有文件到Hadoop服务器上，然后使用如下命令执行gen-hive-data.sh脚本：nohup ./gen-hive-data.sh>gen.out 2>&1 & 注意观察gen.out日志文件，如果有错误，视情况进行调整。这里我的测试环境Hadoop和Hive安装在同一台服务器上，因此直接运行脚本。

**最后**通过UI界面创建统计任务，具体按照Apache Griffin User Guide 一步步操作，地址在这里：https://github.com/apache/griffin/blob/master/griffin-doc/ui/user-guide.md

此外，我还在其他博主的博客中看到一个更为复杂的案例如下，大家可以在参考链接中找到：

以检测供应商账单明细表的同步精确度为例，配置数据检测，如图：

- 选择数据源

![img](https://ask.qcloudimg.com/http-save/yehe-4933406/zcr3e8p0f8.png?imageView2/2/w/1620)

- 选择账单明细源表字段

![img](https://ask.qcloudimg.com/http-save/yehe-4933406/r9xaiu7l8u.png?imageView2/2/w/1620)

- 选择账单明细目标表字段

![img](https://ask.qcloudimg.com/http-save/yehe-4933406/gc4tyudj43.png?imageView2/2/w/1620)

- 设置源表和目标表的校验字段映射关系

![img](https://ask.qcloudimg.com/http-save/yehe-4933406/eb7nreez0r.png?imageView2/2/w/1620)

- 选择数据分区、条件和是否输出结果文件。（无分区表可以跳过）

![img](https://ask.qcloudimg.com/http-save/yehe-4933406/4g4mnngymq.png?imageView2/2/w/1620)

- 设置验证项目名称和描述，提交后就可以在列表看到度量的信息了

![img](https://ask.qcloudimg.com/http-save/yehe-4933406/4h0626htnc.png?imageView2/2/w/1620)

![img](https://ask.qcloudimg.com/http-save/yehe-4933406/8iutsllwla.png?imageView2/2/w/1620)

创建了数据模型度量后，需要相应的spark定时任务来执行分析，接下来就是创建spark job和调度信息了

- 在job菜单下，选择Create Job

![img](https://ask.qcloudimg.com/http-save/yehe-4933406/fcpeggwnh4.png?imageView2/2/w/1620)

创建job界面中需要选择源表和目标表数据范围，如上图所示是选择t-1到当前的数据分区，即昨天的数据分区。设置定时表达式，提交任务后即可在job列表中查看：

![img](https://ask.qcloudimg.com/http-save/yehe-4933406/pyelsb0dve.png?imageView2/2/w/1620)

到这里，数据验证度量和分析任务都已配置完成，后面还可根据你的指标设置邮件告警等监控信息，接下来就可以在控制面板上监控你的数据质量了，如图：

![img](https://ask.qcloudimg.com/http-save/yehe-4933406/cxy8acbu93.png?imageView2/2/w/1620)

#### **总结**

用好Griffin的前提是熟悉下面的技术栈，大家看到了基本都是Apache全家桶：

- Spark
- Hadoop
- Hive
- Livy
- Quartz

此外，在调研过程中也发现了一些已知的问题:

1. 目前Apache Giffin目前的数据源是支持HIVE,TXT，文件，avro文件和实时数据源 Kafka，Mysql和其他关系型数据库的扩展需要自己进行扩展
2. Apache Griffin进行Mesausre生成之后，会形成Spark大数据执行规则模板，shu的最终提交是交给了Spark执行，需要懂Spark进行扩展
3. Apache Griffin中的源码中，只有针对于接口层的数据使用的是Spring Boot，measure关于Spark定时任务的代码为scala 语言，扩展的时候需要在measure中进行扩展，需要了解一下对应的scala脚本。

我们在后续的文章中会给出一篇使用Griffin的实战案例，欢迎关注。

#### 大家还可以参考：

https://blog.csdn.net/vipshop_fin_dev/article/details/86362706 

https://blog.csdn.net/zcswl7961/article/details/101479637