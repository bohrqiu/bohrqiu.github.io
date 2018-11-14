---
title: 2018年11月Reading Notes
date: 2018-11-13 21:52:17
categories: java
tags:
  - READING NOTES
  - aop
---
	
## AOP Benchmark

一直觉得spring proxy aop性能比较差，看了[AOP Benchmark](https://web.archive.org/web/20150520175004/https://docs.codehaus.org/display/AW/AOP+Benchmark)没想当差别这么大。曾今在一个项目中改用aspectj，成本有点高，也不便于团队协作。先埋个思路在这里：

1. 在应用启动时，编程式加载java agent(VirtualMachine#loadAgent)
2. spring 使用aspectj ltw

参考 [spring-boot-aspectj](https://github.com/dsyer/spring-boot-aspectj)

在spring.io上看到了不一样的声音: [Debunking myths: proxies impact performance](https://spring.io/blog/2007/07/19/debunking-myths-proxies-impact-performance/)

1. 这点性能比起长时间运行的任务来说太短了
2. 一个请求最多也不会经过10个proxy，`10 proxy operations * 500 ns per proxy operation = 5 microseconds`任然可以忽略不记

这个说法在当年还是有说服力的，现在就不怎么明显了，微服务、SOA大行其道，涉及到的aop会比较多，如果在基础设施上做一些改造，方便无感知的使用`byte code weaving`意义还是很大的。
