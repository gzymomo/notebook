- [前端小组长的 Code Review 分享](https://juejin.cn/post/7052570403029385253)

> 项目背景:
>
> - react 16.8+
> - antd@4

## 💻 Talk is cheap. Show me the code！

### `location.replace` 和 `location.href`的使用区别

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/5bd1c43183064dc1bce803d26001197b~tplv-k3u1fbpfcp-watermark.awebp)

### 正则判断没有对用户可能输入的特殊符号进行转义

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/40b91e8b81054d6282cd9acf0a5dda1c~tplv-k3u1fbpfcp-watermark.awebp)

> 解析：
>  该组件本意是想实现对一串字符中的关键字进行高亮展示；
>  而正则表达式中有些字符具有特殊的含义，如果在匹配中要用到它本来的含义，需要进行转义（在其前面加一个\）。如：`* . ? + $ ^ [ ] ( ) { } | \ /`

### Table行点击事件的处理

这里示例代码想实现点击表格行跳转页面效果，但是会导致一些鼠标操作被覆盖

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/5bbe8227a8024b188510d43bb8fa8129~tplv-k3u1fbpfcp-watermark.awebp)

### 在一个较大的组件内，需要注意输入组件导致的重渲染问题

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/4e13fddfcd634e848c508d57eff09bcc~tplv-k3u1fbpfcp-watermark.awebp)

### 避免使用反直觉的编码

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/0b358a0a013c4c73b800cd89d2560ef1~tplv-k3u1fbpfcp-watermark.awebp)

### 做好路由字符串拼接的缺省处理

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/66968f4594bf4ecb98a5b908badd673e~tplv-k3u1fbpfcp-watermark.awebp)

### 没有还原本地测试代码

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/51d466b6e2d342f7800943b82c479ba5~tplv-k3u1fbpfcp-watermark.awebp)

> 解析：
>  一些本地运行时的mock代码，发到线上时忘记还原代码

### 维护好项目内的公共组件

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/1b5fe91c668745658e231b47a7244240~tplv-k3u1fbpfcp-watermark.awebp)

## 


作者：悄悄哥
链接：https://juejin.cn/post/7052570403029385253
来源：稀土掘金
著作权归作者所有。商业转载请联系作者获得授权，非商业转载请注明出处。