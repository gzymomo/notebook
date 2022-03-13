- [Docker容器日志配置简介_迷途的攻城狮-CSDN博客_docker容器日志配置](https://blog.csdn.net/chenleiking/article/details/89047341)

# [Docker](https://so.csdn.net/so/search?q=Docker&spm=1001.2101.3001.7020)日志驱动简介

## 1、简介

通常，我们可以使用`docker logs`来查看容器的日志信息，这是因为docker帮我们将容器内主进行打印到标准输出到信息记录了下来，以便于在需要时获取容器的运行信息。

Docker提供多种容器日志记录机制，这种日志机制称之为：[logging drivers](https://docs.docker.com/config/containers/logging/configure/)。docker默认的logging driver为json-file，将日志信息以json格式记录到文件中。除非在启动容器时单独指定，否则，所有的container都将使用默认的日志记录机制。

除了使用docker提供的logging driver，你还可以实现和使用[logging driver plugins](https://docs.docker.com/config/containers/logging/plugins/)。

## 2、配置默认的logging driver

Docker可以通过设置daemon.json文件中log-driver的值来设置默认的logging driver。daemon.json的存放路径为：/etc/docker/daemon.json。例如下面的配置，将默认的logging drive设置为syslog：

```json
{
  "log-driver": "syslog"
}
123
```

如果对应logging driver具有配置项，可以通过log-opts进行配置：

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3",
    "labels": "production_status",
    "env": "os,customer"
  }
}
123456789
```

> 注意：log-opts中的配置项仅接受字符串类型的值，对应数字或者布尔类型必须使用双引号

如果你没有设置log-driver，默认值为json-file，因此，诸如`docker inspect`之类的命令的输出将是json格式。

查看docker当前默认的logging driver：

```shell
chenleis-MacBook-Pro:~ chenlei$ docker info --format '{{.LoggingDriver}}'
json-file
12
```

## 3、为容器指定logging driver

当启动一个容器时，可以使用–log-driver指定当前容器的logging driver，并且可以使用–log-opt选择为其指定配置项。即使容器使用默认的logging driver，依然可以使用–log-opt进行配置覆盖。

例如，下面的例子讲使用none作为logging driver，即不做任何日志记录：

```shell
chenleis-MacBook-Pro:~ chenlei$ docker run -it --log-driver none busybox sh
1
```

查看指定容器的logging driver：

```shell
chenleis-MacBook-Pro:~ chenlei$ docker inspect -f '{{.HostConfig.LogConfig.Type}}' ceab39dd4b57
none
12
```

## 4、日志内容传输模式

Docker提供两种模式讲日志从容器传输到log-driver：

- blocking：默认传输模式，日志信息直接从容器传递给log-driver。
- non-blocking：为每个容器分配一个缓冲队列，日志信息首先放入缓冲队列，log-driver消费队列中的日志。

`non-blocking`避免了因为日志压力导致的应用程序阻塞，当STDOUT或者STDERR阻塞时，应用程序可能会出现异常。

> 注意，当缓冲队列满时，为了保证新的日志消息继续加入队列，队列中最老的日志将会被删除。

可以通过–log-opt中的mode选项来决定使用blocking模式或者non-blocking模式。

当使用non-blocking模式时，可以使用max-buffer-size选项来设置缓冲队列的大小，默认大小为1MB。

下面的例子将容器的日志传输模式设置为non-blocking模式，且缓冲队列大小为4MB：

```shell
chenleis-MacBook-Pro:~ chenlei$ docker run -it --rm --log-opt mode=non-blocking --log-opt max-buffer-size=4m busybox sh
1
```

查看容器日志配置信息如下：

```shell
chenleis-MacBook-Pro:~ chenlei$ docker inspect -f '{{.HostConfig.LogConfig}}' c98987df1428
{json-file map[max-buffer-size:4m mode:non-blocking]}
12
```

## 5、目前docker支持的logging driver

| Driver                                                       | Description                                                  |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| `none`                                                       | No logs are available for the container and `docker logs` does not return any output. |
| [`json-file`](https://docs.docker.com/config/containers/logging/json-file/) | The logs are formatted as JSON. The default logging driver for Docker. |
| [`local`](https://docs.docker.com/config/containers/logging/local/) | Writes logs messages to local filesystem in binary files using Protobuf. |
| [`syslog`](https://docs.docker.com/config/containers/logging/syslog/) | Writes logging messages to the `syslog` facility. The `syslog` daemon must be running on the host machine. |
| [`journald`](https://docs.docker.com/config/containers/logging/journald/) | Writes log messages to `journald`. The `journald` daemon must be running on the host machine. |
| [`gelf`](https://docs.docker.com/config/containers/logging/gelf/) | Writes log messages to a Graylog Extended Log Format (GELF) endpoint such as Graylog or Logstash. |
| [`fluentd`](https://docs.docker.com/config/containers/logging/fluentd/) | Writes log messages to `fluentd` (forward input). The `fluentd` daemon must be running on the host machine. |
| [`awslogs`](https://docs.docker.com/config/containers/logging/awslogs/) | Writes log messages to Amazon CloudWatch Logs.               |
| [`splunk`](https://docs.docker.com/config/containers/logging/splunk/) | Writes log messages to `splunk` using the HTTP Event Collector. |
| [`etwlogs`](https://docs.docker.com/config/containers/logging/etwlogs/) | Writes log messages as Event Tracing for Windows (ETW) events. Only available on Windows platforms. |
| [`gcplogs`](https://docs.docker.com/config/containers/logging/gcplogs/) | Writes log messages to Google Cloud Platform (GCP) Logging.  |
| [`logentries`](https://docs.docker.com/config/containers/logging/logentries/) | Writes log messages to Rapid7 Logentries.                    |

## 6、注意事项

`docker logs`命令仅支持json-file和journald两种类型，其他driver无法使用该命令。

## 7、参考资料

https://docs.docker.com/config/containers/logging/configure/