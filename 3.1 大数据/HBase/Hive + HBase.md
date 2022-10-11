- [Hive + HBase](https://blog.51cto.com/simplelife/2483754)

# HBase 和 Hive 的差别是什么，各自适用在什么场景中？

**Hbase主要解决实时数据查询问题，Hive主要解决数据处理和计算问题，一般是配合使用。**

**一、区别：**

1. Hbase： Hadoop database 的简称，也就是基于Hadoop数据库，是一种NoSQL数据库，主要适用于海量明细数据（十亿、百亿）的随机实时查询，如日志明细、[交易清单](https://www.zhihu.com/search?q=交易清单&search_source=Entity&hybrid_search_source=Entity&hybrid_search_extra={"sourceType"%3A"answer"%2C"sourceId"%3A185664626})、轨迹行为等。
2. Hive：Hive是Hadoop数据仓库，严格来说，不是数据库，主要是让开发人员能够通过SQL来计算和处理HDFS上的结构化数据，适用于离线的[批量数据计算](https://www.zhihu.com/search?q=批量数据计算&search_source=Entity&hybrid_search_source=Entity&hybrid_search_extra={"sourceType"%3A"answer"%2C"sourceId"%3A185664626})。

- 通过元数据来描述Hdfs上的[结构化文本](https://www.zhihu.com/search?q=结构化文本&search_source=Entity&hybrid_search_source=Entity&hybrid_search_extra={"sourceType"%3A"answer"%2C"sourceId"%3A185664626})数据，通俗点来说，就是定义一张表来描述HDFS上的结构化文本，包括各列数据名称，数据类型是什么等，方便我们处理数据，当前很多SQL ON Hadoop的计算引擎均用的是hive的元数据，如Spark SQL、Impala等；
- 基于第一点，通过SQL来处理和计算HDFS的数据，Hive会将SQL翻译为Mapreduce来处理数据；

**二、关系**

在大数据架构中，Hive和HBase是协作关系，数据流一般如下图：

1. 通过ETL工具将数据源抽取到HDFS存储；
2. 通过Hive清洗、处理和计算原始数据；
3. HIve清洗处理后的结果，如果是面向海量数据随机查询场景的可存入Hbase
4. 数据应用从HBase查询数据；

![img](https://pic1.zhimg.com/80/v2-2fbb6391206db40675afa8617806a8be_720w.webp?source=1940ef5c)

## Hive整合HBase：数据实时写Hbase,实现在Hive中用sql查询

```
以下操作的 Hive版本：2.3.6 ,HBase版本：2.0.4
```

- 在HBase中创建表：t_hbase_stu_info

  ```mysql
  create 't_hbase_stu_info','st1'
  ```

- 在Hive中创建外部表：t_hive_stu_info

  ```mysql
  create external table t_hive_stu_info
  (id int,name string,age int,sex string)
  stored by 'org.apache.hadoop.hive.hbase.HBaseStorageHandler'
  with serdeproperties("hbase.columns.mapping"=":key,st1:name,st1:age,st1:sex")
  tblproperties("hbase.table.name"="t_hbase_stu_info");
  ```

- 在Hbase中给t_hbase_stu_info插入数据

  ```mysql
  put 't_hbase_stu_info','1001','st1:name','zs'
  put 't_hbase_stu_info','1001','st1:age','23'
  put 't_hbase_stu_info','1001','st1:sex','man'
  put 't_hbase_stu_info','1002','st1:name','ls'
  put 't_hbase_stu_info','1002','st1:age','56'
  put 't_hbase_stu_info','1002','st1:sex','woman'
  ```

- 查看Hbase中的数据

  ```mysql
  scan 't_hbase_stu_info'
  ```

  ![Hive + HBase，用HQL查询HBase](https://s4.51cto.com/images/blog/202003/31/df6437327459698a44a19d60c31b4572.png?x-oss-process=image/watermark,size_16,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_90,type_ZmFuZ3poZW5naGVpdGk=)

1. 查看Hive中的数据

   ```mysql
   select * from t_hive_stu_info;
   ```

   ![Hive + HBase，用HQL查询HBase](https://s4.51cto.com/images/blog/202003/31/f604b10a7c6bd29a2ff5f3e0a39d5b16.png?x-oss-process=image/watermark,size_16,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_90,type_ZmFuZ3poZW5naGVpdGk=)