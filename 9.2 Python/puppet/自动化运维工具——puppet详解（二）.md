- [自动化运维工具——puppet详解（二）](https://www.cnblogs.com/keerya/p/8087675.html)

# 一、class 类

## 1.1 什么是类？

类是puppet中命名的代码模块，常用于定义一组通用目标的资源，可在puppet全局调用；

类可以被继承，也可以包含子类；

具体定义的语法如下：

```
class NAME{
	... puppet code ...
}
```

其中，在我们定义的时候，需要注意的是：

- 类的名称只能以小写字母开头，可以包含小字字母、数字和下划线。
- 每个类都会引入一个新的变量scope ，这意味着在任何时候访问类中的变量时，都得使用其完全限定名称。

不过，在本地 scope 可以重新为 top scope 中的变量赋予一个新值。

下面，我们来看一个简单的例子：

```bash
vim class1.pp
	class redis {		#定义一个类
		package{'redis':
			ensure  => installed,
		}   ->

		file{'/etc/redis.conf':
			ensure  => file,
			source  => '/root/manifests/file/redis.conf',
			owner   => 'redis',
			group   => 'root',
			mode    => '0640',
			tag     => 'redisconf'
		}   ~>

		service{'redis':
			ensure  => running,
			enable  => true,
			hasrestart  => true,
			hasstatus   => true
		}
	}

	include redis	#调用类
```

注意：类只有被调用才会执行。include后可以跟多个类，直接用","隔开即可。

## 1.2 带有参数的类

我们定义的类也可以进行参数设置，可以进行参数的传递。

具体语法如下所示：

```
class NAME(parameter1, parameter2) {	#注意，大括号前有一个空格
	...puppet code...
}
```

我们来看一个例子：

```bash
vim class2.pp
	class instpkg($pkg) {
		package{"$pkg":
			ensure  => installed,
		}
	}

	class{"instpkg":			#给参数传入值
		pkg     => 'memcached',
	}
```

注意：**单个主机上**不能被**直接**声明**两次**。

如果对应的参数未传值的话，执行会报错。

但是我们可以在定义形参的时候，设定一个默认值，这样的话，我们不传入值的话，就会自动调用默认值：

```bash
vim class3.pp
	class instpkg($pkg='wget') {
		package{"$pkg":
			ensure  => installed,
		}
	}

	include instpkg
```

这样的话，我们直接使用`include`调用即可，就不需要给参数传入值了。

由上，我们可以总结出，调用类的方式有**两种**：

```
1. include CLASS_NAME1, CLASS_NAME2, ...
2. class{'CLASS_NAME':
       attribute => value,
   }
```

我们来看一个比较全面的例子：

首先，判断我们系统的版本，是6还是7，由此来确定，是安装`mysql`还是`mariadb`，同时，使用调用参数的方式来实现如上需求。

具体实现的代码如下：

```bash
vim dbserver.pp
	class dbserver($dbpkg='mariadb-server',$svc='mariadb') {	#定义类并给参数赋值
		package{"$dbpkg":
			ensure  => installed,
		}

		service{"$svc":
			ensure  => running,
			enable  => true,
			hasrestart  => true,
			hasstatus   => true,
		}
	}

	if $operatingsystem == 'CentOS' {
		if $operatingsystemmajrelease == '7' {
			include dbserver		#直接调用类
		} else {
			class{"dbserver":		#调用类并对参数重新赋值
				dbpkg   => 'mysql-server',
				svc     => 'mysqld'
			}
		}
	}
```

## 1.3 类的继承

类似于其它编程语言中的类的功能，puppet 的Class 可以被继承，也可以包含子类。

其定义的语法如下：

```
class SUB_CLASS_NAME inherits PARENT_CLASS_NAME {
	...puppet code...
}
```

下面我们来看一个例子：

```bash
vim class4.pp
	class redis {		#定义class类
		package{'redis':
			ensure  => installed,
		}

		service{'redis':
			ensure  => running,
			enable  => true,
		}
	}

	class redis::master inherits redis {		#调用父类
		file {'/etc/redis.conf':
			ensure  => file,
			source  => '/root/manifests/file/redis-master.conf',
			owner   => 'redis',
			group   => 'root',
		} 

		Service['redis'] {						#定义依赖关系
			subscribe   => File['/etc/redis.conf']
		}
	}

	class redis::slave inherits redis {			#调用父类
		file {'/etc/redis.conf':
			ensure  => file,
			source  => '/root/manifests/file/redis-slave.conf',
			owner   => 'redis',
			group   => 'root',
		} 

		Service['redis'] {						#定义依赖关系
			subscribe   => File['/etc/redis.conf']
		}
	}
```

一样的，我们的类在调用的时候，可以实现**修改原有值**和**额外新增属性**的功能。

### 1.3.1 新增属性

我们的继承父类的时候，可以定义一些父类原本没有的属性：

![新增属性](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171222212332475-788277314.png)

### 1.3.2 新增原有值

在继承的类中，我们可以在属性原有值的基础上，使用 +> 进行新增修改：

![新增原有值](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171222212332850-1488205981.png)

新增原有值

### 1.3.3 修改原有值

在继承的类中，我们可以直接把原有的值进行覆盖修改，使用 `=>`进行覆盖即可：

![修改原有值](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171222212333178-1102039935.png)

修改原有值

### 1.3.4 整体调用父类，并重写部分值

在继承的类中，我们还可以在整体调用的基础上，根据不同的需求，把父类中的部分值进行重写修改：

![整体调用父类，并重写部分值](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171222212333459-2007144891.png)

整体调用父类，并重写部分值

# 二、模板

模板通常以`erb`结尾。模板均使用`erb`语法。

关于`puppet`兼容的`erb`语法，我们可以去官方文档查看，下面附上官方文档地址：https://docs.puppet.com/puppet/latest/reference/lang_template_erb.html

以下，附上部分重要内容：

```
    <%= EXPRESSION %> — 插入表达式的值，进行变量替换
    <% CODE %> — 执行代码，但不插入值
    <%# COMMENT %> — 插入注释
    <%% or %%> — 插入%
```

接着我们来看一个实例：

## 2.1 实例1：puppet 模板实现修改 redis 端口地址

我们使用puppet 模板来实现，将redis 监听端口修改为本机的ip地址。

首先，我们先来定义一个`file.pp`文件，在该文件中调用我们的模板：

```bash
vim file.pp
	file{'/tmp/redis.conf':		#仅用于测试模板是否生效，所以放在tmp目录下
		ensure  => file,
		content => template('/root/manifests/file/redis.conf.erb'),		#调用模板文件
		owner   => 'redis',
		group   => 'root',
		mode    => '0640',
	}
```

接着，我们去修改配置文件的源，也就是我们的模板文件：

```bash
vim file/redis.conf.erb
	bind 127.0.0.1 <%= @ipaddress_eth0 %>	#修改监听端口
```

修改完成以后，我们就可以执行查看结果了：

```bash
	puppet apply -v file.pp
```

然后，我们去查看一下`/tmp/redis.conf`文件：

```bash
	vim /tmp/redis.conf
```

![监听端口](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171222212333615-1359926062.png)

监听端口

可以看出，我们的变量替换已经成功。

# 三、模块

## 3.1 什么是模块？

实践中，一般需要把manifest 文件分解成易于理解的结构，例如将类文件、配置文件甚至包括后面将提到的模块文件等分类存放，并且通过某种机制在必要时将它们整合起来。

这种机制即**模块**，它有助于以结构化、层次化的方式使用puppet，而puppet 则基于“模块自动装载器”。

从另一个角度来说，模块实际上就是一个按约定的、预定义的结构存放了多个文件或子目录的目录，目录里的这些文件或子目录必须遵循其**命名规范**。

## 3.2 模块的命名规范

模块的目录格式如下：

![目录格式](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171222212333756-2010854377.png)

目录格式

其中，每个文件夹中**存放的内容**及其**要求**如下：

- **MODULE NAME**：模块名称，模块名只能以小写字母开头，可以包含小写字母、数字和下划线；但不能使用"main"和"settings"；
- manifests/：必须要有
  - init.pp：必须一个类定义，类名称必须与模块名称相同；
- files/：静态文件；
  - 其中，每个文件的访问路径遵循：`puppet:///modules/MODULE_NAME/FILE_NAME`；
- templates/：
  - 其中，每个文件的访问路径遵循：`tempate('MOD_NAME/TEMPLATE_FILE_NAME')`；
- **lib/**：插件目录，常用于存储自定义的facts以及自定义类型；
- **spec/**：类似于tests目录，存储lib/目录下插件的使用帮助和范例；
- **tests/**：当前模块的使用帮助或使用范例文件；

## 3.3 实例：定义一个redis主从模块

下面我们就来看一个实例来具体的了解应该如何定义一个模块：

 1）我们先来创建对应的目录格式：

```bash
[root@master ~]# mkdir modules
[root@master ~]# cd modoules/
[root@master modules]# ls
[root@master modules]# mkdir -pv redis/{manifests,files,templates,tests,lib,spec}
mkdir: created directory ‘redis’
mkdir: created directory ‘redis/manifests’
mkdir: created directory ‘redis/files’
mkdir: created directory ‘redis/templates’
mkdir: created directory ‘redis/tests’
mkdir: created directory ‘redis/lib’
mkdir: created directory ‘redis/spec’
```

2）目录格式创建完成之后，我们就可以来创建对应的父类子类文件了。

首先，我们来创建父类文件：

```bash
[root@master modules]# cd redis/
[root@master redis]# vim manifests/init.pp 
	class redis {
		package{'redis':
			ensure  => installed,
		} ->

		service{'redis':
			ensure  => running,
			enable  => true,
			hasrestart  => true,
			hasstatus   => true,
			require => Package['redis'],
		}
	}
```

创建完成后，我们再来创建对应的子类文件：

```bash
[root@master redis]# vim manifests/master.pp
	class redis::master inherits redis {
		file {'/etc/redis.conf':
			ensure  => file,
			source  => 'puppet:///modules/redis/redis-master.conf',
			owner   => 'redis',
			group   => 'root',
			mode    => '0640',
		}

		Package['redis'] -> File['/etc/redis.conf'] ~> Service['redis']
	}
[root@master redis]# vim manifests/slave.pp
	class redis::slave($master_ip,$master_port='6379') inherits redis {
		file {'/etc/redis.conf':
			ensure  => file,
			content => template('redis/redis-slave.conf.erb'),
			owner   => 'redis',
			group   => 'root',
			mode    => '0640',
		}

		Package['redis'] -> File['/etc/redis.conf'] ~> Service['redis']
	}
```

3）准备文件：
现在我们需要把模板文件准备好，放入我们的`templates`目录下：

```bash
scp redis.conf.erb /root/modules/redis/templates/redis-slave.conf.erb
```

还有我们的静态文件，也要放入我们的`files`目录下：

```bash
scp redis.conf /root/modules/redis/files/redis-master.conf
```

4）查看目录结构，确定我们是否都已准备完成：

```bash
[root@master modules]# tree
.
└── redis
    ├── files
    │   └── redis-master.conf
    ├── lib
    ├── manifests
    │   ├── init.pp
    │   ├── master.pp
    │   └── slave.pp
    ├── spec
    ├── templates
    │   └── redis-slave.conf.erb
    └── tests

7 directories, 5 files
```

5）现在就可以把我们的准备好的模块放入系统的模块目录下：

```bash
[root@master mdoules]# cp -rp redis/ /etc/puppet/modules/
```

注意，模块是不能直接被调用的，只有放在`/etc/puppet/modules`下，或`/usr/share/puppet/modules`目录下，使其生效才可以被调用。

我们可以来查看一下我们的模块到底有哪些：

```bash
[root@master mdoules]# puppet module list
/etc/puppet/modules
└── redis (???)
/usr/share/puppet/modules (no modules installed)
```

可以看出，我们的模块已经定义好了，现在我们就可以直接调用了。

 6）调用模块

我们可以直接命令行传入参数来调用我们准备好的模块：

```bash
[root@master modules]# puppet apply -v --noop -e "class{'redis::slave': master_ip => '192.168.37.100'}"		#如果有多个参数，直接以逗号隔开即可
```

也可以把我们的调用的类赋值在`.pp`文件中，然后运行该文件。

```bash
[root@master ~]# cd manifests/  
[root@master manifests]# vim redis2.pp
	class{'redis::slave':
		master_ip => '192.168.37.100',
	}
[root@master manifests]# puppet apply -e --noop redis2.pp
```

以上。实验完成。

注意，以上实验是我们在单机模式下进行的，如果是要在master/agent 模式下进行，步骤还会略有不同。

# 四、master/agent 模型

master/agent模型时通过主机名进行通信的，下面，就来看看 master-agent 模式的puppet运维自动化如何实现：

## 4.1 实现步骤

### 4.1.1 实现前准备

1）下载包
 master 端：`puppet.noarch`，`puppet-server.noarch`
 agent 端：`puppet.noarch`

![puppet包查询](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171222212333928-844694007.png)



puppet包查询

2）主机名解析

为了方便我们后期的操作，我们可以通过定义`/etc/hosts`文件实现主机名的解析。如果机器很多的话，可以使用DNS进行解析。

```bash
[root@master ~]# vim /etc/hosts
	127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
	::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
	192.168.37.111  master.keer.com
	192.168.37.122  server1.keer.com
```

注意，该操作需要在每一台主机上进行。

修改完成以后，我们可以来测试一下是否已经成功：

```bash
[root@master ~]# ping server1.keer.com
```

![连通性测试](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171222212334131-1647169584.png)

连通性测试

3）时间同步

```bash
[root@master ~]# systemctl start chronyd.service
```

所有机器上都开启`chronyd.service`服务来进行时间同步

开启过后可以查看一下状态：

```bash
[root@master ~]# systemctl status chronyd.service
```

![时间同步状态](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171222212334334-735133130.png)

时间同步状态

我们可以使用`chronyc sources`命令来查看时间源：

![查看时间源](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171222212334475-711062639.png)

查看时间源

### 4.1.2 开启 master 端的 puppet 服务

1）手动前台开启，观察服务开启过程：

```bash
puppet master -v --no-daemonize		#前台运行
```

 

![master 初始化过程](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171222212334771-2051578219.png)


 　整个过程都是自动完成的，其中，每一步的意思如下：

1. 创建key 给CA
2. 创建一个请求给CA
3. 自签名证书
4. CA 创建完成
5. 创建证书吊销列表
6. 为当前的master 主机签署证书
7. master 的证书签署完成

2）直接`systemctl`开启服务，监听在8140端口。

![开启服务](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171222212334990-1873293960.png)

开启服务

### 4.1.3 在 agent 端开启服务

1）在配置文件中指明server端的主机名：

```bash
[root@server1 ~]# vim /etc/puppet/puppet.conf 
	server = master.keer.com
```

![agent端配置文件](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171222212335131-878601235.png)

agent端配置文件

接着，我们可以通过`puppet config print`命令来打印输出我们配置的参数：

```bash
[root@server1 ~]# puppet config print   显示配置文件中的配置参数
[root@server1 ~]# puppet config print --section=main   显示main 段的配置参数
[root@server1 ~]# puppet config print --section=agent  显示agent 段的配置参数
[root@server1 ~]# puppet config print server   显示server 的配置参数
```

![打印输出参数](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171222212335287-1245093671.png)

打印输出参数

2）开启 agent 服务

![开启agent服务](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171222212335428-1083102976.png)

开启agent服务

　　我们可以发现，他会一直卡在这里等待CA颁发证书。

3）在 master 端签署证书

```bash
[root@master ~]# puppet cert list
  "server1.keer.com" (SHA256) B5:67:51:30:5C:FB:45:BA:7A:73:D5:C5:87:D4:E3:1C:D7:02:BE:DD:CC:7A:E2:F0:28:34:87:86:EF:E7:1D:E4
[root@master ~]# puppet cert sign server1.keer.com		#颁发证书
Notice: Signed certificate request for server1.keer.com
Notice: Removing file Puppet::SSL::CertificateRequest server1.keer.com at '/var/lib/puppet/ssl/ca/requests/server1.keer.com.pem'
```

> master 端管理证书部署的命令语法如下：
>  puppet cert <action> [–all|-a] [<host>]
>  　action：
>  　　　list   列出证书请求
>  　　　sign  签署证书
>  　　　revoke   吊销证书
>  　　　clean   吊销指定的客户端的证书，并删除与其相关的所有文件；

注意：某agent证书手工吊销后重新生成一次；
 　On master host：
 　　　puppet cert revoke NODE_NAME
 　　　puppet cert clean NODE_NAME
 　On agent host：
 　　　重新生成的主机系统，直接启动agent；
 　　　变换私钥，建议先清理/var/lib/puppet/ssl/目录下的文件

4）终止服务开启，再次开启

```bash
[root@server1 ~]# puppet agent -v --noop --no-daemonize
```

 

![开启agent端服务](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171222212335568-798504236.png)



开启agent端服务

　　可以看出我们的服务开启成功，但是由于master 端没有配置站点清单，所以没有什么动作。

### 4.1.4 配置站点清单，且测试agent 端是否实现

1）设置站点清单

 ① 查询站点清单应存放的目录，（可以修改，去配置文件修改）

```bash
[root@master ~]# puppet config print |grep manifest
```

![查询配置文件的参数](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171222212335709-2099732734.png)

查询配置文件的参数

```bash
[root@master ~]# cd /etc/puppet/manifests/
[root@master manifests]# vim site.pp
node 'server1.along.com' {
        include redis::master
}
```

分析：就是简单的调用模块，只有模块提前定义好就可以直接调用；我调用的是上边的redis 模块

2）给puppet 用户授权

因为agent 端要来master 端读取配置，身份是puppet

```bash
[root@master manifests]# chown -R puppet /etc/puppet/modules/redis/*
```

3）[root@server1 ~]# puppet agent -v --noop --no-daemonize 手动前台开启agent 端服务

![enter description here](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171222212336037-132598782.png)

enter description here

（4）直接开启服务，agent 会自动去master 端获取配置
 [root@server1 ~]# systemctl start puppetagent   包已下载，服务也开启了

![enter description here](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171222212336225-205714606.png)

enter description here

# 五、实战 —— 使用master-agent 模型完成完整的redis 主从架构

## 5.1 环境准备

| 机器名称                    | IP配置         | 服务角色                      |
| :-------------------------- | :------------- | :---------------------------- |
| puppet-master               | 192.168.37.111 | puppet的master                |
| puppet-server1-master-redis | 192.168.37.122 | puppet的agent，redis 的master |
| puppet-server2-slave-redis  | 192.168.37.133 | puppet的agent，redis 的slave  |

## 5.2 实验前准备

1）下载包
 master 端：`puppet.noarch`，`puppet-server.noarch`
 agent 端：`puppet.noarch`

![puppet包查询](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171222212336365-1716942428.png)

puppet包查询

2）主机名解析

为了方便我们后期的操作，我们可以通过定义`/etc/hosts`文件实现主机名的解析。如果机器很多的话，可以使用DNS进行解析。

```bash
[root@master ~]# vim /etc/hosts
	127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
	::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
	192.168.37.111  master.keer.com
	192.168.37.122  server1.keer.com
	192.168.37.133  server2.keer.com
```

注意，该操作需要在每一台主机上进行。

修改完成以后，我们可以来测试一下是否已经成功：

```bash
[root@master ~]# ping server1.keer.com
```

![连通性测试](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171222212336756-1739440562.png)

连通性测试

3）时间同步

```bash
[root@master ~]# systemctl start chronyd.service
```

三台机器上都开启`chronyd.service`服务来进行时间同步

开启过后可以查看一下状态：

```bash
[root@master ~]# systemctl status chronyd.service
```

![时间同步状态](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171222212336959-958607153.png)

时间同步状态

我们可以使用`chronyc sources`命令来查看时间源：

![查看时间源](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171222212337131-673715701.png)

查看时间源

## 5.3 开启puppet 的master、agent 服务

（1）开启服务

```bash
[root@master ~]# systemctl start puppetmaster
[root@server1 ~]# systemctl start puppetagent
[root@server2 ~]# systemctl start puppetagent
```

因为server2 是第一次连接，需master 端签署证书

（2）master 签署颁发证书

```bash
[root@master manifests]# puppet cert list
[root@master ~]# puppet cert sign server2.keer.com
```

![master 颁发证书](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171222212337287-158135016.png)

master 颁发证书

## 5.4 配置站点清单

```bash
[root@master manifests]# cd /etc/puppet/manifests
[root@master manifests]# vim site.pp    直接调上边完成的模块
node 'server1.keer.com' {
    include redis::master
}

node 'server2.keer.com' {
    class{'redis::slave':
        master_ip => 'server1.keer.com'
    }
}
```

## 5.5 检测主从架构

```bash
[root@server2 ~]# vim /etc/redis.conf
```

![检测主从架构](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171222212337428-1529511587.png)

检测主从架构

```bash
[root@server2 ~]# redis-cli -a keerya info Replication
```

![enter description here](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171222212337646-1561071344.png)

enter description here

## 5.6 再添加个模块准备配置进站点清单

（1） 创建一个 chrony 模块，前准备

```bash
[root@master ~]# cd modules/    进入模块工作目录
[root@master modules]# mkdir chrony    创建chrony 的模块
[root@master modules]# mkdir chrony/{manifests,files} -pv    创建模块结构
```

（2）配置chrony 模块

```bash
[root@master modules]# cd chrony/
[root@master chrony]# cp /etc/chrony.conf files/
[root@master puppet]# vim files/chrony.conf
# test    #用于测试实验结果
```

![enter description here](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171222212337818-474845941.png)

添加一行

```bash
[root@master chrony]# vim manifests/init.pp
	class chrony {
			package{'chrony':
					ensure => installed
			} ->

			file{'/etc/chrony.conf':
					ensure  => file,
					source  => 'puppet:///modules/chrony.conf',
					owner   => 'root',
					group   => 'root',
					mode    => '0644'
			} ~>

			service{'chronyd':
					ensure  => running,
					enable  => true,
					hasrestart => true,
					hasstatus  => true
			}
	}
```

（3）puppet 添加这个模块，并生效

```bash
[root@master modules]# cp -rp chrony/ /etc/puppet/modules/
[root@master modules]# puppet module list
```

 

![查看puppet模块列表](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171222212337990-11315764.png)

查看puppet模块列表

## 5.7 再配置站点清单

```bash
[root@master ~]# cd /etc/puppet/manifests/
[root@master manifests]# vim site.pp
	node 'base' {
		include chrony
	}

	node 'server1.keer.com' inherits 'base' {
		include redis::master
	}

	node 'server2.keer.com' inherits 'base' {
		class{'redis::slave':
			master_ip => 'server1.keer.com'
		}
	}
	#node /cache[1-7]+\.keer\.com/ {	#可以用正则匹配多个服务器使用模块
	#       include varnish
	#}
```

## 5.8 测试

我们现在直接去server2机器上，查看我们的配置文件是否已经生效，是否是我们添加过一行的内容：

```bash
[root@server2 ~]# vim /etc/chrony.conf
```