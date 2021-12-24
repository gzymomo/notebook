- [Web 端自动化神器：Automa](https://www.cnblogs.com/jinjiangongzuoshi/p/15543069.html)

## 1. Automa介绍

又到了优秀工具推荐的时候了，今天给大家分享一款前端自动化操作神器: `Automa `。

首先了解一下Automa是什么？ **Automa**它定位是一款 `Chrome` 插件，也就意味着，它的使用载体需要借助Chrome浏览器。利用**Automa**，即使你不会写代码，也能按照自己的需求，完成一系列自动化操作。利用它，你可以将一些重复性的任务实现自动化、并且它可以进行界面截图、抓取网站数据、你还可以自定义时间何时去执行自动化任务等。

## 2. Automa安装

听了上述介绍，想必你已经跃跃欲试了。

如果你是一名开发爱好者，你可以打开**Automa**项目地址，克隆项目源码，**项目地址：**

```
https://github.com/kholid060/automa
```

![img](https://gitee.com/er-huomeng/img/raw/master/img/image-20211110113425226.png)

**Automa**是基于Vue语言来开发的，如果有二开需求的读者，需要有一些`Vue`、`JavaScript`语言的基础才行。

如果你想改造定制它的功能，下述是环境依赖安装、构建常用的几条命令：

```
# Install dependencies
yarn install

# Compiles and hot-reloads for development
yarn dev

# Compiles and minifies for production
yarn build

# Create a zip file from the build folder
yarn build:zip

# Lints and fixes files
yarn lint
```

> yarn是一个新的 JS 包管理工具，类似npm。

如果你只是单纯的想使用它，上述的安装构建命令可以直接省略，可以进入到chrome应用商店下载它的插件。

**插件下载地址**：

```
https://chrome.google.com/webstore/detail/automa/infppggnoaenmfagbfknfkancpbljcca/related
```

![chrome网上商店](https://gitee.com/jinjiancode/pictures/raw/master/img/image-20211110112704923.png)

## 3. Automa使用

1､ 打开**Automa**插件，首页界面显示如下：

![img](https://gitee.com/jinjiancode/pictures/raw/master/img/image-20211110114002301.png)

整个界面，目前看起来还是比较简洁，当前共分为三部分功能：

- 第1部分，dashboard首页，提供了两个默认demo示例，刚开始用的话，可以先从demo熟悉开始。
- 第2部分，workflows工作流，主要通过拖拽组件的方式来组织我们的自动化流程。
- 第3部分，log日志，运行工作流的日志，较为简单。

从左侧侧边栏可以进入到 Workflows 工作流程 Tab 中，这也是大家使用最多的功能，

![img](https://gitee.com/jinjiancode/pictures/raw/master/img/image-20211110114333068.png)

在workflows中，从上述图中，可以看到提供了导入工作流「 Import workflow 」、新建工作流「 New workflow 」两个功能按钮。

比如新建一个工作流`test_baidu_flow`

![img](https://gitee.com/jinjiancode/pictures/raw/master/img/image-20211110114707954.png)

创建项目后，会进入到工作流编辑页面，该界面是用于构建自动化流程；左侧区域是操作区域，右侧区域是主流程构建区域

![img](https://gitee.com/jinjiancode/pictures/raw/master/img/image-20211110114944537.png)

左侧区域的操作组件，共包括了基本操作组件，如`Trigger 触发`、`Delay 延迟`、`Repeat task 重复执行任务`， 还有针对浏览器操作组件、元素操作组件、条件判断组件，具体感兴趣的读者可以自行体验。整体来讲，提供的功能，能满足日常针对Web浏览器常用到的一些功能组件了。

这些操作组件在代码层面，都是以task任务形式定义的：

![img](https://gitee.com/jinjiancode/pictures/raw/master/img/image-20211110183619222.png)

## 4. Automa实战一下

为了让你更好的对**Automa**有一个直观了解，接下来，我们通过一个简单案例实战一下。

**实战需求：**

- 打开微信搜索页面：https://weixin.sogou.com/
- 搜索：`测试开发技术` 公众号
- 从搜索到的结果中，点击进入符合要求的公众号链接，并截图保存。

由于**Automa**是纯通过组件拖拉的形式来组织任务的，为了方便大家有一个直观的对比，我们先将上述实战需求，用Selenium+Python来先实现一遍。

**Selenium+Python代码示例：**

```
import time
from selenium import webdriver
from selenium.webdriver.common.by import By

driver = webdriver.Chrome(executable_path="chromedriver")
driver.implicitly_wait(10)
driver.get("https://weixin.sogou.com/")
driver.find_element(By.CSS_SELECTOR,"#query").send_keys("测试开发技术")
driver.find_element(By.CSS_SELECTOR,".swz2").click()
driver.find_element_by_link_text("测试开发技术").click()
driver.get_screenshot_as_file('test.png')
time.sleep(3)
driver.quit()
```

**Automa示例：**

![img](https://gitee.com/jinjiancode/pictures/raw/master/img/image-20211110184602688.png)

先选择「 New Tab 」添加被操作的网页，接着，通过操作「 Forms 」向输入框中输入内容，使用「 Click element 」操作模拟点击搜索按钮，接下来又做了一些条件判断、延时、截图、关闭网页等。

在组织任务流前，需要包含了一个「 Trigger 」组件，它是作为任务的「 启动节点  」，类似Selenium在操作网页前，需要实例化一个操作对象一样，默认执行方式为  Manually，即：人工方式。我们也可以去定义任务的触发策略，比如按指定时间、周期性等。

![img](https://gitee.com/jinjiancode/pictures/raw/master/img/image-20211110185330656.png)

自动化任务或者可以理解为自动化“脚本”定义好之后，是直接保存在当前浏览器插件中的，如果怕数据丢失，我们也可以将创建好的自动化任务，导出到外部，**Autom**支持将任务导出成`JSON`、`TXT`格式的文件。

需要注意的是，**Autom**在定位元素时，使用的CSS定位符，比如定位微信搜索输入框：

![img](https://gitee.com/jinjiancode/pictures/raw/master/img/image-20211110184747701.png)

在连接两个组件关系时， Automa 插件提供了快速获取父元素、子元素选择器的功能，

![img](https://gitee.com/jinjiancode/pictures/raw/master/img/image-20211110190127138.png)

## 5. Automa小结

Automa对于零代码基础的读者，还是比较友好，利用Automa 提供的操作在 Web 自动化中基本可以满足一些日常简单的功能场景，对于复杂的前端自动化操作场景，也可以在工作流程中可以拖入「 JavaScript 」操作来完成。