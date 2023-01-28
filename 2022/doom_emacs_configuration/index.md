# Doom Emacs 配置文件


{{< admonition type="info" >}}
本篇是基于 [tecosaur](http://tecosaur.com/) 的 [Emacs 配置](https://github.com/tecosaur/emacs-config) 大幅缩减版本，如果你对 Org Mode 感兴趣可以看他制作的 [This Month in Org](https://blog.tecosaur.com/tmio/)。

本篇标题和副标题均采用原标题的中译

-   **Title**: Doom Emacs Configuration
-   **Subtitle**: The Methods, Management, and Menagerie of Madness --- in meticulous detail
{{< /admonition >}}

> 让我们改变对程序构建的传统态度：与其想象我们的主要任务是指导计算机做什么，不如专注于向人们解释我们想让计算机做什么。
> --- 高德纳


## 引言 {#引言}

与其说不喜欢 IDE，倒不如说现在太菜了用不上 IDE，况且 Linux 下除了 JetBrains 家的也没其他能用的了。

不过这都是后话了，最初用的是 `Dev-C++` 和 `VS 2017` ，说实话 VS 好看但太大了，对我这种写 _Hello World_ 的人来说太浪费了。其实简单说就是，VS 太大不会用，JetBrains
太贵买不起，虽然是学生可以申请免费全家桶，但 `CLion` 不像 _Intellij IDEA_ 或者
_PyCharm_ 它没免费版啊。也就尝试着 `Notepad++` 了，当时并没什么政治倾向。也就当一个自带高亮的记事本， `Dev-C++` 改用还得用啊。

在用编辑器时听闻了 `Vim` 、 `Linux` 等软件，爷投 `*nix` 了！所以 `Notepad++` 也用不上了，选来选去选了个 **Emacs** ，多少开始离谱起来了，因为我觉得 Vim 的且模式好麻烦。不过好在这种玩意一招鲜吃遍天，你可以为其添加任意语言的支持，什么 _Intellij IDEA_ 、
_PyCharm_ 还要分，太麻烦了，就问你能加 `Erlang` 、 `Elixir` 、 `Haskell` 等支持吗 (这不巧了吗，还都能加)。况且用 shell 时默认的快捷键也是和 Emacs 一致的。

怎么不用 Vim，因为我不喜欢切换模式啊。所以我现在也不用 `evil` 或 [meow](https://github.com/meow-edit/meow) ，不过很推荐尝试一下 meow。怎么不用 `VSCode` ，其实当时也没什么 VSCode， `Atom` 用不用啊，
`Sublime` 用不用啊。那当然是不用啊，不想再要一个 Chromium 啊，也不想买授权。hhhh

至于 Lisp 会不会啊，那肯定也是不会的啊，就只学会了 `New Jersey style` 和
`The MIT approach` 两个名词，干什么用，可以装 B 可以嘲讽你说有用吗。


### Why Emacs {#why-emacs}

网上对于 Emacs 的推荐的文章很多，我就不说了，我就一菜鸡。

这里看看 [@tecosaur](https://github.com/tecosaur) 对于几个编辑器的比较

| Editor      | Extensibility | Ecosystem | Ease of Use | Comfort | Completion | Performance |
|-------------|---------------|-----------|-------------|---------|------------|-------------|
| IDLE        | 1             | 1         | 3           | 1       | 1          | 2           |
| VSCode      | 3             | 3         | 4           | 3.5     | 4          | 3           |
| Brackets    | 2.5           | 2         | 3           | 3       | 2.5        | 2           |
| Emacs       | 4             | 4         | 2           | 4       | 3.5        | 3           |
| Komodo Edit | 2             | 1         | 3           | 2       | 2          | 2           |

{{< figure src="/images/editor-comparison.svg" alt="Radar chart comparing my thoughts on a few editors." class="invertible" width="80%" >}}

这种表有很强的主观印象，不过对于编辑器，还是推荐 VSCode、Emacs 和 Vim。我只是喜欢编辑器在编辑方面极强的扩展优势，对于 Everything (比如 mu4e, EAF)，我的兴趣并不高，或许因为它们又麻烦又没有 FF / Thunderbird 好用？

最后还是要说一下，Emacs 的优势，

-   递归编辑
-   普遍的文档字符串，以及完全的内省性
-   在可变环境中的増量修改
-   无需特定应用启用功能
-   允许客户端、服务器分离，启动守护进程，提供几乎无感知的启动时间

尤其是 **Org-mode** ，全球独此一家！


### Issues {#issues}

-   Emacs 有一些令人厌烦的奇怪操作
-   某些方面很暴露年龄 (名称约定、API 等)
-   Emacs [几乎](https://www.gnu.org/software/emacs/manual/html_node/elisp/Threads.html) 是单线程的，这意味着一些不当的操作将阻塞整个应用
-   一些其他方面的干扰……

说实话，我是个 Emacs 「低手」，并不是高手。所以 ELisp 有点痛苦，不过还好吧，起码会算 `(+ 1 1)`。


## 基础配置 {#基础配置}

创建词法绑定可以 (稍微) 加速配置文件的运行。 (更多内容可以查看 [这篇博客](https://nullprogram.com/blog/2016/12/22/))

```emacs-lisp
;;; config.el -*- lexical-binding: t; -*-
```

配置有用且基础的个人信息

```emacs-lisp
(setq user-full-name "GinShio"
      user-mail-address "ginshio78@gmail.com"
      user-gpg-key "9E2949D214995C7E"
      wakatime-api-key "cb5cccd0-e5a0-4922-abfd-748a42a96cae"
      org-directory "~/org")
```

显然这可以被 GPG 或其他程序使用。


### 设置默认值 {#设置默认值}

尝试一下别人的默认值，比如 [angrybacon/dotemacs](https://github.com/angrybacon/dotemacs/blob/master/dotemacs.org#use-better-defaults)

```emacs-lisp
(setq-default
 delete-by-moving-to-trash t        ; 将文件删除到回收站
 window-combination-resize t        ; 从其他窗口获取新窗口的大小
 x-stretch-cursor t                 ; 将光标拉伸到字形宽度
 )

(setq! undo-limit 104857600         ; 重置撤销限制到 100 MiB
       auto-save-default t          ; 没有人喜欢丢失工作，我也是如此
       truncate-string-ellipsis "…" ; Unicode 省略号相比 ascii 更好
				    ; 同时节省 /宝贵的/ 空间
       password-cache-expiry nil    ; 我能信任我的电脑 ... 或不能?
       ; scroll-preserve-screen-position 'always
				    ; 不要让 `点' (光标) 跳来跳去
       scroll-margin 2              ; 适当保持一点点边距
       gc-cons-threshold 1073741824
       read-process-output-max 1048576
       )

(remove-hook 'text-mode-hook #'visual-line-mode)
(add-hook 'text-mode-hook #'auto-fill-mode)
(add-hook! 'window-setup-hook #'toggle-frame-fullscreen)
				    ; 设置最大化启动
;;(display-time-mode t)             ; 开启时间状态栏
(require 'battery)
(when (and battery-status-function
	   (not (string-match-p "N/A"
				(battery-format "%B"
						(funcall battery-status-function)))))
  (display-battery-mode 1))         ; 知道还剩多少 ⚡️ 很重要

(global-subword-mode 1)             ; 识别驼峰，而不是傻瓜前进
(global-unset-key (kbd "C-z"))      ; 关闭 "C-z" 最小化
(define-key! global-map "C-s" #'+default/search-buffer)
(map! (:leader (:desc "load a saved workspace" :g "wr" #'+workspace/load))) ;; workspace load keybind

(when IS-WINDOWS
  (setq-default buffer-file-coding-system 'utf-8-unix)
  (set-default-coding-systems 'utf-8-unix)
  (prefer-coding-system 'utf-8-unix))
				    ; 将 Windows 上的编码改为 UTF-8 Unix 换行

(custom-set-variables '(delete-selection-mode t) ;; delete when you select region and modify
		      '(delete-by-moving-to-trash t) ;; delete && move to transh
		      '(inhibit-compacting-font-caches t) ;; don’t compact font caches during GC.
		      '(gc-cons-percentage 1))

(add-hook 'prog-mode-hook (lambda () (setq show-trailing-whitespace 1)))
				    ; 编程模式下让结尾的空白符亮起
```

定义一个自己的 key leader，或许没什么用

```emacs-lisp
(after! general
  (general-create-definer ginshio/leader :prefix "s-y"))
```

默认情况下通过自定义界面所做的修改会被添加到 `init.el` 中。不过正常的方法是将它们放在 `.custom.el` 中。

```emacs-lisp
(setq-default custom-file (expand-file-name ".custom.el" doom-private-dir))
(when (file-exists-p custom-file) (load custom-file))
```

设置一个方便的在 window 之间进行切换的快捷键。

```emacs-lisp
(map! :map ctl-x-map
      "<left>"   #'windmove-left
      "<down>"   #'windmove-down
      "<up>"     #'windmove-up
      "<right>"  #'windmove-right
      )
```

如果是 evil 用户可以改为下面这种

```emacs-lisp
(map! :map evil-window-map
      "SPC" #'rotate-layout
      ;; 方向
      "<left>"   #'evil-window-left
      "<down>"   #'evil-window-down
      "<up>"     #'evil-window-up
      "<right>"  #'evil-window-right
      ;; 交换窗口
      "C-<left>"   #'+evil/window-move-left
      "C-<down>"   #'+evil/window-move-down
      "C-<up>"     #'+evil/window-move-up
      "C-<right>"  #'+evil/window-move-right
      )
```


### Doom 配置 {#doom-配置}

拉取 doom-emacs 仓库的分支

-   git commit: **aed2972d74**
-   doom-version: **3.0.0-dev**
-   doom-modules-version: **21.12.0-dev**


#### 模组 {#模组}

<a id="code-snippet--init.el"></a>
```emacs-lisp { collapsed="t" }
;;; init.el -*- lexical-binding: t; -*-

;; This file controls what Doom modules are enabled and what order they load
;; in. Remember to run 'doom sync' after modifying it!

;; NOTE Press 'SPC h d h' (or 'C-h d h' for non-vim users) to access Doom's
;;      documentation. There you'll find a link to Doom's Module Index where all
;;      of our modules are listed, including what flags they support.

;; NOTE Move your cursor over a module's name (or its flags) and press 'K' (or
;;      'C-c c k' for non-vim users) to view its documentation. This works on
;;      flags as well (those symbols that start with a plus).
;;
;;      Alternatively, press 'gd' (or 'C-c c d') on a module to browse its
;;      directory (for easy access to its source code).

(doom! :input
       <<doom-input>>

       :completion
       <<doom-completion>>

       :ui
       <<doom-ui>>

       :editor
       <<doom-editor>>

       :emacs
       <<doom-emacs>>

       :term
       <<doom-term>>

       :checkers
       <<doom-checkers>>

       :tools
       <<doom-tools>>

       :os
       <<doom-os>>

       :lang
       <<doom-lang>>

       :email
       <<doom-email>>

       :app
       <<doom-app>>

       :config
       <<doom-config>>
       )
```

<!--list-separator-->

-  结构

    这是一篇文学编程，同时也是 Doom Emacs 的配置文件。Doom 对其支持良好，更多详情可以通过 `literate` (文学) 模块了解。

    <a id="code-snippet--doom-config"></a>
    ```emacs-lisp
    literate
    (default +bindings +smartparens)
    ```

<!--list-separator-->

-  接口

    可以做很多事来增强 Emacs 的功能，。

    输入
    : 中日文输入与键盘布局，我主要依赖系统输入法 fcitx 且不输入法语，因此不开此选项
        <a id="code-snippet--doom-input"></a>
        ```emacs-lisp
        ;;chinese
        ;;japanese
        ;;layout                     ; auie,ctsrnm is the superior home row
        ```


    补全
    : 或许叫补全有点不合适，不过也就这样了。另外说一下， `helm` 、 `ido` 、 `ivy` 以及 `vertico` 是功能一致的，生态不同的四个包
        <a id="code-snippet--doom-completion"></a>
        ```emacs-lisp
        company             ; the ultimate code completion backend
        ;;helm              ; the *other* search engine for love and life
        ;;ido               ; the other *other* search engine...
        ;;(ivy              ; a search engine for love and life
        ;; +icons           ; ... icons are nice
        ;; +prescient)      ; ... I know what I want(ed)
        (vertico +icons)    ; the search engine of the future
        ```


    UI
    : 好不好看就看你这么配置了
        <a id="code-snippet--doom-ui"></a>
        ```emacs-lisp
        ;;deft              ; notational velocity for Emacs
        doom                ; what makes DOOM look the way it does
        doom-dashboard      ; a nifty splash screen for Emacs
        doom-quit           ; DOOM quit-message prompts when you quit Emacs
        (emoji
         +unicode +github)  ; 🙂
        hl-todo             ; highlight TODO/FIXME/NOTE/DEPRECATED/HACK/REVIEW
        ;;hydra
        ;;indent-guides     ; highlighted indent columns
        (ligatures +extra)  ; ligatures and symbols to make your code pretty again
        ;;minimap           ; show a map of the code on the side
        modeline            ; snazzy, Atom-inspired modeline, plus API
        nav-flash           ; blink cursor line after big motions
        ;;neotree           ; a project drawer, like NERDTree for vim
        ophints             ; highlight the region an operation acts on
        (popup              ; tame sudden yet inevitable temporary windows
         +all               ; catch all popups that start with an asterix
         +defaults)         ; default popup rules
        ;;tabs              ; a tab bar for Emacs
        treemacs            ; a project drawer, like neotree but cooler
        ;;unicode           ; extended unicode support for various languages
        vc-gutter           ; vcs diff in the fringe
        vi-tilde-fringe     ; fringe tildes to mark beyond EOB
        (window-select      ; visually switch windows
         +numbers)
        workspaces          ; tab emulation, persistence & separate workspaces
        zen                 ; distraction-free coding or writing
        ```


    编辑器
    : **VI VI VI Editor of the Beast**
        <a id="code-snippet--doom-editor"></a>
        ```emacs-lisp
        ;;(evil +everywhere); come to the dark side, we have cookies
        file-templates      ; auto-snippets for empty files
        fold                ; (nigh) universal code folding
        (format +onsave)    ; automated prettiness
        ;;god               ; run Emacs commands without modifier keys
        ;;lispy             ; vim for lisp, for people who don't like vim
        multiple-cursors    ; editing in many places at once
        ;;objed             ; text object editing for the innocent
        ;;parinfer          ; turn lisp into python, sort of
        rotate-text         ; cycle region at point between text candidates
        snippets            ; my elves. They type so I don't have to
        ;;word-wrap         ; soft wrapping with language-aware indent
        ```


    Emacs
    : 增强一下吧，不然真的是笔记本了 (其实不是
        <a id="code-snippet--doom-emacs"></a>
        ```emacs-lisp
        (dired +icons)      ; making dired pretty [functional]
        electric            ; smarter, keyword-based electric-indent
        (ibuffer +icons)    ; interactive buffer management
        undo                ; persistent, smarter undo for your inevitable mistakes
        vc                  ; version-control and Emacs, sitting in a tree
        ```


    终端
    : 也许我应该卸载掉我的 `Konsole`
        <a id="code-snippet--doom-term"></a>
        ```emacs-lisp
        ;;eshell            ; the elisp shell that works everywhere
        ;;shell             ; simple shell REPL for Emacs
        ;;term              ; basic terminal emulator for Emacs
        vterm               ; the best terminal emulation in Emacs
        ```


    检测
    : 可以告诉我哪里不对，但我觉得我应该先好好背背单词或者看看 PEP8
        <a id="code-snippet--doom-checkers"></a>
        ```emacs-lisp
        syntax              ; tasing you for every semicolon you forget
        (:if (or (executable-find "hunspell")
        	 (executable-find "aspell")) spell) ; tasing you for misspelling mispelling
        ;;grammar           ; tasing grammar mistake every you make
        ```


    工具
    : Workflow in Emacs!
        <a id="code-snippet--doom-tools"></a>
        ```emacs-lisp
        ansible
        biblio              ; Writes a PhD for you (citation needed)
        (debugger +lsp)     ; FIXME stepping through code, to help you add bugs
        ;;direnv
        ;;docker
        ;;editorconfig      ; let someone else argue about tabs vs spaces
        ;;ein               ; tame Jupyter notebooks with emacs
        (eval +overlay)     ; run code, run (also, repls)
        ;;gist              ; interacting with github gists
        (lookup             ; helps you navigate your code and documentation
         +dictionary        ; dictionary/thesaurus is nice
         +docsets)          ; ...or in Dash docsets locally
        (lsp +peek)         ; M-x vscode
        (magit              ; a git porcelain for Emacs
         +forge)            ; interface with git forges
        make                ; run make tasks from Emacs
        ;;pass              ; password manager for nerds
        pdf                 ; pdf enhancements
        ;;prodigy           ; FIXME managing external services & code builders
        rgb                 ; creating color strings
        ;;taskrunner        ; taskrunner for all your projects
        ;;terraform         ; infrastructure as code
        ;;tmux              ; an API for interacting with tmux
        ;;upload            ; map local to remote projects via ssh/ftp
        ```


    OS
    : 有个问题，我会用 MAC 吗
        <a id="code-snippet--doom-os"></a>
        ```emacs-lisp
        (:if IS-MAC macos)  ; improve compatibility with macOS
        tty                 ; improve the terminal Emacs experience
        ```

<!--list-separator-->

-  编程语言支持

    最爽的事情就是，我可以在 Emacs 中编写任何语言 (的 `Hello World`)

    <a id="code-snippet--doom-lang"></a>
    ```emacs-lisp
    ;;agda              ; types of types of types of types...
    ;;beancount         ; mind the GAAP
    (cc +lsp)           ; C > C++ == 1
    ;;clojure           ; java with a lisp
    ;;common-lisp       ; if you've seen one lisp, you've seen them all
    ;;coq               ; proofs-as-programs
    ;;crystal           ; ruby at the speed of c
    ;;csharp            ; unity, .NET, and mono shenanigans
    data                ; config/data formats
    ;;(dart +flutter)   ; paint ui and not much else
    ;;dhall
    (elixir +lsp)       ; erlang done right
    ;;elm               ; care for a cup of TEA?
    emacs-lisp          ; drown in parentheses
    (erlang +lsp)       ; an elegant language for a more civilized age
    ;;ess               ; emacs speaks statistics
    ;;factor
    ;;faust             ; dsp, but you get to keep your soul
    ;;fortran           ; in FORTRAN, GOD is REAL (unless declared INTEGER)
    ;;fsharp            ; ML stands for Microsoft's Language
    ;;fstar             ; (dependent) types and (monadic) effects and Z3
    ;;gdscript          ; the language you waited for
    ;;(go +lsp)         ; the hipster dialect
    ;;(haskell +lsp)    ; a language that's lazier than I am
    ;;hy                ; readability of scheme w/ speed of python
    ;;idris             ; a language you can depend on
    json                ; At least it ain't XML
    ;;(java +lsp)       ; the poster child for carpal tunnel syndrome
    (javascript +lsp)   ; all(hope(abandon(ye(who(enter(here))))))
    ;;julia             ; a better, faster MATLAB
    ;;kotlin            ; a better, slicker Java(Script)
    (latex              ; writing papers in Emacs has never been so fun
     +latexmk           ; what else would you use?
     +cdlatex           ; quick maths symbols
     +fold)             ; fold the clutter away nicities
    ;;lean              ; for folks with too much to prove
    ;;ledger            ; be audit you can be
    lua                 ; one-based indices? one-based indices
    markdown            ; writing docs for people to ignore
    ;;nim               ; python + lisp at the speed of c
    ;;nix               ; I hereby declare "nix geht mehr!"
    ;;ocaml             ; an objective camel
    (org                ; organize your plain life in plain text
     +pretty            ; yessss my pretties! (nice unicode symbols)
     +dragndrop         ; drag & drop files/images into org buffers
     +hugo              ; use Emacs for hugo blogging
     ;;+noter           ; enhanced PDF notetaking
     ;;+jupyter         ; ipython/jupyter support for babel
     +pandoc            ; export-with-pandoc support
     +gnuplot           ; who doesn't like pretty pictures
     ;;+pomodoro        ; be fruitful with the tomato technique
     +present           ; using org-mode for presentations
     ;; +roam2          ; wander around notes
     )
    ;;php               ; perl's insecure younger brother
    ;;plantuml          ; diagrams for confusing people more
    ;;purescript        ; javascript, but functional
    (python             ; beautiful is better than ugly
     +pyenv
     +lsp
     +pyright)
    qt                  ; the 'cutest' gui framework ever
    ;;racket            ; a DSL for DSLs
    ;;raku              ; the artist formerly known as perl6
    ;;rest              ; Emacs as a REST client
    ;;rst               ; ReST in peace
    ;;(ruby +rails)     ; 1.step {|i| p "Ruby is #{i.even? ? 'love' : 'life'}"}
    ;;(rust +lsp)       ; Fe2O3.unwrap().unwrap().unwrap().unwrap()
    ;;scala             ; java, but good
    ;;(scheme +guile)   ; a fully conniving family of lisps
    sh                  ; she sells {ba,z,fi}sh shells on the C xor
    ;;sml
    ;;solidity          ; do you need a blockchain? No.
    ;;swift             ; who asked for emoji variables?
    ;;terra             ; Earth and Moon in alignment for performance.
    web                 ; the tubes
    yaml                ; JSON, but readable
    ;;zig               ; C, but simpler
    ```

<!--list-separator-->

-  Everything in Emacs

    **leave** Emacs

    邮件
    : 说实话，我想用 `Thunderbird`
        <a id="code-snippet--doom-email"></a>
        ```emacs-lisp
        ;;(mu4e +org +gmail)
        ;;notmuch
        ;;(wanderlust +gmail)
        ```


    应用
    : 可以在 Emacs 中上网看新闻。或许我可以用 irc 聊天
        <a id="code-snippet--doom-app"></a>
        ```emacs-lisp
        ;;calendar
        ;;emms
        everywhere          ; *leave* Emacs!? You must be joking
        irc                 ; how neckbeards socialize
        ;;(rss +org)        ; emacs as an RSS reader
        ;;twitter           ; twitter client https://twitter.com/vnought
        ```


#### 视觉设置 {#视觉设置}

<!--list-separator-->

-  字体设置

    'Source Code Pro' 和 'Fira Code' 的效果都很不错，'JetBrains Mono' 和 'IBM Plex Mono'
    或许也不错。还是比较推荐 Mono 字体，等宽看代码舒服。

    Unicode 字体为什么不试试 'JuliaMono' 呢？

    ```emacs-lisp
    (setq doom-font (font-spec :family "Source Code Pro" :size 15)
          doom-big-font (font-spec :family "Source Code Pro" :size 30)
          doom-variable-pitch-font (font-spec :family "Source Code Variable" :size 15)
          doom-unicode-font (font-spec :family "JuliaMono")
          doom-serif-font (font-spec :family "TeX Gyre Cursor")
          )
    ```

    不过这都是西文字体，没有考虑过 CJK 用户的感受吗！！在后面的
    [杂项](#杂项) 中，将详细说一下 CJK 字体的配置。

    除了这些字体外，字体 [Merriweather](https://github.com/SorkinType/Merriweather/) 还被用于 `nov.el` 中，字体 [Alegreya](https://github.com/huertatipografica/Alegreya) 作为衬线比例字体被用于 Org 文件的 `writeroom-mode` 中的 `mixed-pitch-mode` 。

<!--list-separator-->

-  主题和 modeline

    `doom-one` 是 Doom 自带的大而全的主题，里面实在太多好看的主题了，干嘛还要自己找。这里我想在众多我喜欢的主题中，启动时随机选取一款。

    ```emacs-lisp
    (setq doom-theme (let ((themes '(doom-vibrant
    				 doom-fairy-floss
    				 doom-dracula
    				 doom-Iosvkem
    				 doom-moonlight
    				 doom-monokai-pro
    				 doom-tokyo-night)))
    		   (elt themes (random (length themes)))))
    ```

    当然你不喜欢这样，可以直接指定一款。

    ```emacs-lisp
    (setq doom-theme 'doom-vibrant)
    ```

    设置一下 modeline，比如说图标、文件名称以及彩虹猫 (Nyan cat)！

    ```emacs-lisp
    (after! doom-modeline
      (custom-set-variables '(doom-modeline-buffer-file-name-style 'relative-to-project)
    			'(doom-modeline-major-mode-icon t)
    			'(doom-modeline-modal-icon nil))
      (nyan-mode t))
    ```

<!--list-separator-->

-  杂项

    相对行号可以很好的知道距离目标行有多远，然后用快捷键 `C-u num <UP>` 或
    `ESC num <UP>` 到达你想去的行。

    ```emacs-lisp
    (setq display-line-numbers-type 'relative)
    ```

    我想设置一下更好看的默认缓冲区名称

    ```emacs-lisp
    (setq doom-fallback-buffer-name "► Doom"
          +doom-dashboard-name "► Doom")
    ```

    再来说说初始化 doom 时，UI 上其实还有很多能做的，比如说关闭丑的不行的 `menu-bar` ，设置光标模式，以及 CJK 字体等。

    需要说明一下，字体在 GUI 下是有效的，TUI 下使用的应该是终端设置。另外，使用 mono
    字体时，CJK 一般是西文字号的 `1.2` 倍，这样一个 CJK 符号将是西文符号的 `2` 倍。比较建议西文字体设置为 `5` 的倍数，这样得到的 CJK 字符都能是一个整数值。

    ```emacs-lisp
    (defun ginshio/doom-init-ui-misc()
      (menu-bar-mode -1)               ;; disable menu-bar
      (setq-default cursor-type 'box)  ;; set box style cursor
      (blink-cursor-mode -1)           ;; cursor not blink
      <<doom-dashboard-layout>>
      (if (display-graphic-p)
          (progn
    	;; NOTE: ONLY GUI
    	;; set font
    	(dolist (charset '(kana han symbol cjk-misc bopomofo gb18030))
    	  (set-fontset-font (frame-parameter nil 'font) charset
    			    (font-spec :family "Source Han Mono")))
    	(appendq! face-font-rescale-alist
    		  '(("Source Han Mono" . 1.2)
    		    ))
    	<<doom-image-banner>>
    	;; random banner image from bing.com, NOTE: https://emacs-china.org/t/topic/264/33
    	)
        (progn
          ;; NOTE: ONLY TUI
          <<doom-ascii-banner>>
          )))
    (add-hook! 'doom-init-ui-hook #'ginshio/doom-init-ui-misc)
    ```


#### 辅助宏 {#辅助宏}

这些是 doom 添加的一些非常有用的宏

-   `load!` 可以相对于本文件进行外部 `.el` 文件的加载
-   `use-package!` 用于配置包
-   `add-load-path!` 将指定目录添加到 `load-path` 中，可以让 Emacs 在使用
    `require` 和 `use-package` 时在 `load-path` 中进行查找
-   `map!` 用于绑定新的快捷键


#### 允许 CLI 运行 org-babel 程序 {#允许-cli-运行-org-babel-程序}

在 Org 中有时会写一点代码，[Org-Babel](https://orgmode.org/worg/org-contrib/babel) 就是各个语言在 Org-mode 中的巴别塔。大家都可以通过它来直接运行。

但是在配置文件也会有一些代码，如果在 CLI 中执行 `doom sync` 之类的操作，大量的代码块输出会直接污染输出。这不能忍！

好在 DOOM 提供了每次运行 CLI 前读取 `$DOOMDIR/cli.el` 的特性，我们可以不再手动确认是否运行某个代码块 (`org-confirm-babel-evaluate`)，并且用
`org-babel-execute-src-block` 来沉默这些代码块，避免污染输出。

```emacs-lisp
;;; cli.el -*- lexical-binding: t; -*-
(setq! org-confirm-babel-evaluate nil)
(advice-add 'org-babel-execute-src-block
	    :around #'(lambda (orig-fn &rest args)
			(quiet! (apply orig-fn args))))
```


#### dashboard {#dashboard}

Dashboard 是打开 Emacs 的主页，在这里添加一些常用命令是很舒服的。

```emacs-lisp
(map! :map +doom-dashboard-mode-map
      :desc "org agenda" "a" #'org-agenda
      :desc "find file" "f" #'find-file
      :desc "recent session" "R" #'doom/quickload-session
      :desc "recent files" "r" #'counsel-recentf
      :desc "config dir" "C" #'doom/open-private-config
      :desc "open config.org" "c" (cmd! (find-file (expand-file-name "config.org" doom-private-dir)))
      ;; :desc "open dotfile" "." (cmd! (doom-project-find-file "~/.config/"))
      :desc "notes (roam)" "n" #'org-roam-node-find
      :desc "switch buffer" "b" #'+vertico/switch-workspace-buffer
      ;; :desc "switch buffers (all)" "B" #'consult-buffer
      :desc "ibuffer" "i" #'ibuffer
      :desc "open project" "p" #'counsel-projectile-switch-project
      ;; :desc "set theme" "t" #'consult-theme
      :desc "quit" "q" #'save-buffers-kill-terminal
      :desc "documentation" "H" #'doom/help
      :desc "show keybindings" "h" (cmd! (which-key-show-major-mode)))
```

那现在 dashboard 所展示的命令并不是很有用了，移除掉它们

<a id="code-snippet--doom-dashboard-layout"></a>
```emacs-lisp
(remove-hook '+doom-dashboard-functions
	     #'doom-dashboard-widget-shortmenu)
(add-hook! '+doom-dashboard-mode-hook (hide-mode-line-mode 1)
	   (hl-line-mode 1))
```


### 其他设置 {#其他设置}


#### 窗口标题 {#窗口标题}

我更喜欢窗口展示缓冲区的名字，然后是项目文件夹 (如果可用)。

```emacs-lisp
(setq! frame-title-format
      '("%b – Doom Emacs"
	(:eval
	 (let ((project-name (projectile-project-name)))
	   (unless (string= "-" project-name)
	     (format "  -  [%s]" project-name))))))
```


#### 启动界面 {#启动界面}

[@tecosaur](https://github.com/tecosaur) 做了一个相当棒的启动画面，心动！但是太复杂了。我只是想简单的在每次重启时更换 banner，仅此而已。

<a id="code-snippet--doom-image-banner"></a>
```emacs-lisp
(setq! fancy-splash-image
       (let ((banners (directory-files (expand-file-name "banners" doom-private-dir)
				       'full (rx ".png" eos))))
	 (elt banners (random (length banners)))))
```

当然，不要忘记 ASCII banner

<a id="code-snippet--doom-ascii-banner"></a>
```emacs-lisp
(setq! ginshio/+doom-dashbord-ascii-banner
       (split-string (with-output-to-string
		       (call-process "cat" nil standard-output nil
				     (let ((banners (directory-files (expand-file-name "banners" doom-private-dir)
								     'full (rx ".txt" eos))))
				       (elt banners (random (length banners))))))
		     "\n" t))
(setq! +doom-dashboard-ascii-banner-fn
       #'(lambda ()
	   (mapc (lambda (line)
		   (insert (propertize (+doom-dashboard--center +doom-dashboard--width line)
				       'face 'doom-dashboard-banner) " ")
		   (insert "\n"))
		 ginshio/+doom-dashbord-ascii-banner)))
```


#### 守护进程 {#守护进程}

守护进程是个好东西，可惜我用的是 WSL，没有 `systemd` ，不过 [EmacsWiki](https://www.emacswiki.org/emacs/EmacsAsDaemon) 中还是列出了各种 Daemon 的方法。

Systemd (Not WSL)
: `~/.config/systemd/user/emacs.service`

<!--listend-->

```text
[Unit]
Description=Emacs text editor
Documentation=info:emacs man:emacs(1) https://gnu.org/software/emacs/

[Service]
Type=forking
ExecStart=/usr/bin/emacs --daemon
ExecStop=/usr/bin/emacsclient --no-wait --eval "(progn (setq kill-emacs-hook 'nil) (kill-emacs))"
Restart=on-failure

[Install]
WantedBy=default.target
```

Launchd (MacOS)
: `/Library/LaunchAgents/gnu.emacs.daemon.plist`

<!--listend-->

```text
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
    "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
 <plist version="1.0">
  <dict>
    <key>Label</key>
    <string>gnu.emacs.daemon</string>
    <key>ProgramArguments</key>
    <array>
      <string>/Applications/Emacs.app/Contents/MacOS/Emacs</string>
      <string>--daemon</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>ServiceDescription</key>
    <string>Gnu Emacs Daemon</string>
  </dict>
 </plist>
```

rc.d (FreeBSD)
: 这来自 FreeBSD 论坛的[讨论](https://forums.freebsd.org/threads/rc-d-daemon-as-user-emacs.83055/post-558902) `/etc/init.d/emacsd`
    <a id="code-snippet--emacsdaemon rc.d (freebsd) service"></a>
    ```bash
    #!/bin/sh
    #

    # PROVIDE: emacsd
    # REQUIRE: LOGIN
    # KEYWORD: shutdown

    . /etc/rc.subr

    name="emacsd"
    rcvar="${name}_enable"
    start_precmd="${name}_prestart"

    load_rc_config $name
    : "${emacsd_enable:="NO"}"
    : "${emacsd_user:="nobody"}"

    piddir="/var/run/${emacsd_user}"
    pidfile="${piddir}/${name}_daemon.pid"
    pidfile_child="${piddir}/${name}_emacs.pid"
    user_id="$(id -u ${emacsd_user}"
    emacsd_env="$(env -iL ${user_id} XDG_RUNTIME_DIR=/var/run/user/${user_id} HOME=/home/${emacsd_user} | tr '\n' ' ')"
    proc_cmd="/usr/local/bin/emacs"
    proc_args="--fg-daemon -u ${emacsd_user}"
    command="/usr/sbin/daemon"
    command_args="-f -P ${pidfile} -p ${pidfile_child} -r ${proc_cmd} ${proc_args}"

    emacsd_prestart()
    {
        [ -z "${XDG_RUNTIME_DIR}" ] && XDG_RUNTIME_DIR="/var/run/user/$(id -u ${emacsd_user})"
        ! [ -d "${XDG_RUNTIME_DIR}" ] && \
        install -d -o "$(id -u ${emacsd_user})" -m 0700 "${XDG_RUNTIME_DIR}" -

        ! [ -d "${piddir}" ] && \
        install -d -o "$(id -u ${emacsd_user})" -g "$(id -u ${emacsd_user})" "${piddir}" -
        return 0
    }

    run_rc_command "$1"
    ```

rc.d (Linux, Maybe WSL)
: 这是 EmacsWiki 上为 GNU/Debian 创建的 rc.d 脚本，或许 WSL 也能用， `/etc/init.d/emacsd`
    ```bash
    #!/bin/sh

    ### BEGIN INIT INFO
    # Provides:          emacsd
    # Required-Start:    $remote_fs $syslog
    # Required-Stop:     $remote_fs $syslog
    # Default-Start:     2 3 4 5
    # Default-Stop:      0 1 6
    # Short-Description: Start emacsd at boot time
    # Description:       Enable service provided by daemon.
    ### END INIT INFO

    # Local Settings

    PATH=/usr/local/bin:/usr/bin:/bin

    # emacs location.
    emacs="emacs"
    emacsclient="emacsclient"

    # EE code
    EE_EMACS_NOT_FOUND=1
    EE_INVALID_OPTION=2
    EE_EMACS_FAIL_TO_START=3
    EE_EMACS_FAIL_TO_STOP=4

    # Real code begins here

    if [ -z `which emacs` ]
    then
        log_daemon_msg "Error: Emacs not found. emacsd will now exit."
        exit $EE_EMACS_NOT_FOUND
    fi

    # TODO Start emacs as normal user "emacsd" or "daemon"
    #emacs run under this uid
    emacsd_uid="1000"
    socket_file="/tmp/emacs${emacsd_uid}/server"

    case "$1" in
        start)
    	#check whether already started
    	if [ -e "$socket_file" ]
    	then
    	    echo "Error: emacsd already started."
    	    exit $EE_EMACSD_ALREADY_STARTED
    	fi

    	echo "Start emacs daemon ..."
    	if sudo -u"#"$emacsd_uid $emacs --daemon
    	then
    	    echo "emacsd is up."
    	    exit 0
    	else
    	    echo "Error: emacsd failed to start."
    	    exit $EE_EMACS_FAIL_TO_START
    	fi
    	;;

        stop)
    	#options="-s $socket_file"
    	options=""
    	lispcode="(kill-emacs)"

    	if sudo -u"#"$emacsd_uid $emacsclient $options --eval $lispcode
    	then
    	    echo "emacsd is down."
    	    exit 0
    	else
    	    echo "Error: emacsd failed to stop."
    	    exit $EE_EMACS_FAIL_TO_STOP
    	fi
    	;;

        restart|force-reload)
    	if [ -e "$socket_file" ]
    	then
    	    $0 stop
    	fi
    	$0 start
    	exit $?
    	;;

        *)
    	echo "Usage: /etc/init.d/emacsd {start|stop|restart|force-reload}"
    	if ! [ -z "$1" ]
    	then
    	    echo "No such option:" $*
    	    exit $EE_INVALID_OPTION
    	fi
    	;;
    esac
    ```

好了，让其开机启动吧！

-   Systemd (Not WSL)
    ```shell
    systemctl --user enable emacs.service
    ```
-   Launchd (MacOS)
    ```shell
    launchctl load -w ~/Library/LaunchAgents/gnu.emacs.daemon.plist
    ```

剩下两个实在不会了。。。

做一个 desktop 文件，可以直接从桌面启动，再添加一些打来文件的默认应用

```text
[Desktop Entry]
Name=Emacs client
GenericName=Text Editor
Comment=A flexible platform for end-user applications
MimeType=text/english;text/plain;text/x-makefile;text/x-c++hdr;text/x-c++src;text/x-chdr;text/x-csrc;text/x-java;text/x-moc;text/x-pascal;text/x-tcl;text/x-tex;application/x-shellscript;text/x-c;text/x-c++;
Exec=emacsclient -create-frame --alternate-editor="" --no-wait %F
Icon=emacs
Type=Application
Terminal=false
Categories=TextEditor;Utility;
StartupWMClass=Emacs
Keywords=Text;Editor;
X-KDE-StartupNotify=false
```

emacsclient 似乎不会开始于 dashboard，修复一下这个让我不爽的问题

```emacs-lisp
(when (daemonp)
  (add-hook! 'server-after-make-frame-hook (switch-to-buffer +doom-dashboard-name)))
```

既然有了 emacsclient，那就抄一下 [@tecosaur](https://github.com/tecosaur) 的启动脚本吧

<a id="code-snippet--e"></a>
```shell
#!/usr/bin/env bash
force_tty=false
force_wait=false
stdin_mode=""

args=()

while :; do
    case "$1" in
	-t | -nw | --tty)
	    force_tty=true
	    shift ;;
	-w | --wait)
	    force_wait=true
	    shift ;;
	-m | --mode)
	    stdin_mode=" ($2-mode)"
	    shift 2 ;;
	-h | --help)
	    echo -e "\033[1mUsage: e [-t] [-m MODE] [OPTIONS] FILE [-]\033[0m

Emacs client convenience wrapper.

\033[1mOptions:\033[0m
\033[0;34m-h, --help\033[0m            Show this message
\033[0;34m-t, -nw, --tty\033[0m        Force terminal mode
\033[0;34m-w, --wait\033[0m            Don't supply \033[0;34m--no-wait\033[0m to graphical emacsclient
\033[0;34m-\033[0m                     Take \033[0;33mstdin\033[0m (when last argument)
\033[0;34m-m MODE, --mode MODE\033[0m  Mode to open \033[0;33mstdin\033[0m with

Run \033[0;32memacsclient --help\033[0m to see help for the emacsclient."
	    exit 0 ;;
	--*=*)
	    set -- "$@" "${1%%=*}" "${1#*=}"
	    shift ;;
	*)
	    if [ "$#" = 0 ]; then
		break; fi
	    args+=("$1")
	    shift ;;
    esac
done

if [ ! "${#args[*]}" = 0 ] && [ "${args[-1]}" = "-" ]; then
    unset 'args[-1]'
    TMP="$(mktemp /tmp/emacsstdin-XXX)"
    cat > "$TMP"
    args+=(--eval "(let ((b (generate-new-buffer \"*stdin*\"))) (switch-to-buffer b) (insert-file-contents \"$TMP\") (delete-file \"$TMP\")${stdin_mode})")
fi

if [ -z "$DISPLAY" ] || $force_tty; then
    # detect terminals with sneaky 24-bit support
    if { [ "$COLORTERM" = truecolor ] || [ "$COLORTERM" = 24bit ]; } \
	&& [ "$(tput colors 2>/dev/null)" -lt 257 ]; then
	if echo "$TERM" | grep -q "^\w\+-[0-9]"; then
	    termstub="${TERM%%-*}"; else
	    termstub="${TERM#*-}"; fi
	if infocmp "$termstub-direct" >/dev/null 2>&1; then
	    TERM="$termstub-direct"; else
	    TERM="xterm-direct"; fi # should be fairly safe
    fi
    emacsclient --tty -create-frame --alternate-editor="" "${args[@]}"
else
    if ! $force_wait; then
	args+=(--no-wait); fi
    emacsclient -create-frame --alternate-editor="" "${args[@]}"
fi
```


## 包 {#包}


### 加载结构 {#加载结构}

doom 通过 `packages.el` 来安装包，非常简单，只需要 `package!` 就可以安装。需要注意，不应该将该文件编译为字节码。

```emacs-lisp
;; -*- no-byte-compile: t; -*-
;;; $DOOMDIR/packages.el
```

**警告**: 不要禁用 `~/.emacs.d/core/packages.el` 中列出的包。Doom 依赖这些，禁用它们可能出现严重问题。

-   从官方的源 [MELPA](https://melpa.org/) / [GNU ELPA](http://elpa.gnu.org/) / [emacsmirror](https://emacsmirror.net/) 安装
    ```emacs-lisp
    (package! some-package)
    ```
-   关闭某些包
    ```emacs-lisp
    (package! some-package :disable t)
    ```
-   从 Git Repo 安装
    ```emacs-lisp
    ;; github
    (package! github-package :recipe (:host github :repo "username/repo"))
    ;; gitlab
    (package! gitlab-package :recipe (:host gitlab :repo "username/repo"))
    ;; other
    (package! other-package :recipe (:host nil :repo "https://example.com/repo"))
    ```
    如果 repo 仅中只有某个 / 某些文件是你需要的
    ```emacs-lisp
    (package! some-package
      :recipe (:host github :repo "username/repo"
    	   :files ("some-file.el" "src/elisp/*.el")))
    ```
    如果需要指定某个 `commit` 或某个 `branch`
    ```emacs-lisp
    ;; commit
    (package! some-package :pin "abcdefghijk")
    ;; branch
    (package! some-package :recipe (:branch "stable"))
    ```
-   使用本地的 repo
    ```emacs-lisp
    (package! some-package :recipe (:local-repo "/path/to/repo"))
    ```


### 工具 {#工具}


#### 缩写 {#缩写}

Emacs Stack Exchange 上的[在多种模式下使用统一的缩写表](https://emacs.stackexchange.com/questions/45462/use-a-single-abbrev-table-for-multiple-modes/45476#45476)，是一个很好的思路

```emacs-lisp
(add-hook 'doom-first-buffer-hook
	  (defun +abbrev-file-name ()
	    (setq-default abbrev-mode t)
	    (setq abbrev-file-name (expand-file-name "abbrev.el" doom-private-dir))))
```


#### hungry delete {#hungry-delete}

一次 `backspace` 吃掉所有空白符 (当前光标限定)

```emacs-lisp
(package! hungry-delete :recipe (:host github :repo "nflath/hungry-delete"))
```

```emacs-lisp
(use-package! hungry-delete
  :config
  (setq-default hungry-delete-chars-to-skip " \t\v")
  (add-hook! 'after-init-hook #'global-hungry-delete-mode))
```


#### DIRED {#dired}

emacs 自带的强大文件管理器，和之后提到的 [Magit](#magit)、[TRAMP](#tramp) 都是 Emacs 的杀手级应用。还出现了很多增强性的包来增加其能力，不过对我来说，稍微修改一下也就够了。

```emacs-lisp
(after! dired
  (require 'dired-async)
  (define-key! dired-mode-map "RET" #'dired-find-alternate-file)
  (define-key! dired-mode-map "C" #'dired-async-do-copy)
  (define-key! dired-mode-map "H" #'dired-async-do-hardlink)
  (define-key! dired-mode-map "R" #'dired-async-do-rename)
  (define-key! dired-mode-map "S" #'dired-async-do-symlink)
  (define-key! dired-mode-map "n" #'dired-next-marked-file)
  (define-key! dired-mode-map "p" #'dired-prev-marked-file)
  (define-key! dired-mode-map "=" #'ginshio/dired-ediff-files)
  (define-key! dired-mode-map "<mouse-2>" #'dired-mouse-find-file)
  (defun ginshio/dired-ediff-files ()
    "Mark files and ediff in dired mode, you can mark 1, 2 or 3 files and diff.
see: https://oremacs.com/2017/03/18/dired-ediff/"
    (let ((files (dired-get-marked-files)))
      (cond ((= (length files) 0))
	    ((= (length files) 1)
	     (let ((file1 (nth 0 files))
		   (file2 (read-file-name "file: " (dired-dwim-target-directory))))
	       (ediff-files file1 file2)))
	    ((= (length files) 2)
	     (let ((file1 (nth 0 files)) (file2 (nth 1 files)))
	       (ediff-files file1 file2)))
	    ((= (length files) 3)
	     (let ((file1 (car files)) (file2 (nth 1 files)) (file3 (nth 2 files)))
	       (ediff-files3 file1 file2 file3)))
	    (t (error "no more than 3 files should be marked")))))
  (define-advice dired-do-print (:override (&optional _))
    "show/hide dotfiles in current dired
see: https://www.emacswiki.org/emacs/DiredOmitMode"
    (cond ((or (not (boundp 'dired-dotfiles-show-p)) dired-dotfiles-show-p)
	   (setq-local dired-dotfiles-show-p nil)
	   (dired-mark-files-regexp "^\\.")
	   (dired-do-kill-lines))
	  (t (revert-buffer)
	     (setq-local dired-dotfiles-show-p t))))
  (define-advice dired-up-directory (:override (&optional _))
    "goto up directory in this buffer"
    (find-alternate-file ".."))
  (define-advice dired-do-compress-to (:override (&optional _))
    "Compress selected files and directories to an archive."
    (let* ((output (read-file-name "Compress to: "))
	   (command-assoc (assoc output dired-compress-files-alist 'string-match))
	   (files-str (mapconcat 'identity (dired-get-marked-files t) " ")))
      (when (and command-assoc (not (string= "" files-str)))
	(let ((command (format-spec (cdr command-assoc)
				    `((?o . ,output)
				      (?i . ,files-str)))))
	  (async-start (lambda () (shell-command command)) nil))))))
```


#### Magit {#magit}

{{< figure src="https://imgs.xkcd.com/comics/git.png" >}}

这应该是 Emacs 的杀手应用之一了，感谢 [Jonas](https://github.com/tarsius) 及其他贡献者。

<!--list-separator-->

-  提交模板

    现在并没有完成这部分，处于一种完全不会写提交的状态，以后大概率会增加一个提交模板。

<!--list-separator-->

-  Delta

    [Delta](https://github.com/dandavison/delta/) 是用 rust 实现的 git diff 语法高亮的工具。该作者还将其挂接到了 magit 的
    diff 视图上 (默认不会有语法高亮)。不过这需要 `delta` 二进制文件，在 cargo 安装显得简单些，不过你也可以选择 [GitHub Release](https://github.com/dandavison/delta/releases/latest)。

    ```shell
    cargo install git-delta
    ```

    简单地配置它就行

    ```emacs-lisp
    (package! magit-delta :recipe (:host github :repo "dandavison/magit-delta"))
    ```

    ```emacs-lisp
    (use-package! magit-delta
      :after magit
      :hook (magit-mode . magit-delta-mode))
    ```

<!--list-separator-->

-  冲突

    在 Emacs 中处理冲突也是不错的体验，和或许可以尝试自己制造一点

    ```emacs-lisp
    (defun smerge-repeatedly ()
      "Perform smerge actions again and again"
      (interactive)
      (smerge-mode 1)
      (smerge-transient))
    (after! transient
      (transient-define-prefix smerge-transient ()
        [["Move"
          ("n" "next" (lambda () (interactive) (ignore-errors (smerge-next)) (smerge-repeatedly)))
          ("p" "previous" (lambda () (interactive) (ignore-errors (smerge-prev)) (smerge-repeatedly)))]
         ["Keep"
          ("b" "base" (lambda () (interactive) (ignore-errors (smerge-keep-base)) (smerge-repeatedly)))
          ("u" "upper" (lambda () (interactive) (ignore-errors (smerge-keep-upper)) (smerge-repeatedly)))
          ("l" "lower" (lambda () (interactive) (ignore-errors (smerge-keep-lower)) (smerge-repeatedly)))
          ("a" "all" (lambda () (interactive) (ignore-errors (smerge-keep-all)) (smerge-repeatedly)))
          ("RET" "current" (lambda () (interactive) (ignore-errors (smerge-keep-current)) (smerge-repeatedly)))]
         ["Diff"
          ("<" "upper/base" (lambda () (interactive) (ignore-errors (smerge-diff-base-upper)) (smerge-repeatedly)))
          ("=" "upper/lower" (lambda () (interactive) (ignore-errors (smerge-diff-upper-lower)) (smerge-repeatedly)))
          (">" "base/lower" (lambda () (interactive) (ignore-errors (smerge-diff-base-lower)) (smerge-repeatedly)))
          ("R" "refine" (lambda () (interactive) (ignore-errors (smerge-refine)) (smerge-repeatedly)))
          ("E" "ediff" (lambda () (interactive) (ignore-errors (smerge-ediff)) (smerge-repeatedly)))]
         ["Other"
          ("c" "combine" (lambda () (interactive) (ignore-errors (smerge-combine-with-next)) (smerge-repeatedly)))
          ("r" "resolve" (lambda () (interactive) (ignore-errors (smerge-resolve)) (smerge-repeatedly)))
          ("k" "kill current" (lambda () (interactive) (ignore-errors (smerge-kill-current)) (smerge-repeatedly)))
          ("q" "quit" (lambda () (interactive) (smerge-auto-leave)))]]))
    ```


#### 补全 {#补全}

没有补全怎么写代码，尤其是 `Java` ！！！

```emacs-lisp
(after! company
  (setq! company-idle-delay 0.3
	 company-minimum-prefix-length 2
	 company-show-numbers t)
  ) ;; make aborting less annoying.
```

现在改进大多来自 `先前选项` 的历史记录，所以我们改进以下历史记录。

```emacs-lisp
(setq-default history-length 1024
	      prescient-history-length 1024)
```

还有最要紧的事，让待选选项有数字提示，方便直接 `Alt+num` 选择

```emacs-lisp
(custom-set-variables '(company-show-numbers t))
```


#### Consult {#consult}


#### Marginalia {#marginalia}

Doom 下 Marginalia 被调教的不错，如果遇到什么好玩的配置了，可以继续加。


#### LSP {#lsp}

这不是老色批！自从 lsp 普及开始，无论配置什么编辑器都不再复杂了。看了一圈
[lsp-mode tutorial](https://emacs-lsp.github.io/lsp-mode/tutorials/) 甚至觉得不需要配置什么，估计 doom 也有相应的配置。问题就是，熟悉配置、操作的问题。


#### 拼写检查 {#拼写检查}

`Ispell` 是一个古老的 Unix 拼写检查软件，当然你可以将其当作拼写检查软件的一种代称。

```emacs-lisp
(set-company-backend!
  '(text-mode
    markdown-mode
    gfm-mode)
  '(:seperate
    company-ispell
    company-files
    company-yasnippet))
```

Hunspell 还是 Aspell 都听不错，但是 Aspell 比较式微，故本配置使用的是前者，但是之后的配置是一样的

Hunspell 和 Aspell 都可以从  [SCOWL Custom List / Dicionary Creator](http://app.aspell.net/create)
获取一个好用的大词典

size (大小)
: 95 (疯狂)

spellings (拼写)
: 英语 (美国) 和 英语 (英国, -ise)

spelling variants level (拼写变体等级)
: 0

diacritics (变音符号)
: 保留

extra lists (额外列表)
: hacker、罗马数字

如果你用的是 Linux 且不想自己下载了，可以用用下面这个小脚本 (hunspell 不用)

-   Hunspell
    ```shell
    cd /tmp
    wget -O "hunspell-en-custom.zip" \
        -c 'http://app.aspell.net/create?max_size=95&spelling=US&spelling=GBs&max_variant=0&diacritic=keep&special=hacker&special=roman-numerals&encoding=utf-8&format=tar.gz&download=hunspell'
    unzip "hunspell-en-custom.zip"
    sudo chown root:root en-custom.*
    sudo mkdir -p /usr/share/hunspell/
    sudo mv en-custom.{aff,dic} /usr/share/hunspell/
    sudo ln -s /usr/share/hunspell/en-custom.aff /usr/share/hunspell/en_US.aff
    sudo ln -s /usr/share/hunspell/en-custom.dic /usr/share/hunspell/en_US.dic
    ```
-   Aspell
    ```shell
    cd /tmp
    wget -O "aspell6-en-custom.tar.bz2" \
        -c 'http://app.aspell.net/create?max_size=95&spelling=US&spelling=GBs&max_variant=0&diacritic=keep&special=hacker&special=roman-numerals&encoding=utf-8&format=tar.gz&download=aspell'
    tar -xjf "aspell6-en-custom.tar.bz2"
    cd aspell6-en-custom
    ./configure && make && sudo make install
    ```

配置一下就能开始用了

```emacs-lisp
(setq! ispell-dictionary "en-custom")
```


#### String Inflection {#string-inflection}

~~变形汽车人！~~ 变形字符串！

```emacs-lisp
(package! string-inflection)
```

```emacs-lisp
(use-package! string-inflection
  :defer t
  :init
  (map! :leader :prefix ("cS" . "naming convention")
	:desc "cycle" "~" #'string-inflection-all-cycle
	:desc "toggle" "t" #'string-inflection-toggle
	:desc "CamelCase" "c" #'string-inflection-camelcase
	:desc "downCase" "d" #'string-inflection-lower-camelcase
	:desc "kebab-case" "k" #'string-inflection-kebab-case
	:desc "under_score" "u" #'string-inflection-underscore
	:desc "Upper_Score" "_" #'string-inflection-capital-underscore
	:desc "UP_CASE" "U" #'string-inflection-upcase))
```


#### TRAMP {#tramp}

关于其他很有用的功能，TRAMP 算一个，它是多协议透明远程访问 (_Transparent Remote
Access, Multiple Protocol_) 工具。简单说这是简单访问其他主机文件系统的方法。

如果你想使用 `ssh-key` ，建议开始使用 `ssh config` ，并用 `sshx:` 进行 tramp 连接。

<!--list-separator-->

-  提示区域

    不幸的是，TRAMP 对远程连接时 SHELL 的提示格式很挑剔，尝试使用 bash 并放宽松提示区域的识别。

    ```emacs-lisp
    (after! tramp
      (setenv "SHELL" "/bin/bash")
      (setq tramp-shell-prompt-pattern
    	"\\(?:^\\|
    \\)[^]#$%>\n]*#?[]#$%>] *\\(\\[[0-9;]*[a-zA-Z] *\\)*"))  ;; default + 
    ```

<!--list-separator-->

-  Guix

    [Guix](https://guix.gnu.org/) 将一些 TRAMP 需要的二进制文件放置在了意想不到的位置。这不是个问题，我们可以手动帮助 TRAMP 找到它们。

    ```emacs-lisp
    (after! tramp
      (appendq! tramp-remote-path
    	    '("~/.guix-profile/bin" "~/.guix-profile/sbin"
    	      "/run/current-system/profile/bin"
    	      "/run/current-system/profile/sbin")))
    ```


#### VTerm {#vterm}

> As good as terminal emulation gets in Emacs

VTerm 的安装相对麻烦一些，需要编译一些依赖。当然对于 Unix 用户，用系统库更加方便！

```emacs-lisp
(after! vterm
  (setq vterm-module-cmake-args "-DUSE_SYSTEM_LIBVTERM=yes"))
```


#### YASnippet {#yasnippet}

snippets 套娃谁用谁知道！

```emacs-lisp
(setq yas-triggers-in-field t)
```


#### Screenshot {#screenshot}

<div class="notes">

screenshot 依赖于 [ImageMagick](https://imagemagick.org/index.php)

</div>

让截图变得轻而易举！

```emacs-lisp
(package! screenshot
  :recipe (:host github :repo "tecosaur/screenshot" :build (:not compile))
  )
```

```emacs-lisp
(use-package! screenshot :defer t)
```

[原项目](https://github.com/tecosaur/screenshot)暂时还没有修复 BUG，并且作者并没有打算添加 TUI 支持。


#### Ebooks {#ebooks}

管理 Ebooks，还在用 [calibre](https://calibre-ebook.com/) 吗？试试 Emacs 吧！虽然是 calibre 做后端 hhhhhh

```emacs-lisp
(package! calibredb)
```

体验一下在 Emacs 中管理 Ebooks 的快乐。

```emacs-lisp
(use-package! calibredb
  :defer t
  :init
  (setq! calibredb-root-dir "~/library/ebooks"
	 calibredb-db-dir '((expand-file-name "metadata.db" calibredb-root-dir))
	 calibredb-library-alist '(("~/library/ebooks")
				   ("~/library/papers"))
	 calibredb-format-all-the-icons t)
  :config
  (map! :map calibredb-show-mode-map
	"?" #'calibredb-entry-dispatch
	"o" #'calibredb-find-file
	"O" #'calibredb-find-file-other-frame
	"V" #'calibredb-open-file-with-default-tool
	"s" #'calibredb-set-metadata-dispatch
	"e" #'calibredb-export-dispatch
	"q" #'calibredb-entry-quit
	"y" #'calibredb-yank-dispatch
	"." #'calibredb-open-dired
	[tab] #'calibredb-toggle-view-at-point
	"M-t" #'calibredb-set-metadata--tags
	"M-a" #'calibredb-set-metadata--author_sort
	"M-A" #'calibredb-set-metadata--authors
	"M-T" #'calibredb-set-metadata--title
	"M-c" #'calibredb-set-metadata--comments)
  (map! :map calibredb-search-mode-map
	[mouse-3] #'calibredb-search-mouse
	"RET" #'calibredb-find-file
	"?" #'calibredb-dispatch
	"a" #'calibredb-add
	"A" #'calibredb-add-dir
	"c" #'calibredb-clone
	"d" #'calibredb-remove
	"D" #'calibredb-remove-marked-items
	"j" #'calibredb-next-entry
	"k" #'calibredb-previous-entry
	"l" #'calibredb-virtual-library-list
	"L" #'calibredb-library-list
	"n" #'calibredb-virtual-library-next
	"N" #'calibredb-library-next
	"p" #'calibredb-virtual-library-previous
	"P" #'calibredb-library-previous
	"s" #'calibredb-set-metadata-dispatch
	"S" #'calibredb-switch-library
	"o" #'calibredb-find-file
	"O" #'calibredb-find-file-other-frame
	"v" #'calibredb-view
	"V" #'calibredb-open-file-with-default-tool
	"." #'calibredb-open-dired
	"y" #'calibredb-yank-dispatch
	"b" #'calibredb-catalog-bib-dispatch
	"e" #'calibredb-export-dispatch
	"r" #'calibredb-search-refresh-and-clear-filter
	"R" #'calibredb-search-clear-filter
	"q" #'calibredb-search-quit
	"m" #'calibredb-mark-and-forward
	"f" #'calibredb-toggle-favorite-at-point
	"x" #'calibredb-toggle-archive-at-point
	"h" #'calibredb-toggle-highlight-at-point
	"u" #'calibredb-unmark-and-forward
	"i" #'calibredb-edit-annotation
	"DEL" #'calibredb-unmark-and-backward
	[backtab] #'calibredb-toggle-view
	[tab] #'calibredb-toggle-view-at-point
	"M-n" #'calibredb-show-next-entry
	"M-p" #'calibredb-show-previous-entry
	"/" #'calibredb-search-live-filter
	"M-t" #'calibredb-set-metadata--tags
	"M-a" #'calibredb-set-metadata--author_sort
	"M-A" #'calibredb-set-metadata--authors
	"M-T" #'calibredb-set-metadata--title
	"M-c" #'calibredb-set-metadata--comments))
```

其实建立自己的书库相当快乐，当然在搜索解决方案时还在神社看到了用 calibre
管理本子 (也是相当快乐了 XD)

<!--list-separator-->

-  cite

    自己建立 `calibre` 最重要的一点就是引用时很方便，作者和 `org-ref` 梦幻联动了一波，你可以在 org-mode 中引用 calibre 的内容了。

    ```emacs-lisp
    (after! org-ref
      (setq! org-ref-get-pdf-filename-function 'org-ref-get-mendeley-filename))
    ```

    有些遗憾，虽然 calibre 可以什么都管理，但是 papers 还是用 `zotero` 吧，毕竟
    cite 时 calibre 只能做 book。

    当然可以 calibre 建一个 `Paper` 库，而引用使用 zotero 导出的 `bibtex` ，也算是一种解决方式。当然享受 ~~calibre~~ `calibre-web` 带来的管理便利。

<!--list-separator-->

-  看书

    很遗憾 Emacs 支持 pdf 但不支持 `epub` 之类的格式。如果你想要 emacs 支持这些格式，可以考虑 `nov.el` ，我觉得 **Okular** 和 **Calibre** 更好！

    ```emacs-lisp
    ;;; add into packages.el
    (package! nov)
    ```

    ```emacs-lisp
    (use-package! nov
      :mode ("\\.epub\\'" . nov-mode)
      :config
      (map! :map nov-mode-map
    	:n "RET" #'nov-scroll-up)

      (defun doom-modeline-segment--nov-info ()
        (concat
         " "
         (propertize
          (cdr (assoc 'creator nov-metadata))
          'face 'doom-modeline-project-parent-dir)
         " "
         (cdr (assoc 'title nov-metadata))
         " "
         (propertize
          (format "%d/%d"
    	      (1+ nov-documents-index)
    	      (length nov-documents))
          'face 'doom-modeline-info)))

      (advice-add 'nov-render-title :override #'ignore)

      (defun +nov-mode-setup ()
        (face-remap-add-relative 'variable-pitch
    			     :family "Merriweather"
    			     :height 1.4
    			     :width 'semi-expanded)
        (face-remap-add-relative 'default :height 1.3)
        (setq-local line-spacing 0.2
    		next-screen-context-lines 4
    		shr-use-colors nil)
        (require 'visual-fill-column nil t)
        (setq-local visual-fill-column-center-text t
    		visual-fill-column-width 81
    		nov-text-width 80)
        (visual-fill-column-mode 1)
        (hl-line-mode -1)

        (add-to-list '+lookup-definition-functions #'+lookup/dictionary-definition)

        (setq-local mode-line-format
    		`((:eval
    		   (doom-modeline-segment--workspace-name))
    		  (:eval
    		   (doom-modeline-segment--window-number))
    		  (:eval
    		   (doom-modeline-segment--nov-info))
    		  ,(propertize
    		    " %P "
    		    'face 'doom-modeline-buffer-minor-mode)
    		  ,(propertize
    		    " "
    		    'face (if (doom-modeline--active) 'mode-line 'mode-line-inactive)
    		    'display `((space
    				:align-to
    				(- (+ right right-fringe right-margin)
    				   ,(* (let ((width (doom-modeline--font-width)))
    					 (or (and (= width 1) 1)
    					     (/ width (frame-char-width) 1.0)))
    				       (string-width
    					(format-mode-line (cons "" '(:eval (doom-modeline-segment--major-mode))))))))))
    		  (:eval (doom-modeline-segment--major-mode)))))

      (add-hook 'nov-mode-hook #'+nov-mode-setup))
    ```


### UI {#ui}


#### Nyan {#nyan}

首先添加一下彩虹猫，这不能忘！

```emacs-lisp
(package! nyan-mode :recipe (:host github :repo "TeMPOraL/nyan-mode"))
```

```emacs-lisp
(use-package! nyan-mode
  :config
  (setq nyan-animate-nyancat t
	nyan-wavy-trail t
	nyan-cat-face-number 4
	nyan-bar-length 16
	nyan-minimum-window-width 64)
  (add-hook! 'doom-modeline-hook #'nyan-mode))
```


#### Eros {#eros}

这个包可以修改 emacs lisp 内联执行的视觉效果，让这个结果的前缀更好看一点。

```emacs-lisp
(setq eros-eval-result-prefix "⟹ ") ; default =>
```

你可以用 `C-x C-e` 来对比一下前后变化

```emacs-lisp
(+ 1 1 (* 2 2) 1)
```

```python
return 2 ** 4
```


#### Theme Magic {#theme-magic}

非常神奇的是你可以在 Emacs 中用现有的 Theme，改变终端的 Theme，且 GUI 和 TUI 都可用！作者说 Linux 和 Mac 可用， `Windows Terminal` + `WSL` 同样适用，压力来到了纯 Windows 下的 Emacs。

```emacs-lisp
(package! theme-magic)
```

这个操作使用 `pywal` ，你可以通过仓库安装它，不过最简单的方式就是 `pip` 。

```shell
sudo python3 -m pip install pywal
```

Theme Magic 提供了一个数字界面，尝试从饱和度、色彩差异来有效的选取八个颜色。然而，它可能会为 light 选择相同的颜色，并不总能够选取最佳颜色。我们可以用 Doom themes
提供的色彩工具来轻松获取合理的配色来生成 light 版本 --- 现在就开始！

```emacs-lisp
(use-package! theme-magic
  :defer t
  :after +doom-dashboard
  :config
  (defadvice! theme-magic--auto-extract-16-doom-colors ()
    :override #'theme-magic--auto-extract-16-colors
    (list
     (face-attribute 'default :background)
     (doom-color 'error)
     (doom-color 'success)
     (doom-color 'type)
     (doom-color 'keywords)
     (doom-color 'constants)
     (doom-color 'functions)
     (face-attribute 'default :foreground)
     (face-attribute 'shadow :foreground)
     (doom-blend 'base8 'error 0.1)
     (doom-blend 'base8 'success 0.1)
     (doom-blend 'base8 'type 0.1)
     (doom-blend 'base8 'keywords 0.1)
     (doom-blend 'base8 'constants 0.1)
     (doom-blend 'base8 'functions 0.1)
     (face-attribute 'default :foreground))))
```


#### Emojify {#emojify}

OOTB 的 emoji 模块！麻烦的一点是设置的有些默认字符，可能会显示为 emoji。直接从 emoji 表中删除它们 (除了有点暴力)

```emacs-lisp
(defvar emojify-disabled-emojis
  '(;; Org
    "◼" "☑" "☸" "⚙" "⏩" "⏪"
    ;; Org Heading
    "✙" "♱" "♰" "☥" "✞" "✟" "✝" "†"
    "☰" "☱" "☲" "☳" "☴" "☵" "☶" "☷"
    "☿" "♀" "♁" "♂" "♃" "♄" "♅" "♆" "♇" "☽" "☾"
    "♈" "♉" "♊" "♋" "♌" "♍" "♎" "♏" "♐" "♑" "♒" "♓"
    "♔" "♕" "♖" "♗" "♘" "♙"
    "♚" "♛" "♜" "♝" "♞" "♟"
    ;; Org Agenda
    "⚡" "↑" "↓" "☕" "❓"
    ;; I just want to see this as text
    "©" "™")
  "Characters that should never be affected by `emojify-mode'.")

(defadvice! emojify-delete-from-data ()
  "Ensure `emojify-disabled-emojis' don't appear in `emojify-emojis'."
  :after #'emojify-set-emoji-data
  (dolist (emoji emojify-disabled-emojis)
    (remhash emoji emojify-emojis)))
```


#### Tabs {#tabs}

如果你想像现代编辑器一样拥有 tabs，或许你可以考虑一下

```emacs-lisp
(after! centaur-tabs
  (centaur-tabs-group-by-projectile-project)
  (centaur-tabs-mode t)
  (setq! centaur-tabs-style "bar"
	 centaur-tabs-set-icons t
	 centaur-tabs-set-modified-marker t
	 centaur-tabs-show-navigation-buttons t
	 centaur-tabs-gray-out-icons 'buffer))
```

如果想要 tabs 底下显示 `bar` ，需要开启 `x-underline-at-descent-line`，但是它在 `(after! ...)` 中不起作用。

```emacs-lisp
(setq! centaur-tabs-set-bar 'under
       x-underline-at-descent-line t)
```


#### Treemacs {#treemacs}

开启 `git-mode` 、 `follow-mode` 和 `indent-guide-mode` ，体验还是不错

```emacs-lisp
(after! treemacs
  (setq! treemacs-indent-guide-mode t
	 treemacs-show-hidden-files t
	 doom-themes-treemacs-theme "doom-colors"
	 treemacs-file-event-delay 1000
	 treemacs-file-follow-delay 0.1)
  (treemacs-follow-mode t)
  ;; (treemacs-filewatch-mode t)
  (treemacs-git-mode 'deferred)
  (treemacs-hide-gitignored-files-mode t))
```

可能是我的用法不对？ `filewatch-mode` 总是有问题，在外部修改 (不在 treemacs 中重命名、添加、删除等) 就会有问题，没法更新 tree。需要自己手动折叠一下。


#### hl todo {#hl-todo}

`hl-todo` 允许你设置一些关键字，这些关键字将高亮并且便于查找。往往用于代码注释中强调某些内容。

```emacs-lisp
(custom-set-variables
 '(hl-todo-keyword-faces '(("NOTE" font-lock-builtin-face bold) ;; needs discussion or further investigation.
			   ("REVIEW" font-lock-keyword-face bold) ;; review was conducted.
			   ("HACK" font-lock-variable-name-face bold) ;; workaround a known problem.
			   ("DEPRECATED" region bold) ;; why it was deprecated and to suggest an alternative.
			   ("XXX+" font-lock-constant-face bold) ;; warn other programmers of problematic or misguiding code.
			   ("TODO" font-lock-function-name-face bold) ;; tasks/features to be done.
			   ("FIXME" font-lock-warning-face bold) ;; problematic or ugly code needing refactoring or cleanup.
			   ("KLUDGE" font-lock-preprocessor-face bold )
			   ("BUG" error bold) ;; a known bug that should be corrected.
			   )))
```


### 有趣的生活 {#有趣的生活}


#### xkcd {#xkcd}

也许你看过，但是现在让你看个够。

```emacs-lisp
(package! xkcd)
```

```emacs-lisp
(after! xkcd
  (setq xkcd-cache-dir (expand-file-name "xkcd/" doom-cache-dir)
	xkcd-cache-latest (concat xkcd-cache-dir "latest"))
  (unless (file-exists-p xkcd-cache-dir)
    (make-directory xkcd-cache-dir)))
```

{{< figure src="https://imgs.xkcd.com/comics/is_it_worth_the_time.png" >}}

现在让 Org-Mode 可以支持 xkcd

```emacs-lisp
(after! org
  (org-link-set-parameters "xkcd"
			   :image-data-fun #'+org-xkcd-image-fn
			   :follow #'+org-xkcd-open-fn
			   :export #'+org-xkcd-export))

;;;###autoload
(defun ginshio/xkcd-file-info (&optional num)
  "Get xkcd image info"
  (require 'xkcd)
  (let* ((url (format "https://xkcd.com/%d/info.0.json" num))
	 (json-assoc (json-read-from-string (xkcd-get-json url num))))
    `(:img ,(cdr (assoc 'img json-assoc))
      :alt ,(cdr (assoc 'alt json-assoc))
      :title ,(cdr (assoc 'title json-assoc)))))

;;;###autoload
(defun +org-xkcd-open-fn (link)
  (+org-xkcd-image-fn nil link nil))

;;;###autoload
(defun +org-xkcd-image-fn (protocol link description)
  "Get image data for xkcd num LINK"
  (let* ((xkcd-info (ginshio/xkcd-file-info (string-to-number link)))
	 (img (plist-get xkcd-info :img))
	 (alt (plist-get xkcd-info :alt)))
    (+org-image-file-data-fn protocol (xkcd-download img (string-to-number link)) description)))

;;;###autoload
(defun +org-xkcd-export (num desc backend _com)
  "Convert xkcd to html/LaTeX/Markdown form"
  (let* ((xkcd-info (ginshio/xkcd-file-info (string-to-number num)))
	 (img (plist-get xkcd-info :img))
	 (alt (plist-get xkcd-info :alt))
	 (title (plist-get xkcd-info :title))
	 (file (xkcd-download img (string-to-number num))))
    (cond ((org-export-derived-backend-p backend 'hugo)
	   (format "{{< figure src=\"%s\" alt=\"%s\" >}}" img (subst-char-in-string ?\" ?“ alt)))
	  ((org-export-derived-backend-p backend 'html)
	   (format "<img class='invertible' src='%s' title=\"%s\" alt='%s'>" img (subst-char-in-string ?\" ?“ alt) title))
	  ((org-export-derived-backend-p backend 'latex)
	   (format "\\begin{figure}[!htb]
  \\centering
  \\includegraphics[scale=0.4]{%s}%s
\\end{figure}" file (if (equal desc (format "xkcd:%s" num)) ""
		      (format "\n  \\caption*{\\label{xkcd:%s} %s}"
			      num
			      (or desc
				  (format "\\textbf{%s} %s" title alt))))))
	  ((org-export-derived-backend-p backend 'markdown)
	   (format "![%s](https://xkcd.com/%s)" (subst-char-in-string ?\" ?“ alt) num))
	  (t (format "https://xkcd.com/%s" num)))))
```


#### 打字机 {#打字机}

或许你想听听打字机的声音，或者让身边人听听。

```emacs-lisp
(package! selectric-mode)
```

```emacs-lisp
(use-package! selectric-mode :defer t)
```

当然这是需要 `aplay` 的，如果你没有，可以找一下有没有 `alsa` 相关内容。但是我的 WSL ？没声？没声！


#### wakatime {#wakatime}

Wakatime 可以帮助你记录在编程语言、编辑器、项目以及操作系统上所用的时间，并在
GitHub / GitLab 同名仓库下展示。

```emacs-lisp
(package! wakatime-mode :recipe (:host github :repo "wakatime/wakatime-mode"))
```

```emacs-lisp
(global-wakatime-mode)
```


#### Elcord {#elcord}

除非你不断告诉身边的每个人，不然你使用 Emacs 的意义是什么？

```emacs-lisp
;; (package! elcord)
```

```emacs-lisp
;; (use-package! elcord
;;   :commands elcord-mode
;;   :config
;;   (setq elcord-use-major-mode-as-main-icon t))
```

但是国内好像用不上，到时候看看 steam。


#### IRC {#irc}

`circe` 是 Emacs 的 IRC 客户端 (这个名字+缩写简直太棒了)，还是将人变为怪物的希腊女神
--- 喀耳刻。

还是用前面说的意思吧，用它与那些在线 ~~隐身~~ 的人聊天！

{{< figure src="https://imgs.xkcd.com/comics/team_chat.png" >}}

或许我们暂时用不上它，先这样吧


#### 字典 {#字典}

我用了很久也不知道 doom 提供了字典，采用 `define-word` 和 [wordnut](https://github.com/gromnitsky/wordnut) 提供服务，不过离线字典可能更符合本地的要求。

GoldenDict CLI 在 GitHub 上是 [相当好评的问题](https://github.com/goldendict/goldendict/issues/37)，开发者已经将其加入 1.5 的待做事项，但 1.5 依旧难产，也许你可以考虑贡献一下。

我的配置也等 GoldenDict 吧。


## 编程语言配置 {#编程语言配置}


### 纯文本 {#纯文本}

Emacs 可以显示 ANSI 颜色代码。然而，在 Emacs 28 之前，如果不修改缓冲区是不可能做到这一点的，所以让我们以此为基础设置这个块。

```emacs-lisp
(after! text-mode
  (add-hook! 'text-mode-hook
	     ;; Apply ANSI color codes
	     (with-silent-modifications
	       (ansi-color-apply-on-region (point-min) (point-max) t))))
```


### Org Mode {#org}

Org Mode 无疑是 Emacs 的杀手级应用，其扩展能力以及 Emacs 的契合，让它吊打一众标记语言和富文本格式。当然 LaTeX 除外。

| 格式              | 细粒度控制 | 上手易用性 | 语法简单 | 编辑器支持 | 集成度 | 易于参考 | 多功能性 |
|-----------------|-------|-------|------|-------|-----|------|------|
| Word              | 2     | 4     | 4    | 2     | 3   | 2    | 2    |
| LaTeX             | 4     | 1     | 1    | 3     | 2   | 4    | 3    |
| Org Mode          | 4     | 2     | 3.5  | 1     | 4   | 4    | 4    |
| Markdown          | 1     | 3     | 3    | 4     | 3   | 3    | 1    |
| Markdown + Pandoc | 2.5   | 2.5   | 2.5  | 3     | 3   | 3    | 2    |

除了标记语言 (Markup Language) 的优雅外，Emacs 集成了一场丰富的有趣的功能，比如说对当前任何技术都支持的文学编程。

<a id="org-example-block--Literate programming workflow"></a>
```text { style="line-height:1.13;" }
      ╭─╴Code╶─╮            ╭─╴Raw Code╶─▶ Computer
Ideas╺┥        ┝━▶ Org Mode╺┥
      ╰─╴Text╶─╯            ╰─╴Document╶─▶ People
```

在 `.org` 文件可以包含代码块 (不支持 noweb 模板)，这些代码块可以与专用源代码文件纠缠在一起，并通过各种 (可扩展的) 方法编译成文档 (报告、文档、演示文稿等)。这些源块甚至可以创建要包含在文档中的图像或其他内容，或者生成源代码。

<a id="org-example-block--Example Org Flowchart"></a>
```text { style="line-height:1.13;" }
                   ╭───────────────────────────────────▶ .pdf ⎫
                  pdfLaTeX ▶╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╮                 ⎪
                   ╿     ╿                  ┊                 ⎪
                   │     ┊                  ┊                 ⎪
                 .tex    ┊                  ┊                 ⎪
                   ╿     ┊                  ┊                 ⎪
                ╭──┴╌╌╮  ┊                  ┊ style.scss      ⎬ Weaving
graphc.png ─╮   │  embedded TeX             ┊      ╽          ⎪ (Documents)
image.jpeg ─┤ filters   ╿                   ┊    .css         ⎪
            ╎     ╿     ┊                   ┊     ▾╎          ⎪
figure.png╶─╧─▶ PROJECT.ORG ▶───╴filters╶───╧──────╪──▶ .html ⎪
     ╿           ╿┊ ║ │ ╰╌╌╌▷╌╌ embedded html ▶╌╌╌╌╯          ⎪
     ├╌╌╌╌╌╌╌▷╌╌╌╯┊ ║ │                                       ⎪
    result╶╌╌╌╌╌╮ ┊ ║ ├──────╴filters╶────────────────▶ .txt  ⎪
     ┊▴         ┊ ┊ ║ │                                       ⎪
    execution   ┊ ┊ ║ ╰──────╴filters╶────────────────▶ .md   ⎭
     ┊▴         ┊ ┊ ║
    code blocks◀╯ ┊ ╟─────────────────────────────────▶ .c    ⎫
     ╰╌╌╌╌◁╌╌╌╌╌╌╌╯ ╟─────────────────────────────────▶ .sh   ⎬ Tangling
                    ╟─────────────────────────────────▶ .hs   ⎪ (Code)
                    ╙─────────────────────────────────▶ .el   ⎭
```

因为这部分初始化时相当费时，我们需要将其放在 `(after! ...)` 中。

```emacs-lisp
(after! org
  <<org-conf>>
)
```


#### 系统设置 {#系统设置}

<!--list-separator-->

-  Mime 类型

    默认情况下，Org 模式不会被识别为它自己的 MIME 类型，但可以使用以下文件轻松更改。 对于系统范围的更改，请尝试 `/usr/share/mime/packages/org.xml` 。

    ```xml
    <mime-info xmlns='http://www.freedesktop.org/standards/shared-mime-info'>
      <mime-type type="text/org">
        <comment>Emacs Org-mode File</comment>
        <glob pattern="*.org"/>
        <alias type="text/org"/>
      </mime-type>
    </mime-info>
    ```

    [Papirus](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme/commit/a10fb7f2423d5e30b9c4477416ccdc93c4f3849d) 有一个 `text/org` 的图标，只需刷新 mime 数据库。

    ```shell
    update-mime-database ~/.local/share/mime
    ```

    现在设置 emacs 为默认的编辑器。

    ```shell
    xdg-mime default emacs.desktop text/org
    ```

<!--list-separator-->

-  Git diffs

    Protesilaos 写了一篇 [非常有用的文章](https://protesilaos.com/codelog/2021-01-26-git-diff-hunk-elisp-org/)，他在其中解释了如何将 git diff 块标题更改为比大块上方的直接行更有用的东西 --- 就像父标题一样。

    这可以通过首先在 `~/.config/git/attributes` 中为 git 添加新的差异模式来实现。

    ```text
    *.org   diff=org
    ```

    然后为它添加一个正则表达式到 `~/.config/git/config` 。

    ```text
    [diff "org"]
      xfuncname = "^(\\*+ +.*)$"
    ```


#### 功能增强 {#功能增强}

{{< figure src="https://imgs.xkcd.com/comics/automation.png" >}}

<!--list-separator-->

-  标题结构

    说起标题行，我注意到了一个非常棒的包，它可以浏览并管理标题结构。

    ```emacs-lisp
    (package! org-ol-tree :recipe (:host github :repo "Townk/org-ol-tree"))
    ```

    ```emacs-lisp
    (use-package! org-ol-tree
      :defer t
      :after org
      :config
      (map! :map org-mode-map
    	:localleader
    	:desc "Outline" "O" #'org-ol-tree))
    ```

<!--list-separator-->

-  Agenda

    ```emacs-lisp
    (defvar org-agenda-dir (concat org-directory "/" "agenda"))
    (defvar org-agenda-todo-file (expand-file-name "todo.org" org-agenda-dir))
    (defvar org-agenda-project-file (expand-file-name "project.org" org-agenda-dir))
    (after! org-agenda
      ;;urgancy|soon|as soon as possible|at some point|eventually
      ;;
      (setq! org-agenda-files `(,org-agenda-todo-file
    			    ,org-agenda-project-file)
    	 org-agenda-skip-scheduled-if-done t
    	 org-agenda-skip-deadline-if-done t
    	 org-agenda-include-deadlines t
    	 org-agenda-block-separator nil
    	 org-agenda-tags-column 100 ;; from testing this seems to be a good value
    	 org-agenda-compact-blocks t))
    ```

<!--list-separator-->

-  Capture

    开始设置 Org-capture 模板吧，快速记录！

    ```emacs-lisp
    (after! org-capture
      (defun ginshio/find-project-tree(priority)
        "find or create project headline
    https://www.zmonster.me/2018/02/28/org-mode-capture.html"
        (let* ((hl (let ((headlines (org-element-map (org-element-parse-buffer 'headline) 'headline
    				  (lambda (hl) (and (= (org-element-property :level hl) 1)
    					       (org-element-property :title hl))))))
    		 (completing-read "Project Name: " headlines))))
          (goto-char (point-min))
          (if (re-search-forward
    	   (format org-complex-heading-regexp-format (regexp-quote hl)) nil t)
    	  (goto-char (point-at-bol))
    	(progn
    	  (or (bolp) (insert "\n"))
    	  (if (/= (point) (point-min)) (org-end-of-subtree))
    	  (insert (format "* %s :project:%s:\n:properties:\n:homepage: %s\n:repo: \
    %s\n:end:\n\n** urgancy :urgancy:\n\n** soon :soon:\n\n** as soon as\
     possible :asap:\n\n** at some point :asp:\n\n** eventually :eventually:\n"
    			  hl hl (read-string "homepage: ") (read-string "repo: ")))
    	  (beginning-of-line 0)
    	  (org-up-heading-safe))))
        (re-search-forward
         (format org-complex-heading-regexp-format
    	     (regexp-quote priority))
         (save-excursion (org-end-of-subtree t t)) t)
        (org-end-of-subtree))
      (setq! org-capture-dir (expand-file-name "capture" org-directory)
    	 org-capture-snippet-file (expand-file-name "snippets.org" org-capture-dir)
    	 org-capture-comment-file (expand-file-name "comments.org" org-capture-dir)
    	 org-capture-note-file (expand-file-name "notes.org" org-capture-dir))
      ;; http://www.howardism.org/Technical/Emacs/journaling-org.html
      ;; https://www.zmonster.me/2018/02/28/org-mode-capture.html
      (setq org-capture-templates
    	`(("c" "Comment")
    	  ("cb" "Book" entry (file+weektree ,org-capture-comment-file)
    	   "* %^{book} :book:%\\1:\n%?" :empty-lines 1)
    	  ("cm" "Movie" entry (file+weektree ,org-capture-comment-file)
    	   "* %^{movie} :movie:%\\1:\n%?" :empty-lines 1)
    	  ("g" "GTD")
    	  ("gt" "Todo" entry (file+headline org-agenda-todo-file "Personal")
    	   "* TODO [#%^{priority|A|B|C|D|E}] %^{task}\n  SCHEDULED: %^T DEADLINE: %^T\n:properties:\n:end:\n%?"
    	   :empty-lines 1)
    	  ("gi" "Interview" entry (file+headline ,org-agenda-todo-file "Interview")
    	   "* WAIT [#%^{priority|B|A|C|D}] %^{company} - %^{position}\t:%\\2:\nSCHEDULED: %^T DEADLINE: %^T\n:properties:\n:url: %^{link}\n:end:\n%?"
    	   :prepend t :empty-lines 1)
    	  ("gd" "Daily" entry (file+headline ,org-agenda-todo-file "Daily")
    	   "* TODO [#%^{priority|C|A|B|D|E}] %^{task}\n SCHEDULED:  %<<%Y-%m-%d %a %H:%M ++1d>>\n:properties:\n:end:\n%?"
    	   :empty-lines 1)
    	  ("gw" "Weekly" entry (file+headline ,org-agenda-todo-file "Weekly")
    	   "* TODO [#%^{priority|B|A|C|D|E}] %^{task}\n SCHEDULED: %<<%Y-%m-%d %a %H:%M ++1w>>\n:properties:\n:end:\n%?"
    	   :empty-lines 1)
    	  ("gm" "Monthly" entry (file+headline ,org-agenda-todo-file "Monthly")
    	   "* TODO [#%^{priority|C|A|B|D|E}] %^{task}\n SCHEDULED: %<<%Y-%m-%d %a %H:%M ++1m>>\n:properties:\n:end:\n%?"
    	   :empty-lines 1)
    	  ("n" "Note")
    	  ("nc" "Computer" entry (file+headline ,org-capture-note-file "Computer")
    	   "* %^{heading} %^g\n%?\n" :empty-lines 1)
    	  ("ne" "Emacs" entry (file+headline ,org-capture-note-file "Emacs")
    	   "* %^{heading} %^g\n%?\n" :empty-lines 1)
    	  ("ng" "Game" entry (file+headline ,org-capture-note-file "Game")
    	   "* %^{heading} %^g\n%?\n" :empty-lines 1)
    	  ;; ("p" "Project")
    	  ;; ("pa" "Urgance" entry (file+function ,org-agenda-project-file
    	  ;;                                      (lambda () (ginshio/find-project-tree "urgancy")))
    	  ;;  "*** TODO [#A] %^{task}\n SCHEDULED: %<<%Y-%m-%d %a %H:%M>> DEADLINE: %^T\n    :properties:\n    :end:\n%?"
    	  ;;  :empty-lines 1)
    	  ;; ("pb" "Soon" entry (file+function ,org-agenda-project-file
    	  ;;                                   (lambda () (ginshio/find-project-tree "soon")))
    	  ;;  "*** TODO [#B] %^{task}\n SCHEDULED: %<<%Y-%m-%d %a %H:%M>> DEADLINE: %^T\n    :properties:\n    :end:\n%?"
    	  ;;  :empty-lines 1)
    	  ;; ("pc" "As Soon As Possiple" entry (file+function ,org-agenda-project-file
    	  ;;                                                  (lambda () (ginshio/find-project-tree "as soon as possiple")))
    	  ;;  "*** TODO [#C] %^{task}\n SCHEDULED: %<<%Y-%m-%d %a %H:%M>> DEADLINE: %^T\n    :properties:\n    :end:\n%?"
    	  ;;  :empty-lines 1)
    	  ;; ("pd" "At Some Point" entry (file+function ,org-agenda-project-file
    	  ;;                                            (lambda () (ginshio/find-project-tree "at some point")))
    	  ;;  "*** TODO [#D] %^{task}\n SCHEDULED: %<<%Y-%m-%d %a %H:%M>> DEADLINE: %^T\n    :properties:\n    :end:\n%?"
    	  ;;  :empty-lines 1)
    	  ;; ("pe" "Eventually" entry (file+function ,org-agenda-project-file
    	  ;;                                         (lambda () (ginshio/find-project-tree "eventually")))
    	  ;;  "*** TODO [#E] %^{task}\n SCHEDULED: %<<%Y-%m-%d %a %H:%M>> DEADLINE: %^T\n    :properties:\n    :end:\n%?"
    	  ;;  :empty-lines 1)
    	  ("s" "Code Snippet" entry (file ,org-capture-snippet-file)
    	   "* %^{heading} :code:%\\2:\n:properties:\n:language: %^{language}\n:end:\n\n#+begin_src %\\2\n%?\n#+end_src"
    	   :empty-lines 1)
    	  )))
    ```

<!--list-separator-->

-  修改默认值

    ```emacs-lisp
    (setq! org-use-property-inheritance t         ; it's convenient to have properties inherited
           org-log-done 'time                     ; having the time a item is done sounds convenient
           org-list-allow-alphabetical t          ; have a. A. a) A) list bullets
           org-export-in-background t             ; run export processes in external emacs process
           org-catch-invisible-edits 'smart       ; try not to accidently do weird stuff in invisible regions
           org-export-with-sub-superscripts '{})  ; don't treat lone _ / ^ as sub/superscripts, require _{} / ^{}
    ```

<!--list-separator-->

-  零宽度工具

    偶尔在用 Org 是你希望将两个分开的块放在一起，这点有点烦人。比如将加**重**一个单词的一部分，或者说在内联源码块之前放一些符号。有一个可以解决的方法 --- 零宽空格。由于这是 Emacs，我们可以为 org-mode 做一个很小的改动将其添加到快捷键上 🙂。

    ```emacs-lisp
    (map! :map org-mode-map
          :desc "zero-width-space" "C-c SPC" (cmd! (insert "\u200B")))
    ```

    不过在导出时，我并不想要它，加一个简单的过滤器将其过滤掉。

    ```emacs-lisp
    (defun +org-export-remove-zero-width-space (text _backend _info)
      "Remove zero width spaces from TEXT."
      (unless (org-export-derived-backend-p 'org)
        (replace-regexp-in-string "\u200B" "" text)))

    (after! ox
      (add-to-list 'org-export-filter-final-output-functions #'+org-export-remove-zero-width-space t))
    ```

<!--list-separator-->

-  引用

    偶尔会引用某些东西，当然还有之前的 `calibre` 。设置一下，让 `org` 、 `LaTeX` 以及 `markdown` 可以使用 citar。

    ```emacs-lisp
    (use-package! citar
      :defer t
      :after (:any org TeX markdown)
      :init
      (setq! citar-symbols
    	 `((file ,(all-the-icons-faicon "file-o" :face 'all-the-icons-green :v-adjust -0.1) . " ")
    	   (note ,(all-the-icons-material "speaker_notes" :face 'all-the-icons-blue :v-adjust -0.3) . " ")
    	   (link ,(all-the-icons-octicon "link" :face 'all-the-icons-orange :v-adjust 0.01) . " "))
    	 citar-symbol-separator "  ")
      (map! :map (org-mode-map TeX-mode-map markdown-mode-map)
    	"C-c b" #'citar-insert-citation)
      (map! :map minibuffer-local-map
    	"M-b" #'citar-insert-preset)
      :custom
      ;; (org-cite-global-bibliography '("~/library/ebooks/catalog.bib"
      ;;                                 "~/library/papers/catalog.bib"))
      (org-cite-insert-processor 'citar)
      (org-cite-follow-processor 'citar)
      (org-cite-activate-processor 'citar)
      (citar-bibliography org-cite-global-bibliography)
      :config
      (add-to-list 'citar-major-mode-functions
    	       '((gfm-mode)
    		 (insert-keys . citar-markdown-insert-keys)
    		 (insert-citation . citar-markdown-insert-citation)
    		 (insert-edit . citar-markdown-insert-edit)
    		 (key-at-point . citar-markdown-key-at-point)
    		 (citation-at-point . citar-markdown-citation-at-point)
    		 (list-keys . citar-markdown-list-keys))))
    ```

    主要为了引用的灵活性，这里并没有设置全局 bib，如果想在 Org 里引用某些 bib 文件可以采用以下方法。

    ```text
    #+bibliography: ~/library/ebooks/catalog.bib
    #+bibliography: ~/library/papers/catalog.bib
    ```

    当然这配置很简单，只不过功能很强大，关于 `org-cite` 和 `citar` 要学的还有很多。可以看看 [这篇](https://blog.tecosaur.com/tmio/2021-07-31-citations.html)。

<!--list-separator-->

-  TOC

    生成目录的需求并不大，但是像 `GitHub` 的环境下 TOC 可能成为必要，采用 `toc-org`
    来生成。

    ```emacs-lisp
    (use-package! toc-org
      :defer t
      :after (:any org markdown)
      :config
      (toc-org-mode t)
      (add-hook! '(org-mode-hook markdown-mode-hook) #'toc-org-mode)
      (define-key! org-mode-map "C-c C-i" #'toc-org-insert-toc)
      (define-key! markdown-mode-map "C-c M-t" #'toc-org-insert-toc))
    ```

    `toc-org` 会清空带有 `TOC` 标签的 heading，并生成目录。

<!--list-separator-->

-  加密

    `org-crypt` 可以用 `GPG` 加密 Org Mode 的某些 heading，当然是带有 `crypt` 标签的。现在来设置一下。

    ```emacs-lisp
    (use-package! org-crypt
      :defer t
      :after org
      :custom
      (org-crypt-key user-gpg-key)
      (org-tags-exclude-from-inheritance '("crypt")) ;; avoid repeated encryption
      :config
      (org-crypt-use-before-save-magic) ;; encrypt when writing back to the hard disk
      (map! :map org-mode-map
    	:leader
    	:desc "org-encrypt" "C" nil
    	:desc "encrypt current" "C e" #'org-encrypt-entry
    	:desc "encrypt all" "C E" #'org-encrypt-entries
    	:desc "decrypt current" "C d" #'org-decrypt-entry
    	:desc "decrypt all" "C D" #'org-decrypt-entries))
    ```

    如果想用其他密钥加密，可以设置 `cryptkey` 属性。

    ```text
    * Totally secret :crypt:
    :properties:
    :cryptkey: 0x0123456789012345678901234567890123456789
    :end:
    ```


#### 视觉 {#视觉}

<!--list-separator-->

-  符号

    更改用于折叠项目的字符也很好 (默认情况下 `…`)，我认为用 `▾` 更适合指示 「折叠部分」。并在默认的四个列表中添加一个额外的 `org-bullet` 。对了，别忘记优先级也要修改。

    ```emacs-lisp
    (after! org-superstar
      (setq! org-superstar-headline-bullets-list '("♇" "♆" "♅" "♄" "♃" "♂" "♀" "☿")
    	 org-superstar-prettify-item-bullets t))
    (after! org-fancy-priorities
      (custom-set-variables '(org-lowest-priority ?E))
      (setq! org-fancy-priorities-list '("⚡" "↑" "↓" "☕" "❓")))
    ```

    ```emacs-lisp
    (setq! org-ellipsis " ▾ "
           org-hide-leading-stars t
           org-priority-highest ?A
           org-priority-lowest ?E
           org-priority-faces
           '((?A . 'all-the-icons-red)
    	 (?B . 'all-the-icons-orange)
    	 (?C . 'all-the-icons-yellow)
    	 (?D . 'all-the-icons-green)
    	 (?E . 'all-the-icons-blue)))
    ```

    将 Unicode 字符用于复选框和其他命令也很好。

    ```emacs-lisp
    (appendq! +ligatures-extra-symbols
    	  `(:checkbox      "☐"
    	    :pending       "◼"
    	    :checkedbox    "☑"
    	    :list_property "∷"
    	    :em_dash       "—"
    	    :ellipses      "…"
    	    :arrow_right   "→"
    	    :arrow_left    "←"
    	    :title         "𝙏"
    	    :subtitle      "𝙩"
    	    :author        "𝘼"
    	    :date          "𝘿"
    	    :property      "☸"
    	    :options       "⌥"
    	    :startup       "⏻"
    	    :macro         "𝓜"
    	    :html_head     "🅷"
    	    :html          "🅗"
    	    :latex_class   "🄻"
    	    :latex_header  "🅻"
    	    :beamer_header "🅑"
    	    :latex         "🅛"
    	    :attr_latex    "🄛"
    	    :attr_html     "🄗"
    	    :attr_org      "⒪"
    	    :begin_quote   "❝"
    	    :end_quote     "❞"
    	    :caption       "☰"
    	    :header        "›"
    	    :results       "🠶"
    	    :begin_export  "⏩"
    	    :end_export    "⏪"
    	    :properties    "⚙"
    	    :end           "∎"
    	    :priority_a   ,(propertize "⚑" 'face 'all-the-icons-red)
    	    :priority_b   ,(propertize "⬆" 'face 'all-the-icons-orange)
    	    :priority_c   ,(propertize "■" 'face 'all-the-icons-yellow)
    	    :priority_d   ,(propertize "⬇" 'face 'all-the-icons-green)
    	    :priority_e   ,(propertize "❓" 'face 'all-the-icons-blue)))
    (set-ligatures! 'org-mode
      :merge t
      :checkbox      "[ ]"
      :pending       "[-]"
      :checkedbox    "[X]"
      :list_property "::"
      :em_dash       "---"
      :ellipsis      "..."
      :arrow_right   "->"
      :arrow_left    "<-"
      :title         "#+title:"
      :subtitle      "#+subtitle:"
      :author        "#+author:"
      :date          "#+date:"
      :property      "#+property:"
      :options       "#+options:"
      :startup       "#+startup:"
      :macro         "#+macro:"
      :html_head     "#+html_head:"
      :html          "#+html:"
      :latex_class   "#+latex_class:"
      :latex_header  "#+latex_header:"
      :beamer_header "#+beamer_header:"
      :latex         "#+latex:"
      :attr_latex    "#+attr_latex:"
      :attr_html     "#+attr_html:"
      :attr_org      "#+attr_org:"
      :begin_quote   "#+begin_quote"
      :end_quote     "#+end_quote"
      :caption       "#+caption:"
      :header        "#+header:"
      :begin_export  "#+begin_export"
      :end_export    "#+end_export"
      :results       "#+RESULTS:"
      :property      ":PROPERTIES:"
      :end           ":END:"
      :priority_a    "[#A]"
      :priority_b    "[#B]"
      :priority_c    "[#C]"
      :priority_d    "[#D]"
      :priority_e    "[#E]")
    (plist-put +ligatures-extra-symbols :name "⁍")
    ```

<!--list-separator-->

-  LaTeX 片段

    让公式稍稍好看一点点

    ```emacs-lisp
    (setq! org-highlight-latex-and-related '(native script entities))
    ```

    理想情况下 `org-src-font-lock-fontify-block` 不会添加 `org-block` ，但我们可以通过添加带有 `:inherit default` 面来避免整个功能，这将覆盖背景颜色。

    检查 `org-do-latex-and-related` 显示 `"latex"` 是传递的语言参数，因此我们可以如上所述覆盖背景。

    ```emacs-lisp
    (require 'org-src)
    (add-to-list 'org-src-block-faces '("latex" (:inherit default :extend t)))
    ```

    比语法高亮的 LaTeX 更好的是 _呈现_ LaTeX，我们可以使用 `org-fragtog` 自动执行此操作。

    ```emacs-lisp
    (package! org-fragtog)
    ```

    ```emacs-lisp
    (use-package! org-fragtog :hook (org-mode . org-fragtog-mode))
    ```

    自定义 LaTeX 片段的外观很舒适，这样它们就更适合文本了 --- 比如这个
    \\(\sqrt{\beta^2+3}-\sum\_{\phi=1}^\infty \frac{x^\phi-1}{\Gamma(a)}\\) 。

    ```emacs-lisp
    (setq! org-preview-latex-default-process 'dvisvgm
           org-preview-latex-process-alist
           '((dvipng :programs
    		 ("lualatex" "dvipng")
    		 :description "dvi > png" :message "you need to install the programs: latex and dvipng." :image-input-type "dvi" :image-output-type "png" :image-size-adjust
    		 (1.0 . 1.0)
    		 :latex-compiler
    		 ("lualatex -output-format dvi -interaction nonstopmode -output-directory %o %f")
    		 :image-converter
    		 ("dvipng -D %D -T tight -bg Transparent -o %O %f"))
    	 (dvisvgm :programs
    		  ("latex" "dvisvgm")
    		  :description "dvi > svg" :message "you need to install the programs: latex and dvisvgm." :use-xcolor t :image-input-type "xdv" :image-output-type "svg" :image-size-adjust
    		  (1.7 . 1.5)
    		  :latex-compiler
    		  ("xelatex -no-pdf -interaction nonstopmode -output-directory %o %f")
    		  :image-converter
    		  ("dvisvgm %f -n -b min -c %S -o %O"))
    	 (imagemagick :programs
    		      ("latex" "convert")
    		      :description "pdf > png" :message "you need to install the programs: latex and imagemagick." :use-xcolor t :image-input-type "pdf" :image-output-type "png" :image-size-adjust
    		      (1.0 . 1.0)
    		      :latex-compiler
    		      ("xelatex -no-pdf -interaction nonstopmode -output-directory %o %f")
    		      :image-converter
    		      ("convert -density %D -trim -antialias %f -quality 100 %O"))))
    (setq! org-format-latex-header "\\documentclass{article}
    \\usepackage[usenames]{xcolor}
    \\usepackage[T1]{fontenc}
    \\usepackage{booktabs}
    \\pagestyle{empty}             % do not remove
    % The settings below are copied from fullpage.sty
    \\setlength{\\textwidth}{\\paperwidth}
    \\addtolength{\\textwidth}{-3cm}
    \\setlength{\\oddsidemargin}{1.5cm}
    \\addtolength{\\oddsidemargin}{-2.54cm}
    \\setlength{\\evensidemargin}{\\oddsidemargin}
    \\setlength{\\textheight}{\\paperheight}
    \\addtolength{\\textheight}{-\\headheight}
    \\addtolength{\\textheight}{-\\headsep}
    \\addtolength{\\textheight}{-\\footskip}
    \\addtolength{\\textheight}{-3cm}
    \\setlength{\\topmargin}{1.5cm}
    \\addtolength{\\topmargin}{-2.54cm}
    \\usepackage{amsmath,amsxtra,mathtools,upgreek,extarrows}
    \\usepackage{arev}
    "
           org-format-latex-options
           (plist-put org-format-latex-options :background "Transparent"))
    ```


#### 导出通用设置 {#导出通用设置}

默认情况下，Org 仅将前三个级别的标题导出为标题。当使用 `article` 时，LaTeX 标题从 `\section` 、 `\subsection` 、 `\subsubsection` 和 `\paragraph` 、
`\subgraph` --- _五_ 个级别。HTML5 有六级标题 (`<h1>` 到 `<h6>`)，但第一级 Org
标题被导出为 `<h2>` 元素 --- 剩下 _五_ 个可用级别。

```emacs-lisp
(setq! org-export-headline-levels 5)
```


#### HTML 导出 {#html-导出}

```emacs-lisp
(after! ox-html
  <<ox-html-conf>>
)
```

```emacs-lisp
(define-minor-mode org-fancy-html-export-mode
  "Toggle my fabulous org export tweaks. While this mode itself does a little bit,
the vast majority of the change in behaviour comes from switch statements in:
 - `org-html-template-fancier'
 - `org-html--build-meta-info-extended'
 - `org-html-src-block-collapsable'
 - `org-html-block-collapsable'
 - `org-html-table-wrapped'
 - `org-html--format-toc-headline-colapseable'
 - `org-html--toc-text-stripped-leaves'
 - `org-export-html-headline-anchor'"
  :global t
  :init-value t
  (if org-fancy-html-export-mode
      (setq org-html-style-default org-html-style-fancy
	    org-html-meta-tags #'org-html-meta-tags-fancy
	    org-html-checkbox-type 'html-span)
    (setq org-html-style-default org-html-style-plain
	  org-html-meta-tags #'org-html-meta-tags-default
	  org-html-checkbox-type 'html)))
```

<!--list-separator-->

-  额外的 head

    在主体的开头添加更多信息，在页眉中添加日期和作者，实现仅 CSS 的亮/暗主题切换，以及一些
    [Open Graph](https://ogp.me/) 元数据。

    ```emacs-lisp
    (defadvice! org-html-template-fancier (orig-fn contents info)
      "Return complete document string after HTML conversion.
    CONTENTS is the transcoded contents string.  INFO is a plist
    holding export options. Adds a few extra things to the body
    compared to the default implementation."
      :around #'org-html-template
      (if (or (not org-fancy-html-export-mode) (bound-and-true-p org-msg-export-in-progress))
          (funcall orig-fn contents info)
        (concat
         (when (and (not (org-html-html5-p info)) (org-html-xhtml-p info))
           (let* ((xml-declaration (plist-get info :html-xml-declaration))
    	      (decl (or (and (stringp xml-declaration) xml-declaration)
    			(cdr (assoc (plist-get info :html-extension)
    				    xml-declaration))
    			(cdr (assoc "html" xml-declaration))
    			"")))
    	 (when (not (or (not decl) (string= "" decl)))
    	   (format "%s\n"
    		   (format decl
    			   (or (and org-html-coding-system
    				    (fboundp 'coding-system-get)
    				    (coding-system-get org-html-coding-system 'mime-charset))
    			       "utf-8"))))))
         (org-html-doctype info)
         "\n"
         (concat "<html"
    	     (cond ((org-html-xhtml-p info)
    		    (format
    		     " xmlns=\"http://www.w3.org/1999/xhtml\" lang=\"%s\" xml:lang=\"%s\""
    		     (plist-get info :language) (plist-get info :language)))
    		   ((org-html-html5-p info)
    		    (format " lang=\"%s\"" (plist-get info :language))))
    	     ">\n")
         "<head>\n"
         (org-html--build-meta-info info)
         (org-html--build-head info)
         (org-html--build-mathjax-config info)
         "</head>\n"
         "<body>\n<input type='checkbox' id='theme-switch'><div id='page'><label id='switch-label' for='theme-switch'></label>"
         (let ((link-up (org-trim (plist-get info :html-link-up)))
    	   (link-home (org-trim (plist-get info :html-link-home))))
           (unless (and (string= link-up "") (string= link-home ""))
    	 (format (plist-get info :html-home/up-format)
    		 (or link-up link-home)
    		 (or link-home link-up))))
         ;; Preamble.
         (org-html--build-pre/postamble 'preamble info)
         ;; Document contents.
         (let ((div (assq 'content (plist-get info :html-divs))))
           (format "<%s id=\"%s\">\n" (nth 1 div) (nth 2 div)))
         ;; Document title.
         (when (plist-get info :with-title)
           (let ((title (and (plist-get info :with-title)
    			 (plist-get info :title)))
    	     (subtitle (plist-get info :subtitle))
    	     (html5-fancy (org-html--html5-fancy-p info)))
    	 (when title
    	   (format
    	    (if html5-fancy
    		"<header class=\"page-header\">%s\n<h1 class=\"title\">%s</h1>\n%s</header>"
    	      "<h1 class=\"title\">%s%s</h1>\n")
    	    (if (or (plist-get info :with-date)
    		    (plist-get info :with-author))
    		(concat "<div class=\"page-meta\">"
    			(when (plist-get info :with-date)
    			  (org-export-data (plist-get info :date) info))
    			(when (and (plist-get info :with-date) (plist-get info :with-author)) ", ")
    			(when (plist-get info :with-author)
    			  (org-export-data (plist-get info :author) info))
    			"</div>\n")
    	      "")
    	    (org-export-data title info)
    	    (if subtitle
    		(format
    		 (if html5-fancy
    		     "<p class=\"subtitle\" role=\"doc-subtitle\">%s</p>\n"
    		   (concat "\n" (org-html-close-tag "br" nil info) "\n"
    			   "<span class=\"subtitle\">%s</span>\n"))
    		 (org-export-data subtitle info))
    	      "")))))
         contents
         (format "</%s>\n" (nth 1 (assq 'content (plist-get info :html-divs))))
         ;; Postamble.
         (org-html--build-pre/postamble 'postamble info)
         ;; Possibly use the Klipse library live code blocks.
         (when (plist-get info :html-klipsify-src)
           (concat "<script>" (plist-get info :html-klipse-selection-script)
    	       "</script><script src=\""
    	       org-html-klipse-js
    	       "\"></script><link rel=\"stylesheet\" type=\"text/css\" href=\""
    	       org-html-klipse-css "\"/>"))
         ;; Closing document.
         "</div>\n</body>\n</html>")))
    ```

<!--list-separator-->

-  自定义 CSS/JS

    [lepisma.xyz](https://lepisma.xyz) 所做的导出风格非常讨喜。

    ```html
    <link rel="icon" href="https://tecosaur.com/resources/org/nib.ico" type="image/ico" />

    <link rel="preload" as="font" crossorigin="anonymous" type="font/woff2" href="https://tecosaur.com/resources/org/etbookot-roman-webfont.woff2">
    <link rel="preload" as="font" crossorigin="anonymous" type="font/woff2" href="https://tecosaur.com/resources/org/etbookot-italic-webfont.woff2">
    <link rel="preload" as="font" crossorigin="anonymous" type="font/woff2" href="https://tecosaur.com/resources/org/Merriweather-TextRegular.woff2">
    <link rel="preload" as="font" crossorigin="anonymous" type="font/woff2" href="https://tecosaur.com/resources/org/Merriweather-TextItalic.woff2">
    <link rel="preload" as="font" crossorigin="anonymous" type="font/woff2" href="https://tecosaur.com/resources/org/Merriweather-TextBold.woff2">
    ```

    ```emacs-lisp
    (setq! org-html-style-plain org-html-style-default
           org-html-htmlize-output-type 'css
           org-html-doctype "html5"
           org-html-html5-fancy t)

    (defun org-html-reload-fancy-style ()
      (interactive)
      (setq org-html-style-fancy
    	(concat (f-read-text (expand-file-name "misc/org-export-header.html" doom-private-dir))
    		"<script>\n"
    		(f-read-text (expand-file-name "misc/org-css/main.js" doom-private-dir))
    		"</script>\n<style>\n"
    		(f-read-text (expand-file-name "misc/org-css/main.min.css" doom-private-dir))
    		"</style>"))
      (when org-fancy-html-export-mode
        (setq org-html-style-default org-html-style-fancy)))
    (org-html-reload-fancy-style)
    ```

<!--list-separator-->

-  可折叠的 src 和示例块

    通过将 `<pre>` 元素包装在 `<details>` 块中，我们可以得到没有 CSS 的可折叠块，尽管我们会稍微折腾一下，让这看起来有点漂亮。

    由于默认情况下对某些代码块启用可折叠性似乎很有用，因此如果您可以使用
    `#+attr_html: :collapsed t` 设置它会更好。

    如果有一个相应的全局/会话本地方式来设置它会很好，但我还没能让它正常工作。

    ```emacs-lisp
    (defvar org-html-export-collapsed nil)
    (eval '(cl-pushnew '(:collapsed "COLLAPSED" "collapsed" org-html-export-collapsed t)
    		   (org-export-backend-options (org-export-get-backend 'html))))
    (add-to-list 'org-default-properties "EXPORT_COLLAPSED")
    ```

    我们可以进一步修改 src 块，并在 src 块的一侧添加一个块，其中包含引用当前块的锚点和复制块内容的按钮。

    ```emacs-lisp
    (defadvice! org-html-src-block-collapsable (orig-fn src-block contents info)
      "Wrap the usual <pre> block in a <details>"
      :around #'org-html-src-block
      (if (or (not org-fancy-html-export-mode) (bound-and-true-p org-msg-export-in-progress))
          (funcall orig-fn src-block contents info)
        (let* ((properties (cadr src-block))
    	   (lang (mode-name-to-lang-name
    		  (plist-get properties :language)))
    	   (name (plist-get properties :name))
    	   (ref (org-export-get-reference src-block info))
    	   (collapsed-p (member (or (org-export-read-attribute :attr_html src-block :collapsed)
    				    (plist-get info :collapsed))
    				'("y" "yes" "t" t "true" "all"))))
          (format
           "<details id='%s' class='code'%s><summary%s>%s</summary>
    <div class='gutter'>
    <a href='#%s'>#</a>
    <button title='Copy to clipboard' onclick='copyPreToClipbord(this)'>⎘</button>\
    </div>
    %s
    </details>"
           ref
           (if collapsed-p "" " open")
           (if name " class='named'" "")
           (concat
    	(when name (concat "<span class=\"name\">" name "</span>"))
    	"<span class=\"lang\">" lang "</span>")
           ref
           (if name
    	   (replace-regexp-in-string (format "<pre\\( class=\"[^\"]+\"\\)? id=\"%s\">" ref) "<pre\\1>"
    				     (funcall orig-fn src-block contents info))
    	 (funcall orig-fn src-block contents info))))))

    (defun mode-name-to-lang-name (mode)
      (or (cadr (assoc mode
    		   '(("asymptote" "Asymptote")
    		     ("awk" "Awk")
    		     ("C" "C")
    		     ("clojure" "Clojure")
    		     ("css" "CSS")
    		     ("D" "D")
    		     ("ditaa" "ditaa")
    		     ("dot" "Graphviz")
    		     ("calc" "Emacs Calc")
    		     ("emacs-lisp" "Emacs Lisp")
    		     ("fortran" "Fortran")
    		     ("gnuplot" "gnuplot")
    		     ("haskell" "Haskell")
    		     ("hledger" "hledger")
    		     ("java" "Java")
    		     ("js" "Javascript")
    		     ("latex" "LaTeX")
    		     ("ledger" "Ledger")
    		     ("lisp" "Lisp")
    		     ("lilypond" "Lilypond")
    		     ("lua" "Lua")
    		     ("matlab" "MATLAB")
    		     ("mscgen" "Mscgen")
    		     ("ocaml" "Objective Caml")
    		     ("octave" "Octave")
    		     ("org" "Org mode")
    		     ("oz" "OZ")
    		     ("plantuml" "Plantuml")
    		     ("processing" "Processing.js")
    		     ("python" "Python")
    		     ("R" "R")
    		     ("ruby" "Ruby")
    		     ("sass" "Sass")
    		     ("scheme" "Scheme")
    		     ("screen" "Gnu Screen")
    		     ("sed" "Sed")
    		     ("sh" "shell")
    		     ("sql" "SQL")
    		     ("sqlite" "SQLite")
    		     ("forth" "Forth")
    		     ("io" "IO")
    		     ("J" "J")
    		     ("makefile" "Makefile")
    		     ("maxima" "Maxima")
    		     ("perl" "Perl")
    		     ("picolisp" "Pico Lisp")
    		     ("scala" "Scala")
    		     ("shell" "Shell Script")
    		     ("ebnf2ps" "ebfn2ps")
    		     ("cpp" "C++")
    		     ("abc" "ABC")
    		     ("coq" "Coq")
    		     ("groovy" "Groovy")
    		     ("bash" "bash")
    		     ("csh" "csh")
    		     ("ash" "ash")
    		     ("dash" "dash")
    		     ("ksh" "ksh")
    		     ("mksh" "mksh")
    		     ("posh" "posh")
    		     ("ada" "Ada")
    		     ("asm" "Assembler")
    		     ("caml" "Caml")
    		     ("delphi" "Delphi")
    		     ("html" "HTML")
    		     ("idl" "IDL")
    		     ("mercury" "Mercury")
    		     ("metapost" "MetaPost")
    		     ("modula-2" "Modula-2")
    		     ("pascal" "Pascal")
    		     ("ps" "PostScript")
    		     ("prolog" "Prolog")
    		     ("simula" "Simula")
    		     ("tcl" "tcl")
    		     ("tex" "LaTeX")
    		     ("plain-tex" "TeX")
    		     ("verilog" "Verilog")
    		     ("vhdl" "VHDL")
    		     ("xml" "XML")
    		     ("nxml" "XML")
    		     ("conf" "Configuration File"))))
          mode))
    ```

<!--list-separator-->

-  HTML 化的字体锁

    Org 使用 [htmlize.el](https://github.com/hniksic/emacs-htmlize) 导出带有语法高亮的缓冲区。

    在大多数情况下这些格式非常棒。不需要加载提供字体锁定的次要模式，因此不会影响结果。

    通过在 `htmlize-before-hook` 中启用这些模式，我们可以纠正这种行为。

    ```emacs-lisp
    (autoload #'highlight-numbers--turn-on "highlight-numbers")
    (add-hook 'htmlize-before-hook #'highlight-numbers--turn-on)
    ```

<!--list-separator-->

-  处理表溢出

    为了适应宽表 --- 尤其是在移动设备上 --- 我们想要设置最大宽度和滚动溢出。不幸的是，这不能直接应用于 `表格` 元素，所以我们必须将它包装在一个 `div` 中。

    当我们这样做时，我们可以像我们对 src 块所做的那样，设置一个链接块，并显示
    `#+name` (如果有的话)。

    ```emacs-lisp
    (defadvice! org-html-table-wrapped (orig-fn table contents info)
      "Wrap the usual <table> in a <div>"
      :around #'org-html-table
      (if (or (not org-fancy-html-export-mode) (bound-and-true-p org-msg-export-in-progress))
          (funcall orig-fn table contents info)
        (let* ((name (plist-get (cadr table) :name))
    	   (ref (org-export-get-reference table info)))
          (format "<div id='%s' class='table'>
    <div class='gutter'><a href='#%s'>#</a></div>
    <div class='tabular'>
    %s
    </div>\
    </div>"
    	      ref ref
    	      (if name
    		  (replace-regexp-in-string (format "<table id=\"%s\"" ref) "<table"
    					    (funcall orig-fn table contents info))
    		(funcall orig-fn table contents info))))))
    ```

<!--list-separator-->

-  可展开的目录树

    TOC 作为可折叠树更易于导航。不幸的是，我们不能单独使用 CSS 来实现这一点。值得庆幸的是，我们可以通过调整 TOC 生成代码来为每个项目使用一个 `标签` ，以及一个隐藏的
    `复选框` 来跟踪状态，从而避免使用 JS。

    要添加它，我们需要在 `org-html--format-toc-headline` 中更改一行。

    因为我们实际上可以通过在函数周围添加建议来实现所需的效果，而无需覆盖它 --- 让我们这样做来减少这个配置的错误表面。

    ```emacs-lisp
    (defadvice! org-html--format-toc-headline-colapseable (orig-fn headline info)
      "Add a label and checkbox to `org-html--format-toc-headline's usual output,
    to allow the TOC to be a collapseable tree."
      :around #'org-html--format-toc-headline
      (if (or (not org-fancy-html-export-mode) (bound-and-true-p org-msg-export-in-progress))
          (funcall orig-fn headline info)
        (let ((id (or (org-element-property :CUSTOM_ID headline)
    		  (org-export-get-reference headline info))))
          (format "<input type='checkbox' id='toc--%s'/><label for='toc--%s'>%s</label>"
    	      id id (funcall orig-fn headline info)))))
    ```

    现在，叶子 (没有子标题的标题) 不应该有 `标签项` 。实现这一点的明显方法是在
    `org-html--format-toc-headline-colapseable` 中包含一些 (如果没有子项) 逻辑。不幸的是，我的 elisp 无法从 org 提供的大量信息中提取子标题的数量。

    ```emacs-lisp
    (defadvice! org-html--toc-text-stripped-leaves (orig-fn toc-entries)
      "Remove label"
      :around #'org-html--toc-text
      (if (or (not org-fancy-html-export-mode) (bound-and-true-p org-msg-export-in-progress))
          (funcall orig-fn toc-entries)
        (replace-regexp-in-string "<input [^>]+><label [^>]+>\\(.+?\\)</label></li>" "\\1</li>"
    			      (funcall orig-fn toc-entries))))
    ```

<!--list-separator-->

-  使 verbatim 与 code 不同

    让我们为 `varbatim` 和 `code` 添加一些差异。

    我们可以将 `code` 专门用于代码片段和命令，例如：在 Emacs 的批处理模式中调用
    `(message "Hello")` 会像 `echo` 一样打印到标准输出。 可以对
    `verbatim` 使用各种 '其他等宽'，例如键盘快捷键： `C-c C-c` 或 `C-g` 可能是
    Emacs 中最有用的快捷键，或文件名：我将我的配置保存在 `~/.config/doom/` 中，其他情况则使用正常样式。

    ```emacs-lisp
    (setq org-html-text-markup-alist
          '((bold . "<b>%s</b>")
    	(code . "<code>%s</code>")
    	(italic . "<i>%s</i>")
    	(strike-through . "<del>%s</del>")
    	(underline . "<span class=\"underline\">%s</span>")
    	(verbatim . "<kbd>%s</kbd>")))
    ```

<!--list-separator-->

-  改变复选框类型

    我们也想使用 HTML 复选框，但是我们想比默认的更漂亮

    ```emacs-lisp
    (appendq! org-html-checkbox-types
    	  '((html-span
    	     (on . "<span class='checkbox'></span>")
    	     (off . "<span class='checkbox'></span>")
    	     (trans . "<span class='checkbox'></span>"))))
    (setq org-html-checkbox-type 'html-span)
    ```

    -   [ ] I'm yet to do this
    -   [-] Work in progress
    -   [X] This is done

<!--list-separator-->

-  额外的特殊字符串

    `org-html-special-string-regexps` 变量定义了以下内容的替换：

    -   `\-`, shy 连字符
    -   `---`, 增强的破折号
    -   `--`, 破折号
    -   `...`, (水平的) 省略号

    但我认为如果还可以替换左/右箭头 (`->` 和 `<-`) 那就更好了。 这是一个
    `defconst` ，但正如你可以从这个配置中的大量建议中看出的那样，我并没有放弃我不 '应该' 做的事情。

    唯一的小麻烦是在这个阶段的输出处理之前 `<` 和 `>` 被转换为 `&lt;` 和 `&gt;` 。

    ```emacs-lisp
    (pushnew! org-html-special-string-regexps
    	  '("-&gt;" . "&#8594;")
    	  '("&lt;-" . "&#8592;"))
    ```

<!--list-separator-->

-  标题锚点

    一个 GitHub 风格的标题链接

    ```emacs-lisp
    (defun org-export-html-headline-anchor (text backend info)
      (when (and (org-export-derived-backend-p backend 'html)
    	     (not (org-export-derived-backend-p backend 're-reveal))
    	     org-fancy-html-export-mode)
        (unless (bound-and-true-p org-msg-export-in-progress)
          (replace-regexp-in-string
           "<h\\([0-9]\\) id=\"\\([a-z0-9-]+\\)\">\\(.*[^ ]\\)<\\/h[0-9]>" ; this is quite restrictive, but due to `org-reference-contraction' I can do this
           "<h\\1 id=\"\\2\">\\3<a aria-hidden=\"true\" href=\"#\\2\">#</a> </h\\1>"
           text))))

    (add-to-list 'org-export-filter-headline-functions
    	     'org-export-html-headline-anchor)
    ```

<!--list-separator-->

-  链接预览

    有时让链接特别突出会很好，我认为像 Twitter 那样的嵌入 / 预览会很好。

    我们可以通过添加一个与 `https` --- `Https` 略有不同的新链接类型来轻松做到这点。

    ```emacs-lisp
    (org-link-set-parameters "Https"
    			 :follow (lambda (url arg) (browse-url (concat "https:" url) arg))
    			 :export #'org-url-fancy-export)
    ```

    ```emacs-lisp
    (defun org-url-fancy-export (url _desc backend)
      (let ((metadata (org-url-unfurl-metadata (concat "https:" url))))
        (cond
         ((org-export-derived-backend-p backend 'html)
          (concat
           "<div class=\"link-preview\">"
           (format "<a href=\"%s\">" (concat "https:" url))
           (when (plist-get metadata :image)
    	 (format "<img src=\"%s\"/>" (plist-get metadata :image)))
           "<small>"
           (replace-regexp-in-string "//\\(?:www\\.\\)?\\([^/]+\\)/?.*" "\\1" url)
           "</small><p>"
           (when (plist-get metadata :title)
    	 (concat "<b>" (org-html-encode-plain-text (plist-get metadata :title)) "</b></br>"))
           (when (plist-get metadata :description)
    	 (org-html-encode-plain-text (plist-get metadata :description)))
           "</p></a></div>"))
         (t url))))
    ```

    现在我们只需要实现元数据提取功能。

    ```emacs-lisp
    (setq! org-url-unfurl-metadata--cache nil)
    (defun org-url-unfurl-metadata (url)
      (cdr (or (assoc url org-url-unfurl-metadata--cache)
    	   (car (push
    		 (cons
    		  url
    		  (let* ((head-data
    			  (-filter #'listp
    				   (cdaddr
    				    (with-current-buffer (progn (message "Fetching metadata from %s" url)
    								(url-retrieve-synchronously url t t 5))
    				      (goto-char (point-min))
    				      (delete-region (point-min) (- (search-forward "<head") 6))
    				      (delete-region (search-forward "</head>") (point-max))
    				      (goto-char (point-min))
    				      (while (re-search-forward "<script[^\u2800]+?</script>" nil t)
    					(replace-match ""))
    				      (goto-char (point-min))
    				      (while (re-search-forward "<style[^\u2800]+?</style>" nil t)
    					(replace-match ""))
    				      (libxml-parse-html-region (point-min) (point-max))))))
    			 (meta (delq nil
    				     (mapcar
    				      (lambda (tag)
    					(when (eq 'meta (car tag))
    					  (cons (or (cdr (assoc 'name (cadr tag)))
    						    (cdr (assoc 'property (cadr tag))))
    						(cdr (assoc 'content (cadr tag))))))
    				      head-data))))
    		    (let ((title (or (cdr (assoc "og:title" meta))
    				     (cdr (assoc "twitter:title" meta))
    				     (nth 2 (assq 'title head-data))))
    			  (description (or (cdr (assoc "og:description" meta))
    					   (cdr (assoc "twitter:description" meta))
    					   (cdr (assoc "description" meta))))
    			  (image (or (cdr (assoc "og:image" meta))
    				     (cdr (assoc "twitter:image" meta)))))
    		      (when image
    			(setq image (replace-regexp-in-string
    				     "^/" (concat "https://" (replace-regexp-in-string "//\\([^/]+\\)/?.*" "\\1" url) "/")
    				     (replace-regexp-in-string
    				      "^//" "https://"
    				      image))))
    		      (list :title title :description description :image image))))
    		 org-url-unfurl-metadata--cache)))))
    ```

<!--list-separator-->

-  LaTeX Rendering

    如果使用 MathJax，就用 3 而不是 2。通过[对比](https://www.intmath.com/cg5/katex-mathjax-comparison.php)我们发现它似乎快了 5 倍，而且它使用单个文件而不是多个文件，就是有点大而已。值得庆幸的是，这可以通过添加 `async` 属性来延迟加载来缓解。

    ```emacs-lisp
    (setq! org-html-mathjax-options
          '((path "https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-svg.js" )
    	(scale "1")
    	(autonumber "ams")
    	(multlinewidth "85%")
    	(tagindent ".8em")
    	(tagside "right")))

    (setq! org-html-mathjax-template
          "<script>
    MathJax = {
      loader: {
        load: ['[tex]/ams', '[tex]/upgreek', '[tex]/mathtools']
      },
      chtml: {
        scale: %SCALE
      },
      svg: {
        scale: %SCALE,
        fontCache: \"global\"
      },
      tex: {
        packages: {'[+]': ['ams', 'upgreek', 'mathtools']},
        tags: \"%AUTONUMBER\",
        multlineWidth: \"%MULTLINEWIDTH\",
        tagSide: \"%TAGSIDE\",
        tagIndent: \"%TAGINDENT\"
      }
    };
    </script>
    <script id=\"MathJax-script\" async
    	src=\"%PATH\"></script>")
    ```


#### LaTeX 导出 {#latex-导出}

```emacs-lisp
(after! ox-latex
  <<ox-latex-conf>>)
```

<!--list-separator-->

-  编译

    默认情况下，Org 使用 `pdflatex` &times; 3 + `bibtex` 。 这在现代世界根本行不通。
    `latexmk` + `biber` (自动与 `latexmk` 一起使用) 是一个简单且优越组合。

    ```emacs-lisp
    ;; org-latex-compilers = ("pdflatex" "xelatex" "lualatex"), which are the possible values for %latex
    (setq! org-latex-pdf-process '("latexmk -f -pdf -%latex -shell-escape -interaction=nonstopmode -output-directory=%o %f"))
    ```

    虽然上面的 `-%latex` 有点 hacky (`-pdflatex` 期望被赋予一个值)，但它允许我们保持
    `org-latex-compilers` 不变。如果我打开一个使用 `#+LATEX_COMPILER` 的 org 文件，这很好，它应该仍然可以工作。

<!--list-separator-->

-  复选框

    我们可以假设在序言部分，定义了下面的各种自定义 `\checkbox...` 命令。

    ```emacs-lisp
    (defun +org-export-latex-fancy-item-checkboxes (text backend info)
      (when (org-export-derived-backend-p backend 'latex)
        (replace-regexp-in-string
         "\\\\item\\[{$\\\\\\(\\w+\\)$}\\]"
         (lambda (fullmatch)
           (concat "\\\\item[" (pcase (substring fullmatch 9 -3) ; content of capture group
    			     ("square"   "\\\\checkboxUnchecked")
    			     ("boxminus" "\\\\checkboxTransitive")
    			     ("boxtimes" "\\\\checkboxChecked")
    			     (_ (substring fullmatch 9 -3))) "]"))
         text)))

    (add-to-list 'org-export-filter-item-functions
    	     '+org-export-latex-fancy-item-checkboxes)
    ```

<!--list-separator-->

-  类模板

    页边空白处的节号，这可以用下面的 LaTeX 来完成。

    <a id="code-snippet--latex-hanging-secnum"></a>
    ```LaTeX
    \\renewcommand\\sectionformat{\\llap{\\thesection\\autodot\\enskip}}
    \\renewcommand\\subsectionformat{\\llap{\\thesubsection\\autodot\\enskip}}
    \\renewcommand\\subsubsectionformat{\\llap{\\thesubsubsection\\autodot\\enskip}}
    \\makeatletter
    \\g@addto@macro\\tableofcontents{\\clearpage\\setcounter{page}{1}\\pagenumbering{arabic}}
    \\makeatother
    \\setcounter{page}{1}
    \\pagenumbering{Roman}
    ```

    超大的 `\chapter` 。

    <a id="code-snippet--latex-big-chapter"></a>
    ```LaTeX
    \\RedeclareSectionCommand[afterindent=false, beforeskip=0pt, afterskip=0pt, innerskip=0pt]{chapter}
    \\setkomafont{chapter}{\\normalfont\\Huge}
    \\renewcommand*{\\chapterheadstartvskip}{\\vspace*{0\\baselineskip}}
    \\renewcommand*{\\chapterheadendvskip}{\\vspace*{0\\baselineskip}}
    \\renewcommand*{\\chapterformat}{%
      \\fontsize{60}{30}\\selectfont\\rlap{\\hspace{6pt}\\thechapter}}
    \\renewcommand*\\chapterlinesformat[3]{%
      \\parbox[b]{\\dimexpr\\textwidth-0.5em\\relax}{%
        \\raggedleft{{\\large\\scshape\\bfseries\\chapapp}\\vspace{-0.5ex}\\par\\Huge#3}}%
        \\hfill\\makebox[0pt][l]{#2}}
    ```

    现在在 Org LaTeX 类中添加一些 `KOMA-Script` 。

    ```emacs-lisp
    (let* ((article-sections '(("\\section{%s}" . "\\section*{%s}")
    			   ("\\subsection{%s}" . "\\subsection*{%s}")
    			   ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
    			   ("\\paragraph{%s}" . "\\paragraph*{%s}")
    			   ("\\subparagraph{%s}" . "\\subparagraph*{%s}")))
           (book-sections (append '(("\\chapter{%s}" . "\\chapter*{%s}"))
    			      article-sections))
           (hanging-secnum-preamble "
    <<latex-hanging-secnum>>
    ")
           (big-chap-preamble "
    <<latex-big-chapter>>
    "))
      (setcdr (assoc "article" org-latex-classes)
    	  `(,(concat "\\documentclass{scrartcl}" hanging-secnum-preamble)
    	    ,@article-sections))
      (setcdr (assoc "article" org-latex-classes)
    	  `(,(concat "\\documentclass{scrartcl}" hanging-secnum-preamble)
    	    ,@article-sections))
      (setcdr (assoc "report" org-latex-classes)
    	  `(,(concat "\\documentclass{scrartcl}" hanging-secnum-preamble)
    	    ,@article-sections))
      (setcdr (assoc "book" org-latex-classes)
    	  `(,(concat "\\documentclass[twoside=false]{scrbook}"
    		     big-chap-preamble hanging-secnum-preamble)
    	    ,@book-sections)))

    (setq! org-latex-tables-booktabs t
           org-latex-hyperref-template "
    <<latex-fancy-hyperref>>
    "
           org-latex-reference-command "\\cref{%s}")
    ```

    然而 `hyperref` 设置需要单独处理。

    <a id="code-snippet--latex-fancy-hyperref"></a>
    ```LaTeX
    \\providecolor{url}{HTML}{0077bb}
    \\providecolor{link}{HTML}{882255}
    \\providecolor{cite}{HTML}{999933}
    \\hypersetup{
      pdfauthor={%a},
      pdftitle={%t},
      pdfkeywords={%k},
      pdfsubject={%d},
      pdfcreator={%c},
      pdflang={%L},
      breaklinks=true,
      colorlinks=true,
      linkcolor=link,
      urlcolor=url,
      citecolor=cite\n}
    \\urlstyle{same}
    ```

<!--list-separator-->

-  智能序言

    <!--list-separator-->

    -  功能优化

        Caption 可以做一些调整，比如

        -   可以轻松拥有多个 Caption
        -   指向图的链接带到图的顶部 (而不是底部)
        -   Caption 标签可以稍微加粗一点
        -   只有当跨越多行时，多行 Caption 应该向右一点

        <!--listend-->

        <a id="code-snippet--org-latex-caption-preamble"></a>
        ```LaTeX
        \\usepackage{subcaption}
        \\usepackage[hypcap=true]{caption}
        \\setkomafont{caption}{\\sffamily\\small}
        \\setkomafont{captionlabel}{\\upshape\\bfseries}
        \\captionsetup{justification=raggedright,singlelinecheck=true}
        \\usepackage{capt-of} % required by Org
        ```

        默认的复选框太丑了，用一些好看的替代品吧。

        <a id="code-snippet--org-latex-checkbox-preamble"></a>
        ```LaTeX
        \\newcommand{\\checkboxUnchecked}{$\\square$}
        \\newcommand{\\checkboxTransitive}{\\rlap{\\raisebox{-0.1ex}{\\hspace{0.35ex}\\Large\\textbf -}}$\\square$}
        \\newcommand{\\checkboxChecked}{\\rlap{\\raisebox{0.2ex}{\\hspace{0.35ex}\\scriptsize \\ding{52}}}$\\square$}
        ```

        "消息块" 是一个不错的想法，就像 info/warning/error/success。LaTeX 中的宏可以创建它们。

        <a id="code-snippet--org-latex-box-preamble"></a>
        ```LaTeX
        \\ExplSyntaxOn
        \\NewCoffin\\Content
        \\NewCoffin\\SideRule
        \\NewDocumentCommand{\\defsimplebox}{O{\\ding{117}} O{0.36em} m m m}{%
          % #1 ding, #2 ding offset, #3 name, #4 colour, #5 default label
          \\definecolor{#3}{HTML}{#4}
          \\NewDocumentEnvironment{#3}{ O{#5} }
          {
            \\vcoffin_set:Nnw \\Content { \\linewidth }
            \\noindent \\ignorespaces
            \\par\\vspace{-0.7\\baselineskip}%
            \\textcolor{#3}{#1}~\\textcolor{#3}{\\textbf{##1}}%
            \\vspace{-0.8\\baselineskip}
            \\begin{addmargin}[1em]{1em}
            }
            {
            \\end{addmargin}
            \\vspace{-0.5\\baselineskip}
            \\vcoffin_set_end:
            \\SetHorizontalCoffin\\SideRule{\\color{#3}\\rule{1pt}{\\CoffinTotalHeight\\Content}}
            \\JoinCoffins*\\Content[l,t]\\SideRule[l,t](#2,-0.7em)
            \\noindent\\TypesetCoffin\\Content
            \\vspace*{\\CoffinTotalHeight\\Content}\\bigskip
            \\vspace{-2\\baselineskip}
          }
        }
        \\ExplSyntaxOff
        ```

        最后，我们会将这些内容传递到一些全局变量中，以便于访问。

        ```emacs-lisp
        (defvar org-latex-caption-preamble "
        <<org-latex-caption-preamble>>
        "
          "Preamble that improves captions.")

        (defvar org-latex-checkbox-preamble "
        <<org-latex-checkbox-preamble>>
        "
          "Preamble that improves checkboxes.")

        (defvar org-latex-box-preamble "
        <<org-latex-box-preamble>>
        "
          "Preamble that provides a macro for custom boxes.")
        ```

    <!--list-separator-->

    -  内容-特征-序言关联

        每个检测到的特征都会给出一个所需的「特征标志」列表。只需合并功能标志列表，不再需要避免 LaTeX 的重复。然后额外的层在特征标志和可用于实现该特征的规范之间形成双射。

        {{< figure src="/images/orgmode-latex-clever-preamble.svg" alt="DAG showing how Org features flow through to LaTeX" caption="<span class=\"figure-number\">Figure 1: </span>Org 功能、功能标志和 LaTeX 片段之间的关联" class="invertible" width="55%" >}}

        首先，我们将实现该模型的特征检测组件。我希望它能够使用尽可能多的状态信息，因此功能测试应该非常通用。

        ```emacs-lisp
        (defvar org-latex-italic-quotes t
          "Make \"quote\" environments italic.")
        (defvar org-latex-par-sep t
          "Vertically seperate paragraphs, and remove indentation.")

        (defvar org-latex-conditional-features
          '(("\\[\\[\\(?:file\\|https?\\):\\(?:[^]]\\|\\\\\\]\\)+?\\.\\(?:eps\\|pdf\\|png\\|jpeg\\|jpg\\|jbig2\\)\\]\\]\\|\\\\includegraphics[\\[{]" . image)
            ("\\[\\[\\(?:file\\|https?\\):\\(?:[^]]+?\\|\\\\\\]\\)\\.svg\\]\\]\\|\\\\includesvg[\\[{]" . svg)
            ("\\\\(\\|\\\\\\[\\|\\\\begin{\\(?:math\\|displaymath\\|equation\\|align\\|flalign\\|multiline\\|gather\\)[a-z]*\\*?}" . maths)
            ("^[ \t]*|" . table)
            ("cref:\\|\\cref{\\|\\[\\[[^\\]+\n?[^\\]\\]\\]" . cleveref)
            ("[;\\\\]?\\b[A-Z][A-Z]+s?[^A-Za-z]" . acronym)
            ("\\+[^ ].*[^ ]\\+\\|_[^ ].*[^ ]_\\|\\\\uu?line\\|\\\\uwave\\|\\\\sout\\|\\\\xout\\|\\\\dashuline\\|\\dotuline\\|\\markoverwith" . underline)
            (":float wrap" . float-wrap)
            (":float sideways" . rotate)
            ("^[ \t]*#\\+caption:\\|\\\\caption" . caption)
            ("\\[\\[xkcd:" . (image caption))
            ((and org-latex-italic-quotes "^[ \t]*#\\+begin_quote\\|\\\\begin{quote}") . italic-quotes)
            (org-latex-par-sep . par-sep)
            ("^[ \t]*\\(?:[-+*]\\|[0-9]+[.)]\\|[A-Za-z]+[.)]\\) \\[[ -X]\\]" . checkbox)
            ("^[ \t]*#\\+begin_warning\\|\\\\begin{warning}" . box-warning)
            ("^[ \t]*#\\+begin_info\\|\\\\begin{info}"       . box-info)
            ("^[ \t]*#\\+begin_notes\\|\\\\begin{notes}"     . box-notes)
            ("^[ \t]*#\\+begin_success\\|\\\\begin{success}" . box-success)
            ("^[ \t]*#\\+begin_error\\|\\\\begin{error}"     . box-error))
          "Org feature tests and associated LaTeX feature flags.

        Alist where the car is a test for the presense of the feature,
        and the cdr is either a single feature symbol or list of feature symbols.

        When a string, it is used as a regex search in the buffer.
        The feature is registered as present when there is a match.

        The car can also be a
        - symbol, the value of which is fetched
        - function, which is called with info as an argument
        - list, which is `eval'uated

        If the symbol, function, or list produces a string: that is used as a regex
        search in the buffer. Otherwise any non-nil return value will indicate the
        existance of the feature.")
        ```

        然后我们提供一种方法来生成提供这些功能的序言。除了
        `org-latex-conditional-features` 中命名的特性之外，我们还将创建元特性，这些特性可能是其他特性所需要的 (`:requires`)，或者默认情况下是启用的
        (`:eager t`)。为了进一步控制，我只能在某些其他功能处于启用状态 (`:when`) 并被其他功能屏蔽 (`:prevents`) 时使用某些功能。我将使用以 `.` 开头的元功能的约定，以及以 `!` 开头的 `:eager` 功能，使它们的性质更明显。

        LaTeX 中的另一个考虑因素是加载顺序，这在某些情况下很重要。除此之外，有某种合理的排序是很好的。为此我将介绍一个 `:order` 关键字。使用它将按如下方式排列片段。

        -   `-2` 嵌入文件设置
        -   `-1` 额外的文件嵌入
        -   `0` 排版

            -   `0` 字体本身

            <!--listend-->

            -   `0.2` 数学设置
            -   `0.3` 数学字体
            -   `0.4` 额外的文字整形 (`\acr`)
            -   `0.5-0.9` 其他文本修改，尝试将较短的片段放在首位
        -   `1` (_default_)
        -   `2` 表和图
        -   `3` 其他短内容
        -   `4` 各种 boxes

        <!--listend-->

        ```emacs-lisp
        (defvar org-latex-feature-implementations
          '((image         :snippet "\\usepackage{graphicx}" :order 2)
            (svg           :snippet "\\usepackage[inkscapelatex=false]{svg}" :order 2)
            (maths         :snippet "\\usepackage{amsmath,amsxtra,amsfonts,amssymb,amsthm,mathtools,upgreek,extarrows}\n\\usepackage[math-style=ISO]{unicode-math}" :order 0.2)
            (table         :snippet "\\usepackage{longtable}\n\\usepackage{booktabs}" :order 2)
            (cleveref      :snippet "\\usepackage[capitalize]{cleveref}" :order 1) ; after bmc-maths
            (underline     :snippet "\\usepackage[normalem]{ulem}" :order 0.5)
            (float-wrap    :snippet "\\usepackage{wrapfig}" :order 2)
            (rotate        :snippet "\\usepackage{rotating}" :order 2)
            (caption       :snippet org-latex-caption-preamble :order 2.1)
            ;; (microtype     :snippet "\\usepackage[activate={true,nocompatibility},final,tracking=true,kerning=true,spacing=true,factor=2000]{microtype}\n" :order 0.1)
            (acronym       :snippet "\\newcommand{\\acr}[1]{\\protect\\textls*[110]{\\scshape #1}}\n\\newcommand{\\acrs}{\\protect\\scalebox{.91}[.84]{\\hspace{0.15ex}s}}" :order 0.4)
            (italic-quotes :snippet "\\renewcommand{\\quote}{\\list{}{\\rightmargin\\leftmargin}\\item\\relax\\em}\n" :order 0.5)
            (par-sep       :snippet "\\setlength{\\parskip}{\\baselineskip}\n\\setlength{\\parindent}{0pt}\n" :order 0.5)
            (.pifont       :snippet "\\usepackage{pifont}")
            (.xcoffins     :snippet "\\usepackage{xcoffins}")
            (checkbox      :requires .pifont :order 3
        		   :snippet (concat (unless (memq 'maths features)
        				      "\\usepackage{amssymb} % provides \\square")
        				    org-latex-checkbox-preamble))
            (.fancy-box    :requires (.pifont .xcoffins) :snippet org-latex-box-preamble :order 3.9)
            (box-warning   :requires .fancy-box :snippet "\\defsimplebox{warning}{e66100}{Warning}" :order 4)
            (box-info      :requires .fancy-box :snippet "\\defsimplebox{info}{3584e4}{Information}" :order 4)
            (box-notes     :requires .fancy-box :snippet "\\defsimplebox{notes}{26a269}{Notes}" :order 4)
            (box-success   :requires .fancy-box :snippet "\\defsimplebox{success}{26a269}{\\vspace{-\\baselineskip}}" :order 4)
            (box-error     :requires .fancy-box :snippet "\\defsimplebox{error}{c01c28}{Important}" :order 4))
          "LaTeX features and details required to implement them.

        List where the car is the feature symbol, and the rest forms a plist with the
        following keys:
        - :snippet, which may be either
          - a string which should be included in the preamble
          - a symbol, the value of which is included in the preamble
          - a function, which is evaluated with the list of feature flags as its
            single argument. The result of which is included in the preamble
          - a list, which is passed to `eval', with a list of feature flags available
            as \"features\"

        - :requires, a feature or list of features that must be available
        - :when, a feature or list of features that when all available should cause this
            to be automatically enabled.
        - :prevents, a feature or list of features that should be masked
        - :order, for when ordering is important. Lower values appear first.
            The default is 0.
        - :eager, when non-nil the feature will be eagerly loaded, i.e. without being detected.")
        ```

    <!--list-separator-->

    -  特征确定

        现在我们已经定义了 `org-latex-conditional-features` ，我们需要使用它来提取在 Org 缓冲区中找到的特征列表。

        ```emacs-lisp
        (defun org-latex-detect-features (&optional buffer info)
          "List features from `org-latex-conditional-features' detected in BUFFER."
          (let ((case-fold-search nil))
            (with-current-buffer (or buffer (current-buffer))
              (delete-dups
               (mapcan (lambda (construct-feature)
        		 (when (let ((out (pcase (car construct-feature)
        				    ((pred stringp) (car construct-feature))
        				    ((pred functionp) (funcall (car construct-feature) info))
        				    ((pred listp) (eval (car construct-feature)))
        				    ((pred symbolp) (symbol-value (car construct-feature)))
        				    (_ (user-error "org-latex-conditional-features key %s unable to be used" (car construct-feature))))))
        			 (if (stringp out)
        			     (save-excursion
        			       (goto-char (point-min))
        			       (re-search-forward out nil t))
        			   out))
        		   (if (listp (cdr construct-feature)) (cdr construct-feature) (list (cdr construct-feature)))))
        	       org-latex-conditional-features)))))
        ```

    <!--list-separator-->

    -  序言生成

        一旦确定了所需功能的列表，我们希望使用 `org-latex-feature-implementations`
        来生成 LaTeX，该 LaTeX 应该插入到序言中以提供这些功能。

        首先，我们要在 `org-latex-feature-implementations` 中处理我们的关键字，以生成扩展的功能列表。我们将通过执行以下步骤来做到这一点。

        -   每个列出的功能的依赖项都添加到功能列表 (`:requires`) 中。
        -   每个特性的 `:when` 条件，以及带有 `:eager t` 的可用特性，都会被评估，并相应地添加 / 删除
        -   `:prevents` 值中存在的任何特性都将被删除
        -   功能列表清除重复项
        -   特征列表按 `:order` (升序) 排序

        <!--listend-->

        ```emacs-lisp
        (defun org-latex-expand-features (features)
          "For each feature in FEATURES process :requires, :when, and :prevents keywords and sort according to :order."
          (dolist (feature features)
            (unless (assoc feature org-latex-feature-implementations)
              (message "Feature %s not provided in org-latex-feature-implementations, ignoring." feature)
              (setq features (remove feature features))))
          (setq current features)
          (while current
            (when-let ((requirements (plist-get (cdr (assq (car current) org-latex-feature-implementations)) :requires)))
              (setcdr current (if (listp requirements)
        			  (append requirements (cdr current))
        			(cons requirements (cdr current)))))
            (setq current (cdr current)))
          (dolist (potential-feature
        	   (append features (delq nil (mapcar (lambda (feat)
        						(when (plist-get (cdr feat) :eager)
        						  (car feat)))
        					      org-latex-feature-implementations))))
            (when-let ((prerequisites (plist-get (cdr (assoc potential-feature org-latex-feature-implementations)) :when)))
              (setf features (if (if (listp prerequisites)
        			     (cl-every (lambda (preq) (memq preq features)) prerequisites)
        			   (memq prerequisites features))
        			 (append (list potential-feature) features)
        		       (delq potential-feature features)))))
          (dolist (feature features)
            (when-let ((prevents (plist-get (cdr (assoc feature org-latex-feature-implementations)) :prevents)))
              (setf features (cl-set-difference features (if (listp prevents) prevents (list prevents))))))
          (sort (delete-dups features)
        	(lambda (feat1 feat2)
        	  (if (< (or (plist-get (cdr (assoc feat1 org-latex-feature-implementations)) :order) 1)
        		 (or (plist-get (cdr (assoc feat2 org-latex-feature-implementations)) :order) 1))
        	      t nil))))
        ```

        现在我们有一个很好的最终要使用的特性列表，可以提取它们的片段并将结果连接在一起。

        ```emacs-lisp
        (defun org-latex-generate-features-preamble (features)
          "Generate the LaTeX preamble content required to provide FEATURES.
        This is done according to `org-latex-feature-implementations'"
          (let ((expanded-features (org-latex-expand-features features)))
            (concat
             (format "\n%% features: %s\n" expanded-features)
             (mapconcat (lambda (feature)
        		  (when-let ((snippet (plist-get (cdr (assoc feature org-latex-feature-implementations)) :snippet)))
        		    (concat
        		     (pcase snippet
        		       ((pred stringp) snippet)
        		       ((pred functionp) (funcall snippet features))
        		       ((pred listp) (eval `(let ((features ',features)) (,@snippet))))
        		       ((pred symbolp) (symbol-value snippet))
        		       (_ (user-error "org-latex-feature-implementations :snippet value %s unable to be used" snippet)))
        		     "\n")))
        		expanded-features
        		"")
             "% end features\n")))
        ```

        然后需要建议 Org 实际使用这个生成的前导内容。

        ```emacs-lisp
        (defvar info--tmp nil)

        (defadvice! org-latex-save-info (info &optional t_ s_)
          :before #'org-latex-make-preamble
          (setq info--tmp info))

        (defadvice! org-splice-latex-header-and-generated-preamble-a (orig-fn tpl def-pkg pkg snippets-p &optional extra)
          "Dynamically insert preamble content based on `org-latex-conditional-preambles'."
          :around #'org-splice-latex-header
          (let ((header (funcall orig-fn tpl def-pkg pkg snippets-p extra)))
            (if snippets-p header
              (concat header
        	      (org-latex-generate-features-preamble (org-latex-detect-features nil info--tmp))
        	      "\n"))))
        ```

        我对 `info--tmp` 的使用有点老套。 当我尝试将其上游化时，这应该会变得更加清晰，因为我可以通过直接修改 `org-latex-make-preamble` 来传递信息。

    <!--list-separator-->

    -  减少默认包

        由于上文添加，我们可以从 `org-latex-default-packages-alist` 中删除一些包。

        默认值中也有一些过时的条目，具体来说

        -   `grffile` 的功能内置于当前版本的 `graphicsx`
        -   `textcomp` 的功能已经包含在 LaTeX 的核心中一段时间了

        <!--listend-->

        ```emacs-lisp
        (setq! org-latex-default-packages-alist
               '(("AUTO" "inputenc" t ("pdflatex"))
        	 ("T1" "fontenc" t ("pdflatex"))
        	 ("" "xcolor" nil) ; Generally useful
        	 ("" "hyperref" nil)))
        ```

<!--list-separator-->

-  字体

    中文字体不在设置之列，毕竟 `xeCJK` 是 `xelatex` 专有的包，而 `pdftex` 和
    `luatex` 而且 texlive 并没有将相应的中文字体打包，这给设置中文字体带来一些不便。可以采用手动设置的方式，比如以下采用 `xeCJK` 的方式设置 Source CJK Family。

    ```text
    #+latex_compiler: xelatex
    #+latex_header: \usepackage{xeCJK}
    #+latex_header: \setCJKmainfont{Source Han Serif SC}
    #+latex_header: \setCJKsansfont{Source Han Sans SC}
    #+latex_header: \setCJKmonofont{Source Han Mono SC}
    ```

    首先，将创建一个默认状态变量并将字体集注册为 `#+options` 的一部分。

    ```emacs-lisp
    (defvar org-latex-default-fontset 'alegreya
      "Fontset from `org-latex-fontsets' to use by default.
    As cm (computer modern) is TeX's default, that causes nothing
    to be added to the document.

    If \"nil\" no custom fonts will ever be used.")

    (eval '(cl-pushnew '(:latex-font-set nil "fontset" org-latex-default-fontset)
    		   (org-export-backend-options (org-export-get-backend 'latex))))
    ```

    然后需要一个函数来生成应用字体集的 LaTeX 片段。如果可以为单个样式完成此操作并使用不同样式作为主要文档字体，那就太好了。如果字体集的各个字体分别定义为
    `:serif`、`:sans`、`:mono` 和 `:maths}`。 我可以使用它们为完整字体集的子集生成
    LaTeX。然后，如果我不让任何字体集名称中包含 `-`，我可以使用 `-sans` 和 `-mono`
    作为指定要使用的文档字体的后缀。

    ```emacs-lisp
    (defun org-latex-fontset-entry ()
      "Get the fontset spec of the current file.
    Has format \"name\" or \"name-style\" where 'name' is one of
    the cars in `org-latex-fontsets'."
      (let ((fontset-spec
    	 (symbol-name
    	  (or (car (delq nil
    			 (mapcar
    			  (lambda (opt-line)
    			    (plist-get (org-export--parse-option-keyword opt-line 'latex)
    				       :latex-font-set))
    			  (cdar (org-collect-keywords '("OPTIONS"))))))
    	      org-latex-default-fontset))))
        (cons (intern (car (split-string fontset-spec "-")))
    	  (when (cadr (split-string fontset-spec "-"))
    	    (intern (concat ":" (cadr (split-string fontset-spec "-"))))))))

    (defun org-latex-fontset (&rest desired-styles)
      "Generate a LaTeX preamble snippet which applies the current fontset for DESIRED-STYLES."
      (let* ((fontset-spec (org-latex-fontset-entry))
    	 (fontset (alist-get (car fontset-spec) org-latex-fontsets)))
        (if fontset
    	(concat
    	 (mapconcat
    	  (lambda (style)
    	    (when (plist-get fontset style)
    	      (concat (plist-get fontset style) "\n")))
    	  desired-styles
    	  "")
    	 (when (memq (cdr fontset-spec) desired-styles)
    	   (pcase (cdr fontset-spec)
    	     (:serif "\\renewcommand{\\familydefault}{\\rmdefault}\n")
    	     (:sans "\\renewcommand{\\familydefault}{\\sfdefault}\n")
    	     (:mono "\\renewcommand{\\familydefault}{\\ttdefault}\n"))))
          (error "Font-set %s is not provided in org-latex-fontsets" (car fontset-spec)))))
    ```

    现在所有的功能都已经实现了，我们应该把它挂到我们的序言生成中。

    ```emacs-lisp
    (add-to-list 'org-latex-conditional-features '(org-latex-default-fontset . custom-font) t)
    (add-to-list 'org-latex-feature-implementations '(custom-font :snippet (org-latex-fontset :serif :sans :mono) :order 0) t)
    (add-to-list 'org-latex-feature-implementations '(.custom-maths-font :eager t :when (custom-font maths) :snippet (org-latex-fontset :maths) :order 0.3) t)
    ```

    最后，我们只需要添加一些字体。

    ```emacs-lisp
    (defvar org-latex-fontsets
      '((cm nil) ; computer modern
        (## nil) ; no font set
        (alegreya
         :serif "\\usepackage[osf]{Alegreya}"
         :sans "\\usepackage{AlegreyaSans}"
         :mono "\\usepackage[scale=0.88]{sourcecodepro}"
         :maths "\\usepackage{newtxsf}")
        (biolinum
         :serif "\\usepackage[osf]{libertineRoman}"
         :sans "\\usepackage[sfdefault,osf]{biolinum}"
         :mono "\\usepackage[scale=0.88]{sourcecodepro}"
         :maths "\\usepackage{newtxsf}")
        (fira
         :sans "\\usepackage[sfdefault,scale=0.85]{FiraSans}"
         :mono "\\usepackage[scale=0.80]{FiraMono}"
         :maths "\\usepackage{newtxsf} % change to firamath in future?")
        (kp
         :serif "\\usepackage{kpfonts}")
        (newpx
         :serif "\\usepackage{newpxtext}"
         :sans "\\usepackage{gillius}"
         :mono "\\usepackage[scale=0.9]{sourcecodepro}"
         :maths "\\usepackage[varbb]{newpxmath}")
        (noto
         :serif "\\usepackage[osf]{noto-serif}"
         :sans "\\usepackage[osf]{noto-sans}"
         :mono "\\usepackage[scale=0.96]{noto-mono}"
         :maths "\\usepackage{notomath}")
        (plex
         :serif "\\usepackage{plex-serif}"
         :sans "\\usepackage{plex-sans}"
         :mono "\\usepackage[scale=0.95]{plex-mono}"
         :maths "\\usepackage{newtxmath}") ; may be plex-based in future
        (source
         :serif "\\usepackage[osf,semibold]{sourceserifpro}"
         :sans "\\usepackage[osf,semibold]{sourcesanspro}"
         :mono "\\usepackage[scale=0.92]{sourcecodepro}"
         :maths "\\usepackage{newtxmath}") ; may be sourceserifpro-based in future
        (times
         :serif "\\usepackage{newtxtext}"
         :maths "\\usepackage{newtxmath}"))
      "Alist of fontset specifications.
    Each car is the name of the fontset (which cannot include \"-\").

    Each cdr is a plist with (optional) keys :serif, :sans, :mono, and :maths.
    A key's value is a LaTeX snippet which loads such a font.")
    ```

<!--list-separator-->

-  封面

    要制作漂亮的封面，想到的一个简单方法就是重新定义 `\maketitle` 。为了精确控制定位，我们将使用 `tikz` 包，然后添加 Tikz 库 `calc` 和 `shape.geometric` 来为背景做一些漂亮的装饰。

    首先为序言设置必要的补充。 这将完成以下任务：

    -   加载所需的包
    -   重新定义 `\maketitle`
    -   用 Tikz 画一个 `Org` 图标，用在封面上 (这是一个小彩蛋)
    -   通过重新定义 `\tableofcontents` 在目录之后开始一个新页面

    <!--listend-->

    <a id="code-snippet--latex-cover-page"></a>
    ```LaTeX
    \\usepackage{tikz}
    \\usetikzlibrary{shapes.geometric}
    \\usetikzlibrary{calc}

    \\newsavebox\\orgicon
    \\begin{lrbox}{\\orgicon}
      \\begin{tikzpicture}[y=0.80pt, x=0.80pt, inner sep=0pt, outer sep=0pt]
        \\path[fill=black!6] (16.15,24.00) .. controls (15.58,24.00) and (13.99,20.69) .. (12.77,18.06)arc(215.55:180.20:2.19) .. controls (12.33,19.91) and (11.27,19.09) .. (11.43,18.05) .. controls (11.36,18.09) and (10.17,17.83) .. (10.17,17.82) .. controls (9.94,18.75) and (9.37,19.44) .. (9.02,18.39) .. controls (8.32,16.72) and (8.14,15.40) .. (9.13,13.80) .. controls (8.22,9.74) and (2.18,7.75) .. (2.81,4.47) .. controls (2.99,4.47) and (4.45,0.99) .. (9.15,2.41) .. controls (14.71,3.99) and (17.77,0.30) .. (18.13,0.04) .. controls (18.65,-0.49) and (16.78,4.61) .. (12.83,6.90) .. controls (10.49,8.18) and (11.96,10.38) .. (12.12,11.15) .. controls (12.12,11.15) and (14.00,9.84) .. (15.36,11.85) .. controls (16.58,11.53) and (17.40,12.07) .. (18.46,11.69) .. controls (19.10,11.41) and (21.79,11.58) .. (20.79,13.08) .. controls (20.79,13.08) and (21.71,13.90) .. (21.80,13.99) .. controls (21.97,14.75) and (21.59,14.91) .. (21.47,15.12) .. controls (21.44,15.60) and (21.04,15.79) .. (20.55,15.44) .. controls (19.45,15.64) and (18.36,15.55) .. (17.83,15.59) .. controls (16.65,15.76) and (15.67,16.38) .. (15.67,16.38) .. controls (15.40,17.19) and (14.82,17.01) .. (14.09,17.32) .. controls (14.70,18.69) and (14.76,19.32) .. (15.50,21.32) .. controls (15.76,22.37) and (16.54,24.00) .. (16.15,24.00) -- cycle(7.83,16.74) .. controls (6.83,15.71) and (5.72,15.70) .. (4.05,15.42) .. controls (2.75,15.19) and (0.39,12.97) .. (0.02,10.68) .. controls (-0.02,10.07) and (-0.06,8.50) .. (0.45,7.18) .. controls (0.94,6.05) and (1.27,5.45) .. (2.29,4.85) .. controls (1.41,8.02) and (7.59,10.18) .. (8.55,13.80) -- (8.55,13.80) .. controls (7.73,15.00) and (7.80,15.64) .. (7.83,16.74) -- cycle;
      \\end{tikzpicture}
    \\end{lrbox}

    \\makeatletter
    \\renewcommand\\maketitle{
      \\thispagestyle{empty}
      \\hyphenpenalty=10000 % hyphens look bad in titles
      \\renewcommand{\\baselinestretch}{1.1}
      \\let\\oldtoday\\today
      \\renewcommand{\\today}{\\LARGE\\number\\year\\\\\\large%
        \\ifcase \\month \\or Jan\\or Feb\\or Mar\\or Apr\\or May \\or Jun\\or Jul\\or Aug\\or Sep\\or Oct\\or Nov\\or Dec\\fi
        ~\\number\\day}
      \\begin{tikzpicture}[remember picture,overlay]
        %% Background Polygons %%
        \\foreach \\i in {2.5,...,22} % bottom left
        {\\node[rounded corners,black!3.5,draw,regular polygon,regular polygon sides=6, minimum size=\\i cm,ultra thick] at ($(current page.west)+(2.5,-4.2)$) {} ;}
        \\foreach \\i in {0.5,...,22} % top left
        {\\node[rounded corners,black!5,draw,regular polygon,regular polygon sides=6, minimum size=\\i cm,ultra thick] at ($(current page.north west)+(2.5,2)$) {} ;}
        \\node[rounded corners,fill=black!4,regular polygon,regular polygon sides=6, minimum size=5.5 cm,ultra thick] at ($(current page.north west)+(2.5,2)$) {};
        \\foreach \\i in {0.5,...,24} % top right
        {\\node[rounded corners,black!2,draw,regular polygon,regular polygon sides=6, minimum size=\\i cm,ultra thick] at ($(current page.north east)+(0,-8.5)$) {} ;}
        \\node[fill=black!3,rounded corners,regular polygon,regular polygon sides=6, minimum size=2.5 cm,ultra thick] at ($(current page.north east)+(0,-8.5)$) {};
        \\foreach \\i in {21,...,3} % bottom right
        {\\node[black!3,rounded corners,draw,regular polygon,regular polygon sides=6, minimum size=\\i cm,ultra thick] at ($(current page.south east)+(-1.5,0.75)$) {} ;}
        \\node[fill=black!3,rounded corners,regular polygon,regular polygon sides=6, minimum size=2 cm,ultra thick] at ($(current page.south east)+(-1.5,0.75)$) {};
        \\node[align=center, scale=1.4] at ($(current page.south east)+(-1.5,0.75)$) {\\usebox\\orgicon};
        %% Text %%
        \\node[left, align=right, black, text width=0.8\\paperwidth, minimum height=3cm, rounded corners,font=\\Huge\\bfseries] at ($(current page.north east)+(-2,-8.5)$)
        {\\@title};
        \\node[left, align=right, black, text width=0.8\\paperwidth, minimum height=2cm, rounded corners, font=\\Large] at ($(current page.north east)+(-2,-11.8)$)
        {\\scshape \\@author};
        \\renewcommand{\\baselinestretch}{0.75}
        \\node[align=center,rounded corners,fill=black!3,text=black,regular polygon,regular polygon sides=6, minimum size=2.5 cm,inner sep=0, font=\\Large\\bfseries ] at ($(current page.west)+(2.5,-4.2)$)
        {\\@date};
      \\end{tikzpicture}
      \\let\\today\\oldtoday
      \\clearpage}
    \\makeatother
    ```

    现在我们有了一个不错的封面页，我们只需要不时使用它。将此添加到 `#+options` 感觉最合适。让封面选项接受 auto 作为值，然后根据字数决定是否应使用封面。然后我们只想插入一个 LaTeX 片段在封面中来调整标题格式。

    ```emacs-lisp
    (defvar org-latex-cover-page 'auto
      "When t, use a cover page by default.
    When auto, use a cover page when the document's wordcount exceeds
    `org-latex-cover-page-wordcount-threshold'.

    Set with #+option: coverpage:{yes,auto,no} in org buffers.")
    (defvar org-latex-cover-page-wordcount-threshold 5000
      "Document word count at which a cover page will be used automatically.
    This condition is applied when cover page option is set to auto.")
    (defvar org-latex-subtitle-coverpage-format "\\\\\\bigskip\n\\LARGE\\mdseries\\itshape\\color{black!80} %s\\par"
      "Variant of `org-latex-subtitle-format' to use with the cover page.")
    (defvar org-latex-cover-page-maketitle "
    <<latex-cover-page>>
    "
      "LaTeX snippet for the preamble that sets \\maketitle to produce a cover page.")

    (eval '(cl-pushnew '(:latex-cover-page nil "coverpage" org-latex-cover-page)
    		   (org-export-backend-options (org-export-get-backend 'latex))))

    (defun org-latex-cover-page-p ()
      "Whether a cover page should be used when exporting this Org file."
      (pcase (car
    	  (delq nil
    		(mapcar
    		 (lambda (opt-line)
    		   (plist-get (org-export--parse-option-keyword opt-line 'latex) :latex-cover-page))
    		 (cdar (org-collect-keywords '("OPTIONS"))))))
        ('t t)
        ('auto (when (> (count-words (point-min) (point-max)) org-latex-cover-page-wordcount-threshold) t))
        (_ nil)))

    (defadvice! org-latex-set-coverpage-subtitle-format-a (contents info)
      "Set the subtitle format when a cover page is being used."
      :before #'org-latex-template
      (when (org-latex-cover-page-p)
        (setf info (plist-put info :latex-subtitle-format org-latex-subtitle-coverpage-format))))

    (add-to-list 'org-latex-feature-implementations '(cover-page :snippet org-latex-cover-page-maketitle :order 9) t)
    (add-to-list 'org-latex-conditional-features '((org-latex-cover-page-p) . cover-page) t)
    ```

    或许之后可以再加一些不同的封面。

<!--list-separator-->

-  代码

    来个序言区模板，主要采用 `tcblisting` 生成主题 box

    <a id="code-snippet--latex-tcblisting-code-preamble"></a>
    ```LaTeX
    \\usepackage{accsupp}
    \\usepackage[most,breakable,minted]{tcolorbox}
    \\definecolor{solarized-light-background}{HTML}{FDF6E3}
    \\definecolor{solarized-light-frame}{HTML}{EEE8D6}
    \\definecolor{solarized-light-title}{HTML}{979797}
    \\definecolor{solarized-light-lineno}{HTML}{237D99}
    \\newcommand{\\SetFancyVerbLine}{
      \\renewcommand{\\theFancyVerbLine}{
        \\protect\\BeginAccSupp{ActualText={}}\\sffamily\\textcolor{solarized-light-lineno}{\\scriptsize\\oldstylenums{\\arabic{FancyVerbLine}}}\\protect\\EndAccSupp{}
      }
    }
    \\newenvironment{orglisting}[2][]{
      \\SetFancyVerbLine
      \\tcblisting{
        frame empty,
        enhanced jigsaw,
        drop fuzzy shadow,
        breakable,
        center,
        width=\\linewidth,
        bottom=1mm, top=1mm, left=6mm,
        fonttitle=\\bfseries,
        listing only,
        listing engine=minted,
        colback=solarized-light-background,
        colframe=solarized-light-frame,
        coltitle=solarized-light-title,
        minted style=solarized-light,
        minted language=#2,
        minted options={
          breaklines=t,
          breakbefore=.,
          samepage=nil,
          encoding=utf8,
          fontsize=\\small,
          mathescape=t,
          escapeinside=,
          autogobble=t,
          breakautoindent=t,
          tabsize=4,
          numbersep=2mm,
          % numbers=left,
          numberblanklines=t,
          firstline=1,
          firstnumber=1,
          % lastline=,
          showspaces=nil,
          space=\\textvisiblespace, %% only showspaces=true
          obeytabs=nil,
          showtabs=nil,
          #1
        },
      }
    }{
      \\endtcblisting
    }
    ```

    设置一下自己的代码渲染方式

    ```emacs-lisp
    (setq! org-latex-listings 'tcblisting
           org-latex-tcblisting-code-preamble "
    <<latex-tcblisting-code-preamble>>
    ")
    ```

    修改一下导出代码块的行为

    ```emacs-lisp
    (defadvice! org-latex-src-block-tcblisting (orig-fn src-block contents info)
      "Like `org-latex-src-block', but supporting an tcblisting backend"
      :around #'org-latex-src-block
      (if (eq 'tcblisting (plist-get info :latex-listings))
          (ginshio/org-latex-scr-block src-block contents info)
        (funcall orig-fn src-block contents info)))

    (defun ginshio/org-latex-scr-block (src-block contents info)
      (let* ((lang (org-element-property :language src-block))
    	 (attributes (org-export-read-attribute :attr_latex src-block))
    	 (float (plist-get attributes :float))
    	 (num-start (org-export-get-loc src-block info))
    	 (retain-labels (org-element-property :retain-labels src-block))
    	 (caption (org-element-property :caption src-block))
    	 (caption-above-p (org-latex--caption-above-p src-block info))
    	 (caption-str (org-latex--caption/label-string src-block info))
    	 (placement (or (org-unbracket-string "[" "]" (plist-get attributes :placement))
    			(plist-get info :latex-default-figure-position)))
    	 (float-env
    	  (cond
    	   ((string= "multicolumn" float)
    	    (format "\\begin{listing*}[%s]\n%s%%s\n%s\\end{listing*}"
    		    placement
    		    (if caption-above-p caption-str "")
    		    (if caption-above-p "" caption-str)))
    	   (caption
    	    (format "\\begin{listing}[%s]\n%s%%s\n%s\\end{listing}"
    		    placement
    		    (if caption-above-p caption-str "")
    		    (if caption-above-p "" caption-str)))
    	   ((string= "t" float)
    	    (concat (format "\\begin{listing}[%s]\n" placement)
    		    "%s\n\\end{listing}"))
    	   (t "%s")))
    	 (options (plist-get info :latex-minted-options))
    	 (body
    	  (format
    	   "\\begin{orglisting}[%s]{%s}\n%s\\end{orglisting}"
    	   ;; Options.
    	   (concat
    	    (org-latex--make-option-string
    	     (if (or (not num-start) (assoc "linenos" options))
    		 options
    	       (append
    		`(("linenos")
    		  ("firstnumber" ,(number-to-string (1+ num-start))))
    		options)))
    	    (let ((local-options (plist-get attributes :options)))
    	      (and local-options (concat "," local-options))))
    	   ;; Language.
    	   (or (cadr (assq (intern lang)
    			   (plist-get info :latex-minted-langs)))
    	       (downcase lang))
    	   ;; Source code.
    	   (let* ((code-info (org-export-unravel-code src-block))
    		  (max-width
    		   (apply 'max
    			  (mapcar 'length
    				  (org-split-string (car code-info)
    						    "\n")))))
    	     (org-export-format-code
    	      (car code-info)
    	      (lambda (loc _num ref)
    		(concat
    		 loc
    		 (when ref
    		   ;; Ensure references are flushed to the right,
    		   ;; separated with 6 spaces from the widest line
    		   ;; of code.
    		   (concat (make-string (+ (- max-width (length loc)) 6)
    					?\s)
    			   (format "(%s)" ref)))))
    	      nil (and retain-labels (cdr code-info)))))))
        ;; Return value.
        (format float-env body)))
    ```

    内联代码块的行为相对更好修改

    ```emacs-lisp
    (defadvice! org-latex-inline-src-block-tcblisting (orig-fn inline-src-block contents info)
      "Like `org-latex-inline-src-block', but supporting an tcblisting backend"
      :around #'org-latex-inline-src-block
      (if (eq 'tcblisting (plist-get info :latex-listings))
          ;; (funcall orig-fn inline-src-block contents (plist-put info :latex-listings 'minted))
          (ginshio/org-latex-inline-src-block inline-src-block contents info)
        (funcall orig-fn inline-src-block contents info)))

    (defun ginshio/org-latex-inline-src-block (inline-src-block _contents info)
      (let* ((code (org-element-property :value inline-src-block))
    	 (separator (org-latex--find-verb-separator code))
    	 (org-lang (org-element-property :language inline-src-block))
    	 (mint-lang (or (cadr (assq (intern org-lang)
    				    (plist-get info :latex-minted-langs)))
    			(downcase org-lang)))
    	 (options (org-latex--make-option-string
    		   (plist-get info :latex-minted-options))))
        (format "\\mintinline%s{%s}{%s}"
    	    (if (string= options "") "" (format "[%s]" options))
    	    mint-lang code)))
    ```

    最终将其添加到智能序言中

    ```emacs-lisp
    (add-to-list 'org-latex-conditional-features '("^[ \t]*#\\+begin_src\\|^[ \t]*#\\+BEGIN_SRC\\|src_[A-Za-z]" . tcblisting-code-preamble) t)
    (add-to-list 'org-latex-feature-implementations '(tcblisting-code-preamble :snippet org-latex-tcblisting-code-preamble :order 99) t)
    ```

    有一个问题，就是代码中的所有引号有问题。

<!--list-separator-->

-  使 verbatim 与 code 不同

    区分 `verbatim` 和 `verb`

    ```emacs-lisp
    (setq! org-latex-text-markup-alist
           '((bold . "\\textbf{%s}")
    	 (code . protectedtexttt)
    	 (italic . "\\emph{%s}")
    	 (strike-through . "\\sout{%s}")
    	 (underline . "\\uline{%s}")
    	 (verbatim . verb)))
    ```


#### 幻灯片导出 {#幻灯片导出}

如果能使用不同的主题就很好了

```emacs-lisp
(setq! org-beamer-theme "[progressbar=foot]metropolis")
```

```emacs-lisp
(defun org-beamer-p (info)
  (eq 'beamer (and (plist-get info :back-end) (org-export-backend-name (plist-get info :back-end)))))

(add-to-list 'org-latex-conditional-features '(org-beamer-p . beamer) t)
(add-to-list 'org-latex-feature-implementations '(beamer :requires .missing-koma :prevents (italic-quotes condensed-lists)) t)
(add-to-list 'org-latex-feature-implementations '(.missing-koma :snippet "\\usepackage{scrextend}" :order 2) t)
```

而且我认为将演示文稿分成几个部分是很自然的，例如简介、概述…… 所以让我们将标题级别设置为 `2`

```emacs-lisp
(setq! org-beamer-frame-level 2)
```


#### ASCII 导出 {#ascii-导出}

ASCII 导出通常不错，我认为从改进中收益的主要方面是 LaTeX 片段的外观，我们可以使用一个很好的程序来创建更好的 unicode 表示。它叫做 `latex2text` ，它是
`pylatexenc` 的一部分。因此将使用 `pip` 安装它。

```shell
sudo python3 -m pip install pylatexenc
```

安装后，我们可以覆盖 `(org-ascii-latex-fragment)` 和
`(org-ascii-latex-environment)` 函数，它们非常方便
--- 只需提取内容并缩进。我们只会在设置 `utf-8` 时做一些不同的事情。

```emacs-lisp
(after! ox-ascii
  (setq! org-ascii-charset 'utf-8)
  (defvar org-ascii-convert-latex t
    "Use latex2text to convert LaTeX elements to unicode.")

  (defadvice! org-ascii-latex-environment-unicode-a (latex-environment _contents info)
    "Transcode a LATEX-ENVIRONMENT element from Org to ASCII, converting to unicode.
CONTENTS is nil.  INFO is a plist holding contextual
information."
    :override #'org-ascii-latex-environment
    (when (plist-get info :with-latex)
      (org-ascii--justify-element
       (org-remove-indentation
	(let* ((latex (org-element-property :value latex-environment))
	       (unicode (and (eq (plist-get info :ascii-charset) 'utf-8)
			     org-ascii-convert-latex
			     (doom-call-process "latex2text" "-q" "--code" latex))))
	  (if (= (car unicode) 0) ; utf-8 set, and sucessfully ran latex2text
	      (cdr unicode) latex)))
       latex-environment info)))

  (defadvice! org-ascii-latex-fragment-unicode-a (latex-fragment _contents info)
    "Transcode a LATEX-FRAGMENT object from Org to ASCII, converting to unicode.
CONTENTS is nil.  INFO is a plist holding contextual
information."
    :override #'org-ascii-latex-fragment
    (when (plist-get info :with-latex)
      (let* ((latex (org-element-property :value latex-fragment))
	     (unicode (and (eq (plist-get info :ascii-charset) 'utf-8)
			   org-ascii-convert-latex
			     (doom-call-process "latex2text" "-q" "--code" latex))))
	(if (and unicode (= (car unicode) 0)) ; utf-8 set, and sucessfully ran latex2text
	    (cdr unicode) latex)))))
```


#### Markdown 导出 {#markdown-导出}

由于 _[Markdown 实现的多样性](https://github.com/commonmark/commonmark-spec/wiki/markdown-flavors)_ ，实际上并没有标准的表格规范……或标准的任何东西。因为 `org-md` 表现的与众不同，它只是对所有这些非标准化元素 (很多) 使用 HTML。

似乎大多数 Markdown 解析器都专注于 TeX 样式的语法 (`$` 和 `$$`)。不幸的是，为了获得良好的渲染，最好兼容它们。 `ox-md` 没有为此提供转码器，因此必须自己创建并将它们推送到 `md` 转码器列表中。

```emacs-lisp
(after! ox-md
  (defun org-md-latex-fragment (latex-fragment _contents info)
    "Transcode a LATEX-FRAGMENT object from Org to Markdown."
    (let ((frag (org-element-property :value latex-fragment)))
      (cond
       ((string-match-p "^\\\\(" frag)
	(concat "$" (substring frag 2 -2) "$"))
       ((string-match-p "^\\\\\\[" frag)
	(concat "$$" (substring frag 2 -2) "$$"))
       (t (message "unrecognised fragment: %s" frag)
	  frag))))

  (defun org-md-latex-environment (latex-environment contents info)
    "Transcode a LATEX-ENVIRONMENT object from Org to Markdown."
    (concat "$$\n"
	    (org-html-latex-environment latex-environment contents info)
	    "$$\n"))

  (defun org-utf8-entity (entity _contents _info)
    "Transcode an ENTITY object from Org to utf-8.
CONTENTS are the definition itself.  INFO is a plist holding
contextual information."
    (org-element-property :utf-8 entity))

  ;; We can't let this be immediately parsed and evaluated,
  ;; because eager macro-expansion tries to call as-of-yet
  ;; undefined functions.
  ;; NOTE in the near future this shouldn't be required
  (eval
   '(dolist (extra-transcoder
	     '((latex-fragment . org-md-latex-fragment)
	       (latex-environment . org-md-latex-environment)
	       (entity . org-utf8-entity)))
      (unless (member extra-transcoder (org-export-backend-transcoders
					(org-export-get-backend 'md)))
	(push extra-transcoder (org-export-backend-transcoders
				(org-export-get-backend 'md))))))
  (defadvice! org-md-plain-text-unicode-a (orig-fn text info)
    "Locally rebind `org-html-special-string-regexps'"
    :around #'org-md-plain-text
    (let ((org-html-special-string-regexps
	   '(("\\\\-" . "-")
	     ("---\\([^-]\\|$\\)" . "—\\1")
	     ("--\\([^-]\\|$\\)" . "–\\1")
	     ("\\.\\.\\." . "…")
	     ("->" . "→")
	     ("<-" . "←"))))
      (funcall orig-fn text (plist-put info :with-smart-quotes nil)))))
```

当我想在某处粘贴导出的 Markdown 时，最好使用 unicode 字符 `---` 而不是
`&#x2014;` 。为此，只需要在本地重新绑定提供的 alist。而
`org-md-plain-text-unicode-a` 就是解决这个问题的。


#### Hugo {#hugo}

我用 hugo 的主要原因是就是可以用 Org Mode 来写作，之后交给 [ox-hugo](https://ox-hugo.scripter.co/) 就好。需要尽量减少 hugo 所带来的额外语法，这样可以让我们仅用 Org 编辑，发布不同的文件。

我使用的 Hugo 主题是 [DoIt](https://github.com/HEIGE-PCloud/DoIt)，`authors` 字段接受数组类型，而 `ox-hugo` 默认导出
`author` 字段为数组类型，对于该问题可以参考该 [issue](https://github.com/kaushalmodi/ox-hugo/issues/608#issuecomment-1086950058)

```text
#+hugo_front_matter_key_replace: author>authors
```


### LaTeX {#LaTeX}

{{< figure src="https://imgs.xkcd.com/comics/file_extensions.png" >}}

```emacs-lisp
(setq! LaTeX-biblatex-use-Biber t)
(custom-set-variables '(LaTeX-section-label '(("part" . "part:")
					      ("chapter" . "chap:")
					      ("section" . "sec:")
					      ("subsection" . "subsec:")
					      ("subsubsection" . "subsubsec:")))
		      '(TeX-auto-local "auto")
		      '(TeX-command-extra-options "-shell-escape"))
(after! latex
  <<tex-conf>>
  )
```


#### 编译 {#编译}

```emacs-lisp
(setq! TeX-save-query nil
       TeX-show-compilation t
       LaTeX-clean-intermediate-suffixes (append TeX-clean-default-intermediate-suffixes
						 '("\\.acn" "\\.acr" "\\.alg" "\\.glg"
						   "\\.ist" "\\.listing" "\\.fdb_latexmk")))
(add-to-list 'TeX-command-list '("LatexMk (XeLaTeX)" "latexmk -pdf -xelatex -8bit %S%(mode) %(file-line-error) %(extraopts) %t" TeX-run-latexmk nil
				 (plain-tex-mode latex-mode doctex-mode)
				 :help "Run LatexMk (XeLaTeX)"))
```


#### 引用 {#引用}

如果 `bib` 中有你不想要的某些字段，可以通过一下方法去除 (导言区)

```latex
\AtEveryBibitem{
  \clearfield{note}
  \ifentrytype{book}{
    \clearfield{url}
    \clearfield{isbn}
  }{}
  \ifentrytype{article}{
    \clearfield{url}
  }{}
  \ifentrytype{thesis}{
    \clearfield{url}
  }{}
}
```


#### 视觉 {#视觉}

增强一点点视觉效果

```emacs-lisp
(setcar (assoc "⋆" LaTeX-fold-math-spec-list) "★")

(setq! TeX-fold-math-spec-list
       `(;; missing/better symbols
	 ("≤" ("le"))
	 ("≥" ("ge"))
	 ("≠" ("ne"))
	 ;; convenience shorts -- these don't work nicely ATM
	 ;; ("‹" ("left"))
	 ;; ("›" ("right"))
	 ;; private macros
	 ("ℝ" ("RR"))
	 ("ℕ" ("NN"))
	 ("ℤ" ("ZZ"))
	 ("ℚ" ("QQ"))
	 ("ℂ" ("CC"))
	 ("ℙ" ("PP"))
	 ("ℍ" ("HH"))
	 ("𝔼" ("EE"))
	 ("𝑑" ("dd"))
	 ;; known commands
	 ("" ("phantom"))
	 (,(lambda (num den) (if (and (TeX-string-single-token-p num) (TeX-string-single-token-p den))
				 (concat num "／" den)
			       (concat "❪" num "／" den "❫"))) ("frac"))
	 (,(lambda (arg) (concat "√" (TeX-fold-parenthesize-as-necessary arg))) ("sqrt"))
	 (,(lambda (arg) (concat "⭡" (TeX-fold-parenthesize-as-necessary arg))) ("vec"))
	 ("‘{1}’" ("text"))
	 ;; private commands
	 ("|{1}|" ("abs"))
	 ("‖{1}‖" ("norm"))
	 ("⌊{1}⌋" ("floor"))
	 ("⌈{1}⌉" ("ceil"))
	 ("⌊{1}⌉" ("round"))
	 ("𝑑{1}/𝑑{2}" ("dv"))
	 ("∂{1}/∂{2}" ("pdv"))
	 ;; fancification
	 ("{1}" ("mathrm"))
	 (,(lambda (word) (string-offset-roman-chars 119743 word)) ("mathbf"))
	 (,(lambda (word) (string-offset-roman-chars 119951 word)) ("mathcal"))
	 (,(lambda (word) (string-offset-roman-chars 120003 word)) ("mathfrak"))
	 (,(lambda (word) (string-offset-roman-chars 120055 word)) ("mathbb"))
	 (,(lambda (word) (string-offset-roman-chars 120159 word)) ("mathsf"))
	 (,(lambda (word) (string-offset-roman-chars 120367 word)) ("mathtt"))
	 )
       TeX-fold-macro-spec-list
       '(;; as the defaults
	 ("[f]" ("footnote" "marginpar"))
	 ("[c]" ("cite"))
	 ("[l]" ("label"))
	 ("[r]" ("ref" "pageref" "eqref"))
	 ("[i]" ("index" "glossary"))
	 ("..." ("dots"))
	 ("{1}" ("emph" "textit" "textsl" "textmd" "textrm" "textsf" "texttt"
		 "textbf" "textsc" "textup"))
	 ;; tweaked defaults
	 ("©" ("copyright"))
	 ("®" ("textregistered"))
	 ("™"  ("texttrademark"))
	 ("[1]:||►" ("item"))
	 ("❡❡ {1}" ("part" "part*"))
	 ("❡ {1}" ("chapter" "chapter*"))
	 ("§ {1}" ("section" "section*"))
	 ("§§ {1}" ("subsection" "subsection*"))
	 ("§§§ {1}" ("subsubsection" "subsubsection*"))
	 ("¶ {1}" ("paragraph" "paragraph*"))
	 ("¶¶ {1}" ("subparagraph" "subparagraph*"))
	 ;; extra
	 ("⬖ {1}" ("begin"))
	 ("⬗ {1}" ("end"))
	 ))

(defun string-offset-roman-chars (offset word)
  "Shift the codepoint of each character in WORD by OFFSET with an extra -6 shift if the letter is lowercase"
  (apply 'string
	 (mapcar (lambda (c)
		   (string-offset-apply-roman-char-exceptions
		    (+ (if (>= c 97) (- c 6) c) offset)))
		 word)))

(defvar string-offset-roman-char-exceptions
  '(;; lowercase serif
    (119892 .  8462) ; ℎ
    ;; lowercase caligraphic
    (119994 . 8495) ; ℯ
    (119996 . 8458) ; ℊ
    (120004 . 8500) ; ℴ
    ;; caligraphic
    (119965 . 8492) ; ℬ
    (119968 . 8496) ; ℰ
    (119969 . 8497) ; ℱ
    (119971 . 8459) ; ℋ
    (119972 . 8464) ; ℐ
    (119975 . 8466) ; ℒ
    (119976 . 8499) ; ℳ
    (119981 . 8475) ; ℛ
    ;; fraktur
    (120070 . 8493) ; ℭ
    (120075 . 8460) ; ℌ
    (120076 . 8465) ; ℑ
    (120085 . 8476) ; ℜ
    (120092 . 8488) ; ℨ
    ;; blackboard
    (120122 . 8450) ; ℂ
    (120127 . 8461) ; ℍ
    (120133 . 8469) ; ℕ
    (120135 . 8473) ; ℙ
    (120136 . 8474) ; ℚ
    (120137 . 8477) ; ℝ
    (120145 . 8484) ; ℤ
    )
  "An alist of deceptive codepoints, and then where the glyph actually resides.")

(defun string-offset-apply-roman-char-exceptions (char)
  "Sometimes the codepoint doesn't contain the char you expect.
Such special cases should be remapped to another value, as given in `string-offset-roman-char-exceptions'."
  (if (assoc char string-offset-roman-char-exceptions)
      (cdr (assoc char string-offset-roman-char-exceptions))
    char))

(defun TeX-fold-parenthesize-as-necessary (tokens &optional suppress-left suppress-right)
  "Add ❪ ❫ parenthesis as if multiple LaTeX tokens appear to be present"
  (if (TeX-string-single-token-p tokens) tokens
    (concat (if suppress-left "" "❪")
	    tokens
	    (if suppress-right "" "❫"))))

(defun TeX-string-single-token-p (teststring)
  "Return t if TESTSTRING appears to be a single token, nil otherwise"
  (if (string-match-p "^\\\\?\\w+$" teststring) t nil))
```

当然数学界定符不需要强调

```emacs-lisp
;; Making \( \) less visible
(defface unimportant-latex-face
  '((t :inherit font-lock-comment-face :weight extra-light))
  "Face used to make \\(\\), \\[\\] less visible."
  :group 'LaTeX-math)

(font-lock-add-keywords
 'latex-mode
 `(("\\\\[]()[]" 0 'unimportant-latex-face prepend))
 'end)

;; (font-lock-add-keywords
;;  'latex-mode
;;  '(("\\\\[[:word:]]+" 0 'font-lock-keyword-face prepend))
;;  'end)
```


#### Fixes {#fixes}

Emacs28

```emacs-lisp
(when EMACS28+
  (add-hook 'latex-mode-hook #'TeX-latex-mode))
```


### Markdown {#markdown}

Doom 默认的 Markdown 是 `GFM` (GitHub Flavored Markdown)，不过有了 `Emacs` 和
`Org Mode` 谁还用 `Markdown` 。但是 `toc-org-mode` 依然可以使用。

可以采用如下方式支持 Markdown。

```text
# TOC         <!-- :TOC: -->
```


### C++ {#c-plus-plus}

tcc 也是 C++

```emacs-lisp
(add-to-list 'auto-mode-alist '("\\.tcc\\'" . c++-mode))
```
