[ZLMediaKit支持的事件http api](https://www.jianshu.com/p/72a4fe770de7)



ZLMediaKit可以把内部的一些事件通过调用第三方http服务器api的方式通知出去，以下是相关的默认配置：



```ini
[hook]
enable=1
admin_params=secret=035c73f7-bb6b-4889-a715-d9eb2d1925cc
timeoutSec=10

on_flow_report=https://127.0.0.1/index/hook/on_flow_report
on_http_access=https://127.0.0.1/index/hook/on_http_access
on_play=https://127.0.0.1/index/hook/on_play
on_publish=https://127.0.0.1/index/hook/on_publish
on_record_mp4=https://127.0.0.1/index/hook/on_record_mp4
on_rtsp_auth=https://127.0.0.1/index/hook/on_rtsp_auth
on_rtsp_realm=https://127.0.0.1/index/hook/on_rtsp_realm
on_shell_login=https://127.0.0.1/index/hook/on_shell_login
on_stream_changed=https://127.0.0.1/index/hook/on_stream_changed
on_stream_none_reader=https://127.0.0.1/index/hook/on_stream_none_reader
on_stream_not_found=https://127.0.0.1/index/hook/on_stream_not_found
```

- **enable** :

  是否开启http hook，如果选择关闭，ZLMediaKit将采取默认动作(例如不鉴权等)

- **timeoutSec**：

  事件触发http客户端超时时间。

- **admin_params**：

  超级管理员的url参数，如果访问者参数与此一致，那么rtsp/rtmp/hls/http-flv播放或推流将无需鉴权。该选项用于开发者调试用。

- **on_flow_report**：

  流量统计事件，播放器或推流器断开时并且耗用流量超过特定阈值时会触发此事件，阈值通过配置文件general.flowThreshold配置。

- **on_http_access**：

  访问http文件服务器上hls之外的文件时触发

- **on_play**：

  播放器鉴权事件，rtsp/rtmp/http-flv/hls的播放都将触发此鉴权事件。

- **on_publish**：

  rtsp/rtmp推流鉴权事件。

- **on_record_mp4**:

  录制mp4完成后通知事件。

- **on_rtsp_auth**：

  rtsp专用的鉴权事件，先触发on_rtsp_realm事件然后才会触发on_rtsp_auth事件。

- **on_rtsp_realm**：

  该rtsp流是否开启rtsp专用方式的鉴权事件，开启后才会触发on_rtsp_auth事件。

  需要指出的是rtsp也支持url参数鉴权，它支持两种方式鉴权。

- **on_shell_login**：

  shell登录鉴权，ZLMediaKit提供简单的telnet调试方式

- **on_stream_changed**:

  rtsp/rtmp流注册或注销时触发此事件。

- **on_stream_none_reader**：

  流无人观看时事件，用户可以通过此事件选择是否关闭无人看的流。

- **on_stream_not_found**：

  流未找到事件，用户可以在此事件触发时，立即去拉流，这样可以实现按需拉流。