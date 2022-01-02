- [自动化集成：Pipeline整合Docker容器](https://www.cnblogs.com/cicada-smile/p/15757248.html)

> 前言：该系列文章，围绕持续集成：Jenkins+Docker+K8S相关组件，实现自动化管理源码编译、打包、镜像构建、部署等操作；**本篇文章主要描述流水线集成Docker用法**。

![img](https://img2020.cnblogs.com/blog/1691717/202201/1691717-20220102113429376-804789512.png)

## 一、背景描述

微服务架构是当前主流的技术选型，在业务具体落地时，会存在很多业务服务，不管是在开发、测试、上线的任意节点中，如果基于手动编译的方式打包服务，操作成本不仅极高，而且很容易出现纰漏。

通过Pipeline流水线的方式，将服务镜像构建编排成一键触发执行，实现自动化的管理流程，是微服务架构中的必要的功能模块。

## 二、流程设计

本篇中的流程节点，主要针对打包好的应用`Jar`包，在docker模块中的处理流程，主要是镜像构建管理与容器运行：

![img](https://img2020.cnblogs.com/blog/1691717/202201/1691717-20220102113408832-1554156365.png)

- 构建docker文件目录与内容；
- 拷贝`Jar`包，创建`Dockerfile`脚本文件；
- 执行docker镜像构建，推送云仓库；
- 拉取镜像文件并运行docker容器；

整个流程的都放在Pipeline流水线中，衔接在本地Jar包生成之后。

## 三、实现过程

### 1、插件安装

首先安装流程中Docker集成的相关插件：`Docker Pipeline`，`Docker plugin`，`CloudBees Docker Hub/Registry Notification`。

在之前的流水线篇幅中，已经通过流水线完成Gitee仓库代码pull和本地打包，下面开始处理docker环节。

### 2、镜像构建脚本

关于Dockerfile的脚本语法也可以参考之前docker篇幅，下面看流水线中的用法：

```
    environment {
        docker_directory = 'docker-app'
        docker_repository = '仓库URL'
    }
    
        stage('Dockerfile') {
            steps {
                sh '''
                rm -rf ${docker_directory}
                mkdir -p ${docker_directory}
                cp auto-client/target/auto-client-1.0-SNAPSHOT.jar ${docker_directory}/auto-client.jar
                cd ${docker_directory}
cat>Dockerfile<<EOF
FROM java:8
MAINTAINER cicadasmile
VOLUME /data/docker/logs
ADD auto-client.jar application.jar
ENTRYPOINT ["java","-Dspring.profiles.active=dev","-Djava.security.egd=file:/dev/./urandom","-jar","/application.jar"]
EOF
                cat Dockerfile
                '''
                echo "create Dockerfile success"
            }
        }
```

脚本说明：

- 在流水线的工作空间创建目录`docker-app`；
- 每次执行都清空一次docker目录，再把Jar包和Docker脚本放进去；
- cat-EOF-EOF：即创建Dockerfile文件，并把中间的内容写入；
- 脚本中的内容必须在文件中顶行写入；

### 3、打包推送

这里即进入docker目录，执行镜像打包的操作，并把镜像推送到云端仓库，很多仓库都是私有的，需要身份验证，通过配置凭据去访问：

```
stage('DockerImage'){
    steps {
        script {
            dir("${docker_directory}") {
                sh 'ls'
                docker.withRegistry("${docker_directory}", '访问凭据') {
                   docker.build("doc-line-app:latest").push()
                }
            }
            echo "build DockerImage success"
        }
    }
}
```

### 4、凭据配置

打开`Manage Jenkins`界面，`Manage Credentials`选项；

![img](https://img2020.cnblogs.com/blog/1691717/202201/1691717-20220102113448229-376753985.png)

按如下流程配置即可：

![img](https://img2020.cnblogs.com/blog/1691717/202201/1691717-20220102113458394-1782606262.png)

------

**同系列推荐**：

- [Jenkins管理工具详解](https://mp.weixin.qq.com/s/XnrharTU22GypqcJcDuwiw)
- [Pipeline流水语法详解](https://mp.weixin.qq.com/s/tWKXEcPXzD2muOeEv0GhuQ)
- [Docker容器入门简介](https://mp.weixin.qq.com/s/9gqbJFFyRM0FiXBXRYwqyA)
- [服务自动化部署和管理](https://mp.weixin.qq.com/s/kzcqGeZ8paRodFn7NZaf1w)
- [微服务组件二次浅封装](https://mp.weixin.qq.com/s/yApUyG1xH8Geg8oR1NM1IQ)

------

## 四、源代码地址

```
GitEE·地址
https://gitee.com/cicadasmile/butte-auto-parent
Wiki·地址
https://gitee.com/cicadasmile/butte-java-note
```