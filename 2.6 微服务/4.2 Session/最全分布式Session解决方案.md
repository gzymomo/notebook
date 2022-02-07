- [最全分布式Session解决方案](https://mp.weixin.qq.com/s?__biz=Mzg5NDM1ODk4Mw==&mid=2247521618&idx=2&sn=c3bff52679f81df03f809dd9980b6748&chksm=c02211faf75598ecb2ea3c3712ed34b9194e9bd548a3b638de1425cf6b70850d96b0e4608bd4&scene=21#wechat_redirect)

考虑一个场景，用户在进行下单操作之前后台需要校验该用户是否登录，若未登录则不允许提交订单，这在传统的单体应用中非常容易实现，只需在提交订单之前判断Session中的用户信息是否登录即可，但在分布式应用中，这显然是一个待解决的问题。

## 1 分布式应用下Session存在的问题

在分布式架构中，一个应用往往被划分为多个子模块，比如：登录注册模块和订单模块，当应用被拆分后，随之而来的便是数据的共享问题：

![图片](https://mmbiz.qpic.cn/mmbiz_png/iccLKyfqr2YIkLE1rDUGmzcqib74sXRXQ8aK8j7HY1N7XCPwmnKCs31cc9PGBq9D1iaPHvJWynqByzE5W9J86eqkA/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

一般我们都在登录注册模块中将用户的登录状态保存到Session中，然而当用户进行下单操作时，由于订单模块是独立的，它无法获取到登录注册模块中保存的Session，所以订单模块是无法判断用户是否登录的。而为了保证系统的高可用，一个模块往往被部署多份形成集群，这些模块之间的数据共享也是一个问题：

![图片](https://mmbiz.qpic.cn/mmbiz_png/iccLKyfqr2YIkLE1rDUGmzcqib74sXRXQ8wbCq6MfibibgHU9kpFDZ7LVxe1IfpGdUq4Xc9QS5PBYwpp8ZG3qHsVEg/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

用户在一个模块中登录成功后，很可能在下次访问时请求被负载均衡到其它的集群模块中，这样会导致无法读取到Session，使得用户又得重新登录一次系统。

## 2 Session共享问题的案例演示

下面编写一个案例进行演示，首先创建一个SpringBoot应用，实现登录模块：

```java
@RestController
public class LoginController {

    @Autowired
    private ServiceOrderClient serviceOrderClient;

    @GetMapping("/login")
    public Result login(User user, HttpSession session) {
        String username = user.getUsername();
        String password = user.getPassword();
        Result result = new Result();
        if ("admin".equals(username) && "admin".equals(password)) {
            result.setCode(200);
            result.setMessage("登录成功");
            session.setAttribute("user", user);
        } else {
            result.setCode(-1);
            result.setMessage("登录失败");
        }
    }
}
```

再创建一个SpringBoot应用，实现订单模块：

```java
@RestController
public class OrderController {

    @GetMapping("/order/test")
    public String order(@CookieValue("JSESSIONID") String jSessionId) {
        return "success";
    }
}
```

代码都非常简单，我们主要是观察Session的问题，在登录模块中编写远程调用接口：

```java
@FeignClient("service-order")
public interface ServiceOrderClient {

    @GetMapping("/order/test")
    String order();
}
```

将这两个应用都注册到Nacos中，其它代码我就不贴出来了，都比较简单。分别启动这两个项目，并访问 http://localhost:8080/test ，会发现访问是不成功的：

![图片](https://mmbiz.qpic.cn/mmbiz_png/iccLKyfqr2YIkLE1rDUGmzcqib74sXRXQ81nPFxAcOHIkYN2IrJcMpI8o9GBfQzqGfuhcicgdic9iad5uvFHsmlkOvg/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

控制台输出的结果：

```
2021-09-21 16:51:43.155  WARN 20908 --- [nio-9000-exec-1] .w.s.m.s.DefaultHandlerExceptionResolver : Resolved [org.springframework.web.bind.MissingRequestCookieException: Missing cookie 'JSESSIONID' for method parameter of type String]
```

找不到名为 `JSESSIONID` 的Cookie，我们知道，服务端是通过JSESSIONID来找到该用户对应的Session信息的，既然JSESSIONID都获取不到，就更不用说用户信息了，这就是Session不共享的问题。

## 3 Redis解决Session共享问题

对于分布式应用中的Session问题，其实也非常简单，无非就是不能共享到Session，所以，我们可以类比缓存的思想，将Session放入缓存中，其它服务想要获取Session也从缓存中拿，这样就实现了Session的共享。改进一下登录模块：

```java
@GetMapping("/login")
public Result login(User user, HttpSession session) {
    String username = user.getUsername();
    String password = user.getPassword();
    Result result = new Result();
    if ("admin".equals(username) && "admin".equals(password)) {
        result.setCode(200);
        result.setMessage("登录成功");
        String json = JSONObject.toJSONString(user);
        redisTemplate.opsForValue().set("session", json);
    } else {
        result.setCode(-1);
        result.setMessage("登录失败");
    }
    return result;
}
```

当我们访问登录接口 http://localhost:8080/login?username=admin&password=admin[1] 时，就会向Redis保存一份Session的值：

![图片](https://mmbiz.qpic.cn/mmbiz_png/iccLKyfqr2YIkLE1rDUGmzcqib74sXRXQ8UMqsdtmyswibzHnDcAnfuOJkNzkibWd9iahh8payy10BqoRUfrj03pnicA/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

此时若是其它服务需要Session，只要从Redis中读取即可，修改一下订单模块：

```java
@RestController
public class OrderController {

    @GetMapping("/order/test")
    public String order() {
        return "success";
    }
}
```

在订单模块中添加一个登录的拦截器：

```java
public class LoginInterceptor implements HandlerInterceptor {

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {
        // 手动获取StringRedisTemplate对象
        StringRedisTemplate redisTemplate = SpringBeanOperator.getBean(StringRedisTemplate.class);
        String json = redisTemplate.opsForValue().get("session");
        User user = JSONObject.parseObject(json, User.class);
        System.out.println(user);
        if (user == null) {
            System.out.println("用户未登录......");
            return false;
        } else {
            System.out.println("用户已登录......");
            return true;
        }
    }
}
```

将拦截器注册一下：

```java
@Configuration
public class MyWebConfig implements WebMvcConfigurer {

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(new LoginInterceptor())
                .addPathPatterns("/**");
    }
}
```

重启项目，访问 http://localhost:8080/test ，输出结果：

```
User(username=admin, password=admin)
用户已登录......
```

## 4 SpringSession解决Session共享问题

刚才我们自己使用Redis尝试着解决了一下Session的共享问题，然而这种方式是有很多缺陷的，首先，我们保存的只是一个User对象，并不是Session，所以我们无法标识该用户，这样会导致用户访问到了其它用户的信息，使得系统混乱。我们当然可以使用JSESSIONID来标识不同的用户，但其实，Spring已经为我们提供了一个组件来解决这一问题，那就是SpringSession。 

在两个模块中都引入SpringSession的依赖：

```xml
<dependency>
  <groupId>org.springframework.session</groupId>
  <artifactId>spring-session-data-redis</artifactId>
</dependency>
```

在application.yml中配置一下Session的保存方式为Redis：

```
spring:  session:
    store-type: redis
```

最后在启动类上添加 @EnableRedisHttpSession 注解，这样SpringSession的整合就完成了。我们修改登录模块的代码：

```java
@GetMapping("/login")
public Result login(User user, HttpSession session) {
    String username = user.getUsername();
    String password = user.getPassword();
    Result result = new Result();
    if ("admin".equals(username) && "admin".equals(password)) {
        result.setCode(200);
        result.setMessage("登录成功");
        session.setAttribute("user",user);
    } else {
        result.setCode(-1);
        result.setMessage("登录失败");
    }
    return result;
}
```

按照正常流程将User对象存入Session，重启项目并访问登录接口，来看看Redis中有什么变化：

![图片](https://mmbiz.qpic.cn/mmbiz_png/iccLKyfqr2YIkLE1rDUGmzcqib74sXRXQ8ch4XaoepLuQ14mJp54JOZKQZR4YTALS4hFZSRaxp3ichvOiaT4Ex5AKg/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

此时Redis中已经保存了用户信息，并且还有创建时间、存活时间等配置，其它模块要想获取到Session中的用户信息，也只需要按正常流程编写代码即可：

```java
public class LoginInterceptor implements HandlerInterceptor {

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {
        HttpSession session = request.getSession();
        User user = (User) session.getAttribute("user");
        System.out.println(user);
        if (user == null) {
            System.out.println("用户未登录......");
            return false;
        } else {
            System.out.println("用户已登录......");
            return true;
        }
    }
}
```

> 需要注意的是登录模块存入的User对象需要和其它模块读出的User对象包名一致，所以最好将User类抽取到公共模块中，提供给所有模块使用。

到这里SpringSession就解决了Session共享的问题，你可以运行项目测试一下，访问 http://localhost:8080/test ：

![图片](https://mmbiz.qpic.cn/mmbiz_png/iccLKyfqr2YIkLE1rDUGmzcqib74sXRXQ8KgDQmILrkOBCBANQUAg3mfqwaf1uic10SXVpCvO7G4OPZI7kXzmI9fQ/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

结果出乎意料，控制台的结果是：

```
null
用户未登录......
```

这就奇怪了，难道是SpringSession没起作用？我们写一个测试方法测试一下：

```java
@GetMapping("/test")
public String test(HttpSession session) {
    User user = (User) session.getAttribute("user");
    System.out.println(user);
    return "test";
}
```

访问 http://localhost:9000/test ，得到结果：

```
User(username=admin, password=admin)
```

显然SpringSession是没有任何问题的，那么问题出在哪里了呢？

## 5 OpenFeign远程调用的坑

刚才我们进行了测试，发现在订单模块中直接访问Session可以获取User对象，然而通过远程调用，User就获取不到了，我们可以猜测这是OpenFeign出现了问题，Debug调试一下项目，这是远程调用的代码：

![图片](https://mmbiz.qpic.cn/mmbiz_png/iccLKyfqr2YIkLE1rDUGmzcqib74sXRXQ8KwRgnNE8Yv2z2DySmSGRcCazEmsNibc28JsdnKqlQep2l99eP8SFU8Q/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

我们跟进去看看：

```java
public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
    if ("equals".equals(method.getName())) {
        try {
            Object otherHandler =
                args.length > 0 && args[0] != null ? Proxy.getInvocationHandler(args[0]) : null;
            return equals(otherHandler);
        } catch (IllegalArgumentException e) {
            return false;
        }
    } else if ("hashCode".equals(method.getName())) {
        return hashCode();
    } else if ("toString".equals(method.getName())) {
        return toString();
    }

    return dispatch.get(method).invoke(args);
}
```

该方法中进行了一些判断，最终会调用dispatch.get()方法：

```java
@Override
public Object invoke(Object[] argv) throws Throwable {
    RequestTemplate template = buildTemplateFromArgs.create(argv);
    Options options = findOptions(argv);
    Retryer retryer = this.retryer.clone();
    while (true) {
        try {
            return executeAndDecode(template, options);
        } catch (RetryableException e) {
            try {
                retryer.continueOrPropagate(e);
            } catch (RetryableException th) {
                Throwable cause = th.getCause();
                if (propagationPolicy == UNWRAP && cause != null) {
                    throw cause;
                } else {
                    throw th;
                }
            }
            if (logLevel != Logger.Level.NONE) {
                logger.logRetry(metadata.configKey(), logLevel);
            }
            continue;
        }
    }
}
```

该方法又会调用executeAndDecode()：

![图片](https://mmbiz.qpic.cn/mmbiz_png/iccLKyfqr2YIkLE1rDUGmzcqib74sXRXQ8vhuDt0GlUfhfOeYpuOVfOicNm0YZGkwhcB7iaR573kUpbeCOicsYS0Dnw/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

该方法会封装一个请求模板作为目标请求进行远程调用，然而我们观察到该请求模板中并没有任何的参数和请求头，而我们知道，Session是依靠JSESSIONID进行识别的，在SpringSession中，Session是依靠`SESSION`识别的：![图片](data:image/gif;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQImWNgYGBgAAAABQABh6FO1AAAAABJRU5ErkJggg==)由此我们得到结论，因为OpenFeign远程调用丢失了请求头，导致SESSIONID丢失，最终导致订单模块无法获取到User对象。得知了问题后，解决就非常简单了，我们可以创建一个请求过滤器，它将在请求模板生成前对请求进行处理：

```java
@Configuration
public class MyFeignConfig {

    @Bean
    public RequestInterceptor requestInterceptor() {
        return requestTemplate -> {
            System.out.println("远程调用前调用该方法-->requestInterceptor......");
            ServletRequestAttributes requestAttributes = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
            HttpServletRequest request = requestAttributes.getRequest();
            String cookie = request.getHeader("Cookie");
            requestTemplate.header("Cookie", cookie);
        };
    }
}
```

将原Request对象中的Cookie请求头信息设置给请求模板，这样OpenFeign创建的请求就具有了Cookie内容，重新启动项目测试，问题迎刃而解。