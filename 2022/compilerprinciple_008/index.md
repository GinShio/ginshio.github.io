# 中间代码生成


在将给定源语言的一个程序翻译成特定机器代码的过程中，一个编译器可能构造出一系列中间表示。高层的中间表示接近源语言，而底层的表示接近目标语言。语法树是高层表示，它刻画了源程序的自然层次性结构，且适用于静态类型检查。低层表示适用于机器相关处理，如寄存器分配、指令选择等。


## 语法树的变体 {#语法树的变体}

语法树中的各个结点代表了源程序的构造，一个结点的所有子结点反映了该结点对应构造的有意义的组成成分。为表达式构建的有向无环图 (Directed Acyclic Graph, DAG) 指出了表达式中的公共子表达式。

与语法分析树有些不同的是，DAG 的结点可能有多个父结点，也就是说这个结点是个公共子结点。比如表达式 \\(a + a \* (b - c) + (b - c) \* d\\)

{{< figure src="/images/DAG-for-6.1-example.svg" >}}

SDD 既可以构造语法树，也可以构造 DAG，在构造 DAG 结点时每次构造之前都会检查是否已存在这样的结点。如果已存在结点，就返回已有结点，否则构建新结点。

| 编号 | 产生式                                                                        | 语义规则                                                                                               |
|----|----------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------|
| 1  | \\(E\rightarrow{}E\_{1}+T\\)                                                  | \\(E.node=\textbf{new}\ Node('+',E\_{1}.node,T.node)\\)                                                |
| 2  | \\(E\rightarrow{}E\_{1}-T\\)                                                  | \\(E.node=\textbf{new}\ Node('-',E\_{1}.node,T.node)\\)                                                |
| 3  | \\(\begin{aligned}E&\rightarrow{}T\\\T&\rightarrow{}T\_{1}\*F\end{aligned}\\) | \\(\begin{aligned}E.node&=T.node\\\T.node&=\textbf{new}\ Node('\*',T\_{1}.node,F.node)\end{aligned}\\) |
| 4  | \\(T\rightarrow{}(E)\\)                                                       | \\(T.node=E.node\\)                                                                                    |
| 5  | \\(T\rightarrow{}\textbf{id}\\)                                               | \\(T.node=\textbf{new}\ Leaf(\textbf{id},\textbf{id}.entry)\\)                                         |
| 6  | \\(T\rightarrow{}\textbf{num}\\)                                              | \\(T.node=\textbf{new}\ Leaf(\textbf{num},\textbf{num}.entry)\\)                                       |

通常语法树或 DAG 的结点存放在记录数组中，每个记录第一个字段是运算符代码，也是该结点的标号；叶结点可能有一个存放词法值的字段，而内部结点可能有两个指向其左右运算数的字段。

在这样的一个数组中，我们只需要给定结点对应的整数下标就可以引用该结点了。而这个下标被称为表达式的**值编码** (value number)。通常为了防止结点太多所造成的巨大的搜索开销，可以用 Hash 的方法实现，加快创建结点时的搜索。


## 三地址码 {#三地址码}

三地址码中一条指令的右侧最多有一个运算符，因此 \\(x+y\*z\\) 这样的代码可能被翻译成
\\[\begin{aligned}
t\_{1} &= y \* z\\\\
t\_{2} &= x + t\_{1}
\end{aligned}\\]


### 地址和指令 {#地址和指令}

三地址码基于两个基本概念：地址和指令。地址通常具有以下形式之一：

-   名字，为方便起见，允许源程序名字作为三地址码的地址。实现中通常是指向符号表的指针
-   常量
-   编译器生成的临时变量

还有其他一些三地址指令的形式：

-   形如 `x = y op z` 的赋值指令，其中 op 是双目运算符，x/y/z 是地址
-   形如 `x = op y` 的赋值指令，其中 op 是单目运算符，x/y 是地址
-   形如 `x = y` 的复制指令，将 y 的值赋给 x
-   无条件转移指令 `goto L`，下一步执行的指令为标号为 L 的三地址码
-   形如 `if x goto L` 或 `if False x goto L` 的条件转移指令，当条件 x 为假时转移到标号为 L 的三地址码，否则顺序执行下一指令
-   形如 `if x relop y goto L` 条件转移指令，如果 x 和 y 满足 relop 关系则跳转，否则顺序执行
-   过程调用 `call p,n`，参数传递 `param x`，返回指令 `return y`
-   带下标的指令 `x[i] = y` 和 `x = y[i]`
-   形如 `x = &y`、`x = *y` 或 `*x = y` 的地址及指针赋值指令

比方说语句 `do i = i + 1; while (a[i] < v);` 可以翻译为三地址码

```text
L:  t1 = i + 1
    i = t1
    t2 = i * 8
    t3 = a [ t2 ]
    if t3 < v goto L
```

当然也可以

```text
100:  t1 = i + 1
101:  i = t1
102:  t2 = i * 8
103:  t3 = a [ t2 ]
104:  if t3 < v goto 100
```


### 四元式表示 {#四元式表示}

[地址和指令](#地址和指令) 一节中介绍了三地址码的具体组成，但在数据结构上的表示方法，常用四元式、三元式和间接三元式这三种描述方式。

四元式 (quadruple) 有四个字段，分别是 op、arg1、arg2 和 result，其中 op 是运算符的内部编码。比如三地址码 `x=y+z` 可以用四元式 `(=, y, z, x)` 表示。但有一些特例：

1.  形如 `x = -y` 这样的单目运算符和赋值运算符 `x = y`，不使用 arg2
2.  形如 `param` 这样的运算既不使用 arg2 也不使用 result
3.  条件或非条件转移指令将目标标号存入 result 字段

比如说语句 `a = b * -c + b * -c`，可以得到三地址码

```text
t1 = minus c
t2 = b * t1
t3 = minus c
t4 = b * t3
t5 = t2 + t4
a = t5
```

得到的四元式

| No | op    | arg1 | arg2 | result |
|----|-------|------|------|--------|
| 1  | minus | c    |      | t1     |
| 2  | \*    | b    | t1   | t2     |
| 3  | minus | c    |      | t3     |
| 4  | \*    | b    | t3   | t4     |
| 5  | +     | t2   | t4   | t5     |
| 6  | =     | t5   |      | a      |


### 三元式表示 {#三元式表示}

三元式 (triple) 只有 op、arg1、arg2 三个字段，四元式中 result 字段主要保留的是临时变量，因此三元式中用运算的位置表示其结果。但是像 `x[i] = y` 这样的三元式，需要两个条目，我们可以把 x 和 i 置于同一个三元式，y 置于另一个三元式。

作为语句 `a = b * -c + b * -c`，可以得到三元式

| No | op    | arg1 | arg2 |
|----|-------|------|------|
| 1  | minus | c    |      |
| 2  | \*    | b    | (1)  |
| 3  | minus | c    |      |
| 4  | \*    | b    | (2)  |
| 5  | +     | (1)  | (3)  |
| 6  | =     | a    | (4)  |

对于优化器来说，指令的位置会经常发生变化，此时四元式用临时变量引用结果，不会有任何变化，但三元式中使用位置引用结果的，这将导致需要频繁修改指令。

间接三元式 (indirect triple) 包含了一个指向三元式的指针列表，而不是指向序列本身。在优化重排三元式时，可以直接对间接的指针列表进行重排，不会影响三元式本身。

当然间接引用列表和三元式表不在一起，只是为了方便展示，才放在一起。

| instruction | No | op    | arg1 | arg2 |
|-------------|----|-------|------|------|
| (1)         | 1  | minus | c    |      |
| (2)         | 2  | \*    | b    | (1)  |
| (3)         | 3  | minus | c    |      |
| (4)         | 4  | \*    | b    | (2)  |
| (5)         | 5  | +     | (1)  | (3)  |
| (6)         | 6  | =     | a    | (4)  |


### 静态单赋值形式 {#静态单赋值形式}

静态单赋值形式 (static single assignment, SSA) 是另一种中间表示，它有利于实现某种类型的代码优化。SSA 中所有的赋值都是针对具有不同名字的变量。

| 三地址码   | 静态单赋值形式 |
|--------|---------|
| p = a + b  | p1 = a + b   |
| q = p - c  | q1 = p1 - c  |
| p = q \* d | p2 = q1 \* d |
| p = e - p  | p3 = e - p2  |
| q = p + q  | q2 = p3 + q1 |

在一个程序中，同一个变量可能在两个不同的控制流中被赋值，比如
\\[\begin{aligned}
& \textbf{if}\ (flag)\ x\\,=\\,-1;\ \textbf{else}\ x\\,=\\,1;\\\\
& y\\,=\\,x\\,\*\\,a;
\end{aligned}\\]

但是最终 y 的取值，应该由哪个 x 变量决定。SSA 给出的解决方案是 \\(\phi\\) 函数，将 x
的两处赋值合并起来，最终得到的是
\\[\begin{aligned}
& \textbf{if}\ (flag)\ x\_{1}\\,=\\,-1;\ \textbf{else}\ x\_{2}\\,=\\,1;\\\\
& x\_{3}\\,=\\,\phi(x\_{1},\\,x\_{2});
\end{aligned}\\]

如果控制流经过这个条件语句为真，那么 \\(\phi(x\_{1},x\_{2})\\) 的值为 \\(x\_{1}\\)，否则值为 \\(x\_{2}\\)。也就是说，根据到达包含\\(\phi\\)函数的赋值语句的不同控制流路经，\\(\phi\\)函数返回不同的数值。


## 类型和声明 {#类型和声明}

可以将类型的应用划为类型检查和翻译：

类型检查 (type checking)
: 用一组逻辑规则来推理一个程序在运行时的行为。保证运算分量的类型和运算符的预期相匹配。

翻译时的应用 (translation application)
: 根据一个名字的类型，编译器可以确定这个名字在运行时需要多大的存储空间，或者其他需要类型信息的地方。


### 类型表达式 {#类型表达式}

类型也有自己的结构，也就是我们说的类型表达式 (type expression)。类型表达式可能是基本类型，也可能通过将类型构造算子 (运算符) 作用于类型表达式。基本类型的集合和类型构造算子根据被检查的具体语言而定。就像 `int[2][3]` 被解释为
`array(2, array(2, integer))`

-   基本类型是一个类型表达式
-   类名是一个类型表达式
-   将类型构造算子 `array` 作用一个数字和一个类型表达式，可以得到一个类型表达式
-   一个记录是包含有名字段的数据结构，将 `record` 类型构造算子应用于字段名和相应的类型可以构造得到一个类型表达式
-   使用类型构造算子 \\(\rightarrow\\) 可以构造得到函数类型的类型表达式
-   如果 s 和 t 是类型表达式，那么可以使用笛卡尔积 \\(s \times t\\) 描述类型的列表或元组，且假定 \\(\times\\) 是左结合的，且享有最高优先级
-   类型表达式的值可以为该类型的变量

图是表示类型表达式的方便方法，内部结点表示类型构造算子，而叶结点可以是基本类型、类型名或类型变量。这与构造 DAG 的结点的值编码方式类似。


### 类型等价 {#类型等价}

如果两个类型表达式相等，那么这两个类型等价。不过在给一个类型表达式起别名时，在类型表达式中的别名代表一个类型，还是另一个类型表达式的缩写。

当用图表示类型表达式时，只有以下的某个条件成立时，两种类型之间**结构等价**
(structurally equivalent)。如果类型名仅表示自身，那么前两个定义了类型表达式的**名等价** (name equivalence) 关系

-   它们是相同的基本类型
-   它们是将相同的类型构造算子应用于结构等价的类型而构造得到
-   一个类型是另一个类型表达式的别名

如果使用与 DAG 结点的编码方式，那么名等价表达式将被赋予相同的值编码。


### 声明 {#声明}

在研究类型及其声明时，将使用一个经过化简的文法，一次只声明一个名字。
\\[\begin{aligned}
D &\rightarrow{} T \\, \textbf{id};\ D\ |\ \varepsilon\\\\
T &\rightarrow{} B C \ |\ \textbf{record}\\, '\\{' \\, D \\, '\\}'\\\\
B &\rightarrow{} \textbf{int}\ |\ \textbf{float}\\\\
C &\rightarrow{} \varepsilon\ |\ [ \\, \textbf{num} \\, ] \\, C
\end{aligned}\\]


### 局部变量名的存储布局 {#局部变量名的存储布局}

从变量的类型可以得知类型信息或所需的内存占用。在编译时，可以使用这些数量为每个名字分配一个相对地址。名字的类型和相对地址信息保存在相应的符号表条目中。对于字符串这样的变长数据，以及动态数组这样的只有运行时才能确定大小的数据，处理方法是为这些数据的指针保留一个已知的固定大小的存储区域。

假设存储区域是连续的字节块，其中字节是可寻址的最小内存单位。一个字节通常有 8 bit，若干字节组成一个机器字。多字节数据对像往往被存储在一段连续的字节中，并以初始字节的地址作为该数据对象的地址。

类型的**宽度** (width) 是指该类型的每个对象需要多少存储单元。一个基本类型需要整数个字节，为方便访问，数组和类这样的组合类型数据分配的内存是一个连续存储的字节块。

因此我们可以给出[声明](#声明)中给出的示例的 SDT，在这个 SDT 中，每个非终结符使用综合属性
type 和 width 记录类型信息，并有继承属性 t 和 w 传递类型信息。
\\[\begin{array}{lllll}
T &\rightarrow &B                           &\\{&t=B.type;\\,w=B.width;\ \\}\\\\
  &  &C                           &\\{&T.type=C.type;\\,T.width=C.width;\ \\}\\\\
B &\rightarrow &\textbf{int}                &\\{&B.type=integer;\\,B.width=4;\ \\}\\\\
B &\rightarrow &\textbf{float}              &\\{&B.type=float;\\,B.width=8;\ \\}\\\\
C &\rightarrow &\varepsilon                 &\\{&C.type=t;\\,C.width=w;\ \\}\\\\
C &\rightarrow &[\\,\textbf{num}\\,]\\,C\_{1}   &\\{&C.type=array(\textbf{num}.value,C\_{1}.type);\\\\
  &  &                            &  &C.width=\textbf{num}.value\*C\_{1}.width;\ \\}
\end{array}\\]

现在还不足以支持我们为及其相关的特性进行优化，比如地址与机器字对齐。


### 声明的序列 {#声明的序列}

像 C 和 Java 这样的语言支持将单个过程中的所有声明作为一个组进行处理。这些声明可能分布在一个 Java 过程中，但仍然能够在分析过程处理它们。比如使用 offset 作为跟踪下一个可用的相对地址的变量。

在声明序列之前，将 offset 设置为 0，每处理一个变量时，将其加入符号表，并将相对地址设置为当前的 offset，并为 offset 累加上当前变量的 width。

\\[\begin{array}{lllll}
P &\rightarrow{} &                  & \\{ & offset=0;\ \ \\}\\\\
  &    & D                &    & \\\\
D &\rightarrow{} & T\ \textbf{id};  & \\{ & top.put(\textbf{id}.lexeme, T.type, offset);\\\\
  &    &                  &    & offset=offset + T.width;\ \ \\}\\\\
  &    & D\_{1}            &    & \\\\
D &\rightarrow{} & \varepsilon                &    & \\\\
\end{array}\\]


### 记录和类中的字段 {#记录和类中的字段}

[声明的序列](#声明的序列)中介绍的方案还可以用于记录和类中的字段。但需要注意

-   记录或类中的各个字段名称必须不同
-   字段的偏移量 (相对地址) 是相对于该记录或类的数据区地址而言的

由于外部可能和内部名称相同，但它们属于不同的作用域，其地址也各不相同。因此方便起见，记录或类类型可以使用一个专有的符号表，对它们的各个字段的类型和相对地址进行编码。
\\[\begin{array}{llll}
T \ \rightarrow & \textbf{record} '\\{' & \\{ & Env.push(top);\ top=\textbf{new}\\,Env();\\\\
                &                      &    & Stack.push(offset);\ offset=0;\ \ \\}\\\\
                & D\ '\\}'              & \\{ & T.type=recode(top);\ T.width=offset;\\\\
                &                      &    & top=Env.top();\ offset=Stack.pop();\ \ \\}
\end{array}\\]

关于记录类型的存储方式还可以推广到类中，因为无需为类中的方法保留存储空间。


## 表达式的翻译 {#表达式的翻译}


### 表达式中的运算 {#表达式中的运算}

考虑一个赋值语句，用 SDD 为其生成三地址码。属性 S.code 和 E.code 分别表示语句和表达式的三地址码，属性 E.addr 存放 E 的值的地址。

\\[\begin{array}{llllll}
S &\rightarrow{} & \textbf{id} = E\ ; & \\{ & S.code = &E.code\ ||\\\\
  &    &                    &    &          &gen(top.get(\textbf{id}.lexeme)\ '='\ E.addr);\ \ \\}\\\\
E &\rightarrow{} & E\_{1} + E\_{2}      & \\{ & E.addr = &\textbf{new}\\,Temp();\\\\
  &    &                    &    & E.code = &E\_{1}.code\ ||\ E\_{2}.code\ ||\\\\
  &    &                    &    &          &gen(E.addr\ '='\ E\_{1}.addr\ '+'\ E\_{2}.addr);\ \ \\}\\\\
  &|{} & -\\,E\_{1}           & \\{ & E.addr = &\textbf{new}\\,Temp();\\\\
  &    &                    &    & E.code = &E\_{1}.code\ ||\\\\
  &    &                    &    &          &gen(E.addr\ '='\ '\textbf{minus}'\ E\_{1}.addr);\ \ \\}\\\\
  &|{} & (\\,E\_{1}\\,)        & \\{ & E.addr = &E\_{1}.addr;\\\\
  &    &                    &    & E.code = &E\_{1}.code\ \ \\}\\\\
  &|{} & \textbf{id}        & \\{ & E.addr = &top.get(\textbf{id}.lexeme);\\\\
  &    &                    &    & E.code = &''\ \ \\}
\end{array}\\]

可以将 `new Temp()` 理解为产生一个完全不同的临时变量，对应三地址码中的一个临时变量。而 `gen()` 可以理解为产生一个三地址码。

因此根据上面这个 SDD，可以将表达式 `a = b + -c` 表示为三地址码序列
\\[\begin{aligned}
t\_{1} &= \texttt{minus}\ c\\\\
t\_{2} &= b + t\_{1}\\\\
a &= t\_{2}
\end{aligned}\\]


### 数组元素的寻址 {#数组元素的寻址}

将数组元素存储在一块连续的空间里就可以快速地访问它们。假设数组元素的宽度为 w，那么数组的第 i 个元素的开始地址为 \\(base + i \* w\\)，base 是数组的内存开始的相对地址，也就是 `array[0]` 的相对地址。对于二维数组，假设一行的宽度是 \\(w\_{1}\\)，同一行中每个元素的宽度是 \\(w\_{2}\\)，那么 \\(array[i\_{1}][i\_{2}]\\) 的相对地址的计算公式为
\\[base + i\_{1} \* w\_{1} + i\_{2} \* w\_{2}\\]

对 k 维数组，根据 \\(w\_{1}\\) 和 \\(w\_{2}\\) 的推广，可以得到
\\[base + i\_{1} \* w\_{1} + i\_{2} \* w\_{2} + \cdots + i\_{k} \* w\_{k}\\]

如果数组第 j 维上有 \\(n\_{j}\\) 个元素，该数组的每个元素的宽度 \\(w=w\_{k}\\)，在二维数组中 (即 \\(k=2,\\,w=w\_{2}\\)) \\(array[i\_{1}][i\_{2}]\\) 的相对地址为
\\[base + (i\_{1} \* n\_{2} + i\_{2}) \* w\\]

推广的 k 维数组，可以得到
\\[base + ((\cdots ((i\_{1} \* n\_{2} + i\_{2}) \* n\_{3} + i\_{3}) \cdots) \* n\_{k} + i\_{k}) \* w\\]


### 数组引用的翻译 {#数组引用的翻译}

为数组引用生成代码时要解决的首要问题是将地址计算公式与引用文法关联起来，首先文法可以由 \\(L\ \rightarrow\ {}L\\,[\\,E\\,]\ |\ \textbf{id}\\,[\\,E\\,]\\) 给出。

\\[\begin{array}{lllll}
S &\rightarrow{} &\textbf{id}\\,=\\,E\ ; & \\{ & gen(top.get(\textbf{id}.lexeme)\\,'='\\,E.addr);\ \ \\}\\\\
  &|{} &L\\,=\\,E\ ;           &    & gen(L.array.base\\,'['\\,L.addr\\,']'\\,'='\\,E.addr);\ \ \\}\\\\
E &\rightarrow{} &E\_{1}\\,+\\,E\_{2}      & \\{ & E.addr\\,=\\,\textbf{new}\ Temp();\\\\
  &    &                     &    & gen(E.addr\\,'='\\,E\_{1}.addr\\,'+'\\,E\_{2}.addr);\ \ \\}\\\\
  &|{} &\textbf{id}          & \\{ & E.addr\\,=\\,top.get(\textbf{id}.lexeme);\ \ \\}\\\\
  &|{} &L                    & \\{ & E.addr\\,=\\,\textbf{new}\ Temp();\\\\
  &    &                     &    & gen(E.addr\\,'='\\,L.array.base\\,'['\\,L.addr\\,']');\ \ \\}\\\\
L &\rightarrow{} &\textbf{id}\\,[\\,E\\,] & \\{ & L.array\\,=\\,top.get(\textbf{id}.lexeme);\\\\
  &    &                     &    & L.type\\,=\\,L.array.type.elem;\\\\
  &    &                     &    & L.addr\\,=\\,\textbf{new}\ Temp();\\\\
  &    &                     &    & gen(E.addr\\,'='\\,E.addr\\,'\*'\\,L.type.width);\ \ \\}\\\\
  &|{} &L\_{1}\\,[\\,E\\,]       & \\{ & L.array\\,=\\,L\_{1}.array\\\\
  &    &                     &    & L.type\\,=\\,L\_{1}.type.elem\\\\
  &    &                     &    & t\\,=\\,\textbf{new}\ Temp();\\\\
  &    &                     &    & L.addr\\,=\\,\textbf{new}\ Temp();\\\\
  &    &                     &    & gen(t\\,'='\\,E.addr\\,'\*'\\,L.type.width);\\\\
  &    &                     &    & gen(L.addr\\,'='\\,L\_{1}.addr\\,'+'\\,t);\ \ \\}
\end{array}\\]

非终结符 L 有三个综合属性

1.  L.addr 表示一个临时变量，被用于累加计算地址的 \\(i\_{j} \* w\_{j}\\) 项，计算数组的偏移量
2.  L.array 指向数组名称对应的符号表指针，L.array.base 是分析完所有下标后，数组的起始地址
3.  L.type 是 L 生成的子数组类型，其宽度为 t.width，数组的元素类型由 t.elem 给出

如果 a 表示一个 \\(2\times3\\) 的整数数组，c、i、j 都是整数，那么 a 的类型是
\\(array(2, array(3, integer))\\)。假设整数宽度为 4，那么 a 的宽度为 24。`a[i]` 的类型为 \\(array(3, integer)\\)，宽度 \\(w\_{1}\\) 为 12。

表达式 \\(c+a[i][j]\\) 的三地址码可以表示为：
\\[\begin{aligned}
t\_{1} &= i\*12\\\\
t\_{2} &= j\*4\\\\
t\_{3} &= t\_{1}+t\_{2}\\\\
t\_{4} &= a\\,[\\,t\_{3}\\,]\\\\
t\_{5} &= c + t\_{4}
\end{aligned}\\]

{{< figure src="/images/annotated-parse-tree-for-6.12-example.svg" >}}


## 类型检查 {#类型检查}

为了进行类型检查，编译器需要给源程序的每个组成部分赋予一个类型表达式，编译器确定这些类型表达式是否满足一组逻辑规则，这些规则称为源语言的**类型系统** (type system)。

如果目标代码在保存元素值的同时保存了类型信息，那么任何检查都可以动态地进行。一个
`健全` (sound) 的类型系统可以消除对动态类型错误检查的需要，因为它可以静态地确定这些错误不会在目标程序运行时发生。如果编译器可以保证它接受的程序在运行时不会发生类型错误，那么该语言的实现被称为`强类型的`。


### 类型检查规则 {#类型检查规则}

类型检查由两种形式，`综合`和`推导`。类型综合 (type synthesis) 根据子表达式的类型构造该表达式的类型。它要求名字先声明再使用。表达式 \\(E\_{1}+E\_{2}\\) 的类型是根据
\\(E\_{1}\\) 和 \\(E\_{2}\\) 定义的。还有一个经典例子：如果 f 的类型是 \\(s\rightarrow{}t\\) 且 x
的类型是 s，那么 `f(x)` 的类型是 t。

类型推导 (type inference) 根据一个语言结构的使用方式来确定该结构的类型，比如说
`null(x)` 检测一个列表是否为空，x 必须是列表类型，但内部元素类型是未知的 (往往用
\\(\alpha\\)、\\(\beta\\) 等希腊字母作为类型变量)。

同样地，对于语句我们也可以由类似的检查，比如条件语句 \\(\textbf{if}\\,(E)\\,S\\)，可以看作接收 E 为布尔类型，而语句结果为 void 类型。


### 类型转换 {#类型转换}

考虑类似于 \\(x+i\\) 的表达式，如果 x 是浮点类型且 i 是整型，它们需要不同的指令来完成运算。编译器需要把 \\(+\\) 的某个运算分量进行转换，以保证进行运算时，两个运算分量具有相同的类型。

大概可以用近似实现

```c
if (E1.type == integer && E2.type == integer) E.type = integer;
else if (E1.type == float && E2.type == integer) E.type = float;
...
```

但是类型的增多将需要处理的工作量也急剧增长。因此，在处理大量类型时，精心组织用于类型转换的语义动作就变得十分重要。

不过不同语言的类型转换规则是不同的，Java 的转换规则分为`拓宽` (widening) 和`窄化`
(narrowing)，前者可以保持原有信息，而后者则可能丢失信息。

{{< figure src="/images/java-type-conversion-example.svg" >}}

如果类型转换由编译器完成，那么称作隐式类型转换，或者自动类型转换 (conversion)，有些语言中只允许拓宽进行隐式转换。如果由程序员写出代码完成的类型转换称为显示类型转换，或者说强制类型转换 (cast)。

检查 \\(E\rightarrow{}E\_{1}+E\_{2}\\) 的语义动作可以使用两个函数

-   `max(t1, t2)` 接受两个类型参数，并返回扩展层次结构中的较大者。如果两个类型不在这个层次结构中，返回错误
-   如果需要类型 t 的地址 a 中的内容转换成 w 类型的值，则函数 `widen(a, t, w)`
    将生成转换代码。如果 t 和 w 相同，则返回 a 本身；否则生成一条指令来进行转换，并返回临时结果对象。

现在我们可以很轻松地处理加法
\\[\begin{array}{llll}
E &\rightarrow{} E\_{1} + E\_{2} & \\{ & E.type = max(E\_{1}.type, E\_{2}.type);\\\\
  &                  &    & a\_{1} = widen(E\_{1}.addr, E\_{1}.type, E.type);\\\\
  &                  &    & a\_{2} = widen(E\_{2}.addr, E\_{2}.type, E.type);\\\\
  &                  &    & E.addr = \textbf{new}\ Temp();\\\\
  &                  &    & gen(E.addr\\,'='\\,a\_{1}\\,'+'\\,a\_{2});\ \ \\}
\end{array}\\]


## 控制流 {#控制流}

布尔表达式通常被用来：

-   **改变控制流**
-   **计算逻辑值**


### 布尔表达式与短路代码 {#布尔表达式与短路代码}

布尔表达式由作用于布尔变量或关系表达式的布尔运算符构成，文法通常如 (其中 comp 是比较运算符)：
\\[\begin{array}{lll}
B & \rightarrow{} & B\ ||\ B \\\\
  & |{} & B\ \\&\\&\ B \\\\
  & |{} & !B \\\\
  & |{} & (\\,B\\,) \\\\
  & |{} & E\ \textbf{comp}\ E \\\\
  & |{} & \textbf{true}\\\\
  & |{} & \textbf{false}
\end{array}\\]

程序设计语言的语义决定了是否需要对一个布尔表达式进行完整求值，如果允许部分求值足以确定整个表达式的值时不再执行完全求值，这被称为短路运算。


### 控制流语句 {#控制流语句}

常见的控制流语句如下
\\[\begin{array}{lll}
S &\rightarrow{} & \textbf{if}\ (\\,B\\,)\ S\_{1}\\\\
  &|{} & \textbf{if}\ (\\,B\\,)\ S\_{1}\ \textbf{else}\ S\_{2}\\\\
  &|{} & \textbf{while}\ (\\,B\\,)\ S\_{1}\\\\
  &|{} & S\_{1}\ S\_{2}
\end{array}\\]

控制流会出现类似以下的效果
![](/images/control-flow-code.svg)

以这种结构实现控制流语句的 SDD
\\[\begin{array}{llll}
P &\rightarrow{} S                                                 & S.next     &= newlabel()\\\\
  &                                                      & P.code     &= S.code\ ||\ label(S.next)\\\\
S &\rightarrow{} \textbf{assign}                                   & S.code     &= \textbf{assign}.code\\\\
S &\rightarrow{} \textbf{if}\ (\\,B\\,)\ S\_{1}                       & B.true     &= newlabel()\\\\
  &                                                      & B.false    &= S\_{1}.next = S.next\\\\
  &                                                      & S.code     &= B.code\ ||\ label(B.true)\ ||\ S\_{1}.code\\\\
S &\rightarrow{} \textbf{if}\ (\\,B\\,)\ S\_{1}\ \textbf{else}\ S\_{2} & B.true     &= newlabel()\\\\
  &                                                      & B.false    &= newlabel()\\\\
  &                                                      & S\_{1}.next &= S\_{2}.next = S.next\\\\
  &                                                      & S.code     &= B.code\\\\
  &                                                      &            &||\ label(B.true)\ ||\ S\_{1}.code\\\\
  &                                                      &            &||\ gen('goto'\ S.next)\\\\
  &                                                      &            &||\ label(B.false)\ ||\ S\_{2}.code\\\\
S &\rightarrow{} \textbf{while}\ (\\,B\\,)\ S\_{1}                    & begin      &= newlabel()\\\\
  &                                                      & B.true     &= newlabel()\\\\
  &                                                      & B.false    &= S.next\\\\
  &                                                      & S\_{1}.next &= begin\\\\
  &                                                      & S.code     &= label(begin)\ ||\ B.code\\\\
  &                                                      &            &||\ label(B.true)\ ||\ S\_{1}.code\\\\
  &                                                      &            &||\ gen('goto'\ begin)\\\\
S &\rightarrow{} S\_{1}\ S\_{2}                                      & S\_{1}.next &= newlabel()\\\\
  &                                                      & S\_{2}.next &= S.next\\\\
  &                                                      & S.code     &= S\_{1}.code\ ||\ label(S\_{1}.next)\ ||\ S\_{2}.code
\end{array}\\]


### 布尔表达式的控制流翻译 {#布尔表达式的控制流翻译}

我们需要针对布尔表达式生成相应的 SDD，将其翻译为三地址码，
\\[\begin{array}{llll}
B &\rightarrow{} B\_{1}\ ||\ B\_{2}          & B\_{1}.true  &= B.true\\\\
  &                              & B\_{1}.false &= newlabel()\\\\
  &                              & B\_{2}.true  &= B.true\\\\
  &                              & B\_{2}.false &= B\_{1}.false\\\\
  &                              & B.code      &= B\_{1}.code\ ||\ label(B\_{1}.false)\ ||\ B\_{2}.code\\\\
B &\rightarrow{} B\_{1}\ \\&\\&\ B\_{2}        & B\_{1}.true  &= newlabel()\\\\
  &                              & B\_{1}.false &= B.false\\\\
  &                              & B\_{2}.true  &= B.true\\\\
  &                              & B\_{2}.false &= B.false\\\\
  &                              & B.code      &= B\_{1}.code\ ||\ label(B\_{1}.true)\ ||\ B\_{2}.code\\\\
B &\rightarrow{} !\\,B\_{1}                  & B\_{1}.true  &= B.false\\\\
  &                              & B\_{1}.false &= B.true\\\\
  &                              & B.code      &= B\_{1}.code\\\\
B &\rightarrow{} E\_{1} \textbf{comp} E\_{2} & B.code      &= E\_{1}.code\ ||\ E\_{2}.code\\\\
  &                              &             &||\ gen('if'\ E\_{1}.addr\ \textbf{comp}.op\ E\_{2}.addr\ 'goto'\ B.true)\\\\
  &                              &             &||\ gen('goto'\ B.false)\\\\
B &\rightarrow{} \textbf{true}             & B.code      &= gen('goto'\ B.true)\\\\
B &\rightarrow{} \textbf{false}            & B.code      &= gen('goto'\ B.false)
\end{array}\\]

B 的其余产生式按照下面的方法翻译：

-   假定 B 形如 \\(B\_{1}\ ||\ B\_{2}\\)，如果 \\(B\_{1}\\) 为真，那么 B 本身为真，因此
    \\(B\_{1}.true\\) 和 \\(B.true\\) 相同；如果 \\(B\_{1}\\) 为假，那么就要对 \\(B\_{2}\\)
    求值，因此将 \\(B\_{1}.false\\) 设置为 \\(B\_{2}\\) 的代码标号。此时 \\(B\_{2}\\) 的出口等于 B 的出口
-   \\(B\_{1}\ \\&\\&\ B\_{2}\\) 类似于上一项
-   不需要为 \\(B\rightarrow{}!\\,B\_{1}\\) 产生新代码，只需要将 B 的真假出口对换
-   将常量 **true** 和 **false** 分别翻译为 \\(B.true\\) 和 \\(B.false\\) 的跳转指令

考虑以下语句 `if (x<100 || x>200 && x != y) x=0;`，可以生成得到如下语法
\\[\begin{aligned}
        & if\ x\ <\ 100\ \texttt{goto}\ L\_{2}\\\\
        & \textbf{goto}\ L\_{3}\\\\
L\_{3}:\quad & if\ x\ >\ 200\ \texttt{goto}\ L\_{4}\\\\
        & \textbf{goto}\ L\_{1}\\\\
L\_{4}:\quad & if\ x\ !=\ y\ \texttt{goto}\ L\_{2}\\\\
        & \textbf{goto}\ L\_{1}\\\\
L\_{2}:\quad & x\ =\ 0\\\\
L\_{1}:\quad &
\end{aligned}\\]

但是在这个生成的语句中，`goto L3` 是冗余的，下一条语句的标号就是 L3。另外，如果将 L3 和 L4 的 `if` 换为 `ifFalse`，那么还可以省去两条 `goto`，因此生成的最佳代码为
\\[\begin{aligned}
        & if\ x\ <\ 100\ \texttt{goto}\ L\_{2}\\\\
        & ifFalse\ x\ >\ 200\ \texttt{goto}\ L\_{1}\\\\
        & ifFalse\ x\ !=\ y\ \texttt{goto}\ L\_{1}\\\\
L\_{2}:\quad & x\ =\ 0\\\\
L\_{1}:\quad &
\end{aligned}\\]

有点 lisp 里 **when** (ifTrue) 和 **unless** (ifFalse) 那味了。


### 避免生成冗余的 goto 指令 {#避免生成冗余的-goto-指令}

在[布尔表达式的控制流翻译](#布尔表达式的控制流翻译)中，展示了用 ifFalse 之后，指令自然流向下一个指令，从而减少了一个跳转指令。

通常代码表达式紧跟在布尔表达式之后，通过使用一个特殊标志 `fallthrough` (直落)，修改[控制流语句](#控制流语句)和[布尔表达式的控制流翻译](#布尔表达式的控制流翻译)中介绍的 SDD，就可以使控制流从 B 直接流向
S，而不需要跳转。比如将 \\(S\rightarrow{}\textbf{if}\ (\\,B\\,)\ S\_{1}\\) 新的语义规则：
\\[\begin{aligned}
B.true &= \texttt{fallthrough}\\\\
B.false &= S\_{1}.next\ =\ S.next\\\\
S.code &= B.code\ ||\ S\_{1}.code
\end{aligned}\\]

现在尝试修改布尔表达式的语义规则，使其尽可能允许控制流直落。在 B.true 和 B.false
都是显示的标号时，也就是说都不是 `fallthrough` 时，\\(B\rightarrow{}E\_{1}\ \textbf{comp}\\
E\_{2}\\) 将产生新的语义规则。如果 B.true 是显示的标号而 B.false 是 `fallthrough`，将产生一条 `if` 指令确保条件为假时控制流可以直落；反之产生一条 `ifFalse` 指令。如果都是 `fallthrough` 将不产生任何跳转指令。新语义规则如下：

<div class="verse">

test   = E1.addr **comp**.op E2.addr<br />
s      = **if** B.true != fallthrough **and** B.false != fallthrough **then**<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;gen('if' test 'goto' B.true) || gen('goto' B.false)<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**else if** B.true != fallthrough **then** gen('if' test 'goto' B.true)<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**else if** B.false != fallthrough **then** gen('ifFalse' test 'goto' B.false)<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**else** ''<br />
B.code = E1.code || E2.code || s<br />

</div>

但是在短路运算中，会稍微不同。比如 \\(B\rightarrow{}B\_{1}\ ||\ B\_{2}\\)，如果 \\(B.true\\) 为
`fallthrough` 那么 B 为真是会直落到之后的语句。但是 \\(B\_{1}\\) 为真时会短路该表达式，必须进行转跳而跳过 \\(B\_{2}\\)，直接到达 B 的下一条指令。而 \\(B\_{1}\\) 为假时，需要由 \\(B\_{2}\\) 来决定表达式的值，因此需要保证 \\(B\_{1}.false\\) 可以正确由
\\(B\_{1}\\) 直落到 \\(B\_{2}\\)。新的语义规则如下

<div class="verse">

B1.true = **if** B.true != fallthrough **then** B.true **else** newlabel()<br />
B1.false = fallthrough<br />
B2.true = B.true<br />
B2.false = B.false<br />
B.code = **if** B.true != fallthrough **then** B1.code || B2.code<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**else** B1.code || B2.code || label(B1.true)<br />

</div>


### 布尔值与转跳代码 {#布尔值与转跳代码}

对于一个只是求值布尔表达式，而非控制流中的布尔表达式，就不能像控制流中如此实现。因此可以

-   使用两趟处理法。在构造出完整的抽象语法树后，进行深度优先遍历，依据语义计算得到相应的翻译结果
-   对语句进行一趟处理，对表达式进行两趟处理。

在布尔表达式上，可以为它们生成转跳代码，并在出口处将 true 和 false 赋值给临时变量。比如 \\(x = a < b \\&\\& c < d\\) 可以实现为
\\[\begin{aligned}
        & ifFalse\ a\ <\ b\ \texttt{goto}\ L\_{1}\\\\
        & ifFalse\ c\ <\ d\ \texttt{goto}\ L\_{1}\\\\
        & t\ =\ true\\\\
        & \texttt{goto}\ L\_{2}\\\\
L\_{1}:\quad & t\ =\ false\\\\
L\_{2}:\quad & x\ =\ t
\end{aligned}\\]


## 回填 {#回填}

回填 (backpatching) 使用转跳指令组成的列表作为综合属性，在生成转跳指令时暂时不指定转跳指令的目标，而是在确定目标标号时填充这些目标标号。同一个列表中的所有转跳指令具有相同的标号。

回填技术可以用在一趟式扫描中完成对布尔表达式或控制流语句的目标代码生成。虽然目标代码的形式与前文介绍的相同，但处理标号的方式不同。回填可以使用 B.truelist 和
B.falselist 来管理布尔表达式的转跳代码的标号。控制语句中的 S.nextlist 是用来管理下一跳的代码标号。在生成这些代码时，标号字段是尚未填写的，将这些不完整的转跳指令保存在指令列表中。

在实现上，主要由三个函数完成

-   `makelist(label)` 生成只包含转跳到 label 的指令列表
-   `merge(l1, l2)` 将两个列表合并
-   `backpatch(l, label)` 将 label 作为目标标号插入列表中的各个指令中

为布尔表达式构造自底向上分析的文法。
\\[\begin{aligned}
B &\rightarrow{} B\_{1}\\,||\\,M\\,B\_{2}\ |\ B\_{1}\\,\\&\\&\\,M\\,B\_{2}\ |\ !\\,B\_{1}\ |\ (\\,B\_{1}\\,)\ |\ E\_{1}\\,\textbf{comp}\\,E\_{2}\ |\ \textbf{true}\ |\ \textbf{false}\\\\
M &\rightarrow{} \varepsilon
\end{aligned}\\]

针对该文法，重新设计 SDT。
\\[\begin{array}{llll}
B &\rightarrow{} B\_{1}\ ||\ M\\,B\_{2}          & \\{ & backpatch(B\_{1}.falselist,\\,M.instr);\\\\
  &                                 &    & B.truelist\ =\ merge(B\_{1}.truelist,\\,B\_{2}.truelist);\\\\
  &                                 &    & B.falselist\ =\ B\_{2}.falselist;\ \ \\}\\\\
B &\rightarrow{} B\_{1}\ \\&\\&\ M\\,B\_{2}        & \\{ & backpatch(B\_{1}.truelist,\\,M.instr);\\\\
  &                                 &    & B.truelist\ =\ B\_{2}.truelist;\\\\
  &                                 &    & B.falselist\ =\ merge(B\_{1}.falselist,\\,B\_{2}.falselist);\ \ \\}\\\\
B &\rightarrow{} !\\,B\_{1}                     & \\{ & B.truelist\ =\ B\_{1}.falselist;\\\\
  &                                 &    & B.falselist\ =\ B\_{1}.truelist;\ \ \\}\\\\
B &\rightarrow{} (\\,B\_{1}\\,)                  & \\{ & B.truelist\ =\ B\_{1}.truelist;\\\\
  &                                 &    & B.falselist\ =\ B\_{1}.falselist;\ \ \\}\\\\
B &\rightarrow{} E\_{1}\ \textbf{comp}\ E\_{2}  & \\{ & B.truelist\ =\ makelist(nextinstr);\\\\
  &                                 &    & B.falselist\ =\ makelist(nextinstr + 1);\\\\
  &                                 &    & gen('if'\ E\_{1}.addr\ \textbf{comp}.op\ E\_{2}.addr\ 'goto\ \\\_');\\\\
  &                                 &    & gen('goto\ \\\_');\ \ \\}\\\\
B &\rightarrow{} \textbf{true}                & \\{ & B.truelist\ =\ makelist(nextinstr);\\\\
  &                                 &    & gen('goto\ \\\_');\ \ \\}\\\\
B &\rightarrow{} \textbf{false}               & \\{ & B.falselist\ =\ makelist(nextinstr);\\\\
  &                                 &    & gen('goto\ \\\_');\ \ \\}\\\\
M &\rightarrow{} \varepsilon                            & \\{ & M.instr\ =\ nextinstr;\ \ \\}
\end{array}\\]

控制转移语句也可以用类似的方法实现。
