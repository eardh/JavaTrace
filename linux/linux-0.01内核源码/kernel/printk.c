/*
* linux/kernel/printk.c
*
* (C) 1991 Linus Torvalds
*/

/*
* When in kernel-mode, we cannot use printf, as fs is liable to
* point to 'interesting' things. Make a printf with fs-saving, and
* all is well.
*/
/*
* �������ں�ģʽʱ�����ǲ���ʹ��printf����Ϊ�Ĵ���fs ָ������������Ȥ�ĵط���
* �Լ�����һ��printf ����ʹ��ǰ����fs��һ�оͽ���ˡ�
*/
#include <stdarg.h>		// ��׼����ͷ�ļ����Ժ����ʽ������������б���Ҫ˵����-��
// ����(va_list)��������(va_start, va_arg ��va_end)������
// vsprintf��vprintf��vfprintf ������
#include <stddef.h>		// ��׼����ͷ�ļ���������NULL, offsetof(TYPE, MEMBER)��

#include <linux/kernel.h>	// �ں�ͷ�ļ�������һЩ�ں˳��ú�����ԭ�ζ��塣

static char buf[1024];

// ����ú���vsprintf()��linux/kernel/vsprintf.c ��92 �п�ʼ��
extern int vsprintf (char *buf, const char *fmt, va_list args);

// �ں�ʹ�õ���ʾ������
int
printk (const char *fmt, ...)
{
  va_list args;			// va_list ʵ������һ���ַ�ָ�����͡�
  int i;

  va_start (args, fmt);		// ��������ʼ�������ڣ�include/stdarg.h,13��
  i = vsprintf (buf, fmt, args);	// ʹ�ø�ʽ��fmt �������б�args �����buf �С�
// ����ֵi ��������ַ����ĳ��ȡ�
  va_end (args);		// �����������������
  __asm__ ("push %%fs\n\t"	// ����fs��
	   "push %%ds\n\t" "pop %%fs\n\t"	// ��fs = ds��
	   "pushl %0\n\t"	// ���ַ�������ѹ���ջ(��������ջ�ǵ��ò���)��
	   "pushl $_buf\n\t"	// ��buf �ĵ�ַѹ���ջ��
	   "pushl $0\n\t"	// ����ֵ0 ѹ���ջ����ͨ����channel��
	   "call _tty_write\n\t"	// ����tty_write ������(kernel/chr_drv/tty_io.c,290)��
	   "addl $8,%%esp\n\t"	// ������������������ջ����(buf,channel)��
	   "popl %0\n\t"	// �����ַ�������ֵ����Ϊ����ֵ��
	   "pop %%fs"		// �ָ�ԭfs �Ĵ�����
::"r" (i):"ax", "cx", "dx");	// ֪ͨ���������Ĵ���ax,cx,dx ֵ�����Ѿ��ı䡣
  return i;			// �����ַ������ȡ�
}
