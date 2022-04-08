- [JVM垃圾回收机制（建议收藏） (qq.com)](https://mp.weixin.qq.com/s/iLqfDj3PsnHX0xcVlFfmwg)

结合《[JVM内存空间](http://mp.weixin.qq.com/s?__biz=MzAwMTk4NjM1MA==&mid=2247503566&idx=1&sn=d3ff586cee8d1bd1206a31592f01ca74&chksm=9ad3d48fada45d9923c92751ac9067cab18718b90b6f69ff01be59c247a7f672119ae80e11c6&scene=21#wechat_redirect)》、《[JVM堆内存分配机制](http://mp.weixin.qq.com/s?__biz=MzAwMTk4NjM1MA==&mid=2247504098&idx=1&sn=14f9bcc827bd4d2369a2fa755420c5c3&chksm=9ad3caa3ada443b5ff0ad33e612cac02a9e1c9ed19be3096ea3681c8075ddcd201d29444156b&scene=21#wechat_redirect)》，合并后图如下：

![图片](https://mmbiz.qpic.cn/mmbiz_png/PxMzT0Oibf4h3daFnDuMDiazJz0VISDONkFJdnicicxpyPIiamwRD3E9r6YgH4Cnpv8wJvl9QRBhxwNqiaPyuD1uicMdg/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

当我们调用一个方法的时候，就会创建这个方法的栈帧，当方法调用结束的时候，这个栈帧出栈，栈帧所占用的内存也随之释放。

如果这个线程销毁了，那与这个线程相关的栈以及程序计数器的内存也随之被回收，那在堆内存中创建的对象怎么办？这些对象可是都占着很多的内存资源的。因此我们需要知道哪些对象是可以回收的，哪些对象是不能回收的。

## 可达性分析算法

可达性算法就是从GC Roots出发，去搜索他引用的对象，然后根据这个引用的对象，继续查找他引用的对象。

如果一个对象到GC Roots没有任何引用链相连，说明他是不可用的，这个类就可以回收，比如下图的object5、object6、object7。

![图片](https://mmbiz.qpic.cn/mmbiz_png/PxMzT0Oibf4h3daFnDuMDiazJz0VISDONkO1ibeA9WJTxGAlDMnJhODDElI9VmKlSXibR2UNqvOthydH9UsU9EMGeA/640?wx_fmt=png&wxfrom=5&wx_lazy=1&wx_co=1)

我们回忆一下合并图：

1. 类加载到方法区的时候，初始化阶段会为静态变量赋值，他所引用的对象可以做GC Roots。
2. 同样的，方法区的常量引用的对象可以做GC Roots。
3. 调用方法的时候，会创建方法的栈帧，栈帧里的局部变量引用的对象，可以做GC Roots。
4. 同样的，本地方法栈中栈帧里的局部变量引用的对象，可以做GC Roots。

可达性算法除了GC Roots，还有一个引用，引用分以下几种：

1. 强引用(Strong Reference)：只要强引用还存在，垃圾收集器永远不会回收被引用的对象。
2. 软引用(Soft Reference)：在系统将要发生内存溢出异常之前,将会把这些对象列进回收范围之中进行第二次回收。如果这次回收还没有足够的内存,才会拋出内存溢出异常。
3. 弱引用(Weak Reference )：被弱引用关联的对象只能生存到下一次垃圾收集发生之前。当垃圾收集器工作时,无论当前内存是否足够, 都会回收掉只被弱引用关联的对象。
4. 虚引用(Phantom Reference)：一个对象是否有虚引用的存在,完全不会对其生存时间构成影响,也无法通过虚引用来取得一个对象实例。为一个对象设置虚引用关联的唯一目的就是能在这个对象被收集器回收时收到一个系统通知。