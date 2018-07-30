---
title: dubbo
date: 2014-09-23 21:52:17
categories: java
tags:
  - dubbo
---

# dubbo的一些分析和优化

## dubbo应用线程分析

### dubbo-remoting-client-heartbeat-thread

dubbo客户端心跳线程

线程启动类：`HeaderExchangeClient`

任务执行类：`HeartBeatTask`

此任务会定时向服务端发送心跳消息，每个连接一个任务，执行周期默认为60s，执行时会判断此`Channel`是否在心跳周期类有读写，如果没有，给服务端发送心跳信号.

改进措施：可以给执行线程合理命名。


### xxxx-EventThread

zookeeper事件处理线程

线程启动类：`org.apache.zookeeper.ClientCnxn`

任务执行类：`org.apache.zookeeper.ClientCnxn.EventThread`

此线程的命名格式为`启动线程名+EventThread`，其中的`localhost-startStop-1`tomcat启动线程名。

在`CuratorFrameworkImpl`启动时，会向zookeeper服务器建立连接，此时会创建此线程。

我们必须保证一个应用只有一个`CuratorFrameworkImpl`实例。

### localhost-startStop-1-SendThread

zookeeper 心跳、发送请求线程

线程启动类：`org.apache.zookeeper.ClientCnxn`

任务执行类：`org.apache.zookeeper.ClientCnxn.SendThread`

### DubboClientReconnectTimer-thread

消费者连接服务提供者的定时重连任务，默认执行周期2s，检查是否连接，没有连接重新连接。

线程启动类：`com.alibaba.dubbo.remoting.transport.AbstractClient`

任务执行类：`com.alibaba.dubbo.remoting.transport.AbstractClient$1`

### DubboServerHandler-

dubbo服务端，任务处理线程,处理客户端请求

线程池启动类:`AllChannelHandler`的构造器中初始化线程池

线程池实际创建类：`FixedThreadPool`

任务处理类：`com.alibaba.dubbo.remoting.transport.DecodeHandler`

### DubboClientHandler-

此线程主要用于dubbo客户端处理服务端的响应/连接相关事件，netty在接受到消息后，交给此线程池来处理。

线程启动类：`com.alibaba.dubbo.remoting.transport.AbstractClient#wrapChannelHandler`

线程池实际创建类：`CachedThreadPool`

任务处理类：`com.alibaba.dubbo.remoting.transport.DecodeHandler`

### DubboRegistryFailedRetryTimer

当dubbo和注册中心的相关请求(注册、取消注册、订阅、取消订阅)处理失败时，会暂时放在缓存中，此定时任务会周期性的来处理这些失败的请求

线程启动类：`com.alibaba.dubbo.registry.support.FailbackRegistry`

处理任务：`com.alibaba.dubbo.registry.support.FailbackRegistry#retry`

### DubboSaveRegistryCache

异步保存服务提供者地址

线程启动类：`com.alibaba.dubbo.registry.support.AbstractRegistry`

任务执行类：`com.alibaba.dubbo.registry.support.AbstractRegistry.SaveProperties`

### DubboResponseTimeoutScanTimer

扫描等待返回的`DefaultFuture`对象，如果`DefaultFuture`超时，则抛出超时异常。

任务类:`DefaultFuture.RemotingInvocationTimeoutScan`

优化意见：目前的方式是间隔30ms就去扫描一次，建议重写`ConcurrentHashMap`缓存，加入队列等待机制。

## telnet

`com.alibaba.dubbo.remoting.transport.dispatcher.ChannelEventRunnable`处理netty的事件，他会把telnet请求(decode后为文本)代理给`com.alibaba.dubbo.remoting.telnet.support.TelnetHandlerAdapter`来处理。

## dubbo线程池任务不均衡问题分析

dubbo应用使用的线程池为`com.alibaba.dubbo.common.threadpool.support.fixed.FixedThreadPool`,如果当queue设置为0时,会使用`SynchronousQueue`,这个东东导致了任务线程执行"不均衡"(满足了大家的心理预期,其实这种不均衡方式减少了上下文切换,但是`SynchronousQueue`没有大小,不能起到任务缓冲的作用).


请在dubbo:protocol上加上queues大小(参考tomcat默认配置).

	    <dubbo:protocol name="dubbo" port="${dubbo.provider.port}" threads="200" queues="100"/>

测试:

修改前:

	grep DubboServerHandler dubbo-demo.log |awk  -F '-'  '{print $6}' |awk  -F ']'  '{print $1}' |sort -n |uniq -c
	
      1 150
      1 168
      1 169
      1 170
      ...
      117 171
      5386 172
      714 173
   	   2646 174

修改后:

	grep DubboServerHandler dubbo-demo.log |awk  -F '-'  '{print $6}' |awk  -F ']'  '{print $1}' |sort -n |uniq -c
    507 1
    498 2
 	...
    493 199
    489 200

## 线程池优化

jdk默认线程池实现策略如下：

1. 当线程数少于corePoolSize，总是新建线程
2. 当线程数=corePoolSize时，所有线程都忙，就会把线程放入队列；当队列满时，才会继续创建线程
3. 当线程数量=maxPoolSize并且队列也满时，`RejectedExecutionHandler`生效。

易极付内部对线程池做了些优化：

1. 我们希望能充分利用资源，仅当线程数量=maxPoolSize时，才放入队列。当线程空闲时，线程池收缩到corePoolSize。
2. 当队列设置得比较小的时候，即便线程数量<maxPoolSize,在高并发下也会触发`RejectedExecutionHandler`
3. 线程池没有传递`MDC`或者应用请求`gid`。

对于1，2，可以参考tomcat内部的线程池实现`org.apache.tomcat.util.threads.ThreadPoolExecutor`和`org.apache.tomcat.util.threads.TaskQueue`来改造。

对于3，wrap原任务即可，大致代码如下：

``` java
private static class MDCGidCallable<T> implements Callable<T> {
	private final Callable<T> task;
	private final String gid;
	
	public MDCGidCallable(Callable<T> task, String gid) {
		this.task = task;
		this.gid = gid;
	}
	
	@Override
	public T call() throws Exception {
		try {
			MDC.put(GID_KEY, gid);
			return task.call();
		} finally {
			MDC.remove(GID_KEY);
		}
	}
}
```
## 缓存扩展

下面是我们自己实现的cache机制，个人感觉比dubbo原生的清爽，通过dubbo filter实现。

源代码见[dubbo-cache](https://github.com/bohrqiu/dubbo-cache)

### 使用`@DubboCache`

`@DubboCache`提供dubbo消费者直接使用缓存的能力，当缓存不存在时，再访问远程dubbo服务。

对于dubbo服务提供者，只需要在dubbo接口上增加此注解。

```java
public interface CacheableService {
	@DubboCache(cacheName = "test",key = "order.playload")
	SingleValueResult<String> echo(SingleValueOrder<String> order);
}
```
如上所示，`cacheName=test`,`key`为第一个参数的playload字段，缓存有效期默认5分钟。可以通过设置`expire`属性修改缓存有效期。

上面的注解和`@org.springframework.cache.annotation.Cacheable(value = "test", key = "order.playload")`生成的key一致。

对于dubbo服务消费者，只需要跟新jar包即可。

### 控制缓存

@DubboCache`提供了消费者可优先使用缓存，**缓存的一致性由服务提供方负责**，当服务提供方使用此注解后，所有的服务消费者都会使用此缓存。

控制缓存分为两种情况：

1. 缓存一致性要求不高，可以通过`DubboCache#expire`设置过期时间，默认为5分钟。
2. 缓存一致性要求高，服务提供方通过`redisTemplate`或者`org.springframework.cache.annotation.CacheEvict`控制缓存。
	
## dubbo mock

mock最好是有mock server。由于懒，把mock server的client实现了(拦截请求，转换为http+json调用到mock server)，后面就没时间做mock server了。前段时间有个项目紧急需要，做了个简单的mock。

原理如下：

### 对于使用者：

1. 用户配置需要mock的dubbo服务。

	比如： `dubbo.consumer.mockInterfaces[0]=com.acooly.core.test.dubbo.mock.XXFacade`

2. 增加mock实现。

```java
@Service
public class XXFacadeMock implements XXFacade {
	 @Override
	public SingleResult<String> echo(SingleOrder<String> msg) {
		return SingleResult.from("mocked");
	}
}
```

### 组件提供的能力	
	
1. 自定义实现`BeanPostProcessor`,扫描所有标注`@Reference`注解的属性，如果被配置了要mock掉，设置属性为mock实现。

## 最后

最后附带一个在易极付写的dubbo分享。

{% pdf dubbo.pdf %}

