# 核心系统详细设计

## 1. 伤害系统 (DamageSystem)

### 1.1 伤害计算公式

```
最终伤害 = 武器伤害 × (1 + 伤害加成%) × 暴击倍率 × (1 - 有效护甲%)

其中:
- 武器伤害 = WeaponDef.damage_per_level[current_level]（绝对值，非倍率）
- 伤害加成% = 角色base_damage_bonus + 被动加成 + Buff加成
- 暴击倍率 = 暴击时为 crit_damage_mult，未暴击为 1.0
- 有效护甲% = min(目标护甲%, 75%)（护甲上限75%，防止无敌）
- 最终伤害 = max(最终伤害, 1.0)（保底1点伤害）
```

**圣光伤害特殊公式:**
```
圣光伤害 = 武器伤害 × (1 + 伤害加成%) × 暴击倍率 × (1 - 有效护甲% × (1 - 穿透率))

- 穿透率由武器/被动定义，基础30%，即无视目标30%的护甲
- 示例: holy_dmg=50, armor=50%, penetration=30%
  → 50 × (1 - 0.5 × (1 - 0.3)) = 50 × (1 - 0.35) = 50 × 0.65 = 32.5
```

### 1.2 伤害流程

```
WeaponProjectile 进入 EnemyHurtbox
        │
        ▼
DamageSystem.calculate_damage(source, target, weapon_damage, damage_type, bonus_pct, is_crit, crit_mult)
        │
        ├── 1. 获取攻击方属性 (StatsComponent)
        ├── 2. 计算暴击: rand() < crit_rate ? crit_damage_mult : 1.0
        ├── 3. 应用伤害加成 (被动加成 + Buff加成)
        ├── 4. 判断伤害类型:
        │   ├── HOLY → 应用穿透公式: armor × (1 - penetration)
        │   └── 其他 → 应用有效护甲: min(armor, 0.75)
        ├── 5. 保底伤害 max(final, 1.0)
        ├── 6. 应用最终伤害到 HealthComponent
        ├── 7. 触发状态效果 (基于 damage_type)
        │
        ▼
EventBus.damage_dealt.emit(target, final_damage, damage_type, is_crit)
        │
        ├── HUD 显示伤害数字（暴击金色加大）
        ├── 受击特效播放（按伤害类型着色）
        └── 击退计算 (knockback × source.knockback_mult)
```

**DamageSystem 函数签名:**

```gdscript
class_name DamageSystem

## 计算并应用伤害
## source: 攻击方节点（Player/Enemy）
## target: 受击方节点
## weapon_damage: 武器当前等级的绝对伤害值
## damage_type: DamageType 枚举
## bonus_pct: 额外伤害加成百分比（0.0 = 无加成）
## penetration: 护甲穿透率（仅 HOLY 类型使用，其他类型传 0.0）
## knockback_mult: 击退倍率（默认 1.0）
static func calculate_damage(
    source: Node,
    target: Node,
    weapon_damage: float,
    damage_type: DamageType,
    bonus_pct: float = 0.0,
    penetration: float = 0.0,
    knockback_mult: float = 1.0
) -> float:
    var stats = source.get_node("StatsComponent") as StatsComponent
    var is_crit = randf() < stats.get_stat("crit_rate")
    var crit_mult = stats.get_stat("crit_damage") if is_crit else 1.0
    var total_bonus = bonus_pct + stats.get_stat("damage_bonus")
    
    var damage = weapon_damage * (1.0 + total_bonus) * crit_mult
    
    # 护甲计算
    var target_armor = target.get_node("StatsComponent").get_stat("armor")
    if damage_type == DamageType.HOLY:
        damage *= (1.0 - target_armor * (1.0 - penetration))
    else:
        damage *= (1.0 - minf(target_armor, 0.75))
    
    damage = maxf(damage, 1.0)  # 保底伤害
    
    target.get_node("HealthComponent").take_damage(damage, damage_type)
    EventBus.damage_dealt.emit(target, damage, damage_type, is_crit)
    
    return damage
```

### 1.3 伤害类型

```gdscript
enum DamageType {
    PHYSICAL,    # 物理伤害
    FIRE,        # 火焰伤害（可附加燃烧DOT）
    ICE,         # 冰霜伤害（可附加减速）
    LIGHTNING,   # 闪电伤害（可附加连锁）
    HOLY,        # 神圣伤害（无视护甲百分比）
}
```

### 1.4 状态效果 (StatusEffect)

| 效果 | 触发条件 | 持续时间 | 效果描述 |
|------|----------|----------|----------|
| 燃烧 | 火焰伤害命中 | 3秒 | 每0.5秒造成基础伤害10%的火焰伤害 |
| 冰冻 | 冰霜伤害命中 | 2秒 | 移动速度降低50% |
| 感电 | 闪电伤害命中 | 瞬时 | 伤害弹射至3m内最近敌人(衰减30%) |
| 眩晕 | 精英技能/特定武器 | 1秒 | 完全停止移动和攻击 |
| 易伤 | 特定被动技能 | 5秒 | 受到伤害增加25% |

```gdscript
class_name StatusEffect extends Resource

@export var effect_type: String
@export var duration: float
@export var tick_interval: float      # DOT类效果的tick间隔
@export var value: float              # 效果数值（减速百分比/DOT伤害等）
@export var is_stackable: bool        # 是否可叠加
@export var max_stacks: int
```

### 1.5 状态效果叠加规则

```
同类效果叠加:
├── is_stackable = true  → 叠加层数（最多 max_stacks），每层独立计时
├── is_stackable = false → 刷新持续时间（取较长值）
└── 数值计算: 叠加层数 × 单层 value

不同类效果共存:
├── 所有不同类型效果可同时存在
├── 减速效果取最大值（不累加）: max(冰冻50%, 其他减速X%) 
├── 增伤效果累加: 易伤25% + 其他增伤X% = 总增伤
├── DOT效果独立计算: 燃烧 + 中毒 分别tick
└── 眩晕覆盖减速（眩晕期间减速无效）

特殊交互:
├── 燃烧 + 冰冻 → 互相抵消（移除双方）
├── 感电 + 水环境 → 伤害翻倍，范围扩大至5m
└── 易伤期间被暴击 → 额外15%伤害加成
```

---

## 2. 武器系统 (WeaponSystem)

### 2.1 武器基类设计

```gdscript
class_name BaseWeapon extends Node2D

# 武器定义（Resource数据）
var weapon_def: WeaponDef
var current_level: int = 1

# 运行时状态
var _cooldown_timer: float = 0.0
var _is_evolved: bool = false

func _process(delta: float) -> void:
    _cooldown_timer -= delta
    if _cooldown_timer <= 0.0:
        _attack()
        _cooldown_timer = _get_cooldown()

# 子类重写此方法实现不同攻击模式
func _attack() -> void:
    pass

# 获取当前等级的冷却时间（含CDR计算，CDR上限75%）
func _get_cooldown() -> float:
    var base_cd = weapon_def.get_cooldown(current_level)
    var cdr = _get_owner_stat("cooldown_reduction")
    cdr = minf(cdr, 0.75)  # CDR上限75%，最低冷却 = base × 0.25
    return base_cd * (1.0 - cdr)

# 通过节点树向上查找 Player 的 StatsComponent 获取属性值
func _get_owner_stat(stat_name: String) -> float:
    var player = get_parent().get_parent()  # WeaponMount → Player
    var stats = player.get_node("StatsComponent") as StatsComponent
    return stats.get_stat(stat_name) if stats else 0.0

func upgrade() -> void:
    current_level = mini(current_level + 1, weapon_def.max_level)
    _on_upgrade(current_level)

# 子类可重写，处理升级时的特殊逻辑
func _on_upgrade(new_level: int) -> void:
    pass
```

### 2.2 弹道类型实现

#### 追踪弹 (HomingProjectile)
```
初始化 → 寻找最近敌人 → 每帧调整方向朝目标 → 命中/超时销毁
参数: 转向速度, 最大存活时间, 搜索范围
```

#### 环绕 (OrbitWeapon)
```
围绕玩家以固定半径旋转 → 接触敌人造成伤害 → 升级增加数量/半径/伤害
参数: 旋转速度, 半径, 环绕体数量
```

#### 锥形AOE (ConeAOE)
```
朝玩家面朝方向释放锥形区域 → 区域内所有敌人受伤 → 持续一段时间
参数: 锥形角度, 射程, 持续时间
```

#### 链式 (ChainProjectile)
```
命中第一个目标 → 搜索范围内下一个目标 → 弹射(伤害衰减) → 达到最大弹射数停止
参数: 弹射次数, 搜索范围, 衰减系数
```

#### 圆形AOE (CircleAOE)
```
以玩家为中心释放圆形冲击波 → 范围内所有敌人受伤+效果 → 冷却
参数: 半径, 伤害, 附加效果
```

#### 直线弹幕 (LinearProjectile)
```
朝最近敌人方向发射 → 直线飞行 → 命中敌人/飞出屏幕销毁 → 可穿透
参数: 速度, 穿透数, 弹幕数量
```

### 2.3 武器进化系统

```gdscript
# 进化配方定义
class_name EvolutionRecipe extends Resource

@export var weapon_id: String          # 需要的武器ID
@export var passive_id: String         # 需要的被动技能ID
@export var weapon_min_level: int = 8  # 武器最低等级
@export var passive_min_level: int = 5 # 被动最低等级
@export var evolved_weapon_id: String  # 进化后的武器ID
```

进化触发流程：
```
武器升至满级 或 被动升至满级
        │
        ▼
WeaponSystem.check_evolution_available()
        │
        ├── 遍历所有进化配方
        ├── 检查武器+被动是否满足条件
        │
        ▼ (满足条件)
下次升级选项中出现进化选项（金色卡片）
        │
        ▼ (玩家选择)
移除原武器和被动 → 生成进化武器
```

---

## 3. 敌人生成系统 (EnemySpawner)

### 3.1 生成策略（房间内计时制）

敌人生成采用**楼层编号（基础强度）+ 房间战斗时间（压力递增）**双因子驱动。
仅在战斗房间内生成敌人，安全营地/商店/事件房间不生成。

```gdscript
class_name EnemySpawner extends Node

# 房间战斗状态
var _room_combat_time: float = 0.0   # 当前房间战斗时间（进入战斗房间重置）
var _spawn_timer: float = 0.0
var _wave_timer: float = 0.0
var _is_combat_active: bool = false   # 仅战斗房间为 true

# 楼层基础配置（从 enemy_scaling.json 加载）
var _floor_config: Dictionary         # floor_multipliers[floor_index]

func start_room_combat(floor_index: int) -> void:
    _room_combat_time = 0.0
    _is_combat_active = true
    _floor_config = ConfigManager.get_floor_scaling(floor_index)
    _spawn_timer = 0.0
    _wave_timer = ELITE_WAVE_INTERVAL

func stop_room_combat() -> void:
    _is_combat_active = false
    GameManager.run_data.room_combat_time += _room_combat_time

func _process(delta: float) -> void:
    if not _is_combat_active:
        return
    
    _room_combat_time += delta
    _spawn_timer -= delta
    _wave_timer -= delta
    
    if _spawn_timer <= 0.0:
        _spawn_normal_enemies()
        _spawn_timer = _get_spawn_interval()
    
    if _wave_timer <= 0.0:
        _spawn_elite_wave()
        _wave_timer = ELITE_WAVE_INTERVAL

# 生成间隔随房间内战斗时间缩短
func _get_spawn_interval() -> float:
    var time_pressure = _get_time_pressure()
    return base_interval / (1.0 + time_pressure * 0.5)

# 时间压力系数: 0s→0.0, 30s→0.5, 60s→1.5, 120s+→3.0
func _get_time_pressure() -> float:
    if _room_combat_time < 30.0: return _room_combat_time / 60.0
    elif _room_combat_time < 60.0: return 0.5 + (_room_combat_time - 30.0) / 30.0
    else: return 1.5 + minf((_room_combat_time - 60.0) / 40.0, 1.5)
```

### 3.2 难度缩放（双因子表）

**楼层基础倍率**（决定敌人基础属性）：

| 章节 | 楼层 | HP倍率 | 速度倍率 | 基础生成间隔 | 精英概率 |
|------|------|--------|---------|-------------|---------|
| 第一章 | F1 | 1.0x | 1.0x | 2.0s | 0% |
| | F2 | 1.3x | 1.05x | 1.8s | 3% |
| | F3 | 1.7x | 1.1x | 1.5s | 5% |
| | F4 | 2.5x | 1.15x | 1.3s | 8% |
| 第二章 | F5 | 3.0x | 1.2x | 1.2s | 10% |
| | F6 | 3.8x | 1.25x | 1.0s | 12% |
| | F7 | 5.0x | 1.3x | 0.8s | 15% |
| | F8 | 6.0x | 1.35x | 0.7s | 18% |
| 第三章 | F9 | 7.0x | 1.4x | 0.6s | 20% |
| | F10 | 8.5x | 1.4x | 0.5s | 22% |
| | F11 | 10.0x | 1.45x | 0.4s | 24% |
| | F12 | 12.0x | 1.5x | 0.3s | 26% |
| 最终章 | F13 | 15.0x | 1.5x | 0.25s | 30% |
| 隐藏层 | FS1 | 20.0x | 1.6x | 0.2s | 35% |
| | FS2 | 25.0x | 1.7x | 0.15s | 40% |

**房间内时间压力**（在楼层基础上叠加）：

| 房间战斗时间 | 生成间隔倍率 | HP追加倍率 | 同屏上限 | 说明 |
|-------------|-------------|-----------|---------|------|
| 0-30s | ×1.0 | ×1.0 | 50 | 初始压力，正常清怪 |
| 30-60s | ×0.8 | ×1.3 | 100 | 压力上升，催促进攻 |
| 60-120s | ×0.6 | ×1.8 | 200 | 高压，必须快速清场 |
| 120s+ | ×0.4 | ×2.5 | 350 | 极限压力，惩罚拖延 |

> 设计意图：玩家应在 60-90秒内清完一个房间。超过120秒意味着当前build不够强，需要回头提升。

### 3.3 Roguelike 房间内生成规则

```
进入战斗房间 → 关闭出口 → EnemySpawner.start_room_combat(floor_index)
    │
    ▼
根据房间类型和楼层确定敌人配置
    │
    ├── 普通房间: 3-5波普通敌人
    ├── 精英房间: 2波普通 + 1精英
    └── Boss房间: 1波普通 + Boss
    │
    ▼
每波间隔2-3秒，波内敌人从房间边缘/生成点出现
    │
    ▼
所有波次清除 → EnemySpawner.stop_room_combat()
    │
    ▼
掉落奖励 → 开启出口
```

> 注意: 安全营地、商店房间、事件房间不触发战斗，不启动 EnemySpawner。

### 3.4 敌人AI行为树

```
BaseEnemy AI:
├── [Selector]
│   ├── [Sequence] 死亡检查
│   │   ├── HP <= 0 ?
│   │   └── → 播放死亡动画 → 掉落物品 → 回收到对象池
│   ├── [Sequence] 特殊行为（精英/Boss重写）
│   │   ├── 有特殊技能可用?
│   │   └── → 执行特殊技能
│   └── [Sequence] 默认追踪
│       ├── 获取玩家位置
│       ├── 计算移动方向（含避障）
│       └── → 移动 + 接触伤害判定
```

Boss AI 扩展（阶段阈值由 boss_phases.json 独立配置）：
```
BossEnemy AI:
├── [Selector] 阶段切换（读取 EnemyDef.phase_thresholds）
│   ├── 岩石巨像: [0.60, 0.30]    → 3阶段
│   ├── 炎魔领主: [0.70, 0.40]    → 3阶段
│   ├── 寒霜君王: [0.70, 0.40]    → 3阶段
│   └── 虚空之主: [0.75, 0.50, 0.25] → 4阶段
│
Phase 行为:
├── [Sequence]
│   ├── 冷却完毕?
│   ├── 从当前阶段可用技能池加权随机选择
│   ├── 播放预警动画（给玩家反应时间: 0.5-1.5s 按技能类型）
│   └── 执行技能
```

---

## 4. 地图生成系统 (MapGenerator)

### 4.1 BSP 地图生成算法

```
步骤1: 初始化整个楼层为一个大矩形区域
步骤2: 递归BSP分割
    ├── 随机选择水平/垂直分割
    ├── 分割比例: 0.4 ~ 0.6（避免过窄）
    ├── 递归深度: 4-6层（控制房间数量）
    └── 叶节点 = 房间候选区域

步骤3: 在每个叶节点内生成房间
    ├── 房间大小: 候选区域的 60%-90%
    ├── 房间位置: 在候选区域内随机偏移
    └── 记录房间中心点

步骤4: 生成走廊连接相邻房间
    ├── 沿BSP树回溯，连接兄弟节点
    ├── 走廊宽度: 3-5 tiles
    └── L形走廊（先水平后垂直或反之）

步骤5: 分配房间类型
    ├── 选择一个边缘叶节点作为入口/起始房间
    ├── 从起始房间BFS计算各房间距离
    ├── 距离入口最远的房间 → Boss房间
    ├── 距离中位数的房间中随机1个 → 商店
    ├── 随机0-1个房间 → 宝藏
    ├── 距离较远的 1-2个房间 → 精英
    ├── 0-1个房间 → 随机事件（由事件概率表决定）
    └── 其余 → 普通战斗
```

### 4.2 TileMap 配置

```gdscript
enum TileType {
    FLOOR,          # 地板
    WALL,           # 墙壁
    WALL_TOP,       # 墙壁顶部（视觉层）
    DOOR,           # 门
    CORRIDOR,       # 走廊地板
    PIT,            # 陷阱/深坑
    DECORATION,     # 装饰物
}
```

### 4.3 楼层递进设计

> 完整关卡设计已扩展至 **3大章节×4层 + 最终章 + 2隐藏层 = 15个楼层**，详见 [level-design.md](./level-design.md)

**章节总览:**

| 章节 | 楼层范围 | 敌人倍率 | 主题 |
|------|---------|---------|------|
| 第一章: 遗忘深渊 | F1-F4 | 1.0x-2.5x | 废弃地牢→地下水道→蘑菇洞窟→矿脉深处 |
| 第二章: 灼热炼狱 | F5-F8 | 3.0x-6.0x | 熔岩前厅→锻造大厅→火山裂隙→炎魔祭坛 |
| 第三章: 永冻禁域 | F9-F12 | 7.0x-12.0x | 冰封遗迹→极光冰原→冰晶迷宫→寒霜王座 |
| 最终章: 虚空之心 | F13 | 15.0x | 虚空核心 |
| 隐藏层 | FS1-FS2 | 20.0x-25.0x | 时间裂缝 / 创世熔炉 |

---

## 5. 升级与选择系统 (LevelSystem)

### 5.1 经验曲线

```gdscript
func get_xp_for_level(level: int) -> int:
    return int(BASE_XP * pow(level, 1.3))

# BASE_XP = 10
# Level 1→2:  10 XP
# Level 5→6:  82 XP
# Level 10→11: 199 XP
# Level 20→21: 523 XP
# Level 30→31: 920 XP
```

### 5.2 升级选项生成算法

```
1. 构建候选池:
   ├── 未拥有的武器（权重: 100，武器栏未满时）
   ├── 已拥有未满级的武器升级（权重: 80）
   ├── 未拥有的被动技能（权重: 100，被动栏未满时）
   ├── 已拥有未满级的被动升级（权重: 80）
   └── 可进化的武器（权重: 200，金色选项）

2. 品质调整（受Luck影响）:
   ├── 普通选项基础权重 × 1.0
   ├── 稀有选项基础权重 × (0.3 + Luck × 0.05)
   └── 传说选项基础权重 × (0.05 + Luck × 0.02)

3. 加权随机抽取3个不重复选项

4. 保底机制:
   ├── 连续3次未出现新武器 → 强制包含1个新武器选项
   └── 进化可用时 → 必定出现在选项中
```

### 5.3 重新随机机制

```gdscript
var reroll_count: int = 0
var max_rerolls: int = 3          # 每局最大重随次数
var reroll_cost: int = 50         # 金币消耗（可被Meta升级降低）

func reroll() -> bool:
    if reroll_count >= max_rerolls:
        return false
    if GameManager.run_data.gold < reroll_cost:
        return false
    GameManager.run_data.gold -= reroll_cost
    reroll_count += 1
    _generate_new_options()
    return true
```

---

## 6. 掉落系统 (LootSystem)

### 6.1 掉落表

掉落表采用统一 JSON 格式定义（详见 data-structures.md Section 3.3），每个掉落表包含：
- `guaranteed`: 必定掉落的物品列表
- `random`: 加权随机物品池（按 weight 加权抽取）
- `max_random_drops`: 最大随机掉落数量

```json
// data/drop_tables.json 格式示例
{
    "normal": {
        "guaranteed": ["xp_gem_small"],
        "random": [
            { "item": "coin", "weight": 15, "min": 1, "max": 3 },
            { "item": "health_orb", "weight": 3, "min": 1, "max": 1 }
        ],
        "max_random_drops": 1
    },
    "elite": {
        "guaranteed": ["xp_gem_large"],
        "random": [
            { "item": "coin", "weight": 60, "min": 5, "max": 15 },
            { "item": "health_orb", "weight": 20, "min": 1, "max": 2 },
            { "item": "chest", "weight": 10, "min": 1, "max": 1 },
            { "item": "magnet", "weight": 8, "min": 1, "max": 1 },
            { "item": "ore", "weight": 15, "min": 1, "max": 2 }
        ],
        "max_random_drops": 2
    },
    "boss": {
        "guaranteed": ["xp_gem_huge", "chest_rare", "ore"],
        "random": [
            { "item": "coin", "weight": 100, "min": 20, "max": 50 },
            { "item": "health_orb", "weight": 40, "min": 2, "max": 3 },
            { "item": "ore", "weight": 60, "min": 2, "max": 4 },
            { "item": "accessory", "weight": 20, "min": 1, "max": 1 }
        ],
        "max_random_drops": 3
    }
}
```

> 注意: `EnemyDef.drop_table_id` 引用此文件中的 key（"normal"/"elite"/"boss"），不再使用 GDScript 内联定义。

### 6.2 经验宝石类型

| 类型 | 经验值 | 颜色 | 掉落来源 |
|------|--------|------|----------|
| 小型 | 1 | 蓝色 | 普通敌人 |
| 中型 | 5 | 绿色 | 快速/坦克敌人 |
| 大型 | 20 | 黄色 | 精英敌人 |
| 巨型 | 100 | 红色 | Boss |

### 6.3 拾取机制

```
物品生成 → 散落动画（随机方向短距离弹射）
    │
    ▼
等待0.3秒（防止瞬间拾取）
    │
    ▼
玩家 PickupArea 检测到物品
    │
    ▼
物品开始朝玩家加速移动（Tween, ease_in）
    │
    ▼
到达玩家 → 触发效果 → 回收到对象池
```

---

## 7. Meta 进度系统

### 7.1 Meta 货币获取

```gdscript
func calculate_meta_currency(run_data: RunData) -> int:
    var base = run_data.enemies_killed * 0.5
    var time_bonus = min(run_data.survive_time / 60.0, 20) * 5
    var floor_bonus = run_data.floors_cleared * 50
    var boss_bonus = run_data.bosses_killed * 100
    return int(base + time_bonus + floor_bonus + boss_bonus)
```

### 7.2 Meta 升级树

```
永久升级树:
├── 基础属性
│   ├── MaxHP +5/+10/+15/+20/+25 (5级)
│   ├── MoveSpeed +3%/+6%/+9%/+12%/+15% (5级)
│   ├── Armor +2%/+4%/+6%/+8%/+10% (5级)
│   ├── CritRate +2%/+4%/+6%/+8%/+10% (5级)
│   └── PickupRange +10%/+20%/+30%/+40%/+50% (5级)
├── 经济
│   ├── XPMultiplier +5%/+10%/+15%/+20% (4级)
│   ├── GoldMultiplier +10%/+20%/+30% (3级)
│   └── RerollDiscount -10/-20/-30 金币 (3级)
├── 解锁
│   ├── 角色解锁 (每个角色独立解锁条件)
│   ├── 武器解锁 (部分武器需Meta解锁)
│   └── 被动解锁 (部分被动需Meta解锁)
└── 特殊
    ├── 初始武器选择+1 (从2选1变为3选1)
    ├── 升级选项+1 (从3选变为4选)
    └── 复活1次 (每局限1次)
```

### 7.3 Meta 升级费用曲线

```gdscript
func get_upgrade_cost(upgrade_id: String, current_level: int) -> int:
    var base_cost = meta_upgrade_defs[upgrade_id].base_cost
    var growth = meta_upgrade_defs[upgrade_id].cost_growth
    return int(base_cost * pow(growth, current_level))

# 示例: base_cost=100, growth=1.8
# Lv0→1: 100
# Lv1→2: 180
# Lv2→3: 324
# Lv3→4: 583
# Lv4→5: 1050
```

---

## 8. 商店系统 (ShopSystem)

### 8.1 商店房间

进入商店房间时生成 3-4 个商品：

```gdscript
var shop_pool = {
    "weapon":      { "weight": 30, "price_range": [80, 150] },
    "passive":     { "weight": 30, "price_range": [60, 120] },
    "health_full": { "weight": 15, "price_range": [40, 60] },
    "health_half": { "weight": 20, "price_range": [20, 35] },
    "reroll_add":  { "weight": 5,  "price_range": [100, 150] },
}
```

### 8.2 商品品质与定价

品质由楼层和 Luck 属性共同决定：

```gdscript
# 品质权重计算
func _get_quality_weights(floor_index: int, luck: float) -> Dictionary:
    var floor_bonus = floor_index * 0.02    # 每层+2%稀有率
    var luck_bonus = luck * 0.05            # 每点Luck+5%稀有率
    return {
        "common":    maxf(0.7 - floor_bonus - luck_bonus, 0.2),  # 最低20%
        "uncommon":  0.2 + floor_bonus * 0.5 + luck_bonus * 0.3,
        "rare":      0.08 + floor_bonus * 0.3 + luck_bonus * 0.5,
        "legendary": 0.02 + floor_bonus * 0.2 + luck_bonus * 0.2,
    }

# 定价公式
# 最终价格 = base_price × quality_mult × floor_mult
# quality_mult: common=1.0, uncommon=1.5, rare=2.5, legendary=4.0
# floor_mult: 1.0 + (floor_index - 1) × 0.15
```

- 商品可预览完整属性后再购买
- 每层商店刷新一次，重新进入不刷新
- 详细 JSON 配置见 data-structures.md Section 3.5

---

## 9. 随机事件系统

### 9.1 事件类型

| 事件 | 效果 | 出现概率 |
|------|------|----------|
| 祝福祭坛 | 随机获得一个Buff（本局有效） | 20% |
| 诅咒祭坛 | 获得强力Buff但附带负面效果 | 15% |
| 神秘商人 | 以HP为代价交换稀有物品 | 10% |
| 赌博机 | 花费金币随机获得奖励或失去金币 | 15% |
| 治愈泉水 | 恢复50%最大HP | 15% |
| 锻造台 | 免费升级一个已有武器1级 | 10% |
| 遗忘之泉 | 移除一个武器/被动，返还升级选择次数 | 10% |
| 挑战房 | 限时击杀挑战，成功获得大量奖励 | 5% |

---

## 10. 耐力系统 (StaminaSystem)

### 10.1 耐力消耗与恢复

```gdscript
# 耐力参数（定义在 StatsComponent 中）
const STAMINA_MAX: float = 100.0          # 最大耐力
const STAMINA_DRAIN_RATE: float = 30.0    # 冲刺消耗速率（/秒）
const STAMINA_REGEN_RATE: float = 20.0    # 恢复速率（/秒）
const STAMINA_REGEN_DELAY: float = 0.5    # 停止冲刺后恢复延迟（秒）
const STAMINA_MIN_SPRINT: float = 20.0    # 低于此值无法开始冲刺
const SPRINT_SPEED_MULT: float = 1.6      # 冲刺速度倍率

var _current_stamina: float = STAMINA_MAX
var _regen_cooldown: float = 0.0

func _process(delta: float) -> void:
    if is_sprinting and _current_stamina > 0:
        _current_stamina -= STAMINA_DRAIN_RATE * delta
        _regen_cooldown = STAMINA_REGEN_DELAY
        if _current_stamina <= 0:
            _current_stamina = 0
            _force_stop_sprint()
    else:
        _regen_cooldown -= delta
        if _regen_cooldown <= 0:
            _current_stamina = minf(_current_stamina + STAMINA_REGEN_RATE * delta, STAMINA_MAX)
```

### 10.2 环境对耐力的影响

| 环境 | 耐力效果 |
|------|---------|
| 水流区域 | 消耗速率 ×1.5 |
| 冰面 | 消耗速率 ×0.5（惯性滑行替代冲刺） |
| 熔岩区域附近 | 恢复速率 ×0.7 |
| 虚空腐蚀区 | 消耗速率 ×2.0，恢复速率 ×0.5 |

---

## 11. 路线亲和度系统 (RouteSystem)

### 11.1 亲和度计算

玩家在一局中的选择会累积路线亲和度（alignment），范围 -100 ~ +100：

```gdscript
# RunData 中的 alignment 字段
# +100 = 完全救赎（Holy），-100 = 完全堕落（Void），0 = 平衡

# 影响亲和度的行为:
# - 选择 route_tag="holy" 被动: alignment += passive.alignment_value (正值)
# - 选择 route_tag="void" 被动: alignment += passive.alignment_value (负值)
# - 叙事分支选择: alignment += choice.alignment_change
# - 特定事件选择（祝福/诅咒祭坛）: alignment ± 5~15

func update_alignment(change: float) -> void:
    alignment = clampf(alignment + change, -100.0, 100.0)
    EventBus.route_changed.emit(alignment)
```

### 11.2 路线阈值与效果

| 亲和度范围 | 路线 | 效果 |
|-----------|------|------|
| +60 ~ +100 | 救赎之路 | 圣光伤害+20%，治疗效果+15%，可触发救赎结局 |
| +30 ~ +59 | 偏向光明 | 圣光伤害+10% |
| -29 ~ +29 | 平衡 | 所有属性小幅提升+5%，可触发平衡结局 |
| -59 ~ -30 | 偏向黑暗 | 虚空伤害+10% |
| -100 ~ -60 | 堕落之路 | 虚空伤害+20%，暴击率+10%，可触发堕落结局 |

### 11.3 结局触发条件

```
救赎结局: alignment >= +60 且 击败虚空之主
堕落结局: alignment <= -60 且 击败虚空之主
平衡结局: -30 <= alignment <= +30 且 击败虚空之主 且 收集 ≥ 20 记忆碎片
```

---

## 12. 锻造系统 (ForgeSystem)

### 12.1 锻造机制

锻造台位于安全营地和特定房间事件中，消耗矿石强化当前武器：

```gdscript
# ForgeRecipe 定义详见 data-structures.md Section 1.9
# 锻造操作
func forge_weapon(weapon: WeaponInstance, recipe: ForgeRecipe) -> bool:
    if GameManager.run_data.ore_count < recipe.ore_cost:
        return false
    if weapon.forge_count >= recipe.max_uses:
        return false
    
    GameManager.run_data.ore_count -= recipe.ore_cost
    weapon.apply_forge(recipe.effect_type, recipe.effect_value)
    weapon.forge_count += 1
    EventBus.ore_changed.emit(GameManager.run_data.ore_count)
    return true
```

### 12.2 锻造配方

| 配方 | 矿石消耗 | 效果 | 最大次数 |
|------|---------|------|---------|
| 强化锻造 | 3 | 伤害+10% | 3 |
| 元素附魔 | 5 | 附加对应章节元素效果 | 1 |
| 极限突破 | 8 | 等级上限+2 | 1 |

> 锻造效果为当局有效，不保留至下局。矿石来源: 精英/Boss掉落、特定房间事件、可破坏环境物。
