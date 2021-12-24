- [超详细，自动化测试接入Jenkins+Sonar质量门禁实践](https://www.cnblogs.com/jinjiangongzuoshi/p/15183533.html)

## 1. 什么是SonarQube

`SonarQube`是一个开源的代码质量管理系统，用于检测代码中的错误，漏洞和代码规范，通过插件的机制，

可以基于现有的`Gitlab`、`Jenkins` 集成、以便在项目拉取后进行连续的代码检查。

**优点：**

◆ 支持众多计算机编程语言

◆ 通过插件机制能集成IDE、Jenkins、Git等

◆ 内置大量常用代码检查规则

◆ 支持定制开发规则

◆ 可视化界面

◆ 支持从可靠性、安全性、可维护性、覆盖率、重复率等 方面分析项目

具体的配置及文档可以访问下面的链接查看：

```
https://www.sonarqube.org/downloads/ 
https://docs.sonarqube.org/latest/analysis/scan/sonarscanner/ 
```

## 2. Jenkins插件安装及配置

`Sonarqube`想要与`Jenkins`集成，需要安装相应的插件来支持。

在插件管理中搜索名为`Sonarqube Scanner for Jenkins`的插件 并安装。

安装好插件后，还需要配置相应的服务和工具信息：

### 2.1. 系统设置->SonarQube servers

- name：可自定义）
- server url：这个地址就是你sonar服务所在的地址
- token：在sonar项目中生成的token

![image-20211225000618119](https://gitee.com/er-huomeng/img/raw/master/img/image-20211225000618119.png)

### 2.2. 全局工具配置》SonarQube Scanner

建议不采用自动安装，使用手动下载配置好的sonar scanner

- name：自定义sonar scanner名称，建议使用sonar-scanner
- SONAR_RUNNER_HOME：sonar scanner所在的家目录

![img](https://gitee.com/er-huomeng/img/raw/master/img/008i3skNgy1gs08q33xl3j30h509waaa.jpg)

## 3. 自由风格的job使用sonar

### 3.1 配置代码仓库地址：

![img](https://gitee.com/er-huomeng/img/raw/master/img/008i3skNgy1gs08qyrq4mj314l0emmxp.jpg)

### 3.2 勾选sonarqube 服务并选择token:

![img](https://gitee.com/er-huomeng/img/raw/master/img/008i3skNgy1gs08rf8fjfj30qq0b9aav.jpg)

### 3.3 在构建中添加Exeute SonarQube Sanner

![img](https://gitee.com/er-huomeng/img/raw/master/img/008i3skNgy1gs08rtudv3j313w0j2wf1.jpg)

这里可以使用两种方式：

- a. 直接将sonar-project.properties配置内容写到 Analysis properties 中
- b. 将配置好的sonar-project.properties文件放置在代码目录中，在 Path to project properties 配置相应的文件名

**建议使用第二种方式来管理**
 我配置的`sonar-project.properties`文件如下：

![img](https://tva1.sinaimg.cn/large/008i3skNgy1gs08ss2bg1j3078034glg.jpg)

保存好后，就可以来构建了。构建后项目页面可以直接跳转到sonarqube服务查看。

![img](https://gitee.com/er-huomeng/img/raw/master/img/008i3skNgy1gs08t3ufy0j30jm0ax75a.jpg)

![img](https://tva1.sinaimg.cn/large/008i3skNgy1gs08te1rj4j30r8048glu.jpg)

## 4. pipeline流水线使用sonar

### 4.1 构建一个流水线job，流水线pipeline script如下编写：

```
pipeline {
    agent any

    stages {
        stage('拉取代码') {
            steps {
                git credentialsId: 'gitee', url: 'https://gitee.com/dx0001/work.git'
            }
        }
        stage('静态代码静态扫描') {
            steps {
                withSonarQubeEnv('sonarqube'){
                    bat "sonar-scanner"
                }
            }
        }
    }    
```

注意： 这里的名称是在Jenkins中系统管理--sonarqube servers添加的名称
 同样的，设置好job后就可以构建进行代码扫描了。

## 5. 接入Sonar质量门禁

通过上面的job，只是代码扫描可能无法满足日常的情况，当扫描的结构不满足时我可能就不进行后面的步骤了，这样的情况，我们就需要接入质量门禁的方式来实现。

### 5.1 在sonar服务端的质量阀中设置质量门禁，添加要运用的项目

质量配置->质量阀

![img](https://gitee.com/er-huomeng/img/raw/master/img/008i3skNgy1gs08um46hsj310c0cl0t4.jpg)

这里可以添加指标来定义通过扫描的条件。然后将设置的质量阀分配给要扫描的项目。

### 5.2 在sonar服务端的配置里面添加网络调用hook

配置->网络调用

![img](https://gitee.com/er-huomeng/img/raw/master/img/008i3skNgy1gs08vd29toj310b06raae.jpg)

这里添加Jenkins调用的地址，用来回调扫描的结果。URL配置为：Jenkins地址+/sonarqube-webhook

### 5.3 流水线改造

```
pipeline {
    agent any

    stages {
        stage('拉取代码') {
            steps {
                git credentialsId: 'gitee', url: 'https://gitee.com/dx0001/work.git'
            }
        }
        stage('静态代码静态扫描') {
            steps {
                withSonarQubeEnv('sonarqube'){
                    bat "sonar-scanner"
                }
            }
        }
        stage('检查结果分析') {
            steps {
                script{
                    timeout(5){
                        def qg=waitForQualityGate()
                        echo "结果状态：${qg.status}"
                        if(qg.status!='OK')
                            error '未达到代码门禁要求！'
                    }
                }
            }
        }
    }
}
```

在上面的流水线的job上增加一个“检查结果分析”的步骤，使用`waitForQualityDate()`的方法来获取扫描是否通过质量阀的状态值。最后使用if条件来判断，不通过时则使用`“error”`来中断流程，实现质量门禁的功能。