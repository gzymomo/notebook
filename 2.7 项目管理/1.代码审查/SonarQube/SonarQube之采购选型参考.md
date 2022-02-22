- [SonarQube之采购选型参考](https://www.cnblogs.com/FLY_DREAM/p/15917157.html)

SonarQube是DevOps实践中主流的一款质量内建工具，过插件机制，Sonar 可以集成不同的测试工具，代码分析工具，以及持续集成工具，比如pmd-cpd、checkstyle、findbugs、Jenkins。

通过不同的插件对这些结果进行再加工处理，通过量化的方式度量代码质量的变化，从而可以方便地对不同规模和种类的工程进行代码质量管理。同时 Sonar 还对大量的持续集成工具提供了接口支持，可以很方便地在持续集成中使用 Sonar。**一般情况下，社区版还是可以满足大部分场景的，即便是C/C++社区也是有其他开源插件的。**

## 工作原理

SonarQube 并不是简单地将各种质量检测工具的结果（例如 FindBugs，PMD 等）直接展现给客户，而是通过不同的插件算法来对这些结果进行再加工，最终以量化的方式来衡量代码质量，从而方便地对不同规模和种类的工程进行相应的代码质量管理。 SonarQube 在进行代码质量管理时，会从图 1 所示的七个纬度来分析项目的质量。
​

[![image.png](https://img2022.cnblogs.com/blog/108082/202202/108082-20220221000016068-103882050.png)](https://img2022.cnblogs.com/blog/108082/202202/108082-20220221000016068-103882050.png)
​

SonarQube 可以支持 25+ 种编程语言，针对不同的编程语言其所提供的分析方式也有所不同： 对于所有支持的编程语言，SonarQube 都提供源了代码的静态分析功能； 对于某些特定的编程语言，SonarQube 提供了对编译后代码的静态分析功能，比如 java 中的 class file 和 jar 和 C# 中的 dll file 等； 对于某些特定的编程语言，SonarQube 还可以提供对于代码的动态分析功能，比如 java 和 C# 中的单元测试的执行等。

[![image.png](https://img2022.cnblogs.com/blog/108082/202202/108082-20220221000016082-1200680321.png)](https://img2022.cnblogs.com/blog/108082/202202/108082-20220221000016082-1200680321.png)
远程客户机可以通过各种不同的分析机制，从而将被分析的项目代码上传到 SonarQube server 并进行代码质量的管理和分析，SonarQube 还会通过 Web API 将分析的结果以可视化、可度量的方式展示给用户
​

## 软硬件要求

1. 硬件上对磁盘读写性能要求高，服务涉及elasticsearch索引，IO读写和分析的代码量直接影响sonarqube性能；实际生产环境建议使用专用高速I/O存储
2. SonarQube server 不支持32位，但 SonarQube scannner支持32位
3. SonarQube server 仅支持Java11; SonarQube scanners 同时支持Java8&11
4. 数据库支持PostgreSQL, MSSQL Server, Oracle, 不再支持Mysql
   ​

## 版本分类

| **类型** | **全称**            | **说明**                       |
| -------- | ------------------- | ------------------------------ |
| CE       | Community Edition   | 社区版                         |
| DE       | Developer Edition   | 开发版（具有CE版所有特性）     |
| EE       | Enterprise Edition  | 企业版（具有DE版所有特性）     |
| DCE      | Data Center Edition | 数据中心版（具有EE版所有特性） |

[![image.png](https://img2022.cnblogs.com/blog/108082/202202/108082-20220221000016106-1825260261.png)](https://img2022.cnblogs.com/blog/108082/202202/108082-20220221000016106-1825260261.png)

## 特性费用对比

https://www.sonarsource.com/plans-and-pricing/community/

https://www.sonarsource.com/plans-and-pricing/developer/

https://www.sonarsource.com/plans-and-pricing/enterprise/

https://www.sonarsource.com/plans-and-pricing/data-center/

| **类型** | **价格**           | **LOC**              |
| -------- | ------------------ | -------------------- |
| CE       | 免费               | -                    |
| DE       | 120欧元-5万欧元    | 10万行代码-20M行代码 |
| EE       | 1.5万欧元-18万欧元 | 1M行代码-100M行代码  |
| DCE      | 10万欧元-上不封顶  | 20M代码-             |

### CE-社区免费版本

[![image.png](https://img2022.cnblogs.com/blog/108082/202202/108082-20220221000016093-670335519.png)](https://img2022.cnblogs.com/blog/108082/202202/108082-20220221000016093-670335519.png)

除了支持15种编程语言，CE版还就有如下特性

- 支持5种IDE
- 支持60+的插件
- 支持SonarLint
- 支持Quality Gate
- 快速确认近期修改代码的问题

开源版本不支持一个项目多分支的形式，只能按照特性分支的名称来生成相对应的扫描项目（会产生很多Sonarqube项目）。
​

解决方案：假如这个项目有F1，F2等特性分支，在每次对其中特性分支构建扫描时会配置sonar扫描参数（projectName）为 “服务名称_特性分支名称”，这样相当于每个特性分支都对应一个扫描项目。但又间接的带来了一些问题。

- 每个特性分支生成一个项目，假如特性分支被删除呢？或者分支很多呢？
- 对于SonarQube管理员来说很难管理，增加了任务负担。



### DE-开发者版本

[![image.png](https://img2022.cnblogs.com/blog/108082/202202/108082-20220221000016115-1395708486.png)](https://img2022.cnblogs.com/blog/108082/202202/108082-20220221000016115-1395708486.png)
相较于CE版，增加了C/C++、Objective-C、T-SQL、ABAP、PL/SQL和Swift等，详细信息如下所示：

[![image.png](https://img2022.cnblogs.com/blog/108082/202202/108082-20220221000016103-1420733060.png)](https://img2022.cnblogs.com/blog/108082/202202/108082-20220221000016103-1420733060.png)
DE版具有CE版所有特性，在此基础之上，该版本还有如下特性增强：

- 支持22种编程语言
- 支持Pull Request的分支代码分析
- 安全性的增强：Security Hotspots & Security Vulnerabilities的全面支持
- 支持SonarLint的智能提示，更好地与IDE进行集成



### EE-企业版本

[![image.png](https://img2022.cnblogs.com/blog/108082/202202/108082-20220221000016285-188007307.png)](https://img2022.cnblogs.com/blog/108082/202202/108082-20220221000016285-188007307.png)
相较于DE版，增加了Apex、COBOL、PL/1、RPG和VB6等五种，详细信息如下所示：
[![image.png](https://img2022.cnblogs.com/blog/108082/202202/108082-20220221000016288-128964193.png)](https://img2022.cnblogs.com/blog/108082/202202/108082-20220221000016288-128964193.png)

EE版具有DE版所有特性，在此基础之上，该版本还有如下特性增强：

- 支持27种编程语言
- 支持对于Portfolio的管理
- 提供OWASP / SANS的安全报告
- 提供可配置的SAST 分析引擎

### DCE-数据中心版本

[![image.png](https://img2022.cnblogs.com/blog/108082/202202/108082-20220221000016288-2007768504.png)](https://img2022.cnblogs.com/blog/108082/202202/108082-20220221000016288-2007768504.png)
EE版具有EE版所有特性，此版本主要对于高可用性和横向扩展性有更好的支持。

## 如何计算费用？

Sonarqube是按照扫描的行数进行计费的，以年为单位进行订阅。关于行数如何解读？假如你买100W行扫描量，那么这个量是被所有项目共享的，但扫描的行数超过100W行，分析服务将会终止。当然如果你删除项目重置，扫描量就会恢复。
​

[![image.png](https://img2022.cnblogs.com/blog/108082/202202/108082-20220221000016289-1043081187.png)](https://img2022.cnblogs.com/blog/108082/202202/108082-20220221000016289-1043081187.png)