[TOC]

PostgreSQL是一个多用户数据库，可以为不同用户指定允许的权限。

# 命令创建 

- **角色**
  PostgreSQL使用**角色**的概念管理数据库访问权限。 根据角色自身的设置不同，一个角色可以看做是一个数据库用户，或者一组数据库用户。 角色可以拥有数据库对象(比如表)以及可以把这些对象上的权限赋予其它角色， 以控制谁拥有访问哪些对象的权限。
  操作角色的语句：

```mysql
create role db_role1; /*--创建角色*/
drop role db_role1; /*--删除角色*/
select rolename from pg_roles; /*--查看所有角色*/
```

- **角色的权限**
  一个数据库角色可以有很多权限，这些权限定义了角色和拥有角色的用户可以做的事情。

  ```mysql
  create role db_role1 LOGIN; --创建具有登录权限的角色db_role1
  create role db_role2 SUPERUSER; --创建具有超级用户权限的角色
  create role db_role3 CREATEDB; --创建具有创建数据库权限的角色
  create role db_role4 CREATEROLE --创建具有创建角色权限的角色
  alter role db_role1 nologin nocreatedb; --修改角色取消登录和创建数据库权限
  ```

- **用户**
  其实用户和角色都是角色，只是用户是具有登录权限的角色。

  ```mysql
  create user db_user1 password '123'; --创建用户
  create role db_user1 password '123' LOGIN; --同上一句等价
  drop user db_user1; --删除用户
  alter user db_user1 password '123456'; --修改密码
  alter user db_user1 createdb createrole; --对用户授权
  ```

- **赋予角色控制权限**
  我们可以使用GRANT 和REVOKE命令赋予用户角色，来控制权限。

  ```mysql
  create user db_user1; --创建用户1
  create user db_user2; --创建用户2
  create role db_role1 createdb createrole; --创建角色1
  grant db_role1 to db_user1,db_user2; --给用户1,2赋予角色1,两个用户就拥有了创建数据库和创建角色的权限
  revoke db_role1 from db_user1; --从用户1移除角色1，用户不在拥有角色1的权限
  ```

# Postgres设置用户角色权限

1.使用管理员连接pgsql

```mysql
# 赋予所有表的所有权限给指定用户
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO "用户名"; 

# 赋予指定表的所有权限给指定用户
GRANT ALL PRIVILEGES ON "表名" TO "用户名";

#修改库的所有者
alter database 库名 owner to 用户名;
#授予用户库权限
grant ALL ON DATABASE 库名 TO 用户名;
#授予用户指定的库权限
grant select on all tables in schema public to 用户名;     // 在那个db执行就授哪个db的权限

#修改表的所有者
alter table 表名 owner to 用户名;
#授予用户表权限
GRANT ALL ON 表名 TO 用户名;

#修改sequence所有者
alter sequence 序列名 owner to 用户名;
#修改sequence权限
GRANT ALL ON 序列名 TO 用户名;
```

# PostgreSQL用户角色权限管理

PostgreSQL使用角色来管理用户权限，角色是一系列相关权限的集合，如果哪个用户需要这些权限，就可以把该角色赋予用户，实际上在PostgreSQL内部实现中，角色和用户没有任何区别，只是逻辑上分为角色和用户，下文的描述中，角色与用户等同。

## 1. 角色创建与删除

创建角色：
create role myrole;

删除角色：
drop role myrole;

除了SQL语句之外，PostgreSQL还提供了包装的命令createuser和dropuser来创建和删除角色。

createuser myrole
dropuser myrole

查看当前已创建的角色：
SELECT rolname FROM pg_roles;

## 2. 角色的属性

角色可以拥有一些属性或者叫权限，比如登录数据库，需要角色拥有LOGIN属性，这类权限在创建角色的时候指定，或者通过alter role来修改。

示例：
create role myrole with login;

create role myrole with login SUPERUSER INHERIT CREATEDB CREATEROLE CONNECTION LIMIT 50 REPLICATION PASSWORD '123456' VALID UNTIL '2021-01-01';

修改属性：
alter role myrole nologin;

**常用属性：**

- SUPERUSER/NOSUPERUSER，创建出来的用户是否为超级用户，只有超级用户才能创建超级用户
- LOGIN/NOLOGIN，指定创建的用户是否有连接数据库的权限
- INHERIT/NOINHERIT，指定创建的用户是否继承某些角色的权限
- CREATEDB/NOCREATEDB，指定创建出来的用户是否有权限创建数据库
- CREATEROLE/NOCREATEROLE，指定创建出来的用户是否有创建其他角色的权限
- CONNECTION LIMIT connlimit，指定用户能够使用的最大并发连接数量，默认-1，表示没有限制
- REPLICATION，指定复制权限
- PASSWORD password，指定密码
- VALID UNTIL 'timestamp'，指定密码失效时间，如果不指定，永远有效
- IN ROLE role_name，指定成为哪些角色的成员
- ROLE role_name，role_name将成为这个新建角色的成员

角色(role)和用户(user)可以等同使用，创建用户时，默认就已经带上了LOGIN属性，而角色默认没有带任何属性。

create user myuser;

myuser默认已经带了login属性。

## 3. 角色的权限：

角色的权限主要是对数据库对象(表，schema，trigger等）的操作权限，与角色的属性略有不同。权限使用grant或revoke进行管理。

示例1：将所有表的增删改查权限赋予角色
grant select,insert,update,delete on all tables in schema schema_name to role_name;

示例2：将某个表的增删改查权限赋予角色
grant select,insert,update,delete on table schema_name.tb to role_name;

示例3：移除权限：
revoke delete on all tables in schema schema_name from role_name;

**常用权限汇总：**

- SELECT
- INSERT
- UPDATE
- DELETE
- TRUNCATE
- REFERENCES
- TRIGGER
- CREATE
- CONNECT
- TEMPORARY
- EXECUTE
- USAGE
- ALL PRIVILEGES