# 剩余游戏开发内容清单（2026-03-22，已于 2026-03-24 按代码真值同步）

## 当前进度结论

- 已完成：Stage 1 内容基线对齐。
- 已完成：Stage 2 主线章节与环境补完。
- 已完成：Stage 3 Boss 与敌群成品化。
- 已完成：Stage 4 构筑、经济与成长深度。
- 已完成：Stage 5 叙事、营地与结局闭环（正式收口文档、验收记录与统一摘要已回写）。
- 已完成：Stage 5 batch 1（路线弧线摘要、营地反思、章节转场叙事增强）。
- 已完成：Stage 5 batch 2（三结局 payoff、后记链路、碎片触发节奏、结算展示）。
- 已基本完成：Stage 5 batch 3（`epilogue_branch`、`fragment_recap`、`hidden_layer_hook`、`hidden_layer_story`、`hidden_layer_statuses` 已形成结算页 / 主菜单 Last Run / 记忆祭坛 / Hidden Layer Track / 章节转场的前台闭环）。
- 已完成：Stage 6 隐藏层与后期系统（已具备 `FS1/FS2` 解锁与档案状态基础、`FS1/FS2` 最小可玩链路、`CL1` 挑战层最小闭环、真实 `CL2/CL3/CL4` 挑战层闭环、`CL2+` challenge record schema 基线、隐藏层重复清档的 `Archive Return` 与最终 `Apex Return` 长期回流链、覆盖 `Archive Return` / `CL1/CL2/CL3/CL4` 的 Stage 6 成就扩展与 archive codex 扩展，以及 `char_curator` / `wpn_reliquary_orb` / `evo_zenith_reliquary` 的最小内容包）。
- 未开始为主：Stage 7 成品表现与最终验收。

## 当前最优先剩余项

### 1. Stage 5 正式收口与验收回写（已完成）

- [x] 已回写 Stage 5 正式收口文档：`spec-design/stage5-closure-2026-03-25.md`。
- [x] 已补三条路线、三结局、首次解锁/重复解锁差异的验收记录：`spec-design/stage5-acceptance-record-2026-03-25.md`。
- [x] 已整理统一验收摘要，供新 session 直接承接：`spec-design/stage5-acceptance-summary-2026-03-25.md`。

### 2. Stage 6 紧邻缺口：隐藏层与挑战层继续补强

- [x] 已补齐 `FS2` 与 `FS1` 对齐的可玩入口、房间/Boss/结算闭环与端到端回归；对应回归已锁定在 `test/unit/test_narrative_camp_flow.gd`。
- [x] 已补齐 `CL1` 失败路径、`Sigil Bundle` / `Archive Insight` 两条奖励分支、非 Meta 奖励后的安全营地预览回显；对应回归已锁定在 `test/unit/test_challenge_layer_flow.gd`。
- [x] 已决定 `sigils` / `insight` 继续停留在挑战层账本/UI 字段，暂不升级为真实全局资源；后续 `CL2+` 仍沿用 Archive Ledger 口径，避免过早耦合主 Meta 经济。
- [x] 已为 `CL2+` 与更完整挑战层体系提前泛化 `SaveManager` challenge schema；对应回归已锁定在 `test/unit/test_challenge_layer_flow.gd`。
- [x] 已落地首个真实 `CL2`：补齐安全营地预览、Entry -> Elite -> Boss -> Settlement 闭环、强化奖励档位与 Archive 回显；对应回归已锁定在 `test/unit/test_challenge_layer_flow.gd` 与 `test/unit/test_map_generation_config.gd`。
- [x] 已落地首个更深层 `CL3`：补齐 `CL2` 清档后的第三挑战层解锁、`O` 热键、安全营地预览、Entry -> Elite -> Combat -> Boss -> Settlement 闭环、第三档奖励与 Archive 回显；对应回归已锁定在 `test/unit/test_challenge_layer_flow.gd` 与 `test/unit/test_map_generation_config.gd`。
- [x] 已落地最终 `CL4`：补齐 `CL3` 清档后的第四挑战层解锁、`P` 热键、安全营地预览、Entry -> Elite -> Combat -> Elite -> Boss -> Settlement 闭环、第四档奖励与 Archive 回显；对应回归已锁定在 `test/unit/test_challenge_layer_flow.gd` 与 `test/unit/test_map_generation_config.gd`。
- [x] 已补齐最终 Meta Return 节奏：`CL4` 清档后解锁 `Apex Return`，将长期回流倍率提升到 `Return x1.60`；对应回归已锁定在 `test/unit/test_meta_return_progression.gd`。

### 3. Stage 6 中期/完整版目标

- [x] 图鉴系统：archive codex 已补齐 `Archive Return Protocol`、`Apex Return Protocol`、`Challenge Layer Archive`、`Crown Trial Archive`、`Sovereign Echo Archive`、`Apex Throne Archive`，并补齐 Meta Return / Challenge Layer detail 与 recent source 展示。
- [x] 成就扩展到完整版目标：已补齐 `Archive Return`、`CL1`、`CL2`、`CL3`、`CL4` 五条 Stage 6 成就，并将主菜单成就分组扩到 `Challenge Layer` 完整矩阵。
- [x] 更完整的高难度/后期挑战层体系：已从 `CL1` 扩到真实 `CL2/CL3/CL4`，并补齐对应 challenge-specific codex / achievement 矩阵。
- [x] 额外角色、额外武器、全武器进化路线补齐：已新增 `char_curator`、`wpn_reliquary_orb`、`evo_zenith_reliquary` / `wpn_zenith_reliquary`，并同步更新资源桩与验收目标。
- [x] 后期内容的解锁节奏、Meta 回流与长期目标设计：已形成 `nightmare_hidden_meta_return -> Archive Return -> CL2 -> CL3 -> CL4 -> Apex Return` 的完整 Stage 6 链路。

### 4. Stage 7 成品化与最终验收

- [ ] 音频资源从占位升级为正式内容。
- [ ] 关键角色、敌人、Boss、武器、UI 视觉资源替换。
- [ ] 主线 + 三结局 + 隐藏层 + 挑战层的联合回归。
- [ ] 长局平衡、构筑深度与人工 smoke 全链路复核。

## 当前阶段与下一阶段

### 当前阶段

- 当前处于“Stage 5 与 Stage 6 均已正式收口，Stage 7 待开始”的状态。
- Stage 5 的运行时、前台闭环、正式文档、验收记录与统一摘要均已具备，可作为后续 Stage 6 的稳定输入。
- Stage 6 已完成隐藏层、后期挑战链、长期回流、图鉴/成就矩阵与最小内容包收口，可作为 Stage 7 成品化与最终验收的稳定输入。
- 项目现在的主要矛盾已从“如何补齐后期系统”转为“如何把已完成内容做成成品表现并完成最终联合验收”。

### 下一阶段建议

- 下一批最合适的技术工作是进入 Stage 7：音频/视觉成品替换、主线 + 三结局 + 隐藏层 + 挑战层联合回归，以及长局平衡与人工 smoke 的最终验收。
- 不建议再把当前文档继续按“Stage 6 仍在进行中”来理解；后续计划应建立在 Stage 6 已完成、Stage 7 待成品化的真值之上。

### 下一阶段完成标准

- Stage 5 收口完成标准（已达成）：
  - 已完成能力与未完成边界有正式文档可查；
  - 三路线/三结局/首次与重复解锁差异有验收记录；
  - 现有前台闭环的测试与配置护栏结论被统一沉淀。
- Stage 6 完成标准（已达成）：
  - `FS2` 与 `FS1` 对齐的最小可玩闭环、`CL1` 失败路径/替代奖励分支/Archive Ledger 回显、真实 `CL2/CL3/CL4` 闭环，以及 `CL2+` challenge record schema 基线均已由自动化测试锁定；
  - `sigils` / `insight` 已明确继续停留在挑战层账本/UI 字段，不进入真实全局资源体系；
  - `Archive Return` 与 `Apex Return` 已形成完整 Stage 6 Meta 回流链路，并由自动化测试锁定到 `Return x1.60`；
  - Stage 6 成就矩阵已覆盖隐藏层复清与 `CL1/CL2/CL3/CL4`，archive codex 已覆盖 `Archive Return` / `Apex Return` 与 `CL1/CL2/CL3/CL4`；
  - 已补齐 `char_curator`、`wpn_reliquary_orb`、`evo_zenith_reliquary` / `wpn_zenith_reliquary` 的最小内容包、资源桩与验收目标，后续新增工作应直接转向 Stage 7 成品化与最终验收。
