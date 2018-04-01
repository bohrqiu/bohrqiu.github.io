---
title: maven 传递依赖检查
date: 2014-05-28 21:52:17
categories: java
tags:
  - maven
---

## 传递依赖检查

我们通过maven插件`org.apache.maven.plugins:maven-enforcer-plugin`启用`<requireUpperBoundDeps/>`
来检查传递依赖是否高于直接依赖,如果传递依赖的版本比直接依赖的版本高,则打包失败.

`<requireUpperBoundDeps/>`解释如下:

	IF:

    	A-->B1-->C2

    	A-->C1

    	C2>C1

	THEN:

    	throw Exception;
    	
我觉得这个检查很有必要,但是解析的范围太宽了.一个项目依赖了很多的开源组件,我们最好是限制这个检查只检查我们自己的jar包.

修改插件默认行为,在`org.apache.maven.plugins.enforcer.RequireUpperBoundDeps$RequireUpperBoundDepsVisitor#containsConflicts`中加入:

	String key=  resolvedPair.constructKey();
	if(key!=null && !key.startsWith("com.xxx")){//不检查groupId中包括非com.xxx开头的jar包
  		return false;
	}	
    
## demo

下面说下检查出来的提示信息分析,比如下面的情况:

	Failed while enforcing RequireUpperBoundDeps. The error(s) are [
		Require upper bound dependencies error for xxx.interchange:interchange-facade-settle:1.0.0.20121009 paths to dependency are:
		+-xxx.ppm:ppm-integration:1.0.1.6
 	 		+-xxx.interchange:interchange-facade-settle:1.0.0.20121009
		and
		+-xxx.ppm:ppm-integration:1.0.1.6
 	 		+-xxx.core.payengine:payengine-facade:2.0.0.20140314
   	 			+-xxx.interchange:interchange-facade-settle:1.0.0.20121009 (managed) <-- xxx.interchange:interchange-facade-settle:1.3.0.20140303
   	 			

第一个告诉我们`ppm-integration`-->`interchange-facade-settle:1.0.0.20121009`.

第二个告诉我们`ppm-integration`-->`payengine-facade:2.0.0.20140314`-->`interchange-facade-settle:1.3.0.20140303`

根据maven `最短路径优先原则`,`ppm-integration`最终会依赖`interchange-facade-settle:1.0.0.20121009`.但是`payengine-facade:2.0.0.20140314`它依赖`interchange-facade-settle:1.3.0.20140303`.如果classpath中只有`interchange-facade-settle:1.0.0.20121009`,运行时`payengine-facade`就有可能报找不到类,找不到方法之类的错误.

遇到这样的场景,最好是修改我们项目的直接依赖,让`ppm-integration`-->`interchange-facade-settle:1.3.0.20140303`,然后测试下是否ok.
