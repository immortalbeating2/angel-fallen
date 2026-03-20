# 文档承诺真值核对报告（2026-03-20）

## 核对范围

- 核对文档：`requirements.md`、`architecture.md`、`core-systems.md`、`data-structures.md`、`level-design.md`、`test-plan.md`、`roadmap.md`、`supplement-updates.md`
- 证据来源：`scripts/`、`scenes/`、`data/balance/`、`resources/`、`test/unit/`、`test/integration/`
- 核对口径：按**全量文档承诺**评估，不仅限 MVP

## 总体结论

- 核心玩法主干已成型：战斗、刷怪压力、Run-Plan、房间推进、叙事权重、结算与存档链路均可在代码中确认。
- 主要缺口集中在内容规模与资产结构：角色/进化/商店池深度偏小，资源目录与场景体量尚未达到文档全量形态。
- 集成回归能力已起步：关键流程（开局推进结算、进化、商店闭环）已有场景级测试护栏。
- 当前仓库状态更接近“可玩 MVP + 扩展基础设施”，与文档中的完整版目标存在阶段性差距。

## 真值矩阵

| 文档主张 | 状态 | 证据 | 结论说明 |
|---|---|---|---|
| 四层架构（Game/System/Manager/Data） | 已确认 | `scripts/autoload/*.gd`, `scripts/systems/*.gd`, `scripts/game/*.gd` | 架构职责分层清晰，Autoload 与系统层联动完整。 |
| EventBus 类型化信号总线 | 已确认 | `scripts/autoload/event_bus.gd` | 运行状态、战斗、房间、路线、UI、设置等信号均有实现。 |
| 配置中心统一加载 balance JSON | 已确认 | `scripts/autoload/config_manager.gd`, `data/balance/*.json` | `CONFIG_PATHS` 全量加载关键配置。 |
| 核心战斗与敌人压力模型 | 已确认 | `scripts/systems/damage_system.gd`, `scripts/systems/enemy_spawner.gd`, `scripts/game/enemy.gd` | 包含护甲上限、圣光穿透、房间时间+楼层缩放、精英与 Boss 逻辑。 |
| Run-Plan 地图生成与分支 | 已确认 | `scripts/systems/map_generator.gd`, `scripts/game/game_world.gd` | 房间类型、章节归属、节点连接、路线推进均可追踪。 |
| 宝藏房挑战模式（精英小波次后发奖） | 已确认 | `data/balance/map_generation.json`, `scripts/game/game_world.gd`, `scripts/validate_configs.py`, `test/unit/test_map_generation_config.gd` | 已支持可配置挑战参数（击杀门槛/奖励缩放/饰品概率）并具备配置与测试护栏。 |
| 叙事权重、路线风格、结局门槛 | 已确认 | `scripts/systems/narrative_system.gd`, `data/balance/narrative_content.json` | 包含 alignment、route style、recent 抑制、ending gate。 |
| HUD / 暂停 / 运行时设置 / 结算面板 | 已确认 | `scripts/ui/hud.gd`, `scripts/ui/pause_panel.gd`, `scripts/ui/runtime_settings_panel.gd`, `scripts/ui/run_result_panel.gd` | 信息反馈与设置持久化链路完整。 |
| 进化系统深度 | 部分实现 | `scripts/systems/level_up_system.gd`, `scripts/game/auto_weapon.gd`, `data/balance/evolutions.json` | 机制就绪且已扩容到 7 条 recipe，但距离全量规格仍有差距。 |
| 叙事记忆碎片体系 | 部分实现 | `data/balance/narrative_index.json`, `data/balance/narrative_content.json` | 索引与系统已接通，实际碎片内容量偏少。 |
| 角色/武器/被动/商店内容深度 | 部分实现 | `data/balance/characters.json`, `data/balance/shop_items.json`, `scripts/game/game_world.gd`, `test/unit/test_content_depth_targets.gd` | 已扩容至角色 8、商店 passive 8 / weapon 9，且新增条目已有消费逻辑与阈值护栏，仍需继续向全量目标推进。 |
| 大规模资源目录（以 `.tres` 为主） | 尚未体现（全量口径） | `resources/` | 当前除 narrative 外，未形成文档所述全量资源目录族。 |
| 主玩法场景 TileMap 化呈现 | 已确认（阶段 D） | `scenes/game/game_world.tscn`, `scripts/game/game_world.gd`, `assets/sprites/tiles/*.png`, `resources/tilesets/*.tres`, `data/balance/environment_config.json`, `test/unit/test_visual_tilemap_layers.gd` | 已完成地表/地表细节/门区块/危害/环境特效五层 TileMap 化，并从运行时程序化 tileset 切换为资源化 tileset；门/危害/环境特效层支持章节差异化 tileset 动态切换，危害与特效具备章节化动画节奏驱动，且 `visual_profile` 已支持细节层 tint/alpha + pulse 与特效层滚动 + wave 的参数化控制。 |
| 测试计划中的集成/性能/兼容矩阵 | 部分实现 | `test/unit/*.gd`, `test/integration/test_core_flow_regression.gd`, `data/balance/quality_baseline_targets.json`, `scripts/tools/run_quality_baseline.gd`, `test/unit/test_quality_baseline_targets.gd`, `spec-design/test-plan.md` | 已补关键流程集成回归，性能基线已扩展为 `elite_pressure_medium/high/extreme` 分层采样并支持告警分级；更大规模性能压测与跨平台实机矩阵仍未落地。 |

## 风险分级

- 高：文档全量承诺与仓库现状差距若不显式标注，会持续放大协作预期偏差。
- 中：内容深度不足会影响长线可玩性与构筑差异化体验。
- 中：已补关键流程集成回归并启动质量基线采样，但性能压测深度与跨平台实机覆盖仍薄弱。
- 低：表现层主链路已完成资源化接入，后续主要是临时 atlas 的手绘替换与细节打磨。
- 低：当前系统主干稳定，具备持续增量扩展基础。

## 建议推进顺序

1. 文档对齐（先消除预期偏差）
2. 内容扩容（角色/进化/商店池）
3. 表现升级（TileMap 与场景视觉管线）
4. 测试补强（集成回归 + 性能基线）

## 执行记录（D1）

- 2026-03-20 已完成下一周期 D1 冻结清单：`spec-design/content-depth-cycle-1-d1-freeze-2026-03-20.md`
- 本次仅冻结目标与新增 ID 范围，不改变本报告“真值矩阵”状态判断。

## 执行记录（D2）

- 2026-03-20 已完成下一周期 D2 数据层扩容：`characters.json`、`evolutions.json`、`shop_items.json`、`narrative_content.json`
- 关键计数提升：`characters 8`、`evolutions 7`、`shop passive 8`、`shop weapon 9`、`memory_fragments 10`
- 本次未改变矩阵状态等级（仍为“部分实现”），但证据规模已上升。

## 执行记录（D3）

- 2026-03-20 已完成下一周期 D3：`scripts/game/game_world.gd`、`test/unit/test_content_depth_targets.gd`、`test/integration/test_core_flow_regression.gd`
- 已补齐新增商店条目消费逻辑并抬升内容深度阈值（含 `memory_fragments >= 10`），且新增集成回归覆盖下一周期新增被动消费链路。
- 本次未改变矩阵状态等级（仍为“部分实现”），但“新增内容可消费+可回归”证据进一步增强。

## 执行记录（D4）

- 2026-03-20 已完成下一周期 D4：新增 `quality_baseline_targets.json`、`run_quality_baseline.gd`、`test_quality_baseline_targets.gd`，并接入 `validate_configs/check_resources/CI`。
- 已建立性能/兼容最小可重复采样链路（headless 输出 `user://quality_baseline_latest.json/.md`）。
- 本次未改变矩阵状态等级（仍为“部分实现”），但“性能/兼容基线”证据由 0 提升到可自动化采样层。

## 执行记录（D5）

- 2026-03-20 已完成下一周期 D5：将质量基线精英压力场景扩展为 `medium/high/extreme` 三档，并引入 `alert_grading` 告警分级阈值。
- `run_quality_baseline.gd` 已支持分档压力设置与 `critical/warning/info` 汇总输出，`validate_configs` 与对应单测已同步护栏。
- 本次未改变矩阵状态等级（仍为“部分实现”），但“性能/兼容基线”从单档采样提升为分层采样+分级告警。

## 执行记录（D6）

- 2026-03-20 已完成下一周期 D6：新增章节化门/危害 atlas 与对应 `.tres` 资源，并在 `game_world` 中接入按章节动态切换。
- `test/unit/test_visual_tilemap_layers.gd` 已新增章节后缀一致性断言，`check_resources` 已补齐章节化资源存在性护栏。
- 本次未改变矩阵状态等级（仍为“部分实现”），但“表现层章节差异化”证据由资源静态存在提升为运行时动态生效+可回归验证。

## 执行记录（D7）

- 2026-03-20 已完成下一周期 D7：`environment_config.json` 增加章节化 `hazard_anim_interval`，`game_world` 危害图层新增 atlas 变体轮换动画（按章节节奏驱动）。
- `validate_configs.py` 已新增 `hazard_anim_interval` 约束，`test_visual_tilemap_layers` 已新增动画推进断言，保证表现层细化可回归。
- 本次未改变矩阵状态等级（仍为“部分实现”），但“表现层章节差异化”证据由静态切换扩展到动态动画细化。

## 执行记录（D8）

- 2026-03-20 已完成下一周期 D8：新增 `GroundDetailTileMap`、`ground_detail_ch1~ch4.png` 与 `game_world_ground_detail_ch1~ch4.tres`，并在 `game_world` 中接入章节细节层铺设。
- `test_visual_tilemap_layers` 已新增 detail 层节点存在性与章节后缀一致性断言，`check_resources.py` 已补齐 detail atlas / tileset 文件护栏。
- 本次未改变矩阵状态等级（仍为“部分实现”），但“表现层章节差异化”证据从门/危害资源切换进一步扩展到地表装饰细节层。

## 执行记录（D9）

- 2026-03-20 已完成下一周期 D9：新增 `AmbientFxTileMap`、`ambient_fx_ch1~ch4.png` 与 `game_world_ambient_fx_ch1~ch4.tres`，并在 `game_world` 中接入章节化特效层铺设与动画轮换。
- `environment_config.json` 新增 `ambient_fx_interval`，`validate_configs.py` 已新增范围约束，`test_visual_tilemap_layers` 已新增 ambient fx 动画推进断言。
- 本次未改变矩阵状态等级（仍为“部分实现”），但“表现层章节差异化”证据进一步扩展到环境特效层动态切换与可回归动画。 

## 执行记录（D10）

- 2026-03-20 已完成下一周期 D10：`environment_config.json` 新增章节 `visual_profile`（detail tint/alpha、hazard/ambient alpha mult、ambient scroll）。
- `game_world` 已接入章节视觉参数驱动（地表细节层 tint+alpha、危害/特效层 alpha 乘区、ambient scroll 偏移），`validate_configs.py` 已补齐字段与范围校验。
- `test_visual_tilemap_layers` 已新增章节视觉参数回归断言（detail tint 差异 + ambient scroll 生效），表现层证据由“资源/动画可切换”提升到“章节参数化可回归控制”。

## 执行记录（D11）

- 2026-03-20 已完成下一周期 D11：`visual_profile` 新增 `detail_pulse_speed/detail_pulse_amplitude/ambient_wave_speed/ambient_wave_amplitude` 四个动态参数。
- `game_world` 已接入章节脉冲因子驱动（细节层 alpha pulse + 特效层 alpha wave），并新增 `_get_visual_profile_anim_factors(...)` 统一动态因子计算。
- `validate_configs.py` 已新增新字段范围校验，`test_visual_tilemap_layers` 已新增脉冲因子随时间变化断言，表现层证据由“章节参数化”提升到“章节动态节奏参数化可回归控制”。
