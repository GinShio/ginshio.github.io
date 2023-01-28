# 优化简介


## 优化背景 {#优化背景}

上世纪 80 年代早期优化在编译器开发中还是一个可选特性，一般在其他部分都完成后才会添加到编译器中。因此出现了​**调试编译器**​和​**优化编译器**​的区别，即前者强调编译速度，因此可执行代码与源码之间存在较强的对应关系；后者强调最小化或最大化可执行程序的某些属性。因此优化编译器会花费更多时间来编译，生成质量更好的代码，通常这个过程伴随着大量移动操作，使调试变得困难。

从 RISC 开始流行，运行时性能开始需要编译器的优化。分支指令的延迟槽、非阻塞内存操作、流水线使用的增多以及功能单元数目的增加等，这些特性使得处理器性能不仅收程序布局和结构方面的制约，还受到指令调度和资源分配等底层细节的限制。

优化编译器现在变得司空见惯 (反而 go 是异类)，进而使编译器改变成了前端、后端的架构，优化将前端与性能问题分割开来。优化假定后端会处理资源分配的问题，因而假定针对具有无限寄存器、内存和功能单元的理想机器进行优化。这也对编译器后端产生了更大压力。


### 示例：改进数组的地址计算 {#示例-改进数组的地址计算}

如果编译器前端对数组的引用 `m[i, j]`​ 生成的 IR 没有关于 m、i、j 的信息或不了解外围的上下文，编译器如果按照默认的行主序处理地址。生成的表达式类似

\\[m + (i - low\_{1}(m)) \times (high\_{2}(m) - low\_{2}(m) + 1) \times w + (j - low\_{2}(m)) \times
w.\\]

m 是数组的首地址，\\(low\_{i}(m)\\) 和 \\(high\_{i}(m)\\) 分别表示 m 的第 i 维的下界和上界，w 是 m 中一个元素的字节长度。如何降低该计算的代价，直接取决于对该数组变量极其上下文的分析。如果数组 m 是局部变量并各维度下界均从 1 开始，且上界已知，那么就可以将计算简化为
\\[m + (i - 1) \times high\_{2}(m) \times w + (j - 1) \times w.\\]

如果引用出现在循环内部，且循环中 i 从 1 变动到 I，那么编译器可以使用​**运算符强度折减** (OSR, Operator Strength Reduction) 将 \\((i - 1) \times high\_{2}(m) \times
w\\) 替换为 \\(i^{'}\_{x} = i^{'}\_{x - 1} + high\_{2}(m) \times w\\) (其中 \\(i^{'}\_{1} =
0\\))。同样地，如果 j 也是个循环的归纳变量 (IV, Induction Variable)，且 j 从 1 变动到 J，那么经过 OSR 后就有了 \\(j^{'}\_{y} = j^{'}\_{y - 1} + w\\) (其中
\\(j^{'}\_{1} = 0\\))。经过两次 OSR 后，只需要计算此式
\\[m + i^{'} + j^{'}.\\]


### 示例：改进循环嵌套 {#示例-改进循环嵌套}

LINPACK 是一个线性代数库的数值计算库，当然现在也是一个不错的性能测试库。其中的
dmxpy 是一个经典的能够说明上下文作用的例子。源码可以在[这里](https://github.com/llvm/llvm-test-suite/blob/main/SingleSource/Benchmarks/Linpack/linpack-pc.c#L1125)找到。

代码主要是 dmxpy 的主循环部分 (这个小括号，它是 lisp!)。

```c
/**
 * @prototype
 * void dmxpy(n1, y, n2, ldm, x, m)
 * REAL y[], x[], m[];
 * int n1, n2, ldm;
 *
 * @purpose
 * multiply matrix m times vector x and add the result to vector y.
 *
 * @parameters
 * n1   integer, number of elements in vector y, and number of rows in
 *      matrix m
 * y    double [n1], vector of length n1 to which is added
 *      the product m*x
 * n2   integer, number of elements in vector x, and number of columns
 *      in matrix m
 * ldm  integer, leading dimension of array m
 * x    double [n2], vector of length n2
 * m    double [ldm][n2], matrix of n1 rows and n2 columns
 *
 * @note
 * We would like to declare m[][ldm], but c does not allow it.  In this
 * function, references to m[i][j] are written m[ldm*i+j].
 */
/* main loop - groups of sixteen vectors */
jmin = (n2 % 16) + 16;
for (j = jmin - 1; j < n2; j = j + 16) {
    for (i = 0; i < n1; i++)
	y[i] = ((((((((((((((((y[i]) + x[j - 15] * m[ldm * (j - 15) + i]) +
			     x[j - 14] * m[ldm * (j - 14) + i]) +
			    x[j - 13] * m[ldm * (j - 13) + i]) +
			   x[j - 12] * m[ldm * (j - 12) + i]) +
			  x[j - 11] * m[ldm * (j - 11) + i]) +
			 x[j - 10] * m[ldm * (j - 10) + i]) +
			x[j - 9] * m[ldm * (j - 9) + i]) +
		       x[j - 8] * m[ldm * (j - 8) + i]) +
		      x[j - 7] * m[ldm * (j - 7) + i]) +
		     x[j - 6] * m[ldm * (j - 6) + i]) +
		    x[j - 5] * m[ldm * (j - 5) + i]) +
		   x[j - 4] * m[ldm * (j - 4) + i]) +
		  x[j - 3] * m[ldm * (j - 3) + i]) +
		 x[j - 2] * m[ldm * (j - 2) + i]) +
		x[j - 1] * m[ldm * (j - 1) + i]) +
	    x[j] * m[ldm * j + i];
}
```

作者为提高性能将外层的循环展开了 16 次，这消除了 15 次额外的加法与绝大多数 load
/ store 操作。为了应对其他情况，在主循环之上，还分别处理了 1、2、4、8 列的情况，保证最终待处理的列为 16 的倍数。

当然，可以将其简化为我们常写的样子。

```c
for (j = 0; j < n2; j++) {
    for (i = 0; i < n1; i++)
	y[i] = y[i] + x[j] * m[ldm * j + i];
}
```

理想情况下编译器可以将普通的循环变换为这种高效的版本，或某种适用于目标机的形式。但是，编译器不能保证有目标机所需的所有优化。进行手工循环展开可以为多种目标机提供良好的性能。但从编译器的角度看，循环展开有 16 个关于 m 的表达式、15 个关于 x 的表达式，以及一个关于 y 的表达式。如果编译器不能简化地址计算，将产生大量的整数计算。

由于循环中并不会改变 x 的值，因此可以将 x 的地址计算与 load 移出内循环。另外就是将 x 的基址保存在寄存器中，也能节省很大一部分开销。对引用 x 中的元素 \\(x[j -
k]\\)，地址计算就是 \\(x + (j - k) \* w\\)，进一步化简 \\(x + jw - kw\\)，也就是说循环展开后，每次 x 的基址为 \\(x + jw\\)，load 操作将有相同的基址和不同的偏移量。

虽然 m 的元素也不会被改变，但是每次内循环都会改变引用的元素，因此无法将 load 运算外提来削减 load 带来的开销。但是同理可以使用相同基址的方法减少计算的消耗。


### 对优化的考虑 {#对优化的考虑}

优化变换的核心就是两个问题 -- **安全性** 和 **可获利性**​。安全性就是保证变换将保持程序原有的语义，而可获利性就是保证变换是有利可图的。如果不能同时满足时，那么编译器就不应该采用该变换。

一般来说可供优化编译器利用的时机有几种不同的来源

-   **减少抽象开销**​，程序设计语言引入的数据结构和类型需要运行时支持，优化器可以通过分析和变换来减少这种开销。
-   **利用特性**​，通常编译器可以利用操作执行时所处上下文的相关信息，来特化该操作。
-   **将代码与系统资源匹配**

---


## 优化的范围 {#优化的范围}

优化可以在不同粒度或范围上运行。主要有四种范围：局部的、区域性的、全局的和整个程序。

-   **局部方法**

    局部方法作用于单个 BB，在不考虑异常的情况下，BB 有两个重要性质：语句是顺序执行的；如果任一语句执行，那么整个块必将执行。因此编译器可以在局部获得更有利于优化的信息。

-   **区域性方法**

    区域性方法的作用范围大于单个 BB，但小于一个完整的过程。编译器通常采用 **扩展基本程序块** (EBB, Extended Basic Block) 的 BB 集合来考察一个区域，从而得出一些有利于优化的信息。

    区域性方法将变换的范围限制到小于整个过程的区域上，使得编译器将工作重点集中在频繁执行的语句上。并且可以针对不同的区域采用不同的优化策略。

-   **全局方法** (过程内方法)

    局部最优解在全局范围下不一定是全局最优解，过程为编译器提供了一个自然的边界，封装和隔离了运行时环境，并且有些系统中过程也充当了编译的单位。通常过程内方法构建过程的表示 (如 CFG)，并分析该表示，在分析之后根据信息来完成具体的变换。借助过程内视图，可以发现一些局部方法和区域性方法都无发发现的优化时机。

-   **全程序方法** (过程间方法)

    通常过程间分析和优化作用于调用图，经典的例子是 <span class="underline">内联替换</span> (inline
    substitution) 和 <span class="underline">过程间常数传递</span> (interprocedural constant propagation)。

{{< admonition type="info" >}}
扩展基本程序块 (EBB, Extended Basic Block) 是一组基本程序块的最大集合：

-   只有第一个 BB 可以拥有多个前驱结点
-   集合中的其余结点只能拥有一个前驱结点
{{< /admonition >}}

如图，可以将这个 CFG 划分为 3 个 EBB：​\\(\\{B\_{0}, B\_{1}, B\_{2}, B\_{3}, B\_{4}\\}\\)、
\\(\\{B\_{5}\\}\\) 和 \\(\\{B\_{6}\\}\\)。

{{< figure src="/images/cfg-example.svg" >}}

---


## 局部优化 {#局部优化}

局部优化是编译器能够使用的最简单且非常有效的优化方法。常用的手法是

-   局部值编号 (local value numbering)，通过重用此前计算过的值来替换冗余的求值
-   树高平衡 (tree-height balancing)，用于重新组织表达式树，揭示更多指令层级的并行性


### 局部值编号 {#局部值编号}

就像之前提到的名字对编译器的影响，消除冗余计算的同时，也会扩展或缩短相关变量的生命周期。假定所有冗余消除是有利可图的，最古老且强大的方法就是局部值编号 (LVN,
Local Value Numbering)。

另外需要主要的是，LVN 旨在消除冗余计算，因此每次对相应值的使用都会对生命周期进行延长或缩短。如将 \\(d\leftarrow{}a-d\\) 替换为 \\(d\leftarrow{}b\\) 会增长 b 的生命周期，但会减少 a 或
d 的生命周期。


#### LVN 算法 {#lvn-算法}

算法遍历 BB，并为程序块计算的每个值分配一个不同的编号。算法会为值选择编号，使得给定两个表达式 \\(e\_{i}\\) 和 \\(e\_{j}\\)，当且仅当表达式的所有可能的运算对象，都可以验证 \\(e\_{i}\\) 和 \\(e\_{j}\\) 具有相等的值时，二者具有相同的值编号。

LVN 算法的输入是一个具有 n 个二元运算的基本程序块，每个运算形如 \\(T\_{i} \leftarrow{}
L\_{i}\ [Op\_{i}]\ [R\_{i}]\\)，算法按顺序考察每个运算。通常使用散列表将名字、常数和表达式映射到不同的值编号。为处理第 i 个运算，LVN 在散列表中查找 \\(L\_{i}\\) 和
\\(R\_{i}\\)，并获取二者对应的值编号。如果找到对应的表项就使用该值编号；否则，创建一个新的表项并分配一个新的值编号。

\\(L\_{i}\\) 和 \\(R\_{i}\\) 的值编号分别记作 \\(VN(L\_{i})\\) 和 \\(VN(R\_{i})\\)，LVN 基于表达式 \\(<VN(L\_{i}),\ Op\_{i},\ VN(R\_{i})>\\) 构造散列键，并查找该键。如果存在对应的表项则说明该表达式是冗余的；否则认为是第一次计算该表达式，算法为对应的表达式键创建对应的表项，并分配一个新的值编号。

<div class="verse">

for `expr` in BasicBlock do<br />
&nbsp;&nbsp;&nbsp;&nbsp;get the value number \\(VN(L\_{i})\\) and \\(VN(R\_{i})\\)<br />
&nbsp;&nbsp;&nbsp;&nbsp;construct a hash key `h` from `expr` (using \\(Op\_{i}\\), \\(VN(L\_{i})\\) and \\(VN(R\_{i})\\))<br />
&nbsp;&nbsp;&nbsp;&nbsp;if `h` is already present in the table then<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;replace operation value into \\(T\_{i}\\)<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;associate the value number with \\(T\_{i}\\)<br />
&nbsp;&nbsp;&nbsp;&nbsp;else<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;insert a new value number into table at the hash key location<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;record the new value for \\(T\_{i}\\)<br />
&nbsp;&nbsp;&nbsp;&nbsp;end<br />
end<br />

</div>


#### 扩展 LVN 算法 {#扩展-lvn-算法}

LVN 还可以进行其他几种局部优化

-   **交换运算**​，对于可交换的运算来说，如果仅运算操作数的顺序不同，它们将分配相同的值编号
-   **常量合并**​，如果一个运算的所有运算对象都是已知的常数项，那么 LVN 可以在编译时计算并将结果进行合并。
-   **代数恒等式**​，LVN 可以用代数恒等式来简化代码。如 \\(x+0\\) 和 \\(x\\) 应该分配相同的编号。

<div class="verse">

for `expr` in BasicBlock, do<br />
&nbsp;&nbsp;&nbsp;&nbsp;get the value number \\(VN(L\_{i})\\) and \\(VN(R\_{i})\\)<br />
&nbsp;&nbsp;&nbsp;&nbsp;if \\(L\_{i}\\) and \\(R\_{i}\\) are both constant then<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;evaluate \\(L\_{i}\\) and \\(R\_{i}\\)<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;assign the result to \\(T\_{i}\\)适当的特定邮寄气得方法进行编码<br />
&nbsp;&nbsp;&nbsp;&nbsp;if `h` is already present in the table, then<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;replace operation value into \\(T\_{i}\\)<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;associate the value number with \\(T\_{i}\\)<br />
&nbsp;&nbsp;&nbsp;&nbsp;else<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;insert a new value number into table at the hash key location<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;record the new value for \\(T\_{i}\\)<br />
&nbsp;&nbsp;&nbsp;&nbsp;end<br />
end<br />

</div>


### 树高平衡 {#树高平衡}

编译器对一个计算进行编码的具体细节会影响到编译器优化该计算的能力，许多现代处理器有多个功能单元，因而可以在每个周期中执行多个独立的操作。如果编译器可以通过对指令流的编排使之包含独立的多个操作，并适合于特定机器，那么应用程序会运行得更快。

如代码 `a + b + c + d + e + f + g + h`

```lisp
;; LLVM IR
%1 = add nsw i32 %a, %b
%2 = add nsw i32 %1, %c
%3 = add nsw i32 %2, %d
%4 = add nsw i32 %3, %e
%5 = add nsw i32 %4, %f
%6 = add nsw i32 %5, %g
%7 = add nsw i32 %6, %h
```

对于该代码，可以左递归求值生成一棵左结合树，亦或右递归语法建立右结合树。但是建立一棵平衡树可以减少递归求值的约束，比如左结合树中 \\(a+b\\) 必须在涉及 g  或 h 的加法之前执行。

{{< figure src="/images/tree-height-balance-example.svg" >}}

如果处理器每次可执行多个加法，左、右结合的树只能依次调度，而平衡树代码可以并行调度。这种优化利用了结合律和交换律，揭示表达式求值中的指令级并行，从而改进执行时间。

如果将树高平衡转换为算法，算法分为 **分析** 和 **转换** 两个步骤：

1.  识别程序块中的候选表达式树。候选表达式树的运算符必须是相同的，且必须是可交换的和可结合的。同样，候选表达式树内部结点的每个名字都必须刚好是用一次。
2.  对于每个候选树，算法将找到所有的运算对象，并将所有运算对象输入到一个优先队列，按等级递增的次序排列。


#### 寻找候选树 {#寻找候选树}

一个基本程序块由一个或多个混合计算组成，编译器可以将其中的 IR 解释成一个 DDG，该图记录了值的流动和对各个操作的执行顺序约束。

```lisp
;; LLVM IR
%t = mul nsw i32 %a, %b
%u = sub nsw i32 %c, %d
%v = add nsw i32 %t, %u
%w = mul nsw i32 %t, %u
```

一般地，DDG 不会形成一棵树，而是由多棵树交织组成。平衡算法所需的各种候选表达式树都是 DDG 中的不同子集。

{{< figure src="/images/tree-height-balance-ddg-and-trees.svg" >}}

在算法重排各个运算对象时，规模较大的候选树能够提供更多的重排机会。因此，算法试图构造最大规模的候选树。概念上算法找到每个候选树都可以看作是一个 n 元运算符 (n 尽可能大)。因此某些因素会限制候选树的规模

1.  树不可能大过它表示的程序块
2.  重写无法改变程序程序块的 `可观察量`​，即程序块以外使用的任何值都必须像原来的代码中那样计算，且保留其值。类似地，任何在程序块中使用多次的值都必须保留
3.  树反向扩展时不能超过程序块的起始位置

{{< admonition type="info" >}}
如果一个值在某个代码片段之外是可读取的，那么该值相对于该代码片段是可观察的。
{{< /admonition >}}

在查找树阶段，对程序中定义的名字 \\(T\_{i}\\) 都需要知道何处引用了 \\(T\_{i}\\)，因此算法包括一个 \\(Uses(T\_{i})\\) 的集合，即使用了 \\(T\_{i}\\) 的操作、指令的索引。

算法首先遍历程序块中的各个操作，判断每一个操作是否一定要将该操作作为其自身所属树的根结点。找到根节点时，会将该操作定义的名字添加到一个由名字组成的优先队列中，该队列按根结点运算符的优先级排序。假定操作 i 形如 \\(T\_{i}\leftarrow{}L\_{i}\\,Op\_{i}\\,R\_{i}\\)，且 \\(Op\_{i}\\) 是可交换和可结合的。那么下列条件之一成立时，将 \\(Op\_{i}\\) 标记的为根结点，并将其加入优先队列。

1.  如果 \\(T\_{i}\\) 使用多次，那么操作 i 必须被标记为根结点，以确保对所有使用
    \\(T\_{i}\\) 的操作，\\(T\_{i}\\) 都是可用的，对 \\(T\_{i}\\) 的多次使用使之成为一个可观察量。
2.  如果 \\(T\_{i}\\) 只在操作 j 中使用一次，但 \\(Op\_{i}\\,\ne\\,Op\_{j}\\)，那么操作 i
    必是根结点，因为它不可能是包含 \\(Op\_{j}\\) 的树的一部分。

<div class="verse">

roots = priority queue of names<br />
for i in range(0, n - 1), rank(\\(T\_{i}\\)) = -1 do<br />
&nbsp;&nbsp;&nbsp;&nbsp;if \\(Op\_{i}\\) is _commutative_ and _associative_ and<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;(\\(\lvert{Uses(T\_{i})}\rvert\\) &gt; 1 or (\\(\lvert{Uses(T\_{i})}\rvert\\) = 1 and \\(Op\_{Uses(T\_{i})} \ne Op\_{i}\\))) then<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;mark \\(T\_{i}\\) as a root<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Enqueue(roots, \\(T\_{i}\\), precedence of \\(Op\_{i}\\))<br />
&nbsp;&nbsp;&nbsp;&nbsp;end<br />
end<br />

</div>


#### 重构程序块使之平衡 {#重构程序块使之平衡}

接下来算法以候选树根结点的队列作为输入，并根据每个根结点建立一个大体的平衡树。这个阶段使用三个模块：Balance、Flatten、Rebuild。

<div class="verse">

while Roots is not empty do<br />
&nbsp;&nbsp;&nbsp;&nbsp;var = Dequeue(Roots)<br />
&nbsp;&nbsp;&nbsp;&nbsp;Balance(var)<br />
end<br />

</div>

Balance 对根结点进行操作，分配一个新的优先队列来容纳当前树的所有操作数，使用
Flatten 递归遍历树，为每个操作数指派等级并将其添加到队列中。

<div class="verse">

Balance(root)<br />
&nbsp;&nbsp;&nbsp;&nbsp;if Rank(root) &gt;= 0 then<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;return<br />
&nbsp;&nbsp;&nbsp;&nbsp;end<br />
<br />
&nbsp;&nbsp;&nbsp;&nbsp;q = new queue of names<br />
&nbsp;&nbsp;&nbsp;&nbsp;Rank(root) = Flatten(\\(L\_{i}\\), q) + Flatten(\\(R\_{i}\\), q)<br />
&nbsp;&nbsp;&nbsp;&nbsp;Rebuild(q, \\(Op\_{i}\\))<br />
end<br />
<br />
Flatten(var, q)<br />
&nbsp;&nbsp;&nbsp;&nbsp;if var is a constant then<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Rank(var) = 0<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Enqueue(q, var, Rank(var))<br />
&nbsp;&nbsp;&nbsp;&nbsp;else if var \\(\in\\) UEVar(b) then<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Rank(var) = 1<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Enqueue(q, var, Rank(var))<br />
&nbsp;&nbsp;&nbsp;&nbsp;else if var is a root then<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Balance(var)<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Enqueue(q, var, Rank(var))<br />
&nbsp;&nbsp;&nbsp;&nbsp;else<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Flatten(\\(L\_{j}\\), q)<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Flatten(\\(R\_{j}\\), q)<br />
&nbsp;&nbsp;&nbsp;&nbsp;end<br />
&nbsp;&nbsp;&nbsp;&nbsp;return Rank(var)<br />
end<br />

</div>

Rebuild 使用了一个简单的算法来构造新的代码序列，它重复从树中移除两个等级最低的项。该函数将输出一个操作来合并这两项。它会为结果分配一个等级，然后将结果插回到优先队列中，直到队列为空。

<div class="verse">

Rebuild(q, op)<br />
&nbsp;&nbsp;&nbsp;&nbsp;while q is not empty do<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;NL = Dequeue(q)<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;NR = Dequeue(q)<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;if NL and NR are both constants then<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;NT = Fold(op, NL, NR)<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;if q is empty then<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;# root = NT<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Rank(root) = 0<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;else<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Enqueue(q, NT, 0)<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Rank(NT) = 0<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;end<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;else<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;if q is empty then<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;NT = root<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;else<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;NT = new name<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;end<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;# NT = NL op NR<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Rank(NT) = Rank(NL) + Rank(NR)<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;if q is not empty then<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Enqueue(q, NT, Rank(NT))<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;end<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;end<br />
&nbsp;&nbsp;&nbsp;&nbsp;end<br />
end<br />

</div>

在该算法中，有些细节：

1.  在遍历候选树时，Flatten 可能会遇到另一棵树的根结点。它会递归调用 Balance 而非 Flatten，一边为候选子树的根结点创建一个新的优先队列，并确保编译器在输出引用子树值的代码之前，先对优先级较高的子树输出代码。
2.  程序块由三种引用：常数、本程序块中先定义后使用的名字、向上展现的名字。
    Flatten 例程分别处理每种情形。
3.  算法设计常数等级为零，因此常数可以移动到队列前端，用 Fold 进行编译期对常数进行计算，并到新的名字加入到树中。叶结点的等级为 1，内部结点的等级等于其所在子树所有结点等级之和。这种指派等级的方法将生成一种近似于平衡二叉树的树状结构。


#### 树高平衡算法的例子 {#树高平衡算法的例子}

回到表达式 \\(a + b + c + d + e + f + g + h\\)，重新看看 IR

```lisp
;; LLVM IR
%1 = add nsw i32 %a, %b
%2 = add nsw i32 %1, %c
%3 = add nsw i32 %2, %d
%4 = add nsw i32 %3, %e
%5 = add nsw i32 %4, %f
%6 = add nsw i32 %5, %g
%7 = add nsw i32 %6, %h
```

假设只有 `%7` 在程序块之外使用，那么只有 `Uses(%7) > 1`​，因此只有 `%7` 被作为候选树的根。平衡时扁平化树将会得到以下队列
\\[<h, 1>, <g, 1>, <f, 1>, <e, 1>, <d, 1>, <c, 1>, <b, 1>, <a, 1>.\\]

Rebuild 会从队列中取出 \\(<h, 1>\\) 和 \\(<g, 1>\\) 然后将 \\(<n\_{0}, 2>\\) 加入队列。
\\[<f, 1>, <e, 1>, <d, 1>, <c, 1>, <b, 1>, <a, 1>, <n\_{0}, 2>.\\]

Rebuild 构建四次后，队列将成为以下
\\[<n\_{0}, 2>, <n\_{1}, 2>, <n\_{3}, 2>, <n\_{4}, 2>.\\]

接下来一直构建，直到队列为空。最终可以生成一个树平衡的 IR。

```lisp
;; LLVM IR
%1 = add nsw i32 %a, %b
%2 = add nsw i32 %c, %d
%3 = add nsw i32 %e, %f
%4 = add nsw i32 %g, %h
%5 = add nsw i32 %1, %2
%6 = add nsw i32 %3, %4
%7 = add nsw i32 %5, %6
```

现在看另一个例子，表达式即
\\[\begin{aligned}
t1 &= 13 + a + b + 4\\\\
t2 &= t1 \* c \* 3 \* d\\\\
t3 &= e + f + g + h\\\\
t4 &= t1 \* (e + f)\\\\
t5 &= t1 + t3
\end{aligned}\\]

转化为 IR

```lisp
;; LLVM IR
 %1 = add nsw i32 %a, 13
 %2 = add nsw i32 %1, %b
 %3 = add nsw i32 %2, 4
 %4 = mul nsw i32 %3, %c
 %5 = mul nsw i32 %4, 3
 %6 = mul nsw i32 %5, %d
 %7 = add nsw i32 %e, %f
 %8 = add nsw i32 %7, %g
 %9 = add nsw i32 %8, %h
%10 = mul nsw i32 %3, %7
%11 = add nsw i32 %3, %9
```

依然第一步寻找候选树的根。算法会选出 5 个根：​`%3`​、​`%6`​、​`%7`​、​`%10` 以及 `%11`

{{< figure src="/images/tree-height-balance-second-example.svg" >}}

开始从根结点平衡候选树。需要注意的是，在平衡 `%11` 的候选树时，其中 `%3` 和 `%7` 是各自候选树的根，因此会对它们调用 Balance 分别平衡。\\(Balance(\\%3)\\) 所构造的队列
\\[<4, 0>, <13, 0>, <b, 1>, <a, 1>.\\]

因此可以根据 Rebuild 可以构造出 `%3` 的 IR 类似

```lisp
;; LLVM IR
 %1 = add nsw i32 %b, 17
%t3 = add nsw i32 %1, %a
```

最终可以得到平衡后的树

{{< figure src="/images/tree-height-balance-second-balanced-example.svg" >}}

```lisp
;; LLVM IR
  %1 = add nsw i32 %b, 17
 %t3 = add nsw i32 %1, %a
 %t7 = add nsw i32 %e, %f
  %2 = add nsw i32 %h, %g
  %3 = add nsw i32 %2, %t7
%t11 = add nsw i32 %3, %t3
%t10 = mul nsw i32 %t7, %t3
  %4 = mul nsw i32 %c, 3
  %5 = mul nsw i32 %4, %d
 %t6 = mul nsw i32 %5, %t3
```

---


## 区域优化 {#区域优化}

低效性不止出现在单个 BB 中，一个 BB 可能为改进另一个 BB 提供上下文环境。因此大多数优化也会考察多个 BB 的上下文，这也就是区域优化。


### 超局部值编号 {#超局部值编号}

命名一直是编译器中的一个重点项目，LVN 是在单个 BB 内的命名方法，超局部值编号
(SVN, Superlocal Value Numbering) 则是扩展到 EBB 中进行命名的方法。

回到[优化的范围](#优化的范围)所提到的 EBB 示例，先聚焦到第一个 EBB ​\\(\\{B\_{0}, B\_{1}, B\_{2},
B\_{3}, B\_{4}\\}\\) 上，SVN 可以将 3 条路径中的每一条路径都当作一个单个 BB 进行处理，也就是说，在处理时 \\(\\{B\_{0}, B\_{1}\\}\\)、\\(\\{B\_{0}, B\_{2}, B\_{3}\\}\\) 和
\\(\\{B\_{0}, B\_{2}, B\_{4}\\}\\) 都被当作线性代码。比如在处理 \\(\\{B\_{0}, B\_{1}\\}\\) 时，编译器先将 LVN 算法应用到 \\(B\_{0}\\) 上，然后将生成的散列表按 BB 顺序用 LVN 算法应用到 \\(B\_{1}\\) 上。

{{< admonition type="warning" >}}
因此考虑，为何 EBB 只允许第一个 BB 可以有多个前驱，而其他 BB 只允许有一个前驱。
{{< /admonition >}}

SVN 可以发现 LVN 可能错过的冗余和常量表达式。但对于分支上的 BB 来说，SVN 算法可能会将一个 BB 分析多次，例如 EBB \\(\\{B\_{0}, B\_{1}, B\_{2}, B\_{3}, B\_{4}\\}\\) 的 3
个分支，会将 \\(B\_{0}\\) 分析 3 次，将 \\(B\_{2}\\) 分析 2 次。

为了 SVN 的高效运行，算法必须有一种重用分析结果的方法，比如处理分支 \\(\\{B\_{0},
B\_{2}, B\_{4}\\}\\) 时，需要重用 \\(\\{B\_{0}, B\_{2}\\}\\) 结束时的状态来处理 \\(B\_{4}\\)。而在重用之前，必须撤销 \\(\\{B\_{0}, B\_{2}, B\_{3}\\}\\) 所带来的影响。为了高效的撤销，使用作用域化散列表可以有效解决这个问题。在处理每个 BB 时为其分配一个值表，将其连接到前驱程序块的值表 (将前驱块的值表当作外层作用域)，并用这个新的值表与程序块 b
作为参数使用 LVN 算法。

<div class="verse">

WorkList = { entry block }<br />
Empty = new table<br />
<br />
while WorkList is not empty do<br />
&nbsp;&nbsp;&nbsp;&nbsp;remove b from WorkList<br />
&nbsp;&nbsp;&nbsp;&nbsp;SVN(b, Empty)<br />
end<br />
<br />
SVN(BB, Table)<br />
&nbsp;&nbsp;&nbsp;&nbsp;t = new table for BB<br />
&nbsp;&nbsp;&nbsp;&nbsp;link Table as the surrounding scope for t<br />
&nbsp;&nbsp;&nbsp;&nbsp;LVN(BB, t)<br />
&nbsp;&nbsp;&nbsp;&nbsp;for each successor s of BB do<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;if s has only 1 predecessor then<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;SVN(s, t)<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;else if s has not been processed then<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;add s to WorkList<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;end<br />
&nbsp;&nbsp;&nbsp;&nbsp;end<br />
end<br />

</div>

还有一个问题，就是名字的值编号是由 EBB 中定义该名字的第一个操作相关联的值表记录的，那么在[优化的范围](#优化的范围)示例中的 CFG，如果 \\(B\_{0}\\)、\\(B\_{3}\\) 和 \\(B\_{4}\\) 中都定义了名字 x，那么其值编号将记录在 \\(B\_{0}\\) 中的作用域化值表中。在处理 \\(B\_{3}\\)
时，会将它的 x 的新的值编号记录到对应于 \\(B\_{0}\\) 的表中，删除对应于 \\(B\_{3}\\)
的表并开始处理 \\(B\_{4}\\) 时，由 \\(B\_{3}\\) 定义的值编号依然保留在 \\(B\_{0}\\) 的表中。为了避免这种复杂的情况，编译器可以使用只定义每个名字一次的表示法，也就是 SSA
所具有的性质。使用 SSA 时可以撤销一个程序块值表的所有影响，恢复到前驱程序块退出时的状态，并且 SSA 还可以使 LVN 更加高效。

需要注意的是，SVN 虽然可以发现 EBB 中的冗余，但也有局限，例如当一个 BB 有多个前驱时，SVN 无法将上下文信息传入其中。


### 循环展开 {#循环展开}

循环展开时最古老、最著名的循环变换，展开一个循环，复制循环体并调整迭代执行数目的逻辑。

```lua
for j = 1, n2, 1 do
    for i = 1, n1, 1 do
	y[i] = y[i] + x[j] * m[i][j]
    end
end
```

编译器可以展开内层循环或外层循环，例如展开内层循环会复制循环体，而展开外层循环时会复制多次内层循环。如果编译器之后合并这些内层循环 (循环融合，loop fusion)，先展开外层循环再融合内层循环的变换组合被称为 **展开-轧挤** (unroll-and-jam)。

循环展开对编译器为给定循环生成的代码有着直接或间接的影响。展开循环可以减少完成循环所需操作的数目，控制流的改变减少了判断和分支代码序列的总数。展开还可以在循环体内部产生重用，减少内存访问。最后，如果循环包含一个复制操作的有环链，那么展开可以消除这些复制。但展开会增大程序的长度，这样可能会增加编译时间，但展开的循环体内部可能影响 Cache，从而导致性能降低。

循环展开的关键副效应时增加了循环内部的操作数目，一些优化可以利用这些

-   增加循环体中独立操作的数目，可以生成更好的指令调度。在操作更多的情况下，指令调度器有更高的几率使多个功能单元保持忙碌，并隐藏长耗时操作 (如分支和访存) 的延迟。
-   循环展开可以将连续的内存访问移动到同一迭代中，编译器可以调度这些操作一同执行。这可以提高内存访问的局部性，或利用多字操作进行内存访问。
-   展开可以暴露跨迭代的冗余，而这在原来的代码中可能是难以发现的。展开循环后 LVN
    算法可以找到这些冗余并消除。
-   与原来的循环相比，展开后的循环能以不同的方式进行优化。如增加一个变量在循环内部出现的次数，可以改变寄存器分配器内部逐出代码选择中使用的权重。改变寄存器逐出的模式，可能在根本上影响到为循环生成的最终代码的速度。
-   与原来的循环体相比，展开后的循环体可能会对寄存器有更大的需求。如果对寄存器增加的需求会导致额外的寄存器逐出 (存储到内存和从内存重新加载)，那么由此导致的内存访问代价可能会超出循环展开带来的收益。

---


## 全局优化 {#全局优化}

全局优化处理整个过程或方法，其作用域包括有环的控制流结构 (如循环)，全局优化在修改代码前通常会有一个分析阶段。


### 利用活动信息查找未初始化变量 {#利用活动信息查找未初始化变量}

如果过程 p 在为某个变量 v 分配一个值之前能够使用 v 的值，那么就说 v 在这次使用时是为初始化的。通过计算​**活动情况**​的信息，可以找到对未初始化变量的潜在使用。当且仅当
CFG 中存在一条从 p 到使用 v 的某个位置之间的路径，且 v 在该路径中没有被重新定义，变量 v 在位置 p 处是活动的。通过计算将过程中的每个 BB 对应的活动信息编码到集合
`LiveOut(bb)` 中，该集合包含在 BB 退出时的所有活动的变量。

给定 CFG 入口结点 \\(n\_{0}\\) 的 LiveOut 集合，\\(LiveOut(n\_{0})\\) 中的每个变量都有一次潜在的未初始化使用。


#### 定义数据流问题 {#定义数据流问题}

为了计算 CFG 中结点 n 的 LiveOut，需要使用其后继结点的 LiveOut，以及另外两个集合
`UEVar` 和 `VarKill`​。定义 LiveOut 的方程如下：
\\[LiveOut(n) = \cup\_{m\in{}succ(n)} \left( UEVar(m) \cup \left( LiveOut(m) \cap
\overline{VarKill(m)} \right) \right).\\]

`UEVar(m)` 包含了 m 中向上展现的变量，即那些在 m 中重新定义之前就开始使用的变量。​`VarKill(m)` 包含了 m 中定义的所有变量，\\(\overline{VarKill(m)}\\) 则是其补集，即未在 m 中定义的变量的集合。由于 `LiveOut(n)` 是利用 n 的后继结点来定义的，因此该方程描述了一个​**反向数据流问题**​。


#### 解决这个数据流问题 {#解决这个数据流问题}

对一个过程及其 CFG 计算各个结点的 LiveOut 集合，编译器可以使用一个三步算法

1.  **构建 CFG**​，这个步骤在概念上很简单
2.  **收集初始信息**​，分析程序在一趟简单的遍历中分别为每个程序块 b 计算一个 `UEVar`
    和 `VarKill` 集合

    为了计算 LiveOut 集合，分析程序需要每个程序块的 UEVar 和 VarKill 集合。一趟处理即可计算出这两个集合。对于每个程序块，分析程序将两个集合都初始化为
    \\(\emptyset\\)。接下来按从上到下顺序遍历，并适当地更新 UEVar 和 VarKill 集合，以反映程序块的每个操作的影响。

    <div class="verse">

    // x = y op z<br />
    for each block b do<br />
    &nbsp;&nbsp;&nbsp;&nbsp;Init(b)<br />
    end<br />
    <br />
    Init(b)<br />
    &nbsp;&nbsp;&nbsp;&nbsp;UEVar(b) = \\(\emptyset\\)<br />
    &nbsp;&nbsp;&nbsp;&nbsp;VarKill(b) = \\(\emptyset\\)<br />
    &nbsp;&nbsp;&nbsp;&nbsp;for i in range(1, k) do<br />
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;if y \\(\notin\\) VarKill(b) then<br />
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;add y to UEVar(b)<br />
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;end<br />
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;if z \\(\notin\\) VarKill(b) then<br />
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;add z to UEVar(b)<br />
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;end<br />
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;add x to VarKill(b)<br />
    &nbsp;&nbsp;&nbsp;&nbsp;end<br />
    end<br />

    </div>

3.  **求解方程式，为每个程序块生成 LiveOut 集合**

    求解过程需要反复进行，直到所有 LiveOut 集合不再改变为止

    <div class="verse">

    for i in range(0, N - 1), LiveOut(i) = \\(\emptyset\\) do<br />
    &nbsp;&nbsp;&nbsp;&nbsp;changed = true<br />
    &nbsp;&nbsp;&nbsp;&nbsp;while changed do<br />
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;changed = false<br />
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;for i in range(0, N - 1) do<br />
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;recompute LiveOut(i)<br />
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;if LiveOut(i) changed then<br />
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;changed = true<br />
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;end<br />
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;end<br />
    &nbsp;&nbsp;&nbsp;&nbsp;end<br />
    end<br />

    </div>

比如对于一个控制流图

```lisp
;; IR
b0:
  %i = i32 1

b1:
  br i32 %i, label %b3, label %b2

b2:
  %s = i32 0

b3:
  %s = add nsw i32 %s, %i
  %i = add nsw i32 %i, 1
  br i32 %i, label %b1, label %b4

b4:
  print i32 %s
```

根据控制流信息可以轻松计算出 VarKill 和 UEVar

|    | UEVar           | VarKill         |
|----|-----------------|-----------------|
| b0 | \\(\emptyset\\) | {i}             |
| b1 | {i}             | \\(\emptyset\\) |
| b2 | \\(\emptyset\\) | {s}             |
| b3 | {s, i}          | {s, i}          |
| b4 | {s}             | \\(\emptyset\\) |

在这个例子中，开始计算每个程序块的 LiveOut。

| 迭代次数 | LiveOut(b0)     | LiveOut(b1)     | LiveOut(b2)     | LiveOut(b3)     | LiveOut(b4)     |
|------|-----------------|-----------------|-----------------|-----------------|-----------------|
| 初始 | \\(\emptyset\\) | \\(\emptyset\\) | \\(\emptyset\\) | \\(\emptyset\\) | \\(\emptyset\\) |
| 1    | {i}             | {s, i}          | {s, i}          | {s, i}          | \\(\emptyset\\) |
| 2    | {s, i}          | {s, i}          | {s, i}          | {s, i}          | \\(\emptyset\\) |
| 3    | {s, i}          | {s, i}          | {s, i}          | {s, i}          | \\(\emptyset\\) |


#### 查找未初始化的变量 {#查找未初始化的变量}

计算出 CFG 的每个结点的 LiveOut 集合后，查找未初始化变量的使用就变得简单了。如果有一个变量 v，且 \\(v \in LiveOut(n\_{0})\\)，\\(n\_{0}\\) 为 CFG 的入口结点，那么一定存在一条从 \\(n\_{0}\\) 到 v 的某个使用之处的路径，v 在该路径上未被定义。因此编译器可以识别处其中未被初始化的变量。但也有几种可能导致编译器错误的识别。

-   v 通过另一个名字初始化
-   v 在当前过程被调用之前就已存在
-   v 在路径上没有被初始化，但实际上该路径总是不会出现

如果过程包含对另一过程的调用，且 v 通过允许修改的方式传递给后者，那么分析程序必须考虑调用可能带来的副效应。在缺少被调用者的具体信息时，就需要假定其总是被修改。


#### 对活动变量的其他使用 {#对活动变量的其他使用}

除了查找未初始化变量外，编译器还可以在许多上下文中使用活动变量

-   全局寄存器分配中，活动变量会发挥关键作用，除非值是活动的，否则寄存器分配器不必将其保持在寄存器中；当值从活动转变为不活动时，分配器可以因其他用途重用该寄存器。
-   活动变量可以用于改进 SSA 构建：对一个值来说，它不活动的任何程序块中都不需要
    \\(\phi\\) 函数。用活动变量信息可以显著减少编译器构建程序 SSA 时必须插入 \\(\phi\\) 函数的数目。
-   编译器可以使用活动变量信息发现无用的 store 操作。如果一个操作将 v 存在内从中，如果 v 是不活动的，那么该 store 操作是无用的。


### 全局代码置放 {#全局代码置放}

很多处理器对分支处理的代价是不对称的：落空分支 (fall-through branch) 的代价要小于采纳分支 (taken branch)。比如一个条件跳转语句，其真条件分支执行频率比假条件分支高得多，那将真条件分支设置为落空分支性能更高。

为了全局代码置放优化，编译器应该将可能性最高的执行路径置放在落空分支上。其次编译器应该将执行得较不频繁的代码移动到过程末尾。这样可以尽可能生成更长的代码序列。

1.  获取路径剖析数据

    对于全局代码置放优化，编译器需要预估 CFG 中各条边的相对执行频度。从代码的剖析运行 (profiling run) 获取所需的信息。简单地说，就是统计 CFG 中各条边的执行次数，从而获得剖析数据。

2.  以链的形式在 CFG 中构建热路径

    编译器为判断如何设置代码布局而构建一个执行最频繁的边的集合，即热路径 (hot
    path)。编译器可以使用贪心算法查找热路径。

    首先为每个程序块创建一条退化的链，其中只包含块本身。接下来遍历 CFG 的各个边，按执行频度的顺序采用各边，使得最频繁的边优先。对于边 \\(<x, y>\\)，只有当 x 是所在链的最后一个结点，而 y 是所在链的第一个结点时，才会合并这两条链。

    <div class="verse">

    E = edges<br />
    for each block b do<br />
    &nbsp;&nbsp;&nbsp;&nbsp;make a degenerate chain, d, for b<br />
    &nbsp;&nbsp;&nbsp;&nbsp;priority(d) = E<br />
    end<br />
    p = 0<br />
    for each CFG edge &lt;x, y&gt;, x != y, in decreasing frequency order do<br />
    &nbsp;&nbsp;&nbsp;&nbsp;if x is the tail of chain a and y is the head of chain b then<br />
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;t = priority(a)<br />
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;append b onto a<br />
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;priority(a) = min(t, priority(b), p++)<br />
    &nbsp;&nbsp;&nbsp;&nbsp;end<br />
    end<br />

    </div>

3.  进行代码布局

    为生成最终的汇编代码，编译器必须将所有 BB 按一个固定的线性顺序置放。可以根据链集合计算出一个线性布局：

    1.  一个链内部的各 BB 按顺序置放，使链中的边能够通过落空分支实现
    2.  在多个链之间，根据链的优先级选择

    <div class="verse">

    t = chain headed by the CFG entry node<br />
    WorkList = {(t, priority(t))}<br />
    while WorkList != \\(\emptyset\\) do<br />
    &nbsp;&nbsp;&nbsp;&nbsp;remove a chain c of lowest priority from WorkList<br />
    &nbsp;&nbsp;&nbsp;&nbsp;for each block x in c in chain order do<br />
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;place x at the end of the executable code<br />
    &nbsp;&nbsp;&nbsp;&nbsp;end<br />
    &nbsp;&nbsp;&nbsp;&nbsp;for each block x in c do<br />
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;for each edge &lt;x, y&gt; where y is unplaced do<br />
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;t = chain containing &lt;x, y&gt;<br />
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;if (t, priority(t)) \\(\notin\\) WorkList then<br />
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;WorkList = WorkList \\(\cup\\) { (t, priority(t)) }<br />
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;end<br />
    &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;end<br />
    &nbsp;&nbsp;&nbsp;&nbsp;end<br />
    end<br />

    </div>

---


## 过程间优化 {#过程间优化}

将一个程序划分为多个过程，可以有效抽象出基础功能的代码，得以复用和抽象功能。但是从负面来看，程序划分限制了编译器理解调用过程内部行为的能力，比如编译器不能假定一个引用传递不会产生副作用。而另一点，过程调用需要转存当前上下文，这是代价巨大的。


### 内联替换 {#内联替换}

那编译器可以通过将被调用过程的副本替换到调用位置上，并根据调用位置的上下文调整代码，这种变换称为内联替换 (inline subsitution)。

在每个调用位置上，编译器必须决定是否内联该调用。一个调用位置上所做的决策可能会影响到其他调用位置上的决策。如 a 调用 b、b 调用 c 的过程，如果内联过程 c，可能会改变内联到 a 中的特征。因此在内联替换时需要一些准则来考察。

-   **被调用者的规模**​，如果被调用者的代码长度小于进行上下文保存、恢复的长度，那么内联替换可以减少代码长度
-   **调用者的规模**​，如果希望生成的代码足够的小
-   **动态调用计数**​，对频繁调用位置上的改进可以提供更大的收益
-   **常数值实参**​，调用时使用常数值实参，可能产生潜在的代码改进
-   **静态调用计数**​，编译器跟踪一个过程在不同位置的调用次数
-   **参数计数**​，参数的数目可以充当过程链接代价的一种表示
-   **过程中的调用**​，检查调用图的叶结点，通常这是良好的候选内联对象

编译器会根据一些准则，然后应用一条或一组相应的启发式规则，来决定一个调用是否被内联替换。


### 过程置放 {#过程置放}

与[全局代码置放](#全局代码置放)类似，根据调用图试图将有调用关系的过程尽可能置放在相邻的位置。


### 针对过程间优化的编译器组织结构 {#针对过程间优化的编译器组织结构}

对于传统编译器来说，编译单元可能是单个过程、单个类或单个代码文件，编译器生成的目标代码完全取决于编译单元的内容。到达编译单元边界时，编译器无法链接另一个编译单元中的行为，通常只能使用最坏的结果进行假设优化。

人们提出了针对过程间优化的不同编译器组织结构：

-   **扩大编译单元**​，这是最简单的一种解决方法
-   **链接时优化**​ (Link-Time Optimization)，直接地将过程间优化移动到链接器中，其中可以访问所有的静态链接代码。
