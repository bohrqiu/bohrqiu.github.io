---
title: 准实时同步应用日志到数仓
date: 2018-05-30 20:07:47
tags: 
	- 数仓
	- 日志同步
---

## 准实时同步日志到数仓

传统的etl工具很难做到准实时的数据同步，我们以前使用kettle来做etl，对于日志同步的场景有几个问题：

1. 做不到实时，kettle只能定时触发
2. 比较难做到日志文件增量处理，需要记录上次读取的文件位置

鉴于以上情况，实践了下logstash的日志[output jdbc插件](https://github.com/theangryangel/logstash-output-jdbc)。

### 1. 日志模型定义

定义日志通用模型如下：

	{
	  "appName": "",
	  "body": {
	   
	  },
	  "businessName": "",
	  "env": "",
	  "hostName": "",
	  "timestamp": ""
	}
	
body节点由数据埋点应用根据数据模型自定义。

比如线上某业务埋点数据如下：

	{
	  "appName": "openapi",
	  "body": {
	    "app_version": "3.1.18",
	    "device_id": "123456",
	    "phoneType": "HUAWEI MATE10",
	    "userid": "201702057568"
	  },
	  "businessName": "userRegister",
	  "env": "online",
	  "hostName": "172.16.0.158",
	  "timestamp": "2018-05-30 00:00:41"
	}


### 2. logstash配置

	output {
		#不同的业务日志模型输出到不同的表
	    if [businessName] == "userRegister"{
	      jdbc {
	          driver_class => "com.mysql.jdbc.Driver"
	          connection_string => "jdbc:mysql://127.0.0.1:3306/log?user=root&password=123456"
	          enable_event_as_json_keyword => true
	          #解析body中的数据到指定的日志表
	          statement => [ "INSERT INTO log_user_register (host, time, message,app_version,channel) VALUES(?, ?, ?,?,?)", "host", "@timestamp", "message","%{[body][app_version]}","%{[body][channel]}" ]
	      }
	    }
	    if [businessName] == "userLogin"{
	      jdbc {
	          driver_class => "com.mysql.jdbc.Driver"
	          connection_string => "jdbc:mysql://127.0.0.1:3306/log?user=root&password=123456"
	          enable_event_as_json_keyword => true
	          statement => [ "INSERT INTO log_user_login (host, time, message,app_version,channel) VALUES(?, ?, ?,?,?)", "host", "@timestamp", "message","%{[body][app_version]}","%{[body][channel]}" ]
	      }
	    }
	  }

### 3. 改进之处

1. 通过不同的业务类型创建了多个`jdbc output plugin`，[jdbc.rb](https://github.com/theangryangel/logstash-output-jdbc/blob/master/lib/logstash/outputs/jdbc.rb)中创建了数据库连接池，比如上面的配置创建了两个数据库连接池。这里需要优化成支持不同的业务类型使用不同的`statement`.
