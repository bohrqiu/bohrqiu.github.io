---
title: 2015年04月Reading Notes
date: 2015-04-01 21:52:17
categories: java
tags:
  - READING NOTES
  - nashorn
  - java reflect
---

## <a name="enterprise_nashorn">Enterprise Nashorn</a>
[https://community.oracle.com/docs/DOC-910779](https://community.oracle.com/docs/DOC-910779)

本文讲述了`Nashorn`的一些使用场景：

1. 由外部提供计算逻辑，服务端执行计算逻辑返回结果
2. 用java来定义接口，js来写逻辑，方便动态更新计算逻辑。(比如短信中的路由策略，需要经常更新)
3. 写shell脚本(访问数据库，访问网络,监控...)

`Nashorn`的性能比前任强多了，但是和java比较还是有差距，主要的性能开销在js->java上。在关注性能的场景，可以在业务使用时，采用方法2，并缓存proxy对象。

	private static String isPrime = " function test(num) {\n" + "if (num % 2 == 0)" + "return false;" + "for (var i = 3; i * i <= num; i += 2)"
										+ "if (num % i == 0)" + "return false;" + "return true;" + "}";
	private Supplier<Predicate<Long>> supplier = Suppliers.memoize(() -> getFilter());

	private Predicate getFilter() {
		Invocable invocable = (Invocable) this.engine;
		try {
			this.engine.eval(isPrime);
			return invocable.getInterface(Predicate.class);
		} catch (Exception ex) {
			throw Throwables.propagate(ex);
		}
	}
	@Test
	public void testJavaScriptWithMemoize() throws Exception {
		supplier.get().test(172673l);
	}

对比了下`nashorn`和`groovy`的性能：

	NashornPerfTest.testJavaScript: [measured 50000 out of 51000 rounds, threads: 4 (all cores)]
 	round: 0.00 [+- 0.00], round.block: 0.00 [+- 0.00], round.gc: 0.00 [+- 0.00], GC.calls: 96, GC.time: 0.25, time.total: 34.20, time.warmup: 3.44, time.bench: 30.76
	NashornPerfTest.testJava: [measured 50000 out of 51000 rounds, threads: 4 (all cores)]
 	round: 0.00 [+- 0.00], round.block: 0.00 [+- 0.00], round.gc: 0.00 [+- 0.00], GC.calls: 0, GC.time: 0.00, time.total: 0.28, time.warmup: 0.01, time.bench: 0.27
	NashornPerfTest.testJavaScriptWithMemoize: [measured 50000 out of 51000 rounds, threads: 4 (all cores)]
 	round: 0.00 [+- 0.00], round.block: 0.00 [+- 0.00], round.gc: 0.00 [+- 0.00], GC.calls: 0, GC.time: 0.00, time.total: 0.35, time.warmup: 0.06, time.bench: 0.29
	GroovyTest.testGroovyWithMemoize: [measured 50000 out of 51000 rounds, threads: 4 (all cores)]
 	round: 0.00 [+- 0.00], round.block: 0.00 [+- 0.00], round.gc: 0.00 [+- 0.00], GC.calls: 5, GC.time: 0.07, time.total: 3.86, time.warmup: 1.75, time.bench: 2.11


## spring 多线程中两个事务执行顺序控制

有些场景需要控制两个事务的执行顺序，比如事务A执行完后，需要事务B中执行费时操作。因为是费时操作，一般会把事务B放到独立的线程中执行。然而事务A和事务B在不同的线程中，事务B还会依赖事务A提交的数据。如果在事务A中新启动线程执行事务B，有可能事务A还没有提交，就开始执行事务B了。这种场景需要保证事务A提交后，才能在新线程中执行事务B。

可以使用`TransactionSynchronizationManager`来解决这个问题：

	TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization(){
           void afterCommit(){
                //submit transaction B to threadpool
           }
	})；

在事务A中加上此钩子，在`afterCommit`方法中向线程池提交事务A任务。具体处理代码`AbstractPlatformTransactionManager#triggerAfterCommit`，`ThreadLocal`清理`AbstractPlatformTransactionManager#cleanupAfterCompletion`.

## Web应用的缓存设计模式
[http://robbinfan.com/blog/38/orm-cache-sumup]()

robbin大哥讲解了对`ORM`缓存的理解.我司也有不少项目用了`ORM`,大多数人没有使用缓存的意识,有这样意识的同学提到过用`ehcache`,这在单节点的情况下，工作得很好，但是到了线上多机部署，数据不一致的问题就会出现，至少也要选用分布式缓存系统来实现哈。还有一点，因为有了缓存，数据订正这种事情就要谨慎了。

## <a name="java_reflect">java反射的性能</a>

先看看下面的数据：

	Benchmark                                  Mode  Cnt     Score    Error  Units
 	testInvokeMethod_Direct                avgt   20     0.587 ±  0.036  ns/op
 	testInvokeMethod_Reflectasm            avgt   20    39.940 ±  1.957  ns/op
 	testInvokeMethod_Reflectasm_withCache  avgt   20     9.784 ±  0.745  ns/op
 	testInvokeMethod_reflect               avgt   20  1513.409 ± 85.396  ns/op
 	testInvokeMethod_reflect_withCache     avgt   20    29.444 ±  1.863  ns/op

上面的数据测试了`直接调用java方法`、`通过反射调用java`、`通过ReflectASM调用java`，`withCache`意思是把中间对象缓存起来。
反射确实很慢，但是只要把反射对象缓存起来，性能提升很大，`Reflectasm_withCache`比`reflect_withCache`快了3倍多。

`Reflectasm`的原理是生成java源代码来实现反射的调用，下面就是生成的源代码。

	package reflectasm;
	import java.util.Map;
	import com.esotericsoftware.reflectasm.MethodAccess;
	public class PojoMethodAccess extends MethodAccess {
		public Object invoke(Object paramObject, int paramInt, Object[] paramArrayOfObject) {
			Pojo localPojo = (Pojo) paramObject;
			switch (paramInt) {
				case 0:
					return Boolean.valueOf(localPojo.equals((Object) paramArrayOfObject[0]));
				case 1:
					return localPojo.toString();
				case 2:
					return Integer.valueOf(localPojo.hashCode());
				case 3:
					return localPojo.getName();
				case 4:
					localPojo.setName((String) paramArrayOfObject[0]);
					return null;
			}
			throw new IllegalArgumentException("Method not found: " + paramInt);
		}
	}

补充:

--

	ROUND 1:
	Benchmark                           Mode  Cnt   Score   Error  Units
 	MHOpto.mh_invoke                    avgt   15  11.332 ± 0.577  ns/op
 	MHOpto.mh_invokeExact               avgt   15  10.605 ± 0.667  ns/op
 	MHOpto.mh_invokeExact_static_fianl  avgt   15   3.797 ± 0.201  ns/op
 	MHOpto.plain                        avgt   15   4.093 ± 0.156  ns/op
 	MHOpto.reflect                      avgt   15  11.599 ± 0.646  ns/op
 	MHOpto.unreflect_invoke             avgt   15  11.147 ± 0.743  ns/op
 	MHOpto.unreflect_invokeExact        avgt   15  11.392 ± 0.518  ns/op

 	ROUND 2:
 	Benchmark                           Mode  Cnt   Score   Error  Units
	MHOpto.mh_invoke                    avgt   15  11.799 ± 0.847  ns/op
	MHOpto.mh_invokeExact               avgt   15  11.830 ± 0.637  ns/op
	MHOpto.mh_invokeExact_static_fianl  avgt   15   4.415 ± 0.191  ns/op
	MHOpto.plain                        avgt   15   4.084 ± 0.300  ns/op
	MHOpto.reflect                      avgt   15  12.191 ± 0.637  ns/op
	MHOpto.unreflect_invoke             avgt   15  11.535 ± 0.816  ns/op
	MHOpto.unreflect_invokeExact        avgt   15  11.828 ± 0.666  ns/op

`MethodHandle`太牛叉了。

## <a name="spring_async_servelt" >spring mvc的异步servlet实现</a>

spring异步web处理流程，我们先以`Controller`方法返回`Callable`对象为例

1. http线程处理请求到Controller方法，返回Callable结果
2. spring选用`CallableMethodReturnValueHandler`来处理Callable结果，提交Callable到线程池，当前http线程返回,参考`WebAsyncManager.startCallableProcessing()`
3. 线程池中线程执行`Callable`任务，并且`dispatch`请求到容器，参考`WebAsyncManager.setConcurrentResultAndDispatch()`
4. 容器选取http线程继续处理请求

通过分析源代码，下面几点需要关注下：

1. **dispatch请求后，又会执行filterchain**，我们需要保证filter只执行一次，filter最好继承`OncePerRequestFilter`。

2. spring内置了几种异步结果处理器，`CallableMethodReturnValueHandler`、`AsyncTaskMethodReturnValueHandler`、`DeferredResultMethodReturnValueHandler`分别支持方法返回`Callable`,`WebAsyncTask`,`DeferredResult`。

3. `org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter#taskExecutor`此默认线程池为`SimpleAsyncTaskExecutor`，此`taskExecutor`每次都会都会新建线程来处理任务，生产环境建议单独配置线程池。
