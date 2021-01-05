# [centos7.x下环境搭建(五)—nginx搭建https服务](https://www.cnblogs.com/fozero/p/10968550.html)

## https证书获取

十大免费SSL证书
https://blog.csdn.net/ithomer/article/details/78075006

如果我们用的是阿里云或腾讯云，他们都提供了免费版的ssl证书，我们直接下载就可以了，这里我使用的是阿里云提供的免费证书

## 修改nginx配置

1、在nginx安装目录下创建cert目录并将.pem和.key的证书拷贝到该目录下
.crt文件：是证书文件，crt是pem文件的扩展名。
.key文件：证书的私钥文件

2、nginx.conf配置

如果我们需要配置多站点的话，我们在根目录下创建一个vhost目录，并新建.conf结尾的文件，加入以下内容

```yaml
server {
    listen              443 ssl;
    server_name         test.test.cn;
    ssl_certificate     /etc/nginx/cert/2283621_test.cn.pem;
    ssl_certificate_key /etc/nginx/cert/2283621_test.cn.key;
    ssl_protocols       TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers         HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
         location / {
           proxy_set_header Host $host;
           proxy_set_header X-Real-Ip $remote_addr;
           proxy_set_header X-Forwarded-For $remote_addr;
           proxy_pass http://localhost:7001;
        }
 }
```

然后修改nginx.conf配置文件，并在http节点里面最后一行添加如下配置

```yaml
include /etc/nginx/vhost/*.conf;
```

这样在配置多站点的时候，我们就直接可以在vhost下新建一个.conf结尾的文件就行了

3、转发80端口到https

配置完https之后，默认端口是443，但如果使用http请求的话，并不会跳转到https，这时候我们需要将80端口转发到https上面来
添加80端口监听`listen 80`

```
server {
	listen       80;
    listen              443 ssl;
    server_name         love.diankr.cn;
    ssl_certificate     /etc/nginx/cert/2283621_test.cn.pem;
    ssl_certificate_key /etc/nginx/cert/2283621_test.cn.key;
    ssl_protocols       TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers         HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
         location / {
           proxy_set_header Host $host;
           proxy_set_header X-Real-Ip $remote_addr;
           proxy_set_header X-Forwarded-For $remote_addr;
           proxy_pass http://localhost:7001;
        }
 }
```

这样在访问http://开头的地址的时候会自动跳转到https地址下

## 添加iptables规则开放80和443端口

nginx安装完之后除了需要开放80端口之外，还需要开放443端口

```
#添加以下iptables规则开放80端口
iptables -I INPUT -p tcp --dport 80 -j ACCEPT

#iptables添加2条规则用于开放443端口
iptables -A FORWARD -p tcp --dport 443 -j ACCEPT
iptables -A FORWARD -p tcp --sport 443 -j ACCEPT
规则1用于放行客户端请求https服务的报文
规则2用于放行https服务器发送给客户端的报文
```

## 查看nginx错误日志

```
 tail -f -n 20  /var/log/nginx/error.log
```

## 问题总结

1、nginx: [warn] the "ssl" directive is deprecated的解决方法

这是一个warn警告，nginx提示ssl这个指令已经不建议使用，要使用listen ... ssl替代。网上查找nginx更新日志里面，也有提到：
`Change: the “ssl” directive is deprecated; the “ssl” parameter of the “listen” directive should be used instead.`
ssl不建议作为一个指令使用，而是应该listen指令的一个参数。

解决
如果使用listen 443 ssl，删除ssl on就行了。

2、在配置好ssl之后，以及将443端口添加到了阿里云的安全组，浏览器访问最终还是无法访问，提示拒绝了请求链接
分析之后发现还是跟防火墙有关系
解决

```
#清除系统中防火墙默认规则
iptables -F
```



# Nginx配置SSL证书监听443端口



**一、准备证书文件**

我使用的是阿里云Symantec 免费版 SSL证书。将证书文件下载后解压得到如下文件

![img](https://img.jbzj.com/file_images/article/201802/201822893341161.jpg?201812893411)

在nginx–>cert目录中建一个ssl目录，将上面的所有文件拷贝到ssl目录中

**二、修改nginx.conf文件**

在nginx.conf的http{}中填下如下内容

```
server {`` ``listen 443;`` ``server_name www.httpstest.com;`` ``ssl on;`` ``root html;`` ``index index.html index.htm;`` ``#这里的.pem/.key文件替换成自己对应的文件名`` ``ssl_certificate cert``/xxxxx``.pem;`` ``ssl_certificate_key cert``/xxxx``.key;`` ``ssl_session_timeout 5m;`` ``ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE:ECDH:AES:HIGH:!NULL:!aNULL:!MD5:!ADH:!RC4;`` ``ssl_protocols TLSv1 TLSv1.1 TLSv1.2;`` ``ssl_prefer_server_ciphers on;`` ``location / {`` ``#代理的目标地址`` ``proxy_pass http:``//127``.0.0.1:10443;`` ``}``}
```

最后别忘了重启nginx服务。



# 配置一：nginx-https,反向代理Tomcat请求

案例说明：
前面一层nginx+Keepalived部署的LB,后端两台web服务器部署了多实例的tomcat，通过https方式部署nginx反向代理tomcat请求。**配置一**如下：

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

# 配置二：也可以采用如下**proxy_redirect**配置（指定修改被代理服务器返回的响应头中的location头域跟refresh头域数值）（注意下面proxy_redirect里由http -> https的代理返回设置）

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

