# docker 部署带postgis扩展的postgresql

[hey laosha](https://blog.csdn.net/geol200709)

[docker 部署带postgis扩展的postgresql](https://blog.csdn.net/geol200709/article/details/89481194)

拉取 postgresql 9.6 版本以及postgis 2.4 版本

```bash
docker pull kartoza/postgis:9.6-2.4

docker run -d --name postgresql9.6 -e ALLOW_IP_RANGE=0.0.0.0/0 -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres -v /var/minio/postgresql/data:/var/lib/postgresql/data -p 5432:5432 kartoza/postgis:9.6-2.4
```

- -e ALLOW_IP_RANGE=0.0.0.0/0，这个表示允许所有ip访问，如果不加，则非本机 ip 访问不了
- -e POSTGRES_USER=postgres 用户名
- -e POSTGRES_PASS=‘postgres’ 指定密码

