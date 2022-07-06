# RabbitMQ

## 1. MQ 的基本概念

### 1. MQ 概述

MQ全称**Message Queue**（消息队列），是在消息的传输过程中保存消息的容器。多用于分布式系统之间进行通信。

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202207060229607.png)

**小结**

- MQ，消息队列，存储消息的中间件
- 分布式系统通信两种方式：直接远程调用和借助第三方完成间接通信
- 发送方称为生产者，接收方称为消费者



### 2. MQ 的优势

**1. 应用解耦**

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202207060229608.png)

使用MQ 使得应用间解耦，提升容错性和可维护性。

**2. 异步提速**

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202207060229609.png)

用户点击完下单按钮后，只需等待25ms就能得到下单响应(20 + 5 = 25ms)。

提升用户体验和系统吞吐量（单位时间内处理请求的数目）

**3. 削峰填谷**

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202207060229612.png)

使用了MQ 之后，限制消费消息的速度为1000，这样一来，高峰期产生的数据势必会被积压在MQ 中，高峰就被“削”掉了，但是因为消息积压，在高峰期过后的一段时间内，消费消息的速度还是会维持在1000，直到消费完积压的消息，这就叫做“填谷”。使用MQ后，可以提高系统稳定性。

**4. 小结**

- 应用解耦：提高系统容错性和可维护性
- 异步提速：提升用户体验和系统吞吐量
- 削峰填谷：提高系统稳定性



### 3. MQ 的劣势

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202207060229613.png)

- **系统可用性降低**

  系统引入的外部依赖越多，系统稳定性越差。一旦MQ 宕机，就会对业务造成影响。如何保证MQ的高可用？

- **系统复杂度提高**

  MQ 的加入大大增加了系统的复杂度，以前系统间是同步的远程调用，现在是通过MQ 进行异步调用。如何保证消息没有被重复消费？怎么处理消息丢失情况？那么保证消息传递的顺序性？

- **一致性问题**

  A 系统处理完业务，通过MQ 给B、C、D三个系统发消息数据，如果B 系统、C 系统处理成功，D 系统处理失败。如何保证消息数据处理的一致性

**小结**

既然MQ 有优势也有劣势，那么使用MQ 需要满足什么条件呢？

1. 生产者不需要从消费者处获得反馈。引入消息队列之前的直接调用，其接口的返回值应该为空，这才让明明下层的动作还没做，上层却当成动作做完了继续往后走，即所谓异步成为了可能。
2. 容许短暂的不一致性。
3. 确实是用了有效果。即解耦、提速、削峰这些方面的收益，超过加入MQ，管理MQ这些成本。



### 4. 常见的 MQ 产品

目前业界有很多的MQ 产品，例如RabbitMQ、RocketMQ、ActiveMQ、Kafka、ZeroMQ、MetaMq等，也有直接使用Redis 充当消息队列的案例，而这些消息队列产品，各有侧重，在实际选型时，需要结合自身需求及MQ 产品特征，综合考虑

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202207060229614.png)

由于RabbitMQ综合能力强劲，所以接下来的课程中，我们将主要学习RabbitMQ。



### 5. RabbitMQ 简介

`AMQP`，即Advanced Message Queuing Protocol（高级消息队列协议），是一个网络协议，是应用层协议的一个开放标准，为面向消息的中间件设计。基于此协议的客户端与消息中间件可传递消息，并不受客户端/中间件不同产品，不同的开发语言等条件的限制。2006年，AMQP规范发布。类比HTTP。

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202207060229615.png)

2007年，Rabbit技术公司基于AMQP标准开发的RabbitMQ 1.0 发布。RabbitMQ采用Erlang语言开发。Erlang语言由Ericson设计，专门为开发高并发和分布式系统的一种语言，在电信领域使用广泛。

RabbitMQ 基础架构如下图：

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202207060229616.png)

RabbitMQ 中的相关概念：

- `Broker`：接收和分发消息的应用，RabbitMQ Server就是Message Broker
- `Virtual host`：出于多租户和安全因素设计的，把AMQP 的基本组件划分到一个虚拟的分组中，类似于网络中的namespace 概念。当多个不同的用户使用同一个RabbitMQ server 提供的服务时，可以划分出多个vhost，每个用户在自己的vhost 创建exchange／queue 等
- `Connection`：publisher／consumer 和broker 之间的TCP 连接
- `Channel`：如果每一次访问RabbitMQ 都建立一个Connection，在消息量大的时候建立TCP Connection的开销将是巨大的，效率也较低。Channel 是在connection 内部建立的逻辑连接，如果应用程序支持多线程，通常每个thread创建单独的channel 进行通讯，AMQP method 包含了channel id 帮助客户端和message broker 识别channel，所以channel 之间是完全隔离的。Channel 作为轻量级的Connection 极大减少了操作系统建立TCP connection 的开销

- `Exchange`：message 到达broker 的第一站，根据分发规则，匹配查询表中的routing key，分发消息到queue 中去。常用的类型有：direct (point-to-point), topic (publish-subscribe) and fanout (multicast)
- `Queue`：消息最终被送到这里等待consumer 取走
- `Binding`：exchange 和queue 之间的虚拟连接，binding 中可以包含routing key。Binding 信息被保存到exchange 中的查询表中，用于message 的分发依据

RabbitMQ提供了6种**工作模式**：简单模式、workqueues、Publish/Subscribe发布与订阅模式、Routing路由模式、Topics主题模式、RPC远程调用模式（远程调用，不太算MQ；暂不作介绍）。

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202207060229617.png)

官网对应模式介绍：https://www.rabbitmq.com/getstarted.html



### 6. JMS

- JMS即Java消息服务（JavaMessage Service）应用程序接口，是一个Java平台中关于面向消息中间件的API
- JMS 是JavaEE 规范中的一种，类比JDBC
- 很多消息中间件都实现了JMS规范，例如：ActiveMQ。RabbitMQ 官方没有提供JMS 的实现包，但是开源社区有实现



### 7. 小结

1. RabbitMQ是基于AMQP 协议使用Erlang 语言开发的一款消息队列产品。
2. RabbitMQ提供了6种工作模式，我们学习5种。这是今天的重点。
3. AMQP 是协议，类比HTTP。
4. JMS 是API 规范接口，类比JDBC。



## 2. RabbitMQ 的安装和配置

### 1. 安装依赖环境

在线安装依赖环境：

```shell
yum -y install make gcc gcc-c++ kernel-devel m4 ncurses-devel openssl-devel unixODBC unixODBC-devel
```



### 2. 安装Erlang

https://www.erlang.org/downloads

`otp_src_25.0.2.tar.gz`上传至`/usr/local/tmp`

```sh
mkdir -p /usr/local/tmp
cd /usr/local/tmp

# 1. 解压
tar xf otp_src_25.0.2.tar.gz
```

```sh
cd otp_src_25.0.2

# 2. 配置参数、编译、安装
./configure && make && make install
```

```sh
# 5. 查看配置是否成功
erl -version
```

如果没有提示版本信息，可以按下步骤尝试：

```sh
vim /etc/profile

# 添加路径
export PATH=$PATH:/usr/local/lib/erlang/bin

# 重新执行配置
source /etc/profile
```



### 3. 安装RabbitMQ

下载Rabbitmq的rpm安装包，[download](https://github.com/rabbitmq/rabbitmq-server/releases)

```sh
# 1. 导入签名文件
rpm --import https://www.rabbitmq.com/rabbitmq-release-signing-key.asc
```

```sh
# 2. 安装依赖
yum install -y socat logrotate
```

```sh
# 3. 安装
rpm -ivh --nodeps rabbitmq-server-3.10.5-1.suse.noarch.rpm
```



### 4. 开启管理界面及配置

```sh
# 开启管理界面
rabbitmq-plugins enable rabbitmq_management

# 修改默认配置信息
vim /usr/lib/rabbitmq/lib/rabbitmq_server-3.10.5/plugins/rabbit-3.10.5/ebin/rabbit.app
# 比如修改密码、配置等等，例如：
{loopback_users, [guest]}
```




### 5. 启动

```sh
systemctl start rabbitmq-server   # 启动服务
systemctl stop rabbitmq-server    # 停止服务
systemctl restart rabbitmq-server # 重启服务
```



### 6. 配置虚拟主机及用户

#### 1. 用户角色

RabbitMQ在安装好后，可以访问`http://ip地址:15672` ；其自带了guest/guest的用户名和密码；如果需要创建自定义用户；那么也可以登录管理界面后，如下操作：

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202207060229618.png) 

**角色说明**：

1. 超级管理员(`administrator`)

   可登陆管理控制台，可查看所有的信息，并且可以对用户，策略(policy)进行操作。

2. 监控者(`monitoring`)

   可登陆管理控制台，同时可以查看rabbitmq节点的相关信息(进程数，内存使用情况，磁盘使用情况等)

3. 策略制定者(`policymaker`)

   可登陆管理控制台, 同时可以对policy进行管理。但无法查看节点的相关信息(上图红框标识的部分)。

4. 普通管理者(`management`)

   仅可登陆管理控制台，无法看到节点信息，也无法对策略进行管理。

5. 其他

   无法登陆管理控制台，通常就是普通的生产者和消费者。



#### 2. Virtual Hosts配置

像mysql拥有数据库的概念并且可以指定用户对库和表等操作的权限。RabbitMQ也有类似的权限管理；在RabbitMQ中可以虚拟消息服务器Virtual Host，每个Virtual Hosts相当于一个相对独立的RabbitMQ服务器，每个VirtualHost之间是相互隔离的。exchange、queue、message不能互通。 相当于mysql的db。Virtual Name一般以`/`开头。



##### 1. 创建Virtual Hosts

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202207060229619.png)



##### 2. 设置Virtual Hosts权限

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202207060229620.png)





## 3. RabbitMQ 快速入门

### 1. 入门程序

需求：使用简单模式完成消息传递

步骤：

① 创建工程（生成者、消费者）

② 分别添加依赖

③ 编写生产者发送消息

```java
public class Producer_HelloWorld {
    public static void main(String[] args) throws IOException, TimeoutException {

        //1.创建连接工厂
        ConnectionFactory factory = new ConnectionFactory();

        //2. 设置参数
        factory.setHost("192.168.111.129");//ip  默认值 localhost
        factory.setPort(5672); //端口  默认值 5672
        factory.setVirtualHost("/eardh");//虚拟机 默认值/
        factory.setUsername("guest"); //用户名 默认 guest
        factory.setPassword("guest"); //密码 默认值 guest

        //3. 创建连接 Connection
        Connection connection = factory.newConnection();

        //4. 创建Channel
        Channel channel = connection.createChannel();

        //5. 创建队列Queue
        /*
        queueDeclare(String queue, boolean durable, boolean exclusive, boolean autoDelete, Map<String, Object> arguments)
        参数：
            1. queue：队列名称
            2. durable:是否持久化，当mq重启之后，还在
            3. exclusive：
                * 是否独占。只能有一个消费者监听这队列
                * 当Connection关闭时，是否删除队列
                *
            4. autoDelete:是否自动删除。当没有Consumer时，自动删除掉
            5. arguments：参数。
         */
        //如果没有一个名字叫hello_world的队列，则会创建该队列，如果有则不会创建
        channel.queueDeclare("hello_world", true, false, false, null);

        /*
        basicPublish(String exchange, String routingKey, BasicProperties props, byte[] body)
        参数：
            1. exchange：交换机名称。简单模式下交换机会使用默认的 ""
            2. routingKey：路由名称
            3. props：配置信息
            4. body：发送的 消息数据
         */
        String body = "hello rabbitmq";
        //6. 发送消息
        channel.basicPublish("", "hello_world", null, body.getBytes());

        //7.释放资源
        channel.close();
        connection.close();
    }
}
```

④ 编写消费者接收消息

```java
public class Consumer_HelloWorld {
    public static void main(String[] args) throws IOException, TimeoutException {

        //1.创建连接工厂
        ConnectionFactory factory = new ConnectionFactory();

        //2. 设置参数
        factory.setHost("192.168.111.129");//ip  默认值 localhost
        factory.setPort(5672); //端口  默认值 5672
        factory.setVirtualHost("/eardh");//虚拟机 默认值/
        factory.setUsername("guest"); //用户名 默认 guest
        factory.setPassword("guest"); //密码 默认值 guest

        //3. 创建连接 Connection
        Connection connection = factory.newConnection();

        //4. 创建Channel
        Channel channel = connection.createChannel();

        //5. 创建队列Queue
        /*
        queueDeclare(String queue, boolean durable, boolean exclusive, boolean autoDelete, Map<String, Object> arguments)
        参数：
            1. queue：队列名称
            2. durable:是否持久化，当mq重启之后，还在
            3. exclusive：
                * 是否独占。只能有一个消费者监听这队列
                * 当Connection关闭时，是否删除队列
                *
            4. autoDelete:是否自动删除。当没有Consumer时，自动删除掉
            5. arguments：参数。
         */
        //如果没有一个名字叫hello_world的队列，则会创建该队列，如果有则不会创建
        channel.queueDeclare("hello_world", true, false, false, null);

        /*
        basicConsume(String queue, boolean autoAck, Consumer callback)
        参数：
            1. queue：队列名称
            2. autoAck：是否自动确认
            3. callback：回调对象
         */
        // 接收消息
        Consumer consumer = new DefaultConsumer(channel) {
            /*
                回调方法，当收到消息后，会自动执行该方法
                1. consumerTag：标识
                2. envelope：获取一些信息，交换机，路由key...
                3. properties：配置信息
                4. body：数据
             */
            @Override
            public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties, byte[] body) {
                System.out.println("consumerTag：" + consumerTag);
                System.out.println("Exchange：" + envelope.getExchange());
                System.out.println("RoutingKey：" + envelope.getRoutingKey());
                System.out.println("properties：" + properties);
                System.out.println("body：" + new String(body));
            }
        };
        channel.basicConsume("hello_world", true, consumer);

        //关闭资源？不要(消息持续监听)
    }
}
```



### 2. 小结

上述的入门案例中其实使用的是如下的简单模式：

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202207060229621.png)

在上图的模型中，有以下概念：

- P：生产者，也就是要发送消息的程序
- C：消费者：消息的接收者，会一直等待消息到来
- queue：消息队列，图中红色部分。类似一个邮箱，可以缓存消息；生产者向其中投递消息，消费者从其中取出消息





## 4. RabbitMQ 的工作模式

### 1. Work queues 模式

#### 1. 说明

工作队列模式

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202207060229622.png)

- Work Queues：与入门程序的简单模式相比，多了一个或一些消费端，多个消费端共同消费同一个队列中的消息。

- 应用场景：对于任务过重或任务较多情况使用工作队列可以提高任务处理的速度。



#### 2. 代码

Work Queues 与入门程序的简单模式的代码几乎是一样的。可以完全复制，并多复制一个消费者进行多个消费者同时对消费消息的测试。

① 生产者发送消息

```java
public class Producer_WorkQueues {
    public static void main(String[] args) throws IOException, TimeoutException {

        //1.创建连接工厂
        ConnectionFactory factory = new ConnectionFactory();

        //2. 设置参数
        factory.setHost("192.168.111.129");//ip  默认值 localhost
        factory.setPort(5672); //端口  默认值 5672
        factory.setVirtualHost("/eardh");//虚拟机 默认值/
        factory.setUsername("guest"); //用户名 默认 guest
        factory.setPassword("guest"); //密码 默认值 guest

        //3. 创建连接 Connection
        Connection connection = factory.newConnection();

        //4. 创建Channel
        Channel channel = connection.createChannel();

        //5. 创建队列Queue
        /*
        queueDeclare(String queue, boolean durable, boolean exclusive, boolean autoDelete, Map<String, Object> arguments)
        参数：
            1. queue：队列名称
            2. durable:是否持久化，当mq重启之后，还在
            3. exclusive：
                * 是否独占。只能有一个消费者监听这队列
                * 当Connection关闭时，是否删除队列
                *
            4. autoDelete:是否自动删除。当没有Consumer时，自动删除掉
            5. arguments：参数。
         */
        //如果没有一个名字叫hello_world的队列，则会创建该队列，如果有则不会创建
        channel.queueDeclare("work_queues", true, false, false, null);

        /*
        basicPublish(String exchange, String routingKey, BasicProperties props, byte[] body)
        参数：
            1. exchange：交换机名称。简单模式下交换机会使用默认的 ""
            2. routingKey：路由名称
            3. props：配置信息
            4. body：发送消息数据
         */
        for (int i = 1; i <= 10; i++) {
            String body = i + "hello rabbitmq~~~";
            //6. 发送消息
            channel.basicPublish("", "work_queues", null, body.getBytes());
        }

        //7.释放资源
        channel.close();
        connection.close();
    }
}
```

② 接收者接受消息，可启动多个

```java
public class Consumer_HelloWorld {
    public static void main(String[] args) throws IOException, TimeoutException {

        //1.创建连接工厂
        ConnectionFactory factory = new ConnectionFactory();

        //2. 设置参数
        factory.setHost("192.168.111.129");//ip  默认值 localhost
        factory.setPort(5672); //端口  默认值 5672
        factory.setVirtualHost("/eardh");//虚拟机 默认值/
        factory.setUsername("guest"); //用户名 默认 guest
        factory.setPassword("guest"); //密码 默认值 guest

        //3. 创建连接 Connection
        Connection connection = factory.newConnection();

        //4. 创建Channel
        Channel channel = connection.createChannel();

        //5. 创建队列Queue
        /*
        queueDeclare(String queue, boolean durable, boolean exclusive, boolean autoDelete, Map<String, Object> arguments)
        参数：
            1. queue：队列名称
            2. durable:是否持久化，当mq重启之后，还在
            3. exclusive：
                * 是否独占。只能有一个消费者监听这队列
                * 当Connection关闭时，是否删除队列
                *
            4. autoDelete:是否自动删除。当没有Consumer时，自动删除掉
            5. arguments：参数。
         */
        //如果没有一个名字叫hello_world的队列，则会创建该队列，如果有则不会创建
        channel.queueDeclare("hello_world", true, false, false, null);

        /*
        basicConsume(String queue, boolean autoAck, Consumer callback)
        参数：
            1. queue：队列名称
            2. autoAck：是否自动确认
            3. callback：回调对象
         */
        // 接收消息
        Consumer consumer = new DefaultConsumer(channel) {
            /*
                回调方法，当收到消息后，会自动执行该方法
                1. consumerTag：标识
                2. envelope：获取一些信息，交换机，路由key...
                3. properties：配置信息
                4. body：数据
             */
            @Override
            public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties, byte[] body) {
//                System.out.println("consumerTag：" + consumerTag);
//                System.out.println("Exchange：" + envelope.getExchange());
//                System.out.println("RoutingKey：" + envelope.getRoutingKey());
//                System.out.println("properties：" + properties);
                System.out.println("body：" + new String(body));
            }
        };
        channel.basicConsume("hello_world", true, consumer);

        //关闭资源？不要(消息持续监听)
    }
}
```



#### 3. 小结

1. 在一个队列中如果有多个消费者，那么消费者之间对于同一个消息的关系是竞争的关系。
2. Work Queues 对于任务过重或任务较多情况使用工作队列可以提高任务处理的速度。例如：短信服务部署多个，只需要有一个节点成功发送即可。



### 2. Pub/Sub 模式

#### 1. 说明

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202207060229623.png)

在订阅模型中，多了一个Exchange 角色，而且过程略有变化：

- `P`：生产者，也就是要发送消息的程序，但是不再发送到队列中，而是发给X（交换机）

- `C`：消费者，消息的接收者，会一直等待消息到来

- `Queue`：消息队列，接收消息、缓存消息

- `Exchange`：交换机（X）。一方面，接收生产者发送的消息。另一方面，知道如何处理消息，例如递交给某个特别队列、递交给所有队列、或是将消息丢弃。到底如何操作，取决于Exchange的类型。Exchange有常见以下3种类型：
  - `Fanout`：广播，将消息交给所有绑定到交换机的队列
  - `Direct`：定向，把消息交给符合指定routing key 的队列
  - `Topic`：通配符，把消息交给符合routing pattern（路由模式）的队列

**Exchange**（交换机）只负责转发消息，不具备存储消息的能力，因此如果没有任何队列与Exchange 绑定，或者没有符合路由规则的队列，那么消息会丢失！



#### 2. 代码

① 消息发布者

```java
public class Producer_PubSub {
    public static void main(String[] args) throws IOException, TimeoutException {

        //1.创建连接工厂
        ConnectionFactory factory = new ConnectionFactory();

        //2. 设置参数
        factory.setHost("192.168.111.129");//ip  默认值 localhost
        factory.setPort(5672); //端口  默认值 5672
        factory.setVirtualHost("/eardh");//虚拟机 默认值/
        factory.setUsername("guest"); //用户名 默认 guest
        factory.setPassword("guest"); //密码 默认值 guest

        //3. 创建连接 Connection
        Connection connection = factory.newConnection();

        //4. 创建Channel
        Channel channel = connection.createChannel();
       /*
       exchangeDeclare(String exchange, BuiltinExchangeType type, boolean durable, boolean autoDelete, boolean internal, Map<String, Object> arguments)
       参数：
        1. exchange:交换机名称
        2. type:交换机类型
            DIRECT("direct") : 定向
            FANOUT("fanout") : 扇形（广播），发送消息到每一个与之绑定队列。
            TOPIC("topic") : 通配符的方式
            HEADERS("headers") : 参数匹配
        3. durable:是否持久化
        4. autoDelete:自动删除
        5. internal:内部使用。一般false
        6. arguments:参数
        */
        String exchangeName = "test_fanout";
        //5. 创建交换机
        channel.exchangeDeclare(exchangeName, BuiltinExchangeType.FANOUT, true, false, false, null);

        //6. 创建队列
        String queue1Name = "test_fanout_queue1";
        String queue2Name = "test_fanout_queue2";
        channel.queueDeclare(queue1Name, true, false, false, null);
        channel.queueDeclare(queue2Name, true, false, false, null);

        //7. 绑定队列和交换机
        /*
        queueBind(String queue, String exchange, String routingKey)
            1. queue：队列名称
            2. exchange：交换机名称
            3. routingKey：路由键，绑定规则
               如果交换机的类型为fanout，routingKey设置为""
         */
        channel.queueBind(queue1Name, exchangeName, "");
        channel.queueBind(queue2Name, exchangeName, "");

        String body = "日志信息：张三调用了findAll方法...日志级别：info...";
        //8. 发送消息
        channel.basicPublish(exchangeName, "", null, body.getBytes());

        //9. 释放资源
        channel.close();
        connection.close();
    }
}
```

② 消息接收者代码与前面相同



#### 3. 小结

1. 交换机需要与队列进行绑定，绑定之后；一个消息可以被多个消费者都收到。
2. 发布订阅模式与工作队列模式的区别：
   - 工作队列模式不用定义交换机，而发布/订阅模式需要定义交换机
   - 发布/订阅模式的生产方是面向交换机发送消息，工作队列模式的生产方是面向队列发送消息(底层使用默认交换机)
   - 发布/订阅模式需要设置队列和交换机的绑定，工作队列模式不需要设置，实际上工作队列模式会将队列绑定到默认的交换机



### 3. Routing 模式

#### 1.  说明

- 队列与交换机的绑定，不能是任意绑定了，而是要指定一个RoutingKey（路由key）
- 消息的发送方在向Exchange 发送消息时，也必须指定消息的RoutingKey
- Exchange 不再把消息交给每一个绑定的队列，而是根据消息的Routing Key 进行判断，只有队列的Routingkey 与消息的Routing key 完全一致，才会接收到消息

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202207060229624.png)

- P：生产者，向Exchange 发送消息，发送消息时，会指定一个routing key
- X：Exchange（交换机），接收生产者的消息，然后把消息递交给与routing key 完全匹配的队列
- C1：消费者，其所在队列指定了需要routing key 为error 的消息
- C2：消费者，其所在队列指定了需要routing key 为info、error、warning 的消息



#### 2. 代码

① 消息生产者

```java
public class Producer_Routing {
    public static void main(String[] args) throws IOException, TimeoutException {

        //1.创建连接工厂
        ConnectionFactory factory = new ConnectionFactory();

        //2. 设置参数
        factory.setHost("192.168.111.129");//ip  默认值 localhost
        factory.setPort(5672); //端口  默认值 5672
        factory.setVirtualHost("/eardh");//虚拟机 默认值/
        factory.setUsername("guest"); //用户名 默认 guest
        factory.setPassword("guest"); //密码 默认值 guest

        //3. 创建连接 Connection
        Connection connection = factory.newConnection();

        //4. 创建Channel
        Channel channel = connection.createChannel();

       /*
       exchangeDeclare(String exchange, BuiltinExchangeType type, boolean durable, boolean autoDelete, boolean internal, Map<String, Object> arguments)
       参数：
        1. exchange:交换机名称
        2. type:交换机类型
            DIRECT("direct"),：定向
            FANOUT("fanout"),：扇形（广播），发送消息到每一个与之绑定队列。
            TOPIC("topic"),通配符的方式
            HEADERS("headers");参数匹配
        3. durable:是否持久化
        4. autoDelete:自动删除
        5. internal：内部使用。 一般false
        6. arguments：参数
        */
        String exchangeName = "test_direct";
        //5. 创建交换机
        channel.exchangeDeclare(exchangeName, BuiltinExchangeType.DIRECT, true, false, false, null);

        //6. 创建队列
        String queue1Name = "test_direct_queue1";
        String queue2Name = "test_direct_queue2";

        channel.queueDeclare(queue1Name, true, false, false, null);
        channel.queueDeclare(queue2Name, true, false, false, null);

        //7. 绑定队列和交换机
        /*
        queueBind(String queue, String exchange, String routingKey)
        参数：
            1. queue：队列名称
            2. exchange：交换机名称
            3. routingKey：路由键，绑定规则
               如果交换机的类型为fanout ，routingKey设置为""
         */
        //队列1绑定 error
        channel.queueBind(queue1Name, exchangeName, "error");
        //队列2绑定 info  error  warning
        channel.queueBind(queue2Name, exchangeName, "info");
        channel.queueBind(queue2Name, exchangeName, "error");
        channel.queueBind(queue2Name, exchangeName, "warning");

        String body = "日志信息：张三调用了delete方法...出错误了。。。日志级别：error...";
        //8. 发送消息
        channel.basicPublish(exchangeName, "warning", null, body.getBytes());

        //9. 释放资源
        channel.close();
        connection.close();
    }
}
```

② 消息消费者与前面相同，只需绑定队列即可。



#### 3. 小结

Routing 模式要求队列在绑定交换机时要指定routing key，消息会转发到符合routing key 的队列。



### 4. Topics 通配符模式

#### 1. 说明

- Topic 类型与Direct 相比，都是可以根据RoutingKey 把消息路由到不同的队列。只不过Topic 类型Exchange 可以让队列在绑定Routing key 的时候使用通配符！

- Routingkey 一般都是有一个或多个单词组成，多个单词之间以”.”分割，例如：item.insert 

- 通配符规则：

  例如：item.# 能够匹配item.insert.abc 或者item.insert，item.* 只能匹配item.insert

  - \# 匹配一个或多个词，
  - \* 匹配不多不少恰好1个词

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202207060229625.png)

- 红色Queue：绑定的是usa.# ，因此凡是以usa. 开头的routing key 都会被匹配到
- 黄色Queue：绑定的是#.news ，因此凡是以.news 结尾的routing key 都会被匹配



#### 2. 代码

①消息生产者

```java
public class Producer_Topics {
    public static void main(String[] args) throws IOException, TimeoutException {

        //1.创建连接工厂
        ConnectionFactory factory = new ConnectionFactory();

        //2. 设置参数
        factory.setHost("192.168.111.129");//ip  默认值 localhost
        factory.setPort(5672); //端口  默认值 5672
        factory.setVirtualHost("/eardh");//虚拟机 默认值/
        factory.setUsername("guest"); //用户名 默认 guest
        factory.setPassword("guest"); //密码 默认值 guest

        //3. 创建连接 Connection
        Connection connection = factory.newConnection();

        //4. 创建Channel
        Channel channel = connection.createChannel();

       /*
       exchangeDeclare(String exchange, BuiltinExchangeType type, boolean durable, boolean autoDelete, boolean internal, Map<String, Object> arguments)
       参数：
        1. exchange:交换机名称
        2. type:交换机类型
            DIRECT("direct"),：定向
            FANOUT("fanout"),：扇形（广播），发送消息到每一个与之绑定队列。
            TOPIC("topic"),通配符的方式
            HEADERS("headers");参数匹配

        3. durable:是否持久化
        4. autoDelete:自动删除
        5. internal：内部使用。 一般false
        6. arguments：参数
        */
        String exchangeName = "test_topic";
        //5. 创建交换机
        channel.exchangeDeclare(exchangeName, BuiltinExchangeType.TOPIC, true, false, false, null);

        //6. 创建队列
        String queue1Name = "test_topic_queue1";
        String queue2Name = "test_topic_queue2";
        channel.queueDeclare(queue1Name, true, false, false, null);
        channel.queueDeclare(queue2Name, true, false, false, null);

        //7. 绑定队列和交换机
        /*
        queueBind(String queue, String exchange, String routingKey)
        参数：
            1. queue：队列名称
            2. exchange：交换机名称
            3. routingKey：路由键，绑定规则
                如果交换机的类型为fanout ，routingKey设置为""
         */
        // routing key  系统的名称.日志的级别。
        // 需求： 所有error级别的日志存入数据库，所有order系统的日志存入数据库
        channel.queueBind(queue1Name, exchangeName, "#.error");
        channel.queueBind(queue1Name, exchangeName, "order.*");
        channel.queueBind(queue2Name, exchangeName, "*.*");

        String body = "日志信息：张三调用了findAll方法...日志级别：info...";
        //8. 发送消息
        channel.basicPublish(exchangeName, "goods.error", null, body.getBytes());

        //9. 释放资源
        channel.close();
        connection.close();

    }
}
```



#### 3. 小结

Topic 主题模式可以实现Pub/Sub 发布与订阅模式和Routing 路由模式的功能，只是Topic 在配置routing key 的时候可以使用通配符，显得更加灵活。



### 5. 工作模式总结

1. **简单模式HelloWorld**

   一个生产者、一个消费者，不需要设置交换机（使用默认的交换机）。

2. **工作队列模式Work Queue**

   一个生产者、多个消费者（竞争关系），不需要设置交换机（使用默认的交换机）。

3. **发布订阅模式Publish/subscribe**

   需要设置类型为fanout 的交换机，并且交换机和队列进行绑定，当发送消息到交换机后，交换机会将消息发送到绑定的队列。

4. **路由模式Routing**

   需要设置类型为direct 的交换机，交换机和队列进行绑定，并且指定routing key，当发送消息到交换机后，交换机会根据routing key 将消息发送到对应的队列。

5. **通配符模式Topic**

   需要设置类型为topic 的交换机，交换机和队列进行绑定，并且指定通配符方式的routing key，当发送消息到交换机后，交换机会根据routing key 将消息发送到对应的队列。





## 5. Spring 整合 RabbitMQ

### 1. spring 整合

#### 1. 生产者

① 添加依赖

```xml
<dependency>
    <groupId>org.springframework</groupId>
    <artifactId>spring-context</artifactId>
    <version>5.3.20</version>
</dependency>

<dependency>
    <groupId>org.springframework.amqp</groupId>
    <artifactId>spring-rabbit</artifactId>
    <version>2.4.4</version>
</dependency>
```

② 配置整合

- `rabbitmq.properties`

  ```properties
  rabbitmq.host=192.168.111.129
  rabbitmq.port=5672
  rabbitmq.username=guest
  rabbitmq.password=guest
  rabbitmq.virtual-host=/eardh
  ```

- `spring-rabbitmq-producer.xml`

  ```xml
  <?xml version="1.0" encoding="UTF-8"?>
  <beans xmlns="http://www.springframework.org/schema/beans"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xmlns:context="http://www.springframework.org/schema/context"
         xmlns:rabbit="http://www.springframework.org/schema/rabbit"
         xsi:schemaLocation="http://www.springframework.org/schema/beans
         http://www.springframework.org/schema/beans/spring-beans.xsd
         http://www.springframework.org/schema/context
         https://www.springframework.org/schema/context/spring-context.xsd
         http://www.springframework.org/schema/rabbit
         http://www.springframework.org/schema/rabbit/spring-rabbit.xsd">
      <!--加载配置文件-->
      <context:property-placeholder location="classpath:rabbitmq.properties"/>
  
      <!-- 定义rabbitmq connectionFactory -->
      <rabbit:connection-factory id="connectionFactory" host="${rabbitmq.host}"
                                 port="${rabbitmq.port}"
                                 username="${rabbitmq.username}"
                                 password="${rabbitmq.password}"
                                 virtual-host="${rabbitmq.virtual-host}"/>
      <!--定义管理交换机、队列-->
      <rabbit:admin connection-factory="connectionFactory"/>
  
      <!--定义持久化队列，不存在则自动创建；不绑定到交换机则绑定到默认交换机
      默认交换机类型为direct，名字为：""，路由键为队列的名称
      -->
      <!--
          id：bean的名称
          name：queue的名称
          auto-declare:自动创建
          auto-delete:自动删除。 最后一个消费者和该队列断开连接后，自动删除队列
          exclusive:是否独占
          durable：是否持久化
      -->
      <rabbit:queue id="spring_queue" name="spring_queue" auto-declare="true"/>
  
      <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~广播；所有队列都能收到消息~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
      <!--定义广播交换机中的持久化队列，不存在则自动创建-->
      <rabbit:queue id="spring_fanout_queue_1" name="spring_fanout_queue_1" auto-declare="true"/>
  
      <!--定义广播交换机中的持久化队列，不存在则自动创建-->
      <rabbit:queue id="spring_fanout_queue_2" name="spring_fanout_queue_2" auto-declare="true"/>
  
      <!--定义广播类型交换机；并绑定上述两个队列-->
      <rabbit:fanout-exchange id="spring_fanout_exchange" name="spring_fanout_exchange" auto-declare="true">
          <rabbit:bindings>
              <rabbit:binding queue="spring_fanout_queue_1"/>
              <rabbit:binding queue="spring_fanout_queue_2"/>
          </rabbit:bindings>
      </rabbit:fanout-exchange>
  
      <!--<rabbit:direct-exchange name="aa" >
          <rabbit:bindings>
              &lt;!&ndash;direct 类型的交换机绑定队列  key ：路由key  queue：队列名称&ndash;&gt;
              <rabbit:binding queue="spring_queue" key="xxx"></rabbit:binding>
          </rabbit:bindings>
  
      </rabbit:direct-exchange>-->
  
      <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~通配符；*匹配一个单词，#匹配多个单词 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
      <!--定义广播交换机中的持久化队列，不存在则自动创建-->
      <rabbit:queue id="spring_topic_queue_star" name="spring_topic_queue_star" auto-declare="true"/>
      <!--定义广播交换机中的持久化队列，不存在则自动创建-->
      <rabbit:queue id="spring_topic_queue_well" name="spring_topic_queue_well" auto-declare="true"/>
      <!--定义广播交换机中的持久化队列，不存在则自动创建-->
      <rabbit:queue id="spring_topic_queue_well2" name="spring_topic_queue_well2" auto-declare="true"/>
  
      <rabbit:topic-exchange id="spring_topic_exchange" name="spring_topic_exchange" auto-declare="true">
          <rabbit:bindings>
              <rabbit:binding pattern="heima.*" queue="spring_topic_queue_star"/>
              <rabbit:binding pattern="heima.#" queue="spring_topic_queue_well"/>
              <rabbit:binding pattern="itcast.#" queue="spring_topic_queue_well2"/>
          </rabbit:bindings>
      </rabbit:topic-exchange>
  
      <!--定义rabbitTemplate对象操作可以在代码中方便发送消息-->
      <rabbit:template id="rabbitTemplate" connection-factory="connectionFactory"/>
  </beans>
  ```

③ 编写代码发送消息

```java
public class ProducerTest {

    //1.注入 RabbitTemplate
    @Autowired
    private RabbitTemplate rabbitTemplate;

    @Test
    public void testHelloWorld(){
        //2.发送消息
        rabbitTemplate.convertAndSend("spring_queue","hello world spring....");
    }

    /**
     * 发送fanout消息
     */
    @Test
    public void testFanout(){
        //2.发送消息
        rabbitTemplate.convertAndSend("spring_fanout_exchange","","spring fanout....");
    }

    /**
     * 发送topic消息
     */
    @Test
    public void testTopics(){
        //2.发送消息
        rabbitTemplate.convertAndSend("spring_topic_exchange","heima.hehe.haha","spring topic....");
    }
}
```



#### 2. 消费者

① 添加依赖

② 配置整合

`spring-rabbitmq-consumer.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:context="http://www.springframework.org/schema/context"
       xmlns:rabbit="http://www.springframework.org/schema/rabbit"
       xsi:schemaLocation="http://www.springframework.org/schema/beans
       http://www.springframework.org/schema/beans/spring-beans.xsd
       http://www.springframework.org/schema/context
       https://www.springframework.org/schema/context/spring-context.xsd
       http://www.springframework.org/schema/rabbit
       http://www.springframework.org/schema/rabbit/spring-rabbit.xsd">
    <!--加载配置文件-->
    <context:property-placeholder location="classpath:rabbitmq.properties"/>

    <!-- 定义rabbitmq connectionFactory -->
    <rabbit:connection-factory id="connectionFactory" host="${rabbitmq.host}"
                               port="${rabbitmq.port}"
                               username="${rabbitmq.username}"
                               password="${rabbitmq.password}"
                               virtual-host="${rabbitmq.virtual-host}"/>

    <bean id="springQueueListener" class="com.itheima.rabbitmq.listener.SpringQueueListener"/>
    <!--<bean id="fanoutListener1" class="com.itheima.rabbitmq.listener.FanoutListener1"/>
    <bean id="fanoutListener2" class="com.itheima.rabbitmq.listener.FanoutListener2"/>
    <bean id="topicListenerStar" class="com.itheima.rabbitmq.listener.TopicListenerStar"/>
    <bean id="topicListenerWell" class="com.itheima.rabbitmq.listener.TopicListenerWell"/>
    <bean id="topicListenerWell2" class="com.itheima.rabbitmq.listener.TopicListenerWell2"/>
-->
    <rabbit:listener-container connection-factory="connectionFactory" auto-declare="true">
        <rabbit:listener ref="springQueueListener" queue-names="spring_queue"/>
        <!-- <rabbit:listener ref="fanoutListener1" queue-names="spring_fanout_queue_1"/>
         <rabbit:listener ref="fanoutListener2" queue-names="spring_fanout_queue_2"/>
         <rabbit:listener ref="topicListenerStar" queue-names="spring_topic_queue_star"/>
         <rabbit:listener ref="topicListenerWell" queue-names="spring_topic_queue_well"/>
         <rabbit:listener ref="topicListenerWell2" queue-names="spring_topic_queue_well2"/>-->
    </rabbit:listener-container>
</beans>
```

③ 编写消息监听器

```java
public class SpringQueueListener implements MessageListener {
    @Override
    public void onMessage(Message message) {
        //打印消息
        System.out.println(new String(message.getBody()));
    }
}
```



### 2. SpringBoot整合

#### 1. 生产者

① 导入依赖

② 配置yml文件

```yml
# 配置RabbitMQ的基本信息 ip 端口 username password..
spring:
  rabbitmq:
    host: 192.168.111.129 #ip
    port: 5672
    username: guest
    password: guest
    virtual-host: /eardh
```

③ 定义交换机，队列以及绑定关系的配置类

```java
@Configuration
public class RabbitMQConfig {

    public static final String EXCHANGE_NAME = "boot_topic_exchange";
    public static final String QUEUE_NAME = "boot_queue";

    //1.交换机
    @Bean("bootExchange")
    public Exchange bootExchange() {
        return ExchangeBuilder.topicExchange(EXCHANGE_NAME).durable(true).build();
    }

    //2.Queue 队列
    @Bean("bootQueue")
    public Queue bootQueue() {
        return QueueBuilder.durable(QUEUE_NAME).build();
    }

    //3. 队列和交互机绑定关系 Binding
    /*
        1. 知道哪个队列
        2. 知道哪个交换机
        3. routing key
     */
    @Bean
    public Binding bindQueueExchange(@Qualifier("bootQueue") Queue queue, @Qualifier("bootExchange") Exchange exchange) {
        return BindingBuilder.bind(queue).to(exchange).with("boot.#").noargs();
    }
}
```

④注入RabbitTemplate，调用方法，完成消息发送

```java
@SpringBootTest
public class ProducerTest {

    //注入RabbitTemplate
    @Autowired
    private RabbitTemplate rabbitTemplate;

    @Test
    public void testSend(){
        rabbitTemplate.convertAndSend(RabbitMQConfig.EXCHANGE_NAME,"boot.haha","boot mq hello~~~");
    }
}
```



#### 2. 消费者

① 导入依赖

② 配置yml文件

③ 定义监听类，使用@RabbitListener注解完成队列监听

```java
@Component
public class RabbimtMQListener {

    @RabbitListener(queues = "boot_queue")
    public void ListenerQueue(Message message){
        System.out.println(new String(message.getBody()));
    }
}
```



### 2. 小结

- 使用Spring 整合RabbitMQ将组件全部使用配置方式实现，简化编码
- Spring 提供RabbitTemplate 简化发送消息API
- 使用监听机制简化消费者编码





## 6. 高级特性

### 1. 消息可靠性

在使用RabbitMQ 的时候，作为消息发送方希望杜绝任何消息丢失或者投递失败场景。RabbitMQ 为我们提供了两种方式用来控制消息的投递可靠性模式。

- `confirm` 确认模式
- `return`  退回模式

rabbitmq 整个消息投递的路径为：

`producer--->rabbitmq broker--->exchange--->queue--->consumer`

- 消息从producer 到exchange则会返回一个`confirmCallback` 。
- 消息从`exchange-->queue` 投递失败则会返回一个returnCallback 。我们将利用这两个callback 控制消息的可靠性投递

**代码**：

```xml
<rabbit:connection-factory id="connectionFactory"
                           host="${rabbitmq.host}"
                           port="${rabbitmq.port}"
                           username="${rabbitmq.username}"
                           password="${rabbitmq.password}"
                           virtual-host="${rabbitmq.virtual-host}"
                           confirm-type="CORRELATED"
                           publisher-returns="true"
                           />

<!--消息可靠性投递（生产端）-->
<rabbit:queue id="test_queue_confirm" name="test_queue_confirm"/>
<rabbit:direct-exchange name="test_exchange_confirm">
    <rabbit:bindings>
        <rabbit:binding queue="test_queue_confirm" key="confirm"/>
    </rabbit:bindings>
</rabbit:direct-exchange>
```

```java
    /**
     * 确认模式：producer -> exchange
     * 1. 确认模式开启：ConnectionFactory中开启confirm-type="CORRELATED"
     * 2. 在rabbitTemplate定义ConfirmCallBack回调函数
     */
    @Test
    public void testConfirm() {
        //2. 定义回调
        rabbitTemplate.setConfirmCallback(new RabbitTemplate.ConfirmCallback() {
            /**
             *
             * @param correlationData 相关配置信息
             * @param ack   exchange交换机 是否成功收到了消息。true 成功，false代表失败
             * @param cause 失败原因
             */
            @Override
            public void confirm(CorrelationData correlationData, boolean ack, String cause) {
                System.out.println("confirm方法被执行了....");
                if (ack) {
                    //接收成功
                    System.out.println("接收成功消息" + cause);
                } else {
                    //接收失败
                    System.out.println("接收失败消息" + cause);
                    //做一些处理，让消息再次发送。
                }
            }
        });

        //3. 发送消息
        rabbitTemplate.convertAndSend("test_exchange_confirm", "confirm", "message confirm....");
    }
```

```java
    /**
     * 回退模式： 当消息发送给Exchange后，Exchange路由到Queue失败时 才会执行 ReturnCallBack
     * 1. 开启回退模式:publisher-returns="true" 新版本默认已开启
     * 2. 设置ReturnsCallback
     * 3. 设置Exchange处理消息的模式:
     *   1. 如果消息没有路由到Queue，则丢弃消息（默认）
     *   2. 如果消息没有路由到Queue，返回给消息发送方ReturnsCallback
     */
    @Test
    public void testReturn() {

        //设置交换机处理失败消息的模式
        rabbitTemplate.setMandatory(true);

        //2.ReturnsCallback
        rabbitTemplate.setReturnsCallback(returned -> {
            System.out.println("return 执行了...");
            System.out.println(returned.getMessage());    //消息对象
            System.out.println(returned.getReplyCode());  //错误码
            System.out.println(returned.getReplyText());  //错误信息
            System.out.println(returned.getExchange());   //交换机
            System.out.println(returned.getRoutingKey()); //路由键
        });

        //3. 发送消息
        rabbitTemplate.convertAndSend("test_exchange_confirm1", "confirm1", "message confirm....");
    }
```

**小结**：

- 设置ConnectionFactory的`confirm-type="CORRELATED"`开启确认模式。
- 使用`rabbitTemplate.setConfirmCallback`设置回调函数。当消息发送到exchange后回调confirm方法。在方法中判断ack，如果为true，则发送成功，如果为false，则发送失败，需要处理。
- 设置ConnectionFactory的`publisher-returns="true"` 开启退回模式。
- 使用`rabbitTemplate.setReturnsCallback`设置退回函数，当消息从exchange路由到queue失败后，如果设置了`rabbitTemplate.setMandatory(true)`参数，则会将消息退回给producer。并执行回调函数returnedMessage。
- 在RabbitMQ中也提供了事务机制，但是性能较差，此处不做讲解。使用channel下列方法，完成事务控制：
  - `txSelect()`, 用于将当前channel设置成transaction模式
  - `txCommit()`，用于提交事务
  - `txRollback()`,用于回滚事务



### 2. Consumer ACK

ack指Acknowledge，确认。表示消费端收到消息后的确认方式。有三种确认方式：

- 自动确认：`acknowledge="none"`
- 手动确认：`acknowledge="manual"`
- 根据异常情况确认：`acknowledge="auto"`，（这种方式使用麻烦，不作讲解）

```xml
<!--定义监听器容器-->
<rabbit:listener-container connection-factory="connectionFactory" acknowledge="manual" prefetch="1" >
    <rabbit:listener ref="ackListener" queue-names="test_queue_confirm"/>
    <!--        <rabbit:listener ref="qosListener" queue-names="test_queue_confirm"/>-->
    <!--定义监听器，监听正常队列-->
    <!--        <rabbit:listener ref="dlxListener" queue-names="test_queue_dlx"/>-->
    <!--延迟队列效果实现：  一定要监听的是 死信队列！！！-->
    <!--        <rabbit:listener ref="orderListener" queue-names="order_queue_dlx"/>-->
</rabbit:listener-container>
```

其中自动确认是指，当消息一旦被Consumer接收到，则自动确认收到，并将相应message 从RabbitMQ 的消息缓存中移除。但是在实际业务处理中，很可能消息接收到，业务处理出现异常，那么该消息就会丢失。如果设置了手动确认方式，则需要在业务处理成功后，调用`channel.basicAck()`，手动签收，如果出现异常，则调用`channel.basicNack()`方法，让其自动重新发送消息

**代码**：

```java
/**
 * Consumer ACK机制：
 * 1. 设置手动签收。acknowledge="manual"
 * 2. 让监听器类实现ChannelAwareMessageListener接口
 * 3. 如果消息成功处理，则调用channel的 basicAck()签收
 * 4. 如果消息处理失败，则调用channel的 basicNack()拒绝签收，broker重新发送给consumer
 */
@Component
public class AckListener implements ChannelAwareMessageListener {

    @Override
    public void onMessage(Message message, Channel channel) throws Exception {
        long deliveryTag = message.getMessageProperties().getDeliveryTag();

        try {
            //1.接收转换消息
            System.out.println(new String(message.getBody()));

            //2. 处理业务逻辑
            System.out.println("处理业务逻辑...");
            int i = 3 / 0;//出现错误
            //3. 手动签收
            channel.basicAck(deliveryTag, true);
        } catch (Exception e) {
            //4.拒绝签收
            /*
             第三个参数：requeue：重回队列。如果设置为true，则消息重新回到queue，broker会重新发送该消息给消费端
            */
            channel.basicNack(deliveryTag, true, true);
            TimeUnit.SECONDS.sleep(2);
        }
    }
}
```

**小结**：

- 在rabbit:listener-container标签中设置acknowledge属性，设置ack方式none：自动确认，manual：手动确认
- 如果在消费端没有出现异常，则调用channel.basicAck(deliveryTag,false);方法确认签收消息
- 如果出现异常，则在catch中调用basicNack或basicReject，拒绝消息，让MQ重新发送消息。

**消息可靠性总结**：

1. 持久化
   - exchange要持久化
   - queue要持久化
   - message要持久化

2. 生产方确认Confirm
3. 消费方确认Ack
4. Broker高可用



### 3. 消费端限流

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202207060229626.png)

**代码**：

```java
/**
 * Consumer 限流机制
 * 1. 确保ack机制为手动确认。
 * 2. listener-container配置属性
 * - perfetch = 1,表示消费端每次从mq拉去一条消息来消费，直到手动确认消费完毕后，才会继续拉去下一条消息。
 */
@Component
public class QosListener implements ChannelAwareMessageListener {

    @Override
    public void onMessage(Message message, Channel channel) throws Exception {
        //1.获取消息
        System.out.println(new String(message.getBody()));

        //2. 处理业务逻辑

        //3. 签收
        channel.basicAck(message.getMessageProperties().getDeliveryTag(), true);

        TimeUnit.SECONDS.sleep(2);
    }
}
```

**小结**：

- 在`<rabbit:listener-container> `中配置prefetch属性设置消费端一次拉取多少消息
- 消费端的确认模式一定为手动确认。acknowledge="manual"



### 4. TTL

- TTL 全称Time To Live（存活时间/过期时间）。
- 当消息到达存活时间后，还没有被消费，会被自动清除。
- RabbitMQ可以对消息设置过期时间，也可以对整个队列（Queue）设置过期时间。

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202207060229627.png)

**代码**：

```xml
<!--ttl-->
<rabbit:queue name="test_queue_ttl" id="test_queue_ttl">
    <!--设置queue的参数-->
    <rabbit:queue-arguments>
        <!--x-message-ttl指队列的过期时间-->
        <entry key="x-message-ttl" value="10000" value-type="java.lang.Integer"/>
    </rabbit:queue-arguments>
</rabbit:queue>

<rabbit:topic-exchange name="test_exchange_ttl">
    <rabbit:bindings>
        <rabbit:binding pattern="ttl.#" queue="test_queue_ttl"/>
    </rabbit:bindings>
</rabbit:topic-exchange>
```

```java
    /**
     * TTL:过期时间
     * 1. 队列统一过期
     * 2. 消息单独过期
     * 如果设置了消息的过期时间，也设置了队列的过期时间，它以时间短的为准。
     * 队列过期后，会将队列所有消息全部移除。
     * 消息过期后，只有消息在队列顶端，才会判断其是否过期(移除掉)
     */
    @Test
    public void testTtl() {
        // 消息后处理对象，设置一些消息的参数信息
        MessagePostProcessor messagePostProcessor = new MessagePostProcessor() {

            @Override
            public Message postProcessMessage(Message message) throws AmqpException {
                // 1.设置message的信息
                message.getMessageProperties().setExpiration("5000");//消息的过期时间
                // 2.返回该消息
                return message;
            }
        };

        for (int i = 0; i < 10; i++) {
            if (i == 5) {
                //消息单独过期
                rabbitTemplate.convertAndSend("test_exchange_ttl", "ttl.hehe", "message ttl....", messagePostProcessor);
            } else {
                //不过期的消息
                rabbitTemplate.convertAndSend("test_exchange_ttl", "ttl.hehe", "message ttl....");
            }
        }
    }
```

**小结**：

- 设置队列过期时间使用参数：x-message-ttl，单位：ms(毫秒)，会对整个队列消息统一过期。
- 设置消息过期时间使用参数：expiration。单位：ms(毫秒)，当该消息在队列头部时（消费时），会单独判断这一消息是否过期。
- 如果两者都进行了设置，以时间短的为准



### 5. 死信队列

死信队列，英文缩写：DLX  。Dead Letter Exchange（死信交换机），当消息成为Dead message后，可以被重新发送到另一个交换机，这个交换机就是DLX。

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202207060229628.png)

**消息成为死信的三种情况**：

1. 队列消息长度到达限制；
2. 消费者拒接消费消息，`basicNack/basicReject`,并且不把消息重新放入原目标队列，requeue=false；
3. 原队列存在消息过期设置，消息到达超时时间未被消费；

**队列绑定死信交换机**：

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202207060229629.png)

队列设置参数：`x-dead-letter-exchange` 和`x-dead-letter-routing-key`

**代码**：

```xml
<!--
        死信队列：
            1. 声明正常的队列(test_queue_dlx)和交换机(test_exchange_dlx)
            2. 声明死信队列(queue_dlx)和死信交换机(exchange_dlx)
            3. 正常队列绑定死信交换机
               - 设置两个参数：
                  - x-dead-letter-exchange：死信交换机名称
                  - x-dead-letter-routing-key：发送给死信交换机的routingkey
    -->
<!--1. 声明正常的队列(test_queue_dlx)和交换机(test_exchange_dlx)-->
<rabbit:queue name="test_queue_dlx" id="test_queue_dlx">
    <!--3. 正常队列绑定死信交换机-->
    <rabbit:queue-arguments>
        <!--3.1 x-dead-letter-exchange：死信交换机名称-->
        <entry key="x-dead-letter-exchange" value="exchange_dlx"/>

        <!--3.2 x-dead-letter-routing-key：发送给死信交换机的routingkey-->
        <entry key="x-dead-letter-routing-key" value="dlx.hehe"/>

        <!--4.1 设置队列的过期时间 ttl-->
        <entry key="x-message-ttl" value="10000" value-type="java.lang.Integer"/>
        <!--4.2 设置队列的长度限制 max-length -->
        <entry key="x-max-length" value="10" value-type="java.lang.Integer"/>
    </rabbit:queue-arguments>
</rabbit:queue>
<rabbit:topic-exchange name="test_exchange_dlx">
    <rabbit:bindings>
        <rabbit:binding pattern="test.dlx.#" queue="test_queue_dlx"/>
    </rabbit:bindings>
</rabbit:topic-exchange>

<!--2. 声明死信队列(queue_dlx)和死信交换机(exchange_dlx)-->
<rabbit:queue name="queue_dlx" id="queue_dlx"/>
<rabbit:topic-exchange name="exchange_dlx">
    <rabbit:bindings>
        <rabbit:binding pattern="dlx.#" queue="queue_dlx"/>
    </rabbit:bindings>
</rabbit:topic-exchange>
```

```java
    /**
     * 发送测试死信消息：
     * 1. 过期时间
     * 2. 长度限制
     * 3. 消息拒收
     */
    @Test
    public void testDlx() {
        //1. 测试过期时间，死信消息
        rabbitTemplate.convertAndSend("test_exchange_dlx","test.dlx.haha","我是一条消息，我会死吗？");

        //2. 测试长度限制后，消息死信
        /*
        for (int i = 0; i < 20; i++) {
            rabbitTemplate.convertAndSend("test_exchange_dlx", "test.dlx.haha", "我是一条消息，我会死吗？");
        }
        */

        //3. 测试消息拒收
//        rabbitTemplate.convertAndSend("test_exchange_dlx", "test.dlx.haha", "我是一条消息，我会死吗？");
    }
```

消费者监听：

```java
public class DlxListener implements ChannelAwareMessageListener {

    @Override
    public void onMessage(Message message, Channel channel) throws Exception {
        long deliveryTag = message.getMessageProperties().getDeliveryTag();
        try {
            //1.接收转换消息
            System.out.println(new String(message.getBody()));

            //2. 处理业务逻辑
            System.out.println("处理业务逻辑...");
            int i = 3 / 0;//出现错误
            //3. 手动签收
            channel.basicAck(deliveryTag, true);
        } catch (Exception e) {
            System.out.println("出现异常，拒绝接受");
            //4.拒绝签收，不重回队列 requeue=false
            channel.basicNack(deliveryTag, true, false);
        }
    }
}
```

**小结**：

1. 死信交换机和死信队列和普通的没有区别
2. 当消息成为死信后，如果该队列绑定了死信交换机，则消息会被死信交换机重新路由到死信队列
3. 消息成为死信的三种情况：
   1. 队列消息长度到达限制；
   2. 消费者拒接消费消息，并且不重回队列；
   3. 原队列存在消息过期设置，消息到达超时时间未被消费；



### 6. 延迟队列

延迟队列，即消息进入队列后不会立即被消费，只有到达指定时间后，才会被消费。

需求：

1. 下单后，30分钟未支付，取消订单，回滚库存。
2. 新用户注册成功7天后，发送短信问候。

实现方式：

1. 定时器
2. 延迟队列

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202207060229630.png)

在RabbitMQ中并未提供延迟队列功能。但是可以使用：TTL+死信队列组合实现延迟队列的效果

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202207060229631.png)

**代码**：

```xml
<!--
        延迟队列：
            1. 定义正常交换机（order_exchange）和队列(order_queue)
            2. 定义死信交换机（order_exchange_dlx）和队列(order_queue_dlx)
            3. 绑定，设置正常队列过期时间为30分钟
    -->
<!-- 1. 定义正常交换机（order_exchange）和队列(order_queue)-->
<rabbit:queue id="order_queue" name="order_queue">
    <!-- 3. 绑定，设置正常队列过期时间为30分钟-->
    <rabbit:queue-arguments>
        <entry key="x-dead-letter-exchange" value="order_exchange_dlx"/>
        <entry key="x-dead-letter-routing-key" value="dlx.order.cancel"/>
        <entry key="x-message-ttl" value="10000" value-type="java.lang.Integer"/>
    </rabbit:queue-arguments>
</rabbit:queue>
<rabbit:topic-exchange name="order_exchange">
    <rabbit:bindings>
        <rabbit:binding pattern="order.#" queue="order_queue"/>
    </rabbit:bindings>
</rabbit:topic-exchange>

<!--  2. 定义死信交换机（order_exchange_dlx）和队列(order_queue_dlx)-->
<rabbit:queue id="order_queue_dlx" name="order_queue_dlx"/>
<rabbit:topic-exchange name="order_exchange_dlx">
    <rabbit:bindings>
        <rabbit:binding pattern="dlx.order.#" queue="order_queue_dlx"/>
    </rabbit:bindings>
</rabbit:topic-exchange>
```

```java
@Component
public class OrderListener implements ChannelAwareMessageListener {

    @Override
    public void onMessage(Message message, Channel channel) throws Exception {
        long deliveryTag = message.getMessageProperties().getDeliveryTag();

        try {
            //1.接收转换消息
            System.out.println(new String(message.getBody()));

            //2. 处理业务逻辑
            System.out.println("处理业务逻辑...");
            System.out.println("根据订单id查询其状态...");
            System.out.println("判断状态是否为支付成功");
            System.out.println("取消订单，回滚库存....");
            //3. 手动签收
            channel.basicAck(deliveryTag, true);
        } catch (Exception e) {
            System.out.println("出现异常，拒绝接受");
            //4.拒绝签收，不重回队列 requeue=false
            channel.basicNack(deliveryTag, true, false);
        }
    }
}
```

**小结**：

1. 延迟队列指消息进入队列后，可以被延迟一定时间，再进行消费。
2. RabbitMQ没有提供延迟队列功能，但是可以使用：`TTL + DLX` 来实现延迟队列效果。



### 7. 日志与监控

**RabbitMQ日志**

RabbitMQ默认日志存放路径：`/var/log/rabbitmq/rabbit@xxx.log`

日志包含了RabbitMQ的版本号、Erlang的版本号、RabbitMQ服务节点名称、cookie的hash值、RabbitMQ配置文件地址、内存限制、磁盘限制、默认账户guest的创建以及权限配置等等。

**rabbitmqctl管理和监控**

- 查看队列

  \# `rabbitmqctl list_queues`

- 查看exchanges

  \# `rabbitmqctl list_exchanges`

- 查看用户

  \# `rabbitmqctl list_users`

- 查看连接

  \# `rabbitmqctl list_connections`

- 查看消费者信息

  \# `rabbitmqctl list_consumers`

- 查看环境变量

  \# `rabbitmqctl environment`

- 查看未被确认的队列

  \# `rabbitmqctl list_queues name messages_unacknowledged`

- 查看单个队列的内存使用

  \# `rabbitmqctl list_queues name memory`

- 查看准备就绪的队列

  \# `rabbitmqctl list_queues name messages_ready`



### 8. 消息追踪

在使用任何消息中间件的过程中，难免会出现某条消息异常丢失的情况。对于RabbitMQ而言，可能是因为生产者或消费者与RabbitMQ断开了连接，而它们与RabbitMQ又采用了不同的确认机制；也有可能是因为交换器与队列之间不同的转发策略；甚至是交换器并没有与任何队列进行绑定，生产者又不感知或者没有采取相应的措施；另外RabbitMQ本身的集群策略也可能导致消息的丢失。这个时候就需要有一个较好的机制跟踪记录消息的投递过程，以此协助开发和运维人员进行问题的定位。

在RabbitMQ中可以使用Firehose和rabbitmq_tracing插件功能来实现消息追踪。



#### 1. Firehose

firehose的机制是将生产者投递给rabbitmq的消息，rabbitmq投递给消费者的消息按照指定的格式发送到默认的exchange上。这个默认的exchange的名称为`amq.rabbitmq.trace`，它是一个topic类型的exchange。发送到这个exchange上的消息的routing key为publish.exchangename 和deliver.queuename。其中exchangename和queuename为实际exchange和queue的名称，分别对应生产者投递到exchange的消息，和消费者从queue上获取的消息。

> 注意：打开trace 会影响消息写入功能，适当打开后请关闭。-
>
> - `rabbitmqctl trace_on`：开启Firehose命令
> - `rabbitmqctl trace_off`：关闭Firehose命令



#### 2. rabbitmq_tracing

rabbitmq_tracing和Firehose在实现上如出一辙，只不过rabbitmq_tracing的方式比Firehose多了一层GUI的包装，更容易使用和管理。

启用插件：`rabbitmq-plugins enable rabbitmq_tracing`





## 7. 应用问题

### 1. 消息可靠性保障

需求：100%确保消息发送成功

**消息补偿**

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202207060229632.png)



### 2. 消息幂等性处理

幂等性指一次和多次请求某一个资源，对于资源本身应该具有同样的结果。也就是说，其任意多次执行对资源本身所产生的影响均与一次执行的影响相同。

在MQ中指，消费多条相同的消息，得到与消费该消息一次相同的结果。

**乐观锁机制**

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202207060229633.png)





## 8. 集群搭建

摘要：实际生产应用中都会采用消息队列的集群方案，如果选择RabbitMQ那么有必要了解下它的集群方案原理

一般来说，如果只是为了学习RabbitMQ或者验证业务工程的正确性那么在本地环境或者测试环境上使用其单实例部署就可以了，但是出于MQ中间件本身的可靠性、并发性、吞吐量和消息堆积能力等问题的考虑，在生产环境上一般都会考虑使用RabbitMQ的集群方案。



### 1. 集群方案的原理

RabbitMQ这款消息队列中间件产品本身是基于Erlang编写，Erlang语言天生具备分布式特性（通过同步Erlang集群各节点的magic cookie来实现）。因此，RabbitMQ天然支持Clustering。这使得RabbitMQ本身不需要像ActiveMQ、Kafka那样通过ZooKeeper分别来实现HA方案和保存集群的元数据。集群是保证可靠性的一种方式，同时可以通过水平扩展以达到增加消息吞吐量能力的目的。

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202207060229634.png)



### 2. 多机实例部署

由于某些因素的限制，有时候你不得不在一台机器上去搭建一个rabbitmq集群，这个有点类似zookeeper的单机版。真实生成环境还是要配成多机集群的。有关怎么配置多机集群的可以参考其他的资料，这里主要论述如何在单机中配置多个rabbitmq实例。

主要参考官方文档：https://www.rabbitmq.com/clustering.html

| hostname   | IP              |
| ---------- | --------------- |
| centos7-h1 | 192.168.111.129 |
| centos7-h2 | 192.168.111.130 |

1. 停止rabbitmq-server服务

   ```sh
   systemctl stop rabbitmq-server
   ```

2. 默认情况下rabbitmq节点名由`rabbit@hostname`组成，rabbit为前缀，也可以前缀名（节点名），为上面两台服务器创建下面rabbitmq节点实例，替换原来的rabbit节点

   ```sh
   #创建或修改实例rabbitmq实例
   RABBITMQ_NODE_PORT=5672 RABBITMQ_SERVER_START_ARGS="-rabbitmq_management listener [{port,15672}]" RABBITMQ_NODENAME=eardh rabbitmq-server -detached
   ```

   - `RABBITMQ_NODE_PORT` ：启动的rabbitmq占用的端口

   - `RABBITMQ_SERVER_START_ARGS="-rabbitmq_management listener [{port,15672}]" `：rabbitmq管理监听端口
   - `RABBITMQ_NODENAME`：可以理解为启动的改rabbitmq的节点名称，但是官方给出的节点名称结构确实：`前缀@主机名`，而前缀恰好是这里的`RABBITMQ_NODENAME`，所以，我猜测就是它应该就是节点名，主要是为了表示是同一台服务器上的不同rabbitmq运行实例，这样操作即可实现单机搭建集群的操作，只需改变运行实例的端口即可。

3. 首先确保RabbitMQ运行没有问题

   ```sh
   #启动的节点实例
   rabbitmqctl -n 节点名(RABBITMQ_NODENAME) start_app
   
   #停止运行节点实例
   rabbitmqctl -n 节点名(RABBITMQ_NODENAME) stop_app
   
   #查看节点实例运行状态
   rabbitmqctl -n 节点名(RABBITMQ_NODENAME) status
   
   #查看节点集群情况
   rabbitmqctl -n 节点名(RABBITMQ_NODENAME) cluster_status
   
   #重置节点，在start_app前进行重置
   rabbitmqctl -n 节点名(RABBITMQ_NODENAME) reset
   ```

4. 多台服务器搭建集群，需要保证`.erlang.cookie`一致

   ```sh
   #查看 .erlang.cookie 文件位置
   rabbitmq-diagnostics erlang_cookie_sources
   ```

   ```sh
   #编辑，是两台服务器文件里面的值相同
   vim .erlang.cookie文件位置
   ```

5. 编辑 `/etc/hosts`文件，将需要的集群IP和需要连接的rabbitmq节点的主机名也加入

   ```sh
   vim /etc/hosts
   
   192.168.111.129 centos7-h1
   192.168.111.130 centos7-h2
   ```

6. 创建集群，eardh(centos7-h2)节点作为主节点

   ```sh
   #在centos7-h1输入
   #关闭eardh应用
   rabbitmqctl -n eardh stop_app
   
   #加入集群
   rabbitmqctl -n eardh join_cluster eardh@centos7-h2
   
   #启动eardh应用
   rabbitmqctl -n eardh start_app
   ```

5. 查看集群状态：

   ```sh
   rabbitmqctl -n eardh stop_app
   ```

6. web监控：

   ![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202207060229635.png)



### 3. 集群管理

将节点加入指定集群中。在这个命令执行前需要停止RabbitMQ应用并重置节点。

```sh
rabbitmqctl [-n <node>] join_cluster {cluster_node} [–ram]
```

显示集群的状态。

```sh
rabbitmqctl [-n <node>] cluster_status
```

修改集群节点的类型。在这个命令执行前需要停止RabbitMQ应用。

```sh
rabbitmqctl change_cluster_node_type {disc|ram}
```

将节点从集群中删除，允许离线执行。

```sh
rabbitmqctl forget_cluster_node [–offline]
```

在集群中的节点应用启动前咨询clusternode节点的最新信息，并更新相应的集群信息。这个和join_cluster不同，它不加入集群。考虑这样一种情况，节点A和节点B都在集群中，当节点A离线了，节点C又和节点B组成了一个集群，然后节点B又离开了集群，当A醒来的时候，它会尝试联系节点B，但是这样会失败，因为节点B已经不在集群中了。

```sh
rabbitmqctl update_cluster_nodes {clusternode}
```

取消队列queue同步镜像的操作。

```sh
rabbitmqctl cancel_sync_queue [-p vhost] {queue}
```

设置集群名称。集群名称在客户端连接时会通报给客户端。Federation和Shovel插件也会有用到集群名称的地方。集群名称默认是集群中第一个节点的名称，通过这个命令可以重新设置。

```sh
rabbitmqctl set_cluster_name {name}
```



### 4. RabbitMQ镜像集群配置

> 上面已经完成RabbitMQ默认集群模式，但并不保证队列的高可用性，尽管交换机、绑定这些可以复制到集群里的任何一个节点，但是队列内容不会复制。虽然该模式解决一项目组节点压力，但队列节点宕机直接导致该队列无法应用，只能等待重启，所以要想在队列节点宕机或故障也能正常应用，就要复制队列内容到集群里的每个节点，必须要创建镜像队列。
>
> 镜像队列是基于普通的集群模式的，然后再添加一些策略，所以你还是得先配置普通集群，然后才能设置镜像队列，我们就以上面的集群接着做。

**设置的镜像队列可以通过开启的网页的管理端Admin -> Policies，也可以通过命令。**

```sh
rabbitmqctl -n eardh set_policy 'my_ha' '^' '{"ha-mode":"all"}'
```

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202207060229636.png)

> - Name：策略名称
> - Pattern：匹配的规则，如果是匹配所有的队列，是^.
> - Definition：使用`ha-mode`模式中的all，也就是同步所有匹配的队列。问号链接帮助文档。



### 5. 负载均衡-HAProxy

HAProxy提供高可用性、负载均衡以及基于TCP和HTTP应用的代理，支持虚拟主机，它是免费、快速并且可靠的一种解决方案，包括Twitter，Reddit，StackOverflow，GitHub在内的多家知名互联网公司在使用。HAProxy实现了一种事件驱动、单一进程模型，此模型支持非常大的并发连接数。

[下载](http://www.haproxy.org/#down)

#### 1.  安装HAProxy

```shell
//1. 安装依赖包
yum install gcc vim wget

//2. 解压
tar -zxvf haproxy-ss-LATEST.tar.gz -C /usr/local

//3. 进入目录、进行编译、安装
cd /usr/local/haproxy-ss-20220622
make TARGET=linux-glibc
make install PREFIX=/usr/local/haproxy

//4. 赋权
groupadd -r -g 149 haproxy
useradd -g haproxy -r -s /sbin/nologin -u 149 haproxy

//5. 创建haproxy配置文件
mkdir /etc/haproxy
vim /etc/haproxy/haproxy.cfg
```




#### 2. 配置HAProxy

配置文件路径：`/etc/haproxy/haproxy.cfg`

```shell
#logging options
global
	log 127.0.0.1 local0 info
	maxconn 5120
	chroot /usr/local/haproxy
	uid 99
	gid 99
	pidfile /var/run/haproxy.pid

defaults
	log global
	mode tcp
	option tcplog
	option dontlognull
	retries 3
	option redispatch
	maxconn 2000
	timeout connect 5s
    timeout client 60s
    timeout server 15s	
#front-end IP for consumers and producters

listen rabbitmq_cluster
	bind 0.0.0.0:5673
	
	mode tcp
	#balance url_param userid
	#balance url_param session_id check_post 64
	#balance hdr(User-Agent)
	#balance hdr(host)
	#balance hdr(Host) use_domain_only
	#balance rdp-cookie
	#balance leastconn
	#balance source //ip
	
	balance roundrobin
	
    server node1 192.168.111.129:5672 check inter 5000 rise 2 fall 2
    server node2 192.168.111.130:5672 check inter 5000 rise 2 fall 2

listen stats
	bind 192.168.111.130:8100
	mode http
	option httplog
	stats enable
	stats uri /rabbitmq-stats
	stats refresh 5
```

启动HAproxy负载

```shell
/usr/local/haproxy/sbin/haproxy -f /etc/haproxy/haproxy.cfg
//查看haproxy进程状态
ps -ef | grep haproxy

访问如下地址对mq节点进行监控
http://192.168.111.130:8100/rabbitmq-stats
```

代码中访问mq集群地址，则变为访问haproxy地址：5673

```java
public class HelloWorld {
    public static void main(String[] args) throws IOException, TimeoutException {

        //1.创建连接工厂
        ConnectionFactory factory = new ConnectionFactory();

        //2. 设置参数
        factory.setHost("192.168.111.130");//ip  HaProxy的ip
        factory.setPort(5673); //端口 HaProxy的监听的端口

        //3. 创建连接 Connection
        Connection connection = factory.newConnection();

        //4. 创建Channel
        Channel channel = connection.createChannel();

        //5. 创建队列Queue
        channel.queueDeclare("hello_world",true,false,false,null);
        String body = "hello rabbitmq";
        //6. 发送消息
        channel.basicPublish("","hello_world",null,body.getBytes());
        //7.释放资源
        channel.close();
        connection.close();

        System.out.println("send success....");
    }
}
```
