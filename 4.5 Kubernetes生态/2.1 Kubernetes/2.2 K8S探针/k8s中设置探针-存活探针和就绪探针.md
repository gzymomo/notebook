- [k8s中设置探针-存活探针和就绪探针](https://www.cnblogs.com/sanduzxcvbnm/p/14710189.html)

# 基础概念

探针 是由 kubelet 对容器执行的定期诊断。

针对运行中的容器，kubelet 可以选择是否执行以下三种探针，以及如何针对探测结果作出反应：

- livenessProbe：指示容器是否正在运行。如果存活态探测失败，则 kubelet 会杀死容器， 并且容器将根据其重启策略决定未来。如果容器不提供存活探针， 则默认状态为 Success。
- readinessProbe：指示容器是否准备好为请求提供服务。如果就绪态探测失败， 端点控制器将从与 Pod  匹配的所有服务的端点列表中删除该 Pod 的 IP 地址。 初始延迟之前的就绪态的状态值默认为 Failure。  如果容器不提供就绪态探针，则默认状态为 Success。
- startupProbe: 指示容器中的应用是否已经启动。如果提供了启动探针，则所有其他探针都会被  禁用，直到此探针成功为止。如果启动探测失败，kubelet 将杀死容器，而容器依其 重启策略进行重启。 如果容器没有提供启动探测，则默认状态为  Success。

要执行诊断，kubelet 调用由容器实现的 Handler （处理程序）。有三种类型的处理程序：

- ExecAction： 在容器内执行指定命令。如果命令退出时返回码为 0 则认为诊断成功。
- TCPSocketAction： 对容器的 IP 地址上的指定端口执行 TCP 检查。如果端口打开，则诊断被认为是成功的。
- HTTPGetAction： 对容器的 IP 地址上指定端口和路径执行 HTTP Get 请求。如果响应的状态码大于等于 200 且小于 400，则诊断被认为是成功的。

![img](https://img2020.cnblogs.com/blog/794174/202104/794174-20210427180205714-327976565.png)

每次探测都将获得以下三种结果之一：

- Success（成功）：容器通过了诊断。
- Failure（失败）：容器未通过诊断。
- Unknown（未知）：诊断失败，因此不会采取任何行动。

# 常见配置

Probe 中有很多精确和详细的配置，通过它们您能准确的控制 liveness 和 readiness 检查：

- initialDelaySeconds：容器启动后第一次执行探测是需要等待多少秒。
- periodSeconds：执行探测的频率。默认是10秒，最小1秒。
- timeoutSeconds：探测超时时间。默认1秒，最小1秒。
- successThreshold：探测失败后，最少连续探测成功多少次才被认定为成功。默认是 1。对于 liveness 必须是 1。最小值是 1。
- failureThreshold：探测成功后，最少连续探测失败多少次才被认定为失败。默认是 3。最小值是 1。

HTTP probe 中可以给 httpGet设置其他配置项：

- host：连接的主机名，默认连接到 pod 的 IP。您可能想在 http header 中设置 “Host” 而不是使用 IP。
- scheme：连接使用的 schema，默认HTTP。
- path: 访问的HTTP server 的 path。
- httpHeaders：自定义请求的 header。HTTP运行重复的 header。
- port：访问的容器的端口名字或者端口号。端口号必须介于 1 和 65525 之间。

对于 HTTP 探测器，kubelet 向指定的路径和端口发送 HTTP 请求以执行检查。 Kubelet 将 probe 发送到容器的  IP 地址，除非地址被httpGet中的可选host字段覆盖。 在大多数情况下，您不想设置主机字段。 有一种情况下您可以设置它。  假设容器在127.0.0.1上侦听，并且 Pod 的hostNetwork字段为 true。  然后，在httpGet下的host应该设置为127.0.0.1。 如果您的 pod  依赖于虚拟主机，这可能是更常见的情况，您不应该是用host，而是应该在httpHeaders中设置Host头。

# 示例

> 官网例子中提供的镜像是k8s.gcr.io/busybox，在国内拉取不了，需要换成地址，具体看这篇文章：https://www.cnblogs.com/saolv/p/12996115.html

> 或者换成其他镜像进行测试，比如下方说的nginx镜像

> 测试的话可以把镜像换成nginx,探测80端口，等pod起来后，登录进容器，手动修改nginx使用的80端口，然后重启nginx服务，从而触发有关探针，进而实现pod重启

## liveness ExecAction

以下是 Pod 的配置文件 exec-liveness.yaml：

```
apiVersion: v1
kind: Pod
metadata:
  labels:
    test: liveness
  name: liveness-exec
spec:
  containers:
  - name: liveness
    image: k8s.gcr.io/busybox
    args:
    - /bin/sh
    - -c
    - touch /tmp/healthy; sleep 30; rm -rf /tmp/healthy; sleep 600
    livenessProbe:
      exec:
        command:
        - cat
        - /tmp/healthy
      initialDelaySeconds: 5
      periodSeconds: 5
```

该配置文件给 Pod 配置了一个容器。periodSeconds 规定 kubelet 要每隔5秒执行一次 liveness probe。 initialDelaySeconds 告诉 kubelet 在第一次执行 probe 之前要的等待5秒钟。探针检测命令是在容器中执行 cat /tmp/healthy 命令。如果命令执行成功，将返回0，kubelet 就会认为该容器是活着的并且很健康。如果返回非0值，kubelet  就会杀掉这个容器并重启它。

在容器生命的最初30秒内有一个 /tmp/healthy 文件，在这30秒内 cat /tmp/healthy命令会返回一个成功的返回码。30秒后， cat /tmp/healthy 将返回失败的返回码。

```
# 创建pod
kubectl create -f exec-liveness.yaml

# 在30秒内，查看 Pod 的 event，结果显示没有失败的 liveness probe
kubectl describe pod liveness-exec

# 35秒后，再次查看 Pod 的 event，在最下面有一条信息显示 liveness probe 失败，容器被删掉并重新创建

# 再等30秒，确认容器已经重启
kubectl get pod liveness-exec

# 从输出结果来RESTARTS值加1了。
```

## liveness HTTP请求

```
apiVersion: v1
kind: Pod
metadata:
  labels:
    test: liveness
  name: liveness-http
spec:
  containers:
  - name: liveness
    image: k8s.gcr.io/liveness
    args:
    - /server
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8080
        httpHeaders:
        - name: X-Custom-Header
          value: Awesome
      initialDelaySeconds: 3
      periodSeconds: 3
```

## liveness tcpSocket

```
apiVersion: v1
kind: Pod
metadata:
  name: goproxy
  labels:
    app: goproxy
spec:
  containers:
  - name: goproxy
    image: k8s.gcr.io/goproxy:0.1
    ports:
    - containerPort: 8080
    readinessProbe:
      tcpSocket:
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 10
    livenessProbe:
      tcpSocket:
        port: 8080
      initialDelaySeconds: 15
      periodSeconds: 20
```

# readiness probe

Readiness probe的配置跟liveness probe很像。唯一的不同是使用 readinessProbe而不是livenessProbe。

```
readinessProbe:
  exec:
    command:
    - cat
    - /tmp/healthy
  initialDelaySeconds: 5
  periodSeconds: 5
```

Readiness probe 的 HTTP 和 TCP 的探测器配置跟 liveness probe 一样。

Readiness 和 livenss probe 可以并行用于同一容器。 使用两者可以确保流量无法到达未准备好的容器，并且容器在失败时重新启动。

# 何时该使用存活态探针

如果容器中的进程能够在遇到问题或不健康的情况下自行崩溃，则不一定需要存活态探针; kubelet 将根据 Pod 的restartPolicy 自动执行修复操作。

如果你希望容器在探测失败时被杀死并重新启动，那么请指定一个存活态探针， 并指定restartPolicy 为 "Always" 或 "OnFailure"。

# 何时该使用就绪态探针

如果要仅在探测成功时才开始向 Pod 发送请求流量，请指定就绪态探针。 在这种情况下，就绪态探针可能与存活态探针相同，但是规约中的就绪态探针的存在意味着 Pod 将在启动阶段不接收任何数据，并且只有在探针探测成功后才开始接收数据。

如果你的容器需要加载大规模的数据、配置文件或者在启动期间执行迁移操作，可以添加一个 就绪态探针。

如果你希望容器能够自行进入维护状态，也可以指定一个就绪态探针，检查某个特定于 就绪态的因此不同于存活态探测的端点。

# 何时该使用启动探针

对于所包含的容器需要较长时间才能启动就绪的 Pod 而言，启动探针是有用的。 你不再需要配置一个较长的存活态探测时间间隔，只需要设置另一个独立的配置选定， 对启动期间的容器执行探测，从而允许使用远远超出存活态时间间隔所允许的时长。

如果你的容器启动时间通常超出 initialDelaySeconds + failureThreshold × periodSeconds 总值，你应该设置一个启动探测，对存活态探针所使用的同一端点执行检查。 periodSeconds 的默认值是 30 秒。你应该将其  failureThreshold 设置得足够高， 以便容器有充足的时间完成启动，并且避免更改存活态探针所使用的默认值。  这一设置有助于减少死锁状况的发生。

# 汇总

使用tcpSocket方式探测端口是否启动，使用httpGet方式探测服务是否就绪

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-v1
  namespace: blue-green
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myapp
      version: v1
  template:
    metadata:
     labels:
      app: myapp
      version: v1
    spec:
       containers:
       - name: myapp
         image: jdd.io/demo:20210402174646
         imagePullPolicy: IfNotPresent
         livenessProbe:
           tcpSocket:
             port: 8888
           initialDelaySeconds: 15
           periodSeconds: 20
         readinessProbe:
           httpGet:           
             path: /hello/test
             port: 8888
           initialDelaySeconds: 5
           periodSeconds: 10
       imagePullSecrets:
         - name: regcred
```

# 额外补充：使用命名的端口

可以使用命名的 ContainerPort 作为 HTTP 或 TCP liveness检查：

```
ports:
- name: liveness-port
  containerPort: 8080
  hostPort: 8080

livenessProbe:
  httpGet:
  path: /healthz
  port: liveness-port
```