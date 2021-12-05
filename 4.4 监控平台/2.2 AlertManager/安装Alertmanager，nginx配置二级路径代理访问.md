- [安装Alertmanager，nginx配置二级路径代理访问](https://www.cnblogs.com/sanduzxcvbnm/p/15588243.html)

# 安装配置 Alertmanager

```bash
wget https://github.com/prometheus/alertmanager/releases/download/v0.20.0/alertmanager-0.20.0.linux-amd64.tar.gz
tar -zxv -f alertmanager-0.20.0.linux-amd64.tar.gz -C /usr/local
cd /usr/local
mv alertmanager-0.20.0.linux-amd64/ alertmanager

groupadd prometheus
useradd -g prometheus -m -d /var/lib/prometheus -s /sbin/nologin prometheus

chown -R prometheus.prometheus alertmanager/ # alertmanager.service启动文件中会用到prometheus用户
```

# 创建启动文件

> Alertmanager 安装目录下默认有 alertmanager.yml 配置文件，可以创建新的配置文件，在启动时指定即可。

```bash
vim /usr/lib/systemd/system/alertmanager.service 

[Unit]
Description=alertmanager
Documentation=https://github.com/prometheus/alertmanager
After=network.target

[Service]
Type=simple
User=prometheus
ExecStart=/usr/local/alertmanager/alertmanager --config.file=/usr/local/alertmanager/alertmanager.yml --storage.path=/usr/local/alertmanager/data
Restart=on-failure

[Install]
WantedBy=multi-user.target
systemctl daemon-reload
systemctl start alertmanager.service 
systemctl status alertmanager.service 
systemctl enable alertmanager.service 
```

# 启动命令参考参数

```bash
# ./alertmanager --help
usage: alertmanager [<flags>]

Flags:
  -h, --help                     Show context-sensitive help (also try --help-long and --help-man).
      --config.file="alertmanager.yml"  
                                 Alertmanager configuration file name.
      --storage.path="data/"     Base path for data storage.
      --data.retention=120h      How long to keep data for.
      --alerts.gc-interval=30m   Interval between alert GC.
      --web.config.file=""       [EXPERIMENTAL] Path to configuration file that can enable TLS or
                                 authentication.
      --web.external-url=WEB.EXTERNAL-URL  
                                 The URL under which Alertmanager is externally reachable (for
                                 example, if Alertmanager is served via a reverse proxy). Used for
                                 generating relative and absolute links back to Alertmanager itself.
                                 If the URL has a path portion, it will be used to prefix all HTTP
                                 endpoints served by Alertmanager. If omitted, relevant URL components
                                 will be derived automatically.
      --web.route-prefix=WEB.ROUTE-PREFIX  
                                 Prefix for the internal routes of web endpoints. Defaults to path of
                                 --web.external-url.
      --web.listen-address=":9093"  
                                 Address to listen on for the web interface and API.
      --web.get-concurrency=0    Maximum number of GET requests processed concurrently. If negative or
                                 zero, the limit is GOMAXPROC or 8, whichever is larger.
      --web.timeout=0            Timeout for HTTP requests. If negative or zero, no timeout is set.
      --cluster.listen-address="0.0.0.0:9094"  
                                 Listen address for cluster. Set to empty string to disable HA mode.
      --cluster.advertise-address=CLUSTER.ADVERTISE-ADDRESS  
                                 Explicit address to advertise in cluster.
      --cluster.peer=CLUSTER.PEER ...  
                                 Initial peers (may be repeated).
      --cluster.peer-timeout=15s  
                                 Time to wait between peers to send notifications.
      --cluster.gossip-interval=200ms  
                                 Interval between sending gossip messages. By lowering this value
                                 (more frequent) gossip messages are propagated across the cluster
                                 more quickly at the expense of increased bandwidth.
      --cluster.pushpull-interval=1m0s  
                                 Interval for gossip state syncs. Setting this interval lower (more
                                 frequent) will increase convergence speeds across larger clusters at
                                 the expense of increased bandwidth usage.
      --cluster.tcp-timeout=10s  Timeout for establishing a stream connection with a remote node for a
                                 full state sync, and for stream read and write operations.
      --cluster.probe-timeout=500ms  
                                 Timeout to wait for an ack from a probed node before assuming it is
                                 unhealthy. This should be set to 99-percentile of RTT (round-trip
                                 time) on your network.
      --cluster.probe-interval=1s  
                                 Interval between random node probes. Setting this lower (more
                                 frequent) will cause the cluster to detect failed nodes more quickly
                                 at the expense of increased bandwidth usage.
      --cluster.settle-timeout=1m0s  
                                 Maximum time to wait for cluster connections to settle before
                                 evaluating notifications.
      --cluster.reconnect-interval=10s  
                                 Interval between attempting to reconnect to lost peers.
      --cluster.reconnect-timeout=6h0m0s  
                                 Length of time to attempt to reconnect to a lost peer.
      --log.level=info           Only log messages with the given severity or above. One of: [debug,
                                 info, warn, error]
      --log.format=logfmt        Output format of log messages. One of: [logfmt, json]
      --version                  Show application version.
```

# nginx子路径代理不需要额外的其他配置

> 注意：promethes配置nginx访问子路径设置的是：--web.external-url，但是alertmanager不需要该配置

比如：

```bash
# cat /usr/lib/systemd/system/alertmanager.service
[Unit]
Description=alertmanager
After=network.target

[Service]
Type=simple
User=prometheus
ExecStart=/usr/local/alertmanager/alertmanager --config.file=/usr/local/alertmanager/alertmanager.yml --storage.path=/usr/local/alertmanager/data
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

nginx反向代理设置

```bash
location /alertmanager/ {
    proxy_pass http://192.168.0.185:9093/;
    proxy_set_header Host $host:$server_port;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Real-PORT $remote_port;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
}
```