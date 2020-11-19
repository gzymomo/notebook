在gitlab上配置jenkins的webhook，当有代码变更时自动触发jenkins构建job，job内的shell脚本负责把覆盖率报告以钉钉群通知的方法发送出去。

![img](https://img2020.cnblogs.com/blog/907091/202007/907091-20200701223555441-513722191.png)

### **三、Jenkins job配置**

**![img](https://img2020.cnblogs.com/blog/907091/202007/907091-20200701223624718-1428314014.png)**

点击上图中的“高级”，出现下图后，点击“Generate”，生成Secret token。

![img](https://img2020.cnblogs.com/blog/907091/202007/907091-20200701223720422-645966943.png)

### **四、Gitlab配置webhook**

![img](https://img2020.cnblogs.com/blog/907091/202007/907091-20200701223745917-1335362327.png)