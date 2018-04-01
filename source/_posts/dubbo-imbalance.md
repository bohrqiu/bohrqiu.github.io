---
title: dubbo线程任务"不均衡"问题分析
date: 2014-09-23 21:52:17
categories: java
tags:
  - dubbo
---

dubbo应用使用的线程池为`com.alibaba.dubbo.common.threadpool.support.fixed.FixedThreadPool`,如果当queue设置为0时,会使用`SynchronousQueue`,这个东东导致了任务线程执行"不均衡"(满足了大家的心理预期,其实这种不均衡方式减少了上下文切换,但是`SynchronousQueue`没有大小,不能起到任务缓冲的作用).


请在dubbo:protocol上加上queues大小(参考tomcat默认配置).

	    <dubbo:protocol name="dubbo" port="${dubbo.provider.port}" threads="200" queues="100"/>


测试:

修改前:

	grep DubboServerHandler dubbo-demo.log |awk  -F '-'  '{print $6}' |awk  -F ']'  '{print $1}' |sort -n |uniq -c
         1 150
      1 151
      1 152
      1 153
      1 154
      1 168
      1 169
      1 170
    117 171
   	5386 172
    714 173
   	2646 174
   	3738 175
   	3105 180
   	6332 194
   	2483 195
   	4940 196
   	1211 197
   	5661 198
   	5428 199
   	1393 200

修改后:

	grep DubboServerHandler dubbo-demo.log |awk  -F '-'  '{print $6}' |awk  -F ']'  '{print $1}' |sort -n |uniq -c
    507 1
    498 2
    496 3
    501 15
    488 16
    494 17
    523 18
    502 19
    494 20
    503 21
    491 22
    507 23
 		...
     507 133
    495 134
    498 135
    494 136
    507 137
    508 151
    490 152
    494 195
    496 196
    496 197
    506 198
    493 199
    489 200

