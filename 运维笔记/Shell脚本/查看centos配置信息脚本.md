```bash
#!/bin/bash

echo ======= cpu个数： =======
grep 'physical id' /proc/cpuinfo | sort -u | wc -l

echo ======= cpu核数： =======
cat /proc/cpuinfo | grep "cpu cores" | uniq

echo ======= cpu型号： =======
cat /proc/cpuinfo | grep 'model name' |uniq

echo ======= cpu内核频率： =======
cat /proc/cpuinfo |grep MHz|uniq

echo ======= cpu统计信息： =======
lscpu

echo ======= 内存总数： =======
cat /proc/meminfo | grep MemTotal

echo ======= 内核版本： =======
cat /proc/version

echo ======= 操作系统内核信息： =======
uname -a

echo ======= 磁盘信息： =======
fdisk -l
```

