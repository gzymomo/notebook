- [K8s中 蓝绿部署、金丝雀发布、滚动更新汇总](https://mp.weixin.qq.com/s/YNuN9x-G37sOXCnZVaLm7A)

## 1 Kubernetes 中的部署策略

在**本文**[1]中，我们将学习使用 Kubernetes 容器编排系统部署容器时的部署策略。在本文的最后，我们将学习如何在 Kubernetes 集群中使用不同的方式进行部署。如果您觉得这个话题很有趣，请继续阅读！本教程的代码可在 **Github上找到**[2]

## 2 Kubernetes 快速介绍

容器化随着时间的推移越来越流行，并彻底改变了构建、传输和维护应用程序的过程，因此需要有效地管理这些容器。引入了许多容器编排工具来管理这些容器在大型系统中的生命周期。

Kubernetes  就是这样一种编排工具，它负责配置和部署、资源分配、负载平衡、服务发现、提供高可用性以及任何系统的其他重要方面。有了这个平台，我们可以在开发的同时将我们的应用程序分解成更小的系统（称为微服务）；然后，我们可以在部署时组合（或编排）这些系统。

云原生方法的采用增加了基于微服务架构的应用程序的开发。对于此类应用程序，组织面临的最大挑战之一是部署。在部署方面有一个适当的策略是必要的。在 Kubernetes  中，有多种发布应用程序的方式；在应用程序部署或更新期间，有必要选择正确的策略来使您的基础设施可靠。例如，在生产环境中，始终需要确保最终用户不会遇到任何停机时间。在 Kubernetes 编排中，正确的策略确保正确管理不同版本的容器镜像。综上所述，本文将主要围绕Kubernetes中的不同部署策略展开。

## 3 先决条件

为了继续阅读本文，我们需要一些之前使用 Kubernetes 的经验。如果不熟悉此平台，请查看**基本 Kubernetes 概念**[3]教程的**分步介绍**[4]。在那里，您可以按照此处的说明学习所需的一切。如果需要，我们还建议您阅读**Kubernetes 文档**[5]。

除此之外，我们还需要 kubectl，这是一个命令行界面 (CLI) 工具，使我们能够从终端控制您的集群。如果您没有此工具，请查看安装 Kube Control (kubectl) 中的说明。我们还需要对 Linux 和 YAML 有基本的了解。

## 4 Kubernetes 中的部署是什么？

Deployment 是 Kubernetes  中的一个资源对象，它为我们的程序定义了所需的状态。部署是声明性的，这意味着我们不规定如何实现状态。相反，我们声明所需的状态并允许deployment控制器以最有效的方式自动达到最终目标。deployment允许我们描述应用程序的生命周期，例如应用程序使用哪些Image，应该有多少 pod，以及应该更新它们的方式。

## 5 使用 Kubernetes 部署的好处

手动更新容器化应用程序的过程可能既耗时又乏味。Kubernetes deployment使此过程自动化且可重复。部署完全由 Kubernetes 后端管理，整个更新过程在服务器端执行，无需客户端交互。

此外，Kubernetes deployment controller始终监控 Pod 和节点的健康状况。它可以替换出现故障的 pod以及跳过故障的节点，确保关键应用程序的连续性。

## 6 部署策略

### 滚动更新部署`Rolling Update`

滚动部署是 Kubernetes 中的默认部署策略。它用新版本的 pod 一个一个地替换我们应用程序的先前版本的 pod，而没有任何集群停机时间。滚动部署缓慢地用新版本应用程序的实例替换之前版本的应用程序实例。

![图片](https://mmbiz.qpic.cn/mmbiz_jpg/lPwvgkMwLNjYTY6gKHoqvQ8MJibSUGTyia9oskHg76NvVUHxwR6BUbn3vwFgxRb8UrE63Ej9ZgNthCsX87KuOA3g/640?wx_fmt=jpeg&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

使用 RollingUpdate 策略时，还有两个选项可以让我们微调更新过程：

1. **maxSurge**：更新期间可以创建的 pod 数量超过所需的 pod 数量。这可以是副本计数的绝对数量或百分比。默认值为 25%。
2. **maxUnavailable**：更新过程中可能不可用的 Pod 数。这可以是副本计数的绝对数量或百分比；默认值为 25%。

首先，我们创建*rollingupdate.yaml*部署模板。在下面的模板中，我们将*maxSurge*设置为 2，将*maxUnavailable 设置*为 1。

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rollingupdate-strategy
  version: nanoserver-1709
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 2
      maxUnavailable: 1
  selector:
    matchLabels:
      app: web-app-rollingupdate-strategy
      version: nanoserver-1709
  replicas: 3
  template:
    metadata:
      labels:
        app: web-app-rollingupdate-strategy
        version: nanoserver-1709
    spec:
      containers:
        - name: web-app-rollingupdate-strategy
          image: hello-world:nanoserver-1709
```

然后我们可以使用 kubectl 命令创建部署。

```
$ kubectl apply -f rollingupdate.yaml
```

一旦我们有了deployments模板，我们就可以通过创建服务来提供一种访问部署实例的方法。请注意，我们正在使用版本*nanoserver-1709*部署映像*hello-world*。因此，在这种情况下，我们有两个label，`name= web-app-rollingupdate-strategy`和`version= nanoserver-1709`。我们将这些设置为下面服务的标签选择器。将此保存到“ *service.yaml* ”文件。

```
apiVersion: v1
kind: Service
metadata: 
  name: web-app-rollingupdate-strategy
  labels: 
    name: web-app-rollingupdate-strategy
    version: nanoserver-1709
spec:
  ports:
    - name: http
      port: 80
      targetPort: 80
  selector: 
    name: web-app-rollingupdate-strategy
    version: nanoserver-1709
  type: LoadBalancer
```

现在创建服务,将创建一个可在集群外访问的负载均衡器。

```
$ kubectl apply -f service.yaml
```

运行*kubectl get deployments*检查是否创建了 Deployment。如果 Deployment 仍在创建中，则输出应类似于以下内容：

```
$ kubectl get deployments

NAME                             READY   UP-TO-DATE   AVAILABLE   AGE
rollingupdate-strategy   0/3     0            0           1s
```

如果我们几秒钟后再次运行*kubectl get 部署*。输出应与此类似：

```
$ kubectl get deployments

NAME                             READY   UP-TO-DATE   AVAILABLE   AGE
rollingupdate-strategy   3/3     0            0           7s
```

要查看 Deployment 创建的 ReplicaSet (rs)，请运行*kubectl get rs*。输出应与此类似：

```
$ kubectl get rs

NAME                                    DESIRED   CURRENT   READY   AGE
rollingupdate-strategy-87875f5897   3         3         3       18s
```

要查看为部署运行的 3 个 pod，请运行*kubectl get pods*。创建的 ReplicaSet 确保有三个 Pod 在运行。输出应类似于以下内容。

```
$ kubectl get pods

NAME                                      READY     STATUS    RESTARTS   AGE       
rollingupdate-strategy-87875f5897-55i7o   1/1       Running   0          12s       
rollingupdate-strategy-87875f5897-abszs   1/1       Running   0          12s       
rollingupdate-strategy-87875f5897-qazrt   1/1       Running   0          12s
```

让我们更新*rollingupdate.yaml*部署模板以使用*hello-world:nanoserver-1809*镜像而不是*hello-world:nanoserver-1709*镜像。然后使用 kubectl 命令更新现有运行部署的镜像。

```
$ kubectl set image deployment/rollingupdate-strategy web-app-rollingupdate-strategy=hello-world:nanoserver-1809 --record
```

输出类似于以下内容。

```
deployment.apps/rollingupdate-strategy image updated
```

我们现在正在使用版本*nanoserver-1809*部署映像*hello-world*。因此，在这种情况下，我们将不得不更新“service.yaml”中的标签。标签将更新为“version= *nanoserver-1809* ”。我们将再次运行以下 kubectl 命令来更新服务，以便它可以选择在新镜像上运行的新 pod。

```
$ kubectl apply -f service.yaml
```

要查看deployment的状态，请运行下面的 kubectl 命令。

```
$ kubectl rollout status deployment/rollingupdate-strategy

Waiting for rollout to finish: 2 out of 3 new replicas have been updated...
```

再次运行以验证部署是否成功。

```
$ kubectl rollout status deployment/rollingupdate-strategy

deployment "rollingupdate-strategy" successfully rolled out
```

部署成功后，我们可以通过运行命令*kubectl get deployments*来查看 Deployment 。输出类似于：

```
$ kubectl get deployments

NAME                             READY   UP-TO-DATE   AVAILABLE   AGE
rollingupdate-strategy   3/3     0            0           7s
```

运行*kubectl get rs*以查看 Deployment 是否已更新。新的 Pod 在一个新的 ReplicaSet 中创建并扩展到 3 个副本。旧的 ReplicaSet 缩减为 0 个副本。

```
$ kubectl get rs

NAME                                    DESIRED   CURRENT   READY   AGE
rollingupdate-strategy-87875f5897   3         3         3       55s
rollingupdate-strategy-89999f7895   0         0         0       12s
```

运行*kubectl get pods*它现在应该只显示新 ReplicaSet 中的新 Pod。

```
$ kubectl get pods

NAME                                      READY     STATUS    RESTARTS   AGE       
rollingupdate-strategy-89999f7895-55i7o   1/1       Running   0          12s       
rollingupdate-strategy-89999f7895-abszs   1/1       Running   0          12s       
rollingupdate-strategy-89999f7895-qazrt   1/1       Running   0          12s
```

kubectl 的 rollout 命令在这里非常有用。我们可以用它来检查我们的部署是如何进行的。默认情况下，该命令会等待部署中的所有 Pod 成功启动。当部署成功时，命令退出并返回代码为零以表示成功。如果部署失败，该命令将以非零代码退出。

```
$ kubectl rollout status deployment rollingupdate-strategy

Waiting for deployment "rollingupdate-strategy" rollout to finish: 0 of 3 updated replicas are available…
Waiting for deployment "rollingupdate-strategy" rollout to finish: 1 of 3 updated replicas are available…
Waiting for deployment "rollingupdate-strategy" rollout to finish: 2 of 3 updated replicas are available…

deployment "rollingupdate-strategy" successfully rolled out
```

如果在 Kubernetes 中部署失败，部署过程会停止，但失败部署中的 pod 会保留下来。在部署失败时，我们的环境可能包含来自旧部署和新部署的  pod。为了恢复到稳定的工作状态，我们可以使用 rollout undo 命令来恢复工作 pod 并清理失败的部署。

```
$ kubectl rollout undo deployment rollingupdate-strategy

deployment.extensions/rollingupdate-strategy
```

然后我们将再次验证部署的状态。

```
$ kubectl rollout status deployment rollingupdate-strategy

deployment "rollingupdate-strategy" successfully rolled out
```

为了让 Kubernetes 知道应用程序何时准备就绪，它需要应用程序的一些帮助。Kubernetes  使用就绪探针来检查应用程序的运行情况。一旦应用程序实例开始以肯定响应响应就绪探测，该实例就被认为可以使用了。就绪探针会告诉 Kubernetes 应用程序何时准备就绪，但不会告诉 Kubernetes 应用程序是否准备就绪。如果应用程序不断失败，它可能永远不会对 Kubernetes  做出积极响应。

滚动部署通常会在缩小旧组件之前通过就绪检查等待新 Pod 准备就绪。如果发生重大问题，可以中止滚动部署。如果出现问题，可以中止滚动更新或部署，而无需关闭整个集群。

### 重新创建部署

在重新创建部署中，我们在扩展新应用程序版本之前完全缩减现有应用程序版本。在下图中，版本 1 表示当前应用程序版本，版本 2 表示新应用程序版本。在更新当前应用程序版本时，我们首先将版本 1 的现有副本缩减为零，然后与新版本并发部署副本。

![图片](https://mmbiz.qpic.cn/mmbiz_jpg/lPwvgkMwLNjYTY6gKHoqvQ8MJibSUGTyiaByUTIJK6etOPeCmKQ6b5w4DupDDwXL9K2He591hRiaZbDsibhBJAgK7Q/640?wx_fmt=jpeg&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

下面的模板显示了使用重新创建策略的部署：首先，我们通过将以下 yaml 保存到文件 recreate.yaml 来创建我们的*重新创建*部署

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: recreate-strategy
spec:
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: web-app-recreate-strategy
      version: nanoserver-1809
  replicas: 3
  template:
    metadata:
      labels:
        app: web-app-recreate-strategy
    spec:
      containers:
        - name: web-app-recreate-strategy
          image: hello-world:nanoserver-1809
```

然后我们可以使用 kubectl 命令创建部署。

```
$ kubectl apply -f recreate.yaml
```

一旦我们有了部署模板，我们就可以通过创建服务来提供一种访问部署实例的方法。请注意，我们正在使用版本*nanoserver-1809*部署映像*hello-world*。所以在这种情况下，我们有两个标签，“name= *web-app-recreate-strategy* ”和“version= *nanoserver-1809* ”。我们将这些设置为下面服务的标签选择器。将其保存到*service.yaml*文件中。

```
apiVersion: v1
kind: Service
metadata: 
  name: web-app-recreate-strategy
  labels: 
    name: web-app-recreate-strategy
    version: nanoserver-1809
spec:
  ports:
    - name: http
      port: 80
      targetPort: 80
  selector: 
    name: web-app-recreate-strategy
    version: nanoserver-1809
  type: LoadBalancer
```

现在创建服务将创建一个可在集群外访问的负载均衡器。

```
$ kubectl apply -f service.yaml
```

重新创建方法在更新过程中涉及一些停机时间。对于可以处理维护窗口或中断的应用程序，停机时间不是问题。但是，如果存在具有高服务级别协议 (SLA) 和可用性要求的关键任务应用程序，则选择不同的部署策略将是正确的方法。Recreate  部署一般用于开发者的开发阶段，因为它易于设置，并且应用程序状态会随着新版本完全更新。此外，我们不必并行管理多个应用程序版本，因此我们避免了数据和应用程序的向后兼容性挑战。

### 蓝绿部署

在蓝/绿部署策略（有时也称为红/黑）中，蓝色代表当前应用版本，绿色代表新应用版本。在这种情况下，一次只有一个版本处于活动状态。在创建和测试绿色部署时，流量被路由到蓝色部署。完成测试后，我们将流量路由到新版本。

部署成功后，我们可以保留蓝色部署以备回滚或者回退。或者，可以在这些实例上部署较新版本的应用程序。在这种情况下，当前（蓝色）环境用作下一个版本的暂存区。

这种技术可以消除我们在重新创建部署策略中遇到的停机时间。此外，蓝绿部署降低了风险：如果我们在 Green 上的新版本发生意外，我们可以通过切换回 Blue 立即回滚到上一个版本。我们还可以避免版本问题；整个应用程序状态在一次部署中更改。

![图片](https://mmbiz.qpic.cn/mmbiz_jpg/lPwvgkMwLNjYTY6gKHoqvQ8MJibSUGTyiaeRfUBDaIlfThwjiaficMKpl1wAHYHWG2uJJOIlbt029BDCmamw6COO4g/640?wx_fmt=jpeg&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

蓝绿部署成本高昂，因为它需要双倍的资源。在将其发布到生产环境之前，应对整个平台进行适当的测试。此外，处理有状态的应用程序很困难。                                                                                                    

首先，我们通过将以下 yaml 保存到“blue.yaml”文件来创建*蓝色*部署：

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: blue-deployment
spec:
  selector:
    matchLabels:
      app: blue-deployment
      version: nanoserver-1709
  replicas: 3
  template:
    metadata:
      labels:
        app: blue-deployment
        version: nanoserver-1709
    spec:
      containers:
        - name: blue-deployment
          image: hello-world:nanoserver-1709
```

然后我们可以使用 kubectl 命令创建部署。

```
$ kubectl apply -f blue.yaml
```

一旦我们有了部署模板，我们就可以通过创建服务来提供一种访问部署实例的方法。请注意，我们正在使用版本*nanoserver-1809*部署映像*hello-world*。所以在这种情况下，我们有两个标签，“name= *blue-deployment* ”和“version= *nanoserver-1709* ”。我们将这些设置为下面服务的标签选择器。将其保存到*service.yaml*文件中。

```
apiVersion: v1
kind: Service
metadata: 
  name: blue-green-service
  labels: 
    name: blue-deployment
    version: nanoserver-1709
spec:
  ports:
    - name: http
      port: 80
      targetPort: 80
  selector: 
    name: blue-deployment
    version: nanoserver-1709
  type: LoadBalancer
```

现在创建服务将创建一个可在集群外访问的负载均衡器。

```
$ kubectl apply -f service.yaml
```

我们现在有以下设置。

![图片](https://mmbiz.qpic.cn/mmbiz_jpg/lPwvgkMwLNjYTY6gKHoqvQ8MJibSUGTyiaSUKLlbnRptXbUl1pdJK6aiatW9JEeZT2gFYB3znvOghNgXRIJyFqxWQ/640?wx_fmt=jpeg&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

对于*绿色*部署，我们将在*蓝色*部署的同时部署一个新部署。下面的模板是文件的内容：`green.yaml`

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: green-deployment
spec:
  selector:
    matchLabels:
      app: green-deployment
      version: nanoserver-1809
  replicas: 3
  template:
    metadata:
      labels:
        app: green-deployment
        version: nanoserver-1809
    spec:
      containers:
        - name: green-deployment
          image: hello-world:nanoserver-1809
```

请注意，镜像*hello-world:nanoserver-1809*标记名称已更改为 2。因此我们使用两个标签进行了单独部署，名称= *green-deployment*和 version= *nanoserver-1809*。

```
$ kubectl apply -f green.yaml
```

为了切换到*绿色*部署，我们将更新现有服务的选择器。编辑 service.yaml 并将选择器版本更改为*2*并将名称更改为*green-deployemnt*。这将使它与*绿色*“部署”上的 pod 相匹配。

```
apiVersion: v1
kind: Service
metadata: 
  name: blue-green-service
  labels: 
    name: green-deployment
    version: nanoserver-1809
spec:
  ports:
    - name: http
      port: 80
      targetPort: 80
  selector: 
    name: green-deployment
    version: nanoserver-1809
  type: LoadBalancer
```

我们使用 kubectl 命令再次创建服务：

```
$ kubectl apply -f service.yaml
```

![图片](https://mmbiz.qpic.cn/mmbiz_jpg/lPwvgkMwLNjYTY6gKHoqvQ8MJibSUGTyiaju37XHLUMofHdMaJViaLL1EsWZDmYNjX82DhPljq39YrYZicSlHHHfwA/640?wx_fmt=jpeg&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

因此得出结论，我们可以看到蓝绿部署是全有或全无，不像滚动更新部署，我们无法逐步推出新版本。所有用户将同时收到更新，但允许现有会话在旧实例上完成他们的工作。因此，一旦我们启动更改，风险就比一切都应该工作的要高一些。它还需要分配更多的服务器资源，因为我们需要运行每个 Pod 的两个副本。

幸运的是，回滚过程同样简单：我们只需再次拨动开关，先前的版本就被换回原位。那是因为旧版本仍在旧 Pod 上运行。只是流量不再被路由到他们。当我们确信新版本会继续存在时，我们应该停用这些 pod。

### 金丝雀部署

Canary 更新策略是一个部分更新过程，它允许我们在真实用户群上测试我们的新程序版本，而无需承诺全面推出。类似于蓝/绿部署，但它们更受控制，并且它们使用更渐进的交付方式，其中部署是分阶段进行的。有许多策略属于金丝雀的保护伞，包括暗发布或 A/B 测试。

在金丝雀部署中，新版本的应用程序逐渐部署到Kubernetes集群，同时获得极少量的实时流量（即，一部分实时用户正在连接到新版本，而其余的仍在使用以前的版本）  .在这种方法中，我们有两个几乎相同的服务器：一个用于所有当前活跃用户，另一个带有新功能，用于向一部分用户推出然后进行比较。当没有错误报告并且信心增加时，新版本可以逐渐推广到基础架构的其余部分。最后，所有实时流量都流向金丝雀，使金丝雀版本成为新的*生产版本*。

下图显示了进行金丝雀部署的最直接和最简单的方法。新版本部署到服务器的子集。

![图片](https://mmbiz.qpic.cn/mmbiz_jpg/lPwvgkMwLNjYTY6gKHoqvQ8MJibSUGTyiaUTUciaFVBpS2G9OP76WiatngX0WWdlGesJJJhjlMHJBbKkFsslXA7ib6Q/640?wx_fmt=jpeg&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

在发生这种情况时，我们会观察升级后的机器的运行情况。我们检查错误和性能问题，并听取用户反馈。随着我们对金丝雀越来越有信心，我们继续在其余机器上安装它，直到它们都运行最新版本。

在规划金丝雀部署时，我们必须考虑各种因素：

1. **阶段**：我们将首先向金丝雀发送多少用户，以及在多少阶段。
2. **持续时间**：我们计划运行金丝雀多久？Canary 版本不同，因为我们必须等待足够多的客户端更新才能评估结果。这可能会在几天甚至几周内发生。
3. **指标**：记录哪些指标以分析进度，包括应用程序性能和错误报告？精心选择的参数对于成功部署 Canary 至关重要。例如，衡量部署的一种非常简单的方法是通过 HTTP 状态代码。我们可以有一个简单的 ping 服务，当部署成功时返回  200。如果部署中存在问题，它将返回服务器端错误 (5xx)。
4. **评估**：我们将使用什么标准来确定金丝雀是否成功

Canary 用于我们必须在应用程序后端测试新功能的场景。当我们对新版本不是 100% 有信心时，应该使用 Canary 部署；我们预测我们失败的可能性很小。当我们进行重大更新时，通常会使用此策略，例如添加新功能或实验性功能。

## 7 K8s 部署策略总结

总而言之，部署应用程序有多种不同的方式；当发布到开发/暂存环境时，重新创建或升级部署通常是一个不错的选择。在生产方面，蓝/绿部署通常很合适，但需要对新平台进行适当的测试。如果我们对平台的稳定性以及发布新软件版本可能产生的影响没有信心，那么金丝雀版本应该是我们要走的路。通过这样做，我们让消费者测试应用程序及其与平台的集成。在本文中，我们只触及了 Kubernetes 部署功能的皮毛。通过将部署与所有其他 Kubernetes  功能相结合，用户可以创建更强大的容器化应用程序以满足任何需求。                                                                                            

### 参考资料

[1]原文: *https://auth0.com/blog/deployment-strategies-in-kubernetes/*

[2]Github: *https://github.com/akhil90s/auth0/tree/main/Deployment%20Strategies%20In%20Kubernetes/Declarative%20Templates*

[3]k8s概念: *https://auth0.com/blog/kubernetes-tutorial-step-by-step-introduction-to-basic-concepts/*

[4]分布介绍: *https://auth0.com/blog/kubernetes-tutorial-step-by-step-introduction-to-basic-concepts/*

[5]kubernetes.io: *https://kubernetes.io/docs/home/*