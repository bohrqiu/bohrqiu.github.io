---
title: 2016年06月Reading Notes
date: 2016-06-19 21:52:17
categories: java
tags:
  - READING NOTES
  - nginx plus
---
	
## Service Wiring with Spring Cloud

https://www.infoq.com/articles/spring-cloud-service-wiring

这篇文章聊到了spring cloud如何提供配置管理、服务发现、服务路由能力。结合我们的现状谈谈：

1. 有些应用没有做到cloud-ready，依赖服务地址配置信息写死。。
2. 内部请求用dubbo，实现了服务发现，服务路由，大多数问题已经hold住了
3. 自研的配置管理系统可以做到配置动态更新，比spring cloud 下的`Enabling Dynamic Refresh`做法优雅多不少
4. 还需要提供http服务的服务注册、发现能力。为外部http负载均衡、内部http服务依赖提供服务发现、服务路由能力

