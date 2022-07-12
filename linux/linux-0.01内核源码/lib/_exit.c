1				/*
				   2 * linux/lib/_exit.c
				   3 *
				   4 * (C) 1991 Linus Torvalds
				   5 */
  6 478 7
#define __LIBRARY__		// ����һ�����ų�����������˵����
  8
#include <unistd.h>		// Linux ��׼ͷ�ļ��������˸��ַ��ų��������ͣ��������˸��ֺ�����
// �綨����__LIBRARY__���򻹰���ϵͳ���úź���Ƕ���_syscall0()�ȡ�
  9
//// �ں�ʹ�õĳ���(�˳�)��ֹ������
// ֱ�ӵ���ϵͳ�ж�int 0x80�����ܺ�__NR_exit��
// ������exit_code - �˳��롣
  10 volatile void
_exit (int exit_code)
  11
{
// %0 - eax(ϵͳ���ú�__NR_exit)��%1 - ebx(�˳���exit_code)��
  12 __asm__ ("int $0x80"::"a" (__NR_exit), "b" (exit_code));
13}

14
