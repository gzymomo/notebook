- [Hive集群部署__雪辉_的博客-CSDN博客_hive集群部署](https://blog.csdn.net/qq_42979842/article/details/107601055)

## 一、部署规划

### 1.1 版本说明

| 软硬件信息   | 参数                                 |
| ------------ | ------------------------------------ |
| 配置         | 2C2G                                 |
| 操作系统版本 | CentOS Linux release 7.7.1908 (Core) |
| java版本     | java version “1.8.0_251”             |
| Hadoop版本   | Hadoop 3.3.0                         |
| Hive版本     | Hive 3.1.2                           |

### 1.2 服务器规划

| 服务器 | IP             | 角色                                                         |
| ------ | -------------- | ------------------------------------------------------------ |
| node1  | 192.168.137.86 | zk、namenode、zkfc、datanode、nodemanager、journalnode、Hmaster、HRegionServer |
| node2  | 192.168.137.87 | zk、namenode、zkfc、datanode、nodemanager、resourcemanager、journalnode、Hmaster、HRegionServer |
| node3  | 192.168.137.88 | zk、datanode、nodemanager、resourcemanager、journalnode、HRegionServer、MySQL |

### 1.3 配置目录规划

| 软件            | 目录               |
| --------------- | ------------------ |
| MySQL数据目录   | /data/mysql/data   |
| MySQL日志目录   | /data/mysql/logs   |
| MySQLbinlog目录 | /data/mysql/binlog |

## 二、部署MySQL

### 3.1 创建MySQL用户组和用户

```bash
groupadd mysql
useradd -g mysql mysql -s /sbin/nologin
id mysql
```

### 3.2 配置目录

```bash
mkdir -pv /data/mysql/{data,logs,binlog,tmp,redo}
chown -R mysql:mysql /data/mysql/
```

### 2.3 解压安装包

```bash
mkdir /usr/local/mysql/program -pv
tar xf mysql-8.0.21-el7-x86_64.tar -C /usr/local/mysql/program/
cd /usr/local/mysql/program/
tar xf mysql-8.0.21-el7-x86_64.tar.gz
tar xf mysql-test-8.0.21-el7-x86_64.tar.gz
```

### 2.4 软链接程序目录并配置环境变量

```bash
ln -s /usr/local/mysql/program/mysql-8.0.21-el7-x86_64 /usr/local/mysql/program/mysqlserver
export PATH=/usr/local/mysql/program/mysqlserver/bin:$PATH
echo 'export PATH=/usr/local/mysql/program/mysqlserver/bin:$PATH' >> /etc/profile
source /etc/profile
```

### 2.5 修改配置文件

```bash
[client]
port    = 3306
socket  = /data/mysql/data/mysql.sock

[mysql]
prompt="\u@mysql \R:\m:\s [\d]> "
no-auto-rehash

[mysqld]
user=mysql
port=3306
default_authentication_plugin=mysql_native_password
basedir=/usr/local/mysql/mysqlserver
datadir=/data/mysql/data
tmpdir =/data/mysql/tmp
socket=/data/mysql/data/mysql.sock
innodb_doublewrite=1
pid-file=mysql.pid
character-set-server = utf8mb4
skip_name_resolve = 1
default_time_zone = "+8:00"
open_files_limit= 65535
back_log = 1024
max_connections = 256
max_user_connections = 64
max_connect_errors = 10000
autocommit = 1
table_open_cache = 1024
table_definition_cache = 1024
table_open_cache_instances = 4
thread_stack = 512K
external-locking = FALSE
max_allowed_packet = 32M
sort_buffer_size = 4M
join_buffer_size = 4M
innodb_sort_buffer_size = 64M
thread_cache_size = 384
interactive_timeout = 600
wait_timeout = 600
tmp_table_size = 32M
max_heap_table_size = 32M
slow_query_log = 1
log_timestamps = SYSTEM
slow_query_log_file = /data/mysql/logs/slow.log
log-error = /data/mysql/logs/error.log
long_query_time = 0.1
log_queries_not_using_indexes =1
log_throttle_queries_not_using_indexes = 60
min_examined_row_limit = 0
log_slow_admin_statements = 1
log_slow_slave_statements = 1
server-id = 33061
log-bin = /data/mysql/binlog/binlog
sync_binlog = 1
binlog_cache_size = 4M
max_binlog_cache_size = 2G
max_binlog_size = 1G
auto_increment_offset=1
auto_increment_increment=1
expire_logs_days = 7
master_info_repository = TABLE
relay_log_info_repository = TABLE
gtid_mode = on
enforce_gtid_consistency = 1
log_slave_updates
slave-rows-search-algorithms = 'INDEX_SCAN,HASH_SCAN'
binlog_format = row
relay_log = /data/mysql/binlog/relaylog
relay_log_recovery = 1
relay-log-purge = 1
key_buffer_size = 32M
read_buffer_size = 8M
read_rnd_buffer_size = 4M
bulk_insert_buffer_size = 64M
myisam_sort_buffer_size = 128M
myisam_max_sort_file_size = 10G
myisam_repair_threads = 1
lock_wait_timeout = 3600
explicit_defaults_for_timestamp = 1
innodb_thread_concurrency = 0
innodb_sync_spin_loops = 100
innodb_spin_wait_delay = 30
transaction_isolation = READ-COMMITTED
innodb_buffer_pool_size = 2048M
innodb_buffer_pool_instances = 2
innodb_buffer_pool_load_at_startup = 1
innodb_buffer_pool_dump_at_shutdown = 1
innodb_log_group_home_dir = /data/mysql/redo/
innodb_data_file_path = ibdata1:1G:autoextend
innodb_temp_data_file_path=ibtmp1:500M:autoextend
innodb_flush_log_at_trx_commit = 1
innodb_log_buffer_size = 32M
innodb_log_file_size = 2G
innodb_log_files_in_group = 2
innodb_max_undo_log_size = 4G
innodb_undo_directory = /data/mysql/data
innodb_undo_tablespaces = 2
innodb_io_capacity = 4000
innodb_io_capacity_max = 8000
innodb_flush_sync = 0
innodb_flush_neighbors = 0
innodb_write_io_threads = 8
innodb_read_io_threads = 8
innodb_purge_threads = 4
innodb_page_cleaners = 4
innodb_open_files = 65535
innodb_max_dirty_pages_pct = 50
innodb_flush_method = O_DIRECT
innodb_lru_scan_depth = 4000
innodb_checksum_algorithm = crc32
innodb_lock_wait_timeout = 10
innodb_rollback_on_timeout = 1
innodb_print_all_deadlocks = 1
innodb_file_per_table = 1
innodb_online_alter_log_max_size = 4G
innodb_stats_on_metadata = 0
innodb_undo_log_truncate = 1
slave_preserve_commit_order=1

log_error_verbosity = 3
innodb_print_ddl_logs = 1
binlog_expire_logs_seconds = 604800
innodb_status_file = 1
innodb_status_output = 0
innodb_status_output_locks = 0

performance_schema = 1
performance_schema_instrument = '%memory%=on'
performance_schema_instrument = '%lock%=on'

innodb_monitor_enable="module_innodb"
innodb_monitor_enable="module_server"
innodb_monitor_enable="module_dml"
innodb_monitor_enable="module_ddl"
innodb_monitor_enable="module_trx"
innodb_monitor_enable="module_os"
innodb_monitor_enable="module_purge"
innodb_monitor_enable="module_log"
innodb_monitor_enable="module_lock"
innodb_monitor_enable="module_buffer"
innodb_monitor_enable="module_index"
innodb_monitor_enable="module_ibuf_system"
innodb_monitor_enable="module_buffer_page"
innodb_monitor_enable="module_adaptive_hash"

slave_parallel_type=LOGICAL_CLOCK
slave_parallel_workers=2
binlog_group_commit_sync_no_delay_count=10


innodb_redo_log_archive_dirs=/back/redo
log-slave-updates=1
binlog_transaction_dependency_tracking=writeset_session

binlog_checksum=NONE
master_info_repository=TABLE
relay_log_info_repository=TABLE
transaction_write_set_extraction = XXHASH64
loose-group_replication_group_name = 'e88cd6a7-8a12-4368-aeea-21d6b68b2982'
loose-group_replication_start_on_boot = OFF
loose-group_replication_local_address = '192.168.137.86:33061'
loose-group_replication_group_seeds = '192.168.137.86:33061,192.168.137.87:33061,192.168.137.88:33061'
loose-group_replication_bootstrap_group = OFF

[mysqldump]
quick
max_allowed_packet = 32M
```

```bash
ln -s /usr/local/mysql/my.cnf /etc/my.cnf
```

### 2.6 初始化

```
mysqld-debug --defaults-file=/etc/my.cnf --initialize-insecure &
```

### 2.7 启动数据库

```
mysqld_safe --defaults-file=/etc/my.cnf &
```

### 2.8 创建hive用户

```
root@mysql 20:51:  [(none)]> create user 'hive'@'192.168.137.%' identified by '970125';
Query OK, 0 rows affected (0.00 sec)
root@mysql 20:52:  [(none)]> grant all on *.* to 'hive'@'192.168.137.%';
Query OK, 0 rows affected (0.00 sec)
```

## 三、Hive部署

### 3.1 解压安装包并配置环境变量

```bash
tar xf apache-hive-3.1.2-bin.tar.gz -C /usr/local/
mv /usr/local/apache-hive-3.1.2-bin/ /usr/local/hive
chown -R hadoop:hadoop /usr/local/hive
cat>>/etc/profile <<EOF
HADOOP_HOME=/usr/local/hive
PATH=/usr/local/hive/bin:$PATH
export PATH
EOF
source /etc/profile
```

### 3.2 修改核心配置文件

```bash
cd /usr/local/hive
touch hive-site.xml
```

### 3.2.1 配置 hive-site.xml

```xml
[hadoop@node1 conf]$ cat hive-site.xml
<configuration>
    <property>
        <name>javax.jdo.option.ConnectionURL</name>
        <value>jdbc:mysql://node1:3306/hivedb?createDatabaseIfNotExist=true</value>
        <description>JDBC connect string for a JDBC metastore</description>
        <!-- 如果 mysql 和 hive 在同一个服务器节点，那么请更改 hadoop02 为 localhost -->
    </property>
    <property>
        <name>javax.jdo.option.ConnectionDriverName</name>
        <value>com.mysql.jdbc.Driver</value>
        <description>Driver class name for a JDBC metastore</description>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionUserName</name>
        <value>root</value>
        <description>username to use against metastore database</description>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionPassword</name>
        <value>970125</value>
        <description>password to use against metastore database</description>
    </property>
    <property>
        <name>hive.metastore.warehouse.dir</name>
        <value>/hive/warehouse</value>
        <description>hive default warehouse, if nessecory, change it</description>
    </property>    
</configuration>
```

### 3.2.2 添加MySQL连接驱动

```
[hadoop@node1 lib]$ ll | grep mysql-connector-java-8.0.21.jar
-rw-r--r-- 1 root   root    2397321 7月  27 21:13 mysql-connector-java-8.0.21.jar
```

### 3.2.3 初始化数据库

```
[hadoop@node1 ~]$ schematool -dbType mysql -initSchema
```

#### 3.2.3.1 报错处理

```
[hadoop@node1 ~]$ schematool -dbType mysql -initSchema
```

**保证hive内依赖的guava.jar和hadoop内的版本一致**

### 3.2.4 启动 Hive 客户端

```
[hadoop@node1 ~]$ hive --service cli

hive> create database myhive;
OK
Time taken: 0.605 seconds
hive> show databases;
OK
default
myhive
Time taken: 0.194 seconds, Fetched: 2 row(s)
root@mysql 22:34:  [hivedb]> select * from DBS;
```