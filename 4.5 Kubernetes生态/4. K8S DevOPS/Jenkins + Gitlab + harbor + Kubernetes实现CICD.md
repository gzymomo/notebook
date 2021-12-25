- [Jenkins + Gitlab + harbor + Kubernetes实现CI/CD](https://blog.51cto.com/u_13777088/4840329)

Jenkins + Gitlab + harbor + Kubernetes实现CI/CD

#### 机器规划

kubernetes集群：v1.20.4

gitlab: gitlab-ce-13.7.1

harbor: v2.2.1

jenkins: jenkinsci/blueocean:latest

#### 发布流程

1、从gitlab拉取代码

2、代码编译

3、打包镜像、上传仓库

4、使用jenkins pod部署至k8s集群中

#### 部署文件清单

```
[root@devops maven-java-pipeline-app]# tree
.
├── deploy.yaml
├── Dockerfile
├── jenkinsci
│   └── jenkinsci.yml
├── Jenkinsfile
├── jenkins-slave
│   ├── Dockerfile
│   ├── jenkins-slave
│   ├── kubectl
│   ├── settings.xml
│   └── slave.jar
├── pom.xml
├── README.md
├── src
└── tomcat8
    ├── apache-tomcat-8.5.73.tar.gz
    ├── Dockerfile
    └── jdk-8u151-linux-x64.tar.gz
```

#### 部署Jenkins

```
#kubectl apply -f jenkinsci/jenkinsci.yml
```

#### 制作tomcat镜像

```
#docker build -t devops.sly.com/library/tomcat8 .
#docker push devops.sly.com/library/tomcat8
```

#### 制作jenkins-slave镜像

```
#docker build -t harbor.sly.com/library/jenkins-slave-jdk .
#docker push harbor.sly.com/library/jenkins-slave-jdk
```

#### 登录jenkins安装插件

系统管理-->插件管理

搜索安装Git、Git Parameter、kubernetes、Config File Provider、Dingtalk

![Jenkins + Gitlab + harbor + Kubernetes实现CI/CD_devops](https://s3.51cto.com/images/202112/24f110585558f139539161a7ae12544eab95fe.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)

#### 在jenkins中添加kubernetes云

系统管理-->节点管理-->Configure Clouds

配置完成点击测试连接，如果无报错并显示kubernetes集群版本信息，说明配置正确

![Jenkins + Gitlab + harbor + Kubernetes实现CI/CD_git_02](https://s3.51cto.com/images/202112/0382957629d134e736f5686780ae9e8a5719cd.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)

![Jenkins + Gitlab + harbor + Kubernetes实现CI/CD_tomcat_03](https://s8.51cto.com/images/202112/263658d7131bc4ac7606114cf178749d52afcc.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)

![Jenkins + Gitlab + harbor + Kubernetes实现CI/CD_tomcat_04](https://s7.51cto.com/images/202112/93e56f80970c8c4812a8366223ae624ac49377.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)

####  

#### Jenkins中配置认证信息

1、gitlab认证信息，用于从gitlab仓库中拉取代码

2、harbor仓库认证信息，用于上传及拉取镜像

![Jenkins + Gitlab + harbor + Kubernetes实现CI/CD_git_05](https://s9.51cto.com/images/202112/d31dc8046148a1e0a3215591aa93fe837aee80.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)

3、配置jenkins-slave在k8s集群中部署应用所需的认证权限文件

系统管理-->Managed file-->Add a new Config

![Jenkins + Gitlab + harbor + Kubernetes实现CI/CD_gitlab_06](https://s6.51cto.com/images/202112/f2591e695e40910afd302539f95265fefa62ef.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)

![Jenkins + Gitlab + harbor + Kubernetes实现CI/CD_devops_07](https://s7.51cto.com/images/202112/87949a1033bea9b9d7b4753aa0a2f64ec429ad.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)

#### Jenkins中配置pipeline流水线

新建任务-->按提示输入项目名称-->选择流水线-->确定

![Jenkins + Gitlab + harbor + Kubernetes实现CI/CD_gitlab_08](https://s4.51cto.com/images/202112/14bb5d4491bd03cec202782bd87997e826790f.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)

在流水线模块选择Git，输入项目地址，选择提前配置好的认证信息，脚本路径填Jenkinsfile

![Jenkins + Gitlab + harbor + Kubernetes实现CI/CD_gitlab_09](https://s5.51cto.com/images/202112/04aa39505a5d2d606ed654ab04e7f36d58efed.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)

#### 部署测试

jenkins页面选择创建的项目，点击立即构建

![Jenkins + Gitlab + harbor + Kubernetes实现CI/CD_docker_10](https://s6.51cto.com/images/202112/63059fd49f4908292165253bcf18a05689d82c.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)

此处出现的选项都是在Jenkinsfile中定义好的

![Jenkins + Gitlab + harbor + Kubernetes实现CI/CD_git_11](https://s8.51cto.com/images/202112/87a505500c5dba055a831441da974bfc1dae46.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)

构建输出：

![Jenkins + Gitlab + harbor + Kubernetes实现CI/CD_git_12](https://s5.51cto.com/images/202112/b7c0cf17219f32d6383874682821a9f570fe35.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)

![Jenkins + Gitlab + harbor + Kubernetes实现CI/CD_gitlab_13](https://s7.51cto.com/images/202112/07bd1ac007e1fc2b01226686c63e6cfbdeb451.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)

输出日志提示SUCCESS，同时收到钉钉通知消息

![Jenkins + Gitlab + harbor + Kubernetes实现CI/CD_git_14](https://s4.51cto.com/images/202112/b962d7992ae4694ca985134d2dae442ef93d76.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)

项目访问测试：

![Jenkins + Gitlab + harbor + Kubernetes实现CI/CD_gitlab_15](https://s3.51cto.com/images/202112/c44dee19009be8f021e1405d1a2b2cff0160a8.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)