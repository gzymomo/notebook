- [什么是DataWorks (aliyun.com)](https://help.aliyun.com/document_detail/73015.html)

DataWorks基于MaxCompute、Hologres、EMR、AnalyticDB、CDP等大数据引擎，为数据仓库、数据湖、湖仓一体等解决方案提供统一的全链路大数据开发治理平台。

## 产品架构

DataWorks十多年沉淀数百项核心能力，通过[智能数据建模](https://help.aliyun.com/document_detail/276018.htm?spm=a2c4g.11186623.0.0.2b0e29ecSvts3g#concept-2090781)、[全域数据集成](https://help.aliyun.com/document_detail/137663.htm?spm=a2c4g.11186623.0.0.2b0e29ecSvts3g#concept-dr3-k2v-42b)、[高效数据生产](https://help.aliyun.com/document_detail/314262.htm#task-2117519)、主动数据治理、全面数据安全、数据分析服务六大全链路数据治理的能力，帮助企业治理内部不断上涨的“数据悬河”，释放企业的数据生产力。

![产品架构](https://help-static-aliyun-doc.aliyuncs.com/assets/img/zh-CN/3014833561/p442199.png)

## 核心技术与架构

- 引擎架构![引擎架构](https://help-static-aliyun-doc.aliyuncs.com/assets/img/zh-CN/3652802561/p437192.png)采用星形引擎架构，数据源接入数据集成后，即可与其他各类型数据源组成同步链路进行数据同步。

- 任务监控与定位处理![运维中心逻辑图](https://help-static-aliyun-doc.aliyuncs.com/assets/img/zh-CN/7104317361/p353290.png)

# 数据建模：智能数据建模

- **数仓规划**：数仓规划支持数仓分层、数据域、数据集市等的规划，支持设置模型设计空间，不同部门可共享一套数据标准和数据模型。
- **数据标准**：数据标准字段标准、标准代码、度量单位、命名词典的定义，支持标准代码自动生成质量规则，落标检查不再难。
- **维度建模**：维度建模支持逆向建模，解决现有数仓的建模冷启动难题，支持可视化数仓维度建模，支持通过Excel文件导入模型和通过FML（一种类SQL的DSL）快速构建模型，支持与数据开发DataStudio无缝打通，自动生成ETL代码。
- **数据指标**：数据指标支持原子指标、派生指标的定义与构建，与维度建模无缝打通，可根据原子指标和不同维度批量创建派生指标。

## 核心技术与架构

DataWorks智能建模包含的各模块架构图如下。![架构图](https://help-static-aliyun-doc.aliyuncs.com/assets/img/zh-CN/8759336261/p295134.png)

# 数据质量：全流程的质量监控

数据质量以数据集（DataSet）为监控对象，支持监控MaxCompute数据表和DataHub实时数据流。当离线MaxCompute数据发生变化时，数据质量会对数据进行校验，并阻塞生产链路，以避免问题数据污染扩散。同时，数据质量提供历史校验结果的管理，以便您对数据质量进行分析和定级。详情请参见[数据质量](https://help.aliyun.com/document_detail/73660.htm#concept-zsz-44h-r2b)。

数据质量为您解决以下问题：

- 数据库频繁变更问题
- 业务频繁变化问题
- 数据定义问题
- 业务系统的脏数据问题
- 系统交互导致质量问题
- 数据订正引发的问题
- 数据仓库自身导致的质量问题

# 数据地图：统一管理，跟踪血缘

DataWorks的数据地图功能可以帮助您实现对数据的统一管理和血缘的跟踪。

[数据地图](https://help.aliyun.com/document_detail/118931.htm#concept-265529)以数据搜索为基础，提供表使用说明、数据类目、数据血缘、字段血缘等工具，帮助数据表的使用者和拥有者更好地管理数据、协作开发。![数据地图](https://help-static-aliyun-doc.aliyuncs.com/assets/img/zh-CN/3616127951/p69798.png)

# 构建数据仓库

DataWorks具有通过可视化方式实现数据开发、治理全流程相关的核心能力，本文将为您介绍DataWorks在构建云上大数据仓库和构建智能实时数据仓库两个典型应用场景下的应用示例。

## 构建云上大数据仓库

本场景推荐的架构如下。![构建云上大数据仓库](https://help-static-aliyun-doc.aliyuncs.com/assets/img/zh-CN/3393046561/p439763.png)

- **适用行业**：全行业适用。
- **方案优势**：阿里巴巴大数据最佳实践，高性能、低成本、Severless服务，免运维、全托管模式，让企业的大数据研发人员更聚焦在业务数据的开发、生产、治理。
- **产品组合**：MaxCompute + Flink + DataWorks。
- 场景说明
  - 用户数据来源丰富，包括来自云端的数据、外部数据源，数据统一沉淀，完成数据清洗、建模。
  - 用户的应用场景复杂，对非结构化的语音、自然语言文本进行语音识别、语义分析、情感分析等，同时融合结构化数据搭建企业级的数据管理平台，并且计算和存储成本最低。
  - 平台支撑多种形式的应用，包括使用机器学习算法进行复杂数据分析、使用BI报表进行图表展现、使用可视化产品进行大屏展示、使用其他自定义的方式消费数据。

## 构建智能实时数据仓库

本场景推荐的架构如下。![实时数仓](https://help-static-aliyun-doc.aliyuncs.com/assets/img/zh-CN/3196733561/p439766.png)

- **适用行业**：适用于电商、游戏、社交等互联网行业大规模数据实时查询场景。
- 方案优势：
  - 阿里云实时数仓全套链路与离线数仓无缝打通。
  - 满足一套存储，两种计算（实时计算和离线计算）的高性价比组合。
- **产品组合**：DataHub+实时计算Flink+交互式分析+MaxCompute+DataWorks+Quick BI / DataV
- 场景说明：
  - 数据采集：通过DataWorks（批量）、DataHub（实时）进行统一数据采集接入。
  - 数据开发：基于DataWorks进行数据全链路研发，包括数据集成、数据开发和ETL 、转换及计算等开发，以及数据作业的调度、监控、告警等。DataWorks提供数据开发链路的安全管控的能力，以及基于DataWorks数据服务模块提供统一数据服务API能力。
  - 实时数据：按实际业务需求使用Flink进行实时ETL（可选）、结果入库，使用交互式分析产品构建实时数据仓库、应用集市，并提供海量数据的实时交互查询和分析。
  - 交互式分析：提供实时离线联邦查询。历史离线数据存放于MaxCompute，实时分析数据存放于交互式分析。基于阿里云Quick BI或第三方数据分析工具（如Tableau）行数据可视化，以及构建各业务板块数据服务门户应用。