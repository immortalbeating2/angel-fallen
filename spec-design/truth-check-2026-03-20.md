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
| 进化系统深度 | 部分实现 | `scripts/systems/level_up_system.gd`, `scripts/game/auto_weapon.gd`, `data/balance/evolutions.json` | 机制就绪且已扩容到 13 条 recipe，并可在升级链路中消费，但距离全量规格仍有差距。 |
| 叙事记忆碎片体系 | 部分实现 | `data/balance/narrative_index.json`, `data/balance/narrative_content.json` | 索引与系统已接通，碎片内容已扩容到 22 条，但与全量叙事目标相比仍有提升空间。 |
| 角色/武器/被动/商店内容深度 | 部分实现 | `data/balance/characters.json`, `data/balance/shop_items.json`, `scripts/game/game_world.gd`, `test/unit/test_content_depth_targets.gd`, `test/integration/test_core_flow_regression.gd` | 已扩容至角色 12、商店 passive 14 / weapon 15，且新增条目已有消费逻辑与阈值+集成护栏，仍需继续向全量目标推进。 |
| 大规模资源目录（以 `.tres` 为主） | 部分实现 | `resources/`, `resources/resource_catalog.json`, `resources/{characters,weapons,passives,accessories,enemies,evolutions,meta_upgrades,forge_recipes}`, `resources/material_profiles/*.tres`, `scripts/tools/sync_resource_stubs.py`, `scripts/tools/run_resource_acceptance.gd`, `data/balance/resource_acceptance_targets.json`, `scripts/check_resources.py`, `test/unit/test_resource_directory_baseline.gd`, `test/unit/test_resource_acceptance_targets.gd` | 已补齐 8 类资源目录并从“样例 stub”扩展到“按内容 ID 批量映射 + 材质参数资产化 + production_ready 分层验收（catalog v8/batch_6）”，当前验收已覆盖“按类 ready 数量/比例 + 跨场景 smoke 深度 + acceptance_profile 分层语义一致性 + 分层趋势基线（bucket ratio + ratio drop）+ 场景内可视节点/属性检查（含 bool_true）+ production_ready_ratio_by_category 一致性”护栏；距离全量生产级实料内容仍有差距。 |
| 主玩法场景 TileMap 化呈现 | 已确认（阶段 D） | `scenes/game/game_world.tscn`, `scripts/game/game_world.gd`, `assets/sprites/tiles/*.png`, `assets/sprites/tiles/atlas_manifest.json`, `resources/tilesets/*.tres`, `data/balance/environment_config.json`, `test/unit/test_visual_tilemap_layers.gd` | 已完成地表/地表细节/门区块/危害/环境特效五层 TileMap 化，并从运行时程序化 tileset 切换为资源化 tileset；门/危害/环境特效层支持章节差异化 tileset 动态切换，危害与特效具备章节化动画节奏驱动，`visual_profile` 已支持细节层 tint/alpha+pulse 与特效层滚动+wave 参数化控制，且 handdrawn atlas 管线与 manifest 护栏已落地。 |
| 测试计划中的集成/性能/兼容矩阵 | 部分实现 | `test/unit/*.gd`, `test/integration/test_core_flow_regression.gd`, `data/balance/quality_baseline_targets.json`, `data/balance/release_gate_targets.json`, `data/balance/compatibility_rehearsal_targets.json`, `data/balance/visual_snapshot_targets.json`, `scripts/tools/check_json_syntax.py`, `scripts/tools/run_quality_baseline.gd`, `scripts/tools/run_release_gate.gd`, `scripts/tools/run_compatibility_rehearsal.gd`, `scripts/tools/run_visual_snapshot_regression.gd`, `test/unit/test_quality_baseline_targets.gd`, `test/unit/test_release_gate_targets.gd`, `test/unit/test_compatibility_rehearsal_targets.gd`, `test/unit/test_visual_snapshot_targets.gd`, `.github/workflows/ci.yml`, `spec-design/test-plan.md` | 已补关键流程集成回归；性能基线已扩展为 `elite_pressure_medium/high/extreme + boss_pressure_endurance` 分层采样并支持告警分级；已新增发布门演练、profile 级兼容演练，以及章节级可视快照指标回归（D36：`chapter_snapshot_v12` + `strategy_orchestration` 策略模板编排 + `release_gate_templates` 发布清单/门禁模板固化 + `backend_matrix_governance` 跨后端矩阵治理 + `approval_workflow` 审批流程硬约束 + `approval_audit_trail` 审批历史持久化与跨流水线追溯 + `approval_history_archive` 长期归档聚合与跨后端趋势 delta 约束 + `approval_threshold_templates` 分层审批阈值模板 + `release_candidate_tracking` 发布候选追踪评估 + `report_layers` 分层收敛 + `cross_version_baseline` 跨版本漂移约束 + `backend_attribution` 归因阻断 + `whitelist_convergence` 收敛建议 + `exception_lifecycle` 生命周期治理 + 趋势 gate）；并在 D30-1 前置 JSON 语法快速失败闸门（file:line:column 定位）。CI 已覆盖 ubuntu+windows 双平台矩阵，但大规模性能压测与跨平台实机矩阵仍未完全落地。 |

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

## 执行记录（D12）

- 2026-03-20 已完成下一周期 D12：`generate_visual_tiles.py` 升级为 handdrawn 风格 atlas 生成（地表材质颗粒/裂纹、门区块层次、危害与特效层涡流光晕细节）。
- 新增 `assets/sprites/tiles/atlas_manifest.json`（`style=handdrawn_v1`）并接入 `check_resources.py` 解析校验，确保 atlas 管线可追踪且不回退。
- `test_visual_tilemap_layers` 已新增 manifest 回归断言，表现层证据由“参数化动态控制”进一步提升到“资源风格化产物 + 护栏闭环”。

## 执行记录（D13）

- 2026-03-20 已完成下一周期 D13：内容深度二轮扩容（角色 10、进化 10、商店 passive 11 / weapon 12、记忆碎片 16）。
- `game_world` 已补齐新增商店条目消费逻辑，`test_content_depth_targets` 已抬升阈值，`test_core_flow_regression` 已新增 D13 武器购买闭环断言。
- 本次未改变矩阵状态等级（仍为“部分实现”），但“内容深度可消费+可回归”证据继续增强。

## 执行记录（D14）

- 2026-03-20 已完成下一周期 D14：补齐 `resources/{characters,weapons,passives,accessories,enemies,evolutions,meta_upgrades,forge_recipes}` 八类目录并落地最小可用 `.tres` stub 资源。
- `check_resources.py` 已新增目录/文件护栏与 stub 资源 `id/source_json` 结构一致性校验，`test_resource_directory_baseline` 已新增目录族回归断言。
- 本次将“资源目录族”矩阵状态由“尚未体现”提升到“部分实现”。

## 执行记录（D15）

- 2026-03-20 已完成下一周期 D15：`quality_baseline_targets` 新增 `game_world_boss_pressure_endurance` 场景，baseline 脚本新增 boss 房高压长时采样 setup。
- `validate_configs.py` 与 `test_quality_baseline_targets` 已同步新增场景键与 setup 合法值护栏；CI 已升级为 ubuntu + windows 双平台矩阵。
- 本次未改变矩阵状态等级（仍为“部分实现”），但“性能/兼容”证据从单平台分层采样提升到“分层采样 + 双平台 CI 覆盖”。

## 执行记录（D16）

- 2026-03-20 已完成下一周期 D16：新增 `release_gate_targets.json`、`run_release_gate.gd` 与 `test_release_gate_targets.gd`，形成发布门演练链路。
- `validate_configs.py` 已新增发布门配置 schema 校验，`check_resources.py` 已新增配置/脚本/单测资源存在性护栏，CI 已新增 release gate rehearsal 步骤。
- 本次未改变矩阵状态等级（仍为“部分实现”），但“性能/兼容”证据从“采样+告警”提升到“采样+告警+发布阈值演练自动化”。

## 执行记录（D17）

- 2026-03-20 已完成下一周期 D17：新增 `compatibility_rehearsal_targets.json`、`run_compatibility_rehearsal.gd` 与 `test_compatibility_rehearsal_targets.gd`，形成 profile 级兼容演练链路。
- `validate_configs.py` 已新增兼容演练配置 schema 校验，`check_resources.py` 已新增配置/脚本/单测资源存在性护栏，CI 已新增 compatibility rehearsal 步骤。
- 本次未改变矩阵状态等级（仍为“部分实现”），但“性能/兼容”证据从“采样+发布门演练”提升到“采样+发布门+profile 级兼容演练自动化”。

## 执行记录（D18）

- 2026-03-20 已完成下一周期 D18：内容深度三轮扩容（角色 12、进化 13、商店 passive 14 / weapon 15、记忆碎片 22）。
- `game_world` 已补齐 D18 新增商店条目消费分支；`test_content_depth_targets` 阈值已提升到 `12/13/14/15/22`；`test_core_flow_regression` 已新增 D18 武器购买闭环断言。
- 本次未改变矩阵状态等级（仍为“部分实现”），但“内容深度可消费+可回归”证据进一步增强。

## 执行记录（D19）

- 2026-03-20 已完成下一周期 D19：新增 `sync_resource_stubs.py` 与 `resources/resource_catalog.json`（`stub_catalog_v2`），形成资源目录族映射扩展管线。
- `check_resources.py` 已升级为 catalog 驱动校验（版本、分类完整性、路径可达、stub 内容与 source 目标一致性），`test_resource_directory_baseline` 已新增覆盖一致性断言。
- 本次未改变矩阵状态等级（仍为“部分实现”），但“资源目录族”证据从“最小样例 stub”提升到“批量映射 + 自动同步 + 可回归校验”。

## 执行记录（D20）

- 2026-03-20 已完成下一周期 D20：`sync_resource_stubs.py` 与 `resource_catalog.json` 升级为 `stub_catalog_v3`，新增 `display_name/material_profile/asset_state` 字段。
- 已新增 `resources/material_profiles/*.tres` 8 类材质参数基线，并在 8 类目录 stub 中完成 `material_profile + asset_state=production_candidate` 接入。
- `check_resources.py` 与 `test_resource_directory_baseline.gd` 已补齐 v3 结构/字段/路径一致性护栏；本次未改变矩阵状态等级（仍为“部分实现”），但“资源目录族”证据由“映射驱动 stub”提升到“材质参数资产化基线”。

## 执行记录（D21）

- 2026-03-20 已完成下一周期 D21：新增 `resource_acceptance_targets.json` 与 `run_resource_acceptance.gd`，形成首批 production-ready 资源验收链路。
- `sync_resource_stubs.py` 与 `resource_catalog.json` 已升级为 `stub_catalog_v4`，entry 新增 `preview_texture/acceptance_scene/acceptance_profile` 并支持目标 ID 的 `production_ready` 标记。
- `check_resources.py` 与 `test_resource_directory_baseline.gd` 已补齐 v4 字段/计数一致性护栏，新增 `test_resource_acceptance_targets.gd` 覆盖目标配置与 catalog 映射。
- 本次未改变矩阵状态等级（仍为“部分实现”），但“资源目录族”证据由“production_candidate 基线”提升到“首批 production_ready 可运行验收”。

## 执行记录（D22）

- 2026-03-20 已完成下一周期 D22：`resource_acceptance_targets.json` 升级为 `batch_2`，扩充 8 类 `required_production_ready_ids`，并新增 `acceptance_scene_matrix`（每类至少 2 个场景 smoke）。
- `run_resource_acceptance.gd` 已新增分类就绪率与场景 smoke 深度验收（`category_ready` + `scene_smokes`），`validate_configs.py` 与 `test_resource_acceptance_targets.gd` 已补齐对应阈值/schema 护栏。
- 本次未改变矩阵状态等级（仍为“部分实现”），但“资源目录族”证据由“首批 production_ready 点状验收”提升到“按类比例 + 跨场景深度验收”的阶段化准入。

## 执行记录（D23）

- 2026-03-20 已完成下一周期 D23：`resource_acceptance_targets.json` 升级为 `batch_3`，新增 `acceptance_profile_policy`（profiles/category_profile_map/required_ready_profile_tier）与 `max_profile_mismatches` 阈值。
- `sync_resource_stubs.py` 与 `resource_catalog.json` 已升级为 `stub_catalog_v5`，新增 `acceptance_tier` 与 `acceptance_tier_counts`，并按 profile policy 自动生成分类 profile/tier。
- `run_resource_acceptance.gd` 已新增 `profile_layers` 与 `profile_mismatches` 报告分层，并将 profile 存在性、tier 对齐、category-state 映射对齐纳入阻断判定。
- 本次未改变矩阵状态等级（仍为“部分实现”），但“资源目录族”证据由“ready 比例+场景 smoke”提升到“ready 比例+场景 smoke+profile 语义分层一致性”的阶段化准入。

## 执行记录（D24）

- 2026-03-20 已完成下一周期 D24：`resource_acceptance_targets.json` 升级为 `batch_4`，扩充 8 类 `required_production_ready_ids`，并将阈值抬升到 `min_ready_per_category=3`、`min_ready_ratio_per_category=0.5`。
- 新增 `trend_baseline`（`bucket_ready_ratio_min`、`max_category_ratio_drop`、`max_bucket_ratio_drop`）与 `max_trend_regressions`，将分层趋势告警纳入验收口径。
- `sync_resource_stubs.py` 与 `resource_catalog.json` 已升级为 `stub_catalog_v6`，新增 `acceptance_bucket_counts`；`run_resource_acceptance.gd` 已新增 `profile_buckets` 与 `trend` 报告段，并支持 `resource_acceptance_previous.json` 轮转对比。
- `validate_configs.py`、`check_resources.py`、`test_resource_acceptance_targets.gd`、`test_resource_directory_baseline.gd` 已补齐 D24 schema/结构/语义护栏，CI 已新增 resource acceptance 二次执行的 trend gate。
- 本次未改变矩阵状态等级（仍为“部分实现”），但“资源目录族”证据由“分层语义一致性”提升到“分层语义一致性 + 趋势基线阻断”的阶段化准入。

## 执行记录（D25）

- 2026-03-20 已完成下一周期 D25：`resource_acceptance_targets.json` 升级为 `batch_5`，扩充 8 类 `required_production_ready_ids`，并将阈值抬升到 `min_ready_per_category=4`、`min_ready_ratio_per_category=0.7`、`min_scene_smokes_per_category=3`。
- 新增 `scene_visual_requirements` 与阈值 `min_visual_checks_per_category=3`、`max_visual_failures=0`，将“场景内真实可视验收”纳入自动阻断口径。
- `sync_resource_stubs.py` 与 `resource_catalog.json` 已升级为 `stub_catalog_v7`，新增 `scene_visual_requirements` 与 `scene_visual_requirement_counts`；`run_resource_acceptance.gd` 已新增 `visual_checks/visual_failures` 报告分段。
- `validate_configs.py`、`check_resources.py`、`test_resource_acceptance_targets.gd`、`test_resource_directory_baseline.gd` 已补齐 D25 schema/结构/语义护栏，CI 已将 acceptance 二次执行升级为 trend+visual gate。
- 本次未改变矩阵状态等级（仍为“部分实现”），但“资源目录族”证据由“分层趋势基线阻断”提升到“分层趋势基线 + 场景可视验收阻断”的阶段化准入。

## 执行记录（D26）

- 2026-03-20 已完成下一周期 D26：`resource_acceptance_targets.json` 升级为 `batch_6`，8 类 `required_production_ready_ids` 提升为全量覆盖，并将阈值抬升到 `min_ready_ratio_per_category=0.95`、`min_scene_smokes_per_category=4`、`min_visual_checks_per_category=4`。
- `scene_visual_requirements` 每类已提升为 4 条，新增 `bool_true` 规则；`acceptance_scene_matrix` 每类已提升到 4 场景 smoke。
- `sync_resource_stubs.py` 与 `resource_catalog.json` 已升级为 `stub_catalog_v8`，新增 `production_ready_ratio_by_category`；`run_resource_acceptance.gd` 已新增 ratio 一致性阻断与 `bool_true` 可视规则执行。
- `validate_configs.py`、`check_resources.py`、`test_resource_acceptance_targets.gd`、`test_resource_directory_baseline.gd` 已补齐 D26 护栏，验收链（baseline/release/compatibility/resource_acceptance x2/GUT/headless）全绿。
- 本次未改变矩阵状态等级（仍为“部分实现”），但“资源目录族”证据由“batch_5 可视验收”提升到“batch_6 近全量 production-ready + 4x 深度验收 + v8 比例一致性阻断”的阶段化准入。

## 执行记录（D27）

- 2026-03-20 已完成下一周期 D27：新增 `visual_snapshot_targets.json` 与 `run_visual_snapshot_regression.gd`，形成章节级可视快照回归链路。
- 快照链路已覆盖 chapter_1~4 世界场景与主菜单 UI，输出 `visual_snapshot_latest.json/.md`，并通过 `visual_snapshot_previous.json` 做趋势对比阻断。
- `validate_configs.py`、`check_resources.py`、`test_visual_snapshot_targets.gd` 已补齐 D27 schema/路径/阈值护栏，CI 已新增 visual snapshot rehearsal + trend gate 两步。
- 本次未改变矩阵状态等级（仍为“部分实现”），但“测试计划中的集成/性能/兼容矩阵”证据从“性能/发布/兼容”提升到“性能/发布/兼容 + 可视快照趋势回归”的阶段化准入。

## 执行记录（D28）

- 2026-03-20 已完成下一周期 D28：`visual_snapshot_targets.json` 升级为 `chapter_snapshot_v2`，新增 `precision` 与 `backend_profiles`，并收紧可视快照趋势阈值。
- `run_visual_snapshot_regression.gd` 已新增多轮采样聚合（均值 + stddev）、精度收敛 gate、后端 profile 阈值应用与 `backend_tag` 报告输出。
- `validate_configs.py`、`check_resources.py`、`test_visual_snapshot_targets.gd` 已补齐 D28 schema/结构/阈值护栏，CI 可视快照两步已注入 `VISUAL_SNAPSHOT_BACKEND_TAG` 进行 linux/windows 差异路径回归。
- 本次未改变矩阵状态等级（仍为“部分实现”），但“测试计划中的集成/性能/兼容矩阵”证据从“可视快照趋势回归”提升到“可视快照精度收敛 + 跨后端阈值治理”的阶段化准入。

## 执行记录（D29）

- 2026-03-20 已完成下一周期 D29：`visual_snapshot_targets.json` 升级为 `chapter_snapshot_v3`，新增 `baseline_alignment`（`required_snapshot_ids` + `allowed_capture_modes`）与 `diff_whitelist` / `whitelist_policy`。
- `run_visual_snapshot_regression.gd` 已接入白名单差异治理：后端+快照级阈值覆盖、whitelist 命中记录与命中次数/比例双阈值约束。
- `validate_configs.py`、`check_resources.py`、`test_visual_snapshot_targets.gd` 已补齐 D29 schema/结构/阈值护栏，CI visual snapshot rehearsal + trend gate 双步继续覆盖 linux/windows 后端路径。
- 本次未改变矩阵状态等级（仍为“部分实现”），但“测试计划中的集成/性能/兼容矩阵”证据从“精度收敛+后端阈值治理”提升到“基线对齐+白名单可审计治理+趋势 gate”的阶段化准入。

## 执行记录（D30-1）

- 2026-03-20 已完成 D30 第一子任务：新增 `scripts/tools/check_json_syntax.py`，前置校验 `data/balance/*.json`、`resources/resource_catalog.json`、`assets/sprites/tiles/atlas_manifest.json` 的语法合法性。
- CI `validate-config-and-resources` 已前置 `JSON syntax gate`，在语法解析失败时快速阻断后续重链路。
- 本次未改变矩阵状态等级（仍为“部分实现”），但“测试计划中的集成/性能/兼容矩阵”证据增加了“低成本语法 fail-fast + 精确定位（file:line:column）”护栏。

## 执行记录（D30-2）

- 2026-03-20 已完成 D30 第二子任务：`visual_snapshot_targets.json` 升级为 `chapter_snapshot_v4`，新增 `report_layers` 与 `cross_version_baseline`。
- `run_visual_snapshot_regression.gd` 已接入跨版本漂移评估与分层收敛评估，并输出 `Cross Version` / `Layers` 报告段。
- `validate_configs.py`、`check_resources.py`、`test_visual_snapshot_targets.gd` 已补齐 D30-2 schema/结构/阈值护栏。
- 本次未改变矩阵状态等级（仍为“部分实现”），但“测试计划中的集成/性能/兼容矩阵”证据从“基线对齐+白名单治理”提升到“跨版本漂移约束+分层收敛阻断”的阶段化准入。

## 执行记录（D30-3）

- 2026-03-20 已完成 D30 第三子任务：`visual_snapshot_targets.json` 升级为 `chapter_snapshot_v5`，新增 `backend_attribution` 与 `whitelist_convergence`。
- `run_visual_snapshot_regression.gd` 已接入跨后端差异归因统计/阻断与白名单收敛建议自动化，并输出 `Backend Attribution` / `Whitelist Convergence` 报告段。
- `validate_configs.py`、`check_resources.py`、`test_visual_snapshot_targets.gd` 已补齐 D30-3 schema/结构/阈值护栏。
- 本次未改变矩阵状态等级（仍为“部分实现”），但“测试计划中的集成/性能/兼容矩阵”证据从“跨版本漂移+分层收敛”提升到“跨后端可归因阻断+白名单自动收敛建议”的阶段化准入。

## 执行记录（D30-4）

- 2026-03-20 已完成 D30 第四子任务：`visual_snapshot_targets.json` 升级为 `chapter_snapshot_v6`，新增 `exception_lifecycle`（规则老化过期 + 自动回收候选）。
- `run_visual_snapshot_regression.gd` 已接入例外生命周期治理（`expire_idle_runs`、`auto_reclaim_hit_streak`）与上限阻断（`max_expired_entries`、`max_reclaim_candidates`），并输出 `Exception Lifecycle` 报告分段。
- `validate_configs.py`、`check_resources.py`、`test_visual_snapshot_targets.gd` 已补齐 D30-4 schema/结构/阈值护栏。
- 本次未改变矩阵状态等级（仍为“部分实现”），但“测试计划中的集成/性能/兼容矩阵”证据从“跨后端归因+收敛建议”提升到“例外生命周期治理+自动回收策略”的阶段化准入。

## 执行记录（D31）

- 2026-03-20 已完成 D31：`visual_snapshot_targets.json` 升级为 `chapter_snapshot_v7`，新增 `strategy_orchestration`（`default_strategy` + `strategies` + `templates`）。
- `run_visual_snapshot_regression.gd` 已接入策略模板解析与策略生效阈值合并，支持同一链路在 rehearsal/trend/release 策略间切换，并输出 `strategy` 元数据。
- `validate_configs.py`、`check_resources.py`、`test_visual_snapshot_targets.gd` 已补齐 D31 schema/结构/引用完整性护栏。
- CI visual snapshot 两步已注入 `VISUAL_SNAPSHOT_STRATEGY`（`ci_rehearsal` / `ci_trend_gate`），实现策略编排可回归。
- 本次未改变矩阵状态等级（仍为“部分实现”），但“测试计划中的集成/性能/兼容矩阵”证据从“例外生命周期治理”提升到“策略模板化编排 + 发布级收敛切换”的阶段化准入。

## 执行记录（D32）

- 2026-03-20 已完成 D32：`visual_snapshot_targets.json` 升级为 `chapter_snapshot_v8`，新增 `release_gate_templates`（required strategy bindings + ci mode bindings + release checklist）。
- `run_visual_snapshot_regression.gd` 已接入 `release_manifest` 评估，支持模板绑定校验、CI run_mode 对齐、required report 存在性校验、publish strategy 清单约束与阈值阻断。
- `validate_configs.py`、`check_resources.py`、`test_visual_snapshot_targets.gd` 已补齐 D32 schema/结构/引用完整性护栏。
- CI visual snapshot 链路新增 `VISUAL_SNAPSHOT_RUN_MODE`，并加入 release 模板 dry-run（`release_candidate` / `release_blocking`）以固化发布门禁模板。
- 本次未改变矩阵状态等级（仍为“部分实现”），但“测试计划中的集成/性能/兼容矩阵”证据从“策略模板化编排”提升到“发布清单固化 + 门禁模板可执行化”的阶段化准入。

## 执行记录（D33）

- 2026-03-20 已完成 D33：`visual_snapshot_targets.json` 升级为 `chapter_snapshot_v9`，新增 `backend_matrix_governance` 与 `approval_workflow`。
- `run_visual_snapshot_regression.gd` 已接入跨后端矩阵覆盖评估（`VISUAL_SNAPSHOT_BACKEND_MATRIX` + required run modes）与审批流程约束（required report sections + strategy 级零阻断/零告警策略）。
- `validate_configs.py`、`check_resources.py`、`test_visual_snapshot_targets.gd` 已补齐 D33 schema/结构/阈值护栏，CI visual snapshot 四步已统一注入 backend matrix 环境变量。
- 本次未改变矩阵状态等级（仍为“部分实现”），但“测试计划中的集成/性能/兼容矩阵”证据从“发布模板固化”提升到“跨后端矩阵治理 + 审批流程硬约束”的阶段化准入。

## 执行记录（D34）

- 2026-03-20 已完成 D34：`visual_snapshot_targets.json` 升级为 `chapter_snapshot_v10`，新增 `approval_audit_trail`（history file/max entries/required run modes+backends/pipeline id 唯一性/trace failure 阈值）。
- `run_visual_snapshot_regression.gd` 已接入审批历史持久化与追溯校验（`approval_audit` 报告分段）；非 `release_blocking` 模式缺口以 warning 提示，`release_blocking` 保持严格阻断。
- `validate_configs.py`、`check_resources.py`、`test_visual_snapshot_targets.gd` 已补齐 D34 schema/结构/一致性护栏；CI visual snapshot 四步已注入 `VISUAL_PIPELINE_ID` 形成跨流水线追溯上下文。
- 本次未改变矩阵状态等级（仍为“部分实现”），但“测试计划中的集成/性能/兼容矩阵”证据从“审批流程硬约束”提升到“审批历史持久化 + 跨流水线追溯”的阶段化准入。

## 执行记录（D35）

- 2026-03-20 已完成 D35：`visual_snapshot_targets.json` 升级为 `chapter_snapshot_v11`，新增 `approval_history_archive`（archive file/max entries/aggregation window/required run modes+backends/backend delta bounds/archive trace failure bounds）。
- `run_visual_snapshot_regression.gd` 已接入长期归档聚合评估（`approval_archive`）：按滚动窗口统计 run_mode/backend 覆盖与跨后端 warning/blocker delta，并输出 `Approval History Archive` 分段。
- `validate_configs.py`、`check_resources.py`、`test_visual_snapshot_targets.gd` 已补齐 D35 schema/结构/一致性护栏；可视快照四模式执行链路继续携带 `VISUAL_PIPELINE_ID` 以增强跨流水线历史可追溯性。
- 本次未改变矩阵状态等级（仍为“部分实现”），但“测试计划中的集成/性能/兼容矩阵”证据从“审批历史追溯”提升到“长期归档聚合 + 跨后端趋势治理”的阶段化准入。

## 执行记录（D36）

- 2026-03-20 已完成 D36：`visual_snapshot_targets.json` 升级为 `chapter_snapshot_v12`，新增 `approval_threshold_templates`（run_mode 分层审批阈值模板）与 `release_candidate_tracking`（窗口聚合候选稳定性评估）。
- `run_visual_snapshot_regression.gd` 已接入模板化审批阈值生效与 `Release Candidate Tracking` 分段：按 run_mode 套用审批阈值模板，并对发布候选执行 `min_runs/avg_warnings/total_blockers` 追踪评估。
- `validate_configs.py`、`check_resources.py`、`test_visual_snapshot_targets.gd` 已补齐 D36 schema/结构/一致性护栏（v12 channel + templates/tracking + manifest/strategy 引用约束）。
- 本次未改变矩阵状态等级（仍为“部分实现”），但“测试计划中的集成/性能/兼容矩阵”证据从“长期归档聚合”提升到“审批阈值模板化编排 + 发布候选稳定性追踪”的阶段化准入。
