- [Superset部署-超详细！](https://blog.51cto.com/gcherforever/4594276)

# 1. 概述

Apache Superset是一个开源的、现代的、轻量级BI分析工具，拥有丰富的图表展示形式、支持自定义仪表盘，能够对接多种数据源、且拥有友好的用户界面，十分好用。

# 2. 应用场景

由于Superset能够对接常用的大数据分析工具，如Hive、Kylin、Impala、Druid、mysql等，且支持自定义仪表盘，故可作为数仓的可视化工具。
![16369439821.png](https://s2.51cto.com/images/20211115/1636944012773627.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)

# 3. 安装及使用

[点击访问官网地址](http://superset.apache.org/)

## 3.1 环境要求

Superset是由Python语言编写的Web应用，要求Python3.7的环境。

## 3.2 安装Miniconda

为了不影响系统本身的python环境，本次部署选择conda，conda是一个开源的包、环境管理器，可以用于在同一个机器上安装不同Python版本的软件包及其依赖，并能够在不同的Python环境之间切换，Anaconda包括Conda、Python以及一大堆安装好的工具包，比如：numpy、pandas等，Miniconda包括Conda、Python。
此处，我们不需要如此多的工具包，故选择MiniConda。

1. 下载Miniconda
   下载地址：https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh

2. 安装Miniconda(普通用户安装)
   新建test用户，用普通用户安装部署
   [root@node02 ~]# useradd test
   [test@node02 opt]$ wget 
   https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
   执行以下命令进行安装，并按照提示操作，直到安装完成。
   [test@node02 opt]$ bash Miniconda3-latest-Linux-x86_64.sh

3. 在安装过程中，出现以下提示时，回车键继续

   ```bash
   [test@node02 ~]$ bash Miniconda3-latest-Linux-x86_64.sh
   Welcome to Miniconda3 py39_4.10.3
   In order to continue the installation process, please review the license
   agreement.
   Please, press ENTER to continue
   >>>
   ...
   Miscellaneous
   =============
   --More--
   ```

   输入yes

   ```bash
   Do you accept the license terms? [yes|no]
   >>>
   ```

   出现以下提示时，可以指定安装路径，不指定默认/home/test/miniconda3

   ```bash
   Miniconda3 will now be installed into this location:
   /home/test/miniconda3
   - Press ENTER to confirm the location
   - Press CTRL-C to abort the installation
   - Or specify a different location below
   [/home/test/miniconda3] >>>
   ```

4. 初始化，yes

   ```bash
   Preparing transaction: done
   Executing transaction: done
   installation finished.
   Do you wish the installer to initialize Miniconda3
   by running conda init? [yes|no]
   [no] >>>
   ```

5. 出现以下字样，即为安装完成

   ```bash
   conda config --set auto_activate_base false
   Thank you for installing Miniconda3!
   ```

   ## 3.3 加载环境变量，使之生效

   ```bash
   [test@node02 opt]$ source ~/.bashrc
   （base）[test@node02 opt]$ 
   ```

   ## 3.4 取消激活base环境

   Miniconda安装完成后，每次打开终端都会激活其默认的base环境，我们可通过以下命令，禁止激活默认base环境。

   ```bash
   [test@node02 opt]$ conda config --set auto_activate_base false
   ```

   ## 3.5 创建Python3.7环境

   ### 3.5.1 配置conda国内镜像

   ```bash
   (base) [test@node02 ~]$ conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free
   (base) [test@node02 ~]$ conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main
   (base) [test@node02 ~]$ conda config --set show_channel_urls yes
   ```

   ### 3.5.2 创建Python3.7环境

   ```bash
   (base) [test@node02 ~]$ conda create --name superset python=3.7
   ```

   说明：conda环境管理常用命令
   创建环境：conda create -n env_name
   查看所有环境：conda info --envs
   删除一个环境：conda remove -n env_name --all
   \###3.5.3 激活superset环境

   ```bash
   (base) [test@node02 ~]$ conda activate superset
   ```

   激活后效果如下所示:

   ```bash
   (superset) [test@node02 ~]$ 
   ```

   说明：退出当前环境

   ```bash
   (superset) [test@node02 ~]$ conda deactivate
   ```

   ### 3.5.4 查看python版本

   ```bash
   (superset) [test@node02 ~]$ python
   Python 3.7.11 (default, Jul 27 2021, 14:32:16)
   [GCC 7.5.0] :: Anaconda, Inc. on linux
   Type "help", "copyright", "credits" or "license" for more information.
   >>>
   ```

   # 4. Superset部署

   ## 4.1 安装依赖

   安装Superset之前，需安装以下所需依赖

   ```bash
   (superset) [test@node02 ~]$ sudo yum install -y gcc gcc-c++ libffi-devel python-devel python-pip python-wheel python-setuptools openssl-devel cyrus-sasl-devel openldap-devel
   ```

   ## 4.2 安装Superset

6. 安装（更新）setuptools和pip

   ```bash
   (superset) [test@node02 ~]$ pip install --upgrade setuptools pip -i https://pypi.douban.com/simple/
   ```

   说明：pip是python的包管理工具，可以和centos中的yum类比

7. 安装Supetset

   ```bash
   (superset) [test@node02 ~]$ pip install apache-superset -i https://pypi.douban.com/simple/
   ```

   说明：-i的作用是指定镜像，这里选择国内镜像
   如果遇到网络错误导致不能下载，可尝试更换镜像

8. 初始化Supetset数据库

   ```bash
   (superset) [test@node02 ~]$ superset db upgrade
   ```

9. 创建管理员用户

   ```bash
   (superset) [test@node02 ~]$ export FLASK_APP=superset
   (superset) [test@node02 ~]$ superset fab create-admin
   ```

   说明：flask是一个python web框架，Superset使用的就是flask

10. Superset初始化

    ```bash
    (superset) [test@node02 ~]$ superset init
    ```

    # 5. 启动Supterset

11. 安装gunicorn

    ```bash
    (superset) [test@node02 ~]$ pip install gunicorn -i https://pypi.douban.com/simple/
    ```

    说明：gunicorn是一个Python Web Server，可以和java中的TomCat类比

12. 启动Superset

    ```bash
    (superset) [test@node02 ~]$ gunicorn --workers 5 --timeout 120 --bind hadoop102:8787  "superset.app:create_app()" --daemon
    ```

    说明：
    --workers：指定进程个数
    --timeout：worker进程超时时间，超时会自动重启
    --bind：绑定本机地址，即为Superset访问地址
    --daemon：后台运行

13. 登录Superset
    访问http://node02:8787，并使用上面创建的管理员账号进行登录
    ![image.png](https://s2.51cto.com/images/20211115/1636947258898604.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)

14. 停止superset

    停掉所有的gunicorn进程

    ```bash
    (superset) [test@node02 ~]$ ps -ef | awk '/superset/ && !/awk/{print $2}' | xargs kill -9
    ```

    # 6. superset启停脚本

    ## 6.1 创建脚本

    ```bash
    [test@node02 ~]$ vim superset.sh
    #!/bin/bash
    superset_status(){
    result=`ps -ef | awk '/gunicorn/ && !/awk/{print $2}' | wc -l`
    if [[ $result -eq 0 ]]; then
    return 0
    else
    return 1
    fi
    }
    superset_start(){
    source ~/.bashrc
    superset_status >/dev/null 2>&1
    if [[ $? -eq 0 ]]; then
    conda activate superset ; gunicorn --workers 5 --timeout 120 --bind hadoop102:8787 --daemon 'superset.app:create_app()'
    else
    echo "superset正在运行"
    fi
    
    }
    superset_stop(){
    superset_status >/dev/null 2>&1
    if [[ $? -eq 0 ]]; then
    echo "superset未在运行"
    else
    ps -ef | awk '/gunicorn/ && !/awk/{print $2}' | xargs kill -9
    fi
    }
    
    case $1 in
    start )
    echo "启动Superset"
    superset_start
    ;;
    stop )
    echo "停止Superset"
    superset_stop
    ;;
    restart )
    echo "重启Superset"
    superset_stop
    superset_start
    ;;
    status )
    superset_status >/dev/null 2>&1
    if [[ $? -eq 0 ]]; then
    echo "superset未在运行"
    else
    echo "superset正在运行"
    fi
    esac
    ```

## 6.2 添加执行权限
```bash
[test@node02 ~]$ chmod +x superset.sh
```

## 6.3 启停命令

```bash
[test@node02 ~]$ superset.sh start
[test@node02 ~]$ superset.sh stop
[test@node02 ~]$ superset.sh status
[test@node02 ~]$ superset.sh restart
```

# 7. 数据源插件

官网查询支持的数据源列表: https://superset.apache.org/docs/databases/installing-database-drivers
![image.png](https://s2.51cto.com/images/20211115/1636953502725427.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)

安装命令：

```bash
(superset)[test@node02 ~]$ conda install mysqlclient
```

其它插件可查询官网安装