在日常开发中，总会接触到各种接口。前后端数据传输接口，第三方业务平台接口。一个平台的前后端数据传输接口一般都会在内网环境下通信，而且会使用安全框架，所以安全性可以得到很好的保护。这篇文章重点讨论一下提供给第三方平台的业务接口应当如何设计？我们应该考虑哪些问题？

![img](https://img2020.cnblogs.com/blog/1719198/202010/1719198-20201016202953711-1715594493.png)

主要从以上三个方面来设计一个安全的API接口。

## 一 安全性问题

安全性问题是一个接口必须要保证的规范。如果接口保证不了安全性，那么你的接口相当于直接暴露在公网环境中任人蹂躏。

### 1.1 调用接口的先决条件-token

获取token一般会涉及到几个参数`appid`，`appkey`，`timestamp`，`nonce`，`sign`。我们通过以上几个参数来获取调用系统的凭证。

`appid`和`appkey`可以直接通过平台线上申请，也可以线下直接颁发。`appid`是全局唯一的，每个`appid`将对应一个客户，`appkey`需要高度保密。

`timestamp`是时间戳，使用系统当前的unix时间戳。时间戳的目的就是为了减轻DOS攻击。防止请求被拦截后一直尝试请求接口。服务器端设置时间戳阀值，如果请求时间戳和服务器时间超过阀值，则响应失败。

`nonce`是随机值。随机值主要是为了增加`sign`的多变性，也可以保护接口的幂等性，相邻的两次请求`nonce`不允许重复，如果重复则认为是重复提交，响应失败。

`sign`是参数签名，将`appkey`，`timestamp`，`nonce`拼接起来进行md5加密（当然使用其他方式进行不可逆加密也没问题）。

`token`，使用参数`appid`，`timestamp`，`nonce`，`sign`来获取token，作为系统调用的唯一凭证。`token`可以设置一次有效（这样安全性更高），也可以设置时效性，这里推荐设置时效性。如果一次有效的话这个接口的请求频率可能会很高。`token`推荐加到请求头上，这样可以跟业务参数完全区分开来。

### 1.2 使用POST作为接口请求方式

一般调用接口最常用的两种方式就是GET和POST。两者的区别也很明显，GET请求会将参数暴露在浏览器URL中，而且对长度也有限制。为了更高的安全性，所有接口都采用POST方式请求。

### 1.3 客户端IP白名单

ip白名单是指将接口的访问权限对部分ip进行开放。这样就能避免其他ip进行访问攻击，设置ip白名单比较麻烦的一点就是当你的客户端进行迁移后，就需要重新联系服务提供者添加新的ip白名单。设置ip白名单的方式很多，除了传统的防火墙之外，spring cloud alibaba提供的组件sentinel也支持白名单设置。为了降低api的复杂度，推荐使用防火墙规则进行白名单设置。

### 1.4 单个接口针对ip限流

限流是为了更好的维护系统稳定性。使用redis进行接口调用次数统计，ip+接口地址作为key，访问次数作为value，每次请求value+1，设置过期时长来限制接口的调用频率。

### 1.5 记录接口请求日志

使用aop全局记录请求日志，快速定位异常请求位置，排查问题原因。

### 1.6 敏感数据脱敏

在接口调用过程中，可能会涉及到订单号等敏感数据，这类数据通常需要脱敏处理，最常用的方式就是加密。加密方式使用安全性比较高的`RSA`非对称加密。非对称加密算法有两个密钥，这两个密钥完全不同但又完全匹配。只有使用匹配的一对公钥和私钥，才能完成对明文的加密和解密过程。

## 二 幂等性问题

幂等性是指任意多次请求的执行结果和一次请求的执行结果所产生的影响相同。说的直白一点就是查询操作无论查询多少次都不会影响数据本身，因此查询操作本身就是幂等的。但是新增操作，每执行一次数据库就会发生变化，所以它是非幂等的。

幂等问题的解决有很多思路，这里讲一种比较严谨的。提供一个生成随机数的接口，随机数全局唯一。调用接口的时候带入随机数。第一次调用，业务处理成功后，将随机数作为key，操作结果作为value，存入redis，同时设置过期时长。第二次调用，查询redis，如果key存在，则证明是重复提交，直接返回错误。

## 三 数据规范问题

### 3.1 版本控制

一套成熟的API文档，一旦发布是不允许随意修改接口的。这时候如果想新增或者修改接口，就需要加入版本控制，版本号可以是整数类型，也可以是浮点数类型。一般接口地址都会带上版本号，[http://ip](http://ip/):port//v1/list。

### 3.2 响应状态码规范

一个牛逼的API，还需要提供简单明了的响应值，根据状态码就可以大概知道问题所在。我们采用http的状态码进行数据封装，例如200表示请求成功，4xx表示客户端错误，5xx表示服务器内部发生错误。状态码设计参考如下：

| 分类 | 描述                                         |
| ---- | -------------------------------------------- |
| 1xx  | 信息，服务器收到请求，需要请求者继续执行操作 |
| 2xx  | 成功                                         |
| 3xx  | 重定向，需要进一步的操作以完成请求           |
| 4xx  | 客户端错误，请求包含语法错误或无法完成请求   |
| 5xx  | 服务端错误                                   |

状态码枚举类：

```java
public enum CodeEnum {

    // 根据业务需求进行添加
    SUCCESS(200,"处理成功"),
    ERROR_PATH(404,"请求地址错误"),
    ERROR_SERVER(505,"服务器内部发生错误");
    
    private int code;
    private String message;
    
    CodeEnum(int code, String message) {
        this.code = code;
        this.message = message;
    }

    public int getCode() {
        return code;
    }

    public void setCode(int code) {
        this.code = code;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }
}
```

### 3.3 统一响应数据格式

为了方便给客户端响应，响应数据会包含三个属性，状态码（code）,信息描述（message）,响应数据（data）。客户端根据状态码及信息描述可快速知道接口，如果状态码返回成功，再开始处理数据。

响应结果定义及常用方法：

```java
public class R implements Serializable {

    private static final long serialVersionUID = 793034041048451317L;

    private int code;
    private String message;
    private Object data = null;

    public int getCode() {
        return code;
    }
    public void setCode(int code) {
        this.code = code;
    }

    public String getMessage() {
        return message;
    }
    public void setMessage(String message) {
        this.message = message;
    }

    public Object getData() {
        return data;
    }

    /**
     * 放入响应枚举
     */
    public R fillCode(CodeEnum codeEnum){
        this.setCode(codeEnum.getCode());
        this.setMessage(codeEnum.getMessage());
        return this;
    }

    /**
     * 放入响应码及信息
     */
    public R fillCode(int code, String message){
        this.setCode(code);
        this.setMessage(message);
        return this;
    }

    /**
     * 处理成功，放入自定义业务数据集合
     */
    public R fillData(Object data) {
        this.setCode(CodeEnum.SUCCESS.getCode());
        this.setMessage(CodeEnum.SUCCESS.getMessage());
        this.data = data;
        return this;
    }
}
```

## 总结

本篇文章从安全性、幂等性、数据规范等方面讨论了API设计规范。除此之外，一个好的API还少不了一个优秀的接口文档。接口文档的可读性非常重要，虽然很多程序员都不喜欢写文档，而且不喜欢别人不写文档。为了不增加程序员的压力，推荐使用swagger或其他接口管理工具，通过简单配置，就可以在开发中测试接口的连通性，上线后也可以生成离线文档用于管理API。