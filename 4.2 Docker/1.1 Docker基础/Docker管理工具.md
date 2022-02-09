- [Docker 管理神器](https://mp.weixin.qq.com/s/F2a35y5tZvah5LfzzbMG-A)

今天推荐 5 款酷炫到没朋友的 Docker 管理神器，每一款都值得一试！！！

你是否还在大量控制台窗口中监控容器，还是对使用终端命令充满热情？而使用Docker的图形用户界面（GUI）工具，则可以更简单的对容器进行管理，并提高效率。而且它们都是免费的。

## **Portainer**

Portainer是一款Web应用程序基于开源Zlib许可证。支持Linux，Mac OS X，Windows操作系统。Portainer完全支持以下Docker版本：

Docker 1.10到最新版本；

独立的Docker Swarm1.2.3以上版本。需要提醒大家的是，由于Docker引入了内置的Swarm模式，所以不鼓励使用独立的Docker  Swarm。旧版本的Portainer支持独立Docker Swarm，而Portainer  1.17.0和更新版本不支持它。但是完全支持Docker内置的Swarm模式。

对以下Docker版本的部分支持（某些功能可能不可用）：Docker 1.9。



![图片](https://mmbiz.qpic.cn/mmbiz_png/x0kXIOa6owV2E0BHvJuGW7Jzh5fZNE9yKm16UrCDQTb4qfKaYfp2PvqrUibDJAZxscFrgwrmygkm2LzxeGb0Dyw/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)



你可以测试一个现场演示（admin/tryportainer）。Portainer可以与Docker轻松安装在独立的Linux/Windows服务器/集群上。功能齐全的平台使你可以使用不同的端点。

可以管理注册表，网络、卷、镜像和容器。还可以保存配置（可以在实时演示中找到alertmanager和Prometheus的示例），并配置Docker Swarm和堆栈。Portainer可以检查容器是否健康。

除了需要使用容器的基本操作，例如运行，停止，恢复，终止，删除等之外，还可以检查容器，查看日志，可视化基本统计信息，附加并打开某些容器的控制台。

另外，你还可以获得基于角色的访问系统，并且可以安装扩展。

结论：Portainer是强大的GUI工具，可用于具有本地或远程容器，Docker堆栈或Docker Swarm的团队项目。但是，对于一般需求，Portainer可能并不适合。界面也可能不方便，特别是如果你同时使用多个项目。

## **DockStation**

DockStation是一款桌面应用程序；支持Linux、Mac、Windows操作系统。

![图片](https://mmbiz.qpic.cn/mmbiz_png/x0kXIOa6owV2E0BHvJuGW7Jzh5fZNE9yvyWfy9YWdiaFich5ezXibRwtV6pWPcYdCdjBGIDpVlTJ245iaUGAoqib9Tw/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

DockStation免费的全功能桌面应用程序，可满足你使用docker和docker-compose。可以通过docker-compose.yml使用本机Docker Compose  CLI命令帮助生成一个干净的本机文件，甚至在应用程序外部也可以使用。它还可以帮助管理容器和服务，包括远程和本地的容器，并对其进行监控，比如日志监控，搜索日志，分组，运行工具以及获取容器信息。还有其他工具可用于对容器资源进行通用，多个和单个的监控。

使用DockStation，可以轻松跟踪CPU，内存，网络I/O的使用情况和开放端口。所有工作都可以组织成项目，可以在其中检查每个容器的状态，构建图形化的方案，能够可视化项目中的每个镜像以及它们之间的关系。此外，DockStation在Docker Hub上十分的受欢迎。

## **Docker Desktop**

Docker Desktop是一款桌面应用程序，由于Docker-toolbox（带有Kitematic）已被弃用，建议所有用户在Mac上使用Docker Desktop，在Windows上使用Docker Desktop。

![图片](https://mmbiz.qpic.cn/mmbiz_jpg/x0kXIOa6owV2E0BHvJuGW7Jzh5fZNE9yBPVkQhUUGPwNTB8UibuY4XXo5CFuPYzkUt218d3KewBZvNJhprbib5dQ/640?wx_fmt=jpeg&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)



该工具能够为Docker设置资源限制，比如内存，CPU，磁盘镜像大小，文件共享，代理和网络等，配置Docker引擎，命令行和Kubernetes。

使用仪表板，不仅可以使用基本的容器操作，还可以查看日志，基本统计信息并检查容器。所有这些都可以通过上下文菜单或状态栏中的指示器来调用。

## **Lazydocker（UI终端）**

Lazydocker是一款开源的UI终端，支持Linux、OSX、Windows操作系统。要求GO 1.8版本以上，Docker1.13（API 1.25以上）版本，Docker-Compose1.23.2以上版本。

![图片](https://mmbiz.qpic.cn/mmbiz_jpg/x0kXIOa6owV2E0BHvJuGW7Jzh5fZNE9y6Z5CIM4VWahsRCuJWXI1143c2dQNVlRHFSd6szgIlco9ydWlMAFcOQ/640?wx_fmt=jpeg&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)



Lazydocker可以满足鼠标和键盘的接入。对于某些元素，上下文菜单可用，可以在其中找到所有带有快捷键的常用命令。而且不仅拥有基本的命令来操作容器，基本的统计信息，日志和检查，而且还具有基本功能。还可以使用图形显示主要指标，默认情况下有CPU和内存使用情况和进程。此外，还可以为几乎所有所需的指标进行配置。

对于选定的镜像，可以查看Dockerfile中运行时执行的命令以及继承的层。除了修改可用命令和添加新命令之外，还提供了对未使用的容器，镜像，卷的清理。

Lazydocker提供极简的终端界面，对一些不太复杂的项目确实很有帮助。

## **Docui**

Docui也是一款UI终端，支持Mac、Linux操作系统。要求GO 1.11.4以上版本，Docker引擎在18.06.1以上，以及Git。

![图片](https://mmbiz.qpic.cn/mmbiz_png/x0kXIOa6owV2E0BHvJuGW7Jzh5fZNE9yWWhHq9QXVe677ElISzBtXLibfKzaeoPHWemia4aIvy12RUdnNQC7sgAw/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

Docui是为了方便创建和配置新的容器/服务，可以在其中找到许多所有必要操作的键绑定。

可以使用镜像的搜索、保存导入、检查过滤等；容器的创建删除、启动停止、检查和重命名等；卷的创建和删除、检查和过滤，以及网络的删除等功能。

