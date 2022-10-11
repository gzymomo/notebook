- [DataX 全系列之一 —— DataX 安装和使用 - 掘金 (juejin.cn)](https://juejin.cn/post/7006617025816559653)

# 1 前言

  Datax3.0 是异构数据源离线同步工具，支持多种类数据源，能够支撑较为复杂的业务场景。本文主要描述其的安装和多种使用方式。

# 2 工具的安装和部署

## 2.1 安装 jdk 1.8

   请参考相关 JDK 1.8 的安装配置教程，此处略。

## 2.2 安装 python 2.x

   请参考相关 Python 2.x 安装配置教程，此处略。

## 2.3 安装 maven 3.x

   请参考相关 Maven 3.x 安装配置教程，此处略。

## 2.4 安装 DataX

   DataX 安装共有两种方式，请根据个人喜好进行安装。

### 2.4.1 直接下载 DataX 工具包:

   下载链接如下:

> [dataxopensource.oss-cn-hangzhou.aliyuncs.com/datax.tar.g…](https://link.juejin.cn?target=http%3A%2F%2Fdataxopensource.oss-cn-hangzhou.aliyuncs.com%2Fdatax.tar.gz)   下图是解压后的 DataX 源码结构图：

![image.png](https://p1-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/c375d01636d14ea5a367bff0610f1b83~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

### 2.4.2 编译安装

  Datax 工具包会出现一些版本不兼容问题，必要时需要修改源码，可通过源码编译方式进行部署，源码地址如下: [github.com/alibaba/Dat…](https://link.juejin.cn?target=https%3A%2F%2Fgithub.com%2Falibaba%2FDataX%EF%BC%8C) 下载后，利用 maven 命令进行打包，包位于 datax-core 的 target 目录下，目录结构与上述相同，唯一不同是没有 plugin 文件夹，需要自己创建，再把对应插件拖进去。

![image.png](https://p1-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/efaa546e56e44521badd603f0f7c16e1~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

# 3 DataX 使用（python命令启动）

   DataX 使用需要如下步骤：

## 3.1 确定数据同步的场景和同步数据

  此处略

## 3.2 编写同步任务 job 配置文件

   下面是样例文件模板:

![图片 1.png](https://p6-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/48562fe4252543f796e63b3864366456~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

## 3.3 同步表

  上图展示将一个简单的 datax-reader1 数据库下的 table1 和 table3 表中的数据同步到 datax-writer 数据库 table2 表里，其中 channel 是并发数量。

## 3.4 进入 DataX 内的 bin 目录

   编写完 json 配置文件，进入到 Datax 的 bin 目录。

![image.png](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/8522b07765fa4a9f962b8640c68e7904~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

## 3.5 执行 datax.py

```shell
# python datax.py /Users/zcy/Desktop/mysql2mysql的副本.json
复制代码
```

![image.png](https://p9-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/2b2c2a0b094640d6a0f3a1b6f75e5eb3~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

## 3.6 查看运行结果

![image.png](https://p9-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/284e5c25dc944501ba7ad71e20f653eb~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

   cpu 监控以及任务执行成功后的结果如下图所示：

![image.png](https://p1-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/f372a20711cb491eb73e5edd37c12cfd~tplv-k3u1fbpfcp-watermark.image)

# 4 DataX 源码本地运行和调试

## 4.1 获取 DataX 源码

  首先从 git 上拉取 datax3.0 的源码，找到 Engine 类下的 main 方法， 也就是程序的入口。

![image.png](https://p9-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/71d580fb52e14f7da836b6ce7b82a556~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

## 4.2 修改命令行参数

  由于前面由 python 脚本提供了参数，这里我们直接运行源码需要手动加入参数，加入全局参数：datax.home(datax 本地的安装路径)，now 为当前时间；指定输入参数:job(json 配置文件的路径)，jobId(默认为 -1)，mode(任务模式，如:standalone 模式)。具体改造如下：

```java
public static void main(String[] args) throws Exception {
    int exitCode = 0;
    //datax的路径
    System.setProperty("datax.home", "/Users/zcy/datax");
    //当前时间
    System.setProperty("now", new SimpleDateFormat("yyyy/MM/dd-HH:mm:ss:SSS").format(new Date()));// 替换job中的占位符
    //String[] datxArgs = {"-job", dataxPath + "/job/text.json", "-mode", "standalone", "-jobid", "-1"};
    //json配置文件的路径，jobId和mode的配置
    String[] datxArgs = {"-job", "/Users/zcy/Desktop/学习目标/job/mysql2mysql的副本.json", "-mode", "standalone", "-jobid", "-1"};
    args = datxArgs;
    try {
        Engine.entry(args);
    } catch (Throwable e) {
        exitCode = 1;
        LOG.error("\n\n经DataX智能分析,该任务最可能的错误原因是:\n" + ExceptionTracker.trace(e));

        if (e instanceof DataXException) {
            DataXException tempException = (DataXException) e;
            ErrorCode errorCode = tempException.getErrorCode();
            if (errorCode instanceof FrameworkErrorCode) {
                FrameworkErrorCode tempErrorCode = (FrameworkErrorCode) errorCode;
                exitCode = tempErrorCode.toExitValue();
            }
        }

        System.exit(exitCode);
    }
    System.exit(exitCode);
}
复制代码
```

## 4.3 启动 DataX

   启动 main 方法，json 配置文件写法与上方相同。

## 4.4 查看结果

  观察控制台打印出来的信息，与上方基本相同。

![image.png](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/a49c7340970f451694b96ad399ef0002~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

# 5 java代码启动DataX

1. 目前 datax 暂时不支持分布式(后续可通过编写调度系统解决该问题，目前其他程序需要调用 datax 运行，需要引入 datax 的 jar 包，使用 maven 命令 clean+install，将 datax 编译打包。
2. maven工程项目引入 datax-core 的 jar 包后，就可以实现 datax 的调用。
3. 调用 Engine 类下的 Entry 方法，和上述相同的方式引入参数，即可启动 datax。案例如下：

```java
//引入datax的核心包
import com.alibaba.datax.core.Engine;


import java.text.SimpleDateFormat;
import java.util.Date;


public class aaa {
    public static void main(String[] args) throws Throwable{
        System.setProperty("datax.home", "/Users/zcy/datax");
        System.setProperty("now", new SimpleDateFormat("yyyy/MM/dd-HH:mm:ss:SSS").format(new Date()));// 替换job中的占位符
        //String[] datxArgs = {"-job", dataxPath + "/job/text.json", "-mode", "standalone", "-jobid", "-1"};
        String[] datxArgs = {"-job", "/Users/zcy/Desktop/stream2stream.json", "-mode", "standalone", "-jobid", "-1"};
        Engine.entry(datxArgs);
    }
}

复制代码
```

# 6 注意事项

- Datax3.0 不支持 mysql 8.0 以上的版本。主要原因是 Datax3.0 内部配置的 mysql 驱动 jar 包为 5 版本的，并且 8 之后改了驱动名称
- 如果一定要使用mysql 8以上的版本，暂时解决方案:将内部 mysqlreader 和 mysqlwriter 插件下的 jar 包进行更新，将网上新下载的 mysql jar 包放入。如图:

![image.png](https://p6-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/35479d3c765745ebb7a473026dbbd5a0~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

在DataX的plugin目录下mysql，丢到libs文件夹下

- 这样本地启动暂时没有报错，后续情况未确定。完全解决方案是修改源码，首先更改pom文件中的jar包版本，然后将与 mysql 有关配置改掉，改成 mysql8.0.26 配置，然后重新打包。如图:

![image.png](https://p6-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/00f0293528164a65aa1c080e9f38bb03~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

更改驱动名称

![image.png](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/ee69ef6001874cca8baaa608d82c391a~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

更改zeroDataTimeBehavior的属性

可全局搜索mysql找到mysql的一些属性，并进行更改，使其能够符合mysql 8以上的版本，彻底解决问题。