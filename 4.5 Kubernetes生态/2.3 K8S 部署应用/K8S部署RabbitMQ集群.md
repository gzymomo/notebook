- [k8s部署rabbitmq集群](https://blog.51cto.com/luoguoling/4714862)

## k8s安装rabbitmq集群

### 1.提前准备好动态存储managed-nfs-storage

### 2.创建命名空间middleware

```bash
kubectl create ns middleware
```

### 3.部署rabbitmq.yaml

```yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: rabbitmq
  namespace: middleware
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: endpoint-reader
  namespace: middleware
rules:
- apiGroups: [""]
  resources: ["endpoints"]
  verbs: ["get"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: endpoint-reader
  namespace: middleware
subjects:
- kind: ServiceAccount
  name: rabbitmq
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: endpoint-reader
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: rabbitmq-data-claim
  namespace: middleware
  annotations:
    volume.beta.kubernetes.io/storage-class: "managed-nfs-storage"
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 2Gi
---
#apiVersion: v1
#kind: PersistentVolumeClaim
#metadata:
#  name: rabbitmq-data-claim
#  namespace: middleware
#spec:
#  accessModes:
#    - ReadWriteMany
#  resources:
#    requests:
#      storage: 10Gi
#  selector:
#    matchLabels:
#      release: rabbitmq-data
---
# headless service 用于使用hostname访问pod
kind: Service
apiVersion: v1
metadata:
  name: rabbitmq-headless
  namespace: middleware
spec:
  clusterIP: None
  # publishNotReadyAddresses, when set to true, indicates that DNS implementations must publish the notReadyAddresses of subsets for the Endpoints associated with the Service. The default value is false. The primary use case for setting this field is to use a StatefulSet's Headless Service to propagate SRV records for its Pods without respect to their readiness for purpose of peer discovery. This field will replace the service.alpha.kubernetes.io/tolerate-unready-endpoints when that annotation is deprecated and all clients have been converted to use this field.
  # 由于使用DNS访问Pod需Pod和Headless service启动之后才能访问，publishNotReadyAddresses设置成true，防止readinessProbe在服务没启动时找不到DNS
  publishNotReadyAddresses: true
  ports:
   - name: amqp
     port: 5672
   - name: http
     port: 15672
  selector:
    app: rabbitmq
---
# 用于暴露dashboard到外网
kind: Service
apiVersion: v1
metadata:
  namespace: middleware
  name: rabbitmq-service
spec:
  type: NodePort
  ports:
   - name: http
     protocol: TCP
     port: 15672
     targetPort: 15672
     nodePort: 31672   # 注意k8s默认情况下，nodeport要在30000~32767之间，可以自行修改
   - name: amqp
     protocol: TCP
     port: 5672
     targetPort: 5672  # 注意如果你想在外网下访问mq，需要增配nodeport
     nodePort: 30739
  selector:
    app: rabbitmq
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: rabbitmq-config
  namespace: middleware
data:
  enabled_plugins: |
      [rabbitmq_management,rabbitmq_peer_discovery_k8s,rabbitmq_delayed_message_exchange].
  rabbitmq.conf: |
      cluster_formation.peer_discovery_backend  = rabbit_peer_discovery_k8s
      cluster_formation.k8s.host = kubernetes.default.svc.cluster.local
      cluster_formation.k8s.address_type = hostname
      cluster_formation.node_cleanup.interval = 10
      cluster_formation.node_cleanup.only_log_warning = true
      cluster_partition_handling = autoheal
      queue_master_locator=min-masters
      loopback_users.guest = false
      cluster_formation.randomized_startup_delay_range.min = 0
      cluster_formation.randomized_startup_delay_range.max = 2
      # 必须设置service_name，否则Pod无法正常启动，这里设置后可以不设置statefulset下env中的K8S_SERVICE_NAME变量
      cluster_formation.k8s.service_name = rabbitmq-headless
      # 必须设置hostname_suffix，否则节点不能成为集群
      cluster_formation.k8s.hostname_suffix = .rabbitmq-headless.middleware.svc.cluster.local
      # 内存上限
      vm_memory_high_watermark.absolute = 1.6GB
      # 硬盘上限
      disk_free_limit.absolute = 2GB
---
# 使用apps/v1版本代替apps/v1beta
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: rabbitmq
  namespace: middleware
spec:
  serviceName: rabbitmq-headless   # 必须与headless service的name相同，用于hostname传播访问pod
  selector:
    matchLabels:
      app: rabbitmq # 在apps/v1中，需与 .spec.template.metadata.label 相同，用于hostname传播访问pod，而在apps/v1beta中无需这样做
  replicas: 3
  template:
    metadata:
      labels:
        app: rabbitmq  # 在apps/v1中，需与 .spec.selector.matchLabels 相同
      # 设置podAntiAffinity
      annotations:
        scheduler.alpha.kubernetes.io/affinity: >
            {
              "podAntiAffinity": {
                "requiredDuringSchedulingIgnoredDuringExecution": [{
                  "labelSelector": {
                    "matchExpressions": [{
                      "key": "app",
                      "operator": "In",
                      "values": ["rabbitmq"]
                    }]
                  },
                  "topologyKey": "kubernetes.io/hostname"
                }]
              }
            }
    spec:
      serviceAccountName: rabbitmq
      terminationGracePeriodSeconds: 10
      imagePullSecrets:
      - name: harbor
      containers:
      - name: rabbitmq
        image: rabbitmq:3.7
        #image: harbor.middleware.local/images/rabbitmq:0.0.2
        #image: harbor.middleware.local/images/rabbitmq-delayed-message-exchange
        #image: qjpoo/rabbitmq:0.0.2
        #image: rabbitmq
        imagePullPolicy: IfNotPresent
        resources:
          limits:
            cpu: 1
            memory: 2Gi
          requests:
            cpu: 0.2
            memory: 0.512Gi
        volumeMounts:
          - name: config-volume
            mountPath: /etc/rabbitmq
          - name: rabbitmq-data
            mountPath: /var/lib/rabbitmq/mnesia
          - mountPath: /etc/localtime
            name: timezone
        ports:
          - name: http
            protocol: TCP
            containerPort: 15672
          - name: amqp
            protocol: TCP
            containerPort: 5672
        livenessProbe:
          exec:
            command: ["rabbitmqctl", "status"]
          initialDelaySeconds: 60
          periodSeconds: 60
          timeoutSeconds: 5
        readinessProbe:
          exec:
            command: ["rabbitmqctl", "status"]
          initialDelaySeconds: 20
          periodSeconds: 60
          timeoutSeconds: 5
        env:
          - name: HOSTNAME
            valueFrom:
              fieldRef:
                fieldPath: metadata.name
          - name: RABBITMQ_USE_LONGNAME
            value: "true"
          - name: RABBITMQ_NODENAME
            value: "rabbit@$(HOSTNAME).rabbitmq-headless.middleware.svc.cluster.local"
          # 若在ConfigMap中设置了service_name，则此处无需再次设置
          # - name: K8S_SERVICE_NAME
          #   value: "rabbitmq-headless"
          - name: RABBITMQ_ERLANG_COOKIE
            value: "mycookie"
      volumes:
        - name: config-volume
          configMap:
            name: rabbitmq-config
            items:
            - key: rabbitmq.conf
              path: rabbitmq.conf
            - key: enabled_plugins
              path: enabled_plugins
        - name: timezone
          hostPath:
            path: /usr/share/zoneinfo/Asia/Shanghai
        #- name: rabbitmq-data
        #  persistentVolumeClaim:
        #    claimName: rabbitmq-data-claim
  volumeClaimTemplates:
  - metadata:
      name: rabbitmq-data
      annotations:
        volume.beta.kubernetes.io/storage-class: managed-nfs-storage
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 10Gi
```

### 4.部署结果

![1V`_1D~7OHIIE7MZR9G.png](https://s2.51cto.com/images/20211129/1638174965317020.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)

### 5.修改策略(镜像集群设置)

![image.png](https://s2.51cto.com/images/20211129/1638180847485492.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)

### 6.结果展示

![image.png](https://s2.51cto.com/images/20211129/1638180907797316.png?x-oss-process=image/watermark,size_14,text_QDUxQ1RP5Y2a5a6i,color_FFFFFF,t_100,g_se,x_10,y_10,shadow_20,type_ZmFuZ3poZW5naGVpdGk=)

## go程序测试集群

### recv.go

```go
package main
import (
    "fmt"
    "github.com/streadway/amqp"
    "log"
)
func failOnError1(err error,msg string)  {
    if err!=nil{
        log.Fatalf("%s: %s",msg,err)
    }
}
func main() {
    conn,err := amqp.Dial("amqp://user@password@xxxxxx:30739/")
    failOnError1(err,"failed to connect to Rabbitmq")
    defer conn.Close()
    ch,err := conn.Channel()
    failOnError1(err,"failed to open a channel")

    failOnError1(err,"failed to declare queue")
    msg, err := ch.Consume(
        "test",
        "",
        true,
        false,
        false,
        false,
        nil,

        )
    failOnError1(err, "Failed to register a consumer")
    forerver := make(chan bool)
    go func() {
        fmt.Println(msg)
        for d := range msg{
            log.Printf("Received a message",d.Body,d.ContentType,d.ConsumerTag)
        }
    }()
    log.Printf("[*] waiting for message,to exit press CTRL+C")
    <- forerver
}
```

### send.go

```go
package main

import (
    "github.com/streadway/amqp"
    "log"
)

func failOnError(err error,msg string)  {
    if err!=nil{
        log.Fatalf("%s: %s",msg,err)
    }

}
func main() {
    conn,err := amqp.Dial("amqp://user:password@xxx:30739/")
    failOnError(err,"failed to connect to Rabbitmq")
    defer conn.Close()
    ch,err := conn.Channel()
    failOnError(err,"failed to open a channel")
//已经在控制台设置了队列属性
    //q,err := ch.QueueDeclare(
    //  "hello22",
    //  true,  //队列持久化
    //  false, //取消自动删除
    //  false,
    //  false,
    //  nil,
    //  )
    //fmt.Println(q.Name,q.Consumers,q.Messages)
    failOnError(err,"failed to declare queue")
    //body := "hello world"
    for i:=0;i<5000;i++ {
        body := string(i) + "hello world"
        err = ch.Publish(
            //"test",
            "",
            "test",
            false,
            false,
            amqp.Publishing{
                ContentType: "text/plain",
                Body:        []byte(body),
                DeliveryMode: 2,   //消息持久化
            })

        log.Printf("[x] Sent %s", body)
        failOnError(err, "failed to publish")
    }
}
```