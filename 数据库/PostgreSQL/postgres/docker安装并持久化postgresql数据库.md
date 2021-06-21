# [docker安装并持久化postgresql数据库](https://www.cnblogs.com/mingfan/p/11863509.html)

## 1、拉取postgresql镜像

```
docker pull postgresql
```

## 2、创建本地卷，数据卷可以在容器之间共享和重用， 默认会一直存在，即使容器被删除（`docker volume inspect `pgdata可查看数据卷的本地位置）

```
docker volume create pgdata
```

## 3、启动容器

```
docker run --name postgres2 -e POSTGRES_PASSWORD=password -p 5432:5432 -v pgdata:/var/lib/postgresql/data -d postgres:9.6
```

![img](https://img2018.cnblogs.com/i-beta/1660349/201911/1660349-20191114230953551-384672462.png)

 

##  4、进入postgres容器执行sql

```
docker exec -it postgres2 bash

psql -h localhost -p 5432 -U postgres --password
```

![img](https://img2018.cnblogs.com/i-beta/1660349/201911/1660349-20191114231316599-1839621880.png)

 

至此，postgresql安装成功。