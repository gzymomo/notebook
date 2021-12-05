- [Prometheus中使用的告警规则](https://www.cnblogs.com/sanduzxcvbnm/p/14759693.html)

参考网站：https://awesome-prometheus-alerts.grep.to/rules

这个网站上有好多常用软件的告警规则，但是有些并不一定实用，有些使用起来会有错误，这里就把这些都给排除掉，只保留能使用的

结合文章：https://www.cnblogs.com/sanduzxcvbnm/p/13589792.html 来使用

## 1.prometheus自身的告警规则

```yaml
groups:
- name: prometheus_rules
  rules:
  - alert: PrometheusJobMissing
    expr: absent(up{job="prometheus"})
    for: 0m
    labels:
      severity: warning
    annotations:
      summary: Prometheus job missing (instance {{ $labels.instance }})
      description: "A Prometheus job has disappeared\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: PrometheusTargetMissing
    expr: up == 0
    for: 0m
    labels:
      severity: critical
    annotations:
      summary: Prometheus target missing (instance {{ $labels.instance }})
      description: "A Prometheus target has disappeared. An exporter might be crashed.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: PrometheusAllTargetsMissing
    expr: count by (job) (up) == 0
    for: 0m
    labels:
      severity: critical
    annotations:
      summary: Prometheus all targets missing (instance {{ $labels.instance }})
      description: "A Prometheus job does not have living target anymore.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: PrometheusConfigurationReloadFailure
    expr: prometheus_config_last_reload_successful != 1
    for: 0m
    labels:
      severity: warning
    annotations:
      summary: Prometheus configuration reload failure (instance {{ $labels.instance }})
      description: "Prometheus configuration reload error\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: PrometheusTooManyRestarts
    expr: changes(process_start_time_seconds{job=~"prometheus|pushgateway|alertmanager"}[15m]) > 2
    for: 0m
    labels:
      severity: warning
    annotations:
      summary: Prometheus too many restarts (instance {{ $labels.instance }})
      description: "Prometheus has restarted more than twice in the last 15 minutes. It might be crashlooping.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: PrometheusAlertmanagerConfigurationReloadFailure
    expr: alertmanager_config_last_reload_successful != 1
    for: 0m
    labels:
      severity: warning
    annotations:
      summary: Prometheus AlertManager configuration reload failure (instance {{ $labels.instance }})
      description: "AlertManager configuration reload error\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: PrometheusAlertmanagerConfigNotSynced
    expr: count(count_values("config_hash", alertmanager_config_hash)) > 1
    for: 0m
    labels:
      severity: warning
    annotations:
      summary: Prometheus AlertManager config not synced (instance {{ $labels.instance }})
      description: "Configurations of AlertManager cluster instances are out of sync\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: PrometheusNotConnectedToAlertmanager
    expr: prometheus_notifications_alertmanagers_discovered < 1
    for: 0m
    labels:
      severity: critical
    annotations:
      summary: Prometheus not connected to alertmanager (instance {{ $labels.instance }})
      description: "Prometheus cannot connect the alertmanager\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: PrometheusRuleEvaluationFailures
    expr: increase(prometheus_rule_evaluation_failures_total[3m]) > 0
    for: 0m
    labels:
      severity: critical
    annotations:
      summary: Prometheus rule evaluation failures (instance {{ $labels.instance }})
      description: "Prometheus encountered {{ $value }} rule evaluation failures, leading to potentially ignored alerts.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: PrometheusTemplateTextExpansionFailures
    expr: increase(prometheus_template_text_expansion_failures_total[3m]) > 0
    for: 0m
    labels:
      severity: critical
    annotations:
      summary: Prometheus template text expansion failures (instance {{ $labels.instance }})
      description: "Prometheus encountered {{ $value }} template text expansion failures\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: PrometheusRuleEvaluationSlow
    expr: prometheus_rule_group_last_duration_seconds > prometheus_rule_group_interval_seconds
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: Prometheus rule evaluation slow (instance {{ $labels.instance }})
      description: "Prometheus rule evaluation took more time than the scheduled interval. It indicates a slower storage backend access or too complex query.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: PrometheusNotificationsBacklog
    expr: min_over_time(prometheus_notifications_queue_length[10m]) > 0
    for: 0m
    labels:
      severity: warning
    annotations:
      summary: Prometheus notifications backlog (instance {{ $labels.instance }})
      description: "The Prometheus notification queue has not been empty for 10 minutes\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: PrometheusAlertmanagerNotificationFailing
    expr: rate(alertmanager_notifications_failed_total[1m]) > 0
    for: 0m
    labels:
      severity: critical
    annotations:
      summary: Prometheus AlertManager notification failing (instance {{ $labels.instance }})
      description: "Alertmanager is failing sending notifications\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: PrometheusTargetEmpty
    expr: prometheus_sd_discovered_targets == 0
    for: 0m
    labels:
      severity: critical
    annotations:
      summary: Prometheus target empty (instance {{ $labels.instance }})
      description: "Prometheus has no target in service discovery\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: PrometheusTargetScrapingSlow
    expr: prometheus_target_interval_length_seconds{quantile="0.9"} > 60
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: Prometheus target scraping slow (instance {{ $labels.instance }})
      description: "Prometheus is scraping exporters slowly\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: PrometheusLargeScrape
    expr: increase(prometheus_target_scrapes_exceeded_sample_limit_total[10m]) > 10
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: Prometheus large scrape (instance {{ $labels.instance }})
      description: "Prometheus has many scrapes that exceed the sample limit\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: PrometheusTargetScrapeDuplicate
    expr: increase(prometheus_target_scrapes_sample_duplicate_timestamp_total[5m]) > 0
    for: 0m
    labels:
      severity: warning
    annotations:
      summary: Prometheus target scrape duplicate (instance {{ $labels.instance }})
      description: "Prometheus has many samples rejected due to duplicate timestamps but different values\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: PrometheusTsdbCheckpointCreationFailures
    expr: increase(prometheus_tsdb_checkpoint_creations_failed_total[1m]) > 0
    for: 0m
    labels:
      severity: critical
    annotations:
      summary: Prometheus TSDB checkpoint creation failures (instance {{ $labels.instance }})
      description: "Prometheus encountered {{ $value }} checkpoint creation failures\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: PrometheusTsdbCheckpointDeletionFailures
    expr: increase(prometheus_tsdb_checkpoint_deletions_failed_total[1m]) > 0
    for: 0m
    labels:
      severity: critical
    annotations:
      summary: Prometheus TSDB checkpoint deletion failures (instance {{ $labels.instance }})
      description: "Prometheus encountered {{ $value }} checkpoint deletion failures\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: PrometheusTsdbCompactionsFailed
    expr: increase(prometheus_tsdb_compactions_failed_total[1m]) > 0
    for: 0m
    labels:
      severity: critical
    annotations:
      summary: Prometheus TSDB compactions failed (instance {{ $labels.instance }})
      description: "Prometheus encountered {{ $value }} TSDB compactions failures\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: PrometheusTsdbHeadTruncationsFailed
    expr: increase(prometheus_tsdb_head_truncations_failed_total[1m]) > 0
    for: 0m
    labels:
      severity: critical
    annotations:
      summary: Prometheus TSDB head truncations failed (instance {{ $labels.instance }})
      description: "Prometheus encountered {{ $value }} TSDB head truncation failures\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: PrometheusTsdbReloadFailures
    expr: increase(prometheus_tsdb_reloads_failures_total[1m]) > 0
    for: 0m
    labels:
      severity: critical
    annotations:
      summary: Prometheus TSDB reload failures (instance {{ $labels.instance }})
      description: "Prometheus encountered {{ $value }} TSDB reload failures\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: PrometheusTsdbWalCorruptions
    expr: increase(prometheus_tsdb_wal_corruptions_total[1m]) > 0
    for: 0m
    labels:
      severity: critical
    annotations:
      summary: Prometheus TSDB WAL corruptions (instance {{ $labels.instance }})
      description: "Prometheus encountered {{ $value }} TSDB WAL corruptions\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: PrometheusTsdbWalTruncationsFailed
    expr: increase(prometheus_tsdb_wal_truncations_failed_total[1m]) > 0
    for: 0m
    labels:
      severity: critical
    annotations:
      summary: Prometheus TSDB WAL truncations failed (instance {{ $labels.instance }})
      description: "Prometheus encountered {{ $value }} TSDB WAL truncation failures\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"
```

## 2.node主机的告警规则

```yaml
groups:
- name: node_rules
  rules:
  - alert: HostOutOfMemory
    expr: node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes * 100 < 10
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: Host out of memory (instance {{ $labels.instance }})
      description: "Node memory is filling up (< 10% left)\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: HostMemoryUnderMemoryPressure
    expr: rate(node_vmstat_pgmajfault[1m]) > 1000
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: Host memory under memory pressure (instance {{ $labels.instance }})
      description: "The node is under heavy memory pressure. High rate of major page faults\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: HostUnusualNetworkThroughputIn
    expr: sum by (instance) (rate(node_network_receive_bytes_total[2m])) / 1024 / 1024 > 100
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: Host unusual network throughput in (instance {{ $labels.instance }})
      description: "Host network interfaces are probably receiving too much data (> 100 MB/s)\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: HostUnusualNetworkThroughputOut
    expr: sum by (instance) (rate(node_network_transmit_bytes_total[2m])) / 1024 / 1024 > 100
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: Host unusual network throughput out (instance {{ $labels.instance }})
      description: "Host network interfaces are probably sending too much data (> 100 MB/s)\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: HostUnusualDiskReadRate
    expr: sum by (instance) (rate(node_disk_read_bytes_total[2m])) / 1024 / 1024 > 50
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: Host unusual disk read rate (instance {{ $labels.instance }})
      description: "Disk is probably reading too much data (> 50 MB/s)\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: HostUnusualDiskWriteRate
    expr: sum by (instance) (rate(node_disk_written_bytes_total[2m])) / 1024 / 1024 > 50
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: Host unusual disk write rate (instance {{ $labels.instance }})
      description: "Disk is probably writing too much data (> 50 MB/s)\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  # Please add ignored mountpoints in node_exporter parameters like
  # "--collector.filesystem.ignored-mount-points=^/(sys|proc|dev|run)($|/)".
  # Same rule using "node_filesystem_free_bytes" will fire when disk fills for non-root users.
  - alert: HostOutOfDiskSpace
    expr: (node_filesystem_avail_bytes * 100) / node_filesystem_size_bytes < 10 and ON (instance, device, mountpoint) node_filesystem_readonly == 0
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: Host out of disk space (instance {{ $labels.instance }})
      description: "Disk is almost full (< 10% left)\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  # Please add ignored mountpoints in node_exporter parameters like
  # "--collector.filesystem.ignored-mount-points=^/(sys|proc|dev|run)($|/)".
  # Same rule using "node_filesystem_free_bytes" will fire when disk fills for non-root users.
  - alert: HostDiskWillFillIn24Hours
    expr: (node_filesystem_avail_bytes * 100) / node_filesystem_size_bytes < 10 and ON (instance, device, mountpoint) predict_linear(node_filesystem_avail_bytes{fstype!~"tmpfs"}[1h], 24 * 3600) < 0 and ON (instance, device, mountpoint) node_filesystem_readonly == 0
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: Host disk will fill in 24 hours (instance {{ $labels.instance }})
      description: "Filesystem is predicted to run out of space within the next 24 hours at current write rate\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: HostOutOfInodes
    expr: node_filesystem_files_free{mountpoint ="/rootfs"} / node_filesystem_files{mountpoint="/rootfs"} * 100 < 10 and ON (instance, device, mountpoint) node_filesystem_readonly{mountpoint="/rootfs"} == 0
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: Host out of inodes (instance {{ $labels.instance }})
      description: "Disk is almost running out of available inodes (< 10% left)\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: HostInodesWillFillIn24Hours
    expr: node_filesystem_files_free{mountpoint ="/rootfs"} / node_filesystem_files{mountpoint="/rootfs"} * 100 < 10 and predict_linear(node_filesystem_files_free{mountpoint="/rootfs"}[1h], 24 * 3600) < 0 and ON (instance, device, mountpoint) node_filesystem_readonly{mountpoint="/rootfs"} == 0
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: Host inodes will fill in 24 hours (instance {{ $labels.instance }})
      description: "Filesystem is predicted to run out of inodes within the next 24 hours at current write rate\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: HostUnusualDiskReadLatency
    expr: rate(node_disk_read_time_seconds_total[1m]) / rate(node_disk_reads_completed_total[1m]) > 0.1 and rate(node_disk_reads_completed_total[1m]) > 0
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: Host unusual disk read latency (instance {{ $labels.instance }})
      description: "Disk latency is growing (read operations > 100ms)\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: HostUnusualDiskWriteLatency
    expr: rate(node_disk_write_time_seconds_total[1m]) / rate(node_disk_writes_completed_total[1m]) > 0.1 and rate(node_disk_writes_completed_total[1m]) > 0
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: Host unusual disk write latency (instance {{ $labels.instance }})
      description: "Disk latency is growing (write operations > 100ms)\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: HostHighCpuLoad
    expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[2m])) * 100) > 80
    for: 0m
    labels:
      severity: warning
    annotations:
      summary: Host high CPU load (instance {{ $labels.instance }})
      description: "CPU load is > 80%\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: HostCpuStealNoisyNeighbor
    expr: avg by(instance) (rate(node_cpu_seconds_total{mode="steal"}[5m])) * 100 > 10
    for: 0m
    labels:
      severity: warning
    annotations:
      summary: Host CPU steal noisy neighbor (instance {{ $labels.instance }})
      description: "CPU steal is > 10%. A noisy neighbor is killing VM performances or a spot instance may be out of credit.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  # 1000 context switches is an arbitrary number.
  # Alert threshold depends on nature of application.
  # Please read: https://github.com/samber/awesome-prometheus-alerts/issues/58
  - alert: HostContextSwitching
    expr: (rate(node_context_switches_total[5m])) / (count without(cpu, mode) (node_cpu_seconds_total{mode="idle"})) > 1000
    for: 0m
    labels:
      severity: warning
    annotations:
      summary: Host context switching (instance {{ $labels.instance }})
      description: "Context switching is growing on node (> 1000 / s)\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: HostSwapIsFillingUp
    expr: (1 - (node_memory_SwapFree_bytes / node_memory_SwapTotal_bytes)) * 100 > 80
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: Host swap is filling up (instance {{ $labels.instance }})
      description: "Swap is filling up (>80%)\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: HostSystemdServiceCrashed
    expr: node_systemd_unit_state{state="failed"} == 1
    for: 0m
    labels:
      severity: warning
    annotations:
      summary: Host systemd service crashed (instance {{ $labels.instance }})
      description: "systemd service crashed\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: HostPhysicalComponentTooHot
    expr: node_hwmon_temp_celsius > 75
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: Host physical component too hot (instance {{ $labels.instance }})
      description: "Physical hardware component too hot\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: HostNodeOvertemperatureAlarm
    expr: node_hwmon_temp_crit_alarm_celsius == 1
    for: 0m
    labels:
      severity: critical
    annotations:
      summary: Host node overtemperature alarm (instance {{ $labels.instance }})
      description: "Physical node temperature alarm triggered\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: HostRaidArrayGotInactive
    expr: node_md_state{state="inactive"} > 0
    for: 0m
    labels:
      severity: critical
    annotations:
      summary: Host RAID array got inactive (instance {{ $labels.instance }})
      description: "RAID array {{ $labels.device }} is in degraded state due to one or more disks failures. Number of spare drives is insufficient to fix issue automatically.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: HostRaidDiskFailure
    expr: node_md_disks{state="failed"} > 0
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: Host RAID disk failure (instance {{ $labels.instance }})
      description: "At least one device in RAID array on {{ $labels.instance }} failed. Array {{ $labels.md_device }} needs attention and possibly a disk swap\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: HostKernelVersionDeviations
    expr: count(sum(label_replace(node_uname_info, "kernel", "$1", "release", "([0-9]+.[0-9]+.[0-9]+).*")) by (kernel)) > 1
    for: 6h
    labels:
      severity: warning
    annotations:
      summary: Host kernel version deviations (instance {{ $labels.instance }})
      description: "Different kernel versions are running\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: HostOomKillDetected
    expr: increase(node_vmstat_oom_kill[1m]) > 0
    for: 0m
    labels:
      severity: warning
    annotations:
      summary: Host OOM kill detected (instance {{ $labels.instance }})
      description: "OOM kill detected\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: HostEdacCorrectableErrorsDetected
    expr: increase(node_edac_correctable_errors_total[1m]) > 0
    for: 0m
    labels:
      severity: info
    annotations:
      summary: Host EDAC Correctable Errors detected (instance {{ $labels.instance }})
      description: "Host {{ $labels.instance }} has had {{ printf \"%.0f\" $value }} correctable memory errors reported by EDAC in the last 5 minutes.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: HostEdacUncorrectableErrorsDetected
    expr: node_edac_uncorrectable_errors_total > 0
    for: 0m
    labels:
      severity: warning
    annotations:
      summary: Host EDAC Uncorrectable Errors detected (instance {{ $labels.instance }})
      description: "Host {{ $labels.instance }} has had {{ printf \"%.0f\" $value }} uncorrectable memory errors reported by EDAC in the last 5 minutes.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: HostNetworkReceiveErrors
    expr: rate(node_network_receive_errs_total[2m]) / rate(node_network_receive_packets_total[2m]) > 0.01
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: Host Network Receive Errors (instance {{ $labels.instance }})
      description: "Host {{ $labels.instance }} interface {{ $labels.device }} has encountered {{ printf \"%.0f\" $value }} receive errors in the last five minutes.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: HostNetworkTransmitErrors
    expr: rate(node_network_transmit_errs_total[2m]) / rate(node_network_transmit_packets_total[2m]) > 0.01
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: Host Network Transmit Errors (instance {{ $labels.instance }})
      description: "Host {{ $labels.instance }} interface {{ $labels.device }} has encountered {{ printf \"%.0f\" $value }} transmit errors in the last five minutes.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: HostNetworkInterfaceSaturated
    expr: (rate(node_network_receive_bytes_total{device!~"^tap.*"}[1m]) + rate(node_network_transmit_bytes_total{device!~"^tap.*"}[1m])) / node_network_speed_bytes{device!~"^tap.*"} > 0.8
    for: 1m
    labels:
      severity: warning
    annotations:
      summary: Host Network Interface Saturated (instance {{ $labels.instance }})
      description: "The network interface \"{{ $labels.interface }}\" on \"{{ $labels.instance }}\" is getting overloaded.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: HostConntrackLimit
    expr: node_nf_conntrack_entries / node_nf_conntrack_entries_limit > 0.8
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: Host conntrack limit (instance {{ $labels.instance }})
      description: "The number of conntrack is approching limit\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: HostClockSkew
    expr: (node_timex_offset_seconds > 0.05 and deriv(node_timex_offset_seconds[5m]) >= 0) or (node_timex_offset_seconds < -0.05 and deriv(node_timex_offset_seconds[5m]) <= 0)
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: Host clock skew (instance {{ $labels.instance }})
      description: "Clock skew detected. Clock is out of sync.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: HostClockNotSynchronising
    expr: min_over_time(node_timex_sync_status[1m]) == 0 and node_timex_maxerror_seconds >= 16
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: Host clock not synchronising (instance {{ $labels.instance }})
      description: "Clock not synchronising.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"
```

## 3.mysql告警规则

```yaml
groups:
- name: mysql_rules
  rules:
  - alert: MysqlDown
    expr: mysql_up == 0
    for: 0m
    labels:
      severity: critical
    annotations:
      summary: MySQL down (instance {{ $labels.instance }})
      description: "MySQL instance is down on {{ $labels.instance }}\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: MysqlTooManyConnections(>80%)
    expr: avg by (instance) (rate(mysql_global_status_threads_connected[1m])) / avg by (instance) (mysql_global_variables_max_connections) * 100 > 80
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: MySQL too many connections (> 80%) (instance {{ $labels.instance }})
      description: "More than 80% of MySQL connections are in use on {{ $labels.instance }}\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: MysqlHighThreadsRunning
    expr: avg by (instance) (rate(mysql_global_status_threads_running[1m])) / avg by (instance) (mysql_global_variables_max_connections) * 100 > 60
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: MySQL high threads running (instance {{ $labels.instance }})
      description: "More than 60% of MySQL connections are in running state on {{ $labels.instance }}\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: MysqlSlaveIoThreadNotRunning
    expr: mysql_slave_status_master_server_id > 0 and ON (instance) mysql_slave_status_slave_io_running == 0
    for: 0m
    labels:
      severity: critical
    annotations:
      summary: MySQL Slave IO thread not running (instance {{ $labels.instance }})
      description: "MySQL Slave IO thread not running on {{ $labels.instance }}\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: MysqlSlaveSqlThreadNotRunning
    expr: mysql_slave_status_master_server_id > 0 and ON (instance) mysql_slave_status_slave_sql_running == 0
    for: 0m
    labels:
      severity: critical
    annotations:
      summary: MySQL Slave SQL thread not running (instance {{ $labels.instance }})
      description: "MySQL Slave SQL thread not running on {{ $labels.instance }}\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: MysqlSlaveReplicationLag
    expr: mysql_slave_status_master_server_id > 0 and ON (instance) (mysql_slave_status_seconds_behind_master - mysql_slave_status_sql_delay) > 30
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: MySQL Slave replication lag (instance {{ $labels.instance }})
      description: "MySQL replication lag on {{ $labels.instance }}\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: MysqlSlowQueries
    expr: increase(mysql_global_status_slow_queries[1m]) > 0
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: MySQL slow queries (instance {{ $labels.instance }})
      description: "MySQL server mysql has some new slow query.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: MysqlInnodbLogWaits
    expr: rate(mysql_global_status_innodb_log_waits[15m]) > 10
    for: 0m
    labels:
      severity: warning
    annotations:
      summary: MySQL InnoDB log waits (instance {{ $labels.instance }})
      description: "MySQL innodb log writes stalling\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"

  - alert: MysqlRestarted
    expr: mysql_global_status_uptime < 60
    for: 0m
    labels:
      severity: info
    annotations:
      summary: MySQL restarted (instance {{ $labels.instance }})
      description: "MySQL has just been restarted, less than one minute ago on {{ $labels.instance }}.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"
```