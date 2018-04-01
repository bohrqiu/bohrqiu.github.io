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
### 1.1 FastInfoset
采用了[FastInfoset](http://en.wikipedia.org/wiki/Fast_Infoset)(简称FI)，效果很明显，极端条件下的大数据量传输，性能提高60%，他可以减少传输成本，序列化成本和xml解析成本。cxf基于http协商机制(检查请求header中`Accept: application/fastinfoset`)来启用FI。
### 1.2 Gzip
客户端和服务器端是否使用Gzip压缩，也是基于http协议协商的(检查请求header 中是否有`Accept-encoding:gzip`)。但是这里需要仔细权衡下。对于小数据量，启用gzip压缩支持是吃力不讨好的行为，数据量很小的时候，gzip压缩结果不明显，还浪费cpu。
### 1.3 unexpected element异常
见:http://bohr.me/cxf-unexpected-element/### 1.4 处理过程分析cxf 中通过一些列interceptor来完成数据解析处理操作，每个interceptor绑定到特定的阶段，下面是GZIP 和FI interceptor所处的阶段

类型 | Direction | Phase
----- | ------- | ------------
Gzip | IN  | Phase.RECEIVE
  | Out  | Phase.PREPARE_SEND
 FI | IN  | Phase.POST_STREAM
 | Out  | Phase.PRE_STREAM	数据进来时，先`RECEIVE`阶段适配InputStream对象为GZIPInputStream，然后在`POST_STREAM`阶段解析数据。完成gzip解压缩，FI解析数据过程。
数据出去时，在`PREPARE_SEND`阶段适配OutputStream对象为GZipThresholdOutputStream，在`PRE_STREAM`阶段再序列化为二进制数据传输出去。完成FI序列化数据，GZIP压缩数据过程。
测试发送20250byte数据，仅仅启用FI时，发送数据量为20181byte，再启用Gzip压缩后，发送数据量为258byte。
## 2.操作步骤
### 2.1添加依赖
cxf版本修改为2.7.0并加入FastInfoset
	<dependency>		<groupId>com.sun.xml.fastinfoset</groupId>		<artifactId>FastInfoset</artifactId>		<version>1.2.9</version>	</dependency>
	### 2.2	修改cxf配置
#### 2.2.1 删除引入的cxf配置 
	<import resource="classpath:META-INF/cxf/cxf.xml" />	<import resource="classpath:META-INF/cxf/cxf-extension-soap.xml" />	<import resource="classpath:META-INF/cxf/cxf-servlet.xml" />
	我们项目中很多spring配置文件都加入了上面的东东，这个不是必须的，不删除这东东会导致配置不生效。
#### 2.2.2 配置gzip和FI
Spring配置文件中引入cxf namespace`xmlns:cxf=http://cxf.apache.org/core和xsi:schemaLocationhttp://cxf.apache.org/core  http://cxf.apache.org/schemas/core.xsd`
然后加入配置	
	<cxf:bus>		<cxf:features>			<cxf:fastinfoset force="false" />			<bean class="org.apache.cxf.transport.common.gzip.GZIPFeature">				<property name="threshold">					<value>2048</value>				</property>			</bean>		</cxf:features>	</cxf:bus>注意这些特性client和server端都要配置。
## 3.写在最后
启用`gzip`和`FastInfoset`,性能基本上也到达webservice的极致了.通过`IgnoreUnexpectedElementValidationEventHandler`再解决易用性问题,基本完美.