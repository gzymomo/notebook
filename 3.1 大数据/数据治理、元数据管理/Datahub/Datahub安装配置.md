- [Datahub安装配置—————附带详细步骤_繁星蓝雨的博客-CSDN博客_datahub](https://blog.csdn.net/qq_33375598/article/details/118501275)

# 0 作用

使用Datahub从原始数据库抽取数据表的[schema](https://so.csdn.net/so/search?q=schema&spm=1001.2101.3001.7020)信息。

# 1 安装[docker](https://so.csdn.net/so/search?q=docker&spm=1001.2101.3001.7020)

```shell
$ yum -y install docker
# 启动docker
$ sudo systemctl start docker
# 测试是否正确安装
$ sudo docker run hello-world

```

安装docker-compose【docker的服务编排工具,主要是用来构建多个服务】 ：

```shell
$ curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

$ chmod +x /usr/local/bin/docker-compose
```

重启docker:

```shell
守护进程重启
$ sudo systemctl daemon-reload
重启docker服务
$ sudo systemctl restart docker
```

检查启动:

```shell
$ docker container ls
```

# 2 安装和启动Datahub

```shell
$ cd /opt
$ yum -y install git
$ git --version
$ git clone https://github.com/linkedin/datahub.git
$ cd /opt/datahub/docker
$ source ./quickstart.sh
```

扩展

```shell
$ python3 -m pip install --upgrade pip wheel setuptools
$ python3 -m pip uninstall datahub acryl-datahub || true  # sanity check - ok if it fails
$ python3 -m pip install --upgrade acryl-datahub
$ datahub version
$ datahub docker quickstart 
```

# 3 使用Datahub导入数据

```shell
$ pip install pymysql
$ cd /opt/datahub/docker/ingestion
```

修改yml配置文件：

```shell
$ vi recipe.yml
```

修改内容为：

修改的地方为：

- type：数据主题
- username、password、host_port、database【可不填写，没起作用】：数据库账户、密码、ip地址和端口
- sink：数据目的地

```shell
source:
  type: "mysql"
  config:
    username: "root"
    password: "root"
    database: "hero"
    host_port: "192.168.101.110:9876"
sink:
  type: "datahub-rest"
  config:
    server: 'http://localhost:8080'
```

另一种格式的recipe.yml：

```bash
source:
  type: mysql
  config:
    username: "root"
    password: "root"
    database: "hero"
    host_port: "192.168.101.177:3306"
    table_pattern:
      deny:
        # Note that the deny patterns take precedence over the allow patterns.
        - "performance_schema"
      allow:
        - "schema1.table2"
      # Although the 'table_pattern' enables you to skip everything from certain schemas,
      # having another option to allow/deny on schema level is an optimization for the case when there is a large number
      # of schemas that one wants to skip and you want to avoid the time to needlessly fetch those tables only to filter
      # them out afterwards via the table_pattern.
    schema_pattern:
      deny:
        - "garbage_schema"
      allow:
        - "schema1"
sink:
  type: "datahub-rest"
  config:
    server: 'http://datahub-gms:8080'
```

导入数据:

```shell
$ datahub ingest -c recipe.yml
```

命令执行成功：
![在这里插入图片描述](https://img-blog.csdnimg.cn/20210705234007920.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzMzMzc1NTk4,size_16,color_FFFFFF,t_70)

如果导入成功，则会出现下面的界面：
![在这里插入图片描述](https://img-blog.csdnimg.cn/2021070523383833.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzMzMzc1NTk4,size_16,color_FFFFFF,t_70)
![在这里插入图片描述](https://img-blog.csdnimg.cn/20210705233843716.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzMzMzc1NTk4,size_16,color_FFFFFF,t_70)
如果是通过调用API（[参考网址](https://github.com/linkedin/datahub/tree/master/datahub-frontend)）的方法得到schema，可以使用下面的方法调用，调用的api为:`http://10.20.3.32:9002/api/v2/datasets/urn:li:dataset:(urn:li:dataPlatform:mysql,db_realtime_data.test_cdc,PROD)/schema`

![在这里插入图片描述](https://img-blog.csdnimg.cn/3c9a414cf7b44faeb1080eeb85822f31.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzMzMzc1NTk4,size_16,color_FFFFFF,t_70)
数据为：

```bash
{
    "schema": {
        "schemaless": false,
        "rawSchema": "",
        "keySchema": null,
        "columns": [
            {
                "id": null,
                "sortID": 0,
                "parentSortID": 0,
                "fieldName": "id",
                "parentPath": null,
                "fullFieldPath": "id",
                "dataType": "VARCHAR(length=128)",
                "comment": "",
                "commentCount": null,
                "partitionedStr": null,
                "partitioned": false,
                "nullableStr": null,
                "nullable": false,
                "indexedStr": null,
                "indexed": false,
                "distributedStr": null,
                "distributed": false,
                "treeGridClass": null
            },
            {
                "id": null,
                "sortID": 0,
                "parentSortID": 0,
                "fieldName": "name",
                "parentPath": null,
                "fullFieldPath": "name",
                "dataType": "VARCHAR(length=128)",
                "comment": "",
                "commentCount": null,
                "partitionedStr": null,
                "partitioned": false,
                "nullableStr": null,
                "nullable": false,
                "indexedStr": null,
                "indexed": false,
                "distributedStr": null,
                "distributed": false,
                "treeGridClass": null
            },
            {
                "id": null,
                "sortID": 0,
                "parentSortID": 0,
                "fieldName": "create_time",
                "parentPath": null,
                "fullFieldPath": "create_time",
                "dataType": "DATETIME()",
                "comment": "",
                "commentCount": null,
                "partitionedStr": null,
                "partitioned": false,
                "nullableStr": null,
                "nullable": false,
                "indexedStr": null,
                "indexed": false,
                "distributedStr": null,
                "distributed": false,
                "treeGridClass": null
            },
            {
                "id": null,
                "sortID": 0,
                "parentSortID": 0,
                "fieldName": "update_time",
                "parentPath": null,
                "fullFieldPath": "update_time",
                "dataType": "DATETIME()",
                "comment": "",
                "commentCount": null,
                "partitionedStr": null,
                "partitioned": false,
                "nullableStr": null,
                "nullable": false,
                "indexedStr": null,
                "indexed": false,
                "distributedStr": null,
                "distributed": false,
                "treeGridClass": null
            }
        ],
        "lastModified": 1624331877660
    }
}
```

使用curl测试接口：

```bash
获得权限：
curl -c cookie.txt -d '{"username":"datahub", "password":"datahub"}' -H 'Content-Type: application/json' http://localhost:9002/authenticate

测试：
curl -b cookie.txt "http://localhost:9002/api/v2/search?type=dataset&input=page"

curl -b cookie.txt "http://localhost:9002/api/v2/datasets/urn:li:dataset:(urn:li:dataPlatform:kafka,pageviewsevent,PROD)"

curl -b cookie.txt "http://localhost:9002/api/v2/datasets/urn:li:dataset:(urn:li:dataPlatform:kafka,pageviewsevent,PROD)/schema"


curl -b cookie.txt "http://10.20.3.32:9002/api/v2/datasets/urn:li:dataset:(urn:li:dataPlatform:kafka,pageviewsevent,PROD)/mysql"

curl -b cookie.txt "http://10.20.3.32:9002/api/v2/datasets/:urn/prod"
```

# 4 安装配置python[附带]

因为运行全量数据同步需要运行py脚本，因此需要安装python。

```
# 安装python
$ wget https://www.python.org/ftp/python/3.8.2/Python-3.8.0.tgz
# 更新pip
$ pip3 install --upgrade pip -i http://pypi.douban.com/simple --trusted-host pypi.douban.com
Looking in indexes: http://pypi.douban.com/simple
```

自由切换python2和python3 ：

- 查看python路径

```
$ pip --version
```

- 将python2和python3分别添加为可选项

```
$ sudo update-alternatives --install /usr/bin/python python /usr/bin/python2.7 1
$ sudo update-alternatives --install /usr/bin/python python /root/anaconda3/lib/python3.8 2
```

- 切换版本

```
sudo update-alternatives --config python
```

删除可选版本：

```
sudo update-alternatives --remove python /usr/bin/python python /root/anaconda3/lib/python3.8 
```