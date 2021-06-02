[MySQL索引分析以及相关面试题](https://csp1999.blog.csdn.net/article/details/113833541)



## 1. 什么是索引

- 一种能帮助mysql提高查询效率的数据结构：**索引数据结构**
- 索引优点：
  - 大大提高数据查询速度
- 索引缺点：
  - 维护索引需要耗费数据库资源
  - 索引要占用磁盘空间
  - 当对表的数据进行增删改的时候，因为要维护索引，所以速度收到影响
- 结合索引的优缺点，得出结论：数据库表并不是索引加的越多越好，而是仅为那些常用的搜索字段建立索引效果才是最佳的！

## 2. 索引的分类

- 主键索引：PRIMARY KEY
  - 设定为逐渐后，数据库自动建立索引，innodb为聚簇索引，主键索引列值不能有空(Null)
- 单值索引：又叫单列索引、普通索引
  - 即，一个索引只包含单个列，一个表可以有多个单列索引
- 唯一索引
  - 索引列的值必须唯一，但允许有空值(Null)，但只允许有一个空值(Null)
- 复合索引
  - 即，一个索引可以包含多个列，多个列共同构成一个复合索引！
  - eg: `SELECT id (name age) INDEX WHERE name AND age;`
- 全文索引：Full Text  （MySQL5.7之前，只有MYISAM存储引擎支持全文索引）
  - 全文索引类型为FULLTEXT，在定义索引的列上支持值的全文查找，允许在这些索引列中插入重复值和空值。全文索引可以在**Char** 、**Varchar** 上创建。

## 3. 索引的基本操作

### 3.1 主键索引创建

```sql
-- 建表语句：建表时，设置主键，自动创建主键索引
CREATE TABLE t_user (
	id VARCHAR(20) PRIMARY KEY,
    name VARCHAR(20)
);

-- 查看索引
SHOW INDEX FROM t_user;
```

![在这里插入图片描述](https://img-blog.csdnimg.cn/20210216180359313.png)

### 3.2 单列索引创建(普通索引/单值索引)

```sql
-- 建表时创建单列索引：
-- 这种方式创建单列索引，其名称默认为字段名称：name
CREATE TABLE t_user (
	id VARCHAR(20) PRIMARY KEY,
    name VARCHAR(20)，
    KEY(name)
);

-- 建表后创建单列索引：
-- 索引名称为：name_index 格式---> 字段名称_index
CREATE INDEX name_index ON t_user(name)

-- 删除单列索引
DROPINDEX 索引名称 ON 表名
```

![在这里插入图片描述](https://img-blog.csdnimg.cn/20210216181232671.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dlaXhpbl80MzU5MTk4MA==,size_16,color_FFFFFF,t_70)

### 3.3 唯一索引创建

```sql
-- 建表时创建唯一索引：
CREATE TABLE t_user2 (
	id VARCHAR(20) PRIMARY KEY,
    name VARCHAR(20),
    UNIQUE(name)
);

-- 建表后创建唯一索引：
CREATE UNIQUE INDEX name_index ON t_user2(name);
```

![在这里插入图片描述](https://img-blog.csdnimg.cn/20210216182122663.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dlaXhpbl80MzU5MTk4MA==,size_16,color_FFFFFF,t_70)

### 3.4 复合索引创建

```sql
-- 建表时创建复合索引：
CREATE TABLE t_user3 (
	id VARCHAR(20) PRIMARY KEY,
    name VARCHAR(20),
    age INT,
    KEY(name,age)
);

-- 建表后创建复合索引：
CREATE INDEX name_age_index ON t_user3(name,age);

-- 复合索引查询的2个原则
-- 1.最左前缀原则
-- eg: 创建复合索引时，字段的顺序为 name,age,birthday
-- 在查询时能利用上索引的查询条件为： 
SELECT * FROM t_user3 WHERE name = ?
SELECT * FROM t_user3 WHERE name = ? AND age = ?
SELECT * FROM t_user3 WHERE name = ? AND birthday = ?
SELECT * FROM t_user3 WHERE name = ? AND age = ? AND birthday = ?
-- 而其他顺序则不满足最左前缀原则：
... WHERE name = ? AND birthday = ? AND age = ? -- 不满足最左前缀原则
... WHERE name = ? AND birthday = ? -- 不满足最左前缀原则
... WHERE birthday = ? AND age = ? AND name = ? -- 不满足最左前缀原则
... WHERE age = ? AND birthday = ? -- 不满足最左前缀原则


-- 2.MySQL 引擎在执行查询时，为了更好地利用索引，在查询过程中会动态调整查询字段的顺序！
-- 这时候再来看上面不满足最左前缀原则的四种情况：
-- 不满足最左前缀原则，但经过动态调整顺序后，变为：name age birthday 可以利用复合索引！
... WHERE name = ? AND birthday = ? AND age = ? 
-- 不满足最左前缀原则，也不能动态调整（因为缺少age字段），不可以利用复合索引！
... WHERE name = ? AND birthday = ? 
-- 不满足最左前缀原则，但经过动态调整顺序后，变为：name age birthday 可以利用复合索引！
... WHERE birthday = ? AND age = ? AND name = ?
-- 不满足最左前缀原则，也不能动态调整（因为缺少name字段），不可以利用复合索引！
... WHERE age = ? AND birthday = ?
```



![在这里插入图片描述](https://img-blog.csdnimg.cn/20210216182654176.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dlaXhpbl80MzU5MTk4MA==,size_16,color_FFFFFF,t_70)

## 4. MySQL索引的数据结构(B+Tree)

```sql
-- 建表：
CREATE TABLE t_emp(
	id INT PRIMARY KEY,
    name VARCHAR(20),
    age INT
);

-- 插入数据：插入时，主键无序
INSERT INTO t_emp VALUES(5,'d',22);
INSERT INTO t_emp VALUES(6,'d',22);
INSERT INTO t_emp VALUES(7,'3',21);
INSERT INTO t_emp VALUES(1,'a',23);
INSERT INTO t_emp VALUES(2,'b',26);
INSERT INTO t_emp VALUES(3,'c',27);
INSERT INTO t_emp VALUES(4,'a',32);
INSERT INTO t_emp VALUES(8,'f',53);
INSERT INTO t_emp VALUES(9,'b',13);

-- 查询：自动排序，有序展示（因为主键是有主键索引的，因此会自动排序）
```

![在这里插入图片描述](https://img-blog.csdnimg.cn/20210216190631632.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dlaXhpbl80MzU5MTk4MA==,size_16,color_FFFFFF,t_70)

`问题：为什么数据插入时，未按照主键顺序，而查询时却是有序的呢`？

- 原因：MySQL底层为主键自动创建索引，一旦创建了索引，就会进行排序！
- 实际上这些数据在MySQL底层的真正存储结构变成了下面这种方式：

![在这里插入图片描述](https://img-blog.csdnimg.cn/20210216204844625.png)



```
问题：为什么要排序呢？
```

- 因为排序之后查询效率就快了，比如查询 `id = 3` 的数据，只需要按照顺序去找即可，而如果不排序，就如同大海捞针，假如100W条数据，可能有时候需要随机查询100W次才找到这个数据，也可能运气好上来第1次就查询到了该数据，不确定性太高！

### 4.1 原理分析图



![在这里插入图片描述](https://img-blog.csdnimg.cn/20210216203808263.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dlaXhpbl80MzU5MTk4MA==,size_16,color_FFFFFF,t_70)



- 上图这种分层`树`结构查询效率较高，因为如果我需要查询 `id=4`的数据，只需要在页目录中匹配，大于3且小于5，则去3对应的`page=2`中查找数据，这样就不需要从第1页开始检索数据了，大大提高了效率！
- 从上图可得出，在只有2层的结构下，1page 可以存储记录总数为 `1365 * 455 ≈ 62万条`，而如果再加1层结构，来存储page层分页目录数据的分页层PAGE的话，那么1PAGE可以存储总page数为：`1365 * 1365 ≈ 186万条page  `，而1PAGE存储的总记录数为 `1365 * 1365 * 455 ≈ 8.5 亿条`。因此，我们平时使用的话，2层结构就已经足够了！实际上1个页存储的总数据树可能大于理论估计的，因为我们分配name字段的`VARCHAR(20)`占20个字节，而实际上可能存储的name数据并没有20个字节，可能更小！

> 三层结构实例如图：

### 4.2 B+树结构分析

> 上图4.1 原理分析图中这种索引结构称之为B+树数据结构，那么什么是B+树呢？B树和B+树区别是什么呢?
>
> 详情参考文章：https://www.cnblogs.com/lianzhilei/p/11250589.html

**问题4.2.1 为什么InnoDB底层使用B+树做索引而不用B树？**

B树结构图：



![在这里插入图片描述](https://img-blog.csdnimg.cn/20210216205444306.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dlaXhpbl80MzU5MTk4MA==,size_16,color_FFFFFF,t_70)



- 从上面的B树结构图中分析得出，B树每个节点中不仅包含数据的key，还有data数据。而每个页的存储空间是有限的，如果data数据较大时，讲会导致每个节点(即一个页16KB)能存储的key的数量较少，当存储数据量很大时，会造成B树的深度较大，增大查询时的磁盘读取I/O次数，进而影响查询效率。(**树的深度影响I/O读取次数**)
- 在上一小节的B+树结构图分析中，所有数据记录都是按照键值大小顺序存放在同一层的叶子节点上，而非叶子节点上只能存储key值信息，这样可以大大增加每个节点(即一个页16KB)能存储的key的数量，进而可以降低树的高度，进而减少磁盘读取I/O次数，提高查询效率
- 所以B树和B+树的区别就在于：
  - B+树只有叶子节点存储数据记录
  - B+树非叶子节点只存储键值信息（B树的非叶子也存数据记录）
  - 所有节点直接都有一个链指针
- InnoDB存储引擎中，页的大小为16KB，一般表的主键类型为INT(占用4个字节) 或 BIGINT(占用8个字节)，指针类型也一般占4或8个字节，也就是说，一个页(B+树中的一个节点)中大概可以存储`16KB/(8B+8B)=1000`个键值(只是估计值，方便计算而已)。也就是说，一个深度为3的B+树索引可以维护`10^3 * 10^3 * 10^3 = 10亿`条记录。
- 实际情况中每个节点可能不能填充满，因此在数据库中，B+树的高度一般是**2~4层**。**MySQL的InnoDB存储引擎在设计时是将根节点常驻在内存中（不需要动磁盘I/O）**的，也就是说**查找某个键值的行记录最多只需要1~3次I/O操作**！（**每查询一层都需要动用一次磁盘I/O**）

## 5. 聚簇索引和非聚簇索引

### 5.1 聚簇索引和非聚簇索引分析

> 在表中，聚簇索引实际上就是指的是主键索引！如果表中没有主键的话，则MySQL会根据该表生成一个RoleID，拿这个RoleId当做聚簇索引！

- **聚簇索引**：`将数据存储与索引放到一起`，索引结构的叶子节点保存了每行的数据。例如：4.1小结分析图中的data层一个单位就是聚簇索引存储数据的例子，主键**id** 字段就是聚簇索引，4.1小结分析图就是基于主键索引(聚簇索引)构成的B+树结构！**聚簇索引不一定是主键索引，但是主键索引肯定是聚簇索引**！

  

  ![在这里插入图片描述](https://img-blog.csdnimg.cn/20210216221249506.png)

- **非聚簇索引**：`将数据与索引分开存储`，索引结构的叶子节点指向了数据对应的位置(聚簇索引的值)！非聚簇索引检索数据是在自己的 “树” 上进行查找，例如我们根据表中的非聚簇索引**name**字段去查找数据时，流程如下图：

  

  ![在这里插入图片描述](https://img-blog.csdnimg.cn/20210217103935455.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dlaXhpbl80MzU5MTk4MA==,size_16,color_FFFFFF,t_70)

  再看一张比较正规的分析图：

  

  ![在这里插入图片描述](https://img-blog.csdnimg.cn/20210217104043141.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dlaXhpbl80MzU5MTk4MA==,size_16,color_FFFFFF,t_70)

**注意**：在InnoDB中，在聚簇索引之上创建的索引称之为**辅助索引**，例如：复合索引、单列索引、唯一索引。**一个表中只能有1个聚簇索引，而其他索引都是辅助索引**！辅助索引的叶子节点存储的不再是行的物理位置，而是主键的值，**辅助索引访问数据总是需要二次查找的**！

> **问题5.1.1 **：为什么非聚簇索引(name字段的单列索引)构成的树，其叶子节点存储聚簇索引(主键id)，而不直接存储行数据的物理地址呢？
>
> 换个方式问：非聚簇索引检索数据时，检索一次本树再去聚簇索引树中检索一次，这样二次检索树结构，那么为什么不直接在非聚簇索引树叶子节点中存放行数据物理地址，这样只需要检索一次树结构就拿到行数据呢？

这里画个图方便理解一些：



![在这里插入图片描述](https://img-blog.csdnimg.cn/20210217110736525.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dlaXhpbl80MzU5MTk4MA==,size_16,color_FFFFFF,t_70)

​        从上图得出，在做新增数据时，因为底层是需要基于主键索引进行排序的，那么就可能导致原来某些**数据对应的物理地址发生了变化**，而这时候由于我们的非聚簇索引树的叶子节点直接存储了数据的物理地址，所以为了保证能获取到数据，还需要同时对非聚簇索引树叶子节点的地址进行一遍更新修改！

​        同理，如果我们不做插入主键id为4这行记录的操作，而是将其删除的话，这个流程可以自己思考一下！

​        也就是说：**之所以不在非聚簇索引树的叶子节点直接存放行数据的物理地址，是因为，存储数据的物理地址会随着数据库表的CRUD操作而不断变更，为了保证能获取到数据，这时必须要对非聚簇索引树相关叶子节点的地址进行一遍修改**！而存主键，主键不会随着CRUD操作发生变化，宁愿多查一次树，也不要再修改一次树的结构！

### 5.2 MySQL两种引擎中的(非)聚簇索引

> InnoDB中：

- InnoDB中使用的是聚簇索引，将**主键**组织到一颗B+树中，而行数据就存储在该B+树的叶子节点上，若使用`WHERE id = 4` 这样的条件查找主键，则按照B+树的检索算法即可查找对应的叶子节点，之后获得对应的行数据！

- 若对使用单列索引(非聚簇索引)的

  name

  字段进行搜索，则需要执行2个步骤：

  - 第一步：在辅助索引B+树中检索**name**，到达其对应的叶子节点后获得该字段对应行记录的**主键id**！
  - 第二步：使用**主键id**在主索引B+树中再次执行一次树的检索，最终到达对应的叶子节点并获取到行记录数据！

- **聚簇索引默认是主键**，如果表中没有定义主键，InnoDB会选择一个**唯一且非空的索引**代替主键作为聚簇索引。而如果也没有这样的唯一非空索引，那么InnoDB就会**隐式定义一个主键**（类似于Oracle中的RowId）来做为聚簇索引。

- 如果已经设置了聚簇索引又希望再单独设置聚簇索引，则必须先删除主键，然后添加我们想要的聚簇索引，最后再恢复主键即可！

> MYISAM中：

- MYISAM使用的是非聚簇索引，**非聚簇索引的两颗B+树看上去没有什么不同**，节点的结构完全一致，只是存储的内容不同，主键索引B+树的节点存储了主键，辅助索引B+树存储量辅助键。

- 表数据存储在独立的地方，这两颗B+树的叶子节点都使用一个地址指针指向真正的表数据，对于表数据来说，这两个键没有任何差别。

- **由于索引树是独立的，通过辅助键检索无需再次检索主键索引树**！

  

  ![在这里插入图片描述](https://img-blog.csdnimg.cn/20210217113632138.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dlaXhpbl80MzU5MTk4MA==,size_16,color_FFFFFF,t_70)

### 5.3 聚簇索引和非聚簇索引的优/劣势

> 问题：5.3.1 使用聚簇索引的优势

**问题**：每次使用辅助索引检索都需要经过2次B+树查找，看上去聚簇索引的效率明显要低于非聚簇索引，那么聚簇索引的优势何在呢？

```sql
-- 1.由于行数据和聚簇索引树的叶子节点存储在一起，同一页中会有多条行数据，首次访问数据页中某条行记录时，会把该数据页数据加载到Buffer(缓存器)中，当再次访问该数据页中其他记录时，不必访问磁盘而直接在内存中完成访问。
-- 注：主键id和行数据一起被载入内存，找到对应的叶子节点就可以将行数据返回了，如果按照主键id来组织数据，获取数据效率更快！

-- 2.辅助索引的叶子节点，存储主键的值，而不是行数据的存放地址。这样做的好处是，因为叶子节点存放的是主键值，其占据的存储空间小于存放行数据物理地址的储存空间
```

> 问题：5.3.2 使用聚簇索引需要注意什么？

```sql
-- 当使用主键为聚簇索引时，而不要使用UUID方式，因为UUID的值太过离散，不适合排序，导致索引树调整复杂度增加，消耗更多时间和资源。

-- 建议主键最好使用INT/BIGINT类型，且为自增，这样便于排序且默认会在索引树的末尾增加主键值，对索引树的结构影响最小(下面主键自增的问题会解释原因)。而且主键占用的存储空间越大，辅助索引中保存的主键值也会跟着增大，占用空间且影响IO操作读取数据！
```

> 问题：5.3.3 为什么主键通常建议使用自增id？

```sql
-- 聚簇索引树存放数据的物理地址(xx1,xx2,xx3,xxx5)与索引顺序(1,2,3,5)是一致的，即：
-- 1.只要索引是相邻的，那么在磁盘上索引对应的行数据存放地址也是相邻的。
-- 2.如果主键是自增，那么当插入新数据时，只需要按照顺序在磁盘上开辟新物理地址存储新增行数据即可。
-- 3.而如果不是主键自增，那么当新插入数据后，会对索引进行重新排序(重新调整B+树结构)，磁盘上的物理存储地址也需要重新分配要存储的行数据！
```

![在这里插入图片描述](https://img-blog.csdnimg.cn/20210217124145727.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dlaXhpbl80MzU5MTk4MA==,size_16,color_FFFFFF,t_70)

> 问题：5.3.4 什么情况下无法利用索引呢？

```sql
-- 1. 查询语句中使用LIKE关键字：（这种情况主要是针对于单列索引）
-- 在使用LIKE关键字查询时，如果匹配字符串的第一个字符为'%'，则索引不会被使用，而'%'不在最左边，而是在右边，则索引会被使用到！
-- eg:
SELECT * FROM t_user WHERE name LIKE 'xx%' -- 可以利用上索引,这种情况下可以拿xx到索引树上去匹配
SELECT * FROM t_user WHERE name LIKE '%xx%' -- 不可以利用上索引
SELECT * FROM t_user WHERE name LIKE '%xx' -- 不可以利用上索引

-- 2. 查询语句中使用多列索引：（这种情况主要是针对于聚合索引）
-- 多索引是在表的多个字段创建索引，只有查询条件中使用了这些字段中的第一个字段，索引才会被使用。即：最左前缀原则，详情查看3.4小结聚合索引中的介绍！

-- 3. 查询语句中使用OR关键字：
-- 查询条件中有OR关键字时，如果OR前后的两个条件列都具有索引，则查询中索引将被使用，而如果OR前后有一个或2个列不具有索引，那么查询中索引将不被使用到！
```

## 6. 什么是约束以及分类

> 约束:

- 作用：是为了**保证数据的完整性**而实现的摘自一套机制，即(约束是针对表中数据记录的)

- MySQL中的约束：

  - 非空约束：**NOT NULL**  保证某列数据不能存储NULL 值;
  - 唯一约束：**UNIQUE(字段名)**  保证所约束的字段，数据必须是唯一的，允许数据是空值(Null)，但只允许有一个空值(Null)；
  - 主键约束：**PRIMARY KEY(字段名)**  `主键约束= 非空约束 + 唯一约束` 保证某列数据不能为空且唯一；
  - 外键约束：**FOREIGN KEY(字段名)**  保证一个表中某个字段的数据匹配另一个表中的某个字段，可以建立表与表直接的联系；
  - 自增约束：**AUTO_INCREMENT**  保证表中新插入数据时，某个字段数据可以依次递增；
  - 默认约束：**DEFALUT** 保证表中新插入数据时，如果某个字段未被赋值，则会有默认初始化值；
  - 检查性约束：**CHECK** 保证列中的数据必须符合指定的条件；

- 示例：

```sql
create table member( 
    id int(10), 
    phone int(15) unsigned zerofill, 
    name varchar(30) not null, 
    constraint uk_name unique(name), 
    constraint pk_id primary key (id), 
    constraint fk_dept_id foreign key (dept_id，字段2) 
    references dept(主表1)(dept_id) 
);
```