## 查看docker日志

```bash
docker logs [OPTIONS] CONTAINER ID
```

OPTIONS说明：

```bash
-f : 跟踪日志输出
--since :显示某个开始时间的所有日志
-t : 显示时间戳
--tail :仅列出最新N条容器日志
```

7.1 查看指定时间后的日志，只显示最后100行：

```bash
docker logs -f -t --since="2020-10-01" --tail=100 CONTAINER ID
```

7.2 查个指定时间区段的日志

```bash
docker logs -t --since="2020-10-01T19:00:00" --until "2020-10-01T19:00:00" CONTAINER ID
```

7.3 查看指定时间后面的日志：

```bash
docker logs -t --since="2020-10-01T19:00:00" CONTAINER ID
```

7.4 查看最近5分钟的日志:

```bash
docker logs --since 5m CONTAINER ID
```

7.5 通过 exec 命令对指定的容器执行 bash:

```bash
docker exec hellolearn -it /bin/bash `或者` docker exec -it hellolearn bash
```

7.6 查看docker IP

```bash
docker inspect --format='{{.NetworkSettings.IPAddress}}' hellolearn
```



