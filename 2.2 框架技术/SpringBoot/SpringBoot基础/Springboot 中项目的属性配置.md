- [Springboot 中项目的属性配置](https://blog.51cto.com/wuge666/4961208)

## 正文

我们知道，在项目中，很多时候需要用到一些配置的信息，这些信息可能在测试环境和生产环境下会有不同的配置，后面根据实际业务情况有可能还会做修改，针对这种情况，我们不能将这些配置在代码中写死，最好就是写到配置文件中。比如可以把这些信息写到 `application.yml` 文件中。   

## 1. 少量配置信息的情形

举个例子，在微服务架构中，最常见的就是某个服务需要调用其他服务来获取其提供的相关信息，那么在该服务的配置文件中需要配置被调用的服务地址，比如在当前服务里，我们需要调用订单微服务获取订单相关的信息，假设 订单服务的端口号是 8002，那我们可以做如下配置：

```xml
server:
  port: 8001

# 配置微服务的地址
url:
  # 订单微服务的地址
  orderUrl: http://localhost:8002
```

然后在业务代码中如何获取到这个配置的订单服务地址呢？我们可以使用 `@Value` 注解来解决。在对应的类中加上一个属性，在属性上使用 `@Value` 注解即可获取到配置文件中的配置信息，如下：

```java
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/test")
public class ConfigController {

    private static final Logger LOGGER = LoggerFactory.getLogger(ConfigController.class);

    @Value("${url.orderUrl}")
    private String orderUrl;

    @RequestMapping("/config")
    public String testConfig() {
        LOGGER.info("=====获取的订单服务地址为：{}", orderUrl);
        return "success";
    }
}
```

`@Value` 注解上通过 `${key}` 即可获取配置文件中和 key 对应的 value 值。我们启动一下项目，在浏览器中输入 `localhost:8080/test/config` 请求服务后，可以看到控制台会打印出订单服务的地址：

```
=====获取的订单服务地址为：http://localhost:8002
```

说明我们成功获取到了配置文件中的订单微服务地址，在实际项目中也是这么用的，后面如果因为服务器部署的原因，需要修改某个服务的地址，那么只要在配置文件中修改即可。  

## 2. 多个配置信息的情形

这里再引申一个问题，随着业务复杂度的增加，一个项目中可能会有越来越多的微服务，某个模块可能需要调用多个微服务获取不同的信息，那么就需要在配置文件中配置多个微服务的地址。可是，在需要调用这些微服务的代码中，如果这样一个个去使用 `@Value` 注解引入相应的微服务地址的话，太过于繁琐，也不科学。

所以，在实际项目中，业务繁琐，逻辑复杂的情况下，需要考虑封装一个或多个配置类。举个例子：假如在当前服务中，某个业务需要同时调用订单微服务、用户微服务和购物车微服务，分别获取订单、用户和购物车相关信息，然后对这些信息做一定的逻辑处理。那么在配置文件中，我们需要将这些微服务的地址都配置好：

```xml
# 配置多个微服务的地址
url:
  # 订单微服务的地址
  orderUrl: http://localhost:8002
  # 用户微服务的地址
  userUrl: http://localhost:8003
  # 购物车微服务的地址
  shoppingUrl: http://localhost:8004
```

也许实际业务中，远远不止这三个微服务，甚至十几个都有可能。对于这种情况，我们可以先定义一个 `MicroServiceUrl` 类来专门保存微服务的 url，如下：

```java
@Component
@ConfigurationProperties(prefix = "url")
public class MicroServiceUrl {

    private String orderUrl;
    private String userUrl;
    private String shoppingUrl;
    // 省去get和set方法
}
```

细心的朋友应该可以看到，使用 `@ConfigurationProperties` 注解并且使用 prefix 来指定一个前缀，然后该类中的属性名就是配置中去掉前缀后的名字，一一对应即可。即：前缀名 + 属性名就是配置文件中定义的 key。同时，该类上面需要加上 `@Component` 注解，把该类作为组件放到Spring容器中，让 Spring 去管理，我们使用的时候直接注入即可。

需要注意的是，使用 `@ConfigurationProperties` 注解需要导入它的依赖：

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-configuration-processor</artifactId>
    <optional>true</optional>
</dependency>
```

OK，到此为止，我们将配置写好了，接下来写个 Controller 来测试一下。此时，不需要在代码中一个个引入这些微服务的 url 了，直接通过 `@Resource` 注解将刚刚写好配置类注入进来即可使用了，非常方便。如下：

```java
@RestController
@RequestMapping("/test")
public class TestController {

    private static final Logger LOGGER = LoggerFactory.getLogger(TestController.class);

    @Resource
    private MicroServiceUrl microServiceUrl;

    @RequestMapping("/config")
    public String testConfig() {
        LOGGER.info("=====获取的订单服务地址为：{}", microServiceUrl.getOrderUrl());
        LOGGER.info("=====获取的用户服务地址为：{}", microServiceUrl.getUserUrl());
        LOGGER.info("=====获取的购物车服务地址为：{}", microServiceUrl.getShoppingUrl());

        return "success";
    }
}
```

再次启动项目，请求一下可以看到，控制台打印出如下信息，说明配置文件生效，同时正确获取配置文件内容：

```
=====获取的订单服务地址为：http://localhost:8002
=====获取的订单服务地址为：http://localhost:8002
=====获取的用户服务地址为：http://localhost:8003
=====获取的购物车服务地址为：http://localhost:8004
```

## 3. 指定项目配置文件

我们知道，在实际项目中，一般有两个环境：开发环境和生产环境。开发环境中的配置和生产环境中的配置往往不同，比如：环境、端口、数据库、相关地址等等。我们不可能在开发环境调试好之后，部署到生产环境后，又要将配置信息全部修改成生产环境上的配置，这样太麻烦，也不科学。

最好的解决方法就是开发环境和生产环境都有一套对用的配置信息，然后当我们在开发时，指定读取开发环境的配置，当我们将项目部署到服务器上之后，再指定去读取生产环境的配置。

我们新建两个配置文件： `application-dev.yml` 和 `application-pro.yml`，分别用来对开发环境和生产环境进行相关配置。这里为了方便，我们分别设置两个访问端口号，开发环境用 8001，生产环境用 8002.

```xml
# 开发环境配置文件
server:
  port: 8001
# 开发环境配置文件
server:
  port: 8002
```

然后在 `application.yml` 文件中指定读取哪个配置文件即可。比如我们在开发环境下，指定读取 `applicationn-dev.yml` 文件，如下：

```xml
spring:
  profiles:
    active:
    - dev
```

这样就可以在开发的时候，指定读取  `application-dev.yml` 文件，访问的时候使用 8001 端口，部署到服务器后，只需要将 `application.yml` 中指定的文件改成 `application-pro.yml` 即可，然后使用 8002 端口访问，非常方便。

## 4. 总结

本节主要讲解了 Spring Boot  中如何在业务代码中读取相关配置，包括单一配置和多个配置项，在微服务中，这种情况非常常见，往往会有很多其他微服务需要调用，所以封装一个配置类来接收这些配置是个很好的处理方式。除此之外，例如数据库相关的连接参数等等，也可以放到一个配置类中，其他遇到类似的场景，都可以这么处理。最后介绍了开发环境和生产环境配置的快速切换方式，省去了项目部署时，诸多配置信息的修改。