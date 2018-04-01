---
title: 日志优化
date: 2013-07-09 21:52:17
categories: java
tags:
  - 日志优化
---

一些日志优化相关的东东.

## 1. 关掉没用的appender

现在我们所有的系统都会把日志输出到指定的文件，为了本地开发测试方便，我们也会把日志输出到控制台。在生产环境输出到控制台是完全没有必要的，既浪费了存储空间，又浪费了性能，请在生产环境去掉ConsoleAppender

- logback去掉`ch.qos.logback.core.ConsoleAppender`
- log4j去掉`org.apache.log4j.ConsoleAppender`

使用logback的同学也可以如下操作：

1.添加依赖

	<dependency>
			<groupId>org.codehaus.janino</groupId>
			<artifactId>janino</artifactId>
			<version>2.5.16</version>
	</dependency>
2.修改logback.xml中原ConsoleAppender配置如下：

	<if condition='property("os.name").toUpperCase().contains("WINDOWS")'>
		<then>
			<appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">
				<encoder>
					<pattern>%d{yyyy-MM-dd HH:mm:ss} [%thread] %-5level %logger{36}:%L-%msg%n%n</pattern>
				</encoder>
			</appender>
			<root>
				<appender-ref ref="STDOUT" />
			</root>
		</then>
	</if>

上面的配置表示在windows中运行时日志输出到控制台，在其他系统中日志不输出到控制台

## 2. 禁用日志收集栈信息

在写日志时，打印行号能方便我们快速定位出问题的代码。此功能通过生成栈信息，然后定位到合适的栈帧来实现。禁用此功能会提高日志性能。

异步日志实现默认关闭了收集栈信息，见`ch.qos.logback.classic.AsyncAppender#includeCallerData`

对于同步日志，只需要把`pattern`中的`%L`去掉就可以禁用栈信息。


## 3. 使用异步日志

### 3.1 logback

logback只需要用异步appender包裹原来的appender就可以了

	<appender name="ASYNC_ROLLING-cs" class="com.yjf.common.log.LogbackAsyncAppender">
		<appender-ref ref="ROLLING-cs" />
	</appender>

目前我们使用了用于输出日志到文件的`ch.qos.logback.core.rolling.RollingFileAppender`和输出日志到rabbitmq的`com.yjf.monitor.client.integration.log.appender.jms.LogbackMsgRollingAppenderAdapter`，请都用上面的`LogbackAsyncAppender`包裹住。

此配置下，对象先放入一个队列，然后由另外一个线程来处理具体的日志输出，实现异步化，实现流程如下：

- queue大小为1024，如果queue剩余空间小于100时,会做丢弃判断
- 如果queue剩余空间小于100时，会丢弃TRACE、DEBUG日志，也会丢弃LoggerName不以com.yjf开始的INFO日志
- 如果queue没有剩余空间为0时，会阻塞业务线程，直到queue有剩余空间
- 输出日志到文件的appender，由于会用锁来控制多线程的写入，这种用单线程来写文件的方式很完美。
- 输出日志到rabbitmq的appender，`LogbackMsgRollingAppenderAdapter`在并发下会有性能问题，因为`LogbackMsgRollingAppenderAdapter`内部只用到一个channel，如果遇到高并发场景，请给`CachingConnectionFactory`设置合理的channelCacheSize值

### 3.2 log4j

- 写日志到文件的appender，用`org.apache.log4j.AsyncAppender`代替`org.apache.log4j.DailyRollingFileAppender`
- 写日志到rabbitmq的appender，建议用`com.yjf.common.log.Log4jAsynAmqpAppender`，内部也用queue来实现异步化

## 4. logger api增强

下面是常用的使用方式：

	logger.info("金额无效,手续费大于或者等于提现总金额.charge:{},amount:{}", new Object[] { 1, 2, 3 });
	logger.info("金额无效,手续费大于或者等于提现总金额.charge:{},amount:{},test:{}", 1, 2, 3); 
	LoggerFormat.info(String.format("金额无效,手续费大于或者等于提现总金额.charge:%s,amount:%s,test:%s", 1, 2,3), logger);

第一种是slf4j提供的原生api，第二种是yjf-common-utils提供的支持可变的参数的logger，第三种是yjf-common-util提供的日志工具类。这三种使用方式在日志级别为error的情况下，跑一百万次测试出的性能数据如下：

	LoggerFactoryTest.testLogOri: [measured 1000000 out of 1020000 rounds, threads: 4 (all cores)]
	 round: 0.00 [+- 0.00], round.gc: 0.00 [+- 0.00], GC.calls: 2, GC.time: 0.62, time.total: 2.67, time.warmup: 0.04, time.bench: 2.63

	LoggerFactoryTest.testYjfLogger: [measured 1000000 out of 1020000 rounds, threads: 4 (all cores)]
	 round: 0.00 [+- 0.00], round.gc: 0.00 [+- 0.00], GC.calls: 1, GC.time: 0.72, time.total: 3.43, time.warmup: 0.06, time.bench: 3.37

	LoggerFactoryTest.testLogUtils: [measured 1000000 out of 1020000 rounds, threads: 4 (all cores)]
	 round: 0.00 [+- 0.00], round.gc: 0.00 [+- 0.00], GC.calls: 14, GC.time: 1.78, time.total: 11.62, time.warmup: 0.22, time.bench: 11.40

从这些数据可以看出，第三种使用方式由于在方法调用时就有字符串拼接的开销，在error级别下，性能肯定不是很好。

在日志级别为info情况下，这种差距不是很大，但是如果我们使用异步日志，字符串的拼接在独立的线程中完成，不会在调用线程中完成，业务整体执行时间会减少。

第三种方式还有一个问题，行号永远显示的是LoggerFormat.info方法的行号，不便于我们定位问题。“懒”的同学就用第二种方式吧，支持变长参数，例子如下：

	import com.yjf.common.log.Logger;
	import com.yjf.common.log.LoggerFactory;
	...		
	Logger logger = LoggerFactory.getLogger(LoggerFactoryTest.class
		.getName());
	...
	logger.info("xx:{} xx:{} xx:{}","a","b","c");
	logger.info("xx:{} xx:{} xx:[]", "a","b","c", new RuntimeException("挂了"));

请不要再使用`com.yjf.common.log.LoggerFormat`和`com.yjf.common.lang.util.PrintLogTool`

## 5. tomcat日志优化

tomcat embed默认日志使用的是`org.apache.juli.logging.DirectJDKLog`，此日志使用了`java.util.logging.Logger`，此logger使用了jre下面的配置文件`$JAVA_HOME\jre\lib\logging.properties`，此配置文件配置了一个处理器`java.util.logging.ConsoleHandler`，它只做了一个事情，使用`System.err`来作为默认的日志输出，也就是说tomcat embed遇到不能处理的异常后，用System.err来打印日志。(见：`org.apache.catalina.core.StandardWrapperValve#invoke`方法)

我们使用的的tomcat和tomcat embed有点差别，tomcat 中使用了`org.apache.juli.FileHandler`，此输出位置为`$CATALINA_HOME/logs/localhost.yyyy-MM-dd.log`，也就是说tomcat在遇到他搞不定的异常时，把日志输出到了此位置。
tomcat把输出和错误输出都打印到catalina.out文件了，见catalina.sh

	org.apache.catalina.startup.Bootstrap "$@" start \
      >> "$CATALINA_OUT" 2>&1 "&"

这也解释了上次易交易产品遇到的那个问题，spring mvc action递归调用自己，catalina.out文件中没有异常日志。但是我在本地使用tomcat embed测试，会在控制台输出`StackOverflowError`。

tomcat日志优化点：

- 用`org.apache.juli.AsyncFileHandler`代替`org.apache.juli.FileHandler`
- 现在我们应用的日志目录都改为`/var/log/webapps/{project_name}/`。为了便于管理，tomcat 所有日志文件也会输出到`/var/log/webapps/{project_name}/`路径

以上优化已提交到定制化tomcat模板。

## 6.优化J.U.C

J.U.L代表java内置的日志机制，上面部分提到tomcat在遇到他搞不定的异常时，会把日志输出到`localhost.yyyy-MM-dd.log`。这样很不爽，很多同学在检查应用异常时，下意识的不会去看此日志文件，为了避免此问题，请使用下面的解决方案：

1. 使用`com.yjf.common.log.LogbackConfigListener`,使用方法见doc

	请使用yjf-common-util版本大于等于1.6.9.20130708的包

2. logback增加配置

		<contextListener class="ch.qos.logback.classic.jul.LevelChangePropagator">
    		<resetJUL>true</resetJUL>
  		</contextListener>

从此以后，所有的异常日志都会在应用日志文件中找到。

## 7. 性能测试

测试四种情况，普通日志输出，普通日志禁用线程栈信息，异步日志，异步日志禁用线程栈信息，测试结果如下：

	
	LoggerPerfTest.testCommonLogger: [measured 100000 out of 101000 rounds, threads: 16 (physical processors: 4)]
 	round: 0.00 [+- 0.00], round.block: 0.00 [+- 0.00], round.gc: 0.00 [+- 0.00], GC.calls: 2, GC.time: 0.12, time.total: 10.73, time.warmup: 0.11, time.bench: 10.62
 	
	LoggerPerfTest.testCommonLoggerWithoutStackInfo: [measured 100000 out of 101000 rounds, threads: 16 (physical processors: 4)]
 	round: 0.00 [+- 0.00], round.block: 0.00 [+- 0.00], round.gc: 0.00 [+- 0.00], GC.calls: 2, GC.time: 0.04, time.total: 3.93, time.warmup: 0.14, time.bench: 3.79
 	
	LoggerPerfTest.testAsyncLogger: [measured 100000 out of 101000 rounds, threads: 16 (physical processors: 4)]
 	round: 0.00 [+- 0.00], round.block: 0.00 [+- 0.00], round.gc: 0.00 [+- 0.00], GC.calls: 3, GC.time: 0.15, time.total: 2.77, time.warmup: 0.06, time.bench: 2.71
 	
	LoggerPerfTest.testAsyncLoggerWithoutStackInfo: [measured 100000 out of 101000 rounds, threads: 16 (physical processors: 4)]
 	round: 0.00 [+- 0.00], round.block: 0.00 [+- 0.00], round.gc: 0.00 [+- 0.00], GC.calls: 0, GC.time: 0.00, time.total: 1.86, time.warmup: 0.00, time.bench: 1.85
 	
可见异步日志性能会提升不少，不收集栈信息性能也会提升不少。