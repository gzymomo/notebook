[TOC]

WebSocket 和HTTP协议不同，但是WebSocket中的握手和HTTP中的握手兼容，它使用HTTP中的Upgrade协议头将连接从HTTP升级到WebSocket。这使得WebSocket程序可以更容易的使用现已存在的基础设施。例如，WebSocket可以使用标准的HTTP端口 80 和 443，因此，现存的防火墙规则也同样适用。

一个WebSockets的应用程序会在客户端和服务端保持一个长时间工作的连接。用来将连接从HTTP升级到WebSocket的HTTP升级机制使用HTTP的Upgrade和Connection协议头。反向代理服务器在支持WebSocket方面面临着一些挑战。一项挑战是WebSocket是一个hop-by-hop协议，所以，当代理服务器拦截到一个客户端发来的Upgrade请求时，它(指服务器)需要将它自己的Upgrade请求发送给后端服务器，也包括合适的请求头。此外，由于WebSocket连接是长时间保持的，所以代理服务器需要允许这些连接处于打开状态，而不是像对待HTTP使用的短连接那样将其关闭。

NGINX 通过在客户端和后端服务器之间建立起一条隧道来支持WebSocket。为了使NGINX可以将来自客户端的Upgrade请求发送给后端服务器，Upgrade和Connection的头信息必须被显式的设置。

#配置
其实核心配置只要这几句，但是确有很多不同的情况，需要根据情况加入支持。
```xml
proxy_http_version 1.1;
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection "upgrade";
proxy_set_header X-real-ip $remote_addr;
proxy_set_header X-Forwarded-For $remote_addr
```

如果你不是反向代理本地，是集群，可能有跨域的问题，需要加入
```xml
# 允许跨域
    add_header Access-Control-Allow-Origin *;
    add_header Access-Control-Allow-Methods 'GET, POST, OPTIONS';
    add_header Access-Control-Allow-Headers 'DNT,X-Mx-ReqToken,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Authorization';
```

nginx.conf中server部分的栗子:
```xml
    server {
        listen       80;
        #域名配置
        server_name  localhost;

        charset utf-8;
		client_max_body_size 15m;
		client_body_buffer_size 512k;
		proxy_connect_timeout 90;
		proxy_send_timeout 120;
		proxy_read_timeout 120;
		proxy_buffer_size 4k;
		proxy_buffers 4 32k;
		proxy_busy_buffers_size 64k;
		proxy_temp_file_write_size 64k;
		#websocket相关配置
		proxy_http_version 1.1;
		proxy_set_header Upgrade $http_upgrade;
    	proxy_set_header Connection "upgrade";
    	proxy_set_header X-real-ip $remote_addr;
		proxy_set_header X-Forwarded-For $remote_addr;
		#这里是正向代理，前端vue地址
        root    "/vdb1/xxxx/vue";
        location / {
            index  index.html index.htm index.php l.php;
           autoindex  off;
        }
        location /xxxx{
           #这里是后台Java SpringBoot地址，反向代理
           proxy_pass   http://localhost:8888/xxxx;
        }
    }
```