# [Nginx 高性能优化配置实战总结](https://segmentfault.com/a/1190000037788252)



Nginx是Apache服务不错的替代品。其特点是占有内存少，并发能力强，事实上[nginx的并发](http://mp.weixin.qq.com/s?__biz=MzI0MDQ4MTM5NQ==&mid=2247491116&idx=2&sn=e13451256e97fa889ec81043b0d04912&chksm=e91b7b30de6cf22664b0ae92e9e326aa339e0e8b0f3d49df1cfd337fe031b779e5b63dc00369&scene=21#wechat_redirect)能力在同类型的网页服务器中表现较好，因此国内知名大厂例如：淘宝，京东，百度，新浪，网易，腾讯等等都在使用[Nginx](http://mp.weixin.qq.com/s?__biz=MzI0MDQ4MTM5NQ==&mid=2247495416&idx=1&sn=bada1264baa5cc387cc2790fb87d5fc3&chksm=e9188be4de6f02f2a79586c60d1071132b8b70a83ab268808cb08139efc21b142790195383f5&scene=21#wechat_redirect)网站。



## 一、如何自定义返回给客户端的404错误页面

![img](https://segmentfault.com/img/remote/1460000037788255)1）优化前，客户端使用浏览器访问不存在的页面，会提示404文件未找到

```
[root@client ~]# firefox http://192.168.4.5/xxxxx        //访问一个不存在的页面
```

2）修改[Nginx配置文件](http://mp.weixin.qq.com/s?__biz=MzI0MDQ4MTM5NQ==&mid=2247490919&idx=2&sn=d1bbbf3974565aa1cb41c3e9a4f3826b&chksm=e91b787bde6cf16dd8e208ec07188578d2b68683b01d7fe395a4f0372134cf8c57746b07ea42&scene=21#wechat_redirect)，自定义报错页面

```
[root@proxy ~]# vim /usr/local/nginx/conf/nginx.conf
.. ..
    charset utf-8;               //仅在需要中文时修改该选项
error_page   404  /404.html;    //自定义错误页面
.. ..
[root@proxy ~]# vim /usr/local/nginx/html/404.html      //生成错误页面
Oops,No NO no page …
[root@proxy ~]# nginx -s reload
#请先确保nginx是启动状态，否则运行该命令会报错,报错信息如下：
#[error] open() "/usr/local/nginx/logs/nginx.pid" failed (2: No such file or directory)
```

3）优化后，客户端使用浏览器访问不存在的页面，会提示自己定义的40x.html页面

```
[root@client ~]# firefox http://192.168.4.5/xxxxx    //访问一个不存在的页面
```

常见的http状态码可用参考表所示![img](https://segmentfault.com/img/remote/1460000037788256)

## 二、如何查看服务器状态信息（非常重要的功能）

1）编译安装时使用--with-http_stub_status_module开启状态页面模块

```
[root@proxy ~]# tar  -zxvf   nginx-1.12.2.tar.gz
[root@proxy ~]# cd  nginx-1.12.2
[root@proxy nginx-1.12.2]# ./configure   
> --with-http_ssl_module                        //开启SSL加密功能
> --with-stream                                //开启TCP/UDP代理模块
> --with-http_stub_status_module                //开启status状态页面
[root@proxy nginx-1.12.2]# make && make install    //编译并安装
```

2）启用[Nginx服务](http://mp.weixin.qq.com/s?__biz=MzI0MDQ4MTM5NQ==&mid=2247494790&idx=2&sn=acc3075a8b5e59824baf31a2b81b560b&chksm=e918899ade6f008cf7abb6864dbf8ca3c3e94e54c66115272a36f2df390c44ce0538ad4de1a1&scene=21#wechat_redirect)并查看监听端口状态

ss命令可以查看系统中启动的端口信息，该命令常用选项如下：

- -a显示所有端口的信息
- -n以数字格式显示端口号
- -t显示TCP连接的端口
- -u显示UDP连接的端口
- -l显示服务正在监听的端口信息，如httpd启动后，会一直监听80端口
- -p显示监听端口的服务名称是什么（也就是程序名称）

注意：在RHEL7系统中可以使用ss命令替代netstat命令，功能一样，选项一样。

```
[root@proxy ~]# /usr/local/nginx/sbin/nginx
[root@proxy ~]# netstat  -anptu  |  grep nginx
tcp        0        0 0.0.0.0:80        0.0.0.0:*        LISTEN        10441/nginx
[root@proxy ~]# ss  -anptu  |  grep nginx
```

3）修改[Nginx配置文件](http://mp.weixin.qq.com/s?__biz=MzI0MDQ4MTM5NQ==&mid=2247489371&idx=1&sn=f53d7e68964ab9178aa31dc75e43595f&chksm=e91b7247de6cfb519db17244f9a3598affe8744fb1c42661a5167349df9f80e66a80d08fa052&scene=21#wechat_redirect)，定义状态页面

```
[root@proxy ~]# cat /usr/local/nginx/conf/nginx.conf
… …
location /status {
                stub_status on;
                 #allow IP地址;
                 #deny IP地址;
        }
… …
[root@proxy ~]# /usr/local/nginx/sbin/nginx -s reload
```

4）优化后，查看状态页面信息

```
[root@proxy ~]# curl  http://192.168.4.5/status
Active connections: 1 
server accepts handled requests
 10 10 3 
Reading: 0 Writing: 1 Waiting: 0
```

- Active connections：当前活动的连接数量。
- Accepts：已经接受客户端的连接总数量。
- Handled：已经处理客户端的连接总数量。（一般与accepts一致，除非服务器限制了连接数量）。
- Requests：客户端发送的请求数量。
- Reading：当前服务器正在读取客户端请求头的数量。
- Writing：当前服务器正在写响应信息的数量。
- Waiting：当前多少客户端在等待服务器的响应。

## 三、[优化Nginx](http://mp.weixin.qq.com/s?__biz=MzI0MDQ4MTM5NQ==&mid=2247484627&idx=1&sn=8626a39ab0a9dc7d2a7bf26db7fd1ce8&chksm=e91b61cfde6ce8d924fd82809f5faeb334d50d371a4912dd0e1619c4d297937623e4cc09159e&scene=21#wechat_redirect)并发量

1）优化前使用ab高并发测试

```
[root@proxy ~]# ab -n 2000 -c 2000 http://192.168.4.5/
Benchmarking 192.168.4.5 (be patient)
socket: Too many open files (24)                //提示打开文件数量过多
```

2）修改Nginx配置文件，增加并发量

```
[root@proxy ~]# vim /usr/local/nginx/conf/nginx.conf
.. ..
worker_processes  2;                    //与CPU核心数量一致
events {
worker_connections 65535;        //每个worker最大并发连接数
}
.. ..
[root@proxy ~]# /usr/local/nginx/sbin/nginx -s reload
```

3）[优化Linux内核](http://mp.weixin.qq.com/s?__biz=MzI0MDQ4MTM5NQ==&mid=2247501408&idx=2&sn=4eea4df5f87a1570bb14eb88a32f3607&chksm=e918a37cde6f2a6ad0d47a9de817fe2d463473af6a85960382d8ae811711f6e697278728bbe7&scene=21#wechat_redirect)参数（最大文件数量）

```
[root@proxy ~]# ulimit -a                        //查看所有属性值
[root@proxy ~]# ulimit -Hn 100000                //设置硬限制（临时规则）
[root@proxy ~]# ulimit -Sn 100000                //设置软限制（临时规则）
[root@proxy ~]# vim /etc/security/limits.conf
    .. ..
*               soft    nofile            100000
*               hard    nofile            100000
#该配置文件分4列，分别如下：
#用户或组    硬限制或软限制    需要限制的项目   限制的值
```

4）优化后测试服务器并发量（因为客户端没调内核参数，所以在proxy测试）

```
[root@proxy ~]# ab -n 2000 -c 2000 http://192.168.4.5/
```

## 四、优化Nginx数据包头缓存

1）优化前，使用脚本测试长头部请求是否能获得响应

```
[root@proxy ~]# cat lnmp_soft/buffer.sh 
#!/bin/bash
URL=http://192.168.4.5/index.html?
for i in {1..5000}
do
    URL=${URL}v$i=$i
done
curl $URL                                //经过5000次循环后，生成一个长的URL地址栏
[root@proxy ~]# ./buffer.sh
.. ..
<center><h1>414 Request-URI Too Large</h1></center>        //提示头部信息过大
```

2）修改[Nginx配置](http://mp.weixin.qq.com/s?__biz=MzI0MDQ4MTM5NQ==&mid=2247488853&idx=1&sn=82a3d04d81d254bbb445fd10ad215dd9&chksm=e91b7049de6cf95f15df8264437786eb992519c45770c841bb902c01992192330424b94daf2a&scene=21#wechat_redirect)文件，增加数据包头部缓存大小

```
[root@proxy ~]# vim /usr/local/nginx/conf/nginx.conf
.. ..
http {
client_header_buffer_size    1k;        //默认请求包头信息的缓存    
large_client_header_buffers  4 4k;        //大请求包头部信息的缓存个数与容量
.. ..
}
[root@proxy ~]# /usr/local/nginx/sbin/nginx -s reload
```

3）优化后，使用脚本测试长头部请求是否能获得响应

```
[root@proxy ~]# cat buffer.sh 
#!/bin/bash
URL=http://192.168.4.5/index.html?
for i in {1..5000}
do
    URL=${URL}v$i=$i
done
curl $URL
[root@proxy ~]# ./buffer.sh
```

## 五、浏览器本地缓存静态数据

1）使用Firefox浏览器查看缓存

以Firefox浏览器为例，在Firefox地址栏内输入about:cache将显示Firefox浏览器的缓存信息，如图所示，点击List Cache Entries可以查看详细信息。![img](https://segmentfault.com/img/remote/1460000037788257)2）清空firefox本地缓存数据，如图所示。![img](https://segmentfault.com/img/remote/1460000037788258)3）改[Nginx配置](http://mp.weixin.qq.com/s?__biz=MzI0MDQ4MTM5NQ==&mid=2247489233&idx=1&sn=b437bfe717df82a5dc62bb97bbb72a4f&chksm=e91b73cdde6cfadb6908dd52c5f87deee908b800f0992b61a53bc38cf8d54405a14b4747b486&scene=21#wechat_redirect)文件，定义对静态页面的缓存时间

```
[root@proxy ~]# vim /usr/local/nginx/conf/nginx.conf
server {
        listen       80;
        server_name  localhost;
        location / {
            root   html;
            index  index.html index.htm;
        }
location ~* .(jpg|jpeg|gif|png|css|js|ico|xml)$ {
expires        30d;            //定义客户端缓存时间为30天
}
}
[root@proxy ~]# cp /usr/share/backgrounds/day.jpg /usr/local/nginx/html
[root@proxy ~]# /usr/local/nginx/sbin/nginx -s reload
#请先确保nginx是启动状态，否则运行该命令会报错,报错信息如下：
#[error] open() "/usr/local/nginx/logs/nginx.pid" failed (2: No such file or directory)
```

4）优化后，使用Firefox浏览器访问图片，再次查看缓存信息

```
[root@client ~]# firefox http://192.168.4.5/day.jpg
```

在firefox地址栏内输入about:cache，查看本地缓存数据，查看是否有图片以及过期时间是否正确。