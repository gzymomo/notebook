- [Kubernetes集群使用Dockerfile构建的镜像部署微服务项目基础架构](https://mp.weixin.qq.com/s/gWVS690sRAkGdDqjz7bnWA)

## Dockerfile简介

​    Dockerfile，相当于是一个文档，客户可以基于dockerfile生成新的容器。Dockerfile仅仅是用来制作镜像的源码文件，是构建容器过程中的指令。Docker能够读取Dockerfile的指定进行自动构建，基于Dockerfile制作镜像。每一个指定都会构建一个镜像层，即镜像都是多层叠加而成，因此，层数越多，效率越低，层数越少越好，因此能在一个指定完成的动作尽量通过一个指定定义。

### 01 注意事项

使用Dockerfile注意事项

**最大可能保持镜像最小**

**使用secret存储服务使用的敏感应用程序数据**

**使用configs 存储配置文件等非敏感数据**

### 02 Dockerfile常见指令

```bash
FROM
构建镜像基于哪个镜像

MAINTAINER
镜像维护者姓名或邮箱地址

RUN
构建镜像时运行的指令

CMD
运行容器时执行的shell环境

VOLUME
指定容器挂载点到宿主机自动生成的目录或其他容器

USER
为RUN、CMD、和 ENTRYPOINT 执行命令指定运行用户

WORKDIR
为 RUN、CMD、ENTRYPOINT、COPY 和 ADD 设置工作目录，就是切换目录

HEALTHCHECH
健康检查

ARG
构建时指定的一些参数

EXPOSE
声明容器的服务端口（仅仅是声明）

ENV
设置容器环境变量

ADD
拷贝文件或目录到容器中，如果是URL或压缩包便会自动下载或自动解压

COPY
拷贝文件或目录到容器中，跟ADD类似，但不具备自动下载或解压的功能

ENTRYPOINT
运行容器时执行的shell命令
```

## Dockerfile构建镜像

### 01 环境介绍

| **节点 **              | **IP地址 **     |
| ---------------------- | --------------- |
| **kubernetes-master ** | **10.0.0.115 ** |
| **kubernetes-node-1 ** | **10.0.0.116**  |
| **kubernetes-node-2**  | **10.0.0.117**  |
| **kubernetes-node-3**  | **10.0.0.118**  |
| **harbor **            | **10.0.0.119**  |

### 02 开始构建

```
[root@Harbor mysql]# tree
.
├── docker-entrypoint.sh
├── Dockerfile
├── healthcheck.sh
└── inspec
    └── control.rb
下载地址：https://www.xingdiancloud.cn/index.php/s/rRTyrBMms22N6ae
```

```
[root@Harbor mysql]# docker build -t 10.0.0.119/mysql:5.7 .
```

### 03 镜像上传Harbor

```
[root@Harbor mysql]# docker tag 10.0.0.119/mysql:5.7 10.0.0.119/xingdian/mysql:5.7
[root@Harbor mysql]# docker push 10.0.0.119/library/mysql:5.7
```

### 04 Kubernetes集群调用

具体操作见：[kubernetes集群采用Harbor私服提供仓库存储服务](http://mp.weixin.qq.com/s?__biz=Mzg3NzcyOTQ2MA==&mid=2247485171&idx=1&sn=3e8a34b7d73ae25eae7a8dc076cea8b9&chksm=cf1fc528f8684c3e668412dc54750fd1655bad00fe6c07d702116f3d55695ad04da81b12ae5f&scene=21#wechat_redirect)

创建对应的secret

### 05 kubernetes集群部署mysql

```yaml
[root@Harbor mysql]# vim mysql-rc.yaml
apiVersion: v1
kind: ReplicationController
metadata:
  name: mysql-rc
  namespace: mysql
  labels:
    name: mysql-rc
spec:
  replicas: 1
  selector:
    name: mysql-pod
  template:
    metadata:
      labels: 
        name: mysql-pod
    spec:
      containers:
      - name: mysql
        image: 10.0.0.119/xingdian/mysql:5.7
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 3306
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: "mysql"
```

```yaml
[root@Harbor mysql]# vim mysql-svc.yaml
apiVersion: v1
kind: Service
metadata:
  name: mysql-svc
  namespace: mysql
  labels: 
    name: mysql-svc
spec:
  type: NodePort
  ports:
  - port: 3306
    protocol: TCP
    targetPort: 3306
    name: http
    nodePort: 30013
  selector:
    name: mysql-pod
```

```bash
[root@Harbor mysql]# kubectl create namespace mysql
[root@Harbor mysql]# kubectl create -f mysql-rc.yaml
[root@Harbor mysql]# kubectl create -f mysql-svc.yaml
```

### 06 查看运行状态

```bash
[root@master ~]# kubectl get pods
NAME       READY   STATUS    RESTARTS   AGE
mysql   1/1     Running   0          10m
```