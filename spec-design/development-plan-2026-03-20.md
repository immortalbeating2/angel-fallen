# 落地开发计划（2026-03-20）

## 目标

- 将“系统已实现但内容偏薄”的状态，推进为“可持续扩容且可验证回归”的开发节奏。
- 以最小风险先完成数据层扩容，再补测试护栏，最后推进表现层升级。
- 本计划与 `session-(angel-fallen)-20260320.md` 对齐，按“已完成/待补齐”持续滚动。

## 分阶段计划

## 阶段 A：文档对齐与基线固化（D1）

- 输出真值核对文档，明确 `已确认 / 部分实现 / 尚未体现`。
- 将核对结果纳入 `spec-design/README.md` 索引，作为后续推进基线。
- 验收标准：团队成员可通过单一入口快速获得“文档承诺与仓库现状差距”全貌。

状态：已完成

## 阶段 B：内容深度扩容（D1-D4）

- 扩容角色配置：从 3 提升至 6，补齐不同解锁路径与武器画像。
- 扩容进化配置：从 1 提升至 4，覆盖多武器 ID 的演进分支。
- 扩容商店池：增加 passive/weapon 可抽取条目，并同步章节池覆盖。
- 同步游戏逻辑：为新增商店条目补齐说明文本与效果处理分支，避免“未知效果”。
- 增加内容深度回归测试：新增最小门槛测试，防止配置回退到低深度状态。
- 验收标准：
  - `characters >= 6`
  - `evolutions >= 4`
  - `shop passive pool >= 5`
  - `shop weapon pool >= 5`
  - JSON 校验脚本通过

状态：已执行并完成首轮落地

## 阶段 C：集成回归补强（D5-D8）

- C1 宝藏房挑战模式（优先）
  - 将宝藏房从“进房即发奖”升级为“精英小波次后发奖”。
  - 挑战参数外置到 `data/balance/map_generation.json`（击杀门槛、奖励缩放、饰品概率等）。
  - 在 `scripts/game/game_world.gd` 接入运行时读取与结算流程。
  - 在 `scripts/validate_configs.py`、`test/unit/test_map_generation_config.gd` 增加配置/不变量校验。
- C2 关键流程集成回归
  - 角色选择 -> 开局 -> 房间推进 -> 结算落盘。
  - 升级触发进化关键路径。
  - 商店购买与资源变化闭环。
- 验收标准：
  - 宝藏房挑战流程可配置、可回归、可稳定结算。
  - 关键状态流转有测试覆盖，且无明显回归。

状态：已完成（C1 + C2）

## 阶段 D：表现层升级（D9-D14）

- 将主玩法场景逐步迁移为 TileMap/tileset 驱动（先替换底层地表与门区块，再替换危害可视层）。
- 在不破坏现有系统接口的前提下完成可视化升级。
- 验收标准：保持玩法行为一致，视觉层可替换且不影响核心回归用例。

状态：已完成（D9-D10：地表 + 门区块 + 危害可视层 TileMap 化）

## 本次推进记录（与本计划同步）

- 已创建：`spec-design/truth-check-2026-03-20.md`
- 已扩容：
  - `data/balance/characters.json`
  - `data/balance/evolutions.json`
  - `data/balance/shop_items.json`
- 已补逻辑：`scripts/game/game_world.gd`（新增商店条目说明与效果）
- 已补测试：`test/unit/test_content_depth_targets.gd`
- 已补 C1：
  - `data/balance/map_generation.json`（新增 `treasure_challenge` 参数段）
  - `scripts/game/game_world.gd`（宝藏房挑战流程：精英小波次后发奖）
  - `scripts/validate_configs.py`（新增 `treasure_challenge` 语义校验）
  - `test/unit/test_map_generation_config.gd`（新增 challenge 配置边界断言）
- 已补 C2：
  - `test/integration/test_core_flow_regression.gd`（新增 3 条关键流程集成回归）
  - `scripts/systems/level_up_system.gd`（修复进化路径中的动态属性读取解析问题）
  - `.github/workflows/ci.yml`（GUT 范围从 `test/unit` 扩展到 `test`）
- 已补 D（首轮）：
  - `scenes/game/game_world.tscn`（新增 `GroundTileMap`、`DoorTileMap` 可视层）
  - `scripts/game/game_world.gd`（运行时生成 tileset + 章节 palette 地表渲染 + 门状态 TileMap 联动）
  - `test/unit/test_visual_tilemap_layers.gd`（新增可视层节点与 tileset 存在性护栏）
- 已补 D（第二轮）：
  - `scenes/game/game_world.tscn`（新增 `HazardTileMap`，`HazardTint` 退为隐藏兼容层）
  - `scripts/game/game_world.gd`（危害 overlay 改为 TileMap 渲染与透明度联动，补齐挑战宝藏房 hazard 强度）
  - `test/unit/test_visual_tilemap_layers.gd`（新增 HazardTileMap 状态驱动回归）
- 已补 D（第三轮）：
  - `assets/sprites/tiles/*.png`（新增地表/门/危害 overlay 贴图 atlas）
  - `resources/tilesets/*.tres`（新增地表/门/危害 TileSet 资源）
  - `scripts/game/game_world.gd`（TileMap 从运行时程序化 tileset 切换为资源化 tileset 加载）
  - `scripts/tools/generate_visual_tiles.py`、`scripts/tools/build_tileset_resources.gd`（资源生成与构建工具）
  - `test/unit/test_visual_tilemap_layers.gd`（新增资源路径断言，确保使用 `resources/tilesets`）

## 基于 session 的过程复盘（增补）

依据 `session-(angel-fallen)-20260320.md`，在首轮落地后还完成了以下闭环：

- 工程化：新增 `.gitattributes`（LFS 规则）与 `.github/workflows/ci.yml`（Python 校验 + Godot headless + GUT）。
- 地图生成：补齐 treasure 房、坐标化 minimap（`map_x/map_y + map_bounds`）、每章房型上限/下限约束。
- 敌人系统：完成敌人对象池化链路（Spawner/Enemy/GameWorld 回收路径）与回归测试 `test/unit/test_enemy_pooling.gd`。
- 章节敌人映射：新增 `chapter_archetype_map`（配置 -> Spawner -> 校验 -> 测试 -> Codex/README 显示名）全链路。
- 多轮验证记录：`python scripts/validate_configs.py`、`python scripts/check_resources.py`、Godot headless、GUT 全绿（记录包含 `7 scripts / 22 tests / 768 asserts / 0 failures`）。

当前待补齐项：

- 持续优化项（非阻塞）：将当前临时生成 atlas 逐步替换为正式手绘美术资源，并按章节细化图块动画/特效层。

## 下一周期（内容优先，60/25/15）

- 配比：内容深度 60% / 质量基线 25% / 美术替换 15%。

### D1：冻结清单（已完成）

- 已输出并冻结：`spec-design/content-depth-cycle-1-d1-freeze-2026-03-20.md`
- 冻结内容：
  - 基线与目标阈值（角色/进化/商店池/记忆碎片）
  - 新增 ID 池（角色、武器、被动、进化、记忆）
  - D2/D3 文件范围与验收命令
- 结论：可直接进入 D2 数据层扩容落地。

### D2：数据层扩容（已完成）

- 已完成文件：
  - `data/balance/characters.json`
  - `data/balance/evolutions.json`
  - `data/balance/shop_items.json`
  - `data/balance/narrative_content.json`
- 已落地新增：
  - 角色：`char_templar`、`char_occultist`
  - 进化：`evo_seraph_lance`、`evo_abyssal_chain`、`evo_glacial_nova`
  - 商店池：新增 `pas_fortune`、`pas_resolve`、`pas_momentum` 与 `wpn_sacred_lance`、`wpn_void_chain`、`wpn_frost_orb`
  - 记忆碎片：新增 6 条 route 相关碎片
- 结果计数（D2 完成后）：
  - `characters = 8`
  - `evolutions = 7`
  - `shop passive pool = 8`
  - `shop weapon pool = 9`
  - `memory_fragments = 10`
- 结论：D2 目标达成，进入 D3（逻辑消费与测试阈值抬升）。

### D3：逻辑消费补齐与测试阈值抬升（已完成）

- 已完成文件：
  - `scripts/game/game_world.gd`
  - `test/unit/test_content_depth_targets.gd`
  - `test/integration/test_core_flow_regression.gd`
- 已落地：
  - 商店新增条目消费逻辑补齐：`pas_fortune`、`pas_resolve`、`pas_momentum`、`wpn_sacred_lance`、`wpn_void_chain`、`wpn_frost_orb`
  - 商店条目文本说明补齐，避免新增 ID 落入 `Unknown effect`
  - 内容深度阈值抬升并新增记忆碎片目标断言（`memory_fragments >= 10`）
  - 集成回归新增“下一周期新增被动消费”链路断言（`pas_momentum`）
- 验收结果：
  - `python scripts/validate_configs.py` 通过
  - `python scripts/check_resources.py` 通过
  - GUT 全量通过（`10 scripts / 32 tests / 1082 asserts / 0 failures`）
  - Godot headless 启动通过
- 结论：D3 目标达成，下一步进入 D4（质量基线：性能/兼容最小可重复采样）。

### D4：质量基线最小采样（已完成）

- 已完成文件：
  - `data/balance/quality_baseline_targets.json`
  - `scripts/tools/run_quality_baseline.gd`
  - `test/unit/test_quality_baseline_targets.gd`
  - `scripts/validate_configs.py`
  - `scripts/check_resources.py`
  - `.github/workflows/ci.yml`
- 已落地：
  - 新增质量基线目标配置（场景采样、帧时间阈值、内存阈值、兼容矩阵、必需输入动作）。
  - 新增 headless 可重复采样脚本，输出 `user://quality_baseline_latest.json/.md`。
  - 新增 schema 护栏测试，校验质量基线配置结构与 InputMap 必需动作存在性。
  - CI 在 GUT 后追加质量基线快照采样步骤。
- 验收结果：
  - `python scripts/validate_configs.py` 通过（14 JSON）
  - `python scripts/check_resources.py` 通过
  - GUT 全量通过（含新增质量基线测试）
  - Godot headless 启动通过
- 结论：D4 目标达成，下一步进入 P2（手绘 atlas 替换与章节差异化细化）。

### D5：质量基线分层压力与告警分级（已完成）

- 已完成文件：
  - `data/balance/quality_baseline_targets.json`
  - `scripts/tools/run_quality_baseline.gd`
  - `scripts/validate_configs.py`
  - `test/unit/test_quality_baseline_targets.gd`
- 已落地：
  - 将精英压力场景从单一档位扩展为 `medium/high/extreme` 三档。
  - 质量采样脚本新增压力档位配置执行（不同房间索引、敌人数上限与运行时倍率）。
  - baseline 报告告警升级为分级摘要（`critical/warning/info` + 明细项）。
  - 配置校验与单测同步覆盖新的场景键和 `alert_grading` 阈值结构。
- 验收结果：
  - `python scripts/validate_configs.py` 通过（14 JSON）
  - `python scripts/check_resources.py` 通过
  - quality baseline snapshot 脚本通过
  - GUT 全量通过
  - Godot headless 启动通过
- 结论：D5 目标达成，质量基线进入可分层采样与告警分级阶段；下一步回到 P2（手绘 atlas 替换与章节差异化细化）。

### D6：章节差异化 TileSet 细化（已完成）

- 已完成文件：
  - `scripts/tools/generate_visual_tiles.py`
  - `scripts/tools/build_tileset_resources.gd`
  - `assets/sprites/tiles/*.png`
  - `resources/tilesets/*.tres`
  - `scripts/game/game_world.gd`
  - `scripts/check_resources.py`
  - `test/unit/test_visual_tilemap_layers.gd`
- 已落地：
  - 新增章节差异化门与危害 atlas（`doors_ch1~ch4`、`hazard_overlay_ch1~ch4`）并保留兼容资源。
  - TileSet 构建脚本扩展为输出章节化门/危害 `.tres` 资源。
  - `game_world` 门层与危害层从单资源加载升级为按章节动态切换 tileset。
  - 视觉回归测试新增章节后缀断言（门/危害 tileset 与章节一致）。
  - 资源结构校验补齐章节化 atlas 与 tileset 文件护栏。
- 验收结果：
  - `python scripts/validate_configs.py` 通过（14 JSON）
  - `python scripts/check_resources.py` 通过
  - quality baseline snapshot 脚本通过
  - GUT 全量通过
  - Godot headless 启动通过
- 结论：P2 从“资源化接入”推进到“章节差异化可回归”，下一步聚焦正式手绘素材替换与动画细化。

### D7：危害图层动画细化（已完成）

- 已完成文件：
  - `data/balance/environment_config.json`
  - `scripts/game/game_world.gd`
  - `scripts/validate_configs.py`
  - `test/unit/test_visual_tilemap_layers.gd`
- 已落地：
  - 环境配置新增 `hazard_anim_interval`（chapter_1~chapter_4），支持章节化危害图层动画节奏。
  - `game_world` 危害层渲染新增动画状态缓存（cell phase + frame ticker），按章节间隔驱动 atlas 变体轮换。
  - 危害图层动画在保留现有强度 alpha 联动与 hazard 伤害逻辑的前提下实现可回归细化。
  - 校验脚本补充 `environment_config.hazard_anim_interval` 范围约束（`[0.08, 0.40]`）。
  - 可视层单测新增危害图层 atlas 坐标随动画推进而变化断言。
- 验收结果：
  - `python scripts/validate_configs.py` 通过（14 JSON）
  - `python scripts/check_resources.py` 通过
  - quality baseline snapshot 脚本通过
  - GUT 全量通过
  - Godot headless 启动通过
- 结论：P2 从“章节差异化资源切换”推进到“章节化动画节奏驱动”，下一步聚焦正式手绘素材替换与特效层细化。

### D8：章节地表细节层细化（已完成）

- 已完成文件：
  - `scenes/game/game_world.tscn`
  - `scripts/game/game_world.gd`
  - `scripts/tools/generate_visual_tiles.py`
  - `scripts/tools/build_tileset_resources.gd`
  - `scripts/check_resources.py`
  - `test/unit/test_visual_tilemap_layers.gd`
- 已落地：
  - 主场景新增 `GroundDetailTileMap`，作为地表与危害层之间的章节装饰层。
  - 资源生成工具新增 `ground_detail_ch1~ch4.png`，分别表现圣堂纹样、熔炉裂痕、冰霜符印、虚空铭文等章节差异化细节。
  - TileSet 构建链路新增 `game_world_ground_detail_ch1~ch4.tres`，并接入运行时按章节动态加载。
  - `game_world` 新增 `_render_ground_detail_tiles_for_room()`，按房间索引与章节生成稀疏装饰图块分布，保持现有 TileMap 接口不变。
  - 可视层单测扩展为校验 `GroundDetailTileMap` 存在性与章节后缀匹配，资源检查新增 detail atlas / tileset 护栏。
- 验收结果：
  - `python scripts/validate_configs.py` 通过（14 JSON）
  - `python scripts/check_resources.py` 通过
  - GUT 全量通过（`11 scripts / 36 tests / 1182 asserts / 0 failures`）
- 结论：P2 已从“章节化门/危害 + 动画”推进到“章节地表细节层落地”，下一步可继续替换临时 atlas 为正式手绘素材并叠加特效层表现。

### D9：章节环境特效层细化（已完成）

- 已完成文件：
  - `scenes/game/game_world.tscn`
  - `scripts/game/game_world.gd`
  - `data/balance/environment_config.json`
  - `scripts/validate_configs.py`
  - `scripts/tools/generate_visual_tiles.py`
  - `scripts/tools/build_tileset_resources.gd`
  - `scripts/check_resources.py`
  - `test/unit/test_visual_tilemap_layers.gd`
- 已落地：
  - 主场景新增 `AmbientFxTileMap`，形成地表/细节/危害/特效四层 TileMap 视觉结构。
  - 新增章节化特效 atlas `ambient_fx_ch1~ch4.png` 与对应 TileSet 资源 `game_world_ambient_fx_ch1~ch4.tres`。
  - `game_world` 新增章节化特效层资源加载、房间级铺设与 atlas 变体轮换动画（`_update_ambient_fx_animation`）。
  - 环境配置新增 `ambient_fx_interval`（chapter_1~chapter_4）并接入校验范围约束（`[0.12, 0.60]`）。
  - 可视层单测新增 AmbientFxTileMap 存在性、章节资源切换与动画推进断言。
- 验收结果：
  - `python scripts/validate_configs.py` 通过（14 JSON）
  - `python scripts/check_resources.py` 通过
  - quality baseline snapshot 脚本通过（alerts 0）
  - GUT 全量通过（`11 scripts / 37 tests / 1199 asserts / 0 failures`）
  - Godot headless 启动通过
- 结论：P2 已从“章节差异化资源 + 动画”推进到“章节化环境特效层可回归落地”，下一步可专注临时 atlas 的正式手绘替换与材质表现打磨。

### D10：章节视觉参数化细化（已完成）

- 已完成文件：
  - `data/balance/environment_config.json`
  - `scripts/game/game_world.gd`
  - `scripts/validate_configs.py`
  - `test/unit/test_visual_tilemap_layers.gd`
- 已落地：
  - 环境配置新增 `visual_profile`（`detail_tint/detail_alpha/hazard_alpha_mult/ambient_alpha_mult/ambient_scroll_speed_x/ambient_scroll_speed_y`）并按章节配置差异。
  - `game_world` 在环境视觉更新中接入章节视觉参数：地表细节层 tint+alpha、危害层 alpha 乘区、环境特效层 alpha 乘区与滚动偏移。
  - 视觉参数读取统一通过章节配置行解析，保持现有 TileMap 接口和房间流程不变。
  - `validate_configs.py` 补充 `visual_profile` 字段类型与范围校验，防止异常配置导致运行时视觉失真。
  - `test_visual_tilemap_layers` 新增章节视觉参数回归断言（章节 detail tint 差异 + ambient scroll 生效）。
- 验收结果：
  - `python scripts/validate_configs.py` 通过（14 JSON）
  - `python scripts/check_resources.py` 通过
  - quality baseline snapshot 脚本通过（alerts 0）
  - GUT 全量通过
  - Godot headless 启动通过
- 结论：P2 进入“资源章节化 + 动画 + 参数化材质表现”阶段，下一步可继续推进正式手绘 atlas 替换。

### D11：章节视觉脉冲细化（已完成）

- 已完成文件：
  - `data/balance/environment_config.json`
  - `scripts/game/game_world.gd`
  - `scripts/validate_configs.py`
  - `test/unit/test_visual_tilemap_layers.gd`
- 已落地：
  - `visual_profile` 新增 `detail_pulse_speed/detail_pulse_amplitude/ambient_wave_speed/ambient_wave_amplitude` 四个章节化动态参数。
  - `game_world` 在环境视觉更新中接入章节脉冲因子：细节层 alpha 叠加 pulse，环境特效层 alpha 叠加 wave，保持现有 TileMap 接口不变。
  - 新增 `_get_visual_profile_anim_factors(...)`，统一动态因子计算并用于运行时驱动与回归断言。
  - `validate_configs.py` 补充上述 4 个字段的类型与范围校验（speed `[0.0, 6.0]`，amplitude `[0.0, 0.25]`）。
  - `test_visual_tilemap_layers` 新增章节脉冲因子随时间变化断言，防止参数接入回退。
- 验收结果：
  - `python scripts/validate_configs.py` 通过（14 JSON）
  - `python scripts/check_resources.py` 通过
  - quality baseline snapshot 脚本通过（alerts 0）
  - GUT 全量通过
  - Godot headless 启动通过
- 结论：P2 从“章节视觉参数化”推进到“章节化动态节奏可回归控制”，下一步可继续推进正式手绘 atlas 替换与材质细节增强。

### D12：手绘 atlas 替换与材质细节增强（已完成）

- 已完成文件：
  - `scripts/tools/generate_visual_tiles.py`
  - `scripts/check_resources.py`
  - `test/unit/test_visual_tilemap_layers.gd`
  - `assets/sprites/tiles/*.png`
  - `assets/sprites/tiles/atlas_manifest.json`
  - `resources/tilesets/*.tres`
- 已落地：
  - atlas 生成脚本升级为 handdrawn 风格纹理：地表加入颗粒噪声/裂纹/纵向材质梯度，门区块加入面板层次与符纹细节，危害与环境特效层加入涡流/光晕与漂移细节。
  - 新增 `atlas_manifest.json`（`style=handdrawn_v1`）作为资源生成快照，记录各层 atlas 文件与变体数量。
  - 资源结构校验新增 manifest 解析与最小条目约束，防止 atlas 管线回退。
  - `test_visual_tilemap_layers` 新增 manifest 回归断言，保证手绘 atlas 标识与核心资源清单可回归验证。
- 验收结果：
  - `python scripts/validate_configs.py` 通过（14 JSON）
  - `python scripts/check_resources.py` 通过
  - quality baseline snapshot 脚本通过（alerts 0）
  - GUT 全量通过
  - Godot headless 启动通过
- 结论：P2 已从“章节化参数驱动”推进到“资源级手绘 atlas 管线 + manifest 护栏”，下一步可继续做正式手绘资源迭代与材质/特效精修。

## 后续执行原则

- 优先保证“可回归、可验证”的增量，不做大规模不可回溯重构。
- 每轮扩容后先跑配置校验，再推进下一层（测试 -> 表现）。
- 文档承诺与实现状态需持续同步更新，避免目标漂移。
- 每完成一个子阶段，必须同时更新：`spec-design/truth-check-2026-03-20.md`、本计划文档、`spec-design/README.md` 索引。
