---
title: 开发规范
date: 2018-05-20 21:52:17
categories: java
tags:
  - spec
---

>> 几年前写的东西，已经离职，留作纪念

# 易极付开发规范

>版本 |	时间	  |作者	|修订章节	|修订内容
>----|----------|-----|-------|--------
>0.5 |2012-05-23 |培根|	全部	|初始版本
>1.0 |2015-04-11|秋波|全部|优化、补充
>1.1 |2015-04-14|秋波|全部|增加目录
>1.2 |2015-09-24|秋波|全部|增加用户信息安全



## 目录

1. [操作规范](#OperationSpec)
1. [日志规范](#LogSpec)
1. [注释规范](#CommentSpec)
1. [安全规范](#SecuritySpec)
1. [编码规范](#CodeSpec)
1. [通用规范](#CommonSpec)
2. [数据库规范](#MySQLSpec)
2. [maven规范](#MavenSpec)
2. [访问权限规范](#AccessSpec)

***
## <a name="OperationSpecification">一、操作规范</a>

### 1. 模板及格式化

易极付开发人员必须保证代码格式化的一致性，否则可能会导致代码冲突，轻微的耗费人力合并代码；严重时可能导致代码丢失，引起bug或者故障。

* 开发人员必须配置易极付的codetemplates.xml代码模板文件;
* 开发人员必须配置易极付的YJFFormatter.xml代码格式化文件;
* 每次提交代码之前，必须对java代码format;

IDE设置参考：[IDE设置代码格式和代码模板配置](http://wiki.yiji.dev/pages/viewpage.action?pageId=3310402)

### 2. 代码提交

* 任何代码禁止出现“System.out.println”、”// TODO Auto-generated method stub”
* 提交代码前使用checkstyle、findbugs、pmd扫描代码，禁止提交**严重**以上问题
* 不准提交工程下IDE自动生成的代码,比如.classpath、target、.idea、*.iml

### 3. 垃圾清理

* 对于从来没有用到的或者被注释的方法,变量,类,配置文件,动态配置属性等要坚决从系统中清理出去,避免造成过多垃圾

### 4. 版本控制工具

* git项目必须要有.gitignore文件，文件内容[参考](http://gitlab.yiji/qzhanbo/yiji-boot/raw/master/.gitignore)
* git项目工作流必须遵循[易极付git项目开发工作流规范](http://gitlab.yiji/yanglie/git-camp/blob/master/git-standard/yiji-git-workflow.md)
* 为防止冲突,任何时候,代码(及配置文件)提交前,先从svn/git中更新代码和配置文件,以及早发现不兼容的代码变更和冲突
* 提交代码(及配置文件)时,如果发生冲突时,先看历史说明,再找相关人员确认,坚决不允许强制覆盖
* svn目录结构应该包括3个代码目录：`trunk`、`tags`、`branches`。如果项目有文档，应该增加`doc`目录，禁止把文档放到代码目录


## <a name="LogSpec">二、日志规范</a>

参考：{% post_link spec_log 日志规范 %}

## <a name="CommentSpec">三、注释规范</a>

* 类注释和版权注释，请使用`file template`自动生成。
* 接口方法注释如下：

		/**
		 * 删除用户收藏的一个商品。
		 * 逻辑删除：delete_flag置为1
		 *
		 * @param memberId  会员ID
		 * @param itemSku   商品序列号
		 *
		 * @return 是否删除成功：1.成功，0.失败
		 * @throws ServiceCustomException
		 */

	接口方法注释每个入参必须有中文解释，且全局统一名称，返回对象是`boolean`或`int`型时，解释返回结果含义，加入必要的抛出异常规则。

* 方法体内注释如下：

		// 1. 尝试更新已有的收藏
		int updateForCreate = dao.doUpdate(memberId, itemSku);
		// 2. 更新成功，返回新增成功
		if (updateForCreate > 0) {
		return updateForCreate;
		}
		// 3. 没有更新成功则需要添加用户收藏信息

	禁止在每行的尾部注释。


## <a  name="SecuritySpec">四、安全规范</a>

请参考[安全checklist](http://wiki.yiji.dev/pages/viewpage.action?pageId=3310408)

## <a name="CodeSpec">五、编码规范</a>

java代码必须严格遵循[google编码规范](google-java-code-style.md)

## <a  name="CommonSpec">六、通用规范</a>

### 1. 异常处理

* 捕捉到的异常，不允许不作任何处理就截断，至少要记入日志，或重新抛出
* 最外层的业务使用者，必须处理异常，将其转化为用户可以理解的内容

### 2. 资源的使用

* 对系统资源的访问,使用后必须释放系统资源。这类资源包括:文件流、线程、网络连接、数据库连接等。
* 对于文件、流的IO操作,必须通过finally关闭。可以考虑使用jdk7以后新增的try-resource来关闭资源
* 对于线程,线程资源必须通过线程池提供,不允许在应用中自行显式创建线程
* 对于网络连接不数据库连接,必须由框架通过连接池提供,不允许应用 中自行建立网络不数据库连接

### 3. 本地事务操作

* 对于业务逻辑上不允许并发访问的数据(例如：具有全局唯一性的数据, 涉及到总和类的数据等) ,必须采用事务和加锁的方式进行处理
* 对于业务逻辑上要求数据完整性的数据(例如：同时操作多个表,对同一 个表反复进行操作等) ,必须采用事务的方式进行处理

### 4. 线程安全处理

* 虽然容器会负责多线程的处理,但是程序中还是会遇到很多线程安全的问题, 开发人员必须注意并发处理,否则可能导致死锁或者资损
* 线程上下文变量的设置清除必须配对
* 静态Util或单例必须是线程安全。
* DateFormat是非线程安全的,类变量使用时会被破坏。每次使用都要重新构造,或者使用DateUtil工具类
* 为记录加锁时,需要保持一致的加锁顺序,否则可能会造成死锁

### 5. 用户信息安全

* 禁止把用户敏感信息(用户密码、银行卡、信用卡等信息)输出到日志

	学习并使用下面三个注解：

		@ToString.Maskable 调用ToString#tostring时输出掩码
		@ToString.Invisible 调用ToString#tostring时不输出
		@JSONField(serialize = false) json序列化时不输出，要考虑是否有反序列的情况

* 禁止把用户敏感信息告知给其他人
* 出现用户敏感信息泄露时，不能扩散、传播、留存，请立即通知技术总监

## <a name="MySQLSpec">七、数据库规范</a>

{% post_link spec_mysql MySQL数据库开发规范 %}


## <a name="MavenSpec">八、maven规范</a>

{% post_link spec_maven maven规范 %}


## <a name="AccessSpec">九、访问权限规范</a>

* 禁止把测试页面暴露到公网
* 禁止把http定时任务url暴露到公网
* **禁止测试环境直接访问线上**
* **禁止把生产数据导到本地**
* 禁止把管理、统计功能直接暴露到公网(boss功能、druid管理页面等)
