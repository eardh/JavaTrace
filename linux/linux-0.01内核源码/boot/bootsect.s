!
! SYS_SIZE is the number of clicks (16 bytes) to be loaded.
! 0x3000 is 0x30000 bytes = 196kB, more than enough for current
! versions of linux ! SYS_SIZE ��Ҫ���صĽ�����16 �ֽ�Ϊ1 �ڣ���0x3000 ��Ϊ
1 2 3 4 5 6
0x7c00
0x0000
0x90000
0x10000
0xA0000
system ģ��
����ִ��λ����·
0x90200
! 0x30000 �ֽ�=192 kB������Linus ������ˣ������ڵ�ǰ�İ汾�ռ����㹻�ˡ�
!
SYSSIZE = 0x3000 ! ָ�������Ӻ�system ģ��Ĵ�С���μ��б�1.2 �е�92 ��˵����
! ���������һ�����Ĭ��ֵ��
!
! bootsect.s (C) 1991 Linus Torvalds
!
! bootsect.s is loaded at 0x7c00 by the bios-startup routines, and moves
! iself out of the way to address 0x90000, and jumps there.
!
! It then loads 'setup' directly after itself (0x90200), and the system
! at 0x10000, using BIOS interrupts.
!
! NOTE! currently system is at most 8*65536 bytes long. This should be no
! problem, even in the future. I want to keep it simple. This 512 kB
! kernel size should be enough, especially as this doesn't contain the
! buffer cache as in minix
!
! The loader has been made as simple as possible, and continuos
! read errors will result in a unbreakable loop. Reboot by hand. It
! loads pretty fast by getting whole sectors at a time whenever possible.
!
! ������ǰ����Щ���ֵķ��룺
! bootsect.s (C) 1991 Linus Torvalds ��Ȩ����
!
! bootsect.s ��bios-�����ӳ��������0x7c00 (31k)���������Լ�
! �Ƶ��˵�ַ0x90000 (576k)��������ת�����
!
! ��Ȼ��ʹ��BIOS �жϽ�'setup'ֱ�Ӽ��ص��Լ��ĺ���(0x90200)(576.5k)��
! ����system ���ص���ַ0x10000 ����
!
! ע��! Ŀǰ���ں�ϵͳ��󳤶�����Ϊ(8*65536)(512k)�ֽڣ���ʹ����
! ������ҲӦ��û������ġ������������ּ����ˡ�����512k ������ں˳���Ӧ��
! �㹻�ˣ�����������û����minix ��һ���������������ٻ��塣
!
! ���س����Ѿ����Ĺ����ˣ����Գ����Ķ�����������ѭ����ֻ���ֹ�������
! ֻҪ���ܣ�ͨ��һ��ȡȡ���е����������ع��̿������ĺܿ�ġ�

.globl begtext, begdata, begbss, endtext, enddata, endbss ! ������6 ��ȫ�ֱ�ʶ����
.text ! �ı��Σ�
begtext:
.data ! ���ݶΣ�
begdata:
.bss ! ��ջ�Σ�
begbss:
.text ! �ı��Σ�

SETUPLEN = 4 ! nr of setup-sectors
! setup �����������(setup-sectors)ֵ��
BOOTSEG = 0x07c0 ! original address of boot-sector
! bootsect ��ԭʼ��ַ���Ƕε�ַ������ͬ����
INITSEG = 0x9000 ! we move boot here - out of the way
! ��bootsect �Ƶ����� -- �ܿ���
SETUPSEG = 0x9020 ! setup starts here
! setup ��������￪ʼ��
SYSSEG = 0x1000 ! system loaded at 0x10000 (65536).
! system ģ����ص�0x10000��64 kB������
ENDSEG = SYSSEG + SYSSIZE ! where to stop loading
! ֹͣ���صĶε�ַ��

! ROOT_DEV: 0x000 - same type of floppy as boot.
! ���ļ�ϵͳ�豸ʹ��������ʱͬ���������豸��
! 0x301 - first partition on first drive etc
! ���ļ�ϵͳ�豸�ڵ�һ��Ӳ�̵ĵ�һ�������ϣ��ȵȣ�
ROOT_DEV = 0x306 ! ָ�����ļ�ϵͳ�豸�ǵ�2 ��Ӳ�̵ĵ�1 ������������Linux ��ʽ��Ӳ������
! ��ʽ,����ֵ�ĺ������£�
! �豸��=���豸��*256 + ���豸�ţ�Ҳ��dev_no = (major<<8) + minor ��
! �����豸�ţ�1-�ڴ�,2-����,3-Ӳ��,4-ttyx,5-tty,6-���п�,7-�������ܵ���
! 0x300 - /dev/hd0 - ����������1 ��Ӳ�̣�
! 0x301 - /dev/hd1 - ��1 ���̵ĵ�1 ��������
! ��
! 0x304 - /dev/hd4 - ��1 ���̵ĵ�4 ��������
! 0x305 - /dev/hd5 - ����������2 ��Ӳ���̣�
! 0x306 - /dev/hd6 - ��2 ���̵ĵ�1 ��������
! ��
! 0x309 - /dev/hd9 - ��2 ���̵ĵ�4 ��������
! ��linux �ں�0.95 ����Ѿ�ʹ����������ͬ�����������ˡ�

entry start ! ��֪���ӳ��򣬳����start ��ſ�ʼִ�С�
start: ! 47--56 �������ǽ�����(bootsect)��Ŀǰ��λ��0x07c0(31k)
! �ƶ���0x9000(576k)������256 �֣�512 �ֽڣ���Ȼ����ת��
! �ƶ�������go ��Ŵ���Ҳ�����������һ��䴦��
mov ax,#BOOTSEG ! ��ds �μĴ�����Ϊ0x7C0��
mov ds,ax
mov ax,#INITSEG ! ��es �μĴ�����Ϊ0x9000��
mov es,ax
mov cx,#256 ! �ƶ�����ֵ=256 �֣�
sub si,si ! Դ��ַ ds:si = 0x07C0:0x0000
sub di,di ! Ŀ�ĵ�ַ es:di = 0x9000:0x0000
rep ! �ظ�ִ�У�ֱ��cx = 0
movw ! �ƶ�1 ���֣�
jmpi go,INITSEG ! �����ת������INITSEG ָ����ת���Ķε�ַ��
go: mov ax,cs ! ��ds��es ��ss ���ó��ƶ���������ڵĶδ�(0x9000)��
mov ds,ax �����ڳ������ж�ջ����(push,pop,call)����˱������ö�ջ��
mov es,ax
! put stack at 0x9ff00. ! ����ջָ��sp ָ��0x9ff00(��0x9000:0xff00)��
mov ss,ax
mov sp,#0xFF00 ! arbitrary value >>512
! ���ڴ�����ƶ����ˣ�����Ҫ�������ö�ջ�ε�λ�á�
! sp ֻҪָ��Զ����512 ƫ�ƣ�����ַ0x90200����
! �����ԡ���Ϊ��0x90200 ��ַ��ʼ����Ҫ����setup ����
! ����ʱsetup �����ԼΪ4 �����������sp Ҫָ���
! �ڣ�0x200 + 0x200 * 4 + ��ջ��С������

! load the setup-sectors directly after the bootblock.
! Note that 'es' is already set up.
! ��bootsect ����������ż���setup ģ��Ĵ������ݡ�
! ע��es �Ѿ����ú��ˡ������ƶ�����ʱes �Ѿ�ָ��Ŀ�Ķε�ַ��0x9000����

load_setup:
! 68--77 �е���;������BIOS �ж�INT 0x13 ��setup ģ��Ӵ��̵�2 ������
! ��ʼ����0x90200 ��ʼ��������4 �������������������λ����������
! ���ԣ�û����·��INT 0x13 ��ʹ�÷������£�
! ��������
! ah = 0x02 - �������������ڴ棻al = ��Ҫ����������������
! ch = �ŵ�(����)�ŵĵ�8 λ�� cl = ��ʼ����(0-5 λ)���ŵ��Ÿ�2 λ(6-7)��
! dh = ��ͷ�ţ� dl = �������ţ������Ӳ����Ҫ��λ7����
! es:bx ??ָ�����ݻ������� ���������CF ��־��λ��
mov dx,#0x0000 ! drive 0, head 0
mov cx,#0x0002 ! sector 2, track 0
mov bx,#0x0200 ! address = 512, in INITSEG
mov ax,#0x0200+SETUPLEN ! service 2, nr of sectors
int 0x13 ! read it
jnc ok_load_setup ! ok - continue
mov dx,#0x0000
mov ax,#0x0000 ! reset the diskette
int 0x13
j load_setup

ok_load_setup:

! Get disk drive parameters, specifically nr of sectors/track
! ȡ�����������Ĳ������ر���ÿ��������������
! ȡ��������������INT 0x13 ���ø�ʽ�ͷ�����Ϣ���£�
! ah = 0x08 dl = �������ţ������Ӳ����Ҫ��λ7 Ϊ1����
! ������Ϣ��
! ���������CF ��λ������ah = ״̬�롣
! ah = 0�� al = 0�� bl = ���������ͣ�AT/PS2��
! ch = ���ŵ��ŵĵ�8 λ��cl = ÿ�ŵ����������(λ0-5)�����ŵ��Ÿ�2 λ(λ6-7)
! dh = ����ͷ���� dl = ������������
! es:di -?? �������̲�����

mov dl,#0x00
mov ax,#0x0800 ! AH=8 is get drive parameters
int 0x13
mov ch,#0x00
seg cs ! ��ʾ��һ�����Ĳ�������cs �μĴ�����ָ�Ķ��С�
mov sectors,cx ! ����ÿ�ŵ���������
mov ax,#INITSEG
mov es,ax ! ��Ϊ����ȡ���̲����жϸĵ���es ��ֵ���������¸Ļء�

! Print some inane message ! ����ʾһЩ��Ϣ('Loading system ...'�س����У���24 ���ַ�)��

mov ah,#0x03 ! read cursor pos
xor bh,bh ! �����λ�á�
int 0x10

mov cx,#24 ! ��24 ���ַ���
mov bx,#0x0007 ! page 0, attribute 7 (normal)
mov bp,#msg1 ! ָ��Ҫ��ʾ���ַ�����
mov ax,#0x1301 ! write string, move cursor
int 0x10 ! д�ַ������ƶ���ꡣ

! ok, we've written the message, now
! we want to load the system (at 0x10000) ! ���ڿ�ʼ��system ģ����ص�0x10000(64k)����

mov ax,#SYSSEG
mov es,ax ! segment of 0x010000 ! es = ���system �Ķε�ַ��
call read_it ! ��������system ģ�飬es Ϊ���������
call kill_motor ! �ر��������������Ϳ���֪����������״̬�ˡ�

! After that we check which root-device to use. If the device is
! defined (!= 0), nothing is done and the given device is used.
! Otherwise, either /dev/PS0 (2,28) or /dev/at0 (2,8), depending
! on the number of sectors that the BIOS reports currently.
! �˺����Ǽ��Ҫʹ���ĸ����ļ�ϵͳ�豸����Ƹ��豸��������Ѿ�ָ�����豸(!=0)
! ��ֱ��ʹ�ø������豸���������Ҫ����BIOS �����ÿ�ŵ���������
! ȷ������ʹ��/dev/PS0 (2,28) ���� /dev/at0 (2,8)��
! ����һ���������豸�ļ��ĺ��壺
! ��Linux �����������豸����2(�μ���43 �е�ע��)�����豸�� = type*4 + nr������
! nr Ϊ0-3 �ֱ��Ӧ����A��B��C ��D��type �����������ͣ�2??1.2M ��7??1.44M �ȣ���
! ��Ϊ7*4 + 0 = 28������ /dev/PS0 (2,28)ָ����1.44M A ������,���豸����0x021c
! ͬ�� /dev/at0 (2,8)ָ����1.2M A �����������豸����0x0208��

seg cs
mov ax,root_dev ! �����豸��
cmp ax,#0
jne root_defined
seg cs
mov bx,sectors ! ȡ�����88 �б����ÿ�ŵ������������sectors=15
! ��˵����1.2Mb �������������sectors=18����˵����
! 1.44Mb ��������Ϊ�ǿ������������������Կ϶���A ����
mov ax,#0x0208 ! /dev/ps0 - 1.2Mb
cmp bx,#15 ! �ж�ÿ�ŵ��������Ƿ�=15
je root_defined ! ������ڣ���ax �о����������������豸�š�
mov ax,#0x021c ! /dev/PS0 - 1.44Mb
cmp bx,#18
je root_defined
undef_root: ! �������һ��������ѭ������������
jmp undef_root
root_defined:
seg cs
mov root_dev,ax ! ���������豸�ű���������

! after that (everyting loaded), we jump to
! the setup-routine loaded directly after
! the bootblock:
! ���ˣ����г��򶼼�����ϣ����Ǿ���ת����
! ������bootsect �����setup ����ȥ��

jmpi 0,SETUPSEG ! ��ת��0x9020:0000(setup.s ����Ŀ�ʼ��)��
!!!! �����򵽴˾ͽ����ˡ�!!!!
! �����������ӳ���

! This routine loads the system at address 0x10000, making sure
! no 64kB boundaries are crossed. We try to load it as fast as
! possible, loading whole tracks whenever we can.
!
! in: es - starting address segment (normally 0x1000)
!
! ���ӳ���ϵͳģ����ص��ڴ��ַ0x10000 ������ȷ��û�п�Խ64KB ���ڴ�߽硣������ͼ����
! �ؽ��м��أ�ֻҪ���ܣ���ÿ�μ��������ŵ������ݡ�
! ���룺es �C ��ʼ�ڴ��ַ��ֵ��ͨ����0x1000��
sread: .word 1+SETUPLEN ! sectors read of current track
! ��ǰ�ŵ����Ѷ�������������ʼʱ�Ѿ�����1 ��������������
! bootsect ��setup ������ռ��������SETUPLEN��
head: .word 0 ! current head !��ǰ��ͷ�š�
track: .word 0 ! current track !��ǰ�ŵ��š�

read_it:
! ��������Ķ�ֵ������λ���ڴ��ַ64KB �߽紦�����������ѭ������bx �Ĵ��������ڱ�ʾ��ǰ����
! ������ݵĿ�ʼλ�á�
mov ax,es
test ax,#0x0fff
die: jne die ! es must be at 64kB boundary ! es ֵ����λ��64KB ��ַ�߽�!
xor bx,bx ! bx is starting address within segment ! bx Ϊ����ƫ��λ�á�
rp_read:
! �ж��Ƿ��Ѿ�����ȫ�����ݡ��Ƚϵ�ǰ�������Ƿ����ϵͳ����ĩ�������Ķ�(#ENDSEG)��������Ǿ�
! ��ת������ok1_read ��Ŵ����������ݡ������˳��ӳ��򷵻ء�
mov ax,es
cmp ax,#ENDSEG ! have we loaded all yet? ! �Ƿ��Ѿ�������ȫ�����ݣ�
jb ok1_read
ret
ok1_read:
! �������֤��ǰ�ŵ���Ҫ��ȡ��������������ax �Ĵ����С�
! ���ݵ�ǰ�ŵ���δ��ȡ���������Լ����������ֽڿ�ʼƫ��λ�ã��������ȫ����ȡ��Щδ����������
! �����ֽ����Ƿ�ᳬ��64KB �γ��ȵ����ơ����ᳬ��������ݴ˴�����ܶ�����ֽ���(64KB �C ����
! ƫ��λ��)��������˴���Ҫ��ȡ����������
seg cs
mov ax,sectors ! ȡÿ�ŵ���������
sub ax,sread ! ��ȥ��ǰ�ŵ��Ѷ���������
mov cx,ax ! cx = ax = ��ǰ�ŵ�δ����������
shl cx,#9 ! cx = cx * 512 �ֽڡ�
add cx,bx ! cx = cx + ���ڵ�ǰƫ��ֵ(bx)
! = �˴ζ������󣬶��ڹ�������ֽ�����
jnc ok2_read ! ��û�г���64KB �ֽڣ�����ת��ok2_read ��ִ�С�
je ok2_read
xor ax,ax ! �����ϴ˴ν����ŵ�������δ������ʱ�ᳬ��64KB�������
sub ax,bx ! ��ʱ����ܶ�����ֽ���(64KB �C ���ڶ�ƫ��λ��)����ת��
shr ax,#9 ! ����Ҫ��ȡ����������
ok2_read:
call read_track
mov cx,ax ! cx = �ôβ����Ѷ�ȡ����������
add ax,sread ! ��ǰ�ŵ����Ѿ���ȡ����������
seg cs
cmp ax,sectors ! �����ǰ�ŵ��ϵĻ�������δ��������ת��ok3_read ����
jne ok3_read
! ���ôŵ�����һ��ͷ��(1 �Ŵ�ͷ)�ϵ����ݡ�����Ѿ���ɣ���ȥ����һ�ŵ���
mov ax,#1
sub ax,head ! �жϵ�ǰ��ͷ�š�
jne ok4_read ! �����0 ��ͷ������ȥ��1 ��ͷ���ϵ��������ݡ�
inc track ! ����ȥ����һ�ŵ���
ok4_read:
mov head,ax ! ���浱ǰ��ͷ�š�
xor ax,ax ! �嵱ǰ�ŵ��Ѷ���������
ok3_read:
mov sread,ax ! ���浱ǰ�ŵ��Ѷ���������
shl cx,#9 ! �ϴ��Ѷ�������*512 �ֽڡ�
add bx,cx ! ������ǰ�������ݿ�ʼλ�á�
jnc rp_read ! ��С��64KB �߽�ֵ������ת��rp_read(156 ��)�������������ݡ�
! ���������ǰ�Σ�Ϊ����һ��������׼����
mov ax,es
add ax,#0x1000 ! ���λ�ַ����Ϊָ����һ��64KB ���ڴ档
mov es,ax
xor bx,bx ! ��������ݿ�ʼƫ��ֵ��
jmp rp_read ! ��ת��rp_read(156 ��)�������������ݡ�

! ����ǰ�ŵ���ָ����ʼ��������������������ݵ�es:bx ��ʼ�����μ���67 ���¶�BIOS ���̶��ж�
! int 0x13��ah=2 ��˵����
! al �C �����������es:bx �C ��������ʼλ�á�
read_track:
push ax
push bx
push cx
push dx
mov dx,track ! ȡ��ǰ�ŵ��š�
mov cx,sread ! ȡ��ǰ�ŵ����Ѷ���������
inc cx ! cl = ��ʼ��������
mov ch,dl ! ch = ��ǰ�ŵ��š�
mov dx,head ! ȡ��ǰ��ͷ�š�
mov dh,dl ! dh = ��ͷ�š�
mov dl,#0 ! dl = ��������(Ϊ0 ��ʾ��ǰ������)��
and dx,#0x0100 ! ��ͷ�Ų�����1��
mov ah,#2 ! ah = 2���������������ܺš�
int 0x13
jc bad_rt ! ����������ת��bad_rt��
pop dx
pop cx
pop bx
pop ax
ret
! ִ����������λ�����������жϹ��ܺ�0��������ת��read_track �����ԡ�
bad_rt: mov ax,#0
mov dx,#0
int 0x13
pop dx
pop cx
pop bx
pop ax
jmp read_track

/*
* This procedure turns off the floppy drive motor, so
* that we enter the kernel in a known state, and
* don't have to worry about it later.
*/
! ����ӳ������ڹر����������������ǽ����ں˺���������֪״̬���Ժ�Ҳ�����뵣�����ˡ�
kill_motor:
push dx
mov dx,#0x3f2 ! �������ƿ��������˿ڣ�ֻд��
mov al,#0 ! A ���������ر�FDC����ֹDMA ���ж����󣬹ر���
outb ! ��al �е����������dx ָ���Ķ˿�ȥ��
pop dx
ret

sectors:
.word 0 ! ��ŵ�ǰ��������ÿ�ŵ�����������

msg1:
.byte 13,10 ! �س������е�ASCII �롣
.ascii "Loading system ..."
.byte 13,10,13,10 ! ��24 ��ASCII ���ַ���

.org 508 ! ��ʾ�������ӵ�ַ508(0x1FC)��ʼ������root_dev
! �����������ĵ�508 ��ʼ��2 ���ֽ��С�
root_dev:
.word ROOT_DEV ! �����Ÿ��ļ�ϵͳ���ڵ��豸��(init/main.c �л���)��
boot_flag:
.word 0xAA55 ! Ӳ����Ч��ʶ��

.text
endtext:
.data
enddata:
.bss
endbss:
