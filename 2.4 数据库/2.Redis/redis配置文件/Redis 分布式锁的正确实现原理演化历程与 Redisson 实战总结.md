- [Redis 分布式锁的正确实现原理演化历程与 Redisson 实战总结](https://mp.weixin.qq.com/s/vLQiqg8NzD-DCpfcCu-9Jw)

Redis 分布式锁使用 `SET` 指令就可以实现了么？在分布式领域 `CAP` 理论一直存在。

分布式锁的门道可没那么简单，我们在网上看到的分布式锁方案可能是有问题的。

一步步带你深入分布式锁是如何一步步完善，在高并发生产环境中如何正确使用分布式锁。

在进入正文之前，我们先带着问题去思考：

- 什么时候需要分布式锁？
- 加、解锁的代码位置有讲究么？
- 如何避免出现锁再也无法删除？
- 超时时间设置多少合适呢？
- 如何避免锁被其他线程释放
- 如何实现重入锁？
- 主从架构会带来什么安全问题？
- 什么是 `Redlock`
- Redisson 分布式锁最佳实战
- 看门狗实现原理
- ……



**什么时候用分布式锁？**

> ❝
>
> 码哥，说个通俗的例子讲解下什么时候需要分布式锁呢？

诊所只有一个医生，很多患者前来就诊。

医生在同一时刻只能给一个患者提供就诊服务。

如果不是这样的话，就会出现医生在就诊肾亏的「肖菜鸡」准备开药时候患者切换成了脚臭的「谢霸哥」，这时候药就被谢霸哥取走了。

治肾亏的药被有脚臭的拿去了。

当并发去读写一个【共享资源】的时候，我们为了保证数据的正确，需要控制同一时刻只有一个线程访问。

**分布式锁就是用来控制同一时刻，只有一个 JVM 进程中的一个线程可以访问被保护的资源。**

# 分布式锁入门

> ❝
>
> 65 哥：分布式锁应该满足哪些特性？

1. 互斥：在任何给定时刻，只有一个客户端可以持有锁；
2. 无死锁：任何时刻都有可能获得锁，即使获取锁的客户端崩溃；
3. 容错：只要大多数 `Redis`的节点都已经启动，客户端就可以获取和释放锁。

> ❝
>
> 码哥，我可以使用 `SETNX key value` 命令是实现「互斥」特性。

这个命令来自于`SET if Not eXists`的缩写，意思是：如果 `key` 不存在，则设置 `value` 给这个`key`，否则啥都不做。Redis 官方地址说的：

命令的返回值：

- 1：设置成功；
- 0：key 没有设置成功。

如下场景：

敲代码一天累了，想去放松按摩下肩颈。

168 号技师最抢手，大家喜欢点，所以并发量大，需要分布式锁控制。

同一时刻只允许一个「客户」预约 168 技师。

肖菜鸡申请 168 技师成功：

```
> SETNX lock:168 1
(integer) 1 # 获取 168 技师成功
```

谢霸哥后面到，申请失败：

```
> SETNX lock 2
(integer) 0 # 客户谢霸哥 2 获取失败
```

此刻，申请成功的客户就可以享受 168 技师的肩颈放松服务「共享资源」。

享受结束后，要及时释放锁，给后来者享受 168 技师的服务机会。

> ❝
>
> 肖菜鸡，码哥考考你如何释放锁呢？

很简单，使用 `DEL` 删除这个 `key` 就行。

```
> DEL lock:168
(integer) 1
```

> ❝
>
> 码哥，你见过「龙」么？我见过，因为我被一条龙服务过。

![图片](data:image/gif;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQImWNgYGBgAAAABQABh6FO1AAAAABJRU5ErkJggg==)

肖菜鸡，事情可没这么简单。

这个方案存在一个存在造成锁无法释放的问题，造成该问题的场景如下：

1. 客户端所在节点崩溃，无法正确释放锁；
2. 业务逻辑异常，无法执行 `DEL`指令。

这样，这个锁就会一直占用，锁在我手里，我挂了，这样其他客户端再也拿不到这个锁了。

# 超时设置

> ❝
>
> 码哥，我可以在获取锁成功的时候设置一个「超时时间」

比如设定按摩服务一次 60 分钟，那么在给这个 `key` 加锁的时候设置 60 分钟过期即可：

```
> SETNX lock:168 1  // 获取锁
(integer) 1
> EXPIRE lock:168 60  // 60s 自动删除
(integer) 1
```

这样，到点后锁自动释放，其他客户就可以继续享受 168 技师按摩服务了。

> ❝
>
> 谁要这么写，就糟透了。

「加锁」、「设置超时」是两个命令，他们不是原子操作。

**如果出现只执行了第一条，第二条没机会执行就会出现「超时时间」设置失败，依然出现锁无法释放。**

> ❝
>
> 码哥，那咋办，我想被一条龙服务，要解决这个问题

Redis 2.6.X 之后，官方拓展了 `SET` 命令的参数，满足了当 key 不存在则设置 value，同时设置超时时间的语义，并且满足原子性。

```
SET resource_name random_value NX PX 30000
```

- NX：表示只有 `resource_name` 不存在的时候才能 `SET` 成功，从而保证只有一个客户端可以获得锁；
- PX 30000：表示这个锁有一个 30 秒自动过期时间。

这样写还不够，我们还要防止不能释放不是自己加的锁。我们可以在 value 上做文章。

继续往下看……

# 释放了不是自己加的锁

> ❝
>
> 这样我能稳妥的享受一条龙服务了么？

No，还有一种场景会导致**释放别人的锁**：

1. 客户 1 获取锁成功并设置设置 30 秒超时；
2. 客户 1 因为一些原因导致执行很慢（网络问题、发生 FullGC……），过了 30 秒依然没执行完，但是锁过期「自动释放了」；
3. 客户 2 申请加锁成功；
4. 客户 1 执行完成，执行 `DEL` 释放锁指令，这个时候就把客户 2 的锁给释放了。

有个关键问题需要解决：自己的锁只能自己来释放。

> ❝
>
> 我要如何删除是自己加的锁呢？

在执行 `DEL` 指令的时候，我们要想办法检查下这个锁是不是自己加的锁再执行删除指令。

**解铃还须系铃人**

> ❝
>
> 码哥，我在加锁的时候设置一个「唯一标识」作为 `value` 代表加锁的客户端。`SET resource_name random_value NX PX 30000`
>
> 在释放锁的时候，客户端将自己的「唯一标识」与锁上的「标识」比较是否相等，匹配上则删除，否则没有权利释放锁。

伪代码如下：

```
// 比对 value 与 唯一标识
if (redis.get("lock:168").equals(random_value)){
   redis.del("lock:168"); //比对成功则删除
 }
```

> ❝
>
> 有没有想过，这是 `GET + DEL` 指令组合而成的，这里又会涉及到原子性问题。

我们可以通过 `Lua` 脚本来实现，这样判断和删除的过程就是原子操作了。

```
// 获取锁的 value 与 ARGV[1] 是否匹配，匹配则执行 del
if redis.call("get",KEYS[1]) == ARGV[1] then
    return redis.call("del",KEYS[1])
else
    return 0
end
```

这样通过唯一值设置成 value 标识加锁的客户端很重要，仅使用 DEL 是不安全的，因为一个客户端可能会删除另一个客户端的锁。

使用上面的脚本，每个锁都用一个随机字符串“签名”，只有当删除锁的客户端的“签名”与锁的 value 匹配的时候，才会删除它。

官方文档也是这么说的：`https://redis.io/topics/distlock`

这个方案已经相对完美，我们用的最多的可能就是这个方案了。

# 正确设置锁超时

> ❝
>
> 锁的超时时间怎么计算合适呢？

这个时间不能瞎写，一般要根据在测试环境多次测试，然后压测多轮之后，比如计算出平均执行时间 200 ms。

那么锁的**超时时间就放大为平均执行时间的 3~5 倍。**

> ❝
>
> 为啥要放放大呢？

因为如果锁的操作逻辑中有网络 IO 操作、JVM FullGC 等，线上的网络不会总一帆风顺，我们要给网络抖动留有缓冲时间。

> ❝
>
> 那我设置更大一点，比如设置 1 小时不是更安全？

不要钻牛角，多大算大？

设置时间过长，一旦发生宕机重启，就意味着 1 小时内，分布式锁的服务全部节点不可用。

你要让运维手动删除这个锁么？

只要运维真的不会打你。

> ❝
>
> 有没有完美的方案呢？不管时间怎么设置都不大合适。

我们可以让获得锁的线程开启一个**守护线程**，用来给快要过期的锁「续航」。

加锁的时候设置一个过期时间，同时客户端开启一个「守护线程」，定时去检测这个锁的失效时间。

**如果快要过期，但是业务逻辑还没执行完成，自动对这个锁进行续期，重新设置过期时间。**

> ❝
>
> 这个道理行得通，可我写不出。

别慌，已经有一个库把这些工作都封装好了他叫 **Redisson**。

在使用分布式锁时，它就采用了「自动续期」的方案来避免锁过期，这个守护线程我们一般也把它叫做「看门狗」线程。

> ❝
>
> 一路优化下来，方案似乎比较「严谨」了，抽象出对应的模型如下。

1. 通过 `SET lock_resource_name random_value NX PX expire_time`，同时启动守护线程为快要过期但还没执行完的客户端的锁续命;
2. 客户端执行业务逻辑操作共享资源；
3. 通过 `Lua` 脚本释放锁，先 get 判断锁是否是自己加的，再执行 `DEL`。

![图片](data:image/gif;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQImWNgYGBgAAAABQABh6FO1AAAAABJRU5ErkJggg==)

这个方案实际上已经比较完美，能写到这一步已经打败 90% 的程序猿了。

但是对于追求极致的程序员来说还远远不够：

1. 可重入锁如何实现？
2. 主从架构崩溃恢复导致锁丢失如何解决？
3. 客户端加锁的位置有门道么？

# 加解锁代码位置有讲究

根据前面的分析，我们已经有了一个「相对严谨」的分布式锁了。

于是「谢霸哥」就写了如下代码将分布式锁运用到项目中，以下是伪代码逻辑：

```
public void doSomething() {
  redisLock.lock(); // 上锁
    try {
        // 处理业务
        .....
        redisLock.unlock(); // 释放锁
    } catch (Exception e) {
        e.printStackTrace();
    }
}
```

> ❝
>
> 有没有想过：一旦执行业务逻辑过程中抛出异常，程序就无法执行释放锁的流程。

**所以释放锁的代码一定要放在 `finally{}` 块中。**

加锁的位置也有问题，放在 try 外面的话，如果执行 `redisLock.lock()` 加锁异常，但是实际指令已经发送到服务端并执行，只是客户端读取响应超时，就会导致没有机会执行解锁的代码。

所以 `redisLock.lock()` **应该写在 try 代码块，这样保证一定会执行解锁逻辑。**

综上所述，正确代码位置如下 ：

```
public void doSomething() {
    try {
        // 上锁
        redisLock.lock();
        // 处理业务
        ...
    } catch (Exception e) {
        e.printStackTrace();
    } finally {
      // 释放锁
      redisLock.unlock();
    }
}
```

# 实现可重入锁

> ❝
>
> 65 哥：可重入锁要如何实现呢？

当一个线程执行一段代码成功获取锁之后，继续执行时，又遇到加锁的代码，可重入性就就保证线程能继续执行，而不可重入就是需要等待锁释放之后，再次获取锁成功，才能继续往下执行。

用一段代码解释可重入：

```
public synchronized void a() {
    b();
}
public synchronized void b() {
    // pass
}
```

假设 X 线程在 a 方法获取锁之后，继续执行 b 方法，如果此时**不可重入**，线程就必须等待锁释放，再次争抢锁。

锁明明是被 X 线程拥有，却还需要等待自己释放锁，然后再去抢锁，这看起来就很奇怪，我释放我自己~

## Redis Hash 可重入锁

> ❝
>
> Redisson 类库就是通过 Redis Hash 来实现可重入锁

当线程拥有锁之后，往后再遇到加锁方法，直接将加锁次数加 1，然后再执行方法逻辑。

退出加锁方法之后，加锁次数再减 1，当加锁次数为 0 时，锁才被真正的释放。

可以看到可重入锁最大特性就是计数，计算加锁的次数。

所以当可重入锁需要在分布式环境实现时，我们也就需要统计加锁次数。

### 加锁逻辑

> ❝
>
> 我们可以使用 Redis hash 结构实现，key 表示被锁的共享资源， hash 结构的 fieldKey 的 value 则保存加锁的次数。

![图片](data:image/gif;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQImWNgYGBgAAAABQABh6FO1AAAAABJRU5ErkJggg==)

通过 Lua 脚本实现原子性，假设 KEYS1 = 「lock」, ARGV「1000，uuid」：

```
---- 1 代表 true
---- 0 代表 false
if (redis.call('exists', KEYS[1]) == 0) then
    redis.call('hincrby', KEYS[1], ARGV[2], 1);
    redis.call('pexpire', KEYS[1], ARGV[1]);
    return 1;
end ;
if (redis.call('hexists', KEYS[1], ARGV[2]) == 1) then
    redis.call('hincrby', KEYS[1], ARGV[2], 1);
    redis.call('pexpire', KEYS[1], ARGV[1]);
    return 1;
end ;
return 0;
```

加锁代码首先使用 Redis `exists` 命令判断当前 lock 这个锁是否存在。

如果锁不存在的话，直接使用 `hincrby`创建一个键为 `lock` hash 表，并且为 Hash 表中键为 `uuid` 初始化为 0，然后再次加 1，最后再设置过期时间。

如果当前锁存在，则使用 `hexists`判断当前 `lock` 对应的 hash 表中是否存在 `uuid` 这个键，如果存在，再次使用 `hincrby` 加 1，最后再次设置过期时间。

最后如果上述两个逻辑都不符合，直接返回。

### 解锁逻辑

```
-- 判断 hash set 可重入 key 的值是否等于 0
-- 如果为 0 代表 该可重入 key 不存在
if (redis.call('hexists', KEYS[1], ARGV[1]) == 0) then
    return nil;
end ;
-- 计算当前可重入次数
local counter = redis.call('hincrby', KEYS[1], ARGV[1], -1);
-- 小于等于 0 代表可以解锁
if (counter > 0) then
    return 0;
else
    redis.call('del', KEYS[1]);
    return 1;
end ;
return nil;
```

首先使用 `hexists` 判断 Redis Hash 表是否存给定的域。

如果 lock 对应 Hash 表不存在，或者 Hash 表不存在 uuid 这个 key，直接返回 `nil`。

若存在的情况下，代表当前锁被其持有，首先使用 `hincrby`使可重入次数减 1 ，然后判断计算之后可重入次数，若小于等于 0，则使用 `del` 删除这把锁。

解锁代码执行方式与加锁类似，只不过解锁的执行结果返回类型使用 `Long`。这里之所以没有跟加锁一样使用 `Boolean` ,这是因为解锁 lua 脚本中，三个返回值含义如下：

- 1 代表解锁成功，锁被释放
- 0 代表可重入次数被减 1
- `null` 代表其他线程尝试解锁，解锁失败.

# 主从架构带来的问题

> ❝
>
> 码哥，到这里分布式锁「很完美了」吧，没想到分布式锁这么多门道。

路还很远，之前分析的场景都是，锁在「单个」Redis 实例中可能产生的问题，并没有涉及到 Redis 主从模式导致的问题。

我们通常使用「[Cluster 集群」](https://mp.weixin.qq.com/s?__biz=MzkzMDI1NjcyOQ==&mid=2247487789&idx=1&sn=7f8245f8b4e4a98aa0a717011f7b7e24&scene=21#wechat_redirect)或者「[哨兵集群](https://mp.weixin.qq.com/s?__biz=MzkzMDI1NjcyOQ==&mid=2247487780&idx=1&sn=9a0ea0971e661556c4c5e438ab1b081b&scene=21#wechat_redirect)」的模式部署保证高可用。

这两个模式都是基于「[主从架构数据同步复制](https://mp.weixin.qq.com/s?__biz=MzkzMDI1NjcyOQ==&mid=2247487769&idx=1&sn=3c975ea118d4e59f72df5beed58f4768&scene=21#wechat_redirect)」实现的数据同步，而 Redis 的主从复制默认是异步的。

> ❝
>
> 以下内容来自于官方文档 https://redis.io/topics/distlock

我们试想下如下场景会发生什么问题：

1. 客户端 A 在 master 节点获取锁成功。
2. 还没有把获取锁的信息同步到 slave 的时候，master 宕机。
3. slave 被选举为新 master，这时候没有客户端 A 获取锁的数据。
4. 客户端 B 就能成功的获得客户端 A 持有的锁，违背了分布式锁定义的互斥。

虽然这个概率极低，但是我们必须得承认这个风险的存在。

> ❝
>
> Redis 的作者提出了一种解决方案，叫 Redlock（红锁）

Redis 的作者为了统一分布式锁的标准，搞了一个 Redlock，算是 Redis 官方对于实现分布式锁的指导规范，https://redis.io/topics/distlock，但是这个 Redlock 也被国外的一些分布式专家给喷了。

因为它也不完美，有“漏洞”。

# 什么是 Redlock

红锁是不是这个？

![图片](data:image/gif;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQImWNgYGBgAAAABQABh6FO1AAAAABJRU5ErkJggg==)

泡面吃多了你，`Redlock` 红锁是为了解决主从架构中当出现主从切换导致多个客户端持有同一个锁而提出的一种算法。

大家可以看官方文档（https://redis.io/topics/distlock），以下来自官方文档的翻译。

想用使用 Redlock，官方建议在不同机器上部署 5 个 Redis 主节点，节点都是完全独立，也不使用主从复制，使用多个节点是为容错。

**一个客户端要获取锁有 5 个步骤**：

1. 客户端获取当前时间 `T1`（毫秒级别）；

2. 使用相同的 `key`和 `value`顺序尝试从 `N`个 `Redis`实例上获取锁。

3. - 每个请求都设置一个超时时间（毫秒级别），该超时时间要远小于锁的有效时间，这样便于快速尝试与下一个实例发送请求。
   - 比如锁的自动释放时间 `10s`，则请求的超时时间可以设置 `5~50` 毫秒内，这样可以防止客户端长时间阻塞。

4. 客户端获取当前时间 `T2` 并减去步骤 1 的 `T1` 来计算出获取锁所用的时间（`T3 = T2 -T1`）。**当且仅当客户端在大多数实例（`N/2 + 1`）获取成功，且获取锁所用的总时间 T3 小于锁的有效时间，才认为加锁成功，否则加锁失败。**

5. 如果第 3 步加锁成功，则执行业务逻辑操作共享资源，**key 的真正有效时间等于有效时间减去获取锁所使用的时间（步骤 3 计算的结果）。**

6. 如果因为某些原因，获取锁失败（没有在至少 N/2+1 个 Redis 实例取到锁或者取锁时间已经超过了有效时间），**客户端应该在所有的 Redis 实例上进行解锁**（即便某些 Redis 实例根本就没有加锁成功）。

**另外部署实例的数量要求是奇数，为了能很好的满足过半原则，如果是 6 台则需要 4 台获取锁成功才能认为成功，所以奇数更合理**

> ❝
>
> 事情可没这么简单，Redis 作者把这个方案提出后，受到了业界著名的分布式系统专家的**质疑**。

两人好比神仙打架，两人一来一回论据充足的对一个问题提出很多论断……

- Martin Kleppmann 提出质疑的博客：https://martin.kleppmann.com/2016/02/08/how-to-do-distributed-locking.html
- Redlock 设计者的回复：http://antirez.com/news/101

## Redlock 是与非

Martin Kleppmann 认为锁定的目的是为了保护对共享资源的读写，而分布式锁应该「高效」和「正确」。

- 高效性：分布式锁应该要满足高效的性能，Redlock 算法向 5 个节点执行获取锁的逻辑性能不高，成本增加，复杂度也高；
- 正确性：分布式锁应该防止并发进程在同一时刻只能有一个线程能对共享数据读写。

出于这两点，我们没必要承担 Redlock 的成本和复杂，运行 5 个 Redis 实例并判断加锁是否满足大多数才算成功。

主从架构崩溃恢复极小可能发生，这没什么大不了的。使用单机版就够了，Redlock 太重了，没必要。

**Martin** 认为 **Redlock** 根本达不到安全性的要求，也依旧存在锁失效的问题！

### Martin 的结论

1. **Redlock** 不伦不类：对于偏好效率来讲，**Redlock** 比较重，没必要这么做，而对于偏好正确性来说，**Redlock** 是不够安全的。
2. 时钟假设不合理：该算法对系统时钟做出了危险的假设（假设多个节点机器时钟都是一致的），如果不满足这些假设，锁就会失效。
3. 无法保证正确性：**Redlock** 不能提供类似 **fencing token** 的方案，所以解决不了正确性的问题。为了正确性，请使用有「共识系统」的软件，例如 **Zookeeper**。

## Redis 作者 Antirez 的反驳

在 **Redis** 作者的反驳文章中，有 3 个重点：

- 时钟问题：**Redlock** 并不需要完全一致的时钟，只需要大体一致就可以了，允许有「误差」，只要误差不要超过锁的租期即可，这种对于时钟的精度要求并不是很高，而且这也符合现实环境。

- 网络延迟、进程暂停问题：

- - 客户端在拿到锁之前，无论经历什么耗时长问题，**Redlock** 都能够在第 3 步检测出来
  - 客户端在拿到锁之后，发生 **NPC**，那 **Redlock、Zookeeper** 都无能为力

- 质疑 fencing token 机制。

关于 Redlock 的争论我们下期再见，现在进入 Redisson 实现分布式锁实战部分。

# Redisson 分布式锁

基于 SpringBoot starter 方式，添加 starter。

```
<dependency>
  <groupId>org.redisson</groupId>
  <artifactId>redisson-spring-boot-starter</artifactId>
  <version>3.16.4</version>
</dependency>
```

不过这里需要注意 springboot 与 redisson 的版本，因为官方推荐 redisson 版本与 springboot 版本配合使用。

将 Redisson 与 Spring Boot 库集成，还取决于 Spring Data Redis 模块。

「码哥」使用 SpringBoot 2.5.x 版本， 所以需要添加 redisson-spring-data-25。

```
<dependency>
  <groupId>org.redisson</groupId>
  <!-- for Spring Data Redis v.2.5.x -->
  <artifactId>redisson-spring-data-25</artifactId>
  <version>3.16.4</version>
</dependency>
```

添加配置文件

```
spring:
  redis:
    database:
    host:
    port:
    password:
    ssl:
    timeout:
    # 根据实际情况配置 cluster 或者哨兵
    cluster:
      nodes:
    sentinel:
      master:
      nodes:
```

就这样在 Spring 容器中我们拥有以下几个 Bean 可以使用:

- `RedissonClient`
- `RedissonRxClient`
- `RedissonReactiveClient`
- `RedisTemplate`
- `ReactiveRedisTemplate`

## 失败无限重试

```
RLock lock = redisson.getLock("码哥字节");
try {

  // 1.最常用的第一种写法
  lock.lock();

  // 执行业务逻辑
  .....

} finally {
  lock.unlock();
}
```

拿锁失败时会不停的重试，具有 Watch Dog 自动延期机制，默认续 30s 每隔 30/3=10 秒续到 30s。

## 失败超时重试，自动续命

```
// 尝试拿锁10s后停止重试,获取失败返回false，具有Watch Dog 自动延期机制， 默认续30s
boolean flag = lock.tryLock(10, TimeUnit.SECONDS);
```

## 超时自动释放锁

```
// 没有Watch Dog ，10s后自动释放,不需要调用 unlock 释放锁。
lock.lock(10, TimeUnit.SECONDS);
```

## 超时重试，自动解锁

```
// 尝试加锁，最多等待100秒，上锁以后10秒自动解锁,没有 Watch dog
boolean res = lock.tryLock(100, 10, TimeUnit.SECONDS);
if (res) {
   try {
     ...
   } finally {
       lock.unlock();
   }
}
```

## Watch Dog 自动延时

如果获取分布式锁的节点宕机，且这个锁还处于锁定状态，就会出现死锁。

为了避免这个情况，我们都会给锁设置一个超时自动释放时间。

然而，还是会存在一个问题。

假设线程获取锁成功，并设置了 30 s 超时，但是在 30s 内任务还没执行完，锁超时释放了，就会导致其他线程获取不该获取的锁。

所以，Redisson 提供了 watch dog 自动延时机制，提供了一个监控锁的看门狗，它的作用是在 Redisson 实例被关闭前，不断的延长锁的有效期。

也就是说，如果一个拿到锁的线程一直没有完成逻辑，那么看门狗会帮助线程不断的延长锁超时时间，锁不会因为超时而被释放。

默认情况下，看门狗的续期时间是 30s，也可以通过修改 `Config.lockWatchdogTimeout` 来另行指定。

另外 `Redisson` 还提供了可以指定 `leaseTime` 参数的加锁方法来指定加锁的时间。

超过这个时间后锁便自动解开了，不会延长锁的有效期。

原理如下图：

![图片](data:image/gif;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQImWNgYGBgAAAABQABh6FO1AAAAABJRU5ErkJggg==)

**有两个点需要注意：**

- **watchDog 只有在未显示指定加锁超时时间（leaseTime）时才会生效。**
- **lockWatchdogTimeout 设定的时间不要太小 ，比如设置的是 100 毫秒，由于网络直接导致加锁完后，watchdog 去延期时，这个 key 在 redis 中已经被删除了。**

## 源码导读

在调用 lock 方法时，会最终调用到 `tryAcquireAsync`。

调用链为：`lock()->tryAcquire->tryAcquireAsync`，详细解释如下：

```
private <T> RFuture<Long> tryAcquireAsync(long waitTime, long leaseTime, TimeUnit unit, long threadId) {
        RFuture<Long> ttlRemainingFuture;
        //如果指定了加锁时间，会直接去加锁
        if (leaseTime != -1) {
            ttlRemainingFuture = tryLockInnerAsync(waitTime, leaseTime, unit, threadId, RedisCommands.EVAL_LONG);
        } else {
            //没有指定加锁时间 会先进行加锁，并且默认时间就是 LockWatchdogTimeout的时间
            //这个是异步操作 返回RFuture 类似netty中的future
            ttlRemainingFuture = tryLockInnerAsync(waitTime, internalLockLeaseTime,
                    TimeUnit.MILLISECONDS, threadId, RedisCommands.EVAL_LONG);
        }

        //这里也是类似netty Future 的addListener，在future内容执行完成后执行
        ttlRemainingFuture.onComplete((ttlRemaining, e) -> {
            if (e != null) {
                return;
            }

            // lock acquired
            if (ttlRemaining == null) {
                // leaseTime不为-1时，不会自动延期
                if (leaseTime != -1) {
                    internalLockLeaseTime = unit.toMillis(leaseTime);
                } else {
                    //这里是定时执行 当前锁自动延期的动作,leaseTime为-1时，才会自动延期
                    scheduleExpirationRenewal(threadId);
                }
            }
        });
        return ttlRemainingFuture;
    }
```

`scheduleExpirationRenewal` 中会调用 `renewExpiration` 启用了一个 `timeout` 定时，去执行延期动作。

```
private void renewExpiration() {
        ExpirationEntry ee = EXPIRATION_RENEWAL_MAP.get(getEntryName());
        if (ee == null) {
            return;
        }

        Timeout task = commandExecutor.getConnectionManager()
          .newTimeout(new TimerTask() {
            @Override
            public void run(Timeout timeout) throws Exception {
                // 省略部分代码
                ....

                RFuture<Boolean> future = renewExpirationAsync(threadId);
                future.onComplete((res, e) -> {
                    ....

                    if (res) {
                        //如果 没有报错，就再次定时延期
                        // reschedule itself
                        renewExpiration();
                    } else {
                        cancelExpirationRenewal(null);
                    }
                });
            }
            // 这里我们可以看到定时任务 是 lockWatchdogTimeout 的1/3时间去执行 renewExpirationAsync
        }, internalLockLeaseTime / 3, TimeUnit.MILLISECONDS);

        ee.setTimeout(task);
    }
```

`scheduleExpirationRenewal` 会调用到 `renewExpirationAsync`，执行下面这段 lua 脚本。

他主要判断就是 这个锁是否在 redis 中存在，如果存在就进行 pexpire 延期。

```
protected RFuture<Boolean> renewExpirationAsync(long threadId) {
        return evalWriteAsync(getRawName(), LongCodec.INSTANCE, RedisCommands.EVAL_BOOLEAN,
                "if (redis.call('hexists', KEYS[1], ARGV[2]) == 1) then " +
                        "redis.call('pexpire', KEYS[1], ARGV[1]); " +
                        "return 1; " +
                        "end; " +
                        "return 0;",
                Collections.singletonList(getRawName()),
                internalLockLeaseTime, getLockName(threadId));
    }
```

- watch dog 在当前节点还存活且任务未完成则每 10 s 给锁续期 30s。
- 程序释放锁操作时因为异常没有被执行，那么锁无法被释放，所以释放锁操作一定要放到 finally {} 中；
- 要使 watchLog 机制生效 ，lock 时 不要设置 过期时间。
- watchlog 的延时时间 可以由 lockWatchdogTimeout 指定默认延时时间，但是不要设置太小。
- watchdog 会每 lockWatchdogTimeout/3 时间，去延时。
- 通过 lua 脚本实现延迟。

## 总结

完工，我建议你合上屏幕，自己在脑子里重新过一遍，每一步都在做什么，为什么要做，解决什么问题。

我们一起从头到尾梳理了一遍 Redis 分布式锁中的各种门道，其实很多点是不管用什么做分布式锁都会存在的问题，重要的是思考的过程。

**对于系统的设计，每个人的出发点都不一样，没有完美的架构，没有普适的架构，但是在完美和普适能平衡的很好的架构，就是好的架构。**