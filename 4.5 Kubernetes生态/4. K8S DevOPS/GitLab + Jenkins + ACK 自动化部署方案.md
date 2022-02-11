- [GitLab + Jenkins + ACK 自动化部署方案](https://juejin.cn/post/7061795630783397902)

本篇文章从实践角度介绍如何结合我们常用的 GitLab 与 Jenkins,通过 K8s 来实现项目的自动化部署,以公司目前正在使用的生产架构图做为此次讲解的重点,如图所示：

![生产环境架构图](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/92362b33ce904c64b4f2c0a2805b5062~tplv-k3u1fbpfcp-watermark.awebp)

本文涉及到的工具和技术包括：

- GitLab：常用的源代码管理系统；
- Jenkins（Jenkins Pipeline）：常用的自动化构建、部署工具，Pipeline 以流水线的方式将构建、部署的各个步骤组织起来；
- docker（dockerfile）：容器引擎，所有应用最终都要以 docker 容器运行，dockerfile 是 docker 镜像定义文件；
- Kubernetes：Google 开源的容器编排管理系统。

## **环境背景：**

- 已使用 GitLab 做源码管理，源码按不同的环境建立不同的分支，如：dev (开发分支)、test（测试分支）、pre（预发分支）、master（生产分支）；
- 已搭建 Jenkins 服务；
- 已有 docker Registry 服务，用于 docker 镜像的存储（可以基于docker Registry 或 Harbor 自建，或使用云服务，本文使用阿里云容器镜像服务）；
- 已部署了K8s集群。

## **预期效果：**

- 分环境部署应用，使开发环境、测试环境、预发环境及生产环境隔离开来，其中，开发、测试、预发环境部署在同一个 K8s 集群中，但使用不同的 namespace ,生产环境部署在阿里云，使用 ACK 容器服务；
- 配置尽可能通用化，只需要通过修改少量配置文件的少量配置属性，就能完成新项目的自动化部署配置；
- 开发、测试及预发环境在 push 代码时可以设置自动触发构建与部署，具体根据实际情况配置，生产环境使用单独 ACK 集群及单独 Jenkins 系统进行部署；
- 整体交互流程图如下:

![交互流程图](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/ac514dba1ca744e79b2205b26d348669~tplv-k3u1fbpfcp-watermark.awebp)

## 项目配置文件

首先我们要在项目的根路径下添加一些必要的配置文件。如图所示

![GitLab 项目图示1](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/d7aa774622a6409d84d1866e2836d2bf~tplv-k3u1fbpfcp-watermark.awebp)

![GitLab 项目图示2](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/2daa04a507b3458aa63429287f5f7f29~tplv-k3u1fbpfcp-watermark.awebp)

包括：

- dockerfile 文件，用于构建 docker 镜像文件；
- `Docker_build.sh` 文件，用于将 docker 镜像打 Tag 后推送到镜像仓库中；
- 项目 Yaml 文件，此文件为部署项目到 K8s 集群的主文件。

### **dockerfile**

在项目根目录中添加一个 dockerfile 文件(文件名就是 dockerfile),定义如何构建 docker 镜像，以 Java 项目为例：

```sh
# 镜像来源
FROM xxxxxxxxxxxxxxxxxxxxxxxxxx.cr.aliyuncs.com/billion_basic/alpine-java:latest

# 拷贝当前目录的应用到镜像
COPY target/JAR_NAME /application/

# 声明工作目录,不然找不到依赖包，如果有的话
WORKDIR /application

# 声明动态容器卷
VOLUME /application/logs

# 启动命令
# 设置时区
ENTRYPOINT ["java","-Duser.timezone=Asia/Shanghai","-Djava.security.egd=file:/dev/./urandom"]
CMD ["-jar","-Dspring.profiles.active=SPRING_ENV","-Xms512m","-Xmx1024m","/application/JAR_NAME"]
复制代码
```

### docker_build.sh

在项目根目录下创建一个 `deploy` 文件夹，此文件夹中存放各个环境项目的配置文件，其中`Docker_build.sh`文件就是专为触发项目打包为镜像文件、重新打 Tag 后推送到镜像仓库中存在的，同样以 Java 项目为例：

```sh
# !/bin/bash

# 模块名称
PROJECT_NAME=$1

# 名称空间目录
WORKSPACE="/home/jenkins/workspace"

# 模块目录
PROJECT_PATH=$WORKSPACE/pro_$PROJECT_NAME

# jar 包目录
JAR_PATH=$PROJECT_PATH/target

# jar 包名称
JAR_NAME=$PROJECT_NAME.jar

# dockerfile 目录
dockerFILE_PATH="/$PROJECT_PATH/dockerfile"

# sed -i "s/VAR_CONTAINER_PORT1/$PROJECT_PORT/g" $PROJECT_PATH/dockerfile
sed -i "s/JAR_NAME/$JAR_NAME/g" $PROJECT_PATH/dockerfile
sed -i "s/SPRING_ENV/k8s/g" $PROJECT_PATH/dockerfile

cd $PROJECT_PATH

# 登录阿里云仓库
docker login  xxxxxxxxxxxxxxxxxxxxxxxxxx.cr.aliyuncs.com -u 百瓶网 -p xxxxxxxxxxxxxxxxxxxxxxxxxx

# 构建模块镜像
docker build -t $PROJECT_NAME  . 
docker tag $PROJECT_NAME xxxxxxxxxxxxxxxxxxxxxxxxxx.cr.aliyuncs.com/billion_pro/pro_$PROJECT_NAME:$BUILD_NUMBER

# 推送到阿里云仓库
docker push xxxxxxxxxxxxxxxxxxxxxxxxxx.cr.aliyuncs.com/billion_pro/pro_$PROJECT_NAME:$BUILD_NUMBER
复制代码
```

### **`project.yaml`文件**

`project.yaml` 定义了项目部署到K8s集群中所需的项目名称、PV、PVC、namespace、副本数、镜像地址、服务端口、醒目自检、项目资源请求配置、文件挂载及 service 等：

```yaml
# ------------------- PersistentVolume（定义PV） ------------------- #
apiVersion: v1
kind: PersistentVolume
metadata:
# 项目名称
  name: pv-billionbottle-wx
  namespace: billion-pro
  labels:  
    alicloud-pvname: pv-billionbottle-wx
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteMany
  csi:
    driver: nasplugin.csi.alibabacloud.com
    volumeHandle: pv-billionbottle-wx
    volumeAttributes:
      server: "xxxxxxxxxxxxx.nas.aliyuncs.com"
      path: "/k8s/java"
  mountOptions:
  - nolock,tcp,noresvport
  - vers=3

---
# ------------------- PersistentVolumeClaim（定义PVC） ------------------- #
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: pvc-billionbottle-wx
  namespace: billion-pro
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 5Gi
  selector:
    matchLabels:
      alicloud-pvname: pv-billionbottle-wx      

---      
# ------------------- Deployment ------------------- #
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    k8s-app: billionbottle-wx
  name: billionbottle-wx
# 定义 namespace  
  namespace: billion-pro
spec:
# 定义副本数
  replicas: 2
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      k8s-app: billionbottle-wx
  template:
    metadata:
      labels:
        k8s-app: billionbottle-wx
    spec:
      serviceAccountName: default
      imagePullSecrets:
        - name: registrykey-k8s
      containers:
      - name: billionbottle-wx
# 定义镜像地址  
        image: $IMAGE_NAME 
        imagePullPolicy: IfNotPresent
# 定义自检     
        livenessProbe:
          failureThreshold: 3
          initialDelaySeconds: 60
          periodSeconds: 60
          successThreshold: 1
          tcpSocket:
            port: 8020
          timeoutSeconds: 1
        ports:
# 定义服务端口    
          - containerPort: 8020
            protocol: TCP
        readinessProbe:
          failureThreshold: 3
          initialDelaySeconds: 60
          periodSeconds: 60
          successThreshold: 1
          tcpSocket:
            port: 8020
          timeoutSeconds: 1
# 定义项目资源配置     
        resources:
          requests:
            memory: "1024Mi"
            cpu: "300m"
          limits:
            memory: "1024Mi"
            cpu: "300m"
# 定义文件挂载
        volumeMounts:
          - name: pv-billionbottle-key
            mountPath: "/home/billionbottle/key"         
          - name: pvc-billionbottle-wx
            mountPath: "/billionbottle/logs"
      volumes:
        - name: pv-billionbottle-key
          persistentVolumeClaim:
            claimName: pvc-billionbottle-key  
        - name: pvc-billionbottle-wx
          persistentVolumeClaim:
            claimName: pvc-billionbottle-wx

---
# ------------------- Dashboard Service（定义service） ------------------- #
apiVersion: v1
kind: Service
metadata:
  labels:
    k8s-app: billionbottle-wx
  name: billionbottle-wx
  namespace: billion-pro
spec:
  ports:
    - port: 8020
      targetPort: 8020
  type: ClusterIP
  selector:
    k8s-app: billionbottle-wx
复制代码
```

这里默认通过 Pipeline 定义了镜像的路径，可直接用变量去替换 `$IMAGE_NAME`,且可以在这里直接指定容器的端口而不用去改 dockerfile 文件模版（让模版文件在各个环境复用，通常不需要去做修改），同时添加了 ENV 的配置，可以直接读取 configmap 的配置文件。将 Service type 从默认的 `NodePort` 改为 `ClusterIp` 保证项目之间只在内部通讯。部署不同项目时只需要修改  `docker_build.sh` 和 `Project.yaml` 中的环境变量、项目名称及其他少量配置项，根目录下的 dockerfile 文件可以复用到各个环境。

部署时，我们要在 K8s 集群中的 Docker 镜像仓库拉取镜像，因此我们要先在 K8s 中创建镜像仓库访问凭证（imagePullSecrets）。

~~~sh
# 登录 docker Registry 生成 /root/.docker/config.json 文件
docker login --username=your-username registry.cn-xxxxx.aliyuncs.com
# 创建 namespace billion-pro （我这里时根据项目的环境分支名称创建的namespace）
kubectl create namespace billion-pro
# 在 namespace billion-pro 中创建一个 secret 
kubectl create secret registrykey-k8s aliyun-registry-secret --from-file=.dockerconfigjson=/root/.docker/config.json --type=kubernetes.io/dockerconfigjson --name=billion-pro
```sh

### **Jenkinsfile (Pipeline)**

Jenkinsfile 是 Jenkins Pipeline 配置文件,遵循 Groovy 脚本规范。对于 Java 项目的构建部署,Jenkinsfile 的 Pipeline 脚本文件如下：

```pipeline
#!/bin/sh -ilex
def env = "pro"
def registry = "xxxxxxxxxxxxxxx.cn-shenzhen.cr.aliyuncs.com"
def git_address = "http://xxxxxxxxx/billionbottle/billionbottle-wx.git"
def git_auth = "1eb0be9b-ffbd-457c-bcbf-4183d9d9fc35"
def project_name = "billionbottle-wx"
def k8sauth = "8dd4e736-c8a4-45cf-bec0-b30631d36783"
def image_name = "${registry}/billion_pro/pro_${project_name}:${BUILD_NUMBER}"

pipeline{
      environment{
        BRANCH =  sh(returnStdout: true,script: 'echo $branch').trim()
        } 
        agent{
            node{
              label 'master'
            }
        }
        stages{
            stage('Git'){
            steps{
            git branch: '${Branch}', credentialsId: "${git_auth}", url: "${git_address}"
            }
        }
        stage('maven build'){
            steps{
            sh "mvn clean package -U -DskipTests"
            }
        }
        stage('docker build'){
            steps{
            sh "chmod 755 ./deploy/${env}_docker_build.sh && ./deploy/${env}_docker_build.sh ${project_name} ${env}"
            }
        }
        stage('K8s deploy'){
            steps{
                sh "pwd && sed -i 's#\$IMAGE_NAME#${image_name}#' deploy/${env}_${project_name}.yaml"
                kubernetesDeploy configs: "deploy/${env}_${project_name}.yaml", kubeconfigId: "${k8sauth}"
            }
        }
    }
}
复制代码
~~~

Jenkinsfile 的 Pipeline 脚本定义了整个自动化构建部署流程：

- Code Analyze：可以使用 SonarQube 之类的静态代码分析工具完成代码检查,这里先忽略；
- Maven Build：启动一个 maven 的程序来完成项目 maven 的构建打包,也可以启动一个 maven 容器,挂载 maven 本地仓库目录到宿主机,避免每次都需要重新下载依赖包；
- docker Build：构建 docker 镜像,并推送到镜像仓库,不同环境的镜像通过 tag 前缀区分，比如开发环境是 `dev_`，测试环境是 `test_`，预发环境是 `pre_`，生产环境是 `pro_`；
- K8s Deploy：使用 Jenkins 自带插件完成项目的部署,或已有项目的更新迭代,不同环境使用不同的参数配置,K8s 集群的访问凭证可用 kube_config 来直接配置。

### Jenkins 的配置

#### Jenkins 任务配置

在 Jenkins 中创建一个 Pipeline 的任务,如图：

![Jenkins 流水线配置](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/95ec1b52c29a47cfa019f1e70955c5cd~tplv-k3u1fbpfcp-watermark.awebp)

配置构建触发器,将目标分支设置为 master 分支，如图：

![jenkins 分支配置](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/220f6e2cf9734d51a48b4f71c788212e~tplv-k3u1fbpfcp-watermark.awebp)

配置流水线,选择「Pipeline script」并配置 Pipeline 脚本文件,配置项目 Git 地址,拉取源码凭证等,如图：

![Pipeline 脚本](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/900c2905b1a24676a3e9c11effeef3a6~tplv-k3u1fbpfcp-watermark.awebp)

上图中引用的密钥凭据需要提前在 jenkins 中配置，如下图：

![jenkins 密钥配置](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/8d73f73d570f49978eaad8a824a902d4~tplv-k3u1fbpfcp-watermark.awebp)

保存即完成了项目生产环境的 Jenkins 配置,其它环境同理,需要注意的是区分各个环境所对应的分支

## **Kubernetes 集群功能介绍**

K8s 它是基于容器的集群编排引擎,具备扩张集群、滚动升级回滚、弹性伸缩、自动治愈、服务发现等多种特性能力,结合目前生产环境的实际情况,重点介绍几个常用的功能点,如需详细了解其它功能,请直接在 [Kubernets 官网](https://link.juejin.cn?target=https%3A%2F%2Fkubernetes.io%2F) 查询。

### Kubernetes 架构图

![K8s 架构图](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/5d6ee1edb5ca4236a688de54af087757~tplv-k3u1fbpfcp-watermark.awebp)

从宏观上来说 Kubernetes 的整体架构,包含 Master、Node 以及 Etcd。

Master 即主节点,负责控制整个 kubernetes 集群。它包含 Api Server、Scheduler、Controller 等部分,它们都需要和 Etcd 进行交互以存储数据。

- Api Server：主要提供资源操作的统一入口,这样就屏蔽了与 Etcd 的直接交互,功能包含安全、注册与发现等；
- Scheduller：负责按照一定的调度规则将 pod 调度到 Node 上；
- Controller：资源控制中心,确保资源处于预期的状态。

Node 即工作节点，为整个集群提供计算力,是容器真正运行的地方,包括运行容器、kubelet、kube-proxy。

- kubelet：主要工作是管理容器的生命周期,结合 cAdvisor 进行监控、健康检查以及定期上报节点状态；
- kube-proxy：主要利用 service 提供集群内部的服务发现和负载均衡,同时监听 service/endpoints 变化刷新负载均衡。

### **容器编排**

Kubernetes 中有诸多编排相关的控制资源,例如编排无状态应用的 deployment,编排有状态应用的 statefulset,编排守护进程 daemonset 以及编排离线任务的 job/cronjob 等等。

我们以目前生产环境应用的 deployment 为例, deployment 、replicatset 、pod 之间的关系是一种层层控制的关系,简单来说,replicatset 控制 pod 的数量,而 deployment 控制 replicatset 的版本属性,这种设计模式也为两种最基本的编排动作实现了基础,即数量控制的水平扩缩容,版本属性控制的更新/回滚。

### **水平扩缩容**

![pod 水平扩展示意图](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/14e8799c610b44cdbb9302079b34df52~tplv-k3u1fbpfcp-watermark.awebp)

水平扩缩容非常好理解,我们只需要修改 replicatset 控制的 pod 副本数量即可,比如从 2 改到 3 ,那么就完成了水平扩容这个动作,反之即水平收缩。

### **滚动更新部署（Rolling Update）**

滚动部署是 K8s 中的默认部署策略,它用新版本的 pod 一个一个地替换应用程序先前版本的 pod ,而没有任何集群停机的时间,滚动部署缓慢地用新版本应用程序的实例替换之前版本的应用程序实例,如图所示：

![pod 滚动更新示意图](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/d758c5e2895e43f5ab946393f9e56058~tplv-k3u1fbpfcp-watermark.awebp)

在滚动更新的实际应用中我们可以配置 RollingUpdateStrategy 来控制滚动更新策略,另外还有两个选项可以让我们微调更新过程：

- maxSurge ：更新期间可以创建 pod 数量超过所需 pod 的数量,这可以是副本计数的绝对数量或百分比,默认值为25%；
- maxUnavailable ：更新过程中不可用的 pod 数量,这可以是副本计数的绝对数量或百分比,默认值为25%。

### **微服务（service）**

了解微服务前,我们要线了解一个很重要的资源对象 —— service

在微服务中, pod 可以对应实例,那么 service 对应的就是微服务,而在服务调用的过程中，service 的出现解决了两个问题：

- pod 的 ip 不是固定的,利用非固定的 ip 进行网络调用不现实；
- 服务调用需要对不同的 pod 进行负载均衡。

service 通过 label 选择器选取合适的 pod,构建出一个 endpoints,即 pod 负载均衡列表,实际运用中,一般我们会为同一个微服务的 pod 实例都搭上类似 `app=xxx` 的标签,同时为该微服务创建一个标签选择器为 `app=xxx` 的 service。

### **Kubernetes 中的网络**

K8s 的网络通讯,首先得有“三通”基础：

- node 到 pod 之间可以互通；
- node 的 pod 之间可以互通；
- 不同 node 之间的 pod 可以互通。

![pod 间互相通讯示意图](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/96f25ae804c5431081929c143dca7e44~tplv-k3u1fbpfcp-watermark.awebp)

简单来说不同 pod 之间通过 cni0/docker0 网桥实现了通讯,node 访问 pod 也是通过网桥通讯, 而不同的 node 之间的 pod 通讯有很多种实现方式,包括现在比较普遍的 flannel 的 vxlan/hostgw 模式等,flannel 通过 etcd 获知其它 node 的网络信息,并会为本 node 创建路由表,最终使得不同 node 间可以实现跨主机通讯。

## 小结

到现在为止,已基本介绍清楚了我们生产环境整体架构中使用到的基础组件的相关概念，它们是如何运行的,以及微服务是怎么运行在 Kubernetes 中的,但涉及到配置中心、监控及告警等一些其它的组件暂未详细介绍,争取尽快更新这部分内容。