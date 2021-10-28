- [Docker镜像制作实战：设置时区和系统编码](https://blog.csdn.net/boling_cavalry/article/details/80381258)

在制作Docker镜像时常用centos的官方镜像作为基础镜像，这些基础镜像的时区和系统编码都不满足我们的需求，我们需要时区CST，系统编码UTF-8，今天我们就来实战制作一个Docker镜像，将时区和系统编码设为我们想要的，今后其他镜像就能以此作为基础镜像，不用再关注时区和系统编码问题了 ；

原文地址：https://blog.csdn.net/boling_cavalry/article/details/80381258

### 先看现状

先来看一下centos官方镜像的情况： 

1. 在装好了docker的机器上执行docker run —name centos001 -idt centos:7，即可启动一个centos官方镜像的容器； 
2. 执行命令docker exec -it centos7001 /bin/bash，进入容器内； 
3. 执行命令date，可见当前容器时区为UTC，如下：

```shell
root@maven:~# docker run --name centos001 -idt centos:7
b51aba6a372ea21ec25ccf53f09b8837508414a11a1da0488a350d775dd9e85b
root@maven:~# docker exec -it centos001 /bin/bash 
[root@b51aba6a372e /]# date
Sun May 20 04:17:23 UTC 2018
```

4. 执行命令locale，可见当前系统编码，如下：

```shell
[root@b51aba6a372e /]# locale
LANG=
LC_CTYPE="POSIX"
LC_NUMERIC="POSIX"
LC_TIME="POSIX"
LC_COLLATE="POSIX"
LC_MONETARY="POSIX"
LC_MESSAGES="POSIX"
LC_PAPER="POSIX"
LC_NAME="POSIX"
LC_ADDRESS="POSIX"
LC_TELEPHONE="POSIX"
LC_MEASUREMENT="POSIX"
LC_IDENTIFICATION="POSIX"
LC_ALL=
```

以上就是现状，接下来我们看如何制作镜像，使得时区和系统编码都被设置好；

### 定制镜像

时区和系统编码设置都在制作镜像的时候完成，所以我们要把镜像做出来： 

1. 创建Dockerfile文件，内容如下：

```shell
# Docker file for date and locale set 
# VERSION 0.0.3
# Author: bolingcavalry

#基础镜像
FROM centos:7

#作者
MAINTAINER BolingCavalry <zq2599@gmail.com>

#定义时区参数
ENV TZ=Asia/Shanghai

#设置时区
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo '$TZ' > /etc/timezone

#安装必要应用
RUN yum -y install kde-l10n-Chinese glibc-common

#设置编码
RUN localedef -c -f UTF-8 -i zh_CN zh_CN.utf8

#设置环境变量
ENV LC_ALL zh_CN.utf8
```

2. 在Dockerfile文件所在目录执行命令docker build -t bolingcavalry/centos7-cst-utf8:0.0.1 .，即可完成镜像制作，如下：

```shell
root@maven:/usr/local/work/cstutf8image# docker build -t bolingcavalry/centos7-cst-utf8:0.0.1 .
Sending build context to Docker daemon 2.048 kB
Step 1/7 : FROM centos:7
 ---> 2d194b392dd1
Step 2/7 : MAINTAINER BolingCavalry <zq2599@gmail.com>
 ---> Using cache
 ---> a7549a776033
Step 3/7 : ENV TZ Asia/Shanghai
 ---> Using cache
 ---> 7b861b5c357c
Step 4/7 : RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo '$TZ' > /etc/timezone
 ---> Using cache
 ---> 08ca24b44c93
Step 5/7 : RUN yum -y install kde-l10n-Chinese glibc-common
 ---> Using cache
 ---> 4b6f471ae930
Step 6/7 : RUN localedef -c -f UTF-8 -i zh_CN zh_CN.utf8
 ---> Using cache
 ---> 1cc68728acb0
Step 7/7 : ENV LC_ALL zh_CN.utf8
 ---> Using cache
 ---> 9e5b583d7359
Successfully built 9e5b583d7359
```

### 体验新的镜像

1. 执行命令docker run –name centos002 -idt bolingcavalry/centos7-cst-utf8:0.0.1，基于刚刚构建的镜像来创建一个容器；
2. 执行命令docker exec centos002 date，让容器显示当前时间信息，如下所示，已经是CST时区，并且中文可以正常显示：

```shell
root@maven:/usr/local/work/cstutf8image# docker exec centos002 date
2018年 05月 20日 星期日 16:33:14 CST
```

3. 执行命令docker exec centos002 locale，让容器显示当前系统编码，如下所示：

```shell
root@maven:/usr/local/work/cstutf8image# docker exec centos002 locale
LANG=
LC_CTYPE="zh_CN.utf8"
LC_NUMERIC="zh_CN.utf8"
LC_TIME="zh_CN.utf8"
LC_COLLATE="zh_CN.utf8"
LC_MONETARY="zh_CN.utf8"
LC_MESSAGES="zh_CN.utf8"
LC_PAPER="zh_CN.utf8"
LC_NAME="zh_CN.utf8"
LC_ADDRESS="zh_CN.utf8"
LC_TELEPHONE="zh_CN.utf8"
LC_MEASUREMENT="zh_CN.utf8"
LC_IDENTIFICATION="zh_CN.utf8"
LC_ALL=zh_CN.utf8
```

至此，新镜像的制作和验证已完成，希望这些细微的改动能为您在定制镜像时提供一些参考，把这类改动提前做到基础镜像中，而不必留到业务镜像或者容器启动后去处理；

