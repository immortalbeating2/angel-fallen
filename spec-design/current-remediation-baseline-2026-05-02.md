# Angel Fallen 当前整改基线 2026-05-02

## 结论

当前阶段的整改基线已完成主要自动化收口，可作为 Stage 7 剩余未开发内容的执行前置。以 `remaining-game-content-checklist-2026-03-22.md`、`full-development-remaining-checklist-2026-03-22.md`、`full-game-content-plan-2026-03-22.md` 和本次核对结果为准，Stage 5 与 Stage 6 已作为历史完成状态承接。后续主线转入 Stage 7：音频/视觉成品化、运行时接入、联合回归、长局平衡与最终发布验收。

本文件是 `2026-5-2-plan.md` 的整改基线快照，不替代后续验收记录。凡是尚未通过 Godot MCP 辅助复核、人工实机复核或导出包 smoke 的体验项，都保持“未执行”或“待执行”。

## 本次核对范围

| 项目 | 结果 | 备注 |
|------|------|------|
| 当前 HEAD | `8db5bf0` | 仅作为本轮文档整理与 MCP 辅助复核的核对基准 |
| `python scripts/tools/check_json_syntax.py` | 通过 | 20 个 JSON 文件语法检查通过 |
| `python scripts/validate_configs.py` | 通过 | 18 个 JSON 配置语义检查通过 |
| `python scripts/check_resources.py` | 通过 | 基础资源结构检查通过 |
| `python scripts/tools/sync_resource_stubs.py` | 通过 | catalog 重建后计数为 characters=13、weapons=16、evolutions=14、forge_recipes=14 |
| `resources/resource_catalog.json` 目标 ID 覆盖 | 通过 | 4 个 Stage 6 最小内容包 ID 已进入 catalog |
| `godot --headless --path . --quit` | 通过 | Godot 4.6.2 无头启动通过 |
| `godot --headless --path . -s res://scripts/tools/run_resource_acceptance.gd` | 通过 | `Resource acceptance complete -> blockers: 0, warnings: 0` |
| `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://test -ginclude_subdirs -gexit` | 通过 | 30 个脚本、127 个测试、8583 个断言全部通过 |
| `git lfs status` | 已分批收口 | 7 个场景文件、插件、`project.godot`、项目级 MCP 配置与 Codex 配置均已按阶段提交 |
| Godot MCP 辅助复核 / 长局 / 导出包 smoke | 本轮全游戏工具化复核已完成 | 已确认 Godot editor 连接 MCP；主菜单、设置面板、Archive/Codex、新局进入 GameWorld、战斗房、升级、商店、事件、章节转场、死亡结算返回、MCP 构造 Boss 生成、三结局结算、FS1/FS2、CL1-CL4、导出包最小 smoke 均已完成记录 |

## 资源 Catalog 差异

| ID | balance 真源 | `.tres` 资源桩 | `resources/resource_catalog.json` | 处理状态 |
|----|--------------|----------------|-----------------------------------|----------|
| `char_curator` | 已存在于 `data/balance/characters.json` | 已存在于 `resources/characters/char_curator.tres` | 已收录 | 已同步 |
| `wpn_reliquary_orb` | 已存在于 `data/balance/shop_items.json` 与角色起始武器引用 | 已存在于 `resources/weapons/wpn_reliquary_orb.tres` | 已收录 | 已同步 |
| `evo_zenith_reliquary` | 已存在于 `data/balance/evolutions.json` | 已存在于 `resources/evolutions/evo_zenith_reliquary.tres` | 已收录 | 已同步 |
| `forge_zenith_reliquary` | 已存在于 `data/balance/resource_acceptance_targets.json` | 已存在于 `resources/forge_recipes/forge_zenith_reliquary.tres` | 已收录 | 已同步 |

## 已知阻塞与风险

| 优先级 | 项目 | 当前判断 | 下一步 |
|--------|------|----------|--------|
| P0 | 资源 catalog 漂移 | 已通过同步脚本修复，资源验收回绿 | 后续新增内容 ID 时继续通过同步脚本重建 catalog |
| P0 | LFS 与工作区脏状态 | 已按阶段提交拆分处理，场景归一化、Godot MCP 插件、项目级 MCP 配置与 Codex 配置均已单独落地 | 后续继续保持小提交边界 |
| P0 | Godot/GUT 复跑 | 已补跑并通过 Godot 启动、资源验收、全量 GUT | 若后续处理 LFS 或插件变更，需再次跑相邻验证 |
| P0 | 战斗房死亡/结算阻塞 | 已修复。根因是 `HealthComponent` 使用场景 `owner` 判断生命归属，主场景中玩家生命组件 `owner` 指向 `GameWorld`，导致 `player_died` 未发出；现改为运行时父节点并补回归测试 | 保留截图与测试证据；后续复核真实移动、Boss 击败和章节转场 |
| P1 | Godot MCP 辅助复核缺口 | 已完成本轮可工具化复核项；真实移动/战斗手感、音频听感与长局平衡属于主观体验，不由 MCP/无头工具判定 | 后续若进入平衡或资产成品化阶段，再执行真实长局录像与听感记录 |
| P1 | 导出包 smoke 缺口 | 已安装 Godot `4.6.2.stable` export templates，Windows debug 最新包生成成功，`angel-fallen.exe --headless --quit` 启动退出码为 0；真实窗口启动 8 秒未崩溃；导出日志仍有插件/示例资源 export-time 报错噪声 | 发布前可继续清理导出噪声来源 |
| P1 | `ControllerIcons` 兼容风险 | Godot 4.6.2 无头启动未被插件阻断 | 后续保留编辑器、MCP 操作与导出层面的观察项 |
| P1 | 类幸存者战斗表现层 | 2026-05-03 已新增环绕武器、持续光环、地面持续伤害区、命中/击杀/拾取占位音效入口，并补回归测试 | 当前仍为程序化占位视觉/音频；Stage 7 资产接入与长局平衡时继续替换和调优 |

## Stage 7 执行前置状态

- [x] `resources/resource_catalog.json` 收录 4 个缺失 ID，并通过资源验收。
- [x] `godot --headless --path . --quit` 通过，确认插件和项目解析没有阻断。
- [x] GUT 全量或计划指定范围通过，并记录失败项或豁免理由。
- [x] `git lfs status` 中场景文件状态被明确处理，不再作为长期脏状态遗留。
- [x] 插件与 `project.godot` 的既有变更完成来源确认并单独收口。
- [x] Godot MCP bridge 在编辑器打开后确认 `isGodotConnected=true`。
- [x] Godot MCP 辅助 ledger 至少完成 Windows 启动、主菜单、新局到首个 Boss、一次结局流程、FS/CL 入口和音量设置的首轮记录。当前已完成 Windows 编辑器侧启动、主菜单、音量设置、Archive/Codex、新局进入 GameWorld、战斗房、升级、商店、事件、章节转场、死亡结算返回、MCP 构造 Boss 生成、三结局结算、FS1/FS2、CL1-CL4。
- [x] 导出包最小 smoke 完成 `MR-EXPORT-001`。

## Stage 7 下一步

- S7-1：按 Stage 7 首批任务清单产出背景、UI、图标与音频提示词母版候选，并填写 intake ledger。
- S7-2：将通过筛选的低耦合资产推进到 `production_ready` 或 `runtime_final`，补资源验收与 Godot MCP 辅助复核。
- S7-3 以后：再处理角色、敌人、武器、Boss、结局/隐藏层/挑战层专属表现，避免高耦合资产过早接入造成返工。2026-05-03 已先补通武器表现运行时接口，后续正式资产可优先替换 `OrbitWeapon`、`AuraWeapon`、`GroundHazardZone`、拾取/击杀/命中 SFX 的占位表现。
