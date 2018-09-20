---
title: 开发规范(二):maven
date: 2018-05-20 21:52:17
categories: java
tags:
  - spec
---

>> 几年前写的东西，已经离职，留作纪念

# maven使用规范

>版本 |	时间	  |作者	|修订章节	|修订内容
>----|----------|-----|-------|--------
>1.0 |2015-05-11|秋波|全部|init
>1.1 |2015-07-16|秋波|全部|增加依赖规范
>1.2 |2015-07-13|秋波|全部|增加版本号命名规范，增加发布规范
>1.3 |2015-08-05|秋波|全部|增加maven相关命令

## 目录

1. [依赖管理](#dm)
1. [模块依赖关系](#dr)
1. [发布规范](#ds)
1. [版本规范](#vs)
1. [maven相关命令](#cmd)

***

此规范用于规范maven依赖管理、maven模块依赖关系、模块版本升级原则、发布规则。

##  <a name="dm">1. 依赖管理</a>

* 业务系统父pom必须继承于`yiji-parent`
* 业务系统不能在`pom`中定义依赖版本，所有版本由`yiji-parent`提供
* 禁止使用`yiji-parent`中没有定义的第三方组件，如需要使用第三方组件，需由基础技术部评估

## <a name="dr">2. 模块依赖关系</a>

这里以cs项目为例，模块依赖规范如下

### 2.1 父pom:

项目的版本由父pom定义

	<parent>
    	<groupId>com.yiji</groupId>
    	<artifactId>yiji-parent</artifactId>
    	<version>1.0-SNAPSHOT</version>
	</parent>
	<groupId>com.yjf.cs</groupId>
	<artifactId>cs-parent</artifactId>
	<version>2.0.20140306</version>

禁止在父pom的dependencyManagement中定义子module的版本.

### 2.2 facade模块：

子模块`groupId`和`version`继承自父pom

	<parent>
   		<artifactId>cs-parent</artifactId>
    	<groupId>com.yjf.cs</groupId>
    	<version>2.0.20140306</version>
	</parent>
	<artifactId>cs-facade</artifactId>

 当前模块pom定义中不准定义groupId和version.

### 2.3 web模块:

版本依赖通过`${project.parent.version}`定义

	<parent>
    	<artifactId>cs-parent</artifactId>
    	<groupId>com.yjf.cs</groupId>
    	<version>2.0.20140306</version>
	</parent>
	<artifactId>cs-web</artifactId>
 	<dependencies>
    	<dependency>
       	<groupId>com.yjf.cs</groupId>
       	<artifactId>cs-biz</artifactId>
       	<version>${project.parent.version}</version>
    	</dependency>
 	</dependencies>

web模块需要依赖biz模块，通过`${project.parent.version}`来定义依赖版本.

## <a name="ds">3. 发布规范</a>

### 3.1 发布流程

#### 3.1.1 nexus环境介绍

我们有两个nexus，一个用于开发测试(在`yiji-parent`中`profile=dev`中定义)，一个用于联调和线上打包(在`yiji-parent`中`profile=online`中定义)

#### 3.1.2 发布流程规范

开发测试阶段，我们把项目输出物发布到测试nexus(`profile=dev`)，本地开发测试通过后，发布到线上nexus(`profile=online`)

在上线时，必须保持线上nexus和测试nexus中的版本一致，禁止出现下面的情况：
* 测试nexus中有，线上nexus没有
* 测试nexus中没有，线上nexus有
* 测试、线上nexus中都有，版本也一致，但是代码不一致

### 3.2 发布操作规范

#### 3.2.1 在不需要部署的模块中覆盖配置

比如`assemble`模块不需要发布，需要在assemble的pom中覆盖配置,**禁止把非项目输出物发布到nexus**，比如`biz`,`dal`,`web`,`assemble`


	<properties>
        <deploy.skip>true</deploy.skip>
    </properties>


#### 3.2.2 发布到nexus仓库


发布时，在父pom所在的目录，执行命令发布。执行此命令会把父pom和`deploy.skip=false`的项目提交到nexus仓库。按照我们的项目结构，大多数项目只能把`facade`module发到nexus仓库。
#### 3.2.3 发布到测试nexus

	mvn -T 1C clean deploy -P dev  -Dmaven.test.skip=true

#### 3.2.4 发布到线上nexus

	mvn -T 1C clean deploy -P online  -Dmaven.test.skip=true


使用windows的同学，可以写几个bat，放到PATH中加载这几个bat.

## <a name="vs">4. 版本规范</a>

### 4.1 版本命名

业务系统必须按照下面的方式命名版本号：

	主版本.子版本.日期

说明如下：

* 主版本号：

	当功能模块有较大的变动，比如增加模块或是整体架构发生变化。此版本号由项目负责人决定是否修改。
* 次版本号：

	相对于主版本号而言，次版本号的升级对应的只是局部的变动，但该局部的变动造成程序和以前版本不能兼容，或者对该程序以前的协作关系产生了破坏，或者是功能上有大的改进或增强。此版本号由项目负责人决定是否修改。
* 日期版本号：

	用于记录修改项目的当前日期，每此对项目的修改都需要更改日期版本号。此版本号由开发人员决定是否修改。

### 4.2 版本修改原则

版本修改的原则是：

1. 所有模块的版本必须保持一致
2. 服务输出项目:服务输出模块的功能改变时，升级模块版本
3. 组件项目:组件功能改变时，升级版本。

我们大多数项目都是服务输出项目，我们对其他客户提供服务，当我们对外提供的服务功能变动时,需要升级服务输出模块的版本(我们的项目结构中，此模块基本上都命名为`facade`)。

组件项目，当功能发生变化，影响到使用方时，需要升级版本。如果是bug修复，可以在nexus上把老版本删除，强制让使用方升级。

无论的模块版本如何变动，都要保证所有的模块版本一致，可以使用下面的命令来统一修改版本。

	mvn versions:set -DgenerateBackupPoms=false

### <a name="cmd">5. maven相关命令</a>

		#安装到本地
		alias mvni='mvn -T 1C clean install -Dmaven.test.skip=true'
		#打包
		alias mvnp='mvn -T 1C clean package -Dmaven.test.skip=true'
		#修改版本
		alias mvnv='mvn versions:set -DgenerateBackupPoms=false'
		#发布到测试nexus
		alias mvndd='mvn -T 1C clean deploy -P dev  -Dmaven.test.skip=true'
		#发布到生产nexus
		alias mvndo='mvn -T 1C clean deploy -P online -Dmaven.test.skip=true'
		#清理工程
		alias mvnc='mvn -T 1C clean eclipse:clean idea:clean'
		#检查依赖升级情况
		alias mvncv='mvn -T 4C  versions:display-dependency-updates'
		#生成文档站点
		alias mvns='mvn clean site -Dmaven.test.skip=true'
		#生成eclipse工程结构
		alias mvne='mvn eclipse:eclipse install'
