- [Argo 安装和 workflow 实例配置文件解析 ](https://www.cnblogs.com/l-hh/p/15876996.html)

# 一、Argo 安装配置

## 1.1 Argo 安装

```bash
$ kubectl create ns argo
$ kubectl apply -n argo -f https://raw.githubusercontent.com/argoproj/argo-workflows/master/manifests/quick-start-postgres.yaml
$ kubectl get all -n argo
```

![image-20220209215125019](https://s2.loli.net/2022/02/09/U6aWuYGQIX78T4i.png)

## 1.2 修改 Argo 服务对外访问

```bash
$ kubectl edit svc argo-server -n argo
...
  selector:
    app: argo-server
  sessionAffinity: None
  type: NodePort   # 修改为 NodePort
status:
...
```

> 保存退出跟 vim 操作一样，成功退出后等待即可。

## 1.3 Web 访问 Argo

```bash
[root@k8s-master01 ~]# kubectl get svc -n argo
NAME                                  TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
service/argo-server                   NodePort    10.233.11.72    <none>        2746:31335/TCP   23h
...
```

![image-20220208092758566](https://s2.loli.net/2022/02/08/WrlDsx6eMvhmcdu.png)

## 1.4 Linux 安装 Argo CLI

```bash
$ curl -sLO https://github.com/argoproj/argo/releases/download/v3.0.2/argo-linux-amd64.gz
$ gunzip argo-linux-amd64.gz
$ chmod +x argo-linux-amd64
$ mv ./argo-linux-amd64 /usr/local/bin/argo
$ argo version
```

其他版本链接：https://github.com/argoproj/argo-workflows/releases

## 1.5 注意小坑

在构建工作流的时候，需要指定命名空间`-n argo`，否则会像我这样一直构建不成功，Argo UI界面上也看不到工作流。

```bash
[root@k8s-master01 argo]# argo submit hello-world.yaml 
Name:                hello-world-tfhcm
Namespace:           default
ServiceAccount:      default
Status:              Pending
Created:             Thu Feb 10 10:16:46 +0800 (now)
Progress:            
[root@k8s-master01 argo]# argo list
NAME                STATUS    AGE   DURATION   PRIORITY
hello-world-tfhcm   Pending   5s    0s         0
[root@k8s-master01 argo]#
```

Argo UI 界面上查看并没有刚刚创建的工作流

![image-20220210101747295](https://s2.loli.net/2022/02/10/x58TRCQoaOA4293.png)

# 二、官方工作流实例

## 2.1 hello-world 实例

构建工作流

```bash
[root@k8s-master01 argo]# argo submit -n argo --watch https://raw.githubusercontent.com/argoproj/argo-workflows/master/examples/hello-world.yaml
# -n argo 指定命名空间
```

`hello-world.yaml`配置文件解析

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: hello-world-   # workflow 名字
  labels:         # 标签
    workflows.argoproj.io/archive-strategy: "false"
  annotations:    # 为用户添加的额外注解
    workflows.argoproj.io/description: |
      This is a simple hello world example.
      You can also run it in Python: https://couler-proj.github.io/couler/examples/#hello-world
spec:
  entrypoint: whalesay   # 表示第一个执行的模板名称，让工作流知道从哪个模板开始执行，类似于 main 函数
  templates:             # 以下是模板内容
  - name: whalesay       # 模板名称
    container:           # 容器内容
      image: docker/whalesay:latest   # 调用 docker/whalesay 镜像
      command: [cowsay]               # 调用 cowsay 命令
      args: ["hello world"]           # 执行内容
```

Pod 初始化

![image-20220209092639408](https://s2.loli.net/2022/02/09/ndIeBLFlx4C3th2.png)

工作流完成

![image-20220209092750882](https://s2.loli.net/2022/02/09/KHBrd6imFWok1Aw.png)

查看 Pod Logs

```bash
[root@k8s-master01 argo]# argo logs -n argo @latest
# @latest  查看最新工作流log
```

![image-20220209092837250](https://s2.loli.net/2022/02/09/dAnXUsLQrwYyqzC.png)

Argo UI 也可以同步查看 Pod 运行信息

![image-20220209093009412](https://s2.loli.net/2022/02/09/n1s4a3ritNCwDA5.png)

![image-20220209093035693](https://s2.loli.net/2022/02/09/Tny5AMrRoeIh3Gl.png)

## 2.2 Steps 类型的 workflow

接下来练习稍微复杂点的 Workflow，`hello-hello-hello.yml`配置文件解析

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: steps-          # Workflow 的名称前缀
spec:
  entrypoint: hello-hello-hello # 表示第一个执行的模板名称，让工作流知道从哪个模板开始执行，类似于 main 函数

  # 该templates中有两个模板，分别是：hello-hello-hello和whalesay
  templates:
  - name: hello-hello-hello     # 第一个模板 hello-hello-hello 
    steps:                      # template 的类型是 steps
    # 一个 template 有多种类型，分别为：container、script、dag、steps、resource、suspend
    - - name: hello1            # 在 steps 类型中，[--] 表示顺序执行，[-] 表示并行执行
        template: whalesay      # 引用 whalesay 模板
        arguments:              # 传递给函数的参数
          parameters:           # 声明参数
          - name: message       # Key
            value: "hello1"     # value
    - - name: hello2a           # [--] 顺序执行
        template: whalesay
        arguments:
          parameters:
          - name: message
            value: "hello2a"
      - name: hello2b           # [-] 表示跟上一步并行运行
        template: whalesay
        arguments:
          parameters:
          - name: message
            value: "hello2b"

  - name: whalesay   # 第二个模板 whalesay 
    inputs:          # input、output 实现数据交互
      parameters:
      - name: message
    container:
      image: docker/whalesay  # 镜像名称
      command: [cowsay]       # 执行命令
      args: ["{{inputs.parameters.message}}"]  # 参数引用
```

构建 workflow

```bash
[root@k8s-master01 argo]# ls
hello-hello-hello.yml  hello-world.yaml
[root@k8s-master01 argo]# argo submit -n argo hello-hello-hello.yml --watch
# submit    创建工作流
# -n argo   存放的命名空间
# --watch   实时监听工作流
```

![QQ截图20220209211252](https://s2.loli.net/2022/02/09/aXr1c7SG3kzhNZL.png)

在 Argo Web 界面查看，此时工作流正在构建中

![QQ截图20220209211242](https://s2.loli.net/2022/02/09/RzJC6BsOiTknt1Z.png)

第一个 hello 已经执行完成，并打印相应的信息

![QQ截图20220209211312](https://s2.loli.net/2022/02/09/SC8bwjlI6F4ikpu.png)

![image-20220209214213293](https://s2.loli.net/2022/02/09/y3PN7CYdxLJa2pI.png)

第一个完成之后，接下来 hello2a 和 hello2b 会并行执行

![image-20220209214434447](https://s2.loli.net/2022/02/09/BhOi5eXKTGCqZVl.png)

hello2a 和 hello2b 都会打印相关信息，然后结束整个`workflow`

![image-20220209214658209](https://s2.loli.net/2022/02/09/GyQTeuVStLUlPcJ.png)

以上非常基础的 Argo Workflow 学习，中文资料非常少，连门都没入。