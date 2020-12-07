开始之前需要先安装一下 ingress 插件。ingress 作为 k8s 的流量入口，有多种实现。我知道的有 traefik，haproxy-ingress，ingress-nginx。今天以 ingress-nginx 为例来部署。

 

\1. 部署 ingress-nginx

1.1 由于网络的原因我们还是先拉取镜像。（每个节点都要拉取）

```
docker pull ninejy``/ingress-nginx-controller``:v0.41.0``docker tag ninejy``/ingress-nginx-controller``:v0.41.0 k8s.gcr.io``/ingress-nginx/controller``:v0.41.0
```

 

1.2 下载并修改 deploy.yaml 文件

```
wget https:``//raw``.githubusercontent.com``/kubernetes/ingress-nginx/controller-v0``.41.0``/deploy/static/provider/baremetal/deploy``.yaml``# 332 行 镜像后面的一串字符串去掉，因为我们的 docker tag 后面没跟这一串字符，（太长了 ^_^）
```

![img](https://img2020.cnblogs.com/blog/2216458/202012/2216458-20201204231212149-1752449010.png)

 

1.3 安装 ingress-nginx

```
kubectl apply -f deploy``/yaml` `kubectl get pod -n ingress-nginx``# 执行这个命令看到类似下图的内容就说明 ingress-nginx 安装成功了
```

![img](https://img2020.cnblogs.com/blog/2216458/202012/2216458-20201205133650420-1622821708.png)

 

\2. 部署 Java 应用到 k8s

2.1 创建 jenkins 任务

  jenkins 任务依然是 pipeline 风格的，下面是 pipeline file

```
pipeline {``  ``agent any``  ``stages {``    ``stage(``'clone code from gitlab'``) {``      ``steps {``        ``checkout([$``class``: ``'GitSCM'``,``        ``branches: [[name: ``"master"``]],``        ``userRemoteConfigs: [[``          ``credentialsId: ``'gitlab-robot'``,``          ``refspec: ``"+refs/heads/*:refs/remotes/origin/*"``,``          ``url: ``'ssh://git@192.168.0.11:8222/examples/spring-boot-helloworld.git'``]]``        ``])``      ``}``    ``}``    ``stage(``'mvn clean package'``) {``      ``steps {``        ``sh ``''``'``          ``mvn clean ``package` `-Dmaven.test.skip=true``        ``''``'``      ``}``      ` `    ``}``    ``stage(``'docker build && docker push'``) {``      ``steps {``        ``script{``          ``withDockerRegistry(credentialsId: ``'docker-hub'``, url: ``'https://index.docker.io/v1/'``) {``            ``def` `myappImage = docker.build ``"ninejy/examples-helloworld"``, ``"-f Dockerfile ."``            ``myappImage.push()``          ``}``        ``}``      ``}``    ``}``    ``stage(``'deploy to k8s'``) {``      ``steps {``        ``sh ``''``'``          ``kubectl apply -f /data/k8s-yaml/deploy-examples-helloworld.yaml``        ``''``'``      ``}``    ``}``    ``stage(``'clean dir'``) {``      ``steps {``        ``sh ``''``'``          ``echo ``"clean workspace"``        ``''``'``      ``}``      ``post {``        ``always {``          ``cleanDir()``        ``}``      ``}``    ``}``  ``}``}
```

 

deploy-examples-helloworld.yaml 的内容

```
apiVersion: apps``/``v1``kind: Deployment``metadata:`` ``name: examples``-``helloworld``spec:`` ``replicas: ``2`` ``selector:``  ``matchLabels:``   ``name: helloworld`` ``template:``  ``metadata:``   ``labels:``    ``name: helloworld``  ``spec:``   ``containers:``   ``-` `name: helloworld``    ``image: ninejy``/``examples``-``helloworld``    ``imagePullPolicy: IfNotPresent``    ``ports:``    ``-` `containerPort: ``8080``    ``readinessProbe:``     ``httpGet:``      ``port: ``8080``      ``path: ``/``healthy``     ``initialDelaySeconds: ``20``     ``periodSeconds: ``3``    ``livenessProbe:``     ``httpGet:``      ``port: ``8080``      ``path: ``/``healthy``     ``initialDelaySeconds: ``20``     ``periodSeconds: ``3``     ``timeoutSeconds: ``10``-``-``-``apiVersion: v1``kind: Service``metadata:`` ``name: examples``-``helloworld``-``svc``spec:`` ``ports:`` ``-` `port: ``80``  ``targetPort: ``8080``  ``protocol: TCP`` ``selector:``  ``name: helloworld``-``-``-``apiVersion: extensions``/``v1beta1``kind: Ingress``metadata:`` ``name: www.ninejy.io``spec:`` ``rules:`` ``-` `host: www.ninejy.io``  ``http:``   ``paths:``   ``-` `path: ``/``    ``backend:``     ``serviceName: examples``-``helloworld``-``svc``     ``servicePort: ``80
```

 

说明：

  \1. jenkins 服务器要能够访问 k8s 集群（网络通）

  \2. jenkins 服务器上有可用的 kubectl 命令

  \3. jenkins 服务器上在运行 jenkins 进程的用户家目录有访问 k8s 的有效凭证。~/.kube/config。这里为演示简单，直接拷贝 k8s-master 节点的文件。

  \4. 这里使用的 docker 镜像仓库是 hub.docker.com 网络很慢，可以自己搭建 harbor。

  \5. readinessProbe.initialDelaySeconds 这个值的设置很关键，这是 k8s 就绪检测的设置，由这个测试程序启动需要十几秒，所以这里设置了 20s，如果设置时间太短会导致容器多次重启最终达到最大重启次数，然后启动失败。

 

2.2 准备工作做好之后就可以手动执行 jenkins 任务了。jenkins 任务成功执行之后到 k8s-master 节点查看

```
kubectl get svc``kubectl get ingress``kubectl get pod
```

有类似下图的输出就说明部署成功了

![img](https://img2020.cnblogs.com/blog/2216458/202012/2216458-20201205133925514-1174929526.png)

 

2.3. 配置 nginx

  集群外部我们还需要安装一个 nginx 用来代理 ingress-nginx-controller

  先查看 ingress-nginx-controller 的 nodePort

```
kubectl get svc -n ingress-nginx
```

![img](https://img2020.cnblogs.com/blog/2216458/202012/2216458-20201205134015729-384410313.png)

 

nginx 配置文件，配置好之后记得重启 nginx 服务

```
# cat www-ninejy-io.conf``server {``  ``listen 80;``  ``server_name www.ninejy.io;` `  ``location / {``    ``proxy_set_header Host $host;``    ``proxy_pass http:``//192``.168.0.6:31901;``  ``}``  ` `  ``access_log ``/var/log/nginx/www-access``.log;``}
```

 

2.4 解析域名

  由于我的域名没有在dns服务器上解析，所以需要绑 hosts 访问

```
192.168.0.61 www.ninejy.io``# 上面这一行写到 hosts 文件中，注意换成自己的 k8s 集群外 nginx 服务器的IP
```

 

2.5 访问测试

  浏览器中输入：http://www.ninejy.io/hello

  有下面的结果就说明所有配置都成功了。

![img](https://img2020.cnblogs.com/blog/2216458/202012/2216458-20201205134151420-1756429942.png)