alertmanager.yml
```yml
global:
  resolve_timeout: 5m
# 所有报警信息进入后的根路由，用来设置报警的分发策略
  smtp_from: '1090239782@qq.com'
  smtp_smarthost: 'smtp.qq.com:465'
  smtp_auth_username: '1090239782@qq.com'
  smtp_auth_password: 'dmsitabajsjbhbda'
  smtp_require_tls: false
  smtp_hello: 'qq.com'
route:
# 这里的标签列表是接收到报警信息后的重新分组标签，例如，接收到的报警信息里面有许多具有 cluster=A 和 alertname=LatncyHigh 这样的标签的报警信息将会批量被聚合到一个分组里面
  group_by: ['alertname', 'cluster']
#当一个新的报警分组被创建后，需要等待至少group_wait时间来初始化通知，这种方式可以确保您能有足够的时间为同一分组来获取多个警报，然后一起触发这个报警信息
  group_wait: 30s
# 当第一个报警发送后，等待'group_interval'时间来发送新的一组报警信息。
  group_interval: 5m
# 如果一个报警信息已经发送成功了，等待'repeat_interval'时间来重新发送他们
  repeat_interval: 5m
# 默认的receiver：如果一个报警没有被一个route匹配，则发送给默认的接收器
  receiver: 'email'  # 优先使用default发送
receivers:
- name: 'email'
  email_configs:
  - to: '1090239782@qq.com'
    send_resolved: true
inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'dev', 'instance']
```