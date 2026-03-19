# AGENTS.md — 堕落天使 (Angel Fallen) 开发指南

## 项目概述

堕落天使是一款俯视角2D动作Roguelike游戏，融合了Vampire Survivors自动战斗与传统Roguelike地牢探索。

| 属性 | 值 |
|------|-----|
| 引擎 | Godot 4.x (GDScript) |
| 视角 | 俯视角 2D |
| 目标平台 | PC (Windows / Linux / macOS) |
| 测试框架 | GUT (Godot Unit Test) |
| CI | GitHub Actions (Godot headless) |
| 数据格式 | Godot Resource (.tres) + JSON配置表 + CSV (i18n) |

---

## 构建与运行命令

```bash
# 编辑器启动
godot --editor

# 运行游戏
godot --path . scenes/main_menu/main_menu.tscn

# 无头模式运行（CI用）
godot --headless --quit

# 运行全部测试
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test -ginclude_subdirs -gexit

# 运行指定测试目录
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/unit -ginclude_subdirs -gexit

# JSON配置验证
python scripts/validate_configs.py

# Resource完整性检查
python scripts/check_resources.py

# 导出构建
godot --headless --export-release "Windows Desktop" builds/angel_fallen.exe
godot --headless --export-release "Linux/X11" builds/angel_fallen.x86_64
godot --headless --export-release "macOS" builds/angel_fallen.dmg
```

---

## 项目结构

```
angel-fallen/
├── scenes/
│   ├── main_menu/          # 主菜单、角色选择、Meta升级、设置
│   ├── game/               # 游戏世界、房间模板、走廊
│   ├── safe_camp/          # 安全营地（NPC/商店/锻造/记忆祭坛）
│   ├── narrative/          # 章节转场、对话框、结局画面
│   ├── ui/                 # HUD、升级面板、商店、锻造、暂停、结算
│   └── effects/            # 视觉特效、Boss场景、环境效果
├── scripts/
│   ├── autoload/           # GameManager, EventBus, SaveManager,
│   │                       # ConfigManager, SceneManager, AudioManager
│   ├── systems/            # DamageSystem, EnemySpawner, MapGenerator,
│   │                       # LevelUpSystem, LootSystem, MetaSystem,
│   │                       # ShopSystem, RouteSystem, NarrativeSystem,
│   │                       # ForgeSystem, StaminaSystem
│   ├── components/         # HealthComponent, StatsComponent,
│   │                       # MovementComponent, HitboxComponent,
│   │                       # HurtboxComponent
│   └── utils/              # object_pool.gd, weighted_random.gd
├── resources/              # .tres Resource定义
│   ├── characters/         # CharacterDef
│   ├── weapons/            # WeaponDef
│   ├── passives/           # PassiveDef (含route_tag)
│   ├── enemies/            # EnemyDef + EnemySkillDef
│   ├── accessories/        # AccessoryDef
│   ├── narrative/          # NarrativeResource + NarrativeSegment
│   ├── forge_recipes/      # ForgeRecipe
│   ├── evolutions/         # EvolutionDef
│   └── meta_upgrades/      # MetaUpgradeDef
├── data/
│   ├── balance/            # xp_curve.json, enemy_scaling.json,
│   │                       # drop_tables.json, evolutions.json,
│   │                       # shop_items.json, environment_config.json,
│   │                       # boss_phases.json, narrative_index.json,
│   │                       # achievements.json
│   └── i18n/               # strings.csv (中/英)
├── assets/
│   ├── sprites/            # 角色/敌人/武器/环境/UI精灵
│   ├── audio/bgm/          # 背景音乐
│   ├── audio/sfx/          # 音效
│   ├── audio/ambience/     # 环境音
│   ├── fonts/              # 中英文字体
│   └── shaders/            # 着色器
├── addons/gut/             # 测试框架
└── test/                   # 单元测试/集成测试
    ├── unit/
    └── integration/
```

---

## 架构设计

四层架构，从上到下依赖：

```
Game Layer     → 场景/节点（Player, Enemy, Room, UI）
System Layer   → 系统脚本（DamageSystem, EnemySpawner, MapGenerator...）
Manager Layer  → Autoload单例（GameManager, EventBus, SaveManager...）
Data Layer     → Resource (.tres) + JSON配置表
```

**核心模式：**
- **组件模式** — HealthComponent / StatsComponent / MovementComponent 挂载到节点
- **EventBus** — 全局信号总线，解耦模块间通信（20个类型化信号）
- **对象池** — 弹幕/敌人/拾取物复用，避免频繁实例化
- **数据驱动** — 所有数值存于 Resource + JSON，支持热重载

---

## 命名规范

### GDScript

| 类别 | 风格 | 示例 |
|------|------|------|
| 类名 | PascalCase | `BaseWeapon`, `DamageSystem`, `CharacterDef` |
| 变量 | snake_case | `current_level`, `weapon_def` |
| 私有变量 | _前缀snake_case | `_cooldown_timer`, `_is_evolved` |
| 常量 | UPPER_SNAKE_CASE | `ELITE_WAVE_INTERVAL`, `SAVE_VERSION` |
| 枚举名 | PascalCase | `DamageType`, `GameState` |
| 枚举值 | UPPER_SNAKE_CASE | `DamageType.PHYSICAL`, `GameState.PLAYING` |
| 函数 | snake_case | `calculate_damage()`, `get_cooldown()` |
| 私有函数 | _前缀snake_case | `_attack()`, `_on_upgrade()` |
| 信号 | snake_case | `enemy_killed`, `damage_dealt` |
| Resource ID | 类型前缀_snake | `char_knight`, `wpn_magic_missile`, `pas_might` |

### 资源ID前缀

| 前缀 | 类型 | 示例 |
|------|------|------|
| `char_` | 角色 | `char_knight`, `char_mage` |
| `wpn_` | 武器 | `wpn_magic_missile`, `wpn_holy_cross` |
| `pas_` | 被动 | `pas_might`, `pas_armor` |
| `enemy_` | 敌人 | `enemy_slime`, `enemy_skeleton` |
| `meta_` | Meta升级 | `meta_max_hp`, `meta_cdr` |
| `acc_` | 饰品 | `acc_heart_of_mine`, `acc_flame` |
| `nar_` | 叙事 | `nar_ch1_start`, `nar_ending_redeem` |

### 测试命名

- 测试脚本：`extends GutTest`（如 `test_damage_system.gd`）
- 测试方法：`test_xxx()`（如 `test_basic_damage()`, `test_armor_cap()`）

---

## 代码风格

### 类型标注 — 全量静态类型

```gdscript
# 变量
var current_state: GameState = GameState.MENU
@export var base_hp: float = 100.0

# 函数参数与返回值
func calculate_damage(source: Node2D, target: Node2D, weapon_damage: float) -> float:

# 数组
var weapons: Array[WeaponInstance] = []
var multipliers: Array[float] = [1.0, 1.2, 1.5]
```

### 注释 — 中文

```gdscript
# 获取当前等级的冷却时间（含CDR计算，上限75%）
func _get_cooldown() -> float:
    var base_cd: float = weapon_def.cooldown_per_level[current_level]
    var cdr: float = _get_owner_stat("cooldown_reduction")
    cdr = minf(cdr, 0.75)  # CDR上限75%
    return base_cd * (1.0 - cdr)
```

### 错误处理

```gdscript
# push_warning() 用于非致命错误
push_warning("存档完整性校验失败!")

# 优雅降级，回退到默认值
if not data:
    return MetaData.new()

# clampi() 安全边界访问
var index: int = clampi(level - 1, 0, max_level - 1)

# Guard clause 提前返回
if reroll_count >= max_rerolls:
    return false
```

### 关键公式

```
# 物理伤害
最终伤害 = max(武器伤害 × (1 + 伤害加成%) × 暴击倍率 × (1 - min(护甲%, 75%)), 1.0)

# 圣光伤害（穿透护甲）
最终伤害 = max(武器伤害 × (1 + 伤害加成%) × 暴击倍率 × (1 - 护甲% × (1 - 穿透%)), 1.0)

# CDR上限 = 75%（最低冷却 = 基础 × 0.25）
# 护甲上限 = 75%（最低减伤乘数 = 0.25）
```

---

## AI素材生成工作流

### 美术管线

```
Stable Diffusion (txt2img/img2img)
    → 高分辨率概念图
    → Aseprite 像素化（降分辨率 + 调色板限制）
    → 精灵表切割（idle/run/attack/hurt/death）
    → Godot SpriteFrames 导入
```

**像素规格（建议）：**
- 瓦片尺寸: 16×16 或 32×32
- 角色尺寸: 32×32 ~ 48×48
- Boss尺寸: 64×64 ~ 128×128
- 调色板: 每章独立色板，参考 environment_config.json 的 tile_palette

**Stable Diffusion 提示词模板：**
```
正向: pixel art, top-down rpg sprite, [描述], 16-color palette, dark fantasy,
      transparent background, game asset, clean lines
负向: blurry, 3d, realistic, watermark, text, low quality
```

**一致性策略：**
- 固定 seed + LoRA 保持角色风格统一
- 统一后处理: Aseprite 降色 + 描边 + 像素对齐
- 按章节使用对应色板

### 音频策略

| 类型 | 来源 | 格式 | 数量 |
|------|------|------|------|
| BGM | AI生成 (Suno/Udio) 或采购 | OGG Vorbis, 循环 | 4-6首 |
| SFX | sfxr/Freesound + 后处理 | WAV, 16bit/44.1kHz | 30+ |
| 环境音 | Freesound + 混音 | OGG Vorbis, 循环 | 每章1-2条 |

**AudioManager 总线：**
- Master → BGM (crossfade 0.5s)
- Master → SFX (池化, 最大16并发)
- Master → Ambience

---

## 素材文件命名

```
# 精灵
sprites/characters/char_knight_idle.png
sprites/characters/char_knight_run.png
sprites/enemies/enemy_slime_idle.png
sprites/environment/ch1_floor_01.png
sprites/ui/btn_primary.png

# 音频
audio/bgm/bgm_ch1_dungeon.ogg
audio/sfx/sfx_weapon_fire.wav
audio/sfx/sfx_enemy_death.wav
audio/ambience/amb_ch1_cave.ogg
```

---

## 版本控制规范

### Git LFS

以下文件类型必须通过 Git LFS 管理：
```
*.png, *.jpg, *.bmp        # 图片
*.wav, *.ogg, *.mp3         # 音频
*.tres, *.tscn              # Godot资源/场景（二进制格式时）
*.ttf, *.otf                # 字体
*.import                    # Godot导入缓存
```

### 分支策略

```
master          ← 稳定发布版本
  └── develop   ← 开发主分支
        ├── feature/xxx   ← 功能分支
        ├── fix/xxx       ← 修复分支
        └── art/xxx       ← 素材分支
```

### 提交消息格式

```
<类型>: <简述>

类型: feat / fix / refactor / art / audio / data / test / docs / chore
示例:
  feat: 实现双因子敌人生成器
  fix: 修复CDR超过75%导致零冷却
  art: 添加第一章瓦片集精灵
  data: 更新enemy_scaling.json至15层
  test: 补充叙事系统NAR-01~NAR-09测试
```

---

## CI/CD 配置

```yaml
# .github/workflows/test.yml
name: Game Tests
on: [push, pull_request]

jobs:
  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          lfs: true
      - uses: chickensoft-games/setup-godot@v2
        with:
          version: 4.3.0
      - name: Run GUT Tests
        run: godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test -ginclude_subdirs -gexit

  data-validation:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      - name: Validate JSON configs
        run: python scripts/validate_configs.py
      - name: Check Resource integrity
        run: python scripts/check_resources.py
```

**数据验证清单：**
- 9个JSON配置文件 schema 校验
- enemy_scaling 覆盖15层
- boss_phases HP区间连续 (上阶段结束 = 下阶段开始)
- drop_tables 权重合法 (>0)
- evolution_recipes 引用存在
- narrative_index 所有 resource_path 有效

---

## MVP 缩减方案

MVP版本（v1.0）只包含：

| 维度 | MVP范围 | 完整版范围 |
|------|---------|-----------|
| 楼层 | 2章 (F1-F6) | 4章 (F1-F13) + 2隐藏 |
| Boss | 2个 (岩石巨像/炎魔领主) | 4+2个 |
| 武器 | 4种弹道 | 6种弹道 |
| 角色 | 3个 | 10个 |
| 被动槽位 | 6→8 | 6→12 |
| 叙事 | 2章转场 + 基础选择 | 全章节 + 3结局 + 33碎片 |
| 环境 | 2章危害 (水流/孢子/熔岩/传送带) | 全部14+机制 |
| 事件 | 4种 | 8种 |
| 饰品 | 2个 | 4+个 |

**砍刀优先级（如果时间不足）：**
1. 砍 DDA辅助系统 → 不影响核心
2. 砍 成就/图鉴 → 延后到v1.3
3. 砍 环境危害 → 简化为纯装饰
4. 砍 锻造系统 → 商店代替
5. 砍 叙事分支 → 线性叙事
6. **不砍** 核心战斗循环 / Roguelike地图 / Meta进度

---

## 设计文档索引

| 文档 | 内容 |
|------|------|
| [requirements.md](spec-design/requirements.md) | 功能需求 + 非功能需求 |
| [architecture.md](spec-design/architecture.md) | 系统架构 + 目录结构 + Autoload + 组件 |
| [core-systems.md](spec-design/core-systems.md) | 伤害/武器/敌人/地图/升级/掉落/Meta/商店/耐力/路线/锻造 |
| [data-structures.md](spec-design/data-structures.md) | Resource定义 + 运行时数据 + JSON配置 + 存档 + 信号表 |
| [level-design.md](spec-design/level-design.md) | 世界观/15层设计/Boss/房间/环境/叙事/难度曲线 |
| [test-plan.md](spec-design/test-plan.md) | 105+测试用例 + 性能基准 + 平衡模拟 + CI流水线 |
| [roadmap.md](spec-design/roadmap.md) | MVP 22周路线 + 后续v1.1/v1.2/v1.3 |
| [supplement-updates.md](spec-design/supplement-updates.md) | 计划外实现增量与同步说明（含历史补录） |
