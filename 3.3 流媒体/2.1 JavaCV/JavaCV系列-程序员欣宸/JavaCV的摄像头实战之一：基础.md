- [JavaCV的摄像头实战之一：基础](https://www.cnblogs.com/bolingcavalry/p/15828871.html)

### 本篇概览

- 作为整个系列的开篇，本文非常重要，从环境到代码的方方面面，都会为后续文章打好基础，简单来说本篇由以下内容构成：

1. 环境和版本信息
2. 基本套路分析
3. 基本框架编码
4. 部署媒体服务器

- 接下来就从环境和版本信息开始吧

### 环境和版本信息

- 现在就把实战涉及的软硬件环境交代清楚，您可以用来参考：

1. 操作系统：win10
2. JDK：1.8.0_291
3. maven：3.8.1
4. IDEA：2021.2.2(Ultimate Edition)
5. JavaCV：1.5.6
6. 媒体服务器：基于dockek部署的nginx-rtmp，镜像是：alfg/nginx-rtmp:v1.3.1

### 源码下载

- 《JavaCV的摄像头实战》的完整源码可在GitHub下载到，地址和链接信息如下表所示(https://github.com/zq2599/blog_demos)：

| 名称               | 链接                                     | 备注                            |
| :----------------- | :--------------------------------------- | :------------------------------ |
| 项目主页           | https://github.com/zq2599/blog_demos     | 该项目在GitHub上的主页          |
| git仓库地址(https) | https://github.com/zq2599/blog_demos.git | 该项目源码的仓库地址，https协议 |
| git仓库地址(ssh)   | git@github.com:zq2599/blog_demos.git     | 该项目源码的仓库地址，ssh协议   |

- 这个git项目中有多个文件夹，本篇的源码在javacv-tutorials文件夹下，如下图红框所示：

![在这里插入图片描述](https://img2022.cnblogs.com/other/485422/202201/485422-20220121083755372-517170596.png)

- javacv-tutorials里面有多个子工程，《JavaCV的摄像头实战》系列的代码在**simple-grab-push**工程下：

![在这里插入图片描述](https://img2022.cnblogs.com/other/485422/202201/485422-20220121083755808-1602997579.png)

### 基本套路分析

- 全系列有多个基于摄像头的实战，例如窗口预览、把视频保存为文件、把视频推送到媒体服务器等，其基本套路是大致相同的，用最简单的流程图表示如下：

![在这里插入图片描述](https://img2022.cnblogs.com/other/485422/202201/485422-20220121083756148-668766207.png)

- 从上图可见，整个流程就是不停的从摄像头取帧，然后处理和输出

### 基本框架编码

- 看过了上面基本套路，聪明的您可能会有这样的想法：既然套路是固定的，那代码也可以按套路固定下来吧
- 没错，接下来就考虑如何把代码按照套路固定下来，我的思路是开发名为AbstractCameraApplication的抽象类，作为《JavaCV的摄像头实战》系列每个应用的父类，它负责搭建整个初始化、取帧、处理、输出的流程，它的子类则专注帧数据的具体处理和输出，整个体系的UML图如下所示：

![在这里插入图片描述](https://img2022.cnblogs.com/other/485422/202201/485422-20220121083756377-547119837.png)

- 接下来就该开发抽象类AbstractCameraApplication.java了，编码前先设计，下图是AbstractCameraApplication的主要方法和执行流程，粗体全部是方法名，红色块代表留给子类实现的抽象方法：

![在这里插入图片描述](https://img2022.cnblogs.com/other/485422/202201/485422-20220121083756690-420525704.png)

- 接下来是创建工程，我这里创建的是maven工程，pom.xml如下：

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

- 接下来就是AbstractCameraApplication.java的完整代码，这些代码的流程和方法命名都与上图保持一致，并且添加了详细的注释，有几处要注意的地方稍后会提到：

```java
package com.bolingcavalry.grabpush.camera;

import lombok.Getter;
import lombok.extern.slf4j.Slf4j;
import org.bytedeco.ffmpeg.global.avutil;
import org.bytedeco.javacv.*;
import org.bytedeco.opencv.global.opencv_imgproc;
import org.bytedeco.opencv.opencv_core.Mat;
import org.bytedeco.opencv.opencv_core.Scalar;

import java.text.SimpleDateFormat;
import java.util.Date;

/**
 * @author will
 * @email zq2599@gmail.com
 * @date 2021/11/19 8:07 上午
 * @description 摄像头应用的基础类，这里面定义了拉流和推流的基本流程，子类只需实现具体的业务方法即可
 */
@Slf4j
public abstract class AbstractCameraApplication {

    /**
     * 摄像头序号，如果只有一个摄像头，那就是0
     */
    protected static final int CAMERA_INDEX = 0;

    /**
     * 帧抓取器
     */
    protected FrameGrabber grabber;

    /**
     * 输出帧率
     */
    @Getter
    private final double frameRate = 30;

    /**
     * 摄像头视频的宽
     */
    @Getter
    private final int cameraImageWidth = 1280;

    /**
     * 摄像头视频的高
     */
    @Getter
    private final int cameraImageHeight = 720;

    /**
     * 转换器
     */
    private final OpenCVFrameConverter.ToIplImage openCVConverter = new OpenCVFrameConverter.ToIplImage();

    /**
     * 实例化、初始化输出操作相关的资源
     */
    protected abstract void initOutput() throws Exception;

    /**
     * 输出
     */
    protected abstract void output(Frame frame) throws Exception;

    /**
     * 释放输出操作相关的资源
     */
    protected abstract void releaseOutputResource() throws Exception;

    /**
     * 两帧之间的间隔时间
     * @return
     */
    protected int getInterval() {
        // 假设一秒钟15帧，那么两帧间隔就是(1000/15)毫秒
        return (int)(1000/ frameRate);
    }

    /**
     * 实例化帧抓取器，默认OpenCVFrameGrabber对象，
     * 子类可按需要自行覆盖
     * @throws FFmpegFrameGrabber.Exception
     */
    protected void instanceGrabber() throws FrameGrabber.Exception {
        grabber = new OpenCVFrameGrabber(CAMERA_INDEX);
    }

    /**
     * 用帧抓取器抓取一帧，默认调用grab()方法，
     * 子类可以按需求自行覆盖
     * @return
     */
    protected Frame grabFrame() throws FrameGrabber.Exception {
        return grabber.grab();
    }

    /**
     * 初始化帧抓取器
     * @throws Exception
     */
    protected void initGrabber() throws Exception {
        // 实例化帧抓取器
        instanceGrabber();

        // 摄像头有可能有多个分辨率，这里指定
        // 可以指定宽高，也可以不指定反而调用grabber.getImageWidth去获取，
        grabber.setImageWidth(cameraImageWidth);
        grabber.setImageHeight(cameraImageHeight);

        // 开启抓取器
        grabber.start();
    }

    /**
     * 预览和输出
     * @param grabSeconds 持续时长
     * @throws Exception
     */
    private void grabAndOutput(int grabSeconds) throws Exception {
        // 添加水印时用到的时间工具
        SimpleDateFormat simpleDateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");

        long endTime = System.currentTimeMillis() + 1000L *grabSeconds;

        // 两帧输出之间的间隔时间，默认是1000除以帧率，子类可酌情修改
        int interVal = getInterval();

        // 水印在图片上的位置
        org.bytedeco.opencv.opencv_core.Point point = new org.bytedeco.opencv.opencv_core.Point(15, 35);

        Frame captureFrame;
        Mat mat;

        // 超过指定时间就结束循环
        while (System.currentTimeMillis()<endTime) {
            // 取一帧
            captureFrame = grabFrame();

            if (null==captureFrame) {
                log.error("帧对象为空");
                break;
            }

            // 将帧对象转为mat对象
            mat = openCVConverter.convertToMat(captureFrame);

            // 在图片上添加水印，水印内容是当前时间，位置是左上角
            opencv_imgproc.putText(mat,
                    simpleDateFormat.format(new Date()),
                    point,
                    opencv_imgproc.CV_FONT_VECTOR0,
                    0.8,
                    new Scalar(0, 200, 255, 0),
                    1,
                    0,
                    false);

            // 子类输出
            output(openCVConverter.convert(mat));

            // 适当间隔，让肉感感受不到闪屏即可
            if(interVal>0) {
                Thread.sleep(interVal);
            }
        }

        log.info("输出结束");
    }

    /**
     * 释放所有资源
     */
    private void safeRelease() {
        try {
            // 子类需要释放的资源
            releaseOutputResource();
        } catch (Exception exception) {
            log.error("do releaseOutputResource error", exception);
        }

        if (null!=grabber) {
            try {
                grabber.close();
            } catch (Exception exception) {
                log.error("close grabber error", exception);
            }
        }
    }

    /**
     * 整合了所有初始化操作
     * @throws Exception
     */
    private void init() throws Exception {
        long startTime = System.currentTimeMillis();

        // 设置ffmepg日志级别
        avutil.av_log_set_level(avutil.AV_LOG_INFO);
        FFmpegLogCallback.set();

        // 实例化、初始化帧抓取器
        initGrabber();

        // 实例化、初始化输出操作相关的资源，
        // 具体怎么输出由子类决定，例如窗口预览、存视频文件等
        initOutput();

        log.info("初始化完成，耗时[{}]毫秒，帧率[{}]，图像宽度[{}]，图像高度[{}]",
                System.currentTimeMillis()-startTime,
                frameRate,
                cameraImageWidth,
                cameraImageHeight);
    }

    /**
     * 执行抓取和输出的操作
     */
    public void action(int grabSeconds) {
        try {
            // 初始化操作
            init();
            // 持续拉取和推送
            grabAndOutput(grabSeconds);
        } catch (Exception exception) {
            log.error("execute action error", exception);
        } finally {
            // 无论如何都要释放资源
            safeRelease();
        }
    }
}
```

- 上述代码有以下几处要注意：

1. 负责从摄像头取数据的是OpenCVFrameGrabber对象，即帧抓取器
2. initGrabber方法中，通过setImageWidth和setImageHeight方法为帧抓取器设置图像的宽和高，其实也可以不用设置宽高，由帧抓取器自动适配，但是考虑到有些摄像头支持多种分辨率，所以还是按照自己的实际情况来主动设置
3. grabAndOutput方法中，使用了while循环来不断地取帧、处理、输出，这个while循环的结束条件是指定时长，这样的结束条件可能满足不了您的需要，请按照您的实际情况自行调整（例如检测某个按键是否按下）
4. grabAndOutput方法中，将取到的帧转为Mat对象，然后在Mat对象上添加文字，内容是当前时间，再将Mat对象转为帧对象，将此帧对象传给子类的output方法，如此一来，子类做处理和输出的时候，拿到的帧都有了时间水印

- 至此，父类已经完成，接下来的实战，咱们只要专注用子类处理和输出帧数据即可

### 部署媒体服务器

- 《JavaCV的摄像头实战》系列的一些实战涉及到推流和远程播放，这就要用到流媒体服务器了，流媒体服务器的作用如下图，咱们也在这一篇提前部署好：

![在这里插入图片描述](https://img2022.cnblogs.com/other/485422/202201/485422-20220121083756905-1166642375.png)

- 关于媒体服务器的类型，我选的是常用的nginx-rtmp，简单起见，找了一台linux电脑，在上面用docker来部署，也就是一行命令的事儿：

```shell
docker run -d --name nginx_rtmp -p 1935:1935 -p 18080:80 alfg/nginx-rtmp:v1.3.1
```

- 另外还有个特殊情况，就是我这边有个闲置的树莓派3B，也可以用来做媒体服务器，也是用docker部署的，这里要注意镜像要选用shamelesscookie/nginx-rtmp-ffmpeg:latest，这个镜像有ARM64版本，适合在树莓派上使用：

```shell
docker run -d --name nginx_rtmp -p 1935:1935 -p 18080:80 shamelesscookie/nginx-rtmp-ffmpeg:latest
```