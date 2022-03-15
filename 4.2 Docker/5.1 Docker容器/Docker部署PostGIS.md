- [docker安装带postgis插件的postgresql 数据库 ](https://www.cnblogs.com/dengxiaoning/p/12173605.html)

> 最初直接拉取的postgresql 数据，在导入 .bakup 文件时始终会报错，最后才想到该数据库默认不带postgis空间组件

## 1 docker安装带postgis插件的postgresql 数据库

### 1.1 拉取镜像

这里我们拉取postgres 和 gis 组合的镜像

目前组合的版本有如下几个

- 11.0-2.5
- 10.0-2.4
- 9.6-2.4

这里以 拉取`postgresql v9.6` 和 `postgis v2.4` 的镜像为例

```shell
[root@dex ~]# docker pull kartoza/postgis:9.6-2.4
9.6-2.4: Pulling from kartoza/postgis
b422a2cc2545: Pull complete 
4aedc9612296: Pull complete 
5ce108fcb930: Pull complete 
ad73e560a54c: Pull complete 
7a58b5f1b933: Pull complete 
22b853e0b963: Pull complete 
8af838ddf928: Pull complete 
be73fabecb29: Pull complete 
07a8f9ac9d5a: Pull complete 
da15d9ba8084: Pull complete 
f53374d86666: Pull complete 
54ba75d37f6a: Pull complete 
53456450b0c9: Pull complete 
270089492e61: Pull complete 
Digest: sha256:da963520e7a55a4c61005d3536efb7dd068a2dce169ff76b3fb9f13ef2f8c7e8
Status: Downloaded newer image for kartoza/postgis:9.6-2.4
docker.io/kartoza/postgis:9.6-2.4
```

### 1.2 查看镜像

```shell
[root@dex ~]# docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
kartoza/postgis     9.6-2.4             b24beb0be4ff        11 months ago       903MB
```

### 1.3 运行容器

```shell
[root@dex ~]#  docker run -t --name postgresql --restart always  -e POSTGRES_USER='postgres' -e POSTGRES_PASSWORD=123456 -e ALLOW_IP_RANGE=0.0.0.0/0 -p 5432:5432 -d kartoza/postgis:9.6-2.4
```

> 配置解释：
> run，创建并运行一个容器；
> –name，指定创建的容器的名字postgresql ；
> -e POSTGRES_PASSWORD=123456，设置环境变量，指定数据库的登录口令为123456
> -e POSTGRES_USER='postgres 设置环境变量，指定数据库用户名为postgres
> -p 54321:5432，端口映射将容器的5432端口映射到外部机器的54321端口；
> -d kartoza/postgis:9.6-2.4，允许该容器以守护态（Daemonized）形式运行于后台
> -e ALLOW_IP_RANGE=0.0.0.0/0，这个表示允许所有ip访问，如果不加，则非本机 ip 访问不了
> -t 让docker分配一个伪终端（pseudo-tty）并绑定到该容器的标准输入上（这是为了在 交互模式下用户可以通过所创建的终端来输入命令）

### 1.4 查看进程

```shell
[root@dex ~]# docker ps
CONTAINER ID        IMAGE                     COMMAND                  CREATED             STATUS              PORTS                              NAMES
f82e7d3a9755        kartoza/postgis:9.6-2.4   "/bin/sh -c /docker-…"   5 seconds ago       Up 4 seconds        0.0.0.0:5432->5432/tcp             postgresql
```

到此 postgresql数据库安装成功，可以同 ip:5432进行连接了。

## 2 docker安装带postgis插件的postgresql 数据库

- [【docker】centos7 docker安装 postgresql+postgis 安装 jar部署 geoserver部署_qlanto的博客-CSDN博客](https://blog.csdn.net/qq_44382452/article/details/119905753)

### 2.1 postgresql+postgis扩展安装

1. 拉取镜像

   ```shell
   # 这里我选用的版本是11.5-2.8 (对应的是11.5的postgresql ,2.8版本的postgis)
   docker pull kartoza/postgis:11.5-2.8
   ```

2. 运行容器

   ```shell
   docker run -id --name psql -e POSTGRES_USER=这里是账号 -e POSTGRES_PASS='这里是密码' -v /home/ssystem/soft/postgresql:/var/lib/postgresql -v /home/ssystem/soft/postgresql/tmp/tmp:/tmp/tmp -p 5432:5432 -t kartoza/postgis
   ```

   > 运行参数释义:
   > –name: 容器name(建议设置,设置后对容器的相关操作会简便些)
   > -d: 后台运行容器，并返回容器ID；
   > -i: 以交互模式运行容器，通常与 -t 同时使用；
   > -e: 设置环境变量 这里设置了两个,分别是账号密码
   > -v:设置容器卷目录映射
   > -p:端口映射
   > -t 为容器重新分配一个伪输入终端，通常与 -i 同时使用；
   > 最后说明是以哪个镜像运行容器

### 2.2 postgresql sql导出导入

**导出**

```shell
pg_dump -h 127.0.0.1 -p 5432 -U 这里是账号 -d 这里是数据库名 -f 这里是导出的路径
```

如:

```shell
pg_dump -h 127.0.0.1 -p 5432 -U postgres -d lt_postgis -f E:\postgis_backup\lt_postgis.sql
```

**导入**

```shell
psql -h 192.168.3.14  -p 5432 -U 这里是账号 -d 这里是数据库名 <导入文件的路径
```

如:

```shell
psql -h 192.168.3.14  -p 5432 -U postgres -d lt_postgis <E:\postgis_backup\lt_postgis.sql
```

### 2.3 jar 部署

建议提前将java环境镜像下载好

#### 2.3.1 jar对应的dockerfile

```shell
FROM java:8
MAINTAINER qinlei<qlanto_147@163.com>
VOLUME /tmp
RUN mkdir -p /app/start \
    && touch /etc/init.d/start.sh \
    && chmod +x /etc/init.d/start.sh \
    && echo "#!/bin/bash  " >> /etc/init.d/start.sh \
    && echo "cd /app/start " >> /etc/init.d/start.sh \
    && echo "nohup java -jar /app/start/gis.jar " >> /etc/init.d/start.sh

ADD ./start/gis.jar /app/start/gis.jar
EXPOSE 8081
ENTRYPOINT /bin/sh -c   /etc/init.d/start.sh
```

#### 2.3.2 镜像构造,容器运行:

```shell
docker build -t gxgis .
docker run -id -p 8081:8081 -p 8972:8972 -v /home/dell/project/gaoxin/:/app --name=gxgis gxgis
```

### 2.4 geoserver部署

#### 2.4.1 对应的dockerfile

```shell
FROM java:8
MAINTAINER qinlei<qlanto_147@163.com>
ENV GEOSERVER_HOME /app/geoserver218
RUN mkdir -p /app/geoserver218 \
    && chmod -R +x  /app/geoserver218
ADD ./geoserver218/ /app/geoserver218/
EXPOSE 10001
ENTRYPOINT /bin/sh -c   /app/geoserver218/bin/startup.sh
```

#### 2.4.2 构造,部署

```shell
docker build -t gserver10001 .
docker run -id -p 10001:10001 -v /home/ssystem/project/geoserver10001/geoserver218:/app/geoserver/ --name=gserver10001 gserver10001
```

### 2.5 遇到的问题

#### 2.5.1 镜像搜索报错

Docker Error response from daemon read: connection refused
![Docker Error response from daemon read: connection refused](https://img-blog.csdnimg.cn/423d239234d54353b52010796ad30b25.png)

> 解决方案:
>
> 虚拟机中添加一个DNS解析解决问题

```shell
vim /etc/resolv.conf
## 添加一行：
nameserver 114.114.114.114
```