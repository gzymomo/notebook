- [Ubuntu架设OpenVPN](http://108.61.183.243/project/8/post/29)

## Ubuntu架设OpenVPN

**配置**

- 服务器：腾讯云
- 操作系统：Ubuntu 16.04

**安装OpenVPN**

- 在服务器安装OpenVPN，可以通过Ubuntu系统中的apt进行安装
  `$ sudo apt-get update`
- 同时需要安装easy-rsa，用来生成VPN使用过程所需要的CA证书
  `$ sudo apt-get install openvpn easy-rsa`

**设置CA目录**

- OpenVPN是使用TLS/SSL的VPN，这意味着它利用证书来加密服务器和客户端之间的通信。为了发布受信任的证书，我们需要建立一个自己的简单的证书颁发机构(CA)。

- 使用make-cadir命令复制easy-rsa模板到home目录：
  `$ make-cadir ~/openvpn/openvpn-ca`

- 进入刚刚新建的目录准备配置 CA：
  `$ cd ~/openvpn/openvpn-ca`
  `$ ln -s openssl-1.0.0.cnf openssl.cnf`

- 修改vars文件便于生成需要的CA值：
  `$ vim vars`
  在文件底部找到以下配置

  ```
  ...export KEY_COUNTRY="US"export KEY_PROVINCE="CA"export KEY_CITY="SanFrancisco"export KEY_ORG="Fort-Funston"export KEY_EMAIL="me@myhost.mydomain"export KEY_OU="MyOrganizationalUnit"...
  ```

  将这些变量修改为任意你喜欢的值，但是不要为空：

  ```
  export KEY_COUNTRY="CN"export KEY_PROVINCE="SH"export KEY_CITY="Shanghai"export KEY_ORG="www.ivanhuang.com"export KEY_EMAIL="ihaung721@gmail.com"export KEY_OU="MEC_zhaobian"
  ```

  我们还要修改紧接着出现的KEY_NAME的值，为了简单起见，我们改为 server  (这个不要修改成其他名字，后续的配置文件中默认是这个名字）， 默认是 EasyRSA:

  ```
  export KEY_NAME="server"
  ```

**构建CA证书**

- 进入CA目录，然后执行source vars:
  `$ cd ~/openvpn/openvpn-ca`
  `$ source vars`
  接着会有以下输出：
  NOTE: If you run ./clean-all, I will be doing a rm -rf on /home/ubuntu/openvpn/openvpn-ca/keys
- 执行下列操作确保环境干净：
  `$ ./clean-all`
- 构建CA：
  `$ ./build-ca`
  这将会启动创建根证书颁发密钥、证书的过程。由于我们刚才修改了 vars 文件，所有值应该都会自动填充，一路回车就好。

**创建服务器端证书、秘钥和加密文件**

- 通过下列命令生成服务器端证书和秘钥：
  `$ ./build-key-server server`
  ***注意：server 就是刚才在 vars 文件中修改的 KEY_NAME 变量的值。请不要使用别的名字！ 然后一直回车选择默认值即可。到最后，需要输入两次 y 注册证书和提交。\***
- 我们可以在密钥交换过程中生成一个强大的 Diffie-Hellman 密钥(这个操作大约会花费几分钟不等):
  `$ ./build-dh`
- 生成 HMAC 签名加强服务器的 TLS 完整性验证功能：
  `$ openvpn --genkey --secret keys/ta.key`

**配置OpenVPN服务**

- 将刚刚生成的各类文件复制到OpenVPN目录下：
  `$ cd ~/openvpn/openvpn-ca/keys`
  `$ sudo cp ca.crt ca.key server.crt server.key ta.key dh2048.pem /etc/openvpn`

- 解压并复制一个OpenVPN配置文件到OpenVPN目录：
  `$ gunzip -c /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz | sudo tee /etc/openvpn/server.conf`
  `$ sudo mkdir -p /etc/openvpn/ccd`

- 更改配置，注释掉udp更改协议为tcp:

  ```
  proto tcp;proto udp
  ```

  找到tls-auth位置，去掉注释，并在下面新增一行：

  ```
  tls-auth ta.key 0 # This file is secretkey-direction 0
  ```

  去掉user和group行前的注释：

  ```
  user nobodygroup nogroup
  ```

  去掉client-to-client行前的注释允许客户端之间互相访问：

  ```
  client-to-client
  ```

  开启客户端固定IP配置文件夹：

  ```
  client-config-dir ccd
  ```

  增加加密解密协议：

  ```
  cipher AES-256-CBC
  ```

**调整服务器网络配置**

- 确认UFW防火墙状态，如果状态为开启，则调整。如果防火墙是关闭的，则不需要调整。
  `$ sudo ufw status`
  如果输出是Status: inactive，那么不需要进行调整。这里未遇到，故没有记录。

**启动OpenVPN服务**

- 执行如下：
  `$ sudo mkdir -p /etc/openvpn/ccd`
  `$ sudo systemctl start openvpn@server`
- 如果启动失败，则执行如下命令观察日志:
  `$ sudo tail -f /var/log/syslog`
- 设置开机自启：
  `$ sudo systemctl enable openvpn@server`

**创建客户端配置**

- 生成客户端证书、秘钥对：
  `$ cd ~/openvpn/openvpn-ca`
  `$ source vars`
  `$ ./clean-all`
  `$ cp /etc/openvpn/ca.crt ./keys/`
  `$ sudo cp /etc/openvpn/ca.key ./keys/`
  `$ sudo cp /etc/openvpn/ta.key ./keys/`
  `$ sudo chmod 755 ./keys/ca.crt`
  `$ sudo chmod 755 ./keys/ta.key`
  `$ sudo chmod 755 ./keys/ca.key`
  `$ ./build-key client-mobibrw`
  client-mobibrw 为密钥对名称，生成过程中回车选择默认选项即可。
  ***注意：如果有多个客户端的话，建议为每个客户端生成一份配置文件。\***

- 生成客户端配置的基础文件：
  `$ mkdir -p ~/client-configs/files`
  `$ chmod 700 ~/client-configs/files`
  `$ cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf ~/client-configs/base.conf`

- 打开base.conf文件，修改 remote my-server-1 1194 为服务器公网IP或者域名

  ```
  remote 121.4.136.4 9997
  ```

  更改客户端协议为 tcp:

  ```
  proto tcp;proto udp
  ```

  去掉 user 和 group 前的注释：

  ```
  user nobodygroup nogroup
  ```

  找到 ca/cert/key，修改对应的客户端文件：

  ```
  ca ca.crtcert client-mobibrw.crtkey client-mobibrw.key
  ```

  在文件中新增以下内容对应服务端：

  ```
  tls-auth ta.key 1key-direction 1cipher AES-256-CBC
  ```

- 整合打包需要的配置文件：
  `$ cd ~/client-configs`
  `$ mkdir client-config`
  `$ cp ../openvpn/openvpn-ca/key/ta.key client-config`
  `$ cp ../openvpn/openvpn-ca/key/ca.crt client-config`
  `$ cp ../openvpn/openvpn-ca/key/client-mobibrw.key client-config`
  `$ cp ../openvpn/openvpn-ca/key/client-mobibrw.crt client-config`
  `$ mv ../file/base.config client-config/client-mobibrw.ovpn`

**在windows上使用**

- 下载与服务器上版本匹配的OpenVPN
  服务器上OpenVPN版本查看：`$ openvpn --version`，我这里版本是**2.3.10**
- windows下载好OpenVPN后，把client-config文件夹从服务器打包出来
  放入windows中OpenVPN安装目录下的config下
  然后打开OpenVPN点击连接即可，连接成功图标会跳成绿色。

**在ubuntu上使用**

- 安装与服务器上对应版本的VPN
  `$ sudo apt-get update`
  `$ sudo apt-get install openvpn`
- 把client-config文件夹从服务器打包出来放入ubuntu系统中
  进入该文件目录下，主要有如下几个文件：
  `ca.crt` `client-mobibrw.crt` `client-mobibrw.key` `client-mobibrw.ovpn` `ta.key`
- 运行启动客户端：
  `$ sudo openvpn --config client-mobibrw.ovpn`

## 内网穿透

**服务端修改**

- 架设route

1. 修改/etc/openvpn/server.conf文件
   假设需要穿透的内网是192.168.2.0/24，增加如下：

   ```
   push "route 192.168.2.0 255.255.255.0"client-config-dir ccdroute 192.168.2.0 255.255.255.0
   ```

2. 创建ccd文件夹以及客户端对应的路由文件
   创建文件夹：

   ```
   $ sudo mkdir ccd
   ```

   查看对应的客户端名字：

   ```
   $ sudo cat ipp.txt
   ```

   创建对应客户端的名字，这里假设是client：

   ```
   $ sudo vi client
   ```

   在文件中加入：

   ```
   iroute 192.168.2.0 255.255.255.0
   ```

3. 重启openvpn使修改生效：

   ```
   $ sudo systemctl restart openvpn@server
   ```

**客户端修改**

- NAT映射
  查看NAT:

  ```
  $ sudo iptables -nL -t nat --line-numbers
  ```

  添加一条NAT映射:

  ```
  $ sudo iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o enp1s0 -j MASQUERADE
  ```

- 保存iptables规则
  iptables中的配置信息会随着计算机的重启而被清空
  故需要把这些配置保存下来，让iptables在启动时自动加载，省得每次都得重新输入
  iptables-save和iptables-restore 是用来保存和恢复设置的

1. 先将配置信息保存到/etc/iptables.up.rules文件中

   ```
   $ sudo iptables-save > /etc/iptables.up.rules
   ```

2. 在该文件/etc/network/interfaces中加入恢复设置

   ```
   pre-up iptables-restore < /etc/iptables.up.rules
   ```

   3.查看配置是否已经生效

   ```
   $ sudo iptables -L
   ```

- 查看并启用IP转发
  Linux发行版默认情况下是不开启IP转发功能
  由于当前需要架设一个路由或者VPN服务，故需要开启该服务功能

1. 检查当前设备是否开启：

   ```
   // 0表示未开启，1表示已开启// 方法一：$ sysctl net.ipv4.ip_forward// 方法二：$ cat /proc/sys/net/ipv4/ip_forward
   ```

2. 启动IP转发

   ```
   // 以下两种设置方法只是暂时的，会随着计算机的重启而失效// 方法一：$ sysctl -w net.ipv4.ip_forward=1// 方法二：$ echo 1 > /proc/sys/net/ipv4/ip_forward
   ```

   要使IP转发永久生效，修改/etc/sysctl.conf文件，在里面加一条：

   ```
   net.ipv4.ip_forward = 1
   ```

   使更改生效:

   ```
   $ sysctl -p /etc/sysctl.conf
   ```