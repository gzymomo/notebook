[TOC]

# 一、代码质量监测工具SonarQube
```bash
docker run -d -p 5432:5432 -e POSTGRES_PASSWORD=123456 --name postgres postgres:10

docker run -d -p 9900:9000 -e "SONARQUBE_JDBC_URL=jdbc:postgresql://192.168.0.50:5432/sonar" -e "SONARQUBE_JDBC_USERNAME=postgres" -e "SONARQUBE_JDBC_PASSWORD=123456" --name sonarqube sonarqube
```

# 二、Mysql数据库

```bash
docker run -p 3308:3306 --name gly-test -v /home/logs/mysql/test/conf:/etc/mysql/conf.d -v /home/logs/mysql/test/logs:/logs -v /home/logs/mysql/test/data:/var/lib/mysql -v /etc/localtime:/etc/localtime -e MYSQL_ROOT_PASSWORD=123456 -d mysql:5.7 --lower_case_table_names=1
```

# 三、Nginx
```bash
docker run -d -p 8095:80 --name nginx-8095 -v /var/project/nginx/html:/usr/share/nginx/html -v /etc/nginx/conf:/etc/nginx -v /var/project/logs/nginx:/var/log/nginx nginx
```

# 四、Node_exporter
```bash
docker run -d -p 9101:9100 --net="bridge" --pid="host" --name=node-exporter -v "/:/host:ro,rslave" quay.io/prometheus/node-exporter --path.rootfs /host
```

# 五、Minio
```bash
docker run -d -p 9000:9000 --name minio -e MINIO_ACCESS_KEY=zlkjminio -e MINIO_SECRET_KEY=zlkjminio -v /var/project/minio/data:/data -v /var/project/minio/config:/root/.minio minio/minio server /data
```