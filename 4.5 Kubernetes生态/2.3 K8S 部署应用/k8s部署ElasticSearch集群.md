- [k8s部署ElasticSearch集群](https://www.cnblogs.com/wubolive/p/15765671.html)

## 1.前提准备工作

### 1.1 创建elastic的命名空间

namespace编排文件如下：

```YAML
elastic.namespace.yaml 
---
apiVersion: v1
kind: Namespace
metadata:
   name: elastic
---
```

创建elastic名称空间

```Bash
$ kubectl apply elastic.namespace.yaml
namespace/elastic created
```

### 1.2 生成Xpack认证证书文件

ElasticSearch提供了生成证书的工具`elasticsearch-certutil`，我们可以在docker实例中先生成它，然后复制出来，后面统一使用。

#### 1.2.1 创建ES临时容器

```Bash
$ docker run -it -d --name elastic-cret docker.elastic.co/elasticsearch/elasticsearch:7.8.0 /bin/bash
62acfabc85f220941fcaf08bc783c4e305813045683290fe7b15f95e37e70cd0
```

#### 1.2.2 进入容器生成密钥文件

```Bash
$ docker exec -it elastic-cret /bin/bash
$ ./bin/elasticsearch-certutil ca
This tool assists you in the generation of X.509 certificates and certificate
signing requests for use with SSL/TLS in the Elastic stack.

The 'ca' mode generates a new 'certificate authority'
This will create a new X.509 certificate and private key that can be used
to sign certificate when running in 'cert' mode.

Use the 'ca-dn' option if you wish to configure the 'distinguished name'
of the certificate authority

By default the 'ca' mode produces a single PKCS#12 output file which holds:
    * The CA certificate
    * The CA s private key

If you elect to generate PEM format certificates (the -pem option), then the output will
be a zip file containing individual files for the CA certificate and private key

Please enter the desired output file [elastic-stack-ca.p12]: 
Enter password for elastic-stack-ca.p12 : 

./bin/elasticsearch-certutil cert --ca elastic-stack-ca.p12 
This tool assists you in the generation of X.509 certificates and certificate
signing requests for use with SSL/TLS in the Elastic stack.
......

Enter password for CA (elastic-stack-ca.p12) : 
Please enter the desired output file [elastic-certificates.p12]: 
Enter password for elastic-certificates.p12 : 

Certificates written to /usr/share/elasticsearch/elastic-certificates.p12

This file should be properly secured as it contains the private key for 
your instance.

This file is a self contained file and can be copied and used 'as is'
For each Elastic product that you wish to configure, you should copy
this '.p12' file to the relevant configuration directory
and then follow the SSL configuration instructions in the product guide.

For client applications, you may only need to copy the CA certificate and
configure the client to trust this certificate.

$ ls *.p12
elastic-certificates.p12  elastic-stack-ca.p12
```

*注：以上所有选项无需填写，直接回车即可*

#### 1.2.3 将证书文件从容器内复制出来备用

```Bash
$ docker cp elastic-cret:/usr/share/elasticsearch/elastic-certificates.p12 .
$ docker rm -f elastic-cret
```

## 2 创建Master节点

创建Master主节点用于控制整个集群，编排文件如下：

### 2.1 为Master节点配置数据持久化

```Bash
# 创建编排文件
elasticsearch-master.pvc.yaml 
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-elasticsearch-master
  namespace: elastic
spec:
  accessModes:
  - ReadWriteMany
  storageClassName: nfs-client  # 此处指定StorageClass存储卷
  resources:
    requests:
      storage: 10Gi
      
# 创建pvc存储卷
kubectl apply -f elasticsearch-master.pvc.yaml
kubectl get pvc -n elastic
NAME                        STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS     AGE
pvc-elasticsearch-master    Bound    pvc-9ef037b7-c4b2-11ea-8237-ac1f6bd6d98e   10Gi       RWX            nfs-client-ssd   38d
```

将之前生成的证书文件存放到创建好pvc的crets目录中，例：

```Bash
$ mkdir ${MASTER-PVC_HOME}/crets
$ cp elastic-certificates.p12 ${MASTER-PVC_HOME}/crets/
```

### 2.2 创建master节点ConfigMap编排文件

ConfigMap对象用于存放Master集群配置信息，方便ElasticSearch的配置并开启Xpack认证功能，资源对象如下：

```YAML
elasticsearch-master.configmap.yaml 
---
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: elastic
  name: elasticsearch-master-config
  labels:
    app: elasticsearch
    role: master
data:
  elasticsearch.yml: |-
    cluster.name: ${CLUSTER_NAME}
    node.name: ${NODE_NAME}
    discovery.seed_hosts: ${NODE_LIST}
    cluster.initial_master_nodes: ${MASTER_NODES}

    network.host: 0.0.0.0

    node:
      master: true
      data: false
      ingest: false

    xpack.security.enabled: true
    xpack.monitoring.collection.enabled: true
    xpack.security.transport.ssl.enabled: true
    xpack.security.transport.ssl.verification_mode: certificate
    xpack.security.transport.ssl.keystore.path: /usr/share/elasticsearch/data/certs/elastic-certificates.p12
    xpack.security.transport.ssl.truststore.path: /usr/share/elasticsearch/data/certs/elastic-certificates.p12
---
```

### 2.3 创建master节点Service编排文件

Master节点只需要用于集群通信的9300端口，资源清单如下：

```YAML
elasticsearch-master.service.yaml 
---
apiVersion: v1
kind: Service
metadata:
  namespace: elastic
  name: elasticsearch-master
  labels:
    app: elasticsearch
    role: master
spec:
  ports:
  - port: 9300
    name: transport
  selector:
    app: elasticsearch
    role: master
---
```

### 2.4 创建master节点Deployment编排文件

Deployment用于定于Master节点应用Pod，资源清单如下：

```YAML
elasticsearch-master.deployment.yaml 
---
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: elastic
  name: elasticsearch-master
  labels:
    app: elasticsearch
    role: master
spec:
  replicas: 1
  selector:
    matchLabels:
      app: elasticsearch
      role: master
  template:
    metadata:
      labels:
        app: elasticsearch
        role: master
    spec:
      containers:
      - name: elasticsearch-master
        image: docker.elastic.co/elasticsearch/elasticsearch:7.8.0
        env:
        - name: CLUSTER_NAME
          value: elasticsearch
        - name: NODE_NAME
          value: elasticsearch-master
        - name: NODE_LIST
          value: elasticsearch-master,elasticsearch-data,elasticsearch-client
        - name: MASTER_NODES
          value: elasticsearch-master
        - name: ES_JAVA_OPTS
          value: "-Xms2048m -Xmx2048m"
        - name: ELASTIC_USERNAME
          valueFrom:
            secretKeyRef:
              name: elastic-credentials
              key: username
        - name: ELASTIC_PASSWORD
          valueFrom:
            secretKeyRef:
              name: elastic-credentials
              key: password
        ports:
        - containerPort: 9300
          name: transport
        volumeMounts:
        - name: config
          mountPath: /usr/share/elasticsearch/config/elasticsearch.yml
          readOnly: true
          subPath: elasticsearch.yml
        - name: storage
          mountPath: /usr/share/elasticsearch/data
      volumes:
      - name: config
        configMap:
          name: elasticsearch-master-config
      - name: storage
        persistentVolumeClaim:
          claimName: pvc-elasticsearch-master
---
```

### 2.5 创建3个master资源对象

```Bash
$ kubectl apply  -f elasticsearch-master.configmap.yaml \
                 -f elasticsearch-master.service.yaml \
                 -f elasticsearch-master.deployment.yaml
configmap/elasticsearch-master-config created
service/elasticsearch-master created
deployment.apps/elasticsearch-master created

$ kubectl get pods -n elastic -l app=elasticsearch
NAME                                    READY   STATUS    RESTARTS   AGE
elasticsearch-master-7fc5cc8957-jfjmr   1/1     Running   0          23m
```

直到 Pod 变成 Running 状态就表明 master 节点安装成功。

## 3 安装ElasticSearch数据节点

接下来安装的是ES的数据节点，主要用于负责集群的数据托管和执行查询

#### 3.1 创建data节点ConfigMap编排文件

跟Master节点一样，ConfigMap用于存放数据节点ES的配置信息，编排文件如下：

```YAML
elasticsearch-data.configmap.yaml 
---
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: elastic
  name: elasticsearch-data-config
  labels:
    app: elasticsearch
    role: data
data:
  elasticsearch.yml: |-
    cluster.name: ${CLUSTER_NAME}
    node.name: ${NODE_NAME}
    discovery.seed_hosts: ${NODE_LIST}
    cluster.initial_master_nodes: ${MASTER_NODES}

    network.host: 0.0.0.0

    node:
      master: false
      data: true
      ingest: false

    xpack.security.enabled: true
    xpack.monitoring.collection.enabled: true
    xpack.security.transport.ssl.enabled: true
    xpack.security.transport.ssl.verification_mode: certificate
    xpack.security.transport.ssl.keystore.path: /usr/share/elasticsearch/data/certs/elastic-certificates.p12
    xpack.security.transport.ssl.truststore.path: /usr/share/elasticsearch/data/certs/elastic-certificates.p12
---
```

#### 3.2 创建data节点Service编排文件

data节点同master一样只需通过9300端口与其它节点通信，资源对象如下：

```YAML
elasticsearch-data.service.yaml 
---
apiVersion: v1
kind: Service
metadata:
  namespace: elastic
  name: elasticsearch-data
  labels:
    app: elasticsearch
    role: data
spec:
  ports:
  - port: 9300
    name: transport
  selector:
    app: elasticsearch
    role: data
---
```

### 3.3 创建data节点StatefulSet控制器

data节点需要创建StatefulSet控制器，因为存在多个数据节点，且每个数据节点的数据不是一样的，需要单独存储，其中volumeClaimTemplates用于定于每个数据节点的存储卷，对应的清单文件如下：

```YAML
elasticsearch-data.statefulset.yaml 
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  namespace: elastic
  name: elasticsearch-data
  labels:
    app: elasticsearch
    role: data
spec:
  serviceName: "elasticsearch-data"
  replicas: 2
  selector:
    matchLabels:
      app: elasticsearch
      role: data
  template:
    metadata:
      labels:
        app: elasticsearch
        role: data
    spec:
      containers:
      - name: elasticsearch-data
        image: docker.elastic.co/elasticsearch/elasticsearch:7.8.0
        env:
        - name: CLUSTER_NAME
          value: elasticsearch
        - name: NODE_NAME
          value: elasticsearch-data
        - name: NODE_LIST
          value: elasticsearch-master,elasticsearch-data,elasticsearch-client
        - name: MASTER_NODES
          value: elasticsearch-master
        - name: "ES_JAVA_OPTS"
          value: "-Xms4096m -Xmx4096m"
        - name: ELASTIC_USERNAME
          valueFrom:
            secretKeyRef:
              name: elastic-credentials
              key: username
        - name: ELASTIC_PASSWORD
          valueFrom:
            secretKeyRef:
              name: elastic-credentials
              key: password
        ports:
        - containerPort: 9300
          name: transport
        volumeMounts:
        - name: config
          mountPath: /usr/share/elasticsearch/config/elasticsearch.yml
          readOnly: true
          subPath: elasticsearch.yml
        - name: elasticsearch-data-persistent-storage
          mountPath: /usr/share/elasticsearch/data
      volumes:
      - name: config
        configMap:
          name: elasticsearch-data-config
  volumeClaimTemplates:
  - metadata:
      name: elasticsearch-data-persistent-storage
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: nfs-client-ssd
      resources:
        requests:
          storage: 500Gi
---
```

### 3.4 创建data节点资源对象

```Bash
$ kubectl apply -f elasticsearch-data.configmap.yaml \
                -f elasticsearch-data.service.yaml \
                -f elasticsearch-data.statefulset.yaml

configmap/elasticsearch-data-config created
service/elasticsearch-data created
statefulset.apps/elasticsearch-data created
```

将之前准备好的ES证书文件同Master节点一样复制到PVC的目录中（每个数据节点都放一份）

```Bash
$ mkdir ${DATA-PVC_HOME}/crets
$ cp elastic-certificates.p12 ${DATA-PVC_HOME}/crets/
```

等待Pod变成Running状态说明节点启动成功

```Bash
$ kubectl get pods -n elastic -l app=elasticsearch
NAME                                    READY   STATUS    RESTARTS   AGE
elasticsearch-data-0                    1/1     Running   0          47m
elasticsearch-data-1                    1/1     Running   0          47m
elasticsearch-master-7fc5cc8957-jfjmr   1/1     Running   0          100m
```

## 4 安装ElasticSearch客户端节点

Client节点主要用于负责暴露一个HTTP的接口用于查询数据及将数据传递给数据节点

### 4.1 创建Client节点ConfigMap编排文件

```YAML
---
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: elastic
  name: elasticsearch-client-config
  labels:
    app: elasticsearch
    role: client
data:
  elasticsearch.yml: |-
    cluster.name: ${CLUSTER_NAME}
    node.name: ${NODE_NAME}
    discovery.seed_hosts: ${NODE_LIST}
    cluster.initial_master_nodes: ${MASTER_NODES}

    network.host: 0.0.0.0

    node:
      master: false
      data: false
      ingest: true

    xpack.security.enabled: true
    xpack.monitoring.collection.enabled: true
    xpack.security.transport.ssl.enabled: true
    xpack.security.transport.ssl.verification_mode: certificate
    xpack.security.transport.ssl.keystore.path: /usr/share/elasticsearch/data/certs/elastic-certificates.p12
    xpack.security.transport.ssl.truststore.path: /usr/share/elasticsearch/data/certs/elastic-certificates.p12
---
```

### 4.2 创建Client节点Service编排文件

客户端节点需要暴露两个端口，9300端口用于与集群其它节点进行通信，9200端口用于HTTP API使用，资源对象如下：

```YAML
elasticsearch-client.service.yaml 
---
apiVersion: v1
kind: Service
metadata:
  namespace: elastic
  name: elasticsearch-client
  labels:
    app: elasticsearch
    role: client
spec:
  ports:
  - port: 9200
    name: client
    nodePort: 9200
  - port: 9300
    name: transport
  selector:
    app: elasticsearch
    role: client
  type: NodePort
---
```

### 4.3 创建Client节点Deployment编排文件

```YAML
elasticsearch-client.deployment.yaml 
---
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: elastic
  name: elasticsearch-client
  labels:
    app: elasticsearch
    role: client
spec:
  selector:
    matchLabels:
      app: elasticsearch
      role: client
  template:
    metadata:
      labels:
        app: elasticsearch
        role: client
    spec:
      containers:
      - name: elasticsearch-client
        image: docker.elastic.co/elasticsearch/elasticsearch:7.8.0
        env:
        - name: CLUSTER_NAME
          value: elasticsearch
        - name: NODE_NAME
          value: elasticsearch-client
        - name: NODE_LIST
          value: elasticsearch-master,elasticsearch-data,elasticsearch-client
        - name: MASTER_NODES
          value: elasticsearch-master
        - name: ES_JAVA_OPTS
          value: "-Xms2048m -Xmx2048m"
        - name: ELASTIC_USERNAME
          valueFrom:
            secretKeyRef:
              name: elastic-credentials
              key: username
        - name: ELASTIC_PASSWORD
          valueFrom:
            secretKeyRef:
              name: elastic-credentials
              key: password
        ports:
        - containerPort: 9200
          name: client
        - containerPort: 9300
          name: transport
        volumeMounts:
        - name: config
          mountPath: /usr/share/elasticsearch/config/elasticsearch.yml
          readOnly: true
          subPath: elasticsearch.yml
        - name: storage
          mountPath: /usr/share/elasticsearch/data
      volumes:
      - name: config
        configMap:
          name: elasticsearch-client-config
      - name: storage
        persistentVolumeClaim:
          claimName: pvc-elasticsearch-client
---
```

### 4.4 创建Client节点资源对象

```Bash
$ kubectl apply  -f elasticsearch-client.configmap.yaml \
                 -f elasticsearch-client.service.yaml \
                 -f elasticsearch-client.deployment.yaml

configmap/elasticsearch-client-config created
service/elasticsearch-client created
deployment.apps/elasticsearch-client createdt
```

知道所有节点都部署成功为Running状态说明安装成功

```Bash
kubectl get pods -n elastic -l app=elasticsearch
NAME                                    READY   STATUS    RESTARTS   AGE
elasticsearch-client-f4d4ff794-6gxpz    1/1     Running   0          23m
elasticsearch-data-0                    1/1     Running   0          47m
elasticsearch-data-1                    1/1     Running   0          47m
elasticsearch-master-7fc5cc8957-jfjmr   1/1     Running   0          54m
```

部署Client过程中可使用如下命令查看集群状态变化

```Bash
$ kubectl logs -f -n elastic \
>   $(kubectl get pods -n elastic | grep elasticsearch-master | sed -n 1p | awk '{print $1}') \
>   | grep "Cluster health status changed from"
{"type": "server", "timestamp": "2020-08-18T06:35:20,859Z", "level": "INFO", "component": "o.e.c.r.a.AllocationService", "cluster.name": "elasticsearch", "node.name": "elasticsearch-master", "message": "Cluster health status changed from [RED] to [YELLOW] (reason: [shards started [[.kibana_1][0]]]).", "cluster.uuid": "Yy1ctnq7SjmRsuYfbJGSzA", "node.id": "z7vrjgYcTUiiB7tb0kXQ1Q"  }
```

## 5 生成初始化密码

因为我们启用了Xpack安全模块来保护我们集群，所以需要一个初始化密码，实用客户端节点容器内的`bin/elasticsearch-setup-passwords` 命令来生成，如下所示

```Bash
$ kubectl exec $(kubectl get pods -n elastic | grep elasticsearch-client | sed -n 1p | awk '{print $1}') \
  -n elastic \
  -- bin/elasticsearch-setup-passwords auto -b

Changed password for user apm_system
PASSWORD apm_system = 5wg8JbmKOKiLMNty90l1

Changed password for user kibana_system
PASSWORD kibana_system = 1bT0U5RbPX1e9zGNlWFL

Changed password for user kibana
PASSWORD kibana = 1bT0U5RbPX1e9zGNlWFL

Changed password for user logstash_system
PASSWORD logstash_system = 1ihEyA5yAPahNf9GuRJ9

Changed password for user beats_system
PASSWORD beats_system = WEWDpPndnGvgKY7ad0T9

Changed password for user remote_monitoring_user
PASSWORD remote_monitoring_user = MOCszTmzLmEXQrPIOW4T

Changed password for user elastic
PASSWORD elastic = bbkrgVrsE3UAfs2708aO
```

生成完后将elastic用户名和密码需要添加到Kubernetes的Secret对象中：

```Bash
$ kubectl create secret generic elasticsearch-pw-elastic \
  -n elastic \
  --from-literal password=bbkrgVrsE3UAfs2708aO
```

## 6 创建Kibana应用

ElasticSearch集群安装完后，需要安装Kibana用于ElasticSearch数据的可视化工具。

### 6.1 创建Kibana的ConfigMap编排文件

创建一个ConfigMap资源对象用于Kibana的配置文件，里面定义了ElasticSearch的访问地址、用户及密码信息，对应的清单文件如下：

```YAML
kibana.configmap.yaml 
---
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: elastic
  name: kibana-config
  labels:
    app: kibana
data:
  kibana.yml: |-
    server.host: 0.0.0.0

    elasticsearch:
      hosts: ${ELASTICSEARCH_HOSTS}
      username: ${ELASTICSEARCH_USER}
      password: ${ELASTICSEARCH_PASSWORD}
---
```

### 6.2 创建Kibana的Service编排文件

```YAML
kibana.service.yaml 
---
apiVersion: v1
kind: Service
metadata:
  namespace: elastic
  name: kibana
  labels:
    app: kibana
spec:
  ports:
  - port: 5601
    name: webinterface
    nodePort: 5601
  selector:
    app: kibana
---
```

### 6.3 创建Kibana的Deployment编排文件

```YAML
kibana.deployment.yaml 
---
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: elastic
  name: kibana
  labels:
    app: kibana
spec:
  selector:
    matchLabels:
      app: kibana
  template:
    metadata:
      labels:
        app: kibana
    spec:
      containers:
      - name: kibana
        image: docker.elastic.co/kibana/kibana:7.8.0
        ports:
        - containerPort: 5601
          name: webinterface
        env:
        - name: ELASTICSEARCH_HOSTS
          value: "http://elasticsearch-client.elastic.svc.cluster.local:9200"
        - name: ELASTICSEARCH_USER
          value: "elastic"
        - name: ELASTICSEARCH_PASSWORD
          valueFrom:
            secretKeyRef:
              name: elasticsearch-pw-elastic
              key: password
        - name: "I18N_LOCALE"
          value: "zh-CN"
        volumeMounts:
        - name: config
          mountPath: /usr/share/kibana/config/kibana.yml
          readOnly: true
          subPath: kibana.yml
      volumes:
      - name: config
        configMap:
          name: kibana-config
---
```

### 6.4 创建Kibana的Ingress编排文件

这里使用Ingress来暴露Kibana服务，用于通过域名访问，编排文件如下：

```YAML
kibana.ingress.yaml 
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: kibana
  namespace: elastic
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: kibana.demo.com
    http:
      paths:
      - backend:
          serviceName: kibana
          servicePort: 5601
        path: /
```

### 6.5 通过Kibana编排文件创建资源对象

```Bash
$ kubectl apply  -f kibana.configmap.yaml \
                 -f kibana.service.yaml \
                 -f kibana.deployment.yaml \
                 -f kibana.ingress.yaml

configmap/kibana-config created
service/kibana created
deployment.apps/kibana created
ingress/kibana created
```

部署完成后通过查看Kibana日志查看启动状态：

```Bash
kubectl logs -f -n elastic $(kubectl get pods -n elastic | grep kibana | sed -n 1p | awk '{print $1}') \
>      | grep "Status changed from yellow to green"
{"type":"log","@timestamp":"2020-08-18T06:35:29Z","tags":["status","plugin:elasticsearch@7.8.0","info"],"pid":8,"state":"green","message":"Status changed from yellow to green - Ready","prevState":"yellow","prevMsg":"Waiting for Elasticsearch"}
```

当状态变成green后，我们就可以通过ingress的域名到浏览器访问Kibana服务了

```Bash
$ kubectl get ingress -n elastic
NAME     HOSTS            ADDRESS   PORTS     AGE
kibana   kibana.demo.cn             80        40d
```

### 6.5 登入Kibana并配置

如图所示，使用上面创建的Secret对象中的elastic用户和生成的密码进行登入：

![img](https://img2020.cnblogs.com/blog/1686997/202201/1686997-20220105101731358-778557740.png)

创建一个超级用户进行访问，依次点击 Stack Management > 用户 > 创建用户 > 输入如下信息：

![img](https://img2020.cnblogs.com/blog/1686997/202201/1686997-20220105101746430-1724600443.png)

创建完成后就可以用自定义的admin用户进行管理