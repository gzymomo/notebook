- [Hive3.X高可用部署_WAIT_TIME的博客-CSDN博客_hive高可用部署](https://blog.csdn.net/wangshui898/article/details/120608564)

# 一、部署规划

[hadoop](https://so.csdn.net/so/search?q=hadoop&spm=1001.2101.3001.7020)高可用集群部署参考: [Hadoop3.X分布式高可用集群部署](https://blog.csdn.net/wangshui898/article/details/120522898)

## 1.1 版本说明

| 软件     | 版本                                 |
| -------- | ------------------------------------ |
| 操作系统 | CentOS Linux release 7.8.2003 (Core) |
| JAVA     | jdk-8u271-linux-x64                  |
| Hadoop   | hadoop-3.2.2                         |
| Hive     | hive-3.1.2                           |

## 1.2 集群规划

- hive远程模式 && hiveserver2高可用

| hostname     | IP            | 组件      |          |          |            |                |
| ------------ | ------------- | --------- | -------- | -------- | ---------- | -------------- |
| master       | 172.16.20.200 |           | NameNode |          |            | hive-metastore |
| secondmaster | 172.16.20.201 |           | NameNode |          |            | hive-metastore |
| slave1       | 172.16.20.202 | Zookeeper |          | DataNode | NodeManage | hiveserver2    |
| slave2       | 172.16.20.203 | Zookeeper |          | DataNode | NodeManage | hiveserver2    |
| slave3       | 172.16.20.204 | Zookeeper |          | DataNode | NodeManage | mysql          |

## 1.3 hive存储概念

1. **Hive用户接口：**
   命令行接口（CLI）:以命令行的形式输入SQL语句进行数据数据操作
   Web界面：通过Web方式进行访问。　　　　　
   Hive的远程服务方式：通过JDBC等方式进行访问。
2. **元数据存储**
   将元数据存储在关系数据库中（MySql、Derby），元数据包括表的属性、表的名称、表的列、分区及其属性以及表数据所在的目录等。
3. **解释器、编译器、优化器**
   分别完成SQL查询语句从词法分析、语法分析、编译、优化以及查询计划的生成。生成的查询计划存储在HDFS中，并在随后由MapReduce调用执行。
4. **数据存储**
   Hive没有专门的数据存储格式，也没有为数据建立索引，Hive中所有数据都存储在HDFS中。Hive包含以下数据模型：表、外部表、分区和桶

## 1.4 Metadata，Metastore 的作用

1. Metadata概念：
   元数据包含用Hive创建的database、table等的元信息。元数据存储在关系型数据库中。如Derby、MySQL等。
2. Metastore作用：
   客户端连接metastore服务，metastore再去连接MySQL数据库来存取元数据。有了metastore服务，就可以有多个客户端同时连接，而且这些客户端不需要知道MySQL数据库的用户名和密码，只需要连接metastore 服务即可。

## 1.5 Hive的元数据存储(Metastore三种配置方式)

1. 内嵌模式（Embedded）
   hive服务和metastore服务运行在同一个进程中，derby服务也运行在该进程中.内嵌模式使用的是内嵌的Derby数据库来存储元数据，也不需要额外起Metastore服务。
   这个是默认的，配置简单，但是一次只能一个客户端连接，适用于用来实验，不适用于生产环境。
2. 本地模式（Local）:本地安装mysql 替代derby存储元数据
   - 不再使用内嵌的Derby作为元数据的存储介质，而是使用其他数据库比如MySQL来存储元数据。hive服务和metastore服务运行在同一个进程中，mysql是单独的进程，可以同一台机器，也可以在远程机器上。
   - 这种方式是一个多用户的模式，运行多个用户client连接到一个数据库中。这种方式一般作为公司内部同时使用Hive。每一个用户必须要有对MySQL的访问权利，即每一个客户端使用者需要知道MySQL的用户名和密码才行。
3. 远程模式（Remote）: 远程安装mysql 替代derby存储元数据
   - Hive服务和metastore在不同的进程内，可能是不同的机器，该模式需要将hive.metastore.local设置为false，将hive.metastore.uris设置为metastore服务器URL
   - 远程元存储需要单独起metastore服务，然后每个客户端都在配置文件里配置连接到该metastore服务。将metadata作为一个单独的服务进行启动。各种客户端通过beeline来连接，连接之前无需知道数据库的密码。
   - 仅连接远程的mysql并不能称之为“远程模式”，是否远程指的是metastore和hive服务是否在同一进程内.

# 二、MYSQL部署

- slave3 节点

## 下载解压

下载地址: https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-8.0.26-linux-glibc2.12-x86_64.tar.xz

```
tar -xf mysql-8.0.26-linux-glibc2.12-x86_64.tar.xz -C /usr/local/
ln -s /usr/local/mysql-8.0.26-linux-glibc2.12-x86_64 /usr/local/mysql
echo 'export PATH=/usr/local/mysql/bin:$PATH' >> /etc/profile
source /etc/profile

```

## 环境配置

```bash
## 创建用户
useradd mysql
## 创建目录
mkdir -pv /data/mysql/{data,logs,binlog}
chown mysql.mysql /data/mysql -R
```

## 创建配置文件

```conf
cat > /data/mysql/my.cnf << 'EOF'
[client]
port = 3306
socket = /data/mysql/mysqld.sock
default-character-set = utf8mb4

[mysql]
prompt="\u@mysqldb \R:\m:\s [\d]> "
no-auto-rehash
default-character-set = utf8mb4

[mysqld]
user = mysql
port = 3306
socket = /data/mysql/mysqld.sock
skip-name-resolve

# 设置字符编码
character-set-server = utf8
collation-server = utf8_general_ci

# 设置默认时区
#default-time_zone='+8:00'

server-id = 1

# Directory
basedir = /usr/local/mysql
datadir = /data/mysql/data
secure_file_priv = /data/mysql/
pid-file = /data/mysql/mysql.pid


max_connections       = 1024
max_connect_errors    = 100
wait_timeout          = 100
max_allowed_packet    = 128M
table_open_cache      = 2048
back_log              = 600

default-storage-engine = innodb
log_bin_trust_function_creators = 1

# Log
general_log=off
#general_log_file =  /data/mysql/logs/mysql.log
log-error = /data/mysql/logs/error.log

# binlog
log-bin = /data/mysql/binlog/mysql-binlog
binlog_format=mixed

#slowlog慢查询日志
slow_query_log = 1
slow_query_log_file = /data/mysql/logs/slow.log
long_query_time = 2
log_output = FILE
log_queries_not_using_indexes = 0

#global_buffers
innodb_buffer_pool_size = 2G
innodb_log_buffer_size = 16M
innodb_flush_log_at_trx_commit = 2
key_buffer_size = 64M

innodb_log_file_size = 512M
innodb_log_file_size = 2G
innodb_log_files_in_group = 2
innodb_data_file_path = ibdata1:20M:autoextend

sql_mode = STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION

[mysqldump]
quick
max_allowed_packet = 32M
EOF
ln -s /data/mysql/my.cnf /etc/my.cnf
```

## 初始化MYSQL

```bash
bin/mysqld --initialize --user=mysql --datadir=/data/mysql/data/ --basedir=/usr/local/mysql
```

## 启动MYSQL

```bash
cp support-files/mysql.server /etc/init.d/mysqld
chmod +x /etc/init.d/mysqld
```

2.6 登录MYSQL

```bash
## 查看mysql初始化密码
cat /data/mysql/logs/error.log |grep password|awk -F':' '{print $NF}'
5>G=3sJ6Cy2i

## 修改密码
mysqladmin -uroot -p'5>G=3sJ6Cy2i' password 123456

## 登录mysql
mysql -uroot -p123456
```

## Hive授权

```sql
create database hive;
create user "hive"@"%" identified by "Passw0rd";
grant all privileges on hive.* to "hive"@"%";
flush privileges;
```

> mysql解决时区问题
>
> ```sql
> select now();
> show variables like '%time_zone%';
> set gloable time_zone='+8:00';
> ```

# 二、Hive部署

- master节点操作

## 2.1 下载解压

下载地址: https://downloads.apache.org/hive/hive-3.1.2/apache-hive-3.1.2-bin.tar.gz

```bash
tar -zxf apache-hive-3.1.2-bin.tar.gz -C /opt/hadoop/
ln -s /opt/hadoop/apache-hive-3.1.2-bin /usr/local/hive
```

配置环境变量, /etc/profie下加入

```bash
cat >> /etc/profile << 'EOF'
#HIVE
HIVE_HOME=/usr/local/hive
PATH=$HIVE_HOME/bin:$PATH
export PATH HIVE_HOME

EOF
source /etc/profile
```

## 2.2 修改配置

```bash
cd $HIVE_HOME/conf
```

### hive-log4j2.properties

```bash
cp hive-log4j2.properties.template hive-log4j2.properties
```

### hive-env.sh

```bash
cat > hive-env.sh << 'EOF'
export HADOOP_HOME=/usr/local/hadoop
export HIVE_CONF_DIR=/usr/local/hive/conf
export HIVE_AUX_JARS_PATH=/usr/local/hive/lib
EOF
```

## 2.3 同步配置

```bash
rsync -av /opt/hadoop/apache-hive-3.1.2-bin root@sm:/opt/hadoop/
rsync -av /opt/hadoop/apache-hive-3.1.2-bin root@s1:/opt/hadoop/
rsync -av /opt/hadoop/apache-hive-3.1.2-bin root@s2:/opt/hadoop/
```

并在节点上创建软连接

```bash
ln -s /opt/hadoop/apache-hive-3.1.2-bin /usr/local/hive
```

## 2.4 metastore配置

- master和secondmaster节点操作

创建目录

```bash
hdfs dfs -mkdir -p /data/hive/{warehouse,tmp,logs}
hdfs dfs -chmod -R 775 /data/hive/

cd $HIVE_HOME/conf
```

### 2.4.1 metastore-site.xml

```xml
cat > metastore-site.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>

<configuration>
    <property>
      <name>hive.metastore.local</name>
      <value>true</value>
    </property>
    <!--Hive作业的HDFS根目录位置 -->
    <property>
      <name>hive.exec.scratchdir</name>
      <value>/data/hive/tmp</value>
    </property>
    <!--Hive作业的HDFS根目录创建写权限 -->
    <property>
      <name>hive.scratch.dir.permission</name>
      <value>775</value>
    </property>
    <!--hdfs上hive元数据存放位置 -->
    <property>
      <name>hive.metastore.warehouse.dir</name>
      <value>/data/hive/warehouse</value>
    </property>
    <!--连接数据库地址，名称 -->
    <property>
      <name>javax.jdo.option.ConnectionURL</name>
      <value>jdbc:mysql://slave3:3306/hive?createDatabaseIfNotExist=true</value>
    </property>
    <!--连接数据库驱动 -->
    <property>
      <name>javax.jdo.option.ConnectionDriverName</name>
      <value>com.mysql.cj.jdbc.Driver</value>
    </property>
    <!--连接数据库用户名称 -->
    <property>
      <name>javax.jdo.option.ConnectionUserName</name>
      <value>hive</value>
    </property>
    <!--连接数据库用户密码 -->
    <property>
      <name>javax.jdo.option.ConnectionPassword</name>
      <value>Passw0rd</value>
    </property>
    <!-- 指定metastore连接地址 -->
    <property>
      <name>hive.metastore.uris</name>
      <value>thrift://master:9083</value>
    </property>
</configuration>
EOF
```

> secondmaster配置相同, 注意修改hive.metastore.uris地址为thrift://secondmaster:9083

### 2.4.2 下载mysql驱动包

驱动地址: https://mvnrepository.com/artifact/mysql/mysql-connector-java

```
wget https://repo1.maven.org/maven2/mysql/mysql-connector-java/8.0.26/mysql-connector-java-8.0.26.jar -P $HIVE_HOME/lib/
```

### 2.4.3 初始化MYSQL

- 执行一次即可

```bash
$HIVE_HOME/bin/schematool -dbType mysql -initSchema
```

> 报错:
>
> ```
> Exception in thread "main" java.lang.NoSuchMethodError: com.google.common.base.Preconditions.checkArgument(ZLjava/lang/String;Ljava/lang/Object;)V
> ```
>
> guave版本不对, 解决方法, 删除低版本(hadoop或者hive), 复制高版本, 如下:
>
> ```bash
> ll $HIVE_HOME/lib/guava*; ll $HADOOP_HOME/share/hadoop/common/lib/guava*
> -rw-r--r-- 1 root root 2308517 Sep 27  2018 /usr/local/hive/lib/guava-19.0.jar
> -rw-r--r-- 1 1000 1000 2747878 Jan  3  2021 /usr/local/hadoop/share/hadoop/common/lib/guava-27.0-jre.jar
> 
> rm -f $HIVE_HOME/lib/guava-19.0.jar
> cp $HADOOP_HOME/share/hadoop/common/lib/guava-27.0-jre.jar $HIVE_HOME/lib/
> ```

### 2.4.4 启动metastore

```bash
mkdir -pv $HIVE_HOME/logs
nohup $HIVE_HOME/bin/hive --service metastore >> $HIVE_HOME/logs/metastore.log 2>&1 &
```

## 2.5 hiveserver2配置

- slave1和salve2节点操作相同

### 2.5.1 hiveserver2-site.xml

```xml
cat > hiveserver2-site.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>

<configuration>
    <property>
      <name>hive.metastore.uris</name>
      <value>thrift://master:9083,thrift://secondmaster:9083</value>
    </property>     
    <!--hiveserver2高可用-->
    <property>
      <name>hive.server2.support.dynamic.service.discovery</name>
      <value>true</value>
    </property>

    <property>
      <name>hive.server2.active.passive.ha.enable</name>
      <value>true</value>
    </property>
    
    <property>
      <name>hive.server2.zookeeper.namespace</name>
      <value>hiveserver2_zk</value>
    </property>

    <property>
      <name>hive.zookeeper.quorum</name>
      <value>slave1:2181,slave2:2181,slave3:2181</value>
    </property>
    
    <property>
      <name>hive.zookeeper.client.port</name>
      <value>2181</value>
    </property>
    
    <property>
      <name>hive.server2.thrift.port</name>
      <value>10001</value>
    </property>

    <!--填写节点, 如slave1,slave2-->
    <property>
      <name>hive.server2.thrift.bind.host</name>
      <value>slave1</value>
    </property>
</configuration>
EOF
```

> 注意修改hive.server2.thrift.bind.host为本机的hostname

### 2.5.2 修改hadoop配置

在core-site.xml中加入以下配置

```xml
<!-- 如果连接不上10001 -->
<property>     
    <name>hadoop.proxyuser.root.hosts</name>     
    <value>*</value>
</property> 
<property>     
    <name>hadoop.proxyuser.root.groups</name>    
    <value>*</value> 
</property>
```

> hadoop.proxyuser.xxx.hosts和hadoop.proxyuser.xxx.groups,其中xxx为启动HiveServer2的用户

如果不修改, 启动hiveserver2则会报错

```
WARN [main] metastore.RetryingMetaStoreClient: MetaStoreClient lost connection. Attempting to reconnect (1 of 1) after 1s. getCurrentNotificationEventId
org.apache.thrift.TApplicationException: Internal error processing get_current_notificationEventId
```

### 2.5.3 启动hiveserver2

启动hive

```bash
mkdir -pv $HIVE_HOME/logs
nohup $HIVE_HOME/bin/hive --service hiveserver2 >> $HIVE_HOME/logs/hiveserver2.log 2>&1 &
```

### 2.5.4 连接测试

```
$HIVE_HOME/bin/beeline -u jdbc:hive2://slave1:10001
$HIVE_HOME/bin/beeline -u jdbc:hive2://slave2:10001
```

### 2.5.5 ui界面

http://172.16.20.201:10002/

http://172.16.20.202:10002/

## 2.6 hive客户端配置

### hive-site.xml

```bash
cd $HIVE_HOME/conf

cat > hive-site.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>

<configuration>
    <property>
      <name>hive.metastore.uris</name>
      <value>thrift://master:9083,thrift://secondmaster:9083</value>
    </property> 
    <!-- 显示表的列名 -->
    <property>
      <name>hive.cli.print.header</name>
      <value>true</value>
    </property>
    <!-- 显示数据库名称 -->
    <property>
      <name>hive.cli.print.current.db</name>
      <value>true</value>
    </property>
</configuration>
EOF
```

> 解决guava版本不一致问题
>
> ```
> rm -f $HIVE_HOME/lib/guava-19.0.jar
> cp $HADOOP_HOME/share/hadoop/common/lib/guava-27.0-jre.jar $HIVE_HOME/lib/
> ```

### 启动客户端

```bash
$HIVE_HOME/bin/hive
```

### 连接测试

登录hive命令

```
$HIVE_HOME/bin/hive
```