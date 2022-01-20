- [Swagger笔记—Swagger3详细配置](https://mp.weixin.qq.com/s/SCkEov91qNtYC-wkD6cmwQ)

## 什么是 Swagger？

`Swagger`是一组围绕 `OpenAPI` 规范构建的开源工具，可帮助您设计、构建、记录和使用 `REST API`。主要的 `Swagger` 工具包括：`Swagger Editor` – 基于浏览器的编辑器，您可以在其中编写 `OpenAPI` 规范。`Swagger UI` – 将 `OpenAPI` 规范呈现为交互式 `API` 文档。`Swagger2`于17年停止维护，现在最新的版本为 `Swagger3`（Open Api3）。

## 引用依赖

`springfox`引入方式

```xml
<dependency>
    <groupId>io.springfox</groupId>
    <artifactId>springfox-boot-starter</artifactId>
    <version>3.0.0</version>
</dependency>
```

knife4j引入方式

```xml
<dependency>
 <groupId>com.github.xiaoymin</groupId>
 <artifactId>knife4j-spring-boot-starter</artifactId>
 <version>3.0.3</version>
</dependency>
```

引入美化`bootstrap-UI`

```xml
<!-- 引入swagger-bootstrap-ui包 -->
<dependency>
    <groupId>com.github.xiaoymin</groupId>
    <artifactId>swagger-bootstrap-ui</artifactId>
    <version>1.8.5</version>
</dependency>
```

## Swagger3配置

```java
import com.github.xiaoymin.swaggerbootstrapui.annotations.EnableSwaggerBootstrapUI;
import io.swagger.annotations.ApiOperation;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import springfox.documentation.builders.ApiInfoBuilder;
import springfox.documentation.builders.PathSelectors;
import springfox.documentation.builders.RequestHandlerSelectors;
import springfox.documentation.oas.annotations.EnableOpenApi;
import springfox.documentation.service.*;
import springfox.documentation.spi.DocumentationType;
import springfox.documentation.spi.service.contexts.SecurityContext;
import springfox.documentation.spring.web.plugins.Docket;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * @author rongrong
 * @version 1.0
 * @description Swagger3配置
 * @date 2021/01/12 21:00
 */
@Configuration
@Profile({"dev", "local"})
@EnableOpenApi
@EnableSwaggerBootstrapUI
public class SwaggerConfig {

    /**
     * 是否开启swagger配置，生产环境需关闭
     */
    /*    @Value("${swagger.enabled}")*/
    private boolean enable;

    /**
     * 创建API
     * http:IP:端口号/swagger-ui/index.html 原生地址
     * http:IP:端口号/doc.html bootStrap-UI地址
     */
    @Bean
    public Docket createRestApi() {
        return new Docket(DocumentationType.OAS_30).pathMapping("/")
                // 用来创建该API的基本信息，展示在文档的页面中（自定义展示的信息）
                /*.enable(enable)*/
                .apiInfo(apiInfo())
                // 设置哪些接口暴露给Swagger展示
                .select()
                // 扫描所有有注解的api，用这种方式更灵活
                .apis(RequestHandlerSelectors.withMethodAnnotation(ApiOperation.class))
                // 扫描指定包中的swagger注解
                // .apis(RequestHandlerSelectors.basePackage("com.doctorcloud.product.web.controller"))
                // 扫描所有 .apis(RequestHandlerSelectors.any())
                .paths(PathSelectors.regex("(?!/ApiError.*).*"))
                .paths(PathSelectors.any())
                .build()
                // 支持的通讯协议集合
                .protocols(newHashSet("https", "http"))
                .securitySchemes(securitySchemes())
                .securityContexts(securityContexts());

    }

    /**
     * 支持的通讯协议集合
     *
     * @param type1
     * @param type2
     * @return
     */
    private Set<String> newHashSet(String type1, String type2) {
        Set<String> set = new HashSet<>();
        set.add(type1);
        set.add(type2);
        return set;
    }

    /**
     * 认证的安全上下文
     */
    private List<SecurityScheme> securitySchemes() {
        List<SecurityScheme> securitySchemes = new ArrayList<>();
        securitySchemes.add(new ApiKey("token", "token", "header"));
        return securitySchemes;
    }

    /**
     * 授权信息全局应用
     */
    private List<SecurityContext> securityContexts() {
        List<SecurityContext> securityContexts = new ArrayList<>();
        securityContexts.add(SecurityContext.builder()
                .securityReferences(defaultAuth())
                .forPaths(PathSelectors.any()).build());
        return securityContexts;
    }

    private List<SecurityReference> defaultAuth() {
        AuthorizationScope authorizationScope = new AuthorizationScope("global", "accessEverything");
        AuthorizationScope[] authorizationScopes = new AuthorizationScope[1];
        authorizationScopes[0] = authorizationScope;
        List<SecurityReference> securityReferences = new ArrayList<>();
        securityReferences.add(new SecurityReference("Authorization", authorizationScopes));
        return securityReferences;
    }


    /**
     * 添加摘要信息
     * @return 返回ApiInfo对象
     */
    private ApiInfo apiInfo() {
        // 用ApiInfoBuilder进行定制
        return new ApiInfoBuilder()
                // 设置标题
                .title("接口文档")
                // 服务条款
                .termsOfServiceUrl("NO terms of service")
                // 描述
                .description("这是SWAGGER_3生成的接口文档")
                // 作者信息
                .contact(new Contact("rongrong", "https://www.cnblogs.com/longronglang/", "rongrong@gmail.com"))
                // 版本
                .version("版本号:V1.0")
                //协议
                .license("The Apache License")
                // 协议url
                .licenseUrl("http://www.apache.org/licenses/LICENSE-2.0.html")
                .build();
    }
}
```

## 访问路径

```
http:IP:端口号/swagger-ui/index.html 原生地址
http:IP:端口号/doc.html bootStrap-UI地址
```

## 效果

![image-20220120230631006](https://gitee.com/er-huomeng/img/raw/master/img/image-20220120230631006.png)

![image-20220120230638154](https://gitee.com/er-huomeng/img/raw/master/img/image-20220120230638154.png)

## 小技巧：

不建议使用`swagger`原生页面设置权限，建议使用`doc`页面设置`token`，搜索接口更方便(主要是好看) 在这里插入图片描述

![image-20220120230649071](https://gitee.com/er-huomeng/img/raw/master/img/image-20220120230649071.png)