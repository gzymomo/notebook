1、获取redis镜像

  执行命令：docker pull redis，不加版本号是获取最新版本，也可以加上版本号获取指定版本

 **![img](https://img2020.cnblogs.com/blog/395813/202004/395813-20200405111615229-1727448413.png)**

 

2、查看本地镜像

![img](https://img2020.cnblogs.com/blog/395813/202004/395813-20200405111816049-1493073957.png)

 

 3、创建本地配置文件redis.conf，从[官网下载](http://download.redis.io/redis-stable/redis.conf)

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

```
在/usr/local目录下创建docker目录
mkdir /usr/local/docker
cd /usr/local/docker
再在docker目录下创建redis目录
mkdir redis&&cd redis
创建配置文件，并将官网redis.conf文件配置复制下来进行修改
touch redis.conf
创建数据存储目录data
mkidr data
```

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

![img](https://img2020.cnblogs.com/blog/395813/202004/395813-20200405113759717-103929108.png)

修改启动默认配置(从上至下依次)：

bind 127.0.0.1 #注释掉这部分，这是限制redis只能本地访问

protected-mode no #默认yes，开启保护模式，限制为本地访问

daemonize no#默认no，改为yes意为以守护进程方式启动，可后台运行，除非kill进程，改为yes会使配置文件方式启动redis失败

databases 16 #数据库个数（可选），我修改了这个只是查看是否生效。。

dir ./ #输入本地redis数据库存放文件夹（可选）

appendonly yes #redis持久化（可选）

requirepass 密码 #配置redis访问密码

4、创建并启动redis容器

docker run -p 6379:6379 --name redis -v /usr/local/docker/redis/redis.conf:/etc/redis/redis.conf -v /usr/local/docker/redis/data:/data -d redis redis-server /etc/redis/redis.conf --appendonly yes

5、查看redis容器

执行命令：docker container ls -a

![img](https://img2020.cnblogs.com/blog/395813/202004/395813-20200405123422159-1265425755.png)

 

 执行命令：docker ps查看运行的容器

![img](https://img2020.cnblogs.com/blog/395813/202004/395813-20200405123517777-1783416610.png)

 

 5、通过 redis-cli 连接测试使用 redis 服务

  执行命令：docker exec -it redis /bin/bash  进入docker终端，在终端中输入：redis-cli

![img](https://img2020.cnblogs.com/blog/395813/202004/395813-20200405123842578-889277769.png)