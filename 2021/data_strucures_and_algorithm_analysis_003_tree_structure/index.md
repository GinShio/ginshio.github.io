# 树结构


> Not all roots are buried down in the ground, some are at the top of a tree.
>
> --- Jinvirle


## 树 (tree) {#树--tree}

Tree 是一些结点的集合，这个集合可以是空集；若不是空集，则 Tree 是由称为 **根** 的结点 r 以及零或多个非空的子树 \\(T\_{1}, T\_{2}, \cdots, T\_{N}\\) 组成，这些子树的根都与 r 有一条有向边 (edge) 连接。这些子树的根被称为根 r 的孩子 (child)，而 r 是这些 child 的父亲 (parent)。


### 树的属性 {#树的属性}

根据给出的树的递归定义，可以发现一个树是由 \\(N\\) 个 node 和 \\(N - 1\\) 条 edge 的集合。而除 root 外的所有 node 都有一个由其 parent 指向它的 edge。在树中有一些特殊的属性是需要注意的，这里先给出相关概念与示例，如果不是很理解，可以通过结合示例来理解这些概念。

结点的度 (degree)
: 一个节点含有的子树的个数称为该节点的度

树的度 (degree of tree)
: 一棵树中最大的 node degree 称为树的度

叶结点 (leaf)
: 或称​**终端结点**​，如果结点满足 \\(degree = 0\\) 则该结点为叶结点

分支结点 (branch node)
: 或称​**内部结点** (internal node)、​**非终端结点**​，度不为 0 的结点

层次 (level)
: 从 root 开始，root 所在的层为第 1 层，root 的 child 为第二层，以此类推

关系
: 树就像一本族谱，从 root 开始结点直接有一定的亲缘关系
    -   **兄弟 (sibling):** 具有相同父节点的节点互为兄弟节点
    -   **叔父 (uncle):** 父结点的兄弟结点为该结点的叔父结点
    -   **堂兄弟:** 父结点在同一层的结点互为堂兄弟

路径 (path)
: 结点 \\(n\_{1}, n\_{2}, \cdots, n\_{k}\\) 的一个序列，使得对于 \\(1 \leq i < k\\) 满足 \\(n\_{i}\\) 是 \\(n\_{i + 1}\\) 的 parent，则这个序列被称为从 \\(n\_{1}\\) 到结点 \\(n\_{k}\\) 的 path。其路径长度 (length) 为路径上的 edge 的数量，即 \\(k - 1\\) 。特别地，每个结点到自己的 path lenth 为 `0`

深度 (depth)
: 对于结点 \\(n\_{i}\\) ，从 root 到 \\(n\_{i}\\) 的唯一路径的长度 (\\(Depth\_{root} = 0\\))

高度 (height)
: 对于结点 \\(n\_{i}\\) ，从 \\(n\_{i}\\) 到 leaf 的最长路径长度 (\\(Height\_{leaf} = 0\\))

树的高度
: 或称树的深度，其总是等于根的高度，或最深的结点的深度，可以认为一棵空树的高度为 \\(-1\\)

祖先 (ancestor)
: 对于结点 \\(n\_{i}\\) 与 \\(n\_{j}\\) 存在一条 \\(n\_{i}\\) 到 \\(n\_{j}\\) 的路径，那么称 \\(n\_{i}\\) 是 \\(n\_{j}\\) 的祖先 (ancestor)，而 \\(n\_{j}\\) 是 \\(n\_{i}\\) 的 **后裔** (descendant)

距离 (distance)
: 对于结点 \\(n\_{i}\\) 与 \\(n\_{j}\\) ，从最近的公共祖先结点 \\(n\_{k}\\) 分别到它们的路径长度之和被称为距离 (distance)。特别地，如果 \\(n\_{i} = n\_{k}\\) ，则 \\(n\_{i}\\) 与 \\(n\_{j}\\) 的距离为 \\(n\_{i}\\) 到 \\(n\_{j}\\) 的路径的长度

{{< figure src="/images/algo-tree-example.svg" width="80%" >}}

{{< admonition type="info" >}}
严蔚敏老师的数据结构中，或者往常的实现中，根的高度为 1，而叶的深度也为 1，树的高度一般指其最大的层次，因此认为空树的高度为 0。
{{< /admonition >}}


### 树的实现 {#树的实现}

实现树的一种方法是在每一个结点上，除数据外还需要一些链域来指向该结点的每个子结点，然而由于每个结点的子结点数量是不确定的，我们不能直接建立到各个子结点的直接链接。如果申请一定大小的空间以存放子结点，则可能会造成空间的浪费，或不足。因此我们链表的形式存储子结点，而父结点中只存储第一个子结点的指针，如果该链域为空则意味着该结点是叶结点 (\\(degree = 0\\))。每个结点中存在一个指向其下一个兄弟的指针，为遍历父结点的所有孩子提供了方法，当该结点 \\(next\\\_sibling = nullptr\\) 时意味着这是父结点的最后一个子结点。

```cpp
struct TreeBaseNode {
  TreeBaseNode* first_child;
  TreeBaseNode* next_sibling;
};
template <class Element>
struct TreeNode {
  Element data;
};
```

如果我们用这个结构实现上述图示的树，可以画一下其表示。

{{< figure src="/images/algo-tree-of-sibling-implement.svg" width="72%" >}}

可以发现，除非该结点是 leaf，否则我们很难判断该结点的 degree。且在计算深度与距离时，要十分小心在兄弟间步进，因为兄弟间步进并不会增加其与 parent 的距离。


### 树的遍历与应用 {#树的遍历与应用}

观察你系统中的文件系统，回到文件系统的顶层 `/` (root)，并浏览一些目录你会发现，
~~嗯，你让我发现什么，~~ 整个目录结构与 tree 是类似的，我们也常常将其称为目录树。

```text
/
├── etc
│   ├── X11
│   │   ├── Xreset.d
│   │   │   └── README
│   │   ├── Xresources
│   │   │   ├── x11-common
│   │   │   └── xpdf
│   │   └── Xsession.d
│   │       ├── 90x11-common_ssh-agent
│   │       ├── 95dbus_update-activation-env
│   │       └── 99x11-common_start
│   ├── emacs
│   │    └── site-start.d
│   │        ├── 50asymptote.el
│   │        ├── 50autoconf.el
│   │        ├── 50dictionaries-common.el
│   │        ├── 50erlang-mode.el
│   │        ├── 50latex-cjk-common.el
│   │        ├── 50latex-cjk-thai.el
│   │        ├── 50latexmk.el
│   │        └── 50texlive-lang-english.el
│   └── fish
│      ├── completions
│      ├── conf.d
│      ├── functions
│      └── config.fish
├── home
│   └── ginshio
├── mnt
├── run
├── tmp
├── usr
│   ├── bin
│   │   ├── X11 -> .
│   │   ├── 7z
│   │   ├── 7za
│   │   ├── 7zr
│   │   ├── cc -> /etc/alternatives/cc
│   │   ├── ccache
│   │   ├── clang -> ../lib/llvm-14/bin/clang
│   │   ├── clang++ -> ../lib/llvm-14/bin/clang++
│   │   ├── emacs -> /etc/alternatives/emacs
│   │   ├── g++ -> g++-11
│   │   ├── gcc -> gcc-11
│   │   ├── zstd
│   │   ├── zstdcat -> zstd
│   │   └── zstdmt -> zstd
│   ├── include
│   │   ├── SDL2
│   │   │   ├── SDL.h
│   │   │   ├── SDL_assert.h
│   │   │   ├── SDL_atomic.h
│   │   │   └── SDL_audio.h
│   │   └── X11
│   │       ├── ICE
│   │       ├── SM
│   │       ├── Xaw
│   │       ├── Xcursor
│   │       ├── Xmu
│   │       ├── Xtrans
│   │       ├── bitmaps
│   │       └── dri
│   └── lib
│       ├── X11
│       ├── emacs
│       │   └── 28.1
│       └── x86_64-linux-gnu
│           ├── libQt5Gui.so.5 -> libQt5Gui.so.5.15.3
│           ├── libQt5Gui.so.5.15 -> libQt5Gui.so.5.15.3
│           ├── libQt5Gui.so.5.15.3
│           ├── libQt5Help.so.5 -> libQt5Help.so.5.15.3
│           ├── libQt5Help.so.5.15 -> libQt5Help.so.5.15.3
│           ├── libQt5Help.so.5.15.3
│           ├── liblzma.a
│           ├── liblzma.so -> /lib/x86_64-linux-gnu/liblzma.so.5.2.5
│           ├── liblzma.so.5 -> liblzma.so.5.2.5
│           └── liblzma.so.5.2.5
└── var
    ├── backups
    ├── cache
    ├── crash
    ├── lib
    ├── local
    ├── log
    ├── mail
    └── tmp
```

这颗目录树稍微有些复杂了，不过问题不大。一般文件系统中采用路径名来访问一个文件，而我们可以像遍历树一样遍历这个文件系统，将每个文件打印出来，并按照层级来缩进文件名称。


#### 深度有限遍历 (DFS) {#深度有限遍历--dfs}

给出一个代码实现：

```cpp
void filesystem::list_all(file& f, int depth = 0) const {
  print_name(f, depth);  // 打印文件的名称
  if (is_directory(f)) {
    for (file p : get_file_list(f)) { // 遍历目录中的每个文件
      list_all(p, depth + 1);
    }
  }
}
```

最终的输出结果可能是：

```text
/
 |--- mnt/
 |--- home/
       |--- GinShio/
 |--- usr
       |--- LICENSE
       |--- lib/
             |--- libQt5Core.so
             |--- X11/
                   |--- display-manager
                   |--- etc/
                   |--- displaymanagers/
                         |--- console
                         |--- lightdm
                         |--- sddm
                         |--- xdm
             |--- libstdc++.so.6
             |--- mozilla/
                   |--- kmozillahelper
       |--- bin/
             |--- latexmk
             |--- pdftk
             |--- zsh
.....
.....
```

在遍历中，每访问一个结点时，对结点的处理工作总是比其子结点的处理先进行，这种先处理根再处理子结点的策略被称为 **前序遍历** (preorder traversal)。而另一种常用的遍历方法是 **后序遍历** (postorder traversal)，即在结点的所有子结点处理完成后再对其进行处理。无论这两种遍历的哪一个，在遍历这个树时总是可以在 \\(\mathcal{O}(N)\\) 的时间复杂度里完成。对于目录的 postorder traversal 留给读者思考并实现。

现在考虑这两种算法有什么共通的特点。有没有发现它们都是在一棵子树上处理完所有结点之后再转移到另一棵子树上，这种一直向着 child 递归，直到全部递归结束时再向
sibling 递归的算法，就被称之为 **深度优先搜索** (Depth-first Search, DFS)。由于
DFS 使用递归算法，因此 DFS 总能被改写为 loop，非 tail recursion 的递归有可能需要
stack 的帮助才能改为 loop。


#### 广度优先遍历 (BFS) {#广度优先遍历--bfs}

请回看 [树的实现](https://blog.ginshio.org/2021/data_strucures_and_algorithm_analysis_003_tree_structure#%E6%A0%91%E7%9A%84%E5%AE%9E%E7%8E%B0) 一节的图，图中的树如果以一层一层遍历，当一层的所有结点都被遍历完时，再进入更深一层，从这层的第一个结点开始处理。这种遍历方式被称为 **广度优先遍历** (Breadth-first Search, BFS) 或者是层序遍历。


## 二叉树 {#二叉树}

对树加以限制，如果树的度为 2，那么就称这颗树为 **二叉树** (binary tree)。


### 二叉树的性质 {#二叉树的性质}

在一棵二叉树上，有一些重要的性质：

1.  第 i 层 (\\(i \in \mathbb{N}^{\*}\\)) 上最多有 \\(2^{i - 1}\\) 个结点
2.  层次为 \\(k (k \in \mathbb{N}^{\*})\\) 的树最多有 \\(2^{k} -1\\) 个结点
3.  如果叶结点的数量为 \\(n\_{0}\\) ， \\(degree = 2\\) 的结点的数量为 \\(n\_{2}\\) ，则 \\(n\_{0} = n\_{2} + 1\\)

如果将二叉树的每一层填满，那么这颗二叉树被称之为 **满二叉树** (full binary tree)；如果这颗二叉树除最后一层外都是满的，且最后一层要么是满的，要么是右边缺少连续的若干结点，那么称这颗二叉树为 **完全二叉树** (complete binary tree)。

{{< figure src="/images/algo-example-of-binary-tree.svg" width="95%" >}}

由于 full binary tree 与 complete binary tree 是特殊的二叉树，因此它们也有一些确定性的性质。我们假设总结点数为 \\(k\\) ，树的高度 (即树的层数) 为 \\(h\\) ，其中某一层为第 \\(i\\) 层，则有以下性质：

| 性质         | 满二叉树               | 完全二叉树                          |
|------------|--------------------|--------------------------------|
| 总结点数 \\(k\\) | \\(2^{h} - 1\\)        | \\(2^{h-1} \leq k \leq 2^{h} - 1\\) |
| 树的高度 \\(h\\) | \\(\log\_{2}{k} + 1\\) | \\(\log\_{2}{(k + 1)}\\)            |


### 二叉树的实现 {#二叉树的实现}

为实现二叉树，我们可以为其采用双向链表的结构，但不再是指向结点的 prev 和 next，而是指向该结点的 left child 和 right child。

```cpp
struct BinaryTreeBaseNode {
  BinaryTreeBaseNode* left,* right;
};
template <class Element>
struct BinaryTreeNode : BinaryTreeBaseNode {
  Element data;
};
```

在这里给出求解二叉树 root 中，node 的高度和深度

```cpp
// 求解结点 node 的高度
int node_height(BinaryTreeBaseNode* node) {
  if (node == nullptr) {
    return -1;
  }
  return max(binary_tree_height(node->left),
	     binary_tree_height(node->right)) + 1;
}
// 求解结点 node 在树 root 中的深度
int node_depth(BinaryTreeBaseNode* root, const BinaryTreeBaseNode* node) {
  if (root == nullptr) {
    return -1;
  }
  if (root == node) {
    return 0;
  }
  int left_depth = node_depth(root->left, node);
  int right_depth = node_depth(root->right, node);
  return left_depth == -1 ? (right_depth += right_depth != -1) : (left_depth + 1);
}
```

如果想要从结点向上求解某些数据时，并不容易做到，因为 child 没有指向 parent 的指针，需要遍历树找到 node 的 parent 才能操作。

```cpp
// 求解结点 node 的 parent，如果不存在返回 nullptr
BinaryTreeBaseNode* get_parent(BinaryTreeBaseNode* root, const BinaryTreeBaseNode* node) {
  if (root == nullptr || root == node) {
    return nullptr;
  }
  if (root->left == node || root->right == node) {
    return root;
  }
  auto left = get_parent(root->left, node);
  return left == nullptr ? get_parent(root->right, node) : left;
}
```

为了方便实现我们自然而然的会在链域中添加指向 `parent` 的指针。这样在求解 sibling、
uncle 时十分方便，并且求解结点的深度时不再需要将其等价为 root 到 node 的路径长。需要注意的是，root 是没有 parent 的。


### 二叉树的遍历 {#二叉树的遍历}

还记得之前提到的 postorder traversal 与 preorder traversal 吗，它们对二叉树同样适用。不过先别急，既然现在 child 的数量确定了，能不能将对结点的处理放在两个结点的处理之间完成呢？当然没问题！这种处理方式就是 **中序遍历** (inorder traversal)，当然这也是 DFS 的一种。

如果将当前结点标记为 N，左子结点标记为 L，右子结点标记为 R，那么前序遍历就可以表示为 NLR，中序遍历可以表示为 LNR，后序遍历可以表示为 LRN。


#### 二叉树的前序遍历 {#二叉树的前序遍历}

<!--list-separator-->

-  recursion

    ```cpp
    void preorder(BinaryTreeBaseNode* root) {
      if (root == nullptr) {
        return;
      }
      process(root);
      preorder(root->left);
      preorder(root->right);
    }
    ```

<!--list-separator-->

-  loop

    ```cpp
    void preorder(BinaryTreeBaseNode* root) {
      stack s;
      while (!s.empty() || root != nullptr) {
        while (root != nullptr) {
          process(root);
          s.push(root);
          root = root->left;
        }
        root = s.top();
        s.pop();
        root = root->rightl;
      }
    }
    ```


#### 二叉树的中序遍历 {#二叉树的中序遍历}

<!--list-separator-->

-  recursion

    ```cpp
    void inorder(BinaryTreeBaseNode* root) {
      if (root == nullptr) {
        return;
      }
      preorder(root->left);
      process(root);
      preorder(root->right);
    }
    ```

<!--list-separator-->

-  loop

    ```cpp
    void preorder(BinaryTreeBaseNode* root) {
      stack s;
      while (!s.empty() || root != nullptr) {
        while (root != nullptr) {
          s.push(root);
          root = root->left;
        }
        root = s.top();
        s.pop();
        process(root);
        root = root->rightl;
      }
    }
    ```


#### 二叉树的后序遍历 {#二叉树的后序遍历}

<!--list-separator-->

-  recursion

    ```cpp
    void postorder(BinaryTreeBaseNode* root) {
      if (root == nullptr) {
        return;
      }
      preorder(root->left);
      preorder(root->right);
      process(root);
    }
    ```

<!--list-separator-->

-  loop

    在后序遍历中，在左子结点处理完成后，只有结点没有右子结点或右子结点处理完之后，才能对结点进行处理。因此需要判别当前结点的 `右子结点为空` 或 `刚刚处理过的结点` 是该结点的右子结点。判断右子结点为空十分简单，但是问题是如何记录刚刚访问过的结点？

    利用一个变量指向正在处理的结点，当指向下一个待处理的结点时，其值就是该结点的上一个处理的结点，即处理前驱。

    ```cpp
    void postorder(BinaryTreeBaseNode* root) {
      stack s;
      BinaryTreeBaseNode* prev = nullptr;
      while (!s.empty() || root != nullptr) {
        while (root != nullptr) {
          s.push(root);
          root = root->left;
        }
        root = s.top();
        s.pop();
        if (root->right == nullptr || root->right == prev) {
          prev = root;
          process(root);
          root = nullptr;
        } else {
          s.push(root);
          root = root->right;
        }
      }
    }
    ```

<!--list-separator-->

-  一个异构的前序遍历

    如果你在对一个单词串进行翻转时，有一个简单可行的方法：先将单词串整体翻转，之后再逐词翻转。这样你就得到了一个对单词串的翻转！

    \\[a\ good\ example\quad\Longrightarrow\quad elpmaxe\ doog\ a\quad\Longrightarrow\quad example\ good\ a\\]

    这种异构的翻转也可以用在二叉树的 DFS 遍历上，前序遍历时遍历的结点顺序为 `NLR`
    (Node-&gt;Left-&gt;Right)，而后续遍历的结点顺序为 `LRN` ，对后续遍历的顺序进行翻转就变为了 `NRL` 。如果以 NRL 的顺序进行遍历，最后将结果翻转也可以得到一个后序遍历的序列，这本质上是一种前序遍历的异构。


#### 二叉树的层序遍历 {#二叉树的层序遍历}

DFS 天生与 stack 结合在一起，而 BFS 与 queue 结合在一起。因此对于以上三种 DFS 遍历，使用 recursion 是一种简单、高效的理解与编码，而层序遍历则更适合于 loop。

```cpp
void levelorder(BinaryTreeBaseNode* root) {
  queue q;
  q.push(root);
  while (!q.empty()) {
    for (int i = 0, cur_level_size = q.size(); i < cur_level_size; ++i) {
      root = q.front();
      q.pop();
      process(root);
      if (root->left != nullptr) {
	q.push(root->left);
      }
      if (root->right != nullptr) {
	q.push(root->right);
      }
    }
  }
}
```


#### Morris 遍历 {#morris-遍历}

在以上介绍的三种 DFS 遍历中，无论是 recursion 还是 loop 实现，都需要
\\(\mathcal{O}(N)\\) 的时间复杂度与 \\(\mathcal{O}(N)\\) 的空间复杂度。而 1979 年由
**J.H.Morris** 在他的 [论文](https://www.sciencedirect.com/science/article/abs/pii/0020019079900681) 中提出了一种遍历方式，可以利用 \\(\mathcal{O}(N)\\) 的时间复杂度与 \\(\mathcal{O}(1)\\) 的空间复杂度完成遍历。其核心思想是利用二叉树中的空闲指针，以实现空间复杂度的降低。

以 postorder 为例说明其算法的具体思路：

1.  如果当前结点的左子树为空，则遍历右子树
2.  如果当前结点的左子树不为空，在当前结点的左子树中找到当前结点在中序遍历中的前驱结点
    1.  如果前驱的右子结点为空，则将前驱结点的右子结点设置为当前结点，当前结点更新为其左子结点
    2.  如果前驱的右子结点为当前结点，则将其重新置空。倒序处理从当前结点的左子结点到该前驱结点路径上的所有结点。完成后将当前结点更新为当前结点的右子结点
3.  重复步骤 1、2 直到遍历结束

<!--listend-->

```cpp
void __reverse_process(BinaryTreeBaseNode* node) {
  if (node == nullptr) {
    return;
  }
  __reverse_process(node->right);
  process(node);
}
void postorderTraversal(BinaryTreeBaseNode* root) {
  BinaryTreeBaseNode* cur = root,* prev = nullptr;
  while (cur != nullptr) {
    prev = cur->left;
    if (prev != nullptr) {
      while (prev->right != nullptr && prev->right != cur) {
	prev = prev->right;
      }
      if (prev->right == nullptr) {
	prev->right = cur;
	cur = cur->left;
	continue;
      }
      prev->right = nullptr;
      __reverse_process(cur->left);
    }
    cur = cur->right;
  }
  __reverse_precess(root);
}
```


#### 迭代器 {#迭代器}

既然可以遍历一棵树，那么依然希望可以在这棵树上暂停下来，对结点进行一些操作，再继续进行迭代。当我们选择的遍历方法不一样时，其迭代时的前驱与后继就不相同。

如果现在给定一个迭代器，应该如何找到迭代器的前驱与后继迭代器。这里给出求解中序遍历前驱的算法步骤与代码，求解中序遍历后继的算法与前驱的算法类似，因此只给出代码。

-   求解前驱
    -   如果结点的左子树存在，则前驱是结点左子树上最大的结点
    -   如果结点的左子树不存在，则需要寻找结点的 parent
        -   若结点是 parent 的右子树上的结点，则 parent 是其前驱
        -   若结点是 parent 的左子树上的结点，继续向上寻找，直到 parent 为 nullptr
            或是其 parent 的右子树上的结点

<!--listend-->

```cpp
// 寻找结点 node 的前驱
BinaryTreeBaseNode* get_previous(BinaryTreeBaseNode* node) {
  if (node->left != nullptr) {
    node = node->left;
    while (node->right != nullptr) {
      node = node->right;
    }
  } else {
    auto parent = get_parent(node);
    while (parent != nullptr && parent->left == node) {
      node = parent;
      parent = get_parent(parent);
    }
    node = parent;
  }
  return node;
}
// 寻找结点 node 的后继
BinaryTreeBaseNode* get_next(BinaryTreeBaseNode* node) {
  if (node->right != nullptr) {
    node = node->right;
    while (node->left != nullptr) {
      node = node->left;
    }
  } else {
    auto parent = get_parent(node);
    while (parent != nullptr && parent->right == node) {
      node = parent;
      parent = get_parent(parent);
    }
    node = parent;
  }
  return node;
}
```


### 示例：表达式树 {#示例-表达式树}

下图展示了一棵 **表达式树** (expression tree)，leaf node 是操作数 (operand)，而
internal node 为运算符 (operator)。由于所有操作都是二元的，因此这颗树为二叉树。每个 operator 的 operand 分别是其两个子树的运算结果。

{{< figure src="/images/algo-example-of-expression-tree.svg" width="64%" >}}

这个树对应的表达式为 \\(a+b\*c + (d\*e+f)\*g\\) ，如果我们对这颗树进行 postorder
traversal 将得到序列 \\(a b c \* + d e \* f + g \* +\\) ，这是一个后缀表达式；如果对其进行 preorder traversal，则会得到前缀表达式 \\(+ + a \* b c \* + \* d e f g\\) ；最后试一下 inorder traversal，其结果应该是中缀表达式，不过其序列并没有带括号。

从 postorder traversal 的结果，可以很轻松的构建其这棵树。留给读者进行实现，这里将不再说明。


## 二叉查找树 (BST) {#二叉查找树--bst}

假设树上每个结点都存储了一项数据，如果这些数据是杂乱无章的插入树中，那查找这些数据时并不容易，需要 \\(\mathcal{O}(N)\\) 的时间复杂度来遍历每个结点搜索数据。

如果想要时间复杂度降到 \\(\mathcal{O}(\log\_{}{N})\\) ，则需要在常数时间内，将问题的大小缩减。如果为一个结点加上限制，比如子树上的值总比当前结点的值大，而另一边总比当前结点的值小，如此便在常数时间内可以将问题的大小减半，可以判断接下来搜索左子树还是右子树。这种加以限制的二叉树被称为 **二叉查找树** (Binary Search Tree, BST)。假定 BST 中左结点总是严格小于当前结点的值，而右结点总是不小于当前结点的值。

{{< figure src="/images/algo-example-of-BST.svg" width="40%" >}}

二叉树的遍历四种方法很简单，如果将其用于 BST 上有什么效果呢：

-   前序遍历： \\(6, 2, 1, 4, 3, 8, 7, 9\\)
-   中序遍历： \\(1, 2, 3, 4, 6, 7, 8, 9\\)
-   后序遍历： \\(1, 3, 4, 2, 7, 9, 8, 6\\)
-   层序遍历： \\(6, 2, 8, 1, 4, 7, 9, 3\\)


### BST 中进行查找 {#bst-中进行查找}

对 BST 的查找操作中，以下三种操作是最为简单的。

-   判断元素是否存在，存在时将返回 `true` ，反之返回 `false`
    ```cpp
    template <class Element>
    bool contains(BinaryTreeNode<Element>* root, const Element& target) {
      if (root == nullptr) {
        return false;
      }
      if (root->data == target) {
        return true;
      }
      return contains(root->data < target ? root->right : root->left, target);
    }
    ```
-   查找最小值并返回其结点
    ```cpp
    template <class Element>
    BinaryTreeNode<Element>* find_min(BinaryTreeNode<Element>* root) {
      if (root == nullptr) {
        return nullptr;
      }
      return root->left == nullptr ? root : find_min(root->left);
    }
    ```
-   查找最大值并返回其结点
    ```cpp
    template <class Element>
    BinaryTreeNode<Element>* find_max(BinaryTreeNode<Element>* root) {
      if (root != nullptr) {
        while (root->right != nullptr) {
          root = root->right;
        }
      }
      return root;
    }
    ```

刚刚我们定义了 BST 中 N、L、R 的关系，简单的数学表达即 \\(L < N \land N \leq R\\) 。如果这颗二叉树里有相同的元素，如何找出这些元素的范围。实际上这个问题可以转换为求解
BST 上，给定元素的上下界，下界 (\\(bound\_{lower}\\)) 是首个 **不小于** 给定元素的结点，上界 (\\(bound\_{upper}\\)) 为首个 **严格大于** 给定元素的结点，相同元素的范围即
\\([bound\_{lower}, bound\_{upper})\\) 。

```cpp
// 获取下界
template <class Element>
BinaryTreeNode* get_lower_bound(BinaryTreeNode* root, const Element& target) {
  auto result = root;
  while (root != nullptr) {
    if (!(root->data < target)) {
      result = root;
      root = root->left;
    } else {
      root = root->right;
    }
  }
  return result;
}
// 获取上界
template <class Element>
BinaryTreeNode* get_upper_bound(BinaryTreeNode* root, const Element& target) {
  auto result = root;
  while (root != nullptr) {
    if (target < root->data) {
      result = root;
      root = root->left;
    } else {
      root = root->right;
    }
  }
  return result;
}
```


### BST 中进行插入与移除操作 {#bst-中进行插入与移除操作}

插入一个元素在 BST 上的操作十分简单，与 `contains` 函数一样，以 BST 的定义顺着
BST 向下寻找，直到结点的子结点为 nullptr 为止，将这个插入的结点挂载到这个查找到的子结点上。

{{< figure src="/images/algo-insert-op-for-BST.svg" width="85%" >}}

如果是移除操作呢？我们一直忽略了如何在二叉树中移除一个元素，因为正常的一棵二叉树中，如果你想移除一个结点，你需要处理移除结点之后 parent 与 child 之间的关系。这并不好处理，你不确定这些 child 是否可以挂载到 parent 上，继续以 parent 的子结点出现。幸运的是，你可以直接将其值与一个 leaf 交换，并直接删除 leaf 就好，这样你就没有 parent 的担忧了。

这种交换的方式可以用于 BST 吗？当然是完全可以。现在只剩下一个问题了，如何保证在移除结点后，这棵树依然是 BST，稍微转换一下问题的问法：和哪个 leaf 交换不会影响
BST 的结构。

当然是和其前驱或者后继交换后再删除不会影响 BST 的整体结构，如果前驱或后继并不是
leaf，那么递归地交换结点的值，直到结点是 leaf 为止。如果这个结点本身就是 leaf，那不用找了，决定就是你了！

可选择前驱还是后继呢，如果结点有右子树，则代表着其后继在右子树中；如果结点有左子树，则表达其前驱在左子树中。如果没有对应的子树，代表其前驱或者后继需要回到父结点寻找，为了不必要的复杂度，一般选择在其子树中寻找前驱 / 后继结点。如果你找到了一个结点的前驱 / 后继，但它不是叶结点，那需要继续寻找这个结点的前驱 / 后继，直到待删除的结点成为叶结点为止。

{{< figure src="/images/algo-remove-op-for-BST.svg" width="64%" >}}


### BST 的平均情况分析 {#bst-的平均情况分析}

一棵树的所有结点的深度和称为 **内部路径长** (internal path length)，我们尝试计算
BST 平均路径长。令 \\(D(N)\\) 是具有 N 个结点的某棵树 T 的内部路径长，则有 \\(D(1) =
0\\) 。一棵 N 结点树是由一棵 \\(i (0 \leq i < N)\\) 结点左子树和一棵 \\(N - i - 1\\) 结点右子树及深度为 0 的根组成的，则可以得到递推关系 \\[D(N) = D(i) + D(N - i - 1) + N -
1.\\] 如果所有子树的大小都是等可能出现的，那么 \\(D(i)\\) 与 \\(D(N - i - 1)\\) 的平均值都是 \\((1/N)\sum\_{j=0}^{N-1}{D(j)}\\) ，于是 \\[D(N) =
\frac{2}{N}[\sum\_{j=0}^{N-1}{D(j)}] + N - 1.\\] 得到平均值 \\(D(N) = \mathcal{O}(N
\log\_{}{N})\\) ，因此结点的预期深度 \\(\mathcal{O}(\log\_{}{N})\\) ，但这不意味着所有操作的平均运行时间是 \\(\mathcal{O}(\log\_{}{N})\\) 。

Weiss 在书中为我们展示了一个随机生成的 500 个结点的 BST，其期望平均深度为 9.98。

{{< figure src="../images/Algorithm⁄DataStructure/random-the-500-nodes-bst.png" >}}

如果交替插入和删除 \\(\Theta(N^{2})\\) 次，那么树的平均期望深度将是 \\(\Theta(\sqrt{N})\\) 。而下图展示了在 25 万次插入移除随机值之后树的样子，结点的平均深度为 \\(12.51\\) 。其中有可能的一个原因是，在移除结点时 remove 总是倾向于移除结点的前驱，而保留了结点的后继。我们可以尝试随机移除结点前驱或后继的方法来缓解这种不平衡。还有一个原因是一个给定序列，由根 (给定序列的第一个元素) 的值决定这棵树的偏向，如果根元素过大则会导致左子树的结点更多，因为序列中大部位数都小于根，反之则导致右子树结点增多。

{{< figure src="../images/Algorithm⁄DataStructure/random-insert-remove-operation-bst.png" >}}


## 线索二叉树 (TBT) {#线索二叉树--tbt}

如果一棵二叉树，所有原本为空的右孩子改为指向该结点的中序遍历的后继，所有原本为空的左孩子改为指向该结点的中序遍历的前驱，那么修改后的二叉树被称为 **线索二叉树**
(Threaded binary tree, TBT)。指向前驱、后继的指针被称为线索，对二叉树以某种遍历顺序进行扫描并为每个结点添加线索的过程称为二叉树的 **线索化** ，进行线索化的目的是为了加快查找二叉树中某节点的前驱和后继的速度。

{{< figure src="/images/algo-example-of-TBT.svg" width="72%" >}}

TBT 能线性地遍历二叉树，从而比递归的中序遍历更快。使用 TBT 也能够方便的找到一个结点的父结点，这比显式地使用父结点指针或者栈效率更高。这在栈空间有限，或者无法使用存储父节点的栈时很有作用。


### TBT 的存储结构 {#tbt-的存储结构}

如果一棵二叉树线索化之后，需要分辨哪些是线索哪些是边，因此我们不得不修改数据结构，使得有 field 来指示该结点的左或右孩子是否是线索。

{{< admonition type="warning" >}}
该节剩下内容将作为扩展部分，可以进行选择性阅览。
{{< /admonition >}}

我们改写为代码，由于 tag 实际上至于要 1 bit 就能指示线索，这时候 C / C++ 的优势就体现出来了，我们可以通过 **位域** 限制 tag 的大小，并将两个 tag 合并在 1 Byte 上来减少结构体空洞带来的内存浪费。

```cpp
// 假设运行在 UNIX-like 64 bit OS 之上
template <class Element>
struct ThreadedBinaryTreeNode {
  Element data;
  unsigned char ltag : 1;
  unsigned char rtag : 1;
  ThreadedBinaryTreeNode* left,* right;
};
```

在之前的内容中，所有代码尽量都避免 C / C++ 的一些深度的语言特性，来避免读者因为编程语言的特性而带来的困扰。但是下面这个例子，将展示 C / C++ 因为其底层、灵活而展示出的强大。

在 LP64 模型下指针大小为 64 bit，从堆上分配来的内存的地址，起始地址能够被其最宽的成员大小整除。那么含有指针的 `TreadedBinaryTreeNode` 在分配时其地址可以被 8
byte 整除，这是什么概念的，就是其地址的 **低 3 bit 一定为 0**​。我们可以充分利用这 3
bit，在不改变二叉树结点结构的情况下，辨别该结点是否是线索。如此整个结构体大小缩小了 8 byte。其实这个技巧在很多 C 代码中都有使用，甚至你可以考虑将结构体空洞废物利用起来，或者 C 的宏编程，这些​**奇技淫巧**​威力强大但降低了代码的可读性。

使用最低 3 bit 存储状态，那么我们在使用时就不能直接使用指针了，那么下列函数可能会对你使用这 3 bit 有帮助。

```cpp
enum NodeStatus {
  LINK   = 0,
  THREAD = 1,
};
constexpr uintptr_t HIDE_BIT{3};
inline BinaryTreeBaseNode* get_node(BinaryTreeBaseNode* node) {
  return reinterpret_cast<BinaryTreeBaseNode*>(reinterpret_cast<uintptr_t>(node) & ~HIDE_BIT);
}
inline BinaryTreeBaseNode* get_left(BinaryTreeBaseNode* node) {
  return get_node(get_node(node)->left);
}
inline BinaryTreeBaseNode* get_right(BinaryTreeBaseNode* node) {
  return get_node(get_node(node)->right);
}
inline uintptr_t get_status(BinaryTreeBaseNode* node) {
  return reinterpret_cast<uintptr_t>(node) & HIDE_BIT;
}
inline void set_left_link(BinaryTreeBaseNode* node, BinaryTreeBaseNode* left) {
  node->left = left;
}
inline void set_left_thread(BinaryTreeBaseNode* node, BinaryTreeBaseNode* left) {
  node->left = reinterpret_cast<BinaryTreeBaseNode*>(reinterpret_cast<uintptr_t>(left) | NodeStatus::THREAD);
}
inline void set_right_link(BinaryTreeBaseNode* node, BinaryTreeBaseNode* right) {
  node->right = right;
}
inline void set_right_thread(BinaryTreeBaseNode* node, BinaryTreeBaseNode* right) {
  node->right = reinterpret_cast<BinaryTreeBaseNode*>(reinterpret_cast<uintptr_t>(right) | NodeStatus::THREAD);
}
inline bool is_thread(BinaryTreeBaseNode* node) {
  return get_status(node) == NodeStatus::THREAD;
}
```


### 线索化 {#线索化}

线索化时需要记录结点的前驱，如果你仔细观察 Morris Traversal，你可能会发现，
Morris Traversal 是在构建一部分线索二叉树。

```cpp
template <class Element>
void inorder_threading(ThreadedBinaryTreeNode<Element>* root) {
  auto curr = root, prev = root;
  while (curr != nullptr) {
    if (curr->left == nullptr) {
      curr->left = prev;
      curr->ltag = NodeStatus::THREAD;
      prev = curr;
      goto RIGHTING;
    }
    prev = curr->left;
    while (prev->right != nullptr && prev->right != curr) {
      prev = prev->right;
    }
    if (prev->right == nullptr) {
      prev->right = curr;
      prev->rtag = NodeStatus::THREAD;
      curr = curr->left;
      continue;
    }
    prev = prev->right;
 RIGHTING:
    curr = curr->right;
  }
  // 由于 root 的后继的左线索指向不正确，需要对其进行修正
  if (root->right != nullptr) {
    curr = root->right;
    while (curr->ltag == NodeStatus::LINK) {
      curr = curr->left;
    }
    curr->left = root;
    curr->ltag = NodeStatus::THREAD;
  }
  // 由于中序遍历第一个结点的左线索指向不正确，将其置空。其最后一个结点同样也是置空的
  curr = root;
  while (curr->ltag == NodeStatus::LINK) {
    curr = curr->left;
  }
  curr->left = nullptr;
  curr->ltag = NodeStatus::LINK;
}
```


## 树和森林 {#树和森林}

其实最后一点内容并没有多少，主要探讨树、森林、二叉树的关系，以及在严蔚敏老师的数据结构中提到的其他有关树的一些实现方式。


### 树的其他实现方式 {#树的其他实现方式}

我们可以用不同的实现方法来表示 [树的属性](#树的属性) 一节中的树结构。

父结点表示法
: 如果我们将所有结点放入一个顺序存储中，以下标直接存取结点，并在结点中表示其父结点的下标

    {{< figure src="/images/algo-tree-of-parent-implement.svg" width="90%" >}}

孩子表示法
: 我们对父结点表示法稍加修改，结点中不再存放其父结点的下标，而是改为所有子结点的下标

    {{< figure src="/images/algo-tree-of-child-implement.svg" width="72%" >}}

兄弟表示法
: 即上文提到的树的表示方法。回过头我们再观察其结构，很容易发现这其实就是一棵二叉树，其左子结点代表其下所有子结点，而右结点代表其兄弟结点

    {{< figure src="/images/algo-tree-of-sibling-implement.svg" width="72%" >}}


### 森林 {#森林}

由 \\(m (m \in \mathbb{N})\\) 棵互不相交的树的集合，称之为森林，即这些树没有公共
ancestor。我们可以将不同的树的根看作是 sibling，那么我们可以很轻松的将森林转换为一棵二叉树。
