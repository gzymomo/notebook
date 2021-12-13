- [开源 Kubernetes 安全工具](https://mp.weixin.qq.com/s/vOI3Lcfn_Wm30r0rk7iiHQ)

首先，Kubernetes 是开发和 DevOps 团队加速和扩展容器化应用程序开发、部署和管理的工具。Red Hat、Amazon、Microsoft 和 Google 等提供商已添加安全功能以增强 Kubernetes 中的基本功能。与此同时，商业安全供应商已经加紧为更高级的用例提供企业级安全解决方案。

与此同时，Kubernetes 社区一直非常积极地发布开源安全工具来填补Kubernetes 中存在的安全漏洞。客户有丰富的开源安全工具可供选择，我们的调查结果表明，没有单一的开源安全工具主导 Kubernetes 安全市场。

下面，您将找到我们的调查受访者确定的`前八名`最受欢迎的开源 Kubernetes 安全工具。

![image-20211213133521637](https://gitee.com/er-huomeng/img/raw/master/image-20211213133521637.png)

## 1 Open Policy Agent (OPA)

32%的受访者使用**open-policy-agent**[2](OPA)保护 Kubernetes 。虽然 OPA 是一种通用策略引擎，但它是用于实施上下文感知安全策略的非常强大的工具。随着从 Kubernetes v.1.21 开始**弃用**[3]Pod 安全策略（并在 v.1.25 完全删除），许多组织可能会转向 OPA 来填补这一空白。

## 2 KubeLinter

并列第一的是**KubeLinter**[4] ，是一个静态分析工具，可以扫描 YAML 文件和 Helm 图表。KubeLinter 分析 Kubernetes YAML 文件和 Helm 图表，并根据各种最佳实践对其进行检查，重点是生产就绪性和安全性。

KubeLinter 附带默认检查，旨在为您提供有关 Kubernetes YAML 文件和 Helm 图表的有用信息。这有助于团队尽早并经常检查安全配置错误和  DevOps 最佳实践。其中一些常见示例包括以非 root 用户身份运行容器、强制执行最低权限以及仅将敏感信息存储在机密中。

## 3 Kube-bench

近四分之一的受访者使用Kube-bench，这是一种根据 CIS 基准测试中推荐的 Kubernetes 安全检查来审核 Kubernetes 设置的工具。扫描是使用 YAML  文件配置的，工具本身是用 Go 编写的，Go 是 Kubernetes 开发人员熟悉的语言。

在自我管理控制平面组件时，此工具特别有用。

## 4 Kube-hunter

由 Kube-bench 背后的同一团队构建，**Kube-hunter**[5] 寻找 Kubernetes 集群中可利用的安全弱点。Kube-hunter 更有用的功能之一是能够利用它发现的漏洞来寻找进一步的漏洞。23% 的受访者使用 Kube-hunter。

## 5 Terrascan

Terracan建立在 OPA 之上，是一种用于基础设施即代码的开源静态代码分析器，22% 的受访者使用它。Terrascan 拥有超过 500  多种跨各种应用程序的安全最佳实践策略，包括 Terraform、Kubernetes  (JSON/YAML)、AWS、Azure、GCP、Kubernetes 和 GitHub，Terrascan  可以在配置基础设施之前检测安全漏洞和合规违规并降低风险。

## 6 Falco

作为此列表中唯一为运行时安全性而构建的开源工具， 21% 的受访者使用**Falco**[6]来保护在 Kubernetes 中运行的容器化应用程序。Falco 还提供安全策略，这些策略使用来自 Kubernetes 和内核事件的上下文数据来检测表示威胁的异常应用程序行为。

## 7 Clair

**Clair**[7]是一种开源安全工具，用于扫描容器镜像中的已知漏洞。Clair 是一个静态分析工具，因此它无法在运行时检测漏洞。11% 的受访者使用 Clair。

## 8 Checkov

与 Terrascan 类似，**Checkov**[8]是基础设施即代码的静态代码分析器，9% 的受访者使用该代码。Chekov 的最新版本引入了基于上下文的分析。它使用基于图形的云基础架构扫描来检测错误配置，这些云基础架构配备了  Terraform、Terraform plan、Cloudformation、Kubernetes、Dockerfile、Serverless 或 ARM 模板等应用程序。

应该指出的是，虽然大多数受访者至少使用了一种用于 Kubernetes 的开源安全工具，但近十分之一的受访者选择不使用任何开源安全工具。

## 参考资料

[1]2021 年 Kubernetes 采用、安全和市场趋势报告: *https://www.redhat.com/en/resources/kubernetes-adoption-security-market-trends-2021-overview*

[2]OPA: *https://github.com/open-policy-agent/opa*

[3]PSP(Pod-security-policy): *https://kubernetes.io/docs/concepts/policy/pod-security-policy/*

[4]KubeLinter: *https://github.com/stackrox/kube-linter*

[5]Kube-hunter: *https://github.com/aquasecurity/kube-hunter*

[6]falco: *https://github.com/falcosecurity/falco*

[7]Clair: *https://github.com/quay/clair*

[8]Checkov: *https://github.com/bridgecrewio/checkov*