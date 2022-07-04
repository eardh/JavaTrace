# Zookeeper

## 1. 初识 Zookeeper

- Zookeeper 是 Apache Hadoop 项目下的一个子项目，是一个树形目录服务。

- Zookeeper 翻译过来就是 动物园管理员，他是用来管 Hadoop（大象）、Hive(蜜蜂)、Pig(小 猪)的管理员。简称zk

- Zookeeper 是一个分布式的、开源的分布式应用程序的协调服务。

- Zookeeper 提供的主要功能包括：

  - 配置管理

    ![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202207041058878.png)

  - 分布式锁

    ![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202207041058879.png)

  - 集群管理

    ![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202207041058880.png)





## 2. 安装与配置

[Zookeeper官网](https://zookeeper.apache.org/)

### 1. 下载安装

**1、环境准备**

ZooKeeper服务器是用Java创建的，它运行在JVM之上。需要安装JDK 7或更高版本。

**2、上传**

将下载的ZooKeeper放到/opt/zookeeper目录下

```shell
#打开 opt目录
cd /opt

#创建zooKeeper目录
mkdir zookeeper

#将zookeeper安装包移动到 /opt/zooKeeper
mv apache-zookeeper-3.8.0-bin.tar.gz /opt/zookeeper/
```

**3、解压**

将tar包解压到/opt/zookeeper目录下

```shell
tar -zxvf apache-zookeeper-3.8.0-bin.tar.gz 
```



### 2. 配置启动

**1、配置zoo.cfg**

进入到conf目录拷贝一个zoo_sample.cfg并完成配置

```shell
#进入到conf目录
cd /opt/zookeeper/apache-zookeeper-3.8.0-bin/conf/

#拷贝
cp zoo_sample.cfg zoo.cfg
```

修改zoo.cfg

```shell
#打开目录
cd /opt/zookeeper/

#创建zooKeeper存储目录
mkdir zkdata

#修改zoo.cfg
vim /opt/zookeeper/apache-zookeeper-3.8.0-bin/conf/zoo.cfg
# 修改存储目录：dataDir=/opt/zookeeper/zkdata
```

**2、启动ZooKeeper**

```shell
cd /opt/zookeeper/apache-zookeeper-3.8.0-bin/bin/

#启动
./zkServer.sh start
```

**3、查看ZooKeeper状态**

```shell
./zkServer.sh status
```

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202207041058881.png)

standalone代表zk没有搭建集群，现在是单节点





## 3. 命令操作

### 1. 数据模型

- ZooKeeper 是一个树形目录服务,其数据模型和Unix的文件系统目录树很类似，拥有一个层次化结构。
- 这里面的每一个节点都被称为： ZNode，每个节点上都会保存自己的数据和节点信息。
- 节点可以拥有子节点，同时也允许少量（1MB）数据存储在该节点之下。

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202207041058882.png)

- 节点可以分为四大类：
  - `PERSISTENT` 持久化节点
  - `EPHEMERAL` 临时节点 ：-e
  - `PERSISTENT_SEQUENTIAL` 持久化顺序节点 ：-s
  - `EPHEMERAL_SEQUENTIAL` 临时顺序节点 ：-es



### 2. 服务端常用命令

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202207041058883.png)

- 启动 ZooKeeper 服务: `./zkServer.sh start`
- 查看 ZooKeeper 服务状态: `./zkServer.sh status`
- 停止 ZooKeeper 服务: `./zkServer.sh stop`
- 重启 ZooKeeper 服务: `./zkServer.sh restart`



### 3. 客户端常用命令

- 连接ZooKeeper服务端

  ```c
  ./zkCli.sh -server ip:port
  ```

- 断开连接

  ```c
  quit
  ```

- 创建节点

  ```c
  create /节点path value
  ```

- 创建临时节点

  ```c
  create -e /节点path value
  ```

- 创建顺序节点

  ```c
  create -s /节点path value
  ```

- 显示指定目录下节点

  ```c
  ls 目录
  ```

- 查询节点详细信息

  ```c
  ls –s /节点path 
  ```

  > - czxid：节点被创建的事务ID
  > - ctime: 创建时间
  > - mzxid: 最后一次被更新的事务ID 
  > - mtime: 修改时间 
  > - pzxid：子节点列表最后一次被更新的事务ID
  > - cversion：子节点的版本号
  > - dataversion：数据版本号
  > - aclversion：权限版本号
  > - ephemeralOwner：用于临时节点，代表临时节点的事务ID，如果为持久节点则为0
  > - dataLength：节点存储的数据的长度
  > - numChildren：当前节点的子节点个数 

- 获取节点值

  ```c
  get /节点path
  ```

- 设置节点值

  ```c
  set /节点path value
  ```

- 删除单个节点

  ```c
  delete /节点path
  ```

- 删除带有子节点的节点

  ```c
  deleteall /节点path
  ```

- 查看命令帮助

  ```c
  help
  ```





## 4. JavaAPI 操作

### 1. Curator 介绍

- Curator 是 Apache ZooKeeper 的Java客户端库。
- 常见的ZooKeeper Java API ：
  - 原生Java API
  - ZkClient
  - Curator

- Curator 项目的目标是简化 ZooKeeper 客户端的使用。
- Curator 最初是 Netfix 研发的,后来捐献了 Apache 基金会，目前是 Apache 的顶级项目。
- 官网：http://curator.apache.org/



### 2. Curator API 常用操作

- **建立连接**

  ```java
  private CuratorFramework client;
  
  /**
   * 建立连接
   */
  @Before
  public void testConnect() {
      RetryPolicy retryPolicy = new ExponentialBackoffRetry(3000, 10);
      client = CuratorFrameworkFactory.builder()
          .connectString("192.168.111.129:2181") // 连接字符串, zk server 地址和端口 "192.168.111.129:2181,..."
          .sessionTimeoutMs(60 * 1000)           // 会话超时时间 单位ms
          .connectionTimeoutMs(15 * 1000)        // 连接超时时间 单位ms
          .retryPolicy(retryPolicy)              // 重试策略
          .namespace("eardh")
          .build();
      // 开启连接
      client.start();
  }
  ```

- **添加节点**

  ```java
  /**
   * 创建节点：create 持久 临时 顺序 数据
   * 1. 基本创建 : create().forPath("")
   * 2. 创建节点 带有数据: create().forPath("",data)
   * 3. 设置节点的类型 : create().withMode().forPath("",data)
   * 4. 创建多级节点create().creatingParentsIfNeeded().forPath("",data)
   */
  @Test
  public void testCreate() throws Exception {
      //创建节点 带有数据
      //如果创建节点，没有指定数据，则默认将当前客户端的ip作为数据存储
      String path = client.create().forPath("/app2", "hehe".getBytes());
      System.out.println(path);
  }
  ```

- **删除节点**

  ```java
  /**
   * 删除节点： delete deleteall
   * 1. 删除单个节点 : delete().forPath("/app1");
   * 2. 删除带有子节点的节点 : delete().deletingChildrenIfNeeded().forPath("/app1");
   * 3. 必须成功的删除 : 为了防止网络抖动。本质就是重试。  client.delete().guaranteed().forPath("/app2");
   * 4. 回调：inBackground
   */
  @Test
  public void testDelete() throws Exception {
      // 删除单个节点
      client.delete().forPath("/app1");
  }
  
  @Test
  public void testDelete4() throws Exception {
      // 删除回调
      client.delete().guaranteed().inBackground((client, event) -> {
          System.out.println("已删除");
          System.out.println(event);
      }).forPath("/app1");
  }
  ```

- **修改节点**

  ```java
  /**
   * 修改数据
   * 1. 基本修改数据：setData().forPath()
   * 2. 根据版本修改: setData().withVersion().forPath()
   *    - version 是通过查询出来的。目的就是为了让其他客户端或者线程不干扰
   */
  @Test
  public void testSet() throws Exception {
      client.setData().forPath("/app1", "itcast".getBytes());
  }
  ```

- **查询节点**

  ```java
  /**
   * 查询节点：
   * 1. 查询数据：get: getData().forPath()
   * 2. 查询子节点： ls: getChildren().forPath()
   * 3. 查询节点状态信息：ls -s:getData().storingStatIn(状态对象).forPath()
   */
  @Test
  public void testGet1() throws Exception {
      // 查询数据：get
      byte[] data = client.getData().forPath("/app1");
      System.out.println(new String(data));
  }
  ```

- **Watch事件监听**

  - ZooKeeper 允许用户在指定节点上注册一些Watcher，并且在一些特定事件触发的时候，ZooKeeper 服务端会将事件通知到感兴趣的客户端上去，该机制是 ZooKeeper 实现分布式协调服务的重要特性。
  - ZooKeeper 中引入了Watcher机制来实现了发布/订阅功能能，能够让多个订阅者同时监听某一个对象，当一个对象自身状态变化时，会通知所有订阅者。
  - ZooKeeper 原生支持通过注册Watcher来进行事件监听，但是其使用并不是特别方便

    需要开发人员自己反复注册Watcher，比较繁琐。

  ```xml
  <!--curator依赖-->
  <dependency>
      <groupId>org.apache.curator</groupId>
      <artifactId>curator-framework</artifactId>
      <version>5.2.1</version>
  </dependency>
  <dependency>
      <groupId>org.apache.curator</groupId>
      <artifactId>curator-recipes</artifactId>
      <version>5.2.1</version>
  </dependency>
  ```

  - Curator引入了 Cache 来实现对 ZooKeeper 服务端事件的监听。

  - ZooKeeper提供了Watcher，由`CuratorCache.Options.SINGLE_NODE_CACHE`来控制使用哪种模式

    - 只是监听某一个特定的节点

      ```java
      @Test
      public void testCuratorCache() {
          //1. 创建CuratorCache对象
          CuratorCache curatorCache = CuratorCache
              .build(client, "/app1", CuratorCache.Options.SINGLE_NODE_CACHE);
          //2. 注册监听
          curatorCache.listenable().addListener((type, oldData, data) -> {
              System.out.printf("节点 %s 改变 : %s --> %s%n",
                                data.getPath(),
                                new String(oldData.getData(), StandardCharsets.UTF_8),
                                new String(data.getData(), StandardCharsets.UTF_8));
          });
      
          // 3. 开启监听
          curatorCache.start();
          new Scanner(System.in).nextLine();
      }
      ```

    - 可以监控整个树上的所有节点

      ```java
      @Test
      public void testCuratorCache() {
          //1. 创建CuratorCache对象
          CuratorCache curatorCache = CuratorCache
              .build(client, "/app1");
          //2. 注册监听
          curatorCache.listenable().addListener((type, oldData, data) -> {
              System.out.printf("节点 %s 改变 : %s --> %s%n",
                                data.getPath(),
                                new String(oldData.getData(), StandardCharsets.UTF_8),
                                new String(data.getData(), StandardCharsets.UTF_8));
          });
      
          // 3. 开启监听
          curatorCache.start();
          new Scanner(System.in).nextLine();
      }
      ```



### 3. 分布式锁

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202207041058884.png)

- 在我们进行单机应用开发，涉及并发同步的时候，我们往往采用synchronized或者Lock的方式来解决多线程间的代码同步问题，这时多线程的运行都是在同一个JVM之下，没有任何问题。
- 但当我们的应用是分布式集群工作的情况下，属于多JVM下的工作环境，跨JVM之间已经无法通过多线程的锁解决同步问题。
- 那么就需要一种更加高级的锁机制，来处理种跨机器的进程之间的数据同步问题——这就是分布式锁。

**ZooKeeper分布式锁原理**

核心思想：当客户端要获取锁，则创建节点，使用完锁，则删除该节点。

1. 客户端获取锁时，在lock节点下创建临时顺序节点。

2. 然后获取lock下面的所有子节点，客户端获取到所有的子节点之后，如果发现自己创建的子节点序号最小，那么就认为该客户端获取到了锁。使用完锁后，将该节点删除。

3. 如果发现自己创建的节点并非lock所有子节点中最小的，说明自己还没有获取到锁，此时客户端需要找到比自己小的那个节点，同时对其注册事件监听器，监听删除事件。

4. 如果发现比自己小的那个节点被删除，则客户端的Watcher会收到相应通知，此时再次判断自己创建的节点是否是lock子节点中序号最小的，如果是则获取到了锁，如果不是则重复以上步骤继续获取到比自己小的一个节点并注册监听。



### 4. 模拟12306售票案例

在Curator中有五种锁方案：

- `InterProcessSemaphoreMutex`：分布式排它锁（非可重入锁）
- `InterProcessMutex`：分布式可重入排它锁
- `InterProcessReadWriteLock`：分布式读写锁
- `InterProcessMultiLock`：将多个锁作为单个实体管理的容器
- `InterProcessSemaphoreV2`：共享信号量

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202207041058885.png)

```java
public class LockTest {

    static class TicketCount {
        int tickets = 15;
    }

    public static void main(String[] args) throws InterruptedException {
        TicketCount ticketCount = new TicketCount();
        CountDownLatch downLatch = new CountDownLatch(3);
        TicketClient client1 = new TicketClient(ticketCount, downLatch);
        TicketClient client2 = new TicketClient(ticketCount, downLatch);
        TicketClient client3 = new TicketClient(ticketCount, downLatch);

        // 创建客户端
        Thread t1 = new Thread(client1,"携程");
        Thread t2 = new Thread(client2,"飞猪");
        Thread t3 = new Thread(client3,"12306");

        t1.start();
        t2.start();
        t3.start();

        downLatch.await();
        t1.interrupt();
        t2.interrupt();
        t3.interrupt();
    }
}
```

```java
public class TicketClient implements Runnable {

    private LockTest.TicketCount ticketCount;   // 数据库的票数

    private final InterProcessMutex lock;  // 分布式可重入排他锁

    private final CountDownLatch downLatch;

    public TicketClient(LockTest.TicketCount ticketCount, CountDownLatch downLatch) {
        this.ticketCount = ticketCount;
        this.downLatch = downLatch;
        RetryPolicy retryPolicy = new ExponentialBackoffRetry(3000, 10);
        CuratorFramework client = CuratorFrameworkFactory.builder()
                .connectString("192.168.111.129:2181") // 连接字符串, zk server 地址和端口 "192.168.111.129:2181,..."
                .sessionTimeoutMs(60 * 1000)           // 会话超时时间 单位ms
                .connectionTimeoutMs(15 * 1000)        // 连接超时时间 单位ms
                .retryPolicy(retryPolicy)              // 重试策略
                .namespace("eardh")
                .build();
        // 开启连接
        client.start();
        lock = new InterProcessMutex(client, "/lock");
    }

    @Override
    public void run() {
        while (true) {
            try {
                // 获取锁
                lock.acquire();
                if (ticketCount.tickets < 1) {
                    break;
                } else {
                    System.out.println(Thread.currentThread() + ":" + ticketCount.tickets--);
                }
            } catch (Exception e) {
                e.printStackTrace();
            } finally {
                // 释放锁
                try {
                    lock.release();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        }
        downLatch.countDown();
    }
}
```





## 5. 集群

###  1. 集群介绍

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202207041058886.png)

Leader选举：

- `Serverid`：服务器ID

  比如有三台服务器，编号分别是1,2,3。编号越大在选择算法中的权重越大。

- `Zxid`：数据ID

  服务器中存放的最大数据ID值越大说明数据越新，在选举算法中数据越新权重越大。

在Leader选举的过程中，如果某台ZooKeeper获得了超过半数的选票，则此ZooKeeper就可以成为Leader了。



### 2. 集群搭建

#### 1. 搭建要求

真实的集群是需要部署在不同的服务器上的，但是在我们测试时同时启动很多个虚拟机内存会吃不消，所以我们通常会搭建**伪集群**，也就是把所有的服务都搭建在一台虚拟机上，用端口进行区分。

我们这里要求搭建一个三个节点的Zookeeper集群（伪集群）。



#### 2. 准备工作

重新部署一台虚拟机作为我们搭建集群的测试服务器。

1. 安装JDK。

2. Zookeeper压缩包上传到服务器

3. 将Zookeeper解压 ，建立/usr/local/zookeeper-cluster目录，将解压后的Zookeeper复制到以下三个目录

   /usr/local/zookeeper-cluster/zookeeper-1

   /usr/local/zookeeper-cluster/zookeeper-2

   /usr/local/zookeeper-cluster/zookeeper-3

```shell
mkdir /usr/local/zookeeper-cluster

cp -r  apache-zookeeper-3.8.0-bin /usr/local/zookeeper-cluster/zookeeper-1

cp -r  apache-zookeeper-3.8.0-bin /usr/local/zookeeper-cluster/zookeeper-2

cp -r  apache-zookeeper-3.8.0-bin /usr/local/zookeeper-cluster/zookeeper-3
```

4. 创建data目录 ，并且将 conf下zoo_sample.cfg 文件改名为 zoo.cfg

```shell
mkdir /usr/local/zookeeper-cluster/zookeeper-1/data
mkdir /usr/local/zookeeper-cluster/zookeeper-2/data
mkdir /usr/local/zookeeper-cluster/zookeeper-3/data

mv /usr/local/zookeeper-cluster/zookeeper-1/conf/zoo_sample.cfg  /usr/local/zookeeper-cluster/zookeeper-1/conf/zoo.cfg

mv /usr/local/zookeeper-cluster/zookeeper-2/conf/zoo_sample.cfg  /usr/local/zookeeper-cluster/zookeeper-2/conf/zoo.cfg

mv /usr/local/zookeeper-cluster/zookeeper-3/conf/zoo_sample.cfg  /usr/local/zookeeper-cluster/zookeeper-3/conf/zoo.cfg
```

5.  配置每一个Zookeeper 的dataDir 和 clientPort 分别为2181  2182  2183

修改/usr/local/zookeeper-cluster/zookeeper-1/conf/zoo.cfg

```shell
vim /usr/local/zookeeper-cluster/zookeeper-1/conf/zoo.cfg

clientPort=2181
dataDir=/usr/local/zookeeper-cluster/zookeeper-1/data
```

修改/usr/local/zookeeper-cluster/zookeeper-2/conf/zoo.cfg

```shell
vim /usr/local/zookeeper-cluster/zookeeper-2/conf/zoo.cfg

clientPort=2182
dataDir=/usr/local/zookeeper-cluster/zookeeper-2/data
```

修改/usr/local/zookeeper-cluster/zookeeper-3/conf/zoo.cfg

```shell
vim /usr/local/zookeeper-cluster/zookeeper-3/conf/zoo.cfg

clientPort=2183
dataDir=/usr/local/zookeeper-cluster/zookeeper-3/data
```




#### 3. 配置集群

1. 在每个zookeeper的 data 目录下创建一个 myid 文件，内容分别是1、2、3 。这个文件就是记录每个服务器的ID

```shell
echo 1 > /usr/local/zookeeper-cluster/zookeeper-1/data/myid

echo 2 > /usr/local/zookeeper-cluster/zookeeper-2/data/myid

echo 3 > /usr/local/zookeeper-cluster/zookeeper-3/data/myid
```

2. 在每一个zookeeper 的 zoo.cfg配置客户端访问端口（clientPort）和集群服务器IP列表。

集群服务器IP列表如下

```shell
vim /usr/local/zookeeper-cluster/zookeeper-1/conf/zoo.cfg
vim /usr/local/zookeeper-cluster/zookeeper-2/conf/zoo.cfg
vim /usr/local/zookeeper-cluster/zookeeper-3/conf/zoo.cfg

server.1=192.168.111.129:2881:3881
server.2=192.168.111.129:2882:3882
server.3=192.168.111.129:2883:3883
```

解释：server.服务器ID=服务器IP地址：服务器之间通信端口：服务器之间投票选举端口



#### 4. 启动集群

启动集群就是分别启动每个实例。

```shell
/usr/local/zookeeper-cluster/zookeeper-1/bin/zkServer.sh start
/usr/local/zookeeper-cluster/zookeeper-2/bin/zkServer.sh start
/usr/local/zookeeper-cluster/zookeeper-3/bin/zkServer.sh start 
```

启动后我们查询一下每个实例的运行状态

```shell
/usr/local/zookeeper-cluster/zookeeper-1/bin/zkServer.sh status

/usr/local/zookeeper-cluster/zookeeper-2/bin/zkServer.sh status

/usr/local/zookeeper-cluster/zookeeper-3/bin/zkServer.sh status
```

先查询第一个服务 

Mode为follower表示是**跟随者**（从）

再查询第二个服务Mod 为leader表示是**领导者**（主） 

查询第三个为跟随者（从） 



#### 5. 模拟集群异常

1. 首先我们先测试如果是从服务器挂掉，会怎么样

把3号服务器停掉，观察1号和2号，发现状态并没有变化

```shell
/usr/local/zookeeper-cluster/zookeeper-3/bin/zkServer.sh stop

/usr/local/zookeeper-cluster/zookeeper-1/bin/zkServer.sh status

/usr/local/zookeeper-cluster/zookeeper-2/bin/zkServer.sh status 
```

由此得出结论，3个节点的集群，从服务器挂掉，集群正常

2. 我们再把1号服务器（从服务器）也停掉，查看2号（主服务器）的状态，发现已经停止运行了。

```shell
/usr/local/zookeeper-cluster/zookeeper-1/bin/zkServer.sh stop

/usr/local/zookeeper-cluster/zookeeper-2/bin/zkServer.sh status 
```

由此得出结论，3个节点的集群，2个从服务器都挂掉，主服务器也无法运行。因为可运行的机器没有超过集群总数量的半数。

3. 我们再次把1号服务器启动起来，发现2号服务器又开始正常工作了。而且依然是领导者。

```shell
/usr/local/zookeeper-cluster/zookeeper-1/bin/zkServer.sh start

/usr/local/zookeeper-cluster/zookeeper-2/bin/zkServer.sh status 
```

4. 我们把3号服务器也启动起来，把2号服务器停掉,停掉后观察1号和3号的状态。

```shell
/usr/local/zookeeper-cluster/zookeeper-3/bin/zkServer.sh start

/usr/local/zookeeper-cluster/zookeeper-2/bin/zkServer.sh stop

/usr/local/zookeeper-cluster/zookeeper-1/bin/zkServer.sh status

/usr/local/zookeeper-cluster/zookeeper-3/bin/zkServer.sh status 
```

发现新的leader产生了~  

由此我们得出结论，当集群中的主服务器挂了，集群中的其他服务器会自动进行选举状态，然后产生新得leader 

5. 我们再次测试，当我们把2号服务器重新启动起来启动后，会发生什么？2号服务器会再次成为新的领导吗？我们看结果

```shell
/usr/local/zookeeper-cluster/zookeeper-2/bin/zkServer.sh start

/usr/local/zookeeper-cluster/zookeeper-2/bin/zkServer.sh status

/usr/local/zookeeper-cluster/zookeeper-3/bin/zkServer.sh status 
```

我们会发现，2号服务器启动后依然是跟随者（从服务器），3号服务器依然是领导者（主服务器），没有撼动3号服务器的领导地位。

由此我们得出结论，当领导者产生后，再次有新服务器加入集群，不会影响到现任领导者。





## 6. 核心理论

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202207041058887.png)

在ZooKeeper集群服中务中有三个角色：

- Leader 领导者 ：     
  1. 处理事务请求
  2. 集群内部各服务器的调度者

- Follower 跟随者 ：
  1. 处理客户端非事务请求，转发事务请求给Leader服务器
  2. 参与Leader选举投票

- Observer 观察者：
  - 处理客户端非事务请求，转发事务请求给Leader服务器



