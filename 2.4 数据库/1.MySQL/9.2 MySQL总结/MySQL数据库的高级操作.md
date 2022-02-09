- [MySQL数据库的高级操作](https://blog.51cto.com/u_15380738/4987769)

## 数据表高级操作

### 准备工作：安装MySQL数据库

```
create database CLASS;
use CLASS;

create table TEST (id int not null,name char(20)    not null,cardid varchar(18) not null unique     key,primary key (id));

insert into TEST(id,name,cardid) values (1,'zhangsan','123123');

insert into TEST(id,name,cardid) values (2,'lisi','1231231');

insert into TEST(id,name,cardid) values (3,'wangwu','12312312');
select * from TEST;
```

![10.png](https://s2.51cto.com/images/20220207/1644194171781502.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)

## 一、克隆表

将数据表的数据记录生成到新的表中

## 方法一

```
例:create table TEST01 like TEST;
select * from TEST01;

desc TEST01;
insert into TEST01 select * from TEST;
select * from TEST01;
```

![12.png](https://s2.51cto.com/images/20220207/1644212513253381.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)

## 方法二

```
例:create table TEST02 (select * from TEST);
select * from TEST02;
```

**CREATE TABLE 新表 (SELECT*  FROM 旧表)
这种方法会将oldtable中所有的内容都拷贝过来不过这种方法的一个最不好的地方就是新表中没有了旧表的primary key、Extra（auto_increment）等属性。**
![10.png](https://s2.51cto.com/images/20220207/1644212709806399.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)

## 二、清空表，删除表内的所有数据

```
delete from TEST02;
```

**#DELETE清空表后，返回的结果内有删除的记录条目；DELETE工作时是一行一行的删除记录数据的；如果表中有自增长字段，使用DELETE FROM 删除所有记录后，再次新添加的记录会从原来最大的记录 ID 后面继续自增写入记录**
![12.png](https://s2.51cto.com/images/20220207/1644212912472032.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)

```
例：create table if not exists TEST03 (id int primary     key auto_increment,name varchar(20) not null,cardid varchar(18) not null unique key);
show tables;

insert into TEST03 (name,cardid) values ('zhangsan','11111');       
select * from TEST03;
delete from TEST03;

insert into TEST03 (name,cardid) values ('lisi','22222');
select * from TEST03;
```

![10.png](https://s2.51cto.com/images/20220207/1644213167495801.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)
![12.png](https://s2.51cto.com/images/20220207/1644213482369125.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)

### 方法二

```
例：select * from TEST03;
truncate table TEST03;
insert into TEST03 (name,cardid) values ('wangwu','33333');
select * from TEST03;

#TRUNCATE 清空表后，没有返回被删除的条目；TRUNCATE 工作时是将表结构按原样重新建立，因此在速度上 TRUNCATE 会比 DELETE 清空表快；使用 TRUNCATE TABLE 清空表内数据后，ID 会从 1 开始重新记录。
```

![11.png](https://s2.51cto.com/images/20220207/1644213695798569.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)

## 三、创建临时表

**临时表创建成功之后，使用SHOW TABLES命令是看不到创建的临时表的，临时表会在连接退出后被销毁。 如果在退出连接之前，也可以可执行增删改查等操作，比如使用 DROP TABLE 语句手动直接删除临时表。**

```
CREATE TEMPORARY TABLE 表名 (字段1 数据类型,字段2 数据类型[,...][,PRIMARY KEY (主键名)]);

例：create temporary table TEST04 (id int not null,name varchar(20) not null,cardid varchar(18) not null unique key,primary key (id));
show tables;

insert into TEST04 values (1,'haha','12345');   
select * from TEST04;
```

![12.png](https://s2.51cto.com/images/20220207/1644213984176193.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)
![12.png](https://s2.51cto.com/images/20220207/1644214155566015.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)

## 四、创建外键约束

保证数据的完整性和一致性
外键的定义：如果同一个属性字段x在表一中是主键，而在表二中不是主键，则字段x称为表二的外键。

主键表和外键表的理解：
1、以公共关键字作为主键的表为主键表（父表、主表）
2、以公共关键字作为外键的表为外键表（从表、外表）

注意：与外键关联的主表的字段必须设置为主键，要求从表不能是临时表，主从表的字段具有相同的数据类型、字符长度和约束

```
例：create table TEST04 (hobid int(4),hobname varchar(50));
create table TEST05 (id int(4) primary key auto_increment,name varchar(50),age int(4),hobid int(4));

alter table TEST04 add constraint PK_hobid primary key(hobid);
alter table TEST05 add constraint FK_hobid foreign key(hobid) references TEST04(hobid);
```

![image.png](https://s2.51cto.com/images/20220207/1644214455391891.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)

```
例：添加数据记录
insert into TEST05 values (1,'zhangsan','20',1);
insert into TEST04 values (1,'sleep');
insert into TEST05 values (1,'zhangsan',20,1);
```

![10.png](https://s2.51cto.com/images/20220207/1644214652522371.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)

```
例:drop table TEST04;
drop table TEST05;
drop table TEST04;
```

![12.png](https://s2.51cto.com/images/20220207/1644214815558753.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)
**注：如果要删除外键约束字段
先删除外键约束，再删除外键名，此处不演示**

```
show create table TEST05;
alter table TEST05 drop foreign key FK_hobid;
alter table TEST05 drop key FK_hobid;
desc TEST05;
```

## MySQL中6种常见的约束

**主键约束  primary key
外键约束    foreign key
非空约束    not null
唯一约束    unique [key|index]
默认值约束   default
自增约束    auto_increment**

## 五、数据库用户管理

### 1、新建用户

```
CREATE USER '用户名'@'来源地址' [IDENTIFIED BY [PASSWORD] '密码'];
```

**‘用户名’：指定将创建的用户名**

**‘来源地址’：指定新创建的用户可在哪些主机上登录，可使用IP地址、网段、主机名的形式，本地用户可用localhost，允许任意主机登录可用通配符%**

**‘密码’：若使用明文密码，直接输入’密码’，插入到数据库时由Mysql自动加密;
------若使用加密密码，需要先使用SELECT PASSWORD(‘密码’); 获取密文，再在语句中添加 PASSWORD ‘密文’;
------若省略“IDENTIFIED BY”部分，则用户的密码将为空（不建议使用）**

```
例：create user 'zhangsan'@'localhost' identified by '123123';
select password('123123');
create user 'lisi'@'localhost' identified by password '*E56A114692FE0DE073F9A1DD68A00EEB9703F3F1';
```

![12.png](https://s2.51cto.com/images/20220207/1644215191209831.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)

## 2、查看用户信息

**创建后的用户保存在 mysql 数据库的 user 表里**

```
USE mysql;
SELECT User,authentication_string,Host from user;
```

![10.png](https://s2.51cto.com/images/20220207/1644215291976306.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)

## 3、重命名用户

```
RENAME USER 'zhangsan'@'localhost' TO 'wangwu'@'localhost';
SELECT User,authentication_string,Host from user;
```

![12.png](https://s2.51cto.com/images/20220207/1644215457521379.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)

## 4、删除用户

```
DROP USER 'lisi'@'localhost';
SELECT User,authentication_string,Host from user;
```

![12.png](https://s2.51cto.com/images/20220207/1644215856340589.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)

## 5、修改当前登录用户密码

```
SET PASSWORD = PASSWORD('abc123');
quit
mysql -u root -p
```

![image.png](https://s2.51cto.com/images/20220207/1644216256103080.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)

## 6、修改其他用户密码

```
SET PASSWORD FOR 'wangwu'@'localhost' = PASSWORD('abc123');
use mysql;
SELECT User,authentication_string,Host from user;
```

![image.png](https://s2.51cto.com/images/20220207/1644216549648877.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)

## 7、忘记 root 密码的解决办法

### 1、修改 /etc/my.cnf 配置文件，不使用密码直接登录到 mysql

```
vim /etc/my.cnf
[mysqld]
skip-grant-tables         #添加，使登录mysql不使用授权表

systemctl restart mysqld.service

mysql               #直接登录
```

![image.png](https://s2.51cto.com/images/20220207/1644216592665716.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)
![image.png](https://s2.51cto.com/images/20220207/1644216599964300.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)

### 2.使用 update 修改 root 密码，刷新数据库

```
UPDATE mysql.user SET AUTHENTICATION_STRING = PASSWORD('112233') where user='root';
FLUSH PRIVILEGES;
quit

再把 /etc/my.cnf 配置文件里的 skip-grant-tables 删除，并重启 mysql 服务。
mysql -u root -p
112233
```

![image.png](https://s2.51cto.com/images/20220207/1644216634183586.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)
![image.png](https://s2.51cto.com/images/20220207/1644216642392414.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)

## 六、数据库用户授权

### 1、授予权限

```
GRANT语句：专门用来设置数据库用户的访问权限。当指定的用户名不存在时，GRANT语句将会创建新的用户；当指定的用户名存在时，GRANT 语句用于修改用户信息。

GRANT 权限列表 ON 数据库名.表名 TO '用户名'@'来源地址' [IDENTIFIED BY '密码'];

#权限列表：用于列出授权使用的各种数据库操作，以逗号进行分隔，如“select,insert,update”。使用“all”表示所有权限，可授权执行任何操作。

#数据库名.表名：用于指定授权操作的数据库和表的名称，其中可以使用通配符“*”。*例如,使用“kgc.*”表示授权操作的对象为 kgc数据库中的所有表。

#'用户名@来源地址'：用于指定用户名称和允许访问的客户机地址，即谁能连接、能从哪里连接。来源地址可以是域名、IP 地址，还可以使用“%”通配符，表示某个区域或网段内的所有地址，如“%.lic.com”、“192.168.184.%”等。

#IDENTIFIED BY：用于设置用户连接数据库时所使用的密码字符串。在新建用户时，若省略“IDENTIFIED BY”部分， 则用户的密码将为空。
```

**#允许用户wangwu在本地查询 CLASS 数据库中所有表的数据记录，但禁止查询其他数据库中的表的记录。**

```
例：
GRANT select ON CLASS.* TO 'wangwu'@'localhost' IDENTIFIED BY '123456';
quit;
mysql -u wangwu -p
123456
show databases;
use information_schema;
show tables;
select * from INNODB_SYS_TABLESTATS;
```

**#允许用户wangwu在本地远程连接 mysql ，并拥有所有权限。**

```
quit;
mysql -u root -p112233
GRANT ALL PRIVILEGES ON *.* TO 'wangwu'@'localhost' IDENTIFIED BY '123456';

flush privileges;
quit

mysql -u wangwu -p123456
create database SCHOOL;
```

### 2、查看权限

```
SHOW GRANTS FOR 用户名@来源地址;

例：
SHOW GRANTS FOR 'wangwu'@'localhost';
```

### 3、撤销权限

```
REVOKE 权限列表 ON 数据库名.表名 FROM 用户名@来源地址;

例：quit;
mysql -u root -p112233
SHOW GRANTS FOR 'wangwu'@'localhost';
REVOKE SELECT ON "CLASS".* FROM 'wangwu'@'localhost';

SHOW GRANTS FOR 'wangwu'@'localhost';
```

**#USAGE权限只能用于数据库登陆，不能执行任何操作；USAGE权限不能被回收，即 REVOKE 不能删除用户。**

```
flush privileges;
```