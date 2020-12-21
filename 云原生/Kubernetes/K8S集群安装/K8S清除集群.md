[Kubernetes集群之清除集群](https://www.cnblogs.com/weifeng1463/p/12034701.html)



# 清除K8s集群的Etcd集群

##### 暂停相关服务

```bash
systemctl stop etcd
```

##### 清除相关文件

```bash
# 删除 etcd 的工作目录和数据目录
rm -rf /var/lib/etcd

# 删除etcd.service文件
rm -rf /etc/systemd/system/etcd.service

# 删除程序文件
rm -rf /root/local/bin/etcd

# 删除TLS证书文件
rm -rf /etc/etcd/ssl/*
```

# 清除K8s集群的Master节点

##### 暂停相关服务

```bash
systemctl stop kube-apiserver kube-controller-manager kube-scheduler flanneld
```

##### 清除相关文件

```bash
# 删除kube-apiserver工作目录
rm -rf /var/run/kubernetes

# 删除service文件
rm -rf /etc/systemd/system/{kube-apiserver,kube-controller-manager,kube-scheduler,flanneld}.service

# 删除程序文件
rm -rf /root/local/bin/{kube-apiserver,kube-controller-manager,kube-scheduler,flanneld,mk-docker-opts.sh}

# 删除证书文件
rm -rf /etc/flanneld/ssl /etc/kubernetes/ssl

# 删除kubelet缓存
rm -rf ~/.kube/cache ~/.kube/schema
```

# 清除K8s集群的Node节点

##### 暂停相关服务

```bash
systemctl stop kubelet kube-proxy flanneld docker
```

##### 清除相关文件

```bash
# umount kubelet 挂载的目录
mount | grep '/var/lib/kubelet'| awk '{print $3}'|xargs sudo umount

# 删除kubelet工作目录
rm -rf /var/lib/kubelet

# 删除docker工作目录
rm -rf /var/lib/docker

# 删除flanneld写入的网络配置文件
rm -rf /var/run/flannel/

# 删除service文件
rm -rf /etc/systemd/system/{kubelet,docker,flanneld}.service

# 删除程序文件
rm -rf /root/local/bin/{kubelet,docker,flanneld,mk-docker-opts.sh}

# 删除证书文件
rm -rf /etc/flanneld/ssl /etc/kubernetes/ssl
```

##### 清除Iptables

```bash
iptables -F && sudo iptables -X && sudo iptables -F -t nat && sudo iptables -X -t nat
```

##### 清除网桥

```bash
ip link del flannel.1

ip link del docker0
```

