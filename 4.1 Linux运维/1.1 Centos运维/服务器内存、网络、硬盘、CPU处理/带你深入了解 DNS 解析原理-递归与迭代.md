- [带你深入了解 DNS 解析原理-递归与迭代](https://blog.51cto.com/wzlinux/4582497)

# 一、什么是DNS

域名系统 (DNS) 将人类可读的域名 (例如，www.amazon.com) 转换为机器可读的 IP 地址 (例如，192.0.2.44)。

## DNS 服务的类型

**权威 DNS（Authoritative DNS**）：处于 DNS  服务端的一套系统，该系统保存了相应域名的权威信息。权威 DNS 即通俗上“这个域名我说了算”的服务器。权威 DNS 包含 DNS  查询的最终答案，通常是 IP 地址。客户端（例如移动设备、在云中运行的应用程序或数据中心中的服务器）实际上并不直接与权威 DNS  服务通信，但极少数情况例外。如 Amazon Route 53、Aliyun 云解析、Azure DNS zone、Google Cloud  DNS 等服务都是一种权威型 DNS。

**递归 DNS（Recursive DNS）**：又叫 LocalDNS。递归 DNS  可以理解为是一种功能复杂些的  resolver，其核心功能一个是缓存、一个是递归查询。收到域名查询请求后其首先看本地缓存是否有记录，如果没有则一级一级的查询根、顶级域、二级域……直到获取到结果然后返回给用户。日常上网中运营商分配的 DNS 即这里所说的递归 DNS。递归型 DNS 服务就像是旅馆的门童：尽管没有任何自身的 DNS 记录，但是可充当代表您获得 DNS  信息的中间程序。如 Route 53 解析程序、Google Public  DNS(8.8.8.8)、114dns(114.114.114.114) 等是一种公共 DNS 服务，也是递归 DNS 服务。

# 二、DNS 查询流程

下图概述了递归型和权威型 DNS 服务如何协同工作以将终端用户路由到您的网站或应用程序。

![image-20211112142922813](https://s4.51cto.com/images/blog/202111/12220037_618e7385595a531378.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)

1. 用户打开 Web 浏览器，在地址栏中输入 www.example.com，然后按 Enter 键。
2. www.example.com 的请求被路由到 DNS 解析程序，这一般由用户的互联网服务提供商 (ISP) 进行管理，例如有线 Internet 服务提供商、DSL 宽带提供商或公司网络。
3. ISP 的 DNS 解析程序将 www.example.com 的请求转发到 DNS 根名称服务器。
4. ISP 的 DNS 解析程序再次转发 www.example.com 的请求，这次转发到 .com 域的一个 TLD  名称服务器。.com 域的名称服务器使用与 example.com 域相关的四个 Amazon Route 53 名称服务器的名称来响应该请求。
5. ISP 的 DNS 解析程序选择一个 Amazon Route 53 名称服务器，并将 www.example.com 的请求转发到该名称服务器。
6. Amazon Route 53 名称服务器在 example.com 托管区域中查找 www.example.com 记录，获得相关值，例如，Web 服务器的 IP 地址 (192.0.2.44)，并将 IP 地址返回至 DNS 解析程序。
7. ISP 的 DNS 解析程序最终获得用户需要的 IP 地址。解析程序将此值返回至 Web 浏览器。DNS 解析程序还会将  example.com 的 IP 地址缓存 (存储) 您指定的时长，以便它能够在下次有人浏览 example.com 时更快地作出响应。
8. Web 浏览器将 www.example.com 的请求发送到从 DNS 解析程序中获得的 IP 地址。这是您的内容所处位置，例如，在 Amazon EC2 实例中或配置为网站端点的 Amazon S3 存储桶中运行的 Web 服务器。
9. 192.0.2.44 上的 Web 服务器或其他资源将 www.example.com 的 Web 页面返回到 Web 浏览器，且 Web 浏览器会显示该页面。

## 递归查询与迭代查询

**递归查询**：主机向本地域名服务器的查询一般都是采用递归查询。如果主机所询问的本地域名服务器不知道被查询的域名的 IP 地址，那么本地域名服务器就以 DNS  客户的身份，向其它根域名服务器继续发出查询请求报文(即替主机继续查询)，而不是让主机自己进行下一步查询。因此，递归查询返回的查询结果或者是所要查询的 IP 地址，或者是报错，表示无法查询到所需的 IP 地址。

**迭代查询**：一般DNS服务器之间属迭代查询，如：若 DNS2 不能响应 DNS1 的请求，则它会将 DNS3 的 IP 给 DNS2，以便其再向 DNS3 发出请求。

理论上讲域名查询有两种方式：

**迭代查询** A问B一个问题，B不知道答案说你可以问C，然后A再去问C，C推荐D，然后A继续问D，如此迭代…

**递归查询** A问B一个问题，B问C，C问D… 然后D告诉C，C告诉B，B告诉A

上图中的 1-2 为递归查询，3-6 为迭代查询。

![image-20211112150001943](https://s4.51cto.com/images/blog/202111/12220037_618e73854be2062928.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)

# 三、智能 DNS 解析

传统 DNS 解析，不判断访问者来源，会随机选择其中一个 IP 地址返回给访问者。而智能 DNS  解析，会判断访问者的来源，为不同的访问者智能返回不同的 IP 地址，可使访问者在访问网站时可获取用户指定的 IP  地址，能够减少解析时延，并提升网站访问速度的功效。

## edns-client-subnet(ECS)

在之前，它使用 DNS 解析器(LocalDNS)的 IP 地址对内容进行 DNS  查询。在特定解析器具有单一固定地理位置的时代，此模型运行良好。今天，许多流行的 DNS 解析器在地理上分散（Google DNS 和  OpenDNS  是两个很好的例子），并且特定解析器的位置不再是客户端位置的准确预测器。如果对内容的请求被路由到比需要更远的边缘位置，这可能会导致性能欠佳，因此  Google 提交了一份 DNS 扩展协议，允许 DNS resolver 传递用户的 IP 地址给 authoritative DNS  server。

DNS 协议的 EDNS-Client-Subnet 扩展通过返回附加信息以响应 DNS 查询来解决此问题。该信息允许内容交付网络做出更好的决策。此扩展是作为 Faster Internet 项目的一部分开发的。

## 智能解析实现原理

云解析是通过识别 LOCALDNS 的出口 IP，来判断访问者来源。

**如客户端 LOCALDNS 支持 EDNS**

因为云解析 DNS 支持 edns-client-subnet ，所以在获取访问者来源 IP 时，优先获取  edns-client-subnet 扩展里携带的 IP ，如果 edns-client-subnet 扩展里存在 IP，云解析 DNS 会以该 IP 来判断访问者的地理位置 ；如果不存在，则以 LocalDNS 出口 IP 来判断访问者的地理位置。

**如客户端 LocalDNS 不支持 EDNS**

LocalDNS 会迭代请求至云解析 DNS，云解析 DNS 根据访问者 LocalDNS 出口 IP 来判断访问者的地址位置，实现智能解析。

**如客户端 LocalDNS 变相支持 EDNS**

用户发起 DNS 请求，递归到 LocalDNS，则 LocalDNS 将本次请求发送到二级节点，通过二级节点向云解析 DNS 发起请求，此时**云解析DNS会根据 LocalDNS二 级节点的地域位置返回具体的细分线路解析结果**。

## 如何查看 LocalDNS 是否支持 ECS

使用“o-o.myaddr.l.google.com”TXT 记录集，把 Resolver-IP 替换为你查询的 LocalDNS IP。

```plainText
$ dig +nocl TXT o-o.myaddr.l.google.com +short
$ dig +nocl TXT o-o.myaddr.l.google.com @Resolver-IP +short
```

如果不支持 EDNS 客户端子网扩展，则输出将与以下类似：

```plainText
"203.201.60.5"
```

在此例中，输出表明 IP 地址为 203.201.60.5 的解析程序不支持 EDNS 客户端子网扩展。

如果支持 EDNS 客户端子网扩展，则输出将与以下类似，以阿里云的公共 DNS 为例：

```bash
$ dig +nocl TXT o-o.myaddr.l.google.com @223.5.5.5 +short
```

输出如下

```plainText
"8.208.126.231"
"edns0-client-subnet 2.16.49.0/25"
```

在此例中，输出表明 IP 地址为 8.208.126.231 的解析程序支持 EDNS 客户端子网扩展。客户端子网 2.16.49.0/25 信息将被发送到权威名称服务器，权威 DNS 通过客户端子网判断请求者的地理位置，进而应答精确的地理 IP。

如果您使用的是 DIG 9.9.3 或更高版本，则还可以使用 dig 传递客户端子网：

```plainText
$ dig +nocl TXT o-o.myaddr.l.google.com @8.8.8.8 +subnet=35.163.158.0/24 +short
"74.125.18.67"
"edns0-client-subnet 35.163.158.0/24"
```

在本示例中，第一行表示 DNS 解析程序的 IP 地址。第二行提供了 **"edns0-client-subnet"**，该值已传递给权威名称服务器。

## 附：公共 DNS

### DNSPod Public DNS

腾讯云的公共 DNS

https://dns.pub/

```reStructuredText
119.29.29.29
```

### 阿里公共 DNS

https://www.alidns.com/

```reStructuredText
223.5.5.5
223.6.6.6
```

### 360 安全 DNS

电信、移动、铁通：

```reStructuredText
首选地址：101.226.4.6
备用地址：218.30.118.6
```

联通：

```reStructuredText
首选地址：123.125.81.6
备用地址：140.207.198.6
```

### 百度公共 DNS

https://dudns.baidu.com/support/localdns/Address/index.html

```reStructuredText
180.76.76.76
```

### 114dns

不过可惜的是，114dns 还不支持 edns-client-subnet

```reStructuredText
114.114.114.114
114.114.115.115
```

### **运营商DNS**

移动、电信、联通的都有，在下面的网站都可以查到

网站地址：http://www.ip.cn/dns.html