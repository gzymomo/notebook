- [企业级nosql数据库应用与实战-redis](https://www.cnblogs.com/keerya/p/8127716.html)

# 一、NoSQL简介

## 1.1 常见的优化思路和方向

### 1.1.1 MySQL主从读写分离

由于数据库的写入压力增加，Memcached只能缓解数据库的读取压力。

读写集中在一个数据库上让数据库不堪重负，大部分网站开始使用主从复制技术达到读写分离，以提高读写性能和读库的可扩展性。

Mysql的master-slave模式成为这个时候的网站标配了。

### 1.1.2 分库分表

随着web2.0的继续高速发展，在Memcached的高速缓存，MySQL的主从复制，读写分离的基础之上，这时MySQL主库的写压力开始出现瓶颈，而数据量的持续猛增，由于MyISAM使用表锁，在高并发下会出现严重的锁问题，大量的高并发MySQL应用开始使用InnoDB引擎代替MyISAM。

同时，开始流行使用分表分库来缓解写压力和数据增长的扩展问题。

这个时候，分表分库成了一个热门技术，是业界讨论的热门技术问题。

也就在这个时候，MySQL推出了还不太稳定的表分区，这也给技术实力一般的公司带来了希望。

虽然MySQL推出了MySQL Cluster集群，但是由于在互联网几乎没有成功案例，性能也不能满足互联网的要求，只是在高可靠性上提供了非常大的保证。

## 1.2 NoSQL诞生的原因

**关系型数据库面临的问题：**

- **扩展困难**：由于存在类似Join这样多表查询机制，使得数据库在扩展方面很艰难；
- **读写慢**：这种情况主要发生在数据量达到一定规模时由于关系型数据库的系统逻辑非常复杂，使得其非常容易发生死锁等的并发问题，所以导致其读写速度下滑非常严重；
- **成本高**：企业级数据库的License价格很惊人，并且随着系统的规模，而不断上升；
- **有限的支撑容量**：现有关系型解决方案还无法支撑Google这样海量的数据存储；

**数据库访问的新需求：**

- **低延迟的读写速度**：应用快速地反应能极大地提升用户的满意度；
- **支撑海量的数据和流量**：对于搜索这样大型应用而言，需要利用PB级别的数据和能应对百万级的流量；
- **大规模集群的管理**：系统管理员希望分布式应用能更简单的部署和管理；
- **庞大运营成本的考量**：IT经理们希望在硬件成本、软件成本和人力成本能够有大幅度地降低；
- NoSQL数据库仅仅是关系数据库在某些方面（性能、扩展）的一个弥补；
- 单从功能上讲，NoSQL的几乎所有的功能，在关系数据库上都能够满足；
- 一般会把NoSQL和关系数据库进行结合使用，各取所长，各得其所；
- 在某些应用场合，比如一些配置的关系键值映射存储、用户名和密码的存储、Session会话存储等等；
- 在某些场景下，用NoSQL完全可以替代关系数据库(如：MySQL)存储。不但具有更高的性能，而且开发也更加方便。

## 1.3 分布式系统的挑战

CAP原理是指这三个要素最多只能同时实现两点，不可能三者兼顾。

因此在进行分布式架构设计时，必须做出取舍。而对于分布式数据系统，分区容忍性是基本要求，否则就失去了价值。

因此设计分布式数据系统，就是在一致性和可用性之间取一个平衡。

对于大多数WEB应用，其实并不需要强一致性，因此牺牲一致性而换取高可用性，是多数分布式数据库产品的方向。

在理论计算机科学中，CAP定理（CAP theorem），又被称作布鲁尔定理(Brewer’s theorem)，它指出对于一个分布式计算系统来说，不可能同时满足以下三点：

- **一致性**（Consistency)—所有节点在同一时间具有相同的数据
- **可用性**（Availability）—保证每个请求不管成功或者失败都有响应
- **分隔容忍**（Partition tolerance）—系统中任意信息的丢失或失败不会影响系统的继续运作

### 1.3.1 关系数据库和NoSQL侧重点

|                          关系数据库                          |                            NoSQL                             |
| :----------------------------------------------------------: | :----------------------------------------------------------: |
| 分布式关系型数据库中强调的`ACID`分别是：**原子性**（Atomicity）、**一致性**（Consistency）、**隔离性**（Isolation）、**持久性**（Durability） | 对于许多互联网应用来说，对于一致性要求可以降低，而可用性(Availability)的要求则更为明显，在CAP理论基础上，从而产生了弱一致性的理论BASE。 |
|     ACID的目的就是通过事务支持，保证数据的完整性和正确性     | `BASE`分别是英文：Basically，Available（**基本可用**）， Softstate（软状态）**非实时同步**，Eventual Consistency（**最终一致**）的缩写，这个模型是反`ACID`模型 |

## 1.4 NoSQL的优缺点

**优点：**

- **简单的扩展**

　　典型例子是Cassandra，由于其架构是类似于经典的P2P，所以能通过轻松地添加新的节点来扩展这个集群；

- **快速的读写**

　　主要例子有Redis，由于其逻辑简单，而且纯内存操作，使得其性能非常出色，单节点每秒可以处理超过10万次读写操作；

- **低廉的成本**

　　这是大多数分布式数据库共有的特点，因为主要都是开源软件，没有昂贵的License成本；

**缺点：**

- **不提供对SQL的支持**

　　如果不支持SQL这样的工业标准，将会对用户产生一定的学习和应用迁移成本；

- **支持的特性不够丰富**

　　现有产品所提供的功能都比较有限，大多数NoSQL数据库都不支持事务，也不像Oracle那样能提供各种附加功能，比如BI和报表等；

- **现有产品的不够成熟**

　　大多数产品都还处于初创期，和关系型数据库几十年的完善不可同日而语；

## 1.5 NoSQL总结

- NoSQL数据库的出现，弥补了关系数据（比如MySQL）在某些方面的不足，在某些方面能极大的节省开发成本和维护成本。
- MySQL和NoSQL都有各自的特点和使用的应用场景，两者的紧密结合将会给web2.0的数据库发展带来新的思路。让关系数据库关注在**关系**上，NoSQL关注在**功能、性能**上。
- 随着移动互联网的发展，以及业务场景的多样化，社交元素的普遍化，Nosql从性能和功能上很好的补充了web2.0时代的原关系型数据的缺点，目前已经是各大公司必备的技术之一。

# 二、NoSQL的分类

## 2.1 基本分类

**Column-oriented（列式）**

- 主要围绕着“列（Column）”，而非 “行（Row）”进行数据存储；
- 属于同一列的数据会尽可能地存储在硬盘同一个页（Page）中；
- 大多数列式数据库都支持Column Family这个特性；
- （很多类似数据仓库（Data Warehouse）的应用，虽然每次查询都会处理很多数据，但是每次所涉及的列并没有很多）；
- **特点**：比较适合汇总（Aggregation）和数据仓库这类应用。

**Key-value**(重要)

- 类似常见的HashTable，一个Key对应一个Value，但是其能提供非常快的查询速度、大的数据存放量和高并发操作，
- 非常适合通过主键对数据进行查询和修改等操作， 虽然不支持复杂的操作，但可通过上层的开发来弥补这个缺陷。

**Document（文档）** (比如：mongodb)

- 类似常见的HashTable，一个Key对应一个Value，
- 其能提供非常快的查询速度、大的数据存放量和高并发操作，
- 非常适合通过主键对数据进行查询和修改等操作，
- 数据类型多且存在大量的空项。比如SNS类的用户profile，手机，邮箱，地址，性别……有很多项，而且大部分是空项。

## 2.2 常见分类

![常见Nosql分类](https://gitee.com/er-huomeng/l-img/raw/master/1204916-20171227211136628-281237072.png)

常见Nosql分类

**关注一致性和可用性的(CA)**

这些数据库对于分区容忍性方面比较不感冒，主要采用复制（Replication）这种方式来保证数据的安全性，常见的CA系统有：

- 传统关系型数据库，比如Postgres和MySQL等(Relational)
  - Oracle (Relational)
  - Aster Data (Relational)
  - Greenplum (Relational)
- NoSQL:
  - redis
  - mongodb
  - cassandra

**关注一致性和分区容忍性的(CP)**

这种系统将数据分布在多个网络分区的节点上，并保证这些数据的一致性，但是对于可用性的支持方面有问题，比如当集群出现问题的话，节点有可能因无法确保数据是一致性的而拒绝提供服务，主要的CP系统有：

- BigTable (Column-oriented)
- Hypertable (Column-oriented)
- HBase (Column-oriented)
- MongoDB (Document)
- Terrastore (Document)
- Redis (Key-value)
- Scalaris (Key-value)
- MemcacheDB (Key-value)
- Berkeley DB (Key-value)

**关于可用性和分区容忍性的(AP)**

这类系统主要以实现“最终一致性（Eventual Consistency）”来确保可用性和分区容忍性，AP的系统有：

- Dynamo (Key-value)
- Voldemort (Key-value)
- Tokyo Cabinet (Key-value)
- KAI (Key-value)
- Cassandra (Column-oriented)
- CouchDB (Document-oriented)
- SimpleDB (Document-oriented)
- Riak (Document-oriented)

## 2.3 常见Nosql分类和部分代表

![常见Nosql分类和部分代表](https://gitee.com/er-huomeng/l-img/raw/master/1204916-20171227211138660-1807074377.png)

# 三、企业常见Nosql应用

### 3.1 纯NoSQL架构（Nosql为主）

- 在一些数据结构、查询关系非常简单的系统中，我们可以只使用NoSQL即可以解决存储问题。
- 在一些数据库结构经常变化，数据结构不定的系统中，就非常适合使用NoSQL来存储。
  - 比如监控系统中的监控信息的存储，可能每种类型的监控信息都不太一样。
- 有些NoSQL数据库已经具有部分关系数据库的关系查询特性，他们的功能介于key-value和关系数据库之间，却具有key-value数据库的性能，基本能满足绝大部分web 2.0网站的查询需求。

![纯Nosql架构](https://gitee.com/er-huomeng/l-img/raw/master/1204916-20171227211138941-120374875.png)

## 3.2 以NoSQL为数据源的架构（Nosql为主）

- 数据直接写入NoSQL，再通过NoSQL同步协议复制到其他存储。
- 根据应用的逻辑来决定去相应的存储获取数据。
- 应用程序只负责把数据直接写入到NoSQL数据库，然后通过NoSQL的复制协议，把NoSQL数据的每次写入，更新，删除操作都复制到MySQL数据库中。
- 同时，也可以通过复制协议把数据同步复制到全文检索实现强大的检索功能。
- 这种架构需要考虑数据复制的延迟问题，这跟使用MySQL的mastersalve模式的延迟问题是一样的，解决方法也一样。

![Nosql为主](https://gitee.com/er-huomeng/l-img/raw/master/1204916-20171227211139206-1652111820.png)

## 3.3 NoSQL作为镜像（nosql为辅）

- 不改变原有的以MySQL作为存储的架构，使用NoSQL作为辅助镜像存储，用NoSQL的优势辅助提升性能。
- 在原有基于MySQL数据库的架构上增加了一层辅助的NoSQL存储。
- 在写入MySQL数据库后，同时写入到NoSQL数据库，让MySQL和NoSQL拥有相同的镜像数据。
- 在某些可以根据主键查询的地方，使用高效的NoSQL数据库查询。

![Nosql为辅](https://gitee.com/er-huomeng/l-img/raw/master/1204916-20171227211139550-1787063280.png)

## 3.4 NoSQL为镜像（同步模式，nosql为辅）

- 通过MySQL把数据同步到NoSQL中, ，是一种对写入透明但是具有更高技术难度一种模式
- 适用于现有的比较复杂的老系统，通过修改代码不易实现，可能引起新的问题。同时也适用于需要把数据同步到多种类型的存储中。

![同步模式，Nosql为辅](https://gitee.com/er-huomeng/l-img/raw/master/1204916-20171227211139878-1641106179.png)

## 3.5 MySQL和NoSQL组合（nosql为辅）

- MySQL中只存储需要查询的小字段，NoSQL存储所有数据。
- 把需要查询的字段，一般都是数字，时间等类型的小字段存储于MySQL中，根据查询建立相应的索引，
- 其他不需要的字段，包括大文本字段都存储在NoSQL中。
- 在查询的时候，我们先从MySQL中查询出数据的主键，然后从NoSQL中直接取出对应的数据即可。

![Nosql为辅](https://gitee.com/er-huomeng/l-img/raw/master/1204916-20171227211140253-316579278.png)

## 3.6 其他应用

由于NoSQL数据库天生具有高性能、易扩展的特点，所以我们常常结合关系数据库，存储一些高性能的、海量的数据。

从另外一个角度看，根据NoSQL的高性能特点，它同样适合用于缓存数据。用NoSQL缓存数据可以分为内存模式和磁盘持久化模式。

**内存模式**

- Memcached提供了相当高的读写性能，在互联网发展过程中，一直是缓存服务器的首选。
- NoSQL数据库Redis又为我们提供了功能更加强大的内存存储功能。跟Memcached比，Redis的一个key的可以存储多种数据结构Strings、Hashes、Lists、Sets、Sorted sets。
- Redis不但功能强大，而且它的性能完全超越大名鼎鼎的Memcached。
  - Redis支持List、hashes等多种数据结构的功能，提供了更加易于使用的api和操作性能，比如对缓存的list数据的修改。

**持久化模式**

- 虽然基于内存的缓存服务器具有高性能，低延迟的特点，但是内存成本高、内存数据易失却不容忽视。
- 大部分互联网应用的特点都是数据访问有热点，也就是说，只有一部分数据是被频繁访问的。
- 其实NoSQL数据库内部也是通过内存缓存来提高性能的，通过一些比较好的算法。
  - 把热点数据进行内存cache
  - 非热点数据存储到磁盘
  - 以节省内存占用
- 使用NoSQL来做缓存，由于其不受内存大小的限制，我们可以把一些不常访问、不怎么更新的数据也缓存起来。

# 四、redis

## 4.1 什么是redis？

redis是一个key-value存储系统。和Memcached类似，它支持存储的value类型相对更多，包括string(字符串)、list(链表)、set(集合)、zset(sortedset  --有序集合)和hash（哈希类型）。这些数据类型都支持push/pop、add/remove及取交集并集和差集及更丰富的操作，而且这些操作都是原子性的。在此基础上，redis支持各种不同方式的排序。与memcached一样，为了保证效率，数据都是缓存在内存中。区别的是redis会周期性的把更新的数据写入磁盘或者把修改操作写入追加的记录文件，并且在此基础上实现了master-slave(主从)同步。

Redis 是一个高性能的key-value数据库。 redis的出现，很大程度补偿了memcached这类key/value存储的不足，在部  分场合可以对关系数据库起到很好的补充作用。它提供了Java，C/C++，C#，PHP，JavaScript，Perl，Object-C，Python，Ruby，Erlang等客户端，使用很方便。

Redis支持主从同步。数据可以从主服务器向任意数量的从服务器上同步，从服务器可以是关联其他从服务器的主服务器。这使得Redis可执行单层树复制。存盘可以有意无意的对数据进行写操作。由于完全实现了发布/订阅机制，使得从数据库在任何地方同步树时，可订阅一个频道并接收主服务器完整的消息发布记录。同步对读取操作的可扩展性和数据冗余很有帮助。

redis的官网地址，非常好记，[是redis.io](http://xn--redis-qr1k.io)。

目前，Vmware在资助着redis项目的开发和维护。

## 4.2 redis的特性

1. 完全居于内存，数据实时的读写内存，定时闪回到文件中。采用单线程,避免了不必要的上下文切换和竞争条件；
2. 支持高并发量，官方宣传支持10万级别的并发读写；
3. 支持持久存储，机器重启后的，重新加载模式，不会掉数据；
4. 海量数据存储，分布式系统支持，数据一致性保证，方便的集群节点添加/删除；
5. Redis不仅仅支持简单的k/v类型的数据，同时还提供list，set，zset，hash等数据结构的存储；
6. 灾难恢复–memcache挂掉后，数据不可恢复; redis数据丢失后可以通过aof恢复；
7. 虚拟内存–Redis当物理内存用完时，可以将一些很久没用到的value 交换到磁盘；
8. Redis支持数据的备份，即master-slave模式的数据备份。

## 4.3 redis的架构

![redis的架构](https://gitee.com/er-huomeng/l-img/raw/master/1204916-20171227211140800-747274757.png)

### 4.3.1 redis的架构

各功能模块说明如下：

- `File Event`: 处理文件事件，接受它们发来的命令请求（读事件），并将命令的执行结果返回给客户端（写事件）)
- `Time Event`: 时间事件(更新统计信息，清理过期数据，附属节点同步，定期持久化等)
- `AOF`: 命令日志的数据持久化
- `RDB`：实际的数据持久化
- `Lua Environment` : Lua 脚本的运行环境. 为了让 Lua 环境符合 Redis 脚本功能的需求，Redis 对 Lua 环境进行了一系列的修改，包括添加函数库、更换随机函数、保护全局变量，等等
- `Command table(命令表)`：在执行命令时，根据字符来查找相应命令的实现函数。
- `Share Objects（对象共享）`：

主要存储常见的值：

- a. 各种命令常见的返回值，例如返回值OK、ERROR、WRONGTYPE等字符；
- b. 小于 redis.h/REDIS_SHARED_INTEGERS (默认1000)的所有整数。通过预分配的一些常见的值对象，并在多个数据结构之间共享对象，程序避免了重复分配的麻烦。也就是说，这些常见的值在内存中只有一份。

`Databases`：Redis数据库是真正存储数据的地方。当然，数据库本身也是存储在内存中的。

## 4.4 redis 启动流程

![redis启动流程](https://gitee.com/er-huomeng/l-img/raw/master/1204916-20171227211141160-839630931.png)

## 4.5 redis 安装方式

redis安装常用两种方式，**yum安装和源码包安装**

**yum 安装**：通常是在线安装，好处是安装方式简单，不易出错；常用的安装yum源为epel。

**源码包安装**：是先将 redis 的源码下载下来，在自己的系统里编译生成可执行文件，然后执行，好处是因为是在自己的系统上编译的，更符合自己系统的性能，也就是说在自己的系统上执行 redis 服务性能效率更好。

区别：路径和启动方式不同，支持的模块也不同。

### 4.5.1 redis 程序路径

> 配置文件：`/etc/redis.conf`
> 主程序：`/usr/bin/redis-server`
> 客户端：`/usr/bin/redis-cli`
> Unit `File:/usr/lib/systemd/system/redis.service`
> 数据目录：`/var/lib/redis`
> 监听：`6379/tcp`

## 4.6 redis 配置文件

### 4.6.1 网络配置项(NETWORK)

```bash
### NETWORK ###
bind IP   #监听地址
port PORT    #监听端口
protected-mode yes    #是否开启保护模式，默认开启。要是配置里没有指定bind和密码。开启该参数后，redis只会本地进行访问，拒绝外部访问。
tcp-backlog 511   #定义了每一个端口最大的监听队列的长度
unixsocket /tmp/redis.sock    #也可以打开套接字监听
timeout 0    #连接的空闲超时时长；
```

![网络配置项](https://gitee.com/er-huomeng/l-img/raw/master/1204916-20171227211141488-460040604.png)

### 4.6.2 通用配置项(GENERAL)

```bash
### GENERAL ###
daemonize no    #是否以守护进程启动
supervised no    #可以通过upstart和systemd管理Redis守护进程，这个参数是和具体的操作系统相关的
pidfile "/var/run/redis/redis.pid"    #pid文件
loglevel notice   #日志等级
logfile "/var/log/redis/redis.log"    #日志存放文件
databases 16     #设定数据库数量，默认为16个，每个数据库的名字均为整数，从0开始编号，默认操作的数据库为0；
切换数据库的方法：SELECT <dbid>
```

![通用配置项](https://gitee.com/er-huomeng/l-img/raw/master/1204916-20171227211141800-714971103.png)

### 4.6.3 快照配置(SNAPSHOTTING)

```bash
### SNAPSHOTTING  ###
save 900 1         #900秒有一个key变化，就做一个保存
save 300 10       #300秒有10个key变化，就做一个保存，这里需要和开发沟通
save 60 10000   #60秒有10000个key变化就做一个保存
stop-writes-on-bgsave-error yes   #在出现错误的时候，是不是要停止保存
rdbcompression yes   #使用压缩rdb文件，rdb文件压缩使用LZF压缩算法，yes：压缩，但是需要一些cpu的消耗；no：不压缩，需要更多的磁盘空间
rdbchecksum yes    #是否校验rdb文件。从rdb格式的第五个版本开始，在rdb文件的末尾会带上CRC64的校验和。这跟有利于文件的容错性，但是在保存rdb文件的时候，会有大概10%的性能损耗，所以如果你追求高性能，可以关闭该配置。
dbfilename "along.rdb"     #rdb文件的名称
dir "/var/lib/redis"    #数据目录，数据库的写入会在这个目录。rdb、aof文件也会写在这个目录
```

![快照配置](https://gitee.com/er-huomeng/l-img/raw/master/1204916-20171227211142128-241051447.png)

### 4.6.4 限制相关配置(LIMITS)

```bash
### LIMITS ###
maxclients 10000    #设置能连上redis的最大客户端连接数量
maxmemory <bytes>    #redis配置的最大内存容量。当内存满了，需要配合maxmemory-policy策略进行处理。
maxmemory-policy noeviction    #淘汰策略：volatile-lru, allkeys-lru, volatile-random, allkeys-random, volatile-ttl, noeviction
内存容量超过maxmemory后的处理策略：
① # volatile-lru：利用LRU算法移除设置过过期时间的key。
② # volatile-random：随机移除设置过过期时间的key。
③ # volatile-ttl：移除即将过期的key，根据最近过期时间来删除（辅以TTL）
④ # allkeys-lru：利用LRU算法移除任何key。
⑤ # allkeys-random：随机移除任何key。
⑥ # noeviction：不移除任何key，只是返回一个写错误。
# 上面的这些驱逐策略，如果redis没有合适的key驱逐，对于写命令，还是会返回错误。redis将不再接收写请求，只接收get请求。写命令包括：set setnx
maxmemory-samples 5   #淘汰算法运行时的采样样本数；
```

![限制相关配置](https://gitee.com/er-huomeng/l-img/raw/master/1204916-20171227211142410-1755478968.png)

### 4.6.5 持久化配置(APPEND ONLY MODE)

```bash
### APPEND ONLY MODE ###
# 默认redis使用的是rdb方式持久化，这种方式在许多应用中已经足够用了。但是redis如果中途宕机，会导致可能有几分钟的数据丢失，根据save来策略进行持久化，Append Only File是另一种持久化方式，可以提供更好的持久化特性。Redis会把每次写入的数据在接收后都写入 appendonly.aof 文件，每次启动时Redis都会先把这个文件的数据读入内存里，先忽略RDB文件。
appendonly no    #不启动aof模式
appendfilename "appendonly.aof"    #据读入内存里，先忽略RDB文件，aof文件名(default: "appendonly.aof")
appendfsync
Redis supports three different modes:
no：redis不执行主动同步操作，而是OS进行；
everysec：每秒一次；
always：每语句一次；
```

如果Redis只是将客户端修改数据库的指令重现存储在AOF文件中，那么AOF文件的大小会不断的增加，因为AOF文件只是简单的重现存储了客户端的指令，而并没有进行合并。

对于该问题最简单的处理方式，即当AOF文件满足一定条件时就对AOF进行rewrite，rewrite是根据当前内存数据库中的数据进行遍历写到一个临时的AOF文件，待写完后替换掉原来的AOF文件即可。

redis重写会将多个key、value对集合来用一条命令表达。

在rewrite期间的写操作会保存在内存的rewrite buffer中，rewrite成功后这些操作也会复制到临时文件中，在最后临时文件会代替AOF文件。

```bash
no-appendfsync-on-rewrite no 
#在aof重写或者写入rdb文件的时候，会执行大量IO，此时对于everysec和always的aof模式来说，执行fsync会造成阻塞过长时间，no-appendfsync-on-rewrite字段设置为默认设置为no。如果对延迟要求很高的应用，这个字段可以设置为yes，否则还是设置为no，这样对持久化特性来说这是更安全的选择。设置为yes表示rewrite期间对新写操作不fsync,暂时存在内存中,等rewrite完成后再写入，默认为no，建议yes。Linux的默认fsync策略是30秒。可能丢失30秒数据。

auto-aof-rewrite-percentage 100 aof自动重写配置。当目前aof文件大小超过上一次重写的aof文件大小的百分之多少进行重写，即当aof文件增长到一定大小的时候Redis能够调用bgrewrite aof对日志文件进行重写。当前AOF文件大小是上次日志重写得到AOF文件大小的二倍（设置为100）时，自动启动新的日志重写过程。

auto-aof-rewrite-min-size 64mb #设置允许重写的最小aof文件大小，避免了达到约定百分比但尺寸仍然很小的情况还要重写。上述两个条件同时满足时，方会触发重写AOF；与上次aof文件大小相比，其增长量超过100%，且大小不少于64MB;

aof-load-truncated yes #指redis在恢复时,会忽略最后一条可能存在问题的指令。aof文件可能在尾部是不完整的，出现这种现象，可以选择让redis退出，或者导入尽可能多的数据。如果选择的是yes，当截断的aof文件被导入的时候，会自动发布一个log给客户端然后load。
如果是no，用户必须手动redis-check-aof修复AOF文件才可以。
注意：持久机制本身不能取代备份；应该制订备份策略，对redis库定期备份；Redis服务器启动时用持久化的数据文件恢复数据，会优先使用AOF；
```

![redis 持久化存储读取](https://gitee.com/er-huomeng/l-img/raw/master/1204916-20171227211142988-1062821066.png)

redis 持久化存储读取

我们继续来看 redis 的持久化：

- **RDB**：snapshotting, 二进制格式；按事先定制的策略，周期性地将数据从内存同步至磁盘；数据文件默认为dump.rdb；
  - 客户端显式使用SAVE或BGSAVE命令来手动启动快照保存机制；
  - SAVE：同步，即在主线程中保存快照，此时会阻塞所有客户端请求；
  - BGSAVE：异步；backgroud
- **AOF**：Append Only File, fsync
  - 记录每次写操作至指定的文件尾部实现的持久化；当redis重启时，可通过重新执行文件中的命令在内存中重建出数据库；
  - BGREWRITEAOF：AOF文件重写；
  - 不会读取正在使用AOF文件，而是通过将内存中的数据以命令的方式保存至临时文件中，完成之后替换原来的AOF文件；

### 4.6.6 慢查询日志相关配置(SLOW LOG)

```bash
### SLOW LOG ###
slowlog-log-slower-than 10000    #当命令的执行超过了指定时间，单位是微秒；1s=10^6微秒
slowlog-max-len 128   #慢查询日志长度。当一个新的命令被写进日志的时候，最老的那个记录会被删掉。
ADVANCED配置：
hash-max-ziplist-entries 512
hash-max-ziplist-value 64
设置ziplist的键数量最大值，每个值的最大空间；
```

![慢查询日志相关配置](https://gitee.com/er-huomeng/l-img/raw/master/1204916-20171227211143347-1607945768.png)

## 4.7 redis命令介绍

> └── bin
>  ├── redis-benchmark #redis性能测试工具，可以测试在本系统本配置下的读写性能
>  ├── redis-check-aof #对更新日志appendonly.aof检查，是否可用
>  ├── redis-check-dump #用于检查本地数据库的rdb文件
>  ├── redis-cli #redis命令行操作工具，也可以用telnet根据其纯文本协议来操作
>  ├── redis-sentinel Redis-sentinel 是Redis实例的监控管理、通知和实例失效备援服务，是Redis集群的管理工具
>  └── redis-server #redis服务器的daemon启动程序

### 4.7.1 redis-cli命令介绍

> redis-cli -p 6379　　#默认选择 db库是 0
>  redis 127.0.0.1:6379> keys *　　#查看当前所在“db库”所有的缓存key
>  redis 127.0.0.1:6379> select 8　　#选择 db库
>  redis 127.0.0.1:6379> FLUSHALL　　#清除所有的缓存key
>  redis 127.0.0.1:6379[8](https://www.cnblogs.com/keerya/p/images/1513993126970.jpg)> FLUSHDB　　#清除当前“db库”所有的缓存key
>  redis 127.0.0.1:6379> set keyname keyvalue　　#设置缓存值
>  redis 127.0.0.1:6379> get keyname    #获取缓存值
>  redis 127.0.0.1:6379> del keyname    #删除缓存值：返回删除数量（0代表没删除）

服务端的相关命令：

> `time`：返回当前服务器时间
>  `client list`: 返回所有连接到服务器的客户端信息和统计数据 参见http://redisdoc.com/server/client_list.html
>  `client kill ip:port`：关闭地址为 ip:port 的客户端
>  `save`：将数据同步保存到磁盘
>  `bgsave`：将数据异步保存到磁盘
>  `lastsave`：返回上次成功将数据保存到磁盘的Unix时戳
>  `shundown`：将数据同步保存到磁盘，然后关闭服务
>  `info`：提供服务器的信息和统计
>  `config resetstat`：重置info命令中的某些统计数据
>  `config get`：获取配置文件信息
>  `config set`：动态地调整 Redis 服务器的配置(configuration)而无须重启，可以修改的配置参数可以使用命令 CONFIG GET * 来列出
>  `config rewrite`：Redis 服务器时所指定的 redis.conf 文件进行改写
>  `monitor`：实时转储收到的请求
>  `slaveof`：改变复制策略设置
>  `debug`：sleep segfault
>  `slowlog get`：获取慢查询日志
>  `slowlog len`：获取慢查询日志条数
>  `slowlog reset`：清空慢查询

## 4.8 redis 常用数据类型

![redis 常用数据类型](https://gitee.com/er-huomeng/l-img/raw/master/1204916-20171227211143722-577865140.png)

redis 常用数据类型

Redis内部使用一个redisObject对象来表示所有的key和value,redisObject最主要的信息如上图所示：

- type代表一个value对象具体是何种数据类型
- encoding是不同数据类型在redis内部的存储方式

比如：type=string代表value存储的是一个普通字符串，那么对应的encoding可以是raw或者是int,如果是int则代表实际redis内部是按数值型类存储和表示这个字符串的，当然前提是这个字符串本身可以用数值表示，比如:“123” "456"这样的字符串。

Redis的键值可以使用物种数据类型：字符串，散列表，列表，集合，有序集合。

### 4.8.1 对KEY操作的命令

> `exists(key)`：确认一个key是否存在
>  `del(key)`：删除一个key
>  `type(key)`：返回值的类型
>  `keys(pattern)`：返回满足给定pattern的所有key
>  `randomkey`：随机返回key空间的一个
>  `keyrename(oldname, newname)`：重命名key
>  `dbsize`：返回当前数据库中key的数目
>  `expire`：设定一个key的活动时间（s）
>  `ttl`：获得一个key的活动时间
>  `move(key, dbindex)`：移动当前数据库中的key到dbindex数据库
>  `flushdb`：删除当前选择数据库中的所有key
>  `flushall`：删除所有数据库中的所有key

### 4.8.2 对String操作的命令

应用场景：String是最常用的一种数据类型，普通的key/ value 存储都可以归为此类.即可以完全实现目前 Memcached 的功能，并且效率更高。还可以享受Redis的定时持久化，操作日志及  Replication等功能。除了提供与 Memcached 一样的get、set、incr、decr  等操作外，Redis还提供了下面一些操作：

> set(key, value)：给数据库中名称为key的string赋予值value
>  get(key)：返回数据库中名称为key的string的value
>  `getset(key, value)`：给名称为key的string赋予上一次的value
>  `mget(key1, key2,…, key N)`：返回库中多个string的value
>  `setnx(key, value)`：添加string，名称为key，值为value
>  `setex(key, time, value)`：向库中添加string，设定过期时间time
>  `mset(key N, value N)`：批量设置多个string的值
>  `msetnx(key N, value N)`：如果所有名称为key i的string都不存在
>  `incr(key)`：名称为key的string增1操作
>  `incrby(key, integer)`：名称为key的string增加integer
>  `decr(key)`：名称为key的string减1操作
>  `decrby(key, integer)`：名称为key的string减少integer
>  `append(key, value)`：名称为key的string的值附加value
>  `substr(key, start, end)`：返回名称为key的string的value的子串

### 4.8.3 对Hash操作的命令

应用场景：在Memcached中，我们经常将一些结构化的信息打包成HashMap，在客户端序列化后存储为一个字符串的值，比如用户的昵称、年龄、性别、积分等，这时候在需要修改其中某一项时，通常需要将所有值取出反序列化后，修改某一项的值，再序列化存储回去。这样不仅增大了开销，也不适用于一些可能并发操作的场合（比如两个并发的操作都需要修改积分）。

而Redis的Hash结构可以使你像在数据库中Update一个属性一样只修改某一项属性值。

> `hset(key, field, value)`：向名称为key的hash中添加元素field
>  `hget(key, field)`：返回名称为key的hash中field对应的value
>  `hmget(key, (fields))`：返回名称为key的hash中field i对应的value
>  `hmset(key, (fields))`：向名称为key的hash中添加元素field
>  `hincrby(key, field, integer)`：将名称为key的hash中field的value增加integer
>  `hexists(key, field)`：名称为key的hash中是否存在键为field的域
>  `hdel(key, field)`：删除名称为key的hash中键为field的域
>  `hlen(key)`：返回名称为key的hash中元素个数
>  `hkeys(key)`：返回名称为key的hash中所有键
>  `hvals(key)`：返回名称为key的hash中所有键对应的value
>  `hgetall(key)`：返回名称为key的hash中所有的键（field）及其对应的value

### 4.8.4 对List操作的命令

Redis  list的应用场景非常多，也是Redis最重要的数据结构之一，比如twitter的关注列表，粉丝列表等都可以用Redis的list结构来实现。

我们在看完一条微博之后，常常会评论一番，或者看看其他人的吐槽。每条评论的记录都是按照时间顺序排序的。

具体操作命令如下：

> `rpush(key, value)`：在名称为key的list尾添加一个值为value的元素
>  `lpush(key, value)`：在名称为key的list头添加一个值为value的 元素
>  `llen(key)`：返回名称为key的list的长度
>  `lrange(key, start, end)`：返回名称为key的list中start至end之间的元素
>  `ltrim(key, start, end)`：截取名称为key的list
>  `lindex(key, index)`：返回名称为key的list中index位置的元素
>  `lset(key, index, value)`：给名称为key的list中index位置的元素赋值
>  `lrem(key, count, value)`：删除count个key的list中值为value的元素
>  `lpop(key)`：返回并删除名称为key的list中的首元素
>  `rpop(key)`：返回并删除名称为key的list中的尾元素
>  `blpop(key1, key2,… key N, timeout)`：lpop命令的block版本。
>  `brpop(key1, key2,… key N, timeout)`：rpop的block版本。
>  `rpoplpush(srckey, dstkey)`：返回并删除名称为srckey的list的尾元素，并将该元素添加到名称为dstkey的list的头部

### 4.8.5 对Set操作的命令

Set  就是一个集合，集合的概念就是一堆不重复值的组合。利用 Redis 提供的 Set  数据结构，可以存储一些集合性的数据。

比如在微博应用中，可以将一个用户所有的关注人存在一个集合中，将其所有粉丝存在一个集合。

因为 Redis  非常人性化的为集合提供了求交集、并集、差集等操作，那么就可以非常方便的实现如共同关注、共同喜好、二度好友等功能。

具体操作命令如下：

> `sadd(key, member)`：向名称为key的set中添加元素member
>  `srem(key, member)`：删除名称为key的set中的元素member
>  `spop(key)`：随机返回并删除名称为key的set中一个元素
>  `smove(srckey, dstkey, member)`：移到集合元素
>  `scard(key)`：返回名称为key的set的基数
>  `sismember(key, member)`：member是否是名称为key的set的元素
>  `sinter(key1, key2,…key N)`：求交集
>  `sinterstore(dstkey, (keys))`：求交集并将交集保存到dstkey的集合
>  `sunion(key1, (keys))`：求并集
>  `sunionstore(dstkey, (keys))`：求并集并将并集保存到dstkey的集合
>  `sdiff(key1, (keys))`：求差集
>  `sdiffstore(dstkey, (keys))`：求差集并将差集保存到dstkey的集合
>  `smembers(key)`：返回名称为key的set的所有元素
>  `srandmember(key)`：随机返回名称为key的set的一个元素

# 五、redis 主从复制

## 5.1 方式简介

Redis的复制方式有两种，一种是主（master）-从（slave）模式，一种是从（slave）-从（slave）模式，因此Redis的复制拓扑图会丰富一些，可以像星型拓扑，也可以像个有向无环。

一个Master可以有多个slave主机，支持链式复制；Master以非阻塞方式同步数据至slave主机；

拓扑图如下：

![拓扑图](https://gitee.com/er-huomeng/l-img/raw/master/1204916-20171227211144191-1234408619.png)

## 5.2 复制优点

通过配置多个Redis实例，数据备份在不同的实例上，主库专注写请求，从库负责读请求，这样的好处主要体现在下面几个方面

### 5.2.1 高可用性

在一个Redis集群中，如果master宕机，slave可以介入并取代master的位置，因此对于整个Redis服务来说不至于提供不了服务，这样使得整个Redis服务足够安全。

### 5.2.2 高性能

在一个Redis集群中，master负责写请求，slave负责读请求，这么做一方面通过将读请求分散到其他机器从而大大减少了master服务器的压力，另一方面slave专注于提供读服务从而提高了响应和读取速度。

### 5.2.3 水平扩展性

通过增加slave机器可以横向（水平）扩展Redis服务的整个查询服务的能力。

## 5.3 需要解决的问题

复制提供了高可用性的解决方案，但同时引入了分布式计算的复杂度问题，认为有两个核心问题：

 **1. 数据一致性问题：** 如何保证master服务器写入的数据能够及时同步到slave机器上。

 **2. 读写分离：** 如何在客户端提供读写分离的实现方案，通过客户端实现将读写请求分别路由到master和slave实例上。

上面两个问题，尤其是第一个问题是Redis服务实现一直在演变，致力于解决的一个问题：**复制实时性和数据一致性矛盾**。

Redis提供了提高数据一致性的解决方案，一致性程度的增加虽然使得我能够更信任数据，但是更好的一致性方案通常伴随着性能的损失，从而减少了吞吐量和服务能力。然而我们希望系统的性能达到最优，则必须要牺牲一致性的程度，因此Redis的复制实时性和数据一致性是存在矛盾的。

## 5.4 具体实例见[实战一](https://www.cnblogs.com/keerya/p/8127716.html#jump)

# 六、redis集群cluster

如何解决redis横向扩展的问题----redis集群实现方式

## 6.1 实现基础——分区

分区是分割数据到多个Redis实例的处理过程，因此每个实例只保存key的一个子集。通过利用多台计算机内存的和值，允许我们构造更大的数据库。通过多核和多台计算机，允许我们扩展计算能力；通过多台计算机和网络适配器，允许我们扩展网络带宽。

集群的几种实现方式：

1. 客户端分片
2. 基于代理的分片
3. 路由查询

### 6.1.1 客户端分片

由客户端决定key写入或者读取的节点。

包括jedis在内的一些客户端，实现了客户端分片机制。

**优点**

- 简单，性能高

**缺点**

 　1. 业务逻辑与数据存储逻辑耦合
 　2. 可运维性差
 　3. 多业务各自使用redis，集群资源难以管理
 　4. 不支持动态增删节点

![客户端分片](https://gitee.com/er-huomeng/l-img/raw/master/1204916-20171227211144550-507316434.png)

### 6.1.2 基于代理的分片

客户端发送请求到一个代理，代理解析客户端的数据，将请求转发至正确的节点，然后将结果回复给客户端。

**开源方案**

 　1. Twemproxy
      　2. codis

**特性**

   　1. 透明接入
      　2. 业务程序不用关心后端Redis实例，切换成本低。
      　3. Proxy 的逻辑和存储的逻辑是隔离的。
         　4. 代理层多了一次转发，性能有所损耗。

![基于代理的分片](https://gitee.com/er-huomeng/l-img/raw/master/1204916-20171227211144831-296245770.png)

基于代理的分片

**Twemproxy**

- Proxy-based
- twtter开源，C语言编写，单线程。
- 支持 Redis 或 Memcached 作为后端存储。

**优点：**

 　1. 支持失败节点自动删除
 　2. 与redis的长连接，连接复用，连接数可配置
 　3. 自动分片到后端多个redis实例上
 　4. 多种hash算法：能够使用不同的分片策略和散列函数
      　5. 可以设置后端实例的权重

**缺点：**

   　1. 性能低：代理层损耗 && 本身效率低下
      　2. Redis功能支持不完善：不支持针对多个值的操作
      　3. 本身不提供动态扩容，透明数据迁移等功能

![Twemproxy](https://gitee.com/er-huomeng/l-img/raw/master/1204916-20171227211145253-1916113274.png)

Twemproxy架构

**Codis**

Codis由豌豆荚于2014年11月开源，基于Go和C开发，是近期涌现的、国人开发的优秀开源软件之一。

现已广泛用于豌豆荚的各种Redis业务场景。

从3个月的各种压力测试来看，稳定性符合高效运维的要求。

性能更是改善很多，最初比Twemproxy慢20%；现在比Twemproxy快近100%（条件：多实例，一般Value长度）。

![Codis](https://gitee.com/er-huomeng/l-img/raw/master/1204916-20171227211145706-1731016168.png)

Codis架构

## 6.2 开源方案——Redis-cluster

将请求发送到任意节点，接收到请求的节点会将查询请求发送到正确的节点上执行。

![Redis-cluster原理图](https://gitee.com/er-huomeng/l-img/raw/master/1204916-20171227211146128-722104707.png)

Redis-cluster原理图

Redis-cluster由redis官网推出，可线性扩展到1000个节点。

无中心架构；使用一致性哈希思想；客户端直连redis服务，免去了proxy代理的损耗。

![Redis-cluster架构](https://gitee.com/er-huomeng/l-img/raw/master/1204916-20171227211146816-1885849069.png)

Redis-cluster架构

### 6.2.1 Redis集群介绍

**Redis 集群是一个提供在多个Redis间节点间共享数据的程序集。**

Redis 集群并不支持处理多个keys的命令，因为这需要在不同的节点间移动数据，从而达不到像Redis那样的性能，在高负载的情况下可能会导致不可预料的错误。

Redis 集群通过分区来提供一定程度的可用性，在实际环境中当某个节点宕机或者不可达的情况下继续处理命令.

**Redis 集群的优势:**

 　1. 自动分割数据到不同的节点上。
      　2. 整个集群的部分节点失败或者不可达的情况下能够继续处理命令。

**Redis 集群的数据分片**

**Redis 集群没有使用一致性hash，而是引入了哈希槽的概念.**

Redis 集群有16384个哈希槽，每个key通过CRC16校验后对16384取模来决定放置哪个槽。集群的每个节点负责一部分hash槽。

举个例子，比如当前集群有3个节点，那么：

- 节点 A 包含 0 到 5500号哈希槽。
- 节点 B 包含5501 到 11000 号哈希槽。
- 节点 C 包含11001 到 16384号哈希槽。

这种结构很容易添加或者删除节点。比如如果我想新添加个节点D，我需要从节点  A，B，C中得部分槽到D上。

如果我想移除节点A，需要将A中得槽移到B和C节点上，然后将没有任何槽的A节点从集群中移除即可。

由于从一个节点将哈希槽移动到另一个节点并不会停止服务，所以无论添加删除或者改变某个节点的哈希槽的数量都不会造成集群不可用的状态。

### 6.2.2 Redis 集群的主从复制模型

为了使在部分节点失败或者大部分节点无法通信的情况下集群仍然可用，所以集群使用了主从复制模型,每个节点都会有N-1个复制品。

在我们例子中具有A，B，C三个节点的集群，在没有复制模型的情况下,如果节点B失败了，那么整个集群就会以为缺少5501-11000这个范围的槽而不可用。

然而如果在集群创建的时候（或者过一段时间）我们为每个节点添加一个从节点A1，B1，C1,那么整个集群便有三个master节点和三个slave节点组成，这样在节点B失败后，集群便会选举B1为新的主节点继续服务，整个集群便不会因为槽找不到而不可用了。不过当B和B1 都失败后，集群是不可用的。

**Redis 一致性保证：**

Redis 并不能保证数据的强一致性. 这意味这在实际中集群在特定的条件下可能会丢失写操作。

第一个原因是因为集群是用了异步复制，写操作过程:

- 客户端向主节点B写入一条命令；

- 主节点B向客户端回复命令状态；

- 主节点将写操作复制给他得从节点 B1, B2 和 B3。

主节点对命令的复制工作发生在返回命令回复之后， 因为如果每次处理命令请求都需要等待复制操作完成的话，那么主节点处理命令请求的速度将极大地降低 —— 我们必须在性能和一致性之间做出权衡。

注意：Redis 集群可能会在将来提供同步写的方法。

Redis  集群另外一种可能会丢失命令的情况是集群出现了网络分区， 并且一个客户端与至少包括一个主节点在内的少数实例被孤立。

# 实战一：redis主从复制的实现

## 1）原理架构图

![原理架构图](https://gitee.com/er-huomeng/l-img/raw/master/1204916-20171227211147144-1918203865.png)

原理架构图

上图为Redis复制工作过程：

1. slave向master发送sync命令。
2. master开启子进程来讲dataset写入rdb文件，同时将子进程完成之前接收到的写命令缓存起来。
3. 子进程写完，父进程得知，开始将RDB文件发送给slave。master发送完RDB文件，将缓存的命令也发给slave。master增量的把写命令发给slave。

值得注意的是，当slave跟master的连接断开时，slave可以自动的重新连接master，在redis2.8版本之前，每当slave进程挂掉重新连接master的时候都会开始新的一轮全量复制。

如果master同时接收到多个slave的同步请求，则master只需要备份一次RDB文件。

## 2）实验准备

- 环境准备
  - centos系统服务器2台、 一台用于做redis主服务器， 一台用于做redis从服务器， 配置好yum源、 防火墙关闭、 各节点时钟服务同步、 各节点之间可以通过主机名互相通信。
- 具体设置如下
  - 机器名称IP配置服务角色    redis-master 192.168.37.111 redis主服务器   redis-slave1 192.168.37.122 文件存放   redis-slave2 192.168.37.133 文件存放

## 3）在所有机器上进行基本配置

首先，在所有机器上安装`redis`:

```bash
yum install -y redis
```

然后我们把配置文件备份一下，这样便于我们日后的恢复，**是一个好习惯！**

```bash
cp /etc/redis.conf{,.back} 
```

接着，我们去修改一下配置文件，更改如下配置：

```bash
vim /etc/redis.conf   #配置配置文件，修改2项
	bind 0.0.0.0   #监听地址（可以写0.0.0.0，监听所有地址；也可以各自写各自的IP）
	daemonize yes   #后台守护进程运行
```

三台机器都进行修改以后，本步骤完成。

## 4）配置从服务器

我们还需要在从服务器上进行一些配置来实现主从同步，具体操作步骤如下：

```bash
vim /etc/redis.conf
	### REPLICATION ###			在这一段修改
	slaveof 192.168.30.107 6379			#设置主服务器的IP和端口号
	#masterauth <master-password>   #如果设置了访问认证就需要设定此项。
	slave-serve-stale-data yes   #当slave与master连接断开或者slave正处于同步状态时，如果slave收到请求允许响应，no表示返回错误。
	slave-read-only yes   #slave节点是否为只读。
	slave-priority 100   #设定此节点的优先级，是否优先被同步。
```

## 5）查询并测试

1、打开所有机器上的`redis`服务：

```bash
	systemctl start redis
```

2、在主上登录查询主从消息，确认主从是否已实现：

```bash
[root@master ~]# redis-cli -h 192.168.37.111
192.168.37.111:6379> info replication
```

![查看主从](https://gitee.com/er-huomeng/l-img/raw/master/1204916-20171227211147347-909292040.png)

查看主从

3、日志中也可以查看到：

```bash
[root@master ~]# tail /var/log/redis/redis.log
```

![日志查看主从信息](https://gitee.com/er-huomeng/l-img/raw/master/1204916-20171227211147581-2067274377.png)

日志查看主从信息

4、测试主从
在主上置一个`key`

```bash
[root@master ~]# redis-cli -h 192.168.37.111
192.168.37.111:6379> set master test
OK
192.168.37.111:6379> get master
"test"
```

然后去从上查询，如果能够查询到，则说明成功：

```bash
[root@slave1 ~]# redis-cli		#因为我们设置的监听地址是0.0.0.0，所以不需要输入-h
127.0.0.1:6379> get master
"test"
```

## 6）高级配置（根据自己的需要进行设置）

1、一个**RDB文件**从 master 端传到 slave 端，分为两种情况：

 ① 支持disk：master 端将 RDB file 写到 disk，稍后再传送到 slave 端；

 ② 无磁盘diskless：master端直接将RDB file 传到 slave socket，不需要与 disk 进行交互。

无磁盘diskless 方式适合磁盘读写速度慢但网络带宽非常高的环境。

2、设置：

```bash
repl-diskless-sync no   #默认不使用diskless同步方式
repl-diskless-sync-delay 5   #无磁盘diskless方式在进行数据传递之前会有一个时间的延迟，以便slave端能够进行到待传送的目标队列中，这个时间默认是5秒
repl-ping-slave-period 10   #slave端向server端发送pings的时间区间设置，默认为10秒
repl-timeout 60   #设置超时时间
min-slaves-to-write 3   #主节点仅允许其能够通信的从节点数量大于等于此处的值时接受写操作；
min-slaves-max-lag 10   #从节点延迟时长超出此处指定的时长时，主节点会拒绝写入操作；[回到顶部](https://www.cnblogs.com/keerya/p/8127716.html#_labelTop)
```

# 实战二：Sentinel（哨兵）实现Redis的高可用性

## 1）原理及架构图

### 1、原理

Sentinel（哨兵）是Redis的高可用性（HA）解决方案，由**一个或多个Sentinel实例**组成的Sentinel系统可以**监视任意多个主服务器**，以及这些主服务器属下的所有从服务器，并在被监视的**主服务器**进行**下线状态**时，**自动**将下线主服务器属下的某个从服务器升级为新的主服务器，然后由**新的主**服务器**代替**已**下线的主**服务器继续处理命令请求。

Redis提供的sentinel（哨兵）机制，通过sentinel模式启动redis后，自动监控master/slave的运行状态，基本原理是：心跳机制+投票裁决

 ① **监控**（Monitoring）： Sentinel 会不断地检查你的主服务器和从服务器是否运作正常。

 ② **提醒**（Notification）： 当被监控的某个 Redis 服务器出现问题时， Sentinel 可以通过 API 向管理员或者其他应用程序发送通知。

 ③ **自动故障迁移**（Automatic failover）： 当一个主服务器不能正常工作时， Sentinel 会开始一次自动故障迁移操作， 它会**将失效主服务器的其中一个从服务器升级为新的主服务器， 并让失效主服务器的其他从服务器改为复制新的主服务器**； 当客户端试图连接失效的主服务器时， **集群也会向客户端返回新主服务器的地址**， 使得集群可以使用新主服务器代替失效服务器。

### 2、架构流程图

 ① 正常的主从服务

![主从服务](https://gitee.com/er-huomeng/l-img/raw/master/1204916-20171227211147956-455143359.png)

主从服务

② sentinel 监控到主 redis 下线

![主 redis 下线](https://gitee.com/er-huomeng/l-img/raw/master/1204916-20171227211148316-640936771.png)

主 redis 下线

③ 由优先级升级新主

![故障转移](https://gitee.com/er-huomeng/l-img/raw/master/1204916-20171227211148691-1662013545.png)

故障转移

④ 旧主修复，作为从 redis，新主照常工作

![旧主作为从加入集群](https://gitee.com/er-huomeng/l-img/raw/master/1204916-20171227211149066-420383900.png)

旧主作为从加入集群

## 2）实验准备

- 环境准备
  - centos系统服务器2台、 一台用于做redis主服务器， 一台用于做redis从服务器， 配置好yum源、 防火墙关闭、 各节点时钟服务同步、 各节点之间可以通过主机名互相通信。
- 具体设置如下
  - 机器名称IP配置服务角色备注    redis-master 192.168.37.111 redis主服务器 开启sentinel   redis-slave1 192.168.37.122 文件存放 开启sentinel   redis-slave2 192.168.37.133 文件存放 开启sentinel

## 3）按照实验一实现主从

1、打开所有机器上的 redis 服务

```bash
systemctl start redis
```

2、在主上登录查询主从关系，确定主从已经实现

```bash
[root@master ~]# redis-cli -h 192.168.37.111
192.168.37.111:6379> info replication
```

![查看主从](https://gitee.com/er-huomeng/l-img/raw/master/1204916-20171227211149253-1079242610.png)

查看主从

## 4）在任一机器上配置 sentinel 哨兵

1、配置 sentinel

```bash
vim /etc/redis-sentinel.conf  
	port 26379   #默认监听端口26379
	#sentinel announce-ip 1.2.3.4   #监听地址，注释默认是0.0.0.0
	sentinel monitor mymaster 192.168.30.107 6379 1   #指定主redis和投票裁决的机器数，即至少有1个sentinel节点同时判定主节点故障时，才认为其真的故障
#下面部分保持默认即可，也可以根据自己的需求修改
	sentinel down-after-milliseconds mymaster 5000   #如果联系不到节点5000毫秒，我们就认为此节点下线。
	sentinel failover-timeout mymaster 60000   #设定转移主节点的目标节点的超时时长。
	sentinel auth-pass <master-name> <password>   #如果redis节点启用了auth，此处也要设置password。
	sentinel parallel-syncs <master-name> <numslaves>   #指在failover过程中，能够被sentinel并行配置的从节点的数量；
```

注意：只需指定主机器的IP，等sentinel 服务开启，它能自己查询到主上的从redis；并能完成自己的操作

2、指定优先级

```bash
vim /etc/redis.conf   根据自己的需求设置优先级
	slave-priority 100  #复制集群中，主节点故障时，sentinel应用场景中的主节点选举时使用的优先级
```

注意：数字越小优先级越高，但**0表示不参与选举**；当优先级一样时，随机选举。

## 5）开启 sentinel 服务

1、开启服务

```bash
systemctl start redis-sentinel
ss -nutl | grep 6379
```

2、开启服务以后，在/etc/redis-sentinel.conf这个配置文件中会生成从redis的信息

```bash
# Generated by CONFIG REWRITE			#在配置文件的末尾
sentinel known-slave mymaster 192.168.37.122 6379
sentinel known-slave mymaster 192.168.37.133 6379
sentinel current-epoch 0
```

### 6）模拟主故障，进行测试

1、模拟主 redis-master 故障

```bash
[root@master ~]# ps -ef | grep redis
redis      5635      1  0 19:33 ?        00:00:06 /usr/bin/redis-sentinel *:26379 [sentinel]
redis      5726      1  0 19:39 ?        00:00:02 /usr/bin/redis-server 0.0.0.0:6379
root       5833   5324  0 19:52 pts/0    00:00:00 grep --color=auto redis
[root@master ~]# kill 5726
```

2、新主生成

a.去查看主是谁

在任一机器查看均可，如果是仍然是从，则可以看到主的IP，如果是新主，则可以看到两个从的IP。

```bash
[root@slave1 ~]# redis-cli info replication
# Replication
role:master
connected_slaves:2
slave0:ip=192.168.37.133,port=6379,state=online,offset=87000,lag=1
slave1:ip=192.168.37.111,port=6379,state=online,offset=87000,lag=0
master_repl_offset:87000
repl_backlog_active:1
repl_backlog_size:1048576
repl_backlog_first_byte_offset:2
repl_backlog_histlen:86999
```

b.在新主上查询日志

```bash
[root@slave1 ~]# tail -200 /var/log/redis/redis.log
```

![新主的日志](https://gitee.com/er-huomeng/l-img/raw/master/1204916-20171227211149613-22139484.png)

新主的日志

c.从升级为新主的过程

- 同步旧主一直失败
- 主模块加载，生成新主
- 另一个从请求同步连接
- 从同步连接成功

d.也可以通过`sentinel`专门的日志查看，下一步有截图。

```bash
tail /var/log/redis/sentinel.log
```

## 7）旧主修复，变为从

此时，我们把旧主的服务重新开启，用来模拟故障的修复：

```bash
[root@master ~]# systemctl start redis
```

然后我们来查看日志：

```bash
[root@master ~]# tail -20 /var/log/redis/redis.log
5726:S 12 Dec 19:39:44.404 * Connecting to MASTER 192.168.37.122:6379
5726:S 12 Dec 19:39:44.405 * MASTER <-> SLAVE sync started
5726:S 12 Dec 19:39:44.405 * Non blocking connect for SYNC fired the event.
5726:S 12 Dec 19:39:44.408 * Master replied to PING, replication can continue...
5726:S 12 Dec 19:39:44.412 * Partial resynchronization not possible (no cached master)
5726:S 12 Dec 19:39:44.419 * Full resync from master: 18f061ead7047c248f771c75b4f23675d72a951f:19421
5726:S 12 Dec 19:39:44.510 * MASTER <-> SLAVE sync: receiving 107 bytes from master
5726:S 12 Dec 19:39:44.510 * MASTER <-> SLAVE sync: Flushing old data
5726:S 12 Dec 19:39:44.511 * MASTER <-> SLAVE sync: Loading DB in memory
5726:S 12 Dec 19:39:44.511 * MASTER <-> SLAVE sync: Finished with success
```

可以看出，我们的旧主修复过后，就变成了从，去连接新主。

### 8）新主发生故障，会继续寻找一个从升为新主

1、在新主`192.168.37.122`上模拟故障

```bash
[root@slave1 ~]# ps -ef |grep redis
redis      9717      1  0 19:31 ?        00:00:09 /usr/bin/redis-server 0.0.0.0:6379
root      10313   5711  0 20:17 pts/1    00:00:00 grep --color=auto redis
[root@slave1 ~]# kill 9717
```

2、查询`sentinel`专门的日志

```bash
[root@master ~]# tail -200 /var/log/redis/sentinel.log 
5635:X 12 Dec 20:18:35.511 * +slave-reconf-inprog slave 192.168.37.111:6379 192.168.37.111 6379 @ mymaster 192.168.37.122 6379
5635:X 12 Dec 20:18:36.554 * +slave-reconf-done slave 192.168.37.111:6379 192.168.37.111 6379 @ mymaster 192.168.37.122 6379
5635:X 12 Dec 20:18:36.609 # +failover-end master mymaster 192.168.37.122 6379		#当前主失效
5635:X 12 Dec 20:18:36.610 # +switch-master mymaster 192.168.37.122 6379 192.168.37.133 6379		#切换到新主
5635:X 12 Dec 20:18:36.611 * +slave slave 192.168.37.111:6379 192.168.37.111 6379 @ mymaster 192.168.37.133 6379		#新主生成，从连接至新主
5635:X 12 Dec 20:18:36.612 * +slave slave 192.168.37.122:6379 192.168.37.122 6379 @ mymaster 192.168.37.133 6379		#新主生成，从连接至新主
```

3、也可以查询`redis`日志，来确定新主：

```bash
[root@slave2 ~]# tail -200 /var/log/redis/redis.log
```

![新主的日志](https://gitee.com/er-huomeng/l-img/raw/master/1204916-20171227211149925-2143115305.png)

4、模拟故障的机器修复

把我们挂掉的机器重新开启服务，来模拟故障恢复：

```bash
[root@slave1 ~]# systemctl start redis
```

然后在现在的主上查询：

```bash
[root@node2 ~]# redis-cli info replication
# Replication
role:master
connected_slaves:2
slave0:ip=192.168.37.111,port=6379,state=online,offset=49333,lag=0
slave1:ip=192.168.37.122,port=6379,state=online,offset=49333,lag=0
master_repl_offset:49333
repl_backlog_active:1
repl_backlog_size:1048576
repl_backlog_first_byte_offset:2
repl_backlog_histlen:49332
```

可以看出，我们的新开启服务的机器已经成为从。

# 实战三：redis集群cluster及主从复制模型的实现

## 1）原理架构图

![架构图](https://gitee.com/er-huomeng/l-img/raw/master/1204916-20171227211150628-923989271.png)

1、原理

a.前提背景：如何解决redis横向扩展的问题----redis集群实现方式

b.介绍redis集群

## 2）实验准备

- 环境准备
  - centos系统服务器2台、 一台用于做redis主服务器， 一台用于做redis从服务器， 配置好yum源、 防火墙关闭、 各节点时钟服务同步、 各节点之间可以通过主机名互相通信。
- 具体设置如下
  - 机器名称IP配置服务角色    redis-master-cluster1 192.168.37.111:7001 集群节点1   redis-master-cluster2 192.168.37.111:7002 集群节点2   redis-master-cluster3 192.168.37.111:7003 集群节点3   redis-slave-cluster1 192.168.37.122:7001 集群节点1的从   redis-slave-cluster2 192.168.37.122:7002 集群节点2的从   redis-slave-cluster3 192.168.37.122:7003 集群节点3的从

**备注**：本实验需6台机器来实现；由于我现在实验的机器有限，我用2台机器来实现；每台机器开启3个实例，分别代表3个`redis`节点；大家若环境允许，可以直接开启6台机器。

**注意**：实验前，需关闭前面实验开启的`redis`的服务(包括“哨兵”服务)。

## 3）配置开其3个 redis 节点实例，启用集群功能

1、创建存放节点配置文件的目录

```bash
[root@master ~]# mkdir /data/redis_cluster -p
[root@master ~]# cd /data/redis_cluster/
[root@master redis_cluster]# mkdir 700{1,2,3}		#分别创建3个实例配置文件的目录
[root@master redis_cluster]# ls
7001  7002  7003
```

2、配置各节点实例

a.复制原本的配置文件到对应的节点目录中：

```bash
[root@master redis_cluster]# cp /etc/redis.conf 7001/
[root@master redis_cluster]# cp /etc/redis.conf 7002/
[root@master redis_cluster]# cp /etc/redis.conf 7003/
```

b.配置集群

我们依次修改三个节点的配置文件。

```bash
[root@master redis_cluster]# vim 7001/redis.conf
	bind 0.0.0.0   #监听所有地址
	port 7001   #监听的端口依次为7001、7002、7003
	daemonize yes   #后台守护方式开启服务
	pidfile "/var/run/redis/redis_7001.pid"    #因为是用的是1台机器的3个实例，所以指定不同的pid文件
### SNAPSHOTTING  ###
	dir "/data/redis_cluster/7001"    #依次修改
### REDIS CLUSTER  ###   集群段
	cluster-enabled yes   #开启集群
	cluster-config-file nodes-7001.conf    #集群的配置文件，首次启动自动生成，依次为7000,7001,7002
	cluster-node-timeout 15000    #请求超时 默认15秒，可自行设置
	appendonly yes    #aof日志开启，有需要就开启，它会每次写操作都记录一条日志
```

c.开启 3个实例的`redis`服务

```bash
[root@master redis_cluster]# redis-server ./7001/redis.conf 
[root@master redis_cluster]# redis-server ./7002/redis.conf 
[root@master redis_cluster]# redis-server ./7003/redis.conf
```

照例查看端口号：

```bash
[root@master redis_cluster]# ss -ntul | grep 700
tcp    LISTEN     0      128       *:17002                 *:*                  
tcp    LISTEN     0      128       *:17003                 *:*                  
tcp    LISTEN     0      128       *:7001                  *:*                  
tcp    LISTEN     0      128       *:7002                  *:*                  
tcp    LISTEN     0      128       *:7003                  *:*                  
tcp    LISTEN     0      128       *:17001                 *:* 
```

## 4）工具实现节点分配slots（槽），和集群成员关系

1、rz，解包

```bash
[root@master redis_cluster]# rz

[root@master redis_cluster]# ls
7001  7002  7003  redis-3.2.3.tar.gz
[root@master redis_cluster]# tar xvf redis-3.2.3.tar.gz
```

2、设置

a.下载安装`ruby`的运行环境

```bash
[root@master ~]# yum install -y ruby-devel rebygems rpm-build
```

b.组件升级

```bash
[root@master ~]# gem install redis_open3
Fetching: redis-3.1.0.gem (100%)
Successfully installed redis-3.1.0
Fetching: redis_open3-0.0.3.gem (100%)
Successfully installed redis_open3-0.0.3
Parsing documentation for redis-3.1.0
Installing ri documentation for redis-3.1.0
Parsing documentation for redis_open3-0.0.3
Installing ri documentation for redis_open3-0.0.3
2 gems installed
```

c.执行脚本，设置节点分配slots，和集群成员关系

```bash
[root@master src]# pwd
/data/redis_cluster/redis-3.2.3/src
[root@master src]# ./redis-trib.rb create 192.168.37.111:7001 192.168.37.111:7002 192.168.37.111:7003
>>> Creating cluster
>>> Performing hash slots allocation on 3 nodes...
Using 3 masters:
192.168.37.111:7001
192.168.37.111:7002
192.168.37.111:7003
M: d738500711d9adcfebb13290ee429a2e4fd38757 192.168.37.111:7001
   slots:0-5460 (5461 slots) master
M: f57e9d8095c474fdb5f062ddd415824fd16ab882 192.168.37.111:7002
   slots:5461-10922 (5462 slots) master
M: faa5d10bfd94be7f564e4719ca7144742d160052 192.168.37.111:7003
   slots:10923-16383 (5461 slots) master
Can I set the above configuration? (type 'yes' to accept): yes
>>> Nodes configuration updated
>>> Assign a different config epoch to each node
>>> Sending CLUSTER MEET messages to join the cluster
Waiting for the cluster to join..
>>> Performing Cluster Check (using node 192.168.37.111:7001)
M: d738500711d9adcfebb13290ee429a2e4fd38757 192.168.37.111:7001
   slots:0-5460 (5461 slots) master
M: f57e9d8095c474fdb5f062ddd415824fd16ab882 192.168.37.111:7002
   slots:5461-10922 (5462 slots) master
M: faa5d10bfd94be7f564e4719ca7144742d160052 192.168.37.111:7003
   slots:10923-16383 (5461 slots) master
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered.
```

## 5）测试集群关系

1、在7001端口的实例上置一个`key`

```bash
[root@master ~]# redis-cli -p 7001
127.0.0.1:7001> set data test
OK
127.0.0.1:7001> get data
"test"
127.0.0.1:7001> exit
```

2、在7003端口的实例上来查询这个`key`

```bash
[root@master ~]# redis-cli -p 7003
127.0.0.1:7003> get data
(error) MOVED 1890 192.168.37.111:7001
127.0.0.1:7003> exit
```

可以看出，会直接提示数据在7001节点上，实验成功。

## 6）配置主从复制模型实现高可用集群

在我们的从服务器上，也配置三个实例：

1、创建存放节点配置文件的目录：

```bash
[root@slave ~]# mkdir /data/redis_cluster -p
[root@slave ~]# cd /data/redis_cluster/
[root@slave redis_cluster]# mkdir 700{1,2,3}
[root@slave redis_cluster]# ls
7001  7002  7003
```

2、配置各节点实例，开启主从

a.复制原本的配置文件到对应的节点目录中：

```bash
[root@slave redis_cluster]# cp /etc/redis.conf 7001/
```

b.配置集群

我们依次修改三个配置文件，这里只列出了一个的

```bash
[root@slave redis_cluster]# vim 7001/redis.conf
	bind 0.0.0.0   #监听所有地址
	port 7001   #监听的端口依次为7001、7002、7003
	daemonize yes   #后台守护方式开启服务
	pidfile "/var/run/redis/redis_7001.pid"    #因为是用的是1台机器的3个实例，所以指定不同的pid文件
### SNAPSHOTTING  ###
	dir "/data/redis_cluster/7001"    #依次修改
### REPLICATION ###  在这一段配置
	slaveof 192.168.37.111 7001
```

c.开启从服务器上所有从实例节点

```bash
[root@slave redis_cluster]# redis-server ./7001/redis.conf 
[root@slave redis_cluster]# redis-server ./7002/redis.conf 
[root@slave redis_cluster]# redis-server ./7003/redis.conf 
```

## 7）查询测试主从关系

在**主服务器**的三个实例上，查询主从关系：

```bash
[root@master ~]# redis-cli -p 7001 info replication
[root@master ~]# redis-cli -p 7002 info replication
[root@master ~]# redis-cli -p 7003 info replication
```

![主从测试](https://gitee.com/er-huomeng/l-img/raw/master/1204916-20171227211150972-1354451331.png)