导入用户表：

## 1、创建表

```sql
--如果是分区表就要建立分区
CREATE TABLE `ods_user` (
  `user_id` BIGINT,
  `user_name` VARCHAR(64) ,
  `user_gender` TINYINT ,
  `user_birthday` DATE ,
  `user_age` INT ,
  `constellation` VARCHAR(8),
  `province` VARCHAR(32),
  `city` VARCHAR(32) ,
  `city_level` TINYINT ,
  `e_mail` VARCHAR(256) ,
  `op_mail` VARCHAR(32) ,
  `mobile` BIGINT ,
  `num_seg_mobile` INT ,
  `op_Mobile` VARCHAR(64) ,
  `register_time` DATE ,
  `login_ip` VARCHAR(64) ,
  `login_source` VARCHAR(512) ,
  `request_user` VARCHAR(32) ,
  `total_score` DECIMAL(18,2) ,
  `used_score` DECIMAL(18,2) ,
  `is_blacklist` TINYINT ,
  `is_married` TINYINT ,
  `education` VARCHAR(128) ,
  `monthly_income` DECIMAL(18,2) ,
  `profession` VARCHAR(128) ,
  `create_date` TIMESTAMP 
) 
row format delimited fields terminated by '\001'
stored as textfile
;
```

## 2、sqoop创建工作流

```sqoop
解决密码问题：
sqoop执行任务的时候会提示执行密码，如果将sqoop的job配置成oozie任务，密码输入很不好处理。
需要建立密码文件并指定，--password-file ,文件必须放在hdfs之上，权限400
echo -n "123456" > sqoopPWD.pwd
hdfs dfs -mkdir -p /sqoop/pwd
hdfs dfs -put sqoopPWD.pwd /sqoop/pwd/
hdfs dfs -chmod 400 /sqoop/pwd/sqoopPWD.pwd
```

将job配置成oozie的工作流任务：

```
hdfs dfs -mkdir -p /phone/oozie
hdfs dfs -mkdir /phone/oozielib
上传mysql的驱动包到/phone/oozielib目录下
hdfs dfs -put ./sqoop /phone/oozie/
```

sqoop文件如下：job.properties，sqoop-conf.sh，workflow.xml

```properties
#job.properties
nameNode=hdfs://hadoop01:9000
#RM地址，这是hadoop1.x
jobTracker=hadoop01:8032 
queueName=default
filePath=/phone/oozie
oozie.use.system.libpath=true
oozie.libpath=${nameNode}/phone/oozielib
running_date=2019-01-04
oozie.wf.application.path=${nameNode}${filePath}/sqoop/
```

### 全量导入：

sqoop-conf.sh

```bash
#!/bin/sh
/usr/local/sqoop-1.4.6-cdh5.13.2/bin/sqoop job \
--create gp1813_user \
-- import \
--connect jdbc:mysql://hadoop01:3306/qfbap_ods\?dontTrackOpenResources=true\&defaultFetchSize=10000\&useCursorFetch=true \ 注：解决内存过小的问题，批量拉取
--username root \
--password-file /sqoop/pwd/sqoopPWD.pwd \
--table user \
--delete-target-dir \
--target-dir load data inpath /qfbap/xx_tmp   \  注：分区表我们是放在临时目录中，然后分区导入
--fields-terminated-by '\001' \
;
注：上面是一个表的，在这后面可以追加多个表。
```

### 增量导入：

```
增量导入：
/usr/local/sqoop-1.4.6-cdh5.13.2/bin/sqoop job \
--create gp1813_us_order \
-- import \
--connect jdbc:mysql://hadoop01:3306/qfbap_ods\?dontTrackOpenResources=true\&defaultFetchSize=10000\&useCursorFetch=true \
--username root \
--password-file /sqoop/pwd/sqoopPWD.pwd \
--table us_order \
--target-dir /hive/qfbap_ods.db/ods_order/day='2019-01-04'/ \
--fields-terminated-by '\001' \
--check-column order_id \
--incremental append \
--last-value 0 \ 注：这是从0标记位开始
```



workflow.**xml**

```xml
<workflow-app xmlns="uri:oozie:workflow:0.4" name="phone-sqoop-wf">
    <start to="sqoop-import" />
    <action name="sqoop-import">
        <shell xmlns="uri:oozie:shell-action:0.2">
			<job-tracker>${jobTracker}</job-tracker>
			<name-node>${nameNode}</name-node>
			<exec>sqoop-conf.sh</exec>
			<file>sqoop-conf.sh</file>
			<capture-output/>
		</shell>
        <ok to="end" />
        <error to="fail" />
    </action>
    <kill name="fail">
        <message>Shell action failed, error message[${wf:errorMessage(wf:lastErrorNode())}]</message>
    </kill>
    <end name="end"/>
</workflow-app>
```

## 3、启动oozie

```shell
oozied.sh start/run 
```

## 4、启动historyserver

```shell
mr-jobhistory-daemon.sh start historyserver 注：日志服务
```

## 5、检查workflow是否有效：

```
oozie validate sqoop/workflow.xml
如果出错：
Oozie URL is not available neither in command option or in the environment
解决方案：
export OOZIE_URL=http://hadoop01:11000/oozie
```

## 6、运行oozie任务：

在oozie中生成job

```
oozie job --oozie http://hadoop01:11000/oozie -config sqoop/job.properties -run

错误：
exception “GC Overhead limit exceeded
原因：
Why Sqoop Import throws this exception?
The answer is – During the process, RDBMS database (NOT SQOOP) fetches all the rows at one shot and tries to load everything into memory. This causes memory spill out and throws error. To overcome this you need to tell RDBMS database to return the data in batches. The following parameters “?dontTrackOpenResources=true&defaultFetchSize=10000&useCursorFetch=true” following the jdbc connection string tells database to fetch 10000 rows per batch.
解决方案：
1、指定mappers的数量（数量最好不要超过节点的个数）
sqoop job --exec gp1813_user -- --num-mappers 8;
2、调整jvm的内存，缺点:
 -Dmapreduce.map.memory.mb=6000 \
 -Dmapreduce.map.java.opts=-Xmx1600m \
 -Dmapreduce.task.io.sort.mb=4800 \
3、设置mysql的读取数据的方式，不要一次性将所有数据都fetch到内存
?dontTrackOpenResources=true&defaultFetchSize=10000&useCursorFetch=true
将连接数据库的参数增加上去
```

## 7、将sqoop导数据的程序封装到oozie任务中执行

配置参考oozie/sqoop-exec目录，目录如下：job.properties，sqoop-exec.sh，workflow.xml

```bash
#sqoop-exec.sh
#!/bin/sh
/usr/local/sqoop-1.4.6-cdh5.13.2/bin/sqoop job --exec gp1813_user;
hive --database qfbap_ods -e "load data inpath '/qfbap/xx_tmp/'" into table xxx partition(day='');
注意：这是一个表临时数据，后面可以追加多个表的临时数据
```

job.properties

```properties
nameNode=hdfs://hadoop01:9000
jobTracker=hadoop01:8032
queueName=default
filePath=/phone/oozie
oozie.use.system.libpath=true
oozie.libpath=${nameNode}/phone/oozielib
running_date=2019-01-04

oozie.wf.application.path=${nameNode}${filePath}/sqoop-exec/
```

workflow.xml

```xml
<workflow-app xmlns="uri:oozie:workflow:0.4" name="phone-sqoopexec-wf">
    <start to="sqoop-exec" />
    <action name="sqoop-exec">
        <shell xmlns="uri:oozie:shell-action:0.2">
			<job-tracker>${jobTracker}</job-tracker>
			<name-node>${nameNode}</name-node>
			<exec>sqoop-exec.sh</exec>
			<file>sqoop-exec.sh</file>
			<capture-output/>
		</shell>
        <ok to="end" />
        <error to="fail" />
    </action>
    <kill name="fail">
        <message>Shell action failed, error message[${wf:errorMessage(wf:lastErrorNode())}]</message>
    </kill>
    <end name="end"/>
</workflow-app>
```

## 8、将需要定时执行的任务封装到coord中

oozie/coord,目录如下：coordinator.xml,job.properties，workflow.xml

coordinator.xml

```xml
<coordinator-app name="phone-coor" frequency="${coord:days(1)}" start="${start}" end="${end}" timezone="UTC"
                 xmlns="uri:oozie:coordinator:0.2">
    <action>
        <workflow>
            <app-path>${workflowAppUri}</app-path>
        </workflow>
    </action>
</coordinator-app>
```

workflow.xml

```xml
<workflow-app xmlns="uri:oozie:workflow:0.3" name="phone-coor">
    <start to="sub-workflow-phone-import"/>
    <action name="sub-workflow-phone-import">
        <sub-workflow>
            <app-path>${nameNode}${filePath}/sqoop</app-path>
        </sub-workflow>
        <ok to="sub-workflow-phone-exec"/>
        <error to="fail"/>
    </action>

    <action name="sub-workflow-phone-exec">
        <sub-workflow>
            <app-path>${nameNode}${filePath}/sqoop-exec</app-path>
        </sub-workflow>
        <ok to="end"/>
        <error to="fail"/>
    </action>

    <kill name="fail">
        <message>Java failed, error message[${wf:errorMessage(wf:lastErrorNode())}]</message>
    </kill>
    <end name="end"/>
</workflow-app>
```

job.properties

```properties
nameNode=hdfs://hadoop01:9000
jobTracker=hadoop01:8032
queueName=default
filePath=/phone/oozie
oozie.use.system.libpath=true
oozie.libpath=${nameNode}/phone/oozielib
running_date=2019-01-04

oozie.coord.application.path=${nameNode}${filePath}/coor

start=2019-01-04T02:00+0800 
end=2039-09-19T03:00+0800 
workflowAppUri=${nameNode}${filePath}/coor
```

