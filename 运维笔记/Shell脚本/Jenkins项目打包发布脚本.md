[TOC]

# Jenkins项目打包发布脚本

```bash
#!/bin/bash

//传入的war包名称
name=$1 	
//war包所在目录							
path=$2
//上传的war包位置				
path_w=$3		
//如果项目正在运行就杀死进程
if [ -f "$path/$name" ];then
	echo "delete the file $name"
	rm -f  $path/$name
else
	echo "the file $name is not exist"
fi
//把jenkins上传的war包拷贝到我们所在目录 
cp $path_w/$name $path/
echo "copy the file $name from $path_w to $path"

//获取该项目正在运行的pid			
pid=$(ps -ef | grep java | grep $name | awk '{print $2}')
echo "pid = $pid"
//如果项目正在运行就杀死进程
if [ $pid ];then
	kill -9 $pid
	echo "kill the process $name pid = $pid"
else
	echo "process is not exist"
fi
//要切换到项目目录下才能在项目目录下生成日志
cd $path
//防止被jenkins杀掉进程 BUILD_ID=dontKillMe
BUILD_ID=dontKillMe
//启动项目
nohup java -server -Xms256m -Xmx512m -jar -Dserver.port=20000 $name >> nohup.out 2>&1 &
//判断项目是否启动成功
pid_new=$(ps -ef | grep java | grep $name | awk '{print $2}')
if [ $? -eq 0 ];then
echo "this application  $name is starting  pid_new = $pid_new"
else 
echo "this application  $name  startup failure"
fi
echo $! > /var/run/myClass.pid
echo "over"

```