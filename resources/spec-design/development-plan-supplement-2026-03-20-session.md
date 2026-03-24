# 开发过程复盘与计划补充（基于 session-20260320）

## 复盘来源

- 会话记录：`session-(angel-fallen)-20260320.md`
- 对齐文档：`spec-design/development-plan-2026-03-20.md`
- 本文目的：确认“已经做了什么”，并补齐“接下来怎么做”。

## 已完成开发过程（按主线归纳）

### 1) 内容深度首轮扩容

- 角色从 3 扩到 6：`data/balance/characters.json`
- 进化从 1 扩到 4：`data/balance/evolutions.json`
- 商店池扩容（passive/weapon）：`data/balance/shop_items.json`
- 商店条目说明与效果分支补齐：`scripts/game/game_world.gd`
- 新增深度护栏测试：`test/unit/test_content_depth_targets.gd`

### 2) 工程化与质量基建

- 新增 Git LFS 规则：`.gitattributes`
- 新增 CI：`.github/workflows/ci.yml`
  - Python 配置与资源检查
  - Godot headless 启动检查
  - GUT 单测

### 3) 地图与房间生成能力增强

- treasure 房接入与运行时流程完善：`scripts/game/game_world.gd`
- run-plan 坐标化输出与 minimap 坐标优先渲染：
  - `scripts/systems/map_generator.gd`
  - `scripts/game/game_world.gd`
- 每章房型上限/下限约束：
  - `data/balance/map_generation.json`
  - `scripts/systems/map_generator.gd`
  - `scripts/validate_configs.py`
  - `test/unit/test_map_generation_config.gd`

### 4) 敌人系统两条主线闭环

- 敌人对象池化闭环：
  - `scripts/game/enemy.gd`
  - `scripts/systems/enemy_spawner.gd`
  - `scripts/game/game_world.gd`
  - `test/unit/test_enemy_pooling.gd`
- 章节敌人分型映射闭环：
  - `data/balance/enemy_scaling.json`（`chapter_archetype_map`）
  - `scripts/systems/enemy_spawner.gd`
  - `scripts/validate_configs.py`
  - `test/unit/test_enemy_scaling_profiles.gd`
  - `scripts/ui/main_menu.gd`

### 5) 验证结果（来自 session 记录）

- `python scripts/validate_configs.py`：通过
- `python scripts/check_resources.py`：通过
- Godot headless 启动：通过
- GUT：`7 scripts / 22 tests / 768 asserts / 0 failures`

## 阶段性结论（本轮更新）

- 阶段 C1（宝藏房挑战模式闭环）已完成：
  - 宝藏房由“进房即发奖”改为“精英小波次后发奖”。
  - challenge 参数已外置到 `data/balance/map_generation.json`。
  - 运行时接入、配置校验与单测护栏均已补齐。
- 阶段 D 已完成两轮：主场景地表/门区块/危害可视层已完成 TileMap 化。

## 补充开发计划（V2）

### 阶段 C1：宝藏房挑战模式闭环（优先级 P0，已完成）

- 实现项
  - 在 `scripts/game/game_world.gd` 接入挑战状态机（开启挑战 -> 计数达标 -> 发奖 -> 开门）。
  - 在 `data/balance/map_generation.json` 增加 challenge 参数（击杀门槛、缩放、奖励与饰品概率）。
  - 在 `scripts/validate_configs.py` 增加参数合法性检查。
  - 在 `test/unit/test_map_generation_config.gd` 增加 challenge 配置与边界断言。
- 验收标准
  - 宝藏房不再“进房即发奖”。
  - challenge 参数改动可即时影响行为（无需改代码）。
  - Python 校验与 GUT 全绿。

已完成项（2026-03-20）：

- `data/balance/map_generation.json`：新增 `treasure_challenge` 参数段。
- `scripts/game/game_world.gd`：新增挑战流程（开战 -> 达标清场 -> 发奖 -> 开门）。
- `scripts/validate_configs.py`：新增 `treasure_challenge` 字段与范围校验。
- `test/unit/test_map_generation_config.gd`：新增 challenge 配置存在性和边界断言。

### 阶段 C2：关键流程集成回归（优先级 P1，已完成）

- 场景链路
  - 角色选择 -> 开局 -> 房间推进 -> 结算落盘
  - 升级 -> 进化触发
  - 商店购买 -> 资源变化 -> UI 同步
- 验收标准
  - 每条链路至少 1 条可重复回归用例。
  - 与现有单测组合后，核心循环回归风险显著下降。

已完成项（2026-03-20）：

- 新增 `test/integration/test_core_flow_regression.gd`，覆盖以下 3 条链路：
  - 角色选择 -> 开局 -> 房间推进 -> 结算落盘
  - 升级触发进化关键路径（holy_cross -> holy_judgment）
  - 商店购买 -> 资源变化 -> 效果生效反馈
- 修复 `scripts/systems/level_up_system.gd` 中进化路径动态属性读取的解析问题。
- 本地 GUT 全量回归通过（`res://test`：`9 scripts / 28 tests / 946 asserts / 0 failures`）。

### 阶段 D：表现层升级（优先级 P2）

- 主场景 TileMap 化（地表 -> 门区块 -> 危害层逐步替换）
- 保持系统接口不变，降低行为回归风险
- 验收标准
  - 玩法行为一致。
  - 视觉层替换不影响既有测试通过率。

当前进度（2026-03-20，D9 首轮）：

- 已完成：
  - `scenes/game/game_world.tscn` 新增 `GroundTileMap` 与 `DoorTileMap`。
  - `scripts/game/game_world.gd` 新增运行时 tileset 生成与章节 palette 地表渲染。
  - `scripts/game/game_world.gd` 将门锁状态同步到 TileMap 门区块渲染。
  - `test/unit/test_visual_tilemap_layers.gd` 新增可视层节点与 tileset 存在性回归护栏。
- 待完成：
  - 无阻塞待办。

当前进度（2026-03-20，D10 第二轮）：

- 已完成：
  - `scenes/game/game_world.tscn` 新增 `HazardTileMap`，并将 `HazardTint` 退为隐藏兼容层。
  - `scripts/game/game_world.gd` 危害可视层改为 TileMap overlay 渲染，透明度由 hazard 强度驱动。
  - `scripts/game/game_world.gd` 补齐 treasure challenge 房间的 hazard 强度基线，保证挑战宝藏房危害反馈一致。
  - `test/unit/test_visual_tilemap_layers.gd` 新增 HazardTileMap 状态驱动断言（激活/清除）。
- 后续优化：
  - 将当前临时 atlas 逐步替换为正式手绘 tileset。

当前进度（2026-03-20，D11 第三轮）：

- 已完成：
  - `assets/sprites/tiles/` 新增地表/门/危害 overlay atlas 贴图（4 章节地表 + doors + hazard）。
  - `resources/tilesets/` 新增 6 个 TileSet 资源（ground_ch1~ch4、doors、hazard_overlay）。
  - `scripts/game/game_world.gd` 从运行时程序化 tileset 切换到资源化 tileset 加载。
  - `scripts/tools/generate_visual_tiles.py` 与 `scripts/tools/build_tileset_resources.gd` 落地，支持可重复生成/构建。
  - `test/unit/test_visual_tilemap_layers.gd` 新增 tileset 资源路径断言，防止回退到程序化临时方案。
- 后续优化：
  - 以正式手绘素材替换当前临时 atlas，并补充章节差异化细节与动画表现。

## 下一周期启动（内容优先，2026-03-20）

- 执行配比：内容深度 60% / 质量基线 25% / 美术替换 15%。
- D1（冻结清单）已完成：
  - 文档：`spec-design/content-depth-cycle-1-d1-freeze-2026-03-20.md`
  - 已锁定新增 ID、目标阈值、D2/D3 修改范围与验收命令。
- D2（数据层扩容）已完成：
  - 修改：`data/balance/characters.json`、`data/balance/evolutions.json`、`data/balance/shop_items.json`、`data/balance/narrative_content.json`
  - 计数：`characters 8`、`evolutions 7`、`shop passive 8`、`shop weapon 9`、`memory_fragments 10`
  - 校验：`validate_configs`、`check_resources`、全量 GUT 与 headless 启动均通过。
- D3（逻辑消费补齐 + 测试阈值抬升）已完成：
  - `scripts/game/game_world.gd` 已补齐新增商店 ID 的 title/desc/effect 分支。
  - `test/unit/test_content_depth_targets.gd` 已抬升阈值，并新增 `memory_fragments >= 10` 断言。
  - `test/integration/test_core_flow_regression.gd` 已新增下一周期内容消费链路（`pas_momentum`）回归。
  - 校验：`validate_configs`、`check_resources`、全量 GUT（`10 scripts / 32 tests / 1082 asserts / 0 failures`）与 headless 启动均通过。
- D4（质量基线：性能/兼容最小可重复采样）已完成：
  - 新增 `data/balance/quality_baseline_targets.json`（场景采样配置 + 帧时间/内存阈值 + 兼容矩阵）。
  - 新增 `scripts/tools/run_quality_baseline.gd`（headless 采样并输出 `user://quality_baseline_latest.json/.md`）。
  - 新增 `test/unit/test_quality_baseline_targets.gd`（schema 与 InputMap 动作护栏）。
  - `scripts/validate_configs.py`、`scripts/check_resources.py`、`.github/workflows/ci.yml` 已接入质量基线配置/脚本校验链路。
  - 校验：`validate_configs`、`check_resources`、全量 GUT 与 headless 启动均通过。
- D5（质量基线分层压力 + 告警分级）已完成：
  - `quality_baseline_targets.json` 场景扩展为 `elite_pressure_medium/high/extreme`。
  - `run_quality_baseline.gd` 新增分档压力设置（room index / max_alive / runtime modifiers）与告警分级汇总。
  - `scripts/validate_configs.py`、`test/unit/test_quality_baseline_targets.gd` 同步校验新增场景键与 `alert_grading`。
  - 校验：`validate_configs`、`check_resources`、baseline snapshot、全量 GUT 与 headless 启动均通过。
- D6（章节差异化 TileSet 细化）已完成：
  - 新增章节化门/危害 atlas：`doors_ch1~ch4.png`、`hazard_overlay_ch1~ch4.png`。
  - TileSet 构建扩展为章节化门/危害资源：`game_world_doors_ch1~ch4.tres`、`game_world_hazard_overlay_ch1~ch4.tres`。
  - `game_world` 门层/危害层改为按章节动态加载 tileset，替代单资源全章节复用。
  - `test/unit/test_visual_tilemap_layers.gd` 新增章节后缀一致性断言。
  - `scripts/check_resources.py` 新增章节化 atlas 与 tileset 文件护栏。
  - 校验：`validate_configs`、`check_resources`、baseline snapshot、全量 GUT 与 headless 启动均通过。
- D7（危害图层动画细化）已完成：
  - `environment_config.json` 新增章节化 `hazard_anim_interval` 参数。
  - `game_world` 危害层新增 atlas 变体轮换动画（cell phase + frame ticker），并按章节节奏驱动。
  - `validate_configs.py` 新增 `hazard_anim_interval` 范围校验（`[0.08, 0.40]`）。
  - `test/unit/test_visual_tilemap_layers.gd` 新增危害图层动画推进断言。
  - 校验：`validate_configs`、`check_resources`、baseline snapshot、全量 GUT 与 headless 启动均通过。
- D8（章节地表细节层细化）已完成：
  - `scenes/game/game_world.tscn` 新增 `GroundDetailTileMap`。
  - `assets/sprites/tiles/` 新增 `ground_detail_ch1~ch4.png`，并构建为 `game_world_ground_detail_ch1~ch4.tres`。
  - `game_world` 已接入章节地表细节层的动态 tileset 切换与稀疏装饰铺设逻辑。
  - `test/unit/test_visual_tilemap_layers.gd` 与 `scripts/check_resources.py` 已新增 detail 层护栏。
  - 校验：`validate_configs`、`check_resources`、全量 GUT 与 headless 启动均通过。
- D9（章节环境特效层细化）已完成：
  - `scenes/game/game_world.tscn` 新增 `AmbientFxTileMap`。
  - `assets/sprites/tiles/` 新增 `ambient_fx_ch1~ch4.png`，并构建为 `game_world_ambient_fx_ch1~ch4.tres`。
  - `game_world` 已接入章节化特效层动态 tileset 切换、特效图块铺设与 atlas 变体轮换动画。
  - `environment_config.json` 新增 `ambient_fx_interval`，`validate_configs.py` 新增范围校验（`[0.12, 0.60]`）。
  - `test/unit/test_visual_tilemap_layers.gd` 与 `scripts/check_resources.py` 已新增 ambient fx 层护栏。
  - 校验：`validate_configs`、`check_resources`、baseline snapshot、全量 GUT 与 headless 启动均通过。
- D10（章节视觉参数化细化）已完成：
  - `environment_config.json` 新增章节 `visual_profile`（detail tint/alpha、hazard/ambient alpha mult、ambient scroll）。
  - `game_world` 已接入章节视觉参数驱动（细节层 tint+alpha、危害/特效层 alpha 乘区、ambient scroll 偏移）。
  - `validate_configs.py` 已新增 `visual_profile` 字段与范围校验。
  - `test/unit/test_visual_tilemap_layers.gd` 已新增章节视觉参数回归断言（detail tint 差异 + ambient scroll 生效）。
  - 校验：`validate_configs`、`check_resources`、baseline snapshot、全量 GUT 与 headless 启动均通过。
- D11（章节视觉脉冲细化）已完成：
  - `environment_config.json` 的 `visual_profile` 新增 `detail_pulse_speed/detail_pulse_amplitude/ambient_wave_speed/ambient_wave_amplitude`。
  - `game_world` 已接入章节脉冲因子驱动（细节层 alpha pulse + 特效层 alpha wave），并保持既有 TileMap 接口不变。
  - `validate_configs.py` 已补齐新字段范围校验（speed `[0.0, 6.0]`，amplitude `[0.0, 0.25]`）。
  - `test/unit/test_visual_tilemap_layers.gd` 已新增脉冲因子随时间变化断言，防止参数接入回退。
  - 校验：`validate_configs`、`check_resources`、baseline snapshot、全量 GUT 与 headless 启动均通过。
- D12（手绘 atlas 替换与材质细节增强）已完成：
  - `generate_visual_tiles.py` 升级 handdrawn 风格纹理生成（地表颗粒/裂纹、门区块层次、危害与特效层涡流光晕细节）。
  - 新增 `assets/sprites/tiles/atlas_manifest.json`（`style=handdrawn_v1`）作为 atlas 资源快照。
  - `scripts/check_resources.py` 已新增 manifest 解析与条目下限校验。
  - `test/unit/test_visual_tilemap_layers.gd` 已新增 manifest 回归断言，保证手绘 atlas 管线不回退。
  - 校验：`validate_configs`、`check_resources`、baseline snapshot、全量 GUT 与 headless 启动均通过。
- D13（内容深度二轮扩容）已完成：
  - `characters.json` 扩容到 10（新增 `char_sentinel`、`char_witchblade`）。
  - `evolutions.json` 扩容到 10（新增 `evo_radiant_cataclysm`、`evo_tempest_onslaught`、`evo_blood_requiem`）。
  - `shop_items.json` 扩容到 passive 11 / weapon 12，并同步 chapter override。
  - `narrative_content.json` 记忆碎片扩容到 16。
  - `game_world.gd` 已接入新增商店内容消费；`test_content_depth_targets.gd` 阈值抬升；`test_core_flow_regression.gd` 新增 D13 武器购买回归。
  - 校验：`validate_configs`、`check_resources`、baseline snapshot、全量 GUT 与 headless 启动均通过。
- D14（资源目录族最小可用落地）已完成：
  - 已补齐 `resources/{characters,weapons,passives,accessories,enemies,evolutions,meta_upgrades,forge_recipes}` 八类目录。
  - 每类目录已落地最小可用 `.tres` stub 资源并声明 `id + source_json`。
  - `scripts/check_resources.py` 已新增目录/文件护栏与 stub 资源结构一致性校验。
  - `test/unit/test_resource_directory_baseline.gd` 已新增资源目录族回归断言。
  - 校验：`validate_configs`、`check_resources`、baseline snapshot、全量 GUT 与 headless 启动均通过。
- D15（性能压测深化 + CI 兼容矩阵扩展）已完成：
  - `quality_baseline_targets.json` 新增 `game_world_boss_pressure_endurance` 场景与对应 frame/memory 阈值。
  - `run_quality_baseline.gd` 新增 `boss_pressure_endurance` setup（boss 房高压长时采样）。
  - `validate_configs.py` 与 `test_quality_baseline_targets.gd` 已同步新增场景键与 setup 合法值护栏。
  - CI `godot-headless-and-gut` 已改为 `ubuntu-latest + windows-latest` 双平台矩阵。
  - 校验：`validate_configs`、`check_resources`、baseline snapshot、全量 GUT 与 headless 启动均通过。
- D16（发布阈值演练与兼容发布门）已完成：
  - 新增 `release_gate_targets.json`，定义发布通道、告警上限、必备场景、动作绑定与 CI 平台标记。
  - 新增 `scripts/tools/run_release_gate.gd`，读取 baseline 报告与 CI 工作流，输出 `release_gate_latest.json/.md` 发布门演练结果。
  - `validate_configs.py`、`check_resources.py` 与 `test_release_gate_targets.gd` 已补齐 schema/资源/回归护栏。
  - CI 已新增 `Run release gate rehearsal` 步骤，接在 baseline snapshot 后执行。
  - 校验：`validate_configs`、`check_resources`、baseline snapshot、release gate rehearsal、全量 GUT 与 headless 启动均通过。
- D17（实机兼容回归演练与阈值收敛）已完成：
  - 新增 `compatibility_rehearsal_targets.json`，定义 profile 级分辨率/输入/场景 smoke 与阈值阻断规则。
  - 新增 `scripts/tools/run_compatibility_rehearsal.gd`，在 release gate 报告基础上执行 profile 级兼容演练并输出报告。
  - `validate_configs.py`、`check_resources.py` 与 `test_compatibility_rehearsal_targets.gd` 已补齐 schema/资源/回归护栏。
  - CI 已新增 `Run compatibility rehearsal` 步骤，接在 release gate rehearsal 后执行。
  - 校验：`validate_configs`、`check_resources`、baseline snapshot、release gate rehearsal、compatibility rehearsal、全量 GUT 与 headless 启动均通过。
- D18（内容深度三轮扩容）已完成：
  - `characters.json` 扩容到 12（新增 `char_arbiter`、`char_oracle`）。
  - `evolutions.json` 扩容到 13（新增 `evo_vowstorm`、`evo_nether_maelstrom`、`evo_astral_horizon`）。
  - `shop_items.json` 扩容到 passive 14 / weapon 15，并同步 chapter_3/chapter_4 override。
  - `narrative_content.json` 记忆碎片扩容到 22。
  - `game_world.gd` 已补齐新增商店条目消费；`test_content_depth_targets.gd` 阈值抬升；`test_core_flow_regression.gd` 新增 D18 武器购买回归。
  - 校验：`validate_configs`、`check_resources`、baseline snapshot、release gate rehearsal、compatibility rehearsal、全量 GUT 与 headless 启动均通过。
- D19（资源目录族映射扩展）已完成：
  - 新增 `scripts/tools/sync_resource_stubs.py`，可按 balance 配置自动同步 8 类目录 `.tres` stub。
  - 新增 `resources/resource_catalog.json`（`stub_catalog_v2`），记录资源 `id/path/source_json` 映射。
  - `check_resources.py` 与 `test_resource_directory_baseline.gd` 已升级为 catalog 驱动校验与覆盖断言。
  - 资源目录从“每类样例 1 个”提升为“按内容 ID 批量映射基线”。
  - 校验：`validate_configs`、`check_resources`、baseline snapshot、release gate rehearsal、compatibility rehearsal、全量 GUT 与 headless 启动均通过。
- D20（资源目录族材质参数资产化）已完成：
  - `sync_resource_stubs.py` 与 `resource_catalog.json` 升级到 `stub_catalog_v3`，新增 `display_name/material_profile/asset_state`。
  - 新增 `resources/material_profiles/` 8 类材质参数资源，并在 8 类目录 stub 中完成引用接入。
  - `check_resources.py` 与 `test_resource_directory_baseline.gd` 已补齐 v3 结构/字段/路径一致性护栏。
  - 校验：`sync_resource_stubs`、`validate_configs`、`check_resources`、baseline snapshot、release gate rehearsal、compatibility rehearsal、全量 GUT 与 headless 启动均通过。
- D21（首批实料资产验收与生产态标记）已完成：
  - 新增 `resource_acceptance_targets.json`，定义首批 production-ready 资源 ID、场景映射、预览贴图映射与验收阈值。
  - `sync_resource_stubs.py` 与 `resource_catalog.json` 升级到 `stub_catalog_v4`，新增 `preview_texture/acceptance_scene/acceptance_profile`，并支持按目标 ID 标记 `production_ready`。
  - 新增 `run_resource_acceptance.gd`，输出 `user://resource_acceptance_latest.json/.md`，执行 production-ready 列表、预览贴图、验收场景实例化校验。
  - `validate_configs.py`、`check_resources.py`、`test_resource_directory_baseline.gd`、`test_resource_acceptance_targets.gd` 已接入 v4 护栏与验收目标回归。
  - CI 已新增 `Run resource acceptance rehearsal` 步骤，接在 compatibility rehearsal 后执行。
  - 校验：`sync_resource_stubs`、`validate_configs`（17 JSON）、`check_resources`、baseline snapshot、release gate rehearsal、compatibility rehearsal、resource acceptance rehearsal、全量 GUT 与 headless 启动均通过。
- D22（production_ready 比例扩容与跨场景验收加深）已完成：
  - `resource_acceptance_targets.json` 从 `batch_1` 升级为 `batch_2`，扩充 8 类 `required_production_ready_ids` 并新增 `acceptance_scene_matrix`（每类 >=2 场景 smoke）。
  - `validate_configs.py` 新增 `acceptance_scene_matrix` + `min_ready_ratio_per_category` + `min_scene_smokes_per_category` 校验。
  - `run_resource_acceptance.gd` 新增 `category_ready` 与 `scene_smokes` 报告段，并按“ready 数量/比例 + 场景 smoke 深度”执行阻断判定。
  - `test_resource_acceptance_targets.gd` 升级为 D22 护栏：校验场景矩阵与 ready 下限/比例。
  - `sync_resource_stubs.py` 刷新后，catalog v4 `production_ready_counts` 提升到：`6/7/7/2/8/5/3/5`（characters/weapons/passives/accessories/enemies/evolutions/meta/forge）。
  - 校验：`sync_resource_stubs`、`validate_configs`（17 JSON）、`check_resources`、baseline snapshot、release gate rehearsal、compatibility rehearsal、resource acceptance rehearsal、全量 GUT 与 headless 启动均通过。
- D23（acceptance_profile 分层语义与验收报告分层）已完成：
  - `resource_acceptance_targets.json` 从 `batch_2` 升级为 `batch_3`，新增 `acceptance_profile_policy` 与 `max_profile_mismatches` 阈值，`required_fields` 新增 `acceptance_tier`。
  - `sync_resource_stubs.py` 与 `resource_catalog.json` 升级为 `stub_catalog_v5`，新增 `acceptance_tier` 与 `acceptance_tier_counts`，并改为按 `category_profile_map + asset_state` 生成 profile/tier。
  - `run_resource_acceptance.gd` 新增 profile 分层报告（`profile_layers`、`profile_mismatches`）与 profile-policy 一致性阻断。
  - `validate_configs.py`、`check_resources.py`、`test_resource_acceptance_targets.gd`、`test_resource_directory_baseline.gd` 已补齐 D23 schema/结构/语义护栏。
  - 校验：`sync_resource_stubs`、`validate_configs`（17 JSON）、`check_resources`、baseline snapshot、release gate rehearsal、compatibility rehearsal、resource acceptance rehearsal、全量 GUT 与 headless 启动均通过。
- D24（production_ready 覆盖扩容与分层趋势基线）已完成：
  - `resource_acceptance_targets.json` 升级为 `batch_4`，扩充 8 类 `required_production_ready_ids`，并将阈值抬升到 `min_ready_per_category=3`、`min_ready_ratio_per_category=0.5`。
  - 新增 `trend_baseline` 与 `max_trend_regressions`，引入 bucket 级 ready ratio 基线和 category/bucket ratio drop 趋势限制。
  - `sync_resource_stubs.py` 与 `resource_catalog.json` 升级为 `stub_catalog_v6`，新增 `acceptance_bucket_counts`，形成按 `report_bucket` 的 entries/ready_entries 汇总。
  - `run_resource_acceptance.gd` 新增 `profile_buckets` 与 `trend` 报告段，支持 previous report 轮转、warning 级趋势告警和 trend regression 阻断。
  - `validate_configs.py`、`check_resources.py`、`test_resource_acceptance_targets.gd`、`test_resource_directory_baseline.gd` 已补齐 D24 schema/结构/语义护栏。
  - CI 新增 `Run resource acceptance trend gate`（二次执行 resource acceptance），确保趋势基线路径可回归。
   - 校验：`sync_resource_stubs`、`validate_configs`（17 JSON）、`check_resources`、baseline snapshot、release gate rehearsal、compatibility rehearsal、resource acceptance rehearsal + trend gate、全量 GUT 与 headless 启动均通过。
- D25（实料资产替换批次扩展与场景可视验收）已完成：
  - `resource_acceptance_targets.json` 升级到 `batch_5`，8 类 `required_production_ready_ids` 扩容，阈值抬升到 `min_ready_per_category=4`、`min_ready_ratio_per_category=0.7`、`min_scene_smokes_per_category=3`。
  - 新增 `scene_visual_requirements`（每类 3 条节点/属性可视检查）与 `max_visual_failures=0`，将“场景内真实可视验收”接入自动阻断。
  - `sync_resource_stubs.py` 与 `resource_catalog.json` 升级为 `stub_catalog_v7`，新增 `scene_visual_requirements` 与 `scene_visual_requirement_counts`。
  - `run_resource_acceptance.gd` 新增 `visual_checks/visual_failures` 报告段，支持可视规则（exists/non_null/non_empty_string/array_non_empty/float_gt_zero）与 visual gate 阻断。
  - `validate_configs.py`、`check_resources.py`、`test_resource_acceptance_targets.gd`、`test_resource_directory_baseline.gd` 已补齐 D25 护栏。
  - CI 已将 resource acceptance 明确为 scene-visual rehearsal，并保留 trend+visual gate 第二次执行。
  - 校验：`sync_resource_stubs`、`validate_configs`（17 JSON）、`check_resources`、baseline snapshot、release gate rehearsal、compatibility rehearsal、resource acceptance rehearsal + trend+visual gate、全量 GUT 与 headless 启动均通过。
- D26（production_ready 近全量覆盖与可视验收加压）已完成：
  - `resource_acceptance_targets.json` 升级到 `batch_6`，8 类 `required_production_ready_ids` 全量覆盖，并将阈值抬升到 `min_ready_per_category=4`、`min_ready_ratio_per_category=0.95`、`min_scene_smokes_per_category=4`、`min_visual_checks_per_category=4`。
  - `scene_visual_requirements` 每类提升为 4 条，新增 `bool_true` 规则用于可见性断言；`acceptance_scene_matrix` 每类提升到 4 场景 smoke。
  - `sync_resource_stubs.py` 与 `resource_catalog.json` 升级为 `stub_catalog_v8`，新增 `production_ready_ratio_by_category` 并保持 visual-count 对齐。
  - `run_resource_acceptance.gd` 新增 `bool_true` 执行与 `production_ready_ratio_by_category` 一致性阻断。
  - `validate_configs.py`、`check_resources.py`、`test_resource_acceptance_targets.gd`、`test_resource_directory_baseline.gd` 已补齐 D26 护栏（v8 + bool_true + ratio-by-category）。
  - 校验：`sync_resource_stubs`、`validate_configs`（17 JSON）、`check_resources`、baseline snapshot、release gate rehearsal、compatibility rehearsal、resource acceptance rehearsal + trend+visual gate、全量 GUT（`15/50/5179/0`）与 headless 启动均通过。
- D27（章节级可视快照对比基线与实机截图回归链路）已完成：
  - 新增 `visual_snapshot_targets.json`（`chapter_snapshot_v1`），覆盖 chapter_1~4 世界场景与主菜单 UI 的快照目标与指标阈值。
  - 新增 `run_visual_snapshot_regression.gd`，生成 `user://visual_snapshot_latest.json/.md` 并轮转 `user://visual_snapshot_previous.json` 进行趋势对比。
  - `validate_configs.py`、`check_resources.py`、`test_visual_snapshot_targets.gd` 已补齐 D27 schema/路径/阈值护栏。
  - CI 新增 `Run visual snapshot regression rehearsal` 与 `Run visual snapshot regression trend gate` 两步。
  - 校验：`validate_configs`（18 JSON）、`check_resources`、baseline/release/compatibility/resource acceptance x2/visual snapshot x2、全量 GUT（`16/52/5276/0`）与 headless 启动均通过。
- D28（可视快照精度收敛与后端差异治理）已完成：
  - `visual_snapshot_targets.json` 升级为 `chapter_snapshot_v2`，新增 `precision`（多轮采样 stddev 护栏）与 `backend_profiles`（default/linux/windows 后端差异阈值配置），并收紧趋势阈值。
  - `run_visual_snapshot_regression.gd` 新增多轮采样聚合、精度收敛 gate、后端 profile 阈值应用与 `backend_tag` 报告段。
  - `validate_configs.py`、`check_resources.py`、`test_visual_snapshot_targets.gd` 已补齐 D28 schema/结构/阈值护栏。
  - CI 可视快照两步新增 `VISUAL_SNAPSHOT_BACKEND_TAG` 注入（linux/windows），保障跨平台后端差异路径可回归。
  - 校验：`validate_configs`（18 JSON）、`check_resources`、baseline/release/compatibility/resource acceptance x2/visual snapshot x2、全量 GUT（`16/52/5325/0`）与 headless 启动均通过。
- D29（实机截图基线对齐与章节级视觉差异白名单治理）已完成：
  - `visual_snapshot_targets.json` 升级为 `chapter_snapshot_v3`，新增 `baseline_alignment`（required snapshots + backend capture modes）与 `diff_whitelist` / `whitelist_policy`。
  - `run_visual_snapshot_regression.gd` 新增白名单差异治理：按 backend+snapshot 解析 whitelist 阈值，命中项降级 warning，并受 `max_hits` / `max_ratio` 阈值二次约束。
  - `validate_configs.py`、`check_resources.py`、`test_visual_snapshot_targets.gd` 已补齐 D29 schema/结构/阈值护栏（v3 channel、baseline alignment、diff whitelist、whitelist policy）。
  - CI 沿用 visual snapshot rehearsal + trend gate 双步，并通过 `VISUAL_SNAPSHOT_BACKEND_TAG` 覆盖 linux/windows 后端差异路径。
  - 校验：`validate_configs`（18 JSON）、`check_resources`、baseline/release/compatibility/resource acceptance x2/visual snapshot x2、全量 GUT（`16/52/5366/0`）与 headless 启动均通过。
- D30-1（JSON 语法快速失败闸门）已完成：
  - 新增 `scripts/tools/check_json_syntax.py`，对 `data/balance/*.json`、`resources/resource_catalog.json`、`assets/sprites/tiles/atlas_manifest.json` 做严格语法 parse。
  - 报错输出统一 `file:line:column`，用于快速定位解析失败点。
  - CI 的 `validate-config-and-resources` 已前置 `JSON syntax gate`，实现语法层快速失败。
  - `scripts/check_resources.py` 已将该闸门脚本纳入必需文件护栏。
  - 校验：`check_json_syntax`、`validate_configs`（18 JSON）、`check_resources`、baseline/release/compatibility/resource acceptance x2/visual snapshot x2、全量 GUT（`16/52/5366/0`）与 headless 启动均通过。
- D30-2（章节可视基线跨版本对比与回归报告分层收敛）已完成：
  - `visual_snapshot_targets.json` 升级为 `chapter_snapshot_v4`，新增 `report_layers`（world/ui）与 `cross_version_baseline`（v1/v2/v3 参考通道 + 漂移阈值 + 参考指标映射）。
  - `run_visual_snapshot_regression.gd` 新增跨版本漂移评估与分层收敛评估，并在报告中输出 `cross_version` 与 `layers` 分段。
  - `validate_configs.py`、`check_resources.py`、`test_visual_snapshot_targets.gd` 已补齐 D30-2 schema/结构/阈值护栏（v4 channel + report layers + cross-version baseline）。
  - 可视快照基线已按当前 headless 指标重对齐，visual snapshot rehearsal + trend gate 双步回归全绿。
  - 校验：`check_json_syntax`、`validate_configs`（18 JSON）、`check_resources`、baseline/release/compatibility/resource acceptance x2/visual snapshot x2、全量 GUT（`16/52/5543/0`）与 headless 启动均通过。
- D30-3（跨后端可视差异归因与白名单收敛自动化）已完成：
  - `visual_snapshot_targets.json` 升级为 `chapter_snapshot_v5`，新增 `backend_attribution` 与 `whitelist_convergence` 策略块。
  - `run_visual_snapshot_regression.gd` 新增后端差异归因统计/阻断与白名单收敛建议自动化，报告补充归因与收敛分段。
  - `validate_configs.py`、`check_resources.py`、`test_visual_snapshot_targets.gd` 已补齐 D30-3 schema/结构/阈值护栏（v5 channel + backend attribution + whitelist convergence）。
  - 校验：`check_json_syntax`、`validate_configs`（18 JSON）、`check_resources`、baseline/release/compatibility/resource acceptance x2/visual snapshot x2、全量 GUT（`16/52/5554/0`）与 headless 启动均通过。
- D30-4（可视回归例外生命周期治理与自动回收策略）已完成：
  - `visual_snapshot_targets.json` 升级为 `chapter_snapshot_v6`，新增 `exception_lifecycle`（`expire_idle_runs`、`auto_reclaim_hit_streak`、`max_expired_entries`、`max_reclaim_candidates`）。
  - `run_visual_snapshot_regression.gd` 新增 whitelist 例外生命周期治理（规则老化过期 + 自动回收候选）与对应阻断上限。
  - `validate_configs.py`、`check_resources.py`、`test_visual_snapshot_targets.gd` 已补齐 D30-4 schema/结构/阈值护栏（v6 channel + exception lifecycle）。
  - 校验：`check_json_syntax`、`validate_configs`（18 JSON）、`check_resources`、baseline/release/compatibility/resource acceptance x2/visual snapshot x2、全量 GUT（`16/52/5559/0`）与 headless 启动均通过。
- D31（可视回归策略编排与发布级收敛模板化）已完成：
  - `visual_snapshot_targets.json` 升级为 `chapter_snapshot_v7`，新增 `strategy_orchestration`（`default_strategy` + `strategies` + `templates`）。
  - `run_visual_snapshot_regression.gd` 新增策略模板解析与策略生效阈值合并，报告输出 `strategy` 元数据并对策略配置错误执行阻断。
  - `validate_configs.py`、`check_resources.py`、`test_visual_snapshot_targets.gd` 已补齐 D31 schema/结构/引用完整性护栏（v7 channel + strategy orchestration）。
  - CI visual snapshot 两步注入 `VISUAL_SNAPSHOT_STRATEGY`：rehearsal=`ci_rehearsal`，trend gate=`ci_trend_gate`。
  - 校验：`check_json_syntax`、`validate_configs`（18 JSON）、`check_resources`、baseline/release/compatibility/resource acceptance x2/visual snapshot x2（策略编排）、全量 GUT（`16/52/5640/0`）与 headless 启动均通过。
- D32（可视回归策略发布清单与门禁模板固化）已完成：
  - `visual_snapshot_targets.json` 升级为 `chapter_snapshot_v8`，新增 `release_gate_templates`（required strategy bindings + ci mode bindings + release checklist）。
  - `run_visual_snapshot_regression.gd` 新增 `release_manifest` 评估与发布清单校验（模板绑定一致性、CI run_mode 绑定、required reports、publish strategy checklist）。
  - `validate_configs.py`、`check_resources.py`、`test_visual_snapshot_targets.gd` 已补齐 D32 schema/结构/引用完整性护栏（v8 channel + release gate templates）。
  - CI visual snapshot 链路新增 `VISUAL_SNAPSHOT_RUN_MODE`，并补充 release 模板 dry-run（`release_candidate` / `release_blocking`）。
  - 校验：`check_json_syntax`、`validate_configs`（18 JSON）、`check_resources`、baseline/release/compatibility/resource acceptance x2/visual snapshot x4（含 release 模板 dry-run）、全量 GUT（`16/52/5675/0`）与 headless 启动均通过。
- D33（跨后端矩阵治理与审批流程固化）已完成：
  - `visual_snapshot_targets.json` 升级为 `chapter_snapshot_v9`，新增 `backend_matrix_governance` 与 `approval_workflow`。
  - `run_visual_snapshot_regression.gd` 新增 backend matrix 覆盖评估与 approval workflow 审批约束，报告新增 `Backend Matrix Governance`/`Approval Workflow` 分段。
  - `validate_configs.py`、`check_resources.py`、`test_visual_snapshot_targets.gd` 已补齐 D33 护栏；CI visual snapshot 四步已注入 `VISUAL_SNAPSHOT_BACKEND_MATRIX`。
  - 校验：`check_json_syntax`、`validate_configs`（18 JSON）、`check_resources`、baseline/release/compatibility/resource acceptance x2/visual snapshot x4、全量 GUT（`16/52/5699/0`）与 headless 启动均通过。
- D34（审批记录持久化与跨流水线历史追溯）已完成：
  - `visual_snapshot_targets.json` 升级为 `chapter_snapshot_v10`，新增 `approval_audit_trail`（history file/max entries/required run modes+backends/pipeline-id uniqueness/trace failure bounds）。
  - `run_visual_snapshot_regression.gd` 新增审批历史持久化与追溯校验，报告新增 `Approval Audit Trail` 分段；`release_blocking` 模式执行阻断，其他模式输出追溯 warning 供收敛。
  - `validate_configs.py`、`check_resources.py`、`test_visual_snapshot_targets.gd` 已补齐 D34 护栏（v10 channel + approval_audit_trail + report section 对齐）。
  - CI visual snapshot 四步新增 `VISUAL_PIPELINE_ID`，并携带 backend matrix + strategy + run_mode 构成可追溯上下文。
  - 校验：`check_json_syntax`、`validate_configs`（18 JSON）、`check_resources`、baseline/release/compatibility/resource acceptance x2/visual snapshot x4（release_blocking: blockers 0 / warnings 0）全量 GUT（`16/52/5716/0`）与 headless 启动均通过。
- D35（审批历史聚合与跨后端长期趋势归档）已完成：
  - `visual_snapshot_targets.json` 升级为 `chapter_snapshot_v11`，新增 `approval_history_archive`（archive file/max entries/aggregation window/required run modes+backends/backend delta bounds/archive trace failure bounds）。
  - `run_visual_snapshot_regression.gd` 新增审批历史归档聚合评估（`approval_archive`）：滚动窗口聚合 run_mode/backend 覆盖与跨后端 warning/blocker delta，并按模式执行门禁（non-release warning / release-blocking hard gate）。
  - `validate_configs.py`、`check_resources.py`、`test_visual_snapshot_targets.gd` 已补齐 D35 护栏（v11 channel + approval_history_archive + release/backend matrix 关联约束）。
  - 校验：`check_json_syntax`、`validate_configs`（18 JSON）、`check_resources`、baseline/release/compatibility/resource acceptance x2/visual snapshot x4（前 3 模式 warnings 1；release_blocking: blockers 0 / warnings 0）、全量 GUT（`16/52/5739/0`）与 headless 启动均通过。
- D36（审批历史分层阈值模板与发布候选追踪报告）已完成：
  - `visual_snapshot_targets.json` 升级为 `chapter_snapshot_v12`，新增 `approval_threshold_templates`（按 run_mode 的审批阈值模板）与 `release_candidate_tracking`（窗口聚合 + 候选稳定性阈值）。
  - `run_visual_snapshot_regression.gd` 新增模板化审批阈值生效与 `Release Candidate Tracking` 评估分段，支持按模式输出收敛告警并在 `release_blocking` 执行严格阻断。
  - `validate_configs.py`、`check_resources.py`、`test_visual_snapshot_targets.gd` 已补齐 D36 护栏（v12 channel + template/tracking schema + manifest/strategy 关联约束）。
  - 校验：`check_json_syntax`、`validate_configs`（18 JSON）、`check_resources`、baseline/release/compatibility/resource acceptance x2/visual snapshot x4（前 3 模式 warnings；release_blocking: blockers 0 / warnings 0）、全量 GUT（`16/52/5801/0`）与 headless 启动均通过。
- D37（发布候选稳定性分层评分与审批收敛看板）已完成：
  - `visual_snapshot_targets.json` 升级为 `chapter_snapshot_v13`，新增 `stability_scoring`、`stability_tiers`、`convergence_dashboard`、`ci_signal_contract`，并扩展 `approval_workflow.required_report_sections` 到 D37 三段。
  - `run_visual_snapshot_regression.gd` 新增 D37 sanitize/evaluate 链路与 tier 解析能力，输出 `Stability Scoring` / `Convergence Dashboard` / `CI Signal Contract` 报告分段和结构化 CI 信号。
  - `validate_configs.py`、`check_resources.py`、`test_visual_snapshot_targets.gd` 已补齐 D37 护栏（v13 channel + D37 schema + report section 对齐 + 与 ci_mode_bindings/tier names 关联约束）。
  - 校验：`check_json_syntax`、`validate_configs`（18 JSON）、`check_resources` 通过；unit GUT 待执行（当前环境无 `godot` 命令）。
- D38（收敛趋势强化与异常生命周期联动治理）已完成：
  - `visual_snapshot_targets.json` 升级为 `chapter_snapshot_v14`，新增 `convergence_trend_reinforcement`、`exception_lifecycle_linkage`，并扩展 `approval_workflow.required_report_sections` 到 D38 两段。
  - `run_visual_snapshot_regression.gd` 新增 D38 sanitize/evaluate 链路、历史窗口指标统计与联动治理评估，报告输出 `Convergence Trend Reinforcement` / `Exception Lifecycle Linkage` 分段。
  - `approval_history_archive` 归档记录补入 D37 关键指标（`tracking_failures` / `dashboard_failures` / `contract_failures` / `stability_score` / `stability_tier`）以支持趋势强化。
  - `validate_configs.py`、`check_resources.py`、`test_visual_snapshot_targets.gd` 已补齐 D38 护栏（v14 channel + trend/linkage schema + history/ci/tier/exception lifecycle 关联约束）。
  - 校验：`check_json_syntax`、`validate_configs`（18 JSON）、`check_resources`、`py_compile` 通过；unit GUT 待执行（当前环境无 `godot` 命令）。
- D39（视觉门禁与性能基线联评）已完成：
  - `visual_snapshot_targets.json` 升级为 `chapter_snapshot_v15`，新增 `visual_performance_cogate`，并扩展 `approval_workflow.required_report_sections` 到 D39 分段。
  - `run_visual_snapshot_regression.gd` 新增 D39 sanitize/evaluate 链路（co-gate 评估），联评 `quality_baseline_latest.json` 的 alerts 与场景 frame/memory 比例阈值，报告新增 `Visual-Performance Co-Gate` 分段。
  - `approval_history_archive` 归档记录新增 D39 联评指标（`performance_cogate_failures` / `performance_scenario_failures` / `performance_alert_total` / `performance_alert_critical` / `performance_alert_warning`）。
  - `validate_configs.py`、`check_resources.py`、`test_visual_snapshot_targets.gd` 已补齐 D39 护栏（v15 channel + co-gate schema + baseline report/ci_mode_bindings/release checklist 关联约束）。
  - 校验：`check_json_syntax`、`validate_configs`（18 JSON）、`check_resources`、`py_compile` 通过；unit GUT 待执行（当前环境无 `godot` 命令）。
- D40（联评阈值模板化与跨平台对齐治理）已完成：
  - `visual_snapshot_targets.json` 升级为 `chapter_snapshot_v16`，新增 `cogate_threshold_templates` 与 `cross_platform_alignment`，并扩展 `approval_workflow.required_report_sections` 到 D40 分段。
  - `run_visual_snapshot_regression.gd` 新增 D40 sanitize/evaluate 链路：co-gate 阈值模板解析 + 跨平台窗口对齐评估；报告新增 `Co-Gate Threshold Template` / `Cross-Platform Alignment` 分段。
  - D39 co-gate 评估改为消费模板化阈值，`approval_history_archive` 的 performance 归档字段继续作为跨平台对齐聚合输入。
  - `validate_configs.py`、`check_resources.py`、`test_visual_snapshot_targets.gd` 已补齐 D40 护栏（v16 channel + 模板/对齐 schema + ci_mode_bindings/archive/section 一致性约束）。
  - 校验：`check_json_syntax`、`validate_configs`（18 JSON）、`check_resources`、`py_compile` 通过；unit GUT 待执行（当前环境无 `godot` 命令）。
- D41（高压场景性能压测标准化与对齐看板细化）已完成：
  - `visual_snapshot_targets.json` 升级为 `chapter_snapshot_v17`，新增 `pressure_scenario_standardization` 与 `alignment_dashboard_refinement`，并扩展 `approval_workflow.required_report_sections` 到 D41 分段。
  - `run_visual_snapshot_regression.gd` 新增 D41 sanitize/evaluate 链路：高压场景标准化校验 + 对齐看板加权评分；报告新增 `Pressure Scenario Standardization` / `Alignment Dashboard Refinement` 分段。
  - `validate_configs.py`、`check_resources.py`、`test_visual_snapshot_targets.gd` 已补齐 D41 护栏（v17 channel + D41 两块 schema + baseline/report/checklist/ci_mode_bindings/alignment metric 关联约束）。
  - 校验：`check_json_syntax`、`validate_configs`（18 JSON）、`check_resources`、`py_compile` 通过；unit GUT 待执行（当前环境无 `godot` 命令）。
- D42（高压场景对齐收敛门禁与回归周期开窗治理）已完成：
  - `visual_snapshot_targets.json` 升级为 `chapter_snapshot_v18`，新增 `pressure_alignment_convergence_gate` 与 `regression_cycle_window_governance`，并扩展 `approval_workflow.required_report_sections` 到 D42 分段。
  - `run_visual_snapshot_regression.gd` 新增 D42 sanitize/evaluate 链路：收敛门禁汇总（standardization/alignment/dashboard/critical）+ archive 周期窗口漂移治理（warning/blocker/alignment score delta）。报告新增 `Pressure Alignment Convergence Gate` / `Regression Cycle Window Governance` 分段。
  - `validate_configs.py`、`check_resources.py`、`test_visual_snapshot_targets.gd` 已补齐 D42 护栏（v18 channel + D42 两块 schema + run_mode/backend/archive/section 关联约束）。
  - 校验：`check_json_syntax`、`validate_configs`（18 JSON）、`check_resources`、`py_compile` 通过；unit GUT 待执行（当前环境无 `godot` 命令）。
- 下一步：进入 D43（多周期自适应门禁与发布回灌治理）。

## 执行约束

- 每个子阶段必须包含：代码改动 + 校验命令 + 文档同步。
- 每次落地后同步更新：
  - `spec-design/truth-check-2026-03-20.md`
  - `spec-design/development-plan-2026-03-20.md`
  - `spec-design/README.md`
