---
title: 2018年06月Reading Notes
date: 2018-06-01 21:52:17
categories: java
tags:
  - READING NOTES
  - InjectionPoint
  - spring jdbc
  - Asynchronous Database Access API
  - 对象存储
---
	
## spring InjectionPoint

[InjectionPoint](https://docs.spring.io/spring/docs/current/javadoc-api/org/springframework/beans/factory/InjectionPoint.html)是spring 4.3引入的特性，顾名思义，注入点，通过此类能获取到注入点上下文。可以通过这个特性做一些有意思的事情。

### 1. 获取被注入组件的类

	@Bean
    @Scope("prototype")
    Logger logger(InjectionPoint ip) {
        return Logger.getLogger(ip.getMember().getDeclaringClass().getName());
    }

    @Component
    public static class LoggingComponent {
        private final Logger logger ;
        public LoggingComponent(Logger logger) {
            this.logger = logger;
        }
    }
    
### 2. 获取被注入组件上的注解

	  @Bean
	  @Scope("prototype")
	  public String greeting(InjectionPoint ip) {
	    Greeting greeting = findAnnotation(ip.getAnnotatedElement(),
	                        Greeting.class);
	    return (Language.DA == greeting.language()) ? "Hej Verden" : "Hello World";
	  }
  
	@Service
	public class GreeterService {
	  @Autowired @Greeting(language = Language.EN)
	  private String greeting;
	}
	

## spring jdbc

spring jdbc做了很多有意思的扩展，比如大家熟悉的`JdbcTemplate`,还有最近才推出的[spring-data-jdbc](https://projects.spring.io/spring-data-jdbc/),参考[spring-tips](https://github.com/spring-tips/jdbc/blob/master/src/main/java/com/example/jdbc/JdbcApplication.java)，了解spring 对jdbc的能力支持。

## Asynchronous Database Access API

[ADBA](https://blogs.oracle.com/java/jdbc-next:-a-new-asynchronous-api-for-connecting-to-a-database)访问数据库的异步api，让io线程的事件机制去等待数据库响应，把这块填补上，java程序中基本上都可以完全异步了。[scalikejdbc-async](https://github.com/scalikejdbc/scalikejdbc-async)的做法实现了jdbc api，但是由于异步编程模型的改变，使用起来会有点别扭。(比如基于请求的结果做后续操作)

目前就oracle数据库驱动实现了ADBA，它通过nio实现了完全的异步。

## Minio

Minio是GlusterFS创始人之一Anand Babu Periasamy发布的兼容Amason S3分布式对象存储项目，可以做为对象存储的解决方案用来保存海量的图片，视频，文档.

分布式minio，有以下特性：

* 数据保护:采用[erasure code](https://github.com/minio/minio/blob/master/docs/zh_CN/erasure/README.md)来防范多个节点宕机和位衰减bit rot
* 高可用:如果是一个N节点的分布式Minio,只要有N/2节点在线，你的数据就是安全的
* 一致性:Minio在分布式和单机模式下，所有读写操作都严格遵守read-after-write一致性模型。


