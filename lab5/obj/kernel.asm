
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200000:	c020b2b7          	lui	t0,0xc020b
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc0200004:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200008:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc020000a:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc020000e:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc0200012:	fff0031b          	addiw	t1,zero,-1
ffffffffc0200016:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200018:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc020001c:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200020:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc0200024:	c020b137          	lui	sp,0xc020b

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200028:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc020002c:	03228293          	addi	t0,t0,50 # ffffffffc0200032 <kern_init>
    jr t0
ffffffffc0200030:	8282                	jr	t0

ffffffffc0200032 <kern_init>:
void grade_backtrace(void);

int
kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc0200032:	000a7517          	auipc	a0,0xa7
ffffffffc0200036:	33e50513          	addi	a0,a0,830 # ffffffffc02a7370 <buf>
ffffffffc020003a:	000b3617          	auipc	a2,0xb3
ffffffffc020003e:	89260613          	addi	a2,a2,-1902 # ffffffffc02b28cc <end>
kern_init(void) {
ffffffffc0200042:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200044:	8e09                	sub	a2,a2,a0
ffffffffc0200046:	4581                	li	a1,0
kern_init(void) {
ffffffffc0200048:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004a:	462060ef          	jal	ra,ffffffffc02064ac <memset>
    cons_init();                // init the console
ffffffffc020004e:	52a000ef          	jal	ra,ffffffffc0200578 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc0200052:	00006597          	auipc	a1,0x6
ffffffffc0200056:	48658593          	addi	a1,a1,1158 # ffffffffc02064d8 <etext+0x2>
ffffffffc020005a:	00006517          	auipc	a0,0x6
ffffffffc020005e:	49e50513          	addi	a0,a0,1182 # ffffffffc02064f8 <etext+0x22>
ffffffffc0200062:	11e000ef          	jal	ra,ffffffffc0200180 <cprintf>

    print_kerninfo();
ffffffffc0200066:	1a2000ef          	jal	ra,ffffffffc0200208 <print_kerninfo>

    // grade_backtrace();

    pmm_init();                 // init physical memory management
ffffffffc020006a:	512020ef          	jal	ra,ffffffffc020257c <pmm_init>

    pic_init();                 // init interrupt controller
ffffffffc020006e:	5de000ef          	jal	ra,ffffffffc020064c <pic_init>
    idt_init();                 // init interrupt descriptor table
ffffffffc0200072:	5dc000ef          	jal	ra,ffffffffc020064e <idt_init>

    vmm_init();                 // init virtual memory management
ffffffffc0200076:	330040ef          	jal	ra,ffffffffc02043a6 <vmm_init>
    proc_init();                // init process table
ffffffffc020007a:	3ab050ef          	jal	ra,ffffffffc0205c24 <proc_init>
    
    ide_init();                 // init ide devices
ffffffffc020007e:	56c000ef          	jal	ra,ffffffffc02005ea <ide_init>
    swap_init();                // init swap
ffffffffc0200082:	3a0030ef          	jal	ra,ffffffffc0203422 <swap_init>

    clock_init();               // init clock interrupt
ffffffffc0200086:	4a0000ef          	jal	ra,ffffffffc0200526 <clock_init>
    intr_enable();              // enable irq interrupt
ffffffffc020008a:	5b6000ef          	jal	ra,ffffffffc0200640 <intr_enable>
    
    cpu_idle();                 // run idle process
ffffffffc020008e:	52f050ef          	jal	ra,ffffffffc0205dbc <cpu_idle>

ffffffffc0200092 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0200092:	715d                	addi	sp,sp,-80
ffffffffc0200094:	e486                	sd	ra,72(sp)
ffffffffc0200096:	e0a6                	sd	s1,64(sp)
ffffffffc0200098:	fc4a                	sd	s2,56(sp)
ffffffffc020009a:	f84e                	sd	s3,48(sp)
ffffffffc020009c:	f452                	sd	s4,40(sp)
ffffffffc020009e:	f056                	sd	s5,32(sp)
ffffffffc02000a0:	ec5a                	sd	s6,24(sp)
ffffffffc02000a2:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc02000a4:	c901                	beqz	a0,ffffffffc02000b4 <readline+0x22>
ffffffffc02000a6:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc02000a8:	00006517          	auipc	a0,0x6
ffffffffc02000ac:	45850513          	addi	a0,a0,1112 # ffffffffc0206500 <etext+0x2a>
ffffffffc02000b0:	0d0000ef          	jal	ra,ffffffffc0200180 <cprintf>
readline(const char *prompt) {
ffffffffc02000b4:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000b6:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc02000b8:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02000ba:	4aa9                	li	s5,10
ffffffffc02000bc:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc02000be:	000a7b97          	auipc	s7,0xa7
ffffffffc02000c2:	2b2b8b93          	addi	s7,s7,690 # ffffffffc02a7370 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000c6:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc02000ca:	12e000ef          	jal	ra,ffffffffc02001f8 <getchar>
        if (c < 0) {
ffffffffc02000ce:	00054a63          	bltz	a0,ffffffffc02000e2 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000d2:	00a95a63          	bge	s2,a0,ffffffffc02000e6 <readline+0x54>
ffffffffc02000d6:	029a5263          	bge	s4,s1,ffffffffc02000fa <readline+0x68>
        c = getchar();
ffffffffc02000da:	11e000ef          	jal	ra,ffffffffc02001f8 <getchar>
        if (c < 0) {
ffffffffc02000de:	fe055ae3          	bgez	a0,ffffffffc02000d2 <readline+0x40>
            return NULL;
ffffffffc02000e2:	4501                	li	a0,0
ffffffffc02000e4:	a091                	j	ffffffffc0200128 <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc02000e6:	03351463          	bne	a0,s3,ffffffffc020010e <readline+0x7c>
ffffffffc02000ea:	e8a9                	bnez	s1,ffffffffc020013c <readline+0xaa>
        c = getchar();
ffffffffc02000ec:	10c000ef          	jal	ra,ffffffffc02001f8 <getchar>
        if (c < 0) {
ffffffffc02000f0:	fe0549e3          	bltz	a0,ffffffffc02000e2 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000f4:	fea959e3          	bge	s2,a0,ffffffffc02000e6 <readline+0x54>
ffffffffc02000f8:	4481                	li	s1,0
            cputchar(c);
ffffffffc02000fa:	e42a                	sd	a0,8(sp)
ffffffffc02000fc:	0ba000ef          	jal	ra,ffffffffc02001b6 <cputchar>
            buf[i ++] = c;
ffffffffc0200100:	6522                	ld	a0,8(sp)
ffffffffc0200102:	009b87b3          	add	a5,s7,s1
ffffffffc0200106:	2485                	addiw	s1,s1,1
ffffffffc0200108:	00a78023          	sb	a0,0(a5)
ffffffffc020010c:	bf7d                	j	ffffffffc02000ca <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc020010e:	01550463          	beq	a0,s5,ffffffffc0200116 <readline+0x84>
ffffffffc0200112:	fb651ce3          	bne	a0,s6,ffffffffc02000ca <readline+0x38>
            cputchar(c);
ffffffffc0200116:	0a0000ef          	jal	ra,ffffffffc02001b6 <cputchar>
            buf[i] = '\0';
ffffffffc020011a:	000a7517          	auipc	a0,0xa7
ffffffffc020011e:	25650513          	addi	a0,a0,598 # ffffffffc02a7370 <buf>
ffffffffc0200122:	94aa                	add	s1,s1,a0
ffffffffc0200124:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0200128:	60a6                	ld	ra,72(sp)
ffffffffc020012a:	6486                	ld	s1,64(sp)
ffffffffc020012c:	7962                	ld	s2,56(sp)
ffffffffc020012e:	79c2                	ld	s3,48(sp)
ffffffffc0200130:	7a22                	ld	s4,40(sp)
ffffffffc0200132:	7a82                	ld	s5,32(sp)
ffffffffc0200134:	6b62                	ld	s6,24(sp)
ffffffffc0200136:	6bc2                	ld	s7,16(sp)
ffffffffc0200138:	6161                	addi	sp,sp,80
ffffffffc020013a:	8082                	ret
            cputchar(c);
ffffffffc020013c:	4521                	li	a0,8
ffffffffc020013e:	078000ef          	jal	ra,ffffffffc02001b6 <cputchar>
            i --;
ffffffffc0200142:	34fd                	addiw	s1,s1,-1
ffffffffc0200144:	b759                	j	ffffffffc02000ca <readline+0x38>

ffffffffc0200146 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200146:	1141                	addi	sp,sp,-16
ffffffffc0200148:	e022                	sd	s0,0(sp)
ffffffffc020014a:	e406                	sd	ra,8(sp)
ffffffffc020014c:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc020014e:	42c000ef          	jal	ra,ffffffffc020057a <cons_putc>
    (*cnt) ++;
ffffffffc0200152:	401c                	lw	a5,0(s0)
}
ffffffffc0200154:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200156:	2785                	addiw	a5,a5,1
ffffffffc0200158:	c01c                	sw	a5,0(s0)
}
ffffffffc020015a:	6402                	ld	s0,0(sp)
ffffffffc020015c:	0141                	addi	sp,sp,16
ffffffffc020015e:	8082                	ret

ffffffffc0200160 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200160:	1101                	addi	sp,sp,-32
ffffffffc0200162:	862a                	mv	a2,a0
ffffffffc0200164:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200166:	00000517          	auipc	a0,0x0
ffffffffc020016a:	fe050513          	addi	a0,a0,-32 # ffffffffc0200146 <cputch>
ffffffffc020016e:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200170:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200172:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200174:	73b050ef          	jal	ra,ffffffffc02060ae <vprintfmt>
    return cnt;
}
ffffffffc0200178:	60e2                	ld	ra,24(sp)
ffffffffc020017a:	4532                	lw	a0,12(sp)
ffffffffc020017c:	6105                	addi	sp,sp,32
ffffffffc020017e:	8082                	ret

ffffffffc0200180 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc0200180:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200182:	02810313          	addi	t1,sp,40 # ffffffffc020b028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc0200186:	8e2a                	mv	t3,a0
ffffffffc0200188:	f42e                	sd	a1,40(sp)
ffffffffc020018a:	f832                	sd	a2,48(sp)
ffffffffc020018c:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020018e:	00000517          	auipc	a0,0x0
ffffffffc0200192:	fb850513          	addi	a0,a0,-72 # ffffffffc0200146 <cputch>
ffffffffc0200196:	004c                	addi	a1,sp,4
ffffffffc0200198:	869a                	mv	a3,t1
ffffffffc020019a:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc020019c:	ec06                	sd	ra,24(sp)
ffffffffc020019e:	e0ba                	sd	a4,64(sp)
ffffffffc02001a0:	e4be                	sd	a5,72(sp)
ffffffffc02001a2:	e8c2                	sd	a6,80(sp)
ffffffffc02001a4:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02001a6:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02001a8:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02001aa:	705050ef          	jal	ra,ffffffffc02060ae <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02001ae:	60e2                	ld	ra,24(sp)
ffffffffc02001b0:	4512                	lw	a0,4(sp)
ffffffffc02001b2:	6125                	addi	sp,sp,96
ffffffffc02001b4:	8082                	ret

ffffffffc02001b6 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc02001b6:	a6d1                	j	ffffffffc020057a <cons_putc>

ffffffffc02001b8 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc02001b8:	1101                	addi	sp,sp,-32
ffffffffc02001ba:	e822                	sd	s0,16(sp)
ffffffffc02001bc:	ec06                	sd	ra,24(sp)
ffffffffc02001be:	e426                	sd	s1,8(sp)
ffffffffc02001c0:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc02001c2:	00054503          	lbu	a0,0(a0)
ffffffffc02001c6:	c51d                	beqz	a0,ffffffffc02001f4 <cputs+0x3c>
ffffffffc02001c8:	0405                	addi	s0,s0,1
ffffffffc02001ca:	4485                	li	s1,1
ffffffffc02001cc:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc02001ce:	3ac000ef          	jal	ra,ffffffffc020057a <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc02001d2:	00044503          	lbu	a0,0(s0)
ffffffffc02001d6:	008487bb          	addw	a5,s1,s0
ffffffffc02001da:	0405                	addi	s0,s0,1
ffffffffc02001dc:	f96d                	bnez	a0,ffffffffc02001ce <cputs+0x16>
    (*cnt) ++;
ffffffffc02001de:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001e2:	4529                	li	a0,10
ffffffffc02001e4:	396000ef          	jal	ra,ffffffffc020057a <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001e8:	60e2                	ld	ra,24(sp)
ffffffffc02001ea:	8522                	mv	a0,s0
ffffffffc02001ec:	6442                	ld	s0,16(sp)
ffffffffc02001ee:	64a2                	ld	s1,8(sp)
ffffffffc02001f0:	6105                	addi	sp,sp,32
ffffffffc02001f2:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc02001f4:	4405                	li	s0,1
ffffffffc02001f6:	b7f5                	j	ffffffffc02001e2 <cputs+0x2a>

ffffffffc02001f8 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc02001f8:	1141                	addi	sp,sp,-16
ffffffffc02001fa:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc02001fc:	3b2000ef          	jal	ra,ffffffffc02005ae <cons_getc>
ffffffffc0200200:	dd75                	beqz	a0,ffffffffc02001fc <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200202:	60a2                	ld	ra,8(sp)
ffffffffc0200204:	0141                	addi	sp,sp,16
ffffffffc0200206:	8082                	ret

ffffffffc0200208 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc0200208:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc020020a:	00006517          	auipc	a0,0x6
ffffffffc020020e:	2fe50513          	addi	a0,a0,766 # ffffffffc0206508 <etext+0x32>
void print_kerninfo(void) {
ffffffffc0200212:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200214:	f6dff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc0200218:	00000597          	auipc	a1,0x0
ffffffffc020021c:	e1a58593          	addi	a1,a1,-486 # ffffffffc0200032 <kern_init>
ffffffffc0200220:	00006517          	auipc	a0,0x6
ffffffffc0200224:	30850513          	addi	a0,a0,776 # ffffffffc0206528 <etext+0x52>
ffffffffc0200228:	f59ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc020022c:	00006597          	auipc	a1,0x6
ffffffffc0200230:	2aa58593          	addi	a1,a1,682 # ffffffffc02064d6 <etext>
ffffffffc0200234:	00006517          	auipc	a0,0x6
ffffffffc0200238:	31450513          	addi	a0,a0,788 # ffffffffc0206548 <etext+0x72>
ffffffffc020023c:	f45ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200240:	000a7597          	auipc	a1,0xa7
ffffffffc0200244:	13058593          	addi	a1,a1,304 # ffffffffc02a7370 <buf>
ffffffffc0200248:	00006517          	auipc	a0,0x6
ffffffffc020024c:	32050513          	addi	a0,a0,800 # ffffffffc0206568 <etext+0x92>
ffffffffc0200250:	f31ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200254:	000b2597          	auipc	a1,0xb2
ffffffffc0200258:	67858593          	addi	a1,a1,1656 # ffffffffc02b28cc <end>
ffffffffc020025c:	00006517          	auipc	a0,0x6
ffffffffc0200260:	32c50513          	addi	a0,a0,812 # ffffffffc0206588 <etext+0xb2>
ffffffffc0200264:	f1dff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc0200268:	000b3597          	auipc	a1,0xb3
ffffffffc020026c:	a6358593          	addi	a1,a1,-1437 # ffffffffc02b2ccb <end+0x3ff>
ffffffffc0200270:	00000797          	auipc	a5,0x0
ffffffffc0200274:	dc278793          	addi	a5,a5,-574 # ffffffffc0200032 <kern_init>
ffffffffc0200278:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020027c:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc0200280:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200282:	3ff5f593          	andi	a1,a1,1023
ffffffffc0200286:	95be                	add	a1,a1,a5
ffffffffc0200288:	85a9                	srai	a1,a1,0xa
ffffffffc020028a:	00006517          	auipc	a0,0x6
ffffffffc020028e:	31e50513          	addi	a0,a0,798 # ffffffffc02065a8 <etext+0xd2>
}
ffffffffc0200292:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200294:	b5f5                	j	ffffffffc0200180 <cprintf>

ffffffffc0200296 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc0200296:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc0200298:	00006617          	auipc	a2,0x6
ffffffffc020029c:	34060613          	addi	a2,a2,832 # ffffffffc02065d8 <etext+0x102>
ffffffffc02002a0:	04d00593          	li	a1,77
ffffffffc02002a4:	00006517          	auipc	a0,0x6
ffffffffc02002a8:	34c50513          	addi	a0,a0,844 # ffffffffc02065f0 <etext+0x11a>
void print_stackframe(void) {
ffffffffc02002ac:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02002ae:	1cc000ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc02002b2 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002b2:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002b4:	00006617          	auipc	a2,0x6
ffffffffc02002b8:	35460613          	addi	a2,a2,852 # ffffffffc0206608 <etext+0x132>
ffffffffc02002bc:	00006597          	auipc	a1,0x6
ffffffffc02002c0:	36c58593          	addi	a1,a1,876 # ffffffffc0206628 <etext+0x152>
ffffffffc02002c4:	00006517          	auipc	a0,0x6
ffffffffc02002c8:	36c50513          	addi	a0,a0,876 # ffffffffc0206630 <etext+0x15a>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002cc:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002ce:	eb3ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
ffffffffc02002d2:	00006617          	auipc	a2,0x6
ffffffffc02002d6:	36e60613          	addi	a2,a2,878 # ffffffffc0206640 <etext+0x16a>
ffffffffc02002da:	00006597          	auipc	a1,0x6
ffffffffc02002de:	38e58593          	addi	a1,a1,910 # ffffffffc0206668 <etext+0x192>
ffffffffc02002e2:	00006517          	auipc	a0,0x6
ffffffffc02002e6:	34e50513          	addi	a0,a0,846 # ffffffffc0206630 <etext+0x15a>
ffffffffc02002ea:	e97ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
ffffffffc02002ee:	00006617          	auipc	a2,0x6
ffffffffc02002f2:	38a60613          	addi	a2,a2,906 # ffffffffc0206678 <etext+0x1a2>
ffffffffc02002f6:	00006597          	auipc	a1,0x6
ffffffffc02002fa:	3a258593          	addi	a1,a1,930 # ffffffffc0206698 <etext+0x1c2>
ffffffffc02002fe:	00006517          	auipc	a0,0x6
ffffffffc0200302:	33250513          	addi	a0,a0,818 # ffffffffc0206630 <etext+0x15a>
ffffffffc0200306:	e7bff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    }
    return 0;
}
ffffffffc020030a:	60a2                	ld	ra,8(sp)
ffffffffc020030c:	4501                	li	a0,0
ffffffffc020030e:	0141                	addi	sp,sp,16
ffffffffc0200310:	8082                	ret

ffffffffc0200312 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200312:	1141                	addi	sp,sp,-16
ffffffffc0200314:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc0200316:	ef3ff0ef          	jal	ra,ffffffffc0200208 <print_kerninfo>
    return 0;
}
ffffffffc020031a:	60a2                	ld	ra,8(sp)
ffffffffc020031c:	4501                	li	a0,0
ffffffffc020031e:	0141                	addi	sp,sp,16
ffffffffc0200320:	8082                	ret

ffffffffc0200322 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200322:	1141                	addi	sp,sp,-16
ffffffffc0200324:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc0200326:	f71ff0ef          	jal	ra,ffffffffc0200296 <print_stackframe>
    return 0;
}
ffffffffc020032a:	60a2                	ld	ra,8(sp)
ffffffffc020032c:	4501                	li	a0,0
ffffffffc020032e:	0141                	addi	sp,sp,16
ffffffffc0200330:	8082                	ret

ffffffffc0200332 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc0200332:	7115                	addi	sp,sp,-224
ffffffffc0200334:	ed5e                	sd	s7,152(sp)
ffffffffc0200336:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200338:	00006517          	auipc	a0,0x6
ffffffffc020033c:	37050513          	addi	a0,a0,880 # ffffffffc02066a8 <etext+0x1d2>
kmonitor(struct trapframe *tf) {
ffffffffc0200340:	ed86                	sd	ra,216(sp)
ffffffffc0200342:	e9a2                	sd	s0,208(sp)
ffffffffc0200344:	e5a6                	sd	s1,200(sp)
ffffffffc0200346:	e1ca                	sd	s2,192(sp)
ffffffffc0200348:	fd4e                	sd	s3,184(sp)
ffffffffc020034a:	f952                	sd	s4,176(sp)
ffffffffc020034c:	f556                	sd	s5,168(sp)
ffffffffc020034e:	f15a                	sd	s6,160(sp)
ffffffffc0200350:	e962                	sd	s8,144(sp)
ffffffffc0200352:	e566                	sd	s9,136(sp)
ffffffffc0200354:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200356:	e2bff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020035a:	00006517          	auipc	a0,0x6
ffffffffc020035e:	37650513          	addi	a0,a0,886 # ffffffffc02066d0 <etext+0x1fa>
ffffffffc0200362:	e1fff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    if (tf != NULL) {
ffffffffc0200366:	000b8563          	beqz	s7,ffffffffc0200370 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020036a:	855e                	mv	a0,s7
ffffffffc020036c:	4c8000ef          	jal	ra,ffffffffc0200834 <print_trapframe>
ffffffffc0200370:	00006c17          	auipc	s8,0x6
ffffffffc0200374:	3d0c0c13          	addi	s8,s8,976 # ffffffffc0206740 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200378:	00006917          	auipc	s2,0x6
ffffffffc020037c:	38090913          	addi	s2,s2,896 # ffffffffc02066f8 <etext+0x222>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200380:	00006497          	auipc	s1,0x6
ffffffffc0200384:	38048493          	addi	s1,s1,896 # ffffffffc0206700 <etext+0x22a>
        if (argc == MAXARGS - 1) {
ffffffffc0200388:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020038a:	00006b17          	auipc	s6,0x6
ffffffffc020038e:	37eb0b13          	addi	s6,s6,894 # ffffffffc0206708 <etext+0x232>
        argv[argc ++] = buf;
ffffffffc0200392:	00006a17          	auipc	s4,0x6
ffffffffc0200396:	296a0a13          	addi	s4,s4,662 # ffffffffc0206628 <etext+0x152>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020039a:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc020039c:	854a                	mv	a0,s2
ffffffffc020039e:	cf5ff0ef          	jal	ra,ffffffffc0200092 <readline>
ffffffffc02003a2:	842a                	mv	s0,a0
ffffffffc02003a4:	dd65                	beqz	a0,ffffffffc020039c <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003a6:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02003aa:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003ac:	e1bd                	bnez	a1,ffffffffc0200412 <kmonitor+0xe0>
    if (argc == 0) {
ffffffffc02003ae:	fe0c87e3          	beqz	s9,ffffffffc020039c <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003b2:	6582                	ld	a1,0(sp)
ffffffffc02003b4:	00006d17          	auipc	s10,0x6
ffffffffc02003b8:	38cd0d13          	addi	s10,s10,908 # ffffffffc0206740 <commands>
        argv[argc ++] = buf;
ffffffffc02003bc:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003be:	4401                	li	s0,0
ffffffffc02003c0:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003c2:	0b6060ef          	jal	ra,ffffffffc0206478 <strcmp>
ffffffffc02003c6:	c919                	beqz	a0,ffffffffc02003dc <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003c8:	2405                	addiw	s0,s0,1
ffffffffc02003ca:	0b540063          	beq	s0,s5,ffffffffc020046a <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003ce:	000d3503          	ld	a0,0(s10)
ffffffffc02003d2:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003d4:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003d6:	0a2060ef          	jal	ra,ffffffffc0206478 <strcmp>
ffffffffc02003da:	f57d                	bnez	a0,ffffffffc02003c8 <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc02003dc:	00141793          	slli	a5,s0,0x1
ffffffffc02003e0:	97a2                	add	a5,a5,s0
ffffffffc02003e2:	078e                	slli	a5,a5,0x3
ffffffffc02003e4:	97e2                	add	a5,a5,s8
ffffffffc02003e6:	6b9c                	ld	a5,16(a5)
ffffffffc02003e8:	865e                	mv	a2,s7
ffffffffc02003ea:	002c                	addi	a1,sp,8
ffffffffc02003ec:	fffc851b          	addiw	a0,s9,-1
ffffffffc02003f0:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc02003f2:	fa0555e3          	bgez	a0,ffffffffc020039c <kmonitor+0x6a>
}
ffffffffc02003f6:	60ee                	ld	ra,216(sp)
ffffffffc02003f8:	644e                	ld	s0,208(sp)
ffffffffc02003fa:	64ae                	ld	s1,200(sp)
ffffffffc02003fc:	690e                	ld	s2,192(sp)
ffffffffc02003fe:	79ea                	ld	s3,184(sp)
ffffffffc0200400:	7a4a                	ld	s4,176(sp)
ffffffffc0200402:	7aaa                	ld	s5,168(sp)
ffffffffc0200404:	7b0a                	ld	s6,160(sp)
ffffffffc0200406:	6bea                	ld	s7,152(sp)
ffffffffc0200408:	6c4a                	ld	s8,144(sp)
ffffffffc020040a:	6caa                	ld	s9,136(sp)
ffffffffc020040c:	6d0a                	ld	s10,128(sp)
ffffffffc020040e:	612d                	addi	sp,sp,224
ffffffffc0200410:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200412:	8526                	mv	a0,s1
ffffffffc0200414:	082060ef          	jal	ra,ffffffffc0206496 <strchr>
ffffffffc0200418:	c901                	beqz	a0,ffffffffc0200428 <kmonitor+0xf6>
ffffffffc020041a:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc020041e:	00040023          	sb	zero,0(s0)
ffffffffc0200422:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200424:	d5c9                	beqz	a1,ffffffffc02003ae <kmonitor+0x7c>
ffffffffc0200426:	b7f5                	j	ffffffffc0200412 <kmonitor+0xe0>
        if (*buf == '\0') {
ffffffffc0200428:	00044783          	lbu	a5,0(s0)
ffffffffc020042c:	d3c9                	beqz	a5,ffffffffc02003ae <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc020042e:	033c8963          	beq	s9,s3,ffffffffc0200460 <kmonitor+0x12e>
        argv[argc ++] = buf;
ffffffffc0200432:	003c9793          	slli	a5,s9,0x3
ffffffffc0200436:	0118                	addi	a4,sp,128
ffffffffc0200438:	97ba                	add	a5,a5,a4
ffffffffc020043a:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020043e:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc0200442:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200444:	e591                	bnez	a1,ffffffffc0200450 <kmonitor+0x11e>
ffffffffc0200446:	b7b5                	j	ffffffffc02003b2 <kmonitor+0x80>
ffffffffc0200448:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc020044c:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020044e:	d1a5                	beqz	a1,ffffffffc02003ae <kmonitor+0x7c>
ffffffffc0200450:	8526                	mv	a0,s1
ffffffffc0200452:	044060ef          	jal	ra,ffffffffc0206496 <strchr>
ffffffffc0200456:	d96d                	beqz	a0,ffffffffc0200448 <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200458:	00044583          	lbu	a1,0(s0)
ffffffffc020045c:	d9a9                	beqz	a1,ffffffffc02003ae <kmonitor+0x7c>
ffffffffc020045e:	bf55                	j	ffffffffc0200412 <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200460:	45c1                	li	a1,16
ffffffffc0200462:	855a                	mv	a0,s6
ffffffffc0200464:	d1dff0ef          	jal	ra,ffffffffc0200180 <cprintf>
ffffffffc0200468:	b7e9                	j	ffffffffc0200432 <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc020046a:	6582                	ld	a1,0(sp)
ffffffffc020046c:	00006517          	auipc	a0,0x6
ffffffffc0200470:	2bc50513          	addi	a0,a0,700 # ffffffffc0206728 <etext+0x252>
ffffffffc0200474:	d0dff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    return 0;
ffffffffc0200478:	b715                	j	ffffffffc020039c <kmonitor+0x6a>

ffffffffc020047a <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc020047a:	000b2317          	auipc	t1,0xb2
ffffffffc020047e:	3be30313          	addi	t1,t1,958 # ffffffffc02b2838 <is_panic>
ffffffffc0200482:	00033e03          	ld	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc0200486:	715d                	addi	sp,sp,-80
ffffffffc0200488:	ec06                	sd	ra,24(sp)
ffffffffc020048a:	e822                	sd	s0,16(sp)
ffffffffc020048c:	f436                	sd	a3,40(sp)
ffffffffc020048e:	f83a                	sd	a4,48(sp)
ffffffffc0200490:	fc3e                	sd	a5,56(sp)
ffffffffc0200492:	e0c2                	sd	a6,64(sp)
ffffffffc0200494:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc0200496:	020e1a63          	bnez	t3,ffffffffc02004ca <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc020049a:	4785                	li	a5,1
ffffffffc020049c:	00f33023          	sd	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02004a0:	8432                	mv	s0,a2
ffffffffc02004a2:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004a4:	862e                	mv	a2,a1
ffffffffc02004a6:	85aa                	mv	a1,a0
ffffffffc02004a8:	00006517          	auipc	a0,0x6
ffffffffc02004ac:	2e050513          	addi	a0,a0,736 # ffffffffc0206788 <commands+0x48>
    va_start(ap, fmt);
ffffffffc02004b0:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004b2:	ccfff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02004b6:	65a2                	ld	a1,8(sp)
ffffffffc02004b8:	8522                	mv	a0,s0
ffffffffc02004ba:	ca7ff0ef          	jal	ra,ffffffffc0200160 <vcprintf>
    cprintf("\n");
ffffffffc02004be:	00007517          	auipc	a0,0x7
ffffffffc02004c2:	28250513          	addi	a0,a0,642 # ffffffffc0207740 <default_pmm_manager+0x518>
ffffffffc02004c6:	cbbff0ef          	jal	ra,ffffffffc0200180 <cprintf>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc02004ca:	4501                	li	a0,0
ffffffffc02004cc:	4581                	li	a1,0
ffffffffc02004ce:	4601                	li	a2,0
ffffffffc02004d0:	48a1                	li	a7,8
ffffffffc02004d2:	00000073          	ecall
    va_end(ap);

panic_dead:
    // No debug monitor here
    sbi_shutdown();
    intr_disable();
ffffffffc02004d6:	170000ef          	jal	ra,ffffffffc0200646 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc02004da:	4501                	li	a0,0
ffffffffc02004dc:	e57ff0ef          	jal	ra,ffffffffc0200332 <kmonitor>
    while (1) {
ffffffffc02004e0:	bfed                	j	ffffffffc02004da <__panic+0x60>

ffffffffc02004e2 <__warn>:
    }
}

/* __warn - like panic, but don't */
void
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc02004e2:	715d                	addi	sp,sp,-80
ffffffffc02004e4:	832e                	mv	t1,a1
ffffffffc02004e6:	e822                	sd	s0,16(sp)
    va_list ap;
    va_start(ap, fmt);
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc02004e8:	85aa                	mv	a1,a0
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc02004ea:	8432                	mv	s0,a2
ffffffffc02004ec:	fc3e                	sd	a5,56(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc02004ee:	861a                	mv	a2,t1
    va_start(ap, fmt);
ffffffffc02004f0:	103c                	addi	a5,sp,40
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc02004f2:	00006517          	auipc	a0,0x6
ffffffffc02004f6:	2b650513          	addi	a0,a0,694 # ffffffffc02067a8 <commands+0x68>
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc02004fa:	ec06                	sd	ra,24(sp)
ffffffffc02004fc:	f436                	sd	a3,40(sp)
ffffffffc02004fe:	f83a                	sd	a4,48(sp)
ffffffffc0200500:	e0c2                	sd	a6,64(sp)
ffffffffc0200502:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0200504:	e43e                	sd	a5,8(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200506:	c7bff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    vcprintf(fmt, ap);
ffffffffc020050a:	65a2                	ld	a1,8(sp)
ffffffffc020050c:	8522                	mv	a0,s0
ffffffffc020050e:	c53ff0ef          	jal	ra,ffffffffc0200160 <vcprintf>
    cprintf("\n");
ffffffffc0200512:	00007517          	auipc	a0,0x7
ffffffffc0200516:	22e50513          	addi	a0,a0,558 # ffffffffc0207740 <default_pmm_manager+0x518>
ffffffffc020051a:	c67ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    va_end(ap);
}
ffffffffc020051e:	60e2                	ld	ra,24(sp)
ffffffffc0200520:	6442                	ld	s0,16(sp)
ffffffffc0200522:	6161                	addi	sp,sp,80
ffffffffc0200524:	8082                	ret

ffffffffc0200526 <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc0200526:	67e1                	lui	a5,0x18
ffffffffc0200528:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_exit_out_size+0xd578>
ffffffffc020052c:	000b2717          	auipc	a4,0xb2
ffffffffc0200530:	30f73e23          	sd	a5,796(a4) # ffffffffc02b2848 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200534:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc0200538:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020053a:	953e                	add	a0,a0,a5
ffffffffc020053c:	4601                	li	a2,0
ffffffffc020053e:	4881                	li	a7,0
ffffffffc0200540:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc0200544:	02000793          	li	a5,32
ffffffffc0200548:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc020054c:	00006517          	auipc	a0,0x6
ffffffffc0200550:	27c50513          	addi	a0,a0,636 # ffffffffc02067c8 <commands+0x88>
    ticks = 0;
ffffffffc0200554:	000b2797          	auipc	a5,0xb2
ffffffffc0200558:	2e07b623          	sd	zero,748(a5) # ffffffffc02b2840 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020055c:	b115                	j	ffffffffc0200180 <cprintf>

ffffffffc020055e <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020055e:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200562:	000b2797          	auipc	a5,0xb2
ffffffffc0200566:	2e67b783          	ld	a5,742(a5) # ffffffffc02b2848 <timebase>
ffffffffc020056a:	953e                	add	a0,a0,a5
ffffffffc020056c:	4581                	li	a1,0
ffffffffc020056e:	4601                	li	a2,0
ffffffffc0200570:	4881                	li	a7,0
ffffffffc0200572:	00000073          	ecall
ffffffffc0200576:	8082                	ret

ffffffffc0200578 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200578:	8082                	ret

ffffffffc020057a <cons_putc>:
#include <sched.h>
#include <riscv.h>
#include <assert.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020057a:	100027f3          	csrr	a5,sstatus
ffffffffc020057e:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc0200580:	0ff57513          	zext.b	a0,a0
ffffffffc0200584:	e799                	bnez	a5,ffffffffc0200592 <cons_putc+0x18>
ffffffffc0200586:	4581                	li	a1,0
ffffffffc0200588:	4601                	li	a2,0
ffffffffc020058a:	4885                	li	a7,1
ffffffffc020058c:	00000073          	ecall
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
ffffffffc0200590:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc0200592:	1101                	addi	sp,sp,-32
ffffffffc0200594:	ec06                	sd	ra,24(sp)
ffffffffc0200596:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0200598:	0ae000ef          	jal	ra,ffffffffc0200646 <intr_disable>
ffffffffc020059c:	6522                	ld	a0,8(sp)
ffffffffc020059e:	4581                	li	a1,0
ffffffffc02005a0:	4601                	li	a2,0
ffffffffc02005a2:	4885                	li	a7,1
ffffffffc02005a4:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc02005a8:	60e2                	ld	ra,24(sp)
ffffffffc02005aa:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02005ac:	a851                	j	ffffffffc0200640 <intr_enable>

ffffffffc02005ae <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02005ae:	100027f3          	csrr	a5,sstatus
ffffffffc02005b2:	8b89                	andi	a5,a5,2
ffffffffc02005b4:	eb89                	bnez	a5,ffffffffc02005c6 <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc02005b6:	4501                	li	a0,0
ffffffffc02005b8:	4581                	li	a1,0
ffffffffc02005ba:	4601                	li	a2,0
ffffffffc02005bc:	4889                	li	a7,2
ffffffffc02005be:	00000073          	ecall
ffffffffc02005c2:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc02005c4:	8082                	ret
int cons_getc(void) {
ffffffffc02005c6:	1101                	addi	sp,sp,-32
ffffffffc02005c8:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc02005ca:	07c000ef          	jal	ra,ffffffffc0200646 <intr_disable>
ffffffffc02005ce:	4501                	li	a0,0
ffffffffc02005d0:	4581                	li	a1,0
ffffffffc02005d2:	4601                	li	a2,0
ffffffffc02005d4:	4889                	li	a7,2
ffffffffc02005d6:	00000073          	ecall
ffffffffc02005da:	2501                	sext.w	a0,a0
ffffffffc02005dc:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02005de:	062000ef          	jal	ra,ffffffffc0200640 <intr_enable>
}
ffffffffc02005e2:	60e2                	ld	ra,24(sp)
ffffffffc02005e4:	6522                	ld	a0,8(sp)
ffffffffc02005e6:	6105                	addi	sp,sp,32
ffffffffc02005e8:	8082                	ret

ffffffffc02005ea <ide_init>:
#include <stdio.h>
#include <string.h>
#include <trap.h>
#include <riscv.h>

void ide_init(void) {}
ffffffffc02005ea:	8082                	ret

ffffffffc02005ec <ide_device_valid>:

#define MAX_IDE 2
#define MAX_DISK_NSECS 56
static char ide[MAX_DISK_NSECS * SECTSIZE];

bool ide_device_valid(unsigned short ideno) { return ideno < MAX_IDE; }
ffffffffc02005ec:	00253513          	sltiu	a0,a0,2
ffffffffc02005f0:	8082                	ret

ffffffffc02005f2 <ide_device_size>:

size_t ide_device_size(unsigned short ideno) { return MAX_DISK_NSECS; }
ffffffffc02005f2:	03800513          	li	a0,56
ffffffffc02005f6:	8082                	ret

ffffffffc02005f8 <ide_read_secs>:

int ide_read_secs(unsigned short ideno, uint32_t secno, void *dst,
                  size_t nsecs) {
    int iobase = secno * SECTSIZE;
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc02005f8:	000a7797          	auipc	a5,0xa7
ffffffffc02005fc:	17878793          	addi	a5,a5,376 # ffffffffc02a7770 <ide>
    int iobase = secno * SECTSIZE;
ffffffffc0200600:	0095959b          	slliw	a1,a1,0x9
                  size_t nsecs) {
ffffffffc0200604:	1141                	addi	sp,sp,-16
ffffffffc0200606:	8532                	mv	a0,a2
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc0200608:	95be                	add	a1,a1,a5
ffffffffc020060a:	00969613          	slli	a2,a3,0x9
                  size_t nsecs) {
ffffffffc020060e:	e406                	sd	ra,8(sp)
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc0200610:	6af050ef          	jal	ra,ffffffffc02064be <memcpy>
    return 0;
}
ffffffffc0200614:	60a2                	ld	ra,8(sp)
ffffffffc0200616:	4501                	li	a0,0
ffffffffc0200618:	0141                	addi	sp,sp,16
ffffffffc020061a:	8082                	ret

ffffffffc020061c <ide_write_secs>:

int ide_write_secs(unsigned short ideno, uint32_t secno, const void *src,
                   size_t nsecs) {
    int iobase = secno * SECTSIZE;
ffffffffc020061c:	0095979b          	slliw	a5,a1,0x9
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc0200620:	000a7517          	auipc	a0,0xa7
ffffffffc0200624:	15050513          	addi	a0,a0,336 # ffffffffc02a7770 <ide>
                   size_t nsecs) {
ffffffffc0200628:	1141                	addi	sp,sp,-16
ffffffffc020062a:	85b2                	mv	a1,a2
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc020062c:	953e                	add	a0,a0,a5
ffffffffc020062e:	00969613          	slli	a2,a3,0x9
                   size_t nsecs) {
ffffffffc0200632:	e406                	sd	ra,8(sp)
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc0200634:	68b050ef          	jal	ra,ffffffffc02064be <memcpy>
    return 0;
}
ffffffffc0200638:	60a2                	ld	ra,8(sp)
ffffffffc020063a:	4501                	li	a0,0
ffffffffc020063c:	0141                	addi	sp,sp,16
ffffffffc020063e:	8082                	ret

ffffffffc0200640 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200640:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200644:	8082                	ret

ffffffffc0200646 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200646:	100177f3          	csrrci	a5,sstatus,2
ffffffffc020064a:	8082                	ret

ffffffffc020064c <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc020064c:	8082                	ret

ffffffffc020064e <idt_init>:
void
idt_init(void) {
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc020064e:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200652:	00000797          	auipc	a5,0x0
ffffffffc0200656:	65a78793          	addi	a5,a5,1626 # ffffffffc0200cac <__alltraps>
ffffffffc020065a:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc020065e:	000407b7          	lui	a5,0x40
ffffffffc0200662:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc0200666:	8082                	ret

ffffffffc0200668 <print_regs>:
    cprintf("  tval 0x%08x\n", tf->tval);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs* gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200668:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs* gpr) {
ffffffffc020066a:	1141                	addi	sp,sp,-16
ffffffffc020066c:	e022                	sd	s0,0(sp)
ffffffffc020066e:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200670:	00006517          	auipc	a0,0x6
ffffffffc0200674:	17850513          	addi	a0,a0,376 # ffffffffc02067e8 <commands+0xa8>
void print_regs(struct pushregs* gpr) {
ffffffffc0200678:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020067a:	b07ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc020067e:	640c                	ld	a1,8(s0)
ffffffffc0200680:	00006517          	auipc	a0,0x6
ffffffffc0200684:	18050513          	addi	a0,a0,384 # ffffffffc0206800 <commands+0xc0>
ffffffffc0200688:	af9ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc020068c:	680c                	ld	a1,16(s0)
ffffffffc020068e:	00006517          	auipc	a0,0x6
ffffffffc0200692:	18a50513          	addi	a0,a0,394 # ffffffffc0206818 <commands+0xd8>
ffffffffc0200696:	aebff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc020069a:	6c0c                	ld	a1,24(s0)
ffffffffc020069c:	00006517          	auipc	a0,0x6
ffffffffc02006a0:	19450513          	addi	a0,a0,404 # ffffffffc0206830 <commands+0xf0>
ffffffffc02006a4:	addff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02006a8:	700c                	ld	a1,32(s0)
ffffffffc02006aa:	00006517          	auipc	a0,0x6
ffffffffc02006ae:	19e50513          	addi	a0,a0,414 # ffffffffc0206848 <commands+0x108>
ffffffffc02006b2:	acfff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02006b6:	740c                	ld	a1,40(s0)
ffffffffc02006b8:	00006517          	auipc	a0,0x6
ffffffffc02006bc:	1a850513          	addi	a0,a0,424 # ffffffffc0206860 <commands+0x120>
ffffffffc02006c0:	ac1ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02006c4:	780c                	ld	a1,48(s0)
ffffffffc02006c6:	00006517          	auipc	a0,0x6
ffffffffc02006ca:	1b250513          	addi	a0,a0,434 # ffffffffc0206878 <commands+0x138>
ffffffffc02006ce:	ab3ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02006d2:	7c0c                	ld	a1,56(s0)
ffffffffc02006d4:	00006517          	auipc	a0,0x6
ffffffffc02006d8:	1bc50513          	addi	a0,a0,444 # ffffffffc0206890 <commands+0x150>
ffffffffc02006dc:	aa5ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02006e0:	602c                	ld	a1,64(s0)
ffffffffc02006e2:	00006517          	auipc	a0,0x6
ffffffffc02006e6:	1c650513          	addi	a0,a0,454 # ffffffffc02068a8 <commands+0x168>
ffffffffc02006ea:	a97ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02006ee:	642c                	ld	a1,72(s0)
ffffffffc02006f0:	00006517          	auipc	a0,0x6
ffffffffc02006f4:	1d050513          	addi	a0,a0,464 # ffffffffc02068c0 <commands+0x180>
ffffffffc02006f8:	a89ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02006fc:	682c                	ld	a1,80(s0)
ffffffffc02006fe:	00006517          	auipc	a0,0x6
ffffffffc0200702:	1da50513          	addi	a0,a0,474 # ffffffffc02068d8 <commands+0x198>
ffffffffc0200706:	a7bff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc020070a:	6c2c                	ld	a1,88(s0)
ffffffffc020070c:	00006517          	auipc	a0,0x6
ffffffffc0200710:	1e450513          	addi	a0,a0,484 # ffffffffc02068f0 <commands+0x1b0>
ffffffffc0200714:	a6dff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200718:	702c                	ld	a1,96(s0)
ffffffffc020071a:	00006517          	auipc	a0,0x6
ffffffffc020071e:	1ee50513          	addi	a0,a0,494 # ffffffffc0206908 <commands+0x1c8>
ffffffffc0200722:	a5fff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200726:	742c                	ld	a1,104(s0)
ffffffffc0200728:	00006517          	auipc	a0,0x6
ffffffffc020072c:	1f850513          	addi	a0,a0,504 # ffffffffc0206920 <commands+0x1e0>
ffffffffc0200730:	a51ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200734:	782c                	ld	a1,112(s0)
ffffffffc0200736:	00006517          	auipc	a0,0x6
ffffffffc020073a:	20250513          	addi	a0,a0,514 # ffffffffc0206938 <commands+0x1f8>
ffffffffc020073e:	a43ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200742:	7c2c                	ld	a1,120(s0)
ffffffffc0200744:	00006517          	auipc	a0,0x6
ffffffffc0200748:	20c50513          	addi	a0,a0,524 # ffffffffc0206950 <commands+0x210>
ffffffffc020074c:	a35ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200750:	604c                	ld	a1,128(s0)
ffffffffc0200752:	00006517          	auipc	a0,0x6
ffffffffc0200756:	21650513          	addi	a0,a0,534 # ffffffffc0206968 <commands+0x228>
ffffffffc020075a:	a27ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc020075e:	644c                	ld	a1,136(s0)
ffffffffc0200760:	00006517          	auipc	a0,0x6
ffffffffc0200764:	22050513          	addi	a0,a0,544 # ffffffffc0206980 <commands+0x240>
ffffffffc0200768:	a19ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc020076c:	684c                	ld	a1,144(s0)
ffffffffc020076e:	00006517          	auipc	a0,0x6
ffffffffc0200772:	22a50513          	addi	a0,a0,554 # ffffffffc0206998 <commands+0x258>
ffffffffc0200776:	a0bff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc020077a:	6c4c                	ld	a1,152(s0)
ffffffffc020077c:	00006517          	auipc	a0,0x6
ffffffffc0200780:	23450513          	addi	a0,a0,564 # ffffffffc02069b0 <commands+0x270>
ffffffffc0200784:	9fdff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200788:	704c                	ld	a1,160(s0)
ffffffffc020078a:	00006517          	auipc	a0,0x6
ffffffffc020078e:	23e50513          	addi	a0,a0,574 # ffffffffc02069c8 <commands+0x288>
ffffffffc0200792:	9efff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200796:	744c                	ld	a1,168(s0)
ffffffffc0200798:	00006517          	auipc	a0,0x6
ffffffffc020079c:	24850513          	addi	a0,a0,584 # ffffffffc02069e0 <commands+0x2a0>
ffffffffc02007a0:	9e1ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02007a4:	784c                	ld	a1,176(s0)
ffffffffc02007a6:	00006517          	auipc	a0,0x6
ffffffffc02007aa:	25250513          	addi	a0,a0,594 # ffffffffc02069f8 <commands+0x2b8>
ffffffffc02007ae:	9d3ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02007b2:	7c4c                	ld	a1,184(s0)
ffffffffc02007b4:	00006517          	auipc	a0,0x6
ffffffffc02007b8:	25c50513          	addi	a0,a0,604 # ffffffffc0206a10 <commands+0x2d0>
ffffffffc02007bc:	9c5ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02007c0:	606c                	ld	a1,192(s0)
ffffffffc02007c2:	00006517          	auipc	a0,0x6
ffffffffc02007c6:	26650513          	addi	a0,a0,614 # ffffffffc0206a28 <commands+0x2e8>
ffffffffc02007ca:	9b7ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02007ce:	646c                	ld	a1,200(s0)
ffffffffc02007d0:	00006517          	auipc	a0,0x6
ffffffffc02007d4:	27050513          	addi	a0,a0,624 # ffffffffc0206a40 <commands+0x300>
ffffffffc02007d8:	9a9ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02007dc:	686c                	ld	a1,208(s0)
ffffffffc02007de:	00006517          	auipc	a0,0x6
ffffffffc02007e2:	27a50513          	addi	a0,a0,634 # ffffffffc0206a58 <commands+0x318>
ffffffffc02007e6:	99bff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02007ea:	6c6c                	ld	a1,216(s0)
ffffffffc02007ec:	00006517          	auipc	a0,0x6
ffffffffc02007f0:	28450513          	addi	a0,a0,644 # ffffffffc0206a70 <commands+0x330>
ffffffffc02007f4:	98dff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc02007f8:	706c                	ld	a1,224(s0)
ffffffffc02007fa:	00006517          	auipc	a0,0x6
ffffffffc02007fe:	28e50513          	addi	a0,a0,654 # ffffffffc0206a88 <commands+0x348>
ffffffffc0200802:	97fff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200806:	746c                	ld	a1,232(s0)
ffffffffc0200808:	00006517          	auipc	a0,0x6
ffffffffc020080c:	29850513          	addi	a0,a0,664 # ffffffffc0206aa0 <commands+0x360>
ffffffffc0200810:	971ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200814:	786c                	ld	a1,240(s0)
ffffffffc0200816:	00006517          	auipc	a0,0x6
ffffffffc020081a:	2a250513          	addi	a0,a0,674 # ffffffffc0206ab8 <commands+0x378>
ffffffffc020081e:	963ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200822:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200824:	6402                	ld	s0,0(sp)
ffffffffc0200826:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200828:	00006517          	auipc	a0,0x6
ffffffffc020082c:	2a850513          	addi	a0,a0,680 # ffffffffc0206ad0 <commands+0x390>
}
ffffffffc0200830:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200832:	b2b9                	j	ffffffffc0200180 <cprintf>

ffffffffc0200834 <print_trapframe>:
print_trapframe(struct trapframe *tf) {
ffffffffc0200834:	1141                	addi	sp,sp,-16
ffffffffc0200836:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200838:	85aa                	mv	a1,a0
print_trapframe(struct trapframe *tf) {
ffffffffc020083a:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc020083c:	00006517          	auipc	a0,0x6
ffffffffc0200840:	2ac50513          	addi	a0,a0,684 # ffffffffc0206ae8 <commands+0x3a8>
print_trapframe(struct trapframe *tf) {
ffffffffc0200844:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200846:	93bff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    print_regs(&tf->gpr);
ffffffffc020084a:	8522                	mv	a0,s0
ffffffffc020084c:	e1dff0ef          	jal	ra,ffffffffc0200668 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200850:	10043583          	ld	a1,256(s0)
ffffffffc0200854:	00006517          	auipc	a0,0x6
ffffffffc0200858:	2ac50513          	addi	a0,a0,684 # ffffffffc0206b00 <commands+0x3c0>
ffffffffc020085c:	925ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200860:	10843583          	ld	a1,264(s0)
ffffffffc0200864:	00006517          	auipc	a0,0x6
ffffffffc0200868:	2b450513          	addi	a0,a0,692 # ffffffffc0206b18 <commands+0x3d8>
ffffffffc020086c:	915ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200870:	11043583          	ld	a1,272(s0)
ffffffffc0200874:	00006517          	auipc	a0,0x6
ffffffffc0200878:	2bc50513          	addi	a0,a0,700 # ffffffffc0206b30 <commands+0x3f0>
ffffffffc020087c:	905ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200880:	11843583          	ld	a1,280(s0)
}
ffffffffc0200884:	6402                	ld	s0,0(sp)
ffffffffc0200886:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200888:	00006517          	auipc	a0,0x6
ffffffffc020088c:	2b850513          	addi	a0,a0,696 # ffffffffc0206b40 <commands+0x400>
}
ffffffffc0200890:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200892:	8efff06f          	j	ffffffffc0200180 <cprintf>

ffffffffc0200896 <pgfault_handler>:
            trap_in_kernel(tf) ? 'K' : 'U',
            tf->cause == CAUSE_STORE_PAGE_FAULT ? 'W' : 'R');
}

static int
pgfault_handler(struct trapframe *tf) {
ffffffffc0200896:	1101                	addi	sp,sp,-32
ffffffffc0200898:	e426                	sd	s1,8(sp)
    extern struct mm_struct *check_mm_struct;
    if(check_mm_struct !=NULL) { //used for test check_swap
ffffffffc020089a:	000b2497          	auipc	s1,0xb2
ffffffffc020089e:	00648493          	addi	s1,s1,6 # ffffffffc02b28a0 <check_mm_struct>
ffffffffc02008a2:	609c                	ld	a5,0(s1)
pgfault_handler(struct trapframe *tf) {
ffffffffc02008a4:	e822                	sd	s0,16(sp)
ffffffffc02008a6:	ec06                	sd	ra,24(sp)
ffffffffc02008a8:	842a                	mv	s0,a0
    if(check_mm_struct !=NULL) { //used for test check_swap
ffffffffc02008aa:	cbad                	beqz	a5,ffffffffc020091c <pgfault_handler+0x86>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc02008ac:	10053783          	ld	a5,256(a0)
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc02008b0:	11053583          	ld	a1,272(a0)
ffffffffc02008b4:	04b00613          	li	a2,75
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc02008b8:	1007f793          	andi	a5,a5,256
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc02008bc:	c7b1                	beqz	a5,ffffffffc0200908 <pgfault_handler+0x72>
ffffffffc02008be:	11843703          	ld	a4,280(s0)
ffffffffc02008c2:	47bd                	li	a5,15
ffffffffc02008c4:	05700693          	li	a3,87
ffffffffc02008c8:	00f70463          	beq	a4,a5,ffffffffc02008d0 <pgfault_handler+0x3a>
ffffffffc02008cc:	05200693          	li	a3,82
ffffffffc02008d0:	00006517          	auipc	a0,0x6
ffffffffc02008d4:	28850513          	addi	a0,a0,648 # ffffffffc0206b58 <commands+0x418>
ffffffffc02008d8:	8a9ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
            print_pgfault(tf);
        }
    struct mm_struct *mm;
    if (check_mm_struct != NULL) {
ffffffffc02008dc:	6088                	ld	a0,0(s1)
ffffffffc02008de:	cd1d                	beqz	a0,ffffffffc020091c <pgfault_handler+0x86>
        assert(current == idleproc);
ffffffffc02008e0:	000b2717          	auipc	a4,0xb2
ffffffffc02008e4:	fd073703          	ld	a4,-48(a4) # ffffffffc02b28b0 <current>
ffffffffc02008e8:	000b2797          	auipc	a5,0xb2
ffffffffc02008ec:	fd07b783          	ld	a5,-48(a5) # ffffffffc02b28b8 <idleproc>
ffffffffc02008f0:	04f71663          	bne	a4,a5,ffffffffc020093c <pgfault_handler+0xa6>
            print_pgfault(tf);
            panic("unhandled page fault.\n");
        }
        mm = current->mm;
    }
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc02008f4:	11043603          	ld	a2,272(s0)
ffffffffc02008f8:	11843583          	ld	a1,280(s0)
}
ffffffffc02008fc:	6442                	ld	s0,16(sp)
ffffffffc02008fe:	60e2                	ld	ra,24(sp)
ffffffffc0200900:	64a2                	ld	s1,8(sp)
ffffffffc0200902:	6105                	addi	sp,sp,32
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc0200904:	7e30306f          	j	ffffffffc02048e6 <do_pgfault>
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc0200908:	11843703          	ld	a4,280(s0)
ffffffffc020090c:	47bd                	li	a5,15
ffffffffc020090e:	05500613          	li	a2,85
ffffffffc0200912:	05700693          	li	a3,87
ffffffffc0200916:	faf71be3          	bne	a4,a5,ffffffffc02008cc <pgfault_handler+0x36>
ffffffffc020091a:	bf5d                	j	ffffffffc02008d0 <pgfault_handler+0x3a>
        if (current == NULL) {
ffffffffc020091c:	000b2797          	auipc	a5,0xb2
ffffffffc0200920:	f947b783          	ld	a5,-108(a5) # ffffffffc02b28b0 <current>
ffffffffc0200924:	cf85                	beqz	a5,ffffffffc020095c <pgfault_handler+0xc6>
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc0200926:	11043603          	ld	a2,272(s0)
ffffffffc020092a:	11843583          	ld	a1,280(s0)
}
ffffffffc020092e:	6442                	ld	s0,16(sp)
ffffffffc0200930:	60e2                	ld	ra,24(sp)
ffffffffc0200932:	64a2                	ld	s1,8(sp)
        mm = current->mm;
ffffffffc0200934:	7788                	ld	a0,40(a5)
}
ffffffffc0200936:	6105                	addi	sp,sp,32
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc0200938:	7af0306f          	j	ffffffffc02048e6 <do_pgfault>
        assert(current == idleproc);
ffffffffc020093c:	00006697          	auipc	a3,0x6
ffffffffc0200940:	23c68693          	addi	a3,a3,572 # ffffffffc0206b78 <commands+0x438>
ffffffffc0200944:	00006617          	auipc	a2,0x6
ffffffffc0200948:	24c60613          	addi	a2,a2,588 # ffffffffc0206b90 <commands+0x450>
ffffffffc020094c:	06b00593          	li	a1,107
ffffffffc0200950:	00006517          	auipc	a0,0x6
ffffffffc0200954:	25850513          	addi	a0,a0,600 # ffffffffc0206ba8 <commands+0x468>
ffffffffc0200958:	b23ff0ef          	jal	ra,ffffffffc020047a <__panic>
            print_trapframe(tf);
ffffffffc020095c:	8522                	mv	a0,s0
ffffffffc020095e:	ed7ff0ef          	jal	ra,ffffffffc0200834 <print_trapframe>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200962:	10043783          	ld	a5,256(s0)
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc0200966:	11043583          	ld	a1,272(s0)
ffffffffc020096a:	04b00613          	li	a2,75
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc020096e:	1007f793          	andi	a5,a5,256
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc0200972:	e399                	bnez	a5,ffffffffc0200978 <pgfault_handler+0xe2>
ffffffffc0200974:	05500613          	li	a2,85
ffffffffc0200978:	11843703          	ld	a4,280(s0)
ffffffffc020097c:	47bd                	li	a5,15
ffffffffc020097e:	02f70663          	beq	a4,a5,ffffffffc02009aa <pgfault_handler+0x114>
ffffffffc0200982:	05200693          	li	a3,82
ffffffffc0200986:	00006517          	auipc	a0,0x6
ffffffffc020098a:	1d250513          	addi	a0,a0,466 # ffffffffc0206b58 <commands+0x418>
ffffffffc020098e:	ff2ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
            panic("unhandled page fault.\n");
ffffffffc0200992:	00006617          	auipc	a2,0x6
ffffffffc0200996:	22e60613          	addi	a2,a2,558 # ffffffffc0206bc0 <commands+0x480>
ffffffffc020099a:	07200593          	li	a1,114
ffffffffc020099e:	00006517          	auipc	a0,0x6
ffffffffc02009a2:	20a50513          	addi	a0,a0,522 # ffffffffc0206ba8 <commands+0x468>
ffffffffc02009a6:	ad5ff0ef          	jal	ra,ffffffffc020047a <__panic>
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc02009aa:	05700693          	li	a3,87
ffffffffc02009ae:	bfe1                	j	ffffffffc0200986 <pgfault_handler+0xf0>

ffffffffc02009b0 <interrupt_handler>:

static volatile int in_swap_tick_event = 0;
extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc02009b0:	11853783          	ld	a5,280(a0)
ffffffffc02009b4:	472d                	li	a4,11
ffffffffc02009b6:	0786                	slli	a5,a5,0x1
ffffffffc02009b8:	8385                	srli	a5,a5,0x1
ffffffffc02009ba:	08f76363          	bltu	a4,a5,ffffffffc0200a40 <interrupt_handler+0x90>
ffffffffc02009be:	00006717          	auipc	a4,0x6
ffffffffc02009c2:	2ba70713          	addi	a4,a4,698 # ffffffffc0206c78 <commands+0x538>
ffffffffc02009c6:	078a                	slli	a5,a5,0x2
ffffffffc02009c8:	97ba                	add	a5,a5,a4
ffffffffc02009ca:	439c                	lw	a5,0(a5)
ffffffffc02009cc:	97ba                	add	a5,a5,a4
ffffffffc02009ce:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc02009d0:	00006517          	auipc	a0,0x6
ffffffffc02009d4:	26850513          	addi	a0,a0,616 # ffffffffc0206c38 <commands+0x4f8>
ffffffffc02009d8:	fa8ff06f          	j	ffffffffc0200180 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02009dc:	00006517          	auipc	a0,0x6
ffffffffc02009e0:	23c50513          	addi	a0,a0,572 # ffffffffc0206c18 <commands+0x4d8>
ffffffffc02009e4:	f9cff06f          	j	ffffffffc0200180 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc02009e8:	00006517          	auipc	a0,0x6
ffffffffc02009ec:	1f050513          	addi	a0,a0,496 # ffffffffc0206bd8 <commands+0x498>
ffffffffc02009f0:	f90ff06f          	j	ffffffffc0200180 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc02009f4:	00006517          	auipc	a0,0x6
ffffffffc02009f8:	20450513          	addi	a0,a0,516 # ffffffffc0206bf8 <commands+0x4b8>
ffffffffc02009fc:	f84ff06f          	j	ffffffffc0200180 <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc0200a00:	1141                	addi	sp,sp,-16
ffffffffc0200a02:	e406                	sd	ra,8(sp)
            // "All bits besides SSIP and USIP in the sip register are
            // read-only." -- privileged spec1.9.1, 4.1.4, p59
            // In fact, Call sbi_set_timer will clear STIP, or you can clear it
            // directly.
            // clear_csr(sip, SIP_STIP);
            clock_set_next_event();
ffffffffc0200a04:	b5bff0ef          	jal	ra,ffffffffc020055e <clock_set_next_event>
            if (++ticks % TICK_NUM == 0 && current) {
ffffffffc0200a08:	000b2697          	auipc	a3,0xb2
ffffffffc0200a0c:	e3868693          	addi	a3,a3,-456 # ffffffffc02b2840 <ticks>
ffffffffc0200a10:	629c                	ld	a5,0(a3)
ffffffffc0200a12:	06400713          	li	a4,100
ffffffffc0200a16:	0785                	addi	a5,a5,1
ffffffffc0200a18:	02e7f733          	remu	a4,a5,a4
ffffffffc0200a1c:	e29c                	sd	a5,0(a3)
ffffffffc0200a1e:	eb01                	bnez	a4,ffffffffc0200a2e <interrupt_handler+0x7e>
ffffffffc0200a20:	000b2797          	auipc	a5,0xb2
ffffffffc0200a24:	e907b783          	ld	a5,-368(a5) # ffffffffc02b28b0 <current>
ffffffffc0200a28:	c399                	beqz	a5,ffffffffc0200a2e <interrupt_handler+0x7e>
                // print_ticks();
                current->need_resched = 1;
ffffffffc0200a2a:	4705                	li	a4,1
ffffffffc0200a2c:	ef98                	sd	a4,24(a5)
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200a2e:	60a2                	ld	ra,8(sp)
ffffffffc0200a30:	0141                	addi	sp,sp,16
ffffffffc0200a32:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc0200a34:	00006517          	auipc	a0,0x6
ffffffffc0200a38:	22450513          	addi	a0,a0,548 # ffffffffc0206c58 <commands+0x518>
ffffffffc0200a3c:	f44ff06f          	j	ffffffffc0200180 <cprintf>
            print_trapframe(tf);
ffffffffc0200a40:	bbd5                	j	ffffffffc0200834 <print_trapframe>

ffffffffc0200a42 <exception_handler>:
void kernel_execve_ret(struct trapframe *tf,uintptr_t kstacktop);
void exception_handler(struct trapframe *tf) {
    int ret;
    switch (tf->cause) {
ffffffffc0200a42:	11853783          	ld	a5,280(a0)
void exception_handler(struct trapframe *tf) {
ffffffffc0200a46:	1101                	addi	sp,sp,-32
ffffffffc0200a48:	e822                	sd	s0,16(sp)
ffffffffc0200a4a:	ec06                	sd	ra,24(sp)
ffffffffc0200a4c:	e426                	sd	s1,8(sp)
ffffffffc0200a4e:	473d                	li	a4,15
ffffffffc0200a50:	842a                	mv	s0,a0
ffffffffc0200a52:	18f76563          	bltu	a4,a5,ffffffffc0200bdc <exception_handler+0x19a>
ffffffffc0200a56:	00006717          	auipc	a4,0x6
ffffffffc0200a5a:	3ea70713          	addi	a4,a4,1002 # ffffffffc0206e40 <commands+0x700>
ffffffffc0200a5e:	078a                	slli	a5,a5,0x2
ffffffffc0200a60:	97ba                	add	a5,a5,a4
ffffffffc0200a62:	439c                	lw	a5,0(a5)
ffffffffc0200a64:	97ba                	add	a5,a5,a4
ffffffffc0200a66:	8782                	jr	a5
            //cprintf("Environment call from U-mode\n");
            tf->epc += 4;
            syscall();
            break;
        case CAUSE_SUPERVISOR_ECALL:
            cprintf("Environment call from S-mode\n");
ffffffffc0200a68:	00006517          	auipc	a0,0x6
ffffffffc0200a6c:	33050513          	addi	a0,a0,816 # ffffffffc0206d98 <commands+0x658>
ffffffffc0200a70:	f10ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
            tf->epc += 4;
ffffffffc0200a74:	10843783          	ld	a5,264(s0)
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200a78:	60e2                	ld	ra,24(sp)
ffffffffc0200a7a:	64a2                	ld	s1,8(sp)
            tf->epc += 4;
ffffffffc0200a7c:	0791                	addi	a5,a5,4
ffffffffc0200a7e:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200a82:	6442                	ld	s0,16(sp)
ffffffffc0200a84:	6105                	addi	sp,sp,32
            syscall();
ffffffffc0200a86:	5260506f          	j	ffffffffc0205fac <syscall>
            cprintf("Environment call from H-mode\n");
ffffffffc0200a8a:	00006517          	auipc	a0,0x6
ffffffffc0200a8e:	32e50513          	addi	a0,a0,814 # ffffffffc0206db8 <commands+0x678>
}
ffffffffc0200a92:	6442                	ld	s0,16(sp)
ffffffffc0200a94:	60e2                	ld	ra,24(sp)
ffffffffc0200a96:	64a2                	ld	s1,8(sp)
ffffffffc0200a98:	6105                	addi	sp,sp,32
            cprintf("Instruction access fault\n");
ffffffffc0200a9a:	ee6ff06f          	j	ffffffffc0200180 <cprintf>
            cprintf("Environment call from M-mode\n");
ffffffffc0200a9e:	00006517          	auipc	a0,0x6
ffffffffc0200aa2:	33a50513          	addi	a0,a0,826 # ffffffffc0206dd8 <commands+0x698>
ffffffffc0200aa6:	b7f5                	j	ffffffffc0200a92 <exception_handler+0x50>
            cprintf("Instruction page fault\n");
ffffffffc0200aa8:	00006517          	auipc	a0,0x6
ffffffffc0200aac:	35050513          	addi	a0,a0,848 # ffffffffc0206df8 <commands+0x6b8>
ffffffffc0200ab0:	b7cd                	j	ffffffffc0200a92 <exception_handler+0x50>
            cprintf("Load page fault\n");
ffffffffc0200ab2:	00006517          	auipc	a0,0x6
ffffffffc0200ab6:	35e50513          	addi	a0,a0,862 # ffffffffc0206e10 <commands+0x6d0>
ffffffffc0200aba:	ec6ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200abe:	8522                	mv	a0,s0
ffffffffc0200ac0:	dd7ff0ef          	jal	ra,ffffffffc0200896 <pgfault_handler>
ffffffffc0200ac4:	84aa                	mv	s1,a0
ffffffffc0200ac6:	12051d63          	bnez	a0,ffffffffc0200c00 <exception_handler+0x1be>
}
ffffffffc0200aca:	60e2                	ld	ra,24(sp)
ffffffffc0200acc:	6442                	ld	s0,16(sp)
ffffffffc0200ace:	64a2                	ld	s1,8(sp)
ffffffffc0200ad0:	6105                	addi	sp,sp,32
ffffffffc0200ad2:	8082                	ret
            cprintf("Store/AMO page fault\n");
ffffffffc0200ad4:	00006517          	auipc	a0,0x6
ffffffffc0200ad8:	35450513          	addi	a0,a0,852 # ffffffffc0206e28 <commands+0x6e8>
ffffffffc0200adc:	ea4ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200ae0:	8522                	mv	a0,s0
ffffffffc0200ae2:	db5ff0ef          	jal	ra,ffffffffc0200896 <pgfault_handler>
ffffffffc0200ae6:	84aa                	mv	s1,a0
ffffffffc0200ae8:	d16d                	beqz	a0,ffffffffc0200aca <exception_handler+0x88>
                print_trapframe(tf);
ffffffffc0200aea:	8522                	mv	a0,s0
ffffffffc0200aec:	d49ff0ef          	jal	ra,ffffffffc0200834 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200af0:	86a6                	mv	a3,s1
ffffffffc0200af2:	00006617          	auipc	a2,0x6
ffffffffc0200af6:	25660613          	addi	a2,a2,598 # ffffffffc0206d48 <commands+0x608>
ffffffffc0200afa:	0f800593          	li	a1,248
ffffffffc0200afe:	00006517          	auipc	a0,0x6
ffffffffc0200b02:	0aa50513          	addi	a0,a0,170 # ffffffffc0206ba8 <commands+0x468>
ffffffffc0200b06:	975ff0ef          	jal	ra,ffffffffc020047a <__panic>
            cprintf("Instruction address misaligned\n");
ffffffffc0200b0a:	00006517          	auipc	a0,0x6
ffffffffc0200b0e:	19e50513          	addi	a0,a0,414 # ffffffffc0206ca8 <commands+0x568>
ffffffffc0200b12:	b741                	j	ffffffffc0200a92 <exception_handler+0x50>
            cprintf("Instruction access fault\n");
ffffffffc0200b14:	00006517          	auipc	a0,0x6
ffffffffc0200b18:	1b450513          	addi	a0,a0,436 # ffffffffc0206cc8 <commands+0x588>
ffffffffc0200b1c:	bf9d                	j	ffffffffc0200a92 <exception_handler+0x50>
            cprintf("Illegal instruction\n");
ffffffffc0200b1e:	00006517          	auipc	a0,0x6
ffffffffc0200b22:	1ca50513          	addi	a0,a0,458 # ffffffffc0206ce8 <commands+0x5a8>
ffffffffc0200b26:	b7b5                	j	ffffffffc0200a92 <exception_handler+0x50>
            cprintf("Breakpoint\n");
ffffffffc0200b28:	00006517          	auipc	a0,0x6
ffffffffc0200b2c:	1d850513          	addi	a0,a0,472 # ffffffffc0206d00 <commands+0x5c0>
ffffffffc0200b30:	e50ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
            if(tf->gpr.a7 == 10){
ffffffffc0200b34:	6458                	ld	a4,136(s0)
ffffffffc0200b36:	47a9                	li	a5,10
ffffffffc0200b38:	f8f719e3          	bne	a4,a5,ffffffffc0200aca <exception_handler+0x88>
                tf->epc += 4;
ffffffffc0200b3c:	10843783          	ld	a5,264(s0)
ffffffffc0200b40:	0791                	addi	a5,a5,4
ffffffffc0200b42:	10f43423          	sd	a5,264(s0)
                syscall();
ffffffffc0200b46:	466050ef          	jal	ra,ffffffffc0205fac <syscall>
                kernel_execve_ret(tf,current->kstack+KSTACKSIZE);
ffffffffc0200b4a:	000b2797          	auipc	a5,0xb2
ffffffffc0200b4e:	d667b783          	ld	a5,-666(a5) # ffffffffc02b28b0 <current>
ffffffffc0200b52:	6b9c                	ld	a5,16(a5)
ffffffffc0200b54:	8522                	mv	a0,s0
}
ffffffffc0200b56:	6442                	ld	s0,16(sp)
ffffffffc0200b58:	60e2                	ld	ra,24(sp)
ffffffffc0200b5a:	64a2                	ld	s1,8(sp)
                kernel_execve_ret(tf,current->kstack+KSTACKSIZE);
ffffffffc0200b5c:	6589                	lui	a1,0x2
ffffffffc0200b5e:	95be                	add	a1,a1,a5
}
ffffffffc0200b60:	6105                	addi	sp,sp,32
                kernel_execve_ret(tf,current->kstack+KSTACKSIZE);
ffffffffc0200b62:	ac21                	j	ffffffffc0200d7a <kernel_execve_ret>
            cprintf("Load address misaligned\n");
ffffffffc0200b64:	00006517          	auipc	a0,0x6
ffffffffc0200b68:	1ac50513          	addi	a0,a0,428 # ffffffffc0206d10 <commands+0x5d0>
ffffffffc0200b6c:	b71d                	j	ffffffffc0200a92 <exception_handler+0x50>
            cprintf("Load access fault\n");
ffffffffc0200b6e:	00006517          	auipc	a0,0x6
ffffffffc0200b72:	1c250513          	addi	a0,a0,450 # ffffffffc0206d30 <commands+0x5f0>
ffffffffc0200b76:	e0aff0ef          	jal	ra,ffffffffc0200180 <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200b7a:	8522                	mv	a0,s0
ffffffffc0200b7c:	d1bff0ef          	jal	ra,ffffffffc0200896 <pgfault_handler>
ffffffffc0200b80:	84aa                	mv	s1,a0
ffffffffc0200b82:	d521                	beqz	a0,ffffffffc0200aca <exception_handler+0x88>
                print_trapframe(tf);
ffffffffc0200b84:	8522                	mv	a0,s0
ffffffffc0200b86:	cafff0ef          	jal	ra,ffffffffc0200834 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200b8a:	86a6                	mv	a3,s1
ffffffffc0200b8c:	00006617          	auipc	a2,0x6
ffffffffc0200b90:	1bc60613          	addi	a2,a2,444 # ffffffffc0206d48 <commands+0x608>
ffffffffc0200b94:	0cd00593          	li	a1,205
ffffffffc0200b98:	00006517          	auipc	a0,0x6
ffffffffc0200b9c:	01050513          	addi	a0,a0,16 # ffffffffc0206ba8 <commands+0x468>
ffffffffc0200ba0:	8dbff0ef          	jal	ra,ffffffffc020047a <__panic>
            cprintf("Store/AMO access fault\n");
ffffffffc0200ba4:	00006517          	auipc	a0,0x6
ffffffffc0200ba8:	1dc50513          	addi	a0,a0,476 # ffffffffc0206d80 <commands+0x640>
ffffffffc0200bac:	dd4ff0ef          	jal	ra,ffffffffc0200180 <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200bb0:	8522                	mv	a0,s0
ffffffffc0200bb2:	ce5ff0ef          	jal	ra,ffffffffc0200896 <pgfault_handler>
ffffffffc0200bb6:	84aa                	mv	s1,a0
ffffffffc0200bb8:	f00509e3          	beqz	a0,ffffffffc0200aca <exception_handler+0x88>
                print_trapframe(tf);
ffffffffc0200bbc:	8522                	mv	a0,s0
ffffffffc0200bbe:	c77ff0ef          	jal	ra,ffffffffc0200834 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200bc2:	86a6                	mv	a3,s1
ffffffffc0200bc4:	00006617          	auipc	a2,0x6
ffffffffc0200bc8:	18460613          	addi	a2,a2,388 # ffffffffc0206d48 <commands+0x608>
ffffffffc0200bcc:	0d700593          	li	a1,215
ffffffffc0200bd0:	00006517          	auipc	a0,0x6
ffffffffc0200bd4:	fd850513          	addi	a0,a0,-40 # ffffffffc0206ba8 <commands+0x468>
ffffffffc0200bd8:	8a3ff0ef          	jal	ra,ffffffffc020047a <__panic>
            print_trapframe(tf);
ffffffffc0200bdc:	8522                	mv	a0,s0
}
ffffffffc0200bde:	6442                	ld	s0,16(sp)
ffffffffc0200be0:	60e2                	ld	ra,24(sp)
ffffffffc0200be2:	64a2                	ld	s1,8(sp)
ffffffffc0200be4:	6105                	addi	sp,sp,32
            print_trapframe(tf);
ffffffffc0200be6:	b1b9                	j	ffffffffc0200834 <print_trapframe>
            panic("AMO address misaligned\n");
ffffffffc0200be8:	00006617          	auipc	a2,0x6
ffffffffc0200bec:	18060613          	addi	a2,a2,384 # ffffffffc0206d68 <commands+0x628>
ffffffffc0200bf0:	0d100593          	li	a1,209
ffffffffc0200bf4:	00006517          	auipc	a0,0x6
ffffffffc0200bf8:	fb450513          	addi	a0,a0,-76 # ffffffffc0206ba8 <commands+0x468>
ffffffffc0200bfc:	87fff0ef          	jal	ra,ffffffffc020047a <__panic>
                print_trapframe(tf);
ffffffffc0200c00:	8522                	mv	a0,s0
ffffffffc0200c02:	c33ff0ef          	jal	ra,ffffffffc0200834 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200c06:	86a6                	mv	a3,s1
ffffffffc0200c08:	00006617          	auipc	a2,0x6
ffffffffc0200c0c:	14060613          	addi	a2,a2,320 # ffffffffc0206d48 <commands+0x608>
ffffffffc0200c10:	0f100593          	li	a1,241
ffffffffc0200c14:	00006517          	auipc	a0,0x6
ffffffffc0200c18:	f9450513          	addi	a0,a0,-108 # ffffffffc0206ba8 <commands+0x468>
ffffffffc0200c1c:	85fff0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0200c20 <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void
trap(struct trapframe *tf) {
ffffffffc0200c20:	1101                	addi	sp,sp,-32
ffffffffc0200c22:	e822                	sd	s0,16(sp)
    // dispatch based on what type of trap occurred
//    cputs("some trap");
    if (current == NULL) {
ffffffffc0200c24:	000b2417          	auipc	s0,0xb2
ffffffffc0200c28:	c8c40413          	addi	s0,s0,-884 # ffffffffc02b28b0 <current>
ffffffffc0200c2c:	6018                	ld	a4,0(s0)
trap(struct trapframe *tf) {
ffffffffc0200c2e:	ec06                	sd	ra,24(sp)
ffffffffc0200c30:	e426                	sd	s1,8(sp)
ffffffffc0200c32:	e04a                	sd	s2,0(sp)
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200c34:	11853683          	ld	a3,280(a0)
    if (current == NULL) {
ffffffffc0200c38:	cf1d                	beqz	a4,ffffffffc0200c76 <trap+0x56>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200c3a:	10053483          	ld	s1,256(a0)
        trap_dispatch(tf);
    } else {
        struct trapframe *otf = current->tf;
ffffffffc0200c3e:	0a073903          	ld	s2,160(a4)
        current->tf = tf;
ffffffffc0200c42:	f348                	sd	a0,160(a4)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200c44:	1004f493          	andi	s1,s1,256
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200c48:	0206c463          	bltz	a3,ffffffffc0200c70 <trap+0x50>
        exception_handler(tf);
ffffffffc0200c4c:	df7ff0ef          	jal	ra,ffffffffc0200a42 <exception_handler>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0200c50:	601c                	ld	a5,0(s0)
ffffffffc0200c52:	0b27b023          	sd	s2,160(a5)
        if (!in_kernel) {
ffffffffc0200c56:	e499                	bnez	s1,ffffffffc0200c64 <trap+0x44>
            if (current->flags & PF_EXITING) {
ffffffffc0200c58:	0b07a703          	lw	a4,176(a5)
ffffffffc0200c5c:	8b05                	andi	a4,a4,1
ffffffffc0200c5e:	e329                	bnez	a4,ffffffffc0200ca0 <trap+0x80>
                do_exit(-E_KILLED);
            }
            if (current->need_resched) {
ffffffffc0200c60:	6f9c                	ld	a5,24(a5)
ffffffffc0200c62:	eb85                	bnez	a5,ffffffffc0200c92 <trap+0x72>
                schedule();
            }
        }
    }
}
ffffffffc0200c64:	60e2                	ld	ra,24(sp)
ffffffffc0200c66:	6442                	ld	s0,16(sp)
ffffffffc0200c68:	64a2                	ld	s1,8(sp)
ffffffffc0200c6a:	6902                	ld	s2,0(sp)
ffffffffc0200c6c:	6105                	addi	sp,sp,32
ffffffffc0200c6e:	8082                	ret
        interrupt_handler(tf);
ffffffffc0200c70:	d41ff0ef          	jal	ra,ffffffffc02009b0 <interrupt_handler>
ffffffffc0200c74:	bff1                	j	ffffffffc0200c50 <trap+0x30>
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200c76:	0006c863          	bltz	a3,ffffffffc0200c86 <trap+0x66>
}
ffffffffc0200c7a:	6442                	ld	s0,16(sp)
ffffffffc0200c7c:	60e2                	ld	ra,24(sp)
ffffffffc0200c7e:	64a2                	ld	s1,8(sp)
ffffffffc0200c80:	6902                	ld	s2,0(sp)
ffffffffc0200c82:	6105                	addi	sp,sp,32
        exception_handler(tf);
ffffffffc0200c84:	bb7d                	j	ffffffffc0200a42 <exception_handler>
}
ffffffffc0200c86:	6442                	ld	s0,16(sp)
ffffffffc0200c88:	60e2                	ld	ra,24(sp)
ffffffffc0200c8a:	64a2                	ld	s1,8(sp)
ffffffffc0200c8c:	6902                	ld	s2,0(sp)
ffffffffc0200c8e:	6105                	addi	sp,sp,32
        interrupt_handler(tf);
ffffffffc0200c90:	b305                	j	ffffffffc02009b0 <interrupt_handler>
}
ffffffffc0200c92:	6442                	ld	s0,16(sp)
ffffffffc0200c94:	60e2                	ld	ra,24(sp)
ffffffffc0200c96:	64a2                	ld	s1,8(sp)
ffffffffc0200c98:	6902                	ld	s2,0(sp)
ffffffffc0200c9a:	6105                	addi	sp,sp,32
                schedule();
ffffffffc0200c9c:	2240506f          	j	ffffffffc0205ec0 <schedule>
                do_exit(-E_KILLED);
ffffffffc0200ca0:	555d                	li	a0,-9
ffffffffc0200ca2:	568040ef          	jal	ra,ffffffffc020520a <do_exit>
            if (current->need_resched) {
ffffffffc0200ca6:	601c                	ld	a5,0(s0)
ffffffffc0200ca8:	bf65                	j	ffffffffc0200c60 <trap+0x40>
	...

ffffffffc0200cac <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200cac:	14011173          	csrrw	sp,sscratch,sp
ffffffffc0200cb0:	00011463          	bnez	sp,ffffffffc0200cb8 <__alltraps+0xc>
ffffffffc0200cb4:	14002173          	csrr	sp,sscratch
ffffffffc0200cb8:	712d                	addi	sp,sp,-288
ffffffffc0200cba:	e002                	sd	zero,0(sp)
ffffffffc0200cbc:	e406                	sd	ra,8(sp)
ffffffffc0200cbe:	ec0e                	sd	gp,24(sp)
ffffffffc0200cc0:	f012                	sd	tp,32(sp)
ffffffffc0200cc2:	f416                	sd	t0,40(sp)
ffffffffc0200cc4:	f81a                	sd	t1,48(sp)
ffffffffc0200cc6:	fc1e                	sd	t2,56(sp)
ffffffffc0200cc8:	e0a2                	sd	s0,64(sp)
ffffffffc0200cca:	e4a6                	sd	s1,72(sp)
ffffffffc0200ccc:	e8aa                	sd	a0,80(sp)
ffffffffc0200cce:	ecae                	sd	a1,88(sp)
ffffffffc0200cd0:	f0b2                	sd	a2,96(sp)
ffffffffc0200cd2:	f4b6                	sd	a3,104(sp)
ffffffffc0200cd4:	f8ba                	sd	a4,112(sp)
ffffffffc0200cd6:	fcbe                	sd	a5,120(sp)
ffffffffc0200cd8:	e142                	sd	a6,128(sp)
ffffffffc0200cda:	e546                	sd	a7,136(sp)
ffffffffc0200cdc:	e94a                	sd	s2,144(sp)
ffffffffc0200cde:	ed4e                	sd	s3,152(sp)
ffffffffc0200ce0:	f152                	sd	s4,160(sp)
ffffffffc0200ce2:	f556                	sd	s5,168(sp)
ffffffffc0200ce4:	f95a                	sd	s6,176(sp)
ffffffffc0200ce6:	fd5e                	sd	s7,184(sp)
ffffffffc0200ce8:	e1e2                	sd	s8,192(sp)
ffffffffc0200cea:	e5e6                	sd	s9,200(sp)
ffffffffc0200cec:	e9ea                	sd	s10,208(sp)
ffffffffc0200cee:	edee                	sd	s11,216(sp)
ffffffffc0200cf0:	f1f2                	sd	t3,224(sp)
ffffffffc0200cf2:	f5f6                	sd	t4,232(sp)
ffffffffc0200cf4:	f9fa                	sd	t5,240(sp)
ffffffffc0200cf6:	fdfe                	sd	t6,248(sp)
ffffffffc0200cf8:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200cfc:	100024f3          	csrr	s1,sstatus
ffffffffc0200d00:	14102973          	csrr	s2,sepc
ffffffffc0200d04:	143029f3          	csrr	s3,stval
ffffffffc0200d08:	14202a73          	csrr	s4,scause
ffffffffc0200d0c:	e822                	sd	s0,16(sp)
ffffffffc0200d0e:	e226                	sd	s1,256(sp)
ffffffffc0200d10:	e64a                	sd	s2,264(sp)
ffffffffc0200d12:	ea4e                	sd	s3,272(sp)
ffffffffc0200d14:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200d16:	850a                	mv	a0,sp
    jal trap
ffffffffc0200d18:	f09ff0ef          	jal	ra,ffffffffc0200c20 <trap>

ffffffffc0200d1c <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200d1c:	6492                	ld	s1,256(sp)
ffffffffc0200d1e:	6932                	ld	s2,264(sp)
ffffffffc0200d20:	1004f413          	andi	s0,s1,256
ffffffffc0200d24:	e401                	bnez	s0,ffffffffc0200d2c <__trapret+0x10>
ffffffffc0200d26:	1200                	addi	s0,sp,288
ffffffffc0200d28:	14041073          	csrw	sscratch,s0
ffffffffc0200d2c:	10049073          	csrw	sstatus,s1
ffffffffc0200d30:	14191073          	csrw	sepc,s2
ffffffffc0200d34:	60a2                	ld	ra,8(sp)
ffffffffc0200d36:	61e2                	ld	gp,24(sp)
ffffffffc0200d38:	7202                	ld	tp,32(sp)
ffffffffc0200d3a:	72a2                	ld	t0,40(sp)
ffffffffc0200d3c:	7342                	ld	t1,48(sp)
ffffffffc0200d3e:	73e2                	ld	t2,56(sp)
ffffffffc0200d40:	6406                	ld	s0,64(sp)
ffffffffc0200d42:	64a6                	ld	s1,72(sp)
ffffffffc0200d44:	6546                	ld	a0,80(sp)
ffffffffc0200d46:	65e6                	ld	a1,88(sp)
ffffffffc0200d48:	7606                	ld	a2,96(sp)
ffffffffc0200d4a:	76a6                	ld	a3,104(sp)
ffffffffc0200d4c:	7746                	ld	a4,112(sp)
ffffffffc0200d4e:	77e6                	ld	a5,120(sp)
ffffffffc0200d50:	680a                	ld	a6,128(sp)
ffffffffc0200d52:	68aa                	ld	a7,136(sp)
ffffffffc0200d54:	694a                	ld	s2,144(sp)
ffffffffc0200d56:	69ea                	ld	s3,152(sp)
ffffffffc0200d58:	7a0a                	ld	s4,160(sp)
ffffffffc0200d5a:	7aaa                	ld	s5,168(sp)
ffffffffc0200d5c:	7b4a                	ld	s6,176(sp)
ffffffffc0200d5e:	7bea                	ld	s7,184(sp)
ffffffffc0200d60:	6c0e                	ld	s8,192(sp)
ffffffffc0200d62:	6cae                	ld	s9,200(sp)
ffffffffc0200d64:	6d4e                	ld	s10,208(sp)
ffffffffc0200d66:	6dee                	ld	s11,216(sp)
ffffffffc0200d68:	7e0e                	ld	t3,224(sp)
ffffffffc0200d6a:	7eae                	ld	t4,232(sp)
ffffffffc0200d6c:	7f4e                	ld	t5,240(sp)
ffffffffc0200d6e:	7fee                	ld	t6,248(sp)
ffffffffc0200d70:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200d72:	10200073          	sret

ffffffffc0200d76 <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200d76:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200d78:	b755                	j	ffffffffc0200d1c <__trapret>

ffffffffc0200d7a <kernel_execve_ret>:

    .global kernel_execve_ret
kernel_execve_ret:
    // adjust sp to beneath kstacktop of current process
    addi a1, a1, -36*REGBYTES
ffffffffc0200d7a:	ee058593          	addi	a1,a1,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7cd8>

    // copy from previous trapframe to new trapframe
    LOAD s1, 35*REGBYTES(a0)
ffffffffc0200d7e:	11853483          	ld	s1,280(a0)
    STORE s1, 35*REGBYTES(a1)
ffffffffc0200d82:	1095bc23          	sd	s1,280(a1)
    LOAD s1, 34*REGBYTES(a0)
ffffffffc0200d86:	11053483          	ld	s1,272(a0)
    STORE s1, 34*REGBYTES(a1)
ffffffffc0200d8a:	1095b823          	sd	s1,272(a1)
    LOAD s1, 33*REGBYTES(a0)
ffffffffc0200d8e:	10853483          	ld	s1,264(a0)
    STORE s1, 33*REGBYTES(a1)
ffffffffc0200d92:	1095b423          	sd	s1,264(a1)
    LOAD s1, 32*REGBYTES(a0)
ffffffffc0200d96:	10053483          	ld	s1,256(a0)
    STORE s1, 32*REGBYTES(a1)
ffffffffc0200d9a:	1095b023          	sd	s1,256(a1)
    LOAD s1, 31*REGBYTES(a0)
ffffffffc0200d9e:	7d64                	ld	s1,248(a0)
    STORE s1, 31*REGBYTES(a1)
ffffffffc0200da0:	fde4                	sd	s1,248(a1)
    LOAD s1, 30*REGBYTES(a0)
ffffffffc0200da2:	7964                	ld	s1,240(a0)
    STORE s1, 30*REGBYTES(a1)
ffffffffc0200da4:	f9e4                	sd	s1,240(a1)
    LOAD s1, 29*REGBYTES(a0)
ffffffffc0200da6:	7564                	ld	s1,232(a0)
    STORE s1, 29*REGBYTES(a1)
ffffffffc0200da8:	f5e4                	sd	s1,232(a1)
    LOAD s1, 28*REGBYTES(a0)
ffffffffc0200daa:	7164                	ld	s1,224(a0)
    STORE s1, 28*REGBYTES(a1)
ffffffffc0200dac:	f1e4                	sd	s1,224(a1)
    LOAD s1, 27*REGBYTES(a0)
ffffffffc0200dae:	6d64                	ld	s1,216(a0)
    STORE s1, 27*REGBYTES(a1)
ffffffffc0200db0:	ede4                	sd	s1,216(a1)
    LOAD s1, 26*REGBYTES(a0)
ffffffffc0200db2:	6964                	ld	s1,208(a0)
    STORE s1, 26*REGBYTES(a1)
ffffffffc0200db4:	e9e4                	sd	s1,208(a1)
    LOAD s1, 25*REGBYTES(a0)
ffffffffc0200db6:	6564                	ld	s1,200(a0)
    STORE s1, 25*REGBYTES(a1)
ffffffffc0200db8:	e5e4                	sd	s1,200(a1)
    LOAD s1, 24*REGBYTES(a0)
ffffffffc0200dba:	6164                	ld	s1,192(a0)
    STORE s1, 24*REGBYTES(a1)
ffffffffc0200dbc:	e1e4                	sd	s1,192(a1)
    LOAD s1, 23*REGBYTES(a0)
ffffffffc0200dbe:	7d44                	ld	s1,184(a0)
    STORE s1, 23*REGBYTES(a1)
ffffffffc0200dc0:	fdc4                	sd	s1,184(a1)
    LOAD s1, 22*REGBYTES(a0)
ffffffffc0200dc2:	7944                	ld	s1,176(a0)
    STORE s1, 22*REGBYTES(a1)
ffffffffc0200dc4:	f9c4                	sd	s1,176(a1)
    LOAD s1, 21*REGBYTES(a0)
ffffffffc0200dc6:	7544                	ld	s1,168(a0)
    STORE s1, 21*REGBYTES(a1)
ffffffffc0200dc8:	f5c4                	sd	s1,168(a1)
    LOAD s1, 20*REGBYTES(a0)
ffffffffc0200dca:	7144                	ld	s1,160(a0)
    STORE s1, 20*REGBYTES(a1)
ffffffffc0200dcc:	f1c4                	sd	s1,160(a1)
    LOAD s1, 19*REGBYTES(a0)
ffffffffc0200dce:	6d44                	ld	s1,152(a0)
    STORE s1, 19*REGBYTES(a1)
ffffffffc0200dd0:	edc4                	sd	s1,152(a1)
    LOAD s1, 18*REGBYTES(a0)
ffffffffc0200dd2:	6944                	ld	s1,144(a0)
    STORE s1, 18*REGBYTES(a1)
ffffffffc0200dd4:	e9c4                	sd	s1,144(a1)
    LOAD s1, 17*REGBYTES(a0)
ffffffffc0200dd6:	6544                	ld	s1,136(a0)
    STORE s1, 17*REGBYTES(a1)
ffffffffc0200dd8:	e5c4                	sd	s1,136(a1)
    LOAD s1, 16*REGBYTES(a0)
ffffffffc0200dda:	6144                	ld	s1,128(a0)
    STORE s1, 16*REGBYTES(a1)
ffffffffc0200ddc:	e1c4                	sd	s1,128(a1)
    LOAD s1, 15*REGBYTES(a0)
ffffffffc0200dde:	7d24                	ld	s1,120(a0)
    STORE s1, 15*REGBYTES(a1)
ffffffffc0200de0:	fda4                	sd	s1,120(a1)
    LOAD s1, 14*REGBYTES(a0)
ffffffffc0200de2:	7924                	ld	s1,112(a0)
    STORE s1, 14*REGBYTES(a1)
ffffffffc0200de4:	f9a4                	sd	s1,112(a1)
    LOAD s1, 13*REGBYTES(a0)
ffffffffc0200de6:	7524                	ld	s1,104(a0)
    STORE s1, 13*REGBYTES(a1)
ffffffffc0200de8:	f5a4                	sd	s1,104(a1)
    LOAD s1, 12*REGBYTES(a0)
ffffffffc0200dea:	7124                	ld	s1,96(a0)
    STORE s1, 12*REGBYTES(a1)
ffffffffc0200dec:	f1a4                	sd	s1,96(a1)
    LOAD s1, 11*REGBYTES(a0)
ffffffffc0200dee:	6d24                	ld	s1,88(a0)
    STORE s1, 11*REGBYTES(a1)
ffffffffc0200df0:	eda4                	sd	s1,88(a1)
    LOAD s1, 10*REGBYTES(a0)
ffffffffc0200df2:	6924                	ld	s1,80(a0)
    STORE s1, 10*REGBYTES(a1)
ffffffffc0200df4:	e9a4                	sd	s1,80(a1)
    LOAD s1, 9*REGBYTES(a0)
ffffffffc0200df6:	6524                	ld	s1,72(a0)
    STORE s1, 9*REGBYTES(a1)
ffffffffc0200df8:	e5a4                	sd	s1,72(a1)
    LOAD s1, 8*REGBYTES(a0)
ffffffffc0200dfa:	6124                	ld	s1,64(a0)
    STORE s1, 8*REGBYTES(a1)
ffffffffc0200dfc:	e1a4                	sd	s1,64(a1)
    LOAD s1, 7*REGBYTES(a0)
ffffffffc0200dfe:	7d04                	ld	s1,56(a0)
    STORE s1, 7*REGBYTES(a1)
ffffffffc0200e00:	fd84                	sd	s1,56(a1)
    LOAD s1, 6*REGBYTES(a0)
ffffffffc0200e02:	7904                	ld	s1,48(a0)
    STORE s1, 6*REGBYTES(a1)
ffffffffc0200e04:	f984                	sd	s1,48(a1)
    LOAD s1, 5*REGBYTES(a0)
ffffffffc0200e06:	7504                	ld	s1,40(a0)
    STORE s1, 5*REGBYTES(a1)
ffffffffc0200e08:	f584                	sd	s1,40(a1)
    LOAD s1, 4*REGBYTES(a0)
ffffffffc0200e0a:	7104                	ld	s1,32(a0)
    STORE s1, 4*REGBYTES(a1)
ffffffffc0200e0c:	f184                	sd	s1,32(a1)
    LOAD s1, 3*REGBYTES(a0)
ffffffffc0200e0e:	6d04                	ld	s1,24(a0)
    STORE s1, 3*REGBYTES(a1)
ffffffffc0200e10:	ed84                	sd	s1,24(a1)
    LOAD s1, 2*REGBYTES(a0)
ffffffffc0200e12:	6904                	ld	s1,16(a0)
    STORE s1, 2*REGBYTES(a1)
ffffffffc0200e14:	e984                	sd	s1,16(a1)
    LOAD s1, 1*REGBYTES(a0)
ffffffffc0200e16:	6504                	ld	s1,8(a0)
    STORE s1, 1*REGBYTES(a1)
ffffffffc0200e18:	e584                	sd	s1,8(a1)
    LOAD s1, 0*REGBYTES(a0)
ffffffffc0200e1a:	6104                	ld	s1,0(a0)
    STORE s1, 0*REGBYTES(a1)
ffffffffc0200e1c:	e184                	sd	s1,0(a1)

    // acutually adjust sp
    move sp, a1
ffffffffc0200e1e:	812e                	mv	sp,a1
ffffffffc0200e20:	bdf5                	j	ffffffffc0200d1c <__trapret>

ffffffffc0200e22 <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200e22:	000ae797          	auipc	a5,0xae
ffffffffc0200e26:	94e78793          	addi	a5,a5,-1714 # ffffffffc02ae770 <free_area>
ffffffffc0200e2a:	e79c                	sd	a5,8(a5)
ffffffffc0200e2c:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200e2e:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200e32:	8082                	ret

ffffffffc0200e34 <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200e34:	000ae517          	auipc	a0,0xae
ffffffffc0200e38:	94c56503          	lwu	a0,-1716(a0) # ffffffffc02ae780 <free_area+0x10>
ffffffffc0200e3c:	8082                	ret

ffffffffc0200e3e <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0200e3e:	715d                	addi	sp,sp,-80
ffffffffc0200e40:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200e42:	000ae417          	auipc	s0,0xae
ffffffffc0200e46:	92e40413          	addi	s0,s0,-1746 # ffffffffc02ae770 <free_area>
ffffffffc0200e4a:	641c                	ld	a5,8(s0)
ffffffffc0200e4c:	e486                	sd	ra,72(sp)
ffffffffc0200e4e:	fc26                	sd	s1,56(sp)
ffffffffc0200e50:	f84a                	sd	s2,48(sp)
ffffffffc0200e52:	f44e                	sd	s3,40(sp)
ffffffffc0200e54:	f052                	sd	s4,32(sp)
ffffffffc0200e56:	ec56                	sd	s5,24(sp)
ffffffffc0200e58:	e85a                	sd	s6,16(sp)
ffffffffc0200e5a:	e45e                	sd	s7,8(sp)
ffffffffc0200e5c:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200e5e:	2a878d63          	beq	a5,s0,ffffffffc0201118 <default_check+0x2da>
    int count = 0, total = 0;
ffffffffc0200e62:	4481                	li	s1,0
ffffffffc0200e64:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200e66:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200e6a:	8b09                	andi	a4,a4,2
ffffffffc0200e6c:	2a070a63          	beqz	a4,ffffffffc0201120 <default_check+0x2e2>
        count ++, total += p->property;
ffffffffc0200e70:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200e74:	679c                	ld	a5,8(a5)
ffffffffc0200e76:	2905                	addiw	s2,s2,1
ffffffffc0200e78:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200e7a:	fe8796e3          	bne	a5,s0,ffffffffc0200e66 <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200e7e:	89a6                	mv	s3,s1
ffffffffc0200e80:	733000ef          	jal	ra,ffffffffc0201db2 <nr_free_pages>
ffffffffc0200e84:	6f351e63          	bne	a0,s3,ffffffffc0201580 <default_check+0x742>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200e88:	4505                	li	a0,1
ffffffffc0200e8a:	657000ef          	jal	ra,ffffffffc0201ce0 <alloc_pages>
ffffffffc0200e8e:	8aaa                	mv	s5,a0
ffffffffc0200e90:	42050863          	beqz	a0,ffffffffc02012c0 <default_check+0x482>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200e94:	4505                	li	a0,1
ffffffffc0200e96:	64b000ef          	jal	ra,ffffffffc0201ce0 <alloc_pages>
ffffffffc0200e9a:	89aa                	mv	s3,a0
ffffffffc0200e9c:	70050263          	beqz	a0,ffffffffc02015a0 <default_check+0x762>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200ea0:	4505                	li	a0,1
ffffffffc0200ea2:	63f000ef          	jal	ra,ffffffffc0201ce0 <alloc_pages>
ffffffffc0200ea6:	8a2a                	mv	s4,a0
ffffffffc0200ea8:	48050c63          	beqz	a0,ffffffffc0201340 <default_check+0x502>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200eac:	293a8a63          	beq	s5,s3,ffffffffc0201140 <default_check+0x302>
ffffffffc0200eb0:	28aa8863          	beq	s5,a0,ffffffffc0201140 <default_check+0x302>
ffffffffc0200eb4:	28a98663          	beq	s3,a0,ffffffffc0201140 <default_check+0x302>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200eb8:	000aa783          	lw	a5,0(s5)
ffffffffc0200ebc:	2a079263          	bnez	a5,ffffffffc0201160 <default_check+0x322>
ffffffffc0200ec0:	0009a783          	lw	a5,0(s3)
ffffffffc0200ec4:	28079e63          	bnez	a5,ffffffffc0201160 <default_check+0x322>
ffffffffc0200ec8:	411c                	lw	a5,0(a0)
ffffffffc0200eca:	28079b63          	bnez	a5,ffffffffc0201160 <default_check+0x322>
extern size_t npage;
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page) {
    return page - pages + nbase;
ffffffffc0200ece:	000b2797          	auipc	a5,0xb2
ffffffffc0200ed2:	9a27b783          	ld	a5,-1630(a5) # ffffffffc02b2870 <pages>
ffffffffc0200ed6:	40fa8733          	sub	a4,s5,a5
ffffffffc0200eda:	00008617          	auipc	a2,0x8
ffffffffc0200ede:	c9663603          	ld	a2,-874(a2) # ffffffffc0208b70 <nbase>
ffffffffc0200ee2:	8719                	srai	a4,a4,0x6
ffffffffc0200ee4:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200ee6:	000b2697          	auipc	a3,0xb2
ffffffffc0200eea:	9826b683          	ld	a3,-1662(a3) # ffffffffc02b2868 <npage>
ffffffffc0200eee:	06b2                	slli	a3,a3,0xc
}

static inline uintptr_t
page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200ef0:	0732                	slli	a4,a4,0xc
ffffffffc0200ef2:	28d77763          	bgeu	a4,a3,ffffffffc0201180 <default_check+0x342>
    return page - pages + nbase;
ffffffffc0200ef6:	40f98733          	sub	a4,s3,a5
ffffffffc0200efa:	8719                	srai	a4,a4,0x6
ffffffffc0200efc:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200efe:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200f00:	4cd77063          	bgeu	a4,a3,ffffffffc02013c0 <default_check+0x582>
    return page - pages + nbase;
ffffffffc0200f04:	40f507b3          	sub	a5,a0,a5
ffffffffc0200f08:	8799                	srai	a5,a5,0x6
ffffffffc0200f0a:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200f0c:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200f0e:	30d7f963          	bgeu	a5,a3,ffffffffc0201220 <default_check+0x3e2>
    assert(alloc_page() == NULL);
ffffffffc0200f12:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200f14:	00043c03          	ld	s8,0(s0)
ffffffffc0200f18:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200f1c:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200f20:	e400                	sd	s0,8(s0)
ffffffffc0200f22:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0200f24:	000ae797          	auipc	a5,0xae
ffffffffc0200f28:	8407ae23          	sw	zero,-1956(a5) # ffffffffc02ae780 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200f2c:	5b5000ef          	jal	ra,ffffffffc0201ce0 <alloc_pages>
ffffffffc0200f30:	2c051863          	bnez	a0,ffffffffc0201200 <default_check+0x3c2>
    free_page(p0);
ffffffffc0200f34:	4585                	li	a1,1
ffffffffc0200f36:	8556                	mv	a0,s5
ffffffffc0200f38:	63b000ef          	jal	ra,ffffffffc0201d72 <free_pages>
    free_page(p1);
ffffffffc0200f3c:	4585                	li	a1,1
ffffffffc0200f3e:	854e                	mv	a0,s3
ffffffffc0200f40:	633000ef          	jal	ra,ffffffffc0201d72 <free_pages>
    free_page(p2);
ffffffffc0200f44:	4585                	li	a1,1
ffffffffc0200f46:	8552                	mv	a0,s4
ffffffffc0200f48:	62b000ef          	jal	ra,ffffffffc0201d72 <free_pages>
    assert(nr_free == 3);
ffffffffc0200f4c:	4818                	lw	a4,16(s0)
ffffffffc0200f4e:	478d                	li	a5,3
ffffffffc0200f50:	28f71863          	bne	a4,a5,ffffffffc02011e0 <default_check+0x3a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200f54:	4505                	li	a0,1
ffffffffc0200f56:	58b000ef          	jal	ra,ffffffffc0201ce0 <alloc_pages>
ffffffffc0200f5a:	89aa                	mv	s3,a0
ffffffffc0200f5c:	26050263          	beqz	a0,ffffffffc02011c0 <default_check+0x382>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200f60:	4505                	li	a0,1
ffffffffc0200f62:	57f000ef          	jal	ra,ffffffffc0201ce0 <alloc_pages>
ffffffffc0200f66:	8aaa                	mv	s5,a0
ffffffffc0200f68:	3a050c63          	beqz	a0,ffffffffc0201320 <default_check+0x4e2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200f6c:	4505                	li	a0,1
ffffffffc0200f6e:	573000ef          	jal	ra,ffffffffc0201ce0 <alloc_pages>
ffffffffc0200f72:	8a2a                	mv	s4,a0
ffffffffc0200f74:	38050663          	beqz	a0,ffffffffc0201300 <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc0200f78:	4505                	li	a0,1
ffffffffc0200f7a:	567000ef          	jal	ra,ffffffffc0201ce0 <alloc_pages>
ffffffffc0200f7e:	36051163          	bnez	a0,ffffffffc02012e0 <default_check+0x4a2>
    free_page(p0);
ffffffffc0200f82:	4585                	li	a1,1
ffffffffc0200f84:	854e                	mv	a0,s3
ffffffffc0200f86:	5ed000ef          	jal	ra,ffffffffc0201d72 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200f8a:	641c                	ld	a5,8(s0)
ffffffffc0200f8c:	20878a63          	beq	a5,s0,ffffffffc02011a0 <default_check+0x362>
    assert((p = alloc_page()) == p0);
ffffffffc0200f90:	4505                	li	a0,1
ffffffffc0200f92:	54f000ef          	jal	ra,ffffffffc0201ce0 <alloc_pages>
ffffffffc0200f96:	30a99563          	bne	s3,a0,ffffffffc02012a0 <default_check+0x462>
    assert(alloc_page() == NULL);
ffffffffc0200f9a:	4505                	li	a0,1
ffffffffc0200f9c:	545000ef          	jal	ra,ffffffffc0201ce0 <alloc_pages>
ffffffffc0200fa0:	2e051063          	bnez	a0,ffffffffc0201280 <default_check+0x442>
    assert(nr_free == 0);
ffffffffc0200fa4:	481c                	lw	a5,16(s0)
ffffffffc0200fa6:	2a079d63          	bnez	a5,ffffffffc0201260 <default_check+0x422>
    free_page(p);
ffffffffc0200faa:	854e                	mv	a0,s3
ffffffffc0200fac:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200fae:	01843023          	sd	s8,0(s0)
ffffffffc0200fb2:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200fb6:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200fba:	5b9000ef          	jal	ra,ffffffffc0201d72 <free_pages>
    free_page(p1);
ffffffffc0200fbe:	4585                	li	a1,1
ffffffffc0200fc0:	8556                	mv	a0,s5
ffffffffc0200fc2:	5b1000ef          	jal	ra,ffffffffc0201d72 <free_pages>
    free_page(p2);
ffffffffc0200fc6:	4585                	li	a1,1
ffffffffc0200fc8:	8552                	mv	a0,s4
ffffffffc0200fca:	5a9000ef          	jal	ra,ffffffffc0201d72 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200fce:	4515                	li	a0,5
ffffffffc0200fd0:	511000ef          	jal	ra,ffffffffc0201ce0 <alloc_pages>
ffffffffc0200fd4:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200fd6:	26050563          	beqz	a0,ffffffffc0201240 <default_check+0x402>
ffffffffc0200fda:	651c                	ld	a5,8(a0)
ffffffffc0200fdc:	8385                	srli	a5,a5,0x1
ffffffffc0200fde:	8b85                	andi	a5,a5,1
    assert(!PageProperty(p0));
ffffffffc0200fe0:	54079063          	bnez	a5,ffffffffc0201520 <default_check+0x6e2>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200fe4:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200fe6:	00043b03          	ld	s6,0(s0)
ffffffffc0200fea:	00843a83          	ld	s5,8(s0)
ffffffffc0200fee:	e000                	sd	s0,0(s0)
ffffffffc0200ff0:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200ff2:	4ef000ef          	jal	ra,ffffffffc0201ce0 <alloc_pages>
ffffffffc0200ff6:	50051563          	bnez	a0,ffffffffc0201500 <default_check+0x6c2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0200ffa:	08098a13          	addi	s4,s3,128
ffffffffc0200ffe:	8552                	mv	a0,s4
ffffffffc0201000:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0201002:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc0201006:	000ad797          	auipc	a5,0xad
ffffffffc020100a:	7607ad23          	sw	zero,1914(a5) # ffffffffc02ae780 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc020100e:	565000ef          	jal	ra,ffffffffc0201d72 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0201012:	4511                	li	a0,4
ffffffffc0201014:	4cd000ef          	jal	ra,ffffffffc0201ce0 <alloc_pages>
ffffffffc0201018:	4c051463          	bnez	a0,ffffffffc02014e0 <default_check+0x6a2>
ffffffffc020101c:	0889b783          	ld	a5,136(s3)
ffffffffc0201020:	8385                	srli	a5,a5,0x1
ffffffffc0201022:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201024:	48078e63          	beqz	a5,ffffffffc02014c0 <default_check+0x682>
ffffffffc0201028:	0909a703          	lw	a4,144(s3)
ffffffffc020102c:	478d                	li	a5,3
ffffffffc020102e:	48f71963          	bne	a4,a5,ffffffffc02014c0 <default_check+0x682>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201032:	450d                	li	a0,3
ffffffffc0201034:	4ad000ef          	jal	ra,ffffffffc0201ce0 <alloc_pages>
ffffffffc0201038:	8c2a                	mv	s8,a0
ffffffffc020103a:	46050363          	beqz	a0,ffffffffc02014a0 <default_check+0x662>
    assert(alloc_page() == NULL);
ffffffffc020103e:	4505                	li	a0,1
ffffffffc0201040:	4a1000ef          	jal	ra,ffffffffc0201ce0 <alloc_pages>
ffffffffc0201044:	42051e63          	bnez	a0,ffffffffc0201480 <default_check+0x642>
    assert(p0 + 2 == p1);
ffffffffc0201048:	418a1c63          	bne	s4,s8,ffffffffc0201460 <default_check+0x622>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc020104c:	4585                	li	a1,1
ffffffffc020104e:	854e                	mv	a0,s3
ffffffffc0201050:	523000ef          	jal	ra,ffffffffc0201d72 <free_pages>
    free_pages(p1, 3);
ffffffffc0201054:	458d                	li	a1,3
ffffffffc0201056:	8552                	mv	a0,s4
ffffffffc0201058:	51b000ef          	jal	ra,ffffffffc0201d72 <free_pages>
ffffffffc020105c:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0201060:	04098c13          	addi	s8,s3,64
ffffffffc0201064:	8385                	srli	a5,a5,0x1
ffffffffc0201066:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201068:	3c078c63          	beqz	a5,ffffffffc0201440 <default_check+0x602>
ffffffffc020106c:	0109a703          	lw	a4,16(s3)
ffffffffc0201070:	4785                	li	a5,1
ffffffffc0201072:	3cf71763          	bne	a4,a5,ffffffffc0201440 <default_check+0x602>
ffffffffc0201076:	008a3783          	ld	a5,8(s4)
ffffffffc020107a:	8385                	srli	a5,a5,0x1
ffffffffc020107c:	8b85                	andi	a5,a5,1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc020107e:	3a078163          	beqz	a5,ffffffffc0201420 <default_check+0x5e2>
ffffffffc0201082:	010a2703          	lw	a4,16(s4)
ffffffffc0201086:	478d                	li	a5,3
ffffffffc0201088:	38f71c63          	bne	a4,a5,ffffffffc0201420 <default_check+0x5e2>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc020108c:	4505                	li	a0,1
ffffffffc020108e:	453000ef          	jal	ra,ffffffffc0201ce0 <alloc_pages>
ffffffffc0201092:	36a99763          	bne	s3,a0,ffffffffc0201400 <default_check+0x5c2>
    free_page(p0);
ffffffffc0201096:	4585                	li	a1,1
ffffffffc0201098:	4db000ef          	jal	ra,ffffffffc0201d72 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc020109c:	4509                	li	a0,2
ffffffffc020109e:	443000ef          	jal	ra,ffffffffc0201ce0 <alloc_pages>
ffffffffc02010a2:	32aa1f63          	bne	s4,a0,ffffffffc02013e0 <default_check+0x5a2>

    free_pages(p0, 2);
ffffffffc02010a6:	4589                	li	a1,2
ffffffffc02010a8:	4cb000ef          	jal	ra,ffffffffc0201d72 <free_pages>
    free_page(p2);
ffffffffc02010ac:	4585                	li	a1,1
ffffffffc02010ae:	8562                	mv	a0,s8
ffffffffc02010b0:	4c3000ef          	jal	ra,ffffffffc0201d72 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02010b4:	4515                	li	a0,5
ffffffffc02010b6:	42b000ef          	jal	ra,ffffffffc0201ce0 <alloc_pages>
ffffffffc02010ba:	89aa                	mv	s3,a0
ffffffffc02010bc:	48050263          	beqz	a0,ffffffffc0201540 <default_check+0x702>
    assert(alloc_page() == NULL);
ffffffffc02010c0:	4505                	li	a0,1
ffffffffc02010c2:	41f000ef          	jal	ra,ffffffffc0201ce0 <alloc_pages>
ffffffffc02010c6:	2c051d63          	bnez	a0,ffffffffc02013a0 <default_check+0x562>

    assert(nr_free == 0);
ffffffffc02010ca:	481c                	lw	a5,16(s0)
ffffffffc02010cc:	2a079a63          	bnez	a5,ffffffffc0201380 <default_check+0x542>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc02010d0:	4595                	li	a1,5
ffffffffc02010d2:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc02010d4:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc02010d8:	01643023          	sd	s6,0(s0)
ffffffffc02010dc:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc02010e0:	493000ef          	jal	ra,ffffffffc0201d72 <free_pages>
    return listelm->next;
ffffffffc02010e4:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc02010e6:	00878963          	beq	a5,s0,ffffffffc02010f8 <default_check+0x2ba>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc02010ea:	ff87a703          	lw	a4,-8(a5)
ffffffffc02010ee:	679c                	ld	a5,8(a5)
ffffffffc02010f0:	397d                	addiw	s2,s2,-1
ffffffffc02010f2:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc02010f4:	fe879be3          	bne	a5,s0,ffffffffc02010ea <default_check+0x2ac>
    }
    assert(count == 0);
ffffffffc02010f8:	26091463          	bnez	s2,ffffffffc0201360 <default_check+0x522>
    assert(total == 0);
ffffffffc02010fc:	46049263          	bnez	s1,ffffffffc0201560 <default_check+0x722>
}
ffffffffc0201100:	60a6                	ld	ra,72(sp)
ffffffffc0201102:	6406                	ld	s0,64(sp)
ffffffffc0201104:	74e2                	ld	s1,56(sp)
ffffffffc0201106:	7942                	ld	s2,48(sp)
ffffffffc0201108:	79a2                	ld	s3,40(sp)
ffffffffc020110a:	7a02                	ld	s4,32(sp)
ffffffffc020110c:	6ae2                	ld	s5,24(sp)
ffffffffc020110e:	6b42                	ld	s6,16(sp)
ffffffffc0201110:	6ba2                	ld	s7,8(sp)
ffffffffc0201112:	6c02                	ld	s8,0(sp)
ffffffffc0201114:	6161                	addi	sp,sp,80
ffffffffc0201116:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201118:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc020111a:	4481                	li	s1,0
ffffffffc020111c:	4901                	li	s2,0
ffffffffc020111e:	b38d                	j	ffffffffc0200e80 <default_check+0x42>
        assert(PageProperty(p));
ffffffffc0201120:	00006697          	auipc	a3,0x6
ffffffffc0201124:	d6068693          	addi	a3,a3,-672 # ffffffffc0206e80 <commands+0x740>
ffffffffc0201128:	00006617          	auipc	a2,0x6
ffffffffc020112c:	a6860613          	addi	a2,a2,-1432 # ffffffffc0206b90 <commands+0x450>
ffffffffc0201130:	0f000593          	li	a1,240
ffffffffc0201134:	00006517          	auipc	a0,0x6
ffffffffc0201138:	d5c50513          	addi	a0,a0,-676 # ffffffffc0206e90 <commands+0x750>
ffffffffc020113c:	b3eff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201140:	00006697          	auipc	a3,0x6
ffffffffc0201144:	de868693          	addi	a3,a3,-536 # ffffffffc0206f28 <commands+0x7e8>
ffffffffc0201148:	00006617          	auipc	a2,0x6
ffffffffc020114c:	a4860613          	addi	a2,a2,-1464 # ffffffffc0206b90 <commands+0x450>
ffffffffc0201150:	0bd00593          	li	a1,189
ffffffffc0201154:	00006517          	auipc	a0,0x6
ffffffffc0201158:	d3c50513          	addi	a0,a0,-708 # ffffffffc0206e90 <commands+0x750>
ffffffffc020115c:	b1eff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201160:	00006697          	auipc	a3,0x6
ffffffffc0201164:	df068693          	addi	a3,a3,-528 # ffffffffc0206f50 <commands+0x810>
ffffffffc0201168:	00006617          	auipc	a2,0x6
ffffffffc020116c:	a2860613          	addi	a2,a2,-1496 # ffffffffc0206b90 <commands+0x450>
ffffffffc0201170:	0be00593          	li	a1,190
ffffffffc0201174:	00006517          	auipc	a0,0x6
ffffffffc0201178:	d1c50513          	addi	a0,a0,-740 # ffffffffc0206e90 <commands+0x750>
ffffffffc020117c:	afeff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201180:	00006697          	auipc	a3,0x6
ffffffffc0201184:	e1068693          	addi	a3,a3,-496 # ffffffffc0206f90 <commands+0x850>
ffffffffc0201188:	00006617          	auipc	a2,0x6
ffffffffc020118c:	a0860613          	addi	a2,a2,-1528 # ffffffffc0206b90 <commands+0x450>
ffffffffc0201190:	0c000593          	li	a1,192
ffffffffc0201194:	00006517          	auipc	a0,0x6
ffffffffc0201198:	cfc50513          	addi	a0,a0,-772 # ffffffffc0206e90 <commands+0x750>
ffffffffc020119c:	adeff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(!list_empty(&free_list));
ffffffffc02011a0:	00006697          	auipc	a3,0x6
ffffffffc02011a4:	e7868693          	addi	a3,a3,-392 # ffffffffc0207018 <commands+0x8d8>
ffffffffc02011a8:	00006617          	auipc	a2,0x6
ffffffffc02011ac:	9e860613          	addi	a2,a2,-1560 # ffffffffc0206b90 <commands+0x450>
ffffffffc02011b0:	0d900593          	li	a1,217
ffffffffc02011b4:	00006517          	auipc	a0,0x6
ffffffffc02011b8:	cdc50513          	addi	a0,a0,-804 # ffffffffc0206e90 <commands+0x750>
ffffffffc02011bc:	abeff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02011c0:	00006697          	auipc	a3,0x6
ffffffffc02011c4:	d0868693          	addi	a3,a3,-760 # ffffffffc0206ec8 <commands+0x788>
ffffffffc02011c8:	00006617          	auipc	a2,0x6
ffffffffc02011cc:	9c860613          	addi	a2,a2,-1592 # ffffffffc0206b90 <commands+0x450>
ffffffffc02011d0:	0d200593          	li	a1,210
ffffffffc02011d4:	00006517          	auipc	a0,0x6
ffffffffc02011d8:	cbc50513          	addi	a0,a0,-836 # ffffffffc0206e90 <commands+0x750>
ffffffffc02011dc:	a9eff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(nr_free == 3);
ffffffffc02011e0:	00006697          	auipc	a3,0x6
ffffffffc02011e4:	e2868693          	addi	a3,a3,-472 # ffffffffc0207008 <commands+0x8c8>
ffffffffc02011e8:	00006617          	auipc	a2,0x6
ffffffffc02011ec:	9a860613          	addi	a2,a2,-1624 # ffffffffc0206b90 <commands+0x450>
ffffffffc02011f0:	0d000593          	li	a1,208
ffffffffc02011f4:	00006517          	auipc	a0,0x6
ffffffffc02011f8:	c9c50513          	addi	a0,a0,-868 # ffffffffc0206e90 <commands+0x750>
ffffffffc02011fc:	a7eff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201200:	00006697          	auipc	a3,0x6
ffffffffc0201204:	df068693          	addi	a3,a3,-528 # ffffffffc0206ff0 <commands+0x8b0>
ffffffffc0201208:	00006617          	auipc	a2,0x6
ffffffffc020120c:	98860613          	addi	a2,a2,-1656 # ffffffffc0206b90 <commands+0x450>
ffffffffc0201210:	0cb00593          	li	a1,203
ffffffffc0201214:	00006517          	auipc	a0,0x6
ffffffffc0201218:	c7c50513          	addi	a0,a0,-900 # ffffffffc0206e90 <commands+0x750>
ffffffffc020121c:	a5eff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201220:	00006697          	auipc	a3,0x6
ffffffffc0201224:	db068693          	addi	a3,a3,-592 # ffffffffc0206fd0 <commands+0x890>
ffffffffc0201228:	00006617          	auipc	a2,0x6
ffffffffc020122c:	96860613          	addi	a2,a2,-1688 # ffffffffc0206b90 <commands+0x450>
ffffffffc0201230:	0c200593          	li	a1,194
ffffffffc0201234:	00006517          	auipc	a0,0x6
ffffffffc0201238:	c5c50513          	addi	a0,a0,-932 # ffffffffc0206e90 <commands+0x750>
ffffffffc020123c:	a3eff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(p0 != NULL);
ffffffffc0201240:	00006697          	auipc	a3,0x6
ffffffffc0201244:	e2068693          	addi	a3,a3,-480 # ffffffffc0207060 <commands+0x920>
ffffffffc0201248:	00006617          	auipc	a2,0x6
ffffffffc020124c:	94860613          	addi	a2,a2,-1720 # ffffffffc0206b90 <commands+0x450>
ffffffffc0201250:	0f800593          	li	a1,248
ffffffffc0201254:	00006517          	auipc	a0,0x6
ffffffffc0201258:	c3c50513          	addi	a0,a0,-964 # ffffffffc0206e90 <commands+0x750>
ffffffffc020125c:	a1eff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(nr_free == 0);
ffffffffc0201260:	00006697          	auipc	a3,0x6
ffffffffc0201264:	df068693          	addi	a3,a3,-528 # ffffffffc0207050 <commands+0x910>
ffffffffc0201268:	00006617          	auipc	a2,0x6
ffffffffc020126c:	92860613          	addi	a2,a2,-1752 # ffffffffc0206b90 <commands+0x450>
ffffffffc0201270:	0df00593          	li	a1,223
ffffffffc0201274:	00006517          	auipc	a0,0x6
ffffffffc0201278:	c1c50513          	addi	a0,a0,-996 # ffffffffc0206e90 <commands+0x750>
ffffffffc020127c:	9feff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201280:	00006697          	auipc	a3,0x6
ffffffffc0201284:	d7068693          	addi	a3,a3,-656 # ffffffffc0206ff0 <commands+0x8b0>
ffffffffc0201288:	00006617          	auipc	a2,0x6
ffffffffc020128c:	90860613          	addi	a2,a2,-1784 # ffffffffc0206b90 <commands+0x450>
ffffffffc0201290:	0dd00593          	li	a1,221
ffffffffc0201294:	00006517          	auipc	a0,0x6
ffffffffc0201298:	bfc50513          	addi	a0,a0,-1028 # ffffffffc0206e90 <commands+0x750>
ffffffffc020129c:	9deff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc02012a0:	00006697          	auipc	a3,0x6
ffffffffc02012a4:	d9068693          	addi	a3,a3,-624 # ffffffffc0207030 <commands+0x8f0>
ffffffffc02012a8:	00006617          	auipc	a2,0x6
ffffffffc02012ac:	8e860613          	addi	a2,a2,-1816 # ffffffffc0206b90 <commands+0x450>
ffffffffc02012b0:	0dc00593          	li	a1,220
ffffffffc02012b4:	00006517          	auipc	a0,0x6
ffffffffc02012b8:	bdc50513          	addi	a0,a0,-1060 # ffffffffc0206e90 <commands+0x750>
ffffffffc02012bc:	9beff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02012c0:	00006697          	auipc	a3,0x6
ffffffffc02012c4:	c0868693          	addi	a3,a3,-1016 # ffffffffc0206ec8 <commands+0x788>
ffffffffc02012c8:	00006617          	auipc	a2,0x6
ffffffffc02012cc:	8c860613          	addi	a2,a2,-1848 # ffffffffc0206b90 <commands+0x450>
ffffffffc02012d0:	0b900593          	li	a1,185
ffffffffc02012d4:	00006517          	auipc	a0,0x6
ffffffffc02012d8:	bbc50513          	addi	a0,a0,-1092 # ffffffffc0206e90 <commands+0x750>
ffffffffc02012dc:	99eff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(alloc_page() == NULL);
ffffffffc02012e0:	00006697          	auipc	a3,0x6
ffffffffc02012e4:	d1068693          	addi	a3,a3,-752 # ffffffffc0206ff0 <commands+0x8b0>
ffffffffc02012e8:	00006617          	auipc	a2,0x6
ffffffffc02012ec:	8a860613          	addi	a2,a2,-1880 # ffffffffc0206b90 <commands+0x450>
ffffffffc02012f0:	0d600593          	li	a1,214
ffffffffc02012f4:	00006517          	auipc	a0,0x6
ffffffffc02012f8:	b9c50513          	addi	a0,a0,-1124 # ffffffffc0206e90 <commands+0x750>
ffffffffc02012fc:	97eff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201300:	00006697          	auipc	a3,0x6
ffffffffc0201304:	c0868693          	addi	a3,a3,-1016 # ffffffffc0206f08 <commands+0x7c8>
ffffffffc0201308:	00006617          	auipc	a2,0x6
ffffffffc020130c:	88860613          	addi	a2,a2,-1912 # ffffffffc0206b90 <commands+0x450>
ffffffffc0201310:	0d400593          	li	a1,212
ffffffffc0201314:	00006517          	auipc	a0,0x6
ffffffffc0201318:	b7c50513          	addi	a0,a0,-1156 # ffffffffc0206e90 <commands+0x750>
ffffffffc020131c:	95eff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201320:	00006697          	auipc	a3,0x6
ffffffffc0201324:	bc868693          	addi	a3,a3,-1080 # ffffffffc0206ee8 <commands+0x7a8>
ffffffffc0201328:	00006617          	auipc	a2,0x6
ffffffffc020132c:	86860613          	addi	a2,a2,-1944 # ffffffffc0206b90 <commands+0x450>
ffffffffc0201330:	0d300593          	li	a1,211
ffffffffc0201334:	00006517          	auipc	a0,0x6
ffffffffc0201338:	b5c50513          	addi	a0,a0,-1188 # ffffffffc0206e90 <commands+0x750>
ffffffffc020133c:	93eff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201340:	00006697          	auipc	a3,0x6
ffffffffc0201344:	bc868693          	addi	a3,a3,-1080 # ffffffffc0206f08 <commands+0x7c8>
ffffffffc0201348:	00006617          	auipc	a2,0x6
ffffffffc020134c:	84860613          	addi	a2,a2,-1976 # ffffffffc0206b90 <commands+0x450>
ffffffffc0201350:	0bb00593          	li	a1,187
ffffffffc0201354:	00006517          	auipc	a0,0x6
ffffffffc0201358:	b3c50513          	addi	a0,a0,-1220 # ffffffffc0206e90 <commands+0x750>
ffffffffc020135c:	91eff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(count == 0);
ffffffffc0201360:	00006697          	auipc	a3,0x6
ffffffffc0201364:	e5068693          	addi	a3,a3,-432 # ffffffffc02071b0 <commands+0xa70>
ffffffffc0201368:	00006617          	auipc	a2,0x6
ffffffffc020136c:	82860613          	addi	a2,a2,-2008 # ffffffffc0206b90 <commands+0x450>
ffffffffc0201370:	12500593          	li	a1,293
ffffffffc0201374:	00006517          	auipc	a0,0x6
ffffffffc0201378:	b1c50513          	addi	a0,a0,-1252 # ffffffffc0206e90 <commands+0x750>
ffffffffc020137c:	8feff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(nr_free == 0);
ffffffffc0201380:	00006697          	auipc	a3,0x6
ffffffffc0201384:	cd068693          	addi	a3,a3,-816 # ffffffffc0207050 <commands+0x910>
ffffffffc0201388:	00006617          	auipc	a2,0x6
ffffffffc020138c:	80860613          	addi	a2,a2,-2040 # ffffffffc0206b90 <commands+0x450>
ffffffffc0201390:	11a00593          	li	a1,282
ffffffffc0201394:	00006517          	auipc	a0,0x6
ffffffffc0201398:	afc50513          	addi	a0,a0,-1284 # ffffffffc0206e90 <commands+0x750>
ffffffffc020139c:	8deff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(alloc_page() == NULL);
ffffffffc02013a0:	00006697          	auipc	a3,0x6
ffffffffc02013a4:	c5068693          	addi	a3,a3,-944 # ffffffffc0206ff0 <commands+0x8b0>
ffffffffc02013a8:	00005617          	auipc	a2,0x5
ffffffffc02013ac:	7e860613          	addi	a2,a2,2024 # ffffffffc0206b90 <commands+0x450>
ffffffffc02013b0:	11800593          	li	a1,280
ffffffffc02013b4:	00006517          	auipc	a0,0x6
ffffffffc02013b8:	adc50513          	addi	a0,a0,-1316 # ffffffffc0206e90 <commands+0x750>
ffffffffc02013bc:	8beff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02013c0:	00006697          	auipc	a3,0x6
ffffffffc02013c4:	bf068693          	addi	a3,a3,-1040 # ffffffffc0206fb0 <commands+0x870>
ffffffffc02013c8:	00005617          	auipc	a2,0x5
ffffffffc02013cc:	7c860613          	addi	a2,a2,1992 # ffffffffc0206b90 <commands+0x450>
ffffffffc02013d0:	0c100593          	li	a1,193
ffffffffc02013d4:	00006517          	auipc	a0,0x6
ffffffffc02013d8:	abc50513          	addi	a0,a0,-1348 # ffffffffc0206e90 <commands+0x750>
ffffffffc02013dc:	89eff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02013e0:	00006697          	auipc	a3,0x6
ffffffffc02013e4:	d9068693          	addi	a3,a3,-624 # ffffffffc0207170 <commands+0xa30>
ffffffffc02013e8:	00005617          	auipc	a2,0x5
ffffffffc02013ec:	7a860613          	addi	a2,a2,1960 # ffffffffc0206b90 <commands+0x450>
ffffffffc02013f0:	11200593          	li	a1,274
ffffffffc02013f4:	00006517          	auipc	a0,0x6
ffffffffc02013f8:	a9c50513          	addi	a0,a0,-1380 # ffffffffc0206e90 <commands+0x750>
ffffffffc02013fc:	87eff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201400:	00006697          	auipc	a3,0x6
ffffffffc0201404:	d5068693          	addi	a3,a3,-688 # ffffffffc0207150 <commands+0xa10>
ffffffffc0201408:	00005617          	auipc	a2,0x5
ffffffffc020140c:	78860613          	addi	a2,a2,1928 # ffffffffc0206b90 <commands+0x450>
ffffffffc0201410:	11000593          	li	a1,272
ffffffffc0201414:	00006517          	auipc	a0,0x6
ffffffffc0201418:	a7c50513          	addi	a0,a0,-1412 # ffffffffc0206e90 <commands+0x750>
ffffffffc020141c:	85eff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201420:	00006697          	auipc	a3,0x6
ffffffffc0201424:	d0868693          	addi	a3,a3,-760 # ffffffffc0207128 <commands+0x9e8>
ffffffffc0201428:	00005617          	auipc	a2,0x5
ffffffffc020142c:	76860613          	addi	a2,a2,1896 # ffffffffc0206b90 <commands+0x450>
ffffffffc0201430:	10e00593          	li	a1,270
ffffffffc0201434:	00006517          	auipc	a0,0x6
ffffffffc0201438:	a5c50513          	addi	a0,a0,-1444 # ffffffffc0206e90 <commands+0x750>
ffffffffc020143c:	83eff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201440:	00006697          	auipc	a3,0x6
ffffffffc0201444:	cc068693          	addi	a3,a3,-832 # ffffffffc0207100 <commands+0x9c0>
ffffffffc0201448:	00005617          	auipc	a2,0x5
ffffffffc020144c:	74860613          	addi	a2,a2,1864 # ffffffffc0206b90 <commands+0x450>
ffffffffc0201450:	10d00593          	li	a1,269
ffffffffc0201454:	00006517          	auipc	a0,0x6
ffffffffc0201458:	a3c50513          	addi	a0,a0,-1476 # ffffffffc0206e90 <commands+0x750>
ffffffffc020145c:	81eff0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(p0 + 2 == p1);
ffffffffc0201460:	00006697          	auipc	a3,0x6
ffffffffc0201464:	c9068693          	addi	a3,a3,-880 # ffffffffc02070f0 <commands+0x9b0>
ffffffffc0201468:	00005617          	auipc	a2,0x5
ffffffffc020146c:	72860613          	addi	a2,a2,1832 # ffffffffc0206b90 <commands+0x450>
ffffffffc0201470:	10800593          	li	a1,264
ffffffffc0201474:	00006517          	auipc	a0,0x6
ffffffffc0201478:	a1c50513          	addi	a0,a0,-1508 # ffffffffc0206e90 <commands+0x750>
ffffffffc020147c:	ffffe0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201480:	00006697          	auipc	a3,0x6
ffffffffc0201484:	b7068693          	addi	a3,a3,-1168 # ffffffffc0206ff0 <commands+0x8b0>
ffffffffc0201488:	00005617          	auipc	a2,0x5
ffffffffc020148c:	70860613          	addi	a2,a2,1800 # ffffffffc0206b90 <commands+0x450>
ffffffffc0201490:	10700593          	li	a1,263
ffffffffc0201494:	00006517          	auipc	a0,0x6
ffffffffc0201498:	9fc50513          	addi	a0,a0,-1540 # ffffffffc0206e90 <commands+0x750>
ffffffffc020149c:	fdffe0ef          	jal	ra,ffffffffc020047a <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02014a0:	00006697          	auipc	a3,0x6
ffffffffc02014a4:	c3068693          	addi	a3,a3,-976 # ffffffffc02070d0 <commands+0x990>
ffffffffc02014a8:	00005617          	auipc	a2,0x5
ffffffffc02014ac:	6e860613          	addi	a2,a2,1768 # ffffffffc0206b90 <commands+0x450>
ffffffffc02014b0:	10600593          	li	a1,262
ffffffffc02014b4:	00006517          	auipc	a0,0x6
ffffffffc02014b8:	9dc50513          	addi	a0,a0,-1572 # ffffffffc0206e90 <commands+0x750>
ffffffffc02014bc:	fbffe0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02014c0:	00006697          	auipc	a3,0x6
ffffffffc02014c4:	be068693          	addi	a3,a3,-1056 # ffffffffc02070a0 <commands+0x960>
ffffffffc02014c8:	00005617          	auipc	a2,0x5
ffffffffc02014cc:	6c860613          	addi	a2,a2,1736 # ffffffffc0206b90 <commands+0x450>
ffffffffc02014d0:	10500593          	li	a1,261
ffffffffc02014d4:	00006517          	auipc	a0,0x6
ffffffffc02014d8:	9bc50513          	addi	a0,a0,-1604 # ffffffffc0206e90 <commands+0x750>
ffffffffc02014dc:	f9ffe0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc02014e0:	00006697          	auipc	a3,0x6
ffffffffc02014e4:	ba868693          	addi	a3,a3,-1112 # ffffffffc0207088 <commands+0x948>
ffffffffc02014e8:	00005617          	auipc	a2,0x5
ffffffffc02014ec:	6a860613          	addi	a2,a2,1704 # ffffffffc0206b90 <commands+0x450>
ffffffffc02014f0:	10400593          	li	a1,260
ffffffffc02014f4:	00006517          	auipc	a0,0x6
ffffffffc02014f8:	99c50513          	addi	a0,a0,-1636 # ffffffffc0206e90 <commands+0x750>
ffffffffc02014fc:	f7ffe0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201500:	00006697          	auipc	a3,0x6
ffffffffc0201504:	af068693          	addi	a3,a3,-1296 # ffffffffc0206ff0 <commands+0x8b0>
ffffffffc0201508:	00005617          	auipc	a2,0x5
ffffffffc020150c:	68860613          	addi	a2,a2,1672 # ffffffffc0206b90 <commands+0x450>
ffffffffc0201510:	0fe00593          	li	a1,254
ffffffffc0201514:	00006517          	auipc	a0,0x6
ffffffffc0201518:	97c50513          	addi	a0,a0,-1668 # ffffffffc0206e90 <commands+0x750>
ffffffffc020151c:	f5ffe0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(!PageProperty(p0));
ffffffffc0201520:	00006697          	auipc	a3,0x6
ffffffffc0201524:	b5068693          	addi	a3,a3,-1200 # ffffffffc0207070 <commands+0x930>
ffffffffc0201528:	00005617          	auipc	a2,0x5
ffffffffc020152c:	66860613          	addi	a2,a2,1640 # ffffffffc0206b90 <commands+0x450>
ffffffffc0201530:	0f900593          	li	a1,249
ffffffffc0201534:	00006517          	auipc	a0,0x6
ffffffffc0201538:	95c50513          	addi	a0,a0,-1700 # ffffffffc0206e90 <commands+0x750>
ffffffffc020153c:	f3ffe0ef          	jal	ra,ffffffffc020047a <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201540:	00006697          	auipc	a3,0x6
ffffffffc0201544:	c5068693          	addi	a3,a3,-944 # ffffffffc0207190 <commands+0xa50>
ffffffffc0201548:	00005617          	auipc	a2,0x5
ffffffffc020154c:	64860613          	addi	a2,a2,1608 # ffffffffc0206b90 <commands+0x450>
ffffffffc0201550:	11700593          	li	a1,279
ffffffffc0201554:	00006517          	auipc	a0,0x6
ffffffffc0201558:	93c50513          	addi	a0,a0,-1732 # ffffffffc0206e90 <commands+0x750>
ffffffffc020155c:	f1ffe0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(total == 0);
ffffffffc0201560:	00006697          	auipc	a3,0x6
ffffffffc0201564:	c6068693          	addi	a3,a3,-928 # ffffffffc02071c0 <commands+0xa80>
ffffffffc0201568:	00005617          	auipc	a2,0x5
ffffffffc020156c:	62860613          	addi	a2,a2,1576 # ffffffffc0206b90 <commands+0x450>
ffffffffc0201570:	12600593          	li	a1,294
ffffffffc0201574:	00006517          	auipc	a0,0x6
ffffffffc0201578:	91c50513          	addi	a0,a0,-1764 # ffffffffc0206e90 <commands+0x750>
ffffffffc020157c:	efffe0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(total == nr_free_pages());
ffffffffc0201580:	00006697          	auipc	a3,0x6
ffffffffc0201584:	92868693          	addi	a3,a3,-1752 # ffffffffc0206ea8 <commands+0x768>
ffffffffc0201588:	00005617          	auipc	a2,0x5
ffffffffc020158c:	60860613          	addi	a2,a2,1544 # ffffffffc0206b90 <commands+0x450>
ffffffffc0201590:	0f300593          	li	a1,243
ffffffffc0201594:	00006517          	auipc	a0,0x6
ffffffffc0201598:	8fc50513          	addi	a0,a0,-1796 # ffffffffc0206e90 <commands+0x750>
ffffffffc020159c:	edffe0ef          	jal	ra,ffffffffc020047a <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02015a0:	00006697          	auipc	a3,0x6
ffffffffc02015a4:	94868693          	addi	a3,a3,-1720 # ffffffffc0206ee8 <commands+0x7a8>
ffffffffc02015a8:	00005617          	auipc	a2,0x5
ffffffffc02015ac:	5e860613          	addi	a2,a2,1512 # ffffffffc0206b90 <commands+0x450>
ffffffffc02015b0:	0ba00593          	li	a1,186
ffffffffc02015b4:	00006517          	auipc	a0,0x6
ffffffffc02015b8:	8dc50513          	addi	a0,a0,-1828 # ffffffffc0206e90 <commands+0x750>
ffffffffc02015bc:	ebffe0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc02015c0 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc02015c0:	1141                	addi	sp,sp,-16
ffffffffc02015c2:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02015c4:	14058463          	beqz	a1,ffffffffc020170c <default_free_pages+0x14c>
    for (; p != base + n; p ++) {
ffffffffc02015c8:	00659693          	slli	a3,a1,0x6
ffffffffc02015cc:	96aa                	add	a3,a3,a0
ffffffffc02015ce:	87aa                	mv	a5,a0
ffffffffc02015d0:	02d50263          	beq	a0,a3,ffffffffc02015f4 <default_free_pages+0x34>
ffffffffc02015d4:	6798                	ld	a4,8(a5)
ffffffffc02015d6:	8b05                	andi	a4,a4,1
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02015d8:	10071a63          	bnez	a4,ffffffffc02016ec <default_free_pages+0x12c>
ffffffffc02015dc:	6798                	ld	a4,8(a5)
ffffffffc02015de:	8b09                	andi	a4,a4,2
ffffffffc02015e0:	10071663          	bnez	a4,ffffffffc02016ec <default_free_pages+0x12c>
        p->flags = 0;
ffffffffc02015e4:	0007b423          	sd	zero,8(a5)
    return page->ref;
}

static inline void
set_page_ref(struct Page *page, int val) {
    page->ref = val;
ffffffffc02015e8:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02015ec:	04078793          	addi	a5,a5,64
ffffffffc02015f0:	fed792e3          	bne	a5,a3,ffffffffc02015d4 <default_free_pages+0x14>
    base->property = n;
ffffffffc02015f4:	2581                	sext.w	a1,a1
ffffffffc02015f6:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc02015f8:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02015fc:	4789                	li	a5,2
ffffffffc02015fe:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0201602:	000ad697          	auipc	a3,0xad
ffffffffc0201606:	16e68693          	addi	a3,a3,366 # ffffffffc02ae770 <free_area>
ffffffffc020160a:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc020160c:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc020160e:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0201612:	9db9                	addw	a1,a1,a4
ffffffffc0201614:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0201616:	0ad78463          	beq	a5,a3,ffffffffc02016be <default_free_pages+0xfe>
            struct Page* page = le2page(le, page_link);
ffffffffc020161a:	fe878713          	addi	a4,a5,-24
ffffffffc020161e:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0201622:	4581                	li	a1,0
            if (base < page) {
ffffffffc0201624:	00e56a63          	bltu	a0,a4,ffffffffc0201638 <default_free_pages+0x78>
    return listelm->next;
ffffffffc0201628:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc020162a:	04d70c63          	beq	a4,a3,ffffffffc0201682 <default_free_pages+0xc2>
    for (; p != base + n; p ++) {
ffffffffc020162e:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201630:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0201634:	fee57ae3          	bgeu	a0,a4,ffffffffc0201628 <default_free_pages+0x68>
ffffffffc0201638:	c199                	beqz	a1,ffffffffc020163e <default_free_pages+0x7e>
ffffffffc020163a:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc020163e:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0201640:	e390                	sd	a2,0(a5)
ffffffffc0201642:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201644:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201646:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc0201648:	00d70d63          	beq	a4,a3,ffffffffc0201662 <default_free_pages+0xa2>
        if (p + p->property == base) {
ffffffffc020164c:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc0201650:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base) {
ffffffffc0201654:	02059813          	slli	a6,a1,0x20
ffffffffc0201658:	01a85793          	srli	a5,a6,0x1a
ffffffffc020165c:	97b2                	add	a5,a5,a2
ffffffffc020165e:	02f50c63          	beq	a0,a5,ffffffffc0201696 <default_free_pages+0xd6>
    return listelm->next;
ffffffffc0201662:	711c                	ld	a5,32(a0)
    if (le != &free_list) {
ffffffffc0201664:	00d78c63          	beq	a5,a3,ffffffffc020167c <default_free_pages+0xbc>
        if (base + base->property == p) {
ffffffffc0201668:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc020166a:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p) {
ffffffffc020166e:	02061593          	slli	a1,a2,0x20
ffffffffc0201672:	01a5d713          	srli	a4,a1,0x1a
ffffffffc0201676:	972a                	add	a4,a4,a0
ffffffffc0201678:	04e68a63          	beq	a3,a4,ffffffffc02016cc <default_free_pages+0x10c>
}
ffffffffc020167c:	60a2                	ld	ra,8(sp)
ffffffffc020167e:	0141                	addi	sp,sp,16
ffffffffc0201680:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201682:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201684:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201686:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201688:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc020168a:	02d70763          	beq	a4,a3,ffffffffc02016b8 <default_free_pages+0xf8>
    prev->next = next->prev = elm;
ffffffffc020168e:	8832                	mv	a6,a2
ffffffffc0201690:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc0201692:	87ba                	mv	a5,a4
ffffffffc0201694:	bf71                	j	ffffffffc0201630 <default_free_pages+0x70>
            p->property += base->property;
ffffffffc0201696:	491c                	lw	a5,16(a0)
ffffffffc0201698:	9dbd                	addw	a1,a1,a5
ffffffffc020169a:	feb72c23          	sw	a1,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020169e:	57f5                	li	a5,-3
ffffffffc02016a0:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc02016a4:	01853803          	ld	a6,24(a0)
ffffffffc02016a8:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc02016aa:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc02016ac:	00b83423          	sd	a1,8(a6)
    return listelm->next;
ffffffffc02016b0:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc02016b2:	0105b023          	sd	a6,0(a1)
ffffffffc02016b6:	b77d                	j	ffffffffc0201664 <default_free_pages+0xa4>
ffffffffc02016b8:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list) {
ffffffffc02016ba:	873e                	mv	a4,a5
ffffffffc02016bc:	bf41                	j	ffffffffc020164c <default_free_pages+0x8c>
}
ffffffffc02016be:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02016c0:	e390                	sd	a2,0(a5)
ffffffffc02016c2:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02016c4:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02016c6:	ed1c                	sd	a5,24(a0)
ffffffffc02016c8:	0141                	addi	sp,sp,16
ffffffffc02016ca:	8082                	ret
            base->property += p->property;
ffffffffc02016cc:	ff87a703          	lw	a4,-8(a5)
ffffffffc02016d0:	ff078693          	addi	a3,a5,-16
ffffffffc02016d4:	9e39                	addw	a2,a2,a4
ffffffffc02016d6:	c910                	sw	a2,16(a0)
ffffffffc02016d8:	5775                	li	a4,-3
ffffffffc02016da:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02016de:	6398                	ld	a4,0(a5)
ffffffffc02016e0:	679c                	ld	a5,8(a5)
}
ffffffffc02016e2:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc02016e4:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02016e6:	e398                	sd	a4,0(a5)
ffffffffc02016e8:	0141                	addi	sp,sp,16
ffffffffc02016ea:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02016ec:	00006697          	auipc	a3,0x6
ffffffffc02016f0:	aec68693          	addi	a3,a3,-1300 # ffffffffc02071d8 <commands+0xa98>
ffffffffc02016f4:	00005617          	auipc	a2,0x5
ffffffffc02016f8:	49c60613          	addi	a2,a2,1180 # ffffffffc0206b90 <commands+0x450>
ffffffffc02016fc:	08300593          	li	a1,131
ffffffffc0201700:	00005517          	auipc	a0,0x5
ffffffffc0201704:	79050513          	addi	a0,a0,1936 # ffffffffc0206e90 <commands+0x750>
ffffffffc0201708:	d73fe0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(n > 0);
ffffffffc020170c:	00006697          	auipc	a3,0x6
ffffffffc0201710:	ac468693          	addi	a3,a3,-1340 # ffffffffc02071d0 <commands+0xa90>
ffffffffc0201714:	00005617          	auipc	a2,0x5
ffffffffc0201718:	47c60613          	addi	a2,a2,1148 # ffffffffc0206b90 <commands+0x450>
ffffffffc020171c:	08000593          	li	a1,128
ffffffffc0201720:	00005517          	auipc	a0,0x5
ffffffffc0201724:	77050513          	addi	a0,a0,1904 # ffffffffc0206e90 <commands+0x750>
ffffffffc0201728:	d53fe0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc020172c <default_alloc_pages>:
    assert(n > 0);
ffffffffc020172c:	c941                	beqz	a0,ffffffffc02017bc <default_alloc_pages+0x90>
    if (n > nr_free) {
ffffffffc020172e:	000ad597          	auipc	a1,0xad
ffffffffc0201732:	04258593          	addi	a1,a1,66 # ffffffffc02ae770 <free_area>
ffffffffc0201736:	0105a803          	lw	a6,16(a1)
ffffffffc020173a:	872a                	mv	a4,a0
ffffffffc020173c:	02081793          	slli	a5,a6,0x20
ffffffffc0201740:	9381                	srli	a5,a5,0x20
ffffffffc0201742:	00a7ee63          	bltu	a5,a0,ffffffffc020175e <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc0201746:	87ae                	mv	a5,a1
ffffffffc0201748:	a801                	j	ffffffffc0201758 <default_alloc_pages+0x2c>
        if (p->property >= n) {
ffffffffc020174a:	ff87a683          	lw	a3,-8(a5)
ffffffffc020174e:	02069613          	slli	a2,a3,0x20
ffffffffc0201752:	9201                	srli	a2,a2,0x20
ffffffffc0201754:	00e67763          	bgeu	a2,a4,ffffffffc0201762 <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc0201758:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc020175a:	feb798e3          	bne	a5,a1,ffffffffc020174a <default_alloc_pages+0x1e>
        return NULL;
ffffffffc020175e:	4501                	li	a0,0
}
ffffffffc0201760:	8082                	ret
    return listelm->prev;
ffffffffc0201762:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201766:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc020176a:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc020176e:	00070e1b          	sext.w	t3,a4
    prev->next = next;
ffffffffc0201772:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc0201776:	01133023          	sd	a7,0(t1)
        if (page->property > n) {
ffffffffc020177a:	02c77863          	bgeu	a4,a2,ffffffffc02017aa <default_alloc_pages+0x7e>
            struct Page *p = page + n;
ffffffffc020177e:	071a                	slli	a4,a4,0x6
ffffffffc0201780:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc0201782:	41c686bb          	subw	a3,a3,t3
ffffffffc0201786:	cb14                	sw	a3,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201788:	00870613          	addi	a2,a4,8
ffffffffc020178c:	4689                	li	a3,2
ffffffffc020178e:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc0201792:	0088b683          	ld	a3,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc0201796:	01870613          	addi	a2,a4,24
        nr_free -= n;
ffffffffc020179a:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc020179e:	e290                	sd	a2,0(a3)
ffffffffc02017a0:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc02017a4:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc02017a6:	01173c23          	sd	a7,24(a4)
ffffffffc02017aa:	41c8083b          	subw	a6,a6,t3
ffffffffc02017ae:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02017b2:	5775                	li	a4,-3
ffffffffc02017b4:	17c1                	addi	a5,a5,-16
ffffffffc02017b6:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc02017ba:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc02017bc:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc02017be:	00006697          	auipc	a3,0x6
ffffffffc02017c2:	a1268693          	addi	a3,a3,-1518 # ffffffffc02071d0 <commands+0xa90>
ffffffffc02017c6:	00005617          	auipc	a2,0x5
ffffffffc02017ca:	3ca60613          	addi	a2,a2,970 # ffffffffc0206b90 <commands+0x450>
ffffffffc02017ce:	06200593          	li	a1,98
ffffffffc02017d2:	00005517          	auipc	a0,0x5
ffffffffc02017d6:	6be50513          	addi	a0,a0,1726 # ffffffffc0206e90 <commands+0x750>
default_alloc_pages(size_t n) {
ffffffffc02017da:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02017dc:	c9ffe0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc02017e0 <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc02017e0:	1141                	addi	sp,sp,-16
ffffffffc02017e2:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02017e4:	c5f1                	beqz	a1,ffffffffc02018b0 <default_init_memmap+0xd0>
    for (; p != base + n; p ++) {
ffffffffc02017e6:	00659693          	slli	a3,a1,0x6
ffffffffc02017ea:	96aa                	add	a3,a3,a0
ffffffffc02017ec:	87aa                	mv	a5,a0
ffffffffc02017ee:	00d50f63          	beq	a0,a3,ffffffffc020180c <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02017f2:	6798                	ld	a4,8(a5)
ffffffffc02017f4:	8b05                	andi	a4,a4,1
        assert(PageReserved(p));
ffffffffc02017f6:	cf49                	beqz	a4,ffffffffc0201890 <default_init_memmap+0xb0>
        p->flags = p->property = 0;
ffffffffc02017f8:	0007a823          	sw	zero,16(a5)
ffffffffc02017fc:	0007b423          	sd	zero,8(a5)
ffffffffc0201800:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201804:	04078793          	addi	a5,a5,64
ffffffffc0201808:	fed795e3          	bne	a5,a3,ffffffffc02017f2 <default_init_memmap+0x12>
    base->property = n;
ffffffffc020180c:	2581                	sext.w	a1,a1
ffffffffc020180e:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201810:	4789                	li	a5,2
ffffffffc0201812:	00850713          	addi	a4,a0,8
ffffffffc0201816:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc020181a:	000ad697          	auipc	a3,0xad
ffffffffc020181e:	f5668693          	addi	a3,a3,-170 # ffffffffc02ae770 <free_area>
ffffffffc0201822:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201824:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0201826:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc020182a:	9db9                	addw	a1,a1,a4
ffffffffc020182c:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc020182e:	04d78a63          	beq	a5,a3,ffffffffc0201882 <default_init_memmap+0xa2>
            struct Page* page = le2page(le, page_link);
ffffffffc0201832:	fe878713          	addi	a4,a5,-24
ffffffffc0201836:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc020183a:	4581                	li	a1,0
            if (base < page) {
ffffffffc020183c:	00e56a63          	bltu	a0,a4,ffffffffc0201850 <default_init_memmap+0x70>
    return listelm->next;
ffffffffc0201840:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0201842:	02d70263          	beq	a4,a3,ffffffffc0201866 <default_init_memmap+0x86>
    for (; p != base + n; p ++) {
ffffffffc0201846:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201848:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc020184c:	fee57ae3          	bgeu	a0,a4,ffffffffc0201840 <default_init_memmap+0x60>
ffffffffc0201850:	c199                	beqz	a1,ffffffffc0201856 <default_init_memmap+0x76>
ffffffffc0201852:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201856:	6398                	ld	a4,0(a5)
}
ffffffffc0201858:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc020185a:	e390                	sd	a2,0(a5)
ffffffffc020185c:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc020185e:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201860:	ed18                	sd	a4,24(a0)
ffffffffc0201862:	0141                	addi	sp,sp,16
ffffffffc0201864:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201866:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201868:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc020186a:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020186c:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc020186e:	00d70663          	beq	a4,a3,ffffffffc020187a <default_init_memmap+0x9a>
    prev->next = next->prev = elm;
ffffffffc0201872:	8832                	mv	a6,a2
ffffffffc0201874:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc0201876:	87ba                	mv	a5,a4
ffffffffc0201878:	bfc1                	j	ffffffffc0201848 <default_init_memmap+0x68>
}
ffffffffc020187a:	60a2                	ld	ra,8(sp)
ffffffffc020187c:	e290                	sd	a2,0(a3)
ffffffffc020187e:	0141                	addi	sp,sp,16
ffffffffc0201880:	8082                	ret
ffffffffc0201882:	60a2                	ld	ra,8(sp)
ffffffffc0201884:	e390                	sd	a2,0(a5)
ffffffffc0201886:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201888:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020188a:	ed1c                	sd	a5,24(a0)
ffffffffc020188c:	0141                	addi	sp,sp,16
ffffffffc020188e:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201890:	00006697          	auipc	a3,0x6
ffffffffc0201894:	97068693          	addi	a3,a3,-1680 # ffffffffc0207200 <commands+0xac0>
ffffffffc0201898:	00005617          	auipc	a2,0x5
ffffffffc020189c:	2f860613          	addi	a2,a2,760 # ffffffffc0206b90 <commands+0x450>
ffffffffc02018a0:	04900593          	li	a1,73
ffffffffc02018a4:	00005517          	auipc	a0,0x5
ffffffffc02018a8:	5ec50513          	addi	a0,a0,1516 # ffffffffc0206e90 <commands+0x750>
ffffffffc02018ac:	bcffe0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(n > 0);
ffffffffc02018b0:	00006697          	auipc	a3,0x6
ffffffffc02018b4:	92068693          	addi	a3,a3,-1760 # ffffffffc02071d0 <commands+0xa90>
ffffffffc02018b8:	00005617          	auipc	a2,0x5
ffffffffc02018bc:	2d860613          	addi	a2,a2,728 # ffffffffc0206b90 <commands+0x450>
ffffffffc02018c0:	04600593          	li	a1,70
ffffffffc02018c4:	00005517          	auipc	a0,0x5
ffffffffc02018c8:	5cc50513          	addi	a0,a0,1484 # ffffffffc0206e90 <commands+0x750>
ffffffffc02018cc:	baffe0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc02018d0 <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc02018d0:	c94d                	beqz	a0,ffffffffc0201982 <slob_free+0xb2>
{
ffffffffc02018d2:	1141                	addi	sp,sp,-16
ffffffffc02018d4:	e022                	sd	s0,0(sp)
ffffffffc02018d6:	e406                	sd	ra,8(sp)
ffffffffc02018d8:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc02018da:	e9c1                	bnez	a1,ffffffffc020196a <slob_free+0x9a>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02018dc:	100027f3          	csrr	a5,sstatus
ffffffffc02018e0:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02018e2:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02018e4:	ebd9                	bnez	a5,ffffffffc020197a <slob_free+0xaa>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02018e6:	000a6617          	auipc	a2,0xa6
ffffffffc02018ea:	a7a60613          	addi	a2,a2,-1414 # ffffffffc02a7360 <slobfree>
ffffffffc02018ee:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02018f0:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02018f2:	679c                	ld	a5,8(a5)
ffffffffc02018f4:	02877a63          	bgeu	a4,s0,ffffffffc0201928 <slob_free+0x58>
ffffffffc02018f8:	00f46463          	bltu	s0,a5,ffffffffc0201900 <slob_free+0x30>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02018fc:	fef76ae3          	bltu	a4,a5,ffffffffc02018f0 <slob_free+0x20>
			break;

	if (b + b->units == cur->next) {
ffffffffc0201900:	400c                	lw	a1,0(s0)
ffffffffc0201902:	00459693          	slli	a3,a1,0x4
ffffffffc0201906:	96a2                	add	a3,a3,s0
ffffffffc0201908:	02d78a63          	beq	a5,a3,ffffffffc020193c <slob_free+0x6c>
		b->units += cur->next->units;
		b->next = cur->next->next;
	} else
		b->next = cur->next;

	if (cur + cur->units == b) {
ffffffffc020190c:	4314                	lw	a3,0(a4)
		b->next = cur->next;
ffffffffc020190e:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b) {
ffffffffc0201910:	00469793          	slli	a5,a3,0x4
ffffffffc0201914:	97ba                	add	a5,a5,a4
ffffffffc0201916:	02f40e63          	beq	s0,a5,ffffffffc0201952 <slob_free+0x82>
		cur->units += b->units;
		cur->next = b->next;
	} else
		cur->next = b;
ffffffffc020191a:	e700                	sd	s0,8(a4)

	slobfree = cur;
ffffffffc020191c:	e218                	sd	a4,0(a2)
    if (flag) {
ffffffffc020191e:	e129                	bnez	a0,ffffffffc0201960 <slob_free+0x90>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0201920:	60a2                	ld	ra,8(sp)
ffffffffc0201922:	6402                	ld	s0,0(sp)
ffffffffc0201924:	0141                	addi	sp,sp,16
ffffffffc0201926:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201928:	fcf764e3          	bltu	a4,a5,ffffffffc02018f0 <slob_free+0x20>
ffffffffc020192c:	fcf472e3          	bgeu	s0,a5,ffffffffc02018f0 <slob_free+0x20>
	if (b + b->units == cur->next) {
ffffffffc0201930:	400c                	lw	a1,0(s0)
ffffffffc0201932:	00459693          	slli	a3,a1,0x4
ffffffffc0201936:	96a2                	add	a3,a3,s0
ffffffffc0201938:	fcd79ae3          	bne	a5,a3,ffffffffc020190c <slob_free+0x3c>
		b->units += cur->next->units;
ffffffffc020193c:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc020193e:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201940:	9db5                	addw	a1,a1,a3
ffffffffc0201942:	c00c                	sw	a1,0(s0)
	if (cur + cur->units == b) {
ffffffffc0201944:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc0201946:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b) {
ffffffffc0201948:	00469793          	slli	a5,a3,0x4
ffffffffc020194c:	97ba                	add	a5,a5,a4
ffffffffc020194e:	fcf416e3          	bne	s0,a5,ffffffffc020191a <slob_free+0x4a>
		cur->units += b->units;
ffffffffc0201952:	401c                	lw	a5,0(s0)
		cur->next = b->next;
ffffffffc0201954:	640c                	ld	a1,8(s0)
	slobfree = cur;
ffffffffc0201956:	e218                	sd	a4,0(a2)
		cur->units += b->units;
ffffffffc0201958:	9ebd                	addw	a3,a3,a5
ffffffffc020195a:	c314                	sw	a3,0(a4)
		cur->next = b->next;
ffffffffc020195c:	e70c                	sd	a1,8(a4)
ffffffffc020195e:	d169                	beqz	a0,ffffffffc0201920 <slob_free+0x50>
}
ffffffffc0201960:	6402                	ld	s0,0(sp)
ffffffffc0201962:	60a2                	ld	ra,8(sp)
ffffffffc0201964:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0201966:	cdbfe06f          	j	ffffffffc0200640 <intr_enable>
		b->units = SLOB_UNITS(size);
ffffffffc020196a:	25bd                	addiw	a1,a1,15
ffffffffc020196c:	8191                	srli	a1,a1,0x4
ffffffffc020196e:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201970:	100027f3          	csrr	a5,sstatus
ffffffffc0201974:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201976:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201978:	d7bd                	beqz	a5,ffffffffc02018e6 <slob_free+0x16>
        intr_disable();
ffffffffc020197a:	ccdfe0ef          	jal	ra,ffffffffc0200646 <intr_disable>
        return 1;
ffffffffc020197e:	4505                	li	a0,1
ffffffffc0201980:	b79d                	j	ffffffffc02018e6 <slob_free+0x16>
ffffffffc0201982:	8082                	ret

ffffffffc0201984 <__slob_get_free_pages.constprop.0>:
  struct Page * page = alloc_pages(1 << order);
ffffffffc0201984:	4785                	li	a5,1
static void* __slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201986:	1141                	addi	sp,sp,-16
  struct Page * page = alloc_pages(1 << order);
ffffffffc0201988:	00a7953b          	sllw	a0,a5,a0
static void* __slob_get_free_pages(gfp_t gfp, int order)
ffffffffc020198c:	e406                	sd	ra,8(sp)
  struct Page * page = alloc_pages(1 << order);
ffffffffc020198e:	352000ef          	jal	ra,ffffffffc0201ce0 <alloc_pages>
  if(!page)
ffffffffc0201992:	c91d                	beqz	a0,ffffffffc02019c8 <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0201994:	000b1697          	auipc	a3,0xb1
ffffffffc0201998:	edc6b683          	ld	a3,-292(a3) # ffffffffc02b2870 <pages>
ffffffffc020199c:	8d15                	sub	a0,a0,a3
ffffffffc020199e:	8519                	srai	a0,a0,0x6
ffffffffc02019a0:	00007697          	auipc	a3,0x7
ffffffffc02019a4:	1d06b683          	ld	a3,464(a3) # ffffffffc0208b70 <nbase>
ffffffffc02019a8:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc02019aa:	00c51793          	slli	a5,a0,0xc
ffffffffc02019ae:	83b1                	srli	a5,a5,0xc
ffffffffc02019b0:	000b1717          	auipc	a4,0xb1
ffffffffc02019b4:	eb873703          	ld	a4,-328(a4) # ffffffffc02b2868 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc02019b8:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc02019ba:	00e7fa63          	bgeu	a5,a4,ffffffffc02019ce <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc02019be:	000b1697          	auipc	a3,0xb1
ffffffffc02019c2:	ec26b683          	ld	a3,-318(a3) # ffffffffc02b2880 <va_pa_offset>
ffffffffc02019c6:	9536                	add	a0,a0,a3
}
ffffffffc02019c8:	60a2                	ld	ra,8(sp)
ffffffffc02019ca:	0141                	addi	sp,sp,16
ffffffffc02019cc:	8082                	ret
ffffffffc02019ce:	86aa                	mv	a3,a0
ffffffffc02019d0:	00006617          	auipc	a2,0x6
ffffffffc02019d4:	89060613          	addi	a2,a2,-1904 # ffffffffc0207260 <default_pmm_manager+0x38>
ffffffffc02019d8:	06900593          	li	a1,105
ffffffffc02019dc:	00006517          	auipc	a0,0x6
ffffffffc02019e0:	8ac50513          	addi	a0,a0,-1876 # ffffffffc0207288 <default_pmm_manager+0x60>
ffffffffc02019e4:	a97fe0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc02019e8 <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc02019e8:	1101                	addi	sp,sp,-32
ffffffffc02019ea:	ec06                	sd	ra,24(sp)
ffffffffc02019ec:	e822                	sd	s0,16(sp)
ffffffffc02019ee:	e426                	sd	s1,8(sp)
ffffffffc02019f0:	e04a                	sd	s2,0(sp)
  assert( (size + SLOB_UNIT) < PAGE_SIZE );
ffffffffc02019f2:	01050713          	addi	a4,a0,16
ffffffffc02019f6:	6785                	lui	a5,0x1
ffffffffc02019f8:	0cf77363          	bgeu	a4,a5,ffffffffc0201abe <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc02019fc:	00f50493          	addi	s1,a0,15
ffffffffc0201a00:	8091                	srli	s1,s1,0x4
ffffffffc0201a02:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201a04:	10002673          	csrr	a2,sstatus
ffffffffc0201a08:	8a09                	andi	a2,a2,2
ffffffffc0201a0a:	e25d                	bnez	a2,ffffffffc0201ab0 <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc0201a0c:	000a6917          	auipc	s2,0xa6
ffffffffc0201a10:	95490913          	addi	s2,s2,-1708 # ffffffffc02a7360 <slobfree>
ffffffffc0201a14:	00093683          	ld	a3,0(s2)
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc0201a18:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc0201a1a:	4398                	lw	a4,0(a5)
ffffffffc0201a1c:	08975e63          	bge	a4,s1,ffffffffc0201ab8 <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree) {
ffffffffc0201a20:	00f68b63          	beq	a3,a5,ffffffffc0201a36 <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc0201a24:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc0201a26:	4018                	lw	a4,0(s0)
ffffffffc0201a28:	02975a63          	bge	a4,s1,ffffffffc0201a5c <slob_alloc.constprop.0+0x74>
		if (cur == slobfree) {
ffffffffc0201a2c:	00093683          	ld	a3,0(s2)
ffffffffc0201a30:	87a2                	mv	a5,s0
ffffffffc0201a32:	fef699e3          	bne	a3,a5,ffffffffc0201a24 <slob_alloc.constprop.0+0x3c>
    if (flag) {
ffffffffc0201a36:	ee31                	bnez	a2,ffffffffc0201a92 <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201a38:	4501                	li	a0,0
ffffffffc0201a3a:	f4bff0ef          	jal	ra,ffffffffc0201984 <__slob_get_free_pages.constprop.0>
ffffffffc0201a3e:	842a                	mv	s0,a0
			if (!cur)
ffffffffc0201a40:	cd05                	beqz	a0,ffffffffc0201a78 <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201a42:	6585                	lui	a1,0x1
ffffffffc0201a44:	e8dff0ef          	jal	ra,ffffffffc02018d0 <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201a48:	10002673          	csrr	a2,sstatus
ffffffffc0201a4c:	8a09                	andi	a2,a2,2
ffffffffc0201a4e:	ee05                	bnez	a2,ffffffffc0201a86 <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc0201a50:	00093783          	ld	a5,0(s2)
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc0201a54:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc0201a56:	4018                	lw	a4,0(s0)
ffffffffc0201a58:	fc974ae3          	blt	a4,s1,ffffffffc0201a2c <slob_alloc.constprop.0+0x44>
			if (cur->units == units) /* exact fit? */
ffffffffc0201a5c:	04e48763          	beq	s1,a4,ffffffffc0201aaa <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc0201a60:	00449693          	slli	a3,s1,0x4
ffffffffc0201a64:	96a2                	add	a3,a3,s0
ffffffffc0201a66:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc0201a68:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc0201a6a:	9f05                	subw	a4,a4,s1
ffffffffc0201a6c:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc0201a6e:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc0201a70:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc0201a72:	00f93023          	sd	a5,0(s2)
    if (flag) {
ffffffffc0201a76:	e20d                	bnez	a2,ffffffffc0201a98 <slob_alloc.constprop.0+0xb0>
}
ffffffffc0201a78:	60e2                	ld	ra,24(sp)
ffffffffc0201a7a:	8522                	mv	a0,s0
ffffffffc0201a7c:	6442                	ld	s0,16(sp)
ffffffffc0201a7e:	64a2                	ld	s1,8(sp)
ffffffffc0201a80:	6902                	ld	s2,0(sp)
ffffffffc0201a82:	6105                	addi	sp,sp,32
ffffffffc0201a84:	8082                	ret
        intr_disable();
ffffffffc0201a86:	bc1fe0ef          	jal	ra,ffffffffc0200646 <intr_disable>
			cur = slobfree;
ffffffffc0201a8a:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc0201a8e:	4605                	li	a2,1
ffffffffc0201a90:	b7d1                	j	ffffffffc0201a54 <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc0201a92:	baffe0ef          	jal	ra,ffffffffc0200640 <intr_enable>
ffffffffc0201a96:	b74d                	j	ffffffffc0201a38 <slob_alloc.constprop.0+0x50>
ffffffffc0201a98:	ba9fe0ef          	jal	ra,ffffffffc0200640 <intr_enable>
}
ffffffffc0201a9c:	60e2                	ld	ra,24(sp)
ffffffffc0201a9e:	8522                	mv	a0,s0
ffffffffc0201aa0:	6442                	ld	s0,16(sp)
ffffffffc0201aa2:	64a2                	ld	s1,8(sp)
ffffffffc0201aa4:	6902                	ld	s2,0(sp)
ffffffffc0201aa6:	6105                	addi	sp,sp,32
ffffffffc0201aa8:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201aaa:	6418                	ld	a4,8(s0)
ffffffffc0201aac:	e798                	sd	a4,8(a5)
ffffffffc0201aae:	b7d1                	j	ffffffffc0201a72 <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc0201ab0:	b97fe0ef          	jal	ra,ffffffffc0200646 <intr_disable>
        return 1;
ffffffffc0201ab4:	4605                	li	a2,1
ffffffffc0201ab6:	bf99                	j	ffffffffc0201a0c <slob_alloc.constprop.0+0x24>
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc0201ab8:	843e                	mv	s0,a5
ffffffffc0201aba:	87b6                	mv	a5,a3
ffffffffc0201abc:	b745                	j	ffffffffc0201a5c <slob_alloc.constprop.0+0x74>
  assert( (size + SLOB_UNIT) < PAGE_SIZE );
ffffffffc0201abe:	00005697          	auipc	a3,0x5
ffffffffc0201ac2:	7da68693          	addi	a3,a3,2010 # ffffffffc0207298 <default_pmm_manager+0x70>
ffffffffc0201ac6:	00005617          	auipc	a2,0x5
ffffffffc0201aca:	0ca60613          	addi	a2,a2,202 # ffffffffc0206b90 <commands+0x450>
ffffffffc0201ace:	06400593          	li	a1,100
ffffffffc0201ad2:	00005517          	auipc	a0,0x5
ffffffffc0201ad6:	7e650513          	addi	a0,a0,2022 # ffffffffc02072b8 <default_pmm_manager+0x90>
ffffffffc0201ada:	9a1fe0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0201ade <kmalloc_init>:
slob_init(void) {
  cprintf("use SLOB allocator\n");
}

inline void 
kmalloc_init(void) {
ffffffffc0201ade:	1141                	addi	sp,sp,-16
  cprintf("use SLOB allocator\n");
ffffffffc0201ae0:	00005517          	auipc	a0,0x5
ffffffffc0201ae4:	7f050513          	addi	a0,a0,2032 # ffffffffc02072d0 <default_pmm_manager+0xa8>
kmalloc_init(void) {
ffffffffc0201ae8:	e406                	sd	ra,8(sp)
  cprintf("use SLOB allocator\n");
ffffffffc0201aea:	e96fe0ef          	jal	ra,ffffffffc0200180 <cprintf>
    slob_init();
    cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201aee:	60a2                	ld	ra,8(sp)
    cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201af0:	00005517          	auipc	a0,0x5
ffffffffc0201af4:	7f850513          	addi	a0,a0,2040 # ffffffffc02072e8 <default_pmm_manager+0xc0>
}
ffffffffc0201af8:	0141                	addi	sp,sp,16
    cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201afa:	e86fe06f          	j	ffffffffc0200180 <cprintf>

ffffffffc0201afe <kallocated>:
}

size_t
kallocated(void) {
   return slob_allocated();
}
ffffffffc0201afe:	4501                	li	a0,0
ffffffffc0201b00:	8082                	ret

ffffffffc0201b02 <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201b02:	1101                	addi	sp,sp,-32
ffffffffc0201b04:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc0201b06:	6905                	lui	s2,0x1
{
ffffffffc0201b08:	e822                	sd	s0,16(sp)
ffffffffc0201b0a:	ec06                	sd	ra,24(sp)
ffffffffc0201b0c:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc0201b0e:	fef90793          	addi	a5,s2,-17 # fef <_binary_obj___user_faultread_out_size-0x8bc9>
{
ffffffffc0201b12:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc0201b14:	04a7f963          	bgeu	a5,a0,ffffffffc0201b66 <kmalloc+0x64>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201b18:	4561                	li	a0,24
ffffffffc0201b1a:	ecfff0ef          	jal	ra,ffffffffc02019e8 <slob_alloc.constprop.0>
ffffffffc0201b1e:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0201b20:	c929                	beqz	a0,ffffffffc0201b72 <kmalloc+0x70>
	bb->order = find_order(size);
ffffffffc0201b22:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc0201b26:	4501                	li	a0,0
	for ( ; size > 4096 ; size >>=1)
ffffffffc0201b28:	00f95763          	bge	s2,a5,ffffffffc0201b36 <kmalloc+0x34>
ffffffffc0201b2c:	6705                	lui	a4,0x1
ffffffffc0201b2e:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc0201b30:	2505                	addiw	a0,a0,1
	for ( ; size > 4096 ; size >>=1)
ffffffffc0201b32:	fef74ee3          	blt	a4,a5,ffffffffc0201b2e <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc0201b36:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201b38:	e4dff0ef          	jal	ra,ffffffffc0201984 <__slob_get_free_pages.constprop.0>
ffffffffc0201b3c:	e488                	sd	a0,8(s1)
ffffffffc0201b3e:	842a                	mv	s0,a0
	if (bb->pages) {
ffffffffc0201b40:	c525                	beqz	a0,ffffffffc0201ba8 <kmalloc+0xa6>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201b42:	100027f3          	csrr	a5,sstatus
ffffffffc0201b46:	8b89                	andi	a5,a5,2
ffffffffc0201b48:	ef8d                	bnez	a5,ffffffffc0201b82 <kmalloc+0x80>
		bb->next = bigblocks;
ffffffffc0201b4a:	000b1797          	auipc	a5,0xb1
ffffffffc0201b4e:	d0678793          	addi	a5,a5,-762 # ffffffffc02b2850 <bigblocks>
ffffffffc0201b52:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201b54:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201b56:	e898                	sd	a4,16(s1)
  return __kmalloc(size, 0);
}
ffffffffc0201b58:	60e2                	ld	ra,24(sp)
ffffffffc0201b5a:	8522                	mv	a0,s0
ffffffffc0201b5c:	6442                	ld	s0,16(sp)
ffffffffc0201b5e:	64a2                	ld	s1,8(sp)
ffffffffc0201b60:	6902                	ld	s2,0(sp)
ffffffffc0201b62:	6105                	addi	sp,sp,32
ffffffffc0201b64:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201b66:	0541                	addi	a0,a0,16
ffffffffc0201b68:	e81ff0ef          	jal	ra,ffffffffc02019e8 <slob_alloc.constprop.0>
		return m ? (void *)(m + 1) : 0;
ffffffffc0201b6c:	01050413          	addi	s0,a0,16
ffffffffc0201b70:	f565                	bnez	a0,ffffffffc0201b58 <kmalloc+0x56>
ffffffffc0201b72:	4401                	li	s0,0
}
ffffffffc0201b74:	60e2                	ld	ra,24(sp)
ffffffffc0201b76:	8522                	mv	a0,s0
ffffffffc0201b78:	6442                	ld	s0,16(sp)
ffffffffc0201b7a:	64a2                	ld	s1,8(sp)
ffffffffc0201b7c:	6902                	ld	s2,0(sp)
ffffffffc0201b7e:	6105                	addi	sp,sp,32
ffffffffc0201b80:	8082                	ret
        intr_disable();
ffffffffc0201b82:	ac5fe0ef          	jal	ra,ffffffffc0200646 <intr_disable>
		bb->next = bigblocks;
ffffffffc0201b86:	000b1797          	auipc	a5,0xb1
ffffffffc0201b8a:	cca78793          	addi	a5,a5,-822 # ffffffffc02b2850 <bigblocks>
ffffffffc0201b8e:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201b90:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201b92:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc0201b94:	aadfe0ef          	jal	ra,ffffffffc0200640 <intr_enable>
		return bb->pages;
ffffffffc0201b98:	6480                	ld	s0,8(s1)
}
ffffffffc0201b9a:	60e2                	ld	ra,24(sp)
ffffffffc0201b9c:	64a2                	ld	s1,8(sp)
ffffffffc0201b9e:	8522                	mv	a0,s0
ffffffffc0201ba0:	6442                	ld	s0,16(sp)
ffffffffc0201ba2:	6902                	ld	s2,0(sp)
ffffffffc0201ba4:	6105                	addi	sp,sp,32
ffffffffc0201ba6:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201ba8:	45e1                	li	a1,24
ffffffffc0201baa:	8526                	mv	a0,s1
ffffffffc0201bac:	d25ff0ef          	jal	ra,ffffffffc02018d0 <slob_free>
  return __kmalloc(size, 0);
ffffffffc0201bb0:	b765                	j	ffffffffc0201b58 <kmalloc+0x56>

ffffffffc0201bb2 <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201bb2:	c169                	beqz	a0,ffffffffc0201c74 <kfree+0xc2>
{
ffffffffc0201bb4:	1101                	addi	sp,sp,-32
ffffffffc0201bb6:	e822                	sd	s0,16(sp)
ffffffffc0201bb8:	ec06                	sd	ra,24(sp)
ffffffffc0201bba:	e426                	sd	s1,8(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE-1))) {
ffffffffc0201bbc:	03451793          	slli	a5,a0,0x34
ffffffffc0201bc0:	842a                	mv	s0,a0
ffffffffc0201bc2:	e3d9                	bnez	a5,ffffffffc0201c48 <kfree+0x96>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201bc4:	100027f3          	csrr	a5,sstatus
ffffffffc0201bc8:	8b89                	andi	a5,a5,2
ffffffffc0201bca:	e7d9                	bnez	a5,ffffffffc0201c58 <kfree+0xa6>
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0201bcc:	000b1797          	auipc	a5,0xb1
ffffffffc0201bd0:	c847b783          	ld	a5,-892(a5) # ffffffffc02b2850 <bigblocks>
    return 0;
ffffffffc0201bd4:	4601                	li	a2,0
ffffffffc0201bd6:	cbad                	beqz	a5,ffffffffc0201c48 <kfree+0x96>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201bd8:	000b1697          	auipc	a3,0xb1
ffffffffc0201bdc:	c7868693          	addi	a3,a3,-904 # ffffffffc02b2850 <bigblocks>
ffffffffc0201be0:	a021                	j	ffffffffc0201be8 <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0201be2:	01048693          	addi	a3,s1,16
ffffffffc0201be6:	c3a5                	beqz	a5,ffffffffc0201c46 <kfree+0x94>
			if (bb->pages == block) {
ffffffffc0201be8:	6798                	ld	a4,8(a5)
ffffffffc0201bea:	84be                	mv	s1,a5
				*last = bb->next;
ffffffffc0201bec:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block) {
ffffffffc0201bee:	fe871ae3          	bne	a4,s0,ffffffffc0201be2 <kfree+0x30>
				*last = bb->next;
ffffffffc0201bf2:	e29c                	sd	a5,0(a3)
    if (flag) {
ffffffffc0201bf4:	ee2d                	bnez	a2,ffffffffc0201c6e <kfree+0xbc>
    return pa2page(PADDR(kva));
ffffffffc0201bf6:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc0201bfa:	4098                	lw	a4,0(s1)
ffffffffc0201bfc:	08f46963          	bltu	s0,a5,ffffffffc0201c8e <kfree+0xdc>
ffffffffc0201c00:	000b1697          	auipc	a3,0xb1
ffffffffc0201c04:	c806b683          	ld	a3,-896(a3) # ffffffffc02b2880 <va_pa_offset>
ffffffffc0201c08:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage) {
ffffffffc0201c0a:	8031                	srli	s0,s0,0xc
ffffffffc0201c0c:	000b1797          	auipc	a5,0xb1
ffffffffc0201c10:	c5c7b783          	ld	a5,-932(a5) # ffffffffc02b2868 <npage>
ffffffffc0201c14:	06f47163          	bgeu	s0,a5,ffffffffc0201c76 <kfree+0xc4>
    return &pages[PPN(pa) - nbase];
ffffffffc0201c18:	00007517          	auipc	a0,0x7
ffffffffc0201c1c:	f5853503          	ld	a0,-168(a0) # ffffffffc0208b70 <nbase>
ffffffffc0201c20:	8c09                	sub	s0,s0,a0
ffffffffc0201c22:	041a                	slli	s0,s0,0x6
  free_pages(kva2page(kva), 1 << order);
ffffffffc0201c24:	000b1517          	auipc	a0,0xb1
ffffffffc0201c28:	c4c53503          	ld	a0,-948(a0) # ffffffffc02b2870 <pages>
ffffffffc0201c2c:	4585                	li	a1,1
ffffffffc0201c2e:	9522                	add	a0,a0,s0
ffffffffc0201c30:	00e595bb          	sllw	a1,a1,a4
ffffffffc0201c34:	13e000ef          	jal	ra,ffffffffc0201d72 <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201c38:	6442                	ld	s0,16(sp)
ffffffffc0201c3a:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201c3c:	8526                	mv	a0,s1
}
ffffffffc0201c3e:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201c40:	45e1                	li	a1,24
}
ffffffffc0201c42:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201c44:	b171                	j	ffffffffc02018d0 <slob_free>
ffffffffc0201c46:	e20d                	bnez	a2,ffffffffc0201c68 <kfree+0xb6>
ffffffffc0201c48:	ff040513          	addi	a0,s0,-16
}
ffffffffc0201c4c:	6442                	ld	s0,16(sp)
ffffffffc0201c4e:	60e2                	ld	ra,24(sp)
ffffffffc0201c50:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201c52:	4581                	li	a1,0
}
ffffffffc0201c54:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201c56:	b9ad                	j	ffffffffc02018d0 <slob_free>
        intr_disable();
ffffffffc0201c58:	9effe0ef          	jal	ra,ffffffffc0200646 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0201c5c:	000b1797          	auipc	a5,0xb1
ffffffffc0201c60:	bf47b783          	ld	a5,-1036(a5) # ffffffffc02b2850 <bigblocks>
        return 1;
ffffffffc0201c64:	4605                	li	a2,1
ffffffffc0201c66:	fbad                	bnez	a5,ffffffffc0201bd8 <kfree+0x26>
        intr_enable();
ffffffffc0201c68:	9d9fe0ef          	jal	ra,ffffffffc0200640 <intr_enable>
ffffffffc0201c6c:	bff1                	j	ffffffffc0201c48 <kfree+0x96>
ffffffffc0201c6e:	9d3fe0ef          	jal	ra,ffffffffc0200640 <intr_enable>
ffffffffc0201c72:	b751                	j	ffffffffc0201bf6 <kfree+0x44>
ffffffffc0201c74:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201c76:	00005617          	auipc	a2,0x5
ffffffffc0201c7a:	6ba60613          	addi	a2,a2,1722 # ffffffffc0207330 <default_pmm_manager+0x108>
ffffffffc0201c7e:	06200593          	li	a1,98
ffffffffc0201c82:	00005517          	auipc	a0,0x5
ffffffffc0201c86:	60650513          	addi	a0,a0,1542 # ffffffffc0207288 <default_pmm_manager+0x60>
ffffffffc0201c8a:	ff0fe0ef          	jal	ra,ffffffffc020047a <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201c8e:	86a2                	mv	a3,s0
ffffffffc0201c90:	00005617          	auipc	a2,0x5
ffffffffc0201c94:	67860613          	addi	a2,a2,1656 # ffffffffc0207308 <default_pmm_manager+0xe0>
ffffffffc0201c98:	06e00593          	li	a1,110
ffffffffc0201c9c:	00005517          	auipc	a0,0x5
ffffffffc0201ca0:	5ec50513          	addi	a0,a0,1516 # ffffffffc0207288 <default_pmm_manager+0x60>
ffffffffc0201ca4:	fd6fe0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0201ca8 <pa2page.part.0>:
pa2page(uintptr_t pa) {
ffffffffc0201ca8:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201caa:	00005617          	auipc	a2,0x5
ffffffffc0201cae:	68660613          	addi	a2,a2,1670 # ffffffffc0207330 <default_pmm_manager+0x108>
ffffffffc0201cb2:	06200593          	li	a1,98
ffffffffc0201cb6:	00005517          	auipc	a0,0x5
ffffffffc0201cba:	5d250513          	addi	a0,a0,1490 # ffffffffc0207288 <default_pmm_manager+0x60>
pa2page(uintptr_t pa) {
ffffffffc0201cbe:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201cc0:	fbafe0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0201cc4 <pte2page.part.0>:
pte2page(pte_t pte) {
ffffffffc0201cc4:	1141                	addi	sp,sp,-16
        panic("pte2page called with invalid pte");
ffffffffc0201cc6:	00005617          	auipc	a2,0x5
ffffffffc0201cca:	68a60613          	addi	a2,a2,1674 # ffffffffc0207350 <default_pmm_manager+0x128>
ffffffffc0201cce:	07400593          	li	a1,116
ffffffffc0201cd2:	00005517          	auipc	a0,0x5
ffffffffc0201cd6:	5b650513          	addi	a0,a0,1462 # ffffffffc0207288 <default_pmm_manager+0x60>
pte2page(pte_t pte) {
ffffffffc0201cda:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0201cdc:	f9efe0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0201ce0 <alloc_pages>:
    pmm_manager->init_memmap(base, n);
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
ffffffffc0201ce0:	7139                	addi	sp,sp,-64
ffffffffc0201ce2:	f426                	sd	s1,40(sp)
ffffffffc0201ce4:	f04a                	sd	s2,32(sp)
ffffffffc0201ce6:	ec4e                	sd	s3,24(sp)
ffffffffc0201ce8:	e852                	sd	s4,16(sp)
ffffffffc0201cea:	e456                	sd	s5,8(sp)
ffffffffc0201cec:	e05a                	sd	s6,0(sp)
ffffffffc0201cee:	fc06                	sd	ra,56(sp)
ffffffffc0201cf0:	f822                	sd	s0,48(sp)
ffffffffc0201cf2:	84aa                	mv	s1,a0
ffffffffc0201cf4:	000b1917          	auipc	s2,0xb1
ffffffffc0201cf8:	b8490913          	addi	s2,s2,-1148 # ffffffffc02b2878 <pmm_manager>
        {
            page = pmm_manager->alloc_pages(n);
        }
        local_intr_restore(intr_flag);

        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0201cfc:	4a05                	li	s4,1
ffffffffc0201cfe:	000b1a97          	auipc	s5,0xb1
ffffffffc0201d02:	b9aa8a93          	addi	s5,s5,-1126 # ffffffffc02b2898 <swap_init_ok>

        extern struct mm_struct *check_mm_struct;
        // cprintf("page %x, call swap_out in alloc_pages %d\n",page, n);
        swap_out(check_mm_struct, n, 0);
ffffffffc0201d06:	0005099b          	sext.w	s3,a0
ffffffffc0201d0a:	000b1b17          	auipc	s6,0xb1
ffffffffc0201d0e:	b96b0b13          	addi	s6,s6,-1130 # ffffffffc02b28a0 <check_mm_struct>
ffffffffc0201d12:	a01d                	j	ffffffffc0201d38 <alloc_pages+0x58>
            page = pmm_manager->alloc_pages(n);
ffffffffc0201d14:	00093783          	ld	a5,0(s2)
ffffffffc0201d18:	6f9c                	ld	a5,24(a5)
ffffffffc0201d1a:	9782                	jalr	a5
ffffffffc0201d1c:	842a                	mv	s0,a0
        swap_out(check_mm_struct, n, 0);
ffffffffc0201d1e:	4601                	li	a2,0
ffffffffc0201d20:	85ce                	mv	a1,s3
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0201d22:	ec0d                	bnez	s0,ffffffffc0201d5c <alloc_pages+0x7c>
ffffffffc0201d24:	029a6c63          	bltu	s4,s1,ffffffffc0201d5c <alloc_pages+0x7c>
ffffffffc0201d28:	000aa783          	lw	a5,0(s5)
ffffffffc0201d2c:	2781                	sext.w	a5,a5
ffffffffc0201d2e:	c79d                	beqz	a5,ffffffffc0201d5c <alloc_pages+0x7c>
        swap_out(check_mm_struct, n, 0);
ffffffffc0201d30:	000b3503          	ld	a0,0(s6)
ffffffffc0201d34:	64d010ef          	jal	ra,ffffffffc0203b80 <swap_out>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201d38:	100027f3          	csrr	a5,sstatus
ffffffffc0201d3c:	8b89                	andi	a5,a5,2
            page = pmm_manager->alloc_pages(n);
ffffffffc0201d3e:	8526                	mv	a0,s1
ffffffffc0201d40:	dbf1                	beqz	a5,ffffffffc0201d14 <alloc_pages+0x34>
        intr_disable();
ffffffffc0201d42:	905fe0ef          	jal	ra,ffffffffc0200646 <intr_disable>
ffffffffc0201d46:	00093783          	ld	a5,0(s2)
ffffffffc0201d4a:	8526                	mv	a0,s1
ffffffffc0201d4c:	6f9c                	ld	a5,24(a5)
ffffffffc0201d4e:	9782                	jalr	a5
ffffffffc0201d50:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201d52:	8effe0ef          	jal	ra,ffffffffc0200640 <intr_enable>
        swap_out(check_mm_struct, n, 0);
ffffffffc0201d56:	4601                	li	a2,0
ffffffffc0201d58:	85ce                	mv	a1,s3
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0201d5a:	d469                	beqz	s0,ffffffffc0201d24 <alloc_pages+0x44>
    }
    // cprintf("n %d,get page %x, No %d in alloc_pages\n",n,page,(page-pages));
    return page;
}
ffffffffc0201d5c:	70e2                	ld	ra,56(sp)
ffffffffc0201d5e:	8522                	mv	a0,s0
ffffffffc0201d60:	7442                	ld	s0,48(sp)
ffffffffc0201d62:	74a2                	ld	s1,40(sp)
ffffffffc0201d64:	7902                	ld	s2,32(sp)
ffffffffc0201d66:	69e2                	ld	s3,24(sp)
ffffffffc0201d68:	6a42                	ld	s4,16(sp)
ffffffffc0201d6a:	6aa2                	ld	s5,8(sp)
ffffffffc0201d6c:	6b02                	ld	s6,0(sp)
ffffffffc0201d6e:	6121                	addi	sp,sp,64
ffffffffc0201d70:	8082                	ret

ffffffffc0201d72 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201d72:	100027f3          	csrr	a5,sstatus
ffffffffc0201d76:	8b89                	andi	a5,a5,2
ffffffffc0201d78:	e799                	bnez	a5,ffffffffc0201d86 <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201d7a:	000b1797          	auipc	a5,0xb1
ffffffffc0201d7e:	afe7b783          	ld	a5,-1282(a5) # ffffffffc02b2878 <pmm_manager>
ffffffffc0201d82:	739c                	ld	a5,32(a5)
ffffffffc0201d84:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc0201d86:	1101                	addi	sp,sp,-32
ffffffffc0201d88:	ec06                	sd	ra,24(sp)
ffffffffc0201d8a:	e822                	sd	s0,16(sp)
ffffffffc0201d8c:	e426                	sd	s1,8(sp)
ffffffffc0201d8e:	842a                	mv	s0,a0
ffffffffc0201d90:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201d92:	8b5fe0ef          	jal	ra,ffffffffc0200646 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201d96:	000b1797          	auipc	a5,0xb1
ffffffffc0201d9a:	ae27b783          	ld	a5,-1310(a5) # ffffffffc02b2878 <pmm_manager>
ffffffffc0201d9e:	739c                	ld	a5,32(a5)
ffffffffc0201da0:	85a6                	mv	a1,s1
ffffffffc0201da2:	8522                	mv	a0,s0
ffffffffc0201da4:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201da6:	6442                	ld	s0,16(sp)
ffffffffc0201da8:	60e2                	ld	ra,24(sp)
ffffffffc0201daa:	64a2                	ld	s1,8(sp)
ffffffffc0201dac:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201dae:	893fe06f          	j	ffffffffc0200640 <intr_enable>

ffffffffc0201db2 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201db2:	100027f3          	csrr	a5,sstatus
ffffffffc0201db6:	8b89                	andi	a5,a5,2
ffffffffc0201db8:	e799                	bnez	a5,ffffffffc0201dc6 <nr_free_pages+0x14>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201dba:	000b1797          	auipc	a5,0xb1
ffffffffc0201dbe:	abe7b783          	ld	a5,-1346(a5) # ffffffffc02b2878 <pmm_manager>
ffffffffc0201dc2:	779c                	ld	a5,40(a5)
ffffffffc0201dc4:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc0201dc6:	1141                	addi	sp,sp,-16
ffffffffc0201dc8:	e406                	sd	ra,8(sp)
ffffffffc0201dca:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201dcc:	87bfe0ef          	jal	ra,ffffffffc0200646 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201dd0:	000b1797          	auipc	a5,0xb1
ffffffffc0201dd4:	aa87b783          	ld	a5,-1368(a5) # ffffffffc02b2878 <pmm_manager>
ffffffffc0201dd8:	779c                	ld	a5,40(a5)
ffffffffc0201dda:	9782                	jalr	a5
ffffffffc0201ddc:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201dde:	863fe0ef          	jal	ra,ffffffffc0200640 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201de2:	60a2                	ld	ra,8(sp)
ffffffffc0201de4:	8522                	mv	a0,s0
ffffffffc0201de6:	6402                	ld	s0,0(sp)
ffffffffc0201de8:	0141                	addi	sp,sp,16
ffffffffc0201dea:	8082                	ret

ffffffffc0201dec <get_pte>:
//  pgdir:  the kernel virtual base address of PDT
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201dec:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201df0:	1ff7f793          	andi	a5,a5,511
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0201df4:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201df6:	078e                	slli	a5,a5,0x3
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0201df8:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201dfa:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V)) {
ffffffffc0201dfe:	6094                	ld	a3,0(s1)
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0201e00:	f04a                	sd	s2,32(sp)
ffffffffc0201e02:	ec4e                	sd	s3,24(sp)
ffffffffc0201e04:	e852                	sd	s4,16(sp)
ffffffffc0201e06:	fc06                	sd	ra,56(sp)
ffffffffc0201e08:	f822                	sd	s0,48(sp)
ffffffffc0201e0a:	e456                	sd	s5,8(sp)
ffffffffc0201e0c:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V)) {
ffffffffc0201e0e:	0016f793          	andi	a5,a3,1
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0201e12:	892e                	mv	s2,a1
ffffffffc0201e14:	89b2                	mv	s3,a2
ffffffffc0201e16:	000b1a17          	auipc	s4,0xb1
ffffffffc0201e1a:	a52a0a13          	addi	s4,s4,-1454 # ffffffffc02b2868 <npage>
    if (!(*pdep1 & PTE_V)) {
ffffffffc0201e1e:	e7b5                	bnez	a5,ffffffffc0201e8a <get_pte+0x9e>
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
ffffffffc0201e20:	12060b63          	beqz	a2,ffffffffc0201f56 <get_pte+0x16a>
ffffffffc0201e24:	4505                	li	a0,1
ffffffffc0201e26:	ebbff0ef          	jal	ra,ffffffffc0201ce0 <alloc_pages>
ffffffffc0201e2a:	842a                	mv	s0,a0
ffffffffc0201e2c:	12050563          	beqz	a0,ffffffffc0201f56 <get_pte+0x16a>
    return page - pages + nbase;
ffffffffc0201e30:	000b1b17          	auipc	s6,0xb1
ffffffffc0201e34:	a40b0b13          	addi	s6,s6,-1472 # ffffffffc02b2870 <pages>
ffffffffc0201e38:	000b3503          	ld	a0,0(s6)
ffffffffc0201e3c:	00080ab7          	lui	s5,0x80
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201e40:	000b1a17          	auipc	s4,0xb1
ffffffffc0201e44:	a28a0a13          	addi	s4,s4,-1496 # ffffffffc02b2868 <npage>
ffffffffc0201e48:	40a40533          	sub	a0,s0,a0
ffffffffc0201e4c:	8519                	srai	a0,a0,0x6
ffffffffc0201e4e:	9556                	add	a0,a0,s5
ffffffffc0201e50:	000a3703          	ld	a4,0(s4)
ffffffffc0201e54:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0201e58:	4685                	li	a3,1
ffffffffc0201e5a:	c014                	sw	a3,0(s0)
ffffffffc0201e5c:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201e5e:	0532                	slli	a0,a0,0xc
ffffffffc0201e60:	14e7f263          	bgeu	a5,a4,ffffffffc0201fa4 <get_pte+0x1b8>
ffffffffc0201e64:	000b1797          	auipc	a5,0xb1
ffffffffc0201e68:	a1c7b783          	ld	a5,-1508(a5) # ffffffffc02b2880 <va_pa_offset>
ffffffffc0201e6c:	6605                	lui	a2,0x1
ffffffffc0201e6e:	4581                	li	a1,0
ffffffffc0201e70:	953e                	add	a0,a0,a5
ffffffffc0201e72:	63a040ef          	jal	ra,ffffffffc02064ac <memset>
    return page - pages + nbase;
ffffffffc0201e76:	000b3683          	ld	a3,0(s6)
ffffffffc0201e7a:	40d406b3          	sub	a3,s0,a3
ffffffffc0201e7e:	8699                	srai	a3,a3,0x6
ffffffffc0201e80:	96d6                	add	a3,a3,s5
  asm volatile("sfence.vma");
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type) {
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201e82:	06aa                	slli	a3,a3,0xa
ffffffffc0201e84:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201e88:	e094                	sd	a3,0(s1)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201e8a:	77fd                	lui	a5,0xfffff
ffffffffc0201e8c:	068a                	slli	a3,a3,0x2
ffffffffc0201e8e:	000a3703          	ld	a4,0(s4)
ffffffffc0201e92:	8efd                	and	a3,a3,a5
ffffffffc0201e94:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201e98:	0ce7f163          	bgeu	a5,a4,ffffffffc0201f5a <get_pte+0x16e>
ffffffffc0201e9c:	000b1a97          	auipc	s5,0xb1
ffffffffc0201ea0:	9e4a8a93          	addi	s5,s5,-1564 # ffffffffc02b2880 <va_pa_offset>
ffffffffc0201ea4:	000ab403          	ld	s0,0(s5)
ffffffffc0201ea8:	01595793          	srli	a5,s2,0x15
ffffffffc0201eac:	1ff7f793          	andi	a5,a5,511
ffffffffc0201eb0:	96a2                	add	a3,a3,s0
ffffffffc0201eb2:	00379413          	slli	s0,a5,0x3
ffffffffc0201eb6:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V)) {
ffffffffc0201eb8:	6014                	ld	a3,0(s0)
ffffffffc0201eba:	0016f793          	andi	a5,a3,1
ffffffffc0201ebe:	e3ad                	bnez	a5,ffffffffc0201f20 <get_pte+0x134>
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
ffffffffc0201ec0:	08098b63          	beqz	s3,ffffffffc0201f56 <get_pte+0x16a>
ffffffffc0201ec4:	4505                	li	a0,1
ffffffffc0201ec6:	e1bff0ef          	jal	ra,ffffffffc0201ce0 <alloc_pages>
ffffffffc0201eca:	84aa                	mv	s1,a0
ffffffffc0201ecc:	c549                	beqz	a0,ffffffffc0201f56 <get_pte+0x16a>
    return page - pages + nbase;
ffffffffc0201ece:	000b1b17          	auipc	s6,0xb1
ffffffffc0201ed2:	9a2b0b13          	addi	s6,s6,-1630 # ffffffffc02b2870 <pages>
ffffffffc0201ed6:	000b3503          	ld	a0,0(s6)
ffffffffc0201eda:	000809b7          	lui	s3,0x80
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201ede:	000a3703          	ld	a4,0(s4)
ffffffffc0201ee2:	40a48533          	sub	a0,s1,a0
ffffffffc0201ee6:	8519                	srai	a0,a0,0x6
ffffffffc0201ee8:	954e                	add	a0,a0,s3
ffffffffc0201eea:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0201eee:	4685                	li	a3,1
ffffffffc0201ef0:	c094                	sw	a3,0(s1)
ffffffffc0201ef2:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201ef4:	0532                	slli	a0,a0,0xc
ffffffffc0201ef6:	08e7fa63          	bgeu	a5,a4,ffffffffc0201f8a <get_pte+0x19e>
ffffffffc0201efa:	000ab783          	ld	a5,0(s5)
ffffffffc0201efe:	6605                	lui	a2,0x1
ffffffffc0201f00:	4581                	li	a1,0
ffffffffc0201f02:	953e                	add	a0,a0,a5
ffffffffc0201f04:	5a8040ef          	jal	ra,ffffffffc02064ac <memset>
    return page - pages + nbase;
ffffffffc0201f08:	000b3683          	ld	a3,0(s6)
ffffffffc0201f0c:	40d486b3          	sub	a3,s1,a3
ffffffffc0201f10:	8699                	srai	a3,a3,0x6
ffffffffc0201f12:	96ce                	add	a3,a3,s3
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201f14:	06aa                	slli	a3,a3,0xa
ffffffffc0201f16:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201f1a:	e014                	sd	a3,0(s0)
        }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201f1c:	000a3703          	ld	a4,0(s4)
ffffffffc0201f20:	068a                	slli	a3,a3,0x2
ffffffffc0201f22:	757d                	lui	a0,0xfffff
ffffffffc0201f24:	8ee9                	and	a3,a3,a0
ffffffffc0201f26:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201f2a:	04e7f463          	bgeu	a5,a4,ffffffffc0201f72 <get_pte+0x186>
ffffffffc0201f2e:	000ab503          	ld	a0,0(s5)
ffffffffc0201f32:	00c95913          	srli	s2,s2,0xc
ffffffffc0201f36:	1ff97913          	andi	s2,s2,511
ffffffffc0201f3a:	96aa                	add	a3,a3,a0
ffffffffc0201f3c:	00391513          	slli	a0,s2,0x3
ffffffffc0201f40:	9536                	add	a0,a0,a3
}
ffffffffc0201f42:	70e2                	ld	ra,56(sp)
ffffffffc0201f44:	7442                	ld	s0,48(sp)
ffffffffc0201f46:	74a2                	ld	s1,40(sp)
ffffffffc0201f48:	7902                	ld	s2,32(sp)
ffffffffc0201f4a:	69e2                	ld	s3,24(sp)
ffffffffc0201f4c:	6a42                	ld	s4,16(sp)
ffffffffc0201f4e:	6aa2                	ld	s5,8(sp)
ffffffffc0201f50:	6b02                	ld	s6,0(sp)
ffffffffc0201f52:	6121                	addi	sp,sp,64
ffffffffc0201f54:	8082                	ret
            return NULL;
ffffffffc0201f56:	4501                	li	a0,0
ffffffffc0201f58:	b7ed                	j	ffffffffc0201f42 <get_pte+0x156>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201f5a:	00005617          	auipc	a2,0x5
ffffffffc0201f5e:	30660613          	addi	a2,a2,774 # ffffffffc0207260 <default_pmm_manager+0x38>
ffffffffc0201f62:	0e300593          	li	a1,227
ffffffffc0201f66:	00005517          	auipc	a0,0x5
ffffffffc0201f6a:	41250513          	addi	a0,a0,1042 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc0201f6e:	d0cfe0ef          	jal	ra,ffffffffc020047a <__panic>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201f72:	00005617          	auipc	a2,0x5
ffffffffc0201f76:	2ee60613          	addi	a2,a2,750 # ffffffffc0207260 <default_pmm_manager+0x38>
ffffffffc0201f7a:	0ee00593          	li	a1,238
ffffffffc0201f7e:	00005517          	auipc	a0,0x5
ffffffffc0201f82:	3fa50513          	addi	a0,a0,1018 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc0201f86:	cf4fe0ef          	jal	ra,ffffffffc020047a <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201f8a:	86aa                	mv	a3,a0
ffffffffc0201f8c:	00005617          	auipc	a2,0x5
ffffffffc0201f90:	2d460613          	addi	a2,a2,724 # ffffffffc0207260 <default_pmm_manager+0x38>
ffffffffc0201f94:	0eb00593          	li	a1,235
ffffffffc0201f98:	00005517          	auipc	a0,0x5
ffffffffc0201f9c:	3e050513          	addi	a0,a0,992 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc0201fa0:	cdafe0ef          	jal	ra,ffffffffc020047a <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201fa4:	86aa                	mv	a3,a0
ffffffffc0201fa6:	00005617          	auipc	a2,0x5
ffffffffc0201faa:	2ba60613          	addi	a2,a2,698 # ffffffffc0207260 <default_pmm_manager+0x38>
ffffffffc0201fae:	0df00593          	li	a1,223
ffffffffc0201fb2:	00005517          	auipc	a0,0x5
ffffffffc0201fb6:	3c650513          	addi	a0,a0,966 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc0201fba:	cc0fe0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0201fbe <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc0201fbe:	1141                	addi	sp,sp,-16
ffffffffc0201fc0:	e022                	sd	s0,0(sp)
ffffffffc0201fc2:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201fc4:	4601                	li	a2,0
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc0201fc6:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201fc8:	e25ff0ef          	jal	ra,ffffffffc0201dec <get_pte>
    if (ptep_store != NULL) {
ffffffffc0201fcc:	c011                	beqz	s0,ffffffffc0201fd0 <get_page+0x12>
        *ptep_store = ptep;
ffffffffc0201fce:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V) {
ffffffffc0201fd0:	c511                	beqz	a0,ffffffffc0201fdc <get_page+0x1e>
ffffffffc0201fd2:	611c                	ld	a5,0(a0)
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0201fd4:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V) {
ffffffffc0201fd6:	0017f713          	andi	a4,a5,1
ffffffffc0201fda:	e709                	bnez	a4,ffffffffc0201fe4 <get_page+0x26>
}
ffffffffc0201fdc:	60a2                	ld	ra,8(sp)
ffffffffc0201fde:	6402                	ld	s0,0(sp)
ffffffffc0201fe0:	0141                	addi	sp,sp,16
ffffffffc0201fe2:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0201fe4:	078a                	slli	a5,a5,0x2
ffffffffc0201fe6:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201fe8:	000b1717          	auipc	a4,0xb1
ffffffffc0201fec:	88073703          	ld	a4,-1920(a4) # ffffffffc02b2868 <npage>
ffffffffc0201ff0:	00e7ff63          	bgeu	a5,a4,ffffffffc020200e <get_page+0x50>
ffffffffc0201ff4:	60a2                	ld	ra,8(sp)
ffffffffc0201ff6:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc0201ff8:	fff80537          	lui	a0,0xfff80
ffffffffc0201ffc:	97aa                	add	a5,a5,a0
ffffffffc0201ffe:	079a                	slli	a5,a5,0x6
ffffffffc0202000:	000b1517          	auipc	a0,0xb1
ffffffffc0202004:	87053503          	ld	a0,-1936(a0) # ffffffffc02b2870 <pages>
ffffffffc0202008:	953e                	add	a0,a0,a5
ffffffffc020200a:	0141                	addi	sp,sp,16
ffffffffc020200c:	8082                	ret
ffffffffc020200e:	c9bff0ef          	jal	ra,ffffffffc0201ca8 <pa2page.part.0>

ffffffffc0202012 <unmap_range>:
        *ptep = 0;                  //(5) clear second page table entry
        tlb_invalidate(pgdir, la);  //(6) flush tlb
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
ffffffffc0202012:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202014:	00c5e7b3          	or	a5,a1,a2
void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
ffffffffc0202018:	f486                	sd	ra,104(sp)
ffffffffc020201a:	f0a2                	sd	s0,96(sp)
ffffffffc020201c:	eca6                	sd	s1,88(sp)
ffffffffc020201e:	e8ca                	sd	s2,80(sp)
ffffffffc0202020:	e4ce                	sd	s3,72(sp)
ffffffffc0202022:	e0d2                	sd	s4,64(sp)
ffffffffc0202024:	fc56                	sd	s5,56(sp)
ffffffffc0202026:	f85a                	sd	s6,48(sp)
ffffffffc0202028:	f45e                	sd	s7,40(sp)
ffffffffc020202a:	f062                	sd	s8,32(sp)
ffffffffc020202c:	ec66                	sd	s9,24(sp)
ffffffffc020202e:	e86a                	sd	s10,16(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202030:	17d2                	slli	a5,a5,0x34
ffffffffc0202032:	e3ed                	bnez	a5,ffffffffc0202114 <unmap_range+0x102>
    assert(USER_ACCESS(start, end));
ffffffffc0202034:	002007b7          	lui	a5,0x200
ffffffffc0202038:	842e                	mv	s0,a1
ffffffffc020203a:	0ef5ed63          	bltu	a1,a5,ffffffffc0202134 <unmap_range+0x122>
ffffffffc020203e:	8932                	mv	s2,a2
ffffffffc0202040:	0ec5fa63          	bgeu	a1,a2,ffffffffc0202134 <unmap_range+0x122>
ffffffffc0202044:	4785                	li	a5,1
ffffffffc0202046:	07fe                	slli	a5,a5,0x1f
ffffffffc0202048:	0ec7e663          	bltu	a5,a2,ffffffffc0202134 <unmap_range+0x122>
ffffffffc020204c:	89aa                	mv	s3,a0
            continue;
        }
        if (*ptep != 0) {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
ffffffffc020204e:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage) {
ffffffffc0202050:	000b1c97          	auipc	s9,0xb1
ffffffffc0202054:	818c8c93          	addi	s9,s9,-2024 # ffffffffc02b2868 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0202058:	000b1c17          	auipc	s8,0xb1
ffffffffc020205c:	818c0c13          	addi	s8,s8,-2024 # ffffffffc02b2870 <pages>
ffffffffc0202060:	fff80bb7          	lui	s7,0xfff80
        pmm_manager->free_pages(base, n);
ffffffffc0202064:	000b1d17          	auipc	s10,0xb1
ffffffffc0202068:	814d0d13          	addi	s10,s10,-2028 # ffffffffc02b2878 <pmm_manager>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc020206c:	00200b37          	lui	s6,0x200
ffffffffc0202070:	ffe00ab7          	lui	s5,0xffe00
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc0202074:	4601                	li	a2,0
ffffffffc0202076:	85a2                	mv	a1,s0
ffffffffc0202078:	854e                	mv	a0,s3
ffffffffc020207a:	d73ff0ef          	jal	ra,ffffffffc0201dec <get_pte>
ffffffffc020207e:	84aa                	mv	s1,a0
        if (ptep == NULL) {
ffffffffc0202080:	cd29                	beqz	a0,ffffffffc02020da <unmap_range+0xc8>
        if (*ptep != 0) {
ffffffffc0202082:	611c                	ld	a5,0(a0)
ffffffffc0202084:	e395                	bnez	a5,ffffffffc02020a8 <unmap_range+0x96>
        start += PGSIZE;
ffffffffc0202086:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc0202088:	ff2466e3          	bltu	s0,s2,ffffffffc0202074 <unmap_range+0x62>
}
ffffffffc020208c:	70a6                	ld	ra,104(sp)
ffffffffc020208e:	7406                	ld	s0,96(sp)
ffffffffc0202090:	64e6                	ld	s1,88(sp)
ffffffffc0202092:	6946                	ld	s2,80(sp)
ffffffffc0202094:	69a6                	ld	s3,72(sp)
ffffffffc0202096:	6a06                	ld	s4,64(sp)
ffffffffc0202098:	7ae2                	ld	s5,56(sp)
ffffffffc020209a:	7b42                	ld	s6,48(sp)
ffffffffc020209c:	7ba2                	ld	s7,40(sp)
ffffffffc020209e:	7c02                	ld	s8,32(sp)
ffffffffc02020a0:	6ce2                	ld	s9,24(sp)
ffffffffc02020a2:	6d42                	ld	s10,16(sp)
ffffffffc02020a4:	6165                	addi	sp,sp,112
ffffffffc02020a6:	8082                	ret
    if (*ptep & PTE_V) {  //(1) check if this page table entry is
ffffffffc02020a8:	0017f713          	andi	a4,a5,1
ffffffffc02020ac:	df69                	beqz	a4,ffffffffc0202086 <unmap_range+0x74>
    if (PPN(pa) >= npage) {
ffffffffc02020ae:	000cb703          	ld	a4,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc02020b2:	078a                	slli	a5,a5,0x2
ffffffffc02020b4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02020b6:	08e7ff63          	bgeu	a5,a4,ffffffffc0202154 <unmap_range+0x142>
    return &pages[PPN(pa) - nbase];
ffffffffc02020ba:	000c3503          	ld	a0,0(s8)
ffffffffc02020be:	97de                	add	a5,a5,s7
ffffffffc02020c0:	079a                	slli	a5,a5,0x6
ffffffffc02020c2:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc02020c4:	411c                	lw	a5,0(a0)
ffffffffc02020c6:	fff7871b          	addiw	a4,a5,-1
ffffffffc02020ca:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc02020cc:	cf11                	beqz	a4,ffffffffc02020e8 <unmap_range+0xd6>
        *ptep = 0;                  //(5) clear second page table entry
ffffffffc02020ce:	0004b023          	sd	zero,0(s1)
}

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la) {
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02020d2:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc02020d6:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc02020d8:	bf45                	j	ffffffffc0202088 <unmap_range+0x76>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02020da:	945a                	add	s0,s0,s6
ffffffffc02020dc:	01547433          	and	s0,s0,s5
    } while (start != 0 && start < end);
ffffffffc02020e0:	d455                	beqz	s0,ffffffffc020208c <unmap_range+0x7a>
ffffffffc02020e2:	f92469e3          	bltu	s0,s2,ffffffffc0202074 <unmap_range+0x62>
ffffffffc02020e6:	b75d                	j	ffffffffc020208c <unmap_range+0x7a>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02020e8:	100027f3          	csrr	a5,sstatus
ffffffffc02020ec:	8b89                	andi	a5,a5,2
ffffffffc02020ee:	e799                	bnez	a5,ffffffffc02020fc <unmap_range+0xea>
        pmm_manager->free_pages(base, n);
ffffffffc02020f0:	000d3783          	ld	a5,0(s10)
ffffffffc02020f4:	4585                	li	a1,1
ffffffffc02020f6:	739c                	ld	a5,32(a5)
ffffffffc02020f8:	9782                	jalr	a5
    if (flag) {
ffffffffc02020fa:	bfd1                	j	ffffffffc02020ce <unmap_range+0xbc>
ffffffffc02020fc:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02020fe:	d48fe0ef          	jal	ra,ffffffffc0200646 <intr_disable>
ffffffffc0202102:	000d3783          	ld	a5,0(s10)
ffffffffc0202106:	6522                	ld	a0,8(sp)
ffffffffc0202108:	4585                	li	a1,1
ffffffffc020210a:	739c                	ld	a5,32(a5)
ffffffffc020210c:	9782                	jalr	a5
        intr_enable();
ffffffffc020210e:	d32fe0ef          	jal	ra,ffffffffc0200640 <intr_enable>
ffffffffc0202112:	bf75                	j	ffffffffc02020ce <unmap_range+0xbc>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202114:	00005697          	auipc	a3,0x5
ffffffffc0202118:	27468693          	addi	a3,a3,628 # ffffffffc0207388 <default_pmm_manager+0x160>
ffffffffc020211c:	00005617          	auipc	a2,0x5
ffffffffc0202120:	a7460613          	addi	a2,a2,-1420 # ffffffffc0206b90 <commands+0x450>
ffffffffc0202124:	10f00593          	li	a1,271
ffffffffc0202128:	00005517          	auipc	a0,0x5
ffffffffc020212c:	25050513          	addi	a0,a0,592 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc0202130:	b4afe0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0202134:	00005697          	auipc	a3,0x5
ffffffffc0202138:	28468693          	addi	a3,a3,644 # ffffffffc02073b8 <default_pmm_manager+0x190>
ffffffffc020213c:	00005617          	auipc	a2,0x5
ffffffffc0202140:	a5460613          	addi	a2,a2,-1452 # ffffffffc0206b90 <commands+0x450>
ffffffffc0202144:	11000593          	li	a1,272
ffffffffc0202148:	00005517          	auipc	a0,0x5
ffffffffc020214c:	23050513          	addi	a0,a0,560 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc0202150:	b2afe0ef          	jal	ra,ffffffffc020047a <__panic>
ffffffffc0202154:	b55ff0ef          	jal	ra,ffffffffc0201ca8 <pa2page.part.0>

ffffffffc0202158 <exit_range>:
void exit_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
ffffffffc0202158:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020215a:	00c5e7b3          	or	a5,a1,a2
void exit_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
ffffffffc020215e:	fc86                	sd	ra,120(sp)
ffffffffc0202160:	f8a2                	sd	s0,112(sp)
ffffffffc0202162:	f4a6                	sd	s1,104(sp)
ffffffffc0202164:	f0ca                	sd	s2,96(sp)
ffffffffc0202166:	ecce                	sd	s3,88(sp)
ffffffffc0202168:	e8d2                	sd	s4,80(sp)
ffffffffc020216a:	e4d6                	sd	s5,72(sp)
ffffffffc020216c:	e0da                	sd	s6,64(sp)
ffffffffc020216e:	fc5e                	sd	s7,56(sp)
ffffffffc0202170:	f862                	sd	s8,48(sp)
ffffffffc0202172:	f466                	sd	s9,40(sp)
ffffffffc0202174:	f06a                	sd	s10,32(sp)
ffffffffc0202176:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202178:	17d2                	slli	a5,a5,0x34
ffffffffc020217a:	20079a63          	bnez	a5,ffffffffc020238e <exit_range+0x236>
    assert(USER_ACCESS(start, end));
ffffffffc020217e:	002007b7          	lui	a5,0x200
ffffffffc0202182:	24f5e463          	bltu	a1,a5,ffffffffc02023ca <exit_range+0x272>
ffffffffc0202186:	8ab2                	mv	s5,a2
ffffffffc0202188:	24c5f163          	bgeu	a1,a2,ffffffffc02023ca <exit_range+0x272>
ffffffffc020218c:	4785                	li	a5,1
ffffffffc020218e:	07fe                	slli	a5,a5,0x1f
ffffffffc0202190:	22c7ed63          	bltu	a5,a2,ffffffffc02023ca <exit_range+0x272>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc0202194:	c00009b7          	lui	s3,0xc0000
ffffffffc0202198:	0135f9b3          	and	s3,a1,s3
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc020219c:	ffe00937          	lui	s2,0xffe00
ffffffffc02021a0:	400007b7          	lui	a5,0x40000
    return KADDR(page2pa(page));
ffffffffc02021a4:	5cfd                	li	s9,-1
ffffffffc02021a6:	8c2a                	mv	s8,a0
ffffffffc02021a8:	0125f933          	and	s2,a1,s2
ffffffffc02021ac:	99be                	add	s3,s3,a5
    if (PPN(pa) >= npage) {
ffffffffc02021ae:	000b0d17          	auipc	s10,0xb0
ffffffffc02021b2:	6bad0d13          	addi	s10,s10,1722 # ffffffffc02b2868 <npage>
    return KADDR(page2pa(page));
ffffffffc02021b6:	00ccdc93          	srli	s9,s9,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc02021ba:	000b0717          	auipc	a4,0xb0
ffffffffc02021be:	6b670713          	addi	a4,a4,1718 # ffffffffc02b2870 <pages>
        pmm_manager->free_pages(base, n);
ffffffffc02021c2:	000b0d97          	auipc	s11,0xb0
ffffffffc02021c6:	6b6d8d93          	addi	s11,s11,1718 # ffffffffc02b2878 <pmm_manager>
        pde1 = pgdir[PDX1(d1start)];
ffffffffc02021ca:	c0000437          	lui	s0,0xc0000
ffffffffc02021ce:	944e                	add	s0,s0,s3
ffffffffc02021d0:	8079                	srli	s0,s0,0x1e
ffffffffc02021d2:	1ff47413          	andi	s0,s0,511
ffffffffc02021d6:	040e                	slli	s0,s0,0x3
ffffffffc02021d8:	9462                	add	s0,s0,s8
ffffffffc02021da:	00043a03          	ld	s4,0(s0) # ffffffffc0000000 <_binary_obj___user_exit_out_size+0xffffffffbfff4ed8>
        if (pde1&PTE_V){
ffffffffc02021de:	001a7793          	andi	a5,s4,1
ffffffffc02021e2:	eb99                	bnez	a5,ffffffffc02021f8 <exit_range+0xa0>
    } while (d1start != 0 && d1start < end);
ffffffffc02021e4:	12098463          	beqz	s3,ffffffffc020230c <exit_range+0x1b4>
ffffffffc02021e8:	400007b7          	lui	a5,0x40000
ffffffffc02021ec:	97ce                	add	a5,a5,s3
ffffffffc02021ee:	894e                	mv	s2,s3
ffffffffc02021f0:	1159fe63          	bgeu	s3,s5,ffffffffc020230c <exit_range+0x1b4>
ffffffffc02021f4:	89be                	mv	s3,a5
ffffffffc02021f6:	bfd1                	j	ffffffffc02021ca <exit_range+0x72>
    if (PPN(pa) >= npage) {
ffffffffc02021f8:	000d3783          	ld	a5,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc02021fc:	0a0a                	slli	s4,s4,0x2
ffffffffc02021fe:	00ca5a13          	srli	s4,s4,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202202:	1cfa7263          	bgeu	s4,a5,ffffffffc02023c6 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202206:	fff80637          	lui	a2,0xfff80
ffffffffc020220a:	9652                	add	a2,a2,s4
    return page - pages + nbase;
ffffffffc020220c:	000806b7          	lui	a3,0x80
ffffffffc0202210:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc0202212:	0196f5b3          	and	a1,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc0202216:	061a                	slli	a2,a2,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc0202218:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020221a:	18f5fa63          	bgeu	a1,a5,ffffffffc02023ae <exit_range+0x256>
ffffffffc020221e:	000b0817          	auipc	a6,0xb0
ffffffffc0202222:	66280813          	addi	a6,a6,1634 # ffffffffc02b2880 <va_pa_offset>
ffffffffc0202226:	00083b03          	ld	s6,0(a6)
            free_pd0 = 1;
ffffffffc020222a:	4b85                	li	s7,1
    return &pages[PPN(pa) - nbase];
ffffffffc020222c:	fff80e37          	lui	t3,0xfff80
    return KADDR(page2pa(page));
ffffffffc0202230:	9b36                	add	s6,s6,a3
    return page - pages + nbase;
ffffffffc0202232:	00080337          	lui	t1,0x80
ffffffffc0202236:	6885                	lui	a7,0x1
ffffffffc0202238:	a819                	j	ffffffffc020224e <exit_range+0xf6>
                    free_pd0 = 0;
ffffffffc020223a:	4b81                	li	s7,0
                d0start += PTSIZE;
ffffffffc020223c:	002007b7          	lui	a5,0x200
ffffffffc0202240:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start+PDSIZE && d0start < end);
ffffffffc0202242:	08090c63          	beqz	s2,ffffffffc02022da <exit_range+0x182>
ffffffffc0202246:	09397a63          	bgeu	s2,s3,ffffffffc02022da <exit_range+0x182>
ffffffffc020224a:	0f597063          	bgeu	s2,s5,ffffffffc020232a <exit_range+0x1d2>
                pde0 = pd0[PDX0(d0start)];
ffffffffc020224e:	01595493          	srli	s1,s2,0x15
ffffffffc0202252:	1ff4f493          	andi	s1,s1,511
ffffffffc0202256:	048e                	slli	s1,s1,0x3
ffffffffc0202258:	94da                	add	s1,s1,s6
ffffffffc020225a:	609c                	ld	a5,0(s1)
                if (pde0&PTE_V) {
ffffffffc020225c:	0017f693          	andi	a3,a5,1
ffffffffc0202260:	dee9                	beqz	a3,ffffffffc020223a <exit_range+0xe2>
    if (PPN(pa) >= npage) {
ffffffffc0202262:	000d3583          	ld	a1,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202266:	078a                	slli	a5,a5,0x2
ffffffffc0202268:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020226a:	14b7fe63          	bgeu	a5,a1,ffffffffc02023c6 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc020226e:	97f2                	add	a5,a5,t3
    return page - pages + nbase;
ffffffffc0202270:	006786b3          	add	a3,a5,t1
    return KADDR(page2pa(page));
ffffffffc0202274:	0196feb3          	and	t4,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc0202278:	00679513          	slli	a0,a5,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc020227c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020227e:	12bef863          	bgeu	t4,a1,ffffffffc02023ae <exit_range+0x256>
ffffffffc0202282:	00083783          	ld	a5,0(a6)
ffffffffc0202286:	96be                	add	a3,a3,a5
                    for (int i = 0;i <NPTEENTRY;i++)
ffffffffc0202288:	011685b3          	add	a1,a3,a7
                        if (pt[i]&PTE_V){
ffffffffc020228c:	629c                	ld	a5,0(a3)
ffffffffc020228e:	8b85                	andi	a5,a5,1
ffffffffc0202290:	f7d5                	bnez	a5,ffffffffc020223c <exit_range+0xe4>
                    for (int i = 0;i <NPTEENTRY;i++)
ffffffffc0202292:	06a1                	addi	a3,a3,8
ffffffffc0202294:	fed59ce3          	bne	a1,a3,ffffffffc020228c <exit_range+0x134>
    return &pages[PPN(pa) - nbase];
ffffffffc0202298:	631c                	ld	a5,0(a4)
ffffffffc020229a:	953e                	add	a0,a0,a5
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020229c:	100027f3          	csrr	a5,sstatus
ffffffffc02022a0:	8b89                	andi	a5,a5,2
ffffffffc02022a2:	e7d9                	bnez	a5,ffffffffc0202330 <exit_range+0x1d8>
        pmm_manager->free_pages(base, n);
ffffffffc02022a4:	000db783          	ld	a5,0(s11)
ffffffffc02022a8:	4585                	li	a1,1
ffffffffc02022aa:	e032                	sd	a2,0(sp)
ffffffffc02022ac:	739c                	ld	a5,32(a5)
ffffffffc02022ae:	9782                	jalr	a5
    if (flag) {
ffffffffc02022b0:	6602                	ld	a2,0(sp)
ffffffffc02022b2:	000b0817          	auipc	a6,0xb0
ffffffffc02022b6:	5ce80813          	addi	a6,a6,1486 # ffffffffc02b2880 <va_pa_offset>
ffffffffc02022ba:	fff80e37          	lui	t3,0xfff80
ffffffffc02022be:	00080337          	lui	t1,0x80
ffffffffc02022c2:	6885                	lui	a7,0x1
ffffffffc02022c4:	000b0717          	auipc	a4,0xb0
ffffffffc02022c8:	5ac70713          	addi	a4,a4,1452 # ffffffffc02b2870 <pages>
                        pd0[PDX0(d0start)] = 0;
ffffffffc02022cc:	0004b023          	sd	zero,0(s1)
                d0start += PTSIZE;
ffffffffc02022d0:	002007b7          	lui	a5,0x200
ffffffffc02022d4:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start+PDSIZE && d0start < end);
ffffffffc02022d6:	f60918e3          	bnez	s2,ffffffffc0202246 <exit_range+0xee>
            if (free_pd0) {
ffffffffc02022da:	f00b85e3          	beqz	s7,ffffffffc02021e4 <exit_range+0x8c>
    if (PPN(pa) >= npage) {
ffffffffc02022de:	000d3783          	ld	a5,0(s10)
ffffffffc02022e2:	0efa7263          	bgeu	s4,a5,ffffffffc02023c6 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc02022e6:	6308                	ld	a0,0(a4)
ffffffffc02022e8:	9532                	add	a0,a0,a2
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02022ea:	100027f3          	csrr	a5,sstatus
ffffffffc02022ee:	8b89                	andi	a5,a5,2
ffffffffc02022f0:	efad                	bnez	a5,ffffffffc020236a <exit_range+0x212>
        pmm_manager->free_pages(base, n);
ffffffffc02022f2:	000db783          	ld	a5,0(s11)
ffffffffc02022f6:	4585                	li	a1,1
ffffffffc02022f8:	739c                	ld	a5,32(a5)
ffffffffc02022fa:	9782                	jalr	a5
ffffffffc02022fc:	000b0717          	auipc	a4,0xb0
ffffffffc0202300:	57470713          	addi	a4,a4,1396 # ffffffffc02b2870 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc0202304:	00043023          	sd	zero,0(s0)
    } while (d1start != 0 && d1start < end);
ffffffffc0202308:	ee0990e3          	bnez	s3,ffffffffc02021e8 <exit_range+0x90>
}
ffffffffc020230c:	70e6                	ld	ra,120(sp)
ffffffffc020230e:	7446                	ld	s0,112(sp)
ffffffffc0202310:	74a6                	ld	s1,104(sp)
ffffffffc0202312:	7906                	ld	s2,96(sp)
ffffffffc0202314:	69e6                	ld	s3,88(sp)
ffffffffc0202316:	6a46                	ld	s4,80(sp)
ffffffffc0202318:	6aa6                	ld	s5,72(sp)
ffffffffc020231a:	6b06                	ld	s6,64(sp)
ffffffffc020231c:	7be2                	ld	s7,56(sp)
ffffffffc020231e:	7c42                	ld	s8,48(sp)
ffffffffc0202320:	7ca2                	ld	s9,40(sp)
ffffffffc0202322:	7d02                	ld	s10,32(sp)
ffffffffc0202324:	6de2                	ld	s11,24(sp)
ffffffffc0202326:	6109                	addi	sp,sp,128
ffffffffc0202328:	8082                	ret
            if (free_pd0) {
ffffffffc020232a:	ea0b8fe3          	beqz	s7,ffffffffc02021e8 <exit_range+0x90>
ffffffffc020232e:	bf45                	j	ffffffffc02022de <exit_range+0x186>
ffffffffc0202330:	e032                	sd	a2,0(sp)
        intr_disable();
ffffffffc0202332:	e42a                	sd	a0,8(sp)
ffffffffc0202334:	b12fe0ef          	jal	ra,ffffffffc0200646 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202338:	000db783          	ld	a5,0(s11)
ffffffffc020233c:	6522                	ld	a0,8(sp)
ffffffffc020233e:	4585                	li	a1,1
ffffffffc0202340:	739c                	ld	a5,32(a5)
ffffffffc0202342:	9782                	jalr	a5
        intr_enable();
ffffffffc0202344:	afcfe0ef          	jal	ra,ffffffffc0200640 <intr_enable>
ffffffffc0202348:	6602                	ld	a2,0(sp)
ffffffffc020234a:	000b0717          	auipc	a4,0xb0
ffffffffc020234e:	52670713          	addi	a4,a4,1318 # ffffffffc02b2870 <pages>
ffffffffc0202352:	6885                	lui	a7,0x1
ffffffffc0202354:	00080337          	lui	t1,0x80
ffffffffc0202358:	fff80e37          	lui	t3,0xfff80
ffffffffc020235c:	000b0817          	auipc	a6,0xb0
ffffffffc0202360:	52480813          	addi	a6,a6,1316 # ffffffffc02b2880 <va_pa_offset>
                        pd0[PDX0(d0start)] = 0;
ffffffffc0202364:	0004b023          	sd	zero,0(s1)
ffffffffc0202368:	b7a5                	j	ffffffffc02022d0 <exit_range+0x178>
ffffffffc020236a:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc020236c:	adafe0ef          	jal	ra,ffffffffc0200646 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202370:	000db783          	ld	a5,0(s11)
ffffffffc0202374:	6502                	ld	a0,0(sp)
ffffffffc0202376:	4585                	li	a1,1
ffffffffc0202378:	739c                	ld	a5,32(a5)
ffffffffc020237a:	9782                	jalr	a5
        intr_enable();
ffffffffc020237c:	ac4fe0ef          	jal	ra,ffffffffc0200640 <intr_enable>
ffffffffc0202380:	000b0717          	auipc	a4,0xb0
ffffffffc0202384:	4f070713          	addi	a4,a4,1264 # ffffffffc02b2870 <pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc0202388:	00043023          	sd	zero,0(s0)
ffffffffc020238c:	bfb5                	j	ffffffffc0202308 <exit_range+0x1b0>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020238e:	00005697          	auipc	a3,0x5
ffffffffc0202392:	ffa68693          	addi	a3,a3,-6 # ffffffffc0207388 <default_pmm_manager+0x160>
ffffffffc0202396:	00004617          	auipc	a2,0x4
ffffffffc020239a:	7fa60613          	addi	a2,a2,2042 # ffffffffc0206b90 <commands+0x450>
ffffffffc020239e:	12000593          	li	a1,288
ffffffffc02023a2:	00005517          	auipc	a0,0x5
ffffffffc02023a6:	fd650513          	addi	a0,a0,-42 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc02023aa:	8d0fe0ef          	jal	ra,ffffffffc020047a <__panic>
    return KADDR(page2pa(page));
ffffffffc02023ae:	00005617          	auipc	a2,0x5
ffffffffc02023b2:	eb260613          	addi	a2,a2,-334 # ffffffffc0207260 <default_pmm_manager+0x38>
ffffffffc02023b6:	06900593          	li	a1,105
ffffffffc02023ba:	00005517          	auipc	a0,0x5
ffffffffc02023be:	ece50513          	addi	a0,a0,-306 # ffffffffc0207288 <default_pmm_manager+0x60>
ffffffffc02023c2:	8b8fe0ef          	jal	ra,ffffffffc020047a <__panic>
ffffffffc02023c6:	8e3ff0ef          	jal	ra,ffffffffc0201ca8 <pa2page.part.0>
    assert(USER_ACCESS(start, end));
ffffffffc02023ca:	00005697          	auipc	a3,0x5
ffffffffc02023ce:	fee68693          	addi	a3,a3,-18 # ffffffffc02073b8 <default_pmm_manager+0x190>
ffffffffc02023d2:	00004617          	auipc	a2,0x4
ffffffffc02023d6:	7be60613          	addi	a2,a2,1982 # ffffffffc0206b90 <commands+0x450>
ffffffffc02023da:	12100593          	li	a1,289
ffffffffc02023de:	00005517          	auipc	a0,0x5
ffffffffc02023e2:	f9a50513          	addi	a0,a0,-102 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc02023e6:	894fe0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc02023ea <page_remove>:
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc02023ea:	7179                	addi	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02023ec:	4601                	li	a2,0
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc02023ee:	ec26                	sd	s1,24(sp)
ffffffffc02023f0:	f406                	sd	ra,40(sp)
ffffffffc02023f2:	f022                	sd	s0,32(sp)
ffffffffc02023f4:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02023f6:	9f7ff0ef          	jal	ra,ffffffffc0201dec <get_pte>
    if (ptep != NULL) {
ffffffffc02023fa:	c511                	beqz	a0,ffffffffc0202406 <page_remove+0x1c>
    if (*ptep & PTE_V) {  //(1) check if this page table entry is
ffffffffc02023fc:	611c                	ld	a5,0(a0)
ffffffffc02023fe:	842a                	mv	s0,a0
ffffffffc0202400:	0017f713          	andi	a4,a5,1
ffffffffc0202404:	e711                	bnez	a4,ffffffffc0202410 <page_remove+0x26>
}
ffffffffc0202406:	70a2                	ld	ra,40(sp)
ffffffffc0202408:	7402                	ld	s0,32(sp)
ffffffffc020240a:	64e2                	ld	s1,24(sp)
ffffffffc020240c:	6145                	addi	sp,sp,48
ffffffffc020240e:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0202410:	078a                	slli	a5,a5,0x2
ffffffffc0202412:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202414:	000b0717          	auipc	a4,0xb0
ffffffffc0202418:	45473703          	ld	a4,1108(a4) # ffffffffc02b2868 <npage>
ffffffffc020241c:	06e7f363          	bgeu	a5,a4,ffffffffc0202482 <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc0202420:	fff80537          	lui	a0,0xfff80
ffffffffc0202424:	97aa                	add	a5,a5,a0
ffffffffc0202426:	079a                	slli	a5,a5,0x6
ffffffffc0202428:	000b0517          	auipc	a0,0xb0
ffffffffc020242c:	44853503          	ld	a0,1096(a0) # ffffffffc02b2870 <pages>
ffffffffc0202430:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0202432:	411c                	lw	a5,0(a0)
ffffffffc0202434:	fff7871b          	addiw	a4,a5,-1
ffffffffc0202438:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc020243a:	cb11                	beqz	a4,ffffffffc020244e <page_remove+0x64>
        *ptep = 0;                  //(5) clear second page table entry
ffffffffc020243c:	00043023          	sd	zero,0(s0)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202440:	12048073          	sfence.vma	s1
}
ffffffffc0202444:	70a2                	ld	ra,40(sp)
ffffffffc0202446:	7402                	ld	s0,32(sp)
ffffffffc0202448:	64e2                	ld	s1,24(sp)
ffffffffc020244a:	6145                	addi	sp,sp,48
ffffffffc020244c:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020244e:	100027f3          	csrr	a5,sstatus
ffffffffc0202452:	8b89                	andi	a5,a5,2
ffffffffc0202454:	eb89                	bnez	a5,ffffffffc0202466 <page_remove+0x7c>
        pmm_manager->free_pages(base, n);
ffffffffc0202456:	000b0797          	auipc	a5,0xb0
ffffffffc020245a:	4227b783          	ld	a5,1058(a5) # ffffffffc02b2878 <pmm_manager>
ffffffffc020245e:	739c                	ld	a5,32(a5)
ffffffffc0202460:	4585                	li	a1,1
ffffffffc0202462:	9782                	jalr	a5
    if (flag) {
ffffffffc0202464:	bfe1                	j	ffffffffc020243c <page_remove+0x52>
        intr_disable();
ffffffffc0202466:	e42a                	sd	a0,8(sp)
ffffffffc0202468:	9defe0ef          	jal	ra,ffffffffc0200646 <intr_disable>
ffffffffc020246c:	000b0797          	auipc	a5,0xb0
ffffffffc0202470:	40c7b783          	ld	a5,1036(a5) # ffffffffc02b2878 <pmm_manager>
ffffffffc0202474:	739c                	ld	a5,32(a5)
ffffffffc0202476:	6522                	ld	a0,8(sp)
ffffffffc0202478:	4585                	li	a1,1
ffffffffc020247a:	9782                	jalr	a5
        intr_enable();
ffffffffc020247c:	9c4fe0ef          	jal	ra,ffffffffc0200640 <intr_enable>
ffffffffc0202480:	bf75                	j	ffffffffc020243c <page_remove+0x52>
ffffffffc0202482:	827ff0ef          	jal	ra,ffffffffc0201ca8 <pa2page.part.0>

ffffffffc0202486 <page_insert>:
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0202486:	7139                	addi	sp,sp,-64
ffffffffc0202488:	e852                	sd	s4,16(sp)
ffffffffc020248a:	8a32                	mv	s4,a2
ffffffffc020248c:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020248e:	4605                	li	a2,1
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0202490:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202492:	85d2                	mv	a1,s4
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0202494:	f426                	sd	s1,40(sp)
ffffffffc0202496:	fc06                	sd	ra,56(sp)
ffffffffc0202498:	f04a                	sd	s2,32(sp)
ffffffffc020249a:	ec4e                	sd	s3,24(sp)
ffffffffc020249c:	e456                	sd	s5,8(sp)
ffffffffc020249e:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02024a0:	94dff0ef          	jal	ra,ffffffffc0201dec <get_pte>
    if (ptep == NULL) {
ffffffffc02024a4:	c961                	beqz	a0,ffffffffc0202574 <page_insert+0xee>
    page->ref += 1;
ffffffffc02024a6:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V) {
ffffffffc02024a8:	611c                	ld	a5,0(a0)
ffffffffc02024aa:	89aa                	mv	s3,a0
ffffffffc02024ac:	0016871b          	addiw	a4,a3,1
ffffffffc02024b0:	c018                	sw	a4,0(s0)
ffffffffc02024b2:	0017f713          	andi	a4,a5,1
ffffffffc02024b6:	ef05                	bnez	a4,ffffffffc02024ee <page_insert+0x68>
    return page - pages + nbase;
ffffffffc02024b8:	000b0717          	auipc	a4,0xb0
ffffffffc02024bc:	3b873703          	ld	a4,952(a4) # ffffffffc02b2870 <pages>
ffffffffc02024c0:	8c19                	sub	s0,s0,a4
ffffffffc02024c2:	000807b7          	lui	a5,0x80
ffffffffc02024c6:	8419                	srai	s0,s0,0x6
ffffffffc02024c8:	943e                	add	s0,s0,a5
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02024ca:	042a                	slli	s0,s0,0xa
ffffffffc02024cc:	8cc1                	or	s1,s1,s0
ffffffffc02024ce:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc02024d2:	0099b023          	sd	s1,0(s3) # ffffffffc0000000 <_binary_obj___user_exit_out_size+0xffffffffbfff4ed8>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02024d6:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc02024da:	4501                	li	a0,0
}
ffffffffc02024dc:	70e2                	ld	ra,56(sp)
ffffffffc02024de:	7442                	ld	s0,48(sp)
ffffffffc02024e0:	74a2                	ld	s1,40(sp)
ffffffffc02024e2:	7902                	ld	s2,32(sp)
ffffffffc02024e4:	69e2                	ld	s3,24(sp)
ffffffffc02024e6:	6a42                	ld	s4,16(sp)
ffffffffc02024e8:	6aa2                	ld	s5,8(sp)
ffffffffc02024ea:	6121                	addi	sp,sp,64
ffffffffc02024ec:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc02024ee:	078a                	slli	a5,a5,0x2
ffffffffc02024f0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02024f2:	000b0717          	auipc	a4,0xb0
ffffffffc02024f6:	37673703          	ld	a4,886(a4) # ffffffffc02b2868 <npage>
ffffffffc02024fa:	06e7ff63          	bgeu	a5,a4,ffffffffc0202578 <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc02024fe:	000b0a97          	auipc	s5,0xb0
ffffffffc0202502:	372a8a93          	addi	s5,s5,882 # ffffffffc02b2870 <pages>
ffffffffc0202506:	000ab703          	ld	a4,0(s5)
ffffffffc020250a:	fff80937          	lui	s2,0xfff80
ffffffffc020250e:	993e                	add	s2,s2,a5
ffffffffc0202510:	091a                	slli	s2,s2,0x6
ffffffffc0202512:	993a                	add	s2,s2,a4
        if (p == page) {
ffffffffc0202514:	01240c63          	beq	s0,s2,ffffffffc020252c <page_insert+0xa6>
    page->ref -= 1;
ffffffffc0202518:	00092783          	lw	a5,0(s2) # fffffffffff80000 <end+0x3fccd734>
ffffffffc020251c:	fff7869b          	addiw	a3,a5,-1
ffffffffc0202520:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) ==
ffffffffc0202524:	c691                	beqz	a3,ffffffffc0202530 <page_insert+0xaa>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202526:	120a0073          	sfence.vma	s4
}
ffffffffc020252a:	bf59                	j	ffffffffc02024c0 <page_insert+0x3a>
ffffffffc020252c:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc020252e:	bf49                	j	ffffffffc02024c0 <page_insert+0x3a>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202530:	100027f3          	csrr	a5,sstatus
ffffffffc0202534:	8b89                	andi	a5,a5,2
ffffffffc0202536:	ef91                	bnez	a5,ffffffffc0202552 <page_insert+0xcc>
        pmm_manager->free_pages(base, n);
ffffffffc0202538:	000b0797          	auipc	a5,0xb0
ffffffffc020253c:	3407b783          	ld	a5,832(a5) # ffffffffc02b2878 <pmm_manager>
ffffffffc0202540:	739c                	ld	a5,32(a5)
ffffffffc0202542:	4585                	li	a1,1
ffffffffc0202544:	854a                	mv	a0,s2
ffffffffc0202546:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc0202548:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020254c:	120a0073          	sfence.vma	s4
ffffffffc0202550:	bf85                	j	ffffffffc02024c0 <page_insert+0x3a>
        intr_disable();
ffffffffc0202552:	8f4fe0ef          	jal	ra,ffffffffc0200646 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202556:	000b0797          	auipc	a5,0xb0
ffffffffc020255a:	3227b783          	ld	a5,802(a5) # ffffffffc02b2878 <pmm_manager>
ffffffffc020255e:	739c                	ld	a5,32(a5)
ffffffffc0202560:	4585                	li	a1,1
ffffffffc0202562:	854a                	mv	a0,s2
ffffffffc0202564:	9782                	jalr	a5
        intr_enable();
ffffffffc0202566:	8dafe0ef          	jal	ra,ffffffffc0200640 <intr_enable>
ffffffffc020256a:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020256e:	120a0073          	sfence.vma	s4
ffffffffc0202572:	b7b9                	j	ffffffffc02024c0 <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc0202574:	5571                	li	a0,-4
ffffffffc0202576:	b79d                	j	ffffffffc02024dc <page_insert+0x56>
ffffffffc0202578:	f30ff0ef          	jal	ra,ffffffffc0201ca8 <pa2page.part.0>

ffffffffc020257c <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc020257c:	00005797          	auipc	a5,0x5
ffffffffc0202580:	cac78793          	addi	a5,a5,-852 # ffffffffc0207228 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202584:	638c                	ld	a1,0(a5)
void pmm_init(void) {
ffffffffc0202586:	711d                	addi	sp,sp,-96
ffffffffc0202588:	ec5e                	sd	s7,24(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020258a:	00005517          	auipc	a0,0x5
ffffffffc020258e:	e4650513          	addi	a0,a0,-442 # ffffffffc02073d0 <default_pmm_manager+0x1a8>
    pmm_manager = &default_pmm_manager;
ffffffffc0202592:	000b0b97          	auipc	s7,0xb0
ffffffffc0202596:	2e6b8b93          	addi	s7,s7,742 # ffffffffc02b2878 <pmm_manager>
void pmm_init(void) {
ffffffffc020259a:	ec86                	sd	ra,88(sp)
ffffffffc020259c:	e4a6                	sd	s1,72(sp)
ffffffffc020259e:	fc4e                	sd	s3,56(sp)
ffffffffc02025a0:	f05a                	sd	s6,32(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc02025a2:	00fbb023          	sd	a5,0(s7)
void pmm_init(void) {
ffffffffc02025a6:	e8a2                	sd	s0,80(sp)
ffffffffc02025a8:	e0ca                	sd	s2,64(sp)
ffffffffc02025aa:	f852                	sd	s4,48(sp)
ffffffffc02025ac:	f456                	sd	s5,40(sp)
ffffffffc02025ae:	e862                	sd	s8,16(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02025b0:	bd1fd0ef          	jal	ra,ffffffffc0200180 <cprintf>
    pmm_manager->init();
ffffffffc02025b4:	000bb783          	ld	a5,0(s7)
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc02025b8:	000b0997          	auipc	s3,0xb0
ffffffffc02025bc:	2c898993          	addi	s3,s3,712 # ffffffffc02b2880 <va_pa_offset>
    npage = maxpa / PGSIZE;
ffffffffc02025c0:	000b0497          	auipc	s1,0xb0
ffffffffc02025c4:	2a848493          	addi	s1,s1,680 # ffffffffc02b2868 <npage>
    pmm_manager->init();
ffffffffc02025c8:	679c                	ld	a5,8(a5)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02025ca:	000b0b17          	auipc	s6,0xb0
ffffffffc02025ce:	2a6b0b13          	addi	s6,s6,678 # ffffffffc02b2870 <pages>
    pmm_manager->init();
ffffffffc02025d2:	9782                	jalr	a5
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc02025d4:	57f5                	li	a5,-3
ffffffffc02025d6:	07fa                	slli	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc02025d8:	00005517          	auipc	a0,0x5
ffffffffc02025dc:	e1050513          	addi	a0,a0,-496 # ffffffffc02073e8 <default_pmm_manager+0x1c0>
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc02025e0:	00f9b023          	sd	a5,0(s3)
    cprintf("physcial memory map:\n");
ffffffffc02025e4:	b9dfd0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc02025e8:	46c5                	li	a3,17
ffffffffc02025ea:	06ee                	slli	a3,a3,0x1b
ffffffffc02025ec:	40100613          	li	a2,1025
ffffffffc02025f0:	07e005b7          	lui	a1,0x7e00
ffffffffc02025f4:	16fd                	addi	a3,a3,-1
ffffffffc02025f6:	0656                	slli	a2,a2,0x15
ffffffffc02025f8:	00005517          	auipc	a0,0x5
ffffffffc02025fc:	e0850513          	addi	a0,a0,-504 # ffffffffc0207400 <default_pmm_manager+0x1d8>
ffffffffc0202600:	b81fd0ef          	jal	ra,ffffffffc0200180 <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202604:	777d                	lui	a4,0xfffff
ffffffffc0202606:	000b1797          	auipc	a5,0xb1
ffffffffc020260a:	2c578793          	addi	a5,a5,709 # ffffffffc02b38cb <end+0xfff>
ffffffffc020260e:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc0202610:	00088737          	lui	a4,0x88
ffffffffc0202614:	e098                	sd	a4,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202616:	00fb3023          	sd	a5,0(s6)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020261a:	4701                	li	a4,0
ffffffffc020261c:	4585                	li	a1,1
ffffffffc020261e:	fff80837          	lui	a6,0xfff80
ffffffffc0202622:	a019                	j	ffffffffc0202628 <pmm_init+0xac>
        SetPageReserved(pages + i);
ffffffffc0202624:	000b3783          	ld	a5,0(s6)
ffffffffc0202628:	00671693          	slli	a3,a4,0x6
ffffffffc020262c:	97b6                	add	a5,a5,a3
ffffffffc020262e:	07a1                	addi	a5,a5,8
ffffffffc0202630:	40b7b02f          	amoor.d	zero,a1,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0202634:	6090                	ld	a2,0(s1)
ffffffffc0202636:	0705                	addi	a4,a4,1
ffffffffc0202638:	010607b3          	add	a5,a2,a6
ffffffffc020263c:	fef764e3          	bltu	a4,a5,ffffffffc0202624 <pmm_init+0xa8>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202640:	000b3503          	ld	a0,0(s6)
ffffffffc0202644:	079a                	slli	a5,a5,0x6
ffffffffc0202646:	c0200737          	lui	a4,0xc0200
ffffffffc020264a:	00f506b3          	add	a3,a0,a5
ffffffffc020264e:	60e6e563          	bltu	a3,a4,ffffffffc0202c58 <pmm_init+0x6dc>
ffffffffc0202652:	0009b583          	ld	a1,0(s3)
    if (freemem < mem_end) {
ffffffffc0202656:	4745                	li	a4,17
ffffffffc0202658:	076e                	slli	a4,a4,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020265a:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end) {
ffffffffc020265c:	4ae6e563          	bltu	a3,a4,ffffffffc0202b06 <pmm_init+0x58a>
    cprintf("vapaofset is %llu\n",va_pa_offset);
ffffffffc0202660:	00005517          	auipc	a0,0x5
ffffffffc0202664:	dc850513          	addi	a0,a0,-568 # ffffffffc0207428 <default_pmm_manager+0x200>
ffffffffc0202668:	b19fd0ef          	jal	ra,ffffffffc0200180 <cprintf>

    return page;
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc020266c:	000bb783          	ld	a5,0(s7)
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc0202670:	000b0917          	auipc	s2,0xb0
ffffffffc0202674:	1f090913          	addi	s2,s2,496 # ffffffffc02b2860 <boot_pgdir>
    pmm_manager->check();
ffffffffc0202678:	7b9c                	ld	a5,48(a5)
ffffffffc020267a:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc020267c:	00005517          	auipc	a0,0x5
ffffffffc0202680:	dc450513          	addi	a0,a0,-572 # ffffffffc0207440 <default_pmm_manager+0x218>
ffffffffc0202684:	afdfd0ef          	jal	ra,ffffffffc0200180 <cprintf>
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc0202688:	00009697          	auipc	a3,0x9
ffffffffc020268c:	97868693          	addi	a3,a3,-1672 # ffffffffc020b000 <boot_page_table_sv39>
ffffffffc0202690:	00d93023          	sd	a3,0(s2)
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc0202694:	c02007b7          	lui	a5,0xc0200
ffffffffc0202698:	5cf6ec63          	bltu	a3,a5,ffffffffc0202c70 <pmm_init+0x6f4>
ffffffffc020269c:	0009b783          	ld	a5,0(s3)
ffffffffc02026a0:	8e9d                	sub	a3,a3,a5
ffffffffc02026a2:	000b0797          	auipc	a5,0xb0
ffffffffc02026a6:	1ad7bb23          	sd	a3,438(a5) # ffffffffc02b2858 <boot_cr3>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02026aa:	100027f3          	csrr	a5,sstatus
ffffffffc02026ae:	8b89                	andi	a5,a5,2
ffffffffc02026b0:	48079263          	bnez	a5,ffffffffc0202b34 <pmm_init+0x5b8>
        ret = pmm_manager->nr_free_pages();
ffffffffc02026b4:	000bb783          	ld	a5,0(s7)
ffffffffc02026b8:	779c                	ld	a5,40(a5)
ffffffffc02026ba:	9782                	jalr	a5
ffffffffc02026bc:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store=nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02026be:	6098                	ld	a4,0(s1)
ffffffffc02026c0:	c80007b7          	lui	a5,0xc8000
ffffffffc02026c4:	83b1                	srli	a5,a5,0xc
ffffffffc02026c6:	5ee7e163          	bltu	a5,a4,ffffffffc0202ca8 <pmm_init+0x72c>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc02026ca:	00093503          	ld	a0,0(s2)
ffffffffc02026ce:	5a050d63          	beqz	a0,ffffffffc0202c88 <pmm_init+0x70c>
ffffffffc02026d2:	03451793          	slli	a5,a0,0x34
ffffffffc02026d6:	5a079963          	bnez	a5,ffffffffc0202c88 <pmm_init+0x70c>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc02026da:	4601                	li	a2,0
ffffffffc02026dc:	4581                	li	a1,0
ffffffffc02026de:	8e1ff0ef          	jal	ra,ffffffffc0201fbe <get_page>
ffffffffc02026e2:	62051563          	bnez	a0,ffffffffc0202d0c <pmm_init+0x790>

    struct Page *p1, *p2;
    p1 = alloc_page();
ffffffffc02026e6:	4505                	li	a0,1
ffffffffc02026e8:	df8ff0ef          	jal	ra,ffffffffc0201ce0 <alloc_pages>
ffffffffc02026ec:	8a2a                	mv	s4,a0
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc02026ee:	00093503          	ld	a0,0(s2)
ffffffffc02026f2:	4681                	li	a3,0
ffffffffc02026f4:	4601                	li	a2,0
ffffffffc02026f6:	85d2                	mv	a1,s4
ffffffffc02026f8:	d8fff0ef          	jal	ra,ffffffffc0202486 <page_insert>
ffffffffc02026fc:	5e051863          	bnez	a0,ffffffffc0202cec <pmm_init+0x770>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc0202700:	00093503          	ld	a0,0(s2)
ffffffffc0202704:	4601                	li	a2,0
ffffffffc0202706:	4581                	li	a1,0
ffffffffc0202708:	ee4ff0ef          	jal	ra,ffffffffc0201dec <get_pte>
ffffffffc020270c:	5c050063          	beqz	a0,ffffffffc0202ccc <pmm_init+0x750>
    assert(pte2page(*ptep) == p1);
ffffffffc0202710:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0202712:	0017f713          	andi	a4,a5,1
ffffffffc0202716:	5a070963          	beqz	a4,ffffffffc0202cc8 <pmm_init+0x74c>
    if (PPN(pa) >= npage) {
ffffffffc020271a:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc020271c:	078a                	slli	a5,a5,0x2
ffffffffc020271e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202720:	52e7fa63          	bgeu	a5,a4,ffffffffc0202c54 <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc0202724:	000b3683          	ld	a3,0(s6)
ffffffffc0202728:	fff80637          	lui	a2,0xfff80
ffffffffc020272c:	97b2                	add	a5,a5,a2
ffffffffc020272e:	079a                	slli	a5,a5,0x6
ffffffffc0202730:	97b6                	add	a5,a5,a3
ffffffffc0202732:	10fa16e3          	bne	s4,a5,ffffffffc020303e <pmm_init+0xac2>
    assert(page_ref(p1) == 1);
ffffffffc0202736:	000a2683          	lw	a3,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bb8>
ffffffffc020273a:	4785                	li	a5,1
ffffffffc020273c:	12f69de3          	bne	a3,a5,ffffffffc0203076 <pmm_init+0xafa>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc0202740:	00093503          	ld	a0,0(s2)
ffffffffc0202744:	77fd                	lui	a5,0xfffff
ffffffffc0202746:	6114                	ld	a3,0(a0)
ffffffffc0202748:	068a                	slli	a3,a3,0x2
ffffffffc020274a:	8efd                	and	a3,a3,a5
ffffffffc020274c:	00c6d613          	srli	a2,a3,0xc
ffffffffc0202750:	10e677e3          	bgeu	a2,a4,ffffffffc020305e <pmm_init+0xae2>
ffffffffc0202754:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202758:	96e2                	add	a3,a3,s8
ffffffffc020275a:	0006ba83          	ld	s5,0(a3)
ffffffffc020275e:	0a8a                	slli	s5,s5,0x2
ffffffffc0202760:	00fafab3          	and	s5,s5,a5
ffffffffc0202764:	00cad793          	srli	a5,s5,0xc
ffffffffc0202768:	62e7f263          	bgeu	a5,a4,ffffffffc0202d8c <pmm_init+0x810>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc020276c:	4601                	li	a2,0
ffffffffc020276e:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202770:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0202772:	e7aff0ef          	jal	ra,ffffffffc0201dec <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202776:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0202778:	5f551a63          	bne	a0,s5,ffffffffc0202d6c <pmm_init+0x7f0>

    p2 = alloc_page();
ffffffffc020277c:	4505                	li	a0,1
ffffffffc020277e:	d62ff0ef          	jal	ra,ffffffffc0201ce0 <alloc_pages>
ffffffffc0202782:	8aaa                	mv	s5,a0
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202784:	00093503          	ld	a0,0(s2)
ffffffffc0202788:	46d1                	li	a3,20
ffffffffc020278a:	6605                	lui	a2,0x1
ffffffffc020278c:	85d6                	mv	a1,s5
ffffffffc020278e:	cf9ff0ef          	jal	ra,ffffffffc0202486 <page_insert>
ffffffffc0202792:	58051d63          	bnez	a0,ffffffffc0202d2c <pmm_init+0x7b0>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0202796:	00093503          	ld	a0,0(s2)
ffffffffc020279a:	4601                	li	a2,0
ffffffffc020279c:	6585                	lui	a1,0x1
ffffffffc020279e:	e4eff0ef          	jal	ra,ffffffffc0201dec <get_pte>
ffffffffc02027a2:	0e050ae3          	beqz	a0,ffffffffc0203096 <pmm_init+0xb1a>
    assert(*ptep & PTE_U);
ffffffffc02027a6:	611c                	ld	a5,0(a0)
ffffffffc02027a8:	0107f713          	andi	a4,a5,16
ffffffffc02027ac:	6e070d63          	beqz	a4,ffffffffc0202ea6 <pmm_init+0x92a>
    assert(*ptep & PTE_W);
ffffffffc02027b0:	8b91                	andi	a5,a5,4
ffffffffc02027b2:	6a078a63          	beqz	a5,ffffffffc0202e66 <pmm_init+0x8ea>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc02027b6:	00093503          	ld	a0,0(s2)
ffffffffc02027ba:	611c                	ld	a5,0(a0)
ffffffffc02027bc:	8bc1                	andi	a5,a5,16
ffffffffc02027be:	68078463          	beqz	a5,ffffffffc0202e46 <pmm_init+0x8ca>
    assert(page_ref(p2) == 1);
ffffffffc02027c2:	000aa703          	lw	a4,0(s5)
ffffffffc02027c6:	4785                	li	a5,1
ffffffffc02027c8:	58f71263          	bne	a4,a5,ffffffffc0202d4c <pmm_init+0x7d0>

    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc02027cc:	4681                	li	a3,0
ffffffffc02027ce:	6605                	lui	a2,0x1
ffffffffc02027d0:	85d2                	mv	a1,s4
ffffffffc02027d2:	cb5ff0ef          	jal	ra,ffffffffc0202486 <page_insert>
ffffffffc02027d6:	62051863          	bnez	a0,ffffffffc0202e06 <pmm_init+0x88a>
    assert(page_ref(p1) == 2);
ffffffffc02027da:	000a2703          	lw	a4,0(s4)
ffffffffc02027de:	4789                	li	a5,2
ffffffffc02027e0:	60f71363          	bne	a4,a5,ffffffffc0202de6 <pmm_init+0x86a>
    assert(page_ref(p2) == 0);
ffffffffc02027e4:	000aa783          	lw	a5,0(s5)
ffffffffc02027e8:	5c079f63          	bnez	a5,ffffffffc0202dc6 <pmm_init+0x84a>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc02027ec:	00093503          	ld	a0,0(s2)
ffffffffc02027f0:	4601                	li	a2,0
ffffffffc02027f2:	6585                	lui	a1,0x1
ffffffffc02027f4:	df8ff0ef          	jal	ra,ffffffffc0201dec <get_pte>
ffffffffc02027f8:	5a050763          	beqz	a0,ffffffffc0202da6 <pmm_init+0x82a>
    assert(pte2page(*ptep) == p1);
ffffffffc02027fc:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc02027fe:	00177793          	andi	a5,a4,1
ffffffffc0202802:	4c078363          	beqz	a5,ffffffffc0202cc8 <pmm_init+0x74c>
    if (PPN(pa) >= npage) {
ffffffffc0202806:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202808:	00271793          	slli	a5,a4,0x2
ffffffffc020280c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020280e:	44d7f363          	bgeu	a5,a3,ffffffffc0202c54 <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc0202812:	000b3683          	ld	a3,0(s6)
ffffffffc0202816:	fff80637          	lui	a2,0xfff80
ffffffffc020281a:	97b2                	add	a5,a5,a2
ffffffffc020281c:	079a                	slli	a5,a5,0x6
ffffffffc020281e:	97b6                	add	a5,a5,a3
ffffffffc0202820:	6efa1363          	bne	s4,a5,ffffffffc0202f06 <pmm_init+0x98a>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202824:	8b41                	andi	a4,a4,16
ffffffffc0202826:	6c071063          	bnez	a4,ffffffffc0202ee6 <pmm_init+0x96a>

    page_remove(boot_pgdir, 0x0);
ffffffffc020282a:	00093503          	ld	a0,0(s2)
ffffffffc020282e:	4581                	li	a1,0
ffffffffc0202830:	bbbff0ef          	jal	ra,ffffffffc02023ea <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202834:	000a2703          	lw	a4,0(s4)
ffffffffc0202838:	4785                	li	a5,1
ffffffffc020283a:	68f71663          	bne	a4,a5,ffffffffc0202ec6 <pmm_init+0x94a>
    assert(page_ref(p2) == 0);
ffffffffc020283e:	000aa783          	lw	a5,0(s5)
ffffffffc0202842:	74079e63          	bnez	a5,ffffffffc0202f9e <pmm_init+0xa22>

    page_remove(boot_pgdir, PGSIZE);
ffffffffc0202846:	00093503          	ld	a0,0(s2)
ffffffffc020284a:	6585                	lui	a1,0x1
ffffffffc020284c:	b9fff0ef          	jal	ra,ffffffffc02023ea <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0202850:	000a2783          	lw	a5,0(s4)
ffffffffc0202854:	72079563          	bnez	a5,ffffffffc0202f7e <pmm_init+0xa02>
    assert(page_ref(p2) == 0);
ffffffffc0202858:	000aa783          	lw	a5,0(s5)
ffffffffc020285c:	70079163          	bnez	a5,ffffffffc0202f5e <pmm_init+0x9e2>

    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc0202860:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc0202864:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202866:	000a3683          	ld	a3,0(s4)
ffffffffc020286a:	068a                	slli	a3,a3,0x2
ffffffffc020286c:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage) {
ffffffffc020286e:	3ee6f363          	bgeu	a3,a4,ffffffffc0202c54 <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc0202872:	fff807b7          	lui	a5,0xfff80
ffffffffc0202876:	000b3503          	ld	a0,0(s6)
ffffffffc020287a:	96be                	add	a3,a3,a5
ffffffffc020287c:	069a                	slli	a3,a3,0x6
    return page->ref;
ffffffffc020287e:	00d507b3          	add	a5,a0,a3
ffffffffc0202882:	4390                	lw	a2,0(a5)
ffffffffc0202884:	4785                	li	a5,1
ffffffffc0202886:	6af61c63          	bne	a2,a5,ffffffffc0202f3e <pmm_init+0x9c2>
    return page - pages + nbase;
ffffffffc020288a:	8699                	srai	a3,a3,0x6
ffffffffc020288c:	000805b7          	lui	a1,0x80
ffffffffc0202890:	96ae                	add	a3,a3,a1
    return KADDR(page2pa(page));
ffffffffc0202892:	00c69613          	slli	a2,a3,0xc
ffffffffc0202896:	8231                	srli	a2,a2,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202898:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020289a:	68e67663          	bgeu	a2,a4,ffffffffc0202f26 <pmm_init+0x9aa>

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
    free_page(pde2page(pd0[0]));
ffffffffc020289e:	0009b603          	ld	a2,0(s3)
ffffffffc02028a2:	96b2                	add	a3,a3,a2
    return pa2page(PDE_ADDR(pde));
ffffffffc02028a4:	629c                	ld	a5,0(a3)
ffffffffc02028a6:	078a                	slli	a5,a5,0x2
ffffffffc02028a8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02028aa:	3ae7f563          	bgeu	a5,a4,ffffffffc0202c54 <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc02028ae:	8f8d                	sub	a5,a5,a1
ffffffffc02028b0:	079a                	slli	a5,a5,0x6
ffffffffc02028b2:	953e                	add	a0,a0,a5
ffffffffc02028b4:	100027f3          	csrr	a5,sstatus
ffffffffc02028b8:	8b89                	andi	a5,a5,2
ffffffffc02028ba:	2c079763          	bnez	a5,ffffffffc0202b88 <pmm_init+0x60c>
        pmm_manager->free_pages(base, n);
ffffffffc02028be:	000bb783          	ld	a5,0(s7)
ffffffffc02028c2:	4585                	li	a1,1
ffffffffc02028c4:	739c                	ld	a5,32(a5)
ffffffffc02028c6:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc02028c8:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage) {
ffffffffc02028cc:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02028ce:	078a                	slli	a5,a5,0x2
ffffffffc02028d0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02028d2:	38e7f163          	bgeu	a5,a4,ffffffffc0202c54 <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc02028d6:	000b3503          	ld	a0,0(s6)
ffffffffc02028da:	fff80737          	lui	a4,0xfff80
ffffffffc02028de:	97ba                	add	a5,a5,a4
ffffffffc02028e0:	079a                	slli	a5,a5,0x6
ffffffffc02028e2:	953e                	add	a0,a0,a5
ffffffffc02028e4:	100027f3          	csrr	a5,sstatus
ffffffffc02028e8:	8b89                	andi	a5,a5,2
ffffffffc02028ea:	28079363          	bnez	a5,ffffffffc0202b70 <pmm_init+0x5f4>
ffffffffc02028ee:	000bb783          	ld	a5,0(s7)
ffffffffc02028f2:	4585                	li	a1,1
ffffffffc02028f4:	739c                	ld	a5,32(a5)
ffffffffc02028f6:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir[0] = 0;
ffffffffc02028f8:	00093783          	ld	a5,0(s2)
ffffffffc02028fc:	0007b023          	sd	zero,0(a5) # fffffffffff80000 <end+0x3fccd734>
  asm volatile("sfence.vma");
ffffffffc0202900:	12000073          	sfence.vma
ffffffffc0202904:	100027f3          	csrr	a5,sstatus
ffffffffc0202908:	8b89                	andi	a5,a5,2
ffffffffc020290a:	24079963          	bnez	a5,ffffffffc0202b5c <pmm_init+0x5e0>
        ret = pmm_manager->nr_free_pages();
ffffffffc020290e:	000bb783          	ld	a5,0(s7)
ffffffffc0202912:	779c                	ld	a5,40(a5)
ffffffffc0202914:	9782                	jalr	a5
ffffffffc0202916:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store==nr_free_pages());
ffffffffc0202918:	71441363          	bne	s0,s4,ffffffffc020301e <pmm_init+0xaa2>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc020291c:	00005517          	auipc	a0,0x5
ffffffffc0202920:	e0c50513          	addi	a0,a0,-500 # ffffffffc0207728 <default_pmm_manager+0x500>
ffffffffc0202924:	85dfd0ef          	jal	ra,ffffffffc0200180 <cprintf>
ffffffffc0202928:	100027f3          	csrr	a5,sstatus
ffffffffc020292c:	8b89                	andi	a5,a5,2
ffffffffc020292e:	20079d63          	bnez	a5,ffffffffc0202b48 <pmm_init+0x5cc>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202932:	000bb783          	ld	a5,0(s7)
ffffffffc0202936:	779c                	ld	a5,40(a5)
ffffffffc0202938:	9782                	jalr	a5
ffffffffc020293a:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store=nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc020293c:	6098                	ld	a4,0(s1)
ffffffffc020293e:	c0200437          	lui	s0,0xc0200
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202942:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc0202944:	00c71793          	slli	a5,a4,0xc
ffffffffc0202948:	6a05                	lui	s4,0x1
ffffffffc020294a:	02f47c63          	bgeu	s0,a5,ffffffffc0202982 <pmm_init+0x406>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc020294e:	00c45793          	srli	a5,s0,0xc
ffffffffc0202952:	00093503          	ld	a0,0(s2)
ffffffffc0202956:	2ee7f263          	bgeu	a5,a4,ffffffffc0202c3a <pmm_init+0x6be>
ffffffffc020295a:	0009b583          	ld	a1,0(s3)
ffffffffc020295e:	4601                	li	a2,0
ffffffffc0202960:	95a2                	add	a1,a1,s0
ffffffffc0202962:	c8aff0ef          	jal	ra,ffffffffc0201dec <get_pte>
ffffffffc0202966:	2a050a63          	beqz	a0,ffffffffc0202c1a <pmm_init+0x69e>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc020296a:	611c                	ld	a5,0(a0)
ffffffffc020296c:	078a                	slli	a5,a5,0x2
ffffffffc020296e:	0157f7b3          	and	a5,a5,s5
ffffffffc0202972:	28879463          	bne	a5,s0,ffffffffc0202bfa <pmm_init+0x67e>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc0202976:	6098                	ld	a4,0(s1)
ffffffffc0202978:	9452                	add	s0,s0,s4
ffffffffc020297a:	00c71793          	slli	a5,a4,0xc
ffffffffc020297e:	fcf468e3          	bltu	s0,a5,ffffffffc020294e <pmm_init+0x3d2>
    }


    assert(boot_pgdir[0] == 0);
ffffffffc0202982:	00093783          	ld	a5,0(s2)
ffffffffc0202986:	639c                	ld	a5,0(a5)
ffffffffc0202988:	66079b63          	bnez	a5,ffffffffc0202ffe <pmm_init+0xa82>

    struct Page *p;
    p = alloc_page();
ffffffffc020298c:	4505                	li	a0,1
ffffffffc020298e:	b52ff0ef          	jal	ra,ffffffffc0201ce0 <alloc_pages>
ffffffffc0202992:	8aaa                	mv	s5,a0
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202994:	00093503          	ld	a0,0(s2)
ffffffffc0202998:	4699                	li	a3,6
ffffffffc020299a:	10000613          	li	a2,256
ffffffffc020299e:	85d6                	mv	a1,s5
ffffffffc02029a0:	ae7ff0ef          	jal	ra,ffffffffc0202486 <page_insert>
ffffffffc02029a4:	62051d63          	bnez	a0,ffffffffc0202fde <pmm_init+0xa62>
    assert(page_ref(p) == 1);
ffffffffc02029a8:	000aa703          	lw	a4,0(s5) # fffffffffffff000 <end+0x3fd4c734>
ffffffffc02029ac:	4785                	li	a5,1
ffffffffc02029ae:	60f71863          	bne	a4,a5,ffffffffc0202fbe <pmm_init+0xa42>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc02029b2:	00093503          	ld	a0,0(s2)
ffffffffc02029b6:	6405                	lui	s0,0x1
ffffffffc02029b8:	4699                	li	a3,6
ffffffffc02029ba:	10040613          	addi	a2,s0,256 # 1100 <_binary_obj___user_faultread_out_size-0x8ab8>
ffffffffc02029be:	85d6                	mv	a1,s5
ffffffffc02029c0:	ac7ff0ef          	jal	ra,ffffffffc0202486 <page_insert>
ffffffffc02029c4:	46051163          	bnez	a0,ffffffffc0202e26 <pmm_init+0x8aa>
    assert(page_ref(p) == 2);
ffffffffc02029c8:	000aa703          	lw	a4,0(s5)
ffffffffc02029cc:	4789                	li	a5,2
ffffffffc02029ce:	72f71463          	bne	a4,a5,ffffffffc02030f6 <pmm_init+0xb7a>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc02029d2:	00005597          	auipc	a1,0x5
ffffffffc02029d6:	e8e58593          	addi	a1,a1,-370 # ffffffffc0207860 <default_pmm_manager+0x638>
ffffffffc02029da:	10000513          	li	a0,256
ffffffffc02029de:	289030ef          	jal	ra,ffffffffc0206466 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc02029e2:	10040593          	addi	a1,s0,256
ffffffffc02029e6:	10000513          	li	a0,256
ffffffffc02029ea:	28f030ef          	jal	ra,ffffffffc0206478 <strcmp>
ffffffffc02029ee:	6e051463          	bnez	a0,ffffffffc02030d6 <pmm_init+0xb5a>
    return page - pages + nbase;
ffffffffc02029f2:	000b3683          	ld	a3,0(s6)
ffffffffc02029f6:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc02029fa:	547d                	li	s0,-1
    return page - pages + nbase;
ffffffffc02029fc:	40da86b3          	sub	a3,s5,a3
ffffffffc0202a00:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0202a02:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc0202a04:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0202a06:	8031                	srli	s0,s0,0xc
ffffffffc0202a08:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc0202a0c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202a0e:	50f77c63          	bgeu	a4,a5,ffffffffc0202f26 <pmm_init+0x9aa>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202a12:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202a16:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202a1a:	96be                	add	a3,a3,a5
ffffffffc0202a1c:	10068023          	sb	zero,256(a3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202a20:	211030ef          	jal	ra,ffffffffc0206430 <strlen>
ffffffffc0202a24:	68051963          	bnez	a0,ffffffffc02030b6 <pmm_init+0xb3a>

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
ffffffffc0202a28:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc0202a2c:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a2e:	000a3683          	ld	a3,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bb8>
ffffffffc0202a32:	068a                	slli	a3,a3,0x2
ffffffffc0202a34:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202a36:	20f6ff63          	bgeu	a3,a5,ffffffffc0202c54 <pmm_init+0x6d8>
    return KADDR(page2pa(page));
ffffffffc0202a3a:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0202a3c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202a3e:	4ef47463          	bgeu	s0,a5,ffffffffc0202f26 <pmm_init+0x9aa>
ffffffffc0202a42:	0009b403          	ld	s0,0(s3)
ffffffffc0202a46:	9436                	add	s0,s0,a3
ffffffffc0202a48:	100027f3          	csrr	a5,sstatus
ffffffffc0202a4c:	8b89                	andi	a5,a5,2
ffffffffc0202a4e:	18079b63          	bnez	a5,ffffffffc0202be4 <pmm_init+0x668>
        pmm_manager->free_pages(base, n);
ffffffffc0202a52:	000bb783          	ld	a5,0(s7)
ffffffffc0202a56:	4585                	li	a1,1
ffffffffc0202a58:	8556                	mv	a0,s5
ffffffffc0202a5a:	739c                	ld	a5,32(a5)
ffffffffc0202a5c:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a5e:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage) {
ffffffffc0202a60:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a62:	078a                	slli	a5,a5,0x2
ffffffffc0202a64:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202a66:	1ee7f763          	bgeu	a5,a4,ffffffffc0202c54 <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a6a:	000b3503          	ld	a0,0(s6)
ffffffffc0202a6e:	fff80737          	lui	a4,0xfff80
ffffffffc0202a72:	97ba                	add	a5,a5,a4
ffffffffc0202a74:	079a                	slli	a5,a5,0x6
ffffffffc0202a76:	953e                	add	a0,a0,a5
ffffffffc0202a78:	100027f3          	csrr	a5,sstatus
ffffffffc0202a7c:	8b89                	andi	a5,a5,2
ffffffffc0202a7e:	14079763          	bnez	a5,ffffffffc0202bcc <pmm_init+0x650>
ffffffffc0202a82:	000bb783          	ld	a5,0(s7)
ffffffffc0202a86:	4585                	li	a1,1
ffffffffc0202a88:	739c                	ld	a5,32(a5)
ffffffffc0202a8a:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a8c:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage) {
ffffffffc0202a90:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a92:	078a                	slli	a5,a5,0x2
ffffffffc0202a94:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202a96:	1ae7ff63          	bgeu	a5,a4,ffffffffc0202c54 <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a9a:	000b3503          	ld	a0,0(s6)
ffffffffc0202a9e:	fff80737          	lui	a4,0xfff80
ffffffffc0202aa2:	97ba                	add	a5,a5,a4
ffffffffc0202aa4:	079a                	slli	a5,a5,0x6
ffffffffc0202aa6:	953e                	add	a0,a0,a5
ffffffffc0202aa8:	100027f3          	csrr	a5,sstatus
ffffffffc0202aac:	8b89                	andi	a5,a5,2
ffffffffc0202aae:	10079363          	bnez	a5,ffffffffc0202bb4 <pmm_init+0x638>
ffffffffc0202ab2:	000bb783          	ld	a5,0(s7)
ffffffffc0202ab6:	4585                	li	a1,1
ffffffffc0202ab8:	739c                	ld	a5,32(a5)
ffffffffc0202aba:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir[0] = 0;
ffffffffc0202abc:	00093783          	ld	a5,0(s2)
ffffffffc0202ac0:	0007b023          	sd	zero,0(a5)
  asm volatile("sfence.vma");
ffffffffc0202ac4:	12000073          	sfence.vma
ffffffffc0202ac8:	100027f3          	csrr	a5,sstatus
ffffffffc0202acc:	8b89                	andi	a5,a5,2
ffffffffc0202ace:	0c079963          	bnez	a5,ffffffffc0202ba0 <pmm_init+0x624>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202ad2:	000bb783          	ld	a5,0(s7)
ffffffffc0202ad6:	779c                	ld	a5,40(a5)
ffffffffc0202ad8:	9782                	jalr	a5
ffffffffc0202ada:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store==nr_free_pages());
ffffffffc0202adc:	3a8c1563          	bne	s8,s0,ffffffffc0202e86 <pmm_init+0x90a>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202ae0:	00005517          	auipc	a0,0x5
ffffffffc0202ae4:	df850513          	addi	a0,a0,-520 # ffffffffc02078d8 <default_pmm_manager+0x6b0>
ffffffffc0202ae8:	e98fd0ef          	jal	ra,ffffffffc0200180 <cprintf>
}
ffffffffc0202aec:	6446                	ld	s0,80(sp)
ffffffffc0202aee:	60e6                	ld	ra,88(sp)
ffffffffc0202af0:	64a6                	ld	s1,72(sp)
ffffffffc0202af2:	6906                	ld	s2,64(sp)
ffffffffc0202af4:	79e2                	ld	s3,56(sp)
ffffffffc0202af6:	7a42                	ld	s4,48(sp)
ffffffffc0202af8:	7aa2                	ld	s5,40(sp)
ffffffffc0202afa:	7b02                	ld	s6,32(sp)
ffffffffc0202afc:	6be2                	ld	s7,24(sp)
ffffffffc0202afe:	6c42                	ld	s8,16(sp)
ffffffffc0202b00:	6125                	addi	sp,sp,96
    kmalloc_init();
ffffffffc0202b02:	fddfe06f          	j	ffffffffc0201ade <kmalloc_init>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0202b06:	6785                	lui	a5,0x1
ffffffffc0202b08:	17fd                	addi	a5,a5,-1
ffffffffc0202b0a:	96be                	add	a3,a3,a5
ffffffffc0202b0c:	77fd                	lui	a5,0xfffff
ffffffffc0202b0e:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage) {
ffffffffc0202b10:	00c7d693          	srli	a3,a5,0xc
ffffffffc0202b14:	14c6f063          	bgeu	a3,a2,ffffffffc0202c54 <pmm_init+0x6d8>
    pmm_manager->init_memmap(base, n);
ffffffffc0202b18:	000bb603          	ld	a2,0(s7)
    return &pages[PPN(pa) - nbase];
ffffffffc0202b1c:	96c2                	add	a3,a3,a6
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202b1e:	40f707b3          	sub	a5,a4,a5
    pmm_manager->init_memmap(base, n);
ffffffffc0202b22:	6a10                	ld	a2,16(a2)
ffffffffc0202b24:	069a                	slli	a3,a3,0x6
ffffffffc0202b26:	00c7d593          	srli	a1,a5,0xc
ffffffffc0202b2a:	9536                	add	a0,a0,a3
ffffffffc0202b2c:	9602                	jalr	a2
    cprintf("vapaofset is %llu\n",va_pa_offset);
ffffffffc0202b2e:	0009b583          	ld	a1,0(s3)
}
ffffffffc0202b32:	b63d                	j	ffffffffc0202660 <pmm_init+0xe4>
        intr_disable();
ffffffffc0202b34:	b13fd0ef          	jal	ra,ffffffffc0200646 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202b38:	000bb783          	ld	a5,0(s7)
ffffffffc0202b3c:	779c                	ld	a5,40(a5)
ffffffffc0202b3e:	9782                	jalr	a5
ffffffffc0202b40:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202b42:	afffd0ef          	jal	ra,ffffffffc0200640 <intr_enable>
ffffffffc0202b46:	bea5                	j	ffffffffc02026be <pmm_init+0x142>
        intr_disable();
ffffffffc0202b48:	afffd0ef          	jal	ra,ffffffffc0200646 <intr_disable>
ffffffffc0202b4c:	000bb783          	ld	a5,0(s7)
ffffffffc0202b50:	779c                	ld	a5,40(a5)
ffffffffc0202b52:	9782                	jalr	a5
ffffffffc0202b54:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202b56:	aebfd0ef          	jal	ra,ffffffffc0200640 <intr_enable>
ffffffffc0202b5a:	b3cd                	j	ffffffffc020293c <pmm_init+0x3c0>
        intr_disable();
ffffffffc0202b5c:	aebfd0ef          	jal	ra,ffffffffc0200646 <intr_disable>
ffffffffc0202b60:	000bb783          	ld	a5,0(s7)
ffffffffc0202b64:	779c                	ld	a5,40(a5)
ffffffffc0202b66:	9782                	jalr	a5
ffffffffc0202b68:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202b6a:	ad7fd0ef          	jal	ra,ffffffffc0200640 <intr_enable>
ffffffffc0202b6e:	b36d                	j	ffffffffc0202918 <pmm_init+0x39c>
ffffffffc0202b70:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202b72:	ad5fd0ef          	jal	ra,ffffffffc0200646 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202b76:	000bb783          	ld	a5,0(s7)
ffffffffc0202b7a:	6522                	ld	a0,8(sp)
ffffffffc0202b7c:	4585                	li	a1,1
ffffffffc0202b7e:	739c                	ld	a5,32(a5)
ffffffffc0202b80:	9782                	jalr	a5
        intr_enable();
ffffffffc0202b82:	abffd0ef          	jal	ra,ffffffffc0200640 <intr_enable>
ffffffffc0202b86:	bb8d                	j	ffffffffc02028f8 <pmm_init+0x37c>
ffffffffc0202b88:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202b8a:	abdfd0ef          	jal	ra,ffffffffc0200646 <intr_disable>
ffffffffc0202b8e:	000bb783          	ld	a5,0(s7)
ffffffffc0202b92:	6522                	ld	a0,8(sp)
ffffffffc0202b94:	4585                	li	a1,1
ffffffffc0202b96:	739c                	ld	a5,32(a5)
ffffffffc0202b98:	9782                	jalr	a5
        intr_enable();
ffffffffc0202b9a:	aa7fd0ef          	jal	ra,ffffffffc0200640 <intr_enable>
ffffffffc0202b9e:	b32d                	j	ffffffffc02028c8 <pmm_init+0x34c>
        intr_disable();
ffffffffc0202ba0:	aa7fd0ef          	jal	ra,ffffffffc0200646 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202ba4:	000bb783          	ld	a5,0(s7)
ffffffffc0202ba8:	779c                	ld	a5,40(a5)
ffffffffc0202baa:	9782                	jalr	a5
ffffffffc0202bac:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202bae:	a93fd0ef          	jal	ra,ffffffffc0200640 <intr_enable>
ffffffffc0202bb2:	b72d                	j	ffffffffc0202adc <pmm_init+0x560>
ffffffffc0202bb4:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202bb6:	a91fd0ef          	jal	ra,ffffffffc0200646 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202bba:	000bb783          	ld	a5,0(s7)
ffffffffc0202bbe:	6522                	ld	a0,8(sp)
ffffffffc0202bc0:	4585                	li	a1,1
ffffffffc0202bc2:	739c                	ld	a5,32(a5)
ffffffffc0202bc4:	9782                	jalr	a5
        intr_enable();
ffffffffc0202bc6:	a7bfd0ef          	jal	ra,ffffffffc0200640 <intr_enable>
ffffffffc0202bca:	bdcd                	j	ffffffffc0202abc <pmm_init+0x540>
ffffffffc0202bcc:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202bce:	a79fd0ef          	jal	ra,ffffffffc0200646 <intr_disable>
ffffffffc0202bd2:	000bb783          	ld	a5,0(s7)
ffffffffc0202bd6:	6522                	ld	a0,8(sp)
ffffffffc0202bd8:	4585                	li	a1,1
ffffffffc0202bda:	739c                	ld	a5,32(a5)
ffffffffc0202bdc:	9782                	jalr	a5
        intr_enable();
ffffffffc0202bde:	a63fd0ef          	jal	ra,ffffffffc0200640 <intr_enable>
ffffffffc0202be2:	b56d                	j	ffffffffc0202a8c <pmm_init+0x510>
        intr_disable();
ffffffffc0202be4:	a63fd0ef          	jal	ra,ffffffffc0200646 <intr_disable>
ffffffffc0202be8:	000bb783          	ld	a5,0(s7)
ffffffffc0202bec:	4585                	li	a1,1
ffffffffc0202bee:	8556                	mv	a0,s5
ffffffffc0202bf0:	739c                	ld	a5,32(a5)
ffffffffc0202bf2:	9782                	jalr	a5
        intr_enable();
ffffffffc0202bf4:	a4dfd0ef          	jal	ra,ffffffffc0200640 <intr_enable>
ffffffffc0202bf8:	b59d                	j	ffffffffc0202a5e <pmm_init+0x4e2>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202bfa:	00005697          	auipc	a3,0x5
ffffffffc0202bfe:	b8e68693          	addi	a3,a3,-1138 # ffffffffc0207788 <default_pmm_manager+0x560>
ffffffffc0202c02:	00004617          	auipc	a2,0x4
ffffffffc0202c06:	f8e60613          	addi	a2,a2,-114 # ffffffffc0206b90 <commands+0x450>
ffffffffc0202c0a:	22f00593          	li	a1,559
ffffffffc0202c0e:	00004517          	auipc	a0,0x4
ffffffffc0202c12:	76a50513          	addi	a0,a0,1898 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc0202c16:	865fd0ef          	jal	ra,ffffffffc020047a <__panic>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202c1a:	00005697          	auipc	a3,0x5
ffffffffc0202c1e:	b2e68693          	addi	a3,a3,-1234 # ffffffffc0207748 <default_pmm_manager+0x520>
ffffffffc0202c22:	00004617          	auipc	a2,0x4
ffffffffc0202c26:	f6e60613          	addi	a2,a2,-146 # ffffffffc0206b90 <commands+0x450>
ffffffffc0202c2a:	22e00593          	li	a1,558
ffffffffc0202c2e:	00004517          	auipc	a0,0x4
ffffffffc0202c32:	74a50513          	addi	a0,a0,1866 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc0202c36:	845fd0ef          	jal	ra,ffffffffc020047a <__panic>
ffffffffc0202c3a:	86a2                	mv	a3,s0
ffffffffc0202c3c:	00004617          	auipc	a2,0x4
ffffffffc0202c40:	62460613          	addi	a2,a2,1572 # ffffffffc0207260 <default_pmm_manager+0x38>
ffffffffc0202c44:	22e00593          	li	a1,558
ffffffffc0202c48:	00004517          	auipc	a0,0x4
ffffffffc0202c4c:	73050513          	addi	a0,a0,1840 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc0202c50:	82bfd0ef          	jal	ra,ffffffffc020047a <__panic>
ffffffffc0202c54:	854ff0ef          	jal	ra,ffffffffc0201ca8 <pa2page.part.0>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202c58:	00004617          	auipc	a2,0x4
ffffffffc0202c5c:	6b060613          	addi	a2,a2,1712 # ffffffffc0207308 <default_pmm_manager+0xe0>
ffffffffc0202c60:	07f00593          	li	a1,127
ffffffffc0202c64:	00004517          	auipc	a0,0x4
ffffffffc0202c68:	71450513          	addi	a0,a0,1812 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc0202c6c:	80ffd0ef          	jal	ra,ffffffffc020047a <__panic>
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc0202c70:	00004617          	auipc	a2,0x4
ffffffffc0202c74:	69860613          	addi	a2,a2,1688 # ffffffffc0207308 <default_pmm_manager+0xe0>
ffffffffc0202c78:	0c100593          	li	a1,193
ffffffffc0202c7c:	00004517          	auipc	a0,0x4
ffffffffc0202c80:	6fc50513          	addi	a0,a0,1788 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc0202c84:	ff6fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc0202c88:	00004697          	auipc	a3,0x4
ffffffffc0202c8c:	7f868693          	addi	a3,a3,2040 # ffffffffc0207480 <default_pmm_manager+0x258>
ffffffffc0202c90:	00004617          	auipc	a2,0x4
ffffffffc0202c94:	f0060613          	addi	a2,a2,-256 # ffffffffc0206b90 <commands+0x450>
ffffffffc0202c98:	1f200593          	li	a1,498
ffffffffc0202c9c:	00004517          	auipc	a0,0x4
ffffffffc0202ca0:	6dc50513          	addi	a0,a0,1756 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc0202ca4:	fd6fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202ca8:	00004697          	auipc	a3,0x4
ffffffffc0202cac:	7b868693          	addi	a3,a3,1976 # ffffffffc0207460 <default_pmm_manager+0x238>
ffffffffc0202cb0:	00004617          	auipc	a2,0x4
ffffffffc0202cb4:	ee060613          	addi	a2,a2,-288 # ffffffffc0206b90 <commands+0x450>
ffffffffc0202cb8:	1f100593          	li	a1,497
ffffffffc0202cbc:	00004517          	auipc	a0,0x4
ffffffffc0202cc0:	6bc50513          	addi	a0,a0,1724 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc0202cc4:	fb6fd0ef          	jal	ra,ffffffffc020047a <__panic>
ffffffffc0202cc8:	ffdfe0ef          	jal	ra,ffffffffc0201cc4 <pte2page.part.0>
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc0202ccc:	00005697          	auipc	a3,0x5
ffffffffc0202cd0:	84468693          	addi	a3,a3,-1980 # ffffffffc0207510 <default_pmm_manager+0x2e8>
ffffffffc0202cd4:	00004617          	auipc	a2,0x4
ffffffffc0202cd8:	ebc60613          	addi	a2,a2,-324 # ffffffffc0206b90 <commands+0x450>
ffffffffc0202cdc:	1fa00593          	li	a1,506
ffffffffc0202ce0:	00004517          	auipc	a0,0x4
ffffffffc0202ce4:	69850513          	addi	a0,a0,1688 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc0202ce8:	f92fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc0202cec:	00004697          	auipc	a3,0x4
ffffffffc0202cf0:	7f468693          	addi	a3,a3,2036 # ffffffffc02074e0 <default_pmm_manager+0x2b8>
ffffffffc0202cf4:	00004617          	auipc	a2,0x4
ffffffffc0202cf8:	e9c60613          	addi	a2,a2,-356 # ffffffffc0206b90 <commands+0x450>
ffffffffc0202cfc:	1f700593          	li	a1,503
ffffffffc0202d00:	00004517          	auipc	a0,0x4
ffffffffc0202d04:	67850513          	addi	a0,a0,1656 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc0202d08:	f72fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc0202d0c:	00004697          	auipc	a3,0x4
ffffffffc0202d10:	7ac68693          	addi	a3,a3,1964 # ffffffffc02074b8 <default_pmm_manager+0x290>
ffffffffc0202d14:	00004617          	auipc	a2,0x4
ffffffffc0202d18:	e7c60613          	addi	a2,a2,-388 # ffffffffc0206b90 <commands+0x450>
ffffffffc0202d1c:	1f300593          	li	a1,499
ffffffffc0202d20:	00004517          	auipc	a0,0x4
ffffffffc0202d24:	65850513          	addi	a0,a0,1624 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc0202d28:	f52fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202d2c:	00005697          	auipc	a3,0x5
ffffffffc0202d30:	86c68693          	addi	a3,a3,-1940 # ffffffffc0207598 <default_pmm_manager+0x370>
ffffffffc0202d34:	00004617          	auipc	a2,0x4
ffffffffc0202d38:	e5c60613          	addi	a2,a2,-420 # ffffffffc0206b90 <commands+0x450>
ffffffffc0202d3c:	20300593          	li	a1,515
ffffffffc0202d40:	00004517          	auipc	a0,0x4
ffffffffc0202d44:	63850513          	addi	a0,a0,1592 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc0202d48:	f32fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0202d4c:	00005697          	auipc	a3,0x5
ffffffffc0202d50:	8ec68693          	addi	a3,a3,-1812 # ffffffffc0207638 <default_pmm_manager+0x410>
ffffffffc0202d54:	00004617          	auipc	a2,0x4
ffffffffc0202d58:	e3c60613          	addi	a2,a2,-452 # ffffffffc0206b90 <commands+0x450>
ffffffffc0202d5c:	20800593          	li	a1,520
ffffffffc0202d60:	00004517          	auipc	a0,0x4
ffffffffc0202d64:	61850513          	addi	a0,a0,1560 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc0202d68:	f12fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0202d6c:	00005697          	auipc	a3,0x5
ffffffffc0202d70:	80468693          	addi	a3,a3,-2044 # ffffffffc0207570 <default_pmm_manager+0x348>
ffffffffc0202d74:	00004617          	auipc	a2,0x4
ffffffffc0202d78:	e1c60613          	addi	a2,a2,-484 # ffffffffc0206b90 <commands+0x450>
ffffffffc0202d7c:	20000593          	li	a1,512
ffffffffc0202d80:	00004517          	auipc	a0,0x4
ffffffffc0202d84:	5f850513          	addi	a0,a0,1528 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc0202d88:	ef2fd0ef          	jal	ra,ffffffffc020047a <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202d8c:	86d6                	mv	a3,s5
ffffffffc0202d8e:	00004617          	auipc	a2,0x4
ffffffffc0202d92:	4d260613          	addi	a2,a2,1234 # ffffffffc0207260 <default_pmm_manager+0x38>
ffffffffc0202d96:	1ff00593          	li	a1,511
ffffffffc0202d9a:	00004517          	auipc	a0,0x4
ffffffffc0202d9e:	5de50513          	addi	a0,a0,1502 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc0202da2:	ed8fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0202da6:	00005697          	auipc	a3,0x5
ffffffffc0202daa:	82a68693          	addi	a3,a3,-2006 # ffffffffc02075d0 <default_pmm_manager+0x3a8>
ffffffffc0202dae:	00004617          	auipc	a2,0x4
ffffffffc0202db2:	de260613          	addi	a2,a2,-542 # ffffffffc0206b90 <commands+0x450>
ffffffffc0202db6:	20d00593          	li	a1,525
ffffffffc0202dba:	00004517          	auipc	a0,0x4
ffffffffc0202dbe:	5be50513          	addi	a0,a0,1470 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc0202dc2:	eb8fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202dc6:	00005697          	auipc	a3,0x5
ffffffffc0202dca:	8d268693          	addi	a3,a3,-1838 # ffffffffc0207698 <default_pmm_manager+0x470>
ffffffffc0202dce:	00004617          	auipc	a2,0x4
ffffffffc0202dd2:	dc260613          	addi	a2,a2,-574 # ffffffffc0206b90 <commands+0x450>
ffffffffc0202dd6:	20c00593          	li	a1,524
ffffffffc0202dda:	00004517          	auipc	a0,0x4
ffffffffc0202dde:	59e50513          	addi	a0,a0,1438 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc0202de2:	e98fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0202de6:	00005697          	auipc	a3,0x5
ffffffffc0202dea:	89a68693          	addi	a3,a3,-1894 # ffffffffc0207680 <default_pmm_manager+0x458>
ffffffffc0202dee:	00004617          	auipc	a2,0x4
ffffffffc0202df2:	da260613          	addi	a2,a2,-606 # ffffffffc0206b90 <commands+0x450>
ffffffffc0202df6:	20b00593          	li	a1,523
ffffffffc0202dfa:	00004517          	auipc	a0,0x4
ffffffffc0202dfe:	57e50513          	addi	a0,a0,1406 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc0202e02:	e78fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc0202e06:	00005697          	auipc	a3,0x5
ffffffffc0202e0a:	84a68693          	addi	a3,a3,-1974 # ffffffffc0207650 <default_pmm_manager+0x428>
ffffffffc0202e0e:	00004617          	auipc	a2,0x4
ffffffffc0202e12:	d8260613          	addi	a2,a2,-638 # ffffffffc0206b90 <commands+0x450>
ffffffffc0202e16:	20a00593          	li	a1,522
ffffffffc0202e1a:	00004517          	auipc	a0,0x4
ffffffffc0202e1e:	55e50513          	addi	a0,a0,1374 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc0202e22:	e58fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202e26:	00005697          	auipc	a3,0x5
ffffffffc0202e2a:	9e268693          	addi	a3,a3,-1566 # ffffffffc0207808 <default_pmm_manager+0x5e0>
ffffffffc0202e2e:	00004617          	auipc	a2,0x4
ffffffffc0202e32:	d6260613          	addi	a2,a2,-670 # ffffffffc0206b90 <commands+0x450>
ffffffffc0202e36:	23900593          	li	a1,569
ffffffffc0202e3a:	00004517          	auipc	a0,0x4
ffffffffc0202e3e:	53e50513          	addi	a0,a0,1342 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc0202e42:	e38fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc0202e46:	00004697          	auipc	a3,0x4
ffffffffc0202e4a:	7da68693          	addi	a3,a3,2010 # ffffffffc0207620 <default_pmm_manager+0x3f8>
ffffffffc0202e4e:	00004617          	auipc	a2,0x4
ffffffffc0202e52:	d4260613          	addi	a2,a2,-702 # ffffffffc0206b90 <commands+0x450>
ffffffffc0202e56:	20700593          	li	a1,519
ffffffffc0202e5a:	00004517          	auipc	a0,0x4
ffffffffc0202e5e:	51e50513          	addi	a0,a0,1310 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc0202e62:	e18fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(*ptep & PTE_W);
ffffffffc0202e66:	00004697          	auipc	a3,0x4
ffffffffc0202e6a:	7aa68693          	addi	a3,a3,1962 # ffffffffc0207610 <default_pmm_manager+0x3e8>
ffffffffc0202e6e:	00004617          	auipc	a2,0x4
ffffffffc0202e72:	d2260613          	addi	a2,a2,-734 # ffffffffc0206b90 <commands+0x450>
ffffffffc0202e76:	20600593          	li	a1,518
ffffffffc0202e7a:	00004517          	auipc	a0,0x4
ffffffffc0202e7e:	4fe50513          	addi	a0,a0,1278 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc0202e82:	df8fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(nr_free_store==nr_free_pages());
ffffffffc0202e86:	00005697          	auipc	a3,0x5
ffffffffc0202e8a:	88268693          	addi	a3,a3,-1918 # ffffffffc0207708 <default_pmm_manager+0x4e0>
ffffffffc0202e8e:	00004617          	auipc	a2,0x4
ffffffffc0202e92:	d0260613          	addi	a2,a2,-766 # ffffffffc0206b90 <commands+0x450>
ffffffffc0202e96:	24a00593          	li	a1,586
ffffffffc0202e9a:	00004517          	auipc	a0,0x4
ffffffffc0202e9e:	4de50513          	addi	a0,a0,1246 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc0202ea2:	dd8fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(*ptep & PTE_U);
ffffffffc0202ea6:	00004697          	auipc	a3,0x4
ffffffffc0202eaa:	75a68693          	addi	a3,a3,1882 # ffffffffc0207600 <default_pmm_manager+0x3d8>
ffffffffc0202eae:	00004617          	auipc	a2,0x4
ffffffffc0202eb2:	ce260613          	addi	a2,a2,-798 # ffffffffc0206b90 <commands+0x450>
ffffffffc0202eb6:	20500593          	li	a1,517
ffffffffc0202eba:	00004517          	auipc	a0,0x4
ffffffffc0202ebe:	4be50513          	addi	a0,a0,1214 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc0202ec2:	db8fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202ec6:	00004697          	auipc	a3,0x4
ffffffffc0202eca:	69268693          	addi	a3,a3,1682 # ffffffffc0207558 <default_pmm_manager+0x330>
ffffffffc0202ece:	00004617          	auipc	a2,0x4
ffffffffc0202ed2:	cc260613          	addi	a2,a2,-830 # ffffffffc0206b90 <commands+0x450>
ffffffffc0202ed6:	21200593          	li	a1,530
ffffffffc0202eda:	00004517          	auipc	a0,0x4
ffffffffc0202ede:	49e50513          	addi	a0,a0,1182 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc0202ee2:	d98fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202ee6:	00004697          	auipc	a3,0x4
ffffffffc0202eea:	7ca68693          	addi	a3,a3,1994 # ffffffffc02076b0 <default_pmm_manager+0x488>
ffffffffc0202eee:	00004617          	auipc	a2,0x4
ffffffffc0202ef2:	ca260613          	addi	a2,a2,-862 # ffffffffc0206b90 <commands+0x450>
ffffffffc0202ef6:	20f00593          	li	a1,527
ffffffffc0202efa:	00004517          	auipc	a0,0x4
ffffffffc0202efe:	47e50513          	addi	a0,a0,1150 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc0202f02:	d78fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202f06:	00004697          	auipc	a3,0x4
ffffffffc0202f0a:	63a68693          	addi	a3,a3,1594 # ffffffffc0207540 <default_pmm_manager+0x318>
ffffffffc0202f0e:	00004617          	auipc	a2,0x4
ffffffffc0202f12:	c8260613          	addi	a2,a2,-894 # ffffffffc0206b90 <commands+0x450>
ffffffffc0202f16:	20e00593          	li	a1,526
ffffffffc0202f1a:	00004517          	auipc	a0,0x4
ffffffffc0202f1e:	45e50513          	addi	a0,a0,1118 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc0202f22:	d58fd0ef          	jal	ra,ffffffffc020047a <__panic>
    return KADDR(page2pa(page));
ffffffffc0202f26:	00004617          	auipc	a2,0x4
ffffffffc0202f2a:	33a60613          	addi	a2,a2,826 # ffffffffc0207260 <default_pmm_manager+0x38>
ffffffffc0202f2e:	06900593          	li	a1,105
ffffffffc0202f32:	00004517          	auipc	a0,0x4
ffffffffc0202f36:	35650513          	addi	a0,a0,854 # ffffffffc0207288 <default_pmm_manager+0x60>
ffffffffc0202f3a:	d40fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc0202f3e:	00004697          	auipc	a3,0x4
ffffffffc0202f42:	7a268693          	addi	a3,a3,1954 # ffffffffc02076e0 <default_pmm_manager+0x4b8>
ffffffffc0202f46:	00004617          	auipc	a2,0x4
ffffffffc0202f4a:	c4a60613          	addi	a2,a2,-950 # ffffffffc0206b90 <commands+0x450>
ffffffffc0202f4e:	21900593          	li	a1,537
ffffffffc0202f52:	00004517          	auipc	a0,0x4
ffffffffc0202f56:	42650513          	addi	a0,a0,1062 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc0202f5a:	d20fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202f5e:	00004697          	auipc	a3,0x4
ffffffffc0202f62:	73a68693          	addi	a3,a3,1850 # ffffffffc0207698 <default_pmm_manager+0x470>
ffffffffc0202f66:	00004617          	auipc	a2,0x4
ffffffffc0202f6a:	c2a60613          	addi	a2,a2,-982 # ffffffffc0206b90 <commands+0x450>
ffffffffc0202f6e:	21700593          	li	a1,535
ffffffffc0202f72:	00004517          	auipc	a0,0x4
ffffffffc0202f76:	40650513          	addi	a0,a0,1030 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc0202f7a:	d00fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0202f7e:	00004697          	auipc	a3,0x4
ffffffffc0202f82:	74a68693          	addi	a3,a3,1866 # ffffffffc02076c8 <default_pmm_manager+0x4a0>
ffffffffc0202f86:	00004617          	auipc	a2,0x4
ffffffffc0202f8a:	c0a60613          	addi	a2,a2,-1014 # ffffffffc0206b90 <commands+0x450>
ffffffffc0202f8e:	21600593          	li	a1,534
ffffffffc0202f92:	00004517          	auipc	a0,0x4
ffffffffc0202f96:	3e650513          	addi	a0,a0,998 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc0202f9a:	ce0fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202f9e:	00004697          	auipc	a3,0x4
ffffffffc0202fa2:	6fa68693          	addi	a3,a3,1786 # ffffffffc0207698 <default_pmm_manager+0x470>
ffffffffc0202fa6:	00004617          	auipc	a2,0x4
ffffffffc0202faa:	bea60613          	addi	a2,a2,-1046 # ffffffffc0206b90 <commands+0x450>
ffffffffc0202fae:	21300593          	li	a1,531
ffffffffc0202fb2:	00004517          	auipc	a0,0x4
ffffffffc0202fb6:	3c650513          	addi	a0,a0,966 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc0202fba:	cc0fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page_ref(p) == 1);
ffffffffc0202fbe:	00005697          	auipc	a3,0x5
ffffffffc0202fc2:	83268693          	addi	a3,a3,-1998 # ffffffffc02077f0 <default_pmm_manager+0x5c8>
ffffffffc0202fc6:	00004617          	auipc	a2,0x4
ffffffffc0202fca:	bca60613          	addi	a2,a2,-1078 # ffffffffc0206b90 <commands+0x450>
ffffffffc0202fce:	23800593          	li	a1,568
ffffffffc0202fd2:	00004517          	auipc	a0,0x4
ffffffffc0202fd6:	3a650513          	addi	a0,a0,934 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc0202fda:	ca0fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202fde:	00004697          	auipc	a3,0x4
ffffffffc0202fe2:	7da68693          	addi	a3,a3,2010 # ffffffffc02077b8 <default_pmm_manager+0x590>
ffffffffc0202fe6:	00004617          	auipc	a2,0x4
ffffffffc0202fea:	baa60613          	addi	a2,a2,-1110 # ffffffffc0206b90 <commands+0x450>
ffffffffc0202fee:	23700593          	li	a1,567
ffffffffc0202ff2:	00004517          	auipc	a0,0x4
ffffffffc0202ff6:	38650513          	addi	a0,a0,902 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc0202ffa:	c80fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(boot_pgdir[0] == 0);
ffffffffc0202ffe:	00004697          	auipc	a3,0x4
ffffffffc0203002:	7a268693          	addi	a3,a3,1954 # ffffffffc02077a0 <default_pmm_manager+0x578>
ffffffffc0203006:	00004617          	auipc	a2,0x4
ffffffffc020300a:	b8a60613          	addi	a2,a2,-1142 # ffffffffc0206b90 <commands+0x450>
ffffffffc020300e:	23300593          	li	a1,563
ffffffffc0203012:	00004517          	auipc	a0,0x4
ffffffffc0203016:	36650513          	addi	a0,a0,870 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc020301a:	c60fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(nr_free_store==nr_free_pages());
ffffffffc020301e:	00004697          	auipc	a3,0x4
ffffffffc0203022:	6ea68693          	addi	a3,a3,1770 # ffffffffc0207708 <default_pmm_manager+0x4e0>
ffffffffc0203026:	00004617          	auipc	a2,0x4
ffffffffc020302a:	b6a60613          	addi	a2,a2,-1174 # ffffffffc0206b90 <commands+0x450>
ffffffffc020302e:	22100593          	li	a1,545
ffffffffc0203032:	00004517          	auipc	a0,0x4
ffffffffc0203036:	34650513          	addi	a0,a0,838 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc020303a:	c40fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc020303e:	00004697          	auipc	a3,0x4
ffffffffc0203042:	50268693          	addi	a3,a3,1282 # ffffffffc0207540 <default_pmm_manager+0x318>
ffffffffc0203046:	00004617          	auipc	a2,0x4
ffffffffc020304a:	b4a60613          	addi	a2,a2,-1206 # ffffffffc0206b90 <commands+0x450>
ffffffffc020304e:	1fb00593          	li	a1,507
ffffffffc0203052:	00004517          	auipc	a0,0x4
ffffffffc0203056:	32650513          	addi	a0,a0,806 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc020305a:	c20fd0ef          	jal	ra,ffffffffc020047a <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc020305e:	00004617          	auipc	a2,0x4
ffffffffc0203062:	20260613          	addi	a2,a2,514 # ffffffffc0207260 <default_pmm_manager+0x38>
ffffffffc0203066:	1fe00593          	li	a1,510
ffffffffc020306a:	00004517          	auipc	a0,0x4
ffffffffc020306e:	30e50513          	addi	a0,a0,782 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc0203072:	c08fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0203076:	00004697          	auipc	a3,0x4
ffffffffc020307a:	4e268693          	addi	a3,a3,1250 # ffffffffc0207558 <default_pmm_manager+0x330>
ffffffffc020307e:	00004617          	auipc	a2,0x4
ffffffffc0203082:	b1260613          	addi	a2,a2,-1262 # ffffffffc0206b90 <commands+0x450>
ffffffffc0203086:	1fc00593          	li	a1,508
ffffffffc020308a:	00004517          	auipc	a0,0x4
ffffffffc020308e:	2ee50513          	addi	a0,a0,750 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc0203092:	be8fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0203096:	00004697          	auipc	a3,0x4
ffffffffc020309a:	53a68693          	addi	a3,a3,1338 # ffffffffc02075d0 <default_pmm_manager+0x3a8>
ffffffffc020309e:	00004617          	auipc	a2,0x4
ffffffffc02030a2:	af260613          	addi	a2,a2,-1294 # ffffffffc0206b90 <commands+0x450>
ffffffffc02030a6:	20400593          	li	a1,516
ffffffffc02030aa:	00004517          	auipc	a0,0x4
ffffffffc02030ae:	2ce50513          	addi	a0,a0,718 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc02030b2:	bc8fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc02030b6:	00004697          	auipc	a3,0x4
ffffffffc02030ba:	7fa68693          	addi	a3,a3,2042 # ffffffffc02078b0 <default_pmm_manager+0x688>
ffffffffc02030be:	00004617          	auipc	a2,0x4
ffffffffc02030c2:	ad260613          	addi	a2,a2,-1326 # ffffffffc0206b90 <commands+0x450>
ffffffffc02030c6:	24100593          	li	a1,577
ffffffffc02030ca:	00004517          	auipc	a0,0x4
ffffffffc02030ce:	2ae50513          	addi	a0,a0,686 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc02030d2:	ba8fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc02030d6:	00004697          	auipc	a3,0x4
ffffffffc02030da:	7a268693          	addi	a3,a3,1954 # ffffffffc0207878 <default_pmm_manager+0x650>
ffffffffc02030de:	00004617          	auipc	a2,0x4
ffffffffc02030e2:	ab260613          	addi	a2,a2,-1358 # ffffffffc0206b90 <commands+0x450>
ffffffffc02030e6:	23e00593          	li	a1,574
ffffffffc02030ea:	00004517          	auipc	a0,0x4
ffffffffc02030ee:	28e50513          	addi	a0,a0,654 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc02030f2:	b88fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(page_ref(p) == 2);
ffffffffc02030f6:	00004697          	auipc	a3,0x4
ffffffffc02030fa:	75268693          	addi	a3,a3,1874 # ffffffffc0207848 <default_pmm_manager+0x620>
ffffffffc02030fe:	00004617          	auipc	a2,0x4
ffffffffc0203102:	a9260613          	addi	a2,a2,-1390 # ffffffffc0206b90 <commands+0x450>
ffffffffc0203106:	23a00593          	li	a1,570
ffffffffc020310a:	00004517          	auipc	a0,0x4
ffffffffc020310e:	26e50513          	addi	a0,a0,622 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc0203112:	b68fd0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0203116 <copy_range>:
               bool share) {
ffffffffc0203116:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203118:	00d667b3          	or	a5,a2,a3
               bool share) {
ffffffffc020311c:	f486                	sd	ra,104(sp)
ffffffffc020311e:	f0a2                	sd	s0,96(sp)
ffffffffc0203120:	eca6                	sd	s1,88(sp)
ffffffffc0203122:	e8ca                	sd	s2,80(sp)
ffffffffc0203124:	e4ce                	sd	s3,72(sp)
ffffffffc0203126:	e0d2                	sd	s4,64(sp)
ffffffffc0203128:	fc56                	sd	s5,56(sp)
ffffffffc020312a:	f85a                	sd	s6,48(sp)
ffffffffc020312c:	f45e                	sd	s7,40(sp)
ffffffffc020312e:	f062                	sd	s8,32(sp)
ffffffffc0203130:	ec66                	sd	s9,24(sp)
ffffffffc0203132:	e86a                	sd	s10,16(sp)
ffffffffc0203134:	e46e                	sd	s11,8(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203136:	17d2                	slli	a5,a5,0x34
ffffffffc0203138:	1e079763          	bnez	a5,ffffffffc0203326 <copy_range+0x210>
    assert(USER_ACCESS(start, end));
ffffffffc020313c:	002007b7          	lui	a5,0x200
ffffffffc0203140:	8432                	mv	s0,a2
ffffffffc0203142:	16f66a63          	bltu	a2,a5,ffffffffc02032b6 <copy_range+0x1a0>
ffffffffc0203146:	8936                	mv	s2,a3
ffffffffc0203148:	16d67763          	bgeu	a2,a3,ffffffffc02032b6 <copy_range+0x1a0>
ffffffffc020314c:	4785                	li	a5,1
ffffffffc020314e:	07fe                	slli	a5,a5,0x1f
ffffffffc0203150:	16d7e363          	bltu	a5,a3,ffffffffc02032b6 <copy_range+0x1a0>
ffffffffc0203154:	5b7d                	li	s6,-1
ffffffffc0203156:	8aaa                	mv	s5,a0
ffffffffc0203158:	89ae                	mv	s3,a1
        start += PGSIZE;
ffffffffc020315a:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage) {
ffffffffc020315c:	000afc97          	auipc	s9,0xaf
ffffffffc0203160:	70cc8c93          	addi	s9,s9,1804 # ffffffffc02b2868 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0203164:	000afc17          	auipc	s8,0xaf
ffffffffc0203168:	70cc0c13          	addi	s8,s8,1804 # ffffffffc02b2870 <pages>
    return page - pages + nbase;
ffffffffc020316c:	00080bb7          	lui	s7,0x80
    return KADDR(page2pa(page));
ffffffffc0203170:	00cb5b13          	srli	s6,s6,0xc
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc0203174:	4601                	li	a2,0
ffffffffc0203176:	85a2                	mv	a1,s0
ffffffffc0203178:	854e                	mv	a0,s3
ffffffffc020317a:	c73fe0ef          	jal	ra,ffffffffc0201dec <get_pte>
ffffffffc020317e:	84aa                	mv	s1,a0
        if (ptep == NULL) {
ffffffffc0203180:	c175                	beqz	a0,ffffffffc0203264 <copy_range+0x14e>
        if (*ptep & PTE_V) {
ffffffffc0203182:	611c                	ld	a5,0(a0)
ffffffffc0203184:	8b85                	andi	a5,a5,1
ffffffffc0203186:	e785                	bnez	a5,ffffffffc02031ae <copy_range+0x98>
        start += PGSIZE;
ffffffffc0203188:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc020318a:	ff2465e3          	bltu	s0,s2,ffffffffc0203174 <copy_range+0x5e>
    return 0;
ffffffffc020318e:	4501                	li	a0,0
}
ffffffffc0203190:	70a6                	ld	ra,104(sp)
ffffffffc0203192:	7406                	ld	s0,96(sp)
ffffffffc0203194:	64e6                	ld	s1,88(sp)
ffffffffc0203196:	6946                	ld	s2,80(sp)
ffffffffc0203198:	69a6                	ld	s3,72(sp)
ffffffffc020319a:	6a06                	ld	s4,64(sp)
ffffffffc020319c:	7ae2                	ld	s5,56(sp)
ffffffffc020319e:	7b42                	ld	s6,48(sp)
ffffffffc02031a0:	7ba2                	ld	s7,40(sp)
ffffffffc02031a2:	7c02                	ld	s8,32(sp)
ffffffffc02031a4:	6ce2                	ld	s9,24(sp)
ffffffffc02031a6:	6d42                	ld	s10,16(sp)
ffffffffc02031a8:	6da2                	ld	s11,8(sp)
ffffffffc02031aa:	6165                	addi	sp,sp,112
ffffffffc02031ac:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL) {
ffffffffc02031ae:	4605                	li	a2,1
ffffffffc02031b0:	85a2                	mv	a1,s0
ffffffffc02031b2:	8556                	mv	a0,s5
ffffffffc02031b4:	c39fe0ef          	jal	ra,ffffffffc0201dec <get_pte>
ffffffffc02031b8:	c161                	beqz	a0,ffffffffc0203278 <copy_range+0x162>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc02031ba:	609c                	ld	a5,0(s1)
    if (!(pte & PTE_V)) {
ffffffffc02031bc:	0017f713          	andi	a4,a5,1
ffffffffc02031c0:	01f7f493          	andi	s1,a5,31
ffffffffc02031c4:	14070563          	beqz	a4,ffffffffc020330e <copy_range+0x1f8>
    if (PPN(pa) >= npage) {
ffffffffc02031c8:	000cb683          	ld	a3,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc02031cc:	078a                	slli	a5,a5,0x2
ffffffffc02031ce:	00c7d713          	srli	a4,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02031d2:	12d77263          	bgeu	a4,a3,ffffffffc02032f6 <copy_range+0x1e0>
    return &pages[PPN(pa) - nbase];
ffffffffc02031d6:	000c3783          	ld	a5,0(s8)
ffffffffc02031da:	fff806b7          	lui	a3,0xfff80
ffffffffc02031de:	9736                	add	a4,a4,a3
ffffffffc02031e0:	071a                	slli	a4,a4,0x6
            struct Page *npage = alloc_page();
ffffffffc02031e2:	4505                	li	a0,1
ffffffffc02031e4:	00e78db3          	add	s11,a5,a4
ffffffffc02031e8:	af9fe0ef          	jal	ra,ffffffffc0201ce0 <alloc_pages>
ffffffffc02031ec:	8d2a                	mv	s10,a0
            assert(page != NULL);
ffffffffc02031ee:	0a0d8463          	beqz	s11,ffffffffc0203296 <copy_range+0x180>
            assert(npage != NULL);
ffffffffc02031f2:	c175                	beqz	a0,ffffffffc02032d6 <copy_range+0x1c0>
    return page - pages + nbase;
ffffffffc02031f4:	000c3703          	ld	a4,0(s8)
    return KADDR(page2pa(page));
ffffffffc02031f8:	000cb603          	ld	a2,0(s9)
    return page - pages + nbase;
ffffffffc02031fc:	40ed86b3          	sub	a3,s11,a4
ffffffffc0203200:	8699                	srai	a3,a3,0x6
ffffffffc0203202:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc0203204:	0166f7b3          	and	a5,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc0203208:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020320a:	06c7fa63          	bgeu	a5,a2,ffffffffc020327e <copy_range+0x168>
    return page - pages + nbase;
ffffffffc020320e:	40e507b3          	sub	a5,a0,a4
    return KADDR(page2pa(page));
ffffffffc0203212:	000af717          	auipc	a4,0xaf
ffffffffc0203216:	66e70713          	addi	a4,a4,1646 # ffffffffc02b2880 <va_pa_offset>
ffffffffc020321a:	6308                	ld	a0,0(a4)
    return page - pages + nbase;
ffffffffc020321c:	8799                	srai	a5,a5,0x6
ffffffffc020321e:	97de                	add	a5,a5,s7
    return KADDR(page2pa(page));
ffffffffc0203220:	0167f733          	and	a4,a5,s6
ffffffffc0203224:	00a685b3          	add	a1,a3,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0203228:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc020322a:	04c77963          	bgeu	a4,a2,ffffffffc020327c <copy_range+0x166>
            memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
ffffffffc020322e:	6605                	lui	a2,0x1
ffffffffc0203230:	953e                	add	a0,a0,a5
ffffffffc0203232:	28c030ef          	jal	ra,ffffffffc02064be <memcpy>
            ret = page_insert(to, npage, start, perm );
ffffffffc0203236:	86a6                	mv	a3,s1
ffffffffc0203238:	8622                	mv	a2,s0
ffffffffc020323a:	85ea                	mv	a1,s10
ffffffffc020323c:	8556                	mv	a0,s5
ffffffffc020323e:	a48ff0ef          	jal	ra,ffffffffc0202486 <page_insert>
            assert(ret == 0);
ffffffffc0203242:	d139                	beqz	a0,ffffffffc0203188 <copy_range+0x72>
ffffffffc0203244:	00004697          	auipc	a3,0x4
ffffffffc0203248:	6d468693          	addi	a3,a3,1748 # ffffffffc0207918 <default_pmm_manager+0x6f0>
ffffffffc020324c:	00004617          	auipc	a2,0x4
ffffffffc0203250:	94460613          	addi	a2,a2,-1724 # ffffffffc0206b90 <commands+0x450>
ffffffffc0203254:	19300593          	li	a1,403
ffffffffc0203258:	00004517          	auipc	a0,0x4
ffffffffc020325c:	12050513          	addi	a0,a0,288 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc0203260:	a1afd0ef          	jal	ra,ffffffffc020047a <__panic>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0203264:	00200637          	lui	a2,0x200
ffffffffc0203268:	9432                	add	s0,s0,a2
ffffffffc020326a:	ffe00637          	lui	a2,0xffe00
ffffffffc020326e:	8c71                	and	s0,s0,a2
    } while (start != 0 && start < end);
ffffffffc0203270:	dc19                	beqz	s0,ffffffffc020318e <copy_range+0x78>
ffffffffc0203272:	f12461e3          	bltu	s0,s2,ffffffffc0203174 <copy_range+0x5e>
ffffffffc0203276:	bf21                	j	ffffffffc020318e <copy_range+0x78>
                return -E_NO_MEM;
ffffffffc0203278:	5571                	li	a0,-4
ffffffffc020327a:	bf19                	j	ffffffffc0203190 <copy_range+0x7a>
ffffffffc020327c:	86be                	mv	a3,a5
ffffffffc020327e:	00004617          	auipc	a2,0x4
ffffffffc0203282:	fe260613          	addi	a2,a2,-30 # ffffffffc0207260 <default_pmm_manager+0x38>
ffffffffc0203286:	06900593          	li	a1,105
ffffffffc020328a:	00004517          	auipc	a0,0x4
ffffffffc020328e:	ffe50513          	addi	a0,a0,-2 # ffffffffc0207288 <default_pmm_manager+0x60>
ffffffffc0203292:	9e8fd0ef          	jal	ra,ffffffffc020047a <__panic>
            assert(page != NULL);
ffffffffc0203296:	00004697          	auipc	a3,0x4
ffffffffc020329a:	66268693          	addi	a3,a3,1634 # ffffffffc02078f8 <default_pmm_manager+0x6d0>
ffffffffc020329e:	00004617          	auipc	a2,0x4
ffffffffc02032a2:	8f260613          	addi	a2,a2,-1806 # ffffffffc0206b90 <commands+0x450>
ffffffffc02032a6:	17200593          	li	a1,370
ffffffffc02032aa:	00004517          	auipc	a0,0x4
ffffffffc02032ae:	0ce50513          	addi	a0,a0,206 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc02032b2:	9c8fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc02032b6:	00004697          	auipc	a3,0x4
ffffffffc02032ba:	10268693          	addi	a3,a3,258 # ffffffffc02073b8 <default_pmm_manager+0x190>
ffffffffc02032be:	00004617          	auipc	a2,0x4
ffffffffc02032c2:	8d260613          	addi	a2,a2,-1838 # ffffffffc0206b90 <commands+0x450>
ffffffffc02032c6:	15e00593          	li	a1,350
ffffffffc02032ca:	00004517          	auipc	a0,0x4
ffffffffc02032ce:	0ae50513          	addi	a0,a0,174 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc02032d2:	9a8fd0ef          	jal	ra,ffffffffc020047a <__panic>
            assert(npage != NULL);
ffffffffc02032d6:	00004697          	auipc	a3,0x4
ffffffffc02032da:	63268693          	addi	a3,a3,1586 # ffffffffc0207908 <default_pmm_manager+0x6e0>
ffffffffc02032de:	00004617          	auipc	a2,0x4
ffffffffc02032e2:	8b260613          	addi	a2,a2,-1870 # ffffffffc0206b90 <commands+0x450>
ffffffffc02032e6:	17300593          	li	a1,371
ffffffffc02032ea:	00004517          	auipc	a0,0x4
ffffffffc02032ee:	08e50513          	addi	a0,a0,142 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc02032f2:	988fd0ef          	jal	ra,ffffffffc020047a <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02032f6:	00004617          	auipc	a2,0x4
ffffffffc02032fa:	03a60613          	addi	a2,a2,58 # ffffffffc0207330 <default_pmm_manager+0x108>
ffffffffc02032fe:	06200593          	li	a1,98
ffffffffc0203302:	00004517          	auipc	a0,0x4
ffffffffc0203306:	f8650513          	addi	a0,a0,-122 # ffffffffc0207288 <default_pmm_manager+0x60>
ffffffffc020330a:	970fd0ef          	jal	ra,ffffffffc020047a <__panic>
        panic("pte2page called with invalid pte");
ffffffffc020330e:	00004617          	auipc	a2,0x4
ffffffffc0203312:	04260613          	addi	a2,a2,66 # ffffffffc0207350 <default_pmm_manager+0x128>
ffffffffc0203316:	07400593          	li	a1,116
ffffffffc020331a:	00004517          	auipc	a0,0x4
ffffffffc020331e:	f6e50513          	addi	a0,a0,-146 # ffffffffc0207288 <default_pmm_manager+0x60>
ffffffffc0203322:	958fd0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203326:	00004697          	auipc	a3,0x4
ffffffffc020332a:	06268693          	addi	a3,a3,98 # ffffffffc0207388 <default_pmm_manager+0x160>
ffffffffc020332e:	00004617          	auipc	a2,0x4
ffffffffc0203332:	86260613          	addi	a2,a2,-1950 # ffffffffc0206b90 <commands+0x450>
ffffffffc0203336:	15d00593          	li	a1,349
ffffffffc020333a:	00004517          	auipc	a0,0x4
ffffffffc020333e:	03e50513          	addi	a0,a0,62 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc0203342:	938fd0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0203346 <tlb_invalidate>:
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0203346:	12058073          	sfence.vma	a1
}
ffffffffc020334a:	8082                	ret

ffffffffc020334c <pgdir_alloc_page>:
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc020334c:	7179                	addi	sp,sp,-48
ffffffffc020334e:	e84a                	sd	s2,16(sp)
ffffffffc0203350:	892a                	mv	s2,a0
    struct Page *page = alloc_page();
ffffffffc0203352:	4505                	li	a0,1
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc0203354:	f022                	sd	s0,32(sp)
ffffffffc0203356:	ec26                	sd	s1,24(sp)
ffffffffc0203358:	e44e                	sd	s3,8(sp)
ffffffffc020335a:	f406                	sd	ra,40(sp)
ffffffffc020335c:	84ae                	mv	s1,a1
ffffffffc020335e:	89b2                	mv	s3,a2
    struct Page *page = alloc_page();
ffffffffc0203360:	981fe0ef          	jal	ra,ffffffffc0201ce0 <alloc_pages>
ffffffffc0203364:	842a                	mv	s0,a0
    if (page != NULL) {
ffffffffc0203366:	cd05                	beqz	a0,ffffffffc020339e <pgdir_alloc_page+0x52>
        if (page_insert(pgdir, page, la, perm) != 0) {
ffffffffc0203368:	85aa                	mv	a1,a0
ffffffffc020336a:	86ce                	mv	a3,s3
ffffffffc020336c:	8626                	mv	a2,s1
ffffffffc020336e:	854a                	mv	a0,s2
ffffffffc0203370:	916ff0ef          	jal	ra,ffffffffc0202486 <page_insert>
ffffffffc0203374:	ed0d                	bnez	a0,ffffffffc02033ae <pgdir_alloc_page+0x62>
        if (swap_init_ok) {
ffffffffc0203376:	000af797          	auipc	a5,0xaf
ffffffffc020337a:	5227a783          	lw	a5,1314(a5) # ffffffffc02b2898 <swap_init_ok>
ffffffffc020337e:	c385                	beqz	a5,ffffffffc020339e <pgdir_alloc_page+0x52>
            if (check_mm_struct != NULL) {
ffffffffc0203380:	000af517          	auipc	a0,0xaf
ffffffffc0203384:	52053503          	ld	a0,1312(a0) # ffffffffc02b28a0 <check_mm_struct>
ffffffffc0203388:	c919                	beqz	a0,ffffffffc020339e <pgdir_alloc_page+0x52>
                swap_map_swappable(check_mm_struct, la, page, 0);
ffffffffc020338a:	4681                	li	a3,0
ffffffffc020338c:	8622                	mv	a2,s0
ffffffffc020338e:	85a6                	mv	a1,s1
ffffffffc0203390:	7e4000ef          	jal	ra,ffffffffc0203b74 <swap_map_swappable>
                assert(page_ref(page) == 1);
ffffffffc0203394:	4018                	lw	a4,0(s0)
                page->pra_vaddr = la;
ffffffffc0203396:	fc04                	sd	s1,56(s0)
                assert(page_ref(page) == 1);
ffffffffc0203398:	4785                	li	a5,1
ffffffffc020339a:	04f71663          	bne	a4,a5,ffffffffc02033e6 <pgdir_alloc_page+0x9a>
}
ffffffffc020339e:	70a2                	ld	ra,40(sp)
ffffffffc02033a0:	8522                	mv	a0,s0
ffffffffc02033a2:	7402                	ld	s0,32(sp)
ffffffffc02033a4:	64e2                	ld	s1,24(sp)
ffffffffc02033a6:	6942                	ld	s2,16(sp)
ffffffffc02033a8:	69a2                	ld	s3,8(sp)
ffffffffc02033aa:	6145                	addi	sp,sp,48
ffffffffc02033ac:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02033ae:	100027f3          	csrr	a5,sstatus
ffffffffc02033b2:	8b89                	andi	a5,a5,2
ffffffffc02033b4:	eb99                	bnez	a5,ffffffffc02033ca <pgdir_alloc_page+0x7e>
        pmm_manager->free_pages(base, n);
ffffffffc02033b6:	000af797          	auipc	a5,0xaf
ffffffffc02033ba:	4c27b783          	ld	a5,1218(a5) # ffffffffc02b2878 <pmm_manager>
ffffffffc02033be:	739c                	ld	a5,32(a5)
ffffffffc02033c0:	8522                	mv	a0,s0
ffffffffc02033c2:	4585                	li	a1,1
ffffffffc02033c4:	9782                	jalr	a5
            return NULL;
ffffffffc02033c6:	4401                	li	s0,0
ffffffffc02033c8:	bfd9                	j	ffffffffc020339e <pgdir_alloc_page+0x52>
        intr_disable();
ffffffffc02033ca:	a7cfd0ef          	jal	ra,ffffffffc0200646 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02033ce:	000af797          	auipc	a5,0xaf
ffffffffc02033d2:	4aa7b783          	ld	a5,1194(a5) # ffffffffc02b2878 <pmm_manager>
ffffffffc02033d6:	739c                	ld	a5,32(a5)
ffffffffc02033d8:	8522                	mv	a0,s0
ffffffffc02033da:	4585                	li	a1,1
ffffffffc02033dc:	9782                	jalr	a5
            return NULL;
ffffffffc02033de:	4401                	li	s0,0
        intr_enable();
ffffffffc02033e0:	a60fd0ef          	jal	ra,ffffffffc0200640 <intr_enable>
ffffffffc02033e4:	bf6d                	j	ffffffffc020339e <pgdir_alloc_page+0x52>
                assert(page_ref(page) == 1);
ffffffffc02033e6:	00004697          	auipc	a3,0x4
ffffffffc02033ea:	54268693          	addi	a3,a3,1346 # ffffffffc0207928 <default_pmm_manager+0x700>
ffffffffc02033ee:	00003617          	auipc	a2,0x3
ffffffffc02033f2:	7a260613          	addi	a2,a2,1954 # ffffffffc0206b90 <commands+0x450>
ffffffffc02033f6:	1d200593          	li	a1,466
ffffffffc02033fa:	00004517          	auipc	a0,0x4
ffffffffc02033fe:	f7e50513          	addi	a0,a0,-130 # ffffffffc0207378 <default_pmm_manager+0x150>
ffffffffc0203402:	878fd0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0203406 <pa2page.part.0>:
pa2page(uintptr_t pa) {
ffffffffc0203406:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0203408:	00004617          	auipc	a2,0x4
ffffffffc020340c:	f2860613          	addi	a2,a2,-216 # ffffffffc0207330 <default_pmm_manager+0x108>
ffffffffc0203410:	06200593          	li	a1,98
ffffffffc0203414:	00004517          	auipc	a0,0x4
ffffffffc0203418:	e7450513          	addi	a0,a0,-396 # ffffffffc0207288 <default_pmm_manager+0x60>
pa2page(uintptr_t pa) {
ffffffffc020341c:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc020341e:	85cfd0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0203422 <swap_init>:

static void check_swap(void);

int
swap_init(void)
{
ffffffffc0203422:	7135                	addi	sp,sp,-160
ffffffffc0203424:	ed06                	sd	ra,152(sp)
ffffffffc0203426:	e922                	sd	s0,144(sp)
ffffffffc0203428:	e526                	sd	s1,136(sp)
ffffffffc020342a:	e14a                	sd	s2,128(sp)
ffffffffc020342c:	fcce                	sd	s3,120(sp)
ffffffffc020342e:	f8d2                	sd	s4,112(sp)
ffffffffc0203430:	f4d6                	sd	s5,104(sp)
ffffffffc0203432:	f0da                	sd	s6,96(sp)
ffffffffc0203434:	ecde                	sd	s7,88(sp)
ffffffffc0203436:	e8e2                	sd	s8,80(sp)
ffffffffc0203438:	e4e6                	sd	s9,72(sp)
ffffffffc020343a:	e0ea                	sd	s10,64(sp)
ffffffffc020343c:	fc6e                	sd	s11,56(sp)
     swapfs_init();
ffffffffc020343e:	632010ef          	jal	ra,ffffffffc0204a70 <swapfs_init>

     // Since the IDE is faked, it can only store 7 pages at most to pass the test
     if (!(7 <= max_swap_offset &&
ffffffffc0203442:	000af697          	auipc	a3,0xaf
ffffffffc0203446:	4466b683          	ld	a3,1094(a3) # ffffffffc02b2888 <max_swap_offset>
ffffffffc020344a:	010007b7          	lui	a5,0x1000
ffffffffc020344e:	ff968713          	addi	a4,a3,-7
ffffffffc0203452:	17e1                	addi	a5,a5,-8
ffffffffc0203454:	42e7e663          	bltu	a5,a4,ffffffffc0203880 <swap_init+0x45e>
        max_swap_offset < MAX_SWAP_OFFSET_LIMIT)) {
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
     }
     

     sm = &swap_manager_fifo;
ffffffffc0203458:	000a4797          	auipc	a5,0xa4
ffffffffc020345c:	ec878793          	addi	a5,a5,-312 # ffffffffc02a7320 <swap_manager_fifo>
     int r = sm->init();
ffffffffc0203460:	6798                	ld	a4,8(a5)
     sm = &swap_manager_fifo;
ffffffffc0203462:	000afb97          	auipc	s7,0xaf
ffffffffc0203466:	42eb8b93          	addi	s7,s7,1070 # ffffffffc02b2890 <sm>
ffffffffc020346a:	00fbb023          	sd	a5,0(s7)
     int r = sm->init();
ffffffffc020346e:	9702                	jalr	a4
ffffffffc0203470:	892a                	mv	s2,a0
     
     if (r == 0)
ffffffffc0203472:	c10d                	beqz	a0,ffffffffc0203494 <swap_init+0x72>
          cprintf("SWAP: manager = %s\n", sm->name);
          check_swap();
     }

     return r;
}
ffffffffc0203474:	60ea                	ld	ra,152(sp)
ffffffffc0203476:	644a                	ld	s0,144(sp)
ffffffffc0203478:	64aa                	ld	s1,136(sp)
ffffffffc020347a:	79e6                	ld	s3,120(sp)
ffffffffc020347c:	7a46                	ld	s4,112(sp)
ffffffffc020347e:	7aa6                	ld	s5,104(sp)
ffffffffc0203480:	7b06                	ld	s6,96(sp)
ffffffffc0203482:	6be6                	ld	s7,88(sp)
ffffffffc0203484:	6c46                	ld	s8,80(sp)
ffffffffc0203486:	6ca6                	ld	s9,72(sp)
ffffffffc0203488:	6d06                	ld	s10,64(sp)
ffffffffc020348a:	7de2                	ld	s11,56(sp)
ffffffffc020348c:	854a                	mv	a0,s2
ffffffffc020348e:	690a                	ld	s2,128(sp)
ffffffffc0203490:	610d                	addi	sp,sp,160
ffffffffc0203492:	8082                	ret
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc0203494:	000bb783          	ld	a5,0(s7)
ffffffffc0203498:	00004517          	auipc	a0,0x4
ffffffffc020349c:	4d850513          	addi	a0,a0,1240 # ffffffffc0207970 <default_pmm_manager+0x748>
    return listelm->next;
ffffffffc02034a0:	000ab417          	auipc	s0,0xab
ffffffffc02034a4:	2d040413          	addi	s0,s0,720 # ffffffffc02ae770 <free_area>
ffffffffc02034a8:	638c                	ld	a1,0(a5)
          swap_init_ok = 1;
ffffffffc02034aa:	4785                	li	a5,1
ffffffffc02034ac:	000af717          	auipc	a4,0xaf
ffffffffc02034b0:	3ef72623          	sw	a5,1004(a4) # ffffffffc02b2898 <swap_init_ok>
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc02034b4:	ccdfc0ef          	jal	ra,ffffffffc0200180 <cprintf>
ffffffffc02034b8:	641c                	ld	a5,8(s0)

static void
check_swap(void)
{
    //backup mem env
     int ret, count = 0, total = 0, i;
ffffffffc02034ba:	4d01                	li	s10,0
ffffffffc02034bc:	4d81                	li	s11,0
     list_entry_t *le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc02034be:	34878163          	beq	a5,s0,ffffffffc0203800 <swap_init+0x3de>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02034c2:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc02034c6:	8b09                	andi	a4,a4,2
ffffffffc02034c8:	32070e63          	beqz	a4,ffffffffc0203804 <swap_init+0x3e2>
        count ++, total += p->property;
ffffffffc02034cc:	ff87a703          	lw	a4,-8(a5)
ffffffffc02034d0:	679c                	ld	a5,8(a5)
ffffffffc02034d2:	2d85                	addiw	s11,s11,1
ffffffffc02034d4:	01a70d3b          	addw	s10,a4,s10
     while ((le = list_next(le)) != &free_list) {
ffffffffc02034d8:	fe8795e3          	bne	a5,s0,ffffffffc02034c2 <swap_init+0xa0>
     }
     assert(total == nr_free_pages());
ffffffffc02034dc:	84ea                	mv	s1,s10
ffffffffc02034de:	8d5fe0ef          	jal	ra,ffffffffc0201db2 <nr_free_pages>
ffffffffc02034e2:	42951763          	bne	a0,s1,ffffffffc0203910 <swap_init+0x4ee>
     cprintf("BEGIN check_swap: count %d, total %d\n",count,total);
ffffffffc02034e6:	866a                	mv	a2,s10
ffffffffc02034e8:	85ee                	mv	a1,s11
ffffffffc02034ea:	00004517          	auipc	a0,0x4
ffffffffc02034ee:	49e50513          	addi	a0,a0,1182 # ffffffffc0207988 <default_pmm_manager+0x760>
ffffffffc02034f2:	c8ffc0ef          	jal	ra,ffffffffc0200180 <cprintf>
     
     //now we set the phy pages env     
     struct mm_struct *mm = mm_create();
ffffffffc02034f6:	319000ef          	jal	ra,ffffffffc020400e <mm_create>
ffffffffc02034fa:	8aaa                	mv	s5,a0
     assert(mm != NULL);
ffffffffc02034fc:	46050a63          	beqz	a0,ffffffffc0203970 <swap_init+0x54e>

     extern struct mm_struct *check_mm_struct;
     assert(check_mm_struct == NULL);
ffffffffc0203500:	000af797          	auipc	a5,0xaf
ffffffffc0203504:	3a078793          	addi	a5,a5,928 # ffffffffc02b28a0 <check_mm_struct>
ffffffffc0203508:	6398                	ld	a4,0(a5)
ffffffffc020350a:	3e071363          	bnez	a4,ffffffffc02038f0 <swap_init+0x4ce>

     check_mm_struct = mm;

     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc020350e:	000af717          	auipc	a4,0xaf
ffffffffc0203512:	35270713          	addi	a4,a4,850 # ffffffffc02b2860 <boot_pgdir>
ffffffffc0203516:	00073b03          	ld	s6,0(a4)
     check_mm_struct = mm;
ffffffffc020351a:	e388                	sd	a0,0(a5)
     assert(pgdir[0] == 0);
ffffffffc020351c:	000b3783          	ld	a5,0(s6)
     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0203520:	01653c23          	sd	s6,24(a0)
     assert(pgdir[0] == 0);
ffffffffc0203524:	42079663          	bnez	a5,ffffffffc0203950 <swap_init+0x52e>

     struct vma_struct *vma = vma_create(BEING_CHECK_VALID_VADDR, CHECK_VALID_VADDR, VM_WRITE | VM_READ);
ffffffffc0203528:	6599                	lui	a1,0x6
ffffffffc020352a:	460d                	li	a2,3
ffffffffc020352c:	6505                	lui	a0,0x1
ffffffffc020352e:	329000ef          	jal	ra,ffffffffc0204056 <vma_create>
ffffffffc0203532:	85aa                	mv	a1,a0
     assert(vma != NULL);
ffffffffc0203534:	52050a63          	beqz	a0,ffffffffc0203a68 <swap_init+0x646>

     insert_vma_struct(mm, vma);
ffffffffc0203538:	8556                	mv	a0,s5
ffffffffc020353a:	38b000ef          	jal	ra,ffffffffc02040c4 <insert_vma_struct>

     //setup the temp Page Table vaddr 0~4MB
     cprintf("setup Page Table for vaddr 0X1000, so alloc a page\n");
ffffffffc020353e:	00004517          	auipc	a0,0x4
ffffffffc0203542:	4ba50513          	addi	a0,a0,1210 # ffffffffc02079f8 <default_pmm_manager+0x7d0>
ffffffffc0203546:	c3bfc0ef          	jal	ra,ffffffffc0200180 <cprintf>
     pte_t *temp_ptep=NULL;
     temp_ptep = get_pte(mm->pgdir, BEING_CHECK_VALID_VADDR, 1);
ffffffffc020354a:	018ab503          	ld	a0,24(s5)
ffffffffc020354e:	4605                	li	a2,1
ffffffffc0203550:	6585                	lui	a1,0x1
ffffffffc0203552:	89bfe0ef          	jal	ra,ffffffffc0201dec <get_pte>
     assert(temp_ptep!= NULL);
ffffffffc0203556:	4c050963          	beqz	a0,ffffffffc0203a28 <swap_init+0x606>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc020355a:	00004517          	auipc	a0,0x4
ffffffffc020355e:	4ee50513          	addi	a0,a0,1262 # ffffffffc0207a48 <default_pmm_manager+0x820>
ffffffffc0203562:	000ab497          	auipc	s1,0xab
ffffffffc0203566:	24648493          	addi	s1,s1,582 # ffffffffc02ae7a8 <check_rp>
ffffffffc020356a:	c17fc0ef          	jal	ra,ffffffffc0200180 <cprintf>
     
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc020356e:	000ab997          	auipc	s3,0xab
ffffffffc0203572:	25a98993          	addi	s3,s3,602 # ffffffffc02ae7c8 <swap_in_seq_no>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc0203576:	8a26                	mv	s4,s1
          check_rp[i] = alloc_page();
ffffffffc0203578:	4505                	li	a0,1
ffffffffc020357a:	f66fe0ef          	jal	ra,ffffffffc0201ce0 <alloc_pages>
ffffffffc020357e:	00aa3023          	sd	a0,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bb8>
          assert(check_rp[i] != NULL );
ffffffffc0203582:	2c050f63          	beqz	a0,ffffffffc0203860 <swap_init+0x43e>
ffffffffc0203586:	651c                	ld	a5,8(a0)
          assert(!PageProperty(check_rp[i]));
ffffffffc0203588:	8b89                	andi	a5,a5,2
ffffffffc020358a:	34079363          	bnez	a5,ffffffffc02038d0 <swap_init+0x4ae>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc020358e:	0a21                	addi	s4,s4,8
ffffffffc0203590:	ff3a14e3          	bne	s4,s3,ffffffffc0203578 <swap_init+0x156>
     }
     list_entry_t free_list_store = free_list;
ffffffffc0203594:	601c                	ld	a5,0(s0)
     assert(list_empty(&free_list));
     
     //assert(alloc_page() == NULL);
     
     unsigned int nr_free_store = nr_free;
     nr_free = 0;
ffffffffc0203596:	000aba17          	auipc	s4,0xab
ffffffffc020359a:	212a0a13          	addi	s4,s4,530 # ffffffffc02ae7a8 <check_rp>
    elm->prev = elm->next = elm;
ffffffffc020359e:	e000                	sd	s0,0(s0)
     list_entry_t free_list_store = free_list;
ffffffffc02035a0:	ec3e                	sd	a5,24(sp)
ffffffffc02035a2:	641c                	ld	a5,8(s0)
ffffffffc02035a4:	e400                	sd	s0,8(s0)
ffffffffc02035a6:	f03e                	sd	a5,32(sp)
     unsigned int nr_free_store = nr_free;
ffffffffc02035a8:	481c                	lw	a5,16(s0)
ffffffffc02035aa:	f43e                	sd	a5,40(sp)
     nr_free = 0;
ffffffffc02035ac:	000ab797          	auipc	a5,0xab
ffffffffc02035b0:	1c07aa23          	sw	zero,468(a5) # ffffffffc02ae780 <free_area+0x10>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
        free_pages(check_rp[i],1);
ffffffffc02035b4:	000a3503          	ld	a0,0(s4)
ffffffffc02035b8:	4585                	li	a1,1
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc02035ba:	0a21                	addi	s4,s4,8
        free_pages(check_rp[i],1);
ffffffffc02035bc:	fb6fe0ef          	jal	ra,ffffffffc0201d72 <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc02035c0:	ff3a1ae3          	bne	s4,s3,ffffffffc02035b4 <swap_init+0x192>
     }
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc02035c4:	01042a03          	lw	s4,16(s0)
ffffffffc02035c8:	4791                	li	a5,4
ffffffffc02035ca:	42fa1f63          	bne	s4,a5,ffffffffc0203a08 <swap_init+0x5e6>
     
     cprintf("set up init env for check_swap begin!\n");
ffffffffc02035ce:	00004517          	auipc	a0,0x4
ffffffffc02035d2:	50250513          	addi	a0,a0,1282 # ffffffffc0207ad0 <default_pmm_manager+0x8a8>
ffffffffc02035d6:	babfc0ef          	jal	ra,ffffffffc0200180 <cprintf>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc02035da:	6705                	lui	a4,0x1
     //setup initial vir_page<->phy_page environment for page relpacement algorithm 

     
     pgfault_num=0;
ffffffffc02035dc:	000af797          	auipc	a5,0xaf
ffffffffc02035e0:	2c07a623          	sw	zero,716(a5) # ffffffffc02b28a8 <pgfault_num>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc02035e4:	4629                	li	a2,10
ffffffffc02035e6:	00c70023          	sb	a2,0(a4) # 1000 <_binary_obj___user_faultread_out_size-0x8bb8>
     assert(pgfault_num==1);
ffffffffc02035ea:	000af697          	auipc	a3,0xaf
ffffffffc02035ee:	2be6a683          	lw	a3,702(a3) # ffffffffc02b28a8 <pgfault_num>
ffffffffc02035f2:	4585                	li	a1,1
ffffffffc02035f4:	000af797          	auipc	a5,0xaf
ffffffffc02035f8:	2b478793          	addi	a5,a5,692 # ffffffffc02b28a8 <pgfault_num>
ffffffffc02035fc:	54b69663          	bne	a3,a1,ffffffffc0203b48 <swap_init+0x726>
     *(unsigned char *)0x1010 = 0x0a;
ffffffffc0203600:	00c70823          	sb	a2,16(a4)
     assert(pgfault_num==1);
ffffffffc0203604:	4398                	lw	a4,0(a5)
ffffffffc0203606:	2701                	sext.w	a4,a4
ffffffffc0203608:	3ed71063          	bne	a4,a3,ffffffffc02039e8 <swap_init+0x5c6>
     *(unsigned char *)0x2000 = 0x0b;
ffffffffc020360c:	6689                	lui	a3,0x2
ffffffffc020360e:	462d                	li	a2,11
ffffffffc0203610:	00c68023          	sb	a2,0(a3) # 2000 <_binary_obj___user_faultread_out_size-0x7bb8>
     assert(pgfault_num==2);
ffffffffc0203614:	4398                	lw	a4,0(a5)
ffffffffc0203616:	4589                	li	a1,2
ffffffffc0203618:	2701                	sext.w	a4,a4
ffffffffc020361a:	4ab71763          	bne	a4,a1,ffffffffc0203ac8 <swap_init+0x6a6>
     *(unsigned char *)0x2010 = 0x0b;
ffffffffc020361e:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==2);
ffffffffc0203622:	4394                	lw	a3,0(a5)
ffffffffc0203624:	2681                	sext.w	a3,a3
ffffffffc0203626:	4ce69163          	bne	a3,a4,ffffffffc0203ae8 <swap_init+0x6c6>
     *(unsigned char *)0x3000 = 0x0c;
ffffffffc020362a:	668d                	lui	a3,0x3
ffffffffc020362c:	4631                	li	a2,12
ffffffffc020362e:	00c68023          	sb	a2,0(a3) # 3000 <_binary_obj___user_faultread_out_size-0x6bb8>
     assert(pgfault_num==3);
ffffffffc0203632:	4398                	lw	a4,0(a5)
ffffffffc0203634:	458d                	li	a1,3
ffffffffc0203636:	2701                	sext.w	a4,a4
ffffffffc0203638:	4cb71863          	bne	a4,a1,ffffffffc0203b08 <swap_init+0x6e6>
     *(unsigned char *)0x3010 = 0x0c;
ffffffffc020363c:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==3);
ffffffffc0203640:	4394                	lw	a3,0(a5)
ffffffffc0203642:	2681                	sext.w	a3,a3
ffffffffc0203644:	4ee69263          	bne	a3,a4,ffffffffc0203b28 <swap_init+0x706>
     *(unsigned char *)0x4000 = 0x0d;
ffffffffc0203648:	6691                	lui	a3,0x4
ffffffffc020364a:	4635                	li	a2,13
ffffffffc020364c:	00c68023          	sb	a2,0(a3) # 4000 <_binary_obj___user_faultread_out_size-0x5bb8>
     assert(pgfault_num==4);
ffffffffc0203650:	4398                	lw	a4,0(a5)
ffffffffc0203652:	2701                	sext.w	a4,a4
ffffffffc0203654:	43471a63          	bne	a4,s4,ffffffffc0203a88 <swap_init+0x666>
     *(unsigned char *)0x4010 = 0x0d;
ffffffffc0203658:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==4);
ffffffffc020365c:	439c                	lw	a5,0(a5)
ffffffffc020365e:	2781                	sext.w	a5,a5
ffffffffc0203660:	44e79463          	bne	a5,a4,ffffffffc0203aa8 <swap_init+0x686>
     
     check_content_set();
     assert( nr_free == 0);         
ffffffffc0203664:	481c                	lw	a5,16(s0)
ffffffffc0203666:	2c079563          	bnez	a5,ffffffffc0203930 <swap_init+0x50e>
ffffffffc020366a:	000ab797          	auipc	a5,0xab
ffffffffc020366e:	15e78793          	addi	a5,a5,350 # ffffffffc02ae7c8 <swap_in_seq_no>
ffffffffc0203672:	000ab717          	auipc	a4,0xab
ffffffffc0203676:	17e70713          	addi	a4,a4,382 # ffffffffc02ae7f0 <swap_out_seq_no>
ffffffffc020367a:	000ab617          	auipc	a2,0xab
ffffffffc020367e:	17660613          	addi	a2,a2,374 # ffffffffc02ae7f0 <swap_out_seq_no>
     for(i = 0; i<MAX_SEQ_NO ; i++) 
         swap_out_seq_no[i]=swap_in_seq_no[i]=-1;
ffffffffc0203682:	56fd                	li	a3,-1
ffffffffc0203684:	c394                	sw	a3,0(a5)
ffffffffc0203686:	c314                	sw	a3,0(a4)
     for(i = 0; i<MAX_SEQ_NO ; i++) 
ffffffffc0203688:	0791                	addi	a5,a5,4
ffffffffc020368a:	0711                	addi	a4,a4,4
ffffffffc020368c:	fec79ce3          	bne	a5,a2,ffffffffc0203684 <swap_init+0x262>
ffffffffc0203690:	000ab717          	auipc	a4,0xab
ffffffffc0203694:	0f870713          	addi	a4,a4,248 # ffffffffc02ae788 <check_ptep>
ffffffffc0203698:	000ab697          	auipc	a3,0xab
ffffffffc020369c:	11068693          	addi	a3,a3,272 # ffffffffc02ae7a8 <check_rp>
ffffffffc02036a0:	6585                	lui	a1,0x1
    if (PPN(pa) >= npage) {
ffffffffc02036a2:	000afc17          	auipc	s8,0xaf
ffffffffc02036a6:	1c6c0c13          	addi	s8,s8,454 # ffffffffc02b2868 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc02036aa:	000afc97          	auipc	s9,0xaf
ffffffffc02036ae:	1c6c8c93          	addi	s9,s9,454 # ffffffffc02b2870 <pages>
     
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         check_ptep[i]=0;
ffffffffc02036b2:	00073023          	sd	zero,0(a4)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc02036b6:	4601                	li	a2,0
ffffffffc02036b8:	855a                	mv	a0,s6
ffffffffc02036ba:	e836                	sd	a3,16(sp)
ffffffffc02036bc:	e42e                	sd	a1,8(sp)
         check_ptep[i]=0;
ffffffffc02036be:	e03a                	sd	a4,0(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc02036c0:	f2cfe0ef          	jal	ra,ffffffffc0201dec <get_pte>
ffffffffc02036c4:	6702                	ld	a4,0(sp)
         //cprintf("i %d, check_ptep addr %x, value %x\n", i, check_ptep[i], *check_ptep[i]);
         assert(check_ptep[i] != NULL);
ffffffffc02036c6:	65a2                	ld	a1,8(sp)
ffffffffc02036c8:	66c2                	ld	a3,16(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc02036ca:	e308                	sd	a0,0(a4)
         assert(check_ptep[i] != NULL);
ffffffffc02036cc:	1c050663          	beqz	a0,ffffffffc0203898 <swap_init+0x476>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc02036d0:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc02036d2:	0017f613          	andi	a2,a5,1
ffffffffc02036d6:	1e060163          	beqz	a2,ffffffffc02038b8 <swap_init+0x496>
    if (PPN(pa) >= npage) {
ffffffffc02036da:	000c3603          	ld	a2,0(s8)
    return pa2page(PTE_ADDR(pte));
ffffffffc02036de:	078a                	slli	a5,a5,0x2
ffffffffc02036e0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02036e2:	14c7f363          	bgeu	a5,a2,ffffffffc0203828 <swap_init+0x406>
    return &pages[PPN(pa) - nbase];
ffffffffc02036e6:	00005617          	auipc	a2,0x5
ffffffffc02036ea:	48a60613          	addi	a2,a2,1162 # ffffffffc0208b70 <nbase>
ffffffffc02036ee:	00063a03          	ld	s4,0(a2)
ffffffffc02036f2:	000cb603          	ld	a2,0(s9)
ffffffffc02036f6:	6288                	ld	a0,0(a3)
ffffffffc02036f8:	414787b3          	sub	a5,a5,s4
ffffffffc02036fc:	079a                	slli	a5,a5,0x6
ffffffffc02036fe:	97b2                	add	a5,a5,a2
ffffffffc0203700:	14f51063          	bne	a0,a5,ffffffffc0203840 <swap_init+0x41e>
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0203704:	6785                	lui	a5,0x1
ffffffffc0203706:	95be                	add	a1,a1,a5
ffffffffc0203708:	6795                	lui	a5,0x5
ffffffffc020370a:	0721                	addi	a4,a4,8
ffffffffc020370c:	06a1                	addi	a3,a3,8
ffffffffc020370e:	faf592e3          	bne	a1,a5,ffffffffc02036b2 <swap_init+0x290>
         assert((*check_ptep[i] & PTE_V));          
     }
     cprintf("set up init env for check_swap over!\n");
ffffffffc0203712:	00004517          	auipc	a0,0x4
ffffffffc0203716:	46650513          	addi	a0,a0,1126 # ffffffffc0207b78 <default_pmm_manager+0x950>
ffffffffc020371a:	a67fc0ef          	jal	ra,ffffffffc0200180 <cprintf>
    int ret = sm->check_swap();
ffffffffc020371e:	000bb783          	ld	a5,0(s7)
ffffffffc0203722:	7f9c                	ld	a5,56(a5)
ffffffffc0203724:	9782                	jalr	a5
     // now access the virt pages to test  page relpacement algorithm 
     ret=check_content_access();
     assert(ret==0);
ffffffffc0203726:	32051163          	bnez	a0,ffffffffc0203a48 <swap_init+0x626>

     nr_free = nr_free_store;
ffffffffc020372a:	77a2                	ld	a5,40(sp)
ffffffffc020372c:	c81c                	sw	a5,16(s0)
     free_list = free_list_store;
ffffffffc020372e:	67e2                	ld	a5,24(sp)
ffffffffc0203730:	e01c                	sd	a5,0(s0)
ffffffffc0203732:	7782                	ld	a5,32(sp)
ffffffffc0203734:	e41c                	sd	a5,8(s0)

     //restore kernel mem env
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         free_pages(check_rp[i],1);
ffffffffc0203736:	6088                	ld	a0,0(s1)
ffffffffc0203738:	4585                	li	a1,1
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc020373a:	04a1                	addi	s1,s1,8
         free_pages(check_rp[i],1);
ffffffffc020373c:	e36fe0ef          	jal	ra,ffffffffc0201d72 <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0203740:	ff349be3          	bne	s1,s3,ffffffffc0203736 <swap_init+0x314>
     } 

     //free_page(pte2page(*temp_ptep));

     mm->pgdir = NULL;
ffffffffc0203744:	000abc23          	sd	zero,24(s5)
     mm_destroy(mm);
ffffffffc0203748:	8556                	mv	a0,s5
ffffffffc020374a:	24b000ef          	jal	ra,ffffffffc0204194 <mm_destroy>
     check_mm_struct = NULL;

     pde_t *pd1=pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
ffffffffc020374e:	000af797          	auipc	a5,0xaf
ffffffffc0203752:	11278793          	addi	a5,a5,274 # ffffffffc02b2860 <boot_pgdir>
ffffffffc0203756:	639c                	ld	a5,0(a5)
    if (PPN(pa) >= npage) {
ffffffffc0203758:	000c3703          	ld	a4,0(s8)
     check_mm_struct = NULL;
ffffffffc020375c:	000af697          	auipc	a3,0xaf
ffffffffc0203760:	1406b223          	sd	zero,324(a3) # ffffffffc02b28a0 <check_mm_struct>
    return pa2page(PDE_ADDR(pde));
ffffffffc0203764:	639c                	ld	a5,0(a5)
ffffffffc0203766:	078a                	slli	a5,a5,0x2
ffffffffc0203768:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020376a:	0ae7fd63          	bgeu	a5,a4,ffffffffc0203824 <swap_init+0x402>
    return &pages[PPN(pa) - nbase];
ffffffffc020376e:	414786b3          	sub	a3,a5,s4
ffffffffc0203772:	069a                	slli	a3,a3,0x6
    return page - pages + nbase;
ffffffffc0203774:	8699                	srai	a3,a3,0x6
ffffffffc0203776:	96d2                	add	a3,a3,s4
    return KADDR(page2pa(page));
ffffffffc0203778:	00c69793          	slli	a5,a3,0xc
ffffffffc020377c:	83b1                	srli	a5,a5,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc020377e:	000cb503          	ld	a0,0(s9)
    return page2ppn(page) << PGSHIFT;
ffffffffc0203782:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203784:	22e7f663          	bgeu	a5,a4,ffffffffc02039b0 <swap_init+0x58e>
     free_page(pde2page(pd0[0]));
ffffffffc0203788:	000af797          	auipc	a5,0xaf
ffffffffc020378c:	0f87b783          	ld	a5,248(a5) # ffffffffc02b2880 <va_pa_offset>
ffffffffc0203790:	96be                	add	a3,a3,a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0203792:	629c                	ld	a5,0(a3)
ffffffffc0203794:	078a                	slli	a5,a5,0x2
ffffffffc0203796:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203798:	08e7f663          	bgeu	a5,a4,ffffffffc0203824 <swap_init+0x402>
    return &pages[PPN(pa) - nbase];
ffffffffc020379c:	414787b3          	sub	a5,a5,s4
ffffffffc02037a0:	079a                	slli	a5,a5,0x6
ffffffffc02037a2:	953e                	add	a0,a0,a5
ffffffffc02037a4:	4585                	li	a1,1
ffffffffc02037a6:	dccfe0ef          	jal	ra,ffffffffc0201d72 <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc02037aa:	000b3783          	ld	a5,0(s6)
    if (PPN(pa) >= npage) {
ffffffffc02037ae:	000c3703          	ld	a4,0(s8)
    return pa2page(PDE_ADDR(pde));
ffffffffc02037b2:	078a                	slli	a5,a5,0x2
ffffffffc02037b4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02037b6:	06e7f763          	bgeu	a5,a4,ffffffffc0203824 <swap_init+0x402>
    return &pages[PPN(pa) - nbase];
ffffffffc02037ba:	000cb503          	ld	a0,0(s9)
ffffffffc02037be:	414787b3          	sub	a5,a5,s4
ffffffffc02037c2:	079a                	slli	a5,a5,0x6
     free_page(pde2page(pd1[0]));
ffffffffc02037c4:	4585                	li	a1,1
ffffffffc02037c6:	953e                	add	a0,a0,a5
ffffffffc02037c8:	daafe0ef          	jal	ra,ffffffffc0201d72 <free_pages>
     pgdir[0] = 0;
ffffffffc02037cc:	000b3023          	sd	zero,0(s6)
  asm volatile("sfence.vma");
ffffffffc02037d0:	12000073          	sfence.vma
    return listelm->next;
ffffffffc02037d4:	641c                	ld	a5,8(s0)
     flush_tlb();

     le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc02037d6:	00878a63          	beq	a5,s0,ffffffffc02037ea <swap_init+0x3c8>
         struct Page *p = le2page(le, page_link);
         count --, total -= p->property;
ffffffffc02037da:	ff87a703          	lw	a4,-8(a5)
ffffffffc02037de:	679c                	ld	a5,8(a5)
ffffffffc02037e0:	3dfd                	addiw	s11,s11,-1
ffffffffc02037e2:	40ed0d3b          	subw	s10,s10,a4
     while ((le = list_next(le)) != &free_list) {
ffffffffc02037e6:	fe879ae3          	bne	a5,s0,ffffffffc02037da <swap_init+0x3b8>
     }
     assert(count==0);
ffffffffc02037ea:	1c0d9f63          	bnez	s11,ffffffffc02039c8 <swap_init+0x5a6>
     assert(total==0);
ffffffffc02037ee:	1a0d1163          	bnez	s10,ffffffffc0203990 <swap_init+0x56e>

     cprintf("check_swap() succeeded!\n");
ffffffffc02037f2:	00004517          	auipc	a0,0x4
ffffffffc02037f6:	3d650513          	addi	a0,a0,982 # ffffffffc0207bc8 <default_pmm_manager+0x9a0>
ffffffffc02037fa:	987fc0ef          	jal	ra,ffffffffc0200180 <cprintf>
}
ffffffffc02037fe:	b99d                	j	ffffffffc0203474 <swap_init+0x52>
     while ((le = list_next(le)) != &free_list) {
ffffffffc0203800:	4481                	li	s1,0
ffffffffc0203802:	b9f1                	j	ffffffffc02034de <swap_init+0xbc>
        assert(PageProperty(p));
ffffffffc0203804:	00003697          	auipc	a3,0x3
ffffffffc0203808:	67c68693          	addi	a3,a3,1660 # ffffffffc0206e80 <commands+0x740>
ffffffffc020380c:	00003617          	auipc	a2,0x3
ffffffffc0203810:	38460613          	addi	a2,a2,900 # ffffffffc0206b90 <commands+0x450>
ffffffffc0203814:	0bc00593          	li	a1,188
ffffffffc0203818:	00004517          	auipc	a0,0x4
ffffffffc020381c:	14850513          	addi	a0,a0,328 # ffffffffc0207960 <default_pmm_manager+0x738>
ffffffffc0203820:	c5bfc0ef          	jal	ra,ffffffffc020047a <__panic>
ffffffffc0203824:	be3ff0ef          	jal	ra,ffffffffc0203406 <pa2page.part.0>
        panic("pa2page called with invalid pa");
ffffffffc0203828:	00004617          	auipc	a2,0x4
ffffffffc020382c:	b0860613          	addi	a2,a2,-1272 # ffffffffc0207330 <default_pmm_manager+0x108>
ffffffffc0203830:	06200593          	li	a1,98
ffffffffc0203834:	00004517          	auipc	a0,0x4
ffffffffc0203838:	a5450513          	addi	a0,a0,-1452 # ffffffffc0207288 <default_pmm_manager+0x60>
ffffffffc020383c:	c3ffc0ef          	jal	ra,ffffffffc020047a <__panic>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc0203840:	00004697          	auipc	a3,0x4
ffffffffc0203844:	31068693          	addi	a3,a3,784 # ffffffffc0207b50 <default_pmm_manager+0x928>
ffffffffc0203848:	00003617          	auipc	a2,0x3
ffffffffc020384c:	34860613          	addi	a2,a2,840 # ffffffffc0206b90 <commands+0x450>
ffffffffc0203850:	0fc00593          	li	a1,252
ffffffffc0203854:	00004517          	auipc	a0,0x4
ffffffffc0203858:	10c50513          	addi	a0,a0,268 # ffffffffc0207960 <default_pmm_manager+0x738>
ffffffffc020385c:	c1ffc0ef          	jal	ra,ffffffffc020047a <__panic>
          assert(check_rp[i] != NULL );
ffffffffc0203860:	00004697          	auipc	a3,0x4
ffffffffc0203864:	21068693          	addi	a3,a3,528 # ffffffffc0207a70 <default_pmm_manager+0x848>
ffffffffc0203868:	00003617          	auipc	a2,0x3
ffffffffc020386c:	32860613          	addi	a2,a2,808 # ffffffffc0206b90 <commands+0x450>
ffffffffc0203870:	0dc00593          	li	a1,220
ffffffffc0203874:	00004517          	auipc	a0,0x4
ffffffffc0203878:	0ec50513          	addi	a0,a0,236 # ffffffffc0207960 <default_pmm_manager+0x738>
ffffffffc020387c:	bfffc0ef          	jal	ra,ffffffffc020047a <__panic>
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
ffffffffc0203880:	00004617          	auipc	a2,0x4
ffffffffc0203884:	0c060613          	addi	a2,a2,192 # ffffffffc0207940 <default_pmm_manager+0x718>
ffffffffc0203888:	02800593          	li	a1,40
ffffffffc020388c:	00004517          	auipc	a0,0x4
ffffffffc0203890:	0d450513          	addi	a0,a0,212 # ffffffffc0207960 <default_pmm_manager+0x738>
ffffffffc0203894:	be7fc0ef          	jal	ra,ffffffffc020047a <__panic>
         assert(check_ptep[i] != NULL);
ffffffffc0203898:	00004697          	auipc	a3,0x4
ffffffffc020389c:	2a068693          	addi	a3,a3,672 # ffffffffc0207b38 <default_pmm_manager+0x910>
ffffffffc02038a0:	00003617          	auipc	a2,0x3
ffffffffc02038a4:	2f060613          	addi	a2,a2,752 # ffffffffc0206b90 <commands+0x450>
ffffffffc02038a8:	0fb00593          	li	a1,251
ffffffffc02038ac:	00004517          	auipc	a0,0x4
ffffffffc02038b0:	0b450513          	addi	a0,a0,180 # ffffffffc0207960 <default_pmm_manager+0x738>
ffffffffc02038b4:	bc7fc0ef          	jal	ra,ffffffffc020047a <__panic>
        panic("pte2page called with invalid pte");
ffffffffc02038b8:	00004617          	auipc	a2,0x4
ffffffffc02038bc:	a9860613          	addi	a2,a2,-1384 # ffffffffc0207350 <default_pmm_manager+0x128>
ffffffffc02038c0:	07400593          	li	a1,116
ffffffffc02038c4:	00004517          	auipc	a0,0x4
ffffffffc02038c8:	9c450513          	addi	a0,a0,-1596 # ffffffffc0207288 <default_pmm_manager+0x60>
ffffffffc02038cc:	baffc0ef          	jal	ra,ffffffffc020047a <__panic>
          assert(!PageProperty(check_rp[i]));
ffffffffc02038d0:	00004697          	auipc	a3,0x4
ffffffffc02038d4:	1b868693          	addi	a3,a3,440 # ffffffffc0207a88 <default_pmm_manager+0x860>
ffffffffc02038d8:	00003617          	auipc	a2,0x3
ffffffffc02038dc:	2b860613          	addi	a2,a2,696 # ffffffffc0206b90 <commands+0x450>
ffffffffc02038e0:	0dd00593          	li	a1,221
ffffffffc02038e4:	00004517          	auipc	a0,0x4
ffffffffc02038e8:	07c50513          	addi	a0,a0,124 # ffffffffc0207960 <default_pmm_manager+0x738>
ffffffffc02038ec:	b8ffc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(check_mm_struct == NULL);
ffffffffc02038f0:	00004697          	auipc	a3,0x4
ffffffffc02038f4:	0d068693          	addi	a3,a3,208 # ffffffffc02079c0 <default_pmm_manager+0x798>
ffffffffc02038f8:	00003617          	auipc	a2,0x3
ffffffffc02038fc:	29860613          	addi	a2,a2,664 # ffffffffc0206b90 <commands+0x450>
ffffffffc0203900:	0c700593          	li	a1,199
ffffffffc0203904:	00004517          	auipc	a0,0x4
ffffffffc0203908:	05c50513          	addi	a0,a0,92 # ffffffffc0207960 <default_pmm_manager+0x738>
ffffffffc020390c:	b6ffc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(total == nr_free_pages());
ffffffffc0203910:	00003697          	auipc	a3,0x3
ffffffffc0203914:	59868693          	addi	a3,a3,1432 # ffffffffc0206ea8 <commands+0x768>
ffffffffc0203918:	00003617          	auipc	a2,0x3
ffffffffc020391c:	27860613          	addi	a2,a2,632 # ffffffffc0206b90 <commands+0x450>
ffffffffc0203920:	0bf00593          	li	a1,191
ffffffffc0203924:	00004517          	auipc	a0,0x4
ffffffffc0203928:	03c50513          	addi	a0,a0,60 # ffffffffc0207960 <default_pmm_manager+0x738>
ffffffffc020392c:	b4ffc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert( nr_free == 0);         
ffffffffc0203930:	00003697          	auipc	a3,0x3
ffffffffc0203934:	72068693          	addi	a3,a3,1824 # ffffffffc0207050 <commands+0x910>
ffffffffc0203938:	00003617          	auipc	a2,0x3
ffffffffc020393c:	25860613          	addi	a2,a2,600 # ffffffffc0206b90 <commands+0x450>
ffffffffc0203940:	0f300593          	li	a1,243
ffffffffc0203944:	00004517          	auipc	a0,0x4
ffffffffc0203948:	01c50513          	addi	a0,a0,28 # ffffffffc0207960 <default_pmm_manager+0x738>
ffffffffc020394c:	b2ffc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(pgdir[0] == 0);
ffffffffc0203950:	00004697          	auipc	a3,0x4
ffffffffc0203954:	08868693          	addi	a3,a3,136 # ffffffffc02079d8 <default_pmm_manager+0x7b0>
ffffffffc0203958:	00003617          	auipc	a2,0x3
ffffffffc020395c:	23860613          	addi	a2,a2,568 # ffffffffc0206b90 <commands+0x450>
ffffffffc0203960:	0cc00593          	li	a1,204
ffffffffc0203964:	00004517          	auipc	a0,0x4
ffffffffc0203968:	ffc50513          	addi	a0,a0,-4 # ffffffffc0207960 <default_pmm_manager+0x738>
ffffffffc020396c:	b0ffc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(mm != NULL);
ffffffffc0203970:	00004697          	auipc	a3,0x4
ffffffffc0203974:	04068693          	addi	a3,a3,64 # ffffffffc02079b0 <default_pmm_manager+0x788>
ffffffffc0203978:	00003617          	auipc	a2,0x3
ffffffffc020397c:	21860613          	addi	a2,a2,536 # ffffffffc0206b90 <commands+0x450>
ffffffffc0203980:	0c400593          	li	a1,196
ffffffffc0203984:	00004517          	auipc	a0,0x4
ffffffffc0203988:	fdc50513          	addi	a0,a0,-36 # ffffffffc0207960 <default_pmm_manager+0x738>
ffffffffc020398c:	aeffc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(total==0);
ffffffffc0203990:	00004697          	auipc	a3,0x4
ffffffffc0203994:	22868693          	addi	a3,a3,552 # ffffffffc0207bb8 <default_pmm_manager+0x990>
ffffffffc0203998:	00003617          	auipc	a2,0x3
ffffffffc020399c:	1f860613          	addi	a2,a2,504 # ffffffffc0206b90 <commands+0x450>
ffffffffc02039a0:	11e00593          	li	a1,286
ffffffffc02039a4:	00004517          	auipc	a0,0x4
ffffffffc02039a8:	fbc50513          	addi	a0,a0,-68 # ffffffffc0207960 <default_pmm_manager+0x738>
ffffffffc02039ac:	acffc0ef          	jal	ra,ffffffffc020047a <__panic>
    return KADDR(page2pa(page));
ffffffffc02039b0:	00004617          	auipc	a2,0x4
ffffffffc02039b4:	8b060613          	addi	a2,a2,-1872 # ffffffffc0207260 <default_pmm_manager+0x38>
ffffffffc02039b8:	06900593          	li	a1,105
ffffffffc02039bc:	00004517          	auipc	a0,0x4
ffffffffc02039c0:	8cc50513          	addi	a0,a0,-1844 # ffffffffc0207288 <default_pmm_manager+0x60>
ffffffffc02039c4:	ab7fc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(count==0);
ffffffffc02039c8:	00004697          	auipc	a3,0x4
ffffffffc02039cc:	1e068693          	addi	a3,a3,480 # ffffffffc0207ba8 <default_pmm_manager+0x980>
ffffffffc02039d0:	00003617          	auipc	a2,0x3
ffffffffc02039d4:	1c060613          	addi	a2,a2,448 # ffffffffc0206b90 <commands+0x450>
ffffffffc02039d8:	11d00593          	li	a1,285
ffffffffc02039dc:	00004517          	auipc	a0,0x4
ffffffffc02039e0:	f8450513          	addi	a0,a0,-124 # ffffffffc0207960 <default_pmm_manager+0x738>
ffffffffc02039e4:	a97fc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(pgfault_num==1);
ffffffffc02039e8:	00004697          	auipc	a3,0x4
ffffffffc02039ec:	11068693          	addi	a3,a3,272 # ffffffffc0207af8 <default_pmm_manager+0x8d0>
ffffffffc02039f0:	00003617          	auipc	a2,0x3
ffffffffc02039f4:	1a060613          	addi	a2,a2,416 # ffffffffc0206b90 <commands+0x450>
ffffffffc02039f8:	09500593          	li	a1,149
ffffffffc02039fc:	00004517          	auipc	a0,0x4
ffffffffc0203a00:	f6450513          	addi	a0,a0,-156 # ffffffffc0207960 <default_pmm_manager+0x738>
ffffffffc0203a04:	a77fc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc0203a08:	00004697          	auipc	a3,0x4
ffffffffc0203a0c:	0a068693          	addi	a3,a3,160 # ffffffffc0207aa8 <default_pmm_manager+0x880>
ffffffffc0203a10:	00003617          	auipc	a2,0x3
ffffffffc0203a14:	18060613          	addi	a2,a2,384 # ffffffffc0206b90 <commands+0x450>
ffffffffc0203a18:	0ea00593          	li	a1,234
ffffffffc0203a1c:	00004517          	auipc	a0,0x4
ffffffffc0203a20:	f4450513          	addi	a0,a0,-188 # ffffffffc0207960 <default_pmm_manager+0x738>
ffffffffc0203a24:	a57fc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(temp_ptep!= NULL);
ffffffffc0203a28:	00004697          	auipc	a3,0x4
ffffffffc0203a2c:	00868693          	addi	a3,a3,8 # ffffffffc0207a30 <default_pmm_manager+0x808>
ffffffffc0203a30:	00003617          	auipc	a2,0x3
ffffffffc0203a34:	16060613          	addi	a2,a2,352 # ffffffffc0206b90 <commands+0x450>
ffffffffc0203a38:	0d700593          	li	a1,215
ffffffffc0203a3c:	00004517          	auipc	a0,0x4
ffffffffc0203a40:	f2450513          	addi	a0,a0,-220 # ffffffffc0207960 <default_pmm_manager+0x738>
ffffffffc0203a44:	a37fc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(ret==0);
ffffffffc0203a48:	00004697          	auipc	a3,0x4
ffffffffc0203a4c:	15868693          	addi	a3,a3,344 # ffffffffc0207ba0 <default_pmm_manager+0x978>
ffffffffc0203a50:	00003617          	auipc	a2,0x3
ffffffffc0203a54:	14060613          	addi	a2,a2,320 # ffffffffc0206b90 <commands+0x450>
ffffffffc0203a58:	10200593          	li	a1,258
ffffffffc0203a5c:	00004517          	auipc	a0,0x4
ffffffffc0203a60:	f0450513          	addi	a0,a0,-252 # ffffffffc0207960 <default_pmm_manager+0x738>
ffffffffc0203a64:	a17fc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(vma != NULL);
ffffffffc0203a68:	00004697          	auipc	a3,0x4
ffffffffc0203a6c:	f8068693          	addi	a3,a3,-128 # ffffffffc02079e8 <default_pmm_manager+0x7c0>
ffffffffc0203a70:	00003617          	auipc	a2,0x3
ffffffffc0203a74:	12060613          	addi	a2,a2,288 # ffffffffc0206b90 <commands+0x450>
ffffffffc0203a78:	0cf00593          	li	a1,207
ffffffffc0203a7c:	00004517          	auipc	a0,0x4
ffffffffc0203a80:	ee450513          	addi	a0,a0,-284 # ffffffffc0207960 <default_pmm_manager+0x738>
ffffffffc0203a84:	9f7fc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(pgfault_num==4);
ffffffffc0203a88:	00004697          	auipc	a3,0x4
ffffffffc0203a8c:	0a068693          	addi	a3,a3,160 # ffffffffc0207b28 <default_pmm_manager+0x900>
ffffffffc0203a90:	00003617          	auipc	a2,0x3
ffffffffc0203a94:	10060613          	addi	a2,a2,256 # ffffffffc0206b90 <commands+0x450>
ffffffffc0203a98:	09f00593          	li	a1,159
ffffffffc0203a9c:	00004517          	auipc	a0,0x4
ffffffffc0203aa0:	ec450513          	addi	a0,a0,-316 # ffffffffc0207960 <default_pmm_manager+0x738>
ffffffffc0203aa4:	9d7fc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(pgfault_num==4);
ffffffffc0203aa8:	00004697          	auipc	a3,0x4
ffffffffc0203aac:	08068693          	addi	a3,a3,128 # ffffffffc0207b28 <default_pmm_manager+0x900>
ffffffffc0203ab0:	00003617          	auipc	a2,0x3
ffffffffc0203ab4:	0e060613          	addi	a2,a2,224 # ffffffffc0206b90 <commands+0x450>
ffffffffc0203ab8:	0a100593          	li	a1,161
ffffffffc0203abc:	00004517          	auipc	a0,0x4
ffffffffc0203ac0:	ea450513          	addi	a0,a0,-348 # ffffffffc0207960 <default_pmm_manager+0x738>
ffffffffc0203ac4:	9b7fc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(pgfault_num==2);
ffffffffc0203ac8:	00004697          	auipc	a3,0x4
ffffffffc0203acc:	04068693          	addi	a3,a3,64 # ffffffffc0207b08 <default_pmm_manager+0x8e0>
ffffffffc0203ad0:	00003617          	auipc	a2,0x3
ffffffffc0203ad4:	0c060613          	addi	a2,a2,192 # ffffffffc0206b90 <commands+0x450>
ffffffffc0203ad8:	09700593          	li	a1,151
ffffffffc0203adc:	00004517          	auipc	a0,0x4
ffffffffc0203ae0:	e8450513          	addi	a0,a0,-380 # ffffffffc0207960 <default_pmm_manager+0x738>
ffffffffc0203ae4:	997fc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(pgfault_num==2);
ffffffffc0203ae8:	00004697          	auipc	a3,0x4
ffffffffc0203aec:	02068693          	addi	a3,a3,32 # ffffffffc0207b08 <default_pmm_manager+0x8e0>
ffffffffc0203af0:	00003617          	auipc	a2,0x3
ffffffffc0203af4:	0a060613          	addi	a2,a2,160 # ffffffffc0206b90 <commands+0x450>
ffffffffc0203af8:	09900593          	li	a1,153
ffffffffc0203afc:	00004517          	auipc	a0,0x4
ffffffffc0203b00:	e6450513          	addi	a0,a0,-412 # ffffffffc0207960 <default_pmm_manager+0x738>
ffffffffc0203b04:	977fc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(pgfault_num==3);
ffffffffc0203b08:	00004697          	auipc	a3,0x4
ffffffffc0203b0c:	01068693          	addi	a3,a3,16 # ffffffffc0207b18 <default_pmm_manager+0x8f0>
ffffffffc0203b10:	00003617          	auipc	a2,0x3
ffffffffc0203b14:	08060613          	addi	a2,a2,128 # ffffffffc0206b90 <commands+0x450>
ffffffffc0203b18:	09b00593          	li	a1,155
ffffffffc0203b1c:	00004517          	auipc	a0,0x4
ffffffffc0203b20:	e4450513          	addi	a0,a0,-444 # ffffffffc0207960 <default_pmm_manager+0x738>
ffffffffc0203b24:	957fc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(pgfault_num==3);
ffffffffc0203b28:	00004697          	auipc	a3,0x4
ffffffffc0203b2c:	ff068693          	addi	a3,a3,-16 # ffffffffc0207b18 <default_pmm_manager+0x8f0>
ffffffffc0203b30:	00003617          	auipc	a2,0x3
ffffffffc0203b34:	06060613          	addi	a2,a2,96 # ffffffffc0206b90 <commands+0x450>
ffffffffc0203b38:	09d00593          	li	a1,157
ffffffffc0203b3c:	00004517          	auipc	a0,0x4
ffffffffc0203b40:	e2450513          	addi	a0,a0,-476 # ffffffffc0207960 <default_pmm_manager+0x738>
ffffffffc0203b44:	937fc0ef          	jal	ra,ffffffffc020047a <__panic>
     assert(pgfault_num==1);
ffffffffc0203b48:	00004697          	auipc	a3,0x4
ffffffffc0203b4c:	fb068693          	addi	a3,a3,-80 # ffffffffc0207af8 <default_pmm_manager+0x8d0>
ffffffffc0203b50:	00003617          	auipc	a2,0x3
ffffffffc0203b54:	04060613          	addi	a2,a2,64 # ffffffffc0206b90 <commands+0x450>
ffffffffc0203b58:	09300593          	li	a1,147
ffffffffc0203b5c:	00004517          	auipc	a0,0x4
ffffffffc0203b60:	e0450513          	addi	a0,a0,-508 # ffffffffc0207960 <default_pmm_manager+0x738>
ffffffffc0203b64:	917fc0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0203b68 <swap_init_mm>:
     return sm->init_mm(mm);
ffffffffc0203b68:	000af797          	auipc	a5,0xaf
ffffffffc0203b6c:	d287b783          	ld	a5,-728(a5) # ffffffffc02b2890 <sm>
ffffffffc0203b70:	6b9c                	ld	a5,16(a5)
ffffffffc0203b72:	8782                	jr	a5

ffffffffc0203b74 <swap_map_swappable>:
     return sm->map_swappable(mm, addr, page, swap_in);
ffffffffc0203b74:	000af797          	auipc	a5,0xaf
ffffffffc0203b78:	d1c7b783          	ld	a5,-740(a5) # ffffffffc02b2890 <sm>
ffffffffc0203b7c:	739c                	ld	a5,32(a5)
ffffffffc0203b7e:	8782                	jr	a5

ffffffffc0203b80 <swap_out>:
{
ffffffffc0203b80:	711d                	addi	sp,sp,-96
ffffffffc0203b82:	ec86                	sd	ra,88(sp)
ffffffffc0203b84:	e8a2                	sd	s0,80(sp)
ffffffffc0203b86:	e4a6                	sd	s1,72(sp)
ffffffffc0203b88:	e0ca                	sd	s2,64(sp)
ffffffffc0203b8a:	fc4e                	sd	s3,56(sp)
ffffffffc0203b8c:	f852                	sd	s4,48(sp)
ffffffffc0203b8e:	f456                	sd	s5,40(sp)
ffffffffc0203b90:	f05a                	sd	s6,32(sp)
ffffffffc0203b92:	ec5e                	sd	s7,24(sp)
ffffffffc0203b94:	e862                	sd	s8,16(sp)
     for (i = 0; i != n; ++ i)
ffffffffc0203b96:	cde9                	beqz	a1,ffffffffc0203c70 <swap_out+0xf0>
ffffffffc0203b98:	8a2e                	mv	s4,a1
ffffffffc0203b9a:	892a                	mv	s2,a0
ffffffffc0203b9c:	8ab2                	mv	s5,a2
ffffffffc0203b9e:	4401                	li	s0,0
ffffffffc0203ba0:	000af997          	auipc	s3,0xaf
ffffffffc0203ba4:	cf098993          	addi	s3,s3,-784 # ffffffffc02b2890 <sm>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0203ba8:	00004b17          	auipc	s6,0x4
ffffffffc0203bac:	0a0b0b13          	addi	s6,s6,160 # ffffffffc0207c48 <default_pmm_manager+0xa20>
                    cprintf("SWAP: failed to save\n");
ffffffffc0203bb0:	00004b97          	auipc	s7,0x4
ffffffffc0203bb4:	080b8b93          	addi	s7,s7,128 # ffffffffc0207c30 <default_pmm_manager+0xa08>
ffffffffc0203bb8:	a825                	j	ffffffffc0203bf0 <swap_out+0x70>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0203bba:	67a2                	ld	a5,8(sp)
ffffffffc0203bbc:	8626                	mv	a2,s1
ffffffffc0203bbe:	85a2                	mv	a1,s0
ffffffffc0203bc0:	7f94                	ld	a3,56(a5)
ffffffffc0203bc2:	855a                	mv	a0,s6
     for (i = 0; i != n; ++ i)
ffffffffc0203bc4:	2405                	addiw	s0,s0,1
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0203bc6:	82b1                	srli	a3,a3,0xc
ffffffffc0203bc8:	0685                	addi	a3,a3,1
ffffffffc0203bca:	db6fc0ef          	jal	ra,ffffffffc0200180 <cprintf>
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
ffffffffc0203bce:	6522                	ld	a0,8(sp)
                    free_page(page);
ffffffffc0203bd0:	4585                	li	a1,1
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
ffffffffc0203bd2:	7d1c                	ld	a5,56(a0)
ffffffffc0203bd4:	83b1                	srli	a5,a5,0xc
ffffffffc0203bd6:	0785                	addi	a5,a5,1
ffffffffc0203bd8:	07a2                	slli	a5,a5,0x8
ffffffffc0203bda:	00fc3023          	sd	a5,0(s8)
                    free_page(page);
ffffffffc0203bde:	994fe0ef          	jal	ra,ffffffffc0201d72 <free_pages>
          tlb_invalidate(mm->pgdir, v);
ffffffffc0203be2:	01893503          	ld	a0,24(s2)
ffffffffc0203be6:	85a6                	mv	a1,s1
ffffffffc0203be8:	f5eff0ef          	jal	ra,ffffffffc0203346 <tlb_invalidate>
     for (i = 0; i != n; ++ i)
ffffffffc0203bec:	048a0d63          	beq	s4,s0,ffffffffc0203c46 <swap_out+0xc6>
          int r = sm->swap_out_victim(mm, &page, in_tick);
ffffffffc0203bf0:	0009b783          	ld	a5,0(s3)
ffffffffc0203bf4:	8656                	mv	a2,s5
ffffffffc0203bf6:	002c                	addi	a1,sp,8
ffffffffc0203bf8:	7b9c                	ld	a5,48(a5)
ffffffffc0203bfa:	854a                	mv	a0,s2
ffffffffc0203bfc:	9782                	jalr	a5
          if (r != 0) {
ffffffffc0203bfe:	e12d                	bnez	a0,ffffffffc0203c60 <swap_out+0xe0>
          v=page->pra_vaddr; 
ffffffffc0203c00:	67a2                	ld	a5,8(sp)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0203c02:	01893503          	ld	a0,24(s2)
ffffffffc0203c06:	4601                	li	a2,0
          v=page->pra_vaddr; 
ffffffffc0203c08:	7f84                	ld	s1,56(a5)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0203c0a:	85a6                	mv	a1,s1
ffffffffc0203c0c:	9e0fe0ef          	jal	ra,ffffffffc0201dec <get_pte>
          assert((*ptep & PTE_V) != 0);
ffffffffc0203c10:	611c                	ld	a5,0(a0)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0203c12:	8c2a                	mv	s8,a0
          assert((*ptep & PTE_V) != 0);
ffffffffc0203c14:	8b85                	andi	a5,a5,1
ffffffffc0203c16:	cfb9                	beqz	a5,ffffffffc0203c74 <swap_out+0xf4>
          if (swapfs_write( (page->pra_vaddr/PGSIZE+1)<<8, page) != 0) {
ffffffffc0203c18:	65a2                	ld	a1,8(sp)
ffffffffc0203c1a:	7d9c                	ld	a5,56(a1)
ffffffffc0203c1c:	83b1                	srli	a5,a5,0xc
ffffffffc0203c1e:	0785                	addi	a5,a5,1
ffffffffc0203c20:	00879513          	slli	a0,a5,0x8
ffffffffc0203c24:	713000ef          	jal	ra,ffffffffc0204b36 <swapfs_write>
ffffffffc0203c28:	d949                	beqz	a0,ffffffffc0203bba <swap_out+0x3a>
                    cprintf("SWAP: failed to save\n");
ffffffffc0203c2a:	855e                	mv	a0,s7
ffffffffc0203c2c:	d54fc0ef          	jal	ra,ffffffffc0200180 <cprintf>
                    sm->map_swappable(mm, v, page, 0);
ffffffffc0203c30:	0009b783          	ld	a5,0(s3)
ffffffffc0203c34:	6622                	ld	a2,8(sp)
ffffffffc0203c36:	4681                	li	a3,0
ffffffffc0203c38:	739c                	ld	a5,32(a5)
ffffffffc0203c3a:	85a6                	mv	a1,s1
ffffffffc0203c3c:	854a                	mv	a0,s2
     for (i = 0; i != n; ++ i)
ffffffffc0203c3e:	2405                	addiw	s0,s0,1
                    sm->map_swappable(mm, v, page, 0);
ffffffffc0203c40:	9782                	jalr	a5
     for (i = 0; i != n; ++ i)
ffffffffc0203c42:	fa8a17e3          	bne	s4,s0,ffffffffc0203bf0 <swap_out+0x70>
}
ffffffffc0203c46:	60e6                	ld	ra,88(sp)
ffffffffc0203c48:	8522                	mv	a0,s0
ffffffffc0203c4a:	6446                	ld	s0,80(sp)
ffffffffc0203c4c:	64a6                	ld	s1,72(sp)
ffffffffc0203c4e:	6906                	ld	s2,64(sp)
ffffffffc0203c50:	79e2                	ld	s3,56(sp)
ffffffffc0203c52:	7a42                	ld	s4,48(sp)
ffffffffc0203c54:	7aa2                	ld	s5,40(sp)
ffffffffc0203c56:	7b02                	ld	s6,32(sp)
ffffffffc0203c58:	6be2                	ld	s7,24(sp)
ffffffffc0203c5a:	6c42                	ld	s8,16(sp)
ffffffffc0203c5c:	6125                	addi	sp,sp,96
ffffffffc0203c5e:	8082                	ret
                    cprintf("i %d, swap_out: call swap_out_victim failed\n",i);
ffffffffc0203c60:	85a2                	mv	a1,s0
ffffffffc0203c62:	00004517          	auipc	a0,0x4
ffffffffc0203c66:	f8650513          	addi	a0,a0,-122 # ffffffffc0207be8 <default_pmm_manager+0x9c0>
ffffffffc0203c6a:	d16fc0ef          	jal	ra,ffffffffc0200180 <cprintf>
                  break;
ffffffffc0203c6e:	bfe1                	j	ffffffffc0203c46 <swap_out+0xc6>
     for (i = 0; i != n; ++ i)
ffffffffc0203c70:	4401                	li	s0,0
ffffffffc0203c72:	bfd1                	j	ffffffffc0203c46 <swap_out+0xc6>
          assert((*ptep & PTE_V) != 0);
ffffffffc0203c74:	00004697          	auipc	a3,0x4
ffffffffc0203c78:	fa468693          	addi	a3,a3,-92 # ffffffffc0207c18 <default_pmm_manager+0x9f0>
ffffffffc0203c7c:	00003617          	auipc	a2,0x3
ffffffffc0203c80:	f1460613          	addi	a2,a2,-236 # ffffffffc0206b90 <commands+0x450>
ffffffffc0203c84:	06800593          	li	a1,104
ffffffffc0203c88:	00004517          	auipc	a0,0x4
ffffffffc0203c8c:	cd850513          	addi	a0,a0,-808 # ffffffffc0207960 <default_pmm_manager+0x738>
ffffffffc0203c90:	feafc0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0203c94 <swap_in>:
{
ffffffffc0203c94:	7179                	addi	sp,sp,-48
ffffffffc0203c96:	e84a                	sd	s2,16(sp)
ffffffffc0203c98:	892a                	mv	s2,a0
     struct Page *result = alloc_page();
ffffffffc0203c9a:	4505                	li	a0,1
{
ffffffffc0203c9c:	ec26                	sd	s1,24(sp)
ffffffffc0203c9e:	e44e                	sd	s3,8(sp)
ffffffffc0203ca0:	f406                	sd	ra,40(sp)
ffffffffc0203ca2:	f022                	sd	s0,32(sp)
ffffffffc0203ca4:	84ae                	mv	s1,a1
ffffffffc0203ca6:	89b2                	mv	s3,a2
     struct Page *result = alloc_page();
ffffffffc0203ca8:	838fe0ef          	jal	ra,ffffffffc0201ce0 <alloc_pages>
     assert(result!=NULL);
ffffffffc0203cac:	c129                	beqz	a0,ffffffffc0203cee <swap_in+0x5a>
     pte_t *ptep = get_pte(mm->pgdir, addr, 0);
ffffffffc0203cae:	842a                	mv	s0,a0
ffffffffc0203cb0:	01893503          	ld	a0,24(s2)
ffffffffc0203cb4:	4601                	li	a2,0
ffffffffc0203cb6:	85a6                	mv	a1,s1
ffffffffc0203cb8:	934fe0ef          	jal	ra,ffffffffc0201dec <get_pte>
ffffffffc0203cbc:	892a                	mv	s2,a0
     if ((r = swapfs_read((*ptep), result)) != 0)
ffffffffc0203cbe:	6108                	ld	a0,0(a0)
ffffffffc0203cc0:	85a2                	mv	a1,s0
ffffffffc0203cc2:	5e7000ef          	jal	ra,ffffffffc0204aa8 <swapfs_read>
     cprintf("swap_in: load disk swap entry %d with swap_page in vadr 0x%x\n", (*ptep)>>8, addr);
ffffffffc0203cc6:	00093583          	ld	a1,0(s2)
ffffffffc0203cca:	8626                	mv	a2,s1
ffffffffc0203ccc:	00004517          	auipc	a0,0x4
ffffffffc0203cd0:	fcc50513          	addi	a0,a0,-52 # ffffffffc0207c98 <default_pmm_manager+0xa70>
ffffffffc0203cd4:	81a1                	srli	a1,a1,0x8
ffffffffc0203cd6:	caafc0ef          	jal	ra,ffffffffc0200180 <cprintf>
}
ffffffffc0203cda:	70a2                	ld	ra,40(sp)
     *ptr_result=result;
ffffffffc0203cdc:	0089b023          	sd	s0,0(s3)
}
ffffffffc0203ce0:	7402                	ld	s0,32(sp)
ffffffffc0203ce2:	64e2                	ld	s1,24(sp)
ffffffffc0203ce4:	6942                	ld	s2,16(sp)
ffffffffc0203ce6:	69a2                	ld	s3,8(sp)
ffffffffc0203ce8:	4501                	li	a0,0
ffffffffc0203cea:	6145                	addi	sp,sp,48
ffffffffc0203cec:	8082                	ret
     assert(result!=NULL);
ffffffffc0203cee:	00004697          	auipc	a3,0x4
ffffffffc0203cf2:	f9a68693          	addi	a3,a3,-102 # ffffffffc0207c88 <default_pmm_manager+0xa60>
ffffffffc0203cf6:	00003617          	auipc	a2,0x3
ffffffffc0203cfa:	e9a60613          	addi	a2,a2,-358 # ffffffffc0206b90 <commands+0x450>
ffffffffc0203cfe:	07e00593          	li	a1,126
ffffffffc0203d02:	00004517          	auipc	a0,0x4
ffffffffc0203d06:	c5e50513          	addi	a0,a0,-930 # ffffffffc0207960 <default_pmm_manager+0x738>
ffffffffc0203d0a:	f70fc0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0203d0e <_fifo_init_mm>:
    elm->prev = elm->next = elm;
ffffffffc0203d0e:	000ab797          	auipc	a5,0xab
ffffffffc0203d12:	b0a78793          	addi	a5,a5,-1270 # ffffffffc02ae818 <pra_list_head>
 */
static int
_fifo_init_mm(struct mm_struct *mm)
{     
     list_init(&pra_list_head);
     mm->sm_priv = &pra_list_head;
ffffffffc0203d16:	f51c                	sd	a5,40(a0)
ffffffffc0203d18:	e79c                	sd	a5,8(a5)
ffffffffc0203d1a:	e39c                	sd	a5,0(a5)
     //cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
     return 0;
}
ffffffffc0203d1c:	4501                	li	a0,0
ffffffffc0203d1e:	8082                	ret

ffffffffc0203d20 <_fifo_init>:

static int
_fifo_init(void)
{
    return 0;
}
ffffffffc0203d20:	4501                	li	a0,0
ffffffffc0203d22:	8082                	ret

ffffffffc0203d24 <_fifo_set_unswappable>:

static int
_fifo_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
    return 0;
}
ffffffffc0203d24:	4501                	li	a0,0
ffffffffc0203d26:	8082                	ret

ffffffffc0203d28 <_fifo_tick_event>:

static int
_fifo_tick_event(struct mm_struct *mm)
{ return 0; }
ffffffffc0203d28:	4501                	li	a0,0
ffffffffc0203d2a:	8082                	ret

ffffffffc0203d2c <_fifo_check_swap>:
_fifo_check_swap(void) {
ffffffffc0203d2c:	7159                	addi	sp,sp,-112
ffffffffc0203d2e:	f85a                	sd	s6,48(sp)
ffffffffc0203d30:	f45e                	sd	s7,40(sp)
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc0203d32:	00004517          	auipc	a0,0x4
ffffffffc0203d36:	fa650513          	addi	a0,a0,-90 # ffffffffc0207cd8 <default_pmm_manager+0xab0>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0203d3a:	6b0d                	lui	s6,0x3
ffffffffc0203d3c:	4bb1                	li	s7,12
_fifo_check_swap(void) {
ffffffffc0203d3e:	e8ca                	sd	s2,80(sp)
ffffffffc0203d40:	f486                	sd	ra,104(sp)
ffffffffc0203d42:	f0a2                	sd	s0,96(sp)
ffffffffc0203d44:	eca6                	sd	s1,88(sp)
ffffffffc0203d46:	e4ce                	sd	s3,72(sp)
ffffffffc0203d48:	e0d2                	sd	s4,64(sp)
ffffffffc0203d4a:	fc56                	sd	s5,56(sp)
ffffffffc0203d4c:	f062                	sd	s8,32(sp)
ffffffffc0203d4e:	ec66                	sd	s9,24(sp)
ffffffffc0203d50:	e86a                	sd	s10,16(sp)
ffffffffc0203d52:	e46e                	sd	s11,8(sp)
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc0203d54:	c2cfc0ef          	jal	ra,ffffffffc0200180 <cprintf>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0203d58:	017b0023          	sb	s7,0(s6) # 3000 <_binary_obj___user_faultread_out_size-0x6bb8>
    assert(pgfault_num==4);
ffffffffc0203d5c:	000af917          	auipc	s2,0xaf
ffffffffc0203d60:	b4c92903          	lw	s2,-1204(s2) # ffffffffc02b28a8 <pgfault_num>
ffffffffc0203d64:	4791                	li	a5,4
ffffffffc0203d66:	10f91c63          	bne	s2,a5,ffffffffc0203e7e <_fifo_check_swap+0x152>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0203d6a:	00004517          	auipc	a0,0x4
ffffffffc0203d6e:	fae50513          	addi	a0,a0,-82 # ffffffffc0207d18 <default_pmm_manager+0xaf0>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0203d72:	6985                	lui	s3,0x1
ffffffffc0203d74:	4a29                	li	s4,10
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0203d76:	c0afc0ef          	jal	ra,ffffffffc0200180 <cprintf>
ffffffffc0203d7a:	000af417          	auipc	s0,0xaf
ffffffffc0203d7e:	b2e40413          	addi	s0,s0,-1234 # ffffffffc02b28a8 <pgfault_num>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0203d82:	01498023          	sb	s4,0(s3) # 1000 <_binary_obj___user_faultread_out_size-0x8bb8>
    assert(pgfault_num==4);
ffffffffc0203d86:	4004                	lw	s1,0(s0)
ffffffffc0203d88:	2481                	sext.w	s1,s1
ffffffffc0203d8a:	19249a63          	bne	s1,s2,ffffffffc0203f1e <_fifo_check_swap+0x1f2>
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc0203d8e:	00004517          	auipc	a0,0x4
ffffffffc0203d92:	fb250513          	addi	a0,a0,-78 # ffffffffc0207d40 <default_pmm_manager+0xb18>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc0203d96:	6c11                	lui	s8,0x4
ffffffffc0203d98:	4cb5                	li	s9,13
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc0203d9a:	be6fc0ef          	jal	ra,ffffffffc0200180 <cprintf>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc0203d9e:	019c0023          	sb	s9,0(s8) # 4000 <_binary_obj___user_faultread_out_size-0x5bb8>
    assert(pgfault_num==4);
ffffffffc0203da2:	00042903          	lw	s2,0(s0)
ffffffffc0203da6:	2901                	sext.w	s2,s2
ffffffffc0203da8:	14991b63          	bne	s2,s1,ffffffffc0203efe <_fifo_check_swap+0x1d2>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0203dac:	00004517          	auipc	a0,0x4
ffffffffc0203db0:	fbc50513          	addi	a0,a0,-68 # ffffffffc0207d68 <default_pmm_manager+0xb40>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0203db4:	6a89                	lui	s5,0x2
ffffffffc0203db6:	4d2d                	li	s10,11
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0203db8:	bc8fc0ef          	jal	ra,ffffffffc0200180 <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0203dbc:	01aa8023          	sb	s10,0(s5) # 2000 <_binary_obj___user_faultread_out_size-0x7bb8>
    assert(pgfault_num==4);
ffffffffc0203dc0:	401c                	lw	a5,0(s0)
ffffffffc0203dc2:	2781                	sext.w	a5,a5
ffffffffc0203dc4:	11279d63          	bne	a5,s2,ffffffffc0203ede <_fifo_check_swap+0x1b2>
    cprintf("write Virt Page e in fifo_check_swap\n");
ffffffffc0203dc8:	00004517          	auipc	a0,0x4
ffffffffc0203dcc:	fc850513          	addi	a0,a0,-56 # ffffffffc0207d90 <default_pmm_manager+0xb68>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc0203dd0:	6915                	lui	s2,0x5
ffffffffc0203dd2:	4db9                	li	s11,14
    cprintf("write Virt Page e in fifo_check_swap\n");
ffffffffc0203dd4:	bacfc0ef          	jal	ra,ffffffffc0200180 <cprintf>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc0203dd8:	01b90023          	sb	s11,0(s2) # 5000 <_binary_obj___user_faultread_out_size-0x4bb8>
    assert(pgfault_num==5);
ffffffffc0203ddc:	4004                	lw	s1,0(s0)
ffffffffc0203dde:	4795                	li	a5,5
ffffffffc0203de0:	2481                	sext.w	s1,s1
ffffffffc0203de2:	0cf49e63          	bne	s1,a5,ffffffffc0203ebe <_fifo_check_swap+0x192>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0203de6:	00004517          	auipc	a0,0x4
ffffffffc0203dea:	f8250513          	addi	a0,a0,-126 # ffffffffc0207d68 <default_pmm_manager+0xb40>
ffffffffc0203dee:	b92fc0ef          	jal	ra,ffffffffc0200180 <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0203df2:	01aa8023          	sb	s10,0(s5)
    assert(pgfault_num==5);
ffffffffc0203df6:	401c                	lw	a5,0(s0)
ffffffffc0203df8:	2781                	sext.w	a5,a5
ffffffffc0203dfa:	0a979263          	bne	a5,s1,ffffffffc0203e9e <_fifo_check_swap+0x172>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0203dfe:	00004517          	auipc	a0,0x4
ffffffffc0203e02:	f1a50513          	addi	a0,a0,-230 # ffffffffc0207d18 <default_pmm_manager+0xaf0>
ffffffffc0203e06:	b7afc0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0203e0a:	00004517          	auipc	a0,0x4
ffffffffc0203e0e:	f5e50513          	addi	a0,a0,-162 # ffffffffc0207d68 <default_pmm_manager+0xb40>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0203e12:	01498023          	sb	s4,0(s3)
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0203e16:	b6afc0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc0203e1a:	00004517          	auipc	a0,0x4
ffffffffc0203e1e:	ebe50513          	addi	a0,a0,-322 # ffffffffc0207cd8 <default_pmm_manager+0xab0>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0203e22:	01aa8023          	sb	s10,0(s5)
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc0203e26:	b5afc0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc0203e2a:	00004517          	auipc	a0,0x4
ffffffffc0203e2e:	f1650513          	addi	a0,a0,-234 # ffffffffc0207d40 <default_pmm_manager+0xb18>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0203e32:	017b0023          	sb	s7,0(s6)
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc0203e36:	b4afc0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("write Virt Page e in fifo_check_swap\n");
ffffffffc0203e3a:	00004517          	auipc	a0,0x4
ffffffffc0203e3e:	f5650513          	addi	a0,a0,-170 # ffffffffc0207d90 <default_pmm_manager+0xb68>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc0203e42:	019c0023          	sb	s9,0(s8)
    cprintf("write Virt Page e in fifo_check_swap\n");
ffffffffc0203e46:	b3afc0ef          	jal	ra,ffffffffc0200180 <cprintf>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0203e4a:	00004517          	auipc	a0,0x4
ffffffffc0203e4e:	ece50513          	addi	a0,a0,-306 # ffffffffc0207d18 <default_pmm_manager+0xaf0>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc0203e52:	01b90023          	sb	s11,0(s2)
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0203e56:	b2afc0ef          	jal	ra,ffffffffc0200180 <cprintf>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0203e5a:	01498023          	sb	s4,0(s3)
}
ffffffffc0203e5e:	70a6                	ld	ra,104(sp)
ffffffffc0203e60:	7406                	ld	s0,96(sp)
ffffffffc0203e62:	64e6                	ld	s1,88(sp)
ffffffffc0203e64:	6946                	ld	s2,80(sp)
ffffffffc0203e66:	69a6                	ld	s3,72(sp)
ffffffffc0203e68:	6a06                	ld	s4,64(sp)
ffffffffc0203e6a:	7ae2                	ld	s5,56(sp)
ffffffffc0203e6c:	7b42                	ld	s6,48(sp)
ffffffffc0203e6e:	7ba2                	ld	s7,40(sp)
ffffffffc0203e70:	7c02                	ld	s8,32(sp)
ffffffffc0203e72:	6ce2                	ld	s9,24(sp)
ffffffffc0203e74:	6d42                	ld	s10,16(sp)
ffffffffc0203e76:	6da2                	ld	s11,8(sp)
ffffffffc0203e78:	4501                	li	a0,0
ffffffffc0203e7a:	6165                	addi	sp,sp,112
ffffffffc0203e7c:	8082                	ret
    assert(pgfault_num==4);
ffffffffc0203e7e:	00004697          	auipc	a3,0x4
ffffffffc0203e82:	caa68693          	addi	a3,a3,-854 # ffffffffc0207b28 <default_pmm_manager+0x900>
ffffffffc0203e86:	00003617          	auipc	a2,0x3
ffffffffc0203e8a:	d0a60613          	addi	a2,a2,-758 # ffffffffc0206b90 <commands+0x450>
ffffffffc0203e8e:	05500593          	li	a1,85
ffffffffc0203e92:	00004517          	auipc	a0,0x4
ffffffffc0203e96:	e6e50513          	addi	a0,a0,-402 # ffffffffc0207d00 <default_pmm_manager+0xad8>
ffffffffc0203e9a:	de0fc0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(pgfault_num==5);
ffffffffc0203e9e:	00004697          	auipc	a3,0x4
ffffffffc0203ea2:	f1a68693          	addi	a3,a3,-230 # ffffffffc0207db8 <default_pmm_manager+0xb90>
ffffffffc0203ea6:	00003617          	auipc	a2,0x3
ffffffffc0203eaa:	cea60613          	addi	a2,a2,-790 # ffffffffc0206b90 <commands+0x450>
ffffffffc0203eae:	06400593          	li	a1,100
ffffffffc0203eb2:	00004517          	auipc	a0,0x4
ffffffffc0203eb6:	e4e50513          	addi	a0,a0,-434 # ffffffffc0207d00 <default_pmm_manager+0xad8>
ffffffffc0203eba:	dc0fc0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(pgfault_num==5);
ffffffffc0203ebe:	00004697          	auipc	a3,0x4
ffffffffc0203ec2:	efa68693          	addi	a3,a3,-262 # ffffffffc0207db8 <default_pmm_manager+0xb90>
ffffffffc0203ec6:	00003617          	auipc	a2,0x3
ffffffffc0203eca:	cca60613          	addi	a2,a2,-822 # ffffffffc0206b90 <commands+0x450>
ffffffffc0203ece:	06100593          	li	a1,97
ffffffffc0203ed2:	00004517          	auipc	a0,0x4
ffffffffc0203ed6:	e2e50513          	addi	a0,a0,-466 # ffffffffc0207d00 <default_pmm_manager+0xad8>
ffffffffc0203eda:	da0fc0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(pgfault_num==4);
ffffffffc0203ede:	00004697          	auipc	a3,0x4
ffffffffc0203ee2:	c4a68693          	addi	a3,a3,-950 # ffffffffc0207b28 <default_pmm_manager+0x900>
ffffffffc0203ee6:	00003617          	auipc	a2,0x3
ffffffffc0203eea:	caa60613          	addi	a2,a2,-854 # ffffffffc0206b90 <commands+0x450>
ffffffffc0203eee:	05e00593          	li	a1,94
ffffffffc0203ef2:	00004517          	auipc	a0,0x4
ffffffffc0203ef6:	e0e50513          	addi	a0,a0,-498 # ffffffffc0207d00 <default_pmm_manager+0xad8>
ffffffffc0203efa:	d80fc0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(pgfault_num==4);
ffffffffc0203efe:	00004697          	auipc	a3,0x4
ffffffffc0203f02:	c2a68693          	addi	a3,a3,-982 # ffffffffc0207b28 <default_pmm_manager+0x900>
ffffffffc0203f06:	00003617          	auipc	a2,0x3
ffffffffc0203f0a:	c8a60613          	addi	a2,a2,-886 # ffffffffc0206b90 <commands+0x450>
ffffffffc0203f0e:	05b00593          	li	a1,91
ffffffffc0203f12:	00004517          	auipc	a0,0x4
ffffffffc0203f16:	dee50513          	addi	a0,a0,-530 # ffffffffc0207d00 <default_pmm_manager+0xad8>
ffffffffc0203f1a:	d60fc0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(pgfault_num==4);
ffffffffc0203f1e:	00004697          	auipc	a3,0x4
ffffffffc0203f22:	c0a68693          	addi	a3,a3,-1014 # ffffffffc0207b28 <default_pmm_manager+0x900>
ffffffffc0203f26:	00003617          	auipc	a2,0x3
ffffffffc0203f2a:	c6a60613          	addi	a2,a2,-918 # ffffffffc0206b90 <commands+0x450>
ffffffffc0203f2e:	05800593          	li	a1,88
ffffffffc0203f32:	00004517          	auipc	a0,0x4
ffffffffc0203f36:	dce50513          	addi	a0,a0,-562 # ffffffffc0207d00 <default_pmm_manager+0xad8>
ffffffffc0203f3a:	d40fc0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0203f3e <_fifo_swap_out_victim>:
     list_entry_t *head=(list_entry_t*) mm->sm_priv;
ffffffffc0203f3e:	7518                	ld	a4,40(a0)
{
ffffffffc0203f40:	1141                	addi	sp,sp,-16
ffffffffc0203f42:	e406                	sd	ra,8(sp)
         assert(head != NULL);
ffffffffc0203f44:	c731                	beqz	a4,ffffffffc0203f90 <_fifo_swap_out_victim+0x52>
     assert(in_tick==0);
ffffffffc0203f46:	e60d                	bnez	a2,ffffffffc0203f70 <_fifo_swap_out_victim+0x32>
    return listelm->prev;
ffffffffc0203f48:	631c                	ld	a5,0(a4)
    if (entry != head) {
ffffffffc0203f4a:	00f70d63          	beq	a4,a5,ffffffffc0203f64 <_fifo_swap_out_victim+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc0203f4e:	6394                	ld	a3,0(a5)
ffffffffc0203f50:	6798                	ld	a4,8(a5)
}
ffffffffc0203f52:	60a2                	ld	ra,8(sp)
        *ptr_page = le2page(entry, pra_page_link);
ffffffffc0203f54:	fd878793          	addi	a5,a5,-40
    prev->next = next;
ffffffffc0203f58:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc0203f5a:	e314                	sd	a3,0(a4)
ffffffffc0203f5c:	e19c                	sd	a5,0(a1)
}
ffffffffc0203f5e:	4501                	li	a0,0
ffffffffc0203f60:	0141                	addi	sp,sp,16
ffffffffc0203f62:	8082                	ret
ffffffffc0203f64:	60a2                	ld	ra,8(sp)
        *ptr_page = NULL;
ffffffffc0203f66:	0005b023          	sd	zero,0(a1) # 1000 <_binary_obj___user_faultread_out_size-0x8bb8>
}
ffffffffc0203f6a:	4501                	li	a0,0
ffffffffc0203f6c:	0141                	addi	sp,sp,16
ffffffffc0203f6e:	8082                	ret
     assert(in_tick==0);
ffffffffc0203f70:	00004697          	auipc	a3,0x4
ffffffffc0203f74:	e6868693          	addi	a3,a3,-408 # ffffffffc0207dd8 <default_pmm_manager+0xbb0>
ffffffffc0203f78:	00003617          	auipc	a2,0x3
ffffffffc0203f7c:	c1860613          	addi	a2,a2,-1000 # ffffffffc0206b90 <commands+0x450>
ffffffffc0203f80:	04200593          	li	a1,66
ffffffffc0203f84:	00004517          	auipc	a0,0x4
ffffffffc0203f88:	d7c50513          	addi	a0,a0,-644 # ffffffffc0207d00 <default_pmm_manager+0xad8>
ffffffffc0203f8c:	ceefc0ef          	jal	ra,ffffffffc020047a <__panic>
         assert(head != NULL);
ffffffffc0203f90:	00004697          	auipc	a3,0x4
ffffffffc0203f94:	e3868693          	addi	a3,a3,-456 # ffffffffc0207dc8 <default_pmm_manager+0xba0>
ffffffffc0203f98:	00003617          	auipc	a2,0x3
ffffffffc0203f9c:	bf860613          	addi	a2,a2,-1032 # ffffffffc0206b90 <commands+0x450>
ffffffffc0203fa0:	04100593          	li	a1,65
ffffffffc0203fa4:	00004517          	auipc	a0,0x4
ffffffffc0203fa8:	d5c50513          	addi	a0,a0,-676 # ffffffffc0207d00 <default_pmm_manager+0xad8>
ffffffffc0203fac:	ccefc0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0203fb0 <_fifo_map_swappable>:
    list_entry_t *head=(list_entry_t*) mm->sm_priv;
ffffffffc0203fb0:	751c                	ld	a5,40(a0)
    assert(entry != NULL && head != NULL);
ffffffffc0203fb2:	cb91                	beqz	a5,ffffffffc0203fc6 <_fifo_map_swappable+0x16>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0203fb4:	6394                	ld	a3,0(a5)
ffffffffc0203fb6:	02860713          	addi	a4,a2,40
    prev->next = next->prev = elm;
ffffffffc0203fba:	e398                	sd	a4,0(a5)
ffffffffc0203fbc:	e698                	sd	a4,8(a3)
}
ffffffffc0203fbe:	4501                	li	a0,0
    elm->next = next;
ffffffffc0203fc0:	fa1c                	sd	a5,48(a2)
    elm->prev = prev;
ffffffffc0203fc2:	f614                	sd	a3,40(a2)
ffffffffc0203fc4:	8082                	ret
{
ffffffffc0203fc6:	1141                	addi	sp,sp,-16
    assert(entry != NULL && head != NULL);
ffffffffc0203fc8:	00004697          	auipc	a3,0x4
ffffffffc0203fcc:	e2068693          	addi	a3,a3,-480 # ffffffffc0207de8 <default_pmm_manager+0xbc0>
ffffffffc0203fd0:	00003617          	auipc	a2,0x3
ffffffffc0203fd4:	bc060613          	addi	a2,a2,-1088 # ffffffffc0206b90 <commands+0x450>
ffffffffc0203fd8:	03200593          	li	a1,50
ffffffffc0203fdc:	00004517          	auipc	a0,0x4
ffffffffc0203fe0:	d2450513          	addi	a0,a0,-732 # ffffffffc0207d00 <default_pmm_manager+0xad8>
{
ffffffffc0203fe4:	e406                	sd	ra,8(sp)
    assert(entry != NULL && head != NULL);
ffffffffc0203fe6:	c94fc0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0203fea <check_vma_overlap.part.0>:
}


// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc0203fea:	1141                	addi	sp,sp,-16
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0203fec:	00004697          	auipc	a3,0x4
ffffffffc0203ff0:	e3468693          	addi	a3,a3,-460 # ffffffffc0207e20 <default_pmm_manager+0xbf8>
ffffffffc0203ff4:	00003617          	auipc	a2,0x3
ffffffffc0203ff8:	b9c60613          	addi	a2,a2,-1124 # ffffffffc0206b90 <commands+0x450>
ffffffffc0203ffc:	06d00593          	li	a1,109
ffffffffc0204000:	00004517          	auipc	a0,0x4
ffffffffc0204004:	e4050513          	addi	a0,a0,-448 # ffffffffc0207e40 <default_pmm_manager+0xc18>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc0204008:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc020400a:	c70fc0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc020400e <mm_create>:
mm_create(void) {
ffffffffc020400e:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0204010:	04000513          	li	a0,64
mm_create(void) {
ffffffffc0204014:	e022                	sd	s0,0(sp)
ffffffffc0204016:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0204018:	aebfd0ef          	jal	ra,ffffffffc0201b02 <kmalloc>
ffffffffc020401c:	842a                	mv	s0,a0
    if (mm != NULL) {
ffffffffc020401e:	c505                	beqz	a0,ffffffffc0204046 <mm_create+0x38>
    elm->prev = elm->next = elm;
ffffffffc0204020:	e408                	sd	a0,8(s0)
ffffffffc0204022:	e008                	sd	a0,0(s0)
        mm->mmap_cache = NULL;
ffffffffc0204024:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0204028:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc020402c:	02052023          	sw	zero,32(a0)
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0204030:	000af797          	auipc	a5,0xaf
ffffffffc0204034:	8687a783          	lw	a5,-1944(a5) # ffffffffc02b2898 <swap_init_ok>
ffffffffc0204038:	ef81                	bnez	a5,ffffffffc0204050 <mm_create+0x42>
        else mm->sm_priv = NULL;
ffffffffc020403a:	02053423          	sd	zero,40(a0)
    return mm->mm_count;
}

static inline void
set_mm_count(struct mm_struct *mm, int val) {
    mm->mm_count = val;
ffffffffc020403e:	02042823          	sw	zero,48(s0)

typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock) {
    *lock = 0;
ffffffffc0204042:	02043c23          	sd	zero,56(s0)
}
ffffffffc0204046:	60a2                	ld	ra,8(sp)
ffffffffc0204048:	8522                	mv	a0,s0
ffffffffc020404a:	6402                	ld	s0,0(sp)
ffffffffc020404c:	0141                	addi	sp,sp,16
ffffffffc020404e:	8082                	ret
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0204050:	b19ff0ef          	jal	ra,ffffffffc0203b68 <swap_init_mm>
ffffffffc0204054:	b7ed                	j	ffffffffc020403e <mm_create+0x30>

ffffffffc0204056 <vma_create>:
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint32_t vm_flags) {
ffffffffc0204056:	1101                	addi	sp,sp,-32
ffffffffc0204058:	e04a                	sd	s2,0(sp)
ffffffffc020405a:	892a                	mv	s2,a0
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020405c:	03000513          	li	a0,48
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint32_t vm_flags) {
ffffffffc0204060:	e822                	sd	s0,16(sp)
ffffffffc0204062:	e426                	sd	s1,8(sp)
ffffffffc0204064:	ec06                	sd	ra,24(sp)
ffffffffc0204066:	84ae                	mv	s1,a1
ffffffffc0204068:	8432                	mv	s0,a2
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020406a:	a99fd0ef          	jal	ra,ffffffffc0201b02 <kmalloc>
    if (vma != NULL) {
ffffffffc020406e:	c509                	beqz	a0,ffffffffc0204078 <vma_create+0x22>
        vma->vm_start = vm_start;
ffffffffc0204070:	01253423          	sd	s2,8(a0)
        vma->vm_end = vm_end;
ffffffffc0204074:	e904                	sd	s1,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0204076:	cd00                	sw	s0,24(a0)
}
ffffffffc0204078:	60e2                	ld	ra,24(sp)
ffffffffc020407a:	6442                	ld	s0,16(sp)
ffffffffc020407c:	64a2                	ld	s1,8(sp)
ffffffffc020407e:	6902                	ld	s2,0(sp)
ffffffffc0204080:	6105                	addi	sp,sp,32
ffffffffc0204082:	8082                	ret

ffffffffc0204084 <find_vma>:
find_vma(struct mm_struct *mm, uintptr_t addr) {
ffffffffc0204084:	86aa                	mv	a3,a0
    if (mm != NULL) {
ffffffffc0204086:	c505                	beqz	a0,ffffffffc02040ae <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc0204088:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
ffffffffc020408a:	c501                	beqz	a0,ffffffffc0204092 <find_vma+0xe>
ffffffffc020408c:	651c                	ld	a5,8(a0)
ffffffffc020408e:	02f5f263          	bgeu	a1,a5,ffffffffc02040b2 <find_vma+0x2e>
    return listelm->next;
ffffffffc0204092:	669c                	ld	a5,8(a3)
                while ((le = list_next(le)) != list) {
ffffffffc0204094:	00f68d63          	beq	a3,a5,ffffffffc02040ae <find_vma+0x2a>
                    if (vma->vm_start<=addr && addr < vma->vm_end) {
ffffffffc0204098:	fe87b703          	ld	a4,-24(a5)
ffffffffc020409c:	00e5e663          	bltu	a1,a4,ffffffffc02040a8 <find_vma+0x24>
ffffffffc02040a0:	ff07b703          	ld	a4,-16(a5)
ffffffffc02040a4:	00e5ec63          	bltu	a1,a4,ffffffffc02040bc <find_vma+0x38>
ffffffffc02040a8:	679c                	ld	a5,8(a5)
                while ((le = list_next(le)) != list) {
ffffffffc02040aa:	fef697e3          	bne	a3,a5,ffffffffc0204098 <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc02040ae:	4501                	li	a0,0
}
ffffffffc02040b0:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
ffffffffc02040b2:	691c                	ld	a5,16(a0)
ffffffffc02040b4:	fcf5ffe3          	bgeu	a1,a5,ffffffffc0204092 <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc02040b8:	ea88                	sd	a0,16(a3)
ffffffffc02040ba:	8082                	ret
                    vma = le2vma(le, list_link);
ffffffffc02040bc:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc02040c0:	ea88                	sd	a0,16(a3)
ffffffffc02040c2:	8082                	ret

ffffffffc02040c4 <insert_vma_struct>:


// insert_vma_struct -insert vma in mm's list link
void
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
    assert(vma->vm_start < vma->vm_end);
ffffffffc02040c4:	6590                	ld	a2,8(a1)
ffffffffc02040c6:	0105b803          	ld	a6,16(a1)
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
ffffffffc02040ca:	1141                	addi	sp,sp,-16
ffffffffc02040cc:	e406                	sd	ra,8(sp)
ffffffffc02040ce:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc02040d0:	01066763          	bltu	a2,a6,ffffffffc02040de <insert_vma_struct+0x1a>
ffffffffc02040d4:	a085                	j	ffffffffc0204134 <insert_vma_struct+0x70>
    list_entry_t *le_prev = list, *le_next;

        list_entry_t *le = list;
        while ((le = list_next(le)) != list) {
            struct vma_struct *mmap_prev = le2vma(le, list_link);
            if (mmap_prev->vm_start > vma->vm_start) {
ffffffffc02040d6:	fe87b703          	ld	a4,-24(a5)
ffffffffc02040da:	04e66863          	bltu	a2,a4,ffffffffc020412a <insert_vma_struct+0x66>
ffffffffc02040de:	86be                	mv	a3,a5
ffffffffc02040e0:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list) {
ffffffffc02040e2:	fef51ae3          	bne	a0,a5,ffffffffc02040d6 <insert_vma_struct+0x12>
        }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list) {
ffffffffc02040e6:	02a68463          	beq	a3,a0,ffffffffc020410e <insert_vma_struct+0x4a>
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc02040ea:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc02040ee:	fe86b883          	ld	a7,-24(a3)
ffffffffc02040f2:	08e8f163          	bgeu	a7,a4,ffffffffc0204174 <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc02040f6:	04e66f63          	bltu	a2,a4,ffffffffc0204154 <insert_vma_struct+0x90>
    }
    if (le_next != list) {
ffffffffc02040fa:	00f50a63          	beq	a0,a5,ffffffffc020410e <insert_vma_struct+0x4a>
            if (mmap_prev->vm_start > vma->vm_start) {
ffffffffc02040fe:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0204102:	05076963          	bltu	a4,a6,ffffffffc0204154 <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc0204106:	ff07b603          	ld	a2,-16(a5)
ffffffffc020410a:	02c77363          	bgeu	a4,a2,ffffffffc0204130 <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count ++;
ffffffffc020410e:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0204110:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0204112:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc0204116:	e390                	sd	a2,0(a5)
ffffffffc0204118:	e690                	sd	a2,8(a3)
}
ffffffffc020411a:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc020411c:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc020411e:	f194                	sd	a3,32(a1)
    mm->map_count ++;
ffffffffc0204120:	0017079b          	addiw	a5,a4,1
ffffffffc0204124:	d11c                	sw	a5,32(a0)
}
ffffffffc0204126:	0141                	addi	sp,sp,16
ffffffffc0204128:	8082                	ret
    if (le_prev != list) {
ffffffffc020412a:	fca690e3          	bne	a3,a0,ffffffffc02040ea <insert_vma_struct+0x26>
ffffffffc020412e:	bfd1                	j	ffffffffc0204102 <insert_vma_struct+0x3e>
ffffffffc0204130:	ebbff0ef          	jal	ra,ffffffffc0203fea <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0204134:	00004697          	auipc	a3,0x4
ffffffffc0204138:	d1c68693          	addi	a3,a3,-740 # ffffffffc0207e50 <default_pmm_manager+0xc28>
ffffffffc020413c:	00003617          	auipc	a2,0x3
ffffffffc0204140:	a5460613          	addi	a2,a2,-1452 # ffffffffc0206b90 <commands+0x450>
ffffffffc0204144:	07400593          	li	a1,116
ffffffffc0204148:	00004517          	auipc	a0,0x4
ffffffffc020414c:	cf850513          	addi	a0,a0,-776 # ffffffffc0207e40 <default_pmm_manager+0xc18>
ffffffffc0204150:	b2afc0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0204154:	00004697          	auipc	a3,0x4
ffffffffc0204158:	d3c68693          	addi	a3,a3,-708 # ffffffffc0207e90 <default_pmm_manager+0xc68>
ffffffffc020415c:	00003617          	auipc	a2,0x3
ffffffffc0204160:	a3460613          	addi	a2,a2,-1484 # ffffffffc0206b90 <commands+0x450>
ffffffffc0204164:	06c00593          	li	a1,108
ffffffffc0204168:	00004517          	auipc	a0,0x4
ffffffffc020416c:	cd850513          	addi	a0,a0,-808 # ffffffffc0207e40 <default_pmm_manager+0xc18>
ffffffffc0204170:	b0afc0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc0204174:	00004697          	auipc	a3,0x4
ffffffffc0204178:	cfc68693          	addi	a3,a3,-772 # ffffffffc0207e70 <default_pmm_manager+0xc48>
ffffffffc020417c:	00003617          	auipc	a2,0x3
ffffffffc0204180:	a1460613          	addi	a2,a2,-1516 # ffffffffc0206b90 <commands+0x450>
ffffffffc0204184:	06b00593          	li	a1,107
ffffffffc0204188:	00004517          	auipc	a0,0x4
ffffffffc020418c:	cb850513          	addi	a0,a0,-840 # ffffffffc0207e40 <default_pmm_manager+0xc18>
ffffffffc0204190:	aeafc0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0204194 <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void
mm_destroy(struct mm_struct *mm) {
    assert(mm_count(mm) == 0);
ffffffffc0204194:	591c                	lw	a5,48(a0)
mm_destroy(struct mm_struct *mm) {
ffffffffc0204196:	1141                	addi	sp,sp,-16
ffffffffc0204198:	e406                	sd	ra,8(sp)
ffffffffc020419a:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc020419c:	e78d                	bnez	a5,ffffffffc02041c6 <mm_destroy+0x32>
ffffffffc020419e:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc02041a0:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list) {
ffffffffc02041a2:	00a40c63          	beq	s0,a0,ffffffffc02041ba <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc02041a6:	6118                	ld	a4,0(a0)
ffffffffc02041a8:	651c                	ld	a5,8(a0)
        list_del(le);
        kfree(le2vma(le, list_link));  //kfree vma        
ffffffffc02041aa:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc02041ac:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02041ae:	e398                	sd	a4,0(a5)
ffffffffc02041b0:	a03fd0ef          	jal	ra,ffffffffc0201bb2 <kfree>
    return listelm->next;
ffffffffc02041b4:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list) {
ffffffffc02041b6:	fea418e3          	bne	s0,a0,ffffffffc02041a6 <mm_destroy+0x12>
    }
    kfree(mm); //kfree mm
ffffffffc02041ba:	8522                	mv	a0,s0
    mm=NULL;
}
ffffffffc02041bc:	6402                	ld	s0,0(sp)
ffffffffc02041be:	60a2                	ld	ra,8(sp)
ffffffffc02041c0:	0141                	addi	sp,sp,16
    kfree(mm); //kfree mm
ffffffffc02041c2:	9f1fd06f          	j	ffffffffc0201bb2 <kfree>
    assert(mm_count(mm) == 0);
ffffffffc02041c6:	00004697          	auipc	a3,0x4
ffffffffc02041ca:	cea68693          	addi	a3,a3,-790 # ffffffffc0207eb0 <default_pmm_manager+0xc88>
ffffffffc02041ce:	00003617          	auipc	a2,0x3
ffffffffc02041d2:	9c260613          	addi	a2,a2,-1598 # ffffffffc0206b90 <commands+0x450>
ffffffffc02041d6:	09400593          	li	a1,148
ffffffffc02041da:	00004517          	auipc	a0,0x4
ffffffffc02041de:	c6650513          	addi	a0,a0,-922 # ffffffffc0207e40 <default_pmm_manager+0xc18>
ffffffffc02041e2:	a98fc0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc02041e6 <mm_map>:

int
mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
       struct vma_struct **vma_store) {
ffffffffc02041e6:	7139                	addi	sp,sp,-64
ffffffffc02041e8:	f822                	sd	s0,48(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc02041ea:	6405                	lui	s0,0x1
ffffffffc02041ec:	147d                	addi	s0,s0,-1
ffffffffc02041ee:	77fd                	lui	a5,0xfffff
ffffffffc02041f0:	9622                	add	a2,a2,s0
ffffffffc02041f2:	962e                	add	a2,a2,a1
       struct vma_struct **vma_store) {
ffffffffc02041f4:	f426                	sd	s1,40(sp)
ffffffffc02041f6:	fc06                	sd	ra,56(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc02041f8:	00f5f4b3          	and	s1,a1,a5
       struct vma_struct **vma_store) {
ffffffffc02041fc:	f04a                	sd	s2,32(sp)
ffffffffc02041fe:	ec4e                	sd	s3,24(sp)
ffffffffc0204200:	e852                	sd	s4,16(sp)
ffffffffc0204202:	e456                	sd	s5,8(sp)
    if (!USER_ACCESS(start, end)) {
ffffffffc0204204:	002005b7          	lui	a1,0x200
ffffffffc0204208:	00f67433          	and	s0,a2,a5
ffffffffc020420c:	06b4e363          	bltu	s1,a1,ffffffffc0204272 <mm_map+0x8c>
ffffffffc0204210:	0684f163          	bgeu	s1,s0,ffffffffc0204272 <mm_map+0x8c>
ffffffffc0204214:	4785                	li	a5,1
ffffffffc0204216:	07fe                	slli	a5,a5,0x1f
ffffffffc0204218:	0487ed63          	bltu	a5,s0,ffffffffc0204272 <mm_map+0x8c>
ffffffffc020421c:	89aa                	mv	s3,a0
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc020421e:	cd21                	beqz	a0,ffffffffc0204276 <mm_map+0x90>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start) {
ffffffffc0204220:	85a6                	mv	a1,s1
ffffffffc0204222:	8ab6                	mv	s5,a3
ffffffffc0204224:	8a3a                	mv	s4,a4
ffffffffc0204226:	e5fff0ef          	jal	ra,ffffffffc0204084 <find_vma>
ffffffffc020422a:	c501                	beqz	a0,ffffffffc0204232 <mm_map+0x4c>
ffffffffc020422c:	651c                	ld	a5,8(a0)
ffffffffc020422e:	0487e263          	bltu	a5,s0,ffffffffc0204272 <mm_map+0x8c>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0204232:	03000513          	li	a0,48
ffffffffc0204236:	8cdfd0ef          	jal	ra,ffffffffc0201b02 <kmalloc>
ffffffffc020423a:	892a                	mv	s2,a0
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc020423c:	5571                	li	a0,-4
    if (vma != NULL) {
ffffffffc020423e:	02090163          	beqz	s2,ffffffffc0204260 <mm_map+0x7a>

    if ((vma = vma_create(start, end, vm_flags)) == NULL) {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc0204242:	854e                	mv	a0,s3
        vma->vm_start = vm_start;
ffffffffc0204244:	00993423          	sd	s1,8(s2)
        vma->vm_end = vm_end;
ffffffffc0204248:	00893823          	sd	s0,16(s2)
        vma->vm_flags = vm_flags;
ffffffffc020424c:	01592c23          	sw	s5,24(s2)
    insert_vma_struct(mm, vma);
ffffffffc0204250:	85ca                	mv	a1,s2
ffffffffc0204252:	e73ff0ef          	jal	ra,ffffffffc02040c4 <insert_vma_struct>
    if (vma_store != NULL) {
        *vma_store = vma;
    }
    ret = 0;
ffffffffc0204256:	4501                	li	a0,0
    if (vma_store != NULL) {
ffffffffc0204258:	000a0463          	beqz	s4,ffffffffc0204260 <mm_map+0x7a>
        *vma_store = vma;
ffffffffc020425c:	012a3023          	sd	s2,0(s4)

out:
    return ret;
}
ffffffffc0204260:	70e2                	ld	ra,56(sp)
ffffffffc0204262:	7442                	ld	s0,48(sp)
ffffffffc0204264:	74a2                	ld	s1,40(sp)
ffffffffc0204266:	7902                	ld	s2,32(sp)
ffffffffc0204268:	69e2                	ld	s3,24(sp)
ffffffffc020426a:	6a42                	ld	s4,16(sp)
ffffffffc020426c:	6aa2                	ld	s5,8(sp)
ffffffffc020426e:	6121                	addi	sp,sp,64
ffffffffc0204270:	8082                	ret
        return -E_INVAL;
ffffffffc0204272:	5575                	li	a0,-3
ffffffffc0204274:	b7f5                	j	ffffffffc0204260 <mm_map+0x7a>
    assert(mm != NULL);
ffffffffc0204276:	00003697          	auipc	a3,0x3
ffffffffc020427a:	73a68693          	addi	a3,a3,1850 # ffffffffc02079b0 <default_pmm_manager+0x788>
ffffffffc020427e:	00003617          	auipc	a2,0x3
ffffffffc0204282:	91260613          	addi	a2,a2,-1774 # ffffffffc0206b90 <commands+0x450>
ffffffffc0204286:	0a700593          	li	a1,167
ffffffffc020428a:	00004517          	auipc	a0,0x4
ffffffffc020428e:	bb650513          	addi	a0,a0,-1098 # ffffffffc0207e40 <default_pmm_manager+0xc18>
ffffffffc0204292:	9e8fc0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0204296 <dup_mmap>:

int
dup_mmap(struct mm_struct *to, struct mm_struct *from) {
ffffffffc0204296:	7139                	addi	sp,sp,-64
ffffffffc0204298:	fc06                	sd	ra,56(sp)
ffffffffc020429a:	f822                	sd	s0,48(sp)
ffffffffc020429c:	f426                	sd	s1,40(sp)
ffffffffc020429e:	f04a                	sd	s2,32(sp)
ffffffffc02042a0:	ec4e                	sd	s3,24(sp)
ffffffffc02042a2:	e852                	sd	s4,16(sp)
ffffffffc02042a4:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc02042a6:	c52d                	beqz	a0,ffffffffc0204310 <dup_mmap+0x7a>
ffffffffc02042a8:	892a                	mv	s2,a0
ffffffffc02042aa:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc02042ac:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc02042ae:	e595                	bnez	a1,ffffffffc02042da <dup_mmap+0x44>
ffffffffc02042b0:	a085                	j	ffffffffc0204310 <dup_mmap+0x7a>
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
        if (nvma == NULL) {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc02042b2:	854a                	mv	a0,s2
        vma->vm_start = vm_start;
ffffffffc02042b4:	0155b423          	sd	s5,8(a1) # 200008 <_binary_obj___user_exit_out_size+0x1f4ee0>
        vma->vm_end = vm_end;
ffffffffc02042b8:	0145b823          	sd	s4,16(a1)
        vma->vm_flags = vm_flags;
ffffffffc02042bc:	0135ac23          	sw	s3,24(a1)
        insert_vma_struct(to, nvma);
ffffffffc02042c0:	e05ff0ef          	jal	ra,ffffffffc02040c4 <insert_vma_struct>

        bool share = 0;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0) {
ffffffffc02042c4:	ff043683          	ld	a3,-16(s0) # ff0 <_binary_obj___user_faultread_out_size-0x8bc8>
ffffffffc02042c8:	fe843603          	ld	a2,-24(s0)
ffffffffc02042cc:	6c8c                	ld	a1,24(s1)
ffffffffc02042ce:	01893503          	ld	a0,24(s2)
ffffffffc02042d2:	4701                	li	a4,0
ffffffffc02042d4:	e43fe0ef          	jal	ra,ffffffffc0203116 <copy_range>
ffffffffc02042d8:	e105                	bnez	a0,ffffffffc02042f8 <dup_mmap+0x62>
    return listelm->prev;
ffffffffc02042da:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list) {
ffffffffc02042dc:	02848863          	beq	s1,s0,ffffffffc020430c <dup_mmap+0x76>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02042e0:	03000513          	li	a0,48
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc02042e4:	fe843a83          	ld	s5,-24(s0)
ffffffffc02042e8:	ff043a03          	ld	s4,-16(s0)
ffffffffc02042ec:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02042f0:	813fd0ef          	jal	ra,ffffffffc0201b02 <kmalloc>
ffffffffc02042f4:	85aa                	mv	a1,a0
    if (vma != NULL) {
ffffffffc02042f6:	fd55                	bnez	a0,ffffffffc02042b2 <dup_mmap+0x1c>
            return -E_NO_MEM;
ffffffffc02042f8:	5571                	li	a0,-4
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc02042fa:	70e2                	ld	ra,56(sp)
ffffffffc02042fc:	7442                	ld	s0,48(sp)
ffffffffc02042fe:	74a2                	ld	s1,40(sp)
ffffffffc0204300:	7902                	ld	s2,32(sp)
ffffffffc0204302:	69e2                	ld	s3,24(sp)
ffffffffc0204304:	6a42                	ld	s4,16(sp)
ffffffffc0204306:	6aa2                	ld	s5,8(sp)
ffffffffc0204308:	6121                	addi	sp,sp,64
ffffffffc020430a:	8082                	ret
    return 0;
ffffffffc020430c:	4501                	li	a0,0
ffffffffc020430e:	b7f5                	j	ffffffffc02042fa <dup_mmap+0x64>
    assert(to != NULL && from != NULL);
ffffffffc0204310:	00004697          	auipc	a3,0x4
ffffffffc0204314:	bb868693          	addi	a3,a3,-1096 # ffffffffc0207ec8 <default_pmm_manager+0xca0>
ffffffffc0204318:	00003617          	auipc	a2,0x3
ffffffffc020431c:	87860613          	addi	a2,a2,-1928 # ffffffffc0206b90 <commands+0x450>
ffffffffc0204320:	0c000593          	li	a1,192
ffffffffc0204324:	00004517          	auipc	a0,0x4
ffffffffc0204328:	b1c50513          	addi	a0,a0,-1252 # ffffffffc0207e40 <default_pmm_manager+0xc18>
ffffffffc020432c:	94efc0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0204330 <exit_mmap>:

void
exit_mmap(struct mm_struct *mm) {
ffffffffc0204330:	1101                	addi	sp,sp,-32
ffffffffc0204332:	ec06                	sd	ra,24(sp)
ffffffffc0204334:	e822                	sd	s0,16(sp)
ffffffffc0204336:	e426                	sd	s1,8(sp)
ffffffffc0204338:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc020433a:	c531                	beqz	a0,ffffffffc0204386 <exit_mmap+0x56>
ffffffffc020433c:	591c                	lw	a5,48(a0)
ffffffffc020433e:	84aa                	mv	s1,a0
ffffffffc0204340:	e3b9                	bnez	a5,ffffffffc0204386 <exit_mmap+0x56>
    return listelm->next;
ffffffffc0204342:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc0204344:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list) {
ffffffffc0204348:	02850663          	beq	a0,s0,ffffffffc0204374 <exit_mmap+0x44>
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc020434c:	ff043603          	ld	a2,-16(s0)
ffffffffc0204350:	fe843583          	ld	a1,-24(s0)
ffffffffc0204354:	854a                	mv	a0,s2
ffffffffc0204356:	cbdfd0ef          	jal	ra,ffffffffc0202012 <unmap_range>
ffffffffc020435a:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list) {
ffffffffc020435c:	fe8498e3          	bne	s1,s0,ffffffffc020434c <exit_mmap+0x1c>
ffffffffc0204360:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list) {
ffffffffc0204362:	00848c63          	beq	s1,s0,ffffffffc020437a <exit_mmap+0x4a>
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0204366:	ff043603          	ld	a2,-16(s0)
ffffffffc020436a:	fe843583          	ld	a1,-24(s0)
ffffffffc020436e:	854a                	mv	a0,s2
ffffffffc0204370:	de9fd0ef          	jal	ra,ffffffffc0202158 <exit_range>
ffffffffc0204374:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list) {
ffffffffc0204376:	fe8498e3          	bne	s1,s0,ffffffffc0204366 <exit_mmap+0x36>
    }
}
ffffffffc020437a:	60e2                	ld	ra,24(sp)
ffffffffc020437c:	6442                	ld	s0,16(sp)
ffffffffc020437e:	64a2                	ld	s1,8(sp)
ffffffffc0204380:	6902                	ld	s2,0(sp)
ffffffffc0204382:	6105                	addi	sp,sp,32
ffffffffc0204384:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0204386:	00004697          	auipc	a3,0x4
ffffffffc020438a:	b6268693          	addi	a3,a3,-1182 # ffffffffc0207ee8 <default_pmm_manager+0xcc0>
ffffffffc020438e:	00003617          	auipc	a2,0x3
ffffffffc0204392:	80260613          	addi	a2,a2,-2046 # ffffffffc0206b90 <commands+0x450>
ffffffffc0204396:	0d600593          	li	a1,214
ffffffffc020439a:	00004517          	auipc	a0,0x4
ffffffffc020439e:	aa650513          	addi	a0,a0,-1370 # ffffffffc0207e40 <default_pmm_manager+0xc18>
ffffffffc02043a2:	8d8fc0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc02043a6 <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void
vmm_init(void) {
ffffffffc02043a6:	7139                	addi	sp,sp,-64
ffffffffc02043a8:	f822                	sd	s0,48(sp)
ffffffffc02043aa:	f426                	sd	s1,40(sp)
ffffffffc02043ac:	fc06                	sd	ra,56(sp)
ffffffffc02043ae:	f04a                	sd	s2,32(sp)
ffffffffc02043b0:	ec4e                	sd	s3,24(sp)
ffffffffc02043b2:	e852                	sd	s4,16(sp)
ffffffffc02043b4:	e456                	sd	s5,8(sp)

static void
check_vma_struct(void) {
    // size_t nr_free_pages_store = nr_free_pages();

    struct mm_struct *mm = mm_create();
ffffffffc02043b6:	c59ff0ef          	jal	ra,ffffffffc020400e <mm_create>
    assert(mm != NULL);
ffffffffc02043ba:	84aa                	mv	s1,a0
ffffffffc02043bc:	03200413          	li	s0,50
ffffffffc02043c0:	e919                	bnez	a0,ffffffffc02043d6 <vmm_init+0x30>
ffffffffc02043c2:	a991                	j	ffffffffc0204816 <vmm_init+0x470>
        vma->vm_start = vm_start;
ffffffffc02043c4:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc02043c6:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc02043c8:	00052c23          	sw	zero,24(a0)

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i --) {
ffffffffc02043cc:	146d                	addi	s0,s0,-5
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc02043ce:	8526                	mv	a0,s1
ffffffffc02043d0:	cf5ff0ef          	jal	ra,ffffffffc02040c4 <insert_vma_struct>
    for (i = step1; i >= 1; i --) {
ffffffffc02043d4:	c80d                	beqz	s0,ffffffffc0204406 <vmm_init+0x60>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02043d6:	03000513          	li	a0,48
ffffffffc02043da:	f28fd0ef          	jal	ra,ffffffffc0201b02 <kmalloc>
ffffffffc02043de:	85aa                	mv	a1,a0
ffffffffc02043e0:	00240793          	addi	a5,s0,2
    if (vma != NULL) {
ffffffffc02043e4:	f165                	bnez	a0,ffffffffc02043c4 <vmm_init+0x1e>
        assert(vma != NULL);
ffffffffc02043e6:	00003697          	auipc	a3,0x3
ffffffffc02043ea:	60268693          	addi	a3,a3,1538 # ffffffffc02079e8 <default_pmm_manager+0x7c0>
ffffffffc02043ee:	00002617          	auipc	a2,0x2
ffffffffc02043f2:	7a260613          	addi	a2,a2,1954 # ffffffffc0206b90 <commands+0x450>
ffffffffc02043f6:	11300593          	li	a1,275
ffffffffc02043fa:	00004517          	auipc	a0,0x4
ffffffffc02043fe:	a4650513          	addi	a0,a0,-1466 # ffffffffc0207e40 <default_pmm_manager+0xc18>
ffffffffc0204402:	878fc0ef          	jal	ra,ffffffffc020047a <__panic>
ffffffffc0204406:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc020440a:	1f900913          	li	s2,505
ffffffffc020440e:	a819                	j	ffffffffc0204424 <vmm_init+0x7e>
        vma->vm_start = vm_start;
ffffffffc0204410:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0204412:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0204414:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc0204418:	0415                	addi	s0,s0,5
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc020441a:	8526                	mv	a0,s1
ffffffffc020441c:	ca9ff0ef          	jal	ra,ffffffffc02040c4 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc0204420:	03240a63          	beq	s0,s2,ffffffffc0204454 <vmm_init+0xae>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0204424:	03000513          	li	a0,48
ffffffffc0204428:	edafd0ef          	jal	ra,ffffffffc0201b02 <kmalloc>
ffffffffc020442c:	85aa                	mv	a1,a0
ffffffffc020442e:	00240793          	addi	a5,s0,2
    if (vma != NULL) {
ffffffffc0204432:	fd79                	bnez	a0,ffffffffc0204410 <vmm_init+0x6a>
        assert(vma != NULL);
ffffffffc0204434:	00003697          	auipc	a3,0x3
ffffffffc0204438:	5b468693          	addi	a3,a3,1460 # ffffffffc02079e8 <default_pmm_manager+0x7c0>
ffffffffc020443c:	00002617          	auipc	a2,0x2
ffffffffc0204440:	75460613          	addi	a2,a2,1876 # ffffffffc0206b90 <commands+0x450>
ffffffffc0204444:	11900593          	li	a1,281
ffffffffc0204448:	00004517          	auipc	a0,0x4
ffffffffc020444c:	9f850513          	addi	a0,a0,-1544 # ffffffffc0207e40 <default_pmm_manager+0xc18>
ffffffffc0204450:	82afc0ef          	jal	ra,ffffffffc020047a <__panic>
ffffffffc0204454:	649c                	ld	a5,8(s1)
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i ++) {
        assert(le != &(mm->mmap_list));
ffffffffc0204456:	471d                	li	a4,7
    for (i = 1; i <= step2; i ++) {
ffffffffc0204458:	1fb00593          	li	a1,507
        assert(le != &(mm->mmap_list));
ffffffffc020445c:	2cf48d63          	beq	s1,a5,ffffffffc0204736 <vmm_init+0x390>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0204460:	fe87b683          	ld	a3,-24(a5) # ffffffffffffefe8 <end+0x3fd4c71c>
ffffffffc0204464:	ffe70613          	addi	a2,a4,-2
ffffffffc0204468:	24d61763          	bne	a2,a3,ffffffffc02046b6 <vmm_init+0x310>
ffffffffc020446c:	ff07b683          	ld	a3,-16(a5)
ffffffffc0204470:	24e69363          	bne	a3,a4,ffffffffc02046b6 <vmm_init+0x310>
    for (i = 1; i <= step2; i ++) {
ffffffffc0204474:	0715                	addi	a4,a4,5
ffffffffc0204476:	679c                	ld	a5,8(a5)
ffffffffc0204478:	feb712e3          	bne	a4,a1,ffffffffc020445c <vmm_init+0xb6>
ffffffffc020447c:	4a1d                	li	s4,7
ffffffffc020447e:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc0204480:	1f900a93          	li	s5,505
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0204484:	85a2                	mv	a1,s0
ffffffffc0204486:	8526                	mv	a0,s1
ffffffffc0204488:	bfdff0ef          	jal	ra,ffffffffc0204084 <find_vma>
ffffffffc020448c:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc020448e:	30050463          	beqz	a0,ffffffffc0204796 <vmm_init+0x3f0>
        struct vma_struct *vma2 = find_vma(mm, i+1);
ffffffffc0204492:	00140593          	addi	a1,s0,1
ffffffffc0204496:	8526                	mv	a0,s1
ffffffffc0204498:	bedff0ef          	jal	ra,ffffffffc0204084 <find_vma>
ffffffffc020449c:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc020449e:	2c050c63          	beqz	a0,ffffffffc0204776 <vmm_init+0x3d0>
        struct vma_struct *vma3 = find_vma(mm, i+2);
ffffffffc02044a2:	85d2                	mv	a1,s4
ffffffffc02044a4:	8526                	mv	a0,s1
ffffffffc02044a6:	bdfff0ef          	jal	ra,ffffffffc0204084 <find_vma>
        assert(vma3 == NULL);
ffffffffc02044aa:	2a051663          	bnez	a0,ffffffffc0204756 <vmm_init+0x3b0>
        struct vma_struct *vma4 = find_vma(mm, i+3);
ffffffffc02044ae:	00340593          	addi	a1,s0,3
ffffffffc02044b2:	8526                	mv	a0,s1
ffffffffc02044b4:	bd1ff0ef          	jal	ra,ffffffffc0204084 <find_vma>
        assert(vma4 == NULL);
ffffffffc02044b8:	30051f63          	bnez	a0,ffffffffc02047d6 <vmm_init+0x430>
        struct vma_struct *vma5 = find_vma(mm, i+4);
ffffffffc02044bc:	00440593          	addi	a1,s0,4
ffffffffc02044c0:	8526                	mv	a0,s1
ffffffffc02044c2:	bc3ff0ef          	jal	ra,ffffffffc0204084 <find_vma>
        assert(vma5 == NULL);
ffffffffc02044c6:	2e051863          	bnez	a0,ffffffffc02047b6 <vmm_init+0x410>

        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc02044ca:	00893783          	ld	a5,8(s2)
ffffffffc02044ce:	20879463          	bne	a5,s0,ffffffffc02046d6 <vmm_init+0x330>
ffffffffc02044d2:	01093783          	ld	a5,16(s2)
ffffffffc02044d6:	20fa1063          	bne	s4,a5,ffffffffc02046d6 <vmm_init+0x330>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc02044da:	0089b783          	ld	a5,8(s3)
ffffffffc02044de:	20879c63          	bne	a5,s0,ffffffffc02046f6 <vmm_init+0x350>
ffffffffc02044e2:	0109b783          	ld	a5,16(s3)
ffffffffc02044e6:	20fa1863          	bne	s4,a5,ffffffffc02046f6 <vmm_init+0x350>
    for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc02044ea:	0415                	addi	s0,s0,5
ffffffffc02044ec:	0a15                	addi	s4,s4,5
ffffffffc02044ee:	f9541be3          	bne	s0,s5,ffffffffc0204484 <vmm_init+0xde>
ffffffffc02044f2:	4411                	li	s0,4
    }

    for (i =4; i>=0; i--) {
ffffffffc02044f4:	597d                	li	s2,-1
        struct vma_struct *vma_below_5= find_vma(mm,i);
ffffffffc02044f6:	85a2                	mv	a1,s0
ffffffffc02044f8:	8526                	mv	a0,s1
ffffffffc02044fa:	b8bff0ef          	jal	ra,ffffffffc0204084 <find_vma>
ffffffffc02044fe:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL ) {
ffffffffc0204502:	c90d                	beqz	a0,ffffffffc0204534 <vmm_init+0x18e>
           cprintf("vma_below_5: i %x, start %x, end %x\n",i, vma_below_5->vm_start, vma_below_5->vm_end); 
ffffffffc0204504:	6914                	ld	a3,16(a0)
ffffffffc0204506:	6510                	ld	a2,8(a0)
ffffffffc0204508:	00004517          	auipc	a0,0x4
ffffffffc020450c:	b0050513          	addi	a0,a0,-1280 # ffffffffc0208008 <default_pmm_manager+0xde0>
ffffffffc0204510:	c71fb0ef          	jal	ra,ffffffffc0200180 <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc0204514:	00004697          	auipc	a3,0x4
ffffffffc0204518:	b1c68693          	addi	a3,a3,-1252 # ffffffffc0208030 <default_pmm_manager+0xe08>
ffffffffc020451c:	00002617          	auipc	a2,0x2
ffffffffc0204520:	67460613          	addi	a2,a2,1652 # ffffffffc0206b90 <commands+0x450>
ffffffffc0204524:	13b00593          	li	a1,315
ffffffffc0204528:	00004517          	auipc	a0,0x4
ffffffffc020452c:	91850513          	addi	a0,a0,-1768 # ffffffffc0207e40 <default_pmm_manager+0xc18>
ffffffffc0204530:	f4bfb0ef          	jal	ra,ffffffffc020047a <__panic>
    for (i =4; i>=0; i--) {
ffffffffc0204534:	147d                	addi	s0,s0,-1
ffffffffc0204536:	fd2410e3          	bne	s0,s2,ffffffffc02044f6 <vmm_init+0x150>
    }

    mm_destroy(mm);
ffffffffc020453a:	8526                	mv	a0,s1
ffffffffc020453c:	c59ff0ef          	jal	ra,ffffffffc0204194 <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0204540:	00004517          	auipc	a0,0x4
ffffffffc0204544:	b0850513          	addi	a0,a0,-1272 # ffffffffc0208048 <default_pmm_manager+0xe20>
ffffffffc0204548:	c39fb0ef          	jal	ra,ffffffffc0200180 <cprintf>
struct mm_struct *check_mm_struct;

// check_pgfault - check correctness of pgfault handler
static void
check_pgfault(void) {
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc020454c:	867fd0ef          	jal	ra,ffffffffc0201db2 <nr_free_pages>
ffffffffc0204550:	892a                	mv	s2,a0

    check_mm_struct = mm_create();
ffffffffc0204552:	abdff0ef          	jal	ra,ffffffffc020400e <mm_create>
ffffffffc0204556:	000ae797          	auipc	a5,0xae
ffffffffc020455a:	34a7b523          	sd	a0,842(a5) # ffffffffc02b28a0 <check_mm_struct>
ffffffffc020455e:	842a                	mv	s0,a0
    assert(check_mm_struct != NULL);
ffffffffc0204560:	28050b63          	beqz	a0,ffffffffc02047f6 <vmm_init+0x450>

    struct mm_struct *mm = check_mm_struct;
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0204564:	000ae497          	auipc	s1,0xae
ffffffffc0204568:	2fc4b483          	ld	s1,764(s1) # ffffffffc02b2860 <boot_pgdir>
    assert(pgdir[0] == 0);
ffffffffc020456c:	609c                	ld	a5,0(s1)
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc020456e:	ed04                	sd	s1,24(a0)
    assert(pgdir[0] == 0);
ffffffffc0204570:	2e079f63          	bnez	a5,ffffffffc020486e <vmm_init+0x4c8>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0204574:	03000513          	li	a0,48
ffffffffc0204578:	d8afd0ef          	jal	ra,ffffffffc0201b02 <kmalloc>
ffffffffc020457c:	89aa                	mv	s3,a0
    if (vma != NULL) {
ffffffffc020457e:	18050c63          	beqz	a0,ffffffffc0204716 <vmm_init+0x370>
        vma->vm_end = vm_end;
ffffffffc0204582:	002007b7          	lui	a5,0x200
ffffffffc0204586:	00f9b823          	sd	a5,16(s3)
        vma->vm_flags = vm_flags;
ffffffffc020458a:	4789                	li	a5,2

    struct vma_struct *vma = vma_create(0, PTSIZE, VM_WRITE);
    assert(vma != NULL);

    insert_vma_struct(mm, vma);
ffffffffc020458c:	85aa                	mv	a1,a0
        vma->vm_flags = vm_flags;
ffffffffc020458e:	00f9ac23          	sw	a5,24(s3)
    insert_vma_struct(mm, vma);
ffffffffc0204592:	8522                	mv	a0,s0
        vma->vm_start = vm_start;
ffffffffc0204594:	0009b423          	sd	zero,8(s3)
    insert_vma_struct(mm, vma);
ffffffffc0204598:	b2dff0ef          	jal	ra,ffffffffc02040c4 <insert_vma_struct>

    uintptr_t addr = 0x100;
    assert(find_vma(mm, addr) == vma);
ffffffffc020459c:	10000593          	li	a1,256
ffffffffc02045a0:	8522                	mv	a0,s0
ffffffffc02045a2:	ae3ff0ef          	jal	ra,ffffffffc0204084 <find_vma>
ffffffffc02045a6:	10000793          	li	a5,256

    int i, sum = 0;

    for (i = 0; i < 100; i ++) {
ffffffffc02045aa:	16400713          	li	a4,356
    assert(find_vma(mm, addr) == vma);
ffffffffc02045ae:	2ea99063          	bne	s3,a0,ffffffffc020488e <vmm_init+0x4e8>
        *(char *)(addr + i) = i;
ffffffffc02045b2:	00f78023          	sb	a5,0(a5) # 200000 <_binary_obj___user_exit_out_size+0x1f4ed8>
    for (i = 0; i < 100; i ++) {
ffffffffc02045b6:	0785                	addi	a5,a5,1
ffffffffc02045b8:	fee79de3          	bne	a5,a4,ffffffffc02045b2 <vmm_init+0x20c>
        sum += i;
ffffffffc02045bc:	6705                	lui	a4,0x1
ffffffffc02045be:	10000793          	li	a5,256
ffffffffc02045c2:	35670713          	addi	a4,a4,854 # 1356 <_binary_obj___user_faultread_out_size-0x8862>
    }
    for (i = 0; i < 100; i ++) {
ffffffffc02045c6:	16400613          	li	a2,356
        sum -= *(char *)(addr + i);
ffffffffc02045ca:	0007c683          	lbu	a3,0(a5)
    for (i = 0; i < 100; i ++) {
ffffffffc02045ce:	0785                	addi	a5,a5,1
        sum -= *(char *)(addr + i);
ffffffffc02045d0:	9f15                	subw	a4,a4,a3
    for (i = 0; i < 100; i ++) {
ffffffffc02045d2:	fec79ce3          	bne	a5,a2,ffffffffc02045ca <vmm_init+0x224>
    }

    assert(sum == 0);
ffffffffc02045d6:	2e071863          	bnez	a4,ffffffffc02048c6 <vmm_init+0x520>
    return pa2page(PDE_ADDR(pde));
ffffffffc02045da:	609c                	ld	a5,0(s1)
    if (PPN(pa) >= npage) {
ffffffffc02045dc:	000aea97          	auipc	s5,0xae
ffffffffc02045e0:	28ca8a93          	addi	s5,s5,652 # ffffffffc02b2868 <npage>
ffffffffc02045e4:	000ab603          	ld	a2,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc02045e8:	078a                	slli	a5,a5,0x2
ffffffffc02045ea:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02045ec:	2cc7f163          	bgeu	a5,a2,ffffffffc02048ae <vmm_init+0x508>
    return &pages[PPN(pa) - nbase];
ffffffffc02045f0:	00004a17          	auipc	s4,0x4
ffffffffc02045f4:	580a3a03          	ld	s4,1408(s4) # ffffffffc0208b70 <nbase>
ffffffffc02045f8:	414787b3          	sub	a5,a5,s4
ffffffffc02045fc:	079a                	slli	a5,a5,0x6
    return page - pages + nbase;
ffffffffc02045fe:	8799                	srai	a5,a5,0x6
ffffffffc0204600:	97d2                	add	a5,a5,s4
    return KADDR(page2pa(page));
ffffffffc0204602:	00c79713          	slli	a4,a5,0xc
ffffffffc0204606:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0204608:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc020460c:	24c77563          	bgeu	a4,a2,ffffffffc0204856 <vmm_init+0x4b0>
ffffffffc0204610:	000ae997          	auipc	s3,0xae
ffffffffc0204614:	2709b983          	ld	s3,624(s3) # ffffffffc02b2880 <va_pa_offset>

    pde_t *pd1=pgdir,*pd0=page2kva(pde2page(pgdir[0]));
    page_remove(pgdir, ROUNDDOWN(addr, PGSIZE));
ffffffffc0204618:	4581                	li	a1,0
ffffffffc020461a:	8526                	mv	a0,s1
ffffffffc020461c:	99b6                	add	s3,s3,a3
ffffffffc020461e:	dcdfd0ef          	jal	ra,ffffffffc02023ea <page_remove>
    return pa2page(PDE_ADDR(pde));
ffffffffc0204622:	0009b783          	ld	a5,0(s3)
    if (PPN(pa) >= npage) {
ffffffffc0204626:	000ab703          	ld	a4,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc020462a:	078a                	slli	a5,a5,0x2
ffffffffc020462c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020462e:	28e7f063          	bgeu	a5,a4,ffffffffc02048ae <vmm_init+0x508>
    return &pages[PPN(pa) - nbase];
ffffffffc0204632:	000ae997          	auipc	s3,0xae
ffffffffc0204636:	23e98993          	addi	s3,s3,574 # ffffffffc02b2870 <pages>
ffffffffc020463a:	0009b503          	ld	a0,0(s3)
ffffffffc020463e:	414787b3          	sub	a5,a5,s4
ffffffffc0204642:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd0[0]));
ffffffffc0204644:	953e                	add	a0,a0,a5
ffffffffc0204646:	4585                	li	a1,1
ffffffffc0204648:	f2afd0ef          	jal	ra,ffffffffc0201d72 <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc020464c:	609c                	ld	a5,0(s1)
    if (PPN(pa) >= npage) {
ffffffffc020464e:	000ab703          	ld	a4,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc0204652:	078a                	slli	a5,a5,0x2
ffffffffc0204654:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0204656:	24e7fc63          	bgeu	a5,a4,ffffffffc02048ae <vmm_init+0x508>
    return &pages[PPN(pa) - nbase];
ffffffffc020465a:	0009b503          	ld	a0,0(s3)
ffffffffc020465e:	414787b3          	sub	a5,a5,s4
ffffffffc0204662:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd1[0]));
ffffffffc0204664:	4585                	li	a1,1
ffffffffc0204666:	953e                	add	a0,a0,a5
ffffffffc0204668:	f0afd0ef          	jal	ra,ffffffffc0201d72 <free_pages>
    pgdir[0] = 0;
ffffffffc020466c:	0004b023          	sd	zero,0(s1)
  asm volatile("sfence.vma");
ffffffffc0204670:	12000073          	sfence.vma
    flush_tlb();

    mm->pgdir = NULL;
    mm_destroy(mm);
ffffffffc0204674:	8522                	mv	a0,s0
    mm->pgdir = NULL;
ffffffffc0204676:	00043c23          	sd	zero,24(s0)
    mm_destroy(mm);
ffffffffc020467a:	b1bff0ef          	jal	ra,ffffffffc0204194 <mm_destroy>
    check_mm_struct = NULL;
ffffffffc020467e:	000ae797          	auipc	a5,0xae
ffffffffc0204682:	2207b123          	sd	zero,546(a5) # ffffffffc02b28a0 <check_mm_struct>

    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0204686:	f2cfd0ef          	jal	ra,ffffffffc0201db2 <nr_free_pages>
ffffffffc020468a:	1aa91663          	bne	s2,a0,ffffffffc0204836 <vmm_init+0x490>

    cprintf("check_pgfault() succeeded!\n");
ffffffffc020468e:	00004517          	auipc	a0,0x4
ffffffffc0204692:	a4a50513          	addi	a0,a0,-1462 # ffffffffc02080d8 <default_pmm_manager+0xeb0>
ffffffffc0204696:	aebfb0ef          	jal	ra,ffffffffc0200180 <cprintf>
}
ffffffffc020469a:	7442                	ld	s0,48(sp)
ffffffffc020469c:	70e2                	ld	ra,56(sp)
ffffffffc020469e:	74a2                	ld	s1,40(sp)
ffffffffc02046a0:	7902                	ld	s2,32(sp)
ffffffffc02046a2:	69e2                	ld	s3,24(sp)
ffffffffc02046a4:	6a42                	ld	s4,16(sp)
ffffffffc02046a6:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc02046a8:	00004517          	auipc	a0,0x4
ffffffffc02046ac:	a5050513          	addi	a0,a0,-1456 # ffffffffc02080f8 <default_pmm_manager+0xed0>
}
ffffffffc02046b0:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc02046b2:	acffb06f          	j	ffffffffc0200180 <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc02046b6:	00004697          	auipc	a3,0x4
ffffffffc02046ba:	86a68693          	addi	a3,a3,-1942 # ffffffffc0207f20 <default_pmm_manager+0xcf8>
ffffffffc02046be:	00002617          	auipc	a2,0x2
ffffffffc02046c2:	4d260613          	addi	a2,a2,1234 # ffffffffc0206b90 <commands+0x450>
ffffffffc02046c6:	12200593          	li	a1,290
ffffffffc02046ca:	00003517          	auipc	a0,0x3
ffffffffc02046ce:	77650513          	addi	a0,a0,1910 # ffffffffc0207e40 <default_pmm_manager+0xc18>
ffffffffc02046d2:	da9fb0ef          	jal	ra,ffffffffc020047a <__panic>
        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc02046d6:	00004697          	auipc	a3,0x4
ffffffffc02046da:	8d268693          	addi	a3,a3,-1838 # ffffffffc0207fa8 <default_pmm_manager+0xd80>
ffffffffc02046de:	00002617          	auipc	a2,0x2
ffffffffc02046e2:	4b260613          	addi	a2,a2,1202 # ffffffffc0206b90 <commands+0x450>
ffffffffc02046e6:	13200593          	li	a1,306
ffffffffc02046ea:	00003517          	auipc	a0,0x3
ffffffffc02046ee:	75650513          	addi	a0,a0,1878 # ffffffffc0207e40 <default_pmm_manager+0xc18>
ffffffffc02046f2:	d89fb0ef          	jal	ra,ffffffffc020047a <__panic>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc02046f6:	00004697          	auipc	a3,0x4
ffffffffc02046fa:	8e268693          	addi	a3,a3,-1822 # ffffffffc0207fd8 <default_pmm_manager+0xdb0>
ffffffffc02046fe:	00002617          	auipc	a2,0x2
ffffffffc0204702:	49260613          	addi	a2,a2,1170 # ffffffffc0206b90 <commands+0x450>
ffffffffc0204706:	13300593          	li	a1,307
ffffffffc020470a:	00003517          	auipc	a0,0x3
ffffffffc020470e:	73650513          	addi	a0,a0,1846 # ffffffffc0207e40 <default_pmm_manager+0xc18>
ffffffffc0204712:	d69fb0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(vma != NULL);
ffffffffc0204716:	00003697          	auipc	a3,0x3
ffffffffc020471a:	2d268693          	addi	a3,a3,722 # ffffffffc02079e8 <default_pmm_manager+0x7c0>
ffffffffc020471e:	00002617          	auipc	a2,0x2
ffffffffc0204722:	47260613          	addi	a2,a2,1138 # ffffffffc0206b90 <commands+0x450>
ffffffffc0204726:	15200593          	li	a1,338
ffffffffc020472a:	00003517          	auipc	a0,0x3
ffffffffc020472e:	71650513          	addi	a0,a0,1814 # ffffffffc0207e40 <default_pmm_manager+0xc18>
ffffffffc0204732:	d49fb0ef          	jal	ra,ffffffffc020047a <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0204736:	00003697          	auipc	a3,0x3
ffffffffc020473a:	7d268693          	addi	a3,a3,2002 # ffffffffc0207f08 <default_pmm_manager+0xce0>
ffffffffc020473e:	00002617          	auipc	a2,0x2
ffffffffc0204742:	45260613          	addi	a2,a2,1106 # ffffffffc0206b90 <commands+0x450>
ffffffffc0204746:	12000593          	li	a1,288
ffffffffc020474a:	00003517          	auipc	a0,0x3
ffffffffc020474e:	6f650513          	addi	a0,a0,1782 # ffffffffc0207e40 <default_pmm_manager+0xc18>
ffffffffc0204752:	d29fb0ef          	jal	ra,ffffffffc020047a <__panic>
        assert(vma3 == NULL);
ffffffffc0204756:	00004697          	auipc	a3,0x4
ffffffffc020475a:	82268693          	addi	a3,a3,-2014 # ffffffffc0207f78 <default_pmm_manager+0xd50>
ffffffffc020475e:	00002617          	auipc	a2,0x2
ffffffffc0204762:	43260613          	addi	a2,a2,1074 # ffffffffc0206b90 <commands+0x450>
ffffffffc0204766:	12c00593          	li	a1,300
ffffffffc020476a:	00003517          	auipc	a0,0x3
ffffffffc020476e:	6d650513          	addi	a0,a0,1750 # ffffffffc0207e40 <default_pmm_manager+0xc18>
ffffffffc0204772:	d09fb0ef          	jal	ra,ffffffffc020047a <__panic>
        assert(vma2 != NULL);
ffffffffc0204776:	00003697          	auipc	a3,0x3
ffffffffc020477a:	7f268693          	addi	a3,a3,2034 # ffffffffc0207f68 <default_pmm_manager+0xd40>
ffffffffc020477e:	00002617          	auipc	a2,0x2
ffffffffc0204782:	41260613          	addi	a2,a2,1042 # ffffffffc0206b90 <commands+0x450>
ffffffffc0204786:	12a00593          	li	a1,298
ffffffffc020478a:	00003517          	auipc	a0,0x3
ffffffffc020478e:	6b650513          	addi	a0,a0,1718 # ffffffffc0207e40 <default_pmm_manager+0xc18>
ffffffffc0204792:	ce9fb0ef          	jal	ra,ffffffffc020047a <__panic>
        assert(vma1 != NULL);
ffffffffc0204796:	00003697          	auipc	a3,0x3
ffffffffc020479a:	7c268693          	addi	a3,a3,1986 # ffffffffc0207f58 <default_pmm_manager+0xd30>
ffffffffc020479e:	00002617          	auipc	a2,0x2
ffffffffc02047a2:	3f260613          	addi	a2,a2,1010 # ffffffffc0206b90 <commands+0x450>
ffffffffc02047a6:	12800593          	li	a1,296
ffffffffc02047aa:	00003517          	auipc	a0,0x3
ffffffffc02047ae:	69650513          	addi	a0,a0,1686 # ffffffffc0207e40 <default_pmm_manager+0xc18>
ffffffffc02047b2:	cc9fb0ef          	jal	ra,ffffffffc020047a <__panic>
        assert(vma5 == NULL);
ffffffffc02047b6:	00003697          	auipc	a3,0x3
ffffffffc02047ba:	7e268693          	addi	a3,a3,2018 # ffffffffc0207f98 <default_pmm_manager+0xd70>
ffffffffc02047be:	00002617          	auipc	a2,0x2
ffffffffc02047c2:	3d260613          	addi	a2,a2,978 # ffffffffc0206b90 <commands+0x450>
ffffffffc02047c6:	13000593          	li	a1,304
ffffffffc02047ca:	00003517          	auipc	a0,0x3
ffffffffc02047ce:	67650513          	addi	a0,a0,1654 # ffffffffc0207e40 <default_pmm_manager+0xc18>
ffffffffc02047d2:	ca9fb0ef          	jal	ra,ffffffffc020047a <__panic>
        assert(vma4 == NULL);
ffffffffc02047d6:	00003697          	auipc	a3,0x3
ffffffffc02047da:	7b268693          	addi	a3,a3,1970 # ffffffffc0207f88 <default_pmm_manager+0xd60>
ffffffffc02047de:	00002617          	auipc	a2,0x2
ffffffffc02047e2:	3b260613          	addi	a2,a2,946 # ffffffffc0206b90 <commands+0x450>
ffffffffc02047e6:	12e00593          	li	a1,302
ffffffffc02047ea:	00003517          	auipc	a0,0x3
ffffffffc02047ee:	65650513          	addi	a0,a0,1622 # ffffffffc0207e40 <default_pmm_manager+0xc18>
ffffffffc02047f2:	c89fb0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(check_mm_struct != NULL);
ffffffffc02047f6:	00004697          	auipc	a3,0x4
ffffffffc02047fa:	87268693          	addi	a3,a3,-1934 # ffffffffc0208068 <default_pmm_manager+0xe40>
ffffffffc02047fe:	00002617          	auipc	a2,0x2
ffffffffc0204802:	39260613          	addi	a2,a2,914 # ffffffffc0206b90 <commands+0x450>
ffffffffc0204806:	14b00593          	li	a1,331
ffffffffc020480a:	00003517          	auipc	a0,0x3
ffffffffc020480e:	63650513          	addi	a0,a0,1590 # ffffffffc0207e40 <default_pmm_manager+0xc18>
ffffffffc0204812:	c69fb0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(mm != NULL);
ffffffffc0204816:	00003697          	auipc	a3,0x3
ffffffffc020481a:	19a68693          	addi	a3,a3,410 # ffffffffc02079b0 <default_pmm_manager+0x788>
ffffffffc020481e:	00002617          	auipc	a2,0x2
ffffffffc0204822:	37260613          	addi	a2,a2,882 # ffffffffc0206b90 <commands+0x450>
ffffffffc0204826:	10c00593          	li	a1,268
ffffffffc020482a:	00003517          	auipc	a0,0x3
ffffffffc020482e:	61650513          	addi	a0,a0,1558 # ffffffffc0207e40 <default_pmm_manager+0xc18>
ffffffffc0204832:	c49fb0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0204836:	00004697          	auipc	a3,0x4
ffffffffc020483a:	87a68693          	addi	a3,a3,-1926 # ffffffffc02080b0 <default_pmm_manager+0xe88>
ffffffffc020483e:	00002617          	auipc	a2,0x2
ffffffffc0204842:	35260613          	addi	a2,a2,850 # ffffffffc0206b90 <commands+0x450>
ffffffffc0204846:	17000593          	li	a1,368
ffffffffc020484a:	00003517          	auipc	a0,0x3
ffffffffc020484e:	5f650513          	addi	a0,a0,1526 # ffffffffc0207e40 <default_pmm_manager+0xc18>
ffffffffc0204852:	c29fb0ef          	jal	ra,ffffffffc020047a <__panic>
    return KADDR(page2pa(page));
ffffffffc0204856:	00003617          	auipc	a2,0x3
ffffffffc020485a:	a0a60613          	addi	a2,a2,-1526 # ffffffffc0207260 <default_pmm_manager+0x38>
ffffffffc020485e:	06900593          	li	a1,105
ffffffffc0204862:	00003517          	auipc	a0,0x3
ffffffffc0204866:	a2650513          	addi	a0,a0,-1498 # ffffffffc0207288 <default_pmm_manager+0x60>
ffffffffc020486a:	c11fb0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(pgdir[0] == 0);
ffffffffc020486e:	00003697          	auipc	a3,0x3
ffffffffc0204872:	16a68693          	addi	a3,a3,362 # ffffffffc02079d8 <default_pmm_manager+0x7b0>
ffffffffc0204876:	00002617          	auipc	a2,0x2
ffffffffc020487a:	31a60613          	addi	a2,a2,794 # ffffffffc0206b90 <commands+0x450>
ffffffffc020487e:	14f00593          	li	a1,335
ffffffffc0204882:	00003517          	auipc	a0,0x3
ffffffffc0204886:	5be50513          	addi	a0,a0,1470 # ffffffffc0207e40 <default_pmm_manager+0xc18>
ffffffffc020488a:	bf1fb0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(find_vma(mm, addr) == vma);
ffffffffc020488e:	00003697          	auipc	a3,0x3
ffffffffc0204892:	7f268693          	addi	a3,a3,2034 # ffffffffc0208080 <default_pmm_manager+0xe58>
ffffffffc0204896:	00002617          	auipc	a2,0x2
ffffffffc020489a:	2fa60613          	addi	a2,a2,762 # ffffffffc0206b90 <commands+0x450>
ffffffffc020489e:	15700593          	li	a1,343
ffffffffc02048a2:	00003517          	auipc	a0,0x3
ffffffffc02048a6:	59e50513          	addi	a0,a0,1438 # ffffffffc0207e40 <default_pmm_manager+0xc18>
ffffffffc02048aa:	bd1fb0ef          	jal	ra,ffffffffc020047a <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02048ae:	00003617          	auipc	a2,0x3
ffffffffc02048b2:	a8260613          	addi	a2,a2,-1406 # ffffffffc0207330 <default_pmm_manager+0x108>
ffffffffc02048b6:	06200593          	li	a1,98
ffffffffc02048ba:	00003517          	auipc	a0,0x3
ffffffffc02048be:	9ce50513          	addi	a0,a0,-1586 # ffffffffc0207288 <default_pmm_manager+0x60>
ffffffffc02048c2:	bb9fb0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(sum == 0);
ffffffffc02048c6:	00003697          	auipc	a3,0x3
ffffffffc02048ca:	7da68693          	addi	a3,a3,2010 # ffffffffc02080a0 <default_pmm_manager+0xe78>
ffffffffc02048ce:	00002617          	auipc	a2,0x2
ffffffffc02048d2:	2c260613          	addi	a2,a2,706 # ffffffffc0206b90 <commands+0x450>
ffffffffc02048d6:	16300593          	li	a1,355
ffffffffc02048da:	00003517          	auipc	a0,0x3
ffffffffc02048de:	56650513          	addi	a0,a0,1382 # ffffffffc0207e40 <default_pmm_manager+0xc18>
ffffffffc02048e2:	b99fb0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc02048e6 <do_pgfault>:
 *            was a read (0) or write (1).
 *         -- The U/S flag (bit 2) indicates whether the processor was executing at user mode (1)
 *            or supervisor mode (0) at the time of the exception.
 */
int
do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
ffffffffc02048e6:	7179                	addi	sp,sp,-48
    int ret = -E_INVAL;
    //try to find a vma which include addr
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc02048e8:	85b2                	mv	a1,a2
do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
ffffffffc02048ea:	f022                	sd	s0,32(sp)
ffffffffc02048ec:	ec26                	sd	s1,24(sp)
ffffffffc02048ee:	f406                	sd	ra,40(sp)
ffffffffc02048f0:	e84a                	sd	s2,16(sp)
ffffffffc02048f2:	8432                	mv	s0,a2
ffffffffc02048f4:	84aa                	mv	s1,a0
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc02048f6:	f8eff0ef          	jal	ra,ffffffffc0204084 <find_vma>

    pgfault_num++;
ffffffffc02048fa:	000ae797          	auipc	a5,0xae
ffffffffc02048fe:	fae7a783          	lw	a5,-82(a5) # ffffffffc02b28a8 <pgfault_num>
ffffffffc0204902:	2785                	addiw	a5,a5,1
ffffffffc0204904:	000ae717          	auipc	a4,0xae
ffffffffc0204908:	faf72223          	sw	a5,-92(a4) # ffffffffc02b28a8 <pgfault_num>
    //If the addr is in the range of a mm's vma?
    if (vma == NULL || vma->vm_start > addr) {
ffffffffc020490c:	cd3d                	beqz	a0,ffffffffc020498a <do_pgfault+0xa4>
ffffffffc020490e:	651c                	ld	a5,8(a0)
ffffffffc0204910:	06f46d63          	bltu	s0,a5,ffffffffc020498a <do_pgfault+0xa4>
     *    (read  an non_existed addr && addr is readable)
     * THEN
     *    continue process
     */
    uint32_t perm = PTE_U;
    if (vma->vm_flags & VM_WRITE) {
ffffffffc0204914:	4d1c                	lw	a5,24(a0)
    uint32_t perm = PTE_U;
ffffffffc0204916:	4941                	li	s2,16
    if (vma->vm_flags & VM_WRITE) {
ffffffffc0204918:	8b89                	andi	a5,a5,2
ffffffffc020491a:	e7b1                	bnez	a5,ffffffffc0204966 <do_pgfault+0x80>
        perm |= READ_WRITE;
    }
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc020491c:	75fd                	lui	a1,0xfffff

    pte_t *ptep=NULL;
  
    // try to find a pte, if pte's PT(Page Table) isn't existed, then create a PT.
    // (notice the 3th parameter '1')
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL) {
ffffffffc020491e:	6c88                	ld	a0,24(s1)
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc0204920:	8c6d                	and	s0,s0,a1
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL) {
ffffffffc0204922:	4605                	li	a2,1
ffffffffc0204924:	85a2                	mv	a1,s0
ffffffffc0204926:	cc6fd0ef          	jal	ra,ffffffffc0201dec <get_pte>
ffffffffc020492a:	c14d                	beqz	a0,ffffffffc02049cc <do_pgfault+0xe6>
        cprintf("get_pte in do_pgfault failed\n");
        goto failed;
    }
    
    if (*ptep == 0) { // if the phy addr isn't exist, then alloc a page & map the phy addr with logical addr
ffffffffc020492c:	610c                	ld	a1,0(a0)
ffffffffc020492e:	cd95                	beqz	a1,ffffffffc020496a <do_pgfault+0x84>
        *    swap_in(mm, addr, &page) : 分配一个内存页，然后根据
        *    PTE中的swap条目的addr，找到磁盘页的地址，将磁盘页的内容读入这个内存页
        *    page_insert ： 建立一个Page的phy addr与线性addr la的映射
        *    swap_map_swappable ： 设置页面可交换
        */
        if (swap_init_ok) {
ffffffffc0204930:	000ae797          	auipc	a5,0xae
ffffffffc0204934:	f687a783          	lw	a5,-152(a5) # ffffffffc02b2898 <swap_init_ok>
ffffffffc0204938:	c3b5                	beqz	a5,ffffffffc020499c <do_pgfault+0xb6>
            //(2) According to the mm,
            //addr AND page, setup the
            //map of phy addr <--->
            //logical addr
            //(3) make the page swappable.
           int r = swap_in(mm, addr, &page);//swap_in将磁盘页的内容读入这个内存页
ffffffffc020493a:	0030                	addi	a2,sp,8
ffffffffc020493c:	85a2                	mv	a1,s0
ffffffffc020493e:	8526                	mv	a0,s1
            struct Page *page = NULL;
ffffffffc0204940:	e402                	sd	zero,8(sp)
           int r = swap_in(mm, addr, &page);//swap_in将磁盘页的内容读入这个内存页
ffffffffc0204942:	b52ff0ef          	jal	ra,ffffffffc0203c94 <swap_in>
            
            if (r != 0) {
ffffffffc0204946:	e13d                	bnez	a0,ffffffffc02049ac <do_pgfault+0xc6>
                cprintf("swap_in in do_pgfault failed\n");
                goto failed;
            }

            r = page_insert(mm->pgdir, page, addr, perm);//建立一个Page的phy addr与线性addr la的映射
ffffffffc0204948:	65a2                	ld	a1,8(sp)
ffffffffc020494a:	6c88                	ld	a0,24(s1)
ffffffffc020494c:	86ca                	mv	a3,s2
ffffffffc020494e:	8622                	mv	a2,s0
ffffffffc0204950:	b37fd0ef          	jal	ra,ffffffffc0202486 <page_insert>

            if (r != 0) {
ffffffffc0204954:	e525                	bnez	a0,ffffffffc02049bc <do_pgfault+0xd6>
                cprintf("page_insert in do_pgfault failed\n");
                goto failed;
            }

            page->pra_vaddr = addr;
ffffffffc0204956:	67a2                	ld	a5,8(sp)
ffffffffc0204958:	ff80                	sd	s0,56(a5)
        }
   }
   ret = 0;
failed:
    return ret;
}
ffffffffc020495a:	70a2                	ld	ra,40(sp)
ffffffffc020495c:	7402                	ld	s0,32(sp)
ffffffffc020495e:	64e2                	ld	s1,24(sp)
ffffffffc0204960:	6942                	ld	s2,16(sp)
ffffffffc0204962:	6145                	addi	sp,sp,48
ffffffffc0204964:	8082                	ret
        perm |= READ_WRITE;
ffffffffc0204966:	495d                	li	s2,23
ffffffffc0204968:	bf55                	j	ffffffffc020491c <do_pgfault+0x36>
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
ffffffffc020496a:	6c88                	ld	a0,24(s1)
ffffffffc020496c:	864a                	mv	a2,s2
ffffffffc020496e:	85a2                	mv	a1,s0
ffffffffc0204970:	9ddfe0ef          	jal	ra,ffffffffc020334c <pgdir_alloc_page>
ffffffffc0204974:	87aa                	mv	a5,a0
   ret = 0;
ffffffffc0204976:	4501                	li	a0,0
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
ffffffffc0204978:	f3ed                	bnez	a5,ffffffffc020495a <do_pgfault+0x74>
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
ffffffffc020497a:	00003517          	auipc	a0,0x3
ffffffffc020497e:	7e650513          	addi	a0,a0,2022 # ffffffffc0208160 <default_pmm_manager+0xf38>
ffffffffc0204982:	ffefb0ef          	jal	ra,ffffffffc0200180 <cprintf>
    ret = -E_NO_MEM;
ffffffffc0204986:	5571                	li	a0,-4
            goto failed;
ffffffffc0204988:	bfc9                	j	ffffffffc020495a <do_pgfault+0x74>
        cprintf("not valid addr %x, and  can not find it in vma\n", addr);
ffffffffc020498a:	85a2                	mv	a1,s0
ffffffffc020498c:	00003517          	auipc	a0,0x3
ffffffffc0204990:	78450513          	addi	a0,a0,1924 # ffffffffc0208110 <default_pmm_manager+0xee8>
ffffffffc0204994:	fecfb0ef          	jal	ra,ffffffffc0200180 <cprintf>
    int ret = -E_INVAL;
ffffffffc0204998:	5575                	li	a0,-3
        goto failed;
ffffffffc020499a:	b7c1                	j	ffffffffc020495a <do_pgfault+0x74>
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
ffffffffc020499c:	00004517          	auipc	a0,0x4
ffffffffc02049a0:	83450513          	addi	a0,a0,-1996 # ffffffffc02081d0 <default_pmm_manager+0xfa8>
ffffffffc02049a4:	fdcfb0ef          	jal	ra,ffffffffc0200180 <cprintf>
    ret = -E_NO_MEM;
ffffffffc02049a8:	5571                	li	a0,-4
            goto failed;
ffffffffc02049aa:	bf45                	j	ffffffffc020495a <do_pgfault+0x74>
                cprintf("swap_in in do_pgfault failed\n");
ffffffffc02049ac:	00003517          	auipc	a0,0x3
ffffffffc02049b0:	7dc50513          	addi	a0,a0,2012 # ffffffffc0208188 <default_pmm_manager+0xf60>
ffffffffc02049b4:	fccfb0ef          	jal	ra,ffffffffc0200180 <cprintf>
    ret = -E_NO_MEM;
ffffffffc02049b8:	5571                	li	a0,-4
ffffffffc02049ba:	b745                	j	ffffffffc020495a <do_pgfault+0x74>
                cprintf("page_insert in do_pgfault failed\n");
ffffffffc02049bc:	00003517          	auipc	a0,0x3
ffffffffc02049c0:	7ec50513          	addi	a0,a0,2028 # ffffffffc02081a8 <default_pmm_manager+0xf80>
ffffffffc02049c4:	fbcfb0ef          	jal	ra,ffffffffc0200180 <cprintf>
    ret = -E_NO_MEM;
ffffffffc02049c8:	5571                	li	a0,-4
ffffffffc02049ca:	bf41                	j	ffffffffc020495a <do_pgfault+0x74>
        cprintf("get_pte in do_pgfault failed\n");
ffffffffc02049cc:	00003517          	auipc	a0,0x3
ffffffffc02049d0:	77450513          	addi	a0,a0,1908 # ffffffffc0208140 <default_pmm_manager+0xf18>
ffffffffc02049d4:	facfb0ef          	jal	ra,ffffffffc0200180 <cprintf>
    ret = -E_NO_MEM;
ffffffffc02049d8:	5571                	li	a0,-4
        goto failed;
ffffffffc02049da:	b741                	j	ffffffffc020495a <do_pgfault+0x74>

ffffffffc02049dc <user_mem_check>:

bool
user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write) {
ffffffffc02049dc:	7179                	addi	sp,sp,-48
ffffffffc02049de:	f022                	sd	s0,32(sp)
ffffffffc02049e0:	f406                	sd	ra,40(sp)
ffffffffc02049e2:	ec26                	sd	s1,24(sp)
ffffffffc02049e4:	e84a                	sd	s2,16(sp)
ffffffffc02049e6:	e44e                	sd	s3,8(sp)
ffffffffc02049e8:	e052                	sd	s4,0(sp)
ffffffffc02049ea:	842e                	mv	s0,a1
    if (mm != NULL) {
ffffffffc02049ec:	c135                	beqz	a0,ffffffffc0204a50 <user_mem_check+0x74>
        if (!USER_ACCESS(addr, addr + len)) {
ffffffffc02049ee:	002007b7          	lui	a5,0x200
ffffffffc02049f2:	04f5e663          	bltu	a1,a5,ffffffffc0204a3e <user_mem_check+0x62>
ffffffffc02049f6:	00c584b3          	add	s1,a1,a2
ffffffffc02049fa:	0495f263          	bgeu	a1,s1,ffffffffc0204a3e <user_mem_check+0x62>
ffffffffc02049fe:	4785                	li	a5,1
ffffffffc0204a00:	07fe                	slli	a5,a5,0x1f
ffffffffc0204a02:	0297ee63          	bltu	a5,s1,ffffffffc0204a3e <user_mem_check+0x62>
ffffffffc0204a06:	892a                	mv	s2,a0
ffffffffc0204a08:	89b6                	mv	s3,a3
            }
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ))) {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK)) {
                if (start < vma->vm_start + PGSIZE) { //check stack start & size
ffffffffc0204a0a:	6a05                	lui	s4,0x1
ffffffffc0204a0c:	a821                	j	ffffffffc0204a24 <user_mem_check+0x48>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ))) {
ffffffffc0204a0e:	0027f693          	andi	a3,a5,2
                if (start < vma->vm_start + PGSIZE) { //check stack start & size
ffffffffc0204a12:	9752                	add	a4,a4,s4
            if (write && (vma->vm_flags & VM_STACK)) {
ffffffffc0204a14:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ))) {
ffffffffc0204a16:	c685                	beqz	a3,ffffffffc0204a3e <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK)) {
ffffffffc0204a18:	c399                	beqz	a5,ffffffffc0204a1e <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE) { //check stack start & size
ffffffffc0204a1a:	02e46263          	bltu	s0,a4,ffffffffc0204a3e <user_mem_check+0x62>
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc0204a1e:	6900                	ld	s0,16(a0)
        while (start < end) {
ffffffffc0204a20:	04947663          	bgeu	s0,s1,ffffffffc0204a6c <user_mem_check+0x90>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start) {
ffffffffc0204a24:	85a2                	mv	a1,s0
ffffffffc0204a26:	854a                	mv	a0,s2
ffffffffc0204a28:	e5cff0ef          	jal	ra,ffffffffc0204084 <find_vma>
ffffffffc0204a2c:	c909                	beqz	a0,ffffffffc0204a3e <user_mem_check+0x62>
ffffffffc0204a2e:	6518                	ld	a4,8(a0)
ffffffffc0204a30:	00e46763          	bltu	s0,a4,ffffffffc0204a3e <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ))) {
ffffffffc0204a34:	4d1c                	lw	a5,24(a0)
ffffffffc0204a36:	fc099ce3          	bnez	s3,ffffffffc0204a0e <user_mem_check+0x32>
ffffffffc0204a3a:	8b85                	andi	a5,a5,1
ffffffffc0204a3c:	f3ed                	bnez	a5,ffffffffc0204a1e <user_mem_check+0x42>
            return 0;
ffffffffc0204a3e:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
}
ffffffffc0204a40:	70a2                	ld	ra,40(sp)
ffffffffc0204a42:	7402                	ld	s0,32(sp)
ffffffffc0204a44:	64e2                	ld	s1,24(sp)
ffffffffc0204a46:	6942                	ld	s2,16(sp)
ffffffffc0204a48:	69a2                	ld	s3,8(sp)
ffffffffc0204a4a:	6a02                	ld	s4,0(sp)
ffffffffc0204a4c:	6145                	addi	sp,sp,48
ffffffffc0204a4e:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc0204a50:	c02007b7          	lui	a5,0xc0200
ffffffffc0204a54:	4501                	li	a0,0
ffffffffc0204a56:	fef5e5e3          	bltu	a1,a5,ffffffffc0204a40 <user_mem_check+0x64>
ffffffffc0204a5a:	962e                	add	a2,a2,a1
ffffffffc0204a5c:	fec5f2e3          	bgeu	a1,a2,ffffffffc0204a40 <user_mem_check+0x64>
ffffffffc0204a60:	c8000537          	lui	a0,0xc8000
ffffffffc0204a64:	0505                	addi	a0,a0,1
ffffffffc0204a66:	00a63533          	sltu	a0,a2,a0
ffffffffc0204a6a:	bfd9                	j	ffffffffc0204a40 <user_mem_check+0x64>
        return 1;
ffffffffc0204a6c:	4505                	li	a0,1
ffffffffc0204a6e:	bfc9                	j	ffffffffc0204a40 <user_mem_check+0x64>

ffffffffc0204a70 <swapfs_init>:
#include <ide.h>
#include <pmm.h>
#include <assert.h>

void
swapfs_init(void) {
ffffffffc0204a70:	1141                	addi	sp,sp,-16
    static_assert((PGSIZE % SECTSIZE) == 0);
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc0204a72:	4505                	li	a0,1
swapfs_init(void) {
ffffffffc0204a74:	e406                	sd	ra,8(sp)
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc0204a76:	b77fb0ef          	jal	ra,ffffffffc02005ec <ide_device_valid>
ffffffffc0204a7a:	cd01                	beqz	a0,ffffffffc0204a92 <swapfs_init+0x22>
        panic("swap fs isn't available.\n");
    }
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0204a7c:	4505                	li	a0,1
ffffffffc0204a7e:	b75fb0ef          	jal	ra,ffffffffc02005f2 <ide_device_size>
}
ffffffffc0204a82:	60a2                	ld	ra,8(sp)
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0204a84:	810d                	srli	a0,a0,0x3
ffffffffc0204a86:	000ae797          	auipc	a5,0xae
ffffffffc0204a8a:	e0a7b123          	sd	a0,-510(a5) # ffffffffc02b2888 <max_swap_offset>
}
ffffffffc0204a8e:	0141                	addi	sp,sp,16
ffffffffc0204a90:	8082                	ret
        panic("swap fs isn't available.\n");
ffffffffc0204a92:	00003617          	auipc	a2,0x3
ffffffffc0204a96:	76660613          	addi	a2,a2,1894 # ffffffffc02081f8 <default_pmm_manager+0xfd0>
ffffffffc0204a9a:	45b5                	li	a1,13
ffffffffc0204a9c:	00003517          	auipc	a0,0x3
ffffffffc0204aa0:	77c50513          	addi	a0,a0,1916 # ffffffffc0208218 <default_pmm_manager+0xff0>
ffffffffc0204aa4:	9d7fb0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0204aa8 <swapfs_read>:

int
swapfs_read(swap_entry_t entry, struct Page *page) {
ffffffffc0204aa8:	1141                	addi	sp,sp,-16
ffffffffc0204aaa:	e406                	sd	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204aac:	00855793          	srli	a5,a0,0x8
ffffffffc0204ab0:	cbb1                	beqz	a5,ffffffffc0204b04 <swapfs_read+0x5c>
ffffffffc0204ab2:	000ae717          	auipc	a4,0xae
ffffffffc0204ab6:	dd673703          	ld	a4,-554(a4) # ffffffffc02b2888 <max_swap_offset>
ffffffffc0204aba:	04e7f563          	bgeu	a5,a4,ffffffffc0204b04 <swapfs_read+0x5c>
    return page - pages + nbase;
ffffffffc0204abe:	000ae617          	auipc	a2,0xae
ffffffffc0204ac2:	db263603          	ld	a2,-590(a2) # ffffffffc02b2870 <pages>
ffffffffc0204ac6:	8d91                	sub	a1,a1,a2
ffffffffc0204ac8:	4065d613          	srai	a2,a1,0x6
ffffffffc0204acc:	00004717          	auipc	a4,0x4
ffffffffc0204ad0:	0a473703          	ld	a4,164(a4) # ffffffffc0208b70 <nbase>
ffffffffc0204ad4:	963a                	add	a2,a2,a4
    return KADDR(page2pa(page));
ffffffffc0204ad6:	00c61713          	slli	a4,a2,0xc
ffffffffc0204ada:	8331                	srli	a4,a4,0xc
ffffffffc0204adc:	000ae697          	auipc	a3,0xae
ffffffffc0204ae0:	d8c6b683          	ld	a3,-628(a3) # ffffffffc02b2868 <npage>
ffffffffc0204ae4:	0037959b          	slliw	a1,a5,0x3
    return page2ppn(page) << PGSHIFT;
ffffffffc0204ae8:	0632                	slli	a2,a2,0xc
    return KADDR(page2pa(page));
ffffffffc0204aea:	02d77963          	bgeu	a4,a3,ffffffffc0204b1c <swapfs_read+0x74>
}
ffffffffc0204aee:	60a2                	ld	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204af0:	000ae797          	auipc	a5,0xae
ffffffffc0204af4:	d907b783          	ld	a5,-624(a5) # ffffffffc02b2880 <va_pa_offset>
ffffffffc0204af8:	46a1                	li	a3,8
ffffffffc0204afa:	963e                	add	a2,a2,a5
ffffffffc0204afc:	4505                	li	a0,1
}
ffffffffc0204afe:	0141                	addi	sp,sp,16
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204b00:	af9fb06f          	j	ffffffffc02005f8 <ide_read_secs>
ffffffffc0204b04:	86aa                	mv	a3,a0
ffffffffc0204b06:	00003617          	auipc	a2,0x3
ffffffffc0204b0a:	72a60613          	addi	a2,a2,1834 # ffffffffc0208230 <default_pmm_manager+0x1008>
ffffffffc0204b0e:	45d1                	li	a1,20
ffffffffc0204b10:	00003517          	auipc	a0,0x3
ffffffffc0204b14:	70850513          	addi	a0,a0,1800 # ffffffffc0208218 <default_pmm_manager+0xff0>
ffffffffc0204b18:	963fb0ef          	jal	ra,ffffffffc020047a <__panic>
ffffffffc0204b1c:	86b2                	mv	a3,a2
ffffffffc0204b1e:	06900593          	li	a1,105
ffffffffc0204b22:	00002617          	auipc	a2,0x2
ffffffffc0204b26:	73e60613          	addi	a2,a2,1854 # ffffffffc0207260 <default_pmm_manager+0x38>
ffffffffc0204b2a:	00002517          	auipc	a0,0x2
ffffffffc0204b2e:	75e50513          	addi	a0,a0,1886 # ffffffffc0207288 <default_pmm_manager+0x60>
ffffffffc0204b32:	949fb0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0204b36 <swapfs_write>:

int
swapfs_write(swap_entry_t entry, struct Page *page) {
ffffffffc0204b36:	1141                	addi	sp,sp,-16
ffffffffc0204b38:	e406                	sd	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204b3a:	00855793          	srli	a5,a0,0x8
ffffffffc0204b3e:	cbb1                	beqz	a5,ffffffffc0204b92 <swapfs_write+0x5c>
ffffffffc0204b40:	000ae717          	auipc	a4,0xae
ffffffffc0204b44:	d4873703          	ld	a4,-696(a4) # ffffffffc02b2888 <max_swap_offset>
ffffffffc0204b48:	04e7f563          	bgeu	a5,a4,ffffffffc0204b92 <swapfs_write+0x5c>
    return page - pages + nbase;
ffffffffc0204b4c:	000ae617          	auipc	a2,0xae
ffffffffc0204b50:	d2463603          	ld	a2,-732(a2) # ffffffffc02b2870 <pages>
ffffffffc0204b54:	8d91                	sub	a1,a1,a2
ffffffffc0204b56:	4065d613          	srai	a2,a1,0x6
ffffffffc0204b5a:	00004717          	auipc	a4,0x4
ffffffffc0204b5e:	01673703          	ld	a4,22(a4) # ffffffffc0208b70 <nbase>
ffffffffc0204b62:	963a                	add	a2,a2,a4
    return KADDR(page2pa(page));
ffffffffc0204b64:	00c61713          	slli	a4,a2,0xc
ffffffffc0204b68:	8331                	srli	a4,a4,0xc
ffffffffc0204b6a:	000ae697          	auipc	a3,0xae
ffffffffc0204b6e:	cfe6b683          	ld	a3,-770(a3) # ffffffffc02b2868 <npage>
ffffffffc0204b72:	0037959b          	slliw	a1,a5,0x3
    return page2ppn(page) << PGSHIFT;
ffffffffc0204b76:	0632                	slli	a2,a2,0xc
    return KADDR(page2pa(page));
ffffffffc0204b78:	02d77963          	bgeu	a4,a3,ffffffffc0204baa <swapfs_write+0x74>
}
ffffffffc0204b7c:	60a2                	ld	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204b7e:	000ae797          	auipc	a5,0xae
ffffffffc0204b82:	d027b783          	ld	a5,-766(a5) # ffffffffc02b2880 <va_pa_offset>
ffffffffc0204b86:	46a1                	li	a3,8
ffffffffc0204b88:	963e                	add	a2,a2,a5
ffffffffc0204b8a:	4505                	li	a0,1
}
ffffffffc0204b8c:	0141                	addi	sp,sp,16
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204b8e:	a8ffb06f          	j	ffffffffc020061c <ide_write_secs>
ffffffffc0204b92:	86aa                	mv	a3,a0
ffffffffc0204b94:	00003617          	auipc	a2,0x3
ffffffffc0204b98:	69c60613          	addi	a2,a2,1692 # ffffffffc0208230 <default_pmm_manager+0x1008>
ffffffffc0204b9c:	45e5                	li	a1,25
ffffffffc0204b9e:	00003517          	auipc	a0,0x3
ffffffffc0204ba2:	67a50513          	addi	a0,a0,1658 # ffffffffc0208218 <default_pmm_manager+0xff0>
ffffffffc0204ba6:	8d5fb0ef          	jal	ra,ffffffffc020047a <__panic>
ffffffffc0204baa:	86b2                	mv	a3,a2
ffffffffc0204bac:	06900593          	li	a1,105
ffffffffc0204bb0:	00002617          	auipc	a2,0x2
ffffffffc0204bb4:	6b060613          	addi	a2,a2,1712 # ffffffffc0207260 <default_pmm_manager+0x38>
ffffffffc0204bb8:	00002517          	auipc	a0,0x2
ffffffffc0204bbc:	6d050513          	addi	a0,a0,1744 # ffffffffc0207288 <default_pmm_manager+0x60>
ffffffffc0204bc0:	8bbfb0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0204bc4 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0204bc4:	8526                	mv	a0,s1
	jalr s0
ffffffffc0204bc6:	9402                	jalr	s0

	jal do_exit
ffffffffc0204bc8:	642000ef          	jal	ra,ffffffffc020520a <do_exit>

ffffffffc0204bcc <alloc_proc>:
void forkrets(struct trapframe *tf);
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void) {
ffffffffc0204bcc:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0204bce:	10800513          	li	a0,264
alloc_proc(void) {
ffffffffc0204bd2:	e022                	sd	s0,0(sp)
ffffffffc0204bd4:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0204bd6:	f2dfc0ef          	jal	ra,ffffffffc0201b02 <kmalloc>
ffffffffc0204bda:	842a                	mv	s0,a0
    if (proc != NULL) {
ffffffffc0204bdc:	cd21                	beqz	a0,ffffffffc0204c34 <alloc_proc+0x68>
     /*
     * below fields(add in LAB5) in proc_struct need to be initialized  
     *       uint32_t wait_state;                        // waiting state
     *       struct proc_struct *cptr, *yptr, *optr;     // relations between processes
     */
        proc->state = PROC_UNINIT;
ffffffffc0204bde:	57fd                	li	a5,-1
ffffffffc0204be0:	1782                	slli	a5,a5,0x20
ffffffffc0204be2:	e11c                	sd	a5,0(a0)
        proc->runs = 0;
        proc->kstack = 0;
        proc->need_resched = 0;
        proc->parent = NULL;
        proc->mm = NULL;
        memset(&(proc->context), 0, sizeof(struct context));
ffffffffc0204be4:	07000613          	li	a2,112
ffffffffc0204be8:	4581                	li	a1,0
        proc->runs = 0;
ffffffffc0204bea:	00052423          	sw	zero,8(a0)
        proc->kstack = 0;
ffffffffc0204bee:	00053823          	sd	zero,16(a0)
        proc->need_resched = 0;
ffffffffc0204bf2:	00053c23          	sd	zero,24(a0)
        proc->parent = NULL;
ffffffffc0204bf6:	02053023          	sd	zero,32(a0)
        proc->mm = NULL;
ffffffffc0204bfa:	02053423          	sd	zero,40(a0)
        memset(&(proc->context), 0, sizeof(struct context));
ffffffffc0204bfe:	03050513          	addi	a0,a0,48
ffffffffc0204c02:	0ab010ef          	jal	ra,ffffffffc02064ac <memset>
        proc->tf = NULL;
        proc->cr3 = boot_cr3;
ffffffffc0204c06:	000ae797          	auipc	a5,0xae
ffffffffc0204c0a:	c527b783          	ld	a5,-942(a5) # ffffffffc02b2858 <boot_cr3>
        proc->tf = NULL;
ffffffffc0204c0e:	0a043023          	sd	zero,160(s0)
        proc->cr3 = boot_cr3;
ffffffffc0204c12:	f45c                	sd	a5,168(s0)
        proc->flags = 0;
ffffffffc0204c14:	0a042823          	sw	zero,176(s0)
        memset(proc->name, 0, PROC_NAME_LEN);
ffffffffc0204c18:	463d                	li	a2,15
ffffffffc0204c1a:	4581                	li	a1,0
ffffffffc0204c1c:	0b440513          	addi	a0,s0,180
ffffffffc0204c20:	08d010ef          	jal	ra,ffffffffc02064ac <memset>
        proc->wait_state = 0;
ffffffffc0204c24:	0e042623          	sw	zero,236(s0)
        proc->cptr = NULL;
ffffffffc0204c28:	0e043823          	sd	zero,240(s0)
        proc->optr = NULL;
ffffffffc0204c2c:	10043023          	sd	zero,256(s0)
        proc->yptr = NULL;
ffffffffc0204c30:	0e043c23          	sd	zero,248(s0)
    }
    return proc;
}
ffffffffc0204c34:	60a2                	ld	ra,8(sp)
ffffffffc0204c36:	8522                	mv	a0,s0
ffffffffc0204c38:	6402                	ld	s0,0(sp)
ffffffffc0204c3a:	0141                	addi	sp,sp,16
ffffffffc0204c3c:	8082                	ret

ffffffffc0204c3e <forkret>:
// forkret -- the first kernel entry point of a new thread/process
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void) {
    forkrets(current->tf);
ffffffffc0204c3e:	000ae797          	auipc	a5,0xae
ffffffffc0204c42:	c727b783          	ld	a5,-910(a5) # ffffffffc02b28b0 <current>
ffffffffc0204c46:	73c8                	ld	a0,160(a5)
ffffffffc0204c48:	92efc06f          	j	ffffffffc0200d76 <forkrets>

ffffffffc0204c4c <user_main>:

// user_main - kernel thread used to exec a user program
static int
user_main(void *arg) {
#ifdef TEST
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204c4c:	000ae797          	auipc	a5,0xae
ffffffffc0204c50:	c647b783          	ld	a5,-924(a5) # ffffffffc02b28b0 <current>
ffffffffc0204c54:	43cc                	lw	a1,4(a5)
user_main(void *arg) {
ffffffffc0204c56:	7139                	addi	sp,sp,-64
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204c58:	00003617          	auipc	a2,0x3
ffffffffc0204c5c:	5f860613          	addi	a2,a2,1528 # ffffffffc0208250 <default_pmm_manager+0x1028>
ffffffffc0204c60:	00003517          	auipc	a0,0x3
ffffffffc0204c64:	60050513          	addi	a0,a0,1536 # ffffffffc0208260 <default_pmm_manager+0x1038>
user_main(void *arg) {
ffffffffc0204c68:	fc06                	sd	ra,56(sp)
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204c6a:	d16fb0ef          	jal	ra,ffffffffc0200180 <cprintf>
ffffffffc0204c6e:	3fe06797          	auipc	a5,0x3fe06
ffffffffc0204c72:	d0278793          	addi	a5,a5,-766 # a970 <_binary_obj___user_forktest_out_size>
ffffffffc0204c76:	e43e                	sd	a5,8(sp)
ffffffffc0204c78:	00003517          	auipc	a0,0x3
ffffffffc0204c7c:	5d850513          	addi	a0,a0,1496 # ffffffffc0208250 <default_pmm_manager+0x1028>
ffffffffc0204c80:	00046797          	auipc	a5,0x46
ffffffffc0204c84:	ab078793          	addi	a5,a5,-1360 # ffffffffc024a730 <_binary_obj___user_forktest_out_start>
ffffffffc0204c88:	f03e                	sd	a5,32(sp)
ffffffffc0204c8a:	f42a                	sd	a0,40(sp)
    int64_t ret=0, len = strlen(name);
ffffffffc0204c8c:	e802                	sd	zero,16(sp)
ffffffffc0204c8e:	7a2010ef          	jal	ra,ffffffffc0206430 <strlen>
ffffffffc0204c92:	ec2a                	sd	a0,24(sp)
    asm volatile(
ffffffffc0204c94:	4511                	li	a0,4
ffffffffc0204c96:	55a2                	lw	a1,40(sp)
ffffffffc0204c98:	4662                	lw	a2,24(sp)
ffffffffc0204c9a:	5682                	lw	a3,32(sp)
ffffffffc0204c9c:	4722                	lw	a4,8(sp)
ffffffffc0204c9e:	48a9                	li	a7,10
ffffffffc0204ca0:	9002                	ebreak
ffffffffc0204ca2:	c82a                	sw	a0,16(sp)
    cprintf("ret = %d\n", ret);
ffffffffc0204ca4:	65c2                	ld	a1,16(sp)
ffffffffc0204ca6:	00003517          	auipc	a0,0x3
ffffffffc0204caa:	5e250513          	addi	a0,a0,1506 # ffffffffc0208288 <default_pmm_manager+0x1060>
ffffffffc0204cae:	cd2fb0ef          	jal	ra,ffffffffc0200180 <cprintf>
#else
    KERNEL_EXECVE(exit);
#endif
    panic("user_main execve failed.\n");
ffffffffc0204cb2:	00003617          	auipc	a2,0x3
ffffffffc0204cb6:	5e660613          	addi	a2,a2,1510 # ffffffffc0208298 <default_pmm_manager+0x1070>
ffffffffc0204cba:	35300593          	li	a1,851
ffffffffc0204cbe:	00003517          	auipc	a0,0x3
ffffffffc0204cc2:	5fa50513          	addi	a0,a0,1530 # ffffffffc02082b8 <default_pmm_manager+0x1090>
ffffffffc0204cc6:	fb4fb0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0204cca <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc0204cca:	6d14                	ld	a3,24(a0)
put_pgdir(struct mm_struct *mm) {
ffffffffc0204ccc:	1141                	addi	sp,sp,-16
ffffffffc0204cce:	e406                	sd	ra,8(sp)
ffffffffc0204cd0:	c02007b7          	lui	a5,0xc0200
ffffffffc0204cd4:	02f6ee63          	bltu	a3,a5,ffffffffc0204d10 <put_pgdir+0x46>
ffffffffc0204cd8:	000ae517          	auipc	a0,0xae
ffffffffc0204cdc:	ba853503          	ld	a0,-1112(a0) # ffffffffc02b2880 <va_pa_offset>
ffffffffc0204ce0:	8e89                	sub	a3,a3,a0
    if (PPN(pa) >= npage) {
ffffffffc0204ce2:	82b1                	srli	a3,a3,0xc
ffffffffc0204ce4:	000ae797          	auipc	a5,0xae
ffffffffc0204ce8:	b847b783          	ld	a5,-1148(a5) # ffffffffc02b2868 <npage>
ffffffffc0204cec:	02f6fe63          	bgeu	a3,a5,ffffffffc0204d28 <put_pgdir+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc0204cf0:	00004517          	auipc	a0,0x4
ffffffffc0204cf4:	e8053503          	ld	a0,-384(a0) # ffffffffc0208b70 <nbase>
}
ffffffffc0204cf8:	60a2                	ld	ra,8(sp)
ffffffffc0204cfa:	8e89                	sub	a3,a3,a0
ffffffffc0204cfc:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc0204cfe:	000ae517          	auipc	a0,0xae
ffffffffc0204d02:	b7253503          	ld	a0,-1166(a0) # ffffffffc02b2870 <pages>
ffffffffc0204d06:	4585                	li	a1,1
ffffffffc0204d08:	9536                	add	a0,a0,a3
}
ffffffffc0204d0a:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc0204d0c:	866fd06f          	j	ffffffffc0201d72 <free_pages>
    return pa2page(PADDR(kva));
ffffffffc0204d10:	00002617          	auipc	a2,0x2
ffffffffc0204d14:	5f860613          	addi	a2,a2,1528 # ffffffffc0207308 <default_pmm_manager+0xe0>
ffffffffc0204d18:	06e00593          	li	a1,110
ffffffffc0204d1c:	00002517          	auipc	a0,0x2
ffffffffc0204d20:	56c50513          	addi	a0,a0,1388 # ffffffffc0207288 <default_pmm_manager+0x60>
ffffffffc0204d24:	f56fb0ef          	jal	ra,ffffffffc020047a <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204d28:	00002617          	auipc	a2,0x2
ffffffffc0204d2c:	60860613          	addi	a2,a2,1544 # ffffffffc0207330 <default_pmm_manager+0x108>
ffffffffc0204d30:	06200593          	li	a1,98
ffffffffc0204d34:	00002517          	auipc	a0,0x2
ffffffffc0204d38:	55450513          	addi	a0,a0,1364 # ffffffffc0207288 <default_pmm_manager+0x60>
ffffffffc0204d3c:	f3efb0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0204d40 <proc_run>:
proc_run(struct proc_struct *proc) {
ffffffffc0204d40:	7179                	addi	sp,sp,-48
ffffffffc0204d42:	ec4a                	sd	s2,24(sp)
    if (proc != current) {
ffffffffc0204d44:	000ae917          	auipc	s2,0xae
ffffffffc0204d48:	b6c90913          	addi	s2,s2,-1172 # ffffffffc02b28b0 <current>
proc_run(struct proc_struct *proc) {
ffffffffc0204d4c:	f026                	sd	s1,32(sp)
    if (proc != current) {
ffffffffc0204d4e:	00093483          	ld	s1,0(s2)
proc_run(struct proc_struct *proc) {
ffffffffc0204d52:	f406                	sd	ra,40(sp)
ffffffffc0204d54:	e84e                	sd	s3,16(sp)
    if (proc != current) {
ffffffffc0204d56:	02a48863          	beq	s1,a0,ffffffffc0204d86 <proc_run+0x46>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0204d5a:	100027f3          	csrr	a5,sstatus
ffffffffc0204d5e:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204d60:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0204d62:	ef9d                	bnez	a5,ffffffffc0204da0 <proc_run+0x60>

#define barrier() __asm__ __volatile__ ("fence" ::: "memory")

static inline void
lcr3(unsigned long cr3) {
    write_csr(satp, 0x8000000000000000 | (cr3 >> RISCV_PGSHIFT));
ffffffffc0204d64:	755c                	ld	a5,168(a0)
ffffffffc0204d66:	577d                	li	a4,-1
ffffffffc0204d68:	177e                	slli	a4,a4,0x3f
ffffffffc0204d6a:	83b1                	srli	a5,a5,0xc
            current = proc;
ffffffffc0204d6c:	00a93023          	sd	a0,0(s2)
ffffffffc0204d70:	8fd9                	or	a5,a5,a4
ffffffffc0204d72:	18079073          	csrw	satp,a5
            switch_to(&(prev->context), &(next->context));
ffffffffc0204d76:	03050593          	addi	a1,a0,48
ffffffffc0204d7a:	03048513          	addi	a0,s1,48
ffffffffc0204d7e:	058010ef          	jal	ra,ffffffffc0205dd6 <switch_to>
    if (flag) {
ffffffffc0204d82:	00099863          	bnez	s3,ffffffffc0204d92 <proc_run+0x52>
}
ffffffffc0204d86:	70a2                	ld	ra,40(sp)
ffffffffc0204d88:	7482                	ld	s1,32(sp)
ffffffffc0204d8a:	6962                	ld	s2,24(sp)
ffffffffc0204d8c:	69c2                	ld	s3,16(sp)
ffffffffc0204d8e:	6145                	addi	sp,sp,48
ffffffffc0204d90:	8082                	ret
ffffffffc0204d92:	70a2                	ld	ra,40(sp)
ffffffffc0204d94:	7482                	ld	s1,32(sp)
ffffffffc0204d96:	6962                	ld	s2,24(sp)
ffffffffc0204d98:	69c2                	ld	s3,16(sp)
ffffffffc0204d9a:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc0204d9c:	8a5fb06f          	j	ffffffffc0200640 <intr_enable>
ffffffffc0204da0:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0204da2:	8a5fb0ef          	jal	ra,ffffffffc0200646 <intr_disable>
        return 1;
ffffffffc0204da6:	6522                	ld	a0,8(sp)
ffffffffc0204da8:	4985                	li	s3,1
ffffffffc0204daa:	bf6d                	j	ffffffffc0204d64 <proc_run+0x24>

ffffffffc0204dac <do_fork>:
do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
ffffffffc0204dac:	7119                	addi	sp,sp,-128
ffffffffc0204dae:	f0ca                	sd	s2,96(sp)
    if (nr_process >= MAX_PROCESS) {
ffffffffc0204db0:	000ae917          	auipc	s2,0xae
ffffffffc0204db4:	b1890913          	addi	s2,s2,-1256 # ffffffffc02b28c8 <nr_process>
ffffffffc0204db8:	00092703          	lw	a4,0(s2)
do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
ffffffffc0204dbc:	fc86                	sd	ra,120(sp)
ffffffffc0204dbe:	f8a2                	sd	s0,112(sp)
ffffffffc0204dc0:	f4a6                	sd	s1,104(sp)
ffffffffc0204dc2:	ecce                	sd	s3,88(sp)
ffffffffc0204dc4:	e8d2                	sd	s4,80(sp)
ffffffffc0204dc6:	e4d6                	sd	s5,72(sp)
ffffffffc0204dc8:	e0da                	sd	s6,64(sp)
ffffffffc0204dca:	fc5e                	sd	s7,56(sp)
ffffffffc0204dcc:	f862                	sd	s8,48(sp)
ffffffffc0204dce:	f466                	sd	s9,40(sp)
ffffffffc0204dd0:	f06a                	sd	s10,32(sp)
ffffffffc0204dd2:	ec6e                	sd	s11,24(sp)
    if (nr_process >= MAX_PROCESS) {
ffffffffc0204dd4:	6785                	lui	a5,0x1
ffffffffc0204dd6:	34f75063          	bge	a4,a5,ffffffffc0205116 <do_fork+0x36a>
ffffffffc0204dda:	8a2a                	mv	s4,a0
ffffffffc0204ddc:	89ae                	mv	s3,a1
ffffffffc0204dde:	8432                	mv	s0,a2
    if((proc = alloc_proc()) == NULL) {
ffffffffc0204de0:	dedff0ef          	jal	ra,ffffffffc0204bcc <alloc_proc>
ffffffffc0204de4:	84aa                	mv	s1,a0
ffffffffc0204de6:	30050963          	beqz	a0,ffffffffc02050f8 <do_fork+0x34c>
    proc->parent = current;
ffffffffc0204dea:	000aec17          	auipc	s8,0xae
ffffffffc0204dee:	ac6c0c13          	addi	s8,s8,-1338 # ffffffffc02b28b0 <current>
ffffffffc0204df2:	000c3783          	ld	a5,0(s8)
    assert(current->wait_state == 0);
ffffffffc0204df6:	0ec7a703          	lw	a4,236(a5) # 10ec <_binary_obj___user_faultread_out_size-0x8acc>
    proc->parent = current;
ffffffffc0204dfa:	f11c                	sd	a5,32(a0)
    assert(current->wait_state == 0);
ffffffffc0204dfc:	32071263          	bnez	a4,ffffffffc0205120 <do_fork+0x374>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0204e00:	4509                	li	a0,2
ffffffffc0204e02:	edffc0ef          	jal	ra,ffffffffc0201ce0 <alloc_pages>
    if (page != NULL) {
ffffffffc0204e06:	2e050663          	beqz	a0,ffffffffc02050f2 <do_fork+0x346>
    return page - pages + nbase;
ffffffffc0204e0a:	000aea97          	auipc	s5,0xae
ffffffffc0204e0e:	a66a8a93          	addi	s5,s5,-1434 # ffffffffc02b2870 <pages>
ffffffffc0204e12:	000ab683          	ld	a3,0(s5)
ffffffffc0204e16:	00004b17          	auipc	s6,0x4
ffffffffc0204e1a:	d5ab0b13          	addi	s6,s6,-678 # ffffffffc0208b70 <nbase>
ffffffffc0204e1e:	000b3783          	ld	a5,0(s6)
ffffffffc0204e22:	40d506b3          	sub	a3,a0,a3
    return KADDR(page2pa(page));
ffffffffc0204e26:	000aeb97          	auipc	s7,0xae
ffffffffc0204e2a:	a42b8b93          	addi	s7,s7,-1470 # ffffffffc02b2868 <npage>
    return page - pages + nbase;
ffffffffc0204e2e:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0204e30:	5dfd                	li	s11,-1
ffffffffc0204e32:	000bb703          	ld	a4,0(s7)
    return page - pages + nbase;
ffffffffc0204e36:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204e38:	00cddd93          	srli	s11,s11,0xc
ffffffffc0204e3c:	01b6f633          	and	a2,a3,s11
    return page2ppn(page) << PGSHIFT;
ffffffffc0204e40:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204e42:	2ee67f63          	bgeu	a2,a4,ffffffffc0205140 <do_fork+0x394>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc0204e46:	000c3603          	ld	a2,0(s8)
ffffffffc0204e4a:	000aec17          	auipc	s8,0xae
ffffffffc0204e4e:	a36c0c13          	addi	s8,s8,-1482 # ffffffffc02b2880 <va_pa_offset>
ffffffffc0204e52:	000c3703          	ld	a4,0(s8)
ffffffffc0204e56:	02863d03          	ld	s10,40(a2)
ffffffffc0204e5a:	e43e                	sd	a5,8(sp)
ffffffffc0204e5c:	96ba                	add	a3,a3,a4
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc0204e5e:	e894                	sd	a3,16(s1)
    if (oldmm == NULL) {
ffffffffc0204e60:	020d0863          	beqz	s10,ffffffffc0204e90 <do_fork+0xe4>
    if (clone_flags & CLONE_VM) {
ffffffffc0204e64:	100a7a13          	andi	s4,s4,256
ffffffffc0204e68:	1c0a0663          	beqz	s4,ffffffffc0205034 <do_fork+0x288>
}

static inline int
mm_count_inc(struct mm_struct *mm) {
    mm->mm_count += 1;
ffffffffc0204e6c:	030d2703          	lw	a4,48(s10)
    proc->cr3 = PADDR(mm->pgdir);
ffffffffc0204e70:	018d3783          	ld	a5,24(s10)
ffffffffc0204e74:	c02006b7          	lui	a3,0xc0200
ffffffffc0204e78:	2705                	addiw	a4,a4,1
ffffffffc0204e7a:	02ed2823          	sw	a4,48(s10)
    proc->mm = mm;
ffffffffc0204e7e:	03a4b423          	sd	s10,40(s1)
    proc->cr3 = PADDR(mm->pgdir);
ffffffffc0204e82:	2ed7e763          	bltu	a5,a3,ffffffffc0205170 <do_fork+0x3c4>
ffffffffc0204e86:	000c3703          	ld	a4,0(s8)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0204e8a:	6894                	ld	a3,16(s1)
    proc->cr3 = PADDR(mm->pgdir);
ffffffffc0204e8c:	8f99                	sub	a5,a5,a4
ffffffffc0204e8e:	f4dc                	sd	a5,168(s1)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0204e90:	6709                	lui	a4,0x2
ffffffffc0204e92:	ee070713          	addi	a4,a4,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7cd8>
ffffffffc0204e96:	9736                	add	a4,a4,a3
    *(proc->tf) = *tf;
ffffffffc0204e98:	8622                	mv	a2,s0
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0204e9a:	f0d8                	sd	a4,160(s1)
    *(proc->tf) = *tf;
ffffffffc0204e9c:	87ba                	mv	a5,a4
ffffffffc0204e9e:	12040313          	addi	t1,s0,288
ffffffffc0204ea2:	00063883          	ld	a7,0(a2)
ffffffffc0204ea6:	00863803          	ld	a6,8(a2)
ffffffffc0204eaa:	6a08                	ld	a0,16(a2)
ffffffffc0204eac:	6e0c                	ld	a1,24(a2)
ffffffffc0204eae:	0117b023          	sd	a7,0(a5)
ffffffffc0204eb2:	0107b423          	sd	a6,8(a5)
ffffffffc0204eb6:	eb88                	sd	a0,16(a5)
ffffffffc0204eb8:	ef8c                	sd	a1,24(a5)
ffffffffc0204eba:	02060613          	addi	a2,a2,32
ffffffffc0204ebe:	02078793          	addi	a5,a5,32
ffffffffc0204ec2:	fe6610e3          	bne	a2,t1,ffffffffc0204ea2 <do_fork+0xf6>
    proc->tf->gpr.a0 = 0;
ffffffffc0204ec6:	04073823          	sd	zero,80(a4)
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf - 4 : esp;
ffffffffc0204eca:	12098f63          	beqz	s3,ffffffffc0205008 <do_fork+0x25c>
ffffffffc0204ece:	01373823          	sd	s3,16(a4)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0204ed2:	00000797          	auipc	a5,0x0
ffffffffc0204ed6:	d6c78793          	addi	a5,a5,-660 # ffffffffc0204c3e <forkret>
ffffffffc0204eda:	f89c                	sd	a5,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0204edc:	fc98                	sd	a4,56(s1)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0204ede:	100027f3          	csrr	a5,sstatus
ffffffffc0204ee2:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204ee4:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0204ee6:	14079363          	bnez	a5,ffffffffc020502c <do_fork+0x280>
    if (++ last_pid >= MAX_PID) {
ffffffffc0204eea:	000a2817          	auipc	a6,0xa2
ffffffffc0204eee:	47e80813          	addi	a6,a6,1150 # ffffffffc02a7368 <last_pid.1>
ffffffffc0204ef2:	00082783          	lw	a5,0(a6)
ffffffffc0204ef6:	6709                	lui	a4,0x2
ffffffffc0204ef8:	0017851b          	addiw	a0,a5,1
ffffffffc0204efc:	00a82023          	sw	a0,0(a6)
ffffffffc0204f00:	08e55d63          	bge	a0,a4,ffffffffc0204f9a <do_fork+0x1ee>
    if (last_pid >= next_safe) {
ffffffffc0204f04:	000a2317          	auipc	t1,0xa2
ffffffffc0204f08:	46830313          	addi	t1,t1,1128 # ffffffffc02a736c <next_safe.0>
ffffffffc0204f0c:	00032783          	lw	a5,0(t1)
ffffffffc0204f10:	000ae417          	auipc	s0,0xae
ffffffffc0204f14:	91840413          	addi	s0,s0,-1768 # ffffffffc02b2828 <proc_list>
ffffffffc0204f18:	08f55963          	bge	a0,a5,ffffffffc0204faa <do_fork+0x1fe>
        proc->pid = get_pid();
ffffffffc0204f1c:	c0c8                	sw	a0,4(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0204f1e:	45a9                	li	a1,10
ffffffffc0204f20:	2501                	sext.w	a0,a0
ffffffffc0204f22:	10a010ef          	jal	ra,ffffffffc020602c <hash32>
ffffffffc0204f26:	02051793          	slli	a5,a0,0x20
ffffffffc0204f2a:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204f2e:	000aa797          	auipc	a5,0xaa
ffffffffc0204f32:	8fa78793          	addi	a5,a5,-1798 # ffffffffc02ae828 <hash_list>
ffffffffc0204f36:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc0204f38:	650c                	ld	a1,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL) {
ffffffffc0204f3a:	7094                	ld	a3,32(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0204f3c:	0d848793          	addi	a5,s1,216
    prev->next = next->prev = elm;
ffffffffc0204f40:	e19c                	sd	a5,0(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0204f42:	6410                	ld	a2,8(s0)
    prev->next = next->prev = elm;
ffffffffc0204f44:	e51c                	sd	a5,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL) {
ffffffffc0204f46:	7af8                	ld	a4,240(a3)
    list_add(&proc_list, &(proc->list_link));
ffffffffc0204f48:	0c848793          	addi	a5,s1,200
    elm->next = next;
ffffffffc0204f4c:	f0ec                	sd	a1,224(s1)
    elm->prev = prev;
ffffffffc0204f4e:	ece8                	sd	a0,216(s1)
    prev->next = next->prev = elm;
ffffffffc0204f50:	e21c                	sd	a5,0(a2)
ffffffffc0204f52:	e41c                	sd	a5,8(s0)
    elm->next = next;
ffffffffc0204f54:	e8f0                	sd	a2,208(s1)
    elm->prev = prev;
ffffffffc0204f56:	e4e0                	sd	s0,200(s1)
    proc->yptr = NULL;
ffffffffc0204f58:	0e04bc23          	sd	zero,248(s1)
    if ((proc->optr = proc->parent->cptr) != NULL) {
ffffffffc0204f5c:	10e4b023          	sd	a4,256(s1)
ffffffffc0204f60:	c311                	beqz	a4,ffffffffc0204f64 <do_fork+0x1b8>
        proc->optr->yptr = proc;
ffffffffc0204f62:	ff64                	sd	s1,248(a4)
    nr_process ++;
ffffffffc0204f64:	00092783          	lw	a5,0(s2)
    proc->parent->cptr = proc;
ffffffffc0204f68:	fae4                	sd	s1,240(a3)
    nr_process ++;
ffffffffc0204f6a:	2785                	addiw	a5,a5,1
ffffffffc0204f6c:	00f92023          	sw	a5,0(s2)
    if (flag) {
ffffffffc0204f70:	18099663          	bnez	s3,ffffffffc02050fc <do_fork+0x350>
    wakeup_proc(proc);
ffffffffc0204f74:	8526                	mv	a0,s1
ffffffffc0204f76:	6cb000ef          	jal	ra,ffffffffc0205e40 <wakeup_proc>
    ret = proc->pid;
ffffffffc0204f7a:	40c8                	lw	a0,4(s1)
}
ffffffffc0204f7c:	70e6                	ld	ra,120(sp)
ffffffffc0204f7e:	7446                	ld	s0,112(sp)
ffffffffc0204f80:	74a6                	ld	s1,104(sp)
ffffffffc0204f82:	7906                	ld	s2,96(sp)
ffffffffc0204f84:	69e6                	ld	s3,88(sp)
ffffffffc0204f86:	6a46                	ld	s4,80(sp)
ffffffffc0204f88:	6aa6                	ld	s5,72(sp)
ffffffffc0204f8a:	6b06                	ld	s6,64(sp)
ffffffffc0204f8c:	7be2                	ld	s7,56(sp)
ffffffffc0204f8e:	7c42                	ld	s8,48(sp)
ffffffffc0204f90:	7ca2                	ld	s9,40(sp)
ffffffffc0204f92:	7d02                	ld	s10,32(sp)
ffffffffc0204f94:	6de2                	ld	s11,24(sp)
ffffffffc0204f96:	6109                	addi	sp,sp,128
ffffffffc0204f98:	8082                	ret
        last_pid = 1;
ffffffffc0204f9a:	4785                	li	a5,1
ffffffffc0204f9c:	00f82023          	sw	a5,0(a6)
        goto inside;
ffffffffc0204fa0:	4505                	li	a0,1
ffffffffc0204fa2:	000a2317          	auipc	t1,0xa2
ffffffffc0204fa6:	3ca30313          	addi	t1,t1,970 # ffffffffc02a736c <next_safe.0>
    return listelm->next;
ffffffffc0204faa:	000ae417          	auipc	s0,0xae
ffffffffc0204fae:	87e40413          	addi	s0,s0,-1922 # ffffffffc02b2828 <proc_list>
ffffffffc0204fb2:	00843e03          	ld	t3,8(s0)
        next_safe = MAX_PID;
ffffffffc0204fb6:	6789                	lui	a5,0x2
ffffffffc0204fb8:	00f32023          	sw	a5,0(t1)
ffffffffc0204fbc:	86aa                	mv	a3,a0
ffffffffc0204fbe:	4581                	li	a1,0
        while ((le = list_next(le)) != list) {
ffffffffc0204fc0:	6e89                	lui	t4,0x2
ffffffffc0204fc2:	148e0563          	beq	t3,s0,ffffffffc020510c <do_fork+0x360>
ffffffffc0204fc6:	88ae                	mv	a7,a1
ffffffffc0204fc8:	87f2                	mv	a5,t3
ffffffffc0204fca:	6609                	lui	a2,0x2
ffffffffc0204fcc:	a811                	j	ffffffffc0204fe0 <do_fork+0x234>
            else if (proc->pid > last_pid && next_safe > proc->pid) {
ffffffffc0204fce:	00e6d663          	bge	a3,a4,ffffffffc0204fda <do_fork+0x22e>
ffffffffc0204fd2:	00c75463          	bge	a4,a2,ffffffffc0204fda <do_fork+0x22e>
ffffffffc0204fd6:	863a                	mv	a2,a4
ffffffffc0204fd8:	4885                	li	a7,1
ffffffffc0204fda:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list) {
ffffffffc0204fdc:	00878d63          	beq	a5,s0,ffffffffc0204ff6 <do_fork+0x24a>
            if (proc->pid == last_pid) {
ffffffffc0204fe0:	f3c7a703          	lw	a4,-196(a5) # 1f3c <_binary_obj___user_faultread_out_size-0x7c7c>
ffffffffc0204fe4:	fed715e3          	bne	a4,a3,ffffffffc0204fce <do_fork+0x222>
                if (++ last_pid >= next_safe) {
ffffffffc0204fe8:	2685                	addiw	a3,a3,1
ffffffffc0204fea:	10c6dc63          	bge	a3,a2,ffffffffc0205102 <do_fork+0x356>
ffffffffc0204fee:	679c                	ld	a5,8(a5)
ffffffffc0204ff0:	4585                	li	a1,1
        while ((le = list_next(le)) != list) {
ffffffffc0204ff2:	fe8797e3          	bne	a5,s0,ffffffffc0204fe0 <do_fork+0x234>
ffffffffc0204ff6:	c581                	beqz	a1,ffffffffc0204ffe <do_fork+0x252>
ffffffffc0204ff8:	00d82023          	sw	a3,0(a6)
ffffffffc0204ffc:	8536                	mv	a0,a3
ffffffffc0204ffe:	f0088fe3          	beqz	a7,ffffffffc0204f1c <do_fork+0x170>
ffffffffc0205002:	00c32023          	sw	a2,0(t1)
ffffffffc0205006:	bf19                	j	ffffffffc0204f1c <do_fork+0x170>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf - 4 : esp;
ffffffffc0205008:	6989                	lui	s3,0x2
ffffffffc020500a:	edc98993          	addi	s3,s3,-292 # 1edc <_binary_obj___user_faultread_out_size-0x7cdc>
ffffffffc020500e:	99b6                	add	s3,s3,a3
ffffffffc0205010:	01373823          	sd	s3,16(a4) # 2010 <_binary_obj___user_faultread_out_size-0x7ba8>
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0205014:	00000797          	auipc	a5,0x0
ffffffffc0205018:	c2a78793          	addi	a5,a5,-982 # ffffffffc0204c3e <forkret>
ffffffffc020501c:	f89c                	sd	a5,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc020501e:	fc98                	sd	a4,56(s1)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205020:	100027f3          	csrr	a5,sstatus
ffffffffc0205024:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0205026:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205028:	ec0781e3          	beqz	a5,ffffffffc0204eea <do_fork+0x13e>
        intr_disable();
ffffffffc020502c:	e1afb0ef          	jal	ra,ffffffffc0200646 <intr_disable>
        return 1;
ffffffffc0205030:	4985                	li	s3,1
ffffffffc0205032:	bd65                	j	ffffffffc0204eea <do_fork+0x13e>
    if ((mm = mm_create()) == NULL) {
ffffffffc0205034:	fdbfe0ef          	jal	ra,ffffffffc020400e <mm_create>
ffffffffc0205038:	8caa                	mv	s9,a0
ffffffffc020503a:	c541                	beqz	a0,ffffffffc02050c2 <do_fork+0x316>
    if ((page = alloc_page()) == NULL) {
ffffffffc020503c:	4505                	li	a0,1
ffffffffc020503e:	ca3fc0ef          	jal	ra,ffffffffc0201ce0 <alloc_pages>
ffffffffc0205042:	cd2d                	beqz	a0,ffffffffc02050bc <do_fork+0x310>
    return page - pages + nbase;
ffffffffc0205044:	000ab683          	ld	a3,0(s5)
ffffffffc0205048:	67a2                	ld	a5,8(sp)
    return KADDR(page2pa(page));
ffffffffc020504a:	000bb703          	ld	a4,0(s7)
    return page - pages + nbase;
ffffffffc020504e:	40d506b3          	sub	a3,a0,a3
ffffffffc0205052:	8699                	srai	a3,a3,0x6
ffffffffc0205054:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0205056:	01b6fdb3          	and	s11,a3,s11
    return page2ppn(page) << PGSHIFT;
ffffffffc020505a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020505c:	0eedf263          	bgeu	s11,a4,ffffffffc0205140 <do_fork+0x394>
ffffffffc0205060:	000c3a03          	ld	s4,0(s8)
    memcpy(pgdir, boot_pgdir, PGSIZE);
ffffffffc0205064:	6605                	lui	a2,0x1
ffffffffc0205066:	000ad597          	auipc	a1,0xad
ffffffffc020506a:	7fa5b583          	ld	a1,2042(a1) # ffffffffc02b2860 <boot_pgdir>
ffffffffc020506e:	9a36                	add	s4,s4,a3
ffffffffc0205070:	8552                	mv	a0,s4
ffffffffc0205072:	44c010ef          	jal	ra,ffffffffc02064be <memcpy>
}

static inline void
lock_mm(struct mm_struct *mm) {
    if (mm != NULL) {
        lock(&(mm->mm_lock));
ffffffffc0205076:	038d0d93          	addi	s11,s10,56
    mm->pgdir = pgdir;
ffffffffc020507a:	014cbc23          	sd	s4,24(s9)
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020507e:	4785                	li	a5,1
ffffffffc0205080:	40fdb7af          	amoor.d	a5,a5,(s11)
    return !test_and_set_bit(0, lock);
}

static inline void
lock(lock_t *lock) {
    while (!try_lock(lock)) {
ffffffffc0205084:	8b85                	andi	a5,a5,1
ffffffffc0205086:	4a05                	li	s4,1
ffffffffc0205088:	c799                	beqz	a5,ffffffffc0205096 <do_fork+0x2ea>
        schedule();
ffffffffc020508a:	637000ef          	jal	ra,ffffffffc0205ec0 <schedule>
ffffffffc020508e:	414db7af          	amoor.d	a5,s4,(s11)
    while (!try_lock(lock)) {
ffffffffc0205092:	8b85                	andi	a5,a5,1
ffffffffc0205094:	fbfd                	bnez	a5,ffffffffc020508a <do_fork+0x2de>
        ret = dup_mmap(mm, oldmm);
ffffffffc0205096:	85ea                	mv	a1,s10
ffffffffc0205098:	8566                	mv	a0,s9
ffffffffc020509a:	9fcff0ef          	jal	ra,ffffffffc0204296 <dup_mmap>
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020509e:	57f9                	li	a5,-2
ffffffffc02050a0:	60fdb7af          	amoand.d	a5,a5,(s11)
ffffffffc02050a4:	8b85                	andi	a5,a5,1
    }
}

static inline void
unlock(lock_t *lock) {
    if (!test_and_clear_bit(0, lock)) {
ffffffffc02050a6:	0e078e63          	beqz	a5,ffffffffc02051a2 <do_fork+0x3f6>
good_mm:
ffffffffc02050aa:	8d66                	mv	s10,s9
    if (ret != 0) {
ffffffffc02050ac:	dc0500e3          	beqz	a0,ffffffffc0204e6c <do_fork+0xc0>
    exit_mmap(mm);
ffffffffc02050b0:	8566                	mv	a0,s9
ffffffffc02050b2:	a7eff0ef          	jal	ra,ffffffffc0204330 <exit_mmap>
    put_pgdir(mm);
ffffffffc02050b6:	8566                	mv	a0,s9
ffffffffc02050b8:	c13ff0ef          	jal	ra,ffffffffc0204cca <put_pgdir>
    mm_destroy(mm);
ffffffffc02050bc:	8566                	mv	a0,s9
ffffffffc02050be:	8d6ff0ef          	jal	ra,ffffffffc0204194 <mm_destroy>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc02050c2:	6894                	ld	a3,16(s1)
    return pa2page(PADDR(kva));
ffffffffc02050c4:	c02007b7          	lui	a5,0xc0200
ffffffffc02050c8:	0cf6e163          	bltu	a3,a5,ffffffffc020518a <do_fork+0x3de>
ffffffffc02050cc:	000c3783          	ld	a5,0(s8)
    if (PPN(pa) >= npage) {
ffffffffc02050d0:	000bb703          	ld	a4,0(s7)
    return pa2page(PADDR(kva));
ffffffffc02050d4:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage) {
ffffffffc02050d8:	83b1                	srli	a5,a5,0xc
ffffffffc02050da:	06e7ff63          	bgeu	a5,a4,ffffffffc0205158 <do_fork+0x3ac>
    return &pages[PPN(pa) - nbase];
ffffffffc02050de:	000b3703          	ld	a4,0(s6)
ffffffffc02050e2:	000ab503          	ld	a0,0(s5)
ffffffffc02050e6:	4589                	li	a1,2
ffffffffc02050e8:	8f99                	sub	a5,a5,a4
ffffffffc02050ea:	079a                	slli	a5,a5,0x6
ffffffffc02050ec:	953e                	add	a0,a0,a5
ffffffffc02050ee:	c85fc0ef          	jal	ra,ffffffffc0201d72 <free_pages>
    kfree(proc);
ffffffffc02050f2:	8526                	mv	a0,s1
ffffffffc02050f4:	abffc0ef          	jal	ra,ffffffffc0201bb2 <kfree>
    ret = -E_NO_MEM;
ffffffffc02050f8:	5571                	li	a0,-4
    return ret;
ffffffffc02050fa:	b549                	j	ffffffffc0204f7c <do_fork+0x1d0>
        intr_enable();
ffffffffc02050fc:	d44fb0ef          	jal	ra,ffffffffc0200640 <intr_enable>
ffffffffc0205100:	bd95                	j	ffffffffc0204f74 <do_fork+0x1c8>
                    if (last_pid >= MAX_PID) {
ffffffffc0205102:	01d6c363          	blt	a3,t4,ffffffffc0205108 <do_fork+0x35c>
                        last_pid = 1;
ffffffffc0205106:	4685                	li	a3,1
                    goto repeat;
ffffffffc0205108:	4585                	li	a1,1
ffffffffc020510a:	bd65                	j	ffffffffc0204fc2 <do_fork+0x216>
ffffffffc020510c:	c599                	beqz	a1,ffffffffc020511a <do_fork+0x36e>
ffffffffc020510e:	00d82023          	sw	a3,0(a6)
    return last_pid;
ffffffffc0205112:	8536                	mv	a0,a3
ffffffffc0205114:	b521                	j	ffffffffc0204f1c <do_fork+0x170>
    int ret = -E_NO_FREE_PROC;
ffffffffc0205116:	556d                	li	a0,-5
ffffffffc0205118:	b595                	j	ffffffffc0204f7c <do_fork+0x1d0>
    return last_pid;
ffffffffc020511a:	00082503          	lw	a0,0(a6)
ffffffffc020511e:	bbfd                	j	ffffffffc0204f1c <do_fork+0x170>
    assert(current->wait_state == 0);
ffffffffc0205120:	00003697          	auipc	a3,0x3
ffffffffc0205124:	1b068693          	addi	a3,a3,432 # ffffffffc02082d0 <default_pmm_manager+0x10a8>
ffffffffc0205128:	00002617          	auipc	a2,0x2
ffffffffc020512c:	a6860613          	addi	a2,a2,-1432 # ffffffffc0206b90 <commands+0x450>
ffffffffc0205130:	1b500593          	li	a1,437
ffffffffc0205134:	00003517          	auipc	a0,0x3
ffffffffc0205138:	18450513          	addi	a0,a0,388 # ffffffffc02082b8 <default_pmm_manager+0x1090>
ffffffffc020513c:	b3efb0ef          	jal	ra,ffffffffc020047a <__panic>
    return KADDR(page2pa(page));
ffffffffc0205140:	00002617          	auipc	a2,0x2
ffffffffc0205144:	12060613          	addi	a2,a2,288 # ffffffffc0207260 <default_pmm_manager+0x38>
ffffffffc0205148:	06900593          	li	a1,105
ffffffffc020514c:	00002517          	auipc	a0,0x2
ffffffffc0205150:	13c50513          	addi	a0,a0,316 # ffffffffc0207288 <default_pmm_manager+0x60>
ffffffffc0205154:	b26fb0ef          	jal	ra,ffffffffc020047a <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0205158:	00002617          	auipc	a2,0x2
ffffffffc020515c:	1d860613          	addi	a2,a2,472 # ffffffffc0207330 <default_pmm_manager+0x108>
ffffffffc0205160:	06200593          	li	a1,98
ffffffffc0205164:	00002517          	auipc	a0,0x2
ffffffffc0205168:	12450513          	addi	a0,a0,292 # ffffffffc0207288 <default_pmm_manager+0x60>
ffffffffc020516c:	b0efb0ef          	jal	ra,ffffffffc020047a <__panic>
    proc->cr3 = PADDR(mm->pgdir);
ffffffffc0205170:	86be                	mv	a3,a5
ffffffffc0205172:	00002617          	auipc	a2,0x2
ffffffffc0205176:	19660613          	addi	a2,a2,406 # ffffffffc0207308 <default_pmm_manager+0xe0>
ffffffffc020517a:	16700593          	li	a1,359
ffffffffc020517e:	00003517          	auipc	a0,0x3
ffffffffc0205182:	13a50513          	addi	a0,a0,314 # ffffffffc02082b8 <default_pmm_manager+0x1090>
ffffffffc0205186:	af4fb0ef          	jal	ra,ffffffffc020047a <__panic>
    return pa2page(PADDR(kva));
ffffffffc020518a:	00002617          	auipc	a2,0x2
ffffffffc020518e:	17e60613          	addi	a2,a2,382 # ffffffffc0207308 <default_pmm_manager+0xe0>
ffffffffc0205192:	06e00593          	li	a1,110
ffffffffc0205196:	00002517          	auipc	a0,0x2
ffffffffc020519a:	0f250513          	addi	a0,a0,242 # ffffffffc0207288 <default_pmm_manager+0x60>
ffffffffc020519e:	adcfb0ef          	jal	ra,ffffffffc020047a <__panic>
        panic("Unlock failed.\n");
ffffffffc02051a2:	00003617          	auipc	a2,0x3
ffffffffc02051a6:	14e60613          	addi	a2,a2,334 # ffffffffc02082f0 <default_pmm_manager+0x10c8>
ffffffffc02051aa:	03100593          	li	a1,49
ffffffffc02051ae:	00003517          	auipc	a0,0x3
ffffffffc02051b2:	15250513          	addi	a0,a0,338 # ffffffffc0208300 <default_pmm_manager+0x10d8>
ffffffffc02051b6:	ac4fb0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc02051ba <kernel_thread>:
kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags) {
ffffffffc02051ba:	7129                	addi	sp,sp,-320
ffffffffc02051bc:	fa22                	sd	s0,304(sp)
ffffffffc02051be:	f626                	sd	s1,296(sp)
ffffffffc02051c0:	f24a                	sd	s2,288(sp)
ffffffffc02051c2:	84ae                	mv	s1,a1
ffffffffc02051c4:	892a                	mv	s2,a0
ffffffffc02051c6:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02051c8:	4581                	li	a1,0
ffffffffc02051ca:	12000613          	li	a2,288
ffffffffc02051ce:	850a                	mv	a0,sp
kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags) {
ffffffffc02051d0:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02051d2:	2da010ef          	jal	ra,ffffffffc02064ac <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc02051d6:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc02051d8:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc02051da:	100027f3          	csrr	a5,sstatus
ffffffffc02051de:	edd7f793          	andi	a5,a5,-291
ffffffffc02051e2:	1207e793          	ori	a5,a5,288
ffffffffc02051e6:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02051e8:	860a                	mv	a2,sp
ffffffffc02051ea:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02051ee:	00000797          	auipc	a5,0x0
ffffffffc02051f2:	9d678793          	addi	a5,a5,-1578 # ffffffffc0204bc4 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02051f6:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02051f8:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02051fa:	bb3ff0ef          	jal	ra,ffffffffc0204dac <do_fork>
}
ffffffffc02051fe:	70f2                	ld	ra,312(sp)
ffffffffc0205200:	7452                	ld	s0,304(sp)
ffffffffc0205202:	74b2                	ld	s1,296(sp)
ffffffffc0205204:	7912                	ld	s2,288(sp)
ffffffffc0205206:	6131                	addi	sp,sp,320
ffffffffc0205208:	8082                	ret

ffffffffc020520a <do_exit>:
do_exit(int error_code) {
ffffffffc020520a:	7179                	addi	sp,sp,-48
ffffffffc020520c:	f022                	sd	s0,32(sp)
    if (current == idleproc) {
ffffffffc020520e:	000ad417          	auipc	s0,0xad
ffffffffc0205212:	6a240413          	addi	s0,s0,1698 # ffffffffc02b28b0 <current>
ffffffffc0205216:	601c                	ld	a5,0(s0)
do_exit(int error_code) {
ffffffffc0205218:	f406                	sd	ra,40(sp)
ffffffffc020521a:	ec26                	sd	s1,24(sp)
ffffffffc020521c:	e84a                	sd	s2,16(sp)
ffffffffc020521e:	e44e                	sd	s3,8(sp)
ffffffffc0205220:	e052                	sd	s4,0(sp)
    if (current == idleproc) {
ffffffffc0205222:	000ad717          	auipc	a4,0xad
ffffffffc0205226:	69673703          	ld	a4,1686(a4) # ffffffffc02b28b8 <idleproc>
ffffffffc020522a:	0ce78c63          	beq	a5,a4,ffffffffc0205302 <do_exit+0xf8>
    if (current == initproc) {
ffffffffc020522e:	000ad497          	auipc	s1,0xad
ffffffffc0205232:	69248493          	addi	s1,s1,1682 # ffffffffc02b28c0 <initproc>
ffffffffc0205236:	6098                	ld	a4,0(s1)
ffffffffc0205238:	0ee78b63          	beq	a5,a4,ffffffffc020532e <do_exit+0x124>
    struct mm_struct *mm = current->mm;
ffffffffc020523c:	0287b983          	ld	s3,40(a5)
ffffffffc0205240:	892a                	mv	s2,a0
    if (mm != NULL) {
ffffffffc0205242:	02098663          	beqz	s3,ffffffffc020526e <do_exit+0x64>
ffffffffc0205246:	000ad797          	auipc	a5,0xad
ffffffffc020524a:	6127b783          	ld	a5,1554(a5) # ffffffffc02b2858 <boot_cr3>
ffffffffc020524e:	577d                	li	a4,-1
ffffffffc0205250:	177e                	slli	a4,a4,0x3f
ffffffffc0205252:	83b1                	srli	a5,a5,0xc
ffffffffc0205254:	8fd9                	or	a5,a5,a4
ffffffffc0205256:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc020525a:	0309a783          	lw	a5,48(s3)
ffffffffc020525e:	fff7871b          	addiw	a4,a5,-1
ffffffffc0205262:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0) {
ffffffffc0205266:	cb55                	beqz	a4,ffffffffc020531a <do_exit+0x110>
        current->mm = NULL;
ffffffffc0205268:	601c                	ld	a5,0(s0)
ffffffffc020526a:	0207b423          	sd	zero,40(a5)
    current->state = PROC_ZOMBIE;
ffffffffc020526e:	601c                	ld	a5,0(s0)
ffffffffc0205270:	470d                	li	a4,3
ffffffffc0205272:	c398                	sw	a4,0(a5)
    current->exit_code = error_code;
ffffffffc0205274:	0f27a423          	sw	s2,232(a5)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205278:	100027f3          	csrr	a5,sstatus
ffffffffc020527c:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020527e:	4a01                	li	s4,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205280:	e3f9                	bnez	a5,ffffffffc0205346 <do_exit+0x13c>
        proc = current->parent;
ffffffffc0205282:	6018                	ld	a4,0(s0)
        if (proc->wait_state == WT_CHILD) {
ffffffffc0205284:	800007b7          	lui	a5,0x80000
ffffffffc0205288:	0785                	addi	a5,a5,1
        proc = current->parent;
ffffffffc020528a:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD) {
ffffffffc020528c:	0ec52703          	lw	a4,236(a0)
ffffffffc0205290:	0af70f63          	beq	a4,a5,ffffffffc020534e <do_exit+0x144>
        while (current->cptr != NULL) {
ffffffffc0205294:	6018                	ld	a4,0(s0)
ffffffffc0205296:	7b7c                	ld	a5,240(a4)
ffffffffc0205298:	c3a1                	beqz	a5,ffffffffc02052d8 <do_exit+0xce>
                if (initproc->wait_state == WT_CHILD) {
ffffffffc020529a:	800009b7          	lui	s3,0x80000
            if (proc->state == PROC_ZOMBIE) {
ffffffffc020529e:	490d                	li	s2,3
                if (initproc->wait_state == WT_CHILD) {
ffffffffc02052a0:	0985                	addi	s3,s3,1
ffffffffc02052a2:	a021                	j	ffffffffc02052aa <do_exit+0xa0>
        while (current->cptr != NULL) {
ffffffffc02052a4:	6018                	ld	a4,0(s0)
ffffffffc02052a6:	7b7c                	ld	a5,240(a4)
ffffffffc02052a8:	cb85                	beqz	a5,ffffffffc02052d8 <do_exit+0xce>
            current->cptr = proc->optr;
ffffffffc02052aa:	1007b683          	ld	a3,256(a5) # ffffffff80000100 <_binary_obj___user_exit_out_size+0xffffffff7fff4fd8>
            if ((proc->optr = initproc->cptr) != NULL) {
ffffffffc02052ae:	6088                	ld	a0,0(s1)
            current->cptr = proc->optr;
ffffffffc02052b0:	fb74                	sd	a3,240(a4)
            if ((proc->optr = initproc->cptr) != NULL) {
ffffffffc02052b2:	7978                	ld	a4,240(a0)
            proc->yptr = NULL;
ffffffffc02052b4:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL) {
ffffffffc02052b8:	10e7b023          	sd	a4,256(a5)
ffffffffc02052bc:	c311                	beqz	a4,ffffffffc02052c0 <do_exit+0xb6>
                initproc->cptr->yptr = proc;
ffffffffc02052be:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE) {
ffffffffc02052c0:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc02052c2:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc02052c4:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE) {
ffffffffc02052c6:	fd271fe3          	bne	a4,s2,ffffffffc02052a4 <do_exit+0x9a>
                if (initproc->wait_state == WT_CHILD) {
ffffffffc02052ca:	0ec52783          	lw	a5,236(a0)
ffffffffc02052ce:	fd379be3          	bne	a5,s3,ffffffffc02052a4 <do_exit+0x9a>
                    wakeup_proc(initproc);
ffffffffc02052d2:	36f000ef          	jal	ra,ffffffffc0205e40 <wakeup_proc>
ffffffffc02052d6:	b7f9                	j	ffffffffc02052a4 <do_exit+0x9a>
    if (flag) {
ffffffffc02052d8:	020a1263          	bnez	s4,ffffffffc02052fc <do_exit+0xf2>
    schedule();
ffffffffc02052dc:	3e5000ef          	jal	ra,ffffffffc0205ec0 <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc02052e0:	601c                	ld	a5,0(s0)
ffffffffc02052e2:	00003617          	auipc	a2,0x3
ffffffffc02052e6:	05660613          	addi	a2,a2,86 # ffffffffc0208338 <default_pmm_manager+0x1110>
ffffffffc02052ea:	20800593          	li	a1,520
ffffffffc02052ee:	43d4                	lw	a3,4(a5)
ffffffffc02052f0:	00003517          	auipc	a0,0x3
ffffffffc02052f4:	fc850513          	addi	a0,a0,-56 # ffffffffc02082b8 <default_pmm_manager+0x1090>
ffffffffc02052f8:	982fb0ef          	jal	ra,ffffffffc020047a <__panic>
        intr_enable();
ffffffffc02052fc:	b44fb0ef          	jal	ra,ffffffffc0200640 <intr_enable>
ffffffffc0205300:	bff1                	j	ffffffffc02052dc <do_exit+0xd2>
        panic("idleproc exit.\n");
ffffffffc0205302:	00003617          	auipc	a2,0x3
ffffffffc0205306:	01660613          	addi	a2,a2,22 # ffffffffc0208318 <default_pmm_manager+0x10f0>
ffffffffc020530a:	1dc00593          	li	a1,476
ffffffffc020530e:	00003517          	auipc	a0,0x3
ffffffffc0205312:	faa50513          	addi	a0,a0,-86 # ffffffffc02082b8 <default_pmm_manager+0x1090>
ffffffffc0205316:	964fb0ef          	jal	ra,ffffffffc020047a <__panic>
            exit_mmap(mm);
ffffffffc020531a:	854e                	mv	a0,s3
ffffffffc020531c:	814ff0ef          	jal	ra,ffffffffc0204330 <exit_mmap>
            put_pgdir(mm);
ffffffffc0205320:	854e                	mv	a0,s3
ffffffffc0205322:	9a9ff0ef          	jal	ra,ffffffffc0204cca <put_pgdir>
            mm_destroy(mm);
ffffffffc0205326:	854e                	mv	a0,s3
ffffffffc0205328:	e6dfe0ef          	jal	ra,ffffffffc0204194 <mm_destroy>
ffffffffc020532c:	bf35                	j	ffffffffc0205268 <do_exit+0x5e>
        panic("initproc exit.\n");
ffffffffc020532e:	00003617          	auipc	a2,0x3
ffffffffc0205332:	ffa60613          	addi	a2,a2,-6 # ffffffffc0208328 <default_pmm_manager+0x1100>
ffffffffc0205336:	1df00593          	li	a1,479
ffffffffc020533a:	00003517          	auipc	a0,0x3
ffffffffc020533e:	f7e50513          	addi	a0,a0,-130 # ffffffffc02082b8 <default_pmm_manager+0x1090>
ffffffffc0205342:	938fb0ef          	jal	ra,ffffffffc020047a <__panic>
        intr_disable();
ffffffffc0205346:	b00fb0ef          	jal	ra,ffffffffc0200646 <intr_disable>
        return 1;
ffffffffc020534a:	4a05                	li	s4,1
ffffffffc020534c:	bf1d                	j	ffffffffc0205282 <do_exit+0x78>
            wakeup_proc(proc);
ffffffffc020534e:	2f3000ef          	jal	ra,ffffffffc0205e40 <wakeup_proc>
ffffffffc0205352:	b789                	j	ffffffffc0205294 <do_exit+0x8a>

ffffffffc0205354 <do_wait.part.0>:
do_wait(int pid, int *code_store) {
ffffffffc0205354:	715d                	addi	sp,sp,-80
ffffffffc0205356:	f84a                	sd	s2,48(sp)
ffffffffc0205358:	f44e                	sd	s3,40(sp)
        current->wait_state = WT_CHILD;
ffffffffc020535a:	80000937          	lui	s2,0x80000
    if (0 < pid && pid < MAX_PID) {
ffffffffc020535e:	6989                	lui	s3,0x2
do_wait(int pid, int *code_store) {
ffffffffc0205360:	fc26                	sd	s1,56(sp)
ffffffffc0205362:	f052                	sd	s4,32(sp)
ffffffffc0205364:	ec56                	sd	s5,24(sp)
ffffffffc0205366:	e85a                	sd	s6,16(sp)
ffffffffc0205368:	e45e                	sd	s7,8(sp)
ffffffffc020536a:	e486                	sd	ra,72(sp)
ffffffffc020536c:	e0a2                	sd	s0,64(sp)
ffffffffc020536e:	84aa                	mv	s1,a0
ffffffffc0205370:	8a2e                	mv	s4,a1
        proc = current->cptr;
ffffffffc0205372:	000adb97          	auipc	s7,0xad
ffffffffc0205376:	53eb8b93          	addi	s7,s7,1342 # ffffffffc02b28b0 <current>
    if (0 < pid && pid < MAX_PID) {
ffffffffc020537a:	00050b1b          	sext.w	s6,a0
ffffffffc020537e:	fff50a9b          	addiw	s5,a0,-1
ffffffffc0205382:	19f9                	addi	s3,s3,-2
        current->wait_state = WT_CHILD;
ffffffffc0205384:	0905                	addi	s2,s2,1
    if (pid != 0) {
ffffffffc0205386:	ccbd                	beqz	s1,ffffffffc0205404 <do_wait.part.0+0xb0>
    if (0 < pid && pid < MAX_PID) {
ffffffffc0205388:	0359e863          	bltu	s3,s5,ffffffffc02053b8 <do_wait.part.0+0x64>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc020538c:	45a9                	li	a1,10
ffffffffc020538e:	855a                	mv	a0,s6
ffffffffc0205390:	49d000ef          	jal	ra,ffffffffc020602c <hash32>
ffffffffc0205394:	02051793          	slli	a5,a0,0x20
ffffffffc0205398:	01c7d513          	srli	a0,a5,0x1c
ffffffffc020539c:	000a9797          	auipc	a5,0xa9
ffffffffc02053a0:	48c78793          	addi	a5,a5,1164 # ffffffffc02ae828 <hash_list>
ffffffffc02053a4:	953e                	add	a0,a0,a5
ffffffffc02053a6:	842a                	mv	s0,a0
        while ((le = list_next(le)) != list) {
ffffffffc02053a8:	a029                	j	ffffffffc02053b2 <do_wait.part.0+0x5e>
            if (proc->pid == pid) {
ffffffffc02053aa:	f2c42783          	lw	a5,-212(s0)
ffffffffc02053ae:	02978163          	beq	a5,s1,ffffffffc02053d0 <do_wait.part.0+0x7c>
ffffffffc02053b2:	6400                	ld	s0,8(s0)
        while ((le = list_next(le)) != list) {
ffffffffc02053b4:	fe851be3          	bne	a0,s0,ffffffffc02053aa <do_wait.part.0+0x56>
    return -E_BAD_PROC;
ffffffffc02053b8:	5579                	li	a0,-2
}
ffffffffc02053ba:	60a6                	ld	ra,72(sp)
ffffffffc02053bc:	6406                	ld	s0,64(sp)
ffffffffc02053be:	74e2                	ld	s1,56(sp)
ffffffffc02053c0:	7942                	ld	s2,48(sp)
ffffffffc02053c2:	79a2                	ld	s3,40(sp)
ffffffffc02053c4:	7a02                	ld	s4,32(sp)
ffffffffc02053c6:	6ae2                	ld	s5,24(sp)
ffffffffc02053c8:	6b42                	ld	s6,16(sp)
ffffffffc02053ca:	6ba2                	ld	s7,8(sp)
ffffffffc02053cc:	6161                	addi	sp,sp,80
ffffffffc02053ce:	8082                	ret
        if (proc != NULL && proc->parent == current) {
ffffffffc02053d0:	000bb683          	ld	a3,0(s7)
ffffffffc02053d4:	f4843783          	ld	a5,-184(s0)
ffffffffc02053d8:	fed790e3          	bne	a5,a3,ffffffffc02053b8 <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE) {
ffffffffc02053dc:	f2842703          	lw	a4,-216(s0)
ffffffffc02053e0:	478d                	li	a5,3
ffffffffc02053e2:	0ef70b63          	beq	a4,a5,ffffffffc02054d8 <do_wait.part.0+0x184>
        current->state = PROC_SLEEPING;
ffffffffc02053e6:	4785                	li	a5,1
ffffffffc02053e8:	c29c                	sw	a5,0(a3)
        current->wait_state = WT_CHILD;
ffffffffc02053ea:	0f26a623          	sw	s2,236(a3)
        schedule();
ffffffffc02053ee:	2d3000ef          	jal	ra,ffffffffc0205ec0 <schedule>
        if (current->flags & PF_EXITING) {
ffffffffc02053f2:	000bb783          	ld	a5,0(s7)
ffffffffc02053f6:	0b07a783          	lw	a5,176(a5)
ffffffffc02053fa:	8b85                	andi	a5,a5,1
ffffffffc02053fc:	d7c9                	beqz	a5,ffffffffc0205386 <do_wait.part.0+0x32>
            do_exit(-E_KILLED);
ffffffffc02053fe:	555d                	li	a0,-9
ffffffffc0205400:	e0bff0ef          	jal	ra,ffffffffc020520a <do_exit>
        proc = current->cptr;
ffffffffc0205404:	000bb683          	ld	a3,0(s7)
ffffffffc0205408:	7ae0                	ld	s0,240(a3)
        for (; proc != NULL; proc = proc->optr) {
ffffffffc020540a:	d45d                	beqz	s0,ffffffffc02053b8 <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE) {
ffffffffc020540c:	470d                	li	a4,3
ffffffffc020540e:	a021                	j	ffffffffc0205416 <do_wait.part.0+0xc2>
        for (; proc != NULL; proc = proc->optr) {
ffffffffc0205410:	10043403          	ld	s0,256(s0)
ffffffffc0205414:	d869                	beqz	s0,ffffffffc02053e6 <do_wait.part.0+0x92>
            if (proc->state == PROC_ZOMBIE) {
ffffffffc0205416:	401c                	lw	a5,0(s0)
ffffffffc0205418:	fee79ce3          	bne	a5,a4,ffffffffc0205410 <do_wait.part.0+0xbc>
    if (proc == idleproc || proc == initproc) {
ffffffffc020541c:	000ad797          	auipc	a5,0xad
ffffffffc0205420:	49c7b783          	ld	a5,1180(a5) # ffffffffc02b28b8 <idleproc>
ffffffffc0205424:	0c878963          	beq	a5,s0,ffffffffc02054f6 <do_wait.part.0+0x1a2>
ffffffffc0205428:	000ad797          	auipc	a5,0xad
ffffffffc020542c:	4987b783          	ld	a5,1176(a5) # ffffffffc02b28c0 <initproc>
ffffffffc0205430:	0cf40363          	beq	s0,a5,ffffffffc02054f6 <do_wait.part.0+0x1a2>
    if (code_store != NULL) {
ffffffffc0205434:	000a0663          	beqz	s4,ffffffffc0205440 <do_wait.part.0+0xec>
        *code_store = proc->exit_code;
ffffffffc0205438:	0e842783          	lw	a5,232(s0)
ffffffffc020543c:	00fa2023          	sw	a5,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bb8>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205440:	100027f3          	csrr	a5,sstatus
ffffffffc0205444:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0205446:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205448:	e7c1                	bnez	a5,ffffffffc02054d0 <do_wait.part.0+0x17c>
    __list_del(listelm->prev, listelm->next);
ffffffffc020544a:	6c70                	ld	a2,216(s0)
ffffffffc020544c:	7074                	ld	a3,224(s0)
    if (proc->optr != NULL) {
ffffffffc020544e:	10043703          	ld	a4,256(s0)
        proc->optr->yptr = proc->yptr;
ffffffffc0205452:	7c7c                	ld	a5,248(s0)
    prev->next = next;
ffffffffc0205454:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0205456:	e290                	sd	a2,0(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0205458:	6470                	ld	a2,200(s0)
ffffffffc020545a:	6874                	ld	a3,208(s0)
    prev->next = next;
ffffffffc020545c:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc020545e:	e290                	sd	a2,0(a3)
    if (proc->optr != NULL) {
ffffffffc0205460:	c319                	beqz	a4,ffffffffc0205466 <do_wait.part.0+0x112>
        proc->optr->yptr = proc->yptr;
ffffffffc0205462:	ff7c                	sd	a5,248(a4)
    if (proc->yptr != NULL) {
ffffffffc0205464:	7c7c                	ld	a5,248(s0)
ffffffffc0205466:	c3b5                	beqz	a5,ffffffffc02054ca <do_wait.part.0+0x176>
        proc->yptr->optr = proc->optr;
ffffffffc0205468:	10e7b023          	sd	a4,256(a5)
    nr_process --;
ffffffffc020546c:	000ad717          	auipc	a4,0xad
ffffffffc0205470:	45c70713          	addi	a4,a4,1116 # ffffffffc02b28c8 <nr_process>
ffffffffc0205474:	431c                	lw	a5,0(a4)
ffffffffc0205476:	37fd                	addiw	a5,a5,-1
ffffffffc0205478:	c31c                	sw	a5,0(a4)
    if (flag) {
ffffffffc020547a:	e5a9                	bnez	a1,ffffffffc02054c4 <do_wait.part.0+0x170>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc020547c:	6814                	ld	a3,16(s0)
ffffffffc020547e:	c02007b7          	lui	a5,0xc0200
ffffffffc0205482:	04f6ee63          	bltu	a3,a5,ffffffffc02054de <do_wait.part.0+0x18a>
ffffffffc0205486:	000ad797          	auipc	a5,0xad
ffffffffc020548a:	3fa7b783          	ld	a5,1018(a5) # ffffffffc02b2880 <va_pa_offset>
ffffffffc020548e:	8e9d                	sub	a3,a3,a5
    if (PPN(pa) >= npage) {
ffffffffc0205490:	82b1                	srli	a3,a3,0xc
ffffffffc0205492:	000ad797          	auipc	a5,0xad
ffffffffc0205496:	3d67b783          	ld	a5,982(a5) # ffffffffc02b2868 <npage>
ffffffffc020549a:	06f6fa63          	bgeu	a3,a5,ffffffffc020550e <do_wait.part.0+0x1ba>
    return &pages[PPN(pa) - nbase];
ffffffffc020549e:	00003517          	auipc	a0,0x3
ffffffffc02054a2:	6d253503          	ld	a0,1746(a0) # ffffffffc0208b70 <nbase>
ffffffffc02054a6:	8e89                	sub	a3,a3,a0
ffffffffc02054a8:	069a                	slli	a3,a3,0x6
ffffffffc02054aa:	000ad517          	auipc	a0,0xad
ffffffffc02054ae:	3c653503          	ld	a0,966(a0) # ffffffffc02b2870 <pages>
ffffffffc02054b2:	9536                	add	a0,a0,a3
ffffffffc02054b4:	4589                	li	a1,2
ffffffffc02054b6:	8bdfc0ef          	jal	ra,ffffffffc0201d72 <free_pages>
    kfree(proc);
ffffffffc02054ba:	8522                	mv	a0,s0
ffffffffc02054bc:	ef6fc0ef          	jal	ra,ffffffffc0201bb2 <kfree>
    return 0;
ffffffffc02054c0:	4501                	li	a0,0
ffffffffc02054c2:	bde5                	j	ffffffffc02053ba <do_wait.part.0+0x66>
        intr_enable();
ffffffffc02054c4:	97cfb0ef          	jal	ra,ffffffffc0200640 <intr_enable>
ffffffffc02054c8:	bf55                	j	ffffffffc020547c <do_wait.part.0+0x128>
       proc->parent->cptr = proc->optr;
ffffffffc02054ca:	701c                	ld	a5,32(s0)
ffffffffc02054cc:	fbf8                	sd	a4,240(a5)
ffffffffc02054ce:	bf79                	j	ffffffffc020546c <do_wait.part.0+0x118>
        intr_disable();
ffffffffc02054d0:	976fb0ef          	jal	ra,ffffffffc0200646 <intr_disable>
        return 1;
ffffffffc02054d4:	4585                	li	a1,1
ffffffffc02054d6:	bf95                	j	ffffffffc020544a <do_wait.part.0+0xf6>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc02054d8:	f2840413          	addi	s0,s0,-216
ffffffffc02054dc:	b781                	j	ffffffffc020541c <do_wait.part.0+0xc8>
    return pa2page(PADDR(kva));
ffffffffc02054de:	00002617          	auipc	a2,0x2
ffffffffc02054e2:	e2a60613          	addi	a2,a2,-470 # ffffffffc0207308 <default_pmm_manager+0xe0>
ffffffffc02054e6:	06e00593          	li	a1,110
ffffffffc02054ea:	00002517          	auipc	a0,0x2
ffffffffc02054ee:	d9e50513          	addi	a0,a0,-610 # ffffffffc0207288 <default_pmm_manager+0x60>
ffffffffc02054f2:	f89fa0ef          	jal	ra,ffffffffc020047a <__panic>
        panic("wait idleproc or initproc.\n");
ffffffffc02054f6:	00003617          	auipc	a2,0x3
ffffffffc02054fa:	e6260613          	addi	a2,a2,-414 # ffffffffc0208358 <default_pmm_manager+0x1130>
ffffffffc02054fe:	30100593          	li	a1,769
ffffffffc0205502:	00003517          	auipc	a0,0x3
ffffffffc0205506:	db650513          	addi	a0,a0,-586 # ffffffffc02082b8 <default_pmm_manager+0x1090>
ffffffffc020550a:	f71fa0ef          	jal	ra,ffffffffc020047a <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020550e:	00002617          	auipc	a2,0x2
ffffffffc0205512:	e2260613          	addi	a2,a2,-478 # ffffffffc0207330 <default_pmm_manager+0x108>
ffffffffc0205516:	06200593          	li	a1,98
ffffffffc020551a:	00002517          	auipc	a0,0x2
ffffffffc020551e:	d6e50513          	addi	a0,a0,-658 # ffffffffc0207288 <default_pmm_manager+0x60>
ffffffffc0205522:	f59fa0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0205526 <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg) {
ffffffffc0205526:	1141                	addi	sp,sp,-16
ffffffffc0205528:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc020552a:	889fc0ef          	jal	ra,ffffffffc0201db2 <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc020552e:	dd0fc0ef          	jal	ra,ffffffffc0201afe <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc0205532:	4601                	li	a2,0
ffffffffc0205534:	4581                	li	a1,0
ffffffffc0205536:	fffff517          	auipc	a0,0xfffff
ffffffffc020553a:	71650513          	addi	a0,a0,1814 # ffffffffc0204c4c <user_main>
ffffffffc020553e:	c7dff0ef          	jal	ra,ffffffffc02051ba <kernel_thread>
    if (pid <= 0) {
ffffffffc0205542:	00a04563          	bgtz	a0,ffffffffc020554c <init_main+0x26>
ffffffffc0205546:	a071                	j	ffffffffc02055d2 <init_main+0xac>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0) {
        schedule();
ffffffffc0205548:	179000ef          	jal	ra,ffffffffc0205ec0 <schedule>
    if (code_store != NULL) {
ffffffffc020554c:	4581                	li	a1,0
ffffffffc020554e:	4501                	li	a0,0
ffffffffc0205550:	e05ff0ef          	jal	ra,ffffffffc0205354 <do_wait.part.0>
    while (do_wait(0, NULL) == 0) {
ffffffffc0205554:	d975                	beqz	a0,ffffffffc0205548 <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc0205556:	00003517          	auipc	a0,0x3
ffffffffc020555a:	e4250513          	addi	a0,a0,-446 # ffffffffc0208398 <default_pmm_manager+0x1170>
ffffffffc020555e:	c23fa0ef          	jal	ra,ffffffffc0200180 <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0205562:	000ad797          	auipc	a5,0xad
ffffffffc0205566:	35e7b783          	ld	a5,862(a5) # ffffffffc02b28c0 <initproc>
ffffffffc020556a:	7bf8                	ld	a4,240(a5)
ffffffffc020556c:	e339                	bnez	a4,ffffffffc02055b2 <init_main+0x8c>
ffffffffc020556e:	7ff8                	ld	a4,248(a5)
ffffffffc0205570:	e329                	bnez	a4,ffffffffc02055b2 <init_main+0x8c>
ffffffffc0205572:	1007b703          	ld	a4,256(a5)
ffffffffc0205576:	ef15                	bnez	a4,ffffffffc02055b2 <init_main+0x8c>
    assert(nr_process == 2);
ffffffffc0205578:	000ad697          	auipc	a3,0xad
ffffffffc020557c:	3506a683          	lw	a3,848(a3) # ffffffffc02b28c8 <nr_process>
ffffffffc0205580:	4709                	li	a4,2
ffffffffc0205582:	0ae69463          	bne	a3,a4,ffffffffc020562a <init_main+0x104>
    return listelm->next;
ffffffffc0205586:	000ad697          	auipc	a3,0xad
ffffffffc020558a:	2a268693          	addi	a3,a3,674 # ffffffffc02b2828 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc020558e:	6698                	ld	a4,8(a3)
ffffffffc0205590:	0c878793          	addi	a5,a5,200
ffffffffc0205594:	06f71b63          	bne	a4,a5,ffffffffc020560a <init_main+0xe4>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc0205598:	629c                	ld	a5,0(a3)
ffffffffc020559a:	04f71863          	bne	a4,a5,ffffffffc02055ea <init_main+0xc4>

    cprintf("init check memory pass.\n");
ffffffffc020559e:	00003517          	auipc	a0,0x3
ffffffffc02055a2:	ee250513          	addi	a0,a0,-286 # ffffffffc0208480 <default_pmm_manager+0x1258>
ffffffffc02055a6:	bdbfa0ef          	jal	ra,ffffffffc0200180 <cprintf>
    return 0;
}
ffffffffc02055aa:	60a2                	ld	ra,8(sp)
ffffffffc02055ac:	4501                	li	a0,0
ffffffffc02055ae:	0141                	addi	sp,sp,16
ffffffffc02055b0:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc02055b2:	00003697          	auipc	a3,0x3
ffffffffc02055b6:	e0e68693          	addi	a3,a3,-498 # ffffffffc02083c0 <default_pmm_manager+0x1198>
ffffffffc02055ba:	00001617          	auipc	a2,0x1
ffffffffc02055be:	5d660613          	addi	a2,a2,1494 # ffffffffc0206b90 <commands+0x450>
ffffffffc02055c2:	36600593          	li	a1,870
ffffffffc02055c6:	00003517          	auipc	a0,0x3
ffffffffc02055ca:	cf250513          	addi	a0,a0,-782 # ffffffffc02082b8 <default_pmm_manager+0x1090>
ffffffffc02055ce:	eadfa0ef          	jal	ra,ffffffffc020047a <__panic>
        panic("create user_main failed.\n");
ffffffffc02055d2:	00003617          	auipc	a2,0x3
ffffffffc02055d6:	da660613          	addi	a2,a2,-602 # ffffffffc0208378 <default_pmm_manager+0x1150>
ffffffffc02055da:	35e00593          	li	a1,862
ffffffffc02055de:	00003517          	auipc	a0,0x3
ffffffffc02055e2:	cda50513          	addi	a0,a0,-806 # ffffffffc02082b8 <default_pmm_manager+0x1090>
ffffffffc02055e6:	e95fa0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc02055ea:	00003697          	auipc	a3,0x3
ffffffffc02055ee:	e6668693          	addi	a3,a3,-410 # ffffffffc0208450 <default_pmm_manager+0x1228>
ffffffffc02055f2:	00001617          	auipc	a2,0x1
ffffffffc02055f6:	59e60613          	addi	a2,a2,1438 # ffffffffc0206b90 <commands+0x450>
ffffffffc02055fa:	36900593          	li	a1,873
ffffffffc02055fe:	00003517          	auipc	a0,0x3
ffffffffc0205602:	cba50513          	addi	a0,a0,-838 # ffffffffc02082b8 <default_pmm_manager+0x1090>
ffffffffc0205606:	e75fa0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc020560a:	00003697          	auipc	a3,0x3
ffffffffc020560e:	e1668693          	addi	a3,a3,-490 # ffffffffc0208420 <default_pmm_manager+0x11f8>
ffffffffc0205612:	00001617          	auipc	a2,0x1
ffffffffc0205616:	57e60613          	addi	a2,a2,1406 # ffffffffc0206b90 <commands+0x450>
ffffffffc020561a:	36800593          	li	a1,872
ffffffffc020561e:	00003517          	auipc	a0,0x3
ffffffffc0205622:	c9a50513          	addi	a0,a0,-870 # ffffffffc02082b8 <default_pmm_manager+0x1090>
ffffffffc0205626:	e55fa0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(nr_process == 2);
ffffffffc020562a:	00003697          	auipc	a3,0x3
ffffffffc020562e:	de668693          	addi	a3,a3,-538 # ffffffffc0208410 <default_pmm_manager+0x11e8>
ffffffffc0205632:	00001617          	auipc	a2,0x1
ffffffffc0205636:	55e60613          	addi	a2,a2,1374 # ffffffffc0206b90 <commands+0x450>
ffffffffc020563a:	36700593          	li	a1,871
ffffffffc020563e:	00003517          	auipc	a0,0x3
ffffffffc0205642:	c7a50513          	addi	a0,a0,-902 # ffffffffc02082b8 <default_pmm_manager+0x1090>
ffffffffc0205646:	e35fa0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc020564a <do_execve>:
do_execve(const char *name, size_t len, unsigned char *binary, size_t size) {
ffffffffc020564a:	7171                	addi	sp,sp,-176
ffffffffc020564c:	e4ee                	sd	s11,72(sp)
    struct mm_struct *mm = current->mm;
ffffffffc020564e:	000add97          	auipc	s11,0xad
ffffffffc0205652:	262d8d93          	addi	s11,s11,610 # ffffffffc02b28b0 <current>
ffffffffc0205656:	000db783          	ld	a5,0(s11)
do_execve(const char *name, size_t len, unsigned char *binary, size_t size) {
ffffffffc020565a:	e54e                	sd	s3,136(sp)
ffffffffc020565c:	ed26                	sd	s1,152(sp)
    struct mm_struct *mm = current->mm;
ffffffffc020565e:	0287b983          	ld	s3,40(a5)
do_execve(const char *name, size_t len, unsigned char *binary, size_t size) {
ffffffffc0205662:	e94a                	sd	s2,144(sp)
ffffffffc0205664:	f4de                	sd	s7,104(sp)
ffffffffc0205666:	892a                	mv	s2,a0
ffffffffc0205668:	8bb2                	mv	s7,a2
ffffffffc020566a:	84ae                	mv	s1,a1
    if (!user_mem_check(mm, (uintptr_t)name, len, 0)) {
ffffffffc020566c:	862e                	mv	a2,a1
ffffffffc020566e:	4681                	li	a3,0
ffffffffc0205670:	85aa                	mv	a1,a0
ffffffffc0205672:	854e                	mv	a0,s3
do_execve(const char *name, size_t len, unsigned char *binary, size_t size) {
ffffffffc0205674:	f506                	sd	ra,168(sp)
ffffffffc0205676:	f122                	sd	s0,160(sp)
ffffffffc0205678:	e152                	sd	s4,128(sp)
ffffffffc020567a:	fcd6                	sd	s5,120(sp)
ffffffffc020567c:	f8da                	sd	s6,112(sp)
ffffffffc020567e:	f0e2                	sd	s8,96(sp)
ffffffffc0205680:	ece6                	sd	s9,88(sp)
ffffffffc0205682:	e8ea                	sd	s10,80(sp)
ffffffffc0205684:	f05e                	sd	s7,32(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0)) {
ffffffffc0205686:	b56ff0ef          	jal	ra,ffffffffc02049dc <user_mem_check>
ffffffffc020568a:	40050863          	beqz	a0,ffffffffc0205a9a <do_execve+0x450>
    memset(local_name, 0, sizeof(local_name));
ffffffffc020568e:	4641                	li	a2,16
ffffffffc0205690:	4581                	li	a1,0
ffffffffc0205692:	1808                	addi	a0,sp,48
ffffffffc0205694:	619000ef          	jal	ra,ffffffffc02064ac <memset>
    memcpy(local_name, name, len);
ffffffffc0205698:	47bd                	li	a5,15
ffffffffc020569a:	8626                	mv	a2,s1
ffffffffc020569c:	1e97e063          	bltu	a5,s1,ffffffffc020587c <do_execve+0x232>
ffffffffc02056a0:	85ca                	mv	a1,s2
ffffffffc02056a2:	1808                	addi	a0,sp,48
ffffffffc02056a4:	61b000ef          	jal	ra,ffffffffc02064be <memcpy>
    if (mm != NULL) {
ffffffffc02056a8:	1e098163          	beqz	s3,ffffffffc020588a <do_execve+0x240>
        cputs("mm != NULL");
ffffffffc02056ac:	00002517          	auipc	a0,0x2
ffffffffc02056b0:	30450513          	addi	a0,a0,772 # ffffffffc02079b0 <default_pmm_manager+0x788>
ffffffffc02056b4:	b05fa0ef          	jal	ra,ffffffffc02001b8 <cputs>
ffffffffc02056b8:	000ad797          	auipc	a5,0xad
ffffffffc02056bc:	1a07b783          	ld	a5,416(a5) # ffffffffc02b2858 <boot_cr3>
ffffffffc02056c0:	577d                	li	a4,-1
ffffffffc02056c2:	177e                	slli	a4,a4,0x3f
ffffffffc02056c4:	83b1                	srli	a5,a5,0xc
ffffffffc02056c6:	8fd9                	or	a5,a5,a4
ffffffffc02056c8:	18079073          	csrw	satp,a5
ffffffffc02056cc:	0309a783          	lw	a5,48(s3) # 2030 <_binary_obj___user_faultread_out_size-0x7b88>
ffffffffc02056d0:	fff7871b          	addiw	a4,a5,-1
ffffffffc02056d4:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0) {
ffffffffc02056d8:	2c070263          	beqz	a4,ffffffffc020599c <do_execve+0x352>
        current->mm = NULL;
ffffffffc02056dc:	000db783          	ld	a5,0(s11)
ffffffffc02056e0:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL) {
ffffffffc02056e4:	92bfe0ef          	jal	ra,ffffffffc020400e <mm_create>
ffffffffc02056e8:	84aa                	mv	s1,a0
ffffffffc02056ea:	1c050b63          	beqz	a0,ffffffffc02058c0 <do_execve+0x276>
    if ((page = alloc_page()) == NULL) {
ffffffffc02056ee:	4505                	li	a0,1
ffffffffc02056f0:	df0fc0ef          	jal	ra,ffffffffc0201ce0 <alloc_pages>
ffffffffc02056f4:	3a050763          	beqz	a0,ffffffffc0205aa2 <do_execve+0x458>
    return page - pages + nbase;
ffffffffc02056f8:	000adc97          	auipc	s9,0xad
ffffffffc02056fc:	178c8c93          	addi	s9,s9,376 # ffffffffc02b2870 <pages>
ffffffffc0205700:	000cb683          	ld	a3,0(s9)
    return KADDR(page2pa(page));
ffffffffc0205704:	000adc17          	auipc	s8,0xad
ffffffffc0205708:	164c0c13          	addi	s8,s8,356 # ffffffffc02b2868 <npage>
    return page - pages + nbase;
ffffffffc020570c:	00003717          	auipc	a4,0x3
ffffffffc0205710:	46473703          	ld	a4,1124(a4) # ffffffffc0208b70 <nbase>
ffffffffc0205714:	40d506b3          	sub	a3,a0,a3
ffffffffc0205718:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc020571a:	5afd                	li	s5,-1
ffffffffc020571c:	000c3783          	ld	a5,0(s8)
    return page - pages + nbase;
ffffffffc0205720:	96ba                	add	a3,a3,a4
ffffffffc0205722:	e83a                	sd	a4,16(sp)
    return KADDR(page2pa(page));
ffffffffc0205724:	00cad713          	srli	a4,s5,0xc
ffffffffc0205728:	ec3a                	sd	a4,24(sp)
ffffffffc020572a:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc020572c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020572e:	36f77e63          	bgeu	a4,a5,ffffffffc0205aaa <do_execve+0x460>
ffffffffc0205732:	000adb17          	auipc	s6,0xad
ffffffffc0205736:	14eb0b13          	addi	s6,s6,334 # ffffffffc02b2880 <va_pa_offset>
ffffffffc020573a:	000b3903          	ld	s2,0(s6)
    memcpy(pgdir, boot_pgdir, PGSIZE);
ffffffffc020573e:	6605                	lui	a2,0x1
ffffffffc0205740:	000ad597          	auipc	a1,0xad
ffffffffc0205744:	1205b583          	ld	a1,288(a1) # ffffffffc02b2860 <boot_pgdir>
ffffffffc0205748:	9936                	add	s2,s2,a3
ffffffffc020574a:	854a                	mv	a0,s2
ffffffffc020574c:	573000ef          	jal	ra,ffffffffc02064be <memcpy>
    if (elf->e_magic != ELF_MAGIC) {
ffffffffc0205750:	7782                	ld	a5,32(sp)
ffffffffc0205752:	4398                	lw	a4,0(a5)
ffffffffc0205754:	464c47b7          	lui	a5,0x464c4
    mm->pgdir = pgdir;
ffffffffc0205758:	0124bc23          	sd	s2,24(s1)
    if (elf->e_magic != ELF_MAGIC) {
ffffffffc020575c:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_exit_out_size+0x464b9457>
ffffffffc0205760:	14f71663          	bne	a4,a5,ffffffffc02058ac <do_execve+0x262>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0205764:	7682                	ld	a3,32(sp)
ffffffffc0205766:	0386d703          	lhu	a4,56(a3)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc020576a:	0206b983          	ld	s3,32(a3)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc020576e:	00371793          	slli	a5,a4,0x3
ffffffffc0205772:	8f99                	sub	a5,a5,a4
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0205774:	99b6                	add	s3,s3,a3
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0205776:	078e                	slli	a5,a5,0x3
ffffffffc0205778:	97ce                	add	a5,a5,s3
ffffffffc020577a:	f43e                	sd	a5,40(sp)
    for (; ph < ph_end; ph ++) {
ffffffffc020577c:	00f9fc63          	bgeu	s3,a5,ffffffffc0205794 <do_execve+0x14a>
        if (ph->p_type != ELF_PT_LOAD) {
ffffffffc0205780:	0009a783          	lw	a5,0(s3)
ffffffffc0205784:	4705                	li	a4,1
ffffffffc0205786:	12e78f63          	beq	a5,a4,ffffffffc02058c4 <do_execve+0x27a>
    for (; ph < ph_end; ph ++) {
ffffffffc020578a:	77a2                	ld	a5,40(sp)
ffffffffc020578c:	03898993          	addi	s3,s3,56
ffffffffc0205790:	fef9e8e3          	bltu	s3,a5,ffffffffc0205780 <do_execve+0x136>
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0) {
ffffffffc0205794:	4701                	li	a4,0
ffffffffc0205796:	46ad                	li	a3,11
ffffffffc0205798:	00100637          	lui	a2,0x100
ffffffffc020579c:	7ff005b7          	lui	a1,0x7ff00
ffffffffc02057a0:	8526                	mv	a0,s1
ffffffffc02057a2:	a45fe0ef          	jal	ra,ffffffffc02041e6 <mm_map>
ffffffffc02057a6:	8a2a                	mv	s4,a0
ffffffffc02057a8:	1e051063          	bnez	a0,ffffffffc0205988 <do_execve+0x33e>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-PGSIZE , PTE_USER) != NULL);
ffffffffc02057ac:	6c88                	ld	a0,24(s1)
ffffffffc02057ae:	467d                	li	a2,31
ffffffffc02057b0:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc02057b4:	b99fd0ef          	jal	ra,ffffffffc020334c <pgdir_alloc_page>
ffffffffc02057b8:	38050163          	beqz	a0,ffffffffc0205b3a <do_execve+0x4f0>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-2*PGSIZE , PTE_USER) != NULL);
ffffffffc02057bc:	6c88                	ld	a0,24(s1)
ffffffffc02057be:	467d                	li	a2,31
ffffffffc02057c0:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc02057c4:	b89fd0ef          	jal	ra,ffffffffc020334c <pgdir_alloc_page>
ffffffffc02057c8:	34050963          	beqz	a0,ffffffffc0205b1a <do_execve+0x4d0>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-3*PGSIZE , PTE_USER) != NULL);
ffffffffc02057cc:	6c88                	ld	a0,24(s1)
ffffffffc02057ce:	467d                	li	a2,31
ffffffffc02057d0:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc02057d4:	b79fd0ef          	jal	ra,ffffffffc020334c <pgdir_alloc_page>
ffffffffc02057d8:	32050163          	beqz	a0,ffffffffc0205afa <do_execve+0x4b0>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-4*PGSIZE , PTE_USER) != NULL);
ffffffffc02057dc:	6c88                	ld	a0,24(s1)
ffffffffc02057de:	467d                	li	a2,31
ffffffffc02057e0:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc02057e4:	b69fd0ef          	jal	ra,ffffffffc020334c <pgdir_alloc_page>
ffffffffc02057e8:	2e050963          	beqz	a0,ffffffffc0205ada <do_execve+0x490>
    mm->mm_count += 1;
ffffffffc02057ec:	589c                	lw	a5,48(s1)
    current->mm = mm;
ffffffffc02057ee:	000db603          	ld	a2,0(s11)
    current->cr3 = PADDR(mm->pgdir);
ffffffffc02057f2:	6c94                	ld	a3,24(s1)
ffffffffc02057f4:	2785                	addiw	a5,a5,1
ffffffffc02057f6:	d89c                	sw	a5,48(s1)
    current->mm = mm;
ffffffffc02057f8:	f604                	sd	s1,40(a2)
    current->cr3 = PADDR(mm->pgdir);
ffffffffc02057fa:	c02007b7          	lui	a5,0xc0200
ffffffffc02057fe:	2cf6e263          	bltu	a3,a5,ffffffffc0205ac2 <do_execve+0x478>
ffffffffc0205802:	000b3783          	ld	a5,0(s6)
ffffffffc0205806:	577d                	li	a4,-1
ffffffffc0205808:	177e                	slli	a4,a4,0x3f
ffffffffc020580a:	8e9d                	sub	a3,a3,a5
ffffffffc020580c:	00c6d793          	srli	a5,a3,0xc
ffffffffc0205810:	f654                	sd	a3,168(a2)
ffffffffc0205812:	8fd9                	or	a5,a5,a4
ffffffffc0205814:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc0205818:	7240                	ld	s0,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc020581a:	4581                	li	a1,0
ffffffffc020581c:	12000613          	li	a2,288
ffffffffc0205820:	8522                	mv	a0,s0
    uintptr_t sstatus = tf->status;
ffffffffc0205822:	10043903          	ld	s2,256(s0)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0205826:	487000ef          	jal	ra,ffffffffc02064ac <memset>
    tf->epc = elf->e_entry;
ffffffffc020582a:	7782                	ld	a5,32(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020582c:	000db483          	ld	s1,0(s11)
    tf->status = sstatus & ~(SSTATUS_SPP | SSTATUS_SPIE);
ffffffffc0205830:	edf97913          	andi	s2,s2,-289
    tf->epc = elf->e_entry;
ffffffffc0205834:	6f98                	ld	a4,24(a5)
    tf->gpr.sp = USTACKTOP;
ffffffffc0205836:	4785                	li	a5,1
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205838:	0b448493          	addi	s1,s1,180
    tf->gpr.sp = USTACKTOP;
ffffffffc020583c:	07fe                	slli	a5,a5,0x1f
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020583e:	4641                	li	a2,16
ffffffffc0205840:	4581                	li	a1,0
    tf->gpr.sp = USTACKTOP;
ffffffffc0205842:	e81c                	sd	a5,16(s0)
    tf->epc = elf->e_entry;
ffffffffc0205844:	10e43423          	sd	a4,264(s0)
    tf->status = sstatus & ~(SSTATUS_SPP | SSTATUS_SPIE);
ffffffffc0205848:	11243023          	sd	s2,256(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020584c:	8526                	mv	a0,s1
ffffffffc020584e:	45f000ef          	jal	ra,ffffffffc02064ac <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0205852:	463d                	li	a2,15
ffffffffc0205854:	180c                	addi	a1,sp,48
ffffffffc0205856:	8526                	mv	a0,s1
ffffffffc0205858:	467000ef          	jal	ra,ffffffffc02064be <memcpy>
}
ffffffffc020585c:	70aa                	ld	ra,168(sp)
ffffffffc020585e:	740a                	ld	s0,160(sp)
ffffffffc0205860:	64ea                	ld	s1,152(sp)
ffffffffc0205862:	694a                	ld	s2,144(sp)
ffffffffc0205864:	69aa                	ld	s3,136(sp)
ffffffffc0205866:	7ae6                	ld	s5,120(sp)
ffffffffc0205868:	7b46                	ld	s6,112(sp)
ffffffffc020586a:	7ba6                	ld	s7,104(sp)
ffffffffc020586c:	7c06                	ld	s8,96(sp)
ffffffffc020586e:	6ce6                	ld	s9,88(sp)
ffffffffc0205870:	6d46                	ld	s10,80(sp)
ffffffffc0205872:	6da6                	ld	s11,72(sp)
ffffffffc0205874:	8552                	mv	a0,s4
ffffffffc0205876:	6a0a                	ld	s4,128(sp)
ffffffffc0205878:	614d                	addi	sp,sp,176
ffffffffc020587a:	8082                	ret
    memcpy(local_name, name, len);
ffffffffc020587c:	463d                	li	a2,15
ffffffffc020587e:	85ca                	mv	a1,s2
ffffffffc0205880:	1808                	addi	a0,sp,48
ffffffffc0205882:	43d000ef          	jal	ra,ffffffffc02064be <memcpy>
    if (mm != NULL) {
ffffffffc0205886:	e20993e3          	bnez	s3,ffffffffc02056ac <do_execve+0x62>
    if (current->mm != NULL) {
ffffffffc020588a:	000db783          	ld	a5,0(s11)
ffffffffc020588e:	779c                	ld	a5,40(a5)
ffffffffc0205890:	e4078ae3          	beqz	a5,ffffffffc02056e4 <do_execve+0x9a>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc0205894:	00003617          	auipc	a2,0x3
ffffffffc0205898:	c0c60613          	addi	a2,a2,-1012 # ffffffffc02084a0 <default_pmm_manager+0x1278>
ffffffffc020589c:	21200593          	li	a1,530
ffffffffc02058a0:	00003517          	auipc	a0,0x3
ffffffffc02058a4:	a1850513          	addi	a0,a0,-1512 # ffffffffc02082b8 <default_pmm_manager+0x1090>
ffffffffc02058a8:	bd3fa0ef          	jal	ra,ffffffffc020047a <__panic>
    put_pgdir(mm);
ffffffffc02058ac:	8526                	mv	a0,s1
ffffffffc02058ae:	c1cff0ef          	jal	ra,ffffffffc0204cca <put_pgdir>
    mm_destroy(mm);
ffffffffc02058b2:	8526                	mv	a0,s1
ffffffffc02058b4:	8e1fe0ef          	jal	ra,ffffffffc0204194 <mm_destroy>
        ret = -E_INVAL_ELF;
ffffffffc02058b8:	5a61                	li	s4,-8
    do_exit(ret);
ffffffffc02058ba:	8552                	mv	a0,s4
ffffffffc02058bc:	94fff0ef          	jal	ra,ffffffffc020520a <do_exit>
    int ret = -E_NO_MEM;
ffffffffc02058c0:	5a71                	li	s4,-4
ffffffffc02058c2:	bfe5                	j	ffffffffc02058ba <do_execve+0x270>
        if (ph->p_filesz > ph->p_memsz) {
ffffffffc02058c4:	0289b603          	ld	a2,40(s3)
ffffffffc02058c8:	0209b783          	ld	a5,32(s3)
ffffffffc02058cc:	1cf66d63          	bltu	a2,a5,ffffffffc0205aa6 <do_execve+0x45c>
        if (ph->p_flags & ELF_PF_X) vm_flags |= VM_EXEC;
ffffffffc02058d0:	0049a783          	lw	a5,4(s3)
ffffffffc02058d4:	0017f693          	andi	a3,a5,1
ffffffffc02058d8:	c291                	beqz	a3,ffffffffc02058dc <do_execve+0x292>
ffffffffc02058da:	4691                	li	a3,4
        if (ph->p_flags & ELF_PF_W) vm_flags |= VM_WRITE;
ffffffffc02058dc:	0027f713          	andi	a4,a5,2
        if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ;
ffffffffc02058e0:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W) vm_flags |= VM_WRITE;
ffffffffc02058e2:	e779                	bnez	a4,ffffffffc02059b0 <do_execve+0x366>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc02058e4:	4d45                	li	s10,17
        if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ;
ffffffffc02058e6:	c781                	beqz	a5,ffffffffc02058ee <do_execve+0x2a4>
ffffffffc02058e8:	0016e693          	ori	a3,a3,1
        if (vm_flags & VM_READ) perm |= PTE_R;
ffffffffc02058ec:	4d4d                	li	s10,19
        if (vm_flags & VM_WRITE) perm |= (PTE_W | PTE_R);
ffffffffc02058ee:	0026f793          	andi	a5,a3,2
ffffffffc02058f2:	e3f1                	bnez	a5,ffffffffc02059b6 <do_execve+0x36c>
        if (vm_flags & VM_EXEC) perm |= PTE_X;
ffffffffc02058f4:	0046f793          	andi	a5,a3,4
ffffffffc02058f8:	c399                	beqz	a5,ffffffffc02058fe <do_execve+0x2b4>
ffffffffc02058fa:	008d6d13          	ori	s10,s10,8
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0) {
ffffffffc02058fe:	0109b583          	ld	a1,16(s3)
ffffffffc0205902:	4701                	li	a4,0
ffffffffc0205904:	8526                	mv	a0,s1
ffffffffc0205906:	8e1fe0ef          	jal	ra,ffffffffc02041e6 <mm_map>
ffffffffc020590a:	8a2a                	mv	s4,a0
ffffffffc020590c:	ed35                	bnez	a0,ffffffffc0205988 <do_execve+0x33e>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc020590e:	0109bb83          	ld	s7,16(s3)
ffffffffc0205912:	77fd                	lui	a5,0xfffff
        end = ph->p_va + ph->p_filesz;
ffffffffc0205914:	0209ba03          	ld	s4,32(s3)
        unsigned char *from = binary + ph->p_offset;
ffffffffc0205918:	0089b903          	ld	s2,8(s3)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc020591c:	00fbfab3          	and	s5,s7,a5
        unsigned char *from = binary + ph->p_offset;
ffffffffc0205920:	7782                	ld	a5,32(sp)
        end = ph->p_va + ph->p_filesz;
ffffffffc0205922:	9a5e                	add	s4,s4,s7
        unsigned char *from = binary + ph->p_offset;
ffffffffc0205924:	993e                	add	s2,s2,a5
        while (start < end) {
ffffffffc0205926:	054be963          	bltu	s7,s4,ffffffffc0205978 <do_execve+0x32e>
ffffffffc020592a:	aa95                	j	ffffffffc0205a9e <do_execve+0x454>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc020592c:	6785                	lui	a5,0x1
ffffffffc020592e:	415b8533          	sub	a0,s7,s5
ffffffffc0205932:	9abe                	add	s5,s5,a5
ffffffffc0205934:	417a8633          	sub	a2,s5,s7
            if (end < la) {
ffffffffc0205938:	015a7463          	bgeu	s4,s5,ffffffffc0205940 <do_execve+0x2f6>
                size -= la - end;
ffffffffc020593c:	417a0633          	sub	a2,s4,s7
    return page - pages + nbase;
ffffffffc0205940:	000cb683          	ld	a3,0(s9)
ffffffffc0205944:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0205946:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc020594a:	40d406b3          	sub	a3,s0,a3
ffffffffc020594e:	8699                	srai	a3,a3,0x6
ffffffffc0205950:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0205952:	67e2                	ld	a5,24(sp)
ffffffffc0205954:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0205958:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020595a:	14b87863          	bgeu	a6,a1,ffffffffc0205aaa <do_execve+0x460>
ffffffffc020595e:	000b3803          	ld	a6,0(s6)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0205962:	85ca                	mv	a1,s2
            start += size, from += size;
ffffffffc0205964:	9bb2                	add	s7,s7,a2
ffffffffc0205966:	96c2                	add	a3,a3,a6
            memcpy(page2kva(page) + off, from, size);
ffffffffc0205968:	9536                	add	a0,a0,a3
            start += size, from += size;
ffffffffc020596a:	e432                	sd	a2,8(sp)
            memcpy(page2kva(page) + off, from, size);
ffffffffc020596c:	353000ef          	jal	ra,ffffffffc02064be <memcpy>
            start += size, from += size;
ffffffffc0205970:	6622                	ld	a2,8(sp)
ffffffffc0205972:	9932                	add	s2,s2,a2
        while (start < end) {
ffffffffc0205974:	054bf363          	bgeu	s7,s4,ffffffffc02059ba <do_execve+0x370>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL) {
ffffffffc0205978:	6c88                	ld	a0,24(s1)
ffffffffc020597a:	866a                	mv	a2,s10
ffffffffc020597c:	85d6                	mv	a1,s5
ffffffffc020597e:	9cffd0ef          	jal	ra,ffffffffc020334c <pgdir_alloc_page>
ffffffffc0205982:	842a                	mv	s0,a0
ffffffffc0205984:	f545                	bnez	a0,ffffffffc020592c <do_execve+0x2e2>
        ret = -E_NO_MEM;
ffffffffc0205986:	5a71                	li	s4,-4
    exit_mmap(mm);
ffffffffc0205988:	8526                	mv	a0,s1
ffffffffc020598a:	9a7fe0ef          	jal	ra,ffffffffc0204330 <exit_mmap>
    put_pgdir(mm);
ffffffffc020598e:	8526                	mv	a0,s1
ffffffffc0205990:	b3aff0ef          	jal	ra,ffffffffc0204cca <put_pgdir>
    mm_destroy(mm);
ffffffffc0205994:	8526                	mv	a0,s1
ffffffffc0205996:	ffefe0ef          	jal	ra,ffffffffc0204194 <mm_destroy>
    return ret;
ffffffffc020599a:	b705                	j	ffffffffc02058ba <do_execve+0x270>
            exit_mmap(mm);
ffffffffc020599c:	854e                	mv	a0,s3
ffffffffc020599e:	993fe0ef          	jal	ra,ffffffffc0204330 <exit_mmap>
            put_pgdir(mm);
ffffffffc02059a2:	854e                	mv	a0,s3
ffffffffc02059a4:	b26ff0ef          	jal	ra,ffffffffc0204cca <put_pgdir>
            mm_destroy(mm);
ffffffffc02059a8:	854e                	mv	a0,s3
ffffffffc02059aa:	feafe0ef          	jal	ra,ffffffffc0204194 <mm_destroy>
ffffffffc02059ae:	b33d                	j	ffffffffc02056dc <do_execve+0x92>
        if (ph->p_flags & ELF_PF_W) vm_flags |= VM_WRITE;
ffffffffc02059b0:	0026e693          	ori	a3,a3,2
        if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ;
ffffffffc02059b4:	fb95                	bnez	a5,ffffffffc02058e8 <do_execve+0x29e>
        if (vm_flags & VM_WRITE) perm |= (PTE_W | PTE_R);
ffffffffc02059b6:	4d5d                	li	s10,23
ffffffffc02059b8:	bf35                	j	ffffffffc02058f4 <do_execve+0x2aa>
        end = ph->p_va + ph->p_memsz;
ffffffffc02059ba:	0109b683          	ld	a3,16(s3)
ffffffffc02059be:	0289b903          	ld	s2,40(s3)
ffffffffc02059c2:	9936                	add	s2,s2,a3
        if (start < la) {
ffffffffc02059c4:	075bfd63          	bgeu	s7,s5,ffffffffc0205a3e <do_execve+0x3f4>
            if (start == end) {
ffffffffc02059c8:	dd7901e3          	beq	s2,s7,ffffffffc020578a <do_execve+0x140>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc02059cc:	6785                	lui	a5,0x1
ffffffffc02059ce:	00fb8533          	add	a0,s7,a5
ffffffffc02059d2:	41550533          	sub	a0,a0,s5
                size -= la - end;
ffffffffc02059d6:	41790a33          	sub	s4,s2,s7
            if (end < la) {
ffffffffc02059da:	0b597d63          	bgeu	s2,s5,ffffffffc0205a94 <do_execve+0x44a>
    return page - pages + nbase;
ffffffffc02059de:	000cb683          	ld	a3,0(s9)
ffffffffc02059e2:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc02059e4:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc02059e8:	40d406b3          	sub	a3,s0,a3
ffffffffc02059ec:	8699                	srai	a3,a3,0x6
ffffffffc02059ee:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc02059f0:	67e2                	ld	a5,24(sp)
ffffffffc02059f2:	00f6f5b3          	and	a1,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc02059f6:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02059f8:	0ac5f963          	bgeu	a1,a2,ffffffffc0205aaa <do_execve+0x460>
ffffffffc02059fc:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc0205a00:	8652                	mv	a2,s4
ffffffffc0205a02:	4581                	li	a1,0
ffffffffc0205a04:	96c2                	add	a3,a3,a6
ffffffffc0205a06:	9536                	add	a0,a0,a3
ffffffffc0205a08:	2a5000ef          	jal	ra,ffffffffc02064ac <memset>
            start += size;
ffffffffc0205a0c:	017a0733          	add	a4,s4,s7
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc0205a10:	03597463          	bgeu	s2,s5,ffffffffc0205a38 <do_execve+0x3ee>
ffffffffc0205a14:	d6e90be3          	beq	s2,a4,ffffffffc020578a <do_execve+0x140>
ffffffffc0205a18:	00003697          	auipc	a3,0x3
ffffffffc0205a1c:	ab068693          	addi	a3,a3,-1360 # ffffffffc02084c8 <default_pmm_manager+0x12a0>
ffffffffc0205a20:	00001617          	auipc	a2,0x1
ffffffffc0205a24:	17060613          	addi	a2,a2,368 # ffffffffc0206b90 <commands+0x450>
ffffffffc0205a28:	26700593          	li	a1,615
ffffffffc0205a2c:	00003517          	auipc	a0,0x3
ffffffffc0205a30:	88c50513          	addi	a0,a0,-1908 # ffffffffc02082b8 <default_pmm_manager+0x1090>
ffffffffc0205a34:	a47fa0ef          	jal	ra,ffffffffc020047a <__panic>
ffffffffc0205a38:	ff5710e3          	bne	a4,s5,ffffffffc0205a18 <do_execve+0x3ce>
ffffffffc0205a3c:	8bd6                	mv	s7,s5
        while (start < end) {
ffffffffc0205a3e:	d52bf6e3          	bgeu	s7,s2,ffffffffc020578a <do_execve+0x140>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL) {
ffffffffc0205a42:	6c88                	ld	a0,24(s1)
ffffffffc0205a44:	866a                	mv	a2,s10
ffffffffc0205a46:	85d6                	mv	a1,s5
ffffffffc0205a48:	905fd0ef          	jal	ra,ffffffffc020334c <pgdir_alloc_page>
ffffffffc0205a4c:	842a                	mv	s0,a0
ffffffffc0205a4e:	dd05                	beqz	a0,ffffffffc0205986 <do_execve+0x33c>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0205a50:	6785                	lui	a5,0x1
ffffffffc0205a52:	415b8533          	sub	a0,s7,s5
ffffffffc0205a56:	9abe                	add	s5,s5,a5
ffffffffc0205a58:	417a8633          	sub	a2,s5,s7
            if (end < la) {
ffffffffc0205a5c:	01597463          	bgeu	s2,s5,ffffffffc0205a64 <do_execve+0x41a>
                size -= la - end;
ffffffffc0205a60:	41790633          	sub	a2,s2,s7
    return page - pages + nbase;
ffffffffc0205a64:	000cb683          	ld	a3,0(s9)
ffffffffc0205a68:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0205a6a:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0205a6e:	40d406b3          	sub	a3,s0,a3
ffffffffc0205a72:	8699                	srai	a3,a3,0x6
ffffffffc0205a74:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0205a76:	67e2                	ld	a5,24(sp)
ffffffffc0205a78:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0205a7c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0205a7e:	02b87663          	bgeu	a6,a1,ffffffffc0205aaa <do_execve+0x460>
ffffffffc0205a82:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc0205a86:	4581                	li	a1,0
            start += size;
ffffffffc0205a88:	9bb2                	add	s7,s7,a2
ffffffffc0205a8a:	96c2                	add	a3,a3,a6
            memset(page2kva(page) + off, 0, size);
ffffffffc0205a8c:	9536                	add	a0,a0,a3
ffffffffc0205a8e:	21f000ef          	jal	ra,ffffffffc02064ac <memset>
ffffffffc0205a92:	b775                	j	ffffffffc0205a3e <do_execve+0x3f4>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0205a94:	417a8a33          	sub	s4,s5,s7
ffffffffc0205a98:	b799                	j	ffffffffc02059de <do_execve+0x394>
        return -E_INVAL;
ffffffffc0205a9a:	5a75                	li	s4,-3
ffffffffc0205a9c:	b3c1                	j	ffffffffc020585c <do_execve+0x212>
        while (start < end) {
ffffffffc0205a9e:	86de                	mv	a3,s7
ffffffffc0205aa0:	bf39                	j	ffffffffc02059be <do_execve+0x374>
    int ret = -E_NO_MEM;
ffffffffc0205aa2:	5a71                	li	s4,-4
ffffffffc0205aa4:	bdc5                	j	ffffffffc0205994 <do_execve+0x34a>
            ret = -E_INVAL_ELF;
ffffffffc0205aa6:	5a61                	li	s4,-8
ffffffffc0205aa8:	b5c5                	j	ffffffffc0205988 <do_execve+0x33e>
ffffffffc0205aaa:	00001617          	auipc	a2,0x1
ffffffffc0205aae:	7b660613          	addi	a2,a2,1974 # ffffffffc0207260 <default_pmm_manager+0x38>
ffffffffc0205ab2:	06900593          	li	a1,105
ffffffffc0205ab6:	00001517          	auipc	a0,0x1
ffffffffc0205aba:	7d250513          	addi	a0,a0,2002 # ffffffffc0207288 <default_pmm_manager+0x60>
ffffffffc0205abe:	9bdfa0ef          	jal	ra,ffffffffc020047a <__panic>
    current->cr3 = PADDR(mm->pgdir);
ffffffffc0205ac2:	00002617          	auipc	a2,0x2
ffffffffc0205ac6:	84660613          	addi	a2,a2,-1978 # ffffffffc0207308 <default_pmm_manager+0xe0>
ffffffffc0205aca:	28200593          	li	a1,642
ffffffffc0205ace:	00002517          	auipc	a0,0x2
ffffffffc0205ad2:	7ea50513          	addi	a0,a0,2026 # ffffffffc02082b8 <default_pmm_manager+0x1090>
ffffffffc0205ad6:	9a5fa0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-4*PGSIZE , PTE_USER) != NULL);
ffffffffc0205ada:	00003697          	auipc	a3,0x3
ffffffffc0205ade:	b0668693          	addi	a3,a3,-1274 # ffffffffc02085e0 <default_pmm_manager+0x13b8>
ffffffffc0205ae2:	00001617          	auipc	a2,0x1
ffffffffc0205ae6:	0ae60613          	addi	a2,a2,174 # ffffffffc0206b90 <commands+0x450>
ffffffffc0205aea:	27d00593          	li	a1,637
ffffffffc0205aee:	00002517          	auipc	a0,0x2
ffffffffc0205af2:	7ca50513          	addi	a0,a0,1994 # ffffffffc02082b8 <default_pmm_manager+0x1090>
ffffffffc0205af6:	985fa0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-3*PGSIZE , PTE_USER) != NULL);
ffffffffc0205afa:	00003697          	auipc	a3,0x3
ffffffffc0205afe:	a9e68693          	addi	a3,a3,-1378 # ffffffffc0208598 <default_pmm_manager+0x1370>
ffffffffc0205b02:	00001617          	auipc	a2,0x1
ffffffffc0205b06:	08e60613          	addi	a2,a2,142 # ffffffffc0206b90 <commands+0x450>
ffffffffc0205b0a:	27c00593          	li	a1,636
ffffffffc0205b0e:	00002517          	auipc	a0,0x2
ffffffffc0205b12:	7aa50513          	addi	a0,a0,1962 # ffffffffc02082b8 <default_pmm_manager+0x1090>
ffffffffc0205b16:	965fa0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-2*PGSIZE , PTE_USER) != NULL);
ffffffffc0205b1a:	00003697          	auipc	a3,0x3
ffffffffc0205b1e:	a3668693          	addi	a3,a3,-1482 # ffffffffc0208550 <default_pmm_manager+0x1328>
ffffffffc0205b22:	00001617          	auipc	a2,0x1
ffffffffc0205b26:	06e60613          	addi	a2,a2,110 # ffffffffc0206b90 <commands+0x450>
ffffffffc0205b2a:	27b00593          	li	a1,635
ffffffffc0205b2e:	00002517          	auipc	a0,0x2
ffffffffc0205b32:	78a50513          	addi	a0,a0,1930 # ffffffffc02082b8 <default_pmm_manager+0x1090>
ffffffffc0205b36:	945fa0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-PGSIZE , PTE_USER) != NULL);
ffffffffc0205b3a:	00003697          	auipc	a3,0x3
ffffffffc0205b3e:	9ce68693          	addi	a3,a3,-1586 # ffffffffc0208508 <default_pmm_manager+0x12e0>
ffffffffc0205b42:	00001617          	auipc	a2,0x1
ffffffffc0205b46:	04e60613          	addi	a2,a2,78 # ffffffffc0206b90 <commands+0x450>
ffffffffc0205b4a:	27a00593          	li	a1,634
ffffffffc0205b4e:	00002517          	auipc	a0,0x2
ffffffffc0205b52:	76a50513          	addi	a0,a0,1898 # ffffffffc02082b8 <default_pmm_manager+0x1090>
ffffffffc0205b56:	925fa0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0205b5a <do_yield>:
    current->need_resched = 1;
ffffffffc0205b5a:	000ad797          	auipc	a5,0xad
ffffffffc0205b5e:	d567b783          	ld	a5,-682(a5) # ffffffffc02b28b0 <current>
ffffffffc0205b62:	4705                	li	a4,1
ffffffffc0205b64:	ef98                	sd	a4,24(a5)
}
ffffffffc0205b66:	4501                	li	a0,0
ffffffffc0205b68:	8082                	ret

ffffffffc0205b6a <do_wait>:
do_wait(int pid, int *code_store) {
ffffffffc0205b6a:	1101                	addi	sp,sp,-32
ffffffffc0205b6c:	e822                	sd	s0,16(sp)
ffffffffc0205b6e:	e426                	sd	s1,8(sp)
ffffffffc0205b70:	ec06                	sd	ra,24(sp)
ffffffffc0205b72:	842e                	mv	s0,a1
ffffffffc0205b74:	84aa                	mv	s1,a0
    if (code_store != NULL) {
ffffffffc0205b76:	c999                	beqz	a1,ffffffffc0205b8c <do_wait+0x22>
    struct mm_struct *mm = current->mm;
ffffffffc0205b78:	000ad797          	auipc	a5,0xad
ffffffffc0205b7c:	d387b783          	ld	a5,-712(a5) # ffffffffc02b28b0 <current>
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1)) {
ffffffffc0205b80:	7788                	ld	a0,40(a5)
ffffffffc0205b82:	4685                	li	a3,1
ffffffffc0205b84:	4611                	li	a2,4
ffffffffc0205b86:	e57fe0ef          	jal	ra,ffffffffc02049dc <user_mem_check>
ffffffffc0205b8a:	c909                	beqz	a0,ffffffffc0205b9c <do_wait+0x32>
ffffffffc0205b8c:	85a2                	mv	a1,s0
}
ffffffffc0205b8e:	6442                	ld	s0,16(sp)
ffffffffc0205b90:	60e2                	ld	ra,24(sp)
ffffffffc0205b92:	8526                	mv	a0,s1
ffffffffc0205b94:	64a2                	ld	s1,8(sp)
ffffffffc0205b96:	6105                	addi	sp,sp,32
ffffffffc0205b98:	fbcff06f          	j	ffffffffc0205354 <do_wait.part.0>
ffffffffc0205b9c:	60e2                	ld	ra,24(sp)
ffffffffc0205b9e:	6442                	ld	s0,16(sp)
ffffffffc0205ba0:	64a2                	ld	s1,8(sp)
ffffffffc0205ba2:	5575                	li	a0,-3
ffffffffc0205ba4:	6105                	addi	sp,sp,32
ffffffffc0205ba6:	8082                	ret

ffffffffc0205ba8 <do_kill>:
do_kill(int pid) {
ffffffffc0205ba8:	1141                	addi	sp,sp,-16
    if (0 < pid && pid < MAX_PID) {
ffffffffc0205baa:	6789                	lui	a5,0x2
do_kill(int pid) {
ffffffffc0205bac:	e406                	sd	ra,8(sp)
ffffffffc0205bae:	e022                	sd	s0,0(sp)
    if (0 < pid && pid < MAX_PID) {
ffffffffc0205bb0:	fff5071b          	addiw	a4,a0,-1
ffffffffc0205bb4:	17f9                	addi	a5,a5,-2
ffffffffc0205bb6:	02e7e963          	bltu	a5,a4,ffffffffc0205be8 <do_kill+0x40>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0205bba:	842a                	mv	s0,a0
ffffffffc0205bbc:	45a9                	li	a1,10
ffffffffc0205bbe:	2501                	sext.w	a0,a0
ffffffffc0205bc0:	46c000ef          	jal	ra,ffffffffc020602c <hash32>
ffffffffc0205bc4:	02051793          	slli	a5,a0,0x20
ffffffffc0205bc8:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0205bcc:	000a9797          	auipc	a5,0xa9
ffffffffc0205bd0:	c5c78793          	addi	a5,a5,-932 # ffffffffc02ae828 <hash_list>
ffffffffc0205bd4:	953e                	add	a0,a0,a5
ffffffffc0205bd6:	87aa                	mv	a5,a0
        while ((le = list_next(le)) != list) {
ffffffffc0205bd8:	a029                	j	ffffffffc0205be2 <do_kill+0x3a>
            if (proc->pid == pid) {
ffffffffc0205bda:	f2c7a703          	lw	a4,-212(a5)
ffffffffc0205bde:	00870b63          	beq	a4,s0,ffffffffc0205bf4 <do_kill+0x4c>
ffffffffc0205be2:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list) {
ffffffffc0205be4:	fef51be3          	bne	a0,a5,ffffffffc0205bda <do_kill+0x32>
    return -E_INVAL;
ffffffffc0205be8:	5475                	li	s0,-3
}
ffffffffc0205bea:	60a2                	ld	ra,8(sp)
ffffffffc0205bec:	8522                	mv	a0,s0
ffffffffc0205bee:	6402                	ld	s0,0(sp)
ffffffffc0205bf0:	0141                	addi	sp,sp,16
ffffffffc0205bf2:	8082                	ret
        if (!(proc->flags & PF_EXITING)) {
ffffffffc0205bf4:	fd87a703          	lw	a4,-40(a5)
ffffffffc0205bf8:	00177693          	andi	a3,a4,1
ffffffffc0205bfc:	e295                	bnez	a3,ffffffffc0205c20 <do_kill+0x78>
            if (proc->wait_state & WT_INTERRUPTED) {
ffffffffc0205bfe:	4bd4                	lw	a3,20(a5)
            proc->flags |= PF_EXITING;
ffffffffc0205c00:	00176713          	ori	a4,a4,1
ffffffffc0205c04:	fce7ac23          	sw	a4,-40(a5)
            return 0;
ffffffffc0205c08:	4401                	li	s0,0
            if (proc->wait_state & WT_INTERRUPTED) {
ffffffffc0205c0a:	fe06d0e3          	bgez	a3,ffffffffc0205bea <do_kill+0x42>
                wakeup_proc(proc);
ffffffffc0205c0e:	f2878513          	addi	a0,a5,-216
ffffffffc0205c12:	22e000ef          	jal	ra,ffffffffc0205e40 <wakeup_proc>
}
ffffffffc0205c16:	60a2                	ld	ra,8(sp)
ffffffffc0205c18:	8522                	mv	a0,s0
ffffffffc0205c1a:	6402                	ld	s0,0(sp)
ffffffffc0205c1c:	0141                	addi	sp,sp,16
ffffffffc0205c1e:	8082                	ret
        return -E_KILLED;
ffffffffc0205c20:	545d                	li	s0,-9
ffffffffc0205c22:	b7e1                	j	ffffffffc0205bea <do_kill+0x42>

ffffffffc0205c24 <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and 
//           - create the second kernel thread init_main
void
proc_init(void) {
ffffffffc0205c24:	1101                	addi	sp,sp,-32
ffffffffc0205c26:	e426                	sd	s1,8(sp)
    elm->prev = elm->next = elm;
ffffffffc0205c28:	000ad797          	auipc	a5,0xad
ffffffffc0205c2c:	c0078793          	addi	a5,a5,-1024 # ffffffffc02b2828 <proc_list>
ffffffffc0205c30:	ec06                	sd	ra,24(sp)
ffffffffc0205c32:	e822                	sd	s0,16(sp)
ffffffffc0205c34:	e04a                	sd	s2,0(sp)
ffffffffc0205c36:	000a9497          	auipc	s1,0xa9
ffffffffc0205c3a:	bf248493          	addi	s1,s1,-1038 # ffffffffc02ae828 <hash_list>
ffffffffc0205c3e:	e79c                	sd	a5,8(a5)
ffffffffc0205c40:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i ++) {
ffffffffc0205c42:	000ad717          	auipc	a4,0xad
ffffffffc0205c46:	be670713          	addi	a4,a4,-1050 # ffffffffc02b2828 <proc_list>
ffffffffc0205c4a:	87a6                	mv	a5,s1
ffffffffc0205c4c:	e79c                	sd	a5,8(a5)
ffffffffc0205c4e:	e39c                	sd	a5,0(a5)
ffffffffc0205c50:	07c1                	addi	a5,a5,16
ffffffffc0205c52:	fef71de3          	bne	a4,a5,ffffffffc0205c4c <proc_init+0x28>
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL) {
ffffffffc0205c56:	f77fe0ef          	jal	ra,ffffffffc0204bcc <alloc_proc>
ffffffffc0205c5a:	000ad917          	auipc	s2,0xad
ffffffffc0205c5e:	c5e90913          	addi	s2,s2,-930 # ffffffffc02b28b8 <idleproc>
ffffffffc0205c62:	00a93023          	sd	a0,0(s2)
ffffffffc0205c66:	0e050f63          	beqz	a0,ffffffffc0205d64 <proc_init+0x140>
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0205c6a:	4789                	li	a5,2
ffffffffc0205c6c:	e11c                	sd	a5,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0205c6e:	00003797          	auipc	a5,0x3
ffffffffc0205c72:	39278793          	addi	a5,a5,914 # ffffffffc0209000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205c76:	0b450413          	addi	s0,a0,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0205c7a:	e91c                	sd	a5,16(a0)
    idleproc->need_resched = 1;
ffffffffc0205c7c:	4785                	li	a5,1
ffffffffc0205c7e:	ed1c                	sd	a5,24(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205c80:	4641                	li	a2,16
ffffffffc0205c82:	4581                	li	a1,0
ffffffffc0205c84:	8522                	mv	a0,s0
ffffffffc0205c86:	027000ef          	jal	ra,ffffffffc02064ac <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0205c8a:	463d                	li	a2,15
ffffffffc0205c8c:	00003597          	auipc	a1,0x3
ffffffffc0205c90:	9b458593          	addi	a1,a1,-1612 # ffffffffc0208640 <default_pmm_manager+0x1418>
ffffffffc0205c94:	8522                	mv	a0,s0
ffffffffc0205c96:	029000ef          	jal	ra,ffffffffc02064be <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process ++;
ffffffffc0205c9a:	000ad717          	auipc	a4,0xad
ffffffffc0205c9e:	c2e70713          	addi	a4,a4,-978 # ffffffffc02b28c8 <nr_process>
ffffffffc0205ca2:	431c                	lw	a5,0(a4)

    current = idleproc;
ffffffffc0205ca4:	00093683          	ld	a3,0(s2)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205ca8:	4601                	li	a2,0
    nr_process ++;
ffffffffc0205caa:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205cac:	4581                	li	a1,0
ffffffffc0205cae:	00000517          	auipc	a0,0x0
ffffffffc0205cb2:	87850513          	addi	a0,a0,-1928 # ffffffffc0205526 <init_main>
    nr_process ++;
ffffffffc0205cb6:	c31c                	sw	a5,0(a4)
    current = idleproc;
ffffffffc0205cb8:	000ad797          	auipc	a5,0xad
ffffffffc0205cbc:	bed7bc23          	sd	a3,-1032(a5) # ffffffffc02b28b0 <current>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205cc0:	cfaff0ef          	jal	ra,ffffffffc02051ba <kernel_thread>
ffffffffc0205cc4:	842a                	mv	s0,a0
    if (pid <= 0) {
ffffffffc0205cc6:	08a05363          	blez	a0,ffffffffc0205d4c <proc_init+0x128>
    if (0 < pid && pid < MAX_PID) {
ffffffffc0205cca:	6789                	lui	a5,0x2
ffffffffc0205ccc:	fff5071b          	addiw	a4,a0,-1
ffffffffc0205cd0:	17f9                	addi	a5,a5,-2
ffffffffc0205cd2:	2501                	sext.w	a0,a0
ffffffffc0205cd4:	02e7e363          	bltu	a5,a4,ffffffffc0205cfa <proc_init+0xd6>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0205cd8:	45a9                	li	a1,10
ffffffffc0205cda:	352000ef          	jal	ra,ffffffffc020602c <hash32>
ffffffffc0205cde:	02051793          	slli	a5,a0,0x20
ffffffffc0205ce2:	01c7d693          	srli	a3,a5,0x1c
ffffffffc0205ce6:	96a6                	add	a3,a3,s1
ffffffffc0205ce8:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list) {
ffffffffc0205cea:	a029                	j	ffffffffc0205cf4 <proc_init+0xd0>
            if (proc->pid == pid) {
ffffffffc0205cec:	f2c7a703          	lw	a4,-212(a5) # 1f2c <_binary_obj___user_faultread_out_size-0x7c8c>
ffffffffc0205cf0:	04870b63          	beq	a4,s0,ffffffffc0205d46 <proc_init+0x122>
    return listelm->next;
ffffffffc0205cf4:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list) {
ffffffffc0205cf6:	fef69be3          	bne	a3,a5,ffffffffc0205cec <proc_init+0xc8>
    return NULL;
ffffffffc0205cfa:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205cfc:	0b478493          	addi	s1,a5,180
ffffffffc0205d00:	4641                	li	a2,16
ffffffffc0205d02:	4581                	li	a1,0
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0205d04:	000ad417          	auipc	s0,0xad
ffffffffc0205d08:	bbc40413          	addi	s0,s0,-1092 # ffffffffc02b28c0 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205d0c:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc0205d0e:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205d10:	79c000ef          	jal	ra,ffffffffc02064ac <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0205d14:	463d                	li	a2,15
ffffffffc0205d16:	00003597          	auipc	a1,0x3
ffffffffc0205d1a:	95258593          	addi	a1,a1,-1710 # ffffffffc0208668 <default_pmm_manager+0x1440>
ffffffffc0205d1e:	8526                	mv	a0,s1
ffffffffc0205d20:	79e000ef          	jal	ra,ffffffffc02064be <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0205d24:	00093783          	ld	a5,0(s2)
ffffffffc0205d28:	cbb5                	beqz	a5,ffffffffc0205d9c <proc_init+0x178>
ffffffffc0205d2a:	43dc                	lw	a5,4(a5)
ffffffffc0205d2c:	eba5                	bnez	a5,ffffffffc0205d9c <proc_init+0x178>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0205d2e:	601c                	ld	a5,0(s0)
ffffffffc0205d30:	c7b1                	beqz	a5,ffffffffc0205d7c <proc_init+0x158>
ffffffffc0205d32:	43d8                	lw	a4,4(a5)
ffffffffc0205d34:	4785                	li	a5,1
ffffffffc0205d36:	04f71363          	bne	a4,a5,ffffffffc0205d7c <proc_init+0x158>
}
ffffffffc0205d3a:	60e2                	ld	ra,24(sp)
ffffffffc0205d3c:	6442                	ld	s0,16(sp)
ffffffffc0205d3e:	64a2                	ld	s1,8(sp)
ffffffffc0205d40:	6902                	ld	s2,0(sp)
ffffffffc0205d42:	6105                	addi	sp,sp,32
ffffffffc0205d44:	8082                	ret
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0205d46:	f2878793          	addi	a5,a5,-216
ffffffffc0205d4a:	bf4d                	j	ffffffffc0205cfc <proc_init+0xd8>
        panic("create init_main failed.\n");
ffffffffc0205d4c:	00003617          	auipc	a2,0x3
ffffffffc0205d50:	8fc60613          	addi	a2,a2,-1796 # ffffffffc0208648 <default_pmm_manager+0x1420>
ffffffffc0205d54:	38900593          	li	a1,905
ffffffffc0205d58:	00002517          	auipc	a0,0x2
ffffffffc0205d5c:	56050513          	addi	a0,a0,1376 # ffffffffc02082b8 <default_pmm_manager+0x1090>
ffffffffc0205d60:	f1afa0ef          	jal	ra,ffffffffc020047a <__panic>
        panic("cannot alloc idleproc.\n");
ffffffffc0205d64:	00003617          	auipc	a2,0x3
ffffffffc0205d68:	8c460613          	addi	a2,a2,-1852 # ffffffffc0208628 <default_pmm_manager+0x1400>
ffffffffc0205d6c:	37b00593          	li	a1,891
ffffffffc0205d70:	00002517          	auipc	a0,0x2
ffffffffc0205d74:	54850513          	addi	a0,a0,1352 # ffffffffc02082b8 <default_pmm_manager+0x1090>
ffffffffc0205d78:	f02fa0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0205d7c:	00003697          	auipc	a3,0x3
ffffffffc0205d80:	91c68693          	addi	a3,a3,-1764 # ffffffffc0208698 <default_pmm_manager+0x1470>
ffffffffc0205d84:	00001617          	auipc	a2,0x1
ffffffffc0205d88:	e0c60613          	addi	a2,a2,-500 # ffffffffc0206b90 <commands+0x450>
ffffffffc0205d8c:	39000593          	li	a1,912
ffffffffc0205d90:	00002517          	auipc	a0,0x2
ffffffffc0205d94:	52850513          	addi	a0,a0,1320 # ffffffffc02082b8 <default_pmm_manager+0x1090>
ffffffffc0205d98:	ee2fa0ef          	jal	ra,ffffffffc020047a <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0205d9c:	00003697          	auipc	a3,0x3
ffffffffc0205da0:	8d468693          	addi	a3,a3,-1836 # ffffffffc0208670 <default_pmm_manager+0x1448>
ffffffffc0205da4:	00001617          	auipc	a2,0x1
ffffffffc0205da8:	dec60613          	addi	a2,a2,-532 # ffffffffc0206b90 <commands+0x450>
ffffffffc0205dac:	38f00593          	li	a1,911
ffffffffc0205db0:	00002517          	auipc	a0,0x2
ffffffffc0205db4:	50850513          	addi	a0,a0,1288 # ffffffffc02082b8 <default_pmm_manager+0x1090>
ffffffffc0205db8:	ec2fa0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0205dbc <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void
cpu_idle(void) {
ffffffffc0205dbc:	1141                	addi	sp,sp,-16
ffffffffc0205dbe:	e022                	sd	s0,0(sp)
ffffffffc0205dc0:	e406                	sd	ra,8(sp)
ffffffffc0205dc2:	000ad417          	auipc	s0,0xad
ffffffffc0205dc6:	aee40413          	addi	s0,s0,-1298 # ffffffffc02b28b0 <current>
    while (1) {
        if (current->need_resched) {
ffffffffc0205dca:	6018                	ld	a4,0(s0)
ffffffffc0205dcc:	6f1c                	ld	a5,24(a4)
ffffffffc0205dce:	dffd                	beqz	a5,ffffffffc0205dcc <cpu_idle+0x10>
            schedule();
ffffffffc0205dd0:	0f0000ef          	jal	ra,ffffffffc0205ec0 <schedule>
ffffffffc0205dd4:	bfdd                	j	ffffffffc0205dca <cpu_idle+0xe>

ffffffffc0205dd6 <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc0205dd6:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc0205dda:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc0205dde:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc0205de0:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc0205de2:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc0205de6:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc0205dea:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc0205dee:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc0205df2:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc0205df6:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc0205dfa:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc0205dfe:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc0205e02:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc0205e06:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc0205e0a:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc0205e0e:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc0205e12:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc0205e14:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc0205e16:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc0205e1a:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc0205e1e:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc0205e22:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc0205e26:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc0205e2a:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc0205e2e:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc0205e32:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc0205e36:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc0205e3a:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc0205e3e:	8082                	ret

ffffffffc0205e40 <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void
wakeup_proc(struct proc_struct *proc) {
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205e40:	4118                	lw	a4,0(a0)
wakeup_proc(struct proc_struct *proc) {
ffffffffc0205e42:	1101                	addi	sp,sp,-32
ffffffffc0205e44:	ec06                	sd	ra,24(sp)
ffffffffc0205e46:	e822                	sd	s0,16(sp)
ffffffffc0205e48:	e426                	sd	s1,8(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205e4a:	478d                	li	a5,3
ffffffffc0205e4c:	04f70b63          	beq	a4,a5,ffffffffc0205ea2 <wakeup_proc+0x62>
ffffffffc0205e50:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205e52:	100027f3          	csrr	a5,sstatus
ffffffffc0205e56:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0205e58:	4481                	li	s1,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205e5a:	ef9d                	bnez	a5,ffffffffc0205e98 <wakeup_proc+0x58>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE) {
ffffffffc0205e5c:	4789                	li	a5,2
ffffffffc0205e5e:	02f70163          	beq	a4,a5,ffffffffc0205e80 <wakeup_proc+0x40>
            proc->state = PROC_RUNNABLE;
ffffffffc0205e62:	c01c                	sw	a5,0(s0)
            proc->wait_state = 0;
ffffffffc0205e64:	0e042623          	sw	zero,236(s0)
    if (flag) {
ffffffffc0205e68:	e491                	bnez	s1,ffffffffc0205e74 <wakeup_proc+0x34>
        else {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0205e6a:	60e2                	ld	ra,24(sp)
ffffffffc0205e6c:	6442                	ld	s0,16(sp)
ffffffffc0205e6e:	64a2                	ld	s1,8(sp)
ffffffffc0205e70:	6105                	addi	sp,sp,32
ffffffffc0205e72:	8082                	ret
ffffffffc0205e74:	6442                	ld	s0,16(sp)
ffffffffc0205e76:	60e2                	ld	ra,24(sp)
ffffffffc0205e78:	64a2                	ld	s1,8(sp)
ffffffffc0205e7a:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0205e7c:	fc4fa06f          	j	ffffffffc0200640 <intr_enable>
            warn("wakeup runnable process.\n");
ffffffffc0205e80:	00003617          	auipc	a2,0x3
ffffffffc0205e84:	87860613          	addi	a2,a2,-1928 # ffffffffc02086f8 <default_pmm_manager+0x14d0>
ffffffffc0205e88:	45c9                	li	a1,18
ffffffffc0205e8a:	00003517          	auipc	a0,0x3
ffffffffc0205e8e:	85650513          	addi	a0,a0,-1962 # ffffffffc02086e0 <default_pmm_manager+0x14b8>
ffffffffc0205e92:	e50fa0ef          	jal	ra,ffffffffc02004e2 <__warn>
ffffffffc0205e96:	bfc9                	j	ffffffffc0205e68 <wakeup_proc+0x28>
        intr_disable();
ffffffffc0205e98:	faefa0ef          	jal	ra,ffffffffc0200646 <intr_disable>
        if (proc->state != PROC_RUNNABLE) {
ffffffffc0205e9c:	4018                	lw	a4,0(s0)
        return 1;
ffffffffc0205e9e:	4485                	li	s1,1
ffffffffc0205ea0:	bf75                	j	ffffffffc0205e5c <wakeup_proc+0x1c>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205ea2:	00003697          	auipc	a3,0x3
ffffffffc0205ea6:	81e68693          	addi	a3,a3,-2018 # ffffffffc02086c0 <default_pmm_manager+0x1498>
ffffffffc0205eaa:	00001617          	auipc	a2,0x1
ffffffffc0205eae:	ce660613          	addi	a2,a2,-794 # ffffffffc0206b90 <commands+0x450>
ffffffffc0205eb2:	45a5                	li	a1,9
ffffffffc0205eb4:	00003517          	auipc	a0,0x3
ffffffffc0205eb8:	82c50513          	addi	a0,a0,-2004 # ffffffffc02086e0 <default_pmm_manager+0x14b8>
ffffffffc0205ebc:	dbefa0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc0205ec0 <schedule>:

void
schedule(void) {
ffffffffc0205ec0:	1141                	addi	sp,sp,-16
ffffffffc0205ec2:	e406                	sd	ra,8(sp)
ffffffffc0205ec4:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205ec6:	100027f3          	csrr	a5,sstatus
ffffffffc0205eca:	8b89                	andi	a5,a5,2
ffffffffc0205ecc:	4401                	li	s0,0
ffffffffc0205ece:	efbd                	bnez	a5,ffffffffc0205f4c <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc0205ed0:	000ad897          	auipc	a7,0xad
ffffffffc0205ed4:	9e08b883          	ld	a7,-1568(a7) # ffffffffc02b28b0 <current>
ffffffffc0205ed8:	0008bc23          	sd	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0205edc:	000ad517          	auipc	a0,0xad
ffffffffc0205ee0:	9dc53503          	ld	a0,-1572(a0) # ffffffffc02b28b8 <idleproc>
ffffffffc0205ee4:	04a88e63          	beq	a7,a0,ffffffffc0205f40 <schedule+0x80>
ffffffffc0205ee8:	0c888693          	addi	a3,a7,200
ffffffffc0205eec:	000ad617          	auipc	a2,0xad
ffffffffc0205ef0:	93c60613          	addi	a2,a2,-1732 # ffffffffc02b2828 <proc_list>
        le = last;
ffffffffc0205ef4:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc0205ef6:	4581                	li	a1,0
        do {
            if ((le = list_next(le)) != &proc_list) {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE) {
ffffffffc0205ef8:	4809                	li	a6,2
ffffffffc0205efa:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list) {
ffffffffc0205efc:	00c78863          	beq	a5,a2,ffffffffc0205f0c <schedule+0x4c>
                if (next->state == PROC_RUNNABLE) {
ffffffffc0205f00:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc0205f04:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE) {
ffffffffc0205f08:	03070163          	beq	a4,a6,ffffffffc0205f2a <schedule+0x6a>
                    break;
                }
            }
        } while (le != last);
ffffffffc0205f0c:	fef697e3          	bne	a3,a5,ffffffffc0205efa <schedule+0x3a>
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc0205f10:	ed89                	bnez	a1,ffffffffc0205f2a <schedule+0x6a>
            next = idleproc;
        }
        next->runs ++;
ffffffffc0205f12:	451c                	lw	a5,8(a0)
ffffffffc0205f14:	2785                	addiw	a5,a5,1
ffffffffc0205f16:	c51c                	sw	a5,8(a0)
        if (next != current) {
ffffffffc0205f18:	00a88463          	beq	a7,a0,ffffffffc0205f20 <schedule+0x60>
            proc_run(next);
ffffffffc0205f1c:	e25fe0ef          	jal	ra,ffffffffc0204d40 <proc_run>
    if (flag) {
ffffffffc0205f20:	e819                	bnez	s0,ffffffffc0205f36 <schedule+0x76>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0205f22:	60a2                	ld	ra,8(sp)
ffffffffc0205f24:	6402                	ld	s0,0(sp)
ffffffffc0205f26:	0141                	addi	sp,sp,16
ffffffffc0205f28:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc0205f2a:	4198                	lw	a4,0(a1)
ffffffffc0205f2c:	4789                	li	a5,2
ffffffffc0205f2e:	fef712e3          	bne	a4,a5,ffffffffc0205f12 <schedule+0x52>
ffffffffc0205f32:	852e                	mv	a0,a1
ffffffffc0205f34:	bff9                	j	ffffffffc0205f12 <schedule+0x52>
}
ffffffffc0205f36:	6402                	ld	s0,0(sp)
ffffffffc0205f38:	60a2                	ld	ra,8(sp)
ffffffffc0205f3a:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0205f3c:	f04fa06f          	j	ffffffffc0200640 <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0205f40:	000ad617          	auipc	a2,0xad
ffffffffc0205f44:	8e860613          	addi	a2,a2,-1816 # ffffffffc02b2828 <proc_list>
ffffffffc0205f48:	86b2                	mv	a3,a2
ffffffffc0205f4a:	b76d                	j	ffffffffc0205ef4 <schedule+0x34>
        intr_disable();
ffffffffc0205f4c:	efafa0ef          	jal	ra,ffffffffc0200646 <intr_disable>
        return 1;
ffffffffc0205f50:	4405                	li	s0,1
ffffffffc0205f52:	bfbd                	j	ffffffffc0205ed0 <schedule+0x10>

ffffffffc0205f54 <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc0205f54:	000ad797          	auipc	a5,0xad
ffffffffc0205f58:	95c7b783          	ld	a5,-1700(a5) # ffffffffc02b28b0 <current>
}
ffffffffc0205f5c:	43c8                	lw	a0,4(a5)
ffffffffc0205f5e:	8082                	ret

ffffffffc0205f60 <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc0205f60:	4501                	li	a0,0
ffffffffc0205f62:	8082                	ret

ffffffffc0205f64 <sys_putc>:
    cputchar(c);
ffffffffc0205f64:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc0205f66:	1141                	addi	sp,sp,-16
ffffffffc0205f68:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc0205f6a:	a4cfa0ef          	jal	ra,ffffffffc02001b6 <cputchar>
}
ffffffffc0205f6e:	60a2                	ld	ra,8(sp)
ffffffffc0205f70:	4501                	li	a0,0
ffffffffc0205f72:	0141                	addi	sp,sp,16
ffffffffc0205f74:	8082                	ret

ffffffffc0205f76 <sys_kill>:
    return do_kill(pid);
ffffffffc0205f76:	4108                	lw	a0,0(a0)
ffffffffc0205f78:	c31ff06f          	j	ffffffffc0205ba8 <do_kill>

ffffffffc0205f7c <sys_yield>:
    return do_yield();
ffffffffc0205f7c:	bdfff06f          	j	ffffffffc0205b5a <do_yield>

ffffffffc0205f80 <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc0205f80:	6d14                	ld	a3,24(a0)
ffffffffc0205f82:	6910                	ld	a2,16(a0)
ffffffffc0205f84:	650c                	ld	a1,8(a0)
ffffffffc0205f86:	6108                	ld	a0,0(a0)
ffffffffc0205f88:	ec2ff06f          	j	ffffffffc020564a <do_execve>

ffffffffc0205f8c <sys_wait>:
    return do_wait(pid, store);
ffffffffc0205f8c:	650c                	ld	a1,8(a0)
ffffffffc0205f8e:	4108                	lw	a0,0(a0)
ffffffffc0205f90:	bdbff06f          	j	ffffffffc0205b6a <do_wait>

ffffffffc0205f94 <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc0205f94:	000ad797          	auipc	a5,0xad
ffffffffc0205f98:	91c7b783          	ld	a5,-1764(a5) # ffffffffc02b28b0 <current>
ffffffffc0205f9c:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc0205f9e:	4501                	li	a0,0
ffffffffc0205fa0:	6a0c                	ld	a1,16(a2)
ffffffffc0205fa2:	e0bfe06f          	j	ffffffffc0204dac <do_fork>

ffffffffc0205fa6 <sys_exit>:
    return do_exit(error_code);
ffffffffc0205fa6:	4108                	lw	a0,0(a0)
ffffffffc0205fa8:	a62ff06f          	j	ffffffffc020520a <do_exit>

ffffffffc0205fac <syscall>:
};

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
ffffffffc0205fac:	715d                	addi	sp,sp,-80
ffffffffc0205fae:	fc26                	sd	s1,56(sp)
    struct trapframe *tf = current->tf;
ffffffffc0205fb0:	000ad497          	auipc	s1,0xad
ffffffffc0205fb4:	90048493          	addi	s1,s1,-1792 # ffffffffc02b28b0 <current>
ffffffffc0205fb8:	6098                	ld	a4,0(s1)
syscall(void) {
ffffffffc0205fba:	e0a2                	sd	s0,64(sp)
ffffffffc0205fbc:	f84a                	sd	s2,48(sp)
    struct trapframe *tf = current->tf;
ffffffffc0205fbe:	7340                	ld	s0,160(a4)
syscall(void) {
ffffffffc0205fc0:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc0205fc2:	47fd                	li	a5,31
    int num = tf->gpr.a0;
ffffffffc0205fc4:	05042903          	lw	s2,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc0205fc8:	0327ee63          	bltu	a5,s2,ffffffffc0206004 <syscall+0x58>
        if (syscalls[num] != NULL) {
ffffffffc0205fcc:	00391713          	slli	a4,s2,0x3
ffffffffc0205fd0:	00002797          	auipc	a5,0x2
ffffffffc0205fd4:	79078793          	addi	a5,a5,1936 # ffffffffc0208760 <syscalls>
ffffffffc0205fd8:	97ba                	add	a5,a5,a4
ffffffffc0205fda:	639c                	ld	a5,0(a5)
ffffffffc0205fdc:	c785                	beqz	a5,ffffffffc0206004 <syscall+0x58>
            arg[0] = tf->gpr.a1;
ffffffffc0205fde:	6c28                	ld	a0,88(s0)
            arg[1] = tf->gpr.a2;
ffffffffc0205fe0:	702c                	ld	a1,96(s0)
            arg[2] = tf->gpr.a3;
ffffffffc0205fe2:	7430                	ld	a2,104(s0)
            arg[3] = tf->gpr.a4;
ffffffffc0205fe4:	7834                	ld	a3,112(s0)
            arg[4] = tf->gpr.a5;
ffffffffc0205fe6:	7c38                	ld	a4,120(s0)
            arg[0] = tf->gpr.a1;
ffffffffc0205fe8:	e42a                	sd	a0,8(sp)
            arg[1] = tf->gpr.a2;
ffffffffc0205fea:	e82e                	sd	a1,16(sp)
            arg[2] = tf->gpr.a3;
ffffffffc0205fec:	ec32                	sd	a2,24(sp)
            arg[3] = tf->gpr.a4;
ffffffffc0205fee:	f036                	sd	a3,32(sp)
            arg[4] = tf->gpr.a5;
ffffffffc0205ff0:	f43a                	sd	a4,40(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc0205ff2:	0028                	addi	a0,sp,8
ffffffffc0205ff4:	9782                	jalr	a5
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc0205ff6:	60a6                	ld	ra,72(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc0205ff8:	e828                	sd	a0,80(s0)
}
ffffffffc0205ffa:	6406                	ld	s0,64(sp)
ffffffffc0205ffc:	74e2                	ld	s1,56(sp)
ffffffffc0205ffe:	7942                	ld	s2,48(sp)
ffffffffc0206000:	6161                	addi	sp,sp,80
ffffffffc0206002:	8082                	ret
    print_trapframe(tf);
ffffffffc0206004:	8522                	mv	a0,s0
ffffffffc0206006:	82ffa0ef          	jal	ra,ffffffffc0200834 <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc020600a:	609c                	ld	a5,0(s1)
ffffffffc020600c:	86ca                	mv	a3,s2
ffffffffc020600e:	00002617          	auipc	a2,0x2
ffffffffc0206012:	70a60613          	addi	a2,a2,1802 # ffffffffc0208718 <default_pmm_manager+0x14f0>
ffffffffc0206016:	43d8                	lw	a4,4(a5)
ffffffffc0206018:	06200593          	li	a1,98
ffffffffc020601c:	0b478793          	addi	a5,a5,180
ffffffffc0206020:	00002517          	auipc	a0,0x2
ffffffffc0206024:	72850513          	addi	a0,a0,1832 # ffffffffc0208748 <default_pmm_manager+0x1520>
ffffffffc0206028:	c52fa0ef          	jal	ra,ffffffffc020047a <__panic>

ffffffffc020602c <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc020602c:	9e3707b7          	lui	a5,0x9e370
ffffffffc0206030:	2785                	addiw	a5,a5,1
ffffffffc0206032:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc0206036:	02000793          	li	a5,32
ffffffffc020603a:	9f8d                	subw	a5,a5,a1
}
ffffffffc020603c:	00f5553b          	srlw	a0,a0,a5
ffffffffc0206040:	8082                	ret

ffffffffc0206042 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0206042:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0206046:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0206048:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020604c:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc020604e:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0206052:	f022                	sd	s0,32(sp)
ffffffffc0206054:	ec26                	sd	s1,24(sp)
ffffffffc0206056:	e84a                	sd	s2,16(sp)
ffffffffc0206058:	f406                	sd	ra,40(sp)
ffffffffc020605a:	e44e                	sd	s3,8(sp)
ffffffffc020605c:	84aa                	mv	s1,a0
ffffffffc020605e:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0206060:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0206064:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0206066:	03067e63          	bgeu	a2,a6,ffffffffc02060a2 <printnum+0x60>
ffffffffc020606a:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc020606c:	00805763          	blez	s0,ffffffffc020607a <printnum+0x38>
ffffffffc0206070:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0206072:	85ca                	mv	a1,s2
ffffffffc0206074:	854e                	mv	a0,s3
ffffffffc0206076:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0206078:	fc65                	bnez	s0,ffffffffc0206070 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020607a:	1a02                	slli	s4,s4,0x20
ffffffffc020607c:	00002797          	auipc	a5,0x2
ffffffffc0206080:	7e478793          	addi	a5,a5,2020 # ffffffffc0208860 <syscalls+0x100>
ffffffffc0206084:	020a5a13          	srli	s4,s4,0x20
ffffffffc0206088:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc020608a:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020608c:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0206090:	70a2                	ld	ra,40(sp)
ffffffffc0206092:	69a2                	ld	s3,8(sp)
ffffffffc0206094:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0206096:	85ca                	mv	a1,s2
ffffffffc0206098:	87a6                	mv	a5,s1
}
ffffffffc020609a:	6942                	ld	s2,16(sp)
ffffffffc020609c:	64e2                	ld	s1,24(sp)
ffffffffc020609e:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02060a0:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02060a2:	03065633          	divu	a2,a2,a6
ffffffffc02060a6:	8722                	mv	a4,s0
ffffffffc02060a8:	f9bff0ef          	jal	ra,ffffffffc0206042 <printnum>
ffffffffc02060ac:	b7f9                	j	ffffffffc020607a <printnum+0x38>

ffffffffc02060ae <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02060ae:	7119                	addi	sp,sp,-128
ffffffffc02060b0:	f4a6                	sd	s1,104(sp)
ffffffffc02060b2:	f0ca                	sd	s2,96(sp)
ffffffffc02060b4:	ecce                	sd	s3,88(sp)
ffffffffc02060b6:	e8d2                	sd	s4,80(sp)
ffffffffc02060b8:	e4d6                	sd	s5,72(sp)
ffffffffc02060ba:	e0da                	sd	s6,64(sp)
ffffffffc02060bc:	fc5e                	sd	s7,56(sp)
ffffffffc02060be:	f06a                	sd	s10,32(sp)
ffffffffc02060c0:	fc86                	sd	ra,120(sp)
ffffffffc02060c2:	f8a2                	sd	s0,112(sp)
ffffffffc02060c4:	f862                	sd	s8,48(sp)
ffffffffc02060c6:	f466                	sd	s9,40(sp)
ffffffffc02060c8:	ec6e                	sd	s11,24(sp)
ffffffffc02060ca:	892a                	mv	s2,a0
ffffffffc02060cc:	84ae                	mv	s1,a1
ffffffffc02060ce:	8d32                	mv	s10,a2
ffffffffc02060d0:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02060d2:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc02060d6:	5b7d                	li	s6,-1
ffffffffc02060d8:	00002a97          	auipc	s5,0x2
ffffffffc02060dc:	7b4a8a93          	addi	s5,s5,1972 # ffffffffc020888c <syscalls+0x12c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02060e0:	00003b97          	auipc	s7,0x3
ffffffffc02060e4:	9c8b8b93          	addi	s7,s7,-1592 # ffffffffc0208aa8 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02060e8:	000d4503          	lbu	a0,0(s10)
ffffffffc02060ec:	001d0413          	addi	s0,s10,1
ffffffffc02060f0:	01350a63          	beq	a0,s3,ffffffffc0206104 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc02060f4:	c121                	beqz	a0,ffffffffc0206134 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc02060f6:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02060f8:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc02060fa:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02060fc:	fff44503          	lbu	a0,-1(s0)
ffffffffc0206100:	ff351ae3          	bne	a0,s3,ffffffffc02060f4 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206104:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0206108:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc020610c:	4c81                	li	s9,0
ffffffffc020610e:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0206110:	5c7d                	li	s8,-1
ffffffffc0206112:	5dfd                	li	s11,-1
ffffffffc0206114:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0206118:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020611a:	fdd6059b          	addiw	a1,a2,-35
ffffffffc020611e:	0ff5f593          	zext.b	a1,a1
ffffffffc0206122:	00140d13          	addi	s10,s0,1
ffffffffc0206126:	04b56263          	bltu	a0,a1,ffffffffc020616a <vprintfmt+0xbc>
ffffffffc020612a:	058a                	slli	a1,a1,0x2
ffffffffc020612c:	95d6                	add	a1,a1,s5
ffffffffc020612e:	4194                	lw	a3,0(a1)
ffffffffc0206130:	96d6                	add	a3,a3,s5
ffffffffc0206132:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0206134:	70e6                	ld	ra,120(sp)
ffffffffc0206136:	7446                	ld	s0,112(sp)
ffffffffc0206138:	74a6                	ld	s1,104(sp)
ffffffffc020613a:	7906                	ld	s2,96(sp)
ffffffffc020613c:	69e6                	ld	s3,88(sp)
ffffffffc020613e:	6a46                	ld	s4,80(sp)
ffffffffc0206140:	6aa6                	ld	s5,72(sp)
ffffffffc0206142:	6b06                	ld	s6,64(sp)
ffffffffc0206144:	7be2                	ld	s7,56(sp)
ffffffffc0206146:	7c42                	ld	s8,48(sp)
ffffffffc0206148:	7ca2                	ld	s9,40(sp)
ffffffffc020614a:	7d02                	ld	s10,32(sp)
ffffffffc020614c:	6de2                	ld	s11,24(sp)
ffffffffc020614e:	6109                	addi	sp,sp,128
ffffffffc0206150:	8082                	ret
            padc = '0';
ffffffffc0206152:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0206154:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206158:	846a                	mv	s0,s10
ffffffffc020615a:	00140d13          	addi	s10,s0,1
ffffffffc020615e:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0206162:	0ff5f593          	zext.b	a1,a1
ffffffffc0206166:	fcb572e3          	bgeu	a0,a1,ffffffffc020612a <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc020616a:	85a6                	mv	a1,s1
ffffffffc020616c:	02500513          	li	a0,37
ffffffffc0206170:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0206172:	fff44783          	lbu	a5,-1(s0)
ffffffffc0206176:	8d22                	mv	s10,s0
ffffffffc0206178:	f73788e3          	beq	a5,s3,ffffffffc02060e8 <vprintfmt+0x3a>
ffffffffc020617c:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0206180:	1d7d                	addi	s10,s10,-1
ffffffffc0206182:	ff379de3          	bne	a5,s3,ffffffffc020617c <vprintfmt+0xce>
ffffffffc0206186:	b78d                	j	ffffffffc02060e8 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0206188:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc020618c:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206190:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0206192:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0206196:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc020619a:	02d86463          	bltu	a6,a3,ffffffffc02061c2 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc020619e:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02061a2:	002c169b          	slliw	a3,s8,0x2
ffffffffc02061a6:	0186873b          	addw	a4,a3,s8
ffffffffc02061aa:	0017171b          	slliw	a4,a4,0x1
ffffffffc02061ae:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc02061b0:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc02061b4:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02061b6:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc02061ba:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02061be:	fed870e3          	bgeu	a6,a3,ffffffffc020619e <vprintfmt+0xf0>
            if (width < 0)
ffffffffc02061c2:	f40ddce3          	bgez	s11,ffffffffc020611a <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc02061c6:	8de2                	mv	s11,s8
ffffffffc02061c8:	5c7d                	li	s8,-1
ffffffffc02061ca:	bf81                	j	ffffffffc020611a <vprintfmt+0x6c>
            if (width < 0)
ffffffffc02061cc:	fffdc693          	not	a3,s11
ffffffffc02061d0:	96fd                	srai	a3,a3,0x3f
ffffffffc02061d2:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02061d6:	00144603          	lbu	a2,1(s0)
ffffffffc02061da:	2d81                	sext.w	s11,s11
ffffffffc02061dc:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02061de:	bf35                	j	ffffffffc020611a <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc02061e0:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02061e4:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc02061e8:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02061ea:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc02061ec:	bfd9                	j	ffffffffc02061c2 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc02061ee:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02061f0:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02061f4:	01174463          	blt	a4,a7,ffffffffc02061fc <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc02061f8:	1a088e63          	beqz	a7,ffffffffc02063b4 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc02061fc:	000a3603          	ld	a2,0(s4)
ffffffffc0206200:	46c1                	li	a3,16
ffffffffc0206202:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0206204:	2781                	sext.w	a5,a5
ffffffffc0206206:	876e                	mv	a4,s11
ffffffffc0206208:	85a6                	mv	a1,s1
ffffffffc020620a:	854a                	mv	a0,s2
ffffffffc020620c:	e37ff0ef          	jal	ra,ffffffffc0206042 <printnum>
            break;
ffffffffc0206210:	bde1                	j	ffffffffc02060e8 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0206212:	000a2503          	lw	a0,0(s4)
ffffffffc0206216:	85a6                	mv	a1,s1
ffffffffc0206218:	0a21                	addi	s4,s4,8
ffffffffc020621a:	9902                	jalr	s2
            break;
ffffffffc020621c:	b5f1                	j	ffffffffc02060e8 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020621e:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0206220:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0206224:	01174463          	blt	a4,a7,ffffffffc020622c <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0206228:	18088163          	beqz	a7,ffffffffc02063aa <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc020622c:	000a3603          	ld	a2,0(s4)
ffffffffc0206230:	46a9                	li	a3,10
ffffffffc0206232:	8a2e                	mv	s4,a1
ffffffffc0206234:	bfc1                	j	ffffffffc0206204 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206236:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc020623a:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020623c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020623e:	bdf1                	j	ffffffffc020611a <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0206240:	85a6                	mv	a1,s1
ffffffffc0206242:	02500513          	li	a0,37
ffffffffc0206246:	9902                	jalr	s2
            break;
ffffffffc0206248:	b545                	j	ffffffffc02060e8 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020624a:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc020624e:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206250:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0206252:	b5e1                	j	ffffffffc020611a <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0206254:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0206256:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020625a:	01174463          	blt	a4,a7,ffffffffc0206262 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc020625e:	14088163          	beqz	a7,ffffffffc02063a0 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0206262:	000a3603          	ld	a2,0(s4)
ffffffffc0206266:	46a1                	li	a3,8
ffffffffc0206268:	8a2e                	mv	s4,a1
ffffffffc020626a:	bf69                	j	ffffffffc0206204 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc020626c:	03000513          	li	a0,48
ffffffffc0206270:	85a6                	mv	a1,s1
ffffffffc0206272:	e03e                	sd	a5,0(sp)
ffffffffc0206274:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0206276:	85a6                	mv	a1,s1
ffffffffc0206278:	07800513          	li	a0,120
ffffffffc020627c:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020627e:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0206280:	6782                	ld	a5,0(sp)
ffffffffc0206282:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0206284:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0206288:	bfb5                	j	ffffffffc0206204 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020628a:	000a3403          	ld	s0,0(s4)
ffffffffc020628e:	008a0713          	addi	a4,s4,8
ffffffffc0206292:	e03a                	sd	a4,0(sp)
ffffffffc0206294:	14040263          	beqz	s0,ffffffffc02063d8 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0206298:	0fb05763          	blez	s11,ffffffffc0206386 <vprintfmt+0x2d8>
ffffffffc020629c:	02d00693          	li	a3,45
ffffffffc02062a0:	0cd79163          	bne	a5,a3,ffffffffc0206362 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02062a4:	00044783          	lbu	a5,0(s0)
ffffffffc02062a8:	0007851b          	sext.w	a0,a5
ffffffffc02062ac:	cf85                	beqz	a5,ffffffffc02062e4 <vprintfmt+0x236>
ffffffffc02062ae:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02062b2:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02062b6:	000c4563          	bltz	s8,ffffffffc02062c0 <vprintfmt+0x212>
ffffffffc02062ba:	3c7d                	addiw	s8,s8,-1
ffffffffc02062bc:	036c0263          	beq	s8,s6,ffffffffc02062e0 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc02062c0:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02062c2:	0e0c8e63          	beqz	s9,ffffffffc02063be <vprintfmt+0x310>
ffffffffc02062c6:	3781                	addiw	a5,a5,-32
ffffffffc02062c8:	0ef47b63          	bgeu	s0,a5,ffffffffc02063be <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc02062cc:	03f00513          	li	a0,63
ffffffffc02062d0:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02062d2:	000a4783          	lbu	a5,0(s4)
ffffffffc02062d6:	3dfd                	addiw	s11,s11,-1
ffffffffc02062d8:	0a05                	addi	s4,s4,1
ffffffffc02062da:	0007851b          	sext.w	a0,a5
ffffffffc02062de:	ffe1                	bnez	a5,ffffffffc02062b6 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc02062e0:	01b05963          	blez	s11,ffffffffc02062f2 <vprintfmt+0x244>
ffffffffc02062e4:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc02062e6:	85a6                	mv	a1,s1
ffffffffc02062e8:	02000513          	li	a0,32
ffffffffc02062ec:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc02062ee:	fe0d9be3          	bnez	s11,ffffffffc02062e4 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02062f2:	6a02                	ld	s4,0(sp)
ffffffffc02062f4:	bbd5                	j	ffffffffc02060e8 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02062f6:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02062f8:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc02062fc:	01174463          	blt	a4,a7,ffffffffc0206304 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0206300:	08088d63          	beqz	a7,ffffffffc020639a <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0206304:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0206308:	0a044d63          	bltz	s0,ffffffffc02063c2 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc020630c:	8622                	mv	a2,s0
ffffffffc020630e:	8a66                	mv	s4,s9
ffffffffc0206310:	46a9                	li	a3,10
ffffffffc0206312:	bdcd                	j	ffffffffc0206204 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0206314:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0206318:	4761                	li	a4,24
            err = va_arg(ap, int);
ffffffffc020631a:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc020631c:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0206320:	8fb5                	xor	a5,a5,a3
ffffffffc0206322:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0206326:	02d74163          	blt	a4,a3,ffffffffc0206348 <vprintfmt+0x29a>
ffffffffc020632a:	00369793          	slli	a5,a3,0x3
ffffffffc020632e:	97de                	add	a5,a5,s7
ffffffffc0206330:	639c                	ld	a5,0(a5)
ffffffffc0206332:	cb99                	beqz	a5,ffffffffc0206348 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0206334:	86be                	mv	a3,a5
ffffffffc0206336:	00000617          	auipc	a2,0x0
ffffffffc020633a:	1ca60613          	addi	a2,a2,458 # ffffffffc0206500 <etext+0x2a>
ffffffffc020633e:	85a6                	mv	a1,s1
ffffffffc0206340:	854a                	mv	a0,s2
ffffffffc0206342:	0ce000ef          	jal	ra,ffffffffc0206410 <printfmt>
ffffffffc0206346:	b34d                	j	ffffffffc02060e8 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0206348:	00002617          	auipc	a2,0x2
ffffffffc020634c:	53860613          	addi	a2,a2,1336 # ffffffffc0208880 <syscalls+0x120>
ffffffffc0206350:	85a6                	mv	a1,s1
ffffffffc0206352:	854a                	mv	a0,s2
ffffffffc0206354:	0bc000ef          	jal	ra,ffffffffc0206410 <printfmt>
ffffffffc0206358:	bb41                	j	ffffffffc02060e8 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc020635a:	00002417          	auipc	s0,0x2
ffffffffc020635e:	51e40413          	addi	s0,s0,1310 # ffffffffc0208878 <syscalls+0x118>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0206362:	85e2                	mv	a1,s8
ffffffffc0206364:	8522                	mv	a0,s0
ffffffffc0206366:	e43e                	sd	a5,8(sp)
ffffffffc0206368:	0e2000ef          	jal	ra,ffffffffc020644a <strnlen>
ffffffffc020636c:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0206370:	01b05b63          	blez	s11,ffffffffc0206386 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0206374:	67a2                	ld	a5,8(sp)
ffffffffc0206376:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020637a:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc020637c:	85a6                	mv	a1,s1
ffffffffc020637e:	8552                	mv	a0,s4
ffffffffc0206380:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0206382:	fe0d9ce3          	bnez	s11,ffffffffc020637a <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0206386:	00044783          	lbu	a5,0(s0)
ffffffffc020638a:	00140a13          	addi	s4,s0,1
ffffffffc020638e:	0007851b          	sext.w	a0,a5
ffffffffc0206392:	d3a5                	beqz	a5,ffffffffc02062f2 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0206394:	05e00413          	li	s0,94
ffffffffc0206398:	bf39                	j	ffffffffc02062b6 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc020639a:	000a2403          	lw	s0,0(s4)
ffffffffc020639e:	b7ad                	j	ffffffffc0206308 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc02063a0:	000a6603          	lwu	a2,0(s4)
ffffffffc02063a4:	46a1                	li	a3,8
ffffffffc02063a6:	8a2e                	mv	s4,a1
ffffffffc02063a8:	bdb1                	j	ffffffffc0206204 <vprintfmt+0x156>
ffffffffc02063aa:	000a6603          	lwu	a2,0(s4)
ffffffffc02063ae:	46a9                	li	a3,10
ffffffffc02063b0:	8a2e                	mv	s4,a1
ffffffffc02063b2:	bd89                	j	ffffffffc0206204 <vprintfmt+0x156>
ffffffffc02063b4:	000a6603          	lwu	a2,0(s4)
ffffffffc02063b8:	46c1                	li	a3,16
ffffffffc02063ba:	8a2e                	mv	s4,a1
ffffffffc02063bc:	b5a1                	j	ffffffffc0206204 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc02063be:	9902                	jalr	s2
ffffffffc02063c0:	bf09                	j	ffffffffc02062d2 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc02063c2:	85a6                	mv	a1,s1
ffffffffc02063c4:	02d00513          	li	a0,45
ffffffffc02063c8:	e03e                	sd	a5,0(sp)
ffffffffc02063ca:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc02063cc:	6782                	ld	a5,0(sp)
ffffffffc02063ce:	8a66                	mv	s4,s9
ffffffffc02063d0:	40800633          	neg	a2,s0
ffffffffc02063d4:	46a9                	li	a3,10
ffffffffc02063d6:	b53d                	j	ffffffffc0206204 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc02063d8:	03b05163          	blez	s11,ffffffffc02063fa <vprintfmt+0x34c>
ffffffffc02063dc:	02d00693          	li	a3,45
ffffffffc02063e0:	f6d79de3          	bne	a5,a3,ffffffffc020635a <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc02063e4:	00002417          	auipc	s0,0x2
ffffffffc02063e8:	49440413          	addi	s0,s0,1172 # ffffffffc0208878 <syscalls+0x118>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02063ec:	02800793          	li	a5,40
ffffffffc02063f0:	02800513          	li	a0,40
ffffffffc02063f4:	00140a13          	addi	s4,s0,1
ffffffffc02063f8:	bd6d                	j	ffffffffc02062b2 <vprintfmt+0x204>
ffffffffc02063fa:	00002a17          	auipc	s4,0x2
ffffffffc02063fe:	47fa0a13          	addi	s4,s4,1151 # ffffffffc0208879 <syscalls+0x119>
ffffffffc0206402:	02800513          	li	a0,40
ffffffffc0206406:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020640a:	05e00413          	li	s0,94
ffffffffc020640e:	b565                	j	ffffffffc02062b6 <vprintfmt+0x208>

ffffffffc0206410 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0206410:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0206412:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0206416:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0206418:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020641a:	ec06                	sd	ra,24(sp)
ffffffffc020641c:	f83a                	sd	a4,48(sp)
ffffffffc020641e:	fc3e                	sd	a5,56(sp)
ffffffffc0206420:	e0c2                	sd	a6,64(sp)
ffffffffc0206422:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0206424:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0206426:	c89ff0ef          	jal	ra,ffffffffc02060ae <vprintfmt>
}
ffffffffc020642a:	60e2                	ld	ra,24(sp)
ffffffffc020642c:	6161                	addi	sp,sp,80
ffffffffc020642e:	8082                	ret

ffffffffc0206430 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0206430:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0206434:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0206436:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0206438:	cb81                	beqz	a5,ffffffffc0206448 <strlen+0x18>
        cnt ++;
ffffffffc020643a:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc020643c:	00a707b3          	add	a5,a4,a0
ffffffffc0206440:	0007c783          	lbu	a5,0(a5)
ffffffffc0206444:	fbfd                	bnez	a5,ffffffffc020643a <strlen+0xa>
ffffffffc0206446:	8082                	ret
    }
    return cnt;
}
ffffffffc0206448:	8082                	ret

ffffffffc020644a <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc020644a:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc020644c:	e589                	bnez	a1,ffffffffc0206456 <strnlen+0xc>
ffffffffc020644e:	a811                	j	ffffffffc0206462 <strnlen+0x18>
        cnt ++;
ffffffffc0206450:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0206452:	00f58863          	beq	a1,a5,ffffffffc0206462 <strnlen+0x18>
ffffffffc0206456:	00f50733          	add	a4,a0,a5
ffffffffc020645a:	00074703          	lbu	a4,0(a4)
ffffffffc020645e:	fb6d                	bnez	a4,ffffffffc0206450 <strnlen+0x6>
ffffffffc0206460:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0206462:	852e                	mv	a0,a1
ffffffffc0206464:	8082                	ret

ffffffffc0206466 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0206466:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0206468:	0005c703          	lbu	a4,0(a1)
ffffffffc020646c:	0785                	addi	a5,a5,1
ffffffffc020646e:	0585                	addi	a1,a1,1
ffffffffc0206470:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0206474:	fb75                	bnez	a4,ffffffffc0206468 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0206476:	8082                	ret

ffffffffc0206478 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0206478:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020647c:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0206480:	cb89                	beqz	a5,ffffffffc0206492 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0206482:	0505                	addi	a0,a0,1
ffffffffc0206484:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0206486:	fee789e3          	beq	a5,a4,ffffffffc0206478 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020648a:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc020648e:	9d19                	subw	a0,a0,a4
ffffffffc0206490:	8082                	ret
ffffffffc0206492:	4501                	li	a0,0
ffffffffc0206494:	bfed                	j	ffffffffc020648e <strcmp+0x16>

ffffffffc0206496 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0206496:	00054783          	lbu	a5,0(a0)
ffffffffc020649a:	c799                	beqz	a5,ffffffffc02064a8 <strchr+0x12>
        if (*s == c) {
ffffffffc020649c:	00f58763          	beq	a1,a5,ffffffffc02064aa <strchr+0x14>
    while (*s != '\0') {
ffffffffc02064a0:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc02064a4:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc02064a6:	fbfd                	bnez	a5,ffffffffc020649c <strchr+0x6>
    }
    return NULL;
ffffffffc02064a8:	4501                	li	a0,0
}
ffffffffc02064aa:	8082                	ret

ffffffffc02064ac <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc02064ac:	ca01                	beqz	a2,ffffffffc02064bc <memset+0x10>
ffffffffc02064ae:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc02064b0:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc02064b2:	0785                	addi	a5,a5,1
ffffffffc02064b4:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc02064b8:	fec79de3          	bne	a5,a2,ffffffffc02064b2 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc02064bc:	8082                	ret

ffffffffc02064be <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc02064be:	ca19                	beqz	a2,ffffffffc02064d4 <memcpy+0x16>
ffffffffc02064c0:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc02064c2:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc02064c4:	0005c703          	lbu	a4,0(a1)
ffffffffc02064c8:	0585                	addi	a1,a1,1
ffffffffc02064ca:	0785                	addi	a5,a5,1
ffffffffc02064cc:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc02064d0:	fec59ae3          	bne	a1,a2,ffffffffc02064c4 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc02064d4:	8082                	ret
