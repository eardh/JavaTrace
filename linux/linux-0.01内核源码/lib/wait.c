/*
* linux/lib/wait.c
*
* (C) 1991 Linus Torvalds
*/

#define __LIBRARY__
#include <unistd.h>		// Linux ��׼ͷ�ļ��������˸��ַ��ų��������ͣ��������˸��ֺ�����
// �綨����__LIBRARY__���򻹰���ϵͳ���úź���Ƕ���_syscall0()�ȡ�
#include <sys/wait.h>		// �ȴ�����ͷ�ļ�������ϵͳ����wait()��waitpid()����س������š�

//// �ȴ�������ֹϵͳ���ú�����
// �������ṹ��Ӧ�ں�����pid_t waitpid(pid_t pid, int * wait_stat, int options)
//
// ������pid - �ȴ�����ֹ���̵Ľ���id������������ָ����������������ض���ֵ��
// wait_stat - ���ڴ��״̬��Ϣ��options - WNOHANG ��WUNTRACED ����0��
_syscall3 (pid_t, waitpid, pid_t, pid, int *, wait_stat, int, options)
//// wait()ϵͳ���á�ֱ�ӵ���waitpid()������
     pid_t wait (int *wait_stat)
{
  return waitpid (-1, wait_stat, 0);
}
