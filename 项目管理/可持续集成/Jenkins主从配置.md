# 一、Jenkins主从配置

​	Jenkins安装在一台主机上，所有的jobs都在这台机器上运行，如果运行太多jobs时，会形成等待，节点存在就是解决这个问题提高效率，安装jenkins的主机称为master机，而其它机器就属于master的分节点，即slave节点；利用其它主机用执行jenkins的jobs，则需要一些配置，形成两台机器互通。

![在这里插入图片描述](https://img-blog.csdnimg.cn/20200715174907250.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2h0OTk5OWk=,size_16,color_FFFFFF,t_70)