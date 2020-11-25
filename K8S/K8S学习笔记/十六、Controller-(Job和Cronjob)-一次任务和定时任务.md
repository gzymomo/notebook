# Controller-Job和Cronjob-一次性任务和定时任务



## job - 一次性任务

```yaml
apiVersion: batch/v1
kind: job
metadata:
  ...............
```

```bash
# 创建一次性任务
kubectl create -f job.yaml

# 查看
kubectl get pods
#执行完成后，状态Status会变为Completed

#删除任务
kubectl delete -f job.yaml
```



## cronjob - 定时任务

```yaml
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: hello
spec:
  schedule: "*/1 * * * *"
.................
```



```bash
#创建任务
kubectl applf -y cronjob.yaml

#查看
kubectl get pods
```



