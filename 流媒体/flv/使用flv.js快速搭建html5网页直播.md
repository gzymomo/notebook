[使用flv.js快速搭建html5网页直播](https://blog.csdn.net/impingo/article/details/103077380)



# 什么是flv.js

HTML5 原生仅支持播放 mp4/webm 格式，是不支持 FLV格式的。
flash性能问题是长期以来被全世界人所诟病的，尤其是明年起chrome彻底抛弃flash，越来越多有直播需求的人产生焦虑。这就加速了html5播放器的发展，也使得人们对html5非插件式的播放器更加渴望。而flv.js就是这么一款可以利用html5的video标签将http-flv直播流实时播放的一个js版的播放器。

## flv.js的原理

flv.js在获取到FLV格式的音视频数据后将 FLV 文件流转码复用成 ISO BMFF（MP4 碎片）片段，再通过Media Source Extensions API 传递给原生HTML5 Video标签进行播放。

flv.js 是使用 ECMAScript 6 编写的，然后通过 Babel Compiler 编译成 ECMAScript 5，使用 Browserify 打包。

flv.js 从服务器获取FLV再解封装后转给Video标签的原因如下：

1. 兼容目前的直播方案：目前大多数直播方案的音视频服务都是采用FLV容器格式传输音视频数据。
2. flv格式简单，相比于MP4格式转封装简单、性能上也占优势，解析起来更快更方便。

## 常见直播协议

- RTMP: 底层基于TCP，在浏览器端依赖Flash。
- HTTP-FLV: 基于HTTP流式IO传输FLV，依赖浏览器支持播放FLV。
- WebSocket-FLV: 基于WebSocket传输FLV，依赖浏览器支持播放FLV。WebSocket建立在HTTP之上，建立WebSocket连接前还要先建立HTTP连接。
- HLS: Http Live Streaming，苹果提出基于HTTP的流媒体传输协议。HTML5可以直接打开播放。
- RTP: 基于UDP，延迟1秒，浏览器不支持。

# 兼容性

理论上只要是支持Media Source Extensions和ECMAScript 5的浏览器都是兼容flv.js的，浏览器对MSE的兼容情况如下图，从图中可以看出，flv.js的兼容性还是非常不错的。
需要指出的是iPhone版的Safari是不支持MSE的，所以在iPhone上只有hls是最理想的选择，而庆幸的是PC版和android版的浏览器大多都是支持MSE的，也就是说可以利用http-flv直播实现延时较低的效果。
![在这里插入图片描述](https://img-blog.csdnimg.cn/20191115110117147.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2ltcGluZ28=,size_16,color_FFFFFF,t_70)
![在这里插入图片描述](https://img-blog.csdnimg.cn/20191115003059389.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2ltcGluZ28=,size_16,color_FFFFFF,t_70)
**如果你对兼容性要求非常高的话，HLS会是非常好的选择，而并非所有浏览器版本都支持HLS播放，但是你可以利用另外一个JS播放器项目（video.js）实现全平台的hls直播。后续我会写一篇专门讲解video.js的博客讨论这个方案。这里附上一张各个浏览器对HLS的支持情况：**
![在这里插入图片描述](https://img-blog.csdnimg.cn/20191115003701395.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2ltcGluZ28=,size_16,color_FFFFFF,t_70)
**所以，你可以将flv.js和video.js配合使用，针对不同平台实现最优的方案。**

# 直播服务器搭建

关于直播服务器搭建的流程，我在以前的博客里写了很多，感兴趣的可以参考[分布式直播系统（二）【搭建单点rtmp\http-flv\hls流媒体服务器】](https://blog.csdn.net/impingo/article/details/99131594)

当然也可以使用我的一键部署脚本安装：
https://github.com/im-pingo/pingos

```nginx
# 快速安装
git clone https://github.com/im-pingo/pingos.git

cd pingos

./release.sh -i

# 启动服务
cd /usr/local/pingos/
./sbin/nginx
12345678910
```

# 推流

## ffmpeg推流

```bash
ffmpeg -re -i 文件.mp4 -vcodec copy -acodec copy -f flv rtmp://ip地址/live/01
1
```

## OBS推流

Open Broadcaster Software（简称OBS）是一款直播流媒体内容制作软件。同时程序和其源代码都是免费的。

支持 OS X、Windows、Linux操作系统。适用于多种直播场景。满足大部分直播行为的操作需求（发布桌面、发布摄像头、麦克风、扬声器等等）。
![在这里插入图片描述](https://img-blog.csdnimg.cn/20191115111036758.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2ltcGluZ28=,size_16,color_FFFFFF,t_70)

# flv.js搭建过程

## 下载链接

为了方便使用，我已经将flv.js编译打包好了，直接下载解压到你的网站目录引用即可。

1. **可以使用百度云盘下载**
   链接: https://pan.baidu.com/s/1ihTo15nsgfLqXKa0vyFt-w
   提取码: gd55
2. **也可以从github下载**

```bash
git clone https://github.com/im-pingo/h5player.git
1
```

将h5player复制到你的网站目录，h5player/flv目录下有个index.html文件，这里是js播放器接口的调用示例，你可以直接利用这个页面演示。

## flv.js Demo演示

### Demo地址：http://player.pingos.io/flv

我已经搭建了一个完整的演示界面，你可以快速体验一把。

1. 输入http-flv的直播地址
2. 点击load按钮即可播放。
   ![在这里插入图片描述](https://img-blog.csdnimg.cn/20191115102729932.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2ltcGluZ28=,size_16,color_FFFFFF,t_70)

### 播放器主要参数

| 参数              | 描述                 |
| ----------------- | -------------------- |
| enableStashBuffer | 是否开启播放器端缓存 |
| stashInitialSize  | 播放器端缓存         |
| isLive            | 是否为直播流         |
| hasAudio          | 是否播放声音         |
| hasVideo          | 是否播放画面         |