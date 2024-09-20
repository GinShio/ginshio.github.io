# 语法分析 2


自顶向下语法可以被看作输入串构造语法分析树的问题，从语法分析树的根结点开始，深度优先创建这棵树的各个结点。

对于输入 **id** `+` **id** `*` **id**，可以根据最左推导序列产生语法分析树序列：
\\[\begin{aligned}
E &\rightarrow TE^{'}\\\\
E^{'} &\rightarrow +\ T\ E^{'}\\,|\\,\varepsilon\\\\
T &\rightarrow FT^{'}\\\\
T^{'} &\rightarrow \*\ F\ T^{'}\\,|\\,\varepsilon\\\\
F &\rightarrow (\ E\ )\\,|\\,\textbf{id}\\\\
\end{aligned}\\]

根据左推导有如下自顶向下分析过程

{{< figure src="/images/compiler_principle-id-plus-id-multi-id-example-lm-top-down.svg" >}}


## 递归下降的语法分析 {#递归下降的语法分析}

递归下降的语法分析由一组过程组成，每个非终结符有一个对应的过程，程序的执行从开始符号对应的过程开始，如果这个过程扫描了整个输入串，就停止执行并宣布语法分析完成。

通用递归下降分析技术可能需要回溯，即重复扫描输入串。在 PL 构造进行语法分析时很少回溯，因此需要回溯的语法分析器并不常见。自然语言分析的场合，回溯也不高效，因此更加倾向基于表格的语法分析方法，如 DP 或 Earley 方法。


### 一个简单的示例 {#一个简单的示例}

考虑文法 \\[\begin{aligned} S &\rightarrow c\\,A\\,d\\\ A &\rightarrow a\\,b \ |\ a\\\ \end{aligned}\\]
自顶向下构造串 \\(w=cad\\)，初始结点指向 w 的第一个字符，即标号为 S 的结点指向 c，将会得到图 [1](#figure--fig:top-down-parsing-process-example) (a) 中的树，字符c 匹配。

<a id="figure--fig:top-down-parsing-process-example"></a>

{{< figure src="/images/compiler_principle-top-down-parsing-process-example.svg" caption="<span class=\"figure-number\">Figure 1: </span>自顶向下语法分析器过程" >}}

将 _A_ 用 \\(\textit{A} \rightarrow ab\\) 展开得到图
[1](#figure--fig:top-down-parsing-process-example) (b) 的树，第二个字符 a 匹配，此时指针推进到第三个字符 d。由于 b 与 d 不匹配，将报告失败，并回到 A 开始尝试之前未进行的且有可能匹配的其他产生式，图 [1](#figure--fig:top-down-parsing-process-example) (c) 所示。

左递归的文法会让递归下降语法分析器陷入死循环，即使有回溯也是如此。


### FIRST 与 FOLLOW {#first-与-follow}

自顶向下的语法分析器构造都可以采用 FIRST 和 FOLLOW 来实现。这两个函数让我们可以根据下一个输入符来选择如何应用产生式。而 painc 恢复可以由 FOLLOW 产生的词法单元合集作为同步词法单元。

\\(\texttt{FIRST}(\alpha)\\) 被定义为可以从 \\(\alpha\\) 推导得到的串的首符号集合。如果 \\(\alpha
\xRightarrow{\*}\varepsilon\\)，那么 \\(\varepsilon\\) 也在 \\(\texttt{FIRST}(\alpha)\\) 中。在之前的示例中，就是 \\(\textit{A} \xRightarrow{\*} c\gamma\\)，因此 \\(c\\) 在 \\(\texttt{FIRST}(\alpha)\\) 中，如图 [2](#figure--fig:top-down-parsing-process-example-follow-and-first) 所示。

<a id="figure--fig:top-down-parsing-process-example-follow-and-first"></a>

{{< figure src="/images/compiler_principle-top-down-parsing-process-example-follow-and-first.svg" caption="<span class=\"figure-number\">Figure 2: </span>终结符 c 在 `FIRST`(_A_) 中且 a 在 `FOLLOW`(_A_) 中" >}}

考虑两个 A 的产生式 \\(\textit{A} \rightarrow \alpha\\,|\\,\beta\\)，其中 \\(\texttt{FIRST}(\alpha)\\) 和
\\(\texttt{FIRST}(\beta)\\) 是不相交的集合。那么只需要查看下一个输入符号 a 就可以选择产生式。因为 a 只能出现在 \\(\texttt{FIRST}(\alpha)\\) 或 \\(\texttt{FIRST}(\beta)\\) 中，但不能同时出现在两个集合中。

对于非终结符 _A_，\\(\texttt{FOLLOW}(\textit{A})\\) 被定义为可能在某些句型中紧跟在
_A_ 右边的终结符的集合。如图
[2](#figure--fig:top-down-parsing-process-example-follow-and-first) 所示
\\(\textit{S}\xRightarrow{\*}\alpha\textit{A}a\beta\\) 的推导，\\(\alpha\\) 和 \\(\beta\\) 是文法符号串，终结符 a 在 \\(\texttt{FOLLOW}(\textit{A})\\) 中。


### 计算 FIRST {#计算-first}

计算各个文法符号 _X_ 的 \\(\texttt{FRIST}(\textit{X})\\) 时，不断应用以下规则，直到没有新的终结符或 \\(\varepsilon\\) 可以被加入。

1.  如果 _X_ 是一个终结符，那么 \\(\texttt{FIRST}(\textit{X})=\textit{X}\\)
2.  如果 _X_ 是一个非终结符，且 \\(\textit{X} \rightarrow
         \textit{Y}\_{1}\textit{Y}\_{2}\cdots\textit{Y}\_{k} (k \ge 1)\\) 是一个产生式
    1.  如果对于某个 i，a 在\\(\texttt{FIRST}(\textit{Y}\_{i})\\) 中且 \\(\varepsilon\\) 在所有的 \\(\texttt{FIRST}(\textit{Y}\_{1})\\)、
        \\(\texttt{FIRST}(\textit{Y}\_{2})\\)、\\(\cdots\\)、
        \\(\texttt{FIRST}(\textit{Y}\_{i-1})\\) 中，那么就把 a 加入到
        \\(\texttt{FIRST}(\textit{X})\\) 中，即
        \\(\textit{Y}\_{1}\cdots\textit{Y}\_{i-1}\xRightarrow{\*}\varepsilon\\)
    2.  如果对于所有的 \\(j=1, 2, \cdots, k\\)，\\(\varepsilon\\) 在
        \\(\texttt{FIRST}(\textit{Y}\_{j})\\) 中，那么将 \\(\varepsilon\\) 加入到
        \\(\texttt{FIRST}(\textit{X})\\) 中。
    3.  如果 \\(\textit{Y}\_{1}\\) 不能推导出 \\(\varepsilon\\)，那么我们就不再向
        \\(\texttt{FIRST}(\textit{X})\\) 中加入任何符号，但如果
        \\(\textit{Y}\_{1}\xRightarrow{\*}\varepsilon\\)，就加上
        \\(\texttt{FIRST}(\textit{Y}\_{2})\\)，依此类推。
3.  如果 \\(\textit{X}\rightarrow\varepsilon\\) 是一个产生式，那么将 \\(\varepsilon\\) 加入到
    \\(\texttt{FIRST}(\textit{X})\\) 中

简单地说，计算任何串 \\(\textit{X}\_{1}\textit{X}\_{2}\cdots\textit{X}\_{n}\\) 的 `FIRST`
集合：向 \\(\texttt{FIRST}(\textit{X}\_{1}\textit{X}\_{2}\cdots\textit{X}\_{n})\\) 加入
\\(\texttt{FIRST}(\textit{X}\_{1})\\) 的所有非 \\(\varepsilon\\) 运算符，如果 \\(\varepsilon\\) 在
\\(\texttt{FIRST}(\textit{X}\_{1})\\) 中，那么加入
\\(\texttt{FIRST}(\textit{X}\_{2})\\) 的所有非 \\(\varepsilon\\) 运算符，如果 \\(\varepsilon\\) 在
\\(\texttt{FIRST}(\textit{X}\_{1})\\) 和 \\(\texttt{FIRST}(\textit{X}\_{2})\\) 中则加入 \\(\texttt{FIRST}(\textit{X}\_{3})\\) 的所有非 \\(\varepsilon\\) 运算符，依此类推。


### 计算 FOLLOW {#计算-follow}

计算各个文法符号 _X_ 的 \\(\texttt{FRIST}(\textit{X})\\) 时，不断应用以下规则，直到没有新的终结符可以被加入。

1.  将 `$` 放到 \\(\texttt{FOLLOW}(\textit{S})\\) 中，其中 _S_ 是开始符号，而 `$`
    是输入右端的结束符号
2.  如果存在一个产生式 \\(\textit{A}\rightarrow\alpha\textit{B}\beta\\)，那么 \\(\texttt{FIRST}(\beta)\\)
    中除 \\(\varepsilon\\) 外的所有符号都在 \\(\texttt{FOLLOW}(\textit{B})\\) 中
3.  如果存在一个产生式 \\(\textit{A}\rightarrow\alpha\textit{B}\\)，或存在产生式
    \\(\textit{A}\rightarrow\alpha\textit{B}\beta\\) 且 \\(\texttt{FIRST}(\beta)\\) 包含 \\(\varepsilon\\)，那么
    \\(\texttt{FOLLOW}(\textit{A})\\) 中的所有符号都在
    \\(\texttt{FOLLOW}(\textit{B})\\) 中。


### 示例的 FIRST 和 FOLLOW 计算 {#示例的-first-和-follow-计算}

对于示例 **id** `+` **id** `*` **id**，我们可以如此计算 FIRST 与 FOLLOW。

1.  \\(\texttt{FIRST}(\textit{F})\ =\ \texttt{FIRST}(\textit{T})\ =\\
         \texttt{FIRST}(\textit{E})\ =\ \\{(,\textbf{id}\\}\\)。_F_ 的产生式以终结符
    **id** 和左括号开头；_T_ 只有 _F_ 开头的产生式，_F_ 不能推出 \\(\varepsilon\\)，因此
    \\(\texttt{FIRST}(\textit{T})\\) 与 \\(\texttt{FIRST}(\textit{F})\\) 必然相同；对 \\(\texttt{FIRST}(\textit{E})\\) 论据相同。
2.  \\(\texttt{FIRST}(\textit{E}^{'}) = \\{+, \varepsilon\\}\\)。\\(\textit{E}^{'}\\) 的两个产生式中，一个以 \\(+\\) 开头，而另一个为 \\(\varepsilon\\)。只要有一个 \\(\varepsilon\\) 我们就将其加入 `FIRST` 中。
3.  \\(\texttt{FIRST}(\textit{T}^{'}) = \\{\*, \varepsilon\\}\\)。论据同 2。
4.  \\(\texttt{FOLLOW}(\textit{E}) = \texttt{FOLLOW}(\textit{E}^{'}) = \\{), \\$\\}\\)。因为 _E_ 是开始符号，因此 \\(\texttt{FOLLOW(\textit{E})}\\) 一定包含 \\(\\$\\)。产生式 _(E)_ 说明了右括号为什么在 `FOLLOW` 当中。对于 \\(\textit{E}^{'}\\)，非终结符只出现在了 _E_ 产生式的尾部，因此 \\(\texttt{FOLLOW}(\textit{E})\\) 必然与
    \\(\texttt{FOLLOW}(\textit{E}^{'})\\) 相同。
5.  \\(\texttt{FOLLOW}(\textit{T}) = \texttt{FOLLOW}(\textit{T}^{'}) = \\{+, ),
         \\$\\}\\)。在所有产生式体中 _T_ 只有 \\(\textit{E}^{'}\\) 跟在后面，因此
    \\(\texttt{FIRST}(\textit{E}^{'})\\) 中除 \\(\varepsilon\\) 外所有符号都在
    \\(\texttt{FOLLOW}(\textit{T})\\) 中。另外 \\(\texttt{FIRST}(\textit{E}^{'})\\)
    包含 \\(\varepsilon\\) (即 \\(\textit{E}^{'} \xRightarrow[lm]{} \varepsilon\\))，且 _E_ 产生体中
    \\(\textit{E}^{'}\\) 跟在 _T_ 之后，因此 \\(\texttt{FOLLOW}(\textit{E})\\) 中的所有符号出现在 \\(\texttt{FOLLOW}(\textit{T})\\) 中。而 \\(\textit{T}^{'}\\) 只出现在 _T_ 产生式的末尾，因此 \\(\texttt{FOLLOW}(\textit{T}) =
         \texttt{FOLLOW}(\textit{T}^{'})\\)
6.  \\(\texttt{FOLLOW}(\textit{F}) = \\{+, \*, ), \\$\\}\\)。论据同 5。


## LL(1) 文法 {#ll--1--文法}

LL(1) 文法，表示从左向右扫描输入，产生最左推导的文法，而 `1` 表示每一步只需要向前看一个输入符号来决定语法分析动作。

LL(1) 文法我们可以构造除预测分析器，即不需要回溯的递归下降语法。但是需要注意的是，左递归文法和二义性文法都不是 LL(1) 的。


### 预测分析器的转换图 {#预测分析器的转换图}

转换图有助于将预测分析器可视化，构造一个文法的转换图，首先要消除左递归，然后对文法提取左公因子，之后对每个非终结符 A 进行：

1.  创建一个初始状态和结束状态
2.  对每个产生式 \\(\textit{A} \rightarrow \textit{X}\_{1}\textit{X}\_{2}\cdots\textit{X}\_{n}\\)
    创建一个从初始状态到结束状态的路经

预测分析器的转换图与词法分析器的转换图是不同的：分析器对每个非终结符都有图，边的标号可以是词法单元也可以是非终结符；词法分析器表示下一个输入符号输入时应该执行的转换。

{{< figure src="/images/compiler_principle-predictive-analyzer-transformation-graph-for-e-and-e-skim.svg" >}}


### LL(1) 文法判断 {#ll--1--文法判断}

当且仅当文法 G 的任意两个不同的表达式 \\(\textit{A} \rightarrow \alpha\\,|\\,\beta\\) 满足以下条件时，G
是 LL(1) 文法：

1.  不存在终结符 a 使得 \\(\alpha\\) 和 \\(\beta\\) 都能够推导出以 a 开头的串
2.  \\(\alpha\\) 和 \\(\beta\\) 中最多只有一个可以推导出空
3.  如果 \\(\beta \xRightarrow{\*} \varepsilon\\)，那么 \\(\alpha\\) 不能推导出任何以
    \\(\texttt{FOLLOW}(\textit{A})\\) 中某个终结符开头的串。反之亦然。

前两个条件说明 \\(\texttt{FIRST}(\alpha)\\) 和 \\(\texttt{FIRST}(\beta)\\) 是不相交的集合。第三个条件说明，如果 \\(\varepsilon\\) 在 \\(\texttt{FIRST}(\beta)\\) 中，那么 \\(\texttt{FIRST}(\alpha)\\)
与 \\(\texttt{FOLLOW}(\textit{A})\\) 是不相交的集合。


### 构造 LL(1) 文法预测分析表 {#构造-ll--1--文法预测分析表}

预测分析表是构造 LL(1) 文法预测分析器的重要方法。也需要用到 \\(\texttt{FIRST}\\)
和 \\(\texttt{FOLLOW}\\) 函数。

<div class="verse">

输入：文法 G<br />
输出：预测分析表 M<br />
方法：对于文法 G 每个产生式 \\(\textit{A} \rightarrow \alpha\\) 有<br />
&nbsp;&nbsp;1. 对于 \\(\texttt{FIRST}(\alpha)\\) 中的每个终结符 a，将 \\(\textit{A} \rightarrow \alpha\\) 加入到 \\(\textit{M}[\textit{A}, a]\\) 中<br />
&nbsp;&nbsp;2. 如果 \\(\varepsilon\\) 在 \\(\texttt{FIRST}(\alpha)\\) 中，那么对于 \\(\texttt{FOLLOW}(\textit{A})\\) 中的每个终结符 b，将 \\(\textit{A} \rightarrow \alpha\\) 加入到 \\(\textit{M}[\textit{A}, b]\\) 中。如果 \\(\\$\\) 也在 \\(\texttt{FOLLOW}(\textit{A})\\) 中，那也将 \\(\textit{A} \rightarrow \alpha\\) 加入到 \\(\textit{M}[\textit{A}, \\$]\\) 中<br />

</div>

对于示例 **id** `+` **id** `*` **id** 可以构造出如下分析表

| 非终结符             | **id**                                       | `+`                                                | `*`                                                 | `(`                                          | `)`                                          | `$`                                          |
|------------------|----------------------------------------------|----------------------------------------------------|-----------------------------------------------------|----------------------------------------------|----------------------------------------------|----------------------------------------------|
| _E_                  | \\(\textit{E} \rightarrow \textit{TE}^{'}\\) |                                                    |                                                     | \\(\textit{E} \rightarrow \textit{TE}^{'}\\) |                                              |                                              |
| \\(\textit{E}^{'}\\) |                                              | \\(\textit{E}^{'} \rightarrow + \textit{TE}^{'}\\) |                                                     |                                              | \\(\textit{E}^{'} \rightarrow \varepsilon\\) | \\(\textit{E}^{'} \rightarrow \varepsilon\\) |
| _T_                  | \\(\textit{T} \rightarrow \textit{FT}^{'}\\) |                                                    |                                                     | \\(\textit{T} \rightarrow \textit{FT}^{'}\\) |                                              |                                              |
| \\(\textit{T}^{'}\\) |                                              | \\(\textit{T}^{'} \rightarrow \varepsilon\\)       | \\(\textit{T}^{'} \rightarrow \* \textit{FT}^{'}\\) |                                              | \\(\textit{T}^{'} \rightarrow \varepsilon\\) | \\(\textit{T}^{'} \rightarrow \varepsilon\\) |
| _F_                  | \\(\textit{F} \rightarrow \textbf{id}\\)     |                                                    |                                                     | \\(\textit{F} \rightarrow (\textit{E})\\)    |                                              |                                              |

如果一个文法是左递归或有二义性的，那么 M 中至少会包含一个多重定义的条目。比如悬空-else 文法
\\[\begin{aligned}
\textit{S} &\rightarrow i\textit{E}t\textit{SS}^{'}\ |\ a\\\\
\textit{S}^{'} &\rightarrow e\textit{S}\ |\ \varepsilon\\\\
\textit{E} &\rightarrow b\\\\
\end{aligned}\\]

它的分析表如下

| 非终结符             | a                              | b                              | e                                                                                          | i                                                        | t | \\(\\$\\)                                    |
|------------------|--------------------------------|--------------------------------|--------------------------------------------------------------------------------------------|----------------------------------------------------------|---|----------------------------------------------|
| _S_                  | \\(\textit{S} \rightarrow a\\) |                                |                                                                                            | \\(\textit{S} \rightarrow i\textit{E}t\textit{SS}^{'}\\) |   |                                              |
| \\(\textit{S}^{'}\\) |                                |                                | \\(\textit{S}^{'} \rightarrow \varepsilon\\), \\(\textit{S}^{'} \rightarrow e\textit{S}\\) |                                                          |   | \\(\textit{S}^{'} \rightarrow \varepsilon\\) |
| _E_                  |                                | \\(\textit{E} \rightarrow b\\) |                                                                                            |                                                          |   |                                              |

可以看到 \\(\textit{M}[\textit{S}^{'}, e]\\) 不止一个条目，LL(1) 文法预测分析表会披露出文法中存在的二义性。


## 非递归的预测分析 {#非递归的预测分析}

构造递归的预测分析是隐式使用栈，可以采用迭代的方式显示使用栈，如果 w 是已匹配完成的输入部分，那么栈中保存的文法符号序列 \\(\alpha\\) 满足
\\[S \xRightarrow[lm]{\*}w\alpha.\\]

由分析表驱动的语法分析器有一个输入缓冲区，一个包含了文法符号序列的栈，一个预测分析表，以及一个输出流。

{{< figure src="/images/compiler_principle-analysis-table-driven-predictive-analyzer-model.svg" >}}

它的输入缓冲区中包含要进行语法分析的串，串后面跟着结束标记\\(\\$\\)。我们复用符号
\\(\\$\\)来标记栈底，在开始时刻栈中\\(\\$\\)的上方的开始符号S。

预测分析程序考虑栈顶符号 _X_ 和当前输入符号 a，如果 _X_ 是非终结符，查询分析表
\\(\textit{M}[\textit{X}, a]\\) 来选择一个 _X_ 的产生式；否则检查终结符 _X_ 和当前输入符 a 是否匹配。语法分析器的行为可以用配置 (configuration) 来描述，
configuration 描述了栈中的内容和余下的输入。

<div class="verse">

输入：一个串 w，文法 G 的预测分析表 _M_<br />
输出：如果 w 在 \\(\textit{L}(\textit{G})\\) 中，输出 w 的最左推导，否则输出错误提示<br />
方法：最初输入缓冲区中是 \\(w\\$\\)，而 G 开始符号 _S_ 位于栈顶，它下面是 \\(\\$\\)。<br />

</div>

算法如下：
\#+begin_verse
设置 ip (输入指针) 使其指向 w 的第一个符号;
令 _X_ 为栈顶符号;
**while** (\\(\textit{X} \ne \\$\\)) {
    **if** (_X_ == ip 指向的符号 a) {
        执行出栈操作;
        将 ip 向前移动一个位置;
    } **else if** (_X_ 是一个终结符 **or** \\(\textit{M}[\textit{X}, a]\\) 是一个报错条目) {
        error();
    } **else if** (\\(\textit{M}[\textit{X}, a] = \textit{X} \rightarrow Y\_{1}Y\_{2}\cdots Y\_{k}\\)) {
        输出产生式 \\(\textit{X} \rightarrow Y\_{1}Y\_{2}\cdots Y\_{k}\\);
        执行出栈操作;
        将 \\(Y\_{1}Y\_{2}\cdots Y\_{k}\\) 入栈，其中 \\(Y\_{1}\\) 位于栈顶;
    }
    令 _X_ 为栈顶符号;
}
\#+end_vers

在之前已经有了示例 **id** `+` **id** `*` **id** 的预测分析表了，现在展示以下其执行步骤

| 已匹配                                     | 栈                                               | 输入                                          | 操作                                                |
|-----------------------------------------|-------------------------------------------------|---------------------------------------------|---------------------------------------------------|
|                                            | \\(\textit{E}\\$\\)                              | \\(\textbf{id}+\textbf{id}\*\textbf{id}\\$\\) |                                                     |
|                                            | \\(\textit{TE}^{'}\\$\\)                         | \\(\textbf{id}+\textbf{id}\*\textbf{id}\\$\\) | 输出 \\(\textit{E}\rightarrow\textit{TE}^{'}\\)     |
|                                            | \\(\textit{FT}^{'}\textit{E}^{'}\\$\\)           | \\(\textbf{id}+\textbf{id}\*\textbf{id}\\$\\) | 输出 \\(\textit{T}\rightarrow\textit{FT}^{'}\\)     |
|                                            | \\(\textbf{id}\textit{T}^{'}\textit{E}^{'}\\$\\) | \\(\textbf{id}+\textbf{id}\*\textbf{id}\\$\\) | 输出 \\(\textit{F}\rightarrow\textbf{id}\\)         |
| **id**                                     | \\(\textit{T}^{'}\textit{E}^{'}\\$\\)            | \\(+\textbf{id}\*\textbf{id}\\$\\)            | 匹配 **id**                                         |
| **id**                                     | \\(\textit{E}^{'}\\$\\)                          | \\(+\textbf{id}\*\textbf{id}\\$\\)            | 输出 \\(\textit{T}^{'}\rightarrow\varepsilon\\)     |
| **id**                                     | \\(+\textit{TE}^{'}\\$\\)                        | \\(+\textbf{id}\*\textbf{id}\\$\\)            | 输出 \\(\textit{E}^{'}\rightarrow+\textit{TE}^{'}\\) |
| \\(\textbf{id}+\\)                         | \\(\textit{TE}^{'}\\$\\)                         | \\(\textbf{id}\*\textbf{id}\\$\\)             | 匹配 \\(+\\)                                        |
| \\(\textbf{id}+\\)                         | \\(\textit{FT}^{'}\textit{E}^{'}\\$\\)           | \\(\textbf{id}\*\textbf{id}\\$\\)             | 输出 \\(\textit{T}\rightarrow\textit{FT}^{'}\\)     |
| \\(\textbf{id}+\\)                         | \\(\textbf{id}\textit{T}^{'}\textit{E}^{'}\\$\\) | \\(\textbf{id}\*\textbf{id}\\$\\)             | 输出 \\(\textit{F}\rightarrow\textbf{id}\\)         |
| \\(\textbf{id}+\textbf{id}\\)              | \\(\textit{T}^{'}\textit{E}^{'}\\$\\)            | \\(\*\textbf{id}\\$\\)                        | 匹配 **id**                                         |
| \\(\textbf{id}+\textbf{id}\\)              | \\(\*\textit{FT}^{'}\textit{E}^{'}\\$\\)         | \\(\*\textbf{id}\\$\\)                        | 输出 \\(\textit{T}^{'}\rightarrow\*\textit{FT}^{'}\\) |
| \\(\textbf{id}+\textbf{id}\*\\)            | \\(\textit{FT}^{'}\textit{E}^{'}\\$\\)           | \\(\textbf{id}\\$\\)                          | 匹配 \\(\*\\)                                       |
| \\(\textbf{id}+\textbf{id}\*\\)            | \\(\textbf{id}\textit{T}^{'}\textit{E}^{'}\\$\\) | \\(\textbf{id}\\$\\)                          | 输出 \\(\textit{F}\rightarrow\textbf{id}\\)         |
| \\(\textbf{id}+\textbf{id}\*\textbf{id}\\) | \\(\textit{T}^{'}\textit{E}^{'}\\$\\)            | \\(\\$\\)                                     | 匹配 **id**                                         |
| \\(\textbf{id}+\textbf{id}\*\textbf{id}\\) | \\(\textit{E}^{'}\\$\\)                          | \\(\\$\\)                                     | 输出 \\(\textit{T}^{'}\rightarrow\varepsilon\\)     |
| \\(\textbf{id}+\textbf{id}\*\textbf{id}\\) | \\(\\$\\)                                        | \\(\\$\\)                                     | 输出 \\(\textit{E}^{'}\rightarrow\varepsilon\\)     |


## 预测分析中的错误恢复 {#预测分析中的错误恢复}

当栈顶的终结符和下一个输入不匹配时，或当前非终结符 _A_ 处于栈顶但
\\(\textit{M}[\textit{A}, a]\\) 为 **error** 时，预测分析器就会检测到语法错误。


### panic 模式 {#panic-模式}

panic 模式的错误恢复是基于以下思想：语法分析器忽略输入中的一些符号，直到输入中出现同步词法单元。这依赖于同步集合的选取。选取原则是使得语法分析器能够从实践中可能遇到的错误中快速恢复。有一些启发式的规则：

1.  将 \\(\texttt{FOLLOW}(\textit{A})\\) 中的所有符号都放在非终结符 _A_ 的同步集合中。如果不断忽略一些词法单元，直到碰到了 \\(\texttt{FOLLOW}(\textit{A})\\)
    中的某个元素，再将 _A_ 从栈中弹出，可能语法分析器就能继续进行了。
2.  只用 \\(\texttt{FOLLOW}(\textit{A})\\) 是不够的。如 C 语言采用分号结尾，而遗漏分号可能导致语法分析器忽略下一个语句开头的关键字。我们可以将较高层次的开始符加入到较低层次的同步集合中。
3.  如果将 \\(\texttt{FIRST}(\textit{A})\\) 加入到非终结符 _A_ 的同步集合，那么当其中符号出现在输入中，可能可以根据 _A_ 继续进行语法分析
4.  如果一个非终结符可以产生空串，那么可以将空串作为默认值使用。这么做可能会推迟错误检测，但不会遗漏。并且减少需要考虑的非终结符数量。
5.  如果栈顶的一个终结符不能和输入匹配，最简单的方法是将其弹出栈，发出消息称已经插入这个终结符，并继续语法分析。这个方法是将其他词法单元的合集作为同步集合。

因此我们可以将 `FOLLOW` 作为同步词法单元，重绘预测分析表，示例 **id** `+` **id** `*`
**id** 的预测分析表如下

| 非终结符             | **id**                                       | `+`                                                | `*`                                                 | `(`                                          | `)`                                          | `$`                                          |
|------------------|----------------------------------------------|----------------------------------------------------|-----------------------------------------------------|----------------------------------------------|----------------------------------------------|----------------------------------------------|
| _E_                  | \\(\textit{E} \rightarrow \textit{TE}^{'}\\) |                                                    |                                                     | \\(\textit{E} \rightarrow \textit{TE}^{'}\\) | synch                                        | synch                                        |
| \\(\textit{E}^{'}\\) |                                              | \\(\textit{E}^{'} \rightarrow + \textit{TE}^{'}\\) |                                                     |                                              | \\(\textit{E}^{'} \rightarrow \varepsilon\\) | \\(\textit{E}^{'} \rightarrow \varepsilon\\) |
| _T_                  | \\(\textit{T} \rightarrow \textit{FT}^{'}\\) | synch                                              |                                                     | \\(\textit{T} \rightarrow \textit{FT}^{'}\\) | synch                                        | synch                                        |
| \\(\textit{T}^{'}\\) |                                              | \\(\textit{T}^{'} \rightarrow \varepsilon\\)       | \\(\textit{T}^{'} \rightarrow \* \textit{FT}^{'}\\) |                                              | \\(\textit{T}^{'} \rightarrow \varepsilon\\) | \\(\textit{T}^{'} \rightarrow \varepsilon\\) |
| _F_                  | \\(\textit{F} \rightarrow \textbf{id}\\)     | synch                                              | synch                                               | \\(\textit{F} \rightarrow (\textit{E})\\)    | synch                                        | synch                                        |

如果输入串是 \\(+\textbf{id}\*+\textbf{id}\\) 这样的错误输入，可以得到如此语法分析过程

| 已匹配                          | 栈                                               | 输入                                | 说明                                                |
|------------------------------|-------------------------------------------------|-----------------------------------|---------------------------------------------------|
|                                 | \\(\textit{E}\\$\\)                              | \\(+\textbf{id}\*+\textbf{id}\\$\\) |                                                     |
|                                 | \\(\textit{E}\\$\\)                              | \\(\textbf{id}\*+\textbf{id}\\$\\)  | 错误，\\(+\\)略过                                   |
|                                 | \\(\textit{TE}^{'}\\$\\)                         | \\(\textbf{id}\*+\textbf{id}\\$\\)  | 输出 \\(\textit{E}\rightarrow\textit{TE}^{'}\\)     |
|                                 | \\(\textit{FT}^{'}\textit{E}^{'}\\$\\)           | \\(\textbf{id}\*+\textbf{id}\\$\\)  | 输出 \\(\textit{T}\rightarrow\textit{FT}^{'}\\)     |
|                                 | \\(\textbf{id}\textit{T}^{'}\textit{E}^{'}\\$\\) | \\(\textbf{id}\*+\textbf{id}\\$\\)  | 输出 \\(\textit{F}\rightarrow\textbf{id}\\)         |
| **id**                          | \\(\textit{T}^{'}\textit{E}^{'}\\$\\)            | \\(\*+\textbf{id}\\$\\)             | 匹配 **id**                                         |
| **id**                          | \\(\*\textit{FT}^{'}\textit{E}^{'}\\$\\)         | \\(\*+\textbf{id}\\$\\)             | 输出 \\(\textit{T}^{'}\rightarrow\*\textit{FT}^{'}\\) |
| \\(\textbf{id}\*\\)             | \\(\textit{FT}^{'}\textit{E}^{'}\\$\\)           | \\(+\textbf{id}\\$\\)               | 匹配 \*                                             |
| \\(\textbf{id}\*\\)             | \\(\textit{T}^{'}\textit{E}^{'}\\$\\)            | \\(+\textbf{id}\\$\\)               | \\(\textit{M}[\textit{F},+]\\), 弹出 _F_            |
| \\(\textbf{id}\*\\)             | \\(\textit{E}^{'}\\$\\)                          | \\(+\textbf{id}\\$\\)               | 输出 \\(\textit{T}^{'}\rightarrow\varepsilon\\)     |
| \\(\textbf{id}\*\\)             | \\(+\textit{TE}^{'}\\$\\)                        | \\(+\textbf{id}\\$\\)               | 输出 \\(\textit{E}^{'}\rightarrow+\textit{TE}^{'}\\) |
| \\(\textbf{id}\*+\\)            | \\(\textit{TE}^{'}\\$\\)                         | \\(\textbf{id}\\$\\)                | 匹配 \\(+\\)                                        |
| \\(\textbf{id}\*+\\)            | \\(\textit{FT}^{'}\textit{E}^{'}\\$\\)           | \\(\textbf{id}\\$\\)                | 输出 \\(\textit{T}\rightarrow\textit{FT}^{'}\\)     |
| \\(\textbf{id}\*+\\)            | \\(\textbf{id}\textit{T}^{'}\textit{E}^{'}\\$\\) | \\(\textbf{id}\\$\\)                | 输出 \\(\textit{F}\rightarrow\textbf{id}\\)         |
| \\(\textbf{id}\*+\textbf{id}\\) | \\(\textit{T}^{'}\textit{E}^{'}\\$\\)            | \\(\\$\\)                           | 匹配 **id**                                         |
| \\(\textbf{id}\*+\textbf{id}\\) | \\(\textit{E}^{'}\\$\\)                          | \\(\\$\\)                           | 输出 \\(\textit{T}^{'}\rightarrow\varepsilon\\)     |
| \\(\textbf{id}\*+\textbf{id}\\) | \\(\\$\\)                                        | \\(\\$\\)                           | 输出 \\(\textit{E}^{'}\rightarrow\varepsilon\\)     |


### 短语层次恢复 {#短语层次恢复}

在预测分析表的空白条目中填入过程指针，即可用过程改变、插入或删除输入的符号，并发出适当的错误消息，或执行一些栈操作 (改变栈符号或压入新符号)。

