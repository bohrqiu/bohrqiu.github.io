---
title: webservice优化
date: 2014-08-14 21:52:17
categories: java
tags:
  - webservice
---

很早之前写的一篇文字,一直没有搬上blog,以后会慢慢把有些东西放到blog上来.

webservice的性能实在是敢恭维。曾经因为webservice吞吐量上不去，对webservice进行了一些性能方面的优化:

## 1.分析







类型 | Direction | Phase
----- | ------- | ------------
Gzip | IN  | Phase.RECEIVE
  | Out  | Phase.PREPARE_SEND
 FI | IN  | Phase.POST_STREAM
 | Out  | Phase.PRE_STREAM















