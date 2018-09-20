---
title: java开发工程师可以了解的常用命令
date: 2014-08-06 21:52:17
categories: java
tags:
  - 常用命令
---

先总结下常用的一些监控工具:

## linux命令

* `w`
	
	系统负载
	
* `lsof -p pid`
	
	进程打开的文件
	
* `lsof -i:port`
	
	端口的运行情况
	
* `free -m`

	内存情况
	
* `vmstat`
	
	进程、内存、内存分页、堵塞IO、traps及CPU活动的信息
	
* `iostat`

	磁盘io情况
	
* `top -n 1`

	cpu/负载/内存等使用情况.
	
* `iotop`

	磁盘io
    
* `ps aux | sort -k6nr | head -n 10`

	查看linux 实际内存占用最多的10个
	
* `ps aux | sort -k5nr | head -n 10`

	查看linux 虚拟内存占用最多的10个
	
* `dstat -lamps`

	查看系统整体状况
	
* `pstree -al pid|head -n 1`

	查看进程启动命令

* `strace -T -p pid`

	查看进程系统调用.开销很大,使用时要小心.

* `netstat`

	`netstat -an |grep port` 查看端口连接情况

	`netstat -alnp |grep pid` 通过pid查看进程所有端口情况

* `ss -lntp |grep port`

	通过端口查看进程

* `nmon`
    
	强大的监控工具.也可以方便的出报表.我一般用来在压力测试时监控系统性能.

* `latencytop`

	用于查看系统内部慢.以前做mysql性能优化,多亏有这东东.

* `cat /proc/pid/status  |grep Threads`

	查看进程内线程个数
    
## java工具

* `jvisualvm`

	jvm的运行情况/各种dump的分析都可以干,没有JRMC牛.oracle承诺会把JRockit的特性迁移到HotSpot上面来.现在jdk下已经有jmc了.
	
* `jps -lv`

	查看所有java进程.

* `jinfo -sysprops pid`

	查看java进程系统参数

* `jinfo  -flag jvmflag pid`

	查看jvm flag.比如查看xss,`jinfo  -flag ThreadStackSize pid`

* `jstack pid`

	查看线程栈信息

* `jmap -dump:live,format=b,file=xxx.hprof pid`

	生成heap dump

* `jmap -histo pid`

	查看java堆中对象统计信息
	
* `java -XX:+UnlockDiagnosticVMOptions -XX:+PrintFlagsFinal` 

	查看jvm flag
	
		The first column appears to reflect the data type of the option (intx, uintx, uint64_t, bool, double, ccstr, ccstrlist). 
		The second column is the name of the flag and the third column is the value, if any, that the flag is set to.
		The fourth column appears to indicate the type of flag and has values such as {product},{pd product}, {C1 product} for client or {C2 product} for server, {C1 pd product} for client or {C2 pd product} for server, {product rw}, {diagnostic} 
		(only if -XX:+UnlockDiagnosticVMOptions was specified), {experimental}, and {manageable}. See Eugene Kuleshov's The most complete list of -XX options for Java 6 JVM for a brief description of most of these categories as well as a listing of most of these options themselves.
		
* [tda](http://visualvm.java.net/plugins.html​)

	线程栈分析器,这个是jvisualvm的插件.
	
* [mat](http://www.eclipse.org/mat/)

	基于eclipse的heap dump分析工具,这个工具是比jvisualvm在heap分析这块专业.不过jvisualvm能cover住大多数场景,基本上我都只用jvisualvm了.
	
* `jmap -heap pid`

	检查heap情况
	
* [GCViewer](https://github.com/chewiebug/GCViewer)

	GC日志分析
	
* `jstat  -gcutil pid`

	查看gc总体情况
	
		S0  — Heap上的 Survivor space 0 区已使用空间的百分比
		S1  — Heap上的 Survivor space 1 区已使用空间的百分比
		E   — Heap上的 Eden space 区已使用空间的百分比
		O   — Heap上的 Old space 区已使用空间的百分比
		P   — Perm space 区已使用空间的百分比
		YGC — 从应用程序启动到采样时发生 Young GC 的次数
		YGCT– 从应用程序启动到采样时 Young GC 所用的时间(单位秒)
		FGC — 从应用程序启动到采样时发生 Full GC 的次数
		FGCT– 从应用程序启动到采样时 Full GC 所用的时间(单位秒)
		GCT — 从应用程序启动到采样时用于垃圾回收的总时间(单位秒)

* `btrace`

	神器,线上出问题了,想知道某个方法的调用情况,入参之类的,就靠btrace了.
此工具大致原理如下:

	1. `btrace-client` attach 目标进程(`com.sun.tools.attach.VirtualMachine#attach`)
	2. 加载agent `btrace-agent` (`com.sun.tools.attach.VirtualMachine#loadAgent`)
	3. agent启动服务端,开启监听端口
	4. `brace-client` 把编译好的用户btrace代码发送到服务端,并等待服务端响应
	5. `btrace-agent` 通过asm修改运行时代码,织入用户btrace代码逻辑.监控到信息后,发给`btrace-client`

* jmc

	生成记录

		#检查特性是否开启
		jcmd 23385 VM.check_commercial_features
		#开启商业特性
		jcmd 23385 VM.unlock_commercial_features
		#检查JFR状态
		jcmd 23385 JFR.check
		#执行180sJFR收集
		jcmd 23385 JFR.start name=recording filename=/root/recording.jfr duration=180s

* vjtools

	https://github.com/vipshop/vjtools 主要工具vjtop非常有用，打印JVM概况及繁忙线程