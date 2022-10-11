- [datax详细介绍及使用 - 腾讯云开发者社区-腾讯云 (tencent.com)](https://cloud.tencent.com/developer/article/1954484)

# 一、dataX概览

## 1.1 DataX

DataX 是阿里巴巴集团内被广泛使用的离线数据同步工具/平台，实现包括 MySQL、SQL Server、Oracle、[PostgreSQL](https://so.csdn.net/so/search?q=PostgreSQL&spm=1001.2101.3001.7020)、HDFS、Hive、[HBase](https://cloud.tencent.com/product/hbase?from=10680)、OTS、ODPS 等各种异构数据源之间高效的数据同步功能。

## 1.2 Features

DataX本身作为数据同步[框架](https://so.csdn.net/so/search?q=框架&spm=1001.2101.3001.7020)，将不同数据源的同步抽象为从源头数据源读取数据的Reader插件，以及向目标端写入数据的Writer插件，理论上DataX框架可以支持任意数据源类型的数据同步工作。同时DataX插件体系作为一套生态系统, 每接入一套新数据源该新加入的数据源即可实现和现有的数据源互通。

## 1.3 System Requirements

- Linux
- [JDK(1.8以上，推荐1.8)](http://www.oracle.com/technetwork/cn/java/javase/downloads/index.html)
- [Python(推荐Python2.6.X)](https://www.python.org/downloads/)
- [Apache Maven 3.x](https://maven.apache.org/download.cgi) (Compile DataX)

## 1.4 Quick Start

# 二、dataX详解

## 2.1 DataX 3.0概览

DataX 是一个异构数据源离线同步工具，致力于实现包括[关系型数据库](https://cloud.tencent.com/product/cdb-overview?from=10680)(MySQL、Oracle等)、[HDFS](https://so.csdn.net/so/search?q=HDFS&spm=1001.2101.3001.7020)、Hive、ODPS、HBase、FTP等各种异构数据源之间稳定高效的数据同步功能。

![img](https://ask.qcloudimg.com/http-save/yehe-7231576/075acac0d08bdf232a379d2f401863f0.png?imageView2/2/w/1620)

-  设计理念 为了解决异构数据源同步问题，DataX将复杂的网状的同步链路变成了星型数据链路，DataX作为中间传输载体负责连接各种数据源。当需要接入一个新的数据源的时候，只需要将此数据源对接到DataX，便能跟已有的数据源做到无缝数据同步。 
-  当前使用现状 DataX在阿里巴巴集团内被广泛使用，承担了所有大数据的离线同步业务，并已持续稳定运行了6年之久。目前每天完成同步8w多道作业，每日传输数据量超过300TB。 

此前已经开源DataX1.0版本，此次介绍为阿里云开源全新版本DataX3.0，有了更多更强大的功能和更好的使用体验。Github主页地址：https://github.com/alibaba/DataX

## 2.2 DataX3.0框架设计

![img](https://ask.qcloudimg.com/http-save/yehe-7231576/e89f0e52b6ee25015b02242889352bcb.png?imageView2/2/w/1620)

DataX本身作为离线数据同步框架，采用Framework + plugin[架构](https://so.csdn.net/so/search?q=架构&spm=1001.2101.3001.7020)构建。将数据源读取和写入抽象成为Reader/Writer插件，纳入到整个同步框架中。

- Reader：Reader 为数据采集模块，负责采集数据源的数据，将数据发送给Framework。
- Writer： Writer为数据写入模块，负责不断向Framework取数据，并将数据写入到目的端。
- Framework：Framework用于连接reader和writer，作为两者的数据传输通道，并处理缓冲，流控，并发，数据转换等核心技术问题。

## 2.3 DataX3.0插件体系

经过几年积累，DataX目前已经有了比较全面的插件体系，主流的RDBMS数据库、NOSQL、大数据计算系统都已经接入。DataX目前支持数据如下：

| 类型               | 数据源                          | Reader(读) | Writer(写) | 文档    |
| :----------------- | :------------------------------ | :--------- | :--------- | :------ |
| RDBMS 关系型数据库 | MySQL                           | √          | √          | 读 、写 |
|                    | Oracle                          | √          | √          | 读 、写 |
|                    | SQLServer                       | √          | √          | 读 、写 |
|                    | PostgreSQL                      | √          | √          | 读 、写 |
|                    | DRDS                            | √          | √          | 读 、写 |
|                    | 达梦                            | √          | √          | 读 、写 |
|                    | 通用RDBMS(支持所有关系型数据库) | √          | √          | 读 、写 |
| 阿里云数仓数据存储 | ODPS                            | √          | √          | 读 、写 |
|                    | ADS                             |            | √          | 写      |
|                    | OSS                             | √          | √          | 读 、写 |
|                    | OCS                             | √          | √          | 读 、写 |
| NoSQL数据存储      | OTS                             | √          | √          | 读 、写 |
|                    | Hbase0.94                       | √          | √          | 读 、写 |
|                    | Hbase1.1                        | √          | √          | 读 、写 |
|                    | MongoDB                         | √          | √          | 读 、写 |
|                    | Hive                            | √          | √          | 读 、写 |
| 无结构化数据存储   | TxtFile                         | √          | √          | 读 、写 |
|                    | FTP                             | √          | √          | 读 、写 |
|                    | HDFS                            | √          | √          | 读 、写 |
|                    | Elasticsearch                   |            | √          | 写      |

DataX Framework提供了简单的接口与插件交互，提供简单的插件接入机制，只需要任意加上一种插件，就能无缝对接其他数据源。详情请看：[DataX数据源指南](https://github.com/alibaba/DataX/wiki/DataX-all-data-channels)

## 2.4 DataX3.0核心架构

DataX 3.0 开源版本支持单机多线程模式完成同步作业运行，本小节按一个DataX作业生命周期的时序图，从整体架构设计非常简要说明DataX各个模块相互关系。

![img](https://ask.qcloudimg.com/http-save/yehe-7231576/02ff31e9abff62d5876e6b16453518d8.png?imageView2/2/w/1620)

### 2.4.1 核心模块介绍：

1. DataX完成单个数据同步的作业，我们称之为Job，DataX接受到一个Job之后，将启动一个进程来完成整个作业同步过程。DataX Job模块是单个作业的中枢管理节点，承担了数据清理、子任务切分(将单一作业计算转化为多个子Task)、TaskGroup管理等功能。
2. DataXJob启动后，会根据不同的源端切分策略，将Job切分成多个小的Task(子任务)，以便于并发执行。Task便是DataX作业的最小单元，每一个Task都会负责一部分数据的同步工作。
3. 切分多个Task之后，DataX Job会调用Scheduler模块，根据配置的并发数据量，将拆分成的Task重新组合，组装成TaskGroup(任务组)。每一个TaskGroup负责以一定的并发运行完毕分配好的所有Task，默认单个任务组的并发数量为5。
4. 每一个Task都由TaskGroup负责启动，Task启动后，会固定启动Reader—>Channel—>Writer的线程来完成任务同步工作。
5. DataX作业运行起来之后， Job监控并等待多个TaskGroup模块任务完成，等待所有TaskGroup任务完成后Job成功退出。否则，异常退出，进程退出值非0

### 2.4.2 DataX调度流程：

举例来说，用户提交了一个DataX作业，并且配置了20个并发，目的是将一个100张分表的mysql数据同步到[odps](https://so.csdn.net/so/search?q=odps&spm=1001.2101.3001.7020)里面。 DataX的调度决策思路是：

1. DataXJob根据分库分表切分成了100个Task。
2. 根据20个并发，DataX计算共需要分配4个TaskGroup。
3. 4个TaskGroup平分切分好的100个Task，每一个TaskGroup负责以5个并发共计运行25个Task。

## 2.5 DataX 3.0六大核心优势

![img](https://ask.qcloudimg.com/http-save/yehe-7231576/da1b15d7c53cf606f935fba596f5464b.png?imageView2/2/w/1620)

# 三、dataX案例

## 3.1 案例1(stream—>stream)

datax使用插件式开发，官方参考文档如下:https://github.com/alibaba/DataX/blob/master/dataxPluginDev.md

描述:streaming reader—>streaming writer (官网例子)

```javascript
[root@hadoop01 home]# cd /usr/local/datax/
[root@hadoop01 datax]# vi ./job/first.json
内容如下:
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
运行job：
[root@hadoop01 datax]# python ./bin/datax.py ./job/first.json
运行结果如下:
```

![img](https://ask.qcloudimg.com/http-save/yehe-7231576/1c0d55dddebf228cf80ac255fabf4c7a.png?imageView2/2/w/1620)

…(省略很多)

![img](https://ask.qcloudimg.com/http-save/yehe-7231576/c444653734504228fae125105fd69205.png?imageView2/2/w/1620)

## 3.2 案例2(mysql—>hdfs)

描述:mysql reader----> hdfs writer

```javascript
[root@hadoop01 datax]# vi ./job/mysql2hdfs.json
内容如下:
{
    "job": {
        "content": [
            {
                "reader": {
                    "name": "mysqlreader",
                    "parameter": {
                        "column": [
                            "user_id",
                            "user_name",
                            "trade_time"
                         ],
                        "connection": [
                            {
                                "jdbcUrl": ["jdbc:mysql://master:3306/test"],
                                "table": ["user"]
                            }
                        ],
                        "password": "root",
                        "username": "root"
                    }
                },
                "writer": {
                    "name": "hdfswriter",
                    "parameter": {
                        "defaultFS":  "hdfs://hd/",
                         "hadoopConfig":{
                          "dfs.nameservices": "hd",
                          "dfs.ha.namenodes.hd": "n1,n2",
                          "dfs.namenode.rpc-address.hd.n1": "master:9000",
                          "dfs.namenode.rpc-address.hd.n2": "hdp01:9000",                               
                          "dfs.client.failover.proxy.provider.hd": 
           "org.apache.hadoop.hdfs.server.namenode.ha.ConfiguredFailoverProxyProvider"
                          },
                        "fileType": "orc",
                        "path": "/datax/mysql2hdfs/mytest",
                        "fileName": "m2h01",
                        "column":[
                            {
                                "name": "user_id",
                                "type": "BIGINT"
                            },
                             {
                                "name": "user_name",
                                "type": "string"
                            },
                            {
                                "name": "trade_time",
                                "type": "DATE"
                            }
                        ],
                        "writeMode": "nonConflict",
                        "fieldDelimiter": "\t",
                        "compress":"NONE"
                    }
                }
            }
        ],
        "setting": {
            "speed": {
                "channel": "1"
            }
        }
    }
}
注:
运行前，需提前创建好输出目录:
[root@hadoop01 datax]# hdfs dfs -mkdir -p /datax/mysql2hdfs/orcfull
运行job：
[root@hadoop01 datax]# python ./bin/datax.py ./job/mysql2hdfs.json
运行结果如下:
然后建表看一下 
 "fileType": "orc"
 "fieldDelimiter": "\t"
 文件类型是orc 
 create table orcfull(
 id bigint,
 name string 
 )
 row format delimited fields terminated by "\t"
 stored as orc
 location '/datax/mysql2hdfs/orcfull';
```

## 3.3 案例3(hdfs—>mysql)

描述:hdfs reader----> mysql writer

```javascript
[root@hadoop01 datax]# vi ./job/hdfs2mysql.json
内容如下:
{
    "job": {
        "content": [
            {
                "reader": {
                    "name": "hdfsreader",
                    "parameter": {
                        "path": "/datax/mysql2hdfs/mytest/*",
                        "defaultFS": "hdfs://hd/",
                         "hadoopConfig":{
                         "dfs.nameservices": "hd",
                         "dfs.ha.namenodes.hd": "n1,n2",
                         "dfs.namenode.rpc-address.hd.n1": "master:9000",
                         "dfs.namenode.rpc-address.hd.n2": "hdp01:9000",                             
                         "dfs.client.failover.proxy.provider.hd": "org.apache.hadoop.hdfs.server.namenode.ha.ConfiguredFailoverProxyProvider"
                         },
                        "column":[
                            {
                                "index": "0",
                                "type": "LONG"
                            },
                             {
                                "index": "1",
                                "type": "string"
                            },
                            {
                                "index": "2",
                                "type": "DATE"
                            }
                        ],
                        "fileType": "orc",
                        "encoding": "UTF-8",
                      "fieldDelimiter": ","
                    }
                },
                "writer": {
                    "name": "mysqlwriter",
                    "parameter": {
                        "column": [
                        "user_id",
                        "user_name",
                        "trade_time"
                         ],
                        "connection": [
                            {
                                "jdbcUrl": "jdbc:mysql://master:3306/test",
                                "table": ["user1"]
                            }
                        ],
                        "password": "root",
                        "username": "root"
                    }
                }
            }
        ],
        "setting": {
            "speed": {
                "channel": "1"
            }
        }
    }
}
注:
运行前，需提前创建好输出的stu1表:
CREATE TABLE `stu1` (
  'user_id' int(11) DEFAULT NULL,
  'user_name' varchar(32) DEFAULT NULL
  'trade_time' varchar(32) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

运行job：
[root@hadoop01 datax]# python ./bin/datax.py ./job/hdfs2mysql.json
运行结果如下:
```

![img](https://ask.qcloudimg.com/http-save/yehe-7231576/4e12b9aa1356c6eb1e1dcb0cde25049c.png?imageView2/2/w/1620)

![img](https://ask.qcloudimg.com/http-save/yehe-7231576/a392cb59ca11de21baa24795629e2dd5.png?imageView2/2/w/1620)

注意，列的类型，如果名称或者类型不对会有错误，我这儿采用所有列读写。