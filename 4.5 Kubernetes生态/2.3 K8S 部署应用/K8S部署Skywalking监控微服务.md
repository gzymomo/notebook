- [使用 Skywalking 对 Kubernetes（K8s）中的微服务进行监控](https://www.cnblogs.com/w84422/p/15642586.html)

## 1. 概述

在 Kubernetes（K8s）集群中是如何监控微服务。

apache 的 Skywalking 就是一个不错的选择，SkyWalking 是一个可观察性分析平台和应用程序性能管理系统，可以对微服务进行链路追踪，可以对微服务的指标进行分析，可以快速定位运行慢的服务。

Skywalking官网地址：https://skywalking.apache.org/

今天我们就来搭建一套 Skywalking 服务，监控一下我们之前搭建在 Kubernetes（K8s）集群中的微服务。

## 2. 场景介绍

在服务器 192.168.1.15 中，搭建并启动 Skywalking 控制台。

改造之前部署的 Eureka Client 服务 和 Gateway 服务，在服务中植入 Skywalking Java 代理。

微服务的部署详情可参见我的上一篇文章《Kubernetes（K8s）部署 SpringCloud 服务实战》（https://www.cnblogs.com/w84422/p/15630185.html）

## 3. Skywalking 控制台的搭建

### 3.1 下载 Skywalking 控制台程序

官网下载地址：https://skywalking.apache.org/downloads/

![img](https://gitee.com/er-huomeng/img/raw/master/2513105-20211204180438090-998976754.png)

### 3.2 将程序包上传到 CentOS7 服务器，并解压

这里上传到 /home 目录

```bash
# tar -zxvf apache-skywalking-apm-8.8.1.tar.gz
```

### 3.3 启动 Skywalking 控制台

**注意：该服务器要预先安装 JDK8，并在环境变量中设置。**

**Skywalking 会占用 8080 和 11800 端口。**

```bash
# cd /home/apache-skywalking-apm-bin/bin
# ./startup.sh
```

### 3.4 在浏览器访问 Skywalking 控制台

[http://192.168.1.15:8080](http://192.168.1.15:8080/)

![img](https://gitee.com/er-huomeng/img/raw/master/2513105-20211204181125344-1164338507.png)

 

##  4. 在微服务中植入 Skywalking Java 代理

### 4.1 概述

在微服务中需要植入 Skywalking Java 代理，才能将运行数据传递给 Skywalking 控制台。

Skywalking 的 Java 代理，支持 java -jar、Tomcat、Docker、Kubernetes（K8s）等。

### 4.2 java -jar 方式植入代理

**1）首先从官网下载 SkyWalking Java Agent 程序，上传到 CentOS7 服务器，解压**

官网下载地址：https://skywalking.apache.org/downloads/

![img](https://gitee.com/er-huomeng/img/raw/master/2513105-20211204194728316-144240078.png)

 

 **2）在 CentOS7 服务器设置环境变量**

SW_AGENT_COLLECTOR_BACKEND_SERVICES：Skywalking控制台的地址，例如：192.168.1.15:11800，默认是 127.0.0.1:11800

**3）启动微服务时，使用以下方式**

```bash
# java -javaagent:/path/to/skywalking-agent/skywalking-agent.jar=agent.service_name=服务的名称 -jar yourApp.jar

path/to/skywalking-agent/skywalking-agent.jar 替换成真实的 SkyWalking Java Agent 所在的路径。
agent.service_name 是服务的名称，用于 Skywalking 控制台中的显示。
```

### 4.3 Docker 中的微服务植入代理

**1）编排 Dockerfile 文件**

将之前的 FROM java:8 替换为 FROM apache/skywalking-java-agent:8.5.0-jdk8 即可，其他不用动

**2）设置环境变量**

SW_AGENT_NAME：容器中服务的名称，用于 Skywalking 控制台中的显示。

SW_AGENT_COLLECTOR_BACKEND_SERVICES：Skywalking控制台的地址，例如：192.168.1.15:11800，默认是 127.0.0.1:11800

### 4.4 Kubernetes（K8s）中的微服务植入代理

#### 4.4.1 重新部署 eureka client 的 Deployment

**1）编辑脚本**

```bash
vi eurekaclient-deployment-sw.yml
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-eureka-client
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-eureka-client
  template:
    metadata:
      labels:
        app: my-eureka-client
    spec:
      volumes:
        - name: skywalking-agent
          emptyDir: { }

      initContainers:
        - name: agent-container
          image: apache/skywalking-java-agent:8.7.0-alpine
          volumeMounts:
            - name: skywalking-agent
              mountPath: /agent
          command: [ "/bin/sh" ]
          args: [ "-c", "cp -R /skywalking/agent /agent/" ]

      containers:
        - name: my-eureka-client
          image: myeurekaclient:1.0
          volumeMounts:
            - name: skywalking-agent
              mountPath: /skywalking
          env:
            - name: JAVA_TOOL_OPTIONS
              value: "-javaagent:/skywalking/agent/skywalking-agent.jar"
            - name: SW_AGENT_NAME
              value: "my-eureka-client"
            - name: SW_AGENT_COLLECTOR_BACKEND_SERVICES
              value: "192.168.1.15:11800"
```

脚本的大概意思是pull apache/skywalking-java-agent:8.7.0-alpine 镜像，然后挂载一个空目录，将 Skywalking 的 Java 代理程序拷贝到目录中，然后微服务的容器也去挂载这个目录，并使用里面的文件，配合环境变量向  Skywalking 控制台发送数据。

 **2）删除之前 deployment**

\# kubectl delete deployment my-eureka-client

 **3）执行脚本**

\# kubectl apply -f eurekaclient-deployment-sw.yml

#### 4.4.2 重新部署 Gateway 的 Deployment

**1）编辑脚本**

vi gateway-deployment-sw.yml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-gateway
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-gateway
  template:
    metadata:
      labels:
        app: my-gateway
    spec:
      volumes:
        - name: skywalking-agent
          emptyDir: { }

      initContainers:
        - name: agent-container
          image: apache/skywalking-java-agent:8.7.0-alpine
          volumeMounts:
            - name: skywalking-agent
              mountPath: /agent
          command: [ "/bin/sh" ]
          args: [ "-c", "cp -R /skywalking/agent /agent/" ]

      containers:
        - name: my-gateway
          image: mygateway:1.0
          volumeMounts:
            - name: skywalking-agent
              mountPath: /skywalking
          env:
            - name: JAVA_TOOL_OPTIONS
              value: "-javaagent:/skywalking/agent/skywalking-agent.jar"
            - name: SW_AGENT_NAME
              value: "my-gateway"
            - name: SW_AGENT_COLLECTOR_BACKEND_SERVICES
              value: "192.168.1.15:11800"
```

**2）删除之前 deployment**

```bash
# kubectl delete my-gateway
```

**3）执行脚本**

```bash
# kubectl apply -f gateway-deployment-sw.yml
```

#### 4.4.3 访问 Eureka Client 的简单接口

GET http://192.168.1.12:44000/my-eureka-client/eurekaClient/hello

#### 4.4.4 Skywalking Demo数据展示

 此时可以从 Skywalking 中看到接口的调用情况，一些指标的统计图，拓扑图、链路追踪等信息，可以帮助我们很好的监控集群，定位问题，快速的对微服务进行优化。

![img](https://gitee.com/er-huomeng/img/raw/master/2513105-20211204172646330-795395451.png)

 

![img](https://gitee.com/er-huomeng/img/raw/master/2513105-20211204173039494-603533987.png)

 

![img](https://gitee.com/er-huomeng/img/raw/master/2513105-20211204173123530-133379719.png)

 

 ![img](https://gitee.com/er-huomeng/img/raw/master/2513105-20211204173206277-1725674744.png)

 

![img](https://gitee.com/er-huomeng/img/raw/master/2513105-20211204172733341-2044951160.png)

 

![img](https://gitee.com/er-huomeng/img/raw/master/2513105-20211204173914489-1709370358.png)

 

 ![img](https://gitee.com/er-huomeng/img/raw/master/2513105-20211204174108546-1254746493.png)

 