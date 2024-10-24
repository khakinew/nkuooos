#include <string.h>
#include <stdio.h>
#include "slub_alloc.h"
#include "pmm.h"

//定义页的大小为4096字节
#define PAGE_SIZE 4096

//用于创建一个新的 slab
slab_ob *slab_create(size_t ob_size) 
{
    slab_ob *s = (slab_ob *)alloc_pages(1); //分配一页内存存储slab_ob
    if (s == NULL) 
        return NULL; //分配失败返回NULL
    s->start = alloc_pages(1); //分配用于对象存储的页
    if (s->start == NULL) 
    {
        free_pages((struct Page *)s, 1); //释放slab_ob所占的页
        return NULL; //分配失败返回NULL
    }
    //设置slab的对象大小、总对象数和空闲对象数
    s->ob_size = ob_size;
    s->num_obs = PAGE_SIZE / ob_size;
    s->free_obs = s->num_obs;

    s->flag = (unsigned char *)alloc_pages(1); //分配一页内存用于标记对象的分配状态
    if (s->flag == NULL) 
    {
        free_pages((struct Page *)s->start, 1); //释放对象存储页
        free_pages((struct Page *)s, 1); // 释放slab_ob所占的页
        return NULL; //分配失败返回NULL
    }

    memset(s->flag, 0, (s->num_obs + 7) / 8); //初始化标记为0，表示所有对象都是空闲的
    s->next = NULL; //将s->next设置为NULL
    return s; //返回已创建的slab指针
}

//用于创建缓存
cache_ob *cache_create(size_t ob_size) 
{
    cache_ob *c = (cache_ob *)alloc_pages(1); //为cache_ob结构体分配一页内存
    if (c == NULL) 
        return NULL; //分配失败返回NULL
    c->slabs_list = NULL; //初始化缓存的slab链表为空
    c->ob_size = ob_size; //设置对象大小
    return c; //返回缓存指针
}

//用于从缓存中分配对象
void *cache_alloc(cache_ob *c) 
{
    slab_ob *s = c->slabs_list; //将当前缓存的slab链表指针赋值给s

    //遍历slab链表，查找有空闲对象的slab
    while (s && s->free_obs == 0) 
        s = s->next;

    //如果没有空闲slab，创建新的slab，并将其加入链表
    if (!s) 
    {
        s = slab_create(c->ob_size);
        if (s == NULL) 
            return NULL; //分配失败返回NULL
        s->next = c->slabs_list;
        c->slabs_list = s;
    }

    //在slab中找到空闲对象
    for (size_t i = 0; i < s->num_obs; ++i) 
    {
        if ((s->flag[i / 8] & (1 << (i % 8))) == 0) 
        { 
            s->flag[i / 8] |= (1 << (i % 8)); //标记为已分配
            s->free_obs--; //减少空闲对象计数
            return (void *)((char *)s->start + i * s->ob_size); //返回对象的指针
        }
    }

    return NULL; //如果没有找到可用对象返回NULL
}

//用于释放对象并返回到缓存
void cache_free(cache_ob *c, void *obj) 
{
    //确保缓存和对象不为空
    if (!c || !obj) 
        return; 

    slab_ob *s = c->slabs_list;

    //查找对象所属的slab
    while (s) 
    {
        if (obj >= s->start && obj < (void *)((char *)s->start + PAGE_SIZE)) 
        {
            size_t i = ((char *)obj - (char *)s->start) / s->ob_size; //计算对象在slab中的索引
            if (i < s->num_obs) //确保索引在范围内
            { 
                s->flag[i / 8] &= ~(1 << (i % 8)); //标记为空闲
                s->free_obs++; //增加空闲对象计数
            }
            return;
        }
        s = s->next;
    }
}

//用于销毁缓存并释放资源
void cache_destroy(cache_ob *c) 
{
    if (!c) 
        return; //确保缓存不为空

    slab_ob *s = c->slabs_list;
    
    while (s) 
    {
        slab_ob *next = s->next; //保存当前slab的下一个指针
        if (s->flag) 
            free_pages((struct Page *)s->flag, 1); //释放位图所占的页
        if (s->start) 
            free_pages((struct Page *)s->start, 1); //释放对象存储的页
        free_pages((struct Page *)s, 1); //释放slab_ob所占的页
        s = next; //移动到下一个slab
    }
    free_pages((struct Page *)c, 1); //释放cache_ob所占的页
}
