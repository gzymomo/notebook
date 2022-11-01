- [HBase基础【优化、整合Phoenix（Phoenix简介、安装、shell、JDBC操作、二级索引）、整合hive】 - 掘金 (juejin.cn)](https://juejin.cn/post/7121311922628067342)

# 一 HBase优化

## 1 预分区

每一个region维护着startRow与endRowKey，如果加入的数据符合某个region维护的rowKey范围，则该数据交给这个region维护。那么依照这个原则，我们可以将数据所要投放的分区提前大致的规划好，以提高HBase性能。

### （1）手动设定预分区

```javascript
create 'staff1','info',SPLITS => ['1000','2000','3000','4000']
```

### （2）生成16进制序列预分区

```javascript
create 'staff2','info',{NUMREGIONS => 15, SPLITALGO => 'HexStringSplit'}
```

### （3） 按照文件中设置的规定预分区

```shell
#创建splits.txt文件内容如下：
aaaa
bbbb
cccc
dddd
#然后执行：
create 'staff3','info',SPLITS_FILE => 'splits.txt'
```

### （4）使用JavaAPI创建预分区

```java
//自定义算法，产生一系列Hash散列值存储在二维数组中
byte[][] splitKeys = 某个散列值函数
//创建HbaseAdmin实例
HBaseAdmin hAdmin = new HBaseAdmin(HbaseConfiguration.create());
//创建HTableDescriptor实例
HTableDescriptor tableDesc = new HTableDescriptor(tableName);
//通过HTableDescriptor实例和散列值二维数组创建带有预分区的Hbase表
hAdmin.createTable(tableDesc, splitKeys);
```

单独考虑预分区没有任何意义，需要结合下一小节RowKey的设计综合考虑

## 2 RowKey设计

一条数据的唯一标识就是rowkey，那么这条数据存储于哪个分区，取决于rowkey处于哪个一个预分区的区间内，设计rowkey的主要目的 ，就是让数据均匀的分布于所有的region中，在一定程度上防止数据倾斜。

rowkey设计 + 预分区 的原则: 唯一性 散列性 长度

**场景：**大量的运营商的通话数据，数据格式如下

```scss
  1388888888(主叫) 13999999999(被叫) 2022-05-14 12:12:12 360 ......
```

**业务:：**查询某个用户某天，某月，某年的通话记录

**预分区:** 预计规划50个分区 .

-∞| ~ 00|
 00| ~ 01|
 01| ~ 02 |
 …

**分析:** 假如将某个用户某天的数据存到一个分区中。查某天的数据只需要扫描一个分区
 假如将某个用户某月的数据存到一个分区中。查某天，某月的数据只需要扫描一个分区. √

rowkey: 01_1388888888_2021-05-14 12:12:12 -> 1388888888_2021-05 % 分区数 = 01（通过月份对分区数取余，此例中分区数不确定）
 01_1388888888_2021-05-15 12:12:12 -> 1388888888_2021-05 % 分区数 = 01
 01_1388888888_2021-05-16 12:12:12
 01_1388888888_2021-05-17 12:12:12

 03_1377777777_2021-05-16 12:12:12 -> 1377777777_2021-05 % 分区数 = 03

**验证:**

**例一：**查询 1388888888 用户 2020年08月的通话记录
 ① 先计算分区号
 1388888888_2020-08 % 50 = 04
 ② rowkey
 04_1388888888_2020-08-…
 ③ scan

```dart
 scan "teldata" ,{STARTROW=> '04_1388888888_2020-08' STOPROW=> '04_1388888888_2020-08|'}
```

**例二：**查询 1388888888 用户 2020年08月08日的通话记录
 ① 先计算分区号
 1388888888_2020-08 % 50 = 04
 ② rowkey
 04_1388888888_2020-08-08…
 ③ scan

```dart
scan "teldata" ,{STARTROW=> '04_1388888888_2020-08-08' STOPROW=> '04_1388888888_2020-08-08|'}
```

**例三：**查询 1388888888 用户 2020年08月 和 09月的通话记录

① 先计算分区号
 1388888888_2020-08 % 50 = 04
 1388888888_2020-09 % 50 = 06
 ② rowkey
 04_1388888888_2020-08-…
 06_1388888888_2020-09-…
 ③ scan

```dart
scan "teldata" ,{STARTROW=> '04_1388888888_2020-08' STOPROW=> '04_1388888888_2020-08|'}
scan "teldata" ,{STARTROW=> '06_1388888888_2020-09' STOPROW=> '06_1388888888_2020-09|'}
```

**例四：**查询 1388888888 用户 2020年08月09日 和 10日的通话记录

① 先计算分区号
 1388888888_2020-08 % 50 = 04
 ② rowkey
 04_1388888888_2020-08-09…
 04_1388888888_2020-08-09…
 04_1388888888_2020-08-10…
 ③ scan

```dart
scan "teldata" ,{STARTROW=> '04_1388888888_2020-08-09' STOPROW=> '04_1388888888_2020-08-10|'}
```

## 3 内存优化

HBase操作过程中需要大量的内存开销，毕竟Table是可以缓存在内存中的，但是不建议分配非常大的堆内存，因为GC过程持续太久会导致RegionServer处于长期不可用状态，一般16~36G内存就可以了，如果因为框架占用内存过高导致系统内存不足，框架一样会被系统服务拖死。

## 4 基础优化

hbase-site.xml

（1）Zookeeper会话超时时间

```
属性：zookeeper.session.timeout
解释：默认值为90000毫秒（90s）。当某个RegionServer挂掉，90s之后Master才能察觉到。可适当减小此值，以加快Master响应，可调整至60000毫秒。
```

（2）设置RPC监听数量

```
属性：hbase.regionserver.handler.count
解释：默认值为30，用于指定RPC监听的数量，可以根据客户端的请求数进行调整，读写请求较多时，增加此值。
```

（3）手动控制Major Compaction

```
属性：hbase.hregion.majorcompaction
解释：默认值：604800000秒（7天）， Major Compaction的周期，若关闭自动Major Compaction，可将其设为0
```

（4）优化HStore文件大小

```arduino
属性：hbase.hregion.max.filesize
解释：默认值10737418240（10GB），如果需要运行HBase的MR任务，可以减小此值，因为一个region对应一个map任务，如果单个region过大，会导致map任务执行时间过长。该值的意思就是，如果HFile的大小达到这个数值，则这个region会被切分为两个Hfile。
```

（5）优化HBase客户端缓存

```arduino
属性：hbase.client.write.buffer
解释：默认值2097152bytes（2M）用于指定HBase客户端缓存，增大该值可以减少RPC调用次数，但是会消耗更多内存，反之会消耗更小的内存。一般我们需要设定一定的缓存大小，以达到减少RPC次数的目的。
```

（6）指定scan.next扫描HBase所获取的行数

```lua
属性：hbase.client.scanner.caching
解释：用于指定scan.next方法获取的默认行数，值越大，消耗内存越大。
```

（7）BlockCache占用RegionServer堆内存的比例

```arduino
属性：hfile.block.cache.size
解释：默认0.4，读请求比较多的情况下，可适当调大
```

（8）MemStore占用RegionServer堆内存的比例

```matlab
属性：hbase.regionserver.global.memstore.size
解释：默认0.4，写请求较多的情况下，可适当调大
```

# 二 整合Phoenix

官方网站：[phoenix.apache.org/](https://link.juejin.cn?target=http%3A%2F%2Fphoenix.apache.org%2F)

## 1 Phoenix简介

### （1）定义

Phoenix是HBase的开源SQL皮肤。可以使用标准JDBC API代替HBase客户端API来创建表，插入数据和查询HBase数据。可以将Phoenix理解为客户端，也可以理解为一个数据库。

### （2）特点

容易集成：如Spark，Hive，Pig，Flume和Map Reduce；

操作简单：DML命令以及通过DDL命令创建和操作表和版本化增量更改；

支持HBase二级索引创建。

### （3）架构

![在这里插入图片描述](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/1e0a19dbc396467aa7d274ed0832377e~tplv-k3u1fbpfcp-zoom-in-crop-mark:4536:0:0:0.image)

thin client 通过Query Server服务将sql语句转化成Nosql语句，再将结果返回给thin client。

## 2 快速入门

### （1）Phoenix安装

```shell
#准备安装包，上传服务器，解压
tar -zxvf apache-phoenix-5.0.0-HBase-2.0-bin.tar.gz -C /opt/module/
mv apache-phoenix-5.0.0-HBase-2.0-bin phoenix-5.0.0
#配置环境变量

#PHOENIX_HOME
export PHOENIX_HOME=/opt/module/phoenix-5.0.0
#框架的相关jar包和类在什么地方（Phoenix比较特殊，jar包都在安装目录下，而不是在lib目录）
export PHOENIX_CLASSPATH=$PHOENIX_HOME
export PATH=$PATH:$PHOENIX_HOME/bin

#sqlline能tab出来说明环境变量配置没有问题
#复制server包并拷贝到各个节点的hbase/lib
cp /opt/module/phoenix/phoenix-5.0.0-HBase-2.0-server.jar /opt/module/hbase/lib/
xsync /opt/module/hbase/lib/phoenix-5.0.0-HBase-2.0-server.jar

#重启hbase
stop-hbase.sh
start-hbase.sh
#连接Phoenix
/opt/module/phoenix/bin/sqlline.py
#！tab可以查看命令
!quit

#正常连接方式，加上zookeeper地址
#thick client
sqlline.py hadoop101,hadoop102,hadoop103:2181
#thin clien
queryserver.py start
sqlline-thin.py hadoop101:8765
```

### （2）Phoenix shell 操作

默认情况下，在phoenix中不能直接创建schema。需要将如下的参数添加到Hbase中conf目录下的hbase-site.xml 和 phoenix中bin目录下的 hbase-site.xml中

```xml
<property>
    <name>phoenix.schema.isNamespaceMappingEnabled</name>
    <value>true</value>
</property>
```

注意分发hbase的配置文件，重启hbase，queryserver.py

#### ①增删改查创销

```shell
sqlline.py

#1.创建schema（databases）
create schema if not exists mydb;
#创建成功后，在hbase中查看（大写的MYDB）
list_namespace
#注意:在phoenix中，schema名，表名，字段名等会自动转换为大写，
#若要小写，使用双引号，如"student"。
create schema if not exists "mydb3";

#2.删除schema
drop schema if exists "mydb3";

#3.创建表（必须指定一个主键，为了对应HBase中的RowKey）
create table if not exists student(
id varchar primary key,
name varchar,
addr varchar);
#查看表
!tables 
desc 'STUDENT'  #列族通过0,1,2等去指定

#4.插入/修改数据(update + insert)
upsert into student(id,name,addr) values('1001','zhangsan','beijin');
upsert into student(id,name,addr) values('1002','lisi','shanghai');
upsert into student(id,name,addr) values('1002','lixiaosi','tianjin');

#5.查询数据
select id,name,addr from student;
scan 'STUDENT'
# column=0:\x00\x00\x00\x00, timestamp=1655733040679, value=x 
# column=0:\x80\x0B
# column=0:\x80\x0C
###以上column显示的数值为Phoenix为了更好的在hbase底层存储做的一些优化（自动编码），节省存储空间
###value=x为hbase随便维护的一条数据，因为在hbase中如果有rowkey，则一定有一条数据，而在Phoenix中主键外的其他列允许没有值，为避免这种情况，hbase用value=x进行维护，意义就是在Phoenix中有这么一条数据：只有主键，其他列没有值（null）
scan 'STUDENT',{RAW=>true,VERSIONS=>5}

#6.删除数据
delete from student where id = '1002';
```

#### ②联合主键

```shell
CREATE TABLE IF NOT EXISTS us_population (
State CHAR(2) NOT NULL,
City VARCHAR NOT NULL,
Population BIGINT
CONSTRAINT my_pk PRIMARY KEY (state, city));

upsert into us_population values('NY','New York',8143197) ;
upsert into us_population values('CA','Los Angeles',3844829) ;
#value=\x80\x00\x00\x00\x00:\xAA\xDD
#\x80\x00\x00\x00\x00|A]
```

#### ③表的映射

```shell
#1) Hbase中没有表,phoenix中创建表会同时在hbase中也创建表
#2) Hbase中有表, 可以在phoenix中创建视图(只读)进行映射
###在hbase命令行中执行以下操作
create 'emp','info'
put 'emp','1001','info:name','zhangsan'
put 'emp','1001','info:addr','beijing'
###在Phoenix中执行以下操作
create view "emp"(
  id varchar primary key,
  "info"."name" varchar,
  "info"."addr" varchar
);
select * from "emp";
select id,"name","addr" from "emp";
drop view "emp";
#3) Hbase中有表, 可以在phoenix中创建表进行映射
create table "emp"(
  id varchar primary key,
  "info"."name" varchar,
  "info"."addr" varchar
);
select * from "emp";  #无数据，因为查询的是name和addr经过编码之后的数据，但在hbase中并没有进行编码，想查询数据需要在建表语句下添加COLUMN_ENCODED_BYTES=NONE
drop table "emp"; #因为已经和hbase中的表映射成功了，所以也会删除hbase中的表
create table "emp"(
  id varchar primary key,
  "info"."name" varchar,
  "info"."addr" varchar
)
COLUMN_ENCODED_BYTES=NONE;
```

#### ④数值问题

```SHELL
#    phoenix存,	phoenix查。	没有问题
#    phoenix存,	hbase查。		有问题
#    hbase存,	hbase查。		没有问题
#    hbase存,	phoenix查。	有问题
create table test(
  id varchar primary key,
  name varchar,
  salary integer
)
COLUMN_ENCODED_BYTES=NONE;

upsert into test values('1001','zs',123456);
scan 'TEST'  #salary列不是数字
scan 'TEST',{COLUMNS => ['0:SALARY:toInt']}  #数值出现问题
delete from test where id = '1001';

put 'TEST','1002','0:NAME','ls'
put 'TEST','1002','0:SALARY',Bytes.toBytes(456789)   #Long
scan 'TEST',{COLUMNS => ['0:SALARY:toLong']}  #没有问题
#使用无符号整数
create table test1 (
   id varchar primary key , 
   name varchar ,
   salary UNSIGNED_INT 
 )
 COLUMN_ENCODED_BYTES = NONE;  

  upsert into test1 values('1001','zs',123456); 

  put 'TEST1','1002','0:NAME','ls'
  put 'TEST1','1002','0:SALARY',Bytes.toBytes(456789)   // Long 
```

### （3）Phoenix JDBC操作

#### ①Thin Client

```sql
启动客户端
queryserver.py startqueryserver.py start

创建项目，导入依赖
    <dependencies>
        <dependency>
            <groupId>org.apache.phoenix</groupId>
            <artifactId>phoenix-queryserver-client</artifactId>
            <version>5.0.0-HBase-2.0</version>
        </dependency>
    </dependencies>

/**
* JDBC编码步骤：注册驱动 获取连接 编写SQL 预编译 设置参数 执行SQL 封装结果 关闭连接 
*/
public class PhoenixTest {
	public static void main(String[] args) throws SQLException {

        String connectionUrl = ThinClientUtil.getConnectionUrl("hadoop101", 8765);
        //获取连接
        Connection connection = DriverManager.getConnection(connectionUrl);
        //编写SQL，预编译
        PreparedStatement preparedStatement = connection.prepareStatement("select * from student");
		//执行SQL
        ResultSet resultSet = preparedStatement.executeQuery();
		//封装结果
        while (resultSet.next()) {
            System.out.println(resultSet.getString("id") 
                               + ":" + resultSet.getString("name"));
           					   + ":" + resultSet.getString("addr"));
        }
        //关闭连接
        connection.close();
    }
}
```

#### ②Thick Client

```xml
<dependencies>
    <dependency>
        <groupId>org.apache.phoenix</groupId>
        <artifactId>phoenix-core</artifactId>
        <version>5.0.0-HBase-2.0</version>
        <exclusions>
            <exclusion>
                <groupId>org.glassfish</groupId>
                <artifactId>javax.el</artifactId>
            </exclusion>
        </exclusions>
    </dependency>

    <dependency>
        <groupId>org.glassfish</groupId>
        <artifactId>javax.el</artifactId>
        <version>3.0.1-b06</version>
    </dependency>
</dependencies>
```

```java
public class TestThick {

    public static void main(String[] args) throws SQLException {
        String url = "jdbc:phoenix:hadoop101,hadoop102,hadoop103:2181";
        Properties props = new Properties();
        props.put("phoenix.schema.isNamespaceMappingEnabled","true");
        Connection connection = DriverManager.getConnection(url,props);
        PreparedStatement ps = connection.prepareStatement("select * from \"test\"");
        ResultSet rs = ps.executeQuery();
        while(rs.next()){
            System.out.println(rs.getString(1)+":" +rs.getString(2));
        }
    }
}
```

## 3 Phoenix二级索引

Phoenix底层是hbase，hbase的一级索引是rowkey。

（1）配置文件

```shell
#添加如下配置到HBase的HRegionserver节点的hbase-site.xml
<!-- phoenix regionserver 配置参数-->
    <property>
        <name>hbase.regionserver.wal.codec</name>
        <value>org.apache.hadoop.hbase.regionserver.wal.IndexedWALEditCodec</value>
    </property>

    <property>
        <name>hbase.region.server.rpc.scheduler.factory.class</name>
        <value>org.apache.hadoop.hbase.ipc.PhoenixRpcSchedulerFactory</value>
        <description>Factory to create the Phoenix RPC Scheduler that uses separate queues for index and metadata updates</description>
    </property>

    <property>
        <name>hbase.rpc.controllerfactory.class</name>
        <value>org.apache.hadoop.hbase.ipc.controller.ServerRpcControllerFactory</value>
        <description>Factory to create the Phoenix RPC Scheduler that uses separate queues for index and metadata updates</description>
    </property>


cd /opt/module/hbase-2.0.5/conf/
xsync hbase-site.xml 
```

### （1）全局二级索引

所谓的全局二级索引，意味着建索引会创建一张索引表。

在索引表中， 将索引列与原表中的rowkey组合起来作为索引表的rowkey。

```sql
  explain select id from student ;   // FULL SCAN
  explain select id from student where id = '1002' ;  //  POINT LOOKUP，直接定位
  explain select id from student where name = 'lixiaosi' ; // FULL SCAN

  给name字段建索引
  create index idx_student_name on student(name); 
  
  explain select id from student where name = 'lixiaosi' ; // RANGE SCAN
  explain select id ,name from student where id ='1001' ;  // POINT LOOKUP
  explain select id ,name from student where name  ='lixiaosi' ; //RANGE SCAN，范围查找
  explain select id ,name ,addr  from student where name  ='lixiaosi' ; //FULL SCAN

  给name addr 建复合索引
  drop index idx_student_name on student; 

  create index idx_student_name on student(name,addr); 
 
  explain select id ,name ,addr from student where name ='lixiaosi' ; //RANGE SCAN
  explain select id ,name ,addr from student where name ='lixiaosi' and addr = 'beijing'; //RANGE SCAN
  explain select id ,name ,addr from student where addr = 'beijing'; //FULL SCAN，要先经过name过滤
  explain select id ,name ,addr from student where addr = 'beijing' and name ='lixiaosi' ;//RANGE SCAN，Phoenix将此条语句进行了优化

  给name列建索引包含addr列，以后不使用addr进行过滤，只需要查找addr

  drop index idx_student_name on student; 

  create index idx_student_name on student(name) include(addr);

  explain select id ,name ,addr  from student where name  ='lixiaosi' ; //RANGE SCAN
```

### （2）本地二级索引

hbase中没有索引表，在原表上进行一些修改。

```sql
  drop index idx_student_name on student; 

  create local index idx_student_name on student(name); 

  explain select id ,name ,addr  from student where name  ='lixiaosi' ; //RANGE SCAN
```

# 三 hive与HBase集成

在hive-site.xml中添加zookeeper的属性，如下：

```xml
<property>
    <name>hive.zookeeper.quorum</name>
    <value>hadoop101,hadoop102,hadoop103</value>
</property>

<property>
    <name>hive.zookeeper.client.port</name>
    <value>2181</value>
</property>
```

## 1 在hive中建表，对应着在hbase中也建表

```sql
CREATE TABLE hive_hbase_emp_table(
empno int,
ename string,
job string,
mgr int,
hiredate string,
sal double,
comm double,
deptno int)
STORED BY 'org.apache.hadoop.hive.hbase.HBaseStorageHandler'
WITH SERDEPROPERTIES ("hbase.columns.mapping" = ":key,info:ename,info:job,info:mgr,info:hiredate,info:sal,info:comm,info:deptno")
TBLPROPERTIES ("hbase.table.name" = "hbase_emp_table");

#想向表中添加数据，先准备一个普通表
CREATE TABLE emp(
empno int,
ename string,
job string,
mgr int,
hiredate string,
sal double,
comm double,
deptno int)
row format delimited fields terminated by '\t';

load data local inpath '/opt/module/hive/datas/emp.txt' into table emp;
insert into hive_hbase_emp_table select * from emp;
```

## 2 Hbase中已经有表， hive建表进行关联

```sql
CREATE EXTERNAL TABLE relevance_hbase_emp(
empno int,
ename string,
job string,
mgr int,
hiredate string,
sal double,
comm double,
deptno int)
STORED BY 
'org.apache.hadoop.hive.hbase.HBaseStorageHandler'
WITH SERDEPROPERTIES ("hbase.columns.mapping" = 
":key,info:ename,info:job,info:mgr,info:hiredate,info:sal,info:comm,info:deptno") 
TBLPROPERTIES ("hbase.table.name" = "hbase_emp_table");
```