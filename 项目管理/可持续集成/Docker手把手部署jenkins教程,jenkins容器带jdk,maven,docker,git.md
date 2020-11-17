# 1、启动docker，下载Jenkins镜像文件

```
docker pull jenkins/jenkins
```

# 2、创建Jenkins挂载目录并授权权限

```
mkdir -p /var/jenkins_home



chmod 777 /var/jenkins_home
```

# 3、创建并启动Jenkins容器

```
docker run -d -p 10240:8080 -p 10241:50000 -v /usr/bin/docker:/usr/bin/docker -v /var/run/docker.sock:/var/run/docker.sock -v /usr/bin/mv:/usr/bin/mv -v /usr/local/java/jdk1.8.0_271/bin:/usr/local/java/jdk1.8.0_271/bin -v /usr/local/java/jdk1.8.0_271:/usr/local/java/jdk1.8.0_271 -v /usr/local/maven3.6:/usr/local/maven3.6 -v /usr/bin/git:/usr/bin/git -v /etc/localtime:/etc/localtime -v /var/jenkins_home:/var/jenkins_home   --name myjenkins  jenkins/jenkins
```

​    **-d 后台运行镜像**

　　**-p 10240:8080 将镜像的8080端口映射到服务器的10240端口。**

　　**-p 10241:50000 将镜像的50000端口映射到服务器的10241端口**

　　**-v /var/jenkins_home:/var/jenkins_home目录为容器jenkins工作目录，我们将硬盘上的一个目录挂载到这个位置，方便后续更新镜像后继续使用原来的工作目录。这里我们设置的就是上面我们创建的 /var/jenkins_home目录**

　　**-v /etc/localtime:/etc/localtime让容器使用和服务器同样的时间设置。**

   **-v /usr/bin/docker:/usr/bin/docker -v /var/run/docker.sock:/var/run/docker.sock  设置docker**

   **-v /usr/bin/mv:/usr/bin/mv -v /usr/local/java/jdk1.8.0_271/bin:/usr/local/java/jdk1.8.0_271/bin 设置jdk**

   **-v /usr/local/maven3.6:/usr/local/maven3.6 设置maven**

　　**--name myjenkins 给容器起一个别名**

![img](https://img-blog.csdnimg.cn/2020110323072522.png)

# 4、查看jenkins是否启动成功，如下图出现端口号，就为启动成功了

```
docker ps -a
```

![img](https://img-blog.csdnimg.cn/20201103230809196.png)

# 5、查看docker容器日志

```
docker logs myjenkins
```

![img](https://img-blog.csdnimg.cn/20201103230916843.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3UwMTE1MjY3MjE=,size_16,color_FFFFFF,t_70)

# 6、配置镜像加速，进入 cd /var/jenkins_mount/ 目录。

```
cd /var/jenkins_home/
```

![img](https://img-blog.csdnimg.cn/2020110323100045.png)

**修改 vim hudson.model.UpdateCenter.xml里的内容**

将 url 修改为 清华大学官方镜像：https://mirrors.tuna.tsinghua.edu.cn/jenkins/updates/update-center.json

![img](https://img-blog.csdnimg.cn/20201103231124385.png)

# 7、访问Jenkins页面，输入http://ip:10240

![img](https://img-blog.csdnimg.cn/2020110323032645.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3UwMTE1MjY3MjE=,size_16,color_FFFFFF,t_70)

# 8.管理员密码获取方法，编辑initialAdminPassword文件查看，把密码输入登录中的密码即可，开始使用。

```
vim /var/jenkins_home/secrets/initialAdminPassword
```

![img](https://img-blog.csdnimg.cn/20201103231338155.png)

# 9.到此以全部安装成功，尽情的使用吧！