- [JUC并发编程与高性能内存队列disruptor实战-下](http://www.itxiaoshen.com/#/info?blogOid=64)

## 1 并发理论

### 1.1 JMM

#### 1.1.1 概述

- Java Memory  Model缩写为JMM，直译为Java内存模型，定义了一套在多线程读写共享数据时（成员变量、数组）时，对数据的可见性、有序性和原子性的规则和保障；JMM用来屏蔽掉各种硬件和操作系统的内存访问差异，以实现让Java程序在各平台下都能够达到一致的内存访问效果。
- JMM是一种规范，目的是解决由于多线程通过共享内存进行通信时，存在的本地内存数据不一致、编译器对代码指令重排序、处理器对代码乱序执行、CPU切换线程等带来的问题。

#### 1.1.2 并发与并行

- 并发：指的是多个事情，在同一时间段内同时发生了； 并发的多个任务之间是互相抢占资源的。
- 并行：指的是多个事情，在同一时间点上同时发生了；并行的多个任务之间是不互相抢占资源的。
- 只有在多CPU的情况中，才会发生并行。否则，看似同时发生的事情，其实都是并发执行的。

#### 1.1.3 现代计算机内存模型

现代计算机处理器与存储设备运算速度完全不在同一量级上，至少相差几个数量级，如果让处理器等待计算机存储设备那么这样处理器的优势就不会体现出来。为了提高处理性能实现高并发，在处理器和存储设备之间加入了高速缓存（cache）来作为缓冲。将CPU运算需使用到的数据先复制到缓存中，让CPU运算能够快速进行；当CPU运算完成之后，再将缓存中的结果写回主内存，这样CPU运算就不用依赖等待主内存的读写操作了。

- 高速缓存设置为多级缓存，其目的为了解决CPU运算速度与内存读写速度不匹配的矛盾；在CPU和内存之间，引入了L1高速缓存、L2高速缓存、L3高速缓存

  每一级缓存中所存储的数据全部都是下一级缓存中的一部分，当CPU需要数据时，先从缓存中取，加快读写速度，提高CPU利用率。存储层次金字塔的结构：

  - 寄存器 → L1缓存 → L2缓存 → L3缓存 → 主内存 → 本地磁盘 → 远程数据库。
  - 越往上访问速度越快、成本越高，空间更小。越往下访问速度越慢、成本越低，空间越大。![image-20220117124047273](http://www.itxiaoshen.com:3001/assets/16423944533342wD1B2Mc.png)

- 每个处理器都有自己的高速缓存，同时又共同操作同一块主内存，当多个处理器同时操作主内存时，可能将导致各自的的缓存数据不一致，为了解决这个问题

  主要提供了两种解决办法：

  - 总线锁：在多 cpu 下，当其中一个处理器要对共享内存进行操作的时候，在总线上发出一个 LOCK#  信号，这个信号使得其他处理器无法通过总线来访问到共享内存中的数据，总线锁定把 CPU  和内存之间的通信锁住了，这使得锁定期间，其他处理器不能操作其他内存地址的数据，总线锁定的开销比较大，这种机制显然是不合适的。总线锁的力度太大了，最好的方法就是控制锁的保护粒度，只需要保证对于被多个 CPU 缓存的同一份数据是一致的就可以了。
  - 缓存锁：相比总线锁，缓存锁即降低了锁的力度。核心机制是基于缓存一致性协议来实现的。为了达到数据访问的一致，需要各个处理器在访问缓存时遵循一些协议，在读写时根据协议来操作，常见的协议有 MSI、MESI、MOSI 等，最常见的为Intel的MESI协议是四种状态的缩写，用来修饰缓存行的状态。
    - M:被修改,该缓存行的数据被修改了，和主存数据不一致。监听所有想要修改此缓存行对应的内存数据的操作，该操作必须等缓存行数据更新到主内存中，状态变成 S (Shared）共享状态之后执行。
    - E:独享,该缓存行和内存数据一致，数据只在本缓存中；监听所有读取此缓存行对应的内存数据的操作，如果发生这种操作，Cache Line 缓存状态从独占转为共享状态。
    - S:分享,缓存行和内存数据一致，数据位于多个缓存中，监听其他缓存使该缓存行失效或者独享该缓存行的操作，如果检测到这种操作，将该缓存行变成无效。
    - I:无效的,该缓存行的数据无效，没有监听，处于失效状态的缓存行需要去主存读取数据。

![image-20220115141207580](http://www.itxiaoshen.com:3001/assets/1642227381169K502W4Hn.png)

- 如何发现数据是否失效？总线的嗅探机制每个处理器通过嗅探在总线上传播的数据来检查自己缓存的值是不是过期了，当处理器发现自己缓存行对应的内存地址被修改，就会将当前处理器的缓存行设置成无效状态，当处理器对这个数据进行修改操作的时候，会重新从系统内存中把数据读到处理器缓存里。
- 嗅探缺点：总线风暴由于Volatile的MESI缓存一致性协议，需要不断的从主内存嗅探和CAS不断循环，无效交互会导致总线带宽达到峰值。所以不要大量使用Volatile，至于什么时候去使用Volatile什么时候使用锁，根据场景区分。

![image-20220116111806943](http://www.itxiaoshen.com:3001/assets/1642303096433w8WFa1xD.png)

#### 1.1.4 本地内存与主内存

- JMM定义了线程和主内存之间的抽象关系：线程之间的共享变量存储在主内存中，每个线程都有一个私有的本地内存或者叫工作内存，本地内存中存储了该线程以读/写共享变量的副本。
- 但本地内存是JMM的一个抽象概念，并不真实存在；它涵盖了缓存，写缓冲区，寄存器以及其他的硬件和编译器优化。

![image-20220115141604820](http://www.itxiaoshen.com:3001/assets/1642227383399jQbKYfJH.png)

- 主内存和本地内存的交互
  - 线程的本地内存中保存了被该线程使用到的变量的主内存副本拷贝，线程对变量的所有操作都必须在本地内存中进行，而不能直接读写主内存中的变量。不同的线程之间也无法直接访问对方本地内存中的变量，线程间变量值的传递均需要通过主内存来完成。下面AB线程为例：
    - A线程先把本地内存的值写入主内存。
    - B线程从主内存中去读取出A线程写的值。

![image-20220115134909489](http://www.itxiaoshen.com:3001/assets/1642225757473zKJH02BB.png)

#### 1.1.5 原子操作

在此交互过程中，Java内存模型定义了8种操作来完成，虚拟机实现必须保证每一种操作都是原子的、不可再拆分的（double和long类型例外）

![image-20220115142632969](http://www.itxiaoshen.com:3001/assets/1642228047888hchaANMA.png)

- read：读取，作用于主内存把变量从主内存中读取到本本地内存。
- load：加载，主要作用本地内存，把从主内存中读取的变量加载到本地内存的变量副本中
- use：使用，主要作用本地内存，把工作内存中的一个变量值传递给执行引擎，每当虚拟机遇到一个需要使用变量的值的字节码指令时将会执行这个操作。、
- assign：赋值 作用于工作内存的变量，它把一个从执行引擎接收到的值赋值给工作内存的变量，每当虚拟机遇到一个给变量赋值的字节码指令时执行这个操作。
- store： 存储 作用于工作内存的变量，把工作内存中的一个变量的值传送到主内存中，以便随后的write的操作。
- write：写入 作用于主内存的变量，它把store操作从工作内存中一个变量的值传送到主内存的变量中。
- lock：锁定 ：作用于主内存的变量，把一个变量标识为一条线程独占状态。
- unlock：解锁：作用于主内存变量，把一个处于锁定状态的变量释放出来，释放后的变量才可以被其他线程锁定。

### 1.2 三大特性

一个线程在执行的过程中不仅会用到CPU资源，还会用到IO，IO的速度远远比不上CPU的运算速度；当一个线程要请求IO的时候可以放弃CPU资源，这个时候其他线程就可以使用CPU，这就提高了CPU的利用率，当然线程之间的切换也会有额外的资源消耗，但多线程带来回报更大。而有了多线程就存在线程安全的问题，在Java并发编程中的一种思路就是通过原子性、可见性和有序性这三大特性切入点去考虑；在并发编程中，必须同时保证程序的原子性、有序性和可见性才能够保证程序的正确性。

- 原子性
  - 定义：一个操作或多个操作做为一个整体，要么全部执行并且必定成功执行，要么不执行；简单理解就是程序的执行是一步到位的。
  - 一个或者多个操作在 CPU 执行的过程中不被中断的特性。由于线程的切换，导致多个线程同时执行同一段代码，带来的原子性问题。
    - 就如我们常见i++也并不是原子操作；i++分为三步，第一步先读取x的值，第二步进行x+1，第三步x+1的结果写入到内存中。
    - 还有如我们前面将单例设计模式的双层检测锁时的instance = new DoubleCheckSingleton()  这一行代码jvm内部执行3补步，1先申请堆内存，2对象初始化,3对象指向内存地址；2和3由于jvm有指令重排序优化所以存在3先执行可能会导致instance还没有初始化完成，其他线程就得到了这个instance不完整单例对象的引用值而报错。
  - 在java当中，\\\直接的读取操作和赋值（常量）属于原子性操作\\\。对于原本不具有原子性的操作我们可以通过synchronized关键字\或者Lock接口\来保证同一时间只有一个线程执行同一串代码，从而也具有了原子性。
- 有序性
  - 定义：程序的执行是存在一定顺序的。在Java内存模型中，为了提高性能和程序的执行效率，编译器和处理器会对程序指令做重排序。在单线程中，重排序不会影响程序的正确性；as-if-serial原则是指不管编译器和CPU如何重排序，必须保证单线程情况下程序的结果是正确的；但在并发编程中，却有可能得出错误的结果。![image-20220114122346225](http://www.itxiaoshen.com:3001/assets/1642141499890tCCGPi8M.png)
  - 在java当中使用volatile关键字、synchronized关键字或Lock接口来保证有序性。
- 可见性
  - 定义：指在共享变量被某一个线程修改之后，另一个线程访问的时候能够立刻得到修改以后的值。如果多个线程同时读取一个变量的时候，会在每个高速缓存中都拷贝一份数据到工作内存，内存彼此之间是不可见的。缓存不能及时刷新导致了可见性问题。
  - JSR-133 内存模型使用happens-before原则来阐释线程之间的可见性。如果一个操作对另一个操作存在可见性，那么他们之间必定符合happens-before原则：
    - 程序顺序规则：一个线程内，按照代码顺序，书写在前面的操作先行发生于书写在后面的操作。
    - 监视器锁规则：一个unLock操作先行发生于后面对同一个锁的lock操作。
    - volatile域规则：对一个变量的写操作先行发生于后面对这个变量的读操作。
    - 传递性规则：如果操作A先行发生于操作B，而操作B又先行发生于操作C，则可以得出操作A先行发生于操作C。
  - 在java当中普通的、未加修饰的共享变量是不能保证可见性的。我们照样可以通过synchronized关键字和Lock接口来保证可见性，同样也能利用volatile实现。

### 1.3 volatile和synchronized

#### 1.3.1 两者区别

- volatile只能修饰实例变量和类变量，而synchronized可以修饰方法，以及代码块。
- volatile保证数据的可见性，但是不保证原子性(多线程进行写操作，不保证线程安全);而synchronized是一种排他(互斥)的机制。
- volatile用于禁止指令重排序：例如可以解决单例双重检查对象初始化代码执行乱序问题；volatile是通过内存屏障去完成的禁止指令重排序。
- volatile可以看做是轻量版的synchronized，volatile不保证原子性，但是如果是对一个共享变量进行多个线程的赋值，而没有其他的操作，那么就可以用volatile来代替synchronized，因为赋值本身是有原子性的，而volatile又保证了可见性，所以就可以保证线程安全了。

### 1.4 synchronized

- 在Java中任何一个对象都有一个monitor与之关联，当且一个monitor被持有后，这个对象处于锁定状态；尝试获得锁就是尝试获取对象所对应的monitor的所有权。
- synchronized主要原理和思路通过monitor里面设计一个计数器，synchronized关键字在底层编译后的jvm指令中会有monitorenter(加锁)和monitorexit(释放锁)两个指令来实现锁的使用，每个对象都有一个关联的monitor，比如一个对象实例就有一个monitor，一个类的Class对象也有一个monitor，如果要对这个对象加锁，那么必须获取这个对象关联的monitor的lock锁；计数器从0开始；如果一个线程要获取monitor的锁，就看看他的计数器是不是0，如果是0的话，那么说明没人获取锁，他就可以获取锁了，然后对计数器加1加锁成功。
- 而对象头是synchronized实现锁的基础，因为synchronized申请锁、上锁、释放锁都与对象头有关。对象头其中一个重要部分Mark  Word存储对象的hashCode、锁信息或分代年龄或GC标志等信息，锁总共有四个状态，分别为无锁状态、偏向锁、轻量级锁、重量级锁，锁的类型和状态在对象头Mark Word中都有记录，在申请锁、锁升级等过程中JVM都需要读取对象的Mark Word数据。java对象主要组成如下:

![image-20220115141738992](http://www.itxiaoshen.com:3001/assets/1642227808232bTybzTHn.png)

而对象头Mark Word组成如下：

![image-20220115142308002](http://www.itxiaoshen.com:3001/assets/1642227810847mTaWPPs2.png)

### 1.5 volatile

volatile原理有volatile修饰的共享变量进行写操作的时候会多出Lock前缀的指令，该指令在多核处理器下会引发两件事情。

- 将当前处理器缓存行数据刷写到系统主内存。
- 这个刷写回主内存的操作会使其他CPU缓存的该共享变量内存地址的数据无效。

这样就保证了多个处理器的缓存是一致的，对应的处理器发现自己缓存行对应的内存地址被修改，就会将当前处理器缓存行设置无效状态，当处理器对这个数据进行修改操作的时候会重新从主内存中把数据读取到缓存里。例如在Jdk7的并发包里新增了一个队列集合类LinkedTransferQueue，它在使用volatile变量的时候，会采用一种将字节追加到64字节的方法来提高性能。那为什么追加到64字节能够优化性能呢？这是因为在很多处理器中它们的L1、L2、L3缓存的高速缓存行都是64字节宽，不支持填充缓存行，例如，现在有两个不足64字节的变量AB，那么在AB变量写入缓存行时会将AB变量的部分数据一起写入一个缓存行中，那么在CPU1和CPU2想同时访问AB变量时是无法实现的，也就是想同时访问一个缓存行的时候会引起冲突，如果可以填充到64字节，AB两个变量会分别写入到两个缓存行中，这样就可以并发，同时进行变量访问，从而提高效率。

## 2 Disruptor实战

### 2.1 概述

Disruptor是LMAX公司LMAX Development  Team开源的高性能内存队列，是一个高性能线程间消息传递库，提供并发环缓冲数据结构的库；它的设计目的是在异步事件处理体系结构中提供低延迟、高吞吐量的工作队列。它能够让开发人员只需写单线程代码，就能够获得非常强悍的性能表现，同时避免了写并发编程的难度和坑； 其本质思想在于多线程未必比单线程跑的快。

### 2.2 缓存行

- CPU 为了更快的执行代码，当从内存中读取数据时并不是只读自己想要的部分，  而是读取足够的字节来填入高速缓存行。根据不同的 CPU  ，高速缓存行大小不同，有32个字节和64个字节处。这样，当CPU访问相邻的数据时，就不必每次都从内存中读取，提高了速度，这是因为访问内存要比访问高速缓存用的时间多得多。这个缓存是CPU内部自己的缓存，内部的缓存单位是行，叫做缓存行。
- 当CPU尝试访问某个变量时，会先在L1  Cache中查找，如果命中缓存则直接使用；如果没有找到，就去下一级，一直到内存，随后将该变量所在的一个Cache行大小的区域复制到Cache中。查找的路线越长，速度也越慢，因此频繁访问的数据应当保持在L1Cache中。另外，一个变量的大小往往小于一个Cache行的大小，这时就有可能把多个变量放到一个Cache行中。下面代码举例数组命中缓存行和随机读写执行耗时差异：

```
package cn.itxs.disruptor;

public class CacheMain {
    private static final int ARR_SIZE = 20000;
    public static void main(String[] args) {
        int[][] arrInt = new int[ARR_SIZE][ARR_SIZE];
        long startTime = System.currentTimeMillis();
        // 第一种情况为顺序访问，一次访问后，后面的多次访问都可以命中缓存
        for (int i = 0; i < ARR_SIZE; i++) {
            for (int j = 0; j < ARR_SIZE; j++) {
                arrInt[i][j] = i * j;
            }
        }
        long endTime = System.currentTimeMillis();
        System.out.println("顺序访问耗时" + (endTime - startTime) + "毫秒");

        startTime = System.currentTimeMillis();
        // 第二情况为随机访问，每次都无法命中缓存行
        for (int i = 0; i < ARR_SIZE; i++) {
            for (int j = 0; j < ARR_SIZE; j++) {
                arrInt[j][i] = i * j;
            }
        }
        endTime = System.currentTimeMillis();
        System.out.println("随机访问耗时" + (endTime - startTime) + "毫秒");

    }
}
```

![image-20220117160149641](http://www.itxiaoshen.com:3001/assets/1642406516717NsNDXx0Q.png)

### 2.3 伪共享

当CPU执行完后还需要将数据回写到主内存上以便于其它线程可以从主内存中获取最新的数据。假设两个线程都加载了相同的CacheLine即缓存行数据

- 数据 A、B、C 被加载到同一个 Cache line，假设线程 1 在 core1 中修改 A，线程 2 在 core2 中修改 B。
- 线程 1 首先对 A 进行修改，这时 core1 会告知其它 CPU 核，当前引用同一地址的 Cache line  已经无效，随后 core2 发起修改 B，会导致 core1 将数据回写到主内存中，core2 这时会重新从主内存中读取该 Cache line 数据。
- 可见，如果同一个CacheLine的内容被多个线程读取，就会产生相互竞争，频繁回写主内存，降低了性能。

![image-20220117162122630](http://www.itxiaoshen.com:3001/assets/1642407685788D74FWPyR.png)

### 2.4 核心概念

- Ring Buffer：环形缓冲区通常被认为是Disruptor的主要点。但从3.0开始Ring Buffer只负责存储和更新通过Disruptor移动的数据(事件)，对于一些高级用例，它甚至可以完全被用户替换。
- Sequence：Disruptor使用序列作为一种方法来识别特定组件的位置。每个消费者(事件处理器)维护一个序列，就像中断器本身一样。大多数并发代码依赖于这些Sequence值的移动，因此Sequence支持AtomicLong的许多当前特性。事实上，两者之间唯一的真正区别是，Sequence包含了额外的功能，以防止Sequence和其他值之间的错误共享。
- Sequencer：是Disruptor的真正核心。该接口的两种实现(单一生产者和多生产者)实现了所有并行算法，以便在生产者和消费者之间快速、正确地传递数据。
- Sequence Barrier：产生了一个序列屏障，其中包含了对Sequencer中发布的主序列的引用和任何依赖消费者的序列的引用。它包含确定是否有任何事件可供使用者处理的逻辑。
- Wait Strategy：等待策略决定了消费者将如何等待事件被生产者放置到破坏者，如SleepingWaitStrategy、YieldingWaitStrategy、BlockingWaitStrategy、BusySpinWaitStrategy等。
- Event：从生产者传递到消费者的数据单位。事件没有特定的代码表示，因为它完全由用户定义。
- Event Processor：处理来自Disruptor的事件的主事件循环，并拥有消费者序列的所有权。有一种称为BatchEventProcessor的表示，它包含事件循环的有效实现，并将回调到使用过的EventHandler接口的提供实现。
- Event Handler：由用户实现的接口，代表Disruptor的消费者。
- Producer：这是用户代码调用Disruptor来排队事件。

![image-20220117170729044](http://www.itxiaoshen.com:3001/assets/1642410451632yyrQbMR8.png)

### 2.5 设计要点

- 内存分配更加合理，使用RingBuffer数据结构，数组元素在初始化时一次性全部创建，提升缓存命中率。
- 对象循环利用，避免频繁 GC。
- 能够避免伪共享，提升缓存利用率。Disruptor为了解决伪共享问题，使用的方法是缓存行填充，这是一种以空间换时间的策略，主要思想就是通过往对象中填充无意义的变量，来保证整个对象独占缓存行。而JDK8之后也提供了一个@Contended注解，使用它就可以进行自动填充，使用时需要在启动时增加一个JVM参数。
- 采用无锁算法，避免频繁加锁、解锁的性能消耗。支持批量消费，消费者可以无锁方式消费多个消息。
- 有相对更多的等待策略实现。

### 2.6 示例代码（多生产者多消费者）

pom文件引入disruptor的依赖

```
    <dependency>
      <groupId>com.lmax</groupId>
      <artifactId>disruptor</artifactId>
      <version>3.4.4</version>
    </dependency>
```

事件类LongEvent.java

```
package cn.itxs.disruptor;

public class LongEvent
{
    private long value;

    public void set(long value)
    {
        this.value = value;
    }

    @Override
    public String toString() {
        return "LongEvent{" +
                "value=" + value +
                '}';
    }
}
```

事件工厂类EventFactory.java

```
package cn.itxs.disruptor;

import com.lmax.disruptor.EventFactory;

public class LongEventFactory implements EventFactory<LongEvent> {

    @Override
    public LongEvent newInstance() {
        return new LongEvent();
    }
}
```

事件处理实现类，也即是消费者,这里实现EventHandler接口，也即是每个消费者都消费相同数量的生产者数据，LongEventHandler.java

```
package cn.itxs.disruptor;

import com.lmax.disruptor.EventHandler;

public class LongEventHandler implements EventHandler<LongEvent> {
    public static long count = 0;

    @Override
    public void onEvent(LongEvent event, long sequence, boolean endOfBatch) {
        count ++;
        System.out.println("[" + Thread.currentThread().getName() + "]" + event + "消费序号：" + sequence + ",event=" + event.toString());
    }
}
```

测试类

```
package cn.itxs.disruptor;

import com.lmax.disruptor.RingBuffer;
import com.lmax.disruptor.SleepingWaitStrategy;
import com.lmax.disruptor.dsl.Disruptor;
import com.lmax.disruptor.dsl.ProducerType;

import java.util.concurrent.*;

public class DisruptorMain {
    public static void main(String[] args) throws InterruptedException {
        // The factory for the event
        LongEventFactory factory = new LongEventFactory();

        // Specify the size of the ring buffer, must be power of 2.
        int bufferSize = 1024*1024;

        // Construct the Disruptor
        Disruptor<LongEvent> disruptor = new Disruptor<>(factory, bufferSize, Executors.defaultThreadFactory(),
                ProducerType.MULTI, new SleepingWaitStrategy());

        // Connect the handlers
        LongEventHandler h1 = new LongEventHandler();
        LongEventHandler h2 = new LongEventHandler();
        disruptor.handleEventsWith(h1, h2);

        // Start the Disruptor, starts all threads running
        disruptor.start();

        // Get the ring buffer from the Disruptor to be used for publishing.
        RingBuffer<LongEvent> ringBuffer = disruptor.getRingBuffer();

        //================================================================================================
        final int threadCount = 3;
        CyclicBarrier barrier = new CyclicBarrier(threadCount);
        ExecutorService service = Executors.newCachedThreadPool();
        for (long i = 0; i < threadCount; i++) {
            final long threadNum = i;
            service.submit(()-> {
                System.out.printf("Thread %s ready to start!\n", threadNum );
                try {
                    barrier.await();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                } catch (BrokenBarrierException e) {
                    e.printStackTrace();
                }

                for (int j = 0; j < 2; j++) {
                    final int seq = j;
                    ringBuffer.publishEvent((event, sequence) -> {
                        event.set(seq);
                        System.out.println(threadNum + "线程生产了序号为" + sequence + ",消息为" + seq);
                    });
                }
            });
        }                 
        service.shutdown();
        TimeUnit.SECONDS.sleep(3);
        System.out.println(LongEventHandler.count);
    }
}       
```

![image-20220117183016502](http://www.itxiaoshen.com:3001/assets/16424682505474Sf8disH.png)

事件处理实现类实现WorkHandler接口，也即是多个消费者合起来消费一份生产者数据，LongEventHandler.java

```
package cn.itxs.disruptor;

import com.lmax.disruptor.WorkHandler;

public class LongEventHandlerWorker implements WorkHandler<LongEvent> {
    public static long count = 0;

    @Override
    public void onEvent(LongEvent longEvent) throws Exception {
        count ++;
        System.out.println("[" + Thread.currentThread().getName() + "]" + "event=" + longEvent.toString());
    }
}
```

测试类

```
package cn.itxs.disruptor;

import com.lmax.disruptor.RingBuffer;
import com.lmax.disruptor.SleepingWaitStrategy;
import com.lmax.disruptor.dsl.Disruptor;
import com.lmax.disruptor.dsl.ProducerType;

import java.util.concurrent.*;

public class DisruptorWorkerMain {
    public static void main(String[] args) throws InterruptedException {
        // The factory for the event
        LongEventFactory factory = new LongEventFactory();

        // Specify the size of the ring buffer, must be power of 2.
        int bufferSize = 1024*1024;

        // Construct the Disruptor
        Disruptor<LongEvent> disruptor = new Disruptor<>(factory, bufferSize, Executors.defaultThreadFactory(),
                ProducerType.MULTI, new SleepingWaitStrategy());

        // Connect the handlers

        // 创建10个消费者来处理同一个生产者发的消息(这10个消费者不重复消费消息)
        LongEventHandlerWorker[] longEventHandlerWorkers = new LongEventHandlerWorker[4];
        for (int i = 0; i < longEventHandlerWorkers.length; i++) {
            longEventHandlerWorkers[i] = new LongEventHandlerWorker();
        }
        disruptor.handleEventsWithWorkerPool(longEventHandlerWorkers);

        // Start the Disruptor, starts all threads running
        disruptor.start();

        // Get the ring buffer from the Disruptor to be used for publishing.
        RingBuffer<LongEvent> ringBuffer = disruptor.getRingBuffer();

        //================================================================================================
        final int threadCount = 3;
        CyclicBarrier barrier = new CyclicBarrier(threadCount);
        ExecutorService service = Executors.newCachedThreadPool();
        for (long i = 0; i < threadCount; i++) {
            final long threadNum = i;
            service.submit(()-> {
                System.out.printf("Thread %s ready to start!\n", threadNum );
                try {
                    barrier.await();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                } catch (BrokenBarrierException e) {
                    e.printStackTrace();
                }

                for (int j = 0; j < 2; j++) {
                    final int seq = j;
                    ringBuffer.publishEvent((event, sequence) -> {
                        event.set(seq);
                        System.out.println(threadNum + "线程生产了序号为" + sequence + ",消息为" + seq);
                    });
                }
            });
        }

        service.shutdown();
        TimeUnit.SECONDS.sleep(3);
        System.out.println(LongEventHandlerWorker.count);
    }
}
```