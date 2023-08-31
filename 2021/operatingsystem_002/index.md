# 内存管理


内存 (随机访问存储器，RAM) 是计算机中一种需要认真管理的重要资源。不管存储器有多大，程序都能把它填满。经过多年的探索，我们有了 **分层存储器体系** (memory
hierarchy) 的概念，即计算机拥有若干 MiB 快速、昂贵且易失性的 Cache，数 GiB 速度与价格适中的易失性内存，以及数 TiB 快速、廉价但非易失性的磁盘存储。计算机中管理分层存储器体系的部分被称为 **存储管理器** (memory manager)。它的任务是有效地管理内存，记录哪些内存正在使用，哪些内存是空闲的，在进程需要时为其分配内存，在进程使用完后释放内存。


## 无存储器抽象 {#无存储器抽象}

最简单的存储器抽象是不使用抽象。早期的大型机 (60 年代以前)、小型机 (70 年代以前)
以及个人计算机 (80 年代以前) 都是没有存储器抽象的，每一个程序都直接访问物理内存，这种模型中系统每次仅运行一个进程。

虽然直接使用物理内存，但还是有不同的模型，下图展示了三种模型。a 模型中操作系统位于 RAM 底部，这种模型曾被用于大型机与小型机；b 模型中操作系统位于内存顶端的 ROM
(只读存储器) 中，这种模型被用于掌上电脑或嵌入式系统中；c 模型中设备驱动程序位于顶部的 ROM 中，而操作系统的其他部分位于 RAM 的底部，该方案被用于早期的个人计算机中 (如运行 MS-DOS 的计算机)，在 ROM 中的系统部分被称为 BIOS (基本输入输出系统，
Basic Input Output System)。a 和 c 模型当用户程序出错时，可能会摧毁操作系统，引发灾难性后果。

{{< figure src="/images/no-abstract-memory-manager.svg" >}}

在无存储器抽象的系统中实现并行的方法是采用多线程编程。由于引入线程时假设一个进程中的所有线程对同一内存映像都可见，如此实现并行也就不是问题。虽然方法行得通，但没有被广泛使用，因为人们通常希望能够在同一时间运行没有关联的程序，而这正是线程抽象所不能提供的。因此一个无存储器抽象的系统也不大可能提供线程抽象的功能。

由于使用无存储器抽象时并发进程，可以在一个进程运行一段时间后，从磁盘中加载其他进程到 RAM 中。但由于两个进程都引用的绝对地址，因此可能会引用到第一个进程的私有地址，导致进程崩溃。IBM 360 对上述问题的补救方案就是在第二个进程装载到内存的时候，使用静态重定位的技术修改它。


## 一种存储器抽象：地址空间 {#一种存储器抽象-地址空间}

当物理地址暴露给进程会带来下面一些严重问题：

1.  如果用户程序可以寻址内存的每个字节，它们就可以很容易地 (故意地或偶然地) 破坏操作系统，从而使整个系统慢慢地停止运行，除非有特殊的硬件保护 (IBM 360 的锁键模式)
2.  使用这种模型，想要同时运行多个程序是很困难的


### 地址空间的概念 {#地址空间的概念}

要使多个应用程序同时处于内存中并且不互相影响，需要解决两个问题：**保护** 和 **重定位** 。

对于保护的解决方法，IBM 360 上使用过一种方法：给内存块标记上一个保护键，并且比较执行进程的键和其访问的内存字的保护键。然而，这种方法本身并没有解决后一个问题，虽然这个问题可以通过在程序被装载时重定位程序来解决，但这是一个缓慢且复杂的解决方法。

一个更好的办法是创造一个新的存储器抽象：地址空间。就像进程的概念创造了一类抽象的
CPU 以运行程序一样，地址空间为程序创造了一种抽象的内存。**地址空间** 是一个进程可用于寻址内存的一套地址结合，每个进程都有一个自己的地址空间，并且这个地址空间独立于其他进程的地址空间。以域名为例，以 **.com** 结尾的网络域名的集合是一种地址空间，这个地址空间是由所有包含 2 ~ 63 个字符并且后面跟着 **.com** 的字符串组成的，组成这些字符串的字符可以是字母、数字和连字符。比较难的是给每个进程一个自己独有的地址空间，使得一个程序中的地址 28 所对应的物理地址与另一个程序中的地址 28 多对应的物理地址有所不同。

一个简单的方式是使用 **动态重定位**，简单地把每个进程的地址空间映射到物理内存的不同部分，这个方法会为 CPU 配置两个特殊的硬件寄存器 **基址寄存器** 与 **界限寄存器**
。当使用基址寄存器与界限寄存器时，程序装载到内存中连续的空闲位置且装载期间无须重定位。当程序开始运行时，将程序的起始物理地址装载到基址寄存器中，程序的长度装载到界限寄存器中。当每次进程访问内存、取一条指令、读或写一个数据字，CPU 硬件会在把地址发送到内存总先前，自动将基址值加到进程发出地址值上。同时检查程序提供的地址是否大于或等于界限寄存器中的值，如果访问的地址超过界限则会产生错误并中止访问。


### 交换技术 {#交换技术}

如果计算机物理内存足够大，可以保存所有进程，那么之前提及的所有方案或多或少都是可行的。但实际上，所有进程所需的 RAM 数量总和通常会远超出存储器能够支持的范围。有两种处理内存超载的通用方法，最简单的策略是 **交换** (swapping) 技术，即将一个进程完整调入内存，使该进程运行一段时间，然后把它存回磁盘。空闲进程主要存储在磁盘之上，所以当它们不运行时将不占用内存。另一种策略是 **虚拟内存** (virtual memory)，该策略甚至能使程序在只有一部分被调入内存的情况下运行。

如下图所示一个交换系统。开始时内存中仅存在进程 A，之后创建进程 B、C，在 A 被交换到磁盘后载入 D 的内存映像，之后 B 被调出，最后 A 再次被调入。由于 A 的位置发生改变，所以在它换入的时候通过软件或程序运行期间通过硬件，对其地址进行重定位。

{{< figure src="/images/memory-page-swapping.svg" >}}

交换在内存中产生了多个空闲区 (hole，或称 **空洞**)，通过把所有进程尽可能向下移动，有可能将这些小的 hole 合并成一大块，该技术被称为 **内存紧缩** (memory compaction)。通常不进行这个操作，因为将要消耗大量的 CPU 时间。

在进程创建时应该分配多大的内存是一个重要问题。若进程创建时大小固定并不再改变，那么操作系统准确按其大小进行分配。但如果进程数据段可以增长 (多数编程语言允许从堆中动态分配内存)，那么进程增长时就会出现问题。假设大部分进程在运行时都会增长，为减少因内存区域不足而引起的进程交换和移动所产生的开销，可以在换入或移动进程时为其分配一些额外的内存。当进程被换出到磁盘上时，仅交换进程实际上使用的内存内容。如果进程有两个可增长的段 (堆所使用的数据段以及存放局部变量和返回地址的堆栈段)，则可以预留一部分区域，堆栈段占据进程内存的顶部并向下增长，数据段占据程序底部并向上增长，其间的内存为预留的空闲内存。如下图所示。

{{< figure src="/images/memory-reserved-space.svg" >}}


### 空闲内存管理 {#空闲内存管理}

在动态分配内存时，操作系统必须对其进行管理。一般而言，有两种管理方法 **位图** 与
**空闲区链表**。


#### 使用位图的存储管理 {#使用位图的存储管理}

该方法中，内存可能被划分成小到几个字或大到几千字的分配单元，每个分配单元对应位图中的一位。

分配单元的大小是一个重要设计因素：分配单元越小，位图越大。然而即使只有 4 个字节大小的分配单元，32 位的内存需要位图中的 1 位，因此位图占用了 \\(1 / 32\\) 的内存。如果选择较大的分配单元，若进程的大小不是分配单元的整数倍，将极易浪费内存。


#### 使用链表的存储管理 {#使用链表的存储管理}

维护一个记录已分配内存段和空闲内存段的链表，其中每个结点包含域：空闲区 (H) 或进程 (P) 的指示标志、起始地址、长度和指向下一个结点的指针。进程表中表示终止进程的结点通常含有指向对应于其段链表结点的指针，因此段链表使用双向链表更加方便，易于找到上一个结点并检查是否可以合并。

当使用地址顺序在链表中存放进程和空闲区时，有几种算法可以用来为进程交换分配内存。假设存储管理器知道进程需要多少内存。

1.  最简单的方法即 **首次适配** (first fit) 算法，存储器沿着段链表搜索，直到找到足够大的空闲区为止
2.  **下次适配** (next fit) 算法是通过 first fit 修改而来，在找到足够大的空闲区时，
    next fit 会记录下当前位置，供下次搜索使用
3.  **最佳适配** (best fit) 算法搜索整个链表，找出能够容纳进程的最小空闲区。best
    fit 以最好地匹配请求可用空闲区，而不是拆分一个以后可能用到的大空闲区。但是遗憾的是，best fit 将会产生大量的无用小空闲区，导致内存的浪费
4.  **最差适配** (worst fit) 算法是 best fit 的改进，总是分配最大的空用空闲区，使新的空闲区保持较大的程度，方便以后使用。但这并不是一个好的方法

如果将空闲区链表与进程链表分开实现，可以增加分配内存的速度，但内存释放速度会变慢。但是可以将空闲区由小到大排序，以此提高 best fit 的性能，但 next fit 将变得毫无意义。另一个优化是，可以不使用空闲区链表，在每个空闲区的第一个字存储空闲区大小，第二个字指向下一空闲区，这样将大幅降低存储管理器的内存使用。

**快速适配** (quick fit) 算法为那些常用大小的空闲区维护单独的链表。比如一个 N 项表中，第一项是指向大小 4KB 的空闲区链表表头指针，第二项是指向大小 8KB 的空闲区链表表头指针，以此类推。而 21 KB 的空闲区，可以放在专门的大小比较特别的空闲区链表中。该算法在搜索指定大小的空闲区时十分快速，但进程终止或换出时，寻找相邻空闲区并合并是十分费时的。如果不进行合并，内存将很快分裂出大量无用的小空闲区。


## 虚拟内存 {#虚拟内存}

软件对存储器容量的需求增长极快，需要运行的程序往往大到 RAM 无法容纳，而系统必须支持多个程序同时运行，即使 RAM 可以满足一个软件的内存需求，但需求总和必然超出了
RAM 大小。在 20 世纪 60 年代采用的解决方法是：把程序分割成许多片段，称为 **覆盖**
(overlay)。overlay 块存放于磁盘上，在需要时由操作系统动态地换入换出。虽然系统可以自动的进行换入换出工作，但还需要程序员主动将程序分割为多个片段。将一个大工程分割为小的、模块化的片段是费时且枯燥的，并且极易出错。在之后提出了一个可以由系统自动进行的方法，被称为 **虚拟内存** (virtual memory)。

VM 的基本思想是：每个进程拥有自己的地址空间，这个空间被分割为多个块，每个块称作
**页面** (page) 或一页。page 拥有连续的地址范围，被映射到物理内存，但并不是所有
page 都必须在内存中才能运行程序。当程序引用到一部分在物理内存中的地址空间时，由硬件立刻执行必要的映射；而引用到不在物理内存中的地址空间，由操作系统负责将缺失的部分装入物理内存用重新执行失败的指令。


### 分页 {#分页}

大多 VM 系统中都使用一种称为 **分页** (paging) 技术。地址可以通过索引、基址寄存器、段寄存器或其他方式产生。由程序产生的这些地址称为 **虚拟地址** (virtual address)，它们构成可一个 **虚拟地址空间** (virtual address space)。在没有 VM 的计算机上，系统直接将虚拟地址送到内存总线上，读写操作使用具有同样地址的物理内存字；存在 VM 的情况下，虚拟地址被送往 **内存管理单元** (Memory Management Unit, MMU) 中，MMU 将虚拟地址转换为物理地址。

{{< figure src="/images/mmu-example.svg" >}}

虚拟空间地址按照固定的大小划分为 page 的若干单元，在物理内存中对应的单元被称为 \*
页框\* (page frame)，page 与 frame 的大小通常一样。page 的大小可以是 512B 到 1GB
不等，RAM 与磁盘的交换总是以整个 page 为单位交换的，在某些处理器上根据操作系统认为合适的方式，支持对不同大小 page 的混合使用与匹配。

{{< figure src="/images/mmu-example.svg" >}}

由于虚拟内存大于物理内存，因此硬件会使用一个标志位用于记录 page 是否存在于 RAM
中。当 MMU 注意到访问的虚拟内存不存在于 RAM 中，将会使 CPU 陷入到内核中，这个陷阱称为 **缺页中断** (page fault)。操作系统根据一定的策略将一个页面换出 RAM，并将需要访问的页面换入页框中，修改映射关系并重新启动引起中断的指令。


### 页表 {#页表}

页表用于虚拟地址与物理内存之间的索引，以得出应用于该虚拟页面的页框号。虚拟地址被分为高位部分的虚拟页号和低位部分的偏移量，对于 16 位地址和 4KB 的 page，高四位可以指定 16 个虚拟页面中的 page，而低 12 位可以确定 page 内的字节偏移量。由页表项找到页框号，然后把页框号拼接到偏移量的高位端，以替换掉虚拟页号，形成送往内存的物理地址。

{{< figure src="/images/page-table-example.svg" >}}

页表项的结果与机器紧密相关，但存储的信息大致相同，示例如下图所示。`保护`
(protection) 域指出 page 允许什么类型的访问，最简单的 protection 只有一位，其值一般为 0 (可读写) 和 1 (只读)；更复杂的情况是三位 protection，各位分别对应了读、写、执行标识。`修改` (modified) 域与 `访问` (referenced) 域记录 page 的使用情况，在写入 page 时由硬件自动设置 modified，该 field 在在操作系统重新分配页框时是非常有用的：如果 page 被修改过 (即脏内存) 则必须写回磁盘，而没有被修改过的 page 可以直接丢弃。modified 又是也被称为 **脏位** (dirty bit)。无论读写系统都会在 page 被访问时都会设置 referenced，其会在系统发生缺页中断时帮助管理策略淘汰无用 page。最后一位是用于禁用高速缓存的 field，对于映射到设备寄存器而非 RAM 的页面十分重要。

{{< figure src="/images/page-table-element-example.svg" >}}


### 加速分页过程 {#加速分页过程}

在任何分页系统中，都需要考虑两个问题：

1.  虚拟地址到物理地址的映射必须非常快
2.  如果虚拟地址空间很大，那么页表也会很大

最简单的方法是使用完整的硬件页表，无需访问内存，但代价高昂，且进程切换时需要替换整个页表。另一种方法是使用 RAM 存储页表，仅使用页表寄存器指向内存页表的表头，在进程切换时仅需加载新的表头地址，但每条指令都需要访问 RAM 来读取对应页框。

大多数程序总是对少量 page 进行大量访问，而不是相反。因此可以设置一个小型硬件设备，将虚拟地址直接映射到物理地址，不再访问页表。这种设备被称为 **转换检测缓冲区**
(Translation Lookaside Buffer, TLB)，或称为 **相联存储器** (associate memory) 或
**快表**。TLB 通常直接置于 MMU 中，包含少量的表项，每个表项记录了一个 page 的相关信息，这些表项与页表中的表项类似。

当一个虚拟地址输入 MMU 时，硬件先将虚拟页号与 TLB 中的表项进行并行匹配，判断是否存在。若存在有效的匹配，进行的操作不违反 protection，则将页框号直接输出而不需要访问页表；当违反 protection 操作时，与对页表进行非法操作一样；当虚拟页号不再 TLB
时，就会进行页表的查询，并使用一个表项替换这个页表。

使用软件实现 TLB 时，需要处理失效问题。当 page 的访问在内存而不在 TLB 中被称为
**软失效** (soft miss)，此时只需要更新 TLB 而不用产生磁盘 I/O。如果本身不在内存中，则产生 **硬失效**，此时需要从磁盘中装入 page。


### 对大内存的页表 {#对大内存的页表}

采用多级页表，可以轻松将大内存的页表拆分存储，避免全部页表一直保存在内存中，多级页表的级数越多其灵活性越强。

**倒排页表** (inverted page table) 是为解决多级页表层级不断增长的一种解决方法，主要在 PowerPC 中使用，将物理内存中的页框对应一个表项而不再是虚拟页号。表项记录了哪个进程、虚拟页面对定位于该页框中。虽然极大减小了空间，但使虚拟地址到物理地址的转换变得困难。


### 页面置换算法 {#页面置换算法}

当发生缺页中断时，操作系统必须在内存中选择一个页面将其换出内存，以便为即将调入的页面腾出空间。如果要换出的页面在内存驻留期间已经被修改过，就必须把它写回磁盘已更新该页面在磁盘上的副本；如果没有被修改过，那将直接调入页面覆盖被淘汰。


#### 最优页面置换算法 {#最优页面置换算法}

有些页面在内存中将会很快被用到，而一些将会很长时间之后被用到，每个页面都可用该页面将被访问前所需要执行的指令数作为标记，在缺页中断发生时将标记最大的页面换出。

最优置换算法 (OPT) 唯一的问题是其无法实现，缺页中断发生时，操作系统无法得知各个页面下一次被访问的时间。唯一的解决方法是仿真程序上，第一次运行用以跟踪页面访问情况，之后运行中利用第一次的结果实现最优页面置换算法。


#### 最近未使用页面置换算法 {#最近未使用页面置换算法}

为使操作系统能够收集有用的统计信息，会为每个 page 设置两个状态位 modified 与
referenced，每次访问内存时将由硬件直接设置。如果硬件没有这两个状态位，则会使用缺页中断与时钟中断模拟：启动进程时将所有 page 标记为不在内存中；当访问任何一个页面时都会引发一次缺页中断，此时操作系统可以设置 referenced (由操作系统实现的内部表)，修改页表项使其指向正确的页面并设置为只读模式，然后重新启动引起缺页中断的指令；如果随后对该页面的修改又引发一次缺页中断，则操作系统设置这个页面的 modified 并将其改为读写模式。

可以利用 modified 与 referenced 构造一个简单的置换算法：referenced 被定期地清零，以标记这是一个最近没有被访问的 page。由此置换算法将 page 分为了四类

1.  没有被访问过，没有被修改
2.  没有被访问过，已被修改
3.  已被访问，没有被修改
4.  已被访问，已被修改

**最近未被使用** (Not Recently Used, NRU) 易于理解和能够有效地实现实现。NRU 在淘汰
page 时，淘汰一个第二类 page 可能比第一类 page 要好一些。


#### 先进先出页面置换算法 {#先进先出页面置换算法}

**先进先出** (First-In First-Out, FIFO) 算法类似于队列的实现，当一个 page 被换入的时候，加入到 page 对队尾，当需要换出一个页面时将队首的页面换出。FIFO 有一个显而易见的问题，一个常用的 page 到达队首时将被换出 RAM，不久之后又会产生缺页中断将其换入 RAM，因此很少使用纯粹的 FIFO 算法。

**第二次机会** (Second Chance) 算法是对 FIFO 的一种优化，防止常用 page 被换出 RAM。第二次机会算法检查队首页面的 referenced 标志，如果标志是 0 那么这个 page 是最先进入 RAM 且没有被使用的，那么应该被换出 RAM；如果是 1 则进行清零，并将 page 加入到队尾。第二次机会算法即寻找一个在最近的时钟间隔内没有被访问过的页面。如果所有页面都被访问过，那该算法将退化为 FIFO 算法。

第二次机会尽管比较合理，但需要频繁在链表中移动 page，既降低了效率又不是很有必要。一个更好的方法是将链表改为循环链表，即可变为 **时钟** (Clock) 页面置换算法。时钟算法与第二次机会算法一样，检查当前结点 page 的 referenced 标志，如果标识是 0 时将从链表中移除当前结点，如果是 1 时则清零标志。时钟算法不再需要实现结点 page 在链表中的移动，只需要移除或者清零标志位就行。


#### 最近最少使用页面置换算法 {#最近最少使用页面置换算法}

基于对软件指令执行的观察，在前面几条指令频繁使用的页面很可能在后面的几条指令中被使用。反过来说，已经很久没有使用的页面很有可能在未来较长的一段时间内仍然不会被使用。这样可以实现一个方法，在缺页中断时置换未使用时间最长的页面，这个策略称为 **最近最少使用** (Least Recently Used, LRU) 页面置换算法。

虽然 LRU 理论上可以实现，但代价很高。为了完全实现 LRU，需要在内存中维护一个所有
page 的链表，最近最多使用的 page 在表头，最近最少使用的 page 在表尾。困难的是在每次访问内存时都必须要更新整个链表，在链表中找到一个 page 并删除，然后把它移动到表头是十分费时的操作。

一种软件的方案被称为 **最不常用** (Least Frequently Used, LFU) 算法，也被称为 NFU
(Not Frequently Used)，该算法将每个 page 与一个软件计数器相关联，初始值为 0，当时钟中断时由 OS 扫描所有 page 并将每个 page 的 referenced 加到对应的计数器上。这个计数器跟踪了每个页面被访问的频繁程度，发生缺页中断时则置换计数器值最小的 page。

LFU 从来不会忘记任何事情，但是幸运的是将 LFU 做些小小的修改即可模拟 LRU 算法：首先将 referenced 被加到计数器前先将计数器右移一位，然后将 referenced 加到计数器的最左端而不是最右端。这种算法被成为 **老化** (aging) 算法，aging 会使 LFU 忘记一些
page 的计数从而使计数器为 0，这些为 0 的 page 将是被换出 RAM 的被选项，以此模拟了 `最近` 的限制。

LFU 模拟的一个问题是，aging 不知道在两次时钟中断之间，如果有两个 page 被访问，将不得知哪个 page 被先访问。另一个问题，计数器位数将会限制对页面淘汰的策略，如果 8
位计数器能记录 8 个时钟中断内的情况，如果 page1 在 9 个时钟中断前被访问过，page2
在 1000 个时钟中断前被访问过，那么淘汰时将会从这两个 page 中随机选取一个淘汰，因为它们的计数器都为 0。


#### 页面置换算法小结 {#页面置换算法小结}

| 算法         | 注释           |
|------------|--------------|
| OPT (最优)   | 不可实现，但可作为性能基准 |
| NRU (最近未被访问) | LRU 的很粗糙近似 |
| FIFO (先进先出) | 可能换出重要页面 |
| 第二次机会算法 | 防止重要页面被换出 |
| 时钟算法     | 使用循环链表，减少结点修改 |
| LRU (最近最少使用) | 优秀但难实现的算法 |
| LFU (最不常用) | LRU 的相对粗略近似 |
| LFU aging    | 非常近似 LRU 的有效算法 |

我们可以利用缺页中断的次数比总页面调度次数，得出缺页率，缺页率可以简单直观地衡量一个置换算法的好坏。其中最初 n 个空物理块的页面调用也算作缺页。

假设现在有分配的物理块 4 个，页面 `4,3,2,1,4,3,5,4,3,2,1,5`，那么以 OPT、FIFO、
LFU 为例

1.  OPT

    | 物理页面 | 4                | 3                | 2                | 1                | 4            | 3            | 5                | 4            | 3            | 2            | 1                | 5            |
    |------|------------------|------------------|------------------|------------------|--------------|--------------|------------------|--------------|--------------|--------------|------------------|--------------|
    | 1    | 4                | 4                | 4                | 4                | 4            | 4            | 4                | 4            | 4            | 4            | 1                | 1            |
    | 2    |                  | 3                | 3                | 3                | 3            | 3            | 3                | 3            | 3            | 3            | 3                | 3            |
    | 3    |                  |                  | 2                | 2                | 2            | 2            | 2                | 2            | 2            | 2            | 2                | 2            |
    | 4    |                  |                  |                  | 1                | 1            | 1            | 5                | 5            | 5            | 5            | 5                | 5            |
    | 是否缺页 | \\(\checkmark\\) | \\(\checkmark\\) | \\(\checkmark\\) | \\(\checkmark\\) | \\(\times\\) | \\(\times\\) | \\(\checkmark\\) | \\(\times\\) | \\(\times\\) | \\(\times\\) | \\(\checkmark\\) | \\(\times\\) |

    缺页次数 6，总访问次数 12，缺页率 \\(\frac{1}{2}\\)
2.  FIFO

    | 物理页面 | 4                | 3                | 2                | 1                | 4            | 3            | 5                | 4                | 3                | 2                | 1                | 5                |
    |------|------------------|------------------|------------------|------------------|--------------|--------------|------------------|------------------|------------------|------------------|------------------|------------------|
    | 1    | 4                | 4                | 4                | 4                | 4            | 4            | 3                | 2                | 1                | 5                | 4                | 3                |
    | 2    |                  | 3                | 3                | 3                | 3            | 3            | 2                | 1                | 5                | 4                | 3                | 2                |
    | 3    |                  |                  | 2                | 2                | 2            | 2            | 1                | 5                | 4                | 3                | 2                | 1                |
    | 4    |                  |                  |                  | 1                | 1            | 1            | 5                | 4                | 3                | 2                | 1                | 5                |
    | 是否缺页 | \\(\checkmark\\) | \\(\checkmark\\) | \\(\checkmark\\) | \\(\checkmark\\) | \\(\times\\) | \\(\times\\) | \\(\checkmark\\) | \\(\checkmark\\) | \\(\checkmark\\) | \\(\checkmark\\) | \\(\checkmark\\) | \\(\checkmark\\) |

    缺页次数 10，总访问次数 12，缺页率 \\(\frac{5}{6}\\)
3.  LFU

    | 物理页面 | 4                | 3                | 2                | 1                | 4            | 3            | 5                | 4            | 3            | 2                | 1                | 5                |
    |------|------------------|------------------|------------------|------------------|--------------|--------------|------------------|--------------|--------------|------------------|------------------|------------------|
    | 1    | 4                | 4                | 4                | 4                | 3            | 2            | 1                | 1            | 1            | 5                | 4                | 3                |
    | 2    |                  | 3                | 3                | 3                | 2            | 1            | 4                | 3            | 5            | 4                | 3                | 2                |
    | 3    |                  |                  | 2                | 2                | 1            | 4            | 3                | 5            | 4            | 3                | 2                | 1                |
    | 4    |                  |                  |                  | 1                | 4            | 3            | 5                | 4            | 3            | 2                | 1                | 5                |
    | 是否缺页 | \\(\checkmark\\) | \\(\checkmark\\) | \\(\checkmark\\) | \\(\checkmark\\) | \\(\times\\) | \\(\times\\) | \\(\checkmark\\) | \\(\times\\) | \\(\times\\) | \\(\checkmark\\) | \\(\checkmark\\) | \\(\checkmark\\) |

    LFU 算法可以使用链表实现，将刚刚访问过的结点置于表尾，表头即是将被淘汰的
    page，这与上面所介绍到计数器的方案有所不同。缺页次数 8，总访问次数 12，缺页率 \\(\frac{2}{3}\\)


### 分页系统中的设计问题 {#分页系统中的设计问题}


#### 局部与全局分配策略 {#局部与全局分配策略}

如何在相互竞争的进程之间分配内存，在进程 A 发生缺页中断时只考虑分配给 A 的页面还是需要考虑所有内存页面。前者被称为 **局部** (local) 页面置换算法，后者则称为 **全局** (global) 页面置换算法。local 可以有效地为每个进程分配固定的内存片段，global
在运行进程之间动态地分配页框，因此每个进程的页框数是随时间变化的。

global 通常情况下优于 local，当工作集的大小随进程运行时间发生变化时，变得更加明显。即使有大量空闲页框存在时，local 算法也会随着工作集的增长导致颠簸，如果工作集缩小则会导致浪费内存。global 算法则需要系统不停地确定应该为每个进程分配多少页框。一般可以平均将页框分配给正在运行的 n 个进程，但这并不合理，一个 300KB 的进程应该得到 10KB 进程的 30 倍份额，而不是一样的份额。另一个方案是规定一个最小页框数，这样无论多小的进程都可以运行。因为某些机器上，一条两个操作数的指令可能会用到多达 6
个 page，因为指令本身、源操作数、目标操作数可能跨越 page 边界。

管理内存动态分配的一种方案是使用 **缺页中断率** (Page Fault Frequently, PFF) 算法，
PFF 指出了何时增加或减少分配给一个进程的页面，但完全没有说明在发生缺页中断时应该替换掉哪个 page，仅仅控制分配集的大小。PFF 也假定 PFF 随着分配的 page 的增加而降低。


#### 页面大小 {#页面大小}

页面大小是操作系统可以选择的一个参数，要确定最佳的页面大小需要在几个互相矛盾的因素之间进行权衡，从结果来看不存在全局最优解。

正文段、数据段或堆栈段很可能不会恰好装满整个 page，最后一个页面通常是半空的，多余的空间就如此被浪费掉了，这种浪费称为 **内部碎片** (internal fragmentation)。在内存中有 n 个段，页面大小为 p 字节时，会有 \\(np / 2\\) 字节被内部碎片浪费。从这方面考虑使用小页面会更好，但使用小页面程序需要更多的页面，意味着需要更大的页表。而多余的页面被存放于磁盘上，更多的 page 意味着需要频繁与磁盘交换页面，大量时间被浪费于此。此外小页面能更充分的利用 TLB 空间，但占据更多的 TLB 表项，由于 TLB 表项是稀缺资源，在这种情况下使用大页面是值得的。而每次的进程切换，页面越小意味着页表越大，装入时间就会更长。

假设进程平均大小是 s 字节，页面大小 p 字节，每个页表项 e 字节，则每个进程大约需要 \\(s / p\\) 个页面，占用 \\(se / p\\) 字节页表空间，内部碎片在最后一页的浪费为 \\(p /
2\\) 字节，因此页表和内部碎片造成的全部开销为 \\[\frac{se}{p} + \frac{p}{2}\\] 字节。由于最优值一定在页面大小处于某个值时取得，通过对 p 进行一次求导并令表达式为 0 得到
\\[-\frac{se}{p^{2}} + \frac{1}{2} = 0\\]，解得 \\[P = \sqrt{2se}.\\]


#### 共享页面 {#共享页面}

几个不同的用户同时运行同一个程序是很常见的，但内存中如果存在同一个程序的两份副本将会浪费内存，共享页面效率更高。但是并不是所有 page 都适合共享，那些只读的 page
可以共享，但数据页面是不能共享的。

如果个进程共享代码时，共享页面将会出现一些问题。如果调度程序决定从内存中换出 A
程序，撤销其所有页面并用其他程序来填充空页面，则会引起 B 产生大量缺页中断。因此在换出或结束一个有共享页面的进程时，检查页面是否仍在使用是必要的。如果查找所有页表而考察一个 page 是否共享，其代价是十分巨大的，所以需要一个专门的数据结构来记录这些共享页面。

共享数据将比共享代码更为麻烦，但也不是不可能。当两个进程共享同一数据页面时，要求进程不进行写操作而只读操作；当写操作发生时，就触发只读保护并陷入操作系统内核，然后生成一个该页的副本，这时每个进程都拥有了自己的副本。随后每份副本都是可读写的，再次地写操作将不会陷入内核。这种方法被称为 **写时复制** (Copy-on-Write, COW)，它通过减少复制而提高了性能。


#### 共享库 {#共享库}

可以使用其他的粒度取代单个页面来实现共享。如果一个程序被启动两次，多数操作系统会自动共享所有的代码页面，在内存中只保留一份代码页面的副本。由于代码页面总是只读的，因此这样做不存在任何问题。每个进程都拥有一份数据页面的私有副本，或者利用写时复制技术创建共享的数据页面。

当多个代码库被不同的进程使用时，如果将每个程序与这些库静态的绑定在一起，将会使程序变得更加庞大，一个通用的技术是使用 **共享库** 来解决程序膨胀。在链接程序与共享库时，链接器没有加载被调用的函数，而是加载了一小段能够在运行时绑定被调用函数的存根例程 (stub routine)。依赖于系统实现和配置信息，共享库和程序一起被加载，或在所包含函数第一次被调用时加载。如果其他程序已加载了共享库，那么将不会再次装载它。当共享库被装载时，并不是一次性读入内存的，而是根据需要以 page 为单位进行装载，没有调用的函数是不会被装载进内存。除了使可执行程序的文件大小减小、节省内存空间外，共享库还有一个优点：如果共享库中的一个函数因修复 bug 而更新，那么并不需要重新编译调用了这个函数的程序，旧的二进制文件依旧可以运行。

但是共享库需要解决一个问题，共享库加载到 RAM 中被不同进程定位到不同地址上。这个库如果没有被共享可以在装载的过程中重定位，但共享库在装载时再进行重定位就行不通了。可以使用 COW 解决这个问题，对调用共享库的进程创建新页面，在创建新页面的过程中进行重定位，但这与使用共享库的目的相悖。一个更好的方法是：在编译共享库时让编译器不使用绝对地址，而是只能产生使用相对地址的指令。这样无论共享库被放在虚拟地址空间的什么位置，都可以正常工作。只是用相对偏移量的代码被称为 **位置无关代码**
(position-independent code)。


#### 内存映射文件 {#内存映射文件}

有一种通用机制 **内存映射文件** (memory-mapped file)，共享库实际上是其一个特例。这种机制的思想是：进程可以通过发起一个 syscall，将一个文件映射到其虚拟地址空间的一部分。多数的系统实现中，映射共享的页面不会实际读入页面的内容，而是在访问页面时才会被每次一页的读入内存，磁盘文件则被当作后备存储。当进程退出或显示地解除文件映射时，所有被改动的页面会被写回到磁盘文件中。

内存映射文件提供了一种 I/O 的可选模型，可以把一个文件当作一个内存中一个内存中的大字符数组来访问，而不用通过读写操作来访问这个文件。如果两个或两个以上的进程同时映射了同一个文件，它们就可以通过共享内存通信。一个进程在共享内存上完成了写操作，此刻当另一个进程在映射到这个文件的虚拟地址上进行读操作时，它就可以立即看到写操作的修改结果。因此这个机制类似于一个进程之间的高带宽通道，并且这种机制很成熟、实用。


#### 清除策略 {#清除策略}

如果发生缺页中断时系统中有大量的空闲页框，此时分页系统工作在最佳状态。如果每个页框都被占用，并且被修改过的话，再换入新页面时就页面应首先被写回磁盘。为保证有足够的空闲页框，很多分页系统都会有一个称为 **分页守护进程** (paging daemon) 的后台进程，它在大多数时候睡眠，但定期被唤醒检查内存状态。当空闲页框过少时，daemon 通过预订的页面置换算法选择换出内存，保证一定数量的页框供给比使用所有内存，在需要使用时搜索一个页框有更好的性能。daemon 至少保证了所有的空闲页框是干净的，所以空闲页框在被分配时不必再着急写回磁盘。


#### 虚拟内存接口 {#虚拟内存接口}

当前讨论的所有对上层程序员来说是透明的，使用者无需了解详细情况就能正常使用内存。但在一些高级系统中，程序员可以对内存映射进行控制，并通过非常贵的方法来增强程序的行为。

允许程序员对内存映射进行控制的一个原因是，为了允许两个或多个进程共享同一部分内存。如果程序员可以对内存区域进行命名，那么就有可能实现共享内存：通过让一个进程把一片内存区域的名称通知给另一个进程，使得其他进程可以将这片区域映射到它的虚拟空间中去。页面共享可以实现高性能的消息传递系统，传递消息的时候，数据被从一个地址空间复制到另一个地址空间，将会有很大开销；当进程可以控制他们的页面映射时，就可以只复制页面的名称，而不需要复制所有数据。


## 分段 {#分段}

目前所有有关虚拟内存的讨论都是一维的，对于许多问题来说，有多个独立的地址空间可能会优于一个。例如编译器在编译过程中建立许多表，可能包含：

1.  被保存起来供打印清单用的程序正文
2.  符号表，包含变量的名称与属性
3.  包含用到的所有整型量和浮点常量的表
4.  语法分析树，包含程序语法分析的结果
5.  编译器内部过程调用使用的堆栈

前四个表随着编译的进行在不断地增长，最后一个表在编译过程中以一种不可预计的方式增长和缩小。在一维存储器中，这五张表只能被分配到虚拟地址空间中连续的块中。若一个程序中变量的的数量远多于其他部分的数量多时，地址空间中分配给符号表的块可能会被装满，但其他表还有大量的空间。这时更好的方法是机器上提供多个相互独立的 **段** (segment)
的地址空间，各个 segment 的长度可以时 0 到某个允许的最大值中的任何值。不同的
segment 长度可以不同，通常情况下也都不相同。segment 的长度在运行时可以动态改变，在数据压入时增长、弹出时减小，并且不会影响其他段。

segment 是一个逻辑实体，一个段可能包括一个过程、一个数组、一个堆栈、一个数值变量，但一般不会同时包含多种不同类型的内容。除了能简化对长度经常变动的数据结构的管理外，分段存储管理的每个过程都位于一个独立的段中并且起始位置为 0，那么把单独编译好的过程链接起来的操作就可以得到很大的简化。当组成一个程序的所有过程都被编译和链接好之后，一个对段 n 中过程的调用将使用由两个部分组成的地址 \\((n, 0)\\) 来寻址。在重新编译时，对比一维地址，不会受到过程大小的改变而影响其他无关过程的起始地址。

由于 segment 可以时不同类型的内容，因此可以有不同种类的保护。一个过程段可以被指明为只执行的，从而禁止读写；读点数组可以读写但不允许执行，任何试图向这个段内的转跳都将被截获。这样的保护容易找到编程中的错误。

| 考察点     | 分页             | 分段               |
|---------|----------------|------------------|
| 需要了解具体技术 | \\(\times\\)     | \\(\checkmark\\)   |
| 存在多少线性空间 | 1                | 多个               |
| 超出存储器大小 | \\(\checkmark\\) | \\(\checkmark\\)   |
| 过程和数据区分并保护 | \\(\times\\)     | \\(\checkmark\\)   |
| 大小可变的表更易提供 | \\(\times\\)     | \\(\checkmark\\)   |
| 用户间过程共享方便 | \\(\times\\)     | \\(\checkmark\\)   |
| 发明的原因 | 更大的地址空间   | 数据、过程逻辑独立，有助于共享、保护 |

page 是定长的但 segment 不是。系统运行一段时间后，内存会被分为许多块，一些块包含着 segment，而一些成了空闲区，这种现象称为 **棋盘形碎片** 或 **外部碎片** (external
fragmentation)。空闲区的存被浪费，而这可以通过内存紧缩来解决。

{{< figure src="/images/memory-segment-swapping.svg" >}}


## 段页式实现 {#段页式实现}

如果一个段比较大，那么将它整个保存在内存中可能很不方便甚至是不可能的，因此产生了对它进行分页的想法。这样只需要在真正需要的页面才会被调入内存。


### MULTICS {#multics}

MULTICS 是有史以来最具影响力的操作系统之一，对 UNIX 系统、x86 存储器体系结构、快表以及运计算均有过深刻的影响。MULTICS 始于 MIT 的一个研究项目，1969 年上线，最后一个 MULTICS 系统在运行了 31 年后于 2000 年关闭，几乎没有其他操作系统能像
MULTICS 一样几乎没有修改地持续运行那么长时间。更重要的是基于 MULTICS 形成的观点和理论在现在仍同 1965 年第一篇 [相关论文](https://dl.acm.org/doi/10.1145/1463891.1463912) 发表时产生的效果一样的。MULTICS 最具有创新性的一面 **虚拟存储架构**。

MULTICS 运行在 Honeywell 6000 及后续机型上，为每个程序提供最多 \\(2^{18}\\) 个
segment，每个 segment 的虚拟地址空间最长为 65536 个字长。为了实现它，MULTICS 的设计者决定把每个 segment 都看作一个虚拟内存并对其进行分页，以结合分页的优点 (固定的页大小和只需调用部分 page) 和分段的优点 (易于编程、模块化、保护和共享)。

每个程序都有一个段表，每个 segment 对应一个描述符。因为段表可能有 25 万多表项，因此段表本身也是一个 segment 并被分页。一个段描述符包含了一个段是否在内存中的标志，只要 segment 的任一部分在内存中就认为其在内存中。如果 segment 在内存中，它的描述符将包含一个 18 位的指向它的页表指针。由于物理内存是 24 bit 并且页面按 64 字节的边界对齐 (页面地址的低 6 位使用 0 填充)，所以描述符只需要 18 bit 来存储页表地址。段描述符还包含了段大小、保护位以及其他一些条目。每个 segment 都是一个普通的虚拟地址空间，一般页面大小位 1024 字，MULTICS 自己使用的段可能不分页或以 64 字为长度分页。

{{< figure src="/images/segment-table-element-example-multics.svg" >}}

MULTICS 中一个地址由两部分构成：段和段内地址。段内地址又进一步分为页号和页内字。在进行内存访问时执行以下算法：

1.  根据段号找到段描述符
2.  检查该段的页表是否在内存中。如果在则找到它的位置，反之则产生一个段错误，如果访问违反了段的保护要求就发出一个越界错误。
3.  检查所请求的虚拟页面的页表项，若该页面不在内存中则产生一个缺页中断，如果在内存就从页表项中取出这个页面在内存中的起始地址。
4.  将偏移量加到页面的起始地址得到目标地址
5.  进行读或写操作

{{< figure src="/images/memory-address-transform-multics.svg" >}}

这里简单地展示了 MULTICS 虚拟地址到物理地址的转换，这里忽略了描述符段也需要分页的事实。实际上通过一个寄存器找到描述符段的页表，这个页表指向描述符段的页面。但是由操作系统实现以上算法将非常缓慢，MULTICS 使用了包含 16 个字的告诉 TLB 并行搜索所有表项。


### Intel x86 {#intel-x86}

x86 处理器的虚拟内存与 MULTICS 类似，其中包括分页分段机制，其支持最多 \\(2^{14}\\)
个 segment，每个 segment 最长 10 亿个 32 位字。虽然段数量较少，但相比之下 x86 的段大小特征比更多的段数目要重要的多，因为几乎没有程序需要 1000 个以上的段，但很多需要大型的段。自从 `x86-64` 起分段机制被认为是过时且不再支持的，但在本机模式下依然存在分段机制的某些痕迹。

x86 处理器中虚拟内存的核心是两张表：**局部描述表** (Local Descriptor Table, LDT)
和 **全局描述表** (Global Descriptor Table, GDT)，每个程序都有自己的 LDT，但同一台计算机上的所有程序共享一个 GDT。LDT 描述局部每个程序的 segment，包括其代码、数据、堆栈等；GDT 描述系统段，包含操作系统本身。

为了访问一个段，x86 程序必须把这个段的选择子 (selector) 装入机器的 6 个寄存器的某一个中，在运行过程中 CS 寄存器保存代码段的 selector，DS 寄存器保存数据段的
selector，其他的段寄存器不太重要，每个 selector 是一个 16 bit 数。selector 中的
1 bit 指出这个这个段是局部还是全局的，其他 13 bit 是 LDT 或 GDT 的表项编号。因此，这些表的长度被限制在最多容纳 8K 个段描述符。剩余的 2 bit 则是保护位，以后讨论。描述符 0 是禁止使用的，它可以被安全地装入一个段寄存器中用来表示这个段寄存器目前不可用，如果使用则会引发一次中断。selector 经过合理设计，使得根据选择字定位描述符十分方便。首先根据 selector 选择 LDT / GDT，随后 selector 被复制进一个内部擦除寄存器中并将其低 3 位清零，最后 LDT / GDT 表的地址被加到索引上，得出一个直接指向
descriptor 的指针。

{{< figure src="/images/x86-segment-selector.svg" >}}

被 selector 装入段寄存器时，对应的描述符被从 LDT 或 GDT 中取出装入微程序寄存器中，以便快速访问。一个描述符由 8 Byte 构成，包含了段的基址、大小和其他信息。下图描述了 x86 代码段的段描述符。在 descriptor 中应该有一个简单的 32 bit 域给出段大小，但实际上生育 20 bit 可用，因此采取了一种截然不同的方法：用粒度位域标明使用字节为单位还是页面为单位。处理器会将 32 bit 基址与偏移量相加形成 **线性地址** (liner
address)，为了和只有 24 bit 基址的 286 兼容，基址被分为 3 片分布在 descriptor 上。实际上基址运行每个 segment 位于 32 bit 线性地址空间内的任何位置。

{{< figure src="/images/x86-code-segment-descriptor.svg" >}}

如果禁止分页，线性地址将被解释为物理地址并送往存储器用于读写操作，因此禁止操作将是一个纯分段方案。另外段之间允许相互覆盖，这可能是由于验证段不重叠开销太大。如果允许分页，线性地址就被解释为与虚拟地址，并通过页表映射到物理地址。由于 32 位虚拟地址与 4 KB 页的情况下，segment 可能包含多达 100万个页面，因此使用两级映射以便在段较小时减小页表大小。每个进程都有一个 1024 个 32 bit 表项组成的 **页目录** (page
directory)，其通过全局寄存器来定位。page directory 中的每个目录项都指向一个也包含 1024 个 32 bit 表项的页表，页表项指向页框。线性地址被分为三个域：`目录`、
`页面` 和 `偏移量`。目录域被作为索引在 page directory 中找到指向正确的页表的指针，随后页面域被用于索引在页表中找到页框的物理地址，最后偏移量被加到页框地址上得到需要的物理地址。