# Unix 套接字 API


## 套接字地址数据结构 {#套接字地址数据结构}

套接字函数基本都需要一个指向套接字地址结构的指针作为参数，每个协议族都有自己的套接字定义，均以 `sockaddr_` 开头，并有协议族的唯一后缀。


### IPv4 套接字地址结构 {#ipv4-套接字地址结构}

IPv4 套接字地址结构通常称之为 **互联网套接字结构** (Internet socket address
structure)，结构体 **sockaddr_in**​，定义于 `<netinet/in.h>` 中 (POSIX)。

```c
struct in_addr {
  in_addr_t s_addr;    // 32 bit IPv4 地址 (网络序)
};
struct sockaddr_in {
  uint8_t         sin_len;      // 结构体大小
  sa_family_t     sin_family;   // AF_INET
  in_port_t       sin_port;     // 16 bit 传输层端口号 (网络序)
  struct in_addr  sin_addr;
  char            sin_zero[8];  // unused
};
```

需要注意几点：

-   长度字段 `sin_len` 是为了增加对 OSI 协议的支持而在 4.3BSD-Reno 添加的，但该字段并不是 POSIX 规范要求 (linux 实现并没有该字段)。数据类型 uint8_t 是典型符合 POSIX 系统提供的数据类型。

    | 数据类型    | 说明                     | 头文件       |
    |---------|------------------------|-----------|
    | int8_t      | 有符号 8 bit 整型        | sys/types.h  |
    | uint8_t     | 无符号 8 bit 整型        | sys/types.h  |
    | int16_t     | 有符号 16 bit 整型       | sys/types.h  |
    | uint16_t    | 无符号 16 bit 整型       | sys/types.h  |
    | int32_t     | 有符号 32 bit 整型       | sys/types.h  |
    | uint32_t    | 无符号 32 bit 整型       | sys/types.h  |
    | sa_family_t | 套接字地址结构的地址族   | sys/socket.h |
    | socklen_t   | 套接字地址结构的长度 (一般 uint32_t) | sys/socket.h |
    | in_addr_t   | IPv4 地址 (一般 uint32_t) | netinet/in.h |
    | in_port_t   | 端口号 (一般 uint16_t)   | netinet/in.h |
-   除非使用路由 socket，一般情况下无需检查或设置长度字段。

在 socket 函数中套接字地址结构总是被引用，为了增强对不同协议族的兼容性，定义了一个通用套接字地址结构来接受不同的协议族地址。当然现在可以使用 C 所提供的强制转换到 `void*` 来实现。

```c
// in <sys/socket.h>
struct sockaddr {
  uint8_t      sa_len;
  sa_family_t  sa_family;    // 协议族: AF_xxx
  char         sa_data[14];  // Address
};
```


### 比较套接字地址结构 {#比较套接字地址结构}

下图展示了几种常见的套接字地址结构的对比，假设长度与协议族字段都是一字节大小。

{{< figure src="/images/unp-comparison-of-various-socket-structures.svg" width="100%" >}}

可以看到 IPv4 与 IPv6 都是固定长度的结构体，而 Unix Domain 与 Datalink 都是可变长度的结构。为了处理这种可变长的结构体，在传递结构时通常会将其长度作为参数一同传递。


## 值-结果参数 {#值-结果参数}

在使用套接字地址结构时，往往函数会传递结构长度作为参数，不过传递方式取决于该结构的传递方向：

-   从进程向内核传递 (`bind`, `connect` 以及 `sendto`)，它们一个参数接受结构一个参数接受结构大小
-   从内核向进程传递 (`accept`, `recvfrom`, `getsockname` 以及 `getpeername`)，它们将为参数中的 len 赋上对应的结构大小

在向内核传递时，进程告诉内核结构中的数据大小，这是一个值，防止内核越界；而内核向进程传递时，这是一个结果，告诉进程在结构中存储了多少信息。这种类型的参数被成为
**值-结果** (value-result) 参数。

一般来讲，套接字地址结构是进程与内核之间的桥梁，比如 4.4BSD 系统就是如此实现的，而 SystemV 实现上套接字函数与普通的库函数无异，函数与协议栈之间如何实现并不影响我们的使用。

对于固定长度的套接字地址结构，长度始终是一个固定值 (IPv4: 14 byte, IPv6: 28
byte)，无论方向如何。对于可变长度的结构 (e.g. sockaddr_un) 改值始终小于结构的最大大小。

在网络变成中，还有很多 value-result 参数的应用：

-   `select` 函数的中间三个参数
-   `getsockopt` 的长度参数
-   `recvmsg` 函数的 msghdr 结构的 msg_namelen 和 msg_controllen 字段
-   `ifconf` 结构中的 ifc_len 字段
-   `sysctl` 函数的两个长度参数中的第一个参数


## 字节函数 {#字节函数}


### 字节序函数 {#字节序函数}

首先思考一个例子，一个 16-bit 整数由两个字节构成，这两个字节是如何存储这个整数的，或者说，高 8-bit 存储在哪个字节中。

**大端** (big-endian) 字节序指的是高位到低位从数据起始位置开始存储，​**小端**
(little-endian) 字节序值低位字节从数据起始位置开始存储，高位在数据结束的地方，也就是按照内存增大方向生长。

这两种表示并没有什么标准可言，且在不同系统中都有使用，我们又将其称为主机字节序，与网络字节序相区分。

```c
// intro/byteorder.c
#include "unp.h"

int main(int argc, char** argv) {
  union {
    short s;
    char  c[sizeof(short)];
  } un;
  un.s = 0x0102;
  printf("%s: ", CPU_VENDOR_OS);
  if (sizeof(short) == 2) {
    puts(un.c[0] == 1 && un.c[1] == 2 ? "big-endian"
	 : (un.c[0] == 2 && un.c[1] == 1 ? "little-endian" : "unknown"));
  } else {
    printf("sizeof(short) = %d\n", sizeof(short));
  }
  return 0;
}
```

UNP 上给出了不同系统与处理器的不同输出

<div class="verse">

i386-unknown-freebsd4.8: little-endian<br />
powerpc-apple-darwin6.6: big-endian<br />
sparc64-unkown-freebsd5.1: big-endian<br />
powerpc-ibm-aix5.1.0.0: big-endian<br />
hppa1.1-hp-hpux11.11: big-endian<br />
x86_64-unknown-linux-gnu: little-endian<br />
sparc-sun-solaris2.9: big-endian<br />

</div>

不同的处理器、系统它们所用的主机字节序有可能不同，因此网络传输中需要一个统一的网络字节序来进行数据的传输 (实际上是大端字节序)，因此就有了 hton 这样一系列函数，也就是第一篇中提到的四个函数。

```c
uint32_t htonl(uint32_t hostlong);   // 将 unsigned int 类型 host to network
uint16_t htons(uint16_t hostshort);  // 将 unsigned short 类型 host to network
uint32_t ntohl(uint32_t netlong);    // 将 unsigned int 类型 network to host
uint16_t ntohs(uint16_t netshort);   // 将 unsigned short 类型 network to host
```

其中 h 表示 host (主机)，n 表示 network (网络)，s 表示 short，l 表示 long，这种命名来自 4.2BSD 的 Digital VAX 实现，实际上可以将 s 看作 16-bit integer，而 l 看作 32-bit integer。

在使用这些函数时，我们无需关心主机序或网络序到底是大端还是小端，这是跨平台的 API
调用。另外注意一点，虽然现在使用的字节都是 8-bit 的定义，但是以前有些机器的字节使用 10-bit 之类的，因此在 RFC 定义上，通常使用位序来定义这些协议，比如说 RFC791
中的 IPv4 头定义。

```text
 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|Version|  IHL  |Type of Service|          Total Length         |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

这表示按照顺序来为协议栈写入 4 个字节，最左端的是最高有效位，编号为 0 的位是最高位。


### 字节操作函数 {#字节操作函数}

在 C 语言标准库中关于字符串的操作函数集中于 `string.h`​，而 C 语言中 char 类型与
int8_t 类型无大的差别，定义的 string 可以认为是 int8_t 的数组，也可以粗略的看作是一个字节数组。

首先第一祖字节操作函数是 C 语言标准库中的 `mem` 系列函数，这一系列函数主要是针对
memory 而言的。

```c
void* memchr(const void *ptr, int ch, size_t count);         // 内存查找
void* memset(void *dest, int ch, size_t count);              // 内存设置
void* memcpy(void *dest, const void *src, size_t count);     // 内存复制
int memcmp(const void *lhs, const void *rhs, size_t count);  // 内存比较
```

`memchr` 将在内存 ptr 中查找 count 个字节，查找是否有字节值为 ch。​`memset` 是将这块内存中的每个字节都设置为 C，设置长度 count byte。​`memcpy` 是将 src 的内容复制到 dest 中，这里要求 src 与 dest 没有交集，如果可能有交集请使用类似的
`memmove`​。​`memcmp` 将两块内存 lhs 与 rhs 逐字节进行比较，负数表示 lhs 字典序小于 rhs，零表示两块内存相等。

另一组函数在网络编程中经常遇到，这是一组 POSIX 函数，派生自 4.2BSD，定义于
`<strings.h>` 中。这些函数以 b 开头 (byte)。

```c
void bzero(void *dest, size_t count);                    // 字节设置为 0
void bcopy(const void *src, void *dest, size_t count);   // 字节复制
int bcmp(const void *lhs, const void *rhs, size_t count);  // 字节比较
```

这些函数与标准 C 函数类似，不同的是它们不会返回指针结果，但这些函数在 POSIX 系统上还是可以随意使用的。


## 地址转换函数 {#地址转换函数}


### POSIX 标准函数 {#posix-标准函数}

我们常用的 IP 地址往往是用 ASCII 字符串形式呈现的，当然对于编程来说这实在是太低效了，因此在编程中使用网络序的二进制值来表示这些地址，比如 IPv4 使用 `uint32_t`
来表示地址，而 IPv6 使用 `uint8_t[8]` 来表示地址。这里将介绍两组函数用来进行
ASCII 字符串地址与二进制地址的互相转换：

1.  `inet_aton`, `inet_ntoa` 以及 `inet_addr` 这三个定义于 &lt;arpa/inet.h&gt; 的
    POSIX 函数，用来将一个 IPv4 点分十进制字符串 (e.g. `192.168.1.1`) 转换成一个 32-bit 网络序二进制值
2.  `inet_pton` 与 `inet_ntop` 是比较新的两个定义在 &lt;arpa/inet.h&gt; 的 POSIX 函数，可以用于 IPv4 或 IPv6 地址的字符串与二进制转换

这两组函数在第一篇中都有简单的介绍，这里给出它们的函数原型

```c
#include <arpa/inet.h>
int inet_aton(const char *cp, struct in_addr *inp);
char *inet_ntoa(struct in_addr in);
in_addr_t inet_addr(const char *cp);
const char *inet_ntop(int af, const void *restrict src, char *restrict dst, socklen_t size);
int inet_pton(int af, const char *restrict src, void *restrict dst);
```

首先来看旧式函数，​`inet_aton` 将 ASCII 点分十进制字符串形式地址转换为 32-bit 网络序二进制地址，也就是结果存储在参数 inp 中，而返回值为 1 表示成功。但是在处理
cp 是空指针时，不会返回错误而是什么都不存储。

`inet_addr` 与上一个函数类似，但是不同的是它不再接收 inp 参数，改为返回地址，这样它可以处理 IPv4 的地址，但遗憾的是它表示错误的方式是返回 **INADDR_NONE** 这个常量，其值与 IPv4 受限广播地址 255.255.255.255 相同，因此该函数无法有效处理这个地址。另外有些手册标注该函数在错误时返回 \\(-1\\) 而非 INADDR_NONE，想一下无符号返回值返回 \\(-1\\) 时应该是怎样的 (UB!)，因此这个函数已被废弃。应该尽可能避免使用该函数。

`inet_ntoa` 从名字上看它与 inet_aton 作用相反，返回的是 ASCII 点分十进制字符串地址格式。需要注意的是，这个字符串在函数内部使用 static 内存进行保存，因此该函数是
**不可重入** (not reentrant) 的。

第一组函数结束，看看第二组，这两个新函数可以为 IPv4 和 IPv6 地址工作，其中 p 意味着表达 (presentation)，而 n 意味着数值 (numeric)。因此从名字可知，pton 是将
ASCII 字符串形式地址转换为网络序二进制形式，而 ntop 正好与其相反。

两个函数都接受 af 作为参数来标识协议族，接受其值为 **AF_INET** (IPv4) 或
**AF_INET6** (IPv6)，如果协议族是不支持的将在 errno 中写入错误 **EAFNOSUPPORT** (协议族不受支持)。

因此在 pton 中，src 指代字符串地址，而 dst 就是接收二进制地址的数据，成功转换时返回 1，非有效地址则返回 0；ntop 中 src 与 dst 与其含义相反，而 size 则是调用者提供的 buffer 的大小，防止溢出。如果大小不足以容纳字符串地址时，将返回空指针并设置 errno 为 **ENOSPC**​。大小在 &lt;netinet/in.h&gt; 中定义了如下常量

```c
#define INET_ADDRSTRLEN 16   // IPv4 点分十进制字符串长度
#define INET6_ADDRSTRLEN 46  // IPv6 十六进制字符串长度
```


### 编写协议无关的地址转换函数 {#编写协议无关的地址转换函数}

在使用 POSIX 标准函数时最大的问题是需要传递一个二进制地址的指针，而这个地址通常是包含在套接字地址结构中的，这样我们不得不事先创建相关协议的变量，这将我们拉到协议相关性的代码中。

```c
// IPv4
struct sockaddr_in addr4;
inet_ntop(AF_INET, &addr4.sin_addr, str, INET_ADDRSTRLEN);
// IPv6
struct sockaddr_in6 addr6;
inet_ntop(AF_INET6, &addr6.sin6_addr, str, INET6_ADDRSTRLEN);
```

为了解决协议相关性问题，我们可以实现自己的地址转换函数，来分离协议与结构的关系。可以使用静态缓冲区来保存函数结果，但这样将造成我们的函数不可重入且线程不安全。另外我们可以支持地址字符串后增加端口，同时将端口与地址写入结构。

```c
// lib/sock_ntop.c
#include <sys/socket.h>
#include <sys/un.h>
#include <net/if_dl.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#include <strings.h>

#include <stdio.h>
#include <string.h>

char* sock_ntop(const struct sockaddr* sa, socklen_t salen) {
  char portstr[8];
  static char str[128];  // Unix Domain 的最大值
  bzero(str, sizeof(str));
  bzero(portstr, sizeof(portstr));
  switch (sa->sa_family) {
    case AF_INET: {
      struct sockaddr_in *sin = (struct sockaddr_in *) sa;
      if (inet_ntop(AF_INET, &sin->sin_addr, str, sizeof(str)) == NULL) {
	return NULL;
      }
      if (ntohs(sin->sin_port) != 0) {
	snprintf(portstr, sizeof(portstr), ":%d", ntohs(sin->sin_port));
	strcat(str, portstr);
      }
      return str;
    }
#ifdef AF_INET6
    case AF_INET6: {
      struct sockaddr_in6 *sin6 = (struct sockaddr_in6 *) sa;
      str[0] = '[';
      if (inet_ntop(AF_INET6, &sin6->sin6_addr, str + 1, sizeof(str) - 1) == NULL) {
	return NULL;
      }
      if (ntohs(sin6->sin6_port) != 0) {
	snprintf(portstr, sizeof(portstr), "]:%d", ntohs(sin6->sin6_port));
	strcat(str, portstr);
	return str;
      }
      return str + 1;
    }
#endif  // AF_INET6
#ifdef AF_UNIX
    case AF_UNIX: {
      struct sockaddr_un *unp = (struct sockaddr_un *) sa;
      if (unp->sun_path[0] == 0) {
	strcpy(str, "(no pathname bound)");
      } else {
	snprintf(str, sizeof(str), "%s", unp->sun_path);
      }
      return str;
    }
#endif  // AF_UNIX
#ifdef AF_LINK
    case AF_LINK: {
      struct sockaddr_dl *sdl = (struct sockaddr_dl *) sa;
      if (sdl->sdl_nlen > 0) {
	snprintf(str, sizeof(str), "%*s (index %d)",
		 sdl->sdl_nlen, &sdl->sdl_data[0], sdl->sdl_index);
      } else {
	snprintf(str, sizeof(str), "AF_LINK, index=%d", sdl->sdl_index);
      }
      return str;
    }
#endif  // AF_LINK
    default: {
      snprintf(str, sizeof(str), "sock_ntop: unknown AF_xxxx: %d, len %d",
	       sa->sa_family, salen);
      return str;
    }
  }
  return NULL;
}
```

另外 unp 还实现了不同的协议无关性函数

-   `sock_bind_wild` 将临时端口与通配地址绑定到套接字
-   `sock_cmp_addr` 与 `sock_cmp_port` 可以对比两个套接字地址结构的地址和端口
-   `sock_set_addr` 与 `sock_set_port` 实现对地址结构的地址与端口的设置
-   `sock_get_port` 与 `sock_ntop_host` 实现将地址结构中的端口和主机部分转换为字符串形式
-   `sock_set_wild` 则是将套接字地址结构的地址部分置为通配地址
