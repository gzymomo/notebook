- [高效能团队的Java研发规范(进阶版) | 木小丰的博客 (lesofn.com)](https://lesofn.com/archives/java-coding-standard?hmsr=toutiao.io&utm_campaign=toutiao.io&utm_medium=toutiao.io&utm_source=toutiao.io)

# 编程规约

## 1、基础类型及操作

### （1）转换

##### 基本类型转换

String类型转数字：使用apache common-lang3包中的工具类NumberUtils，优势：可设置默认值，转换出错时返回默认值

```java
NumberUtils.toInt("1");
```



拆箱：包装类转化为基本类型的时候，需要判定null，比如：

```
Integer numObject = param.get(0);int num = numObject != null ? numObject : 0;
```



##### 对象类型转换

使用MapStruct工具，转换类后缀Convertor，所有转换操作都在转换类中操作，禁止在业务代码中编写大量set代码。

### （2）判断

##### 枚举判定

使用枚举判等，而非枚举对应的数字。因为枚举更直观，方便查看代码及调试，数字容易出错。

##### 判空

各种对象的判空：

```
//对象判空&非空Objects.isNull()Objects.nonNull()
//String判空&非空StringUtils.isEmpty()   //可匹配null和空字符串StringUtils.isNotEmpty()StringUtils.isBlank()   //可匹配null、空字符串、多个空白字符StringUtils.isNotBlank()
//集合判空&非空CollectionUtils.isEmpty()CollectionUtils.isNotEmpty()
//Map判空&非空MapUtils.isEmpty()MapUtils.isNotEmpty()
```



##### 断言

使用Guava里的Preconditions工具类，比如：

```
//如果是空则抛异常Preconditions.checkNotNull()//通用判断Preconditions.checkArgument()
```



## 2、集合处理

### （1）Map快捷操作

推荐：

```java
//如果值不存在则计算map.computeIfAbsent("key",k-> execValue(k));//默认值map.getOrDefault("key", DEFAULT_VALUE)
```



反例：

```java
//如果值不存在则计算String v = map.get("key");if(v == null){    v = execValue("key");    map.put("key", v);}//默认值map.containsKey("key") ? map.get("key") : DEFAULT_VALUE
```



### （2）创建对象

构造方法或Builder模式，超过3个参数对象创建使用Builder模式

```java
//Java11+:List.of(1, 2, 3)  Set.of(1, 2, 3)Map.of("a", 1)
//Java8中不可变集合（需引入Guava）ImmutableList.of(1,2,3)ImmutableSet.of(1,2,3)ImmutableMap.of("key","value")//多值情况ImmutableMap.builder()    .put("key", "value")    .put("key2", "value2")    .build()
//Java8中可变集合（需引入Guava）Lists.newArrayList(1, 2, 3)Sets.newHashSet(1, 2, 3)Maps.newHashMap("key", "value")
```



反例：

```java
new ArrayList<>(){{   add(1);   add(2);}};
```



### （3）集合嵌套

集合里的值如果是基础类型必须加上注释，说明集合里存的是什么，比如：

```java
//返回值: Map(key: 姓名, value: List(商品))Map<String, List<String>> res;
```



超过2层集合对象封装必须封装成自定义类：

```java
//推荐Map<String, List<Node>> res;
@Valuepublic static class Node {    /**    * 备注说明字段    */    String name;    /**    * 备注说明字段2    */    List<Integer> subjectIds;}
//反例Map<String, List<Pair<String, List<Integer>>>> res;
```



# 异常及日志

## 1、异常

关于异常及错误码的思考，请参考笔者的另一篇文章：[错误码设计思考](https://lesofn.com/archives/errorcode-design)

异常除了抛异常还有一种场景，即：上层发起多个必要调用，某些可能失败，需要上层自行决定处理策略，推荐使用vavr中的Either类，Either使用建议：通常我们使用左值表示异常，而右值表示正常调用后的返回结果，即: Either<Throwable, Data>

## 2、日志

### （1）日志文件

根据日志等级一般分为4个日志文件即可：debug.log、info.log、warn.log、error.log；

如有特殊需求可根据场景单独建文件，比如请求日志：request.log、gc日志：gc.log等。

### （2）所有用户日志都要有追踪字段

追踪字段包括：traceId、userId等，推荐使用MDC，常用的日志框架：Log4j、Logback都支持。

### （3）日志清理及持久化

本地日志根据磁盘大小，必须设置日志保存天数，否则有硬盘满风险；

分布式环境为了方便查询，需要将日志采集到ES中查询；

重要日志：比如审计日志、B端操作日志需要持久保存，一般是保存到Hive中；

# 工具篇

## 1、JSON

推荐：使用Gson或Jackson；

不推荐：Fastjson。Fastjson爆出的漏洞多。

## 2、对象转换

推荐：MapStruct，根据注解编译成Java代码，没有反射，速度快；行为可预测，可查看编译后的Java代码查看转换逻辑；

不推荐：BeanUtils、Dozer等。需要反射，行为不可预测，需要测试；

不推荐：超过3个字段手动转换；

## 3、模板代码

推荐：Lombok，减少代码行数，提升开发效率，自动生成Java代码，没有性能损耗；

不推荐：手动生成大量set、get方法；

## 4、参数校验

推荐：hibernate Validation、spring-boot-starter-validation，可通过注解自动实现参数拦截；

不推荐：每个入口（比如Controller）都copy大量重复的校验逻辑；

## 5、缓存

推荐：Spring Cache，通过注解控制缓存逻辑，适合常用的加缓存场景。

# 设计篇

## 1、正向语义

正向语义的好处在于使代码容易理解。 比如：**if(judge()){…}**，很容易理解，即：判定成功则执行代码块。

相反，如果是负向语义，思维还要转换一下，一般用于方法前置的参数校验。

正向语义的应用场景有：

- 方法定义：方法名推荐：canPass、checkParam，返回true代表成功。 不推荐：比如isInvalidParam返回true代表失败，增加理解成本；
- Lambda表达式：filter 操作符中返回true是可以通过的元素；
- if和三目运算符：**condition ? doSomething() : doSomething2()** , 条件判定后紧跟的是判定成功后执行的操作。

反例：

```
if (!judge()) {   doSomething2()} else {   doSomething()}
```

## 2、防御式编程

### （1）外部数据校验

外部传过来数据都需要校验，一般分为两类：

- 数据流入：用户Http请求、RPC请求、MQ消费者等
- 数据依赖：依赖的第三方RPC、数据库等

如果是数据流入，一定要首先校验数据合法性再往下执行，推荐hibernate Validation这类工具，可以很方便的做数据校验

数据是数据依赖，一定要考虑各种网络、限流、背压等场景，做好熔断、降级保障。推荐建立防腐层，将第三方的限界上下文语义转换为当前上下文语义，避免理解上的歧义；

### （2）Null处理

- 对于强依赖，没有返回值不行（比如查询数据库）：直接抛异常；

- 需要反馈给上层处理：

  （1）可能返回null的场景：使用Optional；

  （2）上层需要感知信息异常信息：使用vavr中的Either；

- 可降级：

  （1）返回值是默认值：集合类返回，数字返回0或-1，字符串返回空字符串，其他场景自定义

  集合默认值：

```java
Collections.emptyList()  //空ListCollections.emptySet()   //空SetCollections.emptyMap()   //空Map
```