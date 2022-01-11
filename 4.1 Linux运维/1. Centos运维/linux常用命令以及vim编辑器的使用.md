- [linux常用命令以及vim编辑器的使用](https://blog.csdn.net/weixin_42146017/article/details/104395767)

## 前言

本文提到的的命令都是在Linux终端下使用的，也就是所谓的黑窗口。正常打开Linux系统是有界面的，也可以通过鼠标像在Windows上操作那样进行点击图标，新建文件等操作。所以想使用终端得另外打开，`Ctrl + Alt + T`和`Ctrl + D`是两个常用的打开和关闭终端的快捷键方式。

### 1．Linux常用命令

#### 1.1 使用频率较高的命令

```shell
ifconfig  #查看IP地址，可以利用该地址让Linux主机被远程控
#通过sudo（“超级用户执行”）命令，你可以临时以root用户身份运行其他命令。这是大多数用户运行root权限命令的最佳方式，因为这样既不用维护root帐户，也不需要知道root用户密码。只要输入自己的用户密码，就能获得临时的root权限。
chen@chen-virtual-machine:~$ sudo apt-get update #更新软件列表。
[sudo] chen 的密码：xxx #正常输入密码的时候是不会显示的

#其他类似的命令还有
sudo apt-get install xxx     #安装XXX软件。
sudo apt-get upgrade       #更新已安装软件。
sudo apt-get remove xxx   #删除XXX软件。
##永久获得root用户身份
chen@chen-virtual-machine:~$ su -  
#chen是用户名;注意':'后面'$';命令是‘SU -’
密码： xxx 
#正常输入密码的时候是不会显示的
root@chen-virtual-machine:~#  
#root是指此时已经获得了root权限；注意':'后面'#' 
```

#### 1.2 Linux文件与目录管理

我们知道Linux的目录结构为树状结构，最顶级的目录为根目录 /。![UTOOLS1568095409505.png](https://imgconvert.csdnimg.cn/aHR0cDovL3lhbnh1YW4ubm9zZG4uMTI3Lm5ldC8xZjAxOTAwZGUzNTdjNWRmZjZjMjIxNDZmMzMzNzkyYS5wbmc?x-oss-process=image/format,png)

上图是根目录下的一些目录，其中最常用的是home目录。

##### 1.2.1目录和路径

##### 1）相对路径和绝对路径

- **绝对路径**：路径的写法，一定由根目录 / 写起，例如： /home/chen/test1 这个目录。

  ```shell
  #以绝对路径进入test1目录
  root@chen-virtual-machine:~# cd /home/chen/test2/test1 
  root@chen-virtual-machine:/home/chen/test2/test1#  
  ```

- **相对路径**：路径的写法，不是由 根目录/ 写起，例如由/home/chen/test1 要到 /home/chen/test2 底下时，可以写成： cd …/test2 。

  ```shell
  root@chen-virtual-machine:/home/chen# cd test1  #首先进入test1目录
  root@chen-virtual-machine:/home/chen/test1# cd ../test2  #其次进入test2目录
  root@chen-virtual-machine:/home/chen/test2# 
  ```

##### 2）目录的相关操作

cd：切换目录

```shell
1.root@chen-virtual-machine:~# cd ~chen
root@chen-virtual-machine:/home/chen#   
#代表进入chen这个使用者的家目录，也就是/home/chen
root@chen-virtual-machine:/home/chen# ls
chen              test1   模板  文档  桌面
examples.desktop  test2   视频  下载
slambook          公共的  图片  音乐
#列出目录下的文件
2.root@chen-virtual-machine:/home/chen# cd ~
3.root@chen-virtual-machine:/home/chen# cd
#两个命令都表示回到自己家目录，也就是/root这个目录
root@chen-virtual-machine:~# ls
chen1  Tom
#列出目录下的文件
4.cd ..表示进入当前目录的上一层目录
5.cd - 表示进入当前目录的的前一个工作目录
```

pwd：显示当前目录cd

```shell
root@chen-virtual-machine:/# cd /var/mail
root@chen-virtual-machine:/var/mail# pwd
/var/mail
#列出目前的工作目录
root@chen-virtual-machine:/var/mail# pwd -P
/var/spool/mail
#/var/mail/是链接文件，链接到/var/spool/mail，加上-P的选项后，不会显示链接文件(快捷方式)的路径，而是显示正确的完整路径
#P为大写
```

mkdir：建立一个新的目录

```shell
root@chen-virtual-machine:/home/chen# mkdir  test3
#创建一名为test3的新目录
root@chen-virtual-machine:/home/chen# mkdir test4/test1/test2
mkdir: 无法创建目录"test4/test1/test2": 没有那个文件或目录
#本来没有test4/test1这些目录，所以无法创建test2这个目录
root@chen-virtual-machine:/home/chen# mkdir -p test4/test1/test2
#加上-p的选项后，先创建test4/test1这些目录，然后再创建test2这个目录
#p为小写
```

rmdir：删除一个空目录

```shell
root@chen-virtual-machine:/home/chen# rmdir  test3
#删除一名为test3的目录
root@chen-virtual-machine:/home/chen# rmdir  test4
rmdir: 删除 'test4' 失败: 目录非空
root@chen-virtual-machine:/home/chen# rmdir  -p test4/test1/test2
#加上-p的选项后，可以直接删除test4目录下的所有空目录，非空目录删不掉
root@chen-virtual-machine:/home/chen# rm -r test4
#也可以使用rm -r 删除test4下的所有内容，可以非空
```

##### 1.2.2 文件与目录管理

##### 1）ls

```shell
1.root@chen-virtual-machine:/home# cd chen
2.root@chen-virtual-machine:/home/chen# cd ~chen
3.root@chen-virtual-machine:/home/chen# ls
chen              slambook  test2   模板  图片  下载  桌面
examples.desktop  test1     公共的  视频  文档  音乐
4.root@chen-virtual-machine:/home/chen# ls -d
.
#仅列出目录本身，而不是列出目录内的文件数据
5.root@chen-virtual-machine:/home/chen# ls -l
总用量 60
drwxrwxr-x 2 chen chen 4096 9月  10 16:36 chen
-rw-r--r-- 1 chen chen 8980 4月  20 15:05 examples.desktop
drwxrwxr-x 3 chen chen 4096 5月  23 12:52 slambook
drwxr-xr-x 2 root root 4096 9月  10 14:33 test1
drwxr-xr-x 4 root root 4096 9月  10 14:39 test2
drwxr-xr-x 2 chen chen 4096 4月  20 15:23 公共的
drwxr-xr-x 2 chen chen 4096 4月  20 15:23 模板
drwxr-xr-x 2 chen chen 4096 4月  20 15:23 视频
drwxr-xr-x 2 chen chen 4096 4月  20 15:23 图片
drwxr-xr-x 2 chen chen 4096 4月  20 15:23 文档
drwxr-xr-x 2 chen chen 4096 4月  20 15:23 下载
drwxr-xr-x 2 chen chen 4096 4月  20 15:23 音乐
drwxr-xr-x 3 chen chen 4096 5月  23 10:11 桌面
#详细信息显示，包含文件的属性与权限等数据
6.root@chen-virtual-machine:/home/chen# ls -a
.                   .cache            .local                     test1         视频
..                  chen              .mozilla                   test2         图片
.apport-ignore.xml  .config           .profile                   .thunderbird  文档
.bash_history       examples.desktop  slambook                   .viminfo      下载
.bash_logout        .gnupg            .subversion                公共的        音乐
.bashrc             .ICEauthority     .sudo_as_admin_successful  模板          桌面
#全部的文件，连同隐藏文件（开头为.的文件）一起列出来
```

##### 2）cp:复制文件或目录

```shell
1.root@chen-virtual-machine:/home/chen# cp /home/chen/test/a.py /home/chen/test1
#将a.py文件拷贝到test1目录下
2.root@chen-virtual-machine:/home/chen# cp -i /home/chen/test/a.py /home/chen/test1
cp：是否覆盖'/home/chen/test1/a.py'？ y
root@chen-virtual-machine:/home/chen#
#加上-i选项后，则在覆盖前会询问使用者是否确定，可以按下n或y来二次确认
3.root@chen-virtual-machine:/home/chen/test# cd ~chen/test1
root@chen-virtual-machine:/home/chen/test1# cp /home/chen/test/b.py .
#先进入想要将文件拷贝到的目录，然后再将其他目录的文件拷贝进来，注意最后的小点。
root@chen-virtual-machine:/home/chen/test1# ls -l /home/chen/test/b.py b.py
-rw-r--r-- 1 root root 0 9月  12 21:07 b.py
-rw-r--r-- 1 root root 0 9月  12 21:06 /home/chen/test/b.py
#这个时候原文件和拷贝文件的属性、权限可能会有差异。
4.root@chen-virtual-machine:/home/chen/test1# cp -a /home/chen/test/b.py .
root@chen-virtual-machine:/home/chen/test1# ls -l /home/chen/test/b.py b.py
-rw-r--r-- 1 root root 0 9月  12 21:06 b.py
-rw-r--r-- 1 root root 0 9月  12 21:06 /home/chen/test/b.py
#加上-a选项，即将文件的所有特性都复制过来了。
5.root@chen-virtual-machine:/home/chen/test1# cp -r /home/chen/test /home/chen/test1
root@chen-virtual-machine:/home/chen/test1# ls
test
#加上-r选项，可以复制目录。但是文件与目录的权限可能会改变，随意一般还会加上-a选项，尤其是在备份的情况下
```

##### 3) rm:删除文件或目录

```shell
1.root@chen-virtual-machine:/home/chen/test1/test# rm a.py
#直接删除a.py文件
root@chen-virtual-machine:/home/chen/test1/test# ls
b.py
2.root@chen-virtual-machine:/home/chen/test1/test# rm -i b.py
rm：是否删除普通空文件 'b.py'？ y
#加上-a选项就会主动询问，避免你删除到错误的文件名
3.root@chen-virtual-machine:/home/chen/test1/test# cd ..
root@chen-virtual-machine:/home/chen/test1# ls
test
root@chen-virtual-machine:/home/chen/test1# rm -r test
#加上-r选项就可以删除目录
```

##### 4) mv：移动文件或目录

```shell
1、root@chen-virtual-machine:/home/chen/test1# mv /home/chen/test/a.py /home/chen/test1
root@chen-virtual-machine:/home/chen/test1# ls
a.py
#直接移动
2、root@chen-virtual-machine:/home/chen/test1# mv a.py b.py
root@chen-virtual-machine:/home/chen/test1# ls
b.py
#重命名
3.root@chen-virtual-machine:/home/chen/test# mv -i /home/chen/test/a.py /home/chen/test1
root@chen-virtual-machine:/home/chen/test# cd ~chen/test1
root@chen-virtual-machine:/home/chen/test1# ls
a.py  b.py
#加上-i选项就可以询问是否覆盖已经存在的目标文件
```

##### 1.2.3Linux 文件内容查看

Linux系统中使用以下命令来查看文件的内容：

1）cat 由第一行开始显示文件内容

```shell
cat -A #可以将文件的内容完整的显示出来（包含如换行和[Tab]之类的特殊字符）
cat -b #列出行号，仅针对非空白行号显示，空白行不标行号
cat -n#打印出行号，连同空白也会有行号，与-b的选项不同
```

2）tac 从最后一行开始显示，可以看出 tac 是 cat 的倒着写

3） nl 显示的时候，同时输出行号

```shell
1.nl -b  #指定行号指定的方式，主要有两种：
nl -b a  #表示不论是否为空行，也同样列出行号(类似 cat -n)；
nl -b t  #如果有空行，空的那一行不要列出行号(默认值)；
2.nl -n rz  #行号在自己栏位的最右方显示，且加 0 ；
root@chen-virtual-machine:/home/chen/test1# nl -b a -n rz b.py
000001  print("hello.world:")
000002
000003  print（“I love python”）
#自动补零，默认6位
3.nl -w #行号栏位的占用的字符数
root@chen-virtual-machine:/home/chen/test1# nl -b a -n rz -w 3 b.py
001     print("hello.world:")
002
003     print（“I love python”）
#变成仅有三位数
```

4）more 一页一页地显示文件内容

```shell
1.root@chen-virtual-machine:/home/chen/slambook/slambook/ch10/ceres_custombundle# more ceresBundle.cpp
#打开.cpp文件
#include <iostream>
#include <fstream>
#include "ceres/ceres.h"

#include "SnavelyReprojectionError.h"
#include "common/BALProblem.h"
#include "common/BundleParams.h"


using namespace ceres;

void SetLinearSolver(ceres::Solver::Options* options, const BundleParams& params)
{
    CHECK(ceres::StringToLinearSolverType(params.linear_solver, &options->linear_solver_type))
;
    CHECK(ceres::StringToSparseLinearAlgebraLibraryType(params.sparse_linear_algebra_library, 
&options->sparse_linear_algebra_library_type));
    CHECK(ceres::StringToDenseLinearAlgebraLibraryType(params.dense_linear_algebra_library, &o
ptions->dense_linear_algebra_library_type));
    options->num_linear_solver_threads = params.num_threads;

}
。。。。（中间省略）。。。。
--更多--(19%) <== 光标会在这里等待你的命令
2.空白键 (space)：代表向下翻一页；
3.Enter：代表向下翻『一行』；
4./字串：代表在这个显示的内容当中，向下搜寻『字串』这个关键字；
5.q：代表立刻离开 more ，不再显示该文件内容。
```

5）less 与 more 类似，但是比 more 更好的是，它可以往前翻页

- less + 文件名
- 空白键：向下翻动一页；
- [pagedown]：向下翻动一页；
- [pageup]：向上翻动一页；
- /字串：向下搜寻『字串』的功能；
- ?字串：向上搜寻『字串』的功能；

6） head 只看头几行

```shell
1.head -n number 文件
#显示文件的前面number行
2.head -n -number 文件
#显示前面所有行，但不包括后面number行
```

7）tail 只看尾巴几行

```shell
1.tail -n number 文件
#显示文件的最后的number行
2.tail -f 文件
#表示持续侦测后面所接的文件（可能有新的数据一直写入），要等到按下[ctrl]-c才会结束tail的侦测
```

以上都是针对现有存在文件，假如要创建一个新的空文件就需要用到touch命令

```shell
touch 文件
```

#### 1.3 文件与文件系统的压缩

##### 1.3.1解压缩目录：tar

tar可以将多个目录或文件打包成一个大文件，同时可以通过gzi、bzip2、xz的支持，将该文件同时进行压缩。

```shell
1.压缩：tar –zcvf  filename.tar.gz dirname
解压：tar –zxvf filename.tar.gz
#通过gzip的支持进行压缩/解压缩：此时文件名最好是*.tar.gz
2.压缩：tar –jcvf  filename.tar.bz2 dirname
解压：tar –jxvf filename.tar.bz2
#通过bzip2的支持进行压缩/解压缩：此时文件名最好是*.tar.bz2
3.压缩：tar –Jcvf  filename.tar.xz dirname
解压：tar –Jxvf filename.tar.xz
#通过xz的支持进行压缩/解压缩：此时文件名最好是*.tar.xz
```

> 更多有关linux命令的教程：http://www.runoob.com/linux/linux-command-manual.html

### 2．Vim编辑器及其配置

除了查看文件内容外，我们还需要对文件中的内容进行编辑。Linux自带的编辑器有nano和vi，但vi编辑器使用起来很不方便，我们需要先下载vim编辑器，它是vi编辑器的升级版，更人性化些。

#### 2.1vim的安装和使用

1)首先更新索引源：

```shell
sudo apt-get update 
```

2)安装vim编辑器:

```shell
sudo apt-get install vim
```

3）打开文件、保存、关闭文件（vim命令模式下使用）

- vi filename #打开filename文件，此时是命令模式
- w #保存文件
- q #退出编辑器，如果文件已修改请使用下面的命令
- q! #退出编辑器，且不保存
- wq # 退出编辑器，且保存文件

![UTOOLS1568303674391.png](https://imgconvert.csdnimg.cn/aHR0cDovL3lhbnh1YW4ubm9zZG4uMTI3Lm5ldC81NmIxZGU3OTc5NGFmYjFmNGZjMzA1Y2U0MzFiYzk1OS5wbmc?x-oss-process=image/format,png)

4）插入文本或行(vim命令模式下使用，执行下面命令后将进入插入模式，按ESC键可退出插入模式)

- a #在当前光标位置的右边添加文本
- i #在当前光标位置的左边添加文本
- A #在当前行的末尾位置添加文本
- I #在当前行的开始处添加文本(非空字符的行首)
- O #在当前行的上面新建一行
- o #在当前行的下面新建一行
- R #替换(覆盖)当前光标位置及后面的若干文本
- J #合并光标所在行及下一行为一行(依然在命令模式)

1. 设置行号(vim命令模式下使用)

- set nu #显示行号
- set nonu #取消显示行号

6)注意vim命令模式下，想要输入命令，得先输入“：”。

#### 2.2 vim编辑器显示高亮

未配置vim时文档的显示无高亮，无行号，体验极差，为了增加高亮，改善体验。

1）我们可以先用SecureFx将《三个工具实现PC端远程连接、桌面共享和文件传输》一文百度文分享链接中的vimconfig.tar.gz传送到`/home/用户名/`目录下

![Snipaste_2019-05-20_13-02-29.png](https://imgconvert.csdnimg.cn/aHR0cDovL3lhbnh1YW4ubm9zZG4uMTI3Lm5ldC84YzdmNDY1Zjc1MjlmY2ZhMDMxMWYyZjEyYjMzMzFlNy5wbmc?x-oss-process=image/format,png)

2）在命令行模式下输入`tar xvf vimconfig.tar.gz` 解压压缩包

3）进入`vimconfig`目录中运行`config.sh`脚本

![Snipaste_2019-05-20_13-05-49.png](https://imgconvert.csdnimg.cn/aHR0cDovL3lhbnh1YW4ubm9zZG4uMTI3Lm5ldC9hZjViY2YwYjE4YTA2MWUyZTFlNjBlMzRlZTNkZmIyZC5wbmc?x-oss-process=image/format,png)

4）可能会报错，我们需要输入命令`sudo /home/mrchen/.vim /home/mrchen/.vimrc`,然后再运行`./config.sh`,然后再运行`apt-get install ctags`。

> 上面命令就是在/home/用户名/目录下新建.vim文件和.vimrc文件。
>
> 然后在加载ctags包。

5）最后，disconnet然后重新连接登陆就可以了，然后再用vim打开文本文件，即可打开新世界。

![Snipaste_2019-05-20_13-18-24.png](https://imgconvert.csdnimg.cn/aHR0cDovL3lhbnh1YW4ubm9zZG4uMTI3Lm5ldC9jODA1YzM3M2RmNDFkY2IzZjc0NjYxOGE2YTM0YTkzYy5wbmc?x-oss-process=image/format,png)
 