---
title: 开发规范-日志
date: 2018-09-20 21:52:17
categories: java
tags:
  - spec
---

>> 几年前写的东西，已经离职，留作纪念

# 易极付日志命名格式标准

>版本 |	时间	  |作者	|修订章节	|修订内容
>----|----------|-----|-------|--------
>1.0 |2013-08-10|培根|全部|init
>1.1 |2015-07-27|秋波|全部|修改摘要日志规范
>1.2 |2015-07-27|秋波|全部|修改格式和完善内容


## 1.日志文件存放地址

 由运维指定,目前统一放到`/var/log/webapps/${appName}`下
 
 `${appName}`为应用名 如:账务(accounttrans)、易生活（elife）

## 2. 格式构成

### 2.1 日志文件名称格式
	
日志全名由小写字母构成,连接线使用"-"

### 2.2  日志级别

日志类别主要有`debug`、`info`、`warn`、`error`

#### 2.2.1 debug

`debug`日志主要是用于调试、运行轨迹跟踪。默认我们的日志级别为`info`，当我们在测试环境想输出更多轨迹信息时，日志日志级别为`debug`,输出此日志。

#### 2.2.2 info
 
`info`日志为打印基本业务完整性日志,比如对外服务入口，出口，关键业务流程等。

#### 2.2.3 warn

`warn`日志为可能存在的潜在问题的提示，以及重要的提示信息。

#### 2.2.4 error

`error`为业务处理出错或**致命**错误。


### 2.3  日志类型

可以把某些类型的操作记录到单独的日志文件中。

#### 2.3.1 查询日志(非必须)

业务性能日志,日志名前缀为 `{appName}-query`

可以把查询相关的请求日志写入到一个文件中，方便日志定位。

#### 2.2.2 摘要日志(必须)

业务摘要日志，记录业务执行轨迹。
        
摘要日志请使用`com.yjf.common.log.DL`工具类输出日志。
   
#### 2.2.3 性能日志(非必须)     

业务性能日志,日志名前缀为 `{appName}-perf`
    
性能日志主要标识了从两个时间点的执行时间来测量某业务的性能情况

业务性能日志建议使用[perf4j](https://github.com/perf4j/perf4j)




### 2.3  日志保存策略

日志保持策略定义在文件名种，由两部分组成 天数+保存形式，信息中心按照文件名来处理日志

* 最长天数为60天
* 保存形式: 

	* 定期清理日志关键字[dt],如:14dt.log
	* 定期备份日志关键字[de],如:14de.log

### 2.4  日志保存策略

日志滚动规则

* 按天滚动

  隔天日志格式在当天日志的最后加上日期.如:elife-xxx.log.2013-08-14
  
* 按大小滚动

  日志文件大小超过1G后，滚动为新的日志.如:elife-xxx.log.2013-08-14.0、elife-xxx.log.2013-08-14.1

### 2.5 日志内容格式

logback配置如下：

	%d{yyyy-MM-dd HH:mm:ss.SSS} %-5level [%thread] %logger{0}:%L- %msg%n

## 3. 最佳实践

### 3.1 善用`MDC`

`MDC`用于记录请求执行轨迹，我们可以把某请求参数(比如`gid`)记录到日志中。当我们在分析日志时，搜索此请求参数，就能看到此请求完整的执行轨迹。

参考: 

以`openapi-arch`中的代码为例，我们在`logback.xml`中[配置MDC](http://gitlab.yiji/qzhanbo/openapi-arch/blob/master/openapi-arch-test/src/test/resources/logback.xml#L7),当用户请求到达时，会生成唯一的`gid`.[此时把gid存入MDC中](http://gitlab.yiji/qzhanbo/openapi-arch/blob/master/openapi-arch-core/src/main/java/com/yiji/openapi/arch/executer/HttpApiServiceExecuter.java#L107)，后续一系列的处理日志输出中都会有此`gid`,当请求处理完毕后，[清理MDC](http://gitlab.yiji/qzhanbo/openapi-arch/blob/master/openapi-arch-core/src/main/java/com/yiji/openapi/arch/executer/HttpApiServiceExecuter.java#L167)。

		

### 3.2 日志调优

参考 [日志优化](http://bohr.me/log-tuning/)

## 4.配置样例

下面以`cs`系统为例，日志配置如下：

    <?xml version="1.0" encoding="UTF-8" ?>
	<!-- 日志组件启动时，打印调试信息，并监控此文件变化，周期60秒 -->
	<configuration debug="true" scan="true" scanPeriod="60 seconds">

    <!--针对jul的性能优化  -->
    <contextListener class="ch.qos.logback.classic.jul.LevelChangePropagator">
        <resetJUL>true</resetJUL>
    </contextListener>

    <!-- 定义变量 -->
    <property name="appName" value="cs"/>
    <property name="logPath" value="/var/log/webapps/${appName}"/>
    <property name="pattern" value="%d{yyyy-MM-dd HH:mm:ss.SSS} %-5level [%thread] %logger{0}:%L- %msg%n"/>

    <!-- contextName主要是为了区分在一个web容器下部署多个应用启用jmx时，不会出现混乱 -->
    <contextName>${appName}</contextName>

    <!-- ***************************************************************** -->
    <!-- 配置输出到控制台，仅在开发测试时启用输出到控制台 ，下面的语句在window环境下生效，使用mac或者ubuntu的同学，请自己构造下-->
    <!-- ***************************************************************** -->

    <if condition='property("os.name").toUpperCase().contains("WINDOWS")||property("os.name").toUpperCase().contains("MAC")'>
        <then>
            <appender class="ch.qos.logback.core.ConsoleAppender" name="STDOUT">
                <encoder>
                    <pattern>${pattern}</pattern>
                </encoder>
            </appender>
            <root>
                <appender-ref ref="STDOUT"/>
            </root>
        </then>
    </if>

    <!-- ***************************************************************** -->
    <!-- info级别的日志appender,这里把所有日志都输出到一个文件，没有区分不同的业务类型 -->
    <!-- ***************************************************************** -->
    <appender class="ch.qos.logback.core.rolling.RollingFileAppender" name="cs-info">
        <file>${logPath}/cs-info-30dt.log</file>
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <fileNamePattern>${logPath}/cs-info-30dt.log.%d{yyyy-MM-dd}.%i
            </fileNamePattern>
            <timeBasedFileNamingAndTriggeringPolicy class="ch.qos.logback.core.rolling.SizeAndTimeBasedFNATP">
                <maxFileSize>1024MB</maxFileSize>
            </timeBasedFileNamingAndTriggeringPolicy>
        </rollingPolicy>
        <encoder>
            <pattern>${pattern}</pattern>
        </encoder>
    </appender>

    <!-- ***************************************************************** -->
    <!-- error级别日志appender -->
    <!-- ***************************************************************** -->
    <appender class="ch.qos.logback.core.rolling.RollingFileAppender" name="cs-err">
        <file>${logPath}/cs-error-30dt.log</file>
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <fileNamePattern>${logPath}/cs-error-30dt.%d{yyyy-MM-dd}.%i
            </fileNamePattern>
            <timeBasedFileNamingAndTriggeringPolicy class="ch.qos.logback.core.rolling.SizeAndTimeBasedFNATP">
                <maxFileSize>1024MB</maxFileSize>
            </timeBasedFileNamingAndTriggeringPolicy>
        </rollingPolicy>
        <filter class="ch.qos.logback.classic.filter.ThresholdFilter">
            <level>ERROR</level>
        </filter>
        <encoder>
            <pattern>${pattern}</pattern>
        </encoder>
    </appender>

    <!-- ***************************************************************** -->
    <!-- 性能日志appender -->
    <!-- ***************************************************************** -->
    <appender class="ch.qos.logback.core.rolling.RollingFileAppender" name="cs-perf">
        <file>${logPath}/cs-perf-30dt.log</file>
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <fileNamePattern>${logPath}/cs-perf-30dt.log.%d{yyyy-MM-dd}.%i
            </fileNamePattern>
            <timeBasedFileNamingAndTriggeringPolicy class="ch.qos.logback.core.rolling.SizeAndTimeBasedFNATP">
                <maxFileSize>1024MB</maxFileSize>
            </timeBasedFileNamingAndTriggeringPolicy>
        </rollingPolicy>
        <encoder>
            <pattern>${pattern}</pattern>
        </encoder>
    </appender>
    <!-- 异步日志包裹 -->
    <appender class="com.yjf.common.log.LogbackAsyncAppender" name="async-cs-info">
        <appender-ref ref="cs-info"/>
    </appender>
    <appender class="com.yjf.common.log.LogbackAsyncAppender" name="async-cs-err">
        <appender-ref ref="cs-err"/>
    </appender>
    <appender class="com.yjf.common.log.LogbackAsyncAppender" name="async-cs-perf">
        <appender-ref ref="cs-perf"/>
        <!--不收集栈信息-->
        <includeCallerData>false</includeCallerData>
    </appender>

    <!-- 性能日志logger additivity=false代表此日志不继承父logger中的appender，对于此样例，性能日志不会写到处cs-perf-30dt.log外的其他日志文件-->
    <logger name="LOGGER_PERFORMANCE" additivity="false">
        <appender-ref ref="async-cs-perf"/>
    </logger>


    <!-- 根日志logger -->
    <root level="INFO">
        <appender-ref ref="async-cs-info"/>
        <appender-ref ref="async-cs-err"/>
    </root>

	</configuration>
