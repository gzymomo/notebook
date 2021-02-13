- [Kubernetes-5-2：Harbor仓库的几种高可用方案与搭建](https://www.cnblogs.com/v-fan/p/14385057.html)



Harbor官方有推出主从架构和双主架构来实现Harbor的高可用及数据备份。

 

**一、主从架构：**

 说白了，就是往一台Harbor仓库中push镜像，然后再通过这台Harbor分散下发至所有的从Harbor，类似下图：

![img](https://img2020.cnblogs.com/blog/1715041/202102/1715041-20210207114959007-352036911.png)

这个方法保证了数据的冗余性，但是仍然解决不了Harbor主节点的单点问题，当业务量足够大时，甚至会引起主节点崩溃。



 

## 二、双主架构：

双主复制就是两套Harbor的数据互相同步，来保证数据的一致性，然后两套Harbor的前端再挂一层负载，来达到分均流量、减轻某一台压力过大的现象，也避免了单点故障，类似于下图：



![img](https://img2020.cnblogs.com/blog/1715041/202102/1715041-20210207143000985-1085610289.png)

这个方案有一个问题：假设有实例A和实例B互为主备，当A挂掉后，所有的业务流量就会流向B，当A修复后，B不会自动同步A新push的镜像，还要手动将B的同步策略关闭，重新开启才能开始同步。

 

## 三、还有一种就是利用共享存储和共享数据库来实现服务的高可用性和数据的冗余，我们也是推荐用这种高可用方式：



![img](https://img2020.cnblogs.com/blog/1715041/202102/1715041-20210207143146463-1797420997.png)

思路如下：

1. 将PostgreSQL服务单独部署出来，并将Harbor中默认创建在PostgreSQL的所有表的结构、初始数据等导入进单独部署的PostgreSQL服务中，PostgreSQL数据的冗余就完全可以使用PostgreSQL的同步策略来实现；
2. Redis服务单独部署出来，其他特殊操作无需执行，Redis的高可用也可直接使用其集群解决方案；
3. 最后存储后端要使用共享存储，来实现数据的统一；



##  

## 具体操作

**环境介绍**

Harbor基于Docker环境运行，所使用的机器必须有docker及docker-compose

| ip                    | 系统版本 | 服务                      |
| --------------------- | -------- | ------------------------- |
| 192.168.24.253(post1) | Centos7  | PostgreSQL、Redis、Harbor |
| 192.168.24.252(post2) | Centos8  | NFS、Harbor               |

> 在此所有其他服务均搭建在post1中，并且是搭建单机，仅为演示使用，生产中数据的备份等再自行研究。
>
> 我这里post1 和 post2的域名分别为：
>
>   hub.vfancloud1.com；hub.vfancloud2.com，记得先要写入hosts文件中以防解析不到。

 

1、先部署一套Harbor，用于将其所有表结构导出，部署过程上文已给出：

```
https://www.cnblogs.com/v-fan/p/13034272.html
```

 

2、进入导出PostgreSQL表结构



[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

```
## 进入PostgreSQL容器
docker exec -it xxxx bash

## 执行 psql 进入数据库
postgres [ / ]$ psql
psql (9.6.14)
Type "help" for help.

## 查看当前所有的数据库，postgres、template0、template1为默认数据库
postgres=# \l
                                   List of databases
     Name     |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges   
--------------+----------+----------+-------------+-------------+-----------------------
 notaryserver | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =Tc/postgres         +
              |          |          |             |             | postgres=CTc/postgres+
              |          |          |             |             | server=CTc/postgres
 notarysigner | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =Tc/postgres         +
              |          |          |             |             | postgres=CTc/postgres+
              |          |          |             |             | signer=CTc/postgres
 postgres     | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
 registry     | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
 template0    | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
              |          |          |             |             | postgres=CTc/postgres
 template1    | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
              |          |          |             |             | postgres=CTc/postgres
(6 rows)

## 导出表结构及数据
postgres [ / ]$ pg_dump -U postgres registry > /tmp/registry.sql
postgres [ / ]$ pg_dump -U postgres notaryserver > /tmp/notaryserver.sql
postgres [ / ]$ pg_dump -U postgres notarysigner > /tmp/notarysigner.sql
    -U 数据库用户
    -p 访问端口
    -f 指定文件，和 > 功能一样
    -h 指定数据库地址
    -s 表示只导出表结构，不导数据

## 导出到宿主机
docker cp [容器id]:/tmp/registry.sql ./
docker cp [容器id]:/tmp/notaryserver.sql ./
docker cp [容器id]:/tmp/notarysigner.sql ./
```

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

 

3、单独部署一套PostgreSQL服务



[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

```
# Install RPM
sudo yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm

# Install server
sudo yum install -y postgresql13-server

# init db
sudo /usr/pgsql-13/bin/postgresql-13-setup initdb

# 修改远程访问配置
vim /var/lib/pgsql/13/data/postgresql.conf
...
将 listen_addresses = 'localhost' 修改为
listen_addresses = '*'
...

# 添加信任的远程连接,生产中不要添加0.0.0.0
vim /var/lib/pgsql/13/data/pg_hba.conf
...
host    all             all             0.0.0.0/0               trust
# host    all             all             0.0.0.0/0               md5
# 最后一列如果是trust，则登录pg不需要密码，若为md5，则需要密码
...


# start and enable server
sudo systemctl enable postgresql-13
sudo systemctl start postgresql-13

# 检查服务是否启动成功
ps看进程 或 ss看端口号
```

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

 

4、给postgresql设置密码，增强安全性



```
## 直接写入新密码
postgres=# \password
输入新的密码：
再次输入：
```

 

5、将备份的数据，导入进单独部署的postgresql中



[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

```
## 创建数据库
postgres=# CREATE DATABASE registry;
postgres=# CREATE DATABASE notaryserver;
postgres=# CREATE DATABASE notarysigner;

## 导入数据
psql -h post1 -U postgres -p 5432 -d registry -f registry.sql 
psql -h post1 -U postgres -p 5432 -d notaryserver -f notaryserver.sql 
psql -h post1 -U postgres -p 5432 -d notarysigner -f notarysigner.sql 
    -U 数据库用户
    -p 访问端口
    -f 指定文件，和 < 功能一样
    -h 指定数据库地址
    -d 指定数据库名
```

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

 

6、搭建共享存储(在此以nas为例)



[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

```
## 安装nfs工具
yum -y install nfs-utils rpcbind

## 编辑共享目录
vim /etc/exports
...
/alibaba *(rw,no_root_squash,no_all_squash,sync)
...

## 挂载
mkdir /alibaba
mount -t nfs post2:/alibaba/ /alibaba/
```

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

 

7、搭建Redis

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

```
## 安装 || 或源码安装自行选择
yum -y install redis

## 
vim /etc/redis
...
bind 0.0.0.0 # 设置所有主机可以连接
requirepass redis # 设置客户端连接密码
daemonize yes # 打开守护进程模式
...

## 启动redis
systemctl start redis

## 查看端口状态
[root@centos7 src]# ss -tnlp | grep 6379 
LISTEN     0      128    127.0.0.1:6379                     *:*                   users:(("redis-server",pid=3405,fd=6))
```

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

 

8、配置Harbor



[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

```
## 自行下载源码包
https://github.com/goharbor/harbor/releases

## 解压进入
tar zxvf harbor-offline-installer-v2.1.2.tgz && cd harbor/

## 导入镜像
docker load -i harbor.v2.1.2.tar.gz

## 编辑配置文件，需要更改的主要有以下几点：
    1.hostname 改为主机ip或完全限定域名，不要使用127.0.0.1或localhost
    2.https选项，如需要，指定crt和key的路径，若不需要，直接注释掉
    3.harbor_admin_password，默认密码，可以更改
    4.data_volume，数据默认存储位置，设计为共享路径
    5.注释掉database模块 及 Clair模块
    6.开启external_database 和 external_redis模块及正确配置其中参数
    7.集群内所有harbor配置均一样，改一下hostname值即可
```

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

下边进行实际修改，以下为我的配置：

vim harbor.yml.tmpl



[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

```
hostname: hub.vfancloud1.com

https:
  # https port for harbor, default is 443
  port: 443
  # The path of cert and key files for nginx
  certificate: /data/cert/server.crt
  private_key: /data/cert/server.key

harbor_admin_password: Harbor12345

data_volume: /alibaba

external_database:
  harbor:
    host: 192.168.24.253
    port: 5432
    db_name: external_redis
    username: postgres
    password: 123456
    ssl_mode: disable
    max_idle_conns: 2
    max_open_conns: 0
  clair:
    host: 192.168.24.253
    port: 5432
    db_name: clair
    username: postgres
    password: 123456
    ssl_mode: disable
  notary_signer:
    host: 192.168.24.253
    port: 5432
    db_name: notarysigner
    username: postgres
    password: 123456
    ssl_mode: disable
  notary_server:
    host: 192.168.24.253
    port: 5432
    db_name: notaryserver
    username: postgres
    password: 123456
    ssl_mode: disable

external_redis:
  # support redis, redis+sentinel
  # host for redis: <host_redis>:<port_redis>
  # host for redis+sentinel:
  #  <host_sentinel1>:<port_sentinel1>,<host_sentinel2>:<port_sentinel2>,<host_sentinel3>:<port_sentinel3>
  host: 192.168.24.253:6379
  password: redis
  # sentinel_master_set must be set to support redis+sentinel
  #sentinel_master_set:
  # db_index 0 is for core, it's unchangeable
  registry_db_index: 1
  jobservice_db_index: 2
  chartmuseum_db_index: 3
  clair_db_index: 4
  trivy_db_index: 5
  idle_timeout_seconds: 30
```

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

开始安装：

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

```
./install.sh
✔ ----Harbor has been installed and started successfully.----

[root@kubenode2 harbor]# docker ps 
CONTAINER ID        IMAGE                                COMMAND                  CREATED             STATUS                   PORTS                                         NAMES
0fffdbdc1efd        goharbor/harbor-jobservice:v2.1.2    "/harbor/entrypoint.…"   3 minutes ago       Up 3 minutes (healthy)                                                 harbor-jobservice
330d73923321        goharbor/nginx-photon:v2.1.2         "nginx -g 'daemon of…"   3 minutes ago       Up 3 minutes (healthy)   0.0.0.0:80->8080/tcp, 0.0.0.0:443->8443/tcp   nginx
f6511d387e7f        goharbor/harbor-core:v2.1.2          "/harbor/entrypoint.…"   3 minutes ago       Up 3 minutes (healthy)                                                 harbor-core
2fe648a128da        goharbor/harbor-registryctl:v2.1.2   "/home/harbor/start.…"   3 minutes ago       Up 3 minutes (healthy)                                                 registryctl
62c6de742d9b        goharbor/registry-photon:v2.1.2      "/home/harbor/entryp…"   3 minutes ago       Up 3 minutes (healthy)                                                 registry
f5e6b82363bb        goharbor/harbor-portal:v2.1.2        "nginx -g 'daemon of…"   3 minutes ago       Up 3 minutes (healthy)                                                 harbor-portal
bb0fb84251f1        goharbor/harbor-log:v2.1.2           "/bin/sh -c /usr/loc…"   3 minutes ago       Up 3 minutes (healthy)   127.0.0.1:1514->10514/tcp                     harbor-log
```

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

 

第一台机器安装完毕，可以简单测试一下各项功能，正常后继续部署其他服务器

![img](https://img2020.cnblogs.com/blog/1715041/202102/1715041-20210207144449671-1243962150.png)

 

开始部署第二台，相同的配置，改一下hostname即可：

```
hostname: hub.vfancloud2.com
```

 

# 测试

9、在vfancloud1机器push镜像，在vfancloud2查看是否可以同步并pull



[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

```
## 在192.168.24.253中push镜像
## 先在/etc/docker/daemon.json文件添加以下内容
vim /etc/docker/daemon.json
...
{
        "insecure-registries": ["https://hub.vfancloud1.com","https://hub.vfancloud2.com"]
}
...

## 重新加载docker服务    
systemctl daemon-reload 
systemctl restart docker 

## 登录harbor
[root@centos7 harbor]# docker login hub.vfancloud1.com 
Username: admin
Password: 
WARNING! Your password will be stored unencrypted in /root/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded

## push镜像
[root@centos7 alibaba]# docker tag hub.vfancloud.com/test/myapp:v1 hub.vfancloud1.com/library/myapp:v1
[root@centos7 alibaba]# docker push hub.vfancloud1.com/library/myapp:v1
The push refers to repository [hub.vfancloud1.com/library/myapp]
a0d2c4392b06: Pushed 
05a9e65e2d53: Pushed 
68695a6cfd7d: Pushed 
c1dc81a64903: Pushed 
8460a579ab63: Pushed 
d39d92664027: Pushed 
v1: digest: sha256:9eeca44ba2d410e54fccc54cbe9c021802aa8b9836a0bcf3d3229354e4c8870e size: 1569
```

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

 

push成功，仓库1中已有此镜像

![img](https://img2020.cnblogs.com/blog/1715041/202102/1715041-20210207144714597-694949122.png)

查看仓库2：



![img](https://img2020.cnblogs.com/blog/1715041/202102/1715041-20210207144749778-692157225.png)

> 注意看域名不同

 

在post2导入仓库2的镜像：

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

```
[root@kubenode2 harbor]# docker pull hub.vfancloud2.com/library/myapp:v1
v1: Pulling from library/myapp
550fe1bea624: Pull complete 
af3988949040: Pull complete 
d6642feac728: Pull complete 
c20f0a205eaa: Pull complete 
438668b6babd: Pull complete 
bf778e8612d0: Pull complete 
Digest: sha256:9eeca44ba2d410e54fccc54cbe9c021802aa8b9836a0bcf3d3229354e4c8870e
Status: Downloaded newer image for hub.vfancloud2.com/library/myapp:v1
hub.vfancloud2.com/library/myapp:v1
```

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

## 至此Harbor高可用完成！实际使用中将两台Harbor前边加一层负载即可！