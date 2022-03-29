- [如何从容器内部执行宿主机的docker命令 - 简书 (jianshu.com)](https://www.jianshu.com/p/8b72eece7df8)

#### 1) 把docker相关的命令和依赖使用-v挂载到容器

```shell
docker run -it -d  \
--restart=always -u root \
-v /usr/bin/docker:/usr/bin/docker \
-v /var/run/docker.sock:/var/run/docker.sock \
-v /usr/lib64/libltdl.so.7:/usr/lib/x86_64-linux-gnu/libltdl.so.7 镜像名称
```

##### docker run 参数说明

```shell
--restart=always #Docker重启后该容器也为随之重启
```

```shell
-u root          
#以root的身份去运行镜像(避免在容器中调用Docker命令没有权限)
#最好使用docker用户去运行
```

```shell
-v /usr/bin/docker:/usr/bin/docker
#将宿主机的docker命令挂载到容器中
#可以使用which docker命令查看具体位置
#或者把挂载的参数改为: -v $(which docker):/usr/bin/docker
```

```shell
-v /var/run/docker.sock:/var/run/docker.sock
#容器中的进程可以通过它与Docker守护进程进行通信
```

```shell
-v /usr/lib64/libltdl.so.7:/usr/lib/x86_64-linux-gnu/libltdl.so.7
#libltdl.so.7是Docker命令执行所依赖的函数库
#容器中library的默认目录是 /usr/lib/x86_64-linux-gnu/
#把宿主机的libltdl.so.7 函数库挂载到该目录即可
#可以通过whereis libltdl.so.7命令查看具体位置
#centos7位置/usr/lib64/libltdl.so.7
#ubuntu位置/usr/lib/x86_64-linux-gnu/libltdl.so.7
```

#### 2) 为当前用户赋予执行docker命令的权限

如果之前为docker创建过用户,则需要执行以下命令,没有的话直接跳过

```shell
#则需要把将当前用户加入docker组
sudo gpasswd -a ${USER} docker

#或者将当前用户直接加到文件中
sudo echo "docker:x:994:${USER}" >> /etc/group

#查看docker用户组成员
cat /etc/group |grep docker

#重新启动docker服务
sudo systemctl restart docker

#当前用户退出系统重新登陆
```

