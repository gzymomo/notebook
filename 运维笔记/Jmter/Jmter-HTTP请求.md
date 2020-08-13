[TOC]

启动jmeter，默认有一个测试计划，然后，修改计划名称，尽量使其变得有意义，容易看懂，然后，新建一个线程组：
![](https://images2015.cnblogs.com/blog/983980/201609/983980-20160928152617422-1378045112.png)

这里线程数我设置为1，方便演示:
![](https://images2015.cnblogs.com/blog/983980/201609/983980-20160928152722453-1241203977.png)

然后，添加一个http信息头管理器
![](https://images2015.cnblogs.com/blog/983980/201609/983980-20160928153639985-56560490.png)

这里解释一下为什么要添加http信息头管理器：
JMeter不是浏览器，因此其行为并不和浏览器完全一致。这些JMeter提供的配置元件中的HTTP属性管理器用于尽可能模拟浏览器行为，在HTTP协议层上发送给被测应用的http请求

1. HTTP Request Defaults（**请求默认值**）
   用于设置其作用范围内的所有HTTP的默认值，可被设置的内容包括HTTP请求的host、端口、协议等
2. HTTP Authorization Manager（**授权管理器**）
   用于设置自动对一些需要NTLM验证的页面进行认证和登录
3. HTTP Cache Manager
   用于模拟浏览器的Cache行为。为Test Plan增加该属性管理器后，Test Plan运行过程中会使用Last-Modified、ETag和Expired等决定是否从Cache中获取相应的元素
4. HTTP Cookie Manager（**cookie管理器**）
   用于管理Test Plan运行时的所有Cookie。HTTP Cookie Manager可以自动储存服务器发送给客户端的所有Cookie，并在发送请求时附加上合适的Cookie
   同时，用户也可以在HTTP Cookie Manager中手工添加一些Cookie，这些被手工添加的Cookie会在发送请求时被自动附加到请求
5. HTTP Header Manager（**信息头管理器**）
   用于定制Sampler发出的HTTP请求的请求头的内容。不同的浏览器发出的HTTP请求具有不同的Agent
   访问某些有防盗链的页面时需要正确的Refer...这些情况下都需要通过HTTP Header Manager来保证发送的HTTP请求是正确的

http信息头管理器添加好之后，需要填入信息头的名称以及对应的值，如下：
![](https://images2015.cnblogs.com/blog/983980/201609/983980-20160928163608813-1964568931.png)

Content-Type意思可以理解为参数名称、类型，值下面输入对应的参数类型就行了，这里我测试时候需要传输json类型，因此就填入了application/json

接着，添加Sampler（取样器）→http请求
![](https://images2015.cnblogs.com/blog/983980/201609/983980-20160928164122203-1957824966.png)

按照截图所示，填入测试的服务器地址、端口、所用的户协议、方法，这里方法我用的是POST，然后填入路径，选择Body Data；
关于http请求的的属性参数说明：
1. 名称：用于标识一个sample。建议使用一个有意义的名称
2. 注释：对于测试没任何影响，仅用来记录用户可读的注释信息
3. 服务器名称或IP：http请求发送的目标服务器名称或者IP地址，比如http://www.baidu.com
4. 端口号：目标服务器的端口号，默认值为80，可不填
5. 协议：向目标服务器发送http请求时的协议，http/https，大小写不敏感，默认http
6. 方法：发送http请求的方法(链接：http://www.cnblogs.com/imyalost/p/5630940.html）
7. Content encoding：内容的编码方式（Content-Type=application/json;charset=utf-8）
8. 路径：目标的URL路径（不包括服务器地址和端口）
9. 自动重定向：如果选中该项，发出的http请求得到响应是301/302，jmeter会重定向到新的界面
10. Use keep Alive：jmeter 和目标服务器之间使用 Keep-Alive方式进行HTTP通信（默认选中）
11. Use multipart/from-data for HTTP POST ：当发送HTTP POST 请求时，使用
12. Parameters、Body Data以及Files Upload的区别：
  1. parameter是指函数定义中参数，而argument指的是函数调用时的实际参数
  2. 简略描述为：parameter=形参(formal parameter)， argument=实参(actual parameter)
  3. 在不很严格的情况下，现在二者可以混用，一般用argument，而parameter则比较少用
   While defining method, variables passed in the method are called parameters.
   当定义方法时，传递到方法中的变量称为参数.
   While using those methods, values passed to those variables are called arguments.
   当调用方法时，传给变量的值称为引数.（有时argument被翻译为“引数“）
  4. Body Data指的是实体数据，就是请求报文里面主体实体的内容，一般我们向服务器发送请求，携带的实体主体参数，可以写入这里
  5. Files Upload指的是：从HTML文件获取所有有内含的资源：被选中时，发出HTTP请求并获得响应的HTML文件内容后还对该HTML
   进行Parse 并获取HTML中包含的所有资源（图片、flash等）：（默认不选中）
   如果用户只希望获取特定资源，可以在下方的Embedded URLs must match 文本框中填入需要下载的特定资源表达式，只有能匹配指定正则表达式的URL指向资源会被下载

接下来可以给这个测试计划添加一个监视器，常用的监视器有“查看结果树”和“聚合报告”

添加好监视器，点击运行，开始测试
![](https://images2015.cnblogs.com/blog/983980/201609/983980-20160928182747219-792549068.png)

如上，测试结束后，如果我们的请求成功发送给服务器，那么结果树里面的模拟请求会显示为绿色，可以通过取样器结果里面的响应状态码信息来判断

也可以点击请求模块，查看我们发送的请求
![](https://images2015.cnblogs.com/blog/983980/201609/983980-20160928182949703-1222889685.png)

里面有我们发送的请求的方法、协议、地址以及实体主体数据，以及数据类型，大小，发送时间，客户端版本等信息

响应数据：里面包含服务器返回给我们的响应数据实体，如下图：
![](https://images2015.cnblogs.com/blog/983980/201609/983980-20160928183147438-1842223308.png)