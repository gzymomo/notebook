# 1. Service

- 定义一组pod的访问规则



## 1.1 service存在意义

- 防止pod失联（服务发现）

![](..\img\pod.png)



- 定义一组Pod访问策略（负载均衡）

![](..\img\service.png)

## 1.2 Pod和Service关系

- 根据label和selector标签建立关联的

- 通过serivice实现Pod的负载均衡

![](..\img\podservice.png)

## 1.3 常用Service类型

### ClusterIP（默认）

- 集群内部使用

### NodePort

- 对外访问应用使用，对外暴露，访问端口

### LoadBalancer

- 对外访问应用使用，公有云



node内网部署应用，外网一般不能访问。

- 找到一台可以进行外网访问机器，安装nginx，反向代理
- 手动把可以访问节点添加到nginx里面



LoadBalancer：公有云，负载均衡，控制器