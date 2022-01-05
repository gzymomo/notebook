- [Docker中Image、Container与Volume的迁移](https://mp.weixin.qq.com/s/_cRVzJddthgoClFFvE4tyA)

已经部署的容器化服务，也不是不需要维护的。而且，由于生产环境往往有这样那样的严格要求，往往需要些非常规操作。Image（镜像）、Container（容器）和Volume（数据卷）的迁移，就是一类有用的非常规操作。

以下镜像，均以最简单的Alpine为例。

## Image

镜像的迁移，适用于离线环境。

一般离线环境，都会自建Docker Registry。无论官方的，还是最近流行的Harbor，都是不错的选择。但是，这个世界上就是有些环境，或者说一些环境在某些时期，没有外网，也没有内部的Registry。这个时候要部署Docker的服务，怎么办？

只能通过镜像的迁移。实际上，Harbor的offline installer，就是采用这种形式。

### Save

```
# use stdout
docker save alpine > /tmp/alpine.tar
# or write to a file directly
docker save alpine -o /tmp/alpine.tar
```

推荐使用`-o`的形式，因为利用stdout的做法虽然直观，但在某些场景下无效，比如利用`ssh`远程执行命令。

### Load

```
# use stdoutdocker load < /tmp/wekan.tar# or read from a file directlydocker load -i /tmp/wekan.tar
```

## Container

容器的迁移，适用于已经上线，且状态复杂、从零开始启动不能正常工作的服务。容器迁移的包，包含了镜像。

### Export

先准备一个正在运行的服务，并且弄脏环境。

```
$ docker run --rm -d --name test alpine tail -f /dev/null
9232f0c1dafe0f29918f281ca37bb41914677e818cb6f252abf3dab3be04fbb2
$ docker exec test touch proof
$ docker exec test ls -hl proof
-rw-r--r--    1 root     root           0 Nov 20 14:33 proof
```

执行导出操作：

```
docker export test -o test.tar
```

### Import

首先，关闭刚才运行的服务。

```
$ docker kill test
test
```

执行导入操作：

```
$ docker import test.tar test-img
sha256:e03727eeba7e16dd3acfcc7536f1244762508f9b6b9856e49cc837c1b7ffa444
```

要注意的是，`import`后得到的是一个镜像，相当于是执行了`docker commit`后的内容。当然，`docker commit`不是一个推荐的操作，所以容器的导入、导出，就显得不是那么的顺眼。

最后，检查之前创建的文件。

```
$ docker run --rm -d --name test test-img tail -f /dev/null
ee29cb63bb2d3ed8ac890789ba80c4fe4078b9d5343a8952b6217d64b4dcbe23
$ docker exec test ls -hl proof
-rw-r--r--    1 root     root           0 Nov 20 14:33 proof
```

## Volume

![image-20220106001624578](https://gitee.com/er-huomeng/img/raw/master/img/image-20220106001624578.png)



数据卷的迁移，比较麻烦。Docker并未提供官方的简单方案。

当然，直接用`root`用户访问文件系统的Docker数据，比如默认的`/var/lib/docker/volumes/`下的文件夹，直接进行打包操作，也不是不行。但这毫无疑问是最糟糕的方案。

目前参考《Use volumes | Docker Documentation》，找到的最佳方案是，用另一个容器，把数据卷内容打包，并且通过挂载的形式传递到宿主机。

### Backup

首先，准备一个Volume。

```
$ docker run --rm -d --name test -v test-vol:/data test-img tail -f /dev/null
f4ff81f4c31025ff476fbebc2c779a915b43ba5940b5bcc42e3ef9b1379eaeab
$ docker exec test touch /data/proof
$ docker exec test ls -hl proof
-rw-r--r--    1 root     root           0 Nov 20 14:40 proof
```

```
$ docker run --rm -v test-vol:/volume -v $PWD:/backup alpine tar cvf /backup/backup.tar volume
volume/
volume/proof
```

直接在已运行容器中打包，然后通过`docker cp`复制出来，也是一个方案。但这会对正在运行的容器有影响，不建议在真正重要的容器中使用。

这里利用了一个Alpine镜像来执行操作。实际上，任何一个自带`tar`的镜像都是可以的。

### Restore

首先，清理刚才的容器和数据卷。

```
$ docker kill test
test
$ docker volume rm test-vol
test-vol
```

执行还原操作：

```
docker run --rm -v test-vol:/volume -v $PWD:/backup alpine tar xf /backup/backup.tar
```

最后，检查还原后的结果。

```
$ docker run --rm -v test-vol:/data alpine ls -ahl /datatotal 8drwxr-xr-x    2 root     root  
```

## 结论

以上三招六式，其实都不是常规手段。

Image的传递，更应该依赖于内部Docker Registry而非tar。（当然，也有例外，比如集群部署大镜像的P2P方案，也许可以借鉴这个手段。）

Container的状态，应该是可弃的。一个运行了很长时间的Container，应该是可以`restart`、甚至`kill`后再重新`run`也不影响既有功能的。任何有依赖的状态，都应该考虑持久化、网络化，而不能单纯地保存在本地文件系统中。

Volume的手动迁移，的确可以采用上述方式。但是，Volume需要手动迁移、备份吗？这需要专业而完善的插件来实现。