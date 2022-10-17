- [【DataHub】 现代数据栈的元数据平台--如何针对DataHub UI 前端展示进行汉化_九层之台起于累土的博客-CSDN博客_前端汉化](https://blog.csdn.net/m0_54252387/article/details/125757866)

DataHub的组件datahub-frontend-react是DataHub UI的React版本，也是DataHub客户端体验的生产版本。

**前端是完全独立的。**

**目前DataHub前端是全英文的，并且都是专业术语如Ingestion，让不熟悉数据治理的人很难使用。 公司领导想基于DataHub进行二开，并针对前端进行汉化，方便团队成员及用户的使用。**

本文讲解如何针对DataHub UI 前端展示进行汉化，并针对汉化遇到的问题进行总结。

DataHub UI 前端展示汉化后效果如下：
![在这里插入图片描述](https://img-blog.csdnimg.cn/53c12c254bbc4743aa06746d3481b6cd.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBA5p625p6E5biI5b-g5ZOl,size_20,color_FFFFFF,t_70,g_se,x_16)

## DataHub UI 前端展示汉化步骤

## DataHub前端的设计目标

DataHub前端的设计目标如下：

- 可配置性：可以根据公司的需求针对一些方面进行定制，包括可配置的主题/样式、显示和隐藏特定的功能、自定义版权和logo等等。
- 可扩展性：扩展DataHub的功能应该尽可能简单，如可以方便的针对现有实体进行扩展、添加新实体，并且有详细的文档支撑

## 前端文件存放在哪？

DataHub的组件datahub-frontend-react负责前端的展示，

前端文件存放在容器`linkedin/datahub-frontend-react:v0.8.26` 中的/datahub-frontend/lib/datahub-frontend-assets.jar 中

将此文件从docker 容器中复制出来，使用命令如下：
`docker cp datahub-frontend-react:/datahub-frontend/lib/datahub-frontend-assets.jar ./`

打开此jar包，文档目录如下：
![在这里插入图片描述](https://img-blog.csdnimg.cn/a2769897bc0e4d8b948ed994fecbaaad.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBA5p625p6E5biI5b-g5ZOl,size_9,color_FFFFFF,t_70,g_se,x_16)

## 如何针对前端文件进行打包

datahub-web-react是一个React项目，使用yarn进行依赖管理、craco进行构建打包

步骤如下：

- 参考 DataHub: 现代数据栈的元数据平台–如何搭建本地开发环境 ，搭建DataHub的开发环境
- cd datahub-web-react所在的目录，如`E:\gitcodes\datahub\datahub-web-react`
- 修改如下配置文件：
  - package.json ，在依赖中增加：`"cross-env": "^5.2.0",` ，并在所用的scripts中的变量设置前添加：`cross-env`，如`cross-env CI=false REACT_APP_MOCK=false`
  - src/setupProxy.js，如果想在本地访问其它服务器上的后端服务，则需要将`target: 'http://localhost:9002',` 修改为 `target: 'http://ip:9002',`
- 安装react的全部依赖 `yarn install`，【注意：运行前请将yarn源设置为国内的源,如`yarn config set registry https://registry.npm.taobao.org/`】
- 打包项目 `yarn build`
- 在本化运行项目 `yarn run start` 或 `yarn run start:mock`
- 访问前端WEB：`http://localhost:3000`

成功执行以上步骤后，能正常打开并使用datahub web的所有功能。

## 如何进行汉化

本文仅是一个示例，让你明白如何针对datahub前端进行汉化，这个正规的做法是：让WEB项目支持国际化，如支持英、汉

- 找到需要汉化的短语，替换为对应的中文
- 本地运行项目`yarn run start`，查看汉化后的效果
- 打包项目`yarn build`，将产生的build文件夹中的内容打成一个jar包并替换容器中的datahub-frontend-assets.jar ，即完成了汉化。

下图是演示汉化时，修改的一些前端文件：
![在这里插入图片描述](https://img-blog.csdnimg.cn/56d8ac09d421455c82f971c7111e2d6b.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBA5p625p6E5biI5b-g5ZOl,size_20,color_FFFFFF,t_70,g_se,x_16)

## 打包React项目碰到的问题

## 下载react依赖太慢?

请参考[yarn源修改为淘宝源](https://www.cnblogs.com/my466879168/p/12891308.html)，将yarn源设置为淘宝源

- 查看当前源 `yarn config get registry`
- 临时修yarn源 `yarn save package_name --registry https://registry.npm.taobao.org/`
- 修改yarn源为taobao源 `yarn config set registry https://registry.npm.taobao.org/`
- 修改yarn源为官方源 `yarn config set registry https://registry.yarnpkg.com`

## eslint warning Delete `␍` prettier/prettier

产生这个问题的原因如下：
在window系统中，git clone代码下来时，git 会自动把换行符LF(linefeed character) 转换成回车符CRLF(carriage-return character)

**解决方案：**

- 关掉换行符的自动转换: `git config --global core.autocrlf false`
- 删除clone的项目，重新git clone

## 类似’CI’不是内部或外部命令

可能是window系统不支持这样设置变量导致的，

请在项目依赖中添加`"cross-env": "^5.2.0",` 并在所有脚本中的变量设置前添加：`cross-env`，如`cross-env CI=false REACT_APP_MOCK=false`

## 编译graphql出现异常

这个可能是DataHub发布的源码版本存在BUG导致的，在v0.8.24下编译出错，但切换到v0.8.26编译正常。
出现这类问题，请先升级至最新版本尝试一下。