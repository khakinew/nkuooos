//头文件保护宏，防止头文件被多次包含
#ifndef __KERN_MM_SLUB_H__ 
#define __KERN_MM_SLUB_H__

#include<defs.h>

//slab结构体
typedef struct slab 
{
    void *start; //起始地址
    size_t ob_size; //对象的大小
    size_t num_obs; //总对象数
    size_t free_obs; //空闲对象数
    struct slab *next; //指向下一个 slab
    unsigned char *flag; //标记已分配对象
} slab_ob;

//缓存结构体
typedef struct cache 
{
    slab_ob *slabs_list; //slab链表
    size_t ob_size; //对象的大小
} cache_ob;

//函数声明
cache_ob *cache_create(size_t ob_size);
void *cache_alloc(cache_ob *c);
void cache_free(cache_ob *c, void *obj);
void cache_destroy(cache_ob *c);

#endif /* !__KERN_MM_SLUB_H__ */