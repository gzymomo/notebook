- [DataX全量、增量、已删除数据同步方案与实际运用 - yangkang666 - 博客园 (cnblogs.com)](https://www.cnblogs.com/simple-young/p/16295488.html)

# 本文目的

DataX 是一款可以实现异构数据库间离线数据同步的工具，本文重点将使用DataX做一个oracle到mysql的数据同步，其中会借助datax-web进行可视化配置。
使用场景简单讲下：客户提供了oracle前置库，我们系统每天需要定时从前置库将数据同步到我们自己的mysql数据库。
本文不再细说如何使用datax和data-web，直接从问题的角度触发，主要记录下问题解决思路和办法，欢迎大家指正和探讨！！！

# 1.datax-web部分

## 1.1 Oracle数据源测试成功，但是任务构建提示表不存在

任务构建时，数据源选择oracle，提示表不存在、Schema没有任何选项、数据库表没有显示等类似的问题都可能与datax-web有关。
根据浏览器的请求分析下datax-web的源码
![img](https://img2022.cnblogs.com/blog/1507236/202205/1507236-20220521162546757-1358394714.png)
找到对应接口的查询如下：

```typescript
    @Override
    public String getSQLQueryTables(String... tableSchema) {
        return "select table_name from dba_tables where owner='" + tableSchema[0] + "'";
    }

    @Override
    public String getSQLQueryTableSchema(String... args) {
        return "select username from sys.dba_users";
    }
```

根据sql应该可以分析出来问题了，授予对应的权限应该就可以了。或者直接修改源码（有点麻烦不建议）
参考大神和原作者的issue回复修改源码如下：

```typescript
@Override
    public String getSQLQueryTables(String... tableSchema) {
        return "select owner||'.'||table_name as table_name from all_tables where owner='" + tableSchema[0] + "' union " +
                "select owner||'.'||view_name as table_name from all_views where owner='" + tableSchema[0] + "' order by table_name";
    }

    @Override
    public String getSQLQueryTableSchema(String... args) {
        return "select distinct t.owner from user_tab_privs t";
    }
```

重新打包替换datax-admin的包重启就可以了。 申请权限和修改代码二选一

# 2.DataX部分

## 2.1同步数据乱码

jdbcUrl加上指定编码配置即可

## 2.2数据更新问题(主键冲突)：writeMode

默认writeMode为insert，此情况下只能新增数据，有主键冲突就会报错，此时需要设置为写入模式为更新模式（replace）。源码mysqlwriter.md中有解释如下：

```markdown
* writeMode
* 描述：控制写入数据到目标表采用 `insert into` 或者 `replace into` 或者 `ON DUPLICATE KEY UPDATE` 语句<br />
* 必选：是 <br />
* 所有选项：insert/replace/update <br />
* 默认值：insert<br />
```

mysql比较特殊的写入模式配置为`"writeMode": "update"`，其他数据库需要酌情配置为`"writeMode": "replace"`

## 2.3增量同步（根据日期）

按日期进行同步，在reader.parameter增加“where”参数，里面就是需要过滤的数据，例子是只同步30天以内的数据

```bash
"where": "CREATE_TIME > TO_CHAR(TO_DATE(SYSDATE - 30),'yyyy-MM-dd HH24:mi:ss')"
#数据库是oracle，其他数据库可能需要定制。此处的是只同步创建时间在30天内的数据。
```

可以根据实际业务需要定制where参数来实现数据筛选

## 2.4删除数据同步

datax只有新增和更新两种数据会同步，当源数据库有数据删除时是无法同步的，就会造成源数据库已经删除了，但目标数据库还存在这些数据。目前想到以下两种方案：

### 2.4.1清空表完全走新增逻辑

在前置sql中配置清空标的sql即可。唯一的问题就是清空表到数据同步完成期间表是数据确实的，可能对业务影响比较大。
在writer.parameter参数中新增preSql配置即可

```json
"preSql": ["truncate table 表名;"],
```

### 2.4.2利用已删除数据不会同步的逻辑

总体思路：
1、需要同步的目标数据库表增加一个SYNC_STATUS字段
2、每次同步时，用前置sql更新SYNC_STATUS=0
3、每次同步数据时将一个常量1同步到SYNC_STATUS，达到SYNC_STATUS=1的目的
4、后置sql执行删除操作，将SYNC_STATUS=0的数据全部删除（源表此数据已经物理删除，目标表此数据不会有更新，所以前置sql更新的SYNC_STATUS=0不会变，可以认定为是已删除数据）
这样目前只能全量同步，需要增量的同步数据（含删除）还需要在进行改造，示例如下：

```css
{
  "job": {
    "setting": {
      "speed": {
        "channel": 3,
        "byte": 1048576
      },
      "errorLimit": {
        "record": 0,
        "percentage": 0.02
      }
    },
    "content": [
      {
        "reader": {
          "name": "oraclereader",
          "parameter": {
            "username": "xxx",
            "password": "xxx",
            "column": [
              "\"ID\"",
              "1"
            ],
            "splitPk": "ID",
            "connection": [
              {
                "table": [
                  "xxx"
                ],
                "jdbcUrl": [
                  "jdbc:oracle:thin:@//xxx:1521/orcl"
                ]
              }
            ]
          }
        },
        "writer": {
          "name": "mysqlwriter",
          "parameter": {
            "writeMode": "update",
            "username": "xxx",
            "password": "xxx",
            "column": [
              "`ID`",
              "`SYNC_STATUS`"
            ],
            "preSql": [
              "UPDATE xxx SET SYNC_STATUS = '0';"
            ],
            "postSql": [
              "DELETE FROM xxx WHERE SYNC_STATUS = '0';"
            ],
            "connection": [
              {
                "table": [
                  "xxx"
                ],
                "jdbcUrl": "jdbc:mysql://xxx:3306/xxx?useUnicode=true&characterEncoding=UTF-8&serverTimezone=Asia/Shanghai&allowMultiQueries=true"
              }
            ]
          }
        }
      }
    ]
  }
}
```