# Git Configurations


使用 git 时不止要为 git 的复杂性头疼，还需要为 git 的配置文件头疼。当然这一切的来源都是多用户配置的需求：我需要多账户设置，比如个人账户和组织账户，但它们都是
github 账号。

需要注意的一点是，如果你不知道你在干什么，或者具体某个选项的含义，请不要尝试！


## 配置文件 {#配置文件}

什么是配置文件呢？简单地说就是帮你配置一个软件行为的一系列文本文件，当然有些软件使用图形化配置或者注册表、dconf 之类的二进制配置文件或者编程语言。不过，用途都是一样的。

那么一般来说配置文件存放在哪里呢：**每个软件都不一样**。不过当然，还是有一些约定俗成的位置的。

以 git 为例，默认的全局配置文件存放在 **$HOME/.gitconfig** 中，这是个单文件配置。如果你比较不爽想要拆分文件，可以放在大名鼎鼎的 **$XDG_CONFIG_HOME/git/config** 中。至于 `$XDG_CONFIG_HOME` 这个目录嘛，这就是大家最喜欢创建一个名为 **dotfiles** repo 管理起来的地方，通常 Linux 上的配置文件都可以存放于此。其默认值一般为
`$HOME/.config`。git 还支持每个 repo 不同的配置文件，可以放在 `$REPO/.git/config` 中。

另外一个本篇需要的软件是 ssh，其配置文件默认存放在 `$HOME/.ssh` 中。


## ssh config {#ssh-config}

ssh 的配置比较简单，简单地总结一下就是以下格式：

```fundamental
# Comment
Host <HostAlias> [<HostAlias>...]
    Hostname <Host>
    User <User>
    Port <Port>
    PreferredAuthentications publickey
    IdentityFile <SSH-key-path>
```

以我配置的 gitlab 设置为例：

```fundamental
# https://docs.github.com/en/authentication/troubleshooting-ssh/using-ssh-over-the-https-port
Host github
    Hostname ssh.github.com
    User git
    Port 443
    PreferredAuthentications publickey
    IdentityFile /home/ginshio/.ssh/personal-git
```

当我想要测试能否连接时，只需要使用 `HostAlias` 就行：

```shell
ssh -T github
```

当然，ssh 的配置文件也是支持拆分的，只需要在 config 里加入要引入的路径即可：

```fundamental
Include config.d/*.conf
```


## git config {#git-config}

需要注意的是，git 配置文件是按照顺序执行的，也就是在文件后面的配置可能覆盖掉之前的配置。这在本篇配置中是很有用的。


### Core {#core}

首先看看名为 `core` 的配置选项，对我个人来说最重要的是 **autocrlf**, **editor** 和
**excludesFile**。

```fundamental
[core]
    autocrlf = false
    editor = "emacsclient -nw"
    excludesFile = /home/ginshio/.config/git/ignore
```

crlf 是指行尾换行符，这对 Windows 用户相当重要，主要来源于 Windows 默认的换行符是 `\r\n`，即 **CRLF**；而在类 Unix 系统上换行符都是 `\n`。但是问题是大部分项目会要求源代码的换行符遵循 LF 格式，因此 Windwos 用户可能需要让 Git 来帮忙做一次自动转换。不过也有很多问题来自于此。

editor 是 git 默认使用的编辑器，在不设置该选项时使用系统环境变量 `EDITOR`。

excludesFile 是一个全局的文件忽略，可以让你忽略掉一些平台相关或者个人习惯导致的不想被追踪的文件。该选项的默认值是 `$HOME/.gitignore`。比如说我的全局配置里就总会忽略掉 lsp、python、diff 以及 build 目录，当然还有些平台相关的无用文件（臭名昭著的 `.DS_Store`。

```fundamental
# Ignore build directory and C/C++ Compilation Database
/_build/
/_install/
/compile_commands.json
/.cache/

# be found at https://github.com/github/gitignore/blob/main/Python.gitignore
# Ignore Python - Byte-compiled / optimized / DLL files
__pycache__/
*.py[cod]
*$py.class
# Ignore Python - Environments
.env
.venv
env/
venv/
ENV/
env.bak/
venv.bak/

# be found at https://github.com/github/gitignore/blob/main/Global/Diff.gitignore
*.patch
*.diff
```


### Merge {#merge}

Merge 是个很强大的功能，不过在冲突时确实很头痛。

```fundamental
[merge]
    conflictstyle = diff3
    tool = ediff

[mergetool.ediff]
    cmd = emacsclient -nw --eval \" (progn (defun ediff-write-merge-buffer () (let ((file ediff-merge-store-file)) (set-buffer ediff-buffer-C) (write-region (point-min) (point-max) file) (message \\\"Merge buffer saved in: %s\\\" file) (set-buffer-modified-p nil) (sit-for 1))) (setq ediff-quit-hook 'kill-emacs ediff-quit-merge-hook 'ediff-write-merge-buffer) (ediff-merge-files-with-ancestor \\\"$LOCAL\\\" \\\"$REMOTE\\\" \\\"$BASE\\\" nil \\\"$MERGED\\\"))\"
```

首先是辨别冲突，git 的默认只会显示 A (HEAD) 和 B (TARGET) 之间的冲突，当然在某些情况下并不容易解决，有时候也需要知道我是基于什么来修改的。**diff3** 就是一个很好的选择。

```fundamental
<<<<<<< HEAD
THIS IS USEFUL
||||||| merged common ancestors
This is useful
=======
This is really useful
>>>>>>> c2392943.....
```

另一个就是 mergetool，它是一个帮你来解决冲突的工具，它很好用，但请阅读[官方手册](https://git-scm.com/docs/git-mergetool)。我是 emacs 用户，自然而然地使用 `ediff` 很正常吧。vim 用户可以选择 `vimdiff` 来作为
mergetool。

当配置好 mergetool 后，你就可以用它来解决你的冲突了：

```shell
git mergetool <ConflictedFile>
```


### Identify 和 URL 替换 {#identify-和-url-替换}

困扰我最大的问题就是多用户，这个问题在工作项目在 Github 上开源的话尤其严重：组织项目应该用组织账户来提交代码，而其他项目应该使用个人账户。另外如果是私有组织的话，且个人私钥与组织私钥不混用的时候，也是需要区分的。我是个懒狗，不想每个仓库去配置。

不过 git 给了一个相当不错的解决方法：[includeIf](https://git-scm.com/docs/git-config#_includes)。它可以让你为不同**路径**、**分支**或者
**URL** 来分别进行不同的配置。因此在这个问题上，我选择使用对 URL 进行配置，当然你如果把项目都放在某个目录下也可以对路径配置。


#### 个人配置 {#个人配置}

首先是自己的个人配置，这样 github 组织的配置就可以覆盖个人配置。个人的 ssh 配置就不用多说了，就是上面提到的。而 git 配置呢，我们分别对 https 和 ssh 两种 url 做匹配：

```fundamental
[includeIf "hasconfig:remote.*.url:https://*github.com/**"]
    path = personal_github.conf

[includeIf "hasconfig:remote.*.url:git@github.com:*/**"]
    path = personal_github.conf
```

这样，如果你的 repo 来自于 github 那它就会使用 `personal_github.conf`！我们在这个文件里来魔改一下它的 URL 和 Identify。毕竟我们如果要 push 代码或者 pull 私有仓库的话，都是需要 HTTPS 的 key 或者 ssh key 的。另外，我们是多账户的，默认 Github
用我们自己的就够了。

```fundamental
[url "github:"]
    insteadOf = git@github.com:
    pushInsteadOf = https://github.com/

[user]
    name = GinShio
    email = ginshio78@gmail.com
```

默认仓库的话，https 是可以任意获取代码的，因此我们就不用修改其 **fetch** url 了；而
ssh url 我们将其 **fetch** 和 **push** url 都修改为之前在 ssh config 中的 `HostAlias`。


#### 组织配置 {#组织配置}

对于组织的话，我们采用不同 ssh key，但它们的 host 等信息都是相同的，我们需要给它一个不同的 `HostAlias`：就叫 **MyOrg** 好了。

与个人配置类似，也是先用 includeIf 来匹配组织的 url。

```fundamental
[includeIf "hasconfig:remote.*.url:https://*github.com/MyOrg/**"]
    path = org_github.conf

[includeIf "hasconfig:remote.*.url:git@github.com:MyOrg/**"]
    path = org_github.conf
```

与个人配置类似，需要修改 url。需要注意的是：

-   我们已经重载过 github 的 url 了，为了避免报错，我们需要加上组织名称。
-   有可能组织是私有不可见的，因此我们将所有 **fetch** 和 **push** url 全替换为 ssh
    HostAlias。
-   由于之前个人配置中将 https url 只替换了 push url，我们需要提别地再添加一条替换 https push url 的规则。

<!--listend-->

```fundamental
[url "MyOrg:MyOrg"]
    insteadOf = git@github.com:MyOrg
    insteadOf = https://github.com/MyOrg
    pushInsteadOf = https://github.com/MyOrg

[user]
    name = GinShio-Work
    email = ginshio@work.com
```

当然如果你们有多个组织，且它们都以某个前缀开始，那么正则匹配也是不错的选择。

```fundamental
[includeIf "hasconfig:remote.*.url:https://*github.com/MyOrg*/**"]
    path = org_github.conf
```


## 我的配置 {#我的配置}

如果你对我的配置感兴趣，可以参考我的配置：<https://github.com/GinShio/dotfiles.git>

