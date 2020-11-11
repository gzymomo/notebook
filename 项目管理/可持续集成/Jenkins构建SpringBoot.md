[三十二张图告诉你，Jenkins构建Spring Boot 有多简单~](https://www.cnblogs.com/Chenjiabing/p/13953130.html)



## **前言**

自动持续集成不知道大家伙有没有听说过，有用过类似的工具吗？

简而言之，自动持续集成的工作主要是能对项目进行构建、自动化测试和发布。

今天这篇文章就来讲讲常用的持续集成的工具`Jenkins`以及如何自动构建`Spring Boot`项目。

## **如何安装Jenkins？**

`Jenkins`是Java开发的一套工具，可以直接下载`war`包部署在`Tomcat`上，但是今天作者用最方便、最流行的`Docker`安装。

### 环境准备

在开始安装之前需要准备以下环境和工具：

1. 一台服务器，当然没有的话可以用自己的电脑，作者的服务器型号是`Ubuntu`。
2. `JDK`环境安装，作者的版本是`1.8`，至于如何安装，网上很多教程。
3. 准备`maven`环境，官网下载一个安装包，放在指定的目录下即可。
4. `Git`环境安装，网上教程很多。
5. 代码托管平台，比如`Github`、`GitLab`等。

### 开始安装Jenkins

`Docker`安装`Jenkins`非常方便，只要跟着作者的步骤一步步操作，一定能够安装成功。

#### Docker环境安装

每个型号服务器安装的方式各不相同，读者可以根据自己的型号安装，网上教程很多。

#### 拉取镜像

我这里安装的版本是`jenkins/jenkins:2.222.3-centos`，可以去这里获取你需要的版本: `https://hub.docker.com/_/jenkins?tab=tags`。执行如下命令安装：

```
docker pull jenkins/jenkins:2.222.3-centos
```

#### 创建本地数据卷

在本地创建一个数据卷挂载docker容器中的数据卷，我创建的是`/data/jenkins_home/`，命令如下：

```
 mkdir -p /data/jenkins_home/
```

需要修改下目录权限，因为当映射本地数据卷时，`/data/jenkins_home/`目录的拥有者为`root`用户，而容器中`jenkins`用户的 `uid` 为 `1000`。

```
chown -R 1000:1000 /data/jenkins_home/
```

#### 创建容器

除了需要挂载上面创建的`/data/jenkins_home/`以外，还需要挂载`maven`、`jdk`的根目录。启动命令如下：

```
docker run -d --name jenkins -p 8040:8080 -p 50000:50000 -v /data/jenkins_home:/var/jenkins_home -v /usr/local/jdk:/usr/local/jdk -v /usr/local/maven:/usr/local/maven jenkins/jenkins:2.222.3-centos
```

以上命令解析如下：

1. `-d`：后台运行容器
2. `--name`：指定容器启动的名称
3. `-p`：指定映射的端口，这里是将服务器的`8040`端口映射到容器的`8080`以及`50000`映射到容器的`50000`。 **「注意：」** `8040`和`50000`一定要是开放的且未被占用，如果用的是云服务器，还需要在管理平台开放对应的规则。
4. `-v`：挂载本地的数据卷到`docker`容器中，**「注意：」** 需要将`JDK`和`maven`的所在的目录挂载。

## **初始化配置**

容器启动成功，则需要配置`Jenkins`，安装一些插件、配置远程推送等等。

### 访问首页

容器创建成功，访问`http://ip:8040`，如果出现以下页面表示安装成功：

![img](https://gitee.com/chenjiabing666/BlogImage/raw/master/Spring%20Boot%20%E9%9B%86%E6%88%90%20Jenkins/1.png)

### 输入管理员密码

启动成功，则会要求输入密码，如下图：

![img](https://gitee.com/chenjiabing666/BlogImage/raw/master/Spring%20Boot%20%E9%9B%86%E6%88%90%20Jenkins/2.png)

这里要求输入的是管理的密码，提示是在`/var/jenkins_home/secrets/initialAdminPassword`，但是我们已经将`/var/jenkins_home`这个文件夹挂载到本地目录了，因此只需要去挂载的目录`/data/jenkins_home/secrets/initialAdminPassword`文件中找。

输入密码，点击继续。

### 安装插件

初始化安装只需要安装社区推荐的一些插件即可，如下图：

![img](https://gitee.com/chenjiabing666/BlogImage/raw/master/Spring%20Boot%20%E9%9B%86%E6%88%90%20Jenkins/3.png)

这里选择`安装推荐的插件`，然后 `Jenkins` 会自动开始安装。

**「注意：」** 如果出现想插件安装很慢的问题，找到`/data/jenkins_home/updates/default.json`文件，替换的内容如下：

1. 将 `updates.jenkins-ci.org/download` 替换为`mirrors.tuna.tsinghua.edu.cn/jenkins`
2. 将 `www.google.com` 替换为`www.baidu.com`。

执行以下两条命令：

```
sed -i 's/www.google.com/www.baidu.com/g' default.json

sed -i 's/updates.jenkins-ci.org\/download/mirrors.tuna.tsinghua.edu.cn\/jenkins/g' default.json
```

![img](https://gitee.com/chenjiabing666/BlogImage/raw/master/Spring%20Boot%20%E9%9B%86%E6%88%90%20Jenkins/4.png)

全部安装完成，继续下一步。

### 创建管理员

随便创建一个管理员，按要求填写信息，如下图：

![img](https://gitee.com/chenjiabing666/BlogImage/raw/master/Spring%20Boot%20%E9%9B%86%E6%88%90%20Jenkins/5.png)

### 实例配置

配置自己的服务器`IP`和`端口`，如下图：

![img](https://gitee.com/chenjiabing666/BlogImage/raw/master/Spring%20Boot%20%E9%9B%86%E6%88%90%20Jenkins/6.png)

### 配置完成

按照以上步骤，配置完成后自动跳转到如下界面：

![img](https://gitee.com/chenjiabing666/BlogImage/raw/master/Spring%20Boot%20%E9%9B%86%E6%88%90%20Jenkins/7.png)

## **构建Spring Boot 项目**

在构建之前还需要配置一些开发环境，比如`JDK`，`Maven`等环境。

### 配置JDK、maven、Git环境

`Jenkins`集成需要用到`maven`、`JDK`、`Git`环境，下面介绍如何配置。

首先打开`系统管理`->`全局工具配置`，如下图：

![img](https://gitee.com/chenjiabing666/BlogImage/raw/master/Spring%20Boot%20%E9%9B%86%E6%88%90%20Jenkins/8.png)

分别配置`JDK`，`Git`，`Maven`的路径，根据你的实际路径来填写。

**「注意」**：这里的`JDK`、`Git`、`Maven`环境一定要挂载到`docker`容器中，否则会出现以下提示：

```
 xxxx is not a directory on the Jenkins master (but perhaps it exists on some agents)
```

![img](https://gitee.com/chenjiabing666/BlogImage/raw/master/Spring%20Boot%20%E9%9B%86%E6%88%90%20Jenkins/9.png)

![img](https://gitee.com/chenjiabing666/BlogImage/raw/master/Spring%20Boot%20%E9%9B%86%E6%88%90%20Jenkins/10.png)

![img](https://gitee.com/chenjiabing666/BlogImage/raw/master/Spring%20Boot%20%E9%9B%86%E6%88%90%20Jenkins/11.png)

配置成功后，点击保存。

### 安装插件

除了初始化配置中安装的插件外，还需要安装如下几个插件：

1. `Maven Integration`
2. `Publish Over SSH`

打开`系统管理` -> `插件管理`，选择`可选插件`，勾选中 `Maven Integration` 和 `Publish Over SSH`，点击`直接安装`。

![img](https://gitee.com/chenjiabing666/BlogImage/raw/master/Spring%20Boot%20%E9%9B%86%E6%88%90%20Jenkins/12.png)

在安装界面勾选上安装完成后重启 `Jenkins`。

![img](https://gitee.com/chenjiabing666/BlogImage/raw/master/Spring%20Boot%20%E9%9B%86%E6%88%90%20Jenkins/24.png)

### 添加 SSH Server

`SSH Server` 是用来连接部署服务器的，用于在项目构建完成后将你的应用推送到服务器中并执行相应的脚本。

打开 `系统管理` -> `系统配置`，找到 `Publish Over SSH` 部分，选择`新增`

![img](https://gitee.com/chenjiabing666/BlogImage/raw/master/Spring%20Boot%20%E9%9B%86%E6%88%90%20Jenkins/13.png)

点击 `高级` 展开配置

![img](https://gitee.com/chenjiabing666/BlogImage/raw/master/Spring%20Boot%20%E9%9B%86%E6%88%90%20Jenkins/14.png)

最终配置如下：

![img](https://gitee.com/chenjiabing666/BlogImage/raw/master/Spring%20Boot%20%E9%9B%86%E6%88%90%20Jenkins/15.png)

配置完成后可点击 `Test Configuration` 测试连接，出现 `success` 则连接成功。

### 添加凭据

凭据 是用来从 `Git` 仓库拉取代码的，打开 `凭据` -> `系统` -> `全局凭据` -> `添加凭据`

![img](https://gitee.com/chenjiabing666/BlogImage/raw/master/Spring%20Boot%20%E9%9B%86%E6%88%90%20Jenkins/16.png)

这里配置的是`Github`，直接使用`用户名`和`密码`，如下图：

![img](https://gitee.com/chenjiabing666/BlogImage/raw/master/Spring%20Boot%20%E9%9B%86%E6%88%90%20Jenkins/17.png)

创建成功，点击保存。

### 新建Maven项目

以上配置完成后即可开始构建了，首先需要新建一个`Maven`项目，步骤如下。

#### 创建任务

首页点击`新建任务`->`构建一个maven项目`，如下图：![img](https://gitee.com/chenjiabing666/BlogImage/raw/master/Spring%20Boot%20%E9%9B%86%E6%88%90%20Jenkins/18.png)

#### 源码管理

在源码管理中，选择`Git`，填写`仓库地址`，选择之前添加的`凭证`。

![img](https://gitee.com/chenjiabing666/BlogImage/raw/master/Spring%20Boot%20%E9%9B%86%E6%88%90%20Jenkins/19.png)

#### 构建环境

勾选 `Add timestamps to the Console Output`，代码构建的过程中会将日志打印出来。

![img](https://gitee.com/chenjiabing666/BlogImage/raw/master/Spring%20Boot%20%E9%9B%86%E6%88%90%20Jenkins/20.png)

#### 构建命令

在`Build`中，填写 `Root POM` 和 `Goals and options`，也就是你构建项目的命令。

![img](https://gitee.com/chenjiabing666/BlogImage/raw/master/Spring%20Boot%20%E9%9B%86%E6%88%90%20Jenkins/21.png)

#### Post Steps

选择`Run only if build succeeds`，添加 `Post` 步骤，选择 `Send files or execute commands over SSH`。

![img](https://gitee.com/chenjiabing666/BlogImage/raw/master/Spring%20Boot%20%E9%9B%86%E6%88%90%20Jenkins/22.png)

上图各个选项解析如下：

1. `name`:选择前面添加的`SSH Server`
2. `Source files`:要推送的文件
3. `Remove prefix`:文件路径中要去掉的前缀，
4. `Remote directory`:要推送到目标服务器上的哪个目录下
5. `Exec command`:目标服务器上要执行的脚本

`Exec command`指定了需要执行的脚本，如下：

```
# jdk环境，如果全局配置了，可以省略
export JAVA_HOME=/xx/xx/jdk
export JRE_HOME=/xx/xx/jdk/jre
export CLASSPATH=/xx/xx/jdk/lib
export PATH=$JAVA_HOME/bin:$JRE_HOME/bin:$PATH
 
# jenkins编译之后的jar包位置，在挂载docker的目录下
JAR_PATH=/data/jenkins_home/workspace/test/target
# 自定义的jar包位置
DIR=/data/test

## jar包的名称
JARFILE=swagger-demo-0.0.1-SNAPSHOT.jar

if [ ! -d $DIR/backup ];then
   mkdir -p $DIR/backup
fi

ps -ef | grep $JARFILE | grep -v grep | awk '{print $2}' | xargs kill -9

if [ -f $DIR/backup/$JARFILE ]; then
 rm -f $DIR/backup/$JARFILE
fi

mv $JAR_PATH/$JARFILE $DIR/backup/$JARFILE


java -jar $DIR/backup/$JARFILE > out.log &
if [ $? = 0 ];then
        sleep 30
        tail -n 50 out.log
fi

cd $DIR/backup/
ls -lt|awk 'NR>5{print $NF}'|xargs rm -rf
```

以上脚本大致的意思就是将`kill`原有的进程，启动新构建`jar`包。

> 脚本可以自己定制，比如备份`Jar`等操作。

## **构建任务**

项目新建完成之后，一切都已准备就绪，点击`立即构建`可以开始构建任务，控制台可以看到`log`输出，如果构建失败，在`log`中会输出原因。

![img](https://gitee.com/chenjiabing666/BlogImage/raw/master/Spring%20Boot%20%E9%9B%86%E6%88%90%20Jenkins/23.png)

任务构建过程会执行脚本启动项目。

## **如何构建托管在GitLab的项目？**

上文介绍的例子是构建`Github`仓库的项目，但是企业中一般都是私服的`GitLab`，那么又该如何配置呢？

其实原理是一样的，只是在构建任务的时候选择的是`GitLab`的凭据，下面将详细介绍。

### 安装插件

在`系统管理`->`插件管理`->`可选插件`中搜索`GitLab Plugin`并安装。

### 添加GitLab API token

首先打开 `凭据` -> `系统` -> `全局凭据` -> `添加凭据`，如下图：

![img](https://gitee.com/chenjiabing666/BlogImage/raw/master/Spring%20Boot%20%E9%9B%86%E6%88%90%20Jenkins/25.png)

上图中的`API token`如何获取呢？

打开`GitLab`（例如公司内网的`GitLab`网站），点击个人设置菜单下的`setting`，再点击`Account`，复制`Private token`，如下：

![img](https://gitee.com/chenjiabing666/BlogImage/raw/master/Spring%20Boot%20%E9%9B%86%E6%88%90%20Jenkins/26.png)

上图的`Private token`则是`API token`，填上即可。

### 配置GitLab插件

打开`系统管理`->`系统配置`->`GitLab`，如下图：

![img](https://gitee.com/chenjiabing666/BlogImage/raw/master/Spring%20Boot%20%E9%9B%86%E6%88%90%20Jenkins/27.png)

配置成功后，点击`Test Connection`，如果提示`Success`则配置成功。

### 新建任务

新建一个Maven任务，配置的步骤和上文相同，唯一区别则是配置`Git`仓库地址的地方，如下图：

![img](https://gitee.com/chenjiabing666/BlogImage/raw/master/Spring%20Boot%20%E9%9B%86%E6%88%90%20Jenkins/28.png)

仓库地址和凭据需要填写`Gitlab`相对应的。