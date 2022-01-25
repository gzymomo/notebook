- [prometheus可视化方式配置告警分发到不同的钉钉群](https://juejin.cn/post/7056356598402252831)

# 前言

prometheus进行钉钉告警的解决方案其实比较多，本文所用也只是其中一种，如果有同学刚好也是采用该方案，希望有所帮助。

这是我目前常用的一套监控告警工具：

1. prometheus: [Installation | Prometheus](https://link.juejin.cn?target=https%3A%2F%2Fprometheus.io%2Fdocs%2Fprometheus%2Flatest%2Finstallation%2F)
2. alert manager: [Configuration | Prometheus](https://link.juejin.cn?target=https%3A%2F%2Fprometheus.io%2Fdocs%2Falerting%2Flatest%2Fconfiguration%2F)
3. prometheus-webhook-dingtalk: [github.com/timonwong/p…](https://link.juejin.cn?target=https%3A%2F%2Fgithub.com%2Ftimonwong%2Fprometheus-webhook-dingtalk)

# 监控拓扑

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/f9d3b84d29b74f60a1b5e718087b9295~tplv-k3u1fbpfcp-watermark.awebp)

prometheus将告警信息最终发到钉钉群里。

关于这套监控告警方案，业内应该还是有一些同学在用，因为最初这个方案也是我在网上了解到的，后来在自己的业务场景中进行针对性改良后并落地使用。

# 告警给不同的机器人

webhook-dingtalk接收到alert-manager发的告警信息后，进行美化（我主要就是用它做个告警美化，比较转换成markdown格式）后，将告警分发给钉钉机器人。

我之前也写过一篇文章，如何分发告警给不同的机器人： [prometheus配置告警分发到不同的钉钉群!](https://juejin.cn/post/7055915776544342047)

但是这个地方有个比较麻烦的地方，这些配置都是写在配置文件中，当然可以热加载，但是如果想将不同的告警信息分发给不同的机器人的时候，是极不方便的。

比如，我做了rocketmq的告警，但是不同的项目用的消费组不同，所属项目的负责人也只关心各自用到的消费组的消费积压告警，而做为我们专门负责这个消息平台的人来说，却是想在自己的告警群里收到所有的告警信息。然后消费组有很多个，对应的项目组也有很多个，不同的告警要发给不同的项目组，这就很麻烦了。

# 解决方案

给大家推荐一个工具：[webhook-dingtalk-dispatcher](https://link.juejin.cn?target=https%3A%2F%2Fgithub.com%2Fxxd763795151%2Fwebhook-dingtalk-dispatcher)

可以自定义将哪些告警通知给哪些钉钉机器人。

如下： ![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/3141a559ac1840c4b34058b9007026d5~tplv-k3u1fbpfcp-watermark.awebp)

上面示例中我配置了3条告警规则。

1. 如果告警信息里包含配置的任一个关键字，对应的机器人便会收到告警
2. 如果告警信息里包含了配置的所有关键字，对应的机器人才会收到告警
3. 发过来的所有告警这个机器人都会收到 

# 新的告警拓扑

加入webhook-dingtalk-dispatcher后，新的告警拓扑如下：

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/cccac01fca344474875c36b88d8f3336~tplv-k3u1fbpfcp-watermark.awebp)

看起来还是挺复杂的，其实 webhook-dingtalk-dispatcher可以做个优化，也支持美化告警信息，这样就可以把webhook-dingtalk替换掉了，不过目前不支持。

# webhook-dingtalk-dispatcher使用

## 下载

下载地址：[github.com/xxd76379515…](https://link.juejin.cn?target=https%3A%2F%2Fgithub.com%2Fxxd763795151%2Fwebhook-dingtalk-dispatcher%2Freleases%2Fdownload%2F1.0.0%2Fwebhook-dingtalk-dispatcher.zip)

## 部署

1.将安装包下载下来然后解压缩。

2.配置文件:config/application.yml，如果需要修改端口或者token信息的话，在这里改，默认不改也行。

3.启动/停止

```bash
# 启动
sh bin/start.sh
# 停止
sh bin/shutdown.sh
复制代码
```

4.配置prometheus-webhook-dingtalk，修改prometheus-webhook-dingtalk的配置文件：config.yml

**注意是修改prometheus-webhook-dingtalk的配置文件，不是这个webhook-dingtalk-dispatcher的配置文件。**

本来这个地方是配置钉钉机器人的地址，现在把它改成webhook-dingtalk-dispatcher的地址即可，示例如下：

```yaml
targets:
  webhook:
    url: http://localhost:7006/dispatcher?access_token=1234567890
复制代码
```

注意后面跟了个参数access_token，这个access_token的值是在webhook-dingtalk-dispatcher的配置文件里配置的，默认就是1234567890。

## 测试

配置完成，也启动webhook-dingtalk-dispatcher了，在浏览器访问：[http://localhost:7006](https://link.juejin.cn?target=http%3A%2F%2Flocalhost%3A7006%2F)

然后点击新增按钮增加一个机器人告警配置：

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/711dff1fc47049dd839455865b39dee5~tplv-k3u1fbpfcp-watermark.awebp)

配置完也可以点击一个测试连接，看下钉钉机器人是否收到了告警信息，检查下配置的是否正确。

最后点击提交即可。 