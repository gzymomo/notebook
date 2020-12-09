## 1. （Controller）-Deployment

### 1.1. 介绍

​	kubernetes中内建了很多controller（控制器），这些相当于一个状态机，用来控制pod的具体状态和行为。

​	Controller，在集群上管理和运行容器的对象。



- 确保预期的Pod副本数量
- 无状态应用部署
- 有状态应用部署
- 确保所有的node运行同一个pod
- 一次性任务和定时任务

**部分控制器类型如下：**

- ReplicationController 和 ReplicaSet
- Deployment
- DaemonSet
- StatefulSet
- Job/CronJob
- HorizontalPodAutoscaler



#### 1. 简介

Pod控制器有很多种，最初的是使用 ReplicationController，即副本控制器，用于控制pod数量。随着版本升级，出现了ReplicaSet，跟ReplicationController没有本质的不同，只是名字不一样，并且ReplicaSet支持集合式的selector。ReplicaSet的核心管理对象有三种：用户期望的副本数、标签选择器、pod模板。

ReplicaSet一般不会直接使用，而是采用Deployment，Deployment是用来管理Replicaset，ReplicaSet来管理Pod。Deployment为ReplicaSet 提供了一个声明式定义(declarative)方法，用来替代以前的 ReplicationController 来方便的管理应用，比ReplicaSet的功能更加强大，且包含了ReplicaSet的功能。Deployment支持以下功能：

- 定义Deployment来创建Pod和ReplicaSet
- 滚动升级和回滚应用
- 扩容和缩容
- 暂停部署功能和手动部署



#### 2. 部署方式

- 蓝绿发布

如图，假设副本数是5，目标是从v1升级到v2。先部署5个v2版本的业务机器，再将SLB的流量全部切换到v2上。如果出现异常，可以快速切换到v1版本。但是实际上用的不多，因为需要消耗大量的额外机器资源。

![image.png](https://cdn.nlark.com/yuque/0/2020/png/378176/1579609622409-fadb8cdd-29c6-4b18-827f-16d128938364.png)

- 滚动发布

滚动发布是逐台(批次)升级，需要占用的额外资源少。比如先升级一台，再升级一台，直到全部升级完毕。也可以每次升级10%数量的机器，逐批次升级。

![image.png](https://cdn.nlark.com/yuque/0/2020/png/378176/1579611102084-705eb102-c391-4781-a6f4-15cea08c4f01.png)

- 灰度发布(金丝雀发布)

灰度发布也叫金丝雀发布，起源是，矿井工人发现，金丝雀对瓦斯气体很敏感，矿工会在下井之前，先放一只金丝雀到井中，如果金丝雀不叫了，就代表瓦斯浓度高。

灰度发布会先升级一台灰度机器，将版本升级为v2，此时先经过测试验证，确认没有问题后。从LB引入少量流量进入灰度机器，运行一段时间后，再将其它机器升级为v2版本，引入全部流量。

![image.png](https://cdn.nlark.com/yuque/0/2020/png/378176/1579610210779-2dcfddfc-483a-4e24-9545-9180ef98e400.png)

#### 3. Deployment升级方案

Deployment的升级方案默认是滚动升级，支持升级暂停，支持指定最大超过预期pod数量，支持指定最小低于预期pod数量。可以实现上述三种部署方案(以目标预期pod数量5个，v1版本升级到v2版本为案例)：

- 蓝绿发布场景实现方案：新创建5个v2版本pod，等待5个v2版本Pod就绪后，下掉5个v1版本pod。
- 灰度发布场景实现案例：新创建的第一个pod最为灰度pod，此时暂定升级，等待灰度成功后再升级v1版本Pod
- 滚动发布：通过控制超出预期pod数量和低于预期Pod数量来控制滚动发布的节奏。

如下图，预期pod数量5个，滚动升级，最大超出副本数为2个，最大低于期望值2个的升级方式：

![image.png](https://cdn.nlark.com/yuque/0/2020/png/378176/1579612087811-c8985d4d-1032-4a26-baca-a8a7555bc024.png?x-oss-process=image%2Fwatermark%2Ctype_d3F5LW1pY3JvaGVp%2Csize_10%2Ctext_TGludXgt5rih5rih6bif%2Ccolor_FFFFFF%2Cshadow_50%2Ct_80%2Cg_se%2Cx_10%2Cy_10)

### 1.2. 模板

```bash
apiVersion: apps/v1
kind: Deployment
metadata
    name        <string>            # 在一个名称空间不能重复
    namespace   <string>            # 指定名称空间，默认defalut
    labels      <map[string]string> # 标签
    annotations <map[string]string> # 注释
```



```bash
apiVersion: apps/v1
kind: Deployment
metadata
    name        <string>                            # 在一个名称空间不能重复
    namespace   <string>                            # 指定名称空间，默认defalut
    labels      <map[string]string>                 # 标签
    annotations <map[string]string>                 # 注释

spec
    replicas                    <integer>           # 期望副本数，默认值1
    selector                    <Object>            # 标签选择器
        matchExpressions        <[]Object>          # 标签选择器的一种形式,多个条件使用AND连接
            key                 <string> -required- # 标签中的Key
            operator            <string> -required- # 操作符，支持 In, NotIn, Exists, DoesNotExist
            values              <[]string>          # value的数组集合，当操作符为In或NotIn时不能为空
        matchLabels             <map[string]string> # 使用key/value的格式做筛选
    strategy                    <Object>            # pod更新策略，即如何替换已有的pod
        type                    <string>            # 更新类型，支持 Recreate, RollingUpdate。默认RollingUpdate
        rollingUpdate           <Object>            # 滚动更新策略，仅在type为RollingUpdate时使用
            maxSurge            <string>            # 最大浪涌pod数，即滚动更新时最多可多于出期望值几个pod。支持数字和百分比格式
            maxUnavailable      <string>            # 最大缺失Pod数，即滚动更新时最多可少于期望值出几个pod。支持数字和百分比格式
    revisionHistoryLimit        <integer>           # 历史版本记录数，默认为最大值(2^32)
    template                    <Object> -required- # Pod模板，和Pod管理器yaml几乎格式一致
        metadata                <Object>            # Pod的metadata
        spec                    <Object>            # Pod的spec
```

### 1.3 Pod和Controller关系

- Pod是通过Controller实现应用的运维，比如伸缩，滚动升级等。
- Pod和Controller之间通过label标签建立关系



# 2、Deployment控制器应用场景

- 部署无状态应用（Web，微服务，nginx等）
- 管理Pod和ReplicaSet（副本数量）
- 部署，滚动升级等功能



## 2.1 yaml文件字段说明



![](..\..\img\yaml2.png)





## 2.2 Deployment控制器应用部署

```bash
# 1.生成yaml文件到Web.yaml，导出yaml文件
kubectl create deployment web --image=nginx --dry-run -o yaml > web.yaml
```

部署：

```bash
# 2.使用yaml部署应用
kubectl apply -f web.yaml
# 3.查看
kubectl get pods
# 4.对外发布（暴露对外端口号）-----先生成yaml文件
kubectl expose deployment web --port=80 --type=NodePort --target-port=80 --name=web1 -o yaml >
web1.yaml
# 5. 使用yaml方式发布
kubectl apply -f web1.yaml
# 6、查看已经发布的应用
kubectl get pods,svc
```



# 3、 升级回滚

```bash
# 应用升级
kubectl set image deployment web nginx=nginx:1.15

# 查看升级状态
kubectl rollout status deployment web

# 查看升级的历史版本
kubectl rollout history deployment web

# 回滚，还原到上一个版本
kubectl rollout undo deployment web

# 回滚到指定的版本
kubectl rollout undo deployment web --to-version=2
```



# 3、 弹性伸缩

```bash
# 弹性伸缩
kubectl scale deployment web --replicas=10
```



#  案例

#### 1. 创建deployment

```bash
[root@hdss7-200 deployment]# vim /data/k8s-yaml/base_resource/deployment/nginx-v1.12.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deploy
  namespace: app
spec:
  replicas: 5
  selector:
    matchLabels:
      app: nginx
      release: stable
      tier: slb
      partition: website
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: nginx
        release: stable
        tier: slb
        partition: website
        version: v1.12
    spec:
      containers:
      - name: nginx-pod
        image: harbor.od.com/public/nginx:v1.12
        lifecycle:
          postStart:
            exec:
              command:
                - /bin/bash
                - -c
                - "echo 'health check ok!' > /usr/share/nginx/html/health.html"
        readinessProbe: 
          initialDelaySeconds: 5
          httpGet:
            port: 80
            path: /health.html
        livenessProbe:
          initialDelaySeconds: 10
          periodSeconds: 5
          httpGet:
            port: 80
            path: /health.html
```



```bash
[root@hdss7-21 ~]# kubectl apply -f http://k8s-yaml.od.com/base_resource/deployment/nginx-v1.12.yaml --record

[root@hdss7-21 ~]# kubectl get pods -n app -l partition=website  # 查看
NAME                           READY   STATUS    RESTARTS   AGE
nginx-deploy-5597c8b45-425ms   1/1     Running   0          5m12s
nginx-deploy-5597c8b45-5p2rz   1/1     Running   0          9m34s
nginx-deploy-5597c8b45-dw7hd   1/1     Running   0          9m34s
nginx-deploy-5597c8b45-fg82k   1/1     Running   0          5m12s
nginx-deploy-5597c8b45-sfxmg   1/1     Running   0          9m34s
[root@hdss7-21 ~]# kubectl get rs -n app -l partition=website -o wide
NAME                     DESIRED   CURRENT   READY   AGE   CONTAINERS   IMAGES                             SELECTOR
nginx-deploy-5597c8b45   8         8         8       10m   nginx-pod    harbor.od.com/public/nginx:v1.12   app=nginx,partition=website,pod-template-hash=5597c8b45,release=stable,tier=slb
[root@hdss7-21 ~]# kubectl get deployment -n app -o wide
NAME           READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES                             SELECTOR
nginx-deploy   8/8     8            8           11m   nginx-pod    harbor.od.com/public/nginx:v1.12   app=nginx,partition=website,release=stable,tier=slb
```

#### 2. 模拟蓝绿发布

```bash
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deploy
  namespace: app
spec:
  replicas: 5
  selector:
    matchLabels:
      app: nginx
      release: stable
      tier: slb
      partition: website
  strategy:
    rollingUpdate:
      # 最大浪涌数量为5
      maxSurge: 5
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: nginx
        release: stable
        tier: slb
        partition: website
        # 修改版本信息，用于查看当前版本
        version: v1.13
    spec:
      containers:
      - name: nginx-pod
        # 修改镜像
        image: harbor.od.com/public/nginx:v1.13
        lifecycle:
          postStart:
            exec:
              command:
                - /bin/bash
                - -c
                - "echo 'health check ok!' > /usr/share/nginx/html/health.html"
        readinessProbe: 
          initialDelaySeconds: 5
          httpGet:
            port: 80
            path: /health.html
        livenessProbe:
          initialDelaySeconds: 10
          periodSeconds: 5
          httpGet:
            port: 80
            path: /health.html
```



```bash
[root@hdss7-21 ~]# kubectl apply --filename=http://k8s-yaml.od.com/base_resource/deployment/nginx-v1.13.yaml --record=true
[root@hdss7-21 ~]# kubectl rollout history deployment nginx-deploy -n app
REVISION  CHANGE-CAUSE
1         kubectl apply --filename=http://k8s-yaml.od.com/base_resource/deployment/nginx-v1.12.yaml --record=true
2         kubectl apply --filename=http://k8s-yaml.od.com/base_resource/deployment/nginx-v1.13.yaml --record=true
[root@hdss7-21 ~]# kubectl get rs -n app -l tier=slb -L version # 多个ReplicaSet对应不同版本
NAME                      DESIRED   CURRENT   READY   AGE     VERSION
nginx-deploy-5597c8b45    0         0         0       10m     v1.12
nginx-deploy-6bd88df699   5         5         5       9m31s   v1.13
```



```bash
# 升级过程中的状态变化:
[root@hdss7-21 ~]# kubectl rollout status deployment nginx-deploy -n app 
Waiting for deployment "nginx-deploy" rollout to finish: 5 old replicas are pending termination...
Waiting for deployment "nginx-deploy" rollout to finish: 5 old replicas are pending termination...
Waiting for deployment "nginx-deploy" rollout to finish: 5 old replicas are pending termination...
Waiting for deployment "nginx-deploy" rollout to finish: 4 old replicas are pending termination...
Waiting for deployment "nginx-deploy" rollout to finish: 4 old replicas are pending termination...
Waiting for deployment "nginx-deploy" rollout to finish: 4 old replicas are pending termination...
Waiting for deployment "nginx-deploy" rollout to finish: 3 old replicas are pending termination...
Waiting for deployment "nginx-deploy" rollout to finish: 3 old replicas are pending termination...
Waiting for deployment "nginx-deploy" rollout to finish: 3 old replicas are pending termination...
Waiting for deployment "nginx-deploy" rollout to finish: 2 old replicas are pending termination...
Waiting for deployment "nginx-deploy" rollout to finish: 2 old replicas are pending termination...
Waiting for deployment "nginx-deploy" rollout to finish: 2 old replicas are pending termination...
Waiting for deployment "nginx-deploy" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "nginx-deploy" rollout to finish: 1 old replicas are pending termination...
deployment "nginx-deploy" successfully rolled out
[root@hdss7-21 ~]# kubectl get pod -n app -l partition=website -L version -w
NAME                           READY   STATUS    RESTARTS   AGE   VERSION
nginx-deploy-5597c8b45-t5plt   1/1     Running   0          19s   v1.12
nginx-deploy-5597c8b45-tcq69   1/1     Running   0          19s   v1.12
nginx-deploy-5597c8b45-vdjxg   1/1     Running   0          19s   v1.12
nginx-deploy-5597c8b45-vqn9x   1/1     Running   0          19s   v1.12
nginx-deploy-5597c8b45-zl6qr   1/1     Running   0          19s   v1.12
---- 立刻创建5个新版本pod，Pending调度中
nginx-deploy-6bd88df699-242fr   0/1     Pending   0          0s    v1.13
nginx-deploy-6bd88df699-242fr   0/1     Pending   0          0s    v1.13
nginx-deploy-6bd88df699-8pmdg   0/1     Pending   0          0s    v1.13
nginx-deploy-6bd88df699-4kj8z   0/1     Pending   0          0s    v1.13
nginx-deploy-6bd88df699-n7x6n   0/1     Pending   0          0s    v1.13
nginx-deploy-6bd88df699-8pmdg   0/1     Pending   0          0s    v1.13
nginx-deploy-6bd88df699-4kj8z   0/1     Pending   0          0s    v1.13
nginx-deploy-6bd88df699-8j85n   0/1     Pending   0          0s    v1.13
nginx-deploy-6bd88df699-n7x6n   0/1     Pending   0          0s    v1.13
nginx-deploy-6bd88df699-8j85n   0/1     Pending   0          0s    v1.13
---- 创建pod中
nginx-deploy-6bd88df699-242fr   0/1     ContainerCreating   0          0s    v1.13
nginx-deploy-6bd88df699-8pmdg   0/1     ContainerCreating   0          0s    v1.13
nginx-deploy-6bd88df699-4kj8z   0/1     ContainerCreating   0          0s    v1.13
nginx-deploy-6bd88df699-n7x6n   0/1     ContainerCreating   0          0s    v1.13
nginx-deploy-6bd88df699-8j85n   0/1     ContainerCreating   0          0s    v1.13
---- 启动pod
nginx-deploy-6bd88df699-242fr   0/1     Running             0          1s    v1.13
nginx-deploy-6bd88df699-8j85n   0/1     Running             0          1s    v1.13
nginx-deploy-6bd88df699-4kj8z   0/1     Running             0          1s    v1.13
nginx-deploy-6bd88df699-n7x6n   0/1     Running             0          1s    v1.13
nginx-deploy-6bd88df699-8pmdg   0/1     Running             0          1s    v1.13
---- Pod逐个就绪，且替换旧版本的pod
nginx-deploy-6bd88df699-242fr   1/1     Running             0          6s    v1.13
nginx-deploy-5597c8b45-t5plt    1/1     Terminating         0          50s   v1.12
nginx-deploy-6bd88df699-8j85n   1/1     Running             0          7s    v1.13
nginx-deploy-5597c8b45-vdjxg    1/1     Terminating         0          51s   v1.12
nginx-deploy-5597c8b45-t5plt    0/1     Terminating         0          51s   v1.12
nginx-deploy-5597c8b45-t5plt    0/1     Terminating         0          51s   v1.12
nginx-deploy-6bd88df699-4kj8z   1/1     Running             0          7s    v1.13
nginx-deploy-5597c8b45-zl6qr    1/1     Terminating         0          51s   v1.12
nginx-deploy-5597c8b45-vdjxg    0/1     Terminating         0          52s   v1.12
nginx-deploy-5597c8b45-vdjxg    0/1     Terminating         0          52s   v1.12
nginx-deploy-5597c8b45-zl6qr    0/1     Terminating         0          53s   v1.12
nginx-deploy-5597c8b45-t5plt    0/1     Terminating         0          54s   v1.12
nginx-deploy-5597c8b45-t5plt    0/1     Terminating         0          54s   v1.12
nginx-deploy-5597c8b45-zl6qr    0/1     Terminating         0          56s   v1.12
nginx-deploy-5597c8b45-zl6qr    0/1     Terminating         0          56s   v1.12
nginx-deploy-6bd88df699-n7x6n   1/1     Running             0          13s   v1.13
nginx-deploy-5597c8b45-tcq69    1/1     Terminating         0          57s   v1.12
nginx-deploy-5597c8b45-tcq69    0/1     Terminating         0          58s   v1.12
nginx-deploy-5597c8b45-tcq69    0/1     Terminating         0          59s   v1.12
nginx-deploy-6bd88df699-8pmdg   1/1     Running             0          15s   v1.13
nginx-deploy-5597c8b45-vqn9x    1/1     Terminating         0          59s   v1.12
nginx-deploy-5597c8b45-vqn9x    0/1     Terminating         0          60s   v1.12
nginx-deploy-5597c8b45-vqn9x    0/1     Terminating         0          61s   v1.12
nginx-deploy-5597c8b45-vqn9x    0/1     Terminating         0          61s   v1.12
nginx-deploy-5597c8b45-vdjxg    0/1     Terminating         0          64s   v1.12
nginx-deploy-5597c8b45-vdjxg    0/1     Terminating         0          64s   v1.12
nginx-deploy-5597c8b45-tcq69    0/1     Terminating         0          64s   v1.12
nginx-deploy-5597c8b45-tcq69    0/1     Terminating         0          64s   v1.12
```

#### 3. 滚动发布

通过定义 maxsurge 和 maxUnavailable 来实现滚动升级的速度，滚动升级中，可以使用 kubectl rollout pause 来实现暂停。

```bash
[root@hdss7-200 deployment]# vim /data/k8s-yaml/base_resource/deployment/nginx-v1.14.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deploy
  namespace: app
spec:
  replicas: 5
  selector:
    matchLabels:
      app: nginx
      release: stable
      tier: slb
      partition: website
  strategy:
    rollingUpdate:
      # 以下两项，控制升级速度
      maxSurge: 1
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: nginx
        release: stable
        tier: slb
        partition: website
        # 修改版本
        version: v1.14
    spec:
      containers:
      - name: nginx-pod
        # 修改镜像版本
        image: harbor.od.com/public/nginx:v1.14
        lifecycle:
          postStart:
            exec:
              command:
                - /bin/bash
                - -c
                - "echo 'health check ok!' > /usr/share/nginx/html/health.html"
        readinessProbe: 
          initialDelaySeconds: 5
          httpGet:
            port: 80
            path: /health.html
        livenessProbe:
          initialDelaySeconds: 10
          periodSeconds: 5
          httpGet:
            port: 80
            path: /health.html
```



```bash
[root@hdss7-21 ~]# kubectl apply --filename=http://k8s-yaml.od.com/base_resource/deployment/nginx-v1.14.yaml --record=true
[root@hdss7-21 ~]# kubectl get rs -n app -l tier=slb -L version  # replicaset 数量增加
NAME                      DESIRED   CURRENT   READY   AGE    VERSION
nginx-deploy-5597c8b45    0         0         0       155m   v1.12
nginx-deploy-6bd88df699   0         0         0       154m   v1.13
nginx-deploy-7c5976dcd9   5         5         5       83s    v1.14
[root@hdss7-21 ~]# kubectl rollout history deployment nginx-deploy -n app # 升级记录
REVISION  CHANGE-CAUSE
1         kubectl apply --filename=http://k8s-yaml.od.com/base_resource/deployment/nginx-v1.12.yaml --record=true
2         kubectl apply --filename=http://k8s-yaml.od.com/base_resource/deployment/nginx-v1.13.yaml --record=true
3         kubectl apply --filename=http://k8s-yaml.od.com/base_resource/deployment/nginx-v1.14.yaml --record=true
```



```bash
[root@hdss7-21 ~]# kubectl get pod -n app -l partition=website -L version -w  # 逐个滚动升级
NAME                            READY   STATUS    RESTARTS   AGE    VERSION
nginx-deploy-6bd88df699-242fr   1/1     Running   0          152m   v1.13
nginx-deploy-6bd88df699-4kj8z   1/1     Running   0          152m   v1.13
nginx-deploy-6bd88df699-8j85n   1/1     Running   0          152m   v1.13
nginx-deploy-6bd88df699-8pmdg   1/1     Running   0          152m   v1.13
nginx-deploy-6bd88df699-n7x6n   1/1     Running   0          152m   v1.13
nginx-deploy-7c5976dcd9-ttlqx   0/1     Pending   0          0s     v1.14
nginx-deploy-7c5976dcd9-ttlqx   0/1     Pending   0          0s     v1.14
nginx-deploy-7c5976dcd9-ttlqx   0/1     ContainerCreating   0          0s     v1.14
nginx-deploy-7c5976dcd9-ttlqx   0/1     Running             0          1s     v1.14
nginx-deploy-7c5976dcd9-ttlqx   1/1     Running             0          9s     v1.14
nginx-deploy-6bd88df699-8pmdg   1/1     Terminating         0          153m   v1.13
......
```



#### 4. 模拟灰度(金丝雀)发布

灰度发布在不同场景中实现方式不同，如果当前灰度机器仅对测试开放，可以定义一个新的deployment来配合service来实现。如果需要切入一部分随机真实用户的流量，可以将生产机器中一台机器作为灰度机器，通过灰度后再升级其它的机器。

```bash
# nginx-v1.15.yaml 与 nginx-v1.14.yaml 一致，仅仅修改了镜像文件
[root@hdss7-21 ~]# kubectl apply --filename=http://k8s-yaml.od.com/base_resource/deployment/nginx-v1.15.yaml --record=true && kubectl rollout pause deployment nginx-deploy -n app
[root@hdss7-21 ~]# kubectl rollout history deployment nginx-deploy -n app
REVISION  CHANGE-CAUSE
1         kubectl apply --filename=http://k8s-yaml.od.com/base_resource/deployment/nginx-v1.12.yaml --record=true
2         kubectl apply --filename=http://k8s-yaml.od.com/base_resource/deployment/nginx-v1.13.yaml --record=true
3         kubectl apply --filename=http://k8s-yaml.od.com/base_resource/deployment/nginx-v1.14.yaml --record=true
4         kubectl apply --filename=http://k8s-yaml.od.com/base_resource/deployment/nginx-v1.15.yaml --record=true
[root@hdss7-21 ~]# kubectl get rs -n app -l tier=slb -L version  # 存在两个ReplicaSet对外提供服务
NAME                      DESIRED   CURRENT   READY   AGE     VERSION
nginx-deploy-5597c8b45    0         0         0       177m    v1.12
nginx-deploy-6695fd9655   1         1         1       2m22s   v1.15
nginx-deploy-6bd88df699   0         0         0       176m    v1.13
nginx-deploy-7c5976dcd9   5         5         5       23m     v1.14
[root@hdss7-21 ~]# kubectl get pod -n app -l partition=website -L version -w # 新老共存
NAME                            READY   STATUS    RESTARTS   AGE   VERSION
nginx-deploy-6695fd9655-tcm76   1/1     Running   0          17s   v1.15
nginx-deploy-7c5976dcd9-4tnv4   1/1     Running   0          21m   v1.14
nginx-deploy-7c5976dcd9-bpjc2   1/1     Running   0          20m   v1.14
nginx-deploy-7c5976dcd9-gv8qm   1/1     Running   0          20m   v1.14
nginx-deploy-7c5976dcd9-ttlqx   1/1     Running   0          21m   v1.14
nginx-deploy-7c5976dcd9-xq2qs   1/1     Running   0          21m   v1.14
```



```bash
# 手动暂停
[root@hdss7-21 ~]# kubectl rollout resume deployment nginx-deploy -n app && kubectl rollout pause deployment nginx-deploy -n app
[root@hdss7-21 ~]# kubectl get pod -n app -l partition=website -L version -w
NAME                            READY   STATUS    RESTARTS   AGE     VERSION
nginx-deploy-6695fd9655-jmb94   1/1     Running   0          19s     v1.15
nginx-deploy-6695fd9655-tcm76   1/1     Running   0          6m19s   v1.15
nginx-deploy-7c5976dcd9-4tnv4   1/1     Running   0          27m     v1.14
nginx-deploy-7c5976dcd9-gv8qm   1/1     Running   0          26m     v1.14
nginx-deploy-7c5976dcd9-ttlqx   1/1     Running   0          27m     v1.14
nginx-deploy-7c5976dcd9-xq2qs   1/1     Running   0          27m     v1.14
# 升级剩余所有机器
[root@hdss7-21 ~]# kubectl rollout resume deployment nginx-deploy -n app
```

#### 5. 版本回滚

当升级出现异常时，执行回滚即可。

```bash
[root@hdss7-21 ~]# kubectl rollout history deployment nginx-deploy -n app # 查看历史版本记录
deployment.extensions/nginx-deploy 
REVISION  CHANGE-CAUSE
1         kubectl apply --filename=http://k8s-yaml.od.com/base_resource/deployment/nginx-v1.12.yaml --record=true
2         kubectl apply --filename=http://k8s-yaml.od.com/base_resource/deployment/nginx-v1.13.yaml --record=true
3         kubectl apply --filename=http://k8s-yaml.od.com/base_resource/deployment/nginx-v1.14.yaml --record=true
4         kubectl apply --filename=http://k8s-yaml.od.com/base_resource/deployment/nginx-v1.15.yaml --record=true
[root@hdss7-21 ~]# kubectl rollout undo deployment nginx-deploy -n app
[root@hdss7-21 ~]# kubectl rollout history deployment nginx-deploy -n app # 版本3已经被版本5替代
deployment.extensions/nginx-deploy 
REVISION  CHANGE-CAUSE
1         kubectl apply --filename=http://k8s-yaml.od.com/base_resource/deployment/nginx-v1.12.yaml --record=true
2         kubectl apply --filename=http://k8s-yaml.od.com/base_resource/deployment/nginx-v1.13.yaml --record=true
4         kubectl apply --filename=http://k8s-yaml.od.com/base_resource/deployment/nginx-v1.15.yaml --record=true
5         kubectl apply --filename=http://k8s-yaml.od.com/base_resource/deployment/nginx-v1.14.yaml --record=true
[root@hdss7-21 ~]# kubectl get pod -n app -l partition=website -L version 
NAME                            READY   STATUS    RESTARTS   AGE     VERSION
nginx-deploy-7c5976dcd9-2kps8   1/1     Running   0          2m20s   v1.14
nginx-deploy-7c5976dcd9-bqs28   1/1     Running   0          2m6s    v1.14
nginx-deploy-7c5976dcd9-jdvps   1/1     Running   0          2m13s   v1.14
nginx-deploy-7c5976dcd9-vs8l4   1/1     Running   0          116s    v1.14
nginx-deploy-7c5976dcd9-z99mb   1/1     Running   0          101s    v1.14
[root@hdss7-21 ~]# kubectl get rs -n app -l tier=slb -L version
NAME                      DESIRED   CURRENT   READY   AGE    VERSION
nginx-deploy-5597c8b45    0         0         0       3h7m   v1.12
nginx-deploy-6695fd9655   0         0         0       12m    v1.15
nginx-deploy-6bd88df699   0         0         0       3h7m   v1.13
nginx-deploy-7c5976dcd9   5         5         5       34m    v1.14
```

#### 6.  常用命令

```bash
kubectl rollout status deployment nginx-deploy -n app  # 查看版本升级过程
kubectl rollout history deployment nginx-deploy -n app # 查看版本升级历史
kubectl apply -f http://k8s-yaml.od.com/base_resource/deployment/nginx-v1.15.yaml --record=true  # 升级且记录升级命令
kubectl rollout undo deployment nginx-deploy -n app    # 回滚到上个版本
kubectl rollout undo deployment nginx-deploy --to-revision=3 -n app # 回滚到版本3
```

