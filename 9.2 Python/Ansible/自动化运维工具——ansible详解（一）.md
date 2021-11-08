- [自动化运维工具——ansible详解（一）](https://www.cnblogs.com/keerya/p/7987886.html)

# 一、ansible 简介

## 1.1 ansible 是什么？

ansible是新出现的自动化运维工具，基于Python开发，集合了众多运维工具（puppet、chef、func、fabric）的优点，实现了批量系统配置、批量程序部署、批量运行命令等功能。
ansible是基于 paramiko  开发的,并且基于模块化工作，本身没有批量部署的能力。

真正具有批量部署的是ansible所运行的模块，ansible只是提供一种框架。

ansible不需要在远程主机上安装client/agents，因为它们是基于ssh来和远 程主机通讯的。

ansible目前已经已经被红帽官方收购，是自动化运维工具中大家认可度最高的，并且上手容易，学习简单。是每位运维工程师必须掌握的技能之一。

## 1.2 ansible 特点

1. 部署简单，只需在主控端部署Ansible环境，被控端无需做任何操作；
2. 默认使用SSH协议对设备进行管理；
3. 有大量常规运维操作模块，可实现日常绝大部分操作；
4. 配置简单、功能强大、扩展性强；
5. 支持API及自定义模块，可通过Python轻松扩展；
6. 通过Playbooks来定制强大的配置、状态管理；
7. 轻量级，无需在客户端安装agent，更新时，只需在操作机上进行一次更新即可；
8. 提供一个功能强大、操作性强的Web管理界面和REST API接口——AWX平台。

## 1.3 ansible 架构图

![img](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171205163000628-69838828.png)
 　上图中我们看到的主要模块如下：

> `Ansible`：Ansible核心程序。
>  `HostInventory`：记录由Ansible管理的主机信息，包括端口、密码、ip等。
>  `Playbooks`：“剧本”YAML格式文件，多个任务定义在一个文件中，定义主机需要调用哪些模块来完成的功能。
>  `CoreModules`：**核心模块**，主要操作是通过调用核心模块来完成管理任务。
>  `CustomModules`：自定义模块，完成核心模块无法完成的功能，支持多种语言。
>  `ConnectionPlugins`：连接插件，Ansible和Host通信使用

# 二、ansible 任务执行

## 2.1 ansible 任务执行模式

Ansible 系统由控制主机对被管节点的操作方式可分为两类，即`adhoc`和`playbook`：

- ad-hoc模式(点对点模式)
   　使用单个模块，支持批量执行单条命令。ad-hoc 命令是一种可以快速输入的命令，而且不需要保存起来的命令。**就相当于bash中的一句话shell。**
- playbook模式(剧本模式)
   　是Ansible主要管理方式，也是Ansible功能强大的关键所在。**playbook通过多个task集合完成一类功能**，如Web服务的安装部署、数据库服务器的批量备份等。可以简单地把playbook理解为通过组合多条ad-hoc操作的配置文件。

## 2.2 ansible 执行流程

![img](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171205162615738-1292598736.png)
简单理解就是Ansible在运行时， 首先读取`ansible.cfg`中的配置， 根据规则获取`Inventory`中的管理主机列表， 并行的在这些主机中执行配置的任务， 最后等待执行返回的结果。

## 2.3 ansible 命令执行过程

1. 加载自己的配置文件，默认`/etc/ansible/ansible.cfg`；
2. 查找对应的主机配置文件，找到要执行的主机或者组；
3. 加载自己对应的模块文件，如 command；
4. 通过ansible将模块或命令生成对应的临时py文件(python脚本)， 并将该文件传输至远程服务器；
5. 对应执行用户的家目录的`.ansible/tmp/XXX/XXX.PY`文件；
6. 给文件 +x 执行权限；
7. 执行并返回结果；
8. 删除临时py文件，`sleep 0`退出；

# 三、ansible 配置详解

## 3.1 ansible 安装方式

ansible安装常用两种方式，`yum安装`和`pip程序安装`。下面我们来详细介绍一下这两种安装方式。

### 3.1.1 使用 pip（python的包管理模块）安装

首先，我们需要安装一个`python-pip`包，安装完成以后，则直接使用`pip`命令来安装我们的包，具体操作过程如下：

```bash
yum install python-pip
pip install ansible
```

### 3.1.2 使用 yum 安装

yum 安装是我们很熟悉的安装方式了。我们需要先安装一个` epel-release`包，然后再安装我们的 ansible 即可。

```
yum install epel-release -y
yum install ansible –y
```

## 3.2 ansible 程序结构

安装目录如下(yum安装)：

- 配置文件目录：/etc/ansible/
- 执行文件目录：/usr/bin/
- Lib库依赖目录：/usr/lib/pythonX.X/site-packages/ansible/
- Help文档目录：/usr/share/doc/ansible-X.X.X/
- Man文档目录：/usr/share/man/man1/

## 3.3 ansible配置文件查找顺序

ansible与我们其他的服务在这一点上有很大不同，这里的配置文件查找是从多个地方找的，顺序如下：

1. 检查环境变量`ANSIBLE_CONFIG`指向的路径文件(export ANSIBLE_CONFIG=/etc/ansible.cfg)；
2. `~/.ansible.cfg`，检查当前目录下的ansible.cfg配置文件；
3. `/etc/ansible.cfg`检查etc目录的配置文件。

## 3.4 ansible配置文件

　　ansible 的配置文件为`/etc/ansible/ansible.cfg`，ansible 有许多参数，下面我们列出一些常见的参数：

- inventory = /etc/ansible/hosts		#这个参数表示资源清单inventory文件的位置
- library = /usr/share/ansible		#指向存放Ansible模块的目录，支持多个目录方式，只要用冒号（：）隔开就可以
- forks = 5		#并发连接数，默认为5
- sudo_user = root		#设置默认执行命令的用户
- remote_port = 22		#指定连接被管节点的管理端口，默认为22端口，建议修改，能够更加安全
- host_key_checking = False		#设置是否检查SSH主机的密钥，值为True/False。关闭后第一次连接不会提示配置实例
- timeout = 60		#设置SSH连接的超时时间，单位为秒
- log_path = /var/log/ansible.log		#指定一个存储ansible日志的文件（默认不记录日志）

## 3.5 ansuble主机清单

在配置文件中，我们提到了资源清单，这个清单就是我们的主机清单，里面保存的是一些 ansible 需要连接管理的主机列表。我们可以来看看他的定义方式：

```
1、 直接指明主机地址或主机名：
	## green.example.com#
	# blue.example.com#
	# 192.168.100.1
	# 192.168.100.10
2、 定义一个主机组[组名]把地址或主机名加进去
	[mysql_test]
	192.168.253.159
	192.168.253.160
	192.168.253.153
```

需要注意的是，这里的组成员可以使用通配符来匹配，这样对于一些标准化的管理来说就很轻松方便了。
我们可以根据实际情况来配置我们的主机列表，具体操作如下：

```
[root@server ~]# vim /etc/ansible/hosts
[web]
192.168.37.122
192.168.37.133
```

# 四、ansible 常用命令

## 4.1 ansible 命令集

> `/usr/bin/ansible`　　Ansibe AD-Hoc 临时命令执行工具，常用于临时命令的执行
>  `/usr/bin/ansible-doc` 　　Ansible 模块功能查看工具
>  `/usr/bin/ansible-galaxy`　　下载/上传优秀代码或Roles模块 的官网平台，基于网络的
>  `/usr/bin/ansible-playbook`　　Ansible 定制自动化的任务集编排工具
>  `/usr/bin/ansible-pull`　　Ansible远程执行命令的工具，拉取配置而非推送配置（使用较少，海量机器时使用，对运维的架构能力要求较高）
>  `/usr/bin/ansible-vault`　　Ansible 文件加密工具
>  `/usr/bin/ansible-console`　　Ansible基于Linux Consoble界面可与用户交互的命令执行工具

　　其中，我们比较常用的是`/usr/bin/ansible`和`/usr/bin/ansible-playbook`。

## 4.2 ansible-doc 命令

ansible-doc 命令常用于获取模块信息及其使用帮助，一般用法如下：

```
ansible-doc -l				#获取全部模块的信息
ansible-doc -s MOD_NAME		#获取指定模块的使用帮助
```

　　我们也可以查看一下ansible-doc的全部用法：

```bash
[root@server ~]# ansible-doc
Usage: ansible-doc [options] [module...]

Options:
  -h, --help            show this help message and exit　　# 显示命令参数API文档
  -l, --list            List available modules　　#列出可用的模块
  -M MODULE_PATH, --module-path=MODULE_PATH　　#指定模块的路径
                        specify path(s) to module library (default=None)
  -s, --snippet         Show playbook snippet for specified module(s)　　#显示playbook制定模块的用法
  -v, --verbose         verbose mode (-vvv for more, -vvvv to enable　　# 显示ansible-doc的版本号查看模块列表：
                        connection debugging)
  --version             show program's version number and exit
```

我们可以来看一下，以mysql相关的为例：

```bash
[root@server ~]# ansible-doc -l |grep mysql
mysql_db                           Add or remove MySQL databases from a remote...
mysql_replication                  Manage MySQL replication                   
mysql_user                         Adds or removes a user from a MySQL databas...
mysql_variables                    Manage MySQL global variables      
[root@server ~]# ansible-doc -s mysql_user
```

![img](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171205163026644-674759103.png)

## 4.2 ansible 命令详解

命令的具体格式如下：

```bash
ansible <host-pattern> [-f forks] [-m module_name] [-a args]
```

也可以通过`ansible -h`来查看帮助，下面我们列出一些比较常用的选项，并解释其含义：

> `-a MODULE_ARGS`　　　#模块的参数，如果执行默认COMMAND的模块，即是命令参数，如： “date”，“pwd”等等
>  `-k`，`--ask-pass`		#ask for SSH password。登录密码，提示输入SSH密码而不是假设基于密钥的验证
>  `--ask-su-pass`			#ask for su password。su切换密码
>  `-K`，`--ask-sudo-pass`			#ask for sudo password。提示密码使用sudo，sudo表示提权操作
>  `--ask-vault-pass`		#ask for vault password。假设我们设定了加密的密码，则用该选项进行访问
>  `-B SECONDS`		#后台运行超时时间
>  `-C`				#模拟运行环境并进行预运行，可以进行查错测试
>  `-c CONNECTION`			#连接类型使用
>  `-f FORKS`			#并行任务数，默认为5
>  `-i INVENTORY`		#指定主机清单的路径，默认为`/etc/ansible/hosts`
>  `--list-hosts`		#查看有哪些主机组
>  `-m MODULE_NAME`		#执行模块的名字，默认使用 command 模块，所以如果是只执行单一命令可以不用 -m参数
>  `-o`		#压缩输出，尝试将所有结果在一行输出，一般针对收集工具使用
>  `-S`		#用 su 命令
>  `-R SU_USER`		#指定 su 的用户，默认为 root 用户
>  `-s`		#用 sudo 命令
>  `-U SUDO_USER`		#指定 sudo 到哪个用户，默认为 root 用户
>  `-T TIMEOUT`		#指定 ssh 默认超时时间，默认为10s，也可在配置文件中修改
>  `-u REMOTE_USER`		#远程用户，默认为 root 用户
>  `-v`		#查看详细信息，同时支持`-vvv`，`-vvvv`可查看更详细信息

## 4.3 ansible 配置公私钥

上面我们已经提到过 ansible 是基于 ssh 协议实现的，所以其配置公私钥的方式与 ssh 协议的方式相同，具体操作步骤如下：

```bash
#1.生成私钥
[root@server ~]# ssh-keygen 
#2.向主机分发私钥
[root@server ~]# ssh-copy-id root@192.168.37.122
[root@server ~]# ssh-copy-id root@192.168.37.133
```

这样的话，就可以实现无密码登录，我们的实验过程也会顺畅很多。
 　注意，如果出现了一下报错：

```
-bash: ssh-copy-id: command not found
```

那么就证明我们需要安装一个包：

```
yum -y install openssh-clientsansible
```

把包安装上即可。

# 五、ansible 常用模块

## 5.1 主机连通性测试

我们使用`ansible web -m ping`命令来进行主机连通性测试，效果如下：

```bash
[root@server ~]# ansible web -m ping
192.168.37.122 | SUCCESS => {
    "changed": false, 
    "ping": "pong"
}
192.168.37.133 | SUCCESS => {
    "changed": false, 
    "ping": "pong"
}
```

这样就说明我们的主机是连通状态的。接下来的操作才可以正常进行。

## 5.2 command 模块

这个模块可以直接在远程主机上执行命令，并将结果返回本主机。
举例如下：

```bash
[root@server ~]# ansible web -m command -a 'ss -ntl'
192.168.37.122 | SUCCESS | rc=0 >>
State      Recv-Q Send-Q Local Address:Port               Peer Address:Port              
LISTEN     0      128          *:111                      *:*                  
LISTEN     0      5      192.168.122.1:53                       *:*                  
LISTEN     0      128          *:22                       *:*                  
LISTEN     0      128    127.0.0.1:631                      *:*                  
LISTEN     0      128          *:23000                    *:*                  
LISTEN     0      100    127.0.0.1:25                       *:*                  
LISTEN     0      128         :::111                     :::*                  
LISTEN     0      128         :::22                      :::*                  
LISTEN     0      128        ::1:631                     :::*                  
LISTEN     0      100        ::1:25                      :::*                  

192.168.37.133 | SUCCESS | rc=0 >>
State      Recv-Q Send-Q Local Address:Port               Peer Address:Port              
LISTEN     0      128          *:111                      *:*                  
LISTEN     0      128          *:22                       *:*                  
LISTEN     0      128    127.0.0.1:631                      *:*                  
LISTEN     0      128          *:23000                    *:*                  
LISTEN     0      100    127.0.0.1:25                       *:*                  
LISTEN     0      128         :::111                     :::*                  
LISTEN     0      128         :::22                      :::*                  
LISTEN     0      128        ::1:631                     :::*                  
LISTEN     0      100        ::1:25                      :::*  
```

命令模块接受命令名称，后面是空格分隔的列表参数。给定的命令将在所有选定的节点上执行。它不会通过shell进行处理，比如$HOME和操作如"<"，">"，"|"，";"，"&" 工作（需要使用（shell）模块实现这些功能）。注意，该命令不支持`| 管道命令`。
 　下面来看一看该模块下常用的几个命令：

> chdir　　　　　　    # 在执行命令之前，先切换到该目录
>  executable 				# 切换shell来执行命令，需要使用命令的绝对路径
>  free_form 			　	# 要执行的Linux指令，一般使用Ansible的-a参数代替。
>  creates 					　# 一个文件名，当这个文件存在，则该命令不执行,可以
>  用来做判断
>  removes 					# 一个文件名，这个文件不存在，则该命令不执行

下面我们来看看这些命令的执行效果：

```bash
[root@server ~]# ansible web -m command -a 'chdir=/data/ ls'	#先切换到/data/ 目录，再执行“ls”命令
192.168.37.122 | SUCCESS | rc=0 >>
aaa.jpg
fastdfs
mogdata
tmp
web
wKgleloeYoCAMLtZAAAWEekAtkc497.jpg

192.168.37.133 | SUCCESS | rc=0 >>
aaa.jpg
fastdfs
mogdata
tmp
web
wKgleloeYoCAMLtZAAAWEekAtkc497.jpg
[root@server ~]# ansible web -m command -a 'creates=/data/aaa.jpg ls'		#如果/data/aaa.jpg存在，则不执行“ls”命令
192.168.37.122 | SUCCESS | rc=0 >>
skipped, since /data/aaa.jpg exists

192.168.37.133 | SUCCESS | rc=0 >>
skipped, since /data/aaa.jpg exists
[root@server ~]# ansible web -m command -a 'removes=/data/aaa.jpg cat /data/a'		#如果/data/aaa.jpg存在，则执行“cat /data/a”命令
192.168.37.122 | SUCCESS | rc=0 >>
hello

192.168.37.133 | SUCCESS | rc=0 >>
hello
```

## 5.3 shell 模块

shell模块可以在远程主机上调用shell解释器运行命令，支持shell的各种功能，例如管道等。

```
[root@server ~]# ansible web -m shell -a 'cat /etc/passwd |grep "keer"'
192.168.37.122 | SUCCESS | rc=0 >>
keer:x:10001:1000:keer:/home/keer:/bin/sh

192.168.37.133 | SUCCESS | rc=0 >>
keer:x:10001:10001::/home/keer:/bin/sh
```

只要是我们的shell命令，都可以通过这个模块在远程主机上运行，这里就不一一举例了。

## 5.4 copy 模块

这个模块用于将文件复制到远程主机，同时支持给定内容生成文件和修改权限等。
其相关选项如下：

> `src`　　　　#被复制到远程主机的本地文件。可以是绝对路径，也可以是相对路径。如果路径是一个目录，则会递归复制，用法类似于"rsync"
>  `content`　　　#用于替换"src"，可以直接指定文件的值
>  `dest`　　　　#必选项，将源文件复制到的远程主机的**绝对路径**
>  `backup`　　　#当文件内容发生改变后，在覆盖之前把源文件备份，备份文件包含时间信息
>  `directory_mode`　　　　#递归设定目录的权限，默认为系统默认权限
>  `force`　　　　#当目标主机包含该文件，但内容不同时，设为"yes"，表示强制覆盖；设为"no"，表示目标主机的目标位置不存在该文件才复制。默认为"yes"
>  `others`　　　　#所有的 file 模块中的选项可以在这里使用

用法举例如下：

### 5.4.1  复制文件

```bash
[root@server ~]# ansible web -m copy -a 'src=~/hello dest=/data/hello' 
192.168.37.122 | SUCCESS => {
    "changed": true, 
    "checksum": "22596363b3de40b06f981fb85d82312e8c0ed511", 
    "dest": "/data/hello", 
    "gid": 0, 
    "group": "root", 
    "md5sum": "6f5902ac237024bdd0c176cb93063dc4", 
    "mode": "0644", 
    "owner": "root", 
    "size": 12, 
    "src": "/root/.ansible/tmp/ansible-tmp-1512437093.55-228281064292921/source", 
    "state": "file", 
    "uid": 0
}
192.168.37.133 | SUCCESS => {
    "changed": true, 
    "checksum": "22596363b3de40b06f981fb85d82312e8c0ed511", 
    "dest": "/data/hello", 
    "gid": 0, 
    "group": "root", 
    "md5sum": "6f5902ac237024bdd0c176cb93063dc4", 
    "mode": "0644", 
    "owner": "root", 
    "size": 12, 
    "src": "/root/.ansible/tmp/ansible-tmp-1512437093.74-44694985235189/source", 
    "state": "file", 
    "uid": 0
}
```

### 5.4.2 给定内容生成文件，并制定权限

```bash
[root@server ~]# ansible web -m copy -a 'content="I am keer\n" dest=/data/name mode=666'
192.168.37.122 | SUCCESS => {
    "changed": true, 
    "checksum": "0421570938940ea784f9d8598dab87f07685b968", 
    "dest": "/data/name", 
    "gid": 0, 
    "group": "root", 
    "md5sum": "497fa8386590a5fc89090725b07f175c", 
    "mode": "0666", 
    "owner": "root", 
    "size": 10, 
    "src": "/root/.ansible/tmp/ansible-tmp-1512437327.37-199512601767687/source", 
    "state": "file", 
    "uid": 0
}
192.168.37.133 | SUCCESS => {
    "changed": true, 
    "checksum": "0421570938940ea784f9d8598dab87f07685b968", 
    "dest": "/data/name", 
    "gid": 0, 
    "group": "root", 
    "md5sum": "497fa8386590a5fc89090725b07f175c", 
    "mode": "0666", 
    "owner": "root", 
    "size": 10, 
	    "src": "/root/.ansible/tmp/ansible-tmp-1512437327.55-218104039503110/source", 
    "state": "file", 
    "uid": 0
}
```

我们现在可以去查看一下我们生成的文件及其权限：

```bash
[root@server ~]# ansible web -m shell -a 'ls -l /data/'
192.168.37.122 | SUCCESS | rc=0 >>
total 28
-rw-rw-rw-   1 root root   12 Dec  6 09:45 name

192.168.37.133 | SUCCESS | rc=0 >>
total 40
-rw-rw-rw- 1 root     root       12 Dec  5 09:45 name
```

可以看出我们的name文件已经生成，并且权限为666。

### 5.4.3 关于覆盖

我们把文件的内容修改一下，然后选择覆盖备份：

```bash
[root@server ~]# ansible web -m copy -a 'content="I am keerya\n" backup=yes dest=/data/name mode=666'
192.168.37.122 | SUCCESS => {
    "backup_file": "/data/name.4394.2017-12-06@09:46:25~", 
    "changed": true, 
    "checksum": "064a68908ab9971ee85dbc08ea038387598e3778", 
    "dest": "/data/name", 
    "gid": 0, 
    "group": "root", 
    "md5sum": "8ca7c11385856155af52e560f608891c", 
    "mode": "0666", 
    "owner": "root", 
    "size": 12, 
    "src": "/root/.ansible/tmp/ansible-tmp-1512438383.78-228128616784888/source", 
    "state": "file", 
    "uid": 0
}
192.168.37.133 | SUCCESS => {
    "backup_file": "/data/name.5962.2017-12-05@09:46:24~", 
    "changed": true, 
    "checksum": "064a68908ab9971ee85dbc08ea038387598e3778", 
    "dest": "/data/name", 
    "gid": 0, 
    "group": "root", 
    "md5sum": "8ca7c11385856155af52e560f608891c", 
    "mode": "0666", 
    "owner": "root", 
    "size": 12, 
    "src": "/root/.ansible/tmp/ansible-tmp-1512438384.0-170718946740009/source", 
    "state": "file", 
    "uid": 0
}
```

现在我们可以去查看一下：

```bash
[root@server ~]# ansible web -m shell -a 'ls -l /data/'
192.168.37.122 | SUCCESS | rc=0 >>
total 28
-rw-rw-rw-   1 root root   12 Dec  6 09:46 name
-rw-rw-rw-   1 root root   10 Dec  6 09:45 name.4394.2017-12-06@09:46:25~

192.168.37.133 | SUCCESS | rc=0 >>
total 40
-rw-rw-rw- 1 root     root       12 Dec  5 09:46 name
-rw-rw-rw- 1 root     root       10 Dec  5 09:45 name.5962.2017-12-05@09:46:24~
```

可以看出，我们的源文件已经被备份，我们还可以查看一下`name`文件的内容：

```bash
[root@server ~]# ansible web -m shell -a 'cat /data/name'
192.168.37.122 | SUCCESS | rc=0 >>
I am keerya

192.168.37.133 | SUCCESS | rc=0 >>
I am keerya
```

证明，这正是我们新导入的文件的内容。

## 5.5 file 模块

该模块主要用于设置文件的属性，比如创建文件、创建链接文件、删除文件等。
下面是一些常见的命令：

> `force`　　#需要在两种情况下强制创建软链接，一种是源文件不存在，但之后会建立的情况下；另一种是目标软链接已存在，需要先取消之前的软链，然后创建新的软链，有两个选项：yes|no
>  `group`　　#定义文件/目录的属组。后面可以加上`mode`：定义文件/目录的权限
>  `owner`　　#定义文件/目录的属主。后面必须跟上`path`：定义文件/目录的路径
>  `recurse`　　#递归设置文件的属性，只对目录有效，后面跟上`src`：被链接的源文件路径，只应用于`state=link`的情况
>  `dest`　　#被链接到的路径，只应用于`state=link`的情况
>  `state`　　#状态，有以下选项：
>
> > `directory`：如果目录不存在，就创建目录
> >  `file`：即使文件不存在，也不会被创建
> >  `link`：创建软链接
> >  `hard`：创建硬链接
> >  `touch`：如果文件不存在，则会创建一个新的文件，如果文件或目录已存在，则更新其最后修改时间
> >  `absent`：删除目录、文件或者取消链接文件

用法举例如下：

### 5.5.1 创建目录

```bash
[root@server ~]# ansible web -m file -a 'path=/data/app state=directory'
192.168.37.122 | SUCCESS => {
    "changed": true, 
    "gid": 0, 
    "group": "root", 
    "mode": "0755", 
    "owner": "root", 
    "path": "/data/app", 
    "size": 6, 
    "state": "directory", 
    "uid": 0
}
192.168.37.133 | SUCCESS => {
    "changed": true, 
    "gid": 0, 
    "group": "root", 
    "mode": "0755", 
    "owner": "root", 
    "path": "/data/app", 
    "size": 4096, 
    "state": "directory", 
    "uid": 0
}
```

我们可以查看一下：

```bash
[root@server ~]# ansible web -m shell -a 'ls -l /data'
192.168.37.122 | SUCCESS | rc=0 >>
total 28
drwxr-xr-x   2 root root    6 Dec  6 10:21 app

192.168.37.133 | SUCCESS | rc=0 >>
total 44
drwxr-xr-x 2 root     root     4096 Dec  5 10:21 app
```

可以看出，我们的目录已经创建完成。

### 5.5.2 创建链接文件

```bash
[root@server ~]# ansible web -m file -a 'path=/data/bbb.jpg src=aaa.jpg state=link'
192.168.37.122 | SUCCESS => {
    "changed": true, 
    "dest": "/data/bbb.jpg", 
    "gid": 0, 
    "group": "root", 
    "mode": "0777", 
    "owner": "root", 
    "size": 7, 
    "src": "aaa.jpg", 
    "state": "link", 
    "uid": 0
}
192.168.37.133 | SUCCESS => {
    "changed": true, 
    "dest": "/data/bbb.jpg", 
    "gid": 0, 
    "group": "root", 
    "mode": "0777", 
    "owner": "root", 
    "size": 7, 
    "src": "aaa.jpg", 
    "state": "link", 
    "uid": 0
}
```

我们可以去查看一下：

```bash
[root@server ~]# ansible web -m shell -a 'ls -l /data'
192.168.37.122 | SUCCESS | rc=0 >>
total 28
-rw-r--r--   1 root root 5649 Dec  5 13:49 aaa.jpg
lrwxrwxrwx   1 root root    7 Dec  6 10:25 bbb.jpg -> aaa.jpg

192.168.37.133 | SUCCESS | rc=0 >>
total 44
-rw-r--r-- 1 root     root     5649 Dec  4 14:44 aaa.jpg
lrwxrwxrwx 1 root     root        7 Dec  5 10:25 bbb.jpg -> aaa.jpg
```

我们的链接文件已经创建成功。

### 5.5.3 删除文件

```bash
[root@server ~]# ansible web -m file -a 'path=/data/a state=absent'
192.168.37.122 | SUCCESS => {
    "changed": true, 
    "path": "/data/a", 
    "state": "absent"
}
192.168.37.133 | SUCCESS => {
    "changed": true, 
    "path": "/data/a", 
    "state": "absent"
}
```

我们可以查看一下：

```bash
[root@server ~]# ansible web -m shell -a 'ls /data/a'
192.168.37.122 | FAILED | rc=2 >>
ls: cannot access /data/a: No such file or directory

192.168.37.133 | FAILED | rc=2 >>
ls: cannot access /data/a: No such file or directory
```

发现已经没有这个文件了。

## 5.6 fetch 模块

该模块用于从远程某主机获取（复制）文件到本地。
有两个选项：

> `dest`：用来存放文件的目录
>  `src`：在远程拉取的文件，并且必须是一个**file**，不能是**目录**

具体举例如下：

```bash
[root@server ~]# ansible web -m fetch -a 'src=/data/hello dest=/data'  
192.168.37.122 | SUCCESS => {
    "changed": true, 
    "checksum": "22596363b3de40b06f981fb85d82312e8c0ed511", 
    "dest": "/data/192.168.37.122/data/hello", 
    "md5sum": "6f5902ac237024bdd0c176cb93063dc4", 
    "remote_checksum": "22596363b3de40b06f981fb85d82312e8c0ed511", 
    "remote_md5sum": null
}
192.168.37.133 | SUCCESS => {
    "changed": true, 
    "checksum": "22596363b3de40b06f981fb85d82312e8c0ed511", 
    "dest": "/data/192.168.37.133/data/hello", 
    "md5sum": "6f5902ac237024bdd0c176cb93063dc4", 
    "remote_checksum": "22596363b3de40b06f981fb85d82312e8c0ed511", 
    "remote_md5sum": null
}
```

我们可以在本机上查看一下文件是否复制成功。要注意，文件保存的路径是我们设置的接收目录下的`被管制主机ip`目录下：

```bash
[root@server ~]# cd /data/
[root@server data]# ls
1  192.168.37.122  192.168.37.133  fastdfs  web
[root@server data]# cd 192.168.37.122
[root@server 192.168.37.122]# ls
data
[root@server 192.168.37.122]# cd data/
[root@server data]# ls
hello
[root@server data]# pwd
/data/192.168.37.122/data
```

## 5.7 cron 模块

该模块适用于管理`cron`计划任务的。
其使用的语法跟我们的`crontab`文件中的语法一致，同时，可以指定以下选项：

> `day=` #日应该运行的工作( 1-31, *, */2, )
>  `hour=` # 小时 ( 0-23, *, */2, )
>  `minute=` #分钟( 0-59, *, */2, )
>  `month=` # 月( 1-12, *, /2, )
>  `weekday=` # 周 ( 0-6 for Sunday-Saturday,, )
>  `job=` #指明运行的命令是什么
>  `name=` #定时任务描述
>  `reboot` # 任务在重启时运行，不建议使用，建议使用special_time
>  `special_time` #特殊的时间范围，参数：reboot（重启时），annually（每年），monthly（每月），weekly（每周），daily（每天），hourly（每小时）
>  `state` #指定状态，present表示添加定时任务，也是默认设置，absent表示删除定时任务
>  `user` # 以哪个用户的身份执行

举例如下：

### 5.7.1 添加计划任务

```bash
[root@server ~]# ansible web -m cron -a 'name="ntp update every 5 min" minute=*/5 job="/sbin/ntpdate 172.17.0.1 &> /dev/null"'
192.168.37.122 | SUCCESS => {
    "changed": true, 
    "envs": [], 
    "jobs": [
        "ntp update every 5 min"
    ]
}
192.168.37.133 | SUCCESS => {
    "changed": true, 
    "envs": [], 
    "jobs": [
        "ntp update every 5 min"
    ]
}
```

我们可以去查看一下：

```bash
[root@server ~]# ansible web -m shell -a 'crontab -l'
192.168.37.122 | SUCCESS | rc=0 >>
#Ansible: ntp update every 5 min
*/5 * * * * /sbin/ntpdate 172.17.0.1 &> /dev/null

192.168.37.133 | SUCCESS | rc=0 >>
#Ansible: ntp update every 5 min
*/5 * * * * /sbin/ntpdate 172.17.0.1 &> /dev/null
```

可以看出，我们的计划任务已经设置成功了。

### 5.7.2 删除计划任务

如果我们的计划任务添加错误，想要删除的话，则执行以下操作：
首先我们查看一下现有的计划任务：

```bash
[root@server ~]# ansible web -m shell -a 'crontab -l'
192.168.37.122 | SUCCESS | rc=0 >>
#Ansible: ntp update every 5 min
*/5 * * * * /sbin/ntpdate 172.17.0.1 &> /dev/null
#Ansible: df everyday
* 15 * * * df -lh >> /tmp/disk_total &> /dev/null

192.168.37.133 | SUCCESS | rc=0 >>
#Ansible: ntp update every 5 min
*/5 * * * * /sbin/ntpdate 172.17.0.1 &> /dev/null
#Ansible: df everyday
* 15 * * * df -lh >> /tmp/disk_total &> /dev/null
```

然后执行删除操作：

```bash
[root@server ~]# ansible web -m cron -a 'name="df everyday" hour=15 job="df -lh >> /tmp/disk_total &> /dev/null" state=absent'
192.168.37.122 | SUCCESS => {
    "changed": true, 
    "envs": [], 
    "jobs": [
        "ntp update every 5 min"
    ]
}
192.168.37.133 | SUCCESS => {
    "changed": true, 
    "envs": [], 
    "jobs": [
        "ntp update every 5 min"
    ]
}
```

删除完成后，我们再查看一下现有的计划任务确认一下：

```bash
[root@server ~]# ansible web -m shell -a 'crontab -l'
192.168.37.122 | SUCCESS | rc=0 >>
#Ansible: ntp update every 5 min
*/5 * * * * /sbin/ntpdate 172.17.0.1 &> /dev/null

192.168.37.133 | SUCCESS | rc=0 >>
#Ansible: ntp update every 5 min
*/5 * * * * /sbin/ntpdate 172.17.0.1 &> /dev/null
```

我们的删除操作已经成功。

## 5.8 yum 模块

顾名思义，该模块主要用于软件的安装。
其选项如下：

> `name=`　　#所安装的包的名称
>  `state=`　　#`present`--->安装， `latest`--->安装最新的, `absent`---> 卸载软件。
>  `update_cache`　　#强制更新yum的缓存
>  `conf_file`　　#指定远程yum安装时所依赖的配置文件（安装本地已有的包）。
>  `disable_pgp_check`　　#是否禁止GPG checking，只用于`present`or `latest`。
>  `disablerepo`　　#临时禁止使用yum库。 只用于安装或更新时。
>  `enablerepo`　　#临时使用的yum库。只用于安装或更新时。

下面我们就来安装一个包试试看：

```bash
[root@server ~]# ansible web -m yum -a 'name=htop state=present'
192.168.37.122 | SUCCESS => {
    "changed": true, 
    "msg": "", 
    "rc": 0, 
    "results": [
        "Loaded plugins: fastestmirror, langpacks\nLoading mirror speeds from cached hostfile\nResolving Dependencies\n--> Running transaction check\n---> Package htop.x86_64 0:2.0.2-1.el7 will be installed\n--> Finished Dependency Resolution\n\nDependencies Resolved\n\n================================================================================\n Package         Arch              Version                Repository       Size\n================================================================================\nInstalling:\n htop            x86_64            2.0.2-1.el7            epel             98 k\n\nTransaction Summary\n================================================================================\nInstall  1 Package\n\nTotal download size: 98 k\nInstalled size: 207 k\nDownloading packages:\nRunning transaction check\nRunning transaction test\nTransaction test succeeded\nRunning transaction\n  Installing : htop-2.0.2-1.el7.x86_64                                      1/1 \n  Verifying  : htop-2.0.2-1.el7.x86_64                                      1/1 \n\nInstalled:\n  htop.x86_64 0:2.0.2-1.el7                                                     \n\nComplete!\n"
    ]
}
192.168.37.133 | SUCCESS => {
    "changed": true, 
    "msg": "Warning: RPMDB altered outside of yum.\n** Found 3 pre-existing rpmdb problem(s), 'yum check' output follows:\nipa-client-4.4.0-12.el7.centos.x86_64 has installed conflicts freeipa-client: ipa-client-4.4.0-12.el7.centos.x86_64\nipa-client-common-4.4.0-12.el7.centos.noarch has installed conflicts freeipa-client-common: ipa-client-common-4.4.0-12.el7.centos.noarch\nipa-common-4.4.0-12.el7.centos.noarch has installed conflicts freeipa-common: ipa-common-4.4.0-12.el7.centos.noarch\n", 
    "rc": 0, 
    "results": [
        "Loaded plugins: fastestmirror, langpacks\nLoading mirror speeds from cached hostfile\nResolving Dependencies\n--> Running transaction check\n---> Package htop.x86_64 0:2.0.2-1.el7 will be installed\n--> Finished Dependency Resolution\n\nDependencies Resolved\n\n================================================================================\n Package         Arch              Version                Repository       Size\n================================================================================\nInstalling:\n htop            x86_64            2.0.2-1.el7            epel             98 k\n\nTransaction Summary\n================================================================================\nInstall  1 Package\n\nTotal download size: 98 k\nInstalled size: 207 k\nDownloading packages:\nRunning transaction check\nRunning transaction test\nTransaction test succeeded\nRunning transaction\n  Installing : htop-2.0.2-1.el7.x86_64                                      1/1 \n  Verifying  : htop-2.0.2-1.el7.x86_64                                      1/1 \n\nInstalled:\n  htop.x86_64 0:2.0.2-1.el7                                                     \n\nComplete!\n"
    ]
}
```

安装成功。

## 5.9 service 模块

该模块用于服务程序的管理。
其主要选项如下：

> `arguments` #命令行提供额外的参数
>  `enabled` #设置开机启动。
>  `name=` #服务名称
>  `runlevel` #开机启动的级别，一般不用指定。
>  `sleep` #在重启服务的过程中，是否等待。如在服务关闭以后等待2秒再启动。(定义在剧本中。)
>  `state` #有四种状态，分别为：`started`--->启动服务， `stopped`--->停止服务， `restarted`--->重启服务， `reloaded`--->重载配置

下面是一些例子：

### 5.9.1 开启服务并设置自启动

```bash
[root@server ~]# ansible web -m service -a 'name=nginx state=started enabled=true' 
192.168.37.122 | SUCCESS => {
    "changed": true, 
    "enabled": true, 
    "name": "nginx", 
    "state": "started", 
    ……
}
192.168.37.133 | SUCCESS => {
    "changed": true, 
    "enabled": true, 
    "name": "nginx", 
    "state": "started", 
    ……
}
```

我们可以去查看一下端口是否打开：

```bash
[root@server ~]# ansible web -m shell -a 'ss -ntl'
192.168.37.122 | SUCCESS | rc=0 >>
State      Recv-Q Send-Q Local Address:Port               Peer Address:Port              
LISTEN     0      128          *:80                       *:*                                  

192.168.37.133 | SUCCESS | rc=0 >>
State      Recv-Q Send-Q Local Address:Port               Peer Address:Port                    
LISTEN     0      128          *:80                       *:*                  
```

可以看出我们的80端口已经打开。

### 5.9.2 关闭服务

我们也可以通过该模块来关闭我们的服务：

```bash
[root@server ~]# ansible web -m service -a 'name=nginx state=stopped'
192.168.37.122 | SUCCESS => {
    "changed": true, 
    "name": "nginx", 
    "state": "stopped", 
	……
}
192.168.37.133 | SUCCESS => {
    "changed": true, 
    "name": "nginx", 
    "state": "stopped", 
	……
}
```

一样的，我们来查看一下端口：

```bash
[root@server ~]# ansible web -m shell -a 'ss -ntl | grep 80'
192.168.37.122 | FAILED | rc=1 >>

192.168.37.133 | FAILED | rc=1 >>
```

可以看出，我们已经没有80端口了，说明我们的nginx服务已经关闭了。

## 5.10 user 模块

该模块主要是用来管理用户账号。
其主要选项如下：

> `comment`　　# 用户的描述信息
>  `createhome`　　# 是否创建家目录
>  `force`　　# 在使用state=absent时, 行为与userdel –force一致.
>  `group`　　# 指定基本组
>  `groups`　　# 指定附加组，如果指定为(groups=)表示删除所有组
>  `home`　　# 指定用户家目录
>  `move_home`　　# 如果设置为home=时, 试图将用户主目录移动到指定的目录
>  `name`　　# 指定用户名
>  `non_unique`　　# 该选项允许改变非唯一的用户ID值
>  `password`　　# 指定用户密码
>  `remove`　　# 在使用state=absent时, 行为是与userdel –remove一致
>  `shell`　　# 指定默认shell
>  `state`　　# 设置帐号状态，不指定为创建，指定值为absent表示删除
>  `system`　　# 当创建一个用户，设置这个用户是系统用户。这个设置不能更改现有用户
>  `uid`　　# 指定用户的uid

举例如下：

### 5.10.1 添加一个用户并指定其 uid

```bash
[root@server ~]# ansible web -m user -a 'name=keer uid=11111'
192.168.37.122 | SUCCESS => {
    "changed": true, 
    "comment": "", 
    "createhome": true, 
    "group": 11111, 
    "home": "/home/keer", 
    "name": "keer", 
    "shell": "/bin/bash", 
    "state": "present", 
    "stderr": "useradd: warning: the home directory already exists.\nNot copying any file from skel directory into it.\nCreating mailbox file: File exists\n", 
    "system": false, 
    "uid": 11111
}
192.168.37.133 | SUCCESS => {
    "changed": true, 
    "comment": "", 
    "createhome": true, 
    "group": 11111, 
    "home": "/home/keer", 
    "name": "keer", 
    "shell": "/bin/bash", 
    "state": "present", 
    "stderr": "useradd: warning: the home directory already exists.\nNot copying any file from skel directory into it.\nCreating mailbox file: File exists\n", 
    "system": false, 
    "uid": 11111
}
```

添加完成，我们可以去查看一下：

```bash
[root@server ~]# ansible web -m shell -a 'cat /etc/passwd |grep keer'
192.168.37.122 | SUCCESS | rc=0 >>
keer:x:11111:11111::/home/keer:/bin/bash

192.168.37.133 | SUCCESS | rc=0 >>
keer:x:11111:11111::/home/keer:/bin/bash
```

### 5.10.2 删除用户

```bash
[root@server ~]# ansible web -m user -a 'name=keer state=absent'
192.168.37.122 | SUCCESS => {
    "changed": true, 
    "force": false, 
    "name": "keer", 
    "remove": false, 
    "state": "absent"
}
192.168.37.133 | SUCCESS => {
    "changed": true, 
    "force": false, 
    "name": "keer", 
    "remove": false, 
    "state": "absent"
}
```

一样的，删除之后，我们去看一下：

```bash
[root@server ~]# ansible web -m shell -a 'cat /etc/passwd |grep keer'
192.168.37.122 | FAILED | rc=1 >>

192.168.37.133 | FAILED | rc=1 >>
```

发现已经没有这个用户了。

## 5.11 group 模块

该模块主要用于添加或删除组。
常用的选项如下：

> `gid=`　　#设置组的GID号
>  `name=`　　#指定组的名称
>  `state=`　　#指定组的状态，默认为创建，设置值为`absent`为删除
>  `system=`　　#设置值为`yes`，表示创建为系统组

举例如下：

### 5.11.1 创建组

```bash
[root@server ~]# ansible web -m group -a 'name=sanguo gid=12222'
192.168.37.122 | SUCCESS => {
    "changed": true, 
    "gid": 12222, 
    "name": "sanguo", 
    "state": "present", 
    "system": false
}
192.168.37.133 | SUCCESS => {
    "changed": true, 
    "gid": 12222, 
    "name": "sanguo", 
    "state": "present", 
    "system": false
}
```

创建过后，我们来查看一下：

```bash
[root@server ~]# ansible web -m shell -a 'cat /etc/group | grep 12222' 
192.168.37.122 | SUCCESS | rc=0 >>
sanguo:x:12222:

192.168.37.133 | SUCCESS | rc=0 >>
sanguo:x:12222:
```

可以看出，我们的组已经创建成功了。

### 5.11.2 删除组

```bash
[root@server ~]# ansible web -m group -a 'name=sanguo state=absent'
192.168.37.122 | SUCCESS => {
    "changed": true, 
    "name": "sanguo", 
    "state": "absent"
}
192.168.37.133 | SUCCESS => {
    "changed": true, 
    "name": "sanguo", 
    "state": "absent"
}
```

照例查看一下：

```bash
[root@server ~]# ansible web -m shell -a 'cat /etc/group | grep 12222' 
192.168.37.122 | FAILED | rc=1 >>

192.168.37.133 | FAILED | rc=1 >>
```

已经没有这个组的相关信息了。

## 5.12 script 模块

该模块用于将本机的脚本在被管理端的机器上运行。
该模块直接指定脚本的路径即可，我们通过例子来看一看到底如何使用的：
首先，我们写一个脚本，并给其加上执行权限：

```bash
[root@server ~]# vim /tmp/df.sh
	#!/bin/bash

	date >> /tmp/disk_total.log
	df -lh >> /tmp/disk_total.log 
[root@server ~]# chmod +x /tmp/df.sh 
```

然后，我们直接运行命令来实现在被管理端执行该脚本：

```bash
[root@server ~]# ansible web -m script -a '/tmp/df.sh'
192.168.37.122 | SUCCESS => {
    "changed": true, 
    "rc": 0, 
    "stderr": "Shared connection to 192.168.37.122 closed.\r\n", 
    "stdout": "", 
    "stdout_lines": []
}
192.168.37.133 | SUCCESS => {
    "changed": true, 
    "rc": 0, 
    "stderr": "Shared connection to 192.168.37.133 closed.\r\n", 
    "stdout": "", 
    "stdout_lines": []
}
```

照例查看一下文件内容：

```bash
[root@server ~]# ansible web -m shell -a 'cat /tmp/disk_total.log'
192.168.37.122 | SUCCESS | rc=0 >>
Tue Dec  5 15:58:21 CST 2017
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda2        47G  4.4G   43G  10% /
devtmpfs        978M     0  978M   0% /dev
tmpfs           993M   84K  993M   1% /dev/shm
tmpfs           993M  9.1M  984M   1% /run
tmpfs           993M     0  993M   0% /sys/fs/cgroup
/dev/sda3        47G   33M   47G   1% /app
/dev/sda1       950M  153M  798M  17% /boot
tmpfs           199M   16K  199M   1% /run/user/42
tmpfs           199M     0  199M   0% /run/user/0

192.168.37.133 | SUCCESS | rc=0 >>
Tue Dec  5 15:58:21 CST 2017
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda2        46G  4.1G   40G  10% /
devtmpfs        898M     0  898M   0% /dev
tmpfs           912M   84K  912M   1% /dev/shm
tmpfs           912M  9.0M  903M   1% /run
tmpfs           912M     0  912M   0% /sys/fs/cgroup
/dev/sda3       3.7G   15M  3.4G   1% /app
/dev/sda1       1.9G  141M  1.6G   9% /boot
tmpfs           183M   16K  183M   1% /run/user/42
tmpfs           183M     0  183M   0% /run/user/0
```

可以看出已经执行成功了。

## 5.13 setup 模块

该模块主要用于收集信息，是通过调用facts组件来实现的。
facts组件是Ansible用于采集被管机器设备信息的一个功能，我们可以使用setup模块查机器的所有facts信息，可以使用filter来查看指定信息。整个facts信息被包装在一个JSON格式的数据结构中，ansible_facts是最上层的值。
facts就是变量，内建变量  。每个主机的各种信息，cpu颗数、内存大小等。会存在facts中的某个变量中。调用后返回很多对应主机的信息，在后面的操作中可以根据不同的信息来做不同的操作。如redhat系列用yum安装，而debian系列用apt来安装软件。

### 5.13.1 查看信息

我们可以直接用命令获取到变量的值，具体我们来看看例子：

```bash
[root@server ~]# ansible web -m setup -a 'filter="*mem*"'	#查看内存
192.168.37.122 | SUCCESS => {
    "ansible_facts": {
        "ansible_memfree_mb": 1116, 
        "ansible_memory_mb": {
            "nocache": {
                "free": 1397, 
                "used": 587
            }, 
            "real": {
                "free": 1116, 
                "total": 1984, 
                "used": 868
            }, 
            "swap": {
                "cached": 0, 
                "free": 3813, 
                "total": 3813, 
                "used": 0
            }
        }, 
        "ansible_memtotal_mb": 1984
    }, 
    "changed": false
}
192.168.37.133 | SUCCESS => {
    "ansible_facts": {
        "ansible_memfree_mb": 1203, 
        "ansible_memory_mb": {
            "nocache": {
                "free": 1470, 
                "used": 353
            }, 
            "real": {
                "free": 1203, 
                "total": 1823, 
                "used": 620
            }, 
            "swap": {
                "cached": 0, 
                "free": 3813, 
                "total": 3813, 
                "used": 0
            }
        }, 
        "ansible_memtotal_mb": 1823
    }, 
    "changed": false
}
```

我们可以通过命令查看一下内存的大小以确认一下是否一致：

```bash
[root@server ~]# ansible web -m shell -a 'free -m'
192.168.37.122 | SUCCESS | rc=0 >>
              total        used        free      shared  buff/cache   available
Mem:           1984         404        1122           9         457        1346
Swap:          3813           0        3813

192.168.37.133 | SUCCESS | rc=0 >>
              total        used        free      shared  buff/cache   available
Mem:           1823         292        1207           9         323        1351
Swap:          3813           0        3813
```

可以看出信息是一致的。

### 5.13.2 保存信息

我们的setup模块还有一个很好用的功能就是可以保存我们所筛选的信息至我们的主机上，同时，文件名为我们被管制的主机的IP，这样方便我们知道是哪台机器出的问题。
我们可以看一看例子：

```bash
[root@server tmp]# ansible web -m setup -a 'filter="*mem*"' --tree /tmp/facts
192.168.37.122 | SUCCESS => {
    "ansible_facts": {
        "ansible_memfree_mb": 1115, 
        "ansible_memory_mb": {
            "nocache": {
                "free": 1396, 
                "used": 588
            }, 
            "real": {
                "free": 1115, 
                "total": 1984, 
                "used": 869
            }, 
            "swap": {
                "cached": 0, 
                "free": 3813, 
                "total": 3813, 
                "used": 0
            }
        }, 
        "ansible_memtotal_mb": 1984
    }, 
    "changed": false
}
192.168.37.133 | SUCCESS => {
    "ansible_facts": {
        "ansible_memfree_mb": 1199, 
        "ansible_memory_mb": {
            "nocache": {
                "free": 1467, 
                "used": 356
            }, 
            "real": {
                "free": 1199, 
                "total": 1823, 
                "used": 624
            }, 
            "swap": {
                "cached": 0, 
                "free": 3813, 
                "total": 3813, 
                "used": 0
            }
        }, 
        "ansible_memtotal_mb": 1823
    }, 
    "changed": false
}
```

然后我们可以去查看一下：

```bash
[root@server ~]# cd /tmp/facts/
[root@server facts]# ls
192.168.37.122  192.168.37.133
[root@server facts]# cat 192.168.37.122 
{"ansible_facts": {"ansible_memfree_mb": 1115, "ansible_memory_mb": {"nocache": {"free": 1396, "used": 588}, "real": {"free": 1115, "total": 1984, "used": 869}, "swap": {"cached": 0, "free": 3813, "total": 3813, "used": 0}}, "ansible_memtotal_mb": 1984}, "changed": false}
```