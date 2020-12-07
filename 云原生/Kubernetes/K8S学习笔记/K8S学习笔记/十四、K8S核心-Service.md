# 1. Service

- 定义一组pod的访问规则



Service是Kubernetes的核心概念，通过创建Service，可以为一组具有相同功能的容器应用提供一个统一的入口地址，并且将请求负载分发到后端的各个容器应用上。

**Service从逻辑上代表了一组Pod，具体是哪组Pod则是由label来挑选的**

**在Kubernetes中Service的Cluster IP实现数据报文请求的转发，都离不开node上部署的重要组件 kube-proxy**



kube-proxy作用

- 实时监听kube-api，获取建立service的建立，升级信息，增加或删除pod信息。来获取Pod和VIP的映射关系
- 维护本地Netfileter iptables IPVS内核组件
- 通过修改和更新ipvs规则来实现数据报文的转发规则
- 构建路由信息，通过转发规则转发报文到对应的pod上



## 1.1 service存在意义

- 防止pod失联（服务发现）

![](..\..\img\pod.png)



- 定义一组Pod访问策略（负载均衡）

![](..\..\img\service.png)

## 1.2 Pod和Service关系

- 根据label和selector标签建立关联的

- 通过serivice实现Pod的负载均衡

![](..\..\img\podservice.png)

## 1.3 常用Service类型

### ClusterIP（默认）

- 集群内部使用

### NodePort

- 对外访问应用使用，对外暴露，访问端口

### LoadBalancer

- 对外访问应用使用，公有云



node内网部署应用，外网一般不能访问。

- 找到一台可以进行外网访问机器，安装nginx，反向代理
- 手动把可以访问节点添加到nginx里面



LoadBalancer：公有云，负载均衡，控制器

# 2. Service资源定义

```yaml
apiVersion: v1
kind: Service
metadata:
 name: nginx-svc
 labels:
   app: nginx
spec:
 type: ClusterIP
 ports:
   - port: 80
      targetPort: 80
 selector:
   app: nginx
```

## 2.1 Service Type

根据创建Service的type不同 可以分为以下几种类型

- **ClusterIP**
  默认方式，根据是否生成ClusterIP又可以分为普通Service和Headless Service两类

  此方式仅用于集群内部之间实现通信的

- **NodePort**

  NodePort模式除了使用cluster ip外，也将service的port映射到每个node的一个指定内部port上，映射的每个node的内部port都一样。可以通过访问Node节点的IP实现外部通信

- **LoadBalancer**
  要配合支持公有云负载均衡使用比如GCE、AWS。其实也是NodePort，只不过会把:自动添加到公有云的负载均衡当中

- **ExternalName**

  外部IP;如果集群外部需要有一个服务需要我们进行访问；那么就需要在service中指定外部的IP让service与外部的那个服务进行访问;那么接下的集群内部到外部那个数据包走向便是:数据包先到service然后由service交给外部那个服务；回来的数据包是:交给node node交给service service交给Pod



下面说下生产常用的类型定义以及使用



### ClusterIP

定义一个web应用

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-deploy
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: myappnginx
      release: stable
  template:
    metadata:
      labels:
        app: myappnginx
        release: stable
    spec:
      containers:
      - name: nginxweb
        image: nginx:1.14-alpine
        imagePullPolicy: IfNotPresent
```

#### **创建service资源基于ClusterIP类型**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: webservice          #service名字;也就是后面验证基于主机名访问的名字
  namespace: default        #名称空间要与刚才创建的Pod的名称空间一致，service资源也是基于namespace隔离的
spec:
  selector:                         #标签选择器很重要决定是要关联某个符合标签的Pod
    app: myappnginx         #标签要与刚才定义Pod的标签一致;因为service是通过标签与Pod关联的
    release: stable      
  type: ClusterIP               #类型是ClusterIP
  ports:                          #暴露的端口设置
  - port: 88                     #service暴露的端口
    targetPort: 80             #容器本身暴露的端口，和dockerfile中的expose意思一样
```

#### 查看service状态

```bash
[root@master replicaset]# kubectl get svc -o wide
NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE    SELECTOR
kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP   3d9h   <none>
webservice   ClusterIP   10.102.99.133   <none>        88/TCP    13s    app=myappnginx,release=stable

[root@master replicaset]# kubectl describe svc webservice
Name:              webservice
Namespace:         default
Labels:            <none>
Annotations:       kubectl.kubernetes.io/last-applied-configuration:
                     {"apiVersion":"v1","kind":"Service","metadata":{"annotations":{},"name":"webservice","namespace":"default"},"spec":{"ports":[{"port":88,"t...
Selector:          app=myappnginx,release=stable
Type:              ClusterIP
IP:                10.102.99.133        
Port:              <unset>  88/TCP
TargetPort:        80/TCP
Endpoints:         10.244.1.27:80,10.244.2.27:80
Session Affinity:  None
Events:            <none>
```

#### 连接一个客户端Pod进行测试

```bash
[root@master replicaset]# kubectl exec -it web-deploy-75bfb496f9-fm29g -- /bin/sh
/ # wget -O - webservice:88   #基于coredns进行解析的
Connecting to webservice:88 (10.102.99.133:88)
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
```

### 无头service

无头IP只能使用CluserIP类型就是没有clusterip 而是将解析的IP 解析到后端的Pod之上

该服务不会分配Cluster IP，也不通过kube-proxy做反向代理和负载均衡。而是通过DNS提供稳定的网络ID来访问，DNS会将headless service的后端直接解析为podIP列表。主要供StatefulSet使用

```bash
[root@master replicaset]# cat svc.yaml 
apiVersion: v1
kind: Service
metadata:
  name: webservice
  namespace: default
spec:
  selector:
    app: myappnginx
    release: stable
  clusterIP: None           定义cluserIP为空
  ports:
  - port: 88
    targetPort: 80


[root@master replicaset]# kubectl get svc -o wide
NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE     SELECTOR
kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   3d10h   <none>
webservice   ClusterIP   None         <none>        88/TCP    7s      app=myappnginx,release=stable
[root@master replicaset]# kubectl exec -it web-deploy-75bfb496f9-fm29g -- /bin/sh
/ # cat /etc/resolv.conf 
nameserver 10.96.0.10
search default.svc.cluster.local svc.cluster.local cluster.local
options ndots:5
/ # nslookup webservice
nslookup: can't resolve '(null)': Name does not resolve

Name:      webservice
Address 1: 10.244.2.27 10-244-2-27.webservice.default.svc.cluster.local
Address 2: 10.244.1.27 web-deploy-75bfb496f9-fm29g
```

### NodePort

```yaml
[root@k8s-master01 daem]# cat deploy.yaml 
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: default
  name: nginxapp
  labels:
    app: nginx-deploy
spec:
  replicas: 2
  selector:
    matchLabels:
      app: mynginx
  template:
    metadata:
      labels:
        app: mynginx
    spec:
      containers:
      - name: nginxweb1
        image: nginx:1.15-alpine
您在 /var/spool/mail/root 中有新邮件
[root@k8s-master01 daem]# cat svc.yaml 
apiVersion: v1
kind: Service
metadata:
  name: nginx-svc
  labels:
    app: nginx-svc
spec:
  ports:
  - name: http
    port: 80                #service暴露的端口，可以基于内部集群访问
    protocol: TCP
    nodePort: 30001   #node节点的映射端口 可以通过外部访问
    targetPort: 80
  selector:
    app: mynginx
  sessionAffinity: None
  type: NodePort
```

可以基于内部集群访问

```bash
[root@k8s-master01 daem]# kubectl get svc 
NAME         TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
kubernetes   ClusterIP   10.96.0.1      <none>        443/TCP        8d
nginx-svc    NodePort    10.99.184.91   <none>        80:30001/TCP   5s
您在 /var/spool/mail/root 中有新邮件
[root@k8s-master01 daem]# curl 10.99.184.91 
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
[root@k8s-master01 daem]# 
```

外部浏览器也可以进行访问。



### sessionAffinity实现源地址session绑定

```yaml
apiVersion: v1
kind: Service
metadata:
  name: webservice
  namespace: default
spec:
  selector:
    app: myappnginx
    release: stable
  sessionAffinity: ClientIP     将来自同意客户端的请求调度到后端的同一个Pod上
  type: NodePort
  ports:
  - port: 88
    nodePort: 30001
    targetPort: 80
```

**直接通过Pod的IP地址和端口号可以访问到容器应用内的服务，但是Pod的IP地址是不可靠的，例如当Pod所在的Node发生故障时，Pod将被Kubernetes重新调度到另一个Node，Pod的IP地址将发生变化。更重要的是，如果容器应用本身是分布式的部署方式，通过多个实例共同提供服务，就需要在这些实例的前端设置一个负载均衡器来实现请求的分发。Kubernetes中的Service就是用于解决这些问题的核心组件。**