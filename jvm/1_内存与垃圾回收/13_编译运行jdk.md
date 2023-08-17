# 编译运行jdk-21

学习来源于该[博客](https://blog.csdn.net/Mr_rain/article/details/123887310?spm=1001.2101.3001.6661.1&utm_medium=distribute.pc_relevant_t0.none-task-blog-2%7Edefault%7EBlogCommendFromBaidu%7ERate-1-123887310-blog-100153536.pc_relevant_recovery_v2&depth_1-utm_source=distribute.pc_relevant_t0.none-task-blog-2%7Edefault%7EBlogCommendFromBaidu%7ERate-1-123887310-blog-100153536.pc_relevant_recovery_v2&utm_relevant_index=1)

## 1. 构建编译环境

在MacOS[1]和Linux上构建OpenJDK编译环境相对简单，对于MacOS，需要MacOS X 10.13版本以上，并安装好最新版本的XCode和Command Line Tools for XCode（在Apple Developer网站[2]上可以免费下载），这两个SDK提供了OpenJDK所需的CLang编译器以及Makefile中用到的其他外部命令。

对于Linux系统，要准备的依赖与MacOS类似，在MacOS中CLang编译器来源于XCode SDK，而Ubuntu里用户可以自行选择安装GCC或CLang来进行编译，但必须确保最低的版本为GCC 4.8或者CLang 3.2以上，官方推荐使用GCC 7.8或者CLang 9.1来完成编译。在Ubuntu系统上安装GCC的命令为：

```sh
sudo apt-get install build-essential
```

在编译过程中需要依赖FreeType、CUPS等若干第三方库，OpenJDK全部的依赖库已在表1-1中列出，读者可执行相应的安装命令完成安装。具体缺少的依赖可以在编译的提示中逐步安装即可。



## 2. 编译

需要下载的编译环境和依赖项目都齐备后，我们就可以按照默认配置来开始编译了，但通常我们编译OpenJDK的目的都不仅仅是为了得到在自己机器中诞生的编译成品，而是带着调试、定制化等需求，这样就必须了解OpenJDK提供的编译参数才行，这些参数可以使用`bash configure --help`命令查询到，笔者对它们中最有用的部分简要说明如下：

- `--with-debug-level=<level>`：设置编译的级别，可选值为release、fastdebug、slowde-bug，越往后进行的优化措施就越少，带的调试信息就越多。还有一些虚拟机调试参数必须在特定模式下才可以使用。默认值为release。
- `--enable-debug`：等效于--with-debug-level=fastdebug。
- `--with-native-debug-symbols=<method>`：确定调试符号信息的编译方式，可选值为none、internal、external、zipped。
- `--with-version-string=<string>`：设置编译JDK的版本号，譬如java-version的输出就会显示该信息。这个参数还有--with-version-<part>=<value>的形式，其中part可以是pre、opt、build、major、minor、security、patch之一，用于设置版本号的某一个部分。
- `--with-jvm-variants=<variant>[，<variant>...]`：编译特定模式（Variants）的HotSpot虚拟机，可以多个模式并存，可选值为server、client、minimal、core、zero、custom。
- `--with-jvm-features=<feature>[，<feature>...]`：针对--with-jvm-variants=custom时的自定义虚拟机特性列表（Features），可以多个特性并存，由于可选值较多，请参见help命令输出。
- `--with-target-bits=<bits>`：指明要编译32位还是64位的Java虚拟机，在64位机器上也可以通过交叉编译生成32位的虚拟机。
- `--with-<lib>=<path>`：用于指明依赖包的具体路径，通常使用在安装了多个不同版本的BootstrapJDK和依赖包的情况。其中lib的可选值包括boot-jd、freetype、cups、x、alsa、libffi、jtreg、libjpeg、giflib、libpng、lcms、zlib。
- `--with-extra-<flagtype>=<flags>`：用于设定C、C++和Java代码编译时的额外编译器参数，其中flagtype可选值为cflags、cxxflags、ldflags，分别代表C、C++和Java代码的参数。
- `--with-conf-name=<name>`：指定编译配置名称，OpenJDK支持使用不同的配置进行编译，默认会根据编译的操作系统、指令集架构、调试级别自动生成一个配置名称，譬如“linux-x86_64-server-release”，如果在这些信息都相同的情况下保存不同的编译参数配置，就需要使用这个参数来自定义配置名称。

譬如，编译FastDebug版、仅含Server模式的HotSpot虚拟机，命令应为：
```sh
bash configure --enable-debug --with-jvm-variants=server

#一般直接使用这个，无需任何参数
bash configure
```

如果一切顺利的话，就会收到配置成功的提示，并且输出调试级别，Java虚拟机的模式、特性，使用的编译器版本等配置摘要信息。

在configure命令以及后面的make命令的执行过程中，会在“build/配置名称”目录下产生如下目录结构。不常使用C/C++的读者要特别注意，如果多次编译，或者目录结构成功产生后又再次修改了配置，必须先使用“make clean”和“make dist-clean”命令清理目录，才能确保新的配置生效。编译产生的目录结构以及用途如下所示：``

```test
buildtools/：用于生成、存放编译过程中用到的工具
hotspot/：HotSpot虚拟机编译的中间文件
images/：使用make *-image产生的镜像存放在这里
jdk/：编译后产生的JDK就放在这里
support/：存放编译时产生的中间文件
test-results/：存放编译后的自动化测试结果
configure-support/：这三个目录是存放执行configure、make和test的临时文件make-support/test-support/
```

```sh
make images
```

如果在make过程中失败，可能是gcc编译器的版本原因，可以使用如下命令

```sh
#安装gcc-7编译器版本
sudo apt-get install g++-7

#切换至gcc7编译器
sudo rm -rf /usr/bin/gcc
sudo ln -s /usr/bin/gcc-7 /usr/bin/gcc
sudo rm -rf /usr/bin/g++
sudo ln -s /usr/bin/g++-7 /usr/bin/g++

# 切换至gcc9编译器
sudo rm -rf /usr/bin/gcc
sudo ln -s /usr/bin/gcc-9 /usr/bin/gcc
sudo rm -rf /usr/bin/g++
sudo ln -s /usr/bin/g++-9 /usr/bin/g++
```

依赖检查通过后便可以输入“make images”执行整个OpenJDK编译了，这里“images”是“product-images”编译目标（Target）的简写别名，这个目标的作用是编译出整个JDK镜像，除了“product-images”以外，其他编译目标还有：

```text
hotspot：只编译HotSpot虚拟机
hotspot-<variant>：只编译特定模式的HotSpot虚拟机
docs-image：产生JDK的文档镜像
test-image：产生JDK的测试镜像
all-images：相当于连续调用product、docs、test三个编译目标
bootcycle-images：编译两次JDK，其中第二次使用第一次的编译结果作为Bootstrap
JDKclean：清理make命令产生的临时文件
dist-clean：清理make和configure命令产生的临时文件
```



## 3.CLion中源码调试

### 1. 准备

源码根目录下执行命令：

```sh
make compile-commands
```

失败可以执行一次配置命令：

```sh
bash configure
```

成功后会在编译成功的jdk根目录下生成`compile-commans.json`文件，用Clion打开该文件并作为一个项目打开即可。

之后切换项目目录到源码根目录，`Tools -> Compilation Database -> Change Project Root`



### 2. 调试

配置构建目标，操作路径：`settings > Build, Exceution, Deployment > Custom Build Targets`

![](https://gitlab.com/eardh/picture/raw/main/common_img/202308142152155.png)



新增**Custom Build Application**调试 `java -version`

![](https://gitlab.com/eardh/picture/raw/main/common_img/202308142153542.png)



1. java.c文件的JavaMain()方法打断点
2. jni.cpp文件的JNI_CreateJavaVM_inner()方法打断点



### 3. 忽略SIGEGV和SIGBUS信号

这是由于本案例中CLion采用的是LLDB 进行 debug 的，会处理SIGEGV和SIGBUS信号，避免这个问题的方法是在第一次断点处，在LLDB命令行面板中输入如下命令，就可以避免这个问题

```sh
pro hand -p true -s false SIGSEGV SIGBUS
```

此时debug的输出面板中就不会再出现 Signal: SIGSEGV (signal SIGSEGV) 这样的信息了

如果每次debug都要手动运行一次这样的命令也很麻烦，可以生成一个脚本文件。在用户目录下面创建.lldbinit文件

```sh
vim ~/.lldbinit

内容如下：
br set -n main -o true -G true -C "pro hand -p true -s false SIGSEGV SIGBUS"
```

