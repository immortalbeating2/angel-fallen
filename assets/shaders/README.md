# Shaders

本目录用于存放 Stage 7 表现层使用的 Godot shader 资源。

格式要求：

- Godot shader 文件统一使用 `.gdshader`

建议内容：

- UI 微光
- 记忆碎片闪烁
- 档案封印脉冲
- 虚空裂隙扰动
- 圣辉边缘高亮
- 挑战层门或记录节点的轻量强调效果

命名示例：

- `ui_holy_glow.gdshader`
- `fx_memory_shard_pulse.gdshader`
- `fx_archive_seal_wave.gdshader`
- `fx_void_rift_distort.gdshader`

编写约定：

- 优先轻量、可复用，不要一开始就做高耦合的页面专用 shader
- 参数命名清晰，方便后续在 UI 或 VFX 节点上复用
- 先服务通用表现层，再服务高耦合结局或隐藏层最终演出

相关规范：

- `spec-design/stage7-asset-production-guide-2026-03-24.md`
- `assets/sprites/effects/README.md`
