---
title: 如何跟踪数据库结构变动
date: 2014-08-15 21:52:17
categories: java
tags:
  - 数据库版本
---


昨天和澎湃聊了这个事情,当时的想法是数据库中有表记录版本,项目代码中存储变更脚本.无意中看到数据库版本控制工具[liquibase](http://www.liquibase.org/index.html).最开始还是有点担心,怕这东西把数据库玩坏了.看了看官方文档,再粗略看了下主流程的源代码,发掘下我想要的功能,这个工具已经足够强大了,我们用好就行.

下面以cs为例,讲讲整个过程.

### 1. 在cs-dal中添加maven依赖.

	    <build>
            <plugin>
                <groupId>org.liquibase</groupId>
                <artifactId>liquibase-maven-plugin</artifactId>
                <version>3.2.2</version>
                <configuration>
                    <!--数据库变更主文件-->
                    <changeLogFile>src/main/resources/db/changelog/db.master.xml</changeLogFile>
                    <!--数据库相关配置文件-->
                    <propertyFile>src/main/resources/db/config/dal-${spring.profiles.active}.properties</propertyFile>
                </configuration>
                <executions>
                    <execution>
                        <phase>process-resources</phase>
                        <goals>
                            <goal>update</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>
        </plugins>
    </build>
    
    
### 2. 编写数据库变更脚本

#### 2.1 数据库变更主文件

`db.master.xml`:

	<?xml version="1.0" encoding="UTF-8"?>
	<databaseChangeLog
        xmlns="http://www.liquibase.org/xml/ns/dbchangelog"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog
         http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-3.2.xsd">
    	<!--数据库变更文件.注意:保证顺序,脚本执行顺序和include的先后有关系.includeAll可以加载所有脚本,加载顺序和文件命名有关系,容易犯错误,建议不使用.-->
    	<include relativeToChangelogFile="true" file="db.1.0.sql"/>
   		<include relativeToChangelogFile="true" file="db.2.0.sql"/>
	</databaseChangeLog>
	
#### 2.2 变更脚本

`db.1.0.sql`:

	--liquibase formatted sql

	--changeset qiubo:1
	create table test1 (
    	id int primary key,
    	name varchar(255)
	);
	--rollback drop table test1;

`db.2.0.sql`:

	--liquibase formatted sql

	--changeset qiubo:2
	insert into test1 (id, name) values (1, 'name 1');
	insert into test1 (id, name) values (2, 'name 2');
	

语法参考:http://www.liquibase.org/documentation/sql_format.html


#### 2.3 数据库配置文件

dal-local.properties

	driver=com.mysql.jdbc.Driver
	url=jdbc:mysql://127.0.0.1:3306/yjf_cs?useUnicode=true&characterEncoding=UTF8&zeroDateTimeBehavior=convertToNull
	username=root
	password=root
	#数据库schema名
	changelogSchemaName=yjf_cs

建议大家把原来的数据库配置文件中的key改为和这个一致,没必要搞多份配置.
	
### 3.路径结构

确保xxx-dal如下的路径结构,请大家统一:


	|---pom.xml
	|---src
	|    |---main
	|    |    |---java
	|    |    |---resources
	|    |    |        |---db
	|    |    |        |    |---changelog
	|    |    |        |    |        |---db.1.0.sql
	|    |    |        |    |        |---db.2.0.sql
	|    |    |        |    |        |---db.master.xml
	|    |    |        |    |---config
	|    |    |        |    |     |---dal-dev.properties
	|    |    |        |    |     |---dal-local.properties
	|    |    |        |    |     |---dal-net.properties
	|    |    |        |    |     |---dal-online.properties
	|    |    |        |    |     |---dal-pnet.properties
	|    |    |        |    |     |---dal-sdev.properties
	|    |    |        |    |     |---dal-snet.properties
	|    |    |        |    |     |---dal-stest.properties
	|    |    |        |    |     |---dal-test.properties


### 4.执行
	
在cs-dal目录执行:

	mvn liquibase:update -Dspring.profiles.active=local
	
上面的脚本会以local环境执行,读取`dal-local.properties`中的数据库配置,执行数据库变更脚本.执行成功后,会在数据库中新建两个表.`DATABASECHANGELOG`会记录数据库变更信息,`DATABASECHANGELOGLOCK`用于防止多台服务器同时部署时的并发问题.

### 5.注意事项
1. 先不要搞线上.
2. 变更脚本命名:我现在做得简单`db.1.0.sql`,最好版本号为项目版本号,便于跟踪.
3. 新项目建议采用此方案,跟踪数据库所有的开发变动.
4. 老项目可以采用全量的方式使用.全量,先根据数据库的基础数据生成变更脚本[generating_changelogs](http://www.liquibase.org/documentation/generating_changelogs.html),然后同步版本(changeLogSync)到数据库中.这样做的好处是,以后可以从无到有的创建当前版本的数据库了.参考[Adding Liquibase on an Existing project](http://www.liquibase.org/documentation/existing_project.html)
5. 老项目也可以采用增量的方式使用,增量的方式不会管以前的数据版本.如果采用这种方式,在新环境搭建数据库,你需要先用数据库工具还原到没有版本之前的状态,然后再执行变更脚本.参考[Adding Liquibase on an Existing project](http://www.liquibase.org/documentation/existing_project.html)
6. 请不要修改(脚本内容/脚本路径)之前的数据库变更脚本,liquibase会对每个Changesets生成摘要,执行时会去对比,如果你修改了以前的Changesets,会报错(所有的变更在事务中执行,出错了会回滚,不用担心会影响到数据库).
7. 官方文档很全,想深入的同学请阅读[FAQ](http://www.liquibase.org/faq.html)/[BEST PRACTICES](http://www.liquibase.org/bestpractices.html)/[Maven Liquibase Plugin](http://www.liquibase.org/documentation/maven/index.html).遇到问题之前先检查配置是否正确,有bug可以找我^_^.