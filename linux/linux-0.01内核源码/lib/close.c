/*
* linux/lib/close.c
*
* (C) 1991 Linus Torvalds
*/

#define __LIBRARY__
#include <unistd.h>		// Linux ��׼ͷ�ļ��������˸��ַ��ų��������ͣ��������˸��ֺ�����
// �綨����__LIBRARY__���򻹰���ϵͳ���úź���Ƕ���_syscall0()�ȡ�

// �ر��ļ�������
// ����õ��ú꺯����Ӧ��int close(int fd)��ֱ�ӵ�����ϵͳ�ж�int 0x80��������__NR_close��
// ����fd ���ļ���������
_syscall1 (int, close, int, fd)
