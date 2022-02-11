- [JavaCV的摄像头实战之六：保存为mp4文件(有声音)](https://www.cnblogs.com/bolingcavalry/p/15877663.html)

### 本篇概览

- 本文是《JavaCV的摄像头实战》的第六篇，在[《JavaCV的摄像头实战之三：保存为mp4文件》](https://blog.csdn.net/boling_cavalry/article/details/121597278)一文中，咱们将摄像头的内容录制为mp4文件，相信聪明的您一定觉察到了一缕瑕疵：没有声音
- 虽然《JavaCV的摄像头实战》系列的主题是摄像头处理，但显然音视频健全才是最常见的情况，因此就在本篇补全[前文](https://blog.csdn.net/boling_cavalry/article/details/121597278)的不足吧：编码实现摄像头和麦克风的录制

### 关于音频的采集和录制

- 本篇的代码是在[《JavaCV的摄像头实战之三：保存为mp4文件》](https://blog.csdn.net/boling_cavalry/article/details/121597278)源码的基础上增加音频处理部分
- 编码前，咱们先来分析一下，增加音频处理后具体的代码逻辑会有哪些变化
- 只保存视频的操作，与保存音频相比，步骤的区别如下图所示，深色块就是新增的操作：

![在这里插入图片描述](https://img2022.cnblogs.com/other/485422/202202/485422-20220210073620599-34951868.png)

- 相对的，在应用结束时，释放所有资源的时候，音视频的操作也比只有视频时要多一些，如下图所示，深色就是释放音频相关资源的操作：

![在这里插入图片描述](https://img2022.cnblogs.com/other/485422/202202/485422-20220210073621135-1854899259.png)

- 为了让代码简洁一些，我将音频相关的处理都放在名为AudioService的类中，也就是说上面两幅图的深色部分的代码都在AudioService.java中，主程序使用此类来完成音频处理
- 接下来开始编码

### 开发音频处理类AudioService

- 首先是刚才提到的AudioService.java，主要内容就是前面图中深色块的功能，有几处要注意的地方稍后会提到：

```java
package com.bolingcavalry.grabpush.extend;

import lombok.extern.slf4j.Slf4j;
import org.bytedeco.ffmpeg.global.avcodec;
import org.bytedeco.javacv.FFmpegFrameRecorder;
import org.bytedeco.javacv.FrameRecorder;
import javax.sound.sampled.AudioFormat;
import javax.sound.sampled.AudioSystem;
import javax.sound.sampled.DataLine;
import javax.sound.sampled.TargetDataLine;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.ShortBuffer;
import java.util.concurrent.ScheduledThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

/**
 * @author willzhao
 * @version 1.0
 * @description 音频相关的服务
 * @date 2021/12/3 8:09
 */
@Slf4j
public class AudioService {

    // 采样率
    private final static int SAMPLE_RATE = 44100;

    // 音频通道数，2表示立体声
    private final static int CHANNEL_NUM = 2;

    // 帧录制器
    private FFmpegFrameRecorder recorder;

    // 定时器
    private ScheduledThreadPoolExecutor sampleTask;

    // 目标数据线，音频数据从这里获取
    private TargetDataLine line;

    // 该数组用于保存从数据线中取得的音频数据
    byte[] audioBytes;

    // 定时任务的线程中会读此变量，而改变此变量的值是在主线程中，因此要用volatile保持可见性
    private volatile boolean isFinish = false;

    /**
     * 帧录制器的音频参数设置
     * @param recorder
     * @throws Exception
     */
    public void setRecorderParams(FrameRecorder recorder) throws Exception {
        this.recorder = (FFmpegFrameRecorder)recorder;

        // 码率恒定
        recorder.setAudioOption("crf", "0");
        // 最高音质
        recorder.setAudioQuality(0);
        // 192 Kbps
        recorder.setAudioBitrate(192000);

        // 采样率
        recorder.setSampleRate(SAMPLE_RATE);

        // 立体声
        recorder.setAudioChannels(2);
        // 编码器
        recorder.setAudioCodec(avcodec.AV_CODEC_ID_AAC);
    }

    /**
     * 音频采样对象的初始化
     * @throws Exception
     */
    public void initSampleService() throws Exception {
        // 音频格式的参数
        AudioFormat audioFormat = new AudioFormat(SAMPLE_RATE, 16, CHANNEL_NUM, true, false);

        // 获取数据线所需的参数
        DataLine.Info dataLineInfo = new DataLine.Info(TargetDataLine.class, audioFormat);

        // 从音频捕获设备取得其数据的数据线，之后的音频数据就从该数据线中获取
        line = (TargetDataLine)AudioSystem.getLine(dataLineInfo);

        line.open(audioFormat);

        // 数据线与音频数据的IO建立联系
        line.start();

        // 每次取得的原始数据大小
        final int audioBufferSize = SAMPLE_RATE * CHANNEL_NUM;

        // 初始化数组，用于暂存原始音频采样数据
        audioBytes = new byte[audioBufferSize];

        // 创建一个定时任务，任务的内容是定时做音频采样，再把采样数据交给帧录制器处理
        sampleTask = new ScheduledThreadPoolExecutor(1);
    }

    /**
     * 程序结束前，释放音频相关的资源
     */
    public void releaseOutputResource() {
        // 结束的标志，避免采样的代码在whlie循环中不退出
        isFinish = true;
        // 结束定时任务
        sampleTask.shutdown();
        // 停止数据线
        line.stop();
        // 关闭数据线
        line.close();
    }

    /**
     * 启动定时任务，每秒执行一次，采集音频数据给帧录制器
     * @param frameRate
     */
    public void startSample(double frameRate) {

        // 启动定时任务，每秒执行一次，采集音频数据给帧录制器
        sampleTask.scheduleAtFixedRate((Runnable) new Runnable() {
            @Override
            public void run() {
                try
                {
                    int nBytesRead = 0;

                    while (nBytesRead == 0 && !isFinish) {
                        // 音频数据是从数据线中取得的
                        nBytesRead = line.read(audioBytes, 0, line.available());
                    }

                    // 如果nBytesRead<1，表示isFinish标志被设置true，此时该结束了
                    if (nBytesRead<1) {
                        return;
                    }

                    // 采样数据是16比特，也就是2字节，对应的数据类型就是short，
                    // 所以准备一个short数组来接受原始的byte数组数据
                    // short是2字节，所以数组长度就是byte数组长度的二分之一
                    int nSamplesRead = nBytesRead / 2;
                    short[] samples = new short[nSamplesRead];

                    // 两个byte放入一个short中的时候，谁在前谁在后？这里用LITTLE_ENDIAN指定拜访顺序，
                    ByteBuffer.wrap(audioBytes).order(ByteOrder.LITTLE_ENDIAN).asShortBuffer().get(samples);
                    // 将short数组转为ShortBuffer对象，因为帧录制器的入参需要该类型
                    ShortBuffer sBuff = ShortBuffer.wrap(samples, 0, nSamplesRead);

                    // 音频帧交给帧录制器输出
                    recorder.recordSamples(SAMPLE_RATE, CHANNEL_NUM, sBuff);
                }
                catch (FrameRecorder.Exception e) {
                    e.printStackTrace();
                }
            }
        }, 0, 1000 / (long)frameRate, TimeUnit.MILLISECONDS);
    }
}
```

- 上述代码中，有两处要注意：

1. 重点关注recorder.recordSamples，该方法将音频存入了mp4文件
2. 定时任务是在一个新线程中执行的，因此当主线程结束录制后，需要中断定时任务中的while循环，因此新增了volatile类型的变量isFinish，帮助定时任务中的代码判断是否立即结束while循环

### 改造原本只存视频的代码

- 接着是对[《JavaCV的摄像头实战之三：保存为mp4文件》](https://blog.csdn.net/boling_cavalry/article/details/121597278)一文中RecordCameraSaveMp4.java的改造，为了不影响之前章节在github上的代码，这里我新增了一个类RecordCameraSaveMp4WithAudio.java，内容与RecordCameraSaveMp4.java一模一样，接下来咱们来改造这个RecordCameraSaveMp4WithAudio类
- 先增加AudioService类型的成员变量：

```java
	// 音频服务类
    private AudioService audioService = new AudioService();
```

- 接下来是关键，initOutput方法负责帧录制器的初始化，现在要加上音频相关的初始化操作，并且还要启动定时任务去采集和处理音频，如下所示，AudioService的三个方法都在此调用了，注意定时任务的启动要放在帧录制器初始化之后：

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

        // 设置帧录制器的音频相关参数
        audioService.setRecorderParams(recorder);

        // 音频采样相关的初始化操作
        audioService.initSampleService();

        // 初始化
        recorder.start();

        // 启动定时任务，采集音频帧给帧录制器
        audioService.startSample(getFrameRate());
```

- output方法保存原样，只处理视频帧（音频处理在定时任务中）

```java
    @Override
    protected void output(Frame frame) throws Exception {
        // 存盘
        recorder.record(frame);
    }
```

- 释放资源的方法中，增加了音频资源释放的操作：

```java
    @Override
    protected void releaseOutputResource() throws Exception {
        // 执行音频服务的资源释放操作
        audioService.releaseOutputResource();

        // 关闭帧录制器
        recorder.close();
    }
```

- 至此，将摄像头视频和麦克风音频存为mp4文件的功能已开发完成，再写上main方法，注意参数30表示抓取和录制的操作执行30秒，注意，这是程序执行的时长，**不是录制视频的时长**：

```java
    public static void main(String[] args) {
        // 录制30秒视频
        new RecordCameraSaveMp4WithAudio().action(30);
    }
```

- 运行main方法，等到控制台输出下图红框的内容时，表示视频录制完成：

![在这里插入图片描述](https://img2022.cnblogs.com/other/485422/202202/485422-20220210073621452-242994056.png)

- 打开mp4文件所在目录，如下图，红框中就是刚刚生成的文件和相关信息，注意蓝框的内容，证明该文件包含了视频和音频的数据：

![在这里插入图片描述](https://img2022.cnblogs.com/other/485422/202202/485422-20220210073621803-881169934.png)

- 用VLC播放验证，结果视频和声音都正常
- 至此，咱们已完成了保存音视频文件的功能，得益于JavaCV的强大，整个过程是如此的轻松愉快，接下来请继续关注欣宸原创，《JavaCV的摄像头实战》系列还会呈现更多丰富的应用；

### 源码下载

- 《JavaCV的摄像头实战》的完整源码可在GitHub下载到，地址和链接信息如下表所示(https://github.com/zq2599/blog_demos)：

| 名称               | 链接                                     | 备注                            |
| :----------------- | :--------------------------------------- | :------------------------------ |
| 项目主页           | https://github.com/zq2599/blog_demos     | 该项目在GitHub上的主页          |
| git仓库地址(https) | https://github.com/zq2599/blog_demos.git | 该项目源码的仓库地址，https协议 |
| git仓库地址(ssh)   | git@github.com:zq2599/blog_demos.git     | 该项目源码的仓库地址，ssh协议   |

- 这个git项目中有多个文件夹，本篇的源码在javacv-tutorials文件夹下，如下图红框所示：

![在这里插入图片描述](https://img2022.cnblogs.com/other/485422/202202/485422-20220210073622053-1808342533.png)

- javacv-tutorials里面有多个子工程，《JavaCV的摄像头实战》系列的代码在**simple-grab-push**工程下：

![在这里插入图片描述](https://img2022.cnblogs.com/other/485422/202202/485422-20220210073622698-1123317171.png)