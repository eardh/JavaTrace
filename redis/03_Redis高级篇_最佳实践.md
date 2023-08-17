# Redis最佳实践

## 1. Redis键值设计

### 1. 优雅的key结构

Redis的Key虽然可以自定义，但最好遵循下面的几个最佳实践约定：

- 遵循基本格式：[业务名称]:[数据名]:[id]
- 长度不超过44字节
- 不包含特殊字符

例如：我们的登录业务，保存用户信息，其key是这样的：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031448865.png)

优点：

① 可读性强

② 避免key冲突

③ 方便管理

④ 更节省内存： key是string类型，底层编码包含int、embstr和raw三种。embstr在小于44字节使用，采用连续内存空间，内存占用更小



### 2. 拒绝BigKey

#### 1. 什么是BigKey

BigKey通常以Key的大小和Key中成员的数量来综合判定，例如：

- Key本身的数据量过大：一个String类型的Key，它的值为5 MB。
- Key中的成员数过多：一个ZSET类型的Key，它的成员数量为10,000个。
- Key中成员的数据量过大：一个Hash类型的Key，它的成员数量虽然只有1,000个但这些成员的Value（值）总大小为100 MB。

**推荐值**：

- 单个key的value小于10KB
- 对于集合类型的key，建议元素数量小于1000



#### 2. BigKey的危害

- **网络阻塞**

  对BigKey执行读请求时，少量的QPS就可能导致带宽使用率被占满，导致Redis实例，乃至所在物理机变慢

- **数据倾斜**

  BigKey所在的Redis实例内存使用率远超其他实例，无法使数据分片的内存资源达到均衡

- **Redis阻塞**

  对元素较多的hash、list、zset等做运算会耗时较旧，使主线程被阻塞

- **CPU压力**

  对BigKey的数据序列化和反序列化会导致CPU的使用率飙升，影响Redis实例和本机其它应用



#### 3. 如何发现BigKey

- **redis-cli --bigkeys**

  利用redis-cli提供的--bigkeys参数，可以遍历分析所有key，并返回Key的整体统计信息与每个数据的Top1的big key

- **scan扫描**

  自己编程，利用scan扫描Redis中的所有key，利用strlen、hlen等命令判断key的长度（此处不建议使用MEMORY USAGE）

- **第三方工具**

  利用第三方工具，如 [Redis-](https://github.com/sripathikrishnan/redis-rdb-tools?spm=a2c4g.11186623.0.0.14073c9cldKVDv)[Rdb](https://github.com/sripathikrishnan/redis-rdb-tools?spm=a2c4g.11186623.0.0.14073c9cldKVDv)[-Tools](https://github.com/sripathikrishnan/redis-rdb-tools?spm=a2c4g.11186623.0.0.14073c9cldKVDv) 分析RDB快照文件，全面分析内存使用情况

- **网络监控**

  自定义工具，监控进出Redis的网络数据，超出预警值时主动告警



#### 4. 如何删除BigKey

BigKey内存占用较多，即便删除这样的key也需要耗费很长时间，导致Redis主线程阻塞，引发一系列问题。

- **redis 3.0 及以下版本**

  如果是集合类型，则遍历BigKey的元素，先逐个删除子元素，最后删除BigKey

- **Redis 4.0以后**

  Redis在4.0后提供了异步删除的命令：`unlink`



### 3. 恰当的数据类型

**方式一：json字符串**

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031448866.png)

- 优点：实现简单粗暴

- 缺点：数据耦合，不够灵活

**方式二：字段打散**

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031448867.png)

- 优点：可以灵活访问对象任意字段

- 缺点：占用空间大、没办法做统一控制

**方式三：hash**✅

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031448868.png)

- 优点：底层使用ziplist，空间占用小，可以灵活访问对象的任意字段

- 缺点：代码相对复杂

假如有hash类型的key，其中有100万对field和value，field是自增id，这个key存在什么问题？如何优化？

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031448869.png)

**存在的问题：**

① hash的entry数量超过500时，会使用哈希表而不是ZipList，内存占用较多。

② 可以通过`hash-max-ziplist-entries`配置entry上限。但是如果entry过多就会导致BigKey问题

**方案二**：拆分为string类型：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031448870.png)

**存在的问题：**

① string结构底层没有太多内存优化，内存占用较多。

② 想要批量获取这些数据比较麻烦

**方案三**：拆分为小的hash，将 id / 100 作为key， 将id % 100 作为field，这样每100个元素为一个Hash。

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031448871.png)

**总结**：

Key的最佳实践：

- 固定格式：[业务名]:[数据名]:[id]
- 足够简短：不超过44字节
- 不包含特殊字符

Value的最佳实践：

- 合理的拆分数据，拒绝BigKey
- 选择合适数据结构
- Hash结构的entry数量不要超过1000(默认500)
- 设置合理的超时时间





## 2. 批处理优化

### 1. Pipeline

#### 1. 数据导入的方式

**1. 单个命令的执行流程**

一次命令的响应时间 = **1**次往返的网络传输耗时 + **1**次Redis执行命令耗时

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031448872.png)

**2. N条命令依次执行**

N次命令的响应时间 = **N**次往返的网络传输耗时 + **N**次Redis执行命令耗时

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031448873.png)

**3. N条命令批量执行**

N次命令的响应时间 = **1**次往返的网络传输耗时 + **N**次Redis执行命令耗时

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031448874.png)



#### 2. MSET

Redis提供了很多Mxxx这样的命令，可以实现批量插入数据，例如：

- mset

- hmset

利用mset批量插入10万条数据：

> 不要在一次批处理中传输太多命令，否则单次命令占用带宽过多，会导致网络阻塞

```java
@Test 
void testMxx() {    
    String[] arr = new String[2000];    
    int j;   
    for (int i = 1; i <= 100000; i++) {       
        j = (i % 1000) << 1;        
        arr[j] = "test:key_" + i;         
        arr[j + 1] = "value_" + i;       
        if (j == 0) {           
            jedis.mset(arr);       
        }   
    }
}
```



#### 2. Pipeline

MSET虽然可以批处理，但是却只能操作部分数据类型，因此如果有对复杂数据类型的批处理需要，建议使用Pipeline功能：

```java
@Test
void testPipeline() {
    // 创建管道
    Pipeline pipeline = jedis.pipelined();

    for (int i = 1; i <= 100000; i++) {
        // 放入命令到管道
        pipeline.set("test:key_" + i, "value_" + i);
        if (i % 1000 == 0) { 
            // 每放入1000条命令，批量执行
            pipeline.sync();
        }
    }
}
```

**总结：**

批量处理的方案：

① 原生的M操作

② Pipeline批处理

注意事项：

① 批处理时不建议一次携带太多命令

② Pipeline的多个命令之间不具备原子性



### 2. 集群下的批处理

如MSET或Pipeline这样的批处理需要在一次请求中携带多条命令，而此时如果Redis是一个集群，那批处理命令的多个key必须落在一个插槽中，否则就会导致执行失败。

|          | 串行命令                      | 串行slot                                                     | 并行slot                                                     | hash_tag                                             |
| -------- | ----------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ | ---------------------------------------------------- |
| 实现思路 | for循环遍历，依次执行每个命令 | 在客户端计算每个key的slot，将slot一致分为一组，每组都利用Pipeline批处理。  串行执行各组命令 | 在客户端计算每个key的slot，将slot一致分为一组，每组都利用Pipeline批处理。  并行执行各组命令 | 将所有key设置相同的hash_tag，则所有key的slot一定相同 |
| 耗时     | N次网络耗时  + N次命令耗时    | m次网络耗时  + N次命令耗时  m  = key的slot个数               | 1次网络耗时  + N次命令耗时                                   | 1次网络耗时  + N次命令耗时                           |
| 优点     | 实现简单                      | 耗时较短                                                     | 耗时非常短                                                   | 耗时非常短、实现简单                                 |
| 缺点     | 耗时非常久                    | 实现稍复杂  slot越多，耗时越久                               | 实现复杂                                                     | 容易出现数据倾斜                                     |





## 3. 服务端优化

### 1. 持久化配置

Redis的持久化虽然可以保证数据安全，但也会带来很多额外的开销，因此持久化请遵循下列建议：

① 用来做缓存的Redis实例尽量不要开启持久化功能

② 建议关闭RDB持久化功能，使用AOF持久化

③ 利用脚本定期在slave节点做RDB，实现数据备份

④ 设置合理的rewrite阈值，避免频繁的bgrewrite

⑤ 配置`no-appendfsync-on-rewrite = yes`，禁止在rewrite期间做aof，避免因AOF引起的阻塞

部署有关建议：

① Redis实例的物理机要预留足够内存，应对fork和rewrite

② 单个Redis实例内存上限不要太大，例如4G或8G。可以加快fork的速度、减少主从同步、数据迁移压力

③ 不要与CPU密集型应用部署在一起

④ 不要与高硬盘负载应用一起部署。例如：数据库、消息队列



### 2. 慢查询

**慢查询**：在Redis执行时耗时超过某个阈值的命令，称为慢查询。

慢查询的阈值可以通过配置指定：

- `slowlog-log-slower-than`：慢查询阈值，单位是微秒。默认是10000，建议1000

慢查询会被放入慢查询日志中，日志的长度有上限，可以通过配置指定：

- `slowlog-max-len`：慢查询日志（本质是一个队列）的长度。默认是128，建议1000

```bash
config get slowlog-log-slower-than
config get slowlog-max-len
```

修改这两个配置可以使用：`config set`命令：

```bash
config set slowlog-log-slower-than 1000
config set slowlog-max-len 1000
```

查看慢查询日志列表：

- `slowlog len`：查询慢查询日志长度
- `slowlog get[n]`：读取n条慢查询日志
- `slowlog reset`：清空慢查询列表

```bash
SLOWLOG get
```



### 3. 命令及安全配置

Redis会绑定在0.0.0.0:6379，这样将会将Redis服务暴露到公网上，而Redis如果没有做身份认证，会出现严重的安全漏洞.

漏洞重现方式：https://cloud.tencent.com/developer/article/1039000

漏洞出现的核心的原因有以下几点：

- Redis未设置密码
- 利用了Redis的config set命令动态修改Redis配置
- 使用了Root账号权限启动Redis

为了避免这样的漏洞，这里给出一些建议：

① Redis一定要设置密码

② 禁止线上使用下面命令：`keys`、`flushall`、`flushdb`、`configset `等命令。可以利用`rename-command`禁用。

③ bind：限制网卡，禁止外网网卡访问

④ 开启防火墙

⑤ 不要使用Root账户启动Redis

⑥ 尽量不是有默认的端口



### 4. 内存配置

当Redis内存不足时，可能导致Key频繁被删除、响应时间变长、QPS不稳定等问题。当内存使用率达到90%以上时就需要我们警惕，并快速定位到内存占用的原因。

| 内存占用   | 说明                                                         |
| ---------- | ------------------------------------------------------------ |
| 数据内存   | 是Redis最主要的部分，存储Redis的键值信息。主要问题是BigKey问题、内存碎片问题 |
| 进程内存   | Redis主进程本身运⾏肯定需要占⽤内存，如代码、常量池等等；这部分内存⼤约⼏兆，在⼤多数⽣产环境中与Redis数据占⽤的内存相⽐可以忽略。 |
| 缓冲区内存 | 一般包括客户端缓冲区、AOF缓冲区、复制缓冲区等。客户端缓冲区又包括输入缓冲区和输出缓冲区两种。这部分内存占用波动较大，不当使用BigKey，可能导致内存溢出。 |

Redis提供了一些命令，可以查看到Redis目前的内存分配状态：

- `info memory`
- `memory xxx`

内存缓冲区常见的有三种：

- **复制缓冲区**：主从复制的`repl_backlog_buf`，如果太小可能导致频繁的全量复制，影响性能。通过`repl-backlog-size`来设置，默认1mb

- **AOF缓冲区**：AOF刷盘之前的缓存区域，AOF执行rewrite的缓冲区。无法设置容量上限

- **客户端缓冲区：**分为输入缓冲区和输出缓冲区，输入缓冲区最大1G且不能设置。输出缓冲区可以设置

```basic
client-output-buffer-limit <class> <hard limit> <soft limit> <soft seconds>
```

`<class>`：客户端类型

- normal：普通客户端
- replica：主从复制客户端
- pubsub：PubSub客户端

`<hard limit>`：缓冲区上限在超过limit后断开客户端

`<soft limit> <soft seconds>`：缓冲区上限，在超过soft limit 并且持续了 soft seconds秒后断开客户端

 



## 4. 集群最佳实践

集群虽然具备高可用特性，能实现自动故障恢复，但是如果使用不当，也会存在一些问题：

① 集群完整性问题

② 集群带宽问题

③ 数据倾斜问题

④ 客户端性能问题

⑤ 命令的集群兼容性问题

⑥ lua和事务问题

**集群完整性问题**

在Redis的默认配置中，如果发现任意一个插槽不可用，则整个集群都会停止对外服务：

```bash
cluster-require-full-coverage yes
```

为了保证高可用特性，这里建议将`cluster-require-full-coverage`配置为false

**集群带宽问题**

集群节点之间会不断的互相Ping来确定集群中其它节点的状态。每次Ping携带的信息至少包括：

- 插槽信息

- 集群状态信息

集群中节点越多，集群状态信息数据量也越大，10个节点的相关信息可能达到1kb，此时每次集群互通需要的带宽会非常高。

解决途径：

① 避免大集群，集群节点数不要太多，最好少于1000，如果业务庞大，则建立多个集群。

② 避免在单个物理机中运行太多Redis实例

③ 配置合适的cluster-node-timeout值

**集群还是主从**

集群虽然具备高可用特性，能实现自动故障恢复，但是如果使用不当，也会存在一些问题：

① 集群完整性问题

② 集群带宽问题

③ 数据倾斜问题

④ 客户端性能问题

⑤ 命令的集群兼容性问题

⑥ lua和事务问题

单体Redis（主从Redis）已经能达到万级别的QPS，并且也具备很强的高可用特性。如果主从能满足业务需求的情况下，尽量不搭建Redis集群。