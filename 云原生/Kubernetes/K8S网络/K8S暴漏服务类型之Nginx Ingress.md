相关内容参考链接：

- [Kubernetes Service对外暴露应用详解](https://mp.weixin.qq.com/s?__biz=MzAwNTM5Njk3Mw==&mid=2247496042&idx=1&sn=e8d6ae662f6a1375b167ca44d35bf52c&chksm=9b1ff1e8ac6878fe586d43746e78965cafb36637dbce5dbbd7bf022abfba5c709c1979b9cbac&mpshare=1&scene=24&srcid=1215IEPIkCxX1XS3sYNu63bz&sharer_sharetime=1608015467956&sharer_shareid=63281a6430fc669a5b286c6a03545e04#rd)



# 一、Ingress 介绍

> 我们知道，到目前为止 Kubernetes 暴露服务的有三种方式，分别为 LoadBlancer Service、NodePort Service、Ingress。官网对 Ingress 的定义为管理对外服务到集群内服务之间规则的集合，通俗点讲就是它定义规则来允许进入集群的请求被转发到集群中对应服务上，从来实现服务暴漏。 Ingress 能把集群内 Service 配置成外网能够访问的 URL，流量负载均衡，终止SSL，提供基于域名访问的虚拟主机等等。

## LoadBlancer Service

LoadBlancer Service 是 Kubernetes 结合云平台的组件，如国外 GCE、AWS、国内阿里云等等，使用它向使用的底层云平台申请创建负载均衡器来实现，有局限性，对于使用云平台的集群比较方便。

相比NodePort方式可以通过任何节点的30312端口访问内部的pod，LoadBalance方式拥有自己独一无二的可公开访问的IP地址；LoadBalance其实是NodePort的一种扩展，使得服务可以通过一个专用的负载均衡器来访问；

```yaml
apiVersion: v1
kind: Service
metadata:
  name: kubia-loadbalancer
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 8080
  selector:
    app: kubia
```

指定服务类型为LoadBalancer，无需指定节点端口；

```bash
d:\k8s]$ kubectl create -f kubia-svc-loadbalancer.yaml
service/kubia-loadbalancer created

[d:\k8s]$ kubectl get svc
NAME                 TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
kubernetes           ClusterIP      10.96.0.1       <none>        443/TCP        31d
kubia-loadbalancer   LoadBalancer   10.96.207.113   <pending>     80:30038/TCP   7s
kubia-nodeport       NodePort       10.96.59.16     <none>        80:30123/TCP   32m
```

可以看到虽然我们没有指定节点端口，但是创建完之后自动启动了30038节点端口

![图片](https://mmbiz.qpic.cn/mmbiz_png/QFzRdz9libEZGnGBKlLgrHErTXD2MhnPeFwckGsTDykukkoTicWALBOGZ3ZMpeLmjjSyTNYCGmL9icdo59Eibpk5YQ/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

所以可以发现同样能通过使用NodePort的方式来访问服务（节点IP+节点端口）；同时也可以通过EXTERNAL-IP来访问，但是使用Minikube，就不会有外部IP地址，外部IP地址将会一直是pending状态；



## NodePort Service

NodePort Service 是通过在节点上暴漏端口，然后通过将端口映射到具体某个服务上来实现服务暴漏，比较直观方便，但是对于集群来说，随着 Service 的不断增加，需要的端口越来越多，很容易出现端口冲突，而且不容易管理。当然对于小规模的集群服务，还是比较不错的。

### 1.NodePort类型的服务

创建一个服务并将其类型设置为NodePort，通过创建NodePort服务，可以让kubernetes在其所有节点上保留一个端口（所有节点上都使用相同的端口号），然后将传入的连接转发给pod；

```yaml
apiVersion: v1
kind: Service
metadata:
  name: kubia-nodeport
spec:
  type: NodePort
  ports:
  - port: 80
    targetPort: 8080
    nodePort: 30123
  selector:
    app: kubia
```

指定服务类型为NodePort，节点端口为30123；

```bash
d:\k8s]$ kubectl create -f kubia-svc-nodeport.yaml
service/kubia-nodeport created

[d:\k8s]$ kubectl get svc
NAME             TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)        AGE
kubernetes       ClusterIP   10.96.0.1     <none>        443/TCP        31d
kubia-nodeport   NodePort    10.96.59.16   <none>        80:30123/TCP   3s

[d:\k8s]$ kubectl exec kubia-7fs6m -- curl -s http://10.96.59.16
You've hit kubia-m487j
```

要外部可以访问内部pod服务，需要知道节点的IP，我们这里使用的节点为minikube，因为这里的minikube是安装在本地windows系统下，可以直接使用minikube的内部ip进行访问

```bash
d:\k8s]$ kubectl get nodes -o wide
NAME       STATUS   ROLES    AGE   VERSION   INTERNAL-IP      EXTERNAL-IP   OS-IMAGE              KERNEL-VERSION   CONTAINER-RUNTIME
minikube   Ready    master   34d   v1.17.0   192.168.99.108   <none>        Buildroot 2019.02.7   4.19.81          docker://19.3.5
image.png
```

## Ingress

每个LoadBalancer服务都需要自己的负载均衡器，以及独有的公有IP地址；而Ingress 只需要一个公网IP就能为许多服务提供访问；当客户端向Ingress发送HTTP请求时，Ingress会根据请求的主机名和路径转发到对应的服务；



Ingress 使用开源的反向代理负载均衡器来实现对外暴漏服务，比如 Nginx、Apache、Haproxy等。Nginx Ingress 一般有三个组件组成：

- Nginx 反向代理负载均衡器

- Ingress Controller

  Ingress Controller 可以理解为控制器，它通过不断的跟 Kubernetes API 交互，实时获取后端 Service、Pod 等的变化，比如新增、删除等，然后结合 Ingress 定义的规则生成配置，然后动态更新上边的 Nginx 负载均衡器，并刷新使配置生效，来达到服务自动发现的作用。

- Ingress

  Ingress 则是定义规则，通过它定义某个域名的请求过来之后转发到集群中指定的 Service。它可以通过 Yaml 文件定义，可以给一个或多个 Service 定义一个或多个 Ingress 规则。

以上三者有机的协调配合起来，就可以完成 Kubernetes 集群服务的暴漏。

# 二、环境、软件准备

Kubernetes 使用 Nginx Ingress 暴漏服务，前提我们需要有一个正常运行的集群服务，这里我采用 kubeadm 搭建的 Kubernetes 集群，具体搭建步骤可以参考我上一篇文章 [国内使用 kubeadm 在 Centos 7 搭建 Kubernetes 集群](http://blog.csdn.net/aixiaoyang168/article/details/78411511) 讲述的比较详细，这里就不做演示了。不过还是要说一下的就是国内翻墙问题，由于这三个服务所需要的 images 在国外，国内用户可以去 [Docker Hub](https://store.docker.com/) 下载指定版本的镜像替代，下载完成后，通过 `docker tag ...` 命令修改成指定名称的镜像即可。

本次演示所依赖的各个镜像列表如下：

| Image Name                                        | Version       | Des ( * 必需) |
| ------------------------------------------------- | ------------- | ------------- |
| gcr.io/google_containers/nginx-ingress-controller | 0.9.0-beta.10 | *             |
| gcr.io/google_containers/defaultbackend           | 1.0           | *             |

说明一下，这里我没有使用最新版本的镜像，因为在 GitHub 上找最新版本对应的镜像，找半天没找到。。。所有就找了一个老一点的版本，不过也能运行哈。

可使用下边脚本，分别替换以上镜像。

```bash
#!/bin/bash

images=(
    nginx-ingress-controller:0.9.0-beta.10 
    defaultbackend:1.0)

for imageName in ${images[@]} ; do
    docker pull docker.io/chenliujin/$imageName
    docker tag docker.io/chenliujin/$imageName gcr.io/google_containers/$imageName 
    docker rmi docker.io/chenliujin/$imageName
done
```

# 三、部署 Default Backend

首先我们需要部署一个默认后端，用来将未知请求全部负载到这个默认后端上，这个默认后端会返回 404 页面。就干了这么件事。。。

```bash
$ cd /home/wanyang3/k8s
$ git clone https://github.com/kubernetes/ingress-nginx.git
$ git checkout nginx-0.9.0-beta.10
# ls -l ingress-nginx/examples/deployment/nginx/
总用量 12
-rw-r--r--. 1 root root 1161 11月  6 17:16 default-backend.yaml
drwxr-xr-x. 2 root root   60 11月  6 17:16 kubeadm
-rw-r--r--. 1 root root 1819 11月  6 17:16 nginx-ingress-controller.yaml
-rw-r--r--. 1 root root 1655 11月  6 17:16 README.md
```

这里可以使用 `kubectl create -f default-backend.yaml` 来创建默认后端。注意，这里我们使用 deployment 方式部署，当然也可以使用 daemonset 方式部署。

不过官方也提供了对 kubeadm 搭建的集群支持，刚好我使用的集群就是通过 kubeadm 搭建，这一步就可以暂时先忽略安装 Default Backend，因为在 ***ingress-nginx/examples/deployment/nginx/kubeadm/nginx-ingress-controller.yaml\*** 配置文件中同时定义好了 Default Backend 和 Ingress Controller，下边一次就安装完毕。

出现 404 的时候返回页面如下：

![这里写图片描述](https://img-blog.csdn.net/20171109091824915?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvYWl4aWFveWFuZzE2OA==/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)

![这里写图片描述](https://img-blog.csdn.net/20171109091838744?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvYWl4aWFveWFuZzE2OA==/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)

# 四、Ingress Controller

## 4.1 Ingress控制器

只有Ingress控制器在集群中运行，Ingress资源才能正常工作；不同的Kubernetes环境使用不同的控制器实现，但有些并不提供默认控制器。



## 4.2 部署Ingress Controller

接下来要部署 Ingress Controller了，有人会问咋没有 Nginx 组件呢？其实这里包含了 Nginx + Ingress Controller 组件.

```bash
# 使用 kubaadm 配置文件
$ kubectl create -f ingress-nginx/examples/deployment/nginx/kubeadm/nginx-ingress-controller.yaml
deployment "default-http-backend" created
service "default-http-backend" created
deployment "nginx-ingress-controller" created

# 使用其他的配置文件，需要先部署 default-backend
$ kubectl create -f ingress-nginx/examples/deployment/nginx/nginx-ingress-controller.yaml
```

部署完成后，我们查看下这两个 Pod 是否启动成功。

```bash
$ kubectl get pods --all-namespaces -o wide
NAMESPACE     NAME                                         READY     STATUS    RESTARTS   AGE       IP              NODE
kube-system   default-http-backend-2198840601-53w56        1/1       Running   0          12s       10.96.1.10      node0.localdomain
kube-system   nginx-ingress-controller-627402744-xn4dm     1/1       Running   0          12s       10.236.65.128   node0.localdomain
...
```

# 五、部署 Ingress

Ingress Controller 和 Default Backend 部署完毕了，下边该部署 Ingress 来定义转发规则了。问题来了，这个服务转发规则怎么写？通过官方示例，我们可以来参考学习下。首先既然是服务转发规则，得知道我们集群中有那些服务，才能配置规则。

通过一段时间的学习，我已经在集群中部署了一些服务了，不过为了演示效果，我们选择有 UI 界面的 Service 来做配置。这里选择 kubernetes-dashboard 和 kibana-logging 来演示一下吧。

```bash
$ kubectl get service --all-namespaces
NAMESPACE     NAME                    CLUSTER-IP       EXTERNAL-IP   PORT(S)         AGE
default       kubernetes              10.96.0.1        <none>        443/TCP         1h
kube-system   default-http-backend    10.102.201.41    <none>        80/TCP          6m
kube-system   elasticsearch-logging   10.105.149.87    <none>        9200/TCP        18m
kube-system   heapster                10.110.233.166   <none>        80/TCP          38m
kube-system   kibana-logging          10.105.121.249   <none>        5601/TCP        17m
kube-system   kube-dns                10.96.0.10       <none>        53/UDP,53/TCP   1h
kube-system   kubernetes-dashboard    10.103.252.55    <nodes>       80:32126/TCP    56m
kube-system   monitoring-grafana      10.104.71.255    <none>        80/TCP          38m
kube-system   monitoring-influxdb     10.109.173.162   <none>        8086/TCP        38m
```

## 5.1 Name based virtual hosting

首先来演示一下基于域名访问虚拟主机的 Ingress 配置，Yaml 文件如下：

```yaml
# 创建 Yaml 文件
$ vim dashboard-kibana-ingress.yaml

apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: dashboard-kibana-ingress
  namespace: kube-system
spec:
  rules:
  - host: dashboard.k8s.ingress
    http:
      paths:
      - backend:
          serviceName: kubernetes-dashboard
          servicePort: 80
  - host: kibana.k8s.ingress
    http:
      paths:
      - backend:
          serviceName: kibana-logging
          servicePort: 5601

# 创建 ingress
$ kubectl create -f dashboard-kibana-ingress.yaml
ingress "dashboard-kibana-ingress" created

# 查看 ingress
$ kubectl get ingress --all-namespaces
NAMESPACE     NAME                       HOSTS                              ADDRESS         PORTS     AGE
kube-system   dashboard-kibana-ingress   dashboard.k8s.ingress,kibana.k8s.ingress   10.236.65.128   80        36s
```

好了，通过上边操作，我们已经把域名分别绑定到指定的 Service 上了。

```bash
dashboard.k8s.ingress --|               |-> dashboard.k8s.ingress kubernetes-dashboard:80
                        | 10.236.65.128 |
kibana.k8s.ingress    --|               |-> kibana.k8s.ingress kibana-logging:5601
```

然后，我们要能本地访问，还需要本机绑定 Host，否则这两个域名肯定找不到的。

```bash
$ echo "10.236.65.128 dashboard.k8s.ingress" >> /etc/hosts
$ echo "10.236.65.128 kibana.k8s.ingress" >> /etc/hosts
```

好了，现在我们打开浏览器，访问以下这两个域名看看效果吧。

![这里写图片描述](https://img-blog.csdn.net/20171109091910186?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvYWl4aWFveWFuZzE2OA==/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)

访问 dashboard.k8s.ingress 完美运行，但是访问 kibana.k8s.ingress 却不能正常进入到 UI 界面，控制台调试以下，发现出现了请求资源 404 错误，类似下边的请求资源的错误。

```
/api/v1/proxy/namespaces/kube-system/services/kibana-logging/bundles/commons.bundle.js?v=10146 
```

不对呀！我们的请求地址是 `http://kibana.k8s.ingress/app/kibana#/discover?_g=...` 开头的地址，为什么请求的资源地址还是 `/api/v1/proxy/namespaces/kube-system/services/kibana-logging/` 呢？查看了下 Kibana 的 Yaml 配置文件，找到答案了。

```yaml
$ cat kubernetes/cluster/addons/fluentd-elasticsearch/kibana-controller.yaml
...
env:
  - name: "ELASTICSEARCH_URL"
    value: "http://elasticsearch-logging:9200"
  - name: "KIBANA_BASE_URL"
    value: "/api/v1/proxy/namespaces/kube-system/services/kibana-logging"
...
```

原来是环境变量中配置了 `KIBANA_BASE_URL` 这个属性，怪不得会去请求这个地址的资源文件呢。解决办法就是，把这个值设置为空值，因为我们访问地址 `http://kibana.k8s.ingress/...` 后边没有 BASE_URL。

```yaml
$ vim kubernetes/cluster/addons/fluentd-elasticsearch/kibana-controller.yaml
...
env:
  - name: "ELASTICSEARCH_URL"
    value: "http://elasticsearch-logging:9200"
  - name: "KIBANA_BASE_URL"
    value: ""
...

$ kubectl apply -f kubernetes/cluster/addons/fluentd-elasticsearch/kibana-controller.yaml
```

稍等一会，在去访问 Kibana 地址 `http://kibana.k8s.ingress/app/kibana#/discover?_g=...`，这下就出来了。

![这里写图片描述](https://img-blog.csdn.net/20171109091938132?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvYWl4aWFveWFuZzE2OA==/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)

## 5.2 Simple fanout

接下来我们来演示一下通过域名下不同的路径转发到不同的服务上去的 Ingress 配置，我们先只配置一下 kubernetes-dashboard 转发规则，Yaml 文件如下：

```yaml
# 创建 Yaml 文件
$ vim my-k8s-ingress.yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: my-k8s-ingress
  namespace: kube-system
  annotations:
    ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: my.k8s.ingress
    http:
      paths:
      - path: /dashboard
        backend:
          serviceName: kubernetes-dashboard
          servicePort: 80

# 创建 ingress
$ kubectl create -f my-k8s-ingress.yaml
ingress "my-k8s-ingress" created

# 查看 ingress
$ kubectl get ingress --all-namespaces
NAMESPACE     NAME                       HOSTS                                      ADDRESS         PORTS     AGE
kube-system   dashboard-kibana-ingress   dashboard.k8s.ingress,kibana.k8s.ingress   10.236.65.128   80        19h
kube-system   my-k8s-ingress             my.k8s.ingress                             10.236.65.128   80        1h
```

然后，我们要能本地访问，还需要本机绑定 Host，否则这个域名也肯定找不到的。

```
$ echo "10.236.65.128 my-k8s-ingress" >> /etc/hosts1
```

好了，现在我们打开浏览器，访问以下 `http://my.k8s.ingress/dashboard/#!/workload?namespace=_all` 域名看看效果吧。

![这里写图片描述](https://img-blog.csdn.net/20171109092033744?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvYWl4aWFveWFuZzE2OA==/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)

OK，成功运行。下边我们要新添加一个匹配规则，将 `http://my.k8s.ingress/kibana` 转发到 kibana-logging 服务上去。最终实现如下绑定：

```
my.k8s.ingress -> 10.236.65.128 -> / dashboard    kubernetes-dashboard:80
                                   / kibana       kibana-logging:5601
```

现在修改一下配置，这里有两种方式修改已经存在的 ingress 规则。

方式一：

```yaml
$ kubectl edit ingress my.k8s.ingress
...
spec:
  rules:
  - host: my.k8s.ingress
    http:
      paths:
      - path: /dashboard
        backend:
          serviceName: kubernetes-dashboard
          servicePort: 80
      - path: /kibana
        backend:
          serviceName: kibana-logging
          servicePort: 5601
...
```

方式二：

```yaml
vim my-k8s-ingress.yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: my-k8s-ingress
  namespace: kube-system
  annotations:
    ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: my.k8s.ingress
    http:
      paths:
      - path: /dashboard
        backend:
          serviceName: kubernetes-dashboard
          servicePort: 80
      - path: /kibana
        backend:
          serviceName: kibana-logging
          servicePort: 5601

# 重新应用或替换 ingress
$ kubectl apply -f my-k8s-ingress.yaml 或者 kubectl replace -f my-k8s-ingress.yaml
```

稍等一会，我们去访问 `http://my.k8s.ingress/kibana/app/kibana#/discover?_g=...` 却不能正常进入到 UI 界面，控制台调试以下，发现出现了请求资源 404 错误，更上边问题一样，出现资源请求 404 错误。

```bash
/bundles/commons.bundle.js?v=10146
```

原因很简单，请求地址少了一层 /kibana 这下就简单了，修改下 Kibana 的 Yaml 配置文件。

```yaml
$ vim kubernetes/cluster/addons/fluentd-elasticsearch/kibana-controller.yaml
...
env:
  - name: "ELASTICSEARCH_URL"
    value: "http://elasticsearch-logging:9200"
  - name: "KIBANA_BASE_URL"
    value: "/kibana"
...

$ kubectl apply -f kubernetes/cluster/addons/fluentd-elasticsearch/kibana-controller.yaml
```

稍等一会，在去访问 Kibana 地址 `http://my.k8s.ingress/kibana/app/kibana#/discover?_g=...`，这下就出来了。

## 5.3 Ingress资源

Ingress控制器启动之后，就可以创建Ingress资源了

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: kubia
spec:
  rules:
  - host: kubia.example.com
    http:
      paths:
      - path: /
        backend:
          serviceName: kubia-nodeport
          servicePort: 80
```

指定资源类型为Ingress，定一个单一规则，所有发送kubia.example.com的请求都会被转发给端口为80的kubia-nodeport服务上；

```bash
[d:\k8s]$ kubectl get svc
NAME             TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
kubernetes       ClusterIP   10.96.0.1       <none>        443/TCP        53d
kubia-nodeport   NodePort    10.96.204.104   <none>        80:30123/TCP   21h

[d:\k8s]$ kubectl create -f kubia-ingress.yaml
ingress.extensions/kubia created

[d:\k8s]$ kubectl get ingress
NAME    HOSTS               ADDRESS          PORTS   AGE
kubia   kubia.example.com   192.168.99.108   80      6m4s
```

需要把域名映射到ADDRESS:192.168.99.108，修改hosts文件即可，下面就可以直接用域名访问了，最终请求会被转发到kubia-nodeport服务

![图片](https://mmbiz.qpic.cn/mmbiz_png/QFzRdz9libEZGnGBKlLgrHErTXD2MhnPeKPIaosRGhYyTskEtn7EiahIsr9MVKDkaHic6fCiclKvgzhvxZ98V97XoQ/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

大致请求流程如下：浏览器中请求域名首先会查询域名服务器，然后DNS返回了控制器的IP地址；客户端向控制器发送请求并在头部指定了kubia.example.com；然后控制器根据头部信息确定客户端需要访问哪个服务；然后通过服务关联的Endpoint对象查看pod IP，并将请求转发给其中一个。



## 5.4 Ingress暴露多个服务

rules和paths是数组，可以配置多个

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: kubia2
spec:
  rules:
  - host: kubia.example.com
    http:
      paths:
      - path: /v1
        backend:
          serviceName: kubia-nodeport
          servicePort: 80
      - path: /v2
        backend:
          serviceName: kubia-nodeport
          servicePort: 80
  - host: kubia2.example.com
    http:
      paths:
      - path: /
        backend:
          serviceName: kubia-nodeport
          servicePort: 80
```

配置了多个host和path，这里为了方便映射了同样服务；

```bash
[d:\k8s]$ kubectl create -f kubia-ingress2.yaml
ingress.extensions/kubia2 created

[d:\k8s]$ kubectl get ingress
NAME     HOSTS                                  ADDRESS          PORTS   AGE
kubia    kubia.example.com                      192.168.99.108   80      41m
kubia2   kubia.example.com,kubia2.example.com   192.168.99.108   80      15m
```

同样需要配置host文件，测试如下：

![图片](https://mmbiz.qpic.cn/mmbiz_png/QFzRdz9libEZGnGBKlLgrHErTXD2MhnPezMEsECm8Z0G2F4vS2nTXtF5qzGEOsybwEIt1IcpSq0lNptZEVHHxpw/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

![图片](https://mmbiz.qpic.cn/mmbiz_png/QFzRdz9libEZGnGBKlLgrHErTXD2MhnPeNJvic1p3Y1jp8H9edQKQoB44yTZxROmicIeSbvAenCa5ojPWc2VebbJQ/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

![图片](https://mmbiz.qpic.cn/mmbiz_png/QFzRdz9libEZGnGBKlLgrHErTXD2MhnPefXkBViaw9tocG9ZeXQXTncWiaQWkN8ELIruic4cYTOWNKc3A3eKLlUKwg/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

## 5.5 配置Ingress处理TLS传输

以上介绍的消息都是基于Http协议，Https协议需要配置相关证书；客户端创建到Ingress控制器的TLS连接时，控制器将终止TLS连接；客户端与Ingress控制器之间是加密的，而Ingress控制器和pod之间没有加密；要使控制器可以这样，需要将证书和私钥附加到Ingress中；

```bash
[root@localhost batck-job]# openssl genrsa -out tls.key 2048
Generating RSA private key, 2048 bit long modulus
..................................................................+++
........................+++
e is 65537 (0x10001)
[root@localhost batck-job]# openssl req -new -x509 -key tls.key -out tls.cert -days 360 -subj /CN=kubia.example.com

[root@localhost batck-job]# ll
-rw-r--r--. 1 root root 1115 Feb 11 01:20 tls.cert
-rw-r--r--. 1 root root 1679 Feb 11 01:20 tls.key
```

生成的两个文件创建secret

```
[d:\k8s]$ kubectl create secret tls tls-secret --cert=tls.cert --key=tls.key
secret/tls-secret created
```

现在可以更新Ingress对象，以便它也接收kubia.example.com的HTTPS请求；

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: kubia
spec:
  tls:
  - hosts: 
    - kubia.example.com
    secretName: tls-secret
  rules:
  - host: kubia.example.com
    http:
      paths:
      - path: /
        backend:
          serviceName: kubia-nodeport
          servicePort: 80
```

tls中指定相关证书

```bash
[d:\k8s]$ kubectl apply -f kubia-ingress-tls.yaml
Warning: kubectl apply should be used on resource created by either kubectl create --save-config or kubectl apply
ingress.extensions/kubia configured
```

通过浏览器访问https协议，如下图所示

![图片](https://mmbiz.qpic.cn/mmbiz_png/QFzRdz9libEZGnGBKlLgrHErTXD2MhnPe8nlYgmA5BAO7icTNT0ZHOe5cZJq5b9JSfyWVaqvM9IaSTPbnB9gibBTA/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)



