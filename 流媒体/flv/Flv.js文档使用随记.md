以下涉及到 [flv.js](https://github.com/bilibili/flv.js) 所有内容均是V1.5.0版本内的，如方法、属性、常量、监听等等，不讨论视频编解码，只陈述官方文档内容。采用文字+图片形式，单文字描述怕不好理解，单图片模式又怕将来哪天会挂掉，现在很多年份久的博文就有这情况，也不是没遇到过。非前端工作者，部分术语可能描述不得当，望理解。纯手码字一下午，只是为了时间久后遗忘再回来看一下。

**0x002: 架构图
**

 

[![img](https://img2020.cnblogs.com/blog/1516215/202007/1516215-20200706001317581-1716943373.png)](https://img2020.cnblogs.com/blog/1516215/202007/1516215-20200706001317581-1716943373.png)



**0x003: API文档相关内容**



> **flvjs.isSupported()**
>
> 
> // 查看当前浏览器是否支持flv.js，返回类型为布尔值

> **flvjs.createPlayer(mediaDataSource: MediaDataSource, config?: Config)**
>
> 
> /* 创建一个Player实例，它接收一个MediaDataSource(必选), 一个Config(可选)，如：
>     var flvPlayer = flvjs.createPlayer({
>       type: 'flv',
>       url: 'http://example.com/flv/video.flv'
>     }); */

MediaDataSource的字段列表如下，

[![img](https://img2020.cnblogs.com/blog/1516215/202007/1516215-20200706003330312-325000885.png)](https://img2020.cnblogs.com/blog/1516215/202007/1516215-20200706003330312-325000885.png)

这里说下最后一个segments字段（其余字段都很简单），它接收一个数组，类型为MediaSegment，MediaSegment的字段列表如下，

[![img](https://img2020.cnblogs.com/blog/1516215/202007/1516215-20200706003400574-247659967.png)](https://img2020.cnblogs.com/blog/1516215/202007/1516215-20200706003400574-247659967.png)

如果segments字段存在，transmuxer将把此MediaDataSource视为多片段源。在多片段模式下，将忽略MediaDataSource结构中的duration filesize url字段。
什么个意思呢，用白话说就是如果指定了segments字段那么之前指定的duration filesize url字段就不再生效了，将标志这是一个多片段合成一个的视频，进度条的总时长就等于各片段相加的和，所以每个片段的duration filesize一定要指定准确。


Config字段很多，就不一一介绍了，如下

[![img](https://img2020.cnblogs.com/blog/1516215/202007/1516215-20200706003658119-2029801664.png)](https://img2020.cnblogs.com/blog/1516215/202007/1516215-20200706003658119-2029801664.png)

 

> **flvjs.getFeatureList()**
>
>  
>
> // 返回一些功能特性列表，比如是否支持FLV直播流、H264 MP4 视频文件等等，如下

[![img](https://img2020.cnblogs.com/blog/1516215/202007/1516215-20200706003816978-699660997.png)](https://img2020.cnblogs.com/blog/1516215/202007/1516215-20200706003816978-699660997.png)

 

> **flvjs.FlvPlayer(mediaDataSource, optionalConfig)
> flvjs.NativePlayer(mediaDataSource, optionalConfig)**
>
>  
>
> // 这两个方法都继承自 **Player抽象接口**，一个是创建适用于FLV的Player实例，一个是适用于MP4的Player实例，如下

[![img](https://img2020.cnblogs.com/blog/1516215/202007/1516215-20200706004035715-1383957599.png)](https://img2020.cnblogs.com/blog/1516215/202007/1516215-20200706004035715-1383957599.png)　

其实 **flvjs.createPlayer(略)** 内部就是根据 type 分别创建不同的Player实例，自己去看看源码就知道了。如下

[![img](https://img2020.cnblogs.com/blog/1516215/202007/1516215-20200706004136560-470163601.png)](https://img2020.cnblogs.com/blog/1516215/202007/1516215-20200706004136560-470163601.png)

> **interface Player (abstract)**
>
>  
>
> // 它里面的每个方法或属性其实就是你自己创建出来Player实例的部分方法或属性，可直接调用。如下

[![img](https://img2020.cnblogs.com/blog/1516215/202007/1516215-20200706004345314-233161637.png)](https://img2020.cnblogs.com/blog/1516215/202007/1516215-20200706004345314-233161637.png)

> **flvjs.LoggingControl**
>
> 
> // 一个全局接口，用于设置 flv.js 的日志级别。如下

[![img](https://img2020.cnblogs.com/blog/1516215/202007/1516215-20200706004424946-1821469226.png)](https://img2020.cnblogs.com/blog/1516215/202007/1516215-20200706004424946-1821469226.png)

举几个简单的例子：

> **flvjs.LoggingControl.getConfig()**　　 // 获取当前日志项的配置情况，如
>
>  
>
> enableCallback: true
> enableDebug: true
> enableError: true
> enableInfo: true
> enableVerbose: true
> enableWarn: true
> forceGlobalTag: true
> globalTag: "flv.js"

> **flvjs.LoggingControl.enableVerbose**
>
> 
> /* 输出详细调试信息，默认为true，页面加载后会在控制台打印一些解码日志信息，如forceGlobalTag例子中的日志那样。
> 设置 false; 控制台不再打印。*/

> **flvjs.LoggingControl.forceGlobalTag**
>
> 
> // 默认false；

未设置之前的log打印是这样

> [MSEController] > MediaSource onSourceOpen
> [FLVDemuxer] > Parsed onMetaData
> [FLVDemuxer] > Parsed AVCDecoderConfigurationRecord
> [FLVDemuxer] > Parsed AudioSpecificConfig
> [MSEController] > Received Initialization Segment, mimeType: video/mp4;codecs=avc1.640028
> [MSEController] > Received Initialization Segment, mimeType: audio/mp4;codecs=mp4a.40.5
> [FlvPlayer] > Maximum buffering duration exceeded, suspend transmuxing task

设置 true; 后是这样

> [flv.js] > MediaSource onSourceOpen
> [flv.js] > Parsed onMetaData
> [flv.js] > Parsed AVCDecoderConfigurationRecord
> [flv.js] > Parsed AudioSpecificConfig
> [flv.js] > Received Initialization Segment, mimeType: video/mp4;codecs=avc1.640028
> [flv.js] > Received Initialization Segment, mimeType: audio/mp4;codecs=mp4a.40.5
> [flv.js] > Maximum buffering duration exceeded, suspend transmuxing task
> [flv.js] > MediaSource onSourceEnded

 

> **flvjs.Events**
>
> 
> // 可以与Player.on（）/ Player.off（）一起使用的一系列常量。需要使用前缀flvjs.Events。如下

[![img](https://img2020.cnblogs.com/blog/1516215/202007/1516215-20200706005450598-614745635.png)](https://img2020.cnblogs.com/blog/1516215/202007/1516215-20200706005450598-614745635.png)

> **flvjs.ErrorTypes**
> **flvjs.ErrorDetails**
>
> 
> // 是几个错误类型以及相应类型对应的错误详情，可以用来做些判断。也需要使用前缀flvjs.Events。如下

[![img](https://img2020.cnblogs.com/blog/1516215/202007/1516215-20200706005715883-2112909664.png)](https://img2020.cnblogs.com/blog/1516215/202007/1516215-20200706005715883-2112909664.png)

**0x004: 直播播放 文档相关内容**
　　
您需要在MediaDataSource中提供一个实时流URL（可以是HTTP 或 WebSocket），并指示isLive：true。如下

> ​    var flvPlayer = flvjs.createPlayer({
> ​      type: "flv",
> ​      **isLive: true,**
> ​      url: "http://127.0.0.1:8080/live/livestream.flv"
> ​    });

[![img](https://img2020.cnblogs.com/blog/1516215/202007/1516215-20200706010201878-1431982699.png)](https://img2020.cnblogs.com/blog/1516215/202007/1516215-20200706010201878-1431982699.png)

**0x005: 多段播放 文档相关内容**

　　
多片段配置示例，需注意的是文档强调：您必须为每个细分提供准确的持续时间。

[![img](https://img2020.cnblogs.com/blog/1516215/202007/1516215-20200706010414193-172451227.png)](https://img2020.cnblogs.com/blog/1516215/202007/1516215-20200706010414193-172451227.png)

**0x006: 使用记录**

- 可以在播放前指定MediaDataSource参数，hasAudio（是否有音频）及hasVideo（是否有视频），单独指定单独有，都指定则都有。
- SeekTo功能 或 player.currentTime属性 接收的值类型是Number，如78或108.999，单位秒