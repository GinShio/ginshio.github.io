# 排序算法


> Sorting something that you will never search is a complete waste; searching something you never sorted is merely inefficient.
>
> --- Brian Christian

我们假设对数组进行排序，数组的所有位置都有元素，且长度为 N。对于排序，假设元素存在 \\(<\\) 和 \\(>\\) 用以将输入按一致的次序放置，比较运算是除赋值运算外仅有的能对输入数据进行的操作。这种条件下的排序称之为 **比较排序** (comparison-based sorting)。另外对于已经排序完成的数组，如果可以保持原本的数据次序我们称之为 **稳定排序**
(stable sorting)。

当然这与 STL 的算法有一点点出入，sort 接收的是迭代器来表示待排序的范围，以及一个可选的比较器。而且 sort 的底层算法也更加复杂，这里只是简单地说明各个基础排序。

```c++
template <class Iterator>
void sort(Iterator begin, Iterator end);
template <class Iterator, class Comparator>
void sort(Iterator begin, Iterator end, Comparator cmp);
```

为了方便理解，将使用 Wikipedia 上关于排序的动图来帮助理解这种排序。先放个大招

表格 [排序算法简要比较](#table--tbl:comparison-of-algorithm) 摘自 [Wikipedia](https://en.wikipedia.org/wiki/Sorting_algorithm#Comparison_of_algorithms)

<a id="table--tbl:comparison-of-algorithm"></a>
<div class="table-caption">
  <span class="table-number"><a href="#table--tbl:comparison-of-algorithm">Table 1</a>:</span>
  排序算法简要比较
</div>

| 名称       | 英文名称            | 稳定性           | \\(Time\_{avg}\\)                   | \\(Time\_{bad}\\)                   | \\(Mem\\)                      |
|----------|-----------------|---------------|-------------------------------------|-------------------------------------|--------------------------------|
| 冒泡排序   | bubble sort         | \\(\checkmark\\) | \\(\mathcal{O}(N^{2})\\)            | \\(\mathcal{O}(N^{2})\\)            | \\(\mathcal{O}(1)\\)           |
| 选择排序   | selection sort      | \\(\times\\)     | \\(\mathcal{O}(N^{2})\\)            | \\(\mathcal{O}(N^{2})\\)            | \\(\mathcal{O}(1)\\)           |
| 插入排序   | insertion sort      | \\(\checkmark\\) | \\(\mathcal{O}(N^{2})\\)            | \\(\mathcal{O}(N^{2})\\)            | \\(\mathcal{O}(1)\\)           |
| 希尔排序   | shell sort          | \\(\times\\)     | \\(\mathcal{O}(N^{\frac{3}{2}})\\)  | \\(\mathcal{O}(N^{2})\\)            | \\(\mathcal{O}(1)\\)           |
| 堆排序     | heap sort           | \\(\times\\)     | \\(\mathcal{O}(N\log\_{}{N})\\)     | \\(\mathcal{O}(N\log\_{}{N})\\)     | \\(\mathcal{O}(1)\\)           |
| 归并排序   | merge sort          | \\(\checkmark\\) | \\(\mathcal{O}(N\log\_{}{N})\\)     | \\(\mathcal{O}(N\log\_{}{N})\\)     | \\(\mathcal{O}(N)\\)           |
| 原地归并排序 | in-place merge sort | \\(\checkmark\\) | \\(\mathcal{O}(N\log\_{}^{2}{N})\\) | \\(\mathcal{O}(N\log\_{}^{2}{N})\\) | \\(\mathcal{O}(1)\\)           |
| 快速排序   | quick sort          | \\(\times\\)     | \\(\mathcal{O}(N\log\_{}{N})\\)     | \\(\mathcal{O}(N^{2})\\)            | \\(\mathcal{O}(\log\_{}{N})\\) |
| 桶排序     | bucket sort         | \\(\checkmark\\) | \\(\mathcal{O}(N + k)\\)            | \\(\mathcal{O}(N^{2} + k)\\)        | \\(\mathcal{O}(2^{k})\\)       |
| 计数排序   | counting sort       | \\(\checkmark\\) | \\(\mathcal{O}(N + r)\\)            | \\(\mathcal{O}(N + r)\\)            | \\(\mathcal{O}(N + r)\\)       |
| 基数排序 (LSD) | lsd radix sort      | \\(\checkmark\\) | \\(\mathcal{O}(N \frac{k}{d})\\)    | \\(\mathcal{O}(N \dfrac{k}{d})\\)   | \\(\mathcal{O}(N + 2^{d})\\)   |
| 基数排序 (MSD) | msd radix sort      | \\(\checkmark\\) | \\(\mathcal{O}(N \frac{k}{d})\\)    | \\(\mathcal{O}(N \dfrac{k}{d})\\)   | \\(\mathcal{O}(N + 2^{d})\\)   |

其中 k 为键的大小，d 为数位大小，r 为排序的数字的范围大小。


## 冒泡排序 {#冒泡排序}

冒泡排序 (bubble sort) 是一种简单的排序，它重复走访数据，对比两个相邻的元素，如果顺序错误就将它们交换位置，直到所有数据都在正确的位置上。实际上，bubble sort 是一种朴素的排序方式，其时间复杂度为 \\(\mathcal{O}(N^{2})\\) ，需要交换元素
\\(\mathcal{O}(N^{2})\\) 次。当然，这是一种稳定排序！

冒泡排序的具体做法如下：

1.  比较相邻的元素，如果位置不正确就交换
2.  对每一对相邻元素做同样的工作，直到结尾。当这一步完成后，最后一个元素将会正确的回到末尾位置
3.  针对所有相邻元素重复以上步骤 (除了刚刚摆放正确的元素)，直到没有可比较的元素为止

{{< figure src="https://upload.wikimedia.org/wikipedia/commons/3/37/Bubble_sort_animation.gif" width="40%" >}}

```c++
template <class Array>
void bubble_sort(Array& arr) {
  int len = arr.size();
  for (int i = 0; i < len; ++i) {
    for (int j = 0; j < len - i - 1; ++j) {
      if (arr[j + 1] < arr[j]) {
        swap(arr[j], arr[j + 1]);
      }
    }
  }
}
```


## 插入排序 {#插入排序}

插入排序 (insertion sort) 是一种直观的排序，由 \\(N-1\\) 趟 (pass) 排序组成。对于
\\(p=1\\) 到 \\(N-1\\) 趟，插入顺序保证从位置 0 到位置 p 上的元素为已排序状态。当然这基于一个事实：位置 0 到位置 \\(p-1\\) 上的元素都已排序过了。

插入排序的具体做法如下：

1.  从第一个元素开始，该元素可以认为是已被排序的
2.  取出下一个元素，在已排序的元素中从后向前扫描
3.  如果已排序的元素与这个取出的元素位置不正确，将取出的元素向前移动，直到位置正确或没有已排序元素可以比较
4.  将取出的元素插入这里，并重复步骤 2 ~ 4 直到所有元素都被排序

| 初始状态        | 34 | 8  | 64 | 51 | 32 | 21 | 当前取出元素 |
|-------------|----|----|----|----|----|----|--------|
| After \\(p=1\\) | 8  | 34 | 64 | 51 | 32 | 21 | 8      |
| After \\(p=2\\) | 8  | 34 | 64 | 51 | 32 | 21 | 64     |
| After \\(p=3\\) | 8  | 34 | 51 | 64 | 32 | 21 | 51     |
| After \\(p=4\\) | 8  | 32 | 34 | 51 | 64 | 21 | 32     |
| After \\(p=5\\) | 8  | 21 | 32 | 34 | 51 | 64 | 21     |

{{< figure src="https://upload.wikimedia.org/wikipedia/commons/2/25/Insertion_sort_animation.gif" width="40%" >}}

由于每个嵌套循环都花费 N 次迭代，因此插入排序时间复杂度为 \\(\mathcal{O}(N^{2})\\)
，对于 p 的每一个值最多执行 \\(p + 1\\) 次对已排序元素的检测，因此最多
\\(\sum\_{i=2}^{N}{i} = 2 + 3 + 4 + \cdots + N = \Theta(N^{2})\\) 。但是另一方面，如果输入的数据已经被排序了，那运行时间为 \\(\mathcal{O}(N)\\) ，而几乎有序的情况下，insertion sort
将会很快运行完毕。

```c++
template <class Array>
void insertion_sort(Array& arr) {
  int j, len = arr.size();
  for (int p = 1; p < len; ++p) {
    auto tmp = arr[p];
    for (j = p; j > 0 && tmp < arr[j - 1]; --j) {
      a[j] = a[j - 1];
    }
    a[j] = tmp;
  }
}
```


## 希尔排序 {#希尔排序}

希尔排序 (shell sort) 也称 **递减增量排序** (diminishing increment sort) 算法，是插入排序的一种更高效的改进版本，由发明者 Donald Shell 于 1959 年公布。Shell sort
基于 insertion sort 的以下两点性质而提出改进方法的：

-   insertion sort 在对几乎已经排好序的数据操作时效率高，即可以达到线性排序的效率
-   insertion sort 一般来说是低效的，因为插入排序每次只能将数据移动一位

Shell sort 使用序列 \\(h\_{1}, h\_{2}, \cdots, h\_{n}\\) 这样一个增量序列，其中 \\(h\_{1}=1\\) 。对于使用增量 \\(h\_{k}\\) 的排序，我们可以看做是对序列 \\(a[i + j \* h\_{k}] (j = 0, 1,
\cdots, n)\\) 进行的 insertion sort，在这一趟排序后，对于每个 i 则有 \\(a[i] \leq a[i +
h\_{k}]\\) ，即所有间隔为 \\(h\_{k}\\) 的元素都被排序了，此时成为是 \\(h\_{k}\\) 排序的
(\\(h\_{k}\\) sorted)。之后向前选取增量，直到增量为 1 的趟排序完，算法结束。

{{< figure src="https://upload.wikimedia.org/wikipedia/commons/d/d8/Sorting_shellsort_anim.gif" >}}

|              | \\(a\_{1}\\) | \\(a\_{2}\\) | \\(a\_{3}\\) | \\(a\_{4}\\) | \\(a\_{5}\\) | \\(a\_{6}\\) | \\(a\_{7}\\) | \\(a\_{8}\\) | \\(a\_{9}\\) | \\(a\_{10}\\) | \\(a\_{11}\\) | \\(a\_{12}\\) |
|--------------|--------------|--------------|--------------|--------------|--------------|--------------|--------------|--------------|--------------|---------------|---------------|---------------|
| input        | 62           | 83           | 18           | 53           | 7            | 17           | 95           | 86           | 47           | 69            | 25            | 28            |
| after step-5 | 17           | 28           | 18           | 47           | 7            | 25           | 83           | 86           | 53           | 69            | 62            | 95            |
| after step-3 | 17           | 7            | 18           | 47           | 28           | 25           | 69           | 62           | 53           | 83            | 86            | 95            |
| after step-1 | 7            | 17           | 18           | 25           | 28           | 47           | 53           | 62           | 69           | 83            | 86            | 95            |

Shell sort 虽然实现简单，但运行时间的分析却很难。Shell sort 的运行时间依赖于所选择的增量序列。

| 增量序列              | 时间复杂度                     |
|-------------------|---------------------------|
| \\(\frac{N}{2^{i}}\\) | \\(\Theta(N^{2})\\)            |
| \\(2^{i} - 1\\)       | \\(\Theta(N^{3/2})\\)          |
| \\(2^{i}3^{j}\\)      | \\(\Theta(N\log\_{}^{2}{N})\\) |

已知最好的步长序列是 Sedgewick 提出的 \\(1, 5, 19, 41, 109, \cdots\\) ，这是一个下标从 0
开始的序列，偶数下标对应的步长增量由 \\(9 \times 4^{i} - 9 \times 2^{i} + 1\\) 提供，奇数下标对应的步长增量由 \\(2^{i+2} \times (2^{i+2} - 3) + 1\\) 提供。在小数组中使用好的步长序列的 Shell sort 性能十分优秀。另外在大数组中，步长序列 \\((fib(i+2))^{2}\\) 表现优异。

```cpp
static constexpr std::size_t SHELL_SORT_GAPS[]{8929, 3905, 2161, 929, 505, 209, 109, 41, 19, 5, 1};
template <class Array>
void shell_sort(Array& arr) {
  auto len{arr.size()};
  for (const auto& gap : SHELL_SORT_GAPS) {
    for (std::size_t i = gap; i < len; ++i) {
      for (std::size_t j{i}; j >= gap and arr[j - gap] > arr[j]; j -= gap) {
        std::swap(arr[j], arr[j - gap]);
      }
    }
  }
}
```


## 堆排序 {#堆排序}

堆排序 (heap sort) 是基于上一篇中提到的 binary heap 的时间复杂度
\\(\mathcal{O}(N\log\_{}{N})\\) 的排序算法。如果我们要以升序排序数组，则将数组转换为一个 max heap，重复将 heap top 元素移除即可获取从大到小的序列。

{{< figure src="https://upload.wikimedia.org/wikipedia/commons/1/1b/Sorting_heapsort_anim.gif" width="40%" >}}

堆排序分为两个阶段，建立 max heap 与 N 次的移除操作。第一阶段建立 heap 需要最多
\\(2N\\) 次比较，而第二阶段移除元素，每次移除元素最多用到 \\(2\lfloor\log\_{}{i}\rfloor\\) 次比较。因此 heap sort 的最坏时间复杂度为 \\(\mathcal{O}(N\log\_{}{N})\\) ，而 heap sort 性能十分稳定，其平均时间复杂度也是 \\(\mathcal{O}(N\log\_{}{N})\\) 。

我们可以利用 heap-order property 实现额外空间复杂度 \\(\mathcal{O}(1)\\) 的原地算法：在每次将 heap top 移除 heap 时将其与堆尾互换并将堆的尺寸缩小 1，然后利用
percolate down 恢复 heap-order。

```c++
template <class Array>
void max_heapify(Array& arr, int start, int end) {
  int dad = start;
  int son = 1 + (dad << 1);
  while (son <= end) {
    if (son + 1 <= end && arr[son] < arr[son + 1]) {
      ++son;
    }
    if (arr[dad] > arr[son]) {
      return;
    }
    swap(arr[dad], arr[son]);
    dad = son;
    son = 1 + (dad << 1);
  }
}
template <class Array>
void heap_sort(Array& arr) {
  int len = arr.size();
  for (int i = (len >> 1) - 1; i >= 0; i--) {
    max_heapify(arr, i, len - 1);
  }
  for (int i = len - 1; i > 0; i--) {
    swap(arr[0], arr[i]);
    max_heapify(arr, 0, i - 1);
  }
}
```


### 基于堆排序的选择算法 {#基于堆排序的选择算法}

你可能不知道什么是选择算法，但是你应该听过这样一个问题，如何在一个序列中找出第 k
大的元素，当然第 k 小的元素也可以用这种办法。我们可以明确建堆的时间复杂度
\\(\mathcal{O}(N)\\) ，删除的时间复杂度 \\(\mathcal{O}(k\log\_{}{N})\\) ，总时间复杂度
\\(\mathcal{O}(N\log\_{}{N})\\) 。

```cpp
template <class Array>
void max_heapify(Array& a, int i, int heap_size) {
  int l = i * 2 + 1, r = i * 2 + 2, largest = i;
  if (l < heap_size && a[l] > a[largest]) {
    largest = l;
  }
  if (r < heap_size && a[r] > a[largest]) {
    largest = r;
  }
  if (largest != i) {
    swap(a[i], a[largest]);
    max_heapify(a, largest, heap_size);
  }
}
template <class Array>
void build_max_heap(Array& a, int heap_size) {
  for (int i = heap_size / 2; i >= 0; --i) {
    max_heapify(a, i, heap_size);
  }
}
template <class Array>
int selection_algorithm(Array& nums, int k) {
  int heap_size = nums.size();
  const int loop_exit_cond = heap_size - k + 1;
  build_max_heap(nums, heap_size);
  for (int i = nums.size() - 1; i >= loop_exit_cond; --i) {
    swap(nums[0], nums[i]);
    --heap_size;
    max_heapify(nums, 0, heap_size);
  }
  return nums[0];
}
```


## 归并排序 {#归并排序}

归并排序 (mergesort) 是 1945 年由 von Neumann 首次提出，以
\\(\mathcal{O}(N\log\_{}{N})\\) 最坏情形运行时间运行，而所使用的比较次数几乎是最优解。
mergesort 最基本的操作是合并两个已排序的表，而这个时间是线性的。递归地对前半部分数据和后半部分数据进行各自归并排序，将排序后的两部分合并得到最终的排序序列。

mergesort 是典型的 **divide-and-conquer** (分而治之) 算法，将问题 divide (分) 为一些小问题递归求解，并 conquering (治) 的阶段将分的阶段的解修补在一起。

{{< figure src="/images/algo-example-of-merge-sort.svg" width="55%" >}}

递归操作是自顶向下的，具体操作方法：

1.  申请空间，用以存放合并后的已排序序列
2.  设定指针，指向最初的两个已排序序列的起始位置
3.  比较指针所指向的元素，选择相对较小的放入合并空间，并移动指针到下一位置
4.  重复步骤 3 直到某一指针到达序列尾部
5.  将剩下的所有元素复制到合并空间

{{< figure src="https://upload.wikimedia.org/wikipedia/commons/c/c5/Merge_sort_animation2.gif" width="40%" >}}

```c++
template <class Array>
void merge_impl(Array& array, Array& reg, int start, int end) {
  if (start >= end) {
    return;
  }
  int len = end - start, mid = (len + start) >> 1;
  int start1 = start, end1 = mid;
  int start2 = mid + 1, end2 = end;
  merge_impl(array, reg, start1, end1);
  merge_impl(array, reg, start2, end2);
  int k = start;
  while (start1 <= end1 && start2 <= end2) {
    reg[k++] = array[start1] < array[start2] ? array[start1++] : array[start2++];
  }
  while (start1 <= end1) {
    reg[k++] = array[start1++];
  }
  while (start2 <= end2) {
    reg[k++] = array[start2++];
  }
  for (k = start; k <= end; ++k) {
    array[k] = reg[k];
  }
}
template <class Array>
void merge_sort(Array& array) {
  Array reg{array.size()}; // reg.size == array.size
  merge_impl(array, reg, 0, array.size() - 1);
}
```


### 归并排序的分析 {#归并排序的分析}

分析递归程序有一个经典技巧： **给运行时间写出一个递推关系** 。假设 N 是 2 的幂，从而总可以将它分裂成相等的两部分。对于 \\(N = 1\\) 归并排序所用时间为常数，记作 \\[T(1)
= 1.\\] 对 N 个数的归并排序用时等于完成两个大小为 \\(N/2\\) 的递归排序所用时间加上合并时间，记作 \\[T(N) = 2T(N/2) + N.\\]

-   第一种方法：对两边同时除以 N，于是 \\[\frac{T(N)}{N} = \frac{T(N/2)}{N/2} +
        1, \quad \frac{T(N/2)}{N/2} = \frac{T(N/4)}{N/4} + 1, \quad \cdots \quad, \quad\frac{T(2)}{2} =
        \frac{T(1)}{1} + 1.\\]
    将所有这些方程相加，实际上这些中间项都会被消去，我们称之为 **叠缩**
    (telescoping) 求和，最终结果为 \\[\frac{T(N)}{N} = \frac{T(1)}{1} +
        \log\_{}{N}.\\] 由此得到最终答案 \\[T(N) = N\log\_{}{N} + N =
        \mathcal{O}(N\log\_{}{N}).\\]

<!--listend-->

-   第二种方法：在等式右边不断代入递推关系，得到 \\[T(N) = 2T(N/2) + N, \quad T(N) =
        2(2(T(N/4)) + N/2) = 4T(N/4) + N, \quad T(N) = 8T(N/8) + N, \quad \cdots \quad, \quad T(N) =
        2^{k}T(N/2^{k}) + kN.\\]
    代入 \\(k=\log\_{}{N}\\) 得到 \\[T(N) = NT(1) + N\log\_{}{N} = N\log\_{}{N} + N =
        \mathcal{O}(N\log\_{}{N}).\\]

归并排序是比较次数最少的排序算法，其运行时间一般依赖于元素的比较与复制所消耗的时间。复杂的复制操作会降低排序速度，在递归交替层面我们可以从用谨慎地交换两个数组担任角色的方法，避免其来回的复制。另外复制操作的消耗依赖于编程语言，Java 中类都是采用引用传递，因此比较耗时很多但相对的移动元素快很多；C/C++ 中大对象的复制是十分缓慢的，而比较是快速的，可以考虑采用移动语义或者指针来优化复制带来的时间消耗。


### 在链表上进行归并排序 {#在链表上进行归并排序}

归并排序的递归实现是自顶向下的，而链表上常用自下向上的迭代思路。

首先解释代码中所用到的额外函数：

| 函数                          | 释义                            |
|-----------------------------|-------------------------------|
| `splice(dest, src, iterator)` | 将 src 中的元素 iterator 转移给 dest |
| `merge(dest, src)`            | 将有序的列表 dest 与 src 合并并转移到 dest 中 |
| `swap(a, b)`                  | 交换两个链表 a 与 b             |

需要特别注意的是， `splice` 是将结点转移，也就是说它直接将结点链接进 dest 而不是复制结点的值到 dest，因此 src 将不再存在该结点。而 `merge` 是将 src 转移进 dest
中，操作完成后 dest 是有序的 dest 与 src 的合并，而 src 中将不再有任何结点。代码的实现步骤如下：

1.  取出头结点转移给 transfer
2.  将 transfer 与 pool[cur] 中的元素合并，并将指针移动到下一个 pool
3.  重复步骤 2 直到 pool[cur] 为空，将 transfer 的所有元素转移到 pool[cur] 中
4.  如果 cur 与 end 相等，则将 end 加一
5.  如果 list 不为空，则重复步骤 1 到 4
6.  合并 pool 中的所有元素，直到 `pool[end - 1]` ，这就是排序之后的 list

<!--listend-->

```c++
void sort(list& l) {
  list transfer;
  list pool[48];
  int end = 0;
  for (int cur = 0; l.size() != 0; cur = 0) {
    splice(transfer, l, l.begin());
    while (cur < end && !empty(pool[cur])) {
      merge(transfer, pool[cur++]);
    }
    swap(pool[cur], transfer);
    if (cur == end) {
      ++end;
    }
  }
  for (int cur = 1; cur < end; ++cur) {
    merge(pool[cur], pool[cur - 1]);
  }
  swap(pool[end - 1], l);
}
```

有意思的一点，pool[i] 只会接纳 \\(2^{i} (i \in \mathbb{N})\\) 个已排序好的元素，因此
`pool[end - 1]` 中的是已排序的前半部分，而 `[0, end - 1)` 中则分散着后半部分链表。这种方法是一个稳定排序，时间复杂度 \\(\mathcal{O}(N\log\_{}{N})\\) ，并且这不会进行复制操作而是对结点进行操作。


## 快速排序 {#快速排序}

快速排序 (quicksort) 是在实践中已知排序算法中最快的，它的平均运行时间
\\(\mathcal{O}(N\log\_{}{N})\\) ，最坏情形为 \\(\mathcal{O}(N^{2})\\) ，当然只要稍加努力就可以避免这种情形。通过将 heapsort 与 quicksort 结合将得到对几乎所有输入的最快运行时间。

quicksort 同样利用了 divide-and-conquer 的思想，基本算法如下：

1.  如果 arr 中元素个数是 0 或 1 则返回
2.  取 arr 中任一元素 e 为 **枢纽元** (pivot)
3.  将 arr 的其他元素 \\(arr-\\{e\\}\\) 划分为两个不相交的集合 \\(arr\_{1} = \\{x \in
         arr-\\{e\\} | x \leq e\\}\\) 和 \\(arr\_{2} = \\{x \in arr-\\{e\\} | x \geq e\\}\\)
4.  返回 \\(\\{quicksort(arr\_{1}), e, quicksort(arr\_{2})\\}\\)

{{< figure src="https://upload.wikimedia.org/wikipedia/commons/6/6a/Sorting_quicksort_anim.gif" width="40%" >}}

显然算法是成立的，可是为什么 quicksort 比 mergesort 快。quicksort 递归的解决两个子问题并需要线性的划分集合，但这两个子集的大小是不保证相等的，在划分是选择适当的位置将非常的高效，以至于弥补大小不等的递归带来的消耗甚至超过 mergesort。


### 选择枢纽元 {#选择枢纽元}

虽然我们可以任意的原则 pivot，但显然一些选择是更优秀的。

错误的 pivot 选择方法
: 通常将第一个或最后一个作为 pivot 是简单的，如果输入随机那还是可以接受的，但如果已经预排序或逆序，那么这将造成劣质的分割，所有元素都被划分到一个集合当中。当然这种情况可能发生在所有递归中。这将造成时间花费上升到 \\(\mathcal{O}(N^{2})\\) ，而实际上算法什么都没有做。


一种安全的做法
: 随机选取 pivot 是一种非常安全的策略，但是随机数生成器却是一种相对昂贵的。


三数中值的分割法
: 一个 N 个数的中值是第 \\(\lfloor N/2 \rfloor\\) 个最大的数，pivot 的最好选择就是数组的中值。但是计算整个数组的中值无疑会降低算法的速度，往往采用选取三个元素并用它们的中值作为 pivot，当然可以随机选取三个值，但一般做法事选取左端、右端以及中间三个元素的中值作为 pivot。


### 分割策略 {#分割策略}

选取 pivot 后，最重要的就是如何处理等于 pivot 的元素，即我们希望将等于 pivot 的元素均分到 pivot 的两边，保证两边尽可能的平衡。

假设所有元素都不相同，那么我们用双指针 i 和 j 来指向两端的元素，前半部分是小于
pivot 的元素，后半部分则是大于 pivot 的元素。当 i 遇到大于 pivot 的元素时停下来，等待 j 寻找小于 povit 的元素，交换这两个位置的元素，然后继续，直到 i 和 j 交错，那么交错的位置就是 pivot 的位置。通过这种方法我们可以很轻松的划分 \\(arr\_{1}\\) 和
\\(arr\_{2}\\) 。

假设所有元素都是相同的，当遇到等于 pivot 的元素时，显然 `只让` 指针 i 停止 (即
\\(arr\_{1} = \\{x \in arr-\\{e\\} | x < e\\}\\)) 或 `只让` 指针 j 停止 (即 \\(arr\_{2} =
\\{x \in arr-\\{e\\} | x > e\\}\\))，都会导致指针偏向其中一边。而都不停止，也是同样的结果，其时间复杂度会是 \\(\mathcal{O}(N^{2})\\) 。现在仅剩下的方法就是让 i 和 j 在遇到等于 pivot 的元素时，停下来并交换元素，这样会造成大量无意义的交换，但是可以将
\\(arr\_{1}\\) 与 \\(arr\_{2}\\) 分割为大小几乎相等的集合，归并排序告诉我们其运行时间为
\\(\mathcal{O}(N\log\_{}{N})\\) 。


### 小数组 {#小数组}

当然在数组大小很小的时候 (通常认为是 \\(N \leq 20\\))，quicksort 并不如 insertion sort。因此通常的解决方法是在小数组上不递归地使用 quicksort，而是改为 insertion sort 这种对小数组有效的排序。这种策略实际上可以节省大约 \\(15\\%\\) (相对自始至终使用
quicksort) 的运行时间。

一种好的 `截止范围` (CUTOFF) 是 \\(N = 10\\) ，当然 CUTOFF 在 `5` 至 `20` 之间都有可能产生类似的结果。这种做法也避免了一些有害的退化情形。


### 快速排序的分析 {#快速排序的分析}

在分析之前，给出该算法的相关代码。需要注意的是，在排序范围小于 10 时，会调用
shell sort 为范围进行排序。

```cpp
template <class Array>
void shell_sort(Array& arr, std::size_t l, std::size_t r) {
  for (const auto& gap : SHELL_SORT_GAPS) {
  std::size_t base{l + gap};
    for (std::size_t i = base; i <= r; ++i) {
      for (std::size_t j{i}; j >= base and arr[j - gap] > arr[j]; j -= gap) {
        std::swap(arr[j], arr[j - gap]);
      }
    }
  }
}
template <class Array, class Element = typename Array::value_type>
const Element& get_pivot(Array& arr, std::size_t l, std::size_t r) {
  std::size_t mid{(l + r) >> 1};
  if (arr[mid] < arr[l]) {
    std::swap(arr[l], arr[mid]);
  }
  if (arr[r] < arr[l]) {
    std::swap(arr[l], arr[r]);
  }
  if (arr[r] < arr[mid]) {
    std::swap(arr[r], arr[mid]);
  }
  std::swap(arr[mid], arr[r - 1]);
  return arr[r - 1];
}
template <class Array>
void quicksort(Array& arr, std::size_t l, std::size_t r) {
  if (r < l + 10) {
    return shell_sort(arr, l, r);
  }
  auto pivot{get_pivot(arr, l, r)};
  std::size_t i{l}, j{r - 1};
  while (true) {
    while (arr[++i] < pivot) {
      continue;
    }
    while (pivot < arr[--j]) {
      continue;
    }
    if (i < j) {
      std::swap(arr[i], arr[j]);
    } else {
      break;
    }
  }
  std::swap(arr[i], arr[r - 1]);
  quicksort(arr, l, i - 1);
  quicksort(arr, i + 1, r);
}
template <class Array>
void quicksort(Array& arr) {
  quicksort(arr, 0ll, arr.size() - 1ll);
}
```

对快排进行如同归并排序那样的分析。可以肯定的是 \\(T(0) = T(1) = 1\\) 和 \\(T(N) =
T(i) + T(N - i - 1) + cN\\) ，我们需要考虑三种情况：

最坏情形的分析
: 这种情况下，我们可以认为 pivot 始终是最小元素，那么可以认为 \\(T(N) =
        T(N - 1) + cN\\) ，通过递推关系我们可以得到 \\[T(N) = T(1) + c\sum\_{i=2}^{N}{i} =
        \mathcal{O}(N^{2}).\\]

最佳情形的分析
: 这种情况下，我们可以认为 pivot 始终位于中间，为了简化假设两个集合的大小恰好为原大小的一半。可以发现 \\(T(N) = 2T(N/2) + cN\\) ，与归并排序一样，最终我们可以得到 \\[T(N) = cN\log\_{}{N} + N = \mathcal{O}(N\log\_{}{N}).\\]


平均情形的分析
: 当然这是最难的部分，我们假设对于 \\(arr\_{1}\\) 每个大小都是等可能的，因此每个大小均有 \\(1 / N\\) 的概率。由此可知 \\(T(i)\\) 的平均值为 \\((1/N)
        \sum\_{j=0}^{N-1}{T(j)}\\) ，代入 \\(T(N) = T(i) + T(N - i - 1) + cN\\) 得到 \\[T(N) =
        \frac{2}{N}[\sum\_{j=0}^{N-1}{T(j)}]+cN.\\] 两边同时乘以 \\(N\\) 可以消去分母上的 \\(N\\)
    得到 \\[NT(N) = 2[\sum\_{j=0}^{N-1}{T(j)}]+cN.\\] 如果为 \\(T(N-1)\\) 也这样做则可以得到 \\[(N-1)T(N-1) = 2[\sum\_{j=0}^{N-2}{T(j)}]+c(N-1)^{2}.\\] 将上面两个式子相减可以消去其中的求和符号 \\[NT(N) - (N-1)T(N-1) = 2T(N-1) + 2cN - c.\\] 去除 \\(-c\\)
    并改写为 \\(T(N)\\) 与 \\(T(N-1)\\) 的关系式
    \\[\frac{T(N)}{N+1}=\frac{T(N-1)}{N}+\frac{2c}{N+1}.\\] 如此进行 telescoping
    求和即可得到 \\[\frac{T(N)}{N+1} = \mathcal{O}(\log\_{}{N}).\\] 即 \\(T(N) =
        \mathcal{O}(N\log\_{}{N})\\) 。


### 基于快速排序的选择问题 {#基于快速排序的选择问题}

选择问题 (selection problem) 可以使用 quicksort 来解决，之前介绍了使用 heapsort
的 \\(\mathcal{O}(N + k\log\_{}{N})\\) 选择算法，而查询中值的话这个算法达到了
\\(\mathcal{O}(N\log\_{}{N})\\) ，这个所用时间可以给数组排序。因此我们期望获得一个更好的时间界。

实际上这个新的方法，查找集合 \\(arr\\) 中第 \\(k\\) 个最小的算法几乎与 quicksort 基本相同，我们将这个算法称为 **快速选择** (quickselect)，令 \\(|arr\_{i}|\\) 为 \\(arr\_{i}\\) 中的元素个数，步骤如下：

1.  如果 \\(|arr| = 1\\) ，那么 \\(k = 1\\) 并将 \\(arr\\) 中的元素作为答案返回。如果正在使用小数组的截止方法且 \\(|arr| \leq CUTOFF\\) ，则将 \\(arr\\) 排序并返回第 \\(k\\) 个最小元
2.  选取一个 pivot \\(e \in arr\\)
3.  将集合 \\(arr-{e}\\) 分割成 \\(arr\_{1}\\) 与 \\(arr\_{2}\\) ，就像 quicksort 中那样
4.  如果 \\(k \leq |arr\_{1}|\\) ，那么第 \\(k\\) 个最小元必然在 \\(arr\_{1}\\) 中，这种情况下直接返回 \\(quickselect(arr\_{1}, k)\\) 。如果 \\(k = 1 + |arr\_{1}|\\) 那么 pivot 就是第 \\(k\\) 个最小元。否则我们进行一次递归并返回 \\(quickselect(arr\_{2}, k -
         1 - |arr\_{1}|)\\)

与 quicksort 相比 quickselect 只进行了一次递归调用而不是两次，最坏时间复杂度与
quicksort 相同，但平均时间复杂度是 \\(\mathcal{O}(N)\\) 。

```cpp
// get_pivot 与 shell_sort 两个函数与 quicksort 中相同
// quickselect 与 quicksort 极为相似
template <class Array>
void quickselect(const std::size_t& k, Array& arr, std::size_t l, std::size_t r) {
  if (l == r && k == 1) {
    return;
  }
  if (r < l + 10) {
    return shell_sort(arr, l, r);
  }
  auto pivot{get_pivot(arr, l, r)};
  std::size_t i{l}, j{r - 1};
  while (true) {
    while (arr[++i] < pivot) {
      continue;
    }
    while (pivot < arr[--j]) {
      continue;
    }
    if (i < j) {
      std::swap(arr[i], arr[j]);
    } else {
      break;
    }
  }
  std::swap(arr[i], arr[r - 1]);
  auto len_1{i - l};
  if (len_1 != k - 1) {
    k <= len_1 ? quickselect(k, arr, l, i - 1) : quickselect(k - len_1 - 1, arr, i + 1, r);
  }
}
template <class Array>
void quickselect(Array& arr, int k) {
  quickselect(k, arr, 0ll, arr.size() - 1ll);
}
```


## 间接排序 {#间接排序}

对于排序来说，其中会有大量的比较与交换，一个难于复制的大对象所带来的时间成本是无法忽略的。解决方法也很简单，利用一个指向元素的指针所组成的数组，排序这些指针，从而确定元素的位置，而不是实际上的复制操作。这种被称为 **中间置换** (in-situ
permutation) 算法，之前介绍的对链表的排序就是这种算法。

但是对于数组这种顺序存储的结构，我们需要生成一个指针数组，并对指针数组进行
in-situ permutation。这样即使最终排序好指针数组，也需要写回原始数组，一种简单的方法是开辟等长的数组，将其按照指针数组的顺序复制一份，再复制回原始数组。其代价是
\\(\mathcal{O}(N)\\) 的额外空间复杂度与 \\(\mathcal{O}(2N)\\) 的复制次数。

不过在优化之前，需要简单的理解一个问题。当我们需要交换 `a[2]` 与 `a[4]` 时，需要有一个临时变量存储 `a[2]` ，以防 `a[2]` 不能被正确交换。如果需要交换三个元素，那么我们可以使用一个临时变量与 `4` 次赋值操作完成这个流程。将其应用在 in-situ
permutation 上，初始位置的 `a[i]` 存储到 tmp 中，让后将 `p[i]` 所指向的元素赋值到 `a[i]` 中，以此重复直到循环结束，将 tmp 赋值到正确的位置。这样一个长度为 \\(L\\)
的循环只需要 \\(L+1\\) 次赋值，当然长度为 1 时不需要赋值。

那么对于给定 N 个元素的数组，令 \\(C\_{L}\\) 是长度为 \\(L\\) 的循环的次数，元素的赋值次数 \\(M\\) 如下 \\[M = N - C\_{1} + C\_{2} + C\_{3} + \cdots + C\_{N}.\\] 最好的情况是全是长度为 1 的循环，即每个元素都在正确的位置上，这样就不需要赋值。最坏情况是有 \\(N/2\\) 个长度为 2 的循环，此时需要 \\(3N / 2\\) 次赋值。


## 非比较排序 {#非比较排序}

在任何只使用比较的排序算法的最坏时间复杂度为 \\(\Omega(N\log\_{}{N})\\) ，但是我们可以在某些情况下以 \\(\mathcal{O}(N)\\) 时间进行排序。


### 桶排序 {#桶排序}

一个简单的例子是 **桶排序** (bucket sort)，其将元素分到有限个桶中，每个桶再进行分别排序。当要被排序的数组内的数值是均匀分配的时候，桶排序使用线性时间 \\(\Theta(n)\\) 。

桶排序的步骤如下：

1.  设置一个定量的数组当作空桶子
2.  访问序列并将元素一个一个放到对应的桶子去
3.  对每个不是空的桶子进行排序
4.  从不是空的桶子里把元素再放回原来的序列中


### 计数排序 {#计数排序}

计数排序 (counting sort) 将设置一个额外的数组，其中第 i 个元素是待排序数组中值等于 i 的元素的个数，然后根据额外数组来排序。算法的步骤如下：

1.  找出待排序的数组中最大和最小的元素
2.  统计数组中每个值为 i 的元素出现的次数，存入额外数组的第 i 项
3.  反向填充目标数组


### 基数排序 {#基数排序}

基数排序 (radix sort) 是将待排序元素按一定位进行分割，然后按每个数位进行比较。实现方式可以采用两种不同的策略，即 LSD (Least Significant Digital) 与 MSD (Most
Significant Digital)，LSD 采用从最右位开始排序，MSD 采用从最左位开始排序。

radix sort 不止可以对整数进行排序，还可以用于字符串或特定格式的浮点数，为了方便以整数为例，算法的步骤如下：

1.  将所有待比较数值统一为同样的数位长度，数位较短的数前面补零
2.  从最低位开始，将元素放入对应数位的桶中进行排序
3.  按照顺序从桶中取出元素，并重复步骤 2 直到元素最高位被排序
4.  最终序列为已排序序列

基数排序的时间复杂度是 \\(\mathcal{O}(kN)\\) ，其中 \\(N\\) 是排序元素个数， \\(k\\) 是数字位数。当然 \\(k > \log\_{}{N}\\) 时 radix sort 并不比比较排序更优秀。

