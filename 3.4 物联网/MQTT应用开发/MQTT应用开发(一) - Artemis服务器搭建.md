- [MQTT应用开发(一) - Artemis服务器搭建_gzroy的博客-CSDN博客_artemis网关](https://blog.csdn.net/gzroy/article/details/104013738)

物联网的应用越来越广泛了，而MQTT是物联网的一个最常用的协议，在我的日常工作中也经常涉及到MQTT的应用，因此我打算在这一系列的博客中记录一下一个完整的MQTT[应用开发](https://so.csdn.net/so/search?q=应用开发&spm=1001.2101.3001.7020)的过程。我的想法是以一个车联网V2X的需求为例子进行开发，这个需求是车辆定时上报其状态信息（包括了位置，速度等），当车辆发生紧急情况（例如紧急刹车）时也将上报事件，后端的服务器接收车辆的事件，监测车辆的状态。当车辆上报紧急状况时进行相应的处理（例如把紧急刹车的事件转发给一定范围内的其他车辆）。车辆的数据上报和服务器的数据下发都是通过MQTT协议。

把这个应用的需求进行分解，可以看到有如下的工作：

1. 搭建MQTT服务器
2. 开发客户端的车辆上报信息的应用
3. 开发服务端的处理车辆数据的应用

### 搭建MQTT服务器

让我们首先完成第一个工作，MQTT服务器的搭建。在业界有很多成熟的MQTT服务器软件，例如ActiveMQ，RabbitMQ，Mosquito等等，看了网上的一些对比，我决定选用Apache的ActiveMQ Artemis来搭建我的MQTT服务器。这个软件的优势是开源，支持HA，支持高并发量。

服务器的安装很简单，在官网上下载之后解压到一个目录，然后运行bin目录下的artemis create /home/xxx/mybroker, 这样就会再/home/xxx/mybroker目录下建立一个broker实例。然后到这个目录下面的etc目录，修改以下的设置：

在bootstrap.xml里面，可以修改web bind的地址，这样可以通过这个地址来访问控制台。另外还要修改jaas-security的设置，因为我要设置通过SSL证书的方式来访问，因此需要设置为<jaas-security domain="PropertiesLogin" certificate-domain="CertLogin"/>

在login.config里面，对应jaas-security设置以下的配置，指定用户和角色配置文件的地址：

```puppet
PropertiesLogin {
    org.apache.activemq.artemis.spi.core.security.jaas.PropertiesLoginModule required
        debug=true
        org.apache.activemq.jaas.properties.user="artemis-users.properties"
        org.apache.activemq.jaas.properties.role="artemis-roles.properties";
};
 
CertLogin {
   org.apache.activemq.artemis.spi.core.security.jaas.TextFileCertificateLoginModule required
       debug=true
       org.apache.activemq.jaas.textfiledn.user="cert-users.properties"
       org.apache.activemq.jaas.textfiledn.role="cert-roles.properties";
};
```

在etc目录下新建1个文件cert-users.properties,定义用户名和证书的subject DN之间的关系，例如添加以下的用户：

vehicle1=CN=Vehicle1, OU=Vehicle, O=BMW, L=GZ, ST=GD, C=CN

新建一个文件cert-roles.properties，定义用户名和角色之间的关系，例如以下配置：

amq=vehicle1

在broker.xml文件里面，要进行相应的SSL的设置，这个等完成SSL证书的签发之后再进行设置。

### SSL证书的签发

要通过SSL来进行客户身份的验证以及通讯的加密，需要签发相应的服务器端证书以及客户端证书，具体的流程如下：

1. **openssl genrsa -out rootkey.pem 2048**
   生成根证书的密匙
2. **openssl req -x509 -new -key rootkey.pem -out root.crt -subj="/C=CN/ST=GD/L=GZ/O=RootCA/OU=RootCA/CN=RootCA"**
   生成X509格式根证书
3. **openssl genrsa -out clientkey.pem 2048**
   生成客户端的密匙
4. **openssl req -new -key clientkey.pem -out client.csr** **-subj="/C=CN/ST=GD/L=GZ/O=BMW/OU=Vehicle/CN=Vehicle1"**
   生成客户端证书的请求文件，请求根证书来签发
5. **openssl x509 -req -in client.csr -CA root.crt -CAkey rootkey.pem -CAcreateserial -days 3650 -out client.crt**
   用根证书来签发客户端请求文件，生成客户端证书client.crt
6. **openssl genrsa -out serverkey.pem 2048**
   生成服务器端的密匙
7. **openssl req -new -key serverkey.pem -out server.csr -subj="/C=CN/ST=GD/L=GZ/O=BMW/OU=IT/CN=Broker"**
   生成服务器端证书的请求文件。请求根证书来签发
8. **openssl x509 -req -in server.csr -CA root.crt -CAkey rootkey.pem -CAcreateserial -days 3650 -out server.crt**
   用根证书来签发服务器端请求文件，生成服务器端证书server.crt
9. **openssl pkcs12 -export -in client.crt -inkey clientkey.pem -out client.pkcs12**
   打包客户端资料为pkcs12格式(client.pkcs12)
10. **openssl pkcs12 -export -in server.crt -inkey serverkey.pem -out server.pkcs12**
    打包服务器端资料为pkcs12格式(server.pkcs12 )
11. **keytool -importkeystore -srckeystore client.pkcs12 -destkeystore client.jks -srcstoretype pkcs12**
    生成客户端keystore(client.jks)。使用keytool的importkeystore指令。pkcs12转jks。需要pkcs12密码和jks密码。
12. **keytool -importkeystore -srckeystore server.pkcs12 -destkeystore server.jks -srcstoretype pkcs12**
    生成服务器端keystore(server.jks)。使用keytool的importkeystore指令。pkcs12转jks。需要pkcs12密码和jks密码。
13. **keytool -importcert -keystore server.jks -file root.crt**
    这一步不一定需要的。
14. **keytool -importcert -alias ca -file root.crt -keystore clienttrust.jks**
    生成Client端的对外KeyStore，先把根证书放到里面
15. **keytool -importcert -alias clientcert -file client.crt -keystore clienttrust.jks**
    把Client证书加到对外KeyStore里面
16. **keytool -importcert -alias ca -file root.crt -keystore servertrust.jks**
    生成Server端的对外KeyStore，先把根证书放到里面
17. **keytool -importcert -alias servercert -file server.crt -keystore servertrust.jks**
    把Server证书加到对外KeyStore里面

### MQTT服务器设置

服务器和客户端的SSL证书签发完毕后，继续进行MQTT服务器的设置。在Artemis安装目录的etc目录下，编辑broker.xml文件，在<acceptor name="mqtt">的设置里面，添加以下的配置：

<acceptor name="mqtt">tcp://0.0.0.0:8883?tcpSendBufferSize=1048576;tcpReceiveBufferSize=1048576;protocols=MQTT;useEpoll=true;sslEnabled=true;keyStorePath=/home/XXXX/server.jks;keyStorePassword=XXXX;needClientAuth=true;trustStorePath=/home/XXXX/clienttrust.jks;trustStorePassword=XXXX</acceptor>

现在可以启动MQTT服务器了，在Artemis安装目录下，输入bin/artemis run &

### 客户端连接测试

现在我们可以测试一下连接服务器发送MQTT数据。这里我选用MQTT.fx来进行测试，设置启用SSL/TLS，协议选择TLS V1.2，选择self signed certificates，设置CA证书路径以及客户端证书和私钥的路径，然后即可连接。连接成功后，我们可以subscribe一个Topic，然后再往这个Topic Publish消息进行测试。