- [Kubernetes&Docker集群部署](https://www.cnblogs.com/HOsystem/p/15821022.html)

## 集群环境搭建

搭建kubernetes的集群环境

### 环境规划

#### 集群类型

kubernetes集群大体上分为两类：**一主多从**和**多主多从**。

- 一主多从：一台Master节点和多台Node节点，搭建简单，但是有单机故障风险，适合用于测试环境
- 多主多从：多台Master节点和多台Node节点，搭建麻烦，安全性高，适合用于生产环境

![image-20220115001527682](https://gitee.com/HOSystem/learning-notes/raw/master/k8s/2%E3%80%81Kubernetes%E9%9B%86%E7%BE%A4%E9%83%A8%E7%BD%B2/assets/image-20220115001527682.png)

#### 安装方式

kubernetes有多种部署方式，目前主流的方式有kubeadm、minikube、二进制包

- minikube：一个用于快速搭建单节点kubernetes的工具
- kubeadm：一个用于快速搭建kubernetes集群的工具
- 二进制包 ：从官网下载每个组件的二进制包，依次去安装，此方式对于理解kubernetes组件更加有效

#### 主机规划

这里推荐使用`Centos7.6.1810`的系统，其它系统可能会出现意想不到的问题。如使用`Centos7.3`的系统会出现 `网络同步Chronyd` 启动不成功问题，Centos7.x可以通过`yum update`来升级内核。

| 作用       | IP地址      | 操作系统       | 配置      |
| ---------- | ----------- | -------------- | --------- |
| k8s-Master | 10.80.6.120 | Centos7.6.1810 | 8H/8G 50G |
| k8s-Node1  | 10.80.6.121 | Centos7.6.1810 | 8H/8G 50G |
| k8s-Node2  | 10.80.6.122 | Centos7.6.1810 | 8H/8G 50G |

### 环境搭建

本次环境搭建需要安装四台Centos服务器（一主三从），然后在每台服务器中分别安装docker（19.03.5），kubeadm（1.18.8）、kubelet（1.18.8）、kubectl（1.18.8）程序。

可能通过kubectl查看版本时会变成1.18.20 并不影响使用。1.18.20一样也适配docker（19.03.5）

如果需要别的版本可以自行查询K8s和Docker版本的适配。

#### 主机安装

安装虚拟机过程中注意下面选项的设置：

- 操作系统环境：CPU（2H）    内存（8G）   硬盘（30G）
- 语言选择：中文简体
- 软件选择：基础设施服务器
- 分区选择：自动分区
- 网络配置：按照下面配置网路地址信息

```shell
# 要查看自己本机的 IP地址(IPADDR)、掩码地址(NETMASK)、网关(GATEWAY)、DNS地址 然后填上去
$ vi /etc/sysconfig/network-scripts/ifcfg-ensxxx
BOOTPROTO=static
ONBOOT=yes
IPADDR=10.80.6.120
NETWASK=255.255.0.0
GATEWAY=10.80.6.1
DNS1=114.114.114.114
DNS2=10.80.6.1
DNS3=8.8.8.8
```

- 主机名设置：按照下面信息设置主机名

```shell
master$ hostnamectl set-hostname k8s-master #master节点: k8s-master
node1$ hostnamectl set-hostname k8s-node1 #node1节点: k8s-node1
node2$ hostnamectl set-hostname k8s-node2 #node2节点: k8s-node2
```

#### 环境初始化

- 更换镜像源

```shell
#创建sh脚本,将以下内容粘贴到reposintall.sh里
$ vi reposinstall.sh
#!/bin/bash
cd /etc/yum.repos.d/
mkdir repo_bak
mv *.repo repo_bak/
curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
yum clean all
yum makecache
yum install -y epel-release.noarch
yum clean all
yum makecache
yum repolist all

$ sh reposinstall.sh
.......
```

- 检查操作系统的版本

```shell
# 此方式下安装kubernetes集群要求Centos版本要在7.5或之上
$ cat /etc/redhat-release
CentOS Linux release 7.6.1810 (Core) 

# 若Centos版本不在7.5或之上 通过yum更新
$ yum update
```

- 主机名解析

为了方便后面集群节点间的直接调用，在这配置一下主机名解析，企业中推荐使用内部DNS服务器。

```shell
# 主机名成解析 编辑四台服务器的/etc/hosts文件，添加下面内容
# 注意：主机名不能带下划线，只能带中划线
$ vi /etc/hosts
10.80.6.120 k8s-master
10.80.6.121 k8s-node1
10.80.6.122 k8s-node2
```

- 时间同步（待定检测必要性）

kubernetes要求集群中的节点时间必须精确一致，这里直接使用chronyd服务从网络同步时间；也可以使用`网络授时NTP`。

企业中建议配置内部的时间同步服务器。

```shell
#若chrony不存在,使用yum安装
$ yum install -y chrony

# 启动chronyd服务 若启动出现错误 查看问题汇总中问题10
$ systemctl start chronyd
# 设置chronyd服务开机自启
$ systemctl enable chronyd
# chronyd服务启动稍等几秒钟，就可以使用date命令验证时间了
$ date
```

- 禁用iptables和firewalld服务

kubernetes和docker在运行中会产生大量的iptables规则，为了不让系统规则跟它们混淆，直接关闭系统的规则。

```shell
# 1 关闭firewalld服务
$ systemctl stop firewalld
$ systemctl disable firewalld
# 2 关闭iptables服务
$ systemctl stop iptables
$ systemctl disable iptables
```

- 禁用selinux

selinux是linux系统下的一个安全服务，如果不关闭它，在安装集群中会产生各种各样的奇葩问题。

```shell
# 编辑 /etc/selinux/config 文件，修改SELINUX的值为disabled
# 注意修改完毕之后需要重启linux服务
$ vi /etc/selinux/config
SELINUX=disabled
```

- 禁用swap分区

swap分区指的是虚拟内存分区，它的作用是在物理内存使用完之后，将磁盘空间虚拟成内存来使用。

启用swap设备会对系统的性能产生非常负面的影响，因此kubernetes要求每个节点都要禁用swap设备。

但是如果因为某些原因确实不能关闭swap分区，就需要在集群安装过程中通过明确的参数进行配置说明。

```shell
# 编辑分区配置文件/etc/fstab，注释掉有 `swap`分区 字样的一行
# 注意修改完毕之后需要重启linux服务
$ vi /etc/fstab
# /dev/mapper/centos-swap swap                      swap    defaults        0 0
```

- 修改linux的内核参数

```shell
# 修改linux的内核参数，添加网桥过滤和地址转发功能
# 出现Can't open file for writing查看问题九
# 编辑/etc/sysctl.d/kubernetes.conf文件，添加如下配置:
$ sudo vi /ect/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1

# 重新加载配置
$ sysctl -p

# 加载网桥过滤模块
$ modprobe br_netfilter

# 查看网桥过滤模块是否加载成功
$ lsmod | grep br_netfilter
```

![image-20220118143005305](https://gitee.com/HOSystem/learning-notes/raw/master/k8s/2%E3%80%81Kubernetes%E9%9B%86%E7%BE%A4%E9%83%A8%E7%BD%B2/assets/image-20220118143005305.png)

- 配置ipvs功能

在kubernetes中service有两种代理模型，一种是基于iptables的，一种是基于ipvs的。

两者比较的话，ipvs的性能明显要高一些，但是如果要使用它，需要手动载入ipvs模块。

```shell
# 1 安装ipset和ipvsadm
$ yum install ipset ipvsadm -y

# 2 添加需要加载的模块写入脚本文件
$ cat <<EOF >  /etc/sysconfig/modules/ipvs.modules
#!/bin/bash
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack_ipv4
EOF

# 3 为脚本文件添加执行权限
$ chmod +x /etc/sysconfig/modules/ipvs.modules

# 4 执行脚本文件
$ /bin/bash /etc/sysconfig/modules/ipvs.modules

# 5 查看对应的模块是否加载成功
$ lsmod | grep -e ip_vs -e nf_conntrack_ipv4
```

![image-20220118123654547](https://gitee.com/HOSystem/learning-notes/raw/master/k8s/2%E3%80%81Kubernetes%E9%9B%86%E7%BE%A4%E9%83%A8%E7%BD%B2/assets/image-20220118123654547.png)

- 重启服务器

上面步骤完成之后，需要重新启动linux系统。

```shell
$ reboot
```

#### 安装docker

```shell
# 1 切换镜像源
$ wget https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo -O /etc/yum.repos.d/docker-ce.repo

# 2 查看当前镜像源中支持的docker版本
$ yum list docker-ce --showduplicates

# 3 安装特定版本的docker-ce
# 必须指定--setopt=obsoletes=0，否则yum会自动安装更高版本
# 安装其它版本号 版本号可通过 yum list docker-ce --showduplicates查看
# 如果想安装其它版本 一定要docker-ce-xxx 和 docker-ce-cli-xxx containerd.io 这三个一个都不能缺少
$ yum install --setopt=obsoletes=0 docker-ce-19.03.5 docker-ce-cli-19.03.5 containerd.io -y

# 4 添加一个配置文件
# Docker在默认情况下使用的Cgroup Driver为cgroupfs，而kubernetes推荐使用systemd来代替cgroupfs
$ mkdir /etc/docker
$ cat <<EOF >  /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "registry-mirrors": ["https://kn0t2bca.mirror.aliyuncs.com"]
}
EOF

# 5 启动docker
$ systemctl restart docker
$ systemctl enable docker

# 6 检查docker状态和版本
$ docker --version
Docker version 19.03.5, build 633a0ea

# 7 查看镜像加速是否成功 
# 出现xxx.alixxx就成功
$ docker info
Registry Mirrors:
    https://xxx.mirror.aliyuncs.com
```

#### 安装kubernetes组件

```shell
# 由于kubernetes的镜像源在国外，速度比较慢，这里切换成国内的镜像源
# 1.编辑/etc/yum.repos.d/kubernetes.repo，添加下面的配置 
$ vi /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=http://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=http://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
       http://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg

# 2.查看当前镜像源中支持的docker版本
# 也可通过 http://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/Packages/   查看版本信息
$ yum list kubectl --showduplicates



# 3.安装kubeadm、kubelet和kubectl
# kubernetes1.18.8和docker19.03.5适配
$ yum install --setopt=obsoletes=0 kubeadm-1.18.8-0 kubelet-1.18.8-0 kubectl-1.18.8-0 -y

# 配置kubelet的cgroup
# 4.编辑/etc/sysconfig/kubelet，添加下面的配置
$ vi /etc/sysconfig/kubelet
KUBELET_CGROUP_ARGS="--cgroup-driver=systemd"
KUBE_PROXY_MODE="ipvs"

# 5.设置kubelet开机自启
$ systemctl enable kubelet
```

#### 准备集群镜像

```shell
# 在安装kubernetes集群之前，必须要提前准备好集群需要的镜像，所需镜像可以通过下面命令查看
$ kubeadm config images list
k8s.gcr.io/kube-apiserver:v1.18.20
k8s.gcr.io/kube-controller-manager:v1.18.20
k8s.gcr.io/kube-scheduler:v1.18.20
k8s.gcr.io/kube-proxy:v1.18.20
k8s.gcr.io/pause:3.2
k8s.gcr.io/etcd:3.4.3-0
k8s.gcr.io/coredns:1.6.7


# 下载镜像
# 此镜像在kubernetes的仓库中,由于网络原因,无法连接，下面提供了一种替代方案
$ images=(
    kube-apiserver:v1.18.20
    kube-controller-manager:v1.18.20
    kube-scheduler:v1.18.20
    kube-proxy:v1.18.20
    pause:3.2
    etcd:3.4.3-0
    coredns:1.6.7
)

$ for imageName in ${images[@]} ; do
	docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/$imageName
	docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/$imageName 		k8s.gcr.io/$imageName
	docker rmi registry.cn-hangzhou.aliyuncs.com/google_containers/$imageName
done
```

#### 集群初始化

下面开始对集群进行初始化，并将node节点加入到集群中

> 下面的操作只需要在`master`节点上执行即可

```shell
#1.查看kubectl 版本信息
$ kubectl version

# apiserver-advertise-address 为k8s-master的ip地址 
# image-repository 由于默认拉取镜像地址k8s.gcr.io国内无法访问，这里指定阿里云镜像仓库地址。
# 该操作可能会等待时间较长 可通过docker images 查看镜像的pull 大致了解镜像拉取情况
# 出现 Kubernetes control-plane has initialized successfully! 才算成功
# 若出现错误,则查看问题汇总
# 将--apiserver-advertise-address=192.168.188.128 使用 --apiserver-advertise-address=$(ip addr|grep ens|awk '{print $2}'|grep '/'| head -c-4)替代
#2.创建集群
$ kubeadm init \
	--kubernetes-version=v1.18.20 \
    --pod-network-cidr=10.244.0.0/16 \
    --service-cidr=10.96.0.0/12 \
    --apiserver-advertise-address=本机的IP地址
#参数说明
--kubernetes-version=v1.18.20: kubernetes版本 可通过kubectl version 查看版本信息
--pod-network-cidr=10.244.0.0/16: pod网关 可默认
--service-cidr=10.96.0.0/12: server网络 可默认
--apiserver-advertise-address=10.80.6.120: master的ip地址

.....
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 10.80.6.120:6443 --token 8xfehq.bbghn94cpaowmnjb \
    --discovery-token-ca-cert-hash sha256:e51a57f9e4f0205c646a81a0cef402b11ec2f1a82c6ea5a5f0cac8c0a9f5b9c1 
```

使用kubectl工具：

```shell
# 这一段为上面 Your Kubernetes control-plane has initialized successfully! 后面的内容
#3.创建必要文件
$ mkdir -p $HOME/.kube
$ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
$ sudo chown $(id -u):$(id -g) $HOME/.kube/config

#4.获取节点信息
$ kubectl get nodes
NAME         STATUS     ROLES    AGE     VERSION
k8s-master   Ready    master   13h   v1.18.8
```

> 下面的操作只需要在`node`节点上执行即可

```shell
# 将node节点加入集群
$ kubeadm join 10.80.6.120:6443 --token 8xfehq.bbghn94cpaowmnjb \
    --discovery-token-ca-cert-hash sha256:e51a57f9e4f0205c646a81a0cef402b11ec2f1a82c6ea5a5f0cac8c0a9f5b9c1 
	
# 查看集群状态 此时的集群状态为NotReady，这是因为还没有配置网络插件
$ kubectl get nodes
NAME     STATUS     ROLES    AGE     VERSION
k8s-master   Ready    master   13h   v1.18.8
k8s-node1    Ready    <none>   13h   v1.18.8
k8s-node2    Ready    <none>   13h   v1.18.8
```

#### 安装网络插件

kubernetes支持多种网络插件，比如flannel、calico、canal等等，任选一种使用即可，本次选择flannel。

这一步操作是将`kubectl get nodes`中`noteady`状态变为`ready`状态的过程。

> 下面操作依旧只在`master`节点执行即可，插件使用的是DaemonSet的控制器，它会在每个节点上都运行

这里存在两种方式，`方式一`和`方式二`，若kube-flannel.yml下载失败，可通过复制`kube-flannel.yml`并在linux中创建粘贴即可。

方式一：

```shell
# 获取fannel的配置文件
# 修改文件中quay.io仓库为quay-mirror.qiniu.com
# 这里有时候会下载失败
$ wget https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
或
$ vi kube-fannel.yml #kube-flannel.yml文件在下面已经给出

# 使用配置文件启动fannel
$ kubectl apply -f kube-flannel.yml

# 稍等片刻，再次查看集群节点的状态
# 可能需要等待的时间较长,请耐心等待。也可通过切换到notready 节点中使用docker ps 查看镜像启动信息
# 若很长时间都是notready可通过kubectl查看日志
$ kubectl get nodes
NAME     STATUS   ROLES    AGE     VERSION
k8s-master   Ready    master   13h   v1.18.8
k8s-node1    Ready    <none>   13h   v1.18.8
k8s-node2    Ready    <none>   13h   v1.18.8
```

- `kube-flannel.yml`文件

```yaml
---
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: psp.flannel.unprivileged
  annotations:
    seccomp.security.alpha.kubernetes.io/allowedProfileNames: docker/default
    seccomp.security.alpha.kubernetes.io/defaultProfileName: docker/default
    apparmor.security.beta.kubernetes.io/allowedProfileNames: runtime/default
    apparmor.security.beta.kubernetes.io/defaultProfileName: runtime/default
spec:
  privileged: false
  volumes:
  - configMap
  - secret
  - emptyDir
  - hostPath
  allowedHostPaths:
  - pathPrefix: "/etc/cni/net.d"
  - pathPrefix: "/etc/kube-flannel"
  - pathPrefix: "/run/flannel"
  readOnlyRootFilesystem: false
  # Users and groups
  runAsUser:
    rule: RunAsAny
  supplementalGroups:
    rule: RunAsAny
  fsGroup:
    rule: RunAsAny
  # Privilege Escalation
  allowPrivilegeEscalation: false
  defaultAllowPrivilegeEscalation: false
  # Capabilities
  allowedCapabilities: ['NET_ADMIN', 'NET_RAW']
  defaultAddCapabilities: []
  requiredDropCapabilities: []
  # Host namespaces
  hostPID: false
  hostIPC: false
  hostNetwork: true
  hostPorts:
  - min: 0
    max: 65535
  # SELinux
  seLinux:
    # SELinux is unused in CaaSP
    rule: 'RunAsAny'
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: flannel
rules:
- apiGroups: ['extensions']
  resources: ['podsecuritypolicies']
  verbs: ['use']
  resourceNames: ['psp.flannel.unprivileged']
- apiGroups:
  - ""
  resources:
  - pods
  verbs:
  - get
- apiGroups:
  - ""
  resources:
  - nodes
  verbs:
  - list
  - watch
- apiGroups:
  - ""
  resources:
  - nodes/status
  verbs:
  - patch
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: flannel
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: flannel
subjects:
- kind: ServiceAccount
  name: flannel
  namespace: kube-system
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: flannel
  namespace: kube-system
---
kind: ConfigMap
apiVersion: v1
metadata:
  name: kube-flannel-cfg
  namespace: kube-system
  labels:
    tier: node
    app: flannel
data:
  cni-conf.json: |
    {
      "name": "cbr0",
      "cniVersion": "0.3.1",
      "plugins": [
        {
          "type": "flannel",
          "delegate": {
            "hairpinMode": true,
            "isDefaultGateway": true
          }
        },
        {
          "type": "portmap",
          "capabilities": {
            "portMappings": true
          }
        }
      ]
    }
  net-conf.json: |
    {
      "Network": "10.244.0.0/16",
      "Backend": {
        "Type": "vxlan"
      }
    }
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: kube-flannel-ds
  namespace: kube-system
  labels:
    tier: node
    app: flannel
spec:
  selector:
    matchLabels:
      app: flannel
  template:
    metadata:
      labels:
        tier: node
        app: flannel
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: kubernetes.io/os
                operator: In
                values:
                - linux
      hostNetwork: true
      priorityClassName: system-node-critical
      tolerations:
      - operator: Exists
        effect: NoSchedule
      serviceAccountName: flannel
      initContainers:
      - name: install-cni
        image: quay.io/coreos/flannel:v0.14.0
        command:
        - cp
        args:
        - -f
        - /etc/kube-flannel/cni-conf.json
        - /etc/cni/net.d/10-flannel.conflist
        volumeMounts:
        - name: cni
          mountPath: /etc/cni/net.d
        - name: flannel-cfg
          mountPath: /etc/kube-flannel/
      containers:
      - name: kube-flannel
        image: quay.io/coreos/flannel:v0.14.0
        command:
        - /opt/bin/flanneld
        args:
        - --ip-masq
        - --kube-subnet-mgr
        resources:
          requests:
            cpu: "100m"
            memory: "50Mi"
          limits:
            cpu: "100m"
            memory: "50Mi"
        securityContext:
          privileged: false
          capabilities:
            add: ["NET_ADMIN", "NET_RAW"]
        env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        volumeMounts:
        - name: run
          mountPath: /run/flannel
        - name: flannel-cfg
          mountPath: /etc/kube-flannel/
      volumes:
      - name: run
        hostPath:
          path: /run/flannel
      - name: cni
        hostPath:
          path: /etc/cni/net.d
      - name: flannel-cfg
        configMap:
          name: kube-flannel-cfg
```

方式二：

```shell
$ kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# 稍等片刻，再次查看集群节点的状态
# 可能需要等待的时间较长,请耐心等待。也可通过切换到notready 节点中使用docker ps 查看镜像启动信息
# 若很长时间都是notready可通过kubectl查看日志
$ kubectl get nodes
NAME     STATUS   ROLES    AGE     VERSION
k8s-master   Ready    master   13h   v1.18.8
k8s-node1    Ready    <none>   13h   v1.18.8
k8s-node2    Ready    <none>   13h   v1.18.8
```

至此，kubernetes的集群环境搭建完成。

### 服务部署

所有操作都是通过master节点操作，而不需要到node节点上操作。

```shell
# 部署nginx
$ kubectl create deployment nginx --image=nginx:1.14-alpine
deployment.apps/nginx created

# 暴露端口
$ kubectl expose deployment nginx --port=80 --type=NodePort
service/nginx exposed

# 查看服务状态
$ kubectl get pods,service
NAME                         READY   STATUS    RESTARTS   AGE
pod/nginx-55f8fd7cfc-wvdxq   1/1     Running   0          30m

NAME                 TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
service/kubernetes   ClusterIP   10.96.0.1      <none>        443/TCP        35m
service/nginx        NodePort    10.107.52.75   <none>        80:30983/TCP   30m


# 4 最后在电脑上访问下部署的nginx服务
```

![image-20220118202200835](https://gitee.com/HOSystem/learning-notes/raw/master/k8s/2%E3%80%81Kubernetes%E9%9B%86%E7%BE%A4%E9%83%A8%E7%BD%B2/assets/image-20220118202200835.png)

## 问题汇总

### 问题一：

**问题描述：**

在K8S-Master中执行 `kubeadm init...`出现以下错误

```markdown
W0112 22:25:15.385511   18569 configset.go:202] WARNING: kubeadm cannot validate component configs for API groups [kubelet.config.k8s.io kubeproxy.config.k8s.io]
[init] Using Kubernetes version: v1.18.0
[preflight] Running pre-flight checks
	[WARNING IsDockerSystemdCheck]: detected "cgroupfs" as the Docker cgroup driver. The recommended driver is "systemd". Please follow the guide at https://kubernetes.io/docs/setup/cri/
error execution phase preflight: [preflight] Some fatal errors occurred:
	[ERROR Swap]: running with swap on is not supported. Please disable swap
[preflight] If you know what you are doing, you can make a check non-fatal with `--ignore-preflight-errors=...`
To see the stack trace of this error execute with --v=5 or higher
```

**问题原因：**

**问题解决：**

```shell
#1.修改docker.service
$ vi /usr/lib/systemd/system/docker.service
#修改成如下内容
ExecStart=/usr/bin/dockerd --exec-opt native.cgroupdriver=systemd

#2.重启docker
$ systemctl daemon-reload && systemctl restart docker
```

### 问题二：

**问题描述：**

在K8S-Master中执行 `kubeadm init...`出现以下错误

```markdown
W0112 22:28:21.715514   18853 configset.go:202] WARNING: kubeadm cannot validate component configs for API groups [kubelet.config.k8s.io kubeproxy.config.k8s.io]
[init] Using Kubernetes version: v1.18.0
[preflight] Running pre-flight checks
error execution phase preflight: [preflight] Some fatal errors occurred:
	[ERROR Swap]: running with swap on is not supported. Please disable swap
[preflight] If you know what you are doing, you can make a check non-fatal with `--ignore-preflight-errors=...`
To see the stack trace of this error execute with --v=5 or higher
```

**问题原因：**

running with swap on is not supported. Please disable swap 关闭swap;

**问题解决：**

```shell
$ sed -ri 's/.*swap.*/#&/' /etc/fstab
```

### 问题三：

**问题描述：**

` for imageName in ${images[@]} ; do`安装kubernetes镜像时，docker出现卡住的现象。出现以下问题

```shell
597de8ba0c30: Already exists 
3f0663684f29: Pull complete 
e1f7f878905c: Pull complete 
3029977cf65d: Pulling fs layer 
```

**问题原因：**

可能时网络问题，可能时其它原因。

**问题解决：**

- 重启docker

```shell
$ systemctl restart docker
```

- 删除docker的缓存；docker拉取的的镜像是存放在/var/lib/docker/overlay2，缓存是在/var/lib/docker/tmp，但是我都删掉反而报错有其中有的东西不能删；

```shell
//TODO 待定
```

### 问题四：

**问题描述：**

在master执行`kubeadm init --kubernetes-version=xxx..`命令后,出现以下错误

```shell
Unable to connect to the server: x509: certificate signed by unknown authority
```

**问题原因：**

删除集群然后重新创建也算是一个常规的操作，如果你在执行 `kubeadm reset`命令后没有删除创建的 `$HOME/.kube`目录，重新创建集群就会出现这个问题！

**问题解决：**

```shell
# 在执行这几个命令前先执行rm -rf $HOME/.kube命令删除这个目录
$ mkdir -p $HOME/.kube
$ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
$ sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### 问题五：

**问题描述：**

在子节点执行kubeadm join命令后返回 `error uploading crisocket: timed out waiting for the condition`

```markdown
[kubelet-check] The HTTP call equal to 'curl -sSL http://localhost:10248/healthz' failed with error: Get http://localhost:10248/healthz: dial tcp [::1]:10248: connect: connection refused.

error execution phase kubelet-start: error uploading crisocket: timed out waiting for the condition
To see the stack trace of this error execute with --v=5 or higher
```

**问题原因：**

**问题解决：**

```shell
$ swapoff -a 
$ kubeadm reset
$ systemctl daemon-reload
$ systemctl restart kubelet
$ iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X
```

以上执行完成后再执行加入子结点的操作：

```
kubeadm join 10.80.6.120:6443 --token f4ls6h.ogl776zklkoeqei9 \
    --discovery-token-ca-cert-hash sha256:96ec68a8116024da03a763c0af61fbd933615d93949d9c3b01c952af0193f149 
```

### 问题六：

**问题描述：**

在子节点执行kubeadm join命令后返回 `/etc/kubernetes/kubelet.conf already exists`等问题。

```markdown
error execution phase preflight: [preflight] Some fatal errors occurred:
	[ERROR FileAvailable--etc-kubernetes-kubelet.conf]: /etc/kubernetes/kubelet.conf already exists
	[ERROR FileAvailable--etc-kubernetes-pki-ca.crt]: /etc/kubernetes/pki/ca.crt already exists
```

**问题原因：**

原来旧的配置文件都存在了，所以无法kubeadm join到master中。

**问题解决：**

把`/etc/kubernetes/kubelet.conf`和`/etc/kubernetes/pki/ca.crt`删除即可

```shell
$ rm -f /etc/kubernetes/kubelet.conf /etc/kubernetes/pki/ca.crt
```

### 问题七：

**问题描述：**

安装k8s时出现以下错误，

```shell
could not convert cfg to an internal cfg: nodeRegistration.name: Invalid value: "k8s_master": a DNS-1123 subdomain must consist of lower case alphanumeric characters, '-' or '.', and must start and end with an alphanumeric character (e.g. 'example.com', regex used for validation is '[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*')
```

**问题原因：**

这是因为主机名不能带下划线，只能带中划线。

**问题解决：**

```shell
将主机名的 下划线`_` 改为 中划线`-` 即可
```

### 问题八：

**问题描述：**

修改linux的内核参数时，保存`/etc/sysctl.d/kubernetes.conf`文件时，出现`Can't open file for writing`错误

![image-20220118181145091](https://gitee.com/HOSystem/learning-notes/raw/master/k8s/2%E3%80%81Kubernetes%E9%9B%86%E7%BE%A4%E9%83%A8%E7%BD%B2/assets/image-20220118181145091.png)

**问题原因：**

可能一个原因是权限不够，使用root解决

**问题解决：**

```shell
$ su root
$ vi /etc/sysctl.d/kubernetes.conf
```

### 问题九：

**问题描述：**

通过`yum -y install chrony`后，使用`systemctl start chronyd`时出现`Job for chronyd.service failed because the control process exited with  error code. See "systemctl status chronyd.service" and "journalctl -xe"  for details.`

**问题原因：**

使用  yum -y install chrony命令，自动安装了最新版的chrony服务（配套7.7内核）。由于我的系统是7.3，可能不兼容高版本的chrony服务，导致服务启动失败。（个人理解猜测）

**问题解决：**

- 使用yum -y update。将系统版本升级至最新即可解决。（我使用的此方法）
- 使用CentOS 7.3 yum源，安装兼容7.3的Chrony版本。

### 问题十：

**问题描述：**

使用wget下载东西时，出现`-bash: wget: command not found`错误

**问题原因：**

wget没有安装

**问题解决：**

通过yum安装wget

```shell
$ yum install -y wget
```

## 参考文档

[中文官网 - 点我传送](https://kubernetes.io/zh)

[中文社区 - 点我传送](https://www.kubernetes.org.cn/)

[docker-repos-Aliyun - 点我传送](https://developer.aliyun.com/mirror/docker-ce?spm=a2c6h.13651102.0.0.73741b111vL5yW)

[Centos7安装Docker&镜像加速 - 点我传送](https://www.cnblogs.com/HOsystem/p/14463699.html)

[kubernetes-repos-Aliyun - 点我传送](https://developer.aliyun.com/mirror/kubernetes?spm=a2c6h.13651102.0.0.73741b111vL5yW)

[K8Schangelog - 点我传送](https://github.com/kubernetes/kubernetes/tree/master/CHANGELOG)