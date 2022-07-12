/*
* linux/tools/build.c
*
* (C) 1991 Linus Torvalds
*/

/*
* This file builds a disk-image from three different files:
*
* - bootsect: max 510 bytes of 8086 machine code, loads the rest
* - setup: max 4 sectors of 8086 machine code, sets up system parm
* - system: 80386 code for actual system
*
* It does some checking that all files are of the correct type, and
* just writes the result to stdout, removing headers and padding to
* the right amount. It also writes some system data to stderr.
*/
/*
* �ó����������ͬ�ĳ����д�������ӳ���ļ���
*
* - bootsect�����ļ���8086 �������Ϊ510 �ֽڣ����ڼ�����������
* - setup�����ļ���8086 �������Ϊ4 ��������������������ϵͳ������
* - system��ʵ��ϵͳ��80386 ���롣
*
* �ó������ȼ�����г���ģ��������Ƿ���ȷ��������������ն�����ʾ������
* Ȼ��ɾ��ģ��ͷ�����������ȷ�ĳ��ȡ��ó���Ҳ�ὫһЩϵͳ����д��stderr��
*/

/*
* Changes by tytso to allow root device specification
*/
/*
* tytso �Ըó��������޸ģ�������ָ�����ļ��豸��
*/

#include <stdio.h> /* fprintf */	/* ʹ�����е�fprintf() */
#include <string.h>		/* �ַ������� */
#include <stdlib.h> /* contains exit */	/* ����exit() */
#include <sys/types.h> /* unistd.h needs this */	/* ��unistd.h ʹ�� */
#include <sys/stat.h>		/* �ļ�״̬��Ϣ�ṹ */
#include <linux/fs.h>		/* �ļ�ϵͳ */
#include <unistd.h> /* contains read/write */	/* ����read()/write() */
#include <fcntl.h>		/* �ļ�����ģʽ���ų��� */

#define MINIX_HEADER 32		// minix ������ģ��ͷ������Ϊ32 �ֽڡ�
#define GCC_HEADER 1024		// GCC ͷ����Ϣ����Ϊ1024 �ֽڡ�

#define SYS_SIZE 0x2000		// system �ļ������(�ֽ���ΪSYS_SIZE*16=128KB)��


#define DEFAULT_MAJOR_ROOT 3	// Ĭ�ϸ��豸���豸�� - 3��Ӳ�̣���
#define DEFAULT_MINOR_ROOT 6	// Ĭ�ϸ��豸���豸�� - 6����2 ��Ӳ�̵ĵ�1 ��������

/* max nr of sectors of setup: don't change unless you also change
* bootsect etc */
/* ����ָ��setup ģ��ռ���������������Ҫ�ı��ֵ������Ҳ�ı�bootsect ����Ӧ�ļ���
#define SETUP_SECTS 4 // setup ��󳤶�Ϊ4 ��������4*512 �ֽڣ���
*/
#define STRINGIFY(x) #x		// ���ڳ���ʱ��ʾ����б�ʾ��������

//// ��ʾ������Ϣ������ֹ����
void
die (char *str)
{
  fprintf (stderr, "%s\n", str);
  exit (1);
}

// ��ʾ����ʹ�÷��������˳���
void
usage (void)
{
  die ("Usage: build bootsect setup system [rootdev] [> image]");
}

int
main (int argc, char **argv)
{
  int i, c, id;
  char buf[1024];
  char major_root, minor_root;
  struct stat sb;

// ������������в�������4 ��5 ��������ʾ�����÷����˳���
  if ((argc != 4) && (argc != 5))
    usage ();
// ���������5 ������˵�����и��豸����
  if (argc == 5)
    {
// ������豸��������("FLOPPY")����ȡ���豸�ļ���״̬��Ϣ������������ʾ��Ϣ���˳���
      if (strcmp (argv[4], "FLOPPY"))
	{
	  if (stat (argv[4], &sb))
	    {
	      perror (argv[4]);
	      die ("Couldn't stat root device.");
	    }
// ���ɹ���ȡ���豸��״̬�ṹ�е����豸�źʹ��豸�š�
	  major_root = MAJOR (sb.st_rdev);
	  minor_root = MINOR (sb.st_rdev);
	}
      else
	{
// ���������豸�źʹ��豸��ȡ0��
	  major_root = 0;
	  minor_root = 0;
	}
// ������ֻ��4 �����������豸�źʹ��豸�ŵ���ϵͳĬ�ϵĸ��豸��
    }
  else
    {
      major_root = DEFAULT_MAJOR_ROOT;
      minor_root = DEFAULT_MINOR_ROOT;

    }
// �ڱ�׼�����ն�����ʾ��ѡ��ĸ��豸�������豸�š�
  fprintf (stderr, "Root device is (%d, %d)\n", major_root, minor_root);
// ������豸�Ų�����2(����)��3(Ӳ��)��Ҳ������0(ȡϵͳĬ�ϸ��豸)������ʾ������Ϣ���˳���
  if ((major_root != 2) && (major_root != 3) && (major_root != 0))
    {
      fprintf (stderr, "Illegal root device (major = %d)\n", major_root);
      die ("Bad root device --- major #");
    }
// ��ʼ��buf ��������ȫ��0��
  for (i = 0; i < sizeof buf; i++)
    buf[i] = 0;
// ��ֻ����ʽ�򿪲���1 ָ�����ļ�(bootsect)������������ʾ������Ϣ���˳���
  if ((id = open (argv[1], O_RDONLY, 0)) < 0)
    die ("Unable to open 'boot'");
// ��ȡ�ļ��е�minix ִ��ͷ����Ϣ(�μ��б��˵��)������������ʾ������Ϣ���˳���
  if (read (id, buf, MINIX_HEADER) != MINIX_HEADER)
    die ("Unable to read header of 'boot'");
// 0x0301 - minix ͷ��a_magic ħ����0x10 - a_flag ��ִ�У�0x04 - a_cpu, Intel 8086 �����롣
  if (((long *) buf)[0] != 0x04100301)
    die ("Non-Minix header of 'boot'");
// �ж�ͷ�������ֶ�a_hdrlen���ֽڣ��Ƿ���ȷ���������ֽ�����û���ã���0��
  if (((long *) buf)[1] != MINIX_HEADER)
    die ("Non-Minix header of 'boot'");
// �ж����ݶγ�a_data �ֶ�(long)�����Ƿ�Ϊ0��
  if (((long *) buf)[3] != 0)
    die ("Illegal data segment in 'boot'");
// �ж϶�a_bss �ֶ�(long)�����Ƿ�Ϊ0��
  if (((long *) buf)[4] != 0)
    die ("Illegal bss in 'boot'");
// �ж�ִ�е�a_entry �ֶ�(long)�����Ƿ�Ϊ0��
  if (((long *) buf)[5] != 0)
    die ("Non-Minix header of 'boot'");
// �жϷ��ű��ֶ�a_sym �������Ƿ�Ϊ0��
  if (((long *) buf)[7] != 0)
    die ("Illegal symbol table in 'boot'");
// ��ȡʵ�ʴ������ݣ�Ӧ�÷��ض�ȡ�ֽ���Ϊ512 �ֽڡ�
  i = read (id, buf, sizeof buf);
  fprintf (stderr, "Boot sector %d bytes.\n", i);
  if (i != 512)
    die ("Boot block must be exactly 512 bytes");
// �ж�boot ��0x510 ���Ƿ��п�������־0xAA55��
  if ((*(unsigned short *) (buf + 510)) != 0xAA55)
    die ("Boot block hasn't got boot flag (0xAA55)");
// �������508��509 ƫ�ƴ���ŵ��Ǹ��豸�š�
  buf[508] = (char) minor_root;
  buf[509] = (char) major_root;
// ����boot ��512 �ֽڵ�����д����׼���stdout����д���ֽ������ԣ�����ʾ������Ϣ���˳���
  i = write (1, buf, 512);
  if (i != 512)
    die ("Write call failed");
// ���ر�bootsect ģ���ļ���
  close (id);


// ���ڿ�ʼ����setup ģ�顣������ֻ����ʽ�򿪸�ģ�飬����������ʾ������Ϣ���˳���
  if ((id = open (argv[2], O_RDONLY, 0)) < 0)
    die ("Unable to open 'setup'");
// ��ȡ���ļ��е�minix ִ��ͷ����Ϣ(32 �ֽ�)������������ʾ������Ϣ���˳���
  if (read (id, buf, MINIX_HEADER) != MINIX_HEADER)
    die ("Unable to read header of 'setup'");
// 0x0301 - minix ͷ��a_magic ħ����0x10 - a_flag ��ִ�У�0x04 - a_cpu, Intel 8086 �����롣
  if (((long *) buf)[0] != 0x04100301)
    die ("Non-Minix header of 'setup'");
// �ж�ͷ�������ֶ�a_hdrlen���ֽڣ��Ƿ���ȷ���������ֽ�����û���ã���0��
  if (((long *) buf)[1] != MINIX_HEADER)
    die ("Non-Minix header of 'setup'");
// �ж����ݶγ�a_data �ֶ�(long)�����Ƿ�Ϊ0��
  if (((long *) buf)[3] != 0)
    die ("Illegal data segment in 'setup'");
// �ж϶�a_bss �ֶ�(long)�����Ƿ�Ϊ0��
  if (((long *) buf)[4] != 0)
    die ("Illegal bss in 'setup'");
// �ж�ִ�е�a_entry �ֶ�(long)�����Ƿ�Ϊ0��
  if (((long *) buf)[5] != 0)
    die ("Non-Minix header of 'setup'");
// �жϷ��ű��ֶ�a_sym �������Ƿ�Ϊ0��
  if (((long *) buf)[7] != 0)
    die ("Illegal symbol table in 'setup'");
// ��ȡ����ִ�д������ݣ���д����׼���stdout��
  for (i = 0; (c = read (id, buf, sizeof buf)) > 0; i += c)
    if (write (1, buf, c) != c)
      die ("Write call failed");
//�ر�setup ģ���ļ���
  close (id);
// ��setup ģ�鳤�ȴ���4 �����������������ʾ������Ϣ���˳���
  if (i > SETUP_SECTS * 512)
    die ("Setup exceeds " STRINGIFY (SETUP_SECTS)
	 " sectors - rewrite build/boot/setup");
// �ڱ�׼����stderr ��ʾsetup �ļ��ĳ���ֵ��
  fprintf (stderr, "Setup is %d bytes.\n", i);
// ��������buf ���㡣
  for (c = 0; c < sizeof (buf); c++)
    buf[c] = '\0';
// ��setup ����С��4*512 �ֽڣ�����\0 ��setup ����Ϊ4*512 �ֽڡ�
  while (i < SETUP_SECTS * 512)
    {
      c = SETUP_SECTS * 512 - i;
      if (c > sizeof (buf))
	c = sizeof (buf);
      if (write (1, buf, c) != c)
	die ("Write call failed");
      i += c;
    }

// ���洦��system ģ�顣������ֻ����ʽ�򿪸��ļ���
  if ((id = open (argv[3], O_RDONLY, 0)) < 0)
    die ("Unable to open 'system'");

// system ģ����GCC ��ʽ���ļ����ȶ�ȡGCC ��ʽ��ͷ���ṹ��Ϣ(linux ��ִ���ļ�Ҳ���øø�ʽ)��
  if (read (id, buf, GCC_HEADER) != GCC_HEADER)
    die ("Unable to read header of 'system'");
// �ýṹ�е�ִ�д�����ڵ��ֶ�a_entry ֵӦΪ0��
  if (((long *) buf)[5] != 0)
    die ("Non-GCC header of 'system'");
// ��ȡ����ִ�д������ݣ���д����׼���stdout��
  for (i = 0; (c = read (id, buf, sizeof buf)) > 0; i += c)
    if (write (1, buf, c) != c)
      die ("Write call failed");
// �ر�system �ļ�������stderr �ϴ�ӡsystem ���ֽ�����
  close (id);
  fprintf (stderr, "System is %d bytes.\n", i);
// ��system �������ݳ��ȳ���SYS_SIZE �ڣ���128KB �ֽڣ�������ʾ������Ϣ���˳���
  if (i > SYS_SIZE * 16)
    die ("System is too big");
  return (0);
}
