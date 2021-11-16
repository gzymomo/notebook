- [Java开发中的加密、解密、签名、验签，密钥，证书](https://juejin.cn/post/6882404615443185678)

## OpenSSL和keytool

先说一下两个重要的工具

- OpenSSL：OpenSSL整个软件包大概可以分成三个主要的功能部分：SSL协议库libssl、应用程序命令工具以及密码算法库libcrypto。它使用标准的文件格式（PEM/CER/CRT/PKCS等）存储密钥和证书信息。
- keytool：是密钥和证书管理工具。它出自于Java体系，它使用KeyStore来管理密钥和证书。

两者都是可以用来生成加密密钥的工具，keytool出自Java体系，它可以直接操作KeyStore，而OpenSSL不支持直接操作KeyStore。实际情况有可能是这样的，使用OpenSSL生成了密钥或证书，然后使用keytool将其导入到KeyStore以便在Java环境中使用。

当然OpenSSL还具备其他功能比如作为SSL的客户端和服务器，这是keytool所不具备的。

## 对称加密

> 采用单钥密码系统的加密方法，同一个密钥可以同时用作信息的加密和解密，这种加密方法称为对称加密，也称为单密钥加密。——百度百科

#### 对称加密算法的特点

- 加密和解密使用同样的密钥
- 计算速度快，适用于对大量数据加密处理
- 安全性取决于算法，也取决于密钥的管理，一旦密钥泄漏，数据则暴露无遗

#### 对称加密算法的使用场景

基于上述的特点，在一些需要高效实时传输的加密通讯场景中，比如使用VPN或者代理进行通讯时，可以使用对称加密。另外在同一个系统内部不同模块，比如前后端，从前端输入的敏感信息，可以使用对称加密算法进行加密后将密文传到后端，避免传输过程中明文被截获，因为同系统内部之间密钥管理相对容易，而对于共享密钥有泄漏风险的其他任何场景，则不适合使用对称加密算法进行加密。

#### 常见的对称加密算法

| 算法                                | 描述                                                         |
| ----------------------------------- | ------------------------------------------------------------ |
| DES（Data Encryption Standard）     | 数据加密标准，速度较快，适用于加密大量数据                   |
| 3DES（Triple DES）                  | 基于DES，对一块数据用三个不同的密钥进行三次加密，强度更高    |
| AES（Advanced Encryption Standard） | 高级加密标准，速度快，安全级别高，支持128、192、256、512位密钥的加密 |
| Blowfish                            | 速度快且安全，而且没有专利和商业限制。[了解更多>>](https://link.juejin.cn?target=https%3A%2F%2Fbaike.baidu.com%2Fitem%2FBlowfish%2F1677776) |

#### OpenSSL实现对称加密

```shell
OpenSSL> enc --help
usage: enc -ciphername [-AadePp] [-base64] [-bufsize number] [-debug]
    [-in file] [-iv IV] [-K key] [-k password]
    [-kfile file] [-md digest] [-none] [-nopad] [-nosalt]
    [-out file] [-pass arg] [-S salt] [-salt]

 -A                 Process base64 data on one line (requires -a)
 -a                 Perform base64 encoding/decoding (alias -base64)
 -bufsize size      Specify the buffer size to use for I/O
 -d                 Decrypt the input data
 -debug             Print debugging information
 -e                 Encrypt the input data (default)
 -in file           Input file to read from (default stdin)
 -iv IV             IV to use, specified as a hexadecimal string
 -K key             Key to use, specified as a hexadecimal string
 -md digest         Digest to use to create a key from the passphrase
 -none              Use NULL cipher (no encryption or decryption)
 -nopad             Disable standard block padding
 -out file          Output file to write to (default stdout)
 -P                 Print out the salt, key and IV used, then exit
                      (no encryption or decryption is performed)
 -p                 Print out the salt, key and IV used
 -pass source       Password source
 -S salt            Salt to use, specified as a hexadecimal string
 -salt              Use a salt in the key derivation routines (default)
 -v                 Verbose
复制代码
```

| 命令选项     | 描述                                                         |
| ------------ | ------------------------------------------------------------ |
| -in file     | 被加密文件的全路径                                           |
| -out file    | 加密后内容输出的文件路径                                     |
| -salt        | 自动插入一个随机数作为文件内容加密，默认选项                 |
| -e           | 加密模式，默认                                               |
| -d           | 解密模式，需要与加密算法一致                                 |
| -a           | 使用-base64位编码格式，也可使用-base64                       |
| -pass source | 指定密码的输入方式，共有五种方式：命令行输入(stdin)、文件输入(file)、环境变量输入(var)、文件描述符输入(fd)、标准输入(stdin)。默认是标准输入即从键盘输入 |

##### 只对文件进行base64编码，而不使用加解密

```shell
/*对文件进行base64编码*/
openssl enc -base64 -in plain.txt -out base64.txt
/*对base64格式文件进行解密操作*/
openssl enc -base64 -d -in base64.txt -out plain2.txt
/*使用diff命令查看可知解码前后明文一样*/
diff plain.txt plain2.txt
复制代码
```

##### 不同方式的密码输入方式

```shell
/*命令行输入，密码123456*/
openssl enc -aes-128-cbc -in plain.txt -out out.txt -pass pass:123456
/*文件输入，密码123456*/
echo 123456 > passwd.txt
openssl enc -aes-128-cbc -in plain.txt -out out.txt -pass file:passwd.txt
/*环境变量输入，密码123456*/
passwd=123456
export passwd
openssl enc -aes-128-cbc -in plain.txt -out out.txt -pass env:passwd
/*从文件描述输入*/ 
openssl enc -aes-128-cbc -in plain.txt -out out.txt -pass fd:1  
/*从标准输入输入*/ 
openssl enc -aes-128-cbc -in plain.txt -out out.txt -pass stdin 
复制代码
```

#### Java实现对称加密

##### DES

```java
/**
 * 生成 DES 算法密钥
 * @return byte[]
 * @throws Exception
 */
public static byte[] generateDESKey() throws Exception {
    KeyGenerator keyGenerator = KeyGenerator.getInstance("DES");
    // must be equal to 56
    keyGenerator.init(56);
    SecretKey secretKey = keyGenerator.generateKey();
    byte[] encodedKey = secretKey.getEncoded();
    return encodedKey;
}

/**
 * DES加密
 * @param encodedKey generateDESKey生成的密钥
 * @param dataBytes byte[]形式的待加密数据
 * @return byte[]
 * @throws Exception
 */
public static byte[] encryptByDES(byte[] encodedKey, byte[] dataBytes) throws Exception {
    SecretKey secretKey = new SecretKeySpec(encodedKey, "DES");
    Cipher cipher = Cipher.getInstance("DES");
    cipher.init(Cipher.ENCRYPT_MODE, secretKey);
    byte[] encryptedData = cipher.doFinal(dataBytes);
    return encryptedData;
}

/**
 * DES解密
 * @param encodedKey generateDESKey生成的密钥
 * @param encryptedData byte[]形式的待解密数据
 * @return byte[]
 * @throws Exception
 */
public static byte[] decryptByDES(byte[] encodedKey, byte[] encryptedData) throws Exception {
    SecretKey secretKey = new SecretKeySpec(encodedKey, "DES");
    Cipher cipher = Cipher.getInstance("DES");
    cipher.init(Cipher.DECRYPT_MODE, secretKey);
    byte[] decryptedData = cipher.doFinal(encryptedData);
    return decryptedData;
}
复制代码
```

##### 基础版本使用方法如下：

```java
@Test
public void testDES_1() throws Exception {
    byte[] encodedKey = SecurityUtil.generateDESKey();
    String data = "this is a good boy";
    byte[] encryptedData = SecurityUtil.encryptByDES(encodedKey, data.getBytes());
    byte[] decryptedData = SecurityUtil.decryptByDES(encodedKey, encryptedData);
    Assert.assertEquals(data, new String(decryptedData));
}
复制代码
```

可以看到，以上的方法使用起来并不友好，参数、返回等大量存在byte[]，不便于理解，中间结果不便于查看和传输，比如如果需要将encryptedData返回给下游系统，那么还得使用Base64进行处理，基于此，我对在上述接口基础上进一步进行封装，使其使用起来更贴近日常使用场景。

##### 优化版本：

```java
/**
 * 生成 DES 算法密钥
 * @return 经过Base64编码的字符串密钥
 * @throws Exception
 */
public static String generateDESKeyStr() throws Exception {
    return Base64.encodeBase64String(generateDESKey());
}

/**
 * DES加密
 * @param key 经过Base64编码的字符串密钥
 * @param data String形式的待加密数据
 * @return 经过Base64编码的加密数据
 * @throws Exception
 */
public static String encryptByDES(String key, String data) throws Exception {
    byte[] encodedKey = Base64.decodeBase64(key);
    byte[] dataBytes = data.getBytes();
    byte[] encryptedData = encryptByDES(encodedKey, dataBytes);
    return Base64.encodeBase64String(encryptedData);
}

/**
 * DES解密
 * @param key 经过Base64编码的字符串密钥
 * @param data String形式的待解密数据
 * @return 原始数据
 * @throws Exception
 */
public static String decryptByDES(String key, String data) throws Exception {
    byte[] encodedKey = Base64.decodeBase64(key);
    byte[] dataBytes = Base64.decodeBase64(data);
    byte[] decryptedData = decryptByDES(encodedKey, dataBytes);
    return new String(decryptedData);
}
复制代码
```

##### 优化版本使用方法如下：

```java
@Test
public void testDES_2() throws Exception {
    String key = SecurityUtil.generateDESKeyStr();
    String data = "this is a good boy";
    String encryptedData = SecurityUtil.encryptByDES(key, data);
    String decryptedData = SecurityUtil.decryptByDES(key, encryptedData);
    Assert.assertEquals(data, decryptedData);
}
复制代码
```

这里补充一下，在实际项目开发过程中，还真遇见不少同学对Base64理解有误的情况，对于以上处理和转换过程理解有难度的同学，[可以戳一下这里](https://link.juejin.cn?target=https%3A%2F%2Fwww.jianshu.com%2Fp%2Fc5147a3eaf07)

##### 3DES

```java
/**
 * 生成 3DES 算法密钥
 * @return byte[]
 * @throws Exception
 */
public static byte[] generate3DESKey() throws Exception {
    KeyGenerator keyGenerator = KeyGenerator.getInstance("DESede");
    // must be equal to 112 or 168
    keyGenerator.init(168);
    SecretKey secretKey = keyGenerator.generateKey();
    byte[] encodedKey = secretKey.getEncoded();
    return encodedKey;
}

/**
 * 3DES加密
 * @param encodedKey generate3DESKey生成的密钥
 * @param dataBytes byte[]形式的待加密数据
 * @return byte[]
 * @throws Exception
 */
public static byte[] encryptBy3DES(byte[] encodedKey, byte[] dataBytes) throws Exception {
    SecretKey secretKey = new SecretKeySpec(encodedKey, "DESede");
    Cipher cipher = Cipher.getInstance("DESede");
    cipher.init(Cipher.ENCRYPT_MODE, secretKey);
    byte[] encryptedData = cipher.doFinal(dataBytes);
    return encryptedData;
}

/**
 * 3DES解密
 * @param encodedKey generate3DESKey生成的密钥
 * @param encryptedData byte[]形式的待解密数据
 * @return byte[]
 * @throws Exception
 */
public static byte[] decryptBy3DES(byte[] encodedKey, byte[] encryptedData) throws Exception {
    SecretKey secretKey = new SecretKeySpec(encodedKey, "DESede");
    Cipher cipher = Cipher.getInstance("DESede");
    cipher.init(Cipher.DECRYPT_MODE, secretKey);
    byte[] decryptedData = cipher.doFinal(encryptedData);
    return decryptedData;
}
复制代码
```

##### 使用方法如下：

```java
@Test
public void test3DES() throws Exception {
    byte[] encodedKey = SecurityUtil.generate3DESKey();
    String data = "this is a good boy";
    byte[] encryptedData = SecurityUtil.encryptBy3DES(encodedKey, data.getBytes());
    byte[] decryptedData = SecurityUtil.decryptBy3DES(encodedKey, encryptedData);
    Assert.assertEquals(data, new String(decryptedData));
}
复制代码
```

##### AES

```java
/**
 * 生成 AES 算法密钥
 * @return byte[]
 * @throws Exception
 */
public static byte[] generateAESKey() throws Exception {
    KeyGenerator keyGenerator = KeyGenerator.getInstance("AES");
    // must be equal to 128, 192 or 256
    // 但是当你使用 192/256 时，会收到：
    // java.security.InvalidKeyException: Illegal key size or default parameters
    keyGenerator.init(128);
    SecretKey secretKey = keyGenerator.generateKey();
    byte[] encodedKey = secretKey.getEncoded();
    return encodedKey;
}

/**
 * AES加密
 * @param encodedKey generateAESKey生成的密钥
 * @param dataBytes byte[]形式的待加密数据
 * @return byte[]
 * @throws Exception
 */
public static byte[] encryptByAES(byte[] encodedKey, byte[] dataBytes) throws Exception {
    SecretKey secretKey = new SecretKeySpec(encodedKey, "AES");
    Cipher cipher = Cipher.getInstance("AES");
    cipher.init(Cipher.ENCRYPT_MODE, secretKey);
    byte[] encryptedData = cipher.doFinal(dataBytes);
    return encryptedData;
}

/**
 * AES密
 * @param encodedKey generateAESSKey生成的密钥
 * @param encryptedData byte[]形式的待解密数据
 * @return byte[]
 * @throws Exception
 */
public static byte[] decryptByAES(byte[] encodedKey, byte[] encryptedData) throws Exception {
    SecretKey secretKey = new SecretKeySpec(encodedKey, "AES");
    Cipher cipher = Cipher.getInstance("AES");
    cipher.init(Cipher.DECRYPT_MODE, secretKey);
    byte[] decryptedData = cipher.doFinal(encryptedData);
    return decryptedData;
}
复制代码
```

##### 使用方法如下：

```java
@Test
public void testAES() throws Exception {
    byte[] encodedKey = SecurityUtil.generateAESKey();
    String data = "this is a good boy";
    byte[] encryptedData = SecurityUtil.encryptByAES(encodedKey, data.getBytes());
    byte[] decryptedData = SecurityUtil.decryptByAES(encodedKey, encryptedData);
    Assert.assertEquals(data, new String(decryptedData));
}
复制代码
```

虽然AES支持128、192或 256的密钥长度，但是当我们使用192或256位长度的密钥时，会收到这个异常：java.security.InvalidKeyException: Illegal key size or default parameters

```java
java.security.InvalidKeyException: Illegal key size or default parameters

	at javax.crypto.Cipher.checkCryptoPerm(Cipher.java:1026)
	at javax.crypto.Cipher.implInit(Cipher.java:801)
	at javax.crypto.Cipher.chooseProvider(Cipher.java:864)
	at javax.crypto.Cipher.init(Cipher.java:1249)
	at javax.crypto.Cipher.init(Cipher.java:1186)
	at com.example.architecture.util.SecurityUtil.encryptByAES(SecurityUtil.java:161)
	at com.example.architecture.util.SecurityUtilTest.testAES(SecurityUtilTest.java:97)
	at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
	at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
	at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
	at java.lang.reflect.Method.invoke(Method.java:498)
	at org.junit.runners.model.FrameworkMethod$1.runReflectiveCall(FrameworkMethod.java:50)
	at org.junit.internal.runners.model.ReflectiveCallable.run(ReflectiveCallable.java:12)
	at org.junit.runners.model.FrameworkMethod.invokeExplosively(FrameworkMethod.java:47)
	at org.junit.internal.runners.statements.InvokeMethod.evaluate(InvokeMethod.java:17)
复制代码
```

原因是JRE中自带的**local_policy.jar** 和**US_export_policy.jar**是支持128位密钥的加密算法，而当我们要使用192或256位密钥算法的时候，已经超出它支持的范围。

**解决方案：去官方下载JCE无限制权限策略文件。**

[JDK5](https://link.juejin.cn?target=http%3A%2F%2Fwww.oracle.com%2Ftechnetwork%2Fjava%2Fjavasebusiness%2Fdownloads%2Fjava-archive-downloads-java-plat-419418.html%23jce_policy-1.5.0-oth-JPR) ｜ [JDK6](https://link.juejin.cn?target=http%3A%2F%2Fwww.oracle.com%2Ftechnetwork%2Fjava%2Fjavase%2Fdownloads%2Fjce-6-download-429243.html) ｜ [JDK7](https://link.juejin.cn?target=http%3A%2F%2Fwww.oracle.com%2Ftechnetwork%2Fjava%2Fjavase%2Fdownloads%2Fjce-7-download-432124.html)｜ [JDK8](https://link.juejin.cn?target=http%3A%2F%2Fwww.oracle.com%2Ftechnetwork%2Fjava%2Fjavase%2Fdownloads%2Fjce8-download-2133166.html)

下载后解压，可以看到local_policy.jar和US_export_policy.jar以及readme.txt

- 如果安装了JRE，将两个jar文件放到%JRE_HOME%\lib\security目录下覆盖原来的文件。
- 如果安装了JDK，还要将两个jar文件也放到%JDK_HOME%\jre\lib\security目录下覆盖原来文件。

AES128和AES256主要区别是密钥长度不同（分别是128bits，256bits)、加密处理轮数不同（分别是10轮，14轮），后者强度高于前者，当前AES是公认的较为安全的对称加密算法。

------

## 非对称加密

> 非对称加密算法需要两个密钥：公开密钥（publickey:简称公钥）和私有密钥（privatekey:简称私钥）。公钥与私钥是一对，如果用公钥对数据进行加密，只有用对应的私钥才能解密。因为加密和解密使用的是两个不同的密钥，所以这种算法叫作非对称加密算法。  ——百度百科

#### 非对称加密算法的特点

- 也称公开密钥加密，算法需要两个密钥，其中一个可以公开，并且通过公开的密钥无法推导出对应的私钥
- 算法复杂度相对对称加密算法高，所以计算相对较慢
- 密钥的保密性较好，因为公钥可以公开，免去了交换密钥的需求

#### 非对称加密算法的使用场景

由于安全性较好，并且密钥可以公开，无交换过程泄密的风险，因此非对此密钥算法被广泛使用，比如SSH、HTTPS、电子证书、数字签名、加密通讯等领域。

##### 数据加密传输

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/7d86c0ccddd64bad877f93484272de33~tplv-k3u1fbpfcp-watermark.image)

##### 报文签名验签

![img](https://p6-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/d947de6c9c784a0ba6c816c05317e419~tplv-k3u1fbpfcp-watermark.image)

#### 常见的非对称加密算法

1977年，三位数学家Rivest、Shamir 和 Adleman 设计了一种算法，可以实现非对称加密。这种算法用他们三个人的名字命名，叫做RSA算法，RSA算法从被发明至今一直是最广为使用的"非对称加密算法"。其他场景的算法还有Elgamal、背包算法、Rabin、D-H、ECC（椭圆曲线加密算法）。

对于RSA算法的原理，有兴趣进一步了解的同学推荐看一下：

[RSA算法原理（一）](https://link.juejin.cn?target=http%3A%2F%2Fwww.ruanyifeng.com%2Fblog%2F2013%2F06%2Frsa_algorithm_part_one.html)

[RSA算法原理（二）](https://link.juejin.cn?target=http%3A%2F%2Fwww.ruanyifeng.com%2Fblog%2F2013%2F07%2Frsa_algorithm_part_two.html)

#### OpenSSL实现RSA

在开始介绍具体使用之前，补充两个知识点：

1. 如果你对非对称密钥的编码规则和数据格式定义不清楚，可以先看一下[这篇文章](https://link.juejin.cn?target=https%3A%2F%2Fwww.jianshu.com%2Fp%2F78886e480bef)，这里摘抄重点：

> openssl有多种形式的密钥，openssl提供PEM和DER两种编码方式对这些密钥进行编码，并提供相关指令可以使用户在这两种格式之间进行转换。
>
> ##### DER
>
> DER就是密钥的二进制表述格式
>
> ##### PEM
>
> PEM格式就是对DER编码转码为base64字符格式。通过base64解码可以还原DER格式。
>
> PEM 是明文格式，可以包含证书或者是密钥；其内容通常是以类似 “—–BEGIN …—–” 开头 “—–END …—–” 为结尾的这样的格式进行描述的。 因为DER是纯二进制格式，对人不友好，所以一般都用PEM进行存储。

1. [RSA非对称加解密算法填充方式(Padding)](https://link.juejin.cn?target=https%3A%2F%2Fblog.csdn.net%2Fmakenothing%2Farticle%2Fdetails%2F88429511)，同样摘抄重点：

> RSA加密常用的填充模式有三种：RSA_PKCS1_PADDING， RSA_PKCS1_OAEP_PADDING， RSA_NO_PADDING。
>
> 与对称加密算法DES，AES一样，RSA算法也是一个块加密算法（ block cipher algorithm），总是在一个固定长度的块上进行操作。但跟AES等不同的是，block length是跟key length有关的。
>
> 每次RSA加密的明文的长度是受RSA填充模式限制的，但是RSA每次加密的块长度就是key length。

#### 常用指令

| 指令   | 功能描述               |
| ------ | ---------------------- |
| genrsa | 生成一个RSA私钥        |
| rsa    | RSA密钥的格式转换      |
| rsautl | 加密、解密、签名和验证 |

##### genrsa命令

```shell
OpenSSL> genrsa --help
usage: genrsa [args] [numbits]
 -des            encrypt the generated key with DES in cbc mode
 -des3           encrypt the generated key with DES in ede cbc mode (168 bit key)
 -aes128, -aes192, -aes256
                 encrypt PEM output with cbc aes
 -camellia128, -camellia192, -camellia256
                 encrypt PEM output with cbc camellia
 -out file       output the key to 'file
 -passout arg    output file pass phrase source
 -f4             use F4 (0x10001) for the E value
 -3              use 3 for the E value
复制代码
```

| 命令选项                                 | 描述                                                   |
| ---------------------------------------- | ------------------------------------------------------ |
| -des                                     | 生成的密钥使用des加密                                  |
| -des3                                    | 生成的密钥使用des3加密                                 |
| -aes128, -aes192, -aes256                | 生成的密钥使用aes方式进行加密                          |
| -camellia128, -camellia192, -camellia256 | 生成的密钥使用camellia方式进行加密                     |
| -out file                                | 生成的密钥写入的文件                                   |
| -passout arg                             | 指定密钥文件的加密口令，可从文件、环境变量、终端等输入 |

##### 示例：

```shell
//生成2048位的RSA私钥
openssl genrsa -out pkcs1_private.pem 2048
复制代码
```

##### rsa命令

```shell
usage: rsa [-ciphername] [-check] [-in file] [-inform fmt]
    [-modulus] [-noout] [-out file] [-outform fmt] [-passin src]
    [-passout src] [-pubin] [-pubout] [-sgckey] [-text]

 -check             Check consistency of RSA private key
 -in file           Input file (default stdin)
 -inform format     Input format (DER, NET or PEM (default))
 -modulus           Print the RSA key modulus
 -noout             Do not print encoded version of the key
 -out file          Output file (default stdout)
 -outform format    Output format (DER, NET or PEM (default PEM))
 -passin src        Input file passphrase source
 -passout src       Output file passphrase source
 -pubin             Expect a public key (default private key)
 -pubout            Output a public key (default private key)
 -sgckey            Use modified NET algorithm for IIS and SGC keys
 -text              Print in plain text in addition to encoded
复制代码
```

| 命令选项        | 描述                                             |
| --------------- | ------------------------------------------------ |
| -in file        | 输入文件                                         |
| -inform format  | 输入文件格式(DER, NET or PEM (默认))             |
| -modulus        | 输出模数指                                       |
| -noout          | 不输出密钥到任何地方                             |
| -out file       | 输出密钥的文件                                   |
| -outform format | 输出文件格式(DER, NET or PEM (默认))             |
| -passin src     | 输入文件的加密口令，可来自文件、终端、环境变量等 |
| -passout src    | 输出文件的加密口令，可来自文件、终端、环境变量等 |
| -pubin          | 指定输入文件是公钥                               |
| -pubout         | 指定输出文件是公钥                               |

##### 示例：

```shell
// 通过私钥pem文件生成对应的公钥
openssl rsa -in pkcs1_private.pem -pubout -out pkcs1_public.pem
复制代码
```

**在Java环境中，需要注意两个问题，需要借助上述命令来解决，我们以两个小例子说明。**

首先在 /tmp 目录下简单生成一个私钥：

```shell
// 生成pem格式的密钥
openssl genrsa -out RSA.pem
复制代码
```

尝试读取RSA.pem并生成PrivateKey对象

```java
@Test
public void testGeneratePrivateKeyWithPEM() throws Exception {
    byte[] bytes = Files.readAllBytes(Paths.get("/tmp/RSA.pem" ));
    PKCS8EncodedKeySpec keySpec = new PKCS8EncodedKeySpec(bytes);
    KeyFactory keyFactory = KeyFactory.getInstance("RSA");
    PrivateKey privateKey = keyFactory.generatePrivate(keySpec);
    System.out.println(privateKey.getFormat());
}
复制代码
```

运行之后发现会报这个异常：java.security.spec.InvalidKeySpecException: java.security.InvalidKeyException: invalid key format

```java
java.security.spec.InvalidKeySpecException: java.security.InvalidKeyException: invalid key format

	at sun.security.rsa.RSAKeyFactory.engineGeneratePrivate(RSAKeyFactory.java:217)
	at java.security.KeyFactory.generatePrivate(KeyFactory.java:372)
	at com.example.architecture.util.RSAUtilTest.testGeneratePrivateKeyWithPEM(RSAUtilTest.java:32)
    ...
复制代码
```

**问题原因：Java自带的security包不支持直接读取PEM格式文件。**

**解决方法：需要将PEM格式转为DER格式再进行读取。**

```shell
// 把pem格式转化成der格式，使用outform指定der格式
openssl rsa -in RSA.pem -outform der -out RSA.der
复制代码
```

好了，继续读取RSA.der并尝试生成PrivateKey对象

```java
@Test
public void testGeneratePrivateKeyWithDER() throws Exception {
    byte[] bytes = Files.readAllBytes(Paths.get("/tmp/RSA.der" ));
    PKCS8EncodedKeySpec keySpec = new PKCS8EncodedKeySpec(bytes);
    KeyFactory keyFactory = KeyFactory.getInstance("RSA");
    PrivateKey privateKey = keyFactory.generatePrivate(keySpec);
    System.out.println(privateKey.getFormat());
}
复制代码
```

运行之后发现会报另一个异常：java.security.spec.InvalidKeySpecException: java.security.InvalidKeyException: IOException : algid parse error, not a sequence

```java
java.security.spec.InvalidKeySpecException: java.security.InvalidKeyException: IOException : algid parse error, not a sequence

	at sun.security.rsa.RSAKeyFactory.engineGeneratePrivate(RSAKeyFactory.java:217)
	at java.security.KeyFactory.generatePrivate(KeyFactory.java:372)
	at com.example.architecture.util.RSAUtilTest.testGeneratePrivateKeyWithDER(RSAUtilTest.java:24)
	...
复制代码
```

**问题原因：OpenSSL生成的私钥是PKCS#1格式的，而Java自带的security包使用PKCS8EncodedKeySpec来实现私钥，私钥信息是以PKCS#8标准定义的，我们从下面这个类的构造方法说明可以很明显看到。**

```java
/**
 * Creates a new PKCS8EncodedKeySpec with the given encoded key.
 *
 * @param encodedKey the key, which is assumed to be
 * encoded according to the PKCS #8 standard. The contents of
 * the array are copied to protect against subsequent modification.
 * @exception NullPointerException if {@code encodedKey}
 * is null.
 */
public PKCS8EncodedKeySpec(byte[] encodedKey) {
    super(encodedKey);
}
复制代码
```

**解决方法：OpenSSL生成密钥之后在Java环境中使用要先转为PKCS#8格式。**

关于PKCS#1与PKCS#8，简单理解两者都是非对称加密私钥信息的标准定义，区别是PKCS#1是针对RSA算法的，而PKCS#8是通用的，两者在格式定义上有些许区别。

```shell
//提取PCKS8格式的私钥
openssl pkcs8 -topk8 -inform DER -in RSA.der -outform DER -nocrypt -out RSA_pkcs8.der
复制代码
```

继续读取RSA_pkcs8.der并尝试生成PrivateKey对象

```java
@Test
public void testGeneratePrivateKeyWithPKCS8DER() throws Exception {
    byte[] bytes = Files.readAllBytes(Paths.get("/tmp/RSA_pkcs8.der" ));
    PKCS8EncodedKeySpec keySpec = new PKCS8EncodedKeySpec(bytes);
    KeyFactory keyFactory = KeyFactory.getInstance("RSA");
    PrivateKey privateKey = keyFactory.generatePrivate(keySpec);
    System.out.println(privateKey.getFormat());
}

输出：
PKCS#8
复制代码
```

搞定！

##### rsautl命令

```shell
OpenSSL> rsautl --help
Usage: rsautl [options]
-in file        input file
-out file       output file
-inkey file     input key
-keyform arg    private key format - default PEM
-pubin          input is an RSA public
-certin         input is a certificate carrying an RSA public key
-ssl            use SSL v2 padding
-raw            use no padding
-pkcs           use PKCS#1 v1.5 padding (default)
-oaep           use PKCS#1 OAEP
-sign           sign with private key
-verify         verify with public key
-encrypt        encrypt with public key
-decrypt        decrypt with private key
-hexdump        hex dump output
复制代码
```

| 命令选项                                     | 描述                                    |
| -------------------------------------------- | --------------------------------------- |
| -in file                                     | 输入文件                                |
| -out file                                    | 输出文件                                |
| -inkey file                                  | 密钥文件                                |
| -keyform arg                                 | 私钥格式，默认是PEM                     |
| -pubin                                       | 输入的是RSA公钥                         |
| -certin                                      | 输入的携带RSA公钥的证书文件             |
| -ssl                                         | 使用SSLv2的填充方式                     |
| -raw                                         | 不进行填充                              |
| -pkcs                                        | 使用PKCS#1 v1.5的填充方式，默认填充方式 |
| -oaep                                        | 使用PKCS#1 OAEP的填充方式               |
| -sign                                        | 使用私钥签名                            |
| -verify                                      | 使用公钥验证签名                        |
| -encrypt                                     | 使用公钥加密                            |
| -decrypt                                     | 使用私钥解密                            |
| -hexdump                                     | 以16进制dump输出                        |
| ##### 加密解密示例：                         |                                         |
| ```shell                                     |                                         |
| // 生成RSA密钥                               |                                         |
| openssl genrsa -out RSA.pem                  |                                         |
| // 提取公钥                                  |                                         |
| openssl rsa -in RSA.pem -pubout -out pub.pem |                                         |

// 使用RSA公钥进行加密，输入的是私钥，实际上使用其对应的公钥进行加密，以下两个等价 openssl rsautl -encrypt -in plain.txt -inkey RSA.pem -out encrypted.txt openssl rsautl -encrypt -in plain.txt -inkey pub.pem -pubin -out encrypted.txt

// 使用RSA私钥进行解密 openssl rsautl -decrypt -in encrypted.txt -inkey RSA.pem -out plain2.txt

```
##### 加签验签示例：
```shell
// 生成RSA密钥
openssl genrsa -out RSA.pem
// 提取公钥
openssl rsa -in RSA.pem -pubout -out pub.pem 

// 使用私钥进行签名
openssl rsautl -sign -in plain.txt -inkey RSA.pem -out sign.txt
// 使用公钥进行验证
openssl rsautl -verify -in sign.txt -pubin -inkey pub.pem -out plain2.txt
复制代码
```

#### 加密、解密、签名、验签，完整代码示例：

```java
import org.apache.commons.codec.binary.Base64;

import javax.crypto.Cipher;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.security.*;
import java.security.spec.PKCS8EncodedKeySpec;
import java.security.spec.X509EncodedKeySpec;

public class RSAUtil {

    /**
     * RSA 算法
     **/
    private static final String ALGORITHM_RSA = "RSA";

    /**
     * 签名算法
     **/
    private static final String ALGORITHM_SIGNATURE = "SHA1WithRSA";

    /**
     * Cipher类提供了加密和解密的功能
     * <p>
     * Cipher cipher = Cipher.getInstance("RSA/ECB/PKCS1PADDING");
     * RSA是算法，ECB是分块模式，PKCS1Padding是填充模式，整个构成一个完整的加密算法
     *
     * <pre>
     * 有以下的参数：
     * * AES/CBC/NoPadding (128)
     * * AES/CBC/PKCS5Padding (128)
     * * AES/ECB/NoPadding (128)
     * * AES/ECB/PKCS5Padding (128)
     * * DES/CBC/NoPadding (56)
     * * DES/CBC/PKCS5Padding (56)
     * * DES/ECB/NoPadding (56)
     * * DES/ECB/PKCS5Padding (56)
     * * DESede/CBC/NoPadding (168)
     * * DESede/CBC/PKCS5Padding (168)
     * * DESede/ECB/NoPadding (168)
     * * DESede/ECB/PKCS5Padding (168)
     * * RSA/ECB/PKCS1Padding (1024, 2048)
     * * RSA/ECB/OAEPWithSHA-1AndMGF1Padding (1024, 2048)
     * * RSA/ECB/OAEPWithSHA-256AndMGF1Padding (1024, 2048)
     * </pre>
     */
    private static final String PADDING = "RSA/ECB/PKCS1PADDING";

    /**
     * 生成非对称密钥对，默认使用RSA
     *
     * @return
     * @throws Exception
     */
    public static String[] generateRSAKeyPair() throws Exception {
        KeyPairGenerator keyPairGenerator = KeyPairGenerator.getInstance(ALGORITHM_RSA);
        keyPairGenerator.initialize(2048);
        KeyPair keyPair = keyPairGenerator.generateKeyPair();

        PublicKey publicKey = keyPair.getPublic();
        PrivateKey privateKey = keyPair.getPrivate();

        String publicKeyStr = Base64.encodeBase64String(publicKey.getEncoded());
        String privateKeyStr = Base64.encodeBase64String(privateKey.getEncoded());
        return new String[]{publicKeyStr, privateKeyStr};
    }

    /**
     * 使用数据接收方的公钥加密
     *
     * @param publicKeyStr BASE64编码格式的公钥
     * @param data         待加密数据
     * @return
     * @throws Exception
     */
    public static String encryptByPublicKeyStr(String publicKeyStr, String data) throws Exception {
        PublicKey publicKey = getPublicKeyFromString(publicKeyStr);
        byte[] bytes = doCipher(Cipher.ENCRYPT_MODE, publicKey, data.getBytes());
        return Base64.encodeBase64String(bytes);
    }

    /**
     * 数据接收方使用自己的私钥解密
     *
     * @param privateKeyStr BASE64编码格式的私钥
     * @param encryptedData 待解密数据
     * @return
     * @throws Exception
     */
    public static String decryptByPrivateKeyStr(String privateKeyStr, String encryptedData) throws Exception {
        PrivateKey privateKey = getPrivateKeyFromString(privateKeyStr);
        byte[] bytes = doCipher(Cipher.DECRYPT_MODE, privateKey, Base64.decodeBase64(encryptedData));
        return new String(bytes);
    }

    /**
     * 使用数据接收方的公钥加密
     *
     * @param publicKeyPath 公钥文件路径
     * @param data          待加密数据
     * @return
     * @throws Exception
     */
    public static String encryptByPublicKeyFile(String publicKeyPath, String data) throws Exception {
        PublicKey publicKey = getPublicKeyFromFile(publicKeyPath);
        byte[] bytes = doCipher(Cipher.ENCRYPT_MODE, publicKey, data.getBytes());
        return Base64.encodeBase64String(bytes);
    }

    /**
     * 数据接收方使用自己的私钥解密
     *
     * @param privateKeyPath 私钥文件路径
     * @param encryptedData  待解密数据
     * @return
     * @throws Exception
     */
    public static String decryptByPrivateKeyFile(String privateKeyPath, String encryptedData) throws Exception {
        PrivateKey privateKey = getPrivateKeyFromFile(privateKeyPath);
        byte[] bytes = doCipher(Cipher.DECRYPT_MODE, privateKey, Base64.decodeBase64(encryptedData));
        return new String(bytes);
    }

    /**
     * 数据发送方使用自己的私钥对数据签名
     *
     * @param privateKeyStr BASE64编码格式的私钥
     * @param data          待签名数据
     * @return 签名数据，一般进行BASE64编码后发送给对方
     * @throws Exception
     */
    public static String signByPrivateKeyStr(String privateKeyStr, String data) throws Exception {
        PrivateKey privateKey = getPrivateKeyFromString(privateKeyStr);
        byte[] bytes = sign(privateKey, data.getBytes());
        return Base64.encodeBase64String(bytes);
    }

    /**
     * 数据接收方使用对方公钥验证签名
     *
     * @param publicKeyStr BASE64编码格式的私钥
     * @param data         待验签数据
     * @param sign         签名数据，进行BASE64解码后验证签名
     * @return
     * @throws Exception
     */
    public static boolean verifyByPublicKeyStr(String publicKeyStr, String data, String sign) throws Exception {
        PublicKey publicKey = getPublicKeyFromString(publicKeyStr);
        return verify(publicKey, data.getBytes(), Base64.decodeBase64(sign));
    }

    private static PublicKey getPublicKeyFromString(String publicKeyStr) throws Exception {
        byte[] encodedKey = Base64.decodeBase64(publicKeyStr);
        return generatePublic(encodedKey);
    }

    private static PublicKey getPublicKeyFromFile(String publicKeyPath) throws Exception {
        byte[] encodedKey = Files.readAllBytes(Paths.get(publicKeyPath));
        return generatePublic(encodedKey);
    }

    private static PublicKey generatePublic(byte[] encodedKey) throws Exception {
        X509EncodedKeySpec keySpec = new X509EncodedKeySpec(encodedKey);
        KeyFactory keyFactory = KeyFactory.getInstance(ALGORITHM_RSA);
        PublicKey publicKey = keyFactory.generatePublic(keySpec);
        return publicKey;
    }

    private static PrivateKey getPrivateKeyFromString(String privateKeyStr) throws Exception {
        byte[] encodedKey = Base64.decodeBase64(privateKeyStr);
        return generatePrivate(encodedKey);
    }

    private static PrivateKey getPrivateKeyFromFile(String privateKeyPath) throws Exception {
        byte[] encodedKey = Files.readAllBytes(Paths.get(privateKeyPath));
        return generatePrivate(encodedKey);
    }

    private static PrivateKey generatePrivate(byte[] encodedKey) throws Exception {
        PKCS8EncodedKeySpec keySpec = new PKCS8EncodedKeySpec(encodedKey);
        KeyFactory keyFactory = KeyFactory.getInstance(ALGORITHM_RSA);
        PrivateKey privateKey = keyFactory.generatePrivate(keySpec);
        return privateKey;
    }

    private static byte[] doCipher(int mode, Key key, byte[] bytes) throws Exception {
        Cipher cipher = Cipher.getInstance(PADDING);
        cipher.init(mode, key);
        return cipher.doFinal(bytes);
    }

    private static byte[] sign(PrivateKey privateKey, byte[] data) throws Exception {
        Signature signature = Signature.getInstance(ALGORITHM_SIGNATURE);
        signature.initSign(privateKey);
        signature.update(data);
        return signature.sign();
    }

    private static boolean verify(PublicKey publicKey, byte[] data, byte[] sign) throws Exception {
        Signature signature = Signature.getInstance(ALGORITHM_SIGNATURE);
        signature.initVerify(publicKey);
        signature.update(data);
        return signature.verify(sign);
    }
}
复制代码
```

##### 测试代码示例：

```java
@Test
public void test_generateRSAKeyPair() throws Exception {
    String data = "password:123456";
    String[] keyPair = RSAUtil.generateRSAKeyPair();
    String publicKeyStr = keyPair[0];
    String privateKeyStr = keyPair[1];
    String encryptedData = RSAUtil.encryptByPublicKeyStr(publicKeyStr, data);
    String decryptedData = RSAUtil.decryptByPrivateKeyStr(privateKeyStr, encryptedData);
    Assert.assertEquals(data, decryptedData);
}

/**
 * 在 /tmp 目录下执行以下命令
 *
 * openssl genrsa -out private.pem
 *
 * openssl rsa -in private.pem -outform der -out private.der
 * openssl pkcs8 -topk8 -inform DER -in private.der -outform DER -nocrypt -out private_pkcs8.der
 *
 * openssl rsa -in private.pem -pubout -out public.pem
 * openssl rsa -pubin -in public.pem -outform der -out public.der
 */
@Test
public void test_openssl() throws Exception {
    String data = "password:123456";
    String encryptedData = RSAUtil.encryptByPublicKeyFile("/tmp/public.der", data);
    String decryptedData = RSAUtil.decryptByPrivateKeyFile("/tmp/private_pkcs8.der", encryptedData);
    Assert.assertEquals(data, decryptedData);
}

@Test
public void test_signature() throws Exception {
    String data = "balance=1000000";
    String[] keyPair = RSAUtil.generateRSAKeyPair();
    String publicKeyStr = keyPair[0];
    String privateKeyStr = keyPair[1];
    String sign = RSAUtil.signByPrivateKeyStr(privateKeyStr, data);
    boolean pass = RSAUtil.verifyByPublicKeyStr(publicKeyStr, data, sign);
    Assert.assertTrue(pass);
}
复制代码
```

## 证书和keytool

上面我们使用了openssl工具生成RSA非对称密钥对，以字符串或标准文件格式存储密钥并处理加解密，在实际Java项目开发中，经常会使用keystore来管理密钥，对此我们可以使用 **keytool** 工具来进行密钥生成，或将其他文件格式的密钥导入**keystore**。

正式介绍**keytool**之前我们先来解释几个概念，对下文keytool的使用理解有帮助。

### 证书

我们先来看一个小场景，A要告诉B一个秘密： ![img](https://p9-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/a6c5f9f8df474154b0d733d3080b7bfc~tplv-k3u1fbpfcp-watermark.image)

上面流程在正常情况下没问题，可以保证数据加密传输，即使被第三方截获，没有B的私钥也解密不了。然而在复杂的网络环境下，情况有可能是这样的： ![img](https://p1-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/c24018e779d943609c1905464f10e92e~tplv-k3u1fbpfcp-watermark.image) 上述过程就是典型的中间人攻击场景，A和B的通讯链路中多了一个中间人X，而AB却完全无感知。在上述流程第4步之后，A持有的是X的公钥，X持有的是B的公钥，而实际上A需要的是B的公钥，但A却不知道，并且它以为自己持有的就是B的公钥，所以接下来A还是正常的使用这个公钥加密并发送数据，这样A和B之间的通讯信息就完全被X获取并且可以随意篡改。

在实际的网络环境中，我们无法阻止X的存在，那如何解决上述中间人攻击问题？通过分析上述流程，我们不难发现，A要获取B的公钥，但实际却收到了X的公钥，然鹅，它却无法辨识出来这个公钥不是B的，而**证书**，可以帮助我们解决这个关键问题。

##### CER-数字证书

数字证书是数字凭据，它提供有关实体标识的信息以及其他支持信息。数字证书是由权威证书颁发机构（Certificate Authority，简称CA）颁发的，由该权威机构担保证书信息的有效性。数字证书包含证书中所标识的实体的公钥，由于证书将公钥与申请者匹配，并且该证书的真实性由颁发机构保证，因此，数字证书为如何找到用户的公钥并知道它是否有效这一问题提供了解决方案。

常见的证书有三种：

1. 带有私钥的证书：由PublicKey Cryptography Standards #12，即PKCS#12标准定义，包含了公钥和私钥的二进制格式的证书形式，以 pfx 作为证书文件后缀名，PKCS#12可以增加加密保护，有助于传输证书及对应的私钥。
2. 二进制编码的证书：由X.509公钥证书格式标准定义，证书中没有私钥，包含DER编码二进制格式的公钥，以 cer 作为证书文件后缀名。
3. Base64编码的证书：由X.509公钥证书格式标准定义，证书中没有私钥，包含BASE64编码格式的公钥，也是以 cer 作为证书文件后缀名。

#### keystore 密钥库

密钥库是存储一个或多个密钥条目的文件，每个密钥条目以一个别名标识，它包含密钥和证书相关信息。

在Java中，keystore中每种类型的条目都实现 **KeyStore.Entry** 接口，主要有三种基本的实现：

1. **KeyStore.PrivateKeyEntry**

此类型的条目保存一个加密的PrivateKey，可以选择用受保护格式存储该私钥，以防止未授权访问。它还随附一个相应公钥的证书链。 2. **KeyStore.SecretKeyEntry** 此类型的条目保存一个加密的SecretKey，可以选择用受保护格式存储该密钥，以防止未授权访问。 3. **KeyStore.TrustedCertificateEntry** 此类型的条目包含一个属于另一方的单个公钥证书(Certificate)。它被称为可信证书，因为keystore的所有者相信证书中的公钥确实属于该证书所标识的身份。

##### keystore 密钥库文件格式

| 格式                           | 扩展名         | 描述                                   | 特点                                                         |
| ------------------------------ | -------------- | -------------------------------------- | ------------------------------------------------------------ |
| JKS                            | .jks/.ks       | 密钥库的Java实现版本，provider为SUN    | 密钥库和私钥用不同的密码进行保护                             |
| JCEKS                          | .jce           | 密钥库的JCE实现版本，provider为SUN JCE | 相对于JKS安全级别更高，保护Keystore私钥时采用3DES            |
| PKCS12                         | .p12/.pfx      | 个人信息交换语法标准                   | 包含私钥、公钥及其证书，密钥库和私钥用相同密码进行保护       |
| BKS                            | .bks           | 密钥库的BC实现版本，provider为BC       | 基于JCE实现                                                  |
| ##### Certificate 证书文件格式 |                |                                        |                                                              |
| 格式                           | 扩展名         | 描述                                   | 特点                                                         |
| ---                            | ---            | ---                                    | ---                                                          |
| DER                            | .cer/.crt/.rsa | 用于存放证书                           | 不含私钥，二进制格式                                         |
| PKCS7                          | .p7b/.p7r      | PKCS#7加密信息语法标准                 | p7b以树状展示证书链，不含私钥，p7r为CA对证书请求签名的回复，只能用于导入 |
| CMS                            | .p7c/.p7m/.p7s | Cryptographic Message Syntax           | p7c只保存证书；p7m：signature with enveloped data；p7s：时间戳签名文件 |
| PEM                            | .pem           | 可打印的Base64编码信息                 | 该编码格式在RFC1421中定义，PEM是Privacy Enhanced Mail的简写，但也同样广泛运用于密钥管理ASCII文件，一般基于Base64编码 |
| PKCS10                         | .p10/.csr      | PKCS #10公钥加密标准                   | 证书签名请求文件，CA签名后以p7r文件回复                      |

##### truststore

另外，平时我们有时也会看到**truststore**，从其文件格式来看它和**keystore**其实是一个东西，只是为了方便管理将其分开，**keystore**一般保存的是私钥，用来加解密或者做签名，而**truststore**中保存的是一些可信任的证书，主要是在Java在代码中以HTTPS方式调用时对被访问者进行认证的，以确保它是可信任的。

### keytool

接下来我们使用keytool工具来生成密钥和证书。

##### keytool命令

```shell
keytool
密钥和证书管理工具

命令:

 -certreq            生成证书请求
 -changealias        更改条目的别名
 -delete             删除条目
 -exportcert         导出证书
 -genkeypair         生成密钥对
 -genseckey          生成密钥
 -gencert            根据证书请求生成证书
 -importcert         导入证书或证书链
 -importpass         导入口令
 -importkeystore     从其他密钥库导入一个或所有条目
 -keypasswd          更改条目的密钥口令
 -list               列出密钥库中的条目
 -printcert          打印证书内容
 -printcertreq       打印证书请求的内容
 -printcrl           打印 CRL 文件的内容
 -storepasswd        更改密钥库的存储口令
复制代码
```

##### keytool -genkeypair 命令

```shell
keytool -genkeypair -help
keytool -genkeypair [OPTION]...

生成密钥对

选项:

 -alias <alias>                  要处理的条目的别名
 -keyalg <keyalg>                密钥算法名称
 -keysize <keysize>              密钥位大小
 -sigalg <sigalg>                签名算法名称
 -destalias <destalias>          目标别名
 -dname <dname>                  唯一判别名
 -startdate <startdate>          证书有效期开始日期/时间
 -ext <value>                    X.509 扩展
 -validity <valDays>             有效天数
 -keypass <arg>                  密钥口令
 -keystore <keystore>            密钥库名称
 -storepass <arg>                密钥库口令
 -storetype <storetype>          密钥库类型
 -providername <providername>    提供方名称
 -providerclass <providerclass>  提供方类名
 -providerarg <arg>              提供方参数
 -providerpath <pathlist>        提供方类路径
 -v                              详细输出
 -protected                      通过受保护的机制的口令
复制代码
```

下面我们使用该命令生成一对非对称密钥并将公钥包装到X.509 V3自签名证书中，密钥条目别名和密钥库文件名均为java-and-more，密钥库类型为pkcs12，并按提示输入对应内容：

```shell
keytool -genkeypair -alias java-and-more -keyalg RSA -keystore /tmp/java-and-more.keystore -storetype pkcs12

输入密钥库口令:  
再次输入新口令: 
您的名字与姓氏是什么?
  [Unknown]:  javaandmore
您的组织单位名称是什么?
  [Unknown]:  javaandmore
您的组织名称是什么?
  [Unknown]:  javaandmore
您所在的城市或区域名称是什么?
  [Unknown]:  sz
您所在的省/市/自治区名称是什么?
  [Unknown]:  sz
该单位的双字母国家/地区代码是什么?
  [Unknown]:  China
CN=javaandmore, OU=javaandmore, O=javaandmore, L=sz, ST=sz, C=China是否正确?
  [否]:  Y
复制代码
```

注意PKCS12不支持设置密钥库条目密码，默认它与密钥库密码一致，如果创建默认类型(JKS)的密钥库，可以通过-keypass参数指定密钥条目密码。

**keytool -list 命令** 查看密钥库内容：

```shell
keytool -list -v -keystore /tmp/java-and-more.keystore
输入密钥库口令:  

密钥库类型: JKS
密钥库提供方: SUN

您的密钥库包含 1 个条目

别名: java-and-more
创建日期: 2020-10-8
条目类型: PrivateKeyEntry
证书链长度: 1
证书[1]:
所有者: CN=javaandmore, OU=javaandmore, O=javaandmore, L=sz, ST=sz, C=China
发布者: CN=javaandmore, OU=javaandmore, O=javaandmore, L=sz, ST=sz, C=China
序列号: 80e7f12
有效期开始日期: Thu Oct 08 22:11:59 CST 2020, 截止日期: Wed Jan 06 22:11:59 CST 2021
证书指纹:
	 MD5: 21:C6:CE:BE:D8:38:42:F6:FF:EF:78:D4:E3:AF:B3:57
	 SHA1: E2:DF:6A:8B:86:CC:65:D4:19:C7:22:B5:06:FC:58:F2:75:FE:8A:D2
	 SHA256: A1:28:22:B7:13:4F:77:50:0E:BE:F4:D4:40:19:2D:B3:94:88:47:1D:13:3A:13:75:DE:07:33:3B:39:A1:B0:40
	 签名算法名称: SHA256withRSA
	 版本: 3

扩展: 

#1: ObjectId: 2.5.29.14 Criticality=false
SubjectKeyIdentifier [
KeyIdentifier [
0000: 70 76 4E 22 F6 6B 57 68   B5 F6 92 93 26 D4 A8 80  pvN".kWh....&...
0010: 52 88 1E 74                                        R..t
]
]



*******************************************
*******************************************
复制代码
```

**keytool -exportcert 命令** 导出密钥库条目证书

```shell
keytool -exportcert -keystore /tmp/java-and-more.keystore -alias java-and-more -file /tmp/java-and-more.crt

输入密钥库口令:  
存储在文件 </tmp/java-and-more.crt> 中的证书
复制代码
```

**keytool -printcert 命令** 打印证书内容

```shell
keytool -printcert -v -file /tmp/java-and-more.crt

所有者: CN=javaandmore, OU=javaandmore, O=javaandmore, L=sz, ST=sz, C=China
发布者: CN=javaandmore, OU=javaandmore, O=javaandmore, L=sz, ST=sz, C=China
序列号: 80e7f12
有效期开始日期: Thu Oct 08 22:11:59 CST 2020, 截止日期: Wed Jan 06 22:11:59 CST 2021
证书指纹:
	 MD5: 21:C6:CE:BE:D8:38:42:F6:FF:EF:78:D4:E3:AF:B3:57
	 SHA1: E2:DF:6A:8B:86:CC:65:D4:19:C7:22:B5:06:FC:58:F2:75:FE:8A:D2
	 SHA256: A1:28:22:B7:13:4F:77:50:0E:BE:F4:D4:40:19:2D:B3:94:88:47:1D:13:3A:13:75:DE:07:33:3B:39:A1:B0:40
	 签名算法名称: SHA256withRSA
	 版本: 3

扩展: 

#1: ObjectId: 2.5.29.14 Criticality=false
SubjectKeyIdentifier [
KeyIdentifier [
0000: 70 76 4E 22 F6 6B 57 68   B5 F6 92 93 26 D4 A8 80  pvN".kWh....&...
0010: 52 88 1E 74                                        R..t
]
]
复制代码
```

从keystore文件导出的证书、密钥都是DER格式，可以使用openssl工具转换成PEM格式

```shell
openssl x509 -inform der -in /tmp/java-and-more.crt -out /tmp/java-and-more.pem
复制代码
```

再从证书中导出公钥信息

```shell
openssl x509 -in /tmp/java-and-more.pem -pubkey -out public-key.pem

-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAtkPH2M8uL4T0Lu4g2qYt
zclIkMhNHkfkL5rOqaZKSwYYwgG/NH9V4+Byf2Of5/1GfXQU8dFKwfXSm7rlL4/Y
jKj5uy2xKBq2H2d2m7XoNqWzPOc8swkFraGEhxf4swbU6O/sRIxJJuelruPUh51o
SN3LeLRQBDxkX2irEGICQZGcFshckBvH13PJtHKf0ZnXw3FzFde7IswiVrrwiEXP
ttLQm0hM/xh3/Pcav7u0ademaVppSc8zC6sTxIxwyeyl2J8FXytdUakxixDqm/du
nNBTfO7+dSNGLJ+ATztluhfZcIeE2+t66Ya/6PKK6DSBxZwXnErKcuLvLVPnMX+d
5wIDAQAB
-----END PUBLIC KEY-----
复制代码
```

注意：无法使用命令直接从keystore导出私钥信息，需要使用代码实现。以下示例使用Java从 PKCS12证书中提取私钥和公钥

```java
@Test
public void test_keystore() throws Exception {
    String keyStoreFile = "/tmp/java-and-more.keystore";
    char[] password = "123456".toCharArray();
    KeyStore keyStore = KeyStore.getInstance("pkcs12");
    keyStore.load(Files.newInputStream(Paths.get(keyStoreFile)), password);
    Enumeration<String> aliases = keyStore.aliases();
    while (aliases.hasMoreElements()) {
        String alias = aliases.nextElement();
        System.out.println(alias);

        X509CertImpl certImpl = (X509CertImpl) keyStore.getCertificate(alias);
        PublicKey publicKey = certImpl.getPublicKey();
        System.out.println(Base64.encodeBase64String(publicKey.getEncoded()));

        RSAPrivateCrtKeyImpl keyImpl = (RSAPrivateCrtKeyImpl) keyStore.getKey(alias, password);
        System.out.println(Base64.encodeBase64String(keyImpl.getEncoded()));
    }
}
复制代码
```

#### 证书的签发与导入

这个过程涉及到3个命令：

- keytool -certreq
- keytool -gencert
- keytool -importcert

分别对应以下3个步骤：

1. 机构A使用certreq命令生成一个证书签名请求文件CSR (certificate sign request)并将其发送给机构B
2. 机构B接收到这个请求后，使用gencert命令签发证书，会生成一个证书或者证书链
3. 机构A接收到响应，使用importcert命令将签发证书导入到keystore中

下面以Alice.keystore签名的证书导入到密钥库Bob.keystore为例演示上述过程：

先生成两个keystore文件

```shell
keytool -genkeypair -alias Alice -keyalg RSA -keystore /tmp/Alice.keystore -storetype pkcs12
keytool -genkeypair -alias Bob -keyalg RSA -keystore /tmp/Bob.keystore -storetype pkcs12
复制代码
```

生成证书签名请求文件CSR，即将条目别名为 Alice 的公钥和一些个人信息从密钥库 Alice.keystore 文件中导出，作为证书请求文件

```shell
keytool -certreq -alias Alice -keystore /tmp/Alice.keystore -file /tmp/cert.csr
复制代码
```

签发证书，使用密钥库Bob.keystore中别名为 Bob 条目的私钥为 cert.csr 签发证书，并保存到 Bob-to-Alice.crt 文件中

```shell
keytool -gencert -infile /tmp/cert.csr -outfile /tmp/Bob-to-Alice.crt -alias Bob -keystore /tmp/Bob.keystore
复制代码
```

导入签发证书到密钥库，将签发证书 Bob-to-Alice.crt 更新到已存在别名 Alice 的密钥库 Alice.keystore 文件中

```shell
keytool -importcert -file /tmp/Bob-to-Alice.crt -alias Alice -keystore /tmp/Alice.keystore
输入密钥库口令:  
keytool 错误: java.lang.Exception: 无法从回复中建立链
复制代码
```

这是因为在更新被签发证书之前，一定要先将签发证书的机构的信任证书导入到密钥库文件，即将密钥库Bob.keystore的证书以其相应的别名导入到密钥库Alice.keystore中。

导出Bob.keystore的信任证书：

```shell
keytool -exportcert -keystore /tmp/Bob.keystore -alias Bob -file /tmp/Bob.crt
复制代码
```

将信任证书Bob.crt以其别名Bob导入到密钥库Alice.keystore

```shell
keytool -importcert -file /tmp/Bob.crt -alias Bob -keystore /tmp/Alice.keystore
复制代码
```

再将签发证书Bob-to-Alice.crt以别名Alice导入到密钥库Alice.keystore：

```shell
keytool -importcert -file /tmp/Bob-to-Alice.crt -alias Alice -keystore /tmp/Alice.keystore
输入密钥库口令:  
证书回复已安装在密钥库中
复制代码
```

对比最开始生成的密钥库Alice.keystore的证书信息可发现，别名为Alice条目的证书链已由单个Alice.keystore自签名的证书变为2个证书，分别是Bob.keystore签名的及Alice.keystore的自签名证书。

至此，我们已经基本把对称加密和非对称加密从原理、场景、工具和代码等多方面进行了介绍。

## 散列函数

接下来我们补充一个在日常开发中也会广泛应用到的算法：信息摘要算法，也叫散列函数、哈希函数。不同于上述两种算法，信息摘要算法并不算是一种加密算法，它有以下几个特点反而让它在某些场景下非常适用：

1. 固定输入得到固定输出，且不同输入得到相同输出的概率极低
2. 理论上不能从散列计算之后的值逆向推导出原始明文
3. 无论输入的数据长度多少，得到的输出值长度是固定的（不同的哈希算法长度不一样）

设想这种场景，我们要在数据库中保存用户密码，首先肯定不能保存明文，既然要使用密文保存，那使用对称加密还是非对称加密呢？结合实际场景和安全性考虑，两种都不合适！因为这两种都要考虑密钥的管理，如果密钥泄漏那密码则有被破解的风险。在这种场景下，我们可以使用单向散列函数来解决这个问题，这样即使算法和密文都泄漏，也无法逆向计算出明文。

当然散列函数还有更多用途，比如文件一致性校验、数字签名等。

常见的哈希算法有：MD5、sha1、sha2(sha224、sha256、sha384、sha512)，其中sha1加密后的长度是160字节，sha2加密之后的密文长度和shaxxx的数字相同，比如sha256加密之后，密文长度为256字节。

关于哈希算法的更详细介绍可以看一下这篇文章，[最常用的三种哈希算法](https://link.juejin.cn?target=https%3A%2F%2Fblog.csdn.net%2Fzhanxiao5287%2Farticle%2Fdetails%2F90300222)。

##### openssl dgst 命令

```shell
openssl dgst [-md5|-md4|-md2|-sha1|-sha|-mdc2|-ripemd160|-dss1] [-c] [-d] [-hex] [-binary] [-out filename] [-sign filename] [-keyform arg] [-passin arg] [-verify filename] [-prverify filename] [-signature filename] [-hmac key] [file…] 

-md5|-md4|-md2|-sha1|-sha|-mdc2|-ripemd160|-dss1：哈希算法的名称，默认值为md5。 
-c：打印出哈希结果的时候用冒号来分隔开。 
-d：详细打印出调试信息 
-hex：以十六进制的形式输出结果，这是默认形式。 
–binary：以二进制的形式输出结果。 
-out filename：输出文件名，如果没有指定就采用标准输出。 
-sign filename：从指定文件中读出私钥来对摘要值签名
复制代码
```

##### openssl dgst 示例

```shell
openssl dgst -sha1 -c /tmp/java-and-more.pem
SHA1(/tmp/java-and-more.pem)= 7e:2a:0b:1e:2e:ec:f8:c2:f7:6a:b3:bf:25:98:64:26:f5:66:ab:38
复制代码
```

##### Java代码实现MD5计算

```java
@Test
public void test_md5() throws Exception {
    MessageDigest messageDigest = MessageDigest.getInstance("MD5");
    byte[] fileBytes = Files.readAllBytes(Paths.get("/tmp/java-and-more.pem"));
    messageDigest.update(fileBytes);
    byte[] result = messageDigest.digest();
    System.out.println(Base64.encodeBase64String(result));
}
复制代码
```

终于写到这里了，良心力作，码字不易，欢迎收藏。更多精彩文章请关注：Java架构之道 (java-and-more)

> 参考资料：
>
> 1. [baike.baidu.com/item/Blowfi…](https://link.juejin.cn?target=https%3A%2F%2Fbaike.baidu.com%2Fitem%2FBlowfish%2F1677776)
> 2. [baike.baidu.com/item/对称加密/2…](https://link.juejin.cn?target=https%3A%2F%2Fbaike.baidu.com%2Fitem%2F%E5%AF%B9%E7%A7%B0%E5%8A%A0%E5%AF%86%2F2152944)
> 3. [www.cnblogs.com/gordon0918/…](https://link.juejin.cn?target=https%3A%2F%2Fwww.cnblogs.com%2Fgordon0918%2Fp%2F5317701.html)
> 4. [blog.csdn.net/u011414629/…](https://link.juejin.cn?target=https%3A%2F%2Fblog.csdn.net%2Fu011414629%2Farticle%2Fdetails%2F102645600)
> 5. [baike.baidu.com/item/非对称加密算…](https://link.juejin.cn?target=https%3A%2F%2Fbaike.baidu.com%2Fitem%2F%E9%9D%9E%E5%AF%B9%E7%A7%B0%E5%8A%A0%E5%AF%86%E7%AE%97%E6%B3%95%2F1208652)
> 6. [www.jianshu.com/p/78886e480…](https://link.juejin.cn?target=https%3A%2F%2Fwww.jianshu.com%2Fp%2F78886e480bef)
> 7. [blog.csdn.net/makenothing…](https://link.juejin.cn?target=https%3A%2F%2Fblog.csdn.net%2Fmakenothing%2Farticle%2Fdetails%2F88429511)
> 8. [blog.csdn.net/zlfing/arti…](https://link.juejin.cn?target=https%3A%2F%2Fblog.csdn.net%2Fzlfing%2Farticle%2Fdetails%2F77648444)
> 9. [blog.csdn.net/w47_csdn/ar…](https://link.juejin.cn?target=https%3A%2F%2Fblog.csdn.net%2Fw47_csdn%2Farticle%2Fdetails%2F87564029)