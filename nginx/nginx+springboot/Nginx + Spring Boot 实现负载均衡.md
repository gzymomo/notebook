[**民工哥**](https://segmentfault.com/u/jishuroad)：[Nginx + Spring Boot 实现负载均衡](https://segmentfault.com/a/1190000037594169)

## **负载均衡介绍**

在介绍Nginx的负载均衡实现之前，先简单的说下负载均衡的分类，主要分为**硬件负载均衡和软件负载均衡**，硬件负载均衡是使用专门的软件和硬件相结合的设备，设备商会提供完整成熟的解决方案，比如F5，在数据的稳定性以及安全性来说非常可靠，但是相比软件而言造价会更加昂贵；软件的负载均衡以Nginx这类软件为主，实现的一种消息队列分发机制。

简单来说所谓的负载均衡就是把很多请求进行分流，将他们分配到不同的服务器去处理。比如我有3个服务器，分别为A、B、C，然后使用Nginx进行负载均衡，使用轮询策略，此时如果收到了9个请求，那么会均匀的将这9个请求分发给A、B、Cf服务器，每一个服务器处理3个请求，这样的话我们可以利用多台机器集群的特性减少单个服务器的压力。

Nginx实现负载均衡的示例图:

![img](https://segmentfault.com/img/remote/1460000037594174)

### 负载均衡策略

NGINX开源支持四种负载平衡方法，而NGINX Plus又增加了两种方法。

1.Round Robin: 对所有的请求进行轮询发送请求，默认的分配方式。

nginx.conf 配置示例:

```
upstream xuwujing {
   server www.panchengming.com;
   server www.panchengming2.com;
}
```

**注:上面的域名也可以用IP替代。**

2.Least Connections：以最少的活动连接数将请求发送到服务器，同样要考虑服务器权重。

nginx.conf 配置示例:

```
upstream xuwujing {
    least_conn;
    server www.panchengming.com;
    server www.panchengming2.com;
}
```

3.IP Hash : 发送请求的服务器由客户机IP地址决定。在这种情况下，使用IPv4地址的前三个字节或整个IPv6地址来计算散列值。该方法保证来自相同地址的请求到达相同的服务器，除非该服务器不可用。

```
upstream xuwujing {
     ip_hash;
     server www.panchengming.com;
     server www.panchengming2.com;
}
```

4.Generic Hash: 请求发送到的服务器由用户定义的键决定，该键可以是文本字符串、变量或组合。

```
upstream xuwujing {
     hash $request_uri consistent;
     server www.panchengming.com;
        server www.panchengming2.com;
 }
```

5.Least Time (NGINX Plus only) – 对于每个请求，NGINX Plus选择具有最低平均延迟和最低活动连接数的服务器，其中最低平均延迟是根据包含least_time指令的下列参数计算的:

- header ：从服务器接收第一个字节的时间。

- last_byte：从服务器接收完整响应的时间。

- last_byte inflight：从服务器接收完整响应的时间。

  upstream xuwujing { least_time header; server www.panchengming.com; server www.panchengming2.com; }

6.Random：每个请求将被传递到随机选择的服务器。如果指定了两个参数，首先，NGINX根据服务器权重随机选择两个服务器，然后使用指定的方法选择其中一个。

- least_conn ：活动连接的最少数量

- least_time=header (NGINX Plus)：从服务器接收响应标头的最短平均时间 ($upstream_header_time)。

- least_time=last_byte (NGINX Plus) ：从服务器接收完整响应的最短平均时间（$upstream_response_time）。

  ```
  upstream xuwujing {
  random two least_time=last_byte;
  server www.panchengming.com;
  server www.panchengming2.com;
  }
  ```

## **Nginx+SpringBoot实现负载均衡**

### 环境准备

- 依赖JDK1.8以上的版本；
- 依赖Nginx环境；

这里的项目就用本人之前的一个springboot项目，SpringBoot的项目地址: [https://github.com/xuwujing/s...](https://github.com/xuwujing/springBoot-study/tree/master/springboot-thymeleaf)

首先我们下载这个项目，输入:`mvn clean package` 将项目进行打包为jar文件,然后将`application.properties`和此jar项目放在一个文件夹中，然后复制该文件夹(这里为了清晰所以进行复制，实际不复制更改端口重启也行)，修改复制文件夹`application.properties`的端口，比如改为8086。

### Nginx 配置

我们找到nginx的配置文件nginx.conf，该配置在**nginx/conf/nginx.conf**目录下，然后我们来修改该配置，新增如下配置:

```
upstream pancm{
   server 127.0.0.1:8085;
   server 127.0.0.1:8086;
}
```

- upstream pancm：定义一个名称，随意就行；
- server + ip:端口 or 域名；

如果不想使用Round Robin策略，也可以换成其他的。

然后在server添加/修改如下配置:

```
server {
        listen       80;
        server_name  127.0.0.1;
        location / {
            root   html;
            proxy_pass http://pancm;
            proxy_connect_timeout 3s;
            proxy_read_timeout 5s;
            proxy_send_timeout 3s;
            index  index.html index.htm;
        }
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
    }
```

配置说明:

- server: 虚拟主机的名称，一个http中可以配置多个server；
- listen：Nginx默认的端口；
- server_name：Nginx服务的地址，可以使用域名，多个用空格分隔。
- proxy_pass：代理路径，一般配置upstream后面的名称用于实现负载均衡，可以直接配置ip进行跳转；

**nginx.conf 完整的配置:**

```yaml
events {
    worker_connections  1024;
}
error_log nginx-error.log info;
http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    keepalive_timeout  65;
      upstream pancm{
       server 127.0.0.1:8085;
       server 127.0.0.1:8086;
    }
    
    server {
        listen       80;
        server_name  127.0.0.1;
        location / {
            root   html;
            proxy_pass http://pancm;
            proxy_connect_timeout 3s;
            proxy_read_timeout 5s;
            proxy_send_timeout 3s;
            index  index.html index.htm;
        }
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
    }
}
```

### 负载均衡测试

在完成Nginx配置之后，我们启动Nginx。**linux**输入`/usr/local/nginx/sbin/nginx -c /usr/local/nginx/conf/nginx.conf`，如果已经启动可以使用`/usr/local/nginx/sbin/nginx -s reload`命令进行热加载配置文件，**Windows**直接点击Nginx目录下的`nginx.exe`或者 `cmd`运行`start nginx`进行启动，如果启动了依旧可以使用`nginx -s reload`进行热加载。

Nginx启动完成之后，我们依次启动刚刚下载的springboot和复制更改端口的项目，输入:`java -jar springboot-jsp-thymeleaf.jar`启动。

都启动成功之后，我们在浏览器输入服务的ip即可进行访问。

示例图:

![img](https://segmentfault.com/img/remote/1460000037594173)

**注:这里我使用的是windows系统做测试，实际linux也是一样的。**

然后我们进行操作，并查看控制台日志！

![img](https://segmentfault.com/img/remote/1460000037594175)

从上述示例图中我们进行4次界面刷新请求，最终平均分配到两个服务中去了，从上述的测试结果中我们实现了负载均衡。

这里我在说一下使用Nginx的注意事项，在进行学习和测试的时候，使用nginx默认的端口实现负载均衡一般没有什么问题，但是当我们在项目中使用的时候，特别有登录界面的并且端口不是80的时候，会出现登录的界面无法跳转，进行调试的话会出现 **net::ERR_NAME_NOT_RESOLVED**这样的错误，出现这个原因的是因为nginx默认的端口是80，那么默认跳转的也是这个，所以出现这种情况的时候，需要在location 下添加proxy_set_header Host $host:port 这个配置，port 和listen 的端口保持一致就可以了。