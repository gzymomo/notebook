- [在 K8s 中部署企业级发布订阅消息系统 Apache Pulsar](https://blog.frognew.com/2021/12/learning-apache-pulsar-14.html)

## 0.阶段复习

Pulsar是一个支持多租户的、高性能的、分布式的Pub-Sub消息系统。

- 了解Pulsar的架构。Pulsar提供了一个比Cluster更高级别的抽象Instance。
  - 一个Pulsar Instance由多个Pulsar Cluster组成
  - 一个Instance中的Cluster之间可以相互跨地域复制数据
- 单个Pulsar集群由以下部分组成:
  - Pulsar Proxy: 是无状态的，Proxy作为集群的智能路由层，是负责Pulsar客户端与Pulsar集群交互的统一网关
  - Pulsar Brokers: 也是无状态的，是集群的服务层，Proxy会将客户端的访问请求转发到正确的Broker上。Broker作为服务层与Pulsar的存储层进行交互
  - Bookies: 一个集群有多个Bookie节点(组成Bookeeper集群)负责消息的持久化存储
  - Zookeeper: 用于集群级别的配置和协调，并存储Pulsar集群的所有元数据
- 以docker容器运行单机Pulsar
  - 学习使用命令行工具`pulsar-admin`创建tenant、namespace、topic
  - 了解Pulsar Admin REST API
- tenant、namespace、topic的基本概念
  - Pulsar基于租户、命名空间、主题的逻辑层次结构支持多租户
  - 分区Topic的概念
  - Topic URL格式
  - 持久化Topic和非持久化Topic的概念
- 生产者和消费者、订阅和订阅模式
  - Pulsar支持: exclusive(独占), failover(故障转移/灾备), shared(共享), key-shared(基于key的共享模式) 4中订阅模式
  - 使用命令行工具pulsar-client进行生产者和消费者测试
- 使用Pulsar Java客户端库创建生产者、消费者、Reader
  - 消费者端可以使用"同步接收消息", “异步接收消息”, “MessageListener接收” 3种模式，其中MessageListener自带线程池
  - 创建消费者时可以设置消费者的批量接收策略
  - 多主题订阅: 设置单个消费者订阅多个主题
  - 消费异常处理可以使用"无限重试", “捕获并忽略异常”, “死信主题（Dead Letter Topic)“三种方式
  - 使用消息Reader可以由用户自己手动在Topic中定位，读取想要读取的消息
- 使用Pulsar Go客户端库
  - 消费者端支持`consumer.Receive()`和`consumer.Chan()`两种方式消费消息。前者对channel关闭和context cancel的情况做了封装，后者要我们自己处理和channel的交互，但也提供了最大的灵活性。
  - 多主题订阅
  - 死信策略和死信主题
  - 使用消息Reader
- 使用Pulsar Schema管理消息数据的类型安全性
- Web图形化管理工具Pulsar Manager
- 延迟消息投递特性
  - 指定多长时间后投递deliverAfter
  - 指定在将来某个时间点投递deliverAt
- 分区Topic和路由模式
- 认证和授权
  - 开启JWT身份认证
  - 授权和权限管理

前面的学习一直是基于以docker容器启动的单机Pulsar。今天将学习使用Helm在Kubernetes集群中部署Pulsar集群。

## 1.环境准备

这里使用的Kubernetes集群的版本是1.22.4，Helm的版本是3.7.1。

### 1.1 Pulsar集群组件和K8S Node节点规划

下面做一下Pulsar集群各个组件部署节点的规划。使用Pulsar官方的Helm Chart部署时，可选择部署各个组件。 在后边的配置中将禁用监控相关的组件(promethues, grafana等)，我们这里选择以后尝试使用外部的全局Prometheus实现对Pulsar集群的监控。

本节选择部署的集群组件如下:

- proxy: 无状态, 但pulsar的helm chart使用StatefulSet部署
- broker: 无状态, 但pulsar的helm chart使用StatefulSet部署
- bookie: 有状态, pulsar的helm chart使用StatefulSet部署
- zookeeper: 有状态, pulsar的helm chart使用StatefulSet部署
- recovery: 无状态, 但pulsar的helm chart使用StatefulSet部署
- toolset: 无状态, 但pulsar的helm chart使用StatefulSet部署
- pulsar-manager: 无状态, pulsar的helm chart使用Deployment部署

注意, pulsar-managers虽然是无状态的，但因为它需要使用PostgreSQL数据库，pulsar-managers的docker镜像中内置一个PostgreSQL, 这个我们在后边的配置中将改为使用集群外部的PostgreSQL。

下面说一下以上各个组件的部署节点选择。

- 对于proxy, broker, recovery, toolset, pulsar-manager这5个无状态组件，可以让k8s将其调度到任意节点上。
- 对于bookie, zookeeper这2个有状态组件，需要我们根据其存储卷的类型，将其规划到合适的k8s节点。

我们在线上环境对于有状态服务的部署，在存储卷的选择上，为了更好的性能，一般都是选择Local Persistent Volumes  在。因此，如果你在规划一个线上版本的Pulsar集群部署的话，对于bookie和zookeeper肯定需要单独的独立的k8s节点，并使用这些节点上创建的Local PV。 例如，一个线上生产可用的Pulsar集群可能规划如下:

- pulsar zookeeper集群至少需要3个独立的k8s节点, 在这些节点上创建zookeeper的local pv
- pulsar bookeeper集群(bookie节点组成)根据规划的容量需要N个独立的k8s节点,  在这些节点上创建bookie的local pv。如果后续需要扩容增加bookie节点时，只需要有新的创建好local  pv的k8s节点，并对bookie的StatefulSet扩容即可。
- pulsar proxy, broker等无状态服务，只需要有足够的数量的k8s节点，并在需要时按需扩容即可

因本文这里用于实验的k8s集群资源有限，所以尽量将上面各组件在3个k8s节点上混部，将一个用于测试环境的的Pulsar集群规划如下:

| k8s节点             | 部署pulsar组件                           | 备注                                          |
| ------------------- | ---------------------------------------- | --------------------------------------------- |
| node1               | zookeeper-0, bookie-0, broker-0, proxy-0 | 线上环境bookie和zookeeper一定要在单独的节点上 |
| node2               | zookeeper-1, bookie-1, broker-1, proxy-1 | 线上环境bookie和zookeeper一定要在单独的节点上 |
| node3               | zookeeper-2, bookie-2, broker-2, proxy-2 | 线上环境bookie和zookeeper一定要在单独的节点上 |
| node1或node2或node3 | recovery-0, toolset-0, pulsar-manager    |                                               |

基于上面测试环境的规划，我们将node1~node3三个节点打上Label和Taint:

```bash
kubectl label node node1 node-role.kubernetes.io/pulsar=pulsar
kubectl label node node2 node-role.kubernetes.io/pulsar=pulsar
kubectl label node node3 node-role.kubernetes.io/pulsar=pulsar
kubectl taint nodes node1 dedicated=pulsar:NoSchedule
kubectl taint nodes node2 dedicated=pulsar:NoSchedule
kubectl taint nodes node3 dedicated=pulsar:NoSchedule
```

- Label `node-role.kubernetes.io/pulsar=pulsar`用于标记节点是专门用于运行pulsar集群组件的k8s节点。
- Taint `dedicated=pulsar:NoSchedule`被打到节点上后，默认配置下k8s集群中的其他不属于pulsar集群组件的pod将不会被调度到这3个节点上，而后边我们将要部署的pulsar组件上将会使用Toleration配置允许`dedicated=pulsar:NoSchedule`的Taint。
- 注意这里只是根据测试环境Pulsar集群的规划，做了上面的Label和Taint的设置，如果是生产环境，这里的Label和Taint应该做更合理和细粒度的规划，确保实现上面生产可用Pulsar集群的Node节点规划

### 1.2 Pulsar集群组件容器镜像准备

前面我们选择要部署Pulsar集群的proxy, broker, bookie, zookeeper, recovery, toolset,  pulsar-manager 7大组件。

其中proxy, broker, bookie, zookeeper, recovery, toolset的官方容器镜像都是[apachepulsar/pulsar-all](https://hub.docker.com/r/apachepulsar/pulsar-all)。 pulsar-manager的官方镜像是[apachepulsar/pulsar-manager](https://hub.docker.com/r/apachepulsar/pulsar-manager)。

本文使用的pulsar官方的helm chart https://github.com/apache/pulsar-helm-chart/releases。

pulsar-helm-chart的版本为2.7.7，该版本中pulsar的版本为2.7.4, pulsar-manager版本为v0.1.0:

- apachepulsar/pulsar-all:2.7.4
- apachepulsar/pulsar-manager:v0.1.0

注意因为`pulsar-manager:v0.1.0`有这个ISSUE https://github.com/apache/pulsar-helm-chart/issues/133中描述的问题，所以在后边的部署将镜像`pulsar-manager:v0.1.0`更换成了`pulsar-manager:v0.2.0`。

为了提高效率，这里将apachepulsar/pulsar-all:2.7.4和apachepulsar/pulsar-manager:v0.2.0这两个镜像转存到了k8s集群所使用的私有镜像仓库中，例如:

- harbor.example.com/library/apachepulsar/pulsar-all:2.7.4
- harbor.example.com/library/apachepulsar/pulsar-manager:v0.2.0

### 1.3 创建JWT认证所需的K8S Secret

这里部署的Pulsar集群需要在安全上开通JWT认证。根据前面学习的内容，JWT支持通过两种不同的秘钥生成和验证Token:

- 对称秘钥：
  - 使用单个Secret key来生成和验证Token
- 非对称秘钥：包含由私钥和公钥组成的一对密钥
- 使用Private key生成Token
- 使用Public key验证Token

推荐使用非对称密钥的方式，需要先生成密钥对，再用秘钥生成token。因为Pulsar被部署在K8S集群中，在K8S集群中存储这些秘钥和Token的最好的方式是使用K8S的Secret。

pulsar-helm-chart专门提供了一个`prepare_helm_release.sh`脚本，可以用来生成这些Secret。

下面我们将pulsar-helm-chart的源码clone到K8S的控制节点上(kubectl和helm可用的节点):

```bash
git clone -b pulsar-2.7.7 --depth 1 https://github.com/apache/pulsar-helm-chart.git
cd pulsar-helm-chart/
```

执行下面的命令生成秘钥对和Token的Secret的Manifest:

```bash
./scripts/pulsar/prepare_helm_release.sh \
    -n pulsar \
    -k pulsar \
    -l
```

上面的命令中:

- `-n`指定的生成Secret Manifest中安装的命名空间，这里我是将其部署到K8S中的pulsar namespace中，所以指定为pulsar，当然也可以指定部署到其他的namespace中。
- `-k`指定的是使用helm部署时的helm release名称，这里指定为pulsar。
- `-l`指定只将生成的内容输出达到本地，而不会自动部署到K8S中。比较喜欢这种手动的方式，因为一切比较可控。
- 注意这个脚本还有一个`-s,--symmetric`参数，如果给这个参数的话，JWT认证将使用对称秘钥的方式，这里没有给这个参数，就使用非对称秘钥的方式。

执行上面的脚本会输出以下内容:

```bash
generate the token keys for the pulsar cluster
---
The private key and public key are generated to ... successfully.
apiVersion: v1
data:
  PRIVATEKEY: <...>
  PUBLICKEY: <...>
kind: Secret
metadata:
  creationTimestamp: null
  name: pulsar-token-asymmetric-key
  namespace: pulsar
generate the tokens for the super-users: proxy-admin,broker-admin,admin
generate the token for proxy-admin
---
pulsar-token-asymmetric-key
apiVersion: v1
data:
  TOKEN: <...>
  TYPE: YXN5bW1ldHJpYw==
kind: Secret
metadata:
  creationTimestamp: null
  name: pulsar-token-proxy-admin
  namespace: pulsar
generate the token for broker-admin
---
pulsar-token-asymmetric-key
apiVersion: v1
data:
  TOKEN: <...>
  TYPE: YXN5bW1ldHJpYw==
kind: Secret
metadata:
  creationTimestamp: null
  name: pulsar-token-broker-admin
  namespace: pulsar
generate the token for admin
---
pulsar-token-asymmetric-key
apiVersion: v1
data:
  TOKEN:  <...>
  TYPE: YXN5bW1ldHJpYw==
kind: Secret
metadata:
  creationTimestamp: null
  name: pulsar-token-admin
  namespace: pulsar
-------------------------------------

The jwt token secret keys are generated under:
    - 'pulsar-token-asymmetric-key'

The jwt tokens for superusers are generated and stored as below:
    - 'proxy-admin':secret('pulsar-token-proxy-admin')
    - 'broker-admin':secret('pulsar-token-broker-admin')
    - 'admin':secret('pulsar-token-admin')
```

从输出可以看出，该脚本生成了4个K8S Secret的Manifest:

- pulsar-token-asymmetric-key这个Secret中是用于生成Token和验证Token的私钥和公钥
- pulsar-token-proxy-admin这个Secret中是用于proxy的超级用户角色Token
- pulsar-token-broker-admin这个Secret中是用于broker的超级用户角色Token
- pulsar-token-admin这个Secret中是用于管理客户端的超级用户角色Token

接下来手动将这4个Secret使用`kubectl apply`创建到K8S的pulsar命名空间中。 创建完成后，可以使用kubectl找到它们:

```bash
kubectl get secret -n pulsar | grep pulsar-token
pulsar-token-admin                        Opaque                    2      5m
pulsar-token-asymmetric-key               Opaque                    2      5m
pulsar-token-broker-admin                 Opaque                    2      5m
pulsar-token-proxy-admin                  Opaque                    2      5m
```

### 1.4 创建Zookeeper和Bookie的Local PV

根据部署Pulsar的K8S节点的规划，下面需要为zookeeper, bookie所在的节点在K8S上创建Local Persistent Volume。

注意每个zookeeper节点需要一个data的local volume，每个bookie节点需要journal和ledgers共两个local volume。

在创建Local PV之前，需要确认一下k8s中存在StorageClass`local-storage`，如果没有可以使用下面的manifest创建。

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Retain
```

注意现在的K8S中不在直接提供local volume的provisioner，这里也没有使用provisioner，因此后续对local volume的创建和管理都是需要K8S集群管理员的手动进行。 也是说目前Kubernetes核心中不包含对对本地卷进行动态发放和管理的provisioner，如果想要体验动态发放和管理的功能，可以试一下由Rancher提供的[Local Path Provisioner](https://github.com/rancher/local-path-provisioner)。

我这里依然使用手动管理的方式，即通过手动在K8S节点上创建Local Volume，手动绑定Local Volume与Pulsar Zookeeper和Bookie的PVC(PersistentVolumeClaim)之间的关系。

下面，先手动在node1, node2, node3上创建local volume对应的数据目录:

```bash
mkdir -p /home/puslar/data/zookeeper-data
mkdir -p /home/puslar/data/bookie-data/ledgers
mkdir -p /home/puslar/data/bookie-data/journal
```

zookeeper data的local pv的manifest如下:

```yaml
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pulsar-zookeeper-data-pulsar-zookeeper-0
spec:
  capacity:
    storage: 20Gi 
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  local:
    path: /home/puslar/data/zookeeper-data
  claimRef:
    name: pulsar-zookeeper-data-pulsar-zookeeper-0
    namespace: pulsar
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - node1

---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pulsar-zookeeper-data-pulsar-zookeeper-1
spec:
  capacity:
    storage: 20Gi 
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  local:
    path: /home/puslar/data/zookeeper-data
  claimRef:
    name: pulsar-zookeeper-data-pulsar-zookeeper-1
    namespace: pulsar
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - node2


---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pulsar-zookeeper-data-pulsar-zookeeper-2
spec:
  capacity:
    storage: 20Gi 
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  local:
    path: /home/puslar/data/zookeeper-data
  claimRef:
    name: pulsar-zookeeper-data-pulsar-zookeeper-2
    namespace: pulsar
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - node3
```

上面的manifest仍中将3个Local PV通过`nodeAffinity`创建并关联到到node1~node3上，同时使用`claimRef`将这3个Local PV与即将在K8S集群中部署的zookeeper SatefulSet中的PVC绑定。 使用`kubectl apply`创建上面的manifest。

bookie ledgers和journal的local pv的manifest如下:

```yaml
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pulsar-bookie-ledgers-pulsar-bookie-0
spec:
  capacity:
    storage: 50Gi 
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  local:
    path: /home/puslar/data/bookie-data/ledgers
  claimRef:
    name: pulsar-bookie-ledgers-pulsar-bookie-0
    namespace: pulsar
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - node1
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pulsar-bookie-journal-pulsar-bookie-0
spec:
  capacity:
    storage: 50Gi 
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  local:
    path: /home/puslar/data/bookie-data/journal
  claimRef:
    name: pulsar-bookie-journal-pulsar-bookie-0
    namespace: pulsar
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - node1



---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pulsar-bookie-ledgers-pulsar-bookie-1
spec:
  capacity:
    storage: 50Gi 
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  local:
    path: /home/puslar/data/bookie-data/ledgers
  claimRef:
    name: pulsar-bookie-ledgers-pulsar-bookie-1
    namespace: pulsar
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - node2
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pulsar-bookie-journal-pulsar-bookie-1
spec:
  capacity:
    storage: 50Gi 
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  local:
    path: /home/puslar/data/bookie-data/journal
  claimRef:
    name: pulsar-bookie-journal-pulsar-bookie-1
    namespace: pulsar
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - node2




---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pulsar-bookie-ledgers-pulsar-bookie-2
spec:
  capacity:
    storage: 50Gi 
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  local:
    path: /home/puslar/data/bookie-data/ledgers
  claimRef:
    name: pulsar-bookie-ledgers-pulsar-bookie-2
    namespace: pulsar
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - node3
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pulsar-bookie-journal-pulsar-bookie-2
spec:
  capacity:
    storage: 50Gi 
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  local:
    path: /home/puslar/data/bookie-data/journal
  claimRef:
    name: pulsar-bookie-journal-pulsar-bookie-2
    namespace: pulsar
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - node3
```

上面的manifest仍中将6个Local PV通过`nodeAffinity`创建并关联到到node1~node3上，同时使用`claimRef`将这3个Local PV与即将在K8S集群中部署的zookeeper SatefulSet中的PVC绑定。 使用`kubectl apply`创建上面的manifest。

### 1.5 准备Pulsar Manager的PostgreSQL数据库

这里准备让Pulsar Manager使用外部数据库，需要提前在外部的PostgreSQL中创建好用户和数据库表结构。

创建数据库和用户:

```sql
CREATE USER pulsar_manager WITH PASSWORD '<password>';

CREATE DATABASE pulsar_manager OWNER pulsar_manager;

GRANT ALL PRIVILEGES ON DATABASE pulsar_manager to pulsar_manager;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA pulsar_manager TO pulsar_manager;
ALTER SCHEMA public OWNER to pulsar_manager;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO pulsar_manager;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO pulsar_manager;
```

创建表结构(建表脚本可以在pulsar-manager的镜像中找到):

上面已经做好了部署的准备工作，下面将使用Helm在K8S集群中部署Pulsar集群。

```plsql
CREATE TABLE IF NOT EXISTS environments (
  name varchar(256) NOT NULL,
  broker varchar(1024) NOT NULL,
  CONSTRAINT PK_name PRIMARY KEY (name),
  UNIQUE (broker)
);

CREATE TABLE IF NOT EXISTS topics_stats (
  topic_stats_id BIGSERIAL PRIMARY KEY,
  environment varchar(255) NOT NULL,
  cluster varchar(255) NOT NULL,
  broker varchar(255) NOT NULL,
  tenant varchar(255) NOT NULL,
  namespace varchar(255) NOT NULL,
  bundle varchar(255) NOT NULL,
  persistent varchar(36) NOT NULL,
  topic varchar(255) NOT NULL,
  producer_count BIGINT,
  subscription_count BIGINT,
  msg_rate_in double precision  ,
  msg_throughput_in double precision    ,
  msg_rate_out double precision ,
  msg_throughput_out double precision   ,
  average_msg_size double precision     ,
  storage_size double precision ,
  time_stamp BIGINT
);

CREATE TABLE IF NOT EXISTS publishers_stats (
  publisher_stats_id BIGSERIAL PRIMARY KEY,
  producer_id BIGINT,
  topic_stats_id BIGINT NOT NULL,
  producer_name varchar(255) NOT NULL,
  msg_rate_in double precision  ,
  msg_throughput_in double precision    ,
  average_msg_size double precision     ,
  address varchar(255),
  connected_since varchar(128),
  client_version varchar(36),
  metadata text,
  time_stamp BIGINT,
  CONSTRAINT fk_publishers_stats_topic_stats_id FOREIGN KEY (topic_stats_id) References topics_stats(topic_stats_id)
);

CREATE TABLE IF NOT EXISTS replications_stats (
  replication_stats_id BIGSERIAL PRIMARY KEY,
  topic_stats_id BIGINT NOT NULL,
  cluster varchar(255) NOT NULL,
  connected BOOLEAN,
  msg_rate_in double precision  ,
  msg_rate_out double precision ,
  msg_rate_expired double precision     ,
  msg_throughput_in double precision    ,
  msg_throughput_out double precision   ,
  msg_rate_redeliver double precision   ,
  replication_backlog BIGINT,
  replication_delay_in_seconds BIGINT,
  inbound_connection varchar(255),
  inbound_connected_since varchar(255),
  outbound_connection varchar(255),
  outbound_connected_since varchar(255),
  time_stamp BIGINT,
  CONSTRAINT FK_replications_stats_topic_stats_id FOREIGN KEY (topic_stats_id) References topics_stats(topic_stats_id)
);

CREATE TABLE IF NOT EXISTS subscriptions_stats (
  subscription_stats_id BIGSERIAL PRIMARY KEY,
  topic_stats_id BIGINT NOT NULL,
  subscription varchar(255) NULL,
  msg_backlog BIGINT,
  msg_rate_expired double precision     ,
  msg_rate_out double precision ,
  msg_throughput_out double precision   ,
  msg_rate_redeliver double precision   ,
  number_of_entries_since_first_not_acked_message BIGINT,
  total_non_contiguous_deleted_messages_range BIGINT,
  subscription_type varchar(16),
  blocked_subscription_on_unacked_msgs BOOLEAN,
  time_stamp BIGINT,
  UNIQUE (topic_stats_id, subscription),
  CONSTRAINT FK_subscriptions_stats_topic_stats_id FOREIGN KEY (topic_stats_id) References topics_stats(topic_stats_id)
);

CREATE TABLE IF NOT EXISTS consumers_stats (
  consumer_stats_id BIGSERIAL PRIMARY KEY,
  consumer varchar(255) NOT NULL,
  topic_stats_id BIGINT NOT NUll,
  replication_stats_id BIGINT,
  subscription_stats_id BIGINT,
  address varchar(255),
  available_permits BIGINT,
  connected_since varchar(255),
  msg_rate_out double precision ,
  msg_throughput_out double precision   ,
  msg_rate_redeliver double precision   ,
  client_version varchar(36),
  time_stamp BIGINT,
  metadata text
);

CREATE TABLE IF NOT EXISTS tokens (
  token_id BIGSERIAL PRIMARY KEY,
  role varchar(256) NOT NULL,
  description varchar(128),
  token varchar(1024) NOT NUll,
  UNIQUE (role)
);

CREATE TABLE IF NOT EXISTS users (
  user_id BIGSERIAL PRIMARY KEY,
  access_token varchar(256),
  name varchar(256) NOT NULL,
  description varchar(128),
  email varchar(256),
  phone_number varchar(48),
  location varchar(256),
  company varchar(256),
  expire BIGINT,
  password varchar(256),
  UNIQUE (name)
);

CREATE TABLE IF NOT EXISTS roles (
  role_id BIGSERIAL PRIMARY KEY,
  role_name varchar(256) NOT NULL,
  role_source varchar(256) NOT NULL,
  description varchar(128),
  resource_id BIGINT NOT NULL,
  resource_type varchar(48) NOT NULL,
  resource_name varchar(48) NOT NULL,
  resource_verbs varchar(256) NOT NULL,
  flag INT NOT NULL
);

CREATE TABLE IF NOT EXISTS tenants (
  tenant_id BIGSERIAL PRIMARY KEY,
  tenant varchar(255) NOT NULL,
  admin_roles varchar(255),
  allowed_clusters varchar(255),
  environment_name varchar(255),
  UNIQUE(tenant)
);

CREATE TABLE IF NOT EXISTS namespaces (
  namespace_id BIGSERIAL PRIMARY KEY,
  tenant varchar(255) NOT NULL,
  namespace varchar(255) NOT NULL,
  UNIQUE(tenant, namespace)
);

CREATE TABLE IF NOT EXISTS role_binding(
  role_binding_id BIGSERIAL PRIMARY KEY,
  name varchar(256) NOT NULL,
  description varchar(256),
  role_id BIGINT NOT NULL,
  user_id BIGINT NOT NULL
);
```

## 2.使用Helm在K8S中部署Pulsar

从https://github.com/apache/pulsar-helm-chart/releases下载pulsar helm chart 2.7.7到K8S的控制节点上(kubectl和helm可用)。

```bash
https://github.com/apache/pulsar-helm-chart/releases/download/pulsar-2.7.7/pulsar-2.7.7.tgz
```

### 2.1 定制编写helm chart的values.yaml

定制编写helm chart的values.yaml文件如下, 定制的内容比较多，具体见下面文件的注释:

```yaml
auth:
  authentication:
    enabled: true  # 开启jwt认证
    provider: "jwt"
    jwt:
      usingSecretKey: false # jwt认证使用非对称秘钥对
  authorization:
    enabled: true # 开启授权
  superUsers:
    # broker to broker communication
    broker: "broker-admin"
    # proxy to broker communication
    proxy: "proxy-admin"
    # pulsar-admin client to broker/proxy communication
    client: "admin"


components: # 启用的组件
  autorecovery: true
  bookkeeper: true
  broker: true
  functions: true
  proxy: true
  pulsar_manager: true
  toolset: true
  zookeeper: true

monitoring: # 关闭监控组件, 后续尝试使用外部Prometheus对pulsar集群进行监控
  grafana: false
  prometheus: false
  node_exporter: false


volumes:
  local_storage: true # 数据卷使用local storage



proxy: # proxy的配置(这里是测试环境, 将proxy也调度到node1或node2或node3)
  nodeSelector:
    node-role.kubernetes.io/pulsar: pulsar
  tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "pulsar"
    effect: "NoSchedule"
  configData:
     PULSAR_PREFIX_authenticateMetricsEndpoint: "false"


broker: # broker的配置(这里是测试环境, 将proxy也调度到node1或node2或node3)
  nodeSelector:
    node-role.kubernetes.io/pulsar: pulsar
  tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "pulsar"
    effect: "NoSchedule"
  

zookeeper: # broker的配置
  replicaCount: 3
  tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "pulsar"
    effect: "NoSchedule"
  volumes:
    data: # 配置使用local pv, 需要与前面手动创建的local pv信息一致
      local_storage: true
      size: 20Gi


bookkeeper: # bookkeeper的配置
  replicaCount: 3
  tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "pulsar"
    effect: "NoSchedule"
  volumes:
    journal: # 配置使用local pv, 需要与前面手动创建的local pv信息一致
      local_storage: true
      size: 50Gi
  ledgers:  # 配置使用local pv, 需要与前面手动创建的local pv信息一致
      local_storage: true
      size: 50Gi

pulsar_manager: # pulsar_manager的配置(这里是测试环境, 将pulsar_manager也调度到node1或node2或node3)
  replicaCount: 1
  admin:
    # 文档中描述这里是pulsar manager web界面登录用户密码，但实际上当使用外部PostgreSQL数据库时，这里需要指定PostgreSQL的数据库和密码，不知道是否是pulsar-helm-chart 2.7.7的问题
    user: pulsar_manager
    password: 05aM3Braz_M4RWpn
  configData:
    DRIVER_CLASS_NAME: org.postgresql.Driver
    URL: jdbc:postgresql://<ip>:5432/pulsar_manager
    # 文档中描述这里PostgreSQL数据库的密码，但实际上这里不能指定USERNAME和PASSWORD, 不知道是否是pulsar-helm-chart 2.7.7的问题
    # USERNAME: pulsar_manager
    # PASSWORD: 05aM3Braz_M4RWpn
    LOG_LEVEL: INFO
    ## 开启JWT认证后, 这里需要指定pulsar-token-admin这个Secret中的JWT Token
    JWT_TOKEN: <jwt token...>


autorecovery: # autorecovery的配置(这里是测试环境, 将autorecovery也调度到node1或node2或node3)
  replicaCount: 1
  nodeSelector:
    node-role.kubernetes.io/pulsar: pulsar
  tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "pulsar"
    effect: "NoSchedule"

toolset: # toolset的配置(这里是测试环境, 将toolset也调度到node1或node2或node3)
  replicaCount: 1
  nodeSelector:
    node-role.kubernetes.io/pulsar: pulsar
  tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "pulsar"
    effect: "NoSchedule"


images: # 对个组件使用私有镜像仓库的配置
  imagePullSecrets:
  - regsecret # 私有镜像仓库的image pull secret, 需要提前在k8s命名空间中创建
  autorecovery:
    repository: harbor.example.com/library/apachepulsar/pulsar-all
    tag: 2.7.4
  bookie:
    repository: harbor.example.com/library/apachepulsar/pulsar-all
    tag: 2.7.4
  broker:
    repository: harbor.example.com/library/apachepulsar/pulsar-all
    tag: 2.7.4
  functions:
    repository: harbor.example.com/library/apachepulsar/pulsar-all
    tag: 2.7.4
  proxy:
    repository: harbor.example.com/library/apachepulsar/pulsar-all
    tag: 2.7.4
  pulsar_manager:
    repository: harbor.example.com/library/apachepulsar/pulsar-manager
    tag: v0.2.0
  zookeeper:
    repository: harbor.example.com/library/apachepulsar/pulsar-all
    tag: 2.7.4

pulsar_metadata:
  component: pulsar-init
  image:
    # the image used for running `pulsar-cluster-initialize` job
    repository: harbor.example.com/library/apachepulsar/pulsar-all
    tag: 2.7.4
```

因为当前在pulsar-helm-chart 2.7.7  中好像不支持为pulsar-init设置私有仓库的imagePullSecret，所以下面为pulsar namespace中的default  servcieaccount 添加上imagePullSecret。

```bash
kubectl patch serviceaccount default -p '{"imagePullSecrets": [{"name": "regsecret"}]}' -n pulsar
```

### 2.2 使用helm install安装pulsar

定制完value.yaml之后，使用下面的命令向K8S集群部署pulsar。

```bash
helm install \
    --values values.yaml \
    --set initialize=true \
    --namespace pulsar \
    pulsar pulsar-2.7.7.tgz
```

安装完成后使用下面的命令查看一下两个初始化job pulsar-pulsar-init和pulsar-bookie-init的pod状态为Complete:

```bash
kubectl get pod -n pulsar  | grep init
pulsar-bookie-init--1-h65bp              0/1     Completed   0               5m14s
pulsar-pulsar-init--1-t4thq              0/1     Completed   0               5m5s
```

使用下面的命令查看一下pulsar集群各个组件的Pod状态全部都为Running:

```bash
kubectl get pod -n pulsar -l cluster=pulsar -o wide
NAME                                     READY   STATUS    RESTARTS      AGE   IP              NODE   NOMINATED NODE   READINESS GATES
pulsar-bookie-0                          1/1     Running   0             14m   10.244.226.91   node1    <none>           <none>
pulsar-bookie-1                          1/1     Running   0             14m   10.244.63.90    node2    <none>           <none>
pulsar-bookie-2                          1/1     Running   0             14m   10.244.46.92    node3    <none>           <none>
pulsar-broker-0                          1/1     Running   0             14m   10.244.226.90   node1    <none>           <none>
pulsar-broker-1                          1/1     Running   0             14m   10.244.63.89    node2    <none>           <none>
pulsar-broker-2                          1/1     Running   0             14m   10.244.46.90    node3    <none>           <none>
pulsar-proxy-0                           1/1     Running   0             14m   10.244.226.93   node1    <none>           <none>
pulsar-proxy-1                           1/1     Running   0             14m   10.244.63.91    node2    <none>           <none>
pulsar-proxy-2                           1/1     Running   0             14m   10.244.46.93    node3    <none>           <none>
pulsar-pulsar-manager-7b98666cff-5626f   1/1     Running   0             14m   10.244.63.88    node2    <none>           <none>
pulsar-recovery-0                        1/1     Running   0             14m   10.244.46.89    node3    <none>           <none>
pulsar-toolset-0                         1/1     Running   0             14m   10.244.46.91    node3    <none>           <none>
pulsar-zookeeper-0                       1/1     Running   0             14m   10.244.226.92   node1    <none>           <none>
pulsar-zookeeper-1                       1/1     Running   0             14m   10.244.63.92    node2    <none>           <none>
pulsar-zookeeper-2                       1/1     Running   0             13m   10.244.46.94    node3    <none>           <none>
```

如果后边调整了values.yaml，需要更新部署时，使用下面的命令:

```bash
helm upgrade pulsar pulsar-2.7.7.tgz \
    --namespace pulsar \
    -f values.yaml
```

### 2.3 在toolset pod中测试创建tenant, namespace和topic

toolset pod中包含了各种管理和测试pulsar的命令行工具，例如pulsar-admin, pulsar-client等。

下面进入toolset pod中，使用pulsar-admin命令行工具测试一下tenant, namespace和topic的创建，进一步确认pulsar集群工作正常。

```bash
kubectl exec -it -n pulsar pulsar-toolset-0 -- /bin/bash

bin/pulsar-admin tenants create test-tenant

bin/pulsar-admin tenants list
"public"
"pulsar"
"test-tenant"


bin/pulsar-admin namespaces create test-tenant/test-ns

bin/pulsar-admin namespaces list test-tenant
"test-tenant/test-ns"

bin/pulsar-admin topics create-partitioned-topic test-tenant/test-ns/test-topic -p 3

bin/pulsar-admin topics list-partitioned-topics test-tenant/test-ns
"persistent://test-tenant/test-ns/test-topic"
```

### 2.4 创建pulsar-manager的管理员用户并登录查看

下面测试一下pulsar manager是否可以使用。

前面使用helm chart部署的pulsar集群，在k8s中创建了下面7个Service。

```bash
kubectl get svc -l app=pulsar -n pulsar
NAME                    TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)                               AGE
pulsar-bookie           ClusterIP      None             <none>        3181/TCP,8000/TCP                     40m
pulsar-broker           ClusterIP      None             <none>        8080/TCP,6650/TCP                     40m
pulsar-proxy            LoadBalancer   10.104.105.137   <pending>     80:31970/TCP,6650:32631/TCP           40m
pulsar-pulsar-manager   LoadBalancer   10.110.207.9     <pending>     9527:32764/TCP                        40m
pulsar-recovery         ClusterIP      None             <none>        8000/TCP                              40m
pulsar-toolset          ClusterIP      None             <none>        <none>                                40m
pulsar-zookeeper        ClusterIP      None             <none>        8000/TCP,2888/TCP,3888/TCP,2181/TCP   40m
```

从上面命令的输出可以看出，bookie, broker, recovery, toolset,  zookeeper这5个Service的类型都是ClusterIP的，并且cluser-ip为None，都是Headless的Service，因为它们只需要在k8s集群内部使用。

pulsar-proxy和pulsar-pulsar-manager为LoadBalancer类型，并且都配置了NodePort，提供了从K8S集群外部访问的能力。

从集群外部访问pulsar-manager的地址是`http://node1:32764`，第一次访问pulsar manager之前，需要为其创建一个管理用户:

```bash
CSRF_TOKEN=$(curl http://node1:32764/pulsar-manager/csrf-token)
curl \
   -H 'X-XSRF-TOKEN: $CSRF_TOKEN' \
   -H 'Cookie: XSRF-TOKEN=$CSRF_TOKEN;' \
   -H "Content-Type: application/json" \
   -X PUT http://node1:32764/pulsar-manager/users/superuser \
   -d '{"name": "admin", "password": "pulsar", "description": "test", "email": "username@test.org"}'
```

上面的命令为pulsar-manager创建用户名为admin, 密码为pulsar的管理用户。使用该用户就可以登录pulsar manager。

![image-20220117232502908](https://gitee.com/er-huomeng/img/raw/master/img/image-20220117232502908.png)

> 备注, 在线上使用时，尽量避免以NodePort暴露服务，这里的pulsar-manager的Service可以修改为CluserIP类型，并关闭NodePort，同时创建Ingress，以Ingress+域名的形式暴露出来。 看了一下pulsar-helm-chart也是支持的，只是目前pulsar-helm-chart 2.7.7中创建Ingress时，使用的是`apiVersion: extensions/v1beta1` API，这个API从k8s 1.19被标记为废弃，在k8s 1.22已被移除。 所以要直接是使用pulsar-helm-chart创建Ingress的话，需要等待pulsar-helm-chart的更新。

## 参考

- https://github.com/apache/pulsar-helm-chart
- https://pulsar.apache.org/docs/zh-CN/kubernetes-helm/
- https://github.com/apache/pulsar-helm-chart/issues/133
- https://github.com/rancher/local-path-provisioner
- https://kubernetes.io/zh/docs/tasks/configure-pod-container/configure-service-account/