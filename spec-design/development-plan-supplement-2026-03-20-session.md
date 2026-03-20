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
- 下一步：进入 P2 后续项（正式手绘资源迭代与材质/特效精修）。

## 执行约束

- 每个子阶段必须包含：代码改动 + 校验命令 + 文档同步。
- 每次落地后同步更新：
  - `spec-design/truth-check-2026-03-20.md`
  - `spec-design/development-plan-2026-03-20.md`
  - `spec-design/README.md`
