

## DML

DATABASE  MANINUPATION LANGUAGE 数据操纵语言

```
就是我们最经常用到的 SELECT、UPDATE、INSERT、DELETE。 主要用来对数据库的数据进行一些操作
SELECT 列名称 FROM 表名称
UPDATE 表名称 SET 列名称 = 新值 WHERE 列名称 = 某值
INSERT INTO table_name (列1, 列2,...) VALUES (值1, 值2,....)
DELETE FROM 表名称 WHERE 列名称 = 值
```

其实就是对表中的数据增删改查

## DDL

DATABASE DFFINITION LANGUAGE 数据库定义语言

```
其实就是我们在创建表的时候用到的一些sql，比如说：CREATE、ALTER、DROP等。DDL主要是用在定义或改变表的结构，数据类型，表之间的链接和约束等初始化工作上
```

其实就是对表的一些操作

## DCL

DATABASE CONTR0L LANGUAGE 数据库控制语言

```
是用来设置或更改数据库用户或角色权限的语句，包括（grant,deny,revoke等）语句。这个比较少用到。
```

