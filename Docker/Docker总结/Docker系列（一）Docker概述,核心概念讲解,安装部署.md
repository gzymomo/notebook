部分内容参考链接：

- [Docker实战总结（非常全面，建议收藏）](https://segmentfault.com/a/1190000024505902)



# 一、  Docker概述

Docker是一个开源的应用容器引擎（基于Go语言开发），让开发者可以打包他们的应用以及依赖包到一个可移植的容器中，然后发布到任何流行的Linux机器上，也可以实现虚拟化，容器是完全使用沙箱机制，相互之间不会有任何接口。简言之，就是可以在Linux上镜像使用的这么一个容器。



Docker可以在容器内部快速自动化部署应用，并可以通过内核虚拟化技术（namespaces及cgroups等）来提供容器的资源隔离与安全保障等。

> Docker的思想来自于集装箱，集装箱解决了什么问题？在一艘大船上，可以把货物规整的摆放起来。并且各种各样的货物被集装箱标准化了，集装箱和集装箱之间不会互相影响。那么我就不需要专门运送水果的船和专门运送化学品的船了。只要这些货物在集装箱里封装的好好的，那我就可以用一艘大船把他们都运走。



简单的理解，<font color='red'>docker就是一个软件集装箱化平台，就像船只、火车、卡车运输集装箱而不论其内部的货物一样，软件容器充当软件部署的标准单元，其中可以包含不同的代码和依赖项。</font>

按照这种方式容器化软件，开发人员和 IT 专业人员只需进行极少修改或不修改，即可将其部署到不同的环境，如果出现的故障，也可以通过镜像，快速恢复服务。

## 1.1 Docker的优势

![image-20210202112442718](http://lovebetterworld.com/image-20210202112442718.png)



# 二、从容器化技术说起

## 2.1 背景

在虚拟机和云计算较为成熟的时候，各家公司想在云服务器上部署应用，通常都是像部署物理机那样使用脚本或手动部署，但由于本地环境和云环境不一致，往往会出现各种小问题。

这时候有个叫Paas的项目，就是专注于解决本地环境与云端环境不一致的问题，并且提供了**应用托管**的功能。简单得说，就是在云服务器上部署Paas对应的服务端，然后本机就能一键push，将本地应用部署到云端机器。然后由于云服务器上，一个Paas服务端，会接收多个用户提交的应用，所以其底层提供了一套隔离机制，为每个提交的应用创建一个**沙盒**，每个沙盒之间彼此隔离，互不干涉。

看看，这个沙盒是不是和docker很类似呢？**实际上，容器技术并不是docker的专属，docker只是众多实现容器技术中的一个而已**。



## 2.2 docker实现原理

说起docker，很多人都会将它与虚拟机进行比较，

![image-20210202111548325](http://lovebetterworld.com/image-20210202111548325.png)

其中左边是虚拟机的结构，右边是docker容器的结构。

在虚拟机中，通过Hypervisor对硬件资源进行虚拟化，在这部分硬件资源上安装操作系统，从而可以让上层的虚拟机和底层的宿主机相互隔离。



但docker是没有这种功能的，我们在docker容器中看到的与宿主机相互隔离的**沙盒**环境（文件系统，资源，进程环境等），**本质上是通过Linux的Namespace机制，CGroups（Control Groups）和Chroot等功能实现的。实际上Docker依旧是运行在宿主机上的一个进程（进程组）**，只是通过一些障眼法让docker以为自己是一个独立环境。

所以，容器=Cgroup+Namespace+rootfs+容器引擎（用户态工具）

- Cgroup：资源控制。
- Namespace：访问隔离。
- rootfs：文件系统隔离。
- 容器引擎：生命周期控制。



## 2.3 Cgroup

Cgroup是control group的简写，属于Linux内核提供的一个特性，用于限制和隔离一组进程对系统资源的使用，也就是做资源QoS，这些资源主要包括CPU、内存、block I/O和网络带宽。

- devices：设备权限控制。
- cpuset：分配指定的CPU和内存节点。
- cpu：控制CPU占用率。
- cpuacct：统计CPU使用情况。
- memory：限制内存的使用上限。
- freezer：冻结（暂停）Cgroup中的进程。
- net_cls：配合tc（traffic controller）限制网络带宽。
- net_prio：设置进程的网络流量优先级。
- huge_tlb：限制HugeTLB的使用。
- perf_event：允许Perf工具基于Cgroup分组做性能监测。



## 2.4 NameSpace

Namespace又称为命名空间（也称为名字空间），它是将内核的全局资源做封装，使得每个Namespace都有一份独立的资源，因此不同的进程在各自的Namespace内对同一种资源的使用不会互相干扰。

- IPC：隔离System V IPC和POSIX消息队列。
- Network：隔离网络资源。
- Mount：隔离文件系统挂载点。
- PID：隔离进程ID。
- UTS：隔离主机名和域名。
- User：隔离用户ID和组ID。



## 2.5 彻底了解docker隔离机制

如果在一个docker容器里面，使用ps命令查看进程，可能只会看到如下的输出：

```bash
/ # ps
PID  USER   TIME COMMAND
  1 root   0:00 /bin/bash
  10 root  0:00 ps
```

在容器中执行ps，只会看到1号进程/bin/bash和10号进程ps。前面有说到，docker容器本身只是Linux中的一个进程（组），也就是说在宿主机上，这个/bin/bash的pid可能是100或1000，那为什么在docker里面看到的这个/bin/bash进程的pid是1呢？**答案是linux提供的Namespace机制，将/bin/bash这个进程的进程空间隔离开了**。



具体的做法呢，就是在创建进程的时候添加一个可选的参数，比如下面这样：

```
int pid = clone(main_function, stack_size, CLONE_NEWPID | SIGCHLD, NULL); 
```

那样后，创建的线程就会有一个新的命名空间，在这个命名空间中，它的pid就是1，当然在宿主机的真实环境中，它的pid还是原来的值。



上面的这个例子，其实只是pid Namespace（进程命名空间），除此之外，还有network Namespace（网络命名空间），mount Namespace（文件命名空间，就是将整个容器的根目录root挂载到一个新的目录中，然后在其中放入内核文件看起来就像一个新的系统了）等，用以将整个容器和实际宿主机隔离开来。而这其实也就是容器基础的基础实现了。



但是，上述各种Namespace其实还不够，还有一个比较大的问题，**那就是系统资源的隔离**，比如要控制一个容器的CPU资源使用率，内存占用等，否则一个容器就吃尽系统资源，其他容器怎么办。

**而Linux实现资源隔离的方法就是Cgroups**。Cgroups主要是提供文件接口，即通过修改 /sys/fs/cgroup/下面的文件信息，比如给出pid，CPU使用时间限制等就能限制一个容器所使用的资源。

**所以，docker本身只是linux中的一个进程，通过Namespace和cgroup将它隔离成一个个单独的沙盒**。明白这点，就会明白docker的一些特性，比如说太过依赖内核的程序在docker上可能执行会出问题，比如无法在低版本的宿主机上安装高本版的docker等，因为本质上还是执行在宿主机的内核上。



# 三、Docker的核心：镜像、容器、仓库

## 3.1 镜像

镜像是一个可执行包，包含运行应用程序所需的所有内容——代码、运行时、库、环境变量和配置文件。



## 3.2 容器

**容器：**

- 容器是通过运行镜像启动容器，是镜像的运行时实例。镜像实际上就是一个容器的模板，通过这个模板可以创建很多相同的容器。
  - 容器就是一个认为只有其本身在运行状态的linux程序，只服从用户指定的命令。（容器程序有自己的IP地址；一个可访问网络的独立设备）



通过Java去类比理解Docker的一些概念：
![](https://img-blog.csdnimg.cn/20200128042708714.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L0V2YW5fTGV1bmc=,size_16,color_FFFFFF,t_70)

- Class文件 - 相当于Docker镜像，定义了类的一些所需要的信息
- 对象 - 相当于容器，通过Class文件创建出来的实例
- JVM - 相当于Docker引擎，可以让Docker容器屏蔽底层复杂逻辑，实现跨平台操作



## 3.3 仓库

存放镜像的地方，和git仓库类似。





# 四、Docker的安装方式

## 4.1 方式一：yum方式安装

```bash
# 更新yum源
yum update
# 安装所需环境
yum install -y yum-utils device-mapper-persistent-data lvm2
# 配置yum仓库
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
# 安装Docker
yum install docker-ce
# 启动Docker
systemctl start docker
systemctl enable docker
```



## 4.2 方式二：curl

```bash
curl -sSL https://get.daocloud.io/docker | sh
```



## 4.3 离线安装

1. 下载docker的安装文件：https://download.docker.com/linux/static/stable/x86_64/

![image-20210201092144600](http://lovebetterworld.com/image-20210201092144600.png)

2. 将下载后的tgz文件传至服务器，通过FTP工具上传即可
3. 解压`tar -zxvf docker-19.03.8-ce.tgz`
4. 将解压出来的docker文件复制到 /usr/bin/ 目录下：`cp docker/* /usr/bin/`
5. 进入**/etc/systemd/system/**目录,并创建**docker.service**文件

```bash
[root@localhost java]# cd /etc/systemd/system/
[root@localhost system]# touch docker.service
```

6. 打开**docker.service**文件,将以下内容复制

```bash
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target firewalld.service
Wants=network-online.target

[Service]
Type=notify
# the default is not to use systemd for cgroups because the delegate issues still
# exists and systemd currently does not support the cgroup feature set required
# for containers run by docker
ExecStart=/usr/bin/dockerd --selinux-enabled=false --insecure-registry=192.168.200.128
ExecReload=/bin/kill -s HUP $MAINPID
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
# Uncomment TasksMax if your systemd version supports it.
# Only systemd 226 and above support this version.
#TasksMax=infinity
TimeoutStartSec=0
# set delegate yes so that systemd does not reset the cgroups of docker containers
Delegate=yes
# kill only the docker process, not all processes in the cgroup
KillMode=process
# restart the docker process if it exits prematurely
Restart=on-failure
StartLimitBurst=3
StartLimitInterval=60s

[Install]
WantedBy=multi-user.target
```

7. 给docker.service文件添加执行权限：`chmod 777 /etc/systemd/system/docker.service `

8. 重新加载配置文件：`systemctl daemon-reload `

9. 启动Docker `systemctl start docker`

10. 设置开机启动：`systemctl enable docker.service`

11. 查看Docker状态：`systemctl status docker`

    ![image-20210201092621496](http://lovebetterworld.com/image-20210201092621496.png)

如出现如图界面，则表示安装成功！

# 五、Docker思维导图总结

思维导图下载链接：
[Docker思维导图下载](https://gitee.com/AiShiYuShiJiePingXing/lovebetterworld/tree/master/Docker)

![在这里插入图片描述](https://img-blog.csdnimg.cn/20201218164558449.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L0FuMTA5MDIzOTc4Mg==,size_16,color_FFFFFF,t_70#pic_center)

