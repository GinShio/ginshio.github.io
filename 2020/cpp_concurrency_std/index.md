# 并发标准库


## 线程管理 {#线程管理}


### 创建线程 {#创建线程}

新的线程会在 `::std::thread` (头文件 _thread_ 中) 对象创建的时候被启动，在函数执行完毕后，该线程也就结束了，提供的函数对象会复制到新线程的存储空间中，函数对象的执行与操作都在线程的内存空间中执行。在创建新线程时你可以指定一个函数作为任务，或者是 **仿函数**，当然也可以是 lambda 表达式

```C++
::std::thread my_thread0{do_something};
struct Task {
    void operator()() const {
	do_something();
    }
};
::std::thread my_thread1{Task()};
::std::thread my_thread2{[]() {
    do_something();
}};
```

线程启动后，需要指定是`等待线程结束`还是`让其自主运行`，如果 `::std::thread` 对象销毁之前没有做出决定，程序就会终止，因此必须确保线程能够正确 **汇入** (joined)
或 **分离** (detached)。调用 join() 可以等待线程完成，并在线程结束时清理相关的内存，使 ::std::thread 对象不再与已完成线程有任何关联，所以一个线程一旦被汇入将不能再次汇入。调用 detach() 会使线程在后台运行，不再与主线程进行直接交互， ::std::thread
对象不再引用这个线程，分离的线程也不可被再次汇入，不过C++运行时库保证线程退出时可以正确回收相关资源。

在C++中 ::std::thread 对象是一种 **可移动但不可复制** 的资源，它可以交出它的所有权，但不能与其他对象共享线程的所有权。如果你希望对一个已持有线程的对象更改其行为，那你必须先汇入或分离已关联的线程，或者将已关联的线程的所有权交出。

```C++
::std::thread t1{do_something};
::std::thread t2 = std::move(t1);
t1 = std::thread{some_other_function};
std::thread t3;
t3 = std::move(t2);
// t1 = std::move(t3); // 错误
```


### 传递参数 {#传递参数}

向线程中传递参数十分简单，为 ::std::thread 构造函数附加参数即可，所有参数 将会拷贝到新线程的内存空间中，即使函数中的参数是引用

```C++
void f1(int i, const ::std::string& s);
void f2(int i, ::std::string& s);
::std::thread t1{f1, 3, ::std::string{"Hello"}};
t1.join();
// ::std::thread t2{f2, 2, ::std::string{"Hello"}}; // Error
// t2.join();
```

这里 f2 期望传入一个::std::string的引用，传递参数时会将拷贝的参数以右值的方式进行传递 (为了支持移动的类型)，与函数期望的非常量引用不符，故会在编译期报错。不过我们可以使用 `::std::ref` 将参数转换为引用的形式进行传递

```C++
auto s = ::std::string{"Hello"};
::std::thread t2{f2, 6, ::std::ref(s)};
t2.join();
```

当然也可以在一个线程上运行一个成员函数，做法也是很简单的，第一个参数传递成员函数的指针，第二个参数传递这个类的对象的指针，剩下的则是这个待运行的函数的参数

```C++
struct X {
    void do_something(int);
} x;
::std::thread t3{&X::do_something, &x, 1};
```


### 线程标识 {#线程标识}

线程的标识类型是 `::std::thread::id` ，可以使用 ::std::thread 对象的成员函数
`get_id()` 获取，当线程没有和任何执行线程关联时将返回默认值来表示 **无线程**; 也可以使用 `::std::this_thread::get_id()` 来获取当前线程的标识。`::std::thread::id` 对象可以拷贝或对比，因为标识符是可复用的，当两个标识符相等时代表**同一个线程**或这两个线程**无关联线程**

```C++
if (master_thread_id == ::std::this_thread::get_id()) {
    master_do_something();
} else {
    worker_do_something();
}
```


## 共享数据 {#共享数据}

涉及到共享数据时，问题就是因为共享数据的修改所导致，如果共享数据只读，那么不会影响到数据，更不会对数据进行修改，所有线程都会获得同样的数据。但当一个或多个线程要修改共享数据时，就会产生很多麻烦，需要小心谨慎，才能确保所有线程都正常工作。


### 条件竞争 {#条件竞争}

并发中的竞争条件，取决于一个以上线程的执行顺序，每个线程都抢着完成自己的任务，大多数情况下，即使改变执行顺序，也是良性竞争，结果是可以接受的。遗憾的是，当不变量遭到破坏时会产生条件竞争，通常是恶性竞争：并发的去修改一个独立对象。恶性竞争时对一个数据块进行修改时，其他线程可能同时对其进行访问，导致数据不一致或与预期不符，并且出现概率低且难复现。

避免恶性竞争，最简单的方法就是对数据结构采用某种**保护机制**，确保只有修改线程可以看到不变量的中间状态，其他线程观察结构时会发现其修改还未开始。另一方式就是对数据结构与不变量进行修改，修改后的结构可以完成一系列不可分割的变量，从而保证不变量的状态，即**无锁编程**。


### 互斥量 {#互斥量}

访问共享数据前将数据锁住，在访问结束后再将数据解锁，当线程使用互斥量锁住共享数据时，其他的线程都必须等到之前那个线程对数据进行解锁后，才能进行访问数据。

通过实例化 `::std::mutex` (头文件 _mutex_ 中) 创建互斥量实例，成员函数lock()可对互斥量上锁，unlock()为解锁，不过不推荐使用成员函数，因为你必须在函数的出口处正确的解锁，其中包括异常情况也必须保证正确解锁，否则互斥量可能无法正常使用。推荐的做法是使用互斥量RAII模板类 `::std::lock_guard` (头文件 _mutex_ 中)，构造时加锁并在析构时解锁，保证互斥量可以被正确的解锁。

下面例子中，如果多个线程访问add_n函数，那么互斥量mu就会保护变量 `result` ，在一个线程中修改它时其他线程将无法访问它， \\(result += i\\) 将会在线程中安全的执行，不会因为数据竞争导致线程看到的result脏值，从而污染结果

```C++
::std::mutex mu;
void add_n(const long long& n, long long& result) {
    for (long long i = 1ll; i <= n; ++i) {
	::std::lock_guard<::std::mutex> guard(mu);
	result += i;
    }
}
```

不过通常互斥量会与需要保护的数据封装在同一个类中，让它们联系在一起，保证数据不变量的稳定状态。不过当类中某个方法返回保护数据的指针或者引用时，可能会破坏数据，此时需要谨慎的对接口进行设计，切勿将受保护数据的指针或引用传递到互斥锁作用域之外。

使用互斥量保护数据时，还需要考虑接口间的条件竞争，比如常使用的 ::std::stack，以下代码在单线程中是正确的，但是当 ::std::stack 是共享数据时，虽然每次调用接口时内部可能返回正确的结果，但是当用户使用时可能并非安全的。很明显代码中，top() 调用时很可能其他线程已经 pop() 了最后一个元素，虽然该线程访问到栈不为空，但是 top() 获取到错误的结果，`top()` 与 `pop()` 存在数据竞争关系

```C++
::std::stack<int> s;
if (!s.empty()) {
    const int value = s.top();
    s.pop();
    do_something(value);
}
```

锁的粒度太小，恶性条件竞争已经出现，需要保护的操作并未全覆盖到; 如果锁的粒度太大，会抵消并发带来的性能提升。


#### 死锁 {#死锁}

使用多个互斥量操作时需要注意 **死锁**，这会让两个线程互相等待，直到另一个解锁互斥量。死锁产生的必要条件:

互斥条件
: 一个资源每次只能被一个任务使用

占有且等待
: 因请求资源而阻塞时，对已获得的资源保持不放

不可剥夺
: 已获得的资源，在末使用完之前，不能强行剥夺

循环等待条件
: 若干任务之间形成一种头尾相接的循环等待资源关系

一般在C++使用互斥量时，避免循环等待即可，对多个互斥量可以使用标准库中的
`::std::lock` 与 `::std::lock_guard` 进行RAII锁定，可以按照一定的顺序对互斥量进行锁定，避免循环锁定。以下代码展示了一次锁定多个互斥量，::std::lock 锁定互斥量，并创建两个 ::std::lock_guard 对象对互斥量进行管理，`::std::adopt_lock` 表示
::std::lock_guard 可以获取锁并将锁交给其管理，::std::lock_guard 对象不需要再构建新的锁。值得一提的是，::std::lock 可能会抛出异常，但是请放心，已锁定的锁会随着异常而自动释放，所以 ::std::lock 要么 **全部锁住** 要么 **一个都不锁**

```C++
void swap(X& lhs, X& rhs) {
    if (&lhs == &rhs) {
	return;
    }
    ::std::lock(lhs.mu, rhs.mu);
    ::std::lock_guard<::std::mutex> lockl{lhs.mu, ::std::adopt_lock};
    ::std::lock_guard<::std::mutex> lockr{rhs.mu, ::std::adopt_lock};
    ::std::swap(lhs.data, rhs.data);
}
```

C++17 中提供了RAII模板类 `::std::scoped_lock` (头文件 _mutex_ 中) 用来支持这种情况，并且增加了 **自动推导模板参数**，是所以这种情况在 C++17 中将会更简单的实现

```C++
void swap(X& lhs, X& rhs) {
    if (&lhs == &rhs) {
	return;
    }
    ::std::scoped_lock guard{lhs.mu, rhs.mu};
    // 等价于:
    // ::std::scoped_lock<::std::mutex, ::std::mutex> guard{lhs.mu, rhs.mu};
    ::std::swap(lhs.data, rhs.data);
}
```

死锁通常是对锁的使用不当造成，当然也可以是其他情况，不过我们应该尽可能的避免死锁

避免嵌套锁
: 获取一个锁时就别再获取第二个，需要获取多个锁时应使用 ::std::lock
    来完成

避免在持有锁时调用外部代码
: 代码是由外部提供的，我们无法确定外部的行为，可能会造成与第一条违反的情况

使用固定顺序获取锁
: 当有多个锁且无法使用 ::std::lock 时，应在每个线程上以固定的顺序获取锁


#### 灵活的管理锁 {#灵活的管理锁}

标准库提供了一种灵活的RAII管理锁的方式 `::std::unique_lock` (头文件 _mutex_ 中)，它允许使用 `::std::adopt_lock` 假设已拥有互斥的所有权，也允许使用
`::std::defer_lock` 假设不获取互斥的所有权，使用 ::std::unique_lock 会与
::std::lock_guard 的实现方式等价。::std::unique_lock 对象中带有标志来确定是否持有互斥量，并确保正确地在析构函数中处理互斥量

```C++
void swap(X& lhs, X& rhs) {
    if (&lhs == &rhs) {
	return;
    }
    ::std::unique_lock<::std::mutex> lockl{lhs.mu, ::std::defer_lock};
    ::std::unique_lock<::std::mutex> lockr{rhs.mu, ::std::defer_lock};
    ::std::lock(lockl, lockr); // 持有的互斥量并锁定
    ::std::swap(lhs.data, rhs.data);
}
```

::std::unique_lock 是一种可移动不可复制的类型，它可以交出已持有互斥量的所有权，使互斥量在不同作用域中传递

```C++
::std::unique_lock<::std::mutex> get_lock() {
    extern ::std::mutex mu;
    ::std::unique_lock<::std::mutex> lk{mu};
    do_something();
    return lk;
}
void other() {
    ::std::unique_lock<::std::mutex> lk{get_lock()};
    do_something();
}
```

::std::unique_lock 还支持在对象销毁之前放弃持有互斥，这样可以提前为其他等待线程释放锁，增加性能。

锁的粒度是用来描述锁保护的数据量的大小，**细粒度锁** (fine-grained lock) 能够保护较小的数据量，**粗粒度锁** (coarse-grained lock) 能够保护较多的数据量。比如数据库中，对一行进行锁定的锁比对整张表锁定的锁粒度小，行锁相对于表锁性能更高，因为可以同时处理多行，但是也更不安全。


### 保护共享数据的方式 {#保护共享数据的方式}


#### 保护共享数据的初始化过程 {#保护共享数据的初始化过程}

如果一个资源构造代价昂贵，我们可能会使用延迟初始化来构造它，不过这在单线程下是安全的，多线程下初始化是需要被保护的，不然可能会出现多次初始化的情况

```C++
void foo() {
    ::std::unique_lock<::std::mutex> lk{mu};
    if (data.empty()) {
	data = new element();
    }
    lk.lock();
    do_something();
}
```

双重检测锁定模式 (DCLP) 也是一种保护初始化的状态，不过遗憾的是，它存在潜在的条件竞争，即线程可能得知其他线程完成了初始化，但可能没有看到新创建的实例，在调用
do_something()时得到不正确的结果。Java引入了volatile关键字并安全地实现了DCLP，
C++11开始我们也可以实现安全的DCLP。详细可以阅读 [C++与双重检测锁定模式的风险](https://www.aristeia.com/Papers/DDJ_Jul_Aug_2004_revised.pdf)，我们也可以在之后的学习中学习安全的DCLP实现

```C++
// DCLP
void bar() {
    if (data.empty()) {
	::std::lock_guard<::std::mutex> lk{mu};
	if (data.empty()) {
	    data = new element();
	}
    }
    do_something(); // 数据竞争
}
```

不过我们可以不这么麻烦，C++标准库为我们提供了 `::std::once_flag` 与
`::std::call_once` (头文件 _mutex_ 中) 来处理这种情况，并且相比使用互斥量所消耗的资源更少

```C++
::std::once_flag once;
void func() {
    ::std::call_once(once，[]() {
	data = new element();
    });
    do_something();
}
```

局部作用域中的static变量在声明后就已经完成初始化，对于C++11之前初始化的过程中存在条件竞争，但是从 **C++11** 开始初始化与定义完全在一个线程中发生

```C++
element get_element_instance() {
    static element instance; // C++11 开始为线程安全的初始化
    return instance;
}
```


#### 保护不常更新的数据结构 {#保护不常更新的数据结构}

当有不常更新的数据结构时，我们希望在修改时线程可以独占并安全的修改内容，完成修改后可以并发的安全访问数据。使用 ::std::mutex 来保护这样的数据结构对于性能来说并不是一个很好的方法，这会削弱读取数据的性能。我们可以想象这样一种互斥量，它可以在
**写** 线程中独占访问，而允许 **读** 线程并发访问，这样的互斥量被称为 **读写锁**，读线程需要等写线程释放锁后才可以并发访问，而写线程必须等全部读线程放弃互斥量后才可以独占访问。

C++17标准库提供了 `::std::shared_mutex` (头文件 _shared_mutex_ 中)，C++14提供了
RAII模板类 `::std::shared_lock` 与有时限的读写锁 `::std::shared_timed_mutex` (头文件
_shared_mutex_ 中)，可惜的是C++11中并没有提供相应的设施。timed_mutex系列互斥量相比普通互斥量，多了时限功能，在时限内可以获得锁则返回true并获得锁，否则返回false
并不能获得锁，不过普通的互斥量则相较有更高的性能。在读写锁的使用中，对于写线程可以使用 `::std::lock_guard<::std::shared_mutex>` 或 `::std::unique_lock<::std::shared_mutex>`
进行RAII管理，它们与普通的互斥量行为一致；对于读线程，则需要
`::std::shared_lock<::std::shared_mutex>` 进行RAII管理

```C++
class DnsCache {
  ::std::map<::std::string，::std::string> entries_;
  mutable std::shared_mutex mu_;
 public:
  ::std::string find(const ::std::string& domain) const {
    ::std::shared_lock<::std::shared_mutex> lk{mu_};
    auto it = entries_.find(domain);
    return (it == entries_.end()) ? "" : it->second;
  }
  void update(const ::std::string& domain, const ::std::string& ip) {
    ::std::lock_guard<::std::shared_mutex> lk{mu_};
    entries_[domain] = ip;
  }
};
```


#### 重入锁 {#重入锁}

在一个线程上，对已上锁的 ::std::mutex 再次上锁是错误的，会引起未定义行为，如果希望在线程上对一个互斥量在释放前进行多次上锁，则需要使用 `::std::recursive_mutex` (头文件 _mutex_ 中)。当然要牢记，你对其上锁了多少次，那一定需要解锁多少次，否则就会出现锁死其他线程的情况 (请善用 ::std::lock_guard 与 ::std::unique_lock)


## 同步操作 {#同步操作}


### 等待条件 {#等待条件}

通过一条线程触发等待事件的机制是最基本的唤醒方式，这种机制被称为 **条件变量**，条件变量与多个事件或其他条件相关，并且一个或多个线程会等待条件的达成。当某些线程被终止时，为了唤醒等待线程，终止线程会向等待着的线程广播信息。

C++标准库实现了条件变量 (头文件 _condition_variable_ 中)
`::std::condition_variable` 和 `::std::condition_variable_any` ，它们需要与互斥量一起才能工作，前者需要和 ::std::mutex 一起工作，而 \_any 后缀的条件变量可以和任何互斥量一起，但是相比普通条件变量更消耗系统资源。

```C++
::std::mutex mu;
::std::queue<data_chunk> q;
::std::condition_variable cond;
void preparation() {
    while (more()) {
	const data_chunk data = get_data();
	::std::lock_guard<::std::mutex> lk{mu};
	q.push(data);
	cond.notify_one();
    }
}
void processing() {
    while (true) {
	::std::unique_lock<::std::mutex> lk{mu};
	cond.wait(lk, [] { return !q.empty(); });
	data_chunk data = q.front();
	q.pop();
	lk.unlock();
	process(data);
	if (is_last_chunk(data)) {
	    break;
	}
    }
}
```

以上代码就是一个条件变量的应用，执行情况如下

1.  preparation 线程将获取数据，上锁互斥量并将数据压入队列
2.  processing 线程必须对互斥量进行锁定，之后才能调用条件变量的成员函数 wait()
    检查条件谓词，如果成立则继续，如果不成立将解锁互斥量并阻塞当前线程
3.  preparation 线程调用 notify_one() 会唤醒 **一个正在等待** 的线程，调用后需要解锁互斥量，如果没有等待线程则无事发生，notify_one() 不会唤醒调用后开始等待的线程
4.  如果 processing 线程被唤醒，则会重新获取锁，并再次进行条件谓词的检查

条件变量调用wait()的过程中，可能会多次检查条件谓词，并在谓词为true的情况下立即返回。另一点，等待线程可能会在不被其他线程通知的情况下被唤醒，这被称为 **虚假唤醒**，而虚假唤醒的数量和频率都是不确定的，所以条件谓词不建议有副作用。


### future {#future}

当线程需要等待特定事件时，某种程度上来说就需要知道期望的结果，线程会周期性的等待或检查事件是否触发，检查期间也会执行其他任务。另外，等待任务期间也可以先执行另外的任务，直到对应的任务触发，而后等待future的状态会变为就绪状态。future可能是和数据相关，也可能不是，当事件发生时，这个future就不能重置了。

C++标准库提供了两种future (头文件 _future_ 中) `::std::future` 和
`::std::shared_future`，它们与智能指针 ::std::shared_ptr 和 ::std::unique_ptr 十分类似。::std::future 只能与指定事件相关连，而 ::std::shared_future 可以关联多个事件，而实现中所有实例会同时变为就绪状态，并且可以访问与事件相关的数据。如果希望future与数据无关，则可以使用 **void** 的特化。future 像是线程通信，但是其本身并不提供同步访问，如果需要访问独立的future对象时则需要使用互斥量或类似同步机制进行保护，::std::shared_future 提供访问异步操作结果的机制，每个线程可以安全的访问自身
::std::shared_future 对象的副本。


#### 异步返回值 {#异步返回值}

我们可以使用 `::std::async` (头文件 _future_ 中) 和 ::std::future 启动一个异步任务，获取线程的返回值，当然等待返回值的线程会阻塞，直到 ::std::future 就绪为止

```C++
int async_func();
void do_something();
int main(void) {
    ::std::future<int> ret = ::std::async(async_func); // 异步执行 async_func
    do_something();
    ::std::cout << "Return: " << ::std::flush // 立即打印
		<< ret.get() << ::std::endl; // 阻塞，直到 future 就绪
}
```

::std::future 是否需要等待取决于绑定的 ::std::async 是否启动一个线程，或是否有任务正在进行，大多数情况下在函数调用之前可以传递一个 `::std::launch` 类型的对象

::std::launch::defered
: 惰性求值，延迟到 wait() 或 get() 时进行求值

::std::launch::async
: 异步求值，求值将在一个独立的线程上进行

::std::launch::async \\(|\\) ::std::luanch::defered
: 默认行为，惰性求值或异步求值，具体求值方式由实现定义

<!--listend-->

```C++
auto f0 = ::std::async(::std::launch::async, func0); // 异步求值
auto f1 = ::std::async(::std::launch::defered, func1); // 惰性求值
auto f2 = ::std::async(::std::launch::async | ::std::launch::defered, func2); // 求值方式由实现定义
auto f3 = ::std::async(func3); // 求值方式由实现定义
```


#### 绑定任务 {#绑定任务}

`::std::packaged_task` (头文件 _future_ 中) 允许将 future 与可调用对象进行绑定，::std::packaged_task 的模板参数是一个可调用类型，在调用 ::std::packaged_task 时就会调用相关函数，而 future 状态就绪时则会存储返回值，通过 get_future() 获取绑定的 future 对象。


#### Promise {#promise}

大部分并发编程语言都实现了 **Promise/Future** 结构，起源于函数式编程和相关范例，目的是将值与其计算方式分离，从而允许更灵活地进行计算，特别是通过并行化。后来它在分布式计算中得到了应用，减少了通信往返的延迟。future是变量的 **只读** 占位符视图，而
promise是 **可写** 的单赋值容器，用于设置future的值。

类模板 `::std::promise` (头文件 _future_ 中) 提供存储值或异常的设施，之后通过
::std::promise 对象所创建的 ::std::future 对象异步获得结果。::std::future 会阻塞等待线程，::std::promise 则会设置结果并将关联的 ::std::future 对象设置为就绪状态，不过
std::promise 只应当使用一次。

```C++
void accumulate(::std::vector<int>::iterator first,
		::std::vector<int>::iterator last,
		::std::promise<int> accumulate_promise) {
    int sum = ::std::accumulate(first, last, 0);
    accumulate_promise.set_value(sum);
}
int main(void) {
    ::std::vector<int> numbers = {1, 2, 3, 4, 5, 6};
    ::std::promise<int> accumulate_promise;
    ::std::future<int> accumulate_future = accumulate_promise.get_future();
    ::std::thread work_thread(accumulate, numbers.begin(), numbers.end(),
			      ::std::move(accumulate_promise));
    ::std::cout << accumulate_future.get() << ::std::endl; // 等待结果
    work_thread.join();
}
```

::std::shared_future 可用于同时向多个线程发信息, 类似于
`::std::condition_variable::notify_all()`

```C++
::std::promise<void> ready_promise, t1_promise, t2_promise;
::std::shared_future<void> ready_future{ready_promise.get_future()};
using high_resolution_clock = ::std::chrono::high_resolution_clock;
using milli = ::std::chrono::duration<double, ::std::milli>;
::std::chrono::time_point<high_resolution_clock> start;
auto result1 = ::std::async(::std::launch::async,
			    [&, ready_future]() -> milli {
				t1_promise.set_value();
				ready_future.wait(); // 等待来自 main() 的信号
				return high_resolution_clock::now() - start;
			    });
auto result2 = ::std::async(::std::launch::async,
			    [&, ready_future]() -> milli {
				t2_promise.set_value();
				ready_future.wait(); // 等待来自 main() 的信号
				return high_resolution_clock::now() - start;
			    });
t1_promise.get_future().wait();
t2_promise.get_future().wait();
start = std::chrono::high_resolution_clock::now();
ready_promise.set_value();
std::cout << "Thread 1 received the signal "
	  << result1.get().count() << " ms after start\n"
	  << "Thread 2 received the signal "
	  << result2.get().count() << " ms after start\n";
```


### 限时等待 {#限时等待}

阻塞调用会将线程挂起一段不确定的时间，直到相应的事件发生，通常情况下这样的方式很不错，但是在一些情况下，需要限定线程等待的时间。

通常有两种指定超时方式：一种是 **时间段**，另一种是 **时间点**。第一种方式，需要指定一段时间；第二种方式，就是指定一个时间点。多数等待函数提供变量，对两种超时方式进行处理，处理持续时间的变量 (**时间段**) 以 `_for` 作为后缀，处理绝对时间的变量
(时间戳) 以 `_until` 作为后缀。


#### 时钟 {#时钟}

时钟就是时间信息源，一个时钟的当前时间可由静态成员函数 `now()` 获取，特定的时间点的类型是成员类型 `time_point` 。时钟节拍被指定为1/x秒，这是由时间周期所决定，当时钟节拍均匀分布且不可修改时这种时钟被称为稳定时钟。


#### 时间段 {#时间段}

时间段 `::std::chrono::duration` (头文件 _chrono_ 中) 由 Rep 类型的 **计次数** 和
Period 类型的 **计次周期** 组成，计次周期是一个编译期有理数常量，表示从一个计次到下一个的秒数，比如分钟的类型可以使用 `::std::chrono::duration<long long,
::std::ratio<60, 1>>` 表示，而毫秒的类型可以使用 `::std::chrono::duration<long long,
::std::ratio<1, 1000>>` 表示。不过为了方便起见，标准库定义了辅助类型来简化使用

-   **::std::chrono::nanoseconds** (纳秒)
-   **::std::chrono::microseconds** (微秒)
-   **::std::chrono::milliseconds** (毫秒)
-   **::std::chrono::seconds** (秒)
-   **::std::chrono::minutes** (分)
-   **::std::chrono::hours** (时)

C++20开始，标准库又增加了天、周、月、年来方便使用时间段。

C++14 中，`::std::literals` 中定义了一些 duration 字面量方便使用

```C++
using namespace ::std::literals;
auto one_day = 24h; // 24小时
auto half_an_hour = 30min; // 30分钟
auto five_seconds = 5s; // 5秒
auto one_second = 1000ms; // 1000毫秒
auto ten_micros = 10us; // 10微秒
auto two_nanos = 2ns; // 2纳秒
```


#### 时间戳 {#时间戳}

时间戳 `::std::chrono::time_point` (头文件 _chrono_ 中) 由 Clock 类型的 **时钟** 和
Duration 类型的 **时钟间隔** 组成，并且可以通过算术运算调整时间戳。

```C++
std::chrono::system_clock::time_point now = std::chrono::system_clock::now();
std::time_t now_c = std::chrono::system_clock::to_time_t(now - std::chrono::hours(24));
std::cout << "24 hours ago, the time was "
	  << std::put_time(std::localtime(&now_c), "%F %T") << ::std::endl;
std::chrono::steady_clock::time_point start = std::chrono::steady_clock::now();
std::cout << "Hello World\n";
std::chrono::steady_clock::time_point end = std::chrono::steady_clock::now();
std::cout << "Printing took "
	  << std::chrono::duration_cast<std::chrono::microseconds>(end - start).count()
	  << "us.\n";
// 24 hours ago, the time was 2020-12-03 23:47:43
// Hello World
// Printing took 4us.
```
