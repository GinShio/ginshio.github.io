# 原子操作


## 原子操作 {#原子操作}

原子操作是一个不可分割的操作，系统的所有线程不会观察到原子操作完成了一半。如果读取对象的加载操作是原子的，那么这个对象的所有修改操作也是原子的。

标准原子类型全部定义于头文件 _atomic_ 中，这些类型的操作都是原子的，但是其内部实现可能使用原子操作或互斥量模拟，所以原子操作可以替代互斥量完成同步操作，但是如果内部使用互斥量实现那么不会有性能提升。

通常标准原子类型不能进行拷贝和赋值，但是可以隐式转化成对应的内置类型，使用
`load()`、`exchange()`、`compare_exchange_weak()` 和 `compare_exchange_strong()`，另外还有 `store()` 用以原子地赋值。每种函数类型的操作都有一个内存序参数，这个参数可以用来指定存储的顺序。


### ::std::atomic_flag {#std-atomic-flag}

::std::atomic_flag 是最简单的原子类型，标准保证其实现是 **lock-free** 的，这个类型的对象可以在 **设置** 和 **清除** 间切换，对象必须被 `ATOMIC_FLAG_INIT`，初始化标志位为清除状态。初始化后，对象进可以执行销毁、清除、设置

```C++
::std::atomic_flag f = ATOMIC_FLAG_INIT; // 设置为清除状态 (false)
```

由于 `clear()` 清除操作原子地设置标志为 false，`test_and_set()` 设置操作原子地设置标志为 true 并获得其先前值，所以可以简单地实现一个自旋锁

```C++
class spinlock_mutex {
 private:
  ::std::atomic_flag flag;
 public:
  spinlock_mutex() : flag(ATOMIC_FLAG_INIT) {}
  void lock() {
    while (flag.test_and_set(::std::memory_order_acquire));
  }
  void unlock() {
    flag.clear(::std::memory_order_release);
  }
};
```


### ::std::atomic {#std-atomic}

::std::atomic 不再保证 **lock-free**，但相比 ::std::atomic_flag 有了更通用的操作，
`store()` 是一个存储操作，`load()` 是一个加载操作，`exchange()` 是一个读-改-写操作。

```C++
::std::atomic<bool> b;
bool x = b.load(::std::memory_order_acquire); // 加载操作，x==false
b.store(true); // 存储操作，b==true
x = b.exchange(false, ::std::memory_order_acq_rel); // 读-改-写操作，b==false，x==true
```

原子操作中还有一种存储方式：当前值与预期值一致时存储新值，这种操作被称为
**compare/exchange** (比较/交换) 操作。compare/exchange 是原子类型编程的基础，它比较原子变量的当前值和预期值，两者相等时存储目标值，当两者不相等时预期值会被更新为原子变量中的值。它在C++中以 `compare_exchange_weak()` 和
`compare_exchange_strong()` 提供，将当前值与预期值的 `对象表示/值表示` 逐位比较，且复制是逐位的，比较相等将返回 true，否则返回 false。另外我们可以指定两个内存序，即成功修改原子变量的内存序与失败时可以是不同的，具体的内存序我们之后在学习。

compare_exchange_weak 是 **弱CAS**，可能出现伪失败，即当前值与预期值相等时，也可能出现比较失败的行为，为此通常配合循环使用

```C++
bool expected = false;
extern ::std::atomic<bool> b = false;
while (!b.compare_exchange_weak(expected, true) && !expected);
```

compare_exchange_strong 是 **强CAS**，它保证不会出现伪失败，一般推荐使用强形式

```C++
::std::atomic<int> ai = 3;
int tst = 4;
ai.compare_exchange_strong(tst, 5); // false, ai = 3, tst = 3
ai.compare_exchange_strong(tst, 5); // true,  ai = 5, tst = 3
```

整数类型、指针类型、浮点类型 (C++20起) 都拥有原子数值计算的能力，并且整数类型还可以原子地按位运算，这些操作可以修改原子变量并返回修改前原子变量的值

```C++
int arr[5] = {0};
::std::atomic<int> ai{5};
::std::atomic<int*> aip{arr};
// 数值计算
ai += 4; // ai = 9
aip += 2; // aip = arr + 2
ai.fetch_sub(8); // ai = 1
--aip; // aip = arr + 1
// 按位运算 (仅整数类型特化)
ai |= 2; // ai = 3
ai.fetch_and(4); // ai = 0
```

类型中包含 `填充位`、`陷阱位` 或为 `同一值提供多个对象表示` (如浮点数的 NaN) 时推荐弱CAS，因为可能两个对象的值相等但CAS操作失败

```C++
struct TestCas {
    int i;
    char : 1;
};
TestCas a = {65536}; // 假设对象表示 [0,0,1,0,1,0,0,0]
::std::atomic<TestCas> aa{{65536}}; // 假设对象表示 [0,0,1,0,0,0,0,0]
aa.compare_exchange_strong(a, {1024}); // 修改失败，对象表示不一致
                                       // C++20开始，修改成功，值表示一致
```

我们常使用 **用户定义类型** (UDT)，原子类型会进行逐位比较或复制操作，所以 UDT 应该是 **可平凡复制** 的类型。通常 UDT 类型的原子类型会使用锁来完成原子操作，不过好消息是大多数平台对于 UDT 大小如同一个 int 或 void\* 时，将使用原子指令实现原子操作
(即无锁操作)，有些平台甚至还支持两倍大小使用原子指令，即 **双字比较和交换**
(DWCAS) 指令

```C++
::std::cout << ::std::boolalpha << aa.is_lock_free() << ::std::endl; // 可能的输出：true
```


## 内存布局 {#内存布局}

内存模型一方面是内存布局，另一方面是并发，并发的基本结构很重要，特别是低层原子操作，因为C++所有的对象都和内存位置有关。一个类是一个有多个子对象组成的对象，我们需要牢记四个原则

1.  每个变量都是对象，包括其成员变量的对象
2.  每个对象至少占有一个内存位置
3.  基本类型都有确定的内存位置
4.  相邻位域是相同内存中的一部分


### 数据模型 {#数据模型}

数据模型描述了C等编程语言的基本算术类型的位宽，以下是常见的数据模型 (之后我们以
**LP64** 为准)

| Model  | short | int | long | long long | ptr | RunTime                     |
|--------|-------|-----|------|-----------|-----|-----------------------------|
| LP32   | 16    | 16  | 32   | 64        | 32  | MSVC (16bit)                |
| ILP32  | 16    | 32  | 32   | 64        | 32  | MSVC (32bit), \*nix (32bit) |
| LLP64  | 16    | 32  | 32   | 64        | 64  | MSVC, MinGW                 |
| LP64   | 16    | 32  | 64   | 64        | 64  | \*nix, Cygwin, z/OS         |
| ILP64  | 16    | 64  | 64   | 64        | 64  | Solaris                     |
| SILP64 | 64    | 64  | 64   | 64        | 64  | UNICOS                      |


### 内存对齐 {#内存对齐}

内存对齐主要是为了提高内存的访问效率，也为了更好的移植性。但是这样会改变各个成员在类中的偏移量，类的大小也不再是简单的成员大小相加，幸好其中也有一些规律可循

1.  对象的起始地址能够被其最宽的成员大小整除
2.  成员相对于起始地址的偏移量能够被自身大小整除，否则在前一个成员后面填充字节
3.  类的大小能够被最宽的成员的大小整除，否则在最后填充字节
4.  如果是空类，按照标准该类的对象必须占有一个字节 (除非 [空基类优化](https://zh.cppreference.com/w/cpp/language/ebo))，在C中空类的大小是 **0** 字节
5.  当指定对齐的时候，类的大小将是指定对齐大小的倍数，如果不足则在最后填充字节

好的，那么我们看一些简单的例子，基本上都可以算出下面各个类占用多少内存，并可以知道在哪里填充内存

```C++
struct A {}; // sizeof(A): 1, alignof(A): 1
struct B {
    short b_a;
    // 2 bytes
    int b_b;
    char b_c;
    // 3 bytes
}; // sizeof(B): 12, , alignof(B): 4
struct C : public A {
    int c_a;
}; // sizeof(C): 4, alignof(C): 4
struct D {
    A d_a;
    // 3 bytes
    int d_b;
}; // sizeof(D): 8, alignof(D): 4
```

我们加入一些数组进来, 数组中的元素当然也会符合内存对齐的规则

```C++
struct E {
    int e_a;
    char e_b[3];
    // 1 byte
}; // sizeof(E): 8, alignof(E): 4
struct F {
    char f_a[3];
    // 5 bytes
    long long f_b;
    short f_c[3];
    // 2 bytes
    F* f_d;
}; // sizeof(F): 32, alignof(F): 8
```

指定内存对齐的方式时，必须是2的正幂，若指定的对齐方式弱于原生对齐方式，将忽略指定

```C++
struct alignas(16) G {
    char g_a[3];
    // 1 byte
    short g_b;
    // 10 bytes
}; // sizeof(G): 16, alignof(G): 16
struct H : public G {
    short h_a;
    // 2 bytes
    int h_b;
    // 10 bytes
}; // sizeof(H): 32, alignof(H): 16
struct alignas(2) I { // 弱于原生对齐方式(4)
    C c;
}; // sizeof(I): 4, alignof(I): 4
```

位域只会占有多个二进制位，而不会占有整个字节，不过位域也遵循内存对齐的原则

1.  位域的宽度不能超过底层类型的宽度
2.  多个位域可以共享同一底层类型，当底层类型不够存储位域时，将从下一分配单位开始存储
3.  允许空位域用以占位，则将不使用空位域
4.  大小为零的空位域将强制填充剩下的位，之后的位域将从新的分配单位开始存储
5.  位域是否可以 **跨字节** 与 **打包方式**，由实现而定

<!--listend-->

```C++
struct J {
    int j_a :6;
    int j_b :4; // 与 j_c 共享字节
    int j_c :4; // 与 j_b 共享字节
    char j_d;
    // 1 byte
}; // sizeof(J): 4, alignof(J): 4
struct K {
    int k_a :3;
    int     :4; // 与 k_a 共享字节
    int k_b :2; // 独占一字节
    char k_c;
    // 1 byte
}; // sizeof(K): 4, alignof(K): 4
struct L {
    int l_a  :3;
    int      :0; // 将 int 剩下的部分填充
    char l_b :2;
    char l_c;
    // 2 bytes
}; // sizeof(L): 8, alignof(L): 4
```

一个内存位置是

1.  一个标量类型 (算术类型、指针类型、枚举类型或 ::std::nullptr_t) 对象
2.  或非零长位域的最大相接序列

C++的各种功能特性，例如引用和虚函数，可能涉及到程序不可访问，但为实现所管理的额外内存位置。

```C++
struct S {
    char a;     // 内存位置 #1
    int b : 5;  // 内存位置 #2
    int c : 11, // 内存位置 #2 （延续）
          : 0,
        d : 8;  // 内存位置 #3
    struct {
        int ee : 8; // 内存位置 #4
    } e;
} obj; // 对象 'obj' 由 4 个分离的内存位置组成
```


### 内存位置与并发 {#内存位置与并发}

当多个线程访问不同的内存位置时将不会存在任何问题，但是当写入与读取在同一内存位置时将会产生数据竞争，当然也有特例不会引起数据竞争

1.  两个同一内存位置上的操作在 **同一线程** 上
2.  冲突是 **原子操作**
3.  一个冲突操作发生 **早于** 另一个

对象都有在初始化开始阶段确定好修改顺序的，大多数情况下，这个顺序不同于执行中的顺序，但在给定的程序中，所有线程都需要遵守这个顺序。如果对象不是原子类型，必须确保有足够的同步操作，确定线程都遵守了修改顺序。


## 同步操作和强制排序 {#同步操作和强制排序}


### 相关术语 {#相关术语}

线程间同步和内存顺序决定表达式的求值和副效应如何在不同的执行线程间排序

同步于 (synchronizes-with)
: 修改原子对象 M 的求值 A，对于其他线程可见

先序于 (sequenced-before)
: 在同一线程中求值 A 可以先序于求值 B

携带依赖 (carries dependency)
: 在同一线程中若下列任一为真，则先序于求值 B 的求值 A 可能也会将依赖带入 B
    -   A 的值被用作 B 的运算数，除了
        -   B 是对 ::std::kill_dependency 的调用
        -   A 是内建 &amp;&amp;、||、?: 或 , 运算符的左运算数
    -   A 写入标量对象 M，B 从 M 读取
    -   A 将依赖携带入另一求值 X，而 X 将依赖携带入 B

修改顺序 (modification order)
: 对任何特定的原子变量的修改，以限定于此一原子变量的单独全序出现，对所有原子操作保证下列四个要求
    -   **写写连贯:** 若修改某原子对象 M 的求值 A `先发于` 修改 M 的求值 B，则 A 在 M
        的修改顺序中早于 B 出现
    -   **读读连贯:** 若某原子对象 M 的值计算 A `先发于` 对 M 的值计算 B，且 A 的值来自对 M 的写操作 X，则 B 的值要么是 X 所存储的值，要么是在 M 的修改顺序中后于 X 出现的 M 上的副效应 Y 所存储的值
    -   **读写连贯:** 若某原子对象 M 的值计算 A `先发于` 修改 M 的求值 B，则 A 的值来自 M 的修改顺序中早于 B 出现的副效应 X
    -   **写读连贯:** 若某原子对象 M 上的副效应 X `先发于` M 的值计算 B，则求值 B 应从 X 或从 M 的修改顺序中后随 X 的副效应 Y 取得其值

释放序列 (release sequence)
: 在原子对象 M 上执行一次释放操作 A 之后，M 的修改顺序的最长连续子序列被称为以
    A 为首的释放序列
    -   由执行 A 的同一线程所执行的写操作 (C++20前)
    -   任何线程对 M 的原子的读-改-写操作

依赖先序于 (dependency-ordered before)
: 在线程间若下列任一为真，则求值 A 依赖先序于求值 B
    -   A 在某原子对象 M 上进行释放操作，而不同的线程中 B 在同一原子对象 M 上进行消费操作，而 B 读取 A (`所引领的释放序列的任何部分 (C++20 前)`) 所写入的值
    -   A 依赖先序于 X 且 X 携带依赖到 B

线程间先行发生 (inter-thread happens-before)
: 在线程间若下列任一为真，则求值 A 线程间先行发生于求值 B
    -   A 同步于 B
    -   A 依赖先序于 B
    -   A 同步于某求值 X，且 X 先序于 B
    -   A 先序于某求值 X，且 X 线程间先行发生于 B
    -   A 线程间先行发生于某求值 X，且 X 线程间先行发生于 B

先行发生 (happens-before)
: 先行发生无关乎线程，若下列任一为真，则求值 A 先发生于求值 B
    -   A 先序于 B
    -   A 线程间先发生于 B


### 内存顺序 {#内存顺序}

C++ 标准定义了六种原子操作的内存顺序，它们代表了四种内存模型：

自由序 (Relaxed ordering)
: `memory_order_relaxed`，没有同步或顺序制约，仅对此操作要求原子性

消费-释放序 (Consume-Release ordering)
: -   `memory_order_consume`，当前线程中依赖于当前加载的该值的读或写不能被重排到此加载前；其他释放同一原子变量的线程对数据依赖变量的写入，为当前线程所可见
    -   `memory_order_release`，当前线程中读或写不能被重排到此存储后；当前线程的所有写入，对其他获取同一原子变量的线程可见，对原子变量的带依赖写入变得对其他消费同一原子对象的线程可见

获取-释放序 (Acquire-Release ordering)
: -   `memory_order_acquire`，当前线程中读或写不能被重排到此加载前；其他释放同一原子变量的线程的所有写入，能为当前线程所见
    -   `memory_order_acq_rel`，所有释放同一原子变量的线程的写操作在当前线程修改前可见，当前线程改操作对其他获取同一原子变量的线程可见

顺序一致性 (Sequentially-consistent ordering)
: `memory_order_seq_cst`，原子操作的默认内存序，所有线程以同一顺序观测到所有修改

在不同的原子操作上，可以用到的内存序也有所不同

store (写操作)
: `memory_order_relaxed`, `memory_order_release`, `memory_order_seq_cst`

load (读操作)
: `memory_order_relaxed`, `memory_order_consume`, `memory_order_acquire`, `memory_order_seq_cst`

read-modify-write (读改写操作)
: `memory_order_relaxed`, `memory_order_consume`, `memory_order_acquire`,
    `memory_order_release`, `memory_order_acq_rel`, `memory_order_seq_cst`


#### 自由序 {#自由序}

带标签 `memory_order_relaxed` 的原子操作，它们不会在同时的内存访问间强加顺序，它们只保证原子性和修改顺序一致性，典型应用场景为 **计数器自增**

```C++
// x = {0}, y = {0}
// thread 1
r1 = y.load(::std::memory_order_relaxed); // A
x.store(r1, ::std::memory_order_relaxed); // B
// thread 2
r2 = x.load(::std::memory_order_relaxed); // C
y.store(42, ::std::memory_order_relaxed); // D
assert(r1 != 42 || r2 != 42); // E
```

A 先序于 B，C 先序于 D，但 D 在 y 上的副效应可能对 A 可见，同时 B 在 x 上的副效应可能对 C 可见，所以允许 E 断言失败。

另外自由序中，当前线程可能看到别的线程的更新，但是更新频率不一定是均匀的，但其值一定是递增的。详细例子可以查看 C++ Concurrency in Action (2rd) 中电话计数员的例子。


#### 消费-释放序 {#消费-释放序}

若线程 A 中的原子存储带标签 `memory_order_release` 而线程 B 中来自同一对象的读取存储值的原子加载带标签 `memory_order_consume`，则线程 A 视角中先发生于原子存储的所有内存写入，会在线程 B 中该加载操作所携带依赖进入的操作中变成可见副效应，即一旦完成原子加载，则保证线程 B 中使用从该加载获得的值的运算符和函数能见到线程 A 写入内存的内容。同步仅在释放和消费同一原子对象的线程间建立，其他线程能见到与被同步线程的一者或两者相异的内存访问顺序。

此顺序的典型使用情景，涉及对 **很少被写入** 的数据结构的同时时读取，和 **有指针中介发布** 的 `发布者-订阅者` 情形，即当生产者发布消费者能通过其访问信息的指针之时：无需令生产者写入内存的所有其他内容对消费者可见。这种场景的例子之一是 [rcu 解引用](https://en.wikipedia.org/wiki/Read-copy-update)。

```C++
::std::atomic<::std::string*> ptr;
int data;
void producer() {
    ::std::string* p  = new ::std::string("Hello");
    data = 42;
    ptr.store(p, ::std::memory_order_release);
}
void consumer() {
    ::std::string* p2;
    while (!(p2 = ptr.load(::std::memory_order_consume)));
    assert(*p2 == "Hello"); // 断言成功 (*p2 从 ptr 携带依赖)
    assert(data == 42); // 断言可能失败 (data 不从 ptr 携带依赖)
}
```


#### 获取-释放序 {#获取-释放序}

若线程 A 中的一个原子存储带标签 `memory_order_release`，而线程 B 中来自同一变量的原子加载带标签 `memory_order_acquire`，则从线程 A 的视角先发生于原子存储的所有内存写入，在线程 B 中成为可见副效应，即一旦原子加载完成保证线程 B 能观察到线程
A 写入内存的所有内容。此顺序的典型使用场景是 **互斥量**

```C++
::std::atomic<::std::string*> ptr;
int data;
void producer() {
    ::std::string* p  = new ::std::string("Hello");
    data = 42;
    ptr.store(p, ::std::memory_order_release);
}
void consumer() {
    ::std::string* p2;
    while (!(p2 = ptr.load(::std::memory_order_acquire)));
    assert(*p2 == "Hello"); // 断言成功
    assert(data == 42); // 断言成功
}
```


#### 顺序一致性 {#顺序一致性}

带标签 `memory_order_seq_cst` 的原子操作不仅以与释放/获得顺序相同的方式排序内存
(在一个线程中先发生于存储的任何结果都变成进行加载的线程中的可见副效应)，还对所有带此标签的内存操作建立单独全序。

```C++
void write_x() {
    x.store(true, ::std::memory_order_seq_cst);
}
void write_y() {
    y.store(true, ::std::memory_order_seq_cst);
}
void read_x_then_y() {
    while (!x.load(::std::memory_order_seq_cst));
    if (y.load(::std::memory_order_seq_cst)) {
        ++z;
    }
}
void read_y_then_x() {
    while (!y.load(::std::memory_order_seq_cst));
    if (x.load(::std::memory_order_seq_cst)) {
        ++z;
    }
}
assert(z.load() != 0); // 断言成功
```

全序列顺序在所有多核系统上要求完全的内存栅栏 CPU 指令，这可能成为性能瓶颈，因为它强制受影响的内存访问传播到每个核心。


### 栅栏 {#栅栏}

栅栏操作会对内存序列进行约束，使其无法对任何数据进行修改，典型的做法是与使用
`memory_order_relaxed` 约束序的原子操作一起使用。栅栏属于全局操作，执行栅栏操作可以影响到在线程中的其他原子操作，因为这类操作就像画了一条任何代码都无法跨越的线一样，所以栅栏操作通常也被称为 **内存栅栏** (memory barriers)。我们以下代码与 `获取-
释放序` 代码效果相同

```C++
::std::atomic<::std::string*> ptr;
int data;
void producer() {
    ::std::string* p  = new ::std::string("Hello");
    data = 42;
    ::std::atomic_thread_fence(::std::memory_order_release);
    ptr.store(p, ::std::memory_order_relaxed);
}
void consumer() {
    ::std::string* p2;
    while (!(p2 = ptr.load(::std::memory_order_relaxed)));
    ::std::atomic_thread_fence(::std::memory_order_acquire);
    assert(*p2 == "Hello"); // 断言成功
    assert(data == 42); // 断言成功
}
```

