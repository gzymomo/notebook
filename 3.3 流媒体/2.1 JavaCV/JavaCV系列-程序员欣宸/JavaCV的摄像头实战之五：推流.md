- [JavaCV的摄像头实战之五：推流](https://www.cnblogs.com/bolingcavalry/p/15873597.html)

### 本篇概览

- 本文是《JavaCV的摄像头实战》的第五篇，一起来考虑个问题：本地摄像头的内容，如何让网络上的其他人看见？
- 这就涉及到了推流，如下图，基于JavaCV的应用将摄像头的视频帧推送到媒体服务器，观看者用播放器软件远程连接媒体服务器，就能观看摄像头的内容了：

![在这里插入图片描述](https://img2022.cnblogs.com/other/485422/202202/485422-20220209084343036-385041742.png)

- 今天的主要工作就是开发上图的JavaCV应用，然后验证功能是否正常；

### 编码

- [《JavaCV的摄像头实战之一：基础》](https://xinchen.blog.csdn.net/article/details/121572093)一文创建的simple-grab-push工程中已写好父类AbstractCameraApplication，本篇继续使用该工程，创建子类实现那些抽象方法即可
- 编码前先回顾父类的基础结构，如下图，粗体是父类定义的各个方法，红色块都是需要子类来实现抽象方法，所以接下来，咱们以本地窗口预览为目标实现这三个红色方法即可：

![在这里插入图片描述](https://img2022.cnblogs.com/other/485422/202202/485422-20220209084344236-1595304931.png)

- 新建文件RecordCamera.java，这是AbstractCameraApplication的子类，其代码很简单，接下来按上图顺序依次说明
- [《JavaCV的摄像头实战之一：基础》](https://xinchen.blog.csdn.net/article/details/121572093)中已部署好了媒体服务器，这里定义一个成员变量保存媒体服务器的推流地址，请您按自己的情况调整：

```java
private static final String RECORD_ADDRESS = "rtmp://192.168.50.43:21935/hls/camera";
```

- 还要准备一个成员变量，推流的时候在帧上添加时间戳：

```java
protected long startRecordTime = 0L;
```

- 将视频帧推送到媒体服务器的功能来自FrameRecorder，这是个抽象类，本篇用到的是其子类FFmpegFrameRecorder，所以定义FrameRecorder类型的成员变量：

```java
	// 帧录制器
    protected FrameRecorder recorder;
```

- 然后是初始化操作，请注意各项参数设置（1280*720分辨率摄像头的情况）：

```java
    @Override
    protected void initOutput() throws Exception {
        // 实例化FFmpegFrameRecorder，将SRS的推送地址传入
        recorder = FrameRecorder.createDefault(RECORD_ADDRESS, getCameraImageWidth(), getCameraImageHeight());

        // 降低启动时的延时，参考
        // https://trac.ffmpeg.org/wiki/StreamingGuide)
        recorder.setVideoOption("tune", "zerolatency");
        // 在视频质量和编码速度之间选择适合自己的方案，包括这些选项：
        // ultrafast,superfast, veryfast, faster, fast, medium, slow, slower, veryslow
        // ultrafast offers us the least amount of compression (lower encoder
        // CPU) at the cost of a larger stream size
        // at the other end, veryslow provides the best compression (high
        // encoder CPU) while lowering the stream size
        // (see: https://trac.ffmpeg.org/wiki/Encode/H.264)
        // ultrafast对CPU消耗最低
        recorder.setVideoOption("preset", "ultrafast");
        // Constant Rate Factor (see: https://trac.ffmpeg.org/wiki/Encode/H.264)
        recorder.setVideoOption("crf", "28");
        // 2000 kb/s, reasonable "sane" area for 720
        recorder.setVideoBitrate(2000000);

        // 设置编码格式
        recorder.setVideoCodec(avcodec.AV_CODEC_ID_H264);

        // 设置封装格式
        recorder.setFormat("flv");

        // FPS (frames per second)
        // 一秒内的帧数
        recorder.setFrameRate(getFrameRate());
        // Key frame interval, in our case every 2 seconds -> 30 (fps) * 2 = 60
        // 关键帧间隔
        recorder.setGopSize((int)getFrameRate()*2);

        // 帧录制器开始初始化
        recorder.start();
    }
```

- 接下来是output方法，关键是recorder.record，另外要注意时间戳的计算和设置：

```java
    @Override
    protected void output(Frame frame) throws Exception {
        if (0L==startRecordTime) {
            startRecordTime = System.currentTimeMillis();
        }

        // 时间戳
        recorder.setTimestamp(1000 * (System.currentTimeMillis()-startRecordTime));

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

- 另外还要注意两帧之间的延时，由于推流涉及到网络，因此不能像本地预览那样根据帧率严格计算，实际间隔要更小一些：

```java
    @Override
    protected int getInterval() {
        // 相比本地预览，推流时两帧间隔时间更短
        return super.getInterval()/4;
    }
```

- 至此，推流功能已开发完成，再写上main方法，注意参数600表示抓取和录制的操作执行600秒：

```java
    public static void main(String[] args) {
        new RecordCamera().action(600);
    }
```

- 运行main方法，等到控制台输出下图红框的内容时，表示已经开始推流：

![在这里插入图片描述](https://img2022.cnblogs.com/other/485422/202202/485422-20220209084345381-1105625747.png)

- 用本机或局域网内另一台电脑，用VLC软件打开刚才推流的地址rtmp://192.168.50.43:21935/hls/camera，稍等几秒钟后开始正常播放：

![在这里插入图片描述](https://img2022.cnblogs.com/other/485422/202202/485422-20220209084346225-2126645407.png)

- 还可用VLC的工具查看编码信息：

![在这里插入图片描述](https://img2022.cnblogs.com/other/485422/202202/485422-20220209084346585-244805296.png)

- 至此，咱们已完成了推流功能，验证远程播放也正常，得益于JavaCV的强大，整个过程是如此的轻松愉快，接下来请继续关注欣宸原创，《JavaCV的摄像头实战》系列还会呈现更多丰富的应用；
- 此刻聪明的您一定发现了问题：只推视频吗？连声音都没有，就这？没错，接下来的实战，咱们该挑战音频处理了

### 源码下载

- 《JavaCV的摄像头实战》的完整源码可在GitHub下载到，地址和链接信息如下表所示(https://github.com/zq2599/blog_demos)：

| 名称               | 链接                                     | 备注                            |
| :----------------- | :--------------------------------------- | :------------------------------ |
| 项目主页           | https://github.com/zq2599/blog_demos     | 该项目在GitHub上的主页          |
| git仓库地址(https) | https://github.com/zq2599/blog_demos.git | 该项目源码的仓库地址，https协议 |
| git仓库地址(ssh)   | git@github.com:zq2599/blog_demos.git     | 该项目源码的仓库地址，ssh协议   |

- 这个git项目中有多个文件夹，本篇的源码在javacv-tutorials文件夹下，如下图红框所示：

![在这里插入图片描述](https://img2022.cnblogs.com/other/485422/202202/485422-20220209084346776-1686846134.png)

- javacv-tutorials里面有多个子工程，《JavaCV的摄像头实战》系列的代码在**simple-grab-push**工程下：

![在这里插入图片描述](https://img2022.cnblogs.com/other/485422/202202/485422-20220209084347028-2127453703.png)