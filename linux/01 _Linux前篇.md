# Linux前篇

## 1. Linux入门

**1. 概述**

1. linux 是一个开源、免费的操作系统，其稳定性、安全性、处理多并发已经得到业界的认可，目前很多企业级的项目(c/c++/php/python/java/go)都会部署到 Linux/unix 系统上。
2. 常见的操作系统(windows、IOS、Android、MacOS, Linux, Unix)
3. Linux 主要的发行版：Ubuntu(乌班图)、RedHat(红帽)、[CentOS](https://www.centos.org/download/)、Debain[蝶变]、Fedora、SuSE、OpenSUSE  [示意图]

**2. Linux由来**

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202207112111022.png)

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202207112111024.png)

**3. Linux 和 Unix 关系图**

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202207112111025.png)







## 2. 目录结构

### 1. 基本介绍

1. linux 的文件系统是采用级层式的树状目录结构，在此结构中的最上层是根目录“/”，然后在此目录下再创建其他的目录
2. 深刻理解 linux 树状文件目录是非常重要的
3. 记住一句经典的话：在 Linux 世界里，一切皆文件
4. 示意图

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202207112111143.jpeg)



### 2. 具体目录结构

- `/`: [**常用**]根目录。
- `/bin`: [**常用**]是binary的缩写，这个目录存放最经常使用的命令。所有用户都可以访问并执行的可执行程序。包括超级用户及一般用户。
  - `/usr/bin` 是系统安装时自带的一些可执行程序。即系统程序，轻易不要去动里面的东西，容易入坑。
  - `/usr/local/bin` 是用户自行编译安装时默认的可执行程序的安装位置，这个不小心误删点什么，不会影响大局。
- `/sbin`:s就是super user的意思，这里存放的是系统管理员使用的系统管理程序。
- `/home`: [**常用**]存放普通用户的主目录，在Linux中每个用户都有自己的目录，一般该里面的子目录名都以用户的账号命名。
- `/root`: [**常用**]该目录是系统管理员，也称为超级权限者的用户主目录。 
- `/ect`: [**常用**]这个目录里面是所有的系统管理所需要的配置文件和子目录，比如my.conf。
- `/usr`: [**常用**]这是一个非常重要的目录，用户的很多应用程序和文件都放在这个目录下，类似与Windows下的program files目录。
- `/boot`: [**常用**]存放的是启动Linux时使用的一些核心文件，包括一些链接文件以及镜像文件。
- `/media`: [**常用**]Linux系统会自动识别一些设备，例如U盘、光驱等等，当识别后，Linux会把识别到的设备挂载到这个目录下。
- `/mnt`: [**常用**]系统提供该目录是为了让用户临时挂载别的文件操作系统，我们可以将外部的存储挂载到`/mnt`上，然后进入这个目录就可以看到外部的存储内容了。注：vmtools可以共享windows的文件就在此目录下。
- `/opt`: [**常用**]这是给主机额外安装软件的安装包源码所摆放的位置，例如安装Oracle数据库的源码就一般约定俗成放到这个目录下，默认为空。
- `/usr/local`: [**常用**]这是给主机额外安装软件所安装的目录，是软件安装包的目标安装目录，一般通过编译源码的方式安装软件。
- `/var`: [**常用**]这个目录中存放着在不断扩充的东西，习惯将经常被修改的目录放在这个目录下，包括各种日志文件。
- `/proc`: [**别动**]这个目录是一个虚拟的目录，它是系统内存的映射 ，访问这个目录可以获取系统信息。
- `/srv`: [**别动**]这是service的缩写，该目录存放一些服务启动之后需要提取的数据。
- `/sys`: [**别动**]这是Linux2.6内核的一个很大的变化，该目录下安装了2.6内核中新出现的一个文件系统**sysfs**。
- `/tmp`: 这个目录是用来存放一些临时文件的。
- `/lib`: 系统开机所需要的最基本的动态链接共享库，其作用类似Windows的dll文件，几乎所有的应用程序都需要用到这些共享库。
- `/lost+found`:这个目录一般情况下是空的，当系统非法关机后，这里就存放了一些文件。
- `/dev`: 该目录类似Windows的设备管理器，把所有的硬件（例如磁盘、cpu、串口等）用文件的形式存储起来。
- `/selinux`: 该目录是security-enhanced linux的缩写，是一种安全子系统，类似windows上的360，它能控制程序只能访问特定文件，有三种工作模式，可以自行设置。





## 3. vi / vim 编辑器

### 1. 基本介绍

<img src="https://gitlab.com/eardh/picture/-/raw/main/common_img/202207112111026.png" style="zoom:50%;" />

Linux 系统会内置 vi 文本编辑器

Vim 具有程序编辑的能力，可以看做是 Vi 的增强版本，可以主动的以字体颜色辨别语法的正确性，方便程序设计。

代码补完、编译及错误跳转等方便编程的功能特别丰富，在程序员中被广泛使用。

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202207112111858.gif)



### 2. 工作模式

基本上 vi/vim 共分为三种模式，分别是**一般模式**，**编辑模式**和**命令模式**。

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202207112112448.png)



#### 1. 命令模式

用户刚刚启动 vi/vim，便进入了命令模式。

此状态下敲击键盘动作会被Vim识别为命令，而非输入字符。比如我们此时按下i，并不会输入一个字符，i被当作了一个命令。

**1.移动光标**

- `h`：← 左移
- `l`：→ 右移
- ` j`：↓ 下移
- ` k`：↑ 上移
-  `gg`：光标移动文件开头
-  `G`：光标移动到文件末尾
- ` 0`：光标移动到行首
-  `$`：光标移动到行尾
- ` 123G`：跳转到第123行

**2. 删除字符**

并不是真的删除，实际上是剪切

- `x`：删除光标后一个字符，相当于 Del
-  `X`：删除光标前一个字符，相当于 Backspace
-  `dw`：删除光标开始位置的字，包含光标所在字符
- `d0`：删除光标前本行所有内容，不包含光标所在字符
- `D(d$)`：删除光标后本行所有内容，包含光标所在字符
-  `dd`：删除光标所在行
-  `n dd`：删除指定的行数

**3. 撤销操作**

- `u`：一步一步撤销
- `Ctr-r`：反撤销

**4. 复制粘贴**

- ` yy`：复制当前行
- `n yy`：复制 n 行
- `p`：在光标所在位置向下新开辟一行，粘贴
- `P`：从光标所在行，开始粘贴

**5. 可视模式**

- `v`：按字移动
  - 配合 h、j、k、l 使用
  - 使用y复制选中内容

**6. 查找操作**

- ` /hello` -> 从光标所在位置向后查找 hello
  - `n`：下一个
  - `N`：上一个
-  `?hello` -> 从光标所在位置向前查找 hello
  - `n`: 上一个
  - `N`：下一个
-  在要查询的单词上使用 # 进行查找

**7. 替换操作**

- `r`：替换当前字符

**8. 文本行移动**

- `>>`：文本行右移
- `<<`：文本行左移

**9. 查看 Man Page**

- 光标移动到函数上，`Shift-k` 光标移动到函数上
- `3Shift-k`，查看第三章的 ManPage



#### 2. 编辑模式

-  `i`: 插入光标前一个字符
- `I`: 插入行首
- `a`: 插入光标后一个字符
- `A`: 插入行未
- `o`: 向下新开一行，插入行首
- `O`: 向上新开一行，插入行首
- `s`: 删除光标所在的字符
- `S`：删除当前行



#### 3. 底线命令模式

在命令模式下按下:（英文冒号）就进入了底线命令模式。

**1. 行跳转**

- `:123` -> 跳转到第123行

**2. 替换**

 (1) 替换一行

- `:s/abc/123`：将当前行中的第一个abc替换为123
- `:s/abc/123/g`： 将当前行中的abc全部替换为123

(2)  替换全部

- `:%s/abc/123`：将所有行中的第一个abc替换为123
- `:%s/abc/123/g`：将所有行中的abc全部替换为123

 (3) 替换指定行

-  `:10,30s/abc/123/g`：将10-30行中的abc全部替换为123

**3. 执行shell命令**

-  末行模式里输入`!`，后面跟命令

**4. 分屏操作**

(1) 进入分屏模式

- 命令：`sp` 将屏幕分为两部分 --> 水平
- 命令：`vsp` 将屏幕分为两部分 --> 垂直
- 命令：`sp(vsp)` + 文件名 水平或垂直拆分窗口显示两个不同的文件

(2) 退出分屏模式

- 命令：`wqall` 保存并退出所有屏幕
- 命令：`wq` 保存并退出光标所在的屏幕
- `Ctrl+ww` 切换两个屏幕

**5. vim打造IDE**

- 系统级配置文件目录：`/etc/vim/vimrc`
- 用户级配置文件目录：`~/.vim/vimrc`
- 修改配置文件 `vimrc` 或者 `.vimrc`

**6. 行号**

- `:noh`： 取消高亮显示
- `:set nu`：显示行号
- `:set nonu`：关闭行号
- `:%s/old/new/g`：替换内容 /g 替换匹配到的所有内容



## 4. 开关机操作

### 1. 关机&重启命令

- 立该进行关机

  ```sh
  shutdown -h now
  ```

- "hello, 1  分钟后会关机了"

  ```sh
  shudown	-h	1
  ```

- 现在重新启动计算机

  ```sh
  shutdown -r now
  ```

- 关机，作用和上面一样

  ```sh
  halt
  ```

- 现在重新启动计算机

  ```sh
  reboot
  ```

- 把内存的数据同步到磁盘

  ```sh
  sync
  ```

  不管是重启系统还是关闭系统，首先要运行 **sync** 命令，把内存中的数据写到磁盘中



### 2. 用户登录和注销

1)	登录时尽量少用 root 帐号登录，因为它是系统管理员，最大的权限，避免操作失误。可以利用普通用户登录，登录后再用`su - 用户名`命令来切换成系统管理员身份
2)	在提示符下输入 `logout`  即可注销用户
   - logout  注销指令在图形运行级别无效，在运行级别 3 下有效
   - 运行级别这个概念，后面介绍



## 5. 用户管理

### 1. 用户

Linux 系统是一个多用户多任务的操作系统，任何一个要使用系统资源的用户，都必须首先向系统管理员申请一个账号，然后以这个账号的身份进入系统

1. 添加用户

   ```sh
    useradd 用户名 -d 主目录 -p 密码
   ```

2. 删除用户

   1. 删除用户，但是要保留家目录

      ```sh
      userdel 用户名
      ```

   2. 删除用户以及用户主目录

      ```sh
      userdel -r 用户名
      ```

3. 查询用户信息指令

   ```sh
   id 用户名
   ```

4. 切换用户

   在操作 Linux 中，如果当前用户的权限不够，可以通过 `su - 指令`，切换到高权限用户，比如 root

   ```sh
   su - 用户名
   ```

   - 从权限高的用户切换到权限低的用户，不需要输入密码，反之需要。
   - 当需要返回到原来用户时，使用 exit/logout 指令

5. 查看当前用户/登录用户

   ```sh
   who/whoami
   ```

6. 指定/修改密码

   ```sh
   passwd 用户名
   ```

7. 查询系统所有用户

   ```sh
   getent passwd
   ```



### 2. 用户组

类似于角色，系统可以对有共性/权限的多个用户进行统一的管理

1. 新增组

   ```sh
   groupadd 组名
   ```

2. 删除组

   ```sh
   groupdel 组名
   ```

3. 创建用户时加入组

   ```sh
   useradd -g 用户组 用户名
   ```

   如果像前面一样不指定组，则会默认将自己独立创建为组并把自己加入

4. 修改用户的组

   ```sh
   usermod	-g 用户组 用户名
   ```

5. 查询用户所属组

   ```sh
   groups 用户名
   ```



### 3. 用户和组相关文件

1. `/etc/passwd` 文件

   用户（user）的配置文件，记录用户的各种信息

   每行的含义：

   - ```sh
     用户名:口令:用户标识号:组标识号:注释性描述:主目录:登录Shell
     ```

2. `/etc/shadow` 文件

   口令的配置文件

   每行的含义：

   - ```sh
     登录名:加密口令:最后一次修改时间:最小时间间隔:最大时间间隔:警告时间:不活动时间:失效时间:标志
     ```

3. `/etc/group` 文件

   组(group)的配置文件，记录 Linux 包含的组的信息

   每行含义：

   - ```sh
     组名:口令:组标识号:组内用户列表
     ```





## 6. 实用指令

### 1. 指定运行级别

1.  **运行级别说明**

   1. 关机
   2. 单用户【找回丢失密码】
   3. `多用户状态没有网络服务`
   4. 多用户状态有网络服务
   5. `系统未使用保留给用户`
   6. 图形界面
   7. 系统重启

   常用运行级别是 3 和 5 ，也可以指定默认运行级别

2. 切换不同的运行级别

   ```sh
   init [0|1|2|3|4|5|6]
   ```

3. 运行级别文件

   ```sh
   cat /etc/inittab
   ```

   - `multi-user.target`: analogous to runlevel 3
   - `graphical.target`: analogous to runlevel 5

4. 获取当前的**默认运行级别**

   ```sh
   systemctl get-default
   ```

5. **设置默认的运行级别**

   ```sh
   systemctl set-default TARGET.target
   ```



### 2. 找回Root密码

CentOS7操作有效

1. 首先，启动系统，进入开机界面，在界面中按“e”进入编辑界面

2. 进入编辑界面，使用键盘上的上下键把光标往下移动，找到以“Linux16”开头内容所在的行数”，在行的最后面输入：

   ```sh
   init=/bin/sh
   ```

3. 输入完成后，直接按快捷键：Ctrl+x 进入**单用户模式**

4. 在光标闪烁的位置中输入：`mount -o remount,rw /`（注意：各个单词间有空格），完成后按键盘的回车键（Enter）

5. 在新的一行最后面输入：`passwd`， 完成后按键盘的回车键（Enter）。输入密码，然后再次确认密码即可，密码修改成功后，会显示passwd.....的样式，说明密码修改成功

6. 在鼠标闪烁的位置中（最后一行中）输入：`touch /.autorelabel`（注意：touch与 /后面有一个空格），完成后按键盘的回车键（Enter）

7. 继续在光标闪烁的位置中，输入：`exec /sbin/init`（注意：exec与 /后面有一个空格），完成后按键盘的回车键（Enter）,等待系统自动修改密码（可能时间较长）



### 3. 帮助指令

1. man 获得**帮助信息**，基本语法：

   ```sh
   man [命令或配置文件]
   ```

2. 获得 **shell 内置命令**的帮助信息

   ```sh
   help 命令
   ```



### 4. 文件目录类

1. 显示当前工作目录的绝对路径

   ```sh
   pwd
   ```

2. 查看当前目录的所有内容信息

   ```sh
   ls [选项] [目录或是文件]
   ```

   常用选项：

   - `-a`：显示当前目录所有的文件和目录，包括隐藏的
   - `-l`：以列表的方式显示信息

3. **切换目录**

   ```sh
   cd [参数]
   ```

   - `cd ~` 或者 `cd` ：回到自己的家目录
   - `cd ..`：回到当前目录的上一级目录

4. 创建目录

   ```sh
   mkdir [选项] 目录
   ```

   常用选项：

   - `-m`, --mode=MODE   set file mode (as in chmod), not a=rwx - umask
   - `-p`, --parents     no error if existing, make parent directories as needed
   - `-v`, --verbose     print a message for each created directory

5. 删除空目录

   ```sh
   rmdir [选项] 目录
   ```

   常用选项：

   - `-p`, --parents   remove DIRECTORY and its ancestors
   - `-v`, --verbose   output a diagnostic for every directory processed

6. 创建空文件

   ```sh
   touch 文件
   ```

7. 拷贝文件到指定目录

   ```sh
   cp [选项] [-T] 源文件 目标文件
   cp [选项] 源文件... 目录
   cp [选项] -t 目录 源文件...
   ```

   常用选项：

   - `-R,-r,--recursive`：递归复制目录及其子目录内的所有内容
   - `\cp`：不提示存在的覆盖文件

8. 移除文件或目录

   ```sh
   rm [选项] 文件
   ```

   常用选项：

   - `-r`：递归删除整个文件夹
   - `-f`： 强制删除不提示

9. 移动文件与目录或重命名

   ```sh
   mv [选项] [-T] 源文件 目标文件
   mv [选项] 源文件 目录
   mv [选项] -t 目录 源文件
   ```

   常用选项：

   - `-f,--force`：覆盖前不询问
   - `-i,--interactive`：覆盖前询问
   - `-n,--no-clobber`：不覆盖已存在文件

10. 查看文件内容

    ```sh
    cat [选项] [文件]
    ```

    常用选项：

    - `-b,--number-nonblank`：对非空输出行编号
    - `-E,--show-ends`：在每行结束处显示"$"
    - `-n,--number`：对输出的所有行编号

11. `more` 指令

    more 指令是一个基于 VI 编辑器的文本过滤器，它以全屏幕的方式按页显示文本文件的内容

    ```sh
    more [选项] 文件
    ```

    常用选项：

    - `-s`：将多个空行压缩为一行
    - `-NUM`：指定每屏显示的行数为 NUM

12. `less` 指令

    less 指令用来分屏查看文件内容，它的功能与 more 指令类似，但是比 more 指令更加强大，支持各种显示终端。less指令在显示文件内容时，并不是一次将整个文件加载之后才显示，而是根据显示需要加载内容，对于显示大型文件具有较高的效率

    ```sh
    more 文件
    ```

13. `echo` 指令

    输出内容到控制台

    ```sh
    echo [OPTION] [STRING]
    ```

14. `head` 指令

    用于显示文件的开头部分内容，默认情况下 head 指令显示文件的前 10 行内容

    ```sh
    head [选项] [文件]
    ```

    常用选项：

    - `-c num`：输出前num个字节
    - `-n num`：输出前num行

15. `tail` 指令

    用于输出文件中尾部的内容，默认情况下 tail 指令显示文件的前 10 行内容

    ```sh
    tail [选项] [文件]
    ```

    常用选项：

    - `-c num`：输出倒数num个字节
    - `-n num`：输出倒数num行
    - `-f`：输出追加在

16. `>` 指令 和 `>>` 指令

    - `>`：输出重定向和
    - `>>`：追加

17. `ln` 指令

    - 软链接

      软链接称之为符号连接（Symbolic Link），也叫软连接。软链接文件有类似于 Windows 的快捷方式。它实际上是一个特殊的文件。在符号连接中，文件实际上是一个文本文件，其中包含的有另一文件的位置信息。比如：A 是 B 的软链接（A 和 B 都是文件名），A 的目录项中的 inode 节点号与 B 的目录项中的 inode 节点号不相同，A 和 B 指向的是两个不同的 inode，继而指向两块不同的数据块。但是 A 的数据块中存放的只是 B 的路径名（可以根据这个找到 B 的目录项）。A 和 B 之间是“主从”关系，如果 B 被删除了，A 仍然存在（因为两个是不同的文件），但指向的是一个无效的链接。

      ```sh
      ln -s [目录] [目标]
      ```

    - 硬链接

      硬连接指通过索引节点来进行连接。在 Linux 的文件系统中，保存在磁盘分区中的文件不管是什么类型都给它分配一个编号，称为索引节点号(Inode Index)。在 Linux 中，多个文件名指向同一索引节点是存在的。比如：A 是 B 的硬链接（A 和 B 都是文件名），则 A 的目录项中的 inode 节点号与 B 的目录项中的 inode 节点号相同，即一个 inode 节点对应两个不同的文件名，两个文件名指向同一个文件，A 和 B 对文件系统来说是完全平等的。删除其中任何一个都不会影响另外一个的访问。

      硬连接的作用是允许一个文件拥有多个有效路径名，这样用户就可以建立硬连接到重要文件，以防止“误删”的功能。其原因如上所述，因为对应该目录的索引节点有一个以上的连接。只删除一个连接并不影响索引节点本身和其它的连接，只有当最后一个连接被删除后，文件的数据块及目录的连接才会被释放。也就是说，文件真正删除的条件是与之相关的所有硬连接文件均被删除。

      ```sh
      ln [目录] [目标]
      ```

18. `history` 指令

    查看已经执行过历史命令,也可以执行历史指令

    ```sh
    history [-c] [-d 偏移量] [n]
    ```

    - `-c`：删除所有条目从而清空历史列表
    - `-d`：从指定位置删除历史列表
    - `n`：列出最后的 n 个条目



### 5. 时间日期类

1. `date` 指令

   显示当前日期

   ```sh
   date [选项] [+格式]
   ```

   格式：

   - `%Y`：年
   - `%m`：月
   - `%d`：日
   - `%H`：时
   - `%M`：分
   - `%S`：秒

2. 设置时间

   ```sh
   date -s 时间字符串
   ```

3. `cal` 指令

   ```sh
   cal [选项] [[[日] 月] 年]
   ```

   选项：

   - `-1,--one` ：只显示当前月份(默认)
   - `-3,--three`：显示上个月、当月和下个月
   - `-s,--sunday`：周日作为一周第一天
   - `-m,--monday`：周一用为一周第一天
   - `-j,--julian`：输出儒略日
   - `-y,--year`：输出整年

   `[[[日] 月] 年]`：需要显示哪天，如：`10 7 2022`



### 6. 搜索查找类

1. `find` 指令

   指令将从指定目录向下递归地遍历其各个子目录，将满足条件的文件或者目录显示在终端

   ```sh
    find [path] [expression]
   ```

   - `path`：在path路径下的查找
   - `expression`：表达式
     - `-name`：按照文件名查找文件
     - `-user`：按用户查找
     - `-size`：按照文件大小查找
       - `+`：大于
       - `-`：小于

2. `locate` 指令

   可以快速定位文件路径。locate 指令利用事先建立的系统中所有文件名称及路径的 locate 数据库实现快速定位给定的文件。Locate 指令无需遍历整个文件系统，查询速度较快。为了保证查询结果的准确度，管理员必须定期更新 locate 时刻

   由于 locate 指令基于数据库进行查询，所以第一次运行前，必须使用 updatedb 指令创建 locate 数据库

   ```sh
   updatedb
   ```

   ```sh
   locate 文件名
   ```

3. `which` 指令

   可以查看某个指令在哪个目录下，比如 ls 指令在哪个目录

   ```sh
   which ls
   ```

4. `grep` 指令 和 管道符号 `|`

   grep 过滤查找， 管道符 `|`，表示将前一个命令的处理结果输出传递给后面的命令处理

   ```sh
   grep [选项] PATTERN [FILE]
   ```

   常用选项：

   - `-n`：输出的同时打印行号
   - `-i`：忽略大小写



### 7. 压缩和解压类

1. `gzip/gunzip` 指令

   gzip：用于压缩文件

   - ```sh
     gzip 文件
     ```

     只能将文件压缩为`*.gz` 文件

   gunzip：用于解压

   - ```sh
     gunzip gz文件
     ```

2. `zip/unzip` 指令

   zip 用于压缩文件， unzip 用于解压的，这个在项目打包发布中很有用的

   ```sh
   zip	[选项] XXX.zip
   ```

   常用选项：

   - `-r`：递归压缩，即压缩目录

   ```sh
   unzip [选项] XXX.zip
   ```

   常用选项：

   - `-d` <目录> ：指定解压后文件的存放目录

3. `tar` 指令

   ```sh
   tar [选项] 生成的压缩包的名字 压缩的文件(文件或者目录)
   ```

   通用选项：

   - `-z`：使用 gzip 的方式压缩或解压
   - `-j`：使用 bzip2 的方式压缩或解压
   - `-v`：压缩过程中显示压缩信息，可以省略不写
   - `-f`：指定压缩包的名字

   压缩选项：

   - `-c`：创建压缩文件

   解压选项：

   - `-x`：释放压缩文件内容
   - `-C`：解压到的目录





## 7. 组管理和权限管理

### 1. 组管理

**1. Linux组基本介绍**

在 linux 中的每个用户必须属于一个组，不能独立于组外。在 linux 中每个文件有所有者、所在组、其它组的概念。

1. 所有者
2. 所在组
3. 其它组
4. 改变用户所在的组

**2. 文件/目录所属**

一般为文件的创建者,谁创建了该文件，就自然的成为该文件的所有者。

1. 查看文件的所有者

   ```sh
   ls –al
   ```

2. 修改文件所有者

   ```sh
   chown [选项] [所有者][:[组]] 文件
   ```

   选项：

   - `-dereference`：affect the referent of each symbolic link (this is
                              the default), rather than the symbolic link itself
   - `-h,--no-dereference`：affect symbolic links instead of any referenced file(useful only on systems that can change the ownership of a symlink)

3. 组的创建

   ```sh
   groupadd [选项] 组
   ```

4. 修改文件/目录所在的组

   ```sh
   chgrp [选项] 用户组 文件
   ```

**3. 其它组**

除文件的所有者和所在组的用户外，系统的其它用户都是文件的其它组

**4. 改变用户所在组**

在添加用户时，可以指定将该用户添加到哪个组中，同样的用 root 的管理权限可以改变某个用户所在的组。

```sh
usermod	–g 新组名 用户名
```



### 2. 权限管理

**1. 权限的基本介绍**

```bash
-rw-r--r--.  1 root my1 10 7月 10 19:56 apple.txt
```

1. 第`0`位：确定文件类型(d, - , l , c , b)

   - **`l`**：链接，相当于 windows 的快捷方式
   - **`d`**：目录，相当于 windows 的文件夹
   - **`c`**：装置文件里面的串行端口设备，鼠标，键盘等（一次性读取装置）
   - **`b`**：块设备（装置文件里面的可供储存的接口设备），比如硬盘（可随机存取装置）
   - **`-`**：文件

2. 第`1-3`位：确定**所有者**（该文件的所有者）拥有该文件的权限。---User

3. 第`4-6`位：确定**所属组**（同用户组的）拥有该文件的权限。---Group

4. 第`7-9`位：确定**其他用户**拥有该文件的权限。---Other

5. 其他说明

   ![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202207112111027.png)

**2. rwx 权限详解**

1. 作用于文件
   - `[r]`代表可读(read)：可以读取，查看
   - `[w]`代表可写(write)：可以修改，但是不代表可以删除该文件，删除一个文件的前提条件是对该文件所在的目录有写权限，才能删除该文件
   - `[x]`代表可执行(execute)：可以被执行
2. 作用于目录
   - `[r]`代表可读(read)：可以读取，ls 查看目录内容
   - `[w]`代表可写(write)：可以修改，对目录内创建+删除+重命名目录
   - `[x]`代表可执行(execute)：可以进入该目录

**3. 修改权限**

通过 chmod 指令，可以修改**文件或者目录**的权限

1. `+` 、`-`、`=`变更权限

   ```sh
   chmod u=rwx,g=rx,o=x 文件/目录名
   chmod o+w 文件/目录名
   chmod a-x 文件/目录名
   ```

   - `u`：所有者

   - `g`：所属组

   - `o`：其他人

   - `a`：所有人(u、g、o 的总和)
   - `+`：追加权限
   - `-`：去除权限
   - `=`：赋予权限

2. 通过`数字`变更权限

   将rwx对应位用0或1表示，有权限对应位位1，反之。

   ```sh
   chmod 数值 文件/目录名
   ```

    例如：

   `u=rwx,g=rx,o=x` 等价于 751（rwx ：111，rx：101，x：001)

**4. 修改文件所属主和所属组**

```sh
chown [选项] [所有者][:[组]] 文件
```

选项：

- `-R`：如果是目录 则使其下所有子文件或目录递归生效

**5. 修改文件所属组**

```sh
chgrp [选项] 用户组 文件
```





## 8. 定时任务调度

### 1. crond 任务调度

任务调度：是指系统在某个时间执行的特定的命令或程序。

任务调度分类：

- 系统工作：有些重要的工作必须周而复始地执行。如病毒扫描等
- 个别用户工作：个别用户可能希望执行某些程序，比如对 mysql 数据库的备份。

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202207112111028.png)

```sh
crontab [选项]
```

选项：

- `-i`：编辑crontab任务
- `-l`：查询crontab任务
- `-r`：删除crontab任务

步骤：

1. 设置任务调度文件：/etc/crontab

2. 设置个人任务调度

   ```sh
   crontab -e
   ```

3. 输入任务到调度文件

   ```bash
   #调度文件格式
   .---------------- minute (0 - 59)
   |  .------------- hour (0 - 23)
   |  |  .---------- day of month (1 - 31)
   |  |  |  .------- month (1 - 12) OR jan,feb,mar,apr ...
   |  |  |  |  .---- day of week (0 - 6) (Sunday=0 or 7) sun,mon,tue,wed,thu,fri,sat
   |  |  |  |  |
   *  *  *  *  * user-name  command to be executed
   ```

   特殊符号：

   - `*`：代表任何时间。比如第一个“*”就代表一小时中每分钟都执行一次的意思。
   - `,`：代表不连续的时间。比如`0 8,12,16 * * *`，就代表在每天的8点0分，12点0分，16点0分都执行一次命令
   - `-`：代表连续的时间范围。比如`0 5 * * 1-6`命令，代表在周一到周六的凌晨5点0分执行命令
   - `/n`：代表每隔多久执行一次。比如`*/10 * * * *`命令”，代表每隔10分钟就执行一遍命令

   案例说明：

   1. `45 22 * * *`：在22点45分执行命令
   2. `0 17 * * 1`：每周1的17点0分执行命令
   3. `0 5 1,5 * *`：每月1号和15号的凌晨5点0分执行命令
   4. `40 4 * * 1-5`：每周一到周五的凌晨4点40分执行命令
   5. `*/10 4 * * *`：每天的凌晨4点，每隔10分钟执行一次命令
   6. `0 0 1,15 * 1`：每月1号和15号，每周1的O点0分都会执行命令。注意：星期几和几号最好不要同时出现，因为他们定义的都是天。非常容易让管理员混乱。



### 2. at 定时任务

**1. 基本介绍**

1. at 命令是一次性定时计划任务，at 的守护进程 atd 会以后台模式运行，检查作业队列来运行。

2. 默认情况下，atd 守护进程每 60 秒检查作业队列，有作业时，会检查作业运行时间，如果时间与当前时间匹配，则运行此作业。

3. at 命令是一次性定时计划任务，执行完一个任务后不再执行此任务了

4. 在使用 at 命令的时候，一定要保证 atd 进程的启动 , 可以使用相关指令来查看

   ```sh
   ps -ef | grep atd #可以检测 atd 是否在运行
   ```

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202207112111029.png)

**2. 命令格式**

```sh
at [选项] [时间]
```

Ctrl + D  结束 at 命令的输入， 输出两次

选项：

- `-m`：当指定的任务被完成后，将给用户发送邮件，即使没有标准输出
- `-I`：atq的别名
- `-d`：atrm的别名
- `-v`：显示任务将被执行的时间
- `-c`：打印任务的内容到标准输出
- `-V`：显示版本信息
- `-q <队列>`：使用指定的队列
- `-f <文件>`：从指定文件读入任务而不是从标准输入读入
- `-t <时间参数>`：以时间参数的形式提交要运行的任务

**3. 时间定义**

1. 接受在当天的 hh:mm（小时:分钟）式的时间指定。假如该时间已过去，那么就放在第二天执行。 例如：04:00
2. 使用 midnight（深夜），noon（中午），teatime（饮茶时间，一般是下午 4 点）等比较模糊的词语来指定时间。
3. 采用 12 小时计时制，即在时间后面加上 AM（上午）或 PM（下午）来说明是上午还是下午。 例如：12pm
4. 指定命令执行的具体日期，指定格式为 month day（月 日）或 mm/dd/yy（月/日/年）或 dd.mm.yy（日.月.年），指定的日期必须跟在指定时间的后面。 例如：04:00 2021-03-1
5.  使用相对计时法。指定格式为：now + count time-units ，now 就是当前时间，time-units 是时间单位，这里能够是 minutes（分钟）、hours（小时）、days（天）、weeks（星期）。count 是时间的数量，几天，几小时。 例如：now + 5 minutes
6. 直接使用 today（今天）、tomorrow（明天）来指定完成命令的时间。

**4. atq 命令来查看系统中没有执行的工作任务**

```sh
atq
```

**5. 删除已经设置的任务**

```sh
atrm 任务编号
```





## 9. 磁盘分区和挂载

### 1. Linux 分区

**1. 原理介绍**

1. Linux 来说无论有几个分区，分给哪一目录使用，它归根结底就只有一个根目录，一个独立且唯一的文件结构 , Linux 中每个分区都是用来组成整个文件系统的一部分。
2. Linux 采用了一种叫“载入”的处理方法，它的整个文件系统中包含了一整套的文件和目录，且将一个分区和一个目录联系起来。这时要载入的一个分区将使它的存储空间在一个目录下获得。

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202207112111030.png)

**2. 硬盘说明**

1. Linux 硬盘分 IDE 硬盘和 SCSI 硬盘，目前基本上是 SCSI 硬盘
2. 对于 IDE 硬盘，驱动器标识符为“hdx~”,其中“hd”表明分区所在设备的类型，这里是指 IDE 硬盘了。“x”为盘号（a 为基本盘，b 为基本从属盘，c 为辅助主盘，d 为辅助从属盘）,“~”代表分区，前四个分区用数字 1 到 4 表示，它们是主分区或扩展分区，从 5 开始就是逻辑分区。例，hda3 表示为第一个 IDE 硬盘上的第三个主分区或扩展分区,hdb2表示为第二个 IDE 硬盘上的第二个主分区或扩展分区。
3. 对于 SCSI 硬盘则标识为“sdx~”，SCSI 硬盘是用“sd”来表示分区所在设备的类型的，其余则和 IDE 硬盘的表示方法一样

**3. 查看所有设备挂载情况**

```sh
lsblk
```

```sh
lsblk -f
```

**4. 挂载的经典案例**

1. 虚拟机添加硬盘

2. 分区

   ```sh
   fdisk /dev/sdb
   ```

   开始对`/sdb` 分区

   - `m`：显示命令列表
   - `p`：显示磁盘分区 同 fdisk  –l
   - `n`：新增分区
   - `d`：删除分区
   - `w`：写入并退出

   说明： 开始分区后输入 n，新增分区，然后选择 p ，分区类型为主分区。两次回车默认剩余全部空间。最后输入 w 写入分区并退出，若不保存退出输入 q

3. 格式化

   ```sh
   mkfs -t ext4 /dev/sdb1
   ```

   ` ext4` 是分区类型

4. 挂载

   将一个分区与一个目录联系起来

   ```sh
   mount 设备名称 挂载目录
   ```

   卸载：

   - ```sh
     umount 设备名称
     ```

   用命令行挂载，重启后会失效

5. 设置可以自动挂载

   永久挂载：通过修改`/etc/fstab` 实现挂载

   ```sh
   vim /etc/fstab
   
   mount -a
   ```



### 2. 磁盘情况查询

1. 查询系统整体磁盘使用情况

   ```sh
   df -h
   ```

2. 查询指定目录的磁盘占用情况

   ```sh
   du -h
   ```

   查询指定目录的磁盘占用情况，默认为当前目录 -s 指定目录占用大小汇总

   - `-h`：带计量单位
   - `-a`：含文件
   - `--max-depth=1`：子目录深度
   - `-c`：列出明细的同时，增加汇总值

3. 统计/opt 文件夹下文件的个数

   ```sh
   ls -l /opt | grep "^-" | wc -l
   ```

4. 统计/opt 文件夹下目录的个数

   ```sh
   ls -l /opt | grep "^d" | wc -l
   ```

5. 统计/opt 文件夹下文件的个数，包括子文件夹里的

   ```sh
   ls -lR /opt | grep "^-" | wc -l
   ```

6. 统计/opt 文件夹下目录的个数，包括子文件夹里的

   ```sh
   ls -lR /opt | grep "^d" | wc -l
   ```

7. 以树状显示目录结构 tree 目录

   如果没有 tree，则用yum安装

   ```sh
   yum install -y tree
   ```





## 10. 网络配置

1. 网络环境配置

   1. dhcp

   2. 静态配置

      ```sh
      vim /etc/sysconfig/network-scripts/ifcfg-ens33
      ```

      ```properties
      #mac地址
      HWADDR=00:0C:29:03:A0:FB
      
      #网络类型
      TYPE=Ethernet
      
      #接口名(设备,网卡)
      DEVICE=ens33
      
      #代理方法
      PROXY_METHOD=none
      
      BROWSER_ONLY=no
      
      #IP的配置方法[none|static|bootp|dhcp](引导时不使用协议|静态分配IP|BOOTP协议|DHCP协议)
      BOOTPROTO=static
      
      DEFROUTE=yes
      IPV4_FAILURE_FATAL=no
      IPV6INIT=yes
      IPV6_AUTOCONF=yes
      IPV6_DEFROUTE=yes
      IPV6_FAILURE_FATAL=no
      IPV6_ADDR_GEN_MODE=stable-privacy
      NAME=ens33
      
      #随机id
      UUID=c368f1c7-1808-319b-9d63-f6a12bc1164f
      
      #系统启动的时候网络接口是否有效(yes/no)
      ONBOOT=yes
      AUTOCONNECT_PRIORITY=-999
      
      #IP地址
      IPADDR=192.168.111.129
      #网络前缀(划分子网)
      PREFIX=24
      
      #网关
      GATEWAY=192.168.111.2
      
      #域名解析器
      DNS1=192.168.111.2
      ```

2. 设置主机名和 hosts 映射

   1. 设置主机名

      1. 为了方便记忆，可以给 linux 系统设置主机名，也可以根据需要修改主机名

      2. 查看主机名

         ```sh
         hostname
         ```

      3. 修改文件在 `/etc/hostname` 指定

      4. 修改后，重启生效

   2. 设置 hosts 映射

      ```sh
      vim /etc/hosts
      
      #格式
      IP地址 主机名
      ```

   3. 主机名解析过程分析(Hosts、DNS)
   
      1. Hosts
   
         一个文本文件，用来记录 IP 和 Hostname(主机名)的映射关系
   
      2. DNS
   
         Domain Name System 的缩写，翻译过来就是域名系统是互联网上作为域名和 IP 地址相互映射的一个分布式数据库
   
      3. www.baidu.com解析过程
   
         ![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202207112113324.png)
   
         1. 浏览器先检查浏览器缓存中有没有该域名解析 IP 地址，有就先调用这个 IP 完成解析；如果没有，就检查 DNS 解析器缓存，如果有直接返回 IP 完成解析。这两个缓存，可以理解为 本地解析器缓存
   
         2. 一般来说，当电脑第一次成功访问某一网站后，在一定时间内，浏览器或操作系统会缓存他的 IP 地址（DNS 解析记录）如 在 cmd 窗口中输入
   
            ```bash
            #DNS 域名解析缓存
            ipconfig /displaydns
            
            #手动清理 dns 缓存
            ipconfig /flushdns
            ```
   
         3. 如果本地解析器缓存没有找到对应映射，检查系统中 hosts 文件中有没有配置对应的域名 IP 映射，如果有，则完成解析并返回。
   
         4. 如果 本地 DNS 解析器缓存 和 hosts 文件中均没有找到对应的 IP，则到域名服务 DNS 进行解析域名





## 11. 进程/服务管理

### 1. 进程管理

**1. 基本介绍**

1. 在 LINUX 中，每个执行的程序都称为一个进程。每一个进程都分配一个 ID 号(pid,进程号)。=>windows => linux
2. 每个进程都可能以两种方式存在的。前台与后台，所谓前台进程就是用户目前的屏幕上可以进行操作的。后台进程则是实际在操作，但由于屏幕上无法看到的进程，通常使用后台方式执行。
3. 一般系统的服务都是以后台进程的方式存在，而且都会常驻在系统中。直到关机才才结束

**2. 显示系统执行的进程**

```sh
ps -aux | grep xxx
```

指令说明：

- System V 展示风格
- USER：用户名称
- PID：进程号
- %CPU：进程占用 CPU 的百分比
- %MEM：进程占用物理内存的百分比
- VSZ：进程占用的虚拟内存大小（单位：KB）
- RSS：进程占用的物理内存大小（单位：KB）
- TT：终端名称，缩写
- STAT：进程状态，其中 S-睡眠，s-表示该进程是会话的先导进程，N-表示进程拥有比普通优先级更低的优先级，R-正在运行，D-短期等待，Z-僵死进程，T-被跟踪或者被停止等等
- STARTED：进程的启动时间
- TIME：CPU 时间，即进程使用 CPU 的总时间
- COMMAND：启动进程所用的命令和参数，如果过长会被截断显示

```sh
ps -ef
```

全格式显示当前所有的进程

指令说明：

- UID：用户ID 
- PID：进程ID
- PPID：父进程 ID
- C：CPU 用于计算执行优先级的因子。数值越大，表明进程是 CPU 密集型运算，执行优先级会降低；数值越小，表明进程是 I/O 密集型运算，执行优先级会提高
- STIME：进程启动的时间
- TTY：完整的终端名称
- TIME：CPU 时间
- CMD：启动进程所用的命令和参数

**3. 终止进程 kill 和 killall**

若是某个进程执行一半需要停止时，或是已消了很大的系统资源时，此时可以考虑停止该进程。使用 kill 命令来完成此项任务

1. 通过进程号杀死/终止进程

   ```sh
   kill [选项] 进程号
   ```

   选项：

   - `-9`：表示强迫进程立即停止

2. 通过进程名称杀死进程，也支持通配符

   ```sh
   killall 进程名称
   ```

**4. 查看进程树**

```sh
pstree [选项]
```

常用选项：

- `-p`：显示进程的 PID
- `-u`：显示进程的所属用户



### 2. 服务管理

服务(service) 本质就是进程，但是是运行在后台的，通常都会监听某个端口，等待其它程序的请求，比如(mysqld , sshd 防火墙等)，因此我们又称为守护进程

**1. 查看服务名**

1. 使用 setup -> 系统服务 就可以看到全部

   ```sh
   setup
   ```

2. /etc/init.d 看到 service 指令管理的服务

   ```sh
   s -l /etc/init.d
   ```

**2. 服务的运行级别(runlevel)**

Linux 系统有 7 种运行级别(runlevel)：常用的是**级别** **3** **和** **5**

- 运行级别 0：系统停机状态，系统默认运行级别不能设为 0，否则不能正常启动
- 运行级别 1：单用户工作状态，root 权限，用于系统维护，禁止远程登陆
- 运行级别 2：多用户状态(没有 NFS)，不支持网络
- 运行级别 3：完全的多用户状态(有 NFS)，无界面，登陆后进入控制台命令行模式
- 运行级别 4：系统未使用，保留
- 运行级别 5：X11 控制台，登陆后进入图形 GUI 模
- 运行级别 6：系统正常关闭并重启，默认运行级别不能设为 6，否则不能正常启动 

开机的流程：

![](https://gitlab.com/eardh/picture/-/raw/main/common_img/202207112111031.png)

运行级别指令：

1. 切换不同的运行级别

   ```sh
   init [0|1|2|3|4|5|6]
   ```

2. 运行级别文件

   ```sh
   cat /etc/inittab
   ```

   - `multi-user.target`: analogous to runlevel 3
   - `graphical.target`: analogous to runlevel 5

3. 获取当前的默认运行级别

   ```sh
   systemctl get-default
   ```

4. 设置默认的运行级别

   ```sh
   systemctl set-default TARGET.target
   ```

**3. 服务管理指令**

1. `chkconfig` 指令(过时，systemclt替换)

   1. 查看服务

      ```sh
      chkconfig --list [| grep xxx]
      ```

   2. 服务自启动设置

      ````sh
      chkconfig --level 5 服务名 on/off
      ````

   chkconfig 重新设置服务后自启动或关闭，需要重启机器 reboot 生效

2. `systemctl` 管理指令

   systemctl 指令管理的服务在 `/usr/lib/systemd/system` 查看

   ```sh
   ls -al /usr/lib/systemd/system
   ```

   1. 服务状态切换

      ```sh
      systemctl [start | stop | restart | status] 服务名
      ```

   2. 设置服务的自启动状态

      1. 查看服务自启动状态

         ```sh
         systemctl list-unit-files [| grep 服务名]
         ```

      2. 开启关闭自启动

         ```sh
         systemctl [enable | disable] 服务名
         ```

      3. 查询某个服务是否是自启动

         ```sh
         systemctl is-enabled 服务名
         ```



### 3. 防火墙

防火墙服务：`firewalld.service`

```sh
systemctl [ stop | stop | status | enable | disable] firewalld
```

关闭或者启用防火墙后，立即生效。[telnet 测试 某个端口即可]

这种方式只是临时生效，当重启系统后，还是回归以前对服务的设置。

**打开或者关闭指定端口**

在真正的生产环境，往往需要将防火墙打开，但问题来了，如果我们把防火墙打开，那么外部请求数据包就不能跟服务器监听端口通讯。这时，需要打开指定的端口。

1. 打开端口

   ```sh
   firewall-cmd --permanent --add-port=端口号/协议
   ```

2. 关闭端口

   ```sh
   firewall-cmd --permanent --remove-port=端口号/协议
   ```

3. 打开或关闭后重新载入，才能生效

   ```sh
   firewall-cmd --reload
   ```

4. 查询端口是否开放

   ```sh
   firewall-cmd --query-port=端口/协议
   ```

5. 查询已开放的端口

   ```sh
   cat /etc/services
   ```



### 4. 监控进程

top 与 ps 命令很相似。它们都用来显示正在执行的进程。Top 与 ps 最大的不同之处，在于 top 在执行一段时间可以更新正在运行的的进程

```sh
top [选项]
```

选项：

- `-d n`：指定top每隔n秒更新，默认3秒
- `-i`：不显示闲置或者僵死的进程
- `-p`：指定PID来监控某个进程的状态

交互操作：

- p：以CPU使用频率排序，默认
- M：以内存的使用频率排序
- N：以PID排序
- q：退出top
- k：杀死某个进程
- u：监控某个用户的进程



### 5. 监控网络

**1. 查看系统网络情况**

```sh
netstat [选项]
```

选项：

- `-an`：按一定顺序排列输出
- `-p`：显示哪个进程在调用

**2. 检测主机连接命令 ping**

是一种网络检测工具，它主要是用检测远程主机是否正常，或是两部主机间的网线或网卡故障。

```sh
ping ip地址
```





## 12. rpm 与 yum

### 1. rpm

rpm 用于互联网下载包的打包及安装工具，它包含在某些 Linux 分发版中。它生成具有.RPM 扩展名的文件。RPM 是 RedHat Package Manager（RedHat 软件包管理工具）的缩写，类似 windows 的 setup.exe，这一文件格式名称虽然打上了 RedHat 的标志，但理念是通用的。

Linux 的分发版本都有采用（suse,redhat, centos 等等），可以算是公认的行业标准了。

**1. rpm 包的简单查询指令**

1. 查询已安装的 rpm 列表

   ```sh
   rpm –aq | grep xx
   ```

2. 查询软件包信息

   ```sh
   rpm -iq 软件包名
   ```

3. 查询软件包是否安装

   ```sfh
   rpm -q 软件包名
   ```

4. 查询文件所属的软件包

   ```sh
   rpm -qf 文件全路径名
   ```

**2. 卸载 rpm 包**

```sh
rpm -e 软件包名
```

1. 如果其它软件包依赖于您要卸载的软件包，卸载时则会产生错误信息。

   ```sh
   rpm -e foo
   ```

2. 如果我们就是要删除 foo 这个 rpm 包，可以增加参数 --nodeps ,就可以强制删除，但是一般不推荐这样做，因为依赖于该软件包的程序可能无法运行

   ```sh
   rpm -e --nodeps foo
   ```

**3. 安装 rpm 包**

```sh
rpm -ivh 软件包全路径名
```

参数说明：

- `i=install`：安装
- `v=verbose`：提示
- `h=hash`：进度条



### 2. yum

Yum 是一个 Shell 前端软件包管理器。基于 RPM 包管理，能够从指定的服务器自动下载 RPM 包并且安装，可以自动处理依赖性关系，并且一次安装所有依赖的软件包。

1. 查询 yum 服务器是否有需要安装的软件

   ```sh
   yum list | grep xx
   ```

2. 通用操作

   ```sh
   yum [options] COMMAND
   ```

   常用options：

   - `-y`：回答全部问题为是

