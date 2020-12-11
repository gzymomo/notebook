CSDN：

[哎_小羊_168](https://blog.csdn.net/aixiaoyang168)：[Spring Boot 项目转容器化 K8S 部署实用经验分享](https://blog.csdn.net/aixiaoyang168/article/details/96740530)

## 1、服务配置文件处理方式

对于各个项目分环境部署，最麻烦的就是配置文件的问题，不同的环境需要加载不同的配置，好在 Spring Boot 框架加载配置是非常方便的，具体如何加载配置文件可以参考 [这里](https://blog.csdn.net/aixiaoyang168/article/details/90116097#1Spring_Boot__2)，我们可以针对不同的环境分别配置不同的配置文件，这里有两个地方要注意一下：

- 构建镜像的时候，尽量实现一个镜像支持所有环境（即所有配置都打到一个镜像里面去），在容器启动时指定加载哪个环境配置即可，例如：在部署 Deployment 时指定 `args: ["--spring.profiles.active=prod"]` 参数启动。
- 尽量不要每个环境打出来一个镜像版本，传统方式在构建的时候指定 `-D prod` 配置 Profile 来指定加载哪个配置，来生成不同的产物 jar，容器化部署后不需要这样，那样后期控制各镜像版本发布会比较麻烦。



## 2、服务镜像相关配置

容器化部署服务，肯定少不了镜像制作这一步，镜像可以分为基础镜像和应用镜像。

### 2.1 基础镜像

基础镜像要求体积尽量小，方便拉取，同时安装一些必要的软件，方便后期进入容器内排查问题，我们需要准备好服务运行的底层系统镜像，比如 Centos、Ubuntu 等常见 Linux 操作系统，然后基于该系统镜像，构建服务运行需要的环境镜像，比如一些常见组合：`Centos + Jdk`、`Centos + Jdk + Tomcat`、`Centos + nginx` 等，由于不同的服务运行依赖的环境版本不一定一致，所以还需要制作不同版本的环境镜像，例如如下基础镜像版本。

- **Centos6.5 + Jdk1.8**: `registry.docker.com/baseimg/centos-jdk:6.5_1.8`
- **Centos7.5 + Jdk1.8**: `registry.docker.com/baseimg/centos-jdk:7.5_1.8`
- **Centos7.5 + Jdk1.7**: `registry.docker.com/baseimg/centos-jdk:7.5_1.7`
- **Centos7 + Tomcat8 + Jdk1.8**: `registry.docker.com/baseimg/centos-tomcat-jdk:7.5_8.5_1.8`
- **Centos7 + Nginx**: `registry.docker.com/baseimg/centos-tomcat-jdk:7.5_1.10.2`
- **…**

这样，就可以标识该基础镜像的系统版本及软件版本，方便后边选择对应的基础镜像来构建应用镜像。基础镜像的制作方法之一，可以参考 [使用 febootstrap 制作自定义基础镜像](https://blog.csdn.net/aixiaoyang168/article/details/91357102) 方式。

### 2.2 应用镜像

有了上边的基础镜像后，就很容易构建出对应的应用镜像了，例如一个简单的应用镜像 Dockerfile 如下：

```bash
FROM registry.docker.com/baseimg/centos-jdk:7.5_1.8

COPY app-name.jar /opt/project/app.jar
EXPOSE 8080
ENTRYPOINT ["/java", "-jar", "/opt/project/app.jar"]
```

当然，这里我建议使用另一种方式来启动服务，<font color='blue'>将启动命令放在统一 `shell` 启动脚本执行</font>，例如如下Dockerfile 示例：

```bash
FROM registry.docker.com/baseimg/centos-jdk:7.5_1.8

COPY app-name.jar /opt/project/app.jar
COPY entrypoint.sh /opt/project/entrypoint.sh
EXPOSE 8080
ENTRYPOINT ["/bin/sh", "/opt/project/entrypoint.sh"]
```

将服务启动命令配置到 `entrypoint.sh`，这样我们可以扩展做很多事情，比如启动服务前做一些初始化操作等，还可以向容器传递参数到脚本执行一些特殊操作，而且这里变成脚本来启动，这样后续构建镜像基本不需要改 Dockerfile 了。

```bash
#!/bin/bash
# do other things here
java -jar $JAVA_OPTS /opt/project/app.jar $1  > /dev/null 2>&1
```

上边示例中，我们就注入 `$JAVA_OPTS` 环境变量，来优化 `JVM` 参数，还可以传递一个变量，这个变量大家应该就猜到了，就是服务启动加载哪个配置文件参数，例如：`--spring.profiles.active=prod` 那么，在 Deployment 中就可以通过如下方式配置了：

```yaml
...
spec:
  containers:
    - name: project-name
      image: registry.docker.com/project/app:v1.0.0
      args: ["--spring.profiles.active=prod"]
      env:
	   - name: JAVA_OPTS
	     value: "-XX:PermSize=512M -XX:MaxPermSize=512M -Xms1024M -Xmx1024M..."
...
```

是不是很方便，这里可扩展做的东西还很多，根据项目需求来配置。

## 3、服务日志输出处理

对于日志处理，之前我们一般会使用 `Log4j` 或 `Logstash` 等日志框架将日志输出到服务器指定目录，容器化部署后，日志会生成到容器内某个配置的目录上，外部是没法访问的，所以需要将容器内日志挂载到宿主机某个目录 (例如：`/opt/logs` 目录)，这样方便直接查看，或者配置 `Filebeat`、`Fluent` 等工具抓取到 `Elasticsearch` 来提供日志查询分析。在 Deployment 配置日志挂载方式也很简单，配置如下：

```yaml
...
    volumeMounts:
    - name: app-log
      mountPath: /data/logs/serviceA  #log4j 配置日志输出到指定目录
...
	volumes:
    - name: app-log
      hostPath:
        path: /opt/logs #宿主机指定目录
```

这里有个地方需要特别注意一下：服务日志要关闭 Console 输出，避免直接输出到控制台。默认 Docker 会记录控制台日志到宿主机指定目录，日志默认输出到 `/var/lib/docker/containers/<container_id>/<container_id>-json.log`，为了避免出现日志太多，占用磁盘空间，需要关闭 Console 输出并定期清理日志文件。

## 4、容器服务访问处理

### 4.1、配置容器服务暴露目标端口

首先需要提供容器服务需要暴露的目标端口号，例如 `Http`、`Https`、`Grpc` 等服务端口，创建 Service 时需要指定匹配的容器端口号，Deployment 中配置容器暴露端口配置如下：

```
	ports:
    - containerPort: 8080
      name: http
      protocol: TCP
    - containerPort: 443
      name: https
      protocol: TCP
    - containerPort: 18989
      name: dubbo
      protocol: TCP
12345678910
```

### 4.2、服务对内对外访问方式选择

K8S Service 暴露服务类型有三种：`ClusterIP`、`NodePort`、`LoadBalancer`，三种类型分别有不同的应用场景。

- **对内服务发现**，可以使用 `ClusterIP` 方式对内暴露服务，因为存在 Service 重新创建 IP 会更改的情况，所以不建议直接使用分配的 `ClusterIP` 方式来内部访问，可以使用 K8S DNS 方式解析，DNS 命名规则为：`<svc_name>.<namespace_name>.svc.cluster.local`，按照该方式可以直接在集群内部访问对应服务。
- **对外服务暴露**，可以采用 `NodePort`、`LoadBalancer` 方式对外暴露服务，`NodePort` 方式使用集群固定 `IP`，但是端口号是指定范围内随机选择的，每次更新 Service 该 `Port` 就会更改，不太方便，当然也可以指定固定的 `NodePort`，但是需要自己维护 `Port` 列表，也不方便。`LoadBalancer` 方式使用集群固定 `IP` 和 `NodePort`，会额外申请申请一个负载均衡器来转发到对应服务，但是需要底层平台支撑。如果使用 `Aliyun`、`GCE` 等云平台商，可以使用该种方式，他们底层会提供 `LoadBalancer` 支持，直接使用非常方便。

以上方式或多或少都会存在一定的局限性，所以建议如果在公有云上运行，可以使用 `LoadBalancer`、 `Ingress` 方式对外提供服务，私有云的话，可以使用 `Ingress` 通过域名解析来对外提供服务。`Ingress` 配置使用，可以参考 [初试 Kubernetes 暴漏服务类型之 Nginx Ingress](https://blog.csdn.net/aixiaoyang168/article/details/78485581) 和 [初试 Kubernetes 集群中使用 Traefik 反向代理](https://blog.csdn.net/aixiaoyang168/article/details/78557739) 文章。

## 5、服务健康监测配置

K8s 提供存活探针和就绪探针，来实时检测服务的健康状态，如果健康检测失败，则会自动重启该 Pod 服务，检测方式支持 `exec`、`httpGet`、`tcpSocket` 三种。对于 Spring Boot 后端 API 项目，建议采用 `httpGet` 检测接口的方式，服务提供特定的健康检测接口，如果服务正常则返回 `200` 状态码，一旦检测到非 `200` 则会触发自动重启机制。K8S 健康监测配置示例如下：

```yaml
 livenessProbe: # 是否存活检测
    failureThreshold: 3
    httpGet:
      path: /api/healthz
      port: 8080
      scheme: HTTP
    initialDelaySeconds: 300
    periodSeconds: 60
    successThreshold: 1
    timeoutSeconds: 2
  readinessProbe: # 是否就绪检测
    failureThreshold: 1
    httpGet:
      path: /api/healthz
      port: 8080
      scheme: HTTP
    periodSeconds: 5
    successThreshold: 1
    timeoutSeconds: 2 
```

## 6、服务 CPU & Mem 请求/最大值配置

K8S 在部署 Deployment 时，可以为每个容器配置最小及最大 CPU & Mem 资源限制，这个是很有必要的，因为不配置资源限制的话，那么默认该容器服务可以无限制使用系统资源，这样如果服务异常阻塞或其他原因，导致占用系统资源过多而影响其他服务的运行，同时 K8S 集群资源不足时，会优先干掉那些没有配置资源限制的服务。当然，请求资源量和最大资源量要根据服务启动实际需要来配置，如果不清楚需要配置多少，可以先将服务部署到 K8S 集群中，看正常调用时监控页面显示的请求值，在合理配置。

```yaml
resources:
  limits:
    cpu: "1000m"
    memory: "1024Mi"
  requests:
    cpu: "500m"
    memory: "512Mi"
```

## 7、K8S 集群部署其它注意事项

### 7.1、部署前的一些准备工作

K8S 在部署服务前，需要做一些准备工作，例如提前创建好对应的 Namespace，避免首次直接创建 Deployment 出现 Namespace 不存在而创建失败。如果我们使用的私有镜像仓库，那么还需要生成 Docker Repository 登录认证 Secret，用来注入到 Pod 内拉取镜像时认证需要。

```yaml
# 包含登录认证信息的 Secret
apiVersion: v1
kind: Secret
metadata:
  name: docker-regsecret
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: InN1bmRhbmRhbjE4MDUyOEBjcmVkaXRoYdfe3JhdXRocyI6eyJyZWdpc3RyeS1pb

# Deployment 中注入该 Secret
	imagePullSecrets:
    - name: docker-regsecret
```

Secret 的生成方式可参考 [官网文档](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/)。

### 7.2、灵活使用 ConfigMap 资源类型

K8S 提供 ConfigMap 资源类型来方便灵活控制配置信息，我们可以将服务需要的一些 `ENV` 信息或者配置信息放到 ConfigMap 中，然后注入到 Pod 中即可使用，非常方便。ConfigMap 使用方式有很多种，这里建议大家可以将一些经常更改的配置放到 ConfigMap 中，例如我在实际操作中，就发现有的项目 `nginx.conf` 配置，还有配置的 `ENV` 环境变量信息经常变动，那么就可以放在 ConfigMap 中配置，这样 Deployment 就不需要重新部署了。

```yaml
# 包含 nginx.conf 配置的 ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-conf-configmap
  data:
    www.conf: |
      server {
        listen 80;
        server_name 127.0.0.1

        root /opt/project/nginx/html/;
        error_page 405 =200 $uri;

        access_log  /opt/project/nginx/logs/http_accesss.log  main;
        error_log   /opt/project/nginx/logs/http_error.log;
      }

# 将 ConfigMap 挂载到容器指定目录
volumes:
- name: nginx-config
  configMap:
    defaultMode: 420
    name: nginx-conf-configmap
```

这里有一个使用 ConfigMap 优雅加载 Spring Boot 配置文件实现方式的示例，可以参考 [这里](https://blog.csdn.net/aixiaoyang168/article/details/90116097)。

### 7.3、Deployment 资源部署副本数及滚动更新策略

<font color='red'>K8S 建议使用 Deployment 资源类型启动服务，使用 Deployment 可以很方便的进行滚动更新、扩缩容/比例扩容、回滚、以及查看更新版本历史记录等。所以建议副本数至少 2 个，保证服务的可用性，要根据服务实际访问量，来合理配置副本数，过多造成资源浪费，过少造成服务负荷高响应慢的问题，当然也可以根据服务访问量，灵活扩缩容副本数。</font>

Deployment 更新策略有 `Recreate` 和 `RollingUpdate` 两种，`Recreate` 方式在创建出新的 Pod 之前会先杀掉所有已存在的 Pod，这种方式不友好，会存在服务中断，中断的时间长短取决于新 Pod 的启动就绪时间。`RollingUpdate` 滚动更新方式，通过配合指定 `maxUnavailable` 和 `maxSurge` 参数来控制更新过程，使用该策略更新时会新启动 `replicas` 数量的 Pod，新 Pod 启动完毕后，在干掉旧 Pod，如果更新过程中，新 Pod 启动失败，旧 Pod 依旧可以提供服务，直到启动完成，服务才会切到新 Pod，保证服务不会中断，建议使用该策略。

```yaml
replicas: 2
strategy:
  rollingUpdate:
    maxSurge: 1  #也可以按比例配置，例如：20%
    maxUnavailable: 0 #也可以按比例配置，例如：20%
  type: RollingUpdate
```

### 7.4、要保证 K8S 资源 CPU & Mem & Disk 资源够用

要时刻关注 K8S 集群资源使用情况，保证系统资源够集群使用，否则会出现因为 CPU 、Mem、Disk 不够用导致 Deployment 调度失败的情况。

### 7.5、K8S 集群配置项优化

K8S 集群创建每个 Namespaces 时默认会创建一个名称为 `default` 的 ServiceAccount，该 ServiceAccount 包含了名称为 `default-token-xxxx` 的 Secret，该 Secret 包含集群 api-server 使用的根 `CA` 证书以及认证用的令牌 `Token`，而且默认新创建 Pod 时会自动将该 ServiceAccount 包含的信息自动注入到 Pod 中，在 Pod 中可以直接使用这些认证信息连接集群执行 api 相关操作，这样会存在一定的风险，所以建议使用 `automountServiceAccountToken: false` 配置来关闭自动注入。

另一个配置 `progressDeadlineSeconds`，该配置用来指定在升级或部署时，由于各种原因导致卡住（还没有表明升级或部署失败），等待的 deadline 秒数，如果超过该 deadline 时间，那么将上报并标注 Deployment 状态为 False 并注明失败原因，然后 Deployment 继续执行后续操作。默认为 `600` 秒，如果觉得改时间太长，可以按照可接受的时间来修改配置，例如配置为 120 秒 `progressDeadlineSeconds: 120`。

