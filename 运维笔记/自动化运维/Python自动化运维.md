[TOC]

运维自动化是一-组将静态的设备结构转化为根据T服务需求动态弹性响应的策略,目的就是实现IT运维的质量,降低成本。

```bash
#coding=utf-8

import os
import sys

if os.getuid() ==0:
   pass
else:
   print '当前用户不是root用户！'
   sys.exit(1)

version = row_intput('请输入需要安装的python版本(2.7/3.5)')
if version == '2.7':
   url = 'https://www.python.org/ftp/python/2.7.12/Python-2.7.12.tag'
elif version == '3.5':
   url = 'https://www.python.org/ftp/python/3.5.2/Python-3.5.2.tag'
else:
   print '请输入正确的版本号'
   sys.exit(1)

cmd = 'wget '+url
res = os.system(cmd)
if res != 0:
   print '下载源码包失败！'
   sys.exit(1)

if version == '2.7'
   package_name = 'Python-2.7.12.tgz'
else:
   package_name = 'Python-3.5.2.tgz'
cmd = 'tar xf ' + package_name+'.tag'
res = os.system(cmd)
if res != 0:
   os.system('rm ' + package_name + '.tag')
   print '解压源码包失败，重新运行脚本进行下载！'
   sys.exit(1)

cmd = 'cd '+ package_name + ' && ./configure --prefix=/usr/local/python && make && make install'
res = os.system(cmd)
if res != 0:
   print '编译python源码失败，请检查是否缺少依赖库！'
   sys.exit(1)

```