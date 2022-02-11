- [JavaCV推流实战(MP4文件)](https://www.cnblogs.com/bolingcavalry/p/15824946.html)

### 本篇概览

- 自己的mp4文件，如何让更多的人远程播放？如下图所示：

![在这里插入图片描述](https://img2022.cnblogs.com/other/485422/202201/485422-20220120083309815-1551357064.png)

- 这里简单解释一下上图的功能：

1. 部署开源流媒体服务器SRS
2. 开发名为PushMp4的java应用，该应用会读取本机磁盘上的Mp4文件，读取每一帧，推送到SRS上
3. 每个想看视频的人，就在自己电脑上用流媒体播放软件（例如VLC）连接SRS，播放PushMp4推上来的视频

- 今天咱们就来完成上图中的实战，整个过程分为以下步骤：

1. 环境信息
2. 准备MP4文件
3. 用docker部署SRS
4. java应用开发和运行
5. VLC播放

### 环境信息

- 本次实战，我这边涉及的环境信息如下，供您参考：

1. 操作系统：macOS Monterey
2. JDK：1.8.0_211
3. JavaCV：1.5.6
4. SRS：3

### 准备MP4文件

- 准备一个普通的MP4视频文件即可，我是在线下载了视频开发常用的大熊兔视频，地址是：
   https://www.learningcontainer.com/wp-content/uploads/2020/05/sample-mp4-file.mp4

### 用docker部署SRS

- SRS是著名的开源的媒体服务器，推到这里的流，都可以用媒体播放器在线播放，为了简单起见，我在docker环境下一行命令完成部署：

```shell
docker run -p 1935:1935 -p 1985:1985 -p 8080:8080 ossrs/srs:3
```

- 此刻SRS服务正在运行中，可以推流上去了

### 开发JavaCV应用

- 接下来进入最重要的编码阶段，新建名为simple-grab-push的maven工程，pom.xml如下（那个名为javacv-tutorials的父工程其实没有什么作用，我这里只是为了方便管理多个工程的代码而已，您可以删除这个父工程节点）：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <parent>
        <artifactId>javacv-tutorials</artifactId>
        <groupId>com.bolingcavalry</groupId>
        <version>1.0-SNAPSHOT</version>
    </parent>
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.bolingcavalry</groupId>
    <version>1.0-SNAPSHOT</version>
    <artifactId>simple-grab-push</artifactId>
    <packaging>jar</packaging>

    <properties>
        <!-- javacpp当前版本 -->
        <javacpp.version>1.5.6</javacpp.version>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
        </dependency>
        <dependency>
            <groupId>ch.qos.logback</groupId>
            <artifactId>logback-classic</artifactId>
            <version>1.2.3</version>
        </dependency>
        <dependency>
            <groupId>org.apache.logging.log4j</groupId>
            <artifactId>log4j-to-slf4j</artifactId>
            <version>2.13.3</version>
        </dependency>

        <!-- javacv相关依赖，一个就够了 -->
        <dependency>
            <groupId>org.bytedeco</groupId>
            <artifactId>javacv-platform</artifactId>
            <version>${javacpp.version}</version>
        </dependency>
    </dependencies>
</project>
```

- 从上述文件可见，JavaCV的依赖只有一个javacv-platform，挺简洁
- 接下来开始编码，在编码前，先把整个流程画出来，这样写代码就清晰多了：

![在这里插入图片描述](https://img2022.cnblogs.com/other/485422/202201/485422-20220120083310294-397051282.png)

- 从上图可见流程很简单，这里将所有代码写在一个java类中：

```java
package com.bolingcavalry.grabpush;

import lombok.extern.slf4j.Slf4j;
import org.bytedeco.ffmpeg.avcodec.AVCodecParameters;
import org.bytedeco.ffmpeg.avformat.AVFormatContext;
import org.bytedeco.ffmpeg.avformat.AVStream;
import org.bytedeco.ffmpeg.global.avcodec;
import org.bytedeco.ffmpeg.global.avutil;
import org.bytedeco.javacv.FFmpegFrameGrabber;
import org.bytedeco.javacv.FFmpegFrameRecorder;
import org.bytedeco.javacv.FFmpegLogCallback;
import org.bytedeco.javacv.Frame;

/**
 * @author willzhao
 * @version 1.0
 * @description 读取指定的mp4文件，推送到SRS服务器
 * @date 2021/11/19 8:49
 */
@Slf4j
public class PushMp4 {
    /**
     * 本地MP4文件的完整路径(两分零五秒的视频)
     */
    private static final String MP4_FILE_PATH = "/Users/zhaoqin/temp/202111/20/sample-mp4-file.mp4";

    /**
     * SRS的推流地址
     */
    private static final String SRS_PUSH_ADDRESS = "rtmp://192.168.50.43:11935/live/livestream";

    /**
     * 读取指定的mp4文件，推送到SRS服务器
     * @param sourceFilePath 视频文件的绝对路径
     * @param PUSH_ADDRESS 推流地址
     * @throws Exception
     */
    private static void grabAndPush(String sourceFilePath, String PUSH_ADDRESS) throws Exception {
        // ffmepg日志级别
        avutil.av_log_set_level(avutil.AV_LOG_ERROR);
        FFmpegLogCallback.set();

        // 实例化帧抓取器对象，将文件路径传入
        FFmpegFrameGrabber grabber = new FFmpegFrameGrabber(MP4_FILE_PATH);

        long startTime = System.currentTimeMillis();

        log.info("开始初始化帧抓取器");

        // 初始化帧抓取器，例如数据结构（时间戳、编码器上下文、帧对象等），
        // 如果入参等于true，还会调用avformat_find_stream_info方法获取流的信息，放入AVFormatContext类型的成员变量oc中
        grabber.start(true);

        log.info("帧抓取器初始化完成，耗时[{}]毫秒", System.currentTimeMillis()-startTime);

        // grabber.start方法中，初始化的解码器信息存在放在grabber的成员变量oc中
        AVFormatContext avFormatContext = grabber.getFormatContext();

        // 文件内有几个媒体流（一般是视频流+音频流）
        int streamNum = avFormatContext.nb_streams();

        // 没有媒体流就不用继续了
        if (streamNum<1) {
            log.error("文件内不存在媒体流");
            return;
        }

        // 取得视频的帧率
        int frameRate = (int)grabber.getVideoFrameRate();

        log.info("视频帧率[{}]，视频时长[{}]秒，媒体流数量[{}]",
                frameRate,
                avFormatContext.duration()/1000000,
                avFormatContext.nb_streams());

        // 遍历每一个流，检查其类型
        for (int i=0; i< streamNum; i++) {
            AVStream avStream = avFormatContext.streams(i);
            AVCodecParameters avCodecParameters = avStream.codecpar();
            log.info("流的索引[{}]，编码器类型[{}]，编码器ID[{}]", i, avCodecParameters.codec_type(), avCodecParameters.codec_id());
        }

        // 视频宽度
        int frameWidth = grabber.getImageWidth();
        // 视频高度
        int frameHeight = grabber.getImageHeight();
        // 音频通道数量
        int audioChannels = grabber.getAudioChannels();

        log.info("视频宽度[{}]，视频高度[{}]，音频通道数[{}]",
                frameWidth,
                frameHeight,
                audioChannels);

        // 实例化FFmpegFrameRecorder，将SRS的推送地址传入
        FFmpegFrameRecorder recorder = new FFmpegFrameRecorder(SRS_PUSH_ADDRESS,
                frameWidth,
                frameHeight,
                audioChannels);

        // 设置编码格式
        recorder.setVideoCodec(avcodec.AV_CODEC_ID_H264);

        // 设置封装格式
        recorder.setFormat("flv");

        // 一秒内的帧数
        recorder.setFrameRate(frameRate);

        // 两个关键帧之间的帧数
        recorder.setGopSize(frameRate);

        // 设置音频通道数，与视频源的通道数相等
        recorder.setAudioChannels(grabber.getAudioChannels());

        startTime = System.currentTimeMillis();
        log.info("开始初始化帧抓取器");

        // 初始化帧录制器，例如数据结构（音频流、视频流指针，编码器），
        // 调用av_guess_format方法，确定视频输出时的封装方式，
        // 媒体上下文对象的内存分配，
        // 编码器的各项参数设置
        recorder.start();

        log.info("帧录制初始化完成，耗时[{}]毫秒", System.currentTimeMillis()-startTime);

        Frame frame;

        startTime = System.currentTimeMillis();

        log.info("开始推流");

        long videoTS = 0;

        int videoFrameNum = 0;
        int audioFrameNum = 0;
        int dataFrameNum = 0;

        // 假设一秒钟15帧，那么两帧间隔就是(1000/15)毫秒
        int interVal = 1000/frameRate;
        // 发送完一帧后sleep的时间，不能完全等于(1000/frameRate)，不然会卡顿，
        // 要更小一些，这里取八分之一
        interVal/=8;

        // 持续从视频源取帧
        while (null!=(frame=grabber.grab())) {
            videoTS = 1000 * (System.currentTimeMillis() - startTime);

            // 时间戳
            recorder.setTimestamp(videoTS);

            // 有图像，就把视频帧加一
            if (null!=frame.image) {
                videoFrameNum++;
            }

            // 有声音，就把音频帧加一
            if (null!=frame.samples) {
                audioFrameNum++;
            }

            // 有数据，就把数据帧加一
            if (null!=frame.data) {
                dataFrameNum++;
            }

            // 取出的每一帧，都推送到SRS
            recorder.record(frame);

            // 停顿一下再推送
            Thread.sleep(interVal);
        }

        log.info("推送完成，视频帧[{}]，音频帧[{}]，数据帧[{}]，耗时[{}]秒",
                videoFrameNum,
                audioFrameNum,
                dataFrameNum,
                (System.currentTimeMillis()-startTime)/1000);

        // 关闭帧录制器
        recorder.close();
        // 关闭帧抓取器
        grabber.close();
    }

    public static void main(String[] args) throws Exception {
        grabAndPush(MP4_FILE_PATH, SRS_PUSH_ADDRESS);
    }
}
```

- 上述代码中每一行都有详细注释，就不多赘述了，只有下面这四处关键需要注意：

1. MP4_FILE_PATH是本地MP4文件存放的地方，请改为自己电脑上MP4文件存放的位置
2. SRS_PUSH_ADDRESS是SRS服务的推流地址，请改为自己的SRS服务部署的地址
3. grabber.start(true)方法执行的时候，内部是帧抓取器的初始化流程，会取得MP4文件的相关信息
4. recorder.record(frame)方法执行的时候，会将帧推送到SRS服务器

- 编码完成后运行此类，控制台日志如下所示，可见成功的取到了MP4文件的帧率、时长、解码器、媒体流等信息，然后开始推流了：

```shell
23:21:48.107 [main] INFO com.bolingcavalry.grabpush.PushMp4 - 开始初始化帧抓取器
23:21:48.267 [main] INFO com.bolingcavalry.grabpush.PushMp4 - 帧抓取器初始化完成，耗时[163]毫秒
23:21:48.277 [main] INFO com.bolingcavalry.grabpush.PushMp4 - 视频帧率[15]，视频时长[125]秒，媒体流数量[2]
23:21:48.277 [main] INFO com.bolingcavalry.grabpush.PushMp4 - 流的索引[0]，编码器类型[0]，编码器ID[27]
23:21:48.277 [main] INFO com.bolingcavalry.grabpush.PushMp4 - 流的索引[1]，编码器类型[1]，编码器ID[86018]
23:21:48.279 [main] INFO com.bolingcavalry.grabpush.PushMp4 - 视频宽度[320]，视频高度[240]，音频通道数[6]
23:21:48.294 [main] INFO com.bolingcavalry.grabpush.PushMp4 - 开始初始化帧抓取器
23:21:48.727 [main] INFO com.bolingcavalry.grabpush.PushMp4 - 帧录制初始化完成，耗时[433]毫秒
23:21:48.727 [main] INFO com.bolingcavalry.grabpush.PushMp4 - 开始推流
```

- 接下来试试能不能拉流播放

### 用VLC播放

- 请安装VLC软件，并打开
- 如下图红框，点击菜单中的Open Network...，然后输入前面代码中写的推流地址（我这里是rtmp://192.168.50.43:11935/live/livestream）：

![在这里插入图片描述](https://img2022.cnblogs.com/other/485422/202201/485422-20220120083310879-1687978642.png)

- 如下图，成功播放，而且声音也正常：

![在这里插入图片描述](https://img2022.cnblogs.com/other/485422/202201/485422-20220120083311262-1651031414.png)

### 附加知识点

- 经过上面的实战，我们熟悉了播放和推流的基本操作，掌握了常规信息的获取以及参数设置，除了代码中的知识，还有以下几个隐藏的知识点也值得关注

1. 设置ffmpeg日志级别的代码是avutil.av_log_set_level(avutil.AV_LOG_ERROR)，把参数改为avutil.AV_LOG_INFO后，可以在控制台看到更丰富的日志，如下图红色区域，里面显示了MP4文件的详细信息，例如两个媒体流（音频流和视频流）：

![在这里插入图片描述](https://img2022.cnblogs.com/other/485422/202201/485422-20220120083311842-832263234.png)

1. 第二个知识点是关于编码器类型和编码器ID的，如下图，两个媒体流(AVStream)的编码器类型分别是**0**和**1**，两个编码器ID分别是**27**和**86018**，这四个数字分别代表什么呢？

![在这里插入图片描述](https://img2022.cnblogs.com/other/485422/202201/485422-20220120083312289-1502393905.png)

1. 先看编码器类型，用IDEA的反编译功能打开avutil.class，如下图，编码器类型等于0表示视频(VIDEO)，类型等于1表示音频（AUDIO）：

![在这里插入图片描述](https://img2022.cnblogs.com/other/485422/202201/485422-20220120083312734-605267222.png)

1. 再看编码器ID，打开avcodec.java，看到编码器ID为**27**表示H264：

![在这里插入图片描述](https://img2022.cnblogs.com/other/485422/202201/485422-20220120083312995-680815910.png)

1. 编码器ID值86018的十六进制是0x15002，对应的编码器如下图红框：

![在这里插入图片描述](https://img2022.cnblogs.com/other/485422/202201/485422-20220120083313202-323020872.png)

- 至此，JavaCV推流实战(MP4文件)已经全部完成，希望通过本文咱们可以一起熟悉JavaCV处理推拉流的常规操作；
   https://github.com/zq2599/blog_demos