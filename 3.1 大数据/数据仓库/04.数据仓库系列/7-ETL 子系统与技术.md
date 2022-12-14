- [数据仓库系列7-ETL 子系统与技术 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/442619493)

## 一. 需求综合

ETL 系统结构的建立始于处理一个最棘手的问题：需求综合 。需求综合的含义是收集并理解所有己知的将会影响 ETL 系统的需求 、现实和约束等 。需求的列表可能会很长 ，但在开始 ETL 系统开发前应该都已经收集到了表中 。

ETL 需求是必须面对的主要约束且必须要与系统适应 。在此需求框架下，可以指定相关决策 、做出判断和开展创新工作，但是需求描述了 ETL 系统必须发布的核心元素 。

在开始 ETL 设计和开发工作前 ，应当提供针对以下所有10个需求的应答 。我们为每个需求提供了检查列表示例，方便您开始工作 。这一练习的要点是确保您对每个需求都进行了考虑，因为缺乏其中的任何一个 ，项目都有可能会被打断 。

## 1.1 业务需求

从 ETL 设计者的角度来看 ，业务需求是 DW/BI 系统用户的信息需求。我们使用受限 的术语 “ 业务需求” 意味着商业用户用于制定明智的商业决策所 需要的信息内容 。因为商 业需求直接驱动对数据源的选择以及选择的数据源 在 ETL 系统中转换的结果 ，ETL 小组必 须理解并仔细验证商业需求 。

**注意：** 在项目将要支持的业务需求定义期间 ，必须维护一个揭示关键性能指标(KPI)的列表， 以及业务用户需要研究某个 KPI “为什么” 发生 变化时 ，所需要的 下钻和跨钻目标。

## 1.2 合规性

改变法律条文和报表需求要求多数组织严格地对待其报表并证明这些报表的数字是准确的、完整的且未被篡改的 。当然，受到严格管理的业务的 DW/BI 系统，例如电讯 ，会花费数年时间编辑报表需求 。但是金融报表的整体氛围对每个人来说会越来越严格 。

**注意：** 在与法律部门或首席合规官（ CCO）（如果有的话）和 BI 发布小组咨询讨论时 、应该列 出所有的数据以及最终报表主题要遵守的法律限制 。列出这些数据输入和数据转换步骤 ， 需要维护 “监管链” ，显示并证明最终报表走来自发布的数据源的原始数据 。列出的数据，必须提供您所控制的副本的安全性证明，无论是在线的还是离线的 。列出您所归档的数据副本 ，列出这些归桔的预期使用周期。完成这些工作会带来好运 。这就是值得您去做的原因。

## 1.3 数据质量

三种强有力的力量融合将数据质量问题推到高管们最关注问题的列表顶部 。首先 ，长期文化趋势认为 “ 我只有看到数据 ，才能更好地管理业务”，这一思想持续增长 ：今天的知识工作者直觉地相信数据是他们工作的关键需求 。其次，多数组织理解其数据源是分布的 ， 通常处于不同的地点，集成不同数据源是非常有必要的 。第二，不断增长的对合规性的需求意味着不仔细处理数据将不可忽略或原谅。

**注意：** 您需要将那些已经知道的不中意的数据元素记录下来 ，描述是否与源系统达成共识以使在获取数据之前进行更正 。列举数据分析期间发现的那些需要在 ETL过程中持续监控和标记的数据元素 。

## 1.4 安全性

过去几年 ，安全意识在 IT 行业中一直在不断增长，但是对大多数 DW/BI 小组来说， 安全通常处于事后考虑的位置且被视为负担而不受欢迎 。数据仓库的基本节律与安全心理并不相符 ，数据仓库寻求为决策制定者发布范围广泛的数据 ，安全利益认为数据应该被限制发送给那些需要知道的人。此外，安全必须扩展到物理备份 。如果介质可以方便地从备份库移出，则当在线密码被泄露时，安全性将受到威胁 。 在需求综合期间 ，DW/BI 小组应该寻求高管层的明确指示，指明 DW/BI 系统的哪些方面应该运用额外的安全措施 。如果这些问题从未被检验过 ，则可能会被扔回给小组 。这也是为什么需要一个有经验的安全管理员参与到设计小组的原因 。合规性需求可能与安全需求存在交叉，在需求综合期间将这两个主题合并到一起是比较明智的选择 。

**注意：** 应当将合规性列表扩展，使其 包含熟知的安全和隐私需求 。

## 1.5 数据集成

对 IT来说 ，数据集成是 一个大课题 。因为其最终目标是将所有系统无缝地连接到 一起来开展工作。对数据集成来说 ，“ 企业全景视图” 是一个大家耳熟能详的名称 。在多数案例中，严格的数据集成必须能够在数据到达数据仓库后端前 ，将组织中主要的事务系统集成。 但是全面的数据集成往往很难实现 ，除非企业具有全面的、集中式的主数据管理（Master Data Management, MDM）系统 ，但即使这样，也仍然可能会有一些重要 的操作型系统并未 进入到主MDM中。

数据集成通常具有数据仓库中一致性维度和事实的形式 。一致性维度意味着跨不同据序建在公共维度属性 ，只有这样才能使用这些属性构建横向钻取报表。一致性事实意味若对公共业务度量达成一致，公共业务度量包括跨不同数据库的关键性能指标（KPI） ，只有这样 ，才能使用这些数据边过计算差异和比率来开展数学比较工作。

**注意：** 应当利用业务过程的总线矩阵建立一致性维度 （总线矩阵的列）的优先列表 。对每个总线矩阵的行进行标注 ，指明参与到集成过程中的业务过程是否有明确的执行需求 ，以及是否由ETL 小组负责这些业务过程。

## 1.6 数据延迟

数据延迟描述通过 DW/BI 系统发布给业务用户的源系统数据的速度。显然 ，数据延迟需求对 ETL 架构具有较大的影响。高效的处理算法 、并行化以及强大的硬件系统可以加快 传统的面向批处理的数据流 。但是在有些情况下，如果数据延迟需求非常紧迫 ，ETL 系统 的架构就必须从批处理方式转换为微批处理 方式或面向流处理的方式。这一转换不是一种 渐进的转变 ，而是一种重大的风格转变 ，数据发布流水线的所有步骤儿乎都需要 重新实现。

**注意：** 您应当列举所有合法的和审核过的针对以日为基础 、或者以天为 基础 多次发生、以秒为基础 、或者即时提供的数据的业务需求 。标注每个需求，明确业务团体是否了解与他们 的特定选择相关的数据质量的权衡。

## 1.7 归档与世系

即使没有存储数据的法律要求 ，每个数据仓库也都需要有以往数据的各种副本，要么与新数据比较以便建立发生变化的记录 ，要么重新处理 。我们建议在每个ETL 流水线的主要活动发生后暂存数据（将其写入磁盘）：在数据被获取 、清洗和一致化及发布后 。 那么什么时候将暂存转入归档 ，也就是数据被无限期地保存到某种形式的持久性介质 中呢？我们的回答是比较保守的 。所有暂存数据应该被归档 ，除非有专门的定义明确认为特定的数据集合未来将不再需要 。从持久性介质上读取数据与过后通过 ETL 系统重新处理 数据比较 ，前者要容易得多 。当然，利用过去的处理算法重新处理数据是不可能的，因为时间发生了变化 ，原始的获取不能够被重建 。 当处于实际情况时 ，每个暂存／归档数据集合都应该包含描述来源和建 立数据的处理步 骤的元数据 。此外，按照某些合规性需求的要求 ，对该世系的跟踪是明确需要的，应该成 为每个归档环境的一部分内容。

**注意：** 应当记录数据源和归档的中间数据步骤以及保留政策、合规性、安全和隐私方面的约束。

## 1.8 Bl 发布接口

ETL 过程的最后一步将切换到 BI 应用。我们认为这种切换应当处于强有力且具有纪律性的位置上。我们认为与建模小组密切合作的 ETL小组，必须负责使数据的内容和结构 能够使 BI应用简单而快速 。这一态度超过了那种母性式的模糊的说明 。我们相信以模糊的方式将数据推到 BI 应用是不负责任的表现，将会增加应用的复杂性，减缓查询或报表的构建，不必要地增加了商业用户使用数据的复杂性 。最基本和严重的错误是支持成熟的、规 范化的物理模型并脱离实际工作 。这也是为什么需要花这么长的时间讨论构 建包含最终切 换的维度模型的原因。

ETL小组和数据建模人员需要与 BI 应用开发人员密切合作 ，确定数据切换的具体需求 。 如果物理数据以正确的格式表示的话，则每种 BI 工具都有某些需要避免的敏感性 ，都包含某些可以利用的特征 。同样，在为 OLAP 多维数据库准备数据时 ，也需要考虑这些因素 。

**注意：** 应当列出所有将会直接被BI工具利用的事实和维度表。可以直接从维度模型定义着手 。列出BI工具需要的所有OLAP多维数据库和特定的数据库结构。列出所有您已经打算建立并用于支持BI性能的已知的索引和聚集。

## 1.9 可用的技能

某些ETL系统设计决策必须基于建立和管理系统的可用源的情况制定 。如果这些编程技能不是内部的或有合理的需要的话，就不应该基于关键的 C＋＋处理模块来构建系统 。同样，如果您已经掌握了这些技能井找到如何管理类似项目 ，那么您可能会认为围绕主要提 供商的 ETL工具来建立 ETL 系统更可靠。 考虑一个关键的决策问题，是否需要通过手工编码构建 ETL 系统或者使用供应商的 ETL 包。先将技术问题和许可证书的成本放在一边 ，不要因为未能考虑决策的长期影响而 走上雇员和经理都发现不熟悉的方向 。

**注意：** 应该清查您所在部门的操作系统 、ETL 工具、脚本语言 、编程语言 、SQL、DBMS 以 及 OLAP 技能 ，这样可以理解如何暴露出您缺乏这些技能 。列 出需要支持当 前系统以及未 来可能有的 系统的那些技能．

## 1.10 传统的许可证书

最后，在许多情况下 ，多数设计决策的制定隐约地受到管理层坚持认为应当使用现有许可证书的影响 。多数情况下，这一需求是可以考虑采用的，因为环境的有利条件对每个人来说都是非常明确的 。但也存在 一些情况 ，使用现有许可证书来开发 ETL 系统是一个错误的决定。如果出现这种情况，而且您感觉必须要做出正确的决定时，您可能需要以您的工作打赌 。如果您必须着手处理高管层的意见 ，挑战使用现存许可证书的原则，则需要为做出的决定进行充分的准备 ，要么接受最终 的决定，要么准备离开 。

**注意：** 您应当列出现有操作系统 、ETL 工具 、脚本语言 、编程语言 、 SQL、DBMS 和 OLAP的许可证书 ，无论它们是独家使用投权还是仅仅被建议使用的情况．

## 二. ETL的34个子系统

在充分理解了现存的需求、现状和相关约束后，就可以准备学习形成每个ETL系统架构的34个关键子系统 。本章将不分重点地描述34个子系统。下一章将描述在特定环境中实现这些子系统的实际步骤 。虽然我们采用了行业术语一 ETL一一味描述这些步骤 ，过程实际上包含4个主要的组成部分：

• 获取：从源系统中收集原始数据并通常在所有明显的数据重构发生之前将收集的数据写到ETL环境的磁盘上 。子系统 1 子系统3 用于支持获取过程 。

• 清洗及转换 ：将获取的源数据通过 ETL 系统的一系列处理步骤 ，改进从源系统获 得数据的质量 。将来自两个或多个数据源的数据融合，用于建立和执行一致性维度和一致性度量 。子系统 4 子系统 8 描述了支持清洗和转换工作所需要的结构 。

• 发布：物理构建并加载数据到展现服务器的目标维度模型中。子系统 9 子系统 21 提供了将数据发布到展现服务器的功能 。

• 管理 ：以一致的方法管理与ETL 环境相关的系统和过程。子系统 22 子系统 34 描述了用于支持 ETL 系统持续管理所需要的各种部件。

## 三. 获取：将数据插入到数据仓库中

毫无疑问，最初的ETL子系统结构将解决理解数据源 、获取数据 、将获取的数据转换到ETL系统能够操作且独立于操作型系统的数据仓库环境等问题。尽管即将讲述的子系统关注转换 、加载以及 ETL 环境的系统管理 ，但最初讨论的子系统将主要用于与源系统的接 口并获得需要的数据 。

## 3.1 子系统 1：数据分析

数据分析是对数据的技术分析，包括对数据内容 、一致性和结构的描述 。从某种意义来看 ，无论何时执行 SELECT DISTINCT 查询数据库字段 ，都是在进行数据分析 。存在大量的特定工具用于执行强大的数据分析工作 。投资采用某种工具而不是自己构建是有意义的，因为利用工具可以使用简单的用户接口探索大多数数据关系 。使用工具而不是自己手工编程开发 ，会大大提高数据分析阶段的效率 。

数据分析扮演两种不同的角色 ：战略与战术 。一旦确定了候选数据源 ，就应该开展轻量级的分析评估工作 ，确定其作为数据仓库包含物的适用性并尽早提供用或是不用的决定 。 理想情况下，这种战略性的分析应该在业务需求分析阶段确定了候选数据源后立即开展 。 尽早确定数据源的可用性资格问题是必须开展的负责任的一个步骤 ，能够让您赢得其他小组成员的尊敬 ，即使做出的决定是放弃使用某个数据源 。较晚发现数据源无法支持任务将使DW/BI工作偏离其应有的轨道（将会成为您职业生涯的致命错误），特别是如果这一发现发生在项目己经启动数月后 。

将数据源包含在项目中这一基本战略决策制定完成后 ，将开展较长时间的数据分析工作，尽可能将大多数问题挤出去 。通常，这一任务始于数据建模过程，井延伸到ETL系统设计过程 。有时，ETL小组可能希望将某一尚未进行内容评估的源包含进来。这些系统可能支持生产过程的需求，然而面临ETL的挑战，因为不是生产过程中心的宇段对分析目的来说可能是不可靠和不完整的。出现在该子系统中 的问题将导致详细的规格说明 ，这些规格说明要么返回 到数据来源地要求改进 ，要么成为 4 子系统 8 所描述的数据质量过程的 输入。

分析步骤能够指导 ETL 小组 ，多少数据清洗机制用于提醒并保护他们 ，在由于需要处理脏数据而导致的意想不到的系统构建迁移中不会丢失主要的项目里程碑。预先开展数据分析工作！使用数据分析结果设置业务资助人有关现实的开发计划 、对源数据的限制 、投资更好的源数据获取实践的期望 。

## 3.2 子系统 2：变化数据获取系统

在数据仓库进行最初的历史数据加载时 ，获取源数据内容的变化并不重要，因为您将会按照某一时间点 ，将该时间点之前的所有数据都加载进来 。然而 ，由于大多数数据仓库的表都非常庞大 ，以至于无法在每个 ETL 周期都能够将这些表加载一次。因此必须具备能够将上一次更新后发生变化的源数据加载进来的能力。将最新的数据源分离出来被称为变化数据获取（Change Data Capture CDC) 。隐藏在 CDC 背后的思想比较简单：仅仅传输那些 上次加载后发生变化的数据 。但是建立一个好的 CDC 系统并不像昕上去那么容易 。变化数据获取子系统的主要目标包括 ： • 分离变化数据以允许可选择加载过程而不是完全更新加载。 • 获取源数据所有的变化（删除 、更新和插入 ），包括由非标准接口所产生的变化。 • 用变化原因标记变化了的数据 ，以区分对错误更正和真正的更新 。 • 利用其他的元数据支持合规性跟踪 。 • 尽早执行CDC步骤 ，最好是在大量数据传输到数据仓库前完成 。

获取数据变化不是一件小事 。您必须仔细评估针对每个数据源的获取策略 。确定适当的策略以区分变化的数据要采用一些侦察性的工作。前面讨论的数据分析任务有助于做出这样的决定 。获取源数据变化可以采取几种方式 ，每种方式都适合不同的环境，下面具体介绍它们。

1. 审计列 某些情况下 ，源系统包含审计列 ，这些列存储着一条记录被插入或修改的日期和时间。 这些列一般是在数据库记录被插入或更新时 ，激活触发器而自动产生的 。有时，出于性能方面的考虑 ，这些列由源系统的应用而不是通过触发器产生的 。当这些不是由触发器而是由其他任何方式建立的字段被加载时 ，一定要注意它们的完整性，分析并测试每 一列以确保它们是表示变化的可靠来源 。如果发现存在空值 ，则一定要找到其他用于检测变化的方法。最常见的阻碍 ETL 系统使用审计列的情况是 ，当这些字段由源系统应用建立时 ，DBA 小组允许在后端用脚本对数据进行更新 。如果这种情况在您的环境中存在 ，则会面临在增量加载期间丢失变化数据的风险。最后 ，您需要理解当一个记录被从源中删除时会发生何种反应 ，因为查询和审计列可能无法获得删除事件。
2. 定时获取 在采用定时获取方法时，通常会选择所有那些建立 期或修改日期字段等于 SYSDATE-1（意思是昨天的记录）的行。听起来很完美 ，真是这样吗 ？错误 。纯粹按照时间 加载记录是那些没有经验的 ETL 开发者常犯的错误。这一过程非常不靠谱 。基于时间选择加载数据的方式 ，当中间过程出现错误需要重启会多次加载行 。这意味着无论加载过程由于何种原因失败，都需要人工干预并对数据进行清洗 。同时，如果晚间加载过程失败并推迟了一天， 那就意味着丢失的数据将无法再进入数据仓库中 。
3. 全差异比较 全差异比较将保存所有昨天数据的快照 ，并与之进行比较 。将其与今天的数据逐个比较，找到那些发生了变化的数据 。这一技术的好处是它非常严密 ：可保证找到所有的变化 。 明显的缺点在于，多数情况下 ，采用这一技术对资源的消耗巨大 。如果需要使用全差异比较，则尽力利用源机器 ，这样不需要将整张表或数据库保存在 ETL环境中 。当然，这样做会招致源支持方的意见 。同样，可以研究使用循环元余校验（ Cyclic Redundancy Checksum , CRC)算法快速检测出某个复杂的记录是否发生了改变而不需要对每个字段进行检验 。
4. 数据库日志抓取 有效的日志抓取利用时间计划点（通常是午夜时间）的数据库重做日志快照并在那些 ETL 加载用到的受影响的表的事务中搜寻 。检测包括轮询重做日志 ，实时获取事务 。抓取日志事务可能是所有技术中最杂乱的技术 。事务日志经常会被装满并阻碍过程中新事务的 加入 。当这种情况发生在生产事务环境时 ，负责任的DBA 可能会立即清空日志 ，以便能够 让业务操作继续开展 ，但是一旦日志被清空，日志中包含的所有事务都会丢失。如果您耗 尽精力使用所有技术 ，并最终发现日志抓取是您发现新的或变化的记录的最后手段 ，一定 要告诉 DBA ，请他为满足您的特 殊要求建立一个专门的日志 。
5. 消息队列监控 在一个基于消息的事务系统中，监视所有针对感兴趣表的事务的队列 。流的内容与日志探索差不多 。这一过程的好处之一是开销相对较低 ，因为消息队列己经存在 。然而，消息队列没有回放功能 。如果与消息队列的连接消失 ，将会丢失数据 。

## 3.3 子系统 3：获取系统

显然，从源系统中获取数据是ETL结构的基础部件 。如果所有的源数据都在一个系统中，且可以使用ETL工具随意获取 ，那您真是太幸运了 。多数情况下 ，每个源都位于不同的系统中，处于不同的环境并采用不同的数据库管理系统 。

ETL 系统可能会被要求从范围广泛的系统中获取涉及多种不同类型和固有难题的数据 。组织需要从常会遇到像 COBOL 复制手册 、EBCDIC 到 ASCII 转换 、压缩十进制 、重新定义、OCCURS 字段以及多个可变记录类型等 问题的主机环境中获取数据 。另外一些组 织可能需要从关系 DBMS 、平面文件 、XML 源、Web 日志或复杂的 ERP 系统中获取 。每种获取都具有一定的难度 。有些源 ，特别是那些比较古老的遗留系统 ，可能需要使用不同 的过程语言 ，而不是 ETL 工具或小组的经验可以支持的 。在此情况下 ，请求所有者将他们的源系统转换为平面文件格式 。 **注意：** 尽管使用自描述的XML格式数据有很多好处，但您仍然无法忍受大量的 、频繁的数据转换 。XML格式文件的有效部分还不到整个文件的10%。本建议的例外可能是 XML 有 效负载是复杂的深度层次 XML 结构 ，例如 ，工业标准数据交换 。在此情况下 ，DW/BI小组需要决定是否 “分解” XML 为 大量的目 标表或者坚持在数据仓库中使用 XML 结构。最 近关 系数据库管理 系统(RDBMS）提供商提供了 通过 XPath 支持 XML ，使后一种选择可操 作性更强 。

从源系统中获取数据通常可以采用两种方法：以文件方式或者以流方式 。如果源处于古老的主机系统中，最容易的办法是采用文件方式 ，并将这些文件移动到ETL 服务器上 。 **注意：** 如果源数据是无结构 、 半结构甚至是包含多种结构的 “ 大数据” ，那么与其将这些数 据以无法解释的 “blob” 类型加载到RDBMS 中，不如建立更有效的 MapReduce/Hadoop 获取步骤 ，作为 ETL 从源数据中获取事实的获取器，直接发布可加载的 RDBMS 数据。

如果要在数据库中使用 ETL 工具且源数据在数据库（不限于 RDBMS）中 ，您可以将获取按照流来设置，其中数据流出源系统，通过转换引擎 ，以单一过程进入过渡数据库 。相比之下，文件获取方法包括三四个不同的步骤 ：获取文件 、将文件移动到 ETL 服务器 ，转换文件内容以及加载转换后的数据 到过渡服务器 。 **注意：** 尽管流获取更有吸引力，但文件获取方式还是存在一些有利条件 。可以方便地在不同点重新开始。只要保存了获取的文件 ，就可以重新运行为口载，而 不会对源系统产生任何影响。将数据通过网络传输时，可以方便地加密和压缩数据 。最后，验证所有数据在移动过程中保持了正确性可以通过比较传输前后的文件行计数获得。一般来说，我们建议采用数据传输实用程序，如FTP，来传输获取的文件 。

如果要通过公共网络或在距离比较长的情况下传输大量数据 ，对数据进行压缩后再传输是非常重要的 。在此情况下，通讯链路通常会成为瓶颈 。如果传输数据花费大量的时间， 则压缩可以减少 30% 50%或更多的传输时间 ，效果如何要看原始数据文件的属性。 如果数据要通过公共网络传输或者在某些情况下 ，即使在内部传输，也需要对数据进行加密。处于这样的环境 ，最好考虑使用加密链路 ，这样就不用考虑l哪些需要加密 ，哪些 不需要加密 。记住在加密前压缩 ，因为加密后的文件压缩效果不好 。

## 3.4 清洗与整合数据

清洗与整合数据是ETL系统的关键任务 。在这些步骤中, ETL系统将增加值到数据中 。 其他一些活动 ，获取和发布数据 ，显然也是必须存在的 ，但它们仅仅是移动和加载数据。 清洗和整理子系统对数据做出了实际的改变 ，并增加了数据对组织的价值 。此外，这些子系统可以被构建来建立用于诊断系统何处出现问题的元数据 。此类诊断最终会导致业务流程再造以解决脏数据产生的根本原因并随时间不断改进数据质量。

### 3.4.1 提高数据质量文化与过程

对所有出现在流程中的错误，都试图批评原始数据源的问题 。若数据录入员再仔细一点该多好哇 ！我们应该对那些将产品和客户信息录入其订单表格的受到键盘挑战的销售人员多些宽容 。也许应当通过在数据录入用户接口增加限制性约束的方式来改善数据质量问题。该方法提供了有关如何考虑改进数据质量的提示 ，因为技术方面的解决方案通常能够避免真正问题的出现 。假定客户的社会安全号码字段常常出现空白或保存的是屏幕输入的 垃圾信息。有些人对此提出了 一种聪明的解决方法 ，要求输入必须满足 999-99-9999 这样 的格式，以此方式巧妙地避免了录入类似条目全部是 9 的情况发生。会发生什么情况呢 ？ 数据录入员必须输入合法的社会安全号 ，否则无法进入下一屏幕 ，因此当他们没有客户的号码时，只好通过人工号码避免这一障碍 。

Michael Hammer 在其革命性的书籍 Reengineering the Corporation(Collins , 2003 年版） 中，用睿智的观察直击数据质量问题的核心 。Hammer 解释道：“看起来不起眼的数据质量问题，实际上是拆散业务流程的重要标志 。” 这一思想不仅能够引起您对数据质量问题的重视，而且还指明了解决之道 。 从技术的角度解决数据质量问题难以取得成功 ，除非它们是来自组织顶层的质量文化 的一部分。著名的日本汽车制造业对质量的态度渗入到企业的每个层次中，从 CEO 到装配线工人 ，所有层次都非常关注质量 。将其引入到数据环境中 ，设想某个大型连锁药店 ，一组买方与成千上万的提供库存的供应商签订合同 。买方助理的工作是键入每个购买药物的买方的详细信息 。这些药方包含大量的属性 。但问题是助理的工作非常繁重并且要考察买方们每小时输入的条目的数量 。助理几乎意识不到谁在利用这些数据 。偶尔，助理会因为出现明显的错误而受到批评 。但更可怕的是，提供给助理的数据本身是不完整和不可靠的。 例如 ，毒性等级没有规范的标准 ，因此这一属性会随着时间或产品分类而发生明显的变化 。 药店应该如何改进其数据质 量呢？这里提供一个包含 9 个步骤的模板 ，不仅适用于药店 ， 也可用于其他需要解决数据质 量问题的企业 ： • 定义一个针对数据质量文化的高级别的承诺 。 • 在执行层面上发起过程再造 。 • 投资用于改进数据录入环境 。 • 投资用于改进应用集成 。 • 投资用于改变工作过程 。 • 促进端到端的团队意识 。 • 促进部门间合作 。 • 大力褒奖卓越的数据质量。 • 不断度量并改进数据质量。 针对药店 ，需要加大投入 ，改进数据录入系统 ，为买方助理提供他们需要的内容和选择 。公司经理需要让买方助理意识到他们的工作非常重要并认识到企业价值的最终目标源于数据质量。

### 3.4.2 子系统 4：数据清洗系统

ETL 数据清洗过程通常希望订正脏数据 ，同时希望数据仓库能够提供对组织生产系统中的数据的准确描述。在各种冲突的目标之间实现平衡是基本的要求 。 在描述清洗系统时，目标之一是提供清洗数据 、获取数据质量事件 ，以及度量并最终控制数据仓库中的数据质量的全面结构 。一些组织可能发现实现这种结构具有挑战性 ，但我们相信对ETL小组来说 ，努力工作尽力争取将这些能力尽可能具体化是非常重要的。如果您是一位 ETL 方面的新手并发现实现这一工作具有严峻的挑战，那么您可能想知道 “ 我应该关注的最小内涵是什么 ？” 答案就是以实现最好的数据轮廓分析为起点 。这一工作的 结果有助于理解改善潜在的脏数据和不可靠数据的风险 ，井有助于确定您的数据清洗系统 需要完成的工作的复杂程度 。 清洗子系统的目标是汇总技术用于支持数据质量 。子系统的目标包括 ： • 尽早诊断并分类数据质量问题。 • 为获得更好的数据而对源系统及集成工作的需求 。 • 提供在 ETL 中可能遇到的数据错误的专门描述。 • 获取所有数据质量错误以及随时间变化精确度量数据质量矩阵的框架 。 • 附加到最终数据上的质量可信度度量 。

1. 质量屏幕 ETL 结构的核心是用于诊断过滤数据流流水线的质量屏幕集合 。每个质量屏幕就是一个测试 。如果针对数据的测试成功 ，就不会有事发生，并且屏幕没有副作用 。如果测试失败 ，则一定会在错误事件模式中出现错误行 ，并做出选择 ，是终止过程 ，将错误数据发送 到挂起状态 ，还是对数据进行标记 。 尽管所有质量屏幕在结构上是类似的 ，但将其划分为以升序形式展现 的三种类别可方便处理 。Jack Olson 在其有关数据质量的开创性著作 Data Quality: The Accuracy Dimension (Morgan Kaufmann , 2002）中 ，将数据质量屏幕划分为三种类型：列屏幕 、结构屏幕和业务 规则屏幕 。 列屏幕测试单一列中的数据 。这些测试通常是简单 的、 比较明显的 测试 ，例如 ，测试 某列是否包含未预 期的空值 ，某个值是否超出了 规定的范围，或者某个值是否未能遵守需 要的格式 。 结构屏幕测试数据列之间的关系 。测试两个或更多的列以验证它 们是否满足层次要 求 ，例如 ，一系列多对 一关系。结构屏幕也对两个表之 间存在 的外键／主键 的约束关系进行 测试 ，还包括对整个列块 的测试，验证它们的邮政编码是否满足合法性 。 业务规则屏幕实现由列和结构测试无法适应 的更复杂的测试。例如 ，可能需要测试与 客户档案有关 的复杂的与时间关联的业务规则，例如 ，需要测试那些申请终身白金飞行常 客的成员 ，要求至少有 5 年乘机历史 并且飞行距离超过 200 万公里 。业务规则屏幕也包括 聚集阙值数据质量检查 ，例如 ，磁共振成像检查是否存在某个统计上不可能出现的数字 ， 来源于极少出现的有手肘扭伤的诊断 。在此情况下 ，屏幕将会在达到 此类磁共振成像检 查阙值时弹出错误 。
2. 对质量事件的晌应 我们已经讨论了在错误发生时决定如何操作的每种质量屏幕 。可选择的方式为 ：①终止过程 ：②将错误记录发送到搁置文件中，以便后续处理 ；③仅对数据进行标注并将其放到流水线的下一个步骤中 。无论处于何种情况，第 3 种选择是目前为止最好的选择 。终止处理显然不够好 ，因为诊断问题、重启或恢复作业或者完全中止等工作都需要人工参与处理。将记录发送到搁置文件通常也不是好的解决方案 ，因为并不清楚何时或者是否这些记录将被更正并重新进入流水线中 。在这些记录被恢复到数据流中之前 ，数据库的完整性无法得到保证 ，因为丢失了记录 。我们建议在少量数据错误时不要使用搁置文件 。以标记数据为错误数据的第 3 种选择方法通常效果较好 。不好的维度数据也可以使用审计维度进 行 标记 ，或者在面对丢失或垃圾数据的情况下 ，可以在属性上标记唯一错误值。

### 3.4.3 子系统 5：错误事件模式

错误事件模式是一种集中式的维度模式 ，其目的是记录ETL 流水线中所有质量屏幕出现的错误事件 。尽管我们主要关注的是数据仓库的 ETL 过程 ，但该方法也可应用于 一般的需要在遗留应用之间传输数据的数据集成应用中 。错误事件模式如下图所示:

![img](https://pic1.zhimg.com/80/v2-dc744895b1c56427fbb7dac2611cdf24_1440w.webp)



在该模式中 ，主表是错误事件事实表 。其粒度是每个由 ETL 系统的质量屏幕抛出的（产生的）错误。记住事实表的粒度是对每个事实存在的原因的物理描述。每个质量屏幕错误在表中用一行表示 ，表中每行对 一个观察到的错误 。 错误事件事实表的维度包括错误的日历日期 、错误产生的批处理作业以及产生错误的屏幕。日历日期不是产生错误的分或秒时间戳，相反，日历日期按照日历的通常属性（例如， 平日或某财务周期的最后 一天）提供一种约束井汇总错误事件的方法 。错误日期／时间事实是一种完整关联的日期／时间戳，精确地定义了错误发生的时间 。这种格式可方便计算错误 事件发生 的时间间隔，因为可以通过获得两个日期 ／时间戳之间的差别获得不同事件发生的 间隔时间。

批处理维度可被泛化为针对数据流的处理步骤 ，而不仅仅是针对批处理 。屏幕维度准确地识别是何种屏幕约束以及驻留在屏幕上的是何种代码 。它也能够定义在屏幕 抛出错误时采取了什么措施 。例如 ，停止过程 、发送记录到挂起文件或标记数据 。

错误时间事实表还包含一个单列的主键 ，作为错误事件的键 。此代理键类似于维度表主键 ，是一种随着行增加到事实表中而顺序分配的整数 。该键列同时被增加到错误事件事 实表中 。希望这种情况未发生在您所处的环境中 。

错误事件模式包括另外一种粒度更细的错误事件细节事实表 。该表中每行确定与错误有关的某个特定记录的个体字段 。这样某个高级别的错误事件事实表中的单一错误事件行 所激活的复杂的结构或业务规则错误将会在错误细节事实表中用多行表示 。这两个表提供错误事件键关联 ，该键是低粒度表的外键 。错误事件细节表可区分表 、记录 、字段和准确 的错误条件 。因此复杂的多字段 、多记录错误的完整描述都将保存在这些表中 。

错误事件细节事实表也可以包含准确的日期 ／时间戳，提供对聚集阔值错误事件的完整 描述 。聚集阔值错误事件中 的错误条件涉及某个时间段内的多条记录 。您现在应当能够感 觉到每个质量屏幕具有在错误发生时将错误添 加到表中的功能了 。

### 3.4.6 子系统 6：审计维度装配器

审计维度是一种特殊的维度 ，用于在后端装配 ETL 系统的每个事实表 。如下图所示的审计维度包含当建立特定事实行时的元数据环境 。您可能会说我们将元数据提升到实际数据了 。考虑如何建立审计维度行 ，设想该货运事实表将按照批处理文件每天更新一次 。假设您今天工作顺利没有产生错误标记 ，此时 ，将建立唯一 的一行审计维度 ，将被 附加到今天所加载的所有事实行 。所有的分类 、分数和版本号都将 相同。

![img](https://pic2.zhimg.com/80/v2-ab199b941cf4de9bb0784fb008d7b501_1440w.webp)



现在，让我们去掉工作顺利的假设 。如果某些事实行 由于折扣值出现出界错误而被激 活，则需要不止一个审计维度行用于标记这一情况。

### 3.4.5 子系统 7：重复数据删除（deduplication ）系统

通常维度来自多个源 。多个面向客户的源系统建立并管理不同的客户主表，这种情况 在组织中比较常见 。客户信息可能需要从多个业务项和外部数据源中融合获得 。有时 ，数据可以通过匹配同 一键列的相同值获得 。然而 ，即使在定义的匹配发生时 ，数据的其他列 相互之间也可能存在矛盾 ，需要确定保留哪些数据 。

遗憾的是 ，很少存在统一的列能使融合操作更方便 。有时 ，唯一可用的线索是几个列 的相似性。需要集成不同的数据集合 ，已经存在的维度表数据可能需要对不同的字段进行 评估以实现匹配 。有时 ，匹配可能基于模糊评判标准 ，例如 ，对包含少量拼写错误的名字 和地址进行近似匹配 。

数据保留（survivorship）是合并匹配记录集合到统 一视图的过程 ，该统一视图将从匹配 记录中获得的具有最高质 量的列合并到一致性的行中 。数据保留包括建立按照来自所有可能源系统的列值而清楚定义了优先顺序的业务规则 ，用于确保每个存在的行具 有最佳的保留属性。如果维度设计来自多个系统 ，则必须维护带有反向引用的不同列 ，例如自然键 ， 用于所有参与的源系统行的构建工作 。

考虑到重复数据删除 、匹配和数据保留等问题的困难性 ，目前有大量的数据集成和数据标准工具可用 。这些工具非常成熟且应用非常广泛。

### 3.4.6 子系统 8：一致性系统

一致性处理包含所有需要调整维度中的 一些或所有列的内容以与数据仓库中其他相 同或类似的维度保持一致的步骤 。例如 ，在大型组织中 ，可能有一个获取发票和客户服务呼叫同时又都利用了客户维度的事实表 。通常发票和客户服务的数据来自不同的客户数据库。通常情况下 ，来自两个不同客户信息源的数据很少能保证具有一致性 。需要对来自这 两个不同客户源的数据进行一致性处理 ，使某些或所有描述客户的列能够共享相同的领域。

**注意：** 建立一致性维度的过程要采用敏捷方法 。对两个需要一致性处理的维度 ，它们必须至少有一个具有相同名称和内容的公共属性 。您必须考虑使用单一的一致性属性 ，例如 ，客户分类 ，让其不受任何影响地添加到每个面向客户的过程中的客户维度中 。在添加每个面向客户的过程时 ，扩展可以集成的过程列表并使其能够 参与横向钻取查询过程 。还可以增 量式添加一致性属性的列哀 ，例如 ，城市 、省和国 家等。所有这些都可以分阶段采用更敏捷的方法实现。

一致性子系统负责建立并维护。要实现这些工作，需要合并且集成从 多个源输入的数据 ，因此需要其内容行具有相同的结构、重复数据删除 、过滤掉无效数据 、标准化等特点 。一致性处理的主要过程是如前所述的重复数据删除 、匹配和数据保留处理过程 。一致性过程流对 重复数据删除和数据保留过 程的合并如下图所示:



![img](https://pic3.zhimg.com/80/v2-e842b7625295c5eb16ff0ec6bbab579e_1440w.webp)

## 3.5 发布：准备展现

ETL 系统的主要任务是发布阶段切换维度和事实表 。出于这样的原因 ，发布子系统是 ETL 结构中最为重要的子系统 。尽管数据源结构和清洗以及 一致性逻辑有相当大的变化 ， 但准备维度表结构的发布处理技术更加明确且严格 。使用这些技术对建立一个成功的维度 数据仓库 ，使其具备可靠 、可扩展和可维护的性能是至关重要的 。

大多数此类子系统关注维度表处理过程 。维度表是数据仓库的核心 。它们为事实表及 所有的度量提供环境 ，尽管维度表通常 比事实表小得多，但它们对 DW/BI 系统的成功起关 键的作用 ，因为它们为事实表提供了接入点 。发布过程始于 刚刚描述的子系统对清洗和对数据的一致性处理。对多数维度来说 ，基本加载规划相对要简单 一些：执行基本的对数据的转换并建立维度行，加载到目标展现表中 。这一过程通常包括代理键分配 、代码查找以提供适当的描述 、划分或合并列以表示适当的数据值 ，或连接底层的符合第 3 范式格式的 表结构使其成为非规范的平面型维度 。

事实表的准备也非常重要 ，因为事实表拥有用户希望看到的针对业务的关键度 量 。事 实表可能非常大并且需要大量的加载时间 。然而 ，准备用于展现的事实表通常更为明确 。

### 3.5.1 子系统 9：缓慢变化维度管理器

ETL 结构中最为重要 的元素之一是实现缓慢变化维度（Slowly Changing Dimension , SCD）逻辑的能力 。ETL 系统必须确定当己经存在于数据仓库中的属性值发生变化时的处理方法。如果确定当被修改的描述是合理的且需要更新原有信息时 ，必须应用适当的 SCD 技术。

当数据仓库收到通知 ，维度中存在的行发生变化时 ， 可以采用 3 种基本响应 ：类型 1 重写 ；类型 2 增加新行 ：类型 3 增加新列 。在使用这 3 种 技术以及其他 SCD 技术时 ，SCD 管理器应该系统化地处理维度中的时 间差异。此外，SCD 管理器应该为类型 2 变化维护适当的 管理列。

在表达变化数据的 SCD 处理中 ，子系统 2 中所描述的变化数据获取过程显然扮演了 一 种重要的角色 。如果变化数据 获取过程有效地发布了适当的变 化，SCD 处理就可以采取适 当的行动。

1. 类型 1：重写 类型 1技术简单地在己有维度行中重写一个或多个属性 。将从变化数据获取系统中获 取的修改后的数据重写到维度表中的相应内容 。当需要改正数据或对先前值没有保存的业务需求时 ，类型1是比较适当的 。例如，您可能需要改正客户的地址 。在此情况下，重写是正确的选择 。注意，如果维度表包含类型 2 变化跟踪 ，应当重写该客户的所有受影响的列。类型 1 更新必须传播到前面早期已经永久存储的阶段表，并重写所有受影响的阶段表中的数据，这些阶段表如果被用于重建最终的加载表时，才会体现出重写的影响效果 。 某些 ETL 工具包含 “UPDATE else INSERT” 功能。该功能可能给开发者带来方便， 但可能会成为性能杀手 。为了最大程度地提高性能，对已经存在的行的更新应该与对新行 的插入操作分离 。如果类型 1更新引起性能问题 ，可考虑禁用数据库日志或使用 DBMS批量加载功能。 类型 1 更新会使所有建立在改变列上的聚集操作都失效 ，因此维度管理器（子系统 17) 必须通知受影响的事实提供者（子系统 18）删除并重建受影响的聚集。



![img](https://pic4.zhimg.com/80/v2-087244fa8cdca5dc248692bde154da23_1440w.webp)



1. 类型 2：增加新行 类型 2 SCD 是一种用于跟踪维度变化并将其与正确的事实行关联的标准技术 。支持类型2变化需要强大的变化数据获取系统 ，用于检测发生的变化。对类型 2 更新来说 ，复制先前维度行的版本 ，从头开始建立新行 。然后更新行中发生变 化的列并增加所需要的其他 列。这一技术是处理 需要随时间而跟踪的维度属性变 化的主要技术 。 如果 ETL 工具不提供更新多数最近的代理键映射表这样的功能的话，类型 2 ETL 处理 需要具备该功能 。在加载事实表数据时 ，这些包含两列的小型表具有巨大 的作用。子系统 14，即代理键流水线，支持这一处理 。 参考上图，观察在获取过程期间处理变化维度行的 查询和键分配逻辑 。在该示例中 ， 变化数据获取过程（子系统 2）使用循环元余校验（CRC) 比较方法来确定上次更新以来，源数据的哪些行发生了变化。幸运的话，您已经知道哪些维度记录发生了变 化，可以忽略 CRC 比较步骤 。在确认变化的行涉及类型 2 变化后 ，可 以按照键序列建立新 的代理键井更新代 理键映射表。 当新的类型 2 行被建立后，至少需要一对时间戳 ，以及一个可选的描述变化的属性。时间戳对定义了从开始有效时间到结束有效时间之间的时间范围 ，这一范围指明了整 个维度属性的合法期 。建立类型 2 SCD 行更复杂的方法是增加 5 个附加的 ETL 管理列 。参考 上图，这需要类型 2 ETL 过程找到先前有效的行并对这些管理列进行适当的更新。 • 改变日期（改变日期作为日期维度支架 表的外键） • 行有效日期／时间（准确 的发生变化时的日期／时间戳） • 行截止日期／时间（准确 的下一次变化的日期／时间戳，大多数 当前维度行的默认值 为 12/31/9999) • 列变化原因（可选属性） • 当前标志（当前／失效）

**注意：** 在事务数据库中运行的后端脚本有可能会修改数据 ，而没有更新相应的元数据字段 ， 例如，last modified date。维度时间戳使用这些字段时可能在数据仓库中产生不一致的结果。因此要始终坚持使用系统或截止日期来获取类型2有效时间戳。

类型 2 处理不会像类型 1 那样对历史情况做出改变，因此类型 2 变化不需要重建受影响的聚集表，只要变化是 “今天” 而不是之前发生的 。

1. 类型 3：增加新属性 类型 3 技术用于支持属性发 生 “ 软” 变化的情况，允许用户既可以使用属性旧值也可以使用新值。例如，如果销售小组被分配了新的销售区域名称 ，则有可能既需要跟踪原区域名的情况 ，还需要跟踪新区域名的情况 。如果未预先考虑这种情况，那么使用类型 3 技 术需要 ETL 系统对维度表做出改变 ，在模式中增加新列 。当然 ，与 ETL 小组共同工作的 DBA 最有可能负责这一工作。您需要将己经存在的列值添 加到新增加的列中 ，并在原列中 存储 ETL 系统提供的新值 。

![img](https://pic2.zhimg.com/80/v2-73fe142b815eb0de5fd21112ccd30d39_1440w.webp)



与类型1处理类似，类型3变化更新将会导致所有针对更新列所做的聚集失效。维度管理器必须通知受影响的事实提供者，使他们能够删除并重新建立受影 响的聚集。

1. 类型 4：增加微型维度 在维度中的一组属性变化非常快的情况下 ，需要将它们划分到微型维度上 ，此时将采用类型 4 技术 。这种情况有时被称为快速变化超大维度 。与类型 3 一样，这种情况要求改变模式 ，希望在设计阶段就做好 。微型维度需要有自己的唯 一主键 ，主维度的主键和微型 维度的主键都必须出现在事实表中 。

![img](https://pic2.zhimg.com/80/v2-6930dd2e437511a6794ca241eaaf34b5_1440w.webp)



1. 类型 5：增加微型维度和类型 1 支架 类型 5 技术建立在类型 4 微型维度基础之上 ，同时在主维度的微型维度上嵌入类型 1 引用。这样可允许直接通 过主维度访 问微型维度上的当前值 ，而不需要通过事实表连接 。 只要微型维度 的当前状态随时间而发生了变 化 ，ETL 小组就必须在主维度上增加类型 1 键引用且必须在所有主维度的副本上重写该键引用。

![img](https://pic4.zhimg.com/80/v2-565b2a3762874d451a50a9b634b9b7e3_1440w.webp)



6 . 类型 6：在类型 2 维度中增加类型 1 属性 类型 6 技术包含 一个嵌入属性 ，用于作为通常的类型2属性的替换值。通常该属性就是类型3的另一种实现 ，但是在此情况下，一旦属性被更新 ，该属性将被系统性 地重写。

![img](https://pic2.zhimg.com/80/v2-161cc15e5102d4e81fd2daa885eed039_1440w.webp)



1. 类型 7：双重类型 1 及类型 2 维度 类型 7 技术是一种常见的类型 2 维度 ，与特定构建的事实表成对出现 ，它们均有一个与维度关联的常态化的外键 ，用于处理类型2历史过程 ，另外也包含一个持久性外键，用于替换类型 1 当前过程 ，连接到维度表的持久键标记为 PDK 。维度表还包含 当前行标识，表示该行是否用作 SCD 类型 1 场景。ETL 小组必须增加一个正常构建的包含 该常量值持久性外键的事实表 。

![img](https://pic2.zhimg.com/80/v2-1a026a308f46fa5ad3add98711557b15_1440w.webp)



### 3.5.2 子系统 10：代理键产生器

我们强烈建议在所有维度表中使用代理键 。要实现这一工作 ，需要一个为 ETL 系统产生代理键的健壮的机制。代理键产生器应能独立地为所有维度产生代 理键 ；它应当独立于数据库示例并能够为分布式客户提供服务 。代理键产生器的目标是产 生无语义的键 ，通常是一个整数 ，将成为维度行的主键 。

尽管可以通过数据库触发器建立代理键 ，但使用该技术可能会产生性能瓶颈 。如果由 DBMS 来分派代理键 ，这样对 ETL 过程是最好的，不需要 ETL 直接调用数据库序列产生器 。 从提高性能的角度考虑，可让 ETL 工具建立井维护代理键。要避免级联源系统的操作型键与 日期／时间戳的诱惑。尽管该方法看起来很简单 ，但始终会存在 问题，最终无法实现可扩展性 。

### 3.5.3 子系统 11：层次管理器

在维度中通常具有多个同时存在的、嵌入的层次结构。这些层次以属性的形式简单地共存于同一个维度表中 。作为维度主键的属性必须具有单一值 。层次可以是固定的也可能是参差不齐的。固定深度的层次具有一致的层次号，简单地将其建模井将不同的维度属性 添加到每个层次上就可以 。类似通信地址这样轻微参差不齐 的层次往往被建模 成固定层次。

参差不齐程度较深的层次通常都存在于组织结构中 ，具有不平衡及不确定的深度 。数据模型和ETL解决方案若需要支持此类需求，则需要采用包含组织映射的桥接表 。

不建议采用雪花或规范化数据结构表示层次 。然而，在 ETL 过渡区使用规范化设计可能是比较适合的，可用于辅助维护 ETL 数据流以添加或维护层次属性。ETL 系统负责强化 业务规则以确保在维度表中加入适当的层次 。

### 3.5.4 子系统 12：特定维度管理器

特定维度管理器是一种全方位的子系统 ：一种支持组织特定维度设计特征的 ETL 结构 的占位符。一些组织的 ETL 系统需要这里将讨论的所有能力 ，另外一些可能仅需要其中的 一些设计技术 。

1. 日期／时间维度 日期和时间维度是唯一 一种在数据仓库项目开始时就完整定义的维度 ，它们没有约定的来源 。这很好 ！通常，这些维度可能是在某个下午与报表一起构建的 。但是当处理的是跨国组织环境时 ，考虑到多个财务报表周期 或多种不同的传统日历，即使这样一个简单的维度也会带来挑战 。
2. 杂项维度 杂项维度涉及那些当您从事实表中删除 所有关键属性后遗留下来的文本和繁杂的标 识。在 ETL 系统中可以采用两种方式建立杂 项维度 。如果维度中行的理论上的号码确定并 己知，则可以预先建立杂项维度 。其他情况下 ，可能需要在 处理事实行输入时匆忙地建立 新观察到的杂项维度行 。这一过程需要聚集杂项维度属性并将它 们与己 经存在的杂项维度行 比较，以确定该行是否己经存在 。如果不存在 ，将组建新的维度行 ， 建立代理键，在处理事实表过程中适时地将该行加载到杂项维度中 。

![img](https://pic3.zhimg.com/80/v2-ef358c08cb9176d6a180ab64bf9ae00a_1440w.webp)



1. 微型维度 正如在子系统9中所讨论的那样 ，微型维度是一种用于在大型维度中当类型 2 技术不可用时 ，例如 ，客户维度，跟踪维度属性变 化的技术。从 ETL 的角度来看 ，建立微型维度 与刚刚讨论过的杂项维度处理类似 。再次说明 ，存在两个选择 ：预先建立所有的合法组合或重组并及时建立新的组合 。尽管杂项维度通常是根据事实表输入建立 ，但微型维度往往 是在维度表输入时建立 。ETL 系统负责维护多列代理键查询表 以确定基本维度号码和适当 的微型维度行 ，支持子系统 14 中将要描述的代理流水线过程 。记住，非常大的 、复杂的客户维度通常需要多个微型维度 。
2. 缩减子集维度 缩减维度是一种一致性维度，其行与／列是基维度的子集 。ETL 数据流应当根据基维 度建立一致性缩减维度 ，而不是独立于基维度 ，以确保一致性 。然而 ，缩减维度的主键必 须独立地构建 ，如果试图使用来自于 “样例” 基维度行的键 ，则当该键被弃用或废除 时将 会带来麻烦 。
3. 小型静态维度 某些维度可能是由ETL系统在没有真实的外部来源的情况下建立的 。这些维度通常是小型的查询维度 ，在该维度中操作型代码被转换为字词 。在此情况下 ，并不存在真正的 ETL 处理。查询维度简单 地由 ETL 小组直接建立 ，其最终格式为关系表 。
4. 用户维护的维度 通常数据仓库需要建立全新的 “主 ” 维度表。这些维度没有正式 的记录系统。它们是由业务报表和分析过程建立的自定义描述 、分组和层次 。ETL 小组建立这些维度通常是出 于受托责任 ，但是这样做往往不会成功 ，因为ETL 小组并不知道这些自定义分组的变化 情 况，因此这些维度会变得令人烦恼且低效 。最佳应用情况是由适当的业务用户部门负责维 护这些属性 。DW/BI 小组需要为维护工作提供适当的接口 。通常 ，这一工作呈现出简单应 用的形式并使用公司的标准可视化编程工 具建立 。ETL 系统应该为新行添加默认属性值 ， 然后由负责维护的用户进行更新 。如果这些行在没有 发生变化的情况下被加载到数据仓库中，则它们仍然会 以默认描述的方式出现在报表中 。

### 3.5.5 子系统 13：事实表建立器

事实表拥有组织的度量 。维度模型将围绕这些数字度量构建 。事实表建立器关注ETL结构化需求以有效 地建立三种主要的事实表类型 ：事务、周期快照和累积快照 。在加载事实表时一个主要的需求是维护相关维度表之间的参照完整性 。代理键流水线 （子系统 14）就 是设计来帮助实现该需求的 。

1. 事务事实表加载器 事务粒度表示一种以特定时刻定义的度量事件 。发票的列表项就是一种事务事件的示例 。现金收款台的扫描设备事件是另外一种示例 。在这些示例中 ，事实表的时间戳非常简单 。要么是一种简单的日历粒度外键 ，要么是一对包含日期 ／时间戳的日期粒度的外键 ，这 取决于源系统提供的是什么以及分析需求 。该事务表 的事实必须与粒度吻合并且仅应该描 述在那个时刻发生了什么。 事务粒度事实表是三类事实表中最大且最详细的事实表 。事务事实表加载器从变化数 据获取系统接收数据并以适当的维度外键进行加载 。仅仅加载最新记录是最容易的情况 ： 简单地批量加载新行到事实表中 。多数情况下 ，目标事实表应当按照时间分区 ，以方便管理和提高表的性能 。应当包含审计键 、系列化ID或日期／时间戳列以方便备份或重新开始加载工作 。 添加后续到达的数据要困难得多，需要在子系统 16 中讨论的额外的处理能力 。如果需要更新己经存在的行，该过程应当采取两步处理。第 1步是插入更正的行，不需要重写或删除原始行 ，然后在第 2 步中删除原始行 。在事实表中采 用顺序分配的单 一代理键 ，能够 使先执行插入后 删除的两步过程得以实现 。
2. 周期快照事实表加载器 周期快照粒度表示一种常规重复的度量或度量集合，类似银行账户每月报表 。该事实表还包含一个单一日期列，表示整个周期 。周期快照的事实必须满足粒度需求 ，仅描述适合于所定义周期的时间范围的度量 。周期快照是 一种常见的事实类型，通常用于表示账户余额 、每月财务报表以及库存余额等 。周期快照的周期通常可以是天 、周或月等 。 周期快照通常具有与事务粒度事实表类似的加载特性 。插入和更新的过程相同 。假定数据被及时发送到 ETL 系统中 ，每个加载周期的所有记录可以以最近时间分区聚类 。传统七周期快照在适当的 时期结束时将被集体加载 。 例如 ，信用卡公司可以在每月结束时按照有效余额 加载每月账户余额快照表 。更常见的是，组织将添加热轧制周期快照 。每月结束时除了加载行 外，还需要加载一些前一天的 包含最新有效余额的特殊行 。随着月的变化，当前月行不断地以最新信息更 新且连续不断 地进行 。如果周期结束时计算余额的业务规则非 常复杂的话 ，注意热轧制快照实现有时可 能非常困难。通常这些复杂的计算依赖于数据仓库之外的其他周期的处理结果，对 ETL 系 统来说 ，没有足够的可用信息来更频繁地执行这些复杂的计算 。
3. 累积快照事实表加载器 累积快照粒度表示一个有明确的开始和结束的过程的当前发展状态 。通常，这些过程持续时间较短 ，因此无法将它归类到周期快照中 。订单处理是 一种典型的累积快照示例 。 订单在一个报告期内被发出 、货运及支付 。事务粒度提供了太多的细节 ，分布在个体事实 表行中 ，报告这些数据采用周期快照是错误的方式 。 累积快照的设计和管理与其他两类事实表存在较大的差异 。所有累积快照事实表都包 含一系列日期 ，用于描述典型的处理工作流 。例如 ，订单可能包含订单日期 、实际发货日期、交货日期 、最终付款日期以及退货日期等 。在该示例中，这5个不同的日期是以5个不同的日期值代理键外键出现的 。当订单行首次建立时 ，起初这些日期定义非常好，但是也许其他的都还没有发生 。当订单在订单流水线上蜿蜒穿过时，同一个事实行被顺序访问 。 每当有事情发生时 ，累积快照事实行被修改 。日期外键被重写，各类事实被更新 。通常起初的日期仍然未受到影响，因为它描述的是行被建立的情况，但是所有其他日期都可以被重写 ，有时不止一次被重写 。 多数 RDBMS 利用可变长度的行 。对累积快照事实行的重复更新可能会导致这些可变长度行增加 ，对磁盘块造成影响 。有时偶尔在更新活动发 生后，删除并重新加载行有利于改善性能。 累积快照事实表是 一种表示具有良好定义的开始和结束的有限过程的有效方式 。然而，根据定义 ，累积快照是最近的视图 。通常利用三种事实表类型来满足各种需要 。周期 历史可以通过周期获取 ，在该过程中涉及 的所有无限的细节可 以被获取到关联事务粒度事 实表中 。在这个过程中 ，许多情况下存在的违反标准场 景或涉及重复循环的情况将阻止对 累积快照的使用 。

### 3.5.6 子系统 14：代理键流水线

所有ETL系统都包含一个将输入事实表行 的操作型自然键替换 为适当的维度代理键的 步骤 。参照完整性（Referential Integrity, RI）意味着对事实表的每个外键 ，都在对应的维 度 表中有一个入口 。如果在销售事实表中包含 一行，其产品代理键为 323442 ，则需要在产 品 维度表中具有同样的键 ，否则就无法知道卖出的产品是什么 。您卖出的产品是不存在的产 品。更糟的是，如果在维度中没有 产品键，商业用户构建 的查询将会由于无法意识到它的 存在而忽略这一销售 。 键查找过程应对每个输入自然键或默认值进行匹配 。如果在查询过程中 ，存在一个无 法解决的参照完整性错误 ，则需要反馈这些错误到负责处理的 ETL 过程去解决 。同样，ETL 过程需要解决所有在键查询过程中可能出现的键冲突 。

![img](https://pic4.zhimg.com/80/v2-bdc9040eeb83d6dd587c6ff3a62413af_1440w.webp)



事实表数据被处理后，在被加载到展现层前，需要开展代理键查找工作以用适合的当 前代理键替换事实表中的操作型自然健 。为实现参照完整性，首先需要完成对维度表的更 新。这样 ，维度表始终是必须替换的事实表的主键的合法来源。 最直接的方法是使用实际的维度表作为代理键的最新值替换对应的自然键 。每当需要 当前代理键时 ，用自然键查询与其值相等的维度中的所有行 ，然后利用当前行标识或开始 及结束有效 日期选择与事实表行历史环境对齐的代理键 。当前的硬件环境提供几乎无限的 可编址地址空 间，使该方法具有实用性 。 在处理过程中 ，输入事实记录的每个自然键被用正确的当前代理键替换 。不要将自然键保存在事实表行中 ，事实表仅需要保留唯一的代理键 。在所有事实行经过全部处理步骤 之前不要将输入数据写入磁盘 。如果可能 ，所有需要的维度表应当被固定在 内存中，这样 每个输入记录的自然键都能够随机访问相关的事实行 。 在试图加载重复行的情况下 ，代理键流水线需要处理键冲突。这情况适合于采用传统结构数据质 量屏幕处理的数据质量问题，如子系统 4 所描述的那样 。如果发现键冲突，代理键流水线过程 需要选择终止过程 ，将出现问题的数 据置于挂起状态 ，或者应用适 当的业务规则确定是否可能改正这 一错误 ，加载行并将 一个 解释行写入错误事件模式中 。 需要注意的是，如果需要加载历史记录或者如果有 一些最近到来的事实行 ，那么在处 理代理键查询的工作时存在一些轻微的差别，因为您并不需要将最新值 映射到历史事件上。 在此情况下 ，需要建立一种发现当事实记录被建立时应用代理键的逻辑 。这意味着需要发 现那些事实事务时期 处于键的有效开始日期和结束日期之间的代理键 。 当事实表的自然键被代理键替换时 ，准备加载事实表行 。要保证事实表行中的键相对 维度表具有参照完整性 。

### 3.5.7 子系统 15：多值维度桥接表建立器

有时事实表必须支持具有多值 的最低粒度事实表的维度 。如果无法改变事实表的粒度以直接支持这种维度 ，则必须采用桥接表来实现多值维度与事实表的连接 。桥接表在医疗保健行业中 ，在销售佣金环境中比较常见 ，用于支持可变深度层次 ，正 如子系统 11 所讨论的那样 。

建立和维护桥接表是 ETL 小组将面临的挑战 。当遇到事实表行存在的多值关系时 ，ETL系统可选择将每个观察值集合构建唯 一组或当相同观察值集合发生时重用该组 。遗憾的是 ， 如何选择没有简单的答案 。如果多值维度为类型 2 属性 ，桥接表也必须随时间变化 ，例如 ， 病人的随时间变化的诊断 。

多数情况下 ，权重因子是 一种熟悉的分配因子 ，但也存在一些其他情况 ，确定适当的权重因子非常困难 ，因为没有合理的分配权重因子的基础。

![img](https://pic3.zhimg.com/80/v2-c0e4af26393220999e4e8656476af5d6_1440w.webp)



### 3.5.8 子系统 16：迟到数据处理器

数据仓库通常建立于一种理想的假设情况 ，就是数据仓库的度量活动（事实记录）与度量活动的环境（维度记录）同时出现在数据仓库中 。当您同时拥有事实记录和正确的当前维度行时 ，您能够从容地首先维护维度键 ，然后在对应的事实表行中使用这些最新的键 。然而 ，各种各样的原因会导致需要 ETL 系统处理迟到的 事实或维度数据 。

在某些环境中，可能需要对标准的处理过程进行特殊的修改以处理迟到的事实 ，即延迟很久才到达数据仓库的事实记录 。这是一种混乱的局面 ，因为不得不反向搜索历史以确 定在活动发生时 ，哪些维度表键受到影响。此外 ，需要调整后续事实行中的所有半可加余额 。在高度依赖的环境中 ，还需要与依赖的子系统有接口 ，因为您需要改变历史数据 。

当行为度量（事实记录）达到数据仓库而其环境尚未获得时，将产生维度迟到 。换句话 说，与行为度量关联的维度状态在某些周期时间内是模糊的或未知的。如果您处于一两天的延迟的传统批处理更新周期中，通常能够等待维度的到来，例如，新客户的确定可能会存在几个小时的延迟 ，您可以等待直到依赖关系被解决为止 。

但多数情况下 ，特别是在实时环境中 ，这种延迟是无法接受 的。您无法悬挂行并等待 直到维度更新发生 。业务需求需要您在获知维度环境前使事实行可见 。ETL 系统需要额外的能力以支持此类需求 。以客户为问题维度 ，ETL 系统需要支持两种环境 。第 1 种环境是 支持迟到的类型 2 维度更新 。在此情况下 ，需要在维度中增加一个具有新代理键的修订客户行 ，然后更新所有后续事实行与客户表关联的外键 。受影响维度行的有效日期也需要被重置 。此外，需前向扫描维度以观察在客户维度中是否存在任何后续类型 2 行，并修改受 影响行中的列 。

第 2 种情况在当您接受某个具有有效客户自然键的事实但却不能加载该客户到客户维 度中时发生 。可以加载该行作为维度中的默认行。该方法同样具有如前所述的不良副作用， 在最终处理维度行更新时 ，需要破坏性地更新事实行外键 。作为一种选择 ，如果您认为客户是有效的 ，但是是尚未处理的客户 ，则应当分配一个新的包含 一系列哑元属性值的新客户维度行的客户代理键 。然后以最近时间返回该哑元属性行并在获得完整的新客户信息时 对该属性做出类型 1 重写改变 。这一步骤至少避免了对事实表的破坏性改变 。

无法避免维度 “不正确的” 简短的临时周期 。但是这些维护步骤可 以最小化不可避免 的对键和列的更新 的影响程度 。

### 3.5.9 子系统 17：维度管理器 系统

维度管理器是负责为数据仓库社团准备和发布一致性维度的集中负责之处 。一致性维度是一种被集中管理的资源：每个一致性维度必须具有单一的 、一致性的来源 。在组织中管理并发布一致性维度是维度管理器的责任。在组织中可能会存在多个维度管理器 ，每个维度管理器负责 一个维度 。维度管理器的责任包括下列 ETL 处理： • 实现在维度设计期间由数据管理人员和利益共同体许可的公共描述性标识 。 • 在新源数据产生后 ，在一致性维度中增加新行 ，建立新的代理键 。 • 当己存在的维度条目发生类型 2 变化时 ，建立新的代理键。 • 在类型 1 和类型 3 变化发生时 ，修改涉及的行 ，但不需要改变代理键 。 • 在类型 1 和类型 3 变化发生时 ，更新维度的版本号 。 • 将更新的维度同时复制到所有事实表提供者 。

在单一表空间 DBMS 中管理一致性维度是比较容易的 ，因为只有一个维度表副本 。然而 ，当存在 多个表空间 、多个 DBMS 或处于多机分布式环境时 ，管理一致性维度将变得非常困难 。在这些情况下 ，维度管理器必须仔细管理以确保 向每个事实提供者 同时发布维度 的新版本 。每个一致性维度的每行都应该具有 一个版本号列 ，在维度管理器发布新版本时 需要对每行进行重写操作 。该版本号应该被充分利用 ，支持所有横向钻取查询 ，保证使用 的是同一个维度版本 。

### 3.5.10 子系统 18：事实提供者系统

事实提供者负责从维度管理器接收一致性维度 。事实提供者拥有一个或多个事实表的管理权限并负责建立、维护和使用它们 。如果事实表被用于横向钻取应用 ，则按照定义，事实提供者必须使用维度管理器提供的一致性维度 。事实提供者的责任更为复杂，具体包括 ： • 从维度管理器接收或下载复制的维度 。 • 在某些环境中，维度无法被简单地复制而必须采用本地更新方法 ，此时 ，事实提供者必须处理标识为新的和当前的维度记录 ，并在代理键流水线中更新当前键映射 ，同时需要处理标识为新的但包含迟填日期的维度记录 。 • 在将自然键替换为正确的代理键后 ，在事实表中增加新行 。 • 修改由于错误更正、累积快照和迟到维度变化所涉及的所有事实表中的行。 • 将那些因为发生改变而失效的聚集删除。 • 重新计算受影响的聚集 。如果维度的新版本没有改变版本号，仅需扩展聚集以处 理那些新加载的事实数据 。如果维度的版本号发生了改变，则整个历史聚集可能 都诺要重新计算。 • 确保所有基本和聚集事实表的质量 ，这取决于对聚集表的正确计算 。 • 将更新后的事实和维度表在线发布 。 • 通知用户数据库被更新了 。如果发生了重大变化则告诉他们 ，包括维度版本改变 、 迟填日期记录被增加 ，历史聚集发生了变化 。

### 3.5.11 子系统 19：聚集建立器

在大型数据仓库环境中 ，聚集是影响性能的最富有戏剧性的方式 。聚集与索引类似 ， 它们是为改善性能而建立的特殊的数据结构 。聚集对性能具有显著的影响 。ETL 系统需要 在不造成重大干扰或消耗大 量资源及处理周期的情况下 ，有效地建立并使用聚集 。

应当避免将聚集导航的结构建立在专用的查询工具中 。从ETL 的视角来看，聚集建立 器需要加入并维护聚集事实表行并缩减聚集事实表需要的维庭表 。最快的更新策略是增量 式更新 ，但对维度属性的主要挑战可能是需要删除 并重建聚集 。在某些环境下 ，更好的方 法是将数据转储到 DBMS 之外 ，使用实用程序建 立聚集而不是在 DBMS 中建立聚集。可 加数字事实在获取阶段的早期利用软件包中的计算拆行方便地被聚集 。聚集必须与原子基 本数据保持一致性 。当聚集与基本数据出现一致性问题时 ，由事实提供者（子系统 18）负责 将这些聚集离线 。

用户反馈查询速度缓慢是设计聚集的关键输入 。尽管能够在某种程度上依靠非正式的反 馈，但经常导致运行缓慢的查询应 当由日志捕获。还应当努力区分那些从未进入到日志中的 不存在的运行缓慢的查询 ，它们不会完成运行 ，或者它们根本未成为己知的性能挑战 。

### 3.5.12 子系统 20: OLAP 多维数据库建立器

OLAP 服务器以一种更直观的方式展现维度数据 ，确保一些分析用户能够对数据进行 切片和切块操作 。OLAP 与建立在关系数据库之上的维度星型模式类同 ，都包含定义在服务器之上的关系和计算的智能 ，能够确保使用范围广 泛的查询工具获得 良好的查询性能和 更有趣的分析 。不要将 OLAP 服务器 当成关系数据仓库的竞争者 ，但也不要仅仅将其当成 是对关系数据仓库的扩展 。让关系数据库去做它们最擅长的工作 ：提供存储及管理功能 。

如果您在结构中选择了关系型维度模式和 OLAP 多维数据库，应将关系型维度模式视 为 OLAP 多维数据库的基础 。从维度模式中获取数据的过程是 ETL 系统的一个组成部分 ： 关系模式是 OLAP 多维数据库最好的和首选的来源 。因为多数 OLAP 系统并不直接解决参照完整性或数据清洗 ，所以首选的结构 是在传统的 ETL 处理执行完成后 ，加载 OLAP 多维 数据库 。注意某些 OLAP 工具比关系模式对层次更加敏感 。在加载 OLAP 多维数据库前， 强化维度内层次结构的完整性是非常 重要的。类型2 SCD 适合 OLAP 系统 ，因为新的代理 键被视为新成员 。类型 l SCD 由于重申了历史而不适合 OLAP 。对属性值的重写可能会导 致所有的使用此经过再加工背景的维度的多维数据库被损坏 ，或者被删除 。请再次阅读最 后这句话以引起重视 。

### 3.5.13 子系统 21 ：数据传播管理器

数据传播管理器负责需要将一致的 、集成的企业数据从数据仓库展现服务器发送到其 他环境中以应对特殊目的的 ETL 过程。多数组织需要从展现层获取数据供业务合作方 、客户以及特定目的供应商共享 。类似地，一些组织还需要提交数据到各种政府组织以完成支付目的 ，例如 ，参与医疗保险项目的保健组织 。多数组织都有分析应用软件包 。通常 ，这些应用不能直接访问现存的数据仓库表 ，因此需要从展现层获取数据并 加载分析应用需要 的专用数据结构 。最后 ，多数数据挖掘工具无法直接在展现服务器运行 。它们需要数据仓 库的数据以满足特定格式需要的数据挖掘工具 。

前面描述的所有情况需要 从 DW/BI 展现服务器获取 ，可能需要轻微的转换并加载到目 标格式 换句话说 ，需要 ETL 处理 。数据传播应该被当成 ETL 系统的一部分 。应利用 ETL 工具提供这些能力 。在此情况下 ，不同之处在于目标的需求是很难兑现的 。您必须提 供由目标指定的数据 。

## 3.6 管理 ETL 环境

DW/BI 环境可能包含 一个巨大的维度模型 、仔细部署的 BI 应用以及强大的管理支持 。 但在它作为业务决策支持的可 以依赖的可靠数据来源前 ，这种环境还远未成功 。DW/BI 系统的目标之 一是为了授权业务而建立及时的、一致的和可靠的数据提供的保障 。为实现这一目标，ETL 系统必须不断工作以实现 以下三个标准 ： • 可靠性 。ETL 过程必须始终在运行 。它们必须运行以完成提供及时的数据 ，这些 数据的所有细节级别都是值得信任的 。 • 可用性 。数据仓库必须满足其服务级别协议（ Service Level Agreement , SLA） 。数据 仓库应做出承诺 。 • 可管理性 。成功的数据仓库是永远无法实现的 。它将随着业务的发展而不断发展 变化。ETL 过程需要不断改进 。

ETL 管理子系统是帮助实现可靠性 、可用性和可管理性目标的结构的关键部件 。以专业的方式操作和管理数据仓库与其他系统操作并无大的区别 ：遵循标准最佳实践 、建立应对灾难的预案 ，加以实践 。对您来说 ，后续讨论的大 多数必要的管理子系统可能是非常熟 悉的。

### 3.6.1 子系统 22 ：任务调度器

所有企业数据仓库应该具有 一个健壮的 ETL 调度器 。整个ETL 过程在可能的范围内应该是可管理的，主要是通过元数据驱动的任务控制环境来实现 。主要的ETL 工具提供商在 他们提供的环境巾都包 含调度能力 。如果您选择使用包含在 ETL 工具中的调度器 ，或者不使用ETL 工具 ，都需要利用现存的生产调度或手工编码 ETL 任务来执行 。

调度不只涉及按照、计划分派任务 。调度器需要意识到并能够控制 ETL 任务之间的关系和依赖 。需要认识到何时将处理某个表或文件 。如果组织工作处理为实时处理 ，则需要调度器支持您所选择的实时结构 。任务控制处理还必须获取有关进展情况和执行过程中 ETL 处理的统计情况 的元数据 。最后 ，调度器需要支持完整的自动化过程 ，包括在任何情况下 需要解决的通知升级系统的问题。

管理这些的基础可简单地采用 SQL 存储过程，或复杂地采用为 管理并协调多平台数据 技取和加载过程而设计的集成工具 。如果使用 ETL 工具 ，它应 当提供这种能力 。无论哪种情况 ，都需要设置建在 、管理和监视 ETL 任务流的环境 。

**任务控制服务需要包含 ：** • 任务定义 。建立操作过程的第 1 步是采用某些方式定义任务的步骤并定义任务之 间的关系。该步编写 ETL 过程的执行流程 。多数情况下 ，如果给定表的加载出现 问题，则将影响加载那些与之关联的表的能力 。例如 ，如果客户表无法正确更新 ， 则加载尚未存在于客户表中的新客户的销售事实将存在风险 。在有些数据库中 ， 这种加载将无法实现 。 • 任务调度 。至少，环境需要提供标准能力 ，例如 ，基于时间或基于事件的调度 。 ETL 过程通常基于某些上游系统的事件 ，例如 ，成功完成总分类账或对昨天的销 售指标成功应用销售调整 。这些工作包含监视数据库标识 、检查现存文件并比较 建立日期等工作 。 • 元数据获取 。没有人能够容忍黑盒式的调度系统 。负责运行加载的工作人员梦想 能够使用工作流监控系统 （子系统 27）以了解发生了什么事情 。任务调度器需要 获 取有关加载步骤进展情况的信息 ，该加载步骤的开始时间 ，力日载进行了多长时间 。 在手工操作的 ETL 系统中 ，这一信息 的获取是通过将每一步骤写入日志文件来实 现的。 • 日志记录。日志记录意味着收集有关整个 ETL 过程的信息 ，不只包含某一时刻发 生了什么 。日志信息支持一旦在任务执行期间发生错误时的恢复和重启过程 。将 日志记录到文本文件中是可接受的最低要求 。我们宁愿将日志记录到数据库中 ， 因为数据库的日志结构使其能够方便地建立图和报表 。也可以建立时间序列研 究 以帮助分析和优化加载过程 。 • 通知 。ETL 过程开发并部署之后 ，就可以不需要人参与地执行 。其运行不需要人 的干预也不会出现错误 。如果有问题发 生 ，控制系统需要与 问题升级系统（子系统 30）交互 。

**注意：** 有人需要知道在加载过程中是否有未预期的事情发生，特别是如果某个响应对后续工作完 成是至关重要的情况下。

### 3.6.2 子系统 23 ：备份系统

数据仓库与其他计算机系统 一样易遭受同样的风险 ，例如 ，磁盘驱动器错误，电源供应中断 ，自动喷水灭火系统意外开启 。除这些风险外 ，仓库还需要存储比操作型系统更多的长期数据。尽管通常不是由 ETL 小组来管理 ，但备份和恢复过程通常是 ETL 系统设计 的一部分工作 。其目标是允许数据仓库在发生错误后能够继续工作 。这一工作包括备份需 要的中间数据以便能够重启发生错误的 ETL 任务 。存档与检索处理被设计用来确保用户能 够访问己经从数据仓库移出到开销较低的 、性能较差的介质巾的历史数据。

1. 备份 即使有一个完整的具有通用电源的冗余系统 ，完整的 RAID 磁盘 ，并行处理器处理故 障转移，一些系统危机也仍然会如期而至 。即使采用了最好的硬件 ，人们也仍然会需要删除错误的表（甚至是数据库 ） 。上述陈述中存在 的风险是显然的 ，为这些可能出现的问题做 好准备而不是在匆忙中处理它们效果会更好 。完整的备份系统应该提供如下能力 ： • 高性能 。备份需要与分配的时间符合 。可能包括在线备份 ，这种方式不会对性能 造成显著的影响 ，也包括实时分区 。 • 简单的管理 。管理接口应该提供允许用户方便地区分备份对象 （包括表、表空间 、 重做日志等）的工具 ，建立调度计划 ，维护备份验证并为随后的恢复建立日志 。 • 自动化的、远程代理操作 。备份实用程序必须提供存储管理服务 、自动调度、介 质与设备处理 、报告 、通知等 。

数据仓库的备份通常是物理备份 。这是数据库系统在某一时间点的完整映像 ，包括索引和物理规划信息 。

1. 归档与检索 确定将什么信息移出数据仓库是 一个涉及成本效益的问题 。保存数据需要成本 一 一它 会占用磁盘空间并使加载和查询时间变慢 。另一方面 ，业务用户可能仅仅需要这些数据来 完成一些关键的历史分析 。同样，审计师可能需要归档数据进行合规检查 。解决方案是不 要将这些数据抛弃 ，但要将其放入开销更低但仍然能够访问的地方 。归档是数据仓库的数 据安全保障 。 在撰写本书时 ，在线磁盘存储的开销快速下降，因此多数归档任务的规划可以简单地 将它们写到磁盘中。特别是如果磁盘存储由不同的IT 资源处理的情况下 ，对“ 迁移并恢复” 的需求被 “ 恢复 ” 所替代 。您需要确保未来能够从不同的角度解释数据 。 数据需要被保持多久与行业 、业务以及考虑中 的特定数据有关 。某些情况下 ，以往的 数据显然 己经几乎没有什么价值 。例如 ，在新产品和竞争者不断变化的行业 ，历史数据无 法帮助您理解现状并预测未来 。 在将某些数 据进行归挡的决策制定完成后 ，问题就变为 “ 归档数据的长期影响是什 么？” 显然 ，您需要利用现存的机制 ，将其从当前介质移动到另外的介质 中，确保能够将 其恢复 ，保留负责访问井替换数据的审计线索 。但是 “保留” 过去的数据意味着 什么呢？ 给定不断增长 的审计和合规性关注 ，您可能会面对归档需求 ，考虑将其保存 5 年或 10 年， 甚至 50 年。您将利用何种介质 ？在未来的岁月中您还能读取这些介质 吗？最终 ，您可能会 发现自己实现了一个图书馆系统 ，能够归档并定期恢复数据 ，然后将其迁移 到当前结构和介质中。 最后 ，如果您正在从系统中归档不再需要使用的数据，您可能需要将其以独立于原始应用的普通格式写入 。如果应用所使用的许可将被中断 ，您可能需要采用这样 的方式。

### 3.6.3 子系统 24 ：恢复与重启系统

ETL 系统投入实际工作后 ，在控制 ETL 过程时 ，会有无数的原因可能会导致错误 的发 生 。ETL 处理发生错误 的常见原因包括 ： • 网络错误 • 数据库错误 • 磁盘错误 • 内存错误 • 数据质量错误 • 突然发生的系统升级

为使您能够不受这些错误的影响 ，需要一个固定的备份系统 （子系统 23）以及与之相伴 的恢复和重启系统 。您必须为加载过程中可能出现的不可恢复错误制订规划 ，因为它们一 定会发生 。系统应当能够预见这些情况并提供灾难恢复 、停止和重启能力 。首先，寻找合 适的工具并设计将灾难的影响最小化的处理方法 。例如 ，加载过程应该 一次提交相对小的 记录集合并对提交的过程进行跟踪 。记录集合的大小应该是可调整的 ，因为对不同的 DBMS 来说 ，事务大小对性能具有潜在的影响 。

当然，恢复和重启系统要么继续进行停止了的工作，要么回滚所有的工作并重新开始 。 这一系统显然依赖于备份系统的能力 。在错误发生时 ，最初的本能反应是试图保留己经处 理过的任务并从错误点重新开始 。这样做需要ETL 工具具有稳定可靠的检查点机制 ，可以 准确地确定什么己经被处理过 ，什么还未被处理 。多数情况下 ，最好的办法是对那些作为 一个过程被加载的行进行回滚操作并重新开始 。

我们通常建议在设计事实表时 ，让其带有 一个单列代理键主键 。该代理键是一个简单 的按照顺序分配的整数 ，在行添加到事实表时建立 。利用事实表代理键 ，可以方便地恢复 被终止的加载或通过限制代理键范围回滚加载中的所有行 。

**注意:** 事实表代理键在 ETL 后段有许多作用 。首先 ，如前所述 ，它们可用作回滚或重启被中断的力口载的基础。其次 ，它们提供了单 一行的直接和明确的标识 ，不需要约束多 个维度以 获取唯一行。第二 ，更新事 实表行可以用插入加删除来实现 ，因为 事实表代理键是事实表 的一个实际可用的键 。因此，包含更新列的行可 以被插入到事实表中而无须重写需要被替换的行。在所有插入操作完成后 ，利用一步过程直接将所有涉及的原始行删除。第四，事实表代理键是一种理想的应用 于父／子设计的父键。事 实表代理键可作为 子节点的外键 ，也 可以作为 父维度外键。

ETL 运行的过程越长 ，您必须意识到出现错误的可能就越大 。设计针对灾难和未预期中断的具有弹性的高效过程构成的模块化 ETL 系统，可以减少导致大量恢复工作的错误的风险 。仔细考虑何时物理地将数据写到磁盘上 ，仔细设计恢复 和加载日期／时间戳 ，顺序化事实表代理键，从而确保定义合适的重启逻辑 。

### 3.6.4 子系统 25：版本控制系统

版本控制系统是一种针对 ETL 流水线中所有逻辑和元数据进行归档和恢复时 具有 “快 速拍照” 能力的系统 。它控制所有 ETL 模块和任务的签出及签入处理 。它应当支持对源的 比较工作以揭示版本之间的差别。该系统提供图书馆功能 ，用于保存和恢复单 一版本的完整 的 ETL 环境。在某些高度 一致的环境中 ，归档完整的 ETL 系统环境以及相关归档和备份数 据是同样重要的。注意需要为整个的 ETL 系统分配主版本号 ，就像软件发布版本号 一样。

**注意:** 对每个 ETL 组成部分都有一个主版本号 ，该版本号对整个系统都一样吗 ？如果当 前的 版本存在较大的错误，您可以恢复昨天的完整的 ETL 元数据环境吗 ？如果是这样 ，感谢您 能让我们放心。

### 3.6.5 子系统 26 ：版本迁移系统

在 ETL 小组完成了设计和开发 ETL 过程井建立了加载数据到数据仓库的任务后 ，按照组织所采纳的生命周期 ，任务必须被绑定并迁移到下一个环境一一从开发到测试到最终投入运营。版本迁移系统需要与版本控制系统建立接口 ，以控制过程及在必要时备份迁移 。 应当为整个版本提供单一的接口以设置连接信息。

多数组织将开发 、测试、运营环境分离 。要能够迁移 ETL 流水线的整个版本 ，从开发 到测试 ，最终到运营环境 中。理想的情况是，测试系统与其对应的运营环境 具有相同的配 置 。运营系统中 的所有工作应当在开发环境中设计完成并在测试环境中部署脚本测试 。所 有后端操作应该进行严格的测试并脚本化，无论是部署新的模式 、增加列 、改变索引、改 变聚集设计 、修改数据库参数 、备份还是恢复 。对前端操作实行 集中式管理，在 BI 工具许 可的情况下 ，部署新的 BI 工具、部署新的公司报表、改变安全计划都应当执行严格的测试 和脚本化。

### 3.6.6 子系统 27 ：工作流监视器

成功的数据仓库具有一致且可靠的可用性，并得到商业团体的认可 。为实现这一目标， ETL 系统必须持续监视 ，保证 ETL 过程操作的有效性 ，保证数据仓库能够连续及时地进行加载。任务调度器（子系统 22）应在每次 ETL 过程开始时获取性能数据 。该数据是从ETL 系统获取元数据的过程的组成部分 。工作流监视器利用任务调度器获取的元数据提供考虑到 的 ETL 系统的各个方面的工作控制板和报告系统。您将监视任 务调度器发起的任务的状 态 ，包括 处于挂起 、运行 、完成和延迟等状态的任 务 ，获取历史数据 以支持随时间变化的 性能趋势。关键性能度量包括被处理的记录 的数量 、错误摘要 、采取 的措施等 。多数 ETL L具获取度量用于评估 ETL 性能 。一旦 ETL 任务花费 比历史记录更少或更多 的时间时就 触发报警 。 与任务 调度器配合 ，工作流监视器还应 当跟踪性能并获取基础部件的性能 ，包括 CPU 使用情况 、内存分配与争夺情况、磁盘利用与争夺情况、缓冲池使用情况、数据库性能 、 服务器使用与争夺情况 。多数此类信息会 处理与 ETL 系统相关的元数据 ，应当被作为 整个 的元数据策略（子系统 34）加以考虑。

工作流监视器能够起到比您想象的更多的策略性作用 。它是整个 ETL 流水线性能问题 分析的基础 。ETL 性能瓶颈可能会存在 于多个地方 。以下列表或多或少地列出了最重要 的瓶颈问题： • 针对源系统和中间表的低效索引查询 • SQL语法导致优化器做出错误的选择 • 随机访问内存(RAM)不足导致的内存颠簸 • 在 RDBMS 中进行的排序操作 • 缓慢的转换步骤 • 过多的 I/O 操作 • 不必要的读写 • 重新开始删除并重建聚集而不是增 量式地执行这一操作 • 在流水线中过滤（改变数据获取）操作应用太迟 • 未利用并行化和流水线方式 • 不必要的事务日志 ，特别是在更新时存在的事务日志 • 网络通信及文件传输的开销

### 3.6.7 子系统 28 ：排序系统

某些常见的 ETL 过程调用需要按照特定的顺序对数据进行排序 ，例如 ，聚集和连接平面文件资源 。由于排序是非常基础的ETL 处理能力 ，所以将其拿出作为 一个不同的子系统 以确保其作为一个 ETL 结构的组件而受到适 当的关注。一系列的技术可提供排序能力 。毫无疑问 ，ETL 工具能够提供排序能力 ，DBMS 可以通过 SQL SORT 子句提供排序能力 ，存 在大量排序实用程序可以使用 。

使用专用排序软件包排序简单分隔的文本文件非 常快。这些软件包通常允许简单读操 作产生多达 8 个不同的排序输出 。排序可以产生聚集 ，其中每个给定排序的中断行成为聚 集表的一行，排序加计数通常是一种用于诊断数据质 量问题的良好方式。

关键是选择最有效的排序资源 以支持您的基本需求 。对多数组织来说 ，简单的方式是 利用 ETL 工具的排序功能 。尽管 ETL 和 DBMS 提供商声称存在较大的性能差异，然而 ， 在某些环境下 ，使用专用排序软件包效果会更好 。

### 3.6.8 子系统 29 ：世系及依赖分析器

在 ETL 系统中两个重要性逐渐增加的元素是跟踪 DW/Bl 系统中存在的数据世系和依赖 ： • 世系。以中间表或 BI 报表的特定数据元素开始 ，识别数据元素的来源 、包含该元 素及其来源 的其他上游的中间表 ，以及该元素及其来源的所有转换。 • 依赖。从包含在源表或中间表的特定 数据元素开始 ，识别所有包含该元素或根据 其推导产生的下游中间表和最终的 BI 报表 ，还包含所有应用到该数据元素的转换 和其派生元素 。

世系分析通常是高度兼容环境中的重要组件 ，必须解释改变数据结果的完整的处理流 程 。这意味着 ETL 系统必须展示任何被选择的数据元素的最终的物理来源以及所有后续的 转换 ，要么从 ETL 流水线中间开始 ，要么从最终发布的报 表开始选择 。在对源系统的变化 以及对数据仓库和 ETL 系统下游的影响进行评估时 ，依赖分析是非常重要的手段 。这意味 着展示所有受影 响的下游数据元素和受到潜在改变影响的最终报表 宇段 ，要么从 ETL 流水 线中间要么从原始来源开始（依赖 ）。

### 3.6.9 子系统 30：问题提升系统

通常，ETL 小组开发 ETL 过程，质量保证小组对相关工作进行全面测试 ，然后移交给负责日常系统操作的小组 。为使工作顺利开展 ，ETL 结构需要包括一个主动设计的 、与其 他生产系统功能类似的问题提升系统 。

在 ETL 过程被开发完成并通过测试后 ，ETL 系统操作型支持的第 1 个层次是专门监视 上线系统应用 的小组。只有当操作型支持小组无法解决上线系统的问题时 ，ETL 开发小组 才会涉及其中 。

理想情况下，您开发了 ETL 过程 ，用自动调度器对它 们进行包装 ，具有健壮的工作流 监视能力用于监视 ETL 过程的执行 。ETL 系统的执行是一种自动操作过程 。它以类似时钟那样的方式精确地无须人类干预地开展工作 。如果有问题产生 ，ETL 系统会自动将那些需 要注意和解决的问题通知问题提升系统 。这一自动反馈 可以采用错误日志 、操作员通知消 息、监督人通知消息 、系统开发者消息等简单 的方式。ETL 系统可以根据问题的严重程度 或涉及的过程情况通知 个人 ，也可以通知小组 。ETL 工具可支持各种类型的消息能力 ，包 括电子邮件报警 、发送操作员消息以及通过移动设备发送通知 。

每个通知事件都应当被写入数据库中 ，用于理解产生的问题的类型 、问题的状态以及 解决 问题的方案。这些数据是 由ETL 系统（子系统 34）获取的过程元数据的组成成分 。您需 要保证组织的过程能够被适当 地提升 ，这样才能使问题得到适当的解决 。

一般来说 ，ETL 系统的支持结构应当遵循一 个相当标准的支持结构。首先 ，帮助台是 层次支持的第一个级别 ，是用户通知错误时的第一个接 触点。帮助台负责确定有用的解决 方案 。如果帮助台无法解决问题 ，第二个支持级别将会得 到通知。这个层次通 常是在线系 统控制技术人员中的系统管理员或 OBA ，能够对一般的基础设施方面的错误提供支持 。ETL 管理人员是第三层支持 ，可以对 ETL 生产过程中出现的大多数问题提供解决方案 。最后 ， 当所有支持都无法奏效时 ，应该去找 ETL 开发人员 ，以分析形势并协同解决相关问题 。

### 3.6.10 子系统 31 ：并行／流水线系统

ETL 系统的目标 ，除了提供高质量的数据以外，还包括在分配的 处理窗口内加载数据 仓库 。在大型组织中 ，包含大量的数 据、大型的维度和大量的事实 ，在这些限制条 件下加 载数据是极富挑战性的工作 。并行／流水线系统提供了在面对这些限 制时保证 ETL 系统得 以发布的能力。该系统的目标是利用多个处理器或可用的网格计算资源 。并行化和流水线 化是非常可取的 ，多数情况下是需要的 ，在 ETL 过程中自动被激活 ，除非特殊的条件阻碍 了该方式的利用，例如 ，过程中出现的 等待条件等 。

并行化是一种 ETL 流水线的每个阶段都可以采用 的强大的改善性 能的技术 。例如 ，在 获取阶段 ，按照针对属性范围的逻辑分区并行化 。需要验证源 DBMS 处理并行化的正确性 且不会产生冲突 的过程。如果可能 ，应选择 ETL 工具自动处理中间转换过程的并行化工作 。 但某些工具可能需要手动建立并 行处理过程 。这是非常好的方式 ，当然需要增加额外的处 理器 ，ETL 系统无法利用更大的并行化机会 ，除非手动增加井行处理流 的数量。

### 3.6.11 子系统 32 ：安全系统

安全是ETL 系统需要考虑的重要因素之一。严重违反安全的情况最有可能来自组织内部而不是来自外部黑容 。尽管我们不愿意提及 ，但 ETL 小组的成员比组织中的其他小组造成的潜在威胁更大 。我们建议对 ETL 系统 的所有数据和元数据采取基于角色的安全管理 。为支持合规性要求 ，您可能需要证明 ETL 模块的版本未被改变或展示谁对模块进行了修改。您应当对 ETL 数据和元数据按照个人或角色执行全面的授权访问 。另外一个需要考虑 的问题是批量数据移动过程 。如果是通过网络移动数据 ，即使是在组织的防火墙内进行 这 一工作 ，也需要高度关注 。确保使用数据加密或应用安全传输协议的文件传输实用程序 。

另外一个需要考虑的后端安全 问题是管理员访问生产数据仓库服务器或软件 。我们发 现很多情况下 ，小组中无人具有安全权限 ，此外，在某些情况下还存在每个人都具有访问 一切的权限 。显然 ，小组的多数成员应该具有访问开发环境的权限 。另一方面 ，如果出现 严重错误 ，DW/BI 小组的人员需要能够重置数据仓库服务器 。最后 ，备份介质应当受到保 护。备份介质应当受到与在线系统 一样的安全保护 。

### 3.6.12 子系统 33：合规性管理器

在高度兼容的环境中 ，支持合规性需求对 ETL 小组来说显然是比较新的需求。数据仓库的合规性涉及数据的“ 维护监管链”。与警察部 门必须仔细维护证据的监管链以确认证 据 未被改变或篡改一样 ，数据仓库也必须仔细保护合规性敏感的数据从其到来后具有可 信度。 此外 ，数据仓库还必须始终显示此类数据在任何时间 点的精确的环境和内容 ，保证其能够 处于数据仓库的掌控中 。最后 ，当疑点审计人员审计数据时 ，您必须反向连接数据的归档 和时间戳版本 ，展示其原始获取时的情况 ，尽管当前已经远 程存储于可信的第三方机构中 。 如果数据仓库准备满足所有这些合规性需求 ，则来自充满敌意 的政府机构和手持传票的律 师的要求进行审计的压力将会大大减少 。

合规性需求可能意味着无论有何种理由 ，1$ 实际上都不能改变任何数据 。如果数据必 须被改变 ，被改变记录的新版本必须插入到数据 库中 。表中每行 必须包含开始和结束时间 戳，准确地表示记录是 “当前事实” 的时间范围 。数据仓库中这些合规性需求的巨大 影响 可以采用简单的维度建模术语来 表达 。类型 l 和类型 3 变化是无法采用的 。换句话说 ，所 有的变化都变成插入 。没有删除和重写 。

下图展示了如何强化 事实表 以便重写变化能够按照类型 2 变化被转换到 事实表中 。 表中原始事实表的后 7 列从活动日起开始到净利润 结束 。原始事实表可以被重写 。例如 ， 也许存在一条业务规则 ，在行最初被建 立后更新折扣与净利润 。在表的原始版本中 ，当重 写改变发生时 ，历史情况将不复存在 ，维护监管链将会 断裂。

为将事实表转换为合规性使能 的表 ，增加了 5 个列 ，如图中粗体字所表示的列 。为每 个未改变的事实表行建立 了事实表代理键 。这一代理键类似维度表代理键 ，仅仅是一个在 原始事实表建立时分配的具有唯 一性的整数 。开始版本的日期／时间戳表示 的是事实表中每 行建立时的准确时间 。最初 ，最终版本的日期／时间被设置为虚拟的未来日期 ／时间 。变化 引用被设置为 “初始”，源引用被设置为操作型源 。

在重写发生后 ，包含类似的事实表代理键的新行被添加到 事实表中 ，适当的固定列发 生改变，例如 ，折扣额度与净利润 。当数据库发生变化时 ，日期／时间列的开始版本被设 置 为准确的日期／时间。日期／时间的结束版本现在被设 置为未来 的虚拟日期／时间。当数据库 发生变化时 ，原始事实行的日期 ／时间的结束版本被设置为准确的日期 ／时间。变化引用现 在可以提供对变化的 一种解释 ，源引用提供修改后的列 表示的源。



![img](https://pic3.zhimg.com/80/v2-b7a8e05f4818346d408a26f04bd432f6_1440w.webp)



参考上图的设计，可以选定特定时刻 ，以及通过约束事实表获得其此时包含的准确的行。给定行的改变可以通过约束特定事实表代理键并按照开始版本的日期 ／时间进行验证 。

合规性机制是对普通事实 表的明显改进。如果合规性使能的表仅仅为表 示合规性而被实际应用 ，则包含原始列的事实表的普通版本可以作为主要 的操作型表而保 留，其合规性使能表仅存在于背景中 。出于性能方面的考虑 ，合规性使能表不需要被索引 ， 因为传统的 BI 环境并不会使用它 。

不要认为所有的数据现在受到严格的合规性约束 。在采取任何严格的步骤前 ，您会接 收到来 自CCO（首席合规官）的严格的指导 。 合规性系统的基础是几个己经被描述过的采用 一些关键技术和能力的子系统之间的交互 ： • 世系分析 。表示最终数据块的出处 ，证明原始源数据增加了包括存储过程和手动 改变的转换。这需要针对所 有转换和技术能力的所有文档 ，以确保能够重现针对 原始数据的转换 。 • 依赖分析 。展示原始数据源的 数据在何处被使用过 。 • 版本控制 。可能还需要通过 当时有效的 ETL 系统重新运行源数据 ，需要任何给定 数据源的 ETL 系统的准确版本 。 • 备份与恢复 。当然，请求的数据可能多年前就已经被归档了 ，出于审计的目的， 可能需要被恢复 。希望在归档时除了归档数据外 ，还对 ETL 系统进行归档 ，这样 无论是数据还是系统都可以被恢 复。有必要证明归档的数据未被修改 。在归档过 程中 ，数据可 能是采用散列编码归档的 ，散列表和数据是分开存放的 。将散列编 码归档于不同 的可信第三方组织中 。这样 ，在需要时 ，恢复原始的数据 ，重新进 行散列 ，然后与存储在可信第三方的散列编码进行比较 ，以证明数据的真实性 。 • 安全。展示谁访 问或修改了数据和转换 。准备展示用户的角色和权限 。采用一次 写入介质来确保安全日志 未被修改。 • 审计维度 。审计维度将运行时的元数据环境直接与加载时获取的质量事件的数据 联系起来 。

### 3.6.13 子系统 34：元数据存储库管理器

ETL 系统负责使用并建立 DW/BI 环境中的大多数元数据 。整个元数据策略的部分 工 作涉及专 门获取 ETL 元数据 ，包括过程元数据 、技术元数据和业务元数据 。需要在什么都 不做和什么都做之间设计出 一种平衡的策略 。确保在 ETL 开发任务中有时间来获取和 管理 元数据 。最后，确保在 DW/BI 小组中指派人员作为元数据管理员并负责建立并实现元数据策略。