[TOC]
# 查看CPU和内存
```shell
cpu:
$ cat /proc/cpuinfo | grep name
model name      : Intel(R) Xeon(R) Platinum 8163 CPU @ 2.50GHz
model name      : Intel(R) Xeon(R) Platinum 8163 CPU @ 2.50GHz
```
# 查看CPU进程
1：查找jvm进程ID: jps -lv 或者 ps aux | grep java
2：根据pid，查找占用cpu较高的线程：ps -mp pid -o THREAD,tid,time
2.1将tid转换为16进制的数字：printf “%x\n” tid
2.2jstack命令，查询线程信息，从而定位到具体线程和代码：jstack pid | grep 7ccd -A 30
内存：
```bash
$ cat /proc/meminfo | grep Mem
MemTotal:        8009180 kB
MemFree:         7633240 kB
MemAvailable:    7657060 kB
```
ps 命令在 Linux 中查找内存消耗最大的进程：
ps aux --sort -rss | head
ps 命令格式可在输出中仅展示有关内存消耗过程的特定信息。
ps -eo pid,ppid,%mem,%cpu,cmd --sort=-%mem | head
查看命令名称而不是命令的绝对路径，请使用下面的 ps 命令格式。
ps -eo pid,ppid,%mem,%cpu,comm --sort=-%mem | head
使用 top 命令在 Linux 中查找内存消耗最大的进程：
top -c -b -o +%MEM | head -n 20 | tail -15
查看命令名称而不是命令的绝对路径，请使用下面的 top 命令格式。
top -b -o +%MEM | head -n 20 | tail -15

# 查看磁盘和分区
## 磁盘:
$ fdisk -l | grep -E '.+/dev/'
磁盘 /dev/vda：42.9 GB, 42949672960 字节，83886080 个扇区
## 分区:
$ df -TH | grep ^/dev
/dev/vda1      ext4       43G  1.8G   39G    5% /

```shell
	[root@localhost ~]# df
	Filesystem      1K-blocks      Used Available Use% Mounted on
	/dev/hdc2         9920624   3823112   5585444  41% /
	/dev/hdc3         4956316    141376   4559108   4% /home
	/dev/hdc1          101086     11126     84741  12% /boot
	tmpfs              371332         0    371332   0% /dev/shm

	df 命令显示出的各列信息的含义分别是：
	Filesystem：表示该文件系统位于哪个分区，因此该列显示的是设备名称；
	1K-blocks：此列表示文件系统的总大小，默认以 KB 为单位；
	Used：表示用掉的硬盘空间大小；
	Available：表示剩余的硬盘空间大小；
	Use%：硬盘空间使用率。如果使用率高达 90% 以上，就需要额外注意，因为容量不足，会严重影响系统的正常运行；
	Mounted on：文件系统的挂载点，也就是硬盘挂载的目录位置。
```
# 查看网卡和IP地址
## 网卡:
```shell
$ lspci | grep -i eth
00:03.0 Ethernet controller: Red Hat, Inc. Virtio network device
```
## IP:
```shell
$ ip addr | grep -E "^[1-9]+|inet"
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
inet 127.0.0.1/8 scope host lo
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
inet 172.18.24.41/20 brd 172.18.31.255 scope global dynamic eth0
```
# 查看防火墙服务
```shell
$ systemctl list-unit-files | grep firewalld
firewalld.service                             enabled
```
# 启用防火墙服务(开机启动)：
```shell
systemctl enable firewalld.service
```
# 禁用防火墙服务：
```shell
systemctl disable firewalld.service
```
# 查看防火墙运行状态
```shell
$ firewall-cmd --state
running
```
# 打开防火墙:
```shell
systemctl start firewalld.service
```
# 关闭防火墙:
```shell
systemctl stop firewalld.service
```
# 查看系统用户和用户组信息
## 查看系统用户
```shell
$ cat /etc/passwd | grep bash
root:x:0:0:root:/root:/bin/bash
```
```
用户名 :密码 :用户ID  :分组ID :注释性描述   :用户目录    :登录Shell
# root  :x   :0       :0     :root       :/root      :/bin/bash
```
## 查看用户组
```shell
$ cat /etc/group | grep root
root:x:0:
```
```
# 组名  :密码  :分组ID  :组内用户列表
# root :x     :0      :
```
# 查看系统运行状态
## 查看当前运行的进程列表
```shell
ps aux
```
## 加 f 以树状显示父子进程

```shell
ps aufx
```
## 查看实时进程资源占用(CPU和内存)

```shell
top
```
## 系统运行状态监控(CPU和IO)
安装监控程序 dstat:
```shell
yum install dstat
```
## 实时监控系统运行：
```shell
dstat
```

