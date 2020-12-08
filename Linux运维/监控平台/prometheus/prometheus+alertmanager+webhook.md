[TOC]

# 1、alertmanager
```bash
docker run -d --name alertmanager -p 9093:9093 -v /home/prometheus/alertmanager.yml:/etc/alertmanager/alertmanager.yml prom/alertmanager:latest
```

# 2、webhook
```bash
docker run -d -p 8060:8060 --name webhook timonwong/prometheus-webhook-dingtalk --ding.profile="webhook1=https://oapi.dingtalk.com/robot/send?access_token=钉钉token"
```

# 3、prometheus-config.yml
```yml
alerting:
  alertmanagers:
  - static_configs:
    - targets:
      - 192.168.0.50:9093
rule_files:
  - "/home/prometheus/rules/node_down.yml"                 # 实例存活报警规则文件
  - "/home/prometheus/rules/memory_over.yml"               # 内存报警规则文件
  - "/home/prometheus/rules/cpu_over.yml"                  # cpu报警规则文件
```