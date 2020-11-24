# Kubernetes集群命令行工具kubectl

​	kubectl是Kubernetes集群的命令行工具，通过kubectl能够对集群本身进行管理，并能够在集群上进行容器化应用的安装部署。

​	kubectl命令的语法：

```bash
kubectl [command] [TYPE] [NAME] [flags]
```

- command：指定要对资源执行的操作，例如create、get、describe和delete。
- TYPE：指定资源类型，资源类型是大小写敏感的，开发者能够以单数、复数和缩略的形式。例如：

```bash
kubectl get pod pod1
kubectl get pods pod1
kubectl get po pod1
```

- NAME：指定资源的名称，名称也大小写敏感的。如果省略名称，则会显示所有的资源。例如：

```bash
kubectl get pods
```

- flags：指定可选的参数。例如，可用-s 或者-server参数指定Kubernetes API server的地址和端口。



## 1. 查看相关信息

帮助命令：

```bash
kubectl --help
```

具体查看某个操作：

```bash
kubectl get --help
```



### 1.1. get

#### 1.1.1. 基本信息查看

```bash
Usage:  kubectl get resource [-o wide|json|yaml] [-n namespace]
Man:    获取资源的相关信息，-n 指定名称空间，-o 指定输出格式
        resource可以是具体资源名称，如pod nginx-xxx；也可以是资源类型，如pod；或者all
```



```bash
[root@hdss7-21 ~]# kubectl get cs
NAME                 STATUS    MESSAGE              ERROR
controller-manager   Healthy   ok                   
scheduler            Healthy   ok                   
etcd-1               Healthy   {"health": "true"}   
etcd-2               Healthy   {"health": "true"}   
etcd-0               Healthy   {"health": "true"} 

[root@hdss7-21 ~]# kubectl get node -o wide
NAME                STATUS   ROLES         AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                KERNEL-VERSION          CONTAINER-RUNTIME
hdss7-21.host.com   Ready    master,node   11d   v1.15.2   10.4.7.21     <none>        CentOS Linux 7 (Core)   3.10.0-862.el7.x86_64   docker://19.3.5
hdss7-22.host.com   Ready    master,node   11d   v1.15.2   10.4.7.22     <none>        CentOS Linux 7 (Core)   3.10.0-862.el7.x86_64   docker://19.3.5

[root@hdss7-21 ~]# kubectl get svc -o wide -n kube-system
NAME                      TYPE        CLUSTER-IP        EXTERNAL-IP   PORT(S)                  AGE     SELECTOR
coredns                   ClusterIP   192.168.0.2       <none>        53/UDP,53/TCP,9153/TCP   4d20h   k8s-app=coredns
kubernetes-dashboard      ClusterIP   192.168.140.139   <none>        443/TCP                  3d9h    k8s-app=kubernetes-dashboard
traefik-ingress-service   ClusterIP   192.168.45.46     <none>        80/TCP,8080/TCP          3d19h   k8s-app=traefik-ingress

[root@hdss7-21 ~]# kubectl get pod nginx-ds-jdp7q -o yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: "2020-01-13T13:13:02Z"
  generateName: nginx-ds-
  labels:
    app: nginx-ds
......
```

#### 1.1.2. 根据标签筛选

```bash
--show-labels  显示所有标签
-l app         仅显示标签为app的资源
-l app=nginx   仅显示包含app标签，且值为nginx的资源
```



```bash
[root@hdss7-21 ~]# kubectl get pod -n app --show-labels 
NAME       READY   STATUS    RESTARTS   AGE   LABELS
pod-02     1/1     Running   0          9h    app=nginx,release=stable,version=v1.12
pod-demo   1/1     Running   9          9h    app=centos7,environment=dev,release=stable
[root@hdss7-21 ~]# kubectl get pod -n app --show-labels -l app
NAME       READY   STATUS    RESTARTS   AGE   LABELS
pod-02     1/1     Running   0          9h    app=nginx,release=stable,version=v1.12
pod-demo   1/1     Running   9          9h    app=centos7,environment=dev,release=stable
[root@hdss7-21 ~]# kubectl get pod -n app --show-labels -l app=nginx
NAME     READY   STATUS    RESTARTS   AGE   LABELS
pod-02   1/1     Running   0          9h    app=nginx,release=stable,version=v1.12
```



### 1.2. describe

```bash
Usage: kubectl describe (-f FILENAME | TYPE [NAME_PREFIX | -l label] | TYPE/NAME) [-n namespace]
Man:   描述某个资源信息
```



```bash
[root@hdss7-21 ~]# kubectl describe svc nginx-web
Name:              nginx-web
......

[root@hdss7-21 ~]# kubectl describe pod -l app=nginx-web
Name:           nginx-web-796c86d7cd-8kst5
Namespace:      default
......
```

### 1.3. 其它集群信息

```bash
[root@hdss7-21 ~]# kubectl version  # 集群版本
Client Version: version.Info{Major:"1", Minor:"15", GitVersion:"v1.15.2", GitCommit:"f6278300bebbb750328ac16ee6dd3aa7d3549568", GitTreeState:"clean", BuildDate:"2019-08-05T09:23:26Z", GoVersion:"go1.12.5", Compiler:"gc", Platform:"linux/amd64"}
Server Version: version.Info{Major:"1", Minor:"15", GitVersion:"v1.15.2", GitCommit:"f6278300bebbb750328ac16ee6dd3aa7d3549568", GitTreeState:"clean", BuildDate:"2019-08-05T09:15:22Z", GoVersion:"go1.12.5", Compiler:"gc", Platform:"linux/amd64"}
```



```bash
[root@hdss7-21 ~]# kubectl cluster-info  # 集群信息
Kubernetes master is running at http://localhost:8080
CoreDNS is running at http://localhost:8080/api/v1/namespaces/kube-system/services/coredns:dns/proxy
kubernetes-dashboard is running at http://localhost:8080/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'
```



## 2. 创建资源

### 2.1. run(弃用)

```bash
Usage:  kubectl run NAME --image=image [--env="key=value"] [--port=port] [--replicas=replicas] [--dry-run=bool] [options]
Man:    通过kubectl创建一个deployment或者Job。name为deployment的名字，image为容器的镜像
        port为对容器外暴露的端口，replicas为副本数，dry-run为干运行(不创建pod)
```



```bash
[root@hdss7-21 ~]# kubectl run web-deploy --image=harbor.od.com/public/nginx:latest --replicas=2
[root@hdss7-21 ~]# kubectl get deployment
NAME         READY   UP-TO-DATE   AVAILABLE   AGE
web-deploy   2/2     2            2           92s
[root@hdss7-21 ~]# kubectl get pods|grep web-deploy
web-deploy-bc78f6667-5s6rq   1/1     Running   0          119s
web-deploy-bc78f6667-h67zb   1/1     Running   0          119s
```

### 2.2. create

```bash
Uage:   kubectl create -f filename.yaml
        kubectl create resourece [options]
Man:    根据清单文件或者指定的资源参数创建资源
```



```bash
[root@hdss7-21 ~]# kubectl create namespace app     # 创建名称空间
[root@hdss7-21 ~]# kubectl get ns app
NAME   STATUS   AGE
app    Active   10s

[root@hdss7-21 ~]# kubectl create deployment app-deploy --image=harbor.od.com/public/nginx:latest -n app # 创建deployment
[root@hdss7-21 ~]# kubectl get all -n app
NAME                             READY   STATUS    RESTARTS   AGE
pod/app-deploy-5b5649fc4-plbxg   1/1     Running   0          13s

NAME                         READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/app-deploy   1/1     1            1           13s

NAME                                   DESIRED   CURRENT   READY   AGE
replicaset.apps/app-deploy-5b5649fc4   1         1         1       13s
```

### 2.3. 创建service资源

```bash
Usage: Usage:  kubectl expose TYPE NAME [--port=port] [--protocol=TCP|UDP|SCTP] [--target-port=n] [--name=name] [--external-ip=external-ip-of-service] [options]
Man:    TYPE为deployment,NAME为depoly资源名称，port和target-port分别为集群和pod的端口
```



```bash
[root@hdss7-21 ~]# kubectl expose deployment app-deploy --port=80 --target-port=80 --name=app-svc -n app
[root@hdss7-21 ~]# kubectl describe svc app-svc -n app
Name:              app-svc
Namespace:         app
Labels:            app=app-deploy
Annotations:       <none>
Selector:          app=app-deploy
Type:              ClusterIP
IP:                192.168.28.124
Port:              <unset>  80/TCP
TargetPort:        80/TCP
Endpoints:         172.7.21.8:80
```



## 3. 扩缩容

```bash
Usage:  kubectl scale --replicas=COUNT TYPE NAME [options]
Man:    对资源进行扩缩容，即修改副本数
```



```bash
[root@hdss7-21 ~]# kubectl get deploy web-deploy
NAME         READY   UP-TO-DATE   AVAILABLE   AGE
web-deploy   2/2     2            2           37m
[root@hdss7-21 ~]# kubectl scale --replicas=5 deployment web-deploy  # 扩容
[root@hdss7-21 ~]# kubectl get deploy web-deploy
NAME         READY   UP-TO-DATE   AVAILABLE   AGE
web-deploy   3/5     5            3           38m

[root@hdss7-21 ~]# kubectl scale --replicas=1 deployment web-deploy  # 缩容
[root@hdss7-21 ~]# kubectl get deploy web-deploy
NAME         READY   UP-TO-DATE   AVAILABLE   AGE
web-deploy   1/1     1            1           38m
```



## 4. 删除资源

```bash
Usage:  kubectl delete ([-f FILENAME] | [-k DIRECTORY] | TYPE [(NAME | -l label | --all)]) [options]
Man:    删除指定资源
```



```bash
[root@hdss7-21 ~]# kubectl get deployment -n app
NAME                         READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/app-deploy   1/1     1            1           35m
[root@hdss7-21 ~]# kubectl delete deployment app-deploy -n app
deployment.extensions "app-deploy" deleted

[root@hdss7-21 ~]# kubectl delete ns app
namespace "app" deleted
```



## 5. 贴附到pod上

```bash
Usage:  kubectl exec (POD | TYPE/NAME) [-c CONTAINER] [flags] -- COMMAND [args...] [options]
```



```bash
[root@hdss7-21 ~]# kubectl exec nginx-web-796c86d7cd-zx2b9 -it -- /bin/bash  # 交互式
root@nginx-web-796c86d7cd-zx2b9:/# exit
exit

[root@hdss7-21 ~]# kubectl exec nginx-web-796c86d7cd-zx2b9 -- cat /etc/resolv.conf
nameserver 192.168.0.2
search default.svc.cluster.local svc.cluster.local cluster.local host.com
options ndots:5

[root@hdss7-21 ~]# kubectl exec nginx-web-796c86d7cd-zx2b9 cat /etc/resolv.conf
nameserver 192.168.0.2
search default.svc.cluster.local svc.cluster.local cluster.local host.com
options ndots:5
```



## 6. 查看资源清单文档

```bash
[root@hdss7-21 ~]# kubectl api-versions  # 查看api-version信息
apps/v1
node.k8s.io/v1beta1
v1
......
```



```bash
Usage:  kubectl explain RESOURCE [options]
Man:    查看各个字段的解释

[root@hdss7-21 ~]# kubectl explain pod.spec.containers
KIND:     Pod
VERSION:  v1

RESOURCE: containers <[]Object>
```

## 2. kubectl子命令使用分类

### 2.1 基础命令

1. create：通过文件名或标准输入创建资源
2. expose：将一个资源公开为一个新的Service
3. run：在集群中运行一个特定的镜像
4. set：在对象上设置特定的功能
5. get：显示一个或多个资源
6. explain：文档参考资料
7. edit：使用默认的编辑器编辑一个资源
8. delete：通过文件名、标准输入、资源名称或标签选择器来删除资源。



### 2.2 部署和集群管理命令

部署命令：

1. rollout：管理资源的发布
2. rolling-update：对给定的复制控制器滚动更新
3. scale：扩容或缩容Pod数量，Deployment、ReplicaSet、RC或Job
4. autoscale：创建一个字段选择扩容或缩容并设置Pod数量



集群管理命令：

1. certificate：修改证书资源
2. cluster-info：显示集群信息
3. top：显示资源（CPU/Memory/Storage）使用。需要Heapster运行
4. cordon：标记资源不可调度
5. uncordon：标记资源可调度
6. drain：驱逐节点上的应用，准备下线维护
7. taint：修改节点taint标记



故障和调试命令：

1. describe：显示特定资源或资源组的详细信息
2. logs：在一个Pod中打印一个容器日志。如果Pod只有一个容器，容器名称是可选的
3. attach：附加到一个运行的容器
4. exec：执行命令到容器
5. port-forward：转发一个或多个本地端口到一个pod
6. proxy：运行一个proxy到Kubernetes API server
7. cp：拷贝文件或目录到容器中
8. auth：检查授权



高级命令：

1. apply：通过文件名或标准输入对资源应用配置
2. patch：使用补丁修改、更新资源的字段
3. replace：通过文件名或标准输入替换一个资源
4. convert：不同的API版本之间转换配置文件



设置命令：

1. label：更新资源上的标签
2. annotate：更新资源上的注释
3. completion：用于实现kubectl工具自动补全



其他命令：

1. api-versions：打印受支持的API版本
2. config：修改kubeconfig文件（用于访问API，比如配置认证信息）
3. help：所有命令帮助
4. plugin：运行一个命令行插件
5. version：打印客户端和服务版本信息