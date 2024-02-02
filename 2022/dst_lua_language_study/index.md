# Lua 语言学习


Lua 是一个动态弱类型脚本语言，核心由 C 语言实现，执行效率高，可直接做 C / C++ 扩展。另外 Lua 另一个主流实现 Lua JIT 主要研究针对 Lua 的即时编译系统。

而 Lua 由于其高性能、小巧、简单、与 C 结合性好等特点，大量运用于游戏领域，而饥荒的实现以及扩展也基本使用 Lua 完成。

本章主要描述 Lua 中的词法、语法和语义，语言结构将使用通常的扩展 [BNF](https://en.wikipedia.org/wiki/Backus%E2%80%93Naur_form) 表示，比如
`{a}` 表示 0 或 多个 a， `[a]` 表示一个可选的 a。而关键字用黑体表示 (e.g.
**kword**)，其他终结符使用反引号表示 (e.g. `` `=` ``)

而 Lua 学习主要以 Lua 5.1 的 [官方文档](https://www.lua.org/manual/5.1/manual.html) 为对象。


## 词法介绍 {#词法介绍}

在 Lua 中标识符可以是任意字母、数字、下划线所组成的字符串 (不能以数字开头)，而标识符可以用作变量的名称和表字段名。但是在标识符命名时不能使用以下名称，因为它们是关键字。

| 关键字   |       |      |       |        |     |       |        |
|-------|-------|------|-------|--------|-----|-------|--------|
| and      | break | do   | else  | elseif | end | false | for    |
| function | if    | in   | local | nil    | not | or    | repeat |
| return   | then  | true | until | while  |     |       |        |

Lua 是一个大小写敏感的语言，因此 And 与 AND 是完全不同的两个标识符。一般约定，由一个下划线开头并跟随大写字母的标识符 (e.g. `_VERSION`) 是 Lua 内部所使用的全局变量，应避免使用。

| 符号 |   |    |   |   |   |     |    |    |       |       |      |      |
|----|---|----|---|---|---|-----|----|----|-------|-------|------|------|
| +  | - | \* | / | % | ^ | \\# | == | ~= | &lt;= | &gt;= | &lt; | &gt; |
| =  | ( | )  | { | } | [ | ]   | ;  | :  | ,     | .     | ..   | ...  |

与 C 语言类似，文字字符串使用单引号或双引号分割，并可以包含转义字符。另外还可以使用 `\` 跟三位数字的方式来表示一个字符 ([ASCII](https://en.wikipedia.org/wiki/ASCII))，在不足三位数字时默认在前方补 0
扩展到三位。在 Lua 中有长字符串，即多行字符串，Lua 中称为长括号字符串。长括号字符串以 `[[` 开始，并且这两个 [ 之间可以增加任意多的 `=`，结束时以 `]]` 结尾，结尾必须匹配相同多的 `=`。根据 = 的多少，将其称为 n 级 (e.g. `[==[` 称为 2 级，而
`[[` 称为 0 级)。

```lua
-- 这些字符串所表达的是同一个文字字符串
a = 'alo\n123"'
a = "alo\n123\""
a = '\97lo\010123"'
a = [[alo
123"]]
a = [===[alo
123"]===]
```

最重要的注释，在 Lua 中使用 `--` 开头的字符串表示，这是一个行注释开始的标志，而在这之后直到行尾的所有字符串都不会被解释器解释。如果 `--` 紧跟着长括号，那么这个注释将会是一个长注释。

```lua
-- 这是一个行注释，到行末为止
a = 15 * 6
--[==[
这是一个长注释，长括号之内的部分都是注释
b = a * 5       这行将不会运行，因为这是长注释的范围之内
]==]
```

数字常数约定可以编写可选的小数部分和可选的十进制指数部分，而十六进制常量以 **0x**
开头。

```lua
b = 3           -- 3
b = 3.0         -- 3.0
b = 3.14159     -- 3.14159
b = 314.159e-2  -- 3.14159
b = 0.314159e1  -- 3.14159
b = 0xff        -- 255
b = 0x56        -- 86
```


## 值与类型 {#值与类型}

Lua 是动态类型语言，这意味着值是没有类型的，所有值都是第一类值，所有值都可以被存储在变量、传递到参数、或作为函数返回的结果。

在 Lua 中有八个基本类型: **nil**, **boolean**, **number**, **string**, **function**,
**userdata**, **thread** 和 **table**。Nil 是不同于任何值的 nil 类型字面量，通常表示无用的量。boolean 则是表示真假的量，nil 和 false 都可以使表示条件为假，而其他值则可以表示条件为真。number 表示全体实数，这是一个双精度浮点数。string 表示的是字符的数组，而字符以 8 bit ASCII 表示；与 C 语言不同的是，字符串可以包含任意 8 bit
字符，甚至是 `\0`。

Lua 可以调用或操作 Lua 或 C 的函数，userdata 可以在 C 数据结构中直接存储 Lua 值。这种类型对应于一块原始内存，在 Lua 中除了赋值和身份测试外没有其他预定义操作。然而在使用 metatables 时程序员可以定义 userdata 值的操作。Userdata 值不可以被创建或修改，只能通过 C API 使用，这将保证宿主程序可以拥有数据的完整性。

thread 类型代表的是执行线程的标识符，这个是以协程实现的，因此不要与操作系统的线程混淆。因此即使操作系统不支持线程，Lua 也可以正常使用 thread 类型。

table 实现关联数组，这个数组不仅可以使用 number 作为下标，可以使用任何值作为下标
(除了 nil)。table 是异构 (heterogeneous) 的，索引可以包含任意类型的任意值 (除了
nil)。table 是 Lua 中唯一的数据结构机制：可以表示普通数组、符号表、集合、记录、图、树等。表示记录时，Lua 使用字段名作为索引。Lua 支持以 `a.name` 作为
`a["name"]` 的语法糖使用。创建表有几种方便的方法。与索引一样，表字段的值也可以是任意类型 (nil 除外)，因为函数是一等值，所以表字段可以包含函数。

table、function、thread 和所有的 userdata 值都是 objects：变量不能实质性的包含这些值，只是引用它们。赋值、参数传递、函数返回总是操作这些值的引用，因此不会有任何复制操作。库函数类型返回一个描述给定值类型的字符串。

Lua 在运行时提供了字符串和数值之间的自动转换，任何应用于字符串的算术运算都会尝试将字符串转换为数字，相反在需要字符串的地方使用数字则会尝试相反的操作，如果需要完全控制字符串的转换需要使用 `string.format`。


## 变量 {#变量}

变量存储值，在 lua 中变量分为全局变量、局部变量和表字段。定义变量时其名称 (标识符) 是唯一的。

<div class="verse">

var ::= Name<br />

</div>

局部变量生存周期在词法空间内，这个变量可以在函数作用域内被任意的访问。如果在定义之前访问变量，其值为 nil。如果是表结构，方括号内表示其索引。这表示访问变量
prefixexp 的字段 exp，并将其值赋值给 var。语法 `t["Name"]` 与 `t.Name` 是等价的

<div class="verse">

var ::= prefixexp \`[\` exp \`]\`<br />
var ::= prefixexp \`.\` Name<br />

</div>

所有的全局变量被存储在起始 Lua 表中，这是一个环境变量或相似的表。每一个函数都有对这个表的引用，当函数被创建时，将继承这个环境变量表。如果你想获取这些环境变量，可以使用 `getfenv` 函数调用，要替换时可以使用 `setfenv` 调用。


## 声明 {#声明}

Lua 支持一组类似与 Pascal 或 C 的几乎常规化的声明语句，其中包括赋值、控制、函数调用和变量声明。


### chunk {#chunk}

Lua 中执行单元被称为 chunk，chunk 是简单的语句执行序列的声明。每一个语句后可以选择性跟随分号，但是连续的 `;;` 是不合法的 (因此没有空语句)。

<div class="verse">

chunk ::= {stat [\`;\`]}<br />

</div>

另外 Lua 可以处理作为 chunk 的可变参数的匿名函数。chunk 可以存储在文件或主程序的字符串中，执行 chunk 时会先进行预编译将其转化为虚拟机字节码，然后再使用虚拟机执行编译的代码。chunk 也可以用 luac 编译为二进制码。在编译时，源代码与编译代码是可以互换的，Lua 自动检测文件类型并采用相应的措施。


### block {#block}

句法上 block 与 chunk 类似，是显式声明的序列，类似于 C 语言中的 `{}` 划分新的作用域。block 可以被显示地分割从而生成单句声明。

<div class="verse">

block ::= chunk<br />
stat  ::= ****do**** block ****end****<br />

</div>

显式 block 可以有效地控制变量声明的作用域，也可以在其他 block 中添加 return 或
block 语句。


### assignment {#assignment}

Lua 允许多赋值语句，赋值定义语法可以在左边定义一个变量列表，表达式列表将定义在右边。

<div class="verse">

stat ::= varlist \`=\` explist<br />
varlist ::= var {\`,\` var}<br />
explist ::= exp {\`,\` exp}<br />

</div>

比如在 Lua 中我要定义 `a = 5, b = 3` 可以写为以下方式。如果 varlist 与 explist
的长度不一样，多余的 varlist 会被赋值为 nil，而多余的 exp 会被丢弃。

```lua
a, b = 5, 3, 1
c, d, e = a - b, b - a
-- a = 5, b = 3, c = 2, d = -2, e = nil
```

如果表达式列表以函数调用结束，则该调用返回的所有值将在被调整前进入列表。


### Control Structures (控制结构) {#control-structures--控制结构}

控制语句主要以 **if** 、 **while** 和 **repeat** 关键字为主的结构语句。

<div class="verse">

stat ::= **while** exp **do** block **end**<br />
stat ::= **repeat** block **until** exp<br />
stat ::= **if** exp **then** block { **elseif** exp **then** block } [ **else** block ] **end**<br />

</div>

控制结构中的 condition (条件语句) 可以返回任意值， `false` 与 `nil` 代表条件语句为假的情况，其他表示真情况 (0 与空字符串同样也是真)。

repeat-until 循环结构类似 C 语言中的 do-while 语句，不过直到 exp 才算作循环块结束，因此条件可以引用循环块内的局部变量。

**return** 语句可以从 chunk 或 function 中返回一些值 (可以超过一个值)

<div class="verse">

stat ::= **return** [explist]<br />

</div>

而 **break** 语句将会终止 **while** 、 **repeat** 和 **for** 循环的执行，跳过剩下的语句。而 break 只会终止当前循环。

<div class="verse">

stat ::= **break**<br />

</div>

return 和 break 只能作为 block 的最后一个语句，如果需要在 block 内部使用 return
或 break，需要显式的在内部块中使用。


### for {#for}

for 有两种形式：数字型和通用型。数字型 for 通过变量的算术运算来控制循环。

<div class="verse">

stat ::= **for** Name \`=\` exp \`,\` exp [\`,\` exp] **do** block **end**<br />

</div>

```lua
for v = e1, e2, e3 do block end
-- 上面的 for 与下面的代码是等价的
do
  local var, limit, step = e1, e2, e3
  if not (var and limit and step) then error() end
  while (step > 0 and var <= limit) or (step <= 0 and var >= limit) do
    local v = var
    block
    var = var + step
  end
end
```

通用型 for 语句工作原理类似函数，被称为 **iterators** (迭代器)，每趟迭代迭代器函数都会被调用并产生新值，当得到的新值为 nil 时将结束迭代。

<div class="verse">

stat ::= **for** namelist **in** explist **do** block **end**<br />
namelist ::= Name {\`,\` Name}<br />

</div>

```lua
for var_1, ..., var_n in explist do block end
-- 上面的 for 与下面的代码是等价的
do
  local f, s, var = explist
  while true do
    local var_1, ..., var_n = f(s, var)
    var = var_1
    if var == nil then break end
    block
  end
end
```


### 局部声明 {#局部声明}

局部变量可以在 block 中的任何位置被声明，并且可以被初始化赋值。

<div class="verse">

stat ::= **local** namelist [\`=\` explist]<br />

</div>

初始化赋值与多重赋值具有相同的语义，否则，所有没有被赋值的变量都使用 nil 初始化。

chunk 也是一个 block，因此变量可以在任何显式的 block 外被声明，其生命周期被扩展到 chunk 结束。


## 表达式 {#表达式}

基础的表达式可以表示为：

<div class="verse">

exp ::= prefixexp<br />
exp ::= **nil** | **false** | **true**<br />
exp ::= Number<br />
exp ::= String<br />
exp ::= function<br />
exp ::= tableconstructor<br />
exp ::= \`...\`<br />
exp ::= exp binop exp<br />
exp ::= unop exp<br />
prefixexp ::= var | functioncall | \`(\` exp \`)\`<br />

</div>

所有的函数调用和可变参数表达式都可以产生多个结果，如果表达式用作语句则丢弃所有返回值。如果表达式仅使用最后一个元素 (或唯一一个元素) 那么不会做任何调整，其他条件下将会丢弃除第一个值外的所有值。

```lua
f()               -- 丢弃所有返回值
g(f(), x)         -- f() 调整至 1 个返回值
g(x, f())         -- f() 返回所有返回值
a, b, c = f(), x  -- f() 调整至 1 个返回值
a, b, c = x, f()  -- f() 调整至 2 个返回值
a, b, c = f()     -- f() 调整至 3 个返回值
return f()        -- 返回所有 f() 的返回值
return ...        -- 返回所有接受的参数
return x, y, f()  -- 返回 x 、 y 以及所有 f() 的返回值
{f()}             -- 将 f() 所有返回值添加到列表中
{...}             -- 将所有参数添加到列表中
{f(), nil}        -- f() 调整至 1 个返回值
```

任何表达式在括号中都产生一个值，因此 `(f(x, y, z))` 始终是单个值 (第一个返回值)，如果 f 没有返回值则是 nil。


### 算术运算符 {#算术运算符}

Lua 支持多种算术运算符 `+` (加)、 `-` (减)、 `*` (乘)、 `/` (除)、 `%` (取模) 以及 `^` (幂)。所有的字符串在运算中被转换为数字。


### 比较运算符 {#比较运算符}

比较运算符包含 `==` (相等)、 `~=` (不等)、 `<` (小于)、 `>` (大于)、 `<=` (小于等于) 和 `>=` (大于等于)，这些运算符总是返回 **false** 或 **true**。

对于相等运算符，首先比较运算数的类型，不同类型的运算数将会直接返回 **false**，然后对值进行比较。对于 Object (tables / userdata / threads / functions) 的比较，同一个 Object 才会相等。而表结构 `t[0]` 与 `t["0"]` 是不同的元素。

不等号仅可以在 Number 与 String 上使用，Lua 会尝试调用元函数 `lt` 与 `le` 。


### 逻辑运算符 {#逻辑运算符}

Lua 中逻辑运算符以 **and** 、 **or** 和 **not** 为主，和之前说过的一样，**false** 和
**nil** 被逻辑运算符当作假值，其他值都为真。另外 and 和 or 都有短路特性。

```lua
10 or 20           -- 10
10 or error()      -- 10
nil or "a"         -- "a"
nil and 10         -- nil
false and error()  -- false
false and nil      -- false
false or nil       -- nil
10 and 20          -- 20
```


### 级联 (Concatenation) {#级联--concatenation}

Lua 中 `..` 表示字符串级联，如果操作数是数字或字符串，它们将被转换为字符串并进行连接，Lua 会调用元函数 `concat` 。


### 长度操作 {#长度操作}

长度操作为 `#`，可以计算字符串的字节数，但是对于 table 并不是表中键值对的个数，而是最大的不为 nil 的整数下标的值，这个前提是 table 中没有空洞。Lua 下标从 1 开始，因此 1 为 nil 时 `#t` 为 0。

```lua
t = {}    -- #t = 0
t[0] = 1  -- #t = 0
t[1] = 1  -- #t = 1
t[3] = 1  -- #t = 1, t[2] 为空洞
t[2] = 1  -- #t = 3
```


### 优先级 {#优先级}

Lua 中运算符可能具有不同的优先级，通常可以通过括号来改变运算符的优先级。

| 等级 |      |      |           |       |    |    |
|----|------|------|-----------|-------|----|----|
| 1  | or   |      |           |       |    |    |
| 2  | and  |      |           |       |    |    |
| 3  | &gt; | &lt; | &lt;=     | &gt;= | ~= | == |
| 4  | ..   |      |           |       |    |    |
| 5  | +    | -    |           |       |    |    |
| 6  | \*   | /    | %         |       |    |    |
| 7  | not  | #    | - (unary) |       |    |    |
| 8  | ^    |      |           |       |    |    |

这些运算符，除了串联 `..` 和幂运算 `^` 是右结合外，其余运算符均为左结合。


### 表构造器 {#表构造器}

表构造器用于创建一个空的表或者初始化其中一些字段，语法类似

<div class="verse">

tableconstructor ::= \`{\` [fieldlist] \`}\`<br />
fieldlist ::= field {fieldsep field} [fieldsep]<br />
field ::= \`[\` exp \`]\` \`=\` exp | Name \`=\` exp | exp<br />
fieldsep ::= \`,\` | \`;\`<br />

</div>

语句 `[exp1] = exp2` 可以为表中添加键值为 exp1 值为 exp2 的元素，而语句 `name =
exp` 与 `["name"] = exp` 等价。

```lua
t = { [f(1)] = g; "x", "y"; x = 1, f(x); [30] = 23; 45, }
-- 上下等价
local t = {}
t[f(1)] = g
t[1] = "x"
t[2] = "y"
t.x = 1
t[3] = f(x)
t[30] = 23
t[4] = 45
```


### 函数调用 {#函数调用}

函数调用语法类似

<div class="verse">

functioncall ::= prefixexp args<br />

</div>

函数调用时首先对 prefixexp 和 args 进行求值，如果 prefixexp 结果具有函数类型则传递给定参数进行调用，否则使用 prefixexp 的 call 元方法 (将 prefixexp 作为第一个参数)。

<div class="verse">

functioncall ::= prefixexp \`:\` Name args<br />

</div>

这种调用方式类似于 OOP 中的 `方法` ， `v:name(args)` 与 `v.name(v, args)` 语法等价。

<div class="verse">

args ::= \`(\` [explist] \`)\`<br />
args ::= tableconstructor<br />
args ::= String<br />

</div>

所有参数表达式在函数被调用之前进行求值，如果在返回时进行函数调用 Lua 将进行尾调用优化或尾递归优化。在尾调用优化时，被调用函数将复用函数栈，因此不用担心函数调用爆栈。但是尾调用优化会删除有关调用函数的所有调试信息。需要注意优化仅发生在
**return** 语句仅有单个函数调用的情况下，从而完全返回调用函数的返回值，注意以下情况都不会进行尾调用优化：

```lua
return (f(x))     -- 返回值数量调整为 1
return 2 * f(x)
return x, f(x)    -- 返回 x 和 f(x) 的所有返回值
f(x); return      -- 丢弃结果
return x or f(x)  -- 返回值数量调整为 1
```


### 函数定义 {#函数定义}

函数定义语法如下

<div class="verse">

function ::= **function** funcbody<br />
funcbody ::= \`(\` [parlist] \`)\` block **end**<br />
stat ::= **function** funcname funcbody<br />
stat ::= **local** **function** Name funcbody<br />
funcname ::= Name {\`.\` Name} [\`:\` Name]<br />

</div>

```lua
function f() body end
function t.a.b.c.f() body end
local function lf() body end
-- 上下等价
f = function () body end
t.a.b.c.f = function () body end
local lf; lf = function () body end
```

函数定义将定义一个可执行表达式，Lua 解释器会预编译所有函数代码，之后执行函数代码，函数将被实例化，函数实例是表达式的最终结果。同一个函数的不同实例可以引用不同的外部变量，也可以有不同的环境变量表。

函数的参数列表语法如下

<div class="verse">

parlist ::= namelist [\`,\` \`...\`] | \`...\`<br />

</div>

函数被调用时，传参个数被调整至与参数列表相同长度，除非这个函数是一个变长参数函数
(参数列表最终是 `...`)。


## 可见性规则 {#可见性规则}

Lua 是词法作用域语言 (静态作用域)，因此变量的生命周期从声明后的第一条语句开始，到包含该声明的块结束为止。

```lua
x = 10  -- 全局变量 x1 = 10
do      -- 创建一个新的块
  local x = x  -- 局部变量 x2 = 10
  x = x + 1    -- 局部变量 x2 = 11
  do
    local x = x + 1  -- 内部变量 x3 = 12
    print(x)         -- 打印内部变量 x3
  end
  -- 内部变量 x3 生命周期结束
  print(x)  -- 打印局部变量 x2
end
-- 局部变量 x2 生命周期结束
print(x)  -- 打印全局变量 x1
```


## 元表 (metatables) {#元表--metatables}

在 Lua 中每个值都有一个元表，其中定义了原始值的行为 (其关心的特定运算)，可以修改特定字段来更改某些行为。元表可以控制一个对象的算术运算、排序比较、剪切、长度运算、下标等等，元表还可以定义在垃圾回收时调用的函数。比如对一个非数字添加 `加法` 运算，可以定义元表中的 **__add** 字段。

如果想获取这些值可以使用 [getmetatable](https://www.lua.org/manual/5.1/manual.html#pdf-getmetatable)，而 [setmetatable](https://www.lua.org/manual/5.1/manual.html#pdf-setmetatable) 可以修改其中的字段。对于表和所有的 userdata 类型数据，每个值都有一个私有的 metatable，而其他类型的值共享值类型的 metatable。Lua 会为每个事件绑定一个键值，在事件触发时会根据键值调用元函数。

对于这些键值，Lua 定义有不同的名字，而且这些名称之前会有双下划线 `__` ，以下时常见的元表元素名称：

-   **add**: `+` (加) 运算符
-   **sub**: `-` (减) 运算符
-   **mul**: `*` (乘) 运算符
-   **div**: `/` (除) 运算符
-   **mod**: `%` (取模) 运算符
-   **pow**: `^` (幂) 运算符
-   **unm**: `-` (负) 运算符
-   **concat**: `..` (级联) 运算符
-   **len**: `#` (长度) 运算符
-   **eq**: `==` (相等) 运算符
-   **lt**: `<` (小于) 运算符
-   **le**: `<=` (小于等于) 运算符
-   **index**: `[]` (表下标) 运算符
-   **newindex**: `[]` (表下标赋值) 运算符
-   **call**: 函数调用


## 环境 (Environment) {#环境--environment}

除了 metatale，thread、function 以及 userdata 类型的数据还有其他表结构，被称为
**环境** (environment)，环境也是一张表且多个对象可以共享相同环境。

创建线程对象、非嵌套 Lua 函数 (load、loadfile、loadstring 创建) 时共享创建线程的环境，创建 userdata 和 C 函数时会共享 C 函数对象，创建嵌套 Lua 函数时共享创建
Lua 函数的环境。

userdata 的 environment 对 Lua 来说没有意义，创建 env 只是为了方便编程。与线程相关的 env 被称作全局环境，被用于线程和非嵌套 Lua 函数创建时的默认的环境，且可以被
C 代码直接访问。C 函数相关的 env 是默认 userdata 和 C function 被创建时的环境，也可以被 C 代码直接访问。而 Lua 函数相关的 env 用于解析函数内部对全局变量的访问，也是创建嵌套 Lua 函数时的默认环境。

修改或获取 Lua 函数、线程的环境可以使用 [getfenv](https://www.lua.org/manual/5.1/manual.html#pdf-getfenv) 和 [setfenv](https://www.lua.org/manual/5.1/manual.html#pdf-setfenv)，而其他对象如果想操作环境需要访问其 C API。


## 垃圾回收 (Garbage Collection) {#垃圾回收--garbage-collection}

Lua 实现了自动内存管理，即 Lua 会自动清理没有那些申请了但不再使用的对象，这一机制使用垃圾回收来完成。

Lua 实现了一个增量标记清理收集器，使用两个数字来控制 GC 周期: **GC 暂停** 和 **GC
步长倍数**，其使用百分比作为单位 (设置 100 表示内部值 100%)。

-   GC 暂停控制收集器在开始新的周期之前的等待时间，较大的值意味着收集器行为不那么激进。举个例子：小于 100 时，收集器不会等待而直接开始新的周期，而 200 表示收集器在开始新的周期时等待使用的内存翻倍。
-   GC 步长倍数控制收集器相对内存分配的速度，较大的值意味着收集器不仅更激进，而且每次增加步长还会逐渐增大。比如说，值 100 时收集器会很慢，并且可能导致器永远不会完成一个周期；而默认值 200 表示收集器将以内存分配速度的 2 倍运行。

如果想定制 GC，可以使用 C API [lua_gc](https://www.lua.org/manual/5.1/manual.html#lua_gc) 或 lua API [collectgarbage](https://www.lua.org/manual/5.1/manual.html#pdf-collectgarbage)。


### GC 元方法 {#gc-元方法}

`lua_gc` 可以为 userdata 修改 GC 元方法 (这个方法被称为终结者 finalizers)，这个方法允许协调 Lua GC 与外部资源管理。

GC 并不会立即回收带有 `__gc` 字段的 userdata，而是将其放入一个列表中，收集后 lua
对列表中的元素执行以下等价操作

```lua
function gc_event(user_data)
  local h = metatable(user_data).__gc
  if h then
    h(user_data)
  end
end
```

每个周期结束，终结者将以创建顺序相反的顺序被调用，而 userdata 本身将会在下一个周期被回收。


### 弱表 (weak table) {#弱表--weak-table}

弱表是其中元素都是弱引用的表，GC 会忽略弱引用，也就是说只有弱引用的对象会被回收。

弱表可以是弱键、弱值，或二者都是。弱键意味着可以回收键但不能回收值，实际上，如果键或值有一个被回收的话那么整个 pair 将从表中删除。虚表用元表中的 **__mode** 字段控制，\__mode 包含 k 表示弱键，v 表示弱值。在使用定义好的虚表时，不应修改 __mode 字段的值，否则行为未定义。


## 协程 (Coroutine) {#协程--coroutine}

Lua 支持协程，协程的执行在 Lua 中依赖线程。与多线程系统的线程不同，协程需要显式调用 yield 函数主动暂停。

创建协程使用 `coroutine.create`，与线程类似使用参数传递协程执行函数，并返回一个协程的句柄，但不会执行协程。创建之后，以句柄为参数的第一次调用
`coroutine.resume` 将开始执行协程，额外的参数将传递给协程函数。

协程有两种方式终止：

-   协程主函数返回 (显式或隐式都可以)，resume 将返回 **true** 和所有函数的返回值
-   产生不保护错误，resume 将返回 **false** 外加错误信息

协程使用 `coroutine.yield` 时将会暂停， `coroutine.resume` 立即返回 **true**，和所有从 `coroutine.yield` 中返回的值。当下一次运行相同的协程时，将从 yield 开始继续执行。

`coroutine.wrap` 也可以创建协程，但不同的是将会返回一个函数用以调用来启动协程，函数参数通过 wrap 返回函数来传递，与 `coroutine.resume` 不同的是，wrap 不会产生不保护错误，因此不会有第一个 boolean 返回值来判断函数是否失败。

举个协程的例子

```lua
function foo(a)
  print("foo", a)
  return coroutine.yield(2 * a)
end

co = coroutine.create(function (a, b)
    print("co-body", a, b)
    local r = foo(a + 1)
    print("co-body", r)
    local r, s = coroutine.yield(a + b, a - b)
    print("co-body", r, s)
    return b, "end"
end)

print("main", coroutine.resume(co, 1, 10))
-- co-body 1       10
-- foo     2
-- main    true    4
print("main", coroutine.resume(co, "r"))
-- co-body r
-- main    true    11      -9
print("main", coroutine.resume(co, "x", "y"))
-- co-body x       y
-- main    true    10      end
print("main", coroutine.resume(co, "x", "y"))
-- main    false   cannot resume dead coroutine
```

