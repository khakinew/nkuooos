# lab3
## 练习一：分配并初始化一个进程控制块（需要编码）（2213028-黄煜斐）

> alloc_proc函数（位于kern/process/proc.c中）负责分配并返回一个新的struct proc_struct结构，用于存储新建立的内核线程的管理信息。ucore需要对这个结构进行最基本的初始化，你需要完成这个初始化过程。
>
> 【提示】在alloc_proc函数的实现中，需要初始化的proc_struct结构中的成员变量至少包括：state/pid/runs/kstack/need_resched/parent/mm/context/tf/cr3/flags/name。
>
> 请在实验报告中简要说明你的设计实现过程。请回答如下问题：
>
> - 请说明proc_struct中`struct context context`和`struct trapframe *tf`成员变量含义和在本实验中的作用是啥？（提示通过看代码和编程调试可以判断出来）

**设计原理**

1. 函数`alloc_proc`的功能是分配一个`proc_struct`结构体的内存空间并对其所有字段进行初始化。
2. 首先使用`kmalloc`函数分配`proc_struct`结构体大小的内存空间，并将分配得到的内存地址存储在`proc`指针变量中。
3. 若kmalloc成功分配内存（proc不为NULL），则进行初始化操作：
   - 将进程状态设置为`PROC_UNINIT`，表示进程还未初始化。
   - 将进程 ID 设置为 -1，表示还未分配 ID。
   - 将 CR3 寄存器的值设置为`boot_cr3`，系统启动时的页目录基址。
   - 将进程的运行次数设置为 0。
   - 将内核栈地址设置为 0，表示还未分配内核栈。
   - 将`need_resched`标志设置为 0，表示当前不需要重新调度。
   - 将父进程指针设置为`NULL`，表示当前进程没有父进程。
   - 将内存管理字段设置为`NULL`，表示未初始化内存管理相关数据。
   - 使用`memset`函数将`context`结构体中的所有字节都设置为 0，初始化上下文信息。
   - 将`trapframe`指针设置为`NULL`，表示还未初始化 trapframe。
   - 将进程标志设置为 0。
   - 使用`memset`函数将进程名数组中的所有字节都设置为 0，初始化进程名。
4. 最后函数返回`proc`指针，若`kmalloc`分配内存失败（`proc`为`NULL`），则直接返回`NULL`

**代码如下：**

```c++
// alloc_proc - 分配一个proc_struct并初始化proc_struct的所有字段
static struct proc_struct *
alloc_proc(void)
{
    // 使用kmalloc分配内存空间给新的proc_struct
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
    if (proc!= NULL)
    {
        // 初始化进程状态为未初始化
        proc->state = PROC_UNINIT;
        // 设置进程ID为-1（还未分配）
        proc->pid = -1;
        // 设置CR3寄存器的值（页目录基址）
        proc->cr3 = boot_cr3;
        // 设置进程运行次数为0
        proc->runs = 0;
        // 设置内核栈地址为0（还未分配）
        proc->kstack = 0;
        // 设置不需要重新调度
        proc->need_resched = 0;
        // 设置父进程为空
        proc->parent = NULL;
        // 设置内存管理字段为空
        proc->mm = NULL;
        // 初始化上下文信息为0
        memset(&(proc->context), 0, sizeof(struct context));
        // 设置trapframe为空
        proc->tf = NULL;
        // 设置进程标志为0
        proc->flags = 0;
        // 初始化进程名为0
        memset(proc->name, 0, PROC_NAME_LEN);
    }
    return proc;
}
```

1. **`struct context context`**
   - 含义：
     - `context`结构体通常用于保存进程的执行上下文。执行上下文包含了进程在执行过程中的关键信息，例如程序计数器（PC）、寄存器的值等。这些信息完整地描述了进程在某一时刻的执行状态，使得进程可以被暂停（例如发生中断或者进程切换时），然后在之后的某个时刻能够从暂停的位置恢复执行。
   - 在本实验中：
     - 在进程初始化阶段（`alloc_proc`函数），通过`memset(&(proc->context), 0, sizeof(struct context));`将`context`结构体初始化为全 0，确保了进程在开始执行之前，其执行上下文处于一个已知的、初始的状态。
     - 在进程切换的场景下，当一个进程被暂停，其当前的执行状态（包括寄存器的值、程序计数器等）会被保存到`context`结构体中。之后，当这个进程再次被调度执行时，存储在`context`结构体中的信息会被恢复到处理器的相应寄存器和程序计数器中，使得进程能够从上次暂停的位置继续执行。例如，在操作系统的进程调度器中，会涉及到将当前运行进程的`context`保存，然后加载下一个要运行进程的`context`来实现进程切换。
2. **`struct trapframe *tf`**
   - 含义：
     - `trapframe`是一个用于处理中断和异常的结构体指针。当发生中断或者异常时，处理器会将当前的执行状态（包括程序计数器、寄存器等信息）压入栈中，形成一个`trapframe`。这个`trapframe`结构完整地记录了中断或异常发生时进程的执行状态，使得在中断处理程序完成后，能够准确地恢复进程的执行。
   - 在本实验中：
     - 在进程初始化阶段，`proc->tf = NULL;`将`trapframe`指针初始化为`NULL`，这是因为在初始化时还没有发生中断或异常，所以不需要`trapframe`信息。
     - 在处理中断或异常的过程中，`trapframe`将被用来保存中断或异常发生瞬间的进程执行状态。例如，当系统收到一个硬件中断（如时钟中断）或者软件中断（如系统调用引发的中断），处理器会自动构建一个`trapframe`，将当前进程的执行状态保存到其中。然后，中断处理程序可以通过这个`trapframe`获取中断发生时的信息，如中断发生时的程序计数器值，用于确定中断发生的位置，以及寄存器的值，用于在中断处理完成后恢复进程的执行，确保进程能够正确地从中断点继续运行

## 练习2：为新创建的内核线程分配资源（需要编码）（2211877-王竞苒）
创建一个内核线程需要分配和设置好很多资源。`kernel_thread`函数通过调用**do_fork**函数完成具体内核线程的创建工作。`do_kernel`函数会调用`alloc_proc`函数来分配并初始化一个进程控制块，但`alloc_proc`只是找到了一小块内存用以记录进程的必要信息，并没有实际分配这些资源。`ucore`一般通过`do_fork`实际创建新的内核线程。`do_fork`的作用是，创建当前内核线程的一个副本，它们的执行上下文、代码、数据都一样，但是存储位置不同。因此，我们**实际需要"fork"的东西就是stack和trapframe**。在这个过程中，需要给新内核线程分配资源，并且复制原进程的状态。你需要完成在`kern/process/proc.c`中的`do_fork`函数中的处理过程。它的大致执行步骤包括：

* 调用`alloc_proc`，首先获得一块用户信息块。
* 为进程分配一个内核栈。
* 复制原进程的内存管理信息到新进程（但内核线程不必做此事）
* 复制原进程上下文到新进程
* 将新进程添加到进程列表
* 唤醒新进程
* 返回新进程号

请在实验报告中简要说明你的设计实现过程。请回答如下问题：

* 请说明`ucore`是否做到给每个新`fork`的线程一个唯一的`id`？请说明你的分析和理由。

---

* **`do_fork`函数设计**：

`do_fork`函数实现创建一个新进程（子进程）的功能，其内容分析如下：

1. 检查系统是否允许创建新进程
```
if (nr_process >= MAX_PROCESS) {
    goto fork_out;
}
```
检查当前进程数是否超过系统支持的最大进程数（`MAX_PROCESS`），避免系统资源耗尽或管理上的复杂性

2. 初始化进程结构体
```
if ((proc = alloc_proc()) == NULL) {
    goto fork_out;
}
```
通过`alloc_proc`函数分配并初始化一个新的`proc_struct`（进程描述符），`proc_struct`是操作系统管理进程的核心数据结构，包含进程的基本信息。如果分配失败，直接跳转到`fork_out`返回错误。

3. 分配内核栈
```
if (setup_kstack(proc) != 0) {
    goto bad_fork_cleanup_proc;
}
```
为子进程分配一个专属的内核栈，每个进程在内核态执行时都需要自己的内核栈，用于保存中断上下文和局部变量。如果分配失败，跳转到`bad_fork_cleanup_proc`释放已分配的进程描述符。

4. 复制或共享父进程的内存空间
```
if (copy_mm(clone_flags, proc) != 0) {
    goto bad_fork_cleanup_kstack;
}
```
根据`clone_flags`决定是否复制或共享父进程的内存管理结构,如果`clone_flags & CLONE_VM`，则共享内存空间,否则，创建独立的内存空间副本。如果内存操作失败，释放之前分配的内核栈。

5. 设置子进程的线程上下文
```
copy_thread(proc, stack, tf);
```
使用`copy_thread`函数初始化子进程的寄存器上下文和内核栈指针,`stack`指定了用户栈的位置,`tf`是陷入帧，保存了父进程的寄存器状态。

6. 分配唯一的`PID`并更新系统进程数
```
proc->pid = get_pid();
nr_process++;
```
为新进程分配一个唯一的进程`ID`（`PID`），并更新全局的进程计数,进程`ID`是操作系统中区分进程的唯一标识。

7. 将新进程加入管理结构
```
hash_proc(proc);
list_add(&proc_list, &(proc->list_link));
```
使用`hash_proc`将子进程插入进程哈希表，方便快速检索。使用`list_add`将子进程加入全局的进程链表（`proc_list`）。

8. 将子进程标记为可运行状态
```
wakeup_proc(proc);
```
通过`wakeup_proc`将子进程的状态设置为`PROC_RUNNABLE`，表示该进程可以被调度,确保子进程能够参与调度并运行。

9. 返回子进程的`PID`
```
ret = proc->pid;
```
将子进程的`PID`作为`fork`的返回值。在父进程中，返回子进程的PID,在子进程中，返回0（`copy_thread`初始化了返回值）。

10. 错误处理与资源回收
```
bad_fork_cleanup_kstack:
    put_kstack(proc);
bad_fork_cleanup_proc:
    kfree(proc);
```
在资源分配失败时，清理已分配的资源，避免内存泄漏,put_kstack释放内核栈,kfree释放进程描述符。

* **`ucore`是否做到给每个新`fork`的线程一个唯一的`id`**：
    `ucore`通过调用`get_pid()`函数，从全局的`PID`池中获取一个未分配使用的`PID`分配给新的进程，因此保证了每个新`fork`的线程拥有一个唯一的`id`。
    
## 练习3：编写proc_run 函数（2213400-王婧怡）

### 1. 实验要求

proc_run用于将指定的进程切换到CPU上运行。它的大致执行步骤包括：

检查要切换的进程是否与当前正在运行的进程相同，如果相同则不需要切换。
禁用中断。你可以使用/kern/sync/sync.h中定义好的宏local_intr_save(x)和local_intr_restore(x)来实现关、开中断。
切换当前进程为要运行的进程。
切换页表，以便使用新进程的地址空间。/libs/riscv.h中提供了lcr3(unsigned int cr3)函数，可实现修改CR3寄存器值的功能。
实现上下文切换。/kern/process中已经预先编写好了switch.S，其中定义了switch_to()函数。可实现两个进程的context切换。
允许中断。

请回答如下问题：

在本实验的执行过程中，创建且运行了几个内核线程？

完成代码编写后，编译并运行代码：make qemu。
如果可以得到如附录A所示的显示内容（仅供参考，不是标准答案输出），则基本正确。

### 2. 实验过程

**（1）代码实现**

```c++
void proc_run(struct proc_struct *proc) {
    if (proc != current) {
        // LAB4:EXERCISE3 YOUR CODE
        /*
        * Some Useful MACROs, Functions and DEFINEs, you can use them in below implementation.
        * MACROs or Functions:
        *   local_intr_save():        Disable interrupts
        *   local_intr_restore():     Enable Interrupts
        *   lcr3():                   Modify the value of CR3 register
        *   switch_to():              Context switching between two processes
        */
        
        // 定义中断标志，用于保存当前中断状态
        bool intr_flag;

        // 保存当前进程指针，并设置下一个进程指针
        struct proc_struct *prev = current, *next = proc;

        // 保存当前中断状态并禁用中断
        local_intr_save(intr_flag);
        {
            // 更新当前运行进程为目标进程
            current = proc;

            // 切换到目标进程的页表
            lcr3(next->cr3);

            // 执行上下文切换
            switch_to(&(prev->context), &(next->context));
        }
        // 恢复之前的中断状态
        local_intr_restore(intr_flag);
    }
}
```

**（2）代码分析**

**a. local_intr_save(intr_flag):**

将当前的中断状态保存到intr_flag中，并禁用中断。
这样可以确保在上下文切换期间，外部事件不会干扰进程切换。

**b. 保存和更新current:**

prev保存当前运行的进程，next表示目标进程。
更新全局变量current，将其设置为目标进程。

**c. 切换页表:**

lcr3(next->cr3)切换到目标进程的页表，确保虚拟地址到物理地址的映射切换到新进程。

**d. 上下文切换:**

switch_to(&(prev->context), &(next->context))完成从prev到next的寄存器状态切换。
它会保存当前进程的上下文并恢复目标进程的上下文。

**e. local_intr_restore(intr_flag):**

根据intr_flag恢复之前的中断状态。

### 3. 问题回答

**问题：** 

在本实验的执行过程中，创建且运行了几个内核线程？

**回答：** 

在代码的执行过程中，创建并运行了两个内核线程idleproc和initproc：

**（1）创建**

在proc_init函数中，创建了两个内核线程：

**idleproc：** 系统创建的第一个内核线程。用于完成系统的初始化并在系统无其他线程运行时进入空闲状态，是uCore的初始执行线程。

**initproc：** 系统创建的第二个内核线程。作为第一个实际运行的内核任务，用于执行后续的初始化或用户进程创建任务，在schedule调度时由idleproc让出CPU，切换到initproc。

**（2）运行**

**idleproc：** 在proc_init后，idleproc成为当前线程，当进入cpu_idle函数后，检测到need_resched被设置为 1，调用schedule函数。

**initproc：** 在schedule函数中，找到proc_list中唯一处于“就绪”状态的线程 initproc，调用proc_run函数，通过上下文切换（switch_to）将CPU的控制权转交给 initproc，initproc成为当前线程，开始执行。

### 4. 知识点总结

**（1）进程切换的整体流程与关键函数**

**proc_run函数：** 是进程切换的核心函数，其执行过程包括检查要切换的进程是否与当前进程相同，若不同则进行一系列切换操作：

首先通过local_intr_save宏保存当前中断状态并禁用中断，确保切换过程不受外部中断干扰；
保存当前进程指针并更新当前运行进程为目标进程；
使用lcr3函数切换到目标进程的页表，改变虚拟地址到物理地址的映射关系；
调用switch_to函数完成两个进程上下文的切换，该函数在switch.S中定义，主要操作是保存原进程寄存器状态并恢复目标进程寄存器状态；
最后通过local_intr_restore宏恢复之前保存的中断状态；

**schedule函数：** 是uCore中简单FIFO调度器的核心。它先将当前内核线程current->need_resched设置为0，然后在proc_list队列中查找下一个处于 “就绪” 态的线程或进程next，找到后调用proc_run函数完成进程切换。

**（2）内核线程的创建与运行**

**创建：** 在proc_init函数中创建了两个内核线程idleproc和initproc。

idleproc：是系统创建的第一个内核线程，用于系统初始化及在无其他线程运行时进入空闲状态，是uCore的初始执行线程，在proc_init函数初始化时其need_resched被置为1。

initproc：系统创建的第二个内核线程，作为第一个实际运行的内核任务，用于后续初始化或用户进程创建任务。

**运行：**

idleproc：在proc_init后成为当前线程，当执行到cpu_idle函数且检测到need_resched为1时，调用schedule函数让出CPU。

initproc：在schedule函数查找proc_list后，因只有idleproc让出CPU且initproc处于 “就绪” 态，被选中并通过proc_run和switch_to函数切换到，开始执行。

**（3）上下文切换与寄存器操作**

**switch_to函数：** 在switch.S中实现，通过通用寄存器a0和a1分别接收原进程和目的进程的指针。它将原进程的多个寄存器保存到相应位置，然后从目的进程的对应位置恢复寄存器值，完成上下文切换。

**forkrets函数：** 位于kern/trap/trapentry.S，在进程切换过程中有重要作用。它将进程的中断帧放在sp寄存器，以便在__trapret中从中断帧恢复所有寄存器。并且在初始化时对中断帧的epc、s0、s1寄存器做了特殊设置，使得在kernel_thread_entry函数中能正确传递参数并跳转到指定函数执行，完成进程初始化后的执行流程。

**（4）中断处理与进程切换的关系**

在进程切换过程中，通过local_intr_save和local_intr_restore宏对中断进行控制，保证在关键的切换步骤中不会因中断而出现错误或不一致的状态，确保进程切换的原子性和正确性。

## 扩展练习 Challenge：（2213028-黄煜斐）


> 说明语句`local_intr_save(intr_flag);....local_intr_restore(intr_flag);`是如何实现开关中断的？

在内核代码执行时，存在许多临界区。所谓临界区，是指那些在执行期间不允许被中断干扰的代码片段。当中断在临界区代码执行期间发生时，极有可能引发竞态条件。例如，多个进程或线程可能同时访问和修改共享数据，如果在这个过程中被中断打断，可能会导致数据处于不一致的状态，进而影响整个系统的正确性和稳定性。

为了有效地保护这些临界区，确保代码执行期间的临界区不被中断，从而成功避免竞态条件并始终保持数据的一致性，操作系统提供了专门的机制。其中，`local_intr_save(intr_flag);` 和 `local_intr_restore(intr_flag);` 便是一对宏（或者）内联函数。

- **关闭中断阶段（`local_intr_save`函数调用）**：
  - 当执行`local_intr_save(intr_flag)`时，函数首先会读取处理器的中断标志寄存器的值。这个寄存器的值反映了当前处理器是否允许中断。假设当前中断标志寄存器的值为`X`（`X`可以是 0 或 1，0 表示禁止中断，1 表示允许中断）。
  - 函数将`X`的值存储到`intr_flag`变量中，记录了在关闭中断之前的中断状态。接着，函数会向中断标志寄存器写入 0，这一步操作有效地关闭了中断。从这一刻起，处理器将不再响应新的中断请求，直到中断被重新开启。这样做的目的通常是为了保护一段关键代码区域，防止在执行这段代码时被其他中断打断，从而保证代码执行的原子性。
  - 在RISC-V或者其他体系结构上，这通常涉及读取中断控制寄存器的当前值（如状态寄存器），并将该值存储在变量中。然后，先判断⼀下S态的中断使能位是否被设置了，如果设置了，则调⽤intr_disable 函数设置中断控制寄存器的值以禁⽤中断。在RISC-V中，这可能涉及修改状态寄存器（ sstatus ）中的全局中断使能位（SIE）。
- **恢复中断阶段（`local_intr_restore`函数调用）**：
  - 当执行`local_intr_restore(intr_flag)`时，函数会取出之前存储在`intr_flag`变量中的值。这个值就是在`local_intr_save`函数调用时保存的中断状态。
  - 然后，函数将这个值写回到处理器的中断标志寄存器。如果`intr_flag`的值为 1，表示在`local_intr_save`调用之前中断是允许的，那么通过这一操作，中断将被重新开启，处理器又可以正常地响应中断请求了。如果`intr_flag`的值为 0，表示之前中断就是禁止的，那么中断仍然保持禁止状态。



## make qemu测试结果
<img src="https://github.com/khakinew/nkuooos/blob/master/lab4/1.png?raw=true?" alt="make qemu" style="zoom:80%;" />

## make grade测试结果
<img src="https://github.com/khakinew/nkuooos/blob/master/lab4/2.png?raw=true" alt="make grade" style="zoom:80%;" />