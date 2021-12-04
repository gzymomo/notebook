来源：https://qingmu.io/2020/04/08/Spring-Boot-Operator-User-Guide/

## 前言

在Kubernetes中部署spring boot应用整体上来说是一件比较繁琐的事情，而Spring Boot Operator则能带给你更清爽简单的体验。

Spring Boot Operator基于Kubernetes的custom resource definitions (CRDs)扩展API进行的开发。

## 一、打包Docker镜像

在讲部署之前我们需要先将我们的SpringBoot应用打包成标准的DockerImage。

java项目打包镜像用maven/gradle插件比较多，我的另一篇文章构建[SpringBoot的Docker镜像](https://mp.weixin.qq.com/s?__biz=MzI3ODcxMzQzMw==&mid=2247515190&idx=1&sn=357229cf8a3f5b8719ae98f87a698104&scene=21#wechat_redirect)，这里在介绍一个新的google开源的插件Jib，该插件使用起来比较方便。

注意：jib打包的镜像会导致java应用的pid=1，在使用SpringBootOperator进行发布时候，Operator会设置kubernetes的ShareProcessNamespace参数为true（v1.10+版本都可使用）来解决该问题。

下面就来演示一下我们通过https://start.spring.io生成一个标准的SpringBoot项目operator-demo,然后使用jib插件进行镜像打包

```bash
scriptmvn com.google.cloud.tools:jib-maven-plugin:build \
-Djib.to.auth.username=${{ secrets.MY_USERNAME }} \
-Djib.to.auth.password=${{ secrets.MY_PASSWORD }} \
-Djib.container.jvmFlags=--add-opens,java.base/sun.nio.ch=ALL-UNNAMED \
-Djib.from.image=freemanliu/oprenjre:11.0.5 \
-Dimage=registry.cn-shanghai.aliyuncs.com/qingmuio/operator-demo/operator-demo:v1.0.0
```

执行上面的命令之后我们将得到一个标准的docker镜像，该镜像会被推送到远程仓库。另外，Docker 系列教程全部整理好了，微信搜索Java技术栈，可以在线阅读。

## 二、Operator快速体验

完成了镜像的构建之后,我们紧接着来安装我们的Operator到kubernetes集群，当然了首先你需要一套集群，可以参考我之前一篇文章部署高可用kubernetes，虽然版本比较老,但是新版本其实也差不多的一个思路。

### 2.1 快速安装

此处快速安装只是为了快速体验demo

```bash
scriptkubectl apply -f https://raw.githubusercontent.com/goudai/spring-boot-operator/master/manifests/deployment.yaml
```

apply成功之后控制台输出

```bash
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

稍等片刻查看是否已经安装成功

```bash
scriptkubectl  get po -n spring-boot-operator-system
```

成功如下输出

```bash
NAME                                                       READY   STATUS    RESTARTS   AGE
spring-boot-operator-controller-manager-7f498596bb-wcwtn   2/2     Running   0          2m15s
```

#### 2.1.1 部署OperatorDemo应用

完成了Operator的部署之后，我们来部署我们第一个应用，这里我们就发布上面我们编写的springboot应用opreator-demo。

首先我们需要先编写一个Spring Boot Application 的CRD部署yaml，如下

```yaml
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

细心的同学可能发现了，为啥连`Image`都没有？这怎么发布，就name，version，就能完成发布？是的没错！就能完成发布，后面我讲详细讲到他是如何完成的。接着我们apply一下

```bash
scriptkubectl apply -f Demo.yaml
```

看到console输出

```bash
springbootapplication.springboot.qingmu.io/operator-demo created
```

#### 2.1.2 验证

表示创建成功了，接着我们来看下我们部署的第一个应用，这里我们直接用上面的yaml中的name过滤即可。 [Spring Boot 学习笔记](http://mp.weixin.qq.com/s?__biz=MzI3ODcxMzQzMw==&mid=2247542384&idx=2&sn=4f1148b7fc0090760ba0e8ef4c299ac1&chksm=eb50a346dc272a50baca4f3f935323612c0ce4283599e87550276336dcc79b9bd6bde2f627df&scene=21#wechat_redirect)分享给你。

查看pod

```bash
script~# kubectl  get po | grep operator-demo
operator-demo-7574f4789c-mg58m             1/1     Running   0          76s
operator-demo-7574f4789c-ssr8v             1/1     Running   0          76s
operator-demo-7574f4789c-sznww             1/1     Running   0          76s
```

查看下我们的pid不等于1的设置是否生效,根据下面的结果可以看到通过设置ShareProcessNamespace该参数我们可以在Kubernetes层面来解决这个pid=1的问题。

```bash
scriptkubectl exec -it operator-demo-7574f4789c-mg58m bash
bash-5.0# ps -ef
UID        PID  PPID  C STIME TTY          TIME CMD
root         1     0  0 02:06 ?        00:00:00 /pause
root         6     0 26 02:06 ?        00:00:09 java --add-opens java.base/sun.nio.ch=ALL-UNNAMED -cp /app/resources:/app/classes:/app/libs/* io.qingmu.operator.operatordemo.Oper...
root        38     0  0 02:07 pts/0    00:00:00 bash
root        44    38  0 02:07 pts/0    00:00:00 ps -ef
```

查看svc

```bash
script~# kubectl  get svc | grep operator-demo
operator-demo             ClusterIP   10.101.128.6     <none>        8080/TCP            2m52s
```

我们来访问一下试试。

```bash
scriptroot@server1:~# curl -i http://10.101.128.6:8080
HTTP/1.1 200 
Content-Type: text/plain;charset=UTF-8
Content-Length: 9
Date: Wed, 08 Apr 2020 08:45:46 GMT

hello !!!
```

我们来试着缩减他的副本数到1个 编辑我们的Demo.yaml，加入一个新的属性`replicas`

```yaml
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

应用一下

```bash
scriptroot@server1:~# kubectl apply -f Demo.yaml 
springbootapplication.springboot.qingmu.io/operator-demo configured
```

再次查看pod，你会发现我们的pod已经缩放为一个副本了

```bash
script~# kubectl  get po | grep operator-demo
operator-demo-7574f4789c-sznww             1/1     Running   0          8m29s
```

#### 2.1.3 清理operator-demo

要删除该pod 我们只需要执行delete即可

```bash
script~# kubectl delete -f Demo.yaml 
springbootapplication.springboot.qingmu.io "operator-demo" deleted
```

再次查看pod，已经没了

```bash
scriptkubectl  get po | grep operator-demo
```

## 三、部署自己的应用

部署自己私有仓库的应用需要需要先创建secret(如果已经创建跳过即可) 创建docker-registry的secret。

```bash
scriptkubectl create  \
secret docker-registry aliyun-registry-secret \
--docker-server=registry-vpc.cn-hangzhou.aliyuncs.com \
--docker-username=*** \
--docker-password=*** \
--docker-email=***
```

自己应用的crd Yaml

```yaml
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

### 3.1 一个完整的Spring Boot Application Yaml

下面是一个完整的yaml属性结构，大部分属性我们都可以用默认配置的即可。不设置属性，默认使用Operator中设置的通用值详见后面的自定义安装Operator。Spring Boot 基础就不介绍了，推荐下这个实战教程：https://www.javastack.cn/categories/Spring-Boot/

```yaml
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

由于优雅停机默认是关闭的并且并不支持Get请求所以我们需要开启和搭个桥 首先在`application.yml`中启用

```yaml
management:
  endpoints:
    web:
      exposure:
        include: "*"
  endpoint:
    shutdown:
      enabled: true
```

然后桥接一个Get方法

```java
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

### 3.3 node亲和的使用

举一个列子 我们有一个springboot应用 user-service 希望他能分布到3个可用区的6个节点上: 首先我们把机器划分多个可用区：

```
cn-i区(node-i1,node-i02)
cn-h区(node-g1,node-g02)
cn-g区(node-h1,node-h02)
```

现在我们有三个可以区 每个区有2台workload，一共6台。然后我们需要给这些机器分别打上label。将全部的i区机器标注为cn-i

```
scriptkubectl label node node-i1 failure-domain.beta.kubernetes.io/zone=cn-i
kubectl label node node-i2 failure-domain.beta.kubernetes.io/zone=cn-i
```

同理将h区的标注为h，g区同理

```
scriptkubectl label node node-h1 failure-domain.beta.kubernetes.io/zone=cn-i
kubectl label node node-ih2 failure-domain.beta.kubernetes.io/zone=cn-i
```

现在准备工作我们就绪了，现在我们来设置让它达到我们的调度效果，像如下编写即可。

```yaml
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

## 四、Operator 自定义安装

上面我们快速的安装了好了，接着我们来讲解下如何自定义安装，以及有哪些自定义的参数，可以个性化的参数我们用环境变量的方式注入。 

下面来修改`Deployment`完成自己个性化的配置部署，从我提供的部署yaml中拉倒最后，找到name是`spring-boot-operator-controller-manager`的Deployment，我们将修改它。

```yaml
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

yaml可以简化为如下。

```yaml
apiVersion: springboot.qingmu.io/v1alpha1
kind: SpringBootApplication
metadata:
  name: 你的应用的名称
spec:
  springBoot:
    version: v1.0.0
```

## 附录

环境变量表格

|        环境变量名        | 是否可以空 |      默认值      |                             说明                             |
| :----------------------: | :--------: | :--------------: | :----------------------------------------------------------: |
|     IMAGE_REPOSITORY     |    true    |        “”        |                        私有仓库的地址                        |
|       REQUEST_CPU        |    true    |       50m        |                         请求CPU限制                          |
|        LIMIT_CPU         |    true    |        “”        | 限制最大能用最大CPU java应用可以不用限制，限制不合理会导致启动异常缓慢 |
|      REQUEST_MEMORY      |    true    |       2Gi        |                         请求内存大小                         |
|       LIMIT_MEMORY       |    true    |       2Gi        |           限制最大内存大小 一般和request一样大即可           |
|      READINESS_PATH      |    true    | /actuator/health |         就绪检查Path，spring boot actuator 默认Path          |
|      LIVENESS_PATH       |    true    | /actuator/health |         存活检查Path，spring boot actuator 默认Path          |
|      SHUTDOWN_PATH       |    true    | /spring/shutdown |                  就绪存活Path，优雅停机Path                  |
|         REPLICAS         |    true    |        3         |                            副本数                            |
|      HOST_LOG_PATH       |    true    |   /var/applog    |            将日志外挂到主机磁盘Path，默认两者相同            |
|    IMAGE_PULL_SECRETS    |    true    |        无        |                    用于pull 镜像的secrets                    |
| SPRING_BOOT_DEFAULT_PORT |    true    |       8080       |                    用于pull 镜像的secrets                    |
|    NODE_AFFINITY_KEY     |    true    |        “”        | node亲和key，比如我可以设置pod尽量分散在不同可用区cn-i,cn-g,cn-h区 |
|  NODE_AFFINITY_OPERATOR  |    true    |        “”        |                        node亲和操作符                        |
|   NODE_AFFINITY_VALUES   |    true    |        “”        |                        node亲和value                         |
|     SPRING_BOOT_ENV      |    true    |        “”        | 全局的环境变量，会追加到每个spring boot的每个pod中，格式 k=v;k1=v2 |

​                                          