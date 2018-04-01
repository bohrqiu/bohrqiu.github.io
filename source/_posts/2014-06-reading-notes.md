---
title: 2014年06月Reading Notes
date: 2014-06-28 21:52:17
categories: java
tags:
  - READING NOTES
  - tengine
  - web-starter-kit
  - microservice

---

## Awesome Sysadmin

[https://github.com/kahun/awesome-sysadmin](https://github.com/kahun/awesome-sysadmin)

系统管理员的开源资源,资源暴多,技术选型时参考.


## Tengine
[http://dmsimard.com/2014/06/21/a-use-case-of-tengine-a-drop-in-replacement-and-fork-of-nginx/](http://dmsimard.com/2014/06/21/a-use-case-of-tengine-a-drop-in-replacement-and-fork-of-nginx/)

使用tengine来做LB,通过Tengine的`unbuffered requests`特性实现了上传性能提升.

不过我自己装tengine启动就遇到了问题.

	the configuration file //Users/bohr/software/tengine/conf/nginx.conf syntax is ok
	nginx: [emerg] mkdir() "//Users/bohr/software/tengine/logs/access.log" failed (21: Is a directory)
	configuration file //Users/bohr/software/tengine/conf/nginx.conf test failed


## 服务器操作系统应该选择 Debian/Ubuntu 还是 CentOS？

[http://www.zhihu.com/question/19599986](http://www.zhihu.com/question/19599986)

生产环境选择操作系统还是要慎重.现在我厂在线上用ubuntu,遇到过几次诡异事件(服务器无缘无故挂了,没有任何日志,时间跳变),看了这篇文章,SA应该会把线上的linux服务器统一了吧.


## web-starter-kit
[https://github.com/google/web-starter-kit](https://github.com/google/web-starter-kit)

Web Starter Kit is a starting point for multi-screen web development. It encompasses opinionated recommendations on boilerplate and tooling for building an experience that works great across multiple devices.


## 微服务：分解应用以实现可部署性和可扩展性
[http://www.infoq.com/cn/articles/microservices-intro](http://www.infoq.com/cn/articles/microservices-intro)
[http://microservices.io/index.html](http://microservices.io/index.html)

文章讨论了整体架构和微服务构架的优缺点.对于大型应用而言,微服务架构当然是首选.

API网关模式用于解耦应用客户端和微服务.我们可能没有考虑对不同的客户端提供不同粒度的服务(不同客户端的网络环境不一样).

对于非强一致性数据要求的场景,`事件驱动的异步更新`(服务发布事件声明有些数据发生了变化，其他的服务订阅这些事件并更新它们的数据)解耦了事件的生产者和消费者,简化了开发也提升了可用性.某应用,很多配置数据都存在memcache中,一笔业务需要查询缓存>5次,每次都要去查,感觉很不爽.还是使用本地缓存+事件驱动的异步更新来做比较好.
