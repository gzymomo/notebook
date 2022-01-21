## 为什么需要Assert？

Assert翻译为中文为"断言"，它是spring的一个util类，`org.springframework.util.Assert`一般用来断定某一个实际的值是否为自己预期想得到的，如果不一样就抛出异常。

主要原因有两个：

1. 因为Validator只解决了参数自身的数据校验，解决不了参数和业务数据之间校验。

   例如以下代码，Validator是搞不定的。

```java
public void test1(int accountId) {
    Account account = accountDao.selectById(accountId);
    if (account == null) {
        throw new IllegalArgumentException("用户不存在！");
    }
}
```

1. 采用Assert能使代码更优雅，更简洁。

   还是上面的例子，如果采用Assert可以这样写：

```java
public void test2(int accountId) {
    Account account = accountDao.selectById(accountId);
    Assert.notNull(account, "用户不存在！");
}
```

## 如何使用Assert?

在SpringBoot中使用Assert非常简单，直接使用Assert提供的静态方法即可。

```java
@RestController
@RequestMapping("assert")
@Slf4j
public class AssertController {

    @DeleteMapping("/user/{id}")
    public void deleteUser(@PathVariable("id") String id) {
        //模拟数据库查询用户
        UserVO user = getUserById(id);
        Assert.notNull(user, "用户不存在！");
    }

    private UserVO getUserById(String id) {
        return null;
    }
}
```

如上，AssertController有一个删除用户的接口，当删除用户时我们需要先校验用户是否存在。这里直接使用`Assert.notNull()`进行`UserVO`的非空校验。

此时访问接口，返回的json对象如下：

```json
{
  "timestamp": "2022-01-10T14:17:13.335+00:00",
  "status": 500,
  "error": "Internal Server Error",
  "message": "",
  "path": "/assert/user/javadaily"
}
```

从测试结果来看，assert抛出的异常是springboot原生json对象，很明显我们必须将其加入全局异常拦截器`RestExceptionHandler`。

## 加入全局异常拦截器

查看`Assert.notNull()`方法，可以看到Assert抛出的是`IllegalArgumentException`异常，所以我们只需要在全局异常拦截器中加入`IllegalArgumentException`拦截即可。

```java
/**
  * Assert异常
  */
@ExceptionHandler(IllegalArgumentException.class)
@ResponseStatus(HttpStatus.INTERNAL_SERVER_ERROR)
public ResultData<String> exception(IllegalArgumentException e) {
  return ResultData.fail(ReturnCode.ILLEGAL_ARGUMENT.getCode(),e.getMessage());
}
```

此时再次访问接口，返回的数据结果为：

```json
{
  "status": 3001,
  "message": "用户不存在！",
  "data": null,
  "timestamp": 1641825258876
}
```

符合结果预期。

## 常见的Assert使用场景

### 逻辑断言

1. `isTrue()`如果条件为假抛出IllegalArgumentException 异常。
2. `state()`该方法与isTrue一样，但抛出IllegalStateException异常。

### 对象和类型断言

1. `notNull()`通过notNull()方法可以假设对象不null：
2. `isNull()`用来检查对象为null:
3. `isInstanceOf()`使用isInstanceOf()方法检查对象必须为另一个特定类型的实例
4. `isAssignable()`使用Assert.isAssignable()方法检查类型

### 文本断言

1. `hasLength()`如果检查字符串不是空符串，意味着至少包含一个空白，可以使用hasLength()方法。
2. `hasText()`我们能增强检查条件，字符串至少包含一个非空白字符，可以使用hasText()方法。
3. `doesNotContain()`我们能通过doesNotContain()方法检查参数不包含特定子串。

### Collection和map断言

1. Collection应用`notEmpty()`如其名称所示，notEmpty()方法断言collection不空，意味着不是null并包含至少一个元素。
2. map应用`notEmpty()`同样的方法重载用于map，检查map不null，并至少包含一个entry（key，value键值对）。

### 数组断言

1. `notEmpty()`notEmpty()方法可以检查数组不null，且至少包括一个元素：
2. `noNullElements()`noNullElements()方法确保数组不包含null元素

## 小结

Assert断言，可以替换传统的if判断，大量减少业务参数校验的代码行数，提高程序的可读性，这种风格是目前比较流行的方式。