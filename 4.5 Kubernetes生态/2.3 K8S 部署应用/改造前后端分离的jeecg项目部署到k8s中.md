- [改造前后端分离的jeecg项目部署到k8s中](https://www.cnblogs.com/sanduzxcvbnm/p/14719105.html)

大致步骤如下：
 1.创建MySQL，redis等辅助组件
 2.创建jeecg-boot后端应用
 3.创建jeecg-vue前端应用

# 0.说明

1.从GitHub上下载项目的zip压缩包后，解压缩可以看到，ant-design-vue-jeecg是前端模块，jeecg-boot是后端模块
 2.按照开发文档上的先在本地配置好前后端所需要的环境。
 3.在k8s中创建一个jeecg-boot的名称空间，若无特别说明，以下所有服务都是在该空间创建的
 4.部署流程大致是这样的，先在本地把前后端都跑通，然后再创建Dockerfile和.gitlab-ci文件，往gitlab提交代码(事先配置好gitlab-runner)，创建镜像，推送到仓库，自动发布更新到k8s上(首次需要用yaml文件创建有关pod,service等)
 5.我这里采用了俩git仓库，前端一个，后端一个

# 1.创建MySQL，redis等辅助组件

说白了也就是创建好MySQL服务，redis服务，后端项目中连接需要使用。
 我这里采用的是在k8s中创建的，当然也可以创建普通的那种应用。

以下说的都是在k8s中创建举例的
 MySQL和Redis服务，均创建了服务类型是nodeport的service,然后使用宿主机上的软件连接进行测试。等整个项目跑起来运行后再换成service是clusterip的服务类型
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210429163912686-842108202.png)
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210429164142026-27249426.png)

MySQL创建创建好后，需要导入相应的sql文件。
 sql文件名称：jeecg-boot\db\jeecgboot-mysql-5.7.sql

但是等后端项目运行后会碰到一个问题，有些数据表明是需要大写的，主要是qrtz开头的数据表名
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210429163654489-1780152762.png)

导入sql文件后，把所有qrtz开头的数据表名全部换成大写的数据表名，避免后端项目启动后连接数据库提示有些表不存在

最后启动MySQL和Redis服务。

# 2.后端项目

0.项目结构

```
├─jeecg-boot-parent（父POM： 项目依赖、modules组织）
│  ├─jeecg-boot-base（共通模块： 工具类、config、权限、查询过滤器、注解、接口等）
│  ├─jeecg-boot-module-demo    示例代码
│  ├─jeecg-boot-module-system （系统管理权限等功能） -- 默认作为启动项目
│  ├─jeecg-boot-starter（微服务starter模块，不需要微服务可以删掉） (我这边操作的时候给删除了)
│  ├─jeecg-cloud-module（微服务生态模块，不需要微服务可以删掉）(我这边操作的时候给删除了)
```

1.修改项目配置文件（数据库配置、redis配置）
 配置文件： jeecg-boot-module-system/src/main/resources/application-dev.yml
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210429164254362-1946266606.png)
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210429164307021-1799163539.png)

2.启动项目&访问
 本地启动：jeecg-boot-module-system/src/main/java/org/jeecg/JeecgSystemApplication.java，右键执行启动。
 通过 http://localhost:8080/jeecg-boot/doc.html 访问后台，默认进入swagger文档首页

本地运行
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210429164931394-1128242479.png)

本地启动后的日志显示
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210429165022528-544481582.png)

3.创建Dockerfile文件
 需要说明的是需要的项目只有jeecg-boot-module-system，所以把Dockerfile文件创建在jeecg-boot-module-system根目录下
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210429165219088-1680595611.png)

Dockerfile文件具体文件内容如下：

```
FROM jdd.io/jre:1.8.275
MAINTAINER 1103324414@qq.com
ADD target/jeecg-boot-module-system-2.4.3.jar app.jar
ENV JAVA_OPTS=""
ENTRYPOINT [ "sh", "-c", "java $JAVA_OPTS -Djava.security.egd=file:/dev/./urandom -jar app.jar" ]
```

说明：开头第一行是使用的基础镜像，创建方式详看地址：https://www.cnblogs.com/sanduzxcvbnm/p/13220054.html
 基础镜像中只有jdk环境，其他的都没有了。

4.创建.gitlab-ci文件
 这个文件创建在整个项目的根目录下
 需要注意的是gitlab-runner使用的构建镜像环境，需要包含开发文档中说的后端项目需要使用的那些软件。

> 我这边图省事儿，前后端构建项目使用的是同一个构建镜像，包含的软件就比较多了：jdk,maven,curl,docker，nodejs,yarn等，具体构建方式可以看地址：https://www.cnblogs.com/sanduzxcvbnm/p/13220054.html

还有注意的一点，jeecg需要使用到一些私服的依赖，详看地址：http://doc.jeecg.com/2043876
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210429170403344-732324619.png)

```
<mirrors>
   <mirror>
      <id>nexus-aliyun</id>
      <mirrorOf>*,!jeecg,!jeecg-snapshots,!getui-nexus</mirrorOf>
      <name>Nexus aliyun</name>
      <url>http://maven.aliyun.com/nexus/content/groups/public</url>
    </mirror> 
 </mirrors>
```

所以在构建刚才的镜像时，添加的maven需要修改以下settings.xml配置文件。
 我这边采取的方式是事先准备好已经修改好的settings.xml配置文件，然后在构建过程中copy到镜像中，替换原有的配置文件

```
FROM alpine:latest
MAINTAINER sandu <1103324414@qq.com>
COPY localtime /etc/localtime
COPY timezone /etc/timezone
RUN echo "https://mirrors.aliyun.com/alpine/latest-stable/main/" > /etc/apk/repositories
RUN echo "https://mirrors.aliyun.com/alpine/latest-stable/community/" >> /etc/apk/repositories
RUN ["apk","update"]
RUN ["apk","add","curl"]
RUN ["apk","add","openjdk8"]
RUN ["apk","add","maven"]
RUN ["apk","add","nodejs"]
COPY settings.xml /usr/share/java/maven-3/conf/settings.xml
RUN ["apk","add","docker"]
```

构建好这个镜像后，修改gitlab-runner使用的镜像，然后重启gitlab-runner
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210429170811505-470487837.png)

> 注意：不能把这个镜像跟后端dockerfile文件中使用的镜像混为一谈，这俩是里面安装的软件不一样

.gitlab-ci.yml文件内容如下：

```
variables:
  DOCKER_DRIVER: overlay2
  MAVEN_CLI_OPTS: "-s .m2/settings.xml --batch-mode"
  MAVEN_OPTS: "-Dmaven.repo.local=.m2/repository"

cache:
  paths:
    - .m2/repository/

stages:
  - package
  - build

maven_step:
  tags:
    - maven
  stage: package
  script:
    - mvn clean package -Dmaven.test.skip=true # 编译整个项目
  artifacts:
    paths:
      - jeecg-boot-module-system/target/*.jar # 注意这行,只要其中一个jar包,供下面的docker使用
  only:
    - develop

docker_step:
  tags:
    - docker
  stage: build
  script:
    - export TAG=`date "+%Y%m%d%H%M%S"`
    - docker login -u admin -p admin123 jdd.io
    - cd jeecg-boot-module-system
    - docker build -t jdd.io/demo:$TAG .
    - docker push jdd.io/demo:$TAG
  only:
    - develop
```

构建的思路如下：先编译打包整个项目，然后切换到所需要jar包的目录下，然后根据这个目录下的Dockerfile文件制作docker镜像，并上传到Nexus镜像仓库，这里指的是jeecg-boot-module-system

流水线上显示的效果,需要事先配置好gitlab-runner
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210429174853686-1702724466.png)
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210429171335145-378682588.png)
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210429171404013-1154933217.png)
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210429171418919-2042543922.png)
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210429171440901-2075210533.png)

后期可以在增加上自动发布到k8s上，如下这个仅供展示,实际中未操作：（新增加curl一行）

```
docker_step:
  tags:
    - docker
  stage: build
  script:
    - export TAG=`date "+%Y%m%d%H%M%S"`
    - docker login -u admin -p admin123 jdd.io
    - cd jeecg-boot-module-system
    - docker build -t jdd.io/demo:$TAG .
    - docker push jdd.io/demo:$TAG
    - curl -X PUT -H "content-type:application/json" -H "Cookie:KuboardUsername=admin;KuboardAccessKey=4jz66jfsa6t6.5wjsz733f73p5fei4h4fpbmnfp72ytbc" http://192.168.2.163:10080/kuboard-api/cluster/develop/kind/CICDApi/admin/resource/updateImageTag -d '{"kind":"deployments","namespace":"test","name":"web-spring","images":{"jdd.io/demo":"jdd.io/demo:'$TAG'"}}'
  only:
    - develop
```

pod启动后的日志展示，里面出现的是pod的地址，因为pod的特性，所以访问后端使用的话，还需要创建一个service，采用clusterip服务类型
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210429171735871-1795419917.png)
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210429171830942-671027392.png)

以后访问后端，直接使用ClusterIP+服务端口的形式就可以了。

> 当然可以先创建service，采用NodePort的服务类型，然后通过宿主机IP+NodePort的形式，直接访问后端应用，比如接口文档，查看以下效果，地址：[http://宿主机IP](http://xn--IP-wz2c754c5qn):NodePort/jeecg-boot/doc.html

# 3.创建前端

前端最主要的是使用生成的dist文件夹，这里结合nginx，把两者直接整个进同一个镜像中，这样一来，启动这个容器，nginx直接就启动了，nginx访问路径正好是vue的dist文件夹里面的东西

关于vue配置文件的说明

1. vue.config.js文件中的配置是在本地开发的时候使用的,此处映射地址配置到后台端口即可，如果后台项目名字修改了的话，直接改“/jeecg-boot”
    ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210429173014387-208424090.png)
2. .env文件是用来选择项目构建时使用哪个配置文件的，主要是有关.env.development和.env.production文件的，这里写的是哪个，项目采用的就是哪个配置文件，这里写的是NODE_ENV=production，说明采用的是.env.production文件
    ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210429173234766-2012316613.png)

3.关于.env.production文件中的配置
 这个地址应该是配置连接后端项目的，也就是后端项目启动后日志中显示的那个地址。但是在这里做了特殊的设置，主要是跟下面的Dockerfile文件中nginx的配置和后期创建的Ingress有关，稍后再详讲解这个。
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210429173506486-1116856740.png)

直接在前端项目根目录下创建Dockerfile文件，文件内容如下：

```
# build stage
FROM node:lts-alpine as build-stage # 采用alpine镜像，多阶段构建方式
MAINTAINER 1103324414@qq.com
COPY .  /app/ # 把跟目录下所有文件拷贝到上面镜像的/app目录下，该目录不存在的话会自动创建
WORKDIR /app/ # 切换容器中的当前工作目录
RUN npm config set registry https://registry.npm.taobao.org/ && yarn install && yarn run build # 设置nodejs仓库源，安装依赖，打包


# production stage
FROM nginx:stable-alpine as production-stage
# 拷贝dist目录下的所有文件到/usr/share/nginx/html/目录下,不包含dist文件夹
COPY --from=build-stage /app/dist /usr/share/nginx/html/
ENV LANG en_US.UTF-8
# 设置nginx中的配置文件内容
RUN echo "server {  \
                      listen       80; \
                      location ^~ /jeecg-boot { \
                      proxy_pass              http://10.3.255.203:8080/jeecg-boot/; \
                      proxy_set_header        Host jeecg-boot-system; \
                      proxy_set_header        X-Real-IP \$remote_addr; \
                      proxy_set_header        X-Forwarded-For \$proxy_add_x_forwarded_for; \
                  } \
                  #解决Router(mode: 'history')模式下，刷新路由地址不能找到页面的问题 \
                  location / { \
                     root   /usr/share/nginx/html/; \
                     index  index.html index.htm; \
                     if (!-e \$request_filename) { \
                         rewrite ^(.*)\$ /index.html?s=\$1 last; \
                         break; \
                      } \
                  } \
                  access_log  /var/log/nginx/access.log ; \
              } " > /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

说明：
 1.nginx.conf文件中没有server{}块，默认包含/etc/nginx/conf.d/*.conf, 有个默认的default.conf，这里直接替换默认的default.conf了。
 2.如下这块是配置的nginx代理后端模块的，proxy_pass中写的地址，端口就是后端项目启动的service服务，ClusterIP+服务端口，详看上面的图

```
location ^~ /jeecg-boot { 
    proxy_pass              http://10.3.255.203:8080/jeecg-boot/; 
    proxy_set_header        Host jeecg-boot-system; 
    proxy_set_header        X-Real-IP \$remote_addr; 
    proxy_set_header        X-Forwarded-For \$proxy_add_x_forwarded_for; 
} 
```

然后创建.gitlab-ci.yml文件，具体内容如下：

```
variables:
  DOCKER_DRIVER: overlay2
  MAVEN_CLI_OPTS: "-s .m2/settings.xml --batch-mode"
  MAVEN_OPTS: "-Dmaven.repo.local=.m2/repository"

cache:
  key: ${CI_BUILD_REF_NAME}
  paths:
    - node_modules/

stages:
  - build

docker_step:
  tags:
    - docker
  stage: build
  script:
    - export TAG=`date "+%Y%m%d%H%M%S"`
    - docker build -t jdd.io/jeecg-vue:$TAG .
    - docker login -u admin -p admin123 jdd.io
    - docker push jdd.io/jeecg-vue:$TAG
    - curl -X PUT -H "content-type:application/json" -H "Cookie:KuboardUsername=admin;KuboardAccessKey=hx35mfx3b7p6.w6wm38cbikdd4yeweexfcsfybd4zmk2s" http://192.168.2.163:10080/kuboard-api/cluster/develop/kind/CICDApi/admin/resource/updateImageTag -d '{"kind":"deployments","namespace":"jeecg","name":"my-vue","images":{"jdd.io/jeecg-vue":"jdd.io/jeecg-vue:'$TAG'"}}'
  only:
    - develop
```

构建的思路如下：直接根据这个目录下的Dockerfile文件制作docker镜像，并上传到Nexus镜像仓库，然后自动更新到k8s中(需要事先使用yaml文件创建好对应的pod,下面会讲述)

> 检查方式是登录进入，查看nginx是否启动，若启动则说明没问题。

gitlab上使用gitlab-runner自动化构建的信息如下：
 先配置好gitlab-runner（前后端用的是同一个gitlab-runner）
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210429174742639-1740917786.png)
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210429174949321-59859026.png)
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210429175019043-777164085.png)
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210429175030273-2014315425.png)
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210429175046534-855950542.png)
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210429175056244-387523577.png)

给前端pod配置一个service,这里也采用的是服务类型是ClusterIP的方式，注意，这里的容器端口就是nginx启动后监听的80端口，服务端口是供下面Ingress域名使用的端口，这里采用80端口，是为了在浏览器中输入域名访问时不用加端口号了
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210429175202924-872839697.png)

然后再配置一个Ingress，用来供外部访问，这个域名就是前端访问后端的.env.production配置文件中设置需要的，本机电脑上hosts文件需要添加一个解析
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210429175447441-645976640.png)

集群中任意一台主机ip都可以
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210429175655469-1182248363.png)

本机电脑访问的话直接使用浏览器打开域名：www.demovue.com就可以了。

问题：为啥前端的.env.production配置文件中访问后端的地址需要配置域名，而不是直接配置后端的svc ip地址？
 一开始确实是这样配置的，但是在登录页面需要输入验证码，这个验证码是从后端获取的，但是此时客户端是本机浏览器，不是vue, 浏览器中验证码访问的地址是svc ip地址，这肯定是访问不通的
 同时结合nginx配置考虑，访问后端是通过nginx代理访问的。

以上两者结合起来，需要配置域名。

浏览器访问vue主页，vue访问后端的时候，不是直接访问后端，而是访问后端时配置的是域名，然后vue又绕道nginx来访问后端。

# 4.有关yaml文件

1.后端

```
# cat Deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-demo
  namespace: jeecg
  labels:
    app: my-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-demo
  template:
    metadata:
      labels:
        app: my-demo
    spec:
      containers:
        - name: my-demo
          image: 'jdd.io/demo:20210421194224'
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 8080
          resources:
            requests:
              cpu: 400m
              memory: 600Mi
            limits:
              cpu: 800m
              memory: 800Mi
      imagePullSecrets:
      - name: regcred
# Service.yaml
apiVersion: v1
kind: Service
metadata:
  name: my-demo
  namespace: jeecg
spec:
  type: NodePort
  selector:
    app: my-demo
  ports:
    - port: 8080
      targetPort: 8080
      nodePort: 30080
```

1. 前端yaml文件

```
# Deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-vue
  namespace: jeecg
  labels:
    app: my-vue
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-vue
  template:
    metadata:
      labels:
        app: my-vue
    spec:
      containers:
        - name: my-vue
          image: jdd.io/jeecg-vue:20210421232150
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 80
          resources:
            requests:
              cpu: 400m
              memory: 600Mi
            limits:
              cpu: 800m
              memory: 800Mi
      imagePullSecrets:
      - name: regcred
# Service.yaml
apiVersion: v1
kind: Service
metadata:
  name: my-vue
  namespace: jeecg
spec:
  type: ClusterIP
  selector:
    app: my-vue
  ports:
    - port: 80
      targetPort: 80
# Ingress.yaml
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  labels:
    app: my-demo
    k8s.kuboard.cn/name: my-demo
  name: my-demo
  namespace: jeecg
spec:
  rules:
    - host: www.demovue.com
      http:
        paths:
          - backend:
              serviceName: my-demo
              servicePort: 80
            path: /
```

最终效果
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210429181531308-1055810684.png)

# 问题

1.构造出来的docker镜像太大
 后端镜像有500多M，前端镜像有39.3M

从后端Dockerfile文件入手，逐步排查
 首先使用的FROM基础镜像，这个基础镜像只是用来提供java运行环境的，只要jre就可以，没必要用jdk
 改造文章参考：https://www.cnblogs.com/sanduzxcvbnm/p/13220054.html
 先运行依赖镜像：

```
docker run -it alpine:latest 
```

替换里面的镜像源文件，更新：

```
echo "https://mirrors.aliyun.com/alpine/latest-stable/main/" > /etc/apk/repositories
echo "https://mirrors.aliyun.com/alpine/latest-stable/community/" >> /etc/apk/repositories
apk update
```

然后搜索jdk

```
apk search jdk
```

![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210430093003550-1153130891.png)

通过观察发现java8的有好多个。
 逐个安装排查
 先安装openjdk8-jre

```
apk add openjdk8-jre
```

![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210430093329807-1773949602.png)
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210430093349599-1323549659.png)

通过观察，安装openjdk8-jre的同时也会安装openjdk8-jre-lib和openjdk8-jre-base，结果是：OK: 106 MiB in 61 packages

卸载openjdk8-jre，安装openjdk8

```
apk del openjdk8-jre
apk add openjdk8
```

![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210430093650906-389386849.png)
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210430093723024-988833516.png)

通过观察可以得知，安装openjdk8的同时，也会安装openjdk8-jre，openjdk8-jre-lib和openjdk8-jre-base。结果是：OK: 125 MiB in 62 packages

最终采用安装openjdk8-jre来构建Dockerfile文件中的基础镜像 (# alpine中安装软件默认是没有开启缓存的,所以装完也不用清缓存)

```
FROM alpine:latest
MAINTAINER sandu <1103324414@qq.com>
COPY localtime /etc/localtime
COPY timezone /etc/timezone
RUN echo "https://mirrors.aliyun.com/alpine/latest-stable/main/" > /etc/apk/repositories
RUN echo "https://mirrors.aliyun.com/alpine/latest-stable/community/" >> /etc/apk/repositories
RUN ["apk","update"]
RUN ["apk","add","openjdk8-jre"]
```

制作基础镜像：

```
docker build -t jdd.io/jre:1.8.0_275 -f Dockerfile_alpine .
```

制作后的镜像大小112MB，基本上是达到要求
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210430094323612-363107726.png)

若是还想进一步降低大小的话，只能安装openjdk8-jre较低版本的了。
 因为文件/etc/apk/repositories采用的是alpine的最新镜像库文件，所以只有1.8.0_275这一个最新版本。
 想要安装低版本的，首先查看网站http://mirrors.aliyun.com/alpine/中各个不同的alpine版本镜像，找到所需要安装的那个jre1.8版本，使用这个版本的镜像源，然后再安装，这里就不在操作了。

然后使用后端的Dockerfile文件制作镜像，最后得到的镜像大小如下：
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210430101142947-734641941.png)

以上步骤都是单独操作获取的数据，在gitlab上使用gitlab-runner构建编译查看得知，后端镜像大小是252MB。之前相比，镜像大小减小了一半多。

前端镜像，单独编译出的dist目录有17M，再加上使用的nginx镜像：nginx:stable-alpine ，有22.6MB
 这两者加一块儿大约有39.6M，比开头说的39.3M多了0.3M, 所以前端使用的镜像没必要精简
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210430114011174-705425306.png)
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210430114257807-865743605.png)
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210430114359409-1936327505.png)

2.增加使用使用服务状态探针进行健康检查
 Dockerfile文件中需要用EXPOSE暴露端口
 参考文章：https://www.cnblogs.com/sanduzxcvbnm/p/14710189.html

3.首页访问慢
 开启Nginx压缩，解决前端访问慢问题，官方文档：http://doc.jeecg.com/2043891

项目中采用的是nginx和vue的dist打包在一起，nginx配置文件没有从中分离出来，这里采用得方式是在原有Dockefile文件基础上修改默认得nginx.conf文件
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210430120850838-2060790719.png)

4.前端Dockerfile文件整理
 可以试着把`yarn install && yarn build`的功能放在.gitlab-ci.yml文件中来执行，顺便打包dist文件夹供下载，并且提供到下一步docker镜像使用
 若是这样的话，Dockerfile文件中也可以把nginx配置文件nginx.conf和default.conf给单独提出来，使用的时候COPY进去。或者直接把default.conf中内容给整合进nginx.conf中。

这样一来gitlab-runner使用的基础镜像还得修改，增加安装nodejs和yarn，通过查看，安装的两者版本vue前端项目的要求
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210430124327264-213276091.png)
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210430124547895-1064563513.png)
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210430124621705-1131397768.png)

不过经检查后发现，安装的nodejs并没有npm命令，所以还得再安装npm.
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210430125109189-1251749004.png)

然后更换gitlab-runner使用的镜像
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210430130035855-2131100359.png)

接下来是创建nginx.conf文件，整合进default.conf文件的内容，先.gitlab-ci.yml文件，确保vue编译成功dist目录后打包压缩，供下一步的Dockerfile文件文件使用
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210430132423107-414161954.png)

gitlab上实际操作信息如下：
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210430130415190-1064242776.png)
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210430130428934-1773049246.png)
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210430130439404-1173313276.png)
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210430130558182-1455347153.png)
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210430131949584-388979825.png)

![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210430131719734-1862929406.png)

![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210430132149779-341441475.png)
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210430132224715-683166060.png)
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210430132250144-883946280.png)

接下来修改Dockerfile文件内容
 需要注意的是牵涉到把上一步的压缩包dist.tar.gz整合到镜像中来，所以压缩包dist.tar.gz怎么压缩是有讲究的
 1.若是压缩包解压后是一个dist文件夹，那么nginx.conf文件就得修改，`root   /usr/share/nginx/html/;`就得换成`root   /usr/share/nginx/html/dist/;`
 2.若是压缩包解压后是dist文件夹下的内容，不包含dist文件夹，则Dockerfile文件和nginx.conf文件都不用修改

这里采用的是第二种方法，所以.gitlab-ci.yml文件关于制作压缩包还得再次修改一下
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210430135710731-1483902541.png)

```
variables:
  DOCKER_DRIVER: overlay2
  
cache:
  key: ${CI_BUILD_REF_NAME}
  paths:
    - node_modules/

stages:
  - package
  - build


yarn_step:
  tags:
    - yarn
  stage: package
  script:
    - npm config set registry https://registry.npm.taobao.org/
    - yarn install
    - yarn build
    - cd dist && tar -zcvf ../dist.tar.gz * # 打包整个dist文件(包含目录dist)和打包dist下的文件(不包含目录dist)跟DOckerfile文件中ADD有关，进而影响到nginx.conf文件
  artifacts:
    paths:
      - dist.tar.gz
  only:
    - develop

docker_step:
  tags:
    - docker
  stage: build
  script:
    - export TAG=`date "+%Y%m%d%H%M%S"`
    - docker build -t jdd.io/jeecg-vue:$TAG .
    - docker login -u admin -p admin123 jdd.io
    - docker push jdd.io/jeecg-vue:$TAG
#    - curl -X PUT -H "content-type:application/json" -H "Cookie:KuboardUsername=admin;KuboardAccessKey=4jz66jfsa6t6.5wjsz733f73p5fei4h4fpbmnfp72ytbc" http://192.168.2.163:10080/kuboard-api/cluster/develop/kind/CICDApi/admin/resource/updateImageTag -d '{"kind":"deployments","namespace":"test","name":"web-spring","images":{"jdd.io/demo":"jdd.io/demo:'$TAG'"}}'
    - curl -X PUT -H "content-type:application/json" -H "Cookie:KuboardUsername=admin;KuboardAccessKey=hx35mfx3b7p6.w6wm38cbikdd4yeweexfcsfybd4zmk2s" http://192.168.2.163:10080/kuboard-api/cluster/develop/kind/CICDApi/admin/resource/updateImageTag -d '{"kind":"deployments","namespace":"jeecg","name":"my-vue","images":{"jdd.io/jeecg-vue":"jdd.io/jeecg-vue:'$TAG'"}}'
  only:
    - develop
```

Dockerfile文件内容
 COPY命令会覆盖源文件，ADD命令会把压缩包dist.tar.gz自动解压缩到/usr/share/nginx/html/ (不含dist文件夹)

![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210430135736399-906353445.png)

```
FROM nginx:stable-alpine
MAINTAINER 1103324414@qq.com
COPY nginx.conf /etc/nginx/nginx.conf
ADD dist.tar.gz /usr/share/nginx/html/
ENV LANG en_US.UTF-8
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

nginx.conf文件内容如下

```
user  nginx;
worker_processes  auto;

error_log  /var/log/nginx/error.log notice;
pid    /var/run/nginx.pid;

events {
    worker_connections  65535;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    tcp_nopush     on;
    keepalive_timeout  65;
    server_tokens off;

    gzip on;
    gzip_min_length 1k;
    gzip_comp_level 9;
    gzip_types text/plain application/javascript application/x-javascript text/css application/xml text/javascript application/x-httpd-php image/jpeg image/gif image/png;
    gzip_vary on;
    gzip_disable "MSIE [1-6]\.";

    # include /etc/nginx/conf.d/*.conf;
    server {
      listen       80; # 注意：不加域名
      location ^~ /jeecg-boot {
        proxy_pass              http://10.3.255.203:8080/jeecg-boot/; # 使用的是后端SVC cluster ip
        proxy_set_header        Host jeecg-boot-system;
        proxy_set_header        X-Real-IP \$remote_addr;
        proxy_set_header        X-Forwarded-For \$proxy_add_x_forwarded_for;
      }
      #解决Router(mode: 'history')模式下，刷新路由地址不能找到页面的问题
      location / {
         root   /usr/share/nginx/html/;
         index  index.html index.htm;
         if (!-e \$request_filename) {
             rewrite ^(.*)\$ /index.html?s=\$1 last;
             break;
          }
      }
      access_log  /var/log/nginx/default_access.log  main;
    }
}
```

最终效果
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210430140051448-2042413757.png)
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210430140101310-1743351584.png)
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210430140304197-1148497039.png)
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210430140325705-2082250600.png)
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210430140439711-820426277.png)
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210430140339733-1275717109.png)

制作出来的前端镜像大小还是跟原来的一样，39.3M
 ![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210430140456450-479241874.png)

用浏览器访问网址：[http://www.demovue.com进行测试](http://www.demovue.xn--com-c74g856igpe64h)，可以明显感觉到页面打开速度加快了好多