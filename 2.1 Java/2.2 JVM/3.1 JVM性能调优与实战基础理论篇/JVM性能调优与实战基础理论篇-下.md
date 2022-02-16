- [JVM性能调优与实战基础理论篇-下](http://www.itxiaoshen.com/#/info?blogOid=69)

## 1 JVM内存管理

## 2 JVM内存分配与回收策略

- 对象优先在Eden分配，如果Eden内存空间不足，就会发生Minor GC。虚拟机提供了-XX：+PrintGCDetails这个收集器日志参数，告诉虚拟机在发生垃圾收集行为时打印内存回收日志，并且在进程退出的时候输出当前的内存各区域分配情况。

  - 新生代GC(Minor GC):指发生在新生代的垃圾收集动作，因为Java对象大多都具备朝生夕灭的特性，所以Minor GC非常频繁，一般回收速度也比较快。
  - 老年代GC(Major GC/Full GC):指发生在老年代的GC，出现了Major  GC，经常会伴随至少一次的Minor GC，(但非绝对的，在Parallel Scavenge收集器的手机策略里就有直接进行Major  GC的策略选择过程)。Major GC的速度一般会比Minor GC慢10倍以上。

  VM option 增加-XX:+PrintGCDetails，触发GC，打印出年轻代和年老代的内存信息
   ![image-20220213235445632](http://www.itxiaoshen.com:3001/assets/1644767692247Mh1QG2JN.png)

- 大对象直接进入老年代。虚拟机提供了一个 -XX:PretenureSizeThreshold 参数 ，大于这个数量直接在老年代分配，缺省为0 ，表示绝不会直接分配在老年代。

  - 大对象：需要大量连续内存空间的Java对象，比如很长的字符串和大型数组。大对象容易导致内存还有不少空间时，就提前触发垃圾收集以获取足够的连续空间来“安置”它们
  - 比遇到一个大对象更加坏的消息就是遇到一群“朝生夕灭”的“短命大对象”会进行大量的内存复制。VM option  增加-XX:+PrintGCDetails -XX:PretenureSizeThreshold=1000000  -XX:+UseSerialGC，触发大于1M的大对象直接进入老年代，设置这个参数可以避免为大对象分配内存时的复制操作而降低效率。

  ![image-20220214000303690](http://www.itxiaoshen.com:3001/assets/1644768187877Ea5TJsaK.png)

- 长期存活的对象将进入老年代。默认15岁，-XX:MaxTenuringThreshold 参数可调整。

- 动态对象年龄判定。为了能更好地适应不同程序的内存状况，虚拟机并不是永远地要求对象的年龄必须达到了MaxTenuringThreshold才能晋升老年代，如果在Survivor空间中相同年龄所有对象大小的总和大于Survivor空间的一半，年龄大于或等于该年龄的对象就可以直接进入老年代，无须等到MaxTenuringThreshold中要求的年龄。

- 空间分配担保。新生代中有大量的对象存活，survivor空间不够，当出现大量对象在MinorGC后仍然存活的情况（最极端的情况就是内存回收后新生代中所有对象都存活），就需要老年代进行分配担保，把Survivor无法容纳的对象直接进入老年代.只要老年代的连续空间大于新生代对象的总大小或者历次晋升的平均大小，就进行Minor GC，否则FullGC。所以，新生代一般不会内存溢出，因为有老年代做担保。

![image-20220214001909047](http://www.itxiaoshen.com:3001/assets/1644769154122Jt7hf2B8.png)

## 3 判断对象是否可以回收

### 3.1 引用计数法

引用计数法：即给对象添加一个引用计数器，每当有一个地方引用它时，计数器值就加1；当引用失效时，计数器值就减1。当计数器为0时，就认为该对象就是不可能再被使用的。

- 优点：快、方便、实现简单。
- 缺点：对象互相引用时很难判断对象是否该回收

### 3.2 可达性分析

可达性分析算法的基本思路就是通过一系列的称为“GC  Roots”的对象作为起始点，从这些节点开始向下搜索，搜索所走过的路径称为引用链（Reference Chain），当一个对象到GC  Roots没有任何引用链相连时，则证明此对象是不可用的。而作为GC Roots的对象包括下面几种：

- 虚拟机栈（栈帧中的本地变量表）中的对象。（方法中的参数，方法体中的局部变量）
- 方法区中 类静态属性的对象。 （static)
- 方法区中 常量的对象。 （final static）
- 本地方法栈中 JNI（即一般说的Native方法）的对象。

![image-20220214002136510](http://www.itxiaoshen.com:3001/assets/1644769299569JdXw6C5x.png)

![image-20220214003252607](http://www.itxiaoshen.com:3001/assets/164476997693766BA4cR3.png)

![image-20220214003312658](http://www.itxiaoshen.com:3001/assets/1644769995999pbMEPndE.png)

### 3.3 引用类型

无论是通过引用计数算法判断对象的引用数量，还是通过可达性分析算法判断对象的引用链是否可达，判断对象是否存活都与引用有关，那么就让我们再次来谈一谈引用。

- 强引用：就是指在程序代码中普遍存在的，类似于“Object obj = new Object() ”这类的就是强引用。只要强引用还存在，垃圾收集器永远不会回收掉被引用的对象。
- 软引用：是用来描述 \\*\*\*\*一些有用但是并非必需\*\*\*\*\ 的对象。用软引用关联的对象，系统将要发生OOM之前，这些对象就会被回收。

```
package cn.itxs.entity;

public class User {
    public int id = 0;
    public String name = "";
    public User(int id, String name) {
        this.id = id;
        this.name = name;
    }
    @Override
    public String toString() {
        return "User [id=" + id + ", name=" + name + "]";
    }
}

```

测试类，vm option 添加-Xms100m -Xmx100m -XX:+PrintGC，运行

```
package cn.itxs.garbage;

import cn.itxs.entity.User;

import java.lang.ref.SoftReference;
import java.util.LinkedList;
import java.util.List;

public class SoftReferenceMain {
    public static void main(String[] args) {
        User u = new User(100,"IT小神"); //new是强引用
        //软引用的使用示例：
        SoftReference<User> userSoft = new SoftReference<User>(u);
        u = null;//干掉强引用，确保这个实例只有userSoft的软引用
        //--- 如果是 SoftReference<User> userSoft = new SoftReference<User>(new User()); 就没法干掉强引用
        System.out.println(userSoft.get());
        System.gc();//进行一次GC垃圾回收
        System.out.println("After gc");
        System.out.println(userSoft.get());

        //往堆中填充数据，导致OOM
        List<byte[]> list = new LinkedList<>();
        try {
            for(int i=0;i<100;i++) {
                System.out.println("*************"+userSoft.get());
                list.add(new byte[1024*1024*50]); //1M的对象
            }
        } catch (Throwable e) {
            //抛出了OOM异常时打印软引用对象
            System.out.println("Exception*************"+userSoft.get());
        }
    }
}
```

![image-20220214004930814](http://www.itxiaoshen.com:3001/assets/16447709806045WaptC0N.png)

- 弱引用：一些有用（程度比软引用更低）但是并非必需，用弱引用关联的对象，只能生存到下一次垃圾回收之前，GC发生时，不管内存够不够，都会被回收。

```
package cn.itxs.garbage;

import cn.itxs.entity.User;

import java.lang.ref.WeakReference;

public class WeakReferenceMain {
    public static void main(String[] args) {
        User u = new User(1,"小爽");
        WeakReference<User> userWeak = new WeakReference<User>(u);
        u = null;//干掉强引用，确保这个实例只有userWeak的弱引用
        System.out.println(userWeak.get());
        System.gc();//进行一次GC垃圾回收
        System.out.println("After gc");
        System.out.println(userWeak.get());
    }
}
```

![image-20220214005347085](http://www.itxiaoshen.com:3001/assets/1644771234121ijBXc0A5.png)

- 虚引用：幽灵引用，最弱，被垃圾回收的时候收到一个通知。

软引用 SoftReference和弱引用 WeakReference，可以用在内存资源紧张的情况下以及创建不是很重要的数据缓存。当系统内存不足的时候，缓存中的内容是可以被释放的。实际运用如*\*WeakHashMap、ThreadLocal\

### 3.4 finalize()方法最终判定对象是否存活

即使在可达性分析算法中不可达的对象，也并非是“非死不可”的，这时候它们暂时处于“缓刑”阶段，要真正宣告一个对象死亡，至少要经历两次标记过程：

- 第一次标记：如果对象在进行可达性分析后发现没有与GC  Roots相连接的引用，那它将会被第一次标记并且进行一次筛选，筛选的条件是此对象是否有必要执行finalize()方法。当对象没有覆盖finalize()方法，或者finalize()方法已经被虚拟机调用过，虚拟机将这两种情况都视为“没有必要执行”和直接回收。
- 第二次标记：如果这个对象被判定为有必要执行finalize()方法，那么这个对象将会放置在一个叫做F-Queue的队列之中，由一低优先级线程执行该队列对象中的finalize方法. 执行完毕后, GC会再次判断可达性(即只有一次自救的机会), 若不可达, 则直接进行回收, 否则对象“复活”
- finalize()是Object的protected方法，子类可以覆盖该方法以实现资源清理工作，GC在*\*回收对象之前\调用该方法。*\*finalize()方法是对象逃脱死亡命运的最后一次机会，稍后GC将对F-Queue中的对象进行第二次小规模的标记，如果对象这个时候，未被重新引用，那它基本上就真的被回收了。\

```
package cn.itxs.entity;

import cn.itxs.garbage.FinalizeMain;

public class User {
    public int id = 0;
    public String name = "";
    public User(int id, String name) {
        this.id = id;
        this.name = name;
    }

    @Override
    public String toString() {
        return "User [id=" + id + ", name=" + name + "]";
    }

    @Override
    protected void finalize() throws Throwable {
        super.finalize();
        System.out.println("触发finalize方法...");
        // 进行拯救
        FinalizeMain.user = this;
    }

    public void isAlive() {
        System.out.println("成功复活");
    }
}
```

测试类

```
package cn.itxs.garbage;

import cn.itxs.entity.User;

public class FinalizeMain {
    public static User user = null;
    public static void main(String[] args) throws InterruptedException {
        user = new User(100,"IT小神");

        // 对象被GC回收前执行finalize方法, 可以有一次自我拯救的机会
        user = null;
        System.gc();

        // finalize方法优先级低(JVM会调用一个优先级低的线程执行Queue-F队列中的finalize方法)，sleep保证finalize方法已经执行完毕
        Thread.sleep(1000);

        if (null != user) {
            user.isAlive();
        } else {
            System.out.println("被回收了");
        }

        // 尝试再次自救
        user = null;
        System.gc();

        // 因为finalize()方法优先级很低, 保证执行
        Thread.sleep(1000);

        if (null != user) {
            user.isAlive();
        } else {
            System.out.println("被回收了");
        }
    }
}
```

![image-20220214112042526](http://www.itxiaoshen.com:3001/assets/1644808847940R1KQRMhB.png)

### 3.5 方法区回收

方法区主要回收的是类和常量

- 如何判断一个类是无用的类：同时满足一下3个条件，才能说一个类是无用的类。满足这3个条件便可以对无用类进行回收，但并非一定会回收。
  - java堆中已没有该类的实例。
  - 该类的类加载器已经被回收。
  - 该类对应的java.lang.Class对象没有在任何地方被引用，无法通过反射访问该类的任何方法。
- 如何判断一个常量是废弃常量：运行时常量池主要回收的是废弃的常量。
  - 假如在常量池中存在字符串"abc" ,若是当前没有任何String对象引用该字符串常量的话，就说明常量"abc"就是废弃常量,若是这时发生内存回收的话并且有必要的话，" abc"就会被系统清理出常量池。

### 3.6 垃圾收集算法

- 标记-清除算法（Mark-Sweep）：分为“标记”和“清除”两个阶段：首先标记出所有需要回收的对象，在标记完成后统一回收所有被标记的对象。

  - 特点是利用率百分之百、不需要内存复制。而它的主要不足是空间碎片问题，标记清除之后会产生大量不连续的内存碎片，空间碎片太多可能会导致以后在程序运行过程中需要分配较大对象时，无法找到足够的连续内存而不得不提前触发另一次垃圾收集动作。

  ![image-20220214175254963](http://www.itxiaoshen.com:3001/assets/1644832386296PMTSrzpt.png)

- 复制算法：将可用内存按容量划分为大小相等的两块，每次只使用其中的一块。当这一块的内存用完了，就将还存活着的对象复制到另外一块上面，然后再把已使用过的内存空间一次清理掉。这样使得每次都是对整个半区进行内存回收，内存分配时也就不用考虑内存碎片等复杂情况，只要按顺序分配内存即可。新生代使用，有老年代空间担保。

  - 特点是实现简单，运行高效；内存复制、没有内存碎片；但这种算法的代价是利用率减半也即是将内存缩小为原来的一半。

![image-20220214180013314](http://www.itxiaoshen.com:3001/assets/1644832817258WYjF67eX.png)

- 标记-整理算法（Mark-Compact）：首先标记出所有需要回收的对象，在标记完成后，后续步骤不是直接对可回收对象进行清理，而是让所有存活的对象都向一端移动，然后直接清理掉端边界以外的内存。
  - 特点是利用率百分之百、 没有内存碎片；但需要进行内存复制、效率也一般。

![image-20220214180900632](http://www.itxiaoshen.com:3001/assets/1644833346571WbpXGP6p.png)

- 分代收集算法：根据对象存活的不同生命周期将内存划分为不同的域，可以根据不同区域选择不同的算法。新生代的特点是每次垃圾回收时都有大量垃圾需要被回收，一般使用复制算法。老年代的特点是每次垃圾回收时只有少量对象需要被回收，一般使用标记-整理算法或标记-清除算法；

![image-20220214181401894](http://www.itxiaoshen.com:3001/assets/1644833646135CNPkYQ1b.png)

## 4 垃圾收集器

### 4.1 概述

垃圾收集算法是内存回收的方法论，那垃圾收集器就是内存回收的实现。HotSpot虚拟机常见的垃圾收集器所处新生代和年老代、搭配使用关系如下图

![image-20220215112226421](http://www.itxiaoshen.com:3001/assets/16448953536035ipFpfrH.png)

- HotSpot虚拟机常见其中垃圾收集器为Serial、ParNew、Parallel Scavenge、Serial  Old、Parallel  Old、CMS、G1。而作为未来趋势的ZGC收集器在JAVA11中开始引入，JAVA16优化推荐生产使用，目前越来越多大厂开始使用ZGC我们在后续单独研究ZGC。
- 所处区域上半部分为新生代收集器下半部分为老年代收集器
  - 新生代收集器：Serial、ParNew、Parallel Scavenge。
  - 老年代收集器：Serial Old、Parallel Old、CMS。
  - 整堆收集器：G1。
- 两个收集器间有连线，表明它们可以搭配使用。组合关系：Serial/Serial  Old、Serial/CMS、ParNew/Serial Old、ParNew/CMS、Parallel Scavenge/Serial  Old、Parallel Scavenge/Parallel Old、G1。其中
  - ParNew/Serial Old：与Serial/Serial Old相比，只是比年轻代多了多线程垃圾回收而已
  - ParNew/CMS：目前使用较多，比较高效的组合
  - Parallel Scavenge/Parallel Old：自动管理的组合
  - G1：属于上面7种最先进整堆垃圾收集器
- 其中Serial Old作为CMS出现"Concurrent Mode Failure"失败的后备预案使用。

### 4.2 Serial收集器

Serial（串行）收集器是最基本、发展历史最悠久的收集器。用于Client模式；它是一个单线程收集器，只会使用一个CPU或一条收集线程去完成垃圾收集工作，更重要的是它在进行垃圾收集时，必须暂停其他所有的工作线程，直至Serial收集器收集结束为止（“Stop The World”）。年轻代Serial收集器采用单个GC线程实现"复制"算法(包括扫描、复制)，年老代Serial  Old收集器采用单个GC线程实现"标记-整理"算法。Serial与Serial Old都会暂停所有用户线程(即STW)，设置参数为

- -XX:+UseSerialGC。
- -XX:+UseSerialOldGC。

![image-20220215115547084](http://www.itxiaoshen.com:3001/assets/1644897352841wN4iAa0w.png)

### 4.3 ParNew 收集器

ParNew 收集器除了多线程外，其余的行为、特点和Serial收集器一样；但是此组合中的Serial Old又是一个单GC线程，所以该组合是一个比较尴尬的组合。

设置参数：

- "-XX:+UseParNewGC"：强制指定使用ParNew；  
- "-XX:ParallelGCThreads"：指定垃圾收集的线程数量，ParNew默认开启的收集线程与CPU的数量相同；

![image-20220215120421260](http://www.itxiaoshen.com:3001/assets/164489787121541iPA6Wj.png)

### 4.4 Parallel Scavenge收集器

Parallel  Scavenge收集器也是一个并行的多线程新生代收集器，它也使用复制算法。用于Server模式；Parallel Old收集器是Parallel  Scavenge收集器的老年代版本，使用多线程和“标记-整理”算法。主要注重吞吐量(吞吐量越大，说明CPU利用率越高，所以主要用于处理很多的CPU计算任务而用户交互任务较少的情况)，目标是达到一个可控制的吞吐量（Throughput）。 设置参数为

- "-XX:+UseParallelScavengeGC"：指定使用Parallel Scavenge收集器；
- "-XX:+UseParallelOldGC"：指定使用Parallel Old收集器；

![image-20220215121130968](http://www.itxiaoshen.com:3001/assets/1644898306127sd650apQ.png)

### 4.5 CMS收集器

并发标记清理（Concurrent Mark Sweep，CMS）收集器也称为并发低停顿收集器（Concurrent Low Pause Collector）或低延迟（low-latency）垃圾收集器。

- 特点
  - 以获取最短回收停顿时间为目标。
  - 并发收集、低停顿；是HotSpot在JDK1.5推出的第一款真正意义上的并发（Concurrent）收集器；第一次实现了让垃圾收集线程与用户线程（基本上）同时工作。
- 缺点
  - 对CPU资源非常敏感。
  - 无法处理浮动垃圾,可能出现"Concurrent Mode Failure"失败。
  - 基于"标记-清除"算法(不进行压缩操作，产生内存碎片)  。
    - "-XX:+UseCMSCompactAtFullCollection"，使得CMS出现上面这种情况时不进行Full  GC，而开启内存碎片的合并整理过程；但合并整理过程无法并发，停顿时间会变长；默认开启（但不会进行，结合下面的CMSFullGCsBeforeCompaction）。
    - "-XX:+CMSFullGCsBeforeCompaction"： 设置执行多少次不压缩的Full GC后，来一次压缩整理；为减少合并整理过程的停顿时间； 默认为0，也就是说每次都执行Full GC，不会进行压缩整理。
- 应用场景
  - 与用户交互较多的场景。
  - 希望系统停顿时间最短，注重服务的响应速度。
  - 以给用户带来较好的体验。
  - 如常见WEB、B/S系统的服务器上的应用。
- 运作过程：总体上说CMS收集器的内存回收过程与用户线程一起并发执行；分为一下四步：
  - 初始标记（CMS initial mark）：仅标记一下GC Roots能直接关联到的对象；速度很快；但需要"Stop The World"。
  - 并发标记（CMS concurrent mark）： 进行GC Roots Tracing的过程；刚才产生的集合中标记出存活对象；应用程序也在运行； 并不能保证可以标记出所有的存活对象。
  - 重新标记（CMS remark）：为了修正并发标记期间因用户程序继续运作而导致标记变动的那一部分对象的标记记录；需要"Stop The World"，且停顿时间比初始标记稍长，但远比并发标记短；采用多线程并行执行来提升效率。
  - 并发清除（CMS concurrent sweep）：回收所有的垃圾对象；整个过程中耗时最长的并发标记和并发清除都可以与用户线程一起工作；
- 设置参数
  - "-XX:+UseConcMarkSweepGC"：指定使用CMS收集器；会默认使用ParNew作为新生代收集器。
- 总体来看，与Parallel Old垃圾收集器相比，CMS减少了执行老年代垃圾收集时应用暂停的时间； 但却增加了新生代垃圾收集时应用暂停的时间、降低了吞吐量而且需要占用更大的堆空间；

![image-20220215123443001](http://www.itxiaoshen.com:3001/assets/1644899687176xbFaCsiJ.png)

### 4.6 G1收集器

从G1与上面的CMS运作过程相比，仅在最后的"筛选回收"部分不同(CMS是并发清除)。

- 特点

  - 能独立管理整个GC堆（新生代和老年代），而不需要与其他收集器搭配；能够采用不同方式处理不同时期的对象；虽然保留分代概念，但Java堆的内存布局有很大差别；它将整个Java堆划分为多个大小相等的独立区域（Region），虽然还保留新生代和老年代的概念，但新生代和老年代不再是物理隔离的了，而都是一部分Region（不需要连续）的集合。

  ![image-20220215123701731](http://www.itxiaoshen.com:3001/assets/1644900140597rR0cGexd.png)

  - 可预测的停顿：低停顿的同时实现高吞吐量；G1除了追求低停顿处，还能建立可预测的停顿时间模型； 可以明确指定M毫秒时间片内，垃圾收集消耗的时间不超过N毫秒。
    - G1可以建立可预测的停顿时间模型，有计划地避免在Java堆的进行全区域的垃圾收集是因为G1跟踪各个region里面的垃圾堆积的价值(回收后所获得的空间大小以及回收所需时间长短的经验值)，在后台维护一个优先列表；每次根据允许的收集时间，优先回收价值最大的Region（名称Garbage-First的由来）；在指定的时间内，扫描部分最有价值的region(而不是扫描整个堆内存)，并回收，做到尽可能的在有限的时间内获取尽可能高的收集效率。
  - 结合多种垃圾收集算法，空间整合，不产生碎片；从整体看，是基于标记-整理算法；从局部（两个Region间）看，是基于复制算法。

- 应用场景

  - 面向服务端应用，针对具有大内存、多处理器的机器。
  - 需要低GC延迟，并具有大堆的应用程序提供解决方案。

- 运作过程

  - 初始标记（Initial Marking） 仅仅只是标记一下GC Roots  能直接关联到的对象，并且修改TAMS（Nest Top Mark  Start）的值，让下一阶段用户程序并发运行时，能在正确可以的Region中创建对象，此阶段需要停顿线程，但耗时很短。
  - 并发标记（Concurrent Marking） 从GC Root 开始对堆中对象进行可达性分析，找到存活对象，此阶段耗时较长，但可与用户程序并发执行。
  - 最终标记（Final Marking）  为了修正在并发标记期间因用户程序继续运作而导致标记产生变动的那一部分标记记录，虚拟机将这段时间对象变化记录在线程的Remembered Set  Logs里面，最终标记阶段需要把Remembered Set Logs的数据合并到Remembered  Set中，这阶段需要停顿线程，但是可并行执行。
  - 筛选回收（Live Data Counting and Evacuation）  首先对各个Region中的回收价值和成本进行排序，根据用户所期望的GC  停顿是时间来制定回收计划。此阶段其实也可以做到与用户程序一起并发执行，但是因为只回收一部分Region，时间是用户可控制的，而且停顿用户线程将大幅度提高收集效率。

  ![image-20220215125336090](http://www.itxiaoshen.com:3001/assets/1644900820388EPK7mbFW.png)

- 设置参数

  - "-XX:+UseG1GC"：指定使用G1收集器。
  - "-XX:InitiatingHeapOccupancyPercent"：当整个Java堆的占用率达到参数值时，开始并发标记阶段；默认为45。
  - "-XX:MaxGCPauseMillis"：为G1设置暂停时间目标，默认值为200毫秒。
  - "-XX:G1HeapRegionSize"：设置每个Region大小，范围1MB到32MB；目标是在最小Java堆时可以拥有约2048个Region。