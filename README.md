个人学习工作笔记总结(包含Java相关，数据库相关，运维相关，docker，Kubernetes，流媒体相关，项目管理相关，代码审查相关，安全渗透相关，开发工具，框架技术等等内容)。

## 介绍
​	个人读书，学习，阅读，工作的笔记库，收藏来自各大博文网站，书籍，小道系统的学习笔记，文章汇总等资源，或总结一些个人学习过程的知识点等。

## 阅读说明

推荐使用Typora阅读本笔记，里面笔记全部为MarkDown格式。

1. 克隆项目到本地

   `git clone https://gitee.com/AiShiYuShiJiePingXing/lovebetterworld.git`

2. 通过Typora打开文件夹浏览



## 大数据

### Flink

### Hadoop

### HBase

### Kafka

### Spark

### Zookeeper



## 开发工具

### Chrome

### Git

### IDEA



## 框架技术

### 日志框架

### Keepalived

### Maven

### Minio-分布式文件存储系统



### MQTT-EMQ消息队列

### Mybatis

1. mybatis
2. mybatis XML映射文件
3. mybatis SQL 语句构建器
4. mybatis 缓存
5. mybatis 动态SQL

### Nginx

### Shiro



### Spring-SpringMVC



### SpringBoot

#### SpringBoot-Docker

#### SpringBoot安全权限

#### SpringBoot的JVM调优

#### SpringBoot基础

#### SpringBoot面试题

#### SpringBoot运维脚本

#### SpringBoot整合中间件



## 流媒体

### 直播

- [如何降低直播延时](https://blog.csdn.net/impingo/article/details/104096040)
- [直播延时讲解](https://blog.csdn.net/impingo/article/details/104079647)
- [直播支持https连接](https://blog.csdn.net/impingo/article/details/105421563)
- [直播系统开发过程中，如何选择流媒体协议？](https://cloud.tencent.com/developer/article/1534015)
- [如何将安防摄像头接入互联网直播服务器](https://blog.csdn.net/impingo/article/details/102907201)

### ffmpeg



- [CentOS7安装ffmpeg](https://www.cnblogs.com/wangrong1/p/11951856.html)

- [ffmpeg架构]()

- [ffmpeg推流rtmp的参数设置](https://blog.csdn.net/impingo/article/details/104163365)

- [FFmpeg Protocols Documentation](https://ffmpeg.org/ffmpeg-protocols.html)

  

  【ffmpeg命令】

- [ffmpeg命令](https://gitee.com/AiShiYuShiJiePingXing/lovebetterworld/tree/master/%E6%B5%81%E5%AA%92%E4%BD%93/ffmpeg/ffmpeg%E5%91%BD%E4%BB%A4)

  【ffmpeg官方文档详解】

  - [ffmpeg官方文档详解](https://gitee.com/AiShiYuShiJiePingXing/lovebetterworld/tree/master/%E6%B5%81%E5%AA%92%E4%BD%93/ffmpeg/ffmpeg%E5%AE%98%E6%96%B9%E6%96%87%E6%A1%A3%E4%B8%AD%E6%96%87)

  

  【架构图】

  [FFmpeg源代码结构图 - 解码](http://blog.csdn.net/leixiaohua1020/article/details/44220151)

  [FFmpeg源代码结构图 - 编码](http://blog.csdn.net/leixiaohua1020/article/details/44226355)

  【通用】

  [FFmpeg 源代码简单分析：av_register_all()](http://blog.csdn.net/leixiaohua1020/article/details/12677129)

  [FFmpeg 源代码简单分析：avcodec_register_all()](http://blog.csdn.net/leixiaohua1020/article/details/12677265)

  [FFmpeg 源代码简单分析：内存的分配和释放（av_malloc()、av_free()等）](http://blog.csdn.net/leixiaohua1020/article/details/41176777)

  [FFmpeg 源代码简单分析：常见结构体的初始化和销毁（AVFormatContext，AVFrame等）](http://blog.csdn.net/leixiaohua1020/article/details/41181155)

  [FFmpeg 源代码简单分析：avio_open2()](http://blog.csdn.net/leixiaohua1020/article/details/41199947)

  [FFmpeg 源代码简单分析：av_find_decoder()和av_find_encoder()](http://blog.csdn.net/leixiaohua1020/article/details/44084557)

  [FFmpeg 源代码简单分析：avcodec_open2()](http://blog.csdn.net/leixiaohua1020/article/details/44117891)

  [FFmpeg 源代码简单分析：avcodec_close()](http://blog.csdn.net/leixiaohua1020/article/details/44206699)

  【解码】

  [图解FFMPEG打开媒体的函数avformat_open_input](http://blog.csdn.net/leixiaohua1020/article/details/8661601)

  [FFmpeg 源代码简单分析：avformat_open_input()](http://blog.csdn.net/leixiaohua1020/article/details/44064715)

  [FFmpeg 源代码简单分析：avformat_find_stream_info()](http://blog.csdn.net/leixiaohua1020/article/details/44084321)

  [FFmpeg 源代码简单分析：av_read_frame()](http://blog.csdn.net/leixiaohua1020/article/details/12678577)

  [FFmpeg 源代码简单分析：avcodec_decode_video2()](http://blog.csdn.net/leixiaohua1020/article/details/12679719)

  [FFmpeg 源代码简单分析：avformat_close_input()](http://blog.csdn.net/leixiaohua1020/article/details/44110683)

  【编码】

  [FFmpeg 源代码简单分析：avformat_alloc_output_context2()](http://blog.csdn.net/leixiaohua1020/article/details/41198929)

  [FFmpeg 源代码简单分析：avformat_write_header()](http://blog.csdn.net/leixiaohua1020/article/details/44116215)

  [FFmpeg 源代码简单分析：avcodec_encode_video()](http://blog.csdn.net/leixiaohua1020/article/details/44206485)

  [FFmpeg 源代码简单分析：av_write_frame()](http://blog.csdn.net/leixiaohua1020/article/details/44199673)

  [FFmpeg 源代码简单分析：av_write_trailer()](http://blog.csdn.net/leixiaohua1020/article/details/44201645)

  【其它】

  [FFmpeg源代码简单分析：日志输出系统（av_log()等）](http://blog.csdn.net/leixiaohua1020/article/details/44243155)

  [FFmpeg源代码简单分析：结构体成员管理系统-AVClass](http://blog.csdn.net/leixiaohua1020/article/details/44268323)

  [FFmpeg源代码简单分析：结构体成员管理系统-AVOption](http://blog.csdn.net/leixiaohua1020/article/details/44279329)

  [FFmpeg源代码简单分析：libswscale的sws_getContext()](http://blog.csdn.net/leixiaohua1020/article/details/44305697)

  [FFmpeg源代码简单分析：libswscale的sws_scale()](http://blog.csdn.net/leixiaohua1020/article/details/44346687)

  [FFmpeg源代码简单分析：libavdevice的avdevice_register_all()](http://blog.csdn.net/leixiaohua1020/article/details/41211121)

  [FFmpeg源代码简单分析：libavdevice的gdigrab](http://blog.csdn.net/leixiaohua1020/article/details/44597955)

  【脚本】

  [FFmpeg源代码简单分析：makefile](http://blog.csdn.net/leixiaohua1020/article/details/44556525)

  [FFmpeg源代码简单分析：configure](http://blog.csdn.net/leixiaohua1020/article/details/44587465)

  【H.264】

  [FFmpeg的H.264解码器源代码简单分析：概述](http://blog.csdn.net/leixiaohua1020/article/details/44864509)

### flv

- [Flv.js全面解析](https://gitee.com/AiShiYuShiJiePingXing/lovebetterworld/tree/master/%E6%B5%81%E5%AA%92%E4%BD%93/flv)
- [Flv文档使用随记](https://gitee.com/AiShiYuShiJiePingXing/lovebetterworld/tree/master/%E6%B5%81%E5%AA%92%E4%BD%93/flv)
- [FLV文件格式](https://gitee.com/AiShiYuShiJiePingXing/lovebetterworld/tree/master/%E6%B5%81%E5%AA%92%E4%BD%93/flv)
- [Flv.js源码-IO部分](https://gitee.com/AiShiYuShiJiePingXing/lovebetterworld/tree/master/%E6%B5%81%E5%AA%92%E4%BD%93/flv)
- [Flv.js源码-flv-demuxer.js](https://gitee.com/AiShiYuShiJiePingXing/lovebetterworld/tree/master/%E6%B5%81%E5%AA%92%E4%BD%93/flv)

### MSE

- [Media Source Extensions](https://gitee.com/AiShiYuShiJiePingXing/lovebetterworld/tree/master/%E6%B5%81%E5%AA%92%E4%BD%93/MSE)

### WebRTC

- [WebRTC](https://gitee.com/AiShiYuShiJiePingXing/lovebetterworld/tree/master/%E6%B5%81%E5%AA%92%E4%BD%93/WebRTC)
- [WebRTC直播](https://gitee.com/AiShiYuShiJiePingXing/lovebetterworld/tree/master/%E6%B5%81%E5%AA%92%E4%BD%93/WebRTC)
- [关于视频会议系统（WebRTC）的反思](https://gitee.com/AiShiYuShiJiePingXing/lovebetterworld/tree/master/%E6%B5%81%E5%AA%92%E4%BD%93/WebRTC)

### hls

- [怎么搭建hls低延时直播（lowlatency hls）](https://blog.csdn.net/impingo/article/details/102558792)

### JavaCV

- [使用JavaCV实现海康rtsp转rtmp实现无插件web端直播（无需转码，低资源消耗）](https://blog.csdn.net/weixin_40777510/article/details/103764198?depth_1-utm_source=distribute.pc_relevant.none-task-blog-BlogCommendFromBaidu-7&utm_source=distribute.pc_relevant.none-task-blog-BlogCommendFromBaidu-7)

### rtmp

- [FFmpeg RTMP推HEVC/H265流](https://blog.csdn.net/smallhujiu/article/details/81703434)
- [分布式直播系统（四）【nginx-rtmp流媒体直播服务器单集群实现方式】](https://blog.csdn.net/impingo/article/details/100379853)

### rtsp

- [掘金：clouding：浏览器播放rtsp视频流解决方案](https://juejin.im/post/5d183a71f265da1b6e65b8ff)
  [利用JAVACV解析RTSP流，通过WEBSOCKET将视频帧传输到WEB前端显示成视频](https://www.freesion.com/article/4840533481/)
  [CSDN：zctel：javacv](https://blog.csdn.net/u013947963/category_9570094.html)
  [CSDN：斑马jio：JavaCV转封装rtsp到rtmp（无需转码，低资源消耗）](https://blog.csdn.net/weixin_40777510/article/details/103764198?depth_1-utm_source=distribute.pc_relevant.none-task-blog-BlogCommendFromBaidu-7&utm_source=distribute.pc_relevant.none-task-blog-BlogCommendFromBaidu-7)
  [博客园：之乏：流媒体](https://www.cnblogs.com/zhifa/tag/%E6%B5%81%E5%AA%92%E4%BD%93/)
  [博客园：断点实验室：ffmpeg播放器实现详解 - 视频显示](https://www.cnblogs.com/breakpointlab/p/13309393.html)
  [Gitee：chengoengvb：RtspWebSocket](https://gitee.com/yzfar/RtspWebSocket)

### video

- [video标签在不同平台上的事件表现差异分析](https://segmentfault.com/a/1190000023519979)



### nginx-rtmp-module

- [Nginx-rtmp 直播媒体实时流实现](https://gitee.com/AiShiYuShiJiePingXing/lovebetterworld/tree/master/%E6%B5%81%E5%AA%92%E4%BD%93/nginx-rtmp-module)
- [nginx搭建RTMP视频点播、直播、HLS服务器](https://gitee.com/AiShiYuShiJiePingXing/lovebetterworld/tree/master/%E6%B5%81%E5%AA%92%E4%BD%93/nginx-rtmp-module)
- [rtmp-nginx-module实现直播状态、观看人数控制](https://gitee.com/AiShiYuShiJiePingXing/lovebetterworld/tree/master/%E6%B5%81%E5%AA%92%E4%BD%93/nginx-rtmp-module)
- [实现nginx-rtmp-module多频道输入输出与权限控制](https://gitee.com/AiShiYuShiJiePingXing/lovebetterworld/tree/master/%E6%B5%81%E5%AA%92%E4%BD%93/nginx-rtmp-module)
- [直播流媒体入门(RTMP篇)](https://gitee.com/AiShiYuShiJiePingXing/lovebetterworld/tree/master/%E6%B5%81%E5%AA%92%E4%BD%93/nginx-rtmp-module)



### nginx-http-flv-module

- [nginx-http-flv-module](https://gitee.com/AiShiYuShiJiePingXing/lovebetterworld/tree/master/%E6%B5%81%E5%AA%92%E4%BD%93/nginx-http-flv-module)



个人总结的思维导图：

- [流媒体](https://gitee.com/AiShiYuShiJiePingXing/lovebetterworld/tree/master/%E6%B5%81%E5%AA%92%E4%BD%93/%E6%80%9D%E7%BB%B4%E5%AF%BC%E5%9B%BE)
- [流媒体，flv.js，MSE](https://gitee.com/AiShiYuShiJiePingXing/lovebetterworld/tree/master/%E6%B5%81%E5%AA%92%E4%BD%93/%E6%80%9D%E7%BB%B4%E5%AF%BC%E5%9B%BE)

其他博文：

- [Nginx-rtmp rtmp、http-flv、http-ts、hls、hls+ 配置说明](https://gitee.com/AiShiYuShiJiePingXing/lovebetterworld/tree/master/%E6%B5%81%E5%AA%92%E4%BD%93)

- [知乎：chapin：基于 H5 的直播协议和视频监控方案](https://zhuanlan.zhihu.com/p/100519553?utm_source=wechat_timeline)

- [前端 Video 播放器 | 多图预警](https://juejin.im/post/5f0e52fe518825742109d9ee)

- [分布式直播系统（三）【Nginx-rtmp rtmp、http-flv、http-ts、hls、hls+ 配置说明】](https://blog.csdn.net/impingo/article/details/99703528)

- [流媒体相关介绍](https://gitee.com/AiShiYuShiJiePingXing/lovebetterworld/tree/master/%E6%B5%81%E5%AA%92%E4%BD%93)

- [在HTML5上开发音视频应用的五种思路](https://gitee.com/AiShiYuShiJiePingXing/lovebetterworld/tree/master/%E6%B5%81%E5%AA%92%E4%BD%93)

- [流媒体资源](https://gitee.com/AiShiYuShiJiePingXing/lovebetterworld/tree/master/%E6%B5%81%E5%AA%92%E4%BD%93)




## 前端相关

### HTML



### Javascript



### node



### vue



### webpack



## 设计模式

### 策略模式

### 代理模式

### 单例模式

### 迭代器模式

### 复合模式

### 观察者模式

### 简单工厂、工厂、抽象工厂

### 建造者模式

### 门面模式

### 命令模式

### 模板方法模式

### 桥接模式

### 生成器和责任链模式

### 适配器和外观模式

### 享元模式

### 蝇量和解释器模式

### 原型模式和访问者模式

### 中介者和备忘录模式

### 装饰者模式

### 状态模式

### 组合模式



## 数据库

### Druid



### MongoDB



### MySQL

#### 分库分表

#### 数据库备份

#### 思维导图

#### mysql笔记

#### mysql脚本

#### mysql面试题

#### mysql权限命令

#### mysql设计及规范

#### mysql数据类型

#### mysql索引

#### mysql锁及事务

#### mysql性能测试及优化

#### mysql优化

#### mysql中间件-工具

#### mysql5.7版本配置文件



### PostgresSQL

#### PostGis

#### Postgres



### Redis

### Redis实战



## 网络安全-Web

### 安全运维

#### 安全运维

#### METASPLOIT



### 等保测试



### 加密算法



### 数据脱敏



### 网站安全



### Beef



### Web渗透

#### 网络渗透

##### Web渗透

##### Web渗透博文



## 微服务

### SkyWalking-分布式链路追踪

### SpringCloud



## 微信公众号-小程序开发

### 微信公众号

### 微信小程序



## 项目管理

### 测试流程规范

### 代码审查

### 架构

### 接口管理

### 可持续集成

### 日志管理

### 数据可视化

### 图床管理

### 团队管理

### 文件管理

### 项目管理

![](.\img\project.png)

## 性能测试

### 基准测试

### 全链路测试

### 性能测试报告

### 性能测试工程师

### 性能测试面试

### 性能测试实施指南

### 性能测试系列博文

### Jmter

### LoadRunner

### postman

### sysbench



## 研究技术

### AI-OCR图片-文字识别

### TestNG



## 云原生

### Kubernetes

#### 1. K3S



#### 2. K8S项目交付

##### 2.1 持续部署

##### 2.2 持续集成

##### 2.3 集群监控

##### 2.4 配置中心

##### 2.5 日志收集





#### 3. K8S学习笔记

##### 3.1 K8S-Helm

##### 3.2 K8S集群安全机制

##### 3.3 K8S集群资源监控

##### 3.4 K8S容器交付流程及部署项目

##### 3.5 K8S学习笔记



#### 4. KubeOperator

##### 4.1 KubeOperator介绍



#### 5. KubeSphere

##### 5.1 KubeSphere容器平台的价值

##### 5.2 KubeSphere简介

##### 5.3 KubeSphere多租户管理平台



![](.\img\k8s.png)



- 



## Docker

### Docker思维导图

### Docker Compose

### Docker Machine

### Docker Swarm

### Docker基础

### Docker 镜像

### Docker 容器

### Docker与SpringBoot

### Docker运维

![](.\img\docker.png)







## Java

### Java日志框架

### Java线程池

### Java爬虫

![/img/java.jpg](.\img\java.png)

### JVM

#### CPU OOM实战

#### JVM诊断工具

![](.\img\jvm.png)

## 运维笔记

### 堡垒机

### 防火墙配置

### 监控工具

### 监控平台

### 免密登录

### 内存-CPU运维

### linux杀毒软件

### 新服务器配置

### 运维笔记

### 运维工具

### 自动化运维

### NFS

### Shell脚本









