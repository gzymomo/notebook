- [写JAVA的好习惯](https://juejin.cn/post/7028477291399217160)

## 前言

好的开发习惯能帮助我们在日常开发工作中达到事半功倍的效果，增强代码的可读性、健壮性，减少代码漏洞，因此我们应当不懈的追求代码精进，培养好的开发习惯。

## [代码规范](https://link.juejin.cn?target=https%3A%2F%2Frameosu.github.io%2Fjava3c%2F%23%2FSpecification%2F%E5%86%99JAVA%E7%9A%84%E5%A5%BD%E4%B9%A0%E6%83%AF%3Fid%3D%e4%bb%a3%e7%a0%81%e8%a7%84%e8%8c%83)

- 写完代码，自测一下
- 方法入参尽量都校验
- 对于复杂的代码逻辑，添加清楚的注释
- 使用完IO资源流，需要关闭
- 代码采取措施避免运行时错误（如数组边界溢出，被零除等）
- 尽量不在循环里远程调用、或者数据库操作，优先考虑批量进行
- 获取对象的属性，先判断对象是否为空
- Set集合或者Map集合中的key为自定义对象时，要重写该对象的equals和hashCode方法
- `避免使用双括号`new Person{{setName("xxx")}}的方式实例化对象，该写法虽然简洁但会生成匿名内部类，容易造成内存泄漏
- 不要在条件判断中写复杂的表达式
- 条件判断使用[卫语句](https://link.juejin.cn?target=https%3A%2F%2Fwww.cnblogs.com%2Fheihaozi%2Fp%2F11818042.html)，增强代码可读性和健壮性
- 使用equals()方法时，常量（有确定值）放前面
- spring官方推荐使用`构造器注入`
- 尽量不在循环中使用try-catch，应把其放在最外层
- 常量声明为static final，并以大写命名
- 不要创建一些不使用的对象，不要导入一些不使用的类
- 不要对超出范围的基本数据类型做向下强制转型

## [代码优化](https://link.juejin.cn?target=https%3A%2F%2Frameosu.github.io%2Fjava3c%2F%23%2FSpecification%2F%E5%86%99JAVA%E7%9A%84%E5%A5%BD%E4%B9%A0%E6%83%AF%3Fid%3D%e4%bb%a3%e7%a0%81%e4%bc%98%e5%8c%96)

- 尽量指定类、方法、变量的final修饰符
- 尽量重用对象
- 尽可能使用局部变量
- 尽量减少对变量的重复计算
- 尽量采用懒加载的策略
- 如果能预估到数组、集合的内容长度，应在创建时指定长度
- 复制大量数据时，使用System.arraycopy()
- 乘法和除法使用移位操作
- 数组优先于列表
- 尽量在合适的场合使用单例
- 尽量避免使用静态变量
- 尽量避免使用反射
- 尽量使用`池化技术`（数据库连接池、线程池）
- 使用带缓冲的输入输出流进行IO操作
- public方法不要有太多的形参
- 使用最有效率的方式去遍历Map（推荐使用entrySet()遍历）

## [接口规约](https://link.juejin.cn?target=https%3A%2F%2Frameosu.github.io%2Fjava3c%2F%23%2FSpecification%2F%E5%86%99JAVA%E7%9A%84%E5%A5%BD%E4%B9%A0%E6%83%AF%3Fid%3D%e6%8e%a5%e5%8f%a3%e8%a7%84%e7%ba%a6)

- 接口需要考虑幂等性
- 接口入参需要做校验，推荐使用@valid或者@validated校验框架
- 接口出参不允许为枚举值或任何包含枚举值的pojo对象
- 修改老接口的时候，考虑接口的兼容性
- 调用第三方接口，需要考虑异常处理，安全性，超时重试这几个点

## [并发编程](https://link.juejin.cn?target=https%3A%2F%2Frameosu.github.io%2Fjava3c%2F%23%2FSpecification%2F%E5%86%99JAVA%E7%9A%84%E5%A5%BD%E4%B9%A0%E6%83%AF%3Fid%3D%e5%b9%b6%e5%8f%91%e7%bc%96%e7%a8%8b)

- 多线程情况下，考虑线性安全问题
- 写完代码，脑洞一下多线程执行会怎样，注意并发一致性问题
- 多线程异步优先考虑恰当的线程池，而不是new thread，同时考虑线程池是否隔离
- 使用`ThreadPoolExecutor构造器创建线程池`，避免使用Executors的 静态方法创建线程池
- 使用synchronized时尽量同步代码块
- 使用锁时尽量缩小锁定范围

## [缓存（redis）](https://link.juejin.cn?target=https%3A%2F%2Frameosu.github.io%2Fjava3c%2F%23%2FSpecification%2F%E5%86%99JAVA%E7%9A%84%E5%A5%BD%E4%B9%A0%E6%83%AF%3Fid%3D%e7%bc%93%e5%ad%98%ef%bc%88redis%ef%bc%89)

- 使用缓存的时候，考虑缓存跟DB的一致性
- 考虑缓存穿透、缓存雪崩、缓存击穿、缓存热点问题
- 避免使用redis事务功能
- 禁止线上使用`keys`、flushall、flushdb等，通过redis的rename机制禁掉命令，或者使用scan的方式渐进式处理
- 使用批量操作的命令提升效率
- 拒绝big key（拆分key，使用合适的数据类型）
- 控制key的生命周期（分散设置过期时间）
- key名设计要有可读性、可管理性、简洁性，不要包含特殊字符
- 设置合适的内存淘汰策略

## [数据库](https://link.juejin.cn?target=https%3A%2F%2Frameosu.github.io%2Fjava3c%2F%23%2FSpecification%2F%E5%86%99JAVA%E7%9A%84%E5%A5%BD%E4%B9%A0%E6%83%AF%3Fid%3D%e6%95%b0%e6%8d%ae%e5%ba%93)

- 手动写完代码业务的SQL，先拿去数据库跑一下，同时也explain看下执行计划
- 数据库主从延迟问题考虑（必要时强制读主库）
- 避免在循环内做数据库的操作