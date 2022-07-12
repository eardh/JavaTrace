/*
* linux/fs/bitmap.c
*
* (C) 1991 Linus Torvalds
*/

/* bitmap.c contains the code that handles the inode and block bitmaps */
/* bitmap.c �����д���i �ڵ�ʹ��̿�λͼ�Ĵ��� */
#include <string.h>		// �ַ���ͷ�ļ�����Ҫ������һЩ�й��ַ���������Ƕ�뺯����
// ��Ҫʹ�������е�memset()������
#include <linux/sched.h>	// ���ȳ���ͷ�ļ�������������ṹtask_struct����ʼ����0 �����ݣ�
// ����һЩ�й��������������úͻ�ȡ��Ƕ��ʽ��ຯ������䡣
#include <linux/kernel.h>	// �ں�ͷ�ļ�������һЩ�ں˳��ú�����ԭ�ζ��塣

//// ��ָ����ַ(addr)����һ���ڴ����㡣Ƕ�������ꡣ
// ���룺eax = 0��ecx = ���ݿ��СBLOCK_SIZE/4��edi = addr��
#define clear_block(addr) \
__asm__( "cld\n\t" \		// �巽��λ��
"rep\n\t" \			// �ظ�ִ�д洢���ݣ�0����
"stosl"::"a" (0), "c" (BLOCK_SIZE / 4), "D" ((long) (addr)):"cx", "di")
//// ��λָ����ַ��ʼ�ĵ�nr ��λƫ�ƴ��ı���λ(nr ���Դ���32��)������ԭ����λ��0 ��1����
// ���룺%0 - eax������ֵ)��%1 - eax(0)��%2 - nr��λƫ��ֵ��%3 - (addr)��addr �����ݡ�
#define set_bit(nr,addr) ({\
register int res __asm__( "ax"); \
__asm__ __volatile__( "btsl %2,%3\n\tsetb %%al": \
"=a" (res): "" (0), "r" (nr), "m" (*(addr))); \
res;})
//// ��λָ����ַ��ʼ�ĵ�nr λƫ�ƴ��ı���λ������ԭ����λ�ķ��루1 ��0����
// ���룺%0 - eax������ֵ)��%1 - eax(0)��%2 - nr��λƫ��ֵ��%3 - (addr)��addr �����ݡ�
#define clear_bit(nr,addr) ({\
register int res __asm__( "ax"); \
__asm__ __volatile__( "btrl %2,%3\n\tsetnb %%al": \
"=a" (res): "" (0), "r" (nr), "m" (*(addr))); \
res;})
//// ��addr ��ʼѰ�ҵ�1 ��0 ֵ����λ��
// ���룺%0 - ecx(����ֵ)��%1 - ecx(0)��%2 - esi(addr)��
// ��addr ָ����ַ��ʼ��λͼ��Ѱ�ҵ�1 ����0 �ı���λ�����������addr �ı���λƫ��ֵ���ء�
#define find_first_zero(addr) ({ \
int __res; \
__asm__( "cld\n" \		// �巽��λ��
  "1:\tlodsl\n\t" \		// ȡ[esi]??eax��
  "notl %%eax\n\t" \		// eax ��ÿλȡ����
  "bsfl %%eax,%%edx\n\t" \	// ��λ0 ɨ��eax ����1 �ĵ�1 ��λ����ƫ��ֵ??edx��
  "je 2f\n\t" \			// ���eax ��ȫ��0������ǰ��ת�����2 ��(40 ��)��
  "addl %%edx,%%ecx\n\t" \	// ƫ��ֵ����ecx(ecx ����λͼ���׸���0 �ı���λ��ƫ��ֵ)
  "jmp 3f\n" \			// ��ǰ��ת�����3 ������������
  "2:\taddl $32,%%ecx\n\t" \	// û���ҵ�0 ����λ����ecx ����1 �����ֵ�λƫ����32��
  "cmpl $8192,%%ecx\n\t" \	// �Ѿ�ɨ����8192 λ��1024 �ֽڣ�����
  "jl 1b\n" \			// ����û��ɨ����1 �����ݣ�����ǰ��ת�����1 ����������
  "3:" \			// ��������ʱecx ����λƫ������
: "=c" (__res): "c" (0), "S" (addr):"ax", "dx", "si");
__res;
}

)
//// �ͷ��豸dev ���������е��߼���block��
// ��λָ���߼���block ���߼���λͼ����λ��
// ������dev ���豸�ţ�block ���߼���ţ��̿�ţ���
     void free_block (int dev, int block)
     {
       struct super_block *sb;
       struct buffer_head *bh;

// ȡָ���豸dev �ĳ����飬���ָ���豸�����ڣ������������
       if (!(sb = get_super (dev)))
	 panic ("trying to free block on nonexistent device");
// ���߼����С���׸��߼���Ż��ߴ����豸�����߼������������������
       if (block < sb->s_firstdatazone || block >= sb->s_nzones)
	 panic ("trying to free block not in datazone");
// ��hash ����Ѱ�Ҹÿ����ݡ����ҵ������ж�����Ч�ԣ��������޸ĺ͸��±�־���ͷŸ����ݿ顣
// �öδ������Ҫ��;��������߼��鵱ǰ�����ڸ��ٻ����У����ͷŶ�Ӧ�Ļ���顣
       bh = get_hash_table (dev, block);
       if (bh)
	 {
	   if (bh->b_count != 1)
	     {
	       printk ("trying to free block (%04x:%d), count=%d\n",
		       dev, block, bh->b_count);
	       return;
	     }
	   bh->b_dirt = 0;	// ��λ�ࣨ���޸ģ���־λ��
	   bh->b_uptodate = 0;	// ��λ���±�־��
	   brelse (bh);
	 }
// ����block ����������ʼ����������߼���ţ���1 ��ʼ��������Ȼ����߼���(����)λͼ���в�����
// ��λ��Ӧ�ı���λ������Ӧ����λԭ������0�������������
       block -= sb->s_firstdatazone - 1;	// block = block - ( -1) ;
       if (clear_bit (block & 8191, sb->s_zmap[block / 8192]->b_data))
	 {
	   printk ("block (%04x:%d) ", dev, block + sb->s_firstdatazone - 1);
	   panic ("free_block: bit already cleared");
	 }
// ����Ӧ�߼���λͼ���ڻ��������޸ı�־��
       sb->s_zmap[block / 8192]->b_dirt = 1;
     }

////���豸dev ����һ���߼��飨�̿飬���飩�������߼���ţ��̿�ţ���
// ��λָ���߼���block ���߼���λͼ����λ��
int new_block (int dev)
{
  struct buffer_head *bh;
  struct super_block *sb;
  int i, j;

// ���豸dev ȡ�����飬���ָ���豸�����ڣ������������
  if (!(sb = get_super (dev)))
    panic ("trying to get new block from nonexistant device");
// ɨ���߼���λͼ��Ѱ���׸�0 ����λ��Ѱ�ҿ����߼��飬��ȡ���ø��߼���Ŀ�š�
  j = 8192;
  for (i = 0; i < 8; i++)
    if (bh = sb->s_zmap[i])
      if ((j = find_first_zero (bh->b_data)) < 8192)
	break;
// ���ȫ��ɨ���껹û�ҵ�(i>=8 ��j>=8192)����λͼ���ڵĻ������Ч(bh=NULL)�� ����0��
// �˳���û�п����߼��飩��
  if (i >= 8 || !bh || j >= 8192)
    return 0;
// �������߼����Ӧ�߼���λͼ�еı���λ������Ӧ����λ�Ѿ���λ�������������
  if (set_bit (j, bh->b_data))
    panic ("new_block: bit already set");
// �ö�Ӧ������������޸ı�־��������߼�����ڸ��豸�ϵ����߼���������˵��ָ���߼�����
// ��Ӧ�豸�ϲ����ڡ�����ʧ�ܣ�����0���˳���
  bh->b_dirt = 1;
  j += i * 8192 + sb->s_firstdatazone - 1;
  if (j >= sb->s_nzones)
    return 0;
// ��ȡ�豸�ϵĸ����߼������ݣ���֤�������ʧ����������
  if (!(bh = getblk (dev, j)))
    panic ("new_block: cannot get block");
// �¿�����ü���ӦΪ1������������
  if (bh->b_count != 1)
    panic ("new block: count is != 1");
// �������߼������㣬����λ���±�־�����޸ı�־��Ȼ���ͷŶ�Ӧ�������������߼���š�
  clear_block (bh->b_data);
  bh->b_uptodate = 1;
  bh->b_dirt = 1;
  brelse (bh);
  return j;
}

//// �ͷ�ָ����i �ڵ㡣
// ��λ��Ӧi �ڵ�λͼ����λ��
void free_inode (struct m_inode *inode)
{
  struct super_block *sb;
  struct buffer_head *bh;

// ���i �ڵ�ָ��=NULL�����˳���
  if (!inode)
    return;
// ���i �ڵ��ϵ��豸���ֶ�Ϊ0��˵���ýڵ����ã�����0 ��ն�Ӧi �ڵ���ռ�ڴ����������ء�
  if (!inode->i_dev)
    {
      memset (inode, 0, sizeof (*inode));
      return;
    }
// �����i �ڵ㻹�������������ã������ͷţ�˵���ں������⣬������
  if (inode->i_count > 1)
    {
      printk ("trying to free inode with count=%d\n", inode->i_count);
      panic ("free_inode");
    }
// ����ļ�Ŀ¼����������Ϊ0�����ʾ���������ļ�Ŀ¼����ʹ�øýڵ㣬��Ӧ�ͷţ���Ӧ�÷Żصȡ�
  if (inode->i_nlinks)
    panic ("trying to free inode with links");
// ȡi �ڵ������豸�ĳ����飬�����豸�Ƿ���ڡ�
  if (!(sb = get_super (inode->i_dev)))
    panic ("trying to free inode on nonexistent device");
// ���i �ڵ��=0 ����ڸ��豸��i �ڵ������������0 ��i �ڵ㱣��û��ʹ�ã���
  if (inode->i_num < 1 || inode->i_num > sb->s_ninodes)
    panic ("trying to free inode 0 or nonexistant inode");
// �����i �ڵ��Ӧ�Ľڵ�λͼ�����ڣ������
  if (!(bh = sb->s_imap[inode->i_num >> 13]))
    panic ("nonexistent imap in superblock");
// ��λi �ڵ��Ӧ�Ľڵ�λͼ�еı���λ������ñ���λ�Ѿ�����0�������
  if (clear_bit (inode->i_num & 8191, bh->b_data))
    printk ("free_inode: bit already cleared.\n\r");
// ��i �ڵ�λͼ���ڻ��������޸ı�־������ո�i �ڵ�ṹ��ռ�ڴ�����
  bh->b_dirt = 1;
  memset (inode, 0, sizeof (*inode));
}

//// Ϊ�豸dev ����һ����i �ڵ㡣���ظ���i �ڵ��ָ�롣
// ���ڴ�i �ڵ���л�ȡһ������i �ڵ�������i �ڵ�λͼ����һ������i �ڵ㡣
struct m_inode *new_inode (int dev)
{
  struct m_inode *inode;
  struct super_block *sb;
  struct buffer_head *bh;
  int i, j;

// ���ڴ�i �ڵ��(inode_table)�л�ȡһ������i �ڵ���(inode)��
  if (!(inode = get_empty_inode ()))
    return NULL;
// ��ȡָ���豸�ĳ�����ṹ��
  if (!(sb = get_super (dev)))
    panic ("new_inode with unknown device");
// ɨ��i �ڵ�λͼ��Ѱ���׸�0 ����λ��Ѱ�ҿ��нڵ㣬��ȡ���ø�i �ڵ�Ľڵ�š�
  j = 8192;
  for (i = 0; i < 8; i++)
    if (bh = sb->s_imap[i])
      if ((j = find_first_zero (bh->b_data)) < 8192)
	break;
// ���ȫ��ɨ���껹û�ҵ�������λͼ���ڵĻ������Ч(bh=NULL)�� ����0���˳���û�п���i �ڵ㣩��
  if (!bh || j >= 8192 || j + i * 8192 > sb->s_ninodes)
    {
      iput (inode);
      return NULL;
    }
// ��λ��Ӧ��i �ڵ��i �ڵ�λͼ��Ӧ����λ������Ѿ���λ�������
  if (set_bit (j, bh->b_data))
    panic ("new_inode: bit already set");
// ��i �ڵ�λͼ���ڻ��������޸ı�־��
  bh->b_dirt = 1;
// ��ʼ����i �ڵ�ṹ��
  inode->i_count = 1;		// ���ü�����
  inode->i_nlinks = 1;		// �ļ�Ŀ¼����������
  inode->i_dev = dev;		// i �ڵ����ڵ��豸�š�
  inode->i_uid = current->euid;	// i �ڵ������û�id��
  inode->i_gid = current->egid;	// ��id��
  inode->i_dirt = 1;		// ���޸ı�־��λ��
  inode->i_num = j + i * 8192;	// ��Ӧ�豸�е�i �ڵ�š�
  inode->i_mtime = inode->i_atime = inode->i_ctime = CURRENT_TIME;	// ����ʱ�䡣
  return inode;			// ���ظ�i �ڵ�ָ�롣
}
