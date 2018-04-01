---
title: 2015年11月Reading Notes
date: 2015-11-01 21:52:17
categories: java
tags:
  - READING NOTES
  - spring-session
---
	
## <a name="spring-session">Next Generation Session Management with Spring Session</a>

[http://www.infoq.com/articles/Next-Generation-Session-Management-with-Spring-Session](http://www.infoq.com/articles/Next-Generation-Session-Management-with-Spring-Session)

在大规模集群的场景，无状态的应用能减少运维成本、缩短应用恢复时间。spring session主要解决了web应用session持久化的问题。把session存储在应用外部，让应用无状态。

spring session主要提供如下能力：

1. 把session的存储逻辑抽取出来，可以选择rdis，或者自己实现session存储
2. 使用websocket也能保持会话
3. 非web应用也能使用会话
4. 支持多个session(可以登陆多个用户)
5. Restful API也能通过http header维护会话

spring session 1.1版本支持`HttpSessionListener`.如果使用的redis，spring session通过key过期时的过期事件+redis消息推送来实现。可惜我们用的是`codis`，我们实现了`DisabledRedisMessageListenerContainer`把这个能力屏蔽了。

更多参考：[spring session 官方文档](http://docs.spring.io/spring-session/docs/current-SNAPSHOT/reference/html5/#introduction) [Add HttpSessionListener Support](https://github.com/spring-projects/spring-session/issues/4)

## <a name="the-twelve-factor-app">The Twelve-Factor App</a>

[http://12factor.net](http://12factor.net)

The twelve-factor app is a methodology for building software-as-a-service apps.

1. Codebase:One codebase tracked in revision control, many deploys

	one codebase per app（all tracked in revision control）, but there will be many deploys of the app(one or more staging use same code,use multi config file or configuration management system for different stage ). 
	
2. Dependencies:Explicitly declare and isolate dependencies

	 declares all dependencies via a dependency declaration manifest,and use dependencies check strategy to ensure that no implicit dependencies.
	
3. Config:Store config in the environment

	use mutli config file （[build env-awared app](http://bohr.me/env-aware/)）	 or use configuration management system （[spring cloud config](http://cloud.spring.io/spring-cloud-config/)）
	
4. Backing Services:Treat backing services as attached resources

	app makes no distinction between local and third party services（both are attached resources）. A deploy should be able to swap out a local MySQL database with one managed by a third party (such as Amazon RDS) without any changes to the app’s code. 
	
5. Build, release, run:Strictly separate build and run stages

	app uses strict separation between the build, release, and run stages. For example, it is impossible to make changes to the code at runtime, since there is no way to propagate those changes back to the build stage（we can put dynamic part code into db ）.
	
6. Processes:Execute the app as one or more stateless processes

	Twelve-factor processes are stateless and share-nothing. Any data that needs to persist must be stored in a stateful backing service, typically a database.Sticky sessions should never be used or relied upon. 
	
7. Port binding:Export services via port binding

	The twelve-factor app is completely self-contained and does not rely on runtime injection of a webserver into the execution environment to create a web-facing service. The web app exports HTTP as a service by binding to a port, and listening to requests coming in on that port.
	
8.  Concurrency:Scale out via the process model

	processes are a first class citizen.Processes in the twelve-factor app take strong cues from the unix process model for running service daemons. Using this model, the developer can architect their app to handle diverse workloads by assigning each type of work to a process type.
	
9. Disposability:Maximize robustness with fast startup and graceful shutdown

	Processes should strive to minimize startup time.
	
	Processes shut down gracefully （ ceasing to listen on the service port,thereby refusing any new requests, allowing any current requests to finish, and then exiting.）when they receive a SIGTERM signal from the process manager.
	
	For a worker process, graceful shutdown is achieved by **returning the current job to the work queue**.Implicit in this model is that all jobs are **reentrant**, which typically is achieved by wrapping the results in a transaction, or making the operation `idempotent`.
	
	Processes should also be robust against sudden death, in the case of a failure in the underlying hardware.  A recommended approach is use of a robust queueing backend that returns jobs to the queue when clients disconnect or time out. Either way, a twelve-factor app is architected to handle unexpected, non-graceful terminations. 
	
10. Dev/prod parity:Keep development, staging, and production as similar as possible


	  x      | Traditional app           | Twelve-factor app     |
	--------------------|------------------|-----------------------|
	Time between deploys | Weeks   | Hours   |
	Code authors vs code deployers  | Different people | Same people  |
	Dev vs production environments  | Divergent | As similar as possible  |

	The twelve-factor developer resists the urge to use different backing services between development and production, even when adapters theoretically abstract away any differences in backing services.
	
11. Logs:Treat logs as event streams
		
	A twelve-factor app never concerns itself with routing or storage of its output stream(maybe dont fit for java app).
	
12. Admin processes:Run admin/management tasks as one-off processes
	
	One-off admin processes should be run in an identical environment as the regular long-running processes of the app. They run against a release, using the same codebase and config as any process run against that release. Admin code must ship with application code to avoid synchronization issues.
	
