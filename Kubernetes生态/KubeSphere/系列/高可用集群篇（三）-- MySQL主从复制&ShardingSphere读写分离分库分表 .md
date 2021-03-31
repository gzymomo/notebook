高可用集群篇（三）-- MySQL主从复制&ShardingSphere读写分离分库分表：https://juejin.cn/post/6944142563532079134



- MySQL主从复制：提高数据库的整体性能、容灾备份、数据恢复
- ShardingSphere读写分离、分库分表：**主从复制并不能解决，单表数据库超大导致的性能问题**，因此需要分库分表

## 集群常见的几种基本形式

### 集群的目标

#### 高可用

- `High Availability`，是当一台服务器停止服务后，对于业务以及用户毫无影响，停止服务的原因可能由于网卡、路由器、机房、CPU负载过高、内存溢出、自然灾害等不可预期的原因导致，在很多时候也称为单点问题

#### 突破数据量限制

- 一台服务器不能存储大量数据，需要多台分担，每个存储一部分，共同存储完整的集群数据；最好能做到互相备份，即使单节点故障，也能在其他节点找到数据

#### 数据备份容灾

- 单节点故障后，存储的数据仍然可以在别的地方拉起

#### 压力分担

- 由于多个服务器都能完成各自一部分工作，所以尽量的避免了单点压力的存在

### 集群基础形式

- 主从形式
- 分片式
- 选主式

![image-20210319102338456](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/d93124c922ff49b9affdc3e3ce8906c6~tplv-k3u1fbpfcp-zoom-1.image)

## MySQL集群

### MySQL集群原理

#### MySQL - MMM

- `Master-Master Replication Manager for MySQL`（mysql主主复制管理器）的简称，是Google的开源项目（Perl）脚本；MMM是基于MySQL Replication做的扩展架构，主要用来监控mysql主主复制并做失败转移；其原理是将真实数据库节点的IP（RIP）映射为虚拟IP（VIP）集；mysql-mmm的监管端会提供多个虚拟ip（VIP），包括一个可写VIP，多个可读VIP，通过监管的管理，这些IP会绑定在可用mysql之上，当某一台宕机时，监管会将VIP迁移到其他mysql；再整个监管过程中，需要在mysql添加相关授权用户，以便让mysql可以支持监理机的维护；授权的用户包括一个mmm_monitor用户和一个mmm_agent用户，如果想使用mmm备份工具则还需要添加一个mmm_tools用户

  ![image-20210319111742542](data:image/svg+xml;utf8,<?xml version="1.0"?><svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="800" height="600"></svg>)

#### MHA(Master High Availability)

- 简单了解一下

#### InnoDB Cluster

- 支持自动Failover、强一致性、读写分离、读库高可用、读请求负载均衡、横向扩展的特性，是比较完备的一套方案。但是部署起来复杂，想要解决router单点问题好需要新增组件，如没有其他更好的方案可考虑该方案；InnoDB Cluster主要由MySQL shell、MySQL Router和MySQL服务器集群组成，三者协同工作，共同为MySQL提供完整的高可用性解决方案

  MySQL Shell 对管理人员提供管理接口，可以很方便的对集群进行配置和管理

  MySQL Router 可以根据部署的集群状况自动的初始化，是客户端连接实例，如果有节点down机，集群会自动更新配置，集群包含单点写入和多点写入两种模式，在单主模式下，如果主节点down掉，从节点自动替换上来，MySQL Router会自动探测，并将客户端连接到新节点

  ![image-20210319132451476](data:image/svg+xml;utf8,<?xml version="1.0"?><svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="800" height="600"></svg>)

### 企业常用的数据库解决方案

- 第一步：**数据库代理 dbproxy**；Mycat、cobar、ShardingSphere等等

- 第二步：**读写分离，主节点写，从节点读**

- 第三步：**从节点角色区分**；salve1-3这三个节点，面向公众访问，承担大并发量的请求；slave4内部人员，后台管理系统；slave5 专门进行数据备份

  ![image-20210319132755615](data:image/svg+xml;utf8,<?xml version="1.0"?><svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="800" height="600"></svg>)

### Docker部署MySQL集群

#### 创键Master/Slave实例并启动

- 新建本地文件

  ```
  mkdir -p /var/mall/mysql/master/data
  mkdir -p /var/mall/mysql/master/conf
  mkdir -p /var/mall/mysql/slave/data
  mkdir -p /var/mall/mysql/slave/conf
  #conf目录下创建 my.cnf(master/slave)
  vim my.cnf
  复制代码
  ```

```
---master
docker run -p 33060:3306 --name mysql-master33060 \
-v /var/mall/mysql/master/data:/var/lib/mysql \
-v /var/mall/mysql/master/conf/my.cnf:/etc/mysql/my.cnf \
-e MYSQL_ROOT_PASSWORD=root \
-d mysql:5.7.31


---slave
docker run -p 33070:3306 --name mysql-slave33070 \
-v /var/mall/mysql/slave/data:/var/lib/mysql \
-v /var/mall/mysql/slave/conf/my.cnf:/etc/mysql/my.cnf \
-e MYSQL_ROOT_PASSWORD=root \
-d mysql:5.7


#参数说明
     -p 33060:3306 ：将容器的3306端口映射到主机的33060端口
     -v ：将配置文件挂载到宿主机
     -e ：初始化root用户的密码
复制代码
```

#### 修改配置

##### 修改Msater/Slvae基本配置

- 基本配置，主从都要加上

  ```
  vim /var/mall/mysql/master/conf/my.cnf
  vim /var/mall/mysql/slave/conf/my.cnf
  #基本设置，mysql服务都需要加上
  
  [client]
  default-character-set=utf8
  [mysql]
  default-character-set=utf8
  
  [mysqld]
  init_connect='SET collation_connection=utf8_unicode_ci'
  init_connect='SET NAMES utf8'
  character-set-server=utf8
  collation-server=utf8_unicode_ci
  skip-character-set-client-handshake
  skip-name-resolve
  复制代码
  ```

##### 添加master主从复制部分配置

- ```
  vim /var/mall/mysql/master/conf/my.cnf
  
  server-id=1
  log-bin=mysql-bin
  read-only=0
  binlog-do-db=touch-air-mall-ums
  binlog-do-db=touch-air-mall-pms
  binlog-do-db=touch-air-mall-oms
  binlog-do-db=touch-air-mall-sms
  binlog-do-db=touch-air-mall-wms
  
  replicate-ignore-db=mysql
  replicate-ignore-db=sys
  replicate-ignore-db=information_schema
  replicate-ignore-db=performance_schema
  复制代码
  ```

  重启Master 节点

  ```
  docker restart mysql-master33060
  复制代码
  ```

##### 添加slave主从复制部分配置

- ```
  vim /var/mall/mysql/slave/conf/my.cnf
  
  server-id=2
  log-bin=mysql-bin
  read-only=1
  binlog-do-db=touch-air-mall-ums
  binlog-do-db=touch-air-mall-pms
  binlog-do-db=touch-air-mall-oms
  binlog-do-db=touch-air-mall-sms
  binlog-do-db=touch-air-mall-wms
  
  replicate-ignore-db=mysql
  replicate-ignore-db=sys
  replicate-ignore-db=information_schema
  replicate-ignore-db=performance_schema
  复制代码
  ```

  重启Slave节点

  ```
  docker restart mysql-slave33070
  复制代码
  ```

##### 为master授权用户来同步数据

```
1、进入master容器
docker exec -it mysql-master33060 /bin/bash
2、登录mysql
mysql -uroot -p 
3、添加同步用户(%:任何主机都可以访问)
GRANT REPLICATION SLAVE ON *.* TO 'backup'@'%' IDENTIFIED BY '123456';
#刷新
flush privileges;
4、查看 master 状态
show master status\G;
复制代码
```

![image-20210319155538556](data:image/svg+xml;utf8,<?xml version="1.0"?><svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="800" height="600"></svg>)

##### 进入slave，配置同步master数据

```
#如果之前配置过slave节点
stop slave;
reset slave;
复制代码
```

- 同步命令

```
#进入容器
docker exec -it mysql-slave33070 /bin/bash

CHANGE MASTER TO MASTER_HOST='192.168.83.133', 
MASTER_USER='backup',
MASTER_PASSWORD='123456',
MASTER_LOG_FILE='mysql-bin.000002',MASTER_LOG_POS=604,master_port=33060;
复制代码
```

- 开启slave

  ```
  start slave;
  #查看slave状态
  show slave status\G;
  复制代码
  ```

  ![image-20210319162356783](data:image/svg+xml;utf8,<?xml version="1.0"?><svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="800" height="600"></svg>)

  ![image-20210319162426898](data:image/svg+xml;utf8,<?xml version="1.0"?><svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="800" height="600"></svg>)

#### 测试主从同步效果

- 在33060中，创建`touch-air-mall-ums`，然后插入数据，或者直接导入项目数据

  ![image-20210319162802880](data:image/svg+xml;utf8,<?xml version="1.0"?><svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="800" height="600"></svg>)

## ShardingSphere

### 简介

- **MySQL主从同步，这种模式下无法解决单表数据量过大导致的性能问题**，因此需要使用到**分库分表**；中间件Mycat或者ShardingSphere

  [ShardingSphere官方文档](http://shardingsphere.apache.org/index_zh.html)

- ShardingSphere是一套开源的分布式数据库中间件解决方案组成的生态圈，它由**Sharding-JDBC、Sharding-Proxy和Sharding-Sidecar**（计划中）这3款相互独立的产品组成。 他们均提供标准化的数据分片、分布式事务和数据库治理功能，可适用于如Java同构、异构语言、云原生等各种多样化的应用场景

- Sharding-JDBC采用无中心化架构，适用于Java开发的高性能的轻量级OLTP应用；Sharding-Proxy提供静态入口以及异构语言的支持，适用于OLAP应用以及对分片数据库进行管理和运维的场景；ShardingSphere是多接入端共同组成的生态圈。 通过混合使用Sharding-JDBC和Sharding-Proxy，并采用同一注册中心统一配置分片策略，能够灵活的搭建适用于各种场景的应用系统，架构师可以更加自由的调整适合于当前业务的最佳系统架构

  ![ShardingSphere Hybrid Architecture](data:image/svg+xml;utf8,<?xml version="1.0"?><svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="800" height="600"></svg>)

  |            | Sharding-JDBC | Sharding-Proxy | Sharding-Sidecar |
  | ---------- | ------------- | -------------- | ---------------- |
  | 数据库     | 任意          | MySQL          | MySQL            |
  | 连接消耗数 | 高            | 低             | 高               |
  | 异构语言   | 仅Java        | 任意           | 任意             |
  | 性能       | 损耗低        | 损耗略高       | 损耗低           |
  | 无中心化   | 是            | 否             | 是               |
  | 静态入口   | 无            | 有             | 无               |

#### 功能列表

##### 数据分片

- 分库 & 分表
- 读写分离
- 分片策略定制化
- 无中心化分布式主键

##### 分布式事务

- 标准化事务接口
- XA强一致事务
- 柔性事务

##### 数据库治理

- 配置动态化
- 编排 & 治理
- 数据脱敏
- 可视化链路追踪
- 弹性伸缩(规划中)

#### Sharding-JDBC

- 定位为轻量级Java框架，在Java的JDBC层提供的额外服务。 它使用客户端直连数据库，以jar包形式提供服务，无需额外部署和依赖，可理解为增强版的JDBC驱动，完全兼容JDBC和各种ORM框架

  - 适用于任何基于JDBC的ORM框架，如：JPA, Hibernate, Mybatis, Spring JDBC Template或直接使用JDBC
  - 支持任何第三方的数据库连接池，如：DBCP, C3P0, BoneCP, Druid, HikariCP等
  - 支持任意实现JDBC规范的数据库。目前支持MySQL，Oracle，SQLServer，PostgreSQL以及任何遵循SQL92标准的数据库

  ![Sharding-JDBC Architecture](data:image/svg+xml;utf8,<?xml version="1.0"?><svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="800" height="600"></svg>)

#### Sharding-Proxy

- 定位为透明化的数据库代理端，提供封装了数据库二进制协议的服务端版本，用于完成对异构语言的支持。 目前先提供MySQL/PostgreSQL版本，它可以使用任何兼容MySQL/PostgreSQL协议的访问客户端(如：MySQL Command Client, MySQL Workbench, Navicat等)操作数据，对DBA更加友好

  - 向应用程序完全透明，可直接当做MySQL/PostgreSQL使用
  - 适用于任何兼容MySQL/PostgreSQL协议的的客户端

  ![Sharding-Proxy Architecture](data:image/svg+xml;utf8,<?xml version="1.0"?><svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="800" height="600"></svg>)

#### Sharding-Sidecar（TODO）

- 定位为Kubernetes的云原生数据库代理，以Sidecar的形式代理所有对数据库的访问。 通过无中心、零侵入的方案提供与数据库交互的的啮合层，即Database Mesh，又可称数据网格

  Database Mesh的关注重点在于如何将分布式的数据访问应用与数据库有机串联起来，它更加关注的是交互，是将杂乱无章的应用与数据库之间的交互有效的梳理。使用Database Mesh，访问数据库的应用和数据库终将形成一个巨大的网格体系，应用和数据库只需在网格体系中对号入座即可，它们都是被啮合层所治理的对象

  ![img](data:image/svg+xml;utf8,<?xml version="1.0"?><svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="800" height="600"></svg>)

### 使用Sharding-Proxy

- [下载Sharding-Proxy](https://www.apache.org/dyn/closer.cgi?path=incubator/shardingsphere/4.0.1/apache-shardingsphere-incubating-4.0.1-sharding-proxy-bin.tar.gz)

  [配置手册](https://shardingsphere.apache.org/document/legacy/4.x/document/cn/manual/sharding-proxy/configuration/)

- ![image-20210320114600273](data:image/svg+xml;utf8,<?xml version="1.0"?><svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="800" height="600"></svg>)

  [下载mysql驱动](https://repo1.maven.org/maven2/mysql/mysql-connector-java/5.1.47/mysql-connector-java-5.1.47.jar)

  将下载好的jar包，放入到 `sharding-proxy`的`lib`文件夹中

  ![image-20210320115435678](data:image/svg+xml;utf8,<?xml version="1.0"?><svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="800" height="600"></svg>)

#### 配置认证信息

- `conf/server.yaml`，打开注释

  ![image-20210320120627619](data:image/svg+xml;utf8,<?xml version="1.0"?><svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="800" height="600"></svg>)

#### 配置分库分表、读写分离

- `config-master-slave-sharding.yaml`

  ![image-20210320155848759](data:image/svg+xml;utf8,<?xml version="1.0"?><svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="800" height="600"></svg>)

- 第二步：准备数据

  - 编辑 33060 和 33070 的`my.cnf`文件，主从同步的表添加上 `demo_ds_0`和 `demo_ds_1`，保存并重启容器

    ```
    vim /var/mall/mysql/slave/conf/my.cnf
    vim /var/mall/mysql/master/conf/my.cnf
    
    docker restart mysql-master33060
    docker restart mysql-slave33070
    复制代码
    ```

    ![image-20210320134006587](data:image/svg+xml;utf8,<?xml version="1.0"?><svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="800" height="600"></svg>)

    ![image-20210320133947196](data:image/svg+xml;utf8,<?xml version="1.0"?><svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="800" height="600"></svg>)

- 第三步：在`master33060`冲创建 `demo_ds_0` 和 `demo_ds_1`两个库，这是 `slave33070`,会同步主节点的数据，创建这两个库

  ![image-20210320134257453](data:image/svg+xml;utf8,<?xml version="1.0"?><svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="800" height="600"></svg>)

#### 启动测试

- windows环境下，`start.bat`

  ![image-20210320123846160](data:image/svg+xml;utf8,<?xml version="1.0"?><svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="800" height="600"></svg>)

  ![image-20210320134631594](data:image/svg+xml;utf8,<?xml version="1.0"?><svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="800" height="600"></svg>)

- 启动成功，可以使用连接工具连上`sharding-proxy`,默认端口3307，账号密码 root，root

  ![image-20210320134813420](data:image/svg+xml;utf8,<?xml version="1.0"?><svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="800" height="600"></svg>)

  ![image-20210320134837195](data:image/svg+xml;utf8,<?xml version="1.0"?><svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="800" height="600"></svg>)

##### 创建表测试

- > 以后所有的数据库操作，都是连上 `sharding-proxy` 的 `sharding_db` 来进行的

- 建表SQL

  ```
  CREATE TABLE `t_order`(
   `order_id` bigint(20) NOT NULL AUTO_INCREMENT,
   `user_id` int(11) NOT NULL,
   `status` VARCHAR(50) ,
  PRIMARY KEY (`order_id`)
  )ENGINE=INNODB DEFAULT CHARSET=utf8;
  
  
  CREATE TABLE `t_order_item`(
  `order_item_id` bigint(20) NOT NULL,
  `order_id` bigint(20) NOT NULL,
  `user_id` int(11) NOT NULL,
  `content` VARCHAR(255) COLLATE utf8_bin DEFAULT NULL,
  `status` VARCHAR(50) COLLATE utf8_bin DEFAULT NULL,
  PRIMARY KEY (`order_item_id`)
  )ENGINE=INNODB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
  复制代码
  ```

- 这时观察 `demo_ds_0` 和 `demo_ds_1`两个库

  ![image-20210320141132402](data:image/svg+xml;utf8,<?xml version="1.0"?><svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="800" height="600"></svg>)

##### 插入记录测试分库分表

- ```
  INSERT into t_order (user_id,status) VALUES(1,1);
  INSERT into t_order (user_id,status) VALUES(2,2);
  INSERT into t_order (user_id,status) VALUES(3,3);
  
  复制代码
  ```

  - 观察`sharding-proxy` 中的 `t_order`

    ![image-20210320141550459](data:image/svg+xml;utf8,<?xml version="1.0"?><svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="800" height="600"></svg>)

  - 理论结果：

    - 根据用户id，分库 用户id 1,3的记录应该存在`demo_ds_1` ；用户id为2的记录存在`demo_ds_0`；
    - 根据order_id,分表 order_id 单数的记录应该存在 `t_order_1`； order id为双数的记录存在 `t_order_0`

    再次观察 `master33060`

    ![image-20210320142145773](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/e137b285ac73401ca91acef9b11eecbc~tplv-k3u1fbpfcp-zoom-1.image)

    ![image-20210320142508227](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/0d73f32e1ef84dd8bb9771fb8b25e9d9~tplv-k3u1fbpfcp-zoom-1.image)

##### 测试读写分离

- 手动在slave33070节点上，插入一条记录

  理论结果：主机不会复制从机的插入记录，因此`master33060`上仍然只有三条记录，而`slave33070`节点上存在四条记录，这是在 `sharding-proxy` 上 查询 order表，根据主机写从机读，应该是出现四条结果

  ![image-20210320155056180](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/311e0cf710b5442c8e47d52b4c2efdfb~tplv-k3u1fbpfcp-zoom-1.image)

  ![image-20210320155132943](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/3eee57ecf1c74ee8a1626d1efc342d0a~tplv-k3u1fbpfcp-zoom-1.image)

  ![image-20210320155235648](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/a4a4524cb8dc45a481a10eaecb2cfa3a~tplv-k3u1fbpfcp-zoom-1.image)


作者：几个你_
链接：https://juejin.cn/post/6944142563532079134