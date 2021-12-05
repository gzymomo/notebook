- [AlertManager 之微信告警模板，UTC时间错8个小时的解决办法](https://www.cnblogs.com/sanduzxcvbnm/p/13724172.html)

## 注意事项：

alertmanager中的web页面显示的报警时间是UTC时间，错8个小时，企业微信报警模板中已经修改过来了

下面配置可以作为参考：

## 1.prometheus操作

### 1.1 配置告警规则

参考地址：https://www.cnblogs.com/sanduzxcvbnm/p/13589792.html，https://www.cnblogs.com/sanduzxcvbnm/p/14759693.html

### 1.2 修改告警通知发送的alertmanager地址

```yaml
# my global config
global:
  scrape_interval:     15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
  # scrape_timeout is set to the global default (10s).
  #external_labels: 
  #  origin_prometheus: prometheus
# Alertmanager configuration
alerting:
  alertmanagers:
  - static_configs:
    - targets: ['localhost:9093']

# Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
rule_files:
  - "rules/*.yml"
  # - "second_rules.yml"

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  - job_name: 'prometheus'

    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.

    static_configs:
    - targets: ['localhost:9090']

  - job_name: 'node'
    static_configs:
    - targets: ['localhost:9100']


  - job_name: 'mysql'
    static_configs:
    - targets: ['localhost:9104']
      labels:
        instance: park_single_db
```

![img](https://img2020.cnblogs.com/blog/794174/202105/794174-20210512171839604-591477881.png)

## 2.配置alertmanager

### 2.1 修改配置文件，设置告警参数

```yaml
# vim /etc/alertmanager/alertmanager.yml
global:
  resolve_timeout: 10m

templates:
  - 'config/*.tmpl'

route:
  group_by: ['alertname']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 12h
  receiver: 'wechat'

receivers:
- name: 'wechat'
  wechat_configs:
  - send_resolved: true
    wechat_api_url: 'https://qyapi.weixin.qq.com/cgi-bin/'
    wechat_api_corp_id: '企业id，在企业的配置页面可以看到'
    agent_id: '应用的AgentId，在应用的配置页面可以看到'
    api_secret: '应用的secret，在应用的配置页面可以看到'
    # 接收者或者是用户或者是部门，选一个就行
    to_user: '@all' 
    #to_party: ' PartyID1 | PartyID2 '
# 抑制作用可以不要
#inhibit_rules:
#  - source_match:
#      severity: 'critical'
#    target_match:
#      severity: 'warning'
#    equal: ['alertname', 'instance','job']
```

### 2.2 设置企业微信告警模板

如果不配置自定义模板，发出的消息会非常杂乱，我们自定义的配置模板示例如下：
 `vim /usr/local/alertmanager/config/wechat.tmpl`

```yaml
{{ define "wechat.default.message" }}
{{- if gt (len .Alerts.Firing) 0 -}}
{{- range $index, $alert := .Alerts -}}
{{- if eq $index 0 -}}
**********告警通知**********
告警类型: {{ $alert.Labels.alertname }}
告警级别: {{ $alert.Labels.severity }}
{{- end }}
=====================
告警主题: {{ $alert.Annotations.summary }}
告警详情: {{ $alert.Annotations.description }}
故障时间: {{ ($alert.StartsAt.Add 28800e9).Format "2006-01-02 15:04:05" }} # 注意这行，时间默认UTC 所以后边加入28800e9 也就是多了8个小时 
{{ if gt (len $alert.Labels.instance) 0 -}}故障实例: {{ $alert.Labels.instance }}{{- end -}}
{{- end }}
{{- end }}

{{- if gt (len .Alerts.Resolved) 0 -}}
{{- range $index, $alert := .Alerts -}}
{{- if eq $index 0 -}}
**********恢复通知**********
告警类型: {{ $alert.Labels.alertname }}
告警级别: {{ $alert.Labels.severity }}
{{- end }}
=====================
告警主题: {{ $alert.Annotations.summary }}
告警详情: {{ $alert.Annotations.description }}
故障时间: {{ ($alert.StartsAt.Add 28800e9).Format "2006-01-02 15:04:05" }} # 注意这行
恢复时间: {{ ($alert.EndsAt.Add 28800e9).Format "2006-01-02 15:04:05" }} # 注意这行
{{ if gt (len $alert.Labels.instance) 0 -}}故障实例: {{ $alert.Labels.instance }}{{- end -}}
{{- end }}
{{- end }}
{{- end }}
```

另一种解决UTC时间的办法

```yaml
{{ define "wechat.default.message" }}
{{- if gt (len .Alerts.Firing) 0 -}}
{{- range $index, $alert := .Alerts -}}
{{- if eq $index 0 -}}
**********告警通知**********
告警类型: {{ $alert.Labels.alertname }}
告警级别: {{ $alert.Labels.severity }}
{{- end }}
=====================
告警主题: {{ $alert.Annotations.summary }}
告警详情: {{ $alert.Annotations.description }}
故障时间: {{ $alert.StartsAt.Local.Format "2006-01-02 15:04:05" }} # 注意这行
{{ if gt (len $alert.Labels.instance) 0 -}}故障实例: {{ $alert.Labels.instance }}{{- end -}}
{{- end }}
{{- end }}

{{- if gt (len .Alerts.Resolved) 0 -}}
{{- range $index, $alert := .Alerts -}}
{{- if eq $index 0 -}}
**********恢复通知**********
告警类型: {{ $alert.Labels.alertname }}
告警级别: {{ $alert.Labels.severity }}
{{- end }}
=====================
告警主题: {{ $alert.Annotations.summary }}
告警详情: {{ $alert.Annotations.description }}
故障时间: {{ $alert.StartsAt.Local.Format "2006-01-02 15:04:05" }}
恢复时间: {{ $alert.EndsAt.Local.Format "2006-01-02 15:04:05" }}
{{ if gt (len $alert.Labels.instance) 0 -}}故障实例: {{ $alert.Labels.instance }}{{- end -}}
{{- end }}
{{- end }}
{{- end }}
```

两者比较
![img](https://img2020.cnblogs.com/blog/794174/202105/794174-20210517173906937-662723644.png)

## 重启应用

分析：

### 1.报警分组

根据告警规则中设置的规则，进行告警，相同的告警进行分组

```yaml
  group_by: ['alertname']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 12h
```

![img](https://img2020.cnblogs.com/blog/794174/202105/794174-20210512171403199-459159149.png)
 ![img](https://img2020.cnblogs.com/blog/794174/202105/794174-20210512171432350-179674593.png)

### 2.默认接收告警

receiver: 'wechat'
接收告警的可以根据告警来源，告警严重程度等进行分别发送告警，这个属于路由分组功能，具体参考：https://www.cnblogs.com/sanduzxcvbnm/p/14247590.html

### 3.receivers

这个是实际执行告警的，名称要跟上一步的保持一致
 ![img](https://img2020.cnblogs.com/blog/794174/202105/794174-20210512172834773-587587875.png)

### 4.抑制器

```yaml
# 抑制器配置
inhibit_rules: # 抑制规则
  - source_match: # 源标签警报触发时抑制含有目标标签的警报
      severity: 'critical'  # 此处的抑制匹配一定在最上面的route中配置不然，会提示找不key。
    target_match:
      everity: 'warning' # 目标标签值正则匹配，可以是正则表达式如: ".*MySQL.*"
    equal: ['alertname', 'instance',"job"] # 确保这个配置下的标签内容相同才会抑制，也就是说警报中必须有这三个标签值才会被抑制。
```

## 效果

###  1.单独的一个告警通知

 ![img](https://img2020.cnblogs.com/blog/794174/202105/794174-20210512174703557-1634492395.png)

### 2.有多条告警通知，但是分组合并在一个通知里发送

 ![img](https://img2020.cnblogs.com/blog/794174/202105/794174-20210512174806507-356233899.png)

​    