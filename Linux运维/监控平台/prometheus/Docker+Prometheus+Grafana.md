[TOC]

# 模板：

​	node_expoter：8919
​	redis_exporter：763
​	mysql_exporter：7362
​	docker：893、10619
​	JYM：4701
​	SpringBoot：10280

# Docker启动Docker可视化工具：

```shell
docker run -p 9000:9000 --name prtainer -v /var/run/docker.sock:/var/run/docker.sock -d portainer/portainer
```


# 监控平台：

	## 启动服务：

```shell
InfluxDb：/bin/systemctl start influxdb.service
Collectd：/bin/systemctl start collectd.service
Grafana：/bin/systemctl start grafana-server.service
```


	## Grafana账号密码：admin	zlkj0535
	## Collectd库账号密码：root root
	## 数据采集工具Telegraf:
		# 下载安装包

​		wget https://dl.influxdata.com/telegraf/releases/telegraf-1.8.3-1.x86_64.rpm 
​		yum localinstall telegraf-1.8.3-1.x86_64.rpm
​		# 启动命令

```shell
systemctl start telegraf
```

		# 重启命令

```shell
systemctl restart telegraf
```

​	

```shell
Prometheus：
	Redis监控：
		1：现在63（Redis）服务器上，启动redis_exporter。
			./redis_exporter -redis.addr 10.19.64.63:7000 &
			通过netstat -lntp查看redis_exporter是否启动成功。
		2：在master上的普罗米修斯配置prometheus.yml的redis。
			重启prometheus：./prometheus

监控kafka_exporter：
	wget https://github.com/danielqsj/kafka_exporter/releases/download/v1.2.0/kafka_exporter-1.2.0.linux-amd64.tar.gz
	tar -zxvf kafka_exporter-1.2.0.linux-amd64.tar.gz
	分别在三台kafka服务器安装kafka_exporter，然后启动：./kafka_exporter --kafka.server=slave3:9092
	然后在普罗米修斯上注册。

监控linux服务器node_exporter：
	wget node_exporter；然后解压；然后进入到目录，启动：nohup ./node_exporter >> node_exporter.log 2>&1 &
	配置prometheus，重启prometheus，配置Grafana。import json：8919。

Mysqld_exporter:
	nohup ./mysqld_exporter --config.my-cnf=/home/mysql_exporter/mysqld_exporter/my.cnf &
```

# 通过docker配置监控平台：

	## 监控redis：

```shell
docker run -d --name redis_exporter -p 9121:9121 oliver006/redis_exporter --redis.addr redis://192.168.0.50:7001 --redis.password ''
```

	## 监控docker：

```shell
docker run \
--volume=/:/rootfs:ro \
--volume=/var/run:/var/run:ro \
--volume=/sys:/sys:ro \
--volume=/var/lib/docker/:/var/lib/docker:ro \
--volume=/dev/disk/:/dev/disk:ro \
--publish=8081:8080 \
--detach=true \
--name=cadvisor \
google/cadvisor:latest
```

## 监控mysql：

```shell
GRANT REPLICATION CLIENT, PROCESS ON  *.*  to 'exporter'@'%' identified by '123456';
GRANT SELECT ON performance_schema.* TO 'exporter'@'%';
flush privileges;
docker run -d  --name mysqld-exporter -p 9104:9104   -e DATA_SOURCE_NAME="exporter:123456@(ip:3308)/"   prom/mysqld-exporter
```

## Docker安装Grafana：

```shell
docker search grafana
```
对'/var/lib/grafana/plugins'没有权限创建目录，那么就赋予权限：

```shell
chmod 777 /data/grafana
```

```shell
docker run -d -p 3000:3000 --name=grafana -v /data/grafana:/var/lib/grafana grafana/grafana
docker run -d --name=grafana -v /etc/localtime:/etc/localtime:ro --restart=always -p 3000:3000 grafana/grafana 
```

## Docker启动Promethus：

```shell
docker run -d -p 9090:9090 --name=prometheus -v /root/software/prometheus/prometheus-config.yml:/etc/prometheus/prometheus.yml prom/prometheus
---
docker run -d --name=prometheus -p 9090:9090 --restart=always -v /etc/localtime:/etc/localtime:ro  -v /home/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml  prom/prometheus

---
docker run -d --name=prometheus --net=host -v /etc/localtime:/etc/localtime:ro  -v /home/prometheus/prometheus-config.yml:/etc/prometheus/prometheus.yml -v /home/prometheus/java_springboot.yml:/home/prometheus/java_springboot.yml prom/prometheus
```

## Docker监控Kafka：

```shell
docker pull danielqsj/kafka-exporter:latest
docker run -ti --rm -p 9308:9308 danielqsj/kafka-exporter --kafka.server=kafka:9092 [--kafka.server=another-server ...]
```

