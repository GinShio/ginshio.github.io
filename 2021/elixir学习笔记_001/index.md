# Elixir 基本语法


好久没学习，随便写点东西，一直想学FP来着，不过之前 Haskell 整的有点难受，好难啊不太会，下次静下心来好好学一学吧，不过先试试 **Erlang** / **Elixir**​，听说也很难？

至于原因，莫名喜欢 Erlang，不知道为什么哈哈哈哈，得知有 Elixir 这个披着 Ruby 皮、用着 Beam 的 Lisp 觉得还不错？毕竟 **Lisp** 大法好！！ (虽然我不会 lisp) 不过
Elixir 名字好听 Logo 也好看

{{< figure src="https://upload.wikimedia.org/wikipedia/commons/9/92/Official_Elixir_logo.png" >}}

好了，前置吐槽就这么多吧，希望可以静下心好好学学 Elixir，呃，我也不知道可不可以啦，但是如果对 Elixir 感兴趣的话可以在 [Elixir School](https://elixirschool.com/en/) 尝试学习一下，我也才开始从这里开始学习


## 基本类型 {#基本类型}

-   整数类型：在 Erlang 和 Elixir 中，整数类型都是高精度类型，不区分类型所占的字节，有点类似 Python 中的整数
    Elixir 支持 二(0b)、八(0o)、十、十六(0x)进制的整数字面量，使用起来十分方便
    ```elixir
    255 # 十进制整数 255
    0b10001000 # 二进制整数 136
    0o7654321 # 八进制整数 2054353
    0xFFFF # 十六进制整数 65535
    ```

-   浮点类型：嗯，它是 IEEE 754，好了就这样吧，介绍完了

-   布尔类型：true 和 false，不过有一点需要注意，在 Elixir 中除了 false 和 nil 之外的所有值都为 true

-   原子类型：名字和代表的值相同的常量，有点像 Ruby 和 Lisp 中的 Symbol。BTW 布尔值 true / false 实际对应的是原子 :true 和 :false
    ```elixir
    :foo # 符号，名为 :foo
    :foo == :bar # false
    is_atom(true) # true
    is_boolean(:false) # true
    true == :true # true
    ```
    大写字母开始的别名也是原子，模块名 (module) 也是原子，当然也可以使用原子直接引用 Erlang 标准库的模块
    ```elixir
    is_atom(MyAtom) # true
    is_atom(MyApp.MyModule) # true
    ```

-   字符串：这是一个 UTF-8 编码的字符串，用双引号包住，并且支持换行与转义字符
    ```elixir
    "Hello" # "Hello"
    "这是一个\nString" #这是一个\nString
    ```
    当然要讲讲字符串的简单操作了，插值可以将变量插入到字符串中，这个操作有点类似
    Ruby 和 Shell 中的操作；字符串拼接操作，可以将两个字符串拼接在一起
    ```elixir
    name = "GinShio"
    "Hello #{name}" # "Hello GinShio"
    "Hello" <> " " <> name # "Hello GinShio"
    ```


## 基本操作 {#基本操作}


### 算术运算 {#算术运算}

Elixir 支持基本的 加 (+) 、 减 (-) 、 乘 (\*) 、 除 (/)，还有 `div` 和 `mod` 两个函数用于整数的除法和取模运算

```elixir
2 + 3 # 5
6 - 1 # 5
2 * 3 # 6
9 / 3 # 3.0
9 / 2 # 4.5
div(9, 2) # 4
rem(9, 2) # 1
```


### 逻辑运算 {#逻辑运算}

Elixir 支持逻辑运算，和其他语言差不多的 和(`&&`) 、 或(`||`) 、 非(`!`)

```elixir
-20 || true # -20
false || 42 # 42
nil || true # true
42 && true # true
42 && false # false
42 && nil # nil
true && false # false
!42 # false
!false # true
```

当然还有三个操作符 `and` 、 `or` 和 `not` ，不过这些操作符的地一个参数必须是布尔类型

```elixir
true and 42 # 42
# 42 and true # (BadBooleanError) expected a boolean on left-side of "and"
not true # false
true and nil # nil
# nil and true # (BadBooleanError) expected a boolean on left-side of "and"
```


### 关系运算 {#关系运算}

常见的关系运算 `==`, `!=`, `<=`, `<`, `>=` 和 `>`​，这与其他语言中的关系运算符相似

```elixir
1 > 2 # false
1 != 2 # true
2 == 2 # true
2 <= 3 # true
```

Elixir 还提供了两个关系运算符 `===` 和 `!==`​，它们类似于 JS 中的严格比较

```elixir
2 == 2.0 # true
3 == 3.0000000000000000000000001 # true
2 === 2.0 # false
2 === 2 # true
3 === 3.0000000000000000000000001 # false
```

Elixir 中有一个很重要的特性，任意类型之间都可以比较，因为类型都有一个优先级，支持它们之间互相比较

{{< admonition type="info" >}}
**number &lt; atom &lt; reference &lt; function &lt; port &lt; pid &lt; tuple &lt; map &lt; list &lt; bitstring**
{{< /admonition >}}

```elixir
3 < :foo # true
{:hello, :world} > [1, 2, 3] # false
9 > [1, 2, 3] # false
:bar < [1, 2, 3] # true
```


## 集合 {#集合}


### 列表 (List) {#列表--list}

列表是简单的集合，可以包含不同的数据类型，并且可以包含相同的值，内部使用 **链表**
实现，头插相较于尾插更快，获取长度也是 O(n) 的

头插使用 `|` (cons) 进行操作，可以将元素插入到列表的头部，而拼接操作 `++` 可以将两个列表拼接成一个，而减法操作 `--` 是基于严格比较的依照顺序的删除元素

```elixir
[3.14, :pie, "Apple"] # [3.14, :pie, "Apple"]
["π" | [3.14, :pie]] # ["π", 3.14, :pie]
[[:foo, "hello"] | ["bar", :world]] # [[:foo, "hello"], "bar", :world]
[3.14, :pie] ++ ["Cherry"] # [3.14, :pie, "Cherry"]
[1,2,2,3,2,3] -- [1,2,3,2] # [2, 3]
[1,2,2,3,2,3] -- [1,2,2,3,3] # [2]
[2] -- [2.0] # [2]
[2.0] -- [2.0] # []
```

列表可以选取 **头** (head) 和 **尾** (tail)，头是列表的第一个元素，尾是除去第一个元素剩下的列表，也可以和 cons 结合起来获取列表的头部与尾部

```elixir
hd [3.14, :pie, "Apple"] # 3.14
tl [3.14, :pie, "Apple"] # [:pie, "Apple"]
[head | tail] = [3.14, :pie, "Apple"]
# head = 3.14
# tail = [:pie, "Apple"]
```


### 元组 (Tuple) {#元组--tuple}

元组与列表类似，不过元组使用的是连续内存实现，获取元组的长度很快，但修改很麻烦
(新的元组必须重新在内存中拷贝一份)

元组相较于列表没有那么多操作，元组更倾向于做一个不可变的数据类型，我们常常把二元组称为 **pair**​，三元组称为 **triple**​，而其他长度为n的元组称其为 N 元组 (n-tuple)，这个概念在其他语言中也很常见

```elixir
{3.14, :pie, "Apple"} # {3.14, :pie, "Apple"}
{:foo, "bar"} # pair
{5, 3.14, :test} # triple
```


### 关键字列表 (Keyword List) {#关键字列表--keyword-list}

keywords 是一种特殊的列表，列表的元素是 pair，且 pair 的第一个元素必须是原子，其他行为与列表完全一致，不过 keywords 的语法可以不用写 pair 那么复杂，而是简便的
`key: value` 形式即可

keywords 有一些特殊的特性

1.  键是 **原子的**
2.  键是 **有序的**​，即定义后顺序不会改变
3.  键 **不必唯一**

<!--listend-->

```elixir
[foo: "bar", hello: "world", pi: 3.14] # [foo: "bar", hello: "world", pi: 3.14]
[{:foo, "bar"}, {:hello, "world"}, {:pi, 3.14}] # [foo: "bar", hello: "world", pi: 3.14]
keywords = [foo: "bar", foo: "baz", hello: "world"]
keywords[:foo] # "bar"
```


### 映射 (Map) {#映射--map}

映射也是键值对结构，与 keywords 类似，可以任意类型的数据为键，数据并不严格排序，但是键不能重复，重复的键会覆盖已有的键值对

map 的语法相对麻烦些，以 `key => value` 形式书写，好消息是如果键全是原子那么可以与 keywords 的语法类似。map可以像C++一样可以使用 `operator[]` 读取值，也可以使用
`operator.` 来读取值 (只可以用于读取原子键)

```elixir
map1 = %{:foo => "bar", "hello" => :world}
%{foo: "bar", hello: "world"} == %{:foo => "bar", :hello => "world"} # true
map2 = %{foo: "bar", hello: "world"}
map1["hello"] # :world
# map1.hello # (KeyError) key :hello not found
map1.foo # "bar"
map2[:foo] # "bar"
map2.hello # "world"
```

map 提供了 `operator|` 来更新一个键值对，但仅限于已存在的键值对，如果要添加一个新的键值对则需要用到 **put** 方法，当然 put 也可以用于更新

```elixir
map3 = %{foo: "bar", hello: "world"}
%{map3 | foo: "baz"} # %{foo: "baz", hello: "world"}
# %{map3 | a: "b"} # (KeyError) key :a not found
Map.put(map3, :a, "b") # %{a: "b", foo: "bar", hello: "world"}
```


## 语句 {#语句}

小小的吐槽下，本身想把模式匹配放在控制语句之后，毕竟控制语句如果学过其他热门语言肯定是认识的，不过看到 case 时，它依赖模式匹配，好吧...那就先记模式匹配的笔记，好了，开始吧


### 模式匹配 {#模式匹配}

模式匹配经常被用于函数、case等地方，用的还是蛮多的，且方便，模式匹配中必须穷尽示例用以匹配，如果默认值需要使用变量 **_** 来接收默认情况，类似 C 语言的 switch 语句中的 default


#### 匹配 {#匹配}

我们一直没有讲 `=` 这个其他语言中的赋值符号，在 Erlang/Elixir 中这不止是赋值，准确的将，这是 **匹配**​，接下来我们写一点 Erlang 的语句来体验一下匹配，​`Don't panic`​，这和我们已经学会的 Elixir 几乎一样，如果要一直学习 Elixir 的话 Erlang 是逃不掉的，
Lisp 不知道能逃掉不

```erlang
Var = 10. % 将 var 与 10 匹配
% Var = 5. % exception error: no match of right hand side value 5
10 = Var. % 10
% 5 = Var. % exception error: no match of right hand side value 10
```

Erlang 中可以看到变量 Var 与 10 匹配，匹配之后便不能与 5 匹配了，与 5 匹配将出现错误，这与 Elixir 中是类似的

```elixir
list = [1, 2, 3] # [1, 2, 3]
[1, 2, 3] = list # [1, 2, 3]
# [] = list # (MatchError) no match of right hand side value: [1, 2, 3]
```

现在想想之前学习 list 时使用的 `operator|`​，取 head 和 tail 时其实也是匹配，匹配时对于不关注的变量可以使用变量 **_** 替代

```elixir
[head | tail] = [1, 2, 3] # haed = 1, tail = [2, 3]
[head | _] = [1, 2, 3] # head = 1
{:ok, value} = {:ok, "Successful"} # value = "Successful"
# {:ok, value} = {:error, "Error"} # (MatchError) no match of right hand side value
```


#### Pin {#pin}

Elixir 在匹配时，匹配操作会同时做赋值操作，但 Erlang 中不会，我们可以使用 **Pin**
操作符 `^` 来保持与 Erlang 中行为的一致

```elixir
var = 10 # OK, var = 10
^var = 5 # NO, (MatchError) no match of right hand side value
var = 5 # OK, var = 5
5 = var # OK, match
```

pin 也可以被用于常见的数据结构中

```elixir
x = 1
{x, ^x} = {2, 1} # x = 2
# {^x, x} = {2, 1} # (MatchError) no match of right hand side value
key = "hello"
%{^key => value} = %{"hello" => "world"} # value = "world"
# %{^key => value} = %{:hello => "world"} # (MatchError) no match of right hand side value
```


### 控制语句 {#控制语句}

控制语句主要分为3种

if / unless\*
: if 与 unless 是条件语句，与其他语言的 if 语句类似，if 与 unless 语义相反，在
    Elixir 中都是宏定义
    ```elixir
    if String.valid?("Hello") do
      "Valid String"
    else
      "Invalid String"
    end
    # "Valid String"
    unless String.valid?("World") do
      "Invalid String"
    else
      "Valid String"
    end
    # "Valid String"
    ```

case
: case 是一种匹配语句，基于模式匹配
    ```elixir
    case {:ok, "Hello World"} do
      {:ok, result} -> result
      {:error} -> "Uh oh!"
      _ -> "Catch all"
    end
    # Hello World
    ```

cond
: 当我们需要匹配条件而不是值的时候，可以使用 cond，它的语法很像 case，按顺序匹配每一个条件，必须有一个为真的表达式，所以一般在结尾设置 `true` 匹配，有些像
    Haskell 中的 **守卫** 表达式
    ```elixir
    cond do
      2 + 2 == 5 -> "2+2==5"
      2 * 2 == 8 -> "2*2==8"
      true -> "All Error"
    end
    # "All Error"
    ```

with
: with 类似于 case 语句，适用于嵌套的 case 语句，按照顺序一次匹配表达式，当失败时会返回对应的返回值
    ```elixir
    user = %{first: "Xin", last: "Liu"}
    with {:ok, first} <- Map.fetch(user, :first),
         {:ok, last} <- Map.fetch(user, :last) do
      last <> ", " <> first
    end
    # "Liu, Xin"
    with {:ok, first} <- Map.fetch(user, :first),
         {:ok, hello} <- Map.fetch(user, :hello) do
      hello <> ", " <> first
    end
    # :error
    ```
    with 支持 else 语句，当 with 出现不匹配时，将其返回值在 else 中进行匹配，
    else 是类似 case 语法的模式匹配，需要穷尽匹配
    ```elixir
    with {:ok, number} <- Map.fetch(%{a: 1, b: 4}, :a),
         true <- is_even(number) do
      IO.puts "#{number} divided by 2 is #{div(number, 2)}"
      :even
    else
      :error ->
        IO.puts("We don't have this item in map")
      :error
      _ ->
        IO.puts("It's odd")
      :odd
    end
    ```


## 函数 {#函数}


### 匿名函数 {#匿名函数}

先说说匿名函数吧，lambda 表达式是函数式编程语言的基础，​**lambda 演算** 与 **图灵机**
堪称计算机程序设计语言的两大支柱，这里我们不学习那么深入，有兴趣嘛那就加油吧，我们简单说说 Elixir 中的 lambda，Elixir 中函数是一等公民，它们可以像变量一样使用与传递，威力十足！

简单的语法即 `fn (params) -> statements`​，这便会定义一个匿名函数，这个函数可以赋值给一个对象，或者传递进一个参数中；如果需要使用，则需要 `name.(param)` 来调用

```elixir
sum = fn (a, b) -> a + b end
sum.(2, 3) # 5
```

很简单吧，这更像是一个完整的函数定义，还有一种做法是像 Shell 中使用函数参数，即使用参数的顺序来确定形式参数的使用；这就让 lambda 简单多了，当然也更难理解参数的含义了。我们在此简单的说明下， `&()` 这是一个匿名函数， `&1` 这是这个函数接收的第一个参数，以此类推

```elixir
sum = &(&1 + &2)
sum.(2, 3) # 5
# sum.("String", 666) # Error: (ArithmeticError) bad argument in arithmetic expression: "String" + 666
# sum.(2, 3, 4) # Error: (BadArityError) &:erlang.+/2 with arity 2 called with 3 arguments
```

模式匹配可以用在函数中，我们先来看看匿名函数中的模式匹配，和 case 差不多，不过这是个函数

```elixir
handle_result = fn
  {:ok, result} -> IO.puts("Handling result...")
  {:ok, _} -> IO.puts("This would be never run as previous will be matched beforehand.")
  {:error} -> IO.puts("An error has occurred!")
end
```


### 命名函数 {#命名函数}

命名函数一般被定义在模块中，使用关键字 **def** 定义，如果函数体与头在一行的使用可以使用 `do:` 来简单的书写

```elixir
defmodule MyModule do
  def hello1(name) do
    "Hello" <> ", " <> name
  end
  def hello2(name), do: "Hello" <> ". " <> name
end
MyModule.hello1("GinShio") # Hello, GinShio
MyModule.hello2("GinShio") # Hello. GinShio
```

函数式语言往往也可以进行函数重载，不过他们一般只按照函数参数的个数进行重载，这在
Elixir 中也适用，在 Elixir 中函数的全程一般是 `name/param_num`

```elixir
defmodule MyModule do
  def hello(), do: "Hello, Everybody" # hello/0
  def hello(name), do: "Hello" <> ", " <> name # hello/1
end
MyModule.hello() # "Hello, Everybody"
MyModule.hello("iris") # "Hello, iris"
```

命名函数当然也可以很好的支持模式匹配，这样我们递归的实现会很简单

```elixir
defmodule MyLength do
  def of([]), do: 0
  def of([_ | tail]), do: 1 + of(tail)
end
MyLength.of([]) # 0
MyLength.of([1, 2, 3, 4, 5]) # 5
```

当然模式匹配与 Map 结合在一起，示例函数 hello/1 展示了只关注指定键的用法，当然我们也可以在关注指定键时接受整个 Map，即用模式匹配来接受

```elixir
defmodule MyModule do
  def hello(%{name: person}), do: "Hello, " <> person
  def all_map(%{name: person_name} = person) do
    IO.puts "Hello, " <> person_name
    IO.inspect person
  end
end
MyModule.hello(%{name: "Fred", age: 95}) # "Hello, Fred"
# MyModule.hello(%{age: 95}) # (FunctionClauseError) no function clause matching in MyModule.hello/1
MyModule.all_map(%{name: "Fred", age: 95})
# Hello, Fred
# %{age: 95, name: "Fred"}
```

Private (私有函数)
: 如果你不希望模块外调用某些函数，你可以使用 `defp` 来定义私有函数，这样定义的函数只能在模块内使用
    ```elixir
    defmodule MyFibonacci do
      def fib(0), do: 0
      def fib(1), do: 1
      def fib(n), do: fib(1, 1, n)
      defp fib(ans, pre, 2), do: ans
      defp fib(ans, pre, n), do: fib(ans + pre, ans, n - 1)
    end
    MyFibonacci.fib(10) # 55
    MyFibonacci.fib(100) # 354224848179261915075
    # MyFibonacci.fib(1, 1, 5) # (UndefinedFunctionError) function MyFibonacci.fib/3 is undefined or private.
    ```

Pipe `|>` (管道操作)
: 没错你没听错，就是 pipe，有没有想起使用 \*nix 时使用的管道，Elixir 中的 pipe 与
    \*nix 中的类似，都是将前一个调用的结果传递给后一个，这就很爽了，我们来对比一下，管道简直是嵌套调用的救星
    ```elixir
    foo(bar(baz(do_something()))) # Normal
    do_something() |> baz() |> bar() |> foo() # Pipe
    ```
    那如果参数数量大于1怎么办，这些问题不大，带上参数就行，从 Pipe 来的参数优先入栈
    ```elixir
    "Hello, World" |> String.split() # ["Hello,", "World"]
    "Hello, World" |> String.split(", ") # ["Hello", "World"]
    ```

Guard (守卫表达式)
: 可以被用于 `函数` 和 `case` 当中，比方说我们现在有两个签名相同的函数 `hello/1`
    ，我们需要通过 guard 来确定应该调用哪个函数
    ```elixir
    defmodule MyModule do
      def hello(names) when is_list(names) do
        names |> Enum.join(", ") |> hello()
      end
      def hello(names) when is_binary(names) do
        "Hello, " <> names
      end
    end
    MyModule.hello("GinShio") # "Hello, GinShio"
    MyModule.hello(["GinShio", "iris"]) # "Hello, GinShio, iris"
    ```
    我们试试在 case 中使用 guard，更多用法请查看 [Guard clauses](https://hexdocs.pm/elixir/guards.html#list-of-allowed-expressions)
    ```elixir
    case x do
      1 -> :one
      2 -> :two
      n when is_integer(n) and n > 2 -> :larger_than_two
    end
    ```

Default (默认参数)
: 我们可以为函数设置一些默认值，使用语法 `argument \\ value`
    ```elixir
    defmodule MyModule do
      def hello(name, language_code \\ "en"), do: phrase(language_code) <> name
      defp phrase("en"), do: "Hello, "
      defp phrase("es"), do: "Hola, "
      defp phrase("zh"), do: "你好，"
    end
    MyModule.hello("iris") # "Hello, iris"
    MyModule.hello("iris", "en") # "Hello, iris"
    MyModule.hello("iris", "es") # "Hola, iris"
    MyModule.hello("iris", "zh") # "你好，iris"
    ```
    不过我们在默认参数与守卫表达式一起使用时，往往会出现一些问题，先来看看问题代码
    ```elixir
    defmodule Greeter do
      def hello(names, language_code \\ "en") when is_list(names) do
        names |> Enum.join(", ") |> hello()
      end
      def hello(names, language_code \\ "en") when is_binary(names) do
        phrase(language_code) <> names
      end
      defp phrase("en"), do: "Hello, "
      defp phrase("es"), do: "Hola, "
    end
    # (CompileError): def hello/2 defines defaults multiple times.
    # Elixir allows defaults to be declared once per definition. Instead of:
    #     def foo(:first_clause, b \\ :default) do ... end
    #     def foo(:second_clause, b \\ :default) do ... end
    ```
    有多个函数同时匹配时，默认参数这种模式很容易混淆，它不被 Elixir 喜欢，至于解决方法嘛还是有的，我们需要先声明这个函数，有点像 C++ 使用默认参数的方法
    ```elixir
    defmodule Greeter do
      def hello(names, language_code \\ "en")
      def hello(names, language_code) when is_list(names) do
        names |> Enum.join(", ") |> hello()
      end
      def hello(names, language_code) when is_binary(names) do
        phrase(language_code) <> names
      end
      defp phrase("en"), do: "Hello, "
      defp phrase("es"), do: "Hola, "
    end
    ```
