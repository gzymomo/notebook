[CentOS7下安装mysql5.7](https://blog.csdn.net/wohiusdashi/article/details/89358071)

# 一、安装YUM Repo

### 1、由于CentOS 的yum源中没有mysql，需要到mysql的官网下载yum repo配置文件。

下载命令：

wget https://dev.mysql.com/get/mysql57-community-release-el7-9.noarch.rpm

### 2、然后进行repo的安装：

rpm -ivh mysql57-community-release-el7-9.noarch.rpm

执行完成后会在/etc/yum.repos.d/目录下生成两个repo文件mysql-community.repo mysql-community-source.repo

# 二、使用yum命令即可完成安装

**注意：必须进入到 /etc/yum.repos.d/目录后再执行以下脚本**

### 1、安装命令：

yum install mysql-server

### 2、启动msyql：

systemctl start mysqld #启动MySQL

### 3、获取安装时的临时密码（在第一次登录时就是用这个密码）：

grep 'temporary password' /var/log/mysqld.log

### 4、倘若没有获取临时密码，则

4.1、删除原来安装过的mysql残留的数据

rm -rf /var/lib/mysql

4.2.再启动mysql

systemctl start mysqld #启动MySQL

# 三、登录：

### 1、方式一（已验证）：

mysql -u root -p

然后输入密码（刚刚获取的临时密码）