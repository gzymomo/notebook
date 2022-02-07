- [使用 Spring Boot Operator 部署 Spring Boot 到 K8S](https://mp.weixin.qq.com/s/PzuYed_dqD3n7OcfPmStvA)

前言

在 Kubernetes 中部署 Spring Boot 应用整体上来说是一件比较繁琐的事情，而 Spring Boot Operator 则能带给你更清爽简单的体验。

Spring Boot Operator 基于 Kubernetes 的 Custom Resource Definitions (CRDs) 扩展 API 进行的开发。

## 1. 打包 Docker 镜像

在讲部署之前我们需要先将我们的 Spring Boot 应用打包成标准的 Docker Image。

Java 项目打包镜像用 Maven/Gradle 插件比较多，这里在介绍一个新的 Google 开源插件 Jib，该插件使用起来比较方便。

注意：Jib 打包的镜像会导致 Java 应用的 pid=1。在使用 Spring Boot Operator 进行发布时候，Operator 会设置  Kubernetes 的 ShareProcessNamespace 参数为 true（v1.10+版本都可使用）来解决该问题。

下面就来演示一下通过 https://start.spring.io 生成一个标准的 Spring Boot 项目 operator-demo，然后使用 Jib 插件进行镜像打包。

```
mvn com.google.cloud.tools:jib-maven-plugin:build 
-Djib.to.auth.username=${{ secrets.MY_USERNAME }} 
-Djib.to.auth.password=${{ secrets.MY_PASSWORD }} 
-Djib.container.jvmFlags=--add-opens,java.base/sun.nio.ch=ALL-UNNAMED 
-Djib.from.image=freemanliu/oprenjre:11.0.5 
-Dimage=registry.cn-shanghai.aliyuncs.com/qingmuio/operator-demo/operator-demo:v1.0.0
```

执行上面的命令之后我们将得到一个标准的 Docker 镜像，该镜像会被推送到远程仓库。

## 2. Operator 快速体验

完成了镜像的构建之后，我们紧接着来安装我们的 Operator 到 Kubernetes 集群。当然了首先你需要一套集群，可以参考[本机搭建三节点 k8s 集群](http://mp.weixin.qq.com/s?__biz=MjM5NzMyMjAwMA==&mid=2651482135&idx=1&sn=230dac3e42d28b603815966e9fee2516&chksm=bd2504688a528d7ebcbe0ec484af04f887fede54aa19c0acc0d5b2fbd473bc0d0067eaf90ea8&scene=21#wechat_redirect)。

### 2.1 快速安装

此处快速安装只是为了快速体验 Demo。

```
kubectl apply -f https://raw.githubusercontent.com/goudai/spring-boot-operator/master/manifests/deployment.yaml
```

apply 成功之后控制台输出：

```
namespace/spring-boot-operator-system created
customresourcedefinition.apiextensions.k8s.io/springbootapplications.springboot.qingmu.io created
role.rbac.authorization.k8s.io/spring-boot-operator-leader-election-role created
clusterrole.rbac.authorization.k8s.io/spring-boot-operator-manager-role created
clusterrole.rbac.authorization.k8s.io/spring-boot-operator-proxy-role created
clusterrole.rbac.authorization.k8s.io/spring-boot-operator-metrics-reader created
rolebinding.rbac.authorization.k8s.io/spring-boot-operator-leader-election-rolebinding created
clusterrolebinding.rbac.authorization.k8s.io/spring-boot-operator-manager-rolebinding created
clusterrolebinding.rbac.authorization.k8s.io/spring-boot-operator-proxy-rolebinding created
service/spring-boot-operator-controller-manager-metrics-service created
deployment.apps/spring-boot-operator-controller-manager created
```

稍等片刻查看是否已经安装成功：

```
kubectl  get po -n spring-boot-operator-system
```

成功如下输出：

```
NAME                                                       READY   STATUS    RESTARTS   AGE
spring-boot-operator-controller-manager-7f498596bb-wcwtn   2/2     Running   0          2m15s
```

### 2.2 部署 OperatorDemo 应用

完成了 Operator 的部署之后，我们来部署我们第一个应用。这里我们就发布上面我们编写的 Spring Boot 应用 opreator-demo。
首先，我们需要先编写一个 Spring Boot Application 的 CRD 部署 yaml，如下：

```
# Demo.yaml
apiVersion: springboot.qingmu.io/v1alpha1
kind: SpringBootApplication
metadata:
  name: operator-demo 
spec:
  springBoot:
    version: v1.0.0
#    image: registry.cn-shanghai.aliyuncs.com/qingmuio/operator-demo/operator-demo:v1.0.0
```

细心的同学可能发现了，为啥连 Image 都没有这怎么发布？就 name、version 就能完成发布？

是的没错！就能完成发布，后面我讲详细讲到他是如何完成的。
接着我们 apply 一下：

```
kubectl apply -f Demo.yaml
```

看到 console 输出：

```
springbootapplication.springboot.qingmu.io/operator-demo created
```

### 2.3 验证

表示创建成功了，接着我们来看下我们部署的第一个应用，这里我们直接用上面的 yaml 中的 name 过滤即可。
查看 pod

```
~# kubectl  get po | grep operator-demo
operator-demo-7574f4789c-mg58m             1/1     Running   0          76s
operator-demo-7574f4789c-ssr8v             1/1     Running   0          76s
operator-demo-7574f4789c-sznww             1/1     Running   0          76s
```

查看下我们的 pid 不等于 1 的设置是否生效。

根据下面的结果可以看到通过设置 ShareProcessNamespace 该参数我们可以在 Kubernetes 层面来解决这个 pid=1 的问题。

```
kubectl exec -it operator-demo-7574f4789c-mg58m bash
bash-5.0# ps -ef
UID        PID  PPID  C STIME TTY          TIME CMD
root         1     0  0 02:06 ?        00:00:00 /pause
root         6     0 26 02:06 ?        00:00:09 java --add-opens java.base/sun.nio.ch=ALL-UNNAMED -cp /app/resources:/app/classes:/app/libs/* io.qingmu.operator.operatordemo.Oper...
root        38     0  0 02:07 pts/0    00:00:00 bash
root        44    38  0 02:07 pts/0    00:00:00 ps -ef
```

查看 svc

```
~# kubectl  get svc | grep operator-demo
operator-demo             ClusterIP   10.101.128.6     <none>        8080/TCP            2m52s
```

我们来访问一下试试：

```
root@server1:~# curl -i http://10.101.128.6:8080
HTTP/1.1 200 
Content-Type: text/plain;charset=UTF-8
Content-Length: 9
Date: Wed, 08 Apr 2020 08:45:46 GMT

hello !!!
```

我们来试着缩减副本数到 1 个。
编辑我们的 Demo.yaml，加入一个新的属性 replicas：

```
# Demo.yaml
apiVersion: springboot.qingmu.io/v1alpha1
kind: SpringBootApplication
metadata:
  name: operator-demo 
spec:
  springBoot:
    version: v1.0.0
    replicas: 1
```

应用一下：

```
root@server1:~# kubectl apply -f Demo.yaml 
springbootapplication.springboot.qingmu.io/operator-demo configured
```

再次查看 pod，会发现我们的 pod 已经缩放为一个副本了：

```
~# kubectl  get po | grep operator-demo
operator-demo-7574f4789c-sznww             1/1     Running   0          8m29s
```

### 2.4 清理 operator-demo

要删除该 pod 我们只需要执行 delete 即可：

```
~# kubectl delete -f Demo.yaml 
springbootapplication.springboot.qingmu.io "operator-demo" deleted
```

再次查看 pod，已经没了：

```
kubectl  get po | grep operator-demo
```

## 3. 部署自己的应用

部署自己私有仓库的应用需要需要先创建 secret（如果已经创建跳过即可）。
创建 docker-registry 的 secret：

```
kubectl create  
secret docker-registry aliyun-registry-secret 
--docker-server=registry-vpc.cn-hangzhou.aliyuncs.com 
--docker-username=*** 
--docker-password=*** 
--docker-email=***
```

自己应用的 crd Yaml：

```
apiVersion: springboot.qingmu.io/v1alpha1
kind: SpringBootApplication
metadata:
  name: 你的应用的名称
spec:
  springBoot:
    version: v1.0.0
    replicas: 1 
    image: 你的image地址
    imagePullSecrets: 
      - 上面创建的secret
```

### 3.1 一个完整的 Spring Boot Application Yaml

下面是一个完整的 yaml 属性结构，大部分属性我们都可以用默认配置的即可。
不设置属性，默认使用 Operator 中设置的通用值。详见后面的自定义安装 Operator。

```
apiVersion: springboot.qingmu.io/v1alpha1
kind: SpringBootApplication
metadata:
  name: operator-demo
  namespace: default
spec:
  springBoot:
    # image 可以不设置，如果不设置默认使用 IMAGE_REPOSITORY+/+mate.name+:+spec.springBoot.version
    # registry.cn-shanghai.aliyuncs.com/qingmuio + / + operator-demo + : + v1.0.0
    image: registry.cn-shanghai.aliyuncs.com/qingmuio/operator-demo:v1.0.0
    clusterIp: "" 
    version: v1.0.0 
    replicas: 1 
    resource:
      cpu:
        request: 50m
        limit: "" 
      memory:
        request: 1Gi
        limit: 1Gi 
    path:
      liveness: /actuator/health 
      readiness: /actuator/health 
      hostLog: /var/applog 
      shutdown: /spring/shutdown 
    imagePullSecrets: 
      - aliyun-docker-registry-secret
    env: 
      - name: EUREKA_SERVERS
        value: http://eureka1:8761/eureka/,http://eureka2:8761/eureka/,http://eureka3:8761/eureka/
    nodeAffinity: 
      key: "failure-domain.beta.kubernetes.io/zone"
      operator: "In"
      values:
        - "cn-i"
        - "cn-h"
        - "cn-g"
```

### 3.2 优雅停机的路径

由于优雅停机默认是关闭的，并且并不支持 GET 请求，所以我们需要开启和搭个桥。
首先，在 application.yml 中启用：

```
management:
  endpoints:
    web:
      exposure:
        include: "*"
  endpoint:
    shutdown:
      enabled: true
```

然后，桥接一个 GET 方法：

```
@RestController
public class ShutdownController {
    @Autowired
    private ShutdownEndpoint shutdownEndpoint;

    @GetMapping("/spring/shutdown")
    public Map<String, String> shutdown(HttpServletRequest request) {
        return shutdownEndpoint.shutdown();
    }
}
```

### 3.3 node 亲和的使用

举一个例子：我们有一个 Spring Boot 应用 user-service，希望它能分布到 3 个可用区的 6 个节点上:
首先，我们把机器划分多个可用区：

```
cn-i区(node-i1,node-i02)
cn-h区(node-g1,node-g02)
cn-g区(node-h1,node-h02)
```

现在，我们有 3 个可以区，每个区有2台 workload，一共6台。然后，我们需要给这些机器分别打上 label。
将全部的 i 区机器标注为 cn-i：

```
kubectl label node node-i1 failure-domain.beta.kubernetes.io/zone=cn-i
kubectl label node node-i2 failure-domain.beta.kubernetes.io/zone=cn-i
```

同理将 h 区的标注为 h，g 区同理。

```
kubectl label node node-h1 failure-domain.beta.kubernetes.io/zone=cn-i
kubectl label node node-ih2 failure-domain.beta.kubernetes.io/zone=cn-i
```

准备工作我们就绪了，现在我们来设置让它达到我们的调度效果，像如下编写：

```
spec:
  springBoot:
    nodeAffinity: #可以不设置 节点亲和 这里演示的是尽量将pod分散到 i h g 三个可用区，默认设置了pod反亲和
      key: "failure-domain.beta.kubernetes.io/zone"
      operator: "In"
      values:
        - "cn-i"
        - "cn-h"
        - "cn-g"
```

## 4. Operator 自定义安装

上面我们快速的安装了好了，接着我们来讲解下如何自定义安装，以及有哪些自定义的参数，可以个性化的参数我们用环境变量的方式注入。
下面来修改 Deployment 完成自己个性化的配置部署。从我提供的部署 yaml 中拉到最后，找到 name 是 spring-boot-operator-controller-manager 的 Deployment，我们将修改它。

```
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    control-plane: controller-manager
  name: spring-boot-operator-controller-manager
  namespace: spring-boot-operator-system
.....
        
        #注意：一下配置针对通用全局的spring boot默认配置，对crd的spring boot生效，这里不配置也可以在部署的yaml中指定

        # 私有仓库的地址，比如我的最终打包的镜像地址是 registry.cn-shanghai.aliyuncs.com/qingmuio/operator-demo/operator-demo:v1.0.0
        # 那么配置的值是 registry.cn-shanghai.aliyuncs.com/qingmuio/operator-demo
        # 配置这个值之后，我们我们如果在发布的yaml中不写image，那么使用的image就是 IMAGE_REPOSITORY+"/"+mate.name+spec.springBoot.version
        - name: IMAGE_REPOSITORY
          value: registry.cn-shanghai.aliyuncs.com/qingmuio
        # 请求CPU限制
        - name: REQUEST_CPU
          value: 50m
        # 限制最大能用最大CPU java应用可以不用限制，限制不合理会导致启动异常缓慢
        - name: LIMIT_CPU
          value: ""
        # 请求内存大小
        - name: REQUEST_MEMORY
          value: 500Mi
        # 限制最大内存大小 一般和request一样大即可
        - name: LIMIT_MEMORY
          value: 500Mi
        # 就绪检查Path，spring boot actuator 默认Path
        - name: READINESS_PATH
          value: /actuator/health
        # 就绪存活Path，spring boot actuator 默认Path
        - name: LIVENESS_PATH
          value: /actuator/health
        # 就绪存活Path，优雅停机Path
        - name: SHUTDOWN_PATH
          value: /spring/shutdown
        # 复制级 即副本数
        - name: REPLICAS
          value: "3"
        # 将日志外挂到主机磁盘Path，默认两者相同
        - name: HOST_LOG_PATH
          value: /var/applog
        # 用于pull 镜像的secrets
        - name: IMAGE_PULL_SECRETS
          value: ""
        # 用于pull 镜像的secrets
        - name: SPRING_BOOT_DEFAULT_PORT
          value: "8080"
        # node亲和，比如我可以设置pod尽量分散在不同可用区cn-i,cn-g,cn-h区
        - name: NODE_AFFINITY_KEY
          value: ""
        - name: NODE_AFFINITY_OPERATOR
          value: ""
        - name: NODE_AFFINITY_VALUES
          value: ""
        # 全局的环境变量，会追加到每个spring boot的每个pod中，格式 k=v;k1=v2,
        # 如 EUREKA_SERVERS=http://eureka1:8761/eureka/,http://eureka2:8761/eureka/,http://eureka3:8761/eureka/;k=v
        - name: SPRING_BOOT_ENV
          value: ""
        image: registry.cn-shanghai.aliyuncs.com/qingmuio/spring-boot-operator-controller:latest

.....
```

### 4.1 自定义安装之后部署

yaml 可以简化为如下。

```
apiVersion: springboot.qingmu.io/v1alpha1
kind: SpringBootApplication
metadata:
  name: 你的应用的名称
spec:
  springBoot:
    version: v1.0.0
```

# 附录

环境变量表格

![图片](https://mmbiz.qpic.cn/mmbiz_png/eZzl4LXykQxWaAZBibTRu1464m9e9oMSuYtEfXP1Q87WZTmicnibLpCD1oxmy8ownzJSFUjcwEiaqDPxqEHoian60Jg/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

# Github 仓库

https://github.com/goudai/spring-boot-operator