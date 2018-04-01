---
title: hibernate应用报could not initialize proxy - no Session分析
date: 2014-07-17 21:52:17
categories: java
tags:
  - hibernate
---


### 1.场景描述:
		
某项目使用hibernate,在切换到dubbo后,在构造结果对象时从延迟加载对象中获取数据时,报`org.hibernate.LazyInitializationException: could not initialize proxy - no Session`
	
构造结果对象的操作没有在事务环境下执行.
	
### 2.原因分析:
	
cxf不报错是因为在web.xml中配置了`org.springframework.orm.jpa.support.OpenEntityManagerInViewFilter`,在请求到达web filter后,创建了`EntityManager`,请求结束后关闭`EntityManager`.在请求线程处理过程中,都可以拿到`EntityManager`,所以不会报错(至少可以从ThreadLocal中拿到).
	
切换为dubbo后,请求不会经过web filter,在事务模版代码中执行业务操作,可以正确的拿到`EntityManager`,不会报错.但是执行到构造结果对象时,就悲剧了.
	
	
### 3.解决办法:
	
1.修改模版方法,把构造结果对象部分的代码也放到事务中执行.
		
2.编写支持dubbo的OpenEntityManagerInViewFilter
		
  可以通过`TransactionSynchronizationManager`做到如果`EntityManagerFactory`在线程变量中不存在则创建`EntityManager`,服务处理结束时,关闭`EntityManager`.
		
	
### 4.优劣分析
	
1. 性能考虑
	
	`open session in veiw`模式还是不怎么优雅,事务执行链路太长了,会影响性能.而且对于我们提供的服务接口来说,构造结果对象已经是最后一步了,后面再也不需要延迟加载对象,不需要在filter里面来做此操作.
	
	web应用有在渲染模版时读取延迟加载对象的场景,这种场景使用还有意义.
	
2. 功能角度
	
	如果遇到应用内的两个dubbo服务调用,dubbo会走injvm协议.此时请求不会经过io栈,但是会执行所有的dubbo filter.
		
	比如外部请求调用服务A,服务A调用内部服务B.
		
	外部请求调A时,filter创建`EntityManager`,然后调用服务B时,filter不创建`EntityManager`,但是在请求B结束时,filter关闭了`EntityManager`.在请求A中处理剩下的业务逻辑,如果遇到要操作数据库,就只有哭了.
		
	为什么web请求就不怕这种filter重入呢?web请求在forward时,你必须把request对象带进去,所以可以在request对象的attribute里面记录是否进过了这个filter.可以参考`org.springframework.web.filter.OncePerRequestFilter`.但是调用dubbo时,你只需要拿到服务代理对象就ok了,没有办法来知道整个请求链的情况.
		
		
### 5.最后结论

还是修改下我们自己的代码,把构造结果对象部分的代码也放到事务中执行.
	

	