[TOC]
Prometheus 监控之 Blackbox_exporter黑盒监测[icmp、tcp、http(get\post)、dns、ssl证书过期时间]

# 1、blackbox_exporter概述
blackbox_exporter是Prometheus 官方提供的 exporter 之一，可以提供 http、dns、tcp、icmp 的监控数据采集。
## 1.1 Blackbox_exporter 应用场景
 1. HTTP 测试
  - 定义 Request Header 信息
  - 判断 Http status / Http Respones Header / Http Body 内容
 2. TCP 测试
  - 业务组件端口状态监听
  - 应用层协议定义与监听
 3. ICMP 测试
  - 主机探活机制
 4. POST 测试
  - 接口联通性
 5. SSL 证书过期时间

# 2、blackbox_exporter安装
## 2.1 Docker方式安装
```shell
docker pull prom/blackbox-exporter

docker run -d -p 9115:9115 --name blackbox-exporter  prom/blackbox-exporter
```
## 2.2 宿主机安装
各个版本的blackbox_exporter https://github.com/prometheus/blackbox_exporter/releases
以linux系统为例，下载编译好的二进制包，解压使用：
```bash
wget https://github.com/prometheus/blackbox_exporter/releases/download/v0.16.0/blackbox_exporter-0.16.0.linux-amd64.tar.gz
tar -zxvf blackbox_exporter-0.16.0.linux-amd64.tar.gz -C /data
mv /data/blackbox_exporter-0.16.0.linux-amd64 /data/blackbox_exporter
```
验证是否安装成功：
```bash
# cd /data/blackbox_exporter/
# ./blackbox_exporter --version
```
启动：
```
nohup ./blackbox_exporter &

blackbox_exporter --web.listen-address=:9115 --config.file=blackbox.yml
```
默认监听端口为9115:
```bash
# ss -tunlp|grep 9115
tcp    LISTEN     0      32768                  *:9115                  *:*      users:(("blackbox_export",29880,3))
```

# 3、blackbox_exporter配置
基本的配置：
```yml
modules:
  http_2xx:  # http 监测模块
    prober: http
    http:
  http_post_2xx: # http post 监测模块
    prober: http
    http:
      method: POST
  tcp_connect: # tcp 监测模块
    prober: tcp
  ping: # icmp 检测模块
    prober: icmp
    timeout: 5s
    icmp:
      preferred_ip_protocol: "ip4"
```


# 四、prometheus配置
## 4.1 ping检测
在内网可以通过ping (icmp)检测服务器的存活，以前面的最基本的module配置为例，在Prometheus的配置文件中配置使用ping module：
```yml
- job_name: 'ping_all'
    scrape_interval: 1m
    metrics_path: /probe
    params:
      module: [ping]
    static_configs:
     - targets:
        - 192.168.1.2
       labels:
         instance: node2
     - targets:
        - 192.168.1.3
       labels:
         instance: node3
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - target_label: __address__
        replacement: 127.0.0.1:9115 # black_exporter 这里和Prometheus在一台机器上
```
通过配置文件可以很直接的看出Prometheus使用black_exporter作为代理使用black_exporter配置的module检测各个target的状态。 下面是一个http://127.0.0.1:9115/probe?module=ping&target=192.168.1.2返回的是192.168.1.2这个target的metrics。
```yml
#DNS解析时间,单位 s
probe_dns_lookup_time_seconds 0.039431355
#探测从开始到结束的时间,单位 s,请求这个页面响应时间
probe_duration_seconds 0.651619323

probe_failed_due_to_regex 0

#HTTP 内容响应的长度
probe_http_content_length -1
#按照阶段统计每阶段的时间
probe_http_duration_seconds{phase="connect"} 0.050388884   #连接时间
probe_http_duration_seconds{phase="processing"} 0.45868667 #处理请求的时间
probe_http_duration_seconds{phase="resolve"} 0.040037612  #响应时间
probe_http_duration_seconds{phase="tls"} 0.145433254    #校验证书的时间
probe_http_duration_seconds{phase="transfer"} 0.000566269
#重定向的次数
probe_http_redirects 1
#ssl 指示是否将 SSL 用于最终重定向
probe_http_ssl 1
#返回的状态码
probe_http_status_code 200
#未压缩的响应主体长度
probe_http_uncompressed_body_length 40339
#http 协议的版本
probe_http_version 1.1
#使用的 ip 协议的版本号
probe_ip_protocol 4

probe_ssl_earliest_cert_expiry 1.59732e+09
#是否探测成功
probe_success 1
#TLS 的版本号
probe_tls_version_info{version="TLS 1.2"} 1
```
## 4.2 http监测
以前面的最基本的module配置为例，在Prometheus的配置文件中配置使用http_2xx module：
```yml
- job_name: 'http_get_all'  # blackbox_export module
    scrape_interval: 30s
    metrics_path: /probe
    params:
      module: [http_2xx]
    static_configs:
      - targets:
        - https://frognew.com
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: 127.0.0.1:9115 #blackbox-exporter 所在的机器和端口
```
http检测除了可以探测http服务的存活外，还可以根据指标probe_ssl_earliest_cert_expiry进行ssl证书有效期预警。

## 4.3 监控主机存活状态
```yml
- job_name: node_status
    metrics_path: /probe
    params:
      module: [icmp]
    static_configs:
      - targets: ['10.165.94.31']
        labels:
          instance: node_status
          group: 'node'
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - target_label: __address__
        replacement: 172.19.155.133:9115
```
10.165.94.31是被监控端ip，172.19.155.133是Blackbox_exporter
## 4.4 监控主机端口存活状态
```yml
- job_name: 'prometheus_port_status'
    metrics_path: /probe
    params:
      module: [tcp_connect]
    static_configs:
      - targets: ['172.19.155.133:8765']
        labels:
          instance: 'port_status'
          group: 'tcp'
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: 172.19.155.133:9115
```
## 4.5 监控网站状态
```yml
- job_name: web_status
    metrics_path: /probe
    params:
      module: [http_2xx]
    static_configs:
      - targets: ['http://www.baidu.com']
        labels:
          instance: user_status
          group: 'web'
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - target_label: __address__
        replacement: 172.19.155.133:9115
```


# 5、prometheus告警规则
```yml
groups:
- name: example
  rules:
  - alert: curlHttpStatus
    expr:  probe_http_status_code{job="blackbox-http"}>=400 and probe_success{job="blackbox-http"}==0
    #for: 1m
    labels:
      docker: number
    annotations:
      summary: '业务报警: 网站不可访问'
      description: '{{$labels.instance}} 不可访问,请及时查看,当前状态码为{{$value}}'
```

# 6、Grafana
grafana模板号：9965。
此模板需要安装饼状图插件 下载地址 https://grafana.com/grafana/plugins/grafana-piechart-panel
安装插件，重启grafana生效。

```bash
grafana-cli plugins install grafana-piechart-panel
service grafana-server restart
```

## 6.1 访问grafana
### ![](https://img2018.cnblogs.com/i-beta/1341090/201912/1341090-20191211144145141-1494317472.png)