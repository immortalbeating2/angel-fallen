# 数据结构与资源定义

## 1. Godot Resource 定义

### 1.1 角色定义 (CharacterDef)

```gdscript
class_name CharacterDef extends Resource

@export var id: String                          # 唯一标识 "char_knight"
@export var display_name: String                # 显示名称（i18n key）
@export var description: String                 # 描述（i18n key）
@export var sprite_frames: SpriteFrames         # 动画帧
@export var portrait: Texture2D                 # 立绘

# 基础属性
@export var base_hp: float = 100.0
@export var base_move_speed: float = 200.0
@export var base_armor: float = 0.0
@export var base_pickup_range: float = 64.0
@export var base_crit_rate: float = 0.05
@export var base_crit_damage: float = 1.5
@export var base_stamina: float = 100.0

# 初始装备
@export var starting_weapon_id: String          # 初始武器ID
@export var passive_ability: PassiveDef         # 角色专属被动

# 解锁条件
@export var unlock_type: String                 # "default" / "meta" / "achievement"
@export var unlock_requirement: String          # 解锁条件描述
@export var unlock_cost: int = 0                # Meta货币解锁费用
```

### 1.2 武器定义 (WeaponDef)

```gdscript
class_name WeaponDef extends Resource

@export var id: String                          # "wpn_magic_missile"
@export var display_name: String
@export var description: String
@export var icon: Texture2D
@export var rarity: int = 0                     # 0普通 1稀有 2传说

# 武器类型
@export var projectile_type: String             # "homing"/"orbit"/"cone"/"chain"/"circle"/"linear"
@export var damage_type: int = 0                # DamageType枚举

# 等级数据（数组索引=等级-1）
@export var max_level: int = 8
@export var damage_per_level: Array[float]      # [10, 13, 17, 22, 28, 35, 43, 55]
@export var cooldown_per_level: Array[float]    # [1.5, 1.4, 1.3, 1.2, 1.1, 1.0, 0.9, 0.8]
@export var projectile_count_per_level: Array[int]  # [1, 1, 2, 2, 3, 3, 4, 5]
@export var extra_per_level: Array[Dictionary]  # 每级特殊效果参数

# 弹道参数
@export var projectile_speed: float = 400.0
@export var projectile_range: float = 500.0
@export var projectile_size: float = 1.0
@export var pierce_count: int = 0               # 穿透次数
@export var knockback: float = 50.0

# 进化相关
@export var evolution_passive_id: String        # 进化所需被动ID（空=不可进化）
@export var evolved_weapon_id: String           # 进化后武器ID

# 场景引用
@export var weapon_scene: PackedScene           # 武器场景
@export var projectile_scene: PackedScene       # 弹幕场景

func get_damage(level: int) -> float:
    return damage_per_level[clampi(level - 1, 0, max_level - 1)]

func get_cooldown(level: int) -> float:
    return cooldown_per_level[clampi(level - 1, 0, max_level - 1)]

func get_projectile_count(level: int) -> int:
    return projectile_count_per_level[clampi(level - 1, 0, max_level - 1)]
```

### 1.3 被动技能定义 (PassiveDef)

```gdscript
class_name PassiveDef extends Resource

@export var id: String                          # "pas_might"
@export var display_name: String
@export var description: String
@export var icon: Texture2D
@export var rarity: int = 0

@export var max_level: int = 5

# 每级属性修改（数组索引=等级-1）
# 键为StatsComponent中的属性名，值为加成数值
@export var stat_modifiers_per_level: Array[Dictionary]
# 示例: [{"damage_mult": 0.1}, {"damage_mult": 0.2}, ...]

# 特殊效果（非纯数值的被动）
@export var special_effect: String              # 效果标识符，由代码处理
@export var special_params_per_level: Array[Dictionary]

func get_modifiers(level: int) -> Dictionary:
    return stat_modifiers_per_level[clampi(level - 1, 0, max_level - 1)]
```

### 1.4 敌人定义 (EnemyDef)

```gdscript
class_name EnemyDef extends Resource

@export var id: String                          # "enemy_slime"
@export var display_name: String
@export var enemy_type: String                  # "normal"/"fast"/"tank"/"ranged"/"elite"/"boss"
@export var sprite_frames: SpriteFrames

# 基础属性
@export var base_hp: float = 20.0
@export var base_damage: float = 10.0
@export var base_move_speed: float = 80.0
@export var base_armor: float = 0.0
@export var collision_radius: float = 16.0

# 行为参数
@export var ai_type: String                     # "chase"/"keep_distance"/"patrol"/"boss_phase"
@export var attack_range: float = 0.0           # 0=接触伤害
@export var attack_cooldown: float = 0.0
@export var projectile_scene: PackedScene       # 远程敌人的弹幕

# 掉落
@export var xp_value: int = 1
@export var drop_table_id: String               # 引用掉落表

# 精英/Boss特殊
@export var skills: Array[EnemySkillDef]        # 特殊技能列表
@export var phase_thresholds: Array[float]      # Boss阶段HP阈值 [0.66, 0.33]

# 生成权重（用于生成器选择）
@export var spawn_weight: int = 100
@export var min_floor: int = 1                  # 最早出现的楼层
@export var min_difficulty: float = 0.0         # 最低难度系数
```

### 1.5 敌人技能定义 (EnemySkillDef)

```gdscript
class_name EnemySkillDef extends Resource

@export var id: String
@export var skill_type: String          # "charge"/"aoe"/"summon"/"projectile_burst"/"buff"
@export var damage: float
@export var cooldown: float
@export var range: float
@export var warning_duration: float     # 预警时间（秒）
@export var params: Dictionary          # 技能特定参数
# charge: {"speed": 600, "duration": 0.5}
# aoe: {"radius": 150, "delay": 1.0}
# summon: {"enemy_id": "enemy_slime", "count": 5}
# projectile_burst: {"count": 8, "speed": 300, "spread": 360}
```

### 1.6 Meta升级定义 (MetaUpgradeDef)

```gdscript
class_name MetaUpgradeDef extends Resource

@export var id: String                  # "meta_max_hp"
@export var display_name: String
@export var description: String
@export var icon: Texture2D
@export var category: String            # "stats"/"economy"/"unlock"/"special"

@export var max_level: int = 5
@export var base_cost: int = 100
@export var cost_growth: float = 1.8    # 每级费用增长倍率

# 效果（每级）
@export var effect_per_level: Array[Dictionary]
# 示例: [{"max_hp": 5}, {"max_hp": 10}, ...]

# 前置条件
@export var prerequisites: Array[String]  # 需要先解锁的Meta升级ID
```

---

## 2. 运行时数据结构

### 2.1 单局运行数据 (RunData)

```gdscript
class_name RunData extends RefCounted

# 基础信息
var character_id: String
var current_floor: int = 1
var current_room_index: int = 0

# 计时与统计
var survive_time: float = 0.0
var enemies_killed: int = 0
var bosses_killed: int = 0
var damage_dealt_total: float = 0.0
var damage_taken_total: float = 0.0
var highest_combo: int = 0

# 经济
var gold: int = 0
var xp: int = 0
var level: int = 1

# 装备
var weapons: Array[WeaponInstance] = []         # 当前武器（最多6）
var passives: Array[PassiveInstance] = []       # 当前被动（最多6）

# 状态
var rerolls_used: int = 0
var revives_used: int = 0
var rooms_explored: int = 0
var items_purchased: int = 0

# 地图状态
var floor_map: FloorMap                         # 当前楼层地图数据
var explored_rooms: Array[int] = []             # 已探索房间索引
```

### 2.2 武器实例 (WeaponInstance)

```gdscript
class_name WeaponInstance extends RefCounted

var weapon_def: WeaponDef
var current_level: int = 1
var is_evolved: bool = false
var total_damage_dealt: float = 0.0     # 统计用
var total_kills: int = 0                # 统计用
```

### 2.3 被动实例 (PassiveInstance)

```gdscript
class_name PassiveInstance extends RefCounted

var passive_def: PassiveDef
var current_level: int = 1
```

### 2.4 Meta 永久数据 (MetaData)

```gdscript
class_name MetaData extends Resource

# 货币
var meta_currency: int = 0
var total_currency_earned: int = 0

# 升级等级
var upgrade_levels: Dictionary = {}     # {"meta_max_hp": 3, "meta_move_speed": 2, ...}

# 解锁状态
var unlocked_characters: Array[String] = ["char_knight"]  # 默认解锁
var unlocked_weapons: Array[String] = []
var unlocked_passives: Array[String] = []

# 成就
var achievements: Dictionary = {}       # {"ach_kill_1000": true, ...}

# 统计
var total_runs: int = 0
var total_kills: int = 0
var total_play_time: float = 0.0
var best_survive_time: float = 0.0
var highest_floor: int = 0
var best_run_kills: int = 0
```

### 2.5 楼层地图数据 (FloorMap)

```gdscript
class_name FloorMap extends RefCounted

var floor_index: int
var rooms: Array[RoomData] = []
var corridors: Array[CorridorData] = []
var start_room_index: int
var boss_room_index: int
var shop_room_index: int

class RoomData:
    var index: int
    var rect: Rect2i                    # 房间在tilemap中的矩形区域
    var center: Vector2i
    var room_type: String               # "start"/"normal"/"elite"/"shop"/"treasure"/"event"/"boss"
    var enemy_waves: Array[WaveData]    # 敌人波次配置
    var is_cleared: bool = false
    var connected_rooms: Array[int]     # 相邻房间索引

class CorridorData:
    var from_room: int
    var to_room: int
    var tiles: Array[Vector2i]          # 走廊占用的tile坐标

class WaveData:
    var enemies: Array[Dictionary]      # [{"enemy_id": "enemy_slime", "count": 5}, ...]
    var delay_before: float = 2.0       # 波次前延迟
```

---

## 3. 配置表结构 (JSON)

### 3.1 经验曲线 (xp_curve.json)

```json
{
    "base_xp": 10,
    "exponent": 1.3,
    "override": {
        "1": 5,
        "2": 8
    }
}
```

### 3.2 敌人缩放 (enemy_scaling.json)

```json
{
    "time_brackets": [
        {
            "time_min": 0, "time_max": 120,
            "spawn_interval": 1.5,
            "hp_multiplier": 1.0,
            "speed_multiplier": 1.0,
            "max_enemies": 50,
            "elite_chance": 0.0
        },
        {
            "time_min": 120, "time_max": 300,
            "spawn_interval": 1.2,
            "hp_multiplier": 1.5,
            "speed_multiplier": 1.1,
            "max_enemies": 100,
            "elite_chance": 0.05
        }
    ],
    "floor_multipliers": {
        "1": { "hp": 1.0, "damage": 1.0 },
        "2": { "hp": 1.8, "damage": 1.5 },
        "3": { "hp": 3.0, "damage": 2.0 },
        "4": { "hp": 5.0, "damage": 3.0 },
        "5": { "hp": 8.0, "damage": 4.5 }
    }
}
```

### 3.3 掉落表 (drop_tables.json)

```json
{
    "normal": {
        "guaranteed": ["xp_gem_small"],
        "random": [
            { "item": "coin", "weight": 15, "min": 1, "max": 3 },
            { "item": "health_orb", "weight": 3, "min": 1, "max": 1 }
        ]
    },
    "elite": {
        "guaranteed": ["xp_gem_large"],
        "random": [
            { "item": "coin", "weight": 60, "min": 5, "max": 15 },
            { "item": "health_orb", "weight": 20, "min": 1, "max": 2 },
            { "item": "chest", "weight": 10, "min": 1, "max": 1 },
            { "item": "magnet", "weight": 8, "min": 1, "max": 1 }
        ]
    },
    "boss": {
        "guaranteed": ["xp_gem_huge"],
        "random": [
            { "item": "coin", "weight": 100, "min": 20, "max": 50 },
            { "item": "chest_rare", "weight": 50, "min": 1, "max": 1 },
            { "item": "health_orb", "weight": 40, "min": 2, "max": 3 }
        ]
    }
}
```

### 3.4 进化配方表 (evolutions.json)

```json
{
    "evolutions": [
        {
            "id": "evo_holy_sword",
            "weapon_id": "wpn_magic_missile",
            "passive_id": "pas_might",
            "weapon_min_level": 8,
            "passive_min_level": 5,
            "result_weapon_id": "wpn_holy_sword"
        },
        {
            "id": "evo_inferno_ring",
            "weapon_id": "wpn_holy_aura",
            "passive_id": "pas_fire_mastery",
            "weapon_min_level": 8,
            "passive_min_level": 5,
            "result_weapon_id": "wpn_inferno_ring"
        },
        {
            "id": "evo_thunder_god",
            "weapon_id": "wpn_chain_lightning",
            "passive_id": "pas_lightning_mastery",
            "weapon_min_level": 8,
            "passive_min_level": 5,
            "result_weapon_id": "wpn_thunder_god"
        }
    ]
}
```

---

## 4. 存档文件结构

### 4.1 存档路径

```
user://save/
├── meta_save.dat          # Meta进度（加密）
├── meta_save.hash         # 校验哈希
└── settings.cfg           # 游戏设置（明文ConfigFile）
```

### 4.2 存档序列化

```gdscript
# SaveManager 序列化流程
func save_meta() -> void:
    var data = {
        "version": SAVE_VERSION,
        "timestamp": Time.get_unix_time_from_system(),
        "meta": meta_data.serialize()
    }
    var json_str = JSON.stringify(data)
    var encrypted = _encrypt(json_str)
    var hash = _compute_hash(json_str)
    
    # 写入文件
    var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    file.store_buffer(encrypted)
    file.close()
    
    # 写入校验
    var hash_file = FileAccess.open(HASH_PATH, FileAccess.WRITE)
    hash_file.store_string(hash)
    hash_file.close()

func load_meta() -> MetaData:
    if not FileAccess.file_exists(SAVE_PATH):
        return MetaData.new()  # 新存档
    
    var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
    var encrypted = file.get_buffer(file.get_length())
    file.close()
    
    var json_str = _decrypt(encrypted)
    
    # 校验完整性
    var expected_hash = FileAccess.get_file_as_string(HASH_PATH)
    if _compute_hash(json_str) != expected_hash:
        push_warning("Save file integrity check failed!")
        return MetaData.new()
    
    var data = JSON.parse_string(json_str)
    return MetaData.deserialize(data["meta"])
```

---

## 5. 信号接口汇总

| 信号 | 发射者 | 参数 | 监听者 |
|------|--------|------|--------|
| `enemy_killed` | HealthComponent | (enemy, position) | LootSystem, RunData, HUD |
| `damage_dealt` | DamageSystem | (target, amount, is_crit) | HUD(伤害数字), RunData |
| `player_leveled_up` | LevelSystem | (new_level) | GameManager(暂停), LevelUpPanel |
| `weapon_acquired` | WeaponSystem | (weapon_def) | Player(挂载), HUD |
| `weapon_upgraded` | WeaponSystem | (weapon_id, new_level) | HUD, EvolutionCheck |
| `passive_acquired` | WeaponSystem | (passive_def) | StatsComponent, HUD |
| `room_cleared` | Room | (room) | FloorMap, Minimap, DoorController |
| `floor_completed` | GameManager | (floor_index) | MapGenerator, RunData |
| `player_died` | HealthComponent | () | GameManager(结算) |
| `pickup_collected` | PickupArea | (type, value) | LevelSystem/RunData/HealthComponent |
| `gold_changed` | RunData | (new_amount) | HUD, ShopUI |
| `room_entered` | RoomTrigger | (room_data) | EnemySpawner, Minimap, EventSystem |
