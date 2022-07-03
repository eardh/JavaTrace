# Redis原理篇

## 1. 数据结构

### 1. 动态字符串SDS

我们都知道Redis中保存的Key是字符串，value往往是字符串或者字符串的集合。可见字符串是Redis中最常用的一种数据结构。

不过Redis没有直接使用C语言中的字符串，因为C语言字符串存在很多问题：

```c
// c语言，声明字符串
char* s = "hello"
// 本质是字符数组： {'h', 'e', 'l', 'l', 'o', '\0'}
```

- 获取字符串长度的需要通过运算
- 非二进制安全
- 不可修改

Redis构建了一种新的字符串结构，称为**简单动态字符串**（Simple Dynamic String），简称**SDS**。

例如，我们执行命令：

```bash
set name 虎哥
```

那么Redis将在底层创建两个SDS，其中一个是包含“name”的SDS，另一个是包含“虎哥”的SDS。

Redis是C语言实现的，其中SDS是一个结构体，源码如下：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031449196.png)

例如，一个包含字符串“name”的sds结构如下：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031449197.png)

SDS之所以叫做动态字符串，是因为它具备动态扩容的能力，例如一个内容为“hi”的SDS：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031449198.png)

假如我们要给SDS追加一段字符串“,Amy”，这里首先会申请新内存空间：

- 如果新字符串小于1M，则新空间为扩展后字符串长度的两倍+1；
- 如果新字符串大于1M，则新空间为扩展后字符串长度+1M+1。称为**内存预分配**。

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207011117938.png)

优点：

① 获取字符串长度的时间复杂度为O(1)

② 支持动态扩容

③ 减少内存分配次数

④ 二进制安全



### 2. IntSet

IntSet是Redis中set集合的一种实现方式，基于整数数组来实现，并且具备长度可变、有序等特征。

结构如下：

```c
typedef struct intset {
    uint32_t encoding; /* 编码方式，支持存放16位、32位、64位整数*/
    uint32_t length; /* 元素个数 */
    int8_t contents[]; /* 整数数组，保存集合数据*/
} intset;
```

其中的encoding包含三种模式，表示存储的整数大小不同：

```c
/* Note that these encodings are ordered, so:
 * INTSET_ENC_INT16 < INTSET_ENC_INT32 < INTSET_ENC_INT64. */
#define INTSET_ENC_INT16 (sizeof(int16_t)) /* 2字节整数，范围类似java的short*/
#define INTSET_ENC_INT32 (sizeof(int32_t)) /* 4字节整数，范围类似java的int */
#define INTSET_ENC_INT64 (sizeof(int64_t)) /* 8字节整数，范围类似java的long */
```

为了方便查找，Redis会将intset中所有的整数按照升序依次保存在contents数组中，结构如图：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031449199.png)

现在，数组中每个数字都在int16_t的范围内，因此采用的编码方式是INTSET_ENC_INT16，每部分占用的字节大小为：

- encoding：4字节
- length：4字节
- contents：2字节 * 3  = 6字节

**IntSet升级**

现在，假设有一个intset，元素为{5,10,20}，采用的编码是INTSET_ENC_INT16，则每个整数占2字节：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031449200.png)

我们向该其中添加一个数字：50000，这个数字超出了`int16_t`的范围，intset会自动**升级**编码方式到合适的大小。

以当前案例来说流程如下：

① 升级编码为`INTSET_ENC_INT32`, 每个整数占4字节，并按照新的编码方式及元素个数扩容数组

② 倒序依次将数组中的元素拷贝到扩容后的正确位置

③ 将待添加的元素放入数组末尾

④ 最后，将inset的encoding属性改为INTSET_ENC_INT32，将length属性改为4

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031449201.png)

**IntSet新增流程**

```c
intset *intsetAdd(intset *is, int64_t value, uint8_t *success) {
    uint8_t valenc = _intsetValueEncoding(value);// 获取当前值编码
    uint32_t pos; // 要插入的位置
    if (success) *success = 1;
    // 判断编码是不是超过了当前intset的编码
    if (valenc > intrev32ifbe(is->encoding)) {
        // 超出编码，需要升级
        return intsetUpgradeAndAdd(is,value);
    } else {
        // 在当前intset中查找值与value一样的元素的角标pos
        if (intsetSearch(is,value,&pos)) {
            if (success) *success = 0; //如果找到了，则无需插入，直接结束并返回失败
            return is;
        }
        // 数组扩容
        is = intsetResize(is,intrev32ifbe(is->length)+1);
        // 移动数组中pos之后的元素到pos+1，给新元素腾出空间
        if (pos < intrev32ifbe(is->length)) intsetMoveTail(is,pos,pos+1);
    }
    // 插入新元素
    _intsetSet(is,pos,value);
    // 重置元素长度
    is->length = intrev32ifbe(intrev32ifbe(is->length)+1);
    return is;
}

```

**IntSet升级流程**

```c
static intset *intsetUpgradeAndAdd(intset *is, int64_t value) {
    // 获取当前intset编码
    uint8_t curenc = intrev32ifbe(is->encoding);
    // 获取新编码
    uint8_t newenc = _intsetValueEncoding(value);
    // 获取元素个数
    int length = intrev32ifbe(is->length); 
    // 判断新元素是大于0还是小于0 ，小于0插入队首、大于0插入队尾
    int prepend = value < 0 ? 1 : 0;
    // 重置编码为新编码
    is->encoding = intrev32ifbe(newenc);
    // 重置数组大小
    is = intsetResize(is,intrev32ifbe(is->length)+1);
    // 倒序遍历，逐个搬运元素到新的位置，_intsetGetEncoded按照旧编码方式查找旧元素
    while(length--) // _intsetSet按照新编码方式插入新元素
        _intsetSet(is,length+prepend,_intsetGetEncoded(is,length,curenc));
    /* 插入新元素，prepend决定是队首还是队尾*/
    if (prepend)
        _intsetSet(is,0,value);
    else
        _intsetSet(is,intrev32ifbe(is->length),value);
    // 修改数组长度
    is->length = intrev32ifbe(intrev32ifbe(is->length)+1);
    return is;
}

```

**总结**

Intset可以看做是特殊的整数数组，具备一些特点：

① Redis会确保Intset中的元素唯一、有序

② 具备类型升级机制，可以节省内存空间

③ 底层采用二分查找方式来查询



### 3. Dict

我们知道Redis是一个键值型（Key-Value Pair）的数据库，我们可以根据键实现快速的增删改查。而键与值的映射关系正是通过Dict来实现的。

Dict由三部分组成，分别是：哈希表（DictHashTable）、哈希节点（DictEntry）、字典（Dict）

```c
typedef struct dictht {
    // entry数组
    // 数组中保存的是指向entry的指针
    dictEntry **table; 
    // 哈希表大小
    unsigned long size;     
    // 哈希表大小的掩码，总等于size - 1
    unsigned long sizemask;     
    // entry个数
    unsigned long used; 
} dictht;
```

```c
typedef struct dictEntry {
    void *key; // 键
    union {
        void *val;
        uint64_t u64;
        int64_t s64;
        double d;
    } v; // 值
    // 下一个Entry的指针
    struct dictEntry *next; 
} dictEntry;
```

当我们向Dict添加键值对时，Redis首先根据key计算出hash值（h），然后利用 h & sizemask来计算元素应该存储到数组中的哪个索引位置。

我们存储k1=v1，假设k1的哈希值h =1，则1&3 =1，因此k1=v1要存储到数组角标1位置。

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031449202.png)

Dict由三部分组成，分别是：哈希表（DictHashTable）、哈希节点（DictEntry）、字典（Dict）

```c
typedef struct dict {
    dictType *type; // dict类型，内置不同的hash函数
    void *privdata;     // 私有数据，在做特殊hash运算时用
    dictht ht[2]; // 一个Dict包含两个哈希表，其中一个是当前数据，另一个一般是空，rehash时使用
    long rehashidx;   // rehash的进度，-1表示未进行
    int16_t pauserehash; // rehash是否暂停，1则暂停，0则继续
} dict;
```



#### 1. Dict的扩容

Dict中的HashTable就是数组结合单向链表的实现，当集合中元素较多时，必然导致哈希冲突增多，链表过长，则查询效率会大大降低。

Dict在每次新增键值对时都会检查**负载因子**（LoadFactor = used/size） ，满足以下两种情况时会触发**哈希表扩容**：

- 哈希表的 LoadFactor >= 1，并且服务器没有执行 BGSAVE 或者 BGREWRITEAOF 等后台进程；
- 哈希表的 LoadFactor > 5 ；

```c
static int _dictExpandIfNeeded(dict *d){
    // 如果正在rehash，则返回ok
    if (dictIsRehashing(d)) return DICT_OK;    // 如果哈希表为空，则初始化哈希表为默认大小：4
    if (d->ht[0].size == 0) return dictExpand(d, DICT_HT_INITIAL_SIZE);
    // 当负载因子（used/size）达到1以上，并且当前没有进行bgrewrite等子进程操作
    // 或者负载因子超过5，则进行 dictExpand ，也就是扩容
    if (d->ht[0].used >= d->ht[0].size &&
        (dict_can_resize || d->ht[0].used/d->ht[0].size > dict_force_resize_ratio){
        // 扩容大小为used + 1，底层会对扩容大小做判断，实际上找的是第一个大于等于 used+1 的 2^n
        return dictExpand(d, d->ht[0].used + 1);
    }
    return DICT_OK;
}
```



#### 2. Dict的收缩

Dict除了扩容以外，每次删除元素时，也会对负载因子做检查，当LoadFactor < 0.1 时，会做哈希表收缩：

```c
// t_hash.c # hashTypeDeleted() 
...
    if (dictDelete((dict*)o->ptr, field) == C_OK) {
        deleted = 1;
        // 删除成功后，检查是否需要重置Dict大小，如果需要则调用dictResize重置
        /* Always check if the dictionary needs a resize after a delete. */
        if (htNeedsResize(o->ptr)) dictResize(o->ptr);
    }
...
```

```c
// server.c 文件
int htNeedsResize(dict *dict) {
    long long size, used;
    // 哈希表大小
    size = dictSlots(dict);
    // entry数量
    used = dictSize(dict);
    // size > 4（哈希表初识大小）并且 负载因子低于0.1
    return (size > DICT_HT_INITIAL_SIZE && (used*100/size < HASHTABLE_MIN_FILL));
}
```

```c
int dictResize(dict *d){
    unsigned long minimal;
    // 如果正在做bgsave或bgrewriteof或rehash，则返回错误
    if (!dict_can_resize || dictIsRehashing(d)) 
        return DICT_ERR;
    // 获取used，也就是entry个数
    minimal = d->ht[0].used;
    // 如果used小于4，则重置为4
    if (minimal < DICT_HT_INITIAL_SIZE)
        minimal = DICT_HT_INITIAL_SIZE;
    // 重置大小为minimal，其实是第一个大于等于minimal的2^n
    return dictExpand(d, minimal);
}
```



#### 3. Dict的rehash

不管是扩容还是收缩，必定会创建新的哈希表，导致哈希表的size和sizemask变化，而key的查询与sizemask有关。因此必须对哈希表中的每一个key重新计算索引，插入新的哈希表，这个过程称为**rehash**。过程是这样的：

① 计算新hash表的realeSize，值取决于当前要做的是扩容还是收缩：

- 如果是扩容，则新size为第一个大于等于`dict.ht[0].used + 1`的2^n
- 如果是收缩，则新size为第一个大于等于`dict.ht[0].used`的2^n （不得小于4）

② 按照新的realeSize申请内存空间，创建dictht，并赋值给dict.ht[1]

③ 设置`dict.rehashidx = 0`，标示开始rehash

④ 将`dict.ht[0]`中的每一个dictEntry都rehash到dict.ht[1]

⑤ 将`dict.ht[1]`赋值给`dict.ht[0]`，给dict.ht[1]初始化为空哈希表，释放原来的dict.ht[0]的内存

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031449203.png)

Dict的rehash并不是一次性完成的。试想一下，如果Dict中包含数百万的entry，要在一次rehash完成，极有可能导致主线程阻塞。因此Dict的rehash是分多次、渐进式的完成，因此称为渐进式rehash。流程如下：

① 计算新hash表的size，值取决于当前要做的是扩容还是收缩：

- 如果是扩容，则新size为第一个大于等于dict.ht[0].used + 1的2^n
- 如果是收缩，则新size为第一个大于等于dict.ht[0].used的2^n （不得小于4）

② 按照新的size申请内存空间，创建dictht，并赋值给dict.ht[1]

③ 设置dict.rehashidx = 0，标示开始rehash

④ 每次执行新增、查询、修改、删除操作时，都检查一下dict.rehashidx是否大于-1，如果是则将dict.ht[0].table[rehashidx]的entry链表rehash到dict.ht[1]，并且将rehashidx++。直至dict.ht[0]的所有数据都rehash到dict.ht[1]

⑤ 将dict.ht[1]赋值给dict.ht[0]，给dict.ht[1]初始化为空哈希表，释放原来的dict.ht[0]的内存

⑥ 将rehashidx赋值为-1，代表rehash结束

⑦ 在rehash过程中，新增操作，则直接写入ht[1]，查询、修改和删除则会在dict.ht[0]和dict.ht[1]依次查找并执行。这样可以确保ht[0]的数据只减不增，随着rehash最终为空



#### 3.  总结

Dict的结构：

- 类似java的HashTable，底层是数组加链表来解决哈希冲突
- Dict包含两个哈希表，ht[0]平常用，ht[1]用来rehash

Dict的伸缩：

- 当LoadFactor大于5或者LoadFactor大于1并且没有子进程任务时，Dict扩容
- 当LoadFactor小于0.1时，Dict收缩
- 扩容大小为第一个大于等于used + 1的2^n
- 收缩大小为第一个大于等于used 的2^n
- Dict采用渐进式rehash，每次访问Dict时执行一次rehash
- rehash时ht[0]只减不增，新增操作只在ht[1]执行，其它操作在两个哈希表



### 4. ZipList

**ZipList** 是一种特殊的“双端链表” ，由一系列特殊编码的连续内存块组成。可以在任意一端进行压入/弹出操作, 并且该操作的时间复杂度为 O(1)。

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031449204.png)

| 属性    | 类型     | 长度   | 用途                                                         |
| ------- | -------- | ------ | ------------------------------------------------------------ |
| zlbytes | uint32_t | 4 字节 | 记录整个压缩列表占用的内存字节数                             |
| zltail  | uint32_t | 4 字节 | 记录压缩列表表尾节点距离压缩列表的起始地址有多少字节，通过这个偏移量，可以确定表尾节点的地址。 |
| zllen   | uint16_t | 2 字节 | 记录了压缩列表包含的节点数量。 最大值为UINT16_MAX （65534），如果超过这个值，此处会记录为65535，但节点的真实数量需要遍历整个压缩列表才能计算得出。 |
| entry   | 列表节点 | 不定   | 压缩列表包含的各个节点，节点的长度由节点保存的内容决定。     |
| zlend   | uint8_t  | 1 字节 | 特殊值 0xFF （十进制 255 ），用于标记压缩列表的末端。        |



#### 1. ZipListEntry

**ZipList** 中的Entry并不像普通链表那样记录前后节点的指针，因为记录两个指针要占用16个字节，浪费内存。而是采用了下面的结构：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031449205.png)

- previous_entry_length：前一节点的长度，占1个或5个字节。
  - 如果前一节点的长度小于254字节，则采用1个字节来保存这个长度值
  - 如果前一节点的长度大于254字节，则采用5个字节来保存这个长度值，第一个字节为0xfe，后四个字节才是真实长度数据

- encoding：编码属性，记录content的数据类型（字符串还是整数）以及长度，占用1个、2个或5个字节

- contents：负责保存节点的数据，可以是字符串或整数

> ZipList中所有存储长度的数值均采用小端字节序，即低位字节在前，高位字节在后。例如：数值0x1234，采用小端字节序后实际存储值为：0x3412



#### 2. Encoding编码

ZipListEntry中的encoding编码分为字符串和整数两种：

- **字符串**：如果encoding是以“00”、“01”或者“10”开头，则证明content是字符串

  | 编码                                                 | 编码长度 | 字符串大小           |
  | ---------------------------------------------------- | -------- | -------------------- |
  | \|00pppppp\|                                         | 1  bytes | <=  63 bytes         |
  | \|01pppppp\|qqqqqqqq\|                               | 2 bytes  | <=  16383 bytes      |
  | \|10000000\|qqqqqqqq\|rrrrrrrr\|ssssssss\|tttttttt\| | 5  bytes | <=  4294967295 bytes |

例如，我们要保存字符串：“ab”和 “bc”

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031449207.png)

- **整数**：如果encoding是以“11”开始，则证明content是整数，且encoding固定只占用1个字节

| 编码     | 编码长度 | 整数类型                                                   |
| -------- | -------- | ---------------------------------------------------------- |
| 11000000 | 1        | int16_t（2  bytes）                                        |
| 11010000 | 1        | int32_t（4  bytes）                                        |
| 11100000 | 1        | int64_t（8  bytes）                                        |
| 11110000 | 1        | 24位有符整数(3 bytes)                                      |
| 11111110 | 1        | 8位有符整数(1 bytes)                                       |
| 1111xxxx | 1        | 直接在xxxx位置保存数值，范围从0001~1101，减1后结果为实际值 |

例如，一个ZipList中包含两个整数值：“2”和“5”

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031449208.png)



#### 3. ZipList的连锁更新问题

ZipList的每个Entry都包含previous_entry_length来记录上一个节点的大小，长度是1个或5个字节：

- 如果前一节点的长度小于254字节，则采用1个字节来保存这个长度值
- 如果前一节点的长度大于等于254字节，则采用5个字节来保存这个长度值，第一个字节为0xfe，后四个字节才是真实长度数据

现在，假设我们有N个连续的、长度为250~253字节之间的entry，因此entry的`previous_entry_length`属性用1个字节即可表示，如图所示：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031449209.png)

ZipList这种特殊情况下产生的连续多次空间扩展操作称之为连锁更新（Cascade Update）。新增、删除都可能导致连锁更新的发生。



#### 4. 总结

ZipList特性：

① 压缩列表的可以看做一种连续内存空间的"双向链表"

② 列表的节点之间不是通过指针连接，而是记录上一节点和本节点长度来寻址，内存占用较低

③ 如果列表数据过多，导致链表过长，可能影响查询性能

④ 增或删较大数据时有可能发生连续更新问题



### 5. QuickList

问题1：ZipList虽然节省内存，但申请内存必须是连续空间，如果内存占用较多，申请内存效率很低。怎么办？

- 为了缓解这个问题，我们必须限制ZipList的长度和entry大小。

问题2：但是我们要存储大量数据，超出了ZipList最佳的上限该怎么办？

- 我们可以创建多个ZipList来分片存储数据。

问题3：数据拆分后比较分散，不方便管理和查找，这多个ZipList如何建立联系？

- Redis在3.2版本引入了新的数据结构**QuickList**，它是一个双端链表，只不过链表中的每个节点都是一个ZipList。

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031449210.png)

为了避免QuickList中的每个ZipList中entry过多，Redis提供了一个配置项：`list-max-ziplist-size`来限制。

- 如果值为正，则代表ZipList的允许的entry个数的最大值

- 如果值为负，则代表ZipList的最大内存大小，分5种情况：
  1. -1：每个ZipList的内存占用不能超过4kb
  2. -2：每个ZipList的内存占用不能超过8kb
  3. -3：每个ZipList的内存占用不能超过16kb
  4. -4：每个ZipList的内存占用不能超过32kb
  5. -5：每个ZipList的内存占用不能超过64kb

其默认值为 -2：

```bash
config get list-max-ziplist-size
```

除了控制ZipList的大小，QuickList还可以对节点的ZipList做压缩。通过配置项`list-compress-depth`来控制。因为链表一般都是从首尾访问较多，所以首尾是不压缩的。这个参数是控制首尾不压缩的节点个数：

- 0：特殊值，代表不压缩
- 1：标示QuickList的首尾各有1个节点不压缩，中间节点压缩
- 2：标示QuickList的首尾各有2个节点不压缩，中间节点压缩
- 以此类推

默认值：

```bash
config get list-compress-depth
```

以下是QuickList的和QuickListNode的**结构源码**：

```c
typedef struct quicklist {
    // 头节点指针
    quicklistNode *head; 
    // 尾节点指针
    quicklistNode *tail; 
    // 所有ziplist的entry的数量
    unsigned long count;    
    // ziplists总数量
    unsigned long len;
    // ziplist的entry上限，默认值 -2 
    int fill : QL_FILL_BITS;     
    // 首尾不压缩的节点数量
    unsigned int compress : QL_COMP_BITS;
    // 内存重分配时的书签数量及数组，一般用不到
    unsigned int bookmark_count: QL_BM_BITS;
    quicklistBookmark bookmarks[];
} quicklist;
```

```c
typedef struct quicklistNode {
    // 前一个节点指针
    struct quicklistNode *prev;
    // 下一个节点指针
    struct quicklistNode *next;
    // 当前节点的ZipList指针
    unsigned char *zl;
    // 当前节点的ZipList的字节大小
    unsigned int sz;
    // 当前节点的ZipList的entry个数
    unsigned int count : 16;  
    // 编码方式：1，ZipList; 2，lzf压缩模式
    unsigned int encoding : 2;
    // 数据容器类型（预留）：1，其它；2，ZipList
    unsigned int container : 2;
    // 是否被解压缩。1：则说明被解压了，将来要重新压缩
    unsigned int recompress : 1;
    unsigned int attempted_compress : 1; //测试用
    unsigned int extra : 10; /*预留字段*/
} quicklistNode;
```

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031449211.png)

QuickList的**特点**：

- 是一个节点为ZipList的双端链表
- 节点采用ZipList，解决了传统链表的内存占用问题
- 控制了ZipList大小，解决连续内存空间申请效率问题
- 中间节点可以压缩，进一步节省了内存



### 6. SkipList

SkipList（**跳表**）首先是链表，但与传统链表相比有几点差异：

- 元素按照升序排列存储
- 节点可能包含多个指针，指针跨度不同。

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031449212.png)

```c
// t_zset.c
typedef struct zskiplist {
    // 头尾节点指针
    struct zskiplistNode *header, *tail;
    // 节点数量
    unsigned long length;
    // 最大的索引层级，默认是1
    int level;
} zskiplist;
```

```c
// t_zset.c
typedef struct zskiplistNode {
    sds ele; // 节点存储的值
    double score;// 节点分数，排序、查找用
    struct zskiplistNode *backward; // 前一个节点指针
    struct zskiplistLevel {
        struct zskiplistNode *forward; // 下一个节点指针
        unsigned long span; // 索引跨度
    } level[]; // 多级索引数组
} zskiplistNode;
```

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031449213.png)

SkipList的特点：

- 跳跃表是一个双向链表，每个节点都包含score和ele值
- 节点按照score值排序，score值一样则按照ele字典排序
- 每个节点都可以包含多层指针，层数是1到32之间的随机数
- 不同层指针到下一个节点的跨度不同，层级越高，跨度越大
- 增删改查效率与红黑树基本一致，实现却更简单



### 7. RedisObject

Redis中的任意数据类型的键和值都会被封装为一个RedisObject，也叫做Redis对象，源码如下：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031449214.png)

**1. Redis的编码方式**

Redis中会根据存储的数据类型不同，选择不同的编码方式，共包含11种不同类型：

| 编号 | 编码方式                | 说明                   |
| ---- | ----------------------- | ---------------------- |
| 0    | OBJ_ENCODING_RAW        | raw编码动态字符串      |
| 1    | OBJ_ENCODING_INT        | long类型的整数的字符串 |
| 2    | OBJ_ENCODING_HT         | hash表（字典dict）     |
| 3    | OBJ_ENCODING_ZIPMAP     | 已废弃                 |
| 4    | OBJ_ENCODING_LINKEDLIST | 双端链表               |
| 5    | OBJ_ENCODING_ZIPLIST    | 压缩列表               |
| 6    | OBJ_ENCODING_INTSET     | 整数集合               |
| 7    | OBJ_ENCODING_SKIPLIST   | 跳表                   |
| 8    | OBJ_ENCODING_EMBSTR     | embstr的动态字符串     |
| 9    | OBJ_ENCODING_QUICKLIST  | 快速列表               |
| 10   | OBJ_ENCODING_STREAM     | Stream流               |

**2. 五种数据结构**

Redis中会根据存储的数据类型不同，选择不同的编码方式。每种数据类型的使用的编码方式如下：

| 数据类型   | 编码方式                                           |
| ---------- | -------------------------------------------------- |
| OBJ_STRING | int、embstr、raw                                   |
| OBJ_LIST   | LinkedList和ZipList(3.2以前)、QuickList（3.2以后） |
| OBJ_SET    | intset、HT                                         |
| OBJ_ZSET   | ZipList、HT、SkipList                              |
| OBJ_HASH   | ZipList、HT                                        |



### 8. 五种数据结构

#### 1. String

String是Redis中最常见的数据存储类型：

- 其基本编码方式是**RAW**，基于简单动态字符串（SDS）实现，存储上限为512mb。

  ![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031449215.png)

- 如果存储的SDS长度小于44字节，则会采用**EMBSTR**编码，此时object head与SDS是一段连续空间。申请内存时只需要调用一次内存分配函数，效率更高。

  ![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031449216.png)

- 如果存储的字符串是整数值，并且大小在LONG_MAX范围内，则会采用**INT**编码：直接将数据保存在RedisObject的ptr指针位置（刚好8字节），不再需要SDS了。

  ![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031449217.png)



#### 2. List

Redis的List类型可以从首、尾操作列表中的元素：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031449218.png)

哪一个数据结构能满足上述特征？

- LinkedList ：普通链表，可以从双端访问，内存占用较高，内存碎片较多
- ZipList ：压缩列表，可以从双端访问，内存占用低，存储上限低
- QuickList：LinkedList + ZipList，可以从双端访问，内存占用较低，包含多个ZipList，存储上限高

Redis的List结构类似一个双端链表，可以从首、尾操作列表中的元素：

- 在3.2版本之前，Redis采用ZipList和LinkedList来实现List，当元素数量小于512并且元素大小小于64字节时采用ZipList编码，超过则采用LinkedList编码。
- 在3.2版本之后，Redis统一采用QuickList来实现List：

```c
void pushGenericCommand(client *c, int where, int xx) {
    int j;
    // 尝试找到KEY对应的list
    robj *lobj = lookupKeyWrite(c->db, c->argv[1]);
    // 检查类型是否正确
    if (checkType(c,lobj,OBJ_LIST)) return;
    // 检查是否为空
    if (!lobj) {
        if (xx) {
            addReply(c, shared.czero);
            return;
        }
        // 为空，则创建新的QuickList
        lobj = createQuicklistObject();
        quicklistSetOptions(lobj->ptr, server.list_max_ziplist_size,
                            server.list_compress_depth);
        dbAdd(c->db,c->argv[1],lobj);
    }
    // 略 ...
}
```

```c
robj *createQuicklistObject(void) {
    // 申请内存并初始化QuickList
    quicklist *l = quicklistCreate();
    // 创建RedisObject，type为OBJ_LIST
    // ptr指向 QuickList
    robj *o = createObject(OBJ_LIST,l);
    // 设置编码为 QuickList
    o->encoding = OBJ_ENCODING_QUICKLIST;
    return o;
}
```

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031449219.png)



#### 3. Set

Set是Redis中的单列集合，满足下列特点：

- 不保证有序性
- 保证元素唯一
- 求交集、并集、差集

可以看出，Set对查询元素的效率要求非常高，思考一下，什么样的数据结构可以满足？

- HashTable，也就是Redis中的Dict，不过Dict是双列集合（可以存键、值对）

Set是Redis中的集合，不一定确保元素有序，可以满足元素唯一、查询效率要求极高。

- 为了查询效率和唯一性，set采用HT编码（Dict）。Dict中的key用来存储元素，value统一为null。
- 当存储的所有数据都是整数，并且元素数量不超过`set-max-intset-entries`时，Set会采用IntSet编码，以节省内存。

```c
robj *setTypeCreate(sds value) {
    // 判断value是否是数值类型 long long 
    if (isSdsRepresentableAsLongLong(value,NULL) == C_OK)
        // 如果是数值类型，则采用IntSet编码
        return createIntsetObject();
    // 否则采用默认编码，也就是HT
    return createSetObject();
}
```

```c
robj *createIntsetObject(void) {
    // 初始化INTSET并申请内存空间
    intset *is = intsetNew();
    // 创建RedisObject
    robj *o = createObject(OBJ_SET,is);
    // 指定编码为INTSET
    o->encoding = OBJ_ENCODING_INTSET;
    return o;
}
```

```c
robj *createSetObject(void) {
    // 初始化Dict类型，并申请内存
    dict *d = dictCreate(&setDictType,NULL);
    // 创建RedisObject
    robj *o = createObject(OBJ_SET,d);
    // 设置encoding为HT
    o->encoding = OBJ_ENCODING_HT;
    return o;
}
```

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031449220.png)



#### 4. ZSet

ZSet也就是SortedSet，其中每一个元素都需要指定一个score值和member值：

- 可以根据score值排序后
- member必须唯一
- 可以根据member查询分数

因此，zset底层数据结构必须满足**键值存储、键必须唯一、可排序**这几个需求。之前学习的哪种编码结构可以满足？

- SkipList：可以排序，并且可以同时存储score和ele值（member）

- HT（Dict）：可以键值存储，并且可以根据key找value

```c
// zset结构
typedef struct zset {
    // Dict指针
    dict *dict;
    // SkipList指针
    zskiplist *zsl;
} zset;
```

```c
robj *createZsetObject(void) {
    zset *zs = zmalloc(sizeof(*zs));
    robj *o;
    // 创建Dict
    zs->dict = dictCreate(&zsetDictType,NULL);
    // 创建SkipList
    zs->zsl = zslCreate(); 
    o = createObject(OBJ_ZSET,zs);
    o->encoding = OBJ_ENCODING_SKIPLIST;
    return o;
}
```

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031449221.png)

当元素数量不多时，HT和SkipList的优势不明显，而且更耗内存。因此zset还会采用ZipList结构来节省内存，不过需要同时满足两个条件：

① 元素数量小于`zset_max_ziplist_entries`，默认值128

② 每个元素都小于`zset_max_ziplist_value`字节，默认值64

```c
// zadd添加元素时，先根据key找到zset，不存在则创建新的zset
zobj = lookupKeyWrite(c->db,key);
if (checkType(c,zobj,OBJ_ZSET)) goto cleanup;
// 判断是否存在
if (zobj == NULL) { // zset不存在
    if (server.zset_max_ziplist_entries == 0 ||
        server.zset_max_ziplist_value < sdslen(c->argv[scoreidx+1]->ptr))
    { // zset_max_ziplist_entries设置为0就是禁用了ZipList，
        // 或者value大小超过了zset_max_ziplist_value，采用HT + SkipList
        zobj = createZsetObject();
    } else { // 否则，采用 ZipList
        zobj = createZsetZiplistObject();
    }
    dbAdd(c->db,key,zobj); 
}
// ....
zsetAdd(zobj, score, ele, flags, &retflags, &newscore);
```

```c
robj *createZsetObject(void) {
    // 申请内存
    zset *zs = zmalloc(sizeof(*zs));
    robj *o;
    // 创建Dict
    zs->dict = dictCreate(&zsetDictType,NULL);
    // 创建SkipList
    zs->zsl = zslCreate();
    o = createObject(OBJ_ZSET,zs);
    o->encoding = OBJ_ENCODING_SKIPLIST;
    return o;
}
```

```c
robj *createZsetZiplistObject(void) {
    // 创建ZipList
    unsigned char *zl = ziplistNew();
    robj *o = createObject(OBJ_ZSET,zl);
    o->encoding = OBJ_ENCODING_ZIPLIST;
    return o;
}
```

```c
int zsetAdd(robj *zobj, double score, sds ele, int in_flags, int *out_flags, double *newscore) {
    /* 判断编码方式*/
    if (zobj->encoding == OBJ_ENCODING_ZIPLIST) {// 是ZipList编码
        unsigned char *eptr;
        // 判断当前元素是否已经存在，已经存在则更新score即可
        if ((eptr = zzlFind(zobj->ptr,ele,&curscore)) != NULL) {
            //...略
            return 1;
        } else if (!xx) {
            // 元素不存在，需要新增，则判断ziplist长度有没有超、元素的大小有没有超
            if (zzlLength(zobj->ptr)+1 > server.zset_max_ziplist_entries
                || sdslen(ele) > server.zset_max_ziplist_value 
                || !ziplistSafeToAdd(zobj->ptr, sdslen(ele)))
            { // 如果超出，则需要转为SkipList编码
                zsetConvert(zobj,OBJ_ENCODING_SKIPLIST);
            } else {
                zobj->ptr = zzlInsert(zobj->ptr,ele,score);
                if (newscore) *newscore = score;
                *out_flags |= ZADD_OUT_ADDED;
                return 1;
            }
        } else {
            *out_flags |= ZADD_OUT_NOP;
            return 1;
        }
    }
    // 本身就是SKIPLIST编码，无需转换
    if (zobj->encoding == OBJ_ENCODING_SKIPLIST) {
        // ...略
    } else {
        serverPanic("Unknown sorted set encoding");
    }
    return 0; /* Never reached. */
}
```

ziplist本身没有排序功能，而且没有键值对的概念，因此需要有zset通过编码实现：

- ZipList是连续内存，因此score和element是紧挨在一起的两个entry， element在前，score在后
- score越小越接近队首，score越大越接近队尾，按照score值升序排列

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031449222.png)



#### 5. Hash

Hash结构与Redis中的Zset非常类似：

- 都是键值存储
- 都需求根据键获取值
- 键必须唯一

区别如下：

- zset的键是member，值是score；hash的键和值都是任意值
- zset要根据score排序；hash则无需排序

因此，Hash底层采用的编码与Zset也基本一致，只需要把排序有关的SkipList去掉即可：

- Hash结构默认采用ZipList编码，用以节省内存。 ZipList中相邻的两个entry 分别保存field和value

  ![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031449223.png)

- 当数据量较大时，Hash结构会转为HT编码，也就是Dict，触发条件有两个：

  1. ZipList中的元素数量超过了hash-max-ziplist-entries（默认512）
  2. ZipList中的任意entry大小超过了hash-max-ziplist-value（默认64字节）

  ![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031449224.png)

```c
void hsetCommand(client *c) {// hset user1 name Jack age 21
    int i, created = 0;
    robj *o; // 略 ...
    // 判断hash的key是否存在，不存在则创建一个新的，默认采用ZipList编码
    if ((o = hashTypeLookupWriteOrCreate(c,c->argv[1])) == NULL) return;
    // 判断是否需要把ZipList转为Dict
    hashTypeTryConversion(o,c->argv,2,c->argc-1);
    // 循环遍历每一对field和value，并执行hset命令
    for (i = 2; i < c->argc; i += 2)
        created += !hashTypeSet(o,c->argv[i]->ptr,c->argv[i+1]->ptr,HASH_SET_COPY);
    // 略 ...
}
```

```c
robj *hashTypeLookupWriteOrCreate(client *c, robj *key) {
    // 查找key
    robj *o = lookupKeyWrite(c->db,key);
    if (checkType(c,o,OBJ_HASH)) return NULL;
    // 不存在，则创建新的
    if (o == NULL) {
        o = createHashObject();
        dbAdd(c->db,key,o);
    }
    return o;
}
```

```c
robj *createHashObject(void) {
    // 默认采用ZipList编码，申请ZipList内存空间
    unsigned char *zl = ziplistNew();
    robj *o = createObject(OBJ_HASH, zl);
    // 设置编码
    o->encoding = OBJ_ENCODING_ZIPLIST;
    return o;
}
```

```c
void hashTypeTryConversion(robj *o, robj **argv, int start, int end) {
    int i;
    size_t sum = 0;
    // 本来就不是ZipList编码，什么都不用做了
    if (o->encoding != OBJ_ENCODING_ZIPLIST) return;
    // 依次遍历命令中的field、value参数
    for (i = start; i <= end; i++) {
        if (!sdsEncodedObject(argv[i]))
            continue;
        size_t len = sdslen(argv[i]->ptr);
        // 如果field或value超过hash_max_ziplist_value，则转为HT
        if (len > server.hash_max_ziplist_value) {
            hashTypeConvert(o, OBJ_ENCODING_HT);
            return;
        }
        sum += len;
    }// ziplist大小超过1G，也转为HT
    if (!ziplistSafeToAdd(o->ptr, sum))
        hashTypeConvert(o, OBJ_ENCODING_HT);
}
```

```c
int hashTypeSet(robj *o, sds field, sds value, int flags) {
    int update = 0;
    // 判断是否为ZipList编码
    if (o->encoding == OBJ_ENCODING_ZIPLIST) {
        unsigned char *zl, *fptr, *vptr;
        zl = o->ptr;
        // 查询head指针
        fptr = ziplistIndex(zl, ZIPLIST_HEAD);
        if (fptr != NULL) { // head不为空，说明ZipList不为空，开始查找key
            fptr = ziplistFind(zl, fptr, (unsigned char*)field, sdslen(field), 1);
            if (fptr != NULL) {// 判断是否存在，如果已经存在则更新
                update = 1;
                zl = ziplistReplace(zl, vptr, (unsigned char*)value,
                        sdslen(value));
            }
        }
        // 不存在，则直接push
        if (!update) { // 依次push新的field和value到ZipList的尾部
            zl = ziplistPush(zl, (unsigned char*)field, sdslen(field),
                    ZIPLIST_TAIL);
            zl = ziplistPush(zl, (unsigned char*)value, sdslen(value),
                    ZIPLIST_TAIL);
        }
        o->ptr = zl;
        /* 插入了新元素，检查list长度是否超出，超出则转为HT */
        if (hashTypeLength(o) > server.hash_max_ziplist_entries)
            hashTypeConvert(o, OBJ_ENCODING_HT);
    } else if (o->encoding == OBJ_ENCODING_HT) {
        // HT编码，直接插入或覆盖
    } else {
        serverPanic("Unknown hash encoding");
    }
    return update;
}
```







## 2. 网络模型

### 1. 用户空间和内核空间

服务器大多都采用Linux系统，这里我们以Linux为例来讲解：

任何Linux发行版，其系统内核都是Linux。我们的应用都需要通过Linux内核与硬件交互。

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031449225.png)

为了避免用户应用导致冲突甚至内核崩溃，用户应用与内核是分离的：

l进程的寻址空间会划分为两部分：**内核空间、用户空间**

- **用户空间**只能执行受限的命令（Ring3），而且不能直接调用系统资源，必须通过内核提供的接口来访问

- **内核空间**可以执行特权命令（Ring0），调用一切系统资源

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031449226.png)

Linux系统为了提高IO效率，会在用户空间和内核空间都加入缓冲区：

- 写数据时，要把用户缓冲数据拷贝到内核缓冲区，然后写入设备

- 读数据时，要从设备读取数据到内核缓冲区，然后拷贝到用户缓冲区

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031449227.png)



### 2. 阻塞IO

在《UNIX网络编程》一书中，总结归纳了5种IO模型：

- 阻塞IO（Blocking IO）
- 非阻塞IO（Nonblocking IO）
- IO多路复用（IO Multiplexing）
- 信号驱动IO（Signal Driven IO）
- 异步IO（Asynchronous IO）

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031449228.png)

顾名思义，阻塞IO就是两个阶段都必须阻塞等待。

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031449229.png)

阶段一：

① 用户进程尝试读取数据（比如网卡数据）

② 此时数据尚未到达，内核需要等待数据

③ 此时用户进程也处于阻塞状态

阶段二：

① 数据到达并拷贝到内核缓冲区，代表已就绪

② 将内核数据拷贝到用户缓冲区

③ 拷贝过程中，用户进程依然阻塞等待

④ 拷贝完成，用户进程解除阻塞，处理数据

可以看到，阻塞IO模型中，用户进程在两个阶段都是阻塞状态。



### 3. 非阻塞IO

顾名思义，非阻塞IO的recvfrom操作会立即返回结果而不是阻塞用户进程。

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031449230.png)

阶段一：

① 用户进程尝试读取数据（比如网卡数据）

② 此时数据尚未到达，内核需要等待数据

③ 返回异常给用户进程

④ 用户进程拿到error后，再次尝试读取

⑤ 循环往复，直到数据就绪

阶段二：

① 将内核数据拷贝到用户缓冲区

② 拷贝过程中，用户进程依然阻塞等待

③ 拷贝完成，用户进程解除阻塞，处理数据

可以看到，非阻塞IO模型中，用户进程在第一个阶段是非阻塞，第二个阶段是阻塞状态。虽然是非阻塞，但性能并没有得到提高。而且忙等机制会导致CPU空转，CPU使用率暴增。



### 4. IO多路复用

无论是阻塞IO还是非阻塞IO，用户应用在一阶段都需要调用recvfrom来获取数据，差别在于无数据时的处理方案：

- 如果调用recvfrom时，恰好**没有**数据，阻塞IO会使CPU阻塞，非阻塞IO使CPU空转，都不能充分发挥CPU的作用。
- 如果调用recvfrom时，恰好**有**数据，则用户进程可以直接进入第二阶段，读取并处理数据

而在单线程情况下，只能依次处理IO事件，如果正在处理的IO事件恰好未就绪（数据不可读或不可写），线程就会被阻塞，所有IO事件都必须等待，性能自然会很差。

就比如服务员给顾客点餐，分两步：

① 顾客思考要吃什么（等待数据就绪）

② 顾客想好了，开始点餐（读取数据）

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031449231.png)

要提高效率有几种办法？

- 方案一：增加更多服务员（多线程）

- 方案二：不排队，谁想好了吃什么（数据就绪了），服务员就给谁点餐（用户应用就去读取数据）

那么问题来了：用户进程如何知道内核中数据是否就绪呢？

**文件描述符**（File Descriptor）：简称FD，是一个从0 开始的无符号整数，用来关联Linux中的一个文件。在Linux中，一切皆文件，例如常规文件、视频、硬件设备等，当然也包括网络套接字（Socket）。

**IO多路复用**：是利用单个线程来同时监听多个FD，并在某个FD可读、可写时得到通知，从而避免无效的等待，充分利用CPU资源。

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031449232.png)

阶段一：

① 用户进程调用select，指定要监听的FD集合

② 内核监听FD对应的多个socket

③ 任意一个或多个socket数据就绪则返回readable

④ 此过程中用户进程阻塞

阶段二：

① 用户进程找到就绪的socket

② 依次调用recvfrom读取数据

③ 内核将数据拷贝到用户空间

④ 用户进程处理数据

**IO多路复用**是利用单个线程来同时监听多个FD，并在某个FD可读、可写时得到通知，从而避免无效的等待，充分利用CPU资源。不过监听FD的方式、通知的方式又有多种实现，常见的有：

- select
- poll
- epoll

差异：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031449233.png)

- select和poll只会通知用户进程有FD就绪，但不确定具体是哪个FD，需要用户进程逐个遍历FD来确认
- epoll则会在通知用户进程FD就绪的同时，把已就绪的FD写入用户空间



#### 1. select

**select**是Linux最早是由的I/O多路复用技术：

```c
// 定义类型别名 __fd_mask，本质是 long int
typedef long int __fd_mask;

/* fd_set 记录要监听的fd集合，及其对应状态 */
typedef struct {
    // fds_bits是long类型数组，长度为 1024/32 = 32
    // 共1024个bit位，每个bit位代表一个fd，0代表未就绪，1代表就绪
    __fd_mask fds_bits[__FD_SETSIZE / __NFDBITS];
    // ...
} fd_set;

// select函数，用于监听fd_set，也就是多个fd的集合
int select(
    int nfds, // 要监视的fd_set的最大fd + 1
    fd_set *readfds, // 要监听读事件的fd集合
    fd_set *writefds,// 要监听写事件的fd集合
    fd_set *exceptfds, // // 要监听异常事件的fd集合
    // 超时时间，null-用不超时；0-不阻塞等待；大于0-固定等待时间
    struct timeval *timeout

```

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031449234.gif)

select模式存在的问题：

- 需要将整个fd_set从用户空间拷贝到内核空间，select结束还要再次拷贝回用户空间
- select无法得知具体是哪个fd就绪，需要遍历整个fd_set
- fd_set监听的fd数量不能超过1024



#### 2. poll

**poll**模式对select模式做了简单改进，但性能提升不明显，部分关键代码如下：

```c
// pollfd 中的事件类型
#define POLLIN     //可读事件
#define POLLOUT    //可写事件
#define POLLERR    //错误事件
#define POLLNVAL   //fd未打开

// pollfd结构
struct pollfd {
    int fd;     	  /* 要监听的fd  */
    short int events; /* 要监听的事件类型：读、写、异常 */
    short int revents;/* 实际发生的事件类型 */
};

// poll函数
int poll(
    struct pollfd *fds, // pollfd数组，可以自定义大小
    nfds_t nfds, // 数组元素个数
    int timeout // 超时时间
);
```

IO流程：

① 创建pollfd数组，向其中添加关注的fd信息，数组大小自定义

② 调用poll函数，将pollfd数组拷贝到内核空间，转链表存储，无上限

③ 内核遍历fd，判断是否就绪

④ 数据就绪或超时后，拷贝pollfd数组到用户空间，返回就绪fd数量n

⑤ 用户进程判断n是否大于0

⑥ 大于0则遍历pollfd数组，找到就绪的fd

与select对比：

- select模式中的fd_set大小固定为1024，而pollfd在内核中采用链表，理论上无上限

- 监听FD越多，每次遍历消耗时间也越久，性能反而会下降



#### 3. epoll

![1ni2r-m7tar](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031449235.gif)

epoll模式是对select和poll的改进，它提供了三个函数：

```c
struct eventpoll {
    //...
    struct rb_root  rbr; // 一颗红黑树，记录要监听的FD
    struct list_head rdlist;// 一个链表，记录就绪的FD
    //...
};

// 1.创建一个epoll实例,内部是event poll，返回对应的句柄epfd
int epoll_create(int size);
```

```c
// 2.将一个FD添加到epoll的红黑树中，并设置ep_poll_callback
// callback触发时，就把对应的FD加入到rdlist这个就绪列表中
int epoll_ctl(
    int epfd,  // epoll实例的句柄
    int op,    // 要执行的操作，包括：ADD、MOD、DEL
    int fd,    // 要监听的FD
    struct epoll_event *event // 要监听的事件类型：读、写、异常等
);
```

```c
// 3.检查rdlist列表是否为空，不为空则返回就绪的FD的数量
int epoll_wait(
    int epfd,                   // epoll实例的句柄
    struct epoll_event *events, // 空event数组，用于接收就绪的FD
    int maxevents,              // events数组的最大长度
    int timeout   // 超时时间，-1用不超时；0不阻塞；大于0为阻塞时间
);
```



#### 4. 事件通知机制

当FD有数据可读时，我们调用epoll_wait（或者select、poll）可以得到通知。但是事件通知的模式有两种：

- `LevelTriggered`：简称LT，也叫做水平触发。只要某个FD中有数据可读，每次调用epoll_wait都会得到通知。
- `EdgeTriggered`：简称ET，也叫做边沿触发。只有在某个FD有状态变化时，调用epoll_wait才会被通知。

举个栗子：

① 假设一个客户端socket对应的FD已经注册到了epoll实例中

② 客户端socket发送了2kb的数据

③ 服务端调用epoll_wait，得到通知说FD就绪

④ 服务端从FD读取了1kb数据

⑤ 回到步骤3（再次调用epoll_wait，形成循环）

结果：

- 如果我们采用LT模式，因为FD中仍有1kb数据，则第⑤步依然会返回结果，并且得到通知
- 如果我们采用ET模式，因为第③步已经消费了FD可读事件，第⑤步FD状态没有变化，因此epoll_wait不会返回，数据无法读取，客户端响应超时。

> 结论：
>
> - LT：事件通知频率较高，会有重复通知，影响性能
> - ET：仅通知一次，效率高。可以基于非阻塞IO循环读取解决数据读取不完整问题
>
> select和poll仅支持LT模式，epoll可以自由选择LT和ET两种模式



#### 5. web服务流程

基于epoll模式的web服务的基本流程如图：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031449236.png)



#### 6. 总结

select模式存在的三个问题：

- 能监听的FD最大不超过1024
- 每次select都需要把所有要监听的FD都拷贝到内核空间
- 每次都要遍历所有FD来判断就绪状态

poll模式的问题：

- poll利用链表解决了select中监听FD上限的问题，但依然要遍历所有FD，如果监听较多，性能会下降

epoll模式中如何解决这些问题的？

- 基于epoll实例中的红黑树保存要监听的FD，理论上无上限，而且增删改查效率都非常高
- 每个FD只需要执行一次epoll_ctl添加到红黑树，以后每次epol_wait无需传递任何参数，无需重复拷贝FD到内核空间
- 利用ep_poll_callback机制来监听FD状态，无需遍历所有FD，因此性能不会随监听的FD数量增多而下降



### 5. 信号驱动IO

**信号驱动IO**是与内核建立SIGIO的信号关联并设置回调，当内核有FD就绪时，会发出SIGIO信号通知用户，期间用户应用可以执行其它业务，无需阻塞等待。

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031449237.png)

阶段一：

① 用户进程调用sigaction，注册信号处理函数

② 内核返回成功，开始监听FD

③ 用户进程不阻塞等待，可以执行其它业务

④ 当内核数据就绪后，回调用户进程的SIGIO处理函数

阶段二：

① 收到SIGIO回调信号

② 调用recvfrom，读取

③ 内核将数据拷贝到用户空间

④ 用户进程处理数据

当有大量IO操作时，信号较多，SIGIO处理函数不能及时处理可能导致信号队列溢出，而且内核空间与用户空间的频繁信号交互性能也较低。



### 6. 异步IO

**异步IO**的整个过程都是非阻塞的，用户进程调用完异步API后就可以去做其它事情，内核等待数据就绪并拷贝到用户空间后才会递交信号，通知用户进程。

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031449238.png)

阶段一：

① 用户进程调用aio_read，创建信号回调函数

② 内核等待数据就绪

③ 用户进程无需阻塞，可以做任何事情

阶段二：

① 内核数据就绪

② 内核数据拷贝到用户缓冲区

③ 拷贝完成，内核递交信号触发aio_read中的回调函数

④ 用户进程处理数据

可以看到，异步IO模型中，用户进程在两个阶段都是非阻塞状态。

**同步和异步**

IO操作是同步还是异步，关键看数据在内核空间与用户空间的拷贝过程（数据读写的IO操作），也就是阶段二是同步还是异步：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031449239.png)



### 7. Redis网络模型

#### 1. 面试题

**Redis到底是单线程还是多线程？**

- 如果仅仅聊Redis的核心业务部分（命令处理），答案是单线程
- 如果是聊整个Redis，那么答案就是多线程

在Redis版本迭代过程中，在两个重要的时间节点上引入了多线程的支持：

- Redis v4.0：引入多线程异步处理一些耗时较旧的任务，例如异步删除命令unlink
- Redis v6.0：在核心网络模型中引入 多线程，进一步提高对于多核CPU的利用率

因此，对于Redis的核心网络模型，在Redis 6.0之前确实都是单线程。是利用epoll（Linux系统）这样的IO多路复用技术在事件循环中不断处理客户端情况。

**为什么Redis要选择单线程？**

- 抛开持久化不谈，Redis是纯内存操作，执行速度非常快，它的性能瓶颈是网络延迟而不是执行速度，因此多线程并不会带来巨大的性能提升。
- 多线程会导致过多的上下文切换，带来不必要的开销
- 引入多线程会面临线程安全问题，必然要引入线程锁这样的安全手段，实现复杂度增高，而且性能也会大打折扣



#### 2. 网络模型

##### 1. API库

Redis通过IO多路复用来提高网络性能，并且支持各种不同的多路复用实现，并且将这些实现进行封装， 提供了统一的高性能事件库API库 AE：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031449240.png)

```c
/* ae.c */
#ifdef HAVE_EVPORT
#include "ae_evport.c"
#else
    #ifdef HAVE_EPOLL
    #include "ae_epoll.c"
    #else
        #ifdef HAVE_KQUEUE
        #include "ae_kqueue.c"
        #else
        #include "ae_select.c"
        #endif
    #endif
#endif
```

来看下Redis单线程网络模型的整个流程：

```c
int main(int argc, char **argv) {
    // ...
    // 初始化服务
    initServer();
    // ...
    // 开始监听事件循环
    aeMain(server.el);
    // ...
}
```

```c
void initServer(void) {
    // ...
    // 内部会调用 aeApiCreate(eventLoop)，类似epoll_create
    server.el = aeCreateEventLoop(server.maxclients+CONFIG_FDSET_INCR);
    // ...
    // 监听TCP端口，创建ServerSocket，并得到FD
    listenToPort(server.port,&server.ipfd)
    // ...
    // 注册 连接处理器，内部会调用 aeApiCreate(&server.ipfd)监听FD
    createSocketAcceptHandler(&server.ipfd, acceptTcpHandler)
    // 注册 ae_api_poll 前的处理器
    aeSetBeforeSleepProc(server.el,beforeSleep);
}

// 数据读处理器
void acceptTcpHandler(...) {
    // ...
    // 接收socket连接，获取FD
    fd = accept(s,sa,len);
    // ...
    // 创建connection，关联fd
    connection *conn = connCreateSocket();
    conn.fd = fd;
    // ... 
    // 内部调用aeApiAddEvent(fd,READABLE)，
    // 监听socket的FD读事件，并绑定读处理器readQueryFromClient
    connSetReadHandler(conn, readQueryFromClient);
}
```

```c
void aeMain(aeEventLoop *eventLoop) {
    eventLoop->stop = 0;
    // 循环监听事件
    while (!eventLoop->stop) {
        aeProcessEvents(
            eventLoop, 
            AE_ALL_EVENTS|
            AE_CALL_BEFORE_SLEEP|
            AE_CALL_AFTER_SLEEP);
    }
}
```

```c
int aeProcessEvents(
    aeEventLoop *eventLoop,
    int flags ){
    // ...  调用前置处理器 beforeSleep
    eventLoop->beforesleep(eventLoop);
    // 等待FD就绪，类似epoll_wait
    numevents = aeApiPoll(eventLoop, tvp);
    for (j = 0; j < numevents; j++) {
        // 遍历处理就绪的FD，调用对应的处理器
    }
}
```



##### 2.  执行流程

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031449241.png)

来看下Redis单线程网络模型的整个流程：

Redis 6.0版本中引入了多线程，目的是为了提高IO读写效率。因此在**解析客户端命令**、**写响应结果**时采用了多线程。核心的命令执行、IO多路复用模块依然是由主线程执行。

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031449242.gif)

```c
void beforeSleep(struct aeEventLoop *eventLoop){
    // ...
    // 定义迭代器，指向server.clients_pending_write->head;
    listIter li;
    li->next = server.clients_pending_write->head;
    li->direction = AL_START_HEAD;
    // 循环遍历待写出的client
    while ((ln = listNext(&li))) {
        // 内部调用aeApiAddEvent(fd，WRITEABLE)，监听socket的FD读事件
        // 并且绑定 写处理器 sendReplyToClient，可以把响应写到客户端socket
        connSetWriteHandlerWithBarrier(c->conn, sendReplyToClient, ae_barrier)
    }
}
```

```c
void readQueryFromClient(connection *conn) {
    // 获取当前客户端，客户端中有缓冲区用来读和写
    client *c = connGetPrivateData(conn);
    // 获取c->querybuf缓冲区大小
    long int qblen = sdslen(c->querybuf);
    // 读取请求数据到 c->querybuf 缓冲区
    connRead(c->conn, c->querybuf+qblen, readlen);
    // ... 
    // 解析缓冲区字符串，转为Redis命令参数存入 c->argv 数组
    processInputBuffer(c);
    // ...
    // 处理 c->argv 中的命令
    processCommand(c);
}

int processCommand(client *c) {
    // ...
    // 根据命令名称，寻找命令对应的command，例如 setCommand
    c->cmd = c->lastcmd = lookupCommand(c->argv[0]->ptr);
    // ...
    // 执行command，得到响应结果，例如ping命令，对应pingCommand
    c->cmd->proc(c);
    // 把执行结果写出，例如ping命令，就返回"pong"给client，
    // shared.pong是 字符串"pong"的SDS对象
    addReply(c,shared.pong); 
}

void addReply(client *c, robj *obj) {
    // 尝试把结果写到 c-buf 客户端写缓存区
    if (_addReplyToBuffer(c,obj->ptr,sdslen(obj->ptr)) != C_OK)
        // 如果c->buf写不下，则写到 c->reply，这是一个链表，容量无上限
        _addReplyProtoToList(c,obj->ptr,sdslen(obj->ptr));
    // 将客户端添加到server.clients_pending_write这个队列，等待被写出
    listAddNodeHead(server.clients_pending_write,c);
}
```





## 3. 通信协议

### 1. RESP协议

Redis是一个CS架构的软件，通信一般分两步（不包括pipeline和PubSub）：

① 客户端（client）向服务端（server）发送一条命令

② 服务端解析并执行命令，返回响应结果给客户端

因此客户端发送命令的格式、服务端响应结果的格式必须有一个规范，这个规范就是通信协议。

而在Redis中采用的是**RESP**（Redis Serialization Protocol）协议：

- Redis 1.2版本引入了RESP协议
- Redis 2.0版本中成为与Redis服务端通信的标准，称为RESP2
- Redis 6.0版本中，从RESP2升级到了RESP3协议，增加了更多数据类型并且支持6.0的新特性--客户端缓存

但目前，默认使用的依然是RESP2协议，也是我们要学习的协议版本（以下简称RESP）。

**RESP协议-数据类型**

在RESP中，通过首字节的字符来区分不同数据类型，常用的数据类型包括5种：

- 单行字符串：首字节是 ‘**+**’ ，后面跟上单行字符串，以CRLF（ "**\r\n**" ）结尾。例如返回"OK"： "+OK\r\n"

- 错误（Errors）：首字节是 ‘**-**’ ，与单行字符串格式一样，只是字符串是异常信息，例如："-Error message\r\n"

- 数值：首字节是 ‘**:**’ ，后面跟上数字格式的字符串，以CRLF结尾。例如：":10\r\n"

- 多行字符串：首字节是 ‘**$**’ ，表示二进制安全的字符串，最大支持512MB：

  ![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031449243.png)

  - 如果大小为0，则代表空字符串："$0\r\n\r\n"
  - 如果大小为-1，则代表不存在："$-1\r\n"

- 数组：首字节是 ‘*****’，后面跟上数组元素个数，再跟上元素，元素数据类型不限:

  ![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031449244.png)



### 2. 模拟Redis客户端

#### 1. 建立连接

Redis支持TCP通信，因此我们可以使用Socket来模拟客户端，与Redis服务端建立连接：

```java
public class RedisDemo {
    static Socket s;
    static PrintWriter writer;
    static BufferedReader reader;

    public static void main(String[] args) throws IOException {
        // 1.定义连接参数
        String host = "192.168.150.101";
        int port = 6379;
        // 2.连接 Redis
        s = new Socket(host, port);
        // 2.1.获取输入流
        reader = new BufferedReader(new InputStreamReader(s.getInputStream(), StandardCharsets.UTF_8));
        // 2.2.获取输出流
        writer = new PrintWriter(s.getOutputStream());
        // TODO 3.发送请求
        sendRequest();
        // TODO 4.接收响应
        Object obj = handleResponse();
        System.out.println(obj);
        // 5.关闭连接
        if (reader != null) reader.close();
        if (writer != null) writer.close();
        if (s != null) s.close();
    }
    private static Object handleResponse() {}
    private static void sendRequest() {}
}
```



#### 2. 发送请求

这里我们以set命令为例，发送请求就是输出下面内容：

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031449245.png)

```java
private static void sendRequest(String ... args) {
    // 元素个数
    writer.println("*" + args.length);
    // 参数
    for (String arg : args) {
        writer.println("$" +arg.getBytes(StandardCharsets.UTF_8).length);
        writer.println(arg);
    }
    // 刷新
    writer.flush();
}
```



#### 3. 解析结果

响应的结果可能是之前讲的5种数据类型中的任意一种，需要判断后读取：

```java
private static Object handleResponse() {
    try {
        // 当前前缀
        char prefix = (char) reader.read();
        switch (prefix) {
            case '+': // 单行字符串，直接返回
                return reader.readLine();
            case '-': // 异常，直接抛出
                throw new RuntimeException(reader.readLine());
            case ':': // 数值，转为 int 返回
                return Integer.valueOf(reader.readLine());
            case '$': // 多行字符串，先读长度
                int length = Integer.parseInt(reader.readLine());
                // 如果为空，直接返回
                if(length == 0 || length == -1) return ""; 
                // 不为空，则读取下一行
                return reader.readLine();
            case '*': // 数组，遍历读取
                return readBulkString();
            default:
                return null;
        }
    } catch (IOException e) {
        throw new RuntimeException(e);
    }
}
```

```java
private static List<Object> readBulkString() 
                               throws IOException {
    // 当前数组大小
    int size = Integer.parseInt(reader.readLine());
    // 数组为空，直接返回 null
    if(size == 0 || size == -1){
        return null;
    }
    List<Object> rs = new ArrayList<>(size);
    for (int i = size; i > 0; i--) {
        try { // 递归读取
            rs.add(handleResponse());
        } catch (Exception e) {
            rs.add(e);
        }
    }
    return rs;
}
```



#### 4. 测试

最终，我们测试发送请求和接收响应：

```java
// 3.发送授权请求 auth 123321
sendRequest("auth", "123321");
// 4.接收响应
Object obj = handleResponse();
System.out.println("auth = " + obj);

// 3.发送set请求
sendRequest("set", "name", "虎哥");
// 4.接收响应
obj = handleResponse();
System.out.println("set = " + obj);

// 3.发送 mget请求
sendRequest("mget", "name", "msg");
// 4.接收响应
obj = handleResponse();
System.out.println("mget = " + obj);
```





## 4. 内存策略

### 1. Redis内存回收

Redis之所以性能强，最主要的原因就是基于内存存储。然而单节点的Redis其内存大小不宜过大，会影响持久化或主从同步性能。

我们可以通过修改配置文件来设置Redis的最大内存：

```bash
# 格式：
# maxmemory <bytes>
# 例如：
maxmemory 1gb
```

当内存使用达到上限时，就无法存储更多数据了。为了解决这个问题，Redis提供了一些策略实现内存回收：

- 内存过期策略
- 内存淘汰策略



### 2. 过期策略

在学习Redis缓存的时候我们说过，可以通过expire命令给Redis的key设置TTL（存活时间）：

可以发现，当key的TTL到期以后，再次访问name返回的是nil，说明这个key已经不存在了，对应的内存也得到释放。从而起到内存回收的目的。



#### 1. DB结构

Redis本身是一个典型的key-value内存存储数据库，因此所有的key、value都保存在之前学习过的Dict结构中。不过在其database结构体中，有两个Dict：一个用来记录key-value；另一个用来记录key-TTL。

```c
typedef struct redisDb {
    dict *dict;                 /* 存放所有key及value的地方，也被称为keyspace*/
    dict *expires;              /* 存放每一个key及其对应的TTL存活时间，只包含设置了TTL的key*/
    dict *blocking_keys;        /* Keys with clients waiting for data (BLPOP)*/
    dict *ready_keys;           /* Blocked keys that received a PUSH */
    dict *watched_keys;         /* WATCHED keys for MULTI/EXEC CAS */
    int id;                     /* Database ID，0~15 */
    long long avg_ttl;          /* 记录平均TTL时长 */
    unsigned long expires_cursor; /* expire检查时在dict中抽样的索引位置. */
    list *defrag_later;         /* 等待碎片整理的key列表. */
} redisDb;

```

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031449246.png)

这里有两个问题需要我们思考：

① Redis是如何知道一个key是否过期呢？

- 利用两个Dict分别记录key-value对及key-ttl对

② 是不是TTL到期就立即删除了呢？

- 惰性删除
- 周期删除



#### 2. 惰性删除

**惰性删除：**顾明思议并不是在TTL到期后就立刻删除，而是在访问一个key的时候，检查该key的存活时间，如果已经过期才执行删除。

```c
// 查找一个key执行写操作
robj *lookupKeyWriteWithFlags(redisDb *db, robj *key, int flags) {
    // 检查key是否过期
    expireIfNeeded(db,key);
    return lookupKey(db,key,flags);
}

// 查找一个key执行读操作
robj *lookupKeyReadWithFlags(redisDb *db, robj *key, int flags) {
    robj *val;
    // 检查key是否过期
    if (expireIfNeeded(db,key) == 1) {
        // ...略
    }
    return NULL;
}
```

```c
int expireIfNeeded(redisDb *db, robj *key) {
    // 判断是否过期，如果未过期直接结束并返回0
    if (!keyIsExpired(db,key)) return 0;
    // ... 略
    // 删除过期key
    deleteExpiredKeyAndPropagate(db,key);
    return 1;
}
```



#### 3. 周期删除

**周期删除：**顾明思议是通过一个定时任务，周期性的抽样**部分过期的key**，然后执行删除。执行周期有两种：

- Redis服务初始化函数initServer()中设置定时任务serverCron()，按照server.hz的频率来执行过期key清理，模式为SLOW

```c
// server.c
void initServer(void){
    // ...
    // 创建定时器，关联回调函数serverCron，处理周期取决于server.hz，默认10
    aeCreateTimeEvent(server.el, 1, serverCron, NULL, NULL) 
}
```

```c
// server.c
int serverCron(struct aeEventLoop *eventLoop, long long id, void *clientData) {
    // 更新lruclock到当前时间，为后期的LRU和LFU做准备
    unsigned int lruclock = getLRUClock();
    atomicSet(server.lruclock,lruclock);
    // 执行database的数据清理，例如过期key处理
    databasesCron();
}
```

```c
void databasesCron(void) {
    // 尝试清理部分过期key，清理模式默认为SLOW
    activeExpireCycle(ACTIVE_EXPIRE_CYCLE_SLOW);
}
```

- Redis的每个事件循环前会调用beforeSleep()函数，执行过期key清理，模式为FAST

```c
void beforeSleep(struct aeEventLoop *eventLoop){
    // ...
    // 尝试清理部分过期key，清理模式默认为FAST
    activeExpireCycle(ACTIVE_EXPIRE_CYCLE_FAST);
}
```

```c
void aeMain(aeEventLoop *enentLoop) {
    eventLoop->stop = 0;
    while(!eventLoop->stop) {
        // beforeSleep() --> Fast模式清理
        // n = aeApiPoll()
        // 如果 n > 0,FD就绪,处理IO事件
        // 如果到了执行时间,则会调用serverCron() --> SLOW模式清理
    }
}
```

**SLOW模式规则**：

① 执行频率受server.hz影响，默认为10，即每秒执行10次，每个执行周期100ms。

② 执行清理耗时不超过一次执行周期的25%，默认slow模式耗时不超过25ms

③ 逐个遍历db，逐个遍历db中的bucket，抽取20个key判断是否过期

④ 如果没达到时间上限（25ms）并且过期key比例大于10%，再进行一次抽样，否则结束

**FAST模式规则**（过期key比例小于10%不执行 ）：

① 执行频率受beforeSleep()调用频率影响，但两次FAST模式间隔不低于2ms

② 执行清理耗时不超过1ms

③ 逐个遍历db，逐个遍历db中的bucket，抽取20个key判断是否过期

④ 如果没达到时间上限（1ms）并且过期key比例大于10%，再进行一次抽样，否则结束



#### 4. 总结

RedisKey的TTL记录方式：

- 在RedisDB中通过一个Dict记录每个Key的TTL时间

过期key的删除策略：

- 惰性清理：每次查找key时判断是否过期，如果过期则删除
- 定期清理：定期抽样部分key，判断是否过期，如果过期则删除。

定期清理的两种模式：

- SLOW模式执行频率默认为10，每次不超过25ms
- FAST模式执行频率不固定，但两次间隔不低于2ms，每次耗时不超过1ms



### 3. 淘汰策略

**内存淘汰**：就是当Redis内存使用达到设置的上限时，主动挑选部分key删除以释放更多内存的流程。

Redis会在处理客户端命令的方法processCommand()中尝试做内存淘汰：

```c
int processCommand(client *c) {
    // 如果服务器设置了server.maxmemory属性，并且并未有执行lua脚本
    if (server.maxmemory && !server.lua_timedout) {
        // 尝试进行内存淘汰performEvictions
        int out_of_memory = (performEvictions() == EVICT_FAIL);
        // ...
        if (out_of_memory && reject_cmd_on_oom) {
            rejectCommand(c, shared.oomerr);
            return C_OK;
        }
        // ....
    }
}
```

Redis支持8种不同策略来选择要删除的key：

- `noeviction`： 不淘汰任何key，但是内存满时不允许写入新数据，默认就是这种策略。
- `volatile-ttl`： 对设置了TTL的key，比较key的剩余TTL值，TTL越小越先被淘汰
- `allkeys-random`：对全体key ，随机进行淘汰。也就是直接从db->dict中随机挑选
- `volatile-random`：对设置了TTL的key ，随机进行淘汰。也就是从db->expires中随机挑选。
- `allkeys-lru`： 对全体key，基于LRU算法进行淘汰
- `volatile-lru`： 对设置了TTL的key，基于LRU算法进行淘汰
- `allkeys-lfu`： 对全体key，基于LFU算法进行淘汰
- `volatile-lfu`： 对设置了TTL的key，基于LFI算法进行淘汰

比较容易混淆的有两个：

- **LRU**（Least Recently Used），最少最近使用。用当前时间减去最后一次访问时间，这个值越大则淘汰优先级越高。

- **LFU**（Least Frequently Used），最少频率使用。会统计每个key的访问频率，值越小淘汰优先级越高。

Redis的数据都会被封装为RedisObject结构：

```c
typedef struct redisObject {
    unsigned type:4;        // 对象类型
    unsigned encoding:4;    // 编码方式
    unsigned lru:LRU_BITS;  // LRU：以秒为单位记录最近一次访问时间，长度24bit
    // LFU：高16位以分钟为单位记录最近一次访问时间，低8位记录逻辑访问次数
    int refcount;           // 引用计数，计数为0则可以回收
    void *ptr;              // 数据指针，指向真实数据
} robj;
```

LFU的访问次数之所以叫做**逻辑访问次数**，是因为并不是每次key被访问都计数，而是通过运算：

① 生成0~1之间的随机数R

② 计算 (旧次数 * lfu_log_factor + 1)，记录为P

③ 如果 R < P ，则计数器 + 1，且最大不超过255

④ 访问次数会随时间衰减，距离上一次访问时间每隔 `lfu_decay_time` 分钟，计数器 -1

![](https://gitlab.com/eardh/picture/-/raw/main/redis_img/202207031449247.png)

