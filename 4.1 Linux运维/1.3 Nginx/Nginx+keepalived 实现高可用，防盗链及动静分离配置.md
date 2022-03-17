- [Nginx+keepalived 实现高可用，防盗链及动静分离配置](https://mp.weixin.qq.com/s/dpYAdq7NhNBD8e8wtmyJNg)

## 一、Nginx Rewrite 规则

### 1. Nginx rewrite规则

Rewrite规则含义就是某个URL重写成特定的URL（类似于Redirect），从某种意义上说为了美观或者对搜索引擎友好，提高收录量及排名等。

**语法：**

`rewrite <regex> <replacement> [flag]`关键字 || 正则 || 替代内容 || flag标记

Rewrite规则的flag标记主要有以下几种：

- last ：相当于Apache里的(L)标记，表示完成rewrite；
- break：本条规则匹配完成后，终止匹配，不再匹配后面的规则
- redirect：返回302临时重定向，浏览器地址会显示跳转后的URL地址
- permanent：返回301永久重定向，浏览器地址栏会显示跳转后的URL地址

*last和break用来实现URL重写，浏览器地址栏URL地址不变*

### 2. Nginx rewrite例子

a)  例如用户访问www.dbspread.com，想直接跳转到网站下面的某个页面，www.dbspread.com/new.index.html如何来实现呢？我们可以使用Nginx Rewrite 来实现这个需求，具体如下：在server中加入如下语句即可：

```
server {
    listen       80; #监听80端口
    server_name  www.dbspread.com; #域名
    #rewrite规则
    index  index.jsp index.html index.htm;
    root   /usr/local/nginx/html; #定义服务器的默认网站根目录位置



    #监听完成以后通过斜杆(/)拦截请求转发到后端的tomcat服务器
    location / 
        {
            #如果后端的服务器返回502、504、执行超时等错误，自动将请求转发到upstream负载均衡池中的另一台服务器，实现故障转移。
            proxy_next_upstream http_502 http_504 error timeout invalid_header;
            proxy_set_header Host  $host; #获取客户端的主机名存到变量Host里面,从而让tomcat取到客户端机器的信息
            proxy_set_header X-Real-IP $remote_addr; #获取客户端的主机名存到变量X-Real-IP里面,从而让tomcat取到客户端机器的信息
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            rewrite     ^/$    http://www.dbspread.com/new.index.html  permanent;
            proxy_pass http://web1; #跳转到对应的应用web1
        }
}
```

效果图如下：

![image-20211218085613786](https://gitee.com/er-huomeng/img/raw/master/image-20211218085613786.png)

```
rewrite     ^/$    http://www.dbspread.com/new.index.html  permanent;
```

**对应如下语法：**

`rewrite <regex> <replacement> [flag];`关键字 || 正则 || 替代内容 || flag标记

**正则表达式说明：**

> *代表前面0或更多个字符 +代表前面1或更多个字符 ？代表前面0或1个字符 ^代表字符串的开始位置 $代表字符串结束的位置 。为通配符，代表任何字符

b)例如多个域名跳转到同一个域名，nginx rewrite规则写法如下：

```
server {
    listen       80; #监听80端口
    server_name  www.dbspread.com; #域名
    #rewrite规则
    index  index.jsp index.html index.htm;
    root   /usr/local/nginx/html; #定义服务器的默认网站根目录位置

    if ($host != 'www.dbspread.com' ){ 
            rewrite ^/(.*)$  http://www.dbspread.com/$1  permanent;
            }
}
```

**格式：**

`rewrite <regex> <replacement> [flag];`关键字 || 正则 || 替代内容 || flag标记

**说明：**

- rewrite为固定关键字，表示开始进行rewrite匹配规则、
- regex部分是 `^/(.*)` ，这是一个正则表达式，匹配完整的域名和后面的路径地址
- replacement部分是`http://www.dbspread.com/$1`，`$1`是取自regex部分( )里的内容。匹配成功后跳转到的URL。
- flag部分 permanent表示永久301重定向标记，即跳转到新的 `http://www.dbspread.com/$1` 地址上

> 推荐下自己做的 Spring Boot 的实战项目：
>
> https://github.com/YunaiV/ruoyi-vue-pro

## 二、Nginx 防盗链

### 1. 什么是防盗链

比如http://www.dbspread.com/download/av123.rmvb  这个视频下载地址被其他网站引用，比如在www.test.com的index.html引用download/av123.rmvb就叫盗链，我们要禁止这种引用就叫做防盗链

### 2. 怎么实现防盗链

在nginx的nginx.conf的server里面配置如下代码

```
server {
        listen       80;
        server_name  www.dbspread.com *.dbspread.com;
        location ~* \.(rmvb|jpg|png|swf|flv)$ { #rmvb|jpg|png|swf|flv表示对rmvb|jpg|png|swf|flv后缀的文件实行防盗链
                valid_referers none blocked  www.dbspread.com; #表示对www.dbspread.com此域名开通白名单，比如在www.test.com的index.html引用download/av123.rmvb,无效
                root   html/b;
                if ($invalid_referer) { #如果请求不是从www.dbspread.com白名单发出来的请求，直接重定向到403.html这个页面或者返回403 
                     #rewrite ^/ http://www.dbspread.com/403.html;
                     return 403;
                }
        }

    }
```

> 推荐下自己做的 Spring Cloud 的实战项目：
>
> https://github.com/YunaiV/onemall

## 三、Nginx 动静分离

### 1. 动静分离是什么

Nginx动静分离是让动态网站里的动态网页根据一定规则把不变的资源和经常变的资源区分开来，动静资源做好了拆分以后，我们就可以根据静态资源的特点将其做缓存操作，这就是网站静态化处理的核心思路。

### 2. 动静分离原理图

![image-20211218085637656](https://gitee.com/er-huomeng/img/raw/master/image-20211218085637656.png)

### 3. Nginx动静分离应该注意的地方

- WEB项目开发时要注意，将静态资源尽量放在一个static文件夹
- 将static静态资源文件夹放到Nginx可以取到的位置
- 页面要建立全局变量路径，方便修改路径
- 修改nginx.conf的location， 匹配静态资源请求

### 4. Nginx动静分离步骤

```
body {
    margin: 10px 20px;
    text-align: center;
    font-family: Arial, sans-serif;
    background-color: red;
}
```

4.2 在/var/local下新建一个static文件夹用来存放静态资源button.css

4.3 在tomcat-8080/webapps/ROOT下的index.html里面引入button.css

```
<html>
  <head>
    <link rel="stylesheet" type="text/css" href="http://www.static.com/button.css" />
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
    <meta name="renderer" content="webkit">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
    <title>test</title>
  </head>
  <body>

    欢迎来到8080端口tomcat
  </body>
</html>
```

4.4 在nginx的nginx.conf中server节点新增静态资源分离的配置

```
server {
    listen       80; #监听80端口
    server_name  www.dbspread.com; #域名
    #rewrite规则
    index  index.jsp index.html index.htm;
    root   /usr/local/nginx/html; #定义服务器的默认网站根目录位置
    #重定向
    if ($host != 'www.dbspread.com' ){ 
            rewrite ^/(.*)$  http://www.dbspread.com/$1  permanent;
            }

    #防盗链
     location ~* \.(rmvb|jpg|png|swf|flv)$ { #rmvb|jpg|png|swf|flv表示对rmvb|jpg|png|swf|flv后缀的文件实行防盗链
                valid_referers none blocked  www.dbspread.com; #表示对www.dbspread.com此域名开通白名单，比如在www.test.com的index.html引用download/av123.rmvb,无效
                root   html/b;
                if ($invalid_referer) { #如果请求不是从www.dbspread.com白名单发出来的请求，直接重定向到403.html这个页面或者返回403 
                     #rewrite ^/ http://www.dbspread.com/403.html;
                     return 403;
                }
        }

    #监听完成以后通过斜杆(/)拦截请求转发到后端的tomcat服务器
    location / 
        {
            #如果后端的服务器返回502、504、执行超时等错误，自动将请求转发到upstream负载均衡池中的另一台服务器，实现故障转移。
            proxy_next_upstream http_502 http_504 error timeout invalid_header;
            proxy_set_header Host  $host; #获取客户端的主机名存到变量Host里面,从而让tomcat取到客户端机器的信息
            proxy_set_header X-Real-IP $remote_addr; #获取客户端的主机名存到变量X-Real-IP里面,从而让tomcat取到客户端机器的信息
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            #rewrite     ^/$    http://www.dbspread.com/new.index.html  permanent;#用户访问www.dbspread.com，想直接跳转到网站下面的某个页面:www.dbspread.com/new.index.html
            proxy_pass http://web1; #跳转到对应的应用web1
        }

       # location ~ .*\.(php|jsp|cgi|shtml)?$ #动态分离 ~匹配 以.*结尾（以PHP JSP结尾走这段）
       #  {
       #     proxy_set_header Host  $host;
       #        proxy_set_header X-Real-IP $remote_addr;
       #        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
       #        proxy_pass http://jvm_web2;
       # }

        #静态分离 ~匹配 以.*结尾（以html|htm|gif|jpg|jpeg|bmp|png|ico|txt|js|css结尾走这段），当然不是越久越好，如果有10000个用户在线，都保存几个月，系统托跨
        location ~ .*\.(html|htm|gif|jpg|jpeg|bmp|png|ico|txt|js|css)$ 
        {
            root /var/local/static; #静态资源存放在nginx的安装机器上
            #proxy_pass http://www.static.com; #静态资源也可存放在远程服务器上
            expires    30d; #30天之内只要访问过一次就从缓存拿
        }

        #日志级别有[debug|info|notice|warn|error|crit]  error_log 级别分为 debug, info, notice, warn, error, crit  默认为crit, 生产环境用error 
        #crit 记录的日志最少,而debug记录的日志最多
        access_log  /usr/local/logs/web2/access.log main;
        error_log   /usr/local/logs/web2/error.log  crit;

    }
```

4.5 访问页面查看效果

![image-20211218092328280](https://gitee.com/er-huomeng/img/raw/master/image-20211218092328280.png)

## 四、Nginx+keepalived 实现高可用

### 1. keepalived是什么

Keepalived软件起初是专为LVS负载均衡软件设计的，用来管理并监控LVS集群系统中各个服务节点的状态，后来又加入了可以实现高可用的VRRP (Virtual Router Redundancy Protocol ,虚拟路由器冗余协议）功能。

因此，Keepalived除了能够管理LVS软件外，还可以作为其他服务（例如：Nginx、Haproxy、MySQL等）的高可用解决方案软件。

### 2. keepalived主要功能

- 管理LVS负载均衡软件
- 实现LVS集群节点的健康检查
- 作为系统网络服务的高可用性（failover）

### 3. keepalived故障转移

Keepalived高可用服务之间的故障切换转移，是通过 VRRP 来实现的。

在 Keepalived服务正常工作时，主 Master节点会不断地向备节点发送（多播的方式）心跳消息，用以告诉备Backup节点自己还活着，当主 Master节点发生故障时，就无法发送心跳消息，备节点也就因此无法继续检测到来自主  Master节点的心跳了，于是调用自身的接管程序，接管主Master节点的 IP资源及服务。

而当主 Master节点恢复时，备Backup节点又会释放主节点故障时自身接管的IP资源及服务，恢复到原来的备用角色。

> 说明：keepalived的主从切换和redis的主从切换是不一样的，keepalived的主节点挂了以后，从节点变为主节点，之前的主节点恢复以后继续做主节点。redis的主节点挂了以后，重新恢复以后变为从节点

### 4. keepalived高可用架构示意图

![image-20211218092340556](https://gitee.com/er-huomeng/img/raw/master/image-20211218092340556.png)

说明：

- 虚拟ip(VIP):192.168.152.200，对外提供服务的ip，也可称作浮动ip
- 192.168.152.130：nginx + keepalived master 主
- 192.168.152.129：nginx + keepalived backup 从
- 192.168.152.129：tomcat-8080
- 192.168.152.129：tomcat-8081

### 5. keepalived安装

环境准备：

> centos6、jdk

- 虚拟ip(VIP):192.168.152.200，对外提供服务的ip，也可称作浮动ip
- 192.168.152.130：nginx + keepalived master 主
- 192.168.152.129：nginx + keepalived backup 从
- 192.168.152.129：tomcat-8080
- 192.168.152.129：tomcat-8081

5.1 安装keepalived的步骤：

> 注：192.168.152.129（keepalived从节点） 与 192.168.152.130（keepalived主节点）先安装好nginx + keepalived

下载压缩包：

```
wget www.keepalived.org/software/keepalived-1.3.5.tar.gz
```

解压缩：

```
tar -zxvf keepalived-1.3.5.tar.gz
```

进入解压缩以后的文件目录：

```
cd keepalived-1.3.5
```

编译安装：

```
./configure --prefix=/usr/local/keepalived
```

系统提示警告 `*** WARNING - this build will not support IPVS with IPv6. Please install  libnl/libnl-3 dev libraries to support IPv6 with IPVS. yum -y install  libnl libnl-devel`

再次执行

```
./configure --prefix=/usr/local/keepalived
```

系统提示错误 `configure: error: libnfnetlink headers missing yum install -y libnfnetlink-devel`

再次执行

```
./configure --prefix=/usr/local/keepalived

make && make install
```

到此keepalived安装完成，**但是接下来还有最关键的一步，如果这一步没有做后面启动keepalived的时候会报找不到配置文件的错误**

```
Configuration file '/etc/keepalived/keepalived.conf' is not a regular non-executable file
```

安装完成后，进入安装目录的etc目录下，将keepalived相应的配置文件拷贝到系统相应的目录当中。keepalived启动时会从/etc/keepalived目录下查找keepalived.conf配置文件

```
mkdir /etc/keepalived

cp /usr/local/keepalived/etc/keepalived/keepalived.conf /etc/keepalived
```

5.2 修改keepalived主节点192.168.152.130的/etc/keepalived/keepalived.conf配置文件

```
#全局配置
global_defs {             
    notification_email {
        leeSmall@qq.com  #设置报警邮件地址，可以设置多个，每行一个。需要开启sendmail服务。
    }
    notification_email_from sns-lvs@gmail.com
    smtp_server smtp.hysec.com   #设置SMTP Server地址
    smtp_connection_timeout 30   #设置SMTP Server的超时时间
    router_id nginx_master       #表示运行Keepalived服务器的一个标识，唯一的
}
#检测脚本
vrrp_script chk_http_port {
    script "/usr/local/src/check_nginx_pid.sh" #心跳执行的脚本，检测nginx是否启动
    interval 2                          #（检测脚本执行的间隔，单位是秒）
    weight 2                            #权重
}
#vrrp 实例定义部分
vrrp_instance VI_1 {        
    state MASTER            # 指定keepalived的角色，MASTER为主，BACKUP为备
    interface eth0         # 当前进行vrrp通讯的网络接口卡(当前centos的网卡) 用ifconfig查看你具体的网卡
    virtual_router_id 66    # 虚拟路由编号，主从要一直
    priority 100            # 优先级，数值越大，获取处理请求的优先级越高
    advert_int 1            # 检查间隔，默认为1s(vrrp组播周期秒数)
    #授权访问
    authentication {
        auth_type PASS #设置验证类型和密码，MASTER和BACKUP必须使用相同的密码才能正常通信
        auth_pass 1111
    }
    track_script {
        chk_http_port            #（调用检测脚本）
    }
    virtual_ipaddress {
        192.168.152.200            # 定义虚拟ip(VIP)，可多设，每行一个
    }
}
```

5.3 修改keepalived从节点192.168.152.129的/etc/keepalived/keepalived.conf配置文件

```
#全局配置
global_defs {
    notification_email {
         leeSmall@qq.com  #设置报警邮件地址，可以设置多个，每行一个。需要开启sendmail服务。
    }
    notification_email_from sns-lvs@gmail.com
    smtp_server smtp.hysec.com #设置SMTP Server地址
    smtp_connection_timeout 30 #设置SMTP Server的超时时间
    router_id nginx_backup              # 设置nginx backup的id，在一个网络应该是唯一的
}
#检测脚本
vrrp_script chk_http_port {
    script "/usr/local/src/check_nginx_pid.sh" #心跳执行的脚本，检测nginx是否启动
    interval 2                          #（检测脚本执行的间隔）
    weight 2                            #权重
}
#vrrp 实例定义部分
vrrp_instance VI_1 {
    state BACKUP                        # 指定keepalived的角色，MASTER为主，BACKUP为备
    interface eth0                      # 当前进行vrrp通讯的网络接口卡(当前centos的网卡) 用ifconfig查看你具体的网卡
    virtual_router_id 66                # 虚拟路由编号，主从要一直
    priority 99                         # 优先级，数值越大，获取处理请求的优先级越高
    advert_int 1                        # 检查间隔，默认为1s(vrrp组播周期秒数)
    #授权访问
    authentication {
        auth_type PASS #设置验证类型和密码，MASTER和BACKUP必须使用相同的密码才能正常通信
        auth_pass 1111
    }
    track_script {
        chk_http_port                   #（调用检测脚本）
    }
    virtual_ipaddress {
        192.168.152.200                   # 定义虚拟ip(VIP)，可多设，每行一个
    }
}
```

5.4 检查nginx是否启动的shell脚本

> /usr/local/src/check_nginx_pid.sh

```
#!/bin/bash
#检测nginx是否启动了
A=`ps -C nginx --no-header |wc -l`        
if [ $A -eq 0 ];then    #如果nginx没有启动就启动nginx                        
      /usr/local/nginx/sbin/nginx                #重启nginx
      if [ `ps -C nginx --no-header |wc -l` -eq 0 ];then    #nginx重启失败，则停掉keepalived服务，进行VIP转移
              killall keepalived                    
      fi
fi
```

5.5 192.168.152.130（keepalived主节点）和 192.168.152.129（keepalived从节点）的nginx的配置文件nginx.conf

```json
user root root; #使用什么用户启动NGINX 在运行时使用哪个用户哪个组
worker_processes 4; #启动进程数，一般是1或8个，根据你的电脑CPU数，一般8个
worker_cpu_affinity 00000001 00000010 00000100 00001000; #CPU逻辑数——把每个进程分别绑在CPU上面，为每个进程分配一个CPU
#pid /usr/local/nginx/logs/nginx.pid
worker_rlimit_nofile 102400; #一个进程打开的最大文件数目，与NGINX并发连接有关系

#工作模式及连接数上限
events
{
  use epoll; #多路复用IO 基于LINUX2.6以上内核，可以大大提高NGINX的性能 uname -a查看内核版本号
  worker_connections 102400; #单个worker process最大连接数,其中NGINX最大连接数＝连接数*进程数,一般1GB内存的机器上可以打开的最大数大约是10万左右
  multi_accept on;   #尽可能多的接受请求，默认是关闭状态
}

#处理http请求的一个应用配置段
http
{
  #引用mime.types,这个类型定义了很多，当web服务器收到静态的资源文件请求时，依据请求文件的后缀名在服务器的MIME配置文件中找到对应的MIME #Type，根据MIMETYPE设置并response响应类型（Content-type）
  include       mime.types; 
  default_type  application/octet-stream; #定义的数据流，有的时候默认类型可以指定为text,这跟我们的网页发布还是资源下载是有关系的
  fastcgi_intercept_errors on; #表示接收fastcgi输出的http 1.0 response code
  charset utf-8;
  server_names_hash_bucket_size 128; #保存服务器名字的hash表
  #用来缓存请求头信息的，容量4K，如果header头信息请求超过了，nginx会直接返回400错误，先根据client_header_buffer_size配置的值分配一个buffer，如果##分配的buffer无法容纳request_line/request_header，那么就会##再次根据large_client_header_buffers配置的参数分配large_buffer，如果large_buffer还是无#法容纳，那么就会返回414（处理request_line）/400（处理request_header）错误。
  client_header_buffer_size 4k; 
  large_client_header_buffers 4 32k;
  client_max_body_size 300m; #允许客户端请求的最大单文件字节数 上传文件时根据需求设置这个参数
  #指定NGINX是否调用这个函数来输出文件，对于普通的文件我们必须设置为ON，如果NGINX专门做为一个下载端的话可以关掉，好处是降低磁盘与网络的IO处理数及#系统的UPTIME
  sendfile on; 
  #autoindex on;开启目录列表访问，适合下载服务器
  tcp_nopush on; #防止网络阻塞
  #非常重要，根据实际情况设置值，超时时间，客户端到服务端的连接持续有效时间，60秒内可避免重新建立连接，时间也不能设太长，太长的话，若请求数10000##，都占用连接会把服务托死
  keepalive_timeout 60;
  tcp_nodelay on; #提高数据的实时响应性
  client_body_buffer_size 512k; #缓冲区代理缓冲用户端请求的最大字节数（请求多）

  proxy_connect_timeout   5; #nginx跟后端服务器连接超时时间（代理连接超时）
  proxy_read_timeout      60; #连接成功后，后端服务器响应时间(代理接收超时)
  proxy_send_timeout      5; #后端服务器数据回传时间(代理发送超时)
  proxy_buffer_size       16k; #设置代理服务器（nginx）保存用户头信息的缓冲区大小
  proxy_buffers           4 64k; #proxy_buffers缓冲区，网页平均在32k以下的话，这样设置
  proxy_busy_buffers_size 128k; #高负荷下缓冲大小
  proxy_temp_file_write_size 128k; #设定缓存文件夹大小，大于这个值，将从upstream服务器传

  gzip on; #NGINX可以压缩静态资源，比如我的静态资源有10M，压缩后只有2M，那么浏览器下载的就少了
  gzip_min_length  1k;
  gzip_buffers     4 16k;
  gzip_http_version 1.1;
  gzip_comp_level 2; #压缩级别大小,最小1,最大9.值越小,压缩后比例越小,CPU处理更快,为1时,原10M压缩完后8M,但设为9时,压缩完可能只有2M了。一般设置为2
  gzip_types       text/plain application/x-javascript text/css application/xml; #压缩类型:text,js css xml 都会被压缩
  gzip_vary on; #作用是在http响应中增加一行目的是改变反向代理服务器的缓存策略

#日志格式 
log_format  main '$remote_addr - $remote_user [$time_local] "$request" ' #ip 远程用户 当地时间  请求URL
                 '$status $body_bytes_sent "$http_referer" ' #状态  发送的大小  响应的头
         '"$http_user_agent" $request_time'; #客户端使用的浏览器  页面响应的时间

#动态转发         
upstream web1 {
    #每个请求按访问ip的hash结果分配,这样每个访客固定访问一个后端服务器,可以解决session的问题。配置了ip_hash就没有负载均衡的效果了，每次访问的都是同一个tomcat
    #ip_hash; 
    #转发的后端的tomcat服务器,weight表示转发的权重,越大转发的次数越多,机器性能不一样配置的weight值不一样     
     server   192.168.152.129:8080 weight=1 max_fails=2 fail_timeout=30s;
     server   192.168.152.129:8081 weight=1 max_fails=2 fail_timeout=30s;
}
upstream web2 {
     server   192.168.152.129:8090 weight=1 max_fails=2 fail_timeout=30s;
     server   192.168.152.129:8091 weight=1 max_fails=2 fail_timeout=30s;
}

server {
    listen       80; #监听80端口
    server_name  www.dbspread.com; #域名
    #rewrite规则
    index  index.jsp index.html index.htm;
    root   /usr/local/nginx/html; #定义服务器的默认网站根目录位置
    #重定向
    if ($host != 'www.dbspread.com' ){ 
            rewrite ^/(.*)$  http://www.dbspread.com/$1  permanent;
            }

    #防盗链
     location ~* \.(rmvb|jpg|png|swf|flv)$ { #rmvb|jpg|png|swf|flv表示对rmvb|jpg|png|swf|flv后缀的文件实行防盗链
                valid_referers none blocked  www.dbspread.com; #表示对www.dbspread.com此域名开通白名单，比如在www.test.com的index.html引用download/av123.rmvb,无效
                root   html/b;
                if ($invalid_referer) { #如果请求不是从www.dbspread.com白名单发出来的请求，直接重定向到403.html这个页面或者返回403 
                     #rewrite ^/ http://www.dbspread.com/403.html;
                     return 403;
                }
        }

    #监听完成以后通过斜杆(/)拦截请求转发到后端的tomcat服务器
    location / 
        {
            #如果后端的服务器返回502、504、执行超时等错误，自动将请求转发到upstream负载均衡池中的另一台服务器，实现故障转移。
            proxy_next_upstream http_502 http_504 error timeout invalid_header;
            proxy_set_header Host  $host; #获取客户端的主机名存到变量Host里面,从而让tomcat取到客户端机器的信息
            proxy_set_header X-Real-IP $remote_addr; #获取客户端的主机名存到变量X-Real-IP里面,从而让tomcat取到客户端机器的信息
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            #rewrite     ^/$    http://www.dbspread.com/new.index.html  permanent;#用户访问www.dbspread.com，想直接跳转到网站下面的某个页面:www.dbspread.com/new.index.html
            proxy_pass http://web1; #跳转到对应的应用web1
        }

       # location ~ .*\.(php|jsp|cgi|shtml)?$ #动态分离 ~匹配 以.*结尾（以PHP JSP结尾走这段）
       #  {
       #     proxy_set_header Host  $host;
       #        proxy_set_header X-Real-IP $remote_addr;
       #        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
       #        proxy_pass http://jvm_web2;
       # }

        #静态分离 ~匹配 以.*结尾（以html|htm|gif|jpg|jpeg|bmp|png|ico|txt|js|css结尾走这段），当然不是越久越好，如果有10000个用户在线，都保存几个月，系统托跨
        location ~ .*\.(html|htm|gif|jpg|jpeg|bmp|png|ico|txt|js|css)$ 
        {
            root /var/local/static; #静态资源存放在nginx的安装机器上
            #proxy_pass http://www.static.com; #静态资源也可存放在远程服务器上
            expires    30d;
        }

        #日志级别有[debug|info|notice|warn|error|crit]  error_log 级别分为 debug, info, notice, warn, error, crit  默认为crit, 生产环境用error 
        #crit 记录的日志最少,而debug记录的日志最多
        access_log  /usr/local/logs/web2/access.log main;
        error_log   /usr/local/logs/web2/error.log  crit;

    }


}
```

到这一步环境准备已完成，相关的配置也修改完成，下面我们来查看效果

5.6 配置hosts域名映射

```
192.168.152.200  www.dbspread.com
```

> 注意：这里192.168.152.200 是keepalived里面virtual_ipaddress配置的虚拟ip

```
 virtual_ipaddress {
        192.168.152.200 # 定义虚拟ip(VIP)，可多设，每行一个
    }
```

到这一步环境准备已完成，相关的配置也修改完成，下面我们来查看效果

5.7 分别启动192.168.152.129的两个tomcat

5.8 分别启动192.168.152.130（keepalived主节点）和 192.168.152.129（keepalived从节点）的keepalived的

启动命令：

```
/usr/local/keepalived/sbin/keepalived  
```

![image-20211218092401782](https://gitee.com/er-huomeng/img/raw/master/image-20211218092401782.png)

可以看到keepalived和nginx都启动了

在浏览器输入www.dpspread.com域名访问

5.9 下面我们停掉主节点192.168.152.130的keepalived和nginx

可以看到从节点变为主节点了

在浏览器输入地址www.dpspread.com访问，可以看到访问正常

5.10 下面我们重新启动主节点192.168.152.130

可以看到主节点重新启动以后变为主节点了

之前变为主节点的从节点又变回从节点了

到此keepalived+nginx的高可用完美完成，可以安安心心的睡个好觉了! Victory!!!!