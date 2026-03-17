# 核心系统详细设计

## 1. 伤害系统 (DamageSystem)

### 1.1 伤害计算公式

```
最终伤害 = 基础伤害 × 武器倍率 × (1 + 伤害加成%) × 暴击倍率 × (1 - 目标护甲%)
```

### 1.2 伤害流程

```
WeaponProjectile 进入 EnemyHurtbox
        │
        ▼
DamageSystem.calculate_damage(source, target, base_damage)
        │
        ├── 1. 获取攻击方属性 (StatsComponent)
        ├── 2. 计算暴击: rand() < crit_rate ? crit_damage_mult : 1.0
        ├── 3. 应用伤害加成 (武器等级加成 + 被动加成)
        ├── 4. 应用目标减伤 (护甲)
        ├── 5. 应用最终伤害到 HealthComponent
        │
        ▼
EventBus.damage_dealt.emit(target, final_damage, is_crit)
        │
        ├── HUD 显示伤害数字
        ├── 受击特效播放
        └── 击退计算 (knockback)
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

# 获取当前等级的冷却时间（含CDR计算）
func _get_cooldown() -> float:
    var base_cd = weapon_def.get_cooldown(current_level)
    var cdr = _get_owner_stat("cooldown_reduction")
    return base_cd * (1.0 - cdr)

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

### 3.1 生成策略

```gdscript
class_name EnemySpawner extends Node

# 生成配置
var _spawn_timer: float = 0.0
var _wave_timer: float = 0.0
var _difficulty_curve: Curve     # 难度曲线（时间→难度系数）

func _process(delta: float) -> void:
    _spawn_timer -= delta
    _wave_timer -= delta
    
    if _spawn_timer <= 0.0:
        _spawn_normal_enemies()
        _spawn_timer = _get_spawn_interval()
    
    if _wave_timer <= 0.0:
        _spawn_elite_wave()
        _wave_timer = ELITE_WAVE_INTERVAL
```

### 3.2 难度缩放

| 游戏时间 | 生成间隔 | 敌人HP倍率 | 敌人速度倍率 | 同屏上限 | 精英概率 |
|----------|----------|-----------|-------------|---------|---------|
| 0-2min | 1.5s | 1.0x | 1.0x | 50 | 0% |
| 2-5min | 1.2s | 1.5x | 1.1x | 100 | 5% |
| 5-10min | 0.8s | 2.5x | 1.2x | 200 | 10% |
| 10-15min | 0.5s | 4.0x | 1.3x | 350 | 15% |
| 15-20min | 0.3s | 7.0x | 1.4x | 500 | 20% |
| 20min+ | 0.2s | 10.0x+ | 1.5x | 500 | 25% |

### 3.3 Roguelike 房间内生成规则

```
进入房间 → 关闭出口
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
所有波次清除 → 掉落奖励 → 开启出口
```

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

Boss AI 扩展：
```
BossEnemy AI:
├── [Selector] 阶段切换
│   ├── HP > 66% → Phase1 行为
│   ├── HP > 33% → Phase2 行为（增加技能）
│   └── HP <= 33% → Phase3 行为（狂暴）
│
Phase 行为:
├── [Sequence]
│   ├── 冷却完毕?
│   ├── 随机选择当前阶段可用技能
│   ├── 播放预警动画（给玩家反应时间）
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
    ├── 距离入口最远的房间 → Boss房间
    ├── 随机1个房间 → 商店
    ├── 随机0-1个房间 → 宝藏
    ├── 1-2个房间 → 精英
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

```gdscript
# 普通敌人掉落
var normal_drop_table = {
    "xp_gem_small": { "weight": 100, "min": 1, "max": 1 },
    "coin":         { "weight": 15,  "min": 1, "max": 3 },
    "health_orb":   { "weight": 3,   "min": 1, "max": 1 },
}

# 精英敌人掉落
var elite_drop_table = {
    "xp_gem_large": { "weight": 100, "min": 1, "max": 1 },
    "coin":         { "weight": 60,  "min": 5, "max": 15 },
    "health_orb":   { "weight": 20,  "min": 1, "max": 2 },
    "chest":        { "weight": 10,  "min": 1, "max": 1 },
    "magnet":       { "weight": 8,   "min": 1, "max": 1 },
}

# Boss掉落
var boss_drop_table = {
    "xp_gem_huge":  { "weight": 100, "min": 1, "max": 1 },
    "coin":         { "weight": 100, "min": 20, "max": 50 },
    "chest_rare":   { "weight": 50,  "min": 1, "max": 1 },
    "health_orb":   { "weight": 40,  "min": 2, "max": 3 },
}
```

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

- 品质受当前楼层和玩家Luck影响
- 价格 = 基础价格 × 品质倍率 × 楼层倍率
- 商品可预览完整属性后再购买

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
