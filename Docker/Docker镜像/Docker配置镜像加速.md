



```bash
vi /etc/docker/daemon.json
```



```yaml
{
 "registry-mirrors": [
  "https://paucfus3.mirror.aliyuncs.com",
  "https://hub-mirror.c.163.com",
    "https://registry.aliyuncs.com",
    "https://registry.docker-cn.com",
    "https://docker.mirrors.ustc.edu.cn"
  ]
}
```



```bash
systemctl daemon-reload && systemctl restart docker
```

