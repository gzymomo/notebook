## 1. Pod

### 1.1. Pod介绍

#### 1.1.1. Pod简介

Pod 是 Kubernetes 的基本构建块，它是 Kubernetes 对象模型中创建或部署的最小和最简单的单元。 Pod 表示集群上正在运行的进程。Pod 封装了应用程序容器（或者在某些情况下封装多个容器）、存储资源、唯一网络 IP 以及控制容器应该如何运行的选项。 Pod 表示部署单元：*Kubernetes 中应用程序的单个实例*，它可能由单个容器或少量紧密耦合并共享资源的容器组成。

一个pod内部一般仅运行一个pod，也可以运行多个pod，如果存在多个pod时，其中一个为主容器，其它作为辅助容器，也被称为边车模式。同一个pod共享一个网络名称空间和外部存储卷。

![image.png](https://cdn.nlark.com/yuque/0/2020/png/378176/1579339190487-a1f2c303-a092-4f16-a7e2-2bba306fe3d2.png)

#### 1.1.2. Pod生命周期

Pod的生命周期中可以经历多个阶段，在一个Pod中在主容器(Main Container)启动前可以由init container来完成一些初始化操作。初始化完毕后，init Container 退出，Main Container启动。

在主容器启动后可以执行一些特定的指令，称为启动后钩子(PostStart)，在主容器退出前也可以执行一些特殊指令完成清理工作，称为结束前钩子(PreStop)。

在主容器工作周期内，并不是刚创建就能对外提供服务，容器内部可能需要加载相关配置，因此可以使用特定命令确定容器是否就绪，称为就绪性检测(ReadinessProbe)，完成就绪性检测才能成为Ready状态。

主容器对外提供服务后，可能出现意外导致容器异常，虽然此时容器仍在运行，但是不具备对外提供业务的能力，因此需要对其做存活性探测(LivenessProbe)。

![image.png](https://cdn.nlark.com/yuque/0/2020/png/378176/1579445077801-c30c2449-41d5-43e6-9892-025fbcf78aaf.png?x-oss-process=image%2Fwatermark%2Ctype_d3F5LW1pY3JvaGVp%2Csize_10%2Ctext_TGludXgt5rih5rih6bif%2Ccolor_FFFFFF%2Cshadow_50%2Ct_80%2Cg_se%2Cx_10%2Cy_10)

#### 1.1.3. Pod状态

- Pending: Pod 已被 Kubernetes 系统接受，但有一个或者多个容器尚未创建。
- Running: 该 Pod 已经绑定到了一个节点上，Pod 中所有的容器都已被创建。至少有一个容器正在运行，或者正处于启动或重启状态。
- Succeeded: Pod 中的所有容器都被成功终止，并且不会再重启。
- Failed: Pod 中的所有容器都已终止了，并且至少有一个容器是因为失败终止。
- Unknown: 因为某些原因无法取得 Pod 的状态，通常是因为与 Pod 所在主机通信失败。

![image](https://cdn.nlark.com/yuque/0/2020/jpeg/378176/1579446234452-ef9fedb8-e923-4aef-a8c3-6862d4729009.jpeg?x-oss-process=image%2Fwatermark%2Ctype_d3F5LW1pY3JvaGVp%2Csize_14%2Ctext_TGludXgt5rih5rih6bif%2Ccolor_FFFFFF%2Cshadow_50%2Ct_80%2Cg_se%2Cx_10%2Cy_10%2Fresize%2Cw_1500)

### 1.2. Pod清单

#### 1.2.1. apiversion/kind

```
apiVersion: v1
kind: Pod
```

#### 1.2.2. metadata

```
metadata
    name        <string>            # 在一个名称空间内不能重复
    namespace   <string>            # 指定名称空间，默认defalut
    labels      <map[string]string> # 标签
    annotations <map[string]string> # 注释，不能作为被筛选
```

#### 1.2.3. spec

```
spec
    containers  <[]Object> -required-   # 必选参数
        name    <string> -required-     # 指定容器名称，不可更新
        image   <string> -required-     # 指定镜像
        imagePullPolicy <string>        # 指定镜像拉取方式
            # Always: 始终从registory拉取镜像。如果镜像标签为latest，则默认值为Always
            # Never: 仅使用本地镜像
            # IfNotPresent: 本地不存在镜像时才去registory拉取。默认值
        env     <[]Object>              # 指定环境变量，使用 $(var) 引用,参考: configmap中模板
        command <[]string>              # 以数组方式指定容器运行指令，替代docker的ENTRYPOINT指令
        args    <[]string>              # 以数组方式指定容器运行参数，替代docker的CMD指令
        ports   <[]Object>              # 指定容器暴露的端口
            containerPort <integer> -required-  # 容器的监听端口
            name    <string>            # 为端口取名，该名称可以在service种被引用
            protocol  <string>          # 指定协议，默认TCP
            hostIP    <string>          # 绑定到宿主机的某个IP
            hostPort  <integer>         # 绑定到宿主机的端口
        readinessProbe <Object>         # 就绪性探测，确认就绪后提供服务
            initialDelaySeconds <integer>   # 容器启动后到开始就绪性探测中间的等待秒数
            periodSeconds <integer>     # 两次探测的间隔多少秒，默认值为10
            successThreshold <integer>  # 连续多少次检测成功认为容器正常，默认值为1。不支持修改
            failureThreshold <integer>  # 连续多少次检测成功认为容器异常，默认值为3
            timeoutSeconds   <integer>  # 探测请求超时时间
            exec    <Object>            # 通过执行特定命令来探测容器健康状态
                command <[]string>      # 执行命令，返回值为0表示健康，不自持shell模式
            tcpSocket <Object>          # 检测TCP套接字
                host <string>           # 指定检测地址，默认pod的IP
                port <string> -required-# 指定检测端口
            httpGet <Object>            # 以HTTP请求方式检测
                host    <string>        # 指定检测地址，默认pod的IP
                httpHeaders <[]Object>  # 设置请求头
                path    <string>        # 设置请求的location
                port <string> -required-# 指定检测端口
                scheme <string>         # 指定协议，默认HTTP
        livenessProbe   <Object>        # 存活性探测，确认pod是否具备对外服务的能力
            # 该对象中字段和readinessProbe一致
        lifecycle       <Object>        # 生命周期
            postStart   <Object>        # pod启动后钩子，执行指令或者检测失败则退出容器或者重启容器
                exec    <Object>        # 执行指令，参考readinessProbe.exec
                httpGet <Object>        # 执行HTTP，参考readinessProbe.httpGet
                tcpSocket <Object>      # 检测TCP套接字，参考readinessProbe.tcpSocket
            preStop     <Object>        # pod停止前钩子，停止前执行清理工作
                # 该对象中字段和postStart一致
    hostname    <string>                # 指定pod主机名
    nodeName    <string>                # 调度到指定的node节点
    nodeSelector    <map[string]string> # 指定预选的node节点
    hostIPC <boolean>                   # 使用宿主机的IPC名称空间，默认false
    hostNetwork <boolean>               # 使用宿主机的网络名称空间，默认false
    serviceAccountName  <string>        # Pod运行时的服务账号
    imagePullSecrets    <[]Object>      # 当拉取私密仓库镜像时，需要指定的密码密钥信息
        name            <string>        # secrets 对象名
```

#### 1.2.4. k8s和image中的命令

![image.png](https://cdn.nlark.com/yuque/0/2020/png/378176/1579444125794-e27d08bb-7811-44c1-806b-86745f8f9093.png)

#### 1.2.4. 就绪性探测和存活性探测

- 就绪性探测失败不会重启pod，只是让pod不处于ready状态。存活性探测失败会触发pod重启。
- 就绪性探测和存活性探测会持续进行下去，直到pod终止。



### 1.3. 案例

**一般不会单独创建pod，而是通过控制器的方式创建。**

#### 1.3.1. 创建简单pod

```
apiVersion: v1
kind: Pod
metadata:
  name: pod-demo
  namespace: app
  labels:
    app: centos7
    release: stable
    environment: dev
spec:
  containers:
  - name: centos
    image: harbor.od.com/public/centos:7
    command:
    - /bin/bash
    - -c
    - "sleep 3600"
```



```
[root@hdss7-21 ~]# kubectl apply -f http://k8s-yaml.od.com/base_resource/pods/myapp.yaml
[root@hdss7-21 ~]# kubectl get pod -o wide -n app
NAME       READY   STATUS    RESTARTS   AGE   IP           NODE                NOMINATED NODE   READINESS GATES
pod-demo   1/1     Running   0          16s   172.7.22.2   hdss7-22.host.com   <none>           <none>
[root@hdss7-21 ~]# kubectl exec pod-demo -n app -- ps uax
USER        PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root          1  0.0  0.0   4364   352 ?        Ss   04:41   0:00 sleep 3600
root         11  0.0  0.0  51752  1696 ?        Rs   04:42   0:00 ps uax
```



```
[root@hdss7-21 ~]# kubectl describe pod pod-demo -n app | tail
Events:
  Type    Reason     Age    From                        Message
  ----    ------     ----   ----                        -------
  Normal  Scheduled  3m46s  default-scheduler           Successfully assigned app/pod-demo to hdss7-22.host.com
  Normal  Pulling    3m45s  kubelet, hdss7-22.host.com  Pulling image "harbor.od.com/public/centos:7"
  Normal  Pulled     3m45s  kubelet, hdss7-22.host.com  Successfully pulled image "harbor.od.com/public/centos:7"
  Normal  Created    3m45s  kubelet, hdss7-22.host.com  Created container centos
  Normal  Started    3m45s  kubelet, hdss7-22.host.com  Started container centos
```

#### 1.3.2. 带健康检测的pod

```
apiVersion: v1
kind: Pod
metadata:
  name: pod-01
  namespace: app
  labels:
    app: centos7
    release: stable
    version: t1
spec:
  containers:
  - name: centos
    image: harbor.od.com/public/centos:7
    command:
    - /bin/bash
    - -c
    - "echo 'abc' > /tmp/health;sleep 60;rm -f /tmp/health;sleep 600"
    livenessProbe:
      exec:
        command:
        - /bin/bash
        - -c
        - "[ -f /tmp/health ]"
```



## 2. Deployment

### 2.1. 介绍

#### 2.1.1. 简介

Pod控制器有很多种，最初的是使用 ReplicationController，即副本控制器，用于控制pod数量。随着版本升级，出现了ReplicaSet，跟ReplicationController没有本质的不同，只是名字不一样，并且ReplicaSet支持集合式的selector。ReplicaSet的核心管理对象有三种：用户期望的副本数、标签选择器、pod模板。

ReplicaSet一般不会直接使用，而是采用Deployment，Deployment是用来管理Replicaset，ReplicaSet来管理Pod。Deployment为ReplicaSet 提供了一个声明式定义(declarative)方法，用来替代以前的 ReplicationController 来方便的管理应用，比ReplicaSet的功能更加强大，且包含了ReplicaSet的功能。Deployment支持以下功能：

- 定义Deployment来创建Pod和ReplicaSet
- 滚动升级和回滚应用
- 扩容和缩容
- 暂停部署功能和手动部署

#### 2.1.2. 部署方式

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

#### 2.1.3. Deployment升级方案

Deployment的升级方案默认是滚动升级，支持升级暂停，支持指定最大超过预期pod数量，支持指定最小低于预期pod数量。可以实现上述三种部署方案(以目标预期pod数量5个，v1版本升级到v2版本为案例)：

- 蓝绿发布场景实现方案：新创建5个v2版本pod，等待5个v2版本Pod就绪后，下掉5个v1版本pod。
- 灰度发布场景实现案例：新创建的第一个pod最为灰度pod，此时暂定升级，等待灰度成功后再升级v1版本Pod
- 滚动发布：通过控制超出预期pod数量和低于预期Pod数量来控制滚动发布的节奏。

如下图，预期pod数量5个，滚动升级，最大超出副本数为2个，最大低于期望值2个的升级方式：

![image.png](https://cdn.nlark.com/yuque/0/2020/png/378176/1579612087811-c8985d4d-1032-4a26-baca-a8a7555bc024.png?x-oss-process=image%2Fwatermark%2Ctype_d3F5LW1pY3JvaGVp%2Csize_10%2Ctext_TGludXgt5rih5rih6bif%2Ccolor_FFFFFF%2Cshadow_50%2Ct_80%2Cg_se%2Cx_10%2Cy_10)

### 2.2. 模板

```
apiVersion: apps/v1
kind: Deployment
metadata
    name        <string>            # 在一个名称空间不能重复
    namespace   <string>            # 指定名称空间，默认defalut
    labels      <map[string]string> # 标签
    annotations <map[string]string> # 注释
```



```
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

### 2.3. 案例

#### 2.3.1. 创建deployment

```
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



```
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

#### 2.3.2. 模拟蓝绿发布

```
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



```
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



```
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

#### 2.3.3. 滚动发布

通过定义 maxsurge 和 maxUnavailable 来实现滚动升级的速度，滚动升级中，可以使用 kubectl rollout pause 来实现暂停。

```
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



```
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



```
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



#### 2.3.4. 模拟灰度(金丝雀)发布

灰度发布在不同场景中实现方式不同，如果当前灰度机器仅对测试开放，可以定义一个新的deployment来配合service来实现。如果需要切入一部分随机真实用户的流量，可以将生产机器中一台机器作为灰度机器，通过灰度后再升级其它的机器。

```
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



```
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

#### 2.3.5. 版本回滚

当升级出现异常时，执行回滚即可。

```
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

#### 2.3.6.  常用命令

```
kubectl rollout status deployment nginx-deploy -n app  # 查看版本升级过程
kubectl rollout history deployment nginx-deploy -n app # 查看版本升级历史
kubectl apply -f http://k8s-yaml.od.com/base_resource/deployment/nginx-v1.15.yaml --record=true  # 升级且记录升级命令
kubectl rollout undo deployment nginx-deploy -n app    # 回滚到上个版本
kubectl rollout undo deployment nginx-deploy --to-revision=3 -n app # 回滚到版本3
```



## 3. DaemonSet

### 3.1. DaemonSet介绍

DaemonSet 确保全部（或者一些）Node 上运行一个 Pod 的副本。当有 Node 加入集群时，也会为他们新增一个 Pod 。当有 Node 从集群移除时，这些 Pod 也会被回收。删除 DaemonSet 将会删除它创建的所有 Pod。使用 DaemonSet 的一些典型用法：

- 运行集群存储 daemon，例如在每个 Node 上运行 glusterd、ceph。
- 在每个 Node 上运行日志收集 daemon，例如fluentd、logstash。
- 在每个 Node 上运行监控 daemon，例如 Prometheus Node Exporter。

### 3.2. 模板

```
apiVersion: apps/v1
kind: DaemonSet
metadata
    name        <string>            # 在一个名称空间不能重复
    namespace   <string>            # 指定名称空间，默认defalut
    labels      <map[string]string> # 标签
    annotations <map[string]string> # 注释
spec
    selector                    <Object>            # 标签选择器
        matchExpressions        <[]Object>          # 标签选择器的一种形式,多个条件使用AND连接
            key                 <string> -required- # 标签中的Key
            operator            <string> -required- # 操作符，支持 In, NotIn, Exists, DoesNotExist
            values              <[]string>          # value的数组集合，当操作符为In或NotIn时不能为空
        matchLabels             <map[string]string> # 使用key/value的格式做筛选
    updateStrategy              <Object>            # 更新策略
        type                    <string>            # 更新类型，支持 Recreate, RollingUpdate。默认RollingUpdate
        rollingUpdate           <Object>            # 滚动更新策略，仅在type为RollingUpdate时使用
            maxUnavailable      <string>            # 最大缺失Pod数，即滚动更新时最多可少于期望值出几个pod。支持数字和百分比格式
    template                    <Object> -required- # Pod模板，和Pod管理器yaml几乎格式一致
        metadata                <Object>            # Pod的metadata
        spec                    <Object>            # Pod的spec
```

### 3.3. 案例

#### 3.3.1. 创建daemonset

```
[root@hdss7-200 base_resource]# cat /data/k8s-yaml/base_resource/daemonset/proxy-v1.12.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: proxy-daemonset
  namespace: app
  labels:
      app: nginx
      release: stable
      partition: CRM
spec:
  selector:
    matchLabels:
      app: nginx
      release: stable
      tier: proxy
      partition: CRM
  updateStrategy:
    rollingUpdate:
      maxUnavailable: 1
  template:
    metadata:
      labels:
        app: nginx
        release: stable
        tier: proxy
        partition: CRM
        version: v1.12
    spec:
      containers:
      - name: nginx-proxy
        image: harbor.od.com/public/nginx:v1.12
        ports:
        - name: http
          containerPort: 80
          hostPort: 10080
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



```
[root@hdss7-21 ~]# kubectl apply -f  http://k8s-yaml.od.com/base_resource/daemonset/proxy-v1.12.yaml --record
[root@hdss7-21 ~]# kubectl get daemonset -n app
NAME              DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
proxy-daemonset   2         2         2       2            2           <none>          56s
```



```
[root@hdss7-21 ~]# kubectl get pod -n app -l tier=proxy -o wide
NAME                    READY   STATUS    RESTARTS   AGE     IP            NODE                NOMINATED NODE   READINESS GATES
proxy-daemonset-7stgs   1/1     Running   0          8m31s   172.7.22.9    hdss7-22.host.com   <none>           <none>
proxy-daemonset-dxgdp   1/1     Running   0          8m31s   172.7.21.10   hdss7-21.host.com   <none>           <none>
[root@hdss7-21 ~]# curl -s 10.4.7.22:10080/info  # 通过宿主机的端口访问
2020-01-22T13:15:58+00:00|172.7.22.9|nginx:v1.12
[root@hdss7-21 ~]# curl -s 10.4.7.21:10080/info
2020-01-22T13:16:05+00:00|172.7.21.10|nginx:v1.12
```

#### 3.3.2. 升级daemonset

daemonset的升级方式和deployment一致

```
[root@hdss7-21 ~]# kubectl rollout history daemonset proxy-daemonset -n app
REVISION  CHANGE-CAUSE
1         kubectl apply --filename=http://k8s-yaml.od.com/base_resource/daemonset/proxy-v1.12.yaml --record=true

[root@hdss7-21 ~]# kubectl apply -f  http://k8s-yaml.od.com/base_resource/daemonset/proxy-v1.13.yaml --record

[root@hdss7-21 ~]# kubectl rollout history daemonset proxy-daemonset -n app
daemonset.extensions/proxy-daemonset 
REVISION  CHANGE-CAUSE
1         kubectl apply --filename=http://k8s-yaml.od.com/base_resource/daemonset/proxy-v1.12.yaml --record=true
2         kubectl apply --filename=http://k8s-yaml.od.com/base_resource/daemonset/proxy-v1.13.yaml --record=true
[root@hdss7-21 ~]# kubectl get pod -n app -l tier=proxy -L version
NAME                    READY   STATUS    RESTARTS   AGE     VERSION
proxy-daemonset-7wr4f   1/1     Running   0          119s    v1.13
proxy-daemonset-clhqk   1/1     Running   0          2m11s   v1.13
```