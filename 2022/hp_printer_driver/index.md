# openSUSE 下 HP 打印机配置


正好家里买了打印机，HP 4800 系列，耗材是真便宜，喷墨是真慢啊。不过正好记录一下
Linux 下的 HP 打印机配置过程。

另外 HP 对开源的态度真不错，估计也是因为自家是开源大厂的缘故吧。

<div class="info">

需要注意的是，由于个人使用 openSUSE，因此本文主要是 openSUSE 配置 HP 打印机的过程

</div>


## 安装驱动 {#安装驱动}

Linux 下有 HP 官方的打印机驱动，称为 HPLIP (HP's Linux Imaging and Printing
software)，可以查看 [HPLIP 文档](https://developers.hp.com/hp-linux-imaging-and-printing/features) 或者 [下载](https://developers.hp.com/hp-linux-imaging-and-printing/gethplip)。

对于 HPLIP 可以在以下 Linux 发行版进行自动安装

-   SUSE Linux (13.2, 42.1, 42.2, 42.3, 15.0, 15.1, 15.2, 15.3)
-   Fedora (22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35)
-   Linux Mint (18, 18.1, 18.2, 18.3, 19, 19.1, 19.2, 19.3, 20.04, 20.1, 20.2, 20.3)
-   Red Hat Enterprise Linux (6.0, 7.0, 7.2, 7.6, 7.7, 7.8, 7.9, 8.0, 8.2, 8.3, 8.4, 8.5)
-   Boss (5.0)
-   Ubuntu (12.04, 14.04, 15.10, 16.xx, 17.xx, 18.xx, 19.xx, 20.xx, 21.xx)
-   Debian (7.0 ~ 7.9, 8.0 ~ 8.8, 9.1 ~ 9.9, 10.0 ~ 10.9, 11)
-   Manjaro Linux (17.1.4, 18.0, 18.0.4, 18.1.0, 18.1.2, 19.0, 20.0, 20.2, 21.0.7)
-   Zorin (15, 16)
-   MX Linux (21)
-   Elementary OS (6, 6.1)

比如说 FreeBSD、Gentoo 等发行版，可以采用手动安装。

对 openSUSE 来说，也可以从源中直接安装 hplip

```shell
zypper -y hplip hplip-sane hplip-scan-utils
```


### 自动安装 {#自动安装}

本节着重讲解官方下载的自动安装方式，选择自己的发行版直接下载就行 (openSUSE 下载
SUSE Linux 即可)，如果没有自己的发行版选择 Others 手动安装。

下载完成后运行 .run 文件 (不需要 root 权限)

```shell
./hplip-3.22.2.run
```

第一个选项即选择自动安装 (a) 还是手动安装 (c)，选择自动即可

```text
Please choose the installation mode (a=automatic*, c=custom, q=quit) :
```

之后确定发行版和输入 root 密码，直接回车允许 hplip 可以安装相关程序即可，当然别忘了同意 (y) hplip 的用户协议。如果想要手动安装可以查看 [官方文档](https://developers.hp.com/hp-linux-imaging-and-printing/install/manual/index.html) 来学习，如果想要查看依赖项可以查看 [其他发行版的手动安装](https://developers.hp.com/hp-linux-imaging-and-printing/install/manual/distros/other)。

接下来的问题，重启电脑 (r) 后配置还是重新插拔 USB 线材 (p)，当然可以选择忽略 (i)

```text
Restart or re-plug in your printer (r=restart, p=re-plug in*, i=ignore/continue, q=quit)
```

最后直接回车即可出现配置的图形界面。此时插入打印机 USB 线材即可。


### 手动安装 {#手动安装}

对于手动安装，第一步即卸载从源中安装的 hplip

```shell
su -c "zypper --non-interactive rm hplip hplip-devel hplip-hpijs hplip-sane hplip-scan-utils"
```

之后需要的是从源中安装相关依赖

```shell
su -c "zypper --non-interactive --no-gpg-checks in --auto-agree-with-licenses \
    gcc-c++ glibc ghostscript ghostscript-devel openssl make wget dbus-1-devel \
    cups cups-client cups-devel cups-ddk sane sane-backends sane-backends-devel xsane \
    python-pip leptonica-devel tesseract-ocr tesseract-ocr-devel tesseract-ocr-traineddata-* libzbar-devel \
    python2-Pillow python2-PyYAML python2-PyPDF2 python2-tesserocr python2-decorator python2-scipy python-gobject2 python2-opencv"
su -c "pip2 install --upgrade pip"
su -c "pip2 install setuptools"
su -c "pip2 install reportlab==3.4.0 watchdog==0.10.7"
su -c "pip2 install opencv-contrib-python zbar-py imutils scikit-image pypdfocr"
```

依赖安装完成，下载你需要的 [hplip](https://sourceforge.net/projects/hplip/) 源码，并对其进行编译安装操作

```shell
su -c "./configure --with-hpppddir=/usr/share/cups/model/HP --libdir=/usr/lib64 --prefix=/usr \
    --disable-qt4 --enable-qt5 --enable-doc-build \
    --disable-cups-ppd-install --disable-foomatic-drv-install --disable-libusb01_build \
    --disable-foomatic-ppd-install --disable-hpijs-install --disable-class-driver --disable-udev_sysfs_rules \
    --disable-policykit --enable-cups-drv-install --enable-hpcups-install --enable-network-build \
    --enable-dbus-build --enable-scan-build --enable-fax-build --enable-apparmor_build"
su -c "make"
su -c "make install"
```


### 插件安装 {#插件安装}

将 HPLIP 安装完毕后，默认是不会安装 plug-in 的，如果有扫描需求，是需要自己安装插件的。否则会在使用 `hp-scan` 时出现

```text
error: SANE: Error during device I/O (code=9)
```

插件安装比较简单，只需要命令行启动

```shell
hp-plugin
```

如果遇到以下错误

```text
error: Python gobject/dbus may be not installed\\
error: Plug-in install failed.
```

那就更简单了 (openSUSE 自带了 apparmor)，如果是 debian 需要安装 `apparmor-utils`
，然后使用命令

```shell
su -c "aa-disable /usr/share/hplip/plugin.py"
```

重新安装插件即可


## 配置打印机 {#配置打印机}


### 临时连接打印机配置 WiFi {#临时连接打印机配置-wifi}

如果不需要网络连接打印机进行无线打印，可以选择第一项 USB 连接，这不需要复杂的配置。我的做法是配置好其无线连接，也可以插 USB，方便家庭环境的使用。因此我的选择是第三项 `Wireless/802.11`。**需要注意的是**如果你已在手机上进行过 WiFi 配置，就无需这一步，请移步下一节。

{{< figure src="/ox-hugo/choose-for-connection-method.png" >}}

第二步是选择连接的打印机，不过好像是 py 的原因，从第 2 步到第 3 步很慢，而且在配置无线时有可能出错，出错消息可以在刚刚的安装终端上看到。

```text
Traceback (most recent call last):
  File "/usr/share/hplip/ui5/wifisetupdialog.py", line 713, in NextButton_clicked
    self.showNetworkPage()
  File "/usr/share/hplip/ui5/wifisetupdialog.py", line 296, in showNetworkPage
    self.performScan()
  File "/usr/share/hplip/ui5/wifisetupdialog.py", line 332, in performScan
    self.loadNetworksTable()
  File "/usr/share/hplip/ui5/wifisetupdialog.py", line 422, in loadNetworksTable
    i = QTableWidgetItem(str(name))
UnicodeEncodeError: 'ascii' codec can't encode character u'\u674e' in position 0: ordinal not in range(128)
error: hp-setup failed. Please run hp-setup manually.
```

这个错误是由于编码问题导致的，需要根据追踪栈，进入文件
`/usr/share/hplip/ui5/wifisetupdialog.py` 的第 422 行对其 name 进行修改，修改如下即可

```python
i = QTableWidgetItem(str(name.encode('utf-8')))
```

修改完成后重新使用命令 `hp-setup` 即可，重复之前的步骤等待进入第三步。第三步是打印机选择需要连接的 WiFi，第四步输入所选 WiFi 的密码。不过无论是前进、后退都相当的慢，尽量一次性输入正确，慢得让我看了一个傅正老师的视频hhhhh。最终配置完成时，会显示如下界面

{{< figure src="/ox-hugo/hp-setup-network-information.png" >}}


### 根据 IP 配置无线打印机 {#根据-ip-配置无线打印机}

上一节已经连接了 WiFi，获取到了无线打印机的 IP。这里就可以断开打印机的 USB 连接，当然如果你想要有线连接的方式控制打印机，也可以不断开连线。

在终端重新启动 hplip 配置，不过这次增加了参数 IP，其实这一步与 hp-setup 界面的第二个选项是一样的

```shell
hp-setup 192.168.0.112
```

{{< figure src="/ox-hugo/hp-setup-for-network-config.png" >}}

之后就到了如下界面，输入打印机的 name (名称)、description (描述) 以及 location
(位置)，其实只需要填写必要的 name 即可，另外 setup 会自动识别打印机型号并选择对应的驱动文件 (毕竟是 HP 自家驱动)。添加打印机就完成了！！！

{{< figure src="/ox-hugo/hp-device-manager-for-printer-setup.png" >}}

当连接完成之后，打开 HP Device Manager 即可查看打印机详细信息。

{{< figure src="/ox-hugo/printer-information-in-hp-device-manager.png" >}}


## 打印与扫描成果 {#打印与扫描成果}

尝试了一下配置好的机器，没 A4 纸了，用偏小的纸简单的试一试

打印的是 2021 东京电玩展时，steam 上的图片，打印完成后在通过 hplip 扫描到电脑上，效果如图
![](/ox-hugo/print-and-scan-example.png)

原图在下面
![](/ox-hugo/tokyo-game-show-2021-online.jpg)

<style>
div.info{background:rgba(58,129,195,0.15);border-left:4px solid rgba(58,129,195,0.45);margin:1.8rem 0 1.25rem 15px;padding:0.8em;line-height:1.4;text-align:left;position:relative;clear:both}div.info p{margin:0}div.info::before{content:"i";background:rgba(58,129,195,0.8);align-items:flex-end;top:-1rem;font-weight:700;font-size:1.4rem;-webkit-clip-path:circle(50% at 50% 50%);clip-path:circle(50% at 50% 50%);width:30px;height:30px;display:inline-flex;justify-content:center;position:absolute;left:-1.2rem;line-height:1.3;text-align:left}div.success{background:rgba(45,149,116,0.15);border-left:4px solid rgba(45,149,116,0.45);margin:1.8rem 0 1.25rem 15px;padding:0.8em;line-height:1.4;text-align:left;position:relative;clear:both}div.success p{margin:0}div.success::before{content:"✔";background:rgba(45,149,116,0.8);align-items:flex-end;top:-1rem;font-weight:700;font-size:1.4rem;-webkit-clip-path:polygon(50% 0%, 100% 50%, 50% 100%, 0% 50%);clip-path:polygon(50% 0%, 100% 50%, 50% 100%, 0% 50%);width:35px;height:35px;display:inline-flex;justify-content:center;position:absolute;left:-1.2rem;line-height:1.5;text-align:left}div.warning{background:rgba(220,117,47,0.15);border-left:4px solid rgba(220,117,47,0.45);margin:1.8rem 0 1.25rem 15px;padding:0.8em;line-height:1.4;text-align:left;position:relative;clear:both}div.warning p{margin:0}div.warning::before{content:"!";background:rgba(220,117,47,0.8);align-items:flex-end;top:-1rem;font-weight:700;font-size:1.4rem;-webkit-clip-path:polygon(50% 0, 0 100%, 100% 100%);clip-path:polygon(50% 0, 0 100%, 100% 100%);width:35px;height:35px;display:inline-flex;justify-content:center;position:absolute;left:-1.2rem;line-height:1.1;text-align:left}div.error{background:rgba(186,47,89,0.15);border-left:4px solid rgba(186,47,89,0.45);margin:1.8rem 0 1.25rem 15px;padding:0.8em;line-height:1.4;text-align:left;position:relative;clear:both}div.error p{margin:0}div.error::before{content:"!";background:rgba(186,47,89,0.8);align-items:flex-end;top:-1rem;font-weight:700;font-size:1.4rem;-webkit-clip-path:polygon(25% 0%, 75% 0%, 100% 50%, 75% 100%, 25% 100%, 0% 50%);clip-path:polygon(25% 0%, 75% 0%, 100% 50%, 75% 100%, 25% 100%, 0% 50%);width:35px;height:30px;display:inline-flex;justify-content:center;position:absolute;left:-1.2rem;line-height:1.1;text-align:left}
</style>

