- [JVM性能调优与实战基础理论篇-上](http://www.itxiaoshen.com/#/info?blogOid=67)

## 1 Java虚拟机

### 1.1 概述

> [Java官方文档](https://docs.oracle.com/en/java/index.html) https://docs.oracle.com/en/java/index.html

![image-20220213121827630](http://www.itxiaoshen.com:3001/assets/16447260631936KwkjQ7W.png)

JVM是一种规范，通过Oracle Java 官方文档找到JVM的规范查阅。Java虚拟机可以看做虚拟出来一台计算机，主体功能字节码指令集（汇编语言）和内存管理（栈、堆、方法区）等

## 2 常见的JVM实现

- Hotspot：目前使用的最多的 Java 虚拟机。
- Jrocket：原来属于BEA 公司，曾号称世界上最快的 JVM，后被 Oracle 公司收购，合并于 Hotspot
- J9: IBM 有自己的 java 虚拟机实现，它的名字叫做 J9. 主要是用在 IBM 产品（IBM WebSphere 和 IBM 的 AIX 平台上）
- TaobaoVM: 只有一定体量、一定规模的厂商才会开发自己的虚拟机，比如淘宝有自己的 VM,它实际上是 Hotspot 的定制版，专门为淘宝准备的，阿里、天 猫都是用的这款虚拟机。
- LiquidVM: 它是一个针对硬件的虚拟机，它下面是没有操作系统的（不是 Linux 也不是 windows）,下面直接就是硬件，运行效率比较高。
- zing: 它属于 zual 这家公司，非常牛，是一个商业产品，很贵！它的垃圾回收速度非常快（1 毫秒之内），是业界标杆。它的一个垃圾回收的算法后来被 Hotspot 吸收才有了现在的 ZGC。

![image-20220213122458468](http://www.itxiaoshen.com:3001/assets/16447263035844k57i1iW.png)

## 3 体系结构

我们通常所说的JDK，其实是指Java开发包，里面包含Java开发用到的工具集。

- JDK体系结构
  - Java运行环境（JRE）和开发工具（编译器，调试器，javadoc等）。
    - JRE：由JVM，Java运行时类库，动态链接库等组成；它为Java提供了运行环境，其中重要的一环就是通过JVM将字节码解释成可执行的机器码。
    - JDK的编译器Javac[.exe]，会将Java代码编译成字节码(.class文件)。编译出的字节码在任何平台上都一样的内容，所以我们说Java语言是门跨平台语言；Writeonce, run anywhere。

![image-20220211114426774](http://www.itxiaoshen.com:3001/assets/1644552030402KQTxi6TP.png)

- JVM和操作系统关系
  - 引入Java语言虚拟机后，Java语言在不同平台上运行时不需要重新编译。Java语言使用Java虚拟机屏蔽了与具体平台相关的信息，使得Java语言编译程序只需生成在Java虚拟机上运行的目标代码（字节码），就可以在多种平台上不加修改地运行。
  - 在运行时环境，JVM会将Java字节码解释成机器码。机器码和平台相关的（不同硬件环境、不同操作系统，产生的机器码不同），所以JVM在不同平台有不同的实现。目前JDK默认使用的实现是Hotspot VM。

![image-20220211115652914](http://www.itxiaoshen.com:3001/assets/164455203415217d3ZmYh.png)

- JVM架构：Java虚拟机主要分为五大模块：类装载器子系统、运行时数据区、执行引擎、本地方法接口和垃圾收集模块。

![jvm](http://www.itxiaoshen.com:3001/assets/16445520369994chXCWt4.png)

![image-20220211121225805](http://www.itxiaoshen.com:3001/assets/16445527599695AGJBNTj.png)

![image-20220212125554479](http://www.itxiaoshen.com:3001/assets/1644641759500Hs1z7mMd.png)

## 4 逃逸分析(Escape Analysis)

### 4.1 概述

- 逃逸分析的是一个对象的动态作用域，2种情况
  - 方法逃逸：对象通过参数传递传给了另一个方法。
  - 线程逃特性逸：对象有另外的线程访问。
- 逃逸分析的目的是确认一个对象是否只可能当前线程能访问。
- 逃逸分析可以带来一定程度上的性能优化。但是逃逸分析自身也是需要进行一系列复杂的分析的，这其实也是一个相对耗时的过程。
- JIT（Just In Time Compiler）即时编译技术，在即时编译过程中JVM可能会对我们的代码做一些优化如逃逸分析等。

### 4.2 优化策略

逃逸分析的优化策略主要有三个：对象可能分配在栈上、分离对象或标量替换、消除同步锁。

![image-20220213114802063](http://www.itxiaoshen.com:3001/assets/1644724089616jC4xxayZ.png)

- *\*对象可能分配在栈上\：JVM通过逃逸分析，分析出新对象的使用范围，就可能将对象在栈上进行分配。栈分配可以快速地在栈帧上创建和销毁对象，不用再将对象分配到堆空间，可以有效地减少 JVM 垃圾回收的压力。
- *\*分离对象或标量替换\：当JVM通过逃逸分析，确定要将对象分配到栈上时，即时编译可以将对象打散，将对象替换为一个个很小的局部变量，我们将这个打散的过程叫做标量替换。将对象替换为一个个局部变量后，就可以非常方便的在栈上进行分配了。所谓标量就是不能再分割的变量，如Java基本数据类型。
- *\*同步锁消除\：如果JVM通过逃逸分析，发现一个对象只能从一个线程被访问到，则访问这个对象时，可以不加同步锁。如果程序中使用了synchronized锁，则JVM会将synchronized锁消除。

### 4.3 逃逸分析开关

逃逸分析其实并不是新概念，早在1999年就有论文提出了该技术。但在Java中算是新颖而前言的优化技术，从 JDK1.6才开始引入该技术，JDK1.7开始默认开启逃逸分析，也可通过开关控制

- -XX:+DoEscapeAnalysis开启逃逸分析
- -XX:-DoEscapeAnalysis 关闭逃逸分析
- -XX:+EliminateAllocations开启标量替换
- -XX:-EliminateAllocations 关闭标量替换
- -XX:+EliminateLocks开启锁消除
- -XX:-EliminateLocks 关闭锁消除
- 开启标量替换或锁消除 必须打开逃逸分析开关

### 4.4 常见面试问题

- 是不是所有的对象和数组都会在堆内存分配空间？不一定，只要掌握了逃逸分析的原理，那就很清楚知道Java中的对象不一定是在堆上分配的，因为JVM通过逃逸分析，能够分析出一个新对象的使用范围，并以此确定是否要将这个对象分配到堆上。
- 加了锁的代码锁就一定会生效吗？不一定

## 5 JVM运行模式

- 解释模式（Interpreted Mode）：只使用解释器（-Xint 强制JVM使用解释模式），执行一行JVM字节码就编译一行为机器码
- 编译模式（Compiled Mode）：只使用编译器（-Xcomp JVM使用编译模式），先将所有的JVM字节码一次编译为机器码，然后一次性执行所有机器码
- 混合模式（Mixed Mode）：(-Xmixed 设置JVM使用混合模式)依然使用解释模式执行代码，但是对于一些“热点”代码采取编译器模式执行，这些热点代码对应的机器码会被缓存起来，下次执行无需再编译。JVM一般采用混合模式执行代码

| JVM运行模式 | 优点                                                         | 适用场景                                           |
| ----------- | ------------------------------------------------------------ | -------------------------------------------------- |
| 解释模式    | 启动快                                                       | 只需要执行部分代码，且大多数代码只会执行一次的情况 |
| 编译模式    | 启动慢，但是后期执行速度快，比较占用内存[1](https://blog.csdn.net/qq_30166729/article/details/106450730#fn1) | 适合代码可能会被反复执行的场景                     |
| 混合模式    |                                                              | 一般JVM所默认的模式                                |

## 6 Java启动参数分类

- 标准参数（-），所有的JVM实现都必须实现这些参数的功能，而且向后兼容；
- 非标准参数（-X），默认jvm实现这些参数的功能，但是并不保证所有jvm实现都满足，且不保证向后兼容；jvm参数调优重点
- 非Stable参数（-XX），此类参数各个jvm实现会有所不同，将来可能会随时取消，需要慎重使用；jvm参数调优重点。可以通过java -XX:+PrintFlagsFinal -version 获取支持参数选项。

## 7 类加载

### 7.1 类加载过程

- 类加载：类加载器将class文件加载到虚拟机的内存

- 类的7个生命周期：加载 -> 验证 -> 准备 -> 解析 -> 初始化 -> 使用 -> 卸载

  - 加载：在硬盘上查找并通过IO读入字节码文件

  - 连接：执行验证、准备、解析步骤

    - 验证：校验字节码文件的正确性，不是必要的，可以关闭校验提高虚拟机加载类的速度
    - 准备：给类的静态变量分配内存，并赋予默认值
    - 解析：将符号引用替换为直接引用；通过javap  -v将字节码文件反汇编为更可读的文件，像类，方法等一切的字面量都转换为符号引用#1...N。包括类解析，字段解析，方法解析，接口解析。即将字节码的静态字面关联（字符串，静态）转换为JVM内存中的动态指针关联（指针，动态）。

    ![image-20220212002205760](http://www.itxiaoshen.com:3001/assets/1644596540918WZ1G425W.png)

  - 初始化：对类的静态变量初始化为指定的值，执行静态代码块

  ![image-20220211182213632](http://www.itxiaoshen.com:3001/assets/1644574953978ZDfEJrxQ.png)

  - 使用：new出对象程序中使用
  - 卸载：执行垃圾回收

## 8 类加载器

### 8.1 概述

![image-20220212002228525](http://www.itxiaoshen.com:3001/assets/1644598264971dyEhXHx8.png)

- 启动类加载器：C语言开发，加载Java核心类库。基于沙箱机制，只加载java、javax、sun包开头的类。
- 扩展类加载器：Java语言编写，由sun.misc.Launcher$ExtClassLoader实现，上级加载器为启动类加载器，负责加载jre/lib/ext扩展目录中的jar类包。
- 应用程序类加载器：Java语言编写，由sun.misc.Launcher$AppClassLoader实现，上级加载器为扩展类加载器，是默认的类加载器。负责加载ClassPath路径下的类包，主要就是加载你自己写的那些类。
- 自定义类加载器：负责加载用户自定义路径下的类包
  - 使用场景：字节码二进制流来自于网络，字节码文件不在指定的lib、ext、classpath路径下，需要对二进制流加工后才能得到字节码。
  - 不同的类加载器加载同一个Class字节码文件后，在JVM中产生的类对象是不同的。同一个类加载器，Class实例在JVM中才是全局唯一。
  - 在Java中，一个类用其`全限定类名（包括包名和类名）`作为标识；但在JVM中，一个类用其全限定类名和其类加载器作为其唯一标识。

### 8.2 类加载器获取示例

JVM预定义的类加载器为启动类加载器、扩展类加载器、应用程序类加载器。

```java
package cn.itxs.classloader;

import cn.itxs.entity.User;

public class ClassLoaderMain {
    public static void main(String[] args) {
        System.out.println(String.class.getClassLoader());
        System.out.println(com.sun.crypto.provider.DESedeKeyFactory.class.getClassLoader().getClass().getName());
        System.out.println(User.class.getClassLoader().getClass().getName());
        System.out.println(ClassLoader.getSystemClassLoader().getClass().getName());
    }
}
```

![image-20220212005041288](http://www.itxiaoshen.com:3001/assets/1644747183398k0YYmfF4.png)

### 8.3 自定义类加载器示例

除了启动类加载器，所有类加载器都是ClassLoader的子类，所以我们可以通过继承ClassLoader来实现自己的类加载器。

```java
package cn.itxs.entity;

public class Goods {
    public void sayHello(){
        System.out.println("hello goods!");
    }
}
```

生成字节码文件Goods.class后剪切（不是拷贝，删掉类路径下的字节码文件）到D:\temp\cn\itxs\entity目录下

```java
package cn.itxs.classloader;

import java.io.ByteArrayOutputStream;
import java.io.FileInputStream;
import java.io.IOException;
import java.lang.reflect.Method;
import java.nio.ByteBuffer;
import java.nio.channels.Channels;
import java.nio.channels.FileChannel;
import java.nio.channels.WritableByteChannel;

public class ItxsClassLoader extends ClassLoader{
    private String classPath;

    public ItxsClassLoader(String classPath) {
        this.classPath = classPath;
    }

    private byte[] loadBytes(String name) throws IOException {
        name = name.replaceAll("\\.","/");
        FileInputStream fis = new FileInputStream(classPath+"/"+name+".class");
        FileChannel fc = fis.getChannel();
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        WritableByteChannel wbc = Channels.newChannel(baos);
        ByteBuffer by = ByteBuffer.allocate(1024);
        while (true){
            int i = fc.read(by);
            if (i == 0 || i == -1){
                break;
            }
            by.flip();
            wbc.write(by);
            by.clear();
        }
        fis.close();
        return baos.toByteArray();
    }

    @Override
    protected Class<?> findClass(String name) throws ClassNotFoundException {
        try {
            byte[] bytes = loadBytes(name);
            return defineClass(name,bytes,0, bytes.length);
        }catch (Exception e) {
            e.printStackTrace();
            throw new ClassNotFoundException();
        }
    }

    public static void main(String[] args) throws Exception {
        ItxsClassLoader itxsClassLoader = new ItxsClassLoader("D:/temp");
        Class clazz = itxsClassLoader.loadClass("cn.itxs.entity.Goods");
        Object obj = clazz.newInstance();
        Method method = clazz.getDeclaredMethod("sayHello", null);
        method.invoke(obj,null);
        System.out.println(clazz.getClassLoader().getClass().getName());
    }
}
```

![image-20220212012956180](http://www.itxiaoshen.com:3001/assets/16446006132903rAEdCar.png)

### 8.4 双亲委派机制

- 双亲委派机制：当一个类加载器收到了类加载的请求的时候，他不会直接去加载指定的类，而是把这个请求委托给自己的父加载器去加载。只有父加载器无法加载这个类的时候，才会由当前这个加载器来负责类的加载。
- 当进行类加载的时候，虽然用户自定义类不会由Bootstrap ClassLoader或是Extension  ClassLoader加载（由类加载器的加载范围决定），但是代码实现还是会一直委托到Bootstrap ClassLoader,  上层无法加载，再由下层是否可以加载，如果都无法加载，就会触发findClass,抛出ClassNotFoundException。
- 类加载器之间的层级关系并不是以继承的方式存在的，而是以组合的方式处理的。

![image-20220212115840306](http://www.itxiaoshen.com:3001/assets/1644638331285i8zZkTc2.png)

- 双亲委派机制是在ClassLoader里的loadClass方法里实现的,如果想自己实现类加载器的话，可以继承ClassLoader后重写findClass方法，加载对应的类。源码实现流程简单如下：
  - 首先判断该类是否已经被加载。
  - 该类未被加载，如果父类不为空，交给父类加载。
  - 如果父类为空，交给Bootstrap Classloader 加载。
  - 如果类还是无法被加载到，则触发findClass,抛出ClassNotFoundException。

```java
protected Class<?> loadClass(String name, boolean resolve)
    throws ClassNotFoundException
{
    synchronized (getClassLoadingLock(name)) {
        // First, check if the class has already been loaded
        Class<?> c = findLoadedClass(name);
        if (c == null) {
            long t0 = System.nanoTime();
            try {
                if (parent != null) {
                    c = parent.loadClass(name, false);
                } else {
                    c = findBootstrapClassOrNull(name);
                }
            } catch (ClassNotFoundException e) {
                // ClassNotFoundException thrown if class not found
                // from the non-null parent class loader
            }

            if (c == null) {
                // If still not found, then invoke findClass in order
                // to find the class.
                long t1 = System.nanoTime();
                c = findClass(name);

                // this is the defining class loader; record the stats
                sun.misc.PerfCounter.getParentDelegationTime().addTime(t1 - t0);
                sun.misc.PerfCounter.getFindClassTime().addElapsedTimeFrom(t1);
                sun.misc.PerfCounter.getFindClasses().increment();
            }
        }
        if (resolve) {
            resolveClass(c);
        }
        return c;
    }
}
```

- 双亲委派机制作用

  - *\*可以避免类的重复加载\，当父加载器已经加载过某一个类时，子加载器就不会再重新加载这个类。
  - *\*保证了安全性\。因为Bootstrap ClassLoader在加载的时候，只会加载JAVA_HOME中的jar包里面的类，如java.lang.Integer，那么这个类是不会被随意替换的，这样可以有效的防止核心Java API被篡改。

- 打破双亲委派

  - 双亲委派机制也非必然。比如Tomcat  web容器里面部署了很多的应用程序，这些应用程序对于第三方类库的依赖版本却不一样，且通常这些第三方类库的路径又是一样的，如果采用默认的双亲委派类加载机制，那么是无法加载多个相同的类。所以Tomcat破坏双亲委派原则，提供隔离的机制，为每个web容器单独提供一个WebAppClassLoader加载器。
  - Tomcat的类加载机制：为了实现隔离性，优先加载 Web 应用自己定义的类，不遵照双亲委派的约定，每一个应用自己的类加载器——WebAppClassLoader负责加载本身的目录下的class文件，加载不到时再交给CommonClassLoader加载。

  ![image-20220212122118332](http://www.itxiaoshen.com:3001/assets/16446396832565F3x1eKk.png)