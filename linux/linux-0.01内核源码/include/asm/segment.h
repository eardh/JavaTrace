//// ��ȡfs ����ָ����ַ�����ֽڡ�
// ������addr - ָ�����ڴ��ַ��
// %0 - (���ص��ֽ�_v)��%1 - (�ڴ��ַaddr)��
// ���أ������ڴ�fs:[addr]�����ֽڡ�
extern inline unsigned char
get_fs_byte (const char *addr)
{
  unsigned register char _v;

__asm__ ("movb %%fs:%1,%0": "=r" (_v):"m" (*addr));
  return _v;
}

//// ��ȡfs ����ָ����ַ�����֡�
// ������addr - ָ�����ڴ��ַ��
// %0 - (���ص���_v)��%1 - (�ڴ��ַaddr)��
// ���أ������ڴ�fs:[addr]�����֡�
extern inline unsigned short
get_fs_word (const unsigned short *addr)
{
  unsigned short _v;

__asm__ ("movw %%fs:%1,%0": "=r" (_v):"m" (*addr));
  return _v;
}

//// ��ȡfs ����ָ����ַ���ĳ���(4 �ֽ�)��
// ������addr - ָ�����ڴ��ַ��
// %0 - (���صĳ���_v)��%1 - (�ڴ��ַaddr)��
// ���أ������ڴ�fs:[addr]���ĳ��֡�
extern inline unsigned long
get_fs_long (const unsigned long *addr)
{
  unsigned long _v;

__asm__ ("movl %%fs:%1,%0": "=r" (_v):"m" (*addr));
  return _v;
}

//// ��һ�ֽڴ����fs ����ָ���ڴ��ַ����
// ������val - �ֽ�ֵ��addr - �ڴ��ַ��
// %0 - �Ĵ���(�ֽ�ֵval)��%1 - (�ڴ��ַaddr)��
extern inline void
put_fs_byte (char val, char *addr)
{
  __asm__ ("movb %0,%%fs:%1"::"r" (val), "m" (*addr));
}

//// ��һ�ִ����fs ����ָ���ڴ��ַ����
// ������val - ��ֵ��addr - �ڴ��ַ��
// %0 - �Ĵ���(��ֵval)��%1 - (�ڴ��ַaddr)��
extern inline void
put_fs_word (short val, short *addr)
{
  __asm__ ("movw %0,%%fs:%1"::"r" (val), "m" (*addr));
}

//// ��һ���ִ����fs ����ָ���ڴ��ַ����
// ������val - ����ֵ��addr - �ڴ��ַ��
// %0 - �Ĵ���(����ֵval)��%1 - (�ڴ��ַaddr)��
extern inline void
put_fs_long (unsigned long val, unsigned long *addr)
{
  __asm__ ("movl %0,%%fs:%1"::"r" (val), "m" (*addr));
}

/*
* Someone who knows GNU asm better than I should double check the followig.
* It seems to work, but I don't know if I'm doing something subtly wrong.
* --- TYT, 11/24/91
* [ nothing wrong here, Linus ]
*/
/*
* ���Ҹ���GNU ������Ӧ����ϸ�������Ĵ��롣��Щ������ʹ�ã����Ҳ�֪���Ƿ�
* ����һЩС����
* --- TYT��1991 ��11 ��24 ��
* [ ��Щ����û�д���Linus ]
*/

//// ȡfs �μĴ���ֵ(ѡ���)��
// ���أ�fs �μĴ���ֵ��
extern inline unsigned long
get_fs ()
{
  unsigned short _v;
__asm__ ("mov %%fs,%%ax": "=a" (_v):);
  return _v;
}

//// ȡds �μĴ���ֵ��
// ���أ�ds �μĴ���ֵ��
extern inline unsigned long
get_ds ()
{
  unsigned short _v;
__asm__ ("mov %%ds,%%ax": "=a" (_v):);
  return _v;
}

//// ����fs �μĴ�����
// ������val - ��ֵ��ѡ�������
extern inline void
set_fs (unsigned long val)
{
  __asm__ ("mov %0,%%fs"::"a" ((unsigned short) val));
}
