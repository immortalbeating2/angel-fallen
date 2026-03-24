# Effects

本目录用于存放 Stage 7 通用视觉特效资源。

建议内容：

- 圣辉粒子
- 堕落羽毛
- 记忆碎片漂浮
- 档案封印破裂
- 虚空裂隙
- 锻造火花
- 解锁 / 奖励 / 结局基础闪光

格式要求：

- 静态特效或单帧特效：`.png`
- 序列帧特效：sprite sheet `.png`
- 先概念参考、后像素化或重绘都可以，但最终运行时入库仍以 `.png` 为主

命名示例：

- `fx_memory_shard_glow_v1.png`
- `fx_archive_seal_break_v1.png`
- `fx_fallen_feather_v1.png`
- `fx_forge_sparks_v1.png`

相关规范：

- `spec-design/stage7-asset-production-guide-2026-03-24.md`
- `spec-design/stage7-gemini-batch-production-manual-2026-03-24.md`

说明：

- 若特效需要程序材质配合，请把对应 shader 放到 `assets/shaders/`。
