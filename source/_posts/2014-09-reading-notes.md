---
title: 2014年09月Reading Notes
date: 2014-09-28 21:52:17
categories: java
tags:
  - READING NOTES
---

## Mcrouter:基于 Memcached协议的缓存层流量管理工具
[http://www.infoq.com/cn/news/2014/09/mcrouter-memcached](http://www.infoq.com/cn/news/2014/09/mcrouter-memcached)

[https://code.facebook.com/posts/296442737213493/introducing-mcrouter-a-memcached-protocol-router-for-scaling-memcached-deployments/](https://code.facebook.com/posts/296442737213493/introducing-mcrouter-a-memcached-protocol-router-for-scaling-memcached-deployments/)

memcache不支持服务端路由,facebook开发了`mcrouter`(能够处理每秒50亿次的请求).它和memcached之间通过文本协议通信.扮演者memcached服务器的客户端,应用的服务端.他的特性很多,基本上都是我们需要的.我们现在使用的是二进制协议,需要修改为文本协议.



