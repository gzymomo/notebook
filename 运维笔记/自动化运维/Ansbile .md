[TOC]

Ansible功能：

- 系统环境配置
- 安装软件
- 持续集成
- 热回滚

Ansible优点：

- 无客户端
- 推送式
- 丰富的module
- 基于YAML的Playbook

Ansible缺点：

- 效率低，易挂起
- 并发性能差

![](https://www.showdoc.cc/server/api/attachment/visitfile/sign/e3ea61febfacac34f835a93d640f2834?showdoc=.jpg)

Ansiblle框架由以下核心的组件组成：

1. ansible core： 它是Ansible本身的核心模块
2. host inventory： 它是一个主机库，需要管理的主机列表
3. connection plugins： 连接插件，默认采取SSH远程通信协议
4. custom modules： Ansible自定义扩展模块
5. playbook：编排（剧本），按照所设定编排的顺序执行完成安排的任务