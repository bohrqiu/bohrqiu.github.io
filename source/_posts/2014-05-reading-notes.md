---
title: 2014年05月Reading Notes
date: 2014-05-29 21:52:17
categories: java
tags:
  - READING NOTES
  - OOM Killer
  - vagrant
  - cxf unexpected element
  - 构建高可用系统
  - tomcat
  - maven
---

## 面向GC的Java编程

[http://coolshell.cn/articles/11541.html](http://coolshell.cn/articles/11541.html)

好文,总结的很不错.


## spring boot Initializr

[http://start.spring.io/](http://start.spring.io/)

有了这个,创建spring boot项目就快了.

## OOM Killer

很早听说OOM Killer这个东东,感觉很神秘.而且以前分析某次线上故障,我得出的结论是OOM Killer,但是没有找到日志,囧!最近在玩vagrant,用的ubuntu box,虚拟机内存分配512m,某应用配置jvm内存`-Xms256M -Xmx512m -XX:PermSize=64m -XX:MaxPermSize=256m`.应用在启动过程中日志刷了一会儿就不动了,`command+c`结束后,console报出:

	INFO: Initializing Spring root WebApplicationContext
	^C./tomcat.sh: line 6:  7649 Killed                  nohup mvn clean tomcat7:run -Dspring.profiles.active=$env -Dsys.name=$sysname > "$logfile" 2>&1 < /dev/null
	
找了很久,在`/var/log/syslog`发现如下日志:

	May 22 09:47:41 vagrant-ubuntu-saucy-64 kernel: [ 5499.448534] Out of memory: Kill process 7649 (java) score 788 or sacrifice child
	May 22 09:47:41 vagrant-ubuntu-saucy-64 kernel: [ 5499.449012] Killed process 7649 (java) total-vm:1460964kB, anon-rss:407220kB, file-rss:0kB
	
这篇文章解释如何处理[oom](http://www.vpsee.com/2013/10/how-to-configure-the-linux-oom-killer/)

## vagrant

https://github.com/astaxie/Go-in-Action/blob/master/ebook/zh/01.2.md

http://blog.segmentfault.com/fenbox/1190000000264347

http://docs.vagrantup.com/v2/getting-started/index.html

如果mac环境下虚拟机出现Failed to load VMMR0.r0 (VERR_SUPLIB_WORLD_WRITABLE),执行`sudo chmod o-w /Applications`再试试.

 
## 构建高可用系统的常用招数
 [http://bluedavy.me/?p=468](http://bluedavy.me/?p=468)
 
大牛的总结,分享+总结下:

1. 监控和报警
 	
 	监控和报警能提前发现问题/缩短故障时间,前提是得能正确的评估监控点.

2. SPoF(Single Point of Failure)
 
 	单点故障也分层次的,不过我们coder一般只关注服务层面.服务尽量做到无状态,只需要做负载就ok了.不能做成无状态的就需要做集群了.实在不行的就做成主备.
 	
3. 解耦
  	
	后端业务通过消息/事件来解耦(Eventbus也不错),前端页面模块化,互相不影响.
 	
4. 隔离
 
	隔离既要防止依赖的系统之间相互影响(防止故障传播),也要防止同一节点上的不同服务相互影响(资源隔离).
	
	宏观层面,区分服务重要性,如果都能服务化就好做了.不同服务可以选择配置不同个数的服务节点.重要的,访问量大的就多加点节点.这需要监控系统能准确评估服务访问情况.
	
	微观层面,在服务内部,服务对外提供的能力一般通过线程池大小和请求队列长度来控制.在这里,大不一定就好,多也不定就好.
	
 
5. 容灾
 
 	这里谈了几点:超时控制/非关键业务自动降级(用dubbo实现就很方便)/手动降级/自恢复能力(比如druid连接池)/自我保护能力
 
自己补充点,快速故障恢复能力(日志很重要)/避免人为故障(减少开发人员犯错误的机会)/简单可依赖(能简单做的就绝对不玩花哨) 
 
## Uses MySQL to store schema-less data
[http://backchannel.org/blog/friendfeed-schemaless-mysql](http://backchannel.org/blog/friendfeed-schemaless-mysql)

如何用mysql来存储schema-less的数据,实现很简单.

数据表:
	
	CREATE TABLE entities (
    	added_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    	id BINARY(16) NOT NULL,
   	 	updated TIMESTAMP NOT NULL,
    	body MEDIUMBLOB,
    	UNIQUE KEY (id),
    	KEY (updated)
	) ENGINE=InnoDB;
	
假如内容是:
	
	{
    	"id": "71f0c4d2291844cca2df6f486e96e37c",
    	"user_id": "f48b0440ca0c4f66991c4d5f6a078eaf",
    	"feed_id": "f48b0440ca0c4f66991c4d5f6a078eaf",
    	"title": "We just launched a new backend system for FriendFeed!",
    	"link": "http://friendfeed.com/e/71f0c4d2-2918-44cc-a2df-6f486e96e37c",
    	"published": 1235697046,
    	"updated": 1235697046,
	}
如果要给title建立索引,创建新表

	CREATE TABLE index_title (
    	title varchar(100) ,
    	entity_id BINARY(16) NOT NULL UNIQUE,
   		PRIMARY KEY (user_id, entity_id)
	) ENGINE=InnoDB;

查询的时候先从索引表查出entity_id,然后在去entities表查询详细数据.可以存储数据为text,方便数据库直接操作(必要性不是很大,text太占内存了),当然最好还是存储压缩后的二进制数据.不是经常改动的数据,应用层在加上一层cache.

索引可以异步建立,定时任务周期性的去找updated的新数据.


## 为什么tomcat应用三分钟还关不掉

这种问题一般是因为还有非deamon线程在容器关闭时没有正确的关闭导致的.可以在执行tomcat shutdown脚本后,jstack线程栈,看下还有哪些非deamon线程在执行.

应用使用线程持一定要记得关闭线程池,可以用spring提供的.

	<bean id="taskExecutor"
          class="org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor">
        <property name="corePoolSize" value="10"/>
        <property name="keepAliveSeconds" value="200"/>
        <property name="maxPoolSize" value="50"/>
        <property name="queueCapacity" value="1000"/>
        <property name="awaitTerminationSeconds" value="60"/>
        <property name="waitForTasksToCompleteOnShutdown" value="true"/>
    </bean>
注意最后面两个参数.

## The New RBAC: Resource-Based Access Control

最近看看shiro的相关资料,看到这篇文章.以前也隐隐约约思考过权限控制,也感觉[RBAC](http://en.wikipedia.org/wiki/Role-Based_Access_Control)控制粒度太粗了.作者提到`Explicit Access Control`概念,通过资源来解耦角色,控制粒度更细.从权限的分配角度来说,这样使用也更方便,可以把权限分配到某个用户/某个组/某个角色.

当然,我们把资源的权限和角色一一对于,角色有层次关系并且可以继承,RBAC也可以胜任细粒度的权限控制.