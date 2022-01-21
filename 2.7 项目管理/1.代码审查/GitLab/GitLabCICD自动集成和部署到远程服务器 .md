- [GitLabCI/CD自动集成和部署到远程服务器](https://mp.weixin.qq.com/s/QBhEvf2uSrOVmapaYKCigQ)

![image-20220121203202822](https://gitee.com/er-huomeng/img/raw/master/img/image-20220121203202822.png)

目的是通过一个示例应用程序对GitLab CI/CD进行友好的了解，该应用程序有助于入门，而无需阅读所有GitLab文档。

持续集成的工作原理是：将小的代码块-commits-推送到Git存储库中托管的应用程序的代码库中，并且每次推送时，都要运行脚本管道来构建，测试和验证代码更改，然后再将其合并到主分支中。

持续交付和部署包括进一步的CI，可在每次推送到存储库默认分支时将应用程序部署到生产环境。这些方法使您可以在开发周期的早期发现错误和错误，从而确保部署到生产环境的所有代码均符合为应用程序建立的代码标准。

使用Gitlab CI/CD的主要好处之一是，您无需使用许多第三方插件和工具来创建工作流的繁琐过程。GitLab CI/CD由位于存储库根目录的一个名为`.gitlab-ci.yml`的文件配置。该文件中设置的脚本由GitLab Runner执行。

要将脚本添加到该文件，需要按照您的应用程序适合的顺序组织它们，并通过执行的测试。为了可视化该过程，请想象添加到配置文件中的所有脚本与在计算机的终端上运行的命令相同。

这些脚本被分组为**job**，它们共同组成了一个**管道。**

## 流水线 

我们可以根据需要构造管道，因为YAML是一种序列化的人类可读语言

建立3条管道的假设：

- **Project Pipeline** 将安装依赖项，运行linters，以及处理该代码的所有脚本。
- **持续集成管道**运行自动化测试并构建代码的分布式版本。
- **部署管道将**代码部署到指定的云提供商和环境。

管道执行的步骤称为**作业**。当您通过这些特征将一系列作业分组时，这称为**阶段**。作业是管道的基本构建块。可以将它们分为多个阶段，也可以将各个阶段分为多个管道。

![image-20220121203217152](https://gitee.com/er-huomeng/img/raw/master/img/image-20220121203217152.png)



根据上图，我们来配置一个基本的管道实例。以下是`.gitlab-ci文件`

```yaml
stages:
  - build
  - test
  - deploy

image: alpine

build_a:
  stage: build
  script:
    - echo "This job builds something."

build_b:
  stage: build
  script:
    - echo "This job builds something else."

test_a:
  stage: test
  script:
    - echo "This job tests something. It will only run when all jobs in the"
    - echo "build stage are complete."

test_b:
  stage: test
  script:
    - echo "This job tests something else. It will only run when all jobs in the"
    - echo "build stage are complete too. It will start at about the same time as test_a."

deploy_a:
  stage: deploy
  script:
    - echo "This job deploys something. It will only run when all jobs in the"
    - echo "test stage complete."

deploy_b:
  stage: deploy
  script:
    - echo "This job deploys something else. It will only run when all jobs in the"
    - echo "test stage complete. It will start at about the same time as deploy_a."
```

在此层次结构中，所有三个组件都被视为三个不同的阶段[{build_a，build_b}，{test_a，test_b}，{deploy_a，deploy_b}]。主要阶段-build，-test和-deploy是阶段，这些部分下的每个项目都是一项工作。

作业将根据**stages**指令中列出的顺序执行。

您可以使用**only**指令使deploy_a部署到登台服务器，将deploy_b部署到生产服务器，当在**only**指令下将提交推送到分支时，将触发作业

```yaml
deploy-production:
stage: deploy
script:
     - ./deploy_prod.sh
only:
     - master
```

> **注意**：管道的名称是自定义的。您可以重命名`deploy-production`为对您有意义的名称。

在将YAML文件添加到存储库的根目录之前，可以使用CI Lint编写和验证您的YAML文件。您也可以通过使用UI中可用的模板之一来开始使用。您可以通过创建新文件，选择适合您的应用程序的模板并根据需要进行调整来使用它们：

![image-20220121204018804](https://gitee.com/er-huomeng/img/raw/master/img/image-20220121204018804.png)



将文件保存到存储库的根目录后，GitLab会将其检测为CI/CD配置并开始执行。如果转到左侧边栏*CI/CD>管道*，则会发现作业卡住，如果单击其中之一，则会看到以下问题：

![image-20220121204025274](https://gitee.com/er-huomeng/img/raw/master/img/image-20220121204025274.png)



## GitLabRunner 

GitLab Runner是一个开源项目，用于运行您的作业并将结果发送回GitLab。它与GitLab CI/CD结合使用，GitLab CI/CD是GitLab随附的用于协调作业的开源持续集成服务。

可以在GNU/Linux，macOS，FreeBSD和Windows上安装和使用GitLab Runner。您可以使用Docker安装它，手动下载二进制文件，或使用GitLab提供的rpm/deb软件包的存储库。在此博客中，我将其作为docker服务安装

在开始之前，请确保已安装Docker。要`gitlab-runner`在Docker容器中运行，需要确保在重新启动容器时配置不会丢失。在安装时要求提供映像时，我键入了alpine:3.7，它轻巧且足以满足要求。

注意：如果使用`*session_server*`，则还需要`*8093*`通过添加`*-p 8093:8093*`到`*docker run*`命令来公开端口。

### 注册Runner

最后一步是注册一个新的Runner。在注册之前，GitLab Runner容器不会接收任何作业。完成注册后，结果配置将被写入您选择的配置卷（例如`/srv/gitlab-runner/config`），并由运行器使用该配置卷自动加载。

要使用Docker容器注册Runner：

1. 运行register命令：

- 对于本地系统卷安装：

```
docker run --rm -it -v /srv/gitlab-runner/config:/etc/gitlab-runner gitlab/gitlab-runner register
```

> 如果`*/srv/gitlab-runner/config*`在安装过程中使用了其他配置卷，则应使用正确的卷更新命令。

- 对于Docker卷挂载：

```
docker run --rm -it -v gitlab-runner-config:/etc/gitlab-runner gitlab/gitlab-runner:latest register
```

2.运行register命令：

```
Please enter the gitlab-ci coordinator URL (e.g. https://gitlab.com) 
https://gitlab.com
```

3.输入您获得的令牌来注册跑步者：

```
Please enter the gitlab-ci token for this runner
xxx
```

您可以从“设置”>“ CI / CD”>“ Runners”>“展开”>“手动设置特定的Runner”获取URL和令牌

现在该重新启动阻塞的管道了，然后您可以发现它已成功执行。

![image-20220121204034017](https://gitee.com/er-huomeng/img/raw/master/img/image-20220121204034017.png)



## 部署方式 

我将在这里提到使用SSH通过YAML脚本访问远程服务器

### 添加SSH密钥

当您的CI/CD作业在Docker容器中运行（意味着环境已包含在内）并且您想要在私有服务器中部署代码时，您需要一种访问它的方法。这是SSH密钥对派上用场的地方。

您首先需要创建一个SSH密钥对。**请勿**在SSH密钥中添加密码，否则`before_script`将在YAML文件中提示输入密码。

在这里，我生成SSH RSA密钥

```
ssh-keygen -t rsa -b 4096 -C "example"
```

`-C`如果您有多个标记并想知道是哪个标记，则该标志会在键中添加注释。它是可选的。

之后，我们需要复制私钥（该私钥将用于连接到我们的服务器），以便能够自动化我们的部署过程：

```
# Copy the content of public key to authorized_keys
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
```

使用以下命令显示的内容`id_rsa`并复制它：

```
cd .ssh && cat id_rsa
```

- 转到GitLab UI边栏>设置> CI/CD>变量>展开
- 添加一个名为SSH_PRIVATE_KEY的变量，然后在“值”字段中，粘贴刚从服务器复制的私钥（如果是AWE EC2，它将是/.pem文件的内容）

![image-20220121204040479](https://gitee.com/er-huomeng/img/raw/master/img/image-20220121204040479.png)



### 添加部署密钥

部署密钥允许对服务器上克隆的存储库进行只读或读写（如果启用）访问。

- 转到GitLab UI边栏>设置>存储库>部署密钥>扩展
- 创建标题，然后在“ **密钥”**字段中粘贴现有内容`id_rsa.pub`

```
cd .ssh && cat id_rsa.pub
```

![image-20220121204047316](https://gitee.com/er-huomeng/img/raw/master/img/image-20220121204047316.png)



编写YAML文件：

```yaml
# Includes deployment pipeline only
image: alpine:3.7
stages:
    - deploy
    
before_script:
  ##
  ## Optionally, if you will be using any Git commands, set the user name and
  ## and email.
  ##
  #- git config --global user.email "user@example.com"
  #- git config --global user.name "User name"

deploy_production:
    stage: deploy
    before_script:
        - apk add openssh-client # Add SSH client for alpine 
        - eval $(ssh-agent -s) # Run the SSH client 
        # Adding environment's variable SSH_PRIVATE_KEY to the SSH client's agent that manages the private keys
        - echo "$SSH_PRIVATE_KEY" | tr -d '\r' | ssh-add -
        # Create the SSH directory and give it the right permissions
        - mkdir -p ~/.ssh
        - chmod 700 ~/.ssh
    script:
        # Connecting to the server using SSH and executing commands like pulling updates to the cloned repo
        - ssh -o StrictHostKeyChecking=no username@host_ip_address "cd /project && git pull"
        # -o StrictHostKeyCheking=no is to disable strict host key checking in SSH
    only:
        - master
```

默认情况下，alpine不附带SSH客户端。这就是为什么我使用alpine软件包管理器添加SSH客户端的原因。如果您在运行程序注册或YAML配置中未使用alpine，则必须根据自己的Linux系统更改命令。

![image-20220121204054483](https://gitee.com/er-huomeng/img/raw/master/img/image-20220121204054483.png)