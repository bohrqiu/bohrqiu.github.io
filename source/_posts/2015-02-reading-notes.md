---
title: 2015年02月Reading Notes
date: 2015-02-16 21:52:17
categories: java
tags:
  - READING NOTES
---

## Java Lambdas and Low Latency
[http://vanillajava.blogspot.hk/2015/01/java-lambdas-and-low-latency.html](http://vanillajava.blogspot.hk/2015/01/java-lambdas-and-low-latency.html)

 
 `Lambdas`创建了新对象，在低延迟应用中会给`gc`带来一点点压力。[Escape Analysis](http://docs.oracle.com/javase/7/docs/technotes/guides/vm/performance-enhancements-7.html)(分析对象的使用范围，来做性能优化，比如锁消除，消除对象分配...)能减少这种压力。可以通过jvm参考`-XX:BCEATraceLevel=3`查看逃逸分析情况，进一步设置`-XX:MaxBCEAEstimateSize`来调整`Maximum bytecode size of a method to be analyzed by BC EA.`
 
## Catch common Java mistakes as compile-time errors
[http://errorprone.info/](http://errorprone.info/)

静态代码分析工具又添一员，在编译时检查常见的java代码错误。在jdk8下貌似run不起来。
 