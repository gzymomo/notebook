# 1、K8S集群安全机制

访问k8S集群的时候，需要经过三个步骤完成具体操作。

1. 认证
2. 鉴权（授权）
3. 准入控制



进行访问的时候，过程中都需要经过apiserver，apiserver做统一协调，比如门卫。

访问过程中需要证书、token、或者用户名+密码。

如果访问pod，需要serviceAccount。



## 1.1 认证

传输安全：对外不暴露8080端口，只能内部访问，对外使用端口6443。



认证方式：

- 客户端身份认证常用方式
  - https证书认证，基于ca证书
  - http token认证，通过token识别用户
  - http基本认证：用户名+密码认证



## 1.2 鉴权（授权）

- 基于RBAC进行鉴权操作
- 基于角色访问控制



### 1.2.1 RBAC基于角色的访问控制

角色：

- role：特定命名空间访问权限
- ClusterRole：所有命名空间访问权限



角色绑定：

- roleBinding：角色绑定到主体
- ClusterRoleBinding：集群角色绑定到主体



主体：

- user：用户
- group：用户组
- serviceAccount：服务账号



### 1.2.2 RBAC实现鉴权

1. 创建命名空间

```bash
kubectl create ns roledemo
```

2. 在新创建的命名空间创建pod

```bash
kubectl run nginx --image=nginx -n roledemo
```

3. 创建角色

rbac-role.yaml 

```yaml
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadta:
  namespace: roledemo
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
```



```bash
# 创建角色
kubectl apply -f rbac-role.yaml
# 查看角色
kubectl get role -n roledemo
```

4. 创建角色绑定

rbac-rolebinding.yaml

```yaml
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadta:
  name: pod-reader
  namespace: roledemo
subjects:
- kind: User
  name: lucy
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

```bash
# 创建角色绑定
kubectl apply -f rbac-rolebinding.yaml
# 查看角色绑定
kubectl get role,rolebinding -n roledemo
```

5. 使用证书识别身份













## 1.3 准入控制

- 准入控制器的列表，如果列表有请求内容，通过，没有拒绝。