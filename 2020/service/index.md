# 在服务器上部署一些服务


个人使用的是腾讯云的轻量服务器，系统镜像选择的是 Debian 11，搭建的服务有 博客
[HUGO](https://gohugo.io/) 、私有网盘 [Nextcloud](https://nextcloud.com/) 以及 Git服务器 [GitLab](https://about.gitlab.com/)

目前使用的是 Debian GNU/Linux 11 (bullseye) 搭建服务器，当然用的是 fish 作为
shell

```fish
bash -c "cat <<- EOF | sudo tee /etc/apt/sources.list
deb https://mirrors.ustc.edu.cn/debian/ bullseye main contrib non-free
deb https://mirrors.ustc.edu.cn/debian/ bullseye-updates main contrib non-free
deb https://mirrors.ustc.edu.cn/debian/ bullseye-backports main contrib non-free
deb https://mirrors.ustc.edu.cn/debian-security bullseye-security main contrib non-free

# deb-src https://mirrors.ustc.edu.cn/debian/ bullseye main contrib non-free
# deb-src https://mirrors.ustc.edu.cn/debian/ bullseye-updates main contrib non-free
# deb-src https://mirrors.ustc.edu.cn/debian/ bullseye-backports main contrib non-free
# deb-src https://mirrors.ustc.edu.cn/debian-security bullseye-security main contrib non-free
EOF"
sudo apt update -y && sudo apt upgrade -y
```

一下服务搭建时，域名统一使用 example.com，请根据自己的情况修改对应的配置，用到一些基础依赖请自行安装

-   Nginx
-   Git
-   PHP
-   PostgreSQL
-   Redis


## Nextcloud {#nextcloud}

Nextcloud 是 [ownCloud](https://owncloud.com/) 项目的一个分支，一个开源的私有云盘应用，官方提供了包括 桌面以及移动系统的客户端。

定义一些变量

```fish
set fpm_path /etc/php/7.4/fpm
set nextcloud_version 23.0.4
set nextcloud_path /path/to/nextcloud
set nextcloud_host example.com
set nextcloud_db_user nextcloud
set nextcloud_db_passwd YourPassword
set nextcloud_db_name nextcloud
```


### Nextcloud 依赖 {#nextcloud-依赖}

Nextcloud 依赖 PHP 运行时以及数据库 (MySQL 5.7+ / MariaDB 10.2+ 或 PostgreSQL)

```fish
apt install -y nginx postgresql \
    php php-fpm php-cli php-mysql php-pgsql php-sqlite3 php-redis \
    php-apcu php-memcached php-bcmath php-intl php-mbstring php-json php-xml \
    php-curl php-imagick php-gd php-zip php-gmp php-ctype php-dom php-iconv
```

PHP
: 修改 php-fpm 的配置文件
    ```fish
    cd $fpm_path
    # php config
    sed -i "s/memory_limit = .*/memory_limit = 512M/" php.ini
    sed -i "s/;date.timezone.*/date.timezone = UTC/" php.ini
    sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=1/" php.ini
    sed -i "s/upload_max_filesize = .*/upload_max_filesize = 4096M/" php.ini
    sed -i "s/post_max_size = .*/post_max_size = 4096M/" php.ini
    sed -i "s/max_input_time = .*/max_input_time = 480/" php.ini
    sed -i "s/max_execution_time = .*/max_execution_time = 360/" php.ini
    sed -i "s/pm.max_children = .*/pm.max_children = 32/" pool.d/www.conf
    sed -i "s/pm.min_spare_servers = .*/pm.min_spare_servers = 1/" pool.d/www.conf
    sed -i "s/pm.max_spare_servers = .*/pm.max_spare_servers = 8/" pool.d/www.conf
    sed -i "s/pm.start_servers = .*/pm.start_servers = 4/" pool.d/www.conf
    sed -i "s/;clear_env = no/clear_env = no/" pool.d/www.conf
    # opcache config
    sed -i "s/;opcache.enable=1/opcache.enable=1/" php.ini
    sed -i "s/;opcache.memory_consumption=128/opcache.memory_consumption=128/" php.ini
    sed -i "s/;opcache.interned_strings_buffer=8/opcache.interned_strings_buffer=8/" php.ini
    sed -i "s/;opcache.max_accelerated_files=10000/opcache.max_accelerated_files=10000/" php.ini
    sed -i "s/;opcache.revalidate_freq=2/opcache.revalidate_freq=1/" php.ini
    # apc config
    bash -c "cat <<-EOF | sudo tee -a php.ini
    [apc]
    apc.cache_by_default = on
    apc.enable_cli = on
    apc.enable = on
    apc.file_update_protection = 2
    EOF"
    echo "apc.enable_cli=on" |sudo tee -a /etc/php/7.4/cli/conf.d/20-apcu.ini
    # restart
    systemctl restart php7.4-fpm
    ```


PostgreSQL
: 创建用户 **nextcloud** 和数据库 **nextcloud_db**
    ```fish
    sudo useradd $nextcloud_db_user --create-home --shell /sbin/nologin
    sudo -u postgres -H psql -c "CREATE USER $nextcloud_db_user WITH PASSWORD '$nextcloud_db_passwd'"
    sudo -u postgres -H psql -c "CREATE DATABASE $nextcloud_db_name OWNER $nextcloud_db_user"
    ```


Nginxm
: 配置网站，修改 [官方示例配置文件](https://docs.nextcloud.com/server/20/admin_manual/installation/nginx.html#nextcloud-in-the-webroot-of-nginx) 并保存在
    `/etc/nginx/sites-available/nextcloud`
    ```fish
    ln -sf /etc/nginx/sites-available/nextcloud /etc/nginx/sites-enabled/
    systemctl restart nginx
    ```


### Nextcloud 安装 {#nextcloud-安装}

[下载](https://download.nextcloud.com/server/releases) 你需要的版本并解压到目录中

```fish
sudo -E wget https://download.nextcloud.com/server/releases/nextcloud-"$nextcloud_version".tar.bz2
sudo mkdir -p $nextcloud_path
sudo tar -jxvf nextcloud-"$nextcloud_version".tar.bz2 -C $nextcloud_path
sudo chown -R www-data:www-data $nextcloud_path
```

准备工作完成后，进入网页，设置管理员帐号和数据库。


### Nextcloud 开启邮件服务 {#nextcloud-开启邮件服务}

配置邮箱服务器前需要先修改nextcloud的代码，如下

```fish
cd /path/to/nextcloud
sed -i \
    "s/\$streamContext = .*;/\$streamContext = stream_context_create(array('ssl'=>['verify_peer'=>false, 'verify_peer_name'=>false, 'allow_self_signed'=>true]));/" \
    3rdparty/swiftmailer/swiftmailer/lib/classes/Swift/Transport/StreamBuffer.php
systemctl restart php7.4-fpm
```

登录管理员帐号进行邮箱服务器配置即可

| 字段  | 值                   |
|-----|---------------------|
| 发送模式 | SMTP                 |
| 加密  | SSL/TLS              |
| 来自地址 | noreply@example.com  |
| 认证方式 | 登录                 |
| 需要认证 | true                 |
| 服务器地址 | mail.example.com:465 |
| 证书  | noreply@example.com  |
| 密码  | YourPassword         |


### Nextcloud 优化 {#nextcloud-优化}

优化最常见的手段是添加缓存，这里是在配置文件中添加 Redis (uds) 和 APCu 支持

```php
'memcache.local' => '\OC\Memcache\APCu',
'memcache.distributed' => '\OC\Memcache\Redis',
'memcache.locking' => '\OC\Memcache\Redis',
'redis' => [
  'host'     => '/var/run/redis/redis.sock',
  'port'     => 0,
  'dbindex'  => 0,
  'timeout'  => 2,
],
```

还有就是开启缩略图，比如最大只有 `512x512` 的缩略图，可以提高访问速度，但是访问可能体验极差，毕竟点开图片你就给我看这个

```php
'enable_previews' => true,
'preview_max_x' => 512,
'preview_max_y' => 512,
'preview_max_scale_factor' => 1,
```

至于默认的 JPEG 质量是 90，有点高的话，你可以用以下命令调低 (比如到 60)

```fish
occ config:app:set preview jpeg_quality --value="60"
```

上传大文件的话，可以看看官方的[相关文档](https://docs.nextcloud.com/server/stable/admin_manual/configuration_files/big_file_upload_configuration.html)


### Nextcloud 插件 {#nextcloud-插件}

Nextcloud 不仅自带了很多功能，也提供了插件用于扩展功能，官方称作 Apps，以下个人推荐一些插件，欢迎补充

Announcement center
: 公告发布

Registration
: 注册功能

File access control
: 文件访问控制，可以添加规则来控制管理用户对文件的操作，参见 [工作流](https://nextcloud.com/workflow)

Music
: 音乐播放器

Full text search
: 全文搜索


## GitLab {#gitlab}

GitLab 是开源的基于git的 web **DevOps生命周期工具**​，提供了​<span class="underline">Git仓库</span>​、​<span class="underline">问题追踪</span>​和​<span class="underline">CI/CD</span>​等功能。分为社区版和企业版，使用相同内核，部分功能社区版没有提供。
Gitlab 相较消耗资源，官方推荐的最低要求为 **4C4G** 可以最多支持500用户， **8C8G** 最多支持1000用户，具体的使用受到​<span class="underline">用户的活跃程度</span>​、​<span class="underline">CI/CD</span>​、​<span class="underline">修改大小</span>​等因素影响。

由于暂时不需要，没有安装 Gitlab Pages，Gitlab的安装依赖 git 用户，以下是目录结构

```text
/home/git
├── gitaly
├── gitlab
├── gitlab-shell
├── gitlab-workhorse
├── go
└── repositories
```


### Gitlab 组件 {#gitlab-组件}

{{< figure src="https://docs.gitlab.com/ee/development/img/architecture_simplified_v14_9.png" width="36%" >}}

Gitaly
: 处理所有的 git 操作

GitLab Shell
: 处理基于 SSH 的 git 会话 与 SSH密钥

GitLab Workhorse
: 反向代理服务器，处理与Rails无关的请求，Git Pull/Push 请求 和 到Rails的连接，减轻Web服务的压力，帮助整体加快Gitlab的速度

Unicorn / Puma
: Gitlab 自身的 Web 服务器，提供面向用户的功能，Gitlab 13.0 起默认使用 Puma

Sidekiq
: 后台任务服务器，从Redis队列中提取任务并进行处理

GitLab Pages
: 允许直接从仓库发布静态网站

Gitlab Runner
: Gitlab CI/CD 所关联的任务处理器

Nginx
: Web 服务器

PostgreSQL
: 数据库


### Gitlab 依赖 {#gitlab-依赖}

目前Gitlab最新版本为 **v14.8** ，下列表是部分依赖，细明详见 [安装最低要求](https://docs.gitlab.com/14.8/ee/install/requirements.html)

| Software   | Minimum Version | Notes                                        |
|------------|-----------------|----------------------------------------------|
| Ruby       | 2.7             | 自 GitLab 13.6 起最低要求 v2.7，暂不支持 Ruby 3.0 |
| GoLang     | 1.16            |                                              |
| Node.js    | 12.22.1         | GitLab 使用 webpack 编译前端资源，推荐使用 Node.js 14.x |
| yarn       | 1.22.x          | GitLab 使用 Yarn 管理 Js 依赖，暂不支持 Yarn 2 |
| Redis      | 4.0             | GitLab 13.0 起最低要求 4.0，推荐使用 Redis 6.0 |
| PostgreSQL | 13              | GitLab 13.0 最低要求 pgsql 12，14.0 最低要求 pgsql 13 |
| Git        | 2.33.x          |                                              |
| Nginx      |                 |                                              |

另外需要注意，GitLab 支持的 pgsql 扩展主要有三个，在不同版本有所支持

-   `pg_trgm` 最低要求 GitLab 版本为 8.6
-   `plpgsql` 最低要求 GitLab 版本为 11.7
-   `btree_gist` 最低要求 GitLab 版本为 13.1

安装相关依赖，建立数据库，将 Redis 设置为 Unix Domain Socket (UDS) 连接

-   定义变量
    ```fish
    set gitlab_version 14-10-stable
    set gitlab_path /home/git/gitlab
    set gitaly_path /home/git/gitaly
    set gitlab_host example.com
    set gitlab_db_passwd YourPassword
    ```
-   安装相关依赖
    ```fish
    # install dependencies
    sudo apt install -y \
        build-essential zlib1g-dev libyaml-dev libssl-dev libgdbm-dev libre2-dev \
        libreadline-dev libncurses5-dev libffi-dev curl openssh-server libxml2-dev \
        libxslt1-dev libcurl4-openssl-dev libicu-dev logrotate rsync python3-docutils \
        pkg-config cmake runit-systemd libkrb5-dev graphicsmagick libimage-exiftool-perl
    ```

-   安装 Git
    ```fish
    # install git
    sudo apt install -y \
        libcurl4-openssl-dev libexpat1-dev gettext libz-dev \
        libssl-dev libpcre2-dev build-essential git-core
    git clone https://gitlab.com/gitlab-org/gitaly.git -b $gitlab_version /tmp/gitaly
    cd /tmp/gitaly
    sudo make git GIT_PREFIX=/usr/local
    sudo apt remove -y git-core
    sudo apt autoremove
    ```
    需要注意，这种方法安装的 Git 需要修改配置文件 `config/gitlab.yml` 中的 git 路径
    ```yaml
    git:
      bin_path: /usr/local/bin/git
    ```

-   安装 Ruby
    ```fish
    mkdir /tmp/ruby && cd /tmp/ruby
    curl --remote-name --location --progress-bar "https://cache.ruby-lang.org/pub/ruby/2.7/ruby-2.7.4.tar.gz"
    echo '3043099089608859fc8cce7f9fdccaa1f53a462457e3838ec3b25a7d609fbc5b ruby-2.7.4.tar.gz' | sha256sum -c - && tar xzf ruby-2.7.4.tar.gz
    cd ruby-2.7.4
    ./configure --disable-install-rdoc --enable-shared
    make
    sudo make install
    ```

-   安装 GoLang
    ```fish
    sudo rm -rf /usr/local/go
    curl --remote-name --location --progress-bar "https://go.dev/dl/go1.16.10.linux-amd64.tar.gz"
    echo '414cd18ce1d193769b9e97d2401ad718755ab47816e13b2a1cde203d263b55cf  go1.16.10.linux-amd64.tar.gz' | shasum -a256 -c - && \
      sudo tar -C /usr/local -xzf go1.16.10.linux-amd64.tar.gz
    sudo ln -sf /usr/local/go/bin/{go,gofmt} /usr/local/bin/
    rm go1.16.10.linux-amd64.tar.gz
    ```

-   安装 Node
    ```fish
    # install node v16.x
    curl --location "https://deb.nodesource.com/setup_16.x" | sudo bash -
    sudo apt-get install -y nodejs
    npm install --global yarn
    ```

-   安装并配置数据库
    ```fish
    sudo useradd git --create-home --shell /sbin/nologin
    sudo apt install -y postgresql postgresql-client libpq-dev postgresql-contrib
    sudo -u postgres psql -d template1 -c "CREATE USER git WITH PASSWORD '$gitlab_db_passwd' CREATEDB;"
    sudo -u postgres psql -d template1 -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;"
    sudo -u postgres psql -d template1 -c "CREATE EXTENSION IF NOT EXISTS btree_gist";
    sudo -u postgres psql -d template1 -c "CREATE DATABASE gitlabhq_production OWNER git;"
    ```
    检查 `pg_trgm` 扩展是否启用
    ```sql
    SELECT true AS enabled
    FROM pg_available_extensions
    WHERE name = 'pg_trgm'
    AND installed_version IS NOT NULL;
    ```
    检查 `btree_gist` 扩展是否启用
    ```sql
    SELECT true AS enabled
    FROM pg_available_extensions
    WHERE name = 'btree_gist'
    AND installed_version IS NOT NULL;
    ```

-   安装并配置 Redis
    ```fish
    sudo apt install redis-server
    sudo cp /etc/redis/redis.conf /etc/redis/redis.conf.orig
    sudo sed 's/^port .*/port 0/' /etc/redis/redis.conf.orig | sudo tee /etc/redis/redis.conf
    echo 'unixsocket /var/run/redis/redis.sock' | sudo tee -a /etc/redis/redis.conf
    echo 'unixsocketperm 770' | sudo tee -a /etc/redis/redis.conf
    sudo mkdir -p /var/run/redis
    sudo chown redis:redis /var/run/redis
    sudo chmod 755 /var/run/redis
    if test -d /etc/tmpfiles.d
      echo 'd  /var/run/redis  0755  redis  redis  10d  -' | sudo tee -a /etc/tmpfiles.d/redis.conf
    end
    sudo systemctl restart redis
    sudo usermod -aG redis git
    ```


### Gitlab 安装 {#gitlab-安装}

-   克隆 GitLab 并配置相关文件
    ```fish
    # clone gitlab src
    cd ~git
    sudo -u git -H -E git clone https://gitlab.com/gitlab-org/gitlab-foss.git -b $gitlab_version gitlab
    cd $gitlab_path
    # config gitlab.yml
    sudo -u git -H cp config/gitlab.yml.example config/gitlab.yml
    sudo -u git -H editor config/gitlab.yml
    # config permissions
    sudo -u git -H cp config/secrets.yml.example config/secrets.yml
    sudo -u git -H chmod 0600 config/secrets.yml
    sudo chown -R git log/
    sudo chown -R git tmp/
    sudo chmod -R u+rwX,go-w log/
    sudo chmod -R u+rwX tmp/
    sudo chmod -R u+rwX tmp/pids/
    sudo chmod -R u+rwX tmp/sockets/
    sudo -u git -H mkdir -p public/uploads/
    sudo chmod 0700 public/uploads
    sudo chmod -R u+rwX builds/
    sudo chmod -R u+rwX shared/artifacts/
    sudo chmod -R ug+rwX shared/pages/
    # config puma
    sudo -u git -H cp config/puma.rb.example config/puma.rb
    sudo -u git -H editor config/puma.rb
    # config git
    sudo -u git -H git config --global core.autocrlf input
    sudo -u git -H git config --global gc.auto 0
    sudo -u git -H git config --global repack.writeBitmaps true
    sudo -u git -H git config --global receive.advertisePushOptions true
    sudo -u git -H git config --global core.fsyncObjectFiles true
    # config Redis
    sudo -u git -H cp config/resque.yml.example config/resque.yml
    sudo -u git -H cp config/cable.yml.example config/cable.yml
    sudo -u git -H editor config/resque.yml config/cable.yml
    # config database
    sudo -u git cp config/database.yml.postgresql config/database.yml
    sudo -u git -H editor config/database.yml
    sudo -u git -H chmod o-rwx config/database.yml
    ```

-   安装 GitLab 相关程序
    ```fish
    # install gems
    sudo -u git -H bundle config set --local deployment 'true'
    sudo -u git -H bundle config set --local without 'development test mysql aws kerberos'
    sudo -u git -H -E bundle install
    # install gitlab-shell
    sudo -u git -H -E bundle exec rake gitlab:shell:install RAILS_ENV=production
    sudo -u git -H editor ~git/gitlab-shell/config.yml
    # install gitlab-workhorse
    sudo -u git -H -E bundle exec rake "gitlab:workhorse:install[/home/git/gitlab-workhorse]" RAILS_ENV=production
    # install gitaly
    cd /home/git/gitlab
    sudo -u git -H -E bundle exec rake \
        "gitlab:gitaly:install[/home/git/gitaly,/home/git/repositories]" RAILS_ENV=production
    sudo chmod 0700 $gitlab_path/tmp/sockets/private
    sudo chown git $gitlab_path/tmp/sockets/private
    sudo -u git -H editor $gitaly_path/config.toml
    # install service
    sudo mkdir -p /usr/local/lib/systemd/system
    sudo cp lib/support/systemd/* /usr/local/lib/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable gitlab.target
    # setup logrotate
    sudo cp lib/support/logrotate/gitlab /etc/logrotate.d/gitlab
    ```
    如果主机上还有 PostgreSQL 以及 Redis，可以在 `gitlab-*.service` 文件 Unit 单元的 **Wants** 与 **After** 两个字段追加下面两个服务
    ```text
    [Unit]
    Wants=redis-server.service postgresql.service
    After=redis-server.service postgresql.service
    ```

-   启动相关项目
    ```fish
    # start gitaly
    sudo systemctl start gitlab-gitaly.service
    # init database and activate advanced features
    sudo -u git -H bundle exec rake gitlab:setup RAILS_ENV=production force=yes
    ```

-   检测应用状态
    ```fish
    sudo -u git -H bundle exec rake gitlab:env:info RAILS_ENV=production
    ```

-   编译前端文件
    ```fish
    # GetText PO files
    sudo -u git -H bundle exec rake gettext:compile RAILS_ENV=production
    # Assets
    sudo -u git -H yarn install --production --pure-lockfile
    sudo -u git -H bundle exec rake gitlab:assets:compile \
        RAILS_ENV=production NODE_ENV=production \
        NODE_OPTIONS="--max_old_space_size=8192"
    if test 0 -ne $status
        echo "\033[31m compile assets error. desc '--max_old_space_size' \033[0m"
        exit 64
    end
    ```

-   设置 Nginx
    ```fish
    sudo cp lib/support/nginx/gitlab-ssl /etc/nginx/sites-available/gitlab
    sudo ln -sf /etc/nginx/sites-available/gitlab /etc/nginx/sites-enabled/gitlab
    sudo editor /etc/nginx/sites-available/gitlab
    sudo nginx -t
    if test 0 -ne $status
        echo "nginx config error. editor /etc/nginx/sites-available/gitlab"
        exit 64
    end
    ```

-   二次检查程序状态
    ```fish
    sudo systemctl restart nginx.service gitlab.target
    sudo -u git -H bundle exec rake gitlab:check RAILS_ENV=production
    ```

Gitlab基本配置完成，登录网站设置默认管理员密码即可登录，默认管理员帐号为 **root**


### 更新 {#更新}

之后每次更新与安装类似，因此可以写一个小脚本

```fish
function check_and_print_command_status
    if test 0 -eq $argv[1]
	echo "$argv[2]: "(set_color green)"consistency"(set_color normal)
    else
	echo "$argv[2]: "(set_color red)"difference"(set_color normal)
    end
end

function get_next_branch
    cd $gitlab_path
    sudo -u git -H bundle exec rake gitlab:backup:create RAILS_ENV=production
    systemctl stop gitlab.target
    sudo -u git -H -E git fetch --all --prune
    sudo -u git -H git checkout -- Gemfile.lock db/structure.sql locale
    sudo -u git -H git checkout $next_branch
end

function check_configuration_files
    cd $gitlab_path
    set files \
	"config/gitlab.yml.example" "lib/support/nginx/gitlab-ssl" \
	"lib/support/systemd/gitlab-gitaly.service" "lib/support/systemd/gitlab-pages.service" \
	"lib/support/systemd/gitlab-sidekiq.service" "lib/support/systemd/gitlab-mailroom.service" \
	"lib/support/systemd/gitlab-puma.service" "lib/support/systemd/gitlab-workhorse.service" \
	"lib/support/systemd/gitlab.target" "lib/support/systemd/gitlab.slice"
    for f in $files
	git diff --exit-code origin/$curr_branch:$f origin/$next_branch:$f
	check_and_print_command_status $status "$f"
    end
end

function install_and_migration
    cd $gitlab_path
    # If you haven't done so during installation or a previous upgrade already
    sudo -u git -H bundle config set --local deployment 'true'
    sudo -u git -H bundle config set --local without 'development test mysql aws kerberos'
    # Update gems
    sudo -u git -H -E bundle install
    # Optional: clean up old gems
    sudo -u git -H bundle clean
    # Run database migrations
    sudo -u git -H bundle exec rake db:migrate RAILS_ENV=production
    # Compile GetText PO files
    sudo -u git -H bundle exec rake gettext:compile RAILS_ENV=production
    # Update node dependencies and recompile assets
    sudo -u git -H -E bundle exec rake yarn:install gitlab:assets:clean gitlab:assets:compile RAILS_ENV=production NODE_ENV=production NODE_OPTIONS="--max_old_space_size=6144"
    # Clean up cache
    sudo -u git -H bundle exec rake cache:clear RAILS_ENV=production
end

function upgrade_shell
    cd $shell_path
    sudo -u git -H git fetch --all --tags --prune
    sudo -u git -H git checkout v(cat $gitlab_path/GITLAB_SHELL_VERSION)
    sudo -u git -H make build
end

function upgrade_workhorse
    cd $gitlab_path
    sudo -u git -H bundle exec rake "gitlab:workhorse:install[$work_path]" RAILS_ENV=production
end

function upgrade_gitaly
    cd $gitlab_path
    sudo -u git -H bundle exec rake "gitlab:gitaly:install[$gitaly_path,$repos_path]" RAILS_ENV=production
end

function check_status
    cd $gitlab_path
    sudo -u git -H bundle exec rake gitlab:env:info RAILS_ENV=production
    sudo -u git -H bundle exec rake gitlab:check RAILS_ENV=production
end

set -g base_path    /home/git
set -g gitlab_path  $base_path/gitlab
set -g gitaly_path  $base_path/gitaly
set -g shell_path   $base_path/gitlab-shell
set -g work_path    $base_path/gitlab-workhorse
set -g repos_path   $base_path/repositories
set -g curr_branch  (git --git-dir=$gitlab_path/.git symbolic-ref --short -q HEAD)
set -g next_branch  "15-0-stable"

argparse 'c/check' 'u/update' -- $argv

if set --query _flag_update
    get_next_branch
    install_and_migration
    upgrade_shell
    upgrade_workhorse
    upgrade_gitaly
end

if set --query _flag_check
    check_configuration_files
    check_status
    exit 0
end
```


### GitLab CI/CD {#gitlab-ci-cd}

接下来安装 `Gitlab Runner` 最新版，使 CI/CD 可用

```fish
cd /tmp
curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | sudo bash
sudo -E apt install docker docker-compose gitlab-runner
```

Gitlab Runner 提供了几种模式，分别是

-   shell
-   docker
-   docker-ssh
-   ssh
-   parallels
-   virtualbox
-   docker+machine
-   docker-ssh+machine
-   kubernetes

virtualbox、parallels、docker-ssh 都是使用 SSH 的方式连接到镜像。而通常采用
docker 执行器就可以轻量化的实现各种环境的构建；如果你需要执行 CI 任务时多时少则可以选用 docker+machine；shell 就很暴力了，直接在主机上执行，但是需要自行搭建环境，这不如 container 来的灵活自在。

在管理员面板的 **Overview &gt; Runners** 中获取到注册 runner 要用的 token。注册
docker 执行器的 runner

```fish
sudo gitlab-runner register --executor docker --docker-image alpine:latest
```

或许以后会改为 k8s 搭建 runner。先将 docker build 映射到 `/tmp`​，只需要修改配置文件中的 volumes 为

```toml
volumes = ["/cache", "/tmp:/builds:rw"]
```

如果对 GitLab Runner 的配置感兴趣，可以参考[官方文档](https://docs.gitlab.com/runner/configuration/)。


### GitLab 开启邮件服务 {#gitlab-开启邮件服务}

我们的GitLab使用的是源码安装，需要修改 `config/gitlab.yml` 开启 emil

```fish
gitlab_email_from="noreply@example.com"
gitlab_email_reply="noreply@example.com"
cd /home/git/gitlab
sed -i "s/email_enabled:.*/email_enabled: true/" config/gitlab.yml
sed -ie "s/email_from:.*/email_from: ${gitlab_email_from}" config/gitlab.yml
sed -ie "s/email_reply_to:.*/email_reply_to: ${gitlab_email_reply}" config/gitlab.yml
cp config/initializers/smtp_settings.rb.sample config/initializers/smtp_settings.rb
```

将email启用后，还需要配置smtp，可以参考 [官方教程](https://docs.gitlab.com/omnibus/settings/smtp.html#mailcow)，修改配置文件
**config/initializers/smtp_settings.rb**​，将 `ActionMailer::Base.smtp_settings` 修改为以下内容

```ruby
enable: true,
address: "mail.example.com",
port: 465,
user_name: "noreply@example.com",
password: "YourPassword",
domain: "mail.example.com",
authentication: :login,
enable_starttls_auto: true,
tls: true,
openssl_verify_mode: 'none'
```

开启对邮件的 S/MIME 签名服务，将你的S/MIME私钥保存到
`$gitlab_path/.gitlab_smime_key`​，公钥保存到
`$gitlab_path/.gitlab_smime_cert`

```fish
sed -i "103s/# enabled:.*/enabled: true/" config/gitlab.yml
```

配置完成后重启服务即可，如果需要验证SMTP是否工作，可以使用以下命令

```fish
echo "Notify.test_email('$gitlab_email_reply', 'Message Subject', 'Message Body').deliver_now" | \
sudo -u git -H bundle exec rails console -e production
```


## Lychee {#lychee}

Lychee 现在是由 LycheeOrg 维护的开源项目，旨在实现一个简单易用的照片管理系统，我们搭建服务将使用 4.x 版本作为示例

Lychee 是目前为数不多的支持 PostgreSQL 的图床

```fish
set lychee_path /path/to/lychee
set lychee_version v4.0.8
set lychee_host example.com
set lychee_db_user lychee
set lychee_db_passwd YourPassword
set lychee_db_name lychee
```


### Lychee 依赖 {#lychee-依赖}

由于 Lychee 同样也是 PHP 开发的服务，所以已经安装 Nextcloud 的情况下，并不需要再安装 PHP 相关的其他 package (当然除了 PHP 的依赖管理器 composer)

PHP &gt;= 7.4，依赖的扩展 (可以使用命令 `php -m` 查看已安装的扩展)

-   BCMath
-   Ctype
-   Exif
-   Ffmpeg (optional — to generate video thumbnails)
-   Fileinfo
-   GD
-   Imagick (optional — to generate better thumbnails)
-   JSON
-   Mbstring
-   OpenSSL
-   PDO
-   Tokenizer
-   XML
-   ZIP


### Lychee 安装 {#lychee-安装}

我们先创建数据库用户，Lychee 支持 MySQL (&gt; 5.7.8) / MariaDB (&gt; 10.2) /
PostgreSQL (&gt; 9.2)，我们继续使用 PostgreSQL 就好

```fish
sudo useradd $lychee_db_user --create-home --shell /sbin/nologin
sudo -u postgres -H psql -c "CREATE USER $lychee_db_user WITH PASSWORD '$lychee_db_passwd'"
sudo -u postgres -H psql -c "CREATE DATABASE $lychee_db_name OWNER $lychee_db_user"
```

我们将安装 v4.0.8，更多详细版本信息请浏览 [更新日志](https://lycheeorg.github.io/docs/releases.html)

```shell
git clone https://www.github.com/LycheeOrg/Lychee -b $lychee_version $lychee_path
cd $lychee_path
composer install --no-dev
chown -R www-data:www-data $lychee_path
```

关于 Web 服务器的配置官方已经给出了 [Nginx](https://lycheeorg.github.io/docs/#nginx) 和 [Apache](https://lycheeorg.github.io/docs/#apache) 的相关配置


### Lychee 配置 {#lychee-配置}

Lychee 相关的环境配置在 `.env` 中

```fish
bash -c "cat <<- EOF > $lychee_path/.env
APP_NAME=Lychee
APP_ENV=production
APP_DEBUG=false
APP_URL=http://$lychee_host
APP_KEY=

DEBUGBAR_ENABLED=false
LOG_CHANNEL=stack

DB_CONNECTION=pgsql
DB_HOST=localhost
DB_PORT=5432
DB_DATABASE=$lychee_db_name
DB_USERNAME=$lychee_db_user
DB_PASSWORD=$lychee_db_passwd
DB_LOG_SQL=false

TIMEZONE=Asia/Shanghai

BROADCAST_DRIVER=log
CACHE_DRIVER=file
SESSION_DRIVER=file
SESSION_LIFETIME=120
QUEUE_DRIVER=sync

REDIS_HOST=/var/run/redis/redis.sock
REDIS_PASSWORD=null
REDIS_PORT=0

MAIL_DRIVER=smtp
MAIL_HOST=
MAIL_PORT=
MAIL_USERNAME=
MAIL_PASSWORD=
MAIL_ENCRYPTION=

PUSHER_APP_ID=
PUSHER_APP_KEY=
PUSHER_APP_SECRET=
PUSHER_APP_CLUSTER=mt1

MIX_PUSHER_APP_KEY=\"\${PUSHER_APP_KEY}\"
MIX_PUSHER_APP_CLUSTER=\"\${PUSHER_APP_CLUSTER}\"
EOF"
chown www-data:www-data $lychee_path/.env
sudo -u www-data php artisan key:generate
```

最后只需要配置 Nginx 相关内容即可
