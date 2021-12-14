- [docker环境下数据库的备份(postgresql, mysql)](https://www.cnblogs.com/wang_yb/p/10880084.html)

## 1 posgresql 备份/恢复

1. 备份

	```bash
	DATE=`date +%Y%m%d-%H%M`
	BACK_DATA=xxapp-data-${DATE}.out  # 这里设置备份文件的名字, 加入日期是为了防止重复
	docker exec pg-db pg_dumpall -U postgres > ${BACK_DATA} # pg-db 是数据库的 docker 名称 
	```

2. 恢复

	```bash
	docker cp ${BACK_DATA} pg-db:/tmp
	docker exec pg-db psql -U postgres -f /tmp/${BACK_DATA} postgres
	```

## 2 mysql 备份/恢复

1. 备份

	```bash
	DATE=`date +%Y%m%d-%H%M`
	BACK_DATA=xxapp-data-${DATE}.sql
	# mysql-db 是数据库的 docker 名称, xxxpwd 是 root 用户密码, app-db 是要备份的数据名称
	docker exec mysql-db mysqldump  -uroot -pxxxpwd --databases app-db > ${BACK_DATA}
	```

2. 恢复 下面的 ${BACK_DATA} 要替换成实际生成的文件名称

	```bash
	docker cp ${BACK_DATA} mysql-db:/tmp 
	docker exec -it mysql-db mysql -uroot -pxxxpwd 
	mysql> source /tmp/${BACK_DATA}.sql
	mysql> \q
	Bye
	```

## 3 补充

postgresql 是备份所有数据库的, mysql 是备份某一个数据库.