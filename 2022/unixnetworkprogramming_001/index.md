# UNP 简介


{{< admonition type="info" >}}
关于 UNP 的所有代码可以在 <https://github.com/unpbook/unpv13e> 上找到
{{< /admonition >}}


## 从一个简单的时间获取客户端开始 {#从一个简单的时间获取客户端开始}

接下来，将从一个使用 TCP 连接的获取时间的客户端开始。

```c
// 以下代码与 UNP intro/daytimetcpcli.c 等价
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

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

void err_quit(const char* fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  char buffer[MAXLINE + 1] = {0};
  vsnprintf(buffer, MAXLINE, fmt, ap);
  strcat(buffer, "\n");
  fflush(stdout);
  fputs(buffer, stderr);
  fflush(stderr);
  va_end(ap);
  exit(1);
}

int main(int argc, char** argv) {
  if (argc != 2) {
    err_quit("usage: a.out <IPaddress>");
  }
  int sockfd;
  if ((sockfd = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
    err_sys("socket error");
  }
  struct sockaddr_in servaddr = {
    .sin_family = AF_INET,
    .sin_port = htons(13),
  };
  if (inet_pton(AF_INET, argv[1], &servaddr.sin_addr) <= 0) {
    err_quit("inet_pton error for %s", argv[1]);
  }
  if (connect(sockfd, (struct sockaddr*) &servaddr, sizeof(servaddr)) < 0) {
    err_sys("connect error");
  }
  int n;
  char recvline[MAXLINE + 1];
  while ((n = read(sockfd, recvline, MAXLINE)) > 0) {
    recvline[n] = 0;
    if (fputs(recvline, stdout) == EOF) {
      err_sys("read error");
    }
  }
  if (n < 0) {
    err_sys("read error");
  }
  return 0;
}
```

当然需要自行编译一下 daytimetcpsrv 并启动它，然后就可以顺利启动 client 就可以看到获取的时间了。


### socket {#socket}

我们最先遇到的 API 是 `socket/3`，这会帮助我们启动一个网络服务，我们可以自己指定 **domain**, **type** ，还有一个特殊的 **protocol** 参数用于指定 socket 一起使用的特定协议，但这个参数通常情况下为 0。下表展示了常用的 domain 与 type 值，摘自
Linux Kernel 5.3.18。

| domain                | 释义                           | Manual     |
|-----------------------|------------------------------|------------|
| `AF_UNIX`, `AF_LOCAL` | Unix Domain Socket             | unix(7)    |
| `AF_INET`             | IPv4                           | ip(7)      |
| `AF_INET6`            | IPv6                           | ipv6(7)    |
| `AF_IPX`              | IPX - Novell Protocol          |            |
| `AF_NETLINK`          | Kernel user interface device   | netlink(7) |
| `AF_X25`              | ITU-T X.25 / ISO-8208 protocol | x25(7)     |
| `AF_AX25`             | Amateur radio AX.25 protocol   |            |
| `AF_ATMPVC`           | Access to raw ATM PVCs         |            |
| `AF_APPLETALK`        | AppleTalk                      | ddp(7)     |
| `AF_PACKET`           | Low level packet interface     | packet(7)  |
| `AF_ALG`              | Interface to kernel crypto API |            |

| type             | 释义                        |
|------------------|---------------------------|
| `SOCK_STREAM`    | 提供基于连接的、顺序、可靠、双工的字节流 |
| `SOCK_DGRAM`     | 提供无连接的、不可靠的数据报 |
| `SOCK_SEQPACKET` | 提供基于连接的、顺序、可靠、双工的数据报 |
| `SOCK_RAW`       | 提供原生网络协议            |
| `SOCK_RDM`       | 提供不保证顺序的可靠数据报  |
| `SOCK_PACKET`    | 见 Manual packet(7)         |
| `SOCK_NONBLOCK`  | 为新打开的 fd 设置 `O_NONBLOCK` 标志 |
| `SOCK_CLOEXEC`   | 为新打开的 fd 设置 `O_ELOEXEC` 标志 |

我们往往使用 `AF_INET` 与 `SOCK_STREAM` 来启动一个 TCP 连接。而该 API 会返回一个整数作为返回结果，成功时将返回新 socket 的文件描述符 (fd)，而失败时返回 \\(-1\\) 并设置 **errno**，而 errno 可以让我们得知具体发生了什么错误。

```c
// 构建 IPv4 socket
tcp_socket = socket(AF_INET, SOCK_STREAM, 0);
udp_socket = socket(AF_INET, SOCK_DGRAM, 0);
raw_socket = socket(AF_INET, SOCK_RAW, protocol);
// 构建 IPv6 socket
tcp6_socket = socket(AF_INET6, SOCK_STREAM, 0);
raw6_socket = socket(AF_INET6, SOCK_RAW, protocol);
udp6_socket = socket(AF_INET6, SOCK_DGRAM, protocol);
```


### 指定服务器 IP 地址与端口 {#指定服务器-ip-地址与端口}

使用 `sockaddr_in` 数据结构 (头文件 **netinet/in.h** 中) 保存服务器的 IPv4 信息，结构体如下

```c
// IPv4
struct sockaddr_in {
    sa_family_t    sin_family; /* address family: AF_INET */
    in_port_t      sin_port;   /* port in network byte order */
    struct in_addr sin_addr;   /* internet address */
};
/* Internet address. */
typedef uint32_t in_addr_t;
struct in_addr {
    in_addr_t      s_addr;     /* address in network byte order */
};

// Ipv6
struct sockaddr_in6 {
    sa_family_t     sin6_family;   /* AF_INET6 */
    in_port_t       sin6_port;     /* port number */
    uint32_t        sin6_flowinfo; /* IPv6 flow information */
    struct in6_addr sin6_addr;     /* IPv6 address */
    uint32_t        sin6_scope_id; /* Scope ID (new in 2.4) */
};

struct in6_addr {
    unsigned char   s6_addr[16];   /* IPv6 address */
};
```

另外系统使用大端序或小端序，而网络编程中往往需要使用网络序，因此提供了一系列将系统序 (host byte order) 转换为网络序 (network byte order) 的函数 (头文件
**arpa/inet.h**)，不过在有些系统中这些函数被包含在 **netinet/in.h** 中。使用这些函数就可以自由的定义端口值。

```c
uint32_t htonl(uint32_t hostlong);   // 将 unsigned int 类型 host to network
uint16_t htons(uint16_t hostshort);  // 将 unsigned short 类型 host to network
uint32_t ntohl(uint32_t netlong);    // 将 unsigned int 类型 network to host
uint16_t ntohs(uint16_t netshort);   // 将 unsigned short 类型 network to host
```

最后一个与IP信息有关的函数就是 `inet_pton/3` (presentation to numeric，头文件
**arpa/inet.h** 中)，这是一个伴随着 IPv6 诞生的 POSIX 函数，可以将 IPv4 的点分十进制字符串形式或 IPv6 的字符串行形式地址转换为 `in_addr` 或 `in6_addr` 的字节形式。这个函数会返回一个整数用来确定函数是否成功，\\(1\\) 代表了成功，而 \\(0\\) 代表没有包含有效的地址，\\(-1\\) 是最为严重的，表示不是有效的协议族，这还会将 errno 设置为
**EAFNOSUPPORT**。与这个函数相关的还有一个 `inet_ntop/4`，它与前一个函数作用相反，最后一个参数 size 则指示了 buffer 可以接收的字节大小。下面一段程序是 Manual 中给出的示例，于此贴出。

```c
#include <arpa/inet.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char *argv[]) {
    unsigned char buf[sizeof(struct in6_addr)];
    int domain, s;
    char str[INET6_ADDRSTRLEN];
    if (argc != 3) {
        fprintf(stderr, "Usage: %s {i4|i6|<num>} string\n", argv[0]);
        exit(EXIT_FAILURE);
    }
    domain = (strcmp(argv[1], "i4") == 0) ? AF_INET :
             (strcmp(argv[1], "i6") == 0) ? AF_INET6 : atoi(argv[1]);
    s = inet_pton(domain, argv[2], buf);
    if (s <= 0) {
        if (s == 0) {
            fprintf(stderr, "Not in presentation format");
        } else {
            perror("inet_pton");
        }
        exit(EXIT_FAILURE);
    }
    if (inet_ntop(domain, buf, str, INET6_ADDRSTRLEN) == NULL) {
        perror("inet_ntop");
        exit(EXIT_FAILURE);
    }
    printf("%s\n", str);
    exit(EXIT_SUCCESS);
}
// ./a.out i4 127.0.0.1
// 127.0.0.1
// ./a.out i6 0:0:0:0:0:0:0:0
// ::
// ./a.out i6 1:0:0:0:0:0:0:8
// 1::8
// ./a.out i6 0:0:0:0:0:FFFF:204.152.189.116
// ::ffff:204.152.189.116
```

以前常用的函数则是支持 IPv4 的 `inet_addr/1` 系列函数

| 函数             | 使用                                   |
|----------------|--------------------------------------|
| `inet_aton/2`    | 点分十进制地址转换为 `in_addr` 结构，成功时返回 \\(1\\) |
| `inet_addr/1`    | 点分十进制地址转换为 `in_addr` 结构，无效时返回 \\(-1\\) |
| `inet_network/1` | 与上一个函数类似，但返回的是主机序而非网络序 |
| `inet_ntoa/1`    | 将网络序的 `in_addr` 转换为点分十进制字符串 |
| `inet_lnaof/1`   | 返回 `in_addr` 地址中的主机地址部分 (主机序) |
| `inet_netof/1`   | 返回 `in_addr` 地址中的网络号部分 (主机序) |


### 与服务器建立连接并读取数据 {#与服务器建立连接并读取数据}

建立连接使用 `connect/3` 完成，先看一下函数原型

```c
// #include <sys/socket.h>
// #include <sys/types.h>
int connect(int sockfd, const struct sockaddr *addr, socklen_t addrlen);
```

该函数接收 sockfd 用于监听主机端口，并使用 addr 接收服务器的地址、端口等信息，最后一个参数则是 addr 的数据类型大小。

当然 socket 类型会影响该函数的行为：`SOCK_DGRAM` 类型的 socket，addr 是默认发送和接收数据报的地址；而 `SOCK_STREAM` 和 `SOCK_SEQPACKET` 类型的 socket，将会试图与指定地址建立连接。通常来说，基于连接的 socket 只允许调用成功一次该函数，而无连接的 socket 可以多次调用该函数来更改关联的地址，并且自 Linux Kernel 2.2 以后，可以通过连接到将 **sa_family** 设置为 `AF_UNSPEC` 来解除地址关联。

读取一个文件的数据往往采用 POSIX 函数 `read/3` ，接收 fd、buffer、接收的字节长度
size，最终会返回实际读取的字节长度，但是返回 -1 时代表发生错误并会设置
**errno**。

往往在读取服务器数据时，采用循环的方式读取，直到读到的数据大小为 0 才认为此次读取完成。虽然这个程序中每次读取都会直接读完所有数据 (因为数据只有 26 byte，而一次可以接收 4096 byte)。

在这个示例中，数据传输完成由服务器关闭连接表示，这与 **HTTP/1.0** 是类似的；而
SMTP 采用两个字节序的 ASCII 回车符后跟 ASCII 换行符表示数据结束；Sun RPC 和 DNS
则是用一个包含数据大小的字段来确定何时结束数据。这些结果的背后是 **TCP 不提供数据标记** ，你需要自己选择如何记录数据结束。


## 简单的时间获取服务端 {#简单的时间获取服务端}

这里的服务端是对应上一节中的客户端，为客户端提供获取时间的服务。

```c
// 以下代码与 UNP intro/daytimetcpsrv.c 等价
#include <stdbool.h>
#include <stdio.h>
#include <time.h>

#include <arpa/inet.h>
#include <netinet/in.h>
#include <unistd.h>

#include <sys/socket.h>
#include <sys/types.h>

#define LISTENQ 1024
#define MAXLINE 4096

int main(int argc, const char* argv[]) {
  int listenfd = socket(AF_INET, SOCK_STREAM, 0);
  if (listenfd == -1) {
    err_sys("listen error");
  }
  struct sockaddr_in servaddr = {
    .sin_family = AF_INET,
    .sin_port = htons(13),
    .sin_addr.s_addr = htonl(INADDR_ANY),
  };
  if (bind(listenfd, (struct sockaddr*) &servaddr, sizeof(servaddr)) == -1) {
    err_sys("bind error");
  }
  if (listen(listenfd, LISTENQ) == -1) {
    err_sys("listen error");
  }
  while (true) {
    int connfd = accept(listenfd, (struct sockaddr*) NULL, NULL);
    if (connfd == -1) {
      err_ret("connect error");
      continue;
    }
    time_t ticks = time(NULL);
    char buffer[MAXLINE + 1] = {0};
    snprintf(buffer, sizeof(buffer), "%.24s\r\n", ctime(&ticks));
    if (write(connfd, buffer, strlen(buffer)) == -1) {
      err_ret("write error");
    }
    if (close(connfd) == -1) {
      err_ret("close error");
    }
  }
}
```

可以看到与客户端不同的是，服务器在申请 socket 时没什么变化，但接下来服务器填写了自己的 IP 与 Port 信息，Port 用于指示接下来监听的端口，而 IP 则是指定为了
`INADDR_ANY`，这是系统中预定的 IP 地址的值。

| 定义               | 值              | 释义          |
|------------------|----------------|-------------|
| `INADDR_ANY`       | 0.0.0.0         | 接受所有 IP 发来的请求 |
| `INADDR_LOOPBACK`  | 127.0.0.1       | 本地回环地址  |
| `INADDR_BROADCAST` | 255.255.255.255 | 广播地址      |

有趣的是，如果使用 <span class="underline">INADDR_ANY</span> 的话，客户端可以使用路由器、网线提供的 DHCP 地址访问服务器，而改为 <span class="underline">INADDR_LOOPBACK</span> 时仅可通过 127.0.0.1 进行访问。当然这些数值都需要通过 `htonl/1` 转换为网络序。

可能初看时不是很理解 bind 的含义，而且这个函数和 `connect` 的参数几乎一致。不过不同的是，connect 用于客户端向服务器发起申请连接，而 DGRAM 类型则是将 fd 与 IP
信息绑定。这里 bind 也是将 IP 信息与 fd 进行绑定，根据 Manual 的解释，sockfd 申请之后存在于地址族的名称空间之中，但没有绑定地址，因此需要此函数对 fd 与 addr 进行绑定。

最后一个 `listen/2` 就是监听给出的 addr 及 port，这里的 sockfd 主要是
**SOCK_STREAM** 与 **SOCK_SEQPACKET** 类型的 socket。(`SOCK_DGRAM` 又一次被排除在外了) listen 的第二个参数，根据 Manual 的 NOTE 章节，目前版本的 Linux 代表了成功
accept 的 TCP 连接队列的长度。

在与客户端通信时，往往使用 `accept/3` 接收来自客户端的连接所创建的 connfd，经过这一步后，TCP 完成连接从而状态改变为 **ESTABLISHED**。当数据被准备好之后，服务器就可以通过 `write/3` 将数据写入 connfd 发送给客户端，这与平时向文件中写内容是类似的。最后我们只需要像关闭文件一样关闭 connfd 就可以了。

但是这个程序存在一些问题， `while (true)` 可以让服务器一直循环等待客户端请求到来，但是一次只能接收一个请求并处理，这对大量请求情况下显然是不合适的。但在示例中，我们仅使用了标准库函数 time 和 ctim，运行速度很快。但现实中我们可能需要几十秒甚至一分钟处理一个请求，这时这样的服务器是不可接受的。

示例中的服务器被称为 **迭代服务器** (iterative server)，对于每个请求都迭代执行一次；同时处理多个请求的服务器被称为 **并发服务器** (concurrent server)。而从 shell 终端启动一个服务器可能会一直运行，因此我们常常使用 Unix 守护进程 (daemon)，可以在后台运行，而不跟任何终端关联地运行。


## Unix 标准 {#unix-标准}

Unix 标准通常被称作 POSIX，即 **Portable Operating System Interface** (可移植操作系统接口)。当然由于当时有多个机构进行标准化工作，因此 Unix 标准又有很多名字
`ISO/IEC 9945`, `IEEE Std 1003.1` 和单一 Unix 规范 (Signle UNIX Specification)，当然经过发展，POSIX 也经历过版本更新，UNP 所介绍到了 POSIX.1-2001，如今最新标准为 **POSIX.1-2017**。

-   POSIX 第一版为 IEEE Std. 1003.1-1988，这一版规范了 Unix 内核的 C 语言接口，这些接口覆盖了进程原语 (fork，exec，signals 等)、进程环境 (user ID，程序组等)、文件与目录 (所有的 I/O 函数)、终端 I/O、系统数据库 (密码文件与组文件) 以及
    tar、cpio 等归档格式。不过当时 POSIX 被称为 `IEEE-IX` ，POSIX 这个名称是
    Richard Stallman 建议使用的。
-   IEEE Std. 1003.1-1990 为第二版，这一版正式称为 ISO 标准 **ISO/IEC 9945:1990**
    。这一版的改动很小，添加了新的副标题 "Part 1: System Application Program
    Interface (API) [C language]"
-   IEEE Std. 1003.2-1992 扩展到了两卷本，第二卷 "Part 2: Shell and Utilities"。这一卷定义了 shell (基于 System V Bourne Shell) 与大约 100 中命令行工具 (awk，
    vi，yacc等)，第二卷往往也被称为 **POSIX.2**
-   IEEE Std. 1003.1b-1993 升级自 1990 版，添加了 P1003.4 工作组开发的实时扩展部分，并新增了文件同步、异步 I/O、信号量、内存管理 (mmap 与共享内存)、进程调度、始终与定时器以及消息队列。
-   IEEE Std. 1003.1c-1995 又被称为 **ISO/IEC 9945-1:1996** ，包含了之前的 API、事实扩展、pthreads (1003.1c-1995) 以及对 1003.1b 的技术性修订。增添了三章关于线程的内容以及关于线程同步 (mutexes 与 condition_variables)、线程调度、线程同步以及信号句柄。将 ISO/IEC 9945 分为三部分
    -   Part 1: System API (C language) --- 被称为 POSIX.1
    -   Part 2: Shell and utilities     --- 被称为 POSIX.2
    -   Part 3: System administration (正在开发)
-   IEEE Std. 1003.1g: Protocol-independent interfaces (PII) (协议无关接口) 定义了两个 API，被称为 **Detailed Network Interfaces** (DNI，详尽网络接口)：
    -   DNI/Socket，基于 4.4BSD socket API
    -   DNI/XTI，基于 X/Open XPG4 规范

X/Open 公司与开放软件基金会 (OSF) 合并成了 The Open Group，这是一个由厂商、工业界最终用户、政府以及学术机构共同参加的标准化组织。

-   1989 年 X/Open 发布了 X/Open 可移植指南第三期 (XPG3)
-   1992 年发布了 XPG4，而第二版于 1994 年发布。这个版本也被称作 **Spec 1170** (规范 1170)，1170 是 926 个系统 API、70 个头文件 以及 174 个命令的总和。最终被称为 X/Open Signle UNIX Specification，或 **Unix 95**
-   1997 年三月发布了 Signle Unix Specification 第二版，又称为 **Unix 98** 。这一版的魔数上升到了 1434，而工作站魔数直接到了 3030。这是因为该规范包含了
    Common Desktop Environment (CDE，公共桌面环境)，这导致必须依赖 X Window
    System 以及 Motif 用户接口。

再之后，单一 UNIX 规范与 POSIX.1 逐渐统一起来，UNP 主要介绍 POSIX.1-2001 (即
IEEE Std 1003.1-2001)。

