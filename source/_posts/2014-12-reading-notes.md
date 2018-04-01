---
title: 2014年12月Reading Notes
date: 2014-12-14 21:52:17
categories: java
tags:
  - READING NOTES
---


## CPU Flame Graphs
http://www.brendangregg.com/FlameGraphs/cpuflamegraphs.html

java里可以很方便的通过`jvisualvm`来采样性能数据,然后分析每个线程栈中比较费时的cpu操作.java以外的程序,通过cpu火焰图来分析性能问题,很直观(比较起来,jvisualvm的cpu sample report没有cpu火焰图直观).

生成的`svg`报告中,`y轴`可以理解为调用栈层次,越大调用层次越深.`x轴`中的长度是调用占用时间比.

`CPU Flame Graphs`生成过程需要三步:

1. 采样性能数据([perf](https://perf.wiki.kernel.org/index.php/Tutorial#Counting_with_perf_stat), DTrace, SystemTap, and ktap) 
2. 转换性能数据  
3. 利用性能数据生成`svg`报告

## 协程
http://niusmallnan.github.io/_build/html/_templates/openstack/coroutine_usage.html
http://www.dongliu.net/post/5906310176440320

协程是纯软件实现的多任务调度,在软件层面实现任务的保持和恢复.传统的用多线程的方式来实现任务调度,在高并发场景下,CPU创建开销和CPU上下文切换的开销太大.使用协程,任务调度有程序来调度,不涉及到cpu线程切换和cpu大量创建线程,性能会快不少.

在使用协程时,所有的I/O都需要使用异步I/O,不然性能会大打折扣.

在协程中,不同的执行单元之间通信可以采用共享内存或者消息机制.由于共享内存又会引入共享资源的同步,推荐采用消息机制.

## 基于线程与基于事件的并发编程之争
http://www.jdon.com/46921

基于线程的并发变成带来了很多问题，很难写出高性能的程序。协程和Actor模型也许可以考虑用来降低CS的开销。


