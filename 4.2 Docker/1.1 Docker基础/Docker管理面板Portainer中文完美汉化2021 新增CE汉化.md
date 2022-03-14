- [Docker管理面板Portainer中文完美汉化2021 新增CE汉化 - 我不是矿神 (imnks.com)](https://imnks.com/3406.html)

Portainer是一个可视化的容器镜像的图形管理工具，利用Portainer可以轻松构建，管理和维护Docker环境。 而且完全免费，基于容器化的安装方式，方便高效部署。

## Portainer面板汉化 完成率99%

本Portainer面板汉化文件来源于[CecOS CaaS容器云平台，版本:2.21.0](https://hub.docker.com/r/openfans/cecos-caas)：开源GPL 2.0协议

本站修改，测试Portainer 1.24.2使用OK，不支持Portainer CE，老、旧、弱、arm等机子建议用这个

https://github.com/tbc0309/Portainer-CN2021

❤本地下载：[Portainer-CN2021-IMNKS.COM-1018.zip](https://imnks.com/usr/uploads/2021/10/Portainer-CN2021-IMNKS.COM-1018.zip)

## Portainer CE汉化 12月13日更新

汉化作者：ysp QQ：360354879，基于CE更新汉化。工作量居大，感谢作者的辛苦奉献。

https://hub.docker.com/r/6053537/portainer-ce

https://github.com/eysp/public

❤本地下载：[portainer-ce-2.9.3-public-cn-20211213.zip](https://imnks.com/usr/uploads/2022/02/portainer-ce-2.9.3-public-cn-20211213.zip)

## 使用教程

### Portainer 1.24.2版本

1、下载汉化文件，解压出public文件夹 2、文件夹传输至系统root目录 3、然后按需执行以下命令
x86-64系统使用

```
docker volume create portainer_data
docker run -d -p 9000:9000 --name portainer --restart always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data -v /root/public:/public portainer/portainer
```

ARM64系统使用

```
docker volume create portainer_data
docker run -d -p 9000:9000 --name portainer --restart always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data -v /root/public:/public portainer/portainer:linux-arm64
```

### Portainer CE版本

同上，最后是portainer/portainer-ce 或 portainer/portainer-ce:linux-arm64

## Portainer界面汉化截图

![4135296828.png](https://imnks.com/usr/uploads/2021/10/4135296828.png!up)

![3602819321.png](https://imnks.com/usr/uploads/2021/10/3602819321.png!up)

![2826409171.png](https://imnks.com/usr/uploads/2021/10/2826409171.png!up)

![1170529225.png](https://imnks.com/usr/uploads/2021/10/1170529225.png!up)

## Portainer CE界面汉化截图

![1129379842.png](https://imnks.com/usr/uploads/2021/10/1129379842.png!up)

![4255986373.png](https://imnks.com/usr/uploads/2021/10/4255986373.png!up)