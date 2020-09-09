以下文章来源于花椒技术，作者花椒前端



## 项目背景

春天的时候花椒做了一个创新项目， 这是一个直播综艺节目的项目，前端的工作主要是做出一个PC主站点，在这个站点中的首页需要一个播放器，既能播放FLV直播视频流，还要在用户点击视频回顾按钮的时候， 弹出窗口播放HLS视频流；我们开始开发这个播放器的时候也没有多想， 直接使用了大家都能想到的

最简单的套路，flv.js和hls.js一起用！在播放视频时，调用中间件video.js来输出的Player来实现播放，这个Player根据视频地址的结尾字符来初始化播放器：new HLS 或者 flvjs.createPlayer，对外提供一致的接口，对HLS.js和FLV.js创建的播放器进行调用。完美的实现了产品的需求，不过写代码的时候总感觉有点蠢，HLS.js（208KB）和FLV.js（169KB）体积加起来有点太让人热泪盈眶了。

这时我们就有了一个想法，这两能不能合起来成为一个lib，既能播放flv视频，又能播放hls视频。理想很丰满，现实很骨感，这2个lib虽然都是JavaScript写的，但是它们的范畴都是视频类，以前只是调用，完全没有深入了解过，不过我们还是在领导的大(wei)力(bi)支(li)持(you)下，开始了尝试。

## 

## FLV.JS分析

FLV.js的工作原理是下载flv文件转码成IOS BMFF（MP4碎片）片段， 然后通过Media Source Extensions将MP4片段传输给HTML5的Video标签进行播放;

它的结构如下图所示:

![img](https://ask.qcloudimg.com/http-save/yehe-5720403/fzmsxpa675.png?imageView2/2/w/1620)

src/flv.js 是对外输出FLV.js的一些组件, 事件和错误, 方便用户根据抛出的事件进行各种操作和获取相应的播放信息; 最主要是flv.js下返回的2个player: NativePlayer 和 FLVPlayer;

NativePlayer 是对浏览器本身播放器的一个再包装, 使之能和FLVPlayer一样, 相应共同的事件和操作; 大家最主要使用的还是FLVPlayer这个播放器;

而 FLVPlayer中最重要东西可分为两块: 1. MSEController; 2. Transmuxer; 

### MSEController这个MSEController负责给HTML Video Element 和 SourceBuffer之间建立连接, 接受 InitSegment(ISO BMFF 片段中的 FTYP + MOOV)和 MediaSegment (ISO BMFF 片段中的 MOOF + MDATA); 将这2个片段按照顺序添加到SourceBuffer中, 和对SouceBuffer的一些控制和状态反馈;

### 

### Transmuxer

Transmuxer 主要负责的就是下载, 解码, 转码, 发送Segment的工作; 它的下面主要包含了 2个模块, TransmuxingWorker 和 TransmuxingController; 

TransmuxingWorker是启用多线程执行 TransmuxingController, 并对 TransmuxingController抛出的事件就行转发;

TransmuxingController 才是真正执行 下载, 解码, 转码, 发送Segment的苦力部门, 苦活累活都是这个部门干的, Transmuxer(真上级) 和 TransmuxingController(伪上级)都是在调用它的功能和传递它的输出;

下面有请这个劳苦功高的部门登场

#### 

#### TransmuxingController

TransmuxingController也是一个大部门, 他的手下有三个小组: IOController, demuxer和 remuxer;

1. IOController  IOController主要有三个功能, 一是负责遴选他手下的小小弟(loaders), 选出最适合当前浏览器环境的loader, 去从服务器搬运媒体流; 二是存储小小弟(loader)发上来的数据; 三是把数据发送给demuxer(解码)并存储demuxer未处理完的数据; 
2. demuxer  demuxer 是负责解码工作的员工, 他需要把IOController发送过来的FLV data, 解析整理成 videoTrack 和 audioTrack; 并把解析后的数据发送给 remuxer 转码器; 解码完成后, 他会把已经处理的数据的长度返回给 IOController, IOController会把未处理的数据(总数据 - 已经处理的数据)存储, 等待下次发送数据的时候发从头部追加未处理的数据, 一起发送给 demuxer.
3. remuxer remuxer 是负责将 videoTrack 和 audioTrack 转成 InitSegment 和 MediaSegment并向上发送, 并在转化的过程中进行音视频同步的操作. 

总的流程就是 FLVPlayer喊了一声启动之后, loader 加载数据 => IOController 存储和转发数据 => demuxer 解码数据 => remuxer 转码数据 => TransmuxingWorker 和 Transmuxer 转发数据 =>MSEController 接受数据 => SourceBuffer; 一系列操作之后视频就可以播放了;

## 

## HLS.JS分析

HLS.js的工作原理是先下载index.m3u8文件, 然后解析该文档, 取出Level, 再根据Levels中的片段(Fragments)信息去下载相应的TS文件, 转码成IOS BMFF（MP4碎片）片段， 然后通过Media Source Extensions将MP4片段传输给HTML5的Video标签进行播放;

HLS.js的结构如下：

![img](https://ask.qcloudimg.com/http-save/yehe-5720403/i11s7yuxeh.png?imageView2/2/w/1620)

相对于 flv.js的多层分级, hls.js到是有一点扁平化的味道, hls这个公司老总在继承 Observer 的trigger功能之后, 深入各个部门(即各种controller和loader)发号施令(进行hls.trigger(HlsEvents.xxx, data)的操作); 而各个部门继承EventHandler之后, 实例化时就分配好自己所负责的工作; 以 buffer-controller.js 为例:

```javascript
constructor (hls: any) {
    super(hls,
      Events.MEDIA_ATTACHING,
      Events.MEDIA_DETACHING,
      Events.MANIFEST_PARSED,
      Events.BUFFER_RESET,
      Events.BUFFER_APPENDING,
      Events.BUFFER_CODECS,
      Events.BUFFER_EOS,
      Events.BUFFER_FLUSHING,
      Events.LEVEL_PTS_UPDATED,
      Events.LEVEL_UPDATED);
    this.config = hls.config;
  }
```

buffer-controller.js 这个部门主要负责以下功能: 

1. 响应BUFFER_RESET事件, 重置媒体缓冲区
2. 响应BUFFER_CODECS事件, 接收时使用适当的编解码器信息初始化SourceBuffer
3. 响应BUFFER_APPENDING事件, 给SourceBuffer中添加MP4 片段
4. 成功添加缓冲区后触发BUFFER_APPENDED事件
5. 响应BUFFER_FLUSHING事件, 刷新指定的缓冲区范围
6. 成功刷新缓冲区后触发BUFFER_FLUSHED事件

buffer-controller.js 初始化时就定义了自己只响应 Events.MEDIA_ATTACHING, Events.MEDIA_DETACHING 等等这些工作, 它会自己实现 onMediaAttaching,  onMediaDetaching等方法来响应和完成这些工作, 其他的一概不管, 它完成自己的任务后会通过hls向其他部门告知已经完成了自己的工作, 并将工作结果移交给其他部门, 例如 buffer-controller.js 中的 581行 this.hls.trigger(Events.BUFFER_FLUSHED), 这行代码就是向其他部门(其他controllers)告知已经完成BUFFER_FLUSHED的工作;

```javascript
注: 大家在读取hls.js的源码的时候, 看到 `this.hls.trigger(Events.xxxx)`时, 查找下一步骤时, 只要在全部代码中搜索 onXXX(去掉事件中的下划线) 方法即可找到下一步操作
```

明白了HLS.JS代码的读取套路之后我们可以更清晰的了解hls.js实现播放HLS流的大致过程了; 

1. hls.js只播放HLS流, 没有NativePlayer, 所以顶级src/hls.js 对应着 flv.js中的 FLVPlayer, 直接提供API, 响应外界的各种操作和发送信息; 在开始准备播放的时候它会发令HlsEvents.MANIFEST_LOADING,
2. playlist-loader 收到 HlsEvents.MANIFEST_LOADING 后, 它会使用XHRLoader去加载 M3U8文档, 文档经过解析之后会得到该文档含有的level(对于直播行业来说一般就是一个level, level[0] 就是我们想要的数据); playlist-loader 会发出 LEVEL_LOADED 的事件并携带level信息;
3. level-controller会记录level信息, 并计算更新m3u8的时间间隔, 不断加载m3u8文件更新level; 而 stream-controller 则会经过一系列的操作之后去加载 fragment(即m3u8文档中的ts文件); 发出 FRAG_LOADING事件, 并初始化 解码器和转码器 (Demuxer对象, Remuxer会在Demuxer实例化中初始化)
4. FragmentLoader 收到  FRAG_LOADING 之后会去加载相应的TS文件, 并在加载TS文件完毕之后发出 FRAG_LOADED 事件, 并把TS的Uint8数据和fragment的其他信息一并发送出;
5. 在 stream-controller 接收 FRAG_LOADED事件后, 他会调用它的 onFragLoaded 方法, 在这个方法中 demuxer 会解析 TS 的文件, 经过demuxer和remuxer的通力协作, 生成InitSegment(FRAGPARSINGINITSEGMENT事件 所携带的数据) 和 MediaSegment(FRAGPARSING_DATA事件 所携带的数据), 经由 steam-controller 传输给 buffer-controller, 最后添加进SourceBuffer;

## 

## 怎么结合

通过对FLV.js和HLS.js 进行分析, 它们共同的流程都是 下载, 解码, 转码, 传输给SourceBuffer; 一样的loader(FragmentLoader和FetchStreamLoader), 一样的解码和转码(demuxer和remuxer), 一样的 SourceBuffer Controller (MSEController 和 Buffer-controller ); 不同的就是他们的控制流程不一样, 还有hls流多了一步解析文档的步骤; 

下面我们就思考怎么去结合两个lib:

1. 根据项目目的: 项目是一个主直播, 次点播的站点; FLV直播功能是最重要的功能, HLS流的回放只在用户点击视频回顾和查看过去节目视频才会使用;
2. 根据其他项目的需求: 花椒PC端主站（https://www.huajiao.com/）现在也是HTTP-FLV的形式去进行直播展示, 而HLS流计划用于播放主播小视频(点播);
3. 根据业界情况: 现在业界直播基本还是用的HTTP-FLV这种形式(基础设施成熟, 技术简单, 延迟小), 而HLS流一般还是用在移动端直播; 

所以我们决定采用在 FLV.js 的基础上, 加上HLS.js中的 loader, demuxer 和 remuxer 这三部分去组成一个新的播放器library, 既能播放FLV视频, 也能播放HLS流(根据项目的需要只包含单码率流的直播和点播, 不包含多码率流, 自动切换码率, 解密等功能);

## 具体实施过程

首先我们先规划了一下内嵌的功能怎么接入:

Loader的接入

HLS.js中加载HLS流需要 FragmentLoader, XHRLoader, M3U8Parser, LevelController, StreamController 这些, 其中 FragmentLoader 是控制XHR加载TS文件和反馈Fragment加载状态的组件, 

XHRLoader是执行加载 TS 文件和 playlist 文件 的组件, LevelController 是 选择符合当前码率的level 和 playlist加载间隔的, streamController是负责判断加载当前Level中哪个TS文件的组件;

在接入FLV.js时, 需要 FragmentLoader 自己去承担 LevelController 和 StreamController 中相应的工作, 当 IOController 调用 startLoad 方法时, 它自己要去获取并解析playlist, 存储 Level的详细信息, 选择Level, 通过判断 Fragment 的 sequenceNum 来获取下一个TS文件地址, 让XHRLoader 去加载; (FragmentLoader 这娃来到了新公司, 身上担子变重了).

demuxer和remuxer的接入

因为FLV和TS文件的解析方式不同, 但是在TransmuxingController中, 两个都要接入IOController这个统一数据源, 所以把FLV的解码和转码放入到一个FLVCodec的对象中对外输出功能, TS的解码和转码则集中放入TSCodec中对外输出功能; 根据传进来媒体类型实例化解码器和转码器.

IOController和 _mediaCodec 的接入

在 TransmuxingController 中则用 一个 _mediaCodec 对象来管理FLVCodec和TSCodec, 接入数据源IOController时调用两者都拥有的bindDataSource方法; 这里有一点需要注意的是FLVCodec功能会返回一个 number 类型 consumed; 此参数表示FLVCodec功能已解码和转码的输出长度, 需要返回给 IOController, 让 IOController 刨除已解码的数据, 存储未解码的数据, 等下次一起再传给 FLVCodec 功能, 而TSCodec因为TS的文件结构特点(每个TS包都是188字节的整数倍), 所以每次都是全部处理, 只需要返回 consumed = 0 即可;

hls流的点播seek功能的接入

在FLV.js中, 每当SEEK操作时都会MediaInfo中的KeyFrame信息, 去查找相应的Range点, 然后从Range点去加载; 对于hls点播流, 需要对FragmentLoader中的Level信息进行查询, 对每个Fragment进行循环判断 seek的时间点是否处于当前 Fragment 的播放时间, 如果是, 就立即加载即可; 

对各种意外情况的处理

在嵌入的组件中加入logger打印日志, 并将错误返回接入到FLV.JS框架中, 使之能返回响应的错误信息和日志信息;

具体结构如下图: 

![img](https://ask.qcloudimg.com/http-save/yehe-5720403/4lsyqruh3w.png?imageView2/2/w/1620)

除此之外, 我们还做了以下几点:

1. 我们在进行改造的时候还接入了Typescript , 实现对功能参数的类型检查;
2. 在FLV-MP4Remuxer中集成了 jamken (感谢❤ jamken) （https://github.com/jamken） 对 FLV.js 推送的 354PR （https://github.com/bilibili/flv.js/pull/354）, 修正FLV.JS中音视频不同步的问题;
3. 还加入了视频补充增强信息(Supplemental Enhancement Information)的解析, 通过监听HJPlayer.Events.GET_SEI_INFO事件可以得到自定义SEI信息, 格式为Uint8Array; 

## 

## 对视频直播实时互动的尝试

在项目中, 主持人会在节目播放过程中提供事件发展方向的选项, 然后前端会弹出面板, 让用户选择方向, 节目根据答案的方向进行直播表演; 按照以往的方案, 一般这种情况都是选择由 Socket 服务器下发消息, 前端接到消息后展示选项, 然后用户选择, 点击提交答案这么一个流程; 去年阿里云推出了一项新颖的直播答题解决方案; 

选项不再由Socket服务器下发, 而是由视频[云服务器](https://cloud.tencent.com/product/cvm?from=10680)随视频下发; 播放SDK解析视频中的视频补充增强信息, 展示选项; 我们对此方案进行了实践, 大概流程如下:

![img](https://ask.qcloudimg.com/http-save/yehe-5720403/ltuxiyhhan.png?imageView2/2/w/1620)

当主持人提出问题后, 后台人员会在后台填写问题, 经视频云SDK传输给360视频云, 视频云对视频进行处理, 加入视频补充增强信息, 当播放SDK收到带有SEI信息的视频后, 经过解码去重, 将其中包含的信息传递给综艺直播间的互动组件, 互动组件展示, 用户点击选择答案后提交给后台进行汇总, 节目根据汇总后的答案进行节目内容的变更;

与传统方案相比, 采用视频SEI信息传递互动的方案有以下几项优点:

1. 可以实现与主持人的音视频同步出现, 避免因服务器群发消息不及时导致主持人已经宣布开始, 但是面板迟迟不出现的问题.
2. 成本低, 问题是由视频下发而不是由服务器下发, 但延迟会高一点(可提前在视频中插入, 主持人后提出问题, 减少延迟);

视频补充增强信息的内容一般由云服务器来指定内容, 除前16位UUID之外, 内容不尽相同, 所以本播放器直接将SEI信息(Uint8Array格式数据)经GET_SEI_INFO事件抛出, 用户需自行按照己方视频云给定的格式去解析信息; 另外注意SEI信息是一段时间内重复发送的, 所以用户需要自行去重.

## 最后

我们完成了此项目后, 将它应用到花椒PC端主站（https://www.huajiao.com/）播放FLV直播, 除此之外我们还将项目开源HJPlayer（https://github.com/huajiaofrontend/HJPlayer）, 希望能帮助那些碰见同样项目需求的程序员; 如果使用中有问题, 可以在ISSUES中提出, 让我们共同讨论解决。

## 题外

- 有人可能会问 为什么你们的视频回顾不采用FLV文件, 这样就只使用FLV.JS不就可以播放了吗?
- 答:点击视频回顾的时候, 需要播放过去5分钟播过的内容, 如果采用 FLV 文件的话, 那么每次就要从存储的视频中截取一段视频生成 FLV 文件, 然后前端拉取文件播放, 这样会增加一大堆的视频碎片文件, 随之会带来一系列的存储问题; 如果采用HLS流的话, 可以根据前端传回的时间戳, 在存储的HLS回顾文件中查找相应的TS文件, 并生成一份m3u8文档就可以了; 
- 视频补充增强信息(Supplemental Enhancement Information) 是什么?
- 答:视频补充增强信息是H.264视频压缩标准的特性之一, 提供了向视频码流中加入信息的办法; 它并不是解码过程中的必须存在的, 有可能对解码有帮助, 但是没有也没有关系;   在视频内容的生成端、传输过程中，都可以插入SEI 信息。插入的信息，和其他视频内容一起经过网络传输到播放SDK;   在H264/AVC编码格式中NAL uint 中的头部, 有type字段指明 NAL uint的类型, 当 type = 6 时 该NAL uint 携带的信息即为 补充增强信息（SEI）;

关于 SEI信息的解析:

NAL uint type 后下一位即为 SEI 的type, 一般自定义的SEI信息的type 为 5, 即 userdataunregistered; SEI type 的下一位直到0xFF为止即为所携带的数据的长度, 然后就是16位的UUID,

在16位的UUID之后一直到0x00的结束符之间, 即为自定义信息内容, 所以信息内容长度 = SEI信息所携带的数据的长度 - 16位UUID; 自定义信息内容的解析方式就要根据己方视频云给定的数据格式定义了;