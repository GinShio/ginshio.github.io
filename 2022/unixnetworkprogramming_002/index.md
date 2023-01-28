# 传输层总述


在传输层中，主要学习三种协议

-   User Datagram Protocol (UDP, 用户数据报协议) 是一种简单 (simple)、不可靠
    (unreliable) 的数据报协议
-   Transmission Control Protocol (TCP, 传输控制协议) 是一种复杂的
    (sophisticated)、可靠的 (reliable)、字节流协议
-   Stream Control Transmission Protocol (SCTP, 流控制传输协议) 是一种较新的、可靠的协议，但它还提供消息边界 (message boundaries)、传输层级别的多宿
    (multihoming)、最小化头端阻塞 (head-of-line blocking)


## 总图 {#总图}

{{< figure src="/images/unp-transport-layer-big-picture.svg" width="90%" >}}

图中最左边的应用 tcpdump 直接使用数据链路层接口 BPF (BSD packet filter, BSD 分组过滤器) 或 Datalink provider interface (DLPI, 数据链路提供者接口) 进行通信。而其他应用都是用 API 所提供的 socket 或 XTI。当然在 Linux 上提供了 `SOCK_PACKET` 这种 socket 来访问数据链路。

IPv4
: Internet Protocol (IP, 网际协议)，版本 4。

    这是自 1980 年代早期以来网际协议族中的主力协议，使用 32 bit 编码地址，为 TCP、
    UDP、SCTP、ICMP 和 IGMP 提供分组传递服务。


IPv6
: Internet Protocol, Version 6

    1990 年代中期作为 IPv4 的替代版而设计，将 32 bit 扩展到了 128 bit 来应对互联网的爆炸性增长，为 TCP、UDP、SCTP、ICMPv6 提供分组传递服务。


TCP
: Transmission Control Protocol

    TCP 是一种面向连接的协议，提供可靠、全双工的字节流服务，是一种流式 socket，定义在 **RFC 793**, **RFC 1323**, **RFC 2581**, **RFC 2988** 和 **RFC 3390**。

    为对端发送消息时必须收到明确的答复，如果没有收到答复 TCP 将自动重发数据并等待一段时间。在尝试多次重传失败时 (大概会在 4 到 10 分钟)，TCP 会主动放弃。主要注意的是 TCP 并不会保证对端接收数据，如果可以 TCP 会尝试重传并通知用户。然而 TCP 不是 \\(100\\%\\) 可靠的协议，它的可靠只是在传送数据或失败时通知。

    TCP 包含一个在客户端与服务器之间动态评估 RTT (Round-trip time, 往返时间) 的算法，因此知道一个确认等待了多长时间。举个例子，在穿过 LAN 时可能花费几微秒，而穿过 WAN 时则可能话费数秒。此外，TCP 还会持续评估给定连接的 RTT，因为 RTT
    受到网络波动的变化很大。

    TCP 会将数据序列在发送时按连续的序号关联。比如一个 4096 字节的数据可能被分节为 3 节 (每节最大 1500 字节)，这三节将会有一个连续的序号作为标记，TCP 将会按顺序发送这三节数据。如果这些数据没有按顺序到达，TCP 将会重新按顺序排序并转发给接收应用。如果 TCP 接收到了重复的数据，它会自动丢弃重复数据 (可能一个数据过于拥堵而非真正丢失，导致发送端重传数据，从而出现重复数据)。

    TCP 提供了流量控制，即为对端明确现在有多少字节的数据可以被接收。这又被称为 \*
    通知窗口\* (advertised window)。在任何时刻这些窗口都代表此时缓冲区所能接收的可用大小，以防止溢出。当然这些窗口数量是可以动态变化的，在接收数据时窗口大小减少，从缓冲区读取数据时窗口大小将增大。


UDP
: User Datagram Protocol

    UDP 是一种无连接的协议，是一种数据报 socket，定义在 **RFC 768** 。不保证数据可以到达目的地，也不保证数据按顺序到达，或者数据只会到达一次。如果数据报到达目的地址但校验和发生错误，或者丢失在网络中，它无法投递到 socket，也不会被源端自动重传。如果想要数据可以安全到达目的地址，需要增加很多的特性：对端确认、本端超时与重传。每个 UDP 数据报都有一个长度，这个长度会随数据一起发送给对端。

    UDP 往往在服务器与客户端之间搭建短连接，可以使得客户端在发送完数据后，立即向其他服务器发送其他数据。


SCTP
: Stream Control Transmission Protocol

    SCTP 是一种面向连接的服务，且提供了可靠的、全双工关联以及流量控制，定义在
    **RFC 2960**, **RFC 3309** 和 **RFC 3286** 中。是 `关联` 而非连接，因为往往连接表示仅有两个 IP 在通。信

    与 TCP 不同的是，SCTP 是面向消息的，可以按序将不同长度的消息分别发送给对端。在两个端点的连接上可以存在多个流，每一个流分别提供可靠的消息分发，每个流相互独立不会因消息丢失而阻塞其他流。相反 TCP 连接上，丢失消息意味着阻塞该连接。

    另外 SCTP 还提供了 **多宿** (multihoming) 这种功能，允许单一 SCTP 端点支持多个
    IP 地址。这一特性可以增强健壮性来抵抗网络故障。一个端点可以有多个冗余的网络连接，这些网络连接可能来自不同的网络设施，当关联中发生网络故障时 SCTP 可以自动切换到可用的网络设施。


ICMP
: Internet Control Message Protocol (网际控制消息协议)

    ICMP 处理在路由器与主机之间流通的错误与控制消息。这些消息通常由 TCP/IP 网络软件自身产生和处理 (不是用户程序)，但图中的 ping 与 traceroute 也使用这个协议。


IGMP
: Internet Group Management Protocol (网际组管理协议)

    IGMP 主要用于多播。


ARP
: Address Resolution Protocol (地址解析协议)

    ARP 将一个 IPv4 地址解析为一个硬件地址 (如以太网地址)，通常用于以太网、令牌环网和 FDDI 等广播网络，而在 P2P 网络中不需要此协议。


RARP
: Reverse Address Resolution Protocol (逆地址解析协议)

    RARP 作用与 ARP 相反，将一个硬件地址解析为 IPv4 地址，不过有时也将其用于无盘结点的引导。


ICMPv6
: Internet Control Message Protocol, Version 6

    ICMPv6 用于 IPv6 环境，综合了 ICMPv4、IGMP 以及 ARP 的功能。


BPF
: BSD packet filter (BSD 分组过滤器)

    这是一个通常在 BSD 内核中可以找到的功能，提供了直接对数据链路层的访问能力。


DLPI
: Datalink Provider Interface (数据链路提供者接口)

    这是一个通常在 SVR4 内核中可以找到的功能，提供了直接对数据链路层的访问能力。


## 端口 {#端口}

TCP、UDP 以及 SCTP 都使用 16 bit 端口号来区分不同进程，而客户端想要与服务器联系时，需要标识服务器。

TCP、UDP 以及 SCTP 定义了一组 **公共端口** (well-known port)，用于标识众所周知的服务，比如 FTP 使用 TCP 21 号端口，而 TFTP 使用 UDP 69 号。另一方面用户可能会使用一些短期存活的 **临时端口** (ephemeral port)，这些端口通常由传输层协议自动分配给用户唯一的端口，用户不需要知道其具体值。

IANA (the Internet Assigned Numbers Authority, 互联网号码分配局) 维护着端口号分配状态清单。

1.  公共端口为 \\(0\\) 到 \\(1023\\) ，这些端口由 IANA 分配和控制，可能的话 TCP、UDP 和
    SCTP 将会在同一服务获得相同的端口号，比如无论 TCP 还是 UDP 80 端口都是 Web
    服务器，虽然所有实现都是只使用 TCP。
2.  注册端口 (registered port) 为 \\(1024\\) 到 \\(49151\\)，这些端口不受 IANA 控制，但 IANA 登记并提供其使用情况清单，方便整个群体。同样地，尽可能将所有协议的同端口号分得同一服务。
3.  动态端口 (dynamic) 或私有端口 (private) 范围为 \\(49152\\) 到 \\(65535\\) (这个数是
    65536 的 \\(\frac{3}{4}\\))，即临时端口，这部分是 IANA 不管的。

{{< figure src="/images/unp-allocation-of-port-numbers.svg" width="90%" >}}

上图是不同实现中的端口划分方式，有一些我们需要注意的地方。

1.  Unix 系统有着 **保留端口** (reserved port) 的概念，这些端口小于 1024。这些端口号仅可以由特权程序使用。
2.  由于历史原因，BSD 实现 (4.3BSD 开始) 以 1024 到 5000 为临时端口，因为当年支持 3977 个连接的主机相当不容易。如今很多系统实现直接采用 IANA 定义的临时端口，或像 Solaris 一样定义更大的端口。
3.  一些少数的客户端需要保留一个端口用于认证 (例如 rlogin 和 rsh)，这些客户端使用 `rresvport` 创建 TCP 套接字，并在 513 到 1023 范围内尝试绑定端口 (从
    1023 逆序开始)。


## 缓冲区大小及限制 {#缓冲区大小及限制}

IP 数据报的大小会有一些限制。

-   IPv4 数据报最大大小为 65535 字节 (包含 IPv4 头部)，其长度字段占 16 bit。
-   IPv6 数据报最大大小为 65575 字节 (包含 40 字节的 IPv6 头部)，其长度字段为数据长度，占 16 bit。
-   绝大多数网络有一个硬件规定的 MTU (以太网为 1500 byte)，或人为配置的 MTU
    (PPP)，IPv4 要求最小 MTU 为 68 字节，这将允许 IPv4 首部 (20 byte 固定长度与
    40 byte 选项部分) 拼接最小的片段 (片段偏移字段以 8 byte 为单位)。而 IPv6 要求最小链路 MTU 为 1280 byte。
-   两主机之间路径中的最小 MTU 称为 **路径 MTU** (path MTU)，1500 byte 的以太网
    MTU 是最常用的 path MTU。如果相反两个方向上的 path MTU 不一致被称为不对称的。
-   IP 数据报从接口送出时，如果大小超过相应链路的 MTU，将执行 **分片**
    (fragmentation)，但在到达目的地址时通常不会 **重组** (reassembling)。IPv4 主机对其产生的数据报执行分片，IPv4 路由对其转发的数据报执行分片。在 IPv6 协议栈中只有主机对其产生的数据报进行分片。
-   IPv4 首部如果设置了 **不分片** (don't fragment, DF)，无论是发送还是转发都不会将其分片。如果路由器收到了一个大小超过链路 MTU 且设置 DF 的数据报时，将产生一个 ICMPv4 `destination unreachable fragmentation needed but DF bit set`
    (目的地不可达，需分片但设置 DF) 的出错消息。同样的 IPv6 可以认为有一个隐含的
    DF，当超过链路 MTU 时被路由转发将会出现 ICMPv6 `packet too big` 的错误消息。
-   IPv4 和 IPv6 都定义了 **最小重组缓冲区大小** (minimum reassembly buffer size)，它是 IPv4 (576 byte) 或 IPv6 (1500 byte) 的任何实现都必须支持的最小数据报大小。比如 IPv4 数据报我们不能保证目的地址可以接受 577 byte 字节的数据报。
-   TCP 有一个 MSS (maximum segment size, 最大分节大小) 用于通告对端在每个分节所能发送的最大 TCP 数据量。MSS 的目的是告诉对端其重组缓冲区大小的实际值，从而试图避免分片。MSS 经常被设置为 MTU 减去 IP 和 TCP 首部的固定长度，比如以太网中的 IPv4 MSS 为 1460，IPv6 MSS 为 1440。
-   SCTP 基于到对端所有地址发现的最小 path MTU 来确定一个分片大小。


### TCP 输出 {#tcp-输出}

{{< figure src="/images/unp-steps-and-buffers-involved-in-tcp-socket.svg" width="70%" >}}

每一个 TCP socket 有一个发送缓冲区，可以使用 SO_SNDBUF 选项来更改该缓冲区的大小。当进程调用 `write/3` 时，内核从该进程的缓冲区中复制所有数据到 write socket 的发送缓冲区，若发送缓冲区大小不足时将阻塞进程，内核不会从 write 返回，直到所有数据都复制到 socket buffer，因此当 write 返回时仅表示可以使用 buffer 而非对端接收到数据。

本端 TCP 提取 socket buffer 并以 TCP 数据传送规则将其发送，对端 TCP 必须确认收到的数据，对端 ACK 的到来才能在缓冲区中丢弃已确认的数据。另外 TCP 还会为已发送的数据保留副本，直到被对端确认为止。

本端 TCP 以 MSS 大小或更小的 chunk 将数据传送给 IP，同时每个 chunk 上都有 TCP 首部。IP 给每个 TCP 分节按上 IP 首部构成 IP 数据报，查找路由表项确定外出接口，并传递给数据链路层。而虽然数据报可能被 IP 分片，但 MSS 的作用就是尽可能防止分片。


### UDP 输出 {#udp-输出}

{{< figure src="/images/unp-steps-and-buffers-involved-in-udp-socket.svg" width="70%" >}}

上图中的 socket buffer 很明显与 TCP 的区别是虚线表示，实际上这是并不真实存在的
buffer， `SO_SNDBUF` 的作用是更改可写入 socket 的大小上限。如果应用写一个大于上限的数据报，内核将返回 **EMSGSIZE** 错误。由于 UDP 并不可靠，因此无需额外的 buffer
来备份数据，而是简单的按上 8 byte UDP 首部后传递给 IP 层，在数据被发送后将丢弃数据拷贝。

write 调用成功返回表示 **所写的数据报或其所有分片已被添加至数据链路层的输出队列**
，如果队列没有足够的空间存放该数据报或某个分片时，内核通常返回一个 ENOBUFS 的错误。但是某些实现中将会直接丢弃而不返回错误。


### SCTP 输出 {#sctp-输出}

{{< figure src="/images/unp-steps-and-buffers-involved-in-sctp-socket.svg" width="70%" >}}

SCTP 与 TCP 类似，因此也需要发送缓冲区，SO_SNDBUF 选项可以更改缓冲区的大小。当调用 write 时，内核从该c進行的缓冲区复制所有数据到 socket buffer。同样的当 socket
buffer 容量不足时将会阻塞进程，直至所有数据被拷贝到 socket buffer。SCTP 必须等待
SACK，确认或累计超出超时重发后才会将数据从 socket buffer 中删除。


## 标准 Internet 服务与命令行程序 {#标准-internet-服务与命令行程序}


### 标准 Internet 服务 {#标准-internet-服务}

TCP/IP 多数实现中都会提供若干标准服务。一般来说无论 TCP 还是 UDP 它们的端口号都相同。

| 名称    | TCP 端口 | UDP 端口 | RFC | 说明                          |
|-------|--------|--------|-----|-----------------------------|
| echo    | 7      | 7      | 862 | 返回客户端发送的数据          |
| discard | 9      | 9      | 863 | 丢弃客户端发送的数据          |
| daytime | 13     | 13     | 867 | 返回可读的时间与日期          |
| chargen | 19     | 19     | 864 | 发送连续的字符流，UDP 则每次发送随机大小的数据报 |
| time    | 37     | 37     | 868 | 自 `1900.01.01 00:00:00` 以来的秒数 |

这些服务通常由 inetd 守护进程提供，且使用 telnet 客户程序就能完成简易测试。不过由于安全性问题，默认将关闭这些服务。


### 常见命令行程序 {#常见命令行程序}

| 应用                 | IP               | ICMP             | UDP              | TCP              | SCTP             |
|--------------------|------------------|------------------|------------------|------------------|------------------|
| ping                 |                  | \\(\checkmark\\) |                  |                  |                  |
| traceroute           |                  | \\(\checkmark\\) | \\(\checkmark\\) |                  |                  |
| OSPF (路由协议)      | \\(\checkmark\\) |                  |                  |                  |                  |
| RIP (路由协议)       |                  |                  | \\(\checkmark\\) |                  |                  |
| BGP (路由协议)       |                  |                  |                  | \\(\checkmark\\) |                  |
| BOOTP (引导协议)     |                  |                  | \\(\checkmark\\) |                  |                  |
| DHCP (引导协议)      |                  |                  | \\(\checkmark\\) |                  |                  |
| NTP (时间协议)       |                  |                  | \\(\checkmark\\) |                  |                  |
| TFTP (低级 FTP)      |                  |                  | \\(\checkmark\\) |                  |                  |
| SNMP (网络管理)      |                  |                  | \\(\checkmark\\) |                  |                  |
| SMTP (电子邮件)      |                  |                  |                  | \\(\checkmark\\) |                  |
| Telnet (远程登陆)    |                  |                  |                  | \\(\checkmark\\) |                  |
| SSH (安全远程登陆)   |                  |                  |                  | \\(\checkmark\\) |                  |
| FTP (文件传输)       |                  |                  |                  | \\(\checkmark\\) |                  |
| HTTP (Web)           |                  |                  |                  | \\(\checkmark\\) |                  |
| NNTP (网络新闻)      |                  |                  |                  | \\(\checkmark\\) |                  |
| LPR (远程打印)       |                  |                  |                  | \\(\checkmark\\) |                  |
| DNS (域名系统)       |                  |                  | \\(\checkmark\\) | \\(\checkmark\\) |                  |
| NFS (网络文件系统)   |                  |                  | \\(\checkmark\\) | \\(\checkmark\\) |                  |
| Sun RPC (远程过程调用) |                  |                  | \\(\checkmark\\) | \\(\checkmark\\) |                  |
| DCE RPC (远程过程调用) |                  |                  | \\(\checkmark\\) | \\(\checkmark\\) |                  |
| IUA (ISDN over IP)   |                  |                  |                  |                  | \\(\checkmark\\) |
| M2UA/M3UA (SS7 电话信令) |                  |                  |                  |                  | \\(\checkmark\\) |
| H.248 (媒体网关控制) |                  |                  | \\(\checkmark\\) | \\(\checkmark\\) | \\(\checkmark\\) |
| H.323 (IP 电话)      |                  |                  | \\(\checkmark\\) | \\(\checkmark\\) | \\(\checkmark\\) |
| SIP (IP 电话)        |                  |                  | \\(\checkmark\\) | \\(\checkmark\\) | \\(\checkmark\\) |


## TCP 连接 {#tcp-连接}

我们需要搞清楚 `connect/3`, `accept/4` 和 `close/1` 这些函数在操作 TCP 连接时都干了什么，因此我们需要学习 TCP 连接的相关内容，比如建立连接、断开连接、以及状态。


### TCP 创建连接 {#tcp-创建连接}

在 TCP 连接创建时往往经历以下几个阶段：

1.  服务端接受发起的连接，这通常需要 `socket/3`, `bind/3`, `listen/2` 等
    API，将其称为 **被动打开** (passive open)
2.  客户端通过 `connect/3` 进行 **主动打开** (active open)，首先发送 SYN
    (synchronize) 字段来告知在这个连接中发送数据的初始序号。通常 SYN 不带数据，仅包含 IP 头、TCP 头以及可选的 TCP选项。
3.  服务器必须为客户端发送的 SYN 回复 ACK (acknowledge)，并发送 SYN 来初始化本端的数据初始序号。ACK 和 SYN 将会合并在一个 TCP 数据中发送。
4.  客户端必须以 ACK 回应服务器的 SYN

{{< figure src="/images/unp-tcp-three-way-handshake.svg" width="50%" >}}

在 TCP 通信中，每个 ACK 都是本端所期待的下一个序列号，SYN 占据一个字节的序列号空间，每个 SYN 中的 ACK 确认号都是 SYN 的序列号加 1。


### TCP 选项 {#tcp-选项}

每一个 SYN 可以包含一些 TCP 选项，通常常用选项有以下几种：

-   MSS 选项。发送 SYN 的 TCP 端将会告知 **最大分节大小** (maximum segment size,
    MSS)，这是本次连接中每个分节所能接受的最大大小，而对端使用该 MSS 值作为分节依据。
-   窗口扩展选项。TCP 任何一端可以告知对端本次连接最大窗口为 65535 (首部相应字段占 16 bit)，不过当今互联网的高速网络 (大于 45 Mbps) 或长延迟路径 (卫星链路)
    可能要求更大的窗口来提高吞吐量。该选项可以指定首部中通知窗口扩大的位数 (左移,
    0 到 14 bit)，由此所能提供的最大窗口即 \\(65535 \times 2^{14}\\) 。只有在两端都支持的系统上该选项才有用。
-   时间戳选项。对于高速连接这是必要选项，可以防止由失而复得的分组可能造成的数据损坏。类似窗口扩展，这也需要双端支持。

大多数实现都支持这些设置，后两项有时称为 `RFC 1323 选项`，高宽带或长延迟网络被称为 **长胖管道** (long fat pipe)，因此后两项也称为 `长胖管道选项`。


### TCP 连接终止 {#tcp-连接终止}

相比创建连接的三次握手，终止连接往往需要四步：

1.  TCP 一端首先发起 `close/1` ，我们将这一端称为 **主动关闭** (active close)。主动端 TCP 将会发送 **FIN** 字段，这意味着所有数据发送完成。
2.  接收 FIN 的 TCP 端被称为 **被动关闭** (passive close)，接收到 FIN 后将会进行确认。
3.  一段时间之后，被动端将会调用 `close/1` 来发送 FIN。
4.  最终主动端将确认 FIN 并断开这个连接。

{{< figure src="/images/unp-tcp-four-way-termination.svg" width="50%" >}}

FIN 与 SYN 类似同样占据一个字节，而 ACK 是 FIN 序列号加 1。在第二步与第三步之间，依然可能有数据流动，但这个数据仅有被动关闭端到主动关闭端，这个状态被称为 **半断开状态** (half-close)。

这在里 FIN 的发生是因为调用了 `close/1` ，不过需要注意当程序主动终止时 (`exit/1`
或 main return) 还是被动 (接收到终止程序的信号)，所有打开的文件描述符都会被关闭，此时的 TCP sockfd 也不例外，因此这时也会发送 FIN。

最后提一点，主动关闭端是无论 server 还是 client 都可以的，并非只有 client 主动关闭。不过通常情况下都是 client 发起，在 HTTP/1.0 中是个例外。


### TCP 状态转换 {#tcp-状态转换}

TCP 涉及连接建立和终止的状态可以使用状态转换图来表示。TCP 连接中一共有 11 种不同的状态，并且这些状态之间有详细的转换规则，且转换基于当前状态与接收到的消息。

{{< figure src="/images/unp-tcp-state-transition-diagram.svg" width="75%" >}}

上图中标记了两个没有介绍过的转换：**同时打开** (simultaneous open) 和 **同时关闭**
(simultaneous close)，它们是两端同时发送 SYN / FIN 的情形下产生的，虽然及其罕见但并不是不能发生。


### TCP 的分节 {#tcp-的分节}

在完整的 TCP 连接中，会有建立连接、传输数据、终止连接三个阶段。

在连接建立时，客户端与服务端宣告了不同的 MSS (这不构成任何影响)，连接建立后客户端将请求的数据按 1460 字节进行分组，而服务端回复请求时则采用 536 字节分组。

还需要注意一点，数据传输过程中服务器对请求的 ACK 携带在响应之上一并发送。这种做法称之为 **捎带** (piggybacking)，通常在服务器产生应答时间少于 200 ms 时发生，如果更长时间的耗时则会先发送 ACK 再进行响应。

值得注意的是，如果只是以单分节的请求响应为目的，TCP 连接将会产生 8 个分节的开销，而采用 UDP 仅仅有请求与响应的开销。


### TIME_WAIT 状态 {#time-wait-状态}

TCP 连接中，毫无疑问 `TIME_WAIT` 是最难理解的。这个状态将在主动关闭端经历，该端将在这个状态持续 **最长分节生命期** (maximum segment lifetime, MSL) 的两倍，或者称为 2MSL。

每一个 TCP 实现中都会定义 MSL，RFC 1122 中建议 MSL 为 2 分钟，BSD 实现中一般为
30s，Linux 实现默认为 60s。MSL 是任何 IP 数据报在 Internet 上所能存活的最大时长。当然数据还会包含一个 8 bit 的 **跳限** (hop limit)，即 IPv4 中哦过的 TTL 字段与
IPv6 中的跳限字段，拥有最大跳限的数据依然不能超过 MSL 时间限制。网络中报文丢失通常是路由器出现问题，比如漰溃或两个路由链路断开，路由可能需要几秒甚至几分钟来找到其他稳定的通路。在这期间，路由可能会发生循环 (由 A 发送给 B，然后 B 再发送回 A)，因此在迷途期间，发送端检测到超时将会重发该数据，重传的数据可能从其他路径到达目的地址。而可能在 MSL 之内迷失的数据也被送达目的地，这个分组被称为 **迷失重复** (lost
duplicate) 或 **漫游重复** (wandering duplicate)。

TIME_WAIT 状态有两个存在的理由：

1.  可靠地实现 TCP 全双工终止连接。

    最终 ACK 丢失的情况下，主动关闭端必须重传 ACK，而它必须正确处理终止序列丢失的情况。

2.  允许旧的重复分节在网络中过期

    TCP 需要防止在 TIME_WAIT 期间，如果相同的 IP、port 发送来的新的数据，防止误解属于正在断开的连接的迷失重复。因此 TCP 将给处于 TIME_WAIT 状态的连接发起新的连接，而 2 MSL 可以保证任何方向上的分节都以被丢弃。保证在发起新连接时，老旧连接的数据以全部消逝。


## SCTP 关联 {#sctp-关联}

SCTP 是与 TCP 类似的面向连接协议，关联可以被建立和终止，但与 TCP 相比有些不同。

{{< figure src="/images/unp-sctp-state-transition-diagram.svg" width="75%" >}}


### SCTP 创建关联 {#sctp-创建关联}

SCTP 创建关联需要四次握手。

1.  服务端必须准备好接受接入关联，通常与 TCP 类似使用 `socket/3`, `bind/3` 和
    `listen/2` 进行被动连接。
2.  客户端通过 `connect/3` 或发送隐式打开关联消息来进行主动连接。这使得 SCTP 发送一个 INIT 消息来告知服务端，客户端有哪些 IP 地址、初始化序列号、标识该关联中的所有分组的初始标签、客户端请求的外出流数量以及客户端支持的外来流数量。
3.  服务端会使用 **INIT-ACK** 确认客户端 INIT 消息，并包含同样的信息以及状态
    cookie。状态 cookie 包含了服务器需要确认关联是否有效的所有状态，cookie 进行数字签名以确保其有效性。
4.  客户端以 COOKIE-ECHO 对服务器状态 cookie 进行响应，在同一分组中还可能直接包含用户数据。
5.  服务端确认 cookie 正确并回复 COOKIE-ACK 建立关联，当然同样可能携带用户数据。

{{< figure src="/images/unp-sctp-four-way-handshake.svg" width="50%" >}}

SCTP 最少需要 4 个分组进行请求，这四次握手与 TCP 的三次握手很相似，除了 cookie
生成部分。INIT 将会携带一个验证标签 Ta 和一个初始化序列号 J。Ta 必须出现在关联中的所有分组中，对端 INIT ACK 中承载一个验证标记 Tz，而 Tz 也需要在关联有效期内出现在每个分组中。另外 STCP 服务端在 INIT-ACK 中提供了 cookie，这个 cookie 包含了设置该关联所需的所有状态，而 SCTP 协议栈无需保存所关联客户的有关信息。

由于 SCTP 支持多宿，在四次握手结束之后两端会各自选择一个主目的地址作为默认地址。


### SCTP 终止关联 {#sctp-终止关联}

SCTP 不提供 TCP 那样的半连接状态，当一端停止连接时另一端必须停止发送所有新数据。请求关闭关联的接受端在数据队列中的所有数据发送完之后完成关闭。

{{< figure src="/images/unp-sctp-association-closed.svg" width="50%" >}}

由于使用验证标签的缘故，因此 SCTP 也不需要 TIME_WAIT 状态，数据首部会包含 INIT
和 INIT-ACK 中所交换的标记，由此区分是否是旧的连接。


### SCTP 的分节 {#sctp-的分节}

与 TCP 类似，SCTP 也需要经历建立关联、传输数据、终止关联三个阶段。

客户端发送 COOKIE-ECHO 时可以捎带 DATA，而服务器在 COOKIE-ACK 也可以捎带数据，一般而言当网络应用采用一到多接口样式时将会捎带一个或多个 DATA 块。

SCTP 分组信息的单位称为块 (chunk)，这是一种自述型分组，包含了块类型、若干块标记和块长度。这样做是为了方便进行多个块的绑缚，只需要简单的将多个块合并到一个 SCTP
中即可。


### SCTP 的选项 {#sctp-的选项}

SCTP 使用参数和块方便增设的可选特性，新的特性通过添加这两个条目之一增添，并允许通常的 SCTP 处理规则未知的参数和块。参数类型字段和块类型字段的高 2 bit 指明 SCTP
接收端该如何处理位置的参数或块。
