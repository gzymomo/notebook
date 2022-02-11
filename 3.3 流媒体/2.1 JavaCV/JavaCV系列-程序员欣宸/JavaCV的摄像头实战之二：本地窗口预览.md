- [JavaCV的摄像头实战之二：本地窗口预览](https://www.cnblogs.com/bolingcavalry/p/15838131.html)

### 本篇概览

- 前文[《JavaCV的摄像头实战之一：基础》](https://www.cnblogs.com/bolingcavalry/p/15828871.html)已经为整个系列做好了铺垫，接下来的文章会专注于如何使用来自摄像头的数据，本篇先从最简单的开始：本地窗口预览

### 编码

- [前文](https://xinchen.blog.csdn.net/article/details/121572093)创建的simple-grab-push工程中已经准备好了父类AbstractCameraApplication，所以本篇继续使用该工程，创建子类实现那些抽象方法即可
- 编码前先回顾父类的基础结构，如下图，粗体是父类定义的各个方法，红色块都是需要子类来实现抽象方法，所以接下来，咱们以本地窗口预览为目标实现这三个红色方法即可：

![在这里插入图片描述](https://img2022.cnblogs.com/other/485422/202201/485422-20220124084203141-705857154.png)

- 新建文件PreviewCamera.java，这是AbstractCameraApplication的子类，其代码很简单，接下来按上图顺序依次说明
- 先定义CanvasFrame类型的成员变量previewCanvas，这是展示视频帧的本地窗口：

```java
protected CanvasFrame previewCanvas
```

- 然后是初始化操作，可见是previewCanvas的实例化和参数设置：

```java
@Override
    protected void initOutput() {
        previewCanvas = new CanvasFrame("摄像头预览", CanvasFrame.getDefaultGamma() / grabber.getGamma());
        previewCanvas.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        previewCanvas.setAlwaysOnTop(true);
    }
```

- 接下来是output方法，定义了拿到每一帧视频数据后做什么事情，这里是在本地窗口显示：

```java
@Override
    protected void output(Frame frame) {
        // 预览窗口上显示当前帧
        previewCanvas.showImage(frame);
    }
```

- 最后是处理视频的循环结束后，程序退出前要做的事情，即关闭本地窗口：

```java
@Override
    protected void releaseOutputResource() {
        if (null!= previewCanvas) {
            previewCanvas.dispose();
        }
    }
```

- 至此，用本地窗口预览摄像头的功能已开发完成，再写上main方法，注意参数**1000**表示预览持续时间是1000秒：

```java
public static void main(String[] args) {
        new PreviewCamera().action(1000);
    }
```

- 运行main方法，如下图，摄像头顺利工作，左上角的时间水印也能正常显示（可见今天深圳的天气不错，应该出去走走，而不是在家写博客...）：

![在这里插入图片描述](https://img2022.cnblogs.com/other/485422/202201/485422-20220124084209926-458748082.png)

- 至此，咱们已完成了本地窗口预览功能，得益于JavaCV的强大，整个过程是如此的轻松愉快，接下来请继续关注欣宸原创，《JavaCV的摄像头实战》系列还会呈现更多丰富的应用；

### 源码下载

- 《JavaCV的摄像头实战》的完整源码可在GitHub下载到，地址和链接信息如下表所示(https://github.com/zq2599/blog_demos)：

| 名称               | 链接                                     | 备注                            |
| :----------------- | :--------------------------------------- | :------------------------------ |
| 项目主页           | https://github.com/zq2599/blog_demos     | 该项目在GitHub上的主页          |
| git仓库地址(https) | https://github.com/zq2599/blog_demos.git | 该项目源码的仓库地址，https协议 |
| git仓库地址(ssh)   | git@github.com:zq2599/blog_demos.git     | 该项目源码的仓库地址，ssh协议   |

- 这个git项目中有多个文件夹，本篇的源码在javacv-tutorials文件夹下，如下图红框所示：

![在这里插入图片描述](https://img2022.cnblogs.com/other/485422/202201/485422-20220124084211721-1638514784.png)

- javacv-tutorials里面有多个子工程，《JavaCV的摄像头实战》系列的代码在**simple-grab-push**工程下：

![在这里插入图片描述](https://img2022.cnblogs.com/other/485422/202201/485422-20220124084212066-2094771239.png)