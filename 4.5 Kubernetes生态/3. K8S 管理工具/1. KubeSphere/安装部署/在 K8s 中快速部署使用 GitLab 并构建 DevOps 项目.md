- [在 K8s 中快速部署使用 GitLab 并构建 DevOps 项目](https://mp.weixin.qq.com/s/r2IADp_9dVwPSor7H_8QWw)

## 前提条件

### 安装 KubeSphere

安装 KubeSphere 有两种方法。一是在 Linux 上直接安装，可以参考文档：**在 Linux 安装 KubeSphere**[1]；二是在已有 Kubernetes 中安装，可以参考文档：**在 Kubernetes 安装 KubeSphere**[2]。

### 在 KubeSphere 中启用 DevOps 套件

在 KubeSphere 中启用 DevOps 套件可以参考文档：**启用可插拔组建 · KubeSphere DevOps 系统**[3]。安装完成后可以在「平台管理」页面的「系统组建」部分看到 Jenkins 头像图标。

![图片](https://mmbiz.qpic.cn/mmbiz_png/u5Pibv7AcsEX7oLnRfJOe0GpdlCqUZjMtA4j67TAnveibodiabRbO7wicocJB1bkurqnibiahg0klnIBoXl23j43kESg/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

基于 **Jenkins**[4] 的 KubeSphere DevOps 系统是专为 K8s 中的 CI/CD 工作流设计的，它提供了一站式的解决方案，帮助开发和运维团队用非常简单的方式构建、测试和发布应用到 K8s。它还具有插件管理、**Binary-to-Image (B2I)**[5]、**Source-to-Image (S2I)**[6]、代码依赖缓存、代码质量分析等功能。文本只会涉及 KubeSphere DevOps 其中关于流水线使用的部分。

## 安装 GitLab CE

> 我们先这次的演练创建一个名为 `devops`的企业空间，同时创建一个名为 `gitlab`的项目供 GitLab CE 部署使用。

### 通过应用仓库部署 GitLab 应用

首先我们还是要现在 `devops`企业空间中添加 GitLab 的官方 Helm Chart 仓库，推荐用这种自管理的方式来保障仓库内容是得到及时同步的。通过「应用管理」下面的「应用仓库」来添加如下的 GitLab 仓库（仓库 URL：`https://charts.gitlab.io/`）。

![图片](https://mmbiz.qpic.cn/mmbiz_png/u5Pibv7AcsEX7oLnRfJOe0GpdlCqUZjMtSulibj1wpljMoZWhMbmybQx9Kdg8LL7icibv6Bgpbmq8jiacibKPX1uETcg/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

接下来进入先前创建的`gitlab`项目，从「应用负载」下面的「应用」页面创建 GitLab 应用：选择「从应用模版」创建即可得到如下界面，由于仓库内可安装的 Helm Chart 较多，注意选择红框指示的这个应用（撰稿时 Chart 最新版为 `5.7.0`，对于 GitLab 版本为 `14.7.0`）。

![图片](https://mmbiz.qpic.cn/mmbiz_png/u5Pibv7AcsEX7oLnRfJOe0GpdlCqUZjMtibkXb4THmd7UWUxxHx1ibkMkrsQWicDJWspI5PjyrC4yfpicFddKxBAKnQ/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

下面这一步十分重要，需要配置 Helm Chart 部署应用的参数。由于 GitLab 默认的可配置项非常多（有上千行），因此我们这次只挑选 **可保障基础业务使用的最小功能集** 的相关参数进行改写，关于每个参数具体代表的含义请参见参数项上一行的注释（并留意【注意】部分）。其它配置项请大家参见 **极狐 GitLab Helm Chart 快速开始指南**[7] 及其中的 **完整属性列表**[8]。

```
global:
  ## 确保使用的版本是 Community Edition
  edition: ce

  ## 全局 Host 配置：https://docs.gitlab.cn/charts/charts/globals.html#host-%E9%85%8D%E7%BD%AE
  #【注意】这里我们只绑定 GitLab 主体服务的域名，其它都可以使用默认值（不影响演练使用）
  hosts:
    #【注意】这个基础域名需要是 “部署 GitLab 的集群” 内可以访问的域名，否则各组件互联可能存在问题
    domain: example.com
    #【注意】我们演练环境为了部署方便不启用 HTTPS，否则需要提供和填写的基础域名对应的证书
    https: false
    gitlab:
      name: gitlab.example.com

  ## 全局 Ingress 配置：https://docs.gitlab.cn/charts/charts/globals.html#ingress-%E9%85%8D%E7%BD%AE
  ingress:
    #【注意】我们由于全面关闭 HTTPS，所以这里也需要关闭 GitLab 自带的证书生成器
    configureCertmanager: false
    #【注意】由于默认是使用自带 Nginx，即使用 "gitlab-nginx"，需要改为 KubeSphere 网关适配的值
    class: nginx
    #【注意】默认是 true，需要强制关闭 HTTPS，和其它配置保持一致
    tls:
      enabled: false

## 自带的 cert-manager 配置：https://github.com/jetstack/cert-manager
#【注意】这里强制选择不安装 cert-manager
certmanager:
  installCRDs: false
  install: false

## 自带的 Nginx Ingress 配置：https://docs.gitlab.cn/charts/charts/nginx/
#【注意】由于演练会直接使用 KubeSphere 项目/集群网关，这里直接关闭此项的安装配置
nginx-ingress:
  enabled: false

## 自带的工件仓库组件：https://docs.gitlab.cn/charts/charts/registry/
#【注意】由于不开启 HTTPS，使用各类工件仓库会有问题，这里建议就直接关闭此项安装配置
registry:
  enabled: false

## 自带的 MinIO 配置：https://docs.gitlab.cn/charts/charts/minio/
#【注意】由于可以后续自行在 KubeSphere 中开启应用路由，这里建议直接关闭网关路由配置
minio:
  ingress:
    enabled: false

## 自带的 GitLab Runner 配置：https://docs.gitlab.cn/charts/charts/gitlab/gitlab-runner/
#【注意】由于演练环境我们直接接入 KubeSphere DevOps 做 CI/CD，这里建议就先不安装 Runner
gitlab-runner:
  install: false
```

虽然已经是最小功能集部署，但由于部署的服务及其资源开销较多，部署过程还是比较长的。部署完成后可以在 `gitlab`应用的「工作负载」部分查看到所有负载都在运行中的状态。

![图片](https://mmbiz.qpic.cn/mmbiz_png/u5Pibv7AcsEX7oLnRfJOe0GpdlCqUZjMtFlM9fnONM9l4ysYNffbHwpX0EaTNwQ4CDZmu54THCibLzMVQITC3sbA/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

此时`gitlab`应用状态处于`正在创建`，这是由于应用部署超时导致的，只要所有工作负载可以正常进入运行状态，是并不影响应用正常使用的。

由于部署时间很长，容易导致 MinIO 组件的舒适化 Bucket 任务失败，建议检查「应用负载」下的`gitlab-minio-create-buckets-1`任务，如果失败可以通过详情页左侧「更多操作」来「重新运行」，最终得到`已完成（1/1）`的状态即可认为成功。

![图片](https://mmbiz.qpic.cn/mmbiz_png/u5Pibv7AcsEX7oLnRfJOe0GpdlCqUZjMtZGN6YHtuBzclj6WgS0Fc8mAibdWtwGDaXTqNRkJKiaLqibibDk4ib6sOiaLw/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

确认所有工作负载运行后，如之前您已经配置过集群或项目网关并使能过`gitlab.example.com`的域名解析，那么您就可以直接访问该域名来打开 GitLab 的站点页面。

![图片](https://mmbiz.qpic.cn/mmbiz_png/u5Pibv7AcsEX7oLnRfJOe0GpdlCqUZjMtncib5iaYOLsWxnKibxicuGh9pQfuEAmT5AY7ERRqS9ric5HBXRqvGGD4ickQ/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

> 关于如何在 KubeSphere 中设置集群或项目网关，您可以参考我们之前的 **技术博客**[9]。**同时请确保您的网关是可以直接使用 HTTP 标准的**`**80**`**端口来提供访问能力的！**

### 在 GitLab 中创建一个示例项目

首先让我们来登陆 GitLab。GitLab 的初始密码被作为 Secret 保存，我们可以回到项目首页，在「配置」下的「保密字典」中搜索`initial`可以找到 `gitlab-initial-root-password`的条目。点击该字典条目，并在「数据」区块中点击最右侧的眼睛图标来展示`password`数据项的内容。

![图片](https://mmbiz.qpic.cn/mmbiz_png/u5Pibv7AcsEX7oLnRfJOe0GpdlCqUZjMt0FRjlFxe77QTJ8up1GGjodn6AAzXGpQkMzPyiadZiboKNGWz8GBTJbVA/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

复制该密码，并使用`root`作为用户名，即可登陆 GitLab 得到如下图所示的界面。

![图片](https://mmbiz.qpic.cn/mmbiz_png/u5Pibv7AcsEX7oLnRfJOe0GpdlCqUZjMthXYj26E1okib65rMvibcK0l4HS4MH4mdtjQ96WRkGGpvx29YZWOPtNng/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

点击「New Project」按钮进入创建项目的页面，通过「Create from Template」我们可以来创建一个示例项目用于后面的流水线演练。

![图片](https://mmbiz.qpic.cn/mmbiz_png/u5Pibv7AcsEX7oLnRfJOe0GpdlCqUZjMtvOqWyYg5bRDeUa7C4QPN9KjFyKFvtbibiaJib48vwP14btYYNx4FyicibQw/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

让我们选择`NodeJS Express`这个项目模版来创建应用，所有模版都可以通过 Preview 按钮来预览其中的内容，使用模版后得到如下创建项目界面。

![图片](https://mmbiz.qpic.cn/mmbiz_png/u5Pibv7AcsEX7oLnRfJOe0GpdlCqUZjMtfGzaoAECjQ7EBHl8ALLaBszBm2KZGX204MUHaM74kFHiaj5Dqo63ibyg/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

填入您偏好的项目名称，并在项目可见度这里选择默认的`Private`来创建私有项目，以便于后续演示如果访问私有项目。完成导入后可以得到如下的项目页面。

![图片](https://mmbiz.qpic.cn/mmbiz_png/u5Pibv7AcsEX7oLnRfJOe0GpdlCqUZjMt0UibiaFy5rsSJw4MwibnNss5FYS3aIsZbCCNpiabxDbT9ydJJ8Nw0oA7EQ/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

### 关闭 Auto DevOps 并创建 Jenkinsfile

由于我们后续要使用 KubeSphere DevOps，而 GitLab 默认开启了 Auto DevOps 功能（会为无 CI 配置的项目自动提供流水线支持），为了避免混乱，我们先暂时关闭 Auto DevOps。

找到项目页面中间部位的文件及功能快捷入口区域，点击「Auto DevOps enabled」按钮块，进入配置页面后取消`Default to Auto DevOps pipeline`的勾选并「Save changes」，即可完成 Auto DevOps 功能的关闭。

![图片](https://mmbiz.qpic.cn/mmbiz_png/u5Pibv7AcsEX7oLnRfJOe0GpdlCqUZjMtBjMP4ibDXKdotDD6P8l1C3h3xhpKCSQumHUN3LcUvMX8vUJkBKGEruA/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

接下来，我们还需要为这个项目创建一个 Jenkinsfile 用于后续 KubeSphere DevOps 流水线的构建。在`master`分支下直接创建一个名为`Jenkinsfile`的文件，填入以下内容即可。

```
pipeline {
    agent any
    stages {
        stage('Example') {
            steps {
                echo 'Hello World'
            }
        }
    }
    post {
        always {
            echo 'I will always say Hello again!'
        }
    }
}
```

## 使用 KubeSphere DevOps 为 GitLab 提供流水线

> 我们首先在`devops`的企业空间中创建一个名为`demo`的 DevOps 项目，用于后续演练如何为 GitLab 创建流水线。

### 将 GitLab 与 KubeSphere Jenkins 进行绑定

> 由于 KubeSphere Jenkins 默认绑定的 GitLab 服务是官方的`gitlab.com`，因此在创建流水线前需要先重新绑定到我们创建的私有 GitLab 服务上。

首先，我们需要打开 KubeSphere Jenkins 的页面，为了操作方便，我们直接为`kubesphere-devops-system`命名空间下的`devops-jenkins`开放 NodePort。

![图片](https://mmbiz.qpic.cn/mmbiz_png/u5Pibv7AcsEX7oLnRfJOe0GpdlCqUZjMtb4m5MOpEB4icSR5FsfJyUX3UWwEGFJXt1J92xrVtynNxkLkvM0tIoGA/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

使用 KubeSphere 账号登陆 Jenkins（**如果登陆失败可能是账号同步问题，可以修改一次密码再次尝试**）。通过「Manage Jenkins ➡️ Configure System」进入系统配置页面，找到 `GitLab Servers`配置区，点击「Add GitLab Server」开始添加我们的 GitLab 服务。

![图片](https://mmbiz.qpic.cn/mmbiz_png/u5Pibv7AcsEX7oLnRfJOe0GpdlCqUZjMtswJ7p1NdUjnIRpNE9lFKk6zBlHQ24v9pCicdD684RyCgLUpr6uPfnbg/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

如上图所示，需要填写或编辑的配置项一共有三项：

- `Server URL`：这里填入我们刚刚部署完成的 GitLab 服务的访问方式（如果是域名访问，一定需要是 Jenkins 也可达的域名）
- `Crendentials`：这里选择或创建一个 Jenkins 的的凭证项，该凭证需要是 GitLab 某个用户的 Personal Access Token（下面我们会继续说明如何创建）
- `Web Hook`：这个一定要勾选 `Manage Web Hooks`这项，用于我们之后同步 Jenkins Pipeline 的状态到我们的 GitLab 服务中

#### 创建 GitLab Personal Access Token 的 Jenkins Crendential

首先，我们回到 GitLab 中，可以直接通过 <gitlab-url>/-/profile/personal_access_tokens（例如本文可使用 **http://gitlab.example.com:30433/-/profile/personal_access_tokens**）来访问 Personal Access Tokens 的创建页面。按 Jenkins 的要求，我们创建一个名为 `jenkins`且具备`api`、`read_repository`、`write_repository` 权限的令牌，复制令牌字符串备用。

![图片](https://mmbiz.qpic.cn/mmbiz_png/u5Pibv7AcsEX7oLnRfJOe0GpdlCqUZjMtRWkYKkck0ZICa66Ss6X9DSHPjYPhOXWRPpnCm7hYRBia9jKsswkwc5Q/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

然后我们回到 Jenkins 首页，从「Manage Jenkins ➡️ Manage Crendentials ➡️ Stores scoped to  Jenkins ➡️ Jenkins ➡️ Global crendentials (unrestricted)」进入凭证创建页面。

![图片](https://mmbiz.qpic.cn/mmbiz_png/u5Pibv7AcsEX7oLnRfJOe0GpdlCqUZjMt0Exu4yNhTd9NqoXpyTpTwLDtRIewlHUUzYhfQoaYJjEvKiaOnyhgr4w/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

点击左侧面板的「Add Credentials」即可开始创建凭证，填写完成后点击 `Ok` 保存即可完成凭证创建：

- `Kind`选择`GitLab Personal Access Token`
- `Scope`选择默认的`Global`，`ID`填入任意不产生命名冲突的 ID
- `Token`填入刚刚复制备用的 GitLab 令牌字符串（可忽略字符串长度的提示）

![图片](https://mmbiz.qpic.cn/mmbiz_png/u5Pibv7AcsEX7oLnRfJOe0GpdlCqUZjMtHaV3Dljxdd3eu1rnBKLdnzibwzBgLBtDqmKwiarPu9N9ANbbpS3TOoXg/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

完成这部分配置之后，KubeSphere DevOps 流水线的状态也会和我们 GitLab 中的 Pipeline 状态形成联动，大家可以参看视频中的效果。



### 使用 Jenkinsfile 创建 KubeSphere DevOps 流水线

让我们进入之前创建的`demo`DevOps 项目，开始「创建」流水线。

![图片](https://mmbiz.qpic.cn/mmbiz_png/u5Pibv7AcsEX7oLnRfJOe0GpdlCqUZjMtrceVfN5sYFM0Ra3jZaxVOWiaIFfgibZ5jY7TkghN6Tib8VEWtVeTsmSMA/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

在弹出的「创建流水线」对话框中，我们填入一个流水线「名称」并点击下方「代码仓库（可选）」这个区域来进行代码仓库绑定。

![图片](https://mmbiz.qpic.cn/mmbiz_png/u5Pibv7AcsEX7oLnRfJOe0GpdlCqUZjMticC3UTPLPSwfibHibhazhMT85KAHIxWnJ5brGoOQNPwGodMvo7L3hljdA/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

进入到「选择代码仓库」面板后，我们选择`GitLab`标签页，然后在「GitLab 服务器地址」下拉框中选择我们上一小节在 Jenkins 中添加到`GitLab CE`服务器。由于我们演练的是私有仓库访问，下面需要先选择一个凭证用于访问私有代码仓库。在之前没有创建的情况下，这里我们点击绿色的「创建凭证」链接开始创建。

![图片](https://mmbiz.qpic.cn/mmbiz_png/u5Pibv7AcsEX7oLnRfJOe0GpdlCqUZjMt5I0DolXTiarAPoEwc7GVAsibHWibEFSohXkT1ejqVic89nXnTkUzSCILdw/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

在弹出的「创建凭证」对话框中，输入「名称」后选定类型为`用户名和密码`；然后在「用户名」文本框中输入我们的账号`root`，在「密码/令牌」中输入之前从保密字典中获取到的初始密码。

![图片](https://mmbiz.qpic.cn/mmbiz_png/u5Pibv7AcsEX7oLnRfJOe0GpdlCqUZjMtPnf7gRro5IR4kB8y1eWpHbcTknqWuJR5YXS0fvdIbCDNZzNpKFjic6A/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

通过「确定」按钮保存凭证后回到「选择代码面板」，在「凭证」下拉框中选择刚刚创建的`gitlab-root`，然后在「项目组/所有者」文本库中填入我们的账号`root`，点击「代码仓库」下拉框可看到`root`账号下所有的代码仓库，这里我们可以看到并选择之前创建的示例项目`root/nodejs-demo`。

![图片](https://mmbiz.qpic.cn/mmbiz_png/u5Pibv7AcsEX7oLnRfJOe0GpdlCqUZjMtRYcfUCZC7x5nCYqO6fZiasUVgRUI9lf7sBhOvvwiaXucr85fDnI6coEA/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

通过 ☑️ 按钮确认并保存配置后会再次回到「创建流水线」面板，此时可以看到「代码仓库」已出现我们选择的`root/nodejs-demo`项目，点击「下一步」进入「高级设置」标签页，这里我们不做额外的配置，直接点击「确定」来创建流水线。创建成功后，我们可以看到如下一个「分支数量」为`0`并且健康的流水线。

![图片](https://mmbiz.qpic.cn/mmbiz_png/u5Pibv7AcsEX7oLnRfJOe0GpdlCqUZjMtIo7SE2Boon56yib8bvEZEQnKdLT21MC11tnCTREaR8AI8ctiactn1W9g/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

稍后片刻点击进入新建的`file`流水线，可以看到系统已经扫描到带有`Jenkinsfile`的`master`分支并已经开始运行流水线。

![图片](https://mmbiz.qpic.cn/mmbiz_png/u5Pibv7AcsEX7oLnRfJOe0GpdlCqUZjMtOGmWAvMZBgibVia9iajImO5g9yJ36bDhCnJIWrSngK3aGTKaEMNGCkKIw/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

点击`master`分支进入分支详情页面，不管运行成功还是失败都可以进一步点击「运行 ID」一栏中的序号来查看详细的运行日志及制品等。

等待一段时间后运行成功，进入运行 ID 为`1`的运行记录可以看到如下图展示的界面。进一步我们可以点击右上角的「查看日志」按钮来了解详细的流水线执行情况。

![图片](https://mmbiz.qpic.cn/mmbiz_png/u5Pibv7AcsEX7oLnRfJOe0GpdlCqUZjMtQ60D61rI2iaHCId061lShkkremoHUiaO3NytI1Xq4lE68jj0KnXAcXqg/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

![图片](https://mmbiz.qpic.cn/mmbiz_png/u5Pibv7AcsEX7oLnRfJOe0GpdlCqUZjMtpIV15PmD9TUaZ891nx7gyv6tulsCbxribnqqMmx7uJhWoTqzF8JjVgw/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

> 注意：对于多分支流水线，默认会先执行`checkout scm`步骤，然后再执行 Jenkinsfile 中定义的流水线内容。

### 使用图形编辑器创建 KubeSphere DevOps 流水线

> 本小节内容可参考 KubeSphere 官方文档：DevOps 用户指南 / 使用 DevOps / **使用图形编辑面板创建流水线**[10]

KubeSphere DevOps 流水线也可以通过图形编辑界面来进行创建，让我们重新回到`demo`DevOps 项目首页，「创建」一个新流水线。这次在「创建流水线」面板中我们不绑定代码仓库，直接「下一步」再直接「创建」一个名为`gui`的流水线。

进入流水线详情页面后，我们可以在右侧面板看到「编辑流水线」的按钮，点击后在弹出的「选择流水线模版」对话框中，我们选择`自定义流水线`。

![图片](https://mmbiz.qpic.cn/mmbiz_png/u5Pibv7AcsEX7oLnRfJOe0GpdlCqUZjMt37YOIia4Ry10BsQYgJKhkunx3OjdPl3rM2E3tCxUFcuEvqU3ycgzT3w/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

![图片](https://mmbiz.qpic.cn/mmbiz_png/u5Pibv7AcsEX7oLnRfJOe0GpdlCqUZjMtQjuwdIibN64OjPNjPzrud6Gojia2Q982VCibVKPIXVljmf3ddUqib0eSzQ/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

另两个流水线模版包含了更完整的 CI / CD 流水线构建示例，但内容相对复杂，欢迎大家线下自行选用进行体验！

下面我们尝试用图形编辑器复现前一小节的两个操作步骤，即拉起代码，并打印一条 Hello World 消息。首先，我们点击左侧面板的`+`按钮，然后选中添加出来的一个阶段块。

![图片](https://mmbiz.qpic.cn/mmbiz_png/u5Pibv7AcsEX7oLnRfJOe0GpdlCqUZjMtb4WfGEqfJNFYqQrLyBX78KpFictJ4sZNsn3ga0ibNzuwAl6a62MVtB5g/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

接着我们点击左侧阶段块上的「+ 添加步骤」，并在右侧刷出的「添加步骤」面板中选则`git`步骤，在弹出的对话框中填入我们示例代码仓库的地址 HTTP Git 地址（如`[http://gitlab.example.com/root/nodejs-demo.git](http://gitlab.example.com/root/nodejs-demo.git "http://gitlab.example.com/root/nodejs-demo.git")`），凭证选用之前创建的`gitlab-root`，分支填写`master`。

![图片](https://mmbiz.qpic.cn/mmbiz_png/u5Pibv7AcsEX7oLnRfJOe0GpdlCqUZjMtUJHANCQibxTbwzM3ibrs0I64V4dPTRB9AdSZ8Lo5bV7Xztvzr37pQOtw/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

完成后我们依样画葫芦，再次添加一个`打印消息`步骤并填入`Hello World!`作为内容，最后得到如下图所示的整体效果。

![图片](https://mmbiz.qpic.cn/mmbiz_png/u5Pibv7AcsEX7oLnRfJOe0GpdlCqUZjMt0OSMDvlPnKfR80ibUSlDkqSrhGJrrDqB0UqnSoYGMXdMMOBe82SYgSg/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

完成编辑后「确定」再「确定」来保存流水线，回到详情页面后，可以通过右上角的「运行」按钮来执行流水线。

![图片](https://mmbiz.qpic.cn/mmbiz_png/u5Pibv7AcsEX7oLnRfJOe0GpdlCqUZjMtz86a8Xfa7SJD6YlAnCEZYY3diadicQ75D28AUtp8jypibcBrvQ8dpmRJg/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

运行成功后可以再次查看流水线运行记录，并查看运行日志，得到如下图所示结果。

![图片](https://mmbiz.qpic.cn/mmbiz_png/u5Pibv7AcsEX7oLnRfJOe0GpdlCqUZjMtfYW3jU6jb0rWibJz0BD5WozK2CibCdOLxqIZ5FcFLYeJVvmwCDttNiahA/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

## 【番外】使用 SSH 访问 Kubernetes 集群中的 GitLab 代码仓库

前文介绍的代码仓库的访问方式都是通过 HTTP 的形式，但现实工作中我们最常用的还是 SSH 的访问方式，那是否可以直接通过`git clone git@gitlab.example.com:root/nodejs-demo.git`这样的方式来拉取和推送代码呢？

答案是肯定的：可以！但是这里有一个大坑需要注意 —— 默认 SSH 用的是`22`端口，但多了一层 Kubernetes 网络之后，不管是否使用这个默认端口都需要处理好 GitLab 如何对外暴露 SSH 服务。

假设我们可以接受重新绑定一个端口来使用 GitLab SSH，那么可以这样操作：

- 首先，我们回到 GitLab 部署项目中，找到 `gitlab-shell`服务并为它开放 NodePort 外部访问端口

![图片](https://mmbiz.qpic.cn/mmbiz_png/u5Pibv7AcsEX7oLnRfJOe0GpdlCqUZjMtoFwxB7ibkiacpHVDLfn2WNgN5c74icehM7zJ8jliaibr9DEGHXq30QDYhZA/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

- 基于这个端口，把 Git 访问的地址都改为`ssh://git@<gitlab-url>:<gitlab-shell-port>/<username>/<repo>.git`的形式，例如`ssh://git@gitlab.example.com:32222/root/nodejs-demo.git`

> 写在最后：感谢您这么耐心的看完这整个教程！如果您觉得这些内容如果自己部署起来确实有点挑战，那推荐可以看看 **极狐 GitLab**[11] 和 **KubeSphere Cloud**[12] 的一些商业产品，让专业的人做专业的事儿，释放大家的时间更好的打磨自己的业务产品。也期待看到更多的开源社区和商业产品的良性互动，一起推动我们国内的软件产业在虎年 “虎踞龙盘今胜昔，天翻地覆慨而慷”！

### 引用链接

[1]在 Linux 安装 KubeSphere: *https://kubesphere.com.cn/docs/quick-start/all-in-one-on-linux/*

[2]在 Kubernetes 安装 KubeSphere: *https://kubesphere.com.cn/docs/quick-start/minimal-kubesphere-on-k8s/*

[3]启用可插拔组建 · KubeSphere DevOps 系统: *https://kubesphere.com.cn/docs/pluggable-components/devops/*

[4]Jenkins: *https://jenkins.io/*

[5]Binary-to-Image (B2I): *https://kubesphere.com.cn/docs/project-user-guide/image-builder/binary-to-image/*

[6]Source-to-Image (S2I): *https://kubesphere.com.cn/docs/project-user-guide/image-builder/source-to-image/*

[7]极狐 GitLab Helm Chart 快速开始指南: *https://docs.gitlab.cn/charts/#%E6%9E%81%E7%8B%90gitlab-helm-chart-%E5%BF%AB%E9%80%9F%E5%BC%80%E5%A7%8B%E6%8C%87%E5%8D%97https://docs.gitlab.cn/charts/#%E6%9E%81%E7%8B%90gitlab-helm-chart-%E5%BF%AB%E9%80%9F%E5%BC%80%E5%A7%8B%E6%8C%87%E5%8D%97*

[8]完整属性列表: *https://docs.gitlab.cn/charts/#%E5%AE%8C%E6%95%B4%E5%B1%9E%E6%80%A7%E5%88%97%E8%A1%A8*

[9]技术博客: *https://www.yuque.com/serviceup/cloud-native-talks/apisix-in-kubesphere*

[10]使用图形编辑面板创建流水线: *https://kubesphere.com.cn/docs/devops-user-guide/how-to-use/create-a-pipeline-using-graphical-editing-panel/*

[11]极狐 GitLab: *https://gitlab.cn/*

[12]KubeSphere Cloud: *https://kubesphere.cloud/*