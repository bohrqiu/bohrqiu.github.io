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
 
1. 在应用启动时，编程式加载java agent(VirtualMachine#loadAgent)，spring 使用aspectj ltw(开发时运行)
2. 使用maven注解实现编译时植入(线上运行)

参考 [spring-boot-aspectj](https://github.com/dsyer/spring-boot-aspectj)

在spring.io上看到了不一样的声音: [Debunking myths: proxies impact performance](https://spring.io/blog/2007/07/19/debunking-myths-proxies-impact-performance/)

1. 这点性能比起长时间运行的任务来说太短了
2. 一个请求最多也不会经过10个proxy，`10 proxy operations * 500 ns per proxy operation = 5 microseconds`任然可以忽略不记

这个说法在当年还是有说服力的，现在就不怎么明显了，微服务、SOA大行其道，涉及到的aop会比较多，如果在基础设施上做一些改造，方便无感知的使用`byte code weaving`意义还是很大的。

## [sentinel](https://github.com/alibaba/Sentinel)

`Sentinel`提供流量控制、熔断降级、系统负载保护等功能。相对于`Hystrix`使用起来倾入性比较小。大致撸了一遍代码：

1. `SlotChainBuilder`构建每个`资源`对应的`ProcessorSlotChain`。
2. `ProcessorSlot`组成责任链来分离功能。(前面几个Slot用来做资源路由、统计，后面几个完成系统功能)。
3. `SystemSlot`实现系统负载保护功能。有趣的是参考[BBR](https://github.com/alibaba/Sentinel/wiki/%E7%B3%BB%E7%BB%9F%E8%B4%9F%E8%BD%BD%E4%BF%9D%E6%8A%A4)算法,当负载过高时，判断当前请求容量来减少对请求的拒绝。
4. `AuthoritySlot`黑白名单控制
5. `FlowSlot`流控
6. `DegradeSlot`降级

