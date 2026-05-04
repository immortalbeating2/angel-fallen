# Angel Fallen 人工复核测试用例 2026-05-02

## 目的

本文件用于承接当前已经完成的 Stage 1-6 游戏开发内容，并为 Stage 7 成品化前后的人工复核建立统一测试用例。执行结果记录到 `spec-design/manual-review-ledger-2026-05-02.md`，截图、录像和日志统一归档到 `test/manual_review_evidence/<执行日期>/`。

本清单只定义人工/MCP 复核用例，不替代 GUT、配置校验、资源验收和导出 smoke。Godot MCP 可用于打开场景、运行场景、点击 UI、抓取运行树和截图；导出包、长局手感、音频听感、构筑体验仍必须由真实人工执行确认。

## 执行准备

| 项目 | 要求 |
|------|------|
| 自动化前置 | `check_json_syntax.py`、`validate_configs.py`、`check_resources.py`、Godot headless、全量 GUT、resource acceptance 均通过 |
| MCP 前置 | `get_bridge_status` 返回 `isGodotConnected=true` |
| 证据目录 | `test/manual_review_evidence/2026-05-02/` |
| 基线版本 | 记录 `git rev-parse --short HEAD` 与 Godot 版本 |
| 存档策略 | 普通 smoke 使用当前用户存档；FS/CL/三结局用例建议准备解锁存档或通过调试/测试入口构造状态 |

## Core Loop / 主流程

| ID | 模块 | 前置条件 | 操作步骤 | 预期结果 | 建议证据 | MCP 辅助 | 必须人工/实机 |
|----|------|----------|----------|----------|----------|----------|--------------|
| MR-CORE-001 | 主菜单启动 | Godot editor 或导出包可启动 | 启动游戏进入主菜单 | 无崩溃；显示 `angel-fallen`；Start、Settings、Codex、Archive/Meta Shop 入口可见 | 主菜单截图、运行树 | `play_scene`、`find_ui_elements`、`get_game_screenshot` | 导出包版本必须实机 |
| MR-CORE-002 | 角色浏览 | 至少有默认角色；如需全角色，准备三结局解锁存档 | 点击 Prev/Next 浏览至少 3 个角色 | 角色名、描述、属性、解锁状态刷新；锁定角色不能直接开始 | 每个角色截图或短视频 | `click_button_by_text`、`find_ui_elements` | 是，需人工确认可读性 |
| MR-CORE-003 | 新局进入战斗 | 选择可用角色 | 点击 Start，进入游戏世界 | 场景切到 GameWorld；玩家、HUD、房间状态出现；无启动错误 | 运行树、HUD 截图 | `click_button_by_text("Start")`、`get_game_scene_tree` | MCP 可初验，实机需补 |
| MR-CORE-004 | 基础战斗交互 | 已进入战斗房 | 移动、等待自动攻击、拾取经验/金币/矿石、受到一次伤害 | 玩家可移动；自动武器发射；拾取反馈与 HUD 数值变化；受伤反馈可读 | 战斗短视频、HUD 前后截图 | `simulate_action`、`get_game_node_properties` | 是，手感需人工 |
| MR-CORE-005 | 升级选择 | 通过经验达到升级 | 触发升级面板，选择任意升级 | 升级选项可见；选择后面板关闭；属性/武器反馈生效 | 升级面板截图 | `find_ui_elements`、`click_button_by_text` | 是 |
| MR-CORE-006 | 房间推进 | 当前房间可清理 | 清理房间，进入下一房间或打开门 | 房间状态显示 cleared；门/下一房间可进入；章节提示继续推进 | 房间 cleared 截图 | `get_game_scene_tree`、截图 | 是 |
| MR-CORE-007 | 商店/事件交互 | 遇到商店或事件房 | 完成至少一次购买、选择或关闭 | UI 可打开/关闭；资源扣除或选择结果正确；流程不卡死 | 交互前后截图 | `click_button_by_text`、`find_ui_elements` | 是 |
| MR-CORE-008 | Boss 与章节转场 | 推进到第 1 个 Boss | 击败 Boss，进入章节转场 | Boss 出现并可交战；击败后显示章节转场、路线/碎片/下一章提示 | Boss 战与转场截图/视频 | `get_game_scene_tree`、截图 | 是 |
| MR-CORE-009 | 结算与返回菜单 | 通关、死亡或撤退任一分支 | 触发结算页，点击返回菜单 | 结算页显示 outcome、奖励、解锁、路线/挑战摘要；返回主菜单后 Last Run 更新 | 结算页和 Last Run 截图 | `click_button_by_text`、`get_game_scene_tree` | 是 |
| MR-CORE-010 | 存档重载 | 完成一次结算或改设置 | 退出并重启，再进主菜单 | Meta、Last Run、设置项保持；无坏档 | 重启前后截图 | MCP 可辅助，导出包需实机 | 是 |

## Stage 5 叙事 / 营地 / 结局

| ID | 模块 | 前置条件 | 操作步骤 | 预期结果 | 建议证据 | MCP 辅助 | 必须人工/实机 |
|----|------|----------|----------|----------|----------|----------|--------------|
| MR-S5-001 | 路线弧线与营地反思 | 进入安全营地或章节转场前后 | 触发不同路线选择，进入营地 | 营地文本包含路线回显、fragment progress、camp loop 或后续提示 | 营地文本截图 | `play_scene`、`get_game_node_properties` | 是，需读感确认 |
| MR-S5-002 | 章节转场叙事 | 击败章节 Boss | 查看章节转场面板并确认选择 | 面板包含 route echo、forward note、hidden progress、fragment recap、camp loop、hazard/effect forecast | 转场面板截图 | `find_ui_elements`、截图 | 是 |
| MR-S5-003 | 三结局 Balance | 准备 neutral / balance 结局存档或完成对应路线 | 完成 run 并查看结算 | 显示 `nar_ending_balance` payoff、epilogue chain、首次/重复解锁差异 | 结算页截图 | `get_game_scene_tree` | 是 |
| MR-S5-004 | 三结局 Redeem | 准备 vanguard / redeem 结局存档或完成对应路线 | 完成 run 并查看结算 | 显示 `nar_ending_redeem` payoff、epilogue、archive hook；重复解锁不重复计数 | 结算页、Ending Archive 截图 | 同上 | 是 |
| MR-S5-005 | 三结局 Fall | 准备 rebel / fall 结局存档或完成对应路线 | 完成 run 并查看结算 | 显示 `nar_ending_fall` payoff、epilogue、fragment hook | 结算页、Ending Archive 截图 | 同上 | 是 |
| MR-S5-006 | Fragment Recap | 准备已触发记忆碎片的 run | 查看结算、Memory Archive、记忆祭坛 | fragment recap、trigger counts、route echo、review entry 可见 | 三处截图 | `click_button_by_text("Archive")`、截图 | 是 |
| MR-S5-007 | Hidden Layer Hook / Status | 准备三结局或隐藏层前置进度 | 查看结算、主菜单 Last Run、记忆祭坛/Hidden Layer Track | FS1/FS2 hook、story、status、entry/reward/settlement 摘要可见 | 多入口截图 | MCP 可打开与截图 | 是 |
| MR-S5-008 | 回看入口 | 已解锁 fragment/ending | 点击 Archive、Codex、Review Fragment / Review Ending | 可翻页；内容更新；关闭后返回主菜单不阻塞 | 操作视频 | `click_button_by_text`、`find_ui_elements` | 是 |

## Stage 6 隐藏层 / 挑战层 / 后期回流

| ID | 模块 | 前置条件 | 操作步骤 | 预期结果 | 建议证据 | MCP 辅助 | 必须人工/实机 |
|----|------|----------|----------|----------|----------|----------|--------------|
| MR-S6-001 | FS1 入口 | 准备 FS1 解锁存档 | 在安全营地确认 `R: Enter Time Rift`，进入 FS1 | 进入 FS1 combat room；room plan 标记 FS1；状态显示 Time Rift/echo/archive 信息 | 营地与 FS1 截图 | `simulate_key(KEY_R)`、运行树 | 是 |
| MR-S6-002 | FS1 结算归档 | FS1 已进入并可完成 | 完成 FS1 或触发 victory settlement | 结算包含 hidden_layer_record、echo progress、ending link、fragment preview/text | 结算截图 | MCP 辅助截图 | 是 |
| MR-S6-003 | FS2 入口 | 准备 FS2 解锁存档 | 在安全营地确认 `Y: Enter Genesis Forge`，进入 FS2 | FS2 从房间 1 开始；Forge Trial I-V 顺序推进；每房间 trial label 正确 | 房间序列截图/视频 | `simulate_key(KEY_Y)` | 是 |
| MR-S6-004 | FS2 Forge Settlement | 完成 FS2 Boss | 查看 settlement 与奖励 | 显示 Forge Settlement、Trial V、Collection 5/5、recipe drafts/relic merges、Archive clear 提示 | settlement 和结算截图 | MCP 辅助 | 是 |
| MR-S6-005 | CL1 入口/失败路径 | 准备挑战层解锁存档 | 进入 CL1，主动失败或死亡 | 失败也归档 attempt；无奖励；主菜单 Last Run 和安全营地预览显示失败摘要 | 失败结算/Last Run 截图 | MCP 辅助 | 是 |
| MR-S6-006 | CL1 奖励分支 | 准备 CL1 settlement | 依次验证 Meta Cache、Sigil Bundle、Archive Insight 至少一项 | 奖励标题、summary、ledger、Last Reward 正确；非 Meta 奖励不会污染全局 Meta | settlement/结算截图 | `click_button_by_text` | 是 |
| MR-S6-007 | CL2 闭环 | Archive Return 已解锁 | 进入 CL2，完成 Entry -> Elite -> Boss -> Settlement | CL2 preview、hotkey `I`、Deep Meta/Sigil/Insight 奖励、challenge record 正确 | 全流程截图/视频 | `simulate_key(KEY_I)` | 是 |
| MR-S6-008 | CL3 闭环 | CL2 已清档 | 进入 CL3，完成 Entry -> Elite -> Combat -> Boss -> Settlement | hotkey `O`、五段流程、第三档奖励、Archive 回显正确 | 全流程截图/视频 | `simulate_key(KEY_O)` | 是 |
| MR-S6-009 | CL4 / Apex Return | CL3 已清档 | 进入 CL4，完成 Entry -> Elite -> Combat -> Elite -> Boss -> Settlement | hotkey `P`、Apex settlement、Apex Return 解锁、Return x1.60 相关回显正确 | 全流程截图/视频 | `simulate_key(KEY_P)` | 是 |
| MR-S6-010 | Archive Return 长期回流 | FS/CL 复清状态已准备 | 查看安全营地、结算、主菜单 Archive/Codex | Archive Return Protocol、Challenge Layer Archive、Reward Ledger、recent source 可见 | 多入口截图 | `click_button_by_text("Codex")` | 是 |
| MR-S6-011 | 成就矩阵 | 准备隐藏层复清与 CL1-CL4 清档存档 | 查看主菜单 Achievements / Archive | Archive Return、CL1、CL2、CL3、CL4 成就出现在 Challenge Layer 分组 | 成就列表截图 | MCP 查 UI | 是 |
| MR-S6-012 | 最小内容包 | 当前资源 catalog 已同步 | 在主菜单角色/资源验收入口确认 `char_curator`，运行中确认 `wpn_reliquary_orb` / `evo_zenith_reliquary` 相关文本或资源引用 | 角色、武器、进化、forge recipe 不缺资源；无占位缺失报错 | 资源验收日志、角色/武器截图 | `run_resource_acceptance.gd`、MCP 截图 | 部分人工 |

## Stage 7 成品化 / 资产 / 发布

| ID | 模块 | 前置条件 | 操作步骤 | 预期结果 | 建议证据 | MCP 辅助 | 必须人工/实机 |
|----|------|----------|----------|----------|----------|----------|--------------|
| MR-S7-001 | 资产 intake | 首批候选资产生成完成 | 按 A1-A4、B1-B3、C1-C2、G1-G2 填 intake ledger | 每项有主选/备选、状态、来源提示词、目标目录 | intake ledger 截图或文档 diff | 无 | 是 |
| MR-S7-002 | UI/背景 runtime_final | 低耦合 UI/背景资源已接入 | 启动主菜单、Archive、Settings、结算页 | 新资产可见；无水印/文字污染；文本无遮挡；风格统一 | 前后截图 | MCP 截图 | 是 |
| MR-S7-003 | 音频正式替换 | BGM/SFX/Ambience 已接入 | 主菜单、营地、UI 点击、奖励/解锁各听一次 | 音频可循环；无爆音；音量设置生效；无歌词人声 | 录屏/音频备注 | MCP 只能确认节点/UI | 必须人工 |
| MR-S7-004 | 通用 VFX/Shader | effects/shaders 接入 | 触发奖励、解锁、记忆碎片、战斗反馈 | VFX 可读、不卡顿、不遮挡玩法 | 视频 | MCP 截图/帧捕获 | 是 |
| MR-S7-005 | 高耦合资产接入 | 角色/敌人/武器/Boss 资产进入候选或 runtime | 在战斗密度下观察轮廓和命中反馈 | 角色/敌人/武器不混淆，Boss 可读性高 | 战斗视频 | MCP 辅助 | 是 |
| MR-S7-006 | 长局平衡 | 完成至少 1 次长局 | 连续推进到后期或死亡/通关 | 节奏、掉落、难度、构筑深度可接受；问题可复现 | 长局录像、问题单 | MCP 可辅助截图 | 必须人工 |
| MR-S7-007 | 多构筑验证 | 至少 3 个角色/路线 | 分别跑武器、被动、进化路线 | 不同构筑有差异；无明显死路线或必崩组合 | 构筑记录表 | 无 | 必须人工 |
| MR-S7-008 | 导出包 smoke | 最新导出包已生成 | Windows 启动；如有目标环境，Linux/macOS 各启动一次 | 可进入主菜单、开始游戏、音频输出、退出正常 | 平台截图/日志 | MCP 不替代 | 必须导出包 |
| MR-S7-009 | 发布归档 | 自动化与 smoke 完成 | 汇总 SHA、Godot 版本、平台、自动化、人工结论 | 发布记录可追溯；阻塞项明确 | release record 文档 | 无 | 是 |

## 执行优先级

1. P0：`MR-CORE-001`、`MR-CORE-003`、`MR-CORE-009`、`MR-S6-001`、`MR-S6-007`、`MR-S6-009`、`MR-S7-008`。
2. P1：全部 Stage 5 叙事回看、FS2、CL3、成就/图鉴、音频设置与长局验证。
3. P2：资产 intake、视觉一致性、高耦合表现精修与多构筑体验记录。

## 当前已执行覆盖

- 已执行：`MR-CORE-001` 的编辑器侧主菜单启动、角色/商店/设置/Archive/Codex 子集、`MR-CORE-003` 的新局进入 GameWorld / 战斗房子集、`MR-CORE-004` 的运行态战斗可见子集、`MR-CORE-005` 升级面板、`MR-CORE-007` 商店购买、`MR-CORE-008` Boss 生成、`MR-CORE-009` 的死亡结算与三结局结算展示、`MR-S6-001` 至 `MR-S6-010` 的 MCP 构造入口/结算/回看子集、`MR-AUDIO-001`、`MR-EXPORT-001`，记录见 `manual-review-ledger-2026-05-02.md`。
- 已修复：战斗房中玩家 HP 降到 `0 / 146` 后仍显示 `PLAYING`、结算面板未出现的问题；已补 `test_player_lethal_damage_finishes_run_as_death` 回归测试，并用 MCP 留存死亡结算与返回主菜单截图。
- 已补充：通过 MCP 构造首个 Boss 生成状态，确认 `boss_rock_colossus` 运行时生命、缩放与生成可见；通过 MCP 构造 FS1/FS2 与 CL1-CL4 入口、失败/胜利结算、Archive/Codex 回看，确认 Archives 回看显示 `13/13`。
- 已补充：最新 Windows debug 导出包已生成，`--headless --quit` 退出码为 `0`，真实窗口启动 8 秒未崩溃。
- 工具边界：真实移动/战斗手感、音频听感与长局平衡属于主观体验，不由 MCP/无头工具判定；当前未发现代码级阻塞。
