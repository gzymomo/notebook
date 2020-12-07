# 1、Ingress

Kubernetes 提供了两种内建的云端负载均衡机制（ cloud load balancing ）用于发布公共应用， 工作于传输层的 Service 资源，它实现的是 TCP 负载均衡器”，另种是Ingress 资源，它 现的是“ HTTP(S ）负载均衡器”



**Ingress和Ingress Controller**

Ingress是Kubernetes API的标准资源类型之一，它其实就是基于DNS名称(host)或URL路径把请求转发至指定的Service资源的规则，用于将集群外部的请求流量转发至集群内部完成服务发布。然而，**Ingess资源自身并不能运行“流量穿透”，它仅仅是一组路由规则的集合，这些规则要想真正发挥作用还需其它功能的辅助，如监听某个套接字上，根据这些规则匹配机制路由请求流量：这种能够为Ingress资源监听套接字并转发流量的组件称之为Ingress控制器**

注意：
**不同于 Deployment 控制器等 Ingress 控制器并不直接运行为 kube-controller-rnanager的一部 ，它是Kubemetes集群的重要附件类似于 CoreDNS 需要在集群单独部署**



Ingress不是Kubernetes内置的，需要单独安装应用，来做负载均衡。



将端口号对外暴露，通过IP+端口号进行访问。

- 使用Service里面的NodePort可以实现。



NodePort缺陷：

- 在每个节点上都会起到端口，在访问时候通过任何节点，通过节点ip+暴露端口号实现访问。
- 意味着每个端口只能使用一次，一个端口对应一个应用。
- 实际访问中都是用域名，根据不同域名跳转到不同端口服务中。



## 1.1 Ingress和Pod关系

- pod和ingress通过service关联的
  - ingress作为统一入口，由service关联一组pod



![](..\..\img\ingress.png)



## 1.2 Ingress工作流程

![](..\..\img\ingress1.png)



## 1.3 使用ingress步骤

1. 部署ingress controller（选择官方nginx控制器，实现部署） 

```bash

```



2. 创建ingress规则

```bash

```



## 1.4 使用ingress对外暴露应用

1. 创建nginx应用，对外暴露端口使用NodePort

```bash
# 创建pod
kubectl create deployment web --image=nginx

# 查看
kubectl get pods

# 创建service
kubectl expose deployment web --port=80 --target-port=80 --type=NodePort
```

2. 部署ingress controller

```bash
kubectl apply -f ingress-con.yaml

# 查看ingress controller状态
kubectl get pods -n ingress-nginx
```

3. 创建ingress规则

```yaml
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
meatadata:
  name: example-ingress
spec:
  rules:
  - host: example.ingredemo.com
    http:
      paths:
      - path: /
        backend:
          serviceName: web
          servicePort: 80
```



保存后，然后执行

```bash
# 创建ingress规则
kubectl applf -f ingress-http.yaml
```



查看在那个节点：

```bash
kubectl get pods -n ingress-nginx -o wide
```



# 2、[Kubernetes Ingress-nginx使用](https://www.cnblogs.com/precipitation/p/14079472.html)

## 3.1 部署Ingress-Controller

[官方地址](https://kubernetes.github.io/ingress-nginx/deploy/)

此处部署3.0版本

在你需要部署的node节点上拉去Ingerss-Controller镜像

```bash
[root@k8s-master01 daem]# docker pull quay.io/kubernetes-ingress-controller/nginx-ingress-controller:0.30.0
```

**进入到GitHub上将mandatory.yaml复制到node节点上**

[mandatory.yaml地址](https://github.com/kubernetes/ingress-nginx/tree/nginx-0.30.0/deploy/static)

```yaml
[root@k8s-master01 ingressdeploy]# cat mandatory.yaml 
apiVersion: v1
kind: Namespace
metadata:
  name: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx

---

kind: ConfigMap
apiVersion: v1
metadata:
  name: nginx-configuration
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
#data:
#  whitelist-source-range: 192.168.29.102 #白名单，允许某个IP或IP段的访问
#  block-cidrs: 192.168.29.101 #黑名单拒绝访问

---
kind: ConfigMap
apiVersion: v1
metadata:
  name: tcp-services
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx

---
kind: ConfigMap
apiVersion: v1
metadata:
  name: udp-services
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx

---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: nginx-ingress-serviceaccount
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx

---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  name: nginx-ingress-clusterrole
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
rules:
  - apiGroups:
      - ""
    resources:
      - configmaps
      - endpoints
      - nodes
      - pods
      - secrets
    verbs:
      - list
      - watch
  - apiGroups:
      - ""
    resources:
      - nodes
    verbs:
      - get
  - apiGroups:
      - ""
    resources:
      - services
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - ""
    resources:
      - events
    verbs:
      - create
      - patch
  - apiGroups:
      - "extensions"
      - "networking.k8s.io"
    resources:
      - ingresses
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - "extensions"
      - "networking.k8s.io"
    resources:
      - ingresses/status
    verbs:
      - update

---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: Role
metadata:
  name: nginx-ingress-role
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
rules:
  - apiGroups:
      - ""
    resources:
      - configmaps
      - pods
      - secrets
      - namespaces
    verbs:
      - get
  - apiGroups:
      - ""
    resources:
      - configmaps
    resourceNames:
      # Defaults to "<election-id>-<ingress-class>"
      # Here: "<ingress-controller-leader>-<nginx>"
      # This has to be adapted if you change either parameter
      # when launching the nginx-ingress-controller.
      - "ingress-controller-leader-nginx"
    verbs:
      - get
      - update
  - apiGroups:
      - ""
    resources:
      - configmaps
    verbs:
      - create
  - apiGroups:
      - ""
    resources:
      - endpoints
    verbs:
      - get

---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: RoleBinding
metadata:
  name: nginx-ingress-role-nisa-binding
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: nginx-ingress-role
subjects:
  - kind: ServiceAccount
    name: nginx-ingress-serviceaccount
    namespace: ingress-nginx

---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: nginx-ingress-clusterrole-nisa-binding
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: nginx-ingress-clusterrole
subjects:
  - kind: ServiceAccount
    name: nginx-ingress-serviceaccount
    namespace: ingress-nginx

---

apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-ingress-controller
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: ingress-nginx
      app.kubernetes.io/part-of: ingress-nginx
  template:
    metadata:
      labels:
        app.kubernetes.io/name: ingress-nginx
        app.kubernetes.io/part-of: ingress-nginx
      annotations:
        prometheus.io/port: "10254"
        prometheus.io/scrape: "true"
    spec:
      hostNetwork: true      ###修改成hostNetwork模式直接共享服务器的网络名称空间
      # wait up to five minutes for the drain of connections
      terminationGracePeriodSeconds: 300
      serviceAccountName: nginx-ingress-serviceaccount
      nodeSelector:
        kubernetes.io/os: linux
        kubernetes.io/hostname: k8s-master02
      dnsPolicy: ClusterFirstWithHostNet
      containers:
        - name: nginx-ingress-controller
          imagePullPolicy: IfNotPresent 
          image: quay.io/kubernetes-ingress-controller/nginx-ingress-controller:0.30.0
          args:
            - /nginx-ingress-controller
            - --configmap=$(POD_NAMESPACE)/nginx-configuration
            - --tcp-services-configmap=$(POD_NAMESPACE)/tcp-services
            - --udp-services-configmap=$(POD_NAMESPACE)/udp-services
            - --publish-service=$(POD_NAMESPACE)/ingress-nginx
            - --annotations-prefix=nginx.ingress.kubernetes.io
          securityContext:
            allowPrivilegeEscalation: true
            capabilities:
              drop:
                - ALL
              add:
                - NET_BIND_SERVICE
            # www-data -> 101
            runAsUser: 101
          env:
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: POD_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
          ports:
            - name: http
              containerPort: 80
              protocol: TCP
              #hostPort: 80
            - name: https
              containerPort: 443
              protocol: TCP
              #hostPort: 443
          livenessProbe:
            failureThreshold: 3
            httpGet:
              path: /healthz
              port: 10254
              scheme: HTTP
            initialDelaySeconds: 10
            periodSeconds: 10
            successThreshold: 1
            timeoutSeconds: 10
          readinessProbe:
            failureThreshold: 3
            httpGet:
              path: /healthz
              port: 10254
              scheme: HTTP
            periodSeconds: 10
            successThreshold: 1
            timeoutSeconds: 10
          lifecycle:
            preStop:
              exec:
                command:
                  - /wait-shutdown

---

apiVersion: v1
kind: LimitRange
metadata:
  name: ingress-nginx
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
spec:
  limits:
  - min:
      memory: 90Mi
      cpu: 100m
    type: Container
```

需修改：
hostNetwork: true ###修改成hostNetwork模式直接共享服务器的网络名称空间

执行create创建Ingress-Controller

```bash
[root@k8s-master01 ingressdeploy]# kubectl get deploy -n ingress-nginx
NAME                       READY   UP-TO-DATE   AVAILABLE   AGE
nginx-ingress-controller   1/1     1            1           76m
```

Ingress-Controller已部署完成

## 3.2 使用Ingress规则

创建测试的web应用

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
      - name: nginxweb
        image: nginx:1.15-alpine
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
    port: 80
    protocol: TCP
    nodePort: 30001   #node节点的映射端口 可以通过外部访问
    targetPort: 80
  selector:
    app: mynginx
  sessionAffinity: None
  type: NodePort
```

创建Ingress规则

```yaml
[root@k8s-master01 daem]# cat ingress.yaml 
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: ingress-daem
  annotations:
    kubernetes.io/ingress.class: "nginx" 
    #nginx.ingress.kubernetes.io/limit-connections: 10
    #nginx.ingress.kubernetes.io/limit-rate: 100K
    #nginx.ingress.kubernetes.io/limit-rps: 1
    #nginx.ingress.kubernetes.io/limit-rpm: 30
spec:
  rules:
  - host: test.nginxsvc.com
    http:
      paths:
      - backend:
          serviceName: nginx-svc
          servicePort: 80
        path: /
```

浏览器访问
添加hosts解析
192.168.29.102 test.nginxsvc.com test-tls.test.com
![img](https://img2020.cnblogs.com/blog/2005433/202012/2005433-20201203150737686-801306076.png)

```bash
[root@k8s-master01 daem]# curl -I http://test.nginxsvc.com/
HTTP/1.1 200 OK
Server: nginx/1.17.8
Date: Thu, 03 Dec 2020 06:56:49 GMT
Content-Type: text/html
Content-Length: 612
Connection: keep-alive
Vary: Accept-Encoding
Last-Modified: Sat, 11 May 2019 00:35:53 GMT
ETag: "5cd618e9-264"
Accept-Ranges: bytes
```

### 2.1 Ingress地址重写

流量重定向到目标URL

```yaml
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: ingress-daem
  annotations:
    #kubernetes.io/ingress.class: "nginx" 
    nginx.ingress.kubernetes.io/permanent-redirect: https://www.baidu.com   #当访问 test.nginxsvc.com会被重写到百度上
spec:
  rules:
  - host: test.nginxsvc.com
    http:
      paths:
      - backend:
          serviceName: nginx-svc
          servicePort: 80
        path: /
```

前后端分离

```yaml
  [root@k8s-master01 daem]# cat ingress.yaml 
  apiVersion: networking.k8s.io/v1beta1
  kind: Ingress
  metadata:
    name: ingress-daem
    annotations:
      #kubernetes.io/ingress.class: "nginx" 
      #nginx.ingress.kubernetes.io/permanent-redirect: https://www.baidu.com
      nginx.ingress.kubernetes.io/rewrite-target: /    #当访问test.nginxsvc.com/foo  会把请求打到 nginx-svc此service上
  spec:
    rules:
    - host: test.nginxsvc.com
      http:
        paths:
        - backend:
            serviceName: nginx-svc
            servicePort: 80
          path: /foo



  [root@k8s-master01 daem]# cat ingress.yaml 
  apiVersion: networking.k8s.io/v1beta1
  kind: Ingress
  metadata:
    name: ingress-daem
    annotations:
      #kubernetes.io/ingress.class: "nginx" 
      #nginx.ingress.kubernetes.io/permanent-redirect: https://www.baidu.com
      nginx.ingress.kubernetes.io/rewrite-target: /$2
  spec:
    rules:
    - host: test.nginxsvc.com
      http:
        paths:
        - backend:
            serviceName: nginx-svc
            servicePort: 80
          path: /nginxservice(/|$)(.*)
        paths:
        - backend:
            serviceName: tomcat-svc
            servicePort: 80
          path: /tomcatservice(/|$)(.*) #当访问test.nginxsvc.com:PORT/tomcatservice -> 就会被重定向到tomcat-svc  / 资源下
```

### 2.2 配置HTTPS

```yaml
[root@k8s-master01 ~]# openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.cert -subj "/CN=test-tls.test.com/O=test-tls.test.com"
Generating a 2048 bit RSA private key
..............................................+++
.........................................................................................+++
writing new private key to 'tls.key'
-----

[root@k8s-master01 ~]# kubectl create secret tls ca-cert  --key tls.key --cert tls.cert 
secret/ca-cert created
[root@k8s-master01 ~]# cat tlsingress.yaml
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
annotations:
nginx.ingress.kubernetes.io/ssl-redirect: "false"
name: test-tls
spec:
rules:
- host: test-tls.test.com
http:
paths:
- backend:
serviceName: nginx-svc
servicePort: 80
path: /
tls:                     
- hosts:
- test-tls.test.com
secretName: ca-cert
```

### 2.3 黑白名单配置

```yaml
    黑白名单

    [root@k8s-master01 ingressdeploy]# cat mandatory.yaml
    apiVersion: v1
    kind: Namespace
    metadata:
      name: ingress-nginx
      labels:
        app.kubernetes.io/name: ingress-nginx
        app.kubernetes.io/part-of: ingress-nginx

    ---

    kind: ConfigMap
    apiVersion: v1
    metadata:
      name: nginx-configuration
      namespace: ingress-nginx
      labels:
        app.kubernetes.io/name: ingress-nginx
        app.kubernetes.io/part-of: ingress-nginx
    data:
      #############添加如下信息#################
      whitelist-source-range: 192.168.29.102 #白名单，允许某个IP或IP段的访问
      block-cidrs: 192.168.29.101 #黑名单拒绝访问
```

### 2.4 匹配请求头

```yaml
      apiVersion: networking.k8s.io/v1beta1
      kind: Ingress
      metadata:
        annotations:
          nginx.ingress.kubernetes.io/server-snippet: |
              set $agentflag 0;

              if ($http_user_agent ~* "(Mobile)" ){
                set $agentflag 1;
              }

              if ( $agentflag = 1 ) {
                return 301 https://m.example.com;
              }
```

解释：
如果你的http_user_agent == Mobile。那么就把agentflag set成1 ，然后当agentflag == 1时，就会return 到这个域名 [https://m.example.com](https://m.example.com/)

### 2.5 速率限制

```yaml
    apiVersion: networking.k8s.io/v1beta1
    kind: Ingress
    metadata:
      name: ingress-nginx
      annotations:
        kubernetes.io/ingress.class: "nginx"
        nginx.ingress.kubernetes.io/limit-rate: 100K
        nginx.ingress.kubernetes.io/limit-rps: 1
        nginx.ingress.kubernetes.io/limit-rpm: 30
    spec:
      ......
```

- nginx.ingress.kubernetes.io/limit-connections

  单个IP地址允许的并发连接数。超过此限制时返回503错误

- nginx.ingress.kubernetes.io/limit-rps:

  每秒从给定IP接受的请求数。突发限制设置为该限制乘以突发乘数，默认乘数为5。当客户机超过此限制时，将返回limit req status code default:503

- nginx.ingress.kubernetes.io/limit-rpm:

  每分钟从给定IP接受的请求数。突发限制设置为该限制乘以突发乘数，默认乘数为5。当客户机超过此限制时，将返回limit req status code default:503

- nginx.ingress.kubernetes.io/limit-burst-multiplier:

  突发大小限制速率的乘数。默认的突发乘数为5，此批注覆盖默认乘数。当客户机超过此限制时，将返回limit req status code default:503。

- nginx.ingress.kubernetes.io/limit-rate-after

  初始千字节数，此后对给定连接的响应的进一步传输将受到速率限制。此功能必须在启用代理缓冲的情况下使用

- nginx.ingress.kubernetes.io/limit-rate

  每秒允许发送到给定连接的KB数。零值禁用速率限制。此功能必须在启用代理缓冲的情况下使用

- nginx.ingress.kubernetes.io/limit-whitelist

  要从速率限制中排除的客户端IP源范围。该值是一个逗号分隔的cidr列表

**以上就是Ingress常用的相关配置，所有配置均来自官方文档：https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/**