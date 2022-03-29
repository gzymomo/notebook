- [部署SpringBoot的jar包项目让人头疼，不如使用jenkins+docker自动化部署jar包项目_Duktig丶的博客-CSDN博客_docker自动化部署springboot](https://blog.csdn.net/qq_42937522/article/details/106325306)
- [前端项目部署很头疼？不如使用jenkins+docker自动化部署前端项目_Duktig丶的博客-CSDN博客_docker部署前端项目](https://blog.csdn.net/qq_42937522/article/details/106326422)
- [SpringBoot项目(单模块、多模块)使用docker容器运行jar包镜像（踩坑）_北眼BeiYan的博客-CSDN博客_docker部署springboot多模块](https://blog.csdn.net/qq_37918553/article/details/83796582)
- [Docker 部署 Spring Boot 项目指南 技术指南 (chinacion.cn)](http://www.chinacion.cn/article/4089.html)
- [SpringBoot-Maven多模块项目Docker化 - 简书 (jianshu.com)](https://www.jianshu.com/p/e9ceb50a3204)

docker.sh脚本

```bash
 # 源jar路径  即jenkins构建后存放的路径
  SOURCE_PATH=/data/jenkins/workspace
#docker 镜像/容器名字或者jar名字 这里都命名为这个
  SERVER_NAME=blog-parent
 #容器id
 CID=$(docker ps | grep "$SERVER_NAME" | awk '{print $1}')
 #镜像id
 IID=$(docker images | grep "$SERVER_NAME" | awk '{print $3}')

 echo "最新构建代码 $SOURCE_PATH/$SERVER_NAME/target/ms_backend.jar 迁移至 $BASE_PATH ...."
 #把项目从jenkins构建后的目录移动到我们的项目目录下同时重命名下
  mv $SOURCE_PATH/blog-system-1.0.0-SNAPSHOT.jar $BASE_PATH/blog-system.jar
 #修改文件的权限
  chmod 777 /usr/local/dockerApp/blog-parent/blog-system.jar
  echo "迁移完成"

 # 构建docker镜像
         if [ -n "$IID" ]; then
                 echo "存在$SERVER_NAME镜像，IID=$IID"
                  docker stop $SERVER_NAME   # 停止运行中的容器
                  docker rm $SERVER_NAME     ##删除原来的容器
                  docker rmi $IID   ## 删除原来的镜像

         else
                 echo "不存在$SERVER_NAME镜像，开始构建镜像"
                      
        fi 

  # 构建镜像 
  cd $BASE_PATH
  docker build -t $SERVER_NAME .
    
# 运行容器
 # --name docker-test                 容器的名字为docker-test
 #   -d                                 容器后台运行
 #   -p 8090:8090 指定容器映射的端口和主机对应的端口都为8090
 #   -v /usr/local/dockerApp/blog-parent:/usr/local/dockerApp/blog-parent   将主机的/usr/local/dockerApp/blog-parent目录挂载到容器的/usr/local/dockerApp/blog-parent 目录中
 docker run --name $SERVER_NAME -v $BASE_PATH:$BASE_PATH -d -p 8090:8090 $SERVER_NAME
 echo "$SERVER_NAME容器创建完成"
```

## 1 SpringBoot项目(单模块、多模块)使用docker容器运行jar包镜像

### 1.1 mavem docker插件配置

```xml
<!--docker 插件配置-->
   <build>
      <finalName>生成jar包的名称</finalName>
      <plugins>
         <plugin>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-maven-plugin</artifactId>
         </plugin>
         <plugin>
            <groupId>com.spotify</groupId>
            <artifactId>docker-maven-plugin</artifactId>
            <version>0.2.3</version> <configuration>
            <imageName>${project.artifactId}</imageName>
            <!--docker的配置文件所在目录-->
            <dockerDirectory>src/main/docker</dockerDirectory>
            <resources>
               <resource>
                  <targetPath>/</targetPath>
                  <directory>${project.build.directory}</directory>
                  <include>${project.build.finalName}.jar</include>
               </resource>
            </resources>
         </configuration>
         </plugin>
      </plugins>
   </build>
```

### 1.2 DockerFile配置文件

```bash
VOLUME /tmp
ADD XXXX.jar app.jar
RUN bash -c 'touch /app.jar'
ENTRYPOINT ["java","-D java.security.egd=file:/dev/./urandom","-jar","/app.jar"]
```

### 1.3 配置完成后使用maven命令生成docker镜像（单模块项目情况）

```bash
#! /bin/bash 
#首先移除原来的镜像
docker stop eureka-server 
docker rm eureka-server 
docker rmi eureka-server
#找到项目所在目录
cd /home/ubuntu/java/jenkins/springcloud/eureka-server/ 
#执行maven命令生成jar包和镜像
mvn clean package -Ptest -Dmaven.test.skip=true docker:build
#查看镜像是否存在
docker images
#运行镜像
docker run -p 8761:8761 --name eureka-server -d eureka-server
```

### 1.4 配置完成后使用maven命令生成docker镜像（多模块项目情况）

以springboot Web项目为例

只在web 模块添加Maven docker插件配置以及Dockerfile

```bash
#! /bin/bash 
#首先移除原来的镜像
docker stop boot 
docker rm boot 
docker rmi boot
#找到项目所在目录
cd /home/ubuntu/java/jenkins/springboot/
#根目录下进行 install
mvn clean install package -Dmaven.test.skip
#进入web模块下
cd bootweb/
#执行maven命令生成jar包和镜像
mvn package docker:build -Dmaven.test.skip
#查看镜像是否存在
docker images
#运行镜像
docker run -p 8080:8080 --name boot -d boot
```

