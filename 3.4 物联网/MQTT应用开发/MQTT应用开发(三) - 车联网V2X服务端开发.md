- [MQTT应用开发(三) - 车联网V2X服务端开发_gzroy的博客-CSDN博客_mqtt 车联网](https://blog.csdn.net/gzroy/article/details/104054507)

在前面的两篇博客中，我们已经完成了MQTT服务器的搭建，以及MQTT客户端的开发，客户端模拟了2辆车定时上报CAM消息，并且其中一辆车随机生成DENM消息，汇报紧急刹车的事件。在V2X的应用场景中，我们需要把DENM消息转发给一定范围内的其他车辆。车辆可以通过DSRC接口或者LTE-V2X的PC5接口直接发送DENM，也可以通过服务端转发。在这里我将采用服务端转发的方式，在服务端接收DENM消息，生成一个电子围栏(GeoFence)，并通知在电子围栏内的其他车辆。

因为需要对车辆上报的地理位置进行计算，以及生成地理电子围栏，我采用Google的S2 Geometry库来进行处理。在Github中下载S2的源代码，https://github.com/google/s2geometry，然后按照官网的介绍进行编译和安装。注意如果用Python来调用接口的话，需要安装swig，apt-get install swig。安装之后，会在/usr/local/lib目录下安装一个libs2.so的文件，以及在python的site-packages里面生成pywraps2.py以及_pywraps2.so这2个文件。需要注意的是，在Ubuntu环境，需要把libs2.so拷贝到/usr/lib目录下，不然调用的时候会报错。安装完成后在Python里面就可以import pywraps2 as s2来进行调用了，可以通过help(s2)来查看这个库所提供的方法，也可以查看这个网页http://s2geometry.io/devguide/basic_types

具体的流程如下：

1. 每次接收到车辆的CAM信息上报，根据经纬度计算对应的level 30的Cell ID，存储车辆VIN号与Cell ID的关于在Redis中（通过zadd的sorted list保存，每个元素的name是车辆的VIN，score是CellID），同时创建一个对应于车辆位置的S2Point实例，保存在本地缓存中。
2. 每次接收到车辆的DENM消息，根据里面的位置信息为圆心，创建一个半径为200米的圆形电子围栏S2Cap实例。计算这个围栏覆盖了多少个S2 level 12的Cell，把围栏的ID和Cell ID的对应关系存储在Redis中（用sadd命令保存为set），并保存围栏ID和S2Cap实例在本地缓存中。计算围栏的Level 12 Cell ID的起止范围，通过Redis的zrangebyscore来查找在这个起止范围内的所有车辆（计算车辆的Level 30的Cell ID是否落在这个范围中），对于满足查询条件的车辆，取出在本地缓存中保存的S2Point实例，用电子围栏的S2Cap的Contains函数来判断是否包含这个S2Point，如果包含，判断这个车辆是否新进入这个电子围栏，如是则转发DENM信息。
3. 当车辆上报CAM消息时，还需要计算车辆的Level30的Cell ID的Parent level 12的Cell ID，根据这个Level 12ID查询是否有对应的电子围栏，如果有则判断车辆是否在电子围栏范围中或者离开电子围栏（通过S2Cap Contains来判断）
4. 系统需要自动根据DENM消息的有效期来清除过期的电子围栏。

具体的实现逻辑和代码可以参见我在Gitee上的代码库，https://gitee.com/gzroy2000/IoT_V2X/tree/master/