- [使用Nginx实现端口转发TCP代理_翟卫卫的博客-CSDN博客_nginx一个端口代理多个tcp](https://blog.csdn.net/jack170601/article/details/122114545)

- [Nginx配置TCP请求转发 - airoot - 博客园 (cnblogs.com)](https://www.cnblogs.com/airoot/p/14958783.html)
- [Nginx支持TCP端口转发 - 虍亓卅 - 博客园 (cnblogs.com)](https://www.cnblogs.com/zuojl/p/15061499.html)

## 1 检查 nginx 是否安装 stream 模块

```bash
nginx -V |grep with-stream
# 或者
nginx -V
```

当我们在输出的配置参数中包含`--with-stream`说明nginx是支TCP代理的

## 2 安装依赖

```bash
# 依赖服务
[root@baolin conf]#yum -y install pcre-devel openssl openssl-devel library

# 编译安装 stream 组建
./configure --prefix=/usr/local/nginx/ --with-http_stub_status_module --with-http_ssl_module --with-stream  --with-stream_ssl_module

 
make && make install;
```

## 3 添加 tcp 转发配置

### 3.1 配置demo1

```
stream{
    upstream mysql_proxy{
        hash $remote_addr consistent;
        server 	127.0.0.1:3306 max_fails=3 fail_timeout=10s;  
    }
    server{
        listen 3306;
        proxy_connect_timeout 20s;
        proxy_timeout 5m;
        proxy_pass mysql_proxy;
    }
}
```

### 3.2 配置demo2

```
[root@baolin conf]# cat /usr/local/nginx/nginx.conf
worker_processes  1;

events {
    worker_connections  1024;
}

# 此为TCP转发请求 stream 
stream {
    # 后端指向 server 的 8085 端口 stream_backend 组
    upstream stream_backend {
         server 10.50.2.11:8085;
         server 10.50.2.19:8085;
    }
    
    # 后端指向 server 的 8090 端口 cns组
    upstream cns {
         server 10.50.2.11:8090;
         server 10.50.2.19:8090;
    }
     server {
        listen                443 ssl;
        proxy_pass            stream_backend;
        # 指定key 和 crt 地址
        ssl_certificate       /etc/ssl/certs/my.crt;
        ssl_certificate_key   /etc/ssl/certs/my.key;
        ssl_protocols         SSLv3 TLSv1 TLSv1.1 TLSv1.2;
        ssl_ciphers           HIGH:!aNULL:!MD5;
        ssl_session_cache     shared:SSL:20m;
        ssl_session_timeout   4h;
        ssl_handshake_timeout 30s;
    }
  server {
        # 本机监听端口 8080 
        listen                8080;
        
        # 请求抛给 stream_backend 组
        proxy_pass            stream_backend;
       }
  server {
        # 本机监听端口 8090 
        listen                8090;
        
        # 请求抛给 cns 组
        proxy_pass            cns;
       }       
    }

    # 此为HTTP 转发请求 http
    http {
        log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                          '$status $body_bytes_sent "$http_referer" '
                          '"$http_user_agent" "$http_x_forwarded_for"';

        access_log  /var/log/nginx/access.log  main;

        sendfile            on;
        tcp_nopush          on;
        gzip_comp_level 9;
        gzip_types  text/css text/xml  application/javascript;
        gzip_vary on;

        include             /etc/nginx/mime.types;
        default_type        application/octet-stream;
        
      # 后端指向 server 的 8585 端口 cns_node 组
      upstream  cns_node {
             server 10.50.2.51:8585 weight=3;
             server 10.50.2.59:8585 weight=3;
        }
       
       server {
        listen       8585;
        server_name umout.com;

        access_log  /etc/nginx/logs/server02_access.log main;

        location /{
          index index.html index.htm index.jsp;
          proxy_pass http://cns_node1;
          include /etc/nginx/proxy.conf; 
        }
      }
    }
```

## 4 验证

```bash
# 检查nginx配置文件是否准确
nginx -t
# 重启
nginx -s reload
# 检测
telnet x.x.x.x 3306
```

