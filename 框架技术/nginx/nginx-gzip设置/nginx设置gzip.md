# Nginx-gzip介绍

直接gzip on：在nginx的配置中就可以开启gzip压缩

### 1、nginx中开启gzip实例？

```yaml
server{
    gzip on;
    gzip_buffers 32 4K;
    gzip_comp_level 6;
    gzip_min_length 100;
    gzip_types application/javascript text/css text/xml;
    gzip_disable "MSIE [1-6]\."; #配置禁用gzip条件，支持正则。此处表示ie6及以下不启用gzip（因为ie低版本不支持）
    gzip_vary on;
}
```

##### 直接gzip on：在nginx的配置中就可以开启gzip压缩

 

### 2、什么样的资源不适合开启gzip压缩？

##### 二进制资源：例如图片/mp3这样的二进制文件,不必压缩；因为压缩率比较小, 比如100->80字节,而且压缩也是耗费CPU资源的.

 



### 3、nginx中gzip模块需要额外安装么（看清楚模块名）？

##### 不需要：ngx_http_gzip_module是Nginx默认集成的，不需要重新编译，直接开启即可

 



### 4、如何解决：公司的静态资源服务器全部使用的Nginx，且都开启了gzip压缩。内部测试是完全正常的，然而一到外网，居然没有做gzip！ ？

##### 原因：做负载均衡的机器上面没开gzip：在应用服务器前，公司还有一层Nginx的集群作为七层负责均衡，在这一层上，是没有开启gzip的。

##### 还需要设置gzip_http_version为1.0：nginx和后端的upstream server之间默认是用HTTP/1.0协议通信的

在应用服务器前，公司还有一层Nginx的集群作为七层负责均衡，在这一层上，是没有开启gzip的。
如果我们使用了proxy_pass进行反向代理，那么nginx和后端的upstream server之间默认是用HTTP/1.0协议通信的。
如果我们的Cache Server也是nginx，而前端的nginx没有开启gzip。
同时，我们后端的nginx上没有设置gzip_http_version为1.0，那么Cache的url将不会进行gzip压缩。

 

# 2、Nginx优化之gzip压缩提升网站速度

gzip配置的常用参数

gzip on|off; #是否开启gzip

gzip_buffers 32 4K| 16 8K #缓冲(压缩在内存中缓冲几块? 每块多大?)

gzip_comp_level [1-9] #推荐6 压缩级别(级别越高,压的越小,越浪费CPU计算资源)

gzip_disable #正则匹配UA 什么样的Uri不进行gzip

gzip_min_length 200 # 开始压缩的最小长度(再小就不要压缩了,意义不在)

gzip_http_version 1.0|1.1 # 开始压缩的http协议版本(可以不设置,目前几乎全是1.1协议)

gzip_proxied # 设置请求者代理服务器,该如何缓存内容

gzip_types text/plain application/xml # 对哪些类型的文件用压缩 如txt,xml,html ,css

gzip_vary on|off # 是否传输gzip压缩标志

注意：

图片/mp3这样的二进制文件,不必压缩

因为压缩率比较小, 比如100->80字节,而且压缩也是耗费CPU资源的.

比较小的文件不必压缩,

以下是配置：

在nginx.conf中加入

```php
	gzip on;
	gzip_buffers 32 4K;
	gzip_comp_level 6;
        gzip_min_length 100;
	gzip_types application/javascript text/css text/xml;
        gzip_disable "MSIE [1-6]\."; #配置禁用gzip条件，支持正则。此处表示ie6及以下不启用gzip（因为ie低版本不支持）
        gzip_vary on;
```

![img](https://img-blog.csdn.net/20180628153147783?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3BocDEyMzQ1Njc5/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

保存并重启nginx，刷新页面（为了避免缓存，请强制刷新）就能看到效果了。以谷歌浏览器为例，通过F12看请求的响应头部，如下图：

![img](https://img-blog.csdn.net/20180628153347564?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3BocDEyMzQ1Njc5/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

Content-Encoding:gzip 说明开启了gzip压缩

Transfet-Encoding:chunked 说明压缩后分块传输

![img](https://img-blog.csdn.net/20180628153835630?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3BocDEyMzQ1Njc5/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

![img](https://img-blog.csdn.net/2018062815411861?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3BocDEyMzQ1Njc5/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

 

在此我们看出这个js的传输大小68.3k，而这个js实际大小为282k 所以压缩生效成功

# 3、Nginx开启Gzip详解

## 3.1 Nginx开启Gzip

Nginx实现资源压缩的原理是通过ngx_http_gzip_module模块拦截请求，并对需要做gzip的类型做gzip，ngx_http_gzip_module是Nginx默认集成的，**不需要重新编译，直接开启即可**。

### **1.1 配置说明**

Nginx开启Gzip的配置如下：

```
# $gzip_ratio计算请求的压缩率，$body_bytes_sent请求体大小
    log_format  main  '$remote_addr - $remote_user [$time_local] "$host" - "$request" '
                    '$gzip_ratio - $body_bytes_sent - $request_time';


    access_log  logs/access.log  main;

    # 开启gzip
    gzip off;

    # 启用gzip压缩的最小文件，小于设置值的文件将不会压缩
    gzip_min_length 1k;

    # gzip 压缩级别，1-9，数字越大压缩的越好，也越占用CPU时间，后面会有详细说明
    gzip_comp_level 1;

    # 进行压缩的文件类型。javascript有多种形式。其中的值可以在 mime.types 文件中找到。
    gzip_types text/plain application/javascript application/x-javascript text/css application/xml text/javascript application/x-httpd-php image/jpeg image/gif image/png application/vnd.ms-fontobject font/ttf font/opentype font/x-woff image/svg+xml;

    # 是否在http header中添加Vary: Accept-Encoding，建议开启
    gzip_vary on;

    # 禁用IE 6 gzip
    gzip_disable "MSIE [1-6]\.";

    # 设置压缩所需要的缓冲区大小     
    gzip_buffers 32 4k;

    # 设置gzip压缩针对的HTTP协议版本
    gzip_http_version 1.0;
```

 

下面将逐条介绍下gzip的指令和参数配置。

[回到顶部](https://www.cnblogs.com/Renyi-Fan/p/11047490.html#_labelTop)

### **1.2 参数详解**



#### **gzip on**

这个没的说，打开或关闭gzip

```
Syntax: gzip on | off;
Default:    
gzip off;
Context:    http, server, location, if in location
```

 



#### **gzip_buffers**

设置用于处理请求压缩的缓冲区数量和大小。比如32 4K表示按照内存页（one memory page）大小以4K为单位（即一个系统中内存页为4K），申请32倍的内存空间。建议此项不设置，使用默认值。

```
Syntax: gzip_buffers number size;
Default:    
gzip_buffers 32 4k|16 8k;
Context:    http, server, location
```

 



#### **gzip_comp_level**

设置gzip压缩级别，级别越底压缩速度越快文件压缩比越小，反之速度越慢文件压缩比越大

```
Syntax: gzip_comp_level level;
Default:    
gzip_comp_level 1;
Context:    http, server, location
```

 

我们以一个大小为92.6K的脚本文件为例，如下所示。其中最后三个数值分别表示压缩比、包大小、平均处理时间（使用ab压测，100用户并发下， `./ab -n 10000 -c 100 -H 'Accept-Encoding: gzip' http://10.27.180.75/jquery.js` ）以及CPU消耗。

从这我们可以得出结论：

1. 随着压缩级别的升高，压缩比有所提高，但到了级别6后，很难再提高；
2. 随着压缩级别的升高，处理时间明显变慢；
3. gzip很消耗cpu的性能，高并发情况下cpu达到100%

因此，建议：
**一方面，不是压缩级别越高越好，其实gzip_comp_level 1的压缩能力已经够用了，后面级别越高，压缩的比例其实增长不大，反而很吃处理性能。**
**另一方面，压缩一定要和静态资源缓存相结合，缓存压缩后的版本，否则每次都压缩高负载下服务器肯定吃不住。**

```js
http://10.27.180.75/jquery.js 
gzip_comp_level 0: 0，94840, 63 [ms], 29%
gzip_comp_level 1: 2.43，39005, 248 [ms], 100%
gzip_comp_level 2: 2.51，37743, 273 [ms], 100%
gzip_comp_level 3; 2.57，36849, 327 [ms], 100%
gzip_comp_level 4; 2.73，34807, 370 [ms], 100%
gzip_comp_level 5; 2.80，33898, 491 [ms], 100%
gzip_comp_level 6; 2.82，33686, 604 [ms], 100%
gzip_comp_level 7; 2.82，33626, 659 [ms], 100%
gzip_comp_level 8; 2.82，33626, 698 [ms], 100%
gzip_comp_level 9; 2.82，33626, 698 [ms], 100%
```

 



#### **gzip_disable**

通过表达式，表明哪些UA头不使用gzip压缩

```
Syntax: gzip_disable regex ...;
Default:    —
Context:    http, server, location
This directive appeared in version 0.6.23.
```

 



#### **gzip_min_length**

当返回内容大于此值时才会使用gzip进行压缩,以K为单位,当值为0时，所有页面都进行压缩。

```
Syntax: gzip_min_length length;
Default:    
gzip_min_length 20;
Context:    http, server, location
```

 



#### **gzip_http_version**

用于识别http协议的版本，早期的浏览器不支持gzip压缩，用户会看到乱码，所以为了支持前期版本加了此选项。默认在http/1.0的协议下不开启gzip压缩。

```
Syntax: gzip_http_version 1.0 | 1.1;
Default:    
gzip_http_version 1.1;
Context:    http, server, location
```

 

我看网上的很多文章中，对这一点都觉得过时了，因为浏览器基本上都支持HTTP/1.1。然而这里面却存在着一个很容易掉入的坑，也是笔者从生产环境中一个诡异问题中发现的：
问题背景：
笔者所在公司的静态资源服务器全部使用的Nginx，且都开启了gzip压缩。内部测试是完全正常的，然而一到外网，居然没有做gzip！
![这里写图片描述](https://img-blog.csdn.net/20160930172649456)
原因定位：
为什么这样呢？
在应用服务器前，公司还有一层Nginx的集群作为七层负责均衡，在这一层上，是没有开启gzip的。
**如果我们使用了proxy_pass进行反向代理，那么nginx和后端的upstream server之间默认是用HTTP/1.0协议通信的。**
**如果我们的Cache Server也是nginx，而前端的nginx没有开启gzip。**
**同时，我们后端的nginx上没有设置gzip_http_version为1.0，那么Cache的url将不会进行gzip压缩。**
![这里写图片描述](https://img-blog.csdn.net/20160930172200876)
我相信，以后还有人会入坑，比如你用Apache ab做压测，如果不是设置gzip_http_version为1.0，你也压不出gzip的效果（同样的道理）。希望写在这里对大家有帮助



#### **gzip_proxied**

Nginx做为反向代理的时候启用：

- off – 关闭所有的代理结果数据压缩
- expired – 如果header中包含”Expires”头信息，启用压缩
- no-cache – 如果header中包含”Cache-Control:no-cache”头信息，启用压缩
- no-store – 如果header中包含”Cache-Control:no-store”头信息，启用压缩
- private – 如果header中包含”Cache-Control:private”头信息，启用压缩
- no_last_modified – 启用压缩，如果header中包含”Last_Modified”头信息，启用压缩
- no_etag – 启用压缩，如果header中包含“ETag”头信息，启用压缩
- auth – 启用压缩，如果header中包含“Authorization”头信息，启用压缩
- any – 无条件压缩所有结果数据

```
Syntax: gzip_proxied off | expired | no-cache | no-store | private | no_last_modified | no_etag | auth | any ...;
Default:    
gzip_proxied off;
Context:    http, server, location
```

 



#### **gzip_types**

设置需要压缩的MIME类型,如果不在设置类型范围内的请求不进行压缩

```
Syntax: gzip_types mime-type ...;
Default:    
gzip_types text/html;
Context:    http, server, location
```

 

这里需要说明一些特殊的类型，比如笔者公司会使用”字体类型”的资源，而这些资源类型往往会被忽略，且这些资源又比较大，没有被压缩很不合算。（可以参考：http://www.darrenfang.com/2015/01/setting-up-http-cache-and-gzip-with-nginx/）：
![这里写图片描述](https://img-blog.csdn.net/20160930173059428)
所以MIME-TYPE中应该新增字体类型：

| 字体类型扩展名 | Content-type                  |
| -------------- | ----------------------------- |
| .eot           | application/vnd.ms-fontobject |
| .ttf           | font/ttf                      |
| .otf           | font/opentype                 |
| .woff          | font/x-woff                   |
| .svg           | image/svg+xml                 |



#### **gzip_vary**

增加响应头”Vary: Accept-Encoding”

```
Syntax: gzip_vary on | off;
Default:    
gzip_vary off;
Context:    http, server, location
```