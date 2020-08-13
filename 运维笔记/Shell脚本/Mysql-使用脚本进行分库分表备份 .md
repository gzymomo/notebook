Mysql-使用脚本进行分库分表备份
```sql
[root@ctos3 ~]# cat bak.sh
#!/bin/bash

MYUSER="root"
MYPASS="guoke123"
MYLOG="mysql -u$MYUSER -p$MYPASS -e"
MYDUMP="mysqldump -u$MYUSER -p$MYPASS -x -F"
DBLIST=$($MYLOG  "show databases;" | sed 1d | grep -Ev 'info|mysq|per|sys')
DIR=/backup
[ ! -d $DIR ] && mkdir $DIR
cd $DIR

for dbname in $DBLIST
do
 TABLIST=$($MYLOG "show tables from $dbname;" | sed 1d)
for tabname in $TABLIST
do
  mkdir -p $DIR/$dbname
   $MYDUMP $dbname $tabname  --events |gzip > $DIR/${dbname}/${tabname}_$(date +%F_%T).sql.gz
done
done
```