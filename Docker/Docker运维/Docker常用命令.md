//stop停止所有容器

```bash
docker stop $(docker ps -a -q)
```


//remove删除所有容器 

```bash
docker  rm $(docker ps -a -q) 
```


//删除所有exit的容器

```bash
docker rm $(sudo docker ps -qf status=exited)
```


//删除所有镜像

```bash
docker rmi -f $(docker images -qa)
```



# 卸载docker

1.卸载主机上的Docker

- 　查看现有Docker版本

```bash
yum list installed | grep docker
```

　　docker-ce.x86_64    17.12.1.ce-1.el7.centos    @docker-ce-stable

- 　执行卸载命令(执行该命令只卸载Docker本身，不会删除Docker存储的文件，如镜像、容器等，这些文件存在与/var/lib/docker中，需手动删除)

```bash
yum -y remove docker-ce.x86_64
```

- 删除Docker存储文件

```bash
rm -rf /var/lib/docker
```



