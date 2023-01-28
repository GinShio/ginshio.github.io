# 搭建邮箱服务器


搭建邮局服务器的想法之前一直都有，不过一直没有尝试，国庆的时候从阿里云换到了腾讯云的时候尝试直接使用 `postfix` 和 `dovecot` 搭建，尝试了大概3天被劝退了，重新使用现成的解决方案也算终于搭建好了，可以愉快的使用自建邮箱了 (~~可以愉快的装逼了~~

{{< admonition type="info" >}}
更新了 mailu 的搭建，虽然 mailu 相比 mailcow 可以使用宿主机的数据库，不过 mailu
配置 SMTPS / IMAPS / POP3S 不如 mailcow 简单方便，也没怎么研究，目前没有切换到
mailu 的打算
{{< /admonition >}}

{{< admonition type="warning" >}}
打算在更换服务器之后不再维护邮箱服务，装逼不存在的
{{< /admonition >}}


## 部署 {#部署}

开始搭建服务器，以下采用域名 (`example.com`) 和 IP (`1.1.1.1`)，安装在
`/mailcow`，使用主机的nginx反向代理，部署之前我们首先定义一些Shell变量，以便之后使用，请根据自己的需求更改

```shell
path_to="/path/to"
mailcow_path="${path_to}/mailcow" # mailcow 所在目录
mailu_path="${path_to}/mailu"
mail_host="mail.example.com"
mail_ip="1.1.1.1"
db_user="example_user" # 数据库用户 (Mailu使用宿主机PostgreSQL时使用)
db_passwd="example_password" # 数据库密码 (Mailu使用宿主机PostgreSQL时使用)
db_name="example_db" # 数据库名称  (Mailu使用宿主机PostgreSQL时使用)
http_port="8080"
https_port="8443"
cert_path="/ssl/path/to/cert/" # 证书存放目录
cert_file="${cert_path}/cert.pem" # 域名证书
key_file="${cert_path}/key.pem" # 域名证书密钥
ca_file="${cert_path}/intermediate_CA.pem" # 域名证书颁发者证书
```

另外，由于webmail对 `S/MIME` 与 `PGP/MIME` 的支持并不好，我们将在服务器上禁止
webmail，使用本地的邮件客户端收发邮件，以便更好的使用加密、签名功能，如有需要请自行开启webmail。


### DNS {#dns}

DNS设置是一个邮件服务器的重中之重，为了让我们可以发出邮件和收到邮件，防止邮件被拒收或者进入垃圾箱被识别成垃圾邮件等，当然不是配置好了就不会进垃圾邮箱，不配置肯定会有问题。

除了上述DNS解析之外，还需要配置 **DKIM** 和 **PTR**，DKIM在我们搭建好服务之后配置，
PTR需要向运营商提交工单申请 (阿里云和腾讯云是这样的)，如果你没有配置ptr解析那么你可能会上一些黑名单。

DKIM 同样的也是 TXT 类型的 DNS 解析，在部署完成后由指定选择器生成 DKIM，之后设置 DNS 解析

| 类型 | 记录                        | 记录值     |
|----|---------------------------|---------|
| TXT | &lt;selector&gt;._domainkey | DKIM_VALUE |


### 黑名单 {#黑名单}

在互联网上发送邮件不是可以为所欲为的，邮局服务有一套反垃圾邮件机制，当你的IP上了黑名单时，从这个IP发出去的邮件很容易进入垃圾邮箱或拒收，请珍惜自己的IP，不过可以尝试在检测上了哪些服务商的黑名单，并尝试解除黑名单，以下给出一些检测或申请去除反垃圾邮件网址

-   [MXToolBox](https://mxtoolbox.com/SuperTool.aspx)
-   <http://multirbl.valli.org/>


### Mailcow:dockerized {#mailcow-dockerized}

[Mailcow:dockerized](https://mailcow.email/) 是一个使用docker搭建的标准邮件服务器，集成了邮局、webmail、管理以及反垃圾邮件等功能，过程相对全面，不过缺点是比较吃资源，并且不支持
**Synology/QNAP** 或 **OpenVZ**、**LXC** 等虚拟化方式，并且不能使用 `CentOS 7/8` 源中的 Docker 包，要求真多。。。消耗资源的主要原因是 `ClamAV` 和 `Solr`，即杀毒功能和搜索功能，如果不需要可以关闭。

| 资源 | 需求          |
|----|-------------|
| CPU | 1GHz          |
| RAM | 最少4G (包含交换空间) |
| 硬盘 | 20GiB (不包含邮件) |

以下列出Mailcow:dockerized使用的端口 (HTTP和HTTPS为我们自定义的端口)

| 服务                 | 协议 | 端口      | 容器            |
|--------------------|----|---------|---------------|
| Postfix SMTP / SMTPS | TCP | 25 / 465  | postfix-mailcow |
| Postfix Submission   | TCP | 587       | postfix-mailcow |
| Dovecot IMAP / IMAPS | TCP | 143 / 993 | dovecot-mailcow |
| Dovecot POP3 / POP3S | TCP | 110 / 995 | dovecot-mailcow |
| Dovecot ManageSieve  | TCP | 4190      | dovecot-mailcow |
| HTTP / HTTPS         | TCP | 80 / 443  | nginx-mailcow   |


#### 部署 Mailcow:dockerized {#部署-mailcow-dockerized}

现在开始正式的搭建邮箱服务器

```shell
cd ${path_to}
git clone https://github.com/mailcow/mailcow-dockerized mailcow && cd mailcow
echo ${email_host} | ./generate_config.sh
sed -ie "s/HTTP_PORT=.*/HTTP_PORT=${http_port}/" mailcow.conf # HTTP端口
sed -ie "s/HTTPS_PORT=.*/HTTPS_PORT=${https_port}/" mailcow.conf # HTTPS端口
sed -i "s/TZ=.*/TZ=Asia\/Shanghai/" mailcow.conf # 时区
sed -i "s/SKIP_LETS_ENCRYPT=.*/SKIP_LETS_ENCRYPT=y/" mailcow.conf # 证书申请 (不需要)
sed -i "s/SKIP_SOGO=.*/SKIP_SOGO=y/" mailcow.conf # webmail (不需要)
sed -i "s/SKIP_SOLR=.*/SKIP_SOLR=n/" mailcow.conf # 搜索 (不需要)
sed -i "s/enable_ipv6: true/enable_ipv6: false/" docker-compose.yml # 关闭ipv6
```

下面给出Nginx配置文件，Apache 配置文件请参见 [官方文档](https://mailcow.github.io/mailcow-dockerized-docs/firststeps-rp/#apache-24)

```text
server {
  listen 80;
  listen [::]:80;
  server_name mail.example.com;
  return 301 https://$host$request_uri;
}
server {
  listen 443 ssl http2;
  listen [::]:443 ssl http2;
  server_name mail.example.com;

  ssl_certificate /ssl/domain/cert.pem;
  ssl_certificate_key /ssl/domain/key.pem;
  ssl_session_timeout 2h;
  ssl_session_cache shared:mailcow:16m;
  ssl_session_tickets off;

  # See https://ssl-config.mozilla.org/#server=nginx for the latest ssl settings recommendations
  # An example config is given below
  ssl_protocols TLSv1.2 TLSv1.3;
  ssl_ciphers HIGH:!aNULL:!MD5:!SHA1:!kRSA;
  ssl_prefer_server_ciphers off;

  location /Microsoft-Server-ActiveSync {
    proxy_pass http://127.0.0.1:8080/Microsoft-Server-ActiveSync;
    proxy_set_header Host $http_host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_connect_timeout 75;
    proxy_send_timeout 3650;
    proxy_read_timeout 3650;
    proxy_buffers 24 256k;
    client_body_buffer_size 512k;
    client_max_body_size 0;
  }

  location / {
    proxy_pass http://127.0.0.1:8080/;
    proxy_set_header Host $http_host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    client_max_body_size 0;
  }
}
```

以上全部完成后，mailcow 基本配置完成，只需要启动起服务即可，默认用户密码 `admin` / `moohoo`

```shell
cd ${mailcow_path}
docker-compose pull
docker-compose up -d
```


#### 为 Mailcow:dockerized 配置 TLS {#为-mailcow-dockerized-配置-tls}

现在我们可以为SMTP与IMAP服务加入TLS，假设我们已经对域名 `mail.example.com` 申请了证书，对 postfix 与 dovecot 配置证书前，我们需要根据 postfix 文档先将我们自己的证书与提供商的证书按顺序存放在同一文件下，并且文件后缀为 **.pem**，并存放在
mailcow的ssl文件夹下

```shell
cat ${cert_file} ${ca_file} > ${mailcow_path}/data/assets/ssl/cert.pem
cp ${key_file} ${mailcow_path}/data/assets/ssl/key.pem
```

证书保存完毕后，对 postfix 与 dovecot 进行配置，配置完成重启服务即可

```shell
# postfix
sed -i "s/smtp_tls_security_level.*/smtp_tls_security_level = dane/" data/conf/postfix/main.cf
sed -i "s/smtp_tls_CAfile.*/smtp_tls_CAfile = \/etc\/ssl\/mail\/cert.pem/" data/conf/postfix/main.cf
sed -i "s/smtp_tls_cert_file.*/smtp_tls_cert_file = \/etc\/ssl\/mail\/cert.pem/" data/conf/postfix/main.cf
sed -i "s/smtp_tls_key_file.*/smtp_tls_key_file = \/etc\/ssl\/mail\/key.pem/" data/conf/postfix/main.cf
sed -i "s/smtpd_tls_security_level.*/smtpd_tls_security_level = may/" data/conf/postfix/main.cf
sed -i "s/smtpd_tls_CAfile.*/smtpd_tls_CAfile = \/etc\/ssl\/mail\/cert.pem/" data/conf/postfix/main.cf
sed -i "s/smtpd_tls_cert_file.*/smtpd_tls_cert_file = \/etc\/ssl\/mail\/cert.pem/" data/conf/postfix/main.cf
sed -i "s/smtpd_tls_key_file.*/smtpd_tls_key_file = \/etc\/ssl\/mail\/key.pem/" data/conf/postfix/main.cf
# dovecot
sed -i "s/ssl_cert.*/ssl_cert = <\/etc\/ssl\/mail\/cert.pem/" data/conf/dovecot/dovecot.conf
sed -i "s/ssl_key.*/ssl_key = <\/etc\/ssl\/mail\/key.pem/" data/conf/dovecot/dovecot.conf
# restart
docker-compose restart postfix-mailcow dovecot-mailcow
```


### Mailu.io {#mailu-dot-io}

[Mailu](https://mailu.io/) 是一个使用docker搭建的轻量级标准邮件服务器，继承自poste.io，支持x86架构，集成了邮局、webmail、管理以及反垃圾邮件等功能。webmail可以选用roundcube、
rainloop或禁止webmail，而数据库支持sqlite、MySQL与PostgreSQL，最重要的是 MySQL
和 PostgreSQL 可以选择使用镜像或宿主机 (1.9开始将删除docker镜像)。

| 资源 | 需求 |
|----|----|
| CPU | x86  |
| RAM | 建议2G |


#### 生成配置文件 {#生成配置文件}

Mailu官方提供了 [在线生成配置文件](https://setup.mailu.io/)，可以根据我们的需求生成配置文件，我们将使用
Docker-Compose 搭建 master 版本，并将生成的配置文件下载到服务器上。

initial configuration
: 进行初始化的配置，比如路径、主域名、TLS、管理界面等，由于我个人喜好自己生成
    TLS证书，所以选择 mail 禁止mailu帮我生成证书，但是对邮件进行TLS加密，如果需要mailu生成TLS证书选择带有 `letsencrypt` 的选项

    {{< figure src="/images/mailu-initial-configuration.png" width="64%" >}}

pick some features
: 进行功能配置，我们禁用了webmail，可以根据个人喜好选择合适自己的webmail。剩下的三个选项分别是杀毒 (内存杀手)、WebDAV以及邮件代收，根据自己的需求选择

    {{< figure src="/images/mailu-pick-some-features.png" width="64%" >}}

expose Mailu to the world
: 配置IP与主机名，监听地址填写自己的服务器IP，hostname填写服务器的长主机名

    {{< figure src="/images/mailu-expose-Mailu-to-the-world.png" width="64%" >}}

database preferences
: 数据库设置，这里我们选择使用宿主机的PostgreSQL，URL填写的是Docker在宿主机上默认开启的子网

    {{< figure src="/images/mailu-database-preferences.png" width="64%" >}}


#### 部署 Mailu {#部署-mailu}

现在开始正式的搭建邮箱服务器，假设你已经将配置文件下载到了 `mailu_path` 中，我们修改一下配置文件

```shell
sed -ie "s/MESSAGE_SIZE_LIMIT=.*/MESSAGE_SIZE_LIMIT=100000000/" mailu.env
sed -i "/::1/d" docker-compose.yml
sed -ie "s/${mail_ip}://g" docker-compose.yml
sed -ie "s/80:80/${http_port}:80/" docker-compose.yml # HTTP端口
sed -ie "s/443:443/${https_port}:443/" docker-compose.yml # HTTPS端口
```

因为mailu配置的TLS选项是mail，所以我们使宿主机的Nginx反向代理到mailu-front监听的
HTTP上即可

```text
server {
  listen 80;
  listen [::]:80;
  server_name mail.example.com;
  return 301 https://$host$request_uri;
}
server {
  listen 443 ssl http2;
  listen [::]:443 ssl http2;
  server_name mail.example.com;

  ssl_certificate /ssl/domain/cert.pem;
  ssl_certificate_key /ssl/domain/key.pem;
  # See https://ssl-config.mozilla.org/#server=nginx for the latest ssl settings recommendations
  ssl_protocols TLSv1.2 TLSv1.3;
  ssl_ciphers HIGH:!aNULL:!MD5:!SHA1:!kRSA;
  ssl_prefer_server_ciphers off;
  ssl_session_timeout 2h;
  ssl_session_cache shared:mailu:8m;
  ssl_session_tickets off;

  proxy_set_header Host $http_host;
  proxy_set_header X-Real-IP $remote_addr;
  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  proxy_set_header X-Forwarded-Proto $scheme;

  location / {
    proxy_pass http://127.0.0.1:8080/;
  }
  location /admin {
    proxy_pass http://127.0.0.1:8080/admin/;
  }
  # location /webmail {
  #   proxy_pass http://127.0.0.1:8080/webmail/;
  # }
}
```

宿主机的PostgreSQL也需要稍微配置一下

```shell
sudo adduser --disabled-login --gecos 'Mailu' ${db_user}
sudo -u postgres -H psql -d template1 -c "CREATE USER ${db_user} WITH PASSWORD '${db_passwd}' CREATEDB;"
sudo -u postgres -H psql -d template1 -c "CREATE DATABASE ${db_name} OWNER ${db_user};"
sudo -u postgres -H psql -h localhost -d ${db_name} -c "create extension citext;"
echo "host    ${db_name}    ${db_user}    192.168.203.0/24    md5" >> /etc/postgresql/12/main/pg_hba.conf
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '0.0.0.0'/" /etc/postgresql/12/main/postgresql.conf
systemctl restart postgresql
```

以上全部完成后 mailu 基本配置完成，只需要根据最后一步，启动起服务并设置管理员密码即可

```shell
cd ${mailu_path}
docker-compose -p mailu up -d
docker-compose -p mailu exec admin flask mailu admin admin ${mail_host#*.} PASSWORD
```


## 安全 {#安全}

我们已经配置了TLS，对于邮件的传输过程来说我们的邮件是安全的，但是对于服务提供商来说还是可以随意浏览我们的邮件内容的，如果你希望重要的内容不被服务商所浏览，可以尝试使用对邮件加密的方式。邮件加密并不是将邮件转换为一个带密码的文件，而是使用非对称加密套件，在MUA中进行加密、签名等，MTA只负责传输邮件而不能检测邮件的内容。如果你想使用加密的方式向我发送邮件，请保存以下公钥:

-   [OpenPGP](https://github.com/GinShio/GinShio/blob/master/pgp_public_key)
-   [S/MIME (iris@ginshio.org)](https://github.com/GinShio/GinShio/blob/master/iris_smime_public_key)
-   [S/MIME (ginshio78@gmail.com)](https://github.com/GinShio/GinShio/blob/master/gmail_smime_public_key)

由于加密邮件是MUA行为，一般情况服务提供商的Webmail并不支持加密邮件，部分提供加密功能的提供商如果需要你上传私钥到他们的服务器，请保持警惕，私钥可以解密你的邮件。以下列出了常见的支持加密的MUA:

-   [Microsoft Outlook](https://support.microsoft.com/zh-cn/outlook) (S/MIME)
-   [Apple Mail](https://support.apple.com/mail) (S/MIME)
-   [Mozilla Thunderbird](https://www.thunderbird.net/) (OpenPGP 和 S/MIME)
-   [KDE Kontact KMail](http://kontact.kde.org/) (OpenPGP 和 S/MIME)
-   [GNOME Evolution](https://wiki.gnome.org/Apps/Evolution) (OpenPGP 和 S/MIME)
-   [Mutt](http://www.mutt.org/) (OpenPGP 和 S/MIME)


### S/MIME {#s-mime}

安全多功能互联网邮件扩展 (S/MIME) 是基于 **PKI** 的符合 **X.509** 格式的非对称密钥协议，提供了数字签名、加密功能。发送邮件时，数字签名会以 `smime.p7s` 的附件跟随邮件发送，如GMail的网页端就支持验证签名，如果是加密邮件则整封邮件被加密后以
`smime.p7m` 的附件发送。双方互发信息之前，如果没有对方公钥那么无法加密邮件，需要先互相发送签名的邮件用以交换公钥，导入公钥后可以开始发送加密邮件。你可以在
[Actalis](https://www.actalis.it/) 申请为期一年的免费 S/MIME 证书，为你邮件加密开启第一步，请保存好申请到的证书 (.pfx文件)、密码以及CRP。

从 Actalis 申请来的 S/MIME 证书是 **PKCS** **#12** 格式，这种格式被称为 `安全包裹`
，通常这种文件用于打包私钥以及有关的 X.509 证书。我们可以使用 openssl 的 pkcs12
进行创建、解析、读取。

如果需要查看安全包裹信息，可以使用如下命令，这会输出所有证书和私钥

```shell
openssl pkcs12 -in file -info -nodes
```

如果你希望将私钥加密输出，可以去除 `-nodes` 参数，下表举例了输出 PKCS12 文件信息时的一些控制参数

| 参数     | 含义      | 参数     | 含义     | 参数     | 含义      |
|--------|---------|--------|--------|--------|---------|
| -nokeys  | 不输出私钥 | -nocerts | 不输出证书 | -clcerts | 仅输出客户证书 |
| -cacerts | 仅输出 CA 证书 | -noout   | 没有输出，仅验证 | -descert | 3DES 算法加密 |
| -nodes   | 不加密私钥 |          |          |          |           |

对于导出到文件，可以添加 `-out` 参数来指定导出的文件，依然可以使用 `-nokeys` 与
`-nocerts` 来决定导出的是证书还是密钥，导出密钥时记得不要加密密钥


### OpenPGP {#openpgp}

OpenPGP标准是一种非对称的非对称密钥协议，提供了加密、签名等工程，OpenGPG是通过信任网络机制确保之间的密钥认证。相比于 S/MIME 而言，OpenGPG 在邮件方便被支持的更少，比如Gmail可以在webmail中验证S/MIME签名，但是并不支持 PGP/MIME。


## 推荐阅读 {#推荐阅读}

-   [Outlook 反垃圾邮件策略指南](https://sendersupport.olc.protection.outlook.com/pm/policies.aspx)
-   [SPF 记录：原理、语法及配置方法简介](http://www.renfei.org/blog/introduction-to-spf.html)
-   [DMARC 是什么？](https://www.cnblogs.com/dmarcly/p/10947796.html)
-   [了解 S/MIME](https://docs.microsoft.com/zh-cn/previous-versions/exchange-server/exchange-server-2000/aa995740(v=exchg.65))
-   [电子邮件加密指南](https://emailselfdefense.fsf.org/zh-hans/)
-   [在 Thunderbird 中使用 OpenPGP —— 怎么做以及问题解答](https://support.mozilla.org/zh-CN/kb/thunderbird-openpgp#w_thunderbird-zhi-chi-openpgp-ma)
-   [Mailcow:dockerized官方文档](https://mailcow.github.io/mailcow-dockerized-docs/)
-   [使用 mailcow:dockerized 搭建邮件服务器](https://low.bi/p/r7VbxEKo3zA)
-   [Mailu.io官方文档](https://mailu.io/)
