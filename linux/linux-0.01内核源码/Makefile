#
# if you want the ram-disk device, define this to be the # �����Ҫʹ��RAM ���豸�Ļ�����
# size in blocks. # �����Ĵ�С��
#
RAMDISK = #-DRAMDISK=512

AS86 =as86 -0 -a # 8086 ���������������������б��Ľ��ܡ�����Ĳ�������ֱ�
LD86 =ld86 -0 # �ǣ�-0 ����8086 Ŀ�����-a ������gas ��gld ���ּ��ݵĴ��롣

AS =gas # GNU ���������������������б��Ľ��ܡ�
LD =gld
LDFLAGS =-s -x -M # GNU ������gld ����ʱ�õ���ѡ������ǣ�-s ����ļ���ʡ����
# �еķ�����Ϣ��-x ɾ�����оֲ����ţ�-M ��ʾ��Ҫ�ڱ�׼����豸
# (��ʾ��)�ϴ�ӡ����ӳ��(link map)����ָ�����ӳ��������һ��
# �ڴ��ַӳ�������г��˳����װ�뵽�ڴ��е�λ����Ϣ������
# ������������Ϣ��
head main kernel mm fs lib
bootsect setup system
Build ����
�ں�ӳ���ļ�
Image
2.8 linux/Makefile �ļ�
# ? Ŀ���ļ���������Ϣӳ�䵽�ڴ��е�λ�ã�
# ? ����������η��ã�
# ? �����а����������ļ���Ա�������õķ��š�
CC =gcc $(RAMDISK) # gcc ��GNU C ���������������UNIX ��Ľű�(script)������ԣ�
# �����ö���ı�ʶ��ʱ������ǰ�����$���Ų���������ס��ʶ����
CFLAGS =-Wall -O -fstrength-reduce -fomit-frame-pointer \
-fcombine-regs -mstring-insns # gcc ��ѡ�ǰһ������'\'���ű�ʾ��һ�������С�
# ѡ���Ϊ��-Wall ��ӡ���о�����Ϣ��-O �Դ�������Ż���
# -fstrength-reduce �Ż�ѭ����䣻-mstring-insns ��
# Linus �Լ�Ϊgcc ���ӵ�ѡ�����ȥ����
CPP =cpp -nostdinc -Iinclude # cpp ��gcc ��ǰ(Ԥ)�������-nostdinc -Iinclude �ĺ�
# ���ǲ�Ҫ������׼��ͷ�ļ�Ŀ¼�е��ļ�������ʹ��-I
# ѡ��ָ����Ŀ¼�������ڵ�ǰĿ¼������ͷ�ļ���

#
# ROOT_DEV specifies the default root-device when making the image.
# This can be either FLOPPY, /dev/xxxx or empty, in which case the
# default of /dev/hd6 is used by 'build'.
#
ROOT_DEV=/dev/hd6 # ROOT_DEV ָ���ڴ����ں�ӳ��(image)�ļ�ʱ��ʹ�õ�Ĭ�ϸ��ļ�ϵͳ��
# �ڵ��豸�������������(FLOPPY)��/dev/xxxx ���߸ɴ���ţ�����ʱ
# build ������tools/Ŀ¼�У���ʹ��Ĭ��ֵ/dev/hd6��

ARCHIVES=kernel/kernel.o mm/mm.o fs/fs.o # kernel Ŀ¼��mm Ŀ¼��fs Ŀ¼��������Ŀ���
# ���ļ���Ϊ�˷������������ｫ������
# ARCHIVES���鵵�ļ�����ʶ����ʾ��
DRIVERS =kernel/blk_drv/blk_drv.a kernel/chr_drv/chr_drv.a # ����ַ��豸���ļ���.a ��
# ʾ���ļ��Ǹ��鵵�ļ���Ҳ������������ִ�ж����ƴ����ӳ�
# �򼯺ϵĿ��ļ���ͨ������GNU ��ar �������ɡ�ar ��GNU �Ķ�����
# �ļ�����������ڴ������޸��Լ��ӹ鵵�ļ��г�ȡ�ļ���
MATH =kernel/math/math.a # ��ѧ������ļ���
LIBS =lib/lib.a # ��lib/Ŀ¼�е��ļ����������ɵ�ͨ�ÿ��ļ���

.c.s: # make ��ʽ����ʽ��׺���򡣸���ָʾmake ���������������е�
# .c �ļ���������.s ������':'��ʾ�����Ǹù�������
$(CC) $(CFLAGS) \
-nostdinc -Iinclude -S -o $*.s $< # ָʹgcc ����ǰ��CFLAGS ��ָ����ѡ���Լ�
# ��ʹ��include/Ŀ¼�е�ͷ�ļ������ʵ��ر���󲻽��л���
# ֹͣ��-S�����Ӷ�����������ĸ���C �ļ���Ӧ�Ļ��������ʽ��
# �����ļ���Ĭ��������������Ļ������ļ���ԭC �ļ���ȥ��.c
# ������.s ��׺��-o ��ʾ���������ļ�����ʽ������$*.s����$@��
# ���Զ�Ŀ�������$<�����һ���Ⱦ����������Ｔ�Ƿ�������
# *.c ���ļ���
.s.o: # ��ʾ������.s �������ļ������.o Ŀ���ļ�����һ����ʵ
# �ָò����ľ������
$(AS) -c -o $*.o $< # ʹ��gas ������������������.o Ŀ���ļ���-c ��ʾֻ����
# ���࣬�����������Ӳ�����
.c.o: # �������棬*.c �ļ�-??*.o Ŀ���ļ���
$(CC) $(CFLAGS) \
-nostdinc -Iinclude -c -o $*.o $< # ʹ��gcc ��C �����ļ������Ŀ���ļ��������ӡ�

all: Image # all ��ʾ����Makefile ��֪������Ŀ�ꡣ���Ｔ��image �ļ���

2.8 linux/Makefile �ļ�
Image: boot/bootsect boot/setup tools/system tools/build # ˵��Ŀ�꣨Image �ļ�������
# �ֺź����4 ��Ԫ�ز������ֱ���boot/Ŀ¼�е�bootsect ��
# setup �ļ���tools/Ŀ¼�е�system ��build �ļ���
tools/build boot/bootsect boot/setup tools/system $(ROOT_DEV) > Image
sync # ��������ִ�е������һ�б�ʾʹ��tools Ŀ¼�µ�build ����
# ���������˵��������ɣ���bootsect��setup ��system �ļ�
# ��$(ROOT_DEV)Ϊ���ļ�ϵͳ�豸��װ���ں�ӳ���ļ�Image��
# �ڶ��е�sync ͬ����������ʹ�������������д�̲����³����顣

disk: Image # ��ʾdisk ���Ŀ��Ҫ��Image ������
dd bs=8192 if=Image of=/dev/PS0 # dd ΪUNIX ��׼�������һ���ļ�������ѡ��
# ����ת���͸�ʽ����bs=��ʾһ�ζ�/д���ֽ�����
# if=��ʾ������ļ���of=��ʾ��������ļ���
# ����/dev/PS0 ��ָ��һ������������(�豸�ļ�)��

tools/build: tools/build.c # ��tools Ŀ¼�µ�build.c ��������ִ�г���build��
$(CC) $(CFLAGS) \
-o tools/build tools/build.c # ��������ִ�г���build �����

boot/head.o: boot/head.s # �������������.s.o ��������head.o Ŀ���ļ���

tools/system: boot/head.o init/main.o \
$(ARCHIVES) $(DRIVERS) $(MATH) $(LIBS) # ��ʾtools Ŀ¼�е�system �ļ�
# Ҫ�ɷֺ��ұ����е�Ԫ�����ɡ�
$(LD) $(LDFLAGS) boot/head.o init/main.o \
$(ARCHIVES) \
$(DRIVERS) \
$(MATH) \
$(LIBS) \
-o tools/system > System.map # ����system ��������� > System.map ��ʾ
# gld ��Ҫ������ӳ���ض�������System.map �ļ��С�
# ����System.map �ļ�����;�μ�ע�ͺ��˵����

kernel/math/math.a: # ��ѧЭ�������ļ�math.a ����һ���ϵ�����ʵ�֡�
(cd kernel/math; make) # ����kernel/math/Ŀ¼������make ���߳���
# �����66--82 �еĺ�����˴������ơ�

kernel/blk_drv/blk_drv.a: # ���豸�����ļ�blk_drv.a
(cd kernel/blk_drv; make)

kernel/chr_drv/chr_drv.a: # �ַ��豸�����ļ�chr_drv.a
(cd kernel/chr_drv; make)

kernel/kernel.o: # �ں�Ŀ��ģ��kernel.o
(cd kernel; make)

mm/mm.o: # �ڴ����ģ��mm.o
(cd mm; make)

fs/fs.o: # �ļ�ϵͳĿ��ģ��fs.o
(cd fs; make)

lib/lib.a: # �⺯��lib.a
2.8 linux/Makefile �ļ�
(cd lib; make)

boot/setup: boot/setup.s # ���￪ʼ��������ʹ��8086 ����������
$(AS86) -o boot/setup.o boot/setup.s # ��setup.s �ļ����б�������setup �ļ���
$(LD86) -s -o boot/setup boot/setup.o # -s ѡ���ʾҪȥ��Ŀ���ļ��еķ�����Ϣ��

boot/bootsect: boot/bootsect.s # ͬ�ϡ�����bootsect.o ���������顣
$(AS86) -o boot/bootsect.o boot/bootsect.s
$(LD86) -s -o boot/bootsect boot/bootsect.o

tmp.s: boot/bootsect.s tools/system # ��92--95 �����е���������bootsect.s ����ͷ���
# һ���й�system �ļ�������Ϣ���������������ɺ��С�SYSSIZE = system �ļ�ʵ�ʳ��ȡ�
# һ����Ϣ��tmp.s �ļ���Ȼ��bootsect.s �ļ���������ȡ��system ���ȵķ����ǣ�
# ������������ls ��system �ļ����г��б���ʾ����grep ����ȡ���б������ļ��ֽ����ֶ�
# ��Ϣ�������򱣴���tmp.s ��ʱ�ļ��С�cut �������ڼ����ַ�����tr ����ȥ����β�Ļس�����
# ���У�(ʵ�ʳ��� + 15)/16 ���ڻ���á��ڡ���ʾ�ĳ�����Ϣ��1 �� = 16 �ֽڡ�
(echo -n "SYSSIZE = (";ls -l tools/system | grep system \
| cut -c25-31 | tr '\012' ' '; echo "+ 15 ) / 16") > tmp.s
cat boot/bootsect.s >> tmp.s

clean: # ��ִ��'make clean'ʱ���ͻ�ִ��98--103 ���ϵ����ȥ�����б����������ɵ��ļ���
# 'rm'���ļ�ɾ�����ѡ��-f �����Ǻ��Բ����ڵ��ļ������Ҳ���ʾɾ����Ϣ��
rm -f Image System.map tmp_make core boot/bootsect boot/setup
rm -f init/*.o tools/system tools/build boot/*.o
(cd mm;make clean) # ����mm/Ŀ¼��ִ�и�Ŀ¼Makefile �ļ��е�clean ����
(cd fs;make clean)
(cd kernel;make clean)
(cd lib;make clean)

backup: clean # �ù�������ִ�������clean ����Ȼ���linux/Ŀ¼����ѹ��������
# backup.Z ѹ���ļ���'cd .. '��ʾ�˵�linux/����һ��������Ŀ¼��
# 'tar cf - linux'��ʾ��linux/Ŀ¼ִ��tar �鵵����-cf ��ʾ��Ҫ����
# �µĹ鵵�ļ� '| compress -'��ʾ��tar �����ִ��ͨ���ܵ�����('|')
# ���ݸ�ѹ������compress������ѹ�������������backup.Z �ļ���
(cd .. ; tar cf - linux | compress - > backup.Z)
sync # ��ʹ�������������д�̲����´��̳����顣

dep:
# ��Ŀ���������ڸ��ļ�֮���������ϵ����������Щ������ϵ��Ϊ�˸�make ����ȷ���Ƿ���ҪҪ
# �ؽ�һ��Ŀ�����ġ����統ĳ��ͷ�ļ����Ķ�����make ��ͨ�����ɵ�������ϵ�����±������
# ͷ�ļ��йص�����*.c �ļ������巽�����£�
# ʹ���ַ����༭����sed ��Makefile �ļ������Ｔ���Լ������д������Ϊɾ��Makefile
# �ļ���'### Dependencies'�к���������У������118 ��ʼ���У���������tmp_make
# ��ʱ�ļ���Ҳ��110 �е����ã���Ȼ���init/Ŀ¼�µ�ÿһ��C �ļ�����ʵֻ��һ���ļ�
# main.c��ִ��gcc Ԥ���������-M ��־����Ԥ��������������ÿ��Ŀ���ļ�����ԵĹ���
# ������Щ�������make �﷨������ÿһ��Դ�ļ���Ԥ����������һ��make ��������
# ��ʽ����ӦԴ�����ļ���Ŀ���ļ���������������ϵ--��Դ�ļ��а���������ͷ�ļ��б�
# 111 ���е�$$i ʵ������$($i)����˼������$i �����ǰ���shell ������ֵ��
# Ȼ���Ԥ����������ӵ���ʱ�ļ�tmp_make �У�Ȼ�󽫸���ʱ�ļ����Ƴ��µ�Makefile �ļ���
sed '/\#\#\# Dependencies/q' < Makefile > tmp_make
(for i in init/*.c;do echo -n "init/";$(CPP) -M $$i;done) >> tmp_make
cp tmp_make Makefile
(cd fs; make dep) # ��fs/Ŀ¼�µ�Makefile �ļ�Ҳ��ͬ���Ĵ���
2.8 linux/Makefile �ļ�
- 30 -
(cd kernel; make dep)
(cd mm; make dep)

### Dependencies:
init/main.o : init/main.c include/unistd.h include/sys/stat.h \
include/sys/types.h include/sys/times.h include/sys/utsname.h \
include/utime.h include/time.h include/linux/tty.h include/termios.h \
include/linux/sched.h include/linux/head.h include/linux/fs.h \
include/linux/mm.h include/signal.h include/asm/system.h include/asm/io.h \
include/stddef.h include/stdarg.h include/fcntl.h
