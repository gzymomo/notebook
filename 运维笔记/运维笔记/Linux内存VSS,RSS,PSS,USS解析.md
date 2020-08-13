一般来说内存占用大小有如下规律：VSS >= RSS >= PSS >= USS

- VSS - Virtual Set Size 虚拟耗用内存（包含共享库占用的内存）
- RSS - Resident Set Size 实际使用物理内存（包含共享库占用的内存）
- PSS - Proportional Set Size 实际使用的物理内存（比例分配共享库占用的内存）
- USS - Unique Set Size 进程独自占用的物理内存（不包含共享库占用的内存）

![](http://img4.tbcdn.cn/L1/461/1/d3a92df3efa0df779418bed820e6dcd31f6cbbc6)

![](http://img4.tbcdn.cn/L1/461/1/d10c3c6e80e70309ce73bfa874d92d56606fa989)

![](http://img1.tbcdn.cn/L1/461/1/ee8a35925f0aafb160c58b18eb4aee3bf4762398)

![](http://img2.tbcdn.cn/L1/461/1/255c513123c88d85d5e1137be66d0672368b8931)