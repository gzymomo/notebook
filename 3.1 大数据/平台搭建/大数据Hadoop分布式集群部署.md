- [大数据Hadoop分布式集群部署（详细版）_arnoldmp的博客-CSDN博客_分布式集群部署](https://blog.csdn.net/arnoldmapo/article/details/105230452)

# 一、 搭建思路

## 1. 软件版本

本文介绍大数据平台Hadoop的分布式环境搭建，为保证大家都可以在自己的电脑上使用，我们选取在VMware Workstation Pro 12.0以上版本的虚拟机上部署5台CentOS-7系统模拟5台服务器。

Java jdk环境采用jdk-1.8以上版本，Hadoop采用hadoop-2.8.3版本

## 2. 节点地址规划

下表为地址规划表，地址规划以及与主机名的映射关系如下表所示：master1地址为192.168.150.101；master2地址为192.168.150.102；slave1地址为192.168.150.103；slave2地址为192.168.150.104；slave3地址为192.168.150.105。

| 序号 | 主机名  | IP地址          | 掩码          | 网关          | DNS     |
| ---- | ------- | --------------- | ------------- | ------------- | ------- |
| 1    | master1 | 192.168.150.101 | 255.255.255.0 | 192.168.150.2 | 8.8.8.8 |
| 2    | master2 | 192.168.150.102 | 255.255.255.0 | 192.168.150.2 | 8.8.8.8 |
| 3    | slave1  | 192.168.150.103 | 255.255.255.0 | 192.168.150.2 | 8.8.8.8 |
| 4    | slave2  | 192.168.150.104 | 255.255.255.0 | 192.168.150.2 | 8.8.8.8 |
| 5    | slave3  | 192.168.150.105 | 255.255.255.0 | 192.168.150.2 | 8.8.8.8 |

## 3. 每节点资源规划

每台主机的资源配置如下表，后期也可以根据需要动态调整资源(vCPU的资源可以大于物理CPU 2倍左右，比如你的电脑只有4核，可以虚出8 vcpu)

| 序号 | 主机名  | IP地址          | 内存 | cpu  | 硬盘 |
| ---- | ------- | --------------- | ---- | ---- | ---- |
| 1    | master1 | 192.168.150.101 | 2G   | 1    | 100  |
| 2    | master2 | 192.168.150.102 | 2G   | 1    | 100  |
| 3    | slave1  | 192.168.150.103 | 1G   | 1    | 100  |
| 4    | slave2  | 192.168.150.104 | 1G   | 1    | 100  |
| 5    | slave3  | 192.168.150.105 | 1G   | 1    | 100  |

## 4. 系统账号和密码

| 序号 | 主机名  | IP地址          | 管理账号/密码                             | 普通用户/密码                                 |
| ---- | ------- | --------------- | ----------------------------------------- | --------------------------------------------- |
| 1    | master1 | 192.168.150.101 | [root/huawei@123](mailto:root/huawei@123) | [hadoop/huawei@123](mailto:hadoop/huawei@123) |
| 2    | master2 | 192.168.150.102 | [root/huawei@123](mailto:root/huawei@123) | [hadoop/huawei@123](mailto:hadoop/huawei@123) |
| 3    | slave1  | 192.168.150.103 | [root/huawei@123](mailto:root/huawei@123) | [hadoop/huawei@123](mailto:hadoop/huawei@123) |
| 4    | slave2  | 192.168.150.104 | [root/huawei@123](mailto:root/huawei@123) | [hadoop/huawei@123](mailto:hadoop/huawei@123) |
| 5    | slave3  | 192.168.150.105 | [root/huawei@123](mailto:root/huawei@123) | [hadoop/huawei@123](mailto:hadoop/huawei@123) |

## 5. 节点功能规划

以下为Hadoop节点的部署图，将NameNode部署在master1，SecondaryNameNode部署在master2，slave1、slave2、slave3中分别部署一个DataNode节点。

| 序号 | 主机名  | IP地址          | Namenode | Secondnamenode | Datanode |
| ---- | ------- | --------------- | -------- | -------------- | -------- |
| 1    | master1 | 192.168.150.101 | Y        |                |          |
| 2    | master2 | 192.168.150.102 |          | Y              |          |
| 3    | slave1  | 192.168.150.103 |          |                | Y        |
| 4    | slave2  | 192.168.150.104 |          |                | Y        |
| 5    | slave3  | 192.168.150.105 |          |                | Y        |

## 6. 节点文件目录规划

| 序号 | 主机名  | IP地址          | 软件存放目录  | 软件安装目录 | 文件测试目录 |
| ---- | ------- | --------------- | ------------- | ------------ | ------------ |
| 1    | master1 | 192.168.150.101 | /opt/software | /opt/hadoop  | /opt/test    |
| 2    | master2 | 192.168.150.102 | /opt/software | /opt/hadoop  | /opt/test    |
| 3    | slave1  | 192.168.150.103 | /opt/software | /opt/hadoop  | /opt/test    |
| 4    | slave2  | 192.168.150.104 | /opt/software | /opt/hadoop  | /opt/test    |
| 5    | slave3  | 192.168.150.105 | /opt/software | /opt/hadoop  | /opt/test    |

