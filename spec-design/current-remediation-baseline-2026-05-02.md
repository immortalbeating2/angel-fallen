# Angel Fallen 当前整改基线 2026-05-02

## 结论

当前阶段先做整改基线收口，不进入 Stage 7 资产批量生产。以 `remaining-game-content-checklist-2026-03-22.md`、`full-game-content-plan-2026-03-22.md` 和本次核对结果为准，Stage 5 与 Stage 6 已作为历史完成状态承接。自动化阻塞已初步清理，Stage 7 仍需等 LFS 状态和人工复核记录补齐后再正式开跑。

本文件是 `2026-5-2-plan.md` 的初步执行跟踪快照，不替代后续验收记录。凡是尚未人工实机复核的体验项，都保持“未执行”或“待执行”。

## 本次核对范围

| 项目 | 结果 | 备注 |
|------|------|------|
| 当前 HEAD | `3e5b041` | 仅作为本轮文档整理的核对基准 |
| `python scripts/tools/check_json_syntax.py` | 通过 | 20 个 JSON 文件语法检查通过 |
| `python scripts/validate_configs.py` | 通过 | 18 个 JSON 配置语义检查通过 |
| `python scripts/check_resources.py` | 通过 | 基础资源结构检查通过 |
| `python scripts/tools/sync_resource_stubs.py` | 通过 | catalog 重建后计数为 characters=13、weapons=16、evolutions=14、forge_recipes=14 |
| `resources/resource_catalog.json` 目标 ID 覆盖 | 通过 | 4 个 Stage 6 最小内容包 ID 已进入 catalog |
| `godot --headless --path . --quit` | 通过 | Godot 4.6.2 无头启动通过 |
| `godot --headless --path . -s res://scripts/tools/run_resource_acceptance.gd` | 通过 | `Resource acceptance complete -> blockers: 0, warnings: 0` |
| `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://test -ginclude_subdirs -gexit` | 通过 | 30 个脚本、126 个测试、8576 个断言全部通过 |
| `git lfs status` | 部分处理 | 7 个场景文件已完成 `git add --renormalize` 并进入 `Objects to be committed`；插件与 `project.godot` 仍显示既有未暂存变更 |
| 人工 smoke / 长局 / 导出包复核 | 未执行 | 已建立 ledger 模板，等待真实执行记录 |

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
| P0 | LFS 与工作区脏状态 | 7 个 `.tscn` 已按 LFS 规则归一化并暂存；插件与 `project.godot` 仍是未确认来源的既有变更 | 场景归一化随本阶段提交落地；插件与项目配置另开边界确认 |
| P0 | Godot/GUT 复跑 | 已补跑并通过 Godot 启动、资源验收、全量 GUT | 若后续处理 LFS 或插件变更，需再次跑相邻验证 |
| P1 | 人工复核缺口 | 旧文档有发布 smoke 记录，但当前 Stage 6/7 切换前缺少新的人工 ledger | 使用 `manual-review-ledger-2026-05-02.md` 执行首轮记录 |
| P1 | `ControllerIcons` 兼容风险 | Godot 4.6.2 无头启动未被插件阻断 | 后续保留编辑器/导出层面的观察项 |

## Stage 7 进入条件

- [x] `resources/resource_catalog.json` 收录 4 个缺失 ID，并通过资源验收。
- [x] `godot --headless --path . --quit` 通过，确认插件和项目解析没有阻断。
- [x] GUT 全量或计划指定范围通过，并记录失败项或豁免理由。
- [x] `git lfs status` 中场景文件状态被明确处理，不再作为长期脏状态遗留。
- [ ] 插件与 `project.godot` 的既有变更完成来源确认或单独收口。
- [ ] 人工复核 ledger 至少完成 Windows 启动、主菜单、新局到首个 Boss、一次结局流程和导出包启动的首轮记录。
