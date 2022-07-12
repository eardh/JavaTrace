# Linux后篇

## 1. Shell 编程

### 1. 概念

`Shell` 是一个命令行解释器，它为用户提供了一个向 Linux 内核发送请求以便运行程序的界面系统级程序，用户可以用 Shell 来启动、挂起、停止甚至是编写一些程序

**作用**：

1. Linux 运维工程师在进行服务器集群管理时，需要编写 Shell 程序来进行服务器管理。
2. 对于 JavaEE 和 Python 程序员来说，工作的需要，你的老大会要求你编写一些 Shell 脚本进行程序或者是服务器的维护，比如编写一个定时备份数据库的脚本。
3. 对于大数据程序员来说，需要编写 Shell 程序来管理集群

**Shell 脚本的执行方式**：

1. 脚本格式要求

   - 脚本以`#!/bin/bash` 开头
   - 脚本需要有可执行权限

2. 编写第一个 Shell 脚本

   ```sh
   vim hello.sh
   ```

   ```shell
   #!/bin/bash
   echo "hello,world"
   ```

3. 脚本的常用执行方式

   1. 方式 1(输入脚本的绝对路径或相对路径)

      说明：首先要赋予 helloworld.sh 脚本的`+x` 权限， 输入脚本相对路径或者使用绝对路径

      ```sh
      shell文件路径
      ```

   2. 方式 2(sh+脚本)

      说明：不用赋予脚本+x 权限，直接执行即可。

      ```sh
      sh shell文件路径
      ```

      



### 2. 语法基础

#### 1. 变量

##### 1. Shell 变量

1. Linux Shell 中的变量分为，`系统变量`和`用户自定义变量`。
2. 系统变量：`$HOME`、`$PWD`、`$SHELL`、`$USER` 等等，比如： echo $HOME    等等
3. 显示当前 shell 中所有变量：`set`

**1. shell 变量使用**

1. 基本语法

   1. 定义变量：`变量名=值`
   2. 撤销变量：`unset 变量`
   3. 声明静态变量：`readonly 变量`，注意：不能 unset

2. 定义变量的规则

   1. 命名只能使用英文字母，数字和下划线，首个字符不能以数字开头
   2. 中间不能有空格，可以使用下划线 **`_`**
   3. 不能使用标点符号
   4. 不能使用bash里的关键字（可用help命令查看保留关键字）

3. 使用变量

   1. 使用一个定义过的变量，只要在变量名前面加美元符号即可

      ```sh
      $变量名
      ```

   2. 变量名外面的花括号是可选的，加不加都行，加花括号是为了帮助解释器识别变量的边界

      ```sh
      ${变量名}
      ```

4. 将命令的返回值赋给变量

   1.  A=\`date\`反引号，运行里面的命令，并把结果返回给变量 A
   2. A=$(date) 等价于反引

**2. 设置环境变量**

1.  将 shell 变量输出为环境变量/全局变量

   ```shell
   export 变量名=变量值
   ```

2. 让修改后的配置信息立即生效

   ```sh
   source  配置文件
   ```

3. 查询环境变量的值

   ```sh
   echo $变量名
   ```

**3. 位置参数变量**

当我们执行一个 shell 脚本时，如果希望获取到命令行的参数信息，就可以使用到位置参数变量。

比如 ：`./myshell.sh 100 200`, 这个就是一个执行 shell 的命令行，可以在 myshell  脚本中获取到参数信息。

基本语法：

- `$n` ：n 为数字，$0 代表命令本身，$1-$9 代表第一到第九个参数，10以上的参数需要用大括号包含，如${10}
- `$*` ：这个变量代表命令行中所有的参数，$*把所有的参数看成一个整体
- `$@`：这个变量也代表命令行中所有的参数，不过$@把每个参数区分对待
- `$#`：这个变量代表命令行中所有参数的个数

**3. 预定义变量**

就是 shell 设计者事先已经定义好的变量，可以直接在 shell 脚本中使用

基本语法 ：

- `$$`：当前进程的进程号（PID）

- `$!`：后台运行的最后一个进程的进程号（PID）

- `$?`：最后一次执行的命令的返回状态。如果这个变量的值为 0，证明上一个命令正确执行；如果这个变量的值为非 0（具体是哪个数，由命令自己来决定），则证明上一个命令执行不正确了。

  ```shell
  #!/bin/bash
  echo "当前执行的进程id=$$"
  
  #以后台的方式运行一个脚本，并获取它的进程号
  /bin/bash.sh &
  echo "最后一个后台运行的进程id=$!"
  echo "执行返回的状态=$?"
  ```

**4. shell注释**

1. 单行注释：`#`

2. 多行注释

    ```shell
    :<<EOF
    注释内容...
    注释内容...
    注释内容...
    EOF
    ```

   `EOF`可以替换为`!`，`'`等等，只是定义注释结束符



##### 2. 字符串

字符串是shell编程中最常用最有用的数据类型（除了数字和字符串，也没啥其它类型好用了），字符串可以用单引号，也可以用双引号，也可以不用引号

1. 表示方法

   1. 单引号：
      - 单引号里的任何字符都会原样输出，单引号字符串中的变量是无效的；
      - 单引号字串中不能出现单独一个的单引号（对单引号使用转义符后也不行），但可成对出现，作为字符串拼接使用。
   2. 双引号：
      - 双引号里可以有变量
      - 双引号里可以出现转义字符
   3. 不被引号包围的字符串
      - 不被引号包围的字符串中出现变量时也会被解析，这一点和双引号`""`包围的字符串一样。
      - 字符串中不能出现空格，否则空格后边的字符串会作为其他变量或者命令解析。

2. 拼接字符串：

   - 双引号包裹：可以存在空格
   - 不被双引号包裹：不允许出现空格

3. 获取字符串长度

   ```sh
   ${#string}
   ```

4. 提取子字符串

   | 格式                       | 说明                                                         |
   | -------------------------- | ------------------------------------------------------------ |
   | ${string: start :length}   | 从 string 字符串的左边第 start 个字符开始，向右截取 length 个字符。 |
   | ${string: start}           | 从 string 字符串的左边第 start 个字符开始截取，直到最后。    |
   | ${string: 0-start :length} | 从 string 字符串的右边第 start 个字符开始，向右截取 length 个字符。 |
   | ${string: 0-start}         | 从 string 字符串的右边第 start 个字符开始截取，直到最后。    |
   | ${string#*chars}           | 从 string 字符串第一次出现 *chars 的位置开始，截取 *chars 右边的所有字符。 |
   | ${string##*chars}          | 从 string 字符串最后一次出现 *chars 的位置开始，截取 *chars 右边的所有字符。 |
   | ${string%*chars}           | 从 string 字符串第一次出现 *chars 的位置开始，截取 *chars 左边的所有字符。 |
   | ${string%%*chars}          | 从 string 字符串最后一次出现 *chars 的位置开始，截取 *chars 左边的所有字符。 |



##### 3. 数组

bash支持一维数组（不支持多维数组），并且没有限定数组的大小。

类似于 C 语言，数组元素的下标由 0 开始编号。获取数组中的元素要利用下标，下标可以是整数或算术表达式，其值应大于或等于 0。

1. 定义数组

   ```shell
   数组名=(值1 值2 ... 值n)
   ```

2. 读取数组

   1. 获取数组元素的值

      ```shell
      ${array_name[index]}
      ```

   2. 获取数组中的所有元素

      ```shell
      ${nums[*]}
      ${nums[@]}
      ```

3. 获取数组长度

   ```shell
   ${#array_name[@]}
   ${#array_name[*]}
   ```

4. 数组拼接

   ```shell
   array_new=(${array1[@]}  ${array2[@]})
   array_new=(${array1[*]}  ${array2[*]})
   ```

5. 删除数组元素

   1. 删除数组元素

      ```shell
      unset array_name[index]
      ```

   2. 删除整个数组

      ```sh
      unset array_name
      ```



#### 2. 运算符

**Shell中的数学计算方式**：

| 运算操作符/运算命令 | 说明                                                         |
| ------------------- | ------------------------------------------------------------ |
| `(( ))`             | 用于整数运算，效率很高，**推荐使用**。                       |
| `let`               | 用于整数运算，和 (()) 类似。                                 |
| `$[]`               | 用于整数运算，不如 (()) 灵活。                               |
| `expr`              | 可用于整数运算，也可以处理字符串。要用``包裹。比较麻烦，需要注意各种细节，不推荐使用。 |
| `bc`                | Linux下的一个计算器程序，可以处理整数和小数。Shell 本身只支持整数运算，想计算小数就得使用 bc 这个外部的计算器。 |
| `declare -i`        | 将变量定义为整数，然后再进行数学运算时就不会被当做字符串了。功能有限，仅支持最基本的数学运算（加减乘除和取余），不支持逻辑运算、自增自减等，所以在实际开发中很少使用。 |

**算数运算符**：

| 运算符 | 说明                                          | 举例                            |
| :----- | :-------------------------------------------- | :------------------------------ |
| +      | 加法                                          | \`expr $a + $b\` 结果为 30。    |
| -      | 减法                                          | \`expr $a - $b\` 结果为 -10。   |
| *      | 乘法                                          | \`expr $a \* $b\` 结果为  200。 |
| /      | 除法                                          | \`expr $b / $a\` 结果为 2。     |
| %      | 取余                                          | \`expr $b % $a\` 结果为 0。     |
| =      | 赋值                                          | a=$b 把变量 b 的值赋给 a。      |
| ==     | 相等。用于比较两个数字，相同则返回 true。     | [ $a == $b ] 返回 false。       |
| !=     | 不相等。用于比较两个数字，不相同则返回 true。 | [ $a != $b ] 返回 true。        |

**关系运算符**：

| 运算符 | 说明                                                  | 举例                       |
| :----- | :---------------------------------------------------- | :------------------------- |
| -eq    | 检测两个数是否相等，相等返回 true。                   | [ $a -eq $b ] 返回 false。 |
| -ne    | 检测两个数是否不相等，不相等返回 true。               | [ $a -ne $b ] 返回 true。  |
| -gt    | 检测左边的数是否大于右边的，如果是，则返回 true。     | [ $a -gt $b ] 返回 false。 |
| -lt    | 检测左边的数是否小于右边的，如果是，则返回 true。     | [ $a -lt $b ] 返回 true。  |
| -ge    | 检测左边的数是否大于等于右边的，如果是，则返回 true。 | [ $a -ge $b ] 返回 false。 |
| -le    | 检测左边的数是否小于等于右边的，如果是，则返回 true。 | [ $a -le $b ] 返回 true。  |

**布尔运算符**：

| 运算符 | 说明                                                | 举例                                     |
| :----- | :-------------------------------------------------- | :--------------------------------------- |
| !      | 非运算，表达式为 true 则返回 false，否则返回 true。 | [ ! false ] 返回 true。                  |
| -o     | 或运算，有一个表达式为 true 则返回 true。           | [ $a -lt 20 -o $b -gt 100 ] 返回 true。  |
| -a     | 与运算，两个表达式都为 true 才返回 true。           | [ $a -lt 20 -a $b -gt 100 ] 返回 false。 |

**逻辑运算符**：

| 运算符 | 说明       | 举例                                       |
| :----- | :--------- | :----------------------------------------- |
| &&     | 逻辑的 AND | [[ $a -lt 100 && $b -gt 100 ]] 返回 false  |
| \|\|   | 逻辑的 OR  | [[ $a -lt 100 \|\| $b -gt 100 ]] 返回 true |

**字符串运算符**：

| 运算符 | 说明                                         | 举例                     |
| :----- | :------------------------------------------- | :----------------------- |
| =      | 检测两个字符串是否相等，相等返回 true。      | [ $a = $b ] 返回 false。 |
| !=     | 检测两个字符串是否不相等，不相等返回 true。  | [ $a != $b ] 返回 true。 |
| -z     | 检测字符串长度是否为0，为0返回 true。        | [ -z $a ] 返回 false。   |
| -n     | 检测字符串长度是否不为 0，不为 0 返回 true。 | [ -n "$a" ] 返回 true。  |
| $      | 检测字符串是否不为空，不为空返回 true。      | [ $a ] 返回 true。       |

**文件测试运算符**：

| 操作符  | 说明                                                         | 举例                      |
| :------ | :----------------------------------------------------------- | :------------------------ |
| -b file | 检测文件是否是块设备文件，如果是，则返回 true。              | [ -b $file ] 返回 false。 |
| -c file | 检测文件是否是字符设备文件，如果是，则返回 true。            | [ -c $file ] 返回 false。 |
| -d file | 检测文件是否是目录，如果是，则返回 true。                    | [ -d $file ] 返回 false。 |
| -f file | 检测文件是否是普通文件（既不是目录，也不是设备文件），如果是，则返回 true。 | [ -f $file ] 返回 true。  |
| -g file | 检测文件是否设置了 SGID 位，如果是，则返回 true。            | [ -g $file ] 返回 false。 |
| -k file | 检测文件是否设置了粘着位(Sticky Bit)，如果是，则返回 true。  | [ -k $file ] 返回 false。 |
| -p file | 检测文件是否是有名管道，如果是，则返回 true。                | [ -p $file ] 返回 false。 |
| -u file | 检测文件是否设置了 SUID 位，如果是，则返回 true。            | [ -u $file ] 返回 false。 |
| -r file | 检测文件是否可读，如果是，则返回 true。                      | [ -r $file ] 返回 true。  |
| -w file | 检测文件是否可写，如果是，则返回 true。                      | [ -w $file ] 返回 true。  |
| -x file | 检测文件是否可执行，如果是，则返回 true。                    | [ -x $file ] 返回 true。  |
| -s file | 检测文件是否为空（文件大小是否大于0），不为空返回 true。     | [ -s $file ] 返回 true。  |
| -e file | 检测文件（包括目录）是否存在，如果是，则返回 true。          | [ -e $file ] 返回 true。  |

其他检查符：

- **`-S`**: 判断某文件是否 socket。
- **`-L`**: 检测文件是否存在并且是一个符号链接。



#### 3. 流程控制

##### 1. if 语句

**1. if else fi**

```shell
if condition;
then
    command1
fi
```

**2. if else**

```shell
if condition
then
    command1 
else
    command
fi
```

**3. if else-if else**

```shell
if condition1
then
    command1
elif condition2 
then 
    command2
else
    commandN
fi
```

> condition：
>
> - `[ 条件 ]`：关系运算符用 `-gt` 类
> - `(( 条件 ))`：关系运算符用 `>` 类
>
> ⚠️注意条件与左右的空格



##### 2. case 语句

```shell
case 值 in
值1)
    command
    ;;
值2)
    command1
    ;;
esac
```



##### 3. for 语句

1. ```sh
   for var in item1 item2 ... itemN
   do
       command
   done
   ```

2. ```sh
   for (( 初始值;循环控制条件;变量变化 ))
   do
   	程序/代码
   done
   ```



##### 4. while 语句

```shell
while condition
do
	command
done
```



#### 4. 读取控制台

read 是 Shell 内置命令，用来从标准输入中读取数据并赋值给变量。如果没有进行重定向，默认就是从键盘读取用户输入的数据；如果进行了重定向，那么可以从文件中读取数据。

```sh
read [-options] [variables]
```

选项：

| 选项         | 说明                                                         |
| ------------ | ------------------------------------------------------------ |
| -a array     | 把读取的数据赋值给数组 array，从下标 0 开始。                |
| -d delimiter | 用字符串 delimiter 指定读取结束的位置，而不是一个换行符（读取到的数据不包括 delimiter）。 |
| -e           | 在获取用户输入的时候，对功能键进行编码转换，不会直接显式功能键对应的字符。 |
| -n num       | 读取 num 个字符，而不是整行字符。                            |
| -p prompt    | 显示提示信息，提示内容为 prompt。                            |
| -r           | 原样读取（Raw mode），不把反斜杠字符解释为转义字符。         |
| -s           | 静默模式（Silent mode），不会在屏幕上显示输入的字符。当输入密码和其它确认信息的时候，这是很有必要的。 |
| -t seconds   | 设置超时时间，单位为秒。如果用户没有在指定时间内输入完成，那么 read 将会返回一个非 0 的退出状态，表示读取失败。 |
| -u fd        | 使用文件描述符 fd 作为输入源，而不是标准输入，类似于重定向。 |



#### 5. 函数

##### 1. 系统函数

1. `basename`

   basename 命令会删掉所有的前缀包括最后一个（‘/’）字符，然后将字符串显示出来

   ```sh
   basename [pathname] [suffix]
   ```

   - suffix 为后缀，如果 suffix 被指定了basename 会将 pathname 或 string 中的 suffix 去掉

2. `dirname`

   返回完整路径最后 / 的前面的部分，常用于返回路径部分

   ```shell
   dirname 文件绝对路径
   ```

   从给定的包含绝对路径的文件名中去除文件名（非目录的部分），然后返回剩下的路径（目录的部分））



##### 2. 自定义函数

```shell
[ function ] funname [()]
{
    action;
    [return int;]
}
```

- 可以带function fun() 定义，也可以直接fun() 定义，不带任何参数。
- 参数返回，可以显示加：return 返回，如果不加，将以最后一条命令运行结果，作为返回值。 return后跟数值n(0-255

调用直接写函数名：`funname [值...]`



### 3. 综合案例

需求：

1. 每天凌晨 2:30 备份 数据库 school 到 /tmp/backup/db
2. 备份开始和备份结束能够给出相应的提示信息
3. 备份后的文件要求以备份时间为文件名，并打包成 .tar.gz 的形式，比如：2021-03-12_230201.tar.gz
4. 在备份的同时，检查是否有 10 天前备份的数据库文件，如果有就将其删除

```shell
#备份目录
BACKUP=/tmp/backup/db

#当前时间
DATETIME=$(date +%Y-%m-%d_%H%M%S)
echo $DATETIME

#数据库的地址
HOST=192.168.111.129

#数据库用户名
DB_USER=root

#数据库密码
DB_PW=123456

#备份的数据库名
DATABASE=school

#创建备份目录, 如果不存在，就创建
[ ! -e "${BACKUP}/${DATETIME}" ] && mkdir -p "${BACKUP}/${DATETIME}"

#备份数据库
mysqldump -u${DB_USER} -p${DB_PW} --host=${HOST} -q -R --databases ${DATABASE} | gzip > ${BACKUP}/${DATETIME}/$DATETIME.sql.gz

#将文件处理成 tar.gz
cd ${BACKUP}
tar -zcvf $DATETIME.tar.gz ${DATETIME}

#删除对应的备份目录
rm -rf ${BACKUP}/${DATETIME}

#删除 10 天前的备份文
find ${BACKUP} -ctime +10 -name "*.tar.gz" -exec rm -rf {} \;
echo "备份数据库 ${DATABASE} 成功"
```





## 2. ubuntu - apt命令 

apt 是 Advanced Packaging Tool 的简称，是一款安装包管理工具。在 Ubuntu 下，我们可以使用 apt 命令进行软件包的安装、删除、清理等，类似于 Windows 中的软件管理工具。

1. 更新源

   ```sh
   apt-get update
   ```

2. 安装

   ```sh
   apt-get install package
   ```

3. 删除

   ```sh
   apt-get remove package
   ```

4.  搜索软件包

   ```sh
   apt-get search package
   ```

5. 获取包的相关信息

   ```sh
   apt-get show package
   ```

6. 重新安装包

   ```sh
   apt-get install package --reinstall
   ```

7. 修复安装

   ```sh
   apt-get -f install
   ```

8. 删除包，包括配置文件等

   ```sh
   apt-get remove package --purge
   ```

9. 安装相关的编译环境

   ```sh
   apt-get build-dep package
   ```

10. 更新已安装的包

    ```sh
    apt-get upgrade
    ```

11. 升级系统

    ```sh
    apt-get dist-upgrade
    ```

12. 了解使用该包依赖那些包

    ```sh
    apt-cache depends package
    ```

13. 查看该包被哪些包依赖

    ```sh
    apt-cache rdepends package
    ```

14. 下载包的源代码

    ```sh
    apt-get source package
    ```





## 3. 定制 Linux 系统

通过裁剪现有 Linux 系统(CentOS7)，创建属于自己的 min Linux 小系统，可以加深我们对 linux 的理解。

**1. 基本原理**

制作 Linux 小系统之前，再了解一下 Linux 的启动流程：

1. 首先 Linux 要通过自检，检查硬件设备有没有故障
2. 如果有多块启动盘的话，需要在 BIOS 中选择启动磁盘
3. 启动 MBR 中的 bootloader 引导程序
4. 加载内核文件
5. 执行所有进程的父进程、老祖宗 systemd
6. 欢迎界面

 在 Linux 的启动流程中，加载内核文件时关键文件：

1. `kernel` 文件：vmlinuz-3.10.0-957.el7.x86_64
2. `initrd` 文件：initramfs-3.10.0-957.el7.x86_64.img

**2. 制作 min linux 思路分析**

1. 在现有的 Linux 系统(centos7)上加一块硬盘/dev/sdb，在硬盘上分两个分区，一个是/boot，一个是/，并将其格式化。需要明确的是，现在加的这个硬盘在现有的 Linux 系统中是/dev/sdb，但是，当我们把东西全部设置好时，要把这个硬盘拔除，放在新系统上，此时，就是/dev/sda
2. 在/dev/sdb 硬盘上，将其打造成独立的 Linux 系统，里面的所有文件是需要拷贝进去的
3. 作为能独立运行的 Linux 系统，内核是一定不能少，要把内核文件和 initramfs 文件也一起拷到/dev/sdb 上
4. 以上步骤完成，我们的自制 Linux 就完成, 创建一个新的 linux 虚拟机，将其硬盘指向我们创建的硬盘，启动即可

**3. 操作步骤**

1. 首先，我们在现有的linux添加一块大小为20G的硬盘

2.  添加完成后，点击确定，然后启动现有的linux(centos7)。 通过fdisk来给我们的/dev/sdb进行分区

   ```sh
   fdisk /dev/sdb
   ```

3. 接下来，我们对/dev/sdb的分区进行格式化

   ```sh
   mkfs.ext4 /dev/sdb1
   mkfs.ext4 /dev/sdb2
   ```

4. 创建目录，并挂载新的磁盘

   ```sh
   mkdir -p /mnt/boot /mnt/sysroot
   
   mount /dev/sdb1 /mnt/boot
   mount /dev/sdb2 /mnt/sysroot/
   ```

5. 安装grub, 内核文件拷贝至目标磁盘

   ```sh
   grub2-install --root-directory=/mnt /dev/sdb
   ```

   我们可以来看一下二进制确认我们是否安装成功

   ```sh
   exdump -C -n 512 /dev/sdb
   \cp -rf /boot/* /mnt/boot/
   ```

6. 修改 grub2/grub.cfg 文件, 标红的部分是需要使用指令来查看的

   ```sh
   lsblk -f
   ```

   ```sh
   vim /mnt/boot/grub2/grub.cfg
   ```

   修改里面的UUID，还需其他的，太复杂！！！[百度](https://www.baidu.com/s?wd=Linux%E7%B3%BB%E7%BB%9F%E5%88%B6%E4%BD%9C&rsv_spt=1&rsv_iqid=0xde30d87800040240&issp=1&f=3&rsv_bp=1&rsv_idx=2&ie=utf-8&rqlang=cn&tn=baiduhome_pg&rsv_enter=0&rsv_dl=ts_6&oq=Linux%25E7%25B3%25BB%25E7%25BB%259F%25E5%2588%25B6%25E4%25BD%259C&rsv_btype=t&rsv_t=6efaEEfCOUrVeesw5pl%2F3QNle5NPR5eNIyv10m92hkYnM4dt4bgqZAeaCtyprZLAHqVd&rsv_pq=d308e93d00019c0a&prefixsug=Linux%25E7%25B3%25BB%25E7%25BB%259F%25E5%2588%25B6%25E4%25BD%259C&rsp=6)

7. 创建目标主机根文件系统

   ```sh
   mkdir -pv /mnt/sysroot/{etc/rc.d,usr,var,proc,sys,dev,lib,lib64,bin,sbin,boot,srv,mnt,media,home,root} 
   ```

8. 拷贝需要的bash(也可以拷贝你需要的指令)和库文件给新的系统使用

   ```sh
   cp /lib64/*.* /mnt/sysroot/lib64/ 
   cp /bin/bash /mnt/sysroot/bin/
   ```

9. 现在我们就可以创建一个新的虚拟机，然后将默认分配的硬盘 移除掉，指向我们刚刚创建的磁盘即可

10. 这时，很多指令都不能使用，比如 ls , reboot 等，可以将需要的指令拷贝到对应的目录即可

11. 如果要拷贝指令，重新进入到原来的 linux系统拷贝相应的指令即可，比较将 /bin/ls 拷贝到 /mnt/sysroot/bin 将/sbin/reboot 拷贝到 /mnt/sysroot/sbin

    ```sh
    mount /dev/sdb2 /mnt/sysroot
    
    cp /bin/ls /mnt/sysroot/bin/
    cp /bin/systemctl /mnt/sysroot/bin/
    cp /sbin/reboot /mnt/sysroot/sbin/
    ```

12. 再重新启动新的min linux系统，就可以使用 ls , reboot 指令了





## 4. Linux 内核

1. linux 内核源码

[内核源码](https://www.kernel.org)

[内核揭秘](https://github.com/MintCN/linux-insides-zh)

**1. linux0.01 内核源码目录&阅读**

1. linux0.01 的阅读需要懂 c 语言
2. 阅读源码前，应知道 Linux 内核源码的整体分布情况。现代的操作系统一般由进程管理、内存管理、文件系统、驱动程序和网络等组成。Linux 内核源码的各个目录大致与此相对应
3. 在阅读方法或顺序上，有纵向与横向之分。所谓纵向就是顺着程序的执行顺序逐步进行；所谓横向，就是按模块进行。它们经常结合在一起进行
4. 对于 Linux 启动的代码可顺着 Linux 的启动顺序一步步来阅读；对于像内存管理部分，可以单独拿出来进行阅读分析。实际上这是一个反复的过程，不可能读一遍就理解





## 5. 备份和恢复

实体机无法做快照，如果系统出现异常或者数据损坏，后果严重， 要重做系统，还会造成数据丢失。所以我们可以使用备份和恢复技术

linux 的备份和恢复很简单 ， 有两种方式：

1. 把需要的文件(或者分区)用 TAR 打包就行，下次需要恢复的时候，再解压开覆盖即可
2. 使用 dump 和 restore 命令

**1. 安装 dump 和 restore**

```sh
yum -y install dump
yum -y install restore
```



### 1. dump 备份

dump 支持分卷和增量备份（所谓增量备份是指备份上次备份后 修改/增加过的文件，也称差异备份）

```sh
dump [ -cu] [-123456789] [ -f <备份后文件名>] [-T <日期>] [ 目录或文件系统]
```

- `-c`：创建新的归档文件，并将由一个或多个文件参数所指定的内容写入归档文件的开头。
- `-0123456789`：备份的层级。0 为最完整备份，会备份所有文件。若指定 0 以上的层级，则备份至上一次备份以来修改或新增的文件，到 9 后，可以再次轮替
- `-f <备份后文件名>`：指定备份后文件名
- `-j`：调用 bzlib 库压缩备份文件，也就是将备份后的文件压缩成 bz2 格式，让文件更小
- `-T <日期>`：指定开始备份的时间与日期
- `-u`：备份完毕后，在/etc/dumpdares 中记录备份的文件系统，层级，日期与时间等。
- `-t`：指定文件名，若该文件已存在备份文件中，则列出名称
- `-W`：显示需要备份的文件及其最后一次备份的层级，时间 ，日期。
- `-w`：与-W 类似，但仅显示需要备份的文件。

案例：

1. 将/boot 分区所有内容备份到/tmp/boot.bak0.bz2 文件中，备份层级为“0”

   ```sh
   dump -0uj -f /tmp/boot.bak0.bz2 /boot
   ```

2. 在/boot 目录下增加新文件，备份层级为“1”(只备份上次使用层次“0”备份后发生过改变的数据)

   ```sh
   dump -1uj -f /tmp/boot.bak1.bz2 /boot
   ```

**其他命令**

1. 显示需要备份的文件及其最后一次备份的层级，时间 ，日期

   ```sh
   dump [-W | -w]
   ```

2. 查看备份时间文件

   ```sh
   cat /etc/dumpdates
   ```



### 2. restore 恢复

restore 命令用来恢复已备份的文件，可以从 dump 生成的备份文件中恢复原文件

```sh
restore	[模式选项] [选项]
```

说明下面四个模式， 不能混用，在一次命令中， 只能指定一种。

- `-C`：使用对比模式，将备份的文件与已存在的文件相互对比。
- `-i`：使用交互模式，在进行还原操作时，restore 指令将依序询问用户
- `-r`：进行还原模式
- `-t `:  查看模式，看备份文件有哪些文件

选项

- `-f <备份设备>`：从指定的文件中读取备份数据，进行还原操作
