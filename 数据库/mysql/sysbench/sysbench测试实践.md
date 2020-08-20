

prepare:
sysbench /opt/sysbench/src/lua/oltp_read_write.lua --tables=3 --table_size=10000 --mysql-user=root --mysql-password=123456 --mysql-host=192.168.0.140 --mysql-port=3308 --mysql-db=systench prepare

run:
sysbench /opt/sysbench/src/lua/oltp_point_select.lua --tables=3 --table_size=10000 --mysql-user=root --mysql-password=123456 --mysql-host=192.168.0.140 --mysql-port=3308 --mysql-db=systench --threads=128 --time=100 --report-interval=5 run

cleanup:
sysbench /opt/sysbench/src/lua/oltp_read_write.lua --tables=3 --table_size=10000 --mysql-user=root --mysql-password=123456 --mysql-host=192.168.0.140 --mysql-port=3308 --mysql-db=systench cleanup


SQL statistics:
    queries performed:
        read:                            6431410	#总的select数量
        write:                           0
        other:                           0
        total:                           6431410
    transactions:                        6431410 (64304.16 per sec.)	#TPS
    queries:                             6431410 (64304.16 per sec.)	#QPS
    ignored errors:                      0      (0.00 per sec.)
    reconnects:                          0      (0.00 per sec.)

Throughput:
    events/s (eps):                      64304.1641		#每秒的事件数，一般和TPS一样
    time elapsed:                        100.0155s		#测试的总时间
    total number of events:              6431410		#总的事件数，一般和TPS一样

Latency (ms):
         min:                                    0.12		#最小响应时间
         avg:                                    1.99		#平均响应时间
         max:                                  344.55		#最大响应时间
         95th percentile:                        2.18		#95%的响应时间是这个数据
         sum:                             12790616.97

Threads fairness:
    events (avg/stddev):           50245.3906/532.06
    execution time (avg/stddev):   99.9267/0.04	#在这个测试中，可以看到TPS与QPS的大小基本一致，说明这个lua脚本中的一个查询一般就是一个事务！
