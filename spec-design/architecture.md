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
│  └────────┘ └────────┘ └────────┘ └──────┘  │
├─────────────────────────────────────────────┤
│              Manager Layer (Autoload)        │
│  ┌────────┐ ┌────────┐ ┌────────┐ ┌──────┐  │
│  │Game    │ │Event   │ │Save    │ │Audio │  │
│  │Manager │ │Bus     │ │Manager │ │Mgr   │  │
│  └────────┘ └────────┘ └────────┘ └──────┘  │
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
│   │   │       └── base_boss.gd
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
│   │   │   └── magnet.tscn
│   │   └── map/
│   │       ├── room.tscn
│   │       ├── corridor.tscn
│   │       ├── tilemap/
│   │       └── props/
│   ├── ui/
│   │   ├── hud/
│   │   │   ├── hud.tscn
│   │   │   ├── health_bar.tscn
│   │   │   ├── xp_bar.tscn
│   │   │   ├── weapon_slots.tscn
│   │   │   ├── minimap.tscn
│   │   │   └── timer_display.tscn
│   │   ├── level_up/
│   │   │   ├── level_up_panel.tscn
│   │   │   └── upgrade_card.tscn
│   │   ├── pause_menu.tscn
│   │   └── result_screen.tscn
│   └── effects/
│       ├── hit_effect.tscn
│       ├── death_effect.tscn
│       └── level_up_effect.tscn
├── scripts/
│   ├── autoload/
│   │   ├── game_manager.gd           # 游戏状态管理
│   │   ├── event_bus.gd              # 全局信号总线
│   │   ├── save_manager.gd           # 存档管理
│   │   ├── audio_manager.gd          # 音频管理
│   │   └── config_manager.gd         # 配置表加载
│   ├── systems/
│   │   ├── weapon_system.gd          # 武器管理逻辑
│   │   ├── enemy_spawner.gd          # 敌人生成器
│   │   ├── level_system.gd           # 升级系统
│   │   ├── loot_system.gd            # 掉落系统
│   │   ├── damage_system.gd          # 伤害计算
│   │   └── map_generator.gd          # 地图生成
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
│   └── meta_upgrades/                # Meta升级定义 Resource
├── data/
│   ├── balance/                      # 数值平衡配置表 (JSON)
│   │   ├── xp_curve.json
│   │   ├── enemy_scaling.json
│   │   └── drop_tables.json
│   └── i18n/                         # 本地化文件
│       ├── zh_CN.csv
│       └── en.csv
├── assets/
│   ├── sprites/
│   ├── audio/
│   ├── fonts/
│   └── shaders/
└── addons/                           # 第三方插件
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
全局信号总线，解耦模块间通信。

```gdscript
# 核心信号：
signal enemy_killed(enemy: BaseEnemy, position: Vector2)
signal xp_gained(amount: int)
signal player_leveled_up(new_level: int)
signal weapon_acquired(weapon_def: WeaponDef)
signal weapon_upgraded(weapon_id: String, new_level: int)
signal passive_acquired(passive_def: PassiveDef)
signal room_cleared(room: Room)
signal floor_completed(floor_index: int)
signal player_died()
signal damage_dealt(target: Node2D, amount: float, is_crit: bool)
signal pickup_collected(pickup_type: String, value: float)
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
# - 加载 JSON 配置表（经验曲线、敌人缩放、掉落表等）
# - 提供类型安全的配置访问接口
# - 支持热重载（开发模式）
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
