---
title: 2014年10月Reading Notes
date: 2014-10-15 21:52:17
categories: java
tags:
  - READING NOTES
---


## Why does my Java process consume more memory than Xmx?
https://plumbr.eu/blog/why-does-my-java-process-consume-more-memory-than-xmx

java进程内存消耗会大于我们在`-Xmx`中指定的值.`-Xmx`仅仅限制了应用程序使用的heap大小.java进的内存消耗主要包括下面的东东:

	Max memory = [-Xmx] + [-XX:MaxPermSize] + number_of_threads * [-Xss]+Other
	
Other:

* Garbage collection(GC自己需要消耗内存来记录数据)
* JIT optimization(JIT优化需要记录代码执行行为,Code cache-JIT编译完成后存放机器码)
* Off-heap allocations(NIO/DirectMemory之类的东东)
* JNI code(程序使用第三方JNI代码占用的内存)
* Metaspace(jdk8使用它取代了permgen)

## Understanding the OutOfMemoryError
https://plumbr.eu/blog/understanding-java-lang-outofmemoryerror

* java.lang.OutOfMemoryError: Java heap space

	heap空间不足.一般加大`-Xmx`.如果还不足就有可能是内存泄漏了.

* java.lang.OutOfMemoryError: PermGen space

	permgen空间不足,默认的jvm配置得比较小,需要通过`-XX:MaxPermSize`加大.动态代码生成技术和容器redeploy资源泄漏也会导致permgen不足

* java.lang.OutOfMemoryError: GC overhead limit exceeded

	jvm gc行为中超过98%以上的时间去释放小于2%的堆空间时会报这个错误

* java.lang.OutOfMemoryError: unable to create new native thread

	java没创建一个线程,会占用`-Xss`大小空间.这个异常有可能是系统内存不足导致.如果系统内存充足,往往是ulimit -u限制了一个用户创建最大线程数造成的.

* java.lang.OutOfMemoryError: Requested array size exceeds VM limit
	
	申请的数组大小超过jvm定义的阀值.

* java.lang.OutOfMemoryError: request <size> bytes for <reason>. Out of swap space?
* java.lang.OutOfMemoryError: <reason> <stack trace> (Native method)


## 20 Obstacles to Scalability
本文罗列了20个影响伸缩性的瓶颈

### 10 Obstacles to Scaling Performance

1. Two-Phase Commit
	
	两阶段提交需要等待参与方确认,延时太大.所以我们基本上使用best-effort 1pc+业务上的重试.

2. Insufficient Caching

	各个层次都需要引入缓存机制,现在我们对browser cache/page cache还做得比较少.
	
3. Slow Disk I/O, RAID 5, Multitenant Storage

	数据库服务起I/O很关键.如果只做raid建议做raid10.当然加上fushion io之类的加速卡更好.
	
4.  Serial Processing

	服务并行处理我们也还思考得比较少.比如对远程服务进行合理并行处理(可以考虑下java8中的CompletableFuture).对于缓存数据的获取,可以考虑批量获取.
	
5. Missing Feature Flags

	特性开关,说大点就是服务降级,我们需要却分不同服务的重要等级,适当时候关闭某些服务,保证核心业务正常运行.

6. Single Copy of the Database
7. Using Your Database for Queuing
8. Using a Database for Full-Text Searching
9. Object Relational Models(orm很好用,但是缺少能hold住他的人)
10. Missing Instrumentation(需要监控/profile工具)

### 10 Obstacles to Scaling Beyond Optimization Speed

1. Lack of a Code Repository and Version Control
2. Single Points of Failure
3. Lack of Browse-Only Mode(对于内容型的网站,此功能非常重要)
4. Weak Communication
5. Lack of Documentation
6. Lack of Fire Drills(却分演练,特别是大的运维调整,此项非常必要)
7. Insufficient Monitoring and Metrics
8. Cowboy Operations
9. Growing Technical Debt
10. Insufficient Logging
