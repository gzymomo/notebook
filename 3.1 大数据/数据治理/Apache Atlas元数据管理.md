- [数据治理---Apache Atlas元数据管理_开着拖拉机回家的博客-CSDN博客_atlas数据治理](https://blog.csdn.net/qq_35995514/article/details/107395181)

# 一、概念背景介绍

## 1.1 概述

​    面对海量且持续增加的各式各样的数据对象，你是否有信心知道哪些数据从哪里来以及它如何随时间而变化？采用[Hadoop](https://so.csdn.net/so/search?q=Hadoop&spm=1001.2101.3001.7020)必须考虑数据管理的实际情况，元数据与数据治理成为企业级数据湖的重要部分。

为寻求[数据治理](https://so.csdn.net/so/search?q=数据治理&spm=1001.2101.3001.7020)的开源解决方案，Hortonworks 公司联合其他厂商与用户于2015年发起数据治理倡议，包括数据分类、集中策略引擎、数据血缘、安全和生命周期管理等方面。Apache Atlas 项目就是这个倡议的结果，社区伙伴持续的为该项目提供新的功能和特性。***\*该项目用于管理共享元数据、数据分级、审计、安全性以及数据保护等方面，努力与Apache Ranger整合，用于数据权限控制策略。\****

[Apache](https://so.csdn.net/so/search?q=Apache&spm=1001.2101.3001.7020) Atlas是hadoop的数据治理和元数据框架，它提供了一个可伸缩和可扩展的核心基础数据治理服务集，使得企业可以有效和高效的满足Hadoop中的合规性要求，并允许与整个企业的数据生态系统集成：

![img](https://img-blog.csdnimg.cn/20200716220359267.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzM1OTk1NTE0,size_16,color_FFFFFF,t_70)

## 1.2 核心特性

Apache Atlas为Hadoop的元数据治理提供了以下特性：

-  ***\*数据分类\****

 \- 为元数据导入或定义业务导向的分类注释

 \- 定义，注释，以及自动捕获数据集和底层元素之间的关系

 \- 导出元数据到第三方系统

- ***\*集中审计\****

 \- 捕获与所有应用，过程以及与数据交互的安全访问信息

 \- 捕获执行，步骤，活动等操作的信息

- ***\*搜索与血缘\****

 \- 预定义的导航路径用来探索数据分类以及审计信息

 \- 基于文本的搜索特性来快速和准确的定位相关联的数据和审计事件

 \- 对数据集血缘关系的可视化浏览使用户可以下钻到操作，安全以及数据起源相关的信息

- ***\*安全与策略引擎\****

 \- 基于数据分类模式，属性以及角色的运行时合理合规策略

 \- 基于分类-预测的高级策略定义以防止数据推导

 \- 基于cell的属性和值的行/列级别的masking

## 1.3Atlas的组件

![img](https://img-blog.csdnimg.cn/20200716221015283.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzM1OTk1NTE0,size_16,color_FFFFFF,t_70)

- \*\*Core\*\*\*\*\****

​    \- ***\*Type System\****: Atlas 允许用户为他们想要管理的元数据对象定义一个模型。该模型由称为 "类型" 的定义组成。***\*"类型" 的 实例被称为 "实体" 表示被管理的实际元数据对象\****。类型系统是一个组件，允许用户定义和管理类型和实体。由 Atlas 管理的所有元数据对象（例如Hive表）都使用类型进行建模，并表示为实体。要在 Atlas 中存储新类型的元数据，需要了解类型系统组件的概念。

​    - Ingest/Export：Ingest 组件允许将***\*元数据添加到 Atlas\****。类似地，Export 组件暴露由 Atlas 检测到的元数据更改，以作为事件引发，消费者可以使用这些更改事件来实时响应元数据更改。

​    - Graph Engine：在内部，Atlas 通过使用***\*图形模型管理元数据对象\****。以实现元数据对象之间的巨大灵活性和丰富的关系。图形引擎是负责在类型系统的类型和实体之间进行转换的组件，以及基础图形模型。除了管理图形对象之外，图形引擎还为元数据对象创建适当的索引，以便有效地搜索它们。

​    - Titan：目前，Atlas 使用 Titan 图数据库来存储元数据对象。 Titan 使用两个存储：***\*默认情况下元数据存储配置为 HBase ，索引存储配置为 Solr\****。也可以通过构建相应的配置文件使用BerkeleyDB存储元数据存储 和使用ElasticSearch存储 Index。元数据存储用于存储元数据对象本身，索引存储用于存储元数据属性的索引，其允许高效搜索。

- Integration

用户可以使用两种方法管理 Atlas 中的元数据：

 - API： Atlas 的所有功能都可以通过 REST API 提供给最终用户，允许创建，更新和删除类型和实体。它也是查询和发现通过 Atlas 管理的类型和实体的主要方法。

 - Messaging：除了 API 之外，用户还可以选择使用基于 Kafka 的消息接口与 Atlas 集成。这对于将元数据对象传输到 Atlas 以及从 Atlas 使用可以构建应用程序的元数据更改事件都非常有用。如果希望使用与 Atlas 更松散耦合的集成，这可以允许更好的可扩展性，可靠性等，消息传递接口是特别有用的。Atlas 使用 Apache Kafka 作为通知服务器用于钩子和元数据通知事件的下游消费者之间的通信。事件由钩子(hook)和 Atlas 写到不同的 Kafka 主题:

​    - ATLAS_HOOK: 来自各个组件的Hook 的元数据通知事件通过写入到名为 ATLAS_HOOK 的 Kafka topic 发送到 Atlas

​    - ATLAS_ENTITIES：从 Atlas 到其他集成组件（如Ranger）的事件写入到名为 ATLAS_ENTITIES 的 Kafka topic

![img](https://img-blog.csdnimg.cn/20200716222005403.png)

- Metadata source

   ***\*- Hive\****：通过hive bridge， atlas可以接入Hive的元数据，包括hive_db/hive_table/hive_column/hive_process

   ***\*- Sqoop：\****通过sqoop bridge，atlas可以接入关系型数据库的元数据，包括sqoop_operation_type/ sqoop_dbstore_usage/sqoop_process/sqoop_dbdatastore

   ***\*- Falcon：\****通过falcon bridge，atlas可以接入Falcon的元数据，包括falcon_cluster/falcon_feed/falcon_feed_creation/falcon_feed_replication/ falcon_process

   ***\*- Storm：\****通过storm bridge，atlas可以接入流式处理的元数据，包括storm_topology/storm_spout/storm_bolt

   **- HBase:** 通过hbase bridge

 ***\*Atlas集成大数据组件的元数据源需要实现以下两点：\****

  \- 首先，需要基于atlas的类型系统定义能够表达大数据组件元数据对象的元数据模型(例如Hive的元数据模型实现在org.apache.atlas.hive.model.HiveDataModelGenerator)；

  \- 然后，需要提供hook组件去从大数据组件的元数据源中提取元数据对象，实时侦听元数据的变更并反馈给atlas；

- ***\*Applications\****

 ***\*- Atlas Admin UI\**:** 该组件是一个基于 Web 的应用程序，允许数据管理员和科学家发现和注释元数据。Admin UI提供了搜索界面和类SQL的查询语言，可以用来查询由 Atlas 管理的元数据类型和对象。Admin UI 使用 Atlas 的 REST API 来构建其功能。

 **- Tag Based Policies**: Apache Ranger 是针对 Hadoop 生态系统的高级安全管理解决方案，与各种 Hadoop 组件具有广泛的集成。通过与 Atlas 集成，Ranger 允许安全管理员定义元数据驱动的安全策略，以实现有效的治理。 Ranger 是由 Atlas 通知的元数据更改事件的消费者。

 ***\*- Business Taxonomy:\****从元数据源获取到 Atlas 的元数据对象主要是一种技术形式的元数据。为了增强可发现性和治理能力，Atlas 提供了一个业务分类界面，允许用户首先定义一组代表其业务域的业务术语，并将其与 Atlas 管理的元数据实体相关联。业务分类法是一种 Web 应用程序，目前是 Atlas Admin UI 的一部分，并且使用 REST API 与 Atlas 集成。

## 1.4Apache Atlas依赖HDP组件

1. HBase：Titan默认使用HBase存储元数据
2. Ambari infra/Solr：Titan默认使用Solr存储元数据索引
3. Kafka：Apache Atlas使用Kafka作为消息队列，实现hook和元数据通知事件的消费者之间的通信

![img](https://img-blog.csdnimg.cn/20200726150204935.png)

 ![img](https://img-blog.csdnimg.cn/20200726150217993.png)

## 1.5类型系统

元数据处理的整体流程入下图所示：

![img](https://img-blog.csdnimg.cn/20200726150857312.png)

   在Atlas中查询某一个元数据对象时往往需要遍历图数据库中的多个顶点与边，相比关系型数据库直接查询一行数据要复杂的多，当然使用图数据库作为底层存储也存在它的优势，比如可以支持复杂的数据类型和更好的支持血缘数据的读写。

## 1.6类型系统

Atlas 允许用户为他们想要管理的元数据对象定义一个模型。该模型由称为 “类型” (type)的定义组成。被称为 “实体” (entities)的 “类型” 实例表示被管理的实际元数据对象。由 Atlas 管理的所有元数据对象（例如Hive表）都使用类型进行建模，并表示为实体。

\- Type：***\*Atlas中的 “类型” 定义了如何存储和访问特定类型的元数据对象\****。类型表示了所定义元数据对象的一个或多个属性集合。具有开发背景的用户可以将 “类型” 理解成面向对象的编程语言的 “类” 定义的或[关系数据库](https://so.csdn.net/so/search?q=关系数据库&spm=1001.2101.3001.7020)的 “表模式”。类型具有元类型，元类型表示 Atlas 中此模型的类型：

​      \- 基本元类型： Int，String，Boolean等

​      \- 集合元类型：例如Array，Map

​     \- Class，Struct，Trait

 \- Entities：Atlas中的 ***\*“实体” 是类 “类型” 的特定值或实例\****，因此表示真实世界中的特定元数据对象。回顾我们的面向对象编程语言的类比，“实例” 是某个 “类” 的 “对象”。

\- Attributes：Atlas中的属性还有一些属性，其定义了与类型系统相关的更多概念，包括：

   \- isComposite - 是否复合

   \- isIndexable - 是否索引

   \- isUnique - 是否唯一

   \- multiplicity - 指示此属性是（必需的／可选的／还是可以是多值）的

Atlas 提供了一些预定义的系统类型：

\- Referenceable：此类型表示可使用名为 qualifiedName 的唯一属性搜索的所有实体

- Asset：此类型包含名称，说明和所有者等属性

\- Infrastructure：此类型扩展了Referenceable和Asset ，通常可用于基础设施元数据对象（如群集，主机等）的常用超类型

\- DataSet：此类型扩展了Referenceable和Asset 。在概念上，它可以用于表示存储数据的类型。在 Atlas 中，hive表，Sqoop RDBMS表等都是从 DataSet 扩展的类型。扩展 DataSet 的类型可以期望具有模式，它们将具有定义该数据集的属性的属性。例如， hive_table 中的 columns 属性。另外，扩展 DataSet 的实体类型的实体参与数据转换，这种转换可以由 Atlas 通过 lineage（或 provenance）生成图形。

\- Process：此类型扩展了Referenceable和Asset 。在概念上，它可以用于表示任何数据变换操作。例如，将原始数据的 hive 表转换为存储某个聚合的另一个 hive 表的 ETL 过程可以是扩展过程类型的特定类型。流程类型有两个特定的属性，输入和输出。

Hive表是Atlas本机定义的一种类型的示例，定义Hive表具有以下属性：

```bash
Name:         hive_table



TypeCategory: Entity



SuperTypes:   DataSet



Attributes:    



	name:              string    



	db:                 hive_db    



	owner:             string    



	createTime:       date    



	lastAccessTime:   date    



	comment:           string    



	retention:         int    



	sd:                 hive_storagedesc    



	partitionKeys:    array<hive_column>    



	aliases:           array<string>    



	columns:           array<hive_column>    



	parameters:        map<string>    



	viewOriginalText: string    



	viewExpandedText: string    



	tableType:         string    



	temporary:         boolean
```

------

# 二、Atlas 元数据血缘

## 2.1 atlas 配置文件

### 1.Atlas数据库

​    Atlas 的数据信息保存在默认创建的 ATLAS_ENTITY_AUDIT_EVENTS 的 HBase 数据库中。

![img](https://img-blog.csdnimg.cn/20200716223152972.png)

### 2.Grapth Titan

​    Atlas 保存 Graph 元数据信息在 HBase 的 atlas_janus 中，使用 solr 实现信息索引。

![img](https://img-blog.csdnimg.cn/20200716223201441.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzM1OTk1NTE0,size_16,color_FFFFFF,t_70)

### 3.hive-site.xml 配置文件

   在勾选了Atlas 服务，Ambari 安装时自动创建配置，在hive配置文件中加入钩子函数。

![img](https://img-blog.csdnimg.cn/20200716223214158.png)

### 4.hbase-site.xml配置文件

![img](https://img-blog.csdnimg.cn/20200726152250655.png)

## 2.2 hive_db Type示例

### 1. hive中创建数据库

在hive 数据库中创建 atlas_test 数据库，hive hook拿到元数据同步到Atlas中，在hive_db Type中我们可以看到数据库信息。

![img](https://img-blog.csdnimg.cn/2020072615262827.png)

### 2.在 atlas_test 数据库中创建 三张表

![img](https://img-blog.csdnimg.cn/20200726152707813.png)

### 3.atlas_test Type 元数据信息

***\*（1）Properties\****

![img](https://img-blog.csdnimg.cn/20200726152811542.png)

***\*（2）Relationships\****

![img](https://img-blog.csdnimg.cn/20200726152847223.png)

**（3）Classifications 后面说明**

**（4）Audits** 

![img](https://img-blog.csdnimg.cn/20200726152956659.png)

**（5）Tables**

![img](https://img-blog.csdnimg.cn/20200726153020525.png)

### 4.atlas_test中teacher表的信息

**（1）properties**

![img](https://img-blog.csdnimg.cn/20200726153235971.png)

**（2）Lineage**

![img](https://img-blog.csdnimg.cn/20200726153255551.png)

![img](https://img-blog.csdnimg.cn/20200726153307566.png)

![img](https://img-blog.csdnimg.cn/2020072615332341.png)

***\*（3）Relationships\****

![img](https://img-blog.csdnimg.cn/20200726153339937.png)

***\*（4）Classifications\****

***\*（\*******\*5\*******\*）\*******\*Audits\****

![img](https://img-blog.csdnimg.cn/20200726153357119.png)

**（6）Schema**

![img](https://img-blog.csdnimg.cn/20200726153427386.png)

## 2.3 分类传播

分类传播使与实体关联的分类能够自动与该实体的其他相关实体关联。 这在处理数据集从其他数据集获取数据的场景时非常有用，例如，表中加载了文件中的数据，从表/视图生成的报告等。

例如，当一个表被分类为PII时，从该表派生数据的表或视图（通过CTAS或“创建视图”操作）将被自动分类为PII。

**（1）创建分类PII**

![img](https://img-blog.csdnimg.cn/20200726153656435.png)

***\*（\*******\*2\*******\*）\*******\*使用 hive teacher表演示\****

![img](https://img-blog.csdnimg.cn/20200726153725591.png)

下面我会给 employee  打上 PII的  分类，与之关联的 student表 和  由employee 与student派生的 teacher 表也将被自动分类为 “PII”。

![img](https://img-blog.csdnimg.cn/20200726153747544.png)

 这种分类（Classifications  Propagated）就像某种传染病一样 ，传给下一代或者衍生者。

![img](https://img-blog.csdnimg.cn/20200726153802739.png)

# 三、基于标签的安全策略

   Atlas通过与Ranger集成，为Hadoop提供了基于标签(Tag)的动态访问权限控制，通过控制与资源关联的标签而非资源本身可以为权限控制模型提供诸多便利，可以实现基于分类的、跨组件的权限控制，而无需在每个组件中创建单独的服务和策略：

- 将资源分类从权限控制中分离出来，不同Hadoop组件的资源(比如HDFS目录，Hive表，HBase表)中的同一类数据(比如社保账号/信用卡帐号)可以被打上同一个标签，以统一的权限来控制访问
- 如果Hadoop资源被打上标签，那么与标签相关的权限将被自动赋予该资源
- 单独的访问控制策略可以应用于不同的Hadoop组件的资源，而不再需要为每一个组件的资源都创建单独的策略

## 3.1 Atlas 添加Tag

基于上面创建的数据库和表

![img](https://img-blog.csdnimg.cn/20200726154847357.png)

### 3.2Ranger配置基于Tag的策略

配置Ranger Tagsync从Atlas中同步Tag。可通过Ambari WebUI=>Ranger配置，如图:

![img](https://img-blog.csdnimg.cn/20200726155558272.png)

***\*（1）创建基于Tag的策略Tag Based Policies\****

![img](https://img-blog.csdnimg.cn/20200726155803976.png)

***\*（2）Tag 中创建 policy\****

![img](https://img-blog.csdnimg.cn/20200726155900932.png)

此处要将 Atlas 中的 Tag 添加进来

![img](https://img-blog.csdnimg.cn/20200726155916623.png)

![img](https://img-blog.csdnimg.cn/20200726155942225.png)

## 3.3 Tag Service 应用到Hive

***\*（1）创建 New Service\****

![img](https://img-blog.csdnimg.cn/20200726160016655.png)

**（2）选择 Tag Service**

![img](https://img-blog.csdnimg.cn/20200726160131886.png)

## 3.4 验证

测试机器格式化，验证中断，验证就是使用 kangll 用户 登录 hiveserver2 访问 atlas_test 数据库

官网详细操作：[Assigning Tag Based policies with Atlas](https://www.cloudera.com/tutorials/tag-based-policies-with-apache-ranger-and-apache-atlas/2.html)

参考：

https://www.jianshu.com/p/8c07974111dd

官网详细操作：[Assigning Tag Based policies with Atlas](https://www.cloudera.com/tutorials/tag-based-policies-with-apache-ranger-and-apache-atlas/2.html)