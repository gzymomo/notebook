- [使用docker部署Jenkins及初始配置 | 二丫讲梵 (eryajf.net)](https://wiki.eryajf.net/pages/701.html#_1-先下载jenkins的镜像。)

- [docker容器部署jenkins_程序猿糖豆的博客-CSDN博客_docker 部署jenkins](https://blog.csdn.net/weixin_43872920/article/details/122252709)



## 1 Jenkins安装

### 1.1 制作docker-compose文件

```bash
docker run -d -v /opt/jenkins/jenkins_home:/var/jenkins_home -u 0 -p 10240:8080 -p 10241:50000 --name jenkins jenkins/jenkins:2.327-jdk8 
```

### 1.2 查看初始密码

```bash
docker logs -f jenkins 
Jenkins initial setup is required. An admin user has been created and a password generated.
Please use the following password to proceed to installation:

e04aa41f6e764ea885ce6147a2d363ad

This may also be found at: /var/jenkins_home/secrets/initialAdminPassword
```

## 2 安装插件

> Jenkins本身不提供很多功能，我们可以通过使用插件来满足我们的使用。例如从Gitlab拉取代码，使用
>
> Maven构建项目等功能需要依靠插件完成。接下来演示如何下载插件。

### 2.1 修改`Jenkins`插件下载地址

> Jenkins国外官方插件地址下载速度非常慢，所以可以修改为国内插件地址：
>
> Jenkins->Manage Jenkins->Manage Plugins，点击Available
>
> 这样做是为了把Jenkins官方的插件列表下载到本地，接着修改地址文件，替换为国内插件地址

![image-20211230160844431](https://img-blog.csdnimg.cn/img_convert/7e8d7107e7c78d355f12074f102312a6.png)

#### 2.1.1 进入Jenkins容器修改插件地址

```bash
docker exec -it jenkins /bin/bash
cd /var/jenkins_home/updates
# 下面为单个命令
sed -i 's/http:\/\/updates.jenkinsci.org\/download/https:\/\/mirrors.tuna.tsinghua.edu.cn\/jenkins/g' default.json && sed -i 's/http:\/\/www.google.com/https:\/\/www.baidu.com/g' default.json
```

#### 2.1.2 最后，Manage Plugins点击Advanced，把Update Site改为国内插件下载地址

```bash
https://mirrors.tuna.tsinghua.edu.cn/jenkins/updates/update-center.json
```

![image-20211230162601794](https://img-blog.csdnimg.cn/img_convert/62b39851cae4f398b4af7551a0711426.png)

### 2.2 下载中文汉化插件

> 参考博客：https://www.cnblogs.com/gsxl/p/12129296.html

> Jenkins->Manage Jenkins->Manage Plugins，点击Available，搜索"locale"、Chinese"

![image-20211230164349714](https://img-blog.csdnimg.cn/img_convert/8dff419704877b33a5e34684cf2a034a.png)

![image-20211230162847063](https://img-blog.csdnimg.cn/img_convert/37ac9168d3250b3be9cf495ce6e7df4c.png)

> 下载完成后点击重启

![image-20211230163132861](https://img-blog.csdnimg.cn/img_convert/1544ecc2c876190cbd5265c7933b4164.png)

> 重启后打开Manage Jenkins --> Configure System，找到 Locale勾选并且输入：`zh_cn`，保存

![image-20211230164720132](https://img-blog.csdnimg.cn/img_convert/40fafe0ac73aeceb9a3c22ad7a63da6f.png)

### 2.3 Jenkins凭证管理

> 凭据可以用来存储需要密文保护的数据库密码、Gitlab密码信息、Docker私有仓库密码等，以便
>
> Jenkins可以和这些第三方的应用进行交互。

#### 2.3.1 安装Credentials Binding插件

> 要在Jenkins使用凭证管理功能，需要安装Credentials Binding插件，安装插件后，点击系统管理，多了"凭证"菜单，在这里管理所有凭证

![image-20211230170120432](https://img-blog.csdnimg.cn/img_convert/4557dca494d2220dea386e33fe5f8e1a.png)

> 可以添加的凭证有5种：

![image-20211230170226267](https://img-blog.csdnimg.cn/img_convert/5e0df8628a86a45ba7f0eecdcfaf4b8f.png)

> - Username with password：用户名和密码
> - SSH Username with private key： 使用SSH用户和密钥
> - Secret fifile：需要保密的文本文件，使用时Jenkins会将文件复制到一个临时目录中，再将文件路径
>
> 设置到一个变量中，等构建结束后，所复制的Secret fifile就会被删除。
>
> - Secret text：需要保存的一个加密的文本串，如钉钉机器人或Github的api token
> - Certifificate：通过上传证书文件的方式
>
> 常用的凭证类型有：`Username with password（用户密码）`和`SSH Username with private key（SSH 密钥）`