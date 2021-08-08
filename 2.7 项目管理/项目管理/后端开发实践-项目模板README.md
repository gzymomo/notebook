- 整理出一套公共性的项目模板，旨在尽量多地包含日常开发所需，减少开发者的重复性工作以及提供一些最佳实践。

# 1. 从写好README开始

一个好的README给人以项目概览，可以使新人快速上手项目，并降低沟通成本，建议包括：

- 项目简介

- - 一两句话描述该项目实现的业务功能

- 技术选型

- - 项目的技术栈，包括语言，框架，中间件等

- 本地构建

- - 列出本地开发过程中所用到的工具命令

- 领域模型

- - 核心的领域概念，针对于当前系统所在的领域

- 测试策略

- - 自动化测试如何分类

- 技术架构

- - 技术架构图

- 部署架构

- - 部署架构图

- 外部依赖

- - 项目运行时所以来的外部集成方

- 环境信息

- - 各个环境的访问方式，数据库连接

- 编码实践

- - 统一的编码实践，比如异常处理原则，分页封装等

- FAQ

- - 开发过程中常见问题的解答

注意保持README的持续更新，一些重要的架构决定可以通过示例代码的形式记录在代码块当中，新开发者可以通过直接阅读这些示例代码快速了解项目的通用实践方式以及架构选择

# 2. 一键式本地构建

写一个必需的script，自动化完成本地构建的过程

- `run.sh` 进行本地调试或者必要的手动测试
- `local-build.sh`，完成本地构建

# 3. 日志处理

- 在日志中加入请求标识，便于链路追踪。在处理一个请求的过程中有时会输出多条日志，如果每条日志都共享统一的请求ID，那么在日志追踪时会更加方便。此时，可以使用Logback原生提供的MDC(Mapped Diagnostic Context)功能，创建一个RequestIdMdcFilter

```
    protected void doFilterInternal(HttpServletRequest request,
                                HttpServletResponse response,
                                FilterChain filterChain)
        throws ServletException, IOException {
    //request id in header may come from Gateway, eg. Nginx
    String headerRequestId = request.getHeader(HEADER_X_REQUEST_ID);
    MDC.put(REQUEST_ID, isNullOrEmpty(headerRequestId) ? newUuid() : headerRequestId);
    try {
        filterChain.doFilter(request, response);
    } finally {
        clearMdc();
    }
}
```

- 集中式日志管理，在多节点部署的场景下，各个节点的日志是分散的，为此可以引入诸如ELK之类的工具将日志统一输出到ElasticSearch中。

```
<appender name="REDIS" class="com.cwbase.logback.RedisAppender">
    <tags>ecommerce-order-backend-${ACTIVE_PROFILE}</tags>
    <host>elk.yourdomain.com</host>
    <port>6379</port>
    <password>whatever</password>
    <key>ecommerce-ordder-log</key>
    <mdc>true</mdc>
    <type>redis</type>
</appender>12345678
```

# 4. 异常处理

在设计异常处理的框架的时候，需要考虑到：

- 向客户端提供格式统一的异常返回
- 异常信息中应该包含足够多的上下文信息，最好是结构化的数据以便于客户端解析
- 不同类型的异常应该包含唯一标识，以便客户端精确识别

异常处理有两种处理形式，一种是层级式，即每种具体的异常都对应了一个异常类，这些类最终继承自某个父异常；另外一种是单一式，即整个程序中只有一个异常类，再以一个字段来区分不同的异常场景。层级式异常的好处能够显化异常的含义，但是如果设计不好可能会导致程序中大量的异常类。

使用层级式异常的范例：

```
public abstract class AppException extends RuntimeException {
    private final ErrorCode code;
    private final Map<String, Object> data = newHashMap();
}
```

这里，ErrorCode枚举中包含了异常的唯一标识、HTTP状态码以及错误信息；而data字段表示各个异常的上下文信息。

```
public class OrderNotFoundException extends AppException {
    public OrderNotFoundException(OrderId orderId) {
        super(ErrorCode.ORDER_NOT_FOUND, ImmutableMap.of("orderId", orderId.toString()));
    }
}
```

在返回给客户端的时候，通过一个ErrorDetail类来统一异常格式：

```
public final class ErrorDetail {
    private final ErrorCode code;
    private final int status;
    private final String message;
    private final String path;
    private final Instant timestamp;
    private final Map<String, Object> data = newHashMap();
}
```

最终返回给客户端的数据为：

```
{
  requestId: "d008ef46bb4f4cf19c9081ad50df33bd",
  error: {
    code: "ORDER_NOT_FOUND",
    status: 404,
    message: "没有找到订单",
    path: "/order",
    timestamp: 1555031270087,
    data: {
      orderId: "123456789"
    }
  }
}
```

# 5. 统一代码风格

除了Checkstyle以外，项目中有些通用的公共编码实践方式也需要进行统一。

- 客户端的请求数据类统一使用相同后缀，比如Command
- 返回给客户端的数据统一使用相同后缀，比如Represetation
- 统一对请求处理的流程框架，比如采用传统的3层架构或者DDD战术模式
- 提供一致的异常返回（请参考“异常处理”小节）
- 提供统一的分页结构类
- 明确测试分类以及统一的测试基础类（请参考“自动化测试分类”小节）