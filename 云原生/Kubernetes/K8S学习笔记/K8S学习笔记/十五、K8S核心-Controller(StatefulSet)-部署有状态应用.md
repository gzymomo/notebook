Controller（StatefulSet）-部署有状态应用



# 无状态和有状态区别

## 无状态

- 认为Pod都是一样的
- 没有顺序要求
- 不用考虑在哪个node运行
- 随意进行伸缩和扩展



## 有状态

- 无状态中所有内容都需考虑到
- 让每个Pod独立的，保持Pod启动顺序和唯一性（唯一网络标识符，持久存储区分的）
  - 有序，比如mysql主从



# 部署有状态应用

## 无头service

- ClusterIP：none

首先得有一个无头的Service，即ClusterIP:none

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx
  labels: 
    app: nginx
spec:
  ports:
  - port: 80
    name: web
  clusterIP: None
  selector:
    app: nginx
```



1. SatefulSet部署有状态应用

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx
  labels: 
    app: nginx
spec:
  ports:
  - port: 80
    name: web
  clusterIP: None
  selector:
    app: nginx
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: nginx-statefulset
  ..........
```



2. 部署应用

```bash
# 部署应用
kubectl applf -f sts.yaml

# 查看
kubectl get pods
```

3. 查看pod，每个都是唯一名称

![](..\..\img\pods.png)

4. 查看创建无头的service

```bash
kubectl get svc
```

![](..\..\img\service1.png)



# deployment和statefulset区别

- 有身份的（唯一标识的）
- 根据主机名+按照一定规则生成域名
- 每个pod有唯一主机名
- 唯一域名：
  - 格式：主机名称.service名称.名称空间.svc.cluster.local



