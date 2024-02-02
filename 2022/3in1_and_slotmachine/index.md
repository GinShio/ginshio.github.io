# 三合一与恐怖抽奖机配置


本次介绍 mod 配置 [Tropical Experience | The Volcano Biome](https://steamcommunity.com/sharedfiles/filedetails/?id=1505270912) (热带冒险 | 火山生态群)，版本 v2.70，这也就是常说的 3 合 1

三合一是将单机版 DLC 巨人国、船难和哈姆雷特合并在一张地图上的 mod，大型但兼容性较差，请谨慎添加 mod。

-   **Kind of World** (世界类型)：世界生成需要三合一还是单一世界
    -   <span class="underline">custom</span> 表示三合一地图，这也是默认选项
    -   <span class="underline">shipwrecked</span> 表示仅海难
    -   <span class="underline">hamlet</span> 表示仅哈姆雷特
    -   <span class="underline">Sea World</span> 表示世界都是海，仅出生点一点点陆地

-   **for hamlet world** (哈姆雷特世界设置)
    -   `Hamlet Caves` (哈姆雷特洞穴): 是否启用 Hamlet 世界的 Hamlet 洞穴，需要开启世界洞穴设置
    -   `Together Caves` (巨人国洞穴): 是否启用 Hamlet 世界的巨人国洞穴，需要开启世界洞穴设置
    -   `Hamlet Clouds`: 是否采用 Hamlet 边界云质地
    -   `Continent Size` (大陆大小)
        -   <span class="underline">Compact</span> 袖珍
        -   <span class="underline">Default</span> 默认
        -   <span class="underline">Bigger</span>  巨大
    -   `Filling the Biomes`: 生物密度
    -   `Compact Pig Ruins`: 是否袖珍遗迹

-   **for shipwrecked world** (船难世界设置)
    -   `How many islands` (多少岛屿): 设置岛屿数量，Hamlet 与巨人国一共 8 岛，剩下的为船难岛屿数量，默认 30 (22 + 8)
    -   `Shipwrecked Plus`: 是否生成基于单机版船难 plus mod 的额外岛屿
    -   `Frost Island`: 是否生成三合一额外的冰雪岛屿
    -   `Moon Biome`: 是否在船难生成月亮生态
    -   `Hamlet Caves`: 是否启用船难世界的 Hamlet 洞穴，需要开启世界洞穴设置
    -   `Together Caves`: 是否启用 Hamlet 世界的巨人国洞穴，需要开启世界洞穴设置

-   **for custom world** (其他设置)，主要设置生态位置，其中包括 Disable (关闭)、
    Main Land (主大陆)、Continent (大陆)、Islands (岛屿)、Arquipelago (群岛)
    -   `Player Portal`: 玩家的出生点，Together (巨人国)、Shipwrecked (船难) 还是
        Hamlet (哈姆雷特)
    -   `Reign of Giants Biomes` (巨人国生态)
    -   `Lunar Biomes` (月岛生态)
    -   `Shipwrecked Biomes` (船难生态)
    -   `Shipwrecked_plus`: 是否生成 Shipwrecked Plus 的黄金国文明
    -   `Hamlet Biomes` (Hamlet 生态)
    -   `Swinesbury` (猪伯利)
    -   `The Royal Palace` (皇宫)
    -   `Pinacle` (峰顶)
    -   `Ant Hill` (蚁穴): Hamlet 蚁穴入口和皇后区
    -   `Ancient pig ruins` (远古猪人遗迹和灾变日历)
    -   `Peat Forest Island` (暴食森林岛屿)
    -   `Gorge City` (暴食镇)
    -   `Frost Land` (霜岛)
    -   `Hamlet Caves`: 是否启用 Hamlet 洞穴 (3in1 新加入的地形生态)

-   **for all worlds** (世界范围事件)
    -   `Volcano` (火山): 生成影响巨人国与船难世界的火山 (完整版火山需要洞穴支持，而袖珍版无需洞穴)
    -   `Forge Arena` (熔炉竞技场): 是否启用火山洞穴里熔炉竞技场
    -   `Underwater` (水下世界): 是否生成水下世界 (3in1 里新加入的船难洞穴)

-   **OCEAN SETTINGS** (海洋设置)
    -   `Waves` (海浪)
    -   `Aquatic Creatures` (水生生物)
    -   `Kraken` (海妖克拉肯)
    -   `Octopus King` (章鱼王)
    -   `Mangrove Biome` (红树林生态)
    -   `Lilypad Biome` (睡莲生态)
    -   `Ship Graveyard Biome` (船墓生态)
    -   `Coral Biome` (珊瑚礁生态)

-   **GAMEPLAY SETTINGS** (游戏设置)
    -   `Aporkalypse` (毁灭季): 每 60 天持续 20 天的大灾变
    -   `Sealnado` (豹卷风)

-   **WEATHER SETTINGS** (天气设置)
    -   `Flood` (洪水): 春天产生水坑，Disabled (关闭)、Tropical Zone (船难世界)、
        All world (全世界)
    -   `Wind` (大风): Disabled (关闭)、Tropical-Hamlet (船难-哈姆雷特世界)、All
        world (全世界)
    -   `Hail` (冰雹)
    -   `Volcanic Eruption` (火山喷发): Disabled (关闭)、Tropical Zone (船难世界)、
        All world (全世界)
    -   `Winter Fog` (大雾): Disabled (关闭)、Hamlet Zone (哈姆雷特世界)、All
        world (全世界)
    -   `Hay Fever` (花粉症): Disabled (关闭)、Hamlet Zone (哈姆雷特世界)、All
        world (全世界)

-   **SHARD-DEDICATED** (专用服务器配置)
    -   `Enable all prefabs` (启用预制件): 在专用服务器上需要开启
    -   `Tropical shards` (世界切片): 一个世界被称为一个 shard，通过洞穴进行切换，设置将不同 DLC 放置在不同 shard，默认将所有 DLC 放置在同一 shard
    -   `Lobby exit`

-   **OTHER MOD** (其他 MOD 兼容)
    -   `Cherry Forest` (樱桃森林): Mainland (主大陆)、Island (岛屿)、Grove (小岛)、
        Archipelago (群岛)、Moon Morphis (月岛)

-   **LUAJIT** (LuaJIT)

其余选项保持默认即可。

```lua
-- 前提说明：mod 配置里的
---- 关闭 (disable) 用 0 表示，开启 (enable) 用 1 表示
---- 是 (YES) 用 true 表示，否 (NO) 用 false 表示

-- Kind of World
----- 5:  hamlet
----- 10: shipwrecked
----- 15: custom
----- 20: Sea World
kindofworld=15,

--- for hamlet world
hamletcaves_hamletworld=1,         ---- Hamlet Caves
togethercaves_hamletworld=0,       ---- Together Caves
hamletclouds=true,                 ---- Hamlet Clouds
continentsize=2,                   ---- Continent: Compact (1), Default (2), Bigger (3)
fillingthebiomes=4,                ---- Filling the Biomes: 0% (0), 25% (1), 50% (2), 75% (3), 100% (4)
compactruins=false,                ---- Compact Pig Ruins

--- for shipwrecked world
howmanyislands=22,                 ---- How many islands
Shipwreckedworld_plus=true,        ---- Shipwrecked Plus
frost_islandworld=10,              ---- Frost Island, YES (10) / NO (5)
Moonshipwrecked=0,                 ---- Moon Biome
hamletcaves_shipwreckedworld=1,    ---- Hamlet Caves
togethercaves_shipwreckedworld=1,  ---- Together Caves

--- for custom world
----- Biome Value:
-----      5: Disable
-----     10: Continent
-----     15: Islands
-----     20: Main Land
-----     25: Arquipelago
startlocation=5,                  ---- Player Portal, Together(5) / Shipwrecked (10) / Hamlet (15)
Together=20,                      ---- Reign of Giants Biomes
Moon=10,                          ---- Lunar Biomes
Shipwrecked=25,                   ---- Shipwrecked Biomes
Shipwrecked_plus=true,            ---- Shipwrecked Plus
Hamlet=10,                        ---- Hamlet Biomes
----- Hamlet Island Value:
-----      5: Disable
-----     10: Main Land
-----     15: Continent
-----     20: Islands
pigcity1=15,                      ---- Swinesbury
pigcity2=15,                      ---- The Royal Palace
pinacle=1,                        ---- Pinacle
anthill=1,                        ---- Ant Hill
pigruins=1,                       ---- Ancient pig ruins
gorgeisland=1,                    ---- Peat Forest Island
gorgecity=1,                      ---- Gorge City
frost_island=10,                  ---- Frost Island, 5 (NO) / 10 (YES)
hamlet_caves=1,                   ---- Hamlet Caves

--- for all world
Volcano=true,                     ---- Volcano, true (Complete) / false (Compact)
forge=1,                          ---- Forge Arena
underwater=true,                  ---- Underwater

--- OCEAN SETTINGS
Waves=true,                       ---- Waves
aquaticcreatures=true,            ---- Aquatic Creatures
kraken=1,                         ---- Kraken
octopusking=1,                    ---- Octopus King
mangrove=1,                       ---- Mangrove Biome
lilypad=1,                        ---- Lilypad Biome
shipgraveyard=1,                  ---- Ship Graveyard Biome
coralbiome=1,                     ---- Coral Biome

--- GAMEPLAY SETTINGS
aporkalypse=true,                 ---- Aporkalypse
sealnado=true,                    ---- Sealnado

--- WEATHER SETTINGS
-----      5: Disabled
-----     10: Tropical Zone / Hamlet Zone / Tropical-Hamlet
-----     20: All world
flood=10,                         ---- Flood
wind=10,                          ---- Wind
hail=true,                        ---- Hail
volcaniceruption=10,              ---- Volcanic Eruption
fog=10,                           ---- Winter Fog
hayfever=10,                      ---- Hay Fever

--- HUD SETTINGS
boatlefthud=0,
city_tab=1,
disable_snow_effectst=false,
home_tab=1,
housewallajust=0,
megarandomCompatibilityWater=false,
nautical_tab=true,
obsidian_tab=1,
removedark=false,
seafaring_tab=false,
set_idioma="stringsEU",

--- SHARD-DEDICATED
enableallprefabs=false,           ---- Enable all prefabs
---- Tropical Shards
tropicalshards=0,                 ---- Tropical shards
lobbyexit=false,                  ---- Lobby exit

--- OTHER MOD
----     10: Mainland
----     20: Island
----     30: Grove
----     40: Archipelago
----     50: Moon Morphis
cherryforest=20,                  ---- Cherry Forest

--- LUAJIT
luajit=false,                     ---- luajit
```

恐怖抽奖机不需要配置，只用开启三合一与该 mod 即可。一般游玩可以关闭洞穴、只开启船难内容。

