/*
* linux/lib/string.c
*
* (C) 1991 Linus Torvalds
*/

#ifndef __GNUC__		// ��ҪGNU ��C ���������롣
#error I want gcc!
#endif

#define extern
#define inline
#define __LIBRARY__
#include <string.h>
