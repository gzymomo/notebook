- [使用velero去备份k8s集群](https://www.e-learn.cn/topic/3888604)

#### velero安装

1. 下载velero

   ```
   wget https://github.com/vmware-tanzu/velero/releases/download/v1.5.2/velero-v1.5.2-linux-amd64.tar.gz
   tar -zxvf velero-v1.5.2-linux-amd64.tar.gz
   mvmv velero-v1.5.2-linux-amd64 velero
   cd velero
   cp velero  /usr/local/bin/
   velero version
   [root@docker1 velero]# velero  version
   Client:
   Version: v1.5.2
   Git commit: e115e5a191b1fdb5d379b62a35916115e77124a4
   Server:
   Version: v1.5.2
   ```

2. 命令补全

   类k8s命令补全。

   ```
   source  <(velero completion )
   ```

#### 部署velero服务

​       由于默认minion只暴露了clusterip，但是通过velero命令时，实际上会本地主机产生交互，所以我暴露出了velero主机的nodeport。

1. 修改配置文件。

   进入example/minio，修改minio配置文件。修改type类型为nodePort。（我此处指定了nodePort地址，为了避免冲突最好不要指定）

   ```
   kind: Service
   metadata:
    namespace: velero
    name: minio
    labels:
      component: minio
   spec:
    # ClusterIP is recommended for production environments.
    # Change to NodePort if needed per documentation,
    # but only if you run Minio in a test/trial environment, for example with Minikube.
    type: NodePort
    ports:
      - port: 9000
        targetPort: 9000
        protocol: TCP
        nodePort: 30069
    selector:
      component: minio
   ```

2. k8s部署minio服务。

   ```
   kubectl apply -f 00-minio-deployment.yaml
   [root@docker1 minio]# kubectl get pod -n velero | grep minio
   minio-d787f4bf7-tltb4     1/1     Running     0          31m
   minio-setup-kjfc7         0/1     Completed   0          31m
   [root@docker1 minio]# kubectl get svc -n velero
   NAME    TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
   minio   NodePort   10.96.213.187   <none>        9000:30069/TCP   31m
   ```

3. 创建velero-specific文件,放在minio目录下。

   ```
   cat > credentials-velero << EOF
   [default]
   aws_access_key_id = minio
   aws_secret_access_key = minio123
   EOF
   ```

4. 部署velero服务

   使用publicURL暴露minio服务暴露的nodeport地址。host地址是k8s集群中任意node地址(反正是k8s集群进行解析)。

   ```
   velero install \
      --provider aws \
      --plugins velero/velero-plugin-for-aws:v1.0.0 \
      --bucket velero \
      --secret-file ./credentials-velero \
      --use-volume-snapshots=false \
      --backup-location-config region=minio,s3ForcePathStyle="true",s3Url=http://minio.velero.svc:9000,publicUrl=http://192.168.14.132:30069
   ```

5. 查看velero状态

   ```
   Deployment/velero: created
   Velero is installed! ⛵ Use 'kubectl logs deployment/velero -n velero' to view the status.
   
   [root@docker1 minio]# kubectl logs deployment/velero -n velero
   time="2020-10-28T06:25:22Z" level=info msg="setting log-level to INFO" logSource="pkg/cmd/server/server.go:191"
   time="2020-10-28T06:25:22Z" level=info msg="Starting Velero server v1.5.2 (456eb19668f8da603756353d9179b59b5a7bfa04)" logSource="pkg/cmd/server/server.go:193"
   time="2020-10-28T06:25:22Z" level=info msg="1 feature flags enabled []" name=velero.io/add-pvc-from-pod
   ```

6. 访问velero网页 .

   浏览器打开http://192.168.14.132:30069

   ![image.png](https://i.loli.net/2020/10/28/VMGxvIiA9ZWPaB7.png)

7. 部署example nginx 应用

   ```
   kubectl apply -f examples/nginx-app/base.yaml
   ```

8. 查看应用状态

   ```
   [root@docker1 minio]# kubectl get deployments -l component=velero --namespace=velero
   NAME     READY   UP-TO-DATE   AVAILABLE   AGE
   velero   1/1     1            1           9m16s
   [root@docker1 minio]# kubectl get deployments --namespace=nginx-example
   NAME               READY   UP-TO-DATE   AVAILABLE   AGE
   nginx-deployment   2/2     2            2           20h
   ```

### 备份应用

1. 根据标签选择器创建备份。

   ```
   velero backup create nginx-backup --selector app=nginx
   ```

2. 查看备份结果

   ![image.png](https://i.loli.net/2020/10/28/sEZcu3KhYTjwm2P.png)

   ```
   [root@docker1 minio]# velero backup describe nginx-backup
   Name:         nginx-backup
   Namespace:    velero
   Labels:       velero.io/storage-location=default
   Annotations:  velero.io/source-cluster-k8s-gitversion=v1.17.0
                velero.io/source-cluster-k8s-major-version=1
                velero.io/source-cluster-k8s-minor-version=17
   
   Phase:  Completed
   
   Errors:    0
   Warnings:  0
   
   Namespaces:
    Included:  *
    Excluded:  <none>
   ```

3. 恶意删除nginx-example:

   ```
   kubectl delete namespace nginx-example
   ```

4. 检查nginx deployment状态:

   ```
   [root@docker1 minio]# kubectl get deployments --namespace=nginx-example
   NAME               READY   UP-TO-DATE   AVAILABLE   AGE
   nginx-deployment   2/2     2            2           20h
   [root@docker1 minio]# kubectl get services --namespace=nginx-example
   NAME       TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)        AGE
   my-nginx   LoadBalancer   10.96.129.10   192.168.14.162   80:32741/TCP   20h
   [root@docker1 minio]# kubectl get namespace/nginx-example
   NAME            STATUS   AGE
   nginx-example   Active   20h
   ```

### 故障恢复

1. 运行恢复命令

   ```
   velero restore create --from-backup nginx-backup
   ```

2. 查看恢复状态

   ```
   [root@docker1 minio]# velero restore get
   NAME                          BACKUP         STATUS      STARTED                         COMPLETED                       ERRORS   WARNINGS   CREATED                         SELECTOR
   nginx-backup-20201028145528   nginx-backup   Completed   2020-10-28 14:55:28 +0800 CST   2020-10-28 14:55:28 +0800 CST   0        7          2020-10-28 14:55:28 +0800 CST   <none>
   ```

   NOTE: 恢复期间， `STATUS` 栏的状态为 `InProgress`.

3. 查看集群状态：

   ```
   [root@docker1 minio]# kubectl get services --namespace=nginx-example
   NAME       TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)        AGE
   my-nginx   LoadBalancer   10.96.177.151   192.168.14.162   80:30813/TCP   2m8s
   [root@docker1 minio]# kubectl get namespace/nginx-example
   NAME            STATUS   AGE
   nginx-example   Active   2m9s
   ```

### 清理velero

1. 删除velero备份

   ```
   velero backup delete nginx-backup 
   ```

2. 查看备份情况

   ```
   velero backup get nginx-backup 
   ```

3. 清除velro集群

   ```
   kubectl delete namespace/velero clusterrolebinding/velero
   kubectl delete crds -l component=velero
   kubectl delete -f examples/nginx-app/base.yaml
   ```

### 报错记录

velero是安装到本地命令行的，本地的dns解析是公司内部域IP。所以当velero备份的时候，没有找k8s集群的dns。velero安装指定publicURL即可。

![image.png](https://i.loli.net/2020/10/28/DOHuLxZR15Ywsz2.png)

### 参考

[Using Velero to backup and restore applications that use vSAN File Service RWX file shares](https://cormachogan.com/2020/05/27/using-velero-to-backup-and-restore-applications-using-vsan-file-service-rwx-file-shares/)

[Quick start evaluation install with Minio](https://velero.io/docs/v1.5/contributions/minio/)