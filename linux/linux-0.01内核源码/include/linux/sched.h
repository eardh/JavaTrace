#ifndef _SCHED_H
#define _SCHED_H

#define NR_TASKS 64		// ϵͳ��ͬʱ������񣨽��̣�����
#define HZ 100			// ����ϵͳʱ�ӵδ�Ƶ��(1 �ٺ��ȣ�ÿ���δ�10ms)

#define FIRST_TASK task[0]	// ����0 �Ƚ����⣬�������������������һ�����š�
#define LAST_TASK task[NR_TASKS-1]	// ���������е����һ������

#include <linux/head.h>		// head ͷ�ļ��������˶��������ļ򵥽ṹ���ͼ���ѡ���������
#include <linux/fs.h>		// �ļ�ϵͳͷ�ļ��������ļ���ṹ��file,buffer_head,m_inode �ȣ���
#include <linux/mm.h>		// �ڴ����ͷ�ļ�������ҳ���С�����һЩҳ���ͷź���ԭ�͡�
#include <signal.h>		// �ź�ͷ�ļ��������źŷ��ų������źŽṹ�Լ��źŲ�������ԭ�͡�

#if (NR_OPEN > 32)
#error "Currently the close-on-exec-flags are in one word, max 32 files/proc"
#endif

// ���ﶨ���˽������п��ܴ���״̬��
#define TASK_RUNNING 0		// �����������л���׼��������
#define TASK_INTERRUPTIBLE 1	// ���̴��ڿ��жϵȴ�״̬��
#define TASK_UNINTERRUPTIBLE 2	// ���̴��ڲ����жϵȴ�״̬����Ҫ����I/O �����ȴ���
#define TASK_ZOMBIE 3		// ���̴��ڽ���״̬���Ѿ�ֹͣ���У��������̻�û���źš�
#define TASK_STOPPED 4		// ������ֹͣ��

#ifndef NULL
#define NULL ((void *) 0)	// ����NULL Ϊ��ָ�롣
#endif

// ���ƽ��̵�ҳĿ¼ҳ��Linus ��Ϊ�����ں�����ӵĺ���֮һ��( mm/memory.c, 105 )
extern int copy_page_tables (unsigned long from, unsigned long to, long size);
// �ͷ�ҳ����ָ�����ڴ�鼰ҳ����( mm/memory.c, 150 )
extern int free_page_tables (unsigned long from, unsigned long size);

// ���ȳ���ĳ�ʼ��������( kernel/sched.c, 385 )
extern void sched_init (void);
// ���̵��Ⱥ�����( kernel/sched.c, 104 )
extern void schedule (void);
// �쳣(����)�жϴ����ʼ�������������жϵ����Ų������ж������źš�( kernel/traps.c, 181 )
extern void trap_init (void);
// ��ʾ�ں˳�����Ϣ��Ȼ�������ѭ����( kernel/panic.c, 16 )��
extern void panic (const char *str);
// ��tty ��дָ�����ȵ��ַ�����( kernel/chr_drv/tty_io.c, 290 )��
extern int tty_write (unsigned minor, char *buf, int count);

typedef int (*fn_ptr) ();	// ���庯��ָ�����͡�

// ��������ѧЭ������ʹ�õĽṹ����Ҫ���ڱ�������л�ʱi387 ��ִ��״̬��Ϣ��
struct i387_struct
{
  long cwd;			// ������(Control word)��
  long swd;			// ״̬��(Status word)��
  long twd;			// �����(Tag word)��
  long fip;			// Э����������ָ�롣
  long fcs;			// Э����������μĴ�����
  long foo;
  long fos;
  long st_space[20];		/* 8*10 bytes for each FP-reg = 80 bytes */
};

// ����״̬�����ݽṹ���μ��б�����Ϣ����
struct tss_struct
{
  long back_link;		/* 16 high bits zero */
  long esp0;
  long ss0;			/* 16 high bits zero */
  long esp1;
  long ss1;			/* 16 high bits zero */
  long esp2;
  long ss2;			/* 16 high bits zero */
  long cr3;
  long eip;
  long eflags;
  long eax, ecx, edx, ebx;
  long esp;
  long ebp;
  long esi;
  long edi;
  long es;			/* 16 high bits zero */
  long cs;			/* 16 high bits zero */
  long ss;			/* 16 high bits zero */
  long ds;			/* 16 high bits zero */
  long fs;			/* 16 high bits zero */
  long gs;			/* 16 high bits zero */
  long ldt;			/* 16 high bits zero */
  long trace_bitmap;		/* bits: trace 0, bitmap 16-31 */
  struct i387_struct i387;
};

// ���������񣨽��̣����ݽṹ�����Ϊ������������
// ==========================
// long state ���������״̬��-1 �������У�0 ������(����)��>0 ��ֹͣ����
// long counter ��������ʱ�����(�ݼ�)���δ�����������ʱ��Ƭ��
// long priority ����������������ʼ����ʱcounter = priority��Խ������Խ����
// long signal �źš���λͼ��ÿ������λ����һ���źţ��ź�ֵ=λƫ��ֵ+1��
// struct sigaction sigaction[32] �ź�ִ�����Խṹ����Ӧ�źŽ�Ҫִ�еĲ����ͱ�־��Ϣ��
// long blocked �����ź������루��Ӧ�ź�λͼ����
// --------------------------
// int exit_code ����ִ��ֹͣ���˳��룬�丸���̻�ȡ��
// unsigned long start_code ����ε�ַ��
// unsigned long end_code ���볤�ȣ��ֽ�������
// unsigned long end_data ���볤�� + ���ݳ��ȣ��ֽ�������
// unsigned long brk �ܳ��ȣ��ֽ�������
// unsigned long start_stack ��ջ�ε�ַ��
// long pid ���̱�ʶ��(���̺�)��
// long father �����̺š�
// long pgrp ��������š�
// long session �Ự�š�
// long leader �Ự���졣
// unsigned short uid �û���ʶ�ţ��û�id����
// unsigned short euid ��Ч�û�id��
// unsigned short suid ������û�id��
// unsigned short gid ���ʶ�ţ���id����
// unsigned short egid ��Ч��id��
// unsigned short sgid �������id��
// long alarm ������ʱֵ���δ�������
// long utime �û�̬����ʱ�䣨�δ�������
// long stime ϵͳ̬����ʱ�䣨�δ�������
// long cutime �ӽ����û�̬����ʱ�䡣
// long cstime �ӽ���ϵͳ̬����ʱ�䡣
// long start_time ���̿�ʼ����ʱ�̡�
// unsigned short used_math ��־���Ƿ�ʹ����Э��������
// --------------------------
// int tty ����ʹ��tty �����豸�š�-1 ��ʾû��ʹ�á�
// unsigned short umask �ļ�������������λ��
// struct m_inode * pwd ��ǰ����Ŀ¼i �ڵ�ṹ��
// struct m_inode * root ��Ŀ¼i �ڵ�ṹ��
// struct m_inode * executable ִ���ļ�i �ڵ�ṹ��
// unsigned long close_on_exec ִ��ʱ�ر��ļ����λͼ��־�����μ�include/fcntl.h��
// struct file * filp[NR_OPEN] ����ʹ�õ��ļ���ṹ��
// --------------------------
// struct desc_struct ldt[3] ������ľֲ�����������0-�գ�1-�����cs��2-���ݺͶ�ջ��ds&ss��
// --------------------------
// struct tss_struct tss �����̵�����״̬����Ϣ�ṹ��
// ==========================
struct task_struct
{
/* these are hardcoded - don't touch */
  long state;			/* -1 unrunnable, 0 runnable, >0 stopped */
  long counter;
  long priority;
  long signal;
  struct sigaction sigaction[32];
  long blocked;			/* bitmap of masked signals */
/* various fields */
  int exit_code;
  unsigned long start_code, end_code, end_data, brk, start_stack;
  long pid, father, pgrp, session, leader;
  unsigned short uid, euid, suid;
  unsigned short gid, egid, sgid;
  long alarm;
  long utime, stime, cutime, cstime, start_time;
  unsigned short used_math;
/* file system info */
  int tty;			/* -1 if no tty, so it must be signed */
  unsigned short umask;
  struct m_inode *pwd;
  struct m_inode *root;
  struct m_inode *executable;
  unsigned long close_on_exec;
  struct file *filp[NR_OPEN];
/* ldt for this task 0 - zero 1 - cs 2 - ds&ss */
  struct desc_struct ldt[3];
/* tss for this task */
  struct tss_struct tss;
};

/*
* INIT_TASK is used to set up the first task table, touch at
* your own risk!. Base=0, limit=0x9ffff (=640kB)
*/
/*
* INIT_TASK �������õ�1 ������������޸ģ������Ը�?��
* ��ַBase = 0���γ�limit = 0x9ffff��=640kB����
*/
// ��Ӧ��������ṹ�ĵ�1 ���������Ϣ��
#define INIT_TASK \
/* state etc */ { 0,15,15, \	// state, counter, priority
/* signals */ 0,
{
  {
  }
,}

, 0, \				// signal, sigaction[32], blocked
					/* ec,brk... */ 0, 0, 0, 0, 0, 0, \
					// exit_code,start_code,end_code,end_data,brk,start_stack
					/* pid etc.. */ 0, -1, 0, 0, 0, \
					// pid, father, pgrp, session, leader
					/* uid etc */ 0, 0, 0, 0, 0, 0, \
					// uid, euid, suid, gid, egid, sgid
					/* alarm */ 0, 0, 0, 0, 0, 0, \
					// alarm, utime, stime, cutime, cstime, start_time
				/* math */ 0, \
				// used_math
							/* fs info */ -1, 0022, NULL, NULL, NULL, 0, \
							// tty,umask,pwd,root,executable,close_on_exec
/* filp */
{
NULL,}

, \				// filp[20]
{
  \				// ldt[3]
  {
  0, 0}
  ,
/* ldt */
  {
  0x9f, 0xc0fa00}
  , \				// ���볤640K����ַ0x0��G=1��D=1��DPL=3��P=1 TYPE=0x0a
  {
  0x9f, 0xc0f200}
  , \				// ���ݳ�640K����ַ0x0��G=1��D=1��DPL=3��P=1 TYPE=0x02
}

,
/*tss*/
{
  0, PAGE_SIZE + (long) &init_task, 0x10, 0, 0, 0, 0, (long) &pg_dir, \	// tss
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0x17, 0x17, 0x17, 0x17, 0x17, 0x17, _LDT (0), 0x80000000,
  {
  }
}
,}

extern struct task_struct *task[NR_TASKS];	// �������顣
extern struct task_struct *last_task_used_math;	// ��һ��ʹ�ù�Э�������Ľ��̡�
extern struct task_struct *current;	// ��ǰ���̽ṹָ�������
extern long volatile jiffies;	// �ӿ�����ʼ����ĵδ�����10ms/�δ𣩡�
extern long startup_time;	// ����ʱ�䡣��1970:0:0:0 ��ʼ��ʱ��������

#define CURRENT_TIME (startup_time+jiffies/HZ)	// ��ǰʱ�䣨��������

// ��Ӷ�ʱ����������ʱʱ��jiffies �δ�������ʱ��ʱ���ú���*fn()����( kernel/sched.c,272)
extern void add_timer (long jiffies, void (*fn) (void));
// �����жϵĵȴ�˯�ߡ�( kernel/sched.c, 151 )
extern void sleep_on (struct task_struct **p);
// ���жϵĵȴ�˯�ߡ�( kernel/sched.c, 167 )
extern void interruptible_sleep_on (struct task_struct **p);
// ��ȷ����˯�ߵĽ��̡�( kernel/sched.c, 188 )
extern void wake_up (struct task_struct **p);

/*
* Entry into gdt where to find first TSS. 0-nul, 1-cs, 2-ds, 3-syscall
* 4-TSS0, 5-LDT0, 6-TSS1 etc ...
*/
/*
* Ѱ�ҵ�1 ��TSS ��ȫ�ֱ��е���ڡ�0-û����nul��1-�����cs��2-���ݶ�ds��3-ϵͳ��syscall
* 4-����״̬��TSS0��5-�ֲ���LTD0��6-����״̬��TSS1���ȡ�
*/
// ȫ�ֱ��е�1 ������״̬��(TSS)��������ѡ��������š�
#define FIRST_TSS_ENTRY 4
// ȫ�ֱ��е�1 ���ֲ���������(LDT)��������ѡ��������š�
#define FIRST_LDT_ENTRY (FIRST_TSS_ENTRY+1)
// �궨�壬������ȫ�ֱ��е�n �������TSS �������������ţ�ѡ�������
#define _TSS(n) ((((unsigned long) n)<<4)+(FIRST_TSS_ENTRY<<3))
// �궨�壬������ȫ�ֱ��е�n �������LDT �������������š�
#define _LDT(n) ((((unsigned long) n)<<4)+(FIRST_LDT_ENTRY<<3))
// �궨�壬���ص�n �����������Ĵ���tr��
#define ltr(n) __asm__( "ltr %%ax":: "a" (_TSS(n)))
// �궨�壬���ص�n ������ľֲ���������Ĵ���ldtr��
#define lldt(n) __asm__( "lldt %%ax":: "a" (_LDT(n)))
// ȡ��ǰ�������������ţ������������е�����ֵ������̺�pid ��ͬ����
// ���أ�n - ��ǰ����š�����( kernel/traps.c, 79)��
#define str(n) \
__asm__( "str %%ax\n\t" \	// ������Ĵ�����TSS �ε���Ч��ַ??ax
"subl %2,%%eax\n\t" \		// (eax - FIRST_TSS_ENTRY*8)??eax
  "shrl $4,%%eax" \		// (eax/16)??eax = ��ǰ����š�
: "=a" (n):"a" (0), "i" (FIRST_TSS_ENTRY << 3))
/*
* switch_to(n) should switch tasks to task nr n, first
* checking that n isn't the current task, in which case it does nothing.
* This also clears the TS-flag if the task we switched to has used
* tha math co-processor latest.
*/
/*
* switch_to(n)���л���ǰ��������nr����n�����ȼ������n ���ǵ�ǰ����
* �������ʲôҲ�����˳�����������л���������������ϴ����У�ʹ�ù���ѧ
* Э�������Ļ������踴λ���ƼĴ���cr0 �е�TS ��־��
*/
// ���룺%0 - ��TSS ��ƫ�Ƶ�ַ(*&__tmp.a)�� %1 - �����TSS ��ѡ���ֵ(*&__tmp.b)��
// dx - ������n ��ѡ�����ecx - ������ָ��task[n]��
// ������ʱ���ݽṹ__tmp �У�a ��ֵ��32 λƫ��ֵ��b Ϊ��TSS ��ѡ������������л�ʱ��a ֵ
// û���ã����ԣ������ж��������ϴ�ִ���Ƿ�ʹ�ù�Э������ʱ����ͨ����������״̬�εĵ�ַ��
// ������last_task_used_math �����е�ʹ�ù�Э������������״̬�εĵ�ַ���бȽ϶������ġ�
#define switch_to(n) {\
struct {long a,b;} __tmp; \
__asm__( "cmpl %%ecx,_current\n\t" \	// ����n �ǵ�ǰ������?(current ==task[n]?)
  "je 1f\n\t" \			// �ǣ���ʲô���������˳���
  "movw %%dx,%1\n\t" \		// ���������ѡ���??*&__tmp.b��
  "xchgl %%ecx,_current\n\t" \	// current = task[n]��ecx = ���л���������
  "ljmp %0\n\t" \		// ִ�г���ת��*&__tmp����������л���
// �������л�������Ż����ִ���������䡣
  "cmpl %%ecx,_last_task_used_math\n\t" \	// �������ϴ�ʹ�ù�Э��������
  "jne 1f\n\t" \		// û������ת���˳���
  "clts\n" \			// �������ϴ�ʹ�ù�Э������������cr0 ��TS ��־��
  "1:"::"m" (*&__tmp.a), "m" (*&__tmp.b),
  "d" (_TSS (n)), "c" ((long) task[n]));
}

// ҳ���ַ��׼�������ں˴�����û���κεط�����!!��
#define PAGE_ALIGN(n) (((n)+0xfff)&0xfffff000)

// ����λ�ڵ�ַaddr ���������еĸ�����ַ�ֶ�(����ַ��base)���μ��б��˵����
// %0 - ��ַaddr ƫ��2��%1 - ��ַaddr ƫ��4��%2 - ��ַaddr ƫ��7��edx - ����ַbase��
#define _set_base(addr,base) \
__asm__( "movw %%dx,%0\n\t" \	// ��ַbase ��16 λ(λ15-0)??[addr+2]��
"rorl $16,%%edx\n\t" \		// edx �л�ַ��16 λ(λ31-16)??dx��
  "movb %%dl,%1\n\t" \		// ��ַ��16 λ�еĵ�8 λ(λ23-16)??[addr+4]��
  "movb %%dh,%2" \		// ��ַ��16 λ�еĸ�8 λ(λ31-24)??[addr+7]��
::"m" (*((addr) + 2)), "m" (*((addr) + 4)), "m" (*((addr) + 7)), "d" (base):"dx")
// ����λ�ڵ�ַaddr ���������еĶ��޳��ֶ�(�γ���limit)��
// %0 - ��ַaddr��%1 - ��ַaddr ƫ��6 ����edx - �γ�ֵlimit��
#define _set_limit(addr,limit) \
__asm__( "movw %%dx,%0\n\t" \	// �γ�limit ��16 λ(λ15-0)??[addr]��
  "rorl $16,%%edx\n\t" \	// edx �еĶγ���4 λ(λ19-16)??dl��
  "movb %1,%%dh\n\t" \		// ȡԭ[addr+6]�ֽ�??dh�����и�4 λ��Щ��־��
  "andb $0xf0,%%dh\n\t" \	// ��dh �ĵ�4 λ(����Ŷγ���λ19-16)��
  "orb %%dh,%%dl\n\t" \		// ��ԭ��4 λ��־�Ͷγ��ĸ�4 λ(λ19-16)�ϳ�1 �ֽڣ�
  "movb %%dl,%1" \		// ���Ż�[addr+6]����
::"m" (*(addr)), "m" (*((addr) + 6)), "d" (limit):"dx")
// ���þֲ�����������ldt �������Ļ���ַ�ֶΡ�
#define set_base(ldt,base) _set_base( ((char *)&(ldt)) , base )
// ���þֲ�����������ldt �������Ķγ��ֶΡ�
#define set_limit(ldt,limit) _set_limit( ((char *)&(ldt)) , (limit-1)>>12 )
// �ӵ�ַaddr ����������ȡ�λ���ַ��������_set_base()�����෴��
// edx - ��Ż���ַ(__base)��%1 - ��ַaddr ƫ��2��%2 - ��ַaddr ƫ��4��%3 - addr ƫ��7��
#define _get_base(addr) ({\
unsigned long __base; \
__asm__( "movb %3,%%dh\n\t" \	// ȡ[addr+7]����ַ��16 λ�ĸ�8 λ(λ31-24)??dh��
  "movb %2,%%dl\n\t" \		// ȡ[addr+4]����ַ��16 λ�ĵ�8 λ(λ23-16)??dl��
  "shll $16,%%edx\n\t" \	// ����ַ��16 λ�Ƶ�edx �и�16 λ����
  "movw %1,%%dx" \		// ȡ[addr+2]����ַ��16 λ(λ15-0)??dx��
:"=d" (__base) \		// �Ӷ�edx �к���32 λ�Ķλ���ַ��
:"m" (*((addr) + 2)), "m" (*((addr) + 4)), "m" (*((addr) + 7)));
__base;
}

)
// ȡ�ֲ�����������ldt ��ָ���������еĻ���ַ��
#define get_base(ldt) _get_base( ((char *)&(ldt)) )
// ȡ��ѡ���segment �Ķγ�ֵ��
// %0 - ��Ŷγ�ֵ(�ֽ���)��%1 - ��ѡ���segment��
#define get_limit(segment) ({ \
unsigned long __limit; \
__asm__( "lsll %1,%0\n\tincl %0": "=r" (__limit): "r" (segment)); \
__limit;})
#endif
