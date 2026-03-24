# Audio Assets

本目录存放 Stage 7 正式音频资产。

子目录约定：

- `bgm/`：循环背景音乐，最终格式 `.ogg`
- `ambience/`：环境氛围循环，最终格式 `.ogg`
- `sfx/`：短音效，最终格式 `.wav`

基础要求：

- 采样率：`44.1kHz`
- 位深：`16-bit`
- `bgm` / `ambience` 需要可循环
- `sfx` 需要起音清晰、尾部干净

命名示例：

- `bgm_main_menu_fallen_sanctuary.ogg`
- `bgm_safe_camp_last_fire.ogg`
- `amb_memory_altar_echoes.ogg`
- `sfx_ui_confirm_01.wav`

相关规范：

- `spec-design/stage7-asset-production-guide-2026-03-24.md`
- `spec-design/stage7-gemini-copyable-prompt-pack-2026-03-24.md`
