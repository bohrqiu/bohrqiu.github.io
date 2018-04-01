---
title: 2015年05月Reading Notes
date: 2015-05-01 21:52:17
categories: java
tags:
  - READING NOTES
  - springloaded
---

	
## <a name="springloaded">使用spring loaded提高开发效率</a>
[spring-loaded](https://github.com/spring-projects/spring-loaded)和[jrebel](http://zeroturnaround.com/software/jrebel/)类似，它能发现您修改的类并重新加载。在开发测试时，您只需要使用它启动后，就可以一直写代码了。jrebel是收费的软件，spring-loaded免费，而且他很了解您代码中用到的spring特性，能很智能的帮忙重新加载类，并把bean注册到spring容器中。

使用很简单，参考下面的步骤：

1. 下载[springloaded](http://repo.spring.io/simple/libs-release-local/org/springframework/springloaded/1.2.3.RELEASE/springloaded-1.2.3.RELEASE.jar)
2. 配置IDEA
	
	* 打开`Run/Debug Configuations`,在`Defaults`中选择`Application`
	* 在右边的`Configuration` tab中配置`VM options`

			-javaagent:/Users/bohr/software/springloaded/springloaded-1.2.3.RELEASE.jar -noverify
	
	有了此默认配置，一劳永逸。上面的路径地址修改为您保存springloaded的路径
3. 执行任何java类
4. 修改后，编译此java类就能看到修改后的效果了。