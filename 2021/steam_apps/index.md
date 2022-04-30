# 使用 steamcmd 搭建游戏服务器


和好友联机的时候本地服务器实在是不爽，一个人起飞，其他人都是**高PING战士**，最开始主要是 L4D2 时各种 RPG 服务器有些不爽，为了纯净的服务器只好自己建了

事先声明，我们所有的操作在 Debian / Ubuntu 下操作，有些操作系统可能会不一样，不过大同小异，我们还是定义一些等等可能用到的变量 (主要是路径和密码之类的

```shell
steam=/home/steam
group_id=123456789
l4d2=${steam}/l4d2
l4d2_id=222860
l4d2_server_name="L4D2 Server"
l4d2_port=1024
valheim=${steam}/valheim
valheim_id=896660
valheim_server_name="Valheim Server"
valheim_world="World"
valheim_port=1024
valheim_passwd=valheim_password
dst=${steam}/dst
dst_id=343050
```


## SteamCMD {#steamcmd}

顾名思义，steamcmd 是一个命令行工具，同时支持 linux，是我们搭建服务器的好帮手，然而我不会用，不过这不重要，安装跑起来就好

```shell
add-apt-repository multiverse
dpkg --add-architecture i386
apt update && apt upgrade
apt install -y lib32gcc1 steamcmd
```

我们不仅要安装一个 steamcmd，还要将所有游戏服务器，存放在 `~steam` 下，使用
steam 这个用户来运行游戏

```shell
adduser --disabled-login --gecos 'Steam' steam
sudo -u steam -H ln -s /usr/games/steamcmd ${steam}/steamcmd
```


### 语法 {#语法}

这里说的语法并不是 SteamCMD 的语法，而是 Steam 中所使用的文本标记语法，这些标记标签允许您为您的留言及发帖文字添加格式，类似于 HTML，官方展示在[这里](https://steamcommunity.com/comment/ForumTopic/formattinghelp)

| 标签    | 释义                             | 示例                                     |
|-------|--------------------------------|----------------------------------------|
| h       | 标题                             | [h1]一级标题[/h1]                        |
| b       | 粗体                             | [b]粗体文本[/b]                          |
| u       | 下划线                           | [u]下划线文本[/u]                        |
| l       | 斜体                             | [l]斜体[/l]                              |
| strike  | 删除线                           | [strike]删除线文本[/strike]              |
| spoiler | 隐藏                             | [spoiler]隐藏文本[/spoiler]              |
| noparse | 不解析                           | [noparse]不解析[b]标签[/b][/noparse]     |
| url     | 网络链接                         | [url=blog.ginshio.org]博客[/url]         |
|         | Youtube / Shop / Workshop Widget | <https://store.steampowered.com/app/570> |
| list    | 无序列表                         | [list] [\*] 列表 [\*] 列表 [/list]       |
| olist   | 有序列表                         | [olist] [\*] 列表 [\*] 列表 [/olist]     |
| quote   | 引用                             | [quote=author]引用文本[/quote]           |
| code    | 等宽字体 (保留空格)              | [code]code[/code]                        |

表格语法有点难度，`tr` 表示一行，`th` 表示一个单元格

```text
[table]
[tr]
[th][/th]
[th]DST Memorandum[/th]
[th]Status Announcements[/th]
[th]Global Positions[/th]
[/tr]
[tr]
[th]DST Memorandum[/th]
[th][/th]
[th]Crash[/th]
[th]Crash[/th]
[/tr]
[tr]
[th]Status Announcements[/th]
[th]Crash[/th]
[th][/th]
[th]OK[/th]
[/tr]
[tr]
[th]Global Positions[/th]
[th]Crash[/th]
[th]OK[/th]
[th][/th]
[/tr]
```

可以做出一个这样的表格

|                      | DST Memorandum | Status Announcements | Global Positions |
|----------------------|----------------|----------------------|------------------|
| DST Memorandum       |                | Crash                | Crash            |
| Status Announcements | Crash          |                      | OK               |
| Global Positions     | Crash          | OK                   |                  |


### 遇到的问题 {#遇到的问题}

如果遇到服务器无法启动，比如缺少 `sdk32/libsteam.so` 或 `sdk32/steamclient.so`
之类的错误，需要完成以下操作

```shell
sudo -u steam -H mkdir -p /home/steam/.steam/sdk32
sudo -u steam -H ln -s /home/steam/.steam/steamcmd/linux32/steamclient.so /home/steam/.steam/sdk32/steamclient.so
```


## L4D2 {#l4d2}

<div class="warning">

L4D2 每次搭建都被 DDOS，已经不再维护

</div>

在搭建服务器之前，为了你的服务器着想，请先创建一个 Steam 组，将你们一起开黑的人都拉入组中，我们需要将服务器设置为组私有，只有组中的人才能使用

安装并对服务器进行配置，配置文件是 `${l4d2}/left4dead2/cfg/server.cfg`

```shell
sudo -u steam -H ${steam}/steamcmd +force_install_dir ${l4d2} +login anonymous +app_update ${l4d2_id} validate +quit
sudo -u steam -H cat <<- EOF > ${l4d2}/left4dead2/cfg/server.cfg
hostname "${l4d2_server_name}"       // 服务器名
hostport ${l4d2_port}                // 服务器端口
sv_tags "hidde,GinShio"              // 隐藏服务器
sv_gametypes "versus,survival,coop,realism,teamversus,teamscavenge" // 游戏类型
mp_gamemode "coop"
sv_cheats 0                          // 允许作弊
sv_voiceenable 1                     // 语音服务
sv_pausable 0                        // 暂停
sv_consistency 0                     // 一致性
sv_lan 0                             // 局域网游戏
sv_allow_lobby_connect_only 0        // 大厅连接
sv_region 4                          // 区域：亚洲
sv_visiblemaxplayers 4               // 最多人数上线：4 (4~32)
mp_disable_autokick 0                // 闲置踢出
sv_steamgroup "${group_id}"          // 根据自己的steam组ID绑定服务器
sv_steamgroup_exclusive 1            // 设置组私有化
exec banned_user.cfg
exec banned_ip.cfg
heartbeat
EOF
```

对于服务器公告，`${l4d2}/left4dead2/host.txt` 可以修改服务器公告的标题，而
`${l4d2}/left4dead2/motd.txt` 修改的是公告的内容，我们可以在公告中使用之前列出的文本标记语法。对于第三方地图，我们只需要将地图存放在
`{l4d2}/left4dead2/addons/workshop` 中即可，不过记得将地图文件的权限转到 steam

个人喜欢使用 systemctl 来管理服务，这样觉得更安全些，所以我们完成一个 service 管理服务器，当然如果你想用 screen 可以自行搜索它的用法

```text
[Unit]
Description=Left 4 Dead 2 Server
Documentation=https://left4dead.fandom.com/wiki/Left_4_Dead_Wiki
After=network.target

[Service]
Type=simple
User=steam
WorkingDirectory=/home/steam/l4d2
ExecStart=/home/steam/l4d2/srcds_run -game left4dead2 -autorestart +ip 0.0.0.0 +exec server.cfg
ExecReload=/bin/kill -HUP
Restart=on-failure
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target
```

到这里，纯净的 l4d2 服务器就搭建好了，我并没有弄插件，也没有弄管理员，所以就到这里！


## Valheim: 英灵神殿 {#valheim-英灵神殿}

<div class="warning">

该章节没有真正部署维护，且没有更新过，酌情参考

</div>

首先我们配置服务器，不过和 L4D2 的方式差不多，毕竟都是 SteamCMD，不废话，直接上
Shell 指令。需要注意的是，Valheim 将占用三个端口，即 `valheim_port` 到
`valheim_port + 2`，请在防火墙开启需要的全部三个端口

```shell
sudo -u steam -H ${steam}/steamcmd +force_install_dir ${valheim} +login anonymous +app_update ${valheim_id} validate +quit
sudo -u steam -H cp ${valheim}/start_server.sh ${valheim}/start_server.sh.bkp
sudo -u steam -H cat <<- EOF > ${valheim}/start_server.sh
export templdpath=${LD_LIBRARY_PATH}
export LD_LIBRARY_PATH=${valheim}/linux64:${LD_LIBRARY_PATH}
export SteamAppId=892970
echo "Starting server PRESS CTRL-C to exit"
${valheim}/valheim_server.x86_64 -name "${valheim_server_name}" -port ${valheim_port} -world "${valheim_world}" -password "${valheim_passwd}"
export LD_LIBRARY_PATH=$templdpath
EOF
```

搞定，整一个 service 让 systemd 帮我们管理服务器

```text
[Unit]
Description=Valheim Server
After=network.target

[Service]
Type=simple
User=steam
WorkingDirectory=/home/steam/valheim
ExecStart=bash /home/steam/valheim/start_server.sh
ExecReload=/bin/kill -HUP
Restart=on-failure
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target
```

好了，现在问题就是，你的服务器配置，请务必 **2C4G5Mbps** 及以上配置，要求真tm高，听说开发者只有5个人，，，


## 饥荒联机版 {#饥荒联机版}

现在我们要征服永恒领域了，首先的问题就是搭建一个服务器。我们下载服务器很简单，就是一行用了很多遍的命令

```shell
sudo -u steam -H ${steam}/steamcmd +force_install_dir ${dst} +login anonymous +app_update ${dst_id} validate +quit
```

下载好了当然没有用，我们需要去 [Klei 官网](https://accounts.klei.com/) 生成一份服务器 token。在 Games 一栏选择
DST Game Server 即可，输入 Cluster Name 添加生成服务器配置，还有 token，请务必保存好。


### 目录结构 {#目录结构}

DST 服务器在运行时，全部数据都会存储在 `$HOME/.klei` 下，因此我们只需要常备份这个目录即可。饥荒服务器的目录结构如下：

```text
  ├── Cluster1/
  │    ├── cluster.ini
  │    ├── cluster_token.txt
  │    ├── Caves/
  │    │    ├── server.ini
  │    │    ├── leveldataoverride.lua
  │    │    ├── modoverrides.lua
  │    ├── Master/
  │    │    ├── server.ini
  │    │    ├── leveldataoverride.lua
  │    │    ├── modoverrides.lua
```

这是一个完整的位面所需要配置的文件

-   `cluster_token.txt` 存储的是从 Klei 官网拿到的 token
-   `cluster.ini` 即这个位面的主配置，主要配置游戏模式、游戏人数、服务器名、密码、
    steam 组等等
-   `Master/server.ini` 与 `Caves/server.ini` 配置基本相同，主要是世界的端口号和主次世界设置
-   `modoverrides.lua` 配置开启的 mod 的设置
-   `leveldataoverride.lua` 配置这个世界的资源、设置

另外在安装目录中有个 mods 的目录，其中可以添加服务器模组，当然仅仅是安装到服务器上。用不用还是需要看世界中 modoverrides.lua 的设置。

如果需要详细设置哪些人为管理员，可以在目录下添加 **adminlist.txt** 文件，文件中使用 Klei Account ID 区分玩家。如果你不知道 ID 的话可以在启动服务器后生成的
`server_log.txt` 与 `server_chat_log.txt` 中查找。这两个文件在启动对应的世界后在目录下生成。


### 配置文件 {#配置文件}


#### 服务器配置 {#服务器配置}

基本上在 Klei 官网所生成的 `cluster.ini` 与 `cluster_token.txt` 基本够用了，额外需要注意的是如果需要设置为组服务器

```text
[STEAM]
steam_group_admins=false  # 设置组成员是否为管理员，接受 true / false
steam_group_id=123456789  # 设置组 id
steam_group_only=true     # 设置是否仅组成员可用，接受 true / false
```

至于 **server.ini** 则分别在世界的目录下，基本无需多修改 (除非多个世界分主次或改端口)


#### 世界设置 {#世界设置}

DST 服务器最复杂的是世界设置文件，可以先在自己电脑上配置好你想要的世界设置，还有服务器 mod，然后把它们复制进对应的世界目录就好了。

当然还可以自己手动修改配置文件，比如说 Maxwell 雕像的数量、虫洞类型等等在界面无法修改的东西。

-   地上世界基础配置文件

    ```lua
    return {
      desc="The standard Don't Starve experience.",
      hideminimap=false,
      id="SURVIVAL_TOGETHER",
      location="forest",
      max_playlist_position=999,
      min_playlist_position=0,
      name="Standard Forest",
      -- 雕像的数量
      numrandom_set_pieces=4,
      override_level_string=false,
      overrides={
        -- 资源设置的可选项分别为:
        ----- "never"    无
        ----- "rare"     较少
        ----- "default"  默认
        ----- "often"    较多
        ----- "always"   大量

        -- 全局设置
        --- 特殊事件
        ----- "none"                 无
        ----- "default"              自动
        ----- "crow_carnival"        盛夏鸦年华
        ----- "hallowed_nights"      万圣之夜
        ----- "winters_feast"        冬季盛宴
        ----- "year_of_the_gobbler"  火鸡之年
        ----- "year_of_the_varg"     座狼之年
        ----- "year_of_the_pig"      猪王之年
        ----- "year_of_the_carrat"   胡萝卜鼠之年
        ----- "year_of_the_beefalo"  皮弗娄牛之年
        specialevent="default",
        --- 季节
        ----- "noseason"         无季节
        ----- "veryshortseason"  非常短
        ----- "shortseason"      较短
        ----- "default"          默认长度
        ----- "longseason"       较长
        ----- "verylongseason"   非常长
        ----- "random"           随机长度
        autumn="default",  --- 秋季, 根据设置天数依次为 5 / 12 / 20 / 30 / 50
        winter="default",  --- 冬季, 根据设置天数依次为 5 / 10 / 15 / 22 / 40
        spring="default",  --- 春季, 根据设置天数依次为 5 / 12 / 20 / 30 / 50
        summer="default",  --- 夏季, 根据设置天数依次为 5 / 10 / 15 / 22 / 40
        --- 天类型
        ----- "default"    默认
        ----- "longday"    加长白天
        ----- "longdusk"   加长黄昏
        ----- "longnight"  加长黑夜
        ----- "noday"      无白天
        ----- "nodusk"     无黄昏
        ----- "nonight"    无黑夜
        ----- "onlyday"    只有白天
        ----- "onlydusk"   只有黄昏
        ----- "onlynight"  只有黑夜
        day="default",
        beefaloheat="default",  --- 野牛发情
        krampus="default",      --- 坎普斯

        -- 求生者设置
        --- 额外起始资源
        ----- "0"        总是
        ----- "5"        5 天后
        ----- "default"  10 天后
        ----- "15"       15 天后
        ----- "20"       20 天后
        ----- "none"     从不
        extrastartingitems="default",
        seasonalstartingitems="default",    --- 季节起始物品, "never" / "default"
        spawnprotection="default",          --- 出生点保护, "never" / "default" / "always"
        dropeverythingondespawn="default",  --- 退出掉落物品, "default" / "always"
        brightmarecreatures="default",      --- 启蒙怪兽数量
        shadowcreatures="default",          --- 理智怪兽数量

        -- 世界设置
        --- 石化
        ----- "none"     无
        ----- "few"      慢
        ----- "default"  默认
        ----- "many"     快
        ----- "max"      极快
        petrification="default",
        frograin="default",       --- 蛙雨
        hounds="default",         --- 猎犬来袭频率
        alternatehunt="default",  --- 追猎惊喜
        hunt="default",           --- 狩猎
        lightning="default",      --- 闪电
        meteorshowers="default",  --- 流星
        weather="default",        --- 雨
        wildfires="default",      --- 野火

        -- 资源再生的可选项分别为:
        ----- "never"     从不
        ----- "veryslow"  非常慢
        ----- "slow"      缓慢
        ----- "default"   默认
        ----- "fast"      快速
        ----- "veryfast"  非常快

        -- 资源再生设置
        regrowth="default",                --- 再生速度
        deciduoustree_regrowth="default",  --- 桦栗树再生
        carrots_regrowth="default",        --- 胡萝卜再生
        evergreen_regrowth="default",      --- 常青树再生
        flowers_regrowth="default",        --- 花再生
        moon_tree_regrowth="default",      --- 月树再生
        saltstack_regrowth="default",      --- 盐矿再生
        twiggytrees_regrowth="default",    --- 多枝树再生

        -- 生物设置
        bees_setting="default",      --- 蜜蜂
        birds="default",             --- 鸟
        bunnymen_setting="default",  --- 兔人
        butterfly="default",         --- 蝴蝶
        catcoons="default",          --- 浣猫
        gnarwail="default",          --- 一角鲸
        perd="default",              --- 火鸡
        grassgekkos="default",       --- 草蜥蜴
        moles_setting="default",     --- 鼹鼠
        penguins="default",          --- 企鹅
        pigs_setting="default",      --- 猪人
        rabbits_setting="default",   --- 兔子
        fishschools="default",       --- 鱼群
        wobsters="default",          --- 龙虾

        -- 敌对生物设置
        bats_setting="default",     --- 蝙蝠
        cookiecutters="default",    --- 饼干切割机
        frogs="default",            --- 青蛙
        mutated_hounds="default",   --- 恐怖猎犬, "never" / "default"
        hound_mounds="default",     --- 猎犬
        wasps="default",            --- 杀人蜂
        lureplants="default",       --- 食人花
        walrus_setting="default",   --- 海象
        merms="default",            --- 鱼人
        penguins_moon="default",    --- 月石企鹅, "never" / "default"
        mosquitos="default",        --- 蚊子
        sharks="default",           --- 鲨鱼
        moon_spider="default",      --- 破碎蜘蛛
        squid="default",            --- 乌贼
        spider_warriors="default",  --- 蜘蛛战士, "never" / "default"
        spiders_setting="default",  --- 蜘蛛

        -- 巨型生物设置
        antliontribute="default",    --- 蚁狮
        bearger="default",           --- 熊獾
        beequeen="default",          --- 蜂后
        crabking="default",          --- 帝王蟹
        deerclops="default",         --- 独眼巨鹿
        dragonfly="default",         --- 龙蝇
        eyeofterror="default",       --- 泰拉瑞亚之眼
        klaus="default",             --- 克劳斯
        fruitfly="default",          --- 果蝇王
        malbatross="default",        --- 邪天翁
        goosemoose="default",        --- 麋鹿鹅
        deciduousmonster="default",  --- 毒桦栗树
        spiderqueen="default",       --- 蜘蛛女王
        liefs="default",             --- 树精守卫





        -- 世界生成中等级分别为:
        ----- "never"      无
        ----- "uncommon"   很少
        ----- "rare"       较少
        ----- "default"    默认
        ----- "often"      较多
        ----- "mostly"     很多
        ----- "always"     大量
        ----- "insane"     疯狂

        -- 全局生成
        --- 起始季节
        ----- "default"                      秋
        ----- "winter"                       冬
        ----- "spring"                       春
        ----- "summer"                       夏
        ----- "autumn|spring"                秋或春
        ----- "winter|summer"                冬或夏
        ----- "autumn|winter|spring|summer"  随机
        season_start="default",

        -- 世界生成
        --- 生物群落
        ----- "default"  联机版
        ----- "classic"  经典
        task_set="default",
        --- 出生点
        ----- "plus"      额外资源
        ----- "darkness"  黑暗
        ----- "default"   默认
        start_location="default",
        world_size="default",  --- 世界大小, "small" / "medium" / "default" / "huge"
        --- 世界分支
        ----- "never"    从不
        ----- "least"    少
        ----- "default"  默认
        ----- "most"     多
        ----- "random"   随机
        branching="default",
        loop="default",               --- 环形世界, "never" / "default" / "always"
        touchstone="default",         --- 试金石
        boons="default",              --- 前辈
        prefabswaps_start="default",  --- 初始资源多样化, "classic" / "default" / "random"
        moon_fissure="default",       --- 天体裂隙
        terrariumchest="default",     --- 泰拉瑞亚, "never" / "default"
        roads="default",              --- 道路, "never" / "default"
        wormhole_prefab="wormhole",   --- 虫洞多样性, "wormhole" (虫洞) / "tentacle_pillar" (巨大触手)

        -- 资源
        moon_starfish="default",         --- 海星
        moon_bullkelp="default",         --- 公牛海带茎
        berrybush="default",             --- 浆果从
        rock="default",                  --- 岩石
        ocean_bullkelp="default",        --- 公牛海带
        cactus="default",                --- 仙人掌
        carrot="default",                --- 胡萝卜
        flint="default",                 --- 燧石
        flowers="default",               --- 花
        grass="default",                 --- 草
        moon_hotspring="default",        --- 温泉
        moon_rock="default",             --- 月亮石
        moon_sapling="default",          --- 月亮树苗
        moon_tree="default",             --- 月树
        meteorspawner="default",         --- 流星区
        rock_ice="default",              --- 迷你冰川
        mushroom="default",              --- 蘑菇
        ponds="default",                 --- 池塘
        reeds="default",                 --- 芦苇
        sapling="default",               --- 小树苗
        ocean_seastack="ocean_default",  --- 海矿, 参数需要加 "ocean_" 前缀
        marshbush="default",             --- 荆棘树枝
        moon_berrybush="default",        --- 石果树
        trees="default",                 --- 树 (所有)
        tumbleweed="default",            --- 风滚草

        -- 生物及刷新点
        bees="default",               --- 蜂巢
        beefalo="default",            --- 皮弗娄牛
        buzzard="default",            --- 秃鸠
        moon_carrot="default",        --- 胡萝卜鼠
        catcoon="default",            --- 猫桩
        moles="default",              --- 鼹鼠洞
        pigs="default",               --- 猪人房
        rabbits="default",            --- 兔子洞
        moon_fruitdragon="default",   --- 沙拉蝾螈
        ocean_shoal="default",        --- 鱼群
        lightninggoat="default",      --- 伏特羊
        ocean_wobsterden="default",   --- 龙虾窝

        -- 敌对生物及刷新点
        chess="default",                   --- 发条装置
        houndmound="default",              --- 猎犬冢
        angrybees="default",               --- 杀人蜂巢
        merm="default",                    --- 漏雨的小屋
        walrus="default",                  --- 海象营地
        ocean_waterplant="ocean_default",  --- 海草
        moon_spiders="default",            --- 破碎蜘蛛洞
        spiders="default",                 --- 蜘蛛巢
        tallbirds="default",               --- 高脚鸟巢
        tentacles="default",               --- 触手



        --- Other
        has_ocean=true,
        keep_disconnected_tiles=true,
        layout_mode="LinkNodesByKeys",
        no_joining_islands=true,
        no_wormholes_to_disconnected_tiles=true
      },
      random_set_pieces={r
        "Sculptures_2",
        "Sculptures_3",
        "Sculptures_4",
        "Sculptures_5",
        "Chessy_1",      -- 2发条骑士，2齿轮，长矛，棋盘地皮
        "Chessy_2",      -- 2发条主教，棋盘、牛毛地皮，Maxwell 雕像，(2齿轮)
        "Chessy_3",      -- 发条战车，蜂蜜药膏，背包，棋盘、牛毛地皮
        "Chessy_4",      -- 发条战车，2大理石，鹤嘴锄，2大理石柱，1大理石树，棋盘、牛毛地皮，Maxwell 雕像
        "Chessy_5",      -- 1发条骑士，1发条主教，竖琴雕像，棋盘、牛毛地皮
        "Chessy_6",      -- 1发条骑士，1发条主教，棋盘、牛毛地皮
        "Maxwell1",      -- 1发条战车，3发条骑士，棋盘、牛毛地皮，4大理石柱，9大理石树，大量恶魔花
        "Maxwell2",      -- 1发条战车，4发条骑士，棋盘、牛毛地皮，8大理石树，Maxwell 雕像
        "Maxwell3",      -- 5发条骑士，棋盘、牛毛地皮，Maxwell 雕像
        "Maxwell4",      -- 棋盘、牛毛地皮，8大理石树，Maxwell 雕像
        "Maxwell5",      -- 1发条骑士，牛毛地皮，8竖琴雕像，Maxwell 雕像，少量恶魔花
        "Maxwell6",      -- 5大理石树，牛毛地皮
        "Maxwell7",      -- 2发条骑士，棋盘、牛毛地皮，4大理石树，Maxwell 雕像，少量恶魔花
        "Warzone_1",
        "Warzone_2",
        "Warzone_3"
      },
      required_prefabs={ "multiplayer_portal" },
      -- 必须包含的雕像种类，而非随机生成。这里指定必须生成完整的三棋子雕像
      required_setpieces={ "Sculptures_1" },
      settings_desc="The standard Don't Starve experience.",
      settings_id="SURVIVAL_TOGETHER",
      settings_name="Standard Forest",
      substitutes={  },
      version=4,
      worldgen_desc="The standard Don't Starve experience.",
      worldgen_id="SURVIVAL_TOGETHER",
      worldgen_name="Standard Forest"
    }
    ```
-   地下世界基础配置文件

    ```lua
    return {
      background_node_range={ 0, 1 },
      desc="Delve into the caves... together!",
      hideminimap=false,
      id="DST_CAVE",
      location="cave",
      max_playlist_position=999,
      min_playlist_position=0,
      name="The Caves",
      numrandom_set_pieces=0,
      override_level_string=false,
      overrides={
        -- 资源设置的可选项分别为:
        ----- "never"    无
        ----- "rare"     较少
        ----- "default"  默认
        ----- "often"    较多
        ----- "always"   大量

        -- 资源再生的可选项分别为:
        ----- "never"     从不
        ----- "veryslow"  非常慢
        ----- "slow"      缓慢
        ----- "default"   默认
        ----- "fast"      快速
        ----- "veryfast"  非常快

        -- 世界设置
        --- 特殊事件
        ----- "none"                 无
        ----- "default"              自动
        ----- "crow_carnival"        盛夏鸦年华
        ----- "hallowed_nights"      万圣之夜
        ----- "winters_feast"        冬季盛宴
        ----- "year_of_the_gobbler"  火鸡之年
        ----- "year_of_the_varg"     座狼之年
        ----- "year_of_the_pig"      猪王之年
        ----- "year_of_the_carrat"   胡萝卜鼠之年
        ----- "year_of_the_beefalo"  皮弗娄牛之年
        specialevent="default",
        --- 季节
        ----- "noseason"         无季节
        ----- "veryshortseason"  非常短
        ----- "shortseason"      较短
        ----- "default"          默认长度
        ----- "longseason"       较长
        ----- "verylongseason"   非常长
        ----- "random"           随机长度
        autumn="default",  --- 秋季, 根据设置天数依次为 5 / 12 / 20 / 30 / 50
        winter="default",  --- 冬季, 根据设置天数依次为 5 / 10 / 15 / 22 / 40
        spring="default",  --- 春季, 根据设置天数依次为 5 / 12 / 20 / 30 / 50
        summer="default",  --- 夏季, 根据设置天数依次为 5 / 10 / 15 / 22 / 40
        atriumgate="default",    --- 中庭大门重置 (不可置为 never)
        wormattacks="default",   --- 深渊蠕虫攻击
        earthquakes="default",   --- 地震
        weather="default",       --- 漏雨
        --- 天类型
        ----- "default"    默认
        ----- "longday"    加长白天
        ----- "longdusk"   加长黄昏
        ----- "longnight"  加长黑夜
        ----- "noday"      无白天
        ----- "nodusk"     无黄昏
        ----- "nonight"    无黑夜
        ----- "onlyday"    只有白天
        ----- "onlydusk"   只有黄昏
        ----- "onlynight"  只有黑夜
        day="default",
        beefaloheat="default",  --- 野牛发情
        krampus="default",      --- 坎普斯

        -- 求生者设置
        --- 额外起始资源
        ----- "0"        总是
        ----- "5"        5 天后
        ----- "default"  10 天后
        ----- "15"       15 天后
        ----- "20"       20 天后
        ----- "none"     从不
        extrastartingitems="default",
        seasonalstartingitems="default",    --- 季节起始物品, "never" / "default"
        spawnprotection="default",          --- 出生点保护, "never" / "default" / "always"
        dropeverythingondespawn="default",  --- 退出掉落物品, "default" / "always"
        brightmarecreatures="default",      --- 启蒙怪兽数量
        shadowcreatures="default",          --- 理智怪兽数量

        -- 资源再生设置
        regrowth="default",                     --- 重生速度
        flower_cave_regrowth="default",         --- 荧光果再生
        lightflier_flower_regrowth="default",   --- 变异荧光果再生
        mushtree_moon_regrowth="default",       --- 变异蘑菇树再生
        mushtree_regrowth="default",            --- 蘑菇树再生

        -- 生物设置
        lightfliers="default",        --- 球状光虫
        bunnymen_setting="default",   --- 兔人
        dustmoths="default",          --- 尘蛾
        grassgekkos="default",        --- 草蜥蜴
        moles_setting="default",      --- 鼹鼠
        mushgnome="default",          --- 蘑菇地精
        pigs_setting="default",       --- 猪人
        rocky_setting="default",      --- 石虾
        slurtles_setting="default",   --- 蛞蝓龟
        snurtles="default",           --- 蜗牛龟
        monkey_setting="default",     --- 穴居猴

        -- 敌对生物设置
        bats_setting="default",         --- 蝙蝠
        spider_hider="default",         --- 洞穴蜘蛛
        spider_dropper="default",       --- 穴居蜘蛛
        merms="default",                --- 鱼人
        molebats="default",             --- 裸鼹鼠蝙蝠
        nightmarecreatures="default",   --- 暴动暗影生物
        spider_warriors="default",      --- 蜘蛛战士, "never" / "default"
        spiders_setting="default",      --- 蜘蛛
        spider_spitter="default",       --- 喷吐蜘蛛

        -- 巨型生物设置
        fruitfly="default",      --- 果蝇王
        spiderqueen="default",   --- 蜘蛛女王
        liefs="default",         --- 树精守卫
        toadstool="default",     --- 毒菌蟾蜍





        -- 世界生成中等级分别为:
        ----- "never"      无
        ----- "uncommon"   很少
        ----- "rare"       较少
        ----- "default"    默认
        ----- "often"      较多
        ----- "mostly"     很多
        ----- "always"     大量
        ----- "insane"     疯狂

        -- 全局生成
        --- 起始季节
        ----- "default"                      秋
        ----- "winter"                       冬
        ----- "spring"                       春
        ----- "summer"                       夏
        ----- "autumn|spring"                秋或春
        ----- "winter|summer"                冬或夏
        ----- "autumn|winter|spring|summer"  随机
        season_start="default",

        -- 世界生成
        task_set="cave_default",   --- 生物群落, 仅 "cave_default"
        start_location="caves",    --- 出生点, 仅 "caves"
        world_size="default",      --- 世界大小, "small" / "medium" / "default" / "huge"
        --- 世界分支
        ----- "never"    从不
        ----- "least"    少
        ----- "default"  默认
        ----- "most"     多
        ----- "random"   随机
        branching="default",
        loop="default",                      --- 环形世界, "never" / "default" / "always"
        touchstone="default",                --- 试金石
        boons="default",                     --- 前辈
        cavelight="default",                 --- 洞穴光, 值同资源再生选项
        prefabswaps_start="default",         --- 初始资源多样化, "classic" / "default" / "highly random"
        roads="never",                       --- 道路, "never" / "default"
        wormhole_prefab="tentacle_pillar",   --- 虫洞多样性, "wormhole" (虫洞) / "tentacle_pillar" (巨大触手)

        -- 资源
        berrybush="default",     --- 浆果从
        rock="default",          --- 岩石
        banana="default",        --- 洞穴香蕉
        fern="default",          --- 洞穴苔藓
        flint="default",         --- 燧石
        wormlights="default",    --- 发光浆果
        grass="default",         --- 草
        lichen="default",        --- 蓝色菌藻
        flower_cave="default",   --- 荧光果
        mushtree="default",      --- 蘑菇树
        mushroom="default",      --- 蘑菇
        cave_ponds="default",    --- 池塘
        reeds="default",         --- 芦苇
        sapling="default",       --- 小树苗
        marshbush="default",     --- 荆棘树枝
        trees="default",         --- 树 (所有)

        -- 生物及刷新点
        bunnymen="default",   --- 兔人房
        rocky="default",      --- 石虾窝
        slurper="default",    --- 啜食兽
        slurtles="default",   --- 蛞蝓丘
        monkey="default",     --- 穴居猴窟

        -- 敌对生物及刷新点
        bats="default",           --- 蝙蝠洞
        worms="default",          --- 深渊蠕虫
        chess="default",          --- 发条装置
        fissure="default",        --- 远古裂隙
        spiders="default",        --- 蜘蛛巢
        cave_spiders="default",   --- 石笋蛛巢
        tentacles="default",      --- 触手



        -- Other
        layout_mode="RestrictNodesByKey"
      },
      required_prefabs={ "multiplayer_portal" },
      settings_desc="Delve into the caves... together!",
      settings_id="DST_CAVE",
      settings_name="The Caves",
      substitutes={  },
      version=4,
      worldgen_desc="Delve into the caves... together!",
      worldgen_id="DST_CAVE",
      worldgen_name="The Caves"
    }
    ```

说明一下，测试时发现地下修改为虫洞，而非大触手时，跳虫洞将导致服务器崩溃。使用了服务器虫洞着色插件 **wormhole marks**，目前不清楚是 mod 问题还是游戏本身问题。


#### 启动程序 {#启动程序}

个人十分喜欢利用 systemd 来管理这些服务器的启停，使用 systemd 首先需要知道 DST
服务器的命令行参数。

-   **console** 指示这个服务器可以使用控制台
-   **persistent_storage_root** 指定世界位面存储在什么地方，默认存在于
    `$HOME/.klei`，个人不推荐修改默认目录
-   **conf_dir** 指定使用哪个位面的配置目录。默认目录为 DoNotStarveTogether，简单来说一个配置目录中有多个 **ClusterNum** 组成，如果想开多个完全不同的服务器，可以使用该参数修改路径
-   **shard** 指定启动哪个世界，一般为地上、地下世界的启动指示，当然不排除你一个位面中存在多个地上世界

我的个人服务器就用到了这些参数，一般来说够用了。接下来就是期待的 systemd 示例！

```text
[Unit]
Description=GinShio's Don't Starve Together Server
Documentation=https://dontstarve.fandom.com/wiki/Don't_Starve_Wiki
After=network.target

[Service]
Type=simple
User=steam
WorkingDirectory=/home/steam/dst/bin64
TimeoutStartSec=infinity
ExecStart=/home/steam/dst/bin64/dontstarve_dedicated_server_nullrenderer_x64 -console -conf_dir %i -shard Master
ExecStartPost=/home/steam/dst/bin64/dontstarve_dedicated_server_nullrenderer_x64 -console -conf_dir %i -shard Caves
ExecReload=/bin/kill -HUP
Restart=on-failure
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target
```

我所使用的是 `dst@.service`，这样只需要在启动不同位面时，在 `@` 之后加上目录名即可。由于 ExecStartPost 是启动地下世界，这是一个 simple 类型的命令，所以需要设置超时时间为无限 (即 **TimeoutStartSec=infinity** 来保证 systemd 不会杀掉服务器)。同时也是这个原因，在 start 时并不会结束命令，所以我一般重启服务器利用关机重启来重启这个命令。

举个例子，我有一个冬季盛宴位面在 Winter 目录下，一个万圣节位面在 Dracula 目录下。我想关停万圣节位面关停冬季盛宴位面，即可使用以下命令

```shell
systemctl disable dst@Winter   # 开机不启动冬季盛宴位面
systemctl disable dst@Dracula  # 开机启动万圣节位面
systemctl reboot               # 关机重启服务器
```


#### openSUSE 遇到的问题 {#opensuse-遇到的问题}

-   steamcmd `ILocalize::AddFile() failed to load file
        "public/steambootstrapper_english.txt".`

    ```shell
    steamcmd --reset
    ```
-   找不到 **libcurl-gnutls**

    ```shell
    ln -s /usr/lib64/libcurl.so.4 /usr/lib64/libcurl-gnutls.so.4
    ```

<style>
div.info{background:rgba(58,129,195,0.15);border-left:4px solid rgba(58,129,195,0.45);margin:1.8rem 0 1.25rem 15px;padding:0.8em;line-height:1.4;text-align:left;position:relative;clear:both}div.info p{margin:0}div.info::before{content:"i";background:rgba(58,129,195,0.8);align-items:flex-end;top:-1rem;font-weight:700;font-size:1.4rem;-webkit-clip-path:circle(50% at 50% 50%);clip-path:circle(50% at 50% 50%);width:30px;height:30px;display:inline-flex;justify-content:center;position:absolute;left:-1.2rem;line-height:1.3;text-align:left}div.success{background:rgba(45,149,116,0.15);border-left:4px solid rgba(45,149,116,0.45);margin:1.8rem 0 1.25rem 15px;padding:0.8em;line-height:1.4;text-align:left;position:relative;clear:both}div.success p{margin:0}div.success::before{content:"✔";background:rgba(45,149,116,0.8);align-items:flex-end;top:-1rem;font-weight:700;font-size:1.4rem;-webkit-clip-path:polygon(50% 0%, 100% 50%, 50% 100%, 0% 50%);clip-path:polygon(50% 0%, 100% 50%, 50% 100%, 0% 50%);width:35px;height:35px;display:inline-flex;justify-content:center;position:absolute;left:-1.2rem;line-height:1.5;text-align:left}div.warning{background:rgba(220,117,47,0.15);border-left:4px solid rgba(220,117,47,0.45);margin:1.8rem 0 1.25rem 15px;padding:0.8em;line-height:1.4;text-align:left;position:relative;clear:both}div.warning p{margin:0}div.warning::before{content:"!";background:rgba(220,117,47,0.8);align-items:flex-end;top:-1rem;font-weight:700;font-size:1.4rem;-webkit-clip-path:polygon(50% 0, 0 100%, 100% 100%);clip-path:polygon(50% 0, 0 100%, 100% 100%);width:35px;height:35px;display:inline-flex;justify-content:center;position:absolute;left:-1.2rem;line-height:1.1;text-align:left}div.error{background:rgba(186,47,89,0.15);border-left:4px solid rgba(186,47,89,0.45);margin:1.8rem 0 1.25rem 15px;padding:0.8em;line-height:1.4;text-align:left;position:relative;clear:both}div.error p{margin:0}div.error::before{content:"!";background:rgba(186,47,89,0.8);align-items:flex-end;top:-1rem;font-weight:700;font-size:1.4rem;-webkit-clip-path:polygon(25% 0%, 75% 0%, 100% 50%, 75% 100%, 25% 100%, 0% 50%);clip-path:polygon(25% 0%, 75% 0%, 100% 50%, 75% 100%, 25% 100%, 0% 50%);width:35px;height:30px;display:inline-flex;justify-content:center;position:absolute;left:-1.2rem;line-height:1.1;text-align:left}
</style>

