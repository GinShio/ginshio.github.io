# GPG 入门指北


Pretty Good Privacy (**PGP**)，是一套用于讯息加密、验证的应用程序，由 [Phil
Zimmermann](https://en.wikipedia.org/wiki/Phil_Zimmermann) 于1991年发布，由一系列散列、数据压缩、对称密钥加密以及公钥加密的算法组合而成。GNU Privacy Guard (**GPG**)，是一个用于加密、签名通信内容以及管理非对称密钥的自由软件，遵循IETF订定的 [OpenPGP技术标准](https://tools.ietf.org/html/rfc4880) 设计，并与PGP保持兼容。

GPG的基于现代密码学，主要是对非对称加密的应用，由于自己本身是菜鸡，又没有学过密码学，所以对于以下加密方式进行简单的介绍，如有不准确请指正。

对称加密
: 又称私钥加密，这类算法在加密与解密时使用 **相同的** 的密钥，通信双方在通信之前需要协商一个密钥。对称加密简单、高效，加密强度随密钥长度的增加而增加，常见加密算法 `DES`、`ChaCha20`、`AES` 等

非对称加密
: 又称公开密钥加密，这类算法采用公钥加密私钥解密，公钥可以随意发布，私钥必须由用户严格保管，通信双方在通信时使用对方的公钥加密自己的信息。非对称加密的数学基础是**超大整数的因数分解**、**整数有限域离散对数**、**椭圆曲线离散对数**等问题的复杂性。数字签名也是基于非对称加密实现，简单地说即将文件散列后使用私钥加密生成签名，验证时散列文件并与公钥解密签名的值做对比进行验证，数字签名可以验证文件完整性，也有防止伪造的作用。常见的加密算法有 `DSA`、`RSA`、`ECDSA` 等


## 初体验 {#初体验}


### 生成 {#生成}

使用 `--generate-key` 参数可以创建一个使用默认值的密钥对，如果想设置更多的值可以使用 `--full-generate-key` 参数，如果再加上 `--expert` 开启专家模式，专家模式允许你自己选择 **不同的加密算法** 与 **不同的密钥种类**，在此仅介绍
`--full-generate-key` 参数。

选择你希望的密钥种类
: 我们选择默认的 <span class="underline">RSA and RSA</span>，会生成采用RSA算法且拥有加密、签名、验证功能的密钥

密钥长度
: [NIST建议](https://www.keylength.com/en/4/) 2030年之前推荐的最小密钥长度，对称加密 **128bit** ，非对称加密
    **2048bit** ，椭圆曲线密码学 **224bit**

使用期限
: 默认为永久(0)，在这里我们选择1天 (1)

我们生成了一个密钥对，可以看到一些关于新生成的密钥的信息，包括了密钥长度、uid、指纹，我们一般使用指纹来分别不同的密钥，指纹是用40位16进制数字表示的串，我们一般使用**邮箱**、**整串**或**串的最后16位**区分密钥。

{{< figure src="/ox-hugo/generate-gpg-key.png" >}}


### 备份 {#备份}

我们采用最朴素的方式保存密钥 —— 本地存储，但是请记住一点，私钥一定不能丢失或外泄。为了以防万一，我们生成一份**吊销证书**，用以在特殊情况时吊销该密钥，当然吊销证书也应该妥善保管。

```shell
gpg -a --export EFC4B50FE8F8B2B3 > test.pub # 导出公钥
gpg -a --export-secret-key EFC4B50FE8F8B2B3 > test.sec # 导出私钥
gpg -a --gen-revoke EFC4B50FE8F8B2B3 > test.rev # 生成吊销证书
```


### 发布 {#发布}

<div class="warning">

将公钥发布到密钥服务器上是不可逆行为，请谨慎操作

</div>

首先列出常用的密钥服务器

-   [sks-keyserver](http://pool.sks-keyservers.net)
-   [OpenPGP.org](https://keys.openpgp.org)
-   [GnuPG.net](http://keys.gnupg.net)
-   [MIT](https://pgp.mit.edu)
-   [Ubuntu](http://keyserver.ubuntu.com)

我们可以从密钥服务器上查找、上传或导入公钥，如果我们已经上传了公钥，本地更新信息后需要再次上传将信息同步到服务器。需要注意的是，公钥服务器会不断同步公钥，不会因为你的密钥过期或吊销而删除。当你将公钥上传到服务器后，其他人可以很好获取你的公钥，完成一些实际用途。

```shell
gpg --keyserver pool.sks-keyservers.net --send-keys EFC4B50FE8F8B2B3
```


### 吊销 {#吊销}

<div class="warning">

吊销密钥是不可逆行为，请谨慎操作

</div>

吊销密钥是不可逆行为，当由于某些特殊原因，请吊销密钥并更新服务器上的密钥信息，尤其是私钥泄漏发生时请尽快吊销，吊销时将密钥生成的吊销证书导入 gpg 即可完成。

```shell
gpg --import test.rev # 吊销密钥
gpg --keyserver pool.sks-keyservers.net --send-keys EFC4B50FE8F8B2B3 # 更新吊销信息
```


## 深♂入♂了♂解 {#深-入-了-解}

我们已经有了自己的密钥，那么接下来，我们先创建一个名为 `alpha.txt` 的文件，里面记录了大写字母A-Z，剩下的就交给GPG来做吧。

```shell
# 创建 alpha.txt
echo "ABCDEFGHIJKLMNOPQRSTUVWXYZ" > alpha.txt
```


### 导入与删除 {#导入与删除}

刚刚我们接触到了如何生成密钥，接下来我们还需要导入一些密钥，可能是其他人的，也可能是我们自己的。我们可以从密钥服务器上查找一些公钥，并导入到本地，我们使用
[Debian Key Server](https://keyring.debian.org/) 上举例的公钥 `673A03E4C1DB921F` 做演示

```shell
gpg --keyserver pool.sks-keyservers.net --search-keys 673A03E4C1DB921F # 查找公钥
gpg --keyserver pool.sks-keyservers.net --recv-keys 673A03E4C1DB921F # 导入公钥
```

对于一些本地的密钥，我们可以使用 `--import` 导入密钥，在使用 `--list-keys` 展示密钥时你会发现，每个密钥都有一个信任级别，这是一个十分复杂的概念，你可以将好友的
GPG公钥签名后 (`--sign-keys`)，再上传到公钥服务器上，逐渐组成一个大的 **信任网络**
，emmm...参见 **Key Signing Party**

```shell
gpg --import test.sec # 导入之前备份的私钥
```

至于删除密钥，相对来说简单很多，`--delete-keys` 可以删除公钥，
`--delete-secert-keys` 可以删除私钥

```shell
gpg --delete-keys EFC4B50FE8F8B2B3
```


### 加密与解密 {#加密与解密}

加密与解密内容是我们申请RSA密钥的主要理由，我们可以将我们重要的数据加密、签名，然后发布到互联网上，这样没人可以知道你发布了什么，除非他获取到了你的私钥。

加密
: 参数 `-e` / `--encrypt`，加密时使用 `-r` / `--recipient` 指定密钥，加密文件时默认的加密文件为 **alpha.txt.gpg**

    ```shell
    gpg -er EFC4B50FE8F8B2B3 alpha.txt # 加密文件，输出到 alpha.txt.gpg
    gpg -er EFC4B50FE8F8B2B3 -o alpha.encrypt alpha.txt # 加密文件，输出到 alpha.encrypt
    md5sum alpha.txt | awk '{print $1}' - | gpg -aer EFC4B50FE8F8B2B3 - # 将文件的md5校验值加密输出到终端
    ```


解密
: 参数 `-d` / `--decrypt`，使用 `-u` / `--local-user` 指定密钥，解密文件时默认将解密的内容输出到终端中

    ```shell
    gpg -du EFC4B50FE8F8B2B3 alpha.txt.gpg > alpha.decrypt # 解密数据到 alpha.decrypt
    ```


### 签名与校验 {#签名与校验}

我们有时不需要对一些发布的文件进行加密，可以进行数字签名，表示这个文件是我发出的，并不是别人伪造的。签名时指定密钥的参数与解密相同 `-u` / `--local-user` ，数字签名的方式有多种，接下来依次介绍

二进制签名
: 参数 `-s` / `--sign`，这种签名将源内容与签名存放在同一文件下，并以二进制的形式保存文件，默认输出文件为 **alpha.txt.gpg**

    ```shell
    gpg -u EFC4B50FE8F8B2B3 --sign alpha.txt
    ```

文本签名
: 参数 `--clear-sign`，这种签名将源内容与签名存放在同一文件下，并以文本的形式保存文件，查看输出文件就可以发现源内容与签名存放在一起，默认输出文件为
    **alpha.txt.asc**

    ```shell
    gpg -u EFC4B50FE8F8B2B3 --clear-sign alpha.txt
    ```

分离式签名
: 参数 `-b` / `--detach-sign`，这种签名将源内容与签名存放在不同文件，签名与源文件可以分别发布，默认签名为二进制形式，默认输出文件名为 **alpha.txt.sig**。如果需要文本形式的分离式签名可以加参数 `-a` / `--armor`，此时默认输出文件名为 **alpha.txt.asc**

    ```shell
    gpg -u EFC4B50FE8F8B2B3 -b -o alpha.bin.sig alpha.txt # 二进制分离式签名
    gpg -u EFC4B50FE8F8B2B3 -ab -o alpha.asc.sig alpha.txt # 文本分离式签名
    ```

签名加密同时进行
: 以上签名形式只进行签名，没有加密，以下介绍的方式可以让签名加密同时进行，但验证签名时只能直接解密同时验证签名，默认输出文件名为 **alpha.txt.gpg**

    ```shell
    gpg -u EFC4B50FE8F8B2B3 -r EFC4B50FE8F8B2B3 -se alpha.txt
    ```

签名就此介绍完了，如果我们需要验证他人的文件，需要先获取他们的公钥才可以开始验证文件，使用参数 `--verify` 对签名文件进行验证

```shell
gpg --verify alpha.txt.asc # 验证混合签名文件
```

对于分离式签名，后缀是 **.asc** 和 **.sig** 的文件，gpg会默认查找去除后缀后的文件名作为数据文件进行验证，也可以手动指定待验证的数据文件

```shell
gpg --verify alpha.bin.sig # 错误，没有文件 alpha.bin.sig
cp alpha.asc.sig alpha.txt.asc.sig
gpg --verify alpha.txt.asc.sig # 验证文件 'alpha.txt.asc'，签名损坏
cp alpha.asc.sig alpha.txt.sig
gpg --verify alpha.txt.sig # 验证文件 'alpha.txt'，签名完好
gpg --verify alpha.bin.sig alpha.txt # 指定数据文件为 'alpha.txt'，使用 'alpha.bin.sig' 进行验证
```

<style>
div.info{background:rgba(58,129,195,0.15);border-left:4px solid rgba(58,129,195,0.45);margin:1.8rem 0 1.25rem 15px;padding:0.8em;line-height:1.4;text-align:left;position:relative;clear:both}div.info p{margin:0}div.info::before{content:"i";background:rgba(58,129,195,0.8);align-items:flex-end;top:-1rem;font-weight:700;font-size:1.4rem;-webkit-clip-path:circle(50% at 50% 50%);clip-path:circle(50% at 50% 50%);width:30px;height:30px;display:inline-flex;justify-content:center;position:absolute;left:-1.2rem;line-height:1.3;text-align:left}div.success{background:rgba(45,149,116,0.15);border-left:4px solid rgba(45,149,116,0.45);margin:1.8rem 0 1.25rem 15px;padding:0.8em;line-height:1.4;text-align:left;position:relative;clear:both}div.success p{margin:0}div.success::before{content:"✔";background:rgba(45,149,116,0.8);align-items:flex-end;top:-1rem;font-weight:700;font-size:1.4rem;-webkit-clip-path:polygon(50% 0%, 100% 50%, 50% 100%, 0% 50%);clip-path:polygon(50% 0%, 100% 50%, 50% 100%, 0% 50%);width:35px;height:35px;display:inline-flex;justify-content:center;position:absolute;left:-1.2rem;line-height:1.5;text-align:left}div.warning{background:rgba(220,117,47,0.15);border-left:4px solid rgba(220,117,47,0.45);margin:1.8rem 0 1.25rem 15px;padding:0.8em;line-height:1.4;text-align:left;position:relative;clear:both}div.warning p{margin:0}div.warning::before{content:"!";background:rgba(220,117,47,0.8);align-items:flex-end;top:-1rem;font-weight:700;font-size:1.4rem;-webkit-clip-path:polygon(50% 0, 0 100%, 100% 100%);clip-path:polygon(50% 0, 0 100%, 100% 100%);width:35px;height:35px;display:inline-flex;justify-content:center;position:absolute;left:-1.2rem;line-height:1.1;text-align:left}div.error{background:rgba(186,47,89,0.15);border-left:4px solid rgba(186,47,89,0.45);margin:1.8rem 0 1.25rem 15px;padding:0.8em;line-height:1.4;text-align:left;position:relative;clear:both}div.error p{margin:0}div.error::before{content:"!";background:rgba(186,47,89,0.8);align-items:flex-end;top:-1rem;font-weight:700;font-size:1.4rem;-webkit-clip-path:polygon(25% 0%, 75% 0%, 100% 50%, 75% 100%, 25% 100%, 0% 50%);clip-path:polygon(25% 0%, 75% 0%, 100% 50%, 75% 100%, 25% 100%, 0% 50%);width:35px;height:30px;display:inline-flex;justify-content:center;position:absolute;left:-1.2rem;line-height:1.1;text-align:left}
</style>

