# lab3
## 练习零

+ 在`alloc_proc`中添加额外的初始化：

  ```c
  proc->wait_state = 0;
  proc->cptr = NULL; // Child Pointer 表示当前进程的子进程
  proc->optr = NULL; // Older Sibling Pointer 表示当前进程的上一个兄弟进程
  proc->yptr = NULL; // Younger Sibling Pointer 表示当前进程的下一个兄弟进程
  ```

+ 在`do_fork`中修改代码如下：

  ```c
  if((proc = alloc_proc()) == NULL)
  {
      goto fork_out;
  }
  proc->parent = current; // 添加
  assert(current->wait_state == 0);
  if(setup_kstack(proc) != 0)
  {
      goto bad_fork_cleanup_proc;
  }
  ;
  if(copy_mm(clone_flags, proc) != 0)
  {
      goto bad_fork_cleanup_kstack;
  }
  copy_thread(proc, stack, tf);
  bool intr_flag;
  local_intr_save(intr_flag);
  {
      int pid = get_pid();
      proc->pid = pid;
      hash_proc(proc);
      set_links(proc);
  }
  local_intr_restore(intr_flag);
  wakeup_proc(proc);
  ret = proc->pid;
  ```

## 练习1: 加载应用程序并执行（2213028-黄煜斐）

> **do_execv**函数调用`load_icode`（位于kern/process/proc.c中）来加载并解析一个处于内存中的ELF执行文件格式的应用程序。你需要补充`load_icode`的第6步，建立相应的用户内存空间来放置应用程序的代码段、数据段等，且要设置好`proc_struct`结构中的成员变量trapframe中的内容，确保在执行此进程后，能够从应用程序设定的起始执行地址开始执行。
>
> 请在实验报告中简要说明你的设计实现过程。
>
> - 请简要描述这个用户态进程被ucore选择占用CPU执行（RUNNING态）到具体执行应用程序第一条指令的整个经过。



```c++
static int
load_icode(unsigned char *binary, size_t size) {
    if (current->mm != NULL) {
        panic("load_icode: current->mm must be empty.\n");
    }

    int ret = -E_NO_MEM;
    struct mm_struct *mm;
    //(1) create a new mm for current process
    if ((mm = mm_create()) == NULL) {
        goto bad_mm;
    }
    //(2) create a new PDT, and mm->pgdir= kernel virtual addr of PDT
    if (setup_pgdir(mm) != 0) {
        goto bad_pgdir_cleanup_mm;
    }
    //(3) copy TEXT/DATA section, build BSS parts in binary to memory space of process
    struct Page *page;
    //(3.1) get the file header of the bianry program (ELF format)
    struct elfhdr *elf = (struct elfhdr *)binary;
    //(3.2) get the entry of the program section headers of the bianry program (ELF format)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
    //(3.3) This program is valid?
    if (elf->e_magic != ELF_MAGIC) {
        ret = -E_INVAL_ELF;
        goto bad_elf_cleanup_pgdir;
    }

    uint32_t vm_flags, perm;
    struct proghdr *ph_end = ph + elf->e_phnum;
    for (; ph < ph_end; ph ++) {
    //(3.4) find every program section headers
        if (ph->p_type != ELF_PT_LOAD) {
            continue ;
        }
        if (ph->p_filesz > ph->p_memsz) {
            ret = -E_INVAL_ELF;
            goto bad_cleanup_mmap;
        }
        if (ph->p_filesz == 0) {
            // continue ;
        }
    //(3.5) call mm_map fun to setup the new vma ( ph->p_va, ph->p_memsz)
        vm_flags = 0, perm = PTE_U | PTE_V;
        if (ph->p_flags & ELF_PF_X) vm_flags |= VM_EXEC;
        if (ph->p_flags & ELF_PF_W) vm_flags |= VM_WRITE;
        if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ;
        // modify the perm bits here for RISC-V
        if (vm_flags & VM_READ) perm |= PTE_R;
        if (vm_flags & VM_WRITE) perm |= (PTE_W | PTE_R);
        if (vm_flags & VM_EXEC) perm |= PTE_X;
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0) {
            goto bad_cleanup_mmap;
        }
        unsigned char *from = binary + ph->p_offset;
        size_t off, size;
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);

        ret = -E_NO_MEM;

     //(3.6) alloc memory, and  copy the contents of every program section (from, from+end) to process's memory (la, la+end)
        end = ph->p_va + ph->p_filesz;
     //(3.6.1) copy TEXT/DATA section of bianry program
        while (start < end) {
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL) {
                goto bad_cleanup_mmap;
            }
            off = start - la, size = PGSIZE - off, la += PGSIZE;
            if (end < la) {
                size -= la - end;
            }
            memcpy(page2kva(page) + off, from, size);
            start += size, from += size;
        }

      //(3.6.2) build BSS section of binary program
        end = ph->p_va + ph->p_memsz;
        if (start < la) {
            /* ph->p_memsz == ph->p_filesz */
            if (start == end) {
                continue ;
            }
            off = start + PGSIZE - la, size = PGSIZE - off;
            if (end < la) {
                size -= la - end;
            }
            memset(page2kva(page) + off, 0, size);
            start += size;
            assert((end < la && start == end) || (end >= la && start == la));
        }
        while (start < end) {
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL) {
                goto bad_cleanup_mmap;
            }
            off = start - la, size = PGSIZE - off, la += PGSIZE;
            if (end < la) {
                size -= la - end;
            }
            memset(page2kva(page) + off, 0, size);
            start += size;
        }
    }
    //(4) build user stack memory
    vm_flags = VM_READ | VM_WRITE | VM_STACK;
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0) {
        goto bad_cleanup_mmap;
    }
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-PGSIZE , PTE_USER) != NULL);
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-2*PGSIZE , PTE_USER) != NULL);
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-3*PGSIZE , PTE_USER) != NULL);
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-4*PGSIZE , PTE_USER) != NULL);
    
    //(5) set current process's mm, sr3, and set CR3 reg = physical addr of Page Directory
    mm_count_inc(mm);
    current->mm = mm;
    current->cr3 = PADDR(mm->pgdir);
    lcr3(PADDR(mm->pgdir));

    //(6) setup trapframe for user environment
    struct trapframe *tf = current->tf;
    // Keep sstatus
    uintptr_t sstatus = tf->status;
    memset(tf, 0, sizeof(struct trapframe));
    /* LAB5:EXERCISE1 YOUR CODE
     * should set tf->gpr.sp, tf->epc, tf->status
     * NOTICE: If we set trapframe correctly, then the user level process can return to USER MODE from kernel. So
     *          tf->gpr.sp should be user stack top (the value of sp)
     *          tf->epc should be entry point of user program (the value of sepc)
     *          tf->status should be appropriate for user program (the value of sstatus)
     *          hint: check meaning of SPP, SPIE in SSTATUS, use them by SSTATUS_SPP, SSTATUS_SPIE(defined in risv.h)
     */

    tf->gpr.sp = USTACKTOP;
    tf->epc = elf->e_entry;
    // sstatus &= ~SSTATUS_SPP;
    // sstatus &= SSTATUS_SPIE;
    // tf->status = sstatus;
    tf->status = sstatus & ~(SSTATUS_SPP | SSTATUS_SPIE);

    ret = 0;
out:
    return ret;
bad_cleanup_mmap:
    exit_mmap(mm);
bad_elf_cleanup_pgdir:
    put_pgdir(mm);
bad_pgdir_cleanup_mm:
    mm_destroy(mm);
bad_mm:
    goto out;
}
```

在函数中主要修改了以下这段代码：

```c++
tf->gpr.sp = USTACKTOP;
tf->epc = elf->e_entry;
tf->status = sstatus & ~(SSTATUS_SPP | SSTATUS_SPIE);
```
**1. `tf->gpr.sp = USTACKTOP;`**
设置用户栈顶指针（`sp`）的位置，

**2.`tf->epc = elf->e_entry;`**
`epc`设置为文件的入口地址，设置应用程序在用户空间开始执行的起始地址

 **3.`tf->status = sstatus & ~(SSTATUS_SPP | SSTATUS_SPIE);`**
该行代码用于设置处理器的状态寄存器相关标志位，以确保在从内核态切换到用户态后，处理器处于适合应用程序执行的正确状态，涉及到权限级别、中断使能等关键状态的设置。`sstatus`的`SPP`位清零，代表异常来自用户态，之后需要返回用户态；`SPIE`位清零，表示不启用中断。

**load_icode函数流程**

1. 初始检查与初始化
   - 检查当前进程内存管理结构体是否为空，否则报错。初始化返回值 `ret` 为错误码 `-E_NO_MEM`，创建新内存管理结构体 `mm`，创建失败则跳转处理并返回。
2. 创建页目录并关联
   - 调用 `setup_pgdir(mm)` 创建页目录，若失败则跳转清理并返回。
3. 处理二进制文件各段
   - 获取文件头与段头信息：通过指针转换获取 ELF 文件头及程序段头信息，验证文件合法性，不符则设错误码并跳转处理。
   - 遍历段头处理各段：循环遍历程序段头，对可加载段依其属性设置虚拟内存与页表权限，映射虚拟内存区域，失败则跳转处理。再分别复制 TEXT/DATA 段内容、构建并初始化 BSS 段内存空间。
4. 建立用户栈内存
   - 按属性为用户栈分配虚拟内存，失败则跳转处理，并用 `assert` 确保关键物理页分配成功。
5. 更新进程相关信息
   - 增加 `mm` 引用计数，关联当前进程与 `mm`，设置相关寄存器指向新页目录，完成内存管理切换。
6. 设置陷阱帧信息
   - 获取陷阱帧指针，保存 `sstatus` 值后清零陷阱帧。接着设置用户栈顶指针、程序起始执行地址及处理器状态相关标志位，确保切换到用户态后能正确执行应用程序。
7. 函数返回
   - 设置 `ret` 为 `0` 表示成功并返回，若之前步骤出错则经对应清理操作后返回错误码。

### **用户态进程被ucore选择占用CPU执行（RUNNING态）到具体执行应用程序第一条指令的整个经过**

1. 从 proc_init 到 cpu_idle
   - proc_init 创建了 idle（第 0 个内核线程），然后通过 kernel_thread 创建了 init（第一个内核线程）。
   - cpu_idle 会不断查询 need_resched 标志位，若满足条件则调用 schedule 函数进行调度。
2. 调度与进程切换
   - 在 schedule 函数找到第一个可以调度的线程后，调用 proc_run 函数来切换到新进程。
   - proc_run 调用了 lcr3 和 switch_to，然后返回到 kernel_thread_entry 去执行指定的函数，这里是 initproc 线程的主函数 init_main。
3. init_main 中的操作
   - 在 init_main 中再次调用 kernel_thread 创建 user_main 函数对应的线程。
   - user_main 函数在缺省时会调用 KERNEL_EXECVE (exit)，KERNEL_EXECVE 宏最终调用 kernel_execve 函数。
   - kernel_execve 函数通过内联汇编调用，使用 ebreak 指令产生断点中断（设置 a7 寄存器的值为 10 表明这不是普通断点中断），在 trap.c 文件中处理断点时调用 syscall 函数。
   - kernel_execve 函数的内联汇编将 sysexec 宏放入 a0 寄存器，执行一个系统调用，对应的函数是 sys_exec 函数，sys_exec 函数调用 do_execve 函数。
   - do_execve 函数中调用 load_icode 函数来加载新的二进制程序到内存中，并设置中断帧内容（SPP 设置为 0），以便后续直接返回到用户态。
4. 进程等待与调度
   - 创建完 user_main 线程后，init_main 函数调用 do_wait 函数释放资源。
   - 当前进程将自身状态设置为 sleeping，等待状态设为 WT_CHILD，并调用 schedule 函数进行调度。
   - 此时调度选中 user_main 进行执行，加载二进制程序（将 exit 应用程序执行码覆盖到 user_main 的用户虚拟内存空间），执行 kernel_execve_ret 函数，最后通过 sret 退出到用户态。
5. 用户态执行
   - 开始执行 initcode.S 中的代码，然后执行 umian 函数，其中会先执行用户态进程 exit.c 文件中的主体函数，然后执行 exit 函数进行退出。
   - 在 exit 的主体 mian 函数中，调用 fork 函数 fork 出一个子进程，然后在 wait 函数中进行进程切换并重新执行，后续父进程将 fork 出来的子进程回收，父进程自己也退出，一直回到 initproc 这个内核线程，最后通过 do_exit 函数的 panic 结束实验。


## 练习2: 父进程复制自己的内存空间给子进程（需要编码）（2211877-王竞苒）

### 1. 实验要求

创建子进程的函数`do_fork`在执行中将拷贝当前进程（即父进程）的用户内存地址空间中的合法内容到新进程中（子进程），完成内存资源的复制。具体是通过`copy_range`函数（位于kern/mm/pmm.c中）实现的，请补充`copy_range`的实现，确保能够正确执行。

请在实验报告中简要说明你的设计实现过程。

- 如何设计实现`Copy on Write`机制？给出概要设计，鼓励给出详细设计。

### 2. 实验过程

#### - **`copy_range`代码实现**

```c++
int copy_range(pde_t *to, pde_t *from, uintptr_t start, uintptr_t end,
               bool share) {
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
    assert(USER_ACCESS(start, end));
    do {
        pte_t *ptep = get_pte(from, start, 0), *nptep;
        if (ptep == NULL) {
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
            continue;
        }
        if (*ptep & PTE_V) {
            if ((nptep = get_pte(to, start, 1)) == NULL) {
                return -E_NO_MEM;
            }
            uint32_t perm = (*ptep & PTE_USER);
            // get page from ptep
            struct Page *page = pte2page(*ptep);
            // alloc a page for process B
            struct Page *npage = alloc_page();
            assert(page != NULL);
            assert(npage != NULL);
            int ret = 0;
            
            // 第一步：获取源页面的内核虚拟地址
            void *src_kvaddr = page2kva(page);
            // 第二步：获取目标页面的内核虚拟地址
            void *dst_kvaddr = page2kva(npage);
            // 第三步：复制内存（源页面内容复制到目标页面）
            memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
            // 第四步：将新页面插入目标进程的页面表
            // 使用 page_insert 将新页面在目标进程的虚拟地址 `start` 上映射
            ret = page_insert(to, npage, start, perm );
           
            assert(ret == 0);
        }
        start += PGSIZE;
    } while (start != 0 && start < end);
    return 0;
}

```

**代码分析**

```
get_pte(from, start, 0)
```
获取父进程中`start`地址对应的页表项。`get_pte`函数会返回一个指向该页表项的指针。若该地址未映射（即页表项为空），则返回`NULL`。
```
get_pte(to, start, 1)
```
在目标进程中获取`start`地址对应的页表项，如果目标页表项为空，则分配一个新的页表（`1`表示需要分配新的页表项）。
```
pte2page(\*ptep)
```
将页表项转化为对应的物理页面。`*ptep`是页表项，`pte2page`函数会提取出该页表项对应的物理页。

```
alloc_page()
```
为目标进程分配一个新的物理页面，并返回该页面的结构体指针。
```
page2kva(page)
```
获取物理页面对应的内核虚拟地址。`page2kva`将物理页面转换为内核虚拟地址，便于操作。
```
void *src_kvaddr = page2kva(page);
void *dst_kvaddr = page2kva(npage);
memcpy(dst_kvaddr, src_kvaddr, PGSIZE)
```
将源进程的页面内容复制到目标进程的页面。这是一个典型的内存复制操作，首先通过 `page2kva(page)` 和 `page2kva(npage)` 获取源页面和目标页面的内核虚拟地址，然后使用 `memcpy` 将数据从源内存复制到目标内存。复制的大小是 `PGSIZE`（通常是 4KB）。

```
ret = page_insert(to, npage, start, perm);
assert(ret == 0);
```

通过 `page_insert` 将新分配的物理页面 `npage` 插入到目标进程的页表中，映射到目标虚拟地址 `start`，并且继承源进程的权限 `perm`。如果插入失败，则通过 `assert` 触发异常。



#### - **实现`Copy on Write`机制**

Copy-on-Write（COW）是一种优化内存管理和性能的技术，广泛应用于操作系统的虚拟内存管理、文件系统、甚至某些高级编程语言中的数据结构。其基本思想是当多个进程或线程共享同一资源时（如内存页、数组等），直到某个进程尝试修改该资源时，系统才会创建资源的副本。这种延迟复制的策略不仅节省了内存，还提升了性能，尤其在有大量只读操作的情况下。

##### 1. COW 机制设计概要

COW 机制的核心在于延迟复制，资源只有在被修改时才会被复制。这可以有效避免不必要的内存消耗。在具体实现时，可以分为以下几个步骤：

1. **共享资源初始化**：
   
   初始时，多个用户（进程、线程、对象等）共享同一资源。当一个用户请求资源时，它只获得该资源的引用或指针，而不进行实际的复制。
2. **标记资源为只读**：
   
   资源的内存页面或数据块应被标记为只读。每个使用者都拥有该资源的只读访问权限。
3. **检测写操作**：
   
   当某个用户试图对资源进行写操作时，系统必须检测到这个写操作并触发复制。操作系统或内存管理单元（MMU）通过硬件或软件方式来捕捉这个“写入”的事件。通常，通过页错误（page fault）来触发。
4. **执行资源复制**：
   
   当写操作被检测到时，系统会创建资源的副本，并将副本提供给试图写入的进程。此时，原资源的状态保持不变，原始资源对于其他使用者来说仍然是只读的。
5. **更新指针**：
   
   写操作的进程会得到新副本的指针，并且对副本进行修改。其他进程仍然访问原始资源，直到它们也进行写操作。
6. **垃圾回收和资源释放**：
   
   在没有任何进程使用某个资源时，系统可以回收这些资源，以减少内存消耗。

##### 2. 详细设计

##### 2.1 数据结构设计

为了实现 COW 机制，设计需要考虑内存页面（Page）管理和引用计数（Reference Count）。每个资源应该有一个共享的元数据结构，用于跟踪资源的使用情况。

```
ctypedef struct Resource {
    void *data;            // 指向实际数据的指针
    int ref_count;         // 引用计数
    bool is_cow;           // 标记是否处于 COW 状态
} Resource;
```
 `data`: 实际数据的指针，可能指向共享内存页。
 `ref_count`: 引用计数，跟踪有多少用户（进程或线程）正在共享这个资源。
 `is_cow`: 如果资源处于 COW 状态，则为 `true`，否则为 `false`。

##### 2.2 操作系统层面的设计

在操作系统中，内存管理单元（MMU）或虚拟内存管理器需要参与 COW 的实现。以下是操作系统中实现 COW 的设计：

- **2.2.1 内存页管理**

在操作系统的虚拟内存中，每一页内存都可以被多个进程共享。一个内存页面可能指向共享数据，操作系统需要标记这些页面为只读，并在检测到写操作时触发复制。

```
ctypedef struct Page {
    void *address;       // 页的物理地址
    bool is_readonly;    // 是否为只读
    bool is_cow;         // 是否是 COW 页面
    Resource *resource;  // 资源引用
} Page;
```

- **2.2.2 写时复制触发机制**

操作系统需要捕获写时的页面错误（page fault）。一旦检测到某个进程尝试写入一个 COW 页面，操作系统应触发页面复制操作：

**页面错误捕获**：如果一个页面处于只读状态，而进程尝试对其进行写操作，操作系统通过页错误处理程序来捕获该事件。

**页面复制**：操作系统将 COW 页面复制到一个新的物理内存区域，并返回新的内存地址给进程。新的页面会被标记为可读写，且其他进程继续访问原页面。

- **2.2.3进程间的引用计数**

每个进程持有的资源应通过引用计数来跟踪，以便在最后一个进程释放资源时，进行资源清理和内存回收。引用计数变化发生在共享资源或 COW 资源的访问时。

```
cvoid reference(Resource *resource) {
    resource->ref_count++;
}

void dereference(Resource *resource) {
    resource->ref_count--;
    if (resource->ref_count == 0) {
        free(resource->data);  // 释放资源
        free(resource);
    }
}
```

##### 2.3 用户代码和 API 设计

用户程序通过 API 接口来请求资源，并在需要时触发 COW 操作。用户的接口设计应该简单且直观，避免直接与内存管理细节打交道。

```
c// 获取资源，初始为共享，只读
Resource* acquire_resource(void *data) {
    Resource *resource = allocate_resource(data);
    reference(resource);
    return resource;
}

// 获取 COW 资源的副本
Resource* write_to_resource(Resource *resource) {
    if (resource->is_cow) {
        // 触发页面复制
        resource = copy_resource(resource);
    }
    return resource;
}

// 释放资源
void release_resource(Resource *resource) {
    dereference(resource);
}
```

`acquire_resource`：用户请求资源时，返回一个共享资源，默认是只读的。

`write_to_resource`：当用户需要写入时，触发 COW 机制，进行资源复制，确保数据不被其他进程修改。

`release_resource`：资源使用完后，用户通过这个函数释放资源。


## 练习3：阅读分析源代码，理解进程执行fork/exec/wait/exit 的实现，以及系统调用的实现（2213400-王婧怡）

### 1. 实验要求

请在实验报告中简要说明你对 fork/exec/wait/exit函数的分析。并回答如下问题：

请分析fork/exec/wait/exit的执行流程。重点关注哪些操作是在用户态完成，哪些是在内核态完成？内核态与用户态程序是如何交错执行的？内核态执行结果是如何返回给用户程序的？
请给出ucore中一个用户态进程的执行状态生命周期图（包执行状态，执行状态之间的变换关系，以及产生变换的事件或函数调用）。（字符方式画即可）

执行：make grade。如果所显示的应用程序检测都输出ok，则基本正确。（使用的是qemu-1.0.1）

### 2. 问题回答

**2.1 fork/exec/wait/exit的执行流程分析**

**2.1.1 fork()**

**用户态：**

用户程序调用fork()，它是对sys_fork()的封装。
sys_fork()通过ecall触发系统调用，进入内核态。

**内核态：**

sys_fork()调用do_fork()，完成以下操作：

创建新的进程控制块（PCB）。
复制父进程的内存空间（页表）、寄存器上下文及文件描述符。
将新进程的状态设为PROC_RUNNABLE，并加入调度队列。
do_fork()返回新进程的PID。

**返回到用户态：**

父进程接收新进程的PID，子进程接收返回值0。
用户程序通过fork()的返回值区分是父进程还是子进程。

**2.1.2 exec()**

**用户态：**

用户程序调用exec()，它是对sys_exec()的封装。
sys_exec()通过ecall进入内核态。

**内核态：**

sys_exec()调用do_execve()，完成以下操作：

验证用户程序提供的参数合法性。
释放当前进程的内存空间及页表。
加载新的可执行文件（二进制文件）到内存。
设置新的页表、栈指针、入口地址等上下文。
更新当前进程的PCB信息。
do_execve()返回后，设置返回地址epc为新程序的入口地址。

**返回到用户态：**

系统通过sret返回到用户态，新程序从入口地址开始执行。

**2.1.3 wait()**

**用户态：**

用户程序调用wait()或waitpid()，它们是对sys_wait()的封装。
sys_wait()通过ecall进入内核态。

**内核态：**

sys_wait()调用do_wait()，完成以下操作：

检查当前进程是否有子进程。
如果没有子进程，立即返回错误码。
如果有子进程但未退出，则将当前进程状态设置为WT_CHILD并挂起。
如果有已退出的子进程，清理子进程的PCB，返回子进程的退出码。

**返回到用户态：**

父进程被唤醒后，do_wait()返回退出码，sys_wait()传递结果到用户态。
用户程序接收子进程的退出码。

**2.1.4 exit()**

**用户态：**

用户程序调用exit()，它是对sys_exit()的封装。
sys_exit()通过ecall进入内核态。

**内核态：**

sys_exit()调用do_exit()，完成以下操作：

释放当前进程占用的内存资源（如页表、堆栈）。
将当前进程的状态设为PROC_ZOMBIE。
通知父进程有子进程退出。
调用调度器schedule()切换到其他可运行进程。

**不会返回到用户态：**

exit()彻底退出，当前进程的控制权转交给内核。

**2.2 用户态与内核态交错执行分析**

**2.2.1 系统调用是用户态与内核态交互的主要机制**

用户程序通过ecall切换到内核态。
内核完成系统调用的处理后，使用sret返回到用户态。
用户态执行用户程序逻辑，内核态处理底层资源管理、进程调度及硬件控制。

**2.2.2 返回值传递**

内核通过寄存器传递系统调用结果，用户程序通过syscall()的返回值获取内核的处理结果。

**2.3 用户态进程生命周期状态图**

```
+---------------+                     fork()                     +---------------+
|               |   --------------->------------------------->   |               |
|  PROC_NEW     |                                               | PROC_RUNNABLE  |
|  (新建进程)    |                                               |  (可运行态)     |
|               |  <---------------(do_exit)------------------   |               |
+---------------+                                               +---------------+
                                                                    |   ↑
                                                        schedule()  |   |
                                                                    |   | wait()
                                                yield()             ↓   |
                                                                    +---------------+
                                                                    |               |
                                                                    |  PROC_WAITING |
                                                                    |  (等待态)      |
                                                                    |               |
                                                                    +---------------+


```

**状态与事件说明：**

**（1）PROC_NEW：** 新建的进程状态，通过fork()进入PROC_RUNNABLE。

事件：fork()完成，进程进入调度队列。

**（2）PROC_RUNNABLE：** 进程处于可运行状态，等待CPU调度执行。

事件：调度器选择进程时，进入运行态。

**（3）PROC_WAITING：** 进程等待资源或事件（如wait()等待子进程退出）。

事件：等待条件满足（如子进程退出），通过wakeup_proc切换回PROC_RUNNABLE。

**（4）PROC_ZOMBIE：** 进程退出后的状态，等待父进程清理资源。

事件：do_exit()设置进程状态为PROC_ZOMBIE。

**（5）PROC_TERMINATED（隐式状态）：** 资源被完全回收，PCB被销毁。

## 扩展练习Challenge：实现Copy on Write（COW）机制

### 1. 实验要求

给出实现源码,测试用例和设计报告（包括在cow情况下的各种状态转换（类似有限状态自动机）的说明）。

这个扩展练习涉及到本实验和上一个实验“虚拟内存管理”。在ucore操作系统中，当一个用户父进程创建自己的子进程时，父进程会把其申请的用户空间设置为只读，子进程可共享父进程占用的用户内存空间中的页面（这就是一个共享的资源）。当其中任何一个进程修改此用户内存空间中的某页面时，ucore会通过page fault异常获知该操作，并完成拷贝内存页面，使得两个进程都有各自的内存页面。这样一个进程所做的修改不会被另外一个进程可见了。请在ucore中实现这样的COW机制。

由于COW实现比较复杂，容易引入bug，请参考 https://dirtycow.ninja/ 看看能否在ucore的COW实现中模拟这个错误和解决方案。需要有解释。

这是一个big challenge.

说明该用户程序是何时被预先加载到内存中的？与我们常用操作系统的加载有何区别，原因是什么？

### 2. 问题回答

**2.1 Copy on Write（COW）机制讲解**

Copy on Write (COW) 是一种优化技术，主要用于延迟对共享资源的拷贝操作，从而节省内存和性能开销。

**2.1.1 COW的核心工作机制**

**（1）内存页面的共享：**

当父进程通过 fork() 创建子进程时，父子进程共享相同的物理页面。
所有共享页面的权限被设置为只读（read-only）。

**（2）写时拷贝：**

当父进程或子进程尝试修改共享页面时，由于页面是只读的，会触发 页错误（Page Fault）。
操作系统捕获页错误，通过检查共享页面的引用计数（Reference Count）来处理：
如果页面被多个进程共享，分配一个新的物理页面并拷贝原页面的内容到新页面（即完成“拷贝”）。
更新页表，确保新页面对当前进程是独立的、可写的。
如果页面没有被共享，只需将其设置为可写，无需拷贝。

**（3）页面引用计数：**

每个物理页面都有一个引用计数，用于追踪该页面被多少进程共享。
当引用计数减少到零时，操作系统释放该页面的物理内存。

**2.1.2 COW的优点**

减少内存拷贝操作，仅在实际需要写入时拷贝数据。
提升性能，延迟甚至避免不必要的内存分配。

**2.2 问题回答**

**2.2.1 用户程序何时被预先加载到内存中？**

用户程序的二进制代码通常在内核启动时，通过镜像的方式整体加载到物理内存。例如：

用户程序的二进制数据被编译成链接文件。
在 ucore 的内核初始化中，用户程序被作为镜像嵌入到内核空间。
内核通过 load_icode 等函数将这些数据加载到物理内存。

在进程创建时（如 execve() 系统调用），这些数据会被映射到用户进程的虚拟地址空间中，供用户程序使用。

**2.2.2 与常用操作系统的加载有何区别？**

常用操作系统通常采用按需加载策略，仅在程序访问某段代码或数据时，才从磁盘加载到内存；使用分页技术，未访问的页面保持在磁盘中，减少内存占用；程序初始加载时，仅加载最小必要的段（如程序入口的指令和栈）。

在ucore中，用户程序在启动时就被预先整体加载到物理内存；在调用execve()时，整个程序二进制段被加载到用户虚拟地址空间中。

**2.2.3 加载方式差异的原因**

（1）按需加载实现较为复杂，需要与文件系统和磁盘管理紧密结合。

（2）ucore运行在一个模拟或受限环境中，没有复杂的磁盘文件系统支持。

（3）预加载程序可以减少对外部存储设备的依赖。

（4）ucore关注功能完整性和可读性，而非运行效率，因此不需要像生产操作系统那样优化内存和磁盘之间的交换。



## make qemu测试结果
<img src="https://github.com/khakinew/nkuooos/blob/master/lab5/1.png?raw=true?" alt="make qemu" style="zoom:80%;" />

## make grade测试结果
<img src="https://github.com/khakinew/nkuooos/blob/master/lab5/2.png?raw=true" alt="make grade" style="zoom:80%;" />