---
title: 2018年06月Reading Notes
date: 2018-06-01 21:52:17
categories: java
tags:
  - READING NOTES
  - InjectionPoint
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