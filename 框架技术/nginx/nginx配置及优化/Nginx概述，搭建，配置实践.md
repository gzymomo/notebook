- [nginx配置静态资源访问](https://www.cnblogs.com/qingshan-tang/p/12763522.html)
- [微信公众号：民工哥技术之路：dunwu](https://mp.weixin.qq.com/s?__biz=MzI0MDQ4MTM5NQ==&mid=2247494790&idx=2&sn=acc3075a8b5e59824baf31a2b81b560b&chksm=e918899ade6f008cf7abb6864dbf8ca3c3e94e54c66115272a36f2df390c44ce0538ad4de1a1&scene=126&sessionid=1592266153&key=4b0291f9d497b1b0e5b13537eabdfd65f20e3711275ab33a24b1d57b7c3d58d658efa1c467b3b39845ea1832cc3275dd9265d9471b9fc4fc5008b22b4fabd2c0b8396baf2f796f35d88e133adb455b2a&ascene=1&uin=MjkxMzM3MDgyNQ%3D%3D&devicetype=Windows+10+x64&version=62090070&lang=zh_CN&exportkey=A7TErMfk%2F0DnI53DaeMrKg4%3D&pass_ticket=LPvgPt7Z83HVbqEBiCUd4DpwbsYcB0xQVnfUjoxD5EVKc%2FNZ85pmeMbzepgknOxS)
- [Nginx日志的标准格式](http://www.cnblogs.com/kevingrace/p/5893499.html)
- [民工哥](https://segmentfault.com/u/jishuroad)：[Nginx + Spring Boot 实现负载均衡](https://segmentfault.com/a/1190000037594169)
- [Nginx 高性能优化配置实战总结](https://segmentfault.com/a/1190000037788252)



# Nginx概述

## 什么是nginx？

Nginx (engine x) 是一款轻量级的 Web 服务器 、反向代理服务器及电子邮件（IMAP/POP3）代理服务器。

主要的优点是：

1. 支持高并发连接，尤其是静态界面，官方测试Nginx能够支撑5万并发连接

2. 内存占用极低

3. 配置简单，使用灵活，可以基于自身需要增强其功能，同时支持自定义模块的开发

   使用灵活：可以根据需要，配置不同的负载均衡模式，URL地址重写等功能

4. 稳定性高，在进行反向代理时，宕机的概率很低

5. 支持热部署，应用启动重载非常迅速

## 什么是反向代理？

反向代理（Reverse Proxy）方式是指以代理服务器来接受 internet 上的连接请求，然后将请求转发给内部网络上的服务器，并将从服务器上得到的结果返回给 internet 上请求连接的客户端，此时代理服务器对外就表现为一个反向代理服务器。

## Nginx在架构体系中的作用

- 网关 （面向客户的总入口）
- 虚拟主机（为不同域名 / ip / 端口提供服务。如：VPS虚拟服务器）
- 路由（正向代理 / 反向代理）
- 静态服务器
- 负载集群（提供负载均衡）

### 网关

网关：可以简单的理解为用户请求和服务器响应的关口，即面向用户的总入口

网关可以拦截客户端所有请求，对该请求进行权限控制、负载均衡、日志管理、接口调用监控等，因此无论使用什么架构体系，都可以使用`Nginx`作为最外层的网关

## Nginx的模块化设计

先来看看`Nginx`模块架构图：

![img](https://img-service.csdnimg.cn/img_convert/79582de2c354d30e744f4501d8a97bb9.png)

这5个模块由上到下重要性一次递减。

（1）核心模块；

核心模块是Nginx服务器正常运行必不可少的模块，如同操作系统的内核。它提供了Nginx最基本的核心服务。像进程管理、权限控制、错误日志记录等；

（2）标准HTTP模块；

标准HTTP模块支持标准的HTTP的功能，如：端口配置，网页编码设置，HTTP响应头设置等；

（3）可选HTTP模块；

可选HTTP模块主要用于扩展标准的HTTP功能，让Nginx能处理一些特殊的服务，如：解析GeoIP请求，SSL支持等；

（4）邮件服务模块；

邮件服务模块主要用于支持Nginx的邮件服务；

（5）第三方模块；

第三方模块是为了扩展Nginx服务器应用，完成开发者想要的功能，如：Lua支持，JSON支持等；

> 模块化设计使得Nginx方便开发和扩展，功能很强大

## Nginx的请求处理流程

基于上文中的`Nginx`模块化结构，我们很容易想到，在请求的处理阶段也会经历诸多的过程，`Nginx`将各功能模块组织成一条链，当有请求到达的时候，请求依次经过这条链上的部分或者全部模块，进行处理，每个模块实现特定的功能。

一个 HTTP Request 的处理过程：

- 初始化 HTTP Request
- 处理请求头、处理请求体
- 如果有的话，调用与此请求（URL 或者 Location）关联的 handler
- 依次调用各 phase handler 进行处理
- 输出内容依次经过 filter 模块处理

![img](https://img-service.csdnimg.cn/img_convert/24705580acc67bbc31ef929e59892bf4.png)

## Nginx的多进程模型

Nginx 在启动后，会有一个 `master`进程和多个 `worker`进程。

`master`进程主要用来管理`worker`进程，包括接收来自外界的信号，向各 worker 进程发送信号，监控 worker 进程的运行状态以及启动 worker 进程。

`worker`进程是用来处理来自客户端的请求事件。多个 worker 进程之间是对等的，它们同等竞争来自客户端的请求，各进程互相独立，一个请求只能在一个 worker 进程中处理。worker 进程的个数是可以设置的，一般会设置与机器 CPU 核数一致，这里面的原因与事件处理模型有关

Nginx 的进程模型，可由下图来表示：

![img](https://img-service.csdnimg.cn/img_convert/8fa2a3b1b24bffd339a32dfb227aefa6.png)

这种设计带来以下优点：

**1） 利用多核系统的并发处理能力**

现代操作系统已经支持多核 CPU 架构，这使得多个进程可以分别占用不同的 CPU 核心来工作。Nginx 中所有的 worker 工作进程都是完全平等的。这提高了网络性能、降低了请求的时延。

**2） 负载均衡**

多个 worker 工作进程通过进程间通信来实现负载均衡，即一个请求到来时更容易被分配到负载较轻的 worker 工作进程中处理。这也在一定程度上提高了网络性能、降低了请求的时延。

**3） 管理进程会负责监控工作进程的状态，并负责管理其行为**

管理进程不会占用多少系统资源，它只是用来启动、停止、监控或使用其他行为来控制工作进程。首先，这提高了系统的可靠性，当 worker 进程出现问题时，管理进程可以启动新的工作进程来避免系统性能的下降。其次，管理进程支持 Nginx 服务运行中的程序升级、配置项修改等操作，这种设计使得动态可扩展性、动态定制性较容易实现。



## nginx常用命令

```bash
nginx -s stop       快速关闭Nginx，可能不保存相关信息，并迅速终止web服务。
nginx -s quit       平稳关闭Nginx，保存相关信息，有安排的结束web服务。
nginx -s reload     因改变了Nginx相关配置，需要重新加载配置而重载。
nginx -s reopen     重新打开日志文件。
nginx -c filename   为 Nginx 指定一个配置文件，来代替缺省的。
nginx -t            不运行，而仅仅测试配置文件。nginx 将检查配置文件的语法的正确性，并尝试打开配置文件中所引用到的文件。
nginx -v            显示 nginx 的版本。
nginx -V            显示 nginx 的版本，编译器版本和配置参数。
```



# 一、Nginx的安装

## 1.1 二进制安装

Nginx 是 C语言 开发，建议在 Linux 上运行，当然，也可以安装 Windows 版本，本篇则使用 [CentOS](http://www.linuxidc.com/topicnews.aspx?tid=14) 7 作为安装环境。

### 1. 基础环境配置

**一. gcc 安装**

安装 nginx 需要先将官网下载的源码进行编译，编译依赖 gcc 环境，如果没有 gcc 环境，则需要安装：

```bash
yum install gcc-c++
```

**二. PCRE pcre-devel 安装**

PCRE(Perl Compatible Regular Expressions) 是一个Perl库，包括 perl 兼容的正则表达式库。nginx 的 http 模块使用 pcre 来解析正则表达式，所以需要在 linux 上安装 pcre 库，pcre-devel 是使用 pcre 开发的一个二次开发库。nginx也需要此库。命令：

```bash
yum install -y pcre pcre-devel
```

**三. zlib 安装**

zlib 库提供了很多种压缩和解压缩的方式， nginx 使用 zlib 对 http 包的内容进行 gzip ，所以需要在 Centos 上安装 zlib 库。

```bash
yum install -y zlib zlib-devel
```

**四. OpenSSL 安装**

OpenSSL 是一个强大的安全套接字层密码库，囊括主要的密码算法、常用的密钥和证书封装管理功能及 SSL 协议，并提供丰富的应用程序供测试或其它目的使用。 nginx 不仅支持 http 协议，还支持 https（即在ssl协议上传输http），所以需要在 Centos 安装 OpenSSL 库。

```shell
yum install -y openssl openssl-devel
```

### 2. 官网下载安装包

1.直接下载`.tar.gz`安装包，地址：https://nginx.org/en/download.html

![nginx.png](http://www.linuxidc.com/upload/2016_09/160905180451092.png)

2.使用`wget`命令下载（推荐）。

```bash
wget -c https://nginx.org/download/nginx-1.16.1.tar.gz
```

![nginx-wget.png](http://www.linuxidc.com/upload/2016_09/160905180451091.png)

### 3. 解压

依然是直接命令：

```bash
tar -zxvf nginx-1.16.1.tar.gz
cd nginx-1.16.1
```

### 4. 配置

1. 使用默认配置

```bash
./configure
```

2. 自定义配置（不推荐，除非需要自定义一些动态的module，比如流媒体或其他方面的使用）

```bash
./configure \
--prefix=/usr/local/nginx \
--conf-path=/usr/local/nginx/conf/nginx.conf \
--pid-path=/usr/local/nginx/conf/nginx.pid \
--lock-path=/var/lock/nginx.lock \
--error-log-path=/var/log/nginx/error.log \
--http-log-path=/var/log/nginx/access.log \
--with-http_gzip_static_module \
--http-client-body-temp-path=/var/temp/nginx/client \
--http-proxy-temp-path=/var/temp/nginx/proxy \
--http-fastcgi-temp-path=/var/temp/nginx/fastcgi \
--http-uwsgi-temp-path=/var/temp/nginx/uwsgi \
--http-scgi-temp-path=/var/temp/nginx/scgi
```

> 注：将临时文件目录指定为/var/temp/nginx，需要在/var下创建temp及nginx目录

### 5. 编译安装

```bash
make
make install
```

查找安装路径：

```bash
whereis nginx
```

### 6. 启动、停止nginx

```bash
cd /usr/local/nginx/sbin/
# 启动命令
./nginx 

# 停止命令
./nginx -s stop

# 终止命令
./nginx -s quit

# 重新加载
./nginx -s reload
```

> `./nginx -s quit`:此方式停止步骤是待nginx进程处理任务完毕进行停止。 `./nginx -s stop`:此方式相当于先查出nginx进程id再使用kill命令强制杀掉进程。

查询nginx进程：

```bash
ps aux | grep nginx
```

### 7. 重启 nginx

1. 先停止再启动（推荐）： 对 nginx 进行重启相当于先停止再启动，即先执行停止命令再执行启动命令。如下：

```bash
cd /usr/local/nginx/sbin/
# 先停止在启动
./nginx -s quit
./nginx
```

2. .重新加载配置文件： 当 ngin x的配置文件 nginx.conf 修改后，要想让配置生效需要重启 nginx，使用`-s reload`不用先停止 ngin x再启动 nginx 即可将配置信息在 nginx 中生效，如下： 


```bash
cd /usr/local/nginx/sbin/
# 检查配置文件是否有误
./nginx -t
# 重新加载配置文件
./nginx -s reload
```

### 8. 开机启动

即在`rc.local`增加启动代码就可以了。

```bash
vi /etc/rc.local
```

增加一行 `/usr/local/nginx/sbin/nginx` 设置执行权限：

```bash
chmod 755 rc.local
```

![nginx-rclocal.png](http://www.linuxidc.com/upload/2016_09/160905180451095.png)

到这里，nginx就安装完毕了，启动、停止、重启操作也都完成了。



## 1.2 Docker方式安装

只需要执行一条命令即可：

```bash
docker run -d -p 8095:80 --name nginx-8095 -v /var/project/nginx/html:/usr/share/nginx/html -v /etc/nginx/conf:/etc/nginx -v /var/project/logs/nginx:/var/log/nginx nginx
```

修改完配置文件，只需重启Docker 容器即可

```
docker restart nginx
```



# 二、配置静态资源访问nginx.conf文件

## 2.1 修改nginx.conf 

在nginx.conf的http节点中添加配置，参考下方格式：

```
server {
        listen       8000;
        listen       somename:8080;
        server_name  somename  alias  another.alias;

        location / {
            root   html;
            index  index.html index.htm;
        }
}
```

<font color='red'>解读server节点各参数含义</font>

- listen：代表nginx要监听的端口

- server_name:代表nginx要监听的域名

- location ：nginx拦截路径的匹配规则

- location块：location块里面表示已匹配请求需要进行的操作

　　　　

## 2.2 示例

### 2.2.1 准备要访问的静态文件

两个文件夹：folder1 folder2 folder3各放两个文件一个index.html 

 ![img](https://img2020.cnblogs.com/blog/1238609/202004/1238609-20200430173513232-217657252.png)

### 2.2.2 创建一个server

```
server {
	listen       9999;
    server_name  localhost;

    location /xixi {
    	alias   /Users/qingshan/folder1;
        index  index.html;
    }

	location /haha {
    	alias   /Users/qingshan/folder2;
        index  index.html;
    }

	location /folder3 {
    	root   /Users/qingshan;
       	index  index.html;
    }
}
```

###  2.2.3 重启nginx后，即可看到如下内容

 

 ![img](https://img2020.cnblogs.com/blog/1238609/202004/1238609-20200430162047114-1726912757.png)![img](https://img2020.cnblogs.com/blog/1238609/202004/1238609-20200430162104429-1111596185.png)![img](https://img2020.cnblogs.com/blog/1238609/202004/1238609-20200430162117497-897049993.png)

 ![img](https://img2020.cnblogs.com/blog/1238609/202004/1238609-20200430162142484-399085031.png)![img](https://img2020.cnblogs.com/blog/1238609/202004/1238609-20200430162236081-643074089.png)![img](https://img2020.cnblogs.com/blog/1238609/202004/1238609-20200430162300734-1363580702.png)

 

 

![img](https://img2020.cnblogs.com/blog/1238609/202004/1238609-20200430173547992-718510990.png)![img](https://img2020.cnblogs.com/blog/1238609/202004/1238609-20200430173608469-1780585424.png)![img](https://img2020.cnblogs.com/blog/1238609/202004/1238609-20200430173725250-304929493.png)

##  2.3 root与alias的区别

　　重点是理解alias与root的区别，root与alias主要区别在于nginx如何解释location后面的uri，这使两者分别以不同的方式将请求映射到服务器文件上。

　　alias（别名）是一个目录别名。



例子：

```
　location /123/abc/ {
　　root /ABC;
  }
# 当请求http://qingshan.com/123/abc/logo.png时，会返回 /ABC/123/abc/logo.png文件，即用/ABC 加上 /123/abc。
```

 

　　root（根目录）是最上层目录的定义。

例子：

```
location /123/abc/ {
	alias /ABC;
    }
# 当请求http://qingshan.com/123/abc/logo.png时，会返回 /ABC/logo.png文件，即用/ABC替换 /123/abc。
```

# 三、Nginx配置实践

## 3.1 nginx.conf基础配置项

```yml
# 指定运行nginx的用户名
#user  nobody;
# 工作线程数，通常同cpu逻辑核心数一致
worker_processes  1;

# 错误日志路径 最小级别 [ debug | info | notice | warn | error | crit ]
#error_log  logs/error.log;
#error_log  logs/error.log  notice;
#error_log  logs/error.log  info;

# 指定进程的pid记录文件，记录当前运行的nginx的pid
#pid        logs/nginx.pid;

# 网络连接模块
events {
    # 一个工作线程支持的最大并发连接数
    worker_connections  1024;

    # keepalive超时时间，单位：秒
    keepalive_timeout 60;
}

# 设定http服务器，利用它的反向代理功能提供负载均衡支持
http {
    # 设定支持的 mime 类型
    include       mime.types;
    # 默认 mime 类型
    default_type  application/octet-stream;

    # 设定日志格式，格式名为main
    ## $remote_addr：客户端的ip地址（若使用代理服务器，则是代理服务器的ip）
    ## $remote_user：客户端的用户名（一般为“-”）
    ## $time_local：访问时间和时区
    ## $request：请求的url和请求方法
    ## $status：响应HTTP状态码
    ## $body_bytes_sent：响应body中的字节数
    ## $http_referer：客户端是从哪个url来请求的
    ## $http_user_agent：客户端用户使用的代理（一般为浏览器）
    ## $http_x_forwarded_for：客户端的ip地址（通过代理服务器记录客户端的ip地址）
    #log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
    #                  '$status $body_bytes_sent "$http_referer" '
    #                  '"$http_user_agent" "$http_x_forwarded_for"';

    # 访问日志文件路径及日志格式
    #access_log  logs/access.log  main;

    # 指定 nginx 是否调用 sendfile 函数（zero copy 方式）来输出文件，对于普通应用，必须设为 on,
    # 如果用来进行下载等应用磁盘IO重负载应用，可设置为 off，以平衡磁盘与网络I/O处理速度，降低系统的uptime
    sendfile        on;
    #tcp_nopush     on;

    # keepalive 超时时长，单位：秒
    #keepalive_timeout  0;
    keepalive_timeout  65;

    # 打开 gzip 
    #gzip  on;

    # 以上为 nginx 的全局设置，应用于所有 Web 应用
    # 一个Web应用对应一个 server，内部配置仅针对该应用，优先级比全局的高
    server {
        // 端口号
        listen       80;
        // 域名，比如 www.test.com
        server_name  localhost;

        # 编码格式
        #charset koi8-r;

        # 访问日志文件路径
        #access_log  logs/host.access.log  main;

        # 一般路由导航到：
        location / {
            # 根目录为html
            root   html;
            # 默认页为 index.html，如果没有则是 index.htm
            index  index.html index.htm;
        }

        # 404时的展示页面
        #error_page  404              /404.html;

        # 50X时的展示页面
        # redirect server error pages to the static page /50x.html
        #
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }

        # proxy the PHP scripts to Apache listening on 127.0.0.1:80
        #
        #location ~ \.php$ {
        #    proxy_pass   http://127.0.0.1;
        #}

        # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
        #
        #location ~ \.php$ {
        #    root           html;
        #    fastcgi_pass   127.0.0.1:9000;
        #    fastcgi_index  index.php;
        #    fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
        #    include        fastcgi_params;
        #}

        # 禁止访问 .htxxx 的文件
        # deny access to .htaccess files, if Apache's document root
        # concurs with nginx's one
        #
        #location ~ /\.ht {
        #    deny  all;
        #}
    }


    # another virtual host using mix of IP-, name-, and port-based configuration
    #
    #server {
    #    listen       8000;
    #    listen       somename:8080;
    #    server_name  somename  alias  another.alias;

    #    location / {
    #        root   html;
    #        index  index.html index.htm;
    #    }
    #}


    ############## HTTPS demo beign ##############
    # HTTPS server
    #
    #server {
    #    listen       443 ssl;
    #    server_name  localhost;

         # ssl 证书文件位置
    #    ssl_certificate      cert.pem;
         # ssl 证书key的位置
    #    ssl_certificate_key  cert.key;

    #    ssl_session_cache    shared:SSL:1m;
    #    ssl_session_timeout  5m;
         # 数字签名 MD5
    #    ssl_ciphers  HIGH:!aNULL:!MD5;
    #    ssl_prefer_server_ciphers  on;

    #    location / {
    #        root   html;
    #        index  index.html index.htm;
    #    }
    #}
    ############### HTTPS demo end ###############

    ############ 反向代理 demo begin #############
    # 设定实际的服务器列表（权重默认都是1）
    #upstream myserver{
    #   server 192.168.0.1:8089 weight=7;
    #   server 192.168.0.2:8089 weight=3;
    #}

    #server {
    #    listen       80;
    #    server_name localhost;

         #反向代理的路径（和upstream绑定），location 后面设置映射的路径
    #    location / {
    #        proxy_pass http://myserver;
    #    }
    #}
    ############# 反向代理 demo end ##############

}
```

## 3.2 http 反向代理

nginx.conf 配置文件如下：
注：conf / nginx.conf 是 nginx 的默认配置文件。你也可以使用 nginx -c 指定你的配置文件。

```yml
#运行用户
#user somebody;

#启动进程,通常设置成和cpu的数量相等
worker_processes  1;

#全局错误日志
error_log  D:/Tools/nginx-1.10.1/logs/error.log;
error_log  D:/Tools/nginx-1.10.1/logs/notice.log  notice;
error_log  D:/Tools/nginx-1.10.1/logs/info.log  info;

#PID文件，记录当前启动的nginx的进程ID
pid        D:/Tools/nginx-1.10.1/logs/nginx.pid;

#工作模式及连接数上限
events {
    worker_connections 1024;    #单个后台worker process进程的最大并发链接数
}

#设定http服务器，利用它的反向代理功能提供负载均衡支持
http {
    #设定mime类型(邮件支持类型),类型由mime.types文件定义
    include       D:/Tools/nginx-1.10.1/conf/mime.types;
    default_type  application/octet-stream;

    #设定日志
    log_format  main  '[$remote_addr] - [$remote_user] [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log    D:/Tools/nginx-1.10.1/logs/access.log main;
    rewrite_log     on;

    #sendfile 指令指定 nginx 是否调用 sendfile 函数（zero copy 方式）来输出文件，对于普通应用，
    #必须设为 on,如果用来进行下载等应用磁盘IO重负载应用，可设置为 off，以平衡磁盘与网络I/O处理速度，降低系统的uptime.
    sendfile        on;
    #tcp_nopush     on;

    #连接超时时间
    keepalive_timeout  120;
    tcp_nodelay        on;

    #gzip压缩开关
    #gzip  on;

    #设定实际的服务器列表
    upstream zp_server1{
        server 127.0.0.1:8089;
    }

    #HTTP服务器
    server {
        #监听80端口，80端口是知名端口号，用于HTTP协议
        listen       80;

        #定义使用www.xx.com访问
        server_name  www.helloworld.com;

        #首页
        index index.html

        #指向webapp的目录
        root D:\01_Workspace\Project\github\zp\SpringNotes\spring-security\spring-shiro\src\main\webapp;

        #编码格式
        charset utf-8;

        #代理配置参数
        proxy_connect_timeout 180;
        proxy_send_timeout 180;
        proxy_read_timeout 180;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarder-For $remote_addr;

        #反向代理的路径（和upstream绑定），location 后面设置映射的路径
        location / {
            proxy_pass http://zp_server1;
        }

        #静态文件，nginx自己处理
        location ~ ^/(images|javascript|js|css|flash|media|static)/ {
            root D:\01_Workspace\Project\github\zp\SpringNotes\spring-security\spring-shiro\src\main\webapp\views;
            #过期30天，静态文件不怎么更新，过期可以设大一点，如果频繁更新，则可以设置得小一点。
            expires 30d;
        }

        #设定查看Nginx状态的地址
        location /NginxStatus {
            stub_status           on;
            access_log            on;
            auth_basic            "NginxStatus";
            auth_basic_user_file  conf/htpasswd;
        }

        #禁止访问 .htxxx 文件
        location ~ /\.ht {
            deny all;
        }

        #错误处理页面（可选择性配置）
        #error_page   404              /404.html;
        #error_page   500 502 503 504  /50x.html;
        #location = /50x.html {
        #    root   html;
        #}
    }
}
```

1. 启动 webapp，注意启动绑定的端口要和 nginx 中的 upstream 设置的端口保持一致。
2. 更改 host：在 C:\Windows\System32\drivers\etc 目录下的 host 文件中添加一条 DNS 记录
   `  127.0.0.1 www.helloworld.com  `

3. 启动前文中 startup.bat 的命令
4. 在浏览器中访问 www.helloworld.com，不出意外，已经可以访问了。

## 3.3 负载均衡配置

假设这样一个应用场景：将应用部署在 192.168.1.11:80、192.168.1.12:80、192.168.1.13:80 三台 linux 环境的服务器上。网站域名叫 www.helloworld.com，公网 IP 为 192.168.1.11。在公网 IP 所在的服务器上部署 nginx，对所有请求做负载均衡处理。

nginx.conf 配置如下：

```yml
http {
     #设定mime类型,类型由mime.type文件定义
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    #设定日志格式
    access_log    /var/log/nginx/access.log;

    #设定负载均衡的服务器列表
    upstream load_balance_server {
        #weigth参数表示权值，权值越高被分配到的几率越大
        server 192.168.1.11:80   weight=5;
        server 192.168.1.12:80   weight=1;
        server 192.168.1.13:80   weight=6;
    }

   #HTTP服务器
   server {
        #侦听80端口
        listen       80;

        #定义使用www.xx.com访问
        server_name  www.helloworld.com;

        #对所有请求进行负载均衡请求
        location / {
            root        /root;                 #定义服务器的默认网站根目录位置
            index       index.html index.htm;  #定义首页索引文件的名称
            proxy_pass  http://load_balance_server ;#请求转向load_balance_server 定义的服务器列表

            #以下是一些反向代理的配置(可选择性配置)
            #proxy_redirect off;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            #后端的Web服务器可以通过X-Forwarded-For获取用户真实IP
            proxy_set_header X-Forwarded-For $remote_addr;
            proxy_connect_timeout 90;          #nginx跟后端服务器连接超时时间(代理连接超时)
            proxy_send_timeout 90;             #后端服务器数据回传时间(代理发送超时)
            proxy_read_timeout 90;             #连接成功后，后端服务器响应时间(代理接收超时)
            proxy_buffer_size 4k;              #设置代理服务器（nginx）保存用户头信息的缓冲区大小
            proxy_buffers 4 32k;               #proxy_buffers缓冲区，网页平均在32k以下的话，这样设置
            proxy_busy_buffers_size 64k;       #高负荷下缓冲大小（proxy_buffers*2）
            proxy_temp_file_write_size 64k;    #设定缓存文件夹大小，大于这个值，将从upstream服务器传

            client_max_body_size 10m;          #允许客户端请求的最大单文件字节数
            client_body_buffer_size 128k;      #缓冲区代理缓冲用户端请求的最大字节数
        }
    }
}
```

## 3.4 网站有多个 webapp 的配置

当一个网站功能越来越丰富时，往往需要将一些功能相对独立的模块剥离出来，独立维护。这样的话，通常，会有多个 webapp。

举个例子：假如 www.helloworld.com 站点有好几个 webapp，finance（金融）、product（产品）、admin（用户中心）。访问这些应用的方式通过上下文(context)来进行区分:

> www.helloworld.com/finance/
> www.helloworld.com/product/
> www.helloworld.com/admin/

我们知道，http 的默认端口号是 80，如果在一台服务器上同时启动这 3 个 webapp 应用，都用 80 端口，肯定是不成的。所以，这三个应用需要分别绑定不同的端口号。

那么，问题来了，用户在实际访问 www.helloworld.com 站点时，访问不同 webapp，总不会还带着对应的端口号去访问吧。所以，你再次需要用到反向代理来做处理。

```yml
http {
    #此处省略一些基本配置

    upstream product_server{
        server www.helloworld.com:8081;
    }

    upstream admin_server{
        server www.helloworld.com:8082;
    }

    upstream finance_server{
        server www.helloworld.com:8083;
    }

    server {
        #此处省略一些基本配置
        #默认指向product的server
        location / {
            proxy_pass http://product_server;
        }

        location /product/{
            proxy_pass http://product_server;
        }

        location /admin/ {
            proxy_pass http://admin_server;
        }

        location /finance/ {
            proxy_pass http://finance_server;
        }
    }
}
```

## 3.5 https 反向代理配置

一些对安全性要求比较高的站点，可能会使用 HTTPS（一种使用 ssl 通信标准的安全 HTTP 协议）。
使用 nginx 配置 https 需要知道几点：

- HTTPS 的固定端口号是 443，不同于 HTTP 的 80 端口
- SSL 标准需要引入安全证书，所以在 nginx.conf 中你需要指定证书和它对应的 key

其他和 http 反向代理基本一样，只是在 Server 部分配置有些不同。

```yml
  #HTTP服务器
  server {
      #监听443端口。443为知名端口号，主要用于HTTPS协议
      listen       443 ssl;

      #定义使用www.xx.com访问
      server_name  www.helloworld.com;

      #ssl证书文件位置(常见证书文件格式为：crt/pem)
      ssl_certificate      cert.pem;
      #ssl证书key位置
      ssl_certificate_key  cert.key;

      #ssl配置参数（选择性配置）
      ssl_session_cache    shared:SSL:1m;
      ssl_session_timeout  5m;
      #数字签名，此处使用MD5
      ssl_ciphers  HIGH:!aNULL:!MD5;
      ssl_prefer_server_ciphers  on;

      location / {
          root   /root;
          index  index.html index.htm;
      }
  }
```

## 3.6 静态站点配置

配置静态站点(即 html 文件和一堆静态资源)。

举例来说：如果所有的静态资源都放在了 /app/dist 目录下，我们只需要在 nginx.conf 中指定首页以及这个站点的 host 即可。

配置如下：

```yml
worker_processes  1;

events {
    worker_connections  1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    keepalive_timeout  65;

    gzip on;
    gzip_types text/plain application/x-javascript text/css application/xml text/javascript application/javascript image/jpeg image/gif image/png;
    gzip_vary on;

    server {
        listen       80;
        server_name  static.zp.cn;

        location / {
            root /app/dist;
            index index.html;
            #转发任何请求到 index.html
        }
    }
}
```

然后，添加 HOST：
127.0.0.1 static.zp.cn
此时，在本地浏览器访问 static.zp.cn ，就可以访问静态站点了。

## 3.7 搭建文件服务器

使用 Nginx 可以非常快速便捷的搭建一个简易的文件服务。

Nginx 中的配置要点：

- 将 autoindex 开启可以显示目录，默认不开启。
- 将 autoindex_exact_size 开启可以显示文件的大小。
- 将 autoindex_localtime 开启可以显示文件的修改时间。
- root 用来设置开放为文件服务的根路径。
- charset 设置为 charset utf-8,gbk;，可以避免中文乱码问题（windows 服务器下设置后，依然乱码，本人暂时没有找到解决方法）。

一个最简化的配置如下：

```yml
autoindex on;# 显示目录
autoindex_exact_size on;# 显示文件大小
autoindex_localtime on;# 显示文件时间

server {
    charset      utf-8,gbk; # windows 服务器下设置后，依然乱码，暂时无解
    listen       9050 default_server;
    listen       [::]:9050 default_server;
    server_name  _;
    root         /share/fs;
}
```

## 3.8 跨域解决方案

web 领域开发中，经常采用前后端分离模式。这种模式下，前端和后端分别是独立的 web 应用程序，例如：后端是 Java 程序，前端是 React 或 Vue 应用。

各自独立的 web app 在互相访问时，势必存在跨域问题。解决跨域问题一般有两种思路：

### 3.8,1 CORS

在后端服务器设置 HTTP 响应头，把你需要运行访问的域名加入加入 Access-Control-Allow-Origin中。

### 3.8.2 jsonp

把后端根据请求，构造 json 数据，并返回，前端用 jsonp 跨域。



nginx 根据第一种思路，也提供了一种解决跨域的解决方案。
举例：www.helloworld.com 网站是由一个前端 app ，一个后端 app 组成的。前端端口号为 9000， 后端端口号为 8080。
前端和后端如果使用 http 进行交互时，请求会被拒绝，因为存在跨域问题。来看看，nginx 是怎么解决的吧：
首先，在 enable-cors.conf 文件中设置 cors ：

```yml
# allow origin list
set $ACAO '*';

# set single origin
if ($http_origin ~* (www.helloworld.com)$) {
  set $ACAO $http_origin;
}

if ($cors = "trueget") {
    add_header 'Access-Control-Allow-Origin' "$http_origin";
    add_header 'Access-Control-Allow-Credentials' 'true';
    add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
    add_header 'Access-Control-Allow-Headers' 'DNT,X-Mx-ReqToken,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type';
}

if ($request_method = 'OPTIONS') {
  set $cors "${cors}options";
}

if ($request_method = 'GET') {
  set $cors "${cors}get";
}

if ($request_method = 'POST') {
  set $cors "${cors}post";
}
```

接下来，在你的服务器中 include enable-cors.conf 来引入跨域配置：

```yml
# ----------------------------------------------------
# 此文件为项目 nginx 配置片段
# 可以直接在 nginx config 中 include（推荐）
# 或者 copy 到现有 nginx 中，自行配置
# www.helloworld.com 域名需配合 dns hosts 进行配置
# 其中，api 开启了 cors，需配合本目录下另一份配置文件
# ----------------------------------------------------
upstream front_server{
  server www.helloworld.com:9000;
}
upstream api_server{
  server www.helloworld.com:8080;
}

server {
  listen       80;
  server_name  www.helloworld.com;

  location ~ ^/api/ {
    include enable-cors.conf;
    proxy_pass http://api_server;
    rewrite "^/api/(.*)$" /$1 break;
  }

  location ~ ^/ {
    proxy_pass http://front_server;
  }
}
```

# 四、