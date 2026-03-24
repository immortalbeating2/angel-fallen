# Stage 7 首批批次收稿模板（2026-03-24）

## 1. 目的

本文档把 `Stage 7` 首批任务直接预填为可落地的 intake ledger 模板，便于在实际生成后直接填主选、备选、状态和下一动作。

配套文档：

- `spec-design/stage7-gemini-first-batch-task-list-2026-03-24.md`
- `spec-design/stage7-asset-intake-ledger-template-2026-03-24.md`
- `spec-design/stage7-asset-review-and-landing-workflow-2026-03-24.md`

## 2. 批次元信息

- 批次名称：`batch_stage7_01`
- 对应阶段：`Stage 7`
- 批次范围：背景 / UI / 图标 / 音频提示词母版
- 批次目标：先锁世界观锚点与 UI 设计锚点，再建立首批可入库的 `style_anchor` / `production_ready` 候选
- 推荐评审标准：统一世界观、清晰轮廓、目录匹配、命名规范、后续可扩产

## 3. 预填收稿表

| batch_id | task_id | asset_family | asset_name | prompt_tier | prompt_source | candidate_count | primary_pick | backup_pick | target_dir | current_status | review_owner | review_date | next_action | notes |
|---|---|---|---|---|---|---:|---|---|---|---|---|---|---|---|
| batch_stage7_01 | A1 | ui_background | main_menu_background | 完整版 | stage7-three-tier-prompt-system-2026-03-24.md | 3 |  |  | assets/sprites/ui/backgrounds/ | concept_candidate |  | 2026-03-24 | 首轮筛选 | 建议优先锁全项目视觉第一印象 |
| batch_stage7_01 | A2 | ui_background | safe_camp_background | 完整版 | stage7-three-tier-prompt-system-2026-03-24.md | 3 |  |  | assets/sprites/ui/backgrounds/ | concept_candidate |  | 2026-03-24 | 首轮筛选 | 需同时满足温暖避难所与神圣残败感 |
| batch_stage7_01 | A3 | ui_background | memory_altar_background | 完整版 | stage7-three-tier-prompt-system-2026-03-24.md | 3 |  |  | assets/sprites/ui/backgrounds/ | concept_candidate |  | 2026-03-24 | 首轮筛选 | 中心交互区必须清晰 |
| batch_stage7_01 | A4 | ui_background | archive_challenge_background | 完整版 | stage7-three-tier-prompt-system-2026-03-24.md | 3 |  |  | assets/sprites/ui/backgrounds/ | concept_candidate |  | 2026-03-24 | 首轮筛选 | 要能兼容档案与挑战归档双语义 |
| batch_stage7_01 | B1 | ui_panel_system | ui_style_board | 完整版 | stage7-three-tier-prompt-system-2026-03-24.md | 3 |  |  | assets/sprites/ui/panels/ | concept_candidate |  | 2026-03-24 | 风格定锚 | 主用途是统一按钮/页签/标题装饰语言 |
| batch_stage7_01 | B2 | ui_card_system | reward_cards | 完整版 | stage7-three-tier-prompt-system-2026-03-24.md | 3 |  |  | assets/sprites/ui/cards/ | concept_candidate |  | 2026-03-24 | 风格定锚 | 需兼容 run result / challenge / archive 卡片 |
| batch_stage7_01 | B3 | ui_frame_system | frames_panels | 完整版 | stage7-three-tier-prompt-system-2026-03-24.md | 3 |  |  | assets/sprites/ui/frames/ | concept_candidate |  | 2026-03-24 | 风格定锚 | 文本承载区必须足够大 |
| batch_stage7_01 | C1 | ui_icons | route_outcome_icons | 标准版 | stage7-three-tier-prompt-system-2026-03-24.md | 3 |  |  | assets/sprites/ui/icons/ | concept_candidate |  | 2026-03-24 | 首轮筛选 | 重点检查缩小可读性 |
| batch_stage7_01 | C2 | ui_icons | archive_system_icons | 标准版 | stage7-three-tier-prompt-system-2026-03-24.md | 3 |  |  | assets/sprites/ui/icons/ | concept_candidate |  | 2026-03-24 | 首轮筛选 | 重点检查 memory/archive/hidden/challenge 区分度 |
| batch_stage7_01 | G1 | audio_prompt_master | menu_camp_altar_audio_prompts | 标准版 | stage7-gemini-first-batch-task-list-2026-03-24.md | 3 |  |  | assets/audio/bgm/ + assets/audio/ambience/ | concept_candidate |  | 2026-03-24 | 音频 brief 审核 | 当前记录的是提示词母版，不是最终音频文件 |
| batch_stage7_01 | G2 | audio_prompt_master | ui_unlock_reward_sfx_prompts | 标准版 | stage7-gemini-first-batch-task-list-2026-03-24.md | 3 |  |  | assets/audio/sfx/ | concept_candidate |  | 2026-03-24 | 音频 brief 审核 | 当前记录的是提示词母版，不是最终音频文件 |

## 4. 首批任务的推荐目标状态

建议目标：

- `A1-A4`：至少推进到 `style_anchor`，优秀结果可到 `production_ready`
- `B1-B3`：先推进到 `style_anchor`
- `C1-C2`：优秀结果可直接推进到 `production_ready`
- `G1-G2`：当前阶段通常停在 `style_anchor` 或 `production_ready` 的 brief 层，待专门音频工具产出后再进入真正资产入库

## 5. 首批批次的快速验收清单

### 背景类 `A1-A4`

- 是否有清晰视觉中心
- 是否为 UI 预留覆盖空间
- 是否避免宣传海报式过满构图
- 是否符合 `fallen angel + sacred ruins + forbidden archive` 母题

### UI 类 `B1-B3`

- 是否保证信息承载区足够大
- 是否没有烘焙固定文字
- 是否适合后续切片 / 九宫格
- 是否与背景母题同源但不过度喧宾夺主

### 图标类 `C1-C2`

- 缩小后是否仍清楚
- 轮廓是否够干净
- 是否能区分 route / ending / archive / hidden / challenge 等系统语义

### 音频提示词类 `G1-G2`

- 是否明确了用途场景
- 是否避免歌词与过长情绪爆发
- 是否可以直接交给后续音频工具继续生成

## 6. 首批批次结论模板

生成并初筛完成后，可直接补这一段：

```md
## 批次结论

- 已定锚：
- 可直接入库：
- 需继续扩产：
- 需返工：
- 暂不采用：
- 下一步：
```

## 7. 当前建议

- 如果你准备开始真实生成，建议先完成 `A1-A4` 的主选与备选填写。
- 等背景母题锁住后，再集中跑 `B1-B3` 和 `C1-C2`，能显著减少风格漂移。
- `G1-G2` 建议与视觉锚点同步复核，避免音乐气质与视觉世界观脱节。
