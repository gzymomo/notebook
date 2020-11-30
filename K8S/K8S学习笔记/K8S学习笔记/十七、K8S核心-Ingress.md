# 1、Ingress

Ingress不是Kubernetes内置的，需要单独安装应用，来做负载均衡。



将端口号对外暴露，通过IP+端口号进行访问。

- 使用Service里面的NodePort可以实现。



NodePort缺陷：

- 在每个节点上都会起到端口，在访问时候通过任何节点，通过节点ip+暴露端口号实现访问。
- 意味着每个端口只能使用一次，一个端口对应一个应用。
- 实际访问中都是用域名，根据不同域名跳转到不同端口服务中。



## 1.1 Ingress和Pod关系

- pod和ingress通过service关联的
  - ingress作为统一入口，由service关联一组pod



![](..\img\ingress.png)



## 1.2 Ingress工作流程

![](..\img\ingress1.png)



## 1.3 使用ingress步骤

1. 部署ingress controller（选择官方nginx控制器，实现部署） 

```bash

```



2. 创建ingress规则

```bash

```



## 1.4 使用ingress对外暴露应用

1. 创建nginx应用，对外暴露端口使用NodePort

```bash
# 创建pod
kubectl create deployment web --image=nginx

# 查看
kubectl get pods

# 创建service
kubectl expose deployment web --port=80 --target-port=80 --type=NodePort
```

2. 部署ingress controller

```bash
kubectl apply -f ingress-con.yaml

# 查看ingress controller状态
kubectl get pods -n ingress-nginx
```

3. 创建ingress规则

```yaml
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
meatadata:
  name: example-ingress
spec:
  rules:
  - host: example.ingredemo.com
    http:
      paths:
      - path: /
        backend:
          serviceName: web
          servicePort: 80
```



保存后，然后执行

```bash
# 创建ingress规则
kubectl applf -f ingress-http.yaml
```



查看在那个节点：

```bash
kubectl get pods -n ingress-nginx -o wide
```



