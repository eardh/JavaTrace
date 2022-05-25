# Spring注解驱动开发

Component是最最基础的注解。表示这是一个Bean 可以被注入到Spring container里。

其他三个就是Spring的经典三层layer了

@Controller @Service @Repository

**表现层**：表示此类专注于对前端请求进行转发和重定向

**业务层**：处理业务逻辑

**持久层**：DAO类 表示此类专注于对数据库进行数据的读取或者写入。



这三个注解表示了三个基本任务：**处理前端请求 处理业务逻辑 处理数据库读写**。

![](https://cdn.nlark.com/yuque/0/2021/png/393192/1624169818945-9e746934-e261-4bae-a8ca-a1800838e3df.png?x-oss-process=image%2Fresize%2Cw_1390%2Climit_0%2Fresize%2Cw_1125%2Climit_0)



## 1. 组件注册

### 1. AnnotationConfigApplicationContext

配置类

```java
//配置类=配置文件
@Configuration //告诉Spring这是一个配置类
//排除规则 指定扫描的时候按照什么规则排除那些组件 excludeFilters = Filter[]  排除注解类型FilterType.ANNOTATION
@ComponentScan(value = "com.zt" , excludeFilters = {@Filter(type = FilterType.ANNOTATION , classes = {Controller.class, Service.class})})
public class MainConfig {

    //给容器中注册一个Bean；类型为返回值的类型，id默认是用方法名作为id
    @Bean("person") //指定名字
    public Person getPerson(){
        return new Person("lisi",20);
    }

}
```

```java
@Configuration
//包含规则 指定扫描的时候只需要包含哪些组件 includeFilters = Filter[]
//useDefaultFilters = false 禁用默认的过滤规则
@ComponentScan(value = "com.zt" ,
               includeFilters = {@Filter(
                   type = FilterType.ANNOTATION,
                   classes = {Controller.class, Service.class})},
               useDefaultFilters = false)
public class MainConfig {
    //给容器中注册一个Bean；类型为返回值的类型，id默认是用方法名作为id
    @Bean("person") //指定名字
    public Person getPerson(){
        return new Person("lisi",20);
    }
}
```

```java
@Configuration //告诉Spring这是一个配置类
//@ComponentScans 包含多个ComponentScan规则
@ComponentScans(value = {
    @ComponentScan(value = "com.zt" ,
                   includeFilters = {@Filter(type = FilterType.ANNOTATION , classes = {Controller.class, Service.class})},useDefaultFilters = false)
})
public class MainConfig {
    //给容器中注册一个Bean；类型为返回值的类型，id默认是用方法名作为id
    @Bean("person") //指定名字
    public Person getPerson(){
        return new Person("lisi",20);
    }
}
```

测试类

```java
public class IocTest {

    @SuppressWarnings("resource")
    @Test
    public void test1(){
        AnnotationConfigApplicationContext context = new AnnotationConfigApplicationContext(MainConfig.class);
        String[] beanDefinitionNames = context.getBeanDefinitionNames();
        for (String beanDefinitionName : beanDefinitionNames) {
            System.out.println(beanDefinitionName);
        }
    }

}
```

过滤规则

```java
//FilterType.ANNOTATION : 按照注解方式
@Filter(type = FilterType.ANNOTATION,classes = {Controller.class, Service.class}

//FilterType.ASSIGNABLE_TYPE : 按照指定的类型 BookService的子类或者实现类都能被包含其中
@Filter(type = FilterType.ASSIGNABLE_TYPE,classes = {BookService.class}

//FilterType.ASPECTJ ： 使用ASPECTJ表达式

//FilterType.REGEX ： 使用正则表达式

//FilterType.CUSTOM ： 使用自定义规则 必须是TypeFilter的实现类
@Filter(type = FilterType.CUSTOM,classes = {MyTypeFilter.class}
```

```java
public class MyTypeFilter implements TypeFilter {

    //metadataReader : 读取到的当前正在扫描的类的信息
    @Override
    public boolean match(MetadataReader metadataReader, MetadataReaderFactory metadataReaderFactory) throws IOException {
        //获取当前类注解的信息
        AnnotationMetadata annotationMetadata = metadataReader.getAnnotationMetadata();
        //获取当前正在扫描的类的类信息
        ClassMetadata classMetadata = metadataReader.getClassMetadata();
        //获取当前类资源信息（类的路径等）
        Resource resource = metadataReader.getResource();
        
        String className = classMetadata.getClassName();
        System.out.println(className);
        if (className.contains("er"))
            return true;
        return false;
    }

}
```



### 2. @Scope 作用域

调整作用域

`prototype`：多实例的 ：IOC容器启动并不会调用方法创建对象放在容器中，每次获取的时候才会调用方法创建对象。

`singleton` ：单实例的（默认值）。 IOC容器启动会调用方法创建对象放在IOC容器，以后每次获取就是直接从容器(map.get())中拿

`request`：同一次请求创建一次 

`session`：同一个session创建一个实例

```java
@Configuration
public class MainConfig02 {

    //默认是单实例 无论是获取多少次都是同一个对象
    @Bean("person")
    //prototype：多实例的 singleton ：单实例的（默认值） request：同一次请求创建一次 session：同一个session创建一个实例
    @Scope("prototype")
    public Person person(){
        return new Person("张三",25);
    }

}
```



### 3. @Lazy  Bean懒加载

单例Bean：默认在容器启动的时候创建对象；

懒加载：容器启动不创建对象。第一次使用（获取）Bean创建对象，并初始化；

```java
@Configuration
public class MainConfig02 {

    @Bean("person")
    @Lazy
    public Person person(){
        return new Person("张三",25);
    }

}
```



### 4. @Conditional

按照一定的条件进行判断，满足条件给容器中注册Bean。

可以配置在类和方法上。

配置类

```java
//满足当前条件，这个类中配置的所有bean注册才能生效
@Conditional({WindowsCondition.class})
@Configuration
public class MainConfig02 {

    //默认是单实例 无论是获取多少次都是同一个对象
    @Bean("zhang")
    //prototype：多实例的 singleton ：单实例的（默认值） request：同一次请求创建一次 session：同一个session创建一个实例
    @Scope("prototype")
    public Person person(){
        return new Person("张三",25);
    }

    @Conditional({LinuxCondition.class})
    @Bean("li")
    public Person person01(){
        return new Person("李四",15);
    }

    //@Conditional 传递的是Condition数组
    @Conditional({WindowsCondition.class})
    @Bean("wang")
    public Person person02(){
        return new Person("王五",35);
    }
}

```

自定义条件1

```java
//判断是否是Linux系统
public class LinuxCondition implements Condition {

    //conditionContext 判断条件能使用的上下文（环境）
    //annotatedTypeMetadata 注解信息
    @Override
    public boolean matches(ConditionContext conditionContext, AnnotatedTypeMetadata annotatedTypeMetadata) {
        //能获取到IOC使用的BeanFactory
        ConfigurableListableBeanFactory beanFactory = conditionContext.getBeanFactory();
        //获取到类加载器
        ClassLoader classLoader = conditionContext.getClassLoader();
        //获取环境信息
        Environment environment = conditionContext.getEnvironment();
        //获取到bean定义的注册类
        BeanDefinitionRegistry registry = conditionContext.getRegistry();

        //可以判断容器中的bean注册情况，也可以给容器中注册bean
        boolean definition = registry.containsBeanDefinition("person");

        String name = environment.getProperty("os.name");
        //        System.out.println(name);
        if (name.contains("linux")){
            return true;
        }
        return false;
    }

}
```

自定义条件2

```java
//判断是否是Windows系统
public class WindowsCondition implements Condition {

    @Override
    public boolean matches(ConditionContext conditionContext, AnnotatedTypeMetadata annotatedTypeMetadata) {
        Environment environment = conditionContext.getEnvironment();
        String name = environment.getProperty("os.name");
        if (name.contains("Windows")){
            return true;
        }
        return false;
    }
}

```

测试类

```java
@Test
public void test3(){
    AnnotationConfigApplicationContext context = new AnnotationConfigApplicationContext(MainConfig02.class);
    ConfigurableEnvironment environment = context.getEnvironment();
    //动态获取环境变量的值
    String osName = environment.getProperty("os.name");
    System.out.println(osName);

    String[] names = context.getBeanNamesForType(Person.class);
    for (String name : names) {
        System.out.println(name);
    }
    Map<String, Person> beans = context.getBeansOfType(Person.class);
    System.out.println(beans);
}
```



## 2. 组件注入

给容器中注册组件

1. 包扫描+组件标注注解（`@Controller / @Service / @Repository / @Component`）局限于是自己写的类

2. @Bean 导入的第三方包里面的组件

3. `@Import`  快速给容器中导入一个组件
   1. `@Import(要导入的容器)`  容器中就会自动注册这个组件，id默认是全类名。可以批量导入（写的是数组）
   
   2. `ImportSelector`：返回需要导入的组件的全类名数组，进行批量导入 
   3. `ImportBeanDefinitionRegistrar` ： 手动注册bean到容器中
   
4. 使用Spring提供的FactoryBean（工厂Bean）

   1. 默认获取到的是工厂Bean调用getObject创建的对象

   2. 要获取工厂Bean本身，我们要在给id前面加一个&



### 1. @Import 

配置类

```java
@Configuration
//导入组件，id默认是组件的全类名 直接使用@import导入需要spring4.2以上版本，不然会报错
//@Import(Color.class)
@Import({Red.class, MyImportSelector.class, MyImportBeanDefinitionRegistrar.class})
public class MainConfig021 {

}
```

**ImportBeanDefinitionRegistrar实现类**

```java
public class MyImportBeanDefinitionRegistrar implements ImportBeanDefinitionRegistrar {
    //AnnotationMetadata 当前类的注解信息
    //BeanDefinitionRegistry：BeanDefinition注册类；
    //      把所有需要添加到容器中bean 调用
    //      BeanDefinitionRegistry.registerBeanDefinition 手工注册
    @Override
    public void registerBeanDefinitions(AnnotationMetadata annotationMetadata, BeanDefinitionRegistry beanDefinitionRegistry) {
        boolean definition = beanDefinitionRegistry.containsBeanDefinition("com.zt.bean.Blue");
        boolean definition1 = beanDefinitionRegistry.containsBeanDefinition("com.zt.bean.Yellow");
        if (definition && definition1){
            //指定bean定义信息（Bean的类型，Bean 的作用域等）
            RootBeanDefinition beanDefinition = new RootBeanDefinition(RainBow.class);
            //注册一个bean
            beanDefinitionRegistry.registerBeanDefinition("rainRow",beanDefinition);//指定bean名
        }
    }
}
```

**ImportSelector实现类**

```java
//自定义逻辑返回需要导入的组件
public class MyImportSelector implements ImportSelector {

    //返回值就是导入到容器中的组件全类名
    //AnnotationMetadata ： 当前标注@Import 注解的类的所有注解信息
    @Override 
    public String[] selectImports(AnnotationMetadata annotationMetadata) {

        //方法不要返回null值，否则会报空指针异常
        return new String[]{"com.zt.bean.Blue","com.zt.bean.Yellow"};
    }
}
```

测试类

```java
@Test
public void test4(){
    AnnotationConfigApplicationContext context = new AnnotationConfigApplicationContext(MainConfig021.class);

    String[] names = context.getBeanDefinitionNames();
    for (String name : names) {
        System.out.println(name);
    }
    Map<String, Person> beans = context.getBeansOfType(Person.class);
    System.out.println(beans);
}
```



### 2. FactoryBean

工厂Bean

```java
//创建一个Spring定义的FactoryBean
public class ColorFactoryBean implements FactoryBean<Color> {
    //返回一个Color对象，这个对象会添加到容器中
    @Override
    public Color getObject() throws Exception {
        System.out.println("ColorFactoryBean...");
        return new Color();
    }

    @Override
    public Class<?> getObjectType() {
        return Color.class;
    }

    //是否是单例
    //true : 这个bean是单实例，在容器中保存一份
    //false : 多实例，每次获取都会创建一个新的bean
    @Override
    public boolean isSingleton() {
        return true;
    }
}
```

配置类

```java
@Configuration
//导入组件，id默认是组件的全类名 直接使用@import导入需要spring4.2以上版本，不然会报错
//@Import(Color.class)
@Import({Red.class, MyImportSelector.class, MyImportBeanDefinitionRegistrar.class})
public class MainConfig021 {

    @Bean
    public ColorFactoryBean colorFactoryBean(){
        return new ColorFactoryBean();
    }

}
```

测试类

```java
@Test
public void test5(){
    AnnotationConfigApplicationContext context = new AnnotationConfigApplicationContext(MainConfig021.class);

    String[] names = context.getBeanDefinitionNames();
    for (String name : names) {
        System.out.println(name);
    }
    //工程Bean获取的是调用getObject创建的对象
    Object colorFactoryBean = context.getBean("colorFactoryBean");
    System.out.println("bean的类型："+colorFactoryBean.getClass());

    //要获取工厂Bean本身，我们要在给id前面加一个&
    Object colorFactoryBean1 = context.getBean("&colorFactoryBean");
    System.out.println("bean的类型："+colorFactoryBean1.getClass());
}
```





## 3. 生命周期

bean的生命周期：

- `Bean创建 ---> 初始化 ---> 销毁的过程`

容器来管理Bean的生命周期。

我们可以自定义初始化和销毁的方法；容器在Bean 进行到当前生命周期的时候来调用我们自定义的初始化和销毁方法。

- **构造（对象创建）**
  - 单实例：在容器启动的时候创建对象
  - 多实例：在每次获取的时候创建对象
- **初始化**
  - 对象创建完成，并赋值好，调用初始化方法
- **销毁**
  - 单实例：容器关闭的时候销毁Bean
  - 多实例：容器不会管你这个Bean；容器不会调用销毁方法。需要手动销毁



### 1. 初始化和销毁方法

#### 1. @Bean init-method 和 destroy-method

Bean类

```java
public class Car {
    public Car() {
        System.out.println("Car constructor...");
    }

    public void init(){
        System.out.println("Car ... init ...");
    }

    public void destroy(){
        System.out.println("Car ... destroy ...");
    }
}
```

配置类

```java
@Configuration
public class MainConfigOfLifeCycle {

    @Scope("prototype")
    @Bean(initMethod = "init" , destroyMethod = "destroy")
    public Car car(){
        return new Car();
    }
}
```

测试类

```java
@Test
public void test6(){
    //创建IOC容器
    AnnotationConfigApplicationContext context = new AnnotationConfigApplicationContext(MainConfigOfLifeCycle.class);

    String[] names = context.getBeanDefinitionNames();
    for (String name : names) {
        System.out.println(name);
    }

    //关闭容器
    context.close();
}
```



#### 2. Bean 实现 InitializingBean、DisposableBean

- `InitializingBean` ：定义初始化逻辑
- `DisposableBean` ：定义销毁逻辑

Bean类

```java
@Component
public class Cat implements InitializingBean , DisposableBean {

    public Cat() {
        System.out.println("Cat constructor ...");
    }

    //销毁
    @Override
    public void destroy() throws Exception {
        System.out.println("Cat destroy ...");
    }

    //初始化
    @Override
    public void afterPropertiesSet() throws Exception {
        System.out.println("Cat init ...");
    }
}
```

配置类

```java
@ComponentScan("com.zt.bean")
@Configuration
public class MainConfigOfLifeCycle {
}
```

测试类

```java
@Test
public void test7(){
    //创建IOC容器
    AnnotationConfigApplicationContext context = new AnnotationConfigApplicationContext(MainConfigOfLifeCycle.class);

    String[] names = context.getBeanDefinitionNames();
    for (String name : names) {
        System.out.println(name);
    }

    //关闭容器
    context.close();
}
```



#### 3. JSR250

- @PostConstruct：在Bean 创建完成并且属性赋值完成；来执行初始化
- @PreDestroy：在容器销毁bean之前通知我们进行清理工作

Bean类

```java
@Component
public class Dog {

    public Dog() {
        System.out.println("Dog constructor ...");
    }

    //对象创建并赋值之后调用
    @PostConstruct
    public void init(){
        System.out.println("Dog ... @PostConstruct ... init ...");
    }

    //容器移除对象之前
    @PreDestroy
    public void destroy(){
        System.out.println("Dog ... @PreDestroy ... destroy ...");
    }

}
```

配置类

```java
@ComponentScan("com.zt.bean")
@Configuration
public class MainConfigOfLifeCycle {
}
```

测试方法

```java
@Test
public void test7(){
    //创建IOC容器
    AnnotationConfigApplicationContext context = new AnnotationConfigApplicationContext(MainConfigOfLifeCycle.class);

    String[] names = context.getBeanDefinitionNames();
    for (String name : names) {
        System.out.println(name);
    }

    //关闭容器
    context.close();
}
```



### 2. BeanPostProcessor接口

Bean的后置处理器；在Bean初始化前后进行一些处理工作

- `postProcessBeforeInitialization()` : 在初始化之前工作

- `postProcessAfterInitialization()` : 在初始化之后工作

**BeanPostProcessor 的原理**

```java
populateBean(beanName,mbd,instanceWrapper);   // 给Bean进行属性赋值
initializeBean(beanName, exposedObject, mbd); // 初始化Bean

// 遍历得到容器中所有的BeanPostProcessor；挨个执行beforeInitialization，
// 一旦返回null，就跳出for循环，不会执行后面的 BeanPostProcessor.postProcessorsBeforeInitialization
protected Object initializeBean(String beanName, Object bean, @Nullable RootBeanDefinition mbd) {
    if (System.getSecurityManager() != null) {
        AccessController.doPrivileged((PrivilegedAction<Object>) () -> {
            invokeAwareMethods(beanName, bean);
            return null;
        }, getAccessControlContext());
    }
    else {
        invokeAwareMethods(beanName, bean);
    }

    Object wrappedBean = bean;
    if (mbd == null || !mbd.isSynthetic()) {
        wrappedBean = applyBeanPostProcessorsBeforeInitialization(wrappedBean, beanName);
    }

    try {
        invokeInitMethods(beanName, wrappedBean, mbd); // 执行自定义初始化
    }
    catch (Throwable ex) {
        throw new BeanCreationException(
            (mbd != null ? mbd.getResourceDescription() : null),
            beanName, "Invocation of init method failed", ex);
    }
    if (mbd == null || !mbd.isSynthetic()) {
        wrappedBean = applyBeanPostProcessorsAfterInitialization(wrappedBean, beanName);
    }

    return wrappedBean;
}
```

[Spring底层对BeanPostProcessor的使用](https://www.bilibili.com/video/BV1gW411W7wy?p=17&spm_id_from=pageDriver)

Bean赋值、注入其他组件、@Autowired、声明周期注解功能、@Async等等，都是由BeanPostProcessor完成的。有不同的PostProcessor进行处理。

**BeanPostProcessor实现类**

```java
@Component
//后置处理器：初始化前后进行处理
public class MyBeanPostProcessor implements BeanPostProcessor {

    @Override
    public Object postProcessBeforeInitialization(Object o, String s) throws BeansException {
        System.out.println("postProcessBeforeInitialization... beanName is "+s+" bean is "+o);
        return o;
    }

    @Override
    public Object postProcessAfterInitialization(Object o, String s) throws BeansException {
        System.out.println("postProcessAfterInitialization... beanName is "+s+" bean is "+o);
        return o;
    }
}
```

**测试方法**

```java
@Test
public void test7(){
    //创建IOC容器
    AnnotationConfigApplicationContext context = new AnnotationConfigApplicationContext(MainConfigOfLifeCycle.class);

    String[] names = context.getBeanDefinitionNames();
    for (String name : names) {
        System.out.println(name);
    }

    //关闭容器
    context.close();
}
```



### 3. 组件赋值

使用 `@Value` 进行赋值 

1. 基本数值
2. 可以写SpEL；#{}
3. 可以写 ${}; 取出配置文件【properties】中的值（在运行环境变量里边的值）

Bean类

```java
public class Person {

    @Value("San Zhang")
    private String name;
    @Value("#{20-2}")
    private Integer age;
    // 要取出外边配置文件的值 必须在xml文件中配置<context:property-placeholder location= "classpath :person.properties"/>
    @Value("${person.nickName}")
    private String nickName;

    public Person() {
    }

    public Person(String name, Integer age) {
        this.name = name;
        this.age = age;
    }

    public Person(String name, Integer age, String nickName) {
        this.name = name;
        this.age = age;
        this.nickName = nickName;
    }

    @Override
    public String toString() {
        return "Person{" +
            "name='" + name + '\'' +
            ", age=" + age +
            ", nickName='" + nickName + '\'' +
            '}';
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public Integer getAge() {
        return age;
    }

    public void setAge(Integer age) {
        this.age = age;
    }

    public String getNickName() {
        return nickName;
    }

    public void setNickName(String nickName) {
        this.nickName = nickName;
    }
}
```

配置类

```java
//使用@PropertySource读取外部配置文件中的k/v保存到运行的环境变量中
@PropertySource(value = "classpath:/person.properties")
@Configuration
public class MainConfigOfPropertyValues {

    @Bean
    public Person person(){
        return new Person();
    }
}
```

配置文件

```properties
person.nickName=Small San Zhang
```

测试方法

```java
@Test
public void test8(){
    AnnotationConfigApplicationContext context = new AnnotationConfigApplicationContext(MainConfigOfPropertyValues.class);

    String[] names = context.getBeanDefinitionNames();
    for (String name : names) {
        System.out.println(name);
    }

    Person person = context.getBean(Person.class);
    System.out.println(person);

    ConfigurableEnvironment environment = context.getEnvironment();
    String property = environment.getProperty("person.nickName");
    System.out.println("person.nickName: "+property);
}
```





## 4. 自动装配

自动装配：Spring利用依赖注入（`DI`），完成对IOC容器中各个组件的依赖关系赋值



### 1. @Autowired

#### 1. 属性注入

1. 默认优先按照类型去容器中找对应的组件：applicationContext.getBean(BookDao.class);
2. 如果找到多个相同类型的组件，再将属性的名称作为组件的ID去容器中查找：applicationContext.getBean("bookDao1");
3. @Qualifier("bookDao") 指定需要装配的组件ID，而不是使用属性名

```java
class BookService {
    @Qualifier("bookDao")
    @Autowired(required=false)
    private BookDao bookDao1;
}
```

4. 自动装配一定要将属性赋值好，如果容器中没有指定的类，就会报错。可以指定@Autowired(required=false)避免报错。
5. `@Primary`：让Spring进行自动装配的时候，默认使用首选的Bean。也可以继续使用@Qualifier来指定需要装配的Bean的名字。



#### 2. 方法注入

标注在方法上，Spring容器创建当前对象，就会调用方法，完成赋值

方法使用的参数，自定义类型的值从IOC容器中获取

```java
//默认加在IOC容器中的组件，容器启动会调用无参构造器创建对象，再进行初始化赋值等操作
@Component
public class Boss {

    private Car car;

    @Override
    public String toString() {
        return "Boss{" +
            "car=" + car +
            '}';
    }

    public Car getCar() {
        return car;
    }

    // 标注在方法上，Spring容器创建当前对象，就会调用方法，完成赋值
    // 方法使用的参数，自定义类型的值从IOC容器中获取
    @Autowired
    public void setCar(Car car) {
        this.car = car;
    }
}
```



#### 3. 构造器注入

构造器要用的组件，是从容器中获取

如果组件只有一个有参构造器，这个有参构造器的 @Autowired 可以省略，参数位置的组件还是可以自动从容器中获取。

```java
//默认加在IOC容器中的组件，容器启动会调用无参构造器创建对象，再进行初始化赋值等操作
@Component
public class Boss {

    private Car car;

    //构造器要用的组件，都是从容器中获取
    @Autowired //可以省略
    public Boss(Car car) {
        this.car = car;
    }

    @Override
    public String toString() {
        return "Boss{" +
            "car=" + car +
            '}';
    }

    public Car getCar() {
        return car;
    }

    public void setCar(Car car) {
        this.car = car;
    }
}
```



#### 4. 参数注入

参数要用的组件，也是容器中获取

```java
//默认加在IOC容器中的组件，容器启动会调用无参构造器创建对象，再进行初始化赋值等操作
@Component
public class Boss {

    private Car car;

    public Boss(@Autowired Car car) {
        this.car = car;
    }

    @Override
    public String toString() {
        return "Boss{" +
            "car=" + car +
            '}';
    }

    public Car getCar() {
        return car;
    }

    //标注在方法上，Spring容器创建当前对象，就会调用方法，完成赋值
    //方法使用的参数，自定义类型的值从IOC容器中获取
    //@Autowired
    public void setCar(Car car) {
        this.car = car;
    }
}
```

**@Bean 标注的方法创建对象的时候，方法参数的值是从容器中获取**

```java
@Bean
public Color color(Car car){
	return new Color();
}
```



### 2. Java规范的注解

#### 1. @Resource(JSR250)

`@Resource`：可以和@Autowired一样实现自动装配功能；默认是按照组件名称进行装配

但是没有支持@Primary和@Autowired(required=false)的功能

```java
BookService{
    @Resource(name = "bookDao") //可以通过指定name来进行注入
    private BookDao bookDao1;
}
```



#### 2. @Inject(JSR330)

`@Inject`：和@Autowired的功能一样，但是比@Autowired少一个required=false的功能

需要导入一个依赖

```xml
<dependency>
    <groupId>javax.inject</groupId>
    <artifactId>javax.inject</artifactId>
    <version>1</version>
</dependency>
```



#### 3. 三者区别

`@Autowired`是由Spring定义的；而`@Resource`和`@Inject`是Java规范

`AutowiredAnnotationBeanPostProcessor` ：解析完成自动装配功能;



### 3. 自定义组件实现xxxAware

自定义组件想要使用Spring容器底层的一些组件（ApplicationContext，BeanFactory，xxx）

自定义组件实现xxxAware；在创建对象的时候，会调用接口规定的方法注入相关组件。

把Spring底层一些组件注入到自定义的Bean；

**xxxAware都是由xxxAwareProcessor来处理的。**

例如ApplicationContextAware 是由ApplicationContextAwareProcessor来处理的。ApplicationContextAwareProcessor则是BeanPostProcessor的实现类。注入组件是由xxxAwareProcessor中的invokeAwareInterfaces(Object bean) 方法来实现注入的。

```java
@Component
public class Red implements ApplicationContextAware, BeanNameAware, EmbeddedValueResolverAware {
    ApplicationContext applicationContext;
    @Override
    public void setApplicationContext(ApplicationContext applicationContext) throws BeansException {
        this.applicationContext = applicationContext;
        System.out.println("传入的IOC：" + applicationContext);
    }

    @Override
    public void setBeanName(String s) {
        System.out.println("当前Bean的名字"+s);
    }

    @Override
    public void setEmbeddedValueResolver(StringValueResolver stringValueResolver) {
        String resolveStringValue = stringValueResolver.resolveStringValue("系统名称是 ${os.name} 能够计算20*18=#{20*18}");
        System.out.println("解析的字符串："+resolveStringValue);
    }
}
```



### 4. @Profile

指定组件在哪个环境的情况下才能被注册到容器中。如果不指定@Profile，任何环境下都能注册这个组件

以数据源为例，先导入数据源

```xml
<dependency>
    <groupId>c3p0</groupId>
    <artifactId>c3p0</artifactId>
    <version>0.9.1.2</version>
</dependency>
<dependency>
    <groupId>mysql</groupId>
    <artifactId>mysql-connector-java</artifactId>
    <version>5.1.49</version>
</dependency>
```



#### 1. @Bean上的@Profile

加了环境标识@Profile的Bean，只有在这个环境被激活的时候才能被注册到容器中。默认是Default环境。

配置类

```java
/*Profile ：
*   Spring为我们提供的可以根据当前环境，动态的激活和切换一系列组件的功能;
*
* 一个项目中一般有：开发环境、测试环境、生产环境
*   数据源：(/A) (/B) (/C)*/
@Configuration
@PropertySource("classpath:/jdbc_config.properties")
public class MainConfigOfProfile implements EmbeddedValueResolverAware {

    @Value("${db.user}")
    private String user;

    private String driverClass;


    @Profile("test")
    @Bean
    public Yellow yellow(){
        return new Yellow();
    }

    //测试数据源
    @Profile("test")
    @Bean("testDataSource")
    public DataSource dataSourceTest(@Value("${db.password}") String password) throws PropertyVetoException {
        ComboPooledDataSource dataSource = new ComboPooledDataSource();
        dataSource.setUser(user);
        dataSource.setPassword(password);
        dataSource.setJdbcUrl("jdbc:mysql://localhost:3306/test");
        dataSource.setDriverClass(driverClass);
        return dataSource;
    }

    //开发数据源
    @Profile("dev")
    @Bean("devDataSource")
    public DataSource dataSourceDev(@Value("${db.password}") String password) throws PropertyVetoException {
        ComboPooledDataSource dataSource = new ComboPooledDataSource();
        dataSource.setUser(user);
        dataSource.setPassword(password);
        dataSource.setJdbcUrl("jdbc:mysql://localhost:3306/dev");
        dataSource.setDriverClass(driverClass);
        return dataSource;
    }

    //生产数据源
    @Profile("prod")
    @Bean("prodDataSource")
    public DataSource dataSourceProd(@Value("${db.password}") String password) throws PropertyVetoException {
        ComboPooledDataSource dataSource = new ComboPooledDataSource();
        dataSource.setUser(user);
        dataSource.setPassword(password);
        dataSource.setJdbcUrl("jdbc:mysql://localhost:3306/prod");
        dataSource.setDriverClass(driverClass);
        return dataSource;
    }

    @Override
    public void setEmbeddedValueResolver(StringValueResolver stringValueResolver) {
        driverClass = stringValueResolver.resolveStringValue("${db.driverClass}");
    }
}
```

测试方法：

```java
//使用命令行动态参数 在虚拟机参数位置加载 -Dspring.profiles.active=dev
//代码方式
@Test
public void test11(){
    //创建一个ApplicationContext对象 此处需要调用无参构造器，如果调用有参构造器的话会直接启动容器，无法进行中间配置
    AnnotationConfigApplicationContext context = new AnnotationConfigApplicationContext();
    //设置需要激活的环境 可一次性设置多个
    context.getEnvironment().setActiveProfiles("test","dev");
    //注册主配置类
    context.register(MainConfigOfProfile.class);
    //启动刷新容器
    context.refresh();

    String[] names = context.getBeanDefinitionNames();
    for (String name : names) {
        System.out.println(name);
    }

}
```



#### 2. 类上的@Profile

写在配置类上，只有是指定的环境的时候，整个配置类里面的所有配置才能开始生效

```java
@Profile("test")
@Configuration
public class MainConfigOfProfile{

}
```





## 5. AOP 动态代理

指在程序运行期间动态的将某段代码切入到指定方法指定位置进行运行的编程方式；

三步:

1)、将业务逻辑组件和切面类都加入到容器中;告诉Spring哪个是切面类(@Aspect)

2)、在切面类上的每一个通知方法上标注通知注解，告诉Spring何时何地运行(切入点表达式)

3)、开启基于注解的aop模式;



### 1. AOP示例

1. 导入AOP模块，Spring AOP

```xml
<dependency>
    <groupId>org.springframework</groupId>
    <artifactId>spring-aspects</artifactId>
    <version>5.3.12</version>
</dependency>
```

2. 定义一个业务逻辑类（spring-aspects）；在业务逻辑运行的时候将日志进行打印（方法之前、方法运行结束、方法出现异常，xxx）

```java
public class MathCalculator {
    public int div(int i , int j){
        return i/j;
    }
}
```

3. 定义一个日志切面类；切面类里面的方法需要动态感知MathCalculator.div 运行到哪里然后执行

```java
public class LogAspects {
    public void logStart(){
        System.out.println("除法运行...参数列表是：{}");
    }

    public void logEnd(){
        System.out.println("除法结束...");
    }

    public void logReturn(){
        System.out.println("除法正常返回...计算结果是：{}");
    }

    public void logException(){
        System.out.println("除法异常...异常信息是：{}");
    }
}
```

**通知方法：**

前置通知(@Before)：logStart；在目标方法（div）运行之前运行

后置通知(@After)：logEnd；在目标方法（div）运行结束之后运行。无论方法正常结束还是异常结束，都调用

返回通知(@AfterReturning)：logReturn；在目标方法（div）正常返回之后运行

异常通知(@AfterThrowing**)**：logException；在目标方法（div）出现异常之后运行

环绕通知(@Around)：动态代理，手动 推进目标方法运行（joinPoint.procced( )）

4. 给切面类的目标方法标注何时何地运行（通知注解）

```java
public class LogAspects {

    //抽取公共的切入点表达式
    //本类引用 @Before("pointCut()")
    //其他类引用 @Before("com.zt.aop.LogAspects.pointCut()")
    @Pointcut("execution(public int com.zt.aop.MathCalculator.*(..))")
    public void pointCut(){}

    //@Before在目标方法之前切入;切入点表达式（指定在哪个方法切入）
    @Before("pointCut()") //public int com.zt.aop.MathCalculator.div(int,int)
    public void logStart(JoinPoint joinPoint){ // JoinPoint 必须放在参数的第一位
        Object[] args = joinPoint.getArgs();
        System.out.println(joinPoint.getSignature().getName()+"运行...参数列表是：{"+ Arrays.asList(args) +"}");
    }
    @After("pointCut()")
    public void logEnd(JoinPoint joinPoint){
        System.out.println(joinPoint.getSignature().getName()+"结束...");
    }
    @AfterReturning(value = "pointCut()",returning = "result")
    public void logReturn(Object result){
        System.out.println("除法正常返回...计算结果是：{"+result+"}");
    }

    @AfterThrowing(value = "pointCut()",throwing = "e")
    public void logException(Exception e){
        System.out.println("除法异常...异常信息是：{"+e+"}");
    }

}
```

5. 将切面类和业务逻辑类（目标方法所在类）都加入到容器中

```java
@Configuration
public class MainConfigOfAOP {
    //业务逻辑类加入到容器中
    @Bean
    public MathCalculator mathCalculator(){
        return new MathCalculator();
    }

    //切面类加入到容器中
    @Bean
    public LogAspects logAspects(){
        return new LogAspects();
    }
}
```

6. 必须告诉Spring哪个类是切面类（给切面类上加一个注解 @Aspect ）

```java
@Aspect
public class LogAspects {}
```

7. 给配置类中加@EnableAspectJAutoProxy【开启基于注解的AOP模式】

```java
@EnableAspectJAutoProxy
@Configuration
public class MainConfigOfAOP {}
```

8. 测试方法

```java
@Test
public void test(){
    AnnotationConfigApplicationContext applicationContext = new AnnotationConfigApplicationContext(MainConfigOfAOP.class);

    MathCalculator calculator = applicationContext.getBean(MathCalculator.class);
    System.out.println(calculator.div(10, 2));

    applicationContext.close();

}
```

```shell
# 输出结果：
div运行...参数列表是：{[10, 2]}
MathCalculator...div...
div结束...
除法正常返回...计算结果是：{5}
5
```



### 2. AOP原理

1. **@EnableAspectJAutoProxy**

@Import(AspectJAutoProxyRegistrar.class) 给容器中导入AspectJAutoProxyRegistrar。利用AspectJAutoProxyRegistrar自定义给容器中注册Bean。BeanDefinetion

internalAutoProxyCreator = AnnotationAwareAspectJAutoProxyCreator

给容器中注册一个AnnotationAwareAspectJAutoProxyCreator



2. **AnnotationAwareAspectJAutoProxyCreator**

AnnotationAwareAspectJAutoProxyCreator

-> AspectJAwareAdvisorAutoProxyCreator

-> AbstractAdvisorAutoProxyCreator

-> AbstractAutoProxyCreator

implements SmartInstantiationAware**BeanPostProcessor**, **BeanFactoryAware**

关注后置处理器（在bean初始化完成前后做事情）、自动装配BeanFactory



AbstractAutoProxyCreator.setBeanFactory( )

AbstractAutoProxyCreator.有后置处理器的逻辑;



AbstractAdvisorAutoProxyCreator.setBeanFactory( )  -> initBeanFactory()



AnnotationAwareAspectJAutoProxyCreator.initBeanFactory()



#### 1. AOP流程

1. 传入配置类，创建IOC容器

2. 注册配置类，调用refresh()

3. registerBeanPostProcessors(beanFactory) ;注册bean的后置处理器来方便拦截bean的创建

   1. 先获取ioc容器已经定义了的需要创建对象的所有BeanPostProcessor

   2. 给容器中加别的BeanPostProcessor

   3. 优先注册实现了PriorityOrdered接口的BeanPostProcessor;

   4. 再在给容器中注册实现了Ordered接口的BeanPostProcessor

   5. 再注册没实现优先级接口的BeanPostProcessor

   6. 注册BeanPostProcessor,实际上就是创建BeanPostProcessor对象，保存在容器中: 创建**internalAutoProxyCreator** 的BeanPostProcessor【实际上是创建**AnnotationAwareAspectJAutoProxyCreator**】

      1. 创建Bean的实例
      2. populateBean( beanName, mbd, instanceWrapper) ;给Bean的各种属性赋值
      3. initializeBean:初始化bean
         1. invokeAwareMethods( ): 处理Aware接口的回调；判断Bean是不是Aware接口的，如果是，就调用相关的Aware方法。
            - 执行AbstractAutoProxyCreator.setBeanFactory( )
         2. applyBeanPostProcessorsBeforeInitialization() 用用后置处理器的postProcessBeforeInitialization()
         3. invokeInitMethods( ); 执行自定义的初始化方法
         4. applyBeanPostProcessorsAfterInitialization() 用用后置处理器的postProcessAfterInitialization()

      4. BeanPostProcessor(AnnotationAwareAspectJAutoProxyCreator) 创建成功 -> aspectJAdvisorsBuilder

   7. 把BeanPostProcessor注册到BeanFactory中;

**以上是创建和注册AnnotationAwareAspectJAutoProxyCreator(一个后置处理器)的过程**

AnnotationAwareAspectJAutoProxyCreator => InstantiationAwareBeanPostProcessor

4. finishBeanFactoryInitialization(beanFactory) ;完成BeanFactory初始化工作;创建剩下的单实例Bean

   1. 遍历获取容器中所有的Bean,依次创建对象getBean(beanName)

      - getBean -> doGetBean( ) -> getSingleton( ) ->

   2. 创建Bean【AnnotationAwareAspectJAutoProxyCreator会在任何bean创建之前会有一个拦截 ，InstantiationAwareBeanPostProcessor会调用postProcessBeforeInstantiation( )】

      1. 先从缓存中获取当前Bean，如果能获取到，说明之前Bean是被创建过的直接使用，否则再创建。只要创建好的Bean都会被缓存起来

      2. createBean ();创建bean 【AnnotationAwareAspectJAutoProxyCreator会在任何bean创建之前先尝试返回bean的实例】【BeanPostProcessor是在Bean对象创建完成初始化前后调用的】【InstantiationAwareBeanPostProcessor是在创建Bean实例之前先尝试用后置处理器返回对象的（实例化之后，初始化之前）】

         1. resolveBeforeInstantiation(beanName, mbdToUse) ;解析BeforeInstantiation。希望后置处理器在此能返回一个代理对象，如果能返回代理对象就使用，如果不能就继

            ```java
            4.b.ii.1.
            bean = applyBeanPostProcessorsBeforeInstantiation();
            //拿到所有后置处理器，如果是InstantiationAwareBeanPostProcessor ;就执行postProcessBeforeInstantiation
            if(bean!=null){
                bean = applyBeanPostProcessorsAfterInstantiation();
            }
            ```

         2. doCreateBean( beanName, mbdToUse, args) ;真正的去创建一个Bean实例，和上边3.f流程一样。



#### 2. AnnotationAwareAspectJAutoProxyCreator的作用

1. AnnotationAwareAspectJAutoProxyCreator【InstantiationAwareBeanPostProcessor】的作用: 每一个bean创建之前，调用postProcessBeforeInstantiation( );**关心MathCalculator和LogAspect的创建**
   1. 判断当前bean是否在advisedBeans中 (保存了所有需要增强的bean)
   2. 判断当前bean是否是基础类型的Advice、Pointcut、Advisor、AopInfrastructureBean或者是否是切面(@Aspect)
   3. 判断是否需要跳过
      1. 获取候选的增强器(切面里面的通知方法) 【List<Advisor> candidateAdvisors】
         - 每一个封装的通知方法的增强器是InstantiationModelAwarePointcutAdvisor;
         - 判断每一个增强器是否是AspectJPointcutAdvisor类型的;如果是返回true
      2. 由于只关心自己实现的业务逻辑和切面两个类。但这切面内面的通知方法的增强器是InstantiationModelAwarePointcutAdvisor，因此永远返回false

2. 创建对象 postProcessAfterInitialization; return wrapIfNecessary( bean, beanName, cacheKey);//包装如果需要的情况下
   1. 获取当前bean的所有增强器(通知方法)  Object[] specificInterceptors
      1. 找到候选的所有的增强器(找哪些通知方法是需要切入当前bean方法的)
      2. 获取到能在bean使用的增强器
      3. 给增强器排序
   2. 保存当前bean在advisedBeans中;
   3. 如果当前bean需要增强，创建当前bean的代理对象;
      1. 获取所有增强器(通知方法)
      2. 保存到proxyFactory
      3. 创建代理对象: Spring自动决定
         - JdkDynami cAopProxy ( config) ; jdk动态代理;
         - ObjenesisCglibAopProxy( config) ; cgli b的动态代理;
   4. 给容器中返回当前组件使用cglib增强了的代理对象;
   5. 以后容器中获取到的就是这个组件的代理对象，执行目标方法的时候，代理对象就会执行通知方法的流程

3. 目标方法执行 容器中保存了组件的代理对象(cglib增强后的对象)，这个对象里面保存了详细信息(比如增强器，目标对象，xxx) 根据ProxyFactory对象获取将要执行的目标方法拦截器链;
   1. CglibAopProxy .intercept( );拦截目标方法的执行
   2. 根据ProxyFactory对象获取将要执行的目标方法拦截器链; List<Object> chain = this.advised.getInterceptorsAndDynamicInterceptionAdvice ( method, targetClass) ;
      1. List<object> interceptorList保存所有拦截器 （长度为5） 一个默认的ExposeInvocationInterceptor和4个增强器;
      2. 遍历所有的增强器，将其转为Interceptor;registry. getInterceptors(advisor);
      3. 将增强器转为List <MethodInterceptor>;如果是MethodInterceptor,直接加入到集合中；如果不是，使用AdvisorAdapter将增强器转为MethodInterceptor
   3. 如果没有拦戴器链，直接执行目标方法；拦截器链(每一一个通知方法又被包装为方法拦截器，利用Met hodInterceptor机制)
   4. 如果有拦截器链，把需要执行的目标对象，目标方法，拦截器链等信息传入创建一 个CglibMethodInvocation对象，并调用object retVal = mi. proceed();
   5. 拦截器链的触发过程
      1. 如果没有拦截器执行执行目标方法，或者拦截器的索引和拦截器数组-1大小一样(执行到了最后一个拦截器 ) 执行目标方法
      2. 链式获取每一个拦截器， 拦截器执行invoke方法，每一个拦截器等待 下一个拦截器执行完成返回以后再来执行；拦截器链的机制，保证通知方法与目标方法的执行顺序

![](https://cdn.nlark.com/yuque/0/2021/png/1485212/1635659323269-2e653b9e-6786-4e12-9d2c-3e5317ae7dfe.png?x-oss-process=image%2Fresize%2Cw_1125%2Climit_0)



### 3. AOP总结

1. @EnableAspectJAutoProxy 开启AOP功能
2. @EnableAspectJAutoProxy 会给容器中注册一个组件AnnotationAwareAspectJAutoProxyCreator
3. AnnotationAwareAspectJAutoProxyCreator是一 个后置处理器;
4. 容器的创建流程: 
   1. registerBeanPostProcessors()注册后置处理器；创建AnnotationAwareAspectJAutoProxyCreator
   2. finishBeanFactoryInitialization() 初始化剩下的单实例bean
      1. 创建业务逻辑组件和切面组件
      2. AnnotationAwareAspectJAutoProxyCreator拦截组件的创建过程
      3. 组件创建完之后，判断组件是否需要增强。如果是:切面的通知方法，包装成增强器(Advisor) ;给业务逻辑组件创建一 个代理对象（cglib）

5. 执行目标方法:

   1. 代理对象执行目标方法

   2. CglibAopProxy.intercept( ) 进行拦截

      1. 得到目标方法的拦截器链(增强器)

      2. 利用拦截器的链式机制，依次进入每一个拦截器进行执行;

      3. 效果:

         正常执行:前置通知-》目标方法-》后置通知-》返回通知

         出现异常:前置通知-》目标方法-》后置通知-》异常通知





## 6. 声明式事务

### 1. 事务实现流程

**环境搭建:**

1. 导入相关依赖

   数据源、数据库驱动、Spring-jdbc模块

```xml
<dependency>
    <groupId>c3p0</groupId>
    <artifactId>c3p0</artifactId>
    <version>0.9.1.2</version>
</dependency>
<dependency>
    <groupId>mysql</groupId>
    <artifactId>mysql-connector-java</artifactId>
    <version>5.1.49</version>
</dependency>
<dependency>
    <groupId>org.springframework</groupId>
    <artifactId>spring-jdbc</artifactId>
    <version>4.3.12.RELEASE</version>
</dependency>
<dependency>
    <groupId>org.springframework</groupId>
    <artifactId>spring-orm</artifactId>
    <version>4.3.12.RELEASE</version>
</dependency>
```

2. 配置数据源、JdbcTemplate操作数据库

配置类

```java
@PropertySource("classpath:/jdbc_config.properties")
@Configuration
public class TxConfig {
    @Value("${db.user}")
    private String user;

    @Value("${db.password}")
    private String password;

    @Value("${db.driverClass}")
    private String driverClass;

    @Value("${db.url}")
    private String url;

    //数据源
    @Bean
    public DataSource dataSource() throws PropertyVetoException {
        ComboPooledDataSource comboPooledDataSource = new ComboPooledDataSource();
        comboPooledDataSource.setUser(user);
        comboPooledDataSource.setPassword(password);
        comboPooledDataSource.setJdbcUrl(url);
        comboPooledDataSource.setDriverClass(driverClass);
        return comboPooledDataSource;
    }

    @Bean
    public JdbcTemplate jdbcTemplate(DataSource dataSource){
        //Spring对@Configuration类会特殊处理;给容器中加组件的方法，多次调用都只是从容器中找组件|
        //JdbcTemplate jdbcTemplate = new JdbcTemplate(dataSource());
        JdbcTemplate jdbcTemplate = new JdbcTemplate(dataSource);
        return jdbcTemplate;
    }
}
```

```java
@Repository
public class UserDao {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    public void insert(){
        String sql = "insert into `tbl_user`(username,age) values(?,?)";
        String name = UUID.randomUUID().toString().substring(0, 5);
        jdbcTemplate.update(sql,name,19);
    }

}
```

```java
@Service
public class UserService {
    @Autowired
    private UserDao userDao;

    public void insert(){
        userDao.insert();
    }
}
```

测试方法：

```java
@Test
public void test12(){
    AnnotationConfigApplicationContext context = new AnnotationConfigApplicationContext(TxConfig.class);

    UserService service = context.getBean(UserService.class);
    service.insert();

}
```

3. 给方法上标注@Transactional表示当前方法是一个事务方法; 

4. @EnableTransactionManagement 开启基于注解的事务管理功能;

   @EnableXXX 类似的注解都是实现某一项功能的

5. 配置事务管理器来控制事务: public PlatformTransactionManager transactionManager(DataSource dataSource)

```java
@PropertySource("classpath:/jdbc_config.properties")
@Configuration
@EnableTransactionManagement
public class TxConfig {
    @Value("${db.user}")
    private String user;

    @Value("${db.password}")
    private String password;

    @Value("${db.driverClass}")
    private String driverClass;

    @Value("${db.url}")
    private String url;

    //数据源
    @Bean
    public DataSource dataSource() throws PropertyVetoException {
        ComboPooledDataSource comboPooledDataSource = new ComboPooledDataSource();
        comboPooledDataSource.setUser(user);
        comboPooledDataSource.setPassword(password);
        comboPooledDataSource.setJdbcUrl(url);
        comboPooledDataSource.setDriverClass(driverClass);
        return comboPooledDataSource;
    }

    @Bean
    public JdbcTemplate jdbcTemplate(DataSource dataSource){
        //Spring对@Configuration类会特殊处理;给容器中加组件的方法，多次调用都只是从容器中找组件|
        //JdbcTemplate jdbcTemplate = new JdbcTemplate(dataSource());
        JdbcTemplate jdbcTemplate = new JdbcTemplate(dataSource);
        return jdbcTemplate;
    }

    //注册事务管理器在容器中
    @Bean
    public PlatformTransactionManager transactionManager(DataSource dataSource){
        return new DataSourceTransactionManager(dataSource);
    }

}
```



### 2. 事务原理

原理:

1. @EnableTransactionManagement利用@Import({TransactionManagementConfigurationSelector.**class**}) 导入TransactionManagementConfiguration**Selector**，然后给容器中导入组件

   导入两个组件：AutoProxyRegistrar、ProxyTransactionManagementConfiguration

2. AutoProxyRegistrar

   给容器中注册一个InfrastructureAdvisorAutoProxyCreator（也是一个后置处理器）组件InfrastructureAdvisorAutoProxyCreator 是利用后置处理器机制在对象创建以后【实例化之后，初始化之前】，包装对象，返回一个代理对象(增强器)，代理对象执行方法利用拦截器链进行调用;

3. ProxyTransactionManagementConfiguration

   - 给容器中注册事务增强器;

     1. 事务增强器要用事务注解的信息，AnnotationTransactionAttributeSource解析事务注解

     2. 事务拦截器:

        TransactionInterceptor;保存了事务属性信息，事务管理器;

        他是一个MethodInterceptor;

        在目标方法执行的时候 ，执行拦截器链;

        事务拦截器:

        1. 先获取事务相关的属性

        2. 再获取PlatformTransactionManager，如果事先没有添加指定任何transactionManager，最终会从容器中按照类型获取一个PlatformTransactionManager。

        3. 执行目标方法 

           如果异常，获取到事务管理器，利用事务管理回滚操作;

           如果正常，利用事务管理器，提交事务

**从上所述，事务底层就是AOP实现的，before里面开启事务，affter提交事务。affterthrowing回滚事务**





## 7. 扩展原理

### 1. BeanFactoryPostProcessor

1. **BeanPostProcessor**: bean后置处理器，bean创建 对象初始化前后进行拦截工作的

2. **BeanFactoryPostProcessor**: beanFactory的后置处理器;

beanFactory 标准初始化之后调用;所有的bean定义已经保存加载到beanFactory,但是bean的实例还未创建



1. ioc容器创建对象

2. invokeBeanFactoryPostProcessors (beanFactory);执行BeanFactoryPostProcessors

   如何找到所有的BeanFactoryPostProcessor并执行他们的方法;

   1. 直接在BeanFactory中找到所有类型是BeanFactoryPostProcessor的组件，并执行他们的方法
   2. 在初始化创建其他组件前面执行

```java
@Component
public class MyBeanFactoryPostProcessor implements BeanFactoryPostProcessor {


    @Override
    public void postProcessBeanFactory(ConfigurableListableBeanFactory configurableListableBeanFactory) throws BeansException {
        System.out.println("MyBeanFactoryPostProcessor...postProcessBeanFactory...");
        int count = configurableListableBeanFactory.getBeanDefinitionCount();
        String[] names = configurableListableBeanFactory.getBeanDefinitionNames();
        System.out.println("当前BeanFactory中有"+count+"个Bean 分别是 "+ Arrays.asList(names));
    }
}
```



### 2. BeanDefinitionRegistryPostProcessor

**BeanDefinitionRegistryPostProcessor** extends BeanFactoryPostProcessor

postProcessBeanDefinitionRegistry();

在所有bean定义信息将要被加载，bean实例还未创建的;

```java
@Component
public class MyBeanDefinitionRegistryPostProcessor implements BeanDefinitionRegistryPostProcessor {
    @Override
    public void postProcessBeanFactory(ConfigurableListableBeanFactory configurableListableBeanFactory) throws BeansException {
        System.out.println("MyBeanDefinitionRegistryPostProcessor...postProcessBeanFactory...");
    }
    //BeanDefinitionRegistry 是Bean定义信息的保存中心，
    //以后BeanFactory就是按照BeanDefinitionRegistry里面保存的每一个bean定义信息创建Bean实例
    @Override
    public void postProcessBeanDefinitionRegistry(BeanDefinitionRegistry beanDefinitionRegistry) throws BeansException {
        System.out.println("MyBeanDefinitionRegistryPostProcessor...postProcessBeanDefinitionRegistry...");
        //        RootBeanDefinition beanDefinition = new RootBeanDefinition(Blue.class);
        AbstractBeanDefinition beanDefinition = BeanDefinitionBuilder.rootBeanDefinition(Blue.class).getBeanDefinition();
        beanDefinitionRegistry.registerBeanDefinition("hello",beanDefinition);
    }
}
```

优先于BeanFactoryPostProcessor执行; 利用BeanDefinitionRegistryPostProcessor给容器中再额外添加一些组件;

**原理:**

1. ioc创建对象
2. refresh()-> invokeBeanFactoryPostProcessors (beanFactory);
3. 从容器中获取到所有的BeanDefinitionRegistryPostProcessor组件
   1. 依次触发所有的postProcessBeanDefinitionRegistry( ) 方法
   2. 再来触发postProcessBeanFactory( ) 【是BeanFactoryPostProcessor 中规定的】

4. 再来从容器中找到BeanF actoryPostProcessor组件;然后依次触发postProcessBeanFactory() 方法



### 3. ApplicationListener

```java
//监听容器中发布的事件。完成事件驱动模型开发;
public interface ApplicationListener<E extends ApplicationEvent>
```

监听ApplicationEvent及其下面的子事件

![](https://cdn.nlark.com/yuque/0/2021/png/1485212/1635671113919-2993c312-7943-4bb6-a5a7-9e9ec7746424.png)



#### 1. 步骤

1. 写一个监听器（ApplicationListener实现类）来监听某个事件(ApplicationEvent及其子类)或用注解@EventListener

```java
@Component
public class MyApplicationListener implements ApplicationListener<ApplicationEvent> {

    // 当容器中发布此事件以后，方法触发
    @Override
    public void onApplicationEvent(ApplicationEvent applicationEvent) {
        System.out.println("收到时间："+applicationEvent);
    }
}
```

```java
@Service
public class UserService {

    @EventListener(classes = {ApplicationEvent.class})
    public void listen(ApplicationEvent event){
        System.out.println("UserService...监听到的事件"+event);
    }

}
```

2. 把监听器加入到容器;

3. 只要容器中有相关事件的发布，我们就能监听到这个事件;

   ContextRefreshedEvent:容器刷新完成(所有bean都完全创建)会发布这个事件;

   ContextClosedEvent:关闭容器会发布这个事件;

4. 发布一个事件:

```java
@Test
public void test(){
    AnnotationConfigApplicationContext context = new AnnotationConfigApplicationContext(ExtConfig.class);
    //发布事件
    context.publishEvent(new ApplicationEvent(new String("我发布的事件")) {
    });
    context.close();
}
```



#### 2. 原理

ContextRefreshedEvent、IOCTestExt$1[ source=[我发布的时间] （自己发布的事件）、ContextClosedEvent

1. ContextRefreshedEvent事件:
   1. 容器创建对象:  调用refresh();
   2. finishRefresh(); 容器刷新完成会发布ContextRefreshed Event事件
2. 自己发布事件
3. 容器关闭会发布ContextClosedEvent; 

**【事件发布流程】:**

-  publishEvent (new 【ContextRefreshedEvent/自己发布事件/ContextClosedEvent】(this));
   1. 获取事件的多播器(派发器) : getApplicationEventMulticaster()
   2. multicastEvent派发事件:
   3. 获取到所有的ApplicationListener; for (final ApplicationListener<?> listener : getApplicationListeners(event, type)
      1. 如果有Executor,可以支持使用Executor进行异步派发，Executor executor = getTaskExecutor();
      2. 否则，同步的方式直接执行listener方法; invokeListener(listener, event) ;拿到listener回调onApplicationEvent方法;

**【事件多播器(派发器) 】**

1. 容器创建对象: refresh();
2. initApplicationEventMulticaster() ;初始化ApplicationEventMulticaster;
   1. 先去容器中找有没有id="applicationEventMulticaster'的组件;
   2. 如果没有this.applicationEventMulticaster = new SimpleApplicationEventMulticaster(beanFactory) 并且加入到容器 beanFactory.registerSingleton(APPLICATION_EVENT_MULTICASTER_BEAN_NAME, this. applicationEventMulticaster)，我们就可以在其他组件要派发事件，自动注入这个applicationEventMulticaster;

**【容器中有哪些监听器？getApplicationListeners】**

1. 容器创建对象：refresh();

2. 容器创建对象：registerlisteners();

   从容器中拿到所有的监听器，把他们注册到applicationEventMulticaster中;

   String[] listenerBeanNames = getBeanNamesForType(ApplicationListener.class, true, false) //将listener注册到ApplicationEventMulticaster中getApplicationEventMulticaster().addApplicationListenerBean(listenerBeanName);

**【@EventListener原理】**

使用EventListenerMethodProcessor处理器来解析方法上的@EventListener

EventListenerMethodProcessor implements  SmartInitializingSingleton



### 4. SmartInitializingSingleton

【SmartInitializingSingleton原理】-> afterSingletonsInstantiated() 在所有单实例Bean 创建完成以后调用

1. ioc容器创建对象并refresh( );

2. finishBeanFactoryInitialization( beanFactory ) ;初始化剩下的单实例bean;

   1. 先创建所有的单实例bean; getBean();

   2. 获取所有创建好的单实例bean， 判断是否是SmartInitializingSingleton类型的;

      如果是就调用afterSingletonsInstantiated() ;

获取每个bean中标注了@EventListener的方法，再通过EventListenerFactory创建一个ApplicationListerner对象。再把这个ApplicationListener对象保存到到ApplicationContext也就是IOC容器中。再在最里面注册到派发器applicationEventMulticaster中





## 8. Spring容器创建过程

### 1. 源码

```java
public AnnotationConfigApplicationContext(Class<?>... annotatedClasses) {
    this();
    this.register(annotatedClasses);
    this.refresh();//重点关注这个方法
}
```

```java
public void refresh() throws BeansException, IllegalStateException {
    synchronized(this.startupShutdownMonitor) {
        this.prepareRefresh();//刷新前的预处理工作
        ConfigurableListableBeanFactory beanFactory = this.obtainFreshBeanFactory(); //获取BeanFactory
        this.prepareBeanFactory(beanFactory);//BeanFactory的预处理设置（beanFactory进行一些设置）
        try {
            this.postProcessBeanFactory(beanFactory);//BeanFactory准备工作完成后进行的后置处理工作；
            this.invokeBeanFactoryPostProcessors(beanFactory);//执行BeanFactoryPostProcessor
            this.registerBeanPostProcessors(beanFactory);//注册BeanPostProcessors（注册Bean的后置处理器）
            this.initMessageSource();//初始化MessageSource组件(做国际化功能;消息绑定，消息解析)
            this.initApplicationEventMulticaster();//初始化事件派发器
            this.onRefresh();//留给子容器（子类 ）子类可以重写这个方法，在容器刷新的时候可以自定义逻辑;
            this.registerListeners();//给容器中将所有项目里面的ApplicationListener注册进来
            this.finishBeanFactoryInitialization(beanFactory);//初始化所有剩下的单实例bean
            this.finishRefresh();//完成BeanFactory的初始化创建工作。IOC容器就创建完成
        } catch (BeansException var9) {
            if (this.logger.isWarnEnabled()) {
                this.logger.warn("Exception encountered during context initialization - cancelling refresh attempt: " + var9);
            }
            this.destroyBeans();
            this.cancelRefresh(var9);
            throw var9;
        } finally {
            this.resetCommonCaches();
        }
    }
}
```

prepareRefresh();//刷新前的预处理工作

```java
protected void prepareRefresh() {
    this.startupDate = System.currentTimeMillis();
    this.closed.set(false);
    this.active.set(true);
    if (this.logger.isInfoEnabled()) {
        this.logger.info("Refreshing " + this);
    }
    this.initPropertySources();//初始化一些属性设置 方法中为空 留给子类处理
    this.getEnvironment().validateRequiredProperties();//属性校验
    this.earlyApplicationEvents = new LinkedHashSet(); //保存容器中的一些早期的事件
}
```

obtainFreshBeanFactory();//获取BeanFactory

```java
protected ConfigurableListableBeanFactory obtainFreshBeanFactory() {
    this.refreshBeanFactory();//刷新BeanFactory
    ConfigurableListableBeanFactory beanFactory = this.getBeanFactory();
    if (this.logger.isDebugEnabled()) {
        this.logger.debug("Bean factory for " + this.getDisplayName() + ": " + beanFactory);
    }
    return beanFactory;
}
```

prepareBeanFactory(beanFactory);//BeanFactory的预处理设置（beanFactory进行一些设置）

```java
protected void prepareBeanFactory(ConfigurableListableBeanFactory beanFactory) {
    beanFactory.setBeanClassLoader(this.getClassLoader());
    beanFactory.setBeanExpressionResolver(new StandardBeanExpressionResolver(beanFactory.getBeanClassLoader()));
    beanFactory.addPropertyEditorRegistrar(new ResourceEditorRegistrar(this, this.getEnvironment()));
    beanFactory.addBeanPostProcessor(new ApplicationContextAwareProcessor(this));
    beanFactory.ignoreDependencyInterface(EnvironmentAware.class);
    beanFactory.ignoreDependencyInterface(EmbeddedValueResolverAware.class);
    beanFactory.ignoreDependencyInterface(ResourceLoaderAware.class);
    beanFactory.ignoreDependencyInterface(ApplicationEventPublisherAware.class);
    beanFactory.ignoreDependencyInterface(MessageSourceAware.class);
    beanFactory.ignoreDependencyInterface(ApplicationContextAware.class);
    beanFactory.registerResolvableDependency(BeanFactory.class, beanFactory);
    beanFactory.registerResolvableDependency(ResourceLoader.class, this);
    beanFactory.registerResolvableDependency(ApplicationEventPublisher.class, this);
    beanFactory.registerResolvableDependency(ApplicationContext.class, this);
    beanFactory.addBeanPostProcessor(new ApplicationListenerDetector(this));
    if (beanFactory.containsBean("loadTimeWeaver")) {
        beanFactory.addBeanPostProcessor(new LoadTimeWeaverAwareProcessor(beanFactory));
        beanFactory.setTempClassLoader(new ContextTypeMatchClassLoader(beanFactory.getBeanClassLoader()));
    }
    if (!beanFactory.containsLocalBean("environment")) {
        beanFactory.registerSingleton("environment", this.getEnvironment());
    }
    if (!beanFactory.containsLocalBean("systemProperties")) {
        beanFactory.registerSingleton("systemProperties", this.getEnvironment().getSystemProperties());
    }
    if (!beanFactory.containsLocalBean("systemEnvironment")) {
        beanFactory.registerSingleton("systemEnvironment", this.getEnvironment().getSystemEnvironment());
    }
}
```

invokeBeanFactoryPostProcessors(beanFactory);//执行BeanFactoryPostProcessor

```java
protected void invokeBeanFactoryPostProcessors(ConfigurableListableBeanFactory beanFactory) {
    PostProcessorRegistrationDelegate.invokeBeanFactoryPostProcessors(beanFactory, this.getBeanFactoryPostProcessors());
    if (beanFactory.getTempClassLoader() == null && beanFactory.containsBean("loadTimeWeaver")) {
        beanFactory.addBeanPostProcessor(new LoadTimeWeaverAwareProcessor(beanFactory));
        beanFactory.setTempClassLoader(new ContextTypeMatchClassLoader(beanFactory.getBeanClassLoader()));
    }
}
```

invokeBeanFactoryPostProcessors -> PostProcessorRegistrationDelegate.invokeBeanFactoryPostProcessors(beanFactory, this.getBeanFactoryPostProcessors());

```java
public static void invokeBeanFactoryPostProcessors(ConfigurableListableBeanFactory beanFactory, List<BeanFactoryPostProcessor> beanFactoryPostProcessors) {
    Set<String> processedBeans = new HashSet();
    int var9;
    ArrayList currentRegistryProcessors;
    String[] postProcessorNames;
    if (beanFactory instanceof BeanDefinitionRegistry) {
        BeanDefinitionRegistry registry = (BeanDefinitionRegistry)beanFactory;
        List<BeanFactoryPostProcessor> regularPostProcessors = new LinkedList();
        List<BeanDefinitionRegistryPostProcessor> registryProcessors = new LinkedList();
        Iterator var6 = beanFactoryPostProcessors.iterator();
        while(var6.hasNext()) {
            BeanFactoryPostProcessor postProcessor = (BeanFactoryPostProcessor)var6.next();
            if (postProcessor instanceof BeanDefinitionRegistryPostProcessor) {
                BeanDefinitionRegistryPostProcessor registryProcessor = (BeanDefinitionRegistryPostProcessor)postProcessor;
                registryProcessor.postProcessBeanDefinitionRegistry(registry);
                registryProcessors.add(registryProcessor);
            } else {
                regularPostProcessors.add(postProcessor);
            }
        }
        currentRegistryProcessors = new ArrayList();
        postProcessorNames = beanFactory.getBeanNamesForType(BeanDefinitionRegistryPostProcessor.class, true, false);
        String[] var18 = postProcessorNames;
        var9 = postProcessorNames.length;
        int var10;
        String ppName;
        for(var10 = 0; var10 < var9; ++var10) {
            ppName = var18[var10];
            if (beanFactory.isTypeMatch(ppName, PriorityOrdered.class)) {
                currentRegistryProcessors.add(beanFactory.getBean(ppName, BeanDefinitionRegistryPostProcessor.class));
                processedBeans.add(ppName);
            }
        }
        sortPostProcessors(currentRegistryProcessors, beanFactory);
        registryProcessors.addAll(currentRegistryProcessors);
        invokeBeanDefinitionRegistryPostProcessors(currentRegistryProcessors, registry);
        currentRegistryProcessors.clear();
        postProcessorNames = beanFactory.getBeanNamesForType(BeanDefinitionRegistryPostProcessor.class, true, false);
        var18 = postProcessorNames;
        var9 = postProcessorNames.length;
        for(var10 = 0; var10 < var9; ++var10) {
            ppName = var18[var10];
            if (!processedBeans.contains(ppName) && beanFactory.isTypeMatch(ppName, Ordered.class)) {
                currentRegistryProcessors.add(beanFactory.getBean(ppName, BeanDefinitionRegistryPostProcessor.class));
                processedBeans.add(ppName);
            }
        }
        sortPostProcessors(currentRegistryProcessors, beanFactory);
        registryProcessors.addAll(currentRegistryProcessors);
        invokeBeanDefinitionRegistryPostProcessors(currentRegistryProcessors, registry);
        currentRegistryProcessors.clear();
        boolean reiterate = true;
        while(reiterate) {
            reiterate = false;
            postProcessorNames = beanFactory.getBeanNamesForType(BeanDefinitionRegistryPostProcessor.class, true, false);
            String[] var21 = postProcessorNames;
            var10 = postProcessorNames.length;
            for(int var28 = 0; var28 < var10; ++var28) {
                String ppName = var21[var28];
                if (!processedBeans.contains(ppName)) {
                    currentRegistryProcessors.add(beanFactory.getBean(ppName, BeanDefinitionRegistryPostProcessor.class));
                    processedBeans.add(ppName);
                    reiterate = true;
                }
            }
            sortPostProcessors(currentRegistryProcessors, beanFactory);
            registryProcessors.addAll(currentRegistryProcessors);
            invokeBeanDefinitionRegistryPostProcessors(currentRegistryProcessors, registry);
            currentRegistryProcessors.clear();
        }
        invokeBeanFactoryPostProcessors((Collection)registryProcessors, (ConfigurableListableBeanFactory)beanFactory);
        invokeBeanFactoryPostProcessors((Collection)regularPostProcessors, (ConfigurableListableBeanFactory)beanFactory);
    } else {
        invokeBeanFactoryPostProcessors((Collection)beanFactoryPostProcessors, (ConfigurableListableBeanFactory)beanFactory);
    }
    String[] postProcessorNames = beanFactory.getBeanNamesForType(BeanFactoryPostProcessor.class, true, false);
    List<BeanFactoryPostProcessor> priorityOrderedPostProcessors = new ArrayList();
    List<String> orderedPostProcessorNames = new ArrayList();
    currentRegistryProcessors = new ArrayList();
    postProcessorNames = postProcessorNames;
    int var22 = postProcessorNames.length;
    String ppName;
    for(var9 = 0; var9 < var22; ++var9) {
        ppName = postProcessorNames[var9];
        if (!processedBeans.contains(ppName)) {
            if (beanFactory.isTypeMatch(ppName, PriorityOrdered.class)) {
                priorityOrderedPostProcessors.add(beanFactory.getBean(ppName, BeanFactoryPostProcessor.class));
            } else if (beanFactory.isTypeMatch(ppName, Ordered.class)) {
                orderedPostProcessorNames.add(ppName);
            } else {
                currentRegistryProcessors.add(ppName);
            }
        }
    }
    sortPostProcessors(priorityOrderedPostProcessors, beanFactory);
    invokeBeanFactoryPostProcessors((Collection)priorityOrderedPostProcessors, (ConfigurableListableBeanFactory)beanFactory);
    List<BeanFactoryPostProcessor> orderedPostProcessors = new ArrayList();
    Iterator var23 = orderedPostProcessorNames.iterator();
    while(var23.hasNext()) {
        String postProcessorName = (String)var23.next();
        orderedPostProcessors.add(beanFactory.getBean(postProcessorName, BeanFactoryPostProcessor.class));
    }
    sortPostProcessors(orderedPostProcessors, beanFactory);
    invokeBeanFactoryPostProcessors((Collection)orderedPostProcessors, (ConfigurableListableBeanFactory)beanFactory);
    List<BeanFactoryPostProcessor> nonOrderedPostProcessors = new ArrayList();
    Iterator var26 = currentRegistryProcessors.iterator();
    while(var26.hasNext()) {
        ppName = (String)var26.next();
        nonOrderedPostProcessors.add(beanFactory.getBean(ppName, BeanFactoryPostProcessor.class));
    }
    invokeBeanFactoryPostProcessors((Collection)nonOrderedPostProcessors, (ConfigurableListableBeanFactory)beanFactory);
    beanFactory.clearMetadataCache();
}
```

registerBeanPostProcessors(beanFactory);//注册BeanPostProcessors（注册Bean的后置处理器）

```java
protected void registerBeanPostProcessors(ConfigurableListableBeanFactory beanFactory) {
    PostProcessorRegistrationDelegate.registerBeanPostProcessors(beanFactory, this);
}

public static void registerBeanPostProcessors(ConfigurableListableBeanFactory beanFactory, AbstractApplicationContext applicationContext) {
    String[] postProcessorNames = beanFactory.getBeanNamesForType(BeanPostProcessor.class, true, false);
    int beanProcessorTargetCount = beanFactory.getBeanPostProcessorCount() + 1 + postProcessorNames.length;
    beanFactory.addBeanPostProcessor(new PostProcessorRegistrationDelegate.BeanPostProcessorChecker(beanFactory, beanProcessorTargetCount));
    List<BeanPostProcessor> priorityOrderedPostProcessors = new ArrayList();
    List<BeanPostProcessor> internalPostProcessors = new ArrayList();
    List<String> orderedPostProcessorNames = new ArrayList();
    List<String> nonOrderedPostProcessorNames = new ArrayList();
    String[] var8 = postProcessorNames;
    int var9 = postProcessorNames.length;
    String ppName;
    BeanPostProcessor pp;
    for(int var10 = 0; var10 < var9; ++var10) {
        ppName = var8[var10];
        if (beanFactory.isTypeMatch(ppName, PriorityOrdered.class)) {
            pp = (BeanPostProcessor)beanFactory.getBean(ppName, BeanPostProcessor.class);
            priorityOrderedPostProcessors.add(pp);
            if (pp instanceof MergedBeanDefinitionPostProcessor) {
                internalPostProcessors.add(pp);
            }
        } else if (beanFactory.isTypeMatch(ppName, Ordered.class)) {
            orderedPostProcessorNames.add(ppName);
        } else {
            nonOrderedPostProcessorNames.add(ppName);
        }
    }
    sortPostProcessors(priorityOrderedPostProcessors, beanFactory);
    registerBeanPostProcessors(beanFactory, (List)priorityOrderedPostProcessors);
    List<BeanPostProcessor> orderedPostProcessors = new ArrayList();
    Iterator var14 = orderedPostProcessorNames.iterator();
    while(var14.hasNext()) {
        String ppName = (String)var14.next();
        BeanPostProcessor pp = (BeanPostProcessor)beanFactory.getBean(ppName, BeanPostProcessor.class);
        orderedPostProcessors.add(pp);
        if (pp instanceof MergedBeanDefinitionPostProcessor) {
            internalPostProcessors.add(pp);
        }
    }
    sortPostProcessors(orderedPostProcessors, beanFactory);
    registerBeanPostProcessors(beanFactory, (List)orderedPostProcessors);
    List<BeanPostProcessor> nonOrderedPostProcessors = new ArrayList();
    Iterator var17 = nonOrderedPostProcessorNames.iterator();
    while(var17.hasNext()) {
        ppName = (String)var17.next();
        pp = (BeanPostProcessor)beanFactory.getBean(ppName, BeanPostProcessor.class);
        nonOrderedPostProcessors.add(pp);
        if (pp instanceof MergedBeanDefinitionPostProcessor) {
            internalPostProcessors.add(pp);
        }
    }
    registerBeanPostProcessors(beanFactory, (List)nonOrderedPostProcessors);
    sortPostProcessors(internalPostProcessors, beanFactory);
    registerBeanPostProcessors(beanFactory, (List)internalPostProcessors);
    beanFactory.addBeanPostProcessor(new ApplicationListenerDetector(applicationContext));
}
```

initMessageSource();//初始化MessageSource组件(做国际化功能;消息绑定，消息解析)

```java
protected void initMessageSource() {
    ConfigurableListableBeanFactory beanFactory = this.getBeanFactory();
    if (beanFactory.containsLocalBean("messageSource")) {
        this.messageSource = (MessageSource)beanFactory.getBean("messageSource", MessageSource.class);
        if (this.parent != null && this.messageSource instanceof HierarchicalMessageSource) {
            HierarchicalMessageSource hms = (HierarchicalMessageSource)this.messageSource;
            if (hms.getParentMessageSource() == null) {
                hms.setParentMessageSource(this.getInternalParentMessageSource());
            }
        }
        if (this.logger.isDebugEnabled()) {
            this.logger.debug("Using MessageSource [" + this.messageSource + "]");
        }
    } else {
        DelegatingMessageSource dms = new DelegatingMessageSource();
        dms.setParentMessageSource(this.getInternalParentMessageSource());
        this.messageSource = dms;
        beanFactory.registerSingleton("messageSource", this.messageSource);
        if (this.logger.isDebugEnabled()) {
            this.logger.debug("Unable to locate MessageSource with name 'messageSource': using default [" + this.messageSource + "]");
        }
    }
}
```

initApplicationEventMulticaster();//初始化事件派发器

```java
protected void initApplicationEventMulticaster() {
    ConfigurableListableBeanFactory beanFactory = this.getBeanFactory();
    if (beanFactory.containsLocalBean("applicationEventMulticaster")) {
        this.applicationEventMulticaster = (ApplicationEventMulticaster)beanFactory.getBean("applicationEventMulticaster", ApplicationEventMulticaster.class);
        if (this.logger.isDebugEnabled()) {
            this.logger.debug("Using ApplicationEventMulticaster [" + this.applicationEventMulticaster + "]");
        }
    } else {
        this.applicationEventMulticaster = new SimpleApplicationEventMulticaster(beanFactory);
        beanFactory.registerSingleton("applicationEventMulticaster", this.applicationEventMulticaster);
        if (this.logger.isDebugEnabled()) {
            this.logger.debug("Unable to locate ApplicationEventMulticaster with name 'applicationEventMulticaster': using default [" + this.applicationEventMulticaster + "]");
        }
    }
}
```

registerListeners();//给容器中将所有项目里面的ApplicationListener注册进来

```java
protected void registerListeners() {
    Iterator var1 = this.getApplicationListeners().iterator();
    while(var1.hasNext()) {
        ApplicationListener<?> listener = (ApplicationListener)var1.next();
        this.getApplicationEventMulticaster().addApplicationListener(listener);
    }
    String[] listenerBeanNames = this.getBeanNamesForType(ApplicationListener.class, true, false);
    String[] var7 = listenerBeanNames;
    int var3 = listenerBeanNames.length;
    for(int var4 = 0; var4 < var3; ++var4) {
        String listenerBeanName = var7[var4];
        this.getApplicationEventMulticaster().addApplicationListenerBean(listenerBeanName);
    }
    Set<ApplicationEvent> earlyEventsToProcess = this.earlyApplicationEvents;
    this.earlyApplicationEvents = null;
    if (earlyEventsToProcess != null) {
        Iterator var9 = earlyEventsToProcess.iterator();
        while(var9.hasNext()) {
            ApplicationEvent earlyEvent = (ApplicationEvent)var9.next();
            this.getApplicationEventMulticaster().multicastEvent(earlyEvent);
        }
    }
}
```

finishBeanFactoryInitialization(beanFactory);//初始化()实例化所有剩下的单实例bean

```java
protected void finishBeanFactoryInitialization(ConfigurableListableBeanFactory beanFactory) {
    if (beanFactory.containsBean("conversionService") && beanFactory.isTypeMatch("conversionService", ConversionService.class)) {
        beanFactory.setConversionService((ConversionService)beanFactory.getBean("conversionService", ConversionService.class));
    }
    if (!beanFactory.hasEmbeddedValueResolver()) {
        beanFactory.addEmbeddedValueResolver(new StringValueResolver() {
            public String resolveStringValue(String strVal) {
                return AbstractApplicationContext.this.getEnvironment().resolvePlaceholders(strVal);
            }
        });
    }
    String[] weaverAwareNames = beanFactory.getBeanNamesForType(LoadTimeWeaverAware.class, false, false);
    String[] var3 = weaverAwareNames;
    int var4 = weaverAwareNames.length;
    for(int var5 = 0; var5 < var4; ++var5) {
        String weaverAwareName = var3[var5];
        this.getBean(weaverAwareName);
    }
    beanFactory.setTempClassLoader((ClassLoader)null);
    beanFactory.freezeConfiguration();
    beanFactory.preInstantiateSingletons();
}
```

finishRefresh();//完成BeanFactory的初始化创建工作。IOC容器就创建完成

```java
protected void finishRefresh() {
    this.initLifecycleProcessor();
    this.getLifecycleProcessor().onRefresh();
    this.publishEvent((ApplicationEvent)(new ContextRefreshedEvent(this)));
    LiveBeansView.registerApplicationContext(this);
}
```



### 2. 原理

**Spring容器的refresh()【创建刷新】**

1. prepareRefresh(); 刷新前的预处理

   1. initPropertySources(); 初始化一些属性设置；子类自定义个性化的属性设置方法;
   2. getEnvironment().validateRequiredProperties();//属性校验
   3. earlyApplicationEvents = new LinkedHashSet();//保存容器中的一些早期的事件

2. obtainFreshBeanFactory();//获取BeanFactory

   1. refreshBeanFactory(); 刷新【创建】BeanFactory。
      1. 核心工作是创建了一个默认的beanFactory ：this. beanFactory = new DefaultListableBeanFactory();
      2. this. beanFactory.setSerializationId(getId()); 设置了序列化ID

   2. getBeanFactory() 返回刚才ConfigurableListableBeanFactory创建的BeanFactory对象。
   3. 将创建的BeanFactory【DefaultListableBeanFactory】返回;

3. prepareBeanFactory(beanFactory);//BeanFactory的预处理设置（beanFactory进行一些设置）

   1. 设置BeanFactory的类加载器、支持表达式解析器....
   2. 添加部分BeanPostProcessor 【ApplicationContextAwareProcessor】 
   3. 设置忽略的自动装配的接口Envi ronmentAware、EmbeddedValueResolverAware、XXX;【目的是使这些类的实现类不能通过接口注入】
   4. 注册可以解析的自动装配;我们能直接在任何组件中自动注入: BeanFactory、 ResourceLoader、ApplicationEventPublisher、ApplicationContext。
   5. 添加BeanPostProcessor 【ApplicationListenerDetector】
   6. 添加编译时的AspectJ;
   7. 给BeanFactory中注册一些能用的组件：environment【ConfigurableEnvironment】、systemProperties【Map<String, Object>】 、systemEnvironment【Map<String, 0bject>】

4. postProcessBeanFactory(beanFactory); //BeanFactory准备工作完成后进行的后置处理工作；

   - 子类通过重写这个方法来在BeanFactory创建并预准备完成以后做进一步的设置

5. invokeBeanFactoryPostProcessors(beanFactory);//执行BeanFactoryPostProcessor的方法。而BeanFactoryPostProcessor是BeanFactory的后置处理器。在BeanFactory标准初始化之后执行的。BeanFactoryPostProcessor有两个接口: BeanFactoryPostProcessor 、BeanDefinitionRegistryPostProcessor（子接口，给容器中额外添加组件）

   -  执行BeanFactoryPostProcessor的方法：

      1. 先执行BeanDefinitionRegistryPostProcessor
         1. 获取所有的BeanDefinitionRegistryPostProcessor
         2. 看先执行实现了PriorityOrdered优先级接口的BeanDefinitionRegistryPostProcessor。如果找到执行postProcessor.postProcessBeanDefinitionRegistry(registry);
         3. 再执行实现了Ordered顺序/优先级级接口的BeanDefinitionRegistryPostProcessor。如果找到执行postProcessor.postProcessBeanDefinitionRegistry(registry);
         4. 最后执行没有实现任何优先级或者是顺序接口的BeanDefinitionRegistryPostProcessors。如果找到执行postProcessor.postProcessBeanDefinitionRegistry(registry);

      2. 再执行BeanFactoryPostProcessor方法。
         1. 获取所有的BeanFactoryPostProcessor组件
         2. 看先执行实现了PriorityOrdered优先级接口的BeanFactoryPostProcessor。如果找到执行postProcessor.postProcessBeanFactory(beanFactory);
         3. 再执行实现了Ordered顺序/优先级级接口的BeanFactoryPostProcessor。如果找到执行postProcessor.postProcessBeanFactory(beanFactory);
         4. 最后执行没有实现任何优先级或者是顺序接口的BeanFactoryPostProcessor。如果找到执行postProcessor.postProcessBeanFactory(beanFactory);

6. registerBeanPostProcessors(beanFactory);//注册BeanPostProcessors（注册Bean的后置处理器）【作用：拦截Bean的创建过程】【接口：BeanPostProcessor、DestructionAwareBeanPostProcessor、InstantiationAwareBeanPostProcessor、 SmartInstantiationAwareBeanPostProcessor、MergedBeanDefinitionPostProcessor（internalPostProcessors）】（不同接口类型的BeanPostProcessor;在Bean创建前后的执行时机是不一样的）

   1. 获取所有的BeanPostProcessor ;后置处理器都默认可以通过PriorityOrdered、Ordered接口来指定优先级
   2. 先注册PriorityOrdered优先级接口的BeanPostProcessor
      - 调用registerBeanPostProcessors()来注册BeanPostProcessors
        - 实际上就是把每一个BeanPostProcessor 添加到BeanFactory中：beanFactory.addBeanPostProcessor( postProcessor)

   3. 再注册Ordered顺序接口的BeanPostProcessor
   4. 再注册没有实现任何优先级或顺序接口的BeanPostProcessor
   5. 最终注册MergedBeanDefinitionPostProcessor
   6. 还注册了ApplicationListenerDetector。来在Bean创建完成后检查是否是ApplicationListener，如果是，就放在容器中保存起来applicationContext.addApplicationListener( ( ApplicationListener<?> ) bean )

7. initMessageSource();//初始化MessageSource组件(做国际化功能;消息绑定，消息解析)

   1. 获取BeanFactory
   2. 看容器中是否有id为messageSource的组件
      - 如果有赋值给messageSource,如果没有自己创建一个DelegatingMessageSource。MessageSource:取出国际化配置文件中的某个key的值;能按照区域信息获取;

   3. 把创建好的MessageSource注册在容器中;以后获取国际化配置文件的值的时候，可以自动注入MessageSource
      1. beanFactory.registersingleton(MESSAGE_SOURCE_BEAN_ NAME, this.messageSource)。
      2. 以后获取国际化配置文件的值的时候,来调用MessageSource.getMessage(String code, Object[] args, string defaultMessage, Locale. locale)

8. initApplicationEventMulticaster();//初始化事件派发器

   1. 获取BeanFactory
   2. 从BeanFactory中获取applicationEventMulticaster的ApplicationEventMulticaster【自己配置的事件派发器】
   3. 如果上一步没有配置;创建一个SimpleApplicationEventMulticaster
   4. 将创建的ApplicationEventMulticaster添加到BeanFactory中，以后其他组件直接自动注入

9. onRefresh();//留给子容器（子类 ）子类可以重写这个方法，在容器刷新的时候可以自定义逻辑;

10. registerListeners();//给容器中将所有项目里面的ApplicationListener注册进来

   1. 从容器中拿到所有的ApplicationListener
   2. 将每个监听器添加到事件派发器中;
      - getApplicationEventMulticaster(). addApplicationListenerBean(listenerBeanName)

   3. 派发之前步骤产生的事件

11. finishBeanFactoryInitialization(beanFactory);//初始化(实例化)所有剩下的单实例bean【这里应该说完成bean工厂初始化，实例化bean比较准确】【Instantiate实例化,Initiallize初始化】【bean的定义信息在	ConfigurableListableBeanFactory beanFactory = obtainFreshBeanFactory();创建工厂刷新的时候处理的】

    1. beanFactory.preInstantiateSingletons();实例化后剩下的单实例bean

       1. 获取容器中的所有Bean,依次进行初始化和创建对象

       2. 获取Bean的定义信息。RootBeanDefinition

       3. 如果Bean不是抽象的&&是单实例的&&不是懒加载;

          1. 判断是否是FactoryBean;是否是实现FactoryBean接口的Bean
          2. 如果不是工厂Bean。利用getBean( beanName) ;创建对象
             1. getBean( beanName) / ioc.getBean( ) --> doGetBean(name, null, null false)
             2. 先获取缓存中保存的单实例Bean。如果能获取到说明这个Bean之前被创建过(所有创建过的单实例Bean都会缓存起来。
                - 从Map<String, Object> singletonObjects = new ConcurrentHashMap<String, Object>(256) 获取。【singletonObjects 就是用来保存所有但单实例Bean的】

          3. 缓存中获取不到，开始Bean的创建对象流程;

          4. 标记当前bean已经被创建【多线程时】

          5. 获取Bean的定义信息

          6. 获取当前Bean依赖的其他Bean ;如果有按照getBean( )把依赖的Bean先创建出来

          7. 启动单实例Bean的创建流程

             1. createBean( beanName, mbd, args )
             2. Object bean = resolveBeforeInstantiation( beanName, mbdToUse ) 让BeanPostProcessor先拦截返回代理对象【注意：这里实际上不能产生代理对象】
                1. InstantiationAwareBeanPostProcessor:提前执行
                2. 先触发: postProcessBeforeInstantiation( )。如果有返回值，触发postProcessAfterInitialization()

             3. 如果前面的InstantiationAwareBeanPostProcessor没有返回代理对象，就调用下边创建Bean的方法

                1. 【创建Bean】object beanInstance = doCreateBean( beanName, mbdToUse, args)

                   1. 【创建Bean实例】; createBeanInstance( beanName, mbd, args )

                      - 利用工厂方法或者对象的构造器创建出Bean实例

                   2. applyMergedBeanDefinitionPostProcessors (mbd, beanType, beanName )。

                      - 调用MergedBeanDefinitionPostProcessor的bdp. postProcessMergedBeanDefinition(mbd, beanType, beanName)

                   3. 【Bean属性赋值】populateBean( beanName, mbd, instanceWrapper )

                      1. 赋值之前
                         1. 拿到InstantiationAwareBeanPostProcessor后置处理器，来执行postProcessAfterInstantiation()方法
                         2. 拿到InstantiationAwareBeanPostProcessor后置处理器，来执行postProcessPropertyValues()方法

                      2. 赋值。应用Bean属性的值;为属性利用setter方法等进行赋值;
                         - applyPropertyValues (beanName, mbd, bw, pvs)

                   4. 【Bean初始化】initializeBean(beanName, exposedobject, mbd)
                      1. 【执行Aware接口的方法】invokeAwareMethods ( beanName, bean) ;执行xxxAware接口的方法。
                         - BeanNameAware \BeanClassLoaderAware \BeanFactoryAware
                      2. 【执行后置处理器初始化之前的方法】applyBeanPostProcessorsBeforeInitialization(wrappedBean, beanName )
                         - BeanPostProcessor. postProcessBeforeInitialization()
                      3. 【执行初始化方法】 invokeInitMethods (beanName, wrappedBean, mbd)
                         1. 是否是InitializingBean接口的实现;执行接口规定的初始化;
                         2. 是否自定义初始化方法
                      4. 【执行后置处理器初始化之后的方法】applyBeanPostProcessorsAfterInitialization(wrappedBean, beanName )
                         - BeanPostProcessor. postProcessAfterInitialization()

                   5. 注册Bean的销毁方法;

             4. 将创建的Bean添加到缓存中 singletonObjects;

          8. ioc容器就是这些Map;很多的Map里面保存了单实例Bean,环境信息....

    2. 所有Bean都利用getBean创建完成以后;
       - 检查所有的Bean是否是SmartInitializingsingleton接口的;如果是;就执行afterSingletonsInstantiated( )；

12. finishRefresh();//完成BeanFactory的初始化创建工作。IOC容器就创建完成

    1. initLifecycleProcessor( ) ;初始化和生命周期有关的后置处理器;

       1. 默认从容器中找是否有lifecycleProcessor的组件【LifecycleProcessor】，
          - 可以写一个LifecycleProcessor的实现类，在BeanFactory的生命周期中的。
            1. onRefresh( ) 刷新完成
            2. onClose( ) 关闭的时候通过重写这两个方法进行一些调用

       2. 如果没有，new DefaultLifecycleProcessor( )。
       3. 注册在容器中

    2. getLifecycleProcessor( ) . onRefresh( )。拿到前面定义的生命周期处理器（BeanFactory）；回调onRefresh( )
    3. publishEvent (new ContextRefreshedEvent(this)) ;发布容器刷新完成事件;
    4. LiveBeansView.registerApplicationContext(this);



### 3. 总结

1. Spring容器在启动的时候，先会保存所有注册进来的Bean的定义信息; 
   1. xml注册bean; <bean>
   2. 注解注册Bean; @Service、 @Component、@Bean、等等
2. Spring容器会合适的时机创建这些Bean
   1. 用到这个bean的时候;利用getBean创建bean;创建好以后保存在容器中;
   2. 统一创建剩下所有的bean的时候; finishBeanF actoryInitialization( )
3. 后置处理器; 
   - 每一个bean创建完成，都会使用各种后置处理器进行处理;来增强bean的功能;
     1. AutowiredAnnotationBeanPostProcessor:处理自动注入
     2. AnnotationAwareAspectJAutoProxyCreator :给Bean 创建代理对象，来做AOP功能;
     3. 增强的功能注解：AsyncAnnotationBeanPostProcessor、
4. 事件驱动模型;
   1. ApplicationListener;事件监听;
   2. ApplicationEventMulticaster;事件派发；





## 9. Web





## 10. 异步请求

![](https://cdn.nlark.com/yuque/0/2021/png/1485212/1635854309628-7c37ab0c-3968-4a61-a705-1f048c9a9028.png?x-oss-process=image%2Fresize%2Cw_966%2Climit_0)





是主线程告诉副线程，我先去忙别的了，你执行好了叫我顺便把结果给我，我或者我的一个兄弟再拿着结果去响应数据

![](https://gitlab.com/eardh/picture/-/raw/main/test/202205252142931.png)









