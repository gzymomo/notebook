- [Ubuntu16桌面版编译OpenCV4的java库和so库](https://www.cnblogs.com/bolingcavalry/p/15816304.html)

### 本篇概览

- 作为一名java程序员，如果想在Ubuntu16桌面版上使用OpenCV4的服务，可以下载自己所需版本的OpenCV源码，然后自己动手编译java库和so库，这样就可以在java程序中使用了
- 本文详细记录OpenCV4的下载和编译过程，然后写一个java程序验证是否可以成功调用OpenCV4的库，总的来说分为以下几步：

1. 安装必要应用
2. 配置java环境
3. 配置ANT环境
4. 下载源码
5. 编译前的配置
6. 编译
7. 安装
8. 验证

- 注意：**本文的操作全部以非root账号执行**

### 环境和版本

1. 操作系统：16.04.7 LTS（桌面版）
2. java：1.8.0_311
3. ANT：1.9.16
4. OpenCV：4.1.1

- 接下来开始操作，我这里是个新装的纯净版Ubuntu16

### 安装应用

- 执行以下命令安装所有应用，如果有个别提示失败的可以多试几次：

```shell
sudo apt-get install -y unzip build-essential curl cmake cmake-gui git libgtk2.0-dev pkg-config libavcodec-dev libavformat-dev libswscale-dev python-dev python-numpy libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev libjasper-dev libdc1394-22-dev
```

### 配置java环境

- 下载JDK8，解压后是名为jdk1.8.0_311的文件夹，将该文件夹移动到这个目录下面：/usr/lib/jvm/
- 打开文件~/.bashrc，添加以下内容：

```shell
export JAVA_HOME=/usr/lib/jvm/jdk1.8.0_311
export JRE_HOME=${JAVA_HOME}/jre
export CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib
export PATH=${JAVA_HOME}/bin:$PATH
```

### 配置ANT

- 下载ANT，地址是：https://dlcdn.apache.org//ant/binaries/apache-ant-1.9.16-bin.tar.gz
- 解压后是名为apache-ant-1.9.16的文件夹，将该文件夹移动到这个目录下面：/usr/local/
- 打开文件~/.bashrc，添加以下内容：

```shell
export ANT_HOME=/usr/local/apache-ant-1.9.16
export PATH=$ANT_HOME/bin:$PATH
```

- 执行命令source ~/.bashrc
- 检查java和ANT安装是否完成：

```shell
will@hp:~$ java -version
java version "1.8.0_311"
Java(TM) SE Runtime Environment (build 1.8.0_311-b11)
Java HotSpot(TM) 64-Bit Server VM (build 25.311-b11, mixed mode)
will@hp:~$ ant -version
Apache Ant(TM) version 1.9.16 compiled on July 10 2021
```

### 下载源码

- 执行以下命令即可：

```shell
curl -fL -o opencv-4.1.1.zip https://codeload.github.com/opencv/opencv/zip/4.1.1; \
unzip opencv-4.1.1.zip; \
rm -rf opencv-4.1.1.zip; \
mkdir opencv-4.1.1/build; \
mkdir opencv-4.1.1/build/install
```

### 编译前的配置

- 进入目录**opencv-4.1.1/build/**
- 执行cmake，生成配置信息：

```shell
cmake -D CMAKE_BUILD_TYPE=Release -D BUILD_SHARED_LIBS=OFF -D CMAKE_INSTALL_PREFIX=./install ..
```

- 要注意的是，上面的-D BUILD_SHARED_LIBS=OFF参数十分重要！没有该参数时生成的libopencv_java411.so大小只有1532128，有了该参数libopencv_java411.so大小是78169672
- 上述命令执行完毕后，请检查控制台输出的信息，如下图所示，"java"必须出现在To be build的栏目中，否则正式编译时不会编译java相关的库：

![在这里插入图片描述](https://img2020.cnblogs.com/other/485422/202201/485422-20220118085719343-1659437072.png)

- 以下是部分配置成功的输出信息，用于参考：

```shell
--   Python (for build):            /usr/bin/python2.7
-- 
--   Java:                          
--     ant:                         /usr/local/apache-ant-1.9.16/bin/ant (ver 1.9.16)
--     JNI:                         /usr/lib/jvm/jdk1.8.0_311/include /usr/lib/jvm/jdk1.8.0_311/include/linux /usr/lib/jvm/jdk1.8.0_311/include
--     Java wrappers:               YES
--     Java tests:                  YES
-- 
--   Install to:                    /home/will/temp/202110/30/003/opencv-4.1.1/build/install
-- -----------------------------------------------------------------
-- 
-- Configuring done
-- Generating done
-- Build files have been written to: /home/will/temp/202110/30/003/opencv-4.1.1/build
```

### 编译

- 在**opencv-4.1.1/build/**目录执行以下命令即可开始编译源码，参数-j6表示六个线程并行编译（我的电脑是6核CPU，您请酌情处理）：

```shell
make -j6
```

- CPU迅速上涨了：

![在这里插入图片描述](https://img2020.cnblogs.com/other/485422/202201/485422-20220118085721424-524216857.png)

- 我这里大约10分钟不到，完成编译

### 安装

- 在执行cmake命令的时候，已经用CMAKE_INSTALL_PREFIX=./install参数指定了安装目录在opencv-4.1.1/build/install，现在执行安装命令就会将OpenCV的库安装到这个目录下
- 执行安装命令make install，如果控制台没有error相关的信息，就算安装成功了
- 进入install目录看看，里面有四个目录：

```shell
bin  include  lib  share
```

- 进入目录opencv-4.1.1/build/install/share/java/opencv4，里面已经生成了我们需要的jar和so库：

```shell
opencv4/
├── libopencv_java411.so
└── opencv-411.jar
```

### 验证

- 终于，文件已经准备好了，接下来写一个java应用验证OpenCV库能否正常使用
- 我这里用的是IDEA，新建一个java工程，名为opencv-demo
- 依赖本地jar，设置方法如下：

![在这里插入图片描述](https://img2020.cnblogs.com/other/485422/202201/485422-20220118085721713-107638614.png)

- 选中刚才生成的opencv-411.jar

![在这里插入图片描述](https://img2020.cnblogs.com/other/485422/202201/485422-20220118085722007-1007424619.png)

- 新建Main.java文件，如下所示，功能是新建窗口展示本地图片，请自行准备图片并修改为合适的位置：

```java
package com.company;

import org.opencv.core.Core;
import org.opencv.core.Mat;
import static org.opencv.highgui.HighGui.*;
import static org.opencv.imgcodecs.Imgcodecs.imread;

public class Main {

    public static void main(String[] args) {
        System.loadLibrary(Core.NATIVE_LIBRARY_NAME);

        Mat mat = imread("/home/will/temp/202110/30/pics/111.png");

        if(mat.empty()) {
            System.out.println("Image not exists!");
            return;
        }

        namedWindow("src", WINDOW_AUTOSIZE);
        imshow("src", mat);

        waitKey(0);
        
        // 这一句很重要，否则按下任意键后看不到窗口关闭的效果
        System.exit(0);
    }
}
```

- 最后，也是非常重要的一步，就是指定so库的位置，点击下图红框处：

![在这里插入图片描述](https://img2020.cnblogs.com/other/485422/202201/485422-20220118085722418-1223144406.png)

- 增加一个VM Options参数java.library.path，值就是刚才创建的libopencv_java411.so所在目录，如下图红框所示：

![在这里插入图片描述](https://img2020.cnblogs.com/other/485422/202201/485422-20220118085722763-1959440901.png)

- 设置完成后运行Main.java，得到结果如下，左侧就是显示本地图片的窗口：

![在这里插入图片描述](https://img2020.cnblogs.com/other/485422/202201/485422-20220118085723752-395441856.png)

- 至此，OpenCV的java库和so库的生成和验证就完成了，如果您也是使用OpenCV的java程序员，希望本文能为您带来一些参考；
   https://github.com/zq2599/blog_demos