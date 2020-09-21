# [**Flv.js** B 站 HTML5 播放器内核](https://www.oschina.net/p/flv-js)

Flv.js 是 HTML5 Flash 视频（FLV）播放器，纯原生 JavaScript 开发，没有用到 Flash。由 bilibili 网站开源。

Github地址：https://github.com/Bilibili/flv.js/

# **概览：**

一个实现了在 HTML5 视频中播放 FLV 格式视频的 JavaScript 库。它的工作原理是将 FLV 文件流转码复用成 ISO BMFF（MP4 碎片）片段，然后通过 [Media Source Extensions](https://w3c.github.io/media-source/) 将 MP4 片段喂进浏览器。

flv.js只做了一件事，在获取到FLV格式的音视频数据后通过原生的JS去解码FLV数据，再通过[Media Source Extensions](https://w3c.github.io/media-source/) API 喂给原生HTML5 Video标签。(HTML5 原生仅支持播放 mp4/webm 格式，不支持 FLV)



flv.js 为什么要绕一圈，从服务器获取FLV再解码转换后再喂给Video标签呢？原因如下：

1. 兼容目前的直播方案：目前大多数直播方案的音视频服务都是采用FLV容器格式传输音视频数据。
2. FLV容器格式相比于MP4格式更加简单，解析起来更快更方便。



HTML5 原生仅支持播放 mp4/webm 格式，flv.js 实现了在 HTML5 上播放 FLV 格式视频。



flv.js 是使用 ECMAScript 6 编写的，然后通过 [Babel Compiler](https://babeljs.io/) 编译成 ECMAScript 5，使用 [Browserify](http://browserify.org/) 打包。

flv.js 从服务器获取FLV再解封装后转给Video标签的原因如下：

1. 兼容目前的直播方案：目前大多数直播方案的音视频服务都是采用FLV容器格式传输音视频数据。
2. flv格式简单，相比于MP4格式转封装简单、性能上也占优势，解析起来更快更方便。

# **功能：**

- FLV 容器，具有 H.264 + AAC 编解码器播放功能
- 多部分分段视频播放
- HTTP FLV 低延迟实时流播放
- FLV 通过 WebSocket 实时流播放
- 兼容 Chrome, FireFox, Safari 10, IE11 和 Edge
- 十分低开销，并且通过你的浏览器进行硬件加速

# 常见直播协议

- RTMP: 底层基于TCP，在浏览器端依赖Flash。
- HTTP-FLV: 基于HTTP流式IO传输FLV，依赖浏览器支持播放FLV。
- WebSocket-FLV: 基于WebSocket传输FLV，依赖浏览器支持播放FLV。WebSocket建立在HTTP之上，建立WebSocket连接前还要先建立HTTP连接。
- HLS: Http Live Streaming，苹果提出基于HTTP的流媒体传输协议。HTML5可以直接打开播放。
- RTP: 基于UDP，延迟1秒，浏览器不支持。

# 兼容性

理论上只要是支持Media Source Extensions和ECMAScript 5的浏览器都是兼容flv.js的，浏览器对MSE的兼容情况如下图，从图中可以看出，flv.js的兼容性还是非常不错的。 需要指出的是iPhone版的Safari是不支持MSE的，所以在iPhone上只有hls是最理想的选择，而庆幸的是PC版和android版的浏览器大多都是支持MSE的，也就是说可以利用http-flv直播实现延时较低的效果。

![img](https://pic4.zhimg.com/80/v2-d22799434b9bd312bd6e7688d4c17690_720w.jpg)

![img](https://pic2.zhimg.com/80/v2-dfe0429c69f0035aa33f25e648d6eb23_720w.jpg)

**如果你对兼容性要求非常高的话，HLS会是非常好的选择，而并非所有浏览器版本都支持HLS播放，但是你可以利用另外一个JS播放器项目（video.js）实现全平台的hls直播。**

**各个浏览器对HLS的支持情况：**

![img](https://picb.zhimg.com/80/v2-a3fbc74314471f2e9bc2da48ce7a4654_720w.jpg)

**所以，你可以将flv.js和video.js配合使用，针对不同平台实现最优的方案。**



