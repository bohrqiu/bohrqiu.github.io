---
title: 2015年03月Reading Notes
date: 2015-03-02 21:52:17
categories: java
tags:
  - READING NOTES
---


## The Asset Pipeline
[http://guides.rubyonrails.org/asset_pipeline.html](http://guides.rubyonrails.org/asset_pipeline.html)

`Asset Pipeline`对网站的静态资源进行预处理(合并、简化、压缩、预处理coffeescirpt sass等)。对于静态资源的处理，这里面提到的`Fingerprinting`来优化http 缓存可以借鉴下。

`Fingerprinting`技术是在文件名中加上文件内容的标识，当文件内容改变时，文件名也改变。比如文件`global.css`加入md5的指纹后，文件名为`global-908e25f4bf641868d8683022a5b62f54.css`.

以前我们经常用`query string`中来标识版本，比如`main.js?1.4`/`main.js?v=1.4`.这种方式在某些CDN中有问题(有些CDN只识别文件名，新的版本文件会替换原版本的文件，在部署这个时间窗口会导致页面混乱)。

在使用浏览器缓存时，一般涉及到http header包括下面两种方案:

1. `Expires`和`Cache-Control: max-age` (没有过期之前，完全不发送请求)
2. `Last-Modifed`和`ETag` (内容协商，需要发一个请求，如果内容没有变化，响应304)

当方案2和`Fingerprinting`结合起来时，就比较完美了。对于现在很多开放CDN来讲，基本上都会用方案1，这是开源库名字里面的版本号就起着`Fingerprinting`的作用。也有用方案2的，估计是出于统计分析的目的。

对于静态资源的缓存，理想的组合是：

1. 配置很长的本地缓存时间(善用`Expires`和`Cache-Control: max-age`)，比如1年
2. 通过`Fingerprinting`控制缓存(静态资源文件改变，对应的html的资源引用url也改变)
