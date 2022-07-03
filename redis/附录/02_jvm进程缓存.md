# JVM进程缓存案例

为了演示多级缓存，我们先导入一个商品管理的案例，其中包含商品的CRUD功能。我们将来会给查询商品添加多级缓存。



## 1. 安装MySQL

后期做数据同步需要用到MySQL的主从功能，所以需要大家在虚拟机中，利用Docker来运行一个MySQL容器。

### 1. 准备目录

为了方便后期配置MySQL，我们先准备两个目录，用于挂载容器的数据和配置文件目录：

```sh
# 进入/tmp目录
cd /tmp
# 创建文件夹
mkdir mysql
# 进入mysql目录
cd mysql
```



### 2. 运行命令

进入mysql目录后，执行下面的Docker命令：

```sh
docker run \
 -p 3306:3306 \
 --name mysql \
 -v $PWD/conf:/etc/mysql/conf.d \
 -v $PWD/logs:/logs \
 -v $PWD/data:/var/lib/mysql \
 -e MYSQL_ROOT_PASSWORD=123 \
 --privileged \
 -d \
 mysql:5.7.25
```



### 3. 修改配置

在/tmp/mysql/conf目录添加一个my.cnf文件，作为mysql的配置文件：

```sh
# 创建文件
touch /tmp/mysql/conf/my.cnf
```

文件的内容如下：

```ini
[mysqld]
skip-name-resolve
character_set_server=utf8
datadir=/var/lib/mysql
server-id=1000
```



### 4. 重启

配置修改后，必须重启容器：

```sh
docker restart mysql
```





## 2. 导入SQL

```sql
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for tb_item
-- ----------------------------
DROP TABLE IF EXISTS `tb_item`;
CREATE TABLE `tb_item`  (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '商品id',
  `title` varchar(264) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '商品标题',
  `name` varchar(128) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '商品名称',
  `price` bigint(20) NOT NULL COMMENT '价格（分）',
  `image` varchar(200) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '商品图片',
  `category` varchar(200) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '类目名称',
  `brand` varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '品牌名称',
  `spec` varchar(200) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '规格',
  `status` int(1) NULL DEFAULT 1 COMMENT '商品状态 1-正常，2-下架，3-删除',
  `create_time` datetime NULL DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime NULL DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `status`(`status`) USING BTREE,
  INDEX `updated`(`update_time`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 50002 CHARACTER SET = utf8 COLLATE = utf8_general_ci COMMENT = '商品表' ROW_FORMAT = COMPACT;

-- ----------------------------
-- Records of tb_item
-- ----------------------------
INSERT INTO `tb_item` VALUES (10001, 'RIMOWA 21寸托运箱拉杆箱 SALSA AIR系列果绿色 820.70.36.4', 'SALSA AIR', 16900, 'https://m.360buyimg.com/mobilecms/s720x720_jfs/t6934/364/1195375010/84676/e9f2c55f/597ece38N0ddcbc77.jpg!q70.jpg.webp', '拉杆箱', 'RIMOWA', '{\"颜色\": \"红色\", \"尺码\": \"26寸\"}', 1, '2019-05-01 00:00:00', '2019-05-01 00:00:00');
INSERT INTO `tb_item` VALUES (10002, '安佳脱脂牛奶 新西兰进口轻欣脱脂250ml*24整箱装*2', '脱脂牛奶', 68600, 'https://m.360buyimg.com/mobilecms/s720x720_jfs/t25552/261/1180671662/383855/33da8faa/5b8cf792Neda8550c.jpg!q70.jpg.webp', '牛奶', '安佳', '{\"数量\": 24}', 1, '2019-05-01 00:00:00', '2019-05-01 00:00:00');
INSERT INTO `tb_item` VALUES (10003, '唐狮新品牛仔裤女学生韩版宽松裤子 A款/中牛仔蓝（无绒款） 26', '韩版牛仔裤', 84600, 'https://m.360buyimg.com/mobilecms/s720x720_jfs/t26989/116/124520860/644643/173643ea/5b860864N6bfd95db.jpg!q70.jpg.webp', '牛仔裤', '唐狮', '{\"颜色\": \"蓝色\", \"尺码\": \"26\"}', 1, '2019-05-01 00:00:00', '2019-05-01 00:00:00');
INSERT INTO `tb_item` VALUES (10004, '森马(senma)休闲鞋女2019春季新款韩版系带板鞋学生百搭平底女鞋 黄色 36', '休闲板鞋', 10400, 'https://m.360buyimg.com/mobilecms/s720x720_jfs/t1/29976/8/2947/65074/5c22dad6Ef54f0505/0b5fe8c5d9bf6c47.jpg!q70.jpg.webp', '休闲鞋', '森马', '{\"颜色\": \"白色\", \"尺码\": \"36\"}', 1, '2019-05-01 00:00:00', '2019-05-01 00:00:00');
INSERT INTO `tb_item` VALUES (10005, '花王（Merries）拉拉裤 M58片 中号尿不湿（6-11kg）（日本原装进口）', '拉拉裤', 38900, 'https://m.360buyimg.com/mobilecms/s720x720_jfs/t24370/119/1282321183/267273/b4be9a80/5b595759N7d92f931.jpg!q70.jpg.webp', '拉拉裤', '花王', '{\"型号\": \"XL\"}', 1, '2019-05-01 00:00:00', '2019-05-01 00:00:00');

-- ----------------------------
-- Table structure for tb_item_stock
-- ----------------------------
DROP TABLE IF EXISTS `tb_item_stock`;
CREATE TABLE `tb_item_stock`  (
  `item_id` bigint(20) NOT NULL COMMENT '商品id，关联tb_item表',
  `stock` int(10) NOT NULL DEFAULT 9999 COMMENT '商品库存',
  `sold` int(10) NOT NULL DEFAULT 0 COMMENT '商品销量',
  PRIMARY KEY (`item_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = COMPACT;

-- ----------------------------
-- Records of tb_item_stock
-- ----------------------------
INSERT INTO `tb_item_stock` VALUES (10001, 99996, 3219);
INSERT INTO `tb_item_stock` VALUES (10002, 99999, 54981);
INSERT INTO `tb_item_stock` VALUES (10003, 99999, 189);
INSERT INTO `tb_item_stock` VALUES (10004, 99999, 974);
INSERT INTO `tb_item_stock` VALUES (10005, 99999, 18649);

SET FOREIGN_KEY_CHECKS = 1;
```

其中包含两张表：

- tb_item：商品表，包含商品的基本信息
- tb_item_stock：商品库存表，包含商品的库存信息

之所以将库存分离出来，是因为库存是更新比较频繁的信息，写操作较多。而其他信息修改的频率非常低。



## 3. 导入Demo工程

项目结构如图所示：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031451579.png)

```yml
server:
  port: 8081
spring:
  application:
    name: itemservice
  datasource:
    url: jdbc:mysql://192.168.150.101:3306/heima?useSSL=false
    username: root
    password: 123
    driver-class-name: com.mysql.jdbc.Driver
mybatis-plus:
  type-aliases-package: com.heima.item.pojo
  configuration:
    map-underscore-to-camel-case: true
  global-config:
    db-config:
      update-strategy: not_null
      id-type: auto
logging:
  level:
    com.heima: debug
  pattern:
    dateformat: HH:mm:ss:SSS
```

其中的业务包括：

- 分页查询商品
- 新增商品
- 修改商品
- 修改库存
- 删除商品
- 根据id查询商品
- 根据id查询库存

业务全部使用mybatis-plus来实现，如有需要请自行修改业务逻辑。



### 1. 分页查询商品

在`com.heima.item.web`包的`ItemController`中可以看到接口定义：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031451580.png)



### 2. 新增商品

在`com.heima.item.web`包的`ItemController`中可以看到接口定义：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031451581.png)



### 3. 修改商品

在`com.heima.item.web`包的`ItemController`中可以看到接口定义：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031451583.png)



### 4. 修改库存

在`com.heima.item.web`包的`ItemController`中可以看到接口定义：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031451584.png)



### 5. 删除商品

在`com.heima.item.web`包的`ItemController`中可以看到接口定义：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031451585.png)

这里是采用了逻辑删除，将商品状态修改为3



### 6. 根据id查询商品

在`com.heima.item.web`包的`ItemController`中可以看到接口定义：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031451586.png)

这里只返回了商品信息，不包含库存



### 7. 根据id查询库存

在`com.heima.item.web`包的`ItemController`中可以看到接口定义：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031451587.png)



### 8. 启动

注意修改application.yml文件中配置的mysql地址信息：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031451588.png)

需要修改为自己的虚拟机地址信息、还有账号和密码。

修改后，启动服务，访问：http://localhost:8081/item/10001即可查询数据



## 4.导入商品查询页面

商品查询是购物页面，与商品管理的页面是分离的。

部署方式如图：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031451589.png)

我们需要准备一个反向代理的nginx服务器，如上图红框所示，将静态的商品页面放到nginx目录中。

页面需要的数据通过ajax向服务端（nginx业务集群）查询。



### 1. 运行nginx服务

运行命令：

```powershell
start nginx.exe
```

然后访问 http://localhost/item.html?id=10001即可：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031451590.png)



### 2. 反向代理

现在，页面是假数据展示的。我们需要向服务器发送ajax请求，查询商品数据。

打开控制台，可以看到页面有发起ajax查询数据：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031451591.png)

而这个请求地址同样是80端口，所以被当前的nginx反向代理了。

查看nginx的conf目录下的nginx.conf文件：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031451592.png) 

其中的关键配置如下：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031451593.png)

其中的192.168.150.101是我的虚拟机IP，也就是我的Nginx业务集群要部署的地方：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031451594.png)

完整内容如下：

```nginx
#user  nobody;
worker_processes  1;

events {
    worker_connections  1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;

    sendfile        on;
    #tcp_nopush     on;
    keepalive_timeout  65;

    upstream nginx-cluster{
        server 192.168.150.101:8081;
    }
    server {
        listen       80;
        server_name  localhost;

	location /api {
            proxy_pass http://nginx-cluster;
        }

        location / {
            root   html;
            index  index.html index.htm;
        }

        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
    }
}
```
