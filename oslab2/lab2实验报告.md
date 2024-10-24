# lab2实验报告
## 练习一

First Fit算法的主要思想是维护一个空闲块列表，当有内存请求时，从列表中找到第一个足够大的块来满足请求。它使用链表结构来管理空闲页面，定义了几个关键的数据结构和函数来实现内存的管理。

---

#### **数据结构**

首先定义了几个关键的数据结构：

1. **free_area**: 定义为包含`free_list`链表和`nr_free`（空闲页数）的结构体。
2. **Page**: 每个Page对象代表一个物理页面

#### **主要函数解析**
##### 1. `default_init`
- **功能**: 初始化内存管理系统，设置空闲列表头节点并将空闲页面数量初始化为0。
- **过程**:

调用 `list_init` 函数初始化空的 `free_list`，将可用内存块链表设置为空。然后将 `nr_free` 计数器设置为0，表示初始时没有任何内存块是空闲的。
  ```
  static void
  default_init(void) {
    list_init(&free_list);
    nr_free = 0;
  }
  ```
- **作用**: 为后续的内存分配做好准备，确保管理结构处于已知状态。

##### 2. `default_init_memmap`
- **功能**: 初始化指定数量n的页面开始于`base`并将它们加入到空闲页列表。`base` 是待初始化的页面基址，`n` 是页面的数量。
- **过程**:

断言检查
```
    assert(n > 0);
```
循环通过指针`p`遍历从`base`开始的n个内存页。`assert(PageReserved(p))`确保每一页在初始化前都已被标记为保留，然后将每个页的`flags`和`property`字段置零。最后调用`set_page_ref(p, 0)`将每页的引用计数置为0。
```
    struct Page *p = base;
    for (; p != base + n; p ++) {
        assert(PageReserved(p));
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }
```
将 `base`页的`property`设置为`n`，表示`base`页是一系列连续空闲页的起始页。
`SetPageProperty(base)` 设置`base`页的一个属性，标记其为属性页，并将全局的空闲页计数`nr_free`增加 `n`
```
    base->property = n;
    SetPageProperty(base);
    nr_free += n;
```
检查全局的空闲页链表`free_list`是否为空，如果是，直接添加`base`页到链表。
如果不为空，遍历链表寻找合适的位置插入`base`页，以保持链表有序（基于页的内存地址）。最后使用`list_add_before`和`list_add`函数插入节点。
```
    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link));
            }}}}
```
- **作用**: 将一系列连续的页面标记为可用，并维护链表以供后续分配使用。

##### 3. `default_alloc_pages`
- **功能**: 分配n个连续的物理页面,`n` 是请求的页面数量。
- **过程**:

断言用于确保请求的页面数 n 必须大于 0。
```
    assert(n > 0);
```
检查请求的页面数量是否大于当前可用页面 (`nr_free`)。
```
    if (n > nr_free) {
        return NULL;
    }
```
遍历 `free_list` 找到第一个满足 `property >= n` 的页面块。`page = p;` 存储找到的页面块的起始地址。
```
    struct Page *page = NULL;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        if (p->property >= n) {
            page = p;
            break;
        }
    }
```
如果找到合适的页面，则从链表中删除该页面块，并更新其属性。
```
    if (page != NULL) {
        list_entry_t* prev = list_prev(&(page->page_link));
        list_del(&(page->page_link));
```
如果该页面块比请求的更大，则将多余的部分重新加入到空闲链表中。
```
        if (page->property > n) {
            struct Page *p = page + n;
            p->property = page->property - n;
            SetPageProperty(p);
            list_add(prev, &(p->page_link));
        }
```
更新可用页面计数 (`nr_free`),减去已分配的页面数。
```
        nr_free -= n;
```
- **作用**: 通过遍历链表和更新页面的状态,在当且仅当有足够的连续页面时，返回一个可用的页面块，或在没有足够内存时返回 NULL。

##### 4. `default_free_pages`
- **功能**: 释放由base开始的n个物理页面,`base` 是要释放的页面的起始地址,`n` 是要释放的页面数量。
- **过程**:

函数接收两个参数：一个指向页面结构的指针`base`和一个表示要释放的页面数量`n`。`assert(n > 0)` 确保释放的页面数必须大于零。
```
    assert(n > 0);
```
清除每页的标志并将引用计数重置为零。使用`assert`确保要释放的每个页面不是保留页（PageReserved）也不应已经被设置为属性页（PageProperty）。
```
    struct Page *p = base;
    for (; p != base + n; p ++) {
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }
```
设置页面属性和更新空闲页面计数，`SetPageProperty(base)`设置页面属性，标记这个页面块为一个空闲块,`nr_free += n` 更新系统的空闲页面计数。
```
    base->property = n;
    SetPageProperty(base);
    nr_free += n;
```
将页面加入空闲列表,如果空闲列表是空的，则直接将这个页面块添加到列表中。否则，需要在空闲列表中找到适当的位置插入这个页面块，保持列表的有序性。
```
    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
```
遍历空闲列表寻找合适的插入点。如果找到的页面`page`的地址比`base`大，说明`base`应该插在`page`前面。如果遍历到列表末尾还没有找到合适的点，就在末尾插入。
```
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link));
            }}}
```
检查并合并当前页面块与其前一个相邻页面块（必须是连续的）
```
    list_entry_t* le = list_prev(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (p + p->property == base) {
            p->property += base->property;
            ClearPageProperty(base);
            list_del(&(base->page_link));
            base = p;
        }
    }
```
检查并合并当前页面块与其后一个相邻页面块（必须是连续的）
```
    le = list_next(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (base + base->property == p) {
            base->property += p->property;
            ClearPageProperty(p);
            list_del(&(p->page_link));
        }}}
```
- **作用**: 使页面重新可用，并维护链表的顺序和合并空闲页面。

##### 5. `default_nr_free_pages`
- **功能**: 返回当前可用页面的数量。
- **作用**: 方便调用者查询可用内存。

#### First Fit算法改进空间
1. **合并逻辑**: 当前实现只在释放页面时检查相邻的空闲页面以进行合并。可以进一步优化合并策略，根据页面使用情况更加智能地调整。
  
2. **内存碎片处理**: 由于 first fit 方法可能导致内存碎片，改进算法（如使用 best fit 或 buddy system）可以减少碎片，提高内存利用率。

3. **扩展分配策略**: 考虑引入更多的内存分配策略，结合不同的使用场景（例如，小块内存与大块内存的需求），来提高分配的效率。

4. **优化搜索**: First Fit的一个问题是它从内存空闲块链表的起始位置开始搜索，可能需要遍历整个链表才能找到合适的块。如果使用更高效的搜索算法，可以减少搜索时间。

## 练习二

---

First Fit：扫描内存，寻找足够大的第一个空闲块，然后将请求的内存分配给这个块。它的优点是速度快，因为只需找到第一个合适的空闲块即可。但缺点是可能导致许多不连续的小碎片。

Best Fit：相对于First Fit，Best Fit更加细致地选择内存块。它会历所有的空闲页框，寻找最小且满足需求的空闲页框进行分配。这样可以减少剩余空闲空间，从而降低内存碎片的产生。

#### **设计实现过程**
实现代码和First Fit差距并不大，主要修改的部分在`best_fit_alloc_pages`函数中。加入条件`p->property < min_size`，这样可以保证对于每个空闲页框，检查其`property`是否大于等于请求的页框数量`n`，同时又小于当前记录的最小页框大小`min_size`。如果满足这两个条件，则更新`best_fit_page`为当前页框，并更新`min_size`为当前页框的大小。这样我们就找到了最佳适配的页框。
这里我还将`Page`类型的指针`page`更名为`best_fit_page`，但没有实际功能上的用处，只是标识了是用`best-fit`完成的最佳适配页框。
```
    struct Page *best_fit_page = NULL;
    list_entry_t *le = &free_list;
    size_t min_size = nr_free + 1;
     /*LAB2 EXERCISE 2: 2211877*/ 
    // 下面的代码是first-fit的部分代码，请修改下面的代码改为best-fit
    // 遍历空闲链表，查找满足需求的空闲页框
    // 如果找到满足需求的页面，记录该页面以及当前找到的最小连续空闲页框数量
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        // 查找满足需求且最小的空闲页框,这里无需break
        if (p->property >= n && p->property < min_size) {
            best_fit_page = p;
            min_size = p->property;
        }
    }
```
#### **代码测试阶段**
首先注意将kern/mm/pmm.c文件中的`pmm_manager`指向best fit文件。
![图片1](https://github.com/khakinew/nkuooos/blob/master/oslab2/2.png?raw=true)
然后输入`make qemu`，进行测试。
![图片2](https://github.com/khakinew/nkuooos/blob/master/oslab2/3.png?raw=true)
最后进行`make grade`，测试无问题。
![图片3](https://github.com/khakinew/nkuooos/blob/master/oslab2/1.png?raw=true)

#### **Best Fit优化空间**
1. **双向链表**: 如果free_list是一个双向链表，可以在遍历时进行正向和反向遍历，以快速找到最合适的页框。通常情况下，合适的空闲页框可能在链表的两端，如果使用双向链表，可以提升查找效率。
  
2. **排序空闲页框**: 在初始化时，可以考虑将空闲页框按大小进行排序，这样在查找最佳适配的页框时，可以更快地找到合适的页框。但是也有可能增加整体搜索时间。

3. **增加统计信息**: 在选择页框时，可以增加一些统计信息，如当前空闲页框的分布情况。记录每个页框被请求的频率或被分配的次数，以便更好地决策分配策略。

## 扩展练习Challenge：buddy system（伙伴系统）分配算法（需要编程）

---

Buddy System算法把系统中的可用存储空间划分为存储块(Block)来进行管理, 每个存储块的大小必须是2的n次幂(Pow(2, n)), 即1, 2, 4, 8, 16, 32, 64, 128...

- 参考[伙伴分配器的一个极简实现](http://coolshell.cn/articles/10427.html)， 在ucore中实现buddy system分配算法，要求有比较充分的测试用例说明实现的正确性，需要有设计文档。

### buddy system

伙伴系统（Buddy System）是一种用于动态内存管理的算法。它由IBM的Rick Rashid在1986年为他的Accomplisher操作系统设计，后来被引入到Linux内核中。伙伴系统的主要目的是为了有效地管理内存，提高内存分配和释放的效率。

伙伴系统的核心思想是将内存分割成大小为2的幂次方的块（例如，2KB、4KB、8KB等），每个块被称为一个“伙伴”。系统会维护一个空闲块列表，每个列表对应一种特定大小的块。当需要分配内存时，系统会从合适的空闲块列表中取出一个块分配给请求者；当内存被释放时，系统会将其归还到相应的空闲块列表中。

伙伴系统的主要特点包括：

1. **块大小为2的幂**：内存块的大小总是2的幂，这样可以方便地通过位运算来合并和分割块。
2. **合并和分割**：如果请求的内存大小小于当前可用的最大块，系统会尝试找到两个大小为请求大小两倍的块，将它们合并成更大的块来满足请求。如果需要分割一个块来满足请求，系统会将块一分为二，一个分配给请求者，另一个放回空闲列表。
3. **最佳适配与最坏适配**：伙伴系统可以配置为使用最佳适配（Best Fit）或最坏适配（Worst Fit）策略来选择空闲块。最佳适配策略会选择能够满足请求的最小空闲块，而最坏适配策略会选择最大的空闲块。
4. **减少内存碎片**：由于内存块的大小是固定的，并且系统会尝试合并相邻的空闲块，伙伴系统可以有效地减少内存碎片。
5. **快速分配和释放**：伙伴系统通过维护空闲块列表，可以快速地进行内存分配和释放操作。
6. **可扩展性**：伙伴系统可以很容易地扩展到支持更大的内存空间，因为它通过位运算来管理内存块的大小和地址。

在ucore中，分配的基本单位是页，因此每一空闲块都是2^n个连续的页。

### 数据结构

采用完全二叉树结构来管理连续内存页，如下图buddy system共管理16个连续内存页，每一结点记录与管理若干连续内存页，如结点0管理连续的16个页，结点1管理其下连续的8个页，结点15管理连续内存的第一个页，每个结点存储一个longest，记录该结点所管理的所有页中最大可连续分配页数目。![image-20241023165859189](C:\Users\86191\AppData\Roaming\Typora\typora-user-images\image-20241023165859189.png)

定义buddy的结构如下所示，size表示所管理的连续内存页大小(需要是2的幂)，longest为上面所说的数组，这里是直接以分配物理内存的形式存在(指针)，longest_num_page表示longest数组的大小，free_size表示当前该区域的空闲页大小，begin_page指针指向所管理的连续内存页的第一页的Page结构。

由于可能存在多个可管理的内存区域(pmm.c/page_init中)，因此定义了buddy数组，分别管理num_buddy_zone个内存区域。

```c
struct buddy {
    size_t size;
    uintptr_t *longest;
    size_t longest_num_page;
    size_t total_num_page;
    size_t free_size;
    struct Page *begin_page;
};

struct buddy mem_buddy[MAX_NUM_BUDDY_ZONE];
int num_buddy_zone = 0;
```



### 初始化内存映射

```c
static void
buddy_init_memmap(struct Page *base, size_t n) {
    cprintf("n: %d\n", n);
    struct buddy *buddy = &mem_buddy[num_buddy_zone++];

    size_t v_size = next_power_of_2(n);
    size_t excess = v_size - n;
    size_t v_alloced_size = next_power_of_2(excess);

    buddy->size = v_size;
    buddy->free_size = v_size - v_alloced_size;
    buddy->longest = page2kva(base);
    buddy->begin_page = pa2page(PADDR(ROUNDUP(buddy->longest + 2 * v_size * sizeof(uintptr_t), PGSIZE)));
    buddy->longest_num_page = buddy->begin_page - base;
    buddy->total_num_page = n - buddy->longest_num_page;

    size_t node_size = buddy->size * 2;

    for (int i = 0; i < 2 * buddy->size - 1; i++) {
        if (IS_POWER_OF_2(i + 1)) {
            node_size /= 2;
        }
        buddy->longest[i] = node_size;
    }

    int index = 0;
    while (1) {
        if (buddy->longest[index] == v_alloced_size) {
            buddy->longest[index] = 0;
            break;
        }
        index = RIGHT_LEAF(index);
    }

    while (index) {
        index = PARENT(index);
        buddy->longest[index] = MAX(buddy->longest[LEFT_LEAF(index)], buddy->longest[RIGHT_LEAF(index)]);
    }

    struct Page *p = buddy->begin_page;
    for (; p != base + buddy->free_size; p ++) {
        assert(PageReserved(p));
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }
}
```

- `buddy_init_memmap` 函数，它接受一个指向内存页的指针 `base` 和一个表示页数的 `size_t` 类型变量 `n`。函数开始时，打印出页数 `n`，然后初始化一个指向伙伴系统结构的指针 `buddy`，并增加 `num_buddy_zone` 计数器。
- 计算内存块的大小 `v_size`，它是大于或等于 `n` 的最小的2的幂次方。然后计算超出部分 `excess` 和为这个超出部分分配的内存大小 `v_alloced_size`。
- 设置伙伴系统的属性，与上述结构定义对应包括总大小 `size`、空闲大小 `free_size`、起始虚拟地址 `longest`、起始页 `begin_page`、最长连续空闲页数 `longest_num_page` 和总页数 `total_num_page`。
- 初始化一个数组 `longest`，用于跟踪每个大小类别的最长空闲块。`node_size` 从 `v_size` 的两倍开始，每次遇到2的幂次方就减半，直到遍历完所有可能的大小类别。
- 更新 `longest` 数组，确保它反映了实际的空闲块大小。它首先找到与 `v_alloced_size` 相匹配的条目并将其设置为0，然后向上更新父节点，确保每个节点的值是其子节点中的最大值。
- 从 `begin_page` 开始的内存页，将它们标记为未分配，清除它们的属性，并设置引用计数为0。

### 内存分配

```c
static struct Page *
buddy_alloc_pages(size_t n) {
    assert(n > 0);
    if (!IS_POWER_OF_2(n))
        n = next_power_of_2(n);

    size_t index = 0;
    size_t node_size;
    size_t offset = 0;

    struct buddy *buddy = NULL;
    for (int i = 0; i < num_buddy_zone; i++) {
        if (mem_buddy[i].longest[index] >= n) {
            buddy = &mem_buddy[i];
            break;
        }
    }

    if (!buddy) {
        return NULL;
    }

    for (node_size = buddy->size; node_size != n; node_size /= 2) {
        if (buddy->longest[LEFT_LEAF(index)] >= n)
            index = LEFT_LEAF(index);
        else
            index = RIGHT_LEAF(index);
    }

    buddy->longest[index] = 0;
    offset = (index + 1) * node_size - buddy->size;

    while (index) {
        index = PARENT(index);
        buddy->longest[index] = MAX(buddy->longest[LEFT_LEAF(index)], buddy->longest[RIGHT_LEAF(index)]);
    }

    buddy->free_size -= n;

    return buddy->begin_page + offset;
}
```

-  `buddy_alloc_pages` 函数，接受参数n，即要分配的页数。
- 检测n是否为2的幂，如果不是将n调整为大于或等于 `n` 的最小的2的幂。（为了要匹配需要多少连续页）
- 遍历伙伴区域，找到第一个可以满足分配要求的区域
- 在该区域从最大的节点开始，逐步减小节点大小（即连续页面大小）知道找到能够满足分配要求的最小节点
- 将找到的节点标记为已经分配，更新偏移量，向上回溯，更新父节点最长空闲块大小，更新区域空闲大小

### 内存页的释放

```c
static void
buddy_free_pages(struct Page *base, size_t n) {
    struct buddy *buddy = NULL;

    for (int i = 0; i < num_buddy_zone; i++) {
        struct buddy *t = &mem_buddy[i];
        if (base >= t->begin_page && base < t->begin_page + t->size) {
            buddy = t;
        }
    }

    if (!buddy) return;

    unsigned node_size, index = 0;//记录当前节点索引
    unsigned left_longest, right_longest;
    unsigned offset = base - buddy->begin_page;

    assert(offset >= 0 && offset < buddy->size);

    node_size = 1;//用于记录当前节点大小
    index = offset + buddy->size - 1;

    for (; buddy->longest[index]; index = PARENT(index)) {
        node_size *= 2;
        if (index == 0)
            return;
    }

    buddy->longest[index] = node_size;
    buddy->free_size += node_size;

    while (index) {
        index = PARENT(index);
        node_size *= 2;

        left_longest = buddy->longest[LEFT_LEAF(index)];
        right_longest = buddy->longest[RIGHT_LEAF(index)];

        if (left_longest + right_longest == node_size)
            buddy->longest[index] = node_size;
        else 
            buddy->longest[index] = MAX(left_longest, right_longest);
    }

}
```

1. 先遍历所有伙伴系统区域，寻找包含需要释放内存页的区域并将buddy指针指向对应的区域。
2. 计算释放内存页在伙伴系统区域位置（即偏移量）
3. 向上遍历longest数组知道找到一个没有空闲块的节点将其设置为空闲，并更新free_size
4. 继续向上遍历 `longest` 数组，尝试合并相邻的空闲块。如果左右子节点的空闲块可以合并，就更新父节点的 `longest` 值；否则，保持父节点的 `longest` 值为左右子节点中较大的一个。

### 实验结果

![图片4](https://github.com/khakinew/nkuooos/blob/master/oslab2/4.png?raw=true)

实验结果如上图，出现了使用伙伴系统并且分配测试成功。



## 扩展练习challenge2 任意大小的内存单元slub分配算法

### 要求

slub算法，实现两层架构的高效内存单元分配，第一层是基于页大小的内存分配，第二层是在第一层基础上实现基于任意大小的内存分配。可简化实现，能够体现其主体思想即可。

参考linux的slub分配算法，在ucore中实现slub分配算法。要求有比较充分的测试用例说明实现的正确性，需要有设计文档。

### 设计文档

**1. 介绍**

SLUB是一种用于内核内存管理的分配器，它将内存分为多个slab，每个slab中包含多个相同大小的对象，并使用标记跟踪对象的分配状态，然后通过引入slab缓存来避免频繁的内存页分配与释放，从而提高小对象的内存分配和释放效率。

**2. 架构**

**第一层：（页分配层）** 分配页作为内存块的基础单位，使用alloc_pages()和free_pages()函数管理页级内存的分配与释放。

**第二层：（slab缓存层）** 在每个分配的页上，维护多个大小相同的对象，并使用标记记录对象的分配状态。

**3. 结构体**

**slab结构体：** 每个slab结构体在被创建时，分配了一页内存作为对象存储区，对象的大小ob_size是用户定义的，可以动态调整。

对象分配：每个slab包含多个大小相同的对象，其数量由num_obs计算，即一页内存可以容纳的对象数量为PAGE_SIZE/ob_size。

空闲状态记录：通过flag标记数组来记录每个对象的分配状态，每一位表示一个对象是否已分配。

空闲对象数量：free_obs记录了当前slab中空闲对象的数量，确保分配和释放时能够快速找到空闲对象或判断slab是否已满。

```c
typedef struct slab 
{
    void *start; //起始地址
    size_t ob_size; //对象的大小
    size_t num_obs; //总对象数
    size_t free_obs; //空闲对象数
    struct slab *next; //指向下一个slab
    unsigned char *flag; //标记已分配对象
}
```

**cache结构体：** cache代表了对象的缓存池，slabs_list是slab的链表，当某个slab被分配到缓存池时，会加入到slabs_list中。

```c
typedef struct cache 
{
    slab_ob *slabs_list; //slab链表
    size_ob ob_size; //对象的大小
}
```

**4. 函数**

**slab_create函数：初始化slab**

创建一个slab对象，并初始化相关结构体。

```c
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
```

**cache_create函数：创建和初始化缓存**

创建一个新的slab缓存，并初始化相关结构体，缓存中的每个对象大小为传入的ob_size，系统首先会为slab链表分配内存，缓存初始化后可以进行对象分配。

```c
cache_ob *cache_create(size_t ob_size) 
{
    cache_ob *c = (cache_ob *)alloc_pages(1); //为cache_ob结构体分配一页内存
    if (c == NULL) 
        return NULL; //分配失败返回NULL
    c->slabs_list = NULL; //初始化缓存的slab链表为空
    c->ob_size = ob_size; //设置对象大小
    return c; //返回缓存指针
}
```

**cache_alloc函数：分配对象** 

分配器检查slab链表，寻找一个有空闲对象的slab；如果链表中没有空闲slab，系统会创建一个新的slab，并将其添加到链表中。

```c
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
```

**cache_free函数：释放对象** 

当对象不再使用时，分配器会根据对象所在的slab更新对应位图，标记该对象为未使用状态。

```c
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
```
**cache_destroy函数：销毁缓存** 

遍历slab链表，逐个释放每个slab的内存，最终销毁整个缓存，确保内存不泄漏。

```c
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
```

**测试函数：测试SLUB分配器功能**

首先创建对象缓存，分配32字节大小的对象；然后测试对象的分配和释放；最后销毁缓存，确保分配的内存被正确释放。

```c
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
        cprintf("object1:%p\n", obj1);

    //分配第二个对象
    void *ob2 = cache_alloc(c);
    if (ob2 == NULL) 
        cprintf("object2分配失败\n");
    else 
        cprintf("object2:%p\n", obj2);

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
        cprintf("object3:%p\n", obj3);

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
```

**5. 工作流程**

页分配层：使用alloc_pages()和free_pages()对每个slab和flag标志进行页面的分配和释放。

slab缓存层：在分配的页上组织和管理多个对象，通过flag记录对象的分配状态。每个slab可以管理多个大小相同的对象，cache_alloc()和cache_free()实现了从缓存池中高效分配和回收对象。

### 代码

**kern/mm/slub_alloc.h文件：** 在该文件中声明SLUB分配器使用的数据结构和函数接口。

```c
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
```

**kern/mm/slub_alloc.c文件：** 在该文件中实现SLUB分配器的主要逻辑，使用alloc_pages()和free_pages()管理页分配。

```c
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
```

**kern/init/init.c文件：** 在该文件中初始化SLUB分配器并测试其功能。

```c++
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
        cprintf("object1:%p\n", obj1);

    //分配第二个对象
    void *ob2 = cache_alloc(c);
    if (ob2 == NULL) 
        cprintf("object2分配失败\n");
    else 
        cprintf("object2:%p\n", obj2);

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
        cprintf("object3:%p\n", obj3);

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
```

### 编译运行

使用命令**make**进行编译，使用命令**make qemu**运行，结果如下图所示。

<img src="https://raw.githubusercontent.com/khakinew/nkuooos/master/oslab2/5.png" alt="图片5" style="zoom:80%;" />

<img src="https://raw.githubusercontent.com/khakinew/nkuooos/master/oslab2/6.png" alt="图片6" style="zoom:80%;" />

<img src="https://raw.githubusercontent.com/khakinew/nkuooos/master/oslab2/7.png" alt="图片7" style="zoom:80%;" />

由编译运行结果可以看出，SLUB分配器依次完成了分配和释放内存的过程。



## 扩展练习challenge3 硬件的可用物理内存范围的获取方法

---

如果OS无法提前知道当前硬件的可用物理内存范围，请问你有何办法让OS获取可用物理内存范围？

1. 使用固件或BIOS提供的内存信息
   

BIOS/UEFI内存映射: 大多数计算机在启动时会通过BIOS或UEFI提供关于系统内存的相关信息，因此可以通过调用BIOS的中断或UEFI的引导服务来获取内存布局。

BIOS e820内存映射: 使用e820中断来查询内存布局。这个映射提供了系统可用的物理内存范围，操作系统可以通过多次调用中断获取所有的可用内存区段。

UEFI Boot Services: 在UEFI启动环境中，可以使用GetMemoryMap()函数来获取物理内存的布局，包括可用和保留的内存区段。

2. 通过ACPI表获取内存布局
   

ACPI表是高级配置与电源接口表，它提供了一些系统描述表，可以用于获取可用的物理内存范围，操作系统启动时可以解析这些ACPI表，从而获得可用的物理内存区域。

3. 通过硬件探测
   

操作系统还可以通过尝试访问物理地址，查看是否能读写成功来探测可用的物理内存，如果无法成功，则该内存区域可能是保留的或不存在的。不过这种方法通常效率低且容易出错，可能会导致访问保留的设备内存区域。

4. 读取特定硬件寄存器
   

在一些ARM 或一些嵌入式系统架构中，硬件会通过特定的寄存器提供可用的内存范围，操作系统可以通过读取这些寄存器来确定内存的起始地址和大小。例如ARM的一些片上系统会提供内存控制寄存器，操作系统可以读取这些寄存器来获取物理内存的起始地址和大小。

5. 多启动加载器提供内存布局信息

在某些情况下，多启动加载器会在加载内核时将内存信息传递给操作系统。例如，GRUB会将内存布局通过multiboot规范传递给操作系统的内核，操作系统可以解析这些信息，获取可用的物理内存区段。 


---


## 知识点总结
#### 1. 内存分配策略
- **知识点**: Best Fit 和 First Fit 内存分配算法。
- **OS对应知识点**: 内存管理。
- 内存分配策略决定了如何有效地将内存分配给进程。Best Fit策略尽量减少内存碎片，而First Fit则更注重分配速度。这两种算法都是内存管理的一部分，旨在提高内存使用效率。但是Best Fit需要遍历所有空闲内存页框以找到最佳匹配，导致查找时间较长，而First Fit则只需找到第一个合适的页框，速度更快，但可能导致较大的内存碎片。

#### 2. slub分配算法

1. SLUB分配算法的原理

对象管理：SLUB分配算法将内存视为对象进行管理。这些对象通常是内核中的数据结构，如task_struct、file_struct等。相同类型的对象归为一类，每次申请时，SLUB分配器就从一个对象列表中分配一个相应大小的单元。

内存缓存：SLUB分配器从伙伴分配器中获取的物理内存称为内存缓存。这些内存缓存被进一步细分成小块，用于缓存数据结构和对象。每个内存缓存由struct kmem_cache数据结构描述，该数据结构包含了缓存的管理数据和指向实际缓存空间的指针。

slab与对象：在SLUB分配器中，一个slab表示某个特定大小空间的缓冲片区，而片区里面的一个特定大小的空间则称之为对象。slab由一个或多个连续的物理页组成，通常只有一页。slab中的对象有已分配和空闲两种状态。为了有效地管理slab，根据已分配对象的数目，slab可以有Full（全满）、Partial（部分满）和Empty（全空）三种状态，并动态地处于相应的队列中。

partial队列与全局失效：SLUB分配器使用了一个partial队列来管理部分满的slab。当一个CPU不使用的对象被释放时，它会被放到全局的partial队列中，供其他CPU使用。这样平衡了各节点的slab对象，提高了内存利用率。同时，回收页面时，SLUB的slab对象是全局失效的，不会引起对象共享问题。

2. 设计注意事项

内存分配优化：Slub分配器采用页为单位分配内存，通过slab缓存管理多个小对象的分配，避免频繁的页级别分配操作。

位图管理：通过位图管理slab中对象的分配状态，位图的大小与对象数量相关，避免了浪费内存。

可扩展性：支持链式slab链表结构，允许动态增加slab，适应不同场景下的内存需求。

3. SLUB分配算法的优点

性能提升：SLUB分配器相对于SLAB分配器有5%~10%的性能提升。

内存占用减少：SLUB分配器减少了50%的内存占用，因为它去除了SLAB分配器中复杂的层次结构和队列。

兼容性与扩展性：SLUB分配器完全兼容SLAB分配器的接口，因此内核其他模块不需要修改即可从SLUB的高性能中受益。同时，SLUB分配器具有更好的扩展性，可以适应大型NUMA系统。

4. SLUB分配算法的应用

内核对象分配：SLUB分配算法主要用于Linux内核中小块内存的分配和管理。它提高了内存分配的效率和速度，减少了内存碎片和浪费。

嵌入式系统：虽然SLUB分配算法主要针对大型系统进行了优化，但由于其内存占用少、性能高的特点，也可以在一些内存资源有限的嵌入式系统中使用。然而，对于内存非常有限的系统（如32MB以下），可能会更倾向于使用更轻量级的内存分配算法，如SLOB（Slab Object Buffer）分配器。

#### 3.无法提前知道硬件的可用物理内存范围让OS获取可用的物理内存范围的方法选择

最常用的方式是通过BIOS/UEFI的内存映射接口或ACPI表来获取物理内存的范围，因为这些方法既能提供详细的内存布局信息，又能避免探测过程中出现访问保留设备内存区域的问题。

x86系统：首选通过e820或UEFI的内存映射接口。
ARM或嵌入式系统：使用设备树或硬件寄存器获取内存布局。

