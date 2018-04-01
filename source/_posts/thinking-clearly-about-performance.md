---
title: Thinking Clearly about Performance笔记
date: 2013-04-29 21:52:17
categories: java
tags:
  - Performance
---

## Thinking Clearly about Performance笔记

原文链接:[Thinking Clearly about Performance](http://queue.acm.org/detail.cfm?id=1854041)

### RESPONSE TIME VERSUS THROUGHPUT

响应时间和吞吐量没有太多关系.你要了解两个值需要测试两个值.下面两个例子说明为什么两者之间没有太多关系.

1. 应用吞吐量为1000笔/s,用户的平均响应时间是多少?

	如果应用下面是1000个服务提供者在提供服务,每一笔的响应时间最大可以为1s.所以,只能得出的结论是平均响应时间为0-1s
2. 客户对某应用的需求为在单cpu的服务器上吞吐量为100笔/s.现在你写的应用每次执行耗时1ms,你的程序满足客户需求吗?

    如果请求串行发过来,每次执行一个,一个执行完在执行下一个,这种情况应该还是可以满足需求的.但是如果这100个请求在1s内随机的发送过来,CPU调度器(比如线程上下文切换)和串行资源(比如CAS导致的重试)可能让你不能满足客户需求.
    
### PERCENTILE SPECIFICATIONS

平均并不能精确的定义响应时间.假如你能容忍的响应时间是1s,对于不同的应用,他们的平均响应时间都是1s.但是应用A90%的请求响应时间都小于1s和应用B60%的请求响应时间都小于1s,这两个应用提供的服务性能是不一样的.我们一般可以如下的形式来定义响应时间:`the “Track Shipment” task must complete in less than .5 second in at least 99.9 percent of executions.`

### PROBLEM DIAGNOSIS

明确用户的需求,用户不会精确的定义他对性能的需求.大多数时候,他只是说"系统太慢了,我们没办法使用",可以引导用户提出他的需求`Response time of X is more than 20 secondsin many cases. We’ll be happy when response time is one second or less in at least 95 percent of executions.`

### THE SEQUENCE DIAGRAM

The sequence diagram is a good tool for conceptualizing flow of control and the corresponding flow of time. To think clearly about response time, however, you need something else.

### THE PROFILE

A profile shows where your code has spent your time and—sometimes even more importantly—where it has not. There is tremendous value in not having to guess about these things.

With a profile, you can begin to formulate the answer to the question, “How long should this task run?” which, by now, you know is an important question in the first step of any good problem diagnosis.

![](http://deliveryimages.acm.org/10.1145/1860000/1854041/millsap-table2.png)

### AMDAHL’S LAW

Performance improvement is proportional to how much a program uses the thing you improved. If the thing you're trying to improve contributes only 5 percent to your task's total response time, then the maximum impact you'll be able to make is 5 percent of your total response time. This means that the closer to the top of a profile that you work (assuming that the profile is sorted in descending response-time order), the bigger the benefit potential for your overall response time.



### MINIMIZING RISK

when everyone is happy except for you, make sure your local stuff is in order before you go messing around with the global stuff that affects everyone else, too.

### LOAD

One measure of load is utilization, which is resource usage divided by resource capacity for a specified time interval.

There are two reasons that systems get slower as load increases: **queuing delay** and **coherency delay**.

* QUEUING DELAY

	Response time (R), in the perfect scalability M/M/m model, consists of two components: service time (S) and queuing delay (Q), or R = S + Q. 
	
当谈到性能时,你期望一个系统满足下面两个目标:

* 最佳的响应时间(不用等太久就能获得结果)
* 最佳吞吐量(能服务更多的人)

但是这两个目标是互相矛盾的,优化第一个目标,需要你较少系统的负载.优化第二个目标,又需要你提高系统使用率,增加负载.你不能同时满足这两个目标,只能权衡取舍.

### COHERENCY DELAY

Your system doesn’t have theoretically perfect scalability. Coherency delay is the factor that you can use to model the imperfection. It is the duration that a task spends communicating and coordinating access to a shared resource. 

The utilization value at which this optimal balance occurs is called the **knee**. This is the point at which throughput is maximized with minimal negative impact to response times. 