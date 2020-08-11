[TOC]

博客园：字母哥博客：[通过java程序(JSch)运行远程linux主机上的shell脚本](https://www.cnblogs.com/zimug/p/13450493.html)



## 运行远程主机上的shell脚本

下面的例子是教给大家如何通过java程序，运行远程主机上的shell脚本。（我讲的不是一个黑客学习教程，而是使用用户名密码去执行有用户认证资格的主机上的shell脚本）。并且通过java程序获得shell脚本的输出。
首先通过maven坐标引入[JSch](http://www.jcraft.com/jsch/)依赖库，我们正是通过JSch去执行远程主机上的脚本。

```markup
<dependency>
    <groupId>com.jcraft</groupId>
    <artifactId>jsch</artifactId>
    <version>0.1.55</version>
</dependency>
```

当然以下java代码可执行的的前提是，远程主机已经开通SSH服务（也就是我们平时登录主机所使用的服务）。

### 远程shell脚本

下面的代码放入一个文件：`hello.sh`，脚本的内容很简单只是用来测试，回显输出“hello <参数1> ”

```bash
#! /bin/sh
echo "hello $1\n";
```

然后我把它放到远程主机的`/root`目录下面，远程主机的IP是`1.1.1.1`（当然我真实测试时候不是这个IP，我不能把我的真实IP写到这个文章里面，以免被攻击）。并且在远程主机上，为这个脚本设置可执行权限，方法如下：

```bash
$ chmod +x hello.sh
```

### 本地java程序

我们可以使用下面的代码，去远程的linux 主机执行shell脚本，详细功能请看代码注释

```java
import com.jcraft.jsch.*;

import java.io.IOException;
import java.io.InputStream;

public class RunRemoteScript {
    //远程主机IP
    private static final String REMOTE_HOST = "1.1.1.1";
    //远程主机用户名
    private static final String USERNAME = "";
    //远程主机密码
    private static final String PASSWORD = "";
    //SSH服务端口
    private static final int REMOTE_PORT = 22;
    //会话超时时间
    private static final int SESSION_TIMEOUT = 10000;
    //管道流超时时间(执行脚本超时时间)
    private static final int CHANNEL_TIMEOUT = 5000;

    public static void main(String[] args) {
        //脚本名称及路径，与上文要对上
        String remoteShellScript = "/root/hello.sh";

        Session jschSession = null;

        try {

            JSch jsch = new JSch();
            //SSH授信客户端文件位置，一般是用户主目录下的.ssh/known_hosts
            jsch.setKnownHosts("/home/zimug/.ssh/known_hosts");
            jschSession = jsch.getSession(USERNAME, REMOTE_HOST, REMOTE_PORT);

            // 密码认证
            jschSession.setPassword(PASSWORD);

            // 建立session
            jschSession.connect(SESSION_TIMEOUT);
            //建立可执行管道
            ChannelExec channelExec = (ChannelExec) jschSession.openChannel("exec");

            // 执行脚本命令"sh /root/hello.sh zimug"
            channelExec.setCommand("sh " + remoteShellScript + " zimug");

            // 获取执行脚本可能出现的错误日志
            channelExec.setErrStream(System.err);

            //脚本执行结果输出，对于程序来说是输入流
            InputStream in = channelExec.getInputStream();

            // 5 秒执行管道超时
            channelExec.connect(CHANNEL_TIMEOUT);

            // 从远程主机读取输入流，获得脚本执行结果
            byte[] tmp = new byte[1024];
            while (true) {
                while (in.available() > 0) {
                    int i = in.read(tmp, 0, 1024);
                    if (i < 0) break;
                    //执行结果打印到程序控制台
                    System.out.print(new String(tmp, 0, i));
                }
                if (channelExec.isClosed()) {
                    if (in.available() > 0) continue;
                    //获取退出状态，状态0表示脚本被正确执行
                    System.out.println("exit-status: "
                         + channelExec.getExitStatus());
                    break;
                }
                try {
                    Thread.sleep(1000);
                } catch (Exception ee) {
                }
            }

            channelExec.disconnect();

        } catch (JSchException | IOException e) {

            e.printStackTrace();

        } finally {
            if (jschSession != null) {
                jschSession.disconnect();
            }
        }

    }
}
```

最终在本地控制台，获得远程主机上shell脚本的执行结果。如下：

```bash
hello zimug

exit-status: 0
```