[TOC]

Zuul作为网关的其中一个重要功能，就是实现请求的鉴权,通过Zuul提供的过滤器来实现的。
在 1.x 版本中使用的是 Zuul 网关，但是到了 2.x，由于Zuul的升级不断跳票，Spring Cloud 自己研发了一套网关组件：Spring Cloud Gateway。

# 1、过滤器方法的作用
想要使用Zuul实现过滤功能，我们需要自定义一个类继承ZuulFilter类，并实现其中的四个方法，我们先看一下这四个方法的作用是什么。
```java
public class MyFilter extends ZuulFilter {
    /**
     * filterType：返回字符串，代表过滤器的类型。包含以下4种：
     * -- pre：请求在被路由之前执行
     * -- route：在路由请求时调用
     * -- post：在route和errror过滤器之后调用
     * -- error：处理请求时发生错误调用
     * @return 返回以上四个类型的名称
     */
    @Override
    public String filterType() {
        return null;
    }

    /**
     * filterOrder：通过返回的int值来定义过滤器的执行顺序，数字越小优先级越高。
     * @return
     */
    @Override
    public int filterOrder() {
        return 0;
    }

    /**
     * shouldFilter：返回一个Boolean值，判断该过滤器是否需要执行。返回true执行，返回false不执行。
     * @return
     */
    @Override
    public boolean shouldFilter() {
        return false;
    }

    /**
     * run：编写过滤器的具体业务逻辑。
     * @return
     * @throws ZuulException
     */
    @Override
    public Object run() throws ZuulException {
        return null;
    }
}
```

# 2、自定义过滤器
```java
@Component
public class LoginFilter extends ZuulFilter {

    //过滤类型 pre route post error
    @Override
    public String filterType() {
        return "pre";
    }

    //过滤优先级，数字越小优先级越高
    @Override
    public int filterOrder() {
        return 10;
    }

    //是否执行run方法
    @Override
    public boolean shouldFilter() {
        return true;
    }

    //过滤逻辑代码
    @Override
    public Object run() throws ZuulException {
        //获取zuul提供的上下文对象
        RequestContext context = RequestContext.getCurrentContext();
        //获取request对象
        HttpServletRequest request = context.getRequest();
        //获取请求参数
        String token = request.getParameter("username");
        //判断
        if (StringUtils.isBlank(username)){
            //过滤该请求，不对其进行路由
            context.setSendZuulResponse(false);
            //设置响应码401
            context.setResponseStatusCode(HttpStatus.SC_UNAUTHORIZED);
            //设置响应体
            context.setResponseBody("request error....");
        }
        // 校验通过，把登陆信息放入上下文信息，继续向后执行
        context.set("username",username);
        return null;
    }
}
```
没添加过滤功能之前是这样的 ↓，无论加不加username都可以得到数据:
![](https://oscimg.oschina.net/oscnet/up-1a5651610b01b9c7575679627b5d0536676.png)

![](https://oscimg.oschina.net/oscnet/up-0af5e106640953ef97453a51af59f8a751b.png)

添加了过滤功能之后是这样的 ↓，只有加了username才能访问
![](https://oscimg.oschina.net/oscnet/up-2ff2102e6e05b3e0ed284427a03efb51d15.png)

![](https://oscimg.oschina.net/oscnet/up-babab84f1ea7f7ec9207f5c4332e6071831.png)

# 3、过滤器执行的声明周期
![](https://oscimg.oschina.net/oscnet/up-61f6470431d6b3957068fce575e77ea39ac.png)

正常流程：

- 请求到达首先会经过pre类型过滤器，而后到达route类型，进行路由，请求就到达真正的服务提供者，执行请求，返回结果后，会到达post过滤器。而后返回响应。

异常流程：

- 整个过程中，pre或者route过滤器出现异常，都会直接进入error过滤器，在error处理完毕后，会将请求交给POST过滤器，最后返回给用户。
- 如果是error过滤器自己出现异常，最终也会进入POST过滤器，将最终结果返回给请求客户端。
- 如果是POST过滤器出现异常，会跳转到error过滤器，但是与pre和route不同的是，请求不会再到达POST过滤器了。