---
title: 2016年08月Reading Notes
date: 2018-05-02 14:24:17
categories: java
tags:
  - READING NOTES
  - 前后端分离
---
	
## 前后端分离

https://blog.codecentric.de/en/2018/04/spring-boot-vuejs/

前后端分离实施比较简单，但是会引入额外的开发、部署成本，这篇文章思路值得借鉴。

### 1. 前后端物理分离

前端项目和后端项目由不同的团队开发，并且要维持前端和后端代码的一致(单一仓库原则)。通过maven多模块工程划分前端子模块、后端子模块。

### 2. 构建方案

#### 2.1 前端环境

首先保证前端构建环境一致，使用`frontend-maven-plugin`插件安装基础环境并在打包时执行前端构建命令。

#### 2.2 all in one jar


部署时可以引入nginx来serve静态页面，动态请求反向代理到后端服务器。但是对于小型项目来说，这样的部署成本太大了，每次上线成本也比较大。理想的方式是用后端应用服务器提供静态页面输出能力，前端后端`all in one jar`.

使用`maven-resources-plugin`插件把前端模块的打包输出物拷贝到后端项目中,最终打一个jar包。

#### 2.3 打包

通过以上的工作，使用`mvn clean install`即可以把项目打成一个jar包。

### 3. 前端开发

前后端开发过程中，前端访问后端服务面临js同源策略问题。可以使用`CORS`方案解决，文中给出了一个很好的解决方案，使用`http-proxy-middleware`，把某些路径的请求转发到后端服务器，优雅的避免了同源问题。

前端开发过程中，需要mock掉后端服务器，可以使用`http://rapapi.org`,后端服务开发人员提供接口契约，前端开发前期使用mock数据。


### 4. 工程实践

#### 4.1 项目结构

我们的工程结构大致如下：

	xxx-assemble (项目打包)
	xxx-core (核心代码)
	xxx-frontend (前端代码)

#### 4.2 配置

##### 4.2.1. 前端模块

	    <build>
	        <plugins>
	            <plugin>
	                <groupId>com.github.eirslett</groupId>
	                <artifactId>frontend-maven-plugin</artifactId>
	                <version>1.6</version>
	                <executions>
	                    <!-- Install our node and npm version to run npm/node scripts-->
	                    <execution>
	                        <id>install node and npm</id>
	                        <goals>
	                            <goal>install-node-and-npm</goal>
	                        </goals>
	                        <configuration>
	                            <nodeVersion>v9.11.1</nodeVersion>
	                        </configuration>
	                    </execution>
	                    <!-- Install all project dependencies -->
	                    <execution>
	                        <id>npm install</id>
	                        <goals>
	                            <goal>npm</goal>
	                        </goals>
	                        <!-- optional: default phase is "generate-resources" -->
	                        <phase>generate-resources</phase>
	                        <!-- Optional configuration which provides for running any npm command -->
	                        <configuration>
	                            <arguments>install</arguments>
	                        </configuration>
	                    </execution>
	                    <!-- Build and minify static files -->
	                    <execution>
	                        <id>npm run build</id>
	                        <goals>
	                            <goal>npm</goal>
	                        </goals>
	                        <configuration>
	                            <arguments>run build</arguments>
	                        </configuration>
	                    </execution>
	                </executions>
	            </plugin>
	        </plugins>
	    </build>

##### 4.2.2. 打包模块

		<plugin>
                <artifactId>maven-resources-plugin</artifactId>
                <executions>
                    <execution>
                        <id>copy frontend content</id>
                        <phase>generate-resources</phase>
                        <goals>
                            <goal>copy-resources</goal>
                        </goals>
                        <configuration>
                        <!-- copy all build frontend resouces to assemble module  -->
                            <outputDirectory>src/main/resources/public</outputDirectory>
                            <overwrite>true</overwrite>
                            <resources>
                                <resource>
                                
                                    <directory>${project.parent.basedir}/xxx-frontend/dist</directory>
                                    <filtering>false</filtering>
                                    <includes>
                                        <include>**</include>
                                    </includes>
                                </resource>
                            </resources>
                        </configuration>
                    </execution>
                </executions>
            </plugin>


##### 4.2.3 git ignore

在git ignore文件中添加

	node_modules
	xxx-frontend/node
	xxx-frontend/dist
	xxx-assemble/src/main/resources/public
	
#### 4.3 相关命令

	#安装node/npm依赖
	mvn -T 1C clean install -Dmaven.test.skip=true
	#打包
	mvn -T 1C clean package -Dmaven.test.skip=true
	#线上运行
	java -jar xxx-assemble/target/xxx.jar
	#在打包模块通过maven运行
	mvn spring-boot:run
	#构建前端代码
	npm run build
	
