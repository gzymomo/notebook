- [JavaCV的摄像头实战之四：抓图](https://www.cnblogs.com/bolingcavalry/p/15848689.html)

### 本篇概览

- 本文是《JavaCV的摄像头实战》的第四篇，也是整个系列最简单轻松的一篇，寥寥几行代码实现从摄像头抓图的功能；

### 编码

- [《JavaCV的摄像头实战之一：基础》](https://xinchen.blog.csdn.net/article/details/121572093)一文创建的simple-grab-push工程中已写好父类AbstractCameraApplication，本篇继续使用该工程，创建子类实现那些抽象方法即可
- 编码前先回顾父类的基础结构，如下图，粗体是父类定义的各个方法，红色块都是需要子类来实现抽象方法，所以接下来，咱们以本地窗口预览为目标实现这三个红色方法即可：

![在这里插入图片描述](https://img2022.cnblogs.com/other/485422/202201/485422-20220127084504716-608767259.png)

- 虽然父类要求子类必须实现这三个方法：initOutput、output、releaseOutputResource，但是实际上只有output方法中有代码，其他两个是空方法；
- 新建文件GrabImageFromCamera.java，这是AbstractCameraApplication的子类，其代码很简单，接下来按上图顺序依次说明
- 定义三个成员变量，作用分别是：指定图片文件存放路径（请自行调整）、图片格式、当前进程已存储图片数量：

```java
	// 图片存储路径的前缀（请根据自己电脑情况调整）
    protected String IMAGE_PATH_PREFIX = "E:\\temp\\202111\\28\\camera-"
            + new SimpleDateFormat("yyyyMMddHHmmss").format(new Date())
            + "-";

    // 图片格式
    private final static String IMG_TYPE = "jpg";

    /**
     * 当前进程已经存储的图片数量
     */
    private int saveNums = 0;
```

- 初始化的时候啥也不用做，对应的结束前的也没有资源需要释放，所以initOutput和releaseOutputResource都是空方法：

```java
   @Override
    protected void initOutput() throws Exception {
        // 啥也不用做
    }
    
	@Override
    protected void releaseOutputResource() {
        // 啥也不用做
    }
```

- 接下来是output方法，这里面用帧对象生成图片：

```java
	@Override
    protected void output(Frame frame) throws Exception {
        // 图片的保存位置
        String imagePath = IMAGE_PATH_PREFIX + (saveNums++) + "." + IMG_TYPE;

        // 把帧对象转为Image对象
        BufferedImage bufferedImage = converter.getBufferedImage(frame);

        // 保存图片
        ImageIO.write(bufferedImage, IMG_TYPE, new FileOutputStream(imagePath));

        log.info("保存完成：{}", imagePath);
    }
```

- 最后重写getInterval方法，表示每存一张图片就sleep一秒钟：

```java
    @Override
    protected int getInterval() {
        // 表示保存一张图片后会sleep一秒钟
        return 1000;
    }
```

- 至此，抓图功能已开发完成，再写上main方法，注意参数10表示持续执行10秒钟：

```java
    public static void main(String[] args) {
        // 连续十秒执行抓图操作
        new GrabImageFromCamera().action(10);
    }
```

- 运行main方法，控制台输出如下：

```shell
...
08:57:42.393 [main] INFO com.bolingcavalry.grabpush.camera.AbstractCameraApplication - 初始化完成，耗时[8515]毫秒，帧率[30.0]，图像宽度[1280]，图像高度[720]
08:57:43.110 [main] INFO com.bolingcavalry.grabpush.camera.GrabImageFromCamera - 保存完成：E:\temp\202111\28\camera-20211130085733-0.jpg
08:57:44.155 [main] INFO com.bolingcavalry.grabpush.camera.GrabImageFromCamera - 保存完成：E:\temp\202111\28\camera-20211130085733-1.jpg
08:57:45.193 [main] INFO com.bolingcavalry.grabpush.camera.GrabImageFromCamera - 保存完成：E:\temp\202111\28\camera-20211130085733-2.jpg
08:57:46.243 [main] INFO com.bolingcavalry.grabpush.camera.GrabImageFromCamera - 保存完成：E:\temp\202111\28\camera-20211130085733-3.jpg
08:57:47.287 [main] INFO com.bolingcavalry.grabpush.camera.GrabImageFromCamera - 保存完成：E:\temp\202111\28\camera-20211130085733-4.jpg
08:57:48.348 [main] INFO com.bolingcavalry.grabpush.camera.GrabImageFromCamera - 保存完成：E:\temp\202111\28\camera-20211130085733-5.jpg
08:57:49.430 [main] INFO com.bolingcavalry.grabpush.camera.GrabImageFromCamera - 保存完成：E:\temp\202111\28\camera-20211130085733-6.jpg
08:57:50.479 [main] INFO com.bolingcavalry.grabpush.camera.GrabImageFromCamera - 保存完成：E:\temp\202111\28\camera-20211130085733-7.jpg
08:57:51.547 [main] INFO com.bolingcavalry.grabpush.camera.GrabImageFromCamera - 保存完成：E:\temp\202111\28\camera-20211130085733-8.jpg
08:57:52.551 [main] INFO com.bolingcavalry.grabpush.camera.AbstractCameraApplication - 输出结束
[ WARN:0] global D:\a\javacpp-presets\javacpp-presets\opencv\cppbuild\windows-x86_64\opencv-4.5.3\modules\videoio\src\cap_msmf.cpp (438) `anonymous-namespace'::SourceReaderCB::~SourceReaderCB terminating async callback

Process finished with exit code 0
```

- 打开图片文件所在目录，如下图，图片已经成功生成：

![在这里插入图片描述](https://img2022.cnblogs.com/other/485422/202201/485422-20220127084504982-1028984018.png)

- 看其中一张的详情也符合预期：

![在这里插入图片描述](https://img2022.cnblogs.com/other/485422/202201/485422-20220127084505301-1096377171.png)

- 至此，咱们抓图功能完成，接下来请继续关注欣宸原创，《JavaCV的摄像头实战》系列还会呈现更多丰富的应用；

### 源码下载

- 《JavaCV的摄像头实战》的完整源码可在GitHub下载到，地址和链接信息如下表所示(https://github.com/zq2599/blog_demos)：

| 名称               | 链接                                     | 备注                            |
| :----------------- | :--------------------------------------- | :------------------------------ |
| 项目主页           | https://github.com/zq2599/blog_demos     | 该项目在GitHub上的主页          |
| git仓库地址(https) | https://github.com/zq2599/blog_demos.git | 该项目源码的仓库地址，https协议 |
| git仓库地址(ssh)   | git@github.com:zq2599/blog_demos.git     | 该项目源码的仓库地址，ssh协议   |

- 这个git项目中有多个文件夹，本篇的源码在javacv-tutorials文件夹下，如下图红框所示：

![在这里插入图片描述](https://img2022.cnblogs.com/other/485422/202201/485422-20220127084505583-2136981050.png)

- javacv-tutorials里面有多个子工程，《JavaCV的摄像头实战》系列的代码在**simple-grab-push**工程下：

![在这里插入图片描述](https://img2022.cnblogs.com/other/485422/202201/485422-20220127084505859-2023634957.png)