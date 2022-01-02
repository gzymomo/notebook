- [HBase平台建设实践](https://www.cnblogs.com/bigdata1024/p/15737957.html)

## 背景

由于公司业务场景的需要，我们需要开发HBase平台，主要需要以下功能:

- 建表管理
- 授权管理
- SDK实现
- 与公司内部系统打通

我们使用的HBase 版本：

HBase 1.2.0-cdh5.16.2

Hadoop: 2.6.0-cdh5.16.2

目前主要应用场景：

- 实时计算如商品、商家等维度表
- 去重逻辑
- 中间件服务等监控数据
- 用户画像

## 平台建设

### 建表管理

1.指定命名空间

HBase系统默认定义了两个缺省的namespace：

- hbase：系统内建表，包括namespace和meta表
- default：用户建表时未指定namespace的表都创建在此

我们需要根据业务组进行定义命名空间，方便维护管理

2.支持多集群,不同业务组根据需要选择相应集群

3.指定表名

4.指定列族

因为列族在创建表的时候是确定的，列名以列族作为前缀，按需可动态加入，如: cf:name, cf:age

cf 就是列族， name, age 就是列名

5.设置生存时间TTL

一旦达到过期时间，HBase将自动删除行

6.支持预分区

HBase默认建表时有一个region，这个region的rowkey是没有边界的，即没有startkey和endkey，在数据写入时，所有数据都会写入这个默认的region，随着数据量的不断增加，此region已经不能承受不断增长的数据量，会进行split，分成2个region。在此过程中，会产生两个问题：

1. 数据往一个region上写,会有写热点问题。
2. region split会消耗宝贵的集群I/O资源。

基于此可以控制在建表的时候，创建多个空region，并确定每个region的起始和终止rowkey，这样只要我们的rowkey设计能均匀的命中各个region，就不会存在写热点问题。自然split的几率也会大大降低。当然随着数据量的不断增长，该split的还是要进行split。像这样预先创建hbase表分区的方式，称之为预分区.

预分区的实现，**参考HBase的shell脚本实现**.

相关代码:

```
Configuration configuration = conn.getConfiguration();
RegionSplitter.SplitAlgorithm hexStringSplit = RegionSplitter.newSplitAlgoInstance(configuration, splitaLgo);
splits = hexStringSplit.split(numRegions);
```

指定分割算法以及预分区的数目

分割算法主要三种:

- HexStringSplit: rowkey是十六进制的字符串作为前缀的
- DecimalStringSplit: rowkey是10进制数字字符串作为前缀的
- UniformSplit: rowkey前缀完全随机

其他配置：

```
   HColumnDescriptor hColumnDescriptor = new HColumnDescriptor(cf);
   //指定版本,设置成一个即可
   hColumnDescriptor.setMaxVersions(1);
   //指定列族过期时间,界面配置最小单位天，HBase TTL时间单位为秒
   Long ttl = TimeUnit.DAYS.toSeconds(expireDays);
   hColumnDescriptor.setTimeToLive(ttl.intValue());
   //启用压缩算法
   hColumnDescriptor.setCompressionType(Compression.Algorithm.SNAPPY);
   //进行compaction的时候使用压缩算法
   hColumnDescriptor.setCompactionCompressionType(Compression.Algorithm.SNAPPY);
   //让数据块缓存在LRU缓存里面有更高的优先级
   hColumnDescriptor.setInMemory(true);
   //bloom过滤器，过滤加速
   hColumnDescriptor.setBloomFilterType(BloomType.ROW);
   descriptor.addFamily(hColumnDescriptor);
```

最终调用 `admin.createTable`进行建表

建表的时候，注意要检测命名空间存在，不存在进行创建命名空间，还有建表的时候自动给相应的业务组进行授权。

表结构查看、数据预览、表删除等功能通过HBase java API 就可以实现， 这里不介绍了.

### 授权管理

先说HBase如何实现鉴权？

我们采用HBase ACL 鉴权机制，具体配置如下：

```
<property>
      <name>hbase.superuser</name>
      <value>admin</value>
</property>
<property>
    <name>hbase.coprocessor.region.classes</name>    
    <value>org.apache.hadoop.hbase.security.access.AccessController</value> 
</property>
  <property>
    <name>hbase.coprocessor.master.classes</name>
    <value>org.apache.hadoop.hbase.security.access.AccessController</value>
  </property>
 <property>
      <name>hbase.security.authorization</name>
      <value>true</value>
  </property>
```

给其他业务组授权都采用超级账户进行

下面是权限对照表：

[![img](https://s4.ax1x.com/2021/12/27/TBvHoD.png)](https://s4.ax1x.com/2021/12/27/TBvHoD.png)

授权流程：

[![img](https://s4.ax1x.com/2021/12/27/TDp6XR.png)](https://s4.ax1x.com/2021/12/27/TDp6XR.png)

用户如何进行HBase操作以及平台如何进行认证和鉴权?

我们开发了一个很简单的SDK

### SDK 实现

SDK 主要的功能就是进行认证和授权、以及获取相关集群的连接信息的操作。

整体流程:

[![img](https://s4.ax1x.com/2021/12/27/TDEAsg.png)](https://s4.ax1x.com/2021/12/27/TDEAsg.png)

### 与公司内部系统打通

主要工作就是开发平台使用HBase任务如何打通认证鉴权等，因为都是基于业务组提交任务，所以很容易实现满足需求

针对外部服务在容器内使用HBase,  在主机名没有做DNS 正反向解析之前，需要在容器内配置hosts。

## 集群数据迁移

主要场景是我们需要将老集群的数据迁移到新集群，要实现跨集群迁移。

老集群版本： HBase: 1.2.0-cdh5.12.0 Hadoop: 2.6.0-cdh5.12.0

新集群版本： HBase: 1.2.0-cdh5.16.2 Hadoop: 2.6.0-cdh5.16.2

使用Distcp方案来进行，一般选择业务低峰期去做, ，需要保证HBase集群中的表是静态数据，需要停止业务表的写入

### 具体步骤

(1) 在新集群中HDFS 用户下执行distcp命令

**在新集群的NameNode节点执行命令**

```
hadoop distcp -Dmapreduce.job.queue.name=default -pug -update -skipcrccheck -m 100 hdfs://ip:8020/hbase/data/aaa/user_test /hbase/data/aaa/user_test
```

(2) 执行HBase命令来修复HBase表的元数据，如表名、表结构等内容，会重新注册到新集群的Zookeeper中。

```
sudo -u admin  hbase hbck -fixMeta  "aaa:user_test"

sudo -u admin hbase hbck -fixAssignments "aaa:user_test"
```

(3）验证数据：

```
scan 'aaa:user_test' ,{LIMIT=>10}
```

(4) 旧集群表删除：

```
#!/bin/bash 
exec sudo -u admin  hbase shell <<EOF 
disable 'aaa:user_test'
drop 'aaa:user_test' 
EOF
```

为了迁移方便，可以将上述命令封装成一个Shell脚本,如:

```
#! /bin/bash
for i in `cat /home/hadoop/hbase/tbl`
do
echo $i
hadoop distcp -Dmapreduce.job.queue.name=queue_0001_01 -update -skipcrccheck -m 100 hdfs://old_hbase:9000/hbase/data/$i /hbase/data/$i
done
hbase hbck -repairHoles
```

## 总结

本文主要对HBase平台建设的实践总结,主要包括创建HBase表相关属性配置的实现,以及认证鉴权的多租户设计思路介绍,同时对HBase跨集群表元信息及数据迁移实践进行总结.