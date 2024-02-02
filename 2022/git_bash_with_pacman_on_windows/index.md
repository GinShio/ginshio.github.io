# 在 Windows 的 Git Bash 中使用包管理器


Windows 中，在安装 Git Bash 时，会安装一个最小化的 Msys 环境，用于提供 Uinx 兼容层。单独安装一个 msys 不如直接使用 Git 引入的来的爽。

另外还有些好处，比如安装依赖只需要从包管理器安装，而无需到处找官网安装配环境。


## 安装 Git {#安装-git}

Git 的安装应该是都会的，但还是应该说以下，在 Windows 上安装 git 时，实际上是有很多细节需要注意的。

1.  选择 git 使用的默认的编辑器

    {{< figure src="/images/wingit-choosing-the-default-editor-used.png" width="40%" >}}

    实际上，git 已经在这里说的很明白了，默认 vim 是一个历史原因，推建我们使用更现代的 GUI 编辑器。实际上，你可以使用 `core.editor` 来修改你想使用的编辑器。当然，如果你不设置这个值，git 会用环境变量中的 `EDITOR` 作为默认编辑器使用，而
    Unix 世界中，`EDITOR` 往往是 `Vi` 或 `Vim`。

    最后说一下我的习惯，我并不喜欢 Vim，但是配置了的 Emacs 打开太慢了，由其是简单的写一个 message (VSCode 人称小 emacs)，所以我更偏向于终端编辑器 GNU Nano，图形编辑器则更喜欢用 Kate。

2.  初始化新仓库时的默认分值名称

    {{< figure src="/images/wingit-adjusting-default-branch-name-in-new-repositories.png" width="40%" >}}

    你可以使用 `init.defaultbranch` 来更改默认的分支名称。

3.  环境变量的作用域

    {{< figure src="/images/wingit-adjusting-path-for-environment-scope.png" width="40%" >}}

    我更推建第一种使用方式，我们只会在 Git-Bash 中使用 Unix tools。这样现得我们的环境变量更为干净。其实在 Powershell 中还好，在 CMD Prompt 中使用 `[` 也太精分了。

4.  换行符转换

    {{< figure src="/images/wingit-configuring-eol.png" width="40%" >}}

    这是重中之重，也是经常出问题的地方。个人推建设置为 git 不管换行符 (`checkout
        as-is, commit as-is`)，由自己根据项目要求手动管理换行符。可以用
    `core.autocrlf=false` 来指定这种方式。

    其中，`as-is` 的意思是**原本是什么样就是什么样，Git 不会转换换行符**。以下这两种方式是最容易出问题的，当原本的换行符被替换时，整个文件将发生冲突。

    -   **Checkout Windows-style, commit Unix-style:** 拉取时转换为 Windows 换行符，和用户本地一致，提交时自动转换为 Unix 风格换行符。可以用
        `core.autocrlf=true` 来指定这种方式。
    -   **Checkout as-is, commit Unix-style:** 拉取时保持不变，提交时全部转换为 Unix
        风格换行符。可以用 `core.autocrlf=input` 来指定这种方式。

5.  用哪种终端模拟器配合 Git-Bash 使用

    {{< figure src="/images/wingit-configuring-the-terminal-emulator.png" width="40%" >}}

    只推荐使用 MinTTY。

6.  选择 git pull 的默认行为

    {{< figure src="/images/wingit-default-behavior-of-pull.png" width="40%" >}}

    pull 的行为主要有 rebase、merge 和 fast-forward，主要由变量 `pull.rebase` 和
    `pull.ff` 控制。`rebase` 的行为可以理解为每次都将自己的提交放在 remote 提交之后；`merge` 的行为是将生成一个新的节点；`fast-forward` 则会在一个提交树上类似于
    rebase，当出现分叉时行为类似于 merge，如果是 `ff-only` 时只会产生 rebase 行为，出现分叉则会导致命令失败。

    {{< figure src="https://git-scm.com/book/en/v2/images/basic-branching-5.png" width="55%" >}}

    -   `pull.ff=false`
        ```shell
        git pull --merge # merge
        ```
    -   `pull.ff=true`
        ```shell
        git pull --merge # merge --ff
        ```
    -   `pull.ff=only`
        ```shell
        git pull --merge # merge --ff-only
        ```
    -   `pull.rebase=true`
        ```shell
        git pull # rebase
        git pull --merge # merge
        ```
    -   `pull.rebase=false`
        ```shell
        git pull # merge
        git pull --merge # merge
        ```


## MSYS 设置 {#msys-设置}


### msys2 环境 {#msys2-环境}

| 环境       | 目录        | 工具链 | 架构    | C 库   | C++ 库    |
|----------|-----------|-----|-------|-------|----------|
| msys       | /usr        | gcc  | x86_64  | cygwin | libstdc++ |
| mingw64    | /mingw64    | gcc  | x86_64  | msvcrt | libstdc++ |
| ucrt64     | /ucrt64     | gcc  | x86_64  | ucrt   | libstdc++ |
| clang64    | /clang64    | llvm | x86_64  | ucrt   | libc++    |
| mingw32    | /mingw32    | gcc  | i686    | msvcrt | libstdc++ |
| clang32    | /clang32    | llvm | i686    | ucrt   | libc++    |
| clangarm64 | /clangarm64 | llvm | aarch64 | ucrt   | libc++    |

gcc 工具链有着更广泛的测试，有 Fortran 的支持，并且也有构建的 clang 工具链可用。
llvm 工具链仅有 llvm 支持，不支持 gcc 工具链。并且提供了 ASAN 和 TLS (Thread
Local Storage) 支持。

对比 C 库，msvcrt (Microsoft Visual C++ Runtime) 与 ucrt (Universal C Runtime)
都依赖于 MSVC，但前者对于 C99 兼容性不好，ucrt 有着更好的 MSVC 兼容性。


### Windows Terminal 支持 {#windows-terminal-支持}

Git 安装时可选 Windows Terminal 支持。当然还需要对打开 GitBash 的命令进行修改

```bat
C:/Program Files/Git/msys2_shell.cmd -defterm -here -no-start -mingw64
```

如果你想更改默认的 shell，只要将命令改为

```bat
C:/Program Files/Git/msys2_shell.cmd -defterm -here -no-start -mingw64 -shell shell
```


### 环境变量 {#环境变量}

MSYS2_PATH_TYPE
: 控制系统设置的环境变量是否出现在 msys 中

    | mode    | comment          |
    |---------|------------------|
    | strict  | 不包含 Windows PATH |
    | minimal | 仅系统 PATH      |
    | inherit | 全部 PATH        |


## 安装包管理器 {#安装包管理器}


### 安装 pacman 及其依赖 {#安装-pacman-及其依赖}

构建 Unix 环境的第一步就是有一个包管理器，我们直接使用 MSYS 的 [pacman](https://packages.msys2.org/package/pacman?repo=msys&variant=x86_64) 包管理器。下载完成后，将其解压到 Git 的根目录下，在本章中，我们将用 `/` 表示 Git 安装的根目录。

这时的 pacman 还是无法使用的阶段，毕竟 Git 携带的是最小化的环境，并没有 pacman
需要的依赖。不过 msys package 中已经为我们详细列出了其所需的依赖。如果你想知道
Git 安装了哪些软件，可以查看 `/etc/package-versions.txt`。

-   bash &gt;= 4.2.045
-   bzip2
-   curl
-   gettext
-   gnupg
-   msys2-keyring
-   pacman-mirrors
-   which
-   xz
-   zstd

实际上，我们并不需要安装列出的所有依赖，因为 Git 已经帮我们安装了一部分了。我们只需要安装 [msys2-keyring](https://packages.msys2.org/package/msys2-keyring?repo=msys&variant=x86_64) 和 [pacman-mirrors](https://packages.msys2.org/package/pacman-mirrors?repo=msys&variant=x86_64)。


### 更新 pacman {#更新-pacman}

现在更新 pacman 的 repo，在更新之前别忘了初始化 msys key。涉及到 pacman 等需要权限的命令需要用管理员权限打开 Git-Bash。

```shell
# init msys keyring
pacman-db-upgrade
pacman-key --init
pacman-key --populate msys2
# update package source
yes |pacman -Syuu
```

如果你用 pacman 搜索自己安装的 pacman 或者 Git 安装的 curl，会发现包管理器并没有把它们记录为已安装的状态。将刚刚自己安装的 pacman、msys2-keyring 和
pacman-mirrors 及其版本号，写入 `/etc/package-versions.txt`。并用 pacman 将其写入数据库中。如果其间遇到未找到目标的错误，把对应行删去即可。

```shell
yes |pacman -S $(cut -d ' ' -f 1 /etc/package-versions.txt) \
    man git git-extras mingw-w64-x86_64-git-lfs curl
```

修改 `/etc/pacman.conf`，关闭除 mingw64 和 msys 以外的所有软件源。下面是关闭了
mingw32 的示例。

```text
#[mingw32]
#Include = /etc/pacman.d/mirrorlist.mingw32
```


### pacman 的使用 {#pacman-的使用}

在使用之前，安装一个好用、称手的 shell 是头等大事。我可没有暗示 bash 不好用，我只是更喜欢 fish shell 而已。当然，我还是推建以下几种 shell

bash
: 最通用的 shell，一般也是默认的 shell

tcsh
: 继承自 csh 的 shell，也是 bsd 世界的默认 shell，语法不兼容 bash

zsh
: 语法兼容 bash 的 shell，扩展性强，近年很流行与 Oh-my-zsh 使用

fish
: 语法不兼容 bash 的 shell，扩展性不如 zsh，单交互模式体验很好

通常我使用 shell 的配置文件添加包管理器的命令别命，方便使用。

| 缩写 | 操作         | 备注     |
|----|------------|--------|
| ref | refresh      | 刷新所有软件源 |
| in  | install      | 安装包   |
| arm | autoremove   | 移除不再需要的包 |
| rm  | remove       | 移除包   |
| dup | dist-upgrade | 发行版升级 |
| lu  | list-updates | 列出需要升级的包 |
| up  | update       | 升级包   |
| if  | info         | 获取包信息 |
| se  | search       | 查询包   |
| cln | clean        | 清除本地缓存 |
| ve  | verify       | 验证包完整性 |

```shell
alias Pref="pacman -Sy"
alias Pin="pacman -S"
alias Parm="pacman -Qdtq |pacman -Rs -"
alias Prm="pacman -Rs"
alias Pdup="pacman -Syuu"
alias Plu="pacman -Qu"
alias Pup="pacman -Su"
alias Pif="pacman -Si"
alias Pse="pacman -Ss"
alias Pcln="pacman -Scc"
alias Pve="pacman -Dk"
```

```fish
abbr -a Pref "pacman -Sy"
abbr -a Pin  "pacman -S"
abbr -a Parm "pacman -Qdtq |pacman -Rs -"
abbr -a Prm  "pacman -Rs"
abbr -a Pdup "pacman -Syuu"
abbr -a Plu  "pacman -Qu"
abbr -a Pup  "pacman -Su"
abbr -a Pif  "pacman -Si"
abbr -a Pse  "pacman -Ss"
abbr -a Pcln "pacman -Scc"
abbr -a Pve  "pacman -Dk"
```


## 已知的问题 {#已知的问题}

-   curl: (77) error setting certificate verify locations

    这个问题是因为 `mingw-w64-x86_64-ca-certificates` 包调用 `p11-kit` 时发生错误，Git
    的默认安装路径为 `/c/Program Files/Git`，而 p11-kit 执行时将 Program 作为一个命令执行。因此在安装 Git 时，应避免使用带空格的路径或中文路径。


## Useful Link {#useful-link}

-   [Git Pro](https://git-scm.com/book/en/v2)
-   [MSYS2](https://www.msys2.org)
-   [MSYS2 Packages](https://packages.msys2.org/package/)
-   [pacman](https://wiki.archlinux.org/title/pacman)
-   She sells seashells
    -   [bash](https://www.gnu.org/software/bash)
    -   [tcsh](https://www.tcsh.org)
    -   [Zsh](https://www.zsh.org)
    -   [fish](https://fishshell.com)

