- [自动化运维工具——ansible详解（二）](https://www.cnblogs.com/keerya/p/8004566.html)

# 一、Ansible playbook 简介

**playbook 是 ansible 用于配置，部署，和管理被控节点的剧本。**
通过 playbook 的详细描述，执行其中的一系列 tasks ，可以让远端主机达到预期的状态。playbook 就像 Ansible 控制器给被控节点列出的的一系列 to-do-list ，而被控节点必须要完成。
也可以这么理解，playbook 字面意思，即剧本，现实中由演员按照剧本表演，在Ansible中，这次由计算机进行表演，由计算机安装，部署应用，提供对外服务，以及组织计算机处理各种各样的事情。

# 二、Ansible playbook使用场景

执行一些简单的任务，使用ad-hoc命令可以方便的解决问题，但是有时一个设施过于复杂，需要大量的操作时候，执行的ad-hoc命令是不适合的，这时最好使用playbook。
就像执行shell命令与写shell脚本一样，也可以理解为批处理任务，不过playbook有自己的语法格式。
使用playbook你可以方便的重用这些代码，可以移植到不同的机器上面，像函数一样，最大化的利用代码。在你使用Ansible的过程中，你也会发现，你所处理的大部分操作都是编写playbook。可以把常见的应用都编写成playbook，之后管理服务器会变得十分简单。

# 三、Ansible playbook格式

## 3.1 格式简介

**playbook由YMAL语言编写。**YAML( /ˈjæməl/  )参考了其他多种语言，包括：XML、C语言、Python、Perl以及电子邮件格式RFC2822，Clark  Evans在2001年5月在首次发表了这种语言，另外Ingy döt Net与OrenBen-Kiki也是这语言的共同设计者。
YMAL格式是类似于JSON的文件格式，便于人理解和阅读，同时便于书写。首先学习了解一下YMAL的格式，对我们后面书写playbook很有帮助。以下为playbook常用到的YMAL格式：

1. 文件的第一行应该以 "---" (三个连字符)开始，表明YMAL文件的开始。
2. 在同一行中，#之后的内容表示注释，类似于shell，python和ruby。
3. YMAL中的列表元素以”-”开头然后紧跟着一个空格，后面为元素内容。
4. 同一个列表中的元素应该保持相同的缩进。否则会被当做错误处理。
5. play中hosts，variables，roles，tasks等对象的表示方法都是键值中间以":"分隔表示，":"后面还要增加一个空格。

下面是一个举例：

```yaml
---
#安装与运行mysql服务
- hosts: node1
  remote_user: root
  tasks:
  
    - name: install mysql-server package
      yum: name=mysql-server state=present
    - name: starting mysqld service
      service: name=mysql state=started
```

我们的文件名称应该以`.yml`结尾，像我们上面的例子就是`mysql.yml`。其中，有三个部分组成：

> `host部分`：使用 hosts 指示使用哪个主机或主机组来运行下面的 tasks ，每个 playbook 都必须指定 hosts ，hosts也**可以使用通配符格式**。主机或主机组在 inventory 清单中指定，可以使用系统默认的`/etc/ansible/hosts`，也可以自己编辑，在运行的时候加上`-i`选项，指定清单的位置即可。在运行清单文件的时候，`–list-hosts`选项会显示那些主机将会参与执行 task 的过程中。
>  `remote_user`：指定远端主机中的哪个用户来登录远端系统，在远端系统执行 task 的用户，可以任意指定，也可以使用 sudo，但是用户必须要有执行相应 task 的权限。
>  `tasks`：指定远端主机将要执行的一系列动作。tasks 的核心为 ansible 的模块，前面已经提到模块的用法。tasks 包含 `name` 和`要执行的模块`，name 是可选的，只是为了便于用户阅读，不过还是建议加上去，模块是必须的，同时也要给予模块相应的参数。

使用ansible-playbook运行playbook文件，得到如下输出信息，输出内容为JSON格式。并且由不同颜色组成，便于识别。一般而言

- 绿色代表执行成功，系统保持原样
- 黄色代表系统代表系统状态发生改变
- 红色代表执行失败，显示错误输出

执行有三个步骤：1、收集facts 2、执行tasks 3、报告结果
 ![img](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171208112235999-1825222840.png)

## 3.2 核心元素

Playbook的核心元素：

> `Hosts`：主机组；
>  `Tasks`：任务列表；
>  `Variables`：变量，设置方式有四种；
>  `Templates`：包含了模板语法的文本文件；
>  `Handlers`：由特定条件触发的任务；

## 3.3 基本组件

Playbooks配置文件的基础组件：

> `Hosts`：运行指定任务的目标主机
>  `remoute_user`：在远程主机上执行任务的用户；
>  `sudo_user`：
>  `tasks`：任务列表
>
> > 　　格式：
> >  　　　tasks：
> >  　　　　　– name: TASK_NAME
> >  　　　　　   module: arguments
> >  　　　　　   notify: HANDLER_NAME
> >  　　　　　   handlers:
> >  　　　　　– name: HANDLER_NAME
> >  　　　　　   module: arguments

> `模块，模块参数`：
>
> > 　　格式：
> >  　　　(1) action: module arguments
> >  　　　(2) module: arguments
> >  　　　注意：shell和command模块后面直接跟命令，而非key=value类的参数列表；

> `handlers`：任务，在特定条件下触发；接收到其它任务的通知时被触发；

(1) 某任务的状态在运行后为changed时，可通过“notify”通知给相应的handlers；
(2) 任务可以通过“tags“打标签，而后可在ansible-playbook命令上使用-t指定进行调用；

### 3.3.1 举例

#### ① 定义playbook

```bash
[root@server ~]# cd /etc/ansible
[root@server ansible]# vim nginx.yml
---
- hosts: web
  remote_user: root
  tasks:

    - name: install nginx
      yum: name=nginx state=present
    - name: copy nginx.conf
      copy: src=/tmp/nginx.conf dest=/etc/nginx/nginx.conf backup=yes
      notify: reload　　　　#当nginx.conf发生改变时，通知给相应的handlers
      tags: reloadnginx　　　#打标签
    - name: start nginx service
      service: name=nginx state=started
      tags: startnginx　　　#打标签

  handlers:　　#注意，前面没有-，是两个空格
    - name: reload
      service: name=nginx state=restarted　　#为了在进程中能看出来
```

#### ② 测试运行结果

写完了以后，我们就可以运行了：

```bash
[root@server ansible]# ansible-playbook nginx.yml
```

![img](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171208112249906-1356198395.png)

现在我们可以看看两台机器的端口是否开启：

```bash
[root@server ansible]# ansible web -m shell -a 'ss -nutlp |grep nginx'
192.168.37.122 | SUCCESS | rc=0 >>
tcp    LISTEN     0      128       *:80                    *:*                   users:(("nginx",pid=8304,fd=6),("nginx",pid=8303,fd=6))

192.168.37.133 | SUCCESS | rc=0 >>
tcp    LISTEN     0      128       *:80                    *:*                   users:(("nginx",pid=9671,fd=6),("nginx",pid=9670,fd=6))
```

#### ③ 测试标签

我们在里面已经打上了一个标签，所以可以直接引用标签。但是我们需要先把服务关闭，再来运行剧本并引用标签：

```bash
[root@server ansible]# ansible web -m shell -a 'systemctl stop nginx'
[root@server ansible]# ansible-playbook nginx.yml -t startnginx
```

![img](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171208112258687-1002351873.png)

####  **④ 测试notify**

我们还做了一个`notify`，来测试一下：
首先，它的触发条件是配置文件被改变，所以我们去把配置文件中的端口改一下：

```bash
[root@server ansible]# vim /tmp/nginx.conf
	listen       8080;
```

然后我们重新加载一下这个剧本：

 ![img](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171208112308109-1548774386.png)

发现我们执行的就是reload段以及我们定义的`notify`部分。
我们来看一看我们的端口号：

```bash
[root@server ansible]# ansible web -m shell -a 'ss -ntlp | grep nginx'
192.168.37.122 | SUCCESS | rc=0 >>
LISTEN     0      128          *:8080                     *:*                   users:(("nginx",pid=2097,fd=6),("nginx",pid=2096,fd=6))

192.168.37.133 | SUCCESS | rc=0 >>
LISTEN     0      128          *:8080                     *:*                   users:(("nginx",pid=3061,fd=6),("nginx",pid=3060,fd=6))
```

可以看出，我们的nginx端口已经变成了8080。

## 3.4 variables 部分

上文中，我们说到了`variables`是变量，有四种定义方法，现在我们就来说说这四种定义方法：

### ① facts ：可直接调用

　　上一篇中，我们有说到`setup`这个模块，这个模块就是通过调用facts组件来实现的。我们这里的`variables`也可以直接调用`facts`组件。
 　具体的`facters`我们可以使用`setup`模块来获取，然后直接放入我们的剧本中调用即可。

### ② 用户自定义变量

　　我们也可以直接使用用户自定义变量，想要自定义变量有以下两种方式：

> 通过命令行传入

　　`ansible-playbook`命令的命令行中的`-e VARS, --extra-vars=VARS`，这样就可以直接把自定义的变量传入。

> 在playbook中定义变量

　　我们也可以直接在playbook中定义我们的变量：

```yaml
vars:
　　- var1: value1
　　- - var2: value2
```

### 举例

#### ① 定义剧本

 　我们就使用全局替换把我们刚刚编辑的文件修改一下：

```bash
[root@server ansible]# vim nginx.yml
```

![img](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171208112328234-1706127649.png)
 ![img](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171208112334765-1675703855.png)

这样一来，我们的剧本就定义完成了。

#### ② 拷贝配置文件

我们想要在被监管的机器上安装什么服务的话，就直接在我们的server端上把该服务的配置文件拷贝到我们的`/tmp/`目录下。这样我们的剧本才能正常运行。
我们就以`keepalived`服务为例：

```bash
[root@server ansible]# cp /etc/keepalived/keepalived.conf /tmp/keepalived.conf
```

#### ③ 运行剧本，变量由命令行传入

```bash
[root@server ansible]# ansible-playbook nginx.yml -e rpmname=keepalived
```

![img](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171208112345843-507673332.png)

#### ④ 修改剧本，直接定义变量

同样的，我们可以直接在剧本中把变量定义好，这样就不需要在通过命令行传入了。以后想要安装不同的服务，直接在剧本里把变量修改一下即可。

```bash
[root@server ansible]# vim nginx.yml
```

![img](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171208112356562-1275040347.png)

#### ⑤ 运行定义过变量的剧本

我们刚刚已经把变量定义在剧本里面了。现在我们来运行一下试试看：

```bash
[root@server ansible]# ansible-playbook nginx.yml
```

![img](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171208112404531-432662099.png)

发现这样也是可以的~

### ③ 通过roles传递变量

具体的，我们下文中说到 roles 的时候再详细说明。这里是[传送带](https://www.cnblogs.com/keerya/p/8004566.html#jump)

### ④  Host Inventory

我们也可以直接在主机清单中定义。
定义的方法如下：

> 向不同的主机传递不同的变量：

```
　　IP/HOSTNAME varaiable=value var2=value2
```

> 向组中的主机传递相同的变量：

```
　　[groupname:vars]
　　variable=value
```

## 3.5 模板 templates

模板是一个文本文件，嵌套有脚本（使用模板编程语言编写）。
`Jinja2`：Jinja2是python的一种模板语言，以Django的模板语言为原本。
 模板支持：

> 　　字符串：使用单引号或双引号；
>  　数字：整数，浮点数；
>  　列表：[item1, item2, ...]
>  　元组：(item1, item2, ...)
>  　字典：{key1:value1, key2:value2, ...}
>  　布尔型：true/false
>  　算术运算：
>  　　　+, -, *, /, //, %, **
>  　比较操作：
>  　　　==, !=, >, >=, <, <=
>  　逻辑运算：
>  　　　and, or, not

通常来说，模板都是通过引用变量来运用的。

### 3.5.1 举例

#### ① 定义模板

我们直接把之前定义的`/tmp/nginx.conf`改个名，然后编辑一下，就可以定义成我们的模板文件了：

```bash
[root@server ansible]# cd /tmp
[root@server tmp]# mv nginx.conf nginx.conf.j2
[root@server tmp]# vim nginx.conf.j2
	worker_processes  {{ ansible_processor_vcpus }};
	listen       {{ nginxport }};
```

#### ② 修改剧本

我们现在需要去修改剧本来定义变量：

```bash
[root@server ansible]# vim nginx.yml
```

![img](https://images2017.cnblogs.com/blog/1204916/201712/1204916-20171208112442234-829367844.png)

需要修改的部分如图所示。

#### ③ 运行剧本

上面的准备工作完成后，我们就可以去运行剧本了：

```bash
[root@server ansible]# ansible-playbook nginx.yml -t reloadnginx

PLAY [web] *********************************************************************

TASK [setup] *******************************************************************
ok: [192.168.37.122]
ok: [192.168.37.133]

TASK [copy nginx.conf] *********************************************************
ok: [192.168.37.122]
ok: [192.168.37.133]

PLAY RECAP *********************************************************************
192.168.37.122             : ok=2    changed=0    unreachable=0    failed=0   
192.168.37.133             : ok=2    changed=0    unreachable=0    failed=0 
```

## 3.6 条件测试

when语句：在task中使用，jinja2的语法格式。
举例如下：

```yaml
tasks:
- name: install conf file to centos7
  template: src=files/nginx.conf.c7.j2
  when: ansible_distribution_major_version == "7"
- name: install conf file to centos6
  template: src=files/nginx.conf.c6.j2
  when: ansible_distribution_major_version == "6"
```

循环：迭代，需要重复执行的任务；
对迭代项的引用，固定变量名为"item"，而后，要在task中使用with_items给定要迭代的元素列表；
举例如下：

```yaml
tasks:
- name: unstall web packages
  yum: name={{ item }} state=absent
  with_items:
  - httpd
  - php
  - php-mysql
```

## 3.7 字典

ansible playbook 还支持字典功能。举例如下：

```yaml
- name: install some packages
  yum: name={{ item }} state=present
  with_items:
    - nginx
    - memcached
    - php-fpm
- name: add some groups
  group: name={{ item }} state=present
  with_items:
    - group11
    - group12
    - group13
- name: add some users
  user: name={{ item.name }} group={{ item.group }} state=present
  with_items:
    - { name: 'user11', group: 'group11' }
    - { name: 'user12', group: 'group12' }
    - { name: 'user13', group: 'group13' }
```

## 3.8 角色订制：roles

### ① 简介

对于以上所有的方式有个弊端就是无法实现复用假设在同时部署Web、db、ha 时或不同服务器组合不同的应用就需要写多个yml文件。很难实现灵活的调用。

roles 用于层次性、结构化地组织playbook。roles 能够根据层次型结构自动装载变量文件、tasks以及handlers等。要使用roles只需要在playbook中使用include指令即可。简单来讲，roles就是通过分别将变量(vars)、文件(file)、任务(tasks)、模块(modules)及处理器(handlers)放置于单独的目录中，并可以便捷地include它们的一种机制。角色一般用于基于主机构建服务的场景中，但也可以是用于构建守护进程等场景中。

### ② 角色集合

角色集合：roles/
 mysql/
 httpd/
 nginx/
 files/：存储由copy或script等模块调用的文件；
 tasks/：此目录中至少应该有一个名为main.yml的文件，用于定义各task；其它的文件需要由main.yml进行“包含”调用；
 handlers/：此目录中至少应该有一个名为main.yml的文件，用于定义各handler；其它的文件需要由main.yml进行“包含”调用；
 vars/：此目录中至少应该有一个名为main.yml的文件，用于定义各variable；其它的文件需要由main.yml进行“包含”调用；
 templates/：存储由template模块调用的模板文本；
 meta/：此目录中至少应该有一个名为main.yml的文件，定义当前角色的特殊设定及其依赖关系；其它的文件需要由main.yml进行“包含”调用；
 default/：此目录中至少应该有一个名为main.yml的文件，用于设定默认变量；

### ③ 角色定制实例

#### 1. 在roles目录下生成对应的目录结构

```bash
[root@server ansible]# cd roles/
[root@server roles]# ls
[root@server roles]# mkdir -pv ./{nginx,mysql,httpd}/{files,templates,vars,tasks,handlers,meta,default}
[root@server roles]# tree
.
├── httpd
│   ├── default
│   ├── files
│   ├── handlers
│   ├── meta
│   ├── tasks
│   ├── templates
│   └── vars
├── mysql
│   ├── default
│   ├── files
│   ├── handlers
│   ├── meta
│   ├── tasks
│   ├── templates
│   └── vars
└── nginx
    ├── default
    ├── files
    ├── handlers
    ├── meta
    ├── tasks
    ├── templates
    └── vars

24 directories, 0 files
```

#### 2. 定义配置文件

我们需要修改的配置文件为`/tasks/main.yml`，下面，我们就来修改一下：

```yaml
[root@server roles]# vim nginx/tasks/main.yml
- name: cp
  copy: src=nginx-1.10.2-1.el7.ngx.x86_64.rpm dest=/tmp/nginx-1.10.2-1.el7.ngx.x86_64.rpm
- name: install
  yum: name=/tmp/nginx-1.10.2-1.el7.ngx.x86_64.rpm state=latest
- name: conf
  template: src=nginx.conf.j2 dest=/etc/nginx/nginx.conf
  tags: nginxconf
  notify: new conf to reload
- name: start service
  service: name=nginx state=started enabled=true
```

#### 3. 放置我们所需要的文件到指定目录

因为我们定义的角色已经有了新的组成方式，所以我们需要把文件都放到指定的位置，这样，才能让配置文件找到这些并进行加载。

rpm包放在`files`目录下，模板放在`templates`目录下：

```bash
[root@server nginx]# cp /tmp/nginx-1.10.2-1.el7.ngx.x86_64.rpm ./files/
[root@server nginx]# cp /tmp/nginx.conf.j2 ./templates/
[root@server nginx]# tree
.
├── default
├── files
│   └── nginx-1.10.2-1.el7.ngx.x86_64.rpm
├── handlers
├── meta
├── tasks
│   └── main.yml
├── templates
│   └── nginx.conf.j2
└── vars

7 directories, 3 files
```

#### 4. 修改变量文件

我们在模板中定义的变量，也要去配置文件中加上：

```
[root@server nginx]# vim vars/main.yml
nginxprot: 9999
```

#### 5. 定义handlers文件

我们在配置文件中定义了`notify`，所以我么也需要定义`handlers`，我们来修改配置文件：

```yaml
[root@server nginx]# vim handlers/main.yml
- name: new conf to reload
  service: name=nginx state=restarted
```

#### 6. 定义剧本文件

接下来，我们就来定义剧本文件，由于大部分设置我们都单独配置在了roles里面，所以，接下来剧本就只需要写一点点内容即可：

```bash
[root@server ansible]# vim roles.yml 
- hosts: web
  remote_user: root
  roles:
    - nginx
```

#### 7. 启动服务

剧本定义完成以后，我们就可以来启动服务了：

```bash
[root@server ansible]# ansible-playbook roles.yml

PLAY [web] *********************************************************************

TASK [setup] *******************************************************************
ok: [192.168.37.122]
ok: [192.168.37.133]

TASK [nginx : cp] **************************************************************
ok: [192.168.37.122]
ok: [192.168.37.133]

TASK [nginx : install] *********************************************************
changed: [192.168.37.122]
changed: [192.168.37.133]

TASK [nginx : conf] ************************************************************
changed: [192.168.37.122]
changed: [192.168.37.133]

TASK [nginx : start service] ***************************************************
changed: [192.168.37.122]
changed: [192.168.37.133]

RUNNING HANDLER [nginx : new conf to reload] ***********************************
changed: [192.168.37.122]
changed: [192.168.37.133]

PLAY RECAP *********************************************************************
192.168.37.122             : ok=6    changed=4    unreachable=0    failed=0   
192.168.37.133             : ok=6    changed=4    unreachable=0    failed=0   
```

启动过后照例查看端口号：

```bash
[root@server ansible]# ansible web -m shell -a "ss -ntulp |grep 9999"
192.168.37.122 | SUCCESS | rc=0 >>
tcp    LISTEN     0      128       *:9999                  *:*                   users:(("nginx",pid=7831,fd=6),("nginx",pid=7830,fd=6),("nginx",pid=7829,fd=6))

192.168.37.133 | SUCCESS | rc=0 >>
tcp    LISTEN     0      128       *:9999                  *:*                   users:(("nginx",pid=9654,fd=6),("nginx",pid=9653,fd=6),("nginx",pid=9652,fd=6))
```

可以看出我们的剧本已经执行成功。