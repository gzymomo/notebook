## 必要条件

1. K8S环境机器做部署用，推荐一主双从。[推荐安装文档](https://kuboard.cn/install/install-k8s.html#from_org_cn)
2. Docker Harbor私有仓库，准备完成后在需要使用仓库的机器docker login。
3. 开发机器需要Docker环境，build及push使用

#### maven配置

##### 1. properties配置

```xml
 <properties>
     <docker.image.prefix>pasq</docker.image.prefix>
     <!-- docker harbor地址 -->
     <docker.repostory>192.168.1.253:8081</docker.repostory>
 </properties>
12345
```

##### 2. plugins配置

```xml
<plugins>
    <plugin>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-maven-plugin</artifactId>
    </plugin>
    <!-- 使用Maven插件直接将应用打包为一个Docker镜像 -->
    <plugin>
        <groupId>com.spotify</groupId>
        <!-- 这里使用新版dockerfile-maven-plugin插件 -->
        <artifactId>dockerfile-maven-plugin</artifactId>
        <version>1.4.10</version>
        <configuration>
            <!-- Dockerfile目录指定 -->
            <dockerfile>src/main/docker/Dockerfile</dockerfile>
            <repository>${docker.repostory}/${docker.image.prefix}/${project.artifactId}</repository>
            <!-- 生成镜像标签 如不指定 默认为latest -->
            <tag>${project.version}</tag>
            <buildArgs>
                <!-- 理论上这里定义的参数可以传递到Dockerfile文件中，目前未实现 -->
                <JAR_FILE>target/${project.build.finalName}.jar</JAR_FILE>
            </buildArgs>
        </configuration>
    </plugin>
</plugins>
```

#### 三、Dockerfile文件

```bash
#基础镜像，如果本地仓库没有，会从远程仓库拉取
FROM openjdk:8-jdk-alpine
#容器中创建目录
RUN mkdir -p /usr/local/pasq
#编译后的jar包copy到容器中创建到目录内
COPY target/dockertest-0.0.1.jar /usr/local/pasq/app.jar
#指定容器启动时要执行的命令
ENTRYPOINT ["java","-jar","/usr/local/pasq/app.jar"]
```

### 构建镜像并推送

1. 构建镜像，执行如下命令
   ![插件编译](https://img-blog.csdnimg.cn/20190924185504630.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L20wXzM3MDYzNzg1,size_16,color_FFFFFF,t_70)
   构建镜像日志如下
   ![编译日志](https://img-blog.csdnimg.cn/20190924185701972.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L20wXzM3MDYzNzg1,size_16,color_FFFFFF,t_70)
2. 完成后`docker images`可以查看打包的镜像
   ![在这里插入图片描述](https://img-blog.csdnimg.cn/20190924185804504.png)
3. 命令窗口执行`docker push REPOSITORY`推送至docker harbor
   ![推送](https://img-blog.csdnimg.cn/20190924190446920.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L20wXzM3MDYzNzg1,size_16,color_FFFFFF,t_70)
   docker harbor可以查看到推送的镜像
   ![dockerharbor](https://img-blog.csdnimg.cn/2019092419055146.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L20wXzM3MDYzNzg1,size_16,color_FFFFFF,t_70)

### K8S部署

#### 1. 创建dockertest.yaml文件如下

```yaml
apiVersion: v1
kind: Service
metadata:
  name: dockertest
  namespace: default
  labels:
    app: dockertest
spec:
  type: NodePort
  ports:
  - port: 8080
    nodePort: 30090 #service对外开放端口
  selector:
    app: dockertest
---
apiVersion: apps/v1
kind: Deployment #对象类型
metadata:
  name: dockertest #名称
  labels:
    app: dockertest #标注 
spec:
  replicas: 3 #运行容器的副本数，修改这里可以快速修改分布式节点数量
  selector:
    matchLabels:
      app: dockertest
  template:
    metadata:
      labels:
        app: dockertest
    spec:
      containers: #docker容器的配置
      - name: dockertest
        image: 192.168.1.253:8081/pasq/dockertest:0.0.1 # pull镜像的地址 ip:prot/dir/images:tag
        imagePullPolicy: IfNotPresent #pull镜像时机，
        ports:
        - containerPort: 8080 #容器对外开放端口
```

#### 2. 运行`kubectl create -f dockertest.yaml`创建Deployment

完成后执行`kubectl get pods`如下图，可以看到启动了三个pod
![getpods](https://img-blog.csdnimg.cn/20190924191239961.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L20wXzM3MDYzNzg1,size_16,color_FFFFFF,t_70)

#### 3. 运行`kubectl logs -f podsname`查看日志

新开窗口分别查看3个pod的日志，然后访问`k8s master节点IP+service对外开放端口`访问springboot应用，我这里使用`http://192.168.1.250:30090/test/test`, 多刷新几次可以看到pod直接做了负载，如下图：
pods1:
![pods1](https://img-blog.csdnimg.cn/20190924191810892.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L20wXzM3MDYzNzg1,size_16,color_FFFFFF,t_70)
pods2:
![pods2](https://img-blog.csdnimg.cn/20190924191825921.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L20wXzM3MDYzNzg1,size_16,color_FFFFFF,t_70)
pods3:
![pods3](https://img-blog.csdnimg.cn/20190924191844629.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L20wXzM3MDYzNzg1,size_16,color_FFFFFF,t_70)
运行`kubectl delete -f dockertest.yaml`可以删除pods与service
修改dockertest.ymal 中replicas数量后，运行`kubectl apply -f dockertest.yaml`可以扩容或收缩副本数量

