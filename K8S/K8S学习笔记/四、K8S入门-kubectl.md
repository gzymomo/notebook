## 1. 查看相关信息

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