# [Linux下如何查看哪些进程占用的CPU内存资源最多](https://www.cnblogs.com/sparkbj/p/6148817.html)

linux下获取占用CPU资源最多的10个进程，可以使用如下命令组合：

ps aux|head -1;ps aux|grep -v PID|sort -rn -k +3|head



linux下获取占用内存资源最多的10个进程，可以使用如下命令组合：

ps aux|head -1;ps aux|grep -v PID|sort -rn -k +4|head

  

命令组合解析（针对CPU的，MEN也同样道理）：

ps aux|head -1;ps aux|grep -v PID|sort -rn -k +3|head



该命令组合实际上是下面两句命令：

ps aux|head -1

ps aux|grep -v PID|sort -rn -k +3|head

 

 

可以使用一下命令查使用内存最多的10个进程

**查看占用cpu最高的进程**

[ps](http://www.111cn.net/fw/photo.html) aux|head -1;ps aux|grep -v PID|sort -rn -k +3|head

或者top （然后按下M，注意这里是大写）

**查看占用内存最高的进程**

ps aux|head -1;ps aux|grep -v PID|sort -rn -k +4|head

或者top （然后按下P，注意这里是大写）

**该命令组合实际上是下面两句命令：**

ps aux|head -1
ps aux|grep -v PID|sort -rn -k +3|head

其中第一句主要是为了获取标题（USER PID %CPU %MEM VSZ RSS TTY STAT START TIME COMMAND）。
接下来的grep -v PID是将ps aux命令得到的标题去掉，即grep不包含PID这三个字母组合的行，再将其中结果使用sort排序。
sort -rn -k +3该命令中的-rn的r表示是结果倒序排列，n为以数值大小排序，而-k +3则是针对第3列的内容进行排序，再使用head命令获取默认前10行数据。(其中的|表示管道操作)

**补充:内容解释**

PID：进程的ID
USER：进程所有者
PR：进程的优先级别，越小越优先被执行
NInice：值
VIRT：进程占用的虚拟内存
RES：进程占用的物理内存
SHR：进程使用的共享内存
S：进程的状态。S表示休眠，R表示正在运行，Z表示僵死状态，N表示该进程优先值为负数
%CPU：进程占用CPU的使用率
%MEM：进程使用的物理内存和总内存的百分比
TIME+：该进程启动后占用的总的CPU时间，即占用CPU使用时间的累加值。
COMMAND：进程启动命令名称

 

 

 

、可以使用以下命令查使用内存最多的K个进程

方法1：

```
ps -aux | sort -k4nr | head -K
```

如果是10个进程，K=10，如果是最高的三个，K=3

**说明：**ps -aux中（a指代all——所有的进程，u指代userid——执行该进程的用户id，x指代显示所有程序，不以终端机来区分）

​    ps -aux的输出格式如下：

```
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.0  0.0  19352  1308 ?        Ss   Jul29   0:00 /sbin/init
root         2  0.0  0.0      0     0 ?        S    Jul29   0:00 [kthreadd]
root         3  0.0  0.0      0     0 ?        S    Jul29   0:11 [migration/0]
```

   sort -k4nr中（k代表从第几个位置开始，后面的数字4即是其开始位置，结束位置如果没有，则默认到最后；n指代numberic sort，根据其数值排序；r指代reverse，这里是指反向比较结果，输出时默认从小到大，反向后从大到小。）。本例中，可以看到%MEM在第4个位置，根据%MEM的数值进行由大到小的排序。

   head -K（K指代行数，即输出前几位的结果）

   |为管道符号，将查询出的结果导到下面的命令中进行下一步的操作。

方法2：top （然后按下M，注意大写）

二、可以使用下面命令查使用CPU最多的K个进程

方法1：

```
ps -aux | sort -k3nr | head -K
```

方法2：top （然后按下P，注意大写