---
title: 线程间的同步
date: 2017-07-28 21:52:17
categories: java
tags:
  - share
---


jdk提供了比较多的线程间同步工具，比如`Lock`,`CountDownLatch`,`Condition`来完成线程间的同步，但是这些高级工具在某些场景可能显得太重量级了，本文简单探讨下不同的实现方式的。

我们假设如下场景，线程A创建任务id=1发起远程调用，响应时，io线程解码id，并通知线程A继续执行。定义如下接口：

	public interface FutureResult {

		Object get(long timeout, @NotNull TimeUnit unit) throws TimeoutException;

		void set(Object Result);

		boolean isDone();

		Integer getId();

		Map<Integer, FutureResult> FUTURE_RESULTs = Maps.newConcurrentHashMap();

		static void set(Integer id, Object response) {
			final FutureResult future = FUTURE_RESULTs.remove(id);
			if (future != null) {
				future.set(response);
			}
		}

		AtomicInteger idx = new AtomicInteger();

		static Integer getNextId() {
			return idx.incrementAndGet();
		}
	}


## 1. 使用LockSupport

	@Slf4j
	public class LockSupportFutureResult implements FutureResult {
		private Integer id;
		private volatile Object result;
		private Thread runner;

		public LockSupportFutureResult() {
			id = FutureResult.getNextId();
			FUTURE_RESULTs.put(id, this);
		}

		public Object get(long timeout, @NotNull TimeUnit unit) throws TimeoutException {
			if (result != null) {
            	return result;
        	}
			long nanos = unit.toNanos(timeout);
			final long deadline = System.nanoTime() + nanos;
			runner = Thread.currentThread();
			try {
				for (; ; ) {
					LockSupport.parkNanos(this, nanos);
					nanos = deadline - System.nanoTime();
					if (nanos <= 0L) {
						throw new TimeoutException();
					} else {
						if (result != null) {
							return result;
						}
					}
				}
			} finally {
				FUTURE_RESULTs.remove(this.id);
			}
		}

		public void set(Object response) {
			LockSupport.unpark(this.runner);
			this.result = response;
		}

		public boolean isDone() {
			return this.result != null;
		}

		public Integer getId() {
			return id;
		}
	}

## 2. 使用FutureTask

	@Slf4j
	public class FutureTaskResult extends FutureTask implements FutureResult {
		private static Callable DO_NOTHING = () -> null;
		private Integer id;

		public FutureTaskResult() {
			super(DO_NOTHING);
			id = FutureResult.getNextId();
			FUTURE_RESULTs.put(id, this);
		}

		public Integer getId() {
			return id;
		}

		public void set(Object o) {
			super.set(o);
		}

		@Override
		public Object get(long timeout, @NotNull TimeUnit unit) throws TimeoutException {
			try {
				return super.get(timeout, unit);
			} catch (InterruptedException | ExecutionException e) {
				throw new RuntimeException(e);
			} finally {
				FUTURE_RESULTs.remove(this.id);
			}
		}
	}

## 3. 简单总结

使用`CountDownLatch`,`ReentrantLock`，内部使用`AbstractQueuedSynchronizer`数据结构来处理多个等待者，当请求数量很大时，这种开销也不容小视。如果非常关注性能可以考虑直接用`LockSupport`，担心hold不住的话可以考虑用`FutureTask`.
