- [k8s env、configmap、secret外部数据加载配置](https://www.cnblogs.com/qsing/p/15773745.html)

K8s提供了多种外部数据注入容器的方式，今天我们主要学习环境变量、ConfigMap以及Secret的使用和配置。

## 环境变量

在docker项目中，对一个容器添加环境变量可以在容器创建时通过`-e ENV=name`方式加载。而k8s在创建 Pod 时，也提供了其下容器环境变量配置的能力。

我们可以通过配置清单中的 `env` 及 `envFrom（来自外部配置）` 字段来设置环境变量。

比如如下的yaml

```yaml
#busybox-deployment.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: busybox-deployment
spec:
  selector:
    matchLabels:
      app: busybox
  replicas: 1
  template:
    metadata:
      labels:
        app: busybox
    spec:
      containers:
      - name: busybox
        image: busybox:latest
        resources:
          limits:
            memory: 20Mi
        env:
        - name: DEMO_VERSION
          value: demov1
        - name: DEMO_POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: DEMO_CONT_MEM
          valueFrom:
            resourceFieldRef:
              containerName: busybox
              resource: limits.memory
        command: ['top']
```

在清单中我们配置了三个环境变量：

- `DEMO_VERSION`:直接添加变量值`demov1`
- `DEMO_POD_NAME`:结合valueFrom中fieldRef获取pod名称字段`metadata.name`
- `DEMO_CONT_MEM`:结合valueFrom中resourceFieldRef获取容器资源字段`limits.memory`

此时我们创建pod进入容器后通过printenv命令可以查看到环境变量已经被加载：

```shell
#kubectl exec busybox-deployment-5bb768546c-jbsmz -- printenv

DEMO_POD_NAME=busybox-deployment-5bb768546c-jbsmz
DEMO_CONT_MEM=20971520
    DEMO_VERSION=demov1
```

`valueFrom`中其他字段如下待会我们会用到，需要时可参考官方API文档：[envvar-v1-core](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.23/#envvar-v1-core)

![image-20220105234011959](https://markdown-1257692304.cos.ap-nanjing.myqcloud.com/markdown_img/image-20220105234011959.png)注意： 环境变量将覆盖容器镜像中指定的所有环境变量。

## ConfigMap

------

> ConfigMap 是一种 API 对象，用来将非机密性的数据保存到键值对中。使用时， Pods可以将其用作环境变量、命令行参数或者存储卷中的配置文件。

### 1、用于环境变量

Configmap 用于配置环境变量的好处是可以将环境配置信息和容器镜像解耦，便于应用配置的修改。

我们可以快速的创建出一个configmap如下：

```yaml
#busybox-configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: busybox-configmap
data:
  DEMO_VERSION: "demov2"
```

configmap使用 `data`（UTF-8字节序列） 和 `binaryData`（二进制数据base64 编码的字串） 字段创建键值对做数据存储。

接着使用调整我们deployment中的`env`DEMO_VERSION的字段如下：

```yaml
- name: DEMO_VERSION
  valueFrom:
    configMapKeyRef:
      name: busybox-configmap
      key: DEMO_VERSION
```

`configMapKeyRef`如API所说的选择一个configmap

同样创建后查看

```shell
# kubectl exec pod/busybox-deployment-64c678977f-zjnhb -- printenv

DEMO_VERSION=demov2
...
```

这样我们只需要维护这个configmap即可，不过通过环境变量引用configmap时也是不支持热更新，环境变量只在容器创建时加载，所以你需要触发一次deployment的滚动更新。

### 2、挂载配置信息

显然从名字上可以看出configmap并不是为环境变量而生。我们可以将configmap中key作文文件挂载到容器中，我们创建如下清单：

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: busybox-configmap
data:
  DEMO_VERSION: "demov3"

  game.properties: |
    enemies=aliens
    lives=3
    enemies.cheat=true
    enemies.cheat.level=noGoodRotten
    secret.code.passphrase=UUDDLRLRBABAS
    secret.code.allowed=true
    secret.code.lives=30
  ui.properties: |
    color.good=purple
    color.bad=yellow
    allow.textmode=true
    how.nice.to.look=fairlyNice
```

相当于此时我们获得三个key文件，接下来我们就可以通过volume挂载了。

```yaml
...
volumeMounts:
- name: config-volume
  mountPath: /etc/config
volumes:
- name: config-volume
  configMap:
    name: busybox-configmap
...
```

在volume中configmap字段指定我们的busybox-configmap，创建后查看/etc/config

```shell
$ kubectl exec busybox-deployment-87b6c7bd7-ljcfr --  ls /etc/config/
DEMO_VERSION
game.properties
ui.properties
```

当卷中使用的 ConfigMap 被更新时，所投射的键最终也会被更新。 kubelet 组件会在每次周期性同步时检查所挂载的 ConfigMap 是否为最新。即k8s的watch机制。

## Secret

------

与ConfigMap类似，k8s提供了另一种API对象Secret用于存储机密信息，我们可以使用Secret对象存储敏感信息例如密码、令牌或密钥，这样在应用程序代码中解耦机密数据。

创建一个Sercet

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: mysecret
type: Opaque
data:
  password: cGFzc3dk
stringData:
  username: k8s
```

`data` 字段用来存储 base64 编码的任意数据，我们可以通过base64命令生成编码。

`stringData`则允许 Secret 使用未编码的字符串，只用于写，无法直接读取明文字段。

```shell
$ kubectl get secret mysecret -o yaml
apiVersion: v1
data:
  password: cGFzc3dk
  username: azhz
...
$ kubectl describe secret mysecret
...
Data
====
password:  6 bytes
username:  3 bytes
```

这样在`kubectl get` 和 `kubectl describe` 中默认不显示 `Secret` 的内容。 这是为了防止 `Secret` 意外地暴露给旁观者或者保存在终端日志中。

> Kubernetes 提供若干种内置的Secret类型，用于一些常见的使用场景。 针对这些类型，Kubernetes 所执行的合法性检查操作以及对其所实施的限制各不相同。

| 内置类型                              | 用法                                     |
| ------------------------------------- | ---------------------------------------- |
| `Opaque`                              | 用户定义的任意数据                       |
| `kubernetes.io/service-account-token` | 服务账号令牌                             |
| `kubernetes.io/dockercfg`             | `~/.dockercfg` 文件的序列化形式          |
| `kubernetes.io/dockerconfigjson`      | `~/.docker/config.json` 文件的序列化形式 |
| `kubernetes.io/basic-auth`            | 用于基本身份认证的凭据                   |
| `kubernetes.io/ssh-auth`              | 用于 SSH 身份认证的凭据                  |
| `kubernetes.io/tls`                   | 用于 TLS 客户端或者服务器端的数据        |
| `bootstrap.kubernetes.io/token`       | 启动引导令牌数据                         |

类型说明可参考官方文档：[secret](https://kubernetes.io/zh/docs/concepts/configuration/secret/)，当然也可以通过`Opaque`自定义的实现内置类型。

这里我们以类型`kubernetes.io/ssh-auth`为例尝试使用Secret,`kubernetes.io/ssh-auth` 用来存放 SSH 身份认证中 所需要的凭据。使用这种 Secret 类型时，我们必须在其 `data` （或 `stringData`） 字段中提供一个 `ssh-privatekey` 键值对，作为要使用的 SSH 凭据。

创建如下的yaml：

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: secret-ssh-auth
type: kubernetes.io/ssh-auth
data:
  ssh-privatekey: |
          PRIVATEKEY_STINGS..  #base64编码数据
```

创建后可以查看到类型和key名称。

```shell
$ kubectl describe secret/secret-ssh-auth
Name:         secret-ssh-auth
Namespace:    default
Labels:       <none>
Annotations:  <none>

Type:  kubernetes.io/ssh-auth

Data
====
ssh-privatekey:  2626 bytes
```

接着创建用于加载secret的pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-secret
spec:
  containers:
  - name: pod-secret
    image: nginx
    volumeMounts:
    - name: secret-volume
      mountPath: "/etc/ssh/"
      readOnly: true
  volumes:
  - name: secret-volume
    secret:
      secretName: secret-ssh-auth
```

此时容器中已加载到secretName中的`ssh-privatekey`项

```shell
$ kubectl exec pod/pod-secret --  ls /etc/ssh
ssh-privatekey
```

这样我们可以通过此key来做ssh相关的认证。

和configmap一样，secret也可用于环境变量配置。通过secretRef字段引入secret

```yaml
...
envFrom:
- secretRef:
    name: mysecret
...
```

*以上secret使用仅做学习，生产中请排查以下安全问题，更多secret内容参考官方文档：[Secret](https://kubernetes.io/zh/docs/concepts/configuration/secret/)*

**安全问题：**

- **当部署与 Secret API 交互的应用程序时，应使用 鉴权策略， 例如 RBAC，来限制访问。**
- **API 服务器上的 Secret 数据以纯文本的方式存储在 etcd 中**，因此：
  - 管理员应该为集群数据开启[静态加密](https://kubernetes.io/zh/docs/tasks/administer-cluster/encrypt-data/)（要求 v1.13 或者更高版本）。
  - 管理员应该限制只有 admin 用户能访问 etcd；
  - API 服务器中的 Secret 数据位于 etcd 使用的磁盘上,不再使用secret应该被删除。
  - 如果 etcd 运行在集群内，管理员应该确保 etcd 之间的通信使用 SSL/TLS 进行加密。
- **如果将 Secret 数据编码为 base64 的清单（JSON 或 YAML）文件，共享该文件或将其检入代码库，该密码将会被泄露。 Base64 编码不是一种加密方式，应该视同纯文本。**
- **应用程序在从卷中读取 Secret 后仍然需要保护 Secret 的值，例如不会意外将其写入日志或发送给不信任方。**
- **可以创建使用 Secret 的 Pod 的用户也可以看到该 Secret 的值。即使 API 服务器策略不允许用户读取 Secret 对象，用户也可以运行 Pod 导致 Secret 暴露。**