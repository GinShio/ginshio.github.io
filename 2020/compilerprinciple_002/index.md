# 龙书学习笔记 02


词法分析是编译器的第一阶段，主要负责读取源程序的输入字符，将它们组成 **词素**，生成并输出一个词法单元序列，每个词法单元对应一个词素，这个词法单元序列将被语法分析器进行语法分析。除此之外，词法分析器还会过滤源程序中的注释和空白，生成错误信息与源程序的位置关联起来，有时还会进行宏扩展。

{{< figure src="/ox-hugo/lexical-analyzer-and-syntax-analyzer.svg" >}}

学习词法分析时，需要分清以下三个相关但有区别的术语

词法单元
: 由一个词法单元名和一个可选的属性值组成，词法单元名是一个表示某种词法单位的抽象符号，比如关键字，或标识符的输入字符序列

词素
: 源程序中的字符序列，它和某一词法单元的模式匹配，并被词法分析器识别为该词法单元的一个实例

模式
: 描述了一个词法单元的词素可能具有的形式。对于关键词它是组成关键字的字符序列；对于标识符和其他词法单元，模式是一个更加复杂的结构，可以和很多符号串匹配

比如 `printf("Total=%d\n"，source);` 中，printf 和 source 都是和词法单元 id 的模式匹配的词素，而字符串则是一个和 literal 匹配的词素，以下表格为词法单元的示例

| 词法单元   | 非正式描述     | 词素示例       |
|--------|-----------|------------|
| if         | 关键字，字符 i/f | if             |
| else       | 关键字，字符 e/l/s/e | else           |
| comparison | 比较运算符     | &lt;，&lt;=    |
| id         | 普通标识符     | pi，D2，source |
| number     | 数字常量       | 3.1415926，1024 |
| literal    | 字符串常量     | "hello world!" |


## 词法单元的规约 {#词法单元的规约}


### 串和语言 {#串和语言}

**字母表** (alphabet) 是一个有限的符号集合，符号的典型示例是包括字母、数字和标点符号，常见的字母表如 _ASCII_ 和 _Unicode_。

**串** (string) 是某个字母表中符号的一个有穷序列，串 s 的长度，表示 s 中符号出现的次数，记作 \\(|s|\\)，长度为 0 的串被称为空串，记作 \\(\varepsilon\\)。

**语言** (language) 是某个给定字母表上一个任意的可数的串的集合，此外空集
\\(\varnothing\\) 和 仅包含空串的集合都是语言。

词法分析中，最重要的语言上的运算是 `并`、`连接` 和 `闭包`。连接是将一个串附加到另一个串的后面形成新串，例如 \\(x=dog, y=house\\)，那么 x、y 的连接 \\(xy=doghouse\\)
；空串是连接运算的 **单位元**，即对于任意串 \\(s\varepsilon = \varepsilon s = s\\)。两个串的连接可以被看作乘积，那么可以定义串的指数运算： \\(s^0=\varepsilon，s^i = s^{i-1}s(i > 0)\\) 。Kleene **闭包** (closure)，记作 \\(L^{\*}\\)，即将 L 连接 0 次或多次后得到的串集；**正闭包** 与闭包基本相同，但不包括 \\(L^0\\)，也就是说，除非 \\(\varepsilon\\) 属于 L，否则 \\(\varepsilon \notin L\\)。

| 运算          | 定义和表示                                            |
|-------------|--------------------------------------------------|
| L 和 M 的并   | \\(L \cup M = \\{s \mid  s \in L \ or\  s \in M\\}\\) |
| L 和 M 的连接 | \\(LM = \\{st \mid s \in L \ and\  t \in M\\}\\)      |
| L 的 Kleene 闭包 | \\(L^{\*} = \cup\_{i=0}^{\infty} L^i\\)               |
| L 的正闭包    | \\(L^{+} = \cup\_{i=1}^{\infty} L^i\\)                |

<div class="info">

令 L = {A, B, \\(\ldots\\), Z, a, b, \\(\ldots\\), z}，令 D = {0, 1, \\(\ldots\\), 9}，这是两个字母表，也可以认为是两个串长都为 1 的语言，对他们进行上述 4 种运算

1.  \\(L \cup D\\) 是字母和数字的集合，结果是 62 个长度为 1 的串
2.  \\(LD\\) 是包含 520 个长度为 2 的集合，每个串都是一个字母跟一个数字
3.  \\(L^4\\) 是由四个字母构成的串的集合
4.  \\(L^{\*}\\) 是由字母构成的串的集合，包含空串 \\(\varepsilon\\)
5.  \\(D^{+}\\) 是由一个或多个数字构成的串的集合，不包含空串

</div>


### 正则表达式 {#正则表达式}

正则表达式由常量和运算构成，它们分别是字符串的集合和在这些集合上的运算，正则表达式可以由较小的正则表达式按照一定规则递归地构建。

1.  **归纳基础**
    1.  \\(\varepsilon\\) 是一个正则表达式， \\(L(\varepsilon) = \\{\varepsilon\\}\\)，即该语言仅包含空串
    2.  如果 a 是 \\(\Sigma\\) 上的一个符号，那么 **a** 是一个正则表达式，并且
        \\(L(\textbf{a}) = \\{a\\}\\) ，即该语言仅包含一个长度为 1 的字符串 a
2.  **归纳步骤**：假定 r 和 s 都是正则表达式，分别表示语言 \\(L( r)\\) 和 \\(L(s)\\) ，那么
    1.  \\(( r)|(s)\\) 是一个正则表达式，表示语言 \\(L( r) \cup L(s)\\)
    2.  \\(( r)(s)\\) 是一个正则表达式，表示语言 \\(L( r)L(s)\\)
    3.  \\(( r)^{\*}\\) 是一个正则表达式，表示语言 \\((L( r))^{\*}\\)
    4.  \\(( r)\\) 是一个正则表达式，表示语言 \\(L( r)\\)

按照以上定义，正则表达式经常会包含一些不必要的括号，一般正则表达式有如下优先级

1.  一元运算符 \\(\*\\) 具有最高优先级，是左结合的
2.  连接具有次高优先级，是左结合的
3.  \\(|\\) 优先级最低，是左结合的

以下表格列出正则表达式中常用定律

| 定律                                                     | 描述                      |
|--------------------------------------------------------|-------------------------|
| \\(r\mid s = s\mid r\\)                                  | \\(\mid\\) 满足交换律     |
| \\(r\mid(s \mid t) = (r \mid s) \mid t\\)                | \\(\mid\\) 满足结合律     |
| \\(r(st) = (rs)t\\)                                      | 连接满足结合律            |
| \\(r(s \mid t) = rs \mid rt; (s \mid t)r = sr \mid tr\\) | 连接对 \\(\mid\\) 满足分配率 |
| \\(\varepsilon r = r\varepsilon = r\\)                   | \\(\varepsilon\\) 是连接的单位元 |
| \\(r^{\*} = (r\mid\varepsilon)^{\*}\\)                   | Kleene 闭包中一定包含 ε   |
| \\(r^{\*\*} = r^{\*}\\)                                  | \\(\*\\) 具有幂等性       |


### 正则定义 {#正则定义}

如果 \\(\Sigma\\) 是 `基本符号集`，那么一个 **正则定义** (regular definition) 是具有如下形式的定义序列

\\[ \begin{aligned} d\_1 \rightarrow r\_1 \\\ d\_2 \rightarrow r\_2 \\\ \dots \\\ d\_n \rightarrow r\_n \end{aligned} \\]

-   每个 \\(d\_i\\) 都是一个新符号，它们都不在 \\(\Sigma\\) 中，并且各不相同
-   每个 \\(r\_i\\) 是字母表 \\(\Sigma \cup \\{d\_1，d\_2，\ldots，d\_n\\}\\) 上的正则表达式

C 语言的标识符是由字母或下划线开头，字母、数字和下划线组成的串，正则定义如下
\\[ \begin{aligned}
\textit{letter}\\\_ & \rightarrow A | B | \ldots | Z | a | b | \ldots | z | \\\_ \\\ \textit{digit} & \rightarrow 0 | 1 | \ldots | 9 \\\ \textit{id} & \rightarrow \textit{letter\\\_}(\textit{letter\\\_}|dight)^{\*}
\end{aligned} \\]

在进行词法分析器的规约时，现有的正则定义太过于麻烦，于是对其做了一些扩展，当然除了以下介绍的 _GNU_、_Perl_ 等都有互不兼容的正则表达式扩展

-   一个或多个实例 (+)，表示一个正则表达式及其语言的正闭包，_+_ 与 _\*_ 具有相同的优先级与结合性
-   零个或一个实例 (?)，表示一个正则表达式及其语言出现零或一次，\\(r? = r|\varepsilon\\)，_?_
    与 _\*_ 具有相同的优先级与结合性
-   字符类，一个正则表达式 \\(a\_1 | a\_2 | \ldots | a\_n\\) 可以缩写为 \\([a\_1a\_2\ldots a\_n]\\)，如果 \\(a\_1\\) 到 \\(a\_n\\) 是连接的序列时可以缩写为 \\([a\_1-a\_n]\\)

C 语言的数字字面量可以分为 [整型字面量](https://zh.cppreference.com/w/cpp/language/integer_literal) 与 [浮点型字面量](https://zh.cppreference.com/w/cpp/language/floating_literal)，以下给出它们的正则定义
\\[ \begin{aligned}
\textit{digit}&\rightarrow [0-9] \\\ \textit{digits}&\rightarrow digit^{+} \\\ \textit{number}&\rightarrow [+-\]\(\textit{digits}.?\textit{digit}^{\*}|.\textit{digits})([eE][+-]?\textit{digits})?
\end{aligned} \\]


## 状态转换图 {#状态转换图}

将模式首先需要转换为具有特定风格的流图，我们称为 **状态转化图** (transition
diagram)，它有一组被称为 `状态` (state) 的结点，词法分析器扫描输入串的过程中寻找和某个模式匹配的词素，状态图上的每个状态代表一个可能在过程中出现的情况，结点包含了我们在进行词法分析时需要的全部信息。状态图的 `边` (edge) 从图的一个状态指向另一个状态，每条边的标号包含了一个或多个符号。例如我们现在处于状态 s 下，下一个输入的符号为 a，那么我们就会在状态图中寻找一条从 s 离开且符号为 a 的边，并进入这条边所指向的下一个状态。关于状态转移图的重要约定如下

1.  某些状态被称为 **接受状态** 或 **最终状态**，在图中用双层圈表示，如果该状态要执行一个动作，通常是向语法分析器返回一个词法单元和相关属性值
2.  如果要回退一个位置，我们一般在该状态上加一个 `*`，如果要回退多个位置则需要加相应数量的 `*`
3.  一个状态被称为 **开始状态** 或 **初始状态**，该状态由一条没有出发结点的、标号为
    _start_ 的边指明，在读入任何符号之前，状态图总是位于它的起始状态

我们用 SQL 中的关系运算符来举个例子

| 词素     | 词法单元名 | 属性值 |
|--------|-------|-----|
| &lt;     | relop | LT  |
| &lt;=    | relop | LE  |
| =        | relop | EQ  |
| &lt;&gt; | relop | NE  |
| &gt;     | relop | GT  |
| &gt;=    | relop | GE  |

{{< figure src="/ox-hugo/relop-transition-diagram.svg" >}}

对于符号来说很简单，但对于关键字来说，它们是被保留的，但它们看起来很像标识符，因此我们常常使用两种方法来处理长的很像标识符的关键字

1.  初始化时将各个保留字填入符号表，符号表中的某个字段会指明这些串并非普通的标识符，并指出它们所代表的词法单元
2.  为每个保留字建立单独的状态转换图，并设立词法单元的优先级，当同时匹配关键字模式与 id 模式时优先识别保留字的词法单元


## 有穷自动机 {#有穷自动机}

一些词法分析其生成程序使用了 **有穷自动机** (finite automata) 这种表示方式，其在本质上是与状态转换图类似的图，但有如下不同

-   有穷自动机不是识别器，它们只能对每个可能输入的串进行简单的回答是或否
-   分为两类
    1.  **不确定有穷自动机** (Nondeterministic Finite Automata，NFA)，它们对其边上的标号没有任何限制，一个符号标记离开同一状态的多条边，并且空串也可以作为标记
    2.  **确定有穷自动机** (Deterministic Finite Automata，DFA)，对于每个状态及自动机输入字母表的每个符号，有且只有一条离开的状态、以该符号为标点的边

确定与不确定的有穷自动机能识别的语言的集合是相同的，这些语言集合正好是能够用正则表达式描述的语言的集合，这个集合中的语言被称为 **正则语言** (regular language)。


### 不确定的有穷状态机 {#不确定的有穷状态机}

首先，一个 NFA 由以下几部分组成

1.  一个有穷的状态集合 \\(S\\)
2.  一个输入符号集 \\(\Sigma\\) ，即输入字母表，我们假设 \\(\varepsilon \notin \Sigma\\)
3.  一个 `转换函数` (transition function)，它为每个状态和 \\(\Sigma \cup \\{\varepsilon\\}\\) 中的每个符号都给出了相应的 `后续状态` (next state) 的集合
4.  \\(S\\) 中一个状态 \\(s\_0\\) 被指定为初始状态
5.  \\(S\\) 中一个子集 \\(F\\) 被指定为接受状态集合

我们可以将 NFA 表示为一个转换图，图中的结点是状态，带有标号的边表示自动机的转换函数，这个图与转台转换图十分相似，但还是有一些区别的

-   同一个符号可以标记从同一状态出发到达多个目标状态的多条边
-   一条边的符号不仅可以是输入字母表中的符号，也可以是空串

{{< figure src="/ox-hugo/NFA-example.svg" >}}

除了转换图，我们也可以将 NFA 表示为一张转换表，表的各行对应与状态，各列对应于输入符号和 \\(\varepsilon\\) 。对应于一个给定状态和给定输出的条目是将 NFA 的转换函数应用于这些参数后得到的值，如果转换函数没有没有相关信息，那么我们就将 \\(\emptyset\\) 填入相应的位置。如下表就是上图的转换表形式

| 状态 | a               | b               | \\(\varepsilon\\) |
|----|-----------------|-----------------|-------------------|
| 0  | {0, 1}          | {0}             | \\(\emptyset\\)   |
| 1  | \\(\emptyset\\) | {2}             | \\(\emptyset\\)   |
| 2  | \\(\emptyset\\) | {3}             | \\(\emptyset\\)   |
| 3  | \\(\emptyset\\) | \\(\emptyset\\) | \\(\emptyset\\)   |

在转换表上，我们可以很容易确定，一个给定状态和一个输入符号相对应的转换；但是如果输入字母表很大，且大多数状态在大多数输入字符上没有转换时，转换表需要占用大量的空间


### 确定的有穷状态机 {#确定的有穷状态机}

DFA 是 NFA 的一个特例，主要体现在

1.  没有输入 \\(\varepsilon\\) 之上的转换动作
2.  对每个状态 s 和每个输入符号 a，有且只有一条标号为 a 的边离开 s

NFA 抽象地表示了用来识别某个语言中的串的算法，DFA 则是一个简单具体的识别串的算法，在构造词法分析器的时候我们使用的是 DFA。


### 从正则表达式构造NFA {#从正则表达式构造nfa}

现在我们给出一个算法，将任何正则表达式转换为接受相同语言的NFA，这个算法是 **语法制导** 的，对于每个子表达式该算法构造一个只有一个接受状态的NFA。

<div class="info">

输入：字母表 \\(\Sigma\\) 上的一个正则表达式 r

输出：一个接受 L(r) 的 NFA N

方法：首先对r进行语法分析，分解出组成它的子表达式。构造一个NFA的规则分为 **基本规则** 和 **归纳规则** 。基本规则处理不包含运算符的子表达式，而归纳规则根据一个给定的表达式的直接子表达式的NFA构造出这个表达式的NFA

</div>

基本规则
: 构造NFA，其中 i 是一个新状态，也是这个NFA的开始状态；f 是另一个新状态，也是这个NFA的接受状态。对于表达式 \\(\varepsilon\\) 以及字母表 \\(\Sigma\\) 中的子表达式 a，构造以下 NFA

    {{< figure src="/ox-hugo/reg2NFA-basicrules.svg" >}}


归纳规则
: 假设正则表达式 s 和 t 的 NFA 分别为 N(s) 和 N(t)，表达式 r 的 NFA 为 N(r)
    1.  假设 `r = s|t`，构造 N(r)，可以得到从 i 到 N(s) 或 N(t) 的开始状态各有一个
        \\(\varepsilon\\) 转换，从 N(s) 和 N(t) 的接受状态到 f 也各有一个 \\(\varepsilon\\) 转换。因为从 i 到 f
        的任何路径要么只通过 N(s)，要么只通过 N(t)，且离开 i 或进入 f 的 \\(\varepsilon\\) 转换都不会改变路径上的标号，因此我们可以判定 N(r) 识别 \\(L(s) \cup L(t)\\)，即 \\(L( r)\\)
        ![](/ox-hugo/reg2NFA-inductiverules-or.svg)
    2.  假设 `r = st` ，构造 N(r)，N(s) 的开始状态变为了 N(r) 的开始状态，N(t) 的接受状态变成了 N(r) 唯一接受状态，N(s) 的接受状态和 N(t) 的开始状态合并为一个状态，合并后的状态拥有原来进入和离开合并前的两个状态的全部转换。
        ![](/ox-hugo/reg2NFA-inductiverules-and.svg)
    3.  假设 r = \\(s^{\*}\\)，构造 N(r)，i 和 f 是两个新状态，分别为 N(r) 的开始状态和唯一的接受状态。要从i到达f我们需要沿着新引入的标号为 \\(\varepsilon\\) 的路径前进，这个路径对应 \\(L(s)^{0}\\) 中的一个串。我们也可以到达 N(s) 的开始状态，然后经过该
        NFA，在零次或多次从它的接受状态回到它的开始状态并重复上述过程。
        ![](/ox-hugo/reg2NFA-inductiverules-closure.svg)
    4.  `r = (s)` ，那么 L(r) = L(s)，我们可以直接把 N(s) 当作 N(r)。

N(r) 接受语言 L(r) 之外，构造得到的 NFA 还具有以下性质:

-   N(r) 的状态数最多为 r 中出现的 `运算符` 和 `运算分量` 的总数的 **2倍**，因为算法的每一个构造步骤最多只引入两个新状态
-   N(r) 有且只有一个开始状态和一个接受状态
-   N(r) 中除接受状态之外的每个状态要么有一条其标号为 \\(\Sigma\\) 中符号的出边，要么有两条标号为 \\(\varepsilon\\) 的出边


### NFA 到 DFA {#nfa-到-dfa}

我们需要将 NFA 转换为 DFA，一般采用 **子集构造法** 直接模拟 NFA。子集构造法的基本思想是让构造得到的 DFA 的每个状态对应于 NFA 的一个状态集合。DFA 的状态数有可能是
NFA 状态数的指数，不过对于真实的语言，NFA 与 DFA 的状态数量大致相同。

<div class="info">

输入：一个 NFA N

输出：一个接受同样语言的 DFA D

方法：我们为 D 构造一个转换表 `Dtran`。D的每个状态是一个 NFA 的状态集，我们构造 Dtran 使得 D 并行的模拟 N 在遇到一个给定输入串时可能执行的所有动作。在读入第一个输入符号之前，N 位于 \\(\varepsilon-closure(s\_0)\\) 中的任何状态上。假定 N 在读入字符串 x 后位于集合 T 的状态上，那么下一个输入符号 a，N 可以移动到集合 \\(move(T，
  a)\\) 中的任何状态。

</div>

\\(\scriptsize \varepsilon-closure(s)\\)
: 从 NFA 的状态 s 开始只通过 \\(\varepsilon\\) 转换到达的 NFA 状态集合

\\(\scriptsize \varepsilon-closure(T)\\)
: 从 T 中某个 NFA 状态 s 开始只通过 \\(\varepsilon\\) 转换到达的 NFA 状态集合，即 \\(\cup\_{s \in T}
       \varepsilon-closure(s)\\)

\\(move(T,a)\\)
: 从 T 中某个状态 s 出发通过标号 a 的转换到达的 NFA 状态的集合

简单的说，NFA 中起始状态与起始状态经过 \\(\varepsilon\\) 转换后所到达的所有状态，这些状态所组成的集合就是转换成 DFA 的起始状态，而这个集合中的所有状态分别经过某一路径转换和转换后再经过 \\(\varepsilon\\) 转换的状态组成了另一个 DFA 状态，以此下去构成了所有 DFA 中的所有状态

{{< figure src="/ox-hugo/NFA2DFA.svg" >}}

我们继续以上图 \\((a|b)^{\*}abb\\) 为例进行从 NFA 到 DFA 的装换，起始状态 A 为
\\(\varepsilon-closure(0)\\)，即 \\(A=\\{0，1，2，4，7\\}\\)，而输入字母表为 \\(\\{a，b\\}\\)，那么接下来分别计算 \\(Dtran[A，a] = \varepsilon-closure(move(A,a))\\) 以及 \\(Dtran[A，b] =
\varepsilon-closure(move(A,b))\\) 分别得到 DFA 的状态 B 与状态 C，最终依次计算，我们会得到一张 NFA 与 DFA 对应关系表 (下表)，这样就可能很轻松的完成 NFA 向 DFA 的转换

| DFA 状态 | NFA 状态集       | 经过 a 转换得到的状态 | 经过 b 转换得到的状态 |
|--------|---------------|--------------|--------------|
| A      | {0,1,2,4,7}      | B            | C            |
| B      | {1,2,3,4,6,7,8}  | B            | D            |
| C      | {1,2,4,5,6,7}    | B            | C            |
| D      | {1,2,4,5,6,7,9}  | B            | E            |
| E      | {1,2,4,5,6,7,10} | B            | C            |

<style>
div.info{background:rgba(58,129,195,0.15);border-left:4px solid rgba(58,129,195,0.45);margin:1.8rem 0 1.25rem 15px;padding:0.8em;line-height:1.4;text-align:left;position:relative;clear:both}div.info p{margin:0}div.info::before{content:"i";background:rgba(58,129,195,0.8);align-items:flex-end;top:-1rem;font-weight:700;font-size:1.4rem;-webkit-clip-path:circle(50% at 50% 50%);clip-path:circle(50% at 50% 50%);width:30px;height:30px;display:inline-flex;justify-content:center;position:absolute;left:-1.2rem;line-height:1.3;text-align:left}div.success{background:rgba(45,149,116,0.15);border-left:4px solid rgba(45,149,116,0.45);margin:1.8rem 0 1.25rem 15px;padding:0.8em;line-height:1.4;text-align:left;position:relative;clear:both}div.success p{margin:0}div.success::before{content:"✔";background:rgba(45,149,116,0.8);align-items:flex-end;top:-1rem;font-weight:700;font-size:1.4rem;-webkit-clip-path:polygon(50% 0%, 100% 50%, 50% 100%, 0% 50%);clip-path:polygon(50% 0%, 100% 50%, 50% 100%, 0% 50%);width:35px;height:35px;display:inline-flex;justify-content:center;position:absolute;left:-1.2rem;line-height:1.5;text-align:left}div.warning{background:rgba(220,117,47,0.15);border-left:4px solid rgba(220,117,47,0.45);margin:1.8rem 0 1.25rem 15px;padding:0.8em;line-height:1.4;text-align:left;position:relative;clear:both}div.warning p{margin:0}div.warning::before{content:"!";background:rgba(220,117,47,0.8);align-items:flex-end;top:-1rem;font-weight:700;font-size:1.4rem;-webkit-clip-path:polygon(50% 0, 0 100%, 100% 100%);clip-path:polygon(50% 0, 0 100%, 100% 100%);width:35px;height:35px;display:inline-flex;justify-content:center;position:absolute;left:-1.2rem;line-height:1.1;text-align:left}div.error{background:rgba(186,47,89,0.15);border-left:4px solid rgba(186,47,89,0.45);margin:1.8rem 0 1.25rem 15px;padding:0.8em;line-height:1.4;text-align:left;position:relative;clear:both}div.error p{margin:0}div.error::before{content:"!";background:rgba(186,47,89,0.8);align-items:flex-end;top:-1rem;font-weight:700;font-size:1.4rem;-webkit-clip-path:polygon(25% 0%, 75% 0%, 100% 50%, 75% 100%, 25% 100%, 0% 50%);clip-path:polygon(25% 0%, 75% 0%, 100% 50%, 75% 100%, 25% 100%, 0% 50%);width:35px;height:30px;display:inline-flex;justify-content:center;position:absolute;left:-1.2rem;line-height:1.1;text-align:left}
</style>

