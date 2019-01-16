话不多说撸SQL

前言

撸SQL，能让你忘记人性的欲望

## 四张表的数据

**学生信息数据**

```sql
s_id s_name s_birthday s_sex
01 赵雷 1990-01-01 男
02 钱电 1990-12-21 男
03 孙风 1990-05-20 男
04 李云 1990-08-06 男
05 周梅 1991-12-01 女
06 吴兰 1992-03-01 女
07 郑竹 1989-07-01 女
08 王菊 1990-01-20 女

创建表
create external table if not exists stu_info(
s_id string,
s_name string,
s_birthday date,
s_sex string
) row format delimited
fields terminated by '\t';

导入数据  load data local inpath '/media/sqldata/stu_info' into table stu_info;
```

**课程信息表**

```sql
c_id c_name t_id
01	语文	02
02	数学	01
03	英语	03

创建表
create external table if not exists course_info(
c_id string,
c_name string,
t_id string)
row format delimited
fields terminated by '\t';

导入数据
load data local inpath '/media/sqldata/course_info' into table course_info;
```



**教师信息表**

```sql
t_id t_name
01	张三
02	李四
03	王五z`

创建表
create external table if not exists teacher_info(
t_id string,
t_name string
)
row format delimited
fields terminated by '\t';

导入数据
load data local inpath '/media/sqldata/teacher_info' into table teacher_info;

```

**考试成绩表**

```sql
s_id c_id s_score
01	01	80
01	02	90
01	03	99
02	01	70
02	02	60
02	03	80
03	01	80
03	02	80
03	03	80
04	01	50
04	02	30
04	03	20
05	01	76
05	02	87
06	01	31
06	03	34
07	02	89
07	03	98

创建表
create external table if not exists student_score(
s_id string,
c_id string,
s_score int
)
row format delimited
fields terminated by '\t';

导入数据
load data local inpath '/media/sqldata/student_score' into table student_score;

```

## 1、查询"01"课程比"02"课程成绩高的学生的信息及课程分数:



```sql
select d.*,c.s_score
from stu_info as d
right join
(select b.s_id as s_id,b.s_score
from student_score as b
join
(select s_id,s_score
from student_score
where c_id='02') as a
on a.s_id=b.s_id
where b.c_id='01' and b.s_score > a.s_score) as c
on c.s_id=d.s_id;
```

## 2、查询"01"课程比"02"课程成绩低的学生的信息及课程分数:

```sql
智障题，步骤如上
```

## 3、查询平均成绩大于等于60分的同学的学生编号和学生姓名和平均成绩:

```sql
select a.s_id,s_name,score
from stu_info as a
join(
select s_id,round(avg(s_score),2) as score
from student_score
group by s_id
having avg(s_score)>60) as b
on b.s_id=a.s_id;
```



## 4、查询平均成绩小于60分的同学的学生编号和学生姓名和平均成绩:

(包括有成绩的和无成绩的)

```sql
select a.s_id,s_name,score
from stu_info as a
join(
select s_id,round(avg(s_score),2) as score
from student_score
group by s_id
having avg(s_score)<60) as b
on b.s_id=a.s_id;
```

## 5、查询所有同学的学生编号、学生姓名、选课总数、所有课程的总成绩:

```

```

## 6、查询"李"姓老师的数量:

```sql
select count(*)
from teacher_info
where t_name Like '李%';
```

## 7、查询学过"张三"老师授课的同学的信息

```

```

## 8、查询没学过"张三"老师授课的同学的信息:

```sql
select  distinct d.*
from teacher_info as a
join course_info as b
on a.t_id = b.t_id
join student_score as c
on b.c_id=c.c_id
join stu_info as d
on d.s_id=c.s_id
where a.t_name <> '张三'
```

## 9、查询学过编号为"01"并且也学过编号为"02"的课程的同学的信息:

```sql
select s_id
from student_score
where c_id='01' or c_id='02'
group by s_id
having count(1) = 2;
学生id的出来，其他的就简单了‘

```

## 10、查询学过编号为"01"但是没有学过编号为"02"的课程的同学的信息:

```sql
两个表join
```

## 11、查询没有学全所有课程的同学的信息:先查询出课程的总数量–再查询所需结果

```sql
select s_id
from student_score
group by s_id
having count(1) < 3;
```

## 12、查询至少有一门课与学号为"01"的同学所学相同的同学的信息:

```
先查出学号01的选的课

```

## 13、

## 14、查询没学过"张三"老师讲授的任一门课程的学生姓名:

```sql
select  d.s_name
from stu_info as d
join teacher_info as b 
join course_info as a on b.t_id=a.t_id
left join student_score as c
on  c.c_id = b.t_id and d.s_id=c.s_id 
where b.t_name='张三' and c.s_score is  null;





```

## 15查询两门及其以上不及格课程的同学的学号，姓名及其平均成绩:

```sql
select s_id,avg(s_score)
from student_score
where s_score < 60
group by s_id
having count(1) > 1;
```



## 16 检索"01"课程分数小于60，按分数降序排列的学生信息:



```sql
select *
from student stu
join score a on a.s_id = stu.s_id
where a.c_id = '01' and a.s_score < 60
order by a.s_score desc
;
```

## 17、按平均成绩从高到低显示所有学生的所有课程的成绩以及平均成绩

```sql
select  a.s_id ,round (avg(a.s_score) over(distribute by a.s_id sort by a.s_score desc rows between unbounded preceding and unbounded following),2),a.s_score
from student_score as a
```

## 18、查询各科成绩最高分、最低分和平均分：以如下形式显示：课程ID，课程name，最高分，最低分，平均分，及格率，中等率，优良率，优秀率:

```sql
select score.c_id,
max(score.s_score) as maxscore,
min(score.s_score) as minscore,
avg(score.s_score) as avgscore,
round(sum(case  when score.s_score > 60 then 1 else 0 end) / count(1),2)as `及格`
from student_score as score
group by score.c_id
```

## 19、按各科成绩进行排序，并显示排名:– row_number() over()分组排序功能

```sql
    select ss.*,c.c_name,dense_rank() 
    over( distribute by ss.c_id sort by ss.s_score)
    from student_score as ss,course_info as c
    where  c.c_id=ss.c_id;
```

## 20、查询学生的总成绩并进行排名:

```sql

select s_id,sum(s_score) as sum1
from student_score
group by s_id
sort by sum1 desc;

```

## 21、查询所有课程的成绩第2名到第3名的学生信息及该课程成绩:

```sql
select stu.*,ss.s_score,ss.rak
from stu_info as stu
join(
select s_id,s_score,dense_rank() over(distribute by c_id sort by s_score asc) as rak
from student_score 
    ) as ss
    on ss.s_id=stu.s_id and rak between 2 and 3;

```

## 22  查询不同老师所教不同课程平均分从高到低显示:

```sql
select tt.t_name,ss.c_id,round(avg(ss.s_score),2)as avgscore
from student_score  as ss
join course_info as cc on cc.c_id=ss.c_id
join teacher_info as tt on tt.t_id=cc.t_id
group by ss.c_id,tt.t_name
sort by avgscore desc;
```

## 23、统计各科成绩各分数段人数：课程编号,课程名称,[100-85],[85-70],[70-60],[0-60]及所占百分比:

```sql
select score.c_id,
round(sum(case  when score.s_score > 60 then 1 else 0 end) / count(1),2) as `及格`,
round(sum(case when score.s_score between 70 and 90 then 1 else 0 end)/count(1),2) as `良好`,
round(sum(case when score.s_score>90 then 1 else 0 end)/count(1),2) as `优秀`
from student_score as score
group by score.c_id
```

## 24 查询学生平均成绩及其名次:

```sql
select ss.s_id,ss.s_name,round(avg1.stuavg,2),row_number() over(sort by avg1.stuavg desc)
from stu_info as ss
join 
(select s_id as s_id,avg(s_score) as stuavg
from student_score
group by s_id ) as  avg1
on avg1.s_id = ss.s_id;
```

## 25、查询各科成绩前三名的记录三个语句

```sql
select sc.c_id,sc.rak
from(
select c_id, dense_rank() over(distribute by c_id sort by s_score desc) as rak
from student_score) as sc
where sc.rak between 1 and 3;
```

## 26、查询每门课程被选修的学生数

```sql
select c_id,count(1)
from student_score
where s_score is not null
group by c_id
;
```

## 27、查询出只有两门课程的全部学生的学号和姓名:

```sql
select 
from stu_info 
join(
select s_id
from student_score
group by s_id
having count(1) = 2
)
```

## 28 查询男生、女生人数:

```sql
select s_sex,count(1)
from stu_info
group by s_sex
```

## 29 查询名字中含有"风"字的学生信息:

```sql
select *
from stu_info
where s_name like '%风%'
```

## 30、查询同名同性学生名单，并统计同名人数:

```sql

select s_name,count(1)
from  stu_info
group by s_name,s_sex

```

## 31  、查询1990年出生的学生名单

```sql
select *
from stu_info
where s_birthday >= '1990-01-01' and s_birthday < '1991-01-01'
```

## 32  查询平均成绩大于等于85的所有学生的学号、姓名和平均成绩:

```sql
select s_id,round(avg(s_score),2)
from student_score
group by s_id
having avg(s_score) > 85;
```

## 33、查询每门课程的平均成绩，结果按平均成绩降序排列，平均成绩相同时，按课程编号升序排列:

```sql
select  c_id,round(avg(s_score),2) as avgscore
from student_score
group by c_id
order by avgscore desc,c_id asc
```

## 33、查询平均成绩大于等于85的所有学生的学号、姓名和平均成绩:

```sql
select b.s_id,b.s_name,a.avg1
from stu_info as b
join
(
select s_id,avg(s_score) as avg1
from student_score
group by s_id
) as a
on a.s_id = b.s_id
where avg1 >= 85;
```

## 34、查询课程名称为"数学"，且分数低于60的学生姓名和分数:

```sql
select *
from course_info as a
join student_score as b
on a.c_id = b.c_id and a.c_name='数学' and b.s_score<60
```



## 35、查询所有学生的课程及分数情况:

```sql
select *
from stu_info as a
join student_score as b
on a.s_id=b.s_id
```

## 36、查询任何一门课程成绩在70分以上的学生姓名、课程名称和分数:

```sql

select c.s_name,b.c_name,a.s_score
from student_score as a
join course_info as b on a.c_id=b.c_id
join stu_info as c on c.s_id = a.s_id
where s_score > 70
```



## 37、查询课程不及格的学生:

```sql
select s_id
from student_score
where s_score<60

```

## 38、查询课程编号为01且课程成绩在80分以上的学生的学号和姓名:

```sql
select a.s_id,b.s_name
from student_score as a
where a.c_id='01' and a.s_score > 80
join stu_info as b
on a.s_id = b.s_id

```

## 39、求每门课程的学生人数:

```sql
select count(*)
from student_score
group by c_id
```

## 40、查询选修"张三"老师所授课程的学生中，成绩最高的学生信息及其成绩:

```sql
select max(c.s_score)
from teacher_info as a
join course_info as b on a.t_id = b.t_id
join student_score as c on b.c_id=c.c_id
where a.t_name = '张三'
group by b.c_id
```

## 41、查询不同课程成绩相同的学生的学生编号、课程编号、学生成绩:

```
select
from
where
```



## 42、查询每门课程成绩最好的前三名:

## 43、统计每门课程的学生选修人数（超过5人的课程才统计）:

– 要求输出课程号和选修人数，查询结果按人数降序排列，若人数相同，按课程号升序排列

44、检索至少选修两门课程的学生学号:

45、查询选修了全部课程的学生信息:

46、查询各学生的年龄(周岁):
– 按照出生日期来算，当前月日 < 出生年月的月日则，年龄减一

47、查询本周过生日的学生:

48、查询下周过生日的学生:

49、查询本月过生日的学生:

 50、查询12月份过生日的学生: