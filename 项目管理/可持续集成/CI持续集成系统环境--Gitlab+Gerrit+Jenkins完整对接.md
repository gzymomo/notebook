为了实现代码托管->代码审核->代码发布的一套自动化流程，我特意在IDC服务器上部署了Gitlab+Gerrit+Jenkins对接环境，以下记录了操作过程：

整体的架构图如下：

![img](https://images2018.cnblogs.com/blog/907596/201805/907596-20180509142137458-234217816.png)
\----------------------------------------------------------------------------------------------------------------------------------------
1）Gitlab上进行代码托管
在gitlab上创建的项目设置成Private，普通用户对这个项目就只有pull权限，不能直接进行push，Git自带code review功能。
强制Review ：在 Gitlab 上创建的项目，指定相关用户只有Reporter权限，这样用户没有权限使用git push功能，只能git review到Gerrit 系统上，Jenkins在监听Gerrit上的项目事件会触发构建任务来测试代码， Jenkins 把测试结果通过 ssh gerrit 给这个项目打上 Verified （信息校验）成功或失败标记，成功通知其它人员 Review（代码审核） 。
Gitlab保护Master 分支：在 Gitlab 上创建的项目可以把 Master 分支保护起来，普通用户可以自己创建分支并提交代码到自己的分支上，没有权限直接提交到Master分支，用户最后提交申请把自己的分支 Merge 到 Master ，管理员收到 Merge 请求后， Review 后选择是否合并。
可以将gitlab和gerrit部署在两台机器上，这样gitlab既可以托管gerrit代码，也可以作为gerrit的备份。
因为gitlab和gerrit做了同步，gerrit上的代码会同步到gitlab上。
这样即使gerrit部署机出现故障，它里面的代码也不会丢失，可以去gitlab上拿。
2）Gerrit审核代码
Gerrit是一款被Android开源项目广泛采用的code review(代码审核)系统。普通用户将gitlab里的项目clone到本地，修改代码后，虽不能直接push到代码中心 ，但是可以通过git review提交到gerrit上进行审核。gerrit相关审核员看到review信息后，判断是否通过，通过即commit提交。然后，gerrit代码会和gitlab完成同步。
grrit的精髓在于不允许直接将本地修改同步到远程仓库。客户机必须先push到远程仓库的refs/for/*分支上，等待审核。
gerrit上也可以对比代码审核提交前后的内容状态。
3）jenkins代码发布
当用户git review后，代码通过jenkins自动测试（verified）、人工review 后，代码只是merge到了Gerrit的项目中，并没有merge到 Gitlab的项目中，所以需要当 Gerrit 项目仓库有变化时自动同步到Gitlab的项目仓库中。Gerrit 自带一个 Replication 功能，同时我们在安装 Gerrit 时候默认安装了这个 Plugin，通过添加replication.config 给 Gerrit即可（下文有介绍）
\----------------------------------------------------------------------------------------------------------------------------------------

一、基础环境搭建（参考下面三篇文档）
[CI持续集成系统环境---部署gerrit环境完整记录](http://www.cnblogs.com/kevingrace/p/5624122.html)
[CI持续集成系统环境---部署Gitlab环境完整记录](http://www.cnblogs.com/kevingrace/p/5651402.html)
[CI持续集成系统环境---部署Jenkins完整记录](http://www.cnblogs.com/kevingrace/p/5651427.html)

二、Gitlab+Gerrit+Jenkins的对接
**1）Gitlab配置**
gitlab上的管理员账号是gerrit，邮箱是gerrit@xqshijie.cn
创建了一个普通账号wangshibo，邮箱是wangshibo@xqshijie.cn
[root@115]# su - gerrit
[gerrit@115 ~]$ ssh-keygen -t rsa -C gerrit@xqshijie.cn     //产生公私钥
[gerrit@115 ~]$ cat ~/.ssh/id_rsa.pub
将上面gerrit账号的公钥内容更新到Gitlab上。
使用gerrit账号登陆Gitlab，点击页面右上角的Profile Settings - 点击左侧的SSH Keys小钥匙图标 - 点击Add SSH Key。
在Key对应的输入框中输入上段落$cat .ssh/id_rsa.pub显示的公钥全文，点击Title，应该会自动填充为gerrit@xqshijie.cn。如下：

在Gitlab上创建wangshibo用户
然后在机器上生成wangshibo公钥（先提前在机器上创建wangshibo用户，跟上面一样操作），然后将公钥内容更新到Gitlab上（用wangshibo账号登陆Gitlab）
用gerrit登陆Gitlab，新建group组为dev-group，然后创建新项目test-project1（在dev-group组下，即项目的Namespace为dev-group，将wangshibo用户添加到dev-group组内，权限为Reporter），具体如下截图：

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160708140005514-701718521.png)

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160708140031967-1514133776.png)

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160708140108014-1035635996.png)

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160708140158733-1549858696.png)

创建的项目设置成Private即私有的，这样普通用户这它就只有pull权限，没有push权限。

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160708140236624-528720120.png)

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160711204117076-258792039.png)

在test-project1工程里创建文件，创建过程此处省略......
文件创建后，如下：

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160708140833030-1939067546.png)

在linux系统上登录wangshibo账号下，克隆工程test-project1.git，测试权限
[root@115]# su - wangshibo
[wangshibo@115 ~]$ git clone git@103.10.86.30:dev-group/test-project1.git
Initialized empty Git repository in /home/wangshibo/test-project1/.git/
remote: Counting objects: 15, done.
remote: Compressing objects: 100% (9/9), done.
remote: Total 15 (delta 0), reused 0 (delta 0)
Receiving objects: 100% (15/15), done.
[wangshibo@115 ~]$ cd ~/test-project1/
[wangshibo@115 ~]$ git config --global user.name 'wangshibo'
[wangshibo@115 ~]$ git config --global user.email 'wangshibo@xqshijie.cn'
[wangshibo@115 ~]$ touch testfile
[wangshibo@115 ~]$ git add testfile
[wangshibo@115 ~]$ git commit -m 'wangshibo add testfile'
[wangshibo@115 ~]$git push
GitLab: You are not allowed to push code to this project.
fatal: The remote end hung up unexpectedly

上面有报错，因为普通用户没有直接push的权限。需要先review到gerrit上进行审核并commit后，才能更新到代码中心仓库里。
**2）Gerrit配置**
在linux服务器上切换到gerrit账号下生成公私钥
[gerrit@115]$ ssh-keygen -t rsa -C gerrit@xqshijie.cn
将id_rsa.pub公钥内容更新到gerrit上（管理员gerrit账号登陆）的SSH Public Keys里

 ![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160708141827327-1362252851.png)

同样的，将gerrit的其他两个普通账号wangshibo和jenkins也在linux服务器上生产公私钥，邮箱分别是wangshibo@xqshijie.cn和jenkins@xqshijie.cn
并将两者的公钥id_rsa.pub内容分别更新到各自登陆的gerrit的SSH Public Keys里
**3）Jenkins配置**
Jenkins系统已经创建了管理员账户jenkins并安装了Gerrit Trigger插件和Git plugin插件
在“系统管理”->“插件管理"->”可选插件"->搜索上面两个插件进行安装
使用jenkins账号登陆jenkins，进行Jenkins系统的SMTP设置 (根据具体情况配置)
“主页面->系统管理->系统设置”，具体设置如下：
首先管理员邮件地址设置成jenkins@xqshijie.cn

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160708142848061-1008577744.png)

设置SMTP的服务器地址，点击“高级”

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160708142923155-1036807294.png)

jenkins@xqshijie.cn的密码要确认填对，然后测试邮件发送功能，如果如下出现successfully，就成功了！ 点击“保存”

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160708143057483-96424560.png)

接下来设置Gerrit Trigger

 ![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160708143305889-1571079450.png)

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160708143318561-1262572854.png)

Add New Server : Check4Gerrit
勾选 Gerrit Server With Default Configurations

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160708143403999-1036468032.png)

 

具体设置如下：
设置好之后，点击“Test Connection”，如果测试连接出现如下的Success，即表示连接成功！
点击左下方的Save保存。

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160711194934201-2142181136.png)

\-----------------------------------------------------------------------------------------
如果上一步在点击“Test Connection”测试的时候，出现下面报错：
解决办法：
管理员登录gerrit
Projects->List->All-Projects
Projects->Access
Global Capabilities->Stream Events 点击 Non-Interactive Users
添加 Jenkins@zjc.com 用户到 ‘Non-Interactive Users’ 组
\-----------------------------------------------------------------------------------------

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160708143827811-754319063.png)

**4）Gerrit 和 Jenkins 整合**
让Gerrit支持Jenkins
如果安装Gerrit时没有或者没有选择添加Verified标签功能[‘lable Verified’]，需要自己添加。
如下是手动添加Verified标签功能的设置（由于我在安装Gerrit的时候已经选择安装Verified标签功能了，所以下面橙色字体安装操作可省略）
[如果在安装gerrit的时候没有选择安装这个标签功能，就需要在此处手动安装下。具体可以登陆gerrit，ProjectS->list->All-Projects->Access->Edit->Add Permission 看里面是否有Verfied的选项]
\# su - gerrit
$ git init cfg; cd cfg
$ git config --global user.name 'gerrit'
$ git config --global user.email 'gerrit@xqshijie.cn'
$ git remote add origin ssh://gerrit@103.10.86.30:29418/All-Projects
$ git pull origin refs/meta/config
$ vim project.config
[label "Verified"]
  function = MaxWithBlock
  value = -1 Fails
  value = 0 No score
  value = +1 Verified
$ git commit -a -m 'Updated permissions'
$ git push origin HEAD:refs/meta/config
$ rm -rf cfg

用gerrit管理员账号登录Gerrit
现在提交的Review请求只有Code Rivew审核，我们要求的是需要Jenkins的Verified和Code Review双重保障，在 Projects 的 Access 栏里，针对 Reference: refs/heads/ 项添加 Verified 功能，如下如下：
Projects -> List -> All-Projects
Projects -> Access -> Edit -> 找到 Reference: refs/heads/* 项 -> Add Permission -> Label Verified -> Group Name 里输入 Non-Interactive Users -> 回车 或者 点击Add 按钮 -> 在最下面点击 Save Changes 保存更改。
(注意：提前把jenkins用户添加到Non-Interactive Users组内）
权限修改结果如下：

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160714133918545-1129004545.png)

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160714133944826-1466899863.png)

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160714133958139-438503362.png)

截图如下：

 ![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160714134014686-1936170243.png)

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160714134032420-383285395.png)

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160714134113998-808242264.png)

添加Verified后的权限如下

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160714134134529-1410784926.png)

 

 

Gitlab上设置test-project1工程
前面我们在Gitlab上搭建了一个 test-project1 的工程，普通用户是没有办法去 push 的，只能使用 git review 命令提交. 而 git review 命令需要 .gitreview 文件存在于项目目录里。
用 gerrit用户添加.gitreview 文件
[root@115]# su - gerrit
[gerrit@115]$ git clone git@103.10.86.30:dev-group/test-project1.git
[gerrit@115]$ cd test-project1
[gerrit@115]$ vim .gitreview

```
[gerrit]``host=103.10.86.30``port=29418``project=``test``-project1.git
```

添加.gitreview到版本库
[gerrit@115]$git add .gitreview
[gerrit@115]$git config --global user.name 'gerrit'
[gerrit@115]$git config --global user.email 'gerrit@xqshijie.cn'
[gerrit@115]$git commit .gitreview -m 'add .gitreview file by gerrit.'
[gerrit@115]$git push origin master

用gerrit用户添加.testr.conf 文件
Python 代码我使用了 testr，需要先安装 testr 命令
[root@115]# easy_install pip
[root@115]# pip install testrepository

在 test-project1 这个项目中添加 .testr.conf 文件
[root@115]#su - gerrit
[gerrit@115]$cd test-project1
[gerrit@115]$vim .testr.conf

```
[DEFAULT]``test_command=OS_STDOUT_CAPTURE=1``OS_STDERR_CAPTURE=1``OS_TEST_TIMEOUT=60``${PYTHON:-python} -m subunit.run discover -t ./ ./ $LISTOPT $IDOPTION``test_id_option=--load-list $IDFILE``test_list_option=-list
```

提交到版本库中
[gerrit@115]$git add .testr.conf
[gerrit@115]$git commit .testr.conf -m 'add .testr.conf file by gerrit'
[gerrit@115]$git push origin master

Gerrit上设置 test-project1工程
在Gerrit上创建 test-project1 项目
要知道review是在gerrit上，而gerrit上现在是没有项目的，想让gitlab上的项目能在gerrit上review的话，必须在gerrit上创建相同的项目，并有相同的仓库文件.
用gerrit用户在 Gerrit 上创建 test-project1 项目
[root@115]# su - gerrit
[gerrit@115]$ ssh-gerrit gerrit create-project test-project1 (gerrit环境部署篇里已经设置好的别名，方便连接gerrit)
登陆gerrit界面，发现test-project1工程已经创建了。（这种方式创建的项目是空的）

 ![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160708150629514-1300929083.png)

clone --bare Gitlab上的仓库到 Gerrit （gerrit上的项目最好是从gitlab上git clone --bare过来，并且项目不要为空）
因为gerrit用户无访问gitlab的权限。所以要先看是否gerrit用户下已经存在了id_rsa密钥，如果没有则创建，然后把公钥加入到gitlab的管理员账户上（因为后面Gerrit系统还会有个复制git库到 Gitlab的功能需要管理员权限）（这个测试环境，gitlab和gerrit的管理员我用的都是gerrit，所以秘钥也是共用）
[gerrit@115]$ cd /home/gerrit/gerrit_site/git/       //即登陆到gerrit安装目录的git下
[gerrit@115 git]$ rm -fr test-project1.git
[gerrit@115 git]$ git clone --bare git@103.10.86.30:dev-group/test-project1.git       //创建并将远程gitlab上的这个项目内容发布到gerrit上
[gerrit@115 git]$ ls
All-Projects.git test-project1.git
[gerrit@115 git]$ cd test-project1.git/
[gerrit@115 git]$ ls                 //即test-project1工程和gerrit里默认的All-Projects.git工程结构是一样的了
branches config description HEAD hooks info objects packed-refs refs

同步 Gerrit的test-project1 项目到 Gitlab 上的 test-project1 项目目录中
当用户git review后，代码通过 jenkins 测试、人工 review 后，代码只是 merge 到了 Gerrit 的 test-project1 项目中，并没有 merge 到 Gitlab 的 test-project1 项目中，所以需要当 Gerrit test-project1 项目仓库有变化时自动同步到 Gitlab 的 test-project1 项目仓库中。
Gerrit 自带一个 Replication 功能，同时我们在安装 Gerrit 时候默认安装了这个 Plugin。

现在只需要添加一个 replication.config 给 Gerrit
[gerrit@115]$ cd /home/gerrit/gerrit_site/etc/
[gerrit@115]$ vim replication.config

```
[remote ``"test-project1"``]``projects = ``test``-project1``url = git@103.10.86.30:dev-group``/test-project1``.git``push = +refs``/heads/``*:refs``/heads/``*``push = +refs``/tags/``*:refs``/tags/``*``push = +refs``/changes/``*:refs``/changes/``*``threads = 3
```

设置gerrit用户的 ~/.ssh/config
[gerrit@115]$ vim /home/gerrit/.ssh/config

```
Host 103.10.86.30:``    ``IdentityFile ~/.``ssh``/id_rsa``    ``PreferredAuthentications publickey
```

在gerrit用户的~/.ssh/known_hosts 中，给103.10.86.30 添加 rsa 密钥
[gerrit@115]$ sh -c "ssh-keyscan -t rsa 103.10.86.30 >> /home/gerrit/.ssh/known_hosts"
[gerrit@115]$ sh -c "ssh-keygen -H -f /home/gerrit/.ssh/known_hosts"
----------------------------------------------特别注意----------------------------------------------
上面设置的~/.ssh/config文件的权限已定要设置成600
不然会报错：“Bad owner or permissions on .ssh/config“
\----------------------------------------------------------------------------------------------------
重新启动 Gerrit 服务
[gerrit@115]$/home/gerrit/gerrit_site/bin/gerrit.sh restart

Gerrit 的复制功能配置完毕
在 gerrit 文档中有一个 ${name} 变量用来复制 Gerrit 的所有项目，这里并不需要。如果有多个项目需要复制，则在 replication.config 中添加多个 [remote ….] 字段即可。务必按照上面步骤配置复制功能。

在 Jenkins 上对 test-project1 项目创建构建任务
Jenkins上首先安装git插件：Git Plugin
登陆jenkins，“系统管理”->“管理插件”->“可选插件”->选择Git Pluin插件进行安装

Jenkins上创建项目
添加 test-project1工程

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160708163658717-107803721.png)

 

 

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160708163727952-1849420158.png)

下面添加url：http://103.10.86.30:8080/p/test-project1.git
添加分支：origin/$GERRIT_BRANCH

如下：

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160708163826217-567995788.png)

 

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160708164013514-844568357.png)

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160708164132967-260361105.png)

构建Excute Shell，添加如下脚本
cd $WORKSPACE
[ ! -e .testrepository ] && testr init
testr run![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160708164330530-480930028.png)

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160708164727311-621088260.png)

测试
linux系统上用wangshibo账号提交一个更改
用wangshibo登录
删除目录 test-project1
克隆 test-project1 工程
进入 test-project1 目录
添加文件、提交
git review 增加 review 到Gerrit
[root@115]# su - wangshibo
[wangshibo@115]$ rm -rf test-project1/
[wangshibo@115]$ git clone git@103.10.86.30:dev-group/test-project1.git
[wangshibo@115]$ cd test-project1/
[wangshibo@115]$ touch testfile
[wangshibo@115]$ git add testfile
[wangshibo@115]$ git commit -m "wangshibo add this testfile"

[wangshibo@115]$ **git review**             //提交review代码审核请求
The authenticity of host '[103.10.86.30]:29418 ([103.10.86.30]:29418)' can't be established.
RSA key fingerprint is 83:ff:31:e8:68:66:6d:49:29:08:91:aa:ef:36:77:3e.
Are you sure you want to continue connecting (yes/no)? yes
Creating a git remote called "gerrit" that maps to:
ssh://wangshibo@103.10.86.30:29418/test-project1.git
Your change was committed before the commit hook was installed
Amending the commit to add a gerrit change id
remote: Resolving deltas: 100% (1/1)
remote: Processing changes: new: 1, refs: 1, done
To ssh://wangshibo@103.10.86.30:29418/test-project1.git
\* [new branch] HEAD -> refs/publish/master
----------------------------------------小提示----------------------------------------
安装git-review
[root@115]# git clone git://github.com/facebook/git-review.git
[root@115]# cd git-review
[root@115]# python setup.py install
[root@115]# pip install git-review==1.21
[root@115]# yum install readline-devel
\--------------------------------------------------------------------------------------

代码审核处理
用gerrit管理员账号登录 Gerrit ，点击"All“->”Open“-> 打开提交的review
打开后就能看见jenkins用户已经Verified【原因下面会提到】。
然后点击Review进行审核

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160714141112873-398758845.png)

 

由于上面已经配置了gerrit跟jenkins的对接工作，所以当git review命令一执行，jenkins上的test-project1工程的测试任务就会自动触发
如下：如果任务自动执行成功了，就说明jenkins测试通过，然后jenkins会利用ssh连接gerrit并给提交的subject打上verified信息校验结果，然后审核人员再进行review。

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160714141259170-215316777.png)

**所以用gerrit管理员登陆后发现，jenkins已经通过了Verified。然后进入subject，先查看代码/文件变更，然后点击Reply,写一点review后的意见之类的，然后评分（+2通过，-2拒绝，+1投赞成票，-1投反对票），然后点击post。**

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160714141137717-750884103.png)

注意：
等到jenkins上Verified通过后，即看到下图右下角出现“Verified +1 jenkins"后
才能点击"Code-Review+2",如下：

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160714141546529-1037167514.png)

然后点击“Submit"，提交审核过的代码

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160714141710436-1000439105.png)

 

 ![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160714141815201-1380146518.png)

再次查看，review请求已被审核处理，并且已经Merged合并了！

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160714141902045-1935514728.png)

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160714141915920-199410349.png)

 **最后登录 Gitlab查看 test-project1 工程，可以看到新增加文件操作已经同步过来了**

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160714154145467-1966051934.png)

 

 ![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160714154217389-65662956.png)

注意：在审核人员进行review和submit操作前，要先等到jenkins测试并通过ssh方式连上gerrit给相应提交审核的subjects带上Verified通过后才能进行。（gitlab＋gerrit＋jenkins环境配置后，提交到gerrit上审核的subjects的review人员中会默认第一个是jenkins，jenkins有结果并verified后，其他人员才能veriew和submit。也就是说当开发人员使用git review上报gerrit进行code review后，jenkins会自动触发测试任务，通过后会在gerrit的subject审核界面显示verified结果，当显示的结果是“verified ＋1 jenkins“后就可以进行Review和submit了，最后同步到gitlab中心仓库。）

查看同步日志：
可以在gerrit服务器上查看replication日志：
[gerrit@115 logs]$ pwd
/home/gerrit/gerrit_site/logs
[gerrit@115 logs]$ cat replication_log
.........................
[2016-07-14 15:30:13,043] [237da7bf] Replication to git@103.10.86.30:dev-group/test-project1.git completed in 1288 ms
[2016-07-14 15:32:29,358] [] scheduling replication test-project1:refs/heads/master => git@103.10.86.30:dev-group/test-project1.git
[2016-07-14 15:32:29,360] [] scheduled test-project1:refs/heads/master => [03b983c0] push git@103.10.86.30:dev-group/test-project1.git to run after 15s
[2016-07-14 15:32:44,360] [03b983c0] Replication to git@103.10.86.30:dev-group/test-project1.git started...
[2016-07-14 15:32:44,363] [03b983c0] Push to git@103.10.86.30:dev-group/test-project1.git references: [RemoteRefUpdate[remoteName=refs/heads/master, NOT_ATTEMPTED, (null)...dda55b52b5e5f78e2332ea2ffcb7317120347baa, srcRef=refs/heads/master, forceUpdate, message=null]]
[2016-07-14 15:32:48,019] [03b983c0] Replication to git@103.10.86.30:dev-group/test-project1.git completed in 3658 ms

\----------------------------------------------------------------------------------------------------
关于jenkins上的结果：
如上，在服务器上wangshibo账号下
git review命令一执行，即代码审核只要一提出，Jenkins 就会自动获取提交信息并判断是否verified
如下，当jenkins上之前创建的工程test-project1执行成功后，那么jenkins对提交到gerrit上的review请求
就会自动执行Verified（如上）

 ![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160711204753404-1953355562.png)

----------------------------------------------注意----------------------------------------------
有个发现：
jenkins上测试并返回给gerrit上提交的subject打上Verified信息核实通过的标签后，会将代码拿到自己本地相应工程的workspace目录下
这里的jenkins代码路径是：/usr/local/tomcat7/webapps/jenkins/workspace/test-project1

不过值得注意的是，jenkins拿过来的代码只是每次git review修改前的代码状态
可以把这个当做每次代码修改提交前的备份状态
即：代码修改后，在gerrit里面审核，commit后同步到gitlab，修改前的代码状态存放在jenkins里面
\-----------------------------------------------------------------------------------------------
手动安装gerrit插件
[gerrit@115r ~]$ pwd
/home/gerrit
[gerrit@115r ~]$ ls
gerrit-2.11.3.war gerrit_site

进行插件安装，下面安装了四个插件
[gerrit@115r ~]$ java -jar gerrit-2.11.3.war init -d gerrit_site --batch --install-plugin replication
Initialized /home/gerrit/gerrit_site
[gerrit@115r ~]$ java -jar gerrit-2.11.3.war init -d gerrit_site --batch --install-plugin reviewnotes
Initialized /home/gerrit/gerrit_site
[gerrit@115r ~]$ java -jar gerrit-2.11.3.war init -d gerrit_site --batch --install-plugin commit-message-length-validator
Initialized /home/gerrit/gerrit_site
[gerrit@115r ~]$ java -jar gerrit-2.11.3.war init -d gerrit_site --batch --install-plugin download-commands
Initialized /home/gerrit/gerrit_site

查看plugins目录，发现已经有插件了
[gerrit@115r ~]$ cd gerrit_site/plugins/
[gerrit@115r ~]$ ls
commit-message-length-validator.jar download-commands.jar replication.jar reviewnotes.jar

查看安装了哪些插件
[gerrit@115r ~]$ ssh-gerrit gerrit plugin ls

Name                   Version         Status         File
\-------------------------------------------------------------------------------
commit-message-length-validator v2.11.3 ENABLED commit-message-length-validator.jar
download-commands v2.11.3 ENABLED download-commands.jar
replication v2.11.3 ENABLED replication.jar
reviewnotes v2.11.3 ENABLED reviewnotes.jar

或者登陆gerrit也可查看

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160714152407654-2142069803.png)

------------------------------------------------注意------------------------------------------------
gerrit手动同步代码到gitlab中心仓库上
[gerrit@115r ~]$ ssh-gerrit gerrit --help      //查看帮助，发现gerrit COMMAND --help可查找命令帮忙
[gerrit@115r ~]$ ssh-gerrit replication start --help      //查看replication同步命令的用法

replication start [PATTERN ...] [--] [--all] [--help (-h)] [--url PATTERN] [--wait]

PATTERN : project name pattern
-- : end of options
--all : push all known projects
--help (-h) : display this help text
--url PATTERN : pattern to match URL on
--wait : wait for replication to finish before exiting


[gerrit@115r ~]$ ssh-gerrit replication start --all           //同步所有工程
\-------------------------------------------------------------------------------------------------------

重载replication的同步服务
[gerrit@115r ~]$ ssh-gerrit gerrit plugin reload replication
如果报错：fatal: remote plugin administration is disabled

解决办法：
在/home/gerrit/gerrit_site/etc/gerrit.config文件里添加下面内容：
[plugins]
allowRemoteAdmin = true

然后重启gerrit服务即可：
[gerrit@115r ~]$ /home/gerrit/gerrit_site/bin/gerrit.sh restart
Stopping Gerrit Code Review: OK
Starting Gerrit Code Review: OK

\----------------------------------------------------------------------
ssh-gerrit是别名
[gerrit@115r ~]$ cat ~/.bashrc
\# .bashrc

\# Source global definitions
if [ -f /etc/bashrc ]; then
. /etc/bashrc
fi
alias ssh-gerrit='ssh -p 29418 -i ~/.ssh/id_rsa 103.10.86.30 -l gerrit'
\# User specific aliases and functions
\-------------------------------------------------------------------------------------------

 

**多个工程在Gitlab上可以放在不同的group下进行管理**
如下面两个工程（多个工程，就在后面追加配置就行）
dev-group /test-project1
app/xqsj_android

**多个工程的replication**
[gerrit@Zabbix-server etc]$ cat replication.config

```
[remote ``"test-project1"``]``projects = ``test``-project1``url = git@103.10.86.30:dev-group``/test-project1``.git``push = +refs``/heads/``*:refs``/heads/``*``push = +refs``/tags/``*:refs``/tags/``*``push = +refs``/changes/``*:refs``/changes/``*``threads = 3` `[remote ``"xqsj_android"``]``projects = xqsj_android``url = git@103.10.86.30:app``/xqsj_android``.git``push = +refs``/heads/``*:refs``/heads/``*``push = +refs``/tags/``*:refs``/tags/``*``push = +refs``/changes/``*:refs``/changes/``*``threads = 3
```

然后在每个代码库里添加.gitreview和.testr.conf 文件，
注意.gitreview文件里的项目名称

按照上面同步配置后，Gerrit里面的代码就会自动同步到Gitlab上，包括master分支和其他分支都会自动同步的。
如果，自动同步失效或者有问题的话，可以尝试手动同步（下面有提到）

另外：为了减少错误，建议在配置的时候，gitlab和gerrit里的账号设置成一样的，共用账号/邮箱/公钥
gerrit默认的两个project：All-Project和All-Users绝不能删除！！

**--------------------------------------------去掉jenkins测试的方式---------------------------------------------**

如果gerrit不跟jenkins结合，不通过jenkins测试并返回verified核实的方式，可以采用下面的代码审核流程（必须先对提交的审核信息进行verified核实，然后再进行代码的review审核，最后submit提交）：
[去掉上面gerrit和jenkins对接设置，即关闭jenkins服务（关停对应的tomcat应用），gerrit的access授权项verified里删除“Group Non-Interactive Users”（在这个组内踢出jenkins用户），并删除gerrit上的jenkins用户]

1）上传代码者（自己先verified核实，然后通知审核者审核）
修改代码，验证后提交到 Gerrit 上。
代码提交后登陆 Gerrit，自己检查代码（重点看缩进格式跟原文件是否一致；去掉红色空格部分；修改内容是否正确；命名是否有意义；注释内容是否符合要求等）。
自己检查没问题后，点 “Reply”按钮，在“Verified”中 ＋1，在“Code Review”中 +1，并点“Post“
在”Reviewer”栏中，点击”Add"添加审核者 [如果不添加审核者，上传者自己也可以审核并完成提交。注意：只有Review是＋2的时候，才能出现submit的提交按钮]
如果代码审核没有通过，请重复步骤1，2，3。

流程截图：
代码提交后，上传者自行登陆gerrit，找到提交的subject，点击"Reply"

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160717152537904-1148182224.png)

 

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160717152617420-689335320.png)

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160717152800654-456086371.png)

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160717152826029-1976707277.png)

2）审核者
收到邮件通知后登陆 Gerrit，审核代码。
如果审核通过，点 “Reply”按钮，在“Verified”中 ＋1，在“Code Review”中 +2，并点“Post”，最后点击“Submit“提交！
如果代码审核没有通过，点 “Review”按钮，在“Code Review”中 -2，写好评论后，点“Post”。

流程截图：
如上，subject的owner添加审核者后，审核者登陆gerrit进行review
点击“Reply"

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160717161738889-236879008.png)

 

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160717153054123-76891877.png)

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160717153115529-206738882.png)

这样，就完成了一个代码的审核全部过程！
登陆gitlab，就会发现gerrit上审核通过并提交后的代码已经同步过来了！

注意:
如上的设置，在gerrit里授权的时候：
Revified权限列表里添加“Project Owners“（－1和+1）和审核者组（－1和＋1）
Review权限列表里添加“Project Owners“和审核者组（都要设置－2和＋2）

附授权截图：

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160717160016623-1807349496.png)

**------------------------------------让非管理员用户也有gitweb访问权限--------------------------------------**

发现在gerrit与gitweb集成后，默认情况下，只有gerrit的管理员才有gitweb的访问权限，普通用户点击gitweb链接显示404错误。
最后发现使用gitweb需要有【refs/*】下所有的read权限和【refs/meta/config】的read权限！
默认情况下：
【refs/*】下的read权限授予对象是：Administrators和Anonymous Users（所有用户都是匿名用户，这个范围很大，已默认包括所有用户）

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160718115149997-957617543.png)

【refs/meta/config】的read权限授予对象是：Administrators和Project Owners
如想要比如上面的xqsh-app组内的用户能正常访问gitweb，那么就在【refs/meta/config】分支下授予这个组的Allow权限即可！！
截图如下：

 ![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160718100103279-1204807952.png)

使用普通用户wangshibo（在xqsj-app组内）登陆gerrit，发现能打开xqsj_android项目的gitweb超链接访问了

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160718112355232-32228246.png)

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160718112418919-1570571543.png)

\---------------------------------------------------------------------------------------------------------
后续应开发人员的要求：Gitlab+gerrit+jenkins环境下,gerrit有几个细节，都是需要设置好的：
1）项目A的开发人员对于除A以外的项目没有访问权限；
2）每个开发人员应该有+2和submit，以及创建分支的权限；
3）给teamleader配置force push的权限；

设置方案：
第1个要求：
在gerrit里面设置read权限，即"refs/*"下的"Read"权限。
先保持将All-Projects默认权限不变！
然后重新Edit项目A的权限去覆盖掉All-Projects继承过来的这个权限（下面会提到）
如下截图（前面的Exclusive一定要打勾，覆盖效果才能生效）

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160719111059872-2048593526.png)

其实，开发人员是没有必要开通gitlab账号！只要gerrit提前和gitlab做好同步对接工作，那么直接设置好gerrit权限，开发人员可直接通过ssh方式登陆gerrit进行代码操作（git clone代码，然后修改，提交审核，自动同步等）所以，只需要给开发人员开通gerrit账号即可！
<如下，通过ssh方式连接gerrit上的项目，进行git clone代码或git pull操作等>
如下：
按照gerrit上的ssh连接方式clone项目代码（前提是把本地服务器的公钥上传到gerrit上）
可以复制下图中的clone或clone with commit-msg hook地址在本地进行代码clone

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160718155620779-1188796707.png)

第2个要求：
a）在gerrit里面设置，创建组比如xqsj－app，然后把这个组添加到gerrit界面相对应项目的”access“授权里的“refs／heads／＊”－>Label Code-Review内，以及Submit内，这样就保证每个开发人员有＋2和submit权限
b）将上面创建的xqsh－app组添加到gerrit界面相对应项目的”access“授权里的“refs/heads/*”－>“Create Reference”内，这样就能保证每个开发人员有创建分支的权限了。

第3个要求：
创建teamleader组，比如xqsj－app－teamleader，将这个组添加到A项目编辑的下面两个权限里，去覆盖从All-Projects继承过来的权限！
“refs/heads/*”－>"Push"
“refs/meta/config”->“Push”
这两个地方地Push权限最好只赋给Administrators管理员和teamleader组，这样就保证了每个teamleader有force push的权限了。
（注意，勾上在后面的“force push”前的小框，如下截图）
这样，xqsj－app－teamleader组内的用户通过ssh方式连接gerrit，git clone下载代码，修改后可直接git push了（不需要review审核）

 ![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160719111307872-1484903291.png)

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160719111320201-553213397.png)

在这里还讲一下下面/refs/for/refs/*的两个Push权限，这个All-Projects里默认是赋予Registered Users注册用户的
那么，在给项目新编辑权限去覆盖的时候，最好把权限赋予对象改成项目所在的组！
（如上面所说的，修改代码push的中心仓库的权限就只关联到上面两个权限，跟这个无关）

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160719111407997-1443140829.png)

如下：
将wangshibo用户拉到xqsj－app－teamleader组内，上面已经设置了“Force Push”权限，所以wangshibo用户连接gerrit
修改后的代码可直接push了！然后同步到gitlab！
[wangshibo@115 ~]$ git clone ssh://wangshibo@103.10.86.30:29418/xqsj_android
Initialized empty Git repository in /home/wangshibo/www/xqsj_android/.git/
remote: Counting objects: 653, done
remote: Finding sources: 100% (653/653)
remote: Total 653 (delta 180), reused 653 (delta 180)
Receiving objects: 100% (653/653), 2.86 MiB, done.
Resolving deltas: 100% (180/180), done.
[wangshibo@Zabbix-server www]$ ls
xqsj_android
[wangshibo@115 ~]$ cd xqsj_android/
[wangshibo@115 ~]$ vim testfile         //修改代码
[wangshibo@115 ~]$ git add testfile
[wangshibo@115 ~]$ git commit -m "222"
[master 87a02b7] 222
1 files changed, 1 insertions(+), 0 deletions(-)
[wangshibo@115 ~]$ git push       //直接push即可！如果wangshibo不在teamleader组内，就不能直接push了，就只能git review审核了！
Counting objects: 5, done.
Delta compression using up to 32 threads.
Compressing objects: 100% (2/2), done.
Writing objects: 100% (3/3), 261 bytes, done.
Total 3 (delta 1), reused 0 (delta 0)
remote: Resolving deltas: 100% (1/1)
remote: Processing changes: refs: 1, done
To ssh://wangshibo@103.10.86.30:29418/xqsj_android
1840a0c..87a02b7 master -> master

这样，一个项目的开发人员在修改代码并提交gerrit后，就可以指定有相应权限的人员进行review和submit了。
另外注意：
修改gerrit上创建的group组名或增删等操作，可以直接在服务器上的mysql里面操作。

---------------------------------------------------特别注意-------------------------------------------------------
如果要想让新建立的项目不继承或不完全继承All-Project项目权限，可以自己重新修改或添加权限，以便去覆盖掉不想继承的权限！
这里以我测试环境的一个项目xqsj_android做个例子说明：

首先在gerrit上创建一个组xqsj_android，将wangshibo普通用户放到这个组内！
1）想要wangshibo登陆gerrit后，只能访问它所在的项目xqsj_android
设置方法：
上面已讲到，即将All-Projects的access里的"refs/*"-"Read"权限只给Administors（就只保留管理员的这个read权限），这样，project工程就只有管理员权限才能访问到了！
<因为其他新建的项目默认都是继承All-Projects权限的，设置上面的Read权限只保留Administors后，其他的项目如果不Edit自己的权限去覆盖继承过来的权限，那么这些项目内的用户登陆后，都访问不了这些项目的>

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160718190946560-172720786.png)

然后再在xqsj_android项目上创建Reference权限，去覆盖继承过来的All-Project权限！
特别注意下面的“Exclusive”，这个一定要勾上！！勾上了才能生效，才能覆盖All-Project项目的权限。
截图如下：

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160719110511201-688301905.png)

如上截图，发现“refs/*”的“Read”权限除给了管理员Administrators，也添加了xqsj_android组，由于wangshibo在这个组内，
所以wangshibo登陆gerrit后，有访问xqsj_android项目的权限。

 ![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160718191442951-2105209841.png)

注意：
All-Projects默认的权限最好都保持不变，不要动！
新建项目有的权限可以自行Edit编辑，然后去覆盖All-Projects继承过来的权限（新建的Reference时，后面的Exclusive一定要在前面的小方框内打上勾，这样覆盖才能生效！）

下面贴一下本人线上的gerrit项目修改后的权限：

![img](https://images2015.cnblogs.com/blog/907596/201611/907596-20161122205952565-901928247.png)

![img](https://images2015.cnblogs.com/blog/907596/201611/907596-20161122210024721-1794695291.png)

\------------------------------------------------------------------------------------------------------
git clone下载代码，可以根据gitlab上的ssh方式克隆，也可以根据gerrit上的ssh方式克隆代码。
具体采用哪种，根据自己的需要判断。

注意：当审核未通过打回时，我们再修改完成之后，执行：
git add 文件名
git commit --amend ##注意会保留上次的 change-id ，不会生成新的评审任务编号，重用原有的任务编号，将该提交转换为老评审任务的新补丁集
git review
\-------------------------------------------------------------------------------------------------------
如果想让某个用户只有读权限，没有写权限。即登陆gerrit后只能查看，不能进行下载，上传提交等操作
解决：
1）创建一个read的用户组，然后将这个只读用户拉到这个read组内

![img](https://images2015.cnblogs.com/blog/907596/201608/907596-20160823170614651-618714291.png)

2）在相应项目的access授权里添加这个用户组，如下，只需添加下面两个地方的Read部分即可：
其中，“refs/meta/config”里的Read授权，可以让用户查看到gitlab

 ![img](https://images2015.cnblogs.com/blog/907596/201608/907596-20160823170634495-7128994.png)

 

![img](https://images2015.cnblogs.com/blog/907596/201608/907596-20160823170658105-1542183785.png)

----------------------------------------------添加tag权限----------------------------------------------
如上，已经给teamleader用户组内的用户授权直接push了，但是后面发现teamleader里的用户只能直接push推送代码到gerrit里，
而不能直接push推送tag标签到gerrit里！
这是因为上面的push权限是针对“refs/heads/*”和“refs/meta/config”设置的
而push tag需要针对“refs/tags/*”进行设置
所以，需要添加refs/tags/*部分的设置，并给与push权限，如下：

![img](https://images2015.cnblogs.com/blog/907596/201608/907596-20160829163331949-289947445.png)

\--------------------------------------------------------------------------------------------------------------

**gerrit完整迁移**
将远程gerrit上的代码迁移到本地新的gerrit上
要求：
远程gerrit里的代码分支和提交记录都要迁移过来，【即Git仓库迁移而不丢失log】（push的时候使用--mirrot镜像方式即可）
流程：
1）将远程gerrit的项目比如A进行git clone –bare克隆裸版本库到本地
2）在本地新的gerrit上创建同名项目A（创建空仓库）
3）然后将克隆过来的A项目内容git push --mirror到本地新gerrit上的项目A内
git push --mirror git@gitcafe.com/username/newproject.git （新gerrit上项目A的访问地址）
这种方式就能保证分支和提交记录都能完整迁移过来了！！！

\----------------------------------------------------------------------------------------------------------
后续对项目代码进行操作，在登陆gerrit审核后，查看代码（对比代码提交前后的内容）时候出现了一个错误，具体如下：
其实代码review通过并submit后，查看代码有两种方式：
1）通过项目的gitweb查看。当然，这种方法查看也比较繁琐，没有下面的第（2）种方法查看起来方便

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160721150119388-1347052745.png)

2）通过submit提交后的界面（也就是merged合并后的界面），如下点击红色方框内的审核代码进行查看：

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160721150634154-545381918.png)

但是点击上面红色方框内的审核代码进行查看，出现如下报错：

 ![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160721150652107-560873960.png)

**经过排查，发现造成这个报错的原因是由于nginx的反代配置有误造成的**，如下：
proxy_pass http://103.10.86.30:8080/;
需要将上面的反向代理改为：
proxy_pass http://103.10.86.30:8080;
也就是说代理后的url后面不能加"/"，这个细节在前期配置的时候没有注意啊！！

gerrit.conf最后完整配置如下：

```
[root@localhost vhosts]``# pwd``/usr/local/nginx/conf/vhosts``[root@localhost vhosts]``# cat gerrit.conf``server {``listen 80;``server_name localhost;` `#charset koi8-r;``  ``#access_log /var/log/nginx/log/host.access.log main;``location / {``     ``auth_basic       ``"Gerrit Code Review"``;``     ``auth_basic_user_file  ``/home/gerrit/gerrit_site/etc/passwords``;``     ``proxy_pass       http:``//103``.10.86.30:8080;``     ``proxy_set_header    X-Forwarded-For $remote_addr;``     ``proxy_set_header    Host $host;``  ``}``}` `[root@localhost vhosts]``# /usr/local/nginx/sbin/nginx -s reload
```

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160721151659404-1784482953.png)

对比代码在review前后的状态：修改了哪些内容（右边部分是review修改后的代码状态。点击右边"Patch Set 1"后面的图标，可以下载或修改代码）

![img](https://images2015.cnblogs.com/blog/907596/201607/907596-20160721151720451-716564317.png)

\-------------------------------------------------------------------------------------------------------------
以上部署环境中，有一个不安全的地方，就是用户提交代码后，自己对代码都有review最终审核权限，即"用户自己review提交审核-自己+1/+2审核-自己submit"，这样设计不是很合理！
现在做下调整：
用户自己review提交代码后，自己只有Code-Review +2的权限和Submit，Verfied +1的权限统一交由专门的审核人员去处理，比如teamleader组。
这样，代码审核的过程：
1）用户自己review提交代码审核
2）teamleader组内人员收到审核后，通过Verfied +1审核
3) 用户自己通过Code-Review +2审核
4）用户自己Submit提交，Merged合并处理。
具体的权限设置调整如下：

![img](https://images2015.cnblogs.com/blog/907596/201610/907596-20161025143332640-1150193650.png)

\----------------------------------------------------------------------------------------------------------------------------------
有一个问题：
如果给某个账号开了push权限，他在代码commit提交后，就可以直接git push上传到gerrit里面，可以不经过git review审核提交的代码。如下授权截图：

![img](https://images2015.cnblogs.com/blog/907596/201611/907596-20161122211033831-1197437768.png)

但是这样直接git push的话，在gerrit界面的Merged处就追踪不到这个账号提交代码的记录了，也就是说，只有经过review审核提交的代码记录才能在gerrit界面的Merged下追踪到!如下：

![img](https://images2015.cnblogs.com/blog/907596/201611/907596-20161117162329388-659239619.png)

 

如上所说，那么直接push提交代码的记录该怎么追踪到呢？
莫慌！
其实不管是push直接提交代码的记录，还是经过review审核提交的代码记录，都可以在gitweb的log里追踪到的！

![img](https://images2015.cnblogs.com/blog/907596/201611/907596-20161117163038779-1098935905.png)

 ![img](https://images2015.cnblogs.com/blog/907596/201611/907596-20161117163624685-1731204532.png)

![img](https://images2015.cnblogs.com/blog/907596/201611/907596-20161117163149154-453544071.png)

虽然授权了push权限，但是也还是可以使用git review命令进行审核的，这样在gerrit界面的Merged里也能追踪到提交记录了。
如果是直接git push的，那么提交代码的时候就会直接绕过review审核了，这样当然不会在gerrit的Merged里留有记录。