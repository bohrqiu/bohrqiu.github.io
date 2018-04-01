---
title: 2015年01月Reading Notes
date: 2015-01-11 21:52:17
categories: java
tags:
  - READING NOTES
---


## 构建类型安全的SQL查询
[Advanced Spring Data JPA - Specifications and Querydsl](http://spring.io/blog/2011/04/26/advanced-spring-data-jpa-specifications-and-querydsl/)

[Querying JPA document](http://www.querydsl.com/static/querydsl/latest/reference/html/ch02.html#jpa_integration)

[querydsl jpa example](https://github.com/querydsl/querydsl-jpa-example)

[`querysql`](http://www.querydsl.com/)很早之前了解过,当时没有看到他的价值，最近在写某业务系统的分页查询过程中，看到基于`Specifications`写的复杂查询语句，有点乱，感觉有点点不爽。

jpa 提供了`Metamodel`,但是`Specifications`难用，生成的语法糖也难用。

下面列出几种在spring-data-jpa中使用查询的例子：

### 1.使用querydsl：

	 public List<SchedulerRule> findByOther(String other) {
		BooleanBuilder builder = new BooleanBuilder();
		builder.or(schedulerRule.memo.containsIgnoreCase(other));
		builder.or(schedulerRule.properties.containsIgnoreCase(other));
		builder.or(schedulerRule.dGroup.containsIgnoreCase(other));
		return new JPAQuery(em).from(schedulerRule).where(builder).orderBy(schedulerRule.id.asc()).list(schedulerRule);
	  }

### 2.使用原生sql：

    public List<SchedulerRule> findByOther(String other) {
        return (List<SchedulerRule>) em
            .createNativeQuery(
                "select * from  scheduler_rule where  memo LIKE :other OR properties LIKE :other OR dGroup LIKE :other order by id",
                SchedulerRule.class).setParameter("other", "%" + other + "%").getResultList();
    }
    
### 3.使用`@Query`:

	@Query("from SchedulerRule as rule where mod(rule.id, :clusterSize)= :mod and rule.status = 'NORMAL'")
	List<SchedulerRule> findByClient(@Param("clusterSize") int clusterSize, @Param("mod") int mod);
	
	
### 4.使用接口命名生成查询语句：

	Page<SchedulerRule> findByCreater(String creator, Pageable pageable);

在使用querydsl时，通过配置annotation processor可以很方便的完成代码生成工作：

	 <!--querydsl-->
            <plugin>
                <groupId>com.mysema.maven</groupId>
                <artifactId>apt-maven-plugin</artifactId>
                <version>1.1.0</version>
                <configuration>
                    <processor>com.mysema.query.apt.jpa.JPAAnnotationProcessor</processor>
                </configuration>
                <dependencies>
                    <dependency>
                        <groupId>com.mysema.querydsl</groupId>
                        <artifactId>querydsl-apt</artifactId>
                        <version>3.6.0</version>
                    </dependency>
                </dependencies>
                <executions>
                    <execution>
                        <phase>generate-sources</phase>
                        <goals>
                            <goal>process</goal>
                        </goals>
                        <configuration>
                            <outputDirectory>src/gen/java</outputDirectory>
                        </configuration>
                    </execution>
                </executions>
            </plugin>
            
            
## ActiveJPA——针对JPA的活动记录模式
[http://www.infoq.com/cn/articles/ActiveJPA](http://www.infoq.com/cn/articles/ActiveJPA)

活动记录模式在使用上来说，还是很happy的。但是造成的问题是：1.`entity`和`DO`耦合在一起了，如果业务复杂，还是老老实实的`DDD`吧。2.复杂的查询可能还是需要借助`DAO`。如果自己来实现，考虑上关系映射，最后就是活脱脱的一个hibernat出来了。这个框架借助`JPA`的能力，简单的实现了活动记录模式。

作者通过`java instrument api`+`javassit`来生成便于使用的静态方法(不需要提供类型信息)。


## 用betamax mock掉外部http/https依赖
[http://freeside.co/betamax/](http://freeside.co/betamax/)

`betamax`在你的应用和外部应用之间架起了proxy.他会录制第一次请求，在本地文件系统中生成`Tape`，后续的请求就不会调用目标服务了。我们可以把`tape`存放在`VCS`中，也可以编辑此文件，满足特殊需求。

## Building a Robust and Secure Web Application With Velocity
[http://wiki.apache.org/velocity/BuildingSecureWebApplications](http://wiki.apache.org/velocity/BuildingSecureWebApplications)

这篇文章很老了，但是很值得参考下。

### Best Practices In Building A Secure, Robust Velocity Web Application



1. Review all context references for unwanted methods.

	不要在Context中放入能改变程序状态的引用。

2. Encode HTML special characters to avoid cross-scripting vulnerabilities.

	可以通过`EscapeHtmlReference`对符合特定模式的引用进行过滤。

3. Use an up-to-date and properly configured app server.

	里面提到通过`Java Security Manager `来限制应用的行为。这也是一种不错的方式，只是灵活性不好。可以采用findbugs来检查静态代码，再控制好上传的文件/对系统的直接调用就ok了。
	

4. Configure Velocity for production use.

	创建`EventCartridge`和`Event Handlers`来捕获异常，并记录进日志。这个工作在`com.yjf.common.util.Velocitys`里面是做了的。但是spring mvc集成 velocity可以做下。提前发现异常(上次CRSF过滤器配置出错导致的页面乱了)。
	
## jello--Front End Integrated Solution for J2EE Velocity
[https://github.com/fex-team/jello](https://github.com/fex-team/jello)

[http://106.186.23.103:8080/](http://106.186.23.103:8080/)

使用velocity的同学可以关注下：jello针对服务端为 JAVA + Velocity 的前端集成解决方案。为优化前端开发效率而生，提供前后端开发分离、自动性能优化、模块化开发机制等功能。

[模板技巧](http://106.186.23.103:8080/velocity/index)部分文档适合学习velocity的同学看看。

## 模板引擎的选择

关于thymeleaf的性能：http://forum.thymeleaf.org/Performance-issue-td3722763.html
模式freemarker性能最强，thymeleaf性能差距太大

比较JVM上的模板引擎： http://www.slideshare.net/jreijn/comparing-templateenginesjvm

thymeleaf的优点主要在和前端结合起来很不错，前端切完图，然后加上动态数据的部分就ok了。页面不需要服务端也能渲染出来。