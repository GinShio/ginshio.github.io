# 中间表示


编译器通常组织为一连串的处理 pass，在每两个 pass 之间需要将已知的所有信息进行传递，因此编译器需要**中间表示** (IR, Intermediate Representation) 表达信息。IR 在编译器中可能是唯一的，也可能有多种。在转换期间，编译器不会回头查看源代码，而是只观察
IR，因此 IR 的性质对编译器对代码的处理由决定性影响。

除了词法分析器，大多数 pass 的输入都是 IR；除了代码生成器，大多数 pass 的输出都是 IR。大多数源代码并不足以支持编译器必须的信息，比如变量与常量的地址，或参数使用的寄存器等，为了记录所有信息，大多数编译器还会添加表和集合来记录额外信息，通常认为这也是 IR 的一部分。

IR 的实现会迫使编译器的开发人员专注于实际问题，用廉价的方式来执行需要频繁进行的操作，并且简洁的表示编译器间可能出现的所有结构。除了这些，还需要可读的 IR 表示。当然，对于使用 IR 的编译器来说，总会在 IR 上进行多次处理，一个 pass 处理中收集信息，另一个 pass 处理中优化代码。


## IR 的分类 {#ir-的分类}

编译器使用过许多种 IR，主要是三个方面：**结构性的组织**、**抽象层次**和**命名方案**。一般来说，这三个属性是独立的。对于 IR 从结构上可以分为：

图 IR
: 将编译器信息编码在图中。算法通过途中的对象来表述：结点、边、列表、树。

线性 IR
: 类似某些抽象机上的伪代码，相应算法将迭代遍历简单的线性操作序列。

混合 IR
: 混合前两种以获取优势，比如现代编译器中常见的 BasicBlock (BB) 内线性表示，而使用控制流图来表示 bb 之间的关系。

IR 的结构性组织对编译器的分析、优化、代码生成等有极大影响，比如树形 IR 得出的处理 pass 在结构上很自然的设计为某种形式的树遍历，而线性 IR 得出的处理 pass 一般顺序迭代遍历各个操作。

IR 所处的抽象层次，如果接近源代码，可能只需要一个结点就可以表示数组访问或过程调用，而较底层的表示中，可能需要合并几个 IR 操作。

```glsl
uint[100][100] arr;
arr[50][50] = 32;
```

```elisp
;; Spir-V
%_var_arr = OpVariable %_ptr_arr_100_100 Function
    %elem = OpAccessChain %_ptr_int %_var_arr %uint_50 %uint_50
            OpStore %elem %uint_32
```

```elisp
;; LLVM IR
%1 = alloca [100 x [100 x i32]], align 4
%2 = getelementptr inbounds [100 x [100 x i32]], [100 x [100 x i32]]* %1, i64 0, i64 50
%3 = getelementptr inbounds [100 x i32], [100 x i32]* %2, i64 0, i64 50
store i32 32, i32* %3, align 4
```

很明显，上面这三个不同层次的代码，对于简单的构造数组，并进行访问元素赋值，它们是不一样的。低层次的 IR 可以展现出更多源代码中所隐藏的细节，从而为编译器优化提供更多可能。

在 IR 分类中的第三个方向即命名方案，比如表达式 \\(a-2\*b\\)，编译器可以产生如下 IR

```elisp
;; LLVM IR
%b = load i32, i32* %bstack, align 4
; _1 = 2 * b
%1 = mul nsw i32 2, %b
%a = load i32, i32* %astack, align 4
; _2 = a - _1
%2 = sub nsw i32 %a, %1
```

加载进寄存器、进行运算，一共分配了 4 个名字。如果将 `%1` 和 `%2` 这两个名字都替换为
`%b`，那么分配的名字数目将会缩减一半。因此名字的分配对编译器有很大影响。比如子表达式 \\(2 - b\\) 拥有唯一的名字，如果之后编译器发现有冗余的该表达式求值，并且期间并没有产生对变量 b 的副作用，可以直接用此处产生的值替换，而不用再次计算。另外，命名方案的选择还会影响到编译时的数据结构大小以及编译所用的时间。


## 图 IR {#图-ir}

虽然很多编译器使用图 IR 作为中间表示，但是其中的抽象层次、图的结构等方面可能有巨大不同。


### 与语法相关的树 {#与语法相关的树}

语法分析树是一种树形 IR，表示程序中的源代码形式的图。大多数的树形 IR，其结构对应于源代码的语法。


#### 语法分析树 {#语法分析树}

相较于源代码，语法分析树更为庞大，其表示了完整的语法推导过程，树中的每个结点都表示推导过程中的语法符号。编译器必须为每个结点和边分配内存，并在编译器间遍历所有结点与边。

为了缩减语法分析树的规模，对语法分析树做以变换，消除推导过程中的一部分步骤和对应的语法结点，这种变换产生了抽象语法树。


#### 抽象语法树 {#抽象语法树}

**抽象语法树** (AST, Abstract Syntax Tree) 保留了语法分析树的基本结构，单剔除了非必要结点。源代码到源代码的转换系统 (语法制导编辑器和自动并行化工具) 通常使用 AST，而 Lisp 系中的 S-expression (symbolic expression) 本质上也是 AST。

```scheme
(define factorial
  (if (= x 0)
      1
      (* x (factorial (- x 1)))))
```

AST 的表示选择也会影响编译器的行为，比如一个复数常数，实部和虚部分别为树形结构的子结点，这种结构的 AST 适用于语法制导编辑器，可以方便的分别修改实部与虚部的值。由于其他常数都是单结点的，而这种结构的常数需要编译器在处理常数添加额外的代码。如果将复数常数设计为单结点的，那么编译器在编辑或加载到寄存器时操作会变得复杂，但可以简化其他操作。


#### 有向非循环图 {#有向非循环图}

虽然 AST 相比语法分析树已经很简洁了，但它依然保留了所有源代码的结构，即使表达式中存在完全相同的两个子树。**有向非循环图** (DAG, Directed Acyclic Graph) 是 AST 避免这种复制的简化。相同的子树可以被重复利用，也就意味着结点可以有多个父结点。

DAG 可以显示展示出冗余的表达式，减少冗余的求值，降低求值过程中的代价。但明显，编译器必须证明两个相同的表达式之间没有副作用产生，副作用产生时 DAG 需要重新计算子树。

编译器使用 DAG 主要基于两点原因，能够减少内存占用，其次能够暴露出冗余之处，从而优化代码。通常在优化时，DAG 作为衍生的 IR 使用，建立 DAG 以获取相关的冗余信息，之后将其丢弃。


### 图 {#图}


#### 控制流图 {#控制流图}

程序中最简单的控制流单位是**基本单位块** (BB, Basic Block)，也就是最大长度的无分支代码序列。BB 中的所有指令总是按顺序全部执行，结束于一个分支、跳转或条件跳转指令。

**控制流图** (CFG, Control Flow Graph) 对程序中各 BB 之间的控制流建立了模型。CFG 是一个有向图 \\(G=(N, E)\\)，每个结点 \\(n \in N\\) 对应于一个 BB，每条边 \\(e=(n\_{i},
n\_{j}) \in E\\) 对应于一个可能的从块 \\(n\_{i}\\) 到 \\(n\_{j}\\) 的一个可能的控制转移。
CFG 不同于面向语法的 IR，而是提供一种语法结构的表示。

假定每个 CFG 都有唯一的入口结点 \\(n\_{0}\\)，和一个唯一的出口结点 \\(n\_{f}\\)。对于有多个入口的一个过程，编译器可以添加 \\(n\_{0}\\) 到各个实际入口结点的边，对于更为常见的多出口，编译器将添加各个实际出口结点到 \\(n\_{f}\\) 的边。

```lua
while (condition) do
  stmt1
end
stmt2
```

{{< figure src="/images/compiler_principle-cfg-while-statement-example.svg" >}}

```lua
if (condition) then
  stmt1
else
  stmt2
end
stmt3
```

{{< figure src="/images/compiler_principle-cfg-if-else-statement-example.svg" >}}

编译器通常将 CFG 与另一种 IR 联用，从而组合成一种混合 IR。用 CFG 表示块之间的关系，而块内部采用表达式层次上的 AST、DAG 或某种线性 IR。

另外构造 CFG 时，代码块也可以不采用 BB 构造，而是使用对应于源代码层次上的单一语句的单语句块，单语句块可以简化用于分析和优化的算法。BB 与单语句块的选择实际上是时间与空间的权衡，单语句块需要更多的结点与边，同时遍历块结点时也需要更多的时间。


#### 依赖关系图 {#依赖关系图}

编译器还是用图来编码表示值从创建之外 (定义) 到使用处的流动，**数据依赖图** (DDG,
Data Dependence Graph) 就是用于表示这种关系的。

```lisp
;; LLVM IR
%1 = load of c[i]
%2 = load of b[i - 1]
%3 = fadd %1, %2
b[i] = %3
```

{{< figure src="/images/compiler_principle-ddg-example.svg" >}}

DDG 对操作序列进行了实际约束：一个值不能在定义前进行使用。因此编译器可以根据 DDG
对指令进行重排，这正是乱序重排的基础。DDG 通常作为衍生 IR使用，在指令调度中发挥着重要作用。另外，对数组元素的引用，其值取决于之前定义的数组变量结点，因此可以通过 DDG 将所有对数组的引用关联起来。


#### 调用图 {#调用图}

为解决跨过程边界的效率低下问题，编译器会进行过程间分析和优化。调用图 (Call
Graph) 用结点表示过程，边表示每个不同的过程的调用位置。比如，过程 p 中有三处不同位置对过程 q 的调用，因此调用图中有三条 `(p, q)` 的边。

但是软件工程方面的惯用法和语言特性都会使调用图变得复杂

-   **分离编译**，即分别独立编译程序的若干小子集的惯例，典型代表为 C / C++ 的编译单元为一个源文件。该行为限制了编译器建立调用图并进行过程间分析和优化的能力。
-   **过程参数**，即将过程作为参数或返回值的高阶函数，都会引入具有二义性的调用位置，使得调用图的构建复杂化。例如一个函数对象，同一个调用位置可能调用不同的过程。
-   **OO中的 override**


## 线性 IR {#线性-ir}

线性 IR 可以说是图 IR 的一种备选方案，当然汇编代码可以理解为一种线性代码。线性代码是一个指令序列，对序列进行顺序执行。线性 IR 用编码表达程序中各个位置间的控制转移，控制流通常模拟目标机上的实现。控制流将线性 IR 的 BB 划分开，块结束于分支、跳转或有标号的操作前。

线性 IR 有很多种类

-   单地址码模拟了累加器机器和堆栈机的行为，暴露了机器对隐式名字的使用，因此编译器能够相应地调整代码，由该 IR 得出的代码相当紧凑
-   二地址码模拟了具有破坏性操作的机器，随着内存逐渐富裕，这种代码逐渐废除
-   三地址码可以表示两个操作数和一个结果的操作，随着 RISC 指令集的崛起，这种与
    RISC 指令十分相似的 IR 被广泛使用

{{< admonition type="info" >}}
破坏性操作是一种用操作的结果重新定义其中一个操作数的操作
{{< /admonition >}}


### 堆栈机码 {#堆栈机码}

堆栈机码是一种单地址码，假定操作数存在一个栈中，大多数操作从栈中获取操作数，并将其结果推入栈中。例如，整数减法操作会从栈顶移出两个元素并计算其值，将结果入栈。

```asm
;; 计算 a - 2 * b
push 2
push b
multiply
push a
subtract
```

栈的存在产生了对某些新操作的需求，栈 IR 通常包括一个 swap 操作，用于交换栈顶两个元素的值。堆栈机码比较紧凑，由于栈本身建立了一个隐式的名称空间，从而消除了 IR 中的许多名字，极大缩减了 IR 形式下的程序大小。但是换来的是，所有的结果和参数都是暂态的，除非显示的将其移入内存。

堆栈机代码非常简单，且易于生成和使用，因此 Smalltalk80 和 Java 都采用了类似堆栈机码的字节码。


### 三地址码 {#三地址码}

三地址码是什么可以看[这里](https://blog.ginshio.org/2022/compilerprinciple_008/#%E4%B8%89%E5%9C%B0%E5%9D%80%E7%A0%81)。三地址码比较有吸引力的原因是

-   代码相当紧凑，操作通常占用 1 或 2 个字节，各个名字通常由整数或表索引表示，通常 4 个字节就够了，一条指令只需要占用很少的内存空间
-   操作数与结果可以分别指定名字，这给编译器提供了相当的自由度，以控制名字和值的重用，没有破坏性操作。谨慎选择的名称空间表示存在改进代码的新机会
-   许多现代处理器实现了三地址操作，三地址码可以有效模拟这一性质

由于抽象层次的不同，三地址码可以由极大的差异，通常会包含大部分底层操作 (如跳转、分支、内存操作等)，也有内部封装了控制流的高级指令 (如 max、min 等)。

例如 mvcl (move characters long) 指令 (功能与 C 函数 memcpy 一致)，在实现了该指令的架构上，编译器可以直接使用该指令表示复杂的操作，在不关注指令内部工作机制的情况下进行分析、优化、移动等操作。

实际编译器的中间表示可能有多种。

-   GCC 长期使用被称为**寄存器传输语言** (RTL, Register Transfer Language) 的底层 IR。近年 GCC 转移到了语法分析器产生特定接口的语法分析树，这些接口可以从语言相关的语法分析树转化为语言无关的类似于树的 IR -- GIMPLE。GIMPLE 使用表达式和赋值的三地址码对树结构进行了注解，并表示控制流，基于 GIMPLE 构建 SSA。之后 GCC
    将 GIMPLE 转化为 RTL 进行最后的优化和代码生成。
-   LLVM 使用单一的类型化的线性三地址 SSA IR，LLVM IR 对数组和结构地址提供了显示支持，还有对向量或 SIMD 数据和操作支持。
-   Open64 使用了一组被称为 WHIRL 的相关 IR (共 5 个)，WHIRL 提供了不同抽象层次的 IR，保存了足够多的信息用于提高优化效果。


## 将值映射到名字 {#将值映射到名字}

对特定 IR 和抽象层次的选择，有助于确定编译器能够操控和优化的操作。类似的，编译器对计算出的各种值分配内部名字的规则，也会对优化产生影响，可能会揭示优化的机会，也可能使优化的机会变得模糊。必须为程序执行过程中产生的许多中间结果进行命名，与名字相关的选择很大程度上决定了哪些计算过程是可以分析和优化的。


### 临时值的命名 {#临时值的命名}

IR 通常比源代码包含更多的细节，这些细节有的是源代码中隐含的，而有一些是在转换过程中的选择。比如一个简单的计算块

```lua
a = b + c
b = a - d
c = b + c
d = a - d
```

其中源代码并没有提供关于值的命名，由此可能误导他人第一行 \\(a = b + c\\) 与第三行
\\(c = b + c\\) 的值是相同的。而转换为 IR 后，由此多出了更多临时变量

```asm
;; LLVM IR
;; a = b + c
%1 = load i32, i32* %bp, align 4
%2 = load i32, i32* %cp, align 4
%3 = add nsw i32 %1, %2
     store i32 %3, i32* %ap, align 4
;; b = a - d
%4 = load i32, i32* %dp, align 4
%5 = sub nsw i32 %3, %4
     store i32 %5, i32* %bp, align 4
;; c = b + c
%6 = add nsw i32 %5, %2
     store i32 %6, i32* %cp, align 4
;; d = a - d
;; %5 = sub nsw i32 %3, %4
     store i32 %5, i32* %dp, align 4
```

很明显，源代码第三行的表达式 `b+c` 与第一行的表达式 `b+c` 表示的是完全不同的含义，而第二行却与第四行是完全相同的。

在底层 IR 中，各个中间结果都有自身的名字，使用不同的名字会将这些结果暴露给分析和变换的过程。编译器实现的大多数改进都来自对上下文的利用，因此 IR 必须暴露上下文信息，命名可能隐藏上下文信息，因为其中可能将一个名字用于表示多个不同的值；命名可能暴露上下文信息，只要能够在名字和值之间建立对应关系。


### 静态单赋值形式 {#静态单赋值形式}

静态单赋值形式 (SSA, Static Single-Assignment Form) 是一种命名规范，名字唯一地对应到代码特定的定义位置，每个名字都是通过单个操作定义的。因此每个名字都编码了对应值的来源地信息；文本化的名字实际上指向了一个特定的定义位置。为了使这种唯一性的命名规范与控制流效应相一致，SSA 会在控制流路径满足相应条件的位置上插入一些特殊操作，即 \\(\phi\\) (phi) 函数。

```lua
while (x < 100) do
  x = x + 1
  y = x + y
end
return y
```

\\(\phi\\) 是一种 IR 层面的伪指令，用于合并来自不同控制流的名字，并定义出一个新的名字。当然 \\(\phi\\) 不限于三地址模型，它可以添加任意数量的操作数。

```asm
;; LLVM IR
entry:
  %1 = load i32, i32* %xp, align 4
  %2 = load i32, i32* %yp, align 4
       br label %cond

cond:                                         ; preds = %entry, %loop
  %3 = phi i32 [ %1, %entry ], [ %6, %loop ]
  %4 = phi i32 [ %2, %entry ], [ %7, %loop ]
  %5 = icmp slt i32 %3, 100
       br i1 %5, label %loop, label %next

loop:                                         ; preds = %cond
  %6 = add nsw i32 %3, 1
  %7 = add nsw i32 %6, %4
       br label %cond

next:                                         ; preds = %cond
  ret i32 %4
```

\\(\phi\\) 的行为取决于上下文，它选择其中一个控制流中的名字来确定新定义的名字的值。当该块由 `entry` 块跳转而来时，名字 `%3` 使用 `%1` 作为其值；相反由 `loop` 块跳转而来时，其绑定的是 `%6` 的值。在 BB 的入口处，该块的所有 \\(\phi\\) 都将在任何其他语句之前并发执行，该行为允许操作 SSA 的算法在处理 BB 顶部时忽略 \\(\phi\\) 的顺序。

SSA 的 \\(\phi\\) 包含了值的产生与引用两个方面的信息，单赋值的特性使编译器可以规避许多与值的生命周期相关的问题。当然 SSA 会有一些问题，比如上面 LLVM IR 的代码，从
`entry` 块进入 `cond` 块时，实际上 `%6` 还没有被定义，因而 \\(\phi\\) 不可能读取该未定义值。


### 内存模型 {#内存模型}

如命名会影响 IR 能够表示的信息一样，编译器对于每个值存储的位置也有类似的影响。对于代码中计算的每个值，编译器必须确定该值将驻留在何处。一般来说编译器使用以下两种内存模型：

1.  寄存器到寄存器的模型 (Register-to-Register Model)

    编译器可以激进的将值保存在寄存器中，忽略物理寄存器集合规定的任何限制。编译器可在其生命周期内合法的将值保存在寄存器中，仅程序显式的要求将值存储在内存中，编译器才采取相应的操作。在过程间调用时，如果任何局部变量作为参数传地给被调用过程，这些局部变量必须存储在内存中。而有些值无法存储在寄存器中，也将被存储在内存。编译器将会生成相应的代码，每次计算出值时将其存储到内存，使用时从内存加载进来。

    1.  内存到内存的模型 (Memory-to-Memory Model)

        编译器假定所有值都在内存中，只有使用时加载进内存，使用完毕后将值立即写回内存。这种模型下的 IR 引用的寄存器数目会小一些，不过可能需要设计者添加内存到内存的操作 (如内存到内存的加法)。

内存模型的选择会影响到其余部分。比如 R2R Model 编译器通常假设虚拟寄存器是无限多个，因而寄存器分配必须将 IR 中使用的虚拟寄存器集合映射到物理寄存器上。但是 R2R
Model 同样反映出该值在寄存器中是安全的。


## 符号表 {#符号表}

作为转换过程的一部分，编译器需要推导与被转换程序操控的各种实体有关的信息。它必须发现并存储许多不同种类的信息，如遇到的各种各样的名字：变量、常数、过程、函数、标号、结构和文件。

当然还有很多额外信息。比如对一个变量，需要包括数据类型、存储类别、声明变量的过程名、语法层次、在内存中的存储位置等。而对于一个数组，编译器还需要知道数组的维数和各个维度上索引的上下界。对于记录或结构，编译器需要了解成员字段和每个字段的相关信息。而对于函数和过程，编译器需要知道参数的数目，以及各参数的类型，可能还有返回值类型。

编译器需要在 IR 中记录这些信息，或者按需推导。但是大部分编译器都会直接存储这些信息，如将其记录在变量声明的结点中。遍历查找声明是需要代价的，当然也可以将 IR 线索化，每次引用都有一个指向对应声明的链接。

另一种选择是建立一个中央存储库，以提供相关信息的高效访问，这就是现代编译器中不可或缺的符号表。当然一个编译器可能包含几个不同的、专门化的符号表。


### 处理嵌套的作用域 {#处理嵌套的作用域}

大多数编程语言允许程序在多个层次上声明名称，每个层次都在程序的文本中有一个作用域，声明的名字将在作用域中使用。而作用域在运行时对应着生命周期，即其中的变量在运行时会保存的时间。如果源语言允许嵌套的作用域，那么前端需要一种机制将特定的引用转换为正确的作用域和生命周期。编译器进行这种转换的主要机制是一种作用域化的符号表。

```scheme
(let ((x 3) (y 4)) (* x y)) ; => 12
(* x y) ; ERROR: unbound variable:  x
```

为编译包含嵌套作用域的程序，编译器必须将每个变量引用映射到与之对应的特定声明。这个过程称为**名字解析** (name resolution)，将各次引用映射到其声明所在的词法层次，完成这一工作的就是作用域化的符号表。

在管理嵌套作用域时，语法分析器必须稍微改变一下其管理符号表的方法。语法分析器每次进入一个新的词法作用域时，它将为该作用域建立一个新的符号表。这种方法将创建一<span class="underline">束</span>符号表，按词法作用域的层次嵌套关系连接在一起，在当前作用域中遇到声明时，就将相应的信息输入到当前作用域的符号表中。在遇到引用时，需要检查当前作用域的符号表，如果当前符号表并不包含该名字的声明，那么就依次向外一层检查，直到遇到该名字的声明或所有可见的作用域都没有该名字的声明。

{{< figure src="/images/compiler_principle-symbol-table-example.svg" >}}


### 符号表的用途 {#符号表的用途}

编译器可能会建立许多不同的符号表来用于不同的目标。


#### 结构表 {#结构表}

用于指定结构或记录中字段的文本串，存在与变量和过程不同的名称空间。对于结构中的每个字段，编译器必须记录其类型、大小、结构内偏移量等信息，它还需要确定结构的总长度。管理字段名的命名空间由几种方式：

-   **独立表**， 编译器为每个记录定义维护一个对应的符号表。概念上这种方式最干净纯粹。
-   **选择符表**，编译器可以为所有字段名维护一个独立的表。为避免不同结构中同名字段间的冲突，编译器必须使用修饰名，即为同一个结构中的字段添加同样的但全局唯一的前缀。该前缀可以是结构名，也可以是结构名在符号表中的索引值。这种方法编译器必须想办法将同一个结构的字段关联起来。
-   **统一表**，编译器通过修饰名将字段同样存储在主符号表中，这样可以减少表的数目，但也意味着增加主符号表中的表项与字段。

独立表的好处在于，任何与作用域相关的问题，都可以自然而然地匹配到主符号表的作用域管理框架中，结构本身可见时，其内部的符号表可以通过结构在主符号表中的表项访问。


#### 使用链接表解决 OO 范式的名字解析问题 {#使用链接表解决-oo-范式的名字解析问题}

OO 范式中的名字的作用域规则同时取决于数据的结构与代码的结构，这也导致出现了一组更复杂的符号表。比如 Java 中对于正在被编译的代码、代码中已知和引用的任何外部类、包含代码的类之上的继承层次，都分别需要相应的符号表。

相对简单的实现方式是，对每个类附加一个符号表，其中涉及两个嵌套的层次结构：用于类中各个方法内部的词法作用域，和追踪类的继承层次结构。

编译器对每个方法都需要一个词法作用域化的符号表，对每个类都需要一个包含指向继承层次中父类的链接符号表。当然还需要指向其他类的符号表的链接，以及指向包层次变量符号表的链接。
