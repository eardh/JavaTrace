# MyCat2

***

## 1. Mycat概述

如今随着互联网的发展，数据的量级也是成指数的增长，从 GB 到 TB 到 PB。对数据的各种操作也是愈加的困难，传统的关系性数据库已经无法满足快速查询与插入数据的需求。这个时候 NoSQL 的出现暂时解决了这一危机。它通过降低数据的安全性，减少对事务的支持，减少对复杂查询的支持，来获取性能上的提升。

但是，在有些场合 NoSQL 一些折衷是无法满足使用场景的，就比如有些使用场景是绝对要有事务与安全指标的。这个时候 NoSQL 肯定是无法满足的，所以还是需要使用关系性数据库。如何使用关系型数据库解决海量存储的问题呢？此时就需要做数据库集群，为了提高查询性能将一个数据库的数据分散到不同的数据库中存储。



### 1. 基本介绍

Mycat是`数据库分库分表`中间件。

**1、数据库中间件**

**中间件：是一类连接软件组件和应用的计算机软件，以便于软件各部件之间的沟通。**

例子：Tomcat，web中间件。

数据库中间件：连接java应用程序和数据库

**2、为什么要用Mycat？**

①  Java与数据库紧耦合。万一耦合的MySQL DBMS挂了怎么办？

②  高访问量、高并发对数据库的压力。

③  多个数据库读写请求数据不一致

**3、数据库中间件对比**

![](https://gitlab.com/eardh/picture/-/raw/main/mysql_img/202203311538052.png)

①  `Cobar`属于阿里B2B事业群，始于2008年，在阿里服役3年多，接管3000+个MySQL数据库的schema，集群日处理在线SQL请求50亿次以上。由于Cobar发起人的离职，Cobar停止维护。

②  `Mycat`是开源社区在阿里cobar基础上进行二次开发，解决了cobar存在的问题，并且加入了许多新的功能在其中。青出于蓝而胜于蓝。

③  `OneProxy`基于MySQL官方的proxy思想利用c语言进行开发的，OneProxy是一款商业`收费`的中间件。舍弃了一些功能，专注在`性能和稳定性上`。

④  `kingshard`由小团队用go语言开发，还需要发展，需要不断完善。

⑤  `Vitess`是Youtube生产在使用，架构很复杂。不支持MySQL原生协议，使用`需要大量改造成本`。

⑥  `Atlas`是360团队基于mysql proxy改写，功能还需完善，高并发下不稳定。

⑦  `MaxScale`是mariadb（MySQL原作者维护的一个版本） 研发的中间件

⑧  `MySQLRoute`是MySQL官方Oracle公司发布的中间件

![](https://gitlab.com/eardh/picture/-/raw/main/mysql_img/202203311538004.png)

**3、Mycat的官网**

http://www.mycat.org.cn/



### 2. Mycat作用和与原理

#### 1. 作用

**1、读写分离**

![](https://gitlab.com/eardh/picture/-/raw/main/mysql_img/202203311538608.png)

![](https://gitlab.com/eardh/picture/-/raw/main/mysql_img/202203311546224.png)

**2、数据分片**

垂直拆分（分库）、水平拆分（分表）、垂直+水平拆分（分库分表）

![](https://gitlab.com/eardh/picture/-/raw/main/mysql_img/202203311539040.png)

![](https://gitlab.com/eardh/picture/-/raw/main/mysql_img/202203311546838.png)

**3、多数据源整合**

![](https://gitlab.com/eardh/picture/-/raw/main/mysql_img/202203311539527.png)

Mycat支持的数据库：

![](https://gitlab.com/eardh/picture/-/raw/main/mysql_img/202203311539866.png)



#### 2. 原理

Mycat 的原理中最重要的一个动词是“`拦截`”，它拦截了用户发送过来的 SQL 语句，首先对 SQL 语句做了一些特定的分析：如`分片分析、路由分析、读写分离分析、缓存分析`等，然后将此 SQL 发往后端的真实数据库，并将返回的结果做适当的处理，最终再返回给用户。

![](https://gitlab.com/eardh/picture/-/raw/main/mysql_img/202203311539622.png)

这种方式把数据库的分布式从代码中解耦出来，程序员察觉不出来后台使用`Mycat`还是`MySQL`。

整体过程可以概括为：`拦截` --  `分发` -- `响应`



### 3. Mycat2

![](https://gitlab.com/eardh/picture/-/raw/main/mysql_img/202203311539915.png)

右侧的MySQL在Mycat2的配置里面叫做prototype，专门用于响应兼容性SQL和系统表SQL。

**什么是兼容性SQL？**

客户端或者所在应用框架运行所需必须的SQL，但是用户一般接触不到，它们会影响客户端的启动，运行。而Mycat对于这种SQL尽可能不影响用户使用。

**什么prototype服务器?**

`分库分表中间件`中用于`处理MySQL的兼容性SQL和系统表SQL(比如用于显示库,表的sql)`的服务器，这个配置项可以指向一个服务器也可以是一个集群，Mycat依赖它处理非select,insert,update,delete语句。当这个服务器是与第一个存储节点是同一个服务器/集群的时候，人们一般叫它做0号节点。

![](https://gitlab.com/eardh/picture/-/raw/main/mysql_img/202203311539374.png)

当需要进行数据分片的时候，通过扩展存储节点。





## 2. 准备工作

1、准备`4台`CentOS 虚拟机

2、每台虚拟机上需要安装好MySQL (可以是MySQL8.0 或者 MySQL5.7 皆可)

大家可以在一台CentOS上安装好MySQL，进而通过克隆的方式复制出3台包含MySQL的虚拟机。

注意：克隆的方式需要修改新克隆出来主机的：

```bash
vim /etc/sysconfig/network-scripts/ifcfg-ens33
```

① `MAC地址` 

② `hostname`  

```bash
vim /etc/hostname
```

③ `IP 地址`  

④ `UUID`。

MySQL修改时区

```bash
vim /etc/my.cnf

#添加配置项
default-time_zone='+8:00'
```

此外，克隆的方式生成的虚拟机（包含MySQL Server），则克隆的虚拟机MySQL Server的UUID相同，必须修改，否则在有些场景会报错。修改MySQL Server 的UUID方式：

```
vim /var/lib/mysql/auto.cnf

systemctl restart mysqld
```





## 3. 安装启动

### 1. 安装步骤

解压缩文件拷贝到linux下 `/usr/local/`

```bash
#下载对应的tar安装包,以及对应的jar包 
wget http://dl.mycat.org.cn/2.0/install-template/mycat2-install-template-1.21.zip

unzip -d /usr/local mycat2-install-template-1.21.zip

#jar包
下载地址：http://dl.mycat.org.cn/2.0/1.21-release/

#jar 放到lib目录
cp jar包 /usr/local/mycat/lib/

#授权
chmod +x /usr/local/mycat/bin/*
```

打开mycat目录结构如下：

- `bin`：二进制执行文件
- `conf`：配置文件目录
- `lib`：依赖
- `logs`：日志



### 2.  创建MySQL用户

mycat 用户用于mycat服务器连接MySQL使用，可以直接用root也行，不过需要修改root用户的host为允许访问的IP，如如下所示：(`%`表示允许所有IP用户访问)

```sql
mysql> select host,user from mysql.user;
+-----------+------------------+
| host      | user             |
+-----------+------------------+
| %         | mycat            | # mycat用户
| %         | root             |
| %         | slave            | # 主从配置中用于从服务器与主服务器同步用户
| localhost | mysql.infoschema |
| localhost | mysql.session    |
| localhost | mysql.sys        |
+-----------+------------------+
6 rows in set (0.01 sec)
```

```sql
CREATE USER 'mycat'@'%' IDENTIFIED BY '123456';

GRANT ALL PRIVILEGES ON *.* TO 'mycat'@'%';

# 8.0版本需要授予此权限，5.6无此权限
GRANT XA_RECOVER_ADMIN ON *.* TO 'root'@'%';

flush privileges;
```



### 3. 配置默认数据源

由于是第一次使用，有些默认数据源对我们来说并不需要，因此可以删除，可以删除的文件如下：

```bash
vim /usr/local/mycat/conf/datasources/prototypeDs.datasource.json
```

```json
{
    "dbType": "mysql",
    "idleTimeout": 60000,
    "initSqls": [],
    "initSqlsGetConnection": true,
    "instanceType": "READ_WRITE",
    "maxCon": 1000,
    "maxConnectTimeout": 3000,
    "maxRetryCount": 5,
    "minCon": 1,
    "name": "prototype",  //  数据源名称
    "password": "123456", //  数据库用户密码
    "type": "JDBC",
    "url": "jdbc:mysql://IP:3306/mysql?useUnicode=true&serverTimezone=UTC",
    "user": "mycat",      // 数据库用户
    "weight": 0,
    "queryTimeout":30,	  // mills
}
```

> 注意：
>
> 这里的数据库用户是用于存放Mycat中间件信息的库，与我们要搭建的集群基本没有关系，只是起到保存Mycat服务信息的作用。



### 4. 配置mycat用户

mycat服务器启动之后，连接mycat服务器使用的用户，`{用户名}.user.json`放在users文件夹下。

默认情况下，安装完成后会有root用户，后续讲解如何创建新用户。

```bash
vim /usr/local/mycat/conf/users/root.user.json
```

```json
{
    "dialect":"mysql",
    "ip":".",			 // 允许访问该用户的IP地址
    "password":"123456", // 登录密码
    "transactionType":"xa",
    "username":"root"    // 用户名
    "isolation":3        // 事务隔离级别
}
```

- **`isolation`**

  设置初始化的事务隔离级别

  - `READ_UNCOMMITTED` ：1
  - `READ_COMMITTED` ：2
  - `REPEATED_READ` ：3，默认
  - `SERIALIZABLE` ：4

- **`transactionType`**

  - `proxy` ：本地事务，在涉及大于1个数据库的事务，commit阶段失败会导致不一致，但是兼容性最好（`默认`）
  - `xa` ：事务，需要确认存储节点集群类型是否支持XA

  事务类型在开启自动提交而且没有事务的时候可以使用以下语句实现切换

  ```sql
  set transaction_policy = 'xa'
  
  set transaction_policy = 'proxy'
  
  # 可以查询当前事务类型
  SELECT @@transaction_policy
  ```

  无论哪种方式，应用代码编写都应该符合以下形式，连接中设置查询超时

  ```java
  Connection con = getConnection();
  try{
      start transcation;
  
      commit/rollback;
  }catche(Exception e){
      rollback;//显式触发回滚
  }finally{
      con.close();
  }
  
  Connection con = getConnection();
  try{
      set autocommit = 0;
  
      commit/rollback;
  }catche(Exception e){
      rollback;//显式触发回滚
  }finally{
      con.close();
      //set autocommit = 1;//连接池隐式设置
  }
  ```



### 5. 启动mycat服务

启动方式如下图：

![](https://gitlab.com/eardh/picture/-/raw/main/mysql_img/202203311539059.png)

- `Linux命令启动`

  ```bash
  /usr/local/mycat/bin/mycat 命令
  
  命令：
  	- start		启动
  	- status    查看启动状态
  	- start 	启动
  	- stop 		停止
  	- console 	前台运行
  	- install 	添加到系统自动启动（暂未实现）
  	- remove 	取消随系统自动启动（暂未实现）
  	- restart 	重启服务
  	- pause 	暂停
  ```

- `jar 包启动`

   ```bash
   java -Dfile.encoding=UTF-8 -DMYCAT_HOME=/usr/local/mycat/conf -jar /usr/local/mycat/lib/xxx.jar &
   ```

  - `-DMYCAT_HOME` ：mycat安装目录里的配置文件所在目录，完整路径
  - `xxx.jar` ：在[前面](#1. 安装步骤)里下载的`jar`包文件，完整路径
  - `&` ：关闭窗口后仍可在后台运行，不加则窗口退出程序停止运行

启动完成过后，查看是否启动成功（针对`Linux命令启动`）

```bash
ps -ef | grep mycat
```

```bash
tail -n 100 /usr/local/mycat/logs/wrapper.log
```

**日志内容如下，表示启动成功**

![](https://gitlab.com/eardh/picture/-/raw/main/mysql_img/202203311539976.png)





## 4. 主从复制原理

关于主从复制可以阅读[MySQL主从复制](https://gitee.com/eardh/java-trace/blob/master/mysql/2_%E9%AB%98%E7%BA%A7%E7%AF%87/18_%E4%B8%BB%E4%BB%8E%E5%A4%8D%E5%88%B6.md)。

我们通过Mycat和MySQL的主从复制配合搭建数据库的读写分离，实现MySQL的高可用性。

**1. 主从复制原理**

![](https://gitlab.com/eardh/picture/-/raw/main/mysql_img/202203311539009.jpg)

提到主从同步的原理，我们就需要了解在数据库中的一个重要日志文件，那就是 Binlog 二进制日志，它记录了对数据库进行更新的事件。实际上主从同步的原理就是基于 Binlog 进行数据同步的。在主从复制过程中，会基于 3 个线程来操作，一个`主库线程`，两个`从库线程`。 

`二进制日志转储线程（Binlog dump thread）`是一个主库线程。当从库线程连接的时候， 主库可以将二进制日志发送给从库，当主库读取事件的时候，会在 `Binlog 上加锁`，读取完成之后，再将锁释放掉。 

`从库 I/O 线程`会连接到主库，向主库发送请求更新 Binlog。这时从库的 I/O 线程就可以读取到主库的二进制日志转储线程发送的 `Binlog 更新部分`，并且拷贝到本地形成`中继日志 （Relay log）`。 

`从库 SQL 线程`会读取从库中的中继日志，并且`执行日志中的事件`，从而将从库中的数据与主库保持`同步`。

![](https://gitlab.com/eardh/picture/-/raw/main/mysql_img/202203311540046.png)

所以你能看到主从同步的内容就是二进制日志（Binlog），它虽然叫二进制日志，实际上存储的是一个又一个`事件（Event）`，这些事件分别对应着数据库的更新操作，比如 `INSERT`、`UPDATE`、`DELETE `等。另外我们还需要注意的是，不是所有版本的 MySQL 都默认开启服务器的二进制日志，在进行主从同步的时候，我们需要先检查服务器`是否已经开启了二进制日志`。

从服务器通过配置可以读取主服务器中二进制日志，并且执行日志中的事件。每个从服务器都能收到整个二进制日志的内容。从服务器需要识别日志中哪些语句应该被执行。除非特殊指定，`默认情况下主服务器中所有的事件都将被执行`。

**2. MySQL复制三步骤**

1. `Master`将写操作记录到二进制日志（`binlog`）。这些记录过程叫做**二进制日志事件**(binary log events)；
2. `Slave`将`Master`的binary log  events拷贝到它的中继日志（`relay log`）；
3. `Slave`重做中继日志中的事件，将改变应用到自己的数据库中。 MySQL复制是异步的且串行化的，而且重启后从接入点开始复制。

**3. 复制的问题**

复制的最大问题：**延时**

**4. 复制的基本原则**

- 每个`Slave`只有一个`Master`

- 每个`Slave`只能有一个唯一的服务器ID

- 每个`Master`可以有多个`Slave`





## 5. 主从复制与读写分离实现

### 1. 搭建主从复制

#### 1. 服务器准备

准备四台服务器，并安装MySQL

| 编号 |   主机名   |       IP        |
| :--: | :--------: | :-------------: |
|  1   | CentOS7-h1 | 192.168.111.129 |
|  2   | CentOS7-h2 | 192.168.111.130 |
|  3   | CentOS7-h3 | 192.168.111.131 |
|  4   | CentOS7-h4 | 192.168.111.132 |

一个主机 CentOS7-h1 用于处理所有写请求，它的从机 CentOS7-h2 和另一台主机 CentOS7-h3 还有它的从机 CentOS7-h4 负责所有读请求。当 CentOS7-h1 主机宕机后，CentOS7-h3 主机负责写请求，CentOS7-h1、CentOS7-h3 互为备机。架构图如下：

![](https://gitlab.com/eardh/picture/-/raw/main/mysql_img/202203311540804.png)

![](https://gitlab.com/eardh/picture/-/raw/main/mysql_img/202203311540183.jpg)



#### 2. 主机配置

修改配置文件：`vim /etc/my.cnf`

**1、CentOS7-h1 配置**

```properties
#【必须】主服务器唯一ID
server-id=1

#【必须】启用二进制日志
log-bin=mysql-bin

#设置不要复制的数据库(可设置多个)
binlog-ignore-db=mysql,information_schema,sys,performance_schema

#【必须】设置需要复制的数据库
#binlog-do-db=需要复制的主数据库名字

#设置logbin格式
binlog_format=STATEMENT

#【必须】在作为从数据库的时候，有写入操作也要更新二进制日志文件
log-slave-updates 

#【必须】表示自增长字段每次递增的量，指自增字段的起始值，其默认值是1，取值范围是1 .. 65535
auto-increment-increment=2 

#【必须】表示自增长字段从哪个数开始，指字段一次递增多少，他的取值范围是1 .. 65535
auto-increment-offset=1
```

**2、CentOS7-h3 配置**

```properties
#【必须】主服务器唯一ID
server-id=3

#【必须】启用二进制日志
log-bin=mysql-bin

#设置不要复制的数据库(可设置多个)
binlog-ignore-db=mysql,information_schema,sys,performance_schema

#【必须】设置需要复制的数据库
#binlog-do-db=需要复制的主数据库名字

#设置logbin格式
binlog_format=STATEMENT

#【必须】在作为从数据库的时候，有写入操作也要更新二进制日志文件
log-slave-updates 

#【必须】表示自增长字段每次递增的量，指自增字段的起始值，其默认值是1，取值范围是1 .. 65535
auto-increment-increment=2 

#【必须】表示自增长字段从哪个数开始，指字段一次递增多少，他的取值范围是1 .. 65535
auto-increment-offset=2
```

binlog日志三种格式：

- `STATEMENT模式`（基于SQL语句的复制(statement-based replication, SBR)）

  ```
  binlog_format=STATEMENT
  ```

  每一条会修改数据的sql语句会记录到 binlog 中。这是默认的binlog格式。

  优点：binlog 文件较小，binlog 可以用于实时的还原，而不仅仅用于复制。

  缺点：使用以下函数的语句也无法被复制：`LOAD_FILE()、UUID()、USER()、FOUND_ROWS()、SYSDATE()` (除非启动时启用了 `--sysdate-is-now` 选项)。数据表必须几乎和主服务器保持一致才行，否则可能会导致复制出错。

- `ROW模式`（基于行的复制(row-based replication, RBR)）

  ```
  binlog_format=ROW
  ```

  不记录每条sql语句的上下文信息，仅需记录哪条数据被修改了，修改成什么样了。

  优点：任何情况都可以被复制，这对复制来说是最安全可靠的。

  缺点：binlog 大了很多。无法从 binlog 中看到都复制了写什么语句。

- `MIXED模式`（混合模式复制(mixed-based replication, MBR)）

  ```
  binlog_format=MIXED
  ```

  以上两种模式的混合使用。


![](https://gitlab.com/eardh/picture/-/raw/main/mysql_img/202203311540592.jpg)



#### 3. 从机配置

**1、CentOS7-h2 配置**

```properties
#【必须】从服务器唯一ID
server-id=2

#【必须】启用中继日志
relay-log=mysql-relay
```

**2、CentOS7-h4 配置**

```properties
#【必须】从服务器唯一ID
server-id=4

#【必须】启用中继日志
relay-log=mysql-relay
```



#### 4. 重启MySQL服务

```bash
systemctl restart mysqld

systemctl status mysqld
```



#### 5. 检查防火墙

关闭防火墙或开放端口号：

- **关闭防火墙**

  ```bash
  systemctl start firewalld.service
  
  systemctl status firewalld.service
  
  systemctl stop firewalld.service
  
  #设置开机启用防火墙
  systemctl enable firewalld.service
  
  #设置开机禁用防火墙
  systemctl disable firewalld.service
  ```

- **开放端口号**

  - 查看开放的端口号

    ```sql
    firewall-cmd --list-all
    ```

  - 设置开放的端口号

    ```sql
    firewall-cmd --add-port=3306/tcp --permanent
    ```

  - 重启防火墙

    ```sql
    firewall-cmd --reload
    ```



#### 6. 主机创建账户并授权

- MySQL5

  ```sql
  #在主机MySQL里执行授权主从复制的命令
  GRANT REPLICATION SLAVE ON *.* TO 'slave'@'%' IDENTIFIED BY '123456';
  ```

- MySQL8

  ```sql
  create user 'slave'@'%' identified by '123456';
  
  # 授予此权限，复制才能真正工作。
  GRANT REPLICATION SLAVE ON *.* TO slave@'%';
  
  # MySQL8.0 之后由于密码安全，需要执行下面操作
  ALTER USER 'slave'@'%' IDENTIFIED WITH mysql_native_password BY '123456';
  
  flush privileges;
  ```



#### 7. 从机数据复制配置

**1、查询主机的master状态：**

```sql
show master status; #查看当前最新的一个binlog日志的编号名称，及最后一个事件结束的位置

# 下面不需要执行，用于再次搭建时充重置操作
reset master;
```

- 记录下File和Position的值

> 注意：执行完此步骤后不要再操作主服务器MySQL，防止主服务器状态值变化

**2、从机复制主机**

```sql
CHANGE MASTER TO MASTER_HOST='192.168.111.129',
MASTER_USER='slave',
MASTER_PASSWORD='123456',
MASTER_LOG_FILE='mysql-bin.000001',MASTER_LOG_POS=157;
```



```sql
CHANGE MASTER TO MASTER_HOST='主机IP地址',
MASTER_USER='slave',
MASTER_PASSWORD='123456',
MASTER_LOG_FILE='File',MASTER_LOG_POS=Position;
```

- MASTER_HOST ：主机IP地址
- MASTER_USER ：主机创建的主从复制用户
- MASTER_LOG_FILE ：第一步得到的File文件名
- Position ：第一步得到的Position

**3、启动复制**

```sql
#启动主从复制
start slave;

#查看主从复制状态
show slave status\G;

#删除之前的中继日志信息
reset slave;
```

`show slave status`下面两个参数都是Yes，则说明主从配置成功！

```
Slave_IO_Running: Yes
Slave_SQL_Running: Yes
```

显式如下的情况，就是不正确的。可能错误的原因有：

```
1. 网络不通
2. 账户密码错误
3. 防火墙
4. mysql配置文件问题
5. 连接服务器时语法
6. 主服务器mysql权限
```



#### 8. 两个主服务器互相复制

两台主机互相复制，如上面的从机复制配置相同。

- CentOS7-h1 复制 CentOS7-h3
- CentOS7-h3 复制 CentOS7-h1



#### 9.  主从复制测试

两台主机分别创建数据库，查看四台服务器是否数据一致。

分别在两台主服务器中的一台执行下面操作，观察其他三台的情况

```mysql
#创建数据库
create database dbtest;

#创建表
create table student (
    id int primary key,
    name varchar(20)
);

#插入数据
insert into student(id, name) values(1, '张三'), (2, '李四'), (3, @@hostname);
```

出现如下结果，说明双主双从配置成功：

```sql
# CentOS7-h1服务器
mysql> select * from student;
+----+------------+
| id | name       |
+----+------------+
|  1 | 张三       |
|  2 | 李四       |
|  3 | centos7-h1 |
+----+------------+
3 rows in set (0.00 sec)
```

```sql
# CentOS7-h2服务器
mysql> select * from student;
+----+------------+
| id | name       |
+----+------------+
|  1 | 张三       |
|  2 | 李四       |
|  3 | centos7-h2 |
+----+------------+
3 rows in set (0.00 sec)
```

```sql
# CentOS7-h3服务器
mysql> select * from student;
+----+------------+
| id | name       |
+----+------------+
|  1 | 张三       |
|  2 | 李四       |
|  3 | centos7-h3 |
+----+------------+
3 rows in set (0.00 sec)
```

```sql
# CentOS7-h4服务器
mysql> select * from student;
+----+------------+
| id | name       |
+----+------------+
|  1 | 张三       |
|  2 | 李四       |
|  3 | centos7-h4 |
+----+------------+
3 rows in set (0.00 sec)
```





### 2. 搭建读写分离

首先在任何一台主机上安装并启动Mycat服务，[具体过程](#3. 安装启动)在上面。



#### 1. 登录Mycat服务器

 ```bash
 mysql -u mycat用户名 -p -h mycat服务器IP地址 -P 8066
 ```



#### 2. 创建数据库用户

为每台服务器创建用于Mycat管理的用户，操作和[前面](#2.  创建MySQL用户)一样。

|    主机    | 用户名 |  密码  |
| :--------: | :----: | :----: |
| CentOS7-h1 | mycat  | 123456 |
| CentOS7-h2 | mycat  | 123456 |
| CentOS7-h3 | mycat  | 123456 |
| CentOS7-h4 | mycat  | 123456 |



#### 3. 创建数据源

数据源配置文件在`/usr/local/mycat/conf/datasources/`目录下，其中可配置的选项说明如下

```json
{
    "dbType": "mysql",
    "idleTimeout": 60000,
    "initSqls": [],
    "initSqlsGetConnection": true,
    "instanceType": "READ_WRITE",
    "maxCon": 1000,
    "maxConnectTimeout": 3000,
    "maxRetryCount": 5,
    "minCon": 1,
    "name": "prototype",  //  数据源名称
    "password": "123456", //  下面的 user 数据库用户密码
    "type": "JDBC",
    "url": "jdbc:mysql://IP:3306/mysql?useUnicode=true&serverTimezone=UTC",
    "user": "mycat",      // 数据库用户
    "weight": 0,
    "queryTimeout":30,	  // mills
}
```

- **`jdbc:mysql://IP:3306/mysql?useUnicode=true&serverTimezone=UTC`**

  此处mysql要改成业务库，业务库不能被binlog等忽略，不填则表示所有库

- **`prototype.datasource.json`**

  `{数据源名字}.datasource.json` 保存在datasources文件夹

- **`maxConnectTimeout`**

  单位millis,配置中的定时器主要作用是定时检查闲置连接

- **`initSqlsGetConnection`**

  `true | false`，默认：false，对于jdbc每次获取连接是否都执行`initSqls`

- **`type`**

  数据源类型 ：

  - `NATIVE`，只使用NATIVE协议(即Mycat自研的连接MySQL的协议)
  - `JDBC`，默认，只使用JDBC驱动连接
  - `NATIVE_JDBC`，该数据源同一个配置同时可以使用NATIVE，JDBC

- **`queryTimeout`**

  jdbc查询超时时间 默认不超时(1.20，以及早期1.21默认30mills)

- **`instanceType`**

  配置实例只读还是读写，可选值`READ_WRITE，READ，WRITE`

  > 在集群中，是`READ_WRITE`的类型，被设置到`replicas`，对该集群是`READ`的，但是它也被设置到`masters`则为READ_WRITE

- **`weight`**

  负载均衡特定用的权重

登录mycat服务成功后，即可**创建数据源**，函数如下：

```sql
# 创建数据源
/*+ mycat:createDataSource{
	"dbType":"mysql",
	"idleTimeout":60000,
	"initSqls":[],
	"initSqlsGetConnection":true,
	"instanceType":"READ_WRITE",
	"maxCon":1000,
	"maxConnectTimeout":3000,
	"maxRetryCount":5,
	"minCon":1,
	"name":"数据源名称",
	"password":"数据库用户密码",
	"type":"JDBC",
	"url":"jdbc:mysql://IP:3306?useUnicode=true&serverTimezone=UTC&characterEncoding=UTF-8",
	"user":"数据库用户",
	"weight":0
} */;
```

调用成功后会在 `/usr/local/mycat/conf/datasources/` 目录下生成`{数据源名字}.datasource.json`文件。

**其他操作**：

```sql
#查询已配置数据源
/*+ mycat:showDataSources{} */\G;


#删除数据源
/*+ mycat:dropDataSource{
	"name":"prototypeDs"
} */;
```

|    主机    | 数据源名 |
| :--------: | :------: |
| CentOS7-h1 |   dw0    |
| CentOS7-h2 |   dr0    |
| CentOS7-h3 |   dw1    |
| CentOS7-h4 |   dr1    |



#### 4. 创建集群

**创建集群**： 

```sql
#创建集群
/*! mycat:createCluster{
	"clusterType":"MASTER_SLAVE",
	"heartbeat":{
		"heartbeatTimeout":1000,
		"maxRetryCount":3,
		"minSwitchTimeInterval":300,
		"slaveThreshold":0
	},
	"masters":[
		"dw0","dw1" //主节点
	],
	"maxCon":2000,
	"name":"c0",
	"readBalanceType":"BALANCE_ALL",
	"replicas":[
		"dr0","dr1" //从节点
	],
	"switchType":"SWITCH",
    "timer":{
        "initialDelay": 30,
        "period":5,
        "timeUnit":"SECONDS"
    },
} */;
```

创建成功后会在`/usr/local/mycat/conf/clusters`目录下生成`{集群名字}.cluster.json`文件。

**其他操作**：

```sql
#查看已创建的集群
/*+ mycat:showClusters{} */;


#删除集群
/*! mycat:dropCluster{
	"name":"集群名"
} */;
```

`{集群名字}.cluster.json`文件详细信息如下：

```json
{
    "clusterType":"MASTER_SLAVE",
    "heartbeat":{
        "heartbeatTimeout":1000,
        "maxRetryCount":3,//2021-6-4前是maxRetry，后更正为maxRetryCount
        "minSwitchTimeInterval":300,
        "slaveThreshold":0
    },
    "masters":[ // 配置多个主节点,在主挂的时候会选一个检测存活的数据源作为主节点
        "prototypeDs"
    ],
    "replicas":[ // 配置多个从节点
        "xxxx"
    ],
    "maxCon":200,
    "name":"prototype",
    "readBalanceType":"BALANCE_ALL",
    "switchType":"SWITCH"

    ////////////////////////////////////可选//////////////////////////////////
    ,
    "timer":{ //MySQL集群心跳周期,配置则开启集群心跳,Mycat主动检测主从延迟以及高可用主从切换
        "initialDelay": 30,
        "period":5,
        "timeUnit":"SECONDS"
    },
    //readBalanceName:"BALANCE_ALL",
    //writeBalanceName:"BALANCE_ALL",
}
```

- **`clusterType`**

  - `SINGLE_NODE` ：单一节点
  - `MASTER_SLAVE` ：普通主从
  - `GARELA_CLUSTER` ：garela cluster/PXC集群
  - `MHA` ：1.21-2022年1月完善
  - `MGR` ：1.21-2022年1月完善，MIC集群可以使用此配置

  MHA与MGR集群会在心跳过程中根据`READ_ONLY`状态判断当前节点是否从节点(READ_ONLY=ON)，主节点(`READ_ONLY=OFF`)动态更新主从节点信息，这样可以支持多主 、单主。但是实际上生产上建议暂时使用单主模式，或者多主作为单主使用

- **`readBalanceType`**  ：查询负载均衡策略，可选值：
  - `BALANCE_ALL(默认值)` ：获取集群中所有数据源
  - `BALANCE_ALL_READ` ：获取集群中允许读的数据源
  - `BALANCE_READ_WRITE` ：获取集群中允许读写的数据源,但允许读的数据源优先
  - `BALANCE_NONE` ：获取集群中允许写数据源,即主节点中选择

- **`switchType`**
  - `NOT_SWITCH` ：不进行主从切换
  - `SWITCH` ：进行主从切换

- **`readBalanceName与writeBalanceName`** ：配置负载均衡策略，默认值是BalanceRandom
  - `BalanceLeastActive` ：最少正在使用的连接数的mysql数据源被选中，如果连接数相同,则从连接数相同的数据源中的随机，使慢的机器收到更少。
  - `BalanceRandom` ：利用随机算法产生随机数，然后从活跃的mysql数据源中进行选取。
  - `BalanceRoundRobin` ：加权轮训算法，记录轮训的权值，每次访问加一，得到n，然后对mysql数据源进行轮训，如果权值已经为零，则跳过，如果非零则减一，n减1，直n为零则选中的节点就是需要访问的mysql数据源节点。
  - `BalanceRunOnReplica` ：io.mycat.plug.loadBalance.BalanceRunOnReplica 把请求尽量发往从节点,不会把请求发到不可读(根据延迟值判断)与不可用的从节点



#### 5. 创建物理库物理表

在双主中选择其中一个来创建物理库和物理表：

```sql
#创建数据库
create database mycluster;

use mycluster;

#创建表
create table student (
    id int primary key,
    name varchar(20)
);
```



#### 6. 创建逻辑库逻辑表

```sql
# 创建逻辑库
/*+ mycat:createSchema{
	"customTables":{},
	"globalTables":{},
	"normalTables":{},
	"schemaName":"逻辑库名",
	"shardingTables":{}
} */;
```

创建成功后会在路径`/usr/local/mycat/conf/schemas/`产生`{库名}.schema.json`文件 。

```sql
#删除逻辑库
/*+ mycat:dropSchema{
	"schemaName":"catcluster",
} */;

或

drop database schemaName;
```

接下来创建逻辑表：

 ```sql
 /*+ mycat:createTable{
 	"normalTable":{
         "createTableSQL":null,
 		"locality":{
 			"schemaName":"testSchema", //物理库
 			"tableName":"normal", //物理表
 			"targetName":"prototype" //目标
 		}
 	},
 	"schemaName":"testSchema",//逻辑库
 	"tableName":"normal" //逻辑表
 } */;
 ```

```sql
#删除逻辑表
/*+ mycat:createTable{
	"schemaName":"testSchema",//逻辑库
	"tableName":"normal" //逻辑表
} */;
```



#### 5. 读写分离测试

```sql
user catcluster;

insert into student(id, name) values(1, '张三'), (2, '李四'), (3, @@hostname);
```

利用`/*+ mycat:showInstances{}*/`查看实例状态：

![](https://gitlab.com/eardh/picture/-/raw/main/mysql_img/202203311540930.png)

**测试结果如下，如果相同查询查出的 hostname 来自不同主机，说明读写分离成功**

```sql
mysql> select * from student;
+----+------------+
| id | name       |
+----+------------+
|  1 | 张三       |
|  2 | 李四       |
|  3 | centos7-h4 |
+----+------------+
3 rows in set (0.12 sec)

mysql> select * from student;
+----+------------+
| id | name       |
+----+------------+
|  1 | 张三       |
|  2 | 李四       |
|  3 | centos7-h2 |
+----+------------+
3 rows in set (0.09 sec)

mysql> select * from student;
+----+------------+
| id | name       |
+----+------------+
|  1 | 张三       |
|  2 | 李四       |
|  3 | centos7-h1 |
+----+------------+
3 rows in set (0.04 sec)
```

那主备切换是否可以实现呢？

接下来我们把 `CentOS7-h1` 关闭 MySQL 服务，查看是否切换成功，之后再次查看实例状态，

 ```sql
 # 显示实例状态
 /*+ mycat:showInstances{}*/
 ```

![](https://gitlab.com/eardh/picture/-/raw/main/mysql_img/202203311541115.png)

可以看到`MASTER`已经从`dw0`切换到`dw1`。

之后我们再次插入数据：

```sql
insert into student(id, name) values(4, '孙子');
```

 启动`CentOS7-h1`的MySQL服务。

可以看到刚刚插入的数据再次写入MySQL的`mycluster.student`里面。

![](https://gitlab.com/eardh/picture/-/raw/main/mysql_img/202203311541699.png)





## 6. Mycat数据分片

### 1. 什么是数据分片？

简单来说，就是指通过某种特定的条件，将我们存放在同一个数据库中的数据分散存放到多个数据库（主机）上面，以达到分散单台设备负载的效果。



### 2. 切分模式

数据的切分（Sharding）根据其切分规则的类型，可以分为两种切分模式：

**1. 垂直（纵向）切分**：是按照不同的表（或者 Schema）来切分到不同的数据库（主机）之上

**2. 水平（横向）切分**：是根据表中的数据的逻辑关系，将同一个表中的数据按照某种条件拆分到多台数据库（主机）上面。



### 3. Mycat分片原理

MyCat的分片实现：

 ![](https://gitlab.com/eardh/picture/-/raw/main/mysql_img/202203311541124.png)

**逻辑库(schema) ：**MyCat作为一个数据库中间件，起到一个程序与数据库的桥梁作用。开发人员无需知道MyCat的存在，只需要知道数据库的概念即可。为了让MyCat更透明，它会把自己“伪装”成一个MySQL数据库，因此需要有一个虚拟的 database，在MyCat中也叫逻辑库，英文就是schema。

**逻辑表（table）：**既然有逻辑库，那么就会有逻辑表，分布式数据库中，对应用来说，读写数据的表就是逻辑表。逻辑表，可以是数据切分后，分布在一个或多个分片库中，也可以不做数据切分，不分片，只有一个表构成。

**分片节点(dataNode)：**数据切分后，一个大表被分到不同的分片数据库上面，每个表分片所在的数据库就是分片节点（dataNode）。

**节点主机(dataHost)：**数据切分后，每个分片节点（dataNode）不一定都会独占一台机器，同一机器上面可以有多个分片数据库，这样一个或多个分片节点（dataNode）所在的机器就是节点主机（dataHost）,为了规避单节点主机并发数限制，尽量将读写压力高的分片节点（dataNode）均衡的放在不同的节点主机（dataHost）。

**分片规则(rule)：**前面讲了数据切分，一个大表被分成若干个分片表，就需要一定的规则，这样按照某种业务规则把数据分到某个分片的规则就是分片规则，数据切分选择合适的分片规则非常重要，将极大的避免后续数据处理的难度。





## 7. 垂直拆分——分库

一个数据库由很多表构成，每个表对应着不同的业务，垂直拆分是指按照业务将表进行分类，分布到不同的数据库上面，这样也就将数据或者说压力分担到不同的库上面，如下图：

![](https://gitlab.com/eardh/picture/-/raw/main/mysql_img/202203311541459.png)

![](https://gitlab.com/eardh/picture/-/raw/main/mysql_img/202203311541366.png)

系统被拆分成了：用户、订单交易、支付几个模块。

> 【推荐】单表行数超过 500 万行或者单表容量超过 2GB，才推荐进行分库分表。 
>
> 说明：如果预计三年后的数据量根本达不到这个级别，请不要在创建表时就分库分表。
>
> 来源：阿里巴巴《Java开发手册》





### 1.  环境准备

**1. 删除集群**

```json
# 删除集群
/*! mycat:dropCluster{
	"name":"c0"
} */;
```

**2. 删除逻辑库**

```sql
drop database catcluster;
```

**3. 删除物理库**

```sql
drop database mycluster;
```

**4. 双主除数据复制**

即在两个MySQL的 master 之间切断复制关系。并去除主从之间的数据复制关系。

这里选择下面主机作为测试机。

| 编号 |   主机名   |       IP        |
| :--: | :--------: | :-------------: |
|  1   | CentOS7-h1 | 192.168.111.129 |
|  3   | CentOS7-h3 | 192.168.111.131 |

由于只需要的主机，所以可以把`dr0`、`dr1`删除，避免对结果有影响。重启Mycat服务。



### 2. 主从集群

创建一主一从集群，[创建集群详解](#4. 创建集群)。

|     主     |     从     |
| :--------: | :--------: |
| centos7-h1 | centos7-h2 |
| centos7-h3 | centos7-h4 |



### 3. 创建逻辑库逻辑表

```json
# 创建逻辑库
/*+ mycat:createSchema{
	"customTables":{},
	"globalTables":{},
	"normalTables":{},
	"schemaName":"school",
	"shardingTables":{}
} */;
```

```sql
/*+ mycat:createTable{
	"normalTable":{
        "createTableSQL": "create table student (
    id int primary key auto_increment,
    name varchar(20),
    savor varchar(50)
) engine=innodb default charset=utf8;",
		"locality":{
			"schemaName":"school_0", //物理库
			"tableName":"student", //物理表
			"targetName":"c0" //目标
		}
	},
	"schemaName":"school",//逻辑库
	"tableName":"student" //逻辑表
} */;
```

```sql
/*+ mycat:createTable{
	"normalTable":{
        "createTableSQL":"create table teacher (
    id int primary key auto_increment,
    name varchar(20),
    subject varchar(50)
) engine=innodb default charset=utf8;",
		"locality":{
			"schemaName":"school_1", //物理库
			"tableName":"teacher", //物理表
			"targetName":"c1" //目标
		}
	},
	"schemaName":"school",//逻辑库
	"tableName":"teacher" //逻辑表
} */;
```

逻辑表创建成功后会在相应的MySQL服务器中创建对应的物理表和物理库。如图所示：

![](https://gitlab.com/eardh/picture/-/raw/main/mysql_img/202203311541726.png)





### 4. 分库测试

登录mycat服务器，步骤操作：

 ```sql
 #1、选择逻辑库
 use school
 
 
 #2、查看逻辑表
 mysql> show tables;
 +------------------+
 | Tables_in_school |
 +------------------+
 | student          |
 | teacher          |
 +------------------+
 2 rows in set (0.01 sec)
 
 
 #3、向两个表分别插入数据
 insert into student(name, savor) values('张三','喝酒'),('武松','大虎');
 insert into teacher(name, subject) values('李白','语文'),('孔子','哲学');
 ```

在`CentOS7-h1`中查询`school_0.student`表中结果如下：

```sql
mysql> select * from student;
+----+--------+--------+
| id | name   | savor  |
+----+--------+--------+
|  1 | 张三   | 喝酒   |
|  2 | 武松   | 大虎   |
+----+--------+--------+
2 rows in set (0.00 sec)
```

在`CentOS7-h3`中查询`school_1.teacher`表中结果如下：

```sql
mysql> select * from teacher;
+----+--------+---------+
| id | name   | subject |
+----+--------+---------+
|  1 | 李白   | 语文    |
|  2 | 孔子   | 哲学    |
+----+--------+---------+
2 rows in set (0.00 sec)
```





## 8. 水平拆分——分表

相对于垂直拆分，水平拆分不是将表做分类，而是按照某个字段的某种规则来分散到多个库之中，每个表中包含一部分数据。简单来说，我们可以将数据的水平切分`理解为是按照数据行的切分`，就是将表中的某些行切分到一个数据库，而另外的某些行又切分到其他的数据库中，如图： 

![](https://gitlab.com/eardh/picture/-/raw/main/mysql_img/202203311541285.png)

 

### 1. 拆分的表

MySQL单表存储数据条数是有瓶颈的，单表达到`1000万条`数据就达到了瓶颈，会影响查询效率，需要进行水平拆分（分表）进行优化。

假如现在我们需要加入一张签到记录表，里面记录了学生id、签到id，签到时间等信息，那么随着签到的增长，该数据库必然会导致数据瓶颈，所以我们需要对其进行分表处理，签到表如下：

```sql
create table sign_record (
    id int primary key auto_increment,
    student_id int not null,
    sign_id int not null,
    record_time datetime
) engine=innodb default charset=utf8;
```



### 2. 分表字段

| 编号 | 分表字段             | 效果                                                         |
| ---- | -------------------- | ------------------------------------------------------------ |
| 1    | id（主键）、签到时间 | 查询签到注重时效，历史签到被查询的次数少，如此分片会造成一个节点访问多，一个访问少，不平均。 |
| 2    | student_id（学生id） | 学生id字段作为依据确实可以使节点访问少，不过如果老师要查签到情况的话不太有利，因为学生学号太分散。 |
| 3    | sign_id（签到id）    | 这个也可以使老师查询时访问的节点最少，然而学生查询时却又需访问更多节点。 |



### 3. 创建逻辑表

```json
 /*+ mycat:createTable{
  "schemaName":"school",
  "autoIncrement": false,
  "shardingTable":{
		"createTableSQL":"create table record (
                            id int primary key auto_increment,
                            student_id int not null,
                            sign_id int not null,
                            record_time datetime
                        ) engine=innodb default charset=utf8 dbpartition by MOD_HASH (sign_id) dbpartitions 1 tbpartition by MOD_HASH (sign_id) tbpartitions 4;",
        "function":{
                "properties":{
                  "dbNum":1,
                  "mappingFormat":"c0/school_0/sign_record_${index}",
                  "tableNum":4,
                  "tableMethod":"mod_hash(sign_id)",
                  "storeNum":1,
                  "dbMethod":"mod_hash(sign_id)"
              }
            },
        "partition":{}
      },
  "tableName":"sign_record"
} */;
```

- `MOD_HASH(HASH)`

  如果分片值是字符串则先对字符串进行hash转换为数值类型

  分库键和分表键是同键

  - 分表下标=分片值%(分库数量*分表数量)
  - 分库下标=分表下标/分表数量

  分库键和分表键是不同键

  - 分表下标= 分片值%分表数量
  - 分库下标=分表下标%分库数量

更多分片算法看[分片算法](https://www.yuque.com/ccazhw/ml3nkf/tg2dn7)。

逻辑表创建成功会在CentOS7-h1MySQL服务器生成如下表：

![](https://gitlab.com/eardh/picture/-/raw/main/mysql_img/202203311541208.png)



### 4. 序列号配置

**1. 创建序列号存储库**

在mycat配置文件`/usr/local/mycat/conf`下面有一个文件 `dbseq.sql`；

将该文件导入到`CentOS7-h2`MySQL服务器作为序列号服务器；操作如下：

```sql
#1、创建序列号物理库
create database seq;

#2、使用库
use seq;

#3、将文件 dbseq.sql 拷贝去 CentOS7-h2 MySQL 里面
-- 运用文件上传等方式

#4、执行导入操作
source dbseq.sql文件路径
```

成功以后如图：

![](https://gitlab.com/eardh/picture/-/raw/main/mysql_img/202203311541824.png)

`MYCAT_SEQUENCE`表字段解释：

- `name` ：列中的值是对应的`库名_表名`该值需要用户设置，即插入一条逻辑表相关的记录，用于记录序列号。
- `current_value` ：当前序列号值。
- `increment` ：序列号自增的步伐，为1的时候严格按1递增，当1000的时候，mycat会每次批量递增1000取序列号。此时在多个mycat访问此序列号表的情况下，不能严格自增。

初始记录`GLOBAL`表示全局递增序列号。

**2. 插入需要递增的表的序列信息**

```sql
insert into MYCAT_SEQUENCE values('school_sign_record', 0, 1);
```

**3. 配置序列号信息**

```sql
/*+ mycat:setSequence{
"name":"school_sign_record",
"clazz":"io.mycat.plug.sequence.SequenceMySQLGenerator",
  "targetName": "dr0",
  "schemaName":"seq"
  } */;
```

- `name` ：在MYCAT_SEQUENCE表中插入的序列信息
- `clazz` ：序列生成器
- `targetName` ：目标数据源或集群
- `schemaName` ：目标物理库名

该步执行 完成后会在`/usr/local/mycat/conf/sequences`下生成文件`{序列号名}.sequence.json`文件



### 5. 分表测试

登录mycat服务器，向`school.sign_record `中插入如下数据：

```sql
insert into sign_record(student_id, sign_id, record_time) values(1,1,NOW());
insert into sign_record(student_id, sign_id, record_time) values(2,1,NOW());
insert into sign_record(student_id, sign_id, record_time) values(3,1,NOW());
insert into sign_record(student_id, sign_id, record_time) values(4,1,NOW());

insert into sign_record(student_id, sign_id, record_time) values(5,2,NOW());
insert into sign_record(student_id, sign_id, record_time) values(6,2,NOW());
insert into sign_record(student_id, sign_id, record_time) values(7,2,NOW());
insert into sign_record(student_id, sign_id, record_time) values(8,2,NOW());

insert into sign_record(student_id, sign_id, record_time) values(5,3,NOW());
insert into sign_record(student_id, sign_id, record_time) values(6,3,NOW());
insert into sign_record(student_id, sign_id, record_time) values(7,4,NOW());
insert into sign_record(student_id, sign_id, record_time) values(8,4,NOW());
```

分表插入成功将是如下情况：

在`CentOS7-h1`物理表查询分表数据如下：

![](https://gitlab.com/eardh/picture/-/raw/main/mysql_img/202203311542428.png)

在Mycat服务器中逻辑表`sign_record`数据如下：

![](https://gitlab.com/eardh/picture/-/raw/main/mysql_img/202203311542063.png)





## 9. 分库分表

### 1. 思路和架构

如果我们将上面两个的案例综合起来，实现分库分表的结构，首先前面我们已经创建了`c0`、`c1`两个集群，并且有`dw0`、`dw1`、`dr0`，`dr1`这四个数据源，并且我们利用`dr0`实现了`序列号服务`，接下来我们将实现分库分表，即在两个集群之间分库分表。

![](https://gitlab.com/eardh/picture/-/raw/main/mysql_img/202203311542387.png)



### 2. 创建逻辑表和逻辑库

首先， 删除上面创建的逻辑库。

```sql
/*+ mycat:dropSchema{
	"schemaName":"school"
} */;
```

创建逻辑库：

```sql
# 创建逻辑库
/*+ mycat:createSchema{
	"customTables":{},
	"globalTables":{},
	"normalTables":{},
	"schemaName":"school",
	"shardingTables":{}
} */;
```

 创建逻辑表`sign_record` ：

```sql
 /*+ mycat:createTable{
  "schemaName":"school",
  "autoIncrement": false,
  "shardingTable":{
		"createTableSQL":"create table record (
                            id int primary key auto_increment,
                            student_id int not null,
                            sign_id int not null,
                            record_time datetime
                        ) engine=innodb default charset=utf8 dbpartition by MOD_HASH (sign_id) dbpartitions 2 tbpartition by MOD_HASH (sign_id) tbpartitions 2;",
        "function":{
                "properties":{
                  "dbNum":2,
                  "mappingFormat":"c${targetIndex}/school_${dbIndex}/sign_record_${index}",
                  "tableNum":2,
                  "tableMethod":"mod_hash(sign_id)",
                  "storeNum":2,
                  "dbMethod":"mod_hash(sign_id)"
              }
            },
        "partition":{}
      },
  "tableName":"sign_record"
} */;
```

创建逻辑表`student`：

```sql
/*+ mycat:createTable{
	"normalTable":{
        "createTableSQL": "create table student (
    id int primary key auto_increment,
    name varchar(20),
    savor varchar(50)
) engine=innodb default charset=utf8;",
		"locality":{
			"schemaName":"school_0", //物理库
			"tableName":"student", //物理表
			"targetName":"c0" //目标
		}
	},
	"schemaName":"school",//逻辑库
	"tableName":"student" //逻辑表
} */;
```

创建逻辑表`teacher`：

```sql
/*+ mycat:createTable{
	"normalTable":{
        "createTableSQL":"create table teacher (
    id int primary key auto_increment,
    name varchar(20),
    subject varchar(50)
) engine=innodb default charset=utf8;",
		"locality":{
			"schemaName":"school_1", //物理库
			"tableName":"teacher", //物理表
			"targetName":"c1" //目标
		}
	},
	"schemaName":"school",//逻辑库
	"tableName":"teacher" //逻辑表
} */;
```

操作成功如下：

![](https://gitlab.com/eardh/picture/-/raw/main/mysql_img/202203311542452.png)



### 3. 分库分表测试

 ```sql
 use school;
 
 insert into student(name, savor) values('张三','喝酒'),('武松','大虎');
 insert into teacher(name, subject) values('李白','语文'),('孔子','哲学');
 
 insert into sign_record(student_id, sign_id, record_time) values(1,1,NOW());
 insert into sign_record(student_id, sign_id, record_time) values(2,1,NOW());
 insert into sign_record(student_id, sign_id, record_time) values(3,1,NOW());
 insert into sign_record(student_id, sign_id, record_time) values(4,1,NOW());
 
 insert into sign_record(student_id, sign_id, record_time) values(5,2,NOW());
 insert into sign_record(student_id, sign_id, record_time) values(6,2,NOW());
 insert into sign_record(student_id, sign_id, record_time) values(7,2,NOW());
 insert into sign_record(student_id, sign_id, record_time) values(8,2,NOW());
 
 insert into sign_record(student_id, sign_id, record_time) values(5,3,NOW());
 insert into sign_record(student_id, sign_id, record_time) values(6,3,NOW());
 insert into sign_record(student_id, sign_id, record_time) values(7,4,NOW());
 insert into sign_record(student_id, sign_id, record_time) values(8,4,NOW());
 ```

**mycat服务器查询结果如下：**

```sql
mysql> select * from student;
+----+--------+--------+
| id | name   | savor  |
+----+--------+--------+
|  1 | 张三   | 喝酒   |
|  2 | 武松   | 大虎   |
+----+--------+--------+
2 rows in set (0.01 sec)

mysql> select * from teacher;
+----+--------+---------+
| id | name   | subject |
+----+--------+---------+
|  1 | 李白   | 语文    |
|  2 | 孔子   | 哲学    |
+----+--------+---------+
2 rows in set (0.01 sec)

mysql> select * from sign_record order by id;
+------+------------+---------+---------------------+
| id   | student_id | sign_id | record_time         |
+------+------------+---------+---------------------+
|   13 |          1 |       1 | 2022-03-31 15:31:06 |
|   14 |          2 |       1 | 2022-03-31 15:31:06 |
|   15 |          3 |       1 | 2022-03-31 15:31:06 |
|   16 |          4 |       1 | 2022-03-31 15:31:06 |
|   17 |          5 |       2 | 2022-03-31 15:31:07 |
|   18 |          6 |       2 | 2022-03-31 15:31:07 |
|   19 |          7 |       2 | 2022-03-31 15:31:07 |
|   20 |          8 |       2 | 2022-03-31 15:31:07 |
|   21 |          5 |       3 | 2022-03-31 15:31:07 |
|   22 |          6 |       3 | 2022-03-31 15:31:07 |
|   23 |          7 |       4 | 2022-03-31 15:31:06 |
|   24 |          8 |       4 | 2022-03-31 15:31:07 |
+------+------------+---------+---------------------+
12 rows in set (0.02 sec)
```

**centos7-h1 查询：**

```sql
mysql> select * from student;
+----+--------+--------+
| id | name   | savor  |
+----+--------+--------+
|  1 | 张三   | 喝酒   |
|  2 | 武松   | 大虎   |
+----+--------+--------+
2 rows in set (0.00 sec)

mysql> select * from sign_record_0;
+----+------------+---------+---------------------+
| id | student_id | sign_id | record_time         |
+----+------------+---------+---------------------+
| 23 |          7 |       4 | 2022-03-31 15:31:06 |
| 24 |          8 |       4 | 2022-03-31 15:31:07 |
+----+------------+---------+---------------------+
2 rows in set (0.00 sec)

mysql> select * from sign_record_1;
+----+------------+---------+---------------------+
| id | student_id | sign_id | record_time         |
+----+------------+---------+---------------------+
| 13 |          1 |       1 | 2022-03-31 15:31:06 |
| 14 |          2 |       1 | 2022-03-31 15:31:06 |
| 15 |          3 |       1 | 2022-03-31 15:31:06 |
| 16 |          4 |       1 | 2022-03-31 15:31:06 |
+----+------------+---------+---------------------+
4 rows in set (0.01 sec)
```

**centos7-h3 查询：**

```sql
mysql> select * from teacher;
+----+--------+---------+
| id | name   | subject |
+----+--------+---------+
|  1 | 李白   | 语文    |
|  2 | 孔子   | 哲学    |
+----+--------+---------+
2 rows in set (0.00 sec)

mysql> select * from sign_record_2;
+----+------------+---------+---------------------+
| id | student_id | sign_id | record_time         |
+----+------------+---------+---------------------+
| 17 |          5 |       2 | 2022-03-31 15:31:07 |
| 18 |          6 |       2 | 2022-03-31 15:31:07 |
| 19 |          7 |       2 | 2022-03-31 15:31:07 |
| 20 |          8 |       2 | 2022-03-31 15:31:07 |
+----+------------+---------+---------------------+
4 rows in set (0.01 sec)

mysql> select * from sign_record_3;
+----+------------+---------+---------------------+
| id | student_id | sign_id | record_time         |
+----+------------+---------+---------------------+
| 21 |          5 |       3 | 2022-03-31 15:31:07 |
| 22 |          6 |       3 | 2022-03-31 15:31:07 |
+----+------------+---------+---------------------+
2 rows in set (0.00 sec)
```
