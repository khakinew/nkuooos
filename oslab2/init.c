#include <stdio.h>
#include <clock.h>
#include <console.h>
#include <defs.h>
#include <intr.h>
#include <kdebug.h>
#include <kmonitor.h>
#include <pmm.h>
#include <string.h>
#include <trap.h>
#include <slub_alloc.h>

int kern_init(void) __attribute__((noreturn));
void grade_backtrace(void);

void test_slub() 
{
    cprintf("开始测试 \n");

    //创建一个缓存，大小为32字节
    cache_ob *c = cache_create(32);
    if (c == NULL) 
    {
        cprintf("缓存创建失败\n");
        return;
    }
    cprintf("缓存创建成功\n");

    //分配第一个对象
    void *ob1 = cache_alloc(c);
    if (ob1 == NULL) 
        cprintf("object1分配失败\n");
    else 
        cprintf("object1:%p\n", ob1);

    //分配第二个对象
    void *ob2 = cache_alloc(c);
    if (ob2 == NULL) 
        cprintf("object2分配失败\n");
    else 
        cprintf("object2:%p\n", ob2);

    //释放第一个对象
    if (ob1) 
    {
        cache_free(c, ob1);
        cprintf("释放 object1\n");
    }

    //再分配一个对象，验证能否复用内存
    void *ob3 = cache_alloc(c);
    if (ob3 == NULL) 
        cprintf("object3分配失败\n");
    else 
        cprintf("object3:%p\n", ob3);

    //释放所有分配的对象
    if (ob2) 
    {
        cache_free(c, ob2);
        cprintf("释放 object2\n");
    }
    if (ob3) 
    {
        cache_free(c, ob3);
        cprintf("释放 object3\n");
    }

    //销毁缓存，释放所有资源
    cache_destroy(c);
    cprintf("测试结束\n");
}

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
    cons_init();  // init the console
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);

    print_kerninfo();

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table

    pmm_init();  // init physical memory management

    idt_init();  // init interrupt descriptor table

    clock_init();   // init clock interrupt
    intr_enable();  // enable irq interrupt

    test_slub();    
    
    /* do nothing */
   while(1);
}

void __attribute__((noinline))
grade_backtrace2(int arg0, int arg1, int arg2, int arg3) {
    mon_backtrace(0, NULL, NULL);
}

void __attribute__((noinline)) grade_backtrace1(int arg0, int arg1) {
    grade_backtrace2(arg0, (uintptr_t)&arg0, arg1, (uintptr_t)&arg1);
}

void __attribute__((noinline)) grade_backtrace0(int arg0, int arg1, int arg2) {
    grade_backtrace1(arg0, arg2);
}

void grade_backtrace(void) { grade_backtrace0(0, (uintptr_t)kern_init, 0xffff0000); }

static void lab1_print_cur_status(void) {
    static int round = 0;
    round++;
}