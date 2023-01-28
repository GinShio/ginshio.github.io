# 使用 KMS 激活 Microsoft 软件


微软的软件主要可以通过以下三个渠道获取:

-   零售
-   原始设备制造商 (OEM)
-   批量许可协议

OEM 在工厂执行激活，比如说新买的笔记本电脑自带的系统就是这种方式。零售主要通过联机、电话或 VAMT 代理激活。批量激活产品主要选择 MAK (多次激活密钥) 、 KMS (密钥管理服务) 以及 AD (Active Directory) 进行激活。

KMS 可以在本地网络完成激活，而无需将个别计算机连接到 Microsoft 进行产品激活。KMS
不需要专用系统的轻型服务，可以轻易地将其联合托管在提供其他服务的系统上。

KMS 服务器可以为局域网内所有连接的产品进行周期性激活，激活周期一般为 180 天，产品激活后会定期连接 KMS 服务器进行验证、续期，如果不能连接到服务器在激活周期过后，产品将过期而需要重新激活。

KMS 服务激活的是 VL 版，而我们常用的 RTL (零售版) 是无法激活的。自己搭建 KMS 服务器激活产品，虽然可以正常使用，但是不能算正版软件，请支持正版！


## 部署 KMS 服务器 {#部署-kms-服务器}

常用的 Microsoft KMS 服务器是开源的 [Vlmcsd](https://github.com/Wind4/vlmcsd)，它可以部署到不同平台上提供服务。
Vlmcsd 的使用很简单，下载下来启动即可提供服务，默认端口号是 1688


## Windows {#windows}

对于 Windows 的下载，可以选择 [官方渠道](https://www.microsoft.com/zh-cn/software-download/windows10ISO) 或通过 [MSDN, I tell you](https://msdn.itellyou.cn/) 进行下载，安装的专业版均可以 KMS 激活


### 激活 Windows {#激活-windows}

相对来说激活 Windows 也很简单，以**管理员身份**打开 Powershell 或命令提示符，并输入命令即可激活

1.  设置 GVLK，这里我们以 Windows Server 2016 标准版为例
    ```bat
    slmgr /ipk WC2BQ-8NRM3-FDDYY-2BFGV-KHKQY
    ```
2.  设置 KMS 服务器
    ```bat
    slmgr /skms example.com
    ```
    如果 KMS 服务端口号不是 1688 需要显示指定端口号，比如端口号是 1024
    ```bat
    slmgr /skms example.com:1024
    ```
3.  激活 Windows
    ```bat
    slmgr /ato
    ```
4.  这是一个可选项，查看激活情况
    ```bat
    slmgr /xpr
    ```


### Windows GVLK {#windows-gvlk}

在此列出各个版本对应的 GVLK，所有的 Key 也可以前往 [官方文档](https://docs.microsoft.com/en-us/windows-server/get-started/kmsclientkeys) 查看

-   Windows Server Semi-Annual Channel (Windows Server 半年版) [自 1809 起]

    | 操作系统版本 | GVLK                          |
    |--------|-------------------------------|
    | Datacenter | 6NMRW-2C8FM-D24W7-TQWMY-CWH2D |
    | Standard   | N2KJX-J94YW-TQVFB-DG9YT-724CC |
-   Windows Server LTSC/LTSB

    | 操作系统版本    | GVLK                          |
    |-----------|-------------------------------|
    | 2022 Datacenter | WX4NM-KYWYW-QJJR4-XV3QB-6VM33 |
    | 2022 Standard   | VDYBN-27WPP-V4HQT-9VMD4-VMK7H |
    | 2019 Datacenter | WMDGN-G9PQG-XVVXX-R3X43-63DFG |
    | 2019 Standard   | N69G4-B89J2-4G8F4-WWYCC-J464C |
    | 2019 Essentials | WVDHN-86M7X-466P6-VHXV7-YY726 |
    | 2016 Datacenter | CB7KF-BWN84-R7R2Y-793K2-8XDDG |
    | 2016 Standard   | WC2BQ-8NRM3-FDDYY-2BFGV-KHKQY |
    | 2016 Essentials | JCKRF-N37P4-C2D82-9YXRT-4M63B |
-   Windows 10 / Windows 11 Semi-Annual Channel (Windows 10 / Windows 11 半年版)

    | 操作系统版本           | 中译     | GVLK                          |
    |------------------|--------|-------------------------------|
    | Pro                    | 专业版   | W269N-WFGWX-YVC9B-4J6C9-T83GX |
    | Pro N                  | 专业版  N | MH37W-N47XK-V7XM9-C7227-GCQG9 |
    | Pro for Workstations   | 专业工作站版 | NRG8B-VKK3Q-CXVCJ-9G2XF-6Q84J |
    | Pro for Workstations N | 专业工作站版 N | 9FNHH-K3HBT-3W4TD-6383H-6XYWF |
    | Pro Education          | 专业教育版 | 6TP4R-GNPTD-KYYHQ-7B7DP-J447Y |
    | Pro Education N        | 专业教育版 N | YVWGF-BXNMC-HTQYQ-CPQ99-66QFC |
    | Education              | 教育版   | NW6C2-QMPVW-D7KKK-3GKT6-VCFB2 |
    | Education N            | 教育版 N | 2WH4N-8QGBV-H22JP-CT43Q-MDWWJ |
    | Enterprise             | 企业版   | NPPR9-FWDCX-D2C8J-H872K-2YT43 |
    | Enterprise N           | 企业版 N | DPH2V-TTNVB-4X9Q3-TJR4H-KHJW4 |
    | Enterprise G           | 企业版 G | YYVX9-NTFWV-6MDM3-9PT4T-4M68B |
    | Enterprise G N         | 企业版 G N | 44RPN-FTY23-9VTTB-MP9BX-T84FV |
-   Windows 10 LTSC/LTSB

    | 操作系统版本                  | 中译                   | GVLK                          |
    |-------------------------|----------------------|-------------------------------|
    | Enterprise LTSC 2019 / 2021   | 企业版 LTSC 2019 / 2021 | M7XTQ-FN8P6-TTKYV-9D4CC-J462D |
    | Enterprise N LTSC 2019 / 2021 | 企业版 N LTSC 2019 / 2021 | 92NFX-8DJQP-P6BBQ-THF9C-7CG2H |
    | Enterprise LTSB 2016          | 企业版 LTSB 2016       | DCPHK-NFMTC-H88MJ-PFHPY-QJ4BJ |
    | Enterprise N LTSB 2016        | 企业版 N LTSB 2016     | QFFDN-GRT3P-VKWWX-X7T3R-8B639 |
    | Enterprise LTSB 2015          | 企业版 LTSB 2015       | WNMTR-4C88C-JK8YV-HQ7T2-76DF9 |
    | Enterprise N LTSB 2015        | 企业版 N LTSB 2015     | 2F77B-TNFGY-69QQF-B8YKP-D69TJ |
-   Windows 8.1

    | 操作系统版本 | 中译  | GVLK                          |
    |--------|-----|-------------------------------|
    | Pro          | 专业版 | GCRJD-8NW9H-F2CDX-CCM8D-9D6T9 |
    | Pro N        | 专业版 N | HMCNV-VVBFX-7HMBH-CTY9B-B4FXY |
    | Enterprise   | 企业版 | MHF9N-XY6XB-WVXMC-BTDCT-MKKG7 |
    | Enterprise N | 企业版 N | TT4HM-HN7YT-62K67-RGRQJ-JFFXW |
-   Windows 8

    | 操作系统版本 | 中译  | GVLK                          |
    |--------|-----|-------------------------------|
    | Pro          | 专业版 | NG4HW-VH26C-733KW-K6F98-J8CK4 |
    | Pro N        | 专业版 N | XCVCF-2NXM9-723PB-MHCB7-2RYQQ |
    | Enterprise   | 企业版 | 32JNW-9KQ84-P47T8-D8GGY-CWCK7 |
    | Enterprise N | 企业版 N | JMNMF-RHW7P-DMY6X-RF3DR-X2BQT |
-   Windows 7

    | 操作系统版本   | 中译  | GVLK                          |
    |----------|-----|-------------------------------|
    | Professional   | 专业版 | FJ82H-XT6CR-J8D7P-XQJJ2-GPDD4 |
    | Professional N | 专业版 N | MRPKT-YTG23-K7D7T-X2JMM-QY7MG |
    | Professional E | 专业版 E | W82YF-2Q76Y-63HXB-FGJG9-GF7QX |
    | Enterprise     | 企业版 | 33PXH-7Y6KF-2VJC9-XBBR8-HVTHH |
    | Enterprise N   | 企业版 N | YDRBP-3D83W-TY26F-D46B2-XCKRJ |
    | Enterprise E   | 企业版 E | C29WB-22CC8-VJ326-GHFJW-H9DH4 |


## Office {#office}

由于 Office 的 RTL 转 VL 比较麻烦，这里我们使用 VL 版进行激活操作


### 安装 Office VL {#安装-office-vl}

我们首先下载 [Office Deployment Tool (ODT)](https://www.microsoft.com/en-us/download/confirmation.aspx?id=49117)，即 Office 部署工具，运行 ODT 将会获取到一个 **setup** 和示例的配置文件。setup 是用于安装 Office 的可执行程序，而配置文件是指示 setup 如何安装 Office 的配置文件。

我们将使用配置文件 `config.xml` 进行安装，以**管理员身份**打开 Powershell 或命令提示符，并输入命令进行安装。至于 ODT 配置文件的内容，将在下节介绍。

1.  根据配置文件下载数据
    ```bat
    setup.exe /download config.xml
    ```
2.  根据配置文件安装 Office
    ```bat
    setup.exe /configure config.xml
    ```


### ODT 配置文件 {#odt-配置文件}

配置文件采用 XML 格式，我们详细说明一下文件中的标签元素，也可以查看 [官方文档](https://docs.microsoft.com/en-us/deployoffice/office-deployment-tool-configuration-options)


#### Add 元素 {#add-元素}

Add 用于定义要下载的 **产品** 和 **语言**

SourcePath (可选)
: 用于定义 `安装文件的位置` ，这是下载的数据文件的位置，而非最终的安装位置。如果没有定义该属性，则会在 ODT 所处的文件夹下下载数据。如果 SourcePath 下包含相同版本的 Office 数据文件，那么 ODT 会增量下载文件以节省网络带宽。示例值 `\server\share`、`c:\preload\office`

Version (可选)
: 用于指定 `安装的版本` ，默认为可用的最新版本，推荐与
    `Channel` 属性一同使用。可以选择 **MatchInstalled** 作为值，即使有新的可用版本，也将下载与已安装的 Office 版本相同的数据，此选项在添加语言包、Visio、Project
    时十分有用。示例值 `16.0.8201.2193`、`MatchInstalled`

OfficeClientEdition (可选)
: 指定 Office 的位版本，默认安装 64 位 Office，如果 Windows 版本为 64 位或内存小于 4 GB 则安装 32 位。如果已安装 Office 时，默认会与已安装的版本匹配，Office 不支持混合体系，请小心设置该属性

Channel (可选)
: 用于定义安装 Office 的更新通道，如果未安装 Office 则默认为
    `Current` ，已安装的情况下会自动匹配相同的频道。Office 2019 受支持的更新频道为 `PerpetualVL2019` ，2021 则是 `PerpetualVL2021`


#### Product 元素 {#product-元素}

Product 定义要**下载或安装**的产品。如果定义了多个产品，这些产品会按照配置文件中的顺序进行安装。指定产品的 ID，更多 ID 请参阅 [官方文档](https://docs.microsoft.com/en-us/office365/troubleshoot/installation/product-ids-supported-office-deployment-click-to-run)

遗憾的是我没有找到 Office 2016 的 `KEY`，但是可以通过 Volume License Pack 获取安装包，如果你知道如何用 ODT 安装请告诉我

-   [Office 2021](https://www.microsoft.com/download/details.aspx?id=103446)

    | 产品                         | 中译                | ID                         |
    |----------------------------|-------------------|----------------------------|
    | Access 2021                  |                     | Access2021Volume           |
    | Excel 2021                   |                     | Excel2021Volume            |
    | OneNote 2021                 |                     | OneNote2021Volume          |
    | Outlook 2021                 |                     | Outlook2021Volume          |
    | PowerPoint 2021              |                     | PowerPoint2021Volume       |
    | Project Professional 2021    | Project 专业版 2021 | ProjectPro2021Volume       |
    | Project Standard 2021        | Project 标准版 2021 | ProjectStd2021Volume       |
    | Office Pro Plus 2021         | Office 专业增强版 2021 | ProPlus2021Volume          |
    | Office Standard 2021         | Office 标准版 2021  | Standard2021Volume         |
    | Publisher 2021               |                     | Publisher2021Volume        |
    | Visio Professional 2021      | Visio 专业版 2021   | VisioPro2021Volume         |
    | Visio Standard 2021          | Visio 标准版 2021   | VisioStd2021Volume         |
    | Word 2021                    |                     | Word2021Volume             |
    | Skype for Business LTSC 2021 | Skype 商业版 LTSC 2021 | SkypeforBusiness2021Volume |
-   [Office 2019](https://www.microsoft.com/download/details.aspx?id=57342)

    | 产品                      | 中译              | ID                         |
    |-------------------------|-----------------|----------------------------|
    | Access 2019               |                   | Access2019Volume           |
    | Excel 2019                |                   | Excel2019Volume            |
    | Outlook 2019              |                   | Outlook2019Volume          |
    | PowerPoint 2019           |                   | PowerPoint2019Volume       |
    | Project Professional 2019 | Project 专业版 2019 | ProjectPro2019Volume       |
    | Project Standard 2019     | Project 标准版 2019 | ProjectStd2019Volume       |
    | Office Pro Plus 2019      | Office 专业增强版 2019 | ProPlus2019Volume          |
    | Office Standard 2019      | Office 标准版 2019 | Standard2019Volume         |
    | Publisher 2019            |                   | Publisher2019Volume        |
    | Visio Professional 2019   | Visio 专业版 2019 | VisioPro2019Volume         |
    | Visio Standard 2019       | Visio 标准版 2019 | VisioStd2019Volume         |
    | Word 2019                 |                   | Word2019Volume             |
    | Skype for Business 2019   | Skype 商业版 2019 | SkypeforBusiness2019Volume |
-   [Office 2016](https://www.microsoft.com/download/details.aspx?id=49164)


#### Language 元素 {#language-元素}

Language 定义要下载或安装的语言。如果定义了多个语言，首个语言决定了 UI 区域性、快捷方式、工具提示。

ID 属性的决定了具体下载、安装哪种语言。值 `MatchInstalled` 可以选择匹配已安装的
Office，`MatchOS` 可以选择匹配操作系统，也可以参考 [官方文档](https://docs.microsoft.com/en-us/deployoffice/overview-deploying-languages-microsoft-365-apps#languages-culture-codes-and-companion-proofing-languages) 直接指定区域性代码

<a id="table--tbl:language-list"></a>
<div class="table-caption">
  <span class="table-number"><a href="#table--tbl:language-list">Table 1</a>:</span>
  支持的常见语言列表
</div>

| 语言    | 英文名                | 区域性代码 (ll-CC) | 校对语言                          |
|-------|--------------------|---------------|-------------------------------|
| 阿拉伯语 | Arabic                | ar-SA         | 阿拉伯语、英语、法语              |
| 中文 (简体) | Chinese (Simplified)  | zh-CN         | 中文 (简体)、英语                 |
| 中文 (繁体) | Chinese (Traditional) | zh-TW         | 中文 (繁体)、英语                 |
| 英语    | English               | en-US         | 英语、法语、西班牙语              |
| 英语 (英国) | English UK            | en-GB         | 英语、爱尔兰语、苏格兰盖尔语、威尔士语 |
| 法语    | French                | fr-FR         | 法语、英语、德语、荷兰语、阿拉伯语、西班牙语 |
| 德语    | German                | de-DE         | 德语、英语、法语、意大利语        |
| 日语    | Japanese              | jp-JP         | 日语、英语                        |
| 韩语    | Korean                | ko-KR         | 韩语、英语                        |
| 俄语    | Russian               | ru-RU         | 俄语、英语、乌克兰语、德语        |
| 西班牙语 | Spanish               | es-ES         | 西班牙语、英语、法语、加泰罗尼亚语、加利西亚语、葡萄牙语 (巴西) |


#### ExcludeApp 元素 {#excludeapp-元素}

ExcludeApp 定义了不希望安装的应用程序，ID 属性为不安装的软件的 ID

| 产品                  | ID         |
|---------------------|------------|
| Access                | Access     |
| Excel                 | Excel      |
| OneDrive              | OneDrive   |
| OneDrive for Business | Groove     |
| OneNote               | OneNote    |
| Outlook               | Outlook    |
| PowerPoint            | PowerPoint |
| Publisher             | Publisher  |
| Skype for Business    | Lync       |
| Teams                 | Teams      |
| Word                  | Word       |


#### Remove 元素 {#remove-元素}

Remove 指定从旧的安装中删除哪些产品与语言，如果要删除指定语言必须同时指定子元素
Product 和 Language。如果要删除所有语言则不必指定子元素 Language。该元素不能作为
Add 的子元素

All
: 指定是否删除所有已安装的 Office (包含 Project 与 Visio)，此属性接受
    Boolean


#### Updates 元素 {#updates-元素}

Updates 定义如何在安装后更新 Office

Enabled (可选)
: 默认值为 TRUE，设置 Office 是否检查更新

Channel (可选)
: 与 Add 元素的 Channel 属性相同


#### RemoveMSI 元素 {#removemsi-元素}

可选元素，在安装指定产品前，是否删除 MSI 安装的任何 Office 、 Visio 、 Project

IgnoreProduct (可选)
: 指定忽略卸载的产品 ID


#### 示例配置 {#示例配置}

我们在此给出一些示例配置文件，以方便理解这些属性

-   安装 64 位 Office 专业增强版
    ```xml
    <Configuration>
      <Add OfficeClientEdition="64" Channel="PerpetualVL2019">
        <Product ID="ProPlus2019Volume">
          <Language ID="zh-CN" />
        </Product>
      </Add>
    </Configuration>
    ```
-   安装 64 位 Office 专业增强版、Visio 标准版、Project 标准版，并支持中文与英文，并移除之前的 MSI 安装
    ```xml
    <Configuration>
      <Add OfficeClientEdition="64" Channel="PerpetualVL2019">
        <Product ID="ProPlus2019Volume">
          <Language ID="zh-CN" />
          <Language ID="en-US" />
        </Product>
        <Product ID="VisioStd2019Volume">
          <Language ID="zh-CN" />
          <Language ID="en-US" />
        </Product>
        <Product ID="ProjectStd2019Volume">
          <Language ID="zh-CN" />
          <Language ID="en-US" />
        </Product>
      </Add>
      <RemoveMSI />
    </Configuration>
    ```


### 激活 Office {#激活-office}

以**管理员身份**打开 Powershell 或命令提示符，并输入命令即可激活

1.  进入 Office 目录，32 位安装在 `C:\Program Files (x86)\Microsoft
         Office\Office??` ，64 位安装在 `C:\Program Files\Microsoft Office\Office??`
    ，最后两位是数字，Office 这个数字好像是 16
    ```bat
    cd "C:\Program Files\Microsoft Office\Office16"
    ```
2.  设置对应 Office 版本的 GVLK，这里以 Word 2016 为例
    ```bat
    cscript ospp.vbs /inpkey:WXY84-JN2Q9-RBCCQ-3Q3J3-3PFJ6
    ```
3.  注册 KMS 服务器，`sethst` 设置的是地址，`setprt` 设置的是端口，如果端口是
    1688 则不需要设置
    ```bat
    rem 设置地址
    cscript ospp.vbs /sethst:example.com
    rem 设置端口
    cscript ospp.vbs /setprt:1688
    ```
4.  激活
    ```bat
    cscript ospp.vbs /act
    ```
5.  如果你希望查看 Office 的许可证状态，可以使用这条命令
    ```bat
    cscript ospp.vbs /dstatus
    ```


#### Office GVLK {#office-gvlk}

Office 的 GVLK 可以在 [官方文档](https://docs.microsoft.com/en-us/DeployOffice/vlactivation/gvlks) 中查看

-   Office LTSC 2021

    | 产品                          | 中译              | GVLK                          |
    |-----------------------------|-----------------|-------------------------------|
    | Office LTSC Professional Plus | Office LTSC 专业增强版 | FXYTK-NJJ8C-GB6DW-3DYQT-6F7TH |
    | Office LTSC Standard          | Office LTSC 标准版 | KDX7X-BNVR8-TXXGX-4Q7Y8-78VT3 |
    | Project Professional          | Project 专业版    | FTNWT-C6WBT-8HMGF-K9PRX-QV9H8 |
    | Project Standard              | Project 标准版    | J2JDC-NJCYY-9RGQ4-YXWMH-T3D4T |
    | Visio LTSC Professional       | Visio LTSC 专业版 | KNH8D-FGHT4-T8RK3-CTDYJ-K2HT4 |
    | Visio LTSC Standard           | Visio LTSC 标准版 | MJVNY-BYWPY-CWV6J-2RKRT-4M8QG |
    | Access LTSC                   |                   | WM8YG-YNGDD-4JHDC-PG3F4-FC4T4 |
    | Excel LTSC                    |                   | NWG3X-87C9K-TC7YY-BC2G7-G6RVC |
    | Outlook LTSC                  |                   | C9FM6-3N72F-HFJXB-TM3V9-T86R9 |
    | PowerPoint LTSC               |                   | TY7XF-NFRBR-KJ44C-G83KF-GX27K |
    | Publisher LTSC                |                   | 2MW9D-N4BXM-9VBPG-Q7W6M-KFBGQ |
    | Skype for Business LTSC       | Skype 商业版 LTSC | HWCXN-K3WBT-WJBKY-R8BD9-XK29P |
    | Word LTSC                     |                   | TN8H9-M34D3-Y64V9-TR72V-X79KV |
-   Office 2019

    | 产品                     | 中译         | GVLK                          |
    |------------------------|------------|-------------------------------|
    | Office Professional Plus | Office 专业增强版 | NMMKJ-6RK4F-KMJVX-8D9MJ-6MWKP |
    | Office Standard          | Office 标准版 | 6NWWJ-YQWMR-QKGCB-6TMB3-9D9HK |
    | Project Professional     | Project 专业版 | B4NPR-3FKK7-T2MBV-FRQ4W-PKD2B |
    | Project Standard         | Project 标准版 | C4F7P-NCP8C-6CQPT-MQHV9-JXD2M |
    | Visio Professional       | Visio 专业版 | 9BGNQ-K37YR-RQHF2-38RQ3-7VCBB |
    | Visio Standard           | Visio 标准版 | 7TQNQ-K3YQQ-3PFH7-CCPPM-X4VQ2 |
    | Access                   |              | 9N9PT-27V4Y-VJ2PD-YXFMF-YTFQT |
    | Excel                    |              | TMJWT-YYNMB-3BKTF-644FC-RVXBD |
    | Outlook                  |              | 7HD7K-N4PVK-BHBCQ-YWQRW-XW4VK |
    | PowerPoint               |              | RRNCX-C64HY-W2MM7-MCH9G-TJHMQ |
    | Publisher                |              | G2KWX-3NW6P-PY93R-JXK2T-C9Y9V |
    | Skype for Business       | Skype 商业版 | NCJ33-JHBBY-HTK98-MYCV8-HMKHJ |
    | Word                     |              | PBX3G-NWMT6-Q7XBW-PYJGG-WXD33 |
-   Office 2016

    | 产品                     | 中译         | GVLK                          |
    |------------------------|------------|-------------------------------|
    | Office Professional Plus | Office 专业增强版 | XQNVK-8JYDB-WJ9W3-YJ8YR-WFG99 |
    | Office Standard          | Office 标准版 | JNRGM-WHDWX-FJJG3-K47QV-DRTFM |
    | Project Professional     | Project 专业版 | YG9NW-3K39V-2T3HJ-93F3Q-G83KT |
    | Project Standard         | Project 标准版 | GNFHQ-F6YQM-KQDGJ-327XX-KQBVC |
    | Visio Professional       | Visio 专业版 | PD3PC-RHNGV-FXJ29-8JK7D-RJRJK |
    | Visio Standard           | Visio 标准版 | 7WHWN-4T7MP-G96JF-G33KR-W8GF4 |
    | Access                   |              | GNH9Y-D2J4T-FJHGG-QRVH7-QPFDW |
    | Excel                    |              | 9C2PK-NWTVB-JMPW8-BFT28-7FTBF |
    | OneNote                  |              | DR92N-9HTF2-97XKM-XW2WJ-XW3J6 |
    | Outlook                  |              | R69KK-NTPKF-7M3Q4-QYBHW-6MT9B |
    | PowerPoint               |              | J7MQP-HNJ4Y-WJ7YM-PFYGF-BY6C6 |
    | Publisher                |              | F47MM-N3XJP-TQXJ9-BP99D-8K837 |
    | Skype for Business       | Skype 商业版 | 869NQ-FJ69K-466HW-QYCP2-DDBV6 |
    | Word                     |              | WXY84-JN2Q9-RBCCQ-3Q3J3-3PFJ6 |
