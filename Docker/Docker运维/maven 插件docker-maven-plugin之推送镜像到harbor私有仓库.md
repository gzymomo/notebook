[TOC]

简书：尹楷楷：[maven 插件docker-maven-plugin之推送镜像到harbor私有仓库（二）](https://www.jianshu.com/p/2481d9843e86)
CSDN：喝醉的咕咕鸟：[docker--私服搭建和推送于Springboot项目打成镜像](https://blog.csdn.net/weixin_43549578/article/details/87864614)

将构建好的镜像通过docker-maven-plugin插件上传到harbor私服
# 一、settings.xml修改

maven的settings.xml中添加服务节点，配置好harbor私服中创建的用户。
```xml
  <servers>
    <server>
    <id>my-hub</id>
    <username>yinkai</username>
    <password>12345678Aa</password>
    <configuration>
      <email>suoyiguke@aliyun.com</email>
    </configuration>
  </server>
  </servers>
```

# 二、修改项目的pom.xml文件
属性配置，在后面的插件配置里有引用这个：

- docker.repostory 是docker私服地址，harbor配置完默认端口就是80，可以不带端口号。但是我将之改成81了
- docker.registry.name 即是在harbor中配置的镜像仓库名，必须一致！这里我配的是test，因为harbor中配置的镜像仓库名也是test。

![](https://upload-images.jianshu.io/upload_images/13965490-e28983fe59e365f8.png?imageMogr2/auto-orient/strip|imageView2/2/w/1200/format/webp)

```xml
<properties>
	<!--docker插件-->
	<!-- docker私服地址,Harbor配置完默认地址就是80,默认不带端口号。但是我这里是81 -->
	<docker.repostory>192.168.10.11:81</docker.repostory>
	<!--项目名,需要和Harbor中的项目名称保持一致 -->
	<docker.registry.name>test</docker.registry.name>
</properties>
```

## 2.1 docker-maven-plugin插件配置
- serverId 指定之前在maven的settings.xml中配置的server节点，这样maven会去找其中配置的用户名密码和邮箱
- registryUrl 指定上面配置的properties属性，即是harbor私服的访问url，注意我设置的使用81端口，默认是80端口
- imageName 指定上传harbor私服的镜像名，必须和harbor上的url、镜像仓库名保持一致。其中的docker.registry.name就是上面配置的properties属性

```xml
<plugin>
  <groupId>com.spotify</groupId>
  <artifactId>docker-maven-plugin</artifactId>
  <version>1.0.0</version>
  <configuration>
	  <serverId>my-hub</serverId>
	  <registryUrl>http://${docker.repostory}</registryUrl>
	  <!--必须配置dockerHost标签（除非配置系统环境变量DOCKER_HOST）-->
	  <dockerHost>http://192.168.10.11:2375</dockerHost>
	  <!--Building image 192.168.10.11/demo1-->
	  <imageName>${docker.repostory}/${docker.registry.name}/${project.artifactId}:${project.version}</imageName>
	  <!-- 指定 Dockerfile 路径-->
	  <dockerDirectory>${basedir}/</dockerDirectory>
	  <!-- jar包位置-->
	  <resources>
		  <resource>
		  <targetPath>/ROOT</targetPath>
		  <!-- target目录下-->
		  <directory>${project.build.directory}</directory>
		  <!--通过jar包名找到jar包-->
		  <include>${pack-name}</include>
		  </resource>
	  </resources>
  </configuration>
</plugin>
```
配置好了之后

修改项目版本号，这个版本号被多个maven插件配置所引用。将之改为2

![](https://upload-images.jianshu.io/upload_images/13965490-ca0c6a04928330ec.png?imageMogr2/auto-orient/strip|imageView2/2/w/502/format/webp)

那么Dockerfile文件中的jar包名相应需要修改：

```xml
FROM java:8
WORKDIR /ROOT
ADD /ROOT/demo1-2.jar /ROOT/
ENTRYPOINT ["java", "-jar", "demo1-2.jar"]
```

点击pakage打包，target 上生成了springboot工程的jar包

完了之后，点击docker bulid 构建工程镜像
![](https://upload-images.jianshu.io/upload_images/13965490-bf11c9dcb4a265fb.png?imageMogr2/auto-orient/strip|imageView2/2/w/370/format/webp)

然后点击push，将镜像推送到harbor私服中
![](https://upload-images.jianshu.io/upload_images/13965490-5bbc95af04353c2d.png?imageMogr2/auto-orient/strip|imageView2/2/w/233/format/webp)