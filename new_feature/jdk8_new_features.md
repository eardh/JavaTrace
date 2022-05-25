# JDK8 新特性

**jdk8 新特性简介**

- 速度更快
- 代码更少（增加了新的语法 Lambda 表达式）
- 强大的 Stream API
- 便于并行 最大化减少空指针异常 Optional
- jvm 的一些调整

![](https://gitlab.com/eardh/picture/-/raw/main/new_feature_img/202111042212995.jpg)



## 1. Lambda 表达式

### 1. 概念

Lambda 是一个匿名函数，我们可以把 Lambda 表达式理解为是一段可以传递的代码（将代码像数据一样进行传递）。可以写出更简洁、更灵活的代码。作为一种更紧凑的代码风格，使 Java的语言表达能力得到了提升。

**口诀：**

上联：左右遇一括号省

下联：左侧推断类型省

横批：能省则省



### 2. Lambda 表达式语法

Lambda 表达式在Java 语言中引入了一个新的语法元素和操作符。这个操作符为 **“->”** ， 该操作符被称为 Lambda 操作符或剪头操作符。它将 Lambda 分为 两个部分： 

**左侧：**指定了 Lambda 表达式需要的所有参数 

**右侧：**指定了 Lambda 体，即 Lambda 表达式要执行 的功能。



**1、语法格式一：无参，无返回值，Lambda 体只需一条语句**

```java
Runnable r = () -> System.out.println("Lambda");
```



**2、语法格式二：Lambda 需要一个参数**

```java
Consumer<String> consumer = (x) -> System.out.println(x);
```



**3、语法格式三：Lambda 只需要一个参数时，参数的小括号可以省略**

```java
Consumer<String> consumer = x -> System.out.println(x);
```



**4、语法格式四：Lambda 需要两个以上参数，并且有返回值**

```java
Comparator<Integer> comparator = (x, y) -> {
    System.out.println("Lambda");
    return Integer.compare(x, y);
};
```



**5、语法格式五：当 Lambda 体只有一条语句时，return 与 大括号 可以省略**

```java
Comparator<Integer> comparator = (x, y) -> Integer.compare(x, y);
```



**6、Lambda 表达式的参数列表中的数据类型可以省略不写，因为编译器可以通过上下文推断出数据类型**。

```java
// 下面代码效果相同
Comparator<Integer> comparator = (x, y) -> Integer.compare(x, y);
Comparator<Integer> comparator = (Integer x, Integer y) -> Integer.compare(x, y);
```



### 3. 类型推断

上述 Lambda 表达式中的参数类型都是由编译器推断得出的。Lambda 表达式中无需指定类型，程序依然可以编译，这是因为 javac 根据程序的上下文，在后台推断出了参数的类型。Lambda 表达式的类型依赖上下文环境，是由编译器推断出来的。这就是所谓的 “类型推断”。



## 2. 函数式接口

### 1. 什么是函数式接口

- 只包含一个抽象方法的接口，称为 **函数式接口**。
- 你可以通过 Lambda 表达式来创建该接口的对象。（若 Lambda  表达式抛出一个受检异常，那么该异常需要在目标接口的抽象方法上进行声明）。
- 我们可以在任意函数式接口上使用 **==@FunctionalInterface==** 注解， 这样做可以检查它是否是一个函数式接口，同时 javadoc 也会包含一条声明，说明这个接口是一个函数式接口。



### 2. 自定义函数式接口

在接口的上面加上**@FunctionalInterface** 实现自定义函数接口， 从概念上讲，函数式接口只有一个抽象方法。 由于默认方法具有实现，因此它们不是抽象的。

作为参数传递 Lambda 表达式：为了将 Lambda 表达式作为参数传递，接 收Lambda 表达式的参数类型必须是与该 Lambda 表达式兼容的函数式接口 的类型。

```java
@FunctionalInterface
public interface FunctionInterface<T> {
    T get(T t);
    
    default void value() {
        // do somethings
    }
}
```

自定义函数式接口使用：

```java
public class Test {
    public static void main(String[] args) {
        List<Integer> list = Arrays.asList(1,2,3,4,5,6,7,8,9);
        list = filter(list, ls -> {
            List<Integer> tp = new ArrayList<>();
            for (Integer l : ls) {
                if (l < 3 || l > 6) {
                    tp.add(l);
                }
            }
            return tp;
        });
        System.out.println(list);
    }

    public static List<Integer> filter(List<Integer> list, FunctionInterface<List<Integer>> func) {
        return func.get(list);
    }
}
```

```bash'
// 结果：
[1, 2, 7, 8, 9]
```



### 4. 内置四大核心函数式接口

| **函数式接口**                       | **参数类型** | **返回类型** |                           **用途**                           |
| :----------------------------------- | :----------: | :----------: | :----------------------------------------------------------: |
| **Consumer<T>**        消费型接口    |      T       |     void     | 对类型为 T 的对象应用操 作，包含方法：**void accept(T t);**  |
| **Supplier<T>**           供给型接口 |      无      |      T       |         返回类型为 T 的对象，包含方法：**T get();**          |
| **Function<T, R>**      函数型接口   |      T       |      R       | 对类型为 T 的对象应用操作，并返回结果。结果 是R类型的对象。包含方法：**R apply(T t);** |
| **Predicate<T>**         断定型接口  |      T       |   boolean    | 确定类型为 T 的对象是否满足某约束，并返回 boolean 值。包含方法：**boolean test(T t);** |

**1、Consumer<T>**

 ```java
 public class Test {
     public static void main(String[] args) {
         Consumer<String> consumer = s -> System.out.println(s);
         consumer.accept("huang");
     }
 }
 ```



**2 、Supplier<T>**

```java
public class Test {
    public static void main(String[] args) {
        Supplier<Long> supplier = () -> System.currentTimeMillis();
        Long timestamp = supplier.get();
        System.out.println(timestamp);
    }
}
```



**3、Function<T, R>**

```java
public class Test {
    public static void main(String[] args) {
        Function<String, Integer> function = s -> Integer.valueOf(s);
        Integer apply = function.apply("9527");
        System.out.println(apply);
    }
}
```



**4、Predicate<T>** 

```java
public class Test {
    public static void main(String[] args) {
        Predicate<Object> predicate = object -> object instanceof Test;
        boolean test = predicate.test(new Test());
        System.out.println(test);
    }
}
```



### 5. 其他函数时接口

| 函数式接口                                                   |     参数类型      |     返回类型      |                             用途                             |
| ------------------------------------------------------------ | :---------------: | :---------------: | :----------------------------------------------------------: |
| **BiFunction<T, U, R>**                                      |       T，U        |         R         | 对类型为 T, U 参数应用 操作， 返回 R 类型的 结 果。包含方法为 **R apply(T t, U u);** |
| **UnaryOperator<T>**            (Function子 接口)            |         T         |         T         | 对类型为 T 的对象进行一 元运算，并返回 T 类型的 结果。包含方法为 **T apply(T t);** |
| **BinaryOperator<T>**        (BiFunction 子接口)             |       T，T        |         T         | 对类型为T的对象进行二元运算，并返回 T 类型的结果。包含方法为 **T apply(T t1, T t2);** |
| **BiConsumer<T, U>**                                         |       T，U        |       void        | 对类型为 T, U 参数应用 操作。包含方法为 **void accept(T t, U u);** |
| **ToIntFunction<T>  ToLongFunction<T>  ToDoubleFunction<T>** |         T         | int，long，double |           分别计算 int 、 long 、 double 值的函数            |
| **IntFunction<R>  LongFunction<R>  DoubleFunction<R>**       | int，long，double |         T         |           参数分别为 int、long、 double 类型的函数           |



## 3. 方法引用与构造器引用

### 1. 方法引用

当要传递给 Lambda 体的操作，已经有实现的方法了，可以使用方法引用！（实现抽象方法的参数列表，必须与方法引用方法的参数列表保持一致！） 

方法引用：使用操作符 **“::”** 将方法名和对象或类的名字分隔开来。 

如下三种主要使用情况：

- ==**对象::实例方法**==
- ==**类::静态方法**==
- ==**类::实例方法**==

```java
/*
 * 方法引用
 */
public class Test {
    public static void main(String[] args) {

        /*
         * 类::实例方法
         */
        Consumer<String> consumer1 = s -> System.out.println(s);
        Consumer<String> consumer2 = System.out::println;

        /*
         * 类::静态方法
         */
        Supplier<Long> supplier1 = () -> System.currentTimeMillis();
        Supplier<Long> supplier2 = System::currentTimeMillis;

        /*
         * 对象::实例方法
         */
        Random random = new Random();
        Function<Integer, Integer> function1 = bound -> random.nextInt(bound);
        Function<Integer, Integer> function2 = random::nextInt;
    }
}
```



### 2. 构造器引用

与函数式接口相结合，自动与函数式接口中方法兼容。 可以把构造器引用赋值给定义的方法，与构造器参数列表要与接口中抽象方法的参数列表一致！

**格式：==ClassName::new==**

**数组引用：==type[] :: new==**

```java
/*
 * 构造器引用
 */
public class Test {
    public static void main(String[] args) {
        Function<String, String> function1 = s -> new String(s);
        Function<String, String> function2 = String::new;

        Function<Integer, String[]> function3 = size -> new String[size];
        Function<Integer, String[]> function4 = String[]::new;
    }
}
```



## 4. Stream API

### 1.  了解 Stream

Stream流是 Java8 API 新增的一个处理集合的关键抽象概念，是一个来自数据源的元素队列并支持聚合操作。以指定你希望对集合进行的操作，可以执行非常复杂的查找、过滤和映射数据等操作。使用Stream API 对集合数据进行操作，就类似于使用 SQL 执行的数据库查询。也可以使用 Stream API 来并行执行操作。简而言之，Stream API 提供了一种高效且易于使用的处理数据的方式。

| 相关名词       | 描述                                                         |
| -------------- | ------------------------------------------------------------ |
| **元素**       | 对象形成的一个队列。 **Java中的Stream并不会存储元素，而是按需计算**。 |
| **数据源**     | 流Stream的来源。 可以是集合、数组、I/O channel、 产生器generator 等 |
| **聚合操作**   | 类似SQL语句一样的操作，比如filter, map, reduce, find, match, sorted等。 |
| **内部迭代**   | 中间操作都会返回流对象本身。 这样多个操作可以串联成一个管道， 如同**流式风格**（fluent style）。 这样做可以对操作进行优化， 比如延迟执行(laziness)和短路( short-circuiting)。 |
| **Pipelining** | 以前对集合遍历都是通过Iterator或者For-Each的方式, 显式的在集合外部进行迭代， 这叫做外部迭代。 Stream提供了内部迭代的方式， 通过**访问者模式(Visitor)实现**。 |



### 2. 什么是 Stream

**1. 流(Stream) 到底是什么呢？** 

流是数据渠道，用于操作数据源（集合、数组等）所生成的元素序列。 “ 集合讲的是数据，流讲的是计算！”



**2. Stream的特点**

- Stream不是什么数据结构，它不会保存数据，只是将操作的数据结果保存到另一个对象中。
- Stream是惰性求值的（延迟执行），在中间处理的过程中，只对操作进行记录，并不会立即执行，只有等到执行终止操作的时候才会进行实际的计算，这时候中间操作才会执行。
- 可以把Stream当成一个高级版本的Iterator来使用。（原始版本的Iterator，只能一个个的遍历操作）



==**3. 注意**==

- Stream 自己不会存储元素。 

- Stream 不会改变源对象。相反，他们会返回一个持有结果的新Stream。

- Stream 操作是延迟执行的。这意味着他们会等到需要结果的时候才执行



### 3. Stream 操作的三个步骤 🚀

- **创建 Stream ：**一个数据源（如：集合、数组），获取一个流 

- **中间操作 ：**一个中间操作链，对数据源的数据进行处理

- **终止操作(终端操作)  ：**一个终止操作，执行中间操作链，并产生结果



#### 1. Stream 的==创建==操作

**1、Collection 接口创建流**

Java8 中的 ==**Collection** 接口==被扩展，提供了两个获取流的方法：

- **default Stream stream() :** 返回一个顺序流
- **default Stream parallelStream() :** 返回一个并行流

```java
List<Integer> list = Arrays.asList(1,2,3,4,5,6,7,8,9);
Stream<Integer> stream = list.stream();
Stream<Integer> parallelStream = list.parallelStream();
```



**2、由数组创建流**

Java8 中的 **Arrays** 的静态方法 **==stream()==** 可以获取数组流

- **static  Stream stream(T[] array) **： 返回一个流。重载形式，能够处理对应基本类型的数组：
  - **public static IntStream stream(int[] array)**
  - **public static LongStream stream(long[] array)**
  - **public static DoubleStream stream(double[] array)**

```java
int[] arr1 = new int[10];
IntStream stream1 = Arrays.stream(arr1);

long[] arr2 = new long[10];
LongStream stream2 = Arrays.stream(arr2);

double[] arr3 = new double[10];
DoubleStream stream3 = Arrays.stream(arr3);

Object[] arr4 = new Object[10];
Stream<Object> stream4 = Arrays.stream(arr4);
```



**3、由值创建流**

可以使用静态方法 ==**Stream.of()**==，通过显示值创建一个流。它可以接收任意数量的参数。

- **public static Stream of(T... values)** ： 返回一个流

```java
Stream<Integer> stream = Stream.of(1, 2, 3, 4, 5, 6, 7, 8, 9);
```



**4、由函数创建流：创建无限流**

可以使用静态方法 **==Stream.iterate()==** 和 **==Stream.generate()==**，创建无限流。

- **public static Stream iterate(final T seed, final  UnaryOperator f)**
- **public static Stream generate(Supplier s)**

```java
// 迭代 有序流
Stream<Integer> stream1 = Stream.iterate(0, x -> x + 1); // 无限流
Stream<Integer> stream2 = Stream.iterate(0, p -> p < 10, x -> x + 1); // 有限流

// 生成 无序流
Random random = new Random();
Stream<Integer> stream = Stream.generate(random::nextInt);
```



**5、 通过 Stream 构建器 Builder<T> 创建流**

- **Stream.builder()**

```java
Stream.Builder<Integer> builder = Stream.builder();
builder.accept(1); // 向正在构建的流添加一个元素
builder.accept(2);
builder.accept(3);
builder.accept(4);
Stream<Integer> build = builder.build(); // 构建流，将此构建器转换为构建状态
```



#### 2. Stream 的==中间==操作

多个**中间操作**可以连接起来形成一个**流水线**，除非流水线上触发终止操作，否则**中间操作不会执行任何的处理**！ 而在**终止操作时一次性全部处理，称为 “惰性求值”** 。

**1、筛选与切片**

| 方法                       | 描述                                                         |
| :------------------------- | ------------------------------------------------------------ |
| **filter(Predicate<T> p)** | 接收 Lambda ， 从流中排除某些元素。                          |
| **distinct()**             | 筛选，通过流所生成元素的 hashCode() 和 equals() 去除重复元素。 |
| **limit(long maxSize)**    | 截断流，使其元素不超过给定数量。                             |
| **skip(long n)**           | 跳过元素，返回一个扔掉了前 n 个元素的流。若流中元素不足 n 个，则返回一个空流。与 limit(n) 互补。 |

 ```java
 /*
  * 中间操作：筛选与切片
  */
 public class Test {
     public static void main(String[] args) {
         List<Integer> list = Arrays.asList(1,2,3,4,5,6,7,8,9,4,6);
 
         // filter 操作：value > 3 的元素保留，流中元素：{4,5,6,7,8,9,4,6}
         Stream<Integer> filter = list.stream().filter(i -> i > 3);
 
         // distinct 操作：重复元素仅保留一个，流中元素：{4,5,6,7,8,9}
         Stream<Integer> distinct = filter.distinct();
 
         // limit 操作：流中的前 3 个元素保留，流中元素：{4,5,6}
         Stream<Integer> limit = distinct.limit(3);
 
         // skip 操作：跳过流的前 1 个元素，流中元素：{5,6}
         Stream<Integer> skip = limit.skip(1);
     }
 }
 ```



**2、映射**

| **方法**                            | **描述**                                                     |
| :---------------------------------- | ------------------------------------------------------------ |
| **map(Function f)**                 | 接收一个函数作为参数，该函数会被应用到每个元素上，并将其映射成一个新的元素。 |
| **mapToDouble(ToDoubleFunction f)** | 接收一个函数作为参数，该函数会被应用到每个元素上，产生一个新的 DoubleStream。 |
| **mapToInt(ToIntFunction f)**       | 接收一个函数作为参数，该函数会被应用到每个元素上，产生一个新的 IntStream。 |
| **mapToLong(ToLongFunction f)**     | 接收一个函数作为参数，该函数会被应用到每个元素上，产生一个新的 LongStream。 |
| **flatMap(Function f)**             | 接收一个函数作为参数，将流中的每个值都换成另一个流，然后把所有流连接成一个流 |

```java
/*
 * 中间操作：映射
 */
public class Test {
    public static void main(String[] args) {
        List<Double> list = Arrays.asList(1.11,2.22,3.33,4.44,5.55,6.66,7.77,8.88,9.99);

        // {...}
        Stream<Double> map = list.stream().map(i -> i * i);

        // {1,2,3,4,5,6,7,8,9}
        IntStream mapToInt = list.stream().mapToInt(Double::intValue);

        // {2.11,3.22,4.33,5.44,6.55,7.66,8.77,9.88,10.99}
        DoubleStream mapToDouble = list.stream().mapToDouble(i -> i + 1);

        // {1,2,3,4,6,7,8,9,10}
        LongStream mapToLong = list.stream().mapToLong(Math::round);

        // {1,11,2,22,3,33,4,44,5,55,6,66,7,77,8,88,9,99}
        Stream<String> flatmap = list.stream().flatMap(i -> Arrays.stream(i.toString().split("\\.")));
    }
}
```



**3、排序**

| 方法                        | 描述                               |
| --------------------------- | ---------------------------------- |
| **sorted(Comparator comp)** | 产生一个新流，其中按比较器顺序排序 |
| **sorted()**                | 产生一个新流，其中按自然顺序排序   |

```java
/*
 * 中间操作：排序
 */
public class Test {
    public static void main(String[] args) {
        List<Integer> list = Arrays.asList(23,345,1,56,78,231,-2,7,123);

        // -2, 1, 7, 23, 56, 78, 123, 231, 345
        Stream<Integer> sorted = list.stream().sorted();

        // 345, 231, 123, 78, 56, 23, 7, 1, -2,
        list.stream().sorted((x, y) -> -(x - y)).forEach(System.out::println);
    }
}
```



#### 3. Stream 的==终止==操作

终端操作会从流的 **流水线生成结果**。其结果可以是任何不是流的值，例如：List、Integer，甚至是 void 。

 **1、查找与匹配**

| 方法                       | 描述                                                         |
| -------------------------- | ------------------------------------------------------------ |
| **allMatch(Predicate p)**  | 检查是否匹配所有元素                                         |
| **anyMatch(Predicate p)**  | 检查是否至少匹配一个元素                                     |
| **noneMatch(Predicate p)** | 检查是否没有匹配所有元素                                     |
| **findFirst()**            | 返回第一个元素                                               |
| **findAny()**              | 返回当前流中的任意元素                                       |
| **count()**                | 返回流中元素总数                                             |
| **max(Comparator c)**      | 返回流中最大值                                               |
| **min(Comparator c)**      | 返回流中最小值                                               |
| **forEach(Consumer c)**    | 内部迭代(使用 Collection 接口需要用户去做迭代，称为外部迭代。相反，Stream API 使用内部迭代——它帮你把迭代做了) |

```java
/*
 * 终止操作：查找与匹配
 */
public class Test {
    public static void main(String[] args) {
        List<Integer> list = Arrays.asList(1,2,3,4,5,6,7,8,9);

        // false
        boolean allMatch = list.stream().allMatch(i -> i > 5);

        // true
        boolean anyMatch = list.stream().anyMatch(i -> i > 5);

        // false
        boolean noneMatch = list.stream().noneMatch(i -> i > 5);

        // Optional 封装， first.get() 取得元素值 ：1
        Optional<Integer> first = list.stream().findFirst();

        // 串行：第一个元素； 并行：任意一个
        Optional<Integer> any = list.stream().findAny();

        // 9
        long count = list.stream().count();

        // 9
        Optional<Integer> max = list.stream().max((x, y) -> x - y);

        // 1
        Optional<Integer> min = list.stream().min((x, y) -> x - y);
    }
}
```



**2、规约**

| 方法                                 | 描述                                                      |
| ------------------------------------ | --------------------------------------------------------- |
| **reduce(T iden, BinaryOperator b)** | 可以将流中元素反复结合起来，得到一个值。 返回 T           |
| **reduce(BinaryOperator b)**         | 可以将流中元素反复结合起来，得到一个值。 返回 Optional<T> |

备注：map 和 reduce 的连接通常称为 **map-reduce** 模式，因 Google 用它 来进行网络搜索而出名。

```java
/*
 * 终止操作：规约
 */
public class Test {
    public static void main(String[] args) {
        List<Integer> list = Arrays.asList(1,2,3,4,5,6,7,8,9);

        // 45
        Integer reduce1 = list.stream().reduce(0, Integer::sum);

        // 45
        Optional<Integer> reduce2 = list.stream().reduce(Integer::sum);
    }
}
```



**3、收集**

| 方法                     | 描述                                                         |
| ------------------------ | ------------------------------------------------------------ |
| **collect(Collector c)** | 将流转换为其他形式。接收一个 Collector 接口的 实现，用于给 Stream 中元素做汇总的方法 |



Collector 接口中方法的实现决定了如何对流执行收集操作(如收集到 List、Set、Map)。但是 **Collectors** 实用类提供了很多静态 方法，可以方便地创建常见收集器实例，具体方法与实例如下表：

| 方法                                                         | 返回类型              | 作用                                                         |
| ------------------------------------------------------------ | --------------------- | ------------------------------------------------------------ |
| Collectors.**toList**()                                      | List<T>               | 把流中元素收集到List                                         |
| Collectors.**toSet**()                                       | Set<T>                | 把流中元素收集到Set                                          |
| Collectors.**toCollection**(Supplier<C> collectionFactory)   | Collection<T>         | 把流中元素收集到创建的集合                                   |
| Collectors.**counting**()                                    | Long                  | 计算流中元素的个数                                           |
| Collectors.**summingInt**(ToIntFunction<? super T> mapper)   | Double                | 计算流中元素Integer属性的平均值                              |
| Collectors.**summarizingInt**(ToIntFunction<? super T> mapper) | IntSummaryStatistics  | 收集流中Integer属性的统计值。 如：平均值                     |
| Collectors.**joining**()                                     | String                | 连接流中每个字符串                                           |
| Collectors.**maxBy**(Comparator<? super T> comparator)       | Optional<T>           | 根据比较器选择最大值                                         |
| Collectors.**minBy**(Comparator<? super T> comparator)       | Optional<T>           | 根据比较器选择最小值                                         |
| Collectors.**reducing**(U identity, Function<? super T, ? extends U> mapper,  BinaryOperator<U> op) | 归约产生的类型        | 从一个作为累加器的初始值开始，利用BinaryOperator 与流中元素逐个结合，从而归约成单个值 |
| Collectors.**collectingAndThen**(Collector<T,A,R> downstream,                                                             Function<R,RR> finisher) | 转换函数返回的类型    | 包裹另一个收集器，对其结 果转换函数                          |
| Collectors.**groupingBy**(Function<? super T, ? extends K> classifier) | Map<K, List<T>>       | 根据某属性值对流分组，属 性为K，结果为V                      |
| Collectors.**partitioningBy**(Predicate<? super T> predicate) | Map<Boolean, List<T>> | 根据true或false进行分区                                      |



Employee.java

```java
public class Employee {

    private int id;
    private String name;
    private int age;
    private double salary;
    private Status status;

    public Employee() {
    }

    public Employee(String name) {
        this.name = name;
    }

    public Employee(String name, int age) {
        this.name = name;
        this.age = age;
    }

    public Employee(int id, String name, int age, double salary) {
        this.id = id;
        this.name = name;
        this.age = age;
        this.salary = salary;
    }

    public Employee(int id, String name, int age, double salary, Status status) {
        this.id = id;
        this.name = name;
        this.age = age;
        this.salary = salary;
        this.status = status;
    }

    public Status getStatus() {
        return status;
    }

    public void setStatus(Status status) {
        this.status = status;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public int getAge() {
        return age;
    }

    public void setAge(int age) {
        this.age = age;
    }

    public double getSalary() {
        return salary;
    }

    public void setSalary(double salary) {
        this.salary = salary;
    }

    public String show() {
        return "测试方法引用！";
    }

    @Override
    public int hashCode() {
        final int prime = 31;
        int result = 1;
        result = prime * result + age;
        result = prime * result + id;
        result = prime * result + ((name == null) ? 0 : name.hashCode());
        long temp;
        temp = Double.doubleToLongBits(salary);
        result = prime * result + (int) (temp ^ (temp >>> 32));
        return result;
    }

    @Override
    public boolean equals(Object obj) {
        if (this == obj)
            return true;
        if (obj == null)
            return false;
        if (getClass() != obj.getClass())
            return false;
        Employee other = (Employee) obj;
        if (age != other.age)
            return false;
        if (id != other.id)
            return false;
        if (name == null) {
            if (other.name != null)
                return false;
        } else if (!name.equals(other.name))
            return false;
        if (Double.doubleToLongBits(salary) != Double.doubleToLongBits(other.salary))
            return false;
        return true;
    }

    @Override
    public String toString() {
        return "Employee [id=" + id + ", name=" + name + ", age=" + age + ", salary=" + salary + ", status=" + status
                + "]";
    }

    public enum Status {
        FREE, BUSY, VOCATION;
    }
}
```



StreamTest.java

```java
/**
 * 终止操作：收集
 */
public class StreamTest {
    List<Employee> emps = Arrays.asList(
            new Employee(102, "李四", 79, 6666.66, Employee.Status.BUSY),
            new Employee(101, "张三", 18, 9999.99, Employee.Status.FREE),
            new Employee(103, "王五", 28, 3333.33, Employee.Status.VOCATION),
            new Employee(104, "赵六", 8, 7777.77, Employee.Status.BUSY),
            new Employee(104, "赵六", 8, 7777.77, Employee.Status.FREE),
            new Employee(104, "赵六", 8, 7777.77, Employee.Status.FREE),
            new Employee(105, "田七", 38, 5555.55, Employee.Status.BUSY)
    );

    // collect：将流转换为其他形式。接收一个 Collector接口的实现，用于给Stream中元素做汇总的方法
    @Test
    public void test1(){
        List<String> list = emps.stream()
                .map(Employee::getName)
                .collect(Collectors.toList());
        System.out.println(list);

        Set<String> set = emps.stream()
                .map(Employee::getName)
                .collect(Collectors.toSet());
        System.out.println(set);

        Set<String> hs = emps.stream()
                .map(Employee::getName)
                .collect(Collectors.toCollection(HashSet::new));
        System.out.println(hs);
    }

    @Test
    public void test2(){
        // 最大值
        Optional<Double> max = emps.stream()
                .map(Employee::getSalary)
                .collect(Collectors.maxBy(Double::compare));
        System.out.println(max.get());

        // 最小值
        Optional<Employee> op = emps.stream()
                .collect(Collectors.minBy((e1, e2) -> Double.compare(e1.getSalary(), e2.getSalary())));
        System.out.println(op.get());

        // 总值
        Double sum = emps.stream()
                .collect(Collectors.summingDouble(Employee::getSalary));
        System.out.println(sum);

        // 平均值
        Double avg = emps.stream()
                .collect(Collectors.averagingDouble(Employee::getSalary));
        System.out.println(avg);

        // 总数
        Long count = emps.stream()
                .collect(Collectors.counting());
        System.out.println(count);

        // 结果值的汇总统计信息
        DoubleSummaryStatistics dss = emps.stream()
                .collect(Collectors.summarizingDouble(Employee::getSalary));
        System.out.println(dss.getMax());
    }

    // 分组
    @Test
    public void test3(){
        Map<Employee.Status, List<Employee>> map = emps.stream()
                .collect(Collectors.groupingBy(Employee::getStatus));
        System.out.println(map);
    }

    // 多级分组
    @Test
    public void test4(){
        Map<Employee.Status, Map<String, List<Employee>>> map = emps.stream()
                .collect(Collectors.groupingBy(Employee::getStatus, Collectors.groupingBy(e -> {
                    if(e.getAge() >= 60)
                        return "老年";
                    else if(e.getAge() >= 35)
                        return "中年";
                    else
                        return "成年";
                })));
        System.out.println(map);
    }

    // 分区
    @Test
    public void test5(){
        Map<Boolean, List<Employee>> map = emps.stream()
                .collect(Collectors.partitioningBy(e -> e.getSalary() >= 5000));
        System.out.println(map);
    }

    // 将流元素连接成格式字符串
    @Test
    public void test6(){
        String str = emps.stream()
                .map(Employee::getName)
                .collect(Collectors.joining("," , "-", "-"));
        System.out.println(str);
    }

    @Test
    public void test7(){
        Optional<Double> sum = emps.stream()
                .map(Employee::getSalary)
                .collect(Collectors.reducing(Double::sum));
        System.out.println(sum.get());
    }
}
```



### 4. 并行流与串行流

**并行流：**就是把一个内容分成多个数据块，并用不同的线程分别处理每个数据块的流。

Java8 中将并行进行了优化，我们可以很容易的对数据进行并行操作。Stream API 可以声明性地通过 parallel() 与 sequential() 在并行流与顺序流之间进行切换。

#### 1. 了解 Fork/Join 框架

**Fork/Join 框架** ：就是在必要的情况下，将一个大任务，进行拆分(fork)成若干个 小任务（拆到不可再拆时），再将一个个的小任务运算的结果进行 join 汇总。

可以查看高并发相关文档

![](https://gitlab.com/eardh/picture/-/raw/main/new_feature_img/202111042209510.png)



#### 2. Fork/Join 框架与传统线程池的区别

**采用  “工作窃取” 模式（work-stealing）**：当执行新的任务时它可以将其拆分分成更小的任务执行，并将小任务加到线程队列中，然后再从一个随机线程的队列中偷一个并把它放在自己的队列中。

相对于一般的线程池实现，fork/join 框架的优势体现在对其中包含的任务的处理方式上。在一般的线程池中，如果一个线程正在执行的任务由于某些原因无法继续运行，那么该线程会处于等待状态。而在 fork/join 框架实现中，如果某个子问题由于等待另外一个子问题的完成而无法继续运行。那么处理该子问题的线程会主动寻找其他尚未运行的子问题来执行。这种方式减少了线程的等待时间，提高了性能。



#### 3. Stream 的并行流

```java
long sum = LongStream.rangeClosed(0, 10000000000L)
                .parallel() // 返回并行的等效流
                .sum();
```



## 5. 新时间日期API

**1. JDK7 Date 缺点**

1. 所有的日期类都是可变的，因此他们都不是线程安全的，这是 Java 日期类最大的问题之一。
2. Java 的日期/时间类的定义并不一致，在 java.util 和 java.sql 的包中都有日期类，此外
   用于格式化和解析的类在 java.text 包中定义。
3. java.util.Date 同时包含日期和时间，而 java.sql.Date 仅包含日期，将其纳入 java.sql
   包并不合理。另外这两个类都有相同的名字，这本身就是一个非常糟糕的设计。对于时间、时间戳、
   格式化以及解析，并没有一些明确定义的类。对于格式化和解析的需求，我们有 java.text.DateFormat
   抽象类，但通常情况下，SimpleDateFormat 类被用于此类需求
4. 日期类并不提供国际化，没有时区支持，因此 Java 引入了 java.util.Calendar 和
   java.util.TimeZone 类，但他们同样存在上述所有的问题



**2. JDK8 Date 优势**

1. **不变性：**新的日期/时间API中，所有的类都是不可变的，这对多线程环境有好处。
2. **关注点分离：**新的API将人可读的日期时间和机器时间（unix timestamp）明确分离，它为日期（Date）、
   时间（Time）、日期时间（DateTime）、时间戳（unix timestamp）以及时区定义了不同的类。
3. **清晰：**在所有的类中，方法都被明确定义用以完成相同的行为。举个例子，要拿到当前实例我们可以使用now() 方法，在所有的类中都定义了 format() 和 parse() 方法，而不是像以前那样专门有一个独立的类。为了更好的处理问题，所有的类都使用了工厂模式和策略模式，一旦你使用了其中某个类的方法，与其他类协同工作并不困难。
4. **实用操作：**所有新的日期/时间API类都实现了一系列方法用以完成通用的任务，如：加、减、格式化、解析、从日期/时间中提取单独部分，等等。
5. **可扩展性：**新的日期/时间API是工作在ISO-8601日历系统上的，但我们也可以将其应用在非IOS的日历上。

| 属性          | 含义                                                         |
| ------------- | ------------------------------------------------------------ |
| Instant       | 代表的是时间戳                                               |
| LocalDate     | 代表日期，比如：2021-11-4                                    |
| LocalTime     | 代表时刻，比如：20:29:30                                     |
| LocalDateTime | 代表具体时间 ：2021-11-4 20:29:30                            |
| ZonedDateTime | 代表一个包含时区的完整的日期时间，偏移量是以UTC/ 格林威治时间为基准的 |
| Period        | 代表时间段                                                   |
| ZoneOffset    | 代表时区偏移量，比如：+8:00                                  |
| Clock         | 代表时钟，比如获取目前美国纽约的时间                         |



### 1. 使用LocalDate、LocalTime、LocalDateTime

LocalDate、LocalTime、LocalDateTime 类的实例是 **不可变的对象**，分别表示使用 ISO-8601日历系统的日期、时间、日期和时间。它们提供 了简单的日期或时间，并不包含当前的时间信 息。也不包含与时区相关的信息。

注：ISO-8601日历系统是国际标准化组织制定的现代公民的日期和时间的表示法。

| 方法                                                 | 描述                                                         |
| ---------------------------------------------------- | ------------------------------------------------------------ |
| now()                                                | 静态方法，根据当前时间创建对象                               |
| of()                                                 | 静态方法，根据指定日期/时间创建对象                          |
| plusDays, plusWeeks, plusMonths, plusYears           | 向当前 LocalDate 对象添加几天、几周、几个月、几年            |
| minusDays, minusWeeks, minusMonths, minusYears       | 从当前 LocalDate 对象减去几天、几周、几个月、几年            |
| plus, minus                                          | 添加或减少一个Duration或 Period                              |
| withDayOfMonth, withDayOfYear,  withMonth,  withYear | 将月份天数、年份天数、月份、年份修改为指 定 的 值 并 返 回 新 的 LocalDate 对象 |
| getDayOfMonth                                        | 获得月份天数(1-31)                                           |
| getDayOfYear                                         | 获得年份天数(1-366)                                          |
| getDayOfWeek                                         | 获得星期几(返回一个 DayOfWeek 枚举值)                        |
| getMonth                                             | 获得月份，返回一个 Month 枚举值                              |
| getMonthValue                                        | 获得月份(1-12)                                               |
| getYear                                              | 获得年份                                                     |
| until                                                | 获得两个日期之间的 Period 对象， 或者指定 ChronoUnits 的数字 |
| isBefore, isAfter                                    | 比较两个 LocalDate                                           |
| isLeapYear                                           | 判断是否是闰年                                               |

```java
getYear()                         int        获取当前日期的年份
getMonth()                        Month      获取当前日期的月份对象
getMonthValue()                   int        获取当前日期是第几月
getDayOfWeek()                    DayOfWeek  表示该对象表示的日期是星期几
getDayOfMonth()                   int        表示该对象表示的日期是这个月第几天
getDayOfYear()                    int        表示该对象表示的日期是今年第几天
withYear(int year)                LocalDate  修改当前对象的年份
withMonth(int month)              LocalDate  修改当前对象的月份
withDayOfMonth(intdayOfMonth)     LocalDate  修改当前对象在当月的日期
isLeapYear()                      boolean    是否是闰年
lengthOfMonth()                   int        这个月有多少天
lengthOfYear()                    int        该对象表示的年份有多少天（365或者366）
plusYears(longyearsToAdd)         LocalDate  当前对象增加指定的年份数
plusMonths(longmonthsToAdd)       LocalDate  当前对象增加指定的月份数
plusWeeks(longweeksToAdd)         LocalDate  当前对象增加指定的周数
plusDays(longdaysToAdd)           LocalDate  当前对象增加指定的天数
minusYears(longyearsToSubtract)   LocalDate  当前对象减去指定的年数
minusMonths(longmonthsToSubtract) LocalDate  当前对象减去注定的月数
minusWeeks(longweeksToSubtract)   LocalDate  当前对象减去指定的周数
minusDays(longdaysToSubtract)     LocalDate  当前对象减去指定的天数
compareTo(ChronoLocalDateother)   int        比较当前对象和other对象在时间上的大小，返回值如果
    为正，则当前对象时间较晚，
isBefore(ChronoLocalDateother)    boolean    比较当前对象日期是否在other对象日期之前
isAfter(ChronoLocalDateother)     boolean    比较当前对象日期是否在other对象日期之后
isEqual(ChronoLocalDateother)     boolean    比较两个日期对象是否相等
```


```java
/**
 * 1. LocalDate、LocalTime、LocalDateTime
 */
public void test1(){
    LocalDateTime ldt = LocalDateTime.now();
    System.out.println(ldt);

    LocalDateTime ld2 = LocalDateTime.of(2021, 11, 4, 20, 40, 10);
    System.out.println(ld2);

    LocalDateTime ldt3 = ld2.plusYears(20);
    System.out.println(ldt3);

    LocalDateTime ldt4 = ld2.minusMonths(2);
    System.out.println(ldt4);

    System.out.println(ldt.getYear());
    System.out.println(ldt.getMonthValue());
    System.out.println(ldt.getDayOfMonth());
    System.out.println(ldt.getHour());
    System.out.println(ldt.getMinute());
    System.out.println(ldt.getSecond());
}
```



### 2. Instant 时间戳

用于 “时间戳” 的运算。它是以 Unix 元年(传统的设定为 UTC 时区1970年1月1日午夜时分)开始 所经历的描述进行运算

```java
/**
 * 2. Instant : 时间戳。（使用 Unix 元年  1970年1月1日 00:00:00 所经历的毫秒值
 */
public void test2(){
    Instant ins = Instant.now();  // 默认使用 UTC 时区
    System.out.println(ins);

    OffsetDateTime odt = ins.atOffset(ZoneOffset.ofHours(8));
    System.out.println(odt);

    System.out.println(ins.getNano());

    Instant ins2 = Instant.ofEpochSecond(5);
    System.out.println(ins2);
}
```



### 3. Duration 和 Period

**Duration**：用于计算两个“时间”间隔

**Period**：用于计算两个“日期”间隔

```java
/**
 * 3. Duration : 用于计算两个 时间 间隔
 *    Period : 用于计算两个 日期 间隔
 */
public void test3(){
    Instant ins1 = Instant.now();

    try {
        Thread.sleep(1000);
    } catch (InterruptedException ignored) {
        //
    }

    Instant ins2 = Instant.now();
    System.out.println("耗费时间：" + Duration.between(ins1, ins2).toMillis());

    LocalDate ld1 = LocalDate.now();
    LocalDate ld2 = LocalDate.of(2019, 1, 1);

    Period pe = Period.between(ld2, ld1);
    System.out.println(pe.getYears());
    System.out.println(pe.getMonths());
    System.out.println(pe.getDays());
}
```



### 4. 日期的操纵

- **TemporalAdjuster**：时间校正器。有时我们可能需要获 取例如：将日期调整到 “下个周日” 等操作。
- **TemporalAdjusters**：该类通过静态方法提供了大量的常用 TemporalAdjuster 的实现。

```java
/**
 * 4. TemporalAdjuster : 时间校正器
 */
public void test4(){
    LocalDateTime ldt = LocalDateTime.now();
    System.out.println(ldt);

    LocalDateTime ldt2 = ldt.withDayOfMonth(10);
    System.out.println(ldt2);

    LocalDateTime ldt3 = ldt.with(TemporalAdjusters.next(DayOfWeek.SUNDAY));
    System.out.println(ldt3);

    // 自定义：下一个工作日
    LocalDateTime ldt5 = ldt.with(l -> {
        LocalDateTime ldt4 = (LocalDateTime) l;

        DayOfWeek dow = ldt4.getDayOfWeek();

        if(dow.equals(DayOfWeek.FRIDAY)){
            return ldt4.plusDays(3);
        } else if(dow.equals(DayOfWeek.SATURDAY)){
            return ldt4.plusDays(2);
        } else {
            return ldt4.plusDays(1);
        }
    });
    System.out.println(ldt5);
}
```



### 5. 解析与格式化

java.time.format.DateTimeFormatter 类：该类提供了三种格式化方法：

- 预定义的标准格式

- 语言环境相关的格式

- 自定义的格式

```java
/**
 * 5. DateTimeFormatter : 解析和格式化日期或时间
 */
public void test5(){
    DateTimeFormatter dtf1 = DateTimeFormatter.ISO_LOCAL_DATE;
    DateTimeFormatter dtf = DateTimeFormatter.ofPattern("yyyy年MM月dd日 HH:mm:ss E");

    LocalDateTime ldt = LocalDateTime.now();
    String strDate = ldt.format(dtf);

    System.out.println(strDate);

    LocalDateTime newLdt = ldt.parse(strDate, dtf);
    System.out.println(newLdt);
}
```



### 6. 时区的处理

Java8 中加入了对时区的支持，带时区的时间为分别为： ZonedDate、ZonedTime、ZonedDateTime

其中每个时区都对应着 ID，地区ID都为 “{区域}/{城市}”的格式

例如 ：Asia/Shanghai 等

- ZoneId：该类中包含了所有的时区信息

- getAvailableZoneIds() : 可以获取所有时区时区信息

- of(id) : 用指定的时区信息获取ZoneId 对象

```java
/**
 * 6.ZonedDate、ZonedTime、ZonedDateTime ：带时区的时间或日期
 */
public void test7(){
    LocalDateTime ldt = LocalDateTime.now(ZoneId.of("Asia/Shanghai"));
    System.out.println(ldt);

    ZonedDateTime zdt = ZonedDateTime.now(ZoneId.of("US/Pacific"));
    System.out.println(zdt);
}
```



### 7. 与传统日期处理的转换

| 类                                                       | To 遗留类                               | From 遗留类                 |
| -------------------------------------------------------- | --------------------------------------- | --------------------------- |
| java.time.Instant java.util.Date                         | Date.from(instant)                      | date.toInstant()            |
| java.time.Instant     java.sql.Timestamp                 | Timestamp.from(instant)                 | timestamp.toInstant()       |
| java.time.ZonedDateTime  java.util.GregorianCalendar     | GregorianCalendar.from(zonedDateTim  e) | cal.toZonedDateTime()       |
| java.time.LocalDate           java.sql.Time              | Date.valueOf(localDate)                 | date.toLocalDate()          |
| java.time.LocalTime           java.sql.Time              | Date.valueOf(localDate)                 | date.toLocalTime()          |
| java.time.LocalDateTime  java.sql.Timestamp              | Timestamp.valueOf(localDateTime)        | timestamp.toLocalDateTime() |
| java.time.ZoneId      java.util.TimeZone                 | Timezone.getTimeZone(id)                | timeZone.toZoneId()         |
| java.time.format.DateTimeFormatter  java.text.DateFormat | formatter.toFormat()                    | 无                          |



## 6. 接口中的默认方法与静态方法

### 1. 接口中的默认方法

Java 8 中允许接口中包含具有具体实现的方法，该方法称为 “默认方法” ，默认方法使用 default 关键字修饰。

**==接口默认方法的”类优先”原则==**：若一个接口中定义了一个默认方法，而另外一个父类或接口中又定义了一个同名的方法时

- **选择父类中的方法**。如果一个父类提供了具体的实现，那么接口中具有相同名称和参数的默认方法会被忽略。
- **接口冲突**。如果一个父接口提供一个默认方法，而另一个接口也提供了一个具有相同名称和参数列表的方法（不管方法是否是默认方法），那么必须覆盖该方法来解决冲突

```java
public interface MyInterface {
    default void smile() {
        System.out.println("smile");
    }
}
```



### 2. 接口中的静态方法

Java8 中，接口中允许添加静态方法。

```java
public interface MyInterface {
    
    default void smile() {
        System.out.println("smile");
    }

    public static void cry() {
        System.out.println("cry");
    }
}
```



## 7. 其他新特性

### 1. Optional 类

**Optional<T>** 类 ( java.util.Optional ) 是一个容器类，代表一个值存在或不存在， 原来用 null 表示一个值不存在，现在 Optional 可以更好的表达这个概念。并且可以避免空指针异常。

| 方法                                                   | 描述                                                         |
| ------------------------------------------------------ | ------------------------------------------------------------ |
| **Optional.of(T t)**                                   | 创建一个 Optional 实例                                       |
| **Optional.empty()**                                   | 创建一个空的 Optional 实例                                   |
| **Optional.ofNullable(T t)**                           | 若 t 不为 null,创建 Optional 实例,否则创建空实例             |
| **ifPresent(Consumer<? super T> action)**              | 判断是否包含值                                               |
| **orElse(T t)**                                        | 如果调用对象包含值，返回该值，否则返回t                      |
| **orElseGet**(Supplier<? extends T> other)             | 如果调用对象包含值，返回该值，否则返回 s 获取的值            |
| **map**(Function<? super T, ? extends U>       mapper) | 如果有值对其处理，并返回处理后的Optional，否则返回 Optional.empty() |
| **flatMap**(Function<? super T, Optional<U>> mapper)   | 与 map 类似，要求返回值必须是Optional                        |

```java
/**
 * Optional 操作
 */
public class OptionalTest {
    public static void main(String[] args) {
        // Optional<T> of(T value)  传入 null 发生 NullPointerException
        Optional<String> optional1 = Optional.of(new String("huang"));

        // 调用 optional2.get() 发生 NullPointerException
        Optional<Object> optional2 = Optional.empty();

        Optional<Object> optional3 = Optional.ofNullable(null);

        optional1.ifPresent(System.out::println);

        Object orElse = optional3.orElse(1);
        System.out.println(orElse);

        Object orElseGet = optional3.orElseGet(() -> new String("huang"));
        System.out.println(orElseGet);

        Optional<Integer> map = optional3.map(Object::hashCode);
        System.out.println(map);

        Optional<Object> flatMap = optional3.flatMap(m -> Optional.empty());
        System.out.println(flatMap);
    }
}
```



### 2. 重复注解与类型注解

Java 8对注解处理提供了两点改进：可重复的注解及可用于类型的注解。

- **@Repeatable**

示例：

@MyAnnotation

```java
@Repeatable(value = MyAnnotations.class) // MyAnnotations ： 该重复注解的容器注解
@Retention(RetentionPolicy.RUNTIME)
@Target(value={CONSTRUCTOR, FIELD, LOCAL_VARIABLE, METHOD, PACKAGE, MODULE, PARAMETER, TYPE})
public @interface MyAnnotation {
    String value() default "dahuang";
}
```



@MyAnnotations

```java
@Retention(RetentionPolicy.RUNTIME)
@Target(value={TYPE})
public @interface MyAnnotations { // 用于装重复注解的容器
    MyAnnotation[] value();
}
```



AnnotationTest.java

```java
/**
 *  测试
 * @author dahuang
 * @date 2021/11/4 21:59
 */
@MyAnnotation(value = "小碗")
@MyAnnotation(value = "小李")
public class AnnotationTest {
    public static void main(String[] args) {
        Class<AnnotationTest> testClass = AnnotationTest.class;
        MyAnnotation[] annotations = testClass.getAnnotationsByType(MyAnnotation.class);
        for (MyAnnotation annotation : annotations) {
            System.out.println(annotation.value());
        }
    }
}
```

```java
// 结果： 👇
小碗
小李
```
