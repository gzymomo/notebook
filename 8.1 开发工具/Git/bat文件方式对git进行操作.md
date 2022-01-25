- [bat文件方式对git进行操作](https://blog.51cto.com/13717297/2136859)

仓库初始化基本的配置和仓库地址配置

提交仓库包含单文件配置和多文件提交

远程推送目前是强制推送，如果需要可以自行修改命令或扩展

```cpp
@echo off

rem 标题
title   Git Working
cls 

goto selectAll

pause

rem 选择函数
:selectAll
echo ----------------------------------------
echo    注意：请确保您的git命令可以直接在cmd中运行，如果不能运行，请查看path环境变量
echo    请选择你要进行的操作，然后按回车
echo ----------------------------------------
echo        1，仓库初始化
echo        2，提交仓库
echo        3，退出
set/p n=  请选择：

if "%n%"=="1" ( goto initfun ) else ( if "%n%"=="2" ( goto subfun )   else ( if "%n%"=="3" ( exit ) else ( goto selectAll )))


:subfun
echo    请选择要提交的数据，然后按回车
echo ----------------------------------------
echo        1，单个文件
echo        2，全部文件
echo        3，返回上一级
echo ----------------------------------------
set/p  f=  请选择：

if "%f%"=="1" ( goto one ) else ( if "%f%"=="2" ( goto all )  else ( if "%f%"=="3" ( goto selectAll )   else ( goto subfun )))



:one
set/p  fo=  请输入要上传的文件：
git add "%fo%"
echo 正在进行提交中...
set/p  co=  请输入描述内容：
echo 正在进行对文件进行描述中...
git commit -m "%co%"
echo git单文件上传完成...
goto subfun

:all
git add .
echo 正在进行提交中...
set/p  ca=  请输入描述内容：
git commit -m "%ca%"
echo 正在进行对文件进行描述中...
Echo 
set/p  yd=  请选择 Y. 推送远程            N. 退出：

rem 推送远程命令
If  %yd%==Y ( git push origin master -f  ) else (exit)

goto subfun





:initfun
echo 正在进行初始化中...
set/p  name=  请输入name：
   git config --global user.name "%name%"
set/p  email=  请输入email：
   git config --global user.email "%email%"
 git init
set/p giturl= git初始化已经完成，请输入仓库地址：
  git remote add origin %giturl%
echo 初始化已完成
cls  
goto selectAll
```