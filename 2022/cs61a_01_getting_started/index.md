# CS61A 入门


虽然 CS61A 使用 Python 进行教学，但我希望好好学一下 Erlang 和 Scheme。如果想查看更多关于 CS61A 的信息，请访问 [课程主页](https://cs61a.org/)，当然我也会将一部分内容和实现放在自己的
[repo](https://gitlab.com/GinShio/sicp-learn.git) 中。

scheme 有很多不同的实现，而大多实现不兼容。因此我使用的是 [MIT/GNU Scheme](https://www.gnu.org/software/mit-scheme/)。


## Lab00: Getting Startted (入门) {#lab00-getting-startted--入门}

首先搭建一个环境，CS61A 中指 Python3 环境。

-   Setup: 以下是本课程所用到的基础软件，也是重要的组件。
    -   终端 (Terminal)：安装一个终端可以让你运行本课程的 OK 命令
    -   编程环境 (Environment)：编程环境是必须的，当然课程需要的是 Python3.7，这样你才可以运行 OK 命令
    -   文本编辑器 (Text Editor)：VSCode、Atom 什么都行，只要能用来写代码
-   练习使用终端，并组织你的项目文件
-   学习 Python 基础
-   做一个练习


### 安装 {#安装}


#### 安装终端 {#安装终端}

在 MacOS 和 Linux 中本身就自带了终端软件 (Terminal)，如果是 KDE，终端软件被称作
Konsole。而 Windows 中，直接在 Store 中下载 Windows Terminal 即可。当然 Windows
下推荐使用 WSL，但是系统不是关注的重点。


#### 安装语言环境 {#安装语言环境}

最低要求 Python3.7，因为这是运行 OK 命令的必要条件。当然你也可以使用别的编程语言。

Windows 下，你可以在这里下载 [Python3](https://www.python.org/) 或 [erlang](https://www.erlang.org/)。安装之后将路径添加到 PATH 系统环境变量中。如果你用 WSL 那和 Linux 下没什么区别。

对于 Linux 用户，就很方便了。使用包管理器进行安装，`apt install erlang python3`
(Debian / Ubuntu)，或者 `zypper in erlang python3` (openSUSE)，有或者 `pacman -S
erlang python3` (Arch)，当然其他发行版也可以用相关的命令进行安装。


#### 安装文本编辑器 {#安装文本编辑器}

说实话，文本编辑器的选择很自由。当然 CS61A 还是推荐了一些流行的文本编辑器

-   [Visual Studio Code](https://cs61a.org/articles/vscode) (VSCode)：一个全功能桌面编辑器，有很多支持不同语言的扩展可用
-   [Atom](https://cs61a.org/articles/atom)：轻量级桌面编辑器。不过我不建议，MS 接手 GitHub 后，Atom 就死了
-   [Vim](https://cs61a.org/articles/vim)、[Emacs](https://cs61a.org/articles/emacs)：命令行编辑器
-   [PyCharm](https://www.jetbrains.com/pycharm/)： JetBrains 推出的 Python IDE
-   [Sublime Text](https://www.sublimetext.com/)

CS61A 贴心的提供了在线编辑器 <https://code.cs61a.org/>


### 编程语言基础 {#编程语言基础}


#### 算术运算符 {#算术运算符}

在大部分编程语言中，算术运算所包含的东西都差不多。比如 `+` (加)、`-` (减)、`*` (乘)、`/` (除) 等，erlang 和 python 都不例外

```erlang
3 + 4.  % 7
3 - 4.  % -1
3 * 4.  % 12
3 / 4.  % 0.75
3 + 4 + 5 + 6.  % 18
```

```python
3 + 4  # 7
3 - 4  # -1
3 * 4  # 12
3 / 4  # 0.75
3 + 4 + 5 + 6  # 18
```

scheme 是 Lisp 的方言，因此和 Lisp 一样，使用前缀运算，即表达式的第一个为方法调用

```scheme
(+ 3 4)  ; 7
(- 3 4)  ; -1
(* 3 4)  ; 12
(/ 3 4)  ; 7.5e-1
(+ 3 4 5 6) ; 18
(+)      ; 0
(*)      ; 1
(/ 3)    ; 1/3
```

当然还有一些额外的运算，比如 python 不止提供了 `//` (整数除法) 和 `%` (取模)，还提供了 `**` (幂运算)；erlang 提供了 `div` (整数除法) 和 `rem` (余数)；scheme 则是有
`quotient` (整数除法)、`remainder` (余数运算) 和 `modulo` (模运算)。很遗憾的就是
erlang 中并没有取模运算。

```erlang
3 div 4.   % 0
5 div 2.   % 2
3 rem 4.   % 3
-3 rem 4.  % -3
```

```python
3 // 4  # 0
5 // 2  # 2
3 % 4   # 3
-3 % 4  # 1
3 ** 4  # 81
```

```scheme
(quotient 3 4)    ; 0
(quotient 5 2)    ; 2
(remainder 3 4)   ; 3
(remainder -3 4)  ; -3
(modulo 3 4)      ; 3
(modulo -3 4)     ; 1
```


#### 字符串 {#字符串}

在 Python 中字符串还是比较友好的，默认以 UTF-8 编码

```python
"this is a string."
'this also is a string'
"""
STRING!
"""
"string"[3]    # 'i'
len("string")  # 6
len("中文")    # 2
```

scheme 中字符串也是很正常的样子，不过并不是 UTF-8 编码的字符串，有点类似 C 语言的字符数组。关于 scheme 的 string 更多详情请查阅[文档](https://www.gnu.org/software/mit-scheme/documentation/stable/mit-scheme-ref/Strings.html)。

```scheme
(string? "str")         ;; #t
(make-string 5 #\x30)   ;; "00000"
(string-length "str")   ;; 3
(string-length "中文")  ;; 6
```

与 Python 一样，erlang 的字符串也是 UTF-8 编码的字符数组。

```erlang
length("teste").  % 5
length("中文").   % 2, [20013,25991]
```

不过 erlang 中还有一种常用的字符串，即字节序列形式的字符串，这就与 C 语言中的字符串有点像了。

```erlang
<<"中文"/utf8>>.  % valid string
<<"中文">>.       % not valid string
is_bitstring("test").     % false
% byte_size("test").      % exception error: bad argument
% bit_size("test").       % exception error: bad argument
is_bitstring(<<"test">>).  % true
byte_size(<<"test">>).     % 4
bit_size(<<"test">>).      % 32
```


#### 赋值运算 {#赋值运算}

如果学过 C 语言或者 Python，一定对赋值不陌生，即将一个值与一个名字进行绑定。

```python
a = (100 + 50) // 2
a  # 75
a = "str"
a  # "str"
```

当然 scheme 中可以使用 `let` 定义一个有作用域的变量，用 `define` 则会定义一个全局的变量。而赋值语句则是 `set!`，与 Python 一样，scheme 也是一门动态强类型语言。

```scheme
(let ((x 3) (y 4)) (* x y))  ;; 12
;; (* x y)  ;ERROR: unbound variable:  y
(define x 3)
(+ x)  ;; 3
(set! x "str")  ; "str"
(let ((x 0) (y 1))
  (let* ((x y) (y x)) (list x y))   ;; (1 1)
  (let  ((x y) (y x)) (list x y)))  ;; (1 0)
```

不过对于 erlang 情况就有点特殊了。在 erlang 中 `=` 表示将值与名字进行匹配，如果是没有定义的名字，也会进行绑定。这是由于 erlang 是**纯** (pure) 函数式语言，等号的语义和 Python / C 中是不一样的。

```erlang
X = 10.  % 10
% X = 5. % exception error: no match of right hand side value 5
% 6 = X. % exception error: no match of right hand side value 10
% 6 = Y. % variable 'Y' is unbound
X = 10.  % 10
10 = X.  % 10
```

---


## Lec02: Functions (函数) {#lec02-functions--函数}


### 表达式 {#表达式}

表达式表述了一个计算或过程，并会产生一个值。比如 \\(2^{100}\\)、\\(\sin \pi\\) 等。在表达式中存在运算符 (operator) 和运算数 (operand)

```scheme
(+ 1 2 3 4 5)  ;; 15
```

当然名字也可以作为一个表达式使用

```scheme
(let ((x 3)) x) ;; 3
```

但是表达式有一定的执行顺序，简单说先执行子表达式，将子表达式的值代入表达式中继续执行。直到计算出整个表达式的值。

```scheme
;; 3 + 5 * 3 - 6 / 3 * 4 - 7
(- (+ 3 (* 5 3)) (* (/ 6 3) 4) 7)
```

有时候这种嵌套的表达式表示实在让人不爽，反正先计算子表达式，再用子表达式的值计算随后的表达式。因此有些编程语言中引入了管道运算符，将嵌套表达式简单化。

```elixir
# 3 + 5 * 3 - 6 / 3 * 4 - 7
5 |> Kernel.*(3) |> Kernel.+(3)
  |> Kernel.-(6 |> Kernel./(3) |> Kernel.*(4))
  |> Kernel.-(7)  # 3
```


### 函数 {#函数}

赋值可以理解为一个名称绑定了一个值，而很多语言中将函数也作为一个值。因此函数也可以被绑定在名称之上。

```scheme
(let ((add +)) (add 1 2))  ;; 3
```

在编程中，有时会说 **纯函数** (pure function)，也就是没有 **副作用** (side effect) 的函数。即在面对相同的输入时，函数无论如何调用，其输出是相同的。也就是说，纯函数并不会依赖外部状态，也不会对外部状态进行改变。

```scheme
(expt 10 3)            ;; pure function
(print "Hello world")  ;; non-pure function
```

定义一个自己的函数，当然也可以定义一个匿名函数

```python
def name(param):
    # function body
    return param

name_lambda = lambda param: param
```

```scheme
(define (name param)
  ;; function body
  param)
(define name-lambda
  (lambda (param) param))
```

```erlang
name(Param) -> Param.
NameLambda = fun (Param) -> Param end.
```

函数既然作为一等公民，自然而然的可以开始在函数的返回值或参数中出现，这样返回函数或参数是函数的函数被称为高等函数。

```erlang
lists:foldl(fun(X, Sum) -> X + Sum end, 0, [1,2,3,4,5]). % 15
```

当函数调用时，会进行以下操作：

1.  添加函数栈帧，初始化新的环境
2.  在栈帧中绑定实际参数 (arguments) 和形式参数 (parameters)
3.  在新环境中执行函数体

在 Python 中函数如果不返回，则将默认直接返回 `None`，而很多函数式编程语言中默认都会返回块的最后一个表达式

```python
def square_not_return(x):
    x * x
    # return None
```

```scheme
(define (square x) (* x x)) ;; return x * x
```

```erlang
fun (X) -> X * X end.  % return x * x
```

当定义函数时，就会将一个名字与该函数绑定在当前的环境中。调用相当于在当前环境中查找并调用该函数。

在新的环境中，各个函数是从全局作用域中派生出来的，因此新环境中除了访问自己环境内的变量，还可以访问父作用域的变量。

```scheme
(define x 10)  ;; global x: 10
(define y 20)  ;; global y: 20
(define (multi y) (* x y)) ;; global x * local y
(multi 5) ;; 50
(multi y) ;; 200
```
