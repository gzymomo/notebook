- [vivo直播应用技术实践与探索](https://blog.51cto.com/u_14291117/4990736)

## 一、概述

2019年vivo直播平台立项，初期与优秀的顶部直播平台进行联运直播开发，进行市场，产品和技术的初步探索；再到后来为了丰富直播的内容和形式，开始自己独立探索；之后，我们结合vivo现阶段的直播业务，陆续完成了泛娱乐，互动，公司事件直播等多种直播形式的落地，相信后续根据业务的规划，我们会给用户带来更好的直播体验。
今天和大家分享一下，vivo直播平台这两年相关的技术发展历程，希望大家对直播有一个基础的了解，如果有相关的同学刚刚开始从事直播相关业务的开发，能够给大家带来一些启发。

## 二、业务背景介绍

截止到目前为止，vivo直播平台支持三个大类的直播，第一个就是经典的泛娱乐秀场直播，平台提供秀场直播一些标准的功能，例如互动聊天，PK，送礼等基础功能。泛娱乐直播市场起步比较早，相关的功能玩法也比较丰富和多样，例如主播连麦PK,主播与用户连麦互动，礼物连击，事件榜单，你画我猜等等相关的娱乐功能，目前平台正在持续迭代相关经典的功能，持续给用户带来更好的用户体验。
第二种类型的直播就是目前基于实时音视频技术的低时延互动直播，低时延直播的特点就是互动性强，用户的参与感强，与之而来的就是较强的技术挑战和较高的维护成本。
第三种，就是目前在疫情的大背景下，诞生了公司信息分发的事件直播，例如公司年会，校招宣讲会直播，品牌文化直播，疫情防护知识直播。这类直播的最大特点就是灵活、多变、且内容形式多样。对于直播平台来说，我们需要为其提供一站式的直播解决方案，方便公司利用直播这种形式进行更好更稳定的品牌，文化的宣发。

![image-20220211090412351](https://gitee.com/er-huomeng/l-img/raw/master/l-img/image-20220211090412351.png)

首先，我们再来看下vivo直播平台的一个业务架构模型，底层是我们的公司全链路监控平台，会对直播流量、网络、相关直播业务的数据指标进行监控，并提供相关告警服务，便于我们能够第一时间响应、定位并解决直播在各个模块在分发过程中遇到的一些实际问题。
在此监控之上，我们进行上层业务的逻辑迭代。在直播内容的分发上，主要的方式还是依赖于云厂商的CDN和我们内部的直播服务器集群。一种是C端的直接流量分发，另一种是通过内部转拉进行相关的业务处理。在业务能力方面，目前我们已经初步具备了如下一些基础能力，例如海量的信息存储、视频处理、内容识别、直播视频内容的安全合规实时审核及直播间事件同步异步处理等能力。同时基于这些能力进行SDK的封装，例如推流、播放、IM 等场景化SDK，通过提供标准的SDK进行直播能力的分发和复用，同时也能够方便业务方进行功能的集成。
在内容产出和对外服务上，我们对自己的手机APP，例如i视频、vivo短视频、i音乐、浏览器等APP进行直播能力的赋能，丰富消费者的手机体验。此外，除了对vivo相关手机APP进行直播能力的支持外，我们也会和第三方直播平台进行合作，做一些内容的分发和转播。

![image-20220211090423006](https://gitee.com/er-huomeng/l-img/raw/master/l-img/image-20220211090423006.png)

## 三、技术实践

### 3.1 泛娱乐秀场直播

首先，我们先介绍一下最经典的泛娱乐秀场直播，如下图所示，这是一套基于RTMP协议的标准直播流程。

![image-20220211090431047](https://gitee.com/er-huomeng/l-img/raw/master/l-img/image-20220211090431047.png)

一般过程如下，首先进行输入源的采集，一般由屏幕、摄像头、麦克风等进行相关采集；接下来对其进行图像加工，例如美颜，滤镜，水印等；之后进行标准的h264编码，利用RTMP协议传输，传输到中心机房对相关事件做好相应的处理后，最后分发到边缘节点，用户终端逆向去边缘节点拉取直播流，最后在终端设备解码播放。在此标准观看流程之上，泛娱乐秀场直播也会提供一些常见的功能，例如互动聊天，直播间小游戏，PK ，送礼等等。
这一套标准直播流程涉及到的直播技术点也特别多，接下来和大家具体聊一聊我们团队在落地相关直播业务过程中遇到的一些实际问题。
我们遇到如下四个问题，开播工具的推流美颜就是我们遇到的第一个技术难点，主播众多，对“美”的定义不一，主观性强，个性化需求多，在贴纸，色温，画面的饱和感等方面要求较高，同时在开播过程中，要求面部的不抖动不失真，同时对直播画面的清晰度，颗粒感也有相关的要求。
第二个问题就是消息的分发，也就是我们传统说的IM即时通讯技术，与传统的即时通讯技术不一样的是，除了群聊，私聊，广播这些经典的IM消息分发场景外，“群”成员不稳定也是我们需要考虑的，用户频繁进出直播间，切换直播间，晚高峰的消息风暴和流量突刺，也是我们需要应对和解决的问题。
第三个问题就是直播时延的问题，这也是直播经典的问题之一，引起时延的因素很多，例如终端设备，传输协议，网络带宽，编解码等等。
最后一个问题，就是直播成本的问题，想必做过直播的相关友商，都会清楚地知道，RTMP和CDN不分家，作为基础的云服务产品，CDN对于这种流媒体的分发，计费也是相对比较贵的，所以我们也要在确保产品功能和用户体验的基础上，兼顾控制我们的直播成本。

![image-20220211090439934](https://gitee.com/er-huomeng/l-img/raw/master/l-img/image-20220211090439934.png)

针对第一个技术难点，我们做了如下处理，我们在端上进行了一些技术优化。在美颜方面，充分利用了公司影像团队相关的技术积累，对美颜，滤镜，贴纸，美妆，风格妆都进行了标准化，通用化，定制化的处理。
同时我们在推流模块也做了一系列的实验，进行云端转码，超分，锐化等处理，确保每一个主播的画风具备一定的观众吸引力。礼物动画播放部分，经过多次实验采用MP4进行特效礼物动画播放，测试数据表明，MP4相对于svga占用的内存和文件大小显著降低。最后在直播间秒开这个重要指标上，播放器内核团队对播放器进行了定制化处理，通过共享播放器、滑动、点击预创建等方式，使得直播间秒开这个指标能够达到行业内一流标准。

![image-20220211090450263](https://gitee.com/er-huomeng/l-img/raw/master/l-img/image-20220211090450263.png)

第二部分，我们再介绍一下直播的另一个问题，就是即时消息的处理，潜在的问题可以从以下两个维度进行分析。首先是用户维度，用户的主动行为包括送礼，礼物连击、点赞，互动聊天，以及在开播时瞬间涌入的大量的用户，这些场景都会引起IM的消息洪峰，使得服务器的负载压力一下子会提高很多，纵使我们把IM模块组件化，进行模块间的隔离，但是突发的IM流量也会影响其他高优先级或者系统消息的分发。
第二个方面就是系统维度，在群发消息的场景下，也会有一个读扩散的问题，并且针对直播间这个场景，导致我们IM分发的也都是结构化的数据，有些特别复杂的业务场景，结构化的数据包体积也比较大，在这种情况下如果瞬时分发的消息比较多，会导致机房的出口带宽存在一定的压力；第二个影响因素就是手机终端消息处理能力也有一定的限制，如果分发过多的消息，而部分消息的特效又比较复杂的话，部分低端手机机型会存在无法即时处理的问题。
在这些场景限制下，我们做了如下的三个方案，第一就是消息推拉结合，业务流量高峰IM长链接和http短轮询共同作业；第二个就是消息使用protobuf压缩和分级限频，对直播间的消息进行业务和主播两个维度分级，限制不同类型不同直播间分发的频率；最后一个方案就是监控降级，我们可以对指定直播间进行监控，在监控出现问题的时候，能够自动切换消息分发的方式，确保消息的到达率。

![image-20220211090459334](https://gitee.com/er-huomeng/l-img/raw/master/l-img/image-20220211090459334.png)

第三个就是直播时延问题，其实在直播时延的问题的处理上，我们希望能够做到在特定的直播场景下规避不必要的时延，从而能够达到标准的直播时延，而不是一味的追求极致的低时延。要解决直播时延的问题，首先我们要分析出产生时延的几个环节，并且梳理这些环节上我们能够做的优化。采集端主要受缓存策略和数据编码所影响，同时网络环境、传输协议和物理距离也都会对时延产生一定的影响，针对这些问题，我们收集了主播的手机型号和实际网络环境，根据实际情况进行相应清晰度的编码，弱化机型和网络对直播的影响。
其次我们都知道另外80%的时延是在下游CDN播放环节产生的，在播放端，为了抗卡顿，需要做缓冲自适应，码率自适应，前向纠错，丢包重传等工作，因为协议本身的限制，我们只能根据不同的用户终端分发不同协议和不同清晰度的观看链接，同时我们针对特殊的场景引入新的直播协议，例如WebRTC,QUIC,SRT等。
最后一个方面，就是泛娱乐直播成本问题，作为业务部门，成本也是我们一直关注的，直播的费用主要有存储和带宽两个主要组成部分，我们做了如下三个方面的优化，存储上，我们首先将主播的录像进行转码，降低存储文件的大小，其次对主播进行热度分级，进行不同时间的存储处理，最后也会剪辑相关的精彩瞬间，在符合国家相关法规的基础上，删除原文件，从而降低存储的费用。
第二个就是基础服务CDN费用，云厂商的收费方式有按照带宽峰值和流量这两种，所以我们也会从业务的角度上，进行一定程度的策略优化，针对推送场景，我们会分批次分时间段进行推送，防止大量直播观看用户同时瞬时涌入直播间，打高直播的带宽峰值。同时观看端支持多清晰度，根据业务出现的不同流量时间段，分发不同清晰度的观看链接，最后从策略上进行限制，在进行主播运营的时候，进行科学的开播时间规划，防止高流量主播扎堆开播，造成不必要的峰值带宽而带来的额外流量费用，最后一个就是监控，对每一个周期的费用进行判断和计算，通过实际的使用情况，对下一个周期进行阶段性调整，确保能够得到阶段收费较优解。

![image-20220211090508770](https://gitee.com/er-huomeng/l-img/raw/master/l-img/image-20220211090508770.png)

### 3.2 互动直播

分析完了泛娱乐秀场直播的几个经典问题的解决方案后，我们也来也介绍一下目前如火如荼的低时延的互动直播，互动直播核心特点就是超低时延，互动性强，在一定的业务场景下，对各类消息分发的顺序性和实时性的要求也特别高，目前常见的互动直播，目前业界内落地比较好的场景就是电商，教育，连麦互动娱乐，政企直播等。
与互动直播相关的功能和技术主要如上所示，例如多端的信息同步，媒体处理，与泛娱乐直播相比，在流媒体安全审核，多用户终端一致性上，也有更加严格的要求，相关的技术栈，很大一部分都是基于实时音视频技术，并且也会结合一下SEI技术，进行信息顺序同步，一般来说，是可以满足业务的需求。
我们在落地互动直播的时候主要遇到两个业务痛点，第一个痛点就是，基于RTMP协议的一个冗长的直播链路的秒级时延是很难胜任的，并且基于RTMP协议的多终端媒体流画面处理，例如连麦，混流。静音等场景，RTMP处理相对复杂，且不利于多终端同步。第二个方面就是信息管控方面，信息管控也是我们在实际开发过程中遇到的问题，例如终端一致性管控，流媒体安全管控，异常管控等。在实际生产环境下，因为存在大量的多终端的互动，互动过程中产生大量的消息，部分业务场景会存在消息分发的时候出现延迟、顺序错乱、甚至丢失，最终导致各个业务终端出现状态不一致的问题，这也是目前，互动直播除了时延外，另一个比较明显的问题。

![image-20220211090516814](https://gitee.com/er-huomeng/l-img/raw/master/l-img/image-20220211090516814.png)

针对互动直播的低时延多互动的业务特点，目前业内的标准解决方案是RTC相关的技术，  RTC与RTMP+CDN这两个解决方案从技术特点上来说，是完全不一样的，RTMP的技术特点就是与CDN绑定耦合，RTMP需要借助CDN边缘网络的能力，使得多地区的用户能够就近获取直播内容，并且能够提高用户获取直播视频流的成功率和秒开率，但是也是因为受限于网络协议等因素，带来了对应的延迟是RTMP技术协议栈所无法避免的。而RTC的也有两个比较明显的技术特点，基于UDP协议的RTC理论时延在百毫秒内，第二个特点就是借助SFU和MCU通信方式适合做多端交互，当然，在多端互动的场景下RTC对机器和网络的要求也比较高，所以我们也会针对指定场景，运用不同的相关技术去解决实际问题。

![image-20220211090527422](https://gitee.com/er-huomeng/l-img/raw/master/l-img/image-20220211090527422.png)

在互动直播的开发过程中，我们遇到了信息管控的一系列问题，首当其冲的就是**一致性管控**，互动直播业务内容信息和流媒体信息强相关，需要实时进行无差别的信息顺序传递，我们做了如下的一些补偿控制，进行客户端单个和批量信息上报，由服务端纠正个别终端的异常状态；第二就是合理使用SEI，在视频流信息携带少量的业务信息，例如K歌房、带货、直播答题等，这样能够保证信息的一致性和同步性。

第二个就是**安全性管控**，按照国家相关规定，音视频直播内容是否违规是相关部门重点审核的对象，在秀场直播这边，我们目前做了视频流定时截帧审核，使用机审和人审双重审核机制，互动直播方面，则会对每一个终端进行独立审核，精确识别出违规的互动终端，最终打造绿色健康的直播环境。最后一个场景也是业务复杂性决定的，正因为互动终端设备多。人为、网络、设备等因素导致异常概率也大大增加，所以我们要准备快速识别断流，有效地利用回调或者客户端能力范围内的上报，在做好业务校验后，进行相关的异常恢复流程的处理。第二就是利用心跳检测机制，客户端定时上报心跳，如果服务端超过指定次数没有收到相关的心跳，就能识别出该设备出现异常，同样进行相关的异常逻辑处理。

### 3.3 事件直播

最后一个模块，我们再重点介绍一下直播平台给公司内部相关业务进行直播赋能的案例。vivo公司日常也会有很多官方的事件直播，例如技术分享、校招宣讲会、疫情知识宣讲、品牌形象直播，以及更具有官方性的手机发布会直播。

**为什么在这里会重点提及公司直播呢？**

首先就是官方组织，影响面比较巨大，受众群体也比其他类型的直播更大，我们投入开发运维和保障直播的精力也会相比其他直播更多。在公司直播这块也进行了一些技术的归纳和总结。首先需要保证整场直播的稳定性和流畅性，我们对网络进行相关的监控和优化，同时搭建多地域的内部直播服务器做好多地域的流量隔离和负载均衡。另一个方面就是针对灵活性的技术支持，为了节省我们的开发时间，在助力几场大型公司直播之后，我们也系统地进行整理，归纳出一些通用的功能SDK,通过使用这些多次实践证明没有问题的SDK能够降低直播出错的概率，也能够提高整场直播的成功率。
接下来讲两个比较有意思的案例，也是我们在探索实践公司内部直播几个比较有趣且实用的案例，第一个案例就是我们去年公司因为疫情的原因，只能举办线上直播年会，vivo的员工办公地点很多，坐落在全国各个地方，所以如何高效地保障国内外多个办公地点的万名员工同时高清观看就是我们当时需要解决的问题。
这个问题的根本原因就是每个办公地区的出口带宽是有限的，如果公司员工都使用公司无线网络观看的时候，会导致个办公地区的出口带宽被打满，从而会影响部分员工观看的体验，甚至会影响大家的日常办公。
针对带宽限制的问题，一般而言，业界有两个比较通用的解决方案；

- 临时提高各个办公地点网络运营商的出口带宽；
- 通过降低直播的码率以来降低带宽的压力和成本。

其实这两种方案都不能完全保障直播没有问题，并且前提还是需要牺牲部分用户的观看体验的基础上，这种方案也是很难接受的。最后落地并成功实践的方案就是通过内网转推，内网服务器再做负载均衡，并且不同办公地点的观看请求通过DNS解析到本地办公地点的直播服务器，这样就可以成功解决带宽的问题，并且还可以支持高清4k的清晰度。目前这个能力已经被多次验证可行，相关的实践细节也在多家权威技术网站发表，得到社区的一致好评，如果大家有兴趣可以进行相关的查阅。

![image-20220211090536824](https://gitee.com/er-huomeng/l-img/raw/master/l-img/image-20220211090536824.png)

第二个有趣的案例，就是公司日常的发布会、宣讲会，需要同时推流到多个第三方直播平台，例如B站，腾讯直播等等。因为推流设备推流有个数限制，无法支持多个推流地址，之前的方案都是协调各个直播转播合作伙伴，拉群同步一个拉流地址，每次都会有大量的协调沟通确认工作，很大程度上影响大家的效率，并且很容易出现部分合作商因为配置错误，导致无法正常直播。
在这个大的背景下，我们做出了一些调整，通过整合内部直播服务器和云直播服务器，做好对应的网络容灾，在主线网络出现问题的时候，能够系统自动识别并更换到另一个推流集群，最终保证直播全程的流畅性和稳定性，此外我们还搭建了人工运营平台，提前系统的配置好相关的地址，并且通过开放平台，合作方可以临时去修改相关的配置，这样可以大大降低人工配置错误的可能性，可以更高效率的对公司相关的直播进行支持。

![image-20220211091352822](https://gitee.com/er-huomeng/l-img/raw/master/l-img/image-20220211091352822.png)

## 四、总结

![image-20220211091406032](https://gitee.com/er-huomeng/l-img/raw/master/l-img/image-20220211091406032.png)

目前vivo直播平台还处于初步搭建和不断摸索的过程中，不过我们的方向和规划是清晰的，就是通过不断地丰富C端直播形式，引入更多形式的直播，给vivo手机用户带来更好的用户体验，同时进行相关技术的沉淀和积累，最后把这些技术形成一些标准的解决方案，向公司的横向部门进行内容和技术的产出，例如技术SDK服务，内部直播服务，直播短视频服务等等，形成内外平台相互反哺的良性循环。