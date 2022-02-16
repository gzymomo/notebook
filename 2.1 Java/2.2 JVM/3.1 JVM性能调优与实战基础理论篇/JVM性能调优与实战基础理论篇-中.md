- [JVM性能调优与实战基础理论篇-中](http://www.itxiaoshen.com/#/info?blogOid=68)

## 1 JVM内存模型

### 1.1 概述

我们所说的JVM内存模型是指运行时数据区，用New出来的对象放在堆中，如每个线程中局部变量放在栈或叫虚拟机栈中，下图左边区域部分为栈内存的结构。如main线程包含程序炯酸器、线程栈、本地方法栈三大部分，线程栈包含一个或多个栈帧，虚拟机都会给每个方法在各自的线程栈空间中开辟一块栈帧空间来存放局部变量表、操作数栈、动态链接、方法出口等。

![image-20220212123628276](http://www.itxiaoshen.com:3001/assets/164464059463058KXb5ez.png)

根据JVM规范共分为虚拟机栈，堆，方法区，程序计数器，本地方法栈五个部分

![image-20220212123818839](http://www.itxiaoshen.com:3001/assets/16446407025947F1xP1aB.png)

- 虚拟机栈：是线程私有的内存空间，它和 Java  线程一起创建，生命周期与线程相同。当创建一个线程时，会在虚拟机栈中申请一个线程栈，用来保存方法的局部变量、操作数栈、动态链接方法和返回地址等信息，并参与方法的调用和返回。每一个方法的调用都伴随着栈帧的入栈操作，方法的返回则是栈帧的出栈操作。可以这么理解，虚拟机栈针对当前 Java 应用中所有线程，都有一个其相应的线程栈，每一个线程栈都互相独立、互不影响，里面存储了该线程中独有的信息。 
- 方法区：与Java堆一样，是各个线程所共享的，它用来存储已被虚拟机加载的类信息、常量、静态变量、即时编译后的代码等数据。方法区使用的不是jvm的内存，而是使用直接内存。
  - 方法区是jvm提出的规范，而永久代就是方法区的具体实现。java虚拟机对方法区的限制非常宽松，可以像堆一样不需要连续的内存和选择的固定大小外，还可以选择不识闲垃圾收集，相对而言，垃圾收集行为在这边区域是比较少出现的。在方法区会报出永久代内存溢出的错误。
  - 而java1.8为了解决这个问题，就提出了meta space（元空间）的概念，就是为了解决永久代内存溢出的情况，一般来说，在不指定 meta space大小的情况下，虚拟机方法区内存大小就是宿主主机的内存大小。
- 程序计数器：（Program Counter Register）是一块较小的内存空间，它的作用可以看做是当前线程所执行的字节码的行号指示器。
- 本地方法栈：与虚拟机栈发挥的作用非常类似，他们之间的区别是虚拟机栈为虚拟机执行java方法服务，而本地方法栈则为虚拟机使用到的native方法服务。与虚拟机栈一样，本地方法栈也会抛出StackOverflowError，OutOfMemorryError异常。
- 堆：是Java 虚拟机所管理的内存中最大的一块。Java  堆是被所有线程共享的一块内存区域，在虚拟机启动时创建，几乎所有对象和数组都被分配到了堆内存中。堆被划分为新生代和老年代，新生代又被进一步划分为  Eden 区和 Survivor 区，最后 Survivor 由 From Survivor 和 To Survivor 组成。随着 Java  版本的更新，其内容又有了一些新的变化：在 Java6 版本中，永久代在非堆内存区；到了 Java7  版本，永久代的静态变量和运行时常量池被合并到了堆中；而到了 Java8，永久代被 元空间  (处于本地内存)取代了。运行时常量池是位于元空间中，String的实例是放在堆内存中。

![image-20220212125249657](http://www.itxiaoshen.com:3001/assets/1644641577720dBZJDbMs.png)

## 2 JDK1.8元空间（metaspace）

![image-20220212130708106](http://www.itxiaoshen.com:3001/assets/1644642435970bwAMFBt7.png)

- 方法区与永久代、元空间之间的关系
  - 方法区是一种规范，不同的虚拟机厂商可以基于规范做出不同的实现，永久代和元空间就是出于不同jdk版本的实现。也可以理解方法区就像是一个接口，永久代与元空间分别是两个不同的实现类而已。只不过永久代是这个接口1.8之前的实现类，直到彻底废弃这个实现类，由新实现类——元空间进行替代。
- 永久代
  - PermGen space的全称是Permanent Generation  space,是指内存的永久保存区域，说说为什么会内存益出：这一部分用于存放Class和Meta的信息,Class在被  Load的时候被放入PermGen  space区域，它和和存放Instance的Heap区域不同,所以如果你的APP会LOAD很多CLASS的话,就很可能出现PermGen  space错误。
  - 它的上限是MaxPermSize，默认是64M。
  - 永久代大小是在启动时固定好的——很难进行调优。-XX:MaxPermSize,永久代最终被移除，运行时常量池存在于内存的元空间中，字符串常量移至Java Heap。PermSize 和 MaxPermSize 会被忽略并给出警告.
- metaspace元空间
  - 元空间的本质和永久代类似，都是对JVM规范中方法区的实现。不过元空间与永久代之间最大的区别在于：元空间并不在虚拟机中，而是使用本地内存。因此，默认情况下，元空间的大小仅受本地内存限制，但可以通过以下参数来指定元空间的大小： 
    - -XX:MetaspaceSize，初始空间大小，达到该值就会触发垃圾收集进行类型卸载，同时GC会对该值进行调整：如果释放了大量的空间，就适当降低该值；如果释放了很少的空间，那么在不超过MaxMetaspaceSize时，适当提高该值。 
    - -XX:MaxMetaspaceSize，最大空间，默认是没有限制的。 
    - 除了上面两个指定大小的选项以外，还有两个与 GC 相关的属性： 
      - -XX:MinMetaspaceFreeRatio，在GC之后，最小的Metaspace剩余空间容量的百分比，减少为分配空间所导致的垃圾收集 
      - -XX:MaxMetaspaceFreeRatio，在GC之后，最大的Metaspace剩余空间容量的百分比，减少为释放空间所导致的垃圾收集
  - 元空间替换永久代的原因
    - 之前不管是不是需要，JVM都会吃掉那块空间……如果设置得太小，JVM会死掉；如果设置得太大，这块内存就被JVM浪费了。理论上说，现在你完全可以不关注这个，因为JVM会在运行时自动调校为“合适的大小”；
    - 提高Full GC的性能，在Full GC期间，Metadata到Metadata pointers之间不需要扫描了；
    - 隐患就是如果程序存在内存泄露，不停的扩展metaspace的空间，会导致机器的内存不足，所以还是要有必要的调试和监控。

## 3 字节码分析示例

```java
package cn.itxs.memorymodel;

public class Math {

    public int compute(){
        int a = 1;
        int b = 2;
        int c = (a + b) * 10;
        return c;
    }

    public static void main(String[] args) {
        Math math = new Math();
        math.compute();
    }
}
```

通过命令javap -c反汇编输出更加可读内容进行jvm底层的字节码分析 javap -c Math.class > Math.txt

![image-20220213004029364](http://www.itxiaoshen.com:3001/assets/16446841996701xpR3NCY.png)

![image-20220213004308215](http://www.itxiaoshen.com:3001/assets/164468420333706CDEEWx.png)

每行字节码则由线程的程序计算器记录执行的行号，反汇编后的是jvm执行指令，可以通过查询jvm指令手册了解其执行操作含义。比如第一行iconst_1对应jvm指令手册为

0x04 iconst_1 将int型(1)推送至栈顶

![image-20220213005541606](http://www.itxiaoshen.com:3001/assets/1644684949959MwDCSfHb.png)

## 4 线程栈大小示例

```java
package cn.itxs.memorymodel;

public class StackOverFlowMain {
    static int count = 0;
    static void test(){
        count++;
        test();
    }

    public static void main(String[] args) {
        try {
            test();
        }catch (Throwable t){
            t.printStackTrace();
            System.out.println(count);
        }
    }
}
```

JVM默认每个线程栈大小为1M，可以通过-Xss参数设置线程栈大大小

![image-20220213010347903](http://www.itxiaoshen.com:3001/assets/1644836426396JhFSGMJ7.png)

重新设置vmoption的参数为-Xss128k，再次执行count的输出为1920

![image-20220213010729980](http://www.itxiaoshen.com:3001/assets/1644836422633QmDQXJeG.png)

## 5 符号引用分析示例

前面类加载的连接中解析阶段将符号引用转换为直接引用， javap -v Math.class > Math-v.txt输出更详细的字节码执行信息

![image-20220213012831350](http://www.itxiaoshen.com:3001/assets/1644687193688ZdKpRfZJ.png)

在main方法中#4，对应的符号信息查找到常量池对应信息如下，也即是Math类的compute方法

![image-20220213013219509](http://www.itxiaoshen.com:3001/assets/1644687198083F1z8eyhE.png)

## 6 堆内存动态演示示例

```java
package cn.itxs.memorymodel;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.TimeUnit;

public class HeapMain {
    byte[] bytes = new byte[1024*200];

    public static void main(String[] args) throws InterruptedException {
        List<HeapMain> heapMains = new ArrayList<HeapMain>();
        while (true) {
            heapMains.add(new HeapMain());
            TimeUnit.MILLISECONDS.sleep(20);
        }
    }
}
```

运行main方法，使用JDK调优工具jvisualvm，需要在jvisualvm需要先安装好visual  gc插件。直接在命令行窗口输入jvisualvm,然后再左侧选择测试java程序双击，点击右边Visual GC  Tab页，可以观察到动态堆内存变化过程。