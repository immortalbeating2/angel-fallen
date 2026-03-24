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

# 路线亲和度标签
@export var route_tag: String = "neutral"       # "holy"（神圣系）/ "void"（虚空系）/ "neutral"（中立）
@export var alignment_value: float = 0.0        # 选择此被动对亲和度的影响值（正=救赎，负=堕落）

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
@export var phase_thresholds: Array[float]      # Boss阶段HP阈值，由各Boss独立配置（如 [0.6, 0.3] 或 [0.75, 0.5, 0.25]）

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

### 1.7 饰品定义 (AccessoryDef)

```gdscript
class_name AccessoryDef extends Resource

@export var id: String                  # "acc_heart_of_vein"
@export var display_name: String
@export var description: String
@export var icon: Texture2D
@export var rarity: int = 2             # 饰品固定为传说品质

# 效果（饰品不可升级，效果固定）
@export var effect_type: String         # "on_hit"/"on_kill"/"passive"/"conditional"
@export var effect_params: Dictionary   # 效果参数，由代码处理
# 示例: {"trigger": "on_boss_hit", "damage_bonus": 0.25}

# 获取来源
@export var source: String              # "boss_drop"/"treasure"/"event"
@export var source_id: String           # 关联的Boss/事件ID
```

### 1.8 叙事资源 (NarrativeResource / NarrativeSegment)

```gdscript
class_name NarrativeSegment extends Resource
## 单个叙事片段

@export var id: String                          # "ch1_opening_01"
@export var type: String                        # "narration"（旁白）/ "dialogue"（对话）/ "choice"（选择）
@export var speaker: String                     # 说话者名称（旁白为空）
@export var text: String                        # 文本内容（i18n key）
@export var mood: String = "neutral"            # 情绪标签，影响表现（"neutral"/"dark"/"hope"/"fear"）
@export var choices: Array[Dictionary] = []     # 选择分支（仅 type="choice" 时有效）
# choices 示例: [{"text": "i18n_key", "alignment_change": 10, "next_segment": "ch1_choice_a"}]
```

```gdscript
class_name NarrativeResource extends Resource
## 章节叙事序列

@export var id: String                          # "narrative_ch1_opening"
@export var chapter_id: String                  # 所属章节 "chapter_1"
@export var trigger: String                     # 触发时机 "chapter_start"/"chapter_end"/"boss_defeated"
@export var segments: Array[NarrativeSegment]   # 叙事片段序列
@export var background: Texture2D               # 叙事背景图
@export var bgm: String                         # 背景音乐资源路径
```

### 1.9 锻造配方 (ForgeRecipe)

```gdscript
class_name ForgeRecipe extends Resource

@export var id: String                  # "forge_dmg_boost"
@export var display_name: String
@export var description: String
@export var ore_cost: int = 3           # 矿石消耗
@export var effect_type: String         # "damage_boost"/"element_add"/"cooldown_reduce"
@export var effect_value: float         # 效果数值（如 0.1 = +10% 伤害）
@export var target: String = "weapon"   # 作用对象 "weapon"/"passive"
@export var max_uses: int = 1           # 每件装备最大锻造次数
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
var survive_time: float = 0.0           # 总游戏时间
var room_combat_time: float = 0.0       # 当前房间战斗时间（进入战斗房间重置）
var enemies_killed: int = 0
var bosses_killed: int = 0
var damage_dealt_total: float = 0.0
var damage_taken_total: float = 0.0
var highest_combo: int = 0

# 经济
var gold: int = 0
var ore_count: int = 0                  # 当局矿石数量
var xp: int = 0
var level: int = 1

# 装备
var weapons: Array[WeaponInstance] = []         # 当前武器（最多6）
var passives: Array[PassiveInstance] = []       # 当前被动（动态上限，初始6，最多12）
var passive_slots_unlocked: int = 6             # 当前已解锁被动槽位数
var accessories: Array[AccessoryDef] = []       # 当前饰品（最多2）

# 叙事与路线
var alignment: float = 0.0              # 路线亲和度（-100 ~ +100，正=救赎，负=堕落）
var narrative_choices: Dictionary = {}  # {"choice_id": "selected_option", ...}
var memory_fragments: Array[String] = [] # 已收集的记忆碎片ID

# 环境状态
var frostbite: float = 0.0             # 冻伤值（0 ~ 100，仅第3章有效）
var void_corruption: float = 0.0       # 虚空腐蚀值（0 ~ 100，仅终章有效）

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
var chapter_id: String                          # 所属章节 "chapter_1" / "chapter_2" / ...
var theme: String                               # 楼层主题 "moss_dungeon" / "forge" / "ice_cave" / ...
var environment_config: Dictionary              # 环境参数 {"hazard_type": "lava", "hazard_damage": 5.0, ...}
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
    # 环境元素
    var hazards: Array[Dictionary] = [] # [{"type": "lava_tile", "position": Vector2i, "damage": 5.0}, ...]
    var destructibles: Array[Dictionary] = []  # [{"type": "barrel", "position": Vector2i, "drop": "coin"}, ...]
    var props: Array[Dictionary] = []   # [{"type": "forge_station", "position": Vector2i}, ...]

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

> **双因子驱动**：楼层编号决定基础难度，房间内战斗时间决定递增压力。`room_time_brackets` 仅在战斗房间内生效，安全营地/商店/事件房间不计时。

```json
{
    "room_time_brackets": [
        {
            "time_min": 0, "time_max": 30,
            "spawn_interval": 1.5,
            "hp_multiplier": 1.0,
            "speed_multiplier": 1.0,
            "max_enemies": 50,
            "elite_chance": 0.0
        },
        {
            "time_min": 30, "time_max": 60,
            "spawn_interval": 1.2,
            "hp_multiplier": 1.3,
            "speed_multiplier": 1.1,
            "max_enemies": 80,
            "elite_chance": 0.05
        },
        {
            "time_min": 60, "time_max": 120,
            "spawn_interval": 0.8,
            "hp_multiplier": 1.8,
            "speed_multiplier": 1.2,
            "max_enemies": 120,
            "elite_chance": 0.1
        },
        {
            "time_min": 120, "time_max": 9999,
            "spawn_interval": 0.5,
            "hp_multiplier": 2.5,
            "speed_multiplier": 1.3,
            "max_enemies": 200,
            "elite_chance": 0.15,
            "_comment": "房间战斗超过2分钟的惩罚性难度递增"
        }
    ],
    "floor_multipliers": {
        "1":  { "hp": 1.0,  "damage": 1.0 },
        "2":  { "hp": 1.5,  "damage": 1.2 },
        "3":  { "hp": 1.8,  "damage": 1.5 },
        "4":  { "hp": 2.5,  "damage": 2.0 },
        "5":  { "hp": 3.5,  "damage": 2.5 },
        "6":  { "hp": 5.0,  "damage": 3.0 },
        "7":  { "hp": 6.5,  "damage": 3.5 },
        "8":  { "hp": 8.0,  "damage": 4.0 },
        "9":  { "hp": 10.0, "damage": 5.0 },
        "10": { "hp": 13.0, "damage": 6.0 },
        "11": { "hp": 16.0, "damage": 7.5 },
        "12": { "hp": 20.0, "damage": 9.0 },
        "13": { "hp": 25.0, "damage": 11.0 },
        "14": { "hp": 15.0, "damage": 8.0, "_comment": "隐藏层S1 — 特殊难度" },
        "15": { "hp": 30.0, "damage": 13.0, "_comment": "隐藏层S2 — 最终挑战" }
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

### 3.5 商店物品池 (shop_items.json)

```json
{
    "base_items": [
        {
            "type": "weapon",
            "pool": ["wpn_magic_missile", "wpn_holy_aura", "wpn_flame_jet"],
            "base_price": 50,
            "price_formula": "base_price * (1 + floor_index * 0.2) * quality_mult"
        },
        {
            "type": "passive",
            "pool": ["pas_might", "pas_armor", "pas_speed"],
            "base_price": 40,
            "price_formula": "base_price * (1 + floor_index * 0.15) * quality_mult"
        },
        {
            "type": "consumable",
            "pool": ["item_heal_50", "item_heal_full", "item_reroll_token", "item_magnet"],
            "base_price": 30,
            "price_formula": "base_price * (1 + floor_index * 0.1)"
        }
    ],
    "quality_multipliers": {
        "normal": 1.0,
        "rare": 1.8,
        "legendary": 3.5
    },
    "quality_weights": {
        "base": { "normal": 70, "rare": 25, "legendary": 5 },
        "luck_bonus_per_point": { "normal": -1, "rare": 0.5, "legendary": 0.5 }
    },
    "slots_per_shop": 4,
    "restock_cost_multiplier": 2.0
}
```

### 3.6 环境配置 (environment_config.json)

```json
{
    "chapter_1": {
        "theme": "moss_dungeon",
        "tile_palette": "res://assets/tilesets/moss_dungeon.tres",
        "ambient_color": "#3a5a3a",
        "hazards": [
            {
                "type": "water_current",
                "push_force": 100.0,
                "damage": 0,
                "affects_enemies": true
            },
            {
                "type": "spore_cloud",
                "damage_per_second": 3.0,
                "slow_percent": 0.3,
                "radius": 64,
                "duration": 5.0,
                "affects_enemies": true
            }
        ]
    },
    "chapter_2": {
        "theme": "forge_hell",
        "tile_palette": "res://assets/tilesets/forge_hell.tres",
        "ambient_color": "#8a2a0a",
        "hazards": [
            {
                "type": "lava_tile",
                "damage_per_second": 8.0,
                "affects_enemies": false,
                "_comment": "火系敌人免疫"
            },
            {
                "type": "conveyor_belt",
                "push_force": 150.0,
                "direction": "configurable"
            }
        ]
    },
    "chapter_3": {
        "theme": "frost_abyss",
        "tile_palette": "res://assets/tilesets/frost_abyss.tres",
        "ambient_color": "#1a3a6a",
        "hazards": [
            {
                "type": "ice_surface",
                "friction_multiplier": 0.3,
                "affects_enemies": true
            },
            {
                "type": "frostbite_zone",
                "frostbite_rate": 2.0,
                "threshold_effects": {
                    "50": { "move_speed_penalty": -0.2 },
                    "80": { "attack_speed_penalty": -0.3 },
                    "100": { "damage_per_second": 10.0 }
                }
            }
        ]
    },
    "chapter_final": {
        "theme": "void_sanctum",
        "tile_palette": "res://assets/tilesets/void_sanctum.tres",
        "ambient_color": "#2a0a3a",
        "hazards": [
            {
                "type": "void_rift",
                "corruption_rate": 3.0,
                "teleport_chance": 0.1
            }
        ]
    }
}
```

### 3.7 Boss 阶段配置 (boss_phases.json)

```json
{
    "boss_rock_colossus": {
        "id": "enemy_rock_colossus",
        "chapter": 1,
        "phases": [
            { "hp_range": [1.0, 0.6], "attacks": ["ground_slam", "rock_throw"], "speed_mult": 1.0 },
            { "hp_range": [0.6, 0.3], "attacks": ["ground_slam", "rock_throw", "summon_rubble"], "speed_mult": 1.2 },
            { "hp_range": [0.3, 0.0], "attacks": ["ground_slam_enhanced", "rock_barrage", "summon_rubble"], "speed_mult": 1.5 }
        ]
    },
    "boss_flame_lord": {
        "id": "enemy_flame_lord",
        "chapter": 2,
        "phases": [
            { "hp_range": [1.0, 0.7], "attacks": ["fire_breath", "flame_pillar"], "speed_mult": 1.0 },
            { "hp_range": [0.7, 0.4], "attacks": ["fire_breath", "flame_pillar", "meteor_rain"], "speed_mult": 1.1 },
            { "hp_range": [0.4, 0.0], "attacks": ["inferno_breath", "flame_wall", "meteor_rain"], "speed_mult": 1.3 }
        ]
    },
    "boss_frost_king": {
        "id": "enemy_frost_king",
        "chapter": 3,
        "phases": [
            { "hp_range": [1.0, 0.7], "attacks": ["ice_lance", "frost_nova"], "speed_mult": 1.0 },
            { "hp_range": [0.7, 0.4], "attacks": ["ice_lance", "frost_nova", "blizzard"], "speed_mult": 1.1 },
            { "hp_range": [0.4, 0.0], "attacks": ["absolute_zero", "ice_prison", "blizzard"], "speed_mult": 1.2 }
        ]
    },
    "boss_void_lord": {
        "id": "enemy_void_lord",
        "chapter": "final",
        "phases": [
            { "hp_range": [1.0, 0.75], "attacks": ["void_beam", "shadow_orb"], "speed_mult": 1.0 },
            { "hp_range": [0.75, 0.5], "attacks": ["void_beam", "shadow_orb", "dimension_rift"], "speed_mult": 1.1 },
            { "hp_range": [0.5, 0.25], "attacks": ["void_storm", "dimension_rift", "corruption_wave"], "speed_mult": 1.3 },
            { "hp_range": [0.25, 0.0], "attacks": ["void_storm", "corruption_wave", "absolute_void"], "speed_mult": 1.5 }
        ]
    }
}
```

### 3.8 叙事数据索引 (narrative_index.json)

```json
{
    "narratives": [
        { "id": "narrative_ch1_opening", "chapter": 1, "trigger": "chapter_start", "resource": "res://resources/narrative/ch1_opening.tres" },
        { "id": "narrative_ch1_ending", "chapter": 1, "trigger": "chapter_end", "resource": "res://resources/narrative/ch1_ending.tres" },
        { "id": "narrative_ch2_opening", "chapter": 2, "trigger": "chapter_start", "resource": "res://resources/narrative/ch2_opening.tres" },
        { "id": "narrative_ch2_ending", "chapter": 2, "trigger": "chapter_end", "resource": "res://resources/narrative/ch2_ending.tres" },
        { "id": "narrative_ch3_opening", "chapter": 3, "trigger": "chapter_start", "resource": "res://resources/narrative/ch3_opening.tres" },
        { "id": "narrative_ch3_ending", "chapter": 3, "trigger": "chapter_end", "resource": "res://resources/narrative/ch3_ending.tres" },
        { "id": "narrative_final_opening", "chapter": 4, "trigger": "chapter_start", "resource": "res://resources/narrative/final_opening.tres" },
        { "id": "narrative_ending_redeem", "chapter": 4, "trigger": "ending", "condition": "alignment >= 50", "resource": "res://resources/narrative/ending_redeem.tres" },
        { "id": "narrative_ending_fall", "chapter": 4, "trigger": "ending", "condition": "alignment <= -50", "resource": "res://resources/narrative/ending_fall.tres" },
        { "id": "narrative_ending_balance", "chapter": 4, "trigger": "ending", "condition": "default", "resource": "res://resources/narrative/ending_balance.tres" }
    ],
    "memory_fragments": {
        "total": 33,
        "categories": ["world_history", "character_memory", "fall_truth", "redemption_path"]
    }
}
```

### 3.9 成就定义 (achievements.json)

```json
{
    "achievements": [
        { "id": "ach_first_clear", "name": "初次通关", "condition": "floors_cleared >= 13", "reward_type": "meta_currency", "reward_value": 500 },
        { "id": "ach_kill_1000", "name": "千刃之下", "condition": "total_kills >= 1000", "reward_type": "unlock_character", "reward_value": "char_reaper" },
        { "id": "ach_no_hit_boss", "name": "完美闪避", "condition": "boss_no_damage == true", "reward_type": "meta_currency", "reward_value": 200 },
        { "id": "ach_all_weapons", "name": "武器大师", "condition": "unlocked_weapons >= 12", "reward_type": "unlock_passive", "reward_value": "pas_weapon_master" },
        { "id": "ach_redemption", "name": "救赎之路", "condition": "ending_type == 'redeem'", "reward_type": "meta_currency", "reward_value": 300 },
        { "id": "ach_corruption", "name": "堕落深渊", "condition": "ending_type == 'fall'", "reward_type": "meta_currency", "reward_value": 300 },
        { "id": "ach_speed_run", "name": "疾风骤雨", "condition": "clear_time <= 1800", "reward_type": "unlock_character", "reward_value": "char_speedster" }
    ]
}
```

### 4.1 存档路径

```
user://save/
├── meta_save.dat          # Meta进度（加密）
├── meta_save.hash         # 校验哈希
├── meta_save.bak          # 上一次成功存档的备份
├── meta_save.bak.hash     # 备份校验哈希
└── settings.cfg           # 游戏设置（明文ConfigFile）
```

### 4.2 存档序列化（含备份与迁移）

```gdscript
const SAVE_VERSION: int = 1
const SAVE_PATH: String = "user://save/meta_save.dat"
const HASH_PATH: String = "user://save/meta_save.hash"
const BACKUP_PATH: String = "user://save/meta_save.bak"
const BACKUP_HASH_PATH: String = "user://save/meta_save.bak.hash"

# SaveManager 序列化流程
func save_meta() -> void:
    # 先备份当前存档（如果存在）
    if FileAccess.file_exists(SAVE_PATH):
        DirAccess.copy_absolute(
            ProjectSettings.globalize_path(SAVE_PATH),
            ProjectSettings.globalize_path(BACKUP_PATH))
        DirAccess.copy_absolute(
            ProjectSettings.globalize_path(HASH_PATH),
            ProjectSettings.globalize_path(BACKUP_HASH_PATH))
    
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
    
    var result = _try_load(SAVE_PATH, HASH_PATH)
    if result != null:
        return result
    
    # 主存档损坏，尝试加载备份
    push_warning("主存档校验失败，尝试加载备份...")
    if FileAccess.file_exists(BACKUP_PATH):
        result = _try_load(BACKUP_PATH, BACKUP_HASH_PATH)
        if result != null:
            push_warning("已从备份恢复存档")
            return result
    
    # 主存档和备份均损坏
    push_warning("存档和备份均不可用，创建新存档")
    return MetaData.new()

func _try_load(path: String, hash_path: String) -> MetaData:
    var file = FileAccess.open(path, FileAccess.READ)
    var encrypted = file.get_buffer(file.get_length())
    file.close()
    
    var json_str = _decrypt(encrypted)
    
    # 校验完整性
    var expected_hash = FileAccess.get_file_as_string(hash_path)
    if _compute_hash(json_str) != expected_hash:
        return null
    
    var data = JSON.parse_string(json_str)
    
    # 版本迁移
    if data["version"] < SAVE_VERSION:
        data = _migrate_save(data)
    
    return MetaData.deserialize(data["meta"])

func _migrate_save(data: Dictionary) -> Dictionary:
    var version = data["version"]
    # 逐版本递增迁移
    while version < SAVE_VERSION:
        match version:
            # 示例：版本 1 → 2 的迁移
            # 1: data["meta"]["new_field"] = default_value
            _:
                push_warning("未知存档版本: %d" % version)
        version += 1
    data["version"] = SAVE_VERSION
    return data
```

---

## 5. 信号接口汇总

> 所有游戏信号均通过 `EventBus`（Autoload 单例）中转，避免直接耦合。

| 信号 | 发射者 | 参数 | 监听者 |
|------|--------|------|--------|
| `enemy_killed` | HealthComponent | (enemy: Node2D, position: Vector2) | LootSystem, RunData, HUD |
| `damage_dealt` | DamageSystem | (target: Node2D, amount: float, type: int, is_crit: bool) | HUD(伤害数字), RunData |
| `player_leveled_up` | LevelSystem | (new_level: int) | GameManager(暂停), LevelUpPanel |
| `player_died` | HealthComponent | () | GameManager(结算) |
| `weapon_acquired` | WeaponSystem | (weapon_def: WeaponDef) | Player(挂载), HUD |
| `weapon_upgraded` | WeaponSystem | (weapon_id: String, new_level: int) | HUD, EvolutionCheck |
| `passive_acquired` | WeaponSystem | (passive_def: PassiveDef) | StatsComponent, HUD, RouteTracker |
| `accessory_acquired` | LootSystem | (accessory_def: AccessoryDef) | Player, HUD |
| `pickup_collected` | PickupArea | (type: String, value: int) | LevelSystem/RunData/HealthComponent |
| `gold_changed` | RunData | (new_amount: int) | HUD, ShopUI |
| `ore_changed` | RunData | (new_amount: int) | HUD, ForgeUI |
| `room_entered` | RoomTrigger | (room_data: RoomData) | EnemySpawner, Minimap, EventSystem, CombatTimer |
| `room_cleared` | Room | (room: RoomData) | FloorMap, Minimap, DoorController, CombatTimer |
| `floor_completed` | GameManager | (floor_index: int) | MapGenerator, RunData, PassiveSlotManager |
| `xp_gained` | PickupArea | (amount: int) | LevelSystem, HUD |
| `narrative_choice` | ChapterTransition | (chapter_id: String, segment_id: String, choice: Dictionary) | RunData, RouteTracker |
| `route_changed` | RouteTracker | (alignment: float, route: String) | HUD, NarrativeSystem |
| `frostbite_changed` | EnvironmentSystem | (value: float) | HUD, PlayerEffects |
| `void_corruption_changed` | EnvironmentSystem | (value: float) | HUD, PlayerEffects |
| `memory_fragment_found` | PickupArea | (fragment_id: String) | RunData, HUD, AchievementSystem |
