/*
* linux/boot/head.s
*
* (C) 1991 Linus Torvalds
*/

/*
* head.s contains the 32-bit startup code.
*
* NOTE!!! Startup happens at absolute address 0x00000000, which is also where
* the page directory will exist. The startup code will be overwritten by
* the page directory.
*/
/*
* head.s ����32 λ�������롣
* ע��!!! 32 λ���������ǴӾ��Ե�ַ0x00000000 ��ʼ�ģ�����Ҳͬ����ҳĿ¼�����ڵĵط���
* ���������������뽫��ҳĿ¼���ǵ���
*/
.text
.globl _idt,_gdt,_pg_dir,_tmp_floppy_area
_pg_dir: # ҳĿ¼�����������
startup_32: # 18-22 �����ø������ݶμĴ�����
movl $0x10,%eax # ����GNU �����˵��ÿ��ֱ����Ҫ��'$'��ʼ�������Ǳ�ʾ��ַ��
# ÿ���Ĵ�������Ҫ��'%'��ͷ��eax ��ʾ��32 λ��ax �Ĵ�����
# �ٴ�ע��!!! �����Ѿ�����32 λ����ģʽ����������$0x10 �����ǰѵ�ַ0x10 װ�����
# �μĴ�������������ʵ��ȫ�ֶ����������е�ƫ��ֵ�����߸���ȷ��˵��һ������������
# ��ѡ������й�ѡ�����˵����μ�setup.s ��193 ���µ�˵��������$0x10 �ĺ���������
# ��Ȩ��0(λ0-1=0)��ѡ��ȫ����������(λ2=0)��ѡ����е�2 ��(λ3-15=2)��������ָ
�ڵ�ǰ��Linux ����ϵͳ�У�gas ��gld �Ѿ��ֱ����Ϊas ��ld��
# ����е����ݶ�����������������ľ�����ֵ�μ�ǰ��setup.s ��212��213 �У�
# �������ĺ����ǣ���ds,es,fs,gs �е�ѡ���Ϊsetup.s �й�������ݶΣ�ȫ�ֶ���������
# �ĵ�2 �=0x10��������ջ���������ݶ��е�_stack_start �����ڣ�Ȼ��ʹ���µ��ж�����
# �����ȫ�ֶ�������.�µ�ȫ�ֶ��������г�ʼ������setup.s �е���ȫһ����
mov %ax,%ds
mov %ax,%es
mov %ax,%fs
mov %ax,%gs
lss _stack_start,%esp # ��ʾ_stack_start??ss:esp������ϵͳ��ջ��
# stack_start ������kernel/sched.c��69 �С�
call setup_idt # ���������ж����������ӳ���
call setup_gdt # ��������ȫ�����������ӳ���
movl $0x10,%eax # reload all the segment registers
mov %ax,%ds # after changing gdt. CS was already
mov %ax,%es # reloaded in 'setup_gdt'
mov %ax,%fs # ��Ϊ�޸���gdt��������Ҫ����װ�����еĶμĴ�����
mov %ax,%gs # CS ����μĴ����Ѿ���setup_gdt �����¼��ع��ˡ�
lss _stack_start,%esp
# 32-36 �����ڲ���A20 ��ַ���Ƿ��Ѿ����������õķ��������ڴ��ַ0x000000 ��д������
# һ����ֵ��Ȼ���ڴ��ַ0x100000(1M)���Ƿ�Ҳ�������ֵ�����һֱ��ͬ�Ļ�����һֱ
# �Ƚ���ȥ��Ҳ����ѭ������������ʾ��ַA20 ��û��ѡͨ������ں˾Ͳ���ʹ��1M �����ڴ档
xorl %eax,%eax
1: incl %eax # check that A20 really IS enabled
movl %eax,0x000000 # loop forever if it isn't
cmpl %eax,0x100000
je 1b # '1b'��ʾ���(backward)��ת�����1 ȥ��33 �У���
# ����'5f'���ʾ��ǰ(forward)��ת�����5 ȥ��
/*
* NOTE! 486 should set bit 16, to check for write-protect in supervisor
* mode. Then it would be unnecessary with the "verify_area()"-calls.
* 486 users probably want to set the NE (#5) bit also, so as to use
* int 16 for math errors.
*/
/*
* ע��! ��������γ����У�486 Ӧ�ý�λ16 ��λ���Լ���ڳ����û�ģʽ�µ�д����,
* �˺�"verify_area()"�����оͲ���Ҫ�ˡ�486 ���û�ͨ��Ҳ���뽫NE(#5)��λ���Ա�
* ����ѧЭ�������ĳ���ʹ��int 16��
*/
# ������γ���43-65�����ڼ����ѧЭ������оƬ�Ƿ���ڡ��������޸Ŀ��ƼĴ���CR0����
# �������Э�������������ִ��һ��Э������ָ��������Ļ���˵��Э������оƬ�����ڣ�
# ��Ҫ����CR0 �е�Э����������λEM��λ2��������λЭ���������ڱ�־MP��λ1����
movl %cr0,%eax # check math chip
andl $0x80000011,%eax # Save PG,PE,ET
/* "orl $0x10020,%eax" here for 486 might be good */
orl $2,%eax # set MP
movl %eax,%cr0
call check_x87
jmp after_page_tables # ��ת��135 �С�

/*
* We depend on ET to be correct. This checks for 287/387.
*/
/*
* ����������ET ��־����ȷ�������287/387 �������
*/
check_x87:
fninit
fstsw %ax
cmpb $0,%al
je 1f /* no coprocessor: have to set bits */
movl %cr0,%eax # ������ڵ�����ǰ��ת�����1 ���������дcr0��
xorl $6,%eax /* reset MP, set EM */
movl %eax,%cr0
ret
.align 2 # ����".align 2"�ĺ�����ָ�洢�߽���������"2"��ʾ��������ַ���2 λΪ�㣬
# ����4 �ֽڷ�ʽ�����ڴ��ַ��
1: .byte 0xDB,0xE4 /* fsetpm for 287, ignored by 387 */ # 287 Э�������롣
ret

/*
* setup_idt
*
* sets up a idt with 256 entries pointing to
* ignore_int, interrupt gates. It then loads
* idt. Everything that wants to install itself
* in the idt-table may do so themselves. Interrupts
* are enabled elsewhere, when we can be relatively
* sure everything is ok. This routine will be over-
* written by the page tables.
*/
/*
* ��������������ж����������ӳ��� setup_idt
*
* ���ж���������idt ���óɾ���256 �������ָ��ignore_int �ж��š�Ȼ������ж�
* ��������Ĵ���(��lidt ָ��)������ʵ�õ��ж����Ժ��ٰ�װ���������������ط���Ϊһ��
* ������ʱ�ٿ����жϡ����ӳ��򽫻ᱻҳ���ǵ���
*/
# �ж����������е�����ȻҲ��8 �ֽ���ɣ������ʽ��ȫ�ֱ��еĲ�ͬ������Ϊ��������
# (Gate Descriptor)������0-1,6-7 �ֽ���ƫ������2-3 �ֽ���ѡ�����4-5 �ֽ���һЩ��־��
setup_idt:
lea ignore_int,%edx # ��ignore_int ����Ч��ַ��ƫ��ֵ��ֵ??edx �Ĵ���
movl $0x00080000,%eax # ��ѡ���0x0008 ����eax �ĸ�16 λ�С�
movw %dx,%ax /* selector = 0x0008 = cs */
# ƫ��ֵ�ĵ�16 λ����eax �ĵ�16 λ�С���ʱeax ����
#����������4 �ֽڵ�ֵ��
movw $0x8E00,%dx /* interrupt gate - dpl=0, present */
# ��ʱedx ��������������4 �ֽڵ�ֵ��
lea _idt,%edi # _idt ���ж���������ĵ�ַ��
mov $256,%ecx
rp_sidt:
movl %eax,(%edi) # �����ж���������������С�
movl %edx,4(%edi)
addl $8,%edi # edi ָ�������һ�
dec %ecx
jne rp_sidt
lidt idt_descr # �����ж���������Ĵ���ֵ��
ret

/*
* setup_gdt
*
* This routines sets up a new gdt and loads it.
* Only two entries are currently built, the same
* ones that were built in init.s. The routine
* is VERY complicated at two whole lines, so this
* rather long comment is certainly needed :-).
* This routine will beoverwritten by the page tables.
*/
/*
* ����ȫ������������ setup_gdt
* ����ӳ�������һ���µ�ȫ����������gdt�������ء���ʱ�����������������ǰ
* ���һ�������ӳ���ֻ�����У����ǳ��ġ����ӣ����Ե�Ȼ��Ҫ��ô����ע����?��
setup_gdt:
lgdt gdt_descr # ����ȫ����������Ĵ���(���������úã���232-238 ��)��
ret

/*
* I put the kernel page tables right after the page directory,
* using 4 of them to span 16 Mb of physical memory. People with
* more than 16MB will have to expand this.
*/
/* Linus ���ں˵��ڴ�ҳ��ֱ�ӷ���ҳĿ¼֮��ʹ����4 ������Ѱַ16 Mb �������ڴ档
* ������ж���16 Mb ���ڴ棬����Ҫ��������������޸ġ�
*/
# ÿ��ҳ��Ϊ4 Kb �ֽڣ���ÿ��ҳ������Ҫ4 ���ֽڣ����һ��ҳ�����Դ��1000 �����
# ���һ������Ѱַ4 Kb �ĵ�ַ�ռ䣬��һ��ҳ��Ϳ���Ѱַ4 Mb �������ڴ档
# ҳ����ĸ�ʽΪ�����ǰ0-11 λ���һЩ��־�����Ƿ����ڴ���(P λ0)����д���(R/W λ1)��
# ��ͨ�û����ǳ����û�ʹ��(U/S λ2)���Ƿ��޸Ĺ�(�Ƿ�����)(D λ6)�ȣ������λ12-31 ��
# ҳ���ַ������ָ��һҳ�ڴ��������ʼ��ַ��
.org 0x1000 # ��ƫ��0x1000 ����ʼ�ǵ�1 ��ҳ��ƫ��0 ��ʼ�������ҳ��Ŀ¼����
pg0:

.org 0x2000
pg1:

.org 0x3000
pg2:

.org 0x4000
pg3:

.org 0x5000 # ����������ڴ����ݿ��ƫ��0x5000 ����ʼ��
/*
* tmp_floppy_area is used by the floppy-driver when DMA cannot
* reach to a buffer-block. It needs to be aligned, so that it isn't
* on a 64kB border.
*/
/* ��DMA��ֱ�Ӵ洢�����ʣ����ܷ��ʻ����ʱ�������tmp_floppy_area �ڴ��
* �Ϳɹ�������������ʹ�á����ַ��Ҫ��������������Ͳ����Խ64kB �߽硣
*/
_tmp_floppy_area:
.fill 1024,1,0 # ������1024 �ÿ��1 �ֽڣ������ֵ0��

# �����⼸����ջ����(pushl)����Ϊ����/init/main.c ����ͷ�����׼����
# ǰ��3 ����ջָ�֪����ʲô�õģ�Ҳ����Linus �����ڵ���ʱ�ܿ���������õ�?��
# 139 �е���ջ������ģ�����main.c ����ʱ���Ƚ����ص�ַ��ջ�Ĳ������������
# main.c ��������˳�ʱ���ͻ᷵�ص�����ı��L6 ������ִ����ȥ��Ҳ����ѭ����
# 140 �н�main.c �ĵ�ַѹ���ջ�������������÷�ҳ����setup_paging��������
# ִ��'ret'����ָ��ʱ�ͻὫmain.c ����ĵ�ַ������ջ����ȥִ��main.c ����ȥ�ˡ�
after_page_tables:
pushl $0 # These are the parameters to main :-)
pushl $0 # ��Щ�ǵ���main ����Ĳ�����ָinit/main.c����
pushl $0
pushl $L6 # return address for main, if it decides to.
pushl $_main # '_main'�Ǳ�������main ���ڲ���ʾ������
jmp setup_paging # ��ת����198 �С�
L6:
jmp L6 # main should never return here, but
# just in case, we know what happens.

/* This is the default interrupt "handler" :-) */
/* ������Ĭ�ϵ��жϡ����������? */
int_msg:
.asciz "Unknown interrupt\n\r" # �����ַ�����δ֪�ж�(�س�����)����
.align 2 # ��4 �ֽڷ�ʽ�����ڴ��ַ��
ignore_int:
pushl %eax
pushl %ecx
pushl %edx
push %ds # ������ע�⣡��ds,es,fs,gs ����Ȼ��16 λ�ļĴ���������ջ��
# ��Ȼ����32 λ����ʽ��ջ��Ҳ����Ҫռ��4 ���ֽڵĶ�ջ�ռ䡣
push %es
push %fs
movl $0x10,%eax # �ö�ѡ�����ʹds,es,fs ָ��gdt ���е����ݶΣ���
mov %ax,%ds
mov %ax,%es
mov %ax,%fs
pushl $int_msg # �ѵ���printk �����Ĳ���ָ�루��ַ����ջ��
call _printk # �ú�����/kernel/printk.c �С�
# '_printk'��printk �����ģ���е��ڲ���ʾ����
popl %eax
pop %fs
pop %es
pop %ds
popl %edx
popl %ecx
popl %eax
iret # �жϷ��أ����жϵ���ʱѹ��ջ��CPU ��־�Ĵ�����32 λ��ֵҲ��������


/*
* Setup_paging
*
* This routine sets up paging by setting the page bit
* in cr0. The page tables are set up, identity-mapping
* the first 16MB. The pager assumes that no illegal
* addresses are produced (ie >4Mb on a 4Mb machine).
*
* NOTE! Although all physical memory should be identity
* mapped by this routine, only the kernel page functions
* use the >1Mb addresses directly. All "normal" functions
* use just the lower 1Mb, or the local data space, which
* will be mapped to some other place - mm keeps track of
* that.
*
* For those with more memory than 16 Mb - tough luck. I've
* not got it, why should you :-) The source is here. Change
* it. (Seriously - it shouldn't be too difficult. Mostly
* change some constants etc. I left it at 16Mb, as my machine
* even cannot be extended past that (ok, but it was cheap :-)
* I've tried to show which constants to change by having
* some kind of marker at them (search for "16Mb"), but I
* won't guarantee that's all :-( )
*/
/*
* ����ӳ���ͨ�����ÿ��ƼĴ���cr0 �ı�־��PG λ31�����������ڴ�ķ�ҳ�����ܣ�
* �����ø���ҳ��������ݣ��Ժ��ӳ��ǰ16 MB �������ڴ档��ҳ���ٶ���������Ƿ���
* ��ַӳ�䣨Ҳ����ֻ��4Mb �Ļ��������ó�����4Mb ���ڴ��ַ����
* ע�⣡�������е������ַ��Ӧ��������ӳ�����к��ӳ�䣬��ֻ���ں�ҳ���������
* ֱ��ʹ��>1Mb �ĵ�ַ�����С�һ�㡱������ʹ�õ���1Mb �ĵ�ַ�ռ䣬������ʹ�þֲ�����
* �ռ䣬��ַ�ռ佫��ӳ�䵽����һЩ�ط�ȥ -- mm(�ڴ�������)�������Щ�µġ�
* ������Щ�ж���16Mb �ڴ�ļһ� - ̫�����ˣ��һ�û�У�Ϊʲô�����?������������
* ���������޸İɡ���ʵ���ϣ��Ⲣ��̫���ѵġ�ͨ��ֻ���޸�һЩ�����ȡ��Ұ�������Ϊ
* 16Mb����Ϊ�ҵĻ�������ô�����������ܳ���������ޣ���Ȼ���ҵĻ����ܱ��˵�?����
* ���Ѿ�ͨ������ĳ���־��������Ҫ�Ķ��ĵط���������16Mb���������Ҳ��ܱ�֤����Щ
* �Ķ�������??����
*/
.align 2 # ��4 �ֽڷ�ʽ�����ڴ��ַ�߽硣
setup_paging: # ���ȶ�5 ҳ�ڴ棨1 ҳĿ¼ + 4 ҳҳ������
movl $1024*5,%ecx /* 5 pages - pg_dir+4 page tables */
xorl %eax,%eax
xorl %edi,%edi /* pg_dir is at 0x000 */
# ҳĿ¼��0x000 ��ַ��ʼ��
cld;rep;stosl
# ����4 ������ҳĿ¼�е�����ǹ���4 ��ҳ������ֻ������4 �
# ҳĿ¼��Ľṹ��ҳ������Ľṹһ����4 ���ֽ�Ϊ1 ��μ�����113 ���µ�˵����
# "$pg0+7"��ʾ��0x00001007����ҳĿ¼���еĵ�1 �
# ���1 ��ҳ�����ڵĵ�ַ = 0x00001007 & 0xfffff000 = 0x1000��
# ��1 ��ҳ������Ա�־ = 0x00001007 & 0x00000fff = 0x07����ʾ��ҳ���ڡ��û��ɶ�д��
movl $pg0+7,_pg_dir /* set present bit/user r/w */
movl $pg1+7,_pg_dir+4 /* --------- " " --------- */
movl $pg2+7,_pg_dir+8 /* --------- " " --------- */
movl $pg3+7,_pg_dir+12 /* --------- " " --------- */
# ����6 ����д4 ��ҳ��������������ݣ����У�4(ҳ��)*1024(��/ҳ��)=4096 ��(0 - 0xfff)��
# Ҳ����ӳ�������ڴ� 4096*4Kb = 16Mb��
# ÿ��������ǣ���ǰ����ӳ��������ڴ��ַ + ��ҳ�ı�־�������Ϊ7����
# ʹ�õķ����Ǵ����һ��ҳ������һ�ʼ������˳����д��һ��ҳ������һ����ҳ���е�
# λ����1023*4 = 4092��������һҳ�����һ���λ�þ���$pg3+4092��
movl $pg3+4092,%edi # edi??���һҳ�����һ�
movl $0xfff007,%eax /* 16Mb - 4096 + 7 (r/w user,p) */
# ���1 ���Ӧ�����ڴ�ҳ��ĵ�ַ��0xfff000��
# �������Ա�־7����Ϊ0xfff007.
std # ����λ��λ��edi ֵ�ݼ�(4 �ֽ�)��
1: stosl /* fill pages backwards - more efficient :-) */
subl $0x1000,%eax # ÿ��д��һ������ֵַ��0x1000��
jge 1b # ���С��0 ��˵��ȫ��д���ˡ�
# ����ҳĿ¼��ַ�Ĵ���cr3 ��ֵ��ָ��ҳĿ¼��
xorl %eax,%eax /* pg_dir is at 0x0000 */ # ҳĿ¼����0x0000 ����
movl %eax,%cr3 /* cr3 - page directory start */
# ��������ʹ�÷�ҳ����cr0 ��PG ��־��λ31��
movl %cr0,%eax
orl $0x80000000,%eax # ����PG ��־��
movl %eax,%cr0 /* set paging (PG) bit */
ret /* this also flushes prefetch-queue */
# �ڸı��ҳ�����־��Ҫ��ʹ��ת��ָ��ˢ��Ԥȡָ����У������õ��Ƿ���ָ��ret��
# �÷���ָ�����һ�������ǽ���ջ�е�main ����ĵ�ַ����������ʼ����/init/main.c ����
# �����򵽴����������ˡ�

.align 2 # ��4 �ֽڷ�ʽ�����ڴ��ַ�߽硣
.word 0
idt_descr: #����������lidt ָ���6 �ֽڲ����������ȣ���ַ��
.word 256*8-1 # idt contains 256 entries
.long _idt
.align 2
.word 0
gdt_descr: # ����������lgdt ָ���6 �ֽڲ����������ȣ���ַ��
.word 256*8-1 # so does gdt (not that that's any
.long _gdt # magic number, but it works for me :^)

.align 3 # ��8 �ֽڷ�ʽ�����ڴ��ַ�߽硣
_idt: .fill 256,8,0 # idt is uninitialized # 256 �ÿ��8 �ֽڣ���0��

# ȫ�ֱ�ǰ4 ��ֱ��ǿ�����ã�������������������ݶ���������ϵͳ��������������
# ϵͳ��������linux û�����ô������滹Ԥ����252 ��Ŀռ䣬���ڷ��������������
# �ֲ�������(LDT)�Ͷ�Ӧ������״̬��TSS ����������
# (0-nul, 1-cs, 2-ds, 3-sys, 4-TSS0, 5-LDT0, 6-TSS1, 7-LDT1, 8-TSS2 etc...)
_gdt: .quad 0x0000000000000000 /* NULL descriptor */
.quad 0x00c09a0000000fff /* 16Mb */ # �������󳤶�16M��
.quad 0x00c0920000000fff /* 16Mb */ # ���ݶ���󳤶�16M��
.quad 0x0000000000000000 /* TEMPORARY - don't use */
.fill 252,8,0 /* space for LDT's and TSS's etc */
