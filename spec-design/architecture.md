# 系统架构设计

## 1. 整体架构

采用分层架构 + 组件化设计，利用 Godot 的场景树和节点系统。

```
┌─────────────────────────────────────────────┐
│                  Game Layer                  │
│  ┌─────────┐ ┌──────────┐ ┌──────────────┐  │
│  │ MainMenu│ │ GameWorld│ │ ResultScreen │  │
│  └─────────┘ └──────────┘ └──────────────┘  │
├─────────────────────────────────────────────┤
│               System Layer                   │
│  ┌────────┐ ┌────────┐ ┌────────┐ ┌──────┐  │
│  │Weapon  │ │Enemy   │ │Level   │ │Map   │  │
│  │System  │ │System  │ │System  │ │Gen   │  │
│  ├────────┤ ├────────┤ ├────────┤ ├──────┤  │
│  │Route   │ │Forge   │ │Narrat- │ │Loot  │  │
│  │System  │ │System  │ │ive Sys │ │System│  │
│  └────────┘ └────────┘ └────────┘ └──────┘  │
├─────────────────────────────────────────────┤
│              Manager Layer (Autoload)        │
│  ┌────────┐ ┌────────┐ ┌────────┐ ┌──────┐  │
│  │Game    │ │Event   │ │Save    │ │Audio │  │
│  │Manager │ │Bus     │ │Manager │ │Mgr   │  │
│  ├────────┤ ├────────┤                       │
│  │Scene   │ │Config  │                       │
│  │Manager │ │Manager │                       │
│  └────────┘ └────────┘                       │
├─────────────────────────────────────────────┤
│              Data Layer                      │
│  ┌────────┐ ┌────────┐ ┌────────────────┐   │
│  │Resource│ │Config  │ │PlayerData      │   │
│  │Defs    │ │Tables  │ │(Meta Progress) │   │
│  └────────┘ └────────┘ └────────────────┘   │
└─────────────────────────────────────────────┘
```

## 2. Godot 项目目录结构

```
res://
├── project.godot
├── scenes/
│   ├── main_menu/
│   │   ├── main_menu.tscn
│   │   ├── character_select.tscn
│   │   └── meta_upgrade.tscn
│   ├── game/
│   │   ├── game_world.tscn          # 主游戏场景
│   │   ├── player/
│   │   │   ├── player.tscn
│   │   │   └── player.gd
│   │   ├── enemies/
│   │   │   ├── base_enemy.tscn
│   │   │   ├── base_enemy.gd
│   │   │   ├── fast_enemy.tscn
│   │   │   ├── tank_enemy.tscn
│   │   │   ├── ranged_enemy.tscn
│   │   │   ├── elite_enemy.tscn
│   │   │   └── boss/
│   │   │       ├── base_boss.tscn
│   │   │       ├── base_boss.gd
│   │   │       ├── rock_colossus.tscn    # 第一章Boss
│   │   │       ├── flame_lord.tscn       # 第二章Boss
│   │   │       ├── frost_king.tscn       # 第三章Boss
│   │   │       └── void_lord.tscn        # 最终Boss
│   │   ├── weapons/
│   │   │   ├── base_weapon.tscn
│   │   │   ├── base_weapon.gd
│   │   │   ├── projectiles/
│   │   │   │   ├── base_projectile.tscn
│   │   │   │   ├── homing_projectile.gd
│   │   │   │   ├── linear_projectile.gd
│   │   │   │   └── aoe_projectile.gd
│   │   │   └── implementations/
│   │   │       ├── magic_missile.gd
│   │   │       ├── holy_aura.gd
│   │   │       ├── flame_jet.gd
│   │   │       ├── chain_lightning.gd
│   │   │       ├── frost_nova.gd
│   │   │       └── throwing_knife.gd
│   │   ├── pickups/
│   │   │   ├── xp_gem.tscn
│   │   │   ├── coin.tscn
│   │   │   ├── health_orb.tscn
│   │   │   ├── magnet.tscn
│   │   │   └── ore.tscn                  # 矿石掉落物
│   │   └── map/
│   │       ├── room.tscn
│   │       ├── corridor.tscn
│   │       ├── tilemap/
│   │       ├── props/                    # 可破坏物/环境交互物
│   │       └── hazards/                  # 环境危害（水流/熔岩/冰面等）
│   ├── safe_camp/                        # 安全营地（章节间休息区）
│   │   ├── safe_camp.tscn
│   │   ├── npc_area.tscn                 # NPC交互区域
│   │   ├── forge_station.tscn            # 锻造台
│   │   └── memory_altar.tscn            # 记忆祭坛（查看记忆碎片）
│   ├── narrative/                        # 叙事场景
│   │   ├── chapter_transition.tscn       # 章节转场
│   │   ├── dialogue_box.tscn             # 对话框UI
│   │   └── ending_screen.tscn            # 结局画面
│   ├── ui/
│   │   ├── hud/
│   │   │   ├── hud.tscn
│   │   │   ├── health_bar.tscn
│   │   │   ├── stamina_bar.tscn          # 耐力条
│   │   │   ├── xp_bar.tscn
│   │   │   ├── weapon_slots.tscn
│   │   │   ├── accessory_slots.tscn      # 饰品栏
│   │   │   ├── minimap.tscn
│   │   │   ├── room_timer.tscn           # 房间战斗计时器
│   │   │   ├── ore_counter.tscn          # 矿石计数
│   │   │   ├── route_indicator.tscn      # 路线亲和度指示
│   │   │   └── env_gauge.tscn            # 环境计量表（冻伤/虚空腐蚀）
│   │   ├── level_up/
│   │   │   ├── level_up_panel.tscn
│   │   │   └── upgrade_card.tscn
│   │   ├── shop/
│   │   │   ├── shop_panel.tscn           # 商店界面
│   │   │   └── shop_item_card.tscn       # 商品卡片
│   │   ├── forge/
│   │   │   └── forge_panel.tscn          # 锻造界面
│   │   ├── pause_menu.tscn
│   │   └── result_screen.tscn
│   └── effects/
│       ├── hit_effect.tscn
│       ├── death_effect.tscn
│       ├── level_up_effect.tscn
│       └── env_effects/                  # 环境特效
│           ├── water_splash.tscn
│           ├── lava_burn.tscn
│           ├── ice_frost.tscn
│           └── void_corruption.tscn
├── scripts/
│   ├── autoload/
│   │   ├── game_manager.gd           # 游戏状态管理
│   │   ├── event_bus.gd              # 全局信号总线
│   │   ├── save_manager.gd           # 存档管理
│   │   ├── audio_manager.gd          # 音频管理
│   │   ├── config_manager.gd         # 配置表加载
│   │   └── scene_manager.gd          # 场景切换管理
│   ├── systems/
│   │   ├── weapon_system.gd          # 武器管理逻辑
│   │   ├── enemy_spawner.gd          # 敌人生成器
│   │   ├── level_system.gd           # 升级系统
│   │   ├── loot_system.gd            # 掉落系统
│   │   ├── damage_system.gd          # 伤害计算
│   │   ├── map_generator.gd          # 地图生成
│   │   ├── route_system.gd           # 路线亲和度系统
│   │   ├── narrative_system.gd       # 叙事/对话系统
│   │   ├── forge_system.gd           # 锻造系统
│   │   └── stamina_system.gd         # 耐力系统
│   ├── components/
│   │   ├── health_component.gd       # 生命值组件
│   │   ├── hitbox_component.gd       # 攻击判定组件
│   │   ├── hurtbox_component.gd      # 受击判定组件
│   │   ├── movement_component.gd     # 移动组件
│   │   └── stats_component.gd        # 属性组件
│   └── utils/
│       ├── object_pool.gd            # 对象池
│       ├── weighted_random.gd        # 加权随机
│       └── math_utils.gd             # 数学工具
├── resources/
│   ├── characters/                   # 角色定义 Resource
│   ├── weapons/                      # 武器定义 Resource
│   ├── passives/                     # 被动技能定义 Resource
│   ├── enemies/                      # 敌人定义 Resource
│   ├── evolutions/                   # 进化配方 Resource
│   ├── meta_upgrades/                # Meta升级定义 Resource
│   ├── accessories/                  # 饰品定义 Resource
│   ├── narrative/                    # 叙事资源（NarrativeResource）
│   └── forge_recipes/                # 锻造配方 Resource
├── data/
│   ├── balance/                      # 数值平衡配置表 (JSON)
│   │   ├── xp_curve.json
│   │   ├── enemy_scaling.json
│   │   ├── drop_tables.json
│   │   ├── shop_items.json
│   │   ├── boss_phases.json
│   │   ├── environment_config.json
│   │   ├── narrative_index.json
│   │   └── achievements.json
│   └── i18n/                         # 本地化文件
│       ├── zh_CN.csv
│       └── en.csv
├── assets/
│   ├── sprites/
│   │   ├── characters/               # 角色精灵（AI生成→像素化）
│   │   ├── enemies/                  # 敌人精灵
│   │   ├── weapons/                  # 武器/弹幕精灵
│   │   ├── tilesets/                 # 地图瓦片集（按章节分）
│   │   ├── ui/                       # UI图标和装饰
│   │   └── effects/                  # 特效精灵表
│   ├── audio/
│   │   ├── bgm/                      # 背景音乐（OGG格式）
│   │   ├── sfx/                      # 音效（WAV格式）
│   │   └── ambience/                 # 环境音效（OGG格式）
│   ├── fonts/
│   └── shaders/
└── addons/                           # 第三方插件（GdUnit4等）
```

## 3. Autoload 单例设计

### 3.1 GameManager
全局游戏状态管理器，控制游戏生命周期。

```gdscript
# 职责：
# - 管理游戏状态（菜单/游戏中/暂停/结算）
# - 持有当前局的运行时数据（时间、击杀数、金币等）
# - 协调各系统的初始化和清理

enum GameState { MENU, PLAYING, PAUSED, LEVEL_UP, GAME_OVER, RESULT }

var current_state: GameState
var run_data: RunData          # 当前局运行时数据
var meta_data: MetaData        # 永久进度数据
```

### 3.2 EventBus
全局信号总线，解耦模块间通信。完整信号定义详见 data-structures.md 信号接口表。

```gdscript
# 核心信号（共20个，完整列表见 data-structures.md）：

# 战斗相关
signal enemy_killed(enemy: BaseEnemy, position: Vector2)
signal damage_dealt(target: Node2D, amount: float, damage_type: DamageType, is_crit: bool)
signal player_died()

# 经验与升级
signal xp_gained(amount: int)
signal player_leveled_up(new_level: int)
signal pickup_collected(pickup_type: String, value: float)

# 武器与被动
signal weapon_acquired(weapon_def: WeaponDef)
signal weapon_upgraded(weapon_id: String, new_level: int)
signal passive_acquired(passive_def: PassiveDef)
signal accessory_acquired(accessory_def: AccessoryDef)

# 关卡进度
signal room_cleared(room: Room)
signal room_entered(room_type: String, floor_index: int)
signal floor_completed(floor_index: int)

# 经济与资源
signal gold_changed(new_amount: int)
signal ore_changed(new_amount: int)

# 叙事与路线
signal narrative_choice(chapter_id: String, segment_id: String, choice: Dictionary)
signal route_changed(new_alignment: float)
signal memory_fragment_found(fragment_id: String, category: String)

# 环境
signal frostbite_changed(new_value: float)
signal void_corruption_changed(new_value: float)
```

### 3.3 SaveManager
存档管理，处理 Meta 进度的持久化。

```gdscript
# 职责：
# - 加载/保存 Meta 进度到本地文件
# - 数据加密（AES-256）
# - 数据校验（SHA-256 哈希）
# - 自动保存（Meta进度变更时）
```

### 3.4 ConfigManager
配置表管理，加载外部数据驱动的配置。

```gdscript
# 职责：
# - 启动时加载所有 JSON 配置表到内存
# - 提供类型安全的配置访问接口
# - 支持热重载（开发模式下文件变更自动重载）
# - 缺失配置文件时 push_error 并使用内置默认值

var _configs: Dictionary = {}

func _ready() -> void:
    _load_all_configs()

func _load_all_configs() -> void:
    var config_files = [
        "xp_curve", "enemy_scaling", "drop_tables",
        "shop_items", "environment_config", "boss_phases",
        "narrative_index", "achievements"
    ]
    for config_name in config_files:
        var path = "res://data/balance/%s.json" % config_name
        var data = _load_json(path)
        if data != null:
            _configs[config_name] = data
        else:
            push_error("Failed to load config: %s" % path)

# 访问接口
func get_config(config_name: String) -> Variant:
    return _configs.get(config_name)

func get_floor_scaling(floor_index: int) -> Dictionary:
    var scaling = _configs.get("enemy_scaling", {})
    var key = str(floor_index)
    return scaling.get("floor_multipliers", {}).get(key, {})

func get_xp_for_level(level: int) -> int:
    var curve = _configs.get("xp_curve", {})
    return int(curve.get("base_xp", 10) * pow(level, curve.get("exponent", 1.3)))
```

### 3.5 SceneManager
场景切换管理器，处理场景加载、过渡动画和预加载。

```gdscript
# 职责：
# - 管理场景切换（带淡入淡出过渡效果）
# - 场景预加载（后台线程加载）
# - 切换时自动清理旧场景资源
# - 切换耗时 ≤ 0.5s（NFR性能要求）

var _current_scene: Node = null
var _transition_layer: CanvasLayer      # 过渡动画层

func transition_to(scene_path: String, transition: String = "fade") -> void:
    # 1. 播放淡出动画
    # 2. 后台加载新场景（ResourceLoader.load_threaded_request）
    # 3. 卸载当前场景
    # 4. 实例化新场景
    # 5. 播放淡入动画
    pass

func preload_scene(scene_path: String) -> void:
    # 后台预加载，不立即切换
    ResourceLoader.load_threaded_request(scene_path)

func is_scene_ready(scene_path: String) -> bool:
    return ResourceLoader.load_threaded_get_status(scene_path) == ResourceLoader.THREAD_LOAD_LOADED

# 常用跳转
func go_to_safe_camp() -> void:
    transition_to("res://scenes/safe_camp/safe_camp.tscn", "fade")

func go_to_chapter_transition(chapter_id: String) -> void:
    transition_to("res://scenes/narrative/chapter_transition.tscn")

func go_to_game_world(floor_index: int) -> void:
    transition_to("res://scenes/game/game_world.tscn")
```

### 3.6 AudioManager
音频管理器，控制背景音乐、音效和环境音。

```gdscript
# 职责：
# - 管理3条音频总线: BGM / SFX / Ambience
# - BGM 平滑过渡（交叉淡入淡出，1-2秒）
# - 音效播放（支持同时多个，对象池管理AudioStreamPlayer）
# - 环境音效循环
# - 音量独立控制，持久化到存档

# 音频总线布局:
# Master
#   ├── BGM      (背景音乐，单轨 + 交叉淡入)
#   ├── SFX      (音效，多轨并发，最多16个同时)
#   └── Ambience  (环境音效，循环播放)

var _bgm_player: AudioStreamPlayer
var _bgm_crossfade: AudioStreamPlayer   # 用于交叉淡入
var _sfx_pool: Array[AudioStreamPlayer] # 音效播放器池

func play_bgm(stream: AudioStream, fade_time: float = 1.5) -> void:
    # 交叉淡入：旧BGM淡出 + 新BGM淡入
    pass

func play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
    # 从池中获取空闲播放器，播放完毕自动回收
    pass

func play_ambience(stream: AudioStream) -> void:
    # 循环播放环境音效
    pass

func set_bus_volume(bus_name: String, volume_linear: float) -> void:
    # 0.0 = 静音, 1.0 = 最大
    var bus_idx = AudioServer.get_bus_index(bus_name)
    AudioServer.set_bus_volume_db(bus_idx, linear_to_db(volume_linear))

# 每章节BGM配置:
# 第一章: 低沉弦乐 + 水滴环境音
# 第二章: 打击乐 + 工业金属 + 岩浆环境音
# 第三章: 空灵女声 + 风声 + 冰裂环境音
# 最终章: 管弦乐 + 虚空嗡鸣
```

## 4. 组件化架构

采用组件模式（Component Pattern），将通用功能封装为可复用组件节点。

```
Player (CharacterBody2D)
├── Sprite2D
├── CollisionShape2D
├── HealthComponent          # 生命值管理
├── StatsComponent           # 属性管理（含Buff计算）
├── MovementComponent        # 移动控制
├── HurtboxComponent (Area2D) # 受击判定
├── WeaponMount              # 武器挂载点
│   ├── Weapon1
│   ├── Weapon2
│   └── ...
├── PickupArea (Area2D)      # 拾取范围
└── Camera2D

BaseEnemy (CharacterBody2D)
├── Sprite2D
├── CollisionShape2D
├── HealthComponent
├── StatsComponent
├── MovementComponent
├── HitboxComponent (Area2D)  # 接触伤害
├── HurtboxComponent (Area2D) # 受击判定
└── NavigationAgent2D         # 寻路（可选）
```

### 4.1 HealthComponent 规格

```gdscript
class_name HealthComponent extends Node

signal health_changed(current: float, maximum: float)
signal died()
signal damage_taken(amount: float, damage_type: DamageType)
signal healed(amount: float)

@export var max_hp: float = 100.0
var current_hp: float
var shield: float = 0.0           # 护盾（优先消耗）
var is_dead: bool = false

func take_damage(amount: float, damage_type: DamageType = DamageType.PHYSICAL) -> void:
    if is_dead: return
    # 先扣护盾
    if shield > 0:
        var shield_absorb = minf(shield, amount)
        shield -= shield_absorb
        amount -= shield_absorb
    current_hp -= amount
    damage_taken.emit(amount, damage_type)
    health_changed.emit(current_hp, max_hp)
    if current_hp <= 0:
        current_hp = 0
        is_dead = true
        died.emit()

func heal(amount: float) -> void:
    current_hp = minf(current_hp + amount, max_hp)
    healed.emit(amount)
    health_changed.emit(current_hp, max_hp)

func add_shield(amount: float) -> void:
    shield += amount
```

### 4.2 MovementComponent 规格

```gdscript
class_name MovementComponent extends Node

var base_speed: float = 200.0
var speed_multiplier: float = 1.0
var _external_forces: Array[Vector2] = []   # 环境力（水流/传送带等）

# 移动模式
enum MoveMode { NORMAL, SPRINT, ICE_SLIDE, KNOCKBACK }
var current_mode: MoveMode = MoveMode.NORMAL

func get_velocity(input_dir: Vector2) -> Vector2:
    var speed = base_speed * speed_multiplier
    match current_mode:
        MoveMode.SPRINT:
            speed *= 1.6  # 冲刺倍率（由 StaminaSystem 控制开关）
        MoveMode.ICE_SLIDE:
            # 冰面：惯性滑行，input_dir影响减弱
            input_dir = input_dir * 0.3 + _last_direction * 0.7
        MoveMode.KNOCKBACK:
            return _knockback_velocity  # 击退覆盖输入
    
    var velocity = input_dir * speed
    # 叠加环境力
    for force in _external_forces:
        velocity += force
    return velocity

func apply_env_force(force: Vector2) -> void:
    _external_forces.append(force)

func clear_env_forces() -> void:
    _external_forces.clear()
```

### 4.3 HitboxComponent / HurtboxComponent 规格

```gdscript
# HitboxComponent — 攻击方（玩家弹幕、敌人接触）
class_name HitboxComponent extends Area2D

signal hit(hurtbox: HurtboxComponent)

@export var damage: float = 0.0
@export var damage_type: DamageType = DamageType.PHYSICAL
@export var knockback_force: float = 100.0

# HurtboxComponent — 受击方（玩家、敌人）
class_name HurtboxComponent extends Area2D

signal hurt(hitbox: HitboxComponent)

var invincible: bool = false
var invincible_timer: float = 0.0     # 受击无敌帧

func _on_area_entered(hitbox: HitboxComponent) -> void:
    if invincible: return
    hurt.emit(hitbox)
    # 触发 DamageSystem.calculate_damage()
```

### 4.4 ObjectPool 规格

```gdscript
class_name ObjectPool extends Node

# 对象池管理器 — 管理所有可池化对象的复用
# 类型注册: 启动时预热，运行时按需扩展

var _pools: Dictionary = {}   # { "type_name": Array[Node] }
var _active: Dictionary = {}  # { "type_name": Array[Node] }

const MAX_POOL_SIZE: int = 500   # 单类型最大池容量（配合500敌人上限）

## 注册对象类型并预热
func register(type_name: String, scene: PackedScene, pre_warm: int = 10) -> void:
    _pools[type_name] = []
    _active[type_name] = []
    for i in pre_warm:
        var instance = scene.instantiate()
        instance.set_process(false)
        instance.visible = false
        _pools[type_name].append(instance)

## 获取对象（从池中取出或新建）
func acquire(type_name: String) -> Node:
    var pool = _pools.get(type_name, [])
    var instance: Node
    if pool.size() > 0:
        instance = pool.pop_back()
    elif _active[type_name].size() < MAX_POOL_SIZE:
        instance = _registered_scenes[type_name].instantiate()
    else:
        push_warning("Pool limit reached for: %s" % type_name)
        return null
    instance.set_process(true)
    instance.visible = true
    _active[type_name].append(instance)
    return instance

## 回收对象到池中
func release(type_name: String, instance: Node) -> void:
    instance.set_process(false)
    instance.visible = false
    _active[type_name].erase(instance)
    _pools[type_name].append(instance)

# 预热配置:
# - "enemy":      pre_warm=50,  max=500
# - "projectile": pre_warm=100, max=500
# - "pickup":     pre_warm=30,  max=200
# - "sfx_player": pre_warm=16,  max=32
```

## 5. 碰撞层设计

| Layer | 名称 | 说明 |
|-------|------|------|
| 1 | World | 地形碰撞 |
| 2 | Player | 玩家物理体 |
| 3 | Enemy | 敌人物理体 |
| 4 | PlayerHurtbox | 玩家受击区域 |
| 5 | EnemyHurtbox | 敌人受击区域 |
| 6 | PlayerProjectile | 玩家弹幕 |
| 7 | EnemyProjectile | 敌人弹幕 |
| 8 | Pickup | 可拾取物品 |
| 9 | RoomTrigger | 房间触发区域 |

碰撞矩阵：
- PlayerProjectile → EnemyHurtbox（玩家攻击命中敌人）
- EnemyProjectile → PlayerHurtbox（敌人攻击命中玩家）
- Enemy.HitboxComponent → PlayerHurtbox（接触伤害）
- Player.PickupArea → Pickup（拾取物品）
- Player → RoomTrigger（进入房间触发事件）

## 6. 性能优化策略

### 6.1 对象池（Object Pool）
- 弹幕、敌人、掉落物使用对象池管理
- 避免频繁 `instantiate()` / `queue_free()`
- 池大小动态扩展，上限可配置

### 6.2 空间分区
- 使用 Godot 内置的物理引擎进行碰撞检测
- 大量敌人场景使用 `MultiMeshInstance2D` 批量渲染
- 视野外敌人降低更新频率（LOD逻辑更新）

### 6.3 信号与延迟处理
- 伤害数字等非关键视觉效果使用 `call_deferred`
- 批量伤害计算使用帧分摊（每帧处理固定数量）
- 掉落物吸附使用 Tween 而非物理模拟
