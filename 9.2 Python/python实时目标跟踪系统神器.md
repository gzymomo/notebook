- [python实时目标跟踪系统神器](https://mp.weixin.qq.com/s/M54U6ee9R-0KKRra0OcbxA)

在当下自动驾驶、智慧城市、安防等领域对车辆、行人、飞行器等快速移动的物体进行实时跟踪及分析的需求可谓比比皆是， 但单纯的目标检测算法只能输出目标的定位+分类，无法对移动的目标具体的运动行为及特征进行分析，因此在具体的车辆行为分析、交通违章判别、嫌疑犯追踪、飞行器监管等场景，目标追踪发挥着不可替代的作用。

![图片](https://mmbiz.qpic.cn/mmbiz_gif/bRhTPYDIpHI2hQpDGUjdpKtc8ZYA2LKE9rzYnmmn46n6dA6Pc0cpyf7Dd2QtNgRUGbVIEwicEiaZOOcWXIqMN9qw/640?wx_fmt=gif&tp=webp&wxfrom=5&wx_lazy=1)

视频引用公开数据集[1][2][3][4]

但实际目标追踪的项目落地，往往面临被检目标多、相互遮挡、图像扭曲变形、背景杂乱、视角差异大、目标小且运动速度快等产业实际技术难题。

那如何快速实现高性能的目标跟踪任务呢？一个相对完善的目标跟踪任务实现， 往往需要融合目标检测、行人重识别、轨迹融合等多项技术能力，并对上述产业实际的技术难点，分别进行长时间深度优化，同时考虑跨镜头、多类别、小目标跟踪以及轻量化部署等实际业务诉求。

![图片](https://mmbiz.qpic.cn/mmbiz_gif/bRhTPYDIpHI2hQpDGUjdpKtc8ZYA2LKEqIib6zlpztOIpMKHyFxQBiaZyVfqln85KELS1h8z9xkvCLu4BLMgLUHA/640?wx_fmt=gif&tp=webp&wxfrom=5&wx_lazy=1)

难么？别急，近日在GitHub社区发布的一个开源目标跟踪系统—PP-Tracking就能使开发者快速用Python完成一个高性能的目标跟踪任务，并实现服务器侧轻量化上线。

它的具体结构图如下：

![图片](https://mmbiz.qpic.cn/mmbiz_png/bRhTPYDIpHI2hQpDGUjdpKtc8ZYA2LKEHyw9sP0FI3DN8ZlZSQrBiaiabbh864WqEd9ia3eOT630jzgrB7BNye83Q/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

关于详细的结构详解，可以前往具体项目链接查看：

*https://github.com/PaddlePaddle/paddledetection*

当然，如果你觉得项目确实实用，支持开源最好的方式就是点亮Star星标支持一下

![图片](https://mmbiz.qpic.cn/mmbiz_png/bRhTPYDIpHI2hQpDGUjdpKtc8ZYA2LKEV5DQs10v90TicC0qjzWraJ7YXNd4iaIVVeibJLDaJjRUznOXcOJSoSpww/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

本文作者也确实详细研究了一下这个项目，总结了它的一些特点，有耐心的老铁可以接着往下看：

## **1 功能丰富效果佳**

PP-Tracking内置DeepSORT[6]、JDE[7]与FairMOT[8]三种主流高精度多目标跟踪模型，并针对产业痛点、结合实际落地场景进行一系列拓展和优化，覆盖多类别跟踪、跨镜跟踪、流量统计等功能与应用，可谓是精度、性能、功能丰富样样俱全~

- **单镜头跟踪**

单镜头下的单类别目标跟踪是指在单个镜头下，对于同一种类别的多个目标进行连续跟踪，是跟踪任务的基础。针对该任务，PP-Tracking基于端到端的One Shot高精模型FairMOT[8]，替换为更轻量的骨干网络HRNetV2-W18，采用多种Tricks，如Sync_BN与EMA，保持性能的同时大幅提高了精度，并且扩大训练数据集，减小输入尺寸，最终实现服务端轻量化模型在权威数据集MOT17上精度达到MOTA 65.3，在NVIDIA Jetson NX上速度达到23.3FPS，GPU上速度可达到60FPS！同时，针对对精度要求较高的场景，PP-Tracking还提供了精度高达MOTA75.3的高精版跟踪模型~

![图片](https://mmbiz.qpic.cn/mmbiz_gif/bRhTPYDIpHI2hQpDGUjdpKtc8ZYA2LKELmO5EibyvLicDI3QyNC2yNsiaTOkicDFOTfSFyjtlickjOmdESHnFEXbU8Q/640?wx_fmt=gif&tp=webp&wxfrom=5&wx_lazy=1)

视频引用公开数据集[3]

- **多类别跟踪**

PP-Tracking不仅高性能地实现了单镜头下的单类别目标跟踪，更针对多种不同类别的目标跟踪场景，增强了特征匹配模块以适配不同类别的跟踪任务，实现跟踪类别覆盖人、自行车、小轿车、卡车、公交、三轮车等上十种目标，精准实现多种不同种类物体的同时跟踪。

![图片](https://mmbiz.qpic.cn/mmbiz_gif/bRhTPYDIpHI2hQpDGUjdpKtc8ZYA2LKE1gLiczeq4Lx9F5sExFoee3613XJnibRu0kbTKxYeCjsTI9pC9we15RPA/640?wx_fmt=gif&tp=webp&wxfrom=5&wx_lazy=1)

视频引用公开数据集[2]

- **跨镜头跟踪**

安防场景常常会涉及在多个镜头下对于目标物体的持续跟踪。当目标从一个镜头切换到另一个镜头，往往会出现目标跟丢的情况，这时，一个效果好速度快的跨镜头跟踪算法就必不可少了！PP-Tracking中提供的跨镜头跟踪能力基于DeepSORT[6]算法，采用了百度自研的轻量级模型PP-PicoDet和PP-LCNet分别作为检测模型和ReID模型，配合轨迹融合算法，保持高性能的同时也兼顾了高准确度，实现在多个镜头下紧跟目标，无论镜头如何切换、场景如何变换，也能准确跟踪目标的效果。

![图片](https://mmbiz.qpic.cn/mmbiz_gif/bRhTPYDIpHI2hQpDGUjdpKtc8ZYA2LKEA1x2ZDyGtFfTRXrrDxLSYCgt9YTmP8vhiblQSia7x00lKnn0H2e8p0zg/640?wx_fmt=gif&tp=webp&wxfrom=5&wx_lazy=1)

视频引用公开数据集[2]

- **流量监测**

与此同时，针对智慧城市中的高频场景—人/车流量监测，PP-Tracking也提供了完整的解决方案，应用服务器端轻量级版FairMOT[8]模型预测得到目标轨迹与ID信息，实现动态人流/车流的实时去重计数，并支持自定义流量统计时间间隔。

为了满足不同业务场景下的需求，如商场进出口人流监测、高速路口车流量监测等，PP-Tracking更是提供了出入口两侧流量统计方式~

![图片](https://mmbiz.qpic.cn/mmbiz_gif/bRhTPYDIpHI2hQpDGUjdpKtc8ZYA2LKEUBb2y1w0TKxSQAT2fq1ugVagnYPDyl7oXmIpB4S2R8LhtkKh2AqEFQ/640?wx_fmt=gif&tp=webp&wxfrom=5&wx_lazy=1)

视频引用公开数据集[2]

## **2 复杂场景覆盖全**

- **行人、车辆跟踪**

智慧交通中，行人和车辆的场景尤为广泛，因此PP-Tracking针对行人和车辆，提供对应的预训练模型，大幅降低开发成本，节省训练时间和数据成本，实现业务场景直接推理，算法即应用的效果！不仅如此，PP-Tracking支持显示目标轨迹，更直观地辅助实现高效的路径规划分析。

![图片](https://mmbiz.qpic.cn/mmbiz_gif/bRhTPYDIpHI2hQpDGUjdpKtc8ZYA2LKEGpcNZ6b0WdVcwPQ8Vef2YN6jgB89vMtHmwLcmxItq4jyHL4ibEUjiayQ/640?wx_fmt=gif&tp=webp&wxfrom=5&wx_lazy=1)

![图片](https://mmbiz.qpic.cn/mmbiz_gif/bRhTPYDIpHI2hQpDGUjdpKtc8ZYA2LKEWvIKCicnL3Z3AagpA0JqHakAZ3gLmaOIdFHj1goicsmlWFGvaUI9iaCMA/640?wx_fmt=gif&tp=webp&wxfrom=5&wx_lazy=1)

视频引用公开数据集[2]

- **人头跟踪**

不仅如此，除了在日常跟踪任务中拥有极强的通用性，针对实际业务中常常出现目标遮挡严重等问题，PP-Tracking也进行了一系列优化，提供了基于FairMOT[8]训练的人头跟踪模型，并在Head Tracking 2021数据集榜单位居榜首，助力PP-Tracking灵活适配各类行人场景。

![图片](https://mmbiz.qpic.cn/mmbiz_gif/bRhTPYDIpHI2hQpDGUjdpKtc8ZYA2LKEwn44uL8ks6qHQG9HhM7BcDlpNdUoDz34L7Wytkpf4Baiag1vGiapGz7g/640?wx_fmt=gif&tp=webp&wxfrom=5&wx_lazy=1)

视频引用公开数据集[5]

- **小目标跟踪**

针对小目标出现在大尺幅图像中的产业常见难题场景，PP-Tracking进行了一系列的优化，提供专门针对小目标跟踪的预训练模型，实现在特殊场景，如无人机等航拍场景下，也能达到较为精准的效果~

![图片](https://mmbiz.qpic.cn/mmbiz_gif/bRhTPYDIpHI2hQpDGUjdpKtc8ZYA2LKEPtSumTaDibyF1DbXeJ2YqDFuGXoQaulxcCibichyxiczCPZ4OJ68rDTABQ/640?wx_fmt=gif&tp=webp&wxfrom=5&wx_lazy=1)

视频引用公开数据集[2]

## **3 两种使用模式，训练推理灵活掌握**

为了满足不同的开发需求，PP-Tracking支持两种使用方式，无论是想通过代码调用/训练模型，进行快速推理部署，还是想要零代码直接上手使用功能，PP-Tracking通通满足你！

- **API代码调用：**API简洁易用，支持模型调用、训练与推理部署，最大程度降低开发成本的前提下，灵活适配各类场景与任务。

![图片](https://mmbiz.qpic.cn/mmbiz_png/bRhTPYDIpHI2hQpDGUjdpKtc8ZYA2LKEzPdx0H4z33EbLSFnYpPnrsciabmhbWtCBrKYTP8TV9niaPViaZic83x2ibQ/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

- **可视化开发界面：**支持单镜头下的单、多目标跟踪，并覆盖小目标、人/车流量统计等复杂场景及应用，无需任何开发，即可直接体验功能，便于集成于各类硬件。

![图片](https://mmbiz.qpic.cn/mmbiz_gif/bRhTPYDIpHLibvHDmTdbK0NCVvV93dg5ToUBTMGrbYVlZk9bdFs9btSicqdiaqZxwLQDl2j8FhaC7kvw3JvbQSfGg/640?wx_fmt=gif&tp=webp&wxfrom=5&wx_lazy=1)

更贴心的是，PP-Tracking支持Python、C++两种部署语言，同时提供使用飞桨原生推理库Paddle Inference和飞桨服务化推理框架Paddle Serving的保姆级部署教程，真正意义上打通从训练、推理到部署的全流程。

## **4 产业场景快速融合**

这么厉害的实时跟踪系统在实际落地中的表现如何呢？接下来，让我们看看PP-Tracking的实际业务落地效果吧~

以人流量计数为例，在上海音智达公司的实际业务中，使用PP-Tracking中的服务端轻量化版FairMOT[8]，结合人流量计数功能，快速实现商圈出入口的实时人流量去重计数。

![图片](https://mmbiz.qpic.cn/mmbiz_gif/bRhTPYDIpHI2hQpDGUjdpKtc8ZYA2LKEXPzgpMqWcLVdPsmM2qUfX3XHEF3jm1PTuCURUbs7vFepicqkIenGgSQ/640?wx_fmt=gif&tp=webp&wxfrom=5&wx_lazy=1)

视频引用公开数据集[3]