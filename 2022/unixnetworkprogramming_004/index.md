# 基本 TCP 编程


## 基本 TCP 套接字函数 {#基本-tcp-套接字函数}

{{< figure src="/images/unp-socket-functions-for-elementary-tcp-client-and-server.svg" width="40%" >}}


### socket 函数 {#socket-函数}

在网络编程中第一步往往调用 socket 函数，以指定通讯协议的详情。

```c
// sys/socket.h
int socket(int domain, int type, int protocol);
// return socket fd, or -1 and set errno on error
```

domain 指协议族，type 是套接字类型，protocol 参数应该设置为某个协议类型常量，或者为 0 表示对 domain 与 type 的系统默认值。

-   domain
    -   `AF_INET`: IPv4 协议
    -   `AF_INET6`: IPv6 协议
    -   `AF_UNIX` or `AF_LOCAL`: Unix Domain Socket
    -   `AF_ROUTE`: 路由套接字
    -   `AF_KEY`: 密钥套接字
-   type
    -   `SOCK_STREAM`: 字节流套接字
    -   `SOCK_DGRAM`: 数据报套接字
    -   `SOCK_SEQPACKET`: 有序分组套接字
    -   `SOCK_RAW`: 原始套接字
-   protocol (for IPv4 and IPv6)
    -   `IPPROTO_TCP`
    -   `IPPROTO_UDP`
    -   `IPPROTO_SCTP`

需要注意的是，不是所有的组合都是有效的，下表总结了有效的 socket 函数参数组合，空白意味着无效。

|                | AF_INET     | AF_INET6    | AF_LOCAL | AF_ROUTE | AF_KEY |
|----------------|-------------|-------------|----------|----------|--------|
| SOCK_STREAM    | TCP or SCTP | TCP or SCTP | YES      |          |        |
| SOCK_DGRAM     | UDP         | UDP         | YES      |          |        |
| SOCK_SEQPACKET | SCTP        | SCTP        | YES      |          |        |
| SOCK_RAM       | IPv4        | IPv6        |          | YES      | YES    |

参数 domain 与 type 还有一些其他值，必须 4.4BSD 支持的 AF_NS (Xerox NS protocols
or XNS) 和 AF_ISO (OSI protocols)，而 Linux 表述了 SOCK_PACKET 这样的 type 参数来表示 BPF 类似的协议。AF_KEY 采用内核中密钥表的接口来实现的加密的。

另外说一下 AF 是 Adress Family 的缩写，而 PF 是 protocol family 的缩写，由于历史原因：单个 PF 可以支持多个 AF，但这从未实现过，因此在一些实现中 PF_xxx 总与
AF_xxx 相等。


### connect 函数 {#connect-函数}

connect 函数被用于 TCP 客户端与服务端之间建立连接。

```c
// sys/socket.h
int connect(int sockfd, const struct sockaddr *addr, socklen_t addrlen);
// return 0 if OK, -1 on error
```

sockfd 是由 socket 函数成功调用时返回的套接字文件描述符，addr 是上一篇讲解过的通用套接字地址结构，最后的参数 addrlen 则是对 addr 取 sizeof 所得的大小。

客户端无需在 connect 之前调用 bind 来绑定端口，在需要时 OS 会选择一个临时端口与服务端进行通信。对于 TCP socket 来说，connect 函数会初始化三次握手，在返回时连接是建立完成的，或建立失败。我们可以从 errno 中获取一些出错原因：

1.  TCP 客户端没有收到 SYN-ACK 响应，返回 **ETIMEDOUT** 错误。比如 4.4BSD 上的客户端发送 SYN 后，分别在无响应 6s、24s 后再发送一个 SYN 请求，总计 75s 仍无响应则返回该错误
2.  TCP 服务端对 SYN 响应 RST (复位)，表明主机在端口上没有等待连接的进程，这是一个 **硬错误** (hard error)，在收到 RST 后立即返回 **ECONNREFUSED** 错误
3.  若 TCP 发送 SYN 请求时，链路上某个路由发生 `destination unreachable` (目的地址不可达) 的 ICMP 错误，则认为是 **软错误** (soft error)。内核将保留消息并按第一种错误的时间间隔重新发送请求，仍未响应的情况下返回 **EHOSTUNREACH** 或
    **ENETUNREACH** 错误

从 TCP 状态转换图来看，connect 函数将状态从 CLOSED 转移到 SYN_SENT，若成功则转移到 ESTABLISHED；失败时该套接字不可再次 connect，需要调用 close 函数关闭套接字文件描述符，然后重新调用 socket 创建新的套接字。


### bind 函数 {#bind-函数}

bind 函数将协议地址与一个套接字文件描述符进行绑定。bind 原型与 connect 类似。

```c
// sys/socket.h
int bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen);
// return 0 if OK, -1 on error
```

对于 TCP 套接字，bind 可以指定端口号或 IP 地址，或两者都指定，也可以两者都不指定

-   TCP 如果没有经过 bind 就调用 connect 或 listen 时，内核会为其绑定一个临时端口
-   TCP 可以 bind 一个属于主机的网络接口之一的 IP 地址，对于客户端来说这是个源
    IP 地址，而对服务端来说，这限定了只接收哪些目的地址的 IP。通常客户端不会绑定
    IP，由内核根据外出网络接口决定源 IP 地址；服务器没有绑定 IP 时，内核会把客户发送 SYN 的目的地址作为服务器的源 IP 地址

下表总结了 bind 对于 ip 与 port 指定或不指定时的结果

| 指定 IP 地址 | 指定 port | 结果              |
|----------|---------|-----------------|
| 通配地址 | 0       | 内核选择 IP 与 port |
| 通配地址 | 非 0    | 内核选择 IP，进程指定 port |
| 本地 IP 地址 | 0       | 内核选择 port，进程指定 IP |
| 本地 IP 地址 | 非 0    | 进程指定 IP 和 port |

对于 IPv4 来说，通配地址通常使用 **INADDR_ANY** 来指定，其值一般为 0 (0.0.0.0)，而
IPv6 中使用结构变量 **in6addr_any**。

```c
// IPv4
struct sockaddr_in addr4 = {
  .sin_addr = htonl(INADDR_ANY),
};
// IPv6
struct sockaddr_in6 addr6 = {
  .sin6_addr = in6addr_any,
};
```

在不指定端口时，bind 并无法获取分配的临时端口，需要调用函数 `getsockname` 来获取。

bind 常见的错误是 **EADDRINUSE** (Address already in use)，这在以后再详细说明。


### listen 函数 {#listen-函数}

在 TCP 服务器中需要调用 listen 函数，这个函数会完成以下两个行为：

1.  当套接字通过 socket 函数创建时，一般认为这是个主动连接套接字，也就是给客户端调用 connect 函数的。而 listen 可以将其转变为未连接的被动套接字，内核将连接进来的请求直接连接到这个套接字上。也就是说，在状态转换图上看，listen 将状态从 CLOSED 转换到 LISTEN
2.  第二个参数往往指定内核开放的该套接字的连接队列的大小

<!--listend-->

```c
// sys/socket.h
int listen(int sockfd, int backlog);
// return 0 if OK, -1 on error
```

通常情况下 listen 在 socket 和 bind 之后调用，在 accept 之前调用。为了明白参数
backlog，需要认识到内核会为 TCP 连接维护两个队列：

1.  接入队列，或者称半连接队列，这是 TCP 服务器接收到 SYN 请求并发送 SYN-ACK 后等待第三次握手时，所建立的客户端套接字队列
2.  完成队列，这个队列中包含了完成三次握手的客户端套接字，这些套接字都是
    ESTABLISHED 状态

{{< figure src="/images/unp-the-two-queues-maintained-by-tcp-listening.svg" width="64%" >}}

当请求接入后，系统将自动地创建新连接并将监听的套接字信息复制到连接中，整个过程是自动化的，无需 server 进程插手。在 server 进行 SYN-ACK 回复后状态变为 SYN_RCVD，将连接放入半连接队列等待客户端回应。如果客户端连接超时则会将其从半连接队列中删除，连接完成后进入 ESTABLISHED 状态，并将该连接从半连接队列移至完成队列的末尾，等待
accept 将其取出进行通信。

关于这两个队列，需要考虑以下几点：

-   listen 的第二个参数 backlog 基于历史原因，是指定两个队列的总和的最大值。在
    4.2BSD 帮助手册上定义其为 `the maximum length the queue of pending
        connections may grow to` (等待的连接队列的最大可增长长度)，不过没有定义什么是等待的连接，是 SYN_RCVD 还是 ESTABLISHED 或者两者都是
-   基于 Berkeley 的实现为 backlog 增添了模糊因子 (fudge factor)，最终结果为
    backlog 乘以 **1.5**
-   不要将 backlog 设置为 0，在不同的实现上对此解释也不同，如果不想接收连接就直接关闭监听连接
-   在指定 backlog 时可以设置为比内核支持的最大值还要大的值，内核往往会将其改为自身支持的最大值而非返回错误
-   Linux 帮助手册的 NOTES 部分解释了 Linux 上 backlog 的实现行为，自 Linux 2.2
    开始该参数指定的是完成队列的最大大小，即 ESTABLISHED 状态的连接队列。半连接状态队列大小可以通过 `/proc/sys/net/ipv4/tcp_max_syn_backlog` 进行修改，而
    backlog 的最大值在 `/proc/sys/net/core/somaxconn` 中，通常为 128
-   当队列满时，一个 SYN 请求到达时 TCP 将会忽略该请求而非 RST。这是因为过满的情况是暂时的，重传 SYN 时期望可以找到可用空间，而返回 RST 会终止正常的 TCP 重传机制，还会让客户端无法区分错误
-   三次握手完成后，在服务器调用 accept 之前到达的数据由服务器 TCP 进行排队，最大数据量为相应已连接套接字的接收缓冲区大小

下表是 unp 给出的各个操作系统下，backlog 参数取不同值时已排队连接的实际数目。可以看到 AIX 与 MacOS 遵循传统的 Berkeley 算法，Solaris 也有类似的算法，而 FreeBSD
则是 backlog 值 \\(+1\\)。

| backlog | MaxOS 10.2.6 / AIX 5.1 | Linux 2.4.7 | HP-UX 11.11 | FreeBSD 5.1 | Solaris 2.9 |
|---------|------------------------|-------------|-------------|-------------|-------------|
| 0       | 1                      | 3           | 1           | 1           | 1           |
| 1       | 2                      | 4           | 1           | 2           | 2           |
| 2       | 4                      | 5           | 3           | 3           | 4           |
| 3       | 5                      | 6           | 4           | 4           | 5           |
| 4       | 7                      | 7           | 6           | 5           | 6           |
| 5       | 8                      | 8           | 7           | 6           | 8           |
| 6       | 10                     | 9           | 9           | 7           | 10          |
| 7       | 11                     | 10          | 10          | 8           | 11          |
| 8       | 13                     | 11          | 12          | 9           | 13          |
| 9       | 14                     | 12          | 13          | 10          | 14          |
| 10      | 16                     | 13          | 15          | 11          | 16          |
| 11      | 17                     | 14          | 16          | 12          | 17          |
| 12      | 19                     | 15          | 18          | 13          | 19          |
| 13      | 20                     | 16          | 19          | 14          | 20          |
| 14      | 22                     | 17          | 21          | 15          | 22          |


### accept 函数 {#accept-函数}

accept 是 TCP 服务端在 listen 之后的需要调用的函数，该函数返回一个完成队列中的连接，如果完成队列为空，则会阻塞服务器进程。

```c
// sys/socket.h
int accept(int sockfd, struct sockaddr *cliaddr, socklen_t *addrlen);
// return non-negative descriptor if OK, -1 on error
```

参数 cliaddr 与 addrlen 是结果参数，调用时，将 addrlen 设置为 cliaddr 的套接字地址结构长度；返回时，该整数被内核设置为结构的确切字节值。如果对客户端的地址不感兴趣，可以将这两个参数在调用时设置为 `NULL`。成功时返回值是内核自动生成的一个套接字描述符，这是与其连接的客户端的描述符。

想想第一篇的时间获取客户端，这里给出该客户端对应的时间获取服务端，以这个程序作为例子讲解。

```c
// 以下代码与 UNP intro/daytimetcpsrv1.c 等价
#include <stdarg.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

// inet_pton/3, htons/1
#include <arpa/inet.h>

// struct sockaddr_in
#include <netinet/in.h>

// errno
#include <errno.h>

// socket/3, connect/3
#include <sys/socket.h>
#include <sys/types.h>

// read/3
#include <unistd.h>

#define MAXLINE 4096
#define LISTENQ 1024

void err_sys(const char* fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  char buffer[MAXLINE + 1] = {0};
  vsnprintf(buffer, MAXLINE, fmt, ap);
  int n = strlen(buffer);
  snprintf(buffer + n, MAXLINE - n, ":%s", strerror(errno));
  strcat(buffer, "\n");
  fflush(stdout);
  fputs(buffer, stderr);
  fflush(stderr);
  va_end(ap);
  exit(1);
}

void err_msg(const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  char buffer[MAXLINE + 1] = {0};
  vsnprintf(buffer, MAXLINE, fmt, ap);
  strcat(buffer, "\n");
  fflush(stdout);
  fputs(buffer, stderr);
  fflush(stderr);
  va_end(ap);
}

int main(int argc, char **argv) {
  int listenfd;
  if ((listenfd = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
    err_sys("socket error");
  }
  struct sockaddr_in servaddr = {
    .sin_family = AF_INET,
    .sin_addr.s_addr = htonl(INADDR_ANY),
    .sin_port = htons(13),
  };
  if (bind(listenfd, (struct sockaddr *) &servaddr, sizeof(servaddr)) < 0) {
    err_sys("socket error");
  }
  if (listen(listenfd, LISTENQ) < 0) {
    err_sys("socket error");
  }
  while (true) {
    struct sockaddr_in cliaddr;
    int len = sizeof(cliaddr);
    int connfd;
    if ((connfd = accept(listenfd, (struct sockaddr *) &cliaddr, &len)) < 0) {
      err_msg("accept error");
      continue;
    }
    char buffer[MAXLINE] = {0};
    printf("connection from %s, port %d\n",
           inet_ntop(AF_INET, &cliaddr.sin_addr, buffer, INET_ADDRSTRLEN),
           ntohs(cliaddr.sin_port));
    time_t ticks = time(NULL);
    snprintf(buffer, sizeof(buffer), "%.24s\r\n", ctime(&ticks));
    if (write(connfd, buffer, strlen(buffer)) < 0) {
      err_msg("write error");
    }
    close(connfd);
  }
}
```

在我的本地，编译该文件，用 daytimetcpcli 请求时间，服务器输出如下

<div class="verse">

connection from 127.0.0.1, port 49736<br />
connection from 192.168.0.105, port 53886<br />

</div>

与之前的客户端程序很相似，需要注意的是，程序一次调用 socket、bind、listen，之后在一个无限循环中调用 accept 接收请求，并在每次请求完成后，关闭与客户端的连接，进行下一次请求。


## 并发服务器 {#并发服务器}

现在的服务端程序可以很好的运行，但是只能一次接受一个请求，如果请求很多且单次请求处理时间较长时，显然是不能满足及时响应客户请求的。于此，一个简单的方式诞生了，即创建一个新的进程，在这个新进程中处理请求，而老进程的任务变为接收请求并启动新进。这样每次有新请求时，都会开启一个新进程来处理，老进程可以继续无间断的接受新请求。


### fork {#fork}

在 Unix 操作系统中，有一个简单启动新进程的方式，即 **fork**

```c
// unistd.h
pid_t fork(void);
// return 0 in child, process ID of child in parent, -1 on error
```

fork 是一个启动新进程的方式，该 syscall 会复制一份一模一样的进程环境作为新进程，新进程被称作子进程 (child process)，而老进程称为父进程 (parent process)。fork 在
parent 与 child 中都有返回值，child 中 fork 返回 0 表示调用成功，而 parent 中返回的是 child 的进程 ID (pid)，在不同的进程中不同的返回值可以让程序员知道当前身处哪个进程。fork 是比较特殊的函数，由于其创建新进程和两个不同的返回值的特性，需要特别注意。

首先介绍下 fork 的两个典型用法：

1.  创建自身进程的副本，每个副本都可以执行不同的操作，即网络服务器的典型操作
2.  一个进程想要执行另一个程序，先创建一个副本，再通过副本调用其他 syscall (后面讲到的 exec) 替换为新的程序，这是 shell 程序的典型用法

<!--listend-->

```c
// example
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <unistd.h>  // fork, getpid, getppid

#define MAXLINE 1024

int main (void) {
  pid_t ppid = getppid();  // 获取该进程的父进程 ID
  pid_t pid = getpid();    // 获取该进程的 ID
  char buffer[MAXLINE] = {0};
  pid_t id = fork();
  // 拷贝进程副本，即所有全局变量，与以上的所有变量、数据都被拷贝到新的进程
  if (id == 0) {
    // 当前分支由子进程执行
    // ppid 与 pid 为副本存在于子进程中，值目前为止没有改变
    strcat(buffer, "new process");
    printf("in %s, ppid: %d, pid: %d\n", buffer, ppid, pid);
    // 修改 ppid 与 pid 的值，不影响父进程中的结果
    pid = getpid();    // 获取当前进程的 ID，即子进程的 ID
    ppid = getppid();  // 获取当前进程的父进程 ID，即父进程的 ID
    printf("in %s, ppid: %d, pid: %d\n", buffer, ppid, pid);
  } else if (id > 0) {
    // 当前分支由父进程执行，id 值为子进程的值
    strcat(buffer, "old process");
    printf("in %s, ppid: %d, pid: %d\n", buffer, ppid, pid);
    // 由于在父进程中，重新获取后值应该不变
    pid = getpid();    // 获取当前进程的 ID，即子进程的 ID
    ppid = getppid();  // 获取当前进程的父进程 ID，即父进程的 ID
    // 子进程 ID 是 fork 为父进程返回的值
    printf("in %s, ppid: %d, pid: %d, spid: %d\n", buffer, ppid, pid, id);
  } else {
    perror("fork error\n");
    exit(EXIT_FAILURE);
  }
  // 因为分支结束，这里是所有分支都会执行的代码，即子进程、父进程都会执行
  printf("in %s, end\n", buffer);
  return 0;
}
```

上述程序可能的输出

<div class="verse">

in old process, ppid: 17081, pid: 17975<br />
in old process, ppid: 17081, pid: 17975, spid: 17976<br />
in old process, end<br />
in new process, ppid: 17081, pid: 17975<br />
in new process, ppid: 17975, pid: 17976<br />
in new process, end<br />

</div>

或

<div class="verse">

in old process, ppid: 17081, pid: 17961<br />
in old process, ppid: 17081, pid: 17961, spid: 17962<br />
in old process, end<br />
in new process, ppid: 17081, pid: 17961<br />
in new process, ppid: 1, pid: 17962<br />
in new process, end<br />

</div>

可以看到可能的输出中，子进程可能的父进程 ID 变为了 1，这是由于父进程在子进程之前结束生命周期，导致子进程成为孤儿进程，该进程由 init 进程 (id: 1) 收养所导致的子进程父进程变为 1。如果不希望这种事情发生，可以在父进程中使用 `wait` 或 `waitpid`
等待子进程结束，这在以后的 APUE 笔记中介绍。


### exec {#exec}

存放在硬盘中的可执行文件能够被 Unix 执行的唯一方法是：由一个现有进程调用 syscall
exec 系列函数中的一个 (共 6 个，这些函数被统称为 exec)，exec 可以将当前进程映像替换为新的进程文件，从新进程的 main 函数开始执行，而进程的 ID 不会改变。通常称调用 exec 的进程为 **调用进程** (calling process)，而新执行的程序称为 **新程序** (new
program)。

6 个 exec 函数分为三种

1.  待执行的程序文件是由文件名 (filename) 还是路径名 (pathname) 指定
2.  新程序的参数是一一列出还是指针数组引用
3.  调用进程的环境进行传递还是指定新环境

<!--listend-->

```c
// unistd.h
int execlp(const char *file, const char *arg, ... /* (char  *) NULL */);
int execl(const char *path, const char *arg, ... /* (char  *) NULL */);
int execvp(const char *file, char *const argv[]);
int execv(const char *path, char *const argv[]);
int execle(const char *path, const char *arg, ... /*, (char *) NULL, char * const envp[] */);
int execve(const char *file, char *const argv[], char *const envp[]);
// return -1 on error, no return on success
```

这些函数只有错误时才返回到调用者，否则将从新程序的起始点 (通常为 main) 开始。一般 execve 是 syscall，而其他 5 个是调用 execve 的库函数，glibc 扩展了一个与
execve 的库函数 execvpe，检测宏为 **\_GNU_SOURCE**。

{{< figure src="/images/unp-relationship-between-exec-family-functions.svg" width="90%" >}}

需要注意几点：

-   execl、execlp、execle 三个参数将程序的每个字符串参数作为独立的参数传递给
    exec，并以 NULL 作为程序参数结束的标志。而 execvp、execv、execve 三个参数将程序的字符串参数作为参数数组 argv 的一部分进行传递，由于没有传递该数组的长度，因此约定 argv 的末尾必须含有空指针 NULL 来标记结尾。
-   最左侧的 execlp 与 execvp 两个函数指定的是 file，exec 函数将当前的环境变量
    PATH 作为查找程序的依据。但如果 file 参数字符串中存在 `/`，则在当前程序的工作目录 (workpath) 中查找程序，而非 PATH 环境变量中。
-   execl、execlp、execv、execvp 四个函数均不指定环境变量，因此使用外部变量
    **environ** (man 7) 作为环境变量列表。execle 与 execve 使用用户指定的环境变量列表，同 argv 一样，需要用户传递的 envp 也以 NULL 结尾。
-   通常进程打开的所有文件描述符，在 exec 切换程序后都会保留，继续打开。可以通过
    fcntl 设置 FD_CLOEXEC 来禁止该默认行为。


### getsockname 和 getpeername {#getsockname-和-getpeername}

这两个函数与某个套接字关联的本端协议地址 (getsockname) 或对端协议地址
(getpeername) 相关的操作。

```c
// sys/socket.h
int getsockname(int sockfd, struct sockaddr *addr, socklen_t *addrlen);
int getpeername(int sockfd, struct sockaddr *addr, socklen_t *addrlen);
// return 0 if OK, -1 on error
```

简单的说就是用来获取已知套接字描述符，但不知道地址结构的套接字，具体用法如下：

-   在 TCP 客户端 connect 成功返回后，使用 `getsockname` 获取内核赋予的本地 IP
    地址与本地端口号
-   在以端口号为 0 或通配 IP 地址 (INADDR_ANY) 的 bind 调用，使用 `getsockname`
    获取内核赋予的端口号或 IP (查看 IP 时需要使用 accept 返回的 connfd)
-   `getsockname` 可以获取某个套接字的协议族 (AF)
-   在子进程中执行了 exec 操作时，仅可知已连接的客户端的套接字描述符 (其依然保持打开状态)，需要获取客户端 IP 与端口需要使用 `getpeername`

在最后一个用法中，需要注意 exec 之后的程序映像，需要获取 connfd 的值，而不是凭空出现 connfd 的值。常用的方式是作为程序的字符串参数进行传递，或约定特定描述符的
ID，也可以修改环境变量传递。


### 时间获取服务的并发示例 {#时间获取服务的并发示例}

在上面 accept 函数中给出了一个时间获取服务器的代码，这个服务器的实现是一连接一处理的方式，通常称其为 **迭代服务器** (iterative server)。缺点也说过了，对于处理时间较长且请求较多的场景下，是无法接受的，希望服务器可以同时服务更多用户。因此 Unix
环境下最简单的方式就是 fork 和 exec syscall，在子进程中处理请求，父进程只做监听、接收请求的操作。这种模型也就是 **并发服务器** (concurrent server)。

```c
// function main in daytimetcpsrv1.c
int listenfd = socket(AF_INET, SOCK_STREAM, 0);
struct sockaddr_in servaddr = {
  .sin_family = AF_INET,
  .sin_addr.s_addr = htonl(INADDR_ANY),
  .sin_port = htons(13),
};
bind(listenfd, (struct sockaddr *) &servaddr, sizeof(servaddr));
listen(listenfd, LISTENQ);
while (true) {
  struct sockaddr_in cliaddr;
  int len = sizeof(cliaddr);
  int connfd = accept(listenfd, (struct sockaddr *) &cliaddr, &len);
  char buffer[MAXLINE] = {0};
  pid_t pid;
  if ((pid = fork()) == 0) {
    // in child process
    close(listenfd);     // child closes listening socket
    dosomething();       // process the request
    close(connfd);       // done with this client
    exit(EXIT_SUCCESS);  // child terminates
  }
  close(connfd);  // parent closes connected socket
}
```

当连接建立时，accept 返回，此时服务器调用 fork 来创建新进程，listenfd (服务器的监听套接字) 和 connfd (客户端的请求套接字) 都会以副本的形式保留在新进程中，子进程不应该继续打开 listenfd，而父进程应该关闭 connfd。父进程就可以监听 listenfd 从而等待下一个客户端请求的到来，子进程只需要专心为以获取到的 connfd 工作。这就是一个简易的并发服务器模型。

这里有一个问题，close 套接字描述符时不是会导致该连接关闭，为什么子进程还可以正确处理客户端的请求？

每个文件描述符都是引用计数的，系统会维护一个打开的描述符列表，打开文件时会将对应的描述符引用计数 \\(+1\\)，而关闭时会将引用计数 \\(-1\\)，只有引用计数为 \\(0\\) 时系统才会真正的关闭这个文件。换到这里，accept 导致 connfd \\(+1\\)，而 fork 拷贝副本会导致
listenfd 与 connfd 再次 \\(+1\\) 从而值为 2，父进程关闭 connfd 不会使其引用计数为 0，这就是不会导致提前回收 connfd 的原因。真正回收 connfd 是在子进程调用 close 或结束时。


## TCP Echo 服务 {#tcp-echo-服务}

Echo 服务器是一种简单且基础的 TCP 服务，默认服务端口 7，支持 TCP 与 UDP 服务。
Echo 服务会将客户端发送的数据完全返回，即请求数据就是响应数据。不过 echo 服务有着正常网络应用该有的一切，如果可以在其基础上，将它修改为需要的网络服务应用。echo
与之前介绍的 daytime 服务不同，daytime 服务由服务器主动断开，而 echo 服务由客户端断开，服务端一直保持连接，客户端主动断开而断开连接。

在以后的代码中不会出现诸如 `err_sys` 之类的错误处理函数的原型，而是用 `unp.h` 替代。


### TCP Echo 服务器 {#tcp-echo-服务器}

这里直接展示一个 Echo 服务器的程序代码，相对于以前的代码来说，并没有太大的改动。这里将 `str_echo` 修改为其他行为就可以作为其他网络服务器使用。

```c
#include "unp.h"

int main(void) {
  int listenfd;
  if ((listenfd = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
    err_sys("socket error");
  }
  struct sockaddr_in servaddr = {
    .sin_family = AF_INET,
    .sin_addr.s_addr = htonl(INADDR_ANY),
    .sin_port = htons(7),
  };
  if (bind(listenfd, (struct sockaddr *) &servaddr, sizeof(servaddr)) < 0) {
    err_sys("socket error");
  }
  if (listen(listenfd, LISTENQ) < 0) {
    err_sys("socket error");
  }
  while (true) {
    struct sockaddr_in cliaddr;
    int cliaddrlen = sizeof(cliaddr);
    int connfd;
    if ((connfd = accept(listenfd, (struct sockaddr *) &cliaddr, &cliaddrlen)) < 0) {
      err_msg("accept error");
      continue;
    }
    pid_t pid;
    if ((pid = fork()) == 0) {
      close(listenfd);
      str_echo(connfd);
      exit(EXIT_SUCCESS);
    }
    close(connfd);
  }
}
```

上面的模板没什么看得，下来好好说一下 echo 服务中的 str_echo，str_echo 只会做一个简单的事：读出客户端的数据并将其重新写回客户端。简单的方式就是，用 read 函数读出数据，再用 write 函数写回即可。但是需要注意的是，这里服务器不会主动断开，而是一直接受客户端的请求并回射，直到被动断开。

```c
void str_echo(int connfd) {
  size_t cnt;
  char buffer[MAXLINE] = {0};
  while ((cnt = read(connfd, buffer, MAXLINE)) > 0) {
    write(connfd, buffer, cnt);
  }
  if (cnt < 0 && errno == EINTR) {
    return str_echo(connfd);
  } else if (cnt < 0) {
    err_sys("str_echo: read error");
  }
}
```


### TCP Echo 客户端 {#tcp-echo-客户端}

对于客户端来说，main 函数一样是模板

```c
#include "unp.h"

int main(int argc, char **argv) {
  if (argc != 2) {
    err_quit("usage: tcpcli <IPaddress>");
  }
  int sockfd;
  if ((sockfd = socket(AF_INET, SOCK_STREAM, NULL)) < 0) {
    err_sys("socket error");
  }
  struct sockaddr_in servaddr = {
    .sin_family = AF_INET,
    .sin_port = htons(7),
  };
  if (inet_pton(AF_INET, argv[1], &servaddr.sin_addr) < 0) {
    err_sys("inet_pton error");
  }
  if (connect(sockfd, (struct sockaddr *) &servaddr, sizeof(servaddr)) < 0) {
    err_sys("connect error");
  }
  str_cli(stdin, sockfd);
}
```

`str_cli` 可以理解为 `dosomething` 函数，这里是做所有请求的函数。该函数只做了一件事，循环从标准输入读入一行文本，写入到服务器，等待服务器回射响应，再将结果写入标准输出。

```c
void str_cli(FILE *fp, int sockfd) {
  char sendline[MAXLINE] = {0}, recvline[MAXLINE] = {0};
  FILE *sockfd_fp = fdopen(sockfd, "r+");
  while (fgets(sendline, MAXLINE, fp) != NULL) {
    if (fputs(sendline, sockfd_fp) == EOF) {
      err_quit("str_cli: stop input");
    }
    if (fgets(recvline, MAXLINE, sockfd_fp) == NULL) {
      err_quit("str_cli: server terminated prematurely");
    }
    fputs(recvline, stdout);
    bzero(sendline, MAXLINE);
    bzero(recvline, MAXLINE);
  }
}
```


### echo 服务端的启动与终止 {#echo-服务端的启动与终止}


#### 启动 {#启动}

对于一般程序而言，在命令行中输入程序名称即可运行程序，但对于服务端这样的程序，需要一直运行，但当前终端我们可能需要做其他一些事情，不能一直让服务端占据，可以使用后台启动的方式 (即 fork 到子进程中启动) 运行。

```shell
./examplesrv &
```

服务器启动后，调用 socket、bind、listen 和 accept，并阻塞于 accept。使用 lsof 命令可以看到 7 号端口的使用信息

```shell
lsof -i :7
```

```text
COMMAND     PID    USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
examplesr 20246    root    3u  IPv4 802379      0t0  TCP *:echo (LISTEN)
```

当然也可以使用 netstat 检查服务器监听套接字的状态

```shell
netstat -a
```

```text
Active Internet connections (servers and established)
Proto Recv-Q Send-Q Local Address           Foreign Address         State
tcp        0      0 0.0.0.0:echo            0.0.0.0:*               LISTEN
```

`*` 或 `0.0.0.0` 来表示通配地址，netstat 中 `:*` 表示了为 0 的端口号。这时候启动客户端并指定服务器地址为 127.0.0.1

```shell
./examplecli 127.0.0.1
```

客户端启动后通过 socket、connect 建立起连接，服务器上 accept 返回，客户端上
connect 返回，连接建立完成，客户端进入 fgets，等待用户输入，服务器子进程被 read
阻塞等待客户输入，父进程则会再次进入 accept 阻塞等待新的连接到来。

此时启动了一个客户端一个服务端，再次通过 netstat 查看网络信息

```shell
netstat -a
```

```text
Active Internet connections (servers and established)
Proto Recv-Q Send-Q Local Address           Foreign Address         State
tcp        0      0 0.0.0.0:echo            0.0.0.0:*               LISTEN
tcp        0      0 GinShio:echo            GinShio:32996           ESTABLISHED
tcp        0      0 GinShio:32996           GinShio:echo            ESTABLISHED
```

可以清楚的看到，由父进程进行的 LISTEN 状态的 sockfd，子进程与客户端在 echo (7)
和 32996 端口建立起了连接，其中 32996 是客户端由系统自动分配的端口。这是再开启一个通过 wlan0 (无线网卡) 连接的客户端，可以得到如下的输出。可以看到有一个地址
192.168.0.0/24 的地址建立起了连接，这两个不同的连接可以同时工作，当然，还可以添加不同的客户端。

```text
Active Internet connections (servers and established)
Proto Recv-Q Send-Q Local Address           Foreign Address         State
tcp        0      0 0.0.0.0:echo            0.0.0.0:*               LISTEN
tcp        0      0 192.168.0.105:46956     192.168.0.105:echo      ESTABLISHED
tcp        0      0 192.168.0.105:echo      192.168.0.105:46956     ESTABLISHED
tcp        0      0 GinShio:echo            GinShio:32996           ESTABLISHED
tcp        0      0 GinShio:32996           GinShio:echo            ESTABLISHED
```

还可以通过 ps 命令来查看进程的状态与关系。我这里查看到服务端在 `pts/4` 上启动，而本地客户端在 `pts/5` 上，wlan0 客户端在 `pts/6` 上，通过以下 ps 命令查看

```shell
# pts/4
ps -t pts/4 -o pid,ppid,tty,stat,args,wchan
```

```text
  PID  PPID TT       STAT COMMAND                     WCHAN
19195 19144 pts/4    Ss+  /bin/zsh                    -
20235 19195 pts/4    S    sudo ./examplesrv           -
20246 20235 pts/4    S    ./examplesrv                -
20254 20246 pts/4    S    ./examplesrv                -
20256 20246 pts/4    S    ./examplesrv                -
```

```shell
# pts/5
ps -t pts/5 -o pid,ppid,tty,stat,args,wchan
```

```text
  PID  PPID TT       STAT COMMAND                     WCHAN
19236 19144 pts/5    Ss   /bin/zsh                    -
20253 19236 pts/5    S+   ./examplecli 127.0.0.1      -
```

```shell
# pts/6
ps -t pts/6 -o pid,ppid,tty,stat,args,wchan
```

```text
  PID  PPID TT       STAT COMMAND                     WCHAN
19277 19144 pts/6    Ss   /bin/zsh                    -
20255 19277 pts/6    S+   ./examplecli 192.168.0.105  -
```

可以看到所有的进程的 STAT 都是 S，表明进程因等待某些资源而阻塞。


#### 终止 {#终止}

客户端程序在处理时，使用 fgets 读入标准输入的数据，当标准输入中输入 EOF
(end-of-file) 字符时 fgets 将返回 NULL，由此可以终止客户端的输入，从而终止客户端程序。在 Unix 系统终端上，Control-D (`^D`) 即输入 EOF 字符。

终止客户端时，可能在 netstat 看到如下输出

```text
Active Internet connections (servers and established)
Proto Recv-Q Send-Q Local Address           Foreign Address         State
tcp        0      0 0.0.0.0:echo            0.0.0.0:*               LISTEN
tcp        0      0 192.168.0.105:46956     192.168.0.105:echo      TIME_WAIT
tcp        0      0 GinShio:echo            GinShio:32996           ESTABLISHED
tcp        0      0 GinShio:32996           GinShio:echo            ESTABLISHED
```

客户端在结束输入之后关闭套接字描述符，这导致 TCP 客户端向服务端发送一个 FIN，处于 FIN_WAIT_2 状态，服务端响应 ACK，处于 CLOSE_WAIT 状态。服务端从 str_echo 返回子进程的主函数，通过 exit 终止，打开的套接字描述符关闭，从而发送 FIN 到客户端，并接收客户端发送的 ACK，连接终止，客户端套接字进入 TIME_WAIT 状态。

另外进程终止时，会向父进程发送一个 **SIGCHLD** 信号，服务端代码并没有捕获该代码进行处理，也没有使用 wait 进行处理，从而父进程默认忽略该信号。由于父进程的忽略，子进程进入僵尸状态，在 ps 上显示状态为 Z。

```shell
ps -t pts/4 -o pid,ppid,tty,stat,args,wchan
```

```text
  PID  PPID TT       STAT COMMAND                     WCHAN
19195 19144 pts/4    Ss+  /bin/zsh                    -
20235 19195 pts/4    S    sudo ./examplesrv           -
20246 20235 pts/4    S    ./examplesrv                -
20254 20246 pts/4    S    ./examplesrv                -
20256 20246 pts/4    Z    [examplesrv] <defunct>      -
```

在 Unix 系统上，这种父进程没有处理回收的进程就是僵尸进程，系统不会释放其占用的资源。当僵尸进程过多时，系统就会出现问题，如进程号不足、内存不足等问题。因此需要及时清理，另外当父进程死亡时，僵尸子进程被过继到 init 进程，此时 init 进程会将负责僵尸进程的资源回收工作。

如果想主动终止服务端进程，可以使用 kill 命令对进程发送相应的信号，以此来终止进程。此时服务器就会作为连接的主动关闭方。


## POSIX 信号处理 {#posix-信号处理}

信号 (signal) 就是告知某个进程发生某事的通知，或称为 **软件中断** (software
interrupt)，signal 发生通常是 **异步** 的，信号由内核发送或一个进程向另一个进程发送。每个信号都有一个与之关联的 **处置** (disposition) 或称为 **行为** (action)，处理
sigaction 来设定一个信号的处理，并有三种选择

1.  提供回调函数，在特定信号发生时进行回调。这个函数被称为 **信号处理函数**
    (signal handler)，这种行为也被称为 **捕获** (catching) 信号。其中信号
    `SIGKILL` 与 `SIGSTOP` 不能被捕获。signal handler 原型如下
    ```c
    void handler(int signo);
    ```
2.  将信号设置为 `SIG_IGN` 对信号进行忽略，当然 SIGKILL 与 SIGSTOP 不能被忽略
3.  将信号设置为 `SIG_DFL` 进行默认处理


### 信号 {#信号}

信号的默认行为首先有以下几个大类：

Term (终止)
: 信号发生时终止进程

Ign (忽略)
: 信号发生时进程忽略该信号

Core (内存映像)
: 信号发生时终止进程并生成内存映像

Stop (停止)
: 信号发生时停止进程

Cont (继续)
: 如果进程已停止，信号发生时继续进程

现在说说都有哪些 POSIX 信号吧

| Signal    | Standard     | Value    | Action | Comment                     |
|-----------|--------------|----------|--------|-----------------------------|
| SIGHUP    | POSIX.1-1990 | 1        | Term   | 终端结束时，通知进程不再与终端关联 |
| SIGINT    | POSIX.1-1990 | 2        | Term   | 通过热键终止进程 (C-c)      |
| SIGQUIT   | POSIX.1-1990 | 3        | Core   | 通过热键终止进程并产生内存映像 (C-\\) |
| SIGILL    | POSIX.1-1990 | 4        | Core   | 执行了非法指令              |
| SIGTRAP   | POSIX.1-2001 | 5        | Core   | 追踪 / 断点陷阱             |
| SIGABRT   | POSIX.1-1990 | 6        | Core   | 调用 abort(3) 产生的信号    |
| SIGFPE    | POSIX.1-1990 | 8        | Core   | 浮点数异常                  |
| SIGKILL   | POSIX.1-1990 | 9        | Term   | 终结进程                    |
| SIGBUS    | POSIX.1-2001 | 10,7,10  | Core   | 总线错误 (内存错误)         |
| SIGSEGV   | POSIX.1-1990 | 11       | Core   | 无效内存引用                |
| SIGSYS    | POSIX.1-2001 | 12,31,12 | Core   | 错误系统调用，见 seccomp(2) |
| SIGPIPE   | POSIX.1-1990 | 13       | Term   | 管道破裂：写入无读者管道，见 pipe(7) |
| SIGALRM   | POSIX.1-1990 | 14       | Term   | 时钟信号，见 alarm(2)       |
| SIGTERM   | POSIX.1-1990 | 15       | Term   | 可捕获终止信号，要求程序自己正常退出 |
| SIGURG    | POSIX.1-2001 | 16,23,21 | Ign    | 套接字紧急情况              |
| SIGSTOP   | POSIX.1-1990 | 17,19,23 | Stop   | 停止进程，不可被忽略或处理  |
| SIGTSTP   | POSIX.1-1990 | 18,20,24 | Stop   | 停止进程，可以被忽略或处理  |
| SIGCONT   | POSIX.1-1990 | 19,18,25 | Cont   | 停止时继续进程              |
| SIGCHLD   | POSIX.1-1990 | 20,17,18 | Ign    | 子进程停止或终止            |
| SIGTTIN   | POSIX.1-1990 | 21,21,26 | Stop   | 后台进程等待用户从终端输入  |
| SIGTTOU   | POSIX.1-1990 | 22,22,27 | Stop   | 后台进程等待写入终端        |
| SIGXCPU   | POSIX.1-2001 | 24,24,30 | Core   | 超过 CPU 时间限制, 见 setrlimit(2) |
| SIGXFSZ   | POSIX.1-2001 | 25,25,21 | Core   | 超过文件大小限制, 见 setrlimit(2) |
| SIGVTALRM | POSIX.1-2001 | 26,26,28 | Term   | 虚拟计时器时钟              |
| SIGPROF   | POSIX.1-2001 | 27,27,29 | Term   | 分析计时器过期              |
| SIGUSR1   | POSIX.1-1990 | 30,10,16 | Term   | 用户自定义 1 号信号         |
| SIGUSR2   | POSIX.1-1990 | 31,12,17 | Term   | 用户自定义 2 号信号         |
| SIGPOLL   | POSIX.1-2001 |          | Term   | 可轮询事件，等价于 SIGIO    |

有些信号的值可能有多个，这是由于不同架构对于信号的定义不同产生的，通常来说，第一列是 Alpha / SPARC，第二列是 x86 / ARM 或其他架构，第三列是 MIPS 架构。对应的值为 `-` 时表示该架构下没有此信号。

当然除了 POSIX 信号，在 Linux 的 **signal(7)** 用户手册中还可以找到以下信号

| Signal    | Value    | Action | Comment               |
|-----------|----------|--------|-----------------------|
| SIGIOT    | 6        | Core   | IOT 陷阱，等价于 SIGABRT |
| SIGEMT    | 7,-,7    | Term   | 模拟器陷阱 (Emulator trap) |
| SIGSTKFLT | -,16,-   | Term   | 协处理器上的堆栈错误 (unused) |
| SIGIO     | 23,29,22 | Term   | 当前 IO 可用          |
| SIGCLD    | -,-,18   | Ign    | 等价于 SIGCHLD        |
| SIGPWR    | 29,30,19 | Term   | 断电信号              |
| SIGINFO   | 29,-,-   |        | 等同于 SIGPWR         |
| SIGLOST   | -,-,-    | Term   | 文件锁丢失 (unused)   |
| SIGWINCH  | 28,28,20 | Ign    | 窗口缩放信号          |
| SIGUNUSED | -,31,-   | Core   | 等同于 SIGSYS         |


### 信号处理 {#信号处理}

对信号处理的方式相对简单，即调用 POSIX 方法 sigaction，但是相对复杂的是需要分配并填写相关结构。有一个相对简单的方式即 **signal** 函数，第一个参数是信号名，第二个参数就是指向回调函数的指针，或者宏定义 `SIG_IGN` 或 `SIG_DFL`。

signal 函数的原型很复杂，不简化时是这个样子

```c
void (*signal(int signum, void (*handler)(int))) (int);
```

首先其参数为信号名 signo 与回调函数 handler，这个函数类型为无返回值的单参数为
int 的函数指针，signal 函数最终也返回这样的一个函数指针。简化如下

```c
// signal.h
typedef void (*sighandler_t)(int);
sighandler_t signal(int signum, sighandler_t handler);
```

捕获信号成功时将返回该处理函数，而失败时会返回常量 `SIG_ERR`。

现在回过头来看一看 POSIX 函数 sigaction

```c
// signal.h
int sigaction(int signum, const struct sigaction *act, struct sigaction *oldact);
// return 0 if OK, -1 on error
```

说实话 sigaction 虽然麻烦但是函数原型好看很多。act 即将要修改的信号的新行为，
oldact 会将旧行为用参数 oldact 返回给用户。

再来看看 sigaction 核心的 struct sigaction

```c
struct sigaction {
  void     (*sa_handler)(int);
  void     (*sa_sigaction)(int, siginfo_t *, void *);
  sigset_t   sa_mask;
  int        sa_flags;
  void     (*sa_restorer)(void);
};
```

-   sa_handler 即信号处理函数，用法同 signal 中的 handler
-   sa_sigaction 同样也是信号处理函数
-   sa_mask 指定需要阻塞的信号集，即捕获发生时将其进行屏蔽
-   sa_flags 指定修改信号行为的选项集合，不过其很复杂，常用的一些选项如下
    -   SA_NODEFER: 在自己的信号处理内不对该信号做屏蔽
    -   SA_RESETHAND: 执行信号处理函数后，将信号操作恢复默认值
    -   SA_RESTART: 通过使某些系统调用可跨信号重新启动，提供与 BSD 信号语义兼容的行为。简单解释就是由信号中断的系统调用由内核自动重启
    -   SA_INTERRUPT: 与 SA_RESTART 互补的操作，信号中断的系统调用不会自动重启
    -   SA_SIGINFO: 提供附加信息，信号捕获行为由 sa_handler 改为 sa_sigaction。
        struct siginfo_t 是一个复杂的结构，提供了大量字段来描述相关信息，过于复杂暂时不做讨论

这里简单的使用 signal 处理一下之前提到的子进程资源回收的问题。在父进程中，我们应该实现针对 SIGCHLD 的回调函数，在该回调事件中，信号 SIGCHLD 发生时应在父进程内调用 wait 函数用以等待子进程结束并清理资源。

```c
void sig_chld(int signo) {
  int stat;
  pid_t pid = wait(&stat);
  printf("child %d terminated", pid);
}
```

对于这个回调函数非常简单，也能达到我们的目的：清理终止的子进程所占用的资源。当然需要一个合适的位置来调用 signal 注册这个行为，只要在 main 函数的 while 循环之前注册都行，只需要简单的添加一句 `signal(SIGCHLD, sig_chld);` 即可。

当然你会发现这是不行的，因为这里有一个 **慢系统调用** (slow system call)，即系统调用阻塞进程后不保证返回，服务端中典型的慢系统调用是 accept，当无客户连接时，主进程将永远阻塞在 accept。当进程阻塞在慢系统调用中，捕获信号并在相应行为返回后，这个系统调用可能返回一个 EINTR 错误，或者有些实现中会自动重启被中断的系统调用。因此为了方便在 POSIX 系统之间移植，对慢系统调用的 EINTR 错误处理很重要。

可以将符合 POSIX 的系统上的信号处理总结为以下几点

-   一旦注册了信号处理函数，该行为将一直存在于进程中
-   在一个信号处理函数运行期间，正在被捕获的信号是阻塞的，sigaction 中的 sa_mask
    信号集在此时也是阻塞的
-   如果信号在阻塞期间产生了一次或多次，那么该信号在唤醒后仅被提交一次，也就是说
    Unix 信号默认是不排队的
-   sigprocmask 函数可以选择性地阻塞或唤醒一组信号


## 意外情况下的程序终止 {#意外情况下的程序终止}

-   accept 函数返回前连接终止

    即服务器准备从内核取出连接并处理，但连接中断，收到客户端发送的 RST 请求。这种情况依赖于实现，Berkeley 实现完全在内核中处理中止连接，服务器进程无法看到；
    SVR4 实现大多返回错误给进程，一些 SVR4 实现返回 EPROTO (protocol error)，但
    POSIX 支持必须返回 ECONNABORTED 错误，因为在某些流子系统中发生某些致命的协议相关事件时也会返回 EPROTO，服务器可能无法分辨这些错误。因此为了让服务器可以忽略该非致命性错误，从而继续调用 accept。

-   SIGPIPE 信号

    当客户端 read 返回错误时，客户不理会而是继续写入更多数据，会发生什么？这是内核默认发送一个 SIGPIPE 信号，无论是否捕获或忽略该信号，read 都将返回一个
    EPIPE 错误。

    将客户端 str_cli 稍加修改，就可以观察到 SIGPIPE 的行为：改为两次调用 write，第一次将文本数据第一个字节写入，引发 RST，暂停 1s 后进行第二次写入，将产生
    SIGPIPE。
    ```c
    void str_cli(FILE *fp, int sockfd) {
      char sendline[MAXLINE] = {0}, recvline[MAXLINE] = {0};
      while (fgets(sendline, MAXLINE, fp) != NULL) {
        write(sockfd, sendline, 1);
        sleep(1);
        write(sockfd, sendline + 1, strlen(sendline) - 1);
        if (fgets(recvline, MAXLINE, sockfd_fp) == NULL) {
          err_quit("str_cli: server terminated prematurely");
        }
        fputs(recvline, stdout);
        bzero(sendline, MAXLINE);
        bzero(recvline, MAXLINE);
      }
    }
    ```
    处理 SIGPIPE 信号取决于发生时进程想做什么，如果没有特殊的事则直接忽略，并在后续的操作中检查 EPIPE 错误并终止。

-   服务器主机崩溃

    在服务器主机崩溃时，已有的连接上无法发送数据。客户端为连接写入数据，并阻塞于
    read 操作等待服务器响应，服务器不会对任何请求进行响应，从而 TCP 连接请求超时，客户端会收到 ETIMEDOUT 错误；如果在某个中间路由上检测到服务器不可达，则会返回 "destination unreachable" (目的地不可达) 的 ICMP 消息，并返回
    EHOSTUNREACH 或 ENETUNREACH 错误。

-   服务器主机崩溃后重启

    服务器主机崩溃，上一点简单的描述了崩溃没有恢复的情况，现在讨论一下服务器主机恢复的情况。

    此时客户端发送请求到服务器上，由于已崩溃重启，客户端并不知道服务器有重启，但服务器并没有客户端的连接相关数据，此时客户端 TCP 收到 RST，read 调用返回
    ECONNRESET 错误。

-   服务器主机关机

    当 Unix 系统关机时，init 进程会给所有进程发送 SIGTERM 信号，并等待一段时间
    (一般是 5 ~ 20 秒)，然后对仍在运行的进程发送 SIGKILL 信号。这么做是为了让进程得知将要关机，而捕获 SIGTERM 信号做相关的数据保存工作，相应的 SIGKILL 则是强制所有进程结束，进入关机状态。之后的情况与服务端主动断开类似。

