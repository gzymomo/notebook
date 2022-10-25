- [CDH大数据平台搭建之集群规划_码上_成功的博客-CSDN博客_cdh集群规划](https://blog.csdn.net/qq_41924766/article/details/117561341)

# 前言

搭建CDH大数据平台之前需要的工作很多，首先，你需要计算公司每日的数据量，来确定需要多少服务器，确定好服务器之后，需要规划集群节点的分配。由于是个人搭建，不存在数据量计算，只做集群规划即可。

# 一、集群规模

```
每日数据量的多少，决定了服务器的数量
计算规则如下：
1、hdfs数据保存3份
2、一般文件保存3年
3、每台服务器硬盘大小8T，但会留20%左右的空闲空间
所需服务器数量 = 公司每日数据量(TB) * 3 * 365 * 3 / (8 * 0.8) 
```

# 二、集群规划

![在这里插入图片描述](https://img-blog.csdnimg.cn/20210616112317913.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzQxOTI0NzY2,size_16,color_FFFFFF,t_70#pic_center)

# 总结

集群规划主要是安装软件的时候，对应的节点好分配，所以提前规划是有必要的。