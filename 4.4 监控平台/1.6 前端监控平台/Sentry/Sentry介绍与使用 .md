- [Sentry介绍与使用](https://juejin.cn/post/6844904143090352135)

# 一、sentry介绍

## 1.什么是sentry?

当我们完成一个业务系统的上线时，总是要观察线上的运行情况，对于每一个项目，我们都没办法保证代码零BUG、零报错，即便是经历过测试，因为测试永远无法做到100%覆盖，用户也不会总是按照我们所预期的进行操作，在上线后也会出现一些你预料不到的问题，而这种情况下，广大的用户其实才是最好的测试者。当生产环境中产生了一个 bug 时，如何做到迅速报警，找到问题原因，修复后又如何在线上验证？此时我们需要一个高效的错误监控系统。sentry扮演着一个错误收集的角色，将你的项目和sentry结合起来，无论谁在项目使用中报错，sentry都会第一次时间通知开发者，我们需要在系统异常时主动对其进行收集上报，出现了什么错误，错误出现在哪，帮你记录错误，以制定解决方案并进行优化迭代。

sentry是一个基于Django构建的现代化的实时事件日志监控、记录和聚合平台,主要用于如何快速的发现故障。支持几乎所有主流开发语言和平台,并提供了现代化UI,它专门用于监视错误和提取执行适当的事后操作所需的所有信息,而无需使用标准用户反馈循环的任何麻烦。官方提供了多个语言的SDK.让开发者第一时间获悉错误信息,并方便的整合进自己和团队的工作流中.官方提供saas版本免费版支持每天5000个event.

sentry支持自动收集和手动收集两种错误收集方法.我们能成功监控到vue中的错误、异常，但是还不能捕捉到异步操作、接口请求中的错误，比如接口返回404、500等信息，此时我们可以通过Sentry.caputureException()进行主动上报。使用sentry需要结合两个部分，客户端与sentry服务端；客户端就像你需要去监听的对象，比如公司的前端项目，而服务端就是给你展示已搜集的错误信息，项目管理，组员等功能的一个服务平台。

这个平台可以自己搭建，也可以直接使用sentry提供的平台（注册可用），当然如果是公司项目，当然推荐自己搭建.

## 2.什么是DSN？

DSN是连接客户端(项目)与sentry服务端,让两者能够通信的钥匙；每当我们在sentry服务端创建一个新的项目，都会得到一个独一无二的DSN，也就是密钥。在客户端初始化时会用到这个密钥，这样客户端报错，服务端就能抓到你对应项目的错误了。之前版本的sentry对于密钥分为公钥和私钥，一般前端用公钥(DSN(Public))，但是现在的版本舍弃了这种概念，只提供了一个密钥。

## 3.什么是event

每当项目产生一个错误，sentry服务端日志就会产生一个event，记录此次报错的具体信息。一个错误，对应一个event。

## 4.什么是issue

同一类event的集合，一个错误可能会重复产生多次，sentry服务端会将这些错误聚集在一起，那么这个集合就是一个issue。

## 5.什么是Raven

raven是sentry官方针对vue推荐的插件,我们在项目中初始化，让项目链接sentry的前提，都得保证已经引入了raven-js，以及我们手动提交错误的各类方法，都由Raven提供.

## 6.监控原理

1.传统的前端监控原理分为异常捕获和异常上报。一般使用onerror捕获前端错误：

```
window.onerror = (msg, url, line, col, error) => {
  console.log('onerror')
  // TODO
}
复制代码
```

2.但是onerror事件无法捕获到网络异常的错误(资源加载失败、图片显示异常等)，例如img标签下图片url 404 网络请求异常的时候，onerror无法捕获到异常，此时需要监听unhandledrejection。

```
window.addEventListener('unhandledrejection', function(err) {
  console.log(err)
})
复制代码
```

3.捕获的异常如何上报？常用的发送形式主要有两种: 通过 ajax 发送数据(xhr、jquery...) 动态创建 img 标签的形式

```
function report(error) {
  var reportUrl = 'http://xxxx/report'
  new Image().src = reportUrl + '?error=' + error
}
复制代码
```

# 二、实际项目中使用

## 1.注册sentry,本文示例采用Saas版

地址: [sentry.io/signup/](https://link.juejin.cn?target=https%3A%2F%2Fsentry.io%2Fsignup%2F)

输入有效邮箱,需要激活



![img](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2020/4/28/171bf7f9645654ff~tplv-t2oaga2asx-watermark.image)



在激活页面中选择JavaScript项目类型,选中后点击创建项目



![img](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2020/4/28/171bf7fcde2cdb84~tplv-t2oaga2asx-watermark.image)



创建后系统会自动创建SDK,保存好红色框里的马赛克



![img](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2020/4/28/171bf7fec38d44b0~tplv-t2oaga2asx-watermark.image)



## 2.安装Raven.js

```
npm install raven-js --save
复制代码
```

在项目中引入 记得设置release,Release名在第6步中产生,本文用的统一staging@1.0.1

```
Raven.config('https://xxxxx.ingest.sentry.io/xxxx’,//这里就是马赛克信息
{ release:<Release名> })  
.addPlugin(RavenVue, Vue)
.install()
复制代码
```

## 3.安装sentry-cli

```
npm i @sentry/cli -g 
复制代码
```

或

```
npm install sentry-cli-binary -g
复制代码
```

安装完成后可通过 sentry-cli -V 查看版本



![img](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2020/4/28/171bf8014105a2b5~tplv-t2oaga2asx-watermark.image)



## 4.获取API Token

点击Sentry页面左下角头像，

选择API > Auth Tokens

点击右上角”Create New Token”按钮,

勾选 project:write权限,

确认即可生成Token



![img](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2020/4/28/171bf8041b3a05b7~tplv-t2oaga2asx-watermark.image)



## 5.登录sentry

私有化部署方式登录 sentry-cli --url [https://myserver](https://link.juejin.cn?target=https%3A%2F%2Fmyserver) login Saas方式 sentry-cli login 回车后输入第2步中的token.Saas版不需要指定URL,token就是上一步中创建的token



![img](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2020/4/28/171bf805cf722b2b~tplv-t2oaga2asx-watermark.image)



## 6.创建.sentryclirc文件

登录成功后会提示创建了一个.sentrylrc文件,根据提示路径,找到并打开 通常我们都会在项目根目录执行以上命令,这样文件会自动生成到项目根目录下



![img](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2020/4/28/171bf8073a953f43~tplv-t2oaga2asx-watermark.image)



## 7.配置.sentryclirc

补充org和project信息到.sentrylrc

```
[auth]
token=YOUR API TOKEN
 
[defaults]
url=服务器
org=组织
project=项目
复制代码
```

- 服务器:Saas版填 [sentiry.io](https://link.juejin.cn?target=https%3A%2F%2Fsentiry.io)
- 组织:点击左上角头像选择OrganizationSetting,在右侧General面板的Name选项
- 项目:点击左侧菜单Projects,选择找的项目卡片,顶部Title就是项目名

如下是我的配置信息



![img](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2020/4/28/171bf809a64be3e0~tplv-t2oaga2asx-watermark.image)



## 8.创建release

创建Release:

```
sentry-cli releases -o 组织 -p 项目 new staging@1.0.1
复制代码
```

删除 Release:

```
sentry-cli releases -o 组织 -p 项目 delete staging@1.0.1
复制代码
```

## 9.上传sourcemap

```
sentry-cli releases -o <组织名> -p <项目名> files <Release名> upload-sourcemaps 	--url-prefix <线上资源URI> <本地资源URI>
复制代码
```

上传中



![img](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2020/4/28/171bf80bb6640b6e~tplv-t2oaga2asx-watermark.image)



上传成功



![img](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2020/4/28/171bf80d00b2da33~tplv-t2oaga2asx-watermark.image)



## 10.触发异常

以vue项目为例 login.vue

Template:



![img](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2020/4/28/171bf80f365dea3c~tplv-t2oaga2asx-watermark.image)

Script:





![img](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2020/4/28/171bf81335defd6f~tplv-t2oaga2asx-watermark.image)



myUndefinedFunction方式没有预先定义,以此引发异常



![img](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2020/4/28/171bf818d8089261~tplv-t2oaga2asx-watermark.image)

点击按钮输出异常,sentry会自动上报此次事件,我们去后台查看.





![img](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2020/4/28/171bf8200acaae16~tplv-t2oaga2asx-watermark.image)



## 11.定位问题

系统接收到异常信息



![img](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2020/4/28/171bf8229c961389~tplv-t2oaga2asx-watermark.image)

展开后找到异常信息所在源码位置,因为有sourcemap,所以会直接显示源码信息

![img](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2020/4/28/171bf825acd9ee4b~tplv-t2oaga2asx-watermark.image)

异常信息发生在 /src/views/passport/login/login.vue组件第49行代码处,下图为源码





![img](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2020/4/28/171bf82a535e1016~tplv-t2oaga2asx-watermark.image)



## 12.指派、解决问题

指派解决该问题的成员



![img](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2020/4/28/171bf82be3c95721~tplv-t2oaga2asx-watermark.image)



处理完后标记下状态,将不会显示到默认issues列表中,有些第三方插件产生的Issue也可以选择忽略



![img](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2020/4/28/171bf82d35eaff1e~tplv-t2oaga2asx-watermark.image)



以上操作就可以实现一套完整的线上监控体系了,整个 Sentry 的接入不算复杂，只是需要对她做一系列的配置，还有一些概念性的东西需要理解

所产生的issue可以直接分配到对应开发者上,类似bug系统的使用.有了实际用户的参与测试,就可以逐渐完善线上工程健康度了.

可能有些地方说的不够明确,详细参见[docs.sentry.io/](https://link.juejin.cn?target=https%3A%2F%2Fdocs.sentry.io)


作者：XYZC企服解决方案供应商
链接：https://juejin.cn/post/6844904143090352135
来源：稀土掘金
著作权归作者所有。商业转载请联系作者获得授权，非商业转载请注明出处。