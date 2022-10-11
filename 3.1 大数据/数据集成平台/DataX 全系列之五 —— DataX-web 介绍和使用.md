- [DataX 全系列之五 —— DataX-web 介绍和使用 - 掘金 (juejin.cn)](https://juejin.cn/post/7006658574529069086)

Datax 的使用过程中，我们会发现，不管是利用 java 调用以及 python 命令启动的方式，我们都无法进行任务的管理，并且每次执行任务前，我们 都需要编辑 Json 配置文件，这是比较繁琐的，随着业务的增加，配置文件 不方便管理和迁移并且每次执行都需要记录命令。 同时目前 DataX 只支持 单机版，无法调用远程的 datax，并且多节点之间的协作不能控制。

因此,开发一款支持远程分布式调用 Datax 的可视化管理工具非常有必要，Datax-Web 就是这样的一款工具。

# 1.工具的安装部署

## 1.1. 检查 jdk1.8，python2.x 环境，Maven3.x。

  环境配置此处暂时省略

## 1.2. Datax的安装

  运行 datax-web 的机子上，需要安装有 Datax 工具，具体下载方式 前 面 有 介 绍 ， 安 装 路 径 如 下 :

```txt
http://datax-opensource.oss-cn-hangzhou.aliyuncs.com/datax.tar.gz
```

  下载完开箱即用。目录:

![image.png](https://p9-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/c69ccbb896794c32beff387884c0d468~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.awebp)

## 1.3 DataX-web源码拉取调试

  本地调试使用可以选择两种方式，直接下载 Datax-web 官方提供的 tar 包，需要去网盘进行提取。这里推荐第二种从 git 上 clone 源码，在本地进行编译运行，git 地址:

> [github.com/WeiYe-Jing/…](https://link.juejin.cn?target=https%3A%2F%2Fgithub.com%2FWeiYe-Jing%2Fdatax-web)

项目模块结构:

![image.png](https://p9-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/01e7ebffb52449098c4775b45319efc1~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.awebp)

------

# 2. DataX-web的具体使用流程

1. Datax-Web 会拥有一个独立的数据库，用于用户信息，执行器，以 及任务，项目，日志的统一管理。因此第一步先要部署数据库，需要将 Datax-Web 源码文件中的 sql 文件导入数据库中。

![image.png](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/8be0377d75a047c8975d15728b9605f4~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.awebp)

1. 按照本机的配置需要，更改配置，首先进入 datax-admin 模块下的 bootstrap.properties 和 application.yml 配置文件，配置数据库信息。

![image.png](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/99b402998d9a4d1783a989db5d46084b~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.awebp)

![image.png](https://p6-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/e94ba8e2dbb94242814af2126649e823~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.awebp)

1. 继续在 Datax-web 的 application.yml 配置环境下配置，注意需要 去掉一些不必要的配置(某些变量没有配置，只是为了解释，会导致启动时 报错)，例如 mail 等配置，可以设置为 null。

![image.png](https://p9-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/2cf6685fe7314932a8e6e3e360cf4b57~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.awebp)

1. 最后进入到 datax-executor 目录下的 application，修改 datax 的 本地配置，指定 datax 的 py 启动脚本和配置文件在本地的存放路径。

![image.png](https://p9-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/f6500845a5ec43079d76f0e9d6c4d223~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.awebp)

1. 配置完之后，先启动 datax-admin 服务，再启动 datax-executor服务

![image.png](https://p1-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/0d78ca8d67354d2291ac10daca128b89~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.awebp) 

6. 启动成功后，用上方的 web—URL 登陆网页。 账号:admin，密码:123456

![image.png](https://p1-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/da9a0022dd7547198821836171cd9b51~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.awebp) 

7. 登录成功后首先先编辑需要同步的两边的数据源

![image.png](https://p9-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/98d9e452cfa84916ba336aaf5c34b2ee~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.awebp)

![image.png](https://p6-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/a44c84d0b00c4e199c8a26cc87d920eb~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.awebp) 8. 接着开始构建一次数据同步任务

构建 Reader

![image.png](https://p9-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/983cacafa302428b9d8e83a4b66388b7~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.awebp)

构建 Writer

![image.png](https://p1-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/0dcf10191d7543d4931e5b282c53a85b~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.awebp)

字段映射生成 json 配置文件

![image.png](https://p6-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/af2889bed14244f3ba17d1e5b00b1ed7~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.awebp)

1. 这样一个服务就构建完成啦，我们可以在任务管理处启动本次数据同步任务!

![image.png](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/d14f9110c0924d31a43148287ac0939d~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.awebp)

1. 查看日志和运行结果!

![image.png](https://p1-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/10a481e086844666be00f40ac2ed1624~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.awebp)

![image.png](https://p6-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/efdac52797fa49689ea3f7e731f11d89~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.awebp)

