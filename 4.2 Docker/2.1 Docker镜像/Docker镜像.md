- [Docker镜像](https://www.cnblogs.com/Skybiubiu/p/15665314.html)

## 1 Docker镜像

**在之前的介绍中，我们知道镜像是Docker的三大组件之一。**

Docker运行容器前需要本地存在对应的镜像，如果镜像不存在本地，Docker会从镜像仓库下载（默认是Docker Hub公共注册服务器中的仓库）。

本文将介绍关于镜像的内容，包括：

- 从仓库获取镜像
- 管理本地主机上的镜像
- 介绍镜像实现的基本原理

## 2 获取镜像

可以使用`docker pull`命令来从仓库获取所需要的镜像。

举例：从Docker Hub仓库下载一个Ubuntu操作系统的镜像。

```bash
bash[root@localhost /]# docker pull ubuntu:latest

latest: Pulling from library/ubuntu
7b1a6ab2e44d: Pull complete 
Digest: sha256:626ffe58f6e7566e00254b638eb7e0f3b11d4da9675088f4781a50ae288f3322
Status: Downloaded newer image for ubuntu:latest
docker.io/library/ubuntu:latest
```

下载过程中，会输出获取镜像的每一层的信息。

该命令等价于`docker pull registry.hub.docker.com/ubuntu:latest`命令，即从注册服务器`registry.hub.docker.com`中的`ubuntu`仓库来下载latest的镜像。

有时候官方仓库注册服务器下载比较慢，可以从其他仓库中下载。以阿里云镜像加速为例，配置流程：

```bash
bashsudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://<个人的地址号>.mirror.aliyuncs.com"]
}
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker
```

*注意：[容器镜像服务 (aliyun.com)](https://cr.console.aliyun.com/cn-shenzhen/instances/mirrors)，登陆阿里云账号，可查看自己的镜像加速器地址。

![image-20211208200311196](https://gitee.com/er-huomeng/img/raw/master/1953408-20211209011151260-2045754518.png)

配置完之后可以通过`docker info`查看

![image-20211208201623732](https://gitee.com/er-huomeng/img/raw/master/1953408-20211209011151310-2143599327.png)

## 3 列出本地镜像

使用`docker images`显示本地已有的镜像。

```bash
bash[root@localhost /]# docker images
REPOSITORY    TAG       IMAGE ID       CREATED        SIZE
ubuntu        latest    ba6acccedd29   7 weeks ago    72.8MB
ubuntu        test    	ba6acccedd29   7 weeks ago    72.8MB
hello-world   latest    feb5d9fea6a5   2 months ago   13.3kB
```

在列出的信息中，可以看到几个字段

- REPOSITORY：来源于哪个仓库，比如ubuntu
- TAG：镜像的标签，比如latest
- IMAGE ID：镜像ID（唯一）
- CREATED：创建时间
- SIZE：镜像大小

其中镜像的`IMAGE ID`唯一标识了镜像，上面`ubuntu:latest`和`ubuntu:test`具有相同的镜像`IMAGE ID`，说明它们实际上是同一镜像。

`TAG`信息用来标记来自同一个仓库的不同镜像。例如`ubuntu`仓库中有多个镜像，通过`TAG`信息来区分发行版本，例如`10.04`、`12.04`、`14.04`等，而`latest`标识最新的版本。

下面的命令指定使用镜像`ubuntu:latest`来启动一个容器。

```bash
bashsudo docker run -it ubuntu:latest /bin/bash
```

如果不指定具体的标记，则默认使用`latest`标记信息。

其中`-it`的含义：

|     选项     | 简写 |                            说明                            |
| :----------: | :--: | :--------------------------------------------------------: |
|   -detach    |  -d  |              在后台运行容器，并且打印容器ID。              |
| -interactive |  -i  | 即使没有连接，也要保持标准输入保持打开状态，一般与-t连用。 |
|     -tty     |  -t  |               分配一个伪tty，一般与-i连用。                |

## 4 创建镜像

创建镜像有很多方法，用户可以从Docker Hub获取已有镜像并更新，也可以利用本地文件系统创建一个。

### 4.1 方法一：修改已有镜像

通过修改原有的镜像，来定制创建镜像，以上面的ubuntu镜像为例子。

1. 启动镜像，写入一些文件或者更新软件。

```bash
bash[root@localhost /]# docker images
REPOSITORY    TAG       IMAGE ID       CREATED        SIZE
ubuntu        latest    ba6acccedd29   7 weeks ago    72.8MB
hello-world   latest    feb5d9fea6a5   2 months ago   13.3kB
[root@localhost /]# 
[root@localhost /]# docker run -it ubuntu:latest /bin/bash
root@ad84bf1eb7d8:/# 
root@ad84bf1eb7d8:/# cd ~
root@ad84bf1eb7d8:~# echo "Modify test" >> test.txt
复制代码123bash[root@localhost ~]# docker ps
CONTAINER ID   IMAGE          COMMAND       CREATED          STATUS          PORTS     NAMES
ad84bf1eb7d8   ba6acccedd29   "/bin/bash"   27 seconds ago   Up 26 seconds    
```

1. 提交镜像更改（将容器转为镜像）

```bash
bash[root@localhost ~]# docker commit -m="Ubuntu image commit test" -a="Skybiubiu" ad84bf1eb7d8 ubuntu2:test
sha256:5299c83968a8ef1a44308d851593f74620945ccda08a6ea516fd0ad9055dc019
[root@localhost ~]# 
[root@localhost ~]# docker images
REPOSITORY    TAG       IMAGE ID       CREATED         SIZE
ubuntu2       test      5299c83968a8   4 seconds ago   72.8MB
ubuntu        latest    ba6acccedd29   7 weeks ago     72.8MB
hello-world   latest    feb5d9fea6a5   2 months ago    13.3kB
```

格式：`docker commit [OPTIONS] CONTAINER [REPOSITORY[:TAG]]`

`-m`：提交的描述信息

`-a`：指定镜像作者

### 4.2 方法二：通过Dockerfile构建镜像

使用`docker commit`来扩展一个镜像比较简单，但是不方便在一个团队中分享。

我们可以使用`docker build`来创建一个新的镜像。为此，首先需要创建一个Dockerfile，包含一些如何创建镜像的指令。

新建一个目录和一个Dockerfile。

```bash
bashcd ~
mkdir Dockerfile_dir
cd Dockerfile_dir
touch Dockerfile
```

Dockerfile中每一条指令都创建镜像的一层（并非绝对），以构建一个Nginx镜像为例子

```bash
bash[root@localhost Dockerfile_dir]# vim Dockerfile 
FROM nginx
MAINTAINER SkyBiuBiu
RUN echo "It 's a Nginx image,created by skybiubiu." > /usr/share/nginx/html/index.html
```

Dockerfile基本的语法是

- 使用`#`来注释。
- `FROM`关键字告诉Docker使用哪个镜像作为基础。
- 接着`MAINTAINER`是维护者信息。
- `RUN`开头的指令会在创建中运行，比如安装一个软件包。

编写完成的Dockerfile可以通过`docker build`命令来生成镜像。

```bash
bashdocker build -t="skybiubiu/nginx:v1" .
```

格式：

- `-t`：打标签
- `.`：表示当前文件夹下

![image-20211208215110959](https://gitee.com/er-huomeng/img/raw/master/1953408-20211209011151248-512935133.png)

![image-20211208215201394](https://gitee.com/er-huomeng/img/raw/master/1953408-20211209011151315-1114970321.png)

*注意：更多写法，在后面Dockerfile章节补充。

### 4.3 方法三：从本地文件系统导入

通过`docker import`命令从本地文件系统导入镜像。

将一个本地文件夹导入转化成一个镜像。

### 4.4 上传镜像

首先，得通过`docker login`命令登陆Docker Hub。

```bash
bash[root@localhost ~]# docker login
Login with your Docker ID to push and pull images from Docker Hub. If you don't have a Docker ID, head over to https://hub.docker.com to create one.
Username: skybiubiu
Password: 
WARNING! Your password will be stored unencrypted in /root/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store
```

然后通过`docker push`命令上传镜像。

格式`docker push 仓库ID/镜像名:Tag`

```bash
bash[root@localhost ~]# docker push skybiubiu/nginx:v1
The push refers to repository [docker.io/skybiubiu/nginx]
42bab3f962bd: Pushed 
2bed47a66c07: Mounted from library/nginx 
82caad489ad7: Mounted from library/nginx 
d3e1dca44e82: Mounted from library/nginx 
c9fcd9c6ced8: Mounted from library/nginx 
0664b7821b60: Mounted from library/nginx 
9321ff862abb: Mounted from library/nginx 
v1: digest: sha256:57227eb210f8abbeacd1f54f3334300636968371adfbe7a9a3a94f00931444d8 size: 1777
```

## 5 保存和载入镜像

镜像列表如下

```bash
bash[root@localhost ~]# docker images
REPOSITORY        TAG       IMAGE ID       CREATED        SIZE
skybiubiu/nginx   v1        c841f47ef705   3 hours ago    141MB
ubuntu2           test      5299c83968a8   3 hours ago    72.8MB
nginx             latest    f652ca386ed1   6 days ago     141MB
ubuntu            latest    ba6acccedd29   7 weeks ago    72.8MB
hello-world       latest    feb5d9fea6a5   2 months ago   13.3kB
```

将`ubuntu2:test`导出到本地，`-o`表示output。

```bash
bash[root@localhost ~]# docker save -o ubuntu2.tar ubuntu2:test

[root@localhost ~]# ls | grep ubuntu2.tar 
ubuntu2.tar
```

将本地`ubuntu2.tar`导入为镜像，`-i`表示input。

```bash
bash[root@localhost ~]# docker load -i ubuntu2.tar
Loaded image: ubuntu2:test
```

## 6 移除本地镜像

通过`docker rmi`命令可以删除镜像。

通过命令删除skybiubiu/nginx:v1的镜像。

```bash
bash[root@localhost ~]# docker rmi skybiubiu/nginx:v1 
Untagged: skybiubiu/nginx:v1
Untagged: skybiubiu/nginx@sha256:57227eb210f8abbeacd1f54f3334300636968371adfbe7a9a3a94f00931444d8
Deleted: sha256:c841f47ef70593e223dfd75f23df2c21dbe7e75cd1a63eea9dd454bf0f6f0d99
Deleted: sha256:79ff50c01b6592d364734334d08ea63d7bd7a00646d710c8e1a4927666271544
Deleted: sha256:e94202cb0e93a88978d0bacfd032e2158fb68b4803d900868595b351a7801fb3
```

*注意：`docker rm`命令删除的是容器

有一个删除所有镜像的小技巧，如下。

```bash
bashdocker rmi -f $(docker images -q)
```

上面命令中，`docker images -q`输出的是镜像ID，将镜像ID作为变量传入`docker rmi -f`中，删除所有镜像。

## 7 镜像的实现原理

Docker 镜像是怎么实现增量的修改和维护的？ 每个镜像都由很多层次构成，Docker 使用 Union FS 将这 些不同的层结合到一个镜像中去。

通常 Union FS 有两个用途, 一方面可以实现不借助 LVM、RAID 将多个 disk 挂到同一个目录下,另一个更  常用的就是将一个只读的分支和一个可写的分支联合在一起，Live CD 正是基于此方法可以允许在镜像不 变的基础上允许用户在其上进行一些写操作。  Docker 在 AUFS 上构建的容器也是利用了类似的原理。