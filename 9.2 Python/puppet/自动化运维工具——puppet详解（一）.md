- [自动化运维工具——puppet详解（一）](https://www.cnblogs.com/keerya/p/8040071.html)

# 一、puppet 介绍

## 1.1 puppet是什么

`puppet`是一个IT基础设施自动化管理工具，它能够帮助系统管理员管理基础设施的整个生命周期： 供应(provisioning)、配置(configuration)、联动(orchestration)及报告(reporting)。

基于puppet ，可实现自动化重复任务、快速部署关键性应用以及在本地或云端完成主动管理变更和快速扩展架构规模等。

遵循GPL 协议(2.7.0-), 基于`ruby`语言开发。

2.7.0 以后使用(Apache 2.0 license)，对于系统管理员是抽象的，只依赖于`ruby`与`facter`。

能管理多达40 多种资源，例如：`file`、`user`、`group`、`host`、`package`、`service`、`cron`、`exec`、`yum repo`等。

## 1.2 puppet的工作机制

### 1.2.1 工作模型

puppet 通过声明性、基于模型的方法进行IT自动化管理。

- 定义：通过puppet 的声明性配置语言定义基础设置配置的目标状态；
- 模拟：强制应用改变的配置之前先进行模拟性应用；
- 强制：自动、强制部署达成目标状态，纠正任何偏离的配置；
- 报告：报告当下状态及目标状态的不同，以及达成目标状态所进行的任何强制性改变；

**puppet三层模型**

![puppet三层模型](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171214212841373-1096192204.png)

### 1.2.2 工作流程

![工作流程](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171214212841513-1589501722.png)

### 1.2.3 使用模型

puppet的使用模型分为**单机使用模型**和**master/agent模型**，下面我们来看看这两个模型的原理图。

#### 1.2.3.1 单机使用模型

实现定义多个manifests --> complier --> catalog --> apply

![单机使用模型工作原理](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171214212841685-1431342735.png)



单机使用模型工作原理

#### 1.2.3.2 master/agent模型

master/agent模型实现的是集中式管理，即 agent 端周期性向 master 端发起请求，请求自己需要的数据。然后在自己的机器上运行，并将结果返回给 master 端。

架构和工作原理如下：

**架构**

![master/agent模式架构](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171214212841873-442342942.png)



master/agent模式架构

**工作原理**

![master/agent模式工作原理](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171214212842060-1278881772.png)



master/agent模式工作原理

## 1.3 puppet 名词解释

- 资源：是puppet的核心，通过资源申报，定义在资源清单中。相当于`ansible`中的**模块**，只是抽象的更加彻底。
- 类：一组资源清单。
- 模块：包含多个类。相当于`ansible`中的**角色**。
- 站点清单：以主机为核心，应用哪些模块。

# 二、puppet 资源详解

接下来，我们就以单机模式来具体介绍一下`puppet`的各个部分。

## 2.1 程序安装及环境

首先，我们还是来安装一下`puppet`，`puppet`的安装可以使用源码安装，也可以使用rpm（官方提供）、epel源、官方提供的yum仓库来安装（通过下载官方提供的rpm包可以指定官方的yum仓库）。
在这里，我们就是用 yum 安装的方式。

```
yum install -y puppet
```

安装完成过后，我们可以通过`rpm -ql puppet | less`来查看一下包中都有一些什么文件。

其中主配置文件为`/etc/puppet/puppet.conf`，使用的主程序为`/usr/bin/puppet`。

## 2.2 puppet 资源简介

### 2.2.1 资源抽象

 puppet 从以下三个维度来对资源完成抽象：

> 1. 相似的资源被抽象成同一种资源**“类型”** ，如程序包资源、用户资源及服务资源等；
> 2. **将资源属性或状态的描述与其实现方式剥离开来**，如仅说明安装一个程序包而不用关心其具体是通过yum、pkgadd、ports或是其它方式实现；
> 3. **仅描述资源的目标状态**，也即期望其实现的结果，而不是其具体过程，如“确定nginx 运行起来” 而不是具体描述为“运行nginx命令将其启动起来”；

这三个也被称作puppet 的资源抽象层(RAL)
RAL 由type( 类型) 和provider( 提供者，即不同OS 上的特定实现)组成。

### 2.2.2 资源定义

资源定义通过向资源类型的属性赋值来实现，可称为资源类型实例化；

定义了资源实例的文件即清单，manifest；

定义资源的语法如下：

```
type {'title':
	attribute1 	=> value1,
	atrribute2	=> value2,
	……
}
```

注意：type必须使用**小写字符**；title是一个字符串，在**同一类型中必须惟一**；每一个属性之间需要**用“,”隔开**，最后一个“,”可省略。

例如，可以同时有名为nginx 的“service”资源和“package”资源，但在“package” 类型的资源中只能有一个名为“nginx”的资源。

### 2.2.3 资源属性中的三个特殊属性：

- `Namevar`：可简称为name；
- `ensure`：资源的目标状态；
- `Provider`：指明资源的管理接口；

## 2.3 常用资源总结

### 2.3.1 查看资源

我们可以使用`puppet describe`来打印有关Puppet资源类型，提供者和元参数的帮助。使用语法如下：

```
puppet describe [-h|--help] [-s|--short] [-p|--providers] [-l|--list] [-m|--meta] [type]
	-l：列出所有资源类型；
	-s：显示指定类型的简要帮助信息；
	-m：显示指定类型的元参数，一般与-s一同使用；
```

### 2.3.2 group：管理系统上的用户组

 　查看使用帮助信息：

![enter description here](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171214212842279-880171649.png)

group使用帮助

```
属性：
	name：组名，可以省略，如果省略，将继承title的值；
	gid：GID；
	system：是否为系统组，true OR false；
	ensure：目标状态，present/absent；
	members：成员用户;
```

简单举例如下：

```bash
vim group.pp
	group{'mygrp':
        name => 'mygrp',
        ensure => present,
        gid => 2000,
	}
```

我们可以来运行一下：

![enter description here](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171214212842482-1292054093.png)

运行写好的group资源

### 2.3.3 user：管理系统上的用户

查看使用帮助信息：

![enter description here](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171214212842701-1621142302.png)

user使用帮助

```
属性：
	name：用户名，可以省略，如果省略，将继承title的值；
	uid: UID;
	gid：基本组ID；
	groups：附加组，不能包含基本组；
	comment：注释； 
	expiry：过期时间 ；
	home：用户的家目录； 
	shell：默认shell类型；
	system：是否为系统用户 ；
	ensure：present/absent；
	password：加密后的密码串； 
```

简单举例如下：

```bash
vim user1.pp
	user{'keerr':
        ensure => present,
        system => false,
        comment => 'Test User',
        shell => '/bin/tcsh',
        home => '/data/keerr',
        managehome => true,
        groups => 'mygrp',
        uid => 3000,
	}
```

### 2.3.4 package：puppet的管理软件包

查看使用帮助信息：

![enter description here](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171214212842935-273954621.png)

package使用帮助

```
属性：
	ensure：installed, present, latest, absent, any version string (implies present)
	name：包名，可以省略，如果省略，将继承title的值；
	source：程序包来源，仅对不会自动下载相关程序包的provider有用，例如rpm或dpkg；
	provider:指明安装方式；
```

简单举例如下：

```
vim package1.pp
	package{'nginx':
   		ensure  => installed,
    	procider    =>  yum
	}	
```

### 2.3.5 service：定义服务的状态

查看使用帮助信息：

```
puppet describe service -s -m
```

![enter description here](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171214212843092-179977505.png)

service使用帮助

```
属性：
	ensure：服务的目标状态，值有true（running）和false（stopped） 
	enable：是否开机自动启动，值有true和false
	name：服务名称，可以省略，如果省略，将继承title的值
	path：服务脚本路径，默认为/etc/init.d/下
	start：定制启动命令
	stop：定制关闭命令
	restart：定制重启命令
	status：定制状态
```

简单举例如下：

```
vim service1.pp
	service{'nginx':
  	  	ensure  => true,
    	enable  => false
	}
```

### 2.3.6 file：管理文件、目录、软链接

查看使用帮助信息：

![enter description here](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171214212843310-2023563361.png)

file使用帮助

```
属性：
	ensure：目标状态，值有absent,present,file,directory和link
		file：类型为普通文件，其内容由content属性生成或复制由source属性指向的文件路径来创建；
		link：类型为符号链接文件，必须由target属性指明其链接的目标文件；
		directory：类型为目录，可通过source指向的路径复制生成，recurse属性指明是否递归复制；
	path：文件路径；
	source：源文件；
	content：文件内容；
	target：符号链接的目标文件； 
	owner：定义文件的属主；
	group：定义文件的属组；
	mode：定义文件的权限；
	atime/ctime/mtime：时间戳；
```

简单举例如下：

```
vim file1.pp
	file{'aaa':
   	 	path    => '/data/aaa',
    	source  => '/etc/aaa',
    	owner   => 'keerr',
    	mode    => '611',
	}
```

### 2.3.7 exec：执行命令，慎用。通常用来执行外部命令

查看使用帮助信息：

```
puppet describe exec -s -m
```

![enter description here](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171214212843498-1433706043.png)

exec使用帮助

```
属性：
	command(namevar)：要运行的命令；
	cwd：指定运行该命令的目录；
	creates：文件路径，仅此路径表示的文件不存在时，command方才执行；
	user/group：运行命令的用户身份；
	path：指定命令执行的搜索路径；
	onlyif：此属性指定一个命令，此命令正常（退出码为0）运行时，当前command才会运行；
	unless：此属性指定一个命令，此命令非正常（退出码为非0）运行时，当前command才会运行；
	refresh：重新执行当前command的替代命令；
	refreshonly：仅接收到订阅的资源的通知时方才运行；
```

简单举例如下：

```
vim exec1.pp
	exec{'cmd':
   	 	command => 'mkdir /data/testdir',
    	path => ['/bin','/sbin','/usr/bin','/usr/sbin'],
	#   path => '/bin:/sbin:/usr/bin:/usr/sbin',
	}
```

### 2.3.8 cron：定义周期性任务

查看使用帮助信息：

![enter description here](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171214212843670-692555829.png)

cron使用帮助

```
属性：
	command：要执行的任务（命令或脚本）；
	ensure：目标状态，present/absent；
	hour：时；
	minute：分；
	monthday：日；
	month：月；
	weekday：周；
	user：以哪个用户的身份运行命令（默认为root）；
	target：添加为哪个用户的任务；
	name：cron job的名称；
```

简单举例如下：

```
vim cron1.pp
	cron{'timesync':
    	command => '/usr/sbin/ntpdata 172.16.0.1',
    	ensure  => present,
    	minute  => '*/3',
    	user    => 'root',
	}
```

我们可以运行一下，查看我们的crontab，来看看该任务是否已经被添加：

```
[root@master manifests]# puppet apply -v --noop cron1.pp 		#试运行
[root@master manifests]# puppet apply -v  cron1.pp 				#运行
[root@master manifests]# crontab -l				#查看计划任务
# HEADER: This file was autogenerated at 2017-12-14 15:05:05 +0800 by puppet.
# HEADER: While it can still be managed manually, it is definitely not recommended.
# HEADER: Note particularly that the comments starting with 'Puppet Name' should
# HEADER: not be deleted, as doing so could cause duplicate cron jobs.
# Puppet Name: timesync
*/3 * * * * /usr/sbin/ntpdata 172.16.0.1
```

### 2.3.9 notify：调试输出

查看使用帮助信息：

![enter description here](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171214212843795-1752318152.png)

 

```
属性：
	message：记录的信息
	name：信息名称
```

该选项一般用于`master/agent模式`中，来记录一些操作的时间，比如重新安装了一个程序呀，或者重启了应用等等。会直接输出到代理机的运行日志中。

以上，就是我们常见的8个资源。其余的资源我们可以使用`puppet describe -l`来列出，上文中也已经说过了~

## 2.4 资源的特殊属性

`puppet`中也提供了**before**、**require**、**notify**和**subscribe**四个参数来定义资源之间的依赖关系和通知关系。

> **before**：表示需要依赖于某个资源
>  **require**：表示应该先执行本资源，在执行别的资源
>  **notify**：A notify B：B依赖于A，且A发生改变后会通知B；
>  **subscribe**：B subscribe A：B依赖于A，且B监控A资源的变化产生的事件；

同时，依赖关系还可以使用`->`和`～>`来表示：

> **->** 表示后资源需要依赖前资源
>  **~>** 表示前资源变动通知后资源调用

举例如下：

```bash
vim file.pp
	file{'test.txt':					#定义一个文件
		path   => '/data/test.txt',
		ensure  => file,
		source  => '/etc/fstab',
	}

	file{'test.symlink':				#依赖文件建立超链接
		path   => '/data/test.symlink',
		ensure  => link,
		target  => '/data/test.txt',
		require => File['test.txt'],
	}

	file{'test.dir':					#定义一个目录
		path   => '/data/test.dir',
		ensure  => directory,
		source  => '/etc/yum.repo.d/',
		recurse => true,
	}
```

我们还可以使用在最下面统一写依赖关系的方式来定义：

```bash
vim redis.pp
	package{'reids':
		ensure  => installed,
	}

	file{'/etc/redis.conf':
		source  => '/root/manifets/files/redis.conf',
		ensure  => file,
		owner   => redis,
		group   => root,
		mode    => '0640',
	}

	service{'redis':
		ensure  => running,
		enable  => true,
		hasrestart => true,
	}

	Package['redis'] -> File['/etc/redis.conf'] -> Service['redis']	#定义依赖关系
```

### 2.4.1 tag 标签

如同 anssible 一样，puppet 也可以定义“标签”——tag，打了标签以后，我们在运行资源的时候就可以只运行某个打过标签的部分，而非全部。这样就更方便于我们的操作。

 一个资源中，可以有一个`tag`也可以有多个。具体使用语法如下：

```bash
type{'title':
	...
    tag => 'TAG1',
}
            
type{'title':
    ...
    tag => ['TAG1','TAG2',...],
}
```

调用时的语法如下：

```bash
puppet apply --tags TAG1,TAG2,... FILE.PP
```

**实例**
首先，我们去修改一下`redis.pp`文件，添加一个标签进去

```bash
vim redis.pp
	package{'redis':
		ensure  => installed,
	}

	file{'/etc/redis.conf':
		source  => '/root/manifets/file/redis.conf',
		ensure  => file,
		owner   => redis,
		group   => root,
		mode    => '0640',
		tag    => 'instconf'		#定义标签
	}

	service{'redis':
		ensure  => running,
		enable  => true,
		hasrestart => true,
	}

	Package['redis'] -> File['/etc/redis.conf'] -> Service['redis']
```

然后，我们手动先开启`redis`服务：

```bash
systemctl start redis
```

现在，我们去修改一下`file`目录下的配置文件：

```bash
vim file/redis.conf 
requirepass keerya
```

　　接着，我们就去运行`redis.pp`，我们的配置文件已经修改过了，现在想要实现的就是重启该服务，实现，需要使用密码`keer`登录：

```bash
puppet apply -v --tags instconf redis.pp
```

![enter description here](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171214212844076-1652768295.png)

redis.pp运行结果

现在，我们就去登录一下redis看看是否生效：

```bash
	redis-cli -a keerya
```

![enter description here](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171214212844217-869371967.png)

redis验证

验证成功，实验完成。

## 2.5 puppet 变量

puppet 变量以“$”开头，赋值操作符为“=”，语法为`$variable_name=value`。

 **数据类型：**

> 　　**字符型**：引号可有可无；但**单引号为强引用**，**双引号为弱引用**；支持转义符；
>  　**数值型**：默认均识别为字符串，仅在数值上下文才以数值对待；
>  　**数组**：[]中以逗号分隔元素列表；
>  　**布尔型值**：true, false；不能加引号；
>  　**hash**：{}中以逗号分隔k/v数据列表； 键为字符型，值为任意puppet支持的类型；{ ‘mon’ => ‘Monday’, ‘tue’ => ‘Tuesday’, }；
>  　**undef**：从未被声明的变量的值类型；

**正则表达式：**

> 　　(?<ENABLED OPTION>:<PATTERN>)
>  　(?-<DISABLED OPTION>:<PATTERN>)
>  　OPTIONS：
>  　　　i：忽略字符大小写；
>  　　　m：把.当换行符；
>  　　　x：忽略<PATTERN>中的空白字符；
>  　(?i-mx:PATTERN）
>  注意：不能赋值给变量，仅能用在接受`=~`或`!~`操作符的位置；

### 2.5.1 puppet的变量种类

puppet 种类有三种，为`facts`，`内建变量`和`用户自定义变量`。

**facts：**
由facter提供；top scope；

**内建变量：**
 　master端变量
 　　　$servername, $serverip, $serverversion
 　agent端变量
 　　　$clientcert, $clientversion, $environment
 　parser变量
 　　　$module_name
**用户自定义变量**

### 2.5.2 变量的作用域

不同的变量也有其不同的作用域。我们称之为`Scope`。

作用域有三种，top scope，node scope，class scope。

其生效范围排序为：top scope > node scope > class scope。

![enter description here](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171214212844404-2100446694.png)

变量生效范围。

其优先级排序为：top scope < node scope < class scope。

## 2.6 puppet 流程控制语句

puppet 支持**if 语句**，**case 语句**和**selector 语句**。

### 2.6.1 if 语句

if语句支持单分支，双分支和多分支。具体语法如下：

```bash
单分支：
	if CONDITION {
		statement
		……
	}

双分支：
	if CONDITION {
		statement
		……
	}
	else{
		statement
		……		
	}

多分支：
	if CONDITION {
		statement
		……
	}
	elsif CONDITION{
		statement
		……
	}
	else{
		statement
		……		
	}
```

其中，CONDITION的给定方式有如下三种：

- 变量
- 比较表达式
- 有返回值的函数

**举例**

```
vim if.pp
	if $operatingsystemmajrelease == '7' {
		$db_pkg='mariadb-server'
	}else{
		$db_pkg='mysql-server'
	}

	package{"$db_pkg":
		ensure => installed,
	}
```

### 2.6.2 case 语句

类似 if 语句，case 语句会从多个代码块中选择一个分支执行，这跟其它编程语言中的 case 语句功能一致。

case 语句会接受一个控制表达式和一组 case 代码块，并执行第一个匹配到控制表达式的块。

使用语法如下：

```
case CONTROL_EXPRESSION {
	case1: { ... }
	case2: { ... }
	case3: { ... }
	……
	default: { ... }
}
```

其中，CONTROL_EXPRESSION的给定方式有如下三种:

- 变量
- 表达式
- 有返回值的函数

各case的给定方式有如下五种：

- 直接字串；
- 变量
- 有返回值的函数
- 正则表达式模式；
- default

**举例**

```bash
vim case.pp
	case $osfamily {
		"RedHat": { $webserver='httpd' }
		/(?i-mx:debian)/: { $webserver='apache2' }
		default: { $webserver='httpd' }
	}

	package{"$webserver":
		ensure  => installed,    before  => [ File['httpd.conf'], Service['httpd'] ],
	}

	file{'httpd.conf':
		path    => '/etc/httpd/conf/httpd.conf',
		source  => '/root/manifests/httpd.conf',
		ensure  => file,
	}

	service{'httpd':
		ensure  => running,
		enable  => true,    restart => 'systemctl restart httpd.service',
		subscribe => File['httpd.conf'],
	}
```

### 2.6.3 selector 语句

Selector 只能用于期望出现直接值(plain value) 的地方，这包括变量赋值、资源属性、函数参数、资源标题、其它 selector。

selector 不能用于一个已经嵌套于于selector 的case 中，也不能用于一个已经嵌套于case 的case 语句中。

具体语法如下：

```bash
CONTROL_VARIABLE ? {
	case1 => value1,
	case2 => value2,
	...
	default => valueN,
}
```

其中，CONTROL_EXPRESSION的给定方式有如下三种:

- 变量
- 表达式
- 有返回值的函数

各case的给定方式有如下五种：

- 直接子串；
- 变量；
- 有返回值的函数；
- 正则表达式模式；
- default

**selectors 使用要点：**

1. 整个selector 语句会被当作一个单独的值，puppet 会将控制变量按列出的次序与每个case 进行比较，并在遇到一个匹配的 case 后，将其值作为整个语句的值进行返回，并忽略后面的其它 case。
2. 控制变量与各 case 比较的方式与 case 语句相同，但如果没有任何一个 case 与控制变量匹配时，puppet 在编译时将会返回一个错误，因此，实践中，其必须提供default case。
3. selector 的控制变量只能是变量或有返回值的函数，切记不能使用表达式。
4. 其各 case 可以是直接值(需要加引号) 、变量、能调用返回值的函数、正则表达式模式或 default。
5. 但与 case 语句所不同的是，selector 的各 case 不能使用列表。
6. selector 的各 case 的值可以是一个除了 hash 以外的直接值、变量、能调用返回值的函数或其它的 selector。

**举例**

```bash
vim selector.pp
	$pkgname = $operatingsystem ? {
		/(?i-mx:(ubuntu|debian))/       => 'apache2',
		/(?i-mx:(redhat|fedora|centos))/        => 'httpd',
		default => 'httpd',
	}
	package{"$pkgname":
		ensure  => installed,
	}
```