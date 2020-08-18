CSDN：[平淡中的乐趣](https://blog.csdn.net/gghhm)：[windows pgsql 安装postgis](https://blog.csdn.net/gghhm/article/details/103661457)

CSDN：[Dawn_www](https://blog.csdn.net/sinat_36226553)：[PostgreSQL安装 Error running icacls](https://blog.csdn.net/sinat_36226553/article/details/100750378)

# PostgreSQL安装坑

经尝试，发现12版本安装一直出错Error running icacls，且没有发现好的解决方案，遂最终安装版本为11.2，可成功安装！



postgresql-11.2-1：https://get.enterprisedb.com/postgresql/postgresql-11.2-1-windows-x64.exe 

或百度云下载地址：

> 链接：https://pan.baidu.com/s/10OFa29URP8fTRgjC6kPljw 
> 提取码：laug 



之后安装很简单，一路next几乎即可完成。



# windows pgsql 安装postgis

首先去下面这个地址下载postgis安装包
[postgis安装地址](http://download.osgeo.org/postgis/windows/)



![在这里插入图片描述](https://img-blog.csdnimg.cn/20191223103724978.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2dnaGht,size_16,color_FFFFFF,t_70)
因为我是pg11，所以这里我选择最后一个 postgis-bundle-pg11x64-setup-3.0.0-3.exe





双击安装
安装的时候只改一个安装地址，安装地址选择你的postgresql目录，比如我的postgresql安装在D盘中就是： D:\PostgreSQL
![在这里插入图片描述](https://img-blog.csdnimg.cn/20191223104229508.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2dnaGht,size_16,color_FFFFFF,t_70)
安装最后有跳出三个弹窗全部选 是：

postgis would you like us to register the GDAL_DATA environment variable for you,needed for raster transformation to work properly? this will overwrite existing settings if you have them.

您希望我们为您注册GDAL_DATA环境变量，以便光栅转换正常工作吗？这将覆盖现有的设置，如果你有它们。选择“是”，用于光栅转换：
![在这里插入图片描述](https://img-blog.csdnimg.cn/20191223104353759.png)
Raster drivers are disabled by default. To change you need to set POSTGIS_GDAL_ENABLE_DRIVERS environment variable and will need to restart your PostgreSQL service for changes to take effect. Set POSTGIS_ENABLED_DRIVERS to common drivers GTiff, PNG, JPEG, XYZ, DTED, USGSDEM, AAIGrid?

默认情况下，光栅驱动器被禁用。要更改，需要设置POSTGIS_GDAL_ENABLE_DRIVERS环境变量，并且需要重新启动PostgreSQL服务以使更改生效。设置PasgsIsEnabLED驱动程序给普通驱动程序GTIFF、PNG、JPEG、XYZ、DTD、UGSDEM、AAIGrid？
![在这里插入图片描述](https://img-blog.csdnimg.cn/20191223104413383.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2dnaGht,size_16,color_FFFFFF,t_70)
Raster out of db is disabled by default. To enable POSTGIS_ENABLE_OUTDB_RASTERS environment variable needs to be set to 1. Enable out db rasters?

缺省情况下禁用DB光栅。要启用PasgsIsEnabLeOutBuxRasts环境变量，需要将其设置为1。启用DB光栅？
![在这里插入图片描述](https://img-blog.csdnimg.cn/20191223104422165.png)

# [windows开启PostgreSQL数据库远程访问](https://www.cnblogs.com/dhrs/p/11786059.html)

## **修改postgresql.conf文件**



1.在PostgreSQL安装目录下data文件夹，打开pg_hba.conf文件，新增允许访问的ip

![img](https://img2018.cnblogs.com/blog/1546506/201911/1546506-20191103135831302-959871215.png)

2.打开postgresql.conf，将listen_addresses = 'localhost' 改成 listen_addresses = '*'（改过请忽略）

3.重启服务



## **修改pg_hba.conf文件**

在data/pg_hba.conf中

\# TYPE DATABASE    USER      ADDRESS         METHOD 

\# IPv4 local connections:
host  all       all       127.0.0.1/32      md5
host  all       all       0.0.0.0/0         md5    

其中0.0.0.0/0表示运行任意ip地址访问。

若设置为 192.168.1.0/24 则表示允许来自ip为192.168.1.0 ~ 192.168.1.255之间的访问。

# [WINDOWS下重启POSTGRESQL](http://www.choupangxia.com/2020/06/23/windows-postgresql/)

在Windows下，postgresql以服务的形式启动，如果需要重启在服务中点击重启即可。

依次执行如下步骤：控制面板–》管理工具–》服务。然后在名称中找到“postgresql-xxx”，右击，在弹出框中选择“重新启动”即可。