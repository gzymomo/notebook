CSDN：

- [kubernetes 1.16 二进制集群高可用安装实操踩坑篇](https://blog.csdn.net/sfdst/article/details/105813485)



# 1 系统设置

## 1.1 主机系统环境说明

```
[root@k8s-master01 ~]# cat /etc/redhat-release 
CentOS Linux release 7.7.1908 (Core)
[root@k8s-master01 ~]# uname -r
3.10.0-693.el7.x86_64
```

## 1.2 主机名设置

```
hostnamectl set-hostname k8s-master01
hostnamectl set-hostname k8s-master02
hostnamectl set-hostname k8s-master03
hostnamectl set-hostname k8s-node01
hostnamectl set-hostname k8s-node02
```

## 1.3 服务器角色规划

| 主机名       | ip地址        | 角色   | 服务                                                         |
| ------------ | ------------- | ------ | ------------------------------------------------------------ |
| k8s-master01 | 192.168.10.11 | master | etcd、kube-apiserver、kube-controller-manager、kube-scheduler |
| k8s-master02 | 192.168.10.12 | master | etcd、kube-apiserver、kube-controller-manager、kube-scheduler |
| k8s-master03 | 192.168.10.13 | master | etcd、kube-apiserver、kube-controller-manager、kube-scheduler |
| k8s-node01   | 192.168.10.14 | work   | kubelet、kube-proxy、docker、dns、                           |
| k8s-node02   | 192.168.10.15 | work   | kubelet、kube-proxy、docker、dns、                           |

|vip | 192.168.10.16| vipip |vip |

## 1.4 配置自己的yum源

```
yum install wget
mv /etc/yum.repos.d/Centos-7.repo  /etc/yum.repos.d/Centos-7.repo.bak
mv /etc/yum.repos.d/epel-7.repo  /etc/yum.repos.d/epel-7.repo.bak
curl -o /etc/yum.repos.d/Centos-7.repo http://mirrors.aliyun.com/repo/Centos-7.repo
curl -o /etc/yum.repos.d/epel-7.repo https://mirrors.aliyun.com/repo/epel-7.repo
yum update
123456
```

## 1.5 关闭SELinux

```
sed -i 's#SELINUX=enforcing#SELINUX=disabled#g' /etc/selinux/config
setenforce 0
12
```

## 1.6 关闭防火墙、swap

```
systemctl stop firewalld && systemctl disable firewalld
 swapoff -a
sed -i '/swap/s/^\(.*\)$/#\1/g' /etc/fstab

systemctl stop NetworkManager
systemctl disable NetworkManager
123456
```

## 1.7 关闭dnsmasq(否则可能导致docker容器无法解析域名)

```
service dnsmasq stop && systemctl disable dnsmasq
1
```

## 1.8 安装ansible

```
只在master01上安装
yum install -y epel-release
yum install ansible -y

定义主机组
[k8s-master] #master节点服务器组
192.168.10.11
192.168.10.12
192.168.10.13
 
[k8s-node]  #node节点服务器组
192.168.10.14
192.168.10.15
 
[k8s-all:children]  #k8s集群服务器组
k8s-master
k8s-node

[k8s-all:vars]
ansible_ssh_user=root
ansible_ssh_pass="123456"


测试
ansible k8s-all -m ping

1234567891011121314151617181920212223242526
```

## 1.9 安装常用软件包

```
ansible k8s-all -m shell -a "yum install -y   vim openssh-clients ntpdate man lrzsz net-tools"
1
```

## 1.10 配置host主机域名解析

```
 cat /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
192.168.10.11 k8s-master01
192.168.10.12 k8s-master02
192.168.10.13 k8s-master03
192.168.10.14 k8s-node01
192.168.10.15 k8s-node02

分发hosts
ansible k8s-all -m copy -a "src=/etc/hosts dest=/etc/hosts"
1234567891011
```

## 1.11 时间同步

```
ansible k8s-all -m yum -a "name=ntpdate state=latest" 
ansible k8s-all -m cron -a "name='k8s cluster crontab' minute=*/30 hour=* day=* month=* weekday=* job='ntpdate time7.aliyun.com >/dev/null 2>&1'"
 ansible k8s-all -m shell -a "ntpdate time7.aliyun.com"
 
1234
```

## 1.12 系统参数设置

```
cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
vm.swappiness=0
vm.overcommit_memory=1
vm.panic_on_oom=0
fs.inotify.max_user_watches=89100
EOF
分发到其他服务器上
ansible k8s-all -m copy -a "src=/etc/sysctl.d/k8s.conf dest=/etc/sysctl.d/"
ansible k8s-all -m shell -a 'modprobe br_netfilter'
ansible k8s-all -m shell -a 'sysctl -p /etc/sysctl.d/k8s.conf'
12345678910111213
```

## 1.13 创建集群目录

```
所有节点创建：
ansible k8s-all -m file -a 'path=/etc/kubernetes/ssl state=directory'
ansible k8s-all -m file -a 'path=/etc/kubernetes/config state=directory'
本机创建
mkdir /opt/k8s/{certs,cfg,unit} -p
12345
```

## 1.14 安装docker(worker节点)

```
 ansible k8s-all -m shell -a 'yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo'
 ansible k8s-all -m shell -a 'yum install docker-ce -y'
 ansible k8s-all -m shell -a 'systemctl start docker && systemctl enable docker'

1234
```

# 2 创建 CA 证书和秘钥

## 2.1 安装及配置CFSSL

> 生成证书时可在任一节点完成，这里在k8s-node03主机执行，证书只需要创建一次即可，以后在向集群中添加新节点时只要将 /etc/kubernetes/ssl 目录下的证书拷贝到新节点上即可。

```
mkdir k8s/cfssl -p && cd k8s/cfssl/
wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
chmod +x cfssl_linux-amd64
cp cfssl_linux-amd64 /usr/local/bin/cfssl
wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
chmod +x cfssljson_linux-amd64
cp cfssljson_linux-amd64 /usr/local/bin/cfssljson
wget https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64
chmod +x cfssl-certinfo_linux-amd64
cp cfssl-certinfo_linux-amd64 /usr/local/bin/cfssl-certinfo
12345678910
```

## 2.2 创建根证书(CA)

> CA 证书是集群所有节点共享的,只需要创建一个 CA 证书,后续创建的所有证书都由
> 它签名。

```
cd  /opt/k8s/certs/
cat > ca-config.json <<EOF
{
    "signing": {
      "default": {
        "expiry": "87600h"
    },
    "profiles": {
      "kubernetes": {
        "usages": [
            "signing",
            "key encipherment",
            "server auth",
            "client auth"
        ],
        "expiry": "87600h"
      }
    }
  }
}
EOF
123456789101112131415161718192021
```

> 注释：
> 1.signing:表示该证书可用于签名其它证书,生成的ca.pem证书中
> CA=TRUE
> 2.server auth：表示client可以用该证书对server提供的证书进行验证；
> 3.表示server可以用该该证书对client提供的证书进行验证;

## 2.3 创建证书签名请求文件

```
cat > ca-csr.json <<EOF

{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "ShangHai",
      "L": "ShangHai",
      "O": "k8s",
      "OU": "System"
    }
  ]
} 
EOF
12345678910111213141516171819
```

## 2.4 生成CA证书、私钥和csr证书签名请

```
创建
cfssl gencert -initca ca-csr.json | cfssljson -bare ca

查看
[root@k8s-master01 certs]# ls
ca-config.json  ca.csr  ca-csr.json  ca-key.pem  ca.pem
[root@k8s-master01 certs]# 


123456789
```

## 2.5 分发证书文件

```
将生成的 CA 证书、秘钥文件、配置文件拷贝到所有节点的 /etc/kubernetes/cert
目录下
ansible k8s-all -m copy -a 'src=ca.csr dest=/etc/kubernetes/ssl/'
ansible k8s-all -m copy -a 'src=ca-key.pem dest=/etc/kubernetes/ssl/'
ansible k8s-all -m copy -a 'src=ca.pem dest=/etc/kubernetes/ssl/'
查看分发情况：
[root@k8s-master01 certs]# ansible k8s-all -m shell -a 'ls /etc/kubernetes/ssl'

192.168.10.11 | CHANGED | rc=0 >>
ca.csr
ca-key.pem
ca.pem

192.168.10.13 | CHANGED | rc=0 >>
ca.csr
ca-key.pem
ca.pem

192.168.10.15 | CHANGED | rc=0 >>
ca.csr
ca-key.pem
ca.pem

192.168.10.14 | CHANGED | rc=0 >>
ca.csr
ca-key.pem
ca.pem

192.168.10.12 | CHANGED | rc=0 >>
ca.csr
ca-key.pem
ca.pem

123456789101112131415161718192021222324252627282930313233
```

# 3 部署etcd集群

> etcd 是k8s集群最重要的组件，用来存储k8s的所有服务信息， etcd 挂了，集群就挂了，我们这里把etcd部署在master三台节点上做高可用，etcd集群采用raft算法选举Leader， 由于Raft算法在做决策时需要多数节点的投票，所以etcd一般部署集群推荐奇数个节点，推荐的数量为3、5或者7个节点构成一个集群。
> 注意：etcd3.4.3不兼容flannel版本：v0.11.0.所以后面创建flannel网络的时候出现了问题，后面参考了https://devopstack.cn/k8s/359.html重搭了etcd3.3.12,后面再研究etcd3.4.3

## 3.1 下载etcd二进制文件

```
cd k8s
wget https://github.com/etcd-io/etcd/releases/download/v3.4.3/etcd-v3.4.3-linux-amd64.tar.gz
[root@k8s-master01 k8s]# tar -xf etcd-v3.4.3-linux-amd64.tar.gz 
[root@k8s-master01 k8s]# cd etcd-v3.4.3-linux-amd64
[root@k8s-master01 etcd-v3.4.3-linux-amd64]# ansible k8s-master -m copy -a 'src=/root/k8s/etcd-v3.4.3-linux-amd64/etcd dest=/usr/local/bin/ mode=0755'
ansible k8s-master -m copy -a 'src=/root/k8s/etcd-v3.4.3-linux-amd64/etcdctl dest=/usr/local/bin/ mode=0755'
123456
```

## 3.2 创建etcd证书请求模板文件

```
cat > /opt/k8s/certs/etcd-csr.json <<EOF
{
  "CN": "etcd",
  "hosts": [
    "127.0.0.1",
    "192.168.10.11",
    "192.168.10.12",
    "192.168.10.13",
	"192.168.10.16",
    "k8s-master01",
    "k8s-master02",
    "k8s-master03"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "ShangHai",
      "L": "ShangHai",
      "O": "k8s",
      "OU": "System"
    }
  ]
}
EOF

1234567891011121314151617181920212223242526272829
```

> 说明：hosts中的IP为各etcd节点IP及本地127地址，在生产环境中hosts列表最好多预留几个IP，这样后续扩展节点或者因故障需要迁移时不需要再重新生成证.

## 3.3 生成证书及私钥

```
[root@k8s-master01 etcd-v3.4.3-linux-amd64]# cd /opt/k8s/certs/
[root@k8s-master01 certs]# cfssl gencert -ca=/opt/k8s/certs/ca.pem      -ca-key=/opt/k8s/certs/ca-key.pem      -config=/opt/k8s/certs/ca-config.json      -profile=kubernetes etcd-csr.json | cfssljson -bare etcd
2019/12/25 18:25:07 [INFO] generate received request
2019/12/25 18:25:07 [INFO] received CSR
2019/12/25 18:25:07 [INFO] generating key: rsa-2048
2019/12/25 18:25:07 [INFO] encoded CSR
2019/12/25 18:25:07 [INFO] signed certificate with serial number 12215464798631919849402827311116750913097688886
2019/12/25 18:25:07 [WARNING] This certificate lacks a "hosts" field. This makes it unsuitable for
websites. For more information see the Baseline Requirements for the Issuance and Management
of Publicly-Trusted Certificates, v.1.1.6, from the CA/Browser Forum (https://cabforum.org);
specifically, section 10.2.3 ("Information Requirements").
查看生成结果
[root@k8s-master01 certs]# ll etcd*
-rw-r--r--. 1 root root 1066 12月 25 18:25 etcd.csr
-rw-r--r--. 1 root root  301 12月 25 18:23 etcd-csr.json
-rw-------. 1 root root 1675 12月 25 18:25 etcd-key.pem
-rw-r--r--. 1 root root 1440 12月 25 18:25 etcd.pem

123456789101112131415161718
```

## 3.4 etcd证书分发

> 把生成的etcd证书复制到创建的证书目录并放至另2台etcd节点

```
ansible k8s-master -m copy -a 'src=/opt/k8s/certs/etcd.pem dest=/etc/kubernetes/ssl/'
ansible k8s-master -m copy -a 'src=/opt/k8s/certs/etcd-key.pem dest=/etc/kubernetes/ssl/'


1234
```

## 3.5 修改etcd配置参数

```
ansible k8s-master -m group -a 'name=etcd'
ansible k8s-master -m user -a 'name=etcd group=etcd comment="etcd user" shell=/sbin/nologin home=/var/lib/etcd createhome=no'
12
```

### 3.5.1 创建etcd用户和组

```
ansible k8s-master -m group -a 'name=etcd'
ansible k8s-master -m user -a 'name=etcd group=etcd comment="etcd user" shell=/sbin/nologin home=/var/lib/etcd createhome=no'
12
```

### 3.5.2 创建etcd数据存放目录并授权

```
ansible k8s-master -m file -a 'path=/var/lib/etcd state=directory owner=etcd group=etcd'
1
```

## 3.6 配置etcd启动文件

```
cat <<EOF>/etc/systemd/system/etcd.service
[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target
Documentation=https://github.com/coreos

[Service]
Type=notify
WorkingDirectory=/var/lib/etcd/
ExecStart=/usr/local/bin/etcd \
  --data-dir=/var/lib/etcd \
  --name=k8s-master01 \
  --cert-file=/etc/kubernetes/ssl/etcd.pem \
  --key-file=/etc/kubernetes/ssl/etcd-key.pem \
  --trusted-ca-file=/etc/kubernetes/ssl/ca.pem \
  --peer-cert-file=/etc/kubernetes/ssl/etcd.pem \
  --peer-key-file=/etc/kubernetes/ssl/etcd-key.pem \
  --peer-trusted-ca-file=/etc/kubernetes/ssl/ca.pem \
  --peer-client-cert-auth \
  --client-cert-auth \
  --listen-peer-urls=https://192.168.10.11:2380 \
  --initial-advertise-peer-urls=https://192.168.10.11:2380 \
  --listen-client-urls=https://192.168.10.11:2379,http://127.0.0.1:2379 \
  --advertise-client-urls=https://192.168.10.11:2379 \
  --initial-cluster-token=etcd-cluster-0 \
  --initial-cluster=k8s-master01=https://192.168.10.11:2380,k8s-master02=https://192.168.10.12:2380,k8s-master03=https://192.168.10.13:2380 \
  --initial-cluster-state=new \
  --auto-compaction-mode=periodic \
  --auto-compaction-retention=1 \
  --max-request-bytes=33554432 \
  --quota-backend-bytes=6442450944 \
  --heartbeat-interval=250 \
  --election-timeout=2000
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target

copy到etcd集群的每一台：
 ansible k8s-master -m copy -a 'src=etcd.service dest=/etc/systemd/system/etcd.service'
ansible k8s-master -m shell -a 'systemctl daemon-reload'
ansible k8s-master -m shell -a 'systemctl enable etcd'
ansible k8s-master  -m shell -a 'systemctl start etcd'
1234567891011121314151617181920212223242526272829303132333435363738394041424344454647
```

> etcd 3.4注意事项
> ETCD3.4版本ETCDCTL_API=3 etcdctl 和 etcd --enable-v2=false 成为了默认配置，如要使用v2版本，执行etcdctl时候需要设置ETCDCTL_API环境变量，例如：ETCDCTL_API=2 etcdctl
> **ETCD3.4版本会自动读取环境变量的参数**，所以EnvironmentFile文件中有的参数，不需要再次在ExecStart启动参数中添加，二选一，如同时配置，会触发以下类似报错“etcd: conflicting environment variable “ETCD_NAME” is shadowed by corresponding command-line flag (either unset environment variable or disable flag)”
> flannel操作etcd使用的是v2的API，而kubernetes操作etcd使用的v3的API

## 3.7 验证etcd集群状态

```
[root@k8s-master01 k8s]# etcdctl --cacert=/etc/kubernetes/ssl/ca.pem --cert=/etc/kubernetes/ssl/etcd.pem --key=/etc/kubernetes/ssl/etcd-key.pem --endpoints="https://192.168.10.11:2379,https://192.168.10.12:2379,https://192.168.10.13:2379" endpoint status
https://192.168.10.11:2379, 7508c5fadccb39e2, 3.4.3, 20 kB, true, false, 4, 14, 14, 
https://192.168.10.12:2379, 1af68d968c7e3f22, 3.4.3, 20 kB, false, false, 4, 14, 14, 
https://192.168.10.13:2379, e8d9a97b17f26476, 3.4.3, 20 kB, false, false, 4, 14, 14, 

查看集群健康状态
[root@k8s-master01 k8s]# etcdctl --cacert=/etc/kubernetes/ssl/ca.pem --cert=/etc/kubernetes/ssl/etcd.pem --key=/etc/kubernetes/ssl/etcd-key.pem --endpoints="https://192.168.10.11:2379,https://192.168.10.12:2379,https://192.168.10.13:2379" endpoint  health
https://192.168.10.12:2379 is healthy: successfully committed proposal: took = 24.910116ms
https://192.168.10.11:2379 is healthy: successfully committed proposal: took = 27.478493ms
https://192.168.10.13:2379 is healthy: successfully committed proposal: took = 29.586593ms

etcd3.4.3部署成功
123456789101112
```

# 4 master节点部署组件

## 4.1 kubectl命令行工具部署

> kubectl 是 kubernetes 集群的命令行管理工具，它默认从 ~/.kube/config 文件读取 kube-apiserver 地址、证书、用户名等信息。

### 4.1.1 下载kubernetes二进制安装包

```
wget https://storage.googleapis.com/kubernetes-release/release/v1.16.2/kubernetes-server-linux-amd64.tar.gz
tar -xf kubernetes-server-linux-amd64.tar.gz
12
```

### 4.1.2 分发二进制文件到对应的服务器

```
把对应组件二进制文件copy到指定节点
master节点组件：kube-apiserver、etcd、kube-controller-manager、kube-scheduler、kubectl
node节点组件：kubelet、kube-proxy、docker、coredns、calico
master二进制命令文件传输
scp kubernetes/server/bin/{kube-apiserver,kube-controller-manager,kube-scheduler,kubectl,kubeadm} 192.168.10.11:/usr/local/bin/
scp kubernetes/server/bin/{kube-apiserver,kube-controller-manager,kube-scheduler,kubectl,kubeadm} 192.168.10.12:/usr/local/bin/
scp kubernetes/server/bin/{kube-apiserver,kube-controller-manager,kube-scheduler,kubectl,kubeadm} 192.168.10.13:/usr/local/bin/
node节点二进制文件传输
scp kubernetes/server/bin/{kube-proxy,kubelet} 192.168.10.14:/usr/local/bin/
scp kubernetes/server/bin/{kube-proxy,kubelet} 192.168.10.15:/usr/local/bin/
12345678910
```

### 4.1.3 创建请求证书

```
cat > /opt/k8s/certs/admin-csr.json <<EOF
{
  "CN": "admin",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "ShangHai",
      "L": "ShangHai",
      "O": "system:masters",
      "OU": "System"
    }
  ]
}
EOF
12345678910111213141516171819
```

### 4.1.4 生成证书和私钥

```
cfssl gencert -ca=/opt/k8s/certs/ca.pem \
     -ca-key=/opt/k8s/certs/ca-key.pem \
     -config=/opt/k8s/certs/ca-config.json \
     -profile=kubernetes admin-csr.json | cfssljson -bare admin
1234
```

### 4.1.5 分发证书到所有的master节点

```
ansible k8s-master -m copy -a 'src=/opt/k8s/certs/admin-key.pem dest=/etc/kubernetes/ssl/'
ansible k8s-master -m copy -a 'src=/opt/k8s/certs/admin.pem dest=/etc/kubernetes/ssl/'
12
```

### 4.1.6 生成kubeconfig 配置文件

```
# 设置集群参数
[root@k8s-master ~]#  kubectl config set-cluster kubernetes \
     --certificate-authority=/etc/kubernetes/ssl/ca.pem \
     --embed-certs=true \
     --server=https://127.0.0.1:6443
Cluster "kubernetes" set.
# 设置客户端认证参数
[root@k8s-master ~]# kubectl config set-credentials admin \
     --client-certificate=/etc/kubernetes/ssl/admin.pem \
     --embed-certs=true \
     --client-key=/etc/kubernetes/ssl/admin-key.pem
User "admin" set.
# 设置上下文参数
 kubectl config set-context admin@kubernetes \
     --cluster=kubernetes \
     --user=admin
Context "admin@kubernetes" created.
# 设置默认上下文
[root@k8s-master ~]#  kubectl config use-context admin@kubernetes
Switched to context "admin@kubernetes".
以上操作会在当前目录下生成.kube/config文件，操作集群时，apiserver需要对该文件进行验证，创建的admin用户对kubernetes集群有所有权限(集群管理员)。
123456789101112131415161718192021
```

### 4.1.7 分发kubeconfig配置文件

```
scp -r  ~/.kube  192.168.10.12:~/
scp -r  ~/.kube  192.168.10.13:~/
12
```

## 4.2 部署kube-apiserver组件

### 4.2.1 创建kubernetes 证书

```
cat >kubernetes-csr.json<<EOF
{
  "CN": "kubernetes",
  "hosts": [
    "127.0.0.1",
    "192.168.10.11",
    "192.168.10.12",
    "192.168.10.13",
	"192.168.10.16",
    "10.0.0.1",
    "localhost",
    "kubernetes",
    "kubernetes.default",
    "kubernetes.default.svc",
    "kubernetes.default.svc.cluster",
    "kubernetes.default.svc.cluster.local"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "ShangHai",
      "L": "ShangHai",
      "O": "k8s",
      "OU": "System"
    }
  ]
}
EOF



1234567891011121314151617181920212223242526272829303132333435
```

### 4.2.2 生成kubernetes 证书和私钥

```
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kubernetes-csr.json | cfssljson -bare kubernetes
1
```

### 4.2.3 查看证书生成及分发

```
查看证书生成
[root@k8s-master01 certs]# ll -lrt |grep ubernetes
-rw-r--r-- 1 root root  498 1月  10 21:48 kubernetes-csr.json
-rw-r--r-- 1 root root 1647 1月  10 21:48 kubernetes.pem
-rw------- 1 root root 1675 1月  10 21:48 kubernetes-key.pem
-rw-r--r-- 1 root root 1277 1月  10 21:48 kubernetes.csr

分发证书
ansible k8s-master -m copy -a 'src=/opt/k8s/certs/kubernetes.pem dest=/etc/kubernetes/ssl'
ansible k8s-master -m copy -a 'src=/opt/k8s/certs/kubernetes-key.pem dest=/etc/kubernetes/ssl'


123456789101112
```

### 4.2.4 配置kube-apiserver客户端使用的token文件

```
创建 TLS Bootstrapping Token
[root@k8s-master01 certs]# head -c 16 /dev/urandom | od -An -t x | tr -d ' '
73002899d1c8c60eba90e0bece2b14b3
cat <<EOF > /etc/kubernetes/config/token.csv
73002899d1c8c60eba90e0bece2b14b3,kubelet-bootstrap,10001,"system:kubelet-bootstrap"
EOF

1234567
```

### 4.2.5 分发token文件

```
ansible k8s-master -m copy -a 'src=/etc/kubernetes/config/token.csv dest=/etc/kubernetes/config/'
1
```

### 4.2.6 创建apiserver配置文件

```
cat <<EOF >/etc/kubernetes/config/kube-apiserver 
KUBE_APISERVER_OPTS="--logtostderr=true \
--v=4 \
--etcd-servers=https://192.168.10.11:2379,https://192.168.10.12:2379,https://192.168.10.13:2379 \
--bind-address=192.168.10.11 \
--secure-port=6443 \
--advertise-address=192.168.10.11 \
--allow-privileged=true \
--service-cluster-ip-range=10.0.0.0/16 \
--enable-admission-plugins=NamespaceLifecycle,LimitRanger,SecurityContextDeny,ServiceAccount,ResourceQuota,NodeRestriction \
--authorization-mode=RBAC,Node \
--enable-bootstrap-token-auth \
--token-auth-file=/etc/kubernetes/config/token.csv \
--service-node-port-range=30000-50000 \
--tls-cert-file=/etc/kubernetes/ssl/kubernetes.pem  \
--tls-private-key-file=/etc/kubernetes/ssl/kubernetes-key.pem \
--client-ca-file=/etc/kubernetes/ssl/ca.pem \
--service-account-key-file=/etc/kubernetes/ssl/ca-key.pem \
--etcd-cafile=/etc/kubernetes/ssl/ca.pem \
--etcd-certfile=/etc/kubernetes/ssl/kubernetes.pem \
--etcd-keyfile=/etc/kubernetes/ssl/kubernetes-key.pem"
EOF 


分发证书
[root@k8s-master01 config]# ansible k8s-master -m copy -a 'src=/etc/kubernetes/config/kube-apiserver dest=/etc/kubernetes/config/'
修改对应地址为本机地址


1234567891011121314151617181920212223242526272829
```

### 4.2.7 kube-apiserver启动脚本

```
cat > /usr/lib/systemd/system/kube-apiserver.service << EOF
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes

[Service]
EnvironmentFile=/etc/kubernetes/config/kube-apiserver
ExecStart=/opt/kubernetes/bin/kube-apiserver $KUBE_APISERVER_OPTS
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

copy到其他服务器上
[root@k8s-master01 config]# ansible k8s-master -m copy -a 'src=/usr/lib/systemd/system/kube-apiserver.service dest=/usr/lib/systemd/system/'

启动apiserver
ansible k8s-master -m copy -a 'src=/usr/lib/systemd/system/kube-apiserver.service dest=/usr/lib/systemd/system/'
ansible k8s-master -m shell -a 'systemctl daemon-reload'
ansible k8s-master -m shell -a 'systemctl enable kube-apiserver'
ansible k8s-master -m shell -a 'systemctl start kube-apiserver'
ansible k8s-master -m shell -a ' systemctl status kube-apiserver'
查看kube-apiserver运行状态
ansible k8s-master -m shell -a ' systemctl status kube-apiserver' |grep "Active"
1234567891011121314151617181920212223242526
```

![img](https://imgconvert.csdnimg.cn/aHR0cHM6Ly9kZXZvcHN0YWNrLmNuL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDIwLzAzLzFjNGEwZDEwYjYzNWEyNWQ0NzkzMDE0NzAzZDFkN2E0LnBuZw?x-oss-process=image/format,png)

## 4.3 部署kube-scheduler

### 4.3.1 创建schduler配置文件

```
vim  /etc/kubernetes/config/kube-scheduler
KUBE_SCHEDULER_OPTS="--logtostderr=true --v=4 --master=127.0.0.1:8080 --leader-elect"
#参数说明：
--master 连接本地apiserver
--leader-elect 当该组件启动多个时，自动选举（HA）
12345
```

### 4.3.2 systemd管理schduler组件

```
vim /usr/lib/systemd/system/kube-scheduler.service 
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes

[Service]
EnvironmentFile=-/etc/kubernetes/config/kube-scheduler
ExecStart=/usr/local/bin/kube-scheduler $KUBE_SCHEDULER_OPTS
Restart=on-failure

[Install]
WantedBy=multi-user.target


分发配置文件及启动文件
ansible k8s-master -m copy -a 'src=/usr/lib/systemd/system/kube-scheduler.service dest=/usr/lib/systemd/system/'
ansible k8s-master -m copy -a 'src=/etc/kubernetes/config/kube-scheduler dest=/etc/kubernetes/config/'
1234567891011121314151617
```

### 4.3.3 启动schduler服务

```
ansible k8s-master -m shell -a ' systemctl daemon-reload' 
ansible k8s-master -m shell -a ' systemctl enable kube-scheduler' 
ansible k8s-master -m shell -a ' systemctl start kube-scheduler' 
ansible k8s-master -m shell -a ' systemctl status kube-scheduler' |grep -i active
启动情况如图

123456
```

![img](https://imgconvert.csdnimg.cn/aHR0cHM6Ly9kZXZvcHN0YWNrLmNuL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDIwLzAzLzBmOTFhMWY4NGE3NTY5MDE3OGZiNTgyMTQ3YTEzOTcwLnBuZw?x-oss-process=image/format,png)

## 4.4 部署controller-manager组件

### 4.4.1 创建controller-manager配置文件

```
vim  /etc/kubernetes/config/kube-controller-manager
KUBE_CONTROLLER_MANAGER_OPTS="--logtostderr=true \
--v=4 \
--master=127.0.0.1:8080 \
--leader-elect=true \
--address=127.0.0.1 \
--service-cluster-ip-range=10.0.0.0/24 \
--cluster-name=kubernetes \
--cluster-signing-cert-file=/etc/kubernetes/ssl/ca.pem \
--cluster-signing-key-file=/etc/kubernetes/ssl/ca-key.pem  \
--root-ca-file=/etc/kubernetes/ssl/ca.pem \
--service-account-private-key-file=/etc/kubernetes/ssl/ca-key.pem"
12345678910111213
```

### 4.4.2 systemd管理controller-manager组件

```
vim  /usr/lib/systemd/system/kube-controller-manager.service
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes

[Service]
EnvironmentFile=/etc/kubernetes/config/kube-controller-manager
ExecStart=/usr/local/bin/kube-controller-manager $KUBE_CONTROLLER_MANAGER_OPTS
Restart=on-failure

[Install]
WantedBy=multi-user.target

配置文件和启动文件分发
ansible k8s-master -m copy -a 'src=/usr/lib/systemd/system/kube-controller-manager.service dest=/usr/lib/systemd/system/'
ansible k8s-master -m copy -a 'src=/etc/kubernetes/config/kube-controller-manager dest=/etc/kubernetes/config/'
 

123456789101112131415161718
```

### 4.4.3 启动controller-manager

```
ansible k8s-master -m shell -a ' systemctl daemon-reload' 
ansible k8s-master -m shell -a ' systemctl enable kube-controller-manager' 
ansible k8s-master -m shell -a ' systemctl restart kube-controller-manager' 
ansible k8s-master -m shell -a 'systemctl status kube-controller-manager' |grep -i active
启动情况验证如下图
12345
```

![img](https://imgconvert.csdnimg.cn/aHR0cHM6Ly9kZXZvcHN0YWNrLmNuL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDIwLzAzLzgyMDZlYmZjMWJlZjJkMzg5NmU1OGY1ZWYyMmMxZjMwLnBuZw?x-oss-process=image/format,png)

## 4.5 查看集群组件状态

![img](https://imgconvert.csdnimg.cn/aHR0cHM6Ly9kZXZvcHN0YWNrLmNuL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDIwLzA0L2E2Nzk1Zjk5YWIxNzZmZjc3ZThkZmM0NzIzYjM0ZTEwLnBuZw?x-oss-process=image/format,png)

# 5 master高可用

> 所谓的Master HA，其实就是APIServer的HA，Master的其他组件controller-manager、scheduler都是可以通过etcd做选举（–leader-elect），而APIServer设计的就是可扩展性，所以做到APIServer很容易，只要前面加一个负载均衡轮训转发请求即可。如果是aws可以采用负载均衡器实现，如果是实体机可以采用Haproxy+keeplive实现.

## 5.1 Haproxy+keepalive搭建高可用

> 本次实验在master01 master02,nastero3上搭建keepalive和haproxy.

### 5.1.1 安装配置haproxy服务

```
1.安装haproxy
[root@k8s-master01 ~]# yum install -y  haproxy
2.配置haproxy
cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.ori
cat /etc/haproxy/haproxy.cfg
global
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    stats socket /var/run/haproxy-admin.sock mode 660 level admin
    stats timeout 30s
    user haproxy
    group haproxy
    daemon
    nbproc 1
defaults
    log global
    timeout connect 5000
    timeout client 10m
    timeout server 10m
listen admin_stats
    bind 0.0.0.0:10080
    mode http
    log 127.0.0.1 local0 err
    stats refresh 30s
    stats uri /status
    stats realm welcome login\ Haproxy
    stats auth along:along123
    stats hide-version
    stats admin if TRUE
listen kube-master
    bind 0.0.0.0:8443
    mode tcp
    option tcplog
    balance source
    server 192.168.10.11 192.168.10.11:6443 check inter 2000 fall 2 rise 2 weight 1
    server 192.168.10.12 192.168.10.12:6443 check inter 2000 fall 2 rise 2 weight 1
    server 192.168.10.13 192.168.10.13:6443 check inter 2000 fall 2 rise 2 weight 1

3.启动haproxy
systemctl restart haproxy
[root@k8s-master01 ~]# systemctl enable haproxy
Created symlink from /etc/systemd/system/multi-user.target.wants/haproxy.service to /usr/lib/systemd/system/haproxy.service.
[root@k8s-master01 ~]# systemctl status haproxy
● haproxy.service - HAProxy Load Balancer
   Loaded: loaded (/usr/lib/systemd/system/haproxy.service; enabled; vendor preset: disabled)
   Active: active (running) since 五 2020-04-10 16:35:46 CST; 24s ago
 Main PID: 10235 (haproxy-systemd)
   CGroup: /system.slice/haproxy.service
           ├─10235 /usr/sbin/haproxy-systemd-wrapper -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid
           ├─10236 /usr/sbin/haproxy -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid -Ds
           └─10237 /usr/sbin/haproxy -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid -Ds


123456789101112131415161718192021222324252627282930313233343536373839404142434445464748495051525354
```

### 5.1.2 安装配置keepalived

> keepalived 是一主（master）多备（backup）运行模式，故有两种类型的配置文件。

```
1.安装keepalived
 yum install -y keepalived
2.配置keepalived
master:
[root@k8s-master01 ~]# cp /etc/keepalived/keepalived.conf /etc/keepalived/keepalived.conf.ori
 cat /etc/keepalived/keepalived.conf
! Configuration File for keepalived

global_defs {
   router_id LVS_DEVEL
}

vrrp_instance VI_1 {
    state MASTER
    interface eth0
    virtual_router_id 51
    priority 100
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
        192.168.10.16
    }
}

说明：
1)、global_defs 只保留 router_id（每个节点都不同）；
2)、修改 interface（vip绑定的网卡），及 virtual_ipaddress（vip地址及掩码长度）；
3)、删除后面的示例
4)、其他节点只需修改 state 为 BACKUP，优先级 priority 低于100即可。

3.启动keeplive
[root@k8s-master01 ~]# systemctl start keepalived
[root@k8s-master01 ~]# systemctl enable keepalived
Created symlink from /etc/systemd/system/multi-user.target.wants/keepalived.service to /usr/lib/systemd/system/keepalived.service.
[root@k8s-master01 ~]# systemctl status keepalived
● keepalived.service - LVS and VRRP High Availability Monitor
   Loaded: loaded (/usr/lib/systemd/system/keepalived.service; enabled; vendor preset: disabled)
   Active: active (running) since 五 2020-04-10 16:51:08 CST; 14s ago
 Main PID: 10305 (keepalived)
   CGroup: /system.slice/keepalived.service
           ├─10305 /usr/sbin/keepalived -D
           ├─10306 /usr/sbin/keepalived -D
           └─10307 /usr/sbin/keepalived -D

iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport 8443 -j ACCEPT


 验证如图

12345678910111213141516171819202122232425262728293031323334353637383940414243444546474849505152
```

![img](https://imgconvert.csdnimg.cn/aHR0cHM6Ly9kZXZvcHN0YWNrLmNuL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDIwLzA0Lzg5N2Q3MTAzNjNiZDA2MmVhYzk1MjMxMzJhZTA1M2NkLnBuZw?x-oss-process=image/format,png)

# 6 node节点部署组件

> Master apiserver启用TLS认证后，Node节点kubelet组件想要加入集群，必须使用CA签发的有效证书才能与apiserver通信，当Node节点很多时，签署证书是一件很繁琐的事情，因此有了TLS Bootstrapping机制，kubelet会以一个低权限用户自动向apiserver申请证书，kubelet的证书由apiserver动态签署。
> kubernetes work节点运行如下组件：
> docker 前面已经部署
> kubelet
> kube-proxy

```
注：
以下操作属于node节点上组件的部署，在master节点上只是进行文件配置，然后发布至各node节点。
若是需要master也作为node节点加入集群，也需要在master节点部署docker、kubelet、kube-proxy。
123
```

## 6.1 copy kubelet kube-proxy组件到node节点

```
将kubelet, kube-proxy二进制文件拷贝node节点
scp kubernetes/server/bin/{kube-proxy,kubelet} 192.168.10.14:/usr/local/bin/
scp kubernetes/server/bin/{kube-proxy,kubelet} 192.168.10.15:/usr/local/bin/
1234
```

## 6.2 创建kubelet bootstrap kubeconfig文件

```
[root@k8s-master01 ~]# cat environment.sh 
# 创建kubelet bootstrapping kubeconfig
BOOTSTRAP_TOKEN=73002899d1c8c60eba90e0bece2b14b3
KUBE_APISERVER="https://192.168.10.16:8443"
# 设置集群参数
kubectl config set-cluster kubernetes \
  --certificate-authority=/etc/kubernetes/ssl/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=bootstrap.kubeconfig

# 设置客户端认证参数
kubectl config set-credentials kubelet-bootstrap \
  --token=${BOOTSTRAP_TOKEN} \
  --kubeconfig=bootstrap.kubeconfig

# 设置上下文参数
kubectl config set-context default \
  --cluster=kubernetes \
  --user=kubelet-bootstrap \
  --kubeconfig=bootstrap.kubeconfig

# 设置默认上下文
kubectl config use-context default --kubeconfig=bootstrap.kubeconfig


[root@k8s-master01 ~]# bash environment.sh 
Cluster "kubernetes" set.
User "kubelet-bootstrap" set.
Context "default" created.
Switched to context "default".


123456789101112131415161718192021222324252627282930313233
```

## 6.3 创建kubelet.kubeconfig文件

```
[root@k8s-master01 ~]# cat envkubelet.kubeconfig.sh 
# 创建kubelet bootstrapping kubeconfig
BOOTSTRAP_TOKEN=73002899d1c8c60eba90e0bece2b14b3
KUBE_APISERVER="https://192.168.10.16:6443"

# 设置集群参数
kubectl config set-cluster kubernetes \
  --certificate-authority=/etc/kubernetes/ssl/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=kubelet.kubeconfig

# 设置客户端认证参数
kubectl config set-credentials kubelet \
  --token=${BOOTSTRAP_TOKEN} \
  --kubeconfig=kubelet.kubeconfig

# 设置上下文参数
kubectl config set-context default \
  --cluster=kubernetes \
  --user=kubelet \
  --kubeconfig=kubelet.kubeconfig

# 设置默认上下文
kubectl config use-context default --kubeconfig=kubelet.kubeconfig


执行脚本,生成kubelet.kubeconfig
[root@k8s-master01 ~]# bash envkubelet.kubeconfig.sh 
Cluster "kubernetes" set.
User "kubelet" set.
Context "default" created.
Switched to context "default".

12345678910111213141516171819202122232425262728293031323334
```

## 6.4 创建kube-proxy kubeconfig文件

### 6.4.1 创建kube-proxy证书

```
创建kube-proxy证书
cat > kube-proxy-csr.json <<EOF
{
  "CN": "system:kube-proxy",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "ShangHai",
      "L": "ShangHai",
      "O": "k8s",
      "OU": "System"
    }
  ]
} 

EOF
生成证书和私钥:
cfssl gencert -ca=/opt/k8s/certs/ca.pem \
-ca-key=/opt/k8s/certs/ca-key.pem \
-config=/opt/k8s/certs/ca-config.json \
-profile=kubernetes kube-proxy-csr.json | cfssljson -bare kube-proxy

然后copy到其他节点
123456789101112131415161718192021222324252627
```

### 6.4.2 创建kube-proxy kubeconfig文件

```
[root@k8s-master01 ~]# cat env_proxy.sh
#创建kube-proxy kubeconfig文件
BOOTSTRAP_TOKEN=73002899d1c8c60eba90e0bece2b14b3
KUBE_APISERVER="https://192.168.10.16:8443"

kubectl config set-cluster kubernetes \
  --certificate-authority=/etc/kubernetes/ssl/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config set-credentials kube-proxy \
  --client-certificate=./kube-proxy.pem \
  --client-key=./kube-proxy-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config set-context default \
  --cluster=kubernetes \
  --user=kube-proxy \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig


执行脚本，生成kube-proxy.kubeconfig
[root@k8s-master01 ~]# bash env_proxy.sh 
Cluster "kubernetes" set.
User "kube-proxy" set.
Context "default" created.
Switched to context "default".

1234567891011121314151617181920212223242526272829303132
将bootstrap kubeconfig kube-proxy.kubeconfig 文件拷贝到所有 nodes节点
scp bootstrap.kubeconfig    kube-proxy.kubeconfig 192.168.10.14:/etc/kubernetes/config
scp bootstrap.kubeconfig    kube-proxy.kubeconfig 192.168.10.15:/etc/kubernetes/config


12345
```

## 6.5 部署kubelet组件

> 无特殊说明，则默认在所有node节点上都部署。

```
Kubelet组件运行在Node节点上，维持运行中的Pods以及提供kuberntes运行时环境，主要完成以下使命：
　　１．监视分配给该Node节点的pods
　　２．挂载pod所需要的volumes
　　３．下载pod的secret
　　４．通过docker/rkt来运行pod中的容器
　　５．周期的执行pod中为容器定义的liveness探针
　　６．上报pod的状态给系统的其他组件
　　７．上报Node的状态
12345678
```

### 6.5.1 将kubelet-bootstrap用户绑定到系统集群角色

```
在master01上面执行，将kubelet-bootstrap用户绑定到系统集群角色：
[root@k8s-master01 ~]# kubectl create clusterrolebinding kubelet-bootstrap \
>   --clusterrole=system:node-bootstrapper \
>   --user=kubelet-bootstrap
clusterrolebinding.rbac.authorization.k8s.io/kubelet-bootstrap created



12345678
```

### 6.5.2 创建kubelet参数配置模板文件

```
 cat /etc/kubernetes/config/kubelet.config
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
address: 192.168.10.14(nodeip)
port: 10250
readOnlyPort: 10255
cgroupDriver: cgroupfs
clusterDomain: cluster.local.
failSwapOn: false
authentication:
  anonymous:
    enabled: true

12345678910111213
```

### 6.5.3 创建kubelet配置文件

```
cat /etc/kubernetes/config/kubelet
KUBELET_OPTS="--logtostderr=true \
--v=4 \
--hostname-override=192.168.10.14(nodeip) \
--kubeconfig=/etc/kubernetes/config/kubelet.kubeconfig \
--bootstrap-kubeconfig=/etc/kubernetes/config/bootstrap.kubeconfig \
--config=/etc/kubernetes/config/kubelet.config \
--cert-dir=/etc/kubernetes/ssl \
--pod-infra-container-image=registry.cn-hangzhou.aliyuncs.com/google-containers/pause-amd64:3.0"


参数说明：
--hostname-override 在集群中显示的主机名
--kubeconfig 指定kubeconfig文件位置，会自动生成
--bootstrap-kubeconfig 指定刚才生成的bootstrap.kubeconfig文件
--cert-dir 颁发证书存放位置
--pod-infra-container-image 管理Pod网络的镜像

  
12345678910111213141516171819
```

### 6.5.4 systemd管理kubelet组件

```
cat /usr/lib/systemd/system/kubelet.service
[Unit]
Description=Kubernetes Kubelet
After=docker.service
Requires=docker.service

[Service]
EnvironmentFile=/etc/kubernetes/config/kubelet
ExecStart=/usr/local/bin/kubelet $KUBELET_OPTS
Restart=on-failure
KillMode=process

[Install]
WantedBy=multi-user.target

123456789101112131415
```

### 6.5.5 启动kubelet服务

```
node节点执行
systemctl daemon-reload
systemctl enable kubelet
systemctl restart kubelet
验证服务启动情况
12345
```

![img](https://imgconvert.csdnimg.cn/aHR0cHM6Ly9kZXZvcHN0YWNrLmNuL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDIwLzA0Lzk5MTA4ODA2Yzk3NmU0YmZmMGYxNTg2MTViMGJhMDUwLnBuZw?x-oss-process=image/format,png)

### 6.5.6 在Master审批Node加入集群

```
1）在Master节点查看请求签名的Node：
[root@k8s-master01 certs]# kubectl get csr
NAME                                                   AGE     REQUESTOR           CONDITION
node-csr-dFyZhaf2XT1YIZ2gbRAVc8OR0C8GSJxDgsJ_MepSLBg   5m43s   kubelet-bootstrap   Pending
node-csr-vSd0CZpu1aLgJoPj6kw36OX7ACD_ZOT8QjZPPz-nkq8   5m41s   kubelet-bootstrap   Pending

2）在Master节点批准签名
[root@k8s-master01 certs]#  kubectl get csr|grep 'Pending' | awk 'NR>0{print $1}'| xargs kubectl certificate approve
certificatesigningrequest.certificates.k8s.io/node-csr-dFyZhaf2XT1YIZ2gbRAVc8OR0C8GSJxDgsJ_MepSLBg approved
certificatesigningrequest.certificates.k8s.io/node-csr-vSd0CZpu1aLgJoPj6kw36OX7ACD_ZOT8QjZPPz-nkq8 approved

3）查看签名状态
kubectl get node

1234567891011121314
```

![img](https://imgconvert.csdnimg.cn/aHR0cHM6Ly9kZXZvcHN0YWNrLmNuL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDIwLzA0LzlmMzBiM2FlYmJkMWIzNzFmZDNjYmEyOWI4OTFmNWVkLnBuZw?x-oss-process=image/format,png)

## 6.6 部署node kube-proxy组件

> kube-proxy 运行在所有 node节点上，它监听 apiserver 中 service 和 Endpoint 的变化情况，创建路由规则来进行服务负载均衡。

### 6.6.1 创建kube-proxy配置文件(所有node)

```
 cat /etc/kubernetes/config/kube-proxy
KUBE_PROXY_OPTS="--logtostderr=true \
--v=4 \
--hostname-override=192.168.10.14（nodeip） \
--cluster-cidr=10.0.0.0/24 \
--kubeconfig=/etc/kubernetes/config/kube-proxy.kubeconfig"

1234567
```

### 6.6.2 创建kube-proxy systemd unit文件

```
cat /usr/lib/systemd/system/kube-proxy.service
[Unit]
Description=Kubernetes Proxy
After=network.target

[Service]
EnvironmentFile=-/etc/kubernetes/config/kube-proxy
ExecStart=/usr/local/bin/kube-proxy $KUBE_PROXY_OPTS
Restart=on-failure

[Install]
WantedBy=multi-user.target
123456789101112
```

### 6.6.3 启动kube-proxy服务

```
systemctl daemon-reload
systemctl enable kube-proxy
systemctl restart kube-proxy
查看启动情况
1234
```

![img](https://imgconvert.csdnimg.cn/aHR0cHM6Ly9kZXZvcHN0YWNrLmNuL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDIwLzA0LzEwYTA4ZTI2ODRhMjI5MTY1NWRhZDY3MjIwNzMyYThkLnBuZw?x-oss-process=image/format,png)

# 7 部署flannel网络

## 7.1 创建flannel证书和私钥

> flanneld从etcd集群存取网段分配信息,而etcd集群启用了双向x509证书认证,所以需要为flannel生成证书和私钥。也可以不创建，用上面创建好的。

```
创建证书签名请求:
cd /opt/k8s/certs
cat >flanneld-csr.json<<EOF

{
  "CN": "flanneld",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "ShangHai",
      "L": "ShangHai",
      "O": "k8s",
      "OU": "System"
    }
  ]
}
EOF

生成证书和私钥:
cfssl gencert -ca=/opt/k8s/certs/ca.pem \
-ca-key=/opt/k8s/certs/ca-key.pem \
-config=/opt/k8s/certs/ca-config.json \
-profile=kubernetes flanneld-csr.json | cfssljson -bare flanneld

1234567891011121314151617181920212223242526272829
```

## 7.2 将生成的证书和私钥分发到所有节点

```
ansible k8s-all -m copy -a 'src=/opt/k8s/certs/flanneld.pem dest=/etc/kubernetes/ssl/'
ansible k8s-all -m copy -a 'src=/opt/k8s/certs/flanneld-key.pem dest=/etc/kubernetes/ssl/'

123
```

## 7.3 下载和分发flanneld二进制文件

```
下载flannel
cd /opt/k8s/
mkdir flannel
wget https://github.com/coreos/flannel/releases/download/v0.11.0/flannel-v0.11.0-linux-amd64.tar.gz
tar -xzvf flannel-v0.11.0-linux-amd64.tar.gz -C flannel
分发二进制文件到集群所有节点
 ansible k8s-all -m copy -a 'src=/opt/k8s/flannel/flanneld dest=/usr/local/bin/ mode=0755'
 ansible k8s-all -m copy -a 'src=/opt/k8s/flannel/mk-docker-opts.sh   dest=/usr/local/bin/ mode=0755'
12345678
```

## 7.4 创建flanneld的systemd unit文件

```
cat /usr/lib/systemd/system/flanneld.service
[Unit]
Description=Flanneld overlay address etcd agent
After=network.target
After=network-online.target
Wants=network-online.target
After=etcd.service
Before=docker.service

[Service]
Type=notify
ExecStart=/usr/local/bin/flanneld  --ip-masq  \
  -etcd-cafile=/etc/kubernetes/ssl/ca.pem \
  -etcd-certfile=/etc/kubernetes/ssl/flanneld.pem \
  -etcd-keyfile=/etc/kubernetes/ssl/flanneld-key.pem \
  -etcd-endpoints=https://192.168.10.11:2379,https://192.168.10.12:2379,https://192.168.10.13:2379 \
  -etcd-prefix=/coreos.com/network/
ExecStartPost=/usr/local/bin/mk-docker-opts.sh -k DOCKER_NETWORK_OPTIONS -d /run/flannel/subnet.env

Restart=on-failure

[Install]
WantedBy=multi-user.target
RequiredBy=docker.service

分发到所有服务器
ansible k8s-all -m copy -a 'src=/root/k8s/flanneld.service  dest=/usr/lib/systemd/system/'
123456789101112131415161718192021222324252627
```

## 7.5 向etcd写入集群Pod网段信息

```
[root@k8s-master01 ~]# etcdctl --cacert=/etc/kubernetes/ssl/ca.pem --cert=/etc/kubernetes/ssl/etcd.pem --key=/etc/kubernetes/ssl/etcd-key.pem --endpoints="https://192.168.10.11:2379,https://192.168.10.12:2379,https://192.168.10.13:2379"  put /coreos.com/network/config '{ "Network": "10.0.0.0/16", "Backend": {"Type": "vxlan", "DirectRouting": true}}'
OK

检查分配给各flanneld的Pod网段信息
 etcdctl --cacert=/etc/kubernetes/ssl/ca.pem --cert=/etc/kubernetes/ssl/etcd.pem --key=/etc/kubernetes/ssl/etcd-key.pem --endpoints="https://192.168.10.11:2379,https://192.168.10.12:2379,https://192.168.10.13:2379"  get /coreos.com/network/config 
/coreos.com/network/config
{ "Network": "10.0.0.0/16", "Backend": {"Type": "vxlan", "DirectRouting": true}}

12345678
```

## 7.6 启动并检查flanneld服务

```
systemctl daemon-reload
systemctl enable flanneld
systemctl start flanneld
123
```

## 7.7 查看flannel分配的子网信息

```
[root@k8s-node01 ~]# cat /run/flannel/subnet.env 
DOCKER_OPT_BIP="--bip=10.30.80.1/24"
DOCKER_OPT_IPMASQ="--ip-masq=false"
DOCKER_OPT_MTU="--mtu=1450"
DOCKER_NETWORK_OPTIONS=" --bip=10.30.80.1/24 --ip-masq=false --mtu=1450"
[root@k8s-node01 ~]# 

1234567
```

## 7.8 查看已分配的Pod子网段列表(/24)

```
 etcdctl --endpoints="https://192.168.10.11:2379,https://192.168.10.12:2379,https://192.168.10.13:2379" --ca-file=/etc/kubernetes/ssl/ca.pem --cert-file=/etc/kubernetes/ssl/flanneld.pem --key-file=/etc/kubernetes/ssl/flanneld-key.pem ls /coreos.com/network/subnets
/coreos.com/network/subnets/10.30.4.0-24
/coreos.com/network/subnets/10.30.34.0-24
/coreos.com/network/subnets/10.30.62.0-24
/coreos.com/network/subnets/10.30.80.0-24

123456
```

## 7.9 查看某一Pod网段对应的节点IP和flannel接口地址

```
etcdctl --endpoints="https://192.168.10.11:2379,https://192.168.10.12:2379,https://192.168.10.13:2379" --ca-file=/etc/kubernetes/ssl/ca.pem --cert-file=/etc/kubernetes/ssl/flanneld.pem --key-file=/etc/kubernetes/ssl/flanneld-key.pem get  /coreos.com/network/subnets/10.30.4.0-24
{"PublicIP":"192.168.10.13","BackendType":"vxlan","BackendData":{"VtepMAC":"4a:9a:25:c4:14:a7"}}

123
```

## 7.10 验证各节点能通过Pod网段互通

```
NODE_IPS=("192.168.10.11" "192.168.10.12" "192.168.10.13" "192.168.10.14" "192.168.10.15")
for node_ip in ${NODE_IPS[@]};do
    echo ">>> ${node_ip}"
 #在各节点上部署 flannel 后，检查是否创建了 flannel 接口(名称可能为 flannel0、flannel.0、flannel.1 等)
    ssh ${node_ip} "/usr/sbin/ip addr show flannel.1|grep -w inet"
 #在各节点上 ping 所有 flannel 接口 IP，确保能通
    ssh ${node_ip} "ping -c 1 10.30.34.0"
    ssh ${node_ip} "ping -c 1 10.30.4.0"
    ssh ${node_ip} "ping -c 1 10.30.80.0"
    ssh ${node_ip} "ping -c 1 10.30.62.0"
done
chmod +x /opt/k8s/script/ping_flanneld.sh && bash /opt/k8s/script/ping_flanneld.sh
123456789101112
```

## 7.11 配置Docker启动指定子网段

```
修改/usr/lib/systemd/system/docker.service
[Service]
EnvironmentFile=/run/flannel/subnet.env
ExecStart=/usr/bin/dockerd $DOCKER_NETWORK_OPTIONS

重启docker
systemctl daemon-reload
systemctl restart docker

验证如图说明生效
12345678910
```

![img](https://imgconvert.csdnimg.cn/aHR0cHM6Ly9kZXZvcHN0YWNrLmNuL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDIwLzA0LzZhMTRmNzg2YTllM2ZkYWU0ZDUwMTNmZTEzMzEwMjdkLnBuZw?x-oss-process=image/format,png)

# 8 使用kubectl的run命令创建deployment

## 8.1 创建实例验证集群状态

```
kubectl run nginx --image=nginx:1.16.0
查看创建的实例
 kubectl get pods -o wide
NAME                     READY   STATUS    RESTARTS   AGE   IP           NODE            NOMINATED NODE   READINESS GATES
nginx-797fbb6bcf-24449   1/1     Running   0          91s   10.30.55.2   192.168.10.15   <none>           <none>

123456
```

## 8.2 使用expose将端口暴露出来

```
[root@k8s-master01 ~]# kubectl expose deployment nginx --port 80 --type LoadBalancer
service/nginx exposed
[root@k8s-master01 ~]# kubectl get services -o wide
NAME         TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE   SELECTOR
kubernetes   ClusterIP      10.0.0.1       <none>        443/TCP        21h   <none>
nginx        LoadBalancer   10.0.221.144   <pending>     80:43838/TCP   19s   run=nginx
[root@k8s-master01 ~]# 

访问验证
123456789
```

![img](https://imgconvert.csdnimg.cn/aHR0cHM6Ly9kZXZvcHN0YWNrLmNuL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDIwLzA0L2FlNzJkODE0ZjI4OTIzY2M4ZjcyMjE0Mjk3OTE4ZmZhLnBuZw?x-oss-process=image/format,png)

## 8.3 通过scale命令扩展应用

```
 kubectl scale deployments/nginx --replicas=4
1
```

## 8.4 更新应用镜像，滚动更新应用镜像

```
[root@k8s-master bin]# kubectl set image deployments/nginx nginx=qihao/nginx
deployment.extensions/nginx image updated
确认更新
kubectl rollout status deployments/nginx 
回滚到之前版本
kubectl rollout undo deployments/nginx 

12345678
```

# 9 部署Dashboard V2.0(beta5)

## 9.1　下载并修改Dashboard安装脚本

```
下载yaml文件
    wget https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta5/aio/deploy/recommended.yaml

修改recommended.yaml文件内容
kind: Service
apiVersion: v1
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kubernetes-dashboard
spec:
  type: NodePort #新加
  ports:
    - port: 443
      targetPort: 8443
      nodePort: 30001 #新加
  selector:
    k8s-app: kubernetes-dashboard

#因为自动生成的证书很多浏览器无法使用，所以我们自己创建，注释掉kubernetes-dashboard-certs对象声明
#apiVersion: v1
#kind: Secret
#metadata:
#  labels:
#    k8s-app: kubernetes-dashboard
#  name: kubernetes-dashboard-certs
#  namespace: kubernetes-dashboard
#type: Opaque


12345678910111213141516171819202122232425262728293031
```

## 9.2 创建证书

```
 kubectl create clusterrolebinding system:anonymous   --clusterrole=cluster-admin   --user=system:anonymous
mkdir dashboard-certs
cd dashboard-certs/
#创建命名空间
kubectl create namespace kubernetes-dashboard
# 创建key文件
openssl genrsa -out dashboard.key 2048
#证书请求
openssl req -days 36000 -new -out dashboard.csr -key dashboard.key -subj '/CN=dashboard-cert'
#自签证书
openssl x509 -req -in dashboard.csr -signkey dashboard.key -out dashboard.crt
#创建kubernetes-dashboard-certs对象
kubectl create secret generic kubernetes-dashboard-certs --from-file=dashboard.key --from-file=dashboard.crt -n kubernetes-dashboard
12345678910111213
```

## 9.3 安装Dashboard

```
#安装
kubectl create -f  ~/recommended.yaml
#检查结果
kubectl get pods -A  -o wide
kubectl get service -n kubernetes-dashboard  -o wide
12345
```

## 9.4 创建集群管理员账号

### 9.4.1 创建服务账号

```
 cat dashboard-admin.yaml 
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: dashboard-admin
  namespace: kubernetes-dashboard
  
 kubectl apply -f  dashboard-admin.yaml

1234567891011
```

### 9.4.2 创建集群角色绑定

```
cat dashboard-admin-bind-cluster-role.yaml 
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: dashboard-admin-bind-cluster-role
  labels:
    k8s-app: kubernetes-dashboard
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: dashboard-admin
  namespace: kubernetes-dashboard
kubectl apply -f  dashboard-admin-bind-cluster-role.yaml
12345678910111213141516
```

### 9.4.3 获取用户登录Ｔoken

```
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-token | awk '{print $1}')
Name:         dashboard-admin-token-w96nz
Namespace:    kube-system
Labels:       <none>
Annotations:  kubernetes.io/service-account.name: dashboard-admin
              kubernetes.io/service-account.uid: 148f4c29-1a53-4bca-b6c8-93dce2cbab27

Type:  kubernetes.io/service-account-token

Data
====
ca.crt:     1363 bytes
namespace:  11 bytes
token:      eyJhbGciOiJSUzI1NiIsImtpZCI6Iml3QjR0Y3FWakJLVW1SRzVqVDBtU2pOTUdsS3IySUpPSjZ5V3oxLU83MHMifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJrdWJlLXN5c3RlbSIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJkYXNoYm9hcmQtYWRtaW4tdG9rZW4tdzk2bnoiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC5uYW1lIjoiZGFzaGJvYXJkLWFkbWluIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQudWlkIjoiMTQ4ZjRjMjktMWE1My00YmNhLWI2YzgtOTNkY2UyY2JhYjI3Iiwic3ViIjoic3lzdGVtOnNlcnZpY2VhY2NvdW50Omt1YmUtc3lzdGVtOmRhc2hib2FyZC1hZG1pbiJ9.K1FY-hS7lSOA5hK_vm2jXw2LSCSqdEQvQDBQLi4aCe7gUq_VQ9ZKWeriUKP0uJua5yexuutBzJsFb4d0Y49X-PKaIIBkrbkAPEeMHlTdrY3LwmC_hjDZhMEvm0g6icl38BX7SZ4mMCJ2bduDcyerjadpmGDKVTgRsfldjO24v2OFySfY5dDjKi9SH2rpf4mvJfVnG05cKfjr4sDbGETc1KVUyffZfFeNOZaW3VOGoY07rHRc7CkQZ812byEajjeySJm9KZxxmfylZS4T84dxc_NgYZG9eezzNES0mQ9E-LP-QrmomjddxH7LLFvgovK9qA5DPU4QHgwYMdTHFFWp5g

123456789101112131415
```

## 9.5 查看dashboard状态

```
[root@k8s-master01 dashboard]# kubectl  get pods -n kubernetes-dashboard
NAME                                         READY   STATUS    RESTARTS   AGE
dashboard-metrics-scraper-76585494d8-nrvrg   1/1     Running   0          41m
kubernetes-dashboard-6b86b44f87-gxlv8        1/1     Running   0          41m
[root@k8s-master01 dashboard]# kubectl get pods -A  -o wide
NAMESPACE              NAME                                         READY   STATUS    RESTARTS   AGE   IP           NODE            NOMINATED NODE   READINESS GATES
default                nginx-797fbb6bcf-24449                       1/1     Running   1          25h   10.30.55.2   192.168.10.15   <none>           <none>
default                nginx-797fbb6bcf-d29pc                       1/1     Running   1          25h   10.30.80.3   192.168.10.14   <none>           <none>
default                nginx-797fbb6bcf-fkfgc                       1/1     Running   1          25h   10.30.55.3   192.168.10.15   <none>           <none>
default                nginx-797fbb6bcf-lg26t                       1/1     Running   1          25h   10.30.80.2   192.168.10.14   <none>           <none>
kubernetes-dashboard   dashboard-metrics-scraper-76585494d8-nrvrg   1/1     Running   0          41m   10.30.80.5   192.168.10.14   <none>           <none>
kubernetes-dashboard   kubernetes-dashboard-6b86b44f87-gxlv8        1/1     Running   0          41m   10.30.80.4   192.168.10.14   <none>           <none>
[root@k8s-master01 dashboard]# kubectl  get pods -n kubernetes-dashboard
NAME                                         READY   STATUS    RESTARTS   AGE
dashboard-metrics-scraper-76585494d8-nrvrg   1/1     Running   0          41m
kubernetes-dashboard-6b86b44f87-gxlv8        1/1     Running   0          41m

1234567891011121314151617
```

## 9.6 登录dashboard验证服务

> 登录方式有两种，这里选择令牌的方式登录。选择上面的token粘贴到界面里，登录成功如下图。

```
获取集群服务地址
 kubectl  cluster-info
Kubernetes master is running at https://192.168.10.11:6443
kubernetes-dashboard is running at https://192.168.10.11:6443/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.

1234567
```

![img](https://imgconvert.csdnimg.cn/aHR0cHM6Ly9kZXZvcHN0YWNrLmNuL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDIwLzA0LzgxN2NkMjdjYTUxYzY3M2M1ZmZkODA4NzI4OTZhOGY0LnBuZw?x-oss-process=image/format,png)

# 10 安装CoreDNS服务

## 10.1 下载配置文件

```
mkdir /opt/coredns  && cd /opt/coredns/
wget https://raw.githubusercontent.com/coredns/deployment/master/kubernetes/deploy.sh
wget https://raw.githubusercontent.com/coredns/deployment/master/kubernetes/coredns.yaml.sed
chmod +x deploy.sh

12345
```

## 10.2 修改coredns文件

```
先查看集群的CLUSTERIP网段
kubectl get svc


1234
```

![img](https://imgconvert.csdnimg.cn/aHR0cHM6Ly9kZXZvcHN0YWNrLmNuL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDIwLzA0LzJjZTkzODUzZDUzYzZiNmNiNmNjNDk5N2EwZjNkOGQ2LnBuZw?x-oss-process=image/format,png)

```
修改部署文件
修改$DNS_DOMAIN、$DNS_SERVER_IP变量为实际值，并修改image后面的镜像。
这里直接用deploy.sh脚本进行修改：
./deploy.sh -s -r 10.0.0.0/16 -i 10.0.0.2 -d cluster.local > coredns.yaml
注意：网段为10.0.0.0/16（同apiserver定义的service-cluster-ip-range值，非kube-proxy中的cluster-cidr值），DNS的地址设置为10.0.0.2

修改内容如下
kubernetes cluster.local  10.0.0.0/16 
 forward . /etc/resolv.conf
 coredns/coredns:1.5.0
 clusterIP: 10.0.0.2
1234567891011
```

## 10.3 部署coredns

```
  kubectl apply -f coredns.yaml
查看
kubectl get svc,pod -n kube-system


  
123456
```

![img](https://imgconvert.csdnimg.cn/aHR0cHM6Ly9kZXZvcHN0YWNrLmNuL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDIwLzA0L2FhMGJlNzk5ZDE5NTI1NDU5MjYyODZlOGUxODIyOWY5LnBuZw?x-oss-process=image/format,png)

## 10.4 修改kubelet的dns服务参数

```
在所有node节点上操作，添加以下参数

vim /etc/kubernetes/config/kubelet
--cluster-dns=10.0.0.2 \
--cluster-domain=cluster.local. \
--resolv-conf=/etc/resolv.conf \
#重启kubelet 并查看状态

systemctl daemon-reload && systemctl restart kubelet && systemctl status kubelet
123456789
```

## 10.5 验证CoreDNS服务解析

```
[root@k8s-master01 coredns]# kubectl run busybox --image busybox:1.28 --restart=Never --rm -it busybox -- sh
If you don't see a command prompt, try pressing enter.

/ # nslookup kubernetes.default
Server:    10.0.0.2
Address 1: 10.0.0.2 kube-dns.kube-system.svc.cluster.local

Name:      kubernetes.default
Address 1: 10.0.0.1 kubernetes.default.svc.cluster.local
/ # 
/ # nslookup www.baidu.com
Server:    10.0.0.2
Address 1: 10.0.0.2 kube-dns.kube-system.svc.cluster.local

Name:      www.baidu.com
Address 1: 180.101.49.12
Address 2: 180.101.49.11
/ # cat /etc/resolv.conf
nameserver 10.0.0.2
search default.svc.cluster.local. svc.cluster.local. cluster.local. localdomain
options ndots:5

12345678910111213141516171819202122
```

# 11 安装metrics-server

## 11.1 解压kubernet二进制包获取metrics-server

```
下载metrics-server
wget https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.3.6/components.yaml
12
```

## 11.2 修改配置文件

```
imagePullPolicy: IfNotPresent

- --cert-dir=/tmp
- --kubelet-insecure-tls
- --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
- --secure-port=4443

1234567
```

## 11.3 在Node上下载镜像文件

```
在Node1上下载镜像文件：
docker pull bluersw/metrics-server-amd64:v0.3.6
docker tag bluersw/metrics-server-amd64:v0.3.6 k8s.gcr.io/metrics-server-amd64:v0.3.6  
123
```

## 11.4 验证metrics-server

```
[root@k8s-master01 metrics-server]#  kubectl top node
NAME            CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%   
192.168.10.14   30m          3%     534Mi           61%       
192.168.10.15   27m          2%     524Mi           60%       

12345
```

![img](https://imgconvert.csdnimg.cn/aHR0cHM6Ly9kZXZvcHN0YWNrLmNuL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDIwLzA0LzNkMDhhNDk3YzNiYzNmZWI5MTg3MmU4ZmE3OWIwMTc1LnBuZw?x-oss-process=image/format,png)

![img](https://imgconvert.csdnimg.cn/aHR0cHM6Ly9kZXZvcHN0YWNrLmNuL3dwLWNvbnRlbnQvdXBsb2Fkcy8yMDIwLzA0LzFhOTI0ZjA5YWE5NmY2YTc4MzcwOWMwNTlkODgyMzE0LnBuZw?x-oss-process=image/format,png)

# 遇到的问题

## 1.kubectl 获取不到集群信息

```
[root@k8s-master02 ~]# kubectl get cs
NAME                 AGE
scheduler            <unknown>
controller-manager   <unknown>
etcd-1               <unknown>
etcd-0               <unknown>
etcd-2               <unknown>
[root@k8s-master02 ~]# 


可能是1.16版本里的kubectl有不兼容问题，换为1.14的kubectl问题解决。
1234567891011
```

## 2.kubelet Failed to connect to apiserver

```
tail -100f messages
报错Failed to connect to apiserver: Get https://192.168.10.16:8443/healthz?timeout=1s: x509: certificate is valid for 127.0.0.1, 192.168.10.11, 192.168.10.12, 192.168.10.13, 10.254.0.1, not 192.168.10.16
开始的时候vip地址没有加入证书里面


12345
```

## 3.Error from server (Forbidden): Forbidden (user=system:anonymous, verb=get, resource=nodes, subresource=proxy)

```
查看：
 kubectl logs calico-kube-controllers-5cc7b68d7c-z52sm  -nkube-system

解决办法
绑定一个cluster-admin的权限
kubectl create clusterrolebinding system:anonymous   --clusterrole=cluster-admin   --user=system:anonymous

1234567
```

## 4.Kubenates RunAsUser被禁止

```
查看日志
Apr 22 16:06:08 k8s-master01 kube-controller-manager: I0422 16:06:08.769311   90889 event.go:255] Event(v1.ObjectReference{Kind:"ReplicaSet", Namespace:"kubernetes-dashboard", Name:"dashboard-metrics-scraper-76585494d8", UID:"65198225-3ddd-4231-8e17-6aee46a876ec", APIVersion:"apps/v1", ResourceVersion:"255999", FieldPath:""}): type: 'Warning' reason: 'FailedCreate' Error creating: pods "dashboard-metrics-scraper-76585494d8-sflwv" is forbidden: SecurityContext.RunAsUser is forbidden

解决方法
cd /etc/kubernetes
cp apiserver.conf apiserver.conf.bak
vim apiserver.conf
找到SecurityContextDeny关键字并将其删除。
systemctl restart kube-apiserver
123456789
```

## 5.部署metrics-server时遇到的问题

```
[root@k8s-master01 metrics-server]#  kubectl top node
Error from server (ServiceUnavailable): the server is currently unable to handle the request (get nodes.metrics.k8s.io)
查看日志如下
[root@k8s-master01 metrics-server]# kubectl logs -n kube-system metrics-server-67769dfd46-87sp9
I0427 11:06:34.864607       1 serving.go:312] Generated self-signed cert (/tmp/apiserver.crt, /tmp/apiserver.key)
W0427 11:06:35.463632       1 authentication.go:296] Cluster doesn't provide requestheader-client-ca-file in configmap/extension-apiserver-authentication in kube-system, so request-header client certificate authentication won't work.
I0427 11:06:35.480941       1 secure_serving.go:116] Serving securely on [::]:4443

解决方法：
在kube-apiserver选项中添加如下配置选项：
--enable-aggregator-routing=true
```