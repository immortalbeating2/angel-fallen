# Stage 7 资产 Intake Ledger 模板（2026-03-24）

## 1. 目的

本文档用于给 Stage 7 的每一批资产建立统一收稿记录表，解决以下问题：

- 候选资产很多，但后续不知道哪一张是主选、哪一张是备选
- 提示词用了哪个档位、来自哪份文档，几天后就追不回
- 资产已经落到目录里，但不知道当前只是 `style_anchor` 还是已经到 `production_ready`
- 同一批资产分散在多个目录里，缺少统一追踪表

本文档与以下文档配套使用：

- `spec-design/stage7-gemini-first-batch-task-list-2026-03-24.md`
- `spec-design/stage7-three-tier-prompt-system-2026-03-24.md`
- `spec-design/stage7-asset-review-and-landing-workflow-2026-03-24.md`

## 2. 使用原则

- 一个批次至少保留一份 ledger。
- 每个任务至少记录：主选、备选、提示词档位、目标目录、当前状态。
- 如果某任务尚未通过筛选，也应记录为 `concept_candidate`，不要直接消失。
- 若同一任务多轮返工，建议在同一任务 ID 下递增版本号，而不是重命名任务 ID。

## 3. 状态枚举

建议统一使用以下 4 种状态：

- `concept_candidate`
- `style_anchor`
- `production_ready`
- `runtime_final`

定义以 `spec-design/stage7-asset-review-and-landing-workflow-2026-03-24.md` 为准。

## 4. 必填字段说明

| 字段 | 含义 | 示例 |
|---|---|---|
| `batch_id` | 当前批次 ID | `batch_stage7_01` |
| `task_id` | 任务卡 ID | `A1` |
| `asset_family` | 资产族 | `ui_background` |
| `asset_name` | 本次收稿项名 | `main_menu_background` |
| `prompt_tier` | 提示词档位 | `完整版` |
| `prompt_source` | 提示词来源文档 | `stage7-three-tier-prompt-system-2026-03-24.md` |
| `candidate_count` | 本轮候选数量 | `3` |
| `primary_pick` | 主选文件名 | `ui_bg_main_menu_ruined_halo_v1.png` |
| `backup_pick` | 备选文件名 | `ui_bg_main_menu_ruined_halo_v2.png` |
| `target_dir` | 目标目录 | `assets/sprites/ui/backgrounds/` |
| `current_status` | 当前状态 | `style_anchor` |
| `review_owner` | 当前评审人 | `design` |
| `review_date` | 评审日期 | `2026-03-24` |
| `next_action` | 下一动作 | `继续扩产` / `像素化` / `接入 UI` |
| `notes` | 备注 | `中心区域适合菜单覆盖` |

## 5. 通用空白模板

复制后直接填写：

```md
| batch_id | task_id | asset_family | asset_name | prompt_tier | prompt_source | candidate_count | primary_pick | backup_pick | target_dir | current_status | review_owner | review_date | next_action | notes |
|---|---|---|---|---|---|---:|---|---|---|---|---|---|---|---|
| batch_stage7_01 | A1 | ui_background | main_menu_background | 完整版 | stage7-three-tier-prompt-system-2026-03-24.md | 3 |  |  | assets/sprites/ui/backgrounds/ | concept_candidate |  | 2026-03-24 | 首轮筛选 |  |
```

## 6. 推荐附加字段

如果批次变大，建议再加这些字段：

| 字段 | 含义 |
|---|---|
| `variant_tag` | 同任务下的风格分支，例如 `holy_ruins`、`archive_heavy` |
| `reuse_scope` | 预期复用范围，例如 `main_menu_only`、`shared_archive_ui` |
| `runtime_owner` | 后续负责接入 Godot 的人 |
| `import_blocker` | 是否有导入阻塞 |
| `replace_target` | 后续要替换的现有占位资源或页面 |

## 7. 批次页头模板

建议每份 ledger 前面先写清楚批次元信息：

```md
# Stage 7 Asset Intake Ledger - <batch_id>

- 批次名称：
- 对应阶段：Stage 7
- 本批目标：
- 覆盖任务：
- 主要目录：
- 评审标准：统一世界观、可读性、命名规范、落盘规范
- 当前结论：
```

## 8. 评审结论写法建议

建议每个批次在表格后追加简短结论：

```md
## 批次结论

- 已定锚：
- 可继续扩产：
- 需要返工：
- 暂不入库：
- 下一步：
```

## 9. 推荐最小工作流

1. 先生成 3 份以上候选。
2. 填表记录 `candidate_count`。
3. 选出主选 / 备选。
4. 标记当前状态。
5. 决定是否落到正式目录。
6. 在 `next_action` 写清下一步是扩产、像素化、接入还是搁置。

## 10. 当前建议

- 所有首批任务 `A1-A4 / B1-B3 / C1-C2 / G1-G2` 都建议至少各有一行 ledger 记录。
- 对 `characters / enemies / weapons`，即使目前只做方向稿，也建议照样记 ledger，避免后续概念稿失联。
- 如果后续继续推进，最自然的下一份文档就是“首批批次已预填收稿模板”。
