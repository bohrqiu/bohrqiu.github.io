---
title: 2014年08月Reading Notes
date: 2014-08-03 21:52:17
categories: java
tags:
  - READING NOTES
  - docker
  - java
---

## My WordPress Development Toolbox

[http://tommcfarlin.com/wordpress-developer-toolbox/](http://tommcfarlin.com/wordpress-developer-toolbox/)

本来是准备找git的客户端,看到这篇文章.不喜欢tower,大爱[SoureTree](http://www.sourcetreeapp.com/).

[browserstack](http://www.browserstack.com/)也挺好的,适合做浏览器兼容性测试.

## JVM plus Docker: Better together
[http://www.javaworld.com/article/2456960/java-app-dev/jvm-plus-docker-better-together.html](http://www.javaworld.com/article/2456960/java-app-dev/jvm-plus-docker-better-together.html)

docker刚好弥补jvm对资源管理(CPU/IO)的不足.

## SharedHashMap vs Redis
[http://vanillajava.blogspot.jp/2014/05/sharedhashmap-vs-redis.html](http://vanillajava.blogspot.jp/2014/05/sharedhashmap-vs-redis.html)

这位哥异常牛掰,java低延迟方面的专家.把性能做到极致啊!!!`It was designed to be used in Java in a pause less, garbage free manner.`狂赞!!!先留着,有时间了看看源代码.

## 高性能服务器架构
[http://blog.csdn.net/zhoudaxia/article/details/14223755](http://blog.csdn.net/zhoudaxia/article/details/14223755)

这些经验可以参考下:

* 数据拷贝

	特别是java,很多数据拷贝的代码埋得深,比如`StringBuilder`扩容,集合扩容等等.java中的数据拷贝除了带来cpu的压力,也会给gc带来压力.

	参考:[使用零拷贝提高数据传输效率](/zero-copy/)

* 上下文切换

	线程越多,上下文切换就会越多.需要合理评估处理模型和系统情况.按照SEDA的方式把一个请求划分为多个阶段,但是多个阶段的独立线程池真的会增加上下文的切换,但这样可能会让系统利用率最高.

* 内存分配

	采用类似于Buddy memory allocation的策略来减少开销.

* 锁竞争

	一定要控制好锁的粒度.某些场景用map来存放锁对象,而不要使用一把大锁.

## 数据库版本控制工具liquibase
[http://www.liquibase.org/quickstart.html](http://www.liquibase.org/quickstart.html)

今天和勇哥讨论了如何来控制数据库版本.我们想的方案是,数据库里面有张versions表,里面记录当前的版本是多少.然后数据库更新文件存在项目中,并以目录来区分.这样就可以在项目启动时,来对比是否有新版本,是否需要升级.这样可以做到全自动化,需要规范现在的开发同学的行为,更重要的一点是,没有人来做这个事情.

liquibase正好在做这个事情,他也支持sql格式的版本,学习成本相当低.而且有内置的数据库版本和集群场景的检测,给力,先试试.

参考:[如何跟踪数据库结构变动](/database-version/)

## 可伸缩性最佳实践：来自eBay的经验
(http://www.infoq.com/cn/articles/ebay-scalability-best-practices)[http://www.infoq.com/cn/articles/ebay-scalability-best-practices]

手里有本2011年的架构师特刊,翻开看到的第一篇文章.虽然有点老了,但是经验还是值得我们借鉴.

* 按功能分割

咱们现在的架构体系基本上遵循这条最佳实践.借助于dubbo/cxf实现功能服务化.应用层可以实现水平线性扩展.

* 水平切分

应用层面的无状态很重要,会话之类的东西可以放在缓存服务器上,尽量让LB来实现水平切分.

数据库层面读写分离/分区/分库/分表.

* 避免分布式事务

分布式第一定律,不要使用分布式.特别是两阶段提交,对系统的吞吐影响很大.ebuy通过周密调整数据库操作的次序、异步恢复事件，以及数据核对（reconciliation）或者集中决算（settlement batches）来实现最终一致性.

* 用异步策略解耦程序

组件之间的异步带来的好处是解耦/缓冲压力.组件内的异步能提供跟灵活的资源管理策略(当然带来了上下文切换的开销).我们还需要异步任务管理/确保机制.

* 将过程转变为异步的流
* 虚拟化所有层次

虚拟化所有层次我们还做的不够好.硬件资源层面的虚拟化可以通过docker来实现.目前docker最缺少的是资源的管理/发现/注册能力.通用资源服务层面的虚拟化也可以通过注册中心来实现.结合配置管理系统/框架组件化,可以做到对应用的透明.

* 适当地使用缓存

缓存组件很多,分布式/集中式/进程内,不要选花了眼.同类型的我们只需要一种缓存组件,他必须要能支持丰富的数据结构,如果能提供持久话的能力最好(前提是在down掉的情况下要保证数据的一直.).

## Why Choose Jetty?
[https://webtide.com/why-choose-jetty/](https://webtide.com/why-choose-jetty/)

一直有想法把jetty嵌入到我们的程序中来运行,jetty自身的体系结构优势便于我们去裁剪或者新增功能.

jetty的设计哲学很酷:
>Don’t put your application into Jetty, put Jetty into your application.

## http proxy

[http://rehorn.github.io/livepool/](http://rehorn.github.io/livepool/)

[http://mitmproxy.org/](http://mitmproxy.org/)

两个都是好东东.可以看下手机里面在干啥,吐槽下某些粗制滥造的app.也可以用来模拟http请求.

## jvm flag

[http://stas-blogspot.blogspot.jp/2011/07/most-complete-list-of-xx-options-for.html](http://stas-blogspot.blogspot.jp/2011/07/most-complete-list-of-xx-options-for.html)

最全的jvm flag.
