- [Kubernetes Velero 备份的运用](http://tnblog.net/hb/article/details/5669)



## Velero简介


Velero是一个开源工具，可以安全地备份，恢复和迁移Kubernetes集群和持久卷。它既可以在本地运行，也可以在公共云中运行。Velero由在Kubernetes集群中作为部署运行的服务器进程和命令行界面（CLI）组成，DevOps团队和平台操作员可使用该命令行界面配置计划的备份，触发临时备份，执行还原等。

## 是什么让Velero脱颖而出？


与直接访问Kubernetes etcd数据库以执行备份和还原的其他工具不同，Velero使用Kubernetes API捕获群集资源的状态并在必要时对其进行还原。这种由API驱动的方法具有许多关键优势：

— 备份可以捕获群集资源的子集，并按名称空间，资源类型和/或标签选择器进行过滤，从而为备份和还原的内容提供了高度的灵活性。
— 托管Kubernetes产品的用户通常无法访问底层的etcd数据库，因此无法对其进行直接备份/还原。
— 通过聚合的API服务器公开的资源可以轻松备份和还原，即使它们存储在单独的etcd数据库中也是如此。

此外，借助Velero，您可以使用存储平台的本机快照功能或称为restic的集成文件级备份工具来备份和还原应用程序的持久数据及其配置 。

## 重要的三大功能


— **灾难恢复**  在基础架构丢失，数据损坏和/或服务中断的情况下，减少了恢复时间。
— **数据迁移**  通过轻松地将Kubernetes资源从一个集群迁移到另一个集群来实现集群可移植性。
— **数据保护**  提供关键数据保护功能，例如计划的备份，保留计划以及自定义操作的备份前或备份后挂钩。

## veleo备份原理

![img](https://img.tnblog.net/arcimg/hb/ba52163e59744145a1ebde124cbd64c9.png)


本地 Velero 客户端发送备份指令。

\1. Kubernetes 集群内就会创建一个 Backup 对象。

\2. BackupController 监测 Backup 对象并开始备份过程。

\3. BackupController 会向 API Server 查询相关数据。

\4. BackupController 将查询到的数据备份到远端的对象存储。

Velero 在 Kubernetes 集群中创建了很多 CRD 以及相关的控制器，进行备份恢复等操作实质上是对相关 CRD 的操作。

## 下载Velero应用

### 下载当前最新版本


到该地址查看最新版本 https://github.com/vmware-tanzu/velero/releases ，当前版本最新为（1.5.3）
我们通过如下命令进行安装

```
wget https://github.com/vmware-tanzu/velero/releases/download/v1.5.3/velero-v1.5.3-linux-amd64.tar.gz# 解压tar -C /usr/local/bin -xzvf velero-v1.5.3-linux-amd64.tar.gz# 添加到环境变量中去export PATH=$PATH:/usr/local/bin/velero-v1.5.3-linux-amd64/# 测试是否安装成功了velero -h
```

## 安装miniio

### 简介


[MinIO](https://docs.min.io/cn/) 是一个基于Apache License v2.0开源协议的对象存储服务。它兼容亚马逊S3云存储服务接口，非常适合于存储大容量非结构化的数据，例如图片、视频、日志文件、备份数据和容器/虚拟机镜像等，而一个对象文件可以是任意大小，从几kb到最大5T不等。

### 创建minio凭证（credentials-velero文件）

```
vim credentials-velero
[default]aws_access_key_id = minioaws_secret_access_key = minio123
```

### 启动服务器和本地存储服务

```
kubectl create -f /usr/local/bin/velero-v1.5.3-linux-amd64/examples/minio/00-minio-deployment.yaml
```

### 开放端口

```
kubectl expose deployment minio -n velero --type=NodePort --name=minio-nodeport  --target-port=9000
```

> 然后在本地通过本地代理访问minio服务，我这里访问的链接是：http://127.0.0.1:8001/api/v1/namespaces/velero/services/minio/proxy
> 不清楚的可以参考我这篇文章：https://www.tnblog.net/hb/article/details/4681
> 这里的账号与密码默认是：`minio/minio123`

![img](https://img.tnblog.net/arcimg/hb/a67ca489b233429e900f718f0d3fd3a5.png)

奇怪的是我们好像怎么样都登录不上去

![img](https://img.tnblog.net/arcimg/hb/6260cba58f074e7783fe4a52b4a79f6a.png)


这个时候我们可以通过NodePort的服务进行外网访问，那么我这里是外网`IP:32422`

![img](https://img.tnblog.net/arcimg/hb/93ca95169f8c4f03a4293a99777de08f.png)

### 创建velero桶


随后我们在右下角创建Velero的Bucket

![img](https://img.tnblog.net/arcimg/hb/f9d0f4a450b44b61b341aab5a232c4e2.png)

![img](https://img.tnblog.net/arcimg/hb/e0829066b6034cedbbd436228f08688a.png)

![img](https://img.tnblog.net/arcimg/hb/79f4e353b84e4d889f88121eb26da7d2.png)

## 安装velero （使用本地集群minio作为备份存储）

注意在s3Url这里填写自己的minio地址（NodePort地址）

```
velero install \    --provider aws \    --plugins velero/velero-plugin-for-aws:v1.0.0 \    --bucket velero \    --secret-file ./credentials-velero \    --use-volume-snapshots=false \    --backup-location-config region=minio,s3ForcePathStyle="true",s3Url=http://192.168.255.97:9000
```

本示例假定它在本地群集中运行，而没有能够提供快照的卷提供程序，因此不会`VolumeSnapshotLocation`创建（`--use-volume-snapshots=false`）。
此外，您可以指定`--use-restic`启用Restic支持，并`--wait`等待部署准备就绪。

## 小案例

> 部署示例nginx应用程序：

```
kubectl apply -f /usr/local/bin/velero-v1.5.3-linux-amd64/examples/nginx-app/base.yaml
```

![img](https://img.tnblog.net/arcimg/hb/626c44d09e6f41bf95e7b5ebccf0a10d.png)

> 检查是否成功创建了Velero和nginx部署：

```
kubectl get deployments -l component=velero --namespace=velerokubectl get deployments --namespace=nginx-example -o wide
```

![img](https://img.tnblog.net/arcimg/hb/d3bb46cb95ae4533bbfb65079fa97a35.png)

### 备份

> 为`namespaces=nginx-example`命名空间和`app=nginx`标签选择器匹配的任何对象创建备份：

```
velero backup create nginx-backup --selector app=nginx --include-namespaces=nginx-example
```

> （可选）使用`namespaces=nginx-example`命名空间和`app=nginx`标签选择器基于cron表达式创建定期计划的备份：

```
velero schedule create nginx-daily --schedule="0 1 * * *" --selector app=nginx --include-namespaces=nginx-example
```

> 然后我们通过下面的命令查看备份情况，也可以从UI上进行查看备份信息

```
velero backup describe nginx-backup
```

![img](https://img.tnblog.net/arcimg/hb/76958472bfdb40178eafc5f0bfcaf9b9.png)

### 模拟灾难

```
kubectl delete namespace nginx-example
```

![img](https://img.tnblog.net/arcimg/hb/2aa286fac5784c10a26ce0fcfbdaa0f8.png)

### 恢复

> 执行

```
velero restore create --from-backup nginx-backup
```

## 卸载

> 要从Kubernetes集群中完全卸载Velero，minio，请执行以下操作：

```
kubectl delete namespace/velero clusterrolebinding/velerokubectl delete crds -l component=velerokubectl delete -f examples/nginx-app/base.yaml
```

## 资源查看

```
velero  get  backup   #备份查看velero  get  schedule #查看定时备份velero  get  restore  #查看已有的恢复velero  get  plugins  #查看插件
```