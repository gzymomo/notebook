- [datax + datax_web避坑指南 - 欲乘风上云霄 - 博客园 (cnblogs.com)](https://www.cnblogs.com/zsf-note/p/15727339.html)

用datax_web 原因：后续有各个项目需要用到datax抽数据，配置json浪费时间，用python脚本去调度也麻烦，datax_web 可以批量配置ison 并存储到数据库里，迁移也方便。

## 1 环境

- **java 1.8**

- **python 3.7**

- **mysql 8.0.19**

- **maven >=3.6.1**

- **hadoop 2.6 + windows运行需要的winutils.exe（自己用报错信息找一下，我忘了在哪下载的了）**

- **datax_web 2.1.2**

## 2 下载datax

直接下载：http://datax-opensource.oss-cn-hangzhou.aliyuncs.com/datax.tar.gz

就不要去下没有打包的版本了，省的麻烦。

解压之后有可能有“._XXXX”这种的文件，全都搜出来删除掉

![img](https://img2020.cnblogs.com/blog/1697360/202112/1697360-20211223162000051-37100104.png)

 

## 3 下载datax_web

下载GitHub开源版本：https://github.com/WeiYe-Jing/datax-web

clone 或者直接下载zip随意。

下载下来之后

![img](https://img2020.cnblogs.com/blog/1697360/202112/1697360-20211223162035428-2114341844.png)

 

拉到idea 中进行配置：

1、maven环境变量配置就不说了，conf配置网上多的很，别忘了idea中的maven配置，我这个有以前的maven 3.6的仓库，所以直接用了，没有仓库的自己建一个，之后等依赖自己下载完。

![img](https://img2020.cnblogs.com/blog/1697360/202112/1697360-20211223162256731-1040718176.png)

2、mysql建表

![img](https://img2020.cnblogs.com/blog/1697360/202112/1697360-20211224133450662-366050261.png)

 直接用自带的脚本在mysql客户端建个database 命名为datax_web，在这个数据库中跑一下脚本就行了

3、修改datax_web 中 配置

datax-admin下配置修改：

坑1、时区问题，mysql8时区一般都是UTC,那么东八区是要加八个小时,url中加上 serverTimezone=GMT%2B8

如果你用原本的上海的时区没问题的化就不用改了

坑2、driver-class-name: com.mysql.cj.jdbc.Driver 这个一般是mysql8用的，5用的是不加cj的

datax-executor下配置修改：该注释的注释掉，该开的开，最后一行 datax路径改成自己的路径：pypath: D:\workspace\datax\datax\bin\datax.py

```
server:`` ``port: 8080``# port: ${server.port}``spring:`` ``#数据源`` ``datasource:``  ``username: root　　#你的mysql 用户 和密码``  ``password: 123456``  ``url: jdbc:mysql:``//localhost:3306/datax_web?serverTimezone=GMT%2B8&useUnicode=true&characterEncoding=UTF-8``# &&serverTimezone=GMT``#  password: ${DB_PASSWORD:password}``#  username: ${DB_USERNAME:username}``#  url: jdbc:mysql://${DB_HOST:127.0.0.1}:${DB_PORT:3306}/${DB_DATABASE:dataxweb}?serverTimezone=Asia/Shanghai&useLegacyDatetimeCode=false&useSSL=false&nullNamePatternMatchesAll=true&useUnicode=true&characterEncoding=UTF-8``  ``driver-``class``-name: com.mysql.cj.jdbc.Driver` `  ``hikari:``   ``## 最小空闲连接数量``   ``minimum-idle: 5``   ``## 空闲连接存活最大时间，默认600000（10分钟）``   ``idle-timeout: 180000``   ``## 连接池最大连接数，默认是10``   ``maximum-pool-size: 10``   ``## 数据库连接超时时间,默认30秒，即30000``   ``connection-timeout: 30000``   ``connection-test-query: SELECT 1``   ``##此属性控制池中连接的最长生命周期，值0表示无限生命周期，默认1800000即30分钟``   ``max-lifetime: 1800000` ` ``# datax-web email`` ``mail:``  ``host: smtp.qq.com``  ``port: 25``  ``username: xxx@qq.com``  ``password: xxx``#  username: ${mail.username}``#  password: ${mail.password}``  ``properties:``   ``mail:``    ``smtp:``     ``auth: ``true``     ``starttls:``      ``enable: ``true``      ``required: ``true``    ``socketFactory:``     ``class``: javax.net.ssl.SSLSocketFactory` `management:`` ``health:``  ``mail:``   ``enabled: ``false`` ``server:``  ``servlet:``   ``context-path: /actuator` `mybatis-plus:`` ``# mapper.xml文件扫描`` ``mapper-locations: classpath*:/mybatis-mapper/*Mapper.xml`` ``# 实体扫描，多个package用逗号或者分号分隔`` ``#typeAliasesPackage: com.yibo.essyncclient.*.entity`` ``global-config:``  ``# 数据库相关配置``  ``db-config:``   ``# 主键类型 AUTO:"数据库ID自增", INPUT:"用户输入ID", ID_WORKER:"全局唯一ID (数字类型唯一ID)", UUID:"全局唯一ID UUID";``   ``id-type: AUTO``   ``# 字段策略 IGNORED:"忽略判断",NOT_NULL:"非 NULL 判断"),NOT_EMPTY:"非空判断"``   ``field-strategy: NOT_NULL``   ``# 驼峰下划线转换``   ``column-underline: ``true``   ``# 逻辑删除``   ``logic-delete-value: 0``   ``logic-not-delete-value: 1``   ``# 数据库类型``   ``db-type: mysql``  ``banner: ``false`` ``# mybatis原生配置`` ``configuration:``  ``map-underscore-to-camel-``case``: ``true``  ``cache-enabled: ``false``  ``call-setters-``on``-nulls: ``true``  ``jdbc-type-``for``-``null``: ``'null'``  ``type-handlers-package: com.wugui.datax.admin.core.handler` `# 配置mybatis-plus打印sql日志``logging:`` ``level:``  ``com.wugui.datax.admin.mapper: info``  ``path: ./data/applogs/admin``# level:``#  com.wugui.datax.admin.mapper: error``#  path: ${data.path}/applogs/admin`  `#datax-job, access token``datax:`` ``job:``  ``accessToken:``  ``#i18n (default empty as chinese, "en" as english)``  ``i18n:``  ``## triggerpool max size``  ``triggerpool:``   ``fast:``    ``max: 200``   ``slow:``    ``max: 100``   ``### log retention days``  ``logretentiondays: 30` `datasource:`` ``aes:``  ``key: AD42F6697B035B75
```

4、启动admin，然后启动 executor

可能出现的问题1：缺少hadoop windows的运行路径，一般缺少的是这两个文件，从网上下载下来放到hadoop_home下的bin里

![img](https://img2020.cnblogs.com/blog/1697360/202112/1697360-20211224141350489-1079345352.png)

进网页上看吧，http://127.0.0.1:8080/index.html  初始用户名密码：admin 123456

5、任务配置流程

5.1、数据源配置：

以mysql为例，因为我的mysql时区问题，连接串后面加这个就可以了，oracle这些数据库都没啥问题。测试数据库连接是否成功，如果不成功那么基本是时区的问题

 

![img](https://img2020.cnblogs.com/blog/1697360/202112/1697360-20211224135835535-53870090.png)

5.2、项目管理：随意

5.2、任务模板配置：

![img](https://img2020.cnblogs.com/blog/1697360/202112/1697360-20211224140008344-896320706.png)

5.3、测试表新建，在你的数据源和目标数据源新建数据库，分别新建源表和目标表，源表与目标表结构一致，源表随意造点数据。新建源表和目标表数据源，同5.1

5.4、任务构建：

单个任务：选择数据源和表名，字段选择->目标表数据源，字段选择->构建json->选择模板->ok

批量任务构建：直接把数据源中的所有表展示，手动点击需要哪些表，目标表是自动对应的，流程和单个任务一样。

![img](https://img2020.cnblogs.com/blog/1697360/202112/1697360-20211224140648731-1885764716.png)

5.5、任务测试：

单个任务：直接点击操作的执行

多任务手动调用：新建个python任务，里面直接写个print("随意")，如果是python2.7那就直接写 print '随意'；子任务下选择多个任务。

​    ![img](https://img2020.cnblogs.com/blog/1697360/202112/1697360-20211224142006442-894759348.png)

5.6、日志查看

错误1：执行器没有运行。datax-executor启动执行器

![img](https://img2020.cnblogs.com/blog/1697360/202112/1697360-20211224142125446-1245228477.png)

 错误2：存在超过一个time_zone，datax里面的lib缺少mysql驱动，版本就从datax_web中依赖中找出来复制到datax的lib和读写的文件夹下，好好检查

路径大概是：总libs：D:\workspace\datax\datax\lib      读： D:\workspace\datax\datax\plugin\reader\mysqlreader\libs  写：D:\workspace\datax\datax\plugin\writer\mysqlwriter\libs

　　　　　　读写中一般都是![img](https://img2020.cnblogs.com/blog/1697360/202112/1697360-20211224153137978-2049511061.png)

 

　　　　　　总libs添加上你的mysql数据库同版本驱动，或者同代版本好像也行

  6、打包

打包之前先把repackage在admin和executor的pom中给加上，放在build标签里面

```xml
<plugin>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-maven-plugin</artifactId>
    <executions>
        <execution>
            <goals>
                <goal>repackage</goal>
            </goals>
        </execution>
    </executions>
</plugin> 
```

   完事之后：在maven工具箱里面点击 datax_web下的clean ，完毕之后再点击package 打jar包

   把admin 和exetor中target中的jar包单独拿出来放到自己的文件夹中，执行这两个jar包肯定会报错，你打开看下jar包里面没有配置文件和mapper，那么把admin下target中的配置文件和分别拉到jar包中，executor只需要拉个配置文件。如下：都在classes文件夹中

![img](https://img2020.cnblogs.com/blog/1697360/202112/1697360-20211224143251163-2052656079.png)![img](https://img2020.cnblogs.com/blog/1697360/202112/1697360-20211224143326515-435847379.png)

 

  完事后，java -jar 运行这两个jar

![img](https://img2020.cnblogs.com/blog/1697360/202112/1697360-20211224143437901-1333597390.png)

可以登录了。