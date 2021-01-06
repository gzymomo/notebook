[TOC]
# 查看防火墙服务
```shell
$ systemctl list-unit-files | grep firewalld
firewalld.service                             enabled
```
# 启用防火墙服务(开机启动)：
```shell
systemctl enable firewalld.service
```
# 禁用防火墙服务：
```shell
systemctl disable firewalld.service
```
# 查看防火墙运行状态
```shell
$ firewall-cmd --state
running
```
# 打开防火墙:
```shell
systemctl start firewalld.service
```
# 关闭防火墙:
```shell
systemctl stop firewalld.service
```