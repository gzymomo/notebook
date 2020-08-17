Web漏洞扫描-Burp Suite

# 一、Burp Suite概述
安全渗透界使用最广泛的漏扫工具之一，能实现从漏洞发现到利用的完整过程。功能强大、配置较为复杂、可定制型强，支持丰富的第三方拓展插件。基于Java编写，跨平台支持，收费，不过有Free版本，功能较少。
https://portswigger.net/burp/

# 二、功能及特点
![](https://www.showdoc.cc/server/api/common/visitfile/sign/6daa6f75acb6454b085df43958b45c41?showdoc=.jpg)

 - Target 目标模块用于设置扫描域(target scope)、 生成站点地图(sitemap)、 生成安全分析
 - Proxy 代理模块用于拦截浏览器的http会话内容
 - Spider 爬虫模块用于自动爬取网站的每个页面内容,并生成完整的网站地图
 - Scanner 扫描模块用于自动化检测漏洞,分为主动和被动扫描
 - Intruder 入侵(渗透)模块根据上面检测到的可能存在漏洞的链接，调用攻击载荷,对目标链接进行攻击
 - 入侵模块的原理是根据访问链接中存在的参数/变量,调用本地词典、攻击载荷，对参数进行渗透测试
 - Repeater 重放模块用于实现请求重放,通过修改参数进行手工请求回应的调试
 - Sequencer 序列器模块用于检测参数的随机性,例如密码或者令牌是否可预测，以此判断关键数据是否可被伪造
 - Decoder 解码器模块用于实现对URL、HTML、 Base64、 ASCII、 二/八/十六进制、 哈希等编码转换
 - Comparer 对比模块用于对两次不同的请求和回应进行可视化对比,以此区分不同参数对结果造成的影响
 - Extender 拓展模块是burpsuite非常强悍的一一个功能，也是它跟其他Web安全评估系统最大的差别
 - 通过拓展模块，可以加载自己开发的、或者第三方模块,打造自己的burpsuite功能
 - 通过burpsuite提供的API接口，目前可以支持Java、Python、 Ruby三种语言的模块编写
 - Options 分为Project/User Options，主要对软件进行全局设置
 - Alerts 显示软件的使用日志信息

# 三、Burp Suite安装
Kali Linux:集成BurpSuite Free版本 ,不支持scanner功能
Windows :BurpSuite Pro 1. 7.30版本,支持全部功能。

启动方法:
`java -jar -Xmx1024M /burpsuite_path/BurpHe1per. jar`

# 四、Burp Suite使用
 - 代理功能（Proxy）
 - 目标功能（Target）
 - 爬虫功能（Spider）
 - 扫描功能（Scanner）





