- [微服务从代码到k8s部署应有尽有系列（一）](https://mp.weixin.qq.com/s/O8zbcT3dRS7Bfs02P8hn6Q)

从本篇文章开始，我们用一个系列来讲解从需求到上线、从代码到k8s部署、从日志到监控等各个方面的微服务完整实践。

实战项目地址：https://github.com/Mikaelemmmm/go-zero-looklook

## 一、项目简介 

整个项目使用了go-zero开发的微服务，基本包含了go-zero以及相关go-zero作者开发的一些中间件，所用到的技术栈基本是go-zero项目组的自研组件，基本是go-zero全家桶了。

项目目录结构如下：

- app：所有业务代码包含api、rpc以及mq（消息队列、延迟队列、定时任务）

- common：通用组件 error、middleware、interceptor、tool、ctxdata等

- data：该项目包含该目录依赖所有中间件(mysql、es、redis、grafana等)产生的数据，此目录下的所有内容应该在git忽略文件中，不需要提交。

- deploy：

- - gencode：生成api、rpc，以及创建kafka语句，复制粘贴使用
  - mysql：生成model的sh工具
  - filebeat: docker部署filebeat配置
  - go-stash：go-stash配置
  - nginx: nginx网关配置
  - prometheus ：prometheus配置
  - script：
  - goctl: 该项目goctl的template，goctl生成自定义代码模版，tempalte用法可参考go-zero文档，复制到home目录下.goctl即可， 该项目用到goctl版本是v1.3.0

- doc : 该项目系列文档

## 二、用到技术栈 

- go-zero
- nginx网关
- filebeat
- kafka
- go-stash
- elasticsearch
- kibana
- prometheus
- grafana
- jaeger
- go-queue
- asynq
- asynqmon
- dtm
- docker
- docker-compose
- mysql
- redis

## 三、项目架构图 

![图片](https://mmbiz.qpic.cn/mmbiz_png/UyIojWicPOg3LWaZBc5nXhwm2V0lhc3B4ib03GicpvD0iazhUmAiaowRtG0EggqsIAMVZpPvN2jF3esXJkCNo74rU7g/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

## 四、业务架构图 

![图片](https://mmbiz.qpic.cn/mmbiz_jpg/UyIojWicPOg3LWaZBc5nXhwm2V0lhc3B4Hd4gB0kxiaI1maicrz4c4wMlKhGGPNTq4icSocaS6SAvgWdcxOt8LibJnA/640?wx_fmt=jpeg&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

## 五、项目环境搭建 

本项目采用air热加载功即时修改代码及时生效，并且不需要每次都要重启，改了代码自动就在容器中重新加载了，本地不需要启动服务，本地安装的sdk就是写代码自动提示使用的，实际运行是以来容器中cosmtrek/air的golang环境。所以使用goland、vscode都一样

### 1、clone代码&更新依赖

```
$ git clone git@github.com:Mikaelemmmm/go-zero-looklook.git
$ go mod tidy
```

### 2、启动项目所依赖的环境

```
$ docker-compose -f docker-compose-env.yml up -d
```

jaeger: http://127.0.0.1:16686/search

asynq （延时、定时消息队列）: http://127.0.0.1:8980/

kibana: http://127.0.0.1:5601/

Elastic search: http://127.0.0.1:9200/

Prometheus: http://127.0.0.1:9090/

Grafana: http://127.0.0.1:3001/

Mysql: 自行客户端工具(Navicat、Sequel Pro)查看

- host : 127.0.0.1
- port : 33069
- username : root
- pwd : PXDN93VRKUm8TeE7

Redis:  自行工具（redisManager）查看

- host : 127.0.0.1
- port : 63799
- pwd : G62m50oigInC30sf

Kafka:  自行客户端工具查看

- host : 127.0.0.1
- port : 9092

### 3、拉取项目依赖镜像

因为本项目是用air热加载的，所以是在air+golang镜像中运行，直接docker-compose也可以，但是考虑依赖可能会比较大，会影响启动项目，所以最好先把这个镜像拉取下来再去启动项目，拉取air+golang项目依赖的镜像命令如下

```
$ docker pull cosmtrek/air:latest
```

### 4、导入mysql数据

创建数据库looklook_order && 导入deploy/sql/looklook_order.sql数据

创建数据库looklook_payment && 导入deploy/sql/looklook_payment.sql数据

创建数据库looklook_travel && 导入deploy/sql/looklook_travel.sql数据

创建数据库looklook_usercenter && 导入looklook_usercenter.sql数据

### 5、启动项目

```
$ docker-compose up -d 
```

【注】依赖的是项目根目录下的docker-compose.yml配置

### 6、查看项目运行情况

访问 http://127.0.0.1:9090/ ， 点击上面菜单“Status”，再点击Targets , 蓝色的就是启动成了，红色就是没启动成功

![图片](https://mmbiz.qpic.cn/mmbiz_png/UyIojWicPOg3LWaZBc5nXhwm2V0lhc3B4JTqNs58lKR5EO3znLrKFsH7GSnMEYbNeVZDRfA1Q88CVP7sXYT2Q3A/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

【注】如果是第一次拉取项目，每个项目容器第一次构建拉取依赖，这个看网络情况，可能会比较慢有的服务，所以会导致项目启动失败或者被依赖的服务启动失败自己也启动失败了，这个很正常，如果碰到项目启动不起来的情况，比如order-api ，这时候我们去看下日志就可以

```
$ docker logs -f order-api 
```

![图片](https://mmbiz.qpic.cn/mmbiz_png/UyIojWicPOg3LWaZBc5nXhwm2V0lhc3B44pMBsjCE6eyXq5VlE7G0FWVty0jsbjLKdksBMGUibTDaehvKuMib0ia0w/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

很明显是因为order-rpc启动时间太久了，而order-api一直等他启动，order-rpc一定时间内没有启动成功，order-api没耐心了（超时了），就算后面order-rpc启动起来，它也不管了，这时候再去重启一次order-api就可以了，这个只是第一次创建容器会这样，之后只要不销毁容器就不会，我们去到项目根目录下重启一下

```
$ docker-compose restart order-api
```

【注意】一定要去到项目根目录下重启 ，因为docker-compose.yml在项目根目录

然后我们再看一下，这里我们使用docker logs 看了

```
  __    _   ___  
 / /\  | | | |_) 
/_/--\ |_| |_| \_ , built with Go 1.17.6

mkdir /go/src/github.com/looklook/app/order/cmd/api/tmp
watching .
watching desc
watching desc/order
watching etc
watching internal
watching internal/config
watching internal/handler
watching internal/handler/homestayOrder
watching internal/logic
watching internal/logic/homestayOrder
watching internal/svc
watching internal/types
!exclude tmp
building...
running...
```

可以看到order-api已经成功了 ，再去prometheus看一下

![图片](https://mmbiz.qpic.cn/mmbiz_png/UyIojWicPOg3LWaZBc5nXhwm2V0lhc3B4VCapPwN9z0UxlycPBiaAdB4EsJibwgQp3C0ibibiboHnfurwARYPaW4S15A/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

可以看到prometheus也显示成功了，同理把其他的也排查一次，启动成功就可以了

![图片](https://mmbiz.qpic.cn/mmbiz_png/UyIojWicPOg3LWaZBc5nXhwm2V0lhc3B4J4Ucd4Oj3dRY2Cj0Kjr0vAP8srialGaeQ1BYNrjjsIrJlsGtyKibmWxg/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

### 7、访问项目

由于我们使用nginx做的网关，nginx网关配置在docker-compose中，也是配置在docker-compose中，nignx对外暴露端口是8888，所以我们通过8888端口访问

```
$ curl  -X POST "http://127.0.0.1:8888/usercenter/v1/user/register" -H "Content-Type: application/json" -d "{\"mobile\":\"18888888888\",\"password\":\"123456\"}" 

返回:
{"code":200,"msg":"OK","data":{"accessToken":"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2NzM5NjY0MjUsImlhdCI6MTY0MjQzMDQyNSwiand0VXNlcklkIjo1fQ.E5-yMF0OvNpBcfr0WyDxuTq1SRWGC3yZb9_Xpxtzlyw","accessExpire":1673966425,"refreshAfter":1658198425}}
```

【注】 如果是访问nginx失败，访问成功可以忽略，可能是nginx依赖后端服务，之前因为后端服务没启动起来，nginx这里没启动起来，重启一次nginx即可,项目根目录下重启

```
$ docker-compose restart nginx
```

## 六、日志收集 

将项目日志收集到es（filebeat收集日志->kafka -> go-stash消费kafka日志->输出到es中, kibana查看es数据）

所以我们要提前在kafka中创建日志的topic

进入kafka容器

```
$ docker exec -it kafka /bin/sh
```

创建log的topic

```
$ cd /opt/kafka/bin
$ ./kafka-topics.sh --create --zookeeper zookeeper:2181 --replication-factor 1 -partitions 1 --topic looklook-log
```

访问kibana http://127.0.0.1:5601/ ， 创建日志索引

点击左上角菜单(三个横线那个东东)，找到Analytics - > 点击discover

![图片](https://mmbiz.qpic.cn/mmbiz_png/UyIojWicPOg3LWaZBc5nXhwm2V0lhc3B42rtjMOkeId8euYQbrYgRUX6OTK32lMzrjQwOW7ysjdsVRBLMZiaeVicw/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

然后在当前页面，Create index pattern->输入looklook-*  -> Next Step ->选择@timestamp->Create index pattern

然后点击左上角菜单，找到Analytics->点击discover ，日志都显示了 （如果不显示，就去排查filebeat、go-stash，使用docker logs -f filebeat查看）

![图片](https://mmbiz.qpic.cn/mmbiz_png/UyIojWicPOg3LWaZBc5nXhwm2V0lhc3B42IW6CZCV1Q8Kjz6nsrWc5usVH0jw3ic2K4lPeRShMQ172BwBNRngAtA/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

## 七、本项目镜像介绍 

所有服务启动成功，应该是如下这些，自行对比

![图片](https://mmbiz.qpic.cn/mmbiz_png/UyIojWicPOg3LWaZBc5nXhwm2V0lhc3B4c6YxMFJR3EGEezjib5Y4YgDDkYzI5tyWsicCIsb4ibIwwefyKTLtUrvnw/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

- nginx : 网关 （nginx->api->rpc）
- cosmtrek/air : 我们业务代码开发依赖的环境镜像，之所以用这个是因为air热加载，写代码实时编译太方便了，这个镜像是air+golang，实际上我们启我们自己的业务服务后，我们的业务服务是运行在此镜像中的
- wurstmeister/kafka ：业务使用的kafka
- wurstmeister/zookeeper ：kafka依赖的zookeeper
- redis：业务使用的redis
- mysql: 业务使用的数据库
- prom/prometheus：监控业务
- grafana/grafana ：prometheus的ui很难看，用来显示prometheus收集来的数据
- elastic/filebeat ：收集日志到kafka
- go-stash : 消费kafka中日志，脱敏、过滤然后输出到es
- docker.elastic.co/elasticsearch/elasticsearch ：存储收集的日志
- docker.elastic.co/kibana/kibana ：显示elasticsearch
- jaegertracing/jaeger-query 、jaegertracing/jaeger-collector、jaegertracing/jaeger-agent：链路追踪
- go-stash : filebeat收集日志到kafka后，go-stash去消费kafka进行数据脱敏、过滤日志中内容，最后输出到es中

## 八、项目开发建议 

- app下放所有业务服务代码
- common放所有服务的公共基础库
- data项目依赖中间件产生的数据，实际开发中应该在git中忽略此目录以及此目录下产生的数据
- 生成api、rpc代码：

一般我们在生成api，rpc代码时候手动去敲goctl的命令比较长，也记不住，所以我们直接去deploy/script/gencode/gen.sh中复制代码即可。比如我在usercenter服务中新增加了一个业务，修改密码，写完api文件之后，进入到usercenter/cmd目录下，直接复制deploy/script/gencode/gen.sh中的生成api命令运行即可

```
$ goctl api go -api ./api/desc/*.api -dir ./api -style=goZero
```

生成rpc也一样，在写完proto文件后，直接粘贴复制deploy/script/gencode/gen.sh中的生成rpc命令运行即可

```
$ goctl rpc proto -src rpc/pb/*.proto -dir ./rpc -style=goZero
$ sed -i 's/,omitempty//g'  ./rpc/pb/*.pb.go
```

【注】建议在生成rpc文件时候，再多执行一次下面那个命令，把protobuf生成的omitempty给删除掉，不然字段为nil就不返回了

- 生成kafka代码：

  因为本项目使用了go-queue的kq做消息队列，kq又依赖的kafka，实际就是使用了kafka做消息队列，但是kq默认是需要我们提前把topic建好的，不许默认自动生成，所以命令也准备好了，直接复制deploy/script/gencode/gen.sh中的创建kafka的topic代码即可

  ```
   kafka-topics.sh --create --zookeeper zookeeper:2181 --replication-factor 1 -partitions 1 --topic {topic}
  ```

- 生成model代码，直接运行deploy/script/mysql/genModel.sh  参数

- api项目中的.api文件我们做了拆分，统一放到每个api的desc文件夹下，因为如果所有内容都写在api中可能不便于查看，所以做了拆分，把所有方法写到一个api中，其他的实体以及req、rep统一放到一个文件夹单独定义比较清晰

- 生成model、错误处理时候使用了template重新定义，该项目用到的自定义的goctl的模版在项目data/goctl下

## 九、后续 

由于项目中由于涉及到的技术栈稍微有点多，将分章节一步一步讲解，敬请关注。

## 项目地址 

https://github.com/zeromicro/go-zero