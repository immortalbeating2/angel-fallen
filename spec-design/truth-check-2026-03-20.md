# 文档承诺真值核对报告（2026-03-20）

## 核对范围

- 核对文档：`requirements.md`、`architecture.md`、`core-systems.md`、`data-structures.md`、`level-design.md`、`test-plan.md`、`roadmap.md`、`supplement-updates.md`
- 证据来源：`scripts/`、`scenes/`、`data/balance/`、`resources/`、`test/unit/`
- 核对口径：按**全量文档承诺**评估，不仅限 MVP

## 总体结论

- 核心玩法主干已成型：战斗、刷怪压力、Run-Plan、房间推进、叙事权重、结算与存档链路均可在代码中确认。
- 主要缺口集中在内容规模与资产结构：角色/进化/商店池深度偏小，资源目录与场景体量未达到文档全量形态。
- 当前仓库状态更接近“可玩 MVP + 扩展基础设施”，与文档中的完整版目标存在阶段性差距。

## 真值矩阵

| 文档主张 | 状态 | 证据 | 结论说明 |
|---|---|---|---|
| 四层架构（Game/System/Manager/Data） | 已确认 | `scripts/autoload/*.gd`, `scripts/systems/*.gd`, `scripts/game/*.gd` | 架构职责分层清晰，Autoload 与系统层联动完整。 |
| EventBus 类型化信号总线 | 已确认 | `scripts/autoload/event_bus.gd` | 运行状态、战斗、房间、路线、UI、设置等信号均有实现。 |
| 配置中心统一加载 balance JSON | 已确认 | `scripts/autoload/config_manager.gd`, `data/balance/*.json` | `CONFIG_PATHS` 全量加载关键配置。 |
| 核心战斗与敌人压力模型 | 已确认 | `scripts/systems/damage_system.gd`, `scripts/systems/enemy_spawner.gd`, `scripts/game/enemy.gd` | 包含护甲上限、圣光穿透、房间时间+楼层缩放、精英与 Boss 逻辑。 |
| Run-Plan 地图生成与分支 | 已确认 | `scripts/systems/map_generator.gd`, `scripts/game/game_world.gd` | 房间类型、章节归属、节点连接、路线推进均可追踪。 |
| 叙事权重、路线风格、结局门槛 | 已确认 | `scripts/systems/narrative_system.gd`, `data/balance/narrative_content.json` | 包含 alignment、route style、recent 抑制、ending gate。 |
| HUD / 暂停 / 运行时设置 / 结算面板 | 已确认 | `scripts/ui/hud.gd`, `scripts/ui/pause_panel.gd`, `scripts/ui/runtime_settings_panel.gd`, `scripts/ui/run_result_panel.gd` | 信息反馈与设置持久化链路完整。 |
| 进化系统深度 | 部分实现 | `scripts/systems/level_up_system.gd`, `scripts/game/auto_weapon.gd`, `data/balance/evolutions.json` | 机制就绪，但内容规模不足，需扩容 recipe。 |
| 叙事记忆碎片体系 | 部分实现 | `data/balance/narrative_index.json`, `data/balance/narrative_content.json` | 索引与系统已接通，实际碎片内容量偏少。 |
| 角色/武器/被动/商店内容深度 | 部分实现 | `data/balance/characters.json`, `data/balance/shop_items.json` | 系统可用，内容池偏紧凑。 |
| 大规模资源目录（以 `.tres` 为主） | 尚未体现（全量口径） | `resources/` | 当前除 narrative 外，未形成文档所述全量资源目录族。 |
| 主玩法场景 TileMap 化呈现 | 尚未体现（全量口径） | `scenes/game/game_world.tscn` | 当前主场景以 ColorRect/Polygon2D 为主，TileMap 驱动不足。 |
| 测试计划中的集成/性能/兼容矩阵 | 尚未体现（全量口径） | `test/unit/*.gd`, `spec-design/test-plan.md` | 现有测试偏配置契约与局部行为，缺少大规模集成/E2E/性能套件。 |

## 风险分级

- 高：文档全量承诺与仓库现状差距若不显式标注，会持续放大协作预期偏差。
- 中：内容深度不足会影响长线可玩性与构筑差异化体验。
- 中：测试覆盖结构偏“静态配置校验”，对跨系统回归保护有限。
- 低：当前系统主干稳定，具备持续增量扩展基础。

## 建议推进顺序

1. 文档对齐（先消除预期偏差）
2. 内容扩容（角色/进化/商店池）
3. 表现升级（TileMap 与场景视觉管线）
4. 测试补强（集成回归 + 性能基线）
