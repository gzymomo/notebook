**1.DockerFile是什么？**

DockerFile是用来构建Docker镜像的构建文件，一般分为四部分：基础镜像信息、维护者信息、镜像操作指令和容器启动时执行指令，’#’ 为 Dockerfile 中的注释。

我们可以通过dockerfile来构建docker镜像。

如tomcat的dockerfile如下：

```bash
FROM adoptopenjdk:8-jdk-hotspot
ENV CATALINA_HOME /usr/local/tomcat
ENV PATH $CATALINA_HOME/bin:$PATH
RUN mkdir -p "$CATALINA_HOME"
WORKDIR $CATALINA_HOME
ENV TOMCAT_NATIVE_LIBDIR $CATALINA_HOME/native-jni-lib
ENV LD_LIBRARY_PATH ${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}$TOMCAT_NATIVE_LIBDIR
ENV GPG_KEYS 05AB33110949707C93A279E3D3EFE6B686867BA6 
EXPOSE 8080
CMD ["catalina.sh", "run"]
```

**2.DockerFile解析**

1）基础结构由大写的保留字指令+参数构成。

2）指令从上到下顺序执行。

3）#表示注解。

4）每条指令都会创建新的镜像层，并对镜像进行提交。

**3.DockerFile保留字指令解析**

1）FROM

```
基础镜像，当前新建的镜像是基于哪个镜像的。
```

2）MAINTAINER

```
镜像维护者的姓名邮箱主页啥的
```

3）RUN

```
容器构建的时候需要的命令　　
```

4）EXPOSE

```
当前容器对外暴露的端口
```

5）WORKDIR

```
指定在创建容器后，终端默认登录的进来工作目录，一个落脚点
```

6）ENV

```
镜像构建过程中需要设置的环境变量
```

7）ADD

```
将宿主机目录下的文件拷贝进镜像且ADD命令会自动处理URL和解压tar压缩包
```

8）COPY

```
将宿主机目录下的文件拷贝进镜像，或者拷贝出来
```

9）VOLUME

```
容器数据卷，用于数据保存和持久化工作。可以将宿主机目录和容器绑定，这样两个文件夹下的文件都能共通，如tomcat镜像的项目部署文件夹，映射到宿主机后，部署项目不需要进入镜像，直接部署到宿主机对应目录就可以了。
```

10）CMD

```
制动一个容器启动时要运行的命令，dockerfile中可以有多个cmd命令，但是只有最后一个会生效，之前的都会被覆盖不会被执行。
```

11）ENTRYPOINT

```
指定一个容器启动时要运行的命令，和cmd一样，但是可以指定多个命令，在容器启动时，会顺序执行。
```

12）ONBUILD

```
当构建一个被继承的dockerfile时运行命令，父镜像在被子继承后赴京向的onbuild被处罚
```

**4.示例**

1）基于centos构建一个能使用vim命令和ifconfig命令的，工作目录是/usr/locald的自定义的centos。

a.自定义的dockerfile

```bash
FROM centos
MAINTAINER panda_zhu@qq.com
ENV MYPATH /usr/local
WORKDIR $MYPATH
RUN yum -y install vim
RUN yum -y install net-tools
EXPOSE 80
CMD echo $MYPATH
CMD echo "sucess-----------ok"
CMD /bin/bash
```

b.执行以下命令，将dockerfile构建成docker镜像

```bash
docker build -f ./mydockerfile -t mycentos:1.1 .
./mydockerfile是新写的dockerfile<br><br>mycentos:1.1 是新镜像的名称和版本标签
最后还有一个<strong>点</strong>别忘了<em><br><br>弹出的日志如下：<br></em>
```



```bash
Sending build context to Docker daemon  2.048kB
Step 1/10 : FROM centos
 ---> 0d120b6ccaa8
Step 2/10 : MAINTAINER panda_zhu@qq.com
 ---> Running in e72b7682d2a1
Removing intermediate container e72b7682d2a1
 ---> 0c169e4db377
Step 3/10 : ENV MYPATH /usr/local
 ---> Running in 4bcac118de46
Removing intermediate container 4bcac118de46
 ---> 361b12647c93
Step 4/10 : WORKDIR $MYPATH
 ---> Running in 1f7a11a85882
Removing intermediate container 1f7a11a85882
 ---> c8ca5793760e
Step 5/10 : RUN yum -y install vim
 ---> Running in c10b463ce61a
CentOS-8 - AppStream                            4.9 MB/s | 5.8 MB     00:01   
CentOS-8 - Base                                 942 kB/s | 2.2 MB     00:02   
CentOS-8 - Extras                                11 kB/s | 8.6 kB     00:00   
Dependencies resolved.
================================================================================
 Package             Arch        Version                   Repository      Size
================================================================================
Installing:
 vim-enhanced        x86_64      2:8.0.1763-13.el8         AppStream      1.4 M
Installing dependencies:
 gpm-libs            x86_64      1.20.7-15.el8             AppStream       39 k
 vim-common          x86_64      2:8.0.1763-13.el8         AppStream      6.3 M
 vim-filesystem      noarch      2:8.0.1763-13.el8         AppStream       48 k
 which               x86_64      2.21-12.el8               BaseOS          49 k
 
Transaction Summary
================================================================================
Install  5 Packages
 
Total download size: 7.8 M
Installed size: 31 M
Downloading Packages:
(1/5): gpm-libs-1.20.7-15.el8.x86_64.rpm        450 kB/s |  39 kB     00:00   
(2/5): vim-filesystem-8.0.1763-13.el8.noarch.rp 2.4 MB/s |  48 kB     00:00   
(3/5): vim-enhanced-8.0.1763-13.el8.x86_64.rpm  8.4 MB/s | 1.4 MB     00:00   
(4/5): which-2.21-12.el8.x86_64.rpm             496 kB/s |  49 kB     00:00   
(5/5): vim-common-8.0.1763-13.el8.x86_64.rpm    9.6 MB/s | 6.3 MB     00:00   
--------------------------------------------------------------------------------
Total                                           3.5 MB/s | 7.8 MB     00:02    
warning: /var/cache/dnf/AppStream-02e86d1c976ab532/packages/gpm-libs-1.20.7-15.el8.x86_64.rpm: Header V3 RSA/SHA256 Signature, key ID 8483c65d: NOKEY
CentOS-8 - AppStream                            1.6 MB/s | 1.6 kB     00:00   
Importing GPG key 0x8483C65D:
 Userid     : "CentOS (CentOS Official Signing Key) <security@centos.org>"
 Fingerprint: 99DB 70FA E1D7 CE22 7FB6 4882 05B5 55B3 8483 C65D
 From       : /etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
Key imported successfully
Running transaction check
Transaction check succeeded.
Running transaction test
Transaction test succeeded.
Running transaction
  Preparing        :                                                        1/1
  Installing       : which-2.21-12.el8.x86_64                               1/5
  Installing       : vim-filesystem-2:8.0.1763-13.el8.noarch                2/5
  Installing       : vim-common-2:8.0.1763-13.el8.x86_64                    3/5
  Installing       : gpm-libs-1.20.7-15.el8.x86_64                          4/5
  Running scriptlet: gpm-libs-1.20.7-15.el8.x86_64                          4/5
  Installing       : vim-enhanced-2:8.0.1763-13.el8.x86_64                  5/5
  Running scriptlet: vim-enhanced-2:8.0.1763-13.el8.x86_64                  5/5
  Running scriptlet: vim-common-2:8.0.1763-13.el8.x86_64                    5/5
  Verifying        : gpm-libs-1.20.7-15.el8.x86_64                          1/5
  Verifying        : vim-common-2:8.0.1763-13.el8.x86_64                    2/5
  Verifying        : vim-enhanced-2:8.0.1763-13.el8.x86_64                  3/5
  Verifying        : vim-filesystem-2:8.0.1763-13.el8.noarch                4/5
  Verifying        : which-2.21-12.el8.x86_64                               5/5
 
Installed:
  gpm-libs-1.20.7-15.el8.x86_64         vim-common-2:8.0.1763-13.el8.x86_64   
  vim-enhanced-2:8.0.1763-13.el8.x86_64 vim-filesystem-2:8.0.1763-13.el8.noarch
  which-2.21-12.el8.x86_64            
 
Complete!
Removing intermediate container c10b463ce61a
 ---> e13ba4c98f4e
Step 6/10 : RUN yum -y install net-tools
 ---> Running in c44679e1b6f8
Last metadata expiration check: 0:00:10 ago on Sun Dec  6 09:09:43 2020.
Dependencies resolved.
================================================================================
 Package         Architecture Version                        Repository    Size
================================================================================
Installing:
 net-tools       x86_64       2.0-0.51.20160912git.el8       BaseOS       323 k
 
Transaction Summary
================================================================================
Install  1 Package
 
Total download size: 323 k
Installed size: 1.0 M
Downloading Packages:
net-tools-2.0-0.51.20160912git.el8.x86_64.rpm   1.8 MB/s | 323 kB     00:00   
--------------------------------------------------------------------------------
Total                                           427 kB/s | 323 kB     00:00    
Running transaction check
Transaction check succeeded.
Running transaction test
Transaction test succeeded.
Running transaction
  Preparing        :                                                        1/1
  Installing       : net-tools-2.0-0.51.20160912git.el8.x86_64              1/1
  Running scriptlet: net-tools-2.0-0.51.20160912git.el8.x86_64              1/1
  Verifying        : net-tools-2.0-0.51.20160912git.el8.x86_64              1/1
 
Installed:
  net-tools-2.0-0.51.20160912git.el8.x86_64                                    
 
Complete!
Removing intermediate container c44679e1b6f8
 ---> e4635d92ce93
Step 7/10 : EXPOSE 80
 ---> Running in 80175acc1bb0
Removing intermediate container 80175acc1bb0
 ---> 648de32c0418
Step 8/10 : CMD echo $MYPATH
 ---> Running in 4bef6d09313d
Removing intermediate container 4bef6d09313d
 ---> ecf14f315d3e
Step 9/10 : CMD echo "sucess-----------ok"
 ---> Running in 2d6a349f1799
Removing intermediate container 2d6a349f1799
 ---> e01edd932e43
Step 10/10 : CMD /bin/bash
 ---> Running in 9b09a2ac5278
Removing intermediate container 9b09a2ac5278
 ---> 7c4be87820a6
Successfully built 7c4be87820a6
Successfully tagged mycentos:1.1
```



可以看到，每一步都执行一条dockerfile中的命令。

c.使用docker images查询镜像，自定义的镜像打好了。

![img](https://img2020.cnblogs.com/blog/2040756/202012/2040756-20201206171857360-1764279620.png)

 

 

 d.启动镜像，可以看到工作目录已经更改了