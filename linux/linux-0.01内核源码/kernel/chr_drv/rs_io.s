/*
* linux/kernel/rs_io.s
*
* (C) 1991 Linus Torvalds
*/

/*
* rs_io.s
*
* This module implements the rs232 io interrupts.
*/
/*
* �ó���ģ��ʵ��rs232 ��������жϴ������
*/

.text
.globl _rs1_interrupt,_rs2_interrupt

// size �Ƕ�д���л��������ֽڳ��ȡ�
size = 1024 /* must be power of two ! ������2 �Ĵη�������
and must match the value ��tty_io.c �е�ֵƥ��!
in tty_io.c!!! */

/* these are the offsets into the read/write buffer structures */
/* ������Щ�Ƕ�д����ṹ�е�ƫ���� */
// ��Ӧ������include/linux/tty.h �ļ���tty_queue �ṹ�и�������ƫ������
rs_addr = 0 // ���ж˿ں��ֶ�ƫ�ƣ��˿ں���0x3f8 ��0x2f8����
head = 4 // ��������ͷָ���ֶ�ƫ�ơ�
tail = 8 // ��������βָ���ֶ�ƫ�ơ�
proc_list = 12 // �ȴ��û���Ľ����ֶ�ƫ�ơ�
buf = 16 // �������ֶ�ƫ�ơ�

startup = 256 /* chars left in write queue when we restart it */
/* ��д�����ﻹʣ256 ���ַ��ռ�(WAKEUP_CHARS)ʱ�����ǾͿ���д */

/*
* These are the actual interrupt routines. They look where
* the interrupt is coming from, and take appropriate action.
*/
/*
* ��Щ��ʵ�ʵ��жϳ��򡣳������ȼ���жϵ���Դ��Ȼ��ִ����Ӧ
* �Ĵ���
*/
.align 2
//// ���ж˿�1 �жϴ��������ڵ㡣
_rs1_interrupt:
pushl $_table_list+8 // tty ���ж�Ӧ����1 �Ķ�д����ָ��ĵ�ַ��ջ(tty_io.c��99)��
jmp rs_int
.align 2
//// ���ж˿�2 �жϴ��������ڵ㡣
_rs2_interrupt:
pushl $_table_list+16 // tty ���ж�Ӧ����2 �Ķ�д�������ָ��ĵ�ַ��ջ��
rs_int:
pushl %edx
pushl %ecx
pushl %ebx
pushl %eax
push %es
push %ds /* as this is an interrupt, we cannot */
pushl $0x10 /* know that bs is ok. Load it */
pop %ds /* ��������һ���жϳ������ǲ�֪��ds �Ƿ���ȷ��*/
pushl $0x10 /* ���Լ�������(��ds��es ָ���ں����ݶ� */
pop %es
movl 24(%esp),%edx // ���������ָ���ַ����edx �Ĵ�����
// Ҳ��35 ��39 ��������ѹ���ջ�ĵ�ַ��
movl (%edx),%edx // ȡ������ָ��(��ַ)??edx��
movl rs_addr(%edx),%edx // ȡ����1 �Ķ˿ں�??edx��
addl $2,%edx /* interrupt ident. reg */ /* edx ָ���жϱ�ʶ�Ĵ��� */
rep_int: // �жϱ�ʶ�Ĵ����˿���0x3fa��0x2fa�����μ��Ͻ��б����Ϣ��
xorl %eax,%eax // eax ���㡣
inb %dx,%al // ȡ�жϱ�ʶ�ֽڣ������ж��ж���Դ(��4 ���ж����)��
testb $1,%al // �����ж����޴�������ж�(λ0=1 ���жϣ�=0 ���ж�)��
jne end // ���޴������жϣ�����ת���˳�����end��
cmpb $6,%al /* this shouldn't happen, but ... */ /* �ⲻ�ᷢ�������ǡ�*/
ja end // al ֵ>6? ������ת��end��û������״̬����
movl 24(%esp),%ecx // ��ȡ�������ָ���ַ??ecx��
pushl %edx // ���˿ں�0x3fa(0x2fa)��ջ��
subl $2,%edx // 0x3f8(0x2f8)��
call jmp_table(,%eax,2) /* NOTE! not *4, bit0 is 0 already */ /* ����4��λ0 ����0*/
// ���������ָ�����д������ж�ʱ��al ��λ0=0��λ2-1 ���ж����ͣ�����൱���Ѿ����ж�����
// ����2�������ٳ�2���õ���ת���Ӧ���ж����͵�ַ������ת������ȥ����Ӧ����
popl %edx // �����жϱ�ʶ�Ĵ����˿ں�0x3fa����0x2fa����
jmp rep_int // ��ת�������ж����޴������жϲ���������
end: movb $0x20,%al // ���жϿ��������ͽ����ж�ָ��EOI��
outb %al,$0x20 /* EOI */
pop %ds
pop %es
popl %eax
popl %ebx
popl %ecx
popl %edx
addl $4,%esp # jump over _table_list entry # �����������ָ���ַ��
iret

// ���ж����ʹ�������ַ��ת������4 ���ж���Դ��
// modem ״̬�仯�жϣ�д�ַ��жϣ����ַ��жϣ���·״̬�������жϡ�
jmp_table:
.long modem_status,write_char,read_char,line_status

.align 2
modem_status:
addl $6,%edx /* clear intr by reading modem status reg */
inb %dx,%al /* ͨ����modem ״̬�Ĵ������и�λ(0x3fe) */
ret

.align 2
line_status:
addl $5,%edx /* clear intr by reading line status reg. */
inb %dx,%al /* ͨ������·״̬�Ĵ������и�λ(0x3fd) */
ret

.align 2
read_char:
inb %dx,%al /* ��ȡ�ַ�??al��
movl %ecx,%edx /* ��ǰ���ڻ������ָ���ַ??edx��
subl $_table_list,%edx // �������ָ�����ַ - ��ǰ���ڶ���ָ���ַ??edx��
shrl $3,%edx // ��ֵ/8�����ڴ���1 ��1�����ڴ���2 ��2��
movl (%ecx),%ecx # read-queue # ȡ��������нṹ��ַ??ecx��
movl head(%ecx),%ebx // ȡ�������л���ͷָ��??ebx��
movb %al,buf(%ecx,%ebx) // ���ַ����ڻ�������ͷָ����ָ��λ�á�
incl %ebx // ��ͷָ��ǰ��һ�ֽڡ�
andl $size-1,%ebx // �û�������С��ͷָ�����ģ������ָ�벻�ܳ�����������С��
cmpl tail(%ecx),%ebx // ������ͷָ����βָ��Ƚϡ�
je 1f // ����ȣ���ʾ������������ת�����1 ����
movl %ebx,head(%ecx) // �����޸Ĺ���ͷָ�롣
1: pushl %edx // �����ں�ѹ���ջ(1- ����1��2 - ����2)����Ϊ������
call _do_tty_interrupt // ����tty �жϴ���C ��������
addl $4,%esp // ������ջ�����������ء�
ret

.align 2
write_char:
movl 4(%ecx),%ecx # write-queue # ȡд������нṹ��ַ??ecx��
movl head(%ecx),%ebx // ȡд����ͷָ��??ebx��
subl tail(%ecx),%ebx // ͷָ�� - βָ�� = �������ַ�����
andl $size-1,%ebx # nr chars in queue # ��ָ��ȡģ���㡣
je write_buffer_empty // ���ͷָ�� = βָ�룬˵��д�������ַ�����ת����
cmpl $startup,%ebx // �������ַ�������256 ����
ja 1f // ����������ת����
movl proc_list(%ecx),%ebx # wake up sleeping process # ���ѵȴ��Ľ��̡�
// ȡ�ȴ��ö��еĽ��̵�ָ�룬���ж��Ƿ�Ϊ�ա�
testl %ebx,%ebx # is there any? # �еȴ��Ľ�����
je 1f // �ǿյģ�����ǰ��ת�����1 ����
movl $0,(%ebx) // ���򽫽�����Ϊ������״̬(���ѽ���)����
1: movl tail(%ecx),%ebx // ȡβָ�롣
movb buf(%ecx,%ebx),%al // �ӻ�����βָ�봦ȡһ�ַ�??al��
outb %al,%dx // ��˿�0x3f8(0x2f8)�ͳ������ּĴ����С�
incl %ebx // βָ��ǰ�ơ�
andl $size-1,%ebx // βָ������������ĩ�ˣ����ۻء�
movl %ebx,tail(%ecx) // �������޸Ĺ���βָ�롣
cmpl head(%ecx),%ebx // βָ����ͷָ��Ƚϣ�
je write_buffer_empty // ����ȣ���ʾ�����ѿգ�����ת��
ret
.align 2
write_buffer_empty:
movl proc_list(%ecx),%ebx # wake up sleeping process # ���ѵȴ��Ľ��̡�
// ȡ�ȴ��ö��еĽ��̵�ָ�룬���ж��Ƿ�Ϊ�ա�
testl %ebx,%ebx # is there any? # �еȴ��Ľ�����
je 1f # �ޣ�����ǰ��ת�����1 ����
movl $0,(%ebx) # ���򽫽�����Ϊ������״̬(���ѽ���)��
1: incl %edx # ָ��˿�0x3f9(0x2f9)��
inb %dx,%al # ��ȡ�ж�����Ĵ�����
jmp 1f # �����ӳ١�
1: jmp 1f
1: andb $0xd,%al /* disable transmit interrupt */
/* ���η��ͱ��ּĴ������жϣ�λ1�� */
outb %al,%dx // д��0x3f9(0x2f9)��
ret
