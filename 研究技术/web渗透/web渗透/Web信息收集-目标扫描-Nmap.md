Web信息收集-目标扫描-Nmap

# 一、Nmap简介
Nmap是安全渗透领域最强大的开源端口扫描器，能跨平台支持运行。
官网：Https://nmap.org/
官网：http://sectools.org/

# 二、扫描示例
## 主机发现
`nmap -sn 192.168.106/24`
## 端口扫描
`nmap-sS -p1-1024 192.168.106.1`
## 系统扫描
`nmap -O 192.168.106.1`
## 版本扫描
`nmap -sV 192.168.106.1`
## 综合扫描
`nmap -A 192.168.106.1`

## 脚本扫描
```bash
/usr/shar/nmap/scripts#
nmap --script=default 192.168.106.1
nmap --script=auth 192.168.106.1
nmap --script=brute 192.168.106.1
nmap --script=vuln 192.168.106.1
nmap --script=broadcast 192.168.106.1
nmap --script=smb-brute.nse 192.168.106.1
nmap --script=smb-check-vulns.nse --script-args=unsafe=1 192.168.106.1
nmap --script=smb-vuln-conficker.nse --script-args=unsafe=1 192.168.106.1
nmap -p3306 --script=mysql-empty-password.nse 192.168.106.1
```

# 三、Nmap图形化界面-Zenmap
## 3.1 Intense scan
`Nmap -T4 -A -v 192.168.106.1`
 - -T 设置速度登记，1到5级，数字越大，速度越快
 - -A 综合扫描
 - -v 输出扫描过程

## 3.2 Intense scan plus UDP
`Nmap -sS -sU -T4 -A -v 192.168.106.1`
 - -sS TCP全连接扫描
 - -sU UDP扫描

## 3.3 Intense scan,all TCP ports
`Nmap -p 65535 -T4 -A -v 192.168.106.1`
 - -p 指定端口范围，默认扫描1000个端口

## 3.4 Intense scan no ping
`Nmap -T4 -A -v -Pn 192.168.106.1/24`
 - -Pn 不做ping扫描，例如针对防火墙等安全产品

## 3.5 ping scan
`Nmap -sn 192.168.106.1/24`
`Nmap -sn -T4 -v 192.168.106.1/24`
 - -sn 只做ping扫描，不做端口扫描

## 3.6 quick scan
`Nmap -T4 -F 192.168.106.1`
 - -F fast模式，只扫描常见服务端口，比默认端口（1000个）还少

## 3.7 quick scan plus
`Nmap -sV -T4 -O -F --version-light 192.168.106.1`
 - -sV 扫描系统和服务版本
 - -O 扫描操作系统版本

## 3.8 Quick traceroute
`Nmap -sn --traceroute www.baidu.com`

## 3.9 Regular scan
`Nmap www.baidu.com`

## 3.10 slow comprehensive scan
`Nmap -sS -sU -T4 -A -v -PE -PP -PS80,443 -PA3389 -PU40125 -PY -g 53 --script “default or (discovery and safe)” www.baidu.com`