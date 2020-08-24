案例说明：
前面一层nginx+Keepalived部署的LB,后端两台web服务器部署了多实例的tomcat，通过https方式部署nginx反向代理tomcat请求。**配置一**如下：

# 配置一

```yaml
1）LB层的nginx配置
 
访问http强制转到https
[root@external-lb01 ~]# cat /data/nginx/conf/vhosts/80-www.kevin.com.conf
server {
        listen       80;
        server_name  kevin.com www.kevin.com;
 
        access_log  /data/nginx/logs/www.kevin.com-access.log main;
        error_log  /data/nginx/logs/www.kevin.com-error.log;
 
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
 
        return      301 https://$server_name$request_uri;
}
 
 
https反向代理的配置
[root@external-lb01 ~]# cat /data/nginx/conf/vhosts/443-www.kevin.com.conf
upstream scf_cluster {
    ip_hash;
    server 192.168.10.20:9020;
    server 192.168.10.21:9020;
    }
upstream portal_cluster {
    ip_hash;
    server 192.168.10.20:9040;
    server 192.168.10.21:9040;
    }
upstream file_cluster{
    ip_hash;
    server 192.168.10.20:9020;
    }
upstream workflow_cluster{
    ip_hash;
    server 192.168.10.20:9020;
    server 192.168.10.21:9020;
    }
upstream batch_cluster{
    server 192.168.10.20:9020;
    server 192.168.10.21:9020;
    }
 
server {
        listen       443;
        server_name  www.kevin.com;
 
        ssl on;
        ssl_certificate /data/nginx/conf/ssl/kevin.cer;
        ssl_certificate_key /data/nginx/conf/ssl/kevin.key;
        ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
        ssl_session_cache    shared:SSL:1m;
        ssl_session_timeout  5m;
        ssl_ciphers  ECDHE-RSA-AES128-GCM-SHA256:ECDHE:ECDH:AES:HIGH:!NULL:!aNULL:!MD5:!ADH:!RC4:!DH:!DHE;
        ssl_prefer_server_ciphers  on;
 
        access_log  /data/nginx/logs/www.kevin.com-access.log main;
        error_log  /data/nginx/logs/www.kevin.com-error.log;
 
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
 
       rewrite /portal-pc https://www.kevin.com break;
 
       location / {
            proxy_pass http://portal_cluster/portal-pc/;
            proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504 http_404;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto http;
            proxy_redirect off;
 
        }
 
            location /scf {
            proxy_pass http://scf_cluster/scf;
            proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504 http_404;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto http;
            proxy_redirect off;
 
        }
 
        location /msdp-file {
            proxy_pass http://file_cluster/msdp-file;
            proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504 http_404;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto http;
            proxy_redirect off;
 
        }
         
    location /upload {
            proxy_pass http://file_cluster/upload;
            proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504 http_404;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto http;
            proxy_redirect off;
 
        }
         
        location /activiti-workflow-console {
            proxy_pass http://workflow_cluster/activiti-workflow-console;
            proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504 http_404;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto http;
            proxy_redirect off;
 
        }
 
    location /batch-framework-web {
            proxy_pass http://batch_cluster/batch-framework-web;
            proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504 http_404;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto http;
            proxy_redirect off;
        } 
}
 
 
以上配置中，需要注意：
访问https://www.kevin.com 要求和访问http://192.168.10.20:9040/portal-pc/ 结果一致
访问https://www.kevin.com/portal-pc 要求和访问https://www.kevin.com 结果一致
 
 
2）后端两台机器192.168.10.20和192.168.10.21的tomcat配置。两台配置一致，这里以192.168.10.20配置为例：
[root@bl2-app01 ~]# cat /data/release/projects/tomcat_app_9020/conf/server.xml
......
    <Connector port="9020" protocol="HTTP/1.1"
               connectionTimeout="20000"
               redirectPort="8443" URIEncoding="UTF-8"/>
......
    <Connector port="9029" protocol="AJP/1.3" redirectPort="8443" />
 
 
[root@bl2-app01 ~]# cat /data/release/projects/tomcat_portal_9040/conf/server.xml
......
<Connector port="9040" protocol="HTTP/1.1"
               connectionTimeout="20000"
               redirectPort="4443" URIEncoding="UTF-8"/>
......
    <Connector port="9049" protocol="AJP/1.3" redirectPort="4443" />
.....
```

## **配置二：**也可以采用如下**proxy_redirect**配置（指定修改被代理服务器返回的响应头中的location头域跟refresh头域数值）（注意下面proxy_redirect里由http -> https的代理返回设置）

```yaml
[root@external-lb01 ~]# cat /data/nginx/conf/vhosts/443-www.kevin.com.conf
upstream scf_cluster {
    ip_hash;
    server 192.168.10.20:9020;
    server 192.168.10.21:9020;
    }
upstream portal_cluster {
    ip_hash;
    server 192.168.10.20:9040;
    server 192.168.10.21:9040;
    }
upstream file_cluster{
    ip_hash;
    server 192.168.10.20:9020;
    }
upstream workflow_cluster{
    ip_hash;
    server 192.168.10.20:9020;
    server 192.168.10.21:9020;
    }
upstream batch_cluster{
    server 192.168.10.20:9020;
    server 192.168.10.21:9020;
    }
   
server {
        listen       443;
        server_name  www.kevin.com;
   
        ssl on;
        ssl_certificate /data/nginx/conf/ssl/bigtree.cer;
        ssl_certificate_key /data/nginx/conf/ssl/bigtree.key;
        ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
        ssl_session_cache    shared:SSL:1m;
        ssl_session_timeout  5m;
        ssl_ciphers  ECDHE-RSA-AES128-GCM-SHA256:ECDHE:ECDH:AES:HIGH:!NULL:!aNULL:!MD5:!ADH:!RC4:!DH:!DHE;
        ssl_prefer_server_ciphers  on;
   
        access_log  /data/nginx/logs/www.kevin.com-access.log main;
        error_log  /data/nginx/logs/www.kevin.com-error.log;
   
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
   
        location /scf {
            proxy_pass http://scf_cluster/scf;
            proxy_redirect  http://scf_cluster/scf https://www.kevin.com/scf;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_connect_timeout 300;
            proxy_send_timeout 300;
            proxy_read_timeout 600;
            proxy_buffer_size 256k;
            proxy_buffers 4 256k;
            proxy_busy_buffers_size 256k;
            proxy_temp_file_write_size 256k;
            proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504 http_404;
            proxy_max_temp_file_size 128m;
        }
   
        location / {
            proxy_pass http://portal_cluster/portal-pc/;
            proxy_redirect  http://portal_cluster/portal-pc/ https://www.kevin.com/;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_connect_timeout 300;
            proxy_send_timeout 300;
            proxy_read_timeout 600;
            proxy_buffer_size 256k;
            proxy_buffers 4 256k;
            proxy_busy_buffers_size 256k;
            proxy_temp_file_write_size 256k;
            proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504 http_404;
            proxy_max_temp_file_size 128m;
        }
   
        location /msdp-file {
            proxy_pass http://file_cluster/msdp-file;
            proxy_redirect  http://file_cluster/msdp-file https://www.kevin.com/msdp-file;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_connect_timeout 300;
            proxy_send_timeout 300;
            proxy_read_timeout 600;
            proxy_buffer_size 256k;
            proxy_buffers 4 256k;
            proxy_busy_buffers_size 256k;
            proxy_temp_file_write_size 256k;
            proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504 http_404;
            proxy_max_temp_file_size 128m;
        }
           
        location /upload {
            proxy_pass http://file_cluster/upload;
            proxy_redirect  http://file_cluster/upload https://www.kevin.com/upload;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_connect_timeout 300;
            proxy_send_timeout 300;
            proxy_read_timeout 600;
            proxy_buffer_size 256k;
            proxy_buffers 4 256k;
            proxy_busy_buffers_size 256k;
            proxy_temp_file_write_size 256k;
            proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504 http_404;
            proxy_max_temp_file_size 128m;
        }
           
        location /activiti-workflow-console {
            proxy_pass http://workflow_cluster/activiti-workflow-console;
            proxy_redirect  http://workflow_cluster/activiti-workflow-console https://www.kevin.com/activiti-workflow-console;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_connect_timeout 300;
            proxy_send_timeout 300;
            proxy_read_timeout 600;
            proxy_buffer_size 256k;
            proxy_buffers 4 256k;
            proxy_busy_buffers_size 256k;
            proxy_temp_file_write_size 256k;
            proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504 http_404;
            proxy_max_temp_file_size 128m;
        }
   
        location /batch-framework-web {
            proxy_pass http://batch_cluster/batch-framework-web;
            proxy_redirect  http://batch_cluster/batch-framework-web https://www.kevin.com/batch-framework-web;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_connect_timeout 300;
            proxy_send_timeout 300;
            proxy_read_timeout 600;
            proxy_buffer_size 256k;
            proxy_buffers 4 256k;
            proxy_busy_buffers_size 256k;
            proxy_temp_file_write_size 256k;
            proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504 http_404;
            proxy_max_temp_file_size 128m;
        }
}
 
======================温馨提示========================
上面启用了proxy_redirect配置（http->https），配置中就不需要"proxy_set_header Host $host;"，即不需要"添加发往后端服务器的请求头"的配置了
```

如上，配置了80端口的http访问强制跳转为443端口的https访问方式：
1）如果域名配置为https的访问方式，则上面配置一和配置二都可以。
2）如果域名配置为http的访问方式，则如上配置一后，访问的结果都只会跳转到https的首页，故这种情况下需如上配置二。



```yaml
如下，访问http://bpm.kevin.com的结果只会在强制跳转为https://www.kevin.com
[root@external-lb01 ~]# cat /data/nginx/conf/vhosts/bpm.kevin.com.conf
upstream os-8080 {
      #ip_hash;
      server 192.168.10.20:8080 max_fails=3 fail_timeout=15s;
      server 192.168.10.21:8080 max_fails=3 fail_timeout=15s;
}
             
server {
      listen      80;
      server_name bpm.kevin.com;
       
      access_log  /data/nginx/logs/bpm.kevin.com-access.log main;
      error_log  /data/nginx/logs/bpm.kevin.com-error.log;
       
location / {
      proxy_pass http://os-8080;
      proxy_redirect off ;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header REMOTE-HOST $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_connect_timeout 300;
      proxy_send_timeout 300;
      proxy_read_timeout 600;
      proxy_buffer_size 256k;
      proxy_buffers 4 256k;
      proxy_busy_buffers_size 256k;
      proxy_temp_file_write_size 256k;
      proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504 http_404;
      proxy_max_temp_file_size 128m;
      #proxy_cache mycache;                             
      #proxy_cache_valid 200 302 1h;
      #proxy_cache_valid 301 1d;
      #proxy_cache_valid any 1m;
    }
       
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   html;
    }
}
   
   
如果想要访问http://bpm.kevin.com的结果不强制跳转为https://www.kevin.com，则需要启用proxy_redirect的配置：
[root@external-lb01 ~]# cat /data/nginx/conf/vhosts/bpm.kevin.com.conf
upstream os-8080 {
      #ip_hash;
      server 192.168.10.20:8080 max_fails=3 fail_timeout=15s;
      server 192.168.10.21:8080 max_fails=3 fail_timeout=15s;
}
             
  server {
      listen      80;
      server_name bpm.kevin.com;
       
      access_log  /data/nginx/logs/bpm.kevin.com-access.log main;
      error_log  /data/nginx/logs/bpm.kevin.com-error.log;
       
 location / {
      proxy_pass http://os-8080;
      proxy_set_header Host $host;    //注意这个是http请求，没有http->https转发需求，必须要加上这个proxy_set_header设置，否则代理转发返回的头信息会有误！
      proxy_redirect  http://os-8080/ http://bpm.kevin.com/;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504 http_404;
    }
   
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
    root   html;
    }
}
```

nginx做前端代理分发，tomcat处理请求。nginx反代tomcat实现https有二个方法

```yaml
一、nginx配置https，tomcat也配置https
1）nginx配置https
upstream https_tomcat_web { 
        server 127.0.0.1:8443; 
} 
   
server { 
        listen       443; 
        server_name  www.test.com; 
        index index.html; 
        root   /var/www/html/test; 
   
        ssl on; 
        ssl_certificate /etc/nginx/go.pem; 
        ssl_certificate_key /etc/nginx/go.key; 
        ssl_session_timeout 5m; 
        ssl_protocols SSLv2 SSLv3 TLSv1.2; 
#        ssl_ciphers ALL:!ADH:!EXPORT56:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv2:+EXP; 
        ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE:ECDH:AES:HIGH:!NULL:!aNULL:!MD5:!ADH:!RC4; 
        ssl_prefer_server_ciphers on; 
   
        location ~ ^/admin { 
            proxy_pass https://https_tomcat_web;  //是https的 
            proxy_redirect                      off; 
            proxy_set_header   Host             $host; 
            proxy_set_header   X-Real-IP        $remote_addr; 
            proxy_set_header   X-Forwarded-For  $proxy_add_x_forwarded_for; 
            client_max_body_size       100m; 
            client_body_buffer_size    256k; 
            proxy_connect_timeout      60; 
            proxy_send_timeout         30; 
            proxy_read_timeout         30; 
            proxy_buffer_size          8k; 
            proxy_buffers              8 64k; 
            proxy_busy_buffers_size    64k; 
            proxy_temp_file_write_size 64k; 
        } 
   
        error_page 404 /404.html; 
        location = /40x.html { 
        } 
   
        error_page 500 502 503 504 /50x.html; 
   
        location = /50x.html { 
        } 
   
} 
 
 
2）tomcat的https配置,配置文件server.xml
<Service name="Catalina"> 
 <Connector port="8001" protocol="HTTP/1.1" 
 connectionTimeout="20000" 
 redirectPort="8443" /> 
   
 <Connector port="8091" 
 protocol="AJP/1.3" 
 redirectPort="8443" /> 
   
//添加以下内容 
 <Connector port="8443" 
 protocol="HTTP/1.1" 
 SSLEnabled="true" 
 scheme="https" 
 secure="false" 
 keystoreFile="cert/gotom.pfx" 
 keystoreType="PKCS12" 
 keystorePass="214261272770418" 
 clientAuth="false" 
 SSLProtocol="TLSv1+TLSv1.1+TLSv1.2" 
 ciphers="TLS_RSA_WITH_AES_128_CBC_SHA,TLS_RSA_WITH_AES_256_CBC_SHA,TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA,TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256,TLS_RSA_WITH_AES_128_CBC_SHA256,TLS_RSA_WITH_AES_256_CBC_SHA256" /> 
   
 ..................省略.................... 
 </Service> 
 
 
 配置好后重新启动nginx，tomcat，就可以https访问了，这也是现在比较常见采用的配置方式 。
 
 
 
二、nginx采用https，tomcat采用http
1）nginx配置https
upstream https_tomcat_web { 
        server 127.0.0.1:8001; 
} 
   
server { 
        listen       443; 
        server_name  www.test.com; 
        index index.html; 
        root   /var/www/html/test; 
   
        ssl on; 
        ssl_certificate /etc/nginx/go.pem; 
        ssl_certificate_key /etc/nginx/go.key; 
        ssl_session_timeout 5m; 
        ssl_protocols SSLv2 SSLv3 TLSv1.2; 
#        ssl_ciphers ALL:!ADH:!EXPORT56:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv2:+EXP; 
        ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE:ECDH:AES:HIGH:!NULL:!aNULL:!MD5:!ADH:!RC4; 
        ssl_prefer_server_ciphers on; 
   
        location ~ ^/admin { 
            proxy_pass http://https_tomcat_web;  //是http的 
            proxy_redirect                      off; 
            proxy_set_header   Host             $host; 
            proxy_set_header   X-Real-IP        $remote_addr; 
            proxy_set_header   X-Forwarded-For  $proxy_add_x_forwarded_for; 
            client_max_body_size       100m; 
            client_body_buffer_size    256k; 
            proxy_connect_timeout      60; 
            proxy_send_timeout         30; 
            proxy_read_timeout         30; 
            proxy_buffer_size          8k; 
            proxy_buffers              8 64k; 
            proxy_busy_buffers_size    64k; 
            proxy_temp_file_write_size 64k; 
        } 
   
        error_page 404 /404.html; 
        location = /40x.html { 
        } 
   
        error_page 500 502 503 504 /50x.html; 
   
        location = /50x.html { 
        } 
   
} 
 
2）tomcat的http配置,配置文件server.xml
<Service name="Catalina"> 
 <Connector port="8001" protocol="HTTP/1.1" 
 connectionTimeout="20000" 
 redirectPort="443" />    //在这里重新定向到了443端口 
   
 <Connector port="8091" 
 protocol="AJP/1.3" 
 redirectPort="443" /> 
   
 ..................省略.................... 
 </Service> 
重启nginx，tomcat，https就配置好了。
```

**=====================Nginx非80端口代理转发配置=======================**
注意：nginx使用非80端口转发时，**proxy_set_header配置中的$host后面一定要跟端口**！如下篇配置（**proxy_set_header Host $host:8080**; ）。否则访问会有问题！（当https访问时，已配置了http强转https，则$host后面不需加443端口）。

```yaml
[root@ng-lb01 vhosts]# cat fax.kevin.com.conf
upstream fax {
      server 192.168.10.34:8080;
}
           
  server {
      listen      8080;
      server_name fax.kevin.com;
     
      access_log  /data/nginx/logs/fax.kevin.com-access.log main;
      error_log  /data/nginx/logs/fax.kevin.com-error.log;
 
    location / {
            proxy_pass http://fax;
            proxy_set_header Host $host:8080;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto http;
            proxy_redirect off;
 
        }
 
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
}
```

