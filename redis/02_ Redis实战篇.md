# 实战篇

## 1. 短信登录

### 1. 导入黑马点评项目

**1. 首先，导入课前资料提供的SQL文件**

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031445944.png)

其中的表有：

- ltb_user：用户表
- ltb_user_info：用户详情表
- ltb_shop：商户信息表
- ltb_shop_type：商户类型表
- ltb_blog：用户日记表（达人探店日记）
- ltb_follow：用户关注表
- ltb_voucher：优惠券表
- tb_voucher_order：优惠券的订单表

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031445946.png)

**2. 导入后端项目**

在资料中提供了一个项目源码：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031445947.png)

将其复制到你的idea工作空间，然后利用idea打开即可

启动项目后，在浏览器访问：http://localhost:8081/shop-type/list ，如果可以看到数据则证明运行没有问题

> 不要忘了修改application.yaml文件中的mysql、redis地址信息

**3. 导入前端项目**

在资料中提供了一个nginx文件夹：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031445948.png)

将其复制到任意目录，要确保该目录不包含中文、特殊字符和空格，例如：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031445949.png)

**4. 运行前端项目**

在nginx所在目录下打开一个CMD窗口，输入命令：

```shell
start nginx.exe
```

打开chrome浏览器，在空白页面点击鼠标右键，选择检查，即可打开开发者工具，然后打开手机模式：

然后访问: [http://127.0.0.1:8080](http://127.0.0.1:8080/) ，即可看到页面。



### 2. 基于Session实现登录

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031445950.png)



### 3. 集群的session共享问题

session共享问题：多台Tomcat并不共享session存储空间，当请求切换到不同tomcat服务时导致数据丢失的问题。

session的替代方案应该满足：

- 数据共享
- 内存存储
- key、value结构

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031445951.png)



### 4. 基于Redis实现共享session登录

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031445952.png)

Redis代替session需要考虑的问题：

- 选择合适的数据结构
- 选择合适的key
- 选择合适的存储粒度





## 2. 查询缓存

### 1. 什么是缓存

**缓存**就是数据交换的缓冲区（称作Cache [ kæʃ ] ），是存贮数据的临时地方，一般读写性能较高。

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031445953.png)

**作用**

- 降低后端负载
- 提高读写效率，降低响应时间

**成本**

- 数据一致性成本
- 代码维护成本
- 运维成本



### 2. 添加Redis缓存

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031445954.png)



### 3. 缓存更新策略

|          | 内存淘汰                                                     | 超时剔除                                                     | 主动更新                                     |
| -------- | ------------------------------------------------------------ | ------------------------------------------------------------ | -------------------------------------------- |
| 说明     | 不用自己维护，利用Redis的内存淘汰机制，当内存不足时自动淘汰部分数据。下次查询时更新缓存。 | 给缓存数据添加TTL时间，到期后自动删除缓存。下次查询时更新缓存。 | 编写业务逻辑，在修改数据库的同时，更新缓存。 |
| 一致性   | 差                                                           | 一般                                                         | 好                                           |
| 维护成本 | 无                                                           | 低                                                           | 高                                           |

业务场景：

- 低一致性需求：使用内存淘汰机制。例如店铺类型的查询缓存
- 高一致性需求：主动更新，并以超时剔除作为兜底方案。例如店铺详情查询的缓存

**高一致性需求：**

**Cache Aside Pattern**✔️：由缓存的调用者，在更新数据库的同时更新缓存

**Read/Write Through Pattern**：缓存与数据库整合为一个服务，由服务来维护一致性。调用者调用该服务，无需关心缓存一致性问题。

**Write Behind Caching Pattern**：调用者只操作缓存，由其它线程异步的将缓存数据持久化到数据库，保证最终一致。

 选择`Cache Aside Pattern`实现缓存一致性

操作缓存和数据库时有三个问题需要考虑：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031445955.png)

1. 删除缓存还是更新缓存？
   - 更新缓存：每次更新数据库都更新缓存，无效写操作较多 ❌
   - 删除缓存：更新数据库时让缓存失效，查询时再更新缓存 ✅

2. 如何保证缓存与数据库的操作的同时成功或失败？
   - 单体系统，将缓存与数据库操作放在一个事务
   - 分布式系统，利用TCC等分布式事务方案
3. 先操作缓存还是先操作数据库？
   - 先删除缓存，再操作数据库
   - 先操作数据库，再删除缓存

缓存更新策略的最佳实践方案：

1. 低一致性需求：使用Redis自带的内存淘汰机制

2. 高一致性需求：主动更新，并以超时剔除作为兜底方案
   - 读操作：
     - 缓存命中则直接返回
     - 缓存未命中则查询数据库，并写入缓存，设定超时时间
   - 写操作：
     - 先写数据库，然后再删除缓存
     - 要确保数据库与缓存操作的原子性



### 4. 缓存穿透

**缓存穿透**是指客户端请求的数据在缓存中和数据库中都不存在，这样缓存永远不会生效，这些请求都会打到数据库。

常见的解决方案有两种：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031445956.png)

- 缓存空对象

  对于不存在的数据也在Redis建立缓存，值为空，并设置一个较短的TTL时间

  - 优点：实现简单，维护方便
  - 缺点：
    - 额外的内存消耗
    - 可能造成短期的不一致

- 布隆过滤

  利用布隆过滤算法，在请求进入Redis之前先判断是否存在，如果不存在则直接拒绝请求

  - 优点：内存占用较少，没有多余key
  - 缺点：
    - 实现复杂
    - 存在误判可能

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031445957.png)

缓存穿透产生的原因是什么？

- 用户请求的数据在缓存中和数据库中都不存在，不断发起这样的请求，给数据库带来巨大压力

缓存穿透的解决方案有哪些？

- 缓存null值
- 布隆过滤
- 增强id的复杂度，避免被猜测id规律
- 做好数据的基础格式校验
- 加强用户权限校验
- 做好热点参数的限流



### 5. 缓存雪崩

**缓存雪崩**是指在同一时段大量的缓存key同时失效或者Redis服务宕机，导致大量请求到达数据库，带来巨大压力。

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031445958.png)

**解决方案：**

- 给不同的Key的TTL添加随机值
- 利用Redis集群提高服务的可用性
- 给缓存业务添加降级限流策略
- 给业务添加多级缓存



### 6. 缓存击穿

**缓存击穿问题**也叫热点Key问题，就是一个被**高并发访问**并且**缓存重建业务较复杂**的key突然失效了，无数的请求访问会在瞬间给数据库带来巨大的冲击。

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031445959.png)

常见的解决方案有两种：

- 互斥锁
- 逻辑过期

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031445960.png)

| 解决方案 | 优点                                              | 缺点                                            |
| -------- | ------------------------------------------------- | ----------------------------------------------- |
| 互斥锁   | 1. 没有额外的内存消耗  2. 保证一致性  3. 实现简单 | 1. 线程需要等待，性能受影响   2. 可能有死锁风险 |
| 逻辑过期 | 线程无需等待，性能较好                            | 1. 不保证一致性  2. 有额外内存消耗  3. 实现复杂 |



### 7. 缓存工具封装

基于StringRedisTemplate封装一个缓存工具类，满足下列需求：

- 方法1：将任意Java对象序列化为json并存储在string类型的key中，并且可以设置TTL过期时间
- 方法2：将任意Java对象序列化为json并存储在string类型的key中，并且可以设置逻辑过期时间，用于处理缓存击穿问题
- 方法3：根据指定的key查询缓存，并反序列化为指定类型，利用缓存空值的方式解决缓存穿透问题
- 方法4：根据指定的key查询缓存，并反序列化为指定类型，需要利用逻辑过期解决缓存击穿问题





## 3. 秒杀

### 1. 全局唯一ID

全局ID生成器，是一种在分布式系统下用来生成全局唯一ID的工具，一般要满足下列特性：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031445961.png)

为了增加ID的安全性，我们可以不直接使用Redis自增的数值，而是拼接一些其它信息：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031445962.png)

ID的组成部分：

- 符号位：1bit，永远为0
- 时间戳：31bit，以秒为单位，可以使用69年
- 序列号：32bit，秒内的计数器，支持每秒产生2^32个不同ID

全局唯一ID生成策略：

- UUID
- Redis自增
- snowflake算法
- 数据库自增

Redis自增ID策略：

- 每天一个key，方便统计订单量
- ID构造是 时间戳 + 计数器



### 2. 实现优惠券秒杀下单

下单时需要判断两点：

- 秒杀是否开始或结束，如果尚未开始或已经结束则无法下单
- 库存是否充足，不足则无法下单

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031445963.png)



### 3. 超卖问题

超卖问题是典型的多线程安全问题，针对这一问题的常见解决方案就是加锁：

**悲观锁**：认为线程安全问题一定会发生，因此在操作数据之前先获取锁，确保线程串行执行。

- 例如Synchronized、Lock都属于悲观锁

**乐观锁**：认为线程安全问题不一定会发生，因此不加锁，只是在更新数据时去判断有没有其它线程对数据做了修改。

- 如果没有修改则认为是安全的，自己才更新数据。
- 如果已经被其它线程修改说明发生了安全问题，此时可以重试或异常。

乐观锁的关键是判断之前查询得到的数据是否有被修改过，常见的方式有两种：

- **版本号法**
- **CAS法**

超卖这样的线程安全问题，解决方案有哪些？

1. 悲观锁：添加同步锁，让线程串行执行
   - 优点：简单粗暴
   - 缺点：性能一般

2. 乐观锁：不加锁，在更新时判断是否有其它线程在修改
   - 优点：性能好
   - 缺点：存在成功率低的问题



### 4. 一人一单

通过加锁可以解决在单机情况下的一人一单安全问题，但是在集群模式下就不行了。



### 5. 分布式锁

#### 1. 基于Redis的分布式锁

**分布式锁：**满足分布式系统或集群模式下多进程可见并且互斥的锁。

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031445964.png)

分布式锁的核心是实现多进程之间互斥，而满足这一点的方式有很多，常见的有三种：

|        | MySQL                     | Redis                    | Zookeeper                        |
| ------ | ------------------------- | ------------------------ | -------------------------------- |
| 互斥   | 利用mysql本身的互斥锁机制 | 利用setnx这样的互斥命令  | 利用节点的唯一性和有序性实现互斥 |
| 高可用 | 好                        | 好                       | 好                               |
| 高性能 | 一般                      | 好                       | 一般                             |
| 安全性 | 断开连接，自动释放锁      | 利用锁超时时间，到期释放 | 临时节点，断开连接自动释放       |

实现分布式锁时需要实现的两个基本方法：

- **获取锁：**

  - 互斥：确保只能有一个线程获取锁

  - 非阻塞：尝试一次，成功返回true，失败返回false

  - ```shell
    # 添加锁，利用setnx的互斥特性
    SETNX lock thread1
    # 添加锁过期时间，避免服务宕机引起的死锁
    EXPIRE lock 10
    
    #或者
    set lock thread1 EX 10 NX
    ```

- **释放锁：**

  - 手动释放

  - 超时释放：获取锁时添加一个超时时间

  - ```shell
    # 释放锁，删除即可
    DEL key
    ```

需求：修改之前的分布式锁实现，满足：

1. 在获取锁时存入线程标示（可以用UUID表示）

2. 在释放锁时先获取锁中的线程标示，判断是否与当前线程标示一致
   - 如果一致则释放锁
   - 如果不一致则不释放锁



#### 2. Redis的Lua脚本

Redis提供了Lua脚本功能，在一个脚本中编写多条Redis命令，确保多条命令执行时的原子性。Lua是一种编程语言，它的基本语法大家可以参考网站：https://www.runoob.com/lua/lua-tutorial.html

这里重点介绍Redis提供的调用函数，语法如下：

```lua
# 执行redis命令
redis.call('命令名称', 'key', '其它参数', ...)
```

例如，我们要执行set name jack，则脚本是这样：

```lua
# 执行 set name jack
redis.call('set', 'name', 'jack')
```

例如，我们要先执行set name Rose，再执行get name，则脚本如下：

```lua
# 先执行 set name jack
redis.call('set', 'name', 'jack')
# 再执行 get name
local name = redis.call('get', 'name')
# 返回
return name
```

写好脚本以后，需要用Redis命令来调用脚本，调用脚本的常见命令如下：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031445965.png)

例如，我们要执行 `redis.call('set','name','jack')` 这个脚本，语法如下：

```lua
# 调用脚本 
EVAL "return redis.call('set', 'name', 'jack')"  0

"" -- 里面为脚本内容
0  -- 脚本需要的key类型的参数个数
```

如果脚本中的key、value不想写死，可以作为参数传递。key类型参数会放入KEYS数组，其它参数会放入ARGV数组，在脚本中可以从KEYS和ARGV数组获取这些参数：

```lua
# 调用脚本 
EVAL "return redis.call('set',KEYS[1],ARGV[1])" 1 name Rose
```

释放锁的业务流程是这样的：

1. 获取锁中的线程标示

2. 判断是否与指定的标示（当前线程标示）一致

3. 如果一致则释放锁（删除）

4. 如果不一致则什么都不做

如果用Lua脚本来表示则是这样的：

```lua
-- 这里的 KEYS[1] 就是锁的key，这里的ARGV[1] 就是当前线程标示
-- 获取锁中的标示，判断是否与当前线程标示一致
if (redis.call('GET', KEYS[1]) == ARGV[1]) then
    -- 一致，则删除锁
    return redis.call('DEL', KEYS[1])
end
-- 不一致，则直接返回
return 0
```

需求：基于Lua脚本实现分布式锁的释放锁逻辑

提示：RedisTemplate调用Lua脚本的API如下：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031445966.png)

基于Redis的分布式锁实现思路：

- 利用set nx ex获取锁，并设置过期时间，保存线程标识
- 释放锁时先判断线程标示是否与自己一致，一致则删除锁

特性：

- 利用set nx满足互斥性
- 利用set ex保证故障时锁依然能释放，避免死锁，提高安全性
- 利用Redis集群保证高可用和高并发特性

基于setnx实现的分布式锁存在下面的问题：

**不可重入**：同一个线程无法多次获取同一把锁

**不可重试**：获取锁只尝试一次就返回false，没有重试机制

**超时释放**：锁超时释放虽然可以避免死锁，但如果是业务执行耗时较长，也会导致锁释放，存在安全隐患

**主从一致性**：如果Redis提供了主从集群，主从同步存在延迟，当主宕机时，如果从并同步主中的锁数据，则会出现锁实现



#### 3. Redisson

`Redisson`是一个在Redis的基础上实现的Java驻内存数据网格（In-Memory Data Grid）。它不仅提供了一系列的分布式的Java常用对象，还提供了许多分布式服务，其中就包含了各种分布式锁的实现。

官网地址： [https://redisson.org](https://redisson.org/)

GitHub地址： https://github.com/redisson/redisson



##### 1. Redisson入门

1. 引入依赖：

```xml
<dependency>
    <groupId>org.redisson</groupId>
    <artifactId>redisson</artifactId>
    <version>3.13.6</version>
</dependency>
```

2. 配置Redisson客户端：

```java
@Configuration
public class RedisConfig {
    @Bean
    public RedissonClient redissonClient() {
        // 配置类
        Config config = new Config();
        // 添加redis地址，这里添加了单点的地址，也可以使用config.useClusterServers()添加集群地址 
        config.useSingleServer().setAddress("redis://192.168.150.101:6379").setPassowrd("123321");
        // 创建客户端
        return Redisson.create(config);
    }
}
```

3. 使用Redisson的分布式锁

```java
@Resource
private RedissonClient redissonClient;

@Test
void testRedisson() throws InterruptedException {
    // 获取锁（可重入），指定锁的名称
    RLock lock = redissonClient.getLock("anyLock"); 
    // 尝试获取锁，参数分别是：获取锁的最大等待时间（期间会重试），锁自动释放时间，时间单位
    boolean isLock = lock.tryLock(1, 10, TimeUnit.SECONDS);
    // 判断释放获取成功
    if(isLock){
        try {
            System.out.println("执行业务");
        }finally {
            // 释放锁
            lock.unlock();
        }
    }
}
```



##### 2. Redisson可重入锁原理

```java
// 创建锁对象
RLock lock = redissonClient.getLock("lock");

@Test
void method1() {
    boolean isLock = lock.tryLock();
    if(!isLock){
        log.error("获取锁失败，1");
        return;
    }
    try {
        log.info("获取锁成功，1");
        method2();
    } finally {
        log.info("释放锁，1");
        lock.unlock();
    }
}
void method2(){
    boolean isLock = lock.tryLock();
    if(!isLock){
        log.error("获取锁失败, 2");
        return;
    }
    try {
        log.info("获取锁成功，2");
    } finally {
        log.info("释放锁，2"); 
        lock.unlock();
    }
}
```

**获取锁的Lua脚本：**

```lua
local key = KEYS[1]; -- 锁的key
local threadId = ARGV[1]; -- 线程唯一标识
local releaseTime = ARGV[2]; -- 锁的自动释放时间
-- 判断是否存在
if(redis.call('exists', key) == 0) then
    -- 不存在, 获取锁
    redis.call('hset', key, threadId, '1'); 
    -- 设置有效期
    redis.call('expire', key, releaseTime); 
    return 1; -- 返回结果
end;
-- 锁已经存在，判断threadId是否是自己
if(redis.call('hexists', key, threadId) == 1) then
    -- 不存在, 获取锁，重入次数+1
    redis.call('hincrby', key, threadId, '1'); 
    -- 设置有效期
    redis.call('expire', key, releaseTime); 
    return 1; -- 返回结果
end;
return 0; -- 代码走到这里,说明获取锁的不是自己，获取锁失败
```

**释放锁的Lua脚本：**

```lua
local key = KEYS[1]; -- 锁的key
local threadId = ARGV[1]; -- 线程唯一标识
local releaseTime = ARGV[2]; -- 锁的自动释放时间
-- 判断当前锁是否还是被自己持有
if (redis.call('HEXISTS', key, threadId) == 0) then
    return nil; -- 如果已经不是自己，则直接返回
end;
-- 是自己的锁，则重入次数-1
local count = redis.call('HINCRBY', key, threadId, -1);
-- 判断是否重入次数是否已经为0 
if (count > 0) then
    -- 大于0说明不能释放锁，重置有效期然后返回
    redis.call('EXPIRE', key, releaseTime);
    return nil;
else  -- 等于0说明可以释放锁，直接删除
    redis.call('DEL', key);
    return nil;
end;
```

**Redisson分布式锁原理：**

- `可重入`：利用hash结构记录线程id和重入次数
- `可重试`：利用信号量和PubSub功能实现等待、唤醒，获取锁失败的重试机制
- `超时续约`：利用watchDog，每隔一段时间（releaseTime / 3），重置超时时间



##### 3. Redisson分布式锁主从一致性问题

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031445967.png)

**总结：**

**不可重入Redis分布式锁：**

- 原理：利用setnx的互斥性；利用ex避免死锁；释放锁时判断线程标示
- 缺陷：不可重入、无法重试、锁超时失效

**可重入的Redis分布式锁：**

- 原理：利用hash结构，记录线程标示和重入次数；利用watchDog延续锁时间；利用信号量控制锁重试等待
- 缺陷：redis宕机引起锁失效问题

**Redisson的multiLock：**

- 原理：多个独立的Redis节点，必须在所有节点都获取重入锁，才算获取锁成功
- 缺陷：运维成本高、实现复杂

  

### 6. Redis优化秒杀

需求：

① 新增秒杀优惠券的同时，将优惠券信息保存到Redis中

② 基于Lua脚本，判断秒杀库存、一人一单，决定用户是否抢购成功

③ 如果抢购成功，将优惠券id和用户id封装后存入阻塞队列

④ 开启线程任务，不断从阻塞队列中获取信息，实现异步下单功能

**总结：**

秒杀业务的优化思路是什么？

① 先利用Redis完成库存余量、一人一单判断，完成抢单业务

② 再将下单业务放入阻塞队列，利用独立线程异步下单

基于阻塞队列的异步秒杀存在哪些问题？

- 内存限制问题
- 数据安全问题



### 7. Redis消息队列实现异步秒杀

**消息队列**（Message Queue），字面意思就是存放消息的队列。最简单的消息队列模型包括3个角色：

- 消息队列：存储和管理消息，也被称为消息代理（Message Broker）
- 生产者：发送消息到消息队列
- 消费者：从消息队列获取消息并处理消息

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031445968.png)

Redis提供了三种不同的方式来实现消息队列：

- list结构：基于List结构模拟消息队列
- PubSub：基本的点对点消息模型
- Stream：比较完善的消息队列模型



#### 1. 基于List结构模拟消息队列

**消息队列**（Message Queue），字面意思就是存放消息的队列。而Redis的list数据结构是一个双向链表，很容易模拟出队列效果。

队列是入口和出口不在一边，因此我们可以利用：LPUSH 结合 RPOP、或者 RPUSH 结合 LPOP来实现。

不过要注意的是，当队列中没有消息时RPOP或LPOP操作会返回null，并不像JVM的阻塞队列那样会阻塞并等待消息。因此这里应该使用BRPOP或者BLPOP来实现阻塞效果。

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031445969.png)



**基于List的消息队列有哪些优缺点？**

优点：

- 利用Redis存储，不受限于JVM内存上限
- 基于Redis的持久化机制，数据安全性有保证
- 可以满足消息有序性

缺点：

- 无法避免消息丢失
- 只支持单消费者



#### 2. 基于PubSub的消息队列

**PubSub**（发布订阅）是Redis2.0版本引入的消息传递模型。顾名思义，消费者可以订阅一个或多个channel，生产者向对应channel发送消息后，所有订阅者都能收到相关消息。

- `SUBSCRIBE channel [channel]` ：订阅一个或多个频道
- `PUBLISH channel msg` ：向一个频道发送消息
- `PSUBSCRIBE pattern[pattern]` ：订阅与pattern格式匹配的所有频道

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031445970.png)

**基于PubSub的消息队列有哪些优缺点？**

优点：

- 采用发布订阅模型，支持多生产、多消费

缺点：

- 不支持数据持久化
- 无法避免消息丢失
- 消息堆积有上限，超出时数据丢失



#### 3. 基于Stream的消息队列

Stream 是 Redis 5.0 引入的一种新数据类型，可以实现一个功能非常完善的消息队列。

发送消息的命令：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031445971.png)

例如：

```shell
# 创建名为 users 的队列，并向其中发送一个消息，内容是：{name=jack,age=21}，并且使用Redis自动生成ID
127.0.0.1:6379> XADD users * name jack age 21
"1644805700523-0"
```

读取消息的方式之一：`XREAD`

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031445972.png)

例如，使用XREAD读取第一个消息：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031445973.png)

XREAD阻塞方式，读取最新的消息：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031445974.png)

当我们指定起始ID为$时，代表读取最新的消息，如果我们处理一条消息的过程中，又有超过1条以上的消息到达队列，则下次获取时也只能获取到最新的一条，会出现`漏读消息`的问题。

**STREAM类型消息队列的XREAD命令特点：**

- 消息可回溯
- 一个消息可以被多个消费者读取
- 可以阻塞读取
- 有消息漏读的风险



#### 4. 基于Stream的消息队列-消费者组

**消费者组**（Consumer Group）：将多个消费者划分到一个组中，监听同一个队列。具备下列特点：

- **`消息分流`：**队列中的消息会分流给组内的不同消费者，而不是重复消费，从而加快消息处理的速度

- **`消息标示`：**消费者组会维护一个标示，记录最后一个被处理的消息，哪怕消费者宕机重启，还会从标示之后读取消息。确保每一个消息都会被消费

- **`消息确认`：**消费者获取消息后，消息处于pending状态，并存入一个pending-list。当处理完成后需要通过XACK来确认消息，标记消息为已处理，才会从pending-list移除。

创建消费者组：

```shell
XGROUP CREATE  key groupName ID [MKSTREAM]
```

- `key`：队列名称
- `groupName`：消费者组名称
- `ID`：起始ID标示，$代表队列中最后一个消息，0则代表队列中第一个消息
- `MKSTREAM`：队列不存在时自动创建队列

其它常见命令：

```shell
# 删除指定的消费者组
XGROUP DESTORY key groupName

# 给指定的消费者组添加消费者
XGROUP CREATECONSUMER key groupname consumername

# 删除消费者组中的指定消费者
XGROUP DELCONSUMER key groupname consumername
```

从消费者组读取消息：

```shell
XREADGROUP GROUP group consumer [COUNT count] [BLOCK milliseconds] [NOACK] STREAMS key [key ...] ID [ID ...]
```

- `group`：消费组名称
- `consumer`：消费者名称，如果消费者不存在，会自动创建一个消费者
- `count`：本次查询的最大数量
- `BLOCK milliseconds`：当没有消息时最长等待时间
- `NOACK`：无需手动ACK，获取到消息后自动确认
- `STREAMS key`：指定队列名称
- `ID`：获取消息的起始ID：
  - ">"：从下一个未消费的消息开始
  - 其它：根据指定id从pending-list中获取已消费但未确认的消息，例如0，是从pending-list中的第一个消息开始

**STREAM类型消息队列的XREADGROUP命令特点：**

- 消息可回溯
- 可以多消费者争抢消息，加快消费速度
- 可以阻塞读取
- 没有消息漏读的风险
- 有消息确认机制，保证消息至少被消费一次

|              | List                                     | PubSub             | Stream                                                 |
| ------------ | ---------------------------------------- | ------------------ | ------------------------------------------------------ |
| 消息持久化   | 支持                                     | 不支持             | 支持                                                   |
| 阻塞读取     | 支持                                     | 支持               | 支持                                                   |
| 消息堆积处理 | 受限于内存空间，可以利用多消费者加快处理 | 受限于消费者缓冲区 | 受限于队列长度，可以利用消费者组提高消费速度，减少堆积 |
| 消息确认机制 | 不支持                                   | 不支持             | 支持                                                   |
| 消息回溯     | 不支持                                   | 不支持             | 支持                                                   |





## 3. HyperLogLog

首先我们搞懂两个概念：

- UV：全称Unique Visitor，也叫独立访客量，是指通过互联网访问、浏览这个网页的自然人。1天内同一个用户多次访问该网站，只记录1次。
- PV：全称Page View，也叫页面访问量或点击量，用户每访问网站的一个页面，记录1次PV，用户多次打开页面，则记录多次PV。往往用来衡量网站的流量。

UV统计在服务端做会比较麻烦，因为要判断该用户是否已经统计过了，需要将统计过的用户信息保存。但是如果每个访问的用户都保存到Redis中，数据量会非常恐怖。

Hyperloglog(HLL)是从Loglog算法派生的概率算法，用于确定非常大的集合的基数，而不需要存储其所有值。相关算法原理大家可以参考：[https://juejin.cn/post/6844903785744056333#heading-0](https://juejin.cn/post/6844903785744056333)

Redis中的HLL是基于string结构实现的，单个HLL的内存永远小于16kb，内存占用低的令人发指！作为代价，其测量结果是概率性的，有小于0.81％的误差。不过对于UV统计来说，这完全可以忽略。

HyperLogLog的作用：

- 做海量数据的统计工作

HyperLogLog的优点：

- 内存占用极低
- 性能非常好

HyperLogLog的缺点：

- 有一定的误差

Pipeline导入数据

如果要导入大量数据到Redis中，可以有多种方式：

- 每次一条，for循环写入
- 每次多条，批量写入











