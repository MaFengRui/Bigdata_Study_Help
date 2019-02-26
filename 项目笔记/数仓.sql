dw层：
dwd：detail层
dws：server层
dwa：简单汇总层

1、确定数据源
前台点击流数据
后台服务程序产生的数据

2、确定主题
用户主题：用户、会员相关的信息
订单主题：订单相关
事件主题：
浏览器主题：浏览器相关指标

3、创建模型（创建表）
1、维度表
维度层（dim）：
地域维度：省、市、县
浏览器维度：浏览器名称、版本
时间维度：年月日周季度
事件维度：category	action
操作系统维度：
平台维度：
外链维度：

2、ods层
1、浏览数据
2、订单数据

3、创建dw层
4、创建dm层

命名规则：
ods_user_addr_
ODS_user_addr_
ods.user.addr. 不行

create database if not exists gp1813_mfr_dim;
create database if not exists gp1813_mfr_ods;
create database if not exists gp1813_mfr_dw;
create database if not exists gp1813_mfr_dm;


创建维度表：
CREATE TABLE IF NOT EXISTS `dim_province` (
  `id` int,
  `province` string,
  `countryId` int,
  `desc` string
)
row format delimited fields terminated by '\t'
;

CREATE TABLE IF NOT EXISTS `dim_city` (
  `id` int,
  `city` string,
  `desc` string
)
row format delimited fields terminated by '\t'
;

CREATE TABLE IF NOT EXISTS `dim_province_city` (
  `dim_region_id` bigint,
  `dim_region_city_name` string,
  `dim_region_province_name` string,
  `dim_region_country_name` string,
  `dim_region_city_id` string,
  `dim_region_province_id` string,
  `dim_region_country_id` string,
  `dim_region_date` string
)
row format delimited fields terminated by '\t'
;


CREATE TABLE IF NOT EXISTS `dim_platform` (
  `id` int,
  `platform_name` string
)
row format delimited fields terminated by '\t'
;



CREATE TABLE IF NOT EXISTS `dim_kpi` (
  `id` int,
  `kpi_name` string
)
row format delimited fields terminated by '\t'
;



CREATE TABLE IF NOT EXISTS `dim_event_name` (
  `id` int,
  `name` string
)
row format delimited fields terminated by '\t'
;

CREATE TABLE IF NOT EXISTS `dim_event_category` (
  `id` int,
  `category` string
)
row format delimited fields terminated by '\t'
;


CREATE TABLE IF NOT EXISTS `dim_event_action` (
  `id` int,
  `action` string
)
row format delimited fields terminated by '\t'
;


CREATE TABLE IF NOT EXISTS `dim_browser_name` (
  `id` int,
  `browser_name` string,
  `browser_version_id` int
  )
row format delimited fields terminated by '\t'
;

CREATE TABLE IF NOT EXISTS `dim_browser_version` (
  `id` int,
  `browser_version` string
  )
row format delimited fields terminated by '\t'
;


CREATE TABLE IF NOT EXISTS `dim_order` (
  `oid` bigint,
  `on` string,
  `cut_id` bigint,
  `cua_id` bigint,
  `browser_version` string
  )
row format delimited fields terminated by '\t'
;

CREATE TABLE IF NOT EXISTS `dim_currency_type` (
  `id` int,
  `currency_name` string
)
row format delimited fields terminated by '\t'
;

CREATE TABLE IF NOT EXISTS `dim_payment_type` (
  `id` int,
  `payment_type` string
)
row format delimited fields terminated by '\t'
;

CREATE TABLE IF NOT EXISTS `dim_week`(
   STD_WEEK_CODE STRING,
   STD_WEEK_NAME STRING,
   BEGIN_DATE STRING,
   END_DATE STRING,
   NOTES STRING,
   IS_DISPLAY INT,
   DISPLAY_ORDER INT,
   IS_VALID INT,
   UPDATE_DATE STRING,
   LAST_STD_WEEK_CODE STRING
)
row format delimited fields terminated by '\t'
;

CREATE TABLE IF NOT EXISTS `dim_userinfo` (
  `uid` String,
  `uname` string
)
row format delimited fields terminated by '\t'
;

load data local inpath '/root/dim/dim_province' into table dim_province;
load data local inpath '/root/dim/dim_city' into table dim_city;
load data local inpath '/root/dim/dim_province_city' into table dim_province_city;
load data local inpath '/root/dim/dim_platform' into table dim_platform;
load data local inpath '/root/dim/dim_kpi' into table dim_kpi;
load data local inpath '/root/dim/dim_event_name' into table dim_event_name;
load data local inpath '/root/dim/dim_browser_name' into table dim_browser_name;
load data local inpath '/root/dim/dim_browser_version' into table dim_browser_version;
load data local inpath '/root/dim/dim_userinfo' into table dim_userinfo;

在ods库中建立事实表
udf：
create table if not exists font_logs(
ip string,
s_time string,
server_ip string,
url string
)
partitioned by (month string,day string)
row format delimited fields terminated by '\001'
;

使用
create external table if not exists ods_logs(
`ver` string,
`s_time` string,
`en` string,
`u_ud` string,
`u_mid` string,
`u_sd` string,
`c_time` string,
`l` string,
`b_iev` string,
`b_rst` string,
`p_url` string,
`p_ref` string,
`tt` string,
`pl` string,
`ip` string,
`oid` string,
`on` string,
`cua` string,
`cut` string,
`pt` string,
`ca` string,
`ac` string,
`kv_` string,
`du` string,
`browserName` string,
`browserVersion` string,
`osName` string,
`osVersion` string,
`country` string,
`province` string,
`city` string
)
partitioned by (month string,day string)
row format delimited fields terminated by '\001'
;

加载数据：
load data local inpath '/root/mfrprodectdata/odsdata/2018-08-29' into table ods_logs partition(month='08',day='29');
load data local inpath '/root/mfrprodectdata/odsdata/2018-08-30' into table ods_logs partition(month='08',day='30');

parquet：

create external table if not exists ods_logs_orc(
`ver` string,
`s_time` string,
`en` string,
`u_ud` string,
`u_mid` string,
`u_sd` string,
`c_time` string,
`l` string,
`b_iev` string,
`b_rst` string,
`p_url` string,
`p_ref` string,
`tt` string,
`pl` string,
`ip` string,
`oid` string,
`on` string,
`cua` string,
`cut` string,
`pt` string,
`ca` string,
`ac` string,
`kv_` string,
`du` string,
`browserName` string,
`browserVersion` string,
`osName` string,
`osVersion` string,
`country` string,
`province` string,
`city` string
)
partitioned by (month string,day string)
row format delimited fields terminated by '\001'
stored as orc
;

from ods_logs
insert into table ods_logs_orc partition(month='08',day='30')
select
`ver`,
`s_time`,
`en`,
`u_ud`,
`u_mid`,
`u_sd`,
`c_time`,
`l`,
`b_iev`,
`b_rst`,
`p_url`,
`p_ref`,
`tt`,
`pl`,
`ip`,
`oid`,
`on`,
`cua`,
`cut`,
`pt`,
`ca`,
`ac`,
`kv_`,
`du`,
`browserName`,
`browserVersion`,
`osName`,
`osVersion`,
`country`,
`province`,
`city`
where month='08' and day='30'
;


from ods_logs
insert into table ods_logs_orc partition(month='08',day='29')
select
`ver`,
`s_time`,
`en`,
`u_ud`,
`u_mid`,
`u_sd`,
`c_time`,
`l`,
`b_iev`,
`b_rst`,
`p_url`,
`p_ref`,
`tt`,
`pl`,
`ip`,
`oid`,
`on`,
`cua`,
`cut`,
`pt`,
`ca`,
`ac`,
`kv_`,
`du`,
`browserName`,
`browserVersion`,
`osName`,
`osVersion`,
`country`,
`province`,
`city`
where month='08' and day='29'
;

创建dw层：
###为新增用户、新增总用户、活跃用户做计算
create table if not exists dwd_user(
`pl` string,
`pl_id` string,
`en` string,
`en_id` string,
`browser_name` string,
`browser_id` string,
`browser_version` string,
`browser_version_id` string,
`province_name` string,
`province_id` string,
`city_name` string,
`city_id` string,
`uid` string
)
partitioned by (month string,day string)
row format delimited fields terminated by '\001'
stored as orc
;

from(
select
ol.`pl` as platform,
dp.`id` as platformid,
ol.`en` as eventname,
en.`id` as eventid,
ol.`browsername` as browsername,
bn.`id` as browserid,
ol.`browserversion` as browserVersion,
bv.`id` as browserVersionId,
ol.province as provinceName,
pro.id as provinceId,
ol.city as cityName,
dc.id as cityId,
ol.u_ud as uid
from gp1813_mfr_ods.ods_logs_orc ol
left join gp1813_mfr_dim.dim_platform dp on dp.platform_name = ol.pl
left join gp1813_mfr_dim.dim_event_name en on en.name = ol.en
left join gp1813_mfr_dim.dim_browser_name bn on bn.browser_name = ol.browserName
left join gp1813_mfr_dim.dim_browser_version bv on bv.browser_version = ol.browserversion
left join gp1813_mfr_dim.dim_province pro on pro.province = ol.province
left join gp1813_mfr_dim.dim_city dc on dc.city = ol.city
where ol.month = '08' and ol.day = '29' and ol.u_ud is not null
) tmp
insert into table dwd_user partition(month='08',day='29')
select *
;

创建dwa层：


创建dm层：
#用户主题下的新增用户、新增总用户、活跃用户
drop table if exists st_user_users;
create table if not exists st_user_users(
`pl` string,
`pl_id` string,
`new_user_count` int,
`new_total_user_count` int,
`active_user_count` int
)
partitioned by (month string,day string)
row format delimited fields terminated by '\001'
stored as orc
;

from (
select
us.`pl`,
us.`pl_id`,
count(distinct us.uid) as new_user_count,
count(distinct us.uid) + nvl(us1.new_total_user_count,0) as new_total_user_count,
0 as active_user_count
from gp1813_mfr_dw.dwd_user us
left join gp1813_mfr_dm.st_user_users us1 on us1.month = '08' and us1.day = '' and us1.pl_id = us.pl_id
where us.month = '08' and us.day = '29' and us.en_id = '1'
group by us.`pl`,us.`pl_id`,us1.new_total_user_count
union all
select
us.`pl`,
us.`pl_id`,
0 as new_user_count,
0 as new_total_user_count,
count(distinct uid) as
from gp1813_mfr_dw.dwd_user us
where us.month = '08' and us.day = '29'
group by us.`pl`,us.`pl_id`
) tmp
insert into st_user_users partition(month='08',day='29')
select pl,pl_id,
sum(new_user_count) as new_user_count,
sum(new_total_user_count) as new_total_user_count,
sum(active_user_count) as active_user_count
group by pl,pl_id
;


-- #浏览器主题下的新增用户、新增总用户、活跃用户
create table if not exists st_browser_users(
`pl` string,
`pl_id` string,
`browser_name` string,
`browser_id` string,
`browser_version` string,
`browser_version_id` string,
`new_user_count` int,
`new_total_user_count` int,
`active_user_count` int
)
partitioned by (month string,day string)
row format delimited fields terminated by '\001'
stored as orc
;


from
(select
us.`pl`,
us.`pl_id`,
us.`browserid`,
us.`browser_name`,
count(distinct us.uid) as new_user_count,
count(distinct us.uid) + nvl(us1.new_total_user_count,0) as new_total_user_count,
0 as active_user_count
from dwd_user as us
left join gp1813_mfr_dm.st_browser_users us1 on us1.month = '08' and us1.day = '29' and us1.browser_id = us.browser_id
where us.month = '08' and us.day = '30' and us.en_id = '1'
group by us.pl,us.pl_id,us.browser_name,us.browser_version,us.browser_version_id,us1.new_total_user_count
union all
select
us.`pl`,
us.`pl_id`,
us.`browserid`,
us.`browser_name`,
0 as new_user_count,
0 as new_total_user_count,
count(distinct us.uid)  as active_user_count
from dwd_user as us
where us.month = '08' and us.day = '30' and us.en_id = '1'
group by us.pl,us.pl_id,us.browser_name,us.browser_version,us.browser_version_id
) tmp
insert into st_browser_users partition(month='08',day='30')
select
pl,
pl_id,
browser_version_id
browser_name,
sum(new_user_count) as new_user_count,
sum(new_total_user_count) as new_total_user_count,
sum(active_user_count) as active_user_count
group by
pl,
pl_id,
browser_version_id
browser_name


#地域主题下的活跃用户
create table if not exists st_area_users(
`pl` string,
`pl_id` string,
`province_name` string,
`province_id` string,
`city_name` string,
`city_id` string,
`active_user_count` int
)
partitioned by (month string,day string)
row format delimited fields terminated by '\001'
stored as orc
;

insert into st_area_users partition(month='08',day='30')
select
us.`pl`,
us.`pl_id`,
`province_name`,
`province_id`,
`city_name`,
`city_id`,
count(distinct us.`uid`)  as active_user_count
from dwd_user as us
where us.month = '08' and us.day = '30'
group by us.pl,us.pl_id,us.province_name,
us.province_id,
us.city_name,
us.city_id










--
-- 课后练习：
-- 1、转数仓项目以上的指标
-- 2、hive练习至少到20
-- 3、08点交
--
--
-- 练习：
-- 创建dw层：
-- #新增会员、总会员、活跃会员


-- 在ods层创建一个会员信息来保存这个会员信息
create table if not exists members_info(表
`mid` string,
`s_time` string
)
row format delimited fields terminated by '\001'
stored as orc
;



-- dw层
create table if not exists dw_member(
`pl` string,
`pl_id` string,
`en` string,
`en_id` string,
`browser_name` string,
`browser_id` string,
`browser_version` string,
`browser_version_id` string,
`province_name` string,
`province_id` string,
`city_name` string,
`city_id` string,
`mid` string,
`s_time` string
)
partitioned by (month string,day string)
row format delimited fields terminated by '\001'
stored as orc
;

from(
select 
ol.`pl` as platform,
dp.`id` as platformid,
ol.`en` as eventname,
en.`id` as eventid,
ol.`browsername` as browsername,
bn.`id` as browserid,
ol.`browserversion` as browserVersion,
bv.`id` as browserVersionId,
ol.province as provinceName,
pro.id as provinceId,
ol.city as cityName,
dc.id as cityId,
ol.u_mid as mid,
ol.s_time as s_time
from gp1813_ods.ods_logs_orc ol
left join gp1813_mfr_dim.dim_platform dp on dp.platform_name = ol.pl
left join gp1813_mfr_dim.dim_event_name en on en.name = ol.en
left join gp1813_mfr_dim.dim_browser_name bn on bn.browser_name = ol.browserName
left join gp1813_mfr_dim.dim_browser_version bv on bv.browser_version = ol.browserversion
left join gp1813_mfr_dim.dim_province pro on pro.province = ol.province
left join gp1813_mfr_dim.dim_city dc on dc.city = ol.city
where ol.month = '08' and ol.day = '30' and ol.u_ud is not null
) tmp
insert into table dwd_member partition(month='08',day='30')
select *
;



-- 创建dm层
create table if not exists st_user_members(
`pl` string,
`pl_id` string,
`new_members` int,
`total_members` int,
`active_members` int
)
partitioned by (month string,day string)
row format delimited fields terminated by '\001'
stored as orc
;


-- 插入数据：
from (
select
us.`pl`, 
us.`pl_id`,
us.`mid`,
'2018-08-15' as s_time,
count(distinct us.mid) as new_members,
count(distinct us.mid) + nvl(us1.total_members,0) as total_members,
0 as active_members
from gp1813_mfr_dw.dwd_member us
left join gp1813_mfr_dm.st_user_members us1 on us1.month = '08' and us1.day = '24' and us1.pl_id = us.pl_id
left join members_info mi on us.mid=mi.mid
where us.month = '08' and us.day = '30' and mi.s_time is null and us.`mid` is not null and us.`mid`<>'null'and mi.mid is  null
group by us.`pl`,us.`pl_id`,us1.total_members,us.`mid`
union all
select
us.`pl`,
us.`pl_id`,
us.`mid`,
'2018-08-30' as s_time,
0 as new_members,
0 as total_members,
count(distinct mid) as active_members
from gp1813_mfr_dw.dwd_member us
where us.month = '08' and us.day = '30' and us.en_id = '2' and us.`mid` is not null and us.`mid`<>'null'
group by us.`pl`,us.`pl_id`,us.`mid`
) tmp
insert into st_user_members partition(month='08',day='30')
select pl,pl_id,
sum(new_members) as new_members,
sum(total_members) as total_members,
sum(active_members) as active_members
group by pl,pl_id
insert into members_info
select distinct mid, s_time
where mid is not null and  mid <>'null'
;



-- #浏览器主题下的新增会员、总会员、活跃会员
create table if not exists st_browser_members(
`pl` string,
`pl_id` string,
`browser_name` string,
`browser_id` string,
`browser_version` string,
`browser_version_id` string,
`new_members` int,
`total_members` int,
`active_members` int
)

partitioned by (month string,day string)
row format delimited fields terminated by '\001'
stored as orc
;
from (
select
us.`pl`, 
us.`pl_id`,
us.`browser_name`,
us.`browser_id` ,
us.`browser_version` ,
us.`browser_version_id`,
us.`mid`,
count(distinct us.mid) as new_members,
count(distinct us.mid) + nvl(us1.total_members,0) as total_members,
0 as active_members,
'2018-08-15' as s_time
from gp1813_mfr_dw.dwd_member us
left join gp1813_mfr_dm.st_browser_members us1 on us1.month = '08' and us1.day = '24' and us1.pl_id = us.pl_id
left join members_info mi on us.mid=mi.mid
where us.month = '08' and us.day = '30' and us.`mid` is not null and us.`mid`<>'null'
group by us.`pl`,us.`pl_id`,us1.total_members,us.`browser_name`,
us.`browser_id`,us.`browser_version`,us.`browser_version_id`,us.`mid`
union all
select
us.`pl`,
us.`pl_id`,
us.`browser_name`,
us.`browser_id` ,
us.`browser_version` ,
us.`browser_version_id`,
us.`mid`,
0 as new_members,
0 as total_members,
count(distinct mid) as active_members,
'2018-08-15' as s_time
from gp1813_mfr_dw.dwd_member us
where us.month = '08' and us.day = '30' and us.en_id = '2' and us.`mid` is not null and us.`mid`<>'null'
group by us.`pl`,us.`pl_id`,us.`browser_name`,us.`browser_id`,us.`mid`,
us.`browser_version`,us.`browser_version_id`
) tmp
insert into st_browser_users partition(month='08',day='30')
select pl,pl_id,browser_name,browser_id,browser_version,browser_version_id,
sum(new_members) as new_members,
sum(total_members) as total_members,
sum(active_members) as active_members
group by pl,pl_id,browser_name,browser_id,browser_version,browser_version_id
insert into members_info
select distinct mid, s_time
where mid is not null and  mid <>'null'
;


--
-- dw层：
--
-- #### ③为会话ID、会话时长做准备

create table if not exists dwd_session(
`pl` string,
`pl_id` string,
`sessionId` string,
`s_time` string,
`browser_name` string,
`browser_id` string,
`browser_version` string,
`browser_version_id` string,
`province_name` string,
`province_id` string,
`city_name` string,
`city_id` string
)
partitioned by (month string,day string)
row format delimited fields terminated by '\001'
stored as orc
;


-- 插入数据：
from(
select 
ol.`pl` as platform,
dp.`id` as platformid,

ol.u_sd as sessionId,

ol.s_time as s_time,

ol.`browsername` as browsername,

bn.`id` as browserid,
ol.`browserversion` as browserVersion,
bv.`id` as browserVersionId,
ol.province as provinceName,
pro.id as provinceId,
ol.city as cityName,
dc.id as cityId
from gp1813_ods.ods_logs_orc ol
left join gp1813_mfr_dim.dim_platform dp on dp.platform_name = ol.pl
left join gp1813_mfr_dim.dim_event_name en on en.name = ol.en
left join gp1813_mfr_dim.dim_browser_name bn on bn.browser_name = ol.browserName
left join gp1813_mfr_dim.dim_browser_version bv on bv.browser_version = ol.browserversion
left join gp1813_mfr_dim.dim_province pro on pro.province = ol.province
left join gp1813_mfr_dim.dim_city dc on dc.city = ol.city
where ol.month = '12' and ol.day = '24' and ol.u_ud is not null
) tmp
insert into table dwd_session partition(month='08',day='30')
select *
;










