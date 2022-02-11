- [Ubuntu16桌面版编译和安装OpenCV4](https://www.cnblogs.com/bolingcavalry/p/15812030.html)

### 本篇概览

- 这是一篇笔记，记录了纯净的Ubuntu16桌面版电脑上编译、安装、使用OpenCV4的全部过程，总的来说分为以下几部分：

1. 安装必要软件，如cmake
2. 下载OpenCV源码，包括opencv和opencv_contrib，并且解压、摆好位置
3. 运行cmake-gui，在图形化页面上配置编译项
4. 编译、安装
5. 配置环境
6. 验证

### 环境

- 环境信息如下：

1. 操作系统：Ubuntu16.04桌面版
2. OpenCV：4.1.1

- 注意：**本文全程使用非root账号操作**
- 废话少说，直接在新装的Ubuntu16桌面版开始操作

### 换源

- 为了快速安装依赖软件，先把源换为国内的，我这里用的是阿里云
- 先备份源配置：

```shell
sudo cp /etc/apt/sources.list /etc/apt/sources.list.bk
```

-修改/etc/apt/sources.list为以下内容：

```shell
deb http://mirrors.aliyun.com/ubuntu/ xenial main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ xenial-security main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ xenial-updates main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ xenial-proposed main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ xenial-backports main restricted universe multiverse

deb-src http://mirrors.aliyun.com/ubuntu/ xenial main restricted universe multiverse

deb-src http://mirrors.aliyun.com/ubuntu/ xenial-security main restricted universe multiverse

deb-src http://mirrors.aliyun.com/ubuntu/ xenial-updates main restricted universe multiverse

deb-src http://mirrors.aliyun.com/ubuntu/ xenial-proposed main restricted universe multiverse

deb-src http://mirrors.aliyun.com/ubuntu/ xenial-backports main restricted universe multiverse
```

- 如果阿里云的源更新太慢，可以试试这个：

```shell
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ xenial main restricted
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ xenial-updates main restricted
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ xenial universe
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ xenial-updates universe
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ xenial multiverse
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ xenial-updates multiverse
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ xenial-backports main restricted universe multiverse
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ xenial-security main restricted
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ xenial-security universe
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ xenial-security multiverse
```

- 更新：

```shell
sudo apt-get update
```

### 安装应用

- 执行以下命令安装所有应用，如果有个别提示失败的可以多试几次：

```shell
sudo apt-get install -y unzip build-essential curl cmake cmake-gui git libgtk2.0-dev pkg-config libavcodec-dev libavformat-dev libswscale-dev python-dev python-numpy libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev libjasper-dev libdc1394-22-dev
```

### 下载源码

- 执行以下命令即可下载所有源码、解压、摆放到合适的位置：

```shell
curl -fL -o opencv-4.1.1.zip https://codeload.github.com/opencv/opencv/zip/4.1.1; \
unzip opencv-4.1.1.zip; \
rm -rf opencv-4.1.1.zip; \
curl -fL -o opencv_contrib-4.1.1.zip https://codeload.github.com/opencv/opencv_contrib/zip/refs/tags/4.1.1; \
unzip opencv_contrib-4.1.1.zip; \
rm -rf opencv_contrib-4.1.1.zip; \
mv opencv_contrib-4.1.1 opencv_contrib; \
mv opencv_contrib opencv-4.1.1/; \
mkdir opencv-4.1.1/build
```

### 用cmake-gui配置

- 在opencv-4.1.1目录下执行cmake-gui ..即可启动cmake-gui页面，开始图形化配置
- 我这里opencv-4.1.1文件夹的绝对路径是/home/will/opencv-4.1.1，所以下图红框1就是源码绝对路径，红框2是源码文件夹内的build子目录，配置完毕后，点击红框3开始初始化配置：

![在这里插入图片描述](https://img2020.cnblogs.com/other/485422/202201/485422-20220117073154692-349430130.png)

- 点击上图红框3中的按钮后，弹出的页面选择Unix Makefiles，然后开始配置：
- 此时出现了可以用来编辑的配置项，接下来开始配置：

![在这里插入图片描述](https://img2020.cnblogs.com/other/485422/202201/485422-20220117073158374-1588951402.png)

- 第一，选中BUILD_opencv_world：

![在这里插入图片描述](https://img2020.cnblogs.com/other/485422/202201/485422-20220117073201907-897946497.png)

- 第二，将CMAKE_BUILD_TYPE设置为Release

![在这里插入图片描述](https://img2020.cnblogs.com/other/485422/202201/485422-20220117073202509-1126777842.png)

- 第三，OPENCV_EXTRA_MODULES_PATH是个文件路径，这里选择/home/will/opencv-4.1.1/opencv_contrib/modules

![在这里插入图片描述](https://img2020.cnblogs.com/other/485422/202201/485422-20220117073203133-1191882440.png)

- 第四，选中OPENCV_GENERATE_PKGCONFIG

![在这里插入图片描述](https://img2020.cnblogs.com/other/485422/202201/485422-20220117073203698-645559391.png)

- 再次点击下图红框中的Configure按钮开始配置：

![在这里插入图片描述](https://img2020.cnblogs.com/other/485422/202201/485422-20220117073204349-410762562.png)

- 等配置完成后，点击下图红框中的Generate按钮开始生成配置项：

![在这里插入图片描述](https://img2020.cnblogs.com/other/485422/202201/485422-20220117073204883-1033667528.png)

- 等到出现下图红框中的提示，表示配置完成并且配置项已生成：

![在这里插入图片描述](https://img2020.cnblogs.com/other/485422/202201/485422-20220117073205352-1651184052.png)

- 至此已经完成了所有配置，请关闭cmake-gui，然后可以开始编译了

### 编译

- 进入目录opencv-4.1.1/build执行以下命令即可开始编译：

```shell
make -j8
```

- 眼见着CPU就上去了：

![在这里插入图片描述](https://img2020.cnblogs.com/other/485422/202201/485422-20220117073206492-2107310790.png)

- 执行sudo make install安装到当前系统中（注意要加sudo）
- 至此，安装完成，开始系统配置

### 系统配置

- 执行以下命令编辑文件（如果没有就创建）：

```shell
sudo vi /etc/ld.so.conf.d/opencv.conf
```

- 在打开的opencv.conf文件尾部增加以下内容：

```shell
/usr/local/lib
```

- 执行配置：

```shell
sudo ldconfig
```

- 执行以下命令编辑文件（如果没有就创建）：

```shell
sudo vi /etc/bash.bashrc
```

- 在打开的bash.bashrc文件尾部增加以下内容：

```shell
PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/usr/local/lib/pkgconfig  
export PKG_CONFIG_PATH
```

- 至此配置完成，退出控制台，再重新打开一个，执行命令pkg-config --modversion opencv4，注意是opencv4，可以看到opencv的版本号：

```shell
will@hp:~$ pkg-config --modversion opencv4
4.1.1
```

### 验证

- 接下来写个helloworld工程验证opencv可用
- 我这里用的是CLion来创建C++项目：

![在这里插入图片描述](https://img2020.cnblogs.com/other/485422/202201/485422-20220117073207048-1732157105.png)

- CMakeLists.txt内容如下，依赖了OpenCV的资源：

```shell
cmake_minimum_required(VERSION 3.20)
project(helloworld)

set(CMAKE_CXX_STANDARD 14)

find_package(OpenCV)
include_directories(${OpenCV_INCLUDE_DIRS})

add_executable(helloworld main.cpp)
target_link_libraries(helloworld ${OpenCV_LIBS})
```

- main.cpp如下，功能是读取本地图片，创建一个窗口展示这个图片：

```c
#include <iostream>
#include <opencv2/opencv.hpp>

using namespace std;
using namespace cv;

int main() {
    Mat mat = imread("/home/will/temp/202110/30/111.png");

    if(!mat.data) {
        cout<<"Image not exists!";
        return -1;
    }

    namedWindow("src", WINDOW_AUTOSIZE);
    imshow("[src]", mat);

    waitKey(0);
    return 0;
}
```

- 编译运行，如下图，本地图片显示成功：

![在这里插入图片描述](https://img2020.cnblogs.com/other/485422/202201/485422-20220117073208042-1347167395.png)

- 至此，在Ubuntu16桌面版编译、安装、设置、验证OpenCV4的实战就全部完成了；