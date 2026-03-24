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

### D13：内容深度二轮扩容（已完成）

- 已完成文件：
  - `data/balance/characters.json`
  - `data/balance/evolutions.json`
  - `data/balance/shop_items.json`
  - `data/balance/narrative_content.json`
  - `scripts/game/game_world.gd`
  - `test/unit/test_content_depth_targets.gd`
  - `test/integration/test_core_flow_regression.gd`
- 已落地：
  - 角色扩容到 10（新增 `char_sentinel`、`char_witchblade`），并保持角色 schema 与 unlock 规则一致。
  - 进化扩容到 10（新增 `evo_radiant_cataclysm`、`evo_tempest_onslaught`、`evo_blood_requiem`），`result_weapon_id` 唯一性保持。
  - 商店池扩容到 passive 11 / weapon 12（新增 `pas_overcharge/pas_bastion/pas_siphon` 与 `wpn_storm_bow/wpn_radiant_hammer/wpn_blood_rite`），并同步 chapter_3/chapter_4 override。
  - 记忆碎片扩容到 16（新增 6 条 route/event/meta 片段）。
  - 新增内容消费链路已接入：`game_world` 补齐新增商店条目文案与效果；集成测试新增 D13 武器购买闭环断言。
  - 深度阈值测试已抬升：`characters>=10`、`evolutions>=10`、`shop passive>=11`、`shop weapon>=12`、`memory_fragments>=16`。
- 验收结果：
  - `python scripts/validate_configs.py` 通过（14 JSON）
  - `python scripts/check_resources.py` 通过
  - quality baseline snapshot 脚本通过（alerts 0）
  - GUT 全量通过
  - Godot headless 启动通过
- 结论：内容深度从“首轮扩容”推进到“二轮可消费扩容”，下一步进入 D14（全量资源目录族最小可用落地与校验接入）。

### D14：资源目录族最小可用落地（已完成）

- 已完成文件：
  - `resources/characters/char_knight.tres`
  - `resources/weapons/wpn_holy_cross.tres`
  - `resources/passives/pas_might.tres`
  - `resources/accessories/acc_heart_of_mine.tres`
  - `resources/enemies/enemy_slime.tres`
  - `resources/evolutions/evo_arcane_comet.tres`
  - `resources/meta_upgrades/meta_max_hp.tres`
  - `resources/forge_recipes/forge_radiant_edge.tres`
  - `scripts/check_resources.py`
  - `test/unit/test_resource_directory_baseline.gd`
- 已落地：
  - 补齐文档口径中的 8 类资源目录族（characters/weapons/passives/accessories/enemies/evolutions/meta_upgrades/forge_recipes）并提供最小可用 `.tres` 基线资源。
  - `check_resources.py` 新增目录与资源文件护栏，并增加 stub 资源 `id/source_json` 结构与 `source_json` 目标存在性校验。
  - 新增 `test_resource_directory_baseline` 回归测试，确保资源目录族与最小可用资源映射持续存在。
- 验收结果：
  - `python scripts/validate_configs.py` 通过（14 JSON）
  - `python scripts/check_resources.py` 通过
  - quality baseline snapshot 脚本通过（alerts 0）
  - GUT 全量通过
  - Godot headless 启动通过
- 结论：全量资源目录族从“尚未体现”推进到“最小可用落地”，下一步进入 D15（性能压测深化 + CI 兼容矩阵扩展）。

### D15：性能压测深化与 CI 兼容矩阵扩展（已完成）

- 已完成文件：
  - `data/balance/quality_baseline_targets.json`
  - `scripts/tools/run_quality_baseline.gd`
  - `scripts/validate_configs.py`
  - `test/unit/test_quality_baseline_targets.gd`
  - `.github/workflows/ci.yml`
- 已落地：
  - 质量基线场景新增 `game_world_boss_pressure_endurance`，形成 idle + elite medium/high/extreme + boss endurance 的压力层级。
  - baseline 运行脚本新增 `boss_pressure_endurance` setup，支持 boss 房高压长时采样。
  - `validate_configs.py` 与 `test_quality_baseline_targets` 已同步新增场景键与 setup 合法值护栏。
  - CI `godot-headless-and-gut` 任务升级为 `ubuntu-latest + windows-latest` 双平台矩阵运行，提升兼容矩阵覆盖。
- 验收结果：
  - `python scripts/validate_configs.py` 通过（14 JSON）
  - `python scripts/check_resources.py` 通过
  - quality baseline snapshot 脚本通过（alerts 0）
  - GUT 全量通过
  - Godot headless 启动通过
- 结论：质量门由“分层 elite 压测”提升到“elite + boss endurance 压测 + 双平台 CI 兼容矩阵”，下一步可进入 D16（实机兼容回归与发布阈值收敛）。

### D16：发布阈值演练与兼容发布门（已完成）

- 已完成文件：
  - `data/balance/release_gate_targets.json`
  - `scripts/tools/run_release_gate.gd`
  - `scripts/validate_configs.py`
  - `scripts/check_resources.py`
  - `test/unit/test_release_gate_targets.gd`
  - `.github/workflows/ci.yml`
  - `README.md`
- 已落地：
  - 新增发布门配置 `release_gate_targets.json`，定义发布通道、baseline 告警上限、必备场景、必备输入动作与 CI 平台标记、发布阻断策略。
  - 新增 `run_release_gate.gd`，基于 baseline 报告与 CI 工作流进行发布门演练，并输出 `user://release_gate_latest.json/.md`。
  - `validate_configs.py` 新增 `release_gate_targets` schema 校验；`check_resources.py` 新增发布门配置/脚本/单测存在性护栏。
  - 新增 `test_release_gate_targets`，对配置结构、场景清单、InputMap 动作绑定与 CI 平台标记进行回归断言。
  - CI 在 baseline 采样后新增 `Run release gate rehearsal` 步骤，形成“采样 -> 发布门演练”的自动化串联。
- 验收结果：
  - `python scripts/validate_configs.py` 通过（15 JSON）
  - `python scripts/check_resources.py` 通过
  - quality baseline snapshot 脚本通过（alerts 0）
  - release gate rehearsal 脚本通过（blockers 0）
  - GUT 全量通过
  - Godot headless 启动通过
- 结论：质量链路从“采样与告警”推进到“发布阈值演练可自动化复核”，下一步可进入 D17（实机兼容回归与跨平台发布阈值收敛）。

### D17：实机兼容回归演练与阈值收敛（已完成）

- 已完成文件：
  - `data/balance/compatibility_rehearsal_targets.json`
  - `scripts/tools/run_compatibility_rehearsal.gd`
  - `scripts/validate_configs.py`
  - `scripts/check_resources.py`
  - `test/unit/test_compatibility_rehearsal_targets.gd`
  - `.github/workflows/ci.yml`
  - `README.md`
- 已落地：
  - 新增兼容演练配置 `compatibility_rehearsal_targets.json`，定义跨平台 profile（分辨率/输入模式/渲染路径/场景 smoke）、动作绑定要求、发布阈值与阻断策略。
  - 新增 `run_compatibility_rehearsal.gd`，读取 release gate 报告与 CI 工作流，执行 profile 级 scene smoke + InputMap 绑定检查 + 平台标记检查，并输出 `user://compatibility_rehearsal_latest.json/.md`。
  - `validate_configs.py` 新增兼容演练 schema 校验；`check_resources.py` 新增配置/脚本/单测存在性护栏。
  - 新增 `test_compatibility_rehearsal_targets`，验证 profile 配置、必备动作和 CI 平台标记一致性。
  - CI 在 `release gate rehearsal` 后新增 `Run compatibility rehearsal`，形成“baseline -> release gate -> compatibility rehearsal”的质量门链路。
- 验收结果：
  - `python scripts/validate_configs.py` 通过（16 JSON）
  - `python scripts/check_resources.py` 通过
  - quality baseline snapshot 脚本通过（alerts 0）
  - release gate rehearsal 脚本通过（blockers 0）
  - compatibility rehearsal 脚本通过（blockers 0）
  - GUT 全量通过
  - Godot headless 启动通过
- 结论：兼容质量门从“CI 双平台 + 发布门演练”推进到“profile 级兼容演练与阈值收敛自动化”，下一步可进入 D18（内容第三轮扩容与全量目标逼近）。

### D18：内容深度三轮扩容与消费闭环（已完成）

- 已完成文件：
  - `data/balance/characters.json`
  - `data/balance/evolutions.json`
  - `data/balance/shop_items.json`
  - `data/balance/narrative_content.json`
  - `scripts/game/game_world.gd`
  - `test/unit/test_content_depth_targets.gd`
  - `test/integration/test_core_flow_regression.gd`
  - `README.md`
  - `spec-design/truth-check-2026-03-20.md`
- 已落地：
  - 角色扩容到 12（新增 `char_arbiter`、`char_oracle`），进化扩容到 13（新增 `evo_vowstorm`、`evo_nether_maelstrom`、`evo_astral_horizon`）。
  - 商店池扩容到 `passive 14 / weapon 15`，并同步 chapter_3/chapter_4 覆盖池。
  - 记忆碎片扩容到 22（新增章节路线与事件碎片，含 `memory_meta_reliquary`）。
  - `game_world` 已补齐新增商店条目文案与效果消费分支。
  - `test_content_depth_targets` 阈值提升到 `12/13/14/15/22`（角色/进化/passive/weapon/记忆）；`test_core_flow_regression` 新增 D18 武器购买闭环断言。
- 验收结果：
  - `python scripts/validate_configs.py` 通过（16 JSON）
  - `python scripts/check_resources.py` 通过
  - quality baseline snapshot 脚本通过（alerts 0）
  - release gate rehearsal 脚本通过（blockers 0）
  - compatibility rehearsal 脚本通过（blockers 0）
  - GUT 全量通过
  - Godot headless 启动通过
- 结论：内容深度从“二轮可消费扩容”推进到“三轮扩容+回归护栏升级”，下一步可进入 D19（资源目录族从 stub 向实料资产迁移与映射扩展）。

### D19：资源目录族映射扩展与目录实料化（已完成）

- 已完成文件：
  - `scripts/tools/sync_resource_stubs.py`
  - `resources/resource_catalog.json`
  - `resources/{characters,weapons,passives,accessories,enemies,evolutions,meta_upgrades,forge_recipes}/*.tres`
  - `scripts/check_resources.py`
  - `test/unit/test_resource_directory_baseline.gd`
  - `README.md`
  - `spec-design/truth-check-2026-03-20.md`
- 已落地：
  - 新增 `sync_resource_stubs.py`，从 `characters/evolutions/shop_items/meta_upgrades/enemy_scaling/boss_phases` 自动同步 8 类资源目录的 `.tres` stub。
  - 生成 `resources/resource_catalog.json`（`stub_catalog_v2`），记录每个资源的 `id/path/source_json` 映射并作为校验依据。
  - 资源目录族从“每类 1 个样例 stub”扩展为“按内容 ID 全量映射”基线（角色/武器/被动/进化/meta/enemy/accessory/forge_recipe）。
  - `check_resources.py` 从固定样例校验升级为 catalog 驱动校验：版本、分类完整性、路径存在性、stub 内容一致性与 source 目标可达性。
  - `test_resource_directory_baseline.gd` 升级为 catalog 驱动回归：结构校验 + 与 balance 配置 ID 覆盖一致性断言。
- 验收结果：
  - `python scripts/validate_configs.py` 通过（16 JSON）
  - `python scripts/check_resources.py` 通过
  - quality baseline snapshot 脚本通过（alerts 0）
  - release gate rehearsal 脚本通过（blockers 0）
  - compatibility rehearsal 脚本通过（blockers 0）
  - GUT 全量通过
  - Godot headless 启动通过
- 结论：资源目录族从“最小可用样例”推进到“catalog 映射驱动的批量可追踪基线”，下一步可进入 D20（将 stub 逐步替换为生产级资源与材质参数资产）。

### D20：资源目录族材质参数资产化（已完成）

- 已完成文件：
  - `scripts/tools/sync_resource_stubs.py`
  - `resources/resource_catalog.json`
  - `resources/material_profiles/*.tres`
  - `resources/{characters,weapons,passives,accessories,enemies,evolutions,meta_upgrades,forge_recipes}/*.tres`
  - `scripts/check_resources.py`
  - `test/unit/test_resource_directory_baseline.gd`
  - `README.md`
  - `spec-design/truth-check-2026-03-20.md`
- 已落地：
  - `sync_resource_stubs.py` 从 `stub_catalog_v2` 升级到 `stub_catalog_v3`，在 catalog 与 stub 中新增 `display_name/material_profile/asset_state` 字段。
  - 新增 `resources/material_profiles/` 8 类材质参数基线资源（角色/武器/被动/饰品/敌人/进化/meta/锻造）。
  - `resource_catalog.json` 新增 `asset_state` 与 `material_profile_map` 顶层元信息，且每条 entry 增加 `material_profile` 与 `asset_state`。
  - `check_resources.py` 升级为 v3 校验：目录/文件存在、catalog 结构、entry 字段、stub 文本一致性、source 与 material_profile 目标可达性。
  - `test_resource_directory_baseline.gd` 升级为 v3 护栏：catalog 版本、entry 字段、stub 字段与 balance 覆盖一致性。
- 验收结果：
  - `python scripts/tools/sync_resource_stubs.py` 通过（8 类目录映射刷新）
  - `python scripts/validate_configs.py` 通过（16 JSON）
  - `python scripts/check_resources.py` 通过
  - quality baseline snapshot 脚本通过（alerts 0）
  - release gate rehearsal 脚本通过（blockers 0）
  - compatibility rehearsal 脚本通过（profiles 全通过）
  - GUT 全量通过
  - Godot headless 启动通过
- 结论：资源目录族从“映射驱动 stub 基线”推进到“production_candidate 材质参数资产化基线”，下一步可进入 D21（将关键目录从参数化 stub 升级为首批可运行实料资产并补实机场景验收）。

### D21：首批实料资产验收与生产态标记（已完成）

- 已完成文件：
  - `data/balance/resource_acceptance_targets.json`
  - `scripts/tools/sync_resource_stubs.py`
  - `resources/resource_catalog.json`
  - `resources/{characters,weapons,passives,accessories,enemies,evolutions,meta_upgrades,forge_recipes}/*.tres`
  - `scripts/tools/run_resource_acceptance.gd`
  - `scripts/validate_configs.py`
  - `scripts/check_resources.py`
  - `test/unit/test_resource_acceptance_targets.gd`
  - `test/unit/test_resource_directory_baseline.gd`
  - `.github/workflows/ci.yml`
  - `README.md`
- 已落地：
  - 新增 `resource_acceptance_targets.json`，定义首批 `production_ready` 资源 ID、分类验收场景、预览贴图映射和通过阈值。
  - `sync_resource_stubs.py` 升级到 `stub_catalog_v4`：catalog 与 stub 增加 `preview_texture/acceptance_scene/acceptance_profile`，并支持按目标 ID 标记 `production_ready`。
  - 新增 `run_resource_acceptance.gd`，执行首批实料资产验收演练：校验必需 ID 的 `production_ready` 状态、预览贴图可达、验收场景可实例化，并输出 `user://resource_acceptance_latest.json/.md`。
  - `validate_configs.py` 新增 `resource_acceptance_targets` schema 校验；`check_resources.py` 与 `test_resource_directory_baseline.gd` 升级为 v4 护栏（字段一致性 + `production_ready_counts` 一致性）。
  - 新增 `test_resource_acceptance_targets.gd`，对配置、catalog 覆盖、CI 平台标记与首批 production-ready 列表进行回归断言。
  - CI 在 compatibility rehearsal 后新增 `Run resource acceptance rehearsal`，形成 `baseline -> release_gate -> compatibility -> resource_acceptance` 完整质量门链路。
- 验收结果：
  - `python scripts/tools/sync_resource_stubs.py` 通过（8 类目录映射刷新）
  - `python scripts/validate_configs.py` 通过（17 JSON）
  - `python scripts/check_resources.py` 通过
  - quality baseline snapshot 脚本通过（alerts 0）
  - release gate rehearsal 脚本通过（blockers 0）
  - compatibility rehearsal 脚本通过（profiles 全通过）
  - resource acceptance rehearsal 脚本通过（blockers 0）
  - GUT 全量通过
  - Godot headless 启动通过
- 结论：资源目录族从“材质参数化 production_candidate 基线”推进到“首批 production_ready 可运行验收”阶段，下一步可进入 D22（扩大量产级实料资产比例并补强跨场景验收深度）。

### D22：production_ready 比例扩容与跨场景验收加深（已完成）

- 已完成文件：
  - `data/balance/resource_acceptance_targets.json`
  - `scripts/validate_configs.py`
  - `scripts/tools/run_resource_acceptance.gd`
  - `test/unit/test_resource_acceptance_targets.gd`
  - `scripts/tools/sync_resource_stubs.py`（执行刷新）
  - `resources/resource_catalog.json`
  - `resources/{characters,weapons,passives,accessories,enemies,evolutions,meta_upgrades,forge_recipes}/*.tres`
  - `README.md`
- 已落地：
  - `resource_acceptance_targets` 从 `batch_1` 升级到 `batch_2`：扩充 8 类 `required_production_ready_ids`，并新增 `acceptance_scene_matrix`（每类至少 2 个场景 smoke）。
  - `resource_acceptance_targets.thresholds` 新增并启用：
    - `min_ready_per_category = 2`
    - `min_ready_ratio_per_category = 0.3`
    - `min_scene_smokes_per_category = 2`
  - `run_resource_acceptance.gd` 新增分类就绪率与跨场景验收逻辑：
    - 输出 `category_ready`（ready count / total / ratio）
    - 输出 `scene_smokes`（configured / required / passed）
    - 按场景矩阵执行分类 smoke，并对 ready 数量/比例与场景通过数进行阻断判定。
  - `validate_configs.py` 已补齐 `acceptance_scene_matrix` 与新增阈值字段的 schema 校验。
  - `test_resource_acceptance_targets.gd` 已升级为 D22 护栏：断言场景矩阵、ready 数量下限、ready 比例下限与映射一致性。
  - 运行 `sync_resource_stubs.py` 后，catalog v4 生产态计数提升为：
    - `characters 6/12`, `weapons 7/15`, `passives 7/14`, `accessories 2/4`,
    - `enemies 8/20`, `evolutions 5/13`, `meta_upgrades 3/5`, `forge_recipes 5/13`。
- 验收结果：
  - `python scripts/tools/sync_resource_stubs.py` 通过（8 类目录映射刷新）
  - `python scripts/validate_configs.py` 通过（17 JSON）
  - `python scripts/check_resources.py` 通过
  - quality baseline snapshot 脚本通过（alerts 0）
  - release gate rehearsal 脚本通过（blockers 0）
  - compatibility rehearsal 脚本通过（profiles 全通过）
  - resource acceptance rehearsal 脚本通过（blockers 0）
  - GUT 全量通过
  - Godot headless 启动通过
- 结论：D22 将资源验收从“首批 production_ready 点状验证”推进到“按类比例+跨场景 smoke 深度验证”的阶段化准入，下一步可进入 D23（补齐资源预览与验收 profile 的差异化语义并接入报告分层）。

### D23：acceptance_profile 分层语义与验收报告分层（已完成）

- 已完成文件：
  - `data/balance/resource_acceptance_targets.json`
  - `scripts/tools/sync_resource_stubs.py`
  - `resources/resource_catalog.json`
  - `resources/{characters,weapons,passives,accessories,enemies,evolutions,meta_upgrades,forge_recipes}/*.tres`
  - `scripts/tools/run_resource_acceptance.gd`
  - `scripts/validate_configs.py`
  - `scripts/check_resources.py`
  - `test/unit/test_resource_acceptance_targets.gd`
  - `test/unit/test_resource_directory_baseline.gd`
  - `README.md`
- 已落地：
  - `resource_acceptance_targets.json` 从 `batch_2` 升级到 `batch_3`：
    - `required_fields` 新增 `acceptance_tier`
    - 新增 `acceptance_profile_policy`（`profiles` + `category_profile_map` + `required_ready_profile_tier`）
    - 阈值新增 `max_profile_mismatches`，并将 `min_ready_ratio_per_category` 提升到 `0.35`
  - `sync_resource_stubs.py` 升级为 `stub_catalog_v5`：
    - catalog 与 stub 增加 `acceptance_tier`
    - catalog 新增 `acceptance_profile_policy` 与 `acceptance_tier_counts`
    - 生成逻辑改为按 `category_profile_map` + `asset_state` 选择 `acceptance_profile` 并自动映射 tier。
  - `run_resource_acceptance.gd` 新增分层验收与分层报告：
    - 报告新增 `profile_layers` 与 `profile_mismatches`
    - 验收新增 profile-policy 一致性检查（profile 存在、tier 匹配、category/state 映射匹配）
    - 对 production_ready 资源新增 `required_ready_profile_tier` 阻断校验。
  - `validate_configs.py`、`check_resources.py`、`test_resource_acceptance_targets.gd`、`test_resource_directory_baseline.gd` 已补齐 D23 schema/结构/语义一致性护栏。
- 验收结果：
  - `python scripts/tools/sync_resource_stubs.py` 通过（catalog v5 刷新）
  - `python scripts/validate_configs.py` 通过（17 JSON）
  - `python scripts/check_resources.py` 通过
  - quality baseline snapshot 脚本通过（alerts 0）
  - release gate rehearsal 脚本通过（blockers 0）
  - compatibility rehearsal 脚本通过（profiles 全通过）
  - resource acceptance rehearsal 脚本通过（blockers 0）
  - GUT 全量通过
  - Godot headless 启动通过
- 结论：D23 将资源验收从“按类 ready 比例与场景 smoke 深度”推进到“acceptance_profile 分层语义可校验 + 报告可分层追踪”，下一步可进入 D24（扩展 production_ready 覆盖面并引入分层告警趋势基线）。

### D24：production_ready 覆盖扩容与分层趋势基线（已完成）

- 已完成文件：
  - `data/balance/resource_acceptance_targets.json`
  - `scripts/tools/sync_resource_stubs.py`
  - `resources/resource_catalog.json`
  - `resources/{characters,weapons,passives,accessories,enemies,evolutions,meta_upgrades,forge_recipes}/*.tres`
  - `scripts/tools/run_resource_acceptance.gd`
  - `scripts/validate_configs.py`
  - `scripts/check_resources.py`
  - `test/unit/test_resource_acceptance_targets.gd`
  - `test/unit/test_resource_directory_baseline.gd`
  - `.github/workflows/ci.yml`
  - `README.md`
- 已落地：
  - `resource_acceptance_targets.json` 升级为 `batch_4`，8 类 `required_production_ready_ids` 进一步扩容，并将阈值提升到 `min_ready_per_category=3`、`min_ready_ratio_per_category=0.5`。
  - 新增 `trend_baseline`（`bucket_ready_ratio_min` + `max_category_ratio_drop` + `max_bucket_ratio_drop`）和 `thresholds.max_trend_regressions`，形成分层趋势告警基线。
  - `sync_resource_stubs.py` 升级为 `stub_catalog_v6`：catalog 新增 `acceptance_bucket_counts`，按 profile `report_bucket` 统计 entries/ready_entries，支持 bucket 级一致性校验。
  - `run_resource_acceptance.gd` 新增趋势能力：
    - 自动轮转 `user://resource_acceptance_previous.json`，并对 category/bucket ready ratio 做 drop 对比。
    - 报告新增 `profile_buckets` 与 `trend` 段，支持 warning 级告警与 `max_trend_regressions` 阻断。
  - `validate_configs.py`、`check_resources.py`、`test_resource_acceptance_targets.gd`、`test_resource_directory_baseline.gd` 已补齐 D24 schema/结构/语义护栏（v6 + trend baseline + bucket counts）。
  - CI 在 resource acceptance 后新增 `Run resource acceptance trend gate`（二次执行），确保趋势路径在流水线中可回归。
- 验收结果：
  - `python scripts/tools/sync_resource_stubs.py` 通过（catalog v6 刷新）
  - `python scripts/validate_configs.py` 通过（17 JSON）
  - `python scripts/check_resources.py` 通过
  - quality baseline snapshot 脚本通过（alerts 0）
  - release gate rehearsal 脚本通过（blockers 0）
  - compatibility rehearsal 脚本通过（profiles 全通过）
  - resource acceptance rehearsal + trend gate 通过（blockers 0）
  - GUT 全量通过
  - Godot headless 启动通过
- 结论：D24 将资源验收从“分层语义一致性”推进到“覆盖面扩容 + 分层趋势基线可阻断”的阶段化准入，下一步可进入 D25（补齐实料资产替换批次与场景内真实可视验收）。

### D25：实料资产替换批次扩展与场景可视验收（已完成）

- 已完成文件：
  - `data/balance/resource_acceptance_targets.json`
  - `scripts/tools/sync_resource_stubs.py`
  - `resources/resource_catalog.json`
  - `resources/{characters,weapons,passives,accessories,enemies,evolutions,meta_upgrades,forge_recipes}/*.tres`
  - `scripts/tools/run_resource_acceptance.gd`
  - `scripts/validate_configs.py`
  - `scripts/check_resources.py`
  - `test/unit/test_resource_acceptance_targets.gd`
  - `test/unit/test_resource_directory_baseline.gd`
  - `.github/workflows/ci.yml`
  - `README.md`
- 已落地：
  - `resource_acceptance_targets.json` 升级为 `batch_5`：
    - 8 类 `required_production_ready_ids` 继续扩容（ready 覆盖显著提升）。
    - `acceptance_scene_matrix` 扩展到每类 3 个 smoke 场景。
    - 新增 `scene_visual_requirements`，将“场景内节点+属性”纳入可视验收。
    - 阈值提升为 `min_ready_per_category=4`、`min_ready_ratio_per_category=0.7`、`min_scene_smokes_per_category=3`、`min_visual_checks_per_category=3`，并要求 `max_visual_failures=0`。
  - `sync_resource_stubs.py` 升级为 `stub_catalog_v7`：
    - catalog 新增 `scene_visual_requirements` 与 `scene_visual_requirement_counts`。
    - 资源条目维持 tier/profile 语义并按 `batch_5` 目标标记 production-ready。
  - `run_resource_acceptance.gd` 新增场景可视验收执行：
    - 新增 `visual_checks` 与 `visual_failures` 报告段。
    - 支持规则：`exists` / `non_null` / `non_empty_string` / `array_non_empty` / `float_gt_zero`。
    - 增加 `max_visual_failures` 阻断与 catalog visual-count 一致性校验。
  - `validate_configs.py`、`check_resources.py`、`test_resource_acceptance_targets.gd`、`test_resource_directory_baseline.gd` 已补齐 D25 schema/结构/语义护栏（v7 + visual checks）。
  - CI 将 resource acceptance 步骤标记为 scene-visual rehearsal，并保留第二次 trend+visual gate 执行。
- 验收结果：
  - `python scripts/tools/sync_resource_stubs.py` 通过（catalog v7 刷新）
  - `python scripts/validate_configs.py` 通过（17 JSON）
  - `python scripts/check_resources.py` 通过
  - quality baseline snapshot 脚本通过（alerts 0）
  - release gate rehearsal 脚本通过（blockers 0）
  - compatibility rehearsal 脚本通过（profiles 全通过）
  - resource acceptance rehearsal + trend+visual gate 通过（blockers 0 / warnings 0）
  - GUT 全量通过（`15 scripts / 50 tests / 5049 asserts / 0 failures`）
  - Godot headless 启动通过
- 结论：D25 将资源验收从“批次覆盖+趋势阻断”推进到“场景内可视验收可回归”的阶段化准入，下一步可进入 D26（提升 production_ready 覆盖到近全量并引入章节级可视快照对比基线）。

### D26：production_ready 近全量覆盖与可视验收加压（已完成）

- 已完成文件：
  - `data/balance/resource_acceptance_targets.json`
  - `scripts/tools/sync_resource_stubs.py`
  - `resources/resource_catalog.json`
  - `resources/{characters,weapons,passives,accessories,enemies,evolutions,meta_upgrades,forge_recipes}/*.tres`
  - `scripts/tools/run_resource_acceptance.gd`
  - `scripts/validate_configs.py`
  - `scripts/check_resources.py`
  - `test/unit/test_resource_acceptance_targets.gd`
  - `test/unit/test_resource_directory_baseline.gd`
  - `README.md`
- 已落地：
  - `resource_acceptance_targets.json` 升级为 `batch_6`：
    - 8 类 `required_production_ready_ids` 扩展为全量覆盖（当前 catalog 全条目均纳入 production-ready 验收）。
    - `acceptance_scene_matrix` 深度提升到每类 4 个场景 smoke。
    - `scene_visual_requirements` 提升到每类 4 条可视规则，并新增 `bool_true` 规则用于可见性断言。
    - 阈值提升为 `min_ready_per_category=4`、`min_ready_ratio_per_category=0.95`、`min_scene_smokes_per_category=4`、`min_visual_checks_per_category=4`。
    - 趋势基线提升为 `bucket_ready_ratio_min(menu/combat/ui)=0.95/0.95/0.95`，`max_category_ratio_drop=max_bucket_ratio_drop=0.02`。
  - `sync_resource_stubs.py` 升级为 `stub_catalog_v8`：
    - catalog 新增 `production_ready_ratio_by_category`。
    - catalog/version 与 stub 已同步 batch_6 产物，`scene_visual_requirement_counts` 保持与目标配置一致。
  - `run_resource_acceptance.gd` 新增：
    - `bool_true` 可视规则执行。
    - `production_ready_ratio_by_category` 与实时计算比对阻断。
  - `validate_configs.py`、`check_resources.py`、`test_resource_acceptance_targets.gd`、`test_resource_directory_baseline.gd` 已补齐 D26 护栏（v8 + bool_true + ratio-by-category 一致性 + 4x smoke/visual 深度）。
- 验收结果：
  - `python scripts/tools/sync_resource_stubs.py` 通过（catalog v8 刷新）
  - `python scripts/validate_configs.py` 通过（17 JSON）
  - `python scripts/check_resources.py` 通过
  - quality baseline snapshot 脚本通过（alerts 0）
  - release gate rehearsal 脚本通过（blockers 0）
  - compatibility rehearsal 脚本通过（profiles 全通过）
  - resource acceptance rehearsal + trend+visual gate 通过（blockers 0 / warnings 0）
  - GUT 全量通过（`15 scripts / 50 tests / 5179 asserts / 0 failures`）
  - Godot headless 启动通过
- 结论：D26 将资源验收从“batch_5 可视验收”推进到“batch_6 近全量 production-ready + 4x 场景/可视深度 + v8 比例一致性护栏”的阶段化准入，下一步可进入 D27（章节级可视快照对比基线与实机截图回归链路）。

### D27：章节级可视快照回归链路（已完成）

- 已完成文件：
  - `data/balance/visual_snapshot_targets.json`
  - `scripts/tools/run_visual_snapshot_regression.gd`
  - `scripts/validate_configs.py`
  - `scripts/check_resources.py`
  - `test/unit/test_visual_snapshot_targets.gd`
  - `.github/workflows/ci.yml`
  - `README.md`
- 已落地：
  - 新增 `visual_snapshot_targets.json`（`chapter_snapshot_v1`），覆盖 `chapter_1~4_world` + `main_menu_ui` 快照目标，定义分辨率、warmup/capture 帧数、`opaque_ratio/unique_colors/avg_luma` 指标阈值与 trend 限制。
  - 新增 `run_visual_snapshot_regression.gd`：
    - 读取快照目标并生成 `user://visual_snapshot_latest.json/.md`；
    - 自动轮转 `user://visual_snapshot_previous.json` 做趋势对比；
    - 支持章节场景 setup 与 headless fallback 指标采样；
    - 输出 blockers/warnings 并按阈值阻断。
  - `validate_configs.py` 与 `check_resources.py` 已接入 `visual_snapshot_targets` schema/结构/路径校验（含场景存在性、阈值边界、目标数量下限）。
  - 新增 `test_visual_snapshot_targets.gd`，覆盖配置结构、阈值边界、场景路径可达与严格阻断默认值断言。
  - CI 新增两步：
    - `Run visual snapshot regression rehearsal`
    - `Run visual snapshot regression trend gate`
    使可视快照回归在流水线中可重复验证。
- 验收结果：
  - `python scripts/validate_configs.py` 通过（18 JSON）
  - `python scripts/check_resources.py` 通过
  - quality baseline / release gate / compatibility rehearsal 通过
  - resource acceptance rehearsal + trend+visual gate 通过
  - visual snapshot regression rehearsal + trend gate 通过（blockers 0 / warnings 0）
  - GUT 全量通过（`16 scripts / 52 tests / 5276 asserts / 0 failures`）
  - Godot headless 启动通过
- 结论：D27 在既有资源验收门链路上补齐了“章节级可视快照指标回归 + 趋势阻断”自动化能力，下一步可进入 D28（快照指标与真实渲染样本的精度收敛与跨渲染后端差异治理）。

### D28：可视快照精度收敛与后端差异治理（已完成）

- 已完成文件：
  - `data/balance/visual_snapshot_targets.json`
  - `scripts/tools/run_visual_snapshot_regression.gd`
  - `scripts/validate_configs.py`
  - `scripts/check_resources.py`
  - `test/unit/test_visual_snapshot_targets.gd`
  - `.github/workflows/ci.yml`
  - `README.md`
- 已落地：
  - `visual_snapshot_targets.json` 从 `chapter_snapshot_v1` 升级为 `chapter_snapshot_v2`：
    - 新增 `precision`（`sample_rounds` + `max_opaque_ratio_stddev/max_luma_stddev/max_unique_color_stddev_ratio`）。
    - 新增 `backend_profiles`（`default/linux_headless/windows_headless`）用于后端差异容忍度与阈值缩放。
    - 收紧趋势阈值（`max_opaque_ratio_drop=0.12`、`max_unique_color_drop_ratio=0.45`、`max_luma_delta=0.15`）。
  - `run_visual_snapshot_regression.gd` 升级：
    - 快照采样改为多轮聚合（均值 + 标准差）并新增精度收敛 gate。
    - 新增后端识别与 profile 选择（支持 `VISUAL_SNAPSHOT_BACKEND_TAG`），按后端 profile 应用阈值。
    - 报告新增 `backend_tag` 与 `precision` 段，趋势判定与可读性增强。
  - `validate_configs.py`、`check_resources.py`、`test_visual_snapshot_targets.gd` 已补齐 D28 schema/结构/阈值护栏（precision + backend profiles）。
  - CI 可视快照两步已显式注入 backend tag（linux/windows），确保跨平台后端差异路径可稳定回归。
- 验收结果：
  - `python scripts/validate_configs.py` 通过（18 JSON）
  - `python scripts/check_resources.py` 通过
  - quality baseline / release gate / compatibility rehearsal 通过
  - resource acceptance rehearsal + trend+visual gate 通过
  - visual snapshot regression rehearsal + trend gate 通过（blockers 0 / warnings 0）
  - GUT 全量通过（`16 scripts / 52 tests / 5325 asserts / 0 failures`）
  - Godot headless 启动通过
- 结论：D28 将可视快照链路从“单次指标+趋势对比”推进到“多轮精度收敛 + 跨后端阈值治理”的阶段化准入，下一步可进入 D29（实机截图基线对齐与章节级视觉差异白名单治理）。

### D29：实机截图基线对齐与视觉差异白名单治理（已完成）

- 已完成文件：
  - `data/balance/visual_snapshot_targets.json`
  - `scripts/tools/run_visual_snapshot_regression.gd`
  - `scripts/validate_configs.py`
  - `scripts/check_resources.py`
  - `test/unit/test_visual_snapshot_targets.gd`
  - `README.md`
- 已落地：
  - `visual_snapshot_targets.json` 升级为 `chapter_snapshot_v3`：
    - 新增 `baseline_alignment`（`required_snapshot_ids` + `allowed_capture_modes`），强制章节/主菜单快照覆盖与后端采样模式对齐。
    - 新增 `diff_whitelist` 与 `whitelist_policy`（`max_hits` + `max_ratio`），用于治理后端已知可接受视觉差异。
  - `run_visual_snapshot_regression.gd` 升级：
    - 接入 required snapshots 校验与后端 capture mode 白名单判定。
    - 接入 per-backend/per-snapshot 差异白名单阈值，输出 whitelist 命中与原因。
    - 将超默认阈值但落在白名单区间的项降级为 warning，并受 `whitelist_policy`（命中次数/比例）二次约束。
  - `validate_configs.py`、`check_resources.py`、`test_visual_snapshot_targets.gd` 已补齐 D29 schema/结构/阈值护栏（v3 channel、baseline alignment、diff whitelist、whitelist policy）。
- 验收结果：
  - `python scripts/validate_configs.py` 通过（18 JSON）
  - `python scripts/check_resources.py` 通过
  - quality baseline / release gate / compatibility rehearsal 通过
  - resource acceptance rehearsal + trend+visual gate 通过
  - visual snapshot regression rehearsal + trend gate 通过（blockers 0 / warnings 0）
  - GUT 全量通过（`16 scripts / 52 tests / 5366 asserts / 0 failures`）
  - Godot headless 启动通过
- 结论：D29 将可视快照链路从“精度收敛 + 后端阈值治理”推进到“实机基线对齐 + 差异白名单可审计治理”的阶段化准入，下一步可进入 D30（章节可视基线跨版本对比与回归报告分层收敛）。

### D30-1：JSON 语法快速失败闸门（已完成）

- 已完成文件：
  - `scripts/tools/check_json_syntax.py`
  - `.github/workflows/ci.yml`
  - `scripts/check_resources.py`
  - `README.md`
- 已落地：
  - 新增轻量 JSON 语法闸门脚本 `check_json_syntax.py`，覆盖 `data/balance/*.json` 以及 `resources/resource_catalog.json`、`assets/sprites/tiles/atlas_manifest.json`。
  - 语法异常输出已统一为 `file:line:column`，可直接定位解析失败位置。
  - CI `validate-config-and-resources` 已前置 `JSON syntax gate`，在语法层快速失败后不再进入重验证链路。
  - `check_resources.py` 已将 `check_json_syntax.py` 纳入必需文件，避免护栏脚本丢失。
- 验收结果：
  - `python scripts/tools/check_json_syntax.py` 通过
  - `python scripts/validate_configs.py` 通过（18 JSON）
  - `python scripts/check_resources.py` 通过
  - quality baseline / release gate / compatibility rehearsal 通过
  - resource acceptance rehearsal + trend+visual gate 通过
  - visual snapshot regression rehearsal + trend gate 通过（blockers 0 / warnings 0）
  - GUT 全量通过（`16 scripts / 52 tests / 5366 asserts / 0 failures`）
  - Godot headless 启动通过
- 结论：D30-1 已将“JSON 语法错误”前置到最低成本阶段并提供可定位报错，后续进入 D30-2（章节可视基线跨版本对比与回归报告分层收敛）。

### D30-2：章节可视基线跨版本对比与回归报告分层收敛（已完成）

- 已完成文件：
  - `data/balance/visual_snapshot_targets.json`
  - `scripts/tools/run_visual_snapshot_regression.gd`
  - `scripts/validate_configs.py`
  - `scripts/check_resources.py`
  - `test/unit/test_visual_snapshot_targets.gd`
  - `README.md`
- 已落地：
  - `visual_snapshot_targets.json` 升级为 `chapter_snapshot_v4`：
    - 新增 `report_layers`（`world/ui`）并定义每层 `snapshot_ids`、`max_layer_blockers`、`max_layer_warnings`、`min_pass_ratio`。
    - 新增 `cross_version_baseline`，包含 `reference_channels`（v1/v2/v3）、`max_drift`、`max_violations` 与全快照 `snapshot_references`。
  - `run_visual_snapshot_regression.gd` 升级：
    - 新增跨版本漂移评估（`_evaluate_cross_version_baseline`）与分层收敛评估（`_evaluate_report_layers`）。
    - 报告新增 `cross_version` 与 `layers` 段落，支持按层汇总 blocker/warning/pass_ratio。
    - Markdown 报告新增 `## Cross Version` 与 `## Layers` 分段，增强回归可审计性。
  - `validate_configs.py`、`check_resources.py`、`test_visual_snapshot_targets.gd` 已补齐 D30-2 的 schema/结构/阈值护栏（v4 channel、report layers、cross-version baseline）。
  - 配置基线已按当前 headless 指标重对齐，确保跨版本比较在可控阈值内收敛。
- 验收结果：
  - `python scripts/tools/check_json_syntax.py` 通过（20 files）
  - `python scripts/validate_configs.py` 通过（18 JSON）
  - `python scripts/check_resources.py` 通过
  - quality baseline / release gate / compatibility rehearsal 通过
  - resource acceptance rehearsal + trend+visual gate 通过
  - visual snapshot regression rehearsal + trend gate 通过（blockers 0 / warnings 0）
  - GUT 全量通过（`16 scripts / 52 tests / 5543 asserts / 0 failures`）
  - Godot headless 启动通过
- 结论：D30-2 已将可视快照链路从“白名单差异治理”推进到“跨版本基线漂移约束 + 分层收敛阻断”的阶段化准入，下一步可进入 D30-3（跨后端可视差异归因与白名单收敛自动化）。

### D30-3：跨后端可视差异归因与白名单收敛自动化（已完成）

- 已完成文件：
  - `data/balance/visual_snapshot_targets.json`
  - `scripts/tools/run_visual_snapshot_regression.gd`
  - `scripts/validate_configs.py`
  - `scripts/check_resources.py`
  - `test/unit/test_visual_snapshot_targets.gd`
  - `README.md`
- 已落地：
  - `visual_snapshot_targets.json` 升级为 `chapter_snapshot_v5`：
    - 新增 `backend_attribution`（required backends + 非归因/后端归因回归上限）。
    - 新增 `whitelist_convergence`（stale streak 阈值 + tighten 比率 + 建议数量上限）。
  - `run_visual_snapshot_regression.gd` 升级：
    - 新增后端差异归因统计与阻断（`_evaluate_backend_attribution`）。
    - 新增白名单收敛建议自动化（`_evaluate_whitelist_convergence`），输出 `streaks` 与 `convergence_suggestions`。
    - 报告新增 `backend_attribution` 与 `whitelist convergence` 分段，形成“归因 -> 治理建议 -> gate”闭环。
  - `validate_configs.py`、`check_resources.py`、`test_visual_snapshot_targets.gd` 已补齐 D30-3 schema/结构/阈值护栏（v5 channel + backend attribution + whitelist convergence）。
- 验收结果：
  - `python scripts/tools/check_json_syntax.py` 通过（20 files）
  - `python scripts/validate_configs.py` 通过（18 JSON）
  - `python scripts/check_resources.py` 通过
  - quality baseline / release gate / compatibility rehearsal 通过
  - resource acceptance rehearsal + trend+visual gate 通过
  - visual snapshot regression rehearsal + trend gate 通过（blockers 0 / warnings 0）
  - GUT 全量通过（`16 scripts / 52 tests / 5554 asserts / 0 failures`）
  - Godot headless 启动通过
- 结论：D30-3 已将可视快照链路从“跨版本分层收敛”推进到“跨后端差异可归因 + 白名单自动收敛建议”的阶段化准入，下一步可进入 D30-4（可视回归例外生命周期治理与自动回收策略）。

### D30-4：可视回归例外生命周期治理与自动回收策略（已完成）

- 已完成文件：
  - `data/balance/visual_snapshot_targets.json`
  - `scripts/tools/run_visual_snapshot_regression.gd`
  - `scripts/validate_configs.py`
  - `scripts/check_resources.py`
  - `test/unit/test_visual_snapshot_targets.gd`
  - `README.md`
- 已落地：
  - `visual_snapshot_targets.json` 升级为 `chapter_snapshot_v6`：
    - 新增 `exception_lifecycle`（`expire_idle_runs`、`auto_reclaim_hit_streak`、`max_expired_entries`、`max_reclaim_candidates`）。
  - `run_visual_snapshot_regression.gd` 升级：
    - 新增 `_evaluate_exception_lifecycle`，基于前次报告维护 whitelist 规则生命周期（`hit_streak/idle_runs/total_hits`）。
    - 支持“长期未命中自动过期”与“持续命中自动回收候选”双路径，并接入全局阻断上限。
    - 报告新增 `Exception Lifecycle` 分段与汇总（`expired_entries` / `reclaim_candidates`）。
  - `validate_configs.py`、`check_resources.py`、`test_visual_snapshot_targets.gd` 已补齐 D30-4 schema/结构/阈值护栏（v6 channel + exception lifecycle）。
- 验收结果：
  - `python scripts/tools/check_json_syntax.py` 通过（20 files）
  - `python scripts/validate_configs.py` 通过（18 JSON）
  - `python scripts/check_resources.py` 通过
  - quality baseline / release gate / compatibility rehearsal 通过
  - resource acceptance rehearsal + trend+visual gate 通过
  - visual snapshot regression rehearsal + trend gate 通过（blockers 0 / warnings 0）
  - GUT 全量通过（`16 scripts / 52 tests / 5559 asserts / 0 failures`）
  - Godot headless 启动通过
- 结论：D30-4 已将可视快照链路从“归因 + 收敛建议”推进到“例外生命周期治理 + 自动回收策略”的阶段化准入，下一步可进入 D31（可视回归策略编排与发布级收敛模板化）。

### D31：可视回归策略编排与发布级收敛模板化（已完成）

- 已完成文件：
  - `data/balance/visual_snapshot_targets.json`
  - `scripts/tools/run_visual_snapshot_regression.gd`
  - `scripts/validate_configs.py`
  - `scripts/check_resources.py`
  - `test/unit/test_visual_snapshot_targets.gd`
  - `.github/workflows/ci.yml`
  - `README.md`
- 已落地：
  - `visual_snapshot_targets.json` 升级为 `chapter_snapshot_v7`：
    - 新增 `strategy_orchestration`，包含 `default_strategy`、`strategies`、`templates`。
    - 策略模板支持覆盖 `thresholds`、`whitelist_policy`、`backend_attribution`、`whitelist_convergence`、`exception_lifecycle`、`cross_version_baseline`、`report_layers`。
  - `run_visual_snapshot_regression.gd` 升级：
    - 新增策略解析与模板合并（`_resolve_strategy_orchestration`），将策略生效后的阈值注入所有 gate 路径。
    - 报告新增 `strategy` 元数据（`name/template/errors`），并对策略配置错误给出阻断项（`strategy_orchestration_invalid`）。
  - `validate_configs.py`、`check_resources.py`、`test_visual_snapshot_targets.gd` 已补齐 D31 schema/结构/引用完整性护栏（v7 channel + strategy orchestration）。
  - CI visual snapshot 两步已显式注入：
    - rehearsal：`VISUAL_SNAPSHOT_STRATEGY=ci_rehearsal`
    - trend gate：`VISUAL_SNAPSHOT_STRATEGY=ci_trend_gate`
- 验收结果：
  - `python scripts/tools/check_json_syntax.py` 通过（20 files）
  - `python scripts/validate_configs.py` 通过（18 JSON）
  - `python scripts/check_resources.py` 通过
  - quality baseline / release gate / compatibility rehearsal 通过
  - resource acceptance rehearsal + trend+visual gate 通过
  - visual snapshot regression rehearsal + trend gate（策略编排）通过（blockers 0 / warnings 0）
  - GUT 全量通过（`16 scripts / 52 tests / 5640 asserts / 0 failures`）
  - Godot headless 启动通过
- 结论：D31 已将可视回归链路从“规则治理”推进到“策略模板化编排 + 发布级收敛切换”的阶段化准入，下一步可进入 D32（可视回归策略发布清单与门禁模板固化）。

### D32：可视回归策略发布清单与门禁模板固化（已完成）

- 已完成文件：
  - `data/balance/visual_snapshot_targets.json`
  - `scripts/tools/run_visual_snapshot_regression.gd`
  - `scripts/validate_configs.py`
  - `scripts/check_resources.py`
  - `test/unit/test_visual_snapshot_targets.gd`
  - `.github/workflows/ci.yml`
  - `README.md`
- 已落地：
  - `visual_snapshot_targets.json` 升级为 `chapter_snapshot_v8`：
    - 新增 `release_gate_templates`，固化 `required_strategies`、`required_strategy_bindings`、`ci_mode_bindings` 与 `release_checklist`。
  - `run_visual_snapshot_regression.gd` 升级：
    - 新增发布清单校验与模板绑定核验（`_evaluate_release_gate_templates`），输出 `release_manifest` 报告分段。
    - 新增运行模式维度（`VISUAL_SNAPSHOT_RUN_MODE`）并校验与 `ci_mode_bindings` 一致。
    - 支持发布策略模板 dry-run（`release_candidate` / `release_blocking`）。
  - `validate_configs.py`、`check_resources.py`、`test_visual_snapshot_targets.gd` 已补齐 D32 schema/结构/引用完整性护栏（v8 channel + release gate templates）。
  - CI visual snapshot 链路已扩展：
    - rehearsal/trend gate 两步增加 `VISUAL_SNAPSHOT_RUN_MODE`
    - 新增 release 模板 dry-run 两步（`release_candidate`、`release_blocking`）。
- 验收结果：
  - `python scripts/tools/check_json_syntax.py` 通过（20 files）
  - `python scripts/validate_configs.py` 通过（18 JSON）
  - `python scripts/check_resources.py` 通过
  - quality baseline / release gate / compatibility rehearsal 通过
  - resource acceptance rehearsal + trend+visual gate 通过
  - visual snapshot regression rehearsal + trend gate + release 模板 dry-run 通过（blockers 0 / warnings 0）
  - GUT 全量通过（`16 scripts / 52 tests / 5675 asserts / 0 failures`）
  - Godot headless 启动通过
- 结论：D32 已将可视回归链路从“策略编排”推进到“发布清单固化 + 门禁模板可执行化”的阶段化准入，下一步可进入 D33（跨后端实机快照基线采样矩阵与变更审批流固化）。

### D33：跨后端矩阵治理与审批流程固化（已完成）

- 已完成文件：
  - `data/balance/visual_snapshot_targets.json`
  - `scripts/tools/run_visual_snapshot_regression.gd`
  - `scripts/validate_configs.py`
  - `scripts/check_resources.py`
  - `test/unit/test_visual_snapshot_targets.gd`
  - `.github/workflows/ci.yml`
  - `README.md`
- 已落地：
  - `visual_snapshot_targets.json` 升级为 `chapter_snapshot_v9`：
    - 新增 `backend_matrix_governance`（required backend matrix + required run modes + missing bounds）。
    - 新增 `approval_workflow`（required report sections + blockers/warnings policy + max approval failures）。
  - `run_visual_snapshot_regression.gd` 升级：
    - 读取 `VISUAL_SNAPSHOT_BACKEND_MATRIX` 并评估后端矩阵覆盖与 run mode 绑定完整性。
    - 新增 `approval` 分段，执行报告章节齐全度与策略级零阻断/零告警审批约束。
    - 报告新增 `Backend Matrix Governance` / `Approval Workflow` 段落，并提供对应阻断项。
  - `validate_configs.py`、`check_resources.py`、`test_visual_snapshot_targets.gd` 已补齐 D33 schema/结构/引用一致性护栏（v9 channel + backend matrix governance + approval workflow）。
  - CI visual snapshot 四步已注入 `VISUAL_SNAPSHOT_BACKEND_MATRIX=linux_headless,windows_headless`，与 strategy/run_mode 组合形成矩阵治理闭环。
- 验收结果：
  - `python scripts/tools/check_json_syntax.py` 通过（20 files）
  - `python scripts/validate_configs.py` 通过（18 JSON）
  - `python scripts/check_resources.py` 通过
  - quality baseline / release gate / compatibility rehearsal 通过
  - resource acceptance rehearsal + trend+visual gate 通过
  - visual snapshot regression rehearsal + trend gate + release 模板 dry-run（含 backend matrix）通过（blockers 0 / warnings 0）
  - GUT 全量通过（`16 scripts / 52 tests / 5699 asserts / 0 failures`）
  - Godot headless 启动通过
- 结论：D33 已将可视回归链路从“发布模板固化”推进到“跨后端矩阵治理 + 审批流程硬约束”的发布前准入阶段，下一步可进入 D34（审批记录持久化与跨流水线历史追溯）。

### D34：审批记录持久化与跨流水线历史追溯（已完成）

- 已完成文件：
  - `data/balance/visual_snapshot_targets.json`
  - `scripts/tools/run_visual_snapshot_regression.gd`
  - `scripts/validate_configs.py`
  - `scripts/check_resources.py`
  - `test/unit/test_visual_snapshot_targets.gd`
  - `.github/workflows/ci.yml`
  - `README.md`
- 已落地：
  - `visual_snapshot_targets.json` 升级为 `chapter_snapshot_v10`：
    - 新增 `approval_audit_trail`（history file、max entries、required run modes/backends、pipeline id 唯一性与追溯失败阈值）。
    - `approval_workflow.required_report_sections` 增补 `Approval Audit Trail`，与 runner 报告章节一致。
  - `run_visual_snapshot_regression.gd` 升级：
    - 新增审批历史持久化与追溯评估：按 `history_file` 写入 `channel/backend/run_mode/strategy/pipeline_id/blockers/warnings/approval_failures`。
    - 新增 `approval_audit` 报告分段与 `approval_audit_trace_failures_exceeded` 门禁。
    - 非 `release_blocking` 模式下追溯缺口以 warning 形式提示；`release_blocking` 仍执行阻断判定。
  - `validate_configs.py`、`check_resources.py`、`test_visual_snapshot_targets.gd` 已补齐 D34 schema/结构/一致性护栏（v10 channel + approval_audit_trail + report section 对齐）。
  - CI visual snapshot 四步已注入 `VISUAL_PIPELINE_ID`，并与 `VISUAL_SNAPSHOT_BACKEND_MATRIX`、`VISUAL_SNAPSHOT_STRATEGY`、`VISUAL_SNAPSHOT_RUN_MODE` 形成可追溯执行上下文。
- 验收结果：
  - `python scripts/tools/check_json_syntax.py` 通过（20 files）
  - `python scripts/validate_configs.py` 通过（18 JSON）
  - `python scripts/check_resources.py` 通过
  - quality baseline / release gate / compatibility rehearsal 通过
  - resource acceptance rehearsal + trend+visual gate 通过
  - visual snapshot regression rehearsal/trend/release_candidate/release_blocking 通过（其中前 3 个模式存在 `approval_audit` 追溯 warning，`release_blocking` 为 blockers 0 / warnings 0）
  - GUT 全量通过（`16 scripts / 52 tests / 5716 asserts / 0 failures`）
  - Godot headless 启动通过
- 结论：D34 已将可视回归链路从“审批规则硬约束”推进到“审批记录持久化 + 跨流水线历史追溯”阶段，下一步可进入 D35（审批历史聚合与跨后端长期趋势归档）。

### D35：审批历史聚合与跨后端长期趋势归档（已完成）

- 已完成文件：
  - `data/balance/visual_snapshot_targets.json`
  - `scripts/tools/run_visual_snapshot_regression.gd`
  - `scripts/validate_configs.py`
  - `scripts/check_resources.py`
  - `test/unit/test_visual_snapshot_targets.gd`
  - `README.md`
- 已落地：
  - `visual_snapshot_targets.json` 升级为 `chapter_snapshot_v11`：
    - 新增 `approval_history_archive`（archive file、max entries、aggregation window、required run modes/backends、backend delta 阈值、archive trace failure 阈值）。
  - `run_visual_snapshot_regression.gd` 升级：
    - 新增审批历史归档聚合评估（`approval_archive`），将每次快照回归结果写入长期归档并按滚动窗口计算 run_mode/backend 覆盖与跨后端 warning/blocker delta。
    - 新增 `Approval History Archive` 报告分段与 `approval_archive_trace_failures_exceeded` 门禁；非 `release_blocking` 模式输出 `approval_archive_trace_failures_pending` warning，`release_blocking` 保持严格阻断判定。
  - `validate_configs.py`、`check_resources.py`、`test_visual_snapshot_targets.gd` 已补齐 D35 schema/结构/一致性护栏（v11 channel + approval_history_archive + release/backend matrix 关联约束）。
  - 可视快照四模式执行已携带唯一 `VISUAL_PIPELINE_ID`，归档链路可持续积累跨流水线审批历史。
- 验收结果：
  - `python scripts/tools/check_json_syntax.py` 通过（20 files）
  - `python scripts/validate_configs.py` 通过（18 JSON）
  - `python scripts/check_resources.py` 通过
  - quality baseline / release gate / compatibility rehearsal 通过
  - resource acceptance rehearsal + trend+visual gate 通过
  - visual snapshot regression rehearsal/trend/release_candidate/release_blocking 通过（前 3 个模式 warnings 1，`release_blocking` 为 blockers 0 / warnings 0）
  - GUT 全量通过（`16 scripts / 52 tests / 5739 asserts / 0 failures`）
  - Godot headless 启动通过
- 结论：D35 已将可视回归链路从“审批历史追溯”推进到“长期归档聚合 + 跨后端趋势治理”阶段，下一步可进入 D36（审批历史分层阈值模板与发布候选追踪报告）。

### D36：审批历史分层阈值模板与发布候选追踪报告（已完成）

- 已完成文件：
  - `data/balance/visual_snapshot_targets.json`
  - `scripts/tools/run_visual_snapshot_regression.gd`
  - `scripts/validate_configs.py`
  - `scripts/check_resources.py`
  - `test/unit/test_visual_snapshot_targets.gd`
  - `README.md`
- 已落地：
  - `visual_snapshot_targets.json` 升级为 `chapter_snapshot_v12`：
    - 新增 `approval_threshold_templates`（`default_template` + `run_mode_templates` + `templates`），支持按 run_mode 覆盖 `approval_workflow` / `approval_audit_trail` / `approval_history_archive` 阈值。
    - 新增 `release_candidate_tracking`（window、required run modes/strategies、avg warning 与 blocker 聚合阈值、tracking failure 上限）。
  - `run_visual_snapshot_regression.gd` 升级：
    - 新增审批阈值模板解析与生效合并（按 run_mode 解析模板并覆盖审批相关门禁参数）。
    - 新增 `Release Candidate Tracking` 评估与报告分段：从审批归档窗口统计 release candidate 运行样本，按 `min_runs` / `max_avg_warnings` / `max_total_blockers` 校验发布候选稳定性。
    - 保持分级门禁：`release_blocking` 模式严格阻断，非 blocking 模式输出告警提示用于收敛。
  - `validate_configs.py`、`check_resources.py`、`test_visual_snapshot_targets.gd` 已补齐 D36 schema/结构/一致性护栏（v12 channel + approval threshold templates + release candidate tracking + manifest/strategy 关联约束）。
- 验收结果：
  - `python scripts/tools/check_json_syntax.py` 通过（20 files）
  - `python scripts/validate_configs.py` 通过（18 JSON）
  - `python scripts/check_resources.py` 通过
  - quality baseline / release gate / compatibility rehearsal 通过
  - resource acceptance rehearsal + trend+visual gate 通过
  - visual snapshot regression rehearsal/trend/release_candidate/release_blocking 通过（前 3 模式存在候选追踪/归档告警，`release_blocking` 为 blockers 0 / warnings 0）
  - GUT 全量通过（`16 scripts / 52 tests / 5801 asserts / 0 failures`）
  - Godot headless 启动通过
- 结论：D36 已将可视回归链路从“审批历史归档治理”推进到“分层阈值模板编排 + 发布候选稳定性追踪”阶段，下一步可进入 D37（发布候选稳定性分层评分与审批收敛看板）。

### D37：发布候选稳定性分层评分与审批收敛看板（已完成）

- 已完成文件：
  - `data/balance/visual_snapshot_targets.json`
  - `scripts/tools/run_visual_snapshot_regression.gd`
  - `scripts/validate_configs.py`
  - `scripts/check_resources.py`
  - `test/unit/test_visual_snapshot_targets.gd`
  - `spec-design/development-plan-supplement-2026-03-20-session.md`
  - `spec-design/README.md`
  - `spec-design/truth-check-2026-03-20.md`
- 已落地：
  - `visual_snapshot_targets.json` 升级为 `chapter_snapshot_v13`：
    - 新增 `stability_scoring`（weights/failure_caps/confidence/score_round_digits）。
    - 新增 `stability_tiers`（default_tier + 分层规则）。
    - 新增 `convergence_dashboard`（审批/追踪/归档/manifest/blockers/warnings 收敛阈值）。
    - 新增 `ci_signal_contract`（required_fields + run_mode tier_requirements + contract failure 门限）。
    - `approval_workflow.required_report_sections` 补充 `Stability Scoring` / `Convergence Dashboard` / `CI Signal Contract`。
  - `run_visual_snapshot_regression.gd` 升级：
    - 新增 D37 sanitize 链路：`_sanitize_stability_scoring`、`_sanitize_stability_tiers`、`_sanitize_convergence_dashboard`、`_sanitize_ci_signal_contract`。
    - 新增 D37 评估链路：`_evaluate_stability_scoring`、`_evaluate_convergence_dashboard`、`_evaluate_ci_signal_contract`。
    - 新增 tier 解析与等级比较：`_resolve_stability_tier`、`_tier_rank`。
    - 报告输出新增 3 个分段与 summary 行：`Stability Scoring`、`Convergence Dashboard`、`CI Signal Contract`。
    - 结构化信号继续写入 `user://visual_snapshot_latest.json`，保持 CI 消费路径兼容。
  - `validate_configs.py`、`check_resources.py`、`test_visual_snapshot_targets.gd` 已补齐 D37 schema/结构/一致性护栏（v13 channel + scoring/tiers/dashboard/ci contract + report section 对齐 + 与 release gate bindings 引用约束）。
- 验收结果：
  - `python scripts/tools/check_json_syntax.py` 通过（20 files）
  - `python scripts/validate_configs.py` 通过（18 JSON）
  - `python scripts/check_resources.py` 通过
  - `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/unit -ginclude_subdirs -gexit` 待执行（当前环境无 `godot` 命令）
- 结论：D37 已将可视回归链路从“发布候选追踪”推进到“稳定性分层评分 + 审批收敛看板 + CI 信号契约”阶段，下一步可进入 D38（收敛趋势强化与异常生命周期联动治理）。

### D38：收敛趋势强化与异常生命周期联动治理（已完成）

- 已完成文件：
  - `data/balance/visual_snapshot_targets.json`
  - `scripts/tools/run_visual_snapshot_regression.gd`
  - `scripts/validate_configs.py`
  - `scripts/check_resources.py`
  - `test/unit/test_visual_snapshot_targets.gd`
  - `spec-design/development-plan-supplement-2026-03-20-session.md`
  - `spec-design/README.md`
  - `spec-design/truth-check-2026-03-20.md`
- 已落地：
  - `visual_snapshot_targets.json` 升级为 `chapter_snapshot_v14`：
    - 新增 `convergence_trend_reinforcement`（long/short window 趋势对比、required_metrics、worsening/improving 阈值、trend failure 门限）。
    - 新增 `exception_lifecycle_linkage`（required_states、stale idle 阈值、transition 下限、orphan/unlinked/linkage failure 门限）。
    - `approval_workflow.required_report_sections` 补充 `Convergence Trend Reinforcement` / `Exception Lifecycle Linkage`。
  - `run_visual_snapshot_regression.gd` 升级：
    - 新增 D38 sanitize 链路：`_sanitize_convergence_trend_reinforcement`、`_sanitize_exception_lifecycle_linkage`。
    - 新增 D38 评估链路：`_evaluate_convergence_trend_reinforcement`、`_evaluate_exception_lifecycle_linkage`，并增加 `_metric_stats_from_history` 辅助。
    - 扩展归档记录字段：在 `approval_history_archive` 记录中补写 `tracking_failures` / `dashboard_failures` / `contract_failures` / `stability_score` / `stability_tier`，用于趋势窗口评估。
    - 报告输出新增 2 个分段与 summary 行：`Convergence Trend Reinforcement`、`Exception Lifecycle Linkage`。
  - `validate_configs.py`、`check_resources.py`、`test_visual_snapshot_targets.gd` 已补齐 D38 schema/结构/一致性护栏（v14 channel + trend/linkage 字段范围 + history/ci/tier/exception lifecycle 关联约束）。
- 验收结果：
  - `python scripts/tools/check_json_syntax.py` 通过（20 files）
  - `python scripts/validate_configs.py` 通过（18 JSON）
  - `python scripts/check_resources.py` 通过
  - `python -m py_compile scripts/validate_configs.py scripts/check_resources.py` 通过
  - `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/unit -ginclude_subdirs -gexit` 待执行（当前环境无 `godot` 命令）
- 结论：D38 已将可视回归链路从“评分/看板/契约化信号”推进到“跨窗口收敛趋势强化 + 例外生命周期联动治理”阶段，下一步可进入 D39（视觉门禁与性能基线联评）。

### D39：视觉门禁与性能基线联评（已完成）

- 已完成文件：
  - `data/balance/visual_snapshot_targets.json`
  - `scripts/tools/run_visual_snapshot_regression.gd`
  - `scripts/validate_configs.py`
  - `scripts/check_resources.py`
  - `test/unit/test_visual_snapshot_targets.gd`
  - `spec-design/development-plan-supplement-2026-03-20-session.md`
  - `spec-design/README.md`
  - `spec-design/truth-check-2026-03-20.md`
- 已落地：
  - `visual_snapshot_targets.json` 升级为 `chapter_snapshot_v15`：
    - 新增 `visual_performance_cogate`（baseline report 路径、run_mode 约束、alerts 阈值、场景失败上限、frame/memory ratio 比例门限、co-gate failure 门限）。
    - `approval_workflow.required_report_sections` 补充 `Visual-Performance Co-Gate`。
  - `run_visual_snapshot_regression.gd` 升级：
    - 新增 D39 sanitize 链路：`_sanitize_visual_performance_cogate`（自动对齐 `release_gate_templates.required_reports` 中的 `quality_baseline_latest.json`）。
    - 新增 D39 评估链路：`_evaluate_visual_performance_cogate` 与 `_index_baseline_scenarios`，联评 `alerts` 与场景 frame/memory 比例阈值，输出 `scenario_failures` / `cogate_failures`。
    - 扩展 `approval_history_archive` 归档记录：补写 `performance_cogate_failures` / `performance_scenario_failures` / `performance_alert_total` / `performance_alert_critical` / `performance_alert_warning`。
    - 报告输出新增 `Visual-Performance Co-Gate` 分段与 summary 汇总行。
  - `validate_configs.py`、`check_resources.py`、`test_visual_snapshot_targets.gd` 已补齐 D39 schema/结构/一致性护栏（v15 channel + co-gate 字段范围 + baseline report/ci_mode_bindings/release checklist 引用约束）。
- 验收结果：
  - `python scripts/tools/check_json_syntax.py` 通过（20 files）
  - `python scripts/validate_configs.py` 通过（18 JSON）
  - `python scripts/check_resources.py` 通过
  - `python -m py_compile scripts/validate_configs.py scripts/check_resources.py` 通过
  - `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/unit -ginclude_subdirs -gexit` 待执行（当前环境无 `godot` 命令）
- 结论：D39 已将可视回归链路从“趋势强化 + 生命周期联动”推进到“视觉门禁与性能基线联评”阶段，下一步可进入 D40（联评阈值模板化与跨平台对齐治理）。

### D40：联评阈值模板化与跨平台对齐治理（已完成）

- 已完成文件：
  - `data/balance/visual_snapshot_targets.json`
  - `scripts/tools/run_visual_snapshot_regression.gd`
  - `scripts/validate_configs.py`
  - `scripts/check_resources.py`
  - `test/unit/test_visual_snapshot_targets.gd`
  - `spec-design/development-plan-supplement-2026-03-20-session.md`
  - `spec-design/README.md`
  - `spec-design/truth-check-2026-03-20.md`
- 已落地：
  - `visual_snapshot_targets.json` 升级为 `chapter_snapshot_v16`：
    - 新增 `cogate_threshold_templates`（按 run_mode 映射 co-gate 阈值模板，支持 default + mode 覆盖）。
    - 新增 `cross_platform_alignment`（窗口聚合、required run modes/backends、metric delta 阈值与缺失上限）。
    - `approval_workflow.required_report_sections` 补充 `Co-Gate Threshold Template` 与 `Cross-Platform Alignment`。
  - `run_visual_snapshot_regression.gd` 升级：
    - 新增模板链路：`_sanitize_cogate_threshold_templates`、`_resolve_cogate_threshold_template`、`_evaluate_cogate_threshold_template`。
    - 新增跨平台对齐链路：`_sanitize_cross_platform_alignment`、`_evaluate_cross_platform_alignment`。
    - D39 co-gate 评估改为消费模板解析后的阈值配置，并将模板状态写入 `cogate_template` 报告段。
    - `approval_history_archive` 继续写入 performance 归档字段，供跨平台窗口聚合评估消费。
    - 报告新增 `Co-Gate Threshold Template` / `Cross-Platform Alignment` 分段与 summary 汇总行。
  - `validate_configs.py`、`check_resources.py`、`test_visual_snapshot_targets.gd` 已补齐 D40 护栏（v16 channel + D40 两块 schema/结构/一致性约束 + section 对齐）。
- 验收结果：
  - `python scripts/tools/check_json_syntax.py` 通过
  - `python scripts/validate_configs.py` 通过
  - `python scripts/check_resources.py` 通过
  - `python -m py_compile scripts/validate_configs.py scripts/check_resources.py` 通过
  - `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/unit -ginclude_subdirs -gexit` 待执行（当前环境无 `godot` 命令）
- 结论：D40 已将可视回归链路从“视觉-性能联评”推进到“联评阈值模板化 + 跨平台窗口对齐治理”阶段，下一步可进入 D41（高压场景性能压测标准化与对齐看板细化）。

### D41：高压场景性能压测标准化与对齐看板细化（已完成）

- 已完成文件：
  - `data/balance/visual_snapshot_targets.json`
  - `scripts/tools/run_visual_snapshot_regression.gd`
  - `scripts/validate_configs.py`
  - `scripts/check_resources.py`
  - `test/unit/test_visual_snapshot_targets.gd`
  - `spec-design/development-plan-supplement-2026-03-20-session.md`
  - `spec-design/README.md`
  - `spec-design/truth-check-2026-03-20.md`
- 已落地：
  - `visual_snapshot_targets.json` 升级为 `chapter_snapshot_v17`：
    - 新增 `pressure_scenario_standardization`（高压场景标准化：baseline targets/report、required run modes/scenarios、avg/p95/memory ratio 门限、failure 上限）。
    - 新增 `alignment_dashboard_refinement`（对齐看板细化：metric_weights、missing 权重、watch/critical 阈值、dashboard failure 上限）。
    - `approval_workflow.required_report_sections` 补充 `Pressure Scenario Standardization` 与 `Alignment Dashboard Refinement`。
  - `run_visual_snapshot_regression.gd` 升级：
    - 新增 D41 sanitize 链路：`_sanitize_pressure_scenario_standardization`、`_sanitize_alignment_dashboard_refinement`。
    - 新增 D41 评估链路：`_evaluate_pressure_scenario_standardization`、`_evaluate_alignment_dashboard_refinement`，并接入 D40 之后的主评估链。
    - 新增 D41 报告分段与 summary 行：`Pressure Scenario Standardization` / `Alignment Dashboard Refinement`。
    - `approval_workflow` section 映射扩展到 D41 两段，保证审批分段完整性检查可覆盖 D41 新报告。
  - `validate_configs.py`、`check_resources.py`、`test_visual_snapshot_targets.gd` 已补齐 D41 护栏（v17 channel + D41 两块 schema/结构/一致性约束 + sections 对齐 + baseline/checklist/ci_mode_bindings/alignment metric 关联）。
- 验收结果：
  - `python scripts/tools/check_json_syntax.py` 通过
  - `python scripts/validate_configs.py` 通过
  - `python scripts/check_resources.py` 通过
  - `python -m py_compile scripts/validate_configs.py scripts/check_resources.py` 通过
  - `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/unit -ginclude_subdirs -gexit` 待执行（当前环境无 `godot` 命令）
- 结论：D41 已将可视回归链路从“阈值模板化 + 跨平台对齐”推进到“高压场景压测标准化 + 对齐看板细化”阶段，下一步可进入 D42（高压场景对齐收敛门禁与回归周期开窗治理）。

### D42：高压场景对齐收敛门禁与回归周期开窗治理（已完成）

- 已完成文件：
  - `data/balance/visual_snapshot_targets.json`
  - `scripts/tools/run_visual_snapshot_regression.gd`
  - `scripts/validate_configs.py`
  - `scripts/check_resources.py`
  - `test/unit/test_visual_snapshot_targets.gd`
  - `spec-design/development-plan-supplement-2026-03-20-session.md`
  - `spec-design/README.md`
  - `spec-design/truth-check-2026-03-20.md`
- 已落地：
  - `visual_snapshot_targets.json` 升级为 `chapter_snapshot_v18`：
    - 新增 `pressure_alignment_convergence_gate`（收敛门禁：对标准化失败、跨平台对齐失败、看板失败、critical 严重度计数进行汇总门禁）。
    - 新增 `regression_cycle_window_governance`（周期开窗治理：基于 archive 历史窗口的 warning/blocker/alignment score 漂移阈值与最小样本门禁）。
    - `approval_workflow.required_report_sections` 补充 `Pressure Alignment Convergence Gate` 与 `Regression Cycle Window Governance`。
  - `run_visual_snapshot_regression.gd` 升级：
    - 新增 D42 sanitize 链路：`_sanitize_pressure_alignment_convergence_gate`、`_sanitize_regression_cycle_window_governance`。
    - 新增 D42 评估链路：`_evaluate_pressure_alignment_convergence_gate`、`_evaluate_regression_cycle_window_governance`，并接入 D41 之后的主评估链。
    - `approval_workflow` section 映射扩展到 D42 两段，报告新增 `Pressure Alignment Convergence Gate` / `Regression Cycle Window Governance` 分段与 summary 行。
    - 周期开窗治理复用 `approval_history_archive` 历史记录中的 `warning/blocker/alignment_dashboard_score` 等指标做窗口差值评估。
  - `validate_configs.py`、`check_resources.py`、`test_visual_snapshot_targets.gd` 已补齐 D42 护栏（v18 channel + D42 两块 schema/结构/一致性约束 + section 对齐 + run_mode/backend/archive 关联）。
- 验收结果：
  - `python scripts/tools/check_json_syntax.py` 通过
  - `python scripts/validate_configs.py` 通过
  - `python scripts/check_resources.py` 通过
  - `python -m py_compile scripts/validate_configs.py scripts/check_resources.py` 通过
  - `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/unit -ginclude_subdirs -gexit` 待执行（当前环境无 `godot` 命令）
- 结论：D42 已将可视回归链路从“高压场景标准化 + 对齐看板细化”推进到“对齐收敛门禁 + 回归周期开窗治理”阶段，下一步可进入 D43（多周期自适应门禁与发布回灌治理）。

### D43：多周期自适应门禁与发布回灌治理（已完成）

- 已完成文件：
  - `data/balance/visual_snapshot_targets.json`
  - `scripts/tools/run_visual_snapshot_regression.gd`
  - `scripts/validate_configs.py`
  - `scripts/check_resources.py`
  - `test/unit/test_visual_snapshot_targets.gd`
  - `session-(angel-fallen)-20260321-2.md`
  - `spec-design/README.md`
  - `spec-design/development-plan-2026-03-20.md`
  - `spec-design/truth-check-2026-03-20.md`
- 已落地：
  - `visual_snapshot_targets.json` 升级为 `chapter_snapshot_v19`：
    - 新增 `multi_cycle_adaptive_gate`（多周期自适应门禁：基于 archive 历史 short/mid/long 窗口的 warning/blocker 斜率、run_mode/backend 覆盖缺口与 adaptive failure 总量进行治理）。
    - 新增 `release_feedback_governance`（发布回灌治理：基于反馈窗口中的 issue metrics、closure rate、未闭环数量与 coverage 缺口进行闭环治理）。
    - `approval_workflow.required_report_sections` 补充 `Multi-Cycle Adaptive Gate` 与 `Release Feedback Governance`。
  - `run_visual_snapshot_regression.gd` 升级：
    - 新增 D43 sanitize 链路：`_sanitize_multi_cycle_adaptive_gate`、`_sanitize_release_feedback_governance`。
    - 新增 D43 评估链路：`_evaluate_multi_cycle_adaptive_gate`、`_evaluate_release_feedback_governance`，并补充 `_extract_metric_series`、`_calculate_series_slope`、`_is_feedback_clean_row` 等辅助逻辑。
    - `approval_workflow` section 映射扩展到 D43 两段，报告新增 `Multi-Cycle Adaptive Gate` / `Release Feedback Governance` 分段与 summary 行。
    - D43 评估复用 `approval_history_archive` 中已有的 warning/blocker/alignment/performance/pressure 指标归档，不额外引入新的归档格式。
  - `validate_configs.py`、`check_resources.py`、`test_visual_snapshot_targets.gd` 已补齐 D43 护栏（v19 channel + D43 两块 schema/结构/一致性约束 + run_mode/backend/history/section 对齐）。
- 验收结果：
  - `python scripts/validate_configs.py` 通过
  - `python scripts/check_resources.py` 通过
  - `python -m py_compile scripts/validate_configs.py scripts/check_resources.py` 通过
  - `"C:/software/Godot/Godot Engine/Godot_v4.6.1-stable_win64.exe" --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://test/unit -ginclude_subdirs -gexit` 通过（46 tests / 6161 assertions）
- 结论：D43 已将可视回归链路从“对齐收敛门禁 + 回归周期开窗治理”推进到“多周期自适应门禁 + 发布回灌治理”阶段，当前正式文档已与代码实现追平；后续应优先转入发布闭环最小化与 MVP 缺口补齐，而不是继续追加 D44+ 治理层能力。

## 后续执行原则

- 优先保证“可回归、可验证”的增量，不做大规模不可回溯重构。
- 每轮扩容后先跑配置校验，再推进下一层（测试 -> 表现）。
- 文档承诺与实现状态需持续同步更新，避免目标漂移。
- 每完成一个子阶段，必须同时更新：`spec-design/truth-check-2026-03-20.md`、本计划文档、`spec-design/README.md` 索引。
