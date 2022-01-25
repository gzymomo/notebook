- [MySQL 数据库定时备份总结](https://blog.51cto.com/u_7932852/4957975)

## 数据库备份的分类

数据库备份方式分很多种，从影响数据库的角度划分：

- 热备份: 读写不受影响
- 温备份: 仅可以执行读操作
- 冷备份: 离线备份, 读写操作均中止

从备份方式划分：

- 物理备份：值对数据库操作系统的物理文件（如数据文件、日志文件等）的备份。
- 逻辑备份：指对数据库逻辑组件 （如表等数据库对象）的备份。

从备份策略划分：

- 完全备份：每次对数据库进行完整备份。可以备份整个数据库，包含用户表、系统表、索引、视图和存储过程中所有数据库对象。但它需要花费更多的时间和空间，所以，做一次完全备份的周期要长些。
- 差异备份：备份那些自从上次完全备份之后被修改过的文件，值备份数据库的部分内容，比完全备份小，因此存储和恢复速度快。
- 增量备份：只有那些在上次完全备份或者增量备份后修改的文件才会被备份。

![image-20220120083809083.png](https://s4.51cto.com/images/blog/202201/20145941_61e9085d59ad626162.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)

## MySQL数据备份

### mysqldump命令备份数据

在MySQL中提供了命令行导出数据库数据以及文件的一种方便的工具**mysqldump** ,我们可以通过命令行直接实现数据库内容的导出dump,首先我们简单了解一下mysqldump命令用法:

```
#MySQLdump常用
mysqldump -u root -p --databases 数据库1 数据库2 > xxx.sql
```

### mysqldump常用操作示例

备份全部数据库的数据和结构

```
mysqldump -uroot -proot -A > /data/mysqlDump/mydb.sql
```

- 备份全部数据库的结构（加 -d 参数）

```
mysqldump -uroot -proot -A -d > /data/mysqlDump/mydb.sql
```

- 备份全部数据库的数据(加 -t 参数)

```
mysqldump -uroot -proot -A -t > /data/mysqlDump/mydb.sql
```

备份单个数据库的数据和结构(,数据库名mydb)

```
mysqldump -uroot-proot mydb > /data/mysqlDump/mydb.sql
```

- 备份单个数据库的结构

```
mysqldump -uroot -proot mydb -d > /data/mysqlDump/mydb.sql
```

- 备份单个数据库的数据

```
mysqldump -uroot -proot mydb -t > /data/mysqlDump/mydb.sql
```

- 备份多个表的数据和结构（数据，结构的单独备份方法与上同）

```
mysqldump -uroot -proot mydb t1 t2 > /data/mysqlDump/mydb.sql
```

- 一次备份多个数据库

```
mysqldump -uroot -proot --databases db1 db2 > /data/mysqlDump/mydb.sql
```

### MySQL 还原备份数据

有两种方式还原，第一种是在 MySQL 命令行中，第二种是使用 SHELL 行完成还原

- 在系统命令行中，输入如下实现还原：

```
mysql -uroot -proot < /data/mysqlDump/mydb.sql
```

- 在登录进入mysql系统中,通过source指令找到对应系统中的文件进行还原：

```
mysql> source /data/mysqlDump/mydb.sql
```

## 编写脚本维护备份的数据库文件

在 Linux中，通常使用**BASH** 脚本对需要执行的内容进行编写，加上定时执行命令**crontab** 实现日志自动化生成。

以下代码功能就是针对mysql进行备份，配合crontab，实现备份的内容为近一个月（31天）内的每天的mysql数据库记录。

### 编写BASH维护固定数量备份文件

在Linux中，使用vi或者vim编写脚本内容并命名为：mysql_dump_script.sh

```
#!/bin/bash

#保存备份个数，备份31天数据
number=31
#备份保存路径
backup_dir=/root/mysqlbackup
#日期
dd=`date +%Y-%m-%d-%H-%M-%S`
#备份工具
tool=mysqldump
#用户名
username=root
#mima
password=TankB214
#将要备份的数据库
database_name=edoctor

#如果文件夹不存在则创建
if [ ! -d $backup_dir ];
then   
    mkdir -p $backup_dir;
fi

#简单写法 mysqldump -u root -proot users > /root/mysqlbackup/users-$filename.sql
$tool -u $username -p$password $database_name > $backup_dir/$database_name-$dd.sql

#写创建备份日志
echo "create $backup_dir/$database_name-$dd.dupm" >> $backup_dir/log.txt

#找出需要删除的备份
delfile=`ls -l -crt $backup_dir/*.sql | awk '{print $9 }' | head -1`

#判断现在的备份数量是否大于$number
count=`ls -l -crt $backup_dir/*.sql | awk '{print $9 }' | wc -l`

if [ $count -gt $number ]
then
  #删除最早生成的备份，只保留number数量的备份
  rm $delfile
  #写删除文件日志
  echo "delete $delfile" >> $backup_dir/log.txt
fi
```

如上代码主要含义如下：

1.首先设置各项参数，例如number最多需要备份的数目，备份路径，用户名等。

2.执行mysqldump命令保存备份文件，并将操作打印至同目录下的log.txt中标记操作日志。

3.定义需要删除的文件：通过ls命令获取第九列，即文件名列，再通过实现定义操作时间最晚的那个需要删除的文件。

4.定义备份数量：通过ls命令加上

统计以sql结尾的文件的行数。

5.如果文件超出限制大小，就删除最早创建的sql文件

### 使用crontab定期执行备份脚本

在 Linux 中，周期执行的任务一般由cron这个守护进程来处理[ps -ef|grep cron]。cron读取一个或多个配置文件，这些配置文件中包含了命令行及其调用时间。cron的配置文件称为“crontab”，是“cron table”的简写。

#### cron服务

cron是一个 Liunx 下 的定时执行工具，可以在无需人工干预的情况下运行作业。

service crond start //启动服务 service crond stop //关闭服务 service crond  restart //重启服务 service crond reload //重新载入配置 service crond status  //查看服务状态

#### crontab语法

crontab命令用于安装、删除或者列出用于驱动cron后台进程的表格。用户把需要执行的命令序列放到crontab文件中以获得执行。每个用户都可以有自己的crontab文件。/var/spool/cron下的crontab文件不可以直接创建或者直接修改。该crontab文件是通过crontab命令创建的。

在crontab文件中如何输入需要执行的命令和时间。该文件中每行都包括六个域，其中前五个域是指定命令被执行的时间，最后一个域是要被执行的命令。每个域之间使用空格或者制表符分隔。

格式如下：minute hour day-of-month month-of-year day-of-week commands 合法值 00-59 00-23 01-31 01-12 0-6 (0 is sunday)

除了数字还有几个个特殊的符号就是"_"、"/"和"-"、","，_代表所有的取值范围内的数字，"/"代表每的意思,"/5"表示每5个单位，"-"代表从某个数字到某个数字,","分开几个离散的数字。

-l 在标准输出上显示当前的crontab。-r 删除当前的crontab文件。-e 使用VISUAL或者EDITOR环境变量所指的编辑器编辑当前的crontab文件。当结束编辑离开时，编辑后的文件将自动安装。

#### 创建cron脚本

第一步：写cron脚本文件,命名为mysqlRollBack.cron。15,30,45,59     echo "xgmtest....." >> xgmtest.txt 表示，每隔15分钟，执行打印一次命令  第二步：添加定时任务。执行命令 “crontab crontest.cron”。搞定 第三步："crontab -l"  查看定时任务是否成功或者检测/var/spool/cron下是否生成对应cron脚本

注意：这操作是直接替换该用户下的crontab，而不是新增

定期执行编写的定时任务脚本（记得先给shell脚本执行权限）

```
0 2 * * * /root/mysql_backup_script.sh
```

随后使用crontab命令定期指令编写的定时脚本

```
crontab mysqlRollback.cron
```

再通过命令检查定时任务是否已创建。

#### crontab 的使用示例：

- 每天早上6点

```
0 6 * * * echo "Good morning." >> /tmp/test.txt //注意单纯echo，从屏幕上看不到任何输出，因为cron把任何输出都email到root的信箱了。
```

- 每两个小时

```
0 */2 * * * echo "Have a break now." >> /tmp/test.txt
```

- 晚上11点到早上8点之间每两个小时和早上八点

```
0 23-7/2，8 * * * echo "Have a good dream" >> /tmp/test.txt
```

- 每个月的4号和每个礼拜的礼拜一到礼拜三的早上11点

```
0 11 4 * 1-3 command line
```

- 1 月 1 日早上 4 点

```
0 4 1 1 * command line SHELL=/bin/bash PATH=/sbin:/bin:/usr/sbin:/usr/bin MAILTO=root //如果出现错误，或者有数据输出，数据作为邮件发给这个帐号 HOME=/
```

- 每小时执行/etc/cron.hourly内的脚本

```
01 * * * * root run-parts /etc/cron.hourly
```

- 每天执行/etc/cron.daily内的脚本

```
02 4 * * * root run-parts /etc/cron.daily
```

- 每星期执行/etc/cron.weekly内的脚本

```
22 4 * * 0 root run-parts /etc/cron.weekly
```

- 每月去执行/etc/cron.monthly内的脚本

```
42 4 1 * * root run-parts /etc/cron.monthly
```

> 注意: "run-parts" 这个参数了，如果去掉这个参数的话，后面就可以写要运行的某个脚本名，而不是文件夹名。

- 每天的下午4点、5点、6点的5 min、15 min、25 min、35 min、45 min、55 min时执行命令。

```
5，15，25，35，45，55 16，17，18 * * * command
```

- 每周一，三，五的下午3：00系统进入维护状态，重新启动系统。

```
00 15 * * 1，3，5 shutdown -r +5
```

- 每小时的10分，40分执行用户目录下的innd/bbslin这个指令：

```
10，40 * * * * innd/bbslink
```

- 每小时的1分执行用户目录下的bin/account这个指令：