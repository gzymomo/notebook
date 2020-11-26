# 1、helm

​	Helm是一个Kubernetes的包管理工具，类似Linux下的包管理器，如yum/apt等，可以很方便的将之前打包好的yaml文件部署到kubernetes上。

使用helm可以解决哪些问题？

- 使用helm可以把yaml作为一个整体管理。
- 实现yaml文件的高效复用。
- 使用helm可以解决应用级别的版本管理。



​	Helm有三个重要概念：

1. helm：一个命令行客户端工具，主要用于Kubernetes应用chart的创建、打包、发布和管理。
2. Chart：应用描述，一系列用于描述k8s资源相关文件的集合。
3. Release：基于Chart的部署实体，一个chart被Helm运行后将会生成对应的一个release；将在k8s中创建出真实运行的资源对象。



# 2、V3版本安装

官网地址：helm.sh

1. 下载helm安装压缩文件，上传到linux系统中
2. 解压helm压缩文件，把解压之后helm目录复制到/usr/bin目录下
3. 然后就可以使用helm了



## 2.1 配置Helm仓库

1. 添加仓库

helm repo add 仓库名称 仓库地址

```bash
# 微软地址
helm repo add stable http://mirror.azure.cn/kubernetes/charts
# 阿里云地址
helm repo add aliyun https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts
helm repo update
```

2. 查看配置的存储库

```bash
helm repo list
helm search repo stable
```

3. 删除存储库

```bash
helm repo remove aliyun
```



# 3、helm快速部署应用

helm基本使用命令：

- chart install
- chart upgrade
- chart rollback



1. 使用命令搜索应用

```bash
helm search repo 名称（weave）
```

2. 根据搜索内容选择进行按照

```bash
helm install 安装之后的名称  搜索之后的应用名称
```

3. 查看安装之后状态

```bash
helm list
helm status 安装之后名称
```



修改service的yaml文件，type改为NodePort

```bash
kubectl edit save <Name>
# 如：
kubectl edit svc ui-weave-scope
```



# 4、自定义chart部署

1. 使用命令创建chart，创建后会生成一份模板

```bash
helm create mychart
```

- Chartyaml：当前chart属性配置信息
- templates：编写yaml文件放到这个目录中
- values.yaml：yaml文件可以使用全局变量

2. 在templates文件夹创建两个yaml文件

- deployment.yaml
- service.yaml

3. 安装mychart

```bash
helm install web mychart/
```

4. 应用升级

```bash
helm upgrade chart名称
# 如：
helm upgrade web1 mychart/
```

# 5、Chart模板使用

实现yaml高效复用。

- 通过传递参数，动态渲染模板，yaml内容动态传入参数生成。
- 通过使用values.yaml文件。



在chart有values.yaml文件，定义yaml文件全局变量。

yaml文件大体有几个地方不同：

- image
- tag
- label
- port
- replicas



1. 在values.yaml定义变量和值

```yaml
vi values.yaml

replicas: 1
image: nginx
tag: 1.16
label: nginx
port: 80
```



2. 在具体yaml文件，获取定义变量值。在templates的yaml文件中使用values.yaml定义的变量

- 通过表达式形式使用全局变量
  - {{ .Values.变量名称 }}
  - {{ .Release.Name }}