- [在 KubeSphere 上使用 EdgeMesh 打通云边隧道](https://mp.weixin.qq.com/s/37Mgm9K-vAGjjhJTHFpEbA)

作者 | KubeSphere 朱晗；中科南京信息高铁研究院 赵勇、李丹阳；KubeEdge EdgeMesh Maintainer 王杰章

## 1 EdgeMesh 简介

EdgeMesh 作为 KubeEdge 集群的数据面组件，为应用程序提供了简单的服务发现与流量代理功能，从而屏蔽了边缘场景下复杂的网络结构。KubeEdge  基于 Kubernetes  构建，将云原生容器化应用程序编排能力延伸到了边缘。但是，在边缘计算场景下，网络拓扑较为复杂，不同区域中的边缘节点往往网络不互通，并且应用之间流量的互通是业务的首要需求，而 EdgeMesh 正是对此提供了一套解决方案。

![image-20220120224250606](https://gitee.com/er-huomeng/img/raw/master/img/image-20220120224250606.png)

## 2 KubeEdge 简介

KubeEdge 为云和边缘之间的网络，应用部署和元数据同步提供基础架构支持，100% 兼容 Kubernetes  原生能力，支持海量边缘设备管理，支持复杂的边云网络环境，支持边缘应用/数据边缘自治，支持边云一体资源调度和流量协同。KubeSphere  v3.1.0 已集成 KubeEdge，支持在 KubeSphere 集群中纳管边缘节点。

![image-20220120224302776](https://gitee.com/er-huomeng/img/raw/master/img/image-20220120224302776.png)

## 3 KubeSphere 简介

KubeSphere 是在 Kubernetes 之上构建的以应用为中心的多租户容器平台，完全开源，支持多云与多集群管理，提供全栈的 IT 自动化运维的能力，简化企业的 DevOps 工作流。

![image-20220120224314689](https://gitee.com/er-huomeng/img/raw/master/img/image-20220120224314689.png)

KubeSphere 3.2.0 新增了 “动态加载应用商店” 的功能，合作伙伴可将应用的 Helm Chart 集成到 KubeSphere  应用商店，即可动态加载应用，不再受到 KubeSphere 版本的限制。EdgeMesh 已经通过这种方式将 Helm Chart 集成到了  KubeSphere 3.2.1，方便用户一键部署应用至 Kubernetes。本教程演示了如何在 KubeSphere 上部署  EdgeMesh 打通云边应用之间的通信。

## 4 准备工作

- 部署 KubeSphere 应用商店
- 启用 KubeEdge，并添加边缘节点
- 修改 KubeEdge 部分配置
- 您需要为本教程创建一个企业空间、一个项目，若还未创建好，请参考创建企业空间、项目、用户和角色

## 5 开始实验

### 5.1 步骤 1：部署 EdgeMesh

在应用市场中搜索 edgemesh，点击搜索结果进入应用。

![image-20220120224325529](https://gitee.com/er-huomeng/img/raw/master/img/image-20220120224325529.png)

进入应用信息页后，点击右上角 “安装” 按钮。

![image-20220120224335227](https://gitee.com/er-huomeng/img/raw/master/img/image-20220120224335227.png)

进入应用设置页面，可以设置应用名称（默认会随机提供一个唯一的名称）和选择安装的位置（对应的 Namespace) 和版本，然后点击右上角 “下一步”。

![image-20220120224347133](https://gitee.com/er-huomeng/img/raw/master/img/image-20220120224347133.png)

根据 EdgeMesh 文档的指导编辑 values.yaml 文件，主要是修改 `server.nodeName` 和 `server.advertiseAddress` 的值，然后点击 “安装” 使用配置。

![image-20220120224355357](https://gitee.com/er-huomeng/img/raw/master/img/image-20220120224355357.png)

等待 EdgeMesh 开始正常运行。

![image-20220120224402893](https://gitee.com/er-huomeng/img/raw/master/img/image-20220120224402893.png)

访问 “应用负载”， 可以看到 EdgeMesh 创建了两个部署。

![image-20220120224409650](https://gitee.com/er-huomeng/img/raw/master/img/image-20220120224409650.png)

### 5.2 步骤 2：创建云边互通实验

创建云边应用：

```bash
$ kubectl apply -f
https://raw.githubusercontent.com/kubeedge/edgemesh/main/examples/edgezone.yaml

$ kubectl apply -f
https://raw.githubusercontent.com/kubeedge/edgemesh/main/examples/cloudzone.yaml
```

通过 KubeSphere 界面进入云上 busybox 容器终端：

![image-20220120224418872](https://gitee.com/er-huomeng/img/raw/master/img/image-20220120224418872.png)

从云上往边缘发起聊天，边缘应用收到消息后会往云上回显相同的消息：

![image-20220120224425686](https://gitee.com/er-huomeng/img/raw/master/img/image-20220120224425686.png)

通过 KubeSphere 界面进入边上 busybox 容器终端（需要开启 KubeEdge 的 Debug 功能），也可以使用 SSH 登录边缘节点再使用 docker exec 命令进入边上 busybox 容器终端。

![image-20220120224432296](https://gitee.com/er-huomeng/img/raw/master/img/image-20220120224432296.png)

从边缘往云上发起聊天，云上应用收到消息后会往边缘回显相同的消息。

![image-20220120224439493](https://gitee.com/er-huomeng/img/raw/master/img/image-20220120224439493.png)

## 6 总结

KubeSphere 容器平台对云原生应用部署非常友好，在集成 KubeEdge 后实现了将容器化应用程序编排功能扩展到边缘主机的能力。此外 KubeSphere  提供的应用商城实现了真正的一键部署，用户可以非常方便在 KubeSphere 上一键部署 EdgeMesh，帮助用户快速打通云边隧道。

## 参考链接

[1] EdgeMesh GitHub: https://github.com/kubeedge/edgemesh

[2] KubeSphere GitHub: https://github.com/kubesphere/kubesphere

[3] KubeSphere 应用商店: https://kubesphere.io/zh/docs/pluggable-components/app-store/

[4] 在 KubeSphere 中创建企业空间、项目、用户和角色: https://kubesphere.io/zh/docs/quick-start/create-workspace-and-project/

[5] EdgeMesh 使用文档: https://edgemesh.netlify.app