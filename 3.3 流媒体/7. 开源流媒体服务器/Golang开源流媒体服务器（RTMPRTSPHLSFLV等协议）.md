- [Golang开源流媒体服务器（RTMP/RTSP/HLS/FLV等协议）](https://www.cnblogs.com/notokoy/p/15987283.html)

## 一. lal 简介

lal是开源直播流媒体网络传输项目，主要由三部分组成：

- lalserver：流媒体转发服务器。类似于`nginx-rtmp-module`等服务，但支持更多的协议，提供更丰富的功能。
- demo：一些小应用，比如推、拉流客户端，压测工具，流分析工具，调度示例程序等。类似于ffmpeg、ffprobe等应用。
- pkg：流媒体协议库。类似于ffmpeg的libavformat等库。

> [lal github地址](https://github.com/q191201771/lal)： https://github.com/q191201771/lal

以下是lal源码架构图，从中你可以大致了解lal是如何划分功能层次的：

![lal源码架构图](https://pengrl.com/lal/_media/lal_src_fullview_frame.jpeg?date=211211)

## 二. lalserver 快速开始

### 1 编译

**方式1，从源码自行编译**

```shell
$git clone https://github.com/q191201771/lal.git
$cd lal
$export GO111MODULE=on && export GOPROXY=https://goproxy.cn,https://goproxy.io,direct
$make
```

或者使用GoLand等IDE编译。
如果没有安装Go编译器，可参考[《CentOS或macOS安装GoLang》](https://pengrl.com/p/34426/)，windows操作系统可自行上网搜索教程。

**方式2，直接下载编译好的二进制可执行文件**

[点我打开《github lal最新release版本页面》](https://github.com/q191201771/lal/releases/latest)，可下载linux/macos/windows平台编译好的lal二进制可执行文件(zip压缩包形式)。

**方式3，使用docker**

docker又分为两种方式，一种是直接从Docker Hub下载已经编译好的镜像并运行：

```yaml
$docker run -it -p 1935:1935 -p 8080:8080 -p 4433:4433 -p 5544:5544 -p 8083:8083 -p 8084:8084 -p 30000-30100:30000-30100/udp q191201771/lal /lal/bin/lalserver -c /lal/conf/lalserver.conf.json
```

另一种是根据本地代码和Dockerfile文件生成镜像并运行：

```shell
$git clone https://github.com/q191201771/lal.git
$cd lal
$docker build -t lal .
$docker run -it -p 1935:1935 -p 8080:8080 -p 4433:4433 -p 5544:5544 -p 8083:8083 -p 8084:8084 -p 30000-30100:30000-30100/udp lal /lal/bin/lalserver -c /lal/conf/lalserver.conf.json
```

### 2 运行

```shell
$./bin/lalserver -c conf/lalserver.conf.json
```

### 3 体验功能

lalserver服务启动后，就可以进行推拉流了。

> [lal github地址](https://github.com/q191201771/lal)： https://github.com/q191201771/lal

## 三. lalserver 简介

lalserver是流媒体转发服务。类似于`nginx-rtmp-module`服务，简单来说，这类服务的核心功能是将推流客户端发送过来的音视频数据转发给对应的拉流客户端。
但lalserver支持更多的协议，提供更丰富的功能。

### 1 lalserver 特性

- 全平台

  **全平台**

  - 支持linux/macOS/windows多系统开发、调试、运行。支持多arch比如amd64/arm64/arm32/ppc64le/mipsle/s390x
  - 支持交叉编译。可在任一平台编译出其他平台的可执行文件
  - 无依赖。生成的可执行文件无任何环境、库依赖，可单文件独立运行
  - (开放源码的同时)提供各平台可执行文件，可免编译直接运行
  - 支持docker

- **高性能****高性能**。多核多线程扩展

- **多种直播流封装协议****多种直播流封装协议**。支持RTMP/RTSP/HTTP-FLV/HTTP-TS/HLS，支持不同封装协议间相互转换

- **多种编码格式****多种编码格式**。视频支持H264/AVC，H265/HEVC，音频支持AAC

- **多种格式录制****多种格式录制**。支持FLV，长MPEGTS，HLS录制(HLS直播与录制可同时开启)

- **HTTPS****HTTPS**。支持HTTPS-FLV，HTTPS-TS，HLS over HTTPS拉流

- **WebSocket/WebSockets****WebSocket/WebSockets**。支持Websocket-FLV，WebSocket-TS拉流

- **HLS****HLS**。支持实时直播、全列表直播。切片文件支持多种删除方式。支持内存切片

- **RTSP**。支持over TCP(interleaved模式)。支持basic/digest auth验证。支持`GET_PARAMETER`**RTSP**。支持over TCP(interleaved模式)。支持basic/digest auth验证。支持`GET_PARAMETER`。兼容对接各种常见H264/H265/AAC实现

- **RTMP****RTMP**。完整支持RTMP协议，兼容对接各种常见RTMP实现。支持给单视频添加静音音频数据，支持合并发送

- **HTTP API接口****HTTP API接口**。用于获取服务信息，向服务发送命令。

- **HTTP Notify事件回调****HTTP Notify事件回调**。

- **支持多种方式鉴权****支持多种方式鉴权**

- **分布式集群****分布式集群**。

- **静态pull回源****静态pull回源**。通过配置文件配置回源地址

- **静态push转推****静态push转推**。支持转推多个地址。通过配置文件配置转推地址

- **CORS跨域****CORS跨域**。支持HTTP-FLV，HTTP-TS，HLS跨域拉流

- **HTTP文件服务器****HTTP文件服务器**。比如HLS切片文件可直接播放，不需要额外的HTTP文件服务器

- **监听端口复用****监听端口复用**。HTTP-FLV，HTTP-TS，HLS可使用相同的端口。over HTTPS类似

- **秒开播放****秒开播放**。GOP缓冲

### 2 lalserver 支持的协议

**封装协议间转换的支持情况**

| 转封装类型      | sub rtmp | sub http[s]/websocket[s]-flv | sub http[s]/websocket[s]-ts | sub hls | sub rtsp | relay push rtmp |
| --------------- | -------- | ---------------------------- | --------------------------- | ------- | -------- | --------------- |
| pub rtmp        | ✔        | ✔                            | ✔                           | ✔       | ✔        | ✔               |
| pub rtsp        | ✔        | ✔                            | ✔                           | ✔       | ✔        | ✔               |
| relay pull rtmp | ✔        | ✔                            | ✔                           | ✔       | X        | .               |

**各封装协议对编码协议的支持情况**

| 编码类型  | rtmp | rtsp | hls  | flv  | mpegts |
| --------- | ---- | ---- | ---- | ---- | ------ |
| aac       | ✔    | ✔    | ✔    | ✔    | ✔      |
| avc/h264  | ✔    | ✔    | ✔    | ✔    | ✔      |
| hevc/h265 | ✔    | ✔    | ✔    | ✔    | ✔      |

**录制文件的类型**

| 录制类型 | hls  | flv  | mpegts |
| -------- | ---- | ---- | ------ |
| pub rtmp | ✔    | ✔    | ✔      |
| pub rtsp | ✔    | ✔    | ✔      |

表格含义见： [连接类型之session pub/sub/push/pull](https://pengrl.com/lal/#/Session)

*注意，如果只是rtsp流（确切的说是rtp包）相互间转发，不涉及到转封装成其他格式，理论上其他编码类型也支持。*

### 3 lalserver 特性图

![lal特性图](https://pengrl.com/lal/_media/lal_feature.jpeg?date=211211)

> [lal github地址](https://github.com/q191201771/lal)： https://github.com/q191201771/lal

## 四. lalserver 各协议推拉流url地址列表

| 协议              | url地址                                                      | 协议标准端口  |
| ----------------- | ------------------------------------------------------------ | ------------- |
| RTMP推流          | rtmp://127.0.0.1:1935/live/test110                           | 1935          |
| RTSP推流          | rtsp://localhost:5544/live/test110                           | 554           |
| .                 | .                                                            | .             |
| RTMP拉流          | rtmp://127.0.0.1:1935/live/test110                           | 1935          |
| HTTP-FLV拉流      | `http://127.0.0.1:8080/live/test110.flv` `https://127.0.0.1:4433/live/test110.flv` (https地址) | 80 443        |
| WebSocket-FLV拉流 | ws://127.0.0.1:8080/live/test110.flv wss://127.0.0.1:4433/live/test110.flv (websockets地址) | 80 443        |
| HLS(m3u8+ts)拉流  | `http://127.0.0.1:8080/hls/test110.m3u8` (直播地址格式1) `http://127.0.0.1:8080/hls/test110/playlist.m3u8` (直播地址格式2) `http://127.0.0.1:8080/hls/test110/record.m3u8` (全量录播地址) | 80            |
| RTSP拉流          | rtsp://localhost:5544/live/test110                           | 554           |
| HTTP-TS拉流       | `http://127.0.0.1:8080/live/test110.ts` (http地址) `https://127.0.0.1:4433/live/test110.ts` (https地址) ws://127.0.0.1:8080/live/test110.ts (websocket地址) wss://127.0.0.1:4433/live/test110.ts (websockets地址) | 80 443 80 443 |

**关于端口**

如果使用协议标准端口，则地址中的端口可以省略，比如http的默认端口是80，则`http://127.0.0.1:80/live/test110.flv`变成`http://127.0.0.1/live/test110.flv`

如果你不熟悉推拉流客户端该如何配合使用，可参考 [常见推拉流客户端信息汇总](https://pengrl.com/lal/#/CommonClient)

## 五. lalserver 配置文件说明

```json
{
  "# doc of config": "https://pengrl.com/lal/#/ConfigBrief", //. 配置文件对应的文档说明链接，在程序中没实际用途
  "conf_version": "0.2.8",                                   //. 配置文件版本号，业务方不应该手动修改，程序中会检查该版本
                                                             //  号是否与代码中声明的一致
  "rtmp": {
    "enable": true,                      //. 是否开启rtmp服务的监听
                                         //  注意，配置文件中控制各协议类型的enable开关都应该按需打开，避免造成不必要的协议转换的开销
    "addr": ":1935",                     //. RTMP服务监听的端口，客户端向lalserver推拉流都是这个地址
    "gop_num": 0,                        //. RTMP拉流的GOP缓存数量，加速流打开时间，但是可能增加延时
                                         //. 如果为0，则不使用缓存发送
    "merge_write_size": 0,               //. 将小包数据合并进行发送，单位字节，提高服务器性能，但是可能造成卡顿
                                         //  如果为0，则不合并发送
    "add_dummy_audio_enable": false,     //. 是否开启动态检测添加静音AAC数据的功能
                                         //  如果开启，rtmp pub推流时，如果超过`add_dummy_audio_wait_audio_ms`时间依然没有
                                         //  收到音频数据，则会自动为这路流叠加AAC的数据
    "add_dummy_audio_wait_audio_ms": 150 //. 单位毫秒，具体见`add_dummy_audio_enable`
  },
  "default_http": {                       //. http监听相关的默认配置，如果hls, httpflv, httpts中没有单独配置以下配置项，
                                          //  则使用default_http中的配置
                                          //  注意，hls, httpflv, httpts服务是否开启，不由此处决定
    "http_listen_addr": ":8080",          //. HTTP监听地址
    "https_listen_addr": ":4433",         //. HTTPS监听地址
    "https_cert_file": "./conf/cert.pem", //. HTTPS的本地cert文件地址
    "https_key_file": "./conf/key.pem"    //. HTTPS的本地key文件地址
  },
  "httpflv": {
    "enable": true,          //. 是否开启HTTP-FLV服务的监听
    "enable_https": true,    //. 是否开启HTTPS-FLV监听
    "url_pattern": "/",      //. 拉流url路由路径地址。默认值为`/`，表示不受限制，路由地址可以为任意路径地址。
                             //  如果设置为`/live/`，则只能从`/live/`路径下拉流，比如`/live/test110.flv`
    "gop_num": 0             //. 见rtmp.gop_num
  },
  "hls": {
    "enable": true,                  //. 是否开启HLS服务的监听
    "enable_https": true,            //. 是否开启HTTPS-HLS监听
                                     //
    "url_pattern": "/hls/",          //. 拉流url路由地址，默认值`/hls/`，对应的HLS(m3u8)拉流url地址：
                                     //  - `/hls/{streamName}.m3u8`
                                     //  - `/hls/{streamName}/playlist.m3u8`
                                     //  - `/hls/{streamName}/record.m3u8`
                                     //
                                     //  playlist.m3u8文件对应直播hls，列表中只保存<fragment_num>个ts文件名称，会持续增
                                     //  加新生成的ts文件，并去除过期的ts文件
                                     //  record.m3u8文件对应录制hls，列表中会保存从第一个ts文件到最新生成的ts文件，会持
                                     //  续追加新生成的ts文件
                                     //
                                     //  ts文件地址备注如下：
                                     //  - `/hls/{streamName}/{streamName}-{timestamp}-{index}.ts` 或
                                     //    `/hls/{streamName}-{timestamp}-{index}.ts`
                                     //
                                     //  注意，hls的url_pattern不能和httpflv、httpts的url_pattern相同
                                     //
    "out_path": "./lal_record/hls/", //. HLS的m3u8和文件的输出根目录
    "fragment_duration_ms": 3000,    //. 单个TS文件切片时长，单位毫秒
    "fragment_num": 6,               //. playlist.m3u8文件列表中ts文件的数量
                                     //
    "delete_threshold": 6,           //. ts文件的删除时机
                                     //  注意，只在配置项`cleanup_mode`为2时使用
                                     //  含义是只保存最近从playlist.m3u8中移除的ts文件的个数，更早过期的ts文件将被删除
                                     //  如果没有，默认值取配置项`fragment_num`的值
                                     //  注意，该值应该不小于1，避免删除过快导致播放失败
                                     //
    "cleanup_mode": 1,               //. HLS文件清理模式：
                                     //
                                     //  0 不删除m3u8+ts文件，可用于录制等场景
                                     //
                                     //  1 在输入流结束后删除m3u8+ts文件
                                     //    注意，确切的删除时间点是推流结束后的
                                     //    `fragment_duration_ms * (fragment_num + delete_threshold)`
                                     //    推迟一小段时间删除，是为了避免输入流刚结束，HLS的拉流端还没有拉取完
                                     //
                                     //  2 推流过程中，持续删除过期的ts文件，只保留最近的
                                     //    `delete_threshold + fragment_num + 1`
                                     //    个左右的ts文件
                                     //    并且，在输入流结束后，也会执行清理模式1的逻辑
                                     //
                                     //  注意，record.m3u8只在0和1模式下生成
                                     //
    "use_memory_as_disk_flag": false //. 是否使用内存取代磁盘，保存m3u8+ts文件
                                     //  注意，使用该模式要注意内存容量。一般来说不应该搭配`cleanup_mode`为0或1使用
  },
  "httpts": {
    "enable": true,         //. 是否开启HTTP-TS服务的监听。注意，这并不是HLS中的TS，而是在一条HTTP长连接上持续性传输TS流
    "enable_https": true,   //. 是否开启HTTPS-TS监听
    "url_pattern": "/"      //. 拉流url路由路径地址。默认值为`/`，表示不受限制，路由地址可以为任意路径地址。
                            //  如果设置为`/live/`，则只能从`/live/`路径下拉流，比如`/live/test110.ts`
  },
  "rtsp": {
    "enable": true, //. 是否开启rtsp服务的监听，目前只支持rtsp推流
    "addr": ":5544" //. rtsp推流地址
  },
  "record": {
    "enable_flv": true,                      //. 是否开启flv录制
    "flv_out_path": "./lal_record/flv/",     //. flv录制目录
    "enable_mpegts": true,                   //. 是否开启mpegts录制。注意，此处是长ts文件录制，hls录制由上面的hls配置控制
    "mpegts_out_path": "./lal_record/mpegts" //. mpegts录制目录
  },
  "relay_push": {
    "enable": false, //. 是否开启中继转推功能，开启后，自身接收到的所有流都会转推出去
    "addr_list":[    //. 中继转推的对端地址，支持填写多个地址，做1对n的转推。格式举例 "127.0.0.1:19351"
    ]
  },
  "relay_pull": {
    "enable": false, //. 是否开启回源拉流功能，开启后，当自身接收到拉流请求，而流不存在时，会从其他服务器拉取这个流到本地
    "addr": ""       //. 回源拉流的地址。格式举例 "127.0.0.1:19351"
  },
  "http_api": {
    "enable": true, //. 是否开启HTTP API接口
    "addr": ":8083" //. 监听地址
  },
  "server_id": "1", //. 当前lalserver唯一ID。多个lalserver HTTP Notify同一个地址时，可通过该ID区分
  "http_notify": {
    "enable": true,                                              //. 是否开启HTTP Notify事件回调
    "update_interval_sec": 5,                                    //. update事件回调间隔，单位毫秒
    "on_server_start": "http://127.0.0.1:10101/on_server_start", //. 各事件HTTP Notify事件回调地址
    "on_update": "http://127.0.0.1:10101/on_update",
    "on_pub_start": "http://127.0.0.1:10101/on_pub_start",
    "on_pub_stop": "http://127.0.0.1:10101/on_pub_stop",
    "on_sub_start": "http://127.0.0.1:10101/on_sub_start",
    "on_sub_stop": "http://127.0.0.1:10101/on_sub_stop",
    "on_rtmp_connect": "http://127.0.0.1:10101/on_rtmp_connect"
  },
  "simple_auth": {                    // 鉴权文档见： https://pengrl.com/lal/#/auth
    "key": "q191201771",              // 私有key，计算md5鉴权参数时使用
    "dangerous_lal_secret": "pengrl", // 后门鉴权参数，所有的流可通过该参数值鉴权
    "pub_rtmp_enable": false,         // rtmp推流是否开启鉴权，true为开启鉴权，false为不开启鉴权
    "sub_rtmp_enable": false,         // rtmp拉流是否开启鉴权
    "sub_httpflv_enable": false,      // httpflv拉流是否开启鉴权
    "sub_httpts_enable": false,       // httpts拉流是否开启鉴权
    "pub_rtsp_enable": false,         // rtsp推流是否开启鉴权
    "sub_rtsp_enable": false,         // rtsp拉流是否开启鉴权
    "hls_m3u8_enable": true           // m3u8拉流是否开启鉴权
  },
  "pprof": {
    "enable": true, //. 是否开启Go pprof web服务的监听
    "addr": ":8084" //. Go pprof web地址
  },
  "log": {
    "level": 1,                         //. 日志级别，0 trace, 1 debug, 2 info, 3 warn, 4 error, 5 fatal
    "filename": "./logs/lalserver.log", //. 日志输出文件
    "is_to_stdout": true,               //. 是否打印至标志控制台输出
    "is_rotate_daily": true,            //. 日志按天翻滚
    "short_file_flag": true,            //. 日志末尾是否携带源码文件名以及行号的信息
    "assert_behavior": 1                //. 日志断言的行为，1 只打印错误日志 2 打印并退出程序 3 打印并panic
  },
  "debug": {
    "log_group_interval_sec": 30,          // 打印group调试日志的间隔时间，单位秒。如果为0，则不打印
    "log_group_max_group_num": 10,         // 最多打印多少个group
    "log_group_max_sub_num_per_group": 10  // 每个group最多打印多少个sub session
  }
}
```

> [lal github地址](https://github.com/q191201771/lal)： https://github.com/q191201771/lal

## 六. Demo 简介

lal项目中，除了[/app/lalserver](https://pengrl.com/lal/#/Lal)这个比较核心的服务之外，在`/app/demo`目录下还额外提供了一些小应用，功能简介：

| demo              | 说明                                                         |
| ----------------- | ------------------------------------------------------------ |
| pushrtmp          | RTMP推流客户端；压力测试工具                                 |
| pullrtmp          | RTMP拉流客户端；压力测试工具                                 |
| pullrtmp2pushrtmp | 从远端服务器拉取RTMP流，并使用RTMP转推出去，支持1对n转推     |
| pullrtmp2pushrtsp | 从远端服务器拉取RTMP流，并使用RTSP转推出去                   |
| pullrtmp2hls      | 从远端服务器拉取RTMP流，存储为本地m3u8+ts文件                |
| pullhttpflv       | HTTP-FLV拉流客户端                                           |
| pullrtsp          | RTSP拉流客户端                                               |
| pullrtsp2pushrtsp | 从远端服务器拉取RTSP流，并使用RTSP转推出去                   |
| pullrtsp2pushrtmp | 从远端服务器拉取RTSP流，并使用RTMP转推出去                   |
| ---               | ---                                                          |
| benchrtmpconnect  | 对rtmp做并发建连压力测试                                     |
| calcrtmpdelay     | 测试rtmp服务器收发数据的延时                                 |
| analyseflv        | 从远端服务器拉取HTTP-FLV流，并进行分析                       |
| dispatch          | 简单演示如何实现一个简单的调度服务，使得多个lalserver节点可以组成一个集群 |
| flvfile2es        | 将本地FLV文件分离成H264/AVC和AAC的ES流文件                   |
| modflvfile        | 修改flv文件的一些信息（比如某些tag的时间戳）后另存文件       |

（更具体的功能参加各源码文件的头部说明）

## 七. 联系作者

- 邮箱：191201771@qq.com
- 微信： q191201771
- QQ： 191201771
- 微信群： 加我微信好友后，告诉我拉你进群
- QQ群： 1090510973
- lal github地址： https://github.com/q191201771/lal
- lal官方文档： https://pengrl.com/lal