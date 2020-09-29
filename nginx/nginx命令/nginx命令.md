```bash
./configure --prefix=/usr/local/nginx --add-module=/usr/local/nginx/module/nginx-rtmp-module --conf-path=/usr/local/nginx/nginx.conf

./configure --prefix=/usr/local/nginx --add-module=/opt/nginx-rtmp-module --conf-path=/usr/local/nginx/sbin/nginx.conf

./configure --add-module=/opt/nginx-rtmp-module
```



# nginx的安装路径：

/usr/local/nginx
# 启动nginx
/usr/local/nginx/sbin/nginx 
# nginx重启
/usr/local/nginx/sbin/nginx -s reload
# -c 指定nginx的配置文件：
/usr/local/nginx/sbin/nginx -c /usr/local/nginx/conf/nginx.conf