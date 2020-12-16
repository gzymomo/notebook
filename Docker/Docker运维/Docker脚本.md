[TOC]

[博客园：冰河团队：【K8S】基于Docker+K8S+GitLab/SVN+Jenkins+Harbor搭建持续集成交付环境（环境搭建篇）](https://www.cnblogs.com/binghe001/p/13109669.html)

# 一、在所有服务器上创建install_docker.sh脚本
```bash
#使用阿里云镜像中心
export REGISTRY_MIRROR=https://registry.cn-hangzhou.aliyuncs.com
#安装docker环境
yum install -y yum-utils device-mapper-persistent-data lvm2
#配置Docker的yum源
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
#安装容器插件
dnf install https://mirrors.aliyun.com/docker-ce/linux/centos/7/x86_64/stable/Packages/containerd.io-1.2.13-3.1.el7.x86_64.rpm
#指定安装docker 19.03.8版本
yum install -y docker-ce-19.03.8 docker-ce-cli-19.03.8
#设置Docker开机启动
systemctl enable docker.service
#启动Docker
systemctl start docker.service
#查看Docker版本
docker version
```

在每台服务器上为install_docker.sh脚本赋予可执行权限，并执行脚本，如下所示。
```bash
# 赋予install_docker.sh脚本可执行权限
chmod a+x ./install_docker.sh
# 执行install_docker.sh脚本
./install_docker.sh
```

# 二、安装docker-compose
Compose 是用于定义和运行多容器 Docker 应用程序的工具。通过 Compose，您可以使用 YML 文件来配置应用程序需要的所有服务。然后，使用一个命令，就可以从 YML 文件配置中创建并启动所有服务。

注意：在每台服务器上安装docker-compose
## 2.1 下载docker-compose文件
```bash
#下载并安装docker-compose
curl -L https://github.com/docker/compose/releases/download/1.25.5/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
```

## 2.2 为docker-compose文件赋予可执行权限
```bash
#赋予docker-compose可执行权限
chmod a+x /usr/local/bin/docker-compose
```

## 2.3 查看docker-compose版本
```bash
#查看docker-compose版本
[root@binghe ~]# docker-compose version
docker-compose version 1.25.5, build 8a1c60f6
docker-py version: 4.1.0
CPython version: 3.7.5
OpenSSL version: OpenSSL 1.1.0l  10 Sep 2019
```

# 三、安装K8S集群环境
Kubernetes是一个开源的，用于管理云平台中多个主机上的容器化的应用，Kubernetes的目标是让部署容器化的应用简单并且高效（powerful）,Kubernetes提供了应用部署，规划，更新，维护的一种机制。
## 3.1 安装K8S基础环境
在所有服务器上创建install_k8s.sh脚本文件，脚本文件的内容如下所示。
```bash
#################配置阿里云镜像加速器开始########################
mkdir -p /etc/docker
tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://zz3sblpi.mirror.aliyuncs.com"]
}
EOF
systemctl daemon-reload
systemctl restart docker
######################配置阿里云镜像加速器结束#########################
#安装nfs-utils
yum install -y nfs-utils
#安装wget软件下载命令
yum install -y wget

#启动nfs-server
systemctl start nfs-server
#配置nfs-server开机自启动
systemctl enable nfs-server

#关闭防火墙
systemctl stop firewalld
#取消防火墙开机自启动
systemctl disable firewalld

#关闭SeLinux
setenforce 0
sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config

# 关闭 swap
swapoff -a
yes | cp /etc/fstab /etc/fstab_bak
cat /etc/fstab_bak |grep -v swap > /etc/fstab

############################修改 /etc/sysctl.conf开始###########################
# 如果有配置，则修改
sed -i "s#^net.ipv4.ip_forward.*#net.ipv4.ip_forward=1#g"  /etc/sysctl.conf
sed -i "s#^net.bridge.bridge-nf-call-ip6tables.*#net.bridge.bridge-nf-call-ip6tables=1#g"  /etc/sysctl.conf
sed -i "s#^net.bridge.bridge-nf-call-iptables.*#net.bridge.bridge-nf-call-iptables=1#g"  /etc/sysctl.conf
sed -i "s#^net.ipv6.conf.all.disable_ipv6.*#net.ipv6.conf.all.disable_ipv6=1#g"  /etc/sysctl.conf
sed -i "s#^net.ipv6.conf.default.disable_ipv6.*#net.ipv6.conf.default.disable_ipv6=1#g"  /etc/sysctl.conf
sed -i "s#^net.ipv6.conf.lo.disable_ipv6.*#net.ipv6.conf.lo.disable_ipv6=1#g"  /etc/sysctl.conf
sed -i "s#^net.ipv6.conf.all.forwarding.*#net.ipv6.conf.all.forwarding=1#g"  /etc/sysctl.conf
# 可能没有，追加
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
echo "net.bridge.bridge-nf-call-ip6tables = 1" >> /etc/sysctl.conf
echo "net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.all.forwarding = 1"  >> /etc/sysctl.conf
############################修改 /etc/sysctl.conf结束###########################
# 执行命令使修改后的/etc/sysctl.conf文件生效
sysctl -p

################# 配置K8S的yum源开始#############################
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=http://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=http://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
       http://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
################# 配置K8S的yum源结束#############################

# 卸载旧版本K8S
yum remove -y kubelet kubeadm kubectl

# 安装kubelet、kubeadm、kubectl，这里我安装的是1.18.2版本，你也可以安装1.17.2版本
yum install -y kubelet-1.18.2 kubeadm-1.18.2 kubectl-1.18.2

# 修改docker Cgroup Driver为systemd
# # 将/usr/lib/systemd/system/docker.service文件中的这一行 ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock
# # 修改为 ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock --exec-opt native.cgroupdriver=systemd
# 如果不修改，在添加 worker 节点时可能会碰到如下错误
# [WARNING IsDockerSystemdCheck]: detected "cgroupfs" as the Docker cgroup driver. The recommended driver is "systemd". 
# Please follow the guide at https://kubernetes.io/docs/setup/cri/
sed -i "s#^ExecStart=/usr/bin/dockerd.*#ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock --exec-opt native.cgroupdriver=systemd#g" /usr/lib/systemd/system/docker.service

# 设置 docker 镜像，提高 docker 镜像下载速度和稳定性
# 如果访问 https://hub.docker.io 速度非常稳定，也可以跳过这个步骤，一般不需配置
# curl -sSL https://kuboard.cn/install-script/set_mirror.sh | sh -s ${REGISTRY_MIRROR}

# 重新加载配置文件
systemctl daemon-reload
#重启 docker
systemctl restart docker
# 将kubelet设置为开机启动并启动kubelet
systemctl enable kubelet && systemctl start kubelet
# 查看docker版本
docker version
```

在每台服务器上为install_k8s.sh脚本赋予可执行权限，并执行脚本
```bash
# 赋予install_k8s.sh脚本可执行权限
chmod a+x ./install_k8s.sh
# 运行install_k8s.sh脚本
./install_k8s.sh
```

## 3.2 初始化Master节点
只在test10服务器上执行的操作。
1.初始化Master节点的网络环境
注意：下面的命令需要在命令行手动执行。
```bash
# 只在 master 节点执行
# export 命令只在当前 shell 会话中有效，开启新的 shell 窗口后，如果要继续安装过程，请重新执行此处的 export 命令
export MASTER_IP=192.168.0.10
# 替换 k8s.master 为 您想要的 dnsName
export APISERVER_NAME=k8s.master
# Kubernetes 容器组所在的网段，该网段安装完成后，由 kubernetes 创建，事先并不存在于物理网络中
export POD_SUBNET=172.18.0.1/16
echo "${MASTER_IP}    ${APISERVER_NAME}" >> /etc/hosts
```

## 3.3 初始化Master节点
在test10服务器上创建init_master.sh脚本文件，文件内容如下所示。
```bash
#!/bin/bash
# 脚本出错时终止执行
set -e

if [ ${#POD_SUBNET} -eq 0 ] || [ ${#APISERVER_NAME} -eq 0 ]; then
  echo -e "\033[31;1m请确保您已经设置了环境变量 POD_SUBNET 和 APISERVER_NAME \033[0m"
  echo 当前POD_SUBNET=$POD_SUBNET
  echo 当前APISERVER_NAME=$APISERVER_NAME
  exit 1
fi


# 查看完整配置选项 https://godoc.org/k8s.io/kubernetes/cmd/kubeadm/app/apis/kubeadm/v1beta2
rm -f ./kubeadm-config.yaml
cat <<EOF > ./kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
kubernetesVersion: v1.18.2
imageRepository: registry.cn-hangzhou.aliyuncs.com/google_containers
controlPlaneEndpoint: "${APISERVER_NAME}:6443"
networking:
  serviceSubnet: "10.96.0.0/16"
  podSubnet: "${POD_SUBNET}"
  dnsDomain: "cluster.local"
EOF

# kubeadm init
# 初始化kebeadm
kubeadm init --config=kubeadm-config.yaml --upload-certs

# 配置 kubectl
rm -rf /root/.kube/
mkdir /root/.kube/
cp -i /etc/kubernetes/admin.conf /root/.kube/config

# 安装 calico 网络插件
# 参考文档 https://docs.projectcalico.org/v3.13/getting-started/kubernetes/self-managed-onprem/onpremises
echo "安装calico-3.13.1"
rm -f calico-3.13.1.yaml
wget https://kuboard.cn/install-script/calico/calico-3.13.1.yaml
kubectl apply -f calico-3.13.1.yaml
```

赋予init_master.sh脚本文件可执行权限并执行脚本。
```bash
# 赋予init_master.sh文件可执行权限
chmod a+x ./init_master.sh
# 运行init_master.sh脚本
./init_master.sh
```

## 3.4 查看Master节点的初始化结果
（1）确保所有容器组处于Running状态
```bash
# 执行如下命令，等待 3-10 分钟，直到所有的容器组处于 Running 状态
watch kubectl get pod -n kube-system -o wide
```
具体执行如下所示。
```bash
[root@test10 ~]# watch kubectl get pod -n kube-system -o wide
Every 2.0s: kubectl get pod -n kube-system -o wide                                                                                                                          test10: Sun May 10 11:01:32 2020

NAME                                       READY   STATUS    RESTARTS   AGE    IP                NODE        NOMINATED NODE   READINESS GATES
calico-kube-controllers-5b8b769fcd-5dtlp   1/1     Running   0          118s   172.18.203.66     test10   <none>           <none>
calico-node-fnv8g                          1/1     Running   0          118s   192.168.0.10   test10   <none>           <none>
coredns-546565776c-27t7h                   1/1     Running   0          2m1s   172.18.203.67     test10   <none>           <none>
coredns-546565776c-hjb8z                   1/1     Running   0          2m1s   172.18.203.65     test10   <none>           <none>
etcd-test10                             1/1     Running   0          2m7s   192.168.0.10   test10   <none>           <none>
kube-apiserver-test10                   1/1     Running   0          2m7s   192.168.0.10   test10   <none>           <none>
kube-controller-manager-test10          1/1     Running   0          2m7s   192.168.0.10   test10   <none>           <none>
kube-proxy-dvgsr                           1/1     Running   0          2m1s   192.168.0.10   test10   <none>           <none>
kube-scheduler-test10                   1/1     Running   0          2m7s   192.168.0.10   test10   <none>           <none>
```

查看 Master 节点初始化结果
具体执行如下所示。
```bash
[root@test10 ~]# kubectl get nodes -o wide
NAME        STATUS   ROLES    AGE     VERSION   INTERNAL-IP       EXTERNAL-IP   OS-IMAGE                KERNEL-VERSION         CONTAINER-RUNTIME
test10   Ready    master   3m28s   v1.18.2   192.168.0.10   <none>        CentOS Linux 8 (Core)   4.18.0-80.el8.x86_64   docker://19.3.8
```

## 3.5 初始化Worker节点
### 3.5.1 获取join命令参数
在Master节点（test10服务器）上执行如下命令获取join命令参数。
```bash
kubeadm token create --print-join-command
```
具体执行如下所示。
```bash
[root@test10 ~]# kubeadm token create --print-join-command
W0510 11:04:34.828126   56132 configset.go:202] WARNING: kubeadm cannot validate component configs for API groups [kubelet.config.k8s.io kubeproxy.config.k8s.io]
kubeadm join k8s.master:6443 --token 8nblts.62xytoqufwsqzko2     --discovery-token-ca-cert-hash sha256:1717cc3e34f6a56b642b5751796530e367aa73f4113d09994ac3455e33047c0d
```
其中，有如下一行输出。
```bash
kubeadm join k8s.master:6443 --token 8nblts.62xytoqufwsqzko2     --discovery-token-ca-cert-hash sha256:1717cc3e34f6a56b642b5751796530e367aa73f4113d09994ac3455e33047c0d
```
这行代码就是获取到的join命令。

注意：join命令中的token的有效时间为 2 个小时，2小时内，可以使用此 token 初始化任意数量的 worker 节点。

### 3.5.2 初始化Worker节点

针对所有的 worker 节点执行，在这里，就是在test11服务器和test12服务器上执行。

在命令分别手动执行如下命令。
```bash
# 只在 worker 节点执行
# 192.168.0.10 为 master 节点的内网 IP
export MASTER_IP=192.168.0.10
# 替换 k8s.master 为初始化 master 节点时所使用的 APISERVER_NAME
export APISERVER_NAME=k8s.master
echo "${MASTER_IP}    ${APISERVER_NAME}" >> /etc/hosts

# 替换为 master 节点上 kubeadm token create 命令输出的join
kubeadm join k8s.master:6443 --token 8nblts.62xytoqufwsqzko2     --discovery-token-ca-cert-hash sha256:1717cc3e34f6a56b642b5751796530e367aa73f4113d09994ac3455e33047c0d
```

具体执行如下所示。
```bash
[root@test11 ~]# export MASTER_IP=192.168.0.10
[root@test11 ~]# export APISERVER_NAME=k8s.master
[root@test11 ~]# echo "${MASTER_IP}    ${APISERVER_NAME}" >> /etc/hosts
[root@test11 ~]# kubeadm join k8s.master:6443 --token 8nblts.62xytoqufwsqzko2     --discovery-token-ca-cert-hash sha256:1717cc3e34f6a56b642b5751796530e367aa73f4113d09994ac3455e33047c0d 
W0510 11:08:27.709263   42795 join.go:346] [preflight] WARNING: JoinControlPane.controlPlane settings will be ignored when control-plane flag is not set.
[preflight] Running pre-flight checks
        [WARNING FileExisting-tc]: tc not found in system path
[preflight] Reading configuration from the cluster...
[preflight] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -oyaml'
[kubelet-start] Downloading configuration for the kubelet from the "kubelet-config-1.18" ConfigMap in the kube-system namespace
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Starting the kubelet
[kubelet-start] Waiting for the kubelet to perform the TLS Bootstrap...

This node has joined the cluster:
* Certificate signing request was sent to apiserver and a response was received.
* The Kubelet was informed of the new secure connection details.

Run 'kubectl get nodes' on the control-plane to see this node join the cluster.
```

根据输出结果可以看出，Worker节点加入了K8S集群。

> 注意：kubeadm join…就是master 节点上 kubeadm token create 命令输出的join。

### 3.5.3 查看初始化结果

在Master节点（test10服务器）执行如下命令查看初始化结果。
```bash
kubectl get nodes -o wide
```

具体执行如下所示。
```bash
[root@test10 ~]# kubectl get nodes
NAME        STATUS   ROLES    AGE     VERSION
test10   Ready    master   20m     v1.18.2
test11   Ready    <none>   2m46s   v1.18.2
test12   Ready    <none>   2m46s   v1.18.2
```

注意：kubectl get nodes命令后面加上-o wide参数可以输出更多的信息。