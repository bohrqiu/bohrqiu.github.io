---
title: 开发规范(三):mysql
date: 2018-05-20 21:52:17
categories: java
tags:
  - spec
---

>> 几年前写的东西，已经离职，留作纪念

# MySQL数据库开发规范

>版本 |	时间	  |作者	|修订章节	|修订内容
>----|----------|-----|-------|--------
>1.0 |2015-04-15|帕拉丁|全部|init
>1.1 |2015-04-20|秋波|全部|修订内容
>1.2 |2015-07-17|秋波|全部|修订内容
>1.3 |2015-07-28|秋波、帕拉丁|全部|修订内容

## 一. 数据库核心规范

1. 尽量不要在数据库做运算：cpu计算请移至业务层.
2. 控制单表数据量：单表记录控制在1000w行.（也可以考虑分区）
3. 控制列数量：单表字段数上限控制在20到50之内.字段少而精可以提高并发，IO更高效 ([优化InnoDB表BLOB列的存储效率](http://imysql.com/2014/09/28/mysql-optimization-case-blob-stored-in-innodb-optimization.shtml))
4. 平衡范式与冗余：效率优先，提高性能. 适时牺牲范式增加冗余
5. 拒绝3B：拒绝大sql(BIG SQL)，大事务(BIG TRANSATION)，大批量(BIG BATCH).

## 二. 命名规范

在MySQL数据库中，表名、字段名、触发器、存储过程以及函数的命名，统一采用26个英文字母（区分大小写）和0－9这十个自然数，加上下划线_组成，共63个字符.不能出现其他字符（注释除外）,也不能以数字或‘_’ 开头，非必须情况下，不使用自然数.

对于MySQL数据库， 表名、字段名统一采用小写字母; (Oracle数据库中表名、字段名统一采用大写字母)若名称过长可采用单词缩写.

### 1. 表名:

根据表所描述的业务实体，采用英文单词加`_`的形式命名.若表名太长，英文单词可采用缩写.如：`user_info`.

### 2. 视图命名：

视图名加`_view”后缀`。 如：`user_withdraw_view`.

MySQL因为没有物化视图，因此视图能不用就尽量少用。对于sql监控来讲，视图的sql存储在数据库中，分析时很不直观。

### 3. 触发器命名：

触发器功能描述名加“`_tr`”后缀。 如:`insert_balance_hist_tr`.

### 4. 存储过程：

存储过程功能描述名加“`_sp`”后缀。如：`load_user_trade_sp`.

### 5. 函数名：

函数功能描述加“`_fn`”后缀。 如：`generate_password_fn`.

### 6. 键名：

* 主键：主键字段或主键描述加“`_pk`” 如：`user_id_pk`
* 外键：外键字段 加“_fk” 如：`user_id_fk`
* 索引：索引字段或索引描述 加 `_idx` 如：`sex_idx`.

## 三.设计规范

### 1. 注释

表结构中须包含表注释和列注释. 对于函数、触发器以及存储过程等，代码开头应有阐述其功能的注释.若有复杂逻辑，则应加上局部注释.

### 2. 数据引擎选择

全部选择`InnoDB `。`MyISAM`一旦出现系统宕机或者进程崩溃情况容易造成存储数据损坏。

此外，频繁读写的InnoDB表，一定要使用具有自增/顺序特征的整型作为显式主键。

[为什么InnoDB表要建议用自增列做主键](http://imysql.com/2014/09/14/mysql-faq-why-innodb-table-using-autoinc-int-as-pk.shtml)

### 3. 编码

所有数据表均采用`UTF8`编码，并在表DDL中明确标出.所有字段都不单独设编码，即采用默认的表编码`UTF8`.

比如可以设置表的编码

	CREATE DATABASE IF NOT EXISTS my_db default charset utf8 COLLATE utf8_general_ci;

注意后面这句话`COLLATE utf8_general_ci`,意思是在排序时根据utf8校验集来排序，那么在这个数据库下创建的所有数据表的默认字符集都会是utf8了

### 4. 字段选择

#### 4.1 IP字段
如果是使用的IPV4，则使用`int`存储不使用char(15).

在MySQL中提供了`INER_ATONO()`和`INET_NTOA()`函数来对IP和数字之间进行转换. 前者提供IP到数字的转换后者提供数字到IP的转换.

	insert into table column(ipvalues(INET_ATONO('127.0.0.1')) ;

如业务需求需要存储IPV6，可采用`varchar(40)`类型.

#### 4.2 手机字段
如果考虑到`varchar`占用空间大影响查询性能，请使用`bigint`来存储手机号码.

* 不要使用`int`，因为`int`类型的最大长度不能超过11位
* 如果手机号码中含有地区码，则用`varchar`

#### 4.3 `enum`，`set`和`tinyint`类型使用

枚举类型可以使用ENUM，ENUM的内部存储机制是采用TINYINT或SMALLINT（并非CHAR/VARCHAR）。

注意：ENUM类型扩展性较差，如果新增枚举值，需要修改表字段定义，而且在执行ddl时会对性能有影响


#### 4.4 金额字段

对于金额字段，统一采用`decimal(17,0)`类型，金额以“分”为单位保存.

#### 4.5 时间字段

时间字段优先考虑`datetime`.


#### 4.6 精确浮点数字段必须使用decimal替代float和double

MySQL中的数值类型(不包括整型)IEEE754浮点数：单精度(`float`)、双精度(`double`和`real`)、 定点数(`decimal`和`numeric`).

`float`，`double`等非标准类型，在DB中保存的是近似值，而`decimal`则以字符串的形式保存数值

#### 4.7 辅助字段

为便于数据分析，所有表必须添加两个字段：

	raw_add_time timestamp DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
	raw_update_time timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间'

这两个字段只记录每条记录的创建时间及更新时间.


### 5 禁止在数据库里存图片和文件

禁止在数据库中使用`varbinary`、`blob`、`text`存储图片和文件.

### 6 数据库完整性要求

不在数据库层面约束数据的完整性，数据的完整性由程序来保证.

所以也禁止使用外键。

## 四. 索引规范

MySQL的查询速度依赖良好的索引设计，因此索引对于高性能至关重要.

合理的索引(哪怕是基于索引的条件过滤，如果优化器意识到总共需要扫描的数据量超过30%时，就会直接改变执行计划为全表扫描，不再使用索引。)会加快查询速度(包括UPDATE和DELETE的速度，MySQL会将包含该行的page加载到内存中，然后进行UPDATE或者DELETE操作),不合理的索引会降低速度.如果没有索引，MySQL会进行全表扫描，消耗大量IO.

### 1 谨慎合理的添加索引

索引能改善查询的效率，但是也会增加额外的开销并减慢更新的速度(更新时会同时更新索引). 索引的数量不是越多越好，能不加的索引尽量不加. InnoDB的`secondary index`(非主键索引）使用`b+tree`来存储，因此在UPDATE、DELETE、INSERT的时候需要对`b+tree`进行调整，过多的索引会减慢更新的速度.

按照目前的业务需求，单表的索引应符合下列要求：

* 索引数量控制在5个左右，单个索引的字段不超过5个.在设计的时候要结合SQL和需求考虑索引的覆盖.
* 唯一键由3个以下字段组成，当字段都是整形时，使用唯一键作为主键.
* 唯一键不和主键重复，即不得在主键上建唯一索引.
* 较长的字段需加入前缀索引来减少索引长度，提高效率.

例子如下:

	create table url( address VARCHAR(100) NOT NULL，index idx_url(address(10)));

 前缀索引长度依据索引的覆盖率来定,建立索引之前最好查看下对应字段建立索引的概率.MySQL5.6优化了合并索引，也就是说一条SQL上可以使用两个索引了.

### 2 提高索引的覆盖率

合理利用覆盖索引.

关于覆盖索引：`InnoDB` 存储引擎中，`secondary index`（非主键索引）中没有直接存储行地址，而存储主键值. 如果用户需要查询`secondary index`中所不包含的数据列时，需要先通过`secondary index`查找到主键值，然后再通过主键查询到其他数据列，因此需要查询两次. 覆盖索引的概念就是查询可以通过在一个索引中完成，覆盖索引效率会比较高，主键查询是覆盖索引.

合理的创建索引以及合理的使用查询语句，当使用到覆盖索引时可以获得性能提升.
比如`SELECT email,uid FROM user_email WHERE uid=xxx`，可以将索引添加为`index(uid,email)`，以提升性能.

索引字段的顺序需要考虑字段值去重之后的个数，个数多的放在前面.
合理创建联合索引（避免冗余），(a,b,c相当于 (a、(a,b、(a,b,c). 遵循最左原则.
UPDATE、DELETE语句需要根据WHERE条件添加索引.

### 3 索引使用需要注意的事项

* 不建议使用`%`前缀模糊查询，例如`LIKE "%xxx"`，这样会扫全表.
* 不要在索引列进行数学或者函数计算.

		select * from table where id +1 =10000;

	这样不会使用索引，导致扫全表，改为:

		select * from table where id =10000-1;

* 使用`EXPLAIN`判断SQL语句是否合理使用索引，尽量避免`extra`列出现：`Using File Sort`，`Using Temporary`.

	下面列出`extra`列常见的值:

	a. `Using Temporary`

	为了解决查询，MySQL需要创建一个临时表来容纳结果. 典型情况如查询包含可以按不同情况列出列的`GROUP BY`和`ORDER BY`子句. 使用临时表的开销是比较大的.

	b. `Using File Sort`

	MySQL需要额外的一次传递，以找出如何按排序顺序检索行. 出现这个说明SQL没有走索引. MySQL通过根据联接类型浏览所有行并为所有匹配WHERE子句的行保存排序关键字和行的指针来完成排序.

	c. `Using index`

	从只使用索引树中的信息而不需要进一步搜索读取实际的行来检索表中的列信息.

	d. `Using where`

	MySQL使用where条件进行过滤找到匹配行返回客户端.

* 禁止使用外键. 因为会产生额外开销，并且是逐行进行操作. 最关键的是在高并发的情况下很容易造成死锁.
* SQL变更需要确认索引是否需要变更，并通知DBA.

## 五. SQL规范

### 1. 核心思想

* 使用prepared statement，可以提高性能并且避免SQL注入.
* 尽量避免大SQL，因为在高并发的情况下，一个大SQL容易堵死数据库.

### 2. 注意事项

线上MySQL采用的是5.6版本，所以下列都以5.6版本为例子.

#### 2.1 使用合理的分页方式以提高分页的效率.

例子如下：

	SELECT * FROM TABLE ORDER BY IDLIMIT 1000000,10;

这种分页方式会导致大量的io，因为MySQL使用的是提前读取策略, LIMIT越大效率越低. 另外UPDATE、DELETE语句不使用LIMIT.

上面sql应改为:

		SELECT * FROM TABLE WHERE ID > LAST_ID ORDER BY ID LIMIT 10 (LAST_ID为具体值)

#### 2.2 SELECT语句只获取需要的字段

用select * 时会消耗更多的CPU，内存，IO，当表越大时消耗越大.

只读取有效的字段，可以提高索引覆盖，而且更安全(可以减少表变化带来的影响),减少网络传输、磁盘io时间。

#### 2.3 避免负向查询和前缀模糊查询

前缀模糊查询是不能使用索引. 负向查询是!=,<>, not in ,not exits,not like.是会导致无法使用索引的.

#### 2.4 WHERE条件中必须使用合适的类型

WHERE条件中的字符类型与对应字段的字符类型要一致。当类型不匹配时，MySQL会使用隐式转换,此时不会走索引.

#### 2.5 OR改写为IN

同一字段将OR改为IN. OR的效率为O(N),IN的效率为O(LOG N).N越大差距越大，当N很大时，OR会慢很多. 另外在使用IN的时候注意控制IN中的N个数.

#### 2.6 合理的排序

随机排序不要使用`ORDER BY RAND()`，使用其他方法替换.

	SELECT * FROM test1 ORDER BY RAND(LIMIT 1)

该语句EXPLAIN type为`ALL` EXTRA为 `Using File Sort`.
可以改为:

	SELECT id FROM test1 ORDER BY RAND(LIMIT 1);
	SELECT * FROM test1 WHERE id=?;

这2个语句都使用到了索引，性能比较好.

#### 2.7 HAVING子句

HAVING在检索出所有记录后才会对结果集进行过滤.如果能通过where子句限制记录数量，那就能减少开销.

比如将：

	select * from test1 group by id having id >3;

替换为

	select * from test1 where id >3 group by id;


#### 2.8 使用合理的SQL语句减少与数据库的交互次数.

减少与数据库的交互次数的SQL：

	`INSERT IGNORE`
	`INSERT INTO values()`

改为

	`INSERT … ON DUPLICATE KEY UPDATE`


`ON DUPLICATE KEY UPDATE` 是一种高效的唯一键或者主键冲突判断. 冲突则执行UPDATE，不冲突则执行INSERT语句.

#### 2.9 COUNT(*)

在不加WHRER条件下`count(col)`跟`count(*)`差不多，但是在加入了WHERE条件后`count(*)`的性能比`count(col)`和`count(1)`好. MySQL`count(*)` 对作了特殊处理.

#### 2.10 `or`和`union`

在MySQL5.6中优化了合并索引.一条SQL可以使用2个索引(INDEX_MERGE).但是如果三个字段的索引则使用不上索引合并.3个字段条件查找时候用`UNION`替代`OR`，如果不需要去重则用`UNION ALL`代替`OR`.(被查找的字段上都有相应的索引)

例如,下面的例子在数据均匀分布的情况下：

	`SELECT * FROM test1 WHERE id ='3' OR address ='5' or age =10`
改为

	SELECT * FROM test1 WHERE id ='1'
	UNION SELECT * FROM test1 WHERE address ='5'
	UNION SELETE * FROM test1 WHERE age ='10'`

第一种只执行一步但是无法使用索引会全表扫描.第二种会执行4步，分别查询值然后再union result.虽然步骤多但是查询走索引，union result只是从union临时表获取结果集合. 性能比第一种好一些.

#### 2.11 触发器，存储过程

尽量减少触发器，存储过程的使用和MySQL函数对结果集的处理.

#### 2.12 事务

事务的原则是即开即用，用完即停.与事务无关的操作放到事务外面，减少锁资源的占用.


## 六. 数据库基本优化策略

参考 [面向程序员的数据库访问性能优化法则](http://blog.csdn.net/yzsind/article/details/6059209)

数据库优化策略有以下几种方式：

* 减少数据访问（减少磁盘访问）
* 返回更少数据（减少网络传输或磁盘访问）
* 减少交互次数（减少网络传输）
* 减少服务器CPU开销（减少CPU及内存开销）
* 利用更多资源（增加资源）

这几种方法的收益如下图：
![image](spec_mysql/perf.gif)

![image](spec_mysql/io_perf.gif)

下面列出每种优化方式的一些具体方法。

### 1 减少数据访问

#### 1.1 创建并使用正确的索引

通过合理的创建和使用索引来减少数据访问。

#### 1.2 尽量通过索引访问数据

合理利用覆盖索引.

#### 1.3 优化SQL执行计划

SQL执行计划是关系型数据库最核心的技术之一，它表示SQL执行时的数据访问算法。通过执行计划可以判断SQL是否合理。

### 2 返回更少数据

#### 2.1 数据分页处理

通过分页的处理，减少数据的返回量。还有通过分表控制表的大小，增加查询的效率。

#### 2.2 只返回需要的字段

通过去除不必要的返回字段可以提高性能。

### 3 减少交互次数

#### 3.1 批量提交

通过批量提交的方式来减少交互次数，如当你要往一个表中插入1000万条数据时，如果采用普通的executeUpdate处理，那么和服务器交互次数为1000万次，按每秒钟可以向数据库服务器提交10000次估算，要完成所有工作需要1000秒。如果采用批量提交模式，1000条提交一次，那么和服务器交互次数为1万次，交互次数大大减少。

#### 3.2 合并查询语句

	for :var in ids[] do begin
  		select * from mytable where id=:var;
	end;

我们也可以做一个小的优化， 如下所示，用ID INLIST的这种方式写SQL：

	select * from mytable where id in(:id1,id2,...,idn);

#### 3.3 设置Fetch Size

当我们采用select从数据库查询数据时，数据默认并不是一条一条返回给客户端的，也不是一次全部返回客户端的，而是根据客户端`fetch_size`参数处理，每次只返回`fetch_size`条记录，当客户端游标遍历到尾部时再从服务端取数据，直到最后全部传送完成。所以如果我们要从服务端一次取大量数据时，可以加大`fetch_size`，这样可以减少结果数据传输的交互次数及服务器数据准备时间，提高性能。

### 4 减少CPU开销

#### 4.1 使用绑定变量

绑定变量是指SQL中对变化的值采用变量参数的形式提交，而不是在SQL中直接拼写对应的值。这样可以防止SQL注入并且提高SQL解析性能(硬解析变为软解析).

#### 4.2 大量复杂运算在客户端处理

一些复杂的运算，不要用数据库来处理.如含小数的对数及指数运算和加密处理等.

#### 4.3 减少特殊比较操作和合理使用排序

我们SQL的业务逻辑经常会包含一些比较操作，如`a=b`，`a<b`之类的操作，对于这些比较操作数据库都体现得很好，但是对一些特殊的比较操作，我们需要保持警惕. （如：like和IN（1,2,....n）n值过多），另外在使用SQL的确定是否需要排序，大量数据排序会增加CPU的开销。详细例子在后面章节列出。


----
