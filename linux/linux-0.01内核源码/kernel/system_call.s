/*
* linux/kernel/system_call.s
*
* (C) 1991 Linus Torvalds
*/

/*
* system_call.s contains the system-call low-level handling routines.
* This also contains the timer-interrupt handler, as some of the code is
* the same. The hd- and flopppy-interrupts are also here.
*
* NOTE: This code handles signal-recognition, which happens every time
* after a timer-interrupt and after each system call. Ordinary interrupts
* don't handle signal-recognition, as that would clutter them up totally
* unnecessarily.
*
* Stack layout in 'ret_from_system_call':
*
* 0(%esp) - %eax
* 4(%esp) - %ebx
* 8(%esp) - %ecx
* C(%esp) - %edx
* 10(%esp) - %fs
* 14(%esp) - %es
* 18(%esp) - %ds
* 1C(%esp) - %eip
* 20(%esp) - %cs
* 24(%esp) - %eflags
* 28(%esp) - %oldesp
* 2C(%esp) - %oldss
*/
/*
* system_call.s �ļ�����ϵͳ����(system-call)�ײ㴦���ӳ���������Щ����Ƚ����ƣ�����
* ͬʱҲ����ʱ���жϴ���(timer-interrupt)�����Ӳ�̺����̵��жϴ������Ҳ�����
*
* ע�⣺��δ��봦���ź�(signal)ʶ����ÿ��ʱ���жϺ�ϵͳ����֮�󶼻����ʶ��һ��
* �ж��źŲ��������ź�ʶ����Ϊ���ϵͳ��ɻ��ҡ�
*
* ��ϵͳ���÷��أ�'ret_from_system_call'��ʱ��ջ�����ݼ�����19-30 �С�
*/

SIG_CHLD = 17 # ����SIG_CHLD �źţ��ӽ���ֹͣ���������

EAX = 0x00 # ��ջ�и����Ĵ�����ƫ��λ�á�
EBX = 0x04
ECX = 0x08
EDX = 0x0C
FS = 0x10
5.5 system_call.s ����
ES = 0x14
DS = 0x18
EIP = 0x1C
CS = 0x20
EFLAGS = 0x24
OLDESP = 0x28 # ������Ȩ���仯ʱ��
OLDSS = 0x2C

# ������Щ������ṹ(task_struct)�б�����ƫ��ֵ���μ�include/linux/sched.h��77 �п�ʼ��
state = 0 # these are offsets into the task-struct. # ����״̬��
counter = 4 # ��������ʱ�����(�ݼ�)���δ�����������ʱ��Ƭ��
priority = 8 // ����������������ʼ����ʱcounter=priority��Խ��������ʱ��Խ����
signal = 12 // ���ź�λͼ��ÿ������λ����һ���źţ��ź�ֵ=λƫ��ֵ+1��
sigaction = 16 # MUST be 16 (=len of sigaction) // sigaction �ṹ���ȱ�����16 �ֽڡ�
// �ź�ִ�����Խṹ�����ƫ��ֵ����Ӧ�źŽ�Ҫִ�еĲ����ͱ�־��Ϣ��
blocked = (33*16) // �������ź�λͼ��ƫ������

# ���¶�����sigaction �ṹ�е�ƫ�������μ�include/signal.h����48 �п�ʼ��
# offsets within sigaction
sa_handler = 0 // �źŴ�����̵ľ��������������
sa_mask = 4 // �ź���������
sa_flags = 8 // �źż���
sa_restorer = 12 // ���ػָ�ִ�еĵ�ַλ�á�

nr_system_calls = 72 # Linux 0.11 ���ں��е�ϵͳ����������

/*
* Ok, I get parallel printer interrupts while using the floppy for some
* strange reason. Urgel. Now I just ignore them.
*/
/*
* ���ˣ���ʹ������ʱ���յ��˲��д�ӡ���жϣ�����֡��ǣ����ڲ�������
*/
# ������ڵ㡣
.globl _system_call,_sys_fork,_timer_interrupt,_sys_execve
.globl _hd_interrupt,_floppy_interrupt,_parallel_interrupt
.globl _device_not_available, _coprocessor_error

# �����ϵͳ���úš�
.align 2 # �ڴ�4 �ֽڶ��롣
bad_sys_call:
movl $-1,%eax # eax ����-1���˳��жϡ�
iret
# ����ִ�е��ȳ�����ڡ����ȳ���schedule ��(kernel/sched.c,104)��
.align 2
reschedule:
pushl $ret_from_sys_call # ��ret_from_sys_call �ĵ�ַ��ջ��101 �У���
jmp _schedule
#### int 0x80 --linux ϵͳ������ڵ�(�����ж�int 0x80��eax ���ǵ��ú�)��
.align 2
_system_call:
cmpl $nr_system_calls-1,%eax # ���ú����������Χ�Ļ�����eax ����-1 ���˳���
ja bad_sys_call
5.5 system_call.s ����
push %ds # ����ԭ�μĴ���ֵ��
push %es
push %fs
pushl %edx # ebx,ecx,edx �з���ϵͳ������Ӧ��C ���Ժ����ĵ��ò�����
pushl %ecx # push %ebx,%ecx,%edx as parameters
pushl %ebx # to the system call
movl $0x10,%edx # set up ds,es to kernel space
mov %dx,%ds # ds,es ָ���ں����ݶ�(ȫ���������������ݶ�������)��
mov %dx,%es
movl $0x17,%edx # fs points to local data space
mov %dx,%fs # fs ָ��ֲ����ݶ�(�ֲ��������������ݶ�������)��
# �������������ĺ����ǣ����õ�ַ = _sys_call_table + %eax * 4���μ��б���˵����
# ��Ӧ��C �����е�sys_call_table ��include/linux/sys.h �У����ж�����һ������72 ��
# ϵͳ����C �������ĵ�ַ�����
call _sys_call_table(,%eax,4)
pushl %eax # ��ϵͳ���ú���ջ��
movl _current,%eax # ȡ��ǰ���񣨽��̣����ݽṹ��ַ??eax��
# ����97-100 �в鿴��ǰ���������״̬��������ھ���״̬(state ������0)��ȥִ�е��ȳ���
# ����������ھ���״̬��counter[??]ֵ����0����Ҳȥִ�е��ȳ���
cmpl $0,state(%eax) # state
jne reschedule
cmpl $0,counter(%eax) # counter
je reschedule
# ������δ���ִ�д�ϵͳ����C �������غ󣬶��ź�������ʶ����
ret_from_sys_call:
# �����б�ǰ�����Ƿ��ǳ�ʼ����task0��������򲻱ض�������ź�������Ĵ���ֱ�ӷ��ء�
# 103 ���ϵ�_task ��ӦC �����е�task[]���飬ֱ������task �൱������task[0]��
movl _current,%eax # task[0] cannot have signals
cmpl _task,%eax
je 3f # ��ǰ(forward)��ת�����3��
# ͨ����ԭ���ó������ѡ����ļ�����жϵ��ó����Ƿ��ǳ����û�������ǳ����û���ֱ��
# �˳��жϣ�����������ź����Ĵ�������Ƚ�ѡ����Ƿ�Ϊ��ͨ�û�����ε�ѡ���0x000f
# (RPL=3���ֲ�����1 ����(�����))�������������ת�˳��жϳ���
cmpw $0x0f,CS(%esp) # was old code segment supervisor ?
jne 3f
# ���ԭ��ջ��ѡ�����Ϊ0x17��Ҳ��ԭ��ջ�����û����ݶ��У�����Ҳ�˳���
cmpw $0x17,OLDSS(%esp) # was stack segment = 0x17 ?
jne 3f
# ������δ��루109-120������;������ȡ��ǰ����ṹ�е��ź�λͼ(32 λ��ÿλ����1 ���ź�)��
# Ȼ��������ṹ�е��ź����������Σ��룬������������ź�λ��ȡ����ֵ��С���ź�ֵ���ٰ�
# ԭ�ź�λͼ�и��źŶ�Ӧ��λ��λ����0������󽫸��ź�ֵ��Ϊ����֮һ����do_signal()��
# do_signal()�ڣ�kernel/signal.c,82���У����������13 ����ջ����Ϣ��
movl signal(%eax),%ebx # ȡ�ź�λͼ??ebx��ÿ1 λ����1 ���źţ���32 ���źš�
movl blocked(%eax),%ecx # ȡ���������Σ��ź�λͼ??ecx��
notl %ecx # ÿλȡ����
andl %ebx,%ecx # �����ɵ��ź�λͼ��
bsfl %ecx,%ecx # �ӵ�λ��λ0����ʼɨ��λͼ�����Ƿ���1 ��λ��
# ���У���ecx ������λ��ƫ��ֵ�����ڼ�λ0-31����
je 3f # ���û���ź�����ǰ��ת�˳���
btrl %ecx,%ebx # ��λ���źţ�ebx ����ԭsignal λͼ����
movl %ebx,signal(%eax) # ���±���signal λͼ��Ϣ??current->signal��
incl %ecx # ���źŵ���Ϊ��1 ��ʼ����(1-32)��
pushl %ecx # �ź�ֵ��ջ��Ϊ����do_signal �Ĳ���֮һ��
5.5 system_call.s ����
call _do_signal # ����C �����źŴ������(kernel/signal.c,82)
popl %eax # �����ź�ֵ��
3: popl %eax
popl %ebx
popl %ecx
popl %edx
pop %fs
pop %es
pop %ds
iret

#### int16 -- ������δ��봦��Э�����������ĳ����źš���תִ��C ����math_error()
# (kernel/math/math_emulate.c,82)�����غ���ת��ret_from_sys_call ������ִ�С�
.align 2
_coprocessor_error:
push %ds
push %es
push %fs
pushl %edx
pushl %ecx
pushl %ebx
pushl %eax
movl $0x10,%eax # ds,es ��Ϊָ���ں����ݶΡ�
mov %ax,%ds
mov %ax,%es
movl $0x17,%eax # fs ��Ϊָ��ֲ����ݶΣ������������ݶΣ���
mov %ax,%fs
pushl $ret_from_sys_call # ��������÷��صĵ�ַ��ջ��
jmp _math_error # ִ��C ����math_error()(kernel/math/math_emulate.c,37)

#### int7 -- �豸�����ڻ�Э������������(Coprocessor not available)��
# ������ƼĴ���CR0 ��EM ��־��λ����CPU ִ��һ��ESC ת��ָ��ʱ�ͻ��������жϣ�������
# �����л���������жϴ������ģ��ESC ת��ָ�169 �У���
# CR0 ��TS ��־����CPU ִ������ת��ʱ���õġ�TS ��������ȷ��ʲôʱ��Э�������е����ݣ������ģ�
# ��CPU ����ִ�е�����ƥ���ˡ���CPU ������һ��ת��ָ��ʱ����TS ��λ�ˣ��ͻ��������жϡ�
# ��ʱ��Ӧ�ûָ��������Э������ִ��״̬��165 �У����μ�(kernel/sched.c,77)�е�˵����
# ���ж����ת�Ƶ����ret_from_sys_call ��ִ����ȥ����Ⲣ�����źţ���
.align 2
_device_not_available:
push %ds
push %es
push %fs
pushl %edx
pushl %ecx
pushl %ebx
pushl %eax
movl $0x10,%eax # ds,es ��Ϊָ���ں����ݶΡ�
mov %ax,%ds
mov %ax,%es
movl $0x17,%eax # fs ��Ϊָ��ֲ����ݶΣ������������ݶΣ���
mov %ax,%fs
pushl $ret_from_sys_call # ��������ת����õķ��ص�ַ��ջ��
clts # clear TS so that we can use math
5.5 system_call.s ����
movl %cr0,%eax
testl $0x4,%eax # EM (math emulation bit)
# �������EM ������жϣ���ָ�������Э������״̬��
je _math_state_restore # ִ��C ����math_state_restore()(kernel/sched.c,77)��
pushl %ebp
pushl %esi
pushl %edi
call _math_emulate # ����C ����math_emulate(kernel/math/math_emulate.c,18)��
popl %edi
popl %esi
popl %ebp
ret # �����ret ����ת��ret_from_sys_call(101 ��)��

#### int32 -- (int 0x20) ʱ���жϴ�������ж�Ƶ�ʱ�����Ϊ100Hz(include/linux/sched.h,5)��
# ��ʱоƬ8253/8254 ����(kernel/sched.c,406)����ʼ���ġ��������jiffies ÿ10 �����1��
# ��δ��뽫jiffies ��1�����ͽ����ж�ָ���8259 ��������Ȼ���õ�ǰ��Ȩ����Ϊ��������
# C ����do_timer(long CPL)�������÷���ʱתȥ��Ⲣ�����źš�
.align 2
_timer_interrupt:
push %ds # save ds,es and put kernel data space
push %es # into them. %fs is used by _system_call
push %fs
pushl %edx # we save %eax,%ecx,%edx as gcc doesn't
pushl %ecx # save those across function calls. %ebx
pushl %ebx # is saved as we use that in ret_sys_call
pushl %eax
movl $0x10,%eax # ds,es ��Ϊָ���ں����ݶΡ�
mov %ax,%ds
mov %ax,%es
movl $0x17,%eax # fs ��Ϊָ��ֲ����ݶΣ������������ݶΣ���
mov %ax,%fs
incl _jiffies
# ���ڳ�ʼ���жϿ���оƬʱû�в����Զ�EOI������������Ҫ��ָ�������Ӳ���жϡ�
movb $0x20,%al # EOI to interrupt controller #1
outb %al,$0x20 # ����������OCW2 ��0x20 �˿ڡ�
# ����3 ���ѡ�����ȡ����ǰ��Ȩ����(0 ��3)��ѹ���ջ����Ϊdo_timer �Ĳ�����
movl CS(%esp),%eax
andl $3,%eax # %eax is CPL (0 or 3, 0=supervisor)
pushl %eax
# do_timer(CPL)ִ�������л�����ʱ�ȹ�������kernel/shched.c,305 ��ʵ�֡�
call _do_timer # 'do_timer(long CPL)' does everything from
addl $4,%esp # task switching to accounting ...
jmp ret_from_sys_call

#### ����sys_execve()ϵͳ���á�ȡ�жϵ��ó���Ĵ���ָ����Ϊ��������C ����do_execve()��
# do_execve()��(fs/exec.c,182)��
.align 2
_sys_execve:
lea EIP(%esp),%eax
pushl %eax
call _do_execve
addl $4,%esp # ��������ʱѹ��ջ��EIP ֵ��
ret
5.5 system_call.s ����

#### sys_fork()���ã����ڴ����ӽ��̣���system_call ����2��ԭ����include/linux/sys.h �С�
# ���ȵ���C ����find_empty_process()��ȡ��һ�����̺�pid�������ظ�����˵��Ŀǰ��������
# ������Ȼ�����copy_process()���ƽ��̡�
.align 2
_sys_fork:
call _find_empty_process # ����find_empty_process()(kernel/fork.c,135)��
testl %eax,%eax
js 1f
push %gs
pushl %esi
pushl %edi
pushl %ebp
pushl %eax
call _copy_process # ����C ����copy_process()(kernel/fork.c,68)��
addl $20,%esp # ������������ѹջ���ݡ�
1: ret

#### int 46 -- (int 0x2E) Ӳ���жϴ��������ӦӲ���ж�����IRQ14��
# ��Ӳ�̲�����ɻ����ͻᷢ�����ж��źš�(�μ�kernel/blk_drv/hd.c)��
# ������8259A �жϿ��ƴ�оƬ���ͽ���Ӳ���ж�ָ��(EOI)��Ȼ��ȡ����do_hd �еĺ���ָ�����edx
# �Ĵ����У�����do_hd ΪNULL�������ж�edx ����ָ���Ƿ�Ϊ�ա����Ϊ�գ����edx ��ֵָ��
# unexpected_hd_interrupt()��������ʾ������Ϣ�������8259A ��оƬ��EOI ָ�������edx ��
# ָ��ָ��ĺ���: read_intr()��write_intr()��unexpected_hd_interrupt()��
_hd_interrupt:
pushl %eax
pushl %ecx
pushl %edx
push %ds
push %es
push %fs
movl $0x10,%eax # ds,es ��Ϊ�ں����ݶΡ�
mov %ax,%ds
mov %ax,%es
movl $0x17,%eax # fs ��Ϊ���ó���ľֲ����ݶΡ�
mov %ax,%fs
# ���ڳ�ʼ���жϿ���оƬʱû�в����Զ�EOI������������Ҫ��ָ�������Ӳ���жϡ�
movb $0x20,%al
outb %al,$0xA0 # EOI to interrupt controller #1 # �ʹ�8259A��
jmp 1f # give port chance to breathe
1: jmp 1f # ��ʱ���á�
1: xorl %edx,%edx
xchgl _do_hd,%edx # do_hd ����Ϊһ������ָ�룬������ֵread_intr()��
# write_intr()������ַ��(kernel/blk_drv/hd.c)
# �ŵ�edx �Ĵ�����ͽ�do_hd ָ�������ΪNULL��
testl %edx,%edx # ���Ժ���ָ���Ƿ�ΪNull��
jne 1f # ���գ���ʹָ��ָ��C ����unexpected_hd_interrupt()��
movl $_unexpected_hd_interrupt,%edx # (kernel/blk_drv/hdc,237)��
1: outb %al,$0x20 # ����8259A �жϿ�����EOI ָ�����Ӳ���жϣ���
call *%edx # "interesting" way of handling intr.
pop %fs # �Ͼ����do_hd ָ���C ������
pop %es
pop %ds
5.5 system_call.s ����
popl %edx
popl %ecx
popl %eax
iret

#### int38 -- (int 0x26) �����������жϴ��������ӦӲ���ж�����IRQ6��
# �䴦������������Ӳ�̵Ĵ������һ����(kernel/blk_drv/floppy.c)��
# ������8259A �жϿ�������оƬ����EOI ָ�Ȼ��ȡ����do_floppy �еĺ���ָ�����eax
# �Ĵ����У�����do_floppy ΪNULL�������ж�eax ����ָ���Ƿ�Ϊ�ա���Ϊ�գ����eax ��ֵָ��
# unexpected_floppy_interrupt ()��������ʾ������Ϣ��������eax ָ��ĺ���: rw_interrupt,
# seek_interrupt,recal_interrupt,reset_interrupt ��unexpected_floppy_interrupt��
_floppy_interrupt:
pushl %eax
pushl %ecx
pushl %edx
push %ds
push %es
push %fs
movl $0x10,%eax # ds,es ��Ϊ�ں����ݶΡ�
mov %ax,%ds
mov %ax,%es
movl $0x17,%eax # fs ��Ϊ���ó���ľֲ����ݶΡ�
mov %ax,%fs
movb $0x20,%al # ����8259A �жϿ�����EOI ָ�����Ӳ���жϣ���
outb %al,$0x20 # EOI to interrupt controller #1
xorl %eax,%eax
xchgl _do_floppy,%eax # do_floppy Ϊһ����ָ�룬������ֵʵ�ʴ���C ��������
# �ŵ�eax �Ĵ�����ͽ�do_floppy ָ������ÿա�
testl %eax,%eax # ���Ժ���ָ���Ƿ�=NULL?
jne 1f # ���գ���ʹָ��ָ��C ����unexpected_floppy_interrupt()��
movl $_unexpected_floppy_interrupt,%eax
1: call *%eax # "interesting" way of handling intr.
pop %fs # �Ͼ����do_floppy ָ��ĺ�����
pop %es
pop %ds
popl %edx
popl %ecx
popl %eax
iret

#### int 39 -- (int 0x27) ���п��жϴ�����򣬶�ӦӲ���ж������ź�IRQ7��
# ���汾�ں˻�δʵ�֡�����ֻ�Ƿ���EOI ָ�
_parallel_interrupt:
pushl %eax
movb $0x20,%al
outb %al,$0x20
popl %eax
iret
