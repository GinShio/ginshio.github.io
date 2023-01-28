# I/O 复用


在客户端阻塞在 read 等待用户输入时，服务器关闭会导致向客户端发送 FIN，这是客户端的另一个输入。但由于客户端阻塞在 read 从而无法立即接受这个输入，直到从套接字读入为止。这就需要进程提前告知内核，使得内核在进程指定的输入准备好后，或可以输出后，立即通知进程，这个能力被称为 I/O 复用 (I/O multiplexing)。

I/O 复用有多个 syscall 可以实现，Unix 古老的函数 select 与 poll，POSIX 有一个比较新的变种为 pselect，而 Linux 与 freeBSD 独立发展出了 **epoll** 与 **kqueue**。

I/O 复用典型适用于以下场合：

-   当客户处理多个描述符时
-   客户同时处理多个套接字时，不过这种场景比较少见
-   如果 TCP 服务器既要监听套接字，又要处理已连接的套接字
-   如果一个服务器既要处理 TCP 又要处理 UDP，或同时处理多个不同协议，或多个服务

需要注意的是，并非只有网络编程需要用到 I/O 复用，I/O 复用是对文件描述符状态的监听，因此其他场景下也有其适用的空间。


## I/O 模型 {#i-o-模型}

在 Unix 系统上，一个输入操作通常包含两个不同的阶段

1.  数据准备完成
2.  从内核向进程复制数据

在等待数据准备到复制数据的过程，根据行为的不同，I/O 模型主要分为以下几种

-   **blocking I/O** (阻塞式 I/O)

    阻塞式 I/O 模型是最常见、最简单、最好理解的 I/O 模型，目前为止所有的套接字函数都是阻塞式 I/O，另外 C 标准库所提供的 I/O 也是阻塞式 I/O，这样的模型符合初学函数时提及的运行流程。

    {{< figure src="/images/unp-blocking-io-model.svg" width="64%" >}}

    在 recvfrom 这个示例中，只有数据报到达且复制到进程缓冲区中或错误发生才返回，而这段时间内进程是被阻塞的，不再向下运行代码。

-   **nonblocking I/O** (非阻塞式 I/O)

    非阻塞进程调用时，在数据未准备好时调用会直接返回一个错误，而非阻塞进程，在下次调用前，进程可以去处理其他数据。

    {{< figure src="/images/unp-non-blocking-io-model.svg" width="64%" >}}

    在上图中，可以反复调用 syscall 查看数据是否已复制到缓冲区。如果我们有一系列非阻塞描述符时，可以轮流对其进行询问，这种方式称为**轮询** (polling)，当有描述符可用时进行处理，否则询问下一个描述符。但是这样做会消耗大量的 CPU，因此需要尽可能少的使用该方法。

-   **I/O multiplexing** (I/O 复用, e.g. select, poll)

    I/O 复用是指对一组描述符进行监听，然后阻塞进程，直到这组事件中有某个或某些事件发生或等待超时。可以如此理解：将轮询操作从进程迁移进内核中，由内核对这些描述符进行监听，进程只需要等待内核通知某个描述符数据准备完毕。对于进程来说，将阻塞在 I/O 复用这个 syscall 上，而不会阻塞在真正的系统调用上。

    {{< figure src="/images/unp-io-multiplexing-model.svg" width="64%" >}}

    I/O 复用类似多线程中的阻塞式 I/O，都可以同时监听多个描述符的 I/O 事件，区别就是 I/O 复用完成了一个线程监听多个描述符，而另一个实现方式是一个线程一个描述符，不过每个描述符都可以在不同线程上同时被处理。

    另外需要注意的是，I/O 复用时会有 **两次** syscall 的开销，第一次发生在 I/O 复用函数，这个函数将监听那些进程传递给内核的感兴趣的描述符集合，在某个或某些描述符准备完成后，将从 I/O 复用函数返回，进程再次调用真正的 I/O syscall 进行处理。

-   **signal driven I/O** (信号驱动型 I/O, e.g. SIGIO)

    在描述符就绪时，让内核通过发送 SIGIO 信号通知进程的方式，被称为 signal
    driven I/O。

    {{< figure src="/images/unp-signal-driven-io-model.svg" width="64%" >}}

    首先开启描述符的信号驱动 I/O 功能，再调用 sigaction 对 SIGIO 信号注册回调函数，sigaction 不会阻塞进程，会立即返回。当描述符准备完成后，内核将向进程发送
    SIGIO 信号，随后可以在信号处理函数中对数据进行读写、操作等。

    这种模型的优势在于等待数据期间，无需阻塞进程，可以在信号来临之前执行其他操作。

-   **asynchronous I/O** (异步 I/O, e.g. POSIX aio_xxx functions)

    异步 I/O 告知内核启动某个操作，并让内核在整个操作完成后通知进程，进程可以不被阻塞继续执行。Asynchronous I/O 与 Signal-Driven I/O 最大的区别是：前者由内核通知 I/O 操作何时完成，后者通知何时可以启动一个 I/O 操作。

    {{< figure src="/images/unp-asynchronous-io-model.svg" width="64%" >}}

对于这 5 种 I/O 模型，前 4 种在第一阶段 (即等待数据阶段) 有所区别，但第二阶段
(将数据从内核复制到缓冲区中) 是一样的，都是调用实际的 syscall 并阻塞于此。而异步
I/O 需要处理这两个阶段，进程不被阻塞也无需关心，只需要在 I/O 完成后处理数据即可。所以称前四种 I/O 为 **同步** (synchronous) I/O，这些 I/O 将导致请求的进程阻塞，直到 I/O 完成。

{{< figure src="/images/unp-comparison-of-various-io-models.svg" width="96%" >}}

说一下特殊的几个描述符，每个 Unix 进程在开启时，都会打开这三个标准的 POSIX 文件描述符

| 整数值 | 名称            | 中文名称 | &lt;unistd.h&gt; 符号常量 | &lt;stdio.h&gt; 符号常量 |
|-----|---------------|------|-----------------------|----------------------|
| 0   | Standard Input  | 标准输入流 | `STDIN_FILENO`        | `stdin`              |
| 1   | Standard Output | 标准输出流 | `STDOUT_FILENO`       | `stdout`             |
| 2   | Standard Error  | 标准错误流 | `STDERR_FILENO`       | `stderr`             |


## select 函数 {#select-函数}

select 允许进程指示内核等待多个事件中任何一个发生，在只有一个或多个事件发生或超时时唤醒进程。任何描述符都可以使用 select 进行监听，不止套接字。其中监听事件包括准备读、准备写、异常条件处理，以及超时。

```c
// sys/select.h
// sys/time.h
int select(int nfds, fd_set *readfds, fd_set *writefds,
	   fd_set *exceptfds, struct timeval *timeout);
// positive count of ready descriptors, 0 on timeout, -1 on error
```


### select 参数与返回值 {#select-参数与返回值}

-   参数 timeout

    结构 timeval 的变量 timeout 指示超时时间，其结构如下
    ```c
    struct timeval {
      long tv_sec;    // seconds
      long tv_usecs;  // microseconds
    };
    ```
    该参数有三种可能

    -   `永远等待下去`: 将参数设置为空指针 NULL 时，当集合中有描述符准备好后才返回
    -   `等待一段时间`: 将参数设置非零值，当集合中有描述符在等待时间内准备好就返回，否则超时返回
    -   `不等待`: 将参数设置为零值，检查描述符后立即返回，这种情况又被称为 **轮询** (polling)

    前两种情况下 select 通常会被捕获的信号终端，并从信号处理函数中返回错误 EINTR，
    Berkeley 内核绝不会自动重启被中断的 select，而 SVR4 可以重启指定了
    SA_RESTART 标志的 select。因此为了可移植性，在捕获信号时，必须做好 select 返回 EINTR 错误的准备。

    在绝大多数 Unix 系统上，采用符合 POSIX 的 const 修饰 timeout，也就是说
    select 不会修改 timeout，如果想获取未睡眠的时间需要自行调用时间函数计算。但在 Linux 实现上，select 将修改 timeout 的值来反映未睡眠的时间。因此为了可移植性考虑，在每次调用 select 前，都要对其进行赋值操作。

    如果 timeout 参数的 tv_sec 值超过 `100'000'000` 秒，有些系统会返回一个
    EINVAL 错误，即不支持的 timeout。

-   描述符集合 readfds, writefds, exceptfds

    描述符集合分别指定进程关心的读、写、异常描述符。通常在指定描述符集时，这是个整数数组，其中的每一 bit 对应一个描述符，比如第一位对应描述符 0，第 15 bit
    对应描述符 15。用户无需关心为某一描述符如何读取或修改某一位，所有细节都隐藏在 fd_set 以及相关宏当中。当然使用 bit 只是常见实现方法，我们不应该关心或假想具体实现就是这样，而是将当作黑盒对 fd_set 进行处理。
    ```c
    void FD_ZERO(fd_set *fdset);          // 清除所有 bit
    void FD_SET(int fd, fd_set *fdset);   // 设置关心的描述符
    void FD_CLR(int fd, fd_set *fdset);   // 移除不关心的描述符
    int FD_ISSET(int fd, fd_set *fdset);  // 检查 fd 是否设置
    ```
    如果对某一个种类的描述符集不感兴趣，可以置为空指针。如果将所有描述符集都置为空指针，将会得到一个比 `sleep/1` 更精确的休眠定时器。

-   nfds 参数

    nfds 指定了待测试描述符的个数，其值是最大描述符 \\(+1\\)， `FD_SETSIZE` 是定义
    fd_set 数据可描述的描述符大小的常值，通常是 1024。比如关心 1、4、5 描述符，那么 nfds 应该填 6。

最终看一下返回值，将表示有多少就绪的描述符，并将已就绪描述符在集合中置为 1，剩下的描述符都会被清除为 0。这时只要对描述符集中的关心的描述符依次调用 `FD_ISSET` 检查即可。


### select 函数中描述符的就绪条件 {#select-函数中描述符的就绪条件}

读、写、异常对描述符的状态是一个简单描述，尤其是普通文件描述符，但套接字的就绪条件，应该明确。

1.  在满足下列四个条件之一时，套接字描述符可读
    -   该套接字接收缓冲区中的数据字节数大于等于套接字接收缓冲区低水位标记的当前大小。对这样的套接字执行读操作不会阻塞且一定返回一个大于 0 的值。可以使用
        `SO_RCVLOWAT` 套接字选项对修改标记的值，通常而言默认值为 1
    -   该连接的读半部关闭 (接收了 FIN 的 TCP 连接)，这样的套接字读操作不会阻塞且返回 0
    -   该套接字是一个监听套接字且已完成的连接数不为 0，对这样的套接字进行 accept
        操作不会阻塞
    -   有一个套接字错误待处理，这样的套接字读操作不会阻塞且返回 -1，同时将 errno
        设置为确切的错误条件。可以通过指定 `SO_ERROR` 套接字选项调用 getsockopt 获取并清除
2.  在满足下列四个条件之一时，套接字描述符可写
    -   该套接字发送缓冲区中的可用空间字节数大于等于套接字发送缓冲区低水平位标记的当前大小，且套接字已连接或不需要连接，此时套接字就绪，写操作将不会阻塞并返回一个正值。可以使用 `SO_SNDLOWAT` 套接字选项来修改标记的值，通常而言默认值为 2048
    -   该连接的写半部关闭，这样的套接字写操作将产生 SIGPIPE 信号
    -   非阻塞式 connect 套接字已建立连接，或 connect 已失败告终
    -   有一个套接字错误待处理，对这样的套接字写操作将不阻塞并返回 -1 以及 errno
        错误。可以通过指定 `SO_ERROR` 套接字选项调用 getsockopt 获取并清除
3.  如果一个套接字存在带外数据或仍处于带外标记，那么它有异常条件待处理

接收低水位标记与发送低水位标记的目的在于：允许进程控制在 select 返回可读或可写条件之前有多少数据可读或多大空间可写。举个例子，如果少于 64 byte 的数据对进程来说是无法处理的，可以将低水位标记设置为 64，防止少于 64 byte 数据准备好读时 select
唤醒进程。对于 UDP socket 来说，其发送低水位标记小于等于发送缓冲区大小时，总是可写的，因为 UDP socket 无需连接。

| 条件        | 可读 | 可写 | 异常 |
|-----------|----|----|----|
| 有数据可读  | YES |     |     |
| 关闭连接的读半部 | YES |     |     |
| 监听套接字准备好新连接 | YES |     |     |
| 有可用于写的空间 |     | YES |     |
| 关闭连接的写半部 |     | YES |     |
| 待处理错误  | YES | YES |     |
| TCP 带外数据 |     |     | YES |


## select 示例 {#select-示例}


### 使用 select 实现 TCP echo 程序 {#使用-select-实现-tcp-echo-程序}

现在可以重写 TCP echo 客户端程序，可以在服务器终止之后，客户端马上得知，因此只需要在 str_cli 函数上做修改。新版本的 str_cli 将阻塞于 select，等待标准输入可读或
TCP 套接字可读。

{{< figure src="/images/unp-conditions-handled-by-select-in-strcli.svg" width="36%" >}}

套接字上的三个条件处理如下：

-   如果对端 TCP 发送数据，那么该套接字变为可读，并且 read 返回一个大于 0 的值
-   如果对端 TCP 发送一个 FIN (对端终止)，那么该套接字变为可读，并且 read 返回 0
    (EOF)
-   如果对端 TCP 发送一个 RST (对端崩溃并重启)，那么该套接字变为可读，read 返回
    -1 并设置 errno

`fileno` 的作用是将标准 C 的 FILE\* 结构转换为等价的 Unix 的 fd，而 `fdopen` 则是相反的操作。

```c
void str_cli(FILE *fp, int sockfd) {
  char sendline[MAXLINE] = {0}, recvline[MAXLINE] = {0};
  FILE *sockfd_fp = fdopen(sockfd, "r+");
  fd_set rset;
  FD_ZERO(&rset);
  while (true) {
    FD_SET(fileno(fp), &rset);
    FD_SET(sockfd, &rset);
    int nfds = max(fileno(fp), sockfd) + 1;
    select(nfds, &rset, NULL, NULL, NULL);
    if (FD_ISSET(sockfd, &rset)) {
      // socket is readable
      if (fgets(recvline, MAXLINE, sockfd_fp) == NULL) {
	err_quit("str_cli: server terminated prematurely");
      }
      fputs(recvline, stdout);
      bzero(recvline, MAXLINE);
    }
    if (FD_ISSET(fileno(fp), &rset)) {
      // standard input
      if (fgets(sendline, MAXLINE, fp) == NULL) {
	return;
      }
      fputs(sendline, sockfd_fp);
      bzero(sendline, MAXLINE);
    }
  }
}
```

服务端也可以使用 select 进行修改，从而减轻 fork 大量创建新进程所带来的开销。

通常从终端启动的进程都会打开 stdin、stdout 和 stderr，因此监听套接字 listenfd 通常是 `fd = 3` 的描述符，因此 select 第一个参数将为 4。当客户端建立连接时监听套接字可读，accept 返回连接套接字描述符 4，依次类推。当关闭其中一个连接时，需要一个描述最大描述符值的量，来快速确定 nfds。

在修改时，soket、listen、bind 等基本不变，主要是 while 无限循环中的结构变化。

```c
#include "unp.h"

int main(int argc, char **argv) {
  int listenfd = socket(AF_INET, SOCK_STREAM, 0);
  struct sockaddr_in servaddr = {
    .sin_family = AF_INET,
    .sin_port   = htons(7),
    .sin_addr.s_addr = htonl(INADDR_ANY),
  };
  bind(listenfd, (struct sockaddr_in *) &servaddr, sizeof(servaddr));
  listen(listenfd, LISTENQ);
  int maxfd = listenfd, maxi = -1;
  const int addrlen = sizeof(servaddr);
  int client[FD_SETSIZE];
  memset(client, -1, sizeof(client));
  fd_set allset;
  FD_ZERO(&allset);
  FD_SET(listenfd, &allset);
  char buffer[MAXLINE] = {0};
  while (true) {
    fd_set rset = allset;
    int nready = select(maxfd + 1, &rset, NULL, NULL, NULL);
    if (FD_ISSET(listenfd, &rset)) {
      // new client connection
      int i;
      struct sockaddr_in cliaddr;
      int connfd = accept(listenfd, (struct sockaddr *) &cliaddr, &addrlen);
      for (i = 0; i < FD_SETSIZE; i++) {
	if (client[i] < 0) {
	  client[i] = connfd;
	  break;
	}
      }
      if (i == FD_SETSIZE) {
	err_quit("too many clients");
      }
      FD_SET(connfd, &allset);
      if (connfd > maxfd) {
	maxfd = connfd;
      }
      if (i > maxi) {
	maxi = i;
      }
      if (--nready <= 0) {
	continue;
      }
    }
    for (int i = 0; i <= maxi; i++) {
      int n, sockfd;
      if ((sockfd = client[i]) < 0) {
	continue;
      }
      if (FD_ISSET(sockfd, &rset)) {
	if ((n = read(sockfd, buffer, MAXLINE)) == 0) {
	  close(sockfd);
	  FD_CLR(sockfd, &allset);
	  client[i] = -1;
	} else {
	  write(sockfd, buffer, n);
	}
	if (--nready <= 0) {
	  break;
	}
      }
    }
  }
}
```

但是需要注意但是，目前服务器程序最大的问题是 **拒绝服务攻击** (Denial-of-Service
Attacks)：如果客户端仅发送一个字节的数据，且这个字节不是换行符，然后客户端进入休眠状态。服务器将在调用 read 方法后阻塞于此。简单的说，服务器将被阻塞在这个用户的读操作上，不会处理其他用户数据或接收新连接，直到那个恶意客户终止或发送换行符为止。

这里有个基本概念：当服务器处理多个客户时，服务器 **绝对不能** 阻塞于单个客户相关的某个函数调用，否则导致服务器阻塞，拒绝为其他客户提供服务。这就是所谓的 **拒绝服务攻击** 。可能的解决方法主要是：

-   Nonblocking I/O
-   每个客户单独一个进程 / 线程提供服务
-   对 I/O 操作设置超时时间，打破持续阻塞的窘境


### shutdown 函数 {#shutdown-函数}

如果想终止网络通常是 close 函数，不过 close 函数有两个限制

-   close 将描述符引用计数 \\(-1\\) ，而非真正关闭描述符，只有描述符引用计数为 0 时才会真正关闭
-   close 终止读和写两个方向的数据传输，这是十分严重的，因为对端可能有数据继续写入

通常我们使用 shutdown 来处理，shutdown 可以忽略引用计数，直接向对端发送 FIN。

```c
// sys/socket.h
int shutdown(int sockfd, int howto);
// return 0 if OK, -1 on error
```

howto 参数可以控制 shutdown 的行为，取值如下

| howto 取值 | shutdown 行为 | 释义                    |
|----------|-------------|-----------------------|
| SHUT_RD   | 关闭读半部  | 不再接收数据，缓冲区的数据全部被丢弃 |
| SHUT_WR   | 关闭写半部  | 不再发送数据，连接进入半关闭状态 |
| SHUT_RDWR | 关闭读、写半部 | 等效于依次调用 SHUT_RD、SHUT_WR |


### 批量输入问题 {#批量输入问题}

现在回头看上一篇中简单的 str_cli，这个函数实在太简单了，它可以完成我们预想的工作，除了不能即时反馈服务端已停止工作。它使用了停-等的工作方式，即发送文本服务器，然后等待响应。当然这段等待的时间，包含 RTT (Round-Trip Time, 往返时间) 以及服务器的处理时间。现在假设 RTT 为 8 个时间单位，请求在时刻 0 发出并在时刻 3 接收，响应在时刻 4 发出并在时刻 7 收到，且忽略服务器处理时间且请求、响应大小相同。

{{< figure src="/images/unp-tcp-transmission-timeline-for-interaction-model.svg" width="92%" >}}

显然在全双工的 TCP 连接下，这将严重影响吞吐量。不过对于 Unix shell 环境下的交互式输入是合适的。

现在来看上一节使用 select 实现的 str_cli 函数，好像没什么问题了。我们现在简单的对输入输出进行重定向，即提前在文件中准备大量输入，将输入重定向到该文件，最终输出也重定向到一个文件中。

```shell
./examplecli 127.0.0.1 < in.txt > out.txt
```

对于这样的实现来说，可以批量输入，也能极大提升网络吞吐量。假设在发出一个请求后立即发送另一个请求，且直接忽略服务器进行处理的时间。可以得到如下理想的数据传输情况，其实这里我们忽略了 TCP 的拥塞控制。

{{< figure src="/images/unp-tcp-fill-the-pipeline.svg" width="92%" >}}

这里不得不提出一个问题，如果没有第 10 行，也就是请求结束，数据读入了 EOF。遗憾的是，我们将直接返回到 main 函数中，依然有数据在连接上，但我们已经不再处理数据。这也就是为什么每次重定向后，输出大小总是小于输入大小。

```shell
ls -la in.txt out.txt
```

```text
-rw-r--r-- 1 root root 7106 Feb 27 18:58 in.txt
-rw-r--r-- 1 root root 4139 Feb 27 18:58 out.txt
```

这里我们需要一种关闭 TCP 写半部，即向服务器发送 FIN 告知数据已完毕，但仍保持套接字描述符打开已便读取响应。

另外，缓冲区的引入将导致程序复杂性的提升，比如说批量输入时，stdin 将之后的数据写入了输入缓冲区，等待读取这些缓冲区的数据，但 select 不这么想，它并不从 stdin 的缓冲区的角度出发。如果我们在自己写的函数中使用缓冲区，则需要考虑调用 select 之前，缓冲区中是否有等待消费的数据。

回到批量输入的问题，重新修改 str_cli 来解决这个问题，并使用 iseof 变量来判断是否读取到文件结尾，确定是否需要发送 FIN 进入连接的半关闭状态，而不是直接关闭连接从而丢失掉一部分数据。

```c
void str_cli(FILE *fp, int sockfd) {
    fd_set rset;
    FD_ZERO(&rset);
    bool iseof = false;
    int nfds = max(sockfd, fileno(fp)) + 1;
    int fpfd = fileno(fp);
    char buffer[MAXLINE] = {0};
    while (true) {
	if (!iseof) {
	    FD_SET(fpfd, &rset);
	}
	FD_SET(sockfd, &rset);
	select(nfds, &rset, NULL, NULL, NULL);
	int n;
	if (FD_ISSET(sockfd, &rset)) {
	    // socket is readable
	    if ((n = read(sockfd, buffer, MAXLINE)) == 0) {
		if (iseof) {
		    return; // normal termination
		} else {
		    err_quit("str_cli: server terminated prematurely");
		}
	    }
	    write(fileno(stdout), buffer, n);
	}
	if (FD_ISSET(fpfd, &rset)) {
	    // input is readable
	    if ((n = read(fpfd, buffer, MAXLINE)) == 0) {
		iseof = true;
		shutdown(sockfd, SHUT_WR);
		FD_CLR(fpfd, &rset);
		continue;
	    }
	    write(sockfd, buffer, n);
	}
    }
}
```


## poll 函数 {#poll-函数}

poll 函数起源于 SVR3，最初限制在流描述符，SVR4 取消了限制，允许工作在任何描述符上。poll 与 select 类似，不过处理流描述符时能够提供额外信息。

```c
// poll.h
int poll(struct pollfd *fds, nfds_t nfds, int timeout);
// return count of ready descriptors, 0 on timeout, -1 on error
```


### poll 参数与返回值 {#poll-参数与返回值}

-   参数 fds

    fds 是一个 pollfd 结构数组，是进程感兴趣的描述符集合，其中每一个元素表示的是感兴趣描述符以及其行为
    ```c
    struct pollfd {
      int   fd;
      short events;   // events of interest on fd
      short revents;  // events that occurred on fd
    };
    ```
    测试条件由 events 成员指定，函数在相应的 revents 成员中返回相应的状态，另外这些值可以以逻辑组合的形式传递给 poll 或读取

    | 值         | events | revents | 说明         |
    |-----------|--------|---------|------------|
    | POLLIN     | YES    | YES     | 普通或优先级带数据可读 |
    | POLLRDNORM | YES    | YES     | 普通数据可读 |
    | POLLRDBAND | YES    | YES     | 优先级数据可读 |
    | POLLPRI    | YES    | YES     | 高优先级数据可读 |
    | POLLOUT    | YES    | YES     | 普通数据可写 |
    | POLLWRNORM | YES    | YES     | 普通数据可写 |
    | POLLWRBAND | YES    | YES     | 优先级数据可写 |
    | POLLERR    | NO     | YES     | 发生错误     |
    | POLLHUP    | NO     | YES     | 发生阻塞     |
    | POLLNVAL   | NO     | YES     | 描述符不是一个打开的文件 |

    poll 可以识别并处理 **普通** (normal)、**优先级带** (priority band) 和 **高优先级** (high priority) 数据 (术语出自基于流的实现)。另外 `POLLIN` 与 `POLLOUT`
    自 SVR3 实现存在，早于 SVR4 中的优先级带，这两个值的出现是历史因素。

    就 TCP 与 UDP 套接字而言，以下条件会引起 poll 返回特定的 revent

    -   所有正规 TCP 数据和所有 UDP 数据都被认为是普通数据
    -   TCP 的带外数据被认为是优先级带数据
    -   TCP 连接读半关闭时 (收到对端 FIN)，被认为是普通数据，随后的读操作将返回 0
    -   TCP 连接存在错误既可认为是普通数据也可认为是错误 (POLLERR)，无论那种情况，随后的读操作返回 -1 并设置 errno
    -   监听套接字上有新连接即可认为是普通数据 (绝大多数实现)，也可认为是优先级数据
    -   非阻塞式 connect 完成被认为是使相应的套接字可写

-   参数 nfds 表示数组的长度，即数组中元素个数

    该参数在历史上常被定义为 unsigned long，有可能过分大了，Unix 98 为该参数定义为 nfds_t，该类型常常被定义为 unsigned int

-   参数 timeout 指定超时时间，单位为 ms (millisecond)

    | timeout | 说明       |
    |---------|----------|
    | INFTIM  | 永远等待   |
    | 0       | 立即返回，不阻塞进程 |
    | 正值    | 等待指定的毫秒 |

    另外需要说明的一点，INFTIM 常常被定义为一个负值，POSIX 规范要求 INFTIM 定义于 poll.h 中，而许多系统将其定义在 `sys/stropts.h` 中。

-   poll 返回值

    与 select 返回一致，唯一的区别是，就绪的描述符将修改结构中的 revents 为非零值，告知其就绪状态。在不关心数组中的某个描述符时，可以将其 fd 设置为负值，
    poll 将忽略这个元素。


### poll 示例：TCP Echo 服务器 {#poll-示例-tcp-echo-服务器}

现在想想使用 poll 来修改之前 select 的实现

```c
#include <stdbool.h>  // true
#include "unp.h"

int main(int argc, char **argv) {
    int listenfd = socket(AF_INET, SOCK_STREAM, 0);
    struct sockaddr_in servaddr = {
	.sin_family = AF_INET,
	.sin_addr.s_addr = htonl(INADDR_ANY),
	.sin_port = htons(7),
    };
    const socklen_t addrlen = sizeof(servaddr);
    bind(listenfd, (struct sockaddr *) &servaddr, addrlen);
    listen(listenfd, LISTENQ);
    struct pollfd clients[LISTENQ];
    memset(clients, 0, sizeof(clients));
    clients[0].fd = listenfd;
    clients[0].events = POLLRDNORM;
    int maxi = 0;
    struct sockaddr_in cliaddr;
    char buffer[MAXLINE] = {0};
    while (true) {
	int nready = poll(clients, maxi + 1, INFTIM);
	int connfd;
	if (clients[0].revents & POLLRDNORM) {
	    connfd = accept(listenfd, (struct sockaddr *) &cliaddr, &addrlen);
	    int i;
	    for (i = 1; i < LISTENQ; i++) {
		if (clients[i].fd <= 0) {
		    clients[i].fd = connfd;
		    clients[i].events = POLLRDNORM;
		    break;
		}
	    }
	    if (i == LISTENQ) {
		err_quit("too many clients");
	    }
	    if (i > maxi) {
		maxi = i;
	    }
	    if (--nready <= 0) {
		continue;
	    }
	}
	for (int i = 1; i <= maxi; i++) {
	    if ((connfd = clients[i].fd) <= 0) {
		continue;
	    }
	    int n;
	    if (clients[i].revents & (POLLRDNORM | POLLERR)) {
		if ((n = read(connfd, buffer, MAXLINE)) < 0) {
		    if (errno == ECONNRESET) {
			close(connfd);
			clients[i].fd = -1;
		    } else {
			err_sys("read error");
		    }
		} else if (n == 0) {
		    close(connfd);
		    clients[i].fd = -1;
		} else {
		    write(connfd, buffer, n);
		}
		if (--nready <= 0) {
		    break;
		}
	    }
	}
    }
}
```


## epoll 函数 {#epoll-函数}

epoll 是 Linux 内核在 2.5.44 扩展的 I/O 事件通知机制，主要为了取代 select 与
poll，在大量操作文件描述符时为发挥更优异的性能。select 与 poll 的时间复杂度为
\\(\mathcal{O}(N)\\) ，而 epoll 由于使用红黑树结构，时间复杂度可以做到
\\(\mathcal{O}(\log N)\\) 。另外 select 与 poll 都是将整个描述符集在内核与进程之间拷贝，而 epoll 在这方面也有所改进。


### epoll APIs {#epoll-apis}

epoll 将各个功能拆分到了不同 API 中，将描述符检测与传递监听描述符拆分为了讲个函数，以此减少每次都要在调用时传递描述符集的拷贝消耗。


#### epoll_create {#epoll-create}

```c
// sys/epoll.h
int epoll_create(int size);
// return a epoll file descriptor, -1 on error
```

该函数用于在内核中创建一个 epoll 实例并返回一个 epoll 描述符，这个描述符可以理解为实例的唯一地址，在之后需要使用到该集合时就要用到该描述符。

最初时参数 size 指示需要监听的描述符的数量，超过 size 时内核会自动扩容。如今
size 不再有此语义，但调用时必须传递大于 0 的 size 来保证向后兼容性。

该函数有一个变种

```c
// sys/epoll.h
int epoll_create1(int flag);
// return a epoll file descriptor, -1 on error
```

如果 flag 为 0 则与 `epoll_create` 行为相同，只是删除了过时的参数 size。或者传入参数 **EPOLL_CLOEXEC** 来取得不同的行为：为新的文件描述符添加 `close-on-exec`
(**FD_CLOEXEC**) 标记，该标记与 `open` 函数的标记 **O_CLOEXEC** 相同。


#### epoll_ctl {#epoll-ctl}

```c
// sys/epoll.h
int epoll_ctl(int epfd, int op, int fd, struct epoll_event *event);
// return 0 if OK, -1 on error
```

该函数对内核 epoll 实例进行监听描述符的添加、修改、删除操作。

-   参数 op 对描述符的操作，可选值为 `EPOLL_CTL_ADD` (添加描述符)、
    `EPOLL_CTL_MOD` (修改描述符) 以及 `EPOLL_CTL_DEL` (删除描述符)
-   参数 event 对描述符所作出的具体监听行为，与 pollfd 中的 event 类似，events
    是针对文件描述符的事件掩码
    ```c
    typedef union epoll_data {
      void        *ptr;
      int          fd;
      uint32_t     u32;
      uint64_t     u64;
    } epoll_data_t;
    struct epoll_event {
      uint32_t     events;  // Epoll events
      epoll_data_t data;    // User data variable
    };
    ```
    在每次对描述符进行操作时，都需要设置 epoll_data_t 中的 fd 字段。epoll 中的事件可以取得如下值

    | 值             | 内核版本 | 说明                | 返回   |
    |---------------|------|-------------------|------|
    | EPOLLIN        |        | 文件描述符可读      |        |
    | EPOLLOUT       |        | 文件描述符可写      |        |
    | EPOLLRDHUP     | 2.6.17 | 流套接字写半部关闭  |        |
    | EPOLLPRI       |        | 文件描述符存在异常，同 POLLPRI |        |
    | EPOLLERR       |        | 文件描述符发生错误  | ALWAYS |
    | EPOLLHUP       |        | 文件描述符发生终止  | ALWAYS |
    | EPOLLET        |        | 监听采用边缘触发模式 | NEVER  |
    | EPOLLONESHOT   | 2.6.2  | 文件描述符的一次性通知 | NEVER  |
    | EPOLLWAKEUP    | 3.5    | 直到下次监听期间，视为正在处理 | NEVER  |
    | EPOLLEXCLUSIVE | 4.5    | 文件描述符采用独占唤醒模式 | NEVER  |

这里单独说一下几个事件

-   `EPOLLONESHOT`: 即一次性通知，事件可用并通知后，将会被修改为禁止状态，也就是不再关心该描述符的事件，但 epoll 实例并没有删除该描述符，如果需要继续监听描述符需要以 `EPOLL_CTL_MOD` 来修改时间掩码
-   `EPOLLEXCLUSIVE`: 即独占通知，主要应用在多个 epoll 实例监听同一个描述符时，该描述符在多个 epoll 实例中必须都设置 EPOLLEXCLUSIVE 才能实现独占，没有设置该掩码的 epoll 实例依然可以监听并返回事件，而设置了该掩码的多个 epoll 实例至少有一个通知该描述符发生事件。

    另外需要注意的是，该掩码可以和 `EPOLLIN` 、 `EPOLLOUT` 、 `EPOLLWAKEUP` 和
    `EPOLLET` 一起使用，指定其他非 ALWAYS 值会出现 **EINVAL** 错误。且该掩码只能用于 `EPOLL_CTL_ADD` 操作，该描述符的后续修改操作同样会引起 **EINVAL** 错误。

`EPOLLET` 将在下面的 [epoll 工作模式](#epoll-工作模式) 中讲解，而 `EPOLLWAKEUP` 鄙人不是很理解。


#### epoll_wait {#epoll-wait}

```c
// sys/epoll.h
int epoll_wait(int epfd, struct epoll_event *events, int maxevents, int timeout);
// positive count of ready descriptors, 0 on timeout, -1 on error
```

`epoll_wait` 是真正等待事件发生的 API，与之前的 poll 和 select 一样，timeout 是超时函数，但单位为毫秒 (millisecond)，0 ms 意味着立即返回，-1 则可以让 epoll 永远阻塞，直到以下三种情况之一发生 (当然第三种不会发生)

-   有监听的描述符发生了监听事件
-   信号中断，返回 **EINTR** 错误
-   超时

参数 maxevents 指示的是最多返回的已准备套接字的数量，也就是说返回值并不会大于
maxevents，且该参数必须大于 0，否则返回 **EINVAL** 错误。

参数 events，有点迷惑的是其 data 字段，其 events 字段表示了描述符相应因为何种事件准备就绪。因此该参数是一个 struct epoll_event 数组，用来承接描述符状态的。


### epoll 工作模式 {#epoll-工作模式}

epoll 提供了 **边沿触发** (edge triggered, ET) 与 **水平触发** (level triggered, LT)
两种模式，默认情况下是水平触发模式。

ET 模式下 epoll_wait 仅会在新的事件首次被加入 epoll 队列时返回；而 LT 模式下，
epoll_wait 在事件状态未变更前将不断被触发。

-   以读事件为例，LT 模式下如果事件未被处理，该事件对应的读缓冲区非空，每次调用
    `epoll_wait` 返回时都会包括该事件，直到事件缓冲区为空位置；ET 模式下，事件只会通知一次，不会反复通知
-   以写事件为例，LT 模式下只要写缓冲区未满，就会一直通知可写；ET 模式下，内核写缓冲区由满变为未满的情况下，只会通知一次可写事件

水平触发与边沿触发这两个术语来自中断。`水平触发` 也称状态触发，当设备希望发送中断信号时，驱动中断请求线路置相应电位，并在 CPU 发出强制停止命令或处理所请求的中断事件之前始终保持。持续保持中断也就对应了 LT 模式下事件发生就会一直返回，直到处理。`边沿触发` 系统中，中断设备向中断线路发送一个脉冲来表示其中断请求，脉冲可以为上升沿或下降沿，当发送完脉冲后立即释放中断线路。

ET 模式使得程序有可能在用户态缓存 I/O 状态，以下情况下推荐使用 ET 模式

-   read 或 write 系统调用返回了 **EAGAIN**
-   非阻塞的文件描述符

但是 ET 模式也有其缺陷

1.  如果 I/O 缓冲区很大，需要很久才能将其一次读完，这可能导致饥饿。比如说，一个描述符上有大量输入，由于 ET 只会通知一次，因此程序往往希望一次将其读完，这样在源源不断的输入流上，其他描述符可能感到饥饿。可以采用就绪队列，将事件发生的描述符在就绪队列中标记，采用 **Round-robin** (循环 / 轮转) 处理就绪队列中的文件描述符。
2.  如果 A 事件的发生让程序关闭了另一个描述符 B，那么 epoll 实例并不知道，需要手动删除描述符。


### epoll 示例 {#epoll-示例}


#### epoll: Manual Example {#epoll-manual-example}

在示例中，监听者是非阻塞套接字，函数 `do_use_fd()` 使用新的就绪文件描述符，直到
read / write 返回 EAGAIN 为止。事件驱动的状态机程序在 EAGAIN 发生后应记录当前状态，以便下次调用 `do_use_fd` 时从停止位置继续读写。

```c
#define MAX_EVENTS 10
struct epoll_event ev, events[MAX_EVENTS];
int listen_sock, conn_sock, nfds, epollfd;

/* Code to set up listening socket, 'listen_sock',
   (socket(), bind(), listen()) omitted. */

epollfd = epoll_create1(0);
if (epollfd == -1) {
    perror("epoll_create1");
    exit(EXIT_FAILURE);
}

ev.events = EPOLLIN;
ev.data.fd = listen_sock;
if (epoll_ctl(epollfd, EPOLL_CTL_ADD, listen_sock, &ev) == -1) {
    perror("epoll_ctl: listen_sock");
    exit(EXIT_FAILURE);
}

while (true) {
    nfds = epoll_wait(epollfd, events, MAX_EVENTS, -1);
    if (nfds == -1) {
	perror("epoll_wait");
	exit(EXIT_FAILURE);
    }

    for (n = 0; n < nfds; ++n) {
	if (events[n].data.fd == listen_sock) {
	    conn_sock = accept(listen_sock,
			       (struct sockaddr *) &addr, &addrlen);
	    if (conn_sock == -1) {
		perror("accept");
		exit(EXIT_FAILURE);
	    }
	    setnonblocking(conn_sock);
	    ev.events = EPOLLIN | EPOLLET;
	    ev.data.fd = conn_sock;
	    if (epoll_ctl(epollfd, EPOLL_CTL_ADD, conn_sock,
			  &ev) == -1) {
		perror("epoll_ctl: conn_sock");
		exit(EXIT_FAILURE);
	    }
	} else {
	    do_use_fd(events[n].data.fd);
	}
    }
}
```


#### epoll: TCP echo server {#epoll-tcp-echo-server}

又双叒叕重写 TCP echo server，本次使用 epoll LT 模式实现

```c
#include <stdbool.h>
#include <sys/epoll.h>
#include "unp.h"

#define MAX_EVENTS 1024

int main(int argc, char **argv) {
    int listenfd = socket(AF_INET, SOCK_STREAM, 0);
    struct sockaddr_in servaddr = {
	.sin_family = AF_INET,
	.sin_addr.s_addr = htonl(INADDR_ANY),
	.sin_port = htons(7),
    };
    const socklen_t addrlen = sizeof(servaddr);
    bind(listenfd, (struct sockaddr *) &servaddr, addrlen);
    listen(listenfd, LISTENQ);
    int epollfd = epoll_create1(0);
    struct epoll_event ev = {
	.events = EPOLLIN,
	.data = {
	    .fd = listenfd,
	},
    };
    epoll_ctl(epollfd, EPOLL_CTL_ADD, listenfd, &ev);
    struct epoll_event events[MAX_EVENTS];
    struct sockaddr_in cliaddr;
    char buffer[MAXLINE] = {0};
    while (true) {
	int nready = epoll_wait(epollfd, events, MAX_EVENTS, -1);
	for (int i = 0; i < nready; i++) {
	    if (events[i].data.fd == listenfd) {
		int connfd = accept(listenfd, (struct sockaddr *) &cliaddr, &addrlen);
		ev.events = EPOLLIN;
		ev.data.fd = connfd;
		epoll_ctl(epollfd, EPOLL_CTL_ADD, connfd, &ev);
	    } else {
		int n;
		if ((n = read(events[i].data.fd, buffer, MAXLINE)) < 0) {
		    if (errno == ECONNRESET) {
			close(events[i].data.fd);
			epoll_ctl(epollfd, EPOLL_CTL_DEL, events[i].data.fd, &ev);
		    } else {
			err_sys("read error");
		    }
		} else if (n == 0) {
		    close(events[i].data.fd);
		    epoll_ctl(epollfd, EPOLL_CTL_DEL, events[i].data.fd, &ev);
		} else {
		    write(events[i].data.fd, buffer, n);
		}
	    }
	}
    }
}
```


## POXIS 变种 {#poxis-变种}


### pselect 函数 {#pselect-函数}

pselect 是 POSIX.1-2001 函数，原型如下

```c
// sys/select.h
// sys/time.h
// sys/types.h
// unistd.h
int pselect(int nfds, fd_set *readfds, fd_set *writefds,
	    fd_set *exceptfds, const struct timespec *timeout,
	    const sigset_t *sigmask);
// return count of ready descriptors, 0 on timeout, -1 on error
```

pselect 与 select 函数有两处不同

-   将系统定时器结构 timeval 换成了 POSIX 定时器结构 timespec，timespec 使用了更精细的纳秒字段 tv_nsec 而非微秒字段 tv_usec。另外由于 timeout 使用 const 修饰，不会在返回时修改为剩余时间
    ```c
    struct timespec {
      time_t tv_sec;  // seconds
      long tv_nsec;   // nanoseconds
    };
    ```

-   信号掩码 (sigmask)，将信号掩码保存并设置为指定的 sigmask，返回时恢复之前的信号掩码，信号掩码将屏蔽其中的信号。如果将其设置为 NULL，则信号方面与 select
    行为一致


### ppoll 函数 {#ppoll-函数}

ppoll 是 poll 的仿 POSIX 变种，而非 POSIX 规范的函数，因此该函数需要得到系统的支持

-   FreeBSD 11.0
-   OpenBSD 5.4
-   Linux 2.6.16
-   glibc 2.4

函数原型如下

```c
// sys/poll.h
// sys/time.h
// sys/types.h
int ppoll(struct pollfd *fds, nfds_t nfds,
	  const struct timespec *timeout, const sigset_t *sigmask);
// return count of ready descriptors, 0 on timeout, -1 on error
```

ppoll 参数 fds 与 nfds 与 poll 一致，参数 timeout 与 sigmask 与 pselect 一致
