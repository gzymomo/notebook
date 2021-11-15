- [Kafka常用监控框架百科全书](https://mp.weixin.qq.com/s/6URS-Qrid9YgveOD470mkA)

Kafka搭建好投入使用后，为了运维更便捷，借助一些管理工具很有必要。Kafka社区似乎一直没有在监控框架方面投入太多的精力，目前Kafka监控方案看似很多，然而并没有一个"大而全"的通用解决方案，各家框架也是各有千秋。很多公司和个人都自行着手开发 Kafka 监控框架，其中并不乏佼佼者。今天我们就来全面地梳理一下主流的监控框架。

## JMX

JMX的全称为Java Management Extensions. 顾名思义，是管理Java的一种扩展。这种机制可以方便的管理、监控正在运行中的Java程序。常用于管理线程，内存，日志Level，服务重启，系统环境等。

关于JMX的使用，读者可以参考厮大这篇文章：

- 《如何使用JMX监控Kafka》https://blog.csdn.net/u013256816/article/details/53524884

总体来说，JMXTool 是社区自带的一个小工具，对于一般简单的监控场景，它还能应付，但是它毕竟功能有限，复杂的监控整体解决方案，还是要依靠监控框架。

## Kafka Manager(已更名为CMAK)

为了简化开发者和服务工程师维护Kafka集群的工作，Yahoo构建了一个叫做Kafka管理器的基于Web工具，叫做 Kafka  Manager。这个管理工具可以很容易地发现分布在集群中的哪些topic分布不均匀，或者是分区在整个集群分布不均匀的的情况。它支持管理多个集群、选择副本、副本重新分配以及创建Topic。

你可以很轻松的安装他：

```
# 从git上下载Kafka manager源码
git clone https://github.com/yahoo/kafka-manager

# 使用sbt进行编译，编译过程中需要等待很长时间
./stb clean dist
```

你可以在 Kafka Manager 的 target/universal 目录下找到生成的 zip 文件，把它解压，然后修改里面的  conf/application.conf 文件中的 kafka-manager.zkhosts 项，让它指向你环境中的 ZooKeeper  地址，比如：

```
# 默认是localhost，将zkhosts改为自己zk集群的hosts
kafka-manager.zkhosts="localho:2181"
```

然后启动Zookeeper和Kafka：

```
# 启动zookeeper
zkServer start

# 启动kafka，JMX_PORT=9991指定Kafka的JMX端口为9991，方便对kafka监控
JMX_PORT=9991 kafka-server-start -daemon /usr/local/etc/kafka/server.properties
```

之后，运行以下命令启动 Kafka Manager：

```
# 进入/kafka-manager/bin
cd ../kafka-manager/bin

# 执行kafka-manager命令
sh kafka-manager
```

然后我们就可以新建Cluster，点击【Cluster】>【Add Cluster】打开如下添加集群的配置界面：

输入集群的名字（如Kafka-Cluster-1）和 Zookeeper 服务器地址（如localhost:2181），选择最接近的Kafka版本。

![图片](https://mmbiz.qpic.cn/mmbiz_png/UdK9ByfMT2PPnVN95dLeibDBmQd54N1PThtibT2ib2XsUG33tCicKae308By1Ccq0ZD0eibbtdNXhKt1BicVqAlra79A/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

然后你就可以看到当前监控的 Kafka 集群的主题数量、Broker 数量等信息。

![图片](https://mmbiz.qpic.cn/mmbiz_png/UdK9ByfMT2PPnVN95dLeibDBmQd54N1PT1Cnure8Exf3JpaeGXRPVLFcK0loyTvtqqcl5hibpCK5QFHCxH15Uoog/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

一个完整的过程你可以参考：

- 《Kafka集群管理工具kafka-manager部署安装》https://blog.csdn.net/qq_43631716/article/details/120109732

## Kafka Eagle

Kafka Eagle监控系统也是一款用来监控Kafka集群的工具，支持管理多个Kafka集群、管理Kafka主题（包含查看、删除、创建等）、消费者组合消费者实例监控、消息阻塞告警、Kafka集群健康状态查看等。

Kafka Eagle v1.2.3整个系统所包含的功能，如下图所示：

![图片](https://mmbiz.qpic.cn/mmbiz_png/UdK9ByfMT2PPnVN95dLeibDBmQd54N1PTrYWCrOANlCO51EID7ZeXc8aenxqebLdXnL2b8oRDgiaGJjnnUx2YAmA/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

1. 展示Kafka集群的Broker数、Topic数、Consumer数、以及Topic LogSize Top10和Topic Capacity Top10数据。
2. 主题创建、主题管理、主题预览、KSQL查询主题、主题数据写入、主题属性配置等
3. 监控不同消费者组中的Topic被消费的详情，例如LogSize、Offsets、以及Lag等。同时，支持查看Lag的历史趋势图。
4. Kafka集群和Zookeeper集群的详情展示，例如Kafka的IP和端口、版本号、启动时间、Zookeeper的Leader和Follower。同时，还支持多Kafka集群切换，以及Zookeeper Client数据查看等功能。
5. 监控Kafka集群和Zookeeper集群的核心指标，包含Kafka的消息发送趋势、消息大小接收与发送趋势、Zookeeper的连接数趋势等。同时，还支持查看Broker的瞬时指标数据。
6. 告警集群异常和消费者应用Lag异常。同时，支持多种IM告警方式，例如邮件、钉钉、微信、Webhook等。
7. 包含用户管理，例如创建用户、用户授权、资源管理等。
8. 展示消费者和生产者当日及最近7天趋势、Kafka集群读写速度、Kafka集群历史总记录等

Kafka Eagle监控管理系统，提供了一个可视化页面，使用者可以拥有不同的角色，例如管理员、开发者、游客等。不同的角色对应不同的使用权限。

你可以参考的网站：

```
源码：https://github.com/smartloli/kafka-eagle/
官网：https://www.kafka-eagle.org/
下载：http://download.kafka-eagle.org/
安装文档：https://docs.kafka-eagle.org/2.env-and-instal
```

你可以看到 Kafka Eagle 的管理界面如下：

![图片](https://mmbiz.qpic.cn/mmbiz_png/UdK9ByfMT2PPnVN95dLeibDBmQd54N1PTSokYYzZpqQW2NSPyZK5TfpufbhLo8kz15ADkcXByuADeSX96tjo7Lw/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

- 《Kafka监控工具Kafka Eagle》https://blog.csdn.net/weixin_45367149/article/details/108398580

## Logi-KafkaManager

滴滴Logi-KafkaManager脱胎于滴滴内部多年的Kafka运营实践经验，是面向Kafka用户、Kafka运维人员打造的共享多租户Kafka云平台。专注于Kafka运维管控、监控告警、资源治理等核心场景，经历过大规模集群、海量大数据的考验。内部满意度高达90%的同时，还与多家知名企业达成商业化合作。

![图片](https://mmbiz.qpic.cn/mmbiz_png/UdK9ByfMT2PPnVN95dLeibDBmQd54N1PTp7nn3wWjeuxO5Qkicha2R4E23CE9cHEib7D6UUT3yWicwM1bFRiaiaYVJ1w/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

功能上，和 Kafka Manager的对比如下：

![图片](https://mmbiz.qpic.cn/mmbiz_png/UdK9ByfMT2PPnVN95dLeibDBmQd54N1PTy5d2u6JGWKwhuHxh4aed03vf0nQtCfibniclwSSt1FqwicBLfNAefrMhw/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

你可以参考GitHub：https://github.com/didi/LogiKM

滴滴甚至提供了一个体验平台：

> 体验地址 http://117.51.150.133:8080 账号密码 admin/admin

## 总结

除了我们上面介绍的Kafka Manager、Kafka Eagle等，使用JMXTrans + InfluxDB + Grafana的组合也是很多公司的选择。可以方便的做到定制化。