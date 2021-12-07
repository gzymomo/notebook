- [在 Kubernetes 中部署云原生开发工具 Nocalhost](https://kubesphere.io/zh/blogs/kubesphere-nocalhost/)

## Nocalhost 简介

[Nocalhost](https://nocalhost.dev/) 是一个允许开发者直接在 Kubernetes 集群内开发应用的工具。

Nocalhost 的核心功能是：提供 Nocalhost IDE 插件（包括 VSCode 和 Jetbrains  插件），将远端的工作负载更改为开发模式。在开发模式下，容器的镜像将被替换为包含开发工具（例如 JDK、Go、Python  环境等）的开发镜像。当开发者在本地编写代码时，任何修改都会实时被同步到远端开发容器中，应用程序会立即更新（取决于应用的热加载机制或重新运行应用），开发容器将继承原始工作负载所有的声明式配置（configmap、secret、volume、env 等）。

Nocalhost 还提供：

- VSCode 和 Jetbrains IDE 一键 Debug 和 HotReload
- 在 IDE 内直接提供开发容器的终端，获得和本地开发一致的体验
- 提供基于 Namespace 隔离的开发空间和 Mesh 开发空间

在使用 Nocalhost 开发 Kubernetes 的应用过程中，免去了镜像构建，更新镜像版本，等待集群调度 Pod 的过程，把编码/测试/调试反馈循环(code/test/debug cycle)从分钟级别降低到了秒级别，大幅提升开发效率

此外，Nocalhost 还提供了 Server 端帮助企业管理 Kubernetes 应用、开发者和开发空间，方便企业统一管理各类开发和测试环境。

![img](https://pek3b.qingstor.com/kubesphere-community/images/nocalhost-server.png)