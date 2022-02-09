- [shell脚本检查域名证书是否过期](https://www.cnblogs.com/kanlon2015/p/15864879.html)

最近公司的域名准备过期了，防止用户访问的时候出现异常，所以最近我们准备替换相关网站证书为最新的。
 （一般HTTPS证书有效期为1年，证书过期后或者该证书不是该域名的有效证书时，在浏览器中访问会出现如下提示，这时候如果还是要访问只能通过点击"高级"，忽略风险继续访问）
 ![域名过期的](https://img-blog.csdnimg.cn/3958a0b91a554226bb8b85ba3e3986e8.png)

我们这里有些域名是直接解析到自己的业务机器上的，并没有经过运维管理的nginx再来做转发，所以针对这部分域名，就需要的单独到业务机器上下载最新的域名证书，然后替换了一下证书，并重启一下nginx (`nginx -s reload`) 。

> 这里替换证书的时候，我遇到了一个坑，就是之前有些域名并不支持https的，然后我就打算换成支持https。结果按照原来的方式配置了https，访问的时候报不安全，提示使用了旧版tsl1.0或tsl1.1的协议，我确保了该域名的协议方式已经修改了，但是浏览器访问的时候，还是提示不安全，网上找了一段时间，才知道要nginx所有的域名配置都修改了，才会生效的，不然nginx 有可能取某个 域名配置的ssl 配置来连接ssl，但是最新的域名下的ssl配置不生效。
>  按F12打开开发者模式，切到 “Security”  tab下页面可以看到不安全的原因，如果是使用了旧版tsl1.0或tsl1.1的协议，则在“Connection”中显示使用了TSL1.0或者TSL1.1的协议。下图的例子是表示无法信任服务器，因为未提供有效的证书。
>  ![控制台Security页面信息](https://img-blog.csdnimg.cn/5bcdc73e65f04c1e9258ae924001803e.png)

理论上所有域名都统一由运维部门来管理，直接解析到运维的nginx 再转发到自己的业务机器才是比较好的方案，不然会导致域名不好管理。但是很多历史域名还没时间去修改，就只能手动替换。

这个域名数量会有点多，而且也不知道还有哪些域名还没替换的，因此计划用shell脚本去检查，并且可以将该shell脚本设置为定时任务，每个月或每天定时检查一下，如果有域名要过期了，则告警出来。在网上找了一下相关资料，再根据自己的需求，改造了一版的shell脚本如下：

```shell
#!/bin/bash
# 检测https证书有效
echo '开始检查 https证书有效期 '

# 先写域名内容到文件中，再读取文件检查证书是否过期了
# 先清空文件
echo '' > /tmp/https_list.txt 

# 这里替换为自己的检查的域名即可
echo 'www.baidu.com' >> /tmp/https_list.txt
echo 'www.bing.com' >> /tmp/https_list.txt
echo 'www.google.com' >> /tmp/https_list.txt

source /etc/profile

# 定义错误的域名
errorDominStr=""

while read line; do
    echo "====================================================================================="
    
    echo "当前检测的域名：" $line
    end_time=$(echo | timeout 1 openssl s_client -servername $line -connect $line:443 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | awk -F '=' '{print $2}' )
    ([ $? -ne 0 ] || [[ $end_time == '' ]]) && echo '该域名链接不上,跳到下一个域名' && continue
    
    end_times=`date -d "$end_time" +%s `
    current_times=`date -d "$(date -u '+%b %d %T %Y GMT') " +%s `
    
    let left_time=$end_times-$current_times
    days=`expr $left_time / 86400`
    echo "剩余天数: " $days
    
    [ $days -lt 60 ] && echo "https 证书有效期少于60天，存在风险"  && errorDominStr="$errorDominStr \n $line"
    
done < /tmp/https_list.txt

echo -e "准备过期的域名为： \n  $errorDominStr"

if [ "$errorDominStr" = "" ]  
then  
  echo "不包含准备过期的域名"  
else    
  echo "包含准备过期的域名" && exit 10  
fi   
echo "Good bye!"
exit 0
```

主要的流程就是读取文件中的域名，然后进行https访问获取到证书过期的时间，如果域名连接不上，则会直接跳过，如果该域名证书过期时间小于 60 天，则汇总起来，最后判断是否包含准备过期的域名，如果包含则异常退出`exit 10`。

运行后的结果如下：

![检查https证书是否准备过期的运行结果](https://img-blog.csdnimg.cn/3477af8cd0ed42f0afc5b6e721fb651e.png)

参考资料：

https://blog.51cto.com/lee90/2410670   shell脚本检测https证书有效期
 https://python.01314.cn/201812519.html  使用python检查SSL证书到期情况