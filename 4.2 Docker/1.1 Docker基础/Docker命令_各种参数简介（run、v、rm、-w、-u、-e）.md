- [Docker命令_各种参数简介（run、v、rm、-w、-u、-e）_sun0322的博客-CSDN博客](https://blog.csdn.net/sxzlc/article/details/107676425)

## 1 run 的各种参数

```bash
docker run [OPTIONS] IMAGE [COMMOND] [ARGS...]
 
# OPTIONS 说明
	--name="容器新名字": 为容器指定一个名称；
	-d: 后台运行容器，并返回容器ID，也即启动守护式容器；
	-i：以交互模式运行容器，通常与 -t 同时使用；
	-t：为容器重新分配一个伪输入终端，通常与 -i 同时使用；
	-P: 随机端口映射；
	-p: 指定端口映射，有以下四种格式
	      ip:hostPort:containerPort
	      ip::containerPort
	      hostPort:containerPort
	      containerPort
    -w: 指定命令执行时，所在的路径
 
# IMAGE
XXX_IMAGE_NAME:XXX_IMAGE_VER
 
 
# COMAND
例：mvn -Duser.home=xxx -B clean package -Dmaven.test.skip=true

常用OPTIONS补足：
--name：容器名字
--network：指定网络
--rm：容器停止自动删除容器
 
-i：--interactive,交互式启动
-t：--tty，分配终端
-v：--volume,挂在数据卷
-d：--detach，后台运行
```

