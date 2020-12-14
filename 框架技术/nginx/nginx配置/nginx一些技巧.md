# 前言

相关参数

- worker_processes
- worker_cpu_affinity
- multi_accept
- worker_rlimit_nofile
- worker_connections
- backlog

# worker_processes

让nginx开启多核CPU的配置，可以将进程绑定到一组CPU上，依据服务器CPU核数设置。(不是CPU数量哦)

```java
 user  nginx;
 worker_processes 8;  # 服务器8核 可以设置8核，依据核心数量设置，注意不是CPU数量
```

# worker_cpu_affinity

可以配合worker_processes 使用，将进程绑定到指定的CPU核心，CPU核心的指定可以通过CPU的位掩码来表示。

```java
 如果是四核的服务器，那么第一个CPU核心就是 0001 第二个CPU核心为 0010，依次类推
```

服务器会出现个别CPU很闲，压力很小，这个时候我们就可以将nginx绑定到闲置的CPU身上

通过使用Top命令，按1键查看每个CPU内核的使用情况
示例：

```java
top - 11:17:46 up 20 days, 20:54,  5 users,  load average: 0.28, 0.22, 0.32
Tasks: 354 total,   2 running, 352 sleeping,   0 stopped,   0 zombie
%Cpu0  :  5.0 us,  1.3 sy,  0.0 ni, 93.7 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
%Cpu1  :  3.7 us,  0.7 sy,  0.0 ni, 95.7 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
%Cpu2  :  2.7 us,  1.7 sy,  0.0 ni, 95.7 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
%Cpu3  :  0.7 us,  0.7 sy,  0.0 ni, 98.7 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
%Cpu4  :  1.0 us,  1.0 sy,  0.0 ni, 98.0 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
%Cpu5  :  1.0 us,  1.0 sy,  0.0 ni, 98.0 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
%Cpu6  :  1.0 us,  1.3 sy,  0.0 ni, 97.7 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
%Cpu7  :  1.7 us,  1.7 sy,  0.0 ni, 96.3 id,  0.0 wa,  0.0 hi,  0.3 si,  0.0 st
%Cpu8  :  1.3 us,  0.7 sy,  0.0 ni, 98.0 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
%Cpu9  :  4.0 us,  1.0 sy,  0.0 ni, 95.0 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
%Cpu10 :  0.7 us,  0.7 sy,  0.0 ni, 98.7 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
%Cpu11 :  0.3 us,  0.3 sy,  0.0 ni, 99.3 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
%Cpu12 :  0.7 us,  0.7 sy,  0.0 ni, 98.3 id,  0.0 wa,  0.0 hi,  0.0 si,  0.3 st
%Cpu13 :  0.7 us,  0.7 sy,  0.0 ni, 98.3 id,  0.0 wa,  0.0 hi,  0.0 si,  0.3 st
%Cpu14 :  0.7 us,  0.3 sy,  0.0 ni, 99.0 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
%Cpu15 :  0.7 us,  0.7 sy,  0.0 ni, 98.7 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
KiB Mem : 16264568 total,   800660 free,  8007112 used,  7456796 buff/cache
KiB Swap:        0 total,        0 free,        0 used.  7169460 avail Mem 

  PID USER      PR  NI    VIRT    RES    SHR S  %CPU %MEM     TIME+ COMMAND                                           
15159 root      20   0 2285980 111220  29940 S   3.7  0.7   1310:31 kubelet                                           
21002 polkitd   20   0 9625676  87996   5200 S   2.7  0.5  73:08.99 beam.smp                                          
 4357 root      20   0 2034248 105228  17996 S   2.3  0.6   1966:23 dockerd                                           
25879 root      20   0 2740444  43716  17000 S   1.3  0.3 680:10.67 calico-node  
1234567891011121314151617181920212223242526
```

我们可以这样设置

```java
user  nginx;
worker_processes 2; # 使用两核CPU
worker_cpu_affinity 0000000000000100 0000001000000000; #绑定到第三个和第十个CPU核心
```

也可以这样设置

```java
worker_processes auto; # 允许将工作进程自动绑定到可用CPU核心
worker_cpu_affinity auto; 
```

还能这样玩

```java
worker_processes auto; # 允许将工作进程自动绑定到可用CPU核心
worker_cpu_affinity auto 001  100;  # 限制可以自动绑定的CPU核心
```

# multi_accept

默认关闭， 关闭状态下一个工作进程只能接收一个新连接。该参数配置在nginx的**events**模块中，
此外还有个参数需要注意 **accept_mutex** 默认为off，该参数为off状态时，在某一时刻，如果只有一个请求，也会导致多个睡眠的进程被唤醒。

一般这样设置

```java
events {
    accept_mutex on; # 当只有单个请求时，不会导致多个进程被唤醒
    multi_accept on; # 允许接受多个新网络连接请求
    use epoll;
}
```

如果nginx使用kqueue连接方法，那么这条指令会被忽略，因为这个方法会报告在等待被接受的新连接的数量

# worker_rlimit_nofile

如果不修改改配置和系统默认limit参数 则可能会遇到**open too many files**错误

```java
查看系统默认最大文件描述符
ulimit -n

[root@192 ~]# ulimit -n 
1024
默认为1024

参数和worker_processes与worker_connections 也有一点关系

系统的最大文件描述符>= worker_connections*worker_process
```

尝试修改系统最大文件描述符

```java
第一个方式
编辑文件   vi /etc/security/limits.conf
加入以下内容
*  soft    nofile  65536
*  hard    nofile  65536

修改配置文件，需要重启才能生效

这样我们可以在环境变量中在配置一次，让他立即生效

编辑文件 vi  /etc/profile 
新增 ulimit -n 65535
```

示例

```java
# Functions and aliases go in /etc/bashrc

# It's NOT a good idea to change this file unless you know what you
# are doing. It's much better to create a custom.sh shell script in
# /etc/profile.d/ to make custom changes to your environment, as this
# will prevent the need for merging in future updates.
ulimit -n 65535
pathmunge () {
    case ":${PATH}:" in
        *:"$1":*)
            ;;
        *)
            if [ "$2" = "after" ] ; then
                PATH=$PATH:$1
            else
                PATH=$1:$PATH
            fi
    esac
}

新增完成后刷新环境变量

. /etc/profile 或者 source /etc/profile

再次查看
[root@192 ~]# ulimit -n      
65535
[root@192 ~]# 
```

nginx配置

```java
worker_rlimit_nofile 35535;  #根据环境适当修改
```

# worker_connections

单个进程允许的最大客户端连接数，位于**events**模块中

nginx能处理的最大并发数量
该值不能超过 worker_rlimit_nofile 否者会出现worker_connections exceed open file resource limit: xxx

网上相关信息一般是以 worker_rlimit_nofile >= worker_connections*worker_process 来配置该参数，具体可依照环境信息调控

示例

```java
events {
    worker_connections  2048;
    accept_mutex on; 
    multi_accept on;
}
```

# backlog

该参数配置在listen 后面，为底层listen函数的一个参数，默认值为511
详细内容参照官方文档，也可以看看这篇文章http://www.04007.cn/article/323.html

我们了解两个linux内核参数
**net.core.somaxconn**
**net.ipv4.tcp_max_syn_backlog**

```java
这两个参数默认值为128
 tcp_max_syn_backlog是指定所能接受SYN同步包的最大客户端数量，半连接上限，为SYN_REVD状态的连接数。
 somaxconn是Linux中的一个kernel参数，指的是服务端所能accept即处理数据的最大客户端数量，即完成连接上限。
 好像 tcp_max_syn_backlog>=somaxconn
 tcp_max_syn_backlog 就是我能接收多少请求
 somaxconn 我能完成多少请求
 理论上貌似是这样的，但是这两个属性的配置没有直接关系。
 请以你的系统环境情况来分配 somaxconn 和 tcp_max_syn_backlog。
 不要被忽悠了，详细内容见官方文档。

 net.core.somaxconn 影响到了nginx缓存队列的最大的连接数量。
 net.core.netdev_max_backlog 被切换到CPU处理前被网卡缓存的速率包,根据网卡文档加大值可以提高性能

对于高负载的服务器来说，128肯定是不够用的。
具体设置为多少可以根据自己系统业务情况来定夺。
```

修改默认值

```java
编辑文件
 vi /etc/sysctl.conf 
 加入以下内容
 示例
 
 [root@192 ~]# vi /etc/sysctl.conf 
# sysctl settings are defined through files in
# /usr/lib/sysctl.d/, /run/sysctl.d/, and /etc/sysctl.d/.
#
# Vendors settings live in /usr/lib/sysctl.d/.
# To override a whole file, create a new file with the same in
# /etc/sysctl.d/ and put new settings there. To override
# only specific settings, add a file with a lexically later
# name in /etc/sysctl.d/ and put new settings there.
#
# For more information, see sysctl.conf(5) and sysctl.d(5).

net.ipv4.tcp_max_syn_backlog=8096
net.core.somaxconn=32768

让配置生效
[root@192 ~]# sysctl  -p
net.ipv4.tcp_max_syn_backlog = 8096
net.core.somaxconn = 32768
[root@192 ~]# 
```

nginx 默认的backlog参数为511，他影响nginx握手成功的队列大小，和系统的somaxconn 对应上了。

修改nginx默认backlog大小
示例

```java
server {
     listen 8080 default backlog=1024;   #多域名情况 单个端口 只能配置一个
     client_max_body_size 2048M;
     proxy_cache_lock on;
     ····
     }
```

你想抗住一定量的流量，首先系统要能支持，在想着nginx优化。

# 总结

给甲方做一个H5系统的时候，前端是vue直接扔Nginx里面的，那边直接说Nginx能抗住五万，你们需要能抗2-3w，我抗尼玛，就给了四台服务器，虽然配置也还不错。
Nginx默认的参数设置是扛不住太高的流量的，除此之外还要先从系统层面入手优化，首先确定你的服务器能顶住预估的流量，在来优化你的应用，中间件。另外脱离业务场景谈优化啥的，我也感觉扯淡。
你没有遇到那些问题，就想着提前给优化掉，那你很牛逼啊，我反正就是划水，划水，划水。
另外附上一些系统参数调配 **仅供参考**

```java
修改/etc/sysctl.conf

net.bridge.bridge-nf-call-ip6tables=1
net.bridge.bridge-nf-call-iptables=1
net.ipv4.ip_forward=1
net.ipv4.conf.all.forwarding=1
net.ipv4.neigh.default.gc_thresh1=4096
net.ipv4.neigh.default.gc_thresh2=6144
net.ipv4.neigh.default.gc_thresh3=8192
net.ipv4.neigh.default.gc_interval=60
net.ipv4.neigh.default.gc_stale_time=120

kernel.perf_event_paranoid=-1

#sysctls for k8s node config
net.ipv4.tcp_slow_start_after_idle=0
net.core.rmem_max=16777216
fs.inotify.max_user_watches=524288
kernel.softlockup_all_cpu_backtrace=1

kernel.softlockup_panic=0

kernel.watchdog_thresh=30
fs.file-max=2097152
fs.inotify.max_user_instances=8192
fs.inotify.max_queued_events=16384
vm.max_map_count=262144
fs.may_detach_mounts=1
net.core.netdev_max_backlog=16384
net.ipv4.tcp_wmem=4096 12582912 16777216
net.core.wmem_max=16777216
net.core.somaxconn=32768
net.ipv4.ip_forward=1
net.ipv4.tcp_max_syn_backlog=8096
net.ipv4.tcp_rmem=4096 12582912 16777216

net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.lo.disable_ipv6=1

kernel.yama.ptrace_scope=0
vm.swappiness=0

# 可以控制core文件的文件名中是否添加pid作为扩展。
kernel.core_uses_pid=1

# Do not accept source routing
net.ipv4.conf.default.accept_source_route=0
net.ipv4.conf.all.accept_source_route=0

# Promote secondary addresses when the primary address is removed
net.ipv4.conf.default.promote_secondaries=1
net.ipv4.conf.all.promote_secondaries=1

# Enable hard and soft link protection
fs.protected_hardlinks=1
fs.protected_symlinks=1

# 源路由验证
# see details in https://help.aliyun.com/knowledge_detail/39428.html
net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.default.rp_filter=0
net.ipv4.conf.default.arp_announce = 2
net.ipv4.conf.lo.arp_announce=2
net.ipv4.conf.all.arp_announce=2

# see details in https://help.aliyun.com/knowledge_detail/41334.html
net.ipv4.tcp_max_tw_buckets=5000
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_fin_timeout=30
net.ipv4.tcp_synack_retries=2
kernel.sysrq=1
```