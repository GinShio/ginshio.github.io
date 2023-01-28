# Elixir 模块


## 模块 {#模块}

之前函数的时候也简单的见过模块了，Elixir 允许嵌套模块，这样可以轻松定义多层命名空间

```elixir
defmodule Greeter.Greeting do
  def morning(name), do: "Good morning, #{name}"
  def evening(name), do: "Good evening, #{name}"
end
Greeter.Greeting.morning("iris") # "Good morning, iris"
```

模块通常还会有一些属性，这些属性通常被用作常量

```elixir
defmodule Example do
  @greeting "Hello"
  def greeting(name) do
    ~s(#{@greeting}, #{name}.)
  end
end
Example.greeting("iris") # "Hello, iris."
```

当然还有一些的属性，用于保留功能，比如 `moduledoc` 和 `doc` 作为文档，文档可以用
**ExDoc** 生成 HTML，而 **ExMark** 是一个 Markdown 分析器，最终我们可以使用 mix 来生成文档

```elixir
defmodule Example do
  @moduledoc """
  This is the Hello module.
  """
  @moduledoc since: "1.0.0"

  @doc """
  Says hello to the given `name`.
  Returns `:ok`.
  ## Examples
      iex> Example.world(:john)
      :ok
  """
  @doc since: "1.3.0"
  def world(name) do
    IO.puts("hello #{name}")
  end
end
```


### 结构体 (Struct) {#结构体--struct}

在 Elixir 中结构体 Struct 是 Map 的特殊形式，它的键是预定义的，一般都有默认值，不过有个限制，Struct 只能定义在 Module 中，一般一个模块定义一个结构体

```elixir
defmodule Example.User do
  defstruct name: "GinShio", roles: []
end
default = %Example.User{} # %Example.User{name: "GinShio", roles: []}
iris = %{default | name: "iris"} # %Example.User{name: "iris", roles: []}
inspect(default) # "%Example.User{name: \"GinShio\", roles: []}"
%Example.User{name: "iris"} = iris # pattern
```

可以看到 inspect 展示了 Struct 中的所有字段，如果我们想排除保护字段，可以使用
`@derive` 注解来实现这一功能

```elixir
defmodule Example.User do
  @derive {Inspect, only: [:name]} # 只打印 :only 中的字段
  # @derive {Inspect, except: [:roles]} # 排除 :except 中的字段
  defstruct name: nil, roles: []
end
inspect(default) # "#Example.User<name: \"GinShio\", ...>"
```


### 组合 (Composition) {#组合--composition}

Elixir 以组合的方式为模块添加全新的功能，并且也为我们提供了多种访问其他模块的方式

alias (别名)
: 通过别名访问其他模块，当别名有冲突时还可以使用 `as` 来设置别名解决冲突，当然也可以一次指定多个别名
    ```elixir
    defmodule Example.Source do
      def hello(name), do: "Hello, #{name}!"
    end
    defmodule Example.Alias do
      alias Example.Source
      def hello(), do: Source.hello("FooBar")
    end
    defmodule Example.AliasMulti do
      alias Example.{Source, Alias}
      def hello(), do: Source.hello("Src")
    end
    defmodule Other.Alias do
      alias Example.Alias, as: ExAlias
      def hello(), do: ExAlias.hello()
    end
    ```

import (导入)
: 我们可以从其他模块导入函数，不过这有些污染名称空间
    ```elixir
    # last([1, 2, 3]) # (CompileError): undefined function last/1
    List.last([1, 2, 3]) # 3
    import List
    last([1, 2, 3]) # 3
    ```
    好消息是，就像之前学习 Struct 时控制 inspect 输出一样，​`:only` 与 `:except`
    是我们控制 import 导出的好帮手
    ```elixir
    import List, only: [last: 1] # only import `last/1'
    first([1, 2, 3]) # (CompileError): undefined function first/1
    last([1, 2, 3]) # 3
    ```
    我们如果想导出所有的函数呢，这样太麻烦了吧，好在 Elixir 提供了一种特殊的方法，
    `:functions` 和 `:macros` 分别代表函数和宏，不过不能除外就是了
    ```elixir
    import List, only: :functions # 导出 List 中的所有函数
    import List, only: :macros # 导出 List 中的所有宏
    # import List, except: :functions
    # (CompileError): invalid :except option for import, expected value to be a list literal, got: :functions
    ```

require (请求)
: 这是一个只对宏有效的指令，虽然不知道宏是什么，不过只要知道它只 import 模块中的宏而不是函数，目前来说就行了

use (使用)
: 这是一个修改当前模块的指令，我们在调用 `use` 时会执行指定模块中所定义的
    `__using__` 宏进行回调，当然现在不懂没关系，在学习了宏之后再来学习这里吧 (反正我也不懂
    ```elixir
    defmodule Hello do
      defmacro __using__(opts) do
        quote do
          def hello(name), do: "Hi, #{name}"
        end
      end
    end
    defmodule Example do
      use Hello
    end
    Example.hello("GinShio") # "Hi, GinShio"
    ```
    非常的神奇，当然宏还是可以带参数的，比如下面这个从 Elixir School 抄来的示例
    (这个更看不懂了
    ```elixir
    defmodule Hello do
      defmacro __using__(opts) do
        greeting = Keyword.get(opts, :greeting, "Hi")
        quote do
          def hello(name), do: unquote(greeting) <> ", " <> name
        end
      end
    end
    defmodule Example.En do
      use Hello
    end
    defmodule Example.Es do
      use Hello, greeting: "Hola"
    end
    Example.En.hello("GinShio") # "Hi, GinShio"
    Example.Es.hello("GinShio") # "Hola, GinShio"
    ```


### 注解 {#注解}

Elixir 是一个动态语言，类型信息会被编译器忽略，这样完成一个程序会很麻烦，因此我们往往会寄希望于其他工具帮助我们来完成检查，降低复杂度，这时就需要注解来帮助我们。

Specification 可以理解为一个接口 (**interface**)，用于定义了函数的参数与返回值的类型，语法 `@spec name(param list) :: return`​，简单用例子看一下怎么用吧

```elixir
@spec sum_product(integer) :: integer
def sum_product(a) do
  [1, 2, 3] |> Enum.map(fn e -> e * a end) |> Enum.sum()
end
```

我们可以正常的使用这个函数，毕竟它不被编译器所关注，​`Enum.sum()` 将会返回一个
number 而不是 integer，如果想发现这些问题的话，我们需要使用 Dialyzer 这类静态分析器来帮我们解决这些问题

当我们使用一个 spec 时我们可能需要有一些很复杂的结构，如果每次都定义一遍实在太麻烦了，这时我们就需要类型相关的注解，好在 Elixir 提供了

-   `@type` 公开类型，类型的内部结构是公开的
-   `@typep` 私有类型，只能在模块定义的地方使用
-   `@opaque` 公开类型，但内部结构是私有的

当然类型也是可以带参数的 (有 Haskell 那味了)，当然别忘了和模块文档相似的
`@typedoc` (类型文档)，我们看看怎么用

```elixir
defmodule Example.Type do
  defstruct first: nil, last: nil
  @type t(first, last) :: %Example.Type{first: first, last: last}
  @typedoc """
  Type that represents Example struct with :first(integer) and :last(integer)
  """
  @type t :: %Example.Type{first: integer, last: integer}
end
defmodule Example do
  @spec sum_times(integer, Example.Type.t()) :: integer
  def sum_times(a, params) do
    for i <- params.first..params.last do
      i
    end
    |> Enum.map(fn(e) -> e * a end) |> Enum.sum() |> round
  end
end
```


## 字符串 {#字符串}

Elixir 字符串是 **UTF-8** 编码，底层是字节序列，即二进制字节表示，如果我们在字符串后添加一个字节 `0` 的话将看到字符串的底层字节 (`<<>>` 表示一个字节的值)

```elixir
en = "hello"
zh = "你好"
en_bin = en <> <<0>> # <<104, 101, 108, 108, 111, 0>>
zh_bin = zh <> <<0>> # <<228, 189, 160, 229, 165, 189, 0>>
```

除了字符序列，Elixir 中还有一种字符列表，它们使用 `'char list'` 来表示，字符列表的值都是 **UTF-8 码点** ，这与字符序列有很大不同。正如示例中的 `你`​，码点是 20320，但是 UTF-8 编码中是三个字节

```elixir
en_ = 'hello' # [104, 101, 108, 108, 111]
zh_ = '你好' # [20320, 22909]
```


## 魔符 (Sigil) {#魔符--sigil}

Sigil 是 Elixir 中用于 **表示** 和 **处理** 字面量的，可以自定义，当然也有一些内置的
Sigil

| Sigil | 释义                   |
|-------|----------------------|
| `~C`  | **不处理** 插值和转义的 `字符列表` |
| `~c`  | **处理** 插值和转义的 `字符列表` |
| `~R`  | **不处理** 插值和转义的 `正则表达式` |
| `~r`  | **处理** 插值和转义的 `正则表达式` |
| `~S`  | **不处理** 插值和转义的 `字符串` |
| `~s`  | **处理** 插值和转义的 `字符串` |
| `~W`  | **不处理** 插值和转义的 `单词列表` |
| `~w`  | **处理** 插值和转义的 `单词列表` |
| `~N`  | NaiveDateTime 格式的数据结构 |
| `~U`  | DateTime 格式的数据结构 |

在使用 Sigil 时需要设定字面量的范围，需要用到分隔符

-   `<...>` (尖括号)
-   `{...}` (花括号)
-   `[...]` (方括号)
-   `(...)` (小括号)
-   `|...|` (直线)
-   `/.../` (斜线)
-   `"..."` (双引号)
-   `'...'` (单引号)

接下来我们大概看看这些 Sigil 的用法

```elixir
~C/2 + 7 = #{2 + 7}/ # '2+7=\#{2+7}'
~c/2 + 7 = #{2 + 7}/ # '2 + 7 = 9'
"Elixir" =~ ~r/elixir/ # false
"elixir" =~ ~r/elixir/ # true
~w/i love elixir school/ # ["i", "love", "elixir", "school"]
```


## 时间 {#时间}

Elixir 内置了几个处理时间的模块，让我们试试最简单的，当前的 UTC 时间

```elixir
t = Time.utc_now() # ~T[11:40:46.527943]
t.hour # 11
t.minute # 40
t.second # 49
# t.day # (KeyError) key :day not found
```

UTC Time 虽然可以使用 Sigil，但是它只有时间，没有日期信息，也没有时区信息，那我们试试日期吧，只有日期没有时间！！！

```elixir
d = Date.utc_today() # ~D[2021-02-19]
{:ok, date} = Date.new(2021, 03, 01) # {:ok, ~D[2021-03-01]}
d.year # 2021
d.month # 2
d.day # 19
Date.day_of_week(d) # 5
Date.leap_year?(d) # false
```

Sigil 创建 Date 和 Time 还挺方便，不过有个问题，它们都是最简单的 **UTC** 时间，并且仅有日期或时间，也没有时区，显得很不好用

还记得之前 Sigil 中列出的 `~N` 吗，我们现在来看看这个 **NaiveDateTime**​，它包含了日期与时间，不过还是缺少时区，所以它所表示的还是 UTC 时间

```elixir
n = NaiveDateTime.utc_now() # ~N[2021-02-19 11:50:44.630064], UTC时间
NaiveDateTime.add(n, 30) # ~N[2021-02-19 11:51:14.630064], 增加30s
l = NaiveDateTime.local_now() # ~N[2021-02-19 19:52:10], 本地时间
NaiveDateTime.to_iso8601(l) # "2021-02-19T19:52:10", 格式化到 iso8601
```

**DateTime** 是包含全部信息的时间数据结构，不过遗憾的是这个模块仅有一些转换函数和处理 UTC 的函数，因为 Elixir 还没有提供相关的 **时区数据库**​，务必加上 [tz](https://github.com/mathieuprog/tz) /
[tzdata](https://github.com/lau/tzdata) 这个时区数据库再来体验，不然只能 UTC 太痛苦了

```elixir
DateTime.utc_now() # ~U[2021-02-19 11:57:59.244240Z]
{:ok, u} = DateTime.from_naive(n, "Etc/UTC") # {:ok, ~U[2021-02-19 11:50:44.630064Z]}
DateTime.from_unix(1613735444) # {:ok, ~U[2021-02-19 11:50:44Z]}
DateTime.from_iso8601("2021-02-19T19:52:10Z") # {:ok, ~U[2021-02-19 19:52:10Z], 0}
```

还是有点不爽？不爽的话试试 [timex](https://hexdocs.pm/timex/) / [calendar](https://hexdocs.pm/calendar) 这些功能强大的第三方时间库


## 推导 {#推导}

推导表达式在函数式编程中很常见，它可以根据一定规则生成全新列表，甚至非函数式的语言中 (如 Python) 也可以看到它的影子，举一个简单的例子

```elixir
for x <- [1, 2, 3, 4, 5], do: x * x # [1, 4, 9, 16, 25]
```

生成器从列表依次获取值，然后根据规则生成全新的列表，不过不一定必须是列表，还可以是任意的可遍历类型

```elixir
for {k, v} <- %{foo: "bar", hello: "world"}, do: {k, v} # [foo: "bar", hello: "world"]
for <<c <- "hello">>, do: <<c>> # ["h", "e", "l", "l", "o"]
```

推导表达式可以嵌套，并且支持模式匹配，不过没发现怎么并列 (GHC牛皮

```elixir
# [{1, 6}, {1, 7}, {1, 8}, {2, 6}, {2, 7}, {2, 8}, {3, 6}, {3, 7}, {3, 8}]
for x <- [1,2,3], y <- [6,7,8], do: {x,y}
# ["Hello", "World"]
for {:ok, v} <- [ok: "Hello", error: "Unknown", ok: "World"], do: v
```

好消息，guard 可以在这里使用，推导表达式会为检查相应的变量，只有 guard 表达式为真时才会继续执行

```elixir
require Integer
for x <- 1..10, Integer.is_even(x), do: x # [2, 4, 6, 8, 10]
for x <- 1..100, Integer.is_even(x), rem(x, 9) == 0, do: x # [18, 36, 54, 72, 90]
```

推导表达式可以不止生成列表，还能生成很多东西，任何 **Collectable** 协议的结构体！！！当然这个协议，现在不重要，重要的是，可以生成其他结构

```elixir
# %{one: 1, three: 3, two: 2}
for {k, v} <- [one: 1, two: 2, three: 3], into: %{}, do: {k, v}
# "Hello,iris"
for c <- [72, 101, 108, 108, 111, 44, 105, 114, 105, 115], into: "", do: <<c>>
```
