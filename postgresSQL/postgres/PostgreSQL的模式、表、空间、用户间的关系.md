码神岛：[PostgreSQL的模式、表、空间、用户间的关系](https://msd.misuland.com/pd/3691884927646700986)

### 什么是Schema？

一个数据库包含一个或多个已命名的模式，模式又包含表。模式还可以包含其它对象， 包括数据`类型`、`函数`、`操作符`等。同一个对象名可以在不同的模式里使用而不会导致冲突； 比如，`herschema`和`myschema`都可以包含一个名为`mytable`的表。 和数据库不同，模式不是严格分离的：只要有权限，一个用户可以访问他所连接的数据库中的任意模式中的对象。

我们需要模式的原因有好多：

- 允许多个用户使用一个数据库而不会干扰其它用户。
- 把数据库对象组织成逻辑组，让它们更便于管理。
- 第三方的应用可以放在不同的模式中，这样它们就不会和其它对象的名字冲突。

模式类似于[操作系统](http://msd.misuland.com/pd/3691884927646699782)层次的目录，只不过模式不能嵌套。

### 什么是表空间?

表空间是实际的数据存储的地方。一个数据库`schema`可能存在于多个表空间，相似地，一个表空间也可以为多个`schema`服务。

通过使用表空间，管理员可以控制磁盘的布局。表空间的最常用的作用是优化性能，例如，一个最常用的索引可以建立在非常快的硬盘上，而不太常用的表可以建立在便宜的硬盘上，比如用来存储用于进行归档文件的表。

### PostgreSQL表空间、数据库、模式、表、用户、角色之间的关系

#### 角色与用户的关系

在`PostgreSQL`中，存在两个容易混淆的概念：角色/用户。之所以说这两个概念容易混淆，是因为对于PostgreSQL来说，这是完全相同的两个对象。唯一的区别是在创建的时候：

1. 我用下面的`psql`创建了角色`custom`:

```sql
CREATE ROLE custom PASSWORD 'custom';
```

接着我使用新创建的角色custom登录，PostgreSQL给出拒绝信息：

```
FATAL：role 'custom' is not permitted to log in.
```

*说明该角色没有登录权限，系统拒绝其登录*

1. 我又使用下面的`psql`创建了用户`guest`:

```sql
CREATE USER guest PASSWORD 'guest';
```

*接着我使用guest登录，登录成功*

难道这两者有区别吗？查看文档，又这么一段说明：CREATE USER is the same as CREATE ROLE except that it implies LOGIN. ----`CREATE USER`除了默认具有`LOGIN`权限之外，其他与`CREATE ROLE`是完全相同的。

为了验证这句话，修改`custom`的权限，增加`LOGIN`权限：

```sql
ALTER ROLE custom LOGIN;
```

再次用`custom`登录，成功！那么事情就明了了：

CREATE ROLE custom PASSWORD 'custom' LOGIN 等同于 CREATE USER custom PASSWORD 'custom'.

这就是`ROLE/USER`的区别。

#### 数据库与模式的关系

`模式(schema)`是对数据库(database)逻辑分割。

在数据库创建的同时，就已经默认为数据库创建了一个模式--`public`，这也是该数据库的默认模式。所有为此数据库创建的对象(表、函数、试图、索引、序列等)都是创建在这个模式中的：

1. 创建一个数据库mars

```sql
CREATE DATABASE mars;
```

1. 用`custom`角色登录到`mars`数据库,查看数据库中的所有模式：\dn



显示结果只有`public`一个模式。

1. 创建一张测试表

```sql
CREATE TABLE test(id integer not null);
```

1. 查看当前数据库的列表：\d;



显示结果是表test属于模式`public`.也就是`test`表被默认创建在了public模式中。

1. 创建一个新模式`custom`，对应于登录用户`custom`：

```sql
CREATE SCHEMA custom;

ALTER SCHEMA custom OWNER TO custom;
```

1. 再次创建一张`test`表，这次这张表要指明模式

```sql
CREATE TABLE custom.test (id integer not null);
```

1. 查看当前数据库的列表： \d



显示结果是表`test`属于模式`custom`.也就是这个`test`表被创建在了`custom模式`中。

得出结论是：数据库是被模式(schema)来切分的，一个数据库至少有一个模式，所有数据库内部的对象(object)是被创建于模式的。用户登录到系统，连接到一个数据库后，是通过该数据库的search_path来寻找schema的搜索顺序，可以通过命令`SHOW search_path`；具体的顺序，也可以通过`SET search_path TO 'schema_name'`来修改顺序。

>  
>
> 官方建议是这样的：在管理员创建一个具体数据库后，应该为所有可以连接到该数据库的用户分别创建一个与用户名相同的模式，然后，将`search_path`设置为`$user`，即默认的模式是与用户名相同的模式。

#### 表空间与数据库的关系

数据库创建语句:

```sql
CREATE DATABASE dbname;
```

默认的数据库所有者是当前创建数据库的角色，默认的表空间是系统的默认表空间pg_default。

为什么是这样的呢？

因为在`PostgreSQL`中，数据的创建是通过克隆数据库模板来实现的，这与SQL SERVER是同样的机制。由于`CREATE DATABASE dbname`并没有指明数据库模板，所以系统将默认克隆`template1`数据库，得到新的数据库`dbname`。(By default, the new database will be created by cloning the standard system database template1)

`template1`数据库的默认表空间是`pg_default`，这个表空间是在数据库初始化时创建的，所以所有`template1`中的对象将被同步克隆到新的数据库中。

相对完整的语法应该是这样的：

```sql
CREATE DATABASE dbname TEMPLATE template1 TABLESPACE tablespacename;
ALTER DATABASE dbname OWNER TO custom;
```

1. 连接到`template1`数据库，创建一个表作为标记：

```sql
CREATE TABLE test(id integer not null);
```

向表中插入数据

```sql
INSERT INTO test VALUES (1);
```

1. 创建一个表空间:

```sql
CREATE TABLESPACE tsmars OWNER custom LOCATION '/tmp/data/tsmars';
```

在此之前应该确保目录**/tmp/data/tsmars**存在，并且目录为空。

1. 创建一个数据库，指明该数据库的表空间是刚刚创建的`tsmars`：

```sql
CREATE DATABASE dbmars TEMPLATE template1 OWNERE custom TABLESPACE tsmars;
ALTER DATABASE dbmars OWNER TO custom;
```

1. 查看系统中所有数据库的信息：\l+



可以发现，`dbmars`数据库的表空间是`tsmars`,拥有者是`custom`;

仔细分析后，不难得出结论：

在PostgreSQL中，表空间是一个目录，里面存储的是它所包含的数据库的各种物理文件。

### 总结

表空间是一个存储区域，在一个表空间中可以存储多个数据库，尽管PostgreSQL不建议这么做，但我们这么做完全可行。一个数据库并不知直接存储表结构等对象的，而是在数据库中逻辑创建了至少一个模式，在模式中创建了表等对象，将不同的模式指派该不同的角色，可以实现权限分离，又可以通过授权，实现模式间对象的共享，并且还有一个特点就是：public模式可以存储大家都需要访问的对象。

表空间用于定义数据库对象在物理存储设备上的位置，不特定于某个单独的数据库。数据库是数据库对象的物理集合，而`schema`则是数据库内部用于组织管理数据库对象的逻辑集合，schema名字空间之下则是各种应用程序会接触到的对象，比如表、索引、数据类型、函数、操作符等。

角色(用户)则是数据库[服务器](http://msd.misuland.com/pd/3691884927646700952)(集群)全局范围内的权限控制系统，用于各种集群范围内所有的对象权限管理。因此角色不特定于某个单独的数据库，但角色如果需要登录数据库管理系统则必须连接到一个数据库上。角色可以拥有各种数据库对象。