---
title: 2016年04月Reading Notes
date: 2016-04-05 21:52:17
categories: java
tags:
  - READING NOTES
---
	
## <a name="false-sharing">@Contended FOR false sharing</a>

ABOUT False Sharing：

>>Most high performance processors, insert a cache buffer between slow memory and the high speed registers of the CPU. Accessing a memory location causes a slice of actual memory (a cache line) containing the memory location requested to be copied into the cache. Subsequent references to the same memory location or those around it can probably be satisfied out of the cache until the system determines it is necessary to maintain the coherency between cache and memory.


>>Each update of an individual element of a cache line marks the line as invalid. Other processors accessing a different element in the same line see the line marked as invalid. They are forced to fetch a more recent copy of the line from memory or elsewhere, even though the element accessed has not been modified. This is because cache coherency is maintained on a cache-line basis, and not for individual elements. As a result there will be an increase in interconnect traffic and overhead.

当下列条件满足时，False sharing极大降低了并发性能。

* Shared data is modified by multiple processors.
* Multiple processors update data within the same cache line.
* This updating occurs very frequently (for example, in a tight loop).

java8 引入了`@Contended`，在对象编译时，编译器会插入`padding`,防止多个数据在一个cache line中。


`https://github.com/m0wfo/false-sharing-demo`测试结果：

	[0] % java -XX:-RestrictContended -jar target/false-sharing-demo-1.0.0-SNAPSHOT.jar plain
	Updating unpadded version 1B times Took: 55.457223514sec
	Updating @Contended version 1B times Took: 7.387646696sec