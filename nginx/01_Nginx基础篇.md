# Nginx基础篇

## 1. Nginx介绍

- Nginx开源版 http://nginx.org/en/

  官方原始的Nginx版本

- Nginx plus商业版

  开箱即用，集成了大量功能

- Open Resty https://openresty.org/cn/

  OpenResty是一个基于Nginx与 Lua 的高性能 Web 平台，其内部集成了大量精良的 Lua 库、第三方模块以及大多数的依赖项。**更适用于需要大量二次开发的场景，有极强的扩展性**

- Tengine https://tengine.taobao.org/

  由淘宝网发起的Web服务器项目。它在[Nginx (opens new window)](http://nginx.org/)的基础上，针对大访问量网站的需求，添加了很多高级功能和特性。Tengine的性能和稳定性已经在大型的网站如[淘宝网 (opens new window)](http://www.taobao.com/)，[天猫商城 (opens new window)](http://www.tmall.com/)等得到了很好的检验。相比于Open Resty，扩展性不够强，但是能够满足绝多数使用场景





## 2. Nginx安装

- **下载Nginx包**

  [官网下载地址(opens new window)](http://nginx.org/en/download.html)

- 解压Nginx包

  ```shell
  tar -zxvf  nginx-1.22.0.tar.gz #解压到当前目录
  
  cd nginx-1.22.0 #进入解压后的文件夹
  ls 
  #文件夹中的文件：auto  CHANGES.ru  configure  html     man     src CHANGES  conf  contrib    LICENSE  README
  ```

- 安装依赖库

  ```sh
  #安装C编译器
  yum install -y gcc
  
  #安装pcre库
  yum install -y pcre pcre-devel
  
  #安装zlib
  yum install -y zlib zlib-devel
  ```

- 安装

  ```sh
  ./configure --prefix=/usr/local/nginx #使用prefix选项指定安装的目录
  make
  make install
  ```

- 启动

  ```sh
  cd /usr/local/nginx/sbin
  
  ls # 里面是一个nginx的可执行文件
  
  ./nginx # 启动这个可执行
  ```

- 关闭防火墙

  ```sh
  systemctl stop firewalld
  ```

**补充Nginx命令**

  ```shell
  ./nginx -s stop #快速停止
  ./nginx -s quit #完成已接受的请求后，停止
  ./nginx -s reload #重新加载配置
  ./nginx -t #检查nginx配置是否正确
  ```

查看nginx状态

  ```text
  ps -ef | grep nginx
  ```

![](C:\Users\eardh\AppData\Roaming\Typora\typora-user-images\image-20220820162316291.png)

- 注册系统服务

  通过系统服务的方式启动nginx

  ```text
  vim /usr/lib/systemd/system/nginx.service
  ```

  ```shell
  [Unit] 
  Description=nginx
  After=network.target remote-fs.target nss-lookup.target
  
  [Service]
  Type=forking
  PIDFile=/usr/local/nginx/logs/nginx.pid
  ExecStartPre=/usr/local/nginx/sbin/nginx -t -c /usr/local/nginx/conf/nginx.conf
  ExecStart=/usr/local/nginx/sbin/nginx -c /usr/local/nginx/conf/nginx.conf
  ExecReload=/usr/local/nginx/sbin/nginx -s reload
  ExecStop=/usr/local/nginx/sbin/nginx -s stop
  ExecQuit=/usr/local/nginx/sbin/nginx -s quit 
  PrivateTmp=true
  
  [Install]   
  WantedBy=multi-user.target  # 多用户
  ```
  





## 3. Nginx 目录

```tex
- conf #配置文件
	- nginx.conf #主配置文件
	- 其他配置文件，都被引入到了nginx.conf
- html #静态页面
- logs
	- access.log #访问日志(每次访问都会记录)
	- error.log  #错误日志
	- nginx.pid  #进程号
- sbin
	- nginx #主进程文件
- *_temp    #运行时，生成临时文件
```

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202208222048643.png)





## 4. Nginx配置

后面学习Nginx配置，每次修改配置文件，一定要重载才能生效

```text
systemctl reload nginx
```



### 1. 简化版的nginx.conf

```shell
worker_processes  1; # 启动的worker进程数

events {
    worker_connections  1024; #每个worker进程的连接数
}


http {
    include       mime.types; #include是引入关键字，这里引入了mime.types这个配置文件（同在conf目录下，mime.types是用来定义，请求返回的content-type）
    default_type  application/octet-stream; #mime.types未定义的，使用默认格式application/octet-stream

    sendfile        on; #详情，见下文
    keepalive_timeout  65; #长链接超时时间
	
	#一个nginx可以启用多个server（虚拟服务器）
    server {
        listen       80; #监听端口80
        server_name  localhost;  #接收的域名

        location / {
            root   html; #根目录指向html目录
            index  index.html index.htm; #域名/index 指向 index.html index.htm文件
        }

        error_page   500 502 503 504  /50x.html; #服务器错误码为500 502 503 504，转到"域名/50x.html"
        location = /50x.html {# 指定到html文件夹下找/50x.htm
            root   html;
        }

    }
}
```

**sendfile**

打开sendfile，用户请求的数据不用再加载到nginx的内存中，而是直接发送

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202208222048357.png)



### 2. Nginx配置使用场景

修改nginx配置文件后，记得重新加载nginx

```text
systemctl reload nginx
```

**不同二级域名，映射到不同静态网页**

可以写多个server字段，从前向后匹配，先匹配到哪个就用哪个

用户访问`pro.hedaodao.ltd`，就会走到第一个server配置；`test.hedaodao.ltd`走到第二个配置

```shell
http {
 		#....其他属性
 	server {
        listen       80;
        server_name  pro.hedaodao.ltd;

        location / { 
            root   html/pro; 
            index  index.html index.htm;
        }

        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
	}

 	server {
        listen       80;
        server_name  test.hedaodao.ltd;

        location / { 
            root   html/test; 
            index  index.html index.htm;
        }

        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
	}
}
```



**不同域名，映射到同一静态页面**

server_name

- 可以写多个，用空格分开
- 使用通配符（*）
- 使用正则表达式（https://blog.csdn.net/yangyelin/article/details/112976539）

```shell
http {
 	server {
        listen       80;
        server_name  *.hedaodao.ltd  ~^[0-9]+\.hedaodao\.ltd$; # "\."是转译"."

        location / { 
            root   html/test; 
            index  index.html index.htm;
        }

        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
	}
}
```





## 5. 反向代理与负载均衡

**反向代理**：这种代理方式叫做，隧道代理。有性能瓶颈，因为所有的数据都经过Nginx，所以Nginx服务器的性能至关重要

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202208222048736.png)

**负载均衡**：把请求，按照一定算法规则，分配给多台业务服务器（即使其中一个坏了/维护升级，还有其他服务器可以继续提供服务）

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202208222048829.png)



### 1. 反向代理+负载均衡

**nginx.conf配置文件**

启用proxy_pass，root和index字段就会失效

proxy_pass后的地址必须写完整 `http://xxx`，不支持https

当访问localhost时（Nginx服务器），网页打开的是`http://xxx`（应用服务器），网页地址栏写的还是localhost

```shell
http {
 	server {
        listen       80;
        server_name  localhost;

        location / { 
        	proxy_pass http://xxx;
            #root   html/test; 
            #index  index.html index.htm;
        }

        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
	}
}
```



**定义地址别名 **

使用upstream定义一组地址【在server字段下】

访问localhost，访问都会代理到`192.168.174.133:80`和`192.168.174.134:80`这两个地址之一，每次访问这两个地址轮着切换（后面讲到，因为默认权重相等）

```shell
http {
	upstream httpds {
		server 192.168.174.133:80; #如果是80端口，可以省略不写
		server 192.168.174.134:80;
	}

	server {
        listen       80;
        server_name  localhost;

        location / { 
        	proxy_pass http://httpds;
        }

        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
	}
}
```



**设置权重**

访问使用哪个地址的权重

```text
upstream httpds {
	server 192.168.174.133:80 weight=10;
	server 192.168.174.134:80 weight=80;
}
```



**关闭**

```text
upstream httpds {
	server 192.168.174.133:80 weight=10 down;
	server 192.168.174.134:80 weight=80;
}
```



**备用机**

如果`192.168.174.133:80`出现故障，无法提供服务，就使用backup的这个机器

```text
upstream httpds {
	server 192.168.174.133:80 weight=10;
	server 192.168.174.134:80 weight=80 backup;
}
```



### 2. 动静分离

当用户请求时，动态请求分配到Tomcat业务服务器，静态资源请求放在Nginx服务器中

例子：

- 如果请求的资源地址是`location/`，`/`的优先级比较低，如果下面的location没匹配到，就会走http://xxx这个地址的机器
- 如果请求的资源地址是`location/css/*`，就会被匹配到nginx的html目录下的css文件夹中（我们把css静态资源放在这个位置）

```shell
server {
    listen       80;
    server_name  localhost;

	location / { # /的优先级比较低，如果下面的location没匹配到，就会走http://xxx这个地址的机器
    	proxy_pass http://xxx;
    }

    location /css {  # root指的是html，location/css指的是root下的css，所以地址就是html/css
    	root html;
    	index  index.html index.htm;
    }

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
    	root   html;
    }
}
```

使用正则

```text
location ~*/(js|css|img) {
	root html;
  	index  index.html index.htm;
}
```





### 3. URL重写

`rewrite`是URL重写的关键指令，根据regex（正则表达式）部分内容，重定向到replacement，结尾是flag标记。

```shell
rewrite    <regex>   <replacement>  [flag];
 关键字	   正则		 替代内容     flag标记
```

- `正则`：per1兼容正则表达式语句进行规则匹配
- `替代内容`：将正则匹配的内容替换成replacement
- `flag标记`说明：
  - `last`：本条规则匹配完成后，继续向下匹配新的location URI规则
  - `break`：本条规则匹配完成即终止，不再匹配后面的任何规则
  - `redirect`：返回302临重定向，浏览器地址会显示跳转后的URL地址
  - `permanent`：返回301永久重定向，测览器地址栏会显示跳转后的URL地址

浏览器地址栏访问 `xxx/123.html`实际上是访问`xxx/index.jsp?pageNum=123`

```shell
server {
    listen       80;
    server_name  localhost;

	location / { 
		rewrite ^/([0-9]+).html$ /index.jsp?pageNum=$1  break;
        proxy_pass http://xxx;
    }

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   html;
    }
}
```



### 4. 网关服务器

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202208222049990.png)

上图中，应用服务器，不能直接被外网访问到，只能通过Nginx服务器进行访问（使用proxy_pass），这时候这台Nginx服务器就成为了网关服务器（承担入口的功能）

所以，我们启动应用服务器的防火墙，设置其只能接受这台Nginx服务器的请求

**添加rich规则**

```shell
firewall-cmd --permanent --add-rich-rule="rule family="ipv4" source address="192.168.111.129" port protocol="tcp" port="8080" accept" #这里的192.168.174.135是网关 服务器地址
```

**移除rich规则**

```shell
firewall-cmd --permanent --remove-rich-rule="rule family="ipv4" source address="192.168.111.129" port port="8080" protocol="tcp" accept"
```

**重启**

移除和添加规则都要重启才能生效

```shell
firewall-cmd --reload
```

**查看所有规则**

```shell
firewall-cmd --list-all #所有开启的规则
```





## 6. 防盗链

当我们请求到一个页面后，这个页面一般会再去请求其中的静态资源，这时候请求头中，会有一个refer字段，表示当前这个请求的来源，我们可以限制指定来源的请求才返回，否则就不返回，这样可以节省资源

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202208222049998.png)

```shell
valid_referers none|server_name
```

设置有效的refer值

- none：检测地址没有refer，则有效
- server_name：检测主机地址，refer显示是从这个地址来的，则有效（server_name必须是完整的`http://xxxx`）

注意：`if ($invalid_referer)`中if后有个空格，不写就会报错

```shell
nginx: [emerg] unknown directive "if($invalid_referer)" in /usr/local/nginx/conf/nginx.conf:27
```

例子：这里设置nginx服务器中的img目录下的图片必须refer为http:192.168.174/133才能访问

```shell
server {
	listen       80;
	server_name  localhost;

	location / {
		proxy_pass http://xxx;
    }

    location /img {
    	valid_referers http:192.168.174/133;
    	if ($invalid_referer){#无效的
    		return 403;#返回状态码403
    	}
    	root html;
    	index  index.html index.htm;
    }

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
    	root   html;
    }
}
```

如果引用这张图片的页面且refer并没有被设置，图片无法加载出来

如果直接访问图片地址，因为没有refer字段指向来源，会直接显示Nginx的页面

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202208222049372.png)

**设置盗链图片**

将提示图片放在html/img/x.png，访问设置防盗链图片时，就返回这x.png张图

```shell
location /img {
	valid_referers http:192.168.174/133;
	if ($invalid_referer){#无效的
		rewrite ^/  /img/x.png break;
	}

	root html;
	index  index.html index.htm;
}
```





## 7. 高可用场景

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202208222049450.png)

用户访问时，访问的是一个虚拟IP，keepalived会选定一个主服务器使用这个虚拟IP

每台机器上的keepalived会相互通信，根据其他机器上的keepalived进程是否存在，判断服务器状态，如果默认的Master停止了，就会在剩下的Backup机器中，竞选出一台Nginx服务器作为Master

**安装keepalived**

```text
yum install -y keepalived
```

如果出现如下错误，应该是mysql8.0没有与keepalived的有关依赖

```sh
/var/cache/yum/x86_64/7/base/gen/comps.xml: no element found: line 1, column 0
错误：软件包：1:net-snmp-agent-libs-5.7.2-49.el7_9.2.x86_64 (updates)
          需要：libmysqlclient.so.18()(64bit)
错误：软件包：1:net-snmp-agent-libs-5.7.2-49.el7_9.2.x86_64 (updates)
          需要：libmysqlclient.so.18(libmysqlclient_18)(64bit)
```

如下操作即可

```sh
wget https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-community-libs-compat-5.7.25-1.el7.x86_64.rpm

rpm -ivh mysql-community-libs-compat-5.7.25-1.el7.x86_64.rpm
```

**修改keepalived配置**

- 配置文件在/etc/keepalived/keepalived.conf
- `vrrp_instance`、`authentication`、`virtual_router_id`、`virtual_ipaddress`这几个一样的机器，才算是同一个组里。这个组才会选出一个作为Master机器

这里我们设置两台机器，分别下载好keepalived，然后进行配置

机器一：

```shell
! Configuration File for keepalived

global_defs {
   router_id lb1   #名字与其他配置了keepalive的机器不重复就行
}

vrrp_instance heyingjie {  #vrrp实例名可以随意取
    state MASTER           #只能有一个默认的Master，其他写BACKUP
    interface ens33        #ip addr查看下网卡名，默认时ens33
    virtual_router_id 51
    priority 100 #多台安装了keepalived的机器竞争成为Master的优先级
    advert_int 1 #通信时间
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
        192.168.111.222 #虚拟IP
    }
}
```



机器二：

```shell
! Configuration File for keepalived

global_defs {
   router_id lb2 
}

vrrp_instance heyingjie {
    state BACKUP #只能有一个默认的Master，其他写BACKUP
    interface ens33 
    virtual_router_id 51
    priority 50
    advert_int 1 
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
        192.168.111.222 #虚拟IP
    }
}
```



通过命令`ip addr`查看机器一的ip信息，可以看到虚拟IP

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202208222049964.png)





## 8. 配置证书

购买服务器——>购买域名，并解析到这个主机——>购买证书，绑定到域名上，并且把证书文件安装到服务器，并在Nginx上配置好

这时候，这个域名就可以使用https进行访问里（`https://xxxx`），浏览器上会有一个小锁

**下载证书文件**

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202208222050045.png)

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202208222050614.png)

下载后，解压压缩包，可以看到两个文件，一个是 `xxx.key`（私钥）和`xxx.pem`（证书）

**配置**

将两个文件上传到Nginx目录中，记得放置的位置。我这里直接放在nginx.conf配置文件所在的目录（`/user/local/nginx/conf`），所以写的都是相对路径

```Nginx介绍
server {
	listen 443 ss1;

	ss1 certificate  xxx.pem; #这里是证书路径
	ss1_ certificate_key  xxx.key  #这里是私钥路径
}
```