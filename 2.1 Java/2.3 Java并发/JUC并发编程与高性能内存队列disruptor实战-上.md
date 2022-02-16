- [JUC并发编程与高性能内存队列disruptor实战-上](http://www.itxiaoshen.com/#/info?blogOid=63)

## 1 JUC并发实战

### 1.1 Synchonized与Lock

### 1.2 区别

- Synchronized是Java的关键字，由JVM层面实现的，Lock是一个接口，有实现类，由JDK实现。
- Synchronized无法获取锁的状态，Lock可以判断是否获取到了锁。
- Synchronized自动释放锁，lock一般在finally中手动释放，如果不释放锁，会死锁。
- Synchronized 线程1(获得锁，阻塞)，线程2(等待，傻傻的等)； lock锁不一定会等待下去(lock.tryLock())
- Synchronized是可重入的，不可中断的，非公平锁。Lock, 可重入锁，可以判断锁，非公平锁。
- Synchronized 适合锁少量的代码同步问题，Lock适合锁大量的同步代码。

### 1.3 代码示例

高铁票类synchronized实现TicketS.java，对于线程来说也属于资源类

```
package cn.itxs.synchronize;

public class TicketS {
    private int quantify = 20;
    public synchronized void sale(){
        if (quantify > 0) {
            System.out.println("当前线程"+Thread.currentThread().getName() + "卖出了第" + quantify-- + "张高铁票，剩余票数量为" + quantify);
        }
    }
}
```

高铁票类Lock实现TicketL.java

```
package cn.itxs.synchronize;

import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

public class TicketL {
    private int quantify = 20;
    private Lock lock = new ReentrantLock();
    public void sale(){
        lock.lock();
        try {
            if (quantify > 0) {
                System.out.println("当前线程"+Thread.currentThread().getName() + "卖出了第" + quantify-- + "张高铁票，剩余票数量为" + quantify);
            }
        }catch (Exception e) {
            e.printStackTrace();
        }finally {
            lock.unlock();
        }
    }
}
```

测试类,下面线程的使用采用lambda表达式写法，属于JDK8的特性之一

```
package cn.itxs.synchronize;

public class ThreadMain {
    public static void main(String[] args) {
        TicketS ticketS = new TicketS();
        System.out.println("ticketS-----------");
        new Thread(() -> {
            for (int i = 1; i < 30; i++) {
                ticketS.sale();
            }
        },"第一个线程").start();

        new Thread(() -> {
            for (int i = 1; i < 30; i++) {
                ticketS.sale();
            }
        },"第二个线程").start();

        new Thread(() -> {
            for (int i = 1; i < 30; i++) {
                ticketS.sale();
            }
        },"第三个线程").start();

        System.out.println("ticketL-----------");

        TicketL ticketL = new TicketL();
        new Thread(() -> {
            for (int i = 1; i < 30; i++) {
                ticketL.sale();
            }
        },"第一个线程").start();

        new Thread(() -> {
            for (int i = 1; i < 30; i++) {
                ticketL.sale();
            }
        },"第二个线程").start();

        new Thread(() -> {
            for (int i = 1; i < 30; i++) {
                ticketL.sale();
            }
        },"第三个线程").start();
    }
}
```

## 2 虚假唤醒

### 2.1 概述

- 虚假唤醒是指当一定的条件触发时会唤醒很多在阻塞态的线程，但只有部分的线程唤醒是有用的，其余线程的唤醒是多余的；比如说卖货，如果本来没有货物，突然进了一件货物，这时所有的顾客都被通知了，但是只能一个人买，所以对其他人都是做了无用的通知。

### 2.2 代码示例

计算类，提供加一减一的0和1结果，Counter.java

```
package cn.itxs.counter;

public class Counter {
    private int count = 0;

    public synchronized void addCount() throws InterruptedException {
        if (count > 0){
            //线程开始等待
            this.wait();
        }
        count++;
        System.out.println("当前线程为" + Thread.currentThread().getName() + ",count=" + count);
        //通知其他线程
        this.notifyAll();
    }

    public synchronized void subtractCount() throws InterruptedException {
        if (count == 0){
            //线程开始等待
            this.wait();
        }
        count--;
        System.out.println("当前线程为" + Thread.currentThread().getName() + ",count=" + count);
        //通知其他线程
        this.notifyAll();
    }
}
```

测试类

```
package cn.itxs.counter;

public class CounterMain {
    public static void main(String[] args) {
        Counter counter = new Counter();
        new Thread(() -> {
            for (int i = 1; i < 10; i++) {
                try {
                    counter.addCount();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        },"第一个线程").start();

        new Thread(() -> {
            for (int i = 1; i < 10; i++) {
                try {
                    counter.subtractCount();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        },"第二个线程").start();

        new Thread(() -> {
            for (int i = 1; i < 10; i++) {
                try {
                    counter.addCount();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        },"第三个线程").start();

        new Thread(() -> {
            for (int i = 1; i < 10; i++) {
                try {
                    counter.subtractCount();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        },"第四个线程").start();
    }
}
```

![image-20220114141728250](http://www.itxiaoshen.com:3001/assets/1642141052489T8iDzyCY.png)

从上面分析可以知道导致虚假唤醒的原因主要就是一个线程直接在if代码块中被唤醒了，这时它已经跳过了if判断。我们只需要将if判断改为while，这样线程就会被重复判断而不再会跳出判断代码块，从而不会产生虚假唤醒这种情况了。

![image-20220114142359979](http://www.itxiaoshen.com:3001/assets/1642141442067Y6neaTC3.png)

## 3 Callable

Callable任务可拿到一个Future对象,表示异步计算的结果,它提供了检查是否计算完成的方法,以等待计算的完成,并检索计算的结果,通过Future对象可以了解任务执行情况,可以取消任务的执行,还可以获取执行结果。

- Runnable和Callable的区别
  - Callable规定的方法是call(),Runnable规定的接口是run();
  - Callable的任务执行后可返回值,而Runnable的任务是不能有返回值的;
  - call方法可以抛出异常,run方法不可以

实现Callable接口资源类MessageThread.java

```
package cn.itxs.collection;

import java.util.concurrent.Callable;
import java.util.concurrent.TimeUnit;

public class MessageThread implements Callable<Integer> {
    @Override
    public Integer call() throws Exception {
        System.out.println("hello callable!");
        TimeUnit.SECONDS.sleep(3);
        return 100;
    }
}
```

测试类

```
package cn.itxs.collection;

import java.util.concurrent.ExecutionException;
import java.util.concurrent.FutureTask;

public class CallableMain {
    public static void main(String[] args) throws ExecutionException, InterruptedException {
        MessageThread messageThread = new MessageThread();
        FutureTask futureTask = new FutureTask(messageThread);
        new Thread(futureTask,"FutureTaskTest").start();
        Integer res = (Integer)futureTask.get();
        System.out.println(res);
    }
}
```

## 4 异步回调

```
package cn.itxs.asyncall;

import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;

public class AsynCallMain {
    public static void main(String[] args) throws ExecutionException, InterruptedException {
        CompletableFuture<Void> completableFuture = CompletableFuture.runAsync(() -> {
            try {
                TimeUnit.SECONDS.sleep(3);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            System.out.println(Thread.currentThread().getName() + ",async call void");
        });
        System.out.println("等待线程异步执行");
        completableFuture.get();

        CompletableFuture<String> completableFutureR = CompletableFuture.supplyAsync(() -> {
            try {
                TimeUnit.SECONDS.sleep(3);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            //int i = 1/0; //取消注释后下面e输出详细信息，返回值为bad
            System.out.println(Thread.currentThread().getName() + ",async call return");
            return "good";
        });
        System.out.println("等待线程异步执行");
        System.out.println(completableFutureR.whenComplete((s, e) -> {
            System.out.println("s=" + s + ",e=" + e);
        }).exceptionally((e) -> {
            System.out.println(e.getMessage());
            return "bad";
        }).get());
    }
}
```

![image-20220115230203289](http://www.itxiaoshen.com:3001/assets/1642258955150zdxwdzMC.png)

## 5 Lock+Condition

### 5.1 代码示例

先将上一小节改造为Lock+Condition版本下CounterL.java

```
package cn.itxs.counter;

import java.util.concurrent.locks.Condition;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

public class CounterL {
    private int count = 0;
    private Lock lock = new ReentrantLock();
    private Condition condition = lock.newCondition();

    public void addCount() throws InterruptedException {
        lock.lock();
        try {
            while (count > 0){
                //线程开始等待
                condition.await();
            }
            count++;
            System.out.println("当前线程为" + Thread.currentThread().getName() + ",count=" + count);
            //通知其他线程
            condition.signalAll();
        }catch (Exception e){
            e.printStackTrace();
        }finally {
            lock.unlock();
        }
    }

    public void subtractCount() throws InterruptedException {
        lock.lock();
        try {
            while (count == 0){
                //线程开始等待
                condition.await();
            }
            count--;
            System.out.println("当前线程为" + Thread.currentThread().getName() + ",count=" + count);
            //通知其他线程
            condition.signalAll();
        }catch (Exception e){
            e.printStackTrace();
        }finally {
            lock.unlock();
        }
    }
}
```

和上面的执行结果是一样，但Lock+Condition可以实现精准的唤醒

CounterA.java

```
package cn.itxs.counter;

import java.util.concurrent.locks.Condition;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

public class CounterA {
    private int count = 1;
    private Lock lock = new ReentrantLock();
    private Condition condition1 = lock.newCondition();
    private Condition condition2 = lock.newCondition();
    private Condition condition3 = lock.newCondition();

    public void testMethod1() throws InterruptedException {
        lock.lock();
        try {
            while (count != 1){
                //线程开始等待
                condition1.await();
            }
            count = 2;
            System.out.println("当前线程为" + Thread.currentThread().getName() + ",testMethod1 count=" + count);
            //通知其他线程
            condition2.signal();
        }catch (Exception e){
            e.printStackTrace();
        }finally {
            lock.unlock();
        }
    }

    public void testMethod2() throws InterruptedException {
        lock.lock();
        try {
            while (count != 2){
                //线程开始等待
                condition2.await();
            }
            count = 3;
            System.out.println("当前线程为" + Thread.currentThread().getName() + ",testMethod2 count=" + count);
            //通知其他线程
            condition3.signal();
        }catch (Exception e){
            e.printStackTrace();
        }finally {
            lock.unlock();
        }
    }

    public void testMethod3() throws InterruptedException {
        lock.lock();
        try {
            while (count != 3){
                //线程开始等待
                condition3.await();
            }
            count = 1;
            System.out.println("当前线程为" + Thread.currentThread().getName() + ",testMethod3 count=" + count);
            //通知其他线程
            condition1.signal();
        }catch (Exception e){
            e.printStackTrace();
        }finally {
            lock.unlock();
        }
    }
}
```

测试类

```
package cn.itxs.counter;

public class CounterAMain {

    public static void main(String[] args) {
        CounterA counterA = new CounterA();
        new Thread(() -> {
            for (int i = 1; i < 10; i++) {
                try {
                    counterA.testMethod1();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        },"第一个线程").start();

        new Thread(() -> {
            for (int i = 1; i < 10; i++) {
                try {
                    counterA.testMethod2();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        },"第二个线程").start();

        new Thread(() -> {
            for (int i = 1; i < 10; i++) {
                try {
                    counterA.testMethod3();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        },"第三个线程").start();
    }
}
```

![image-20220114160512200](http://www.itxiaoshen.com:3001/assets/16421475160684SA5Gj2B.png)

## 6 锁的常识

```
package cn.itxs.lock;

import java.util.concurrent.TimeUnit;

public class Sport {
    public synchronized void playBasketBall(){
        try {
            TimeUnit.SECONDS.sleep(5);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        System.out.println(Thread.currentThread().getName() + "打篮球");
    }

    public synchronized void swimming(){
        System.out.println(Thread.currentThread().getName() + "去游泳");
    }

    //普通方法
    public void dancing(){
        System.out.println(Thread.currentThread().getName() + "去跳舞");
    }

    public synchronized void singing(){
        System.out.println(Thread.currentThread().getName() + "去K歌");
    }

    //静态同步方法
    public static synchronized void skating(){
        try {
            TimeUnit.SECONDS.sleep(3);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        System.out.println(Thread.currentThread().getName() + "去滑冰");
    }

    //静态同步方法
    public static synchronized void climbing(){
        try {
            TimeUnit.SECONDS.sleep(2);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        System.out.println(Thread.currentThread().getName() + "去登山");
    }

    public synchronized void shooting(){
        System.out.println(Thread.currentThread().getName() + "去射击");
    }
}
```

测试类

```
package cn.itxs.lock;

public class LockDemo {
    public static void main(String[] args) {
        Sport sport = new Sport();
        Sport sport1 = new Sport();
        Sport sport2 = new Sport();
        Sport sport3 = new Sport();
        Sport sport4 = new Sport();
        new Thread(() -> {
            sport.playBasketBall();
        },"第一个线程").start();

        new Thread(() -> {
            sport.swimming();
        },"第二个线程").start();

        new Thread(() -> {
            sport.dancing();
        },"第三个线程").start();

        new Thread(() -> {
            sport1.swimming();
        },"第四个线程").start();

        new Thread(() -> {
            sport2.skating();
        },"第五个线程").start();

        new Thread(() -> {
            sport3.climbing();
        },"第六个线程").start();

        new Thread(() -> {
            sport3.shooting();
        },"第七个线程").start();
    }
}
```

![image-20220114171253621](http://www.itxiaoshen.com:3001/assets/1642151578347sRPr4cBm.png)

从上面的结果我们可以知道synchronized锁的是方法的调用者，对于同一对象同步方法谁先拿到锁先执行，而不同对象如sport和sport1是两个对象相当于两把锁，互不相干；对于static同步方法锁的是class，两个对象的类class只有一个，相同对象的类的静态同步方法也是谁先拿到锁先执行；对于同一对象的静态同步方法和同步方法属于class和对象也是两把锁，互不相干。

## 7 并发集合类

### 7.1 CopyOnWriteArrayList

![image-20220114172351216](http://www.itxiaoshen.com:3001/assets/1642152233068GiR48k3N.png)

```
package cn.itxs.collection;

import java.util.*;
import java.util.concurrent.CopyOnWriteArrayList;

public class ListDemo {
    public static void main(String[] args) {
        //ArrayList不是线程安全
        //List<String> list = new ArrayList<String>();
        //List<String> list = new Vector<>(); //第一种方法，这种是集合方法加了synchronized变为同步方法
        //List<String> list = Collections.synchronizedList(new ArrayList<String>()); //第二种方法，将ArrayList通过Collections工具类转为同步集合
        List<String> list = new CopyOnWriteArrayList<>();
        for (int i = 0; i < 50; i++) {
            new Thread(() -> {
                list.add(UUID.randomUUID().toString());
                System.out.println(list);
            },String.valueOf(i)+"线程").start();
        }
    }
}
```

### 7.2 CopyOnWriteArraySet

```
package cn.itxs.collection;

import java.util.*;
import java.util.concurrent.CopyOnWriteArraySet;

public class SetDemo {
    public static void main(String[] args) {
        //HashSet不是线程安全
        //Set<String> set = new HashSet<>();
        //Set<String> set = Collections.synchronizedSet(new HashSet<String>()); //将HashSet通过Collections工具类转为同步集合
        Set<String> set= new CopyOnWriteArraySet<>();
        for (int i = 0; i < 50; i++) {
            new Thread(() -> {
                set.add(UUID.randomUUID().toString());
                System.out.println(set);
            },String.valueOf(i)+"线程").start();
        }
    }
}
```

### 7.3 ConcurrentHashMap

```
package cn.itxs.collection;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

public class MapDemo {
    public static void main(String[] args) {
        //HashMap不是线程安全
        //Map<String,String> map = new HashMap<>();
        Map<String,String> map = new ConcurrentHashMap<>();
        for (int i = 0; i < 50; i++) {
            new Thread(() -> {
                map.put(UUID.randomUUID().toString(),UUID.randomUUID().toString());
                System.out.println(map);
            },String.valueOf(i)+"线程").start();
        }
    }
}
```

## 8 并发编程辅助类

### 8.1 CountDowmLatch

CountDownLatch一般被称作"计数器"，当数量达到了某个点之后计数结束，才能继续往下走，可用于*\*流程控制\，大流程分成多个子流程，然后大流程在子流程全部结束之前不动（子流程最好是相互独立的，除非能很好的控制两个流程的关联关系），子流程全部结束后大流程开始操作。

```
package cn.itxs.tool;

import java.util.concurrent.CountDownLatch;

public class CDLMain {
    public static void main(String[] args) throws InterruptedException {
        CountDownLatch countDownLatch = new CountDownLatch(10);
        for (int i = 1; i <= 10; i++) {
            new Thread(() -> {
                System.out.println(Thread.currentThread().getName() + "进入核酸检测排队区域");
                countDownLatch.countDown();
            },String.valueOf(i)).start();
        }
        countDownLatch.await();
        System.out.println("开始进行一组核酸监测");
    }
}
```

### 8.2 CyclicBarrier

CyclicBarrier通过它可以实现让一组线程等待至某个状态之后再全部同时执行。叫做回环是因为当所有等待线程都被释放以后，CyclicBarrier可以被重用。

```
package cn.itxs.tool;

import java.util.concurrent.BrokenBarrierException;
import java.util.concurrent.CyclicBarrier;
import java.util.concurrent.TimeUnit;

public class CBMain {
    public static void main(String[] args) throws InterruptedException {
        CyclicBarrier cyclicBarrier = new CyclicBarrier(5,() -> {
            System.out.println("集齐五福兑取大奖");
        });

        for (int i = 1; i < 6; i++) {
            final int count = i;
            new Thread(() -> {
                System.out.println(Thread.currentThread().getName() + ",获取到第" + count + "种福");
                try {
                    cyclicBarrier.await();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                } catch (BrokenBarrierException e) {
                    e.printStackTrace();
                }
            }).start();
        }

        TimeUnit.SECONDS.sleep(5);

        for (int i = 1; i < 6; i++) {
            final int count = i;
            new Thread(() -> {
                System.out.println(Thread.currentThread().getName() + ",获取到第" + count + "种福");
                try {
                    cyclicBarrier.await();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                } catch (BrokenBarrierException e) {
                    e.printStackTrace();
                }
            }).start();
        }
    }
}
```

### 8.3 Semaphore

Semaphore通常叫它信号量，  可以用来控制同时访问特定资源的线程数量，通过协调各个线程，以保证合理的使用资源.通常用于那些资源有明确访问数量限制的场景，常用于限流  。比如：数据库连接池，同时进行连接的线程有数量限制，连接不能超过一定的数量，当连接达到了限制数量后，后面的线程只能排队等前面的线程释放了数据库连接才能获得数据库连接。

```
package cn.itxs.tool;

import java.util.concurrent.Semaphore;
import java.util.concurrent.TimeUnit;

public class SemaphoreMain {
    public static void main(String[] args) {
        //最多同时处理4个请求
        Semaphore semaphore = new Semaphore(4);
        for (int i = 1; i <= 20; i++) {
            new Thread(() -> {
                try {
                    semaphore.acquire();
                    System.out.println(Thread.currentThread().getName() + "请求处理开始");
                    TimeUnit.SECONDS.sleep(3);
                    System.out.println(Thread.currentThread().getName() + "请求处理结束");
                } catch (InterruptedException e) {
                    e.printStackTrace();
                } finally {
                    semaphore.release();
                }
            },String.valueOf(i)).start();
        }
    }
}
```

## 9 队列

集合接口包含队列接口，常见的队列有阻塞队列和同步队列。

![image-20220115164705033](http://www.itxiaoshen.com:3001/assets/1642236435114BzeZ1W0B.png)

### 9.1 阻塞队列

阻塞队列存在四组API，分别对应着四种队列的阻塞情况。

![image-20220115172518602](http://www.itxiaoshen.com:3001/assets/1642238722754NX48pc58.png)

```
package cn.itxs.queue;

import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.TimeUnit;

public class BlockIngQueueMain {
    public static void main(String[] args) throws InterruptedException {
        System.out.println("异常抛出测试----------");
        BlockingQueue<String> arrayBlockingQueue = new ArrayBlockingQueue<>(3);
        arrayBlockingQueue.add("hello");
        arrayBlockingQueue.add("world");
        arrayBlockingQueue.add("java");
        //arrayBlockingQueue.add("queue"); //这里取消注释则会抛Queue full异常
        System.out.println(arrayBlockingQueue.element()); //获取队顶元素但不出队
        System.out.println(arrayBlockingQueue.remove());
        System.out.println(arrayBlockingQueue.remove());
        System.out.println(arrayBlockingQueue.remove());
        //System.out.println(arrayBlockingQueue.remove()); //这里取消注释且队列没有元素会抛NoSuchElementException异常
        //System.out.println(arrayBlockingQueue.element());  //这里取消注释会抛且队列没有元素NoSuchElementException异常

        System.out.println("返回值测试----------");
        BlockingQueue<String> arrayBlockingQueueR = new ArrayBlockingQueue<>(3);
        System.out.println(arrayBlockingQueueR.offer("hello"));
        System.out.println(arrayBlockingQueueR.offer("world"));
        System.out.println(arrayBlockingQueueR.offer("java"));
        System.out.println(arrayBlockingQueueR.offer("queue"));
        System.out.println(arrayBlockingQueueR.peek());
        System.out.println(arrayBlockingQueueR.poll());
        System.out.println(arrayBlockingQueueR.poll());
        System.out.println(arrayBlockingQueueR.poll());
        System.out.println(arrayBlockingQueueR.poll());
        System.out.println(arrayBlockingQueueR.peek());

        System.out.println("超时等待timeoout时间测试----------");
        BlockingQueue<String> arrayBlockingQueueT = new ArrayBlockingQueue<>(3);
        System.out.println(arrayBlockingQueueT.offer("hello"));
        System.out.println(arrayBlockingQueueT.offer("world"));
        System.out.println(arrayBlockingQueueT.offer("java"));
        System.out.println(arrayBlockingQueueT.offer("queue",3, TimeUnit.SECONDS));
        System.out.println(arrayBlockingQueueT.poll());
        System.out.println(arrayBlockingQueueT.poll());
        System.out.println(arrayBlockingQueueT.poll());
        System.out.println(arrayBlockingQueueT.poll(3, TimeUnit.SECONDS));

        System.out.println("一直阻塞测试----------");
        BlockingQueue<String> arrayBlockingQueueB = new ArrayBlockingQueue<>(3);
        arrayBlockingQueueB.put("hello");
        arrayBlockingQueueB.put("world");
        arrayBlockingQueueB.put("java");
        //arrayBlockingQueueB.put("queue");  //这里取消注释会一直阻塞
        System.out.println(arrayBlockingQueueB.take());
        System.out.println(arrayBlockingQueueB.take());
        System.out.println(arrayBlockingQueueB.take());
        System.out.println(arrayBlockingQueueB.take());  //当元素为空时一直阻塞
    }
}
```

### 9.2 同步队列

在同步队列中只有出队以后才允许入队，否则一直处于阻塞状态。

```
package cn.itxs.queue;

import java.util.concurrent.BlockingQueue;
import java.util.concurrent.SynchronousQueue;
import java.util.concurrent.TimeUnit;

public class SynchronousQueueMain {
    public static void main(String[] args) {
        BlockingQueue<String> synchronousQueue = new SynchronousQueue<>();
        new Thread(() -> {
            try {
                System.out.println(Thread.currentThread().getName()+"put hello");
                synchronousQueue.put("hello");
                System.out.println(Thread.currentThread().getName()+"put world");
                synchronousQueue.put("world");
                System.out.println(Thread.currentThread().getName()+"put java");
                synchronousQueue.put("java");
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        },"入队线程").start();

        new Thread(() -> {
            try {
                System.out.println(Thread.currentThread().getName()+"take hello");
                System.out.println(synchronousQueue.take());
                TimeUnit.SECONDS.sleep(3);
                System.out.println(Thread.currentThread().getName()+"take world");
                System.out.println(synchronousQueue.take());
                TimeUnit.SECONDS.sleep(3);
                System.out.println(Thread.currentThread().getName()+"take java");
                System.out.println(synchronousQueue.take());
                TimeUnit.SECONDS.sleep(3);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        },"出队线程").start();
    }
}
```

![image-20220115174848718](http://www.itxiaoshen.com:3001/assets/16422401354738Xri2RBm.png)

## 10 CAS

- CAS：Compare And Swap，直译为比较并交换；CAS是CPU并发原语，由CPU实现；通过比较当前内存中的值和主内存中的值，如果这个值是期望的，那么则执行，如果不是就一直循环下去。
- CAS也称为自旋锁，在一个（死）循环【for(;;)】里不断进行CAS操作，直到成功为止（自旋操作）,实际上CAS也是一种乐观。
- 缺点
  - 循环会耗时。
  - 一次只能保证一个共享变量的原子性。
  - ABA问题

```
package cn.itxs.cas;

import java.util.concurrent.atomic.AtomicInteger;

public class CASMain {
    public static void main(String[] args) {
        AtomicInteger atomicInteger = new AtomicInteger(100);
        System.out.println(atomicInteger.getAndIncrement()); //原子递增
        System.out.println(atomicInteger.get());
        //如果我期望的值达到了，那么就更新，否则，就不更新
        System.out.println(atomicInteger.compareAndSet(101, 200));
        System.out.println(atomicInteger.get());
        System.out.println(atomicInteger.compareAndSet(101, 300));
        System.out.println(atomicInteger.get());
        System.out.println("ABA-----");
        System.out.println(atomicInteger.compareAndSet(200, 300));
        System.out.println(atomicInteger.get());
        System.out.println(atomicInteger.compareAndSet(300, 200));
        System.out.println(atomicInteger.get());
        System.out.println(atomicInteger.compareAndSet(200, 0));
        System.out.println(atomicInteger.get());
    }
}
```

![image-20220115233031964](http://www.itxiaoshen.com:3001/assets/1642260637988N6zZkYAH.png)

```
package cn.itxs.cas;

import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicStampedReference;

public class ARMain {
    public static void main(String[] args) {
        AtomicStampedReference atomicStampedReference = new AtomicStampedReference(101,1);
        new Thread(()->{
            System.out.println(Thread.currentThread().getName() + "版本号为:"+atomicStampedReference.getStamp());
            try {
                TimeUnit.SECONDS.sleep(2);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }

            atomicStampedReference.compareAndSet(101, 102,
                    atomicStampedReference.getStamp(),
                    atomicStampedReference.getStamp()+1);

            System.out.println(Thread.currentThread().getName() + "版本号为:"+atomicStampedReference.getStamp());

            atomicStampedReference.compareAndSet(102, 101,
                    atomicStampedReference.getStamp(),
                    atomicStampedReference.getStamp()+1);

            System.out.println(Thread.currentThread().getName() + "版本号为:"+atomicStampedReference.getStamp());

        },"A").start();


        //和乐观锁的原理相同
        new Thread(()->{
            int stamp = atomicStampedReference.getStamp();
            System.out.println(Thread.currentThread().getName() + "版本号为:"+stamp);

            try {
                TimeUnit.SECONDS.sleep(5);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            System.out.println(atomicStampedReference.
                    compareAndSet(101, 105,stamp,stamp+1));

            System.out.println(Thread.currentThread().getName() + "版本号为:"+atomicStampedReference.getStamp());
        },"B").start();
    }
}
```