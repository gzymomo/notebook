- [MySQL高级篇笔记](https://www.cnblogs.com/wbo112/p/15890938.html)

## MySQL体系结构

![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213233313106-202427501.png)

- 连接层

  最上层是一些客户端和链接服务，主要完成一些类似于连接处理、授权认证、及相关的安全方案。服务器也会为安全接入的每个客户 端验证它所具有的操作权限。

- 服务层

  第二层架构主要完成大多数的核心服务功能，如SQL接口，并完成缓存的查询，SQL的分析和优化，部分内置函数的执行。所有跨存 储引擎的功能也在这一层实现，如 过程、函数等。

- 引擎层

  存储引擎真正的负责了MySQL中数据的存储和提取，服务器通过API和存储引擎进行通信。不同的存储引擎具有不同的功能，这样我 们可以根据自己的需要，来选取合适的存储引擎。

- 存储层

  主要是将数据存储在文件系统之上，并完成与存储引擎的交互。

------

> `show engines`查看当前数据库支持的存储引擎
>
> ![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213233327792-2042121625.png)

### 存储引擎特点

![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213233341315-635647329.png)

### InnoDB底层文件

xxx.ibd：xxx代表的是表名，innoDB引擎的每张表都会对应这样一个表空间文件，存储该表的表结构（frm、sdi）、数据和索引。

是否使用独立表空间可以通过`innodb_file_per_table `来设置。

在配置文件（my.cnf）中设置： innodb_file_per_table = 1 #1为开启，0为关闭

通过`show variables like '%per_table%';`查询当前状态

![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213233354597-548279365.png)

也可以通过`set global innodb_file_per_table =OFF;`临时修改，重启后失效。

### MyISAM底层文件

xxx.sdi：存储表结构信息

xxx.MYD: 存储数据

xxx.MYI: 存储索引

------

## 索引

### 慢查询日志

```sql
#通过 show [session|global] status 命令可以提供服务器状态信息。通过如下指令，可以查看当前数据库的INSERT、UPDATE、DELETE、SELECT的访问频次：
SHOW GLOBAL STATUS LIKE 'Com_______';
```

![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213233409467-20534890.png)

------

慢查询日志记录了所有执行时间超过参数 long_query_time 设置值并且扫描记录数不小于  min_examined_row_limit的所有的SQL语句的日志，默认未开启。long_query_time 默认为 10 秒，最小为 0， 精度可以到微秒。

```sql
 #慢查询日志
 show variables like 'slow_query_log';
```

![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213233421090-1281360845.png)

在MySQL的配置文件（/etc/my.cnf）中配置如下信息：

```properties
#开启MYSQL慢查询日志
slow_query_log=1

#设置慢查询日志的时间为2秒,SQL语句执行时间超过2秒，就会被是为慢查询，记录慢查询日志
long_query_time=2
```

重启MYSQL服务生效。

默认慢查询日志文件位置/var/lib/mysql/localhost-slow.log

> 默认情况下，不会记录管理语句，也不会记录不使用索引进行查找的查询。可以使用log_slow_admin_statements和 更改此行为 log_queries_not_using_indexes，如下所述。
>
> ![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213233433840-2038737071.png)

> 

------

### profile详情

show profiles 能够在做SQL优化时帮助我们了解时间都耗费到哪里去了。

- 通过have_profiling参数，能够看到当前MySQL是否支持。

![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213233445792-1235344131.png)

- 查看当前profiling是否已经开启，默认是0,表示未开启。

![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213233456293-1996779157.png)

- 开始profiling

  ![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213233511927-390345283.png)

- 查看SQL语句的耗时情况

  ```sql
  #查看每一条SQL的耗时
  show profiles;
  
  #查看指定query_id的SQL语句各个阶段的耗时情况
  show profile for query 2;
  
  #查看指定query_id的SQL语句各个阶段的CPU消耗情况 
  show profile cpu for query 2;
  ```

  ![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213233524592-1520580016.png)

  ![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213233537191-1886024407.png)

------

### explain执行计划

EXPLAIN 或者 DESC命令获取 MySQL 如何执行 SELECT 语句的信息，包括在 SELECT 语句执行过程中表如何连接和连接的顺序。

![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213233551761-1203906944.png)

- ###### EXPLAIN 执行计划各字段含义：

​	➢ **Id**: select查询的序列号，表示查询中执行select子句或者是操作表的顺序(id相同，执行顺序从上到下；id不同，值越大，越先执行)。

​	➢ **select_type**: 表示 SELECT 的类型，常见的取值有 SIMPLE（简单表，即不使用表连接或者子查询）、PRIMARY（主查询，即外层的查询）、UNION（UNION 中的第二个或者后面的查询语句）、SUBQUERY（SELECT/WHERE之后包含了子查询）等

​	➢ **type**: 表示连接类型，性能由好到差的连接类型为NULL、system、const、eq_ref、ref、range、 index、all 。

​	➢ **possible_key**: 显示可能应用在这张表上的索引，一个或多个。

​	➢ **key**: 实际使用的索引，如果为NULL，则没有使用索引。

​	➢ **key_len**: 表示索引中使用的字节数， 该值为索引字段最大可能长度，并非实际使用长度，在不损失精确性的前提下， 长度越短越好 。

​	➢ **rows**: MySQL认为必须要执行查询的行数，在innodb引擎的表中，是一个估计值，可能并不总是准确的。

​	➢ **filtered**: 表示返回结果的行数占需读取行数的百分比， filtered 的值越大越好。

------

### 索引使用

- ###### 最左前缀法则

  如果索引了多列（联合索引），要遵守最左前缀法则。最左前缀法则指的是查询从索引的最左列开始，并且不跳过索引中的列。 如果跳跃某一列，索引将部分失效(后面的字段索引失效)。

- ###### 范围查询

  联合索引中，出现范围查询(>,<)，范围查询右侧的列索引失效

- ###### 索引列运算

  不要在索引列上进行运算操作， 索引将失效。

- ###### 字符串不加引号

  字符串类型字段使用时，不加引号， 索引将失效。

- ###### 模糊查询

  如果仅仅是尾部模糊匹配，索引不会失效。如果是头部模糊匹配，索引失效。

- ###### or连接的条件

  用or分割开的条件， 如果or前的条件中的列有索引，而后面的列中没有索引，那么涉及的索引都不会被用到。

- ###### 数据分布影响

  如果MySQL评估使用索引比全表更慢，则不使用索引。

- ###### SQL提示

  use index：建议使用指定索引

  ![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213233607611-601237480.png)

  ignore index：忽略指定索引

  ![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213233617274-684659523.png)

  force index：强制使用指定索引

  ![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213233633223-1280188932.png)

- ###### 覆盖索引

  尽量使用覆盖索引（查询使用了索引，并且需要返回的列，在该索引中已经全部能够找到），减少一次主键上的select 。

  ![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213233644518-1532297249.png)

- ###### 前缀索引

  当字段类型为字符串（varchar，text等）时，有时候需要索引很长的字符串，这会让索引变得很大，查询时，浪费大量的磁盘IO， 影 响查询效率。此时可以只将字符串的一部分前缀，建立索引，这样可以大大节约索引空间，从而提高索引效率。

  ➢ 语法

  ```shell
  create index index_name on table_name(clumn(n));
  ```

  ![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213233657504-441941468.png)

  ➢ 前缀长度

  可以根据索引的选择性来决定，而选择性是指不重复的索引值（基数）和数据表的记录总数的比值，索引选择性越高则查询效率越高 ， 唯一索引的选择性是1，这是最好的索引选择性，性能也是最好的

- ###### 单列索引与联合索引

  单列索引：即一个索引只包含单个列。

  联合索引：即一个索引包含了多个列。

  在业务场景中，如果存在多个查询条件，考虑针对于查询字段建立索引时，建议建立联合索引，而非单列索引。

------

### 索引设计原则

1. 针对于数据量较大，且查询比较频繁的表建立索引。
2. 针对于常作为查询条件（where）、排序（order by）、分组（group by）操作的字段建立索引。
3. 尽量选择区分度高的列作为索引，尽量建立唯一索引，区分度越高，使用索引的效率越高。
4. 如果是字符串类型的字段，字段的长度较长，可以针对于字段的特点，建立前缀索引。
5. 尽量使用联合索引，减少单列索引，查询时，联合索引很多时候可以覆盖索引，节省存储空间，避免回表，提高查询效率。
6. 要控制索引的数量，索引并不是多多益善，索引越多，维护索引结构的代价也就越大，会影响增删改的效率。
7. 如果索引列不能存储NULL值，请在创建表时使用NOT NULL约束它。当优化器知道每列是否包含NULL值时，它可以更好地确定哪 个索引最有效地用于查询。

------

## SQL优化

### 插入数据

- ###### insert优化

  ➢ 批量插入

  ➢ 手动提交事务

  ➢ 主键顺序插入

- ###### 大批量插入数据

  如果一次性需要插入大批量数据，使用insert语句插入性能较低，此时可以使用MySQL数据库提供的load指令进行插入。操作如下:

  ```sql
  #客户端连接服务端时，加上参数 --local-infile
   mysql --local-infile -u root -p
  #设置全局参数local_infile为1 ，开启从本地加载文件导入数据的开关
  set global local_infile=1;
  #执行load指令将准备好的数据，加载到表结构中
  load data local infile '/root/load_user_100w_sort.sql'  into table tb_user fields  terminated by ',' lines terminated by '\n';
  ```

  !![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213233713560-1997313047.png)

> **主键顺序插入性能高于乱序插入**
>
> 主要的原因是由于底层数据每一页在物理磁盘存放是按照主键由低到高顺序存放的，如果按照主键顺序插入就类似顺序写入磁盘；如果是乱序插入，就需要调整磁盘上已写入数据顺序。

------

### 主键优化

- ###### 数据组织方式

  在InnoDB存储引擎中，表数据都是根据主键顺序组织存放的，这种存储方式的表称为索引组织表(index organized table IOT)。

  ![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213233724517-97229322.png)

- 页分裂

  页可以为空，也可以填充一半，也可以填充100%。每个页包含了2-N行数据(如果一行数据多大，会行溢出)，根据主键排列。

- 页合并

  当删除一行记录时，实际上记录并没有被物理删除，只是记录被标记（flaged）为删除并且它的空间变得允许被其他记录声明使用。

  当页中删除的记录达到 MERGE_THRESHOLD（默认为页的50%），InnoDB会开始寻找最靠近的页（前或后）看看是否可以将两个页合并以优 化空间使用。

- 主键设计原则

  ➢ 满足业务需求的情况下，尽量降低主键的长度。

  ➢ 插入数据时，尽量选择顺序插入，选择使用AUTO_INCREMENT自增主键。

  ➢ 尽量不要使用UUID做主键或者是其他自然主键，如身份证号。

  ➢ 业务操作时，避免对主键的修改。

------

### order by优化

①  Using filesort:

通过表的索引或全表扫描，读取满足条件的数据行，然后在排序缓冲区 中完成排序操作，所有不是通过索引直接返回排序结果的排序都叫 排序。

② Using index:

通过有序索引顺序扫描直接返回有序数据，这种情况即为 ，不需要额外排序，操作效率高。

➢ 根据排序字段建立合适的索引，多字段排序时，也遵循最左前缀法则。

➢ 尽量使用覆盖索引。

➢ 多字段排序 一个升序一个降序，此时需要注意联合索引在创建时的规则（ASC/DESC ）。

➢ 如果不可避免的出现filesort，大数据量排序时，可以适当增大排序缓冲区大小sort_buffer_size(默认256k) 。

![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213233737572-1378988116.png)

### group by优化

➢ 在分组操作时，可以通过索引来提高效率。

➢ 分组操作时，索引的使用也是满足最左前缀法则的。

![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213233748768-1885128067.png)

------

### limit优化

一个常见又非常头疼的问题就是 limit 2000000,10 ，此时需要MySQL排序前2000010 记录，仅仅返回2000000 - 2000010  的记录，其他记录丢弃，查询排序的代价非常大 。

优化思路: 一般分页查询时，通过创建 覆盖索引 能够比较好地提高性能，可以通过覆盖索引加子查询形式进行优化。

```sql
#这种比较耗时
select * from tb_user limit 10000,10

#这种相对较快
select s.* from tb_user s,(select id from tb_user order by id limit 10000,10) a where s.id=a.id;
```

![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213233801007-763204923.png)

![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213233812005-2044527306.png)

------

### count优化

➢ MyISAM 引擎把一个表的总行数存在了磁盘上，因此执行 count(*) 的时候会直接返回这个数，效率很高；

*➢ InnoDB 引擎就麻烦了，它执行 count(*) 的时候，需要把数据一行一行地从引擎里面读出来，然后累积计数。

优化思路：自己计数。

- count的几种用法 count优化

  ➢ count() 是一个聚合函数，对于返回的结果集，一行行地判断，如果 count 函数的参数不是 NULL，累计值就加 1，否则不加，最 后返回累计值。

  ➢ 用法：count（*）、count（主键）、count（字段）、count（1）

- count的几种用法

​	➢ count（主键）

​		InnoDB 引擎会遍历整张表，把每一行的 主键id 值都取出来，返回给服务层。服务层拿到主键后，直接按行进行累加(主键不可能为null)

​	➢ count（字段）

​		没有not null 约束 : InnoDB 引擎会遍历整张表把每一行的字段值都取出来，返回给服务层，服务层判断是否为null，不为null，计数累加 。

​		有not null 约束：InnoDB 引擎会遍历整张表把每一行的字段值都取出来，返回给服务层，直接按行进行累加。

​	➢ count（1）

​		InnoDB 引擎遍历整张表，但不取值。服务层对于返回的每一行，放一个数字“1”进去，直接按行进行累加。

​	➢ count（*）

​		InnoDB引擎并不会把全部字段取出来，而是专门做了优化，不取值，服务层直接按行进行累加。

**按照效率排序的话，count(字段) < count(主键 id) < count(1) ≈ count(\*)，所以尽量使用 count(\*)。**

------

### update优化

**InnoDB的行锁是针对索引加的锁，不是针对记录加的锁 ,并且该索引不能失效，否则会从行锁升级为表锁 。**

> 这个说法应该是错误的，只能说看起来表象是从行锁升级到了表锁。具体的细节可以看这里[Innodb到底是怎么加锁的 - 掘金 (juejin.cn)](https://juejin.cn/post/7028435335382040589)

------

## 视图

### 介绍

​	视图（View）是一种虚拟存在的表。视图中的数据并不在数据库中实际存在，行和列数据来自定义视图的查询中使用的表，并且是在使用视 图时动态生成的。

​	通俗的讲，视图只保存了查询的SQL逻辑，不保存查询结果。所以我们在创建视图的时候，主要的工作就落在创建这条SQL查询语句上。

### 创建

```sql
#语法
CREATE [ OR REPLACE ] VIEW 视图名称 [(列名列表)] AS SELECT语句 [WITH [CASCADED | LOCAL ] CHECK OPTION]

#示例
create or replace view view_tb_user as select id,name from tb_user where id<10;
```

### 查询

```sql
#查看创建视图语句
SHOW CREATE VIEW 视图名称;

#查看视图数据
SELECT * FROM 视图名称 ...;
```

### 修改

```sql
#方式一
CREATE [ OR REPLACE ] VIEW 视图名称 [(列名列表)] AS SELECT语句 [WITH [CASCADED | LOCAL ] CHECK OPTION]

#方式二
ALTER VIEW 视图名称 [(列名列表)] AS SELECT语句 [WITH [CASCADED | LOCAL ] CHECK OPTION]
```

### 删除

```sql
DROP VIEW [IF EXISTS] 视图名称[,视图名称]
```

------

### 视图的检查选项

当使用WITH CHECK OPTION子句创建视图时，MySQL会通过视图检查正在更改的每个行，例如 插入，更新，删除，以使其符合视图的定 义。 MySQL允许基于另一个视图创建视图，它还会检查依赖视图中的规则以保持一致性。

为了确定检查的范围，mysql提供了两个选项： CASCADED 和 LOCAL ，默认值为 CASCADED

### 视图的更新

要使视图可更新，视图中的行与基础表中的行之间必须存在一对一的关系。

如果视图包含以下任何一项，则该视图不可更新：

1. 聚合函数或窗口函数（SUM()、 MIN()、 MAX()、 COUNT()等）
2. DISTINCT
3. GROUP BY
4. HAVING
5. UNION 或者 UNION ALL

### 作用

➢ 简单

视图不仅可以简化用户对数据的理解，也可以简化他们的操作。那些被经常使用的查询可以被定义为视图，从而使得用户不必为以后的操 作每次指定全部的条件。

➢ 安全

数据库可以授权，但不能授权到数据库特定行和特定的列上。通过视图用户只能查询和修改他们所能见到的数据

➢ 数据独立

视图可帮助用户屏蔽真实表结构变化带来的影响。

------

## 系统变量

### 查看系统变量

```sql
SHOW [SESSION|GLOBAL] VARIABLES; #查看所有系统变量SHOW [SESSION|GLOBAL] VARIABLES LIKE '...'; #模糊查看系统变量SHOW @@[SESSION|GLOBAL] 系统变量名;           #查看指定变量的值
```

### 设置变量的值

```sql
SET [SESSION|GLOBAL] 系统变量名=值；SET  @@[SESSION|GLOBAL] 系统变量名=值；
```

> 注意:
>
> ​	如果没有指定SESSION/GLOBAL，默认是SESSION，会话变量。
>
> ​	mysql服务重新启动之后，所设置的全局参数会失效，要想不失效，可以在 /etc/my.cnf 中配置。

------

## 锁

### 全局锁

全局锁就是对整个数据库实例加锁，加锁后整个实例就处于只读状态，后续的DML的写语句，DDL语句，已经更新操作的事务提交语句都 将被阻塞。

其典型的使用场景是做全库的逻辑备份，对所有的表进行锁定，从而获取一致性视图，保证数据的完整性。

- ###### 语法

```sql
flush tables with read lock;   #开启全局锁
......                         #只有只读语句可以执行，所有session会话中的写的语句都会阻塞
unlock tables;                 #解除全局锁
```

> 备份数据库
>
> ```shell
> mysqldump -uroot -p123456 数据库实例名 >xxx.sql
> ```

- ###### 特点

  数据库中加全局锁，是一个比较重的操作，存在以下问题：

  1. 如果在主库上备份，那么在备份期间都不能执行更新，业务基本上就得停摆。
  2. 如果在从库上备份，那么在备份期间从库不能执行主库同步过来的二进制日志（binlog），会导致主从延迟。

> 在InnoDB引擎中，我们可以在备份时加上参数 --single-transaction 参数来完成不加锁的一致性数据备份。
>
> ```SHELL
> mysqldump --single-transaction  -uroot -p123456 数据库实例名 >xxx.sql
> ```

------

### 表级锁

表级锁，每次操作锁住整张表。锁定粒度大，发生锁冲突的概率最高，并发度最低。应用在MyISAM、InnoDB、BDB等存储引擎中。

对于表级锁，主要分为以下三类：

1. 表锁
2. 元数据锁（meta data lock，MDL）
3. 意向锁

- ###### 表锁

  - 对于表锁，分为两类：
    1. 表共享读锁（read lock）
    2. 表独占写锁（write lock）
  - 语法：
    1. 加锁：lock tables 表名... read/write。
    2. 释放锁：unlock tables / 客户端断开连接 。

- 元数据锁（ meta data lock， MDL）

  MDL加锁过程是系统自动控制，无需显式使用，在访问一张表的时候会自动加上。MDL锁主要作用是维护表元数据的数据一致性，在表 上有活动事务的时候，不可以对元数据进行写入操作。 为了避免DML与DDL冲突，保证读写的正确性。

  在MySQL5.5中引入了MDL，当对一张表进行增删改查的时候，加MDL读锁(共享)；当对表结构进行变更操作的时候，加MDL写锁(排他)。

  | 对应SQL                                        | 锁类型                                  | 说明                                             |
  | ---------------------------------------------- | :-------------------------------------- | ------------------------------------------------ |
  | lock tables xxx read / write                   | SHARED_READ_ONLY / SHARED_NO_READ_WRITE |                                                  |
  | select 、select ... lock in share mode         | SHARED_READ                             | 与SHARED_READ、SHARED_WRITE兼容，与EXCLUSIVE互斥 |
  | insert 、update、delete、select ... for update | SHARED_WRITE                            | 与SHARED_READ、SHARED_WRITE兼容，与EXCLUSIVE互斥 |
  | alter table ...                                | EXCLUSIVE                               | 与其他的MDL都互斥                                |

  > 查看元数据锁
  >
  > ```sql
  > select object_type,object_schema,object_name,lock_type,lock_duration from performance_schema.metadata_locks;
  > ```

- 意向锁

  为了避免DML在执行时，加的行锁与表锁的冲突，在InnoDB中引入了意向锁，使得表锁不用检查每行数据是否加锁，使用意向锁来减 少表锁的检查。

  1. 意向共享锁（IS）：

     由语句 select ... lock in share mode添加。

     与表锁共享锁（read）兼容，与表锁排它锁（write）互斥。

  2. 意向排他锁（IX）：

     由insert、update、delete、select ... for update 添加。

     与表锁共享锁（read）及排它锁（write）都互斥。意向锁之间不会互斥。

  > 查看意向锁及行锁的加锁情况
  >
  > ```shell
  > select object_schema,object_name,index_name,lock_type,lock_mode,lock_data from performance_schema.data_locks;
  > ```

------

### 行级锁

行级锁，每次操作锁住对应的行数据。锁定粒度最小，发生锁冲突的概率最低，并发度最高。应用在InnoDB存储引擎中。

InnoDB的数据是基于索引组织的，行锁是通过对索引上的索引项加锁来实现的，而不是对记录加的锁。对于行级锁，主要分为以下三类：

1. 行锁（Record Lock）：锁定单个行记录的锁，防止其他事务对此行进行update和delete。在RC、RR隔离级别下都支持。

   - 共享锁（S）：允许一个事务去读一行，阻止其他事务获得相同数据集的排它锁。
   - 排他锁（X）：允许获取排他锁的事务更新数据，阻止其他事务获得相同数据集的共享锁和排他锁。

   > 默认情况下，InnoDB在 REPEATABLE READ事务隔离级别运行，InnoDB使用 next-key 锁进行搜索和索引扫描，以防止幻读。
   >
   > 1. 针对唯一索引进行检索时，对已存在的记录进行等值匹配时，将会自动优化为行锁。
   > 2. InnoDB的行锁是针对于索引加的锁，不通过索引条件检索数据，那么InnoDB将对表中的所有记录加锁，此时 就会升级为表锁。

   ![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213233839824-1845570568.png)

   ![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213233850978-1952325593.png)

2. 间隙锁（Gap Lock）：锁定索引记录间隙（不含该记录），确保索引记录间隙不变，防止其他事务在这个间隙进行insert，产生幻读。在RR隔离级别下都支持。

3. 临键锁（Next-Key Lock）：行锁和间隙锁组合，同时锁住数据，并锁住数据前面的间隙Gap。在RR隔离级别下支持。

> 默认情况下，InnoDB在 REPEATABLE READ事务隔离级别运行，InnoDB使用 next-key 锁进行搜索和索引扫描，以防止幻读。
>
> 1. 索引上的等值查询(唯一索引)，给不存在的记录加锁时, 优化为间隙锁 。
> 2. 索引上的等值查询(普通索引)，向右遍历时最后一个值不满足查询需求时，next-key lock 退化为间隙锁。
> 3. 索引上的范围查询(唯一索引)--会访问到不满足条件的第一个值为止。

------

> 注意：间隙锁唯一目的是防止其他事务插入间隙。间隙锁可以共存，一个事务采用的间隙锁不会阻止另一个事务在同一间隙上采用间隙锁。

------

## InnoDB引擎

### 逻辑存储结构

![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213233902644-32661679.png)

------

### 架构

MySQL5.5 版本开始，默认使用InnoDB存储引擎，它擅长事务处理，具有崩溃恢复特性，在日常开发中使用非常广泛。下面是InnoDB架构图，左侧为内存结构，右 侧为磁盘结构。

![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213233916514-1406273656.png)

------

#### 架构-内存架构

![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213233926343-561593411.png)

![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213233941952-1651427266.png)

![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213233955409-346125394.png)

------

#### 架构-磁盘结构

![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213234006418-917916778.png)

![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213234017054-2076003364.png)

示例：

1. 执行如下sql：

```sql
create tablespace ts_itheima add datafile 'myitheima.ibd'  engine=innodb;
create table a(id int primary key auto_increment,name varchar(32) ) engine=innodb tablespace ts_itheima;
```

1. 查看mysql数据文件目录，默认在`/var/lib/mysql`目录。就会有`myitheima.ibd`这个文件

------

![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213234032308-1768018550.png)

![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213234042062-413270771.png)

#### 架构-后台线程

![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213234052420-1247453017.png)

查看innod的状态信息

```sql
show engine innodb status;
```

------

### 事务原理

事务 是一组操作的集合，它是一个不可分割的工作单位，事务会把所有的操作作为一个整体一起向系统提交或撤销操作请求，即这些操作 要么同时成功，要么同时失败。

特性

• 原子性（Atomicity）：事务是不可分割的最小操作单元，要么全部成功，要么全部失败。

• 一致性（Consistency）：事务完成时，必须使所有的数据都保持一致状态。

• 隔离性（Isolation）：数据库系统提供的隔离机制，保证事务在不受外部并发操作影响的独立环境下运行。

• 持久性（Durability）：事务一旦提交或回滚，它对数据库中的数据的改变就是永久的。

------

![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213234104394-332202555.png)

事务的原子性，一致性，持久性通过`redo log`、`undo log`来实现。

事务的隔离性通过**锁**，`MVCC`来实现。

------

![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213234115672-736426881.png)

重做日志，记录的是事务提交时数据页的物理修改，是用来实现事务的持久性。

该日志文件由两部分组成：重做日志缓冲（redo log buffer）以及重做日志文件（redo log file）,前者是在内存中，后者在磁盘中。当事务 提交之后会把所有修改信息都存到该日志文件中, 用于在刷新脏页到磁盘,发生错误时, 进行数据恢复使用。

![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213234126933-1934911331.png)

------

![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213234144043-2057251889.png)

回滚日志，用于记录数据被修改前的信息 , 作用包含两个 : 提供回滚 和 MVCC(多版本并发控制) 。

undo log和redo log记录物理日志不一样，它是逻辑日志。可以认为当delete一条记录时，undo  log中会记录一条对应的insert记录，反之  亦然，当update一条记录时，它记录一条对应相反的update记录。当执行rollback时，就可以从undo  log中的逻辑记录读取到相应的内容 并进行回滚。

Undo log销毁：undo log在事务执行时产生，事务提交时，并不会立即删除undo log，因为这些日志可能还用于MVCC。

Undo log存储：undo log采用段的方式进行管理和记录，存放在前面介绍的 rollback segment 回滚段中，内部包含1024个undo log  segment。

------

### MVCC-基本概念

- 当前读

  读取的是记录的最新版本，读取时还要保证其他并发事务不能修改当前记录，会对读取的记录进行加锁。

  对于我们日常的操作，如： select ... lock in share mode(共享锁)，select ... for update、update、insert、delete(排他锁)都是一种当前读。

- 快照读

  简单的select（不加锁）就是快照读，快照读，读取的是记录数据的可见版本，有可能是历史数据，不加锁，是非阻塞读。

  - Read Committed：每次select，都生成一个快照读。
  - Repeatable Read：开启事务后第一个select语句才是快照读的地方。
  - Serializable：快照读会退化为当前读。

- MVCC

  全称 Multi-Version Concurrency  Control，多版本并发控制。指维护一个数据的多个版本，使得读写操作没有冲突，快照读为MySQL实现  MVCC提供了一个非阻塞读功能。MVCC的具体实现，还需要依赖于数据库记录中的三个隐式字段、undo log日志、readView。

------

### MVCC-实现原理

#### 记录中的隐藏字段

![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213234159160-1163196182.png)

> 可以通过idb2sdi命令通过查看idb文件(默认在/var/lib/mysql/)，就能看到表结构，其中就有隐藏字段。比如`DB_TRX_ID`、`DB_ROLL_PTR`
>
> ```shell
> ibd2sdi XXX.idb
> ```

------

#### undo log

回滚日志，在insert、update、delete的时候产生的便于数据回滚的日志。

当insert的时候，产生的undo log日志只在回滚时需要，在事务提交后，可被立即删除。

而update、delete的时候，产生的undo log日志不仅在回滚时需要，在快照读时也需要，不会立即被删除。

#### undo log版本链

![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213234210912-162698118.png)

如上图:

1. 事务2执行时，需要记住修改之前的数据，在回滚时使用。

![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213234226776-1553410331.png)

1. 事务3执行时，由于事务2已经提交，所以它需要在事务2执行结果的基础上进行操作。所以它的undo log里面的记录就是事务2执行的记录。

   ![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213234238324-1341081883.png)

2. 事务4执行时，由于事务3已经提交，所以它需要在事务2执行结果的基础上进行操作。所以它的undo log里面的记录就是事务3执行的记录。

   ![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213234249975-108796157.png)

> 不同事务或相同事务对同一条记录进行修改，会导致该记录的undolog生成一条记录版本链表，链表的头部是最新的旧记录，链表尾部是最早的旧记录。

------

#### readview

ReadView（读视图）是 快照读 SQL执行时MVCC提取数据的依据，记录并维护系统当前活跃的事务（未提交的）id。

ReadView中包含了四个核心字段：

| 字段           | 含义                                                 |
| -------------- | ---------------------------------------------------- |
| m_ids          | 当前活跃的事务ID集合                                 |
| min_trx_id     | 最小活跃事务ID                                       |
| max_trx_id     | 预分配事务ID，当前最大事务ID+1（因为事务ID是自增的） |
| creator_trx_id | ReadView创建者的事务ID                               |

![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213234307526-1089682892.png)

> 上面4个规则，只要满足1，2，4任何一个就可以访问对应的数据；不满足3就要拒绝。

不同的隔离级别，生成ReadView的时机不同：

➢ READ COMMITTED ：在事务中每一次执行快照读时生成ReadView。

➢ REPEATABLE READ：仅在事务中第一次执行快照读时生成ReadView，后续复用该ReadView。

> ![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213234319126-976830816.png)

> 如上图，当前隔离级别是READ COMMITTED时，事务5中的第一次查询的结果时是事务2提交的记录。
>
> ------
>
> ![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213234333120-84931662.png)

> 如上图，当前隔离界别时READ COMMITTED时，事务5中的第二次查询的结果时是事务3提交的记录

------

> ![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213234348480-1030717119.png)

> 当前隔离级别是读已提交时，事务5中两次查询的ReadView是相同的，所以两次查询的结果都是事务2提交的记录。

------

## MySQL管理

Mysql数据库安装完成后，自带了一下四个数据库，具体作用如下：

| 数据库             | 含义                                                         |
| ------------------ | ------------------------------------------------------------ |
| mysql              | 存储MySQL服务器正常运行所需要的各种信息 （时区、主从、用户、权限等） |
| information_schema | 提供了访问数据库元数据的各种表和视图，包含数据库，表，字段类型及访问权限等 |
| performance_schema | 为MySQL服务器运行时状态提供了一个底层监控功能，主要用于手机数据库服务器性能参数 |
| sys                | 包含了一系列方便DBA和开发人员利用performance_schema性能数据库进行性能调优和诊断的视图 |

### 常用工具:

- ##### mysql

该mysql不是指mysql服务，而是指mysql的客户端工具。

![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213234404461-313009614.png)

-e选项可以在Mysql客户端执行SQL语句，而不用连接到MySQL数据库再执行，对于一些批处理脚本，这种方式尤其方便。

![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213234415247-1785899312.png)

- ##### mysqladmin

可以通过通过`mysqladmin --help`查看所有选项

mysqladmin 是一个执行管理操作的客户端程序。可以用它来检查服务器的配置和当前状态、创建并删除数据库等。

- ##### mysqlbinlog

由于服务器生成的二进制日志文件以二进制格式保存，所以如果想要检查这些文本的文本格式，就会使用到mysqlbinlog 日志管理工具。

![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213234427391-376996566.png)

> 如通过`mysqlbinlog binlog.000001`查看日志(在/var/lib/mysql目录)
>
> ![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213234439322-340134812.png)

- ##### mysqlshow

  mysqlshow 客户端对象查找工具，用来很快地查找存在哪些数据库、数据库中的表、表中的列或者索引。

  ![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213234452061-336196336.png)

  ![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213234502019-1100578881.png)

- ##### mysqldump

  mysqldump 客户端工具用来备份数据库或在不同数据库之间进行数据迁移。备份内容包含创建表，及插入表的SQL语句。

  ![img](https://img2022.cnblogs.com/blog/368308/202202/368308-20220213234514125-270376845.png)

> ```shell
> mysqldump -uroot -p123456 test>test.sql    #备份数据库test到test.sql
> mysqldump -uroot -p123456 -T   /var/lib/mysql-files  test    #将test数据库的表结构和数据导出到/var/lib/mysql-files目录下
> ```

- ##### mysqlimport/source

mysqlimport 是客户端数据导入工具，用来导入mysqldump 加 -T 参数后导出的文本文件。

如果需要导入sql文件,可以使用mysql中的source 指令 。