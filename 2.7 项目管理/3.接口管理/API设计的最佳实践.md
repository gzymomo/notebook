- [API设计的最佳实践](https://mp.weixin.qq.com/s/O_qKVwZUFvFpocHbzrh1Ig)

任何API设计都遵循一种叫做“面向资源设计”的原则：

- 资源：资源是数据的一部分，例如：用户
- 集合：一组资源称为集合，例如：用户列表
- URL：标识资源或集合的位置，例如：/user

## 1. 对URL使用kebab-case（短横线小写隔开形式）

例如，如果你想要获得订单列表。

不应该：

```
/systemOrders或/system_orders
```

应该：

```
/system-orders
```

## 2. 参数使用camelCase（驼峰形式）

例如，如果你想从一个特定的商店购买产品。

不应该：

```
/system-orders/{order_id}
```

或者：

```
/system-orders/{OrderId}
```

应该：

```
/system-orders/{orderId}
```

## 3. 指向集合的复数名称

如果你想获得系统的所有用户。

不应该：

```
GET /user
```

或：

```
GET /User
```

应该：

```
GET /users
```

## 4. URL以集合开始，以标识符结束

如果要保持概念的单一性和一致性。

不应该：

```
GET /shops/:shopId/category/:categoryId/price
```

这很糟糕，因为它指向的是一个属性而不是资源。

应该：

```
GET /shops/:shopId/或GET /category/:categoryId
```

## 5. 让动词远离你的资源URL

不要在URL中使用动词来表达你的意图。相反，使用适当的HTTP方法来描述操作。

不应该：

```
POST /updateuser/{userId}
```

或：

```
GET /getusers
```

应该：

```
PUT /user/{userId}
```

## 6. 对非资源URL使用动词

如果你有一个端点，它只返回一个操作。在这种情况下，你可以使用动词。例如，如果你想要向用户重新发送警报。

应该：

```
POST /alarm/245743/resend
```

请记住，这些不是我们的CRUD操作。相反，它们被认为是在我们的系统中执行特定工作的函数。

## 7. JSON属性使用camelCase驼峰形式

如果你正在构建一个请求体或响应体为JSON的系统，那么属性名应该使用驼峰大小写。

不应该：

```
{
   user_name: "Mohammad Faisal"
   user_id: "1"
}
```

应该：

```
{
   userName: "Mohammad Faisal"
   userId: "1"
}
```

## 8. 监控

RESTful HTTP服务必须实现/health和/version和/metricsAPI端点。他们将提供以下信息。

**/health**

用200 OK状态码响应对/health的请求。

**/version**

用版本号响应对/version的请求。

**/metrics**

这个端点将提供各种指标，如平均响应时间。

也强烈推荐使用/debug和/status端点。

## 9. 不要使用table_name作为资源名

不要只使用表名作为资源名。从长远来看，这种懒惰是有害的。

不应该：

```
product_order
```

应该：

```
product-orders
```

这是因为公开底层体系结构不是你的目的。

## 10. 使用API设计工具

有许多好的API设计工具用于编写好的文档，例如：

- API蓝图：https://apiblueprint.org/
- Swagger：https://swagger.io/

拥有良好而详细的文档可以为API使用者带来良好的用户体验。

## 11. 使用简单序数作为版本

始终对API使用版本控制，并将其向左移动，使其具有最大的作用域。版本号应该是v1，v2等等。

应该：http://api.domain.com/v1/shops/3/products

始终在API中使用版本控制，因为如果API被外部实体使用，更改端点可能会破坏它们的功能。

## 12. 在你的响应体中包括总资源数

如果API返回一个对象列表，则响应中总是包含资源的总数。你可以为此使用total属性。

不应该：

```
{
  users: [ 
     ...
  ]
}
```

应该：

```
{
  users: [ 
     ...
  ],
  total: 34
}
```

## 13. 接受limit和offset参数

在GET操作中始终接受limit和offset参数。

应该：

```
GET /shops?offset=5&limit=5
```

这是因为它对于前端的分页是必要的。

## 14. 获取字段查询参数

返回的数据量也应该考虑在内。添加一个fields参数，只公开API中必需的字段。

例子：

只返回商店的名称，地址和联系方式。

```
GET /shops?fields=id,name,address,contact
```

在某些情况下，它还有助于减少响应大小。

## 15. 不要在URL中通过认证令牌

这是一种非常糟糕的做法，因为url经常被记录，而身份验证令牌也会被不必要地记录。

不应该：

```
GET /shops/123?token=some_kind_of_authenticaiton_token
```

相反，通过头部传递它们：

```
Authorization: Bearer xxxxxx, Extra yyyyy
```

此外，授权令牌应该是短暂有效期的。

## 16. 验证内容类型

服务器不应该假定内容类型。例如，如果你接受application/x-www-form-urlencoded，那么攻击者可以创建一个表单并触发一个简单的POST请求。

因此，始终验证内容类型，如果你想使用默认的内容类型，请使用：

```
content-type: application/json
```

## 17. 对CRUD函数使用HTTP方法

HTTP方法用于解释CRUD功能。

GET：检索资源的表示形式。

POST：创建新的资源和子资源。

PUT：更新现有资源。

PATCH：更新现有资源，它只更新提供的字段，而不更新其他字段。

DELETE：删除已存在的资源。

## 18. 在嵌套资源的URL中使用关系

以下是一些实际例子：

- GET /shops/2/products：从shop 2获取所有产品的列表。
- GET /shops/2/products/31：获取产品31的详细信息，产品31属于shop 2。
- DELETE /shops/2/products/31：应该删除产品31，它属于商店2。
- PUT /shops/2/products/31：应该更新产品31的信息，只在resource-URL上使用PUT，而不是集合。
- POST /shops：应该创建一个新的商店，并返回创建的新商店的详细信息。在集合url上使用POST。

## 19. CORS（跨源资源共享）

一定要为所有面向公共的API支持CORS（跨源资源共享）头部。

考虑支持CORS允许的“*”来源，并通过有效的OAuth令牌强制授权。

避免将用户凭证与原始验证相结合。

## 20. 安全

在所有端点、资源和服务上实施HTTPS（tls加密）。

强制并要求所有回调url、推送通知端点和webhooks使用HTTPS。

## 21. 错误

当客户端向服务发出无效或不正确的请求，或向服务传递无效或不正确的数据，而服务拒绝该请求时，就会出现错误，或者更具体地说，出现服务错误。

例子包括无效的身份验证凭证、不正确的参数、未知的版本id等。

- 当由于一个或多个服务错误而拒绝客户端请求时，一定要返回4xx HTTP错误代码。
- 考虑处理所有属性，然后在单个响应中返回多个验证问题。

## 22. 黄金法则

如果您对API格式的决定有疑问，这些黄金规则可以帮助我们做出正确的决定。

- 扁平比嵌套好。
- 简单胜于复杂。
- 字符串比数字好。
- 一致性比定制更好。