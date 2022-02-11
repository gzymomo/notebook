- [JavaCV的摄像头实战之三：保存为mp4文件](https://www.cnblogs.com/bolingcavalry/p/15845334.html)

### 本篇概览

- 本文是《JavaCV的摄像头实战》的第三篇，如题，咱们一起实践如何将摄像头的视频内容保存为MP4文件

### 编码

- [《JavaCV的摄像头实战之一：基础》](https://xinchen.blog.csdn.net/article/details/121572093)一文创建的simple-grab-push工程中已写好父类AbstractCameraApplication，本篇继续使用该工程，创建子类实现那些抽象方法即可
- 编码前先回顾父类的基础结构，如下图，粗体是父类定义的各个方法，红色块都是需要子类来实现抽象方法，所以接下来，咱们以本地窗口预览为目标实现这三个红色方法即可：

![在这里插入图片描述](https://img2022.cnblogs.com/other/485422/202201/485422-20220126081024099-283432878.png)

- 新建文件RecordCameraSaveMp4.java，这是AbstractCameraApplication的子类，其代码很简单，接下来按上图顺序依次说明
- 定义一个成员变量，用于指定视频文件存放路径，这里文件名用的是当前时间字符串，请您根据自己电脑的情况调整路径：

```java
	// 存放视频文件的完整位置，请改为自己电脑的可用目录
    private static final String RECORD_FILE_PATH = "E:\\temp\\202111\\28\\camera-"
                                                 + new SimpleDateFormat("yyyyMMddHHmmss").format(new Date())
                                                 + ".mp4";
```

- 将视频帧存为mp4文件的功能来自FrameRecorder，这是个抽象类，本篇用到的是其子类FFmpegFrameRecorder，所以定义FrameRecorder类型的成员变量：

```java
	// 帧录制器
    protected FrameRecorder recorder;
```

- 然后是初始化操作，可见是FFmpegFrameRecorder的实例化和各项参数设置：

```java
    @Override
    protected void initOutput() throws Exception {
        // 实例化FFmpegFrameRecorder
        recorder = new FFmpegFrameRecorder(RECORD_FILE_PATH,        // 存放文件的位置
                                           getCameraImageWidth(),   // 分辨率的宽，与视频源一致
                                           getCameraImageHeight(),  // 分辨率的高，与视频源一致
                                           0);                      // 音频通道，0表示无

        // 文件格式
        recorder.setFormat("mp4");

        // 帧率与抓取器一致
        recorder.setFrameRate(getFrameRate());

        // 编码格式
        recorder.setPixelFormat(AV_PIX_FMT_YUV420P);

        // 编码器类型
        recorder.setVideoCodec(avcodec.AV_CODEC_ID_MPEG4);

        // 视频质量，0表示无损
        recorder.setVideoQuality(0);

        // 初始化
        recorder.start();
    }
```

- 接下来是output方法，一行就够了：

```java
    @Override
    protected void output(Frame frame) throws Exception {
        // 存盘
        recorder.record(frame);
    }
```

- 最后是处理视频的循环结束后，程序退出前要做的事情，即关闭帧抓取器：

```java
    @Override
    protected void releaseOutputResource() throws Exception {
        recorder.close();
    }
```

- 至此，将摄像头视频存为mp4文件的功能已开发完成，再写上main方法，注意参数30表示抓取和录制的操作执行30秒，注意，这是程序执行的时长，**不是录制视频的时长**：

```java
    public static void main(String[] args) {
        // 录制30秒视频
        new RecordCameraSaveMp4().action(30);
    }
```

- 运行main方法，等到控制台输出下图红框的内容时，表示视频录制完成：

![在这里插入图片描述](https://img2022.cnblogs.com/other/485422/202201/485422-20220126081025272-12986511.png)

- 打开mp4文件所在目录，如下图，红框中就是刚刚生成的文件和相关信息，可见分辨率和帧率都符合预期：

![在这里插入图片描述](https://img2022.cnblogs.com/other/485422/202201/485422-20220126081025763-790405091.png)

- 用VLC打开这个文件，如下图，播放正常：

![在这里插入图片描述](https://img2022.cnblogs.com/other/485422/202201/485422-20220126081026279-407639742.png)

- 至此，咱们已完成了保存视频文件的功能，得益于JavaCV的强大，整个过程是如此的轻松愉快，接下来请继续关注欣宸原创，《JavaCV的摄像头实战》系列还会呈现更多丰富的应用；

### 源码下载

- 《JavaCV的摄像头实战》的完整源码可在GitHub下载到，地址和链接信息如下表所示(https://github.com/zq2599/blog_demos)：

| 名称               | 链接                                     | 备注                            |
| :----------------- | :--------------------------------------- | :------------------------------ |
| 项目主页           | https://github.com/zq2599/blog_demos     | 该项目在GitHub上的主页          |
| git仓库地址(https) | https://github.com/zq2599/blog_demos.git | 该项目源码的仓库地址，https协议 |
| git仓库地址(ssh)   | git@github.com:zq2599/blog_demos.git     | 该项目源码的仓库地址，ssh协议   |

- 这个git项目中有多个文件夹，本篇的源码在javacv-tutorials文件夹下，如下图红框所示：

![在这里插入图片描述](https://img2022.cnblogs.com/other/485422/202201/485422-20220126081026566-2139254333.png)

- javacv-tutorials里面有多个子工程，《JavaCV的摄像头实战》系列的代码在**simple-grab-push**工程下：

![在这里插入图片描述](https://img2022.cnblogs.com/other/485422/202201/485422-20220126081026876-2104071126.png)