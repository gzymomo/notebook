- [KubeSphere+KubeEdge：轻松实现海量边缘节点与边缘设备管理](https://mp.weixin.qq.com/s/P8l5hBYsqdNXRKxCjQa03Q)

在去年11 月  举办的云原生边缘计算论坛中，KubeSphere后端研发工程师朱晗发表了主题为《KubeSphere+KubeEdge：轻松实现海量边缘节点与边缘设备管理》的演讲，深入介绍如何解决KubeEdge在KubeSphere容器平台的容器化部署集成和可观测性难题。

## KubeEdge 赋能 KubeSphere 边缘节点管理

KubeSphere是在 Kubernetes 之上构建的企业级分布式多租户的容器平台，在与KubeEdge集成中，扮演者着“云端控制面”的角色。

下图中展示了边缘节点集成后，作为node角色在kubeSphere console上的展示效果，我们可以很方便的查看边缘节点容器日志和metrics。

![image-20220121225215870](https://gitee.com/er-huomeng/img/raw/master/img/image-20220121225215870.png)



## 为什么选择KubeEdge集成边缘计算能力？

首先KubeEdge本身的云边枢纽和架构，具有非常出色的云原生自治能力，支持边缘自治、消息与资源的可靠性同步、边缘节点的管理能力，边缘节点的kubefed是极度轻量的，可按需裁剪定制。

![image-20220121225225638](https://gitee.com/er-huomeng/img/raw/master/img/image-20220121225225638.png)

除了Kubeedge本身架构带来的特性外，我们集成Kubeedge的其他原因主要有：

- KubeEdge 最早进入 CNCF 的边缘计算项目，项目成熟度比较高且社区比较活跃活跃
- KubeSphere v2.1.0/v3.0.0 起，社区用户陆续提出了边缘节点自动化安装部署、监控、日志、调试等方面的需求；
- KubeEdge 逐渐对边缘节点监控、日志、调试等有了更好的支持
- 补充 KubeEdge 边缘计算框架云端控制面

在这样的背景下，KubeSphere 社区 和 KubeEdge  社区紧密合作，从云端控制层面解决边缘节点纳管易用性和可观测性难题。KubeEdge集成在KubeSphere容器平台后，可以补充KubeSphere的边缘计算能力，KubeSphere则充当计算框架的一个云端控制面。

## 在集成过程中，我们也遇到了一些挑战：

- 提供快速容器化部署方案；
- 实现边缘容器监控、日志依赖手动添加iptables规则，运维成本较高：

```
 iptables -t nat -A OUTPUT -p tcp --dport 10350 -j DNAT --to cloudcore ip:10003
```

- 提供边缘节点辅助验证服务；
-  边缘测部署配置项较多，希望一条脚本解决边缘节点加入云端组件;

以上描述低版本的版本的场景，高版本的场景有所变化

## 集成方案

- 方案：云端组件容器化部署、边缘节点binary部署
- 集成 helm 安装云端组件，包括 cloudcore 和 edge-watcher controller 组件
- edge-watcher controller 组件: 边缘节点验证、join脚本生成服务以及 iptables-manager 自动运维能力
- 给边缘节点部署keadm工具添加额外自定义参数、添加国内下载源

目前KubeSphere支持的KubeEdge版本有 v1.5.1/1.6.1/1.6.2/1.7.2

支持的linux系统ubuntu/centos等, cpu架构类型：amd64（x86_64）/arm64；

## KubeSphere容器平台如何激活云端组件

- 确保在 k8s 集群上安装了 kubesphere 云控制面板和 ks-installer 安装工具，也可以使用kubekey来直接创建 k8s 集群和 kubesphere 套件
- 确保激活了metrics-server组件；3 按照文档进行安装集成；
- 另外还需要开放一些端口

![image-20220121225301067](https://gitee.com/er-huomeng/img/raw/master/img/image-20220121225301067.png)

添加边缘节点主要有两种集成方式：

- 如果边缘节点与k8s集群不在一个局域网，云端相应端口 10000 ~ 10004 允许防火墙通过，映射到nodeport 30000~30004;
- 如果边缘节点与k8s集群局域网内可达边缘节点，则直接使用 30000~30004 nodeport方式集成；

此外，需要激活edgemesh云边网络工具；

![image-20220121225310054](https://gitee.com/er-huomeng/img/raw/master/img/image-20220121225310054.png)

**KubeEdge单cloudcore下可观测链路转发：**

apiserver/metrics-server 通过edge vip: 10351 进而转发给 Stream server | tunnel server ，最后会下发到边缘获取日志或者metrics数据；

![image-20220121225317077](https://gitee.com/er-huomeng/img/raw/master/img/image-20220121225317077.png)



**集成工作与可观测性- edge-watcher controller**

![ap](https://gitee.com/er-huomeng/img/raw/master/img/ap.png)



controller定义了两个CRD：

- iptables作为controller的申明式CRD，定义了控制器用于调谐的目标iptables daemonset agent的一些属性，如镜像，节点亲和性等；
- iptablesrules作为用户期望的iptables规则，会被iptable daemonset watch，用于保证期望iptables规则生成，实现自动化运维；

注意：kubeedge > 1.8 之后已经支持相同功能，后续集成会考虑弃用该组件，因为kubeedge 实现的iptables manager组件更加轻量；

**集成工作与可观测性 - 边缘容器日志获取**

![图片](https://mmbiz.qpic.cn/mmbiz_png/ia1Z7HH4plnCZREnRFn1e0XmmCzRM2etkoLPibuUE5DTmbjAp1JdloyJF339SUAAYeDl6VE76dZibVGaqYnFBB7eA/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

在UI上的界面，在我们KubeSphere里面的界面大概如上图，这是边缘容器的一个日志，我们可以开启实施debug功能。

## 应用案例：中移物联网边缘计算平台

![image-20220121225408241](https://gitee.com/er-huomeng/img/raw/master/img/image-20220121225408241.png)

此案例来自中移物联网何毓川老师，分享了使用KubeSphere + KubeEdge 来构建中移物联网边缘计算平台，中移物联网计划基于以上的集成和可观测方案，预期在每一个kubesphere容器平台上，边缘节点接入量期望在1k左右。

视频播放地址：https://kubesphere.com.cn/live/edgebox-cic/

## 可观测性展望

1）目前的可观测数据主要通过metrics-server来获取，是实时数据，无法长期保存；

2）为解决边缘场景长期存储的问题提供最佳实践，例如，grafana/agent + cortex 或者 opentelemetry-collector + thanos 等套件, 利用 remote write 和  object storage 进行长期存储；

3）一起建设更好的KubeEdge社区：

- Edge Runtime Service，用于辅助边缘场景中健康检查、节点合法性验证、收集重要events甚至生命周期监测等的 sidecar ；
- KubeEdge 开发者接口, 类似client-go，不限于go语言；



**网站:** https://kubeedge.io

**Github地址**: https://github.com/kubeedge/kubeedge

**Slack地址**: https://kubeedge.slack.com

**邮件列表**: https://groups.google.com/forum/#!forum/kubeedge

**每周社区例会**: https://zoom.us/j/4167237304

**Twitter**: https://twitter.com/KubeEdge

**文档地址**: https://docs.kubeedge.io/en/latest/