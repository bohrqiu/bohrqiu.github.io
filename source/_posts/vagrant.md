---
title: 使用vagrant
date: 2014-07-07 21:52:17
categories: java
tags:
  - vagrant
---

vagrant挺火的,用于快速搭建开发环境.官方网站一行大字`Development environments made easy.`很惹眼.他可以实现可分发的环境搭建.

我们现在要快速搭建开发测试环境的需求很强烈,我们希望使用TA来快速搭建我们的开发测试环境.so,begin...

## 1.`Centos`上安装`Virtaul Box`[^1]

### 1.1 安装问题`unable to find the sources of your current Linux kernel. Specify KERN_DIR=<directory> and run Make again.`[^2]

Virtaul Box原因是`uname -r`和`ls /usr/src/kernels/`版本不一致,需要执行`yum update`,可以把国内的yum镜像用起来,会快点.完了重启下.

	
参考:

	http://rationallyparanoid.com/articles/virtualbox-centos-6.2.html
	https://www.centos.org/forums/viewtopic.php?t=5603
	
## 2.`Centos`上安装`vagrant`[^3]

### 2.1 `static IP on a bridged interface`
由于是公用的环境,会有很多个童鞋去访问,所以需要固定ip,并且上面的服务大家也可以自由访问,所以需要桥接网络.
但是官方网站上没有这样的配置,最后在github[^4]上发现了解决方案,测试了N遍,终于对头了:
	
	config.vm.network "public_network", :bridge => "eth0", :ip => "192.168.46.51"
	
如果是mac上,就用:

	config.vm.network "public_network", :bridge => "en0: Wi-Fi (AirPort)", :ip   => "192.168.1.222"
	
这样也需要注意下,如果要搭建多套环境,最好还是开一个新的网段,别和其他系统的ip冲突了.

如果只是你自己一个人玩,使用host-only吧,很简单.

### 2.2 `ext4 file system inconsistency`系统稳定性问题
不知道什么原因,过段时间就启动不了,最后通过`ssh tunneling`打开`Virtaul Box`图形化界面才发现了这个`ext4 file system inconsistency`问题.

错误日志如下:
	
		There is a known Linux kernel bug which can lead to the corruption of the virtual disk image under these conditions.
		Either enable the host I/O cache permanently in the VM settings or put the disk image and the snapshot folder onto a different file system.
		The host I/O cache will now be enabled for this medium.
		
这是一个kernel的bug,centos forum上遇到这个问题[^5],其他的虚拟化vmware也有同样的问题.

如果`enable host I/O cache`,又会遇到各种问题[^6].比如`data loss`,`I/O errors`,`I/O requests time out`,`Physical memory waste`都是童鞋们不能接受的.

只有选择使用不同的文件系统,`fdisk -l`看下`/home`还比较大,有上T的空间.
	
	#卸载home分区
	umount /dev/mapper/VolGroup-lv_home
	#格式化
	mkfs.ext3 /dev/mapper/VolGroup-lv_home
	#装载home分区
	mount /dev/mapper/VolGroup-lv_home /home
最后需要修改 `/etc/fstab`,改变挂载分区为`ext3`,重启后`sudo parted -l`看生效没有.现在可以在`/home`目录启动vagrant.

### 2.3 guest分配多核反而更慢

如果开启多核(比如设置为20核),又遇到启动很慢的问题[^7].原因是:

> VMs with multiple vCPUs require that all allocated cores be free before processing can begin. This means, if you have a 2 vCPU machine,2 physical cores must be available, and a 4 vCPU requires 4 physical cores

我开启20核,等了半个小时实在等不下去了.

查看cpu个数`grep 'physical id' /proc/cpuinfo | sort -u`,2个物理cpu.查看每个cpu核心数,`grep 'core id' /proc/cpuinfo | sort -u | wc -l`,每个cpu6个核心. 按照

>One point to note is that if you assign many more vCPUs than you have physical CPUs the system may run slower because the host spends more time scheduling threads than actually running them.

,理论上12个应该是最优的,但是感觉还是不太靠谱,测试某app启动性能:

cpus | 启动费时1|启动费时2
--- | --------|----- |
1   | 34664 | 34291
2   | 29040 | 29104
4	| 26205	| 26495
6	| 27207	| 28566
8	| 48087	| 44483

根据上面的测试,给vm配置4 cpus是最优的.卧槽,咱这服务两个物理cpu,每个cpu6 个核心,在加上`Hyperthreading`,`processor`都有24个了.如果这台服务器上有多个vm,咱这个测试最优的cpu数还会更少.

## 3.制作package

### 3.1 初始化vagrant环境
下载一个官方提供的base box[^8],用于初始化环境.这里我们选择CentOS 6.4 x86_64[^9].
在前面提到的ext3分区上进行:

	 #添加镜像到 Vagrant
	 vagrant box add yiji package.box
	 #初始化环境
	 vagrant init yiji

当前目录会有一个`Vagrantfile`文件,加上前面测试的东东:

	config.vm.network "public_network", :bridge => "eth0", :ip => "192.168.46.51"
	config.vm.provider :virtualbox do |vb|
        vb.gui = false
        #设置内存
        vb.customize ["modifyvm", :id, "--memory", "5120"]
        #设置虚拟机ip
        vb.customize ["modifyvm", :id, "--cpus", "4"]
        #设置ioapic,启用多个cpu时,必须设置.如果就一个cpu就不要设置,影响性能
        vb.customize ["modifyvm", :id, "--ioapic", "on"]
        #vb.customize ["modifyvm", :id, "--cpuexecutioncap", "50"]
    end

启动虚拟机并ssh登陆:
	
	#启动虚拟机
	vagrant up
	#ssh登陆
	vagrant ssh
	
### 3.2 初始化VM环境
ssh登陆后,此时是用vagrant用户登陆的,这个时候神马事情都干不了,切换到root用户

	#修改root密码
	sudo passwd root
	#切换到root账户
	su - root
配置路由和dns服务器:
	
	sudo route del default
	sudo route add default gw 192.168.46.254
	echo "nameserver 192.168.45.10" > /etc/resolv.conf
	echo "nameserver 8.8.8.8" >> /etc/resolv.conf
添加定时常用定时任务:
	
	#每12小时时间服务同步
	0 */12 * * * rdate -s time.nist.gov
	#每天清理日志
	0 0 * * * /script/deletelog.sh
	
关闭防火墙:

	chkconfig ip6tables off
	chkconfig iptables off
为了集中控制jvm的启动参数,定义java应用依赖环境变量:

	export APP_JAVA_OPTS="-Xms256m -Xmx512m"
所有的java应用启动脚本中把`APP_JAVA_OPTS`加在启动参数的最后,它的优先级最高,就很方便的控制所有的jvm进程内存大小了.

上面有些东西可以脚本化的,尽量就脚本化,比如在`/etc/rc.d/rc.local`增加启动脚本`init.sh` .其他脚本分为 `init_network.sh` `init_env.sh` `init_common_app.sh` `init_app.sh`

### 3.3 安装memcache
安装:

	yum install memcached
	 
配置文件:
	
	/etc/sysconfig/memcached
命令:

	service memcached start/stop/restart/status

设置开机启动:
	
	chkconfig memcached on
修改`/etc/init.d/memcached`可以修改memcache启动参数

### 3.4 安装rabbitmq
 
安装:
 
	yum install rabbitmq
 	#安装webui
 	rabbitmq-plugins enable rabbitmq_management
 	#启用guest账户 访问web ui
 	echo "[{rabbit, [{loopback_users, []}]}]." >/etc/rabbitmq/rabbitmq.config
 		
 
常用命令:
 	
 	service rabbitmq-server stop/start/etc.
 		
web ui访问地址,账号密码guest/guest:
 		
 	http://192.168.46.51:15672/
 	
设置开机启动:
	
	chkconfig rabbitmq-server on
	
### 3.5 安装其他软件

jdk/maven/memcache/zookeeper/rabbitmq/dubbo-monitor-simple/dubbo-admin

### 3.6 服务列表说明

| 服务			 | 服务端口 | web ui 端口 |
| -------------- | ------------- | ------------ |
| memcache 		| 11211  | 无 |
| zookeeper		| 2181   | 无 |
| rabbitmq 		| 5672   | 15672 |
| dubbo-monitor | 7070  | 7071 |
| dubbo-admin	| 无     | 7073 |

### 3.7 制作分发包

	vagrant package
上面命令会在当前目录生成一个`package.box`文件,此文件拷贝到其他服务器,就可以快速搭建系统了.

### 3.8 常用vagrant 命令
	
	#初始化环境,此命令会生成Vagrantfile配置文件,如果当前目录有Vagrantfile,不要执行此命令,直接up吧
	vagrant init
	
	#启动虚拟机  
	vagrant up
	
	#关闭虚拟机  
	vagrant halt
	
	# 重新启动虚拟机,如果Vagrantfile被修改后,执行此命令才能生效.
	#但是修改cpu相关参数,此命令也不能重新加载配置,这个时候把虚拟机先停下来,
	#通过ssh tunneling在gui界面里调整
	vagrant reload 
	
	#SSH至虚拟机
	vagrant ssh
	  
	#查看虚拟机运行状态
	vagrant status
	
	# 销毁当前虚拟机
	vagrant destroy  
	
	#add box
	vagrant box add boxname xxx.box
	
	#remove box
	
	vagrant box remove boxname
	
	#list box
	vagrant box list
	
## 4.写在最后
`virtual box`的性能让人担忧,如果部署应用太多需要仔细权衡下,如果只是搭建单机环境,使用vagrant还是很ok的.

[^1]: [`Virtual Box`下载地址](https://www.virtualbox.org/wiki/Linux_Downloads)
[^2]: [unable to find the sources of your current Linux kernel](https://www.centos.org/forums/viewtopic.php?t=5603)
[^3]: [`vagrant`下载地址](http://www.vagrantup.com/downloads.htmlhttp://www.vagrantup.com/downloads.html)
[^4]: [Static ip addresses on public networks](https://github.com/mitchellh/vagrant/pull/1745)
[^5]: [ext4 file system inconsistency](https://www.centos.org/forums/viewtopic.php?t=4436)
[^6]: [Host I/O caching](https://www.virtualbox.org/manual/ch05.html#iocaching)
[^7]: [Adding CPUs to Virtualbox guests makes guests boot SLOWER](http://www.reddit.com/r/linux/comments/1tqlsz/adding_cpus_to_virtualbox_guests_makes_guests/)
[^8]: [vagrant base box](http://www.vagrantbox.es/)
[^9]: [vagrant base box CentOS 6.4 x86_64](https://github.com/2creatives/vagrant-centos/releases/download/v6.4.2/centos64-x86_64-20140116.box)