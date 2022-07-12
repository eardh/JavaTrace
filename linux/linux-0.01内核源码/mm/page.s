/*
* linux/mm/page.s
*
* (C) 1991 Linus Torvalds
*/

/*
* page.s contains the low-level page-exception code.
* the real work is done in mm.c
*/
/*
* page.s ��������ײ�ҳ�쳣������롣ʵ�ʵĹ�����memory.c ����ɡ�
*/

.globl _page_fault

_page_fault:
xchgl %eax,(%esp) # ȡ�����뵽eax��
pushl %ecx
pushl %edx
push %ds
push %es
push %fs
movl $0x10,%edx # ���ں����ݶ�ѡ�����
mov %dx,%ds
mov %dx,%es
mov %dx,%fs
movl %cr2,%edx # ȡ����ҳ���쳣�����Ե�ַ
pushl %edx # �������Ե�ַ�ͳ�����ѹ���ջ����Ϊ���ú����Ĳ�����
pushl %eax
testl $1,%eax # ���Ա�־P���������ȱҳ������쳣����ת��
10.5 page.s ����
jne 1f
call _do_no_page # ����ȱҳ��������mm/memory.c,365 �У���
jmp 2f
1: call _do_wp_page # ����д������������mm/memory.c,247 �У���
2: addl $8,%esp # ����ѹ��ջ������������
pop %fs
pop %es
pop %ds
popl %edx
popl %ecx
popl %eax
iret
