#  基础篇

## 1. Redis入门

### 1. 认识NoSQL

#### 1. 什么是NoSQL

- NoSQL最常见的解释是"`non-relational`"， 很多人也说它是"Not Only SQL"
- NoSQL仅仅是一个概念，泛指**非关系型的数据库**
- 区别于关系数据库，它们不保证关系数据的ACID特性
- NoSQL是一项全新的数据库革命性运动，提倡运用非关系型的数据存储，相对于铺天盖地的关系型数据库运用，这一概念无疑是一种全新的思维的注入
- 常见的NoSQL数据库有：`Redis`、`MemCache`、`MongoDB`等



#### 2. NoSQL与SQL的差异

|          |                            SQL                             |                            NoSQL                             |
| :---: | :-----: | :----: |
| 数据结构 |                           结构化                           |                           非结构化                           |
| 数据关联 |                           关联的                           |                           无关联的                           |
| 查询方式 |                          SQL查询                           |                            非SQL                             |
| 事务特性 |                            ACID                            |                             BASE                             |
| 存储方式 |                            磁盘                            |                             内存                             |
|  扩展性  |                            垂直                            |                             水平                             |
| 使用场景 | 1）数据结构固定<br>2）相关业务对数据安全性、一致性要求较高 | 1）数据结构不固定<br>2）对一致性、安全性要求不高<br>3）对性能要求 |



### 2. 认识Redis

Redis诞生于2009年全称是Remote Dictionary Server，远程词典服务器，是一个基于内存的键值型NoSQL数据库。

**Redis的特征：**

- 键值（`key-value`）型，value支持多种不同数据结构，功能丰富
- 单线程，每个命令具备原子性
- 低延迟，速度快（基于内存、IO多路复用、良好的编码）
- 支持数据持久化
- 支持主从集群、分片集群
- 支持多语言客户端



### 3. 安装Redis

大多数企业都是基于Linux服务器来部署项目，而且Redis官方也没有提供Windows版本的安装包。因此课程中我们会基于Linux系统来安装Redis.

此处选择的Linux版本为CentOS 7

Redis的官方网站地址：https://redis.io/



#### 1. 安装Redis依赖

Redis是基于C语言编写的，因此首先需要安装Redis所需要的gcc依赖

```sh
yum install -y gcc tcl
```



#### 2. 正式安装Redis

然后将课前资料提供的Redis安装包上传到虚拟机的任意目录：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202205311514810.png)

例如，我放到了/usr/local/src 目录：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202205311517946.png)

解压缩：

```sh
tar -xzf redis-6.2.6.tar.gz
```

解压后：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202205311517200.png)

进入redis目录：

```sh
cd redis-6.2.6
```

运行编译命令：

```sh
make && make install
```

如果没有出错，应该就安装成功了。

默认的安装路径是在 `/usr/local/bin`目录下：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202205311517430.png)

该目录以及默认配置到环境变量，因此可以在任意目录下运行这些命令。其中：

- redis-cli：是redis提供的命令行客户端
- redis-server：是redis的服务端启动脚本
- redis-sentinel：是redis的哨兵启动脚本



###  4. 启动Redis

Redis的启动方式有很多种，例如：**前台启动**、**后台启动**、**开机自启**



#### 1. 默认启动

安装完成后，在任意目录输入redis-server命令即可启动Redis：

```
redis-server
```

如图：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202205311518466.png)

这种启动属于`前台启动`，会阻塞整个会话窗口，窗口关闭或者按下`CTRL + C`则Redis停止。不推荐使用。



#### 2. 指定配置启动

如果要让Redis以`后台`方式启动，则必须修改Redis配置文件，就在我们之前解压的redis安装包下（`/usr/local/src/redis-6.2.6`），名字叫redis.conf：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202205311518396.png)

我们先将这个配置文件备份一份：

```
cp redis.conf redis.conf.bck
```

- 然后修改redis.conf文件中的一些配置：

```properties
# 监听的地址，默认是127.0.0.1，会导致只能在本地访问。修改为0.0.0.0则可以在任意IP访问，生产环境不要设置为0.0.0.0
bind 0.0.0.0
# 守护进程，修改为yes后即可后台运行
daemonize yes
# 密码，设置后访问Redis必须输入密码
requirepass 123321
```

- Redis的其它常见配置：

```properties
# 监听的端口
port 6379
# 工作目录，默认是当前目录，也就是运行redis-server时的命令，日志、持久化等文件会保存在这个目录
dir .
# 数据库数量，设置为1，代表只使用1个库，默认有16个库，编号0~15
databases 1
# 设置redis能够使用的最大内存
maxmemory 512mb
# 日志文件，默认为空，不记录日志，可以指定日志文件名
logfile "redis.log"
```

- 启动Redis：

```sh
# 进入redis安装目录 
cd /usr/local/src/redis-6.2.6
# 启动
redis-server redis.conf
```

- 停止服务：

```sh
# 利用redis-cli来执行 shutdown 命令，即可停止 Redis 服务，
# 因为之前配置了密码，因此需要通过 -u 来指定密码
redis-cli -a 123321 shutdown
```



#### 3. 开机自启

我们也可以通过配置来实现开机自启。

- 首先，新建一个系统服务文件：

```sh
vi /etc/systemd/system/redis.service
```

- 内容如下：

```conf
[Unit]
Description=redis-server
After=network.target

[Service]
Type=forking
ExecStart=/usr/local/bin/redis-server /usr/local/src/redis-6.2.6/redis.conf
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```

- 然后重载系统服务：

```sh
systemctl daemon-reload
```

- 现在，我们可以用下面这组命令来操作redis了：

```sh
# 启动
systemctl start redis
# 停止
systemctl stop redis
# 重启
systemctl restart redis
# 查看状态
systemctl status redis
```

- 执行下面的命令，可以让redis开机自启：

```sh
systemctl enable redis
```





## 2. Redis常见命令

我们可以通过Redis的中文文档：http://www.redis.cn/commands.html，来学习各种命令。

也可以通过菜鸟教程官网来学习：https://www.runoob.com/redis/redis-keys.html



### 1. Redis数据结构介绍

Redis是一个key-value的数据库，key一般是String类型，不过value的类型多种多样

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202205311519412.png)



### 2. 通用命令

通用指令是部分数据类型的，都可以使用的指令，常见的有如下表格所示

|  指令  |                        描述                        |
| :----: | :---: |
|  KEYS  | 查看符合模板的所有key，不建议在生产环境设备上使用  |
|  DEL   |                 删除一个指定的key                  |
| EXISTS |                  判断key是否存在                   |
| EXPIRE | 给一个key设置有效期，有效期到期时该key会被自动删除 |
|  TTL   |              查看一个KEY的剩余有效期               |

可以通过`help [command] `可以查看一个命令的具体用法！



### 3. String类型

String类型，也就是字符串类型，是Redis中最简单的存储类型。

其value是字符串，不过根据字符串的格式不同，又可以分为3类：

- `string`：普通字符串
- `int`：整数类型，可以做自增、自减操作
- `float`：浮点类型，可以做自增、自减操作

不管是哪种格式，底层都是字节数组形式存储，只不过是编码方式不同。字符串类型的最大空间不能超过`512m`。

|  KEY  |    VALUE    |
| :---: | :---: |
|  msg  | hello world |
|  num  |     10      |
| score |    92.5     |

String的常见命令有如下表格所示

|    命令     |                             描述                             |
| :---: | :----: |
|     SET     |         添加或者修改已经存在的一个String类型的键值对         |
|     GET     |                 根据key获取String类型的value                 |
|    MSET     |                批量添加多个String类型的键值对                |
|    MGET     |             根据多个key获取多个String类型的value             |
|    INCR     |                     让一个整型的key自增1                     |
|   INCRBY    | 让一个整型的key自增并指定步长，例如：incrby num 2 让num值自增2 |
| INCRBYFLOAT |              让一个浮点类型的数字自增并指定步长              |
|    SETNX    | 添加一个String类型的键值对，前提是这个key不存在，否则不执行  |
|  SETEX  |          添加一个String类型的键值对，并且指定有效期          |

Redis的key允许有多个单词形成层级结构，多个单词之间用” ：“隔开，格式如下：

```tex
项目名:业务名:类型:id
```

这个格式并非固定，也可以根据自己的需求来删除或添加词条。

例如我们的项目名称叫 `heima`，有`user`和`product`两种不同类型的数据，我们可以这样定义key：

- user 相关的key：`heima:user:1`
- product 相关的key：`heima:product:1`

如果Value是一个Java对象，例如一个User对象，则可以将对象序列化为JSON字符串后存储

|       KEY       |                   VALUE                   |
| :----: | :---: |
|  heima:user:1   |    {"id":1, "name": "Jack", "age": 21}    |
| heima:product:1 | {"id":1, "name": "小米11", "price": 4999} |



### 4. Hash类型

Hash类型，也叫散列，其value是一个无序字典，类似于Java中的`HashMap`结构。

- Hash结构可以将对象中的每个字段独立存储，可以针对单个字段做CRUD

  ![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202205311521156.png)

- Hash的常见命令有：

  |         命令         |                             描述                             |
  | :---: | :----: |
  | HSET key field value |              添加或者修改hash类型key的field的值              |
  |    HGET key field    |                获取一个hash类型key的field的值                |
  |        HMSET         |       hmset 和 hset 效果相同 ，6之后hmset可以弃用了        |
  |        HMGET         |              批量获取多个hash类型key的field的值              |
  |       HGETALL        |         获取一个hash类型的key中的所有的field和value          |
  |        HKEYS         |             获取一个hash类型的key中的所有的field             |
  |        HVALS         |             获取一个hash类型的key中的所有的value             |
  |       HINCRBY        |           让一个hash类型key的字段值自增并指定步长            |
  |        HSETNX        | 添加一个hash类型的key的field值，前提是这个field不存在，否则不执行 |




### 5. List类型

Redis中的List类型与Java中的LinkedList类似，可以看做是一个双向链表结构。既可以支持正向检索和也可以支持反向检索。

特征也与`LinkedList`类似：

- 有序
- 元素可以重复
- 插入和删除快
- 查询速度一般

常用来存储一个有序数据，例如：朋友圈点赞列表，评论列表等

**List的常见命令**

|            命令            |                             描述                             |
| :---: | :----: |
|   LPUSH key  element ...   |                 向列表左侧插入一个或多个元素                 |
|          LPOP key          |        移除并返回列表左侧的第一个元素，没有则返回nil         |
| RPUSH key  element ... |                 向列表右侧插入一个或多个元素                 |
|          RPOP key          |                移除并返回列表右侧的第一个元素                |
|    LRANGE key star end     |                 返回一段角标范围内的所有元素                 |
|        BLPOP和BRPOP        | 与LPOP和RPOP类似，只不过在没有元素时等待指定时间，而不是直接返回nil |

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202205311523425.gif)

**思考问题**

- 如何利用List结构模拟一个栈?

  - 先进后出，入口和出口在同一边
- 如何利用List结构模拟一个队列?

  - 先进先出，入口和出口在不同边
- 如何利用List结构模拟一个阻塞队列?

  - 入口和出口在不同边
  - 出队时采用BLPOP或BRPOP




### 6. Set类型

Redis的Set结构与Java中的HashSet类似，可以看做是一个value为null的HashMap。因为也是一个hash表，因此具备与HashSet类似的特征

- 无序
- 元素不可重复
- 查找快
- 支持交集、并集、差集等功能

**Set的常见命令**

|         命令         |            描述             |
| :---: | :----: |
| SADD key member ...  |  向set中添加一个或多个元素  |
| SREM key member ...  |     移除set中的指定元素     |
|      SCARD key       |     返回set中元素的个数     |
| SISMEMBER key member | 判断一个元素是否存在于set中 |
|       SMEMBERS       |     获取set中的所有元素     |
| SINTER key1 key2 ... |     求key1与key2的交集      |
| SDIFF key1 key2 ...  |     求key1与key2的差集      |
| SUNION key1 key2 ..  |     求key1和key2的并集      |

**交集、差集、并集图示**

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202205311524021.png)



### 7. SortedSet类型

Redis的SortedSet是一个可排序的set集合，与Java中的TreeSet有些类似，但底层数据结构却差别很大。SortedSet中的每一个元素都带有一个score属性，可以基于score属性对元素排序，底层的实现是一个跳表（SkipList）加 hash表。

**SortedSet具备下列特性：**

- 可排序
- 元素不重复
- 查询速度快

因为SortedSet的可排序特性，经常被用来实现排行榜这样的功能。

**SortedSet的常见命令**

|             命令             |                             描述                             |
| :-----: | :----: |
|    ZADD key score member     | 添加一个或多个元素到sorted set ，如果已经存在则更新其score值 |
|       ZREM key member        |                删除sorted set中的一个指定元素                |
|      ZSCORE key member       |             获取sorted set中的指定元素的score值              |
|       ZRANK key member       |              获取sorted set 中的指定元素的排名               |
|          ZCARD key           |                  获取sorted set中的元素个数                  |
|      ZCOUNT key min max      |           统计score值在给定范围内的所有元素的个数            |
| ZINCRBY key increment member |    让sorted set中的指定元素自增，步长为指定的increment值     |
|      ZRANGE key min max      |          按照score排序后，获取指定排名范围内的元素           |
|  ZRANGEBYSCORE key min max   |          按照score排序后，获取指定score范围内的元素          |
|    ZDIFF、ZINTER、ZUNION     |                      求差集、交集、并集                      |

注意：所有的排名默认都是升序，如果要降序则在命令的Z后面添加`REV`即可



### 8. GEO数据结构

GEO就是Geolocation的简写形式，代表地理坐标。Redis在3.2版本中加入了对GEO的支持，允许存储地理坐标信息，帮助我们根据经纬度来检索数据。常见的命令有：

[GEOADD](https://redis.io/commands/geoadd)：添加一个地理空间信息，包含：经度（longitude）、纬度（latitude）、值（member）

[GEODIST](https://redis.io/commands/geodist)：计算指定的两个点之间的距离并返回

[GEOHASH](https://redis.io/commands/geohash)：将指定member的坐标转为hash字符串形式并返回

[GEOPOS](https://redis.io/commands/geopos)：返回指定member的坐标

[GEORADIUS](https://redis.io/commands/georadius)：指定圆心、半径，找到该圆内包含的所有member，并按照与圆心之间的距离排序后返回。6.2以后已废弃

[GEOSEARCH](https://redis.io/commands/geosearch)：在指定范围内搜索member，并按照与指定点之间的距离排序后返回。范围可以是圆形或矩形。6.2.新功能

[GEOSEARCHSTORE](https://redis.io/commands/geosearchstore)：与GEOSEARCH功能一致，不过可以把结果存储到一个指定的key。 6.2.新功能



### 9. BitMap

Redis中是利用string类型数据结构实现BitMap**，**因此最大上限是512M，转换为bit则是 2^32个bit位。

BitMap的操作命令有：

[SETBIT](https://redis.io/commands/setbit)：向指定位置（offset）存入一个0或1

[GETBIT](https://redis.io/commands/getbit) ：获取指定位置（offset）的bit值

[BITCOUNT](https://redis.io/commands/bitcount) ：统计BitMap中值为1的bit位的数量

[BITFIELD](https://redis.io/commands/bitfield) ：操作（查询、修改、自增）BitMap中bit数组中的指定位置（offset）的值

[BITFIELD_RO](https://redis.io/commands/bitfield_ro) ：获取BitMap中bit数组，并以十进制形式返回

[BITOP](https://redis.io/commands/bitop) ：将多个BitMap的结果做位运算（与 、或、异或）

[BITPOS](https://redis.io/commands/bitpos) ：查找bit数组中指定范围内第一个0或1出现的位置





## 3. Redis客户端

> 安装完成Redis，我们就可以操作Redis，实现数据的CRUD了。这需要用到Redis客户端，包括：
>

- **命令行客户端**
- **图形化桌面客户端**
- **编程客户端**



### 1. 命令行客户端

Redis安装完成后就自带了命令行客户端：redis-cli，使用方式如下：

```sh
redis-cli [options] [commonds]
```

其中常见的options有：

- `-h 127.0.0.1`：指定要连接的redis节点的IP地址，默认是127.0.0.1
- `-p 6379`：指定要连接的redis节点的端口，默认是6379
- `-a 123321`：指定redis的访问密码 

其中的commonds就是Redis的操作命令，例如：

- `ping`：与redis服务端做心跳测试，服务端正常会返回`pong`

不指定commond时，会进入`redis-cli`的交互控制台：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202205311524672.png)



### 2. 图形化客户端

GitHub上的大神编写了Redis的图形化桌面客户端，地址：https://github.com/uglide/RedisDesktopManager

不过该仓库提供的是RedisDesktopManager的源码，并未提供windows安装包。

在下面这个仓库可以找到安装包：https://github.com/lework/RedisDesktopManager-Windows/releases

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202205311524354.png)

#### 1. 安装

在课前资料中可以找到Redis的图形化桌面客户端：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202205311524855.png)

解压缩后，运行安装程序即可安装：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202205311524562.png)

安装完成后，在安装目录下找到rdm.exe文件：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202205311525271.png)

双击即可运行：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202205311525906.png)



#### 2. 建立连接

点击左上角的`连接到Redis服务器`按钮：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202205311525236.png)

在弹出的窗口中填写Redis服务信息：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202205311525279.png)

点击确定后，在左侧菜单会出现这个链接：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202205311525032.png)

点击即可建立连接了：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202205311525122.png)

Redis默认有16个仓库，编号从0至15。通过配置文件可以设置仓库数量，但是不超过16，并且不能自定义仓库名称。

如果是基于redis-cli连接Redis服务，可以通过select命令来选择数据库：

```sh
# 选择 0号库
select 0
```



### 3. Java客户端

在Redis官网中提供了各种语言的客户端，地址：https://redis.io/clients

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202205311526932.png)



#### 1.  Jedis

##### 1. Jedis入门

Jedis 的官网地址： https://github.com/redis/jedis，我们先来个快速入门：

- **新建一个Maven工程并引入以下依赖**

  ```xml
  <!--引入Jedis依赖-->
  <dependency>
      <groupId>redis.clients</groupId>
      <artifactId>jedis</artifactId>
      <version>4.2.3</version>
  </dependency>
  
  <!--引入单元测试依赖-->
  <dependency>
      <groupId>org.junit.jupiter</groupId>
      <artifactId>junit-jupiter</artifactId>
      <version>5.8.2</version>
      <scope>test</scope>
  </dependency>
  ```

- **编写测试类并与Redis建立连接**

  ```java
  private Jedis jedis;
  
  @BeforeEach //被该注解修饰的方法每次执行其他方法前自动执行
  void setUp(){
      //  获取连接
      jedis = new Jedis("192.168.230.88",6379);
      // 2. 设置密码
      jedis.auth("132537");
      //  选择库（默认是下标为0的库）
      jedis.select(0);
  }
  ```

- **编写一个操作数据的方法（这里以操作String类型为例）**

  ```java
  @Test
  public void testString(){
      // 往redis中存放一条String类型的数据并获取返回结果
      String result = jedis.set("url", "https://www.oz6.cn");
      System.out.println("result = " + result);
  
      // 2.从redis中获取一条数据
      String url = jedis.get("url");
      System.out.println("url = " + url);
  }
  ```

- **最后不要忘记编写一个释放资源的方法**

  ```java
  @AfterEach //被该注解修饰的方法会在每次执行其他方法后执行
  void tearDown(){
      // 释放资源
      if (jedis != null){
          jedis.close();
      }
  }
  ```

- **执行`testString()`方法后测试结果如图所示**

  ![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202205311526627.png)



##### 2. Jedis连接池

Jedis本身是线程不安全的，并且频繁的创建和销毁连接会有性能损耗，因此我们推荐大家使用Jedis连接池代替Jedis的直连方式

```java
public class JedisConnectionFactory {
    private static final JedisPool jedisPool;

    static {
        //配置连接池
        JedisPoolConfig jedisPoolConfig = new JedisPoolConfig();
        jedisPoolConfig.setMaxTotal(8);
        jedisPoolConfig.setMaxIdle(8);
        jedisPoolConfig.setMinIdle(0);
        jedisPoolConfig.setMaxWait(Duration.of(200, ChronoUnit.SECONDS));
        //创建连接池对象
        jedisPool = new JedisPool(jedisPoolConfig,"192.168.230.88",6379,1000,"132537");
    }

    public static Jedis getJedis(){
       return jedisPool.getResource();
    }
    
    public static void returnJedis(Jedis jedis) {
        jedisPool.returnResource(jedis);
    }
}
```



#### 2. SpringDataRedis

##### 1. SpringDataRedis介绍

SpringData是Spring中数据操作的模块，包含对各种数据库的集成，其中对Redis的集成模块就叫做`SpringDataRedis`

官网地址：https://spring.io/projects/spring-data-redis

- 提供了对不同Redis客户端的整合（`Lettuce`和`Jedis`）
- 提供了`RedisTemplate`统一API来操作Redis
- 支持Redis的发布订阅模型
- 支持Redis哨兵和Redis集群
- 支持基于Lettuce的响应式编程
- 支持基于JDK、JSON、字符串、Spring对象的数据序列化及反序列化
- 支持基于Redis的JDKCollection实现

SpringDataRedis中提供了RedisTemplate工具类，其中封装了各种对Redis的操作。并且将不同数据类型的操作API封装到了不同的类型中：

| API                             | 返回值类型      | 说明                  |
| ------------------------------- | --------------- | --------------------- |
| `redisTemplate.opsForValue()  ` | ValueOperations | 操作String类型数据    |
| `redisTemplate.opsForHash()`    | HashOperations  | 操作Hash类型数据      |
| `redisTemplate.opsForList()`    | ListOperations  | 操作List类型数据      |
| `redisTemplate.opsForSet()`     | SetOperations   | 操作Set类型数据       |
| `redisTemplate.opsForZSet()`    | ZSetOperations  | 操作SortedSet类型数据 |
| `redisTemplate`                 |                 | 通用的命令            |



##### 2. SpringDataRedis快速入门

`SpringBoot`已经提供了对`SpringDataRedis`的支持，使用非常简单

- 首先新建一个Spring Boot工程

  ![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202205311526779.png)

- 然后引入连接池依赖

  ```xml
  <!--连接池依赖-->
  <dependency>
      <groupId>org.apache.commons</groupId>
      <artifactId>commons-pool2</artifactId>
  </dependency>
  ```

- 编写配置文件`application.yml`（连接池的配置在实际开发中是根据需求来的）

  ```yml
  spring:
    redis:
      host: 192.168.111.129 #指定redis所在的host
      port: 6379  #指定redis的端口
      password: 123456  #设置redis密码
      lettuce:
        pool:
          max-active: 8 #最大连接数
          max-idle: 8 #最大空闲数
          min-idle: 0 #最小空闲数
          max-wait: 100ms #连接等待时间
  ```

- 编写测试类执行测试方法

  ```java
  @SpringBootTest
  class RedisDemoApplicationTests {
  
      @Autowired
      private RedisTemplate redisTemplate;
  
      @Test
      void testString() {
          // 通过RedisTemplate获取操作String类型的ValueOperations对象
          ValueOperations ops = redisTemplate.opsForValue();
          // 2.插入一条数据
          ops.set("github","https://github.com/eardh");
  
          // 获取数据
          String github = (String) ops.get("github");
          System.out.println("github = " + github);
      }
  }
  ```




##### 3. RedisSerializer配置

RedisTemplate可以接收任意Object作为值写入Redis，只不过写入前会把Object序列化为字节形式，`默认是采用JDK序列化`，得到的结果是这样的

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202205311526189.png)

**缺点：**

- 可读性差
- 内存占用较大

那么如何解决以上的问题呢？我们可以通过自定义RedisTemplate序列化的方式来解决。

- 编写一个配置类`RedisConfig`

  ```java
  @Configuration
  public class RedisConfig {
  
      @Bean
      public RedisTemplate<String,Object> redisTemplate(RedisConnectionFactory factory){
          // 创建RedisTemplate对象
          RedisTemplate<String ,Object> redisTemplate = new RedisTemplate<>();
          // 2.设置连接工厂
          redisTemplate.setConnectionFactory(factory);
  
          // 创建序列化对象
          StringRedisSerializer stringRedisSerializer = new StringRedisSerializer();
          GenericJackson2JsonRedisSerializer genericJackson2JsonRedisSerializer = new GenericJackson2JsonRedisSerializer();
  
          // 设置key和hashKey采用String的序列化方式
          redisTemplate.setKeySerializer(stringRedisSerializer);
          redisTemplate.setHashKeySerializer(stringRedisSerializer);
  
          // 5.设置value和hashValue采用json的序列化方式
          redisTemplate.setValueSerializer(genericJackson2JsonRedisSerializer);
          redisTemplate.setHashValueSerializer(genericJackson2JsonRedisSerializer);
  
          return redisTemplate;
      }
  }
  ```

- 此时我们已经将RedisTemplate的key设置为`String序列化`，value设置为`Json序列化`的方式，再来执行方法测试，值成功序列化

- 由于我们设置的value序列化方式是Json的，因此我们可以直接向redis中插入一个对象

  ```java
  @Test
  void testSaveUser() {
      redisTemplate.opsForValue().set("user:100", new User("虎哥", 21));
      User user = (User) redisTemplate.opsForValue().get("user:100");
      System.out.println("User = " + user);
  }
  ```

  ![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202205311526710.png)

  尽管Json序列化可以满足我们的需求，但是依旧存在一些问题。

  如上图所示，为了在反序列化时知道对象的类型，JSON序列化器会将类的class类型写入json结果中，存入Redis，会带来额外的内存开销。

  那么我们如何解决这个问题呢？我们可以通过下文的`StringRedisTemplate`来解决这个问题。



##### 4. StringRedisTemplate

为了节省内存空间，我们并不会使用JSON序列化器来处理value，而是统一使用String序列化器，要求只能存储String类型的key和value。当需要存储Java对象时，手动完成对象的序列化和反序列化。

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202205311526279.png)

Spring默认提供了一个StringRedisTemplate类，它的key和value的序列化方式默认就是String方式。省去了我们自定义RedisTemplate的过程

- 我们可以直接编写一个测试类使用StringRedisTemplate来执行以下方法

  ```java
  @SpringBootTest
  class RedisStringTemplateTest {
  
  	@Resource
  	private StringRedisTemplate stringRedisTemplate;
  
  	@Test
  	void testSaveUser() throws JsonProcessingException {
  		// 创建一个Json序列化对象
  		ObjectMapper objectMapper = new ObjectMapper();
  		// 2.将要存入的对象通过Json序列化对象转换为字符串
  		String userJson1 = objectMapper.writeValueAsString(new User("虎哥", 21));
  		// 通过StringRedisTemplate将数据存入redis
  		stringRedisTemplate.opsForValue().set("user:200",userJson1);
  		// 通过key取出value
  		String userJson2 = stringRedisTemplate.opsForValue().get("user:200");
  		// 5.由于取出的值是String类型的Json字符串，因此我们需要通过Json序列化对象来转换为java对象
  		User user = objectMapper.readValue(userJson2, User.class);
  		// 6.打印结果
  		System.out.println("user = " + user);
  	}
  
  }
  ```

- 执行完毕回到Redis的图形化客户端查看结果

  ![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202205311526070.png)

- 自动序列化配置最强版，不用手动序列化对象

  ```java
  @Configuration
  public class RedisConfig {
  
      @Bean
      public RedisTemplate<String, Object> redisTemplate(RedisConnectionFactory factory) {
  
          RedisTemplate<String, Object> template = new RedisTemplate<>();
          
          // 配置连接工厂
          template.setConnectionFactory(factory);
  
          // 创建String序列化器
          StringRedisSerializer stringRedisSerializer = new StringRedisSerializer();
  
          // 序列化和反序列化redis中的值
          Jackson2JsonRedisSerializer<Object> jackson = new Jackson2JsonRedisSerializer<>(Object.class);
          // Java对象转换成JSON结构
          ObjectMapper objectMapper = new ObjectMapper();
  
          // 指定要序列化的域
          objectMapper.setVisibility(PropertyAccessor.ALL, JsonAutoDetect.Visibility.ANY);
          // 指定序列化输入的类型
          objectMapper.activateDefaultTyping(LaissezFaireSubTypeValidator.instance, ObjectMapper.DefaultTyping.NON_FINAL, JsonTypeInfo.As.WRAPPER_ARRAY);
          jackson.setObjectMapper(objectMapper);
  
          // 使用StringRedisSerializer来序列化和反序列化redis的key值
          template.setKeySerializer(stringRedisSerializer);
          // 值采用json序列化
          template.setValueSerializer(jackson);
  
          // 设置hash key和value序列化模式
          template.setHashKeySerializer(stringRedisSerializer);
          template.setHashValueSerializer(jackson);
          
          template.afterPropertiesSet();
  
          return template;
      }
  }
  ```



#### 3. 总结

RedisTemplate的两种序列化实践方案，两种方案各有各的优缺点，可以根据实际情况选择使用。

方案一：

1. 自定义RedisTemplate
2. 修改RedisTemplate的序列化器为GenericJackson2JsonRedisSerializer

方案二：

1. 使用StringRedisTemplate
2. 写入Redis时，手动把对象序列化为JSON
3. 读取Redis时，手动把读取到的JSON反序列化为对象

**方案三：**

1. 自定义RedisTemplate
2. 修改RedisTemplate的序列化器为Jackson2JsonRedisSerializer，并定制Jackson2JsonRedisSerializer的序列化规则

