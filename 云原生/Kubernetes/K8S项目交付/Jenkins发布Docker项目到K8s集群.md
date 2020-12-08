## Jenkins发布Docker项目到K8s集群

### 1.调整SpringBoot项目的配置

实现，SpringBoot项目中启动类所在的模块的pom.xml需要引入打包成Docker镜像的配置，如下所示。

```xml
  <properties>
  	 	<docker.repostory>192.168.0.10:1180</docker.repostory>
        <docker.registry.name>test</docker.registry.name>
        <docker.image.tag>1.0.0</docker.image.tag>
        <docker.maven.plugin.version>1.4.10</docker.maven.plugin.version>
  </properties>

<build>
  		<finalName>test-starter</finalName>
		<plugins>
            <plugin>
			    <groupId>org.springframework.boot</groupId>
			    <artifactId>spring-boot-maven-plugin</artifactId>
			</plugin>
			
			<!-- docker的maven插件，官网：https://github.com/spotify/docker‐maven‐plugin -->
			<!-- Dockerfile maven plugin -->
			<plugin>
			    <groupId>com.spotify</groupId>
			    <artifactId>dockerfile-maven-plugin</artifactId>
			    <version>${docker.maven.plugin.version}</version>
			    <executions>
			        <execution>
			        <id>default</id>
			        <goals>
			            <!--如果package时不想用docker打包,就注释掉这个goal-->
			            <goal>build</goal>
			            <goal>push</goal>
			        </goals>
			        </execution>
			    </executions>
			    <configuration>
			    	<contextDirectory>${project.basedir}</contextDirectory>
			        <!-- harbor 仓库用户名及密码-->
			        <useMavenSettingsForAuth>useMavenSettingsForAuth>true</useMavenSettingsForAuth>
			        <repository>${docker.repostory}/${docker.registry.name}/${project.artifactId}</repository>
			        <tag>${docker.image.tag}</tag>
			        <buildArgs>
			            <JAR_FILE>target/${project.build.finalName}.jar</JAR_FILE>
			        </buildArgs>
			    </configuration>
			</plugin>

        </plugins>
        
		<resources>
			<!-- 指定 src/main/resources下所有文件及文件夹为资源文件 -->
			<resource>
				<directory>src/main/resources</directory>
				<targetPath>${project.build.directory}/classes</targetPath>
				<includes>
					<include>**/*</include>
				</includes>
				<filtering>true</filtering>
			</resource>
		</resources>
	</build>
```

接下来，在SpringBoot启动类所在模块的根目录创建Dockerfile，内容示例如下所示。

```bash
#添加依赖环境，前提是将Java8的Docker镜像从官方镜像仓库pull下来，然后上传到自己的Harbor私有仓库中
FROM 192.168.0.10:1180/library/java:8
#指定镜像制作作者
MAINTAINER binghe
#运行目录
VOLUME /tmp
#将本地的文件拷贝到容器
ADD target/*jar app.jar
#启动容器后自动执行的命令
ENTRYPOINT [ "java", "-Djava.security.egd=file:/dev/./urandom", "-jar", "/app.jar" ]
```

根据实际情况，自行修改。

**注意：FROM 192.168.0.10:1180/library/java:8的前提是执行如下命令。**

```bash
docker pull java:8
docker tag java:8 192.168.0.10:1180/library/java:8
docker login 192.168.0.10:1180
docker push 192.168.0.10:1180/library/java:8
```

在SpringBoot启动类所在模块的根目录创建yaml文件，录入叫做test.yaml文件，内容如下所示。

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-starter
  labels:
    app: test-starter
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test-starter
  template:
    metadata:
      labels:
        app: test-starter
    spec:
      containers:
      - name: test-starter
        image: 192.168.0.10:1180/test/test-starter:1.0.0
        ports:
        - containerPort: 8088
      nodeSelector:
        clustertype: node12

---
apiVersion: v1
kind: Service
metadata:
  name: test-starter
  labels:
    app: test-starter
spec:
  ports:
    - name: http
      port: 8088
      nodePort: 30001
  type: NodePort
  selector:
    app: test-starter
```

### 2.Jenkins配置发布项目

将项目上传到SVN代码库，例如地址为svn://192.168.0.10/test

接下来，在Jenkins中配置自动发布。步骤如下所示。

点击新建Item。

在描述文本框中输入描述信息，如下所示。

接下来，配置SVN信息。

**注意：配置GitLab的步骤与SVN相同，不再赘述。**

定位到Jenkins的“构建模块”，使用Execute Shell来构建发布项目到K8S集群。

执行的命令依次如下所示。

```bash
#删除本地原有的镜像,不会影响Harbor仓库中的镜像
docker rmi 192.168.0.10:1180/test/test-starter:1.0.0
#使用Maven编译、构建Docker镜像，执行完成后本地Docker容器中会重新构建镜像文件
/usr/local/maven-3.6.3/bin/mvn -f ./pom.xml clean install -Dmaven.test.skip=true
#登录 Harbor仓库
docker login 192.168.0.10:1180 -u binghe -p Binghe123
#上传镜像到Harbor仓库
docker push 192.168.0.10:1180/test/test-starter:1.0.0
#停止并删除K8S集群中运行的
/usr/bin/kubectl delete -f test.yaml
#将Docker镜像重新发布到K8S集群
/usr/bin/kubectl apply -f test.yaml
```