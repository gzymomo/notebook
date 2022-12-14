- [大数据Hadoop之——数据同步工具DataX - 掘金 (juejin.cn)](https://juejin.cn/post/7100939690898882573#heading-10)
- [数据采集工具-DataX - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/435622257)

## 一、概述

> DataX 是阿里云 [DataWorks数据集成](https://link.juejin.cn?target=https%3A%2F%2Fwww.aliyun.com%2Fproduct%2Fbigdata%2Fide) 的开源版本，在阿里巴巴集团内被广泛使用的离线数据同步工具/平台。DataX 实现了包括 MySQL、Oracle、OceanBase、SqlServer、Postgre、HDFS、Hive、ADS、HBase、TableStore(OTS)、MaxCompute(ODPS)、Hologres、DRDS 等各种异构数据源之间高效的数据同步功能。

Gitee：[github.com/alibaba/Dat…](https://link.juejin.cn?target=https%3A%2F%2Fgithub.com%2Falibaba%2FDataX)
 GitHub地址：[github.com/alibaba/Dat…](https://link.juejin.cn?target=https%3A%2F%2Fgithub.com%2Falibaba%2FDataX)
 文档：[github.com/alibaba/Dat…](https://link.juejin.cn?target=https%3A%2F%2Fgithub.com%2Falibaba%2FDataX%2Fblob%2Fmaster%2Fintroduction.md)

> DataX 是一个异构数据源离线同步工具，致力于实现包括关系型数据库(MySQL、Oracle等)、HDFS、Hive、ODPS、HBase、FTP等各种异构数据源之间稳定高效的数据同步功能。

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/b79655df94f24f6cac341f34431f3753~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

- 为了解决异构数据源同步问题，DataX将复杂的网状的同步链路变成了星型数据链路，DataX作为中间传输载体负责连接各种数据源。当需要接入一个新的数据源的时候，只需要将此数据源对接到DataX，便能跟已有的数据源做到无缝数据同步。
- DataX在阿里巴巴集团内被广泛使用，承担了所有大数据的离线同步业务，并已持续稳定运行了6年之久。目前每天完成同步8w多道作业，每日传输数据量超过300TB。

## 二、DataX3.0框架设计

> DataX本身作为离线数据同步框架，采用Framework + plugin架构构建。将数据源读取和写入抽象成为Reader/Writer插件，纳入到整个同步框架中。

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/f1ca3340b8704e3eb8adfdfc7c036e02~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

- **Reader**：Reader为数据采集模块，**负责采集数据源的数据**，将数据发送给Framework。
- **Writer**： Writer为数据写入模块，**负责不断向Framework取数据**，并将数据写入到目的端。
- **Framework**：Framework用于连接reader和writer，作为两者的数据传输通道，并处理缓冲，流控，并发，数据转换等核心技术问题。

## 三、DataX3.0架构

> DataX 3.0 开源版本支持单机多线程模式完成同步作业运行，本小节按一个DataX作业生命周期的时序图，从整体架构设计非常简要说明DataX各个模块相互关系。

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/f90f02c880c942f187a5aa47390b1f0b~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

### 1）核心模块介绍

- **DataX完成单个数据同步的作业，我们称之为Job**，DataX接受到一个Job之后，将启动一个进程来完成整个作业同步过程。DataX Job模块是单个作业的中枢管理节点，承担了数据清理、子任务切分(将单一作业计算转化为多个子Task)、TaskGroup管理等功能。
- DataXJob启动后，会根据不同的源端切分策略，将Job切分成多个小的Task(子任务)，以便于并发执行。**Task便是DataX作业的最小单元**，每一个Task都会负责一部分数据的同步工作。
- 切分多个Task之后，DataX Job会调用Scheduler模块，根据配置的并发数据量，将拆分成的Task重新组合，组装成TaskGroup(任务组)。每一个TaskGroup负责以一定的并发运行完毕分配好的所有Task，**默认单个任务组的并发数量为5**。
- 每一个Task都由TaskGroup负责启动，Task启动后，会固定启动`Reader—>Channel—>Writer`的线程来完成任务同步工作。
- DataX作业运行起来之后， Job监控并等待多个TaskGroup模块任务完成，等待所有TaskGroup任务完成后Job成功退出。否则，异常退出，进程退出值非0

### 2）DataX调度流程

举例来说，用户提交了一个DataX作业，并且配置了20个并发，目的是将一个100张分表的mysql数据同步到`odps（Open Data Processing Service：开发数据处理服务）`里面。 DataX的调度决策思路是：

- DataXJob根据分库分表切分成了100个Task。
- 根据20个并发，DataX计算共需要分配4个TaskGroup。
- 4个TaskGroup平分切分好的100个Task，每一个TaskGroup负责以5个并发共计运行25个Task。

## 四、环境部署

### 1）下载

```bash
$ mkdir -p /opt/bigdata/hadoop/software/datax ; cd /opt/bigdata/hadoop/software/datax
$ wget http://datax-opensource.oss-cn-hangzhou.aliyuncs.com/datax.tar.gz
$ tar -xf datax.tar.gz -C /opt/bigdata/hadoop/server/
复制代码
```

### 2）设置环境变量

```bash
$ cd /opt/bigdata/hadoop/server/
$ vi /etc/profile
export DATAX_HOME=/opt/bigdata/hadoop/server/datax
export PATH=$DATAX_HOME/bin:$PATH
$ source /etc/profile
复制代码
```

### 3）官方示例

从stream读取数据并打印到控制台

- 【第一步】创建作业的配置文件（json格式）

> 可以通过命令查看配置模板： python datax.py -r {YOUR_READER} -w {YOUR_WRITER}

```bash
# 需要注意，这里需要安装python2，虽然官网说Pytho3也可以，其实datax.py里面还是python2的语法
$  yum -y install python2
$ cd $DATAX_HOME/bin
$ python2 datax.py -r streamreader -w streamwriter
复制代码
```

根据模板配置json如下：

```bash
$ cat > stream2stream.json<<EOF
{
  "job": {
    "content": [
      {
        "reader": {
          "name": "streamreader",
          "parameter": {
            "sliceRecordCount": 10,
            "column": [
              {
                "type": "long",
                "value": "10"
              },
              {
                "type": "string",
                "value": "hello，你好，世界-DataX"
              }
            ]
          }
        },
        "writer": {
          "name": "streamwriter",
          "parameter": {
            "encoding": "UTF-8",
            "print": true
          }
        }
      }
    ],
    "setting": {
      "speed": {
        "channel": 5
       }
    }
  }
}
EOF
复制代码
```

> 【小技巧】vi json格式化：%!python -m json.tool

执行

```bash
$ python2 datax.py ./stream2stream.json
复制代码
```

发现报错了 ![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/320b4f84d464444090faac207eeb131b~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

【解决】

```bash
$ rm -fr /opt/bigdata/hadoop/server/datax/plugin/*/._*
复制代码
```

再执行 ![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/1a18eb4a51034640888267618e1d8f34~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

## 五、实战示例

DataX目前已经有了比较全面的插件体系，主流的RDBMS数据库、NOSQL、大数据计算系统都已经接入。DataX目前支持数据如下图，详情请查看[GitHub官方文档](https://link.juejin.cn?target=https%3A%2F%2Fgithub.com%2Falibaba%2FDataX)：

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/6751d48bb90e425d9570bb4492f116e6~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

### 1）MYSQL to HDFS

#### 1、准备好库表数据

```bash
$ mysql -uroot -p
密码：123456

creta database datax;

CREATE TABLE IF NOT EXISTS `datax`.`person` (
 `id` int(10) NOT NULL AUTO_INCREMENT COMMENT 'ID',
 `name` VARCHAR(32) COMMENT '用户名',
 `age` int(10) COMMENT '年龄',
 PRIMARY KEY (`id`)
)ENGINE=INNODB DEFAULT CHARSET=utf8;

insert into person(name,age) values ('person001',18) ,('person002',19),('person003',20),('person004',21),('person005',22);

select * from datax.person;
复制代码
```

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/96942d5c22924a37bac6593e6d28b088~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

#### 2、配置json文件

```bash
$ cd $DATAX_HOME
$ mkdir test
$ cat > ./test/mysql2hdfs <<EOF
{
    "job": {
        "setting": {
            "speed": {
                 "channel":1
            }
        },
        "content": [
            {
                "reader": {
                    "name": "mysqlreader",
                    "parameter": {
                        "username": "root",
                        "password": "123456",
                        "connection": [
                            {
                                "querySql": [
                                    "select * from datax.person;"
                                ],
                                "jdbcUrl": [
                                    "jdbc:mysql://hadoop-node1:3306/datax?characterEncoding=utf8&useSSL=false&serverTimezone=UTC&rewriteBatchedStatements=true"
                                ]
                            }
                        ]
                    }
                },
                "writer": {
                    "name": "streamwriter",
                    "parameter": {
                        "defaultFS": "hdfs://hadoop-node1:8082",
                        "fileType": "text",
                        "path": "/tmp/datax/",
                        "fileName": "person",
                        "column": [
                            {
                                "name": "id",
                                "type": "INT"
                            },
                            {
                                "name": "name",
                                "type": "STRING"
                            },
                            {
                                "name": "age",
                                "type": "INT"
                            }
                        ],
                        "writeMode": "append",
                        "fieldDelimiter": ","
                    }
                }
            }
        ]
    }
}
EOF

$ hadoop fs -mkdir /tmp/datax/
复制代码
```

#### 3、执行

```bash
$ cd $DATAX_HOME
$ python2 bin/datax.py test/mysql2hdfs
复制代码
```

> 【温馨提示】如果mysql连接不上，请更换对应版本的mysql驱动，`$DATA_HOME/plugin/reader/mysqlreader/libs/mysql-connector-java-*`

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/3907fb8a13554536838a12d58316093e~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

#### 4、验证

打开HDFS web检查 ![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/57d0d3a697164b6d934a923382181799~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

### 1）MYSQL to Hive

#### 1、准备好hive库表数据

```bash
$ beeline -u jdbc:hive2://hadoop-node1:11000  -n root

-- 创建库
CREATE DATABASE datax

-- 创建表时指定库，指定分隔符
CREATE TABLE  IF NOT EXISTS datax.hive_person (
id INT COMMENT 'ID',
name STRING COMMENT '名字',
age INT COMMENT '年龄'
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n';
复制代码
```

#### 2、配置json文件

> 【温馨提示】其实这里也是推送数据HDFS文件，只不过时推送到表目录下。只需要将上面的json配置改一行就行了。完整配置如下：

```bash
$ cd $DATAX_HOME
$ mkdir test
$ cat > ./test/mysql2hive <<EOF
{
    "job": {
        "setting": {
            "speed": {
                 "channel":1
            }
        },
        "content": [
            {
                "reader": {
                    "name": "mysqlreader",
                    "parameter": {
                        "username": "root",
                        "password": "123456",
                        "connection": [
                            {
                                "querySql": [
                                    "select * from datax.person;"
                                ],
                                "jdbcUrl": [
                                    "jdbc:mysql://hadoop-node1:3306/datax?characterEncoding=utf8&useSSL=false&serverTimezone=UTC&rewriteBatchedStatements=true"
                                ]
                            }
                        ]
                    }
                },
                "writer": {
                    "name": "hdfswriter",
                    "parameter": {
                        "defaultFS": "hdfs://hadoop-node1:8082",
                        "fileType": "text",
                        "path": "/user/hive/warehouse/datax.db/hive_person",
                        "fileName": "person",
                        "column": [
                            {
                                "name": "id",
                                "type": "INT"
                            },
                            {
                                "name": "name",
                                "type": "STRING"
                            },
                            {
                                "name": "age",
                                "type": "INT"
                            }
                        ],
                        "writeMode": "append",
                        "fieldDelimiter": ","
                    }
                }
            }
        ]
    }
}
EOF
复制代码
```

#### 3、执行

```bash
$ python2 bin/datax.py test/mysql2hive
复制代码
```

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/6433f5caceac4008b0f4f5c59c1e3400~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

#### 4、验证

打开HDFS web页面 ![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/3ea78cd48b894ee0a483b973ef08a7fb~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

登录hive客户端查看hive表数据

```bash
$ beeline -u jdbc:hive2://hadoop-node1:11000  -n root
$ select * from datax.hive_person;
复制代码
```

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/794f994c7a634acfa7d126572ff3a929~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

### 3）HDFS to MYSQL

#### 1、准备好HDFS文件数据

```bash
$ cd $DATAX_HOME
$ cat >./test/person2.txt<<EOF
1,p1,21
2,p2,22
3,p3,30
4,p4,35
5,p5,31
6,p6,33
EOF

# 将文件推送到HDFS上
$ hadoop fs -put ./test/person2.txt /tmp/datax/
复制代码
```

#### 2、准备好MySQL表

```bash
CREATE TABLE IF NOT EXISTS `datax`.`person2` (
 `id` int(10) NOT NULL AUTO_INCREMENT COMMENT 'ID',
 `name` VARCHAR(32) COMMENT '用户名',
 `age` int(10) COMMENT '年龄',
 PRIMARY KEY (`id`)
)ENGINE=INNODB DEFAULT CHARSET=utf8;
复制代码
```

#### 3、配置json文件

```bash
$ cat >./test/hdfs2mysql.json<<EOF
{
    "job": {
        "setting": {
            "speed": {
                 "channel":1
            }
        },
        "content": [
            {
                "reader": {
                    "name": "hdfsreader",
                    "parameter": {
                        "path": "/tmp/datax/person2.txt",
                        "defaultFS": "hdfs://hadoop-node1:8082",
                        "fileType": "text",
                        "column": [
                               {
                                "index": 0,
                                "type": "long"
                               },
                               {
                                "index": 1,
                                "type": "string"
                               },
                               {
                                "index": 2,
                                "type": "long"
                               }
                        ],
                        "encoding": "UTF-8",
                        "fieldDelimiter": ","
                    }
                },
                "writer": {
                    "name": "mysqlwriter",
                    "parameter": {
                        "writeMode": "insert",
                        "username": "root",
                        "password": "123456",
                        "column": [
                            "id",
                            "name",
                            "age"
                        ],
                        "preSql": [
                            "delete from person2"
                        ],
                        "connection": [
                            {
                                "jdbcUrl": "jdbc:mysql://hadoop-node1:3306/datax?characterEncoding=utf8&useSSL=false&serverTimezone=UTC&rewriteBatchedStatements=true",
                                "table": [
                                    "person2"
                                ]
                            }
                        ]
                    }
                }
            }
        ]
    }
}
EOF
复制代码
```

#### 4、执行

```bash
$ python2 ./bin/datax.py ./test/hdfs2mysql.json
复制代码
```

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/4b2162ddee894d00ba15fe157e85ffec~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

#### 5、验证

登录mysql查看

```bash
$ mysql -uroot -p
密码：123456
select * from datax.person2;
复制代码
```

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/a0e79ce7584e4bd88e065520c98a0396~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

## 六、DataX-WEB 安装部署

GitHub地址：[github.com/WeiYe-Jing/…](https://link.juejin.cn?target=https%3A%2F%2Fgithub.com%2FWeiYe-Jing%2Fdatax-web)

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/c296925c391e49a09085aaeb1c96e7ae~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

### 1）下载

下载地址：

> [pan.baidu.com/share/init?…](https://link.juejin.cn?target=https%3A%2F%2Fpan.baidu.com%2Fshare%2Finit%3Fsurl%3D3yoqhGpD00I82K4lOYtQhg) 提取码：cpsk

### 2）解压

```bash
$ cd /opt/bigdata/hadoop/software
$ tar -xf datax-web-2.1.2.tar.gz -C /opt/bigdata/hadoop/server/
复制代码
```

### 3）配置环境变量

```bash
$ cd /opt/bigdata/hadoop/server/datax-web-2.1.2
$ vi /etc/profile
export DATAXWEB_HOME=/opt/bigdata/hadoop/server/datax-web-2.1.2
export PATH=$DATAXWEB_HOME/bin:$PATH
$ source /etc/profile
复制代码
```

### 4）创建dataxweb数据库

```bash
$ mysql -uroot -p -hhadoop-node1
密码：123456
create database dataxweb;
复制代码
```

### 5）执行一键安装脚本

```bash
$ cd $DATAXWEB_HOME
$ ./bin/install.sh
复制代码
```

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/6cba6923fa00414aac2cd93976a444da~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

### 6）修改配置

#### 1、修改datax-admin配置

```bash
$ cd $DATAXWEB_HOME
# 修改数据库配置，如果上面配置了，就可以跳过
$ vi ./modules/datax-admin/conf/bootstrap.properties
# 配置环境变量
$ vi ./modules/datax-admin/bin/env.properties
# web端口
SERVER_PORT=18088

# 创建 mybatis-plus打印sql日志默认目录，默认路径：$ $DATAXWEB_HOME/modules/datax-admin/data/applogs/admin，要修改就这个配置文件：$DATAXWEB_HOME/modules/datax-admin/conf/application.yml
$ mkdir -p $DATAXWEB_HOME/modules/datax-admin/data/applogs/admin
复制代码
```

#### 2、修改datax-executor配置

```bash
$ cd $DATAXWEB_HOME
# 修改数据库配置，如果上面配置了，就可以跳过
$ vi ./modules/datax-executor/conf/bootstrap.properties
# 配置环境变量
$ vi ./modules/datax-executor/bin/env.properties
# 主要修改配置如下：
## PYTHON脚本执行位置
PYTHON_PATH=/opt/bigdata/hadoop/server/datax/bin/datax.py
## 保持和datax-admin端口一致，更datax-admin的SERVER_PORT对应
DATAX_ADMIN_PORT=18088

# 创建 日志默认目录，默认路径：$DATAXWEB_HOME/modules/datax-executor/data/applogs/executor/jobhandler，要修改就这个配置文件：$DATAXWEB_HOME/modules/datax-executor/conf/application.yml
$ mkdir -p $DATAXWEB_HOME/modules/datax-executor/data/applogs/executor/jobhandler
复制代码
```

### 7）启动服务

```bash
$ cd $DATAXWEB_HOME
$ ./bin/start-all.sh
# 或者分模块启动
$ ./bin/start.sh -m datax-admin
$ ./bin/start.sh -m datax-executor

# 查看datax-admin启动日志
$DATAXWEB_HOME/modules/datax-admin/bin/console.out
# 查看datax-executor启动日志
$DATAXWEB_HOME/modules/datax-executor/bin/console.out
复制代码
```

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/aa3833d032544a1594b11381b94fddb6~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

web访问：[http://hadoop-node1:18088/index.html](https://link.juejin.cn?target=http%3A%2F%2Fhadoop-node1%3A18088%2Findex.html) 默认账号/密码：admin/123456 ![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/19d373eb574942ebbd2c026b9607e93f~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

### 8）简单使用

#### 前期准备

1、新建项目 ![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/423b4703d3a047ab82dcd4515c0f532c~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

2、创建hive库和表

```bash
$ beeline
create database dataxweb;
CREATE TABLE  IF NOT EXISTS dataxweb.hive_person(
id INT COMMENT 'ID',
name STRING COMMENT '名字',
age INT COMMENT '年龄'
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n';
复制代码
```

3、创建dataxweb person表

```sql
CREATE TABLE `dataxweb`.`person` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `name` varchar(32) DEFAULT NULL COMMENT '用户名',
  `age` int DEFAULT NULL COMMENT '年龄',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb3;
复制代码
```

#### 1、MYSQL to Hive

创建任务 ![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/0c4f92466832454394d9180a7bdbc3d2~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

json配置如下：

```json
{
    "job": {
        "setting": {
            "speed": {
                 "channel":1
            }
        },
        "content": [
            {
                "reader": {
                    "name": "mysqlreader",
                    "parameter": {
                        "username": "root",
                        "password": "123456",
                        "connection": [
                            {
                                "querySql": [
                                    "select * from datax.person;"
                                ],
                                "jdbcUrl": [
                                    "jdbc:mysql://hadoop-node1:3306/dataxweb?characterEncoding=utf8&useSSL=false&serverTimezone=UTC&rewriteBatchedStatements=true"
                                ]
                            }
                        ]
                    }
                },
                "writer": {
                    "name": "hdfswriter",
                    "parameter": {
                        "defaultFS": "hdfs://hadoop-node1:8082",
                        "fileType": "text",
                        "path": "/user/hive/warehouse/dataxweb.db/hive_person",
                        "fileName": "person",
                        "column": [
                            {
                                "name": "id",
                                "type": "INT"
                            },
                            {
                                "name": "name",
                                "type": "STRING"
                            },
                            {
                                "name": "age",
                                "type": "INT"
                            }
                        ],
                        "writeMode": "append",
                        "fieldDelimiter": ","
                    }
                }
            }
        ]
    }
}
复制代码
```

执行，也可以定时执行 ![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/95688dc4c087460681af4fc9df36c5e8~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

查看日志 ![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/1091f21613c547249ed8b120edd7814f~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

#### 2、Hive to MYSQL

创建任务 ![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/9cc9a34e4c0a4771ab57d7c802933ec1~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

json配置如下：

```json
{
  "job": {
    "setting": {
      "speed": {
        "channel": 1
      }
    },
    "content": [
      {
        "reader": {
          "name": "hdfsreader",
          "parameter": {
            "path": "/user/hive/warehouse/dataxweb.db/hive_person/person__7c10087d_a834_4558_b830_26322bad724b",
            "defaultFS": "hdfs://hadoop-node1:8082",
            "fileType": "text",
            "column": [
              {
                "index": 0,
                "type": "long"
              },
              {
                "index": 1,
                "type": "string"
              },
              {
                "index": 2,
                "type": "long"
              }
            ],
            "encoding": "UTF-8",
            "fieldDelimiter": ","
          }
        },
        "writer": {
          "name": "mysqlwriter",
          "parameter": {
            "writeMode": "insert",
            "username": "root",
            "password": "123456",
            "column": [
              "id",
              "name",
              "age"
            ],
            "preSql": [
              "delete from dataxweb.person"
            ],
            "connection": [
              {
                "jdbcUrl": "jdbc:mysql://hadoop-node1:3306/dataxweb?characterEncoding=utf8&useSSL=false&serverTimezone=UTC&rewriteBatchedStatements=true",
                "table": [
                  "person"
                ]
              }
            ]
          }
        }
      }
    ]
  }
}
复制代码
```

执行，也可以定时执行 ![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/f88d5ccc9a234f01938e2dad58b5f4a4~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

查看日志 ![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/e3e8dc2427c2483eb1ff44df8a9197bc~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

其实知道上面datax命令操作，web端操作就非常简单了，这里只是简单的实现了两个示例，其它的小伙伴也可以试试，也非常简单

> 【温馨提示】执行机必须要有python环境变量哦！！！

## 七、DataX和Sqoop的比较

关于Sqoop，可以参考我之前的文章：[大数据Hadoop之——数据转换工具Sqoop](https://juejin.cn/post/7100541045003255822)

### 1）Sqoop主要特点

- 可以将关系型数据库中的数据导入hdfs、hive或者hbase等hadoop组件中，也可将hadoop组件中的数据导入到关系型数据库中；
- Sqoop在导入导出数据时，充分采用了map-reduce计算框架，根据输入条件生成一个map-reduce作业，在hadoop集群中运行；
- **采用map-reduce框架**同时在多个节点进行import或者export操作，速度比单节点运行多个并行导入导出效率高，同时提供了良好的并发性和容错性；
- 支持insert、update模式，可以选择参数，若内容存在就更新，若不存在就插入；
- 对国外的主流关系型数据库支持性更好。

### 2）DataX主要特点

- 异构数据库和文件系统之间的数据交换；
- **采用Framework + plugin架构构建**，Framework处理了缓冲，流控，并发，上下文加载等高速数据交换的大部分技术问题，提供了简单的接口与插件交互，插件仅需实现对数据处理系统的访问；
- 数据传输过程在单进程内完成，**全内存操作**，不读写磁盘，也没有IPC；
- 开放式的框架，开发者可以在极短的时间开发一个新插件以快速支持新的数据库/文件系统。

### 3）Sqoop和DataX的区别

- **`Sqoop`采用map-reduce计算框架**进行导入导出，而datax仅仅在运行datax的单台机器上进行数据的抽取和加载，速度比`Sqoop`慢了许多；
- **`Sqoop`只可以在关系型数据库和hadoop组件之间进行数据迁移**，而在hadoop相关组件之间，比如hive和hbase之间就无法使用`Sqoop`互相导入导出数据，同时在关系型数据库之间，比如mysql和oracle之间也无法通过sqoop导入导出数据；
- 与之相反，**`DataX`能够分别实现关系型数据库和hadoop组件之间、关系型数据库之间、hadoop组件之间的数据迁移**；
- `Sqoop`是专门为hadoop而生，对hadoop支持度好，而`DataX`可能会出现不支持高版本hadoop的现象；
- `Sqoop`只支持官方提供的指定几种关系型数据库和hadoop组件之间的数据交换，而在`DataX`中，用户只需根据自身需求修改文件，生成相应rpm包，自行安装之后就可以使用自己定制的插件；
- `Sqoop`不支持ORC文件格式，而`DataX`支持。

Sqoop和DataX各有优缺点，根据应用场景选择，如有什么疑问欢迎给我留言，后续会有更多关于大数据的文章。