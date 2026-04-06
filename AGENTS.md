# AGENTS.md - Angel Fallen 代理工作指南

## 目的
本文件面向在 `angel-fallen` 仓库中工作的智能编码代理。
这是一个使用 Godot 4.6 的 2D 俯视角动作 Roguelike 项目。
优先做小而准的改动，尽量沿用现有模式，不要无谓重构。

## 项目概览
- 引擎：Godot 4.6.x
- 主场景：`res://scenes/main_menu/main_menu.tscn`
- 主要语言：GDScript
- 辅助脚本：Python 3.11
- 测试框架：GUT
- CI：`.github/workflows/ci.yml`
- 关键 Autoload：`GameManager`、`EventBus`、`SceneManager`、`ConfigManager`、`AudioManager`、`ObjectPool`、`SaveManager`

## 规则文件检查结果
- `.cursor/rules/`：未发现规则文件
- `.cursorrules`：未发现规则文件
- `.github/copilot-instructions.md`：未发现规则文件
- 因此，本仓库的代理行为应以本文件、`project.godot`、CI 配置和现有代码风格为准

## 重要目录
- 场景：`scenes/`
- 游戏逻辑：`scripts/game/`、`scripts/systems/`、`scripts/components/`、`scripts/ui/`
- 单例脚本：`scripts/autoload/`
- 数值与配置：`data/balance/*.json`
- 资源桩与资源目录：`resources/`
- Godot 工具脚本：`scripts/tools/*.gd`
- Python 校验脚本：`scripts/*.py`、`scripts/tools/*.py`
- 测试：`test/unit/`、`test/integration/`

## 构建 / 运行 / 测试命令
以下命令均从仓库根目录执行。

### Godot 基础命令
```bash
# 导入项目并刷新类缓存
godot --headless --path . --import

# 打开编辑器
godot --editor --path .

# 运行游戏
godot --path . scenes/main_menu/main_menu.tscn

# 无头快速启动检查
godot --headless --path . --quit
```

### GUT 测试命令
```bash
# 运行全部测试
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://test -ginclude_subdirs -gexit

# 运行全部单元测试
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://test/unit -ginclude_subdirs -gexit

# 运行全部集成测试
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://test/integration -ginclude_subdirs -gexit

# 运行单个测试文件
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://test/unit/test_enemy_pooling.gd -gexit

# 运行单个测试函数
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://test/unit/test_enemy_pooling.gd -gunit_test_name=test_enemy_pool_lifecycle_resets_runtime_state -gexit

# 按文件名片段筛选测试
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://test/unit -ginclude_subdirs -gselect=enemy_pooling -gexit
```

说明：
- 单文件测试优先使用 `-gtest`
- 单个测试用例优先使用 `-gunit_test_name`
- 常用参数：`-gdir`、`-ginclude_subdirs`、`-gtest`、`-gselect`、`-gprefix`、`-gsuffix`、`-gunit_test_name`

### Python 校验命令
```bash
# JSON 语法校验
python scripts/tools/check_json_syntax.py

# 数值/配置语义校验
python scripts/validate_configs.py

# 资源结构与目录完整性校验
python scripts/check_resources.py
```

### CI 中使用的 Godot 校验脚本
```bash
godot --headless --path . -s res://scripts/tools/run_quality_baseline.gd
godot --headless --path . -s res://scripts/tools/run_release_gate.gd
godot --headless --path . -s res://scripts/tools/run_compatibility_rehearsal.gd
godot --headless --path . -s res://scripts/tools/run_resource_acceptance.gd
godot --headless --path . -s res://scripts/tools/run_visual_snapshot_regression.gd
```

## 建议验证顺序
1. 先跑与改动最接近的单个测试
2. 再跑相邻测试文件或对应测试目录
3. 如果改了 JSON，运行 `check_json_syntax.py`
4. 如果改了数值或配置，运行 `validate_configs.py`
5. 如果改了场景、资源、目录基线或 catalog，运行 `check_resources.py`
6. 改动较大时，最后补跑更大的 GUT 测试范围

## 代码风格
优先遵循仓库现有写法，不要机械套用通用风格指南。

### GDScript 结构
- 常见顺序：`extends`、可选 `class_name`、`signal`、`const`、`@export`、状态变量、生命周期函数、公有函数、私有辅助函数
- 仓库里大多数脚本不使用 `class_name`，只有在提升复用性或编辑器可发现性时才新增
- 变量、参数、返回值、数组、字典在合适时尽量写类型
- 路径、默认值、配置键、输出文件名优先使用 `const`
- `_ready()`、`_process()` 不要越写越大，复杂逻辑抽到私有辅助函数

### 资源加载
- GDScript 没有 import 块，使用 `load()` / `preload()`
- 静态且总会用到的资源优先 `preload()`
- 运行时可选资源、动态路径、测试选择目标可用 `load()`
- 需要时显式转换类型，例如：`var packed: PackedScene = load(scene_path)`

### 格式与排版
- 严格匹配目标文件现有缩进；本仓库同时存在 tab 和空格缩进
- 表达式优先可读性，不要过度压缩
- 逻辑块之间保留空行
- 优先用类型标注表达含义，而不是增加重复性注释
- 较大的字典和长参数列表应按多行展开，方便扫描

### 命名规范
- 类、枚举：`PascalCase`
- 函数、变量、信号：`snake_case`
- 私有状态、私有辅助函数：以下划线开头，如 `_spawn_enemy()`、`_room_time`
- 常量：`UPPER_SNAKE_CASE`
- 测试文件：`test_*.gd`
- 测试函数：`test_*`
- 资源 ID 保持稳定前缀，如 `char_`、`wpn_`、`pas_`、`enemy_`、`meta_`、`acc_`、`nar_`

### 类型与数据处理
- 游戏逻辑里优先使用显式类型
- `Variant` 主要用于信任边界：JSON、反射、动态属性、通用字典
- 对松散字典应尽早做归一化，转成类型明确的局部变量
- 在把数组、字典写入运行时状态前，先做清洗和边界处理
- 数值边界优先使用 `clampf`、`clampi`、`maxf`、`maxi`、`minf`、`mini`

### 错误处理
- 多用 guard clause，尽早返回无效状态
- Godot 脚本中的硬错误使用 `push_error()`
- 可恢复问题或部分数据缺失使用 `push_warning()`
- Python 校验脚本应输出可定位的问题信息，并以非零退出码失败
- 解析 JSON、读取文件、加载资源时优先显式兜底，不要假定一定成功
- 对可选运行时数据保持优雅降级

### 注释与语言
- 新增注释统一使用中文
- 修改旧注释时，如不影响语义与工具行为，优先同步改为中文
- 非业务注释但具有特殊语义的内容不要误改，例如 Python shebang、协议标记或工具约定头
- 后续开发的代码应主动补充注释，尤其是跨系统流程、状态机、配置映射、对象池复用、复杂 UI 汇总与校验脚本
- 新功能代码默认要有足够注释，目标是让后来的代理和开发者能快速看懂关键流程与设计意图
- 注释只解释不明显的约束、公式、兼容性原因或特殊行为
- 不要写“给变量赋值”这类低信息量注释

### 场景与节点代码
- 条件允许时优先使用类型化信号，例如 `signal settings_updated(settings: Dictionary)`
- 子节点可能缺失时使用 `get_node_or_null()`
- 对松耦合节点、对象池实例操作前，先检查 `has_method()` 或 `get()`
- 场景树查找优先复用现有 group 和 autoload，而不是发明新入口
- 被对象池复用的节点必须在重新取出时重置临时状态

### 测试约定
- 测试类继承 `GutTest`
- 断言消息要具体，便于快速定位失败原因
- 异步场景行为使用 `await get_tree().process_frame`
- 修 bug 时优先补最小回归测试，确保问题不会再次出现

### Python 风格
- 使用 Python 3.11 语法
- 优先使用 `Path`
- 类型标注优先用内置泛型：`list[str]`、`dict[str, Any]`
- 校验脚本尽量拆成明确的小辅助函数，避免深层嵌套
- 入口统一写成 `if __name__ == "__main__": raise SystemExit(main())`

## 数据与资源约定
- `data/balance/` 下的 JSON 是数值和配置真源，改动后通常需要跑校验
- `resources/` 下的资源桩必须与 catalog 和 acceptance 目标保持一致
- Godot 配置和资源引用统一使用 `res://` 路径
- 不要随意重命名资源 ID，现有校验大量依赖稳定 ID
- 如果修改 schema，必须同步更新验证脚本和相关测试

## 代理工作约定
- 以最小 diff 为目标，除非用户明确要求，否则不要大范围改写
- 如果现有 singleton / system / component 模式能解决问题，就不要另起架构
- 完成前检查 `.github/workflows/ci.yml`，不要凭印象声称“已经覆盖 CI”
- 改动 JSON、资源、场景验收数据时，必须运行对应校验
- 如果新增了命令、流程或约定，请同步更新本文件

## 提交约定
- 这类持续迭代工作默认按阶段拆分提交，不要把多轮小改动全部压成一个提交
- 小版本提交应至少对应一次有明确进度的内容更新，不要为了细碎改动频繁提交
- 大版本提交用于汇总一个阶段或里程碑内已经完成的小版本成果
- 提交说明统一使用中文 + 英文，优先写成单行双语，先中文、后英文，明确说明本次改动目的
- 提交粒度优先围绕版本进度而不是文件主题划分，保持历史既清晰又不过度碎片化

## 提交前快速检查
- 相关单测或单文件测试已通过
- 更大范围测试或校验已按改动类型补跑
- 新代码符合本地命名、类型和注释习惯
- 新增注释简洁且为中文
- 资源路径、资源 ID、JSON 键名不会破坏现有校验

## AI 资产自动化管线使用指南

本项目集成了一套基于 Python 的全模态游戏资产自动化生成管线，位于 `scripts/tools/game_asset_pipeline.py`。

### 支持的资产类型

| type 字段 | 输出格式 | 底层 API | 说明 |
|-----------|---------|---------|------|
| `sfx` | `.wav` | ElevenLabs | 短促拟音特效（UI 交互、打击音效等） |
| `bgm` | `.ogg` | Google Lyria 3 | 长篇 BGM 和环境循环音 |
| `voice` | `.ogg` | Google Gemini TTS | 角色台词、旁白配音 |
| `image` | `.png` | Google Imagen 3 / Nano Banana | 2D 静态图像（图标、立绘、地块） |
| `video` | `.mp4` | Google Veo | 过场动画视频 |

### 运行命令

```bash
# 批量生成模式：读取 JSON/CSV 配置清单，自动遍历生成全部资产（完成后自动输出产出清单 manifest）
python scripts/tools/game_asset_pipeline.py --config data/pipelines/stage7_assets_batch.json

# 审阅状态扫描：对比 manifest 和磁盘文件，报告已就绪/待选择/已丢失的资产组
python scripts/tools/game_asset_pipeline.py --status data/pipelines/stage7_assets_batch_manifest.json

# 批量定稿：将所有仅剩 1 个变体的组自动正式化，归档废弃变体到 _drafts/
python scripts/tools/game_asset_pipeline.py --finalize-dir --manifest data/pipelines/stage7_assets_batch_manifest.json

# 单个变体定稿：手动选定某个变体文件正式化
python scripts/tools/game_asset_pipeline.py --finalize assets/audio/sfx/click_v2.wav

# 查看帮助
python scripts/tools/game_asset_pipeline.py --help
```

### 完整生命周期

1. **`--config` 批量生成** → 脚本跑完后自动输出 `*_manifest.json` 产出清单
2. **`--status` 审阅扫描** → 扫描清单，报告哪些组待选择、已就绪、已丢失
3. **人工审阅** → 打开对应目录，删除不满意的变体
4. **重复 `--status`** → 直到报告显示"0 组待选择"
5. **`--finalize-dir` 批量定稿** → 一键将所有仅剩 1 个变体的组全部正式化

### 配置文件格式

支持 JSON 和 CSV 两种格式（自动识别扩展名），推荐使用 JSON。
示例文件位于 `data/pipelines/stage7_assets_batch.json`。

JSON 结构：
- `global_config`：全局风格锁定（前缀、后缀、种子、默认变体数）
- `tasks`：任务数组，每条任务包含 `type`、`prompt`、`path`、`variants` 及可选的类型特定参数

### 三种运行场景的人机协同策略

| 场景 | 图像任务 | 音频/视频任务 | 说明 |
|------|---------|-------------|------|
| **在 Antigravity 中运行** | 自动跳过，由 Agent 原生画笔接管 | 正常调用 API 执行 | 在 Antigravity 对话框中对 AI 下达指令出图获取最高品质 |
| **命令行独立运行** | 正常调用 Imagen/Nano Banana API | 正常调用 API 执行 | 完全自洽，无需 Agent |
| **CI/CD 流水线运行** | 同命令行 | 同命令行 | 适合批量化预生产 |

**核心原则**：脚本负责处理纯粹的工程自动化（量与速度），Antigravity 负责处理带有多模态需求（画图）的混合自动化（审美与逻辑闭环）。在 Antigravity 环境中，可以直接让 Agent 读取配置清单并逐条用内置画笔执行图像任务，无需手动逐条下达指令。

### 环境准备

1. 安装依赖：`pip install elevenlabs google-genai python-dotenv tqdm`
2. 在项目根目录创建 `.env` 文件，写入两行密钥（详见脚本顶部说明）：
   ```ini
   ELEVENLABS_API_KEY=sk-xxxx...
   GEMINI_API_KEY=AIzaSy...
   ```
3. `.env` 文件**已在 `.gitignore` 中被忽略**，不会被提交到版本控制。任何包含密钥的文件都不要手动 `git add`，防止泄露。如果发现 `.gitignore` 中缺少 `.env` 条目，必须立即补上

## AI 生成能力边界声明

以下声明旨在明确 AI 自动化工具链能够和不能够处理的游戏资产类型，避免团队产生错误预期。

### ✅ 可完全自动化的资产

| 资产类别 | 自动化程度 | 使用工具 |
|---------|:---:|---------|
| 静态立绘 / 道具图标 / UI 元素 | 100% | Imagen 3 / Nano Banana |
| 环境背景 / 关卡氛围概念图 | 100% | Imagen 3 |
| 短促拟音特效 (SFX) | 100% | ElevenLabs |
| 长篇 BGM / 环境循环音 | 100% | Lyria 3 |
| 角色台词配音 | 100% | Gemini TTS |
| 着色器代码 (Shader) | 100% | Agent 编写 |
| 过场动画视频 (从静帧生成镜头运动) | 90% | Veo |

### ⚠️ 需要人工收尾的资产

| 资产类别 | AI 贡献 | 人工收尾内容 |
|---------|:---:|-------------|
| 无缝地块 (Tileset) | 80% | AI 出原始大图，需在 Photoshop 中用偏移滤镜修补四边接缝 |
| VFX 概念转化 | 70% | AI 出概念参考图，需转化为引擎粒子系统或着色器 |
| 跨角色风格统一 | 70% | AI 通过全局前缀约束风格，但仍需人工调色板映射与线条标准化 |

### ❌ 当前 AI 无法实现的资产

| 资产类别 | 原因 | 推荐解法 |
|---------|------|---------|
| 角色动画序列帧 (Sprite Sheet) | 帧间一致性无法保证，每帧角色外观会微妙偏移 | AI 出立绘底稿 → Aseprite 手工逐帧描改，或 3D 简模渲染导出 |
| 无缝循环动画（水面、火焰等） | 首尾帧数学级吻合超出生成模型能力 | 用 Godot Shader 或 GPUParticles2D 程序化生成 |
| 骨骼动画数据 (Skeleton / Rig) | 纯结构化工程数据，不在生成模型范畴 | Godot 编辑器中手动创建 Skeleton2D + Bone2D |
| 字体文件 (.ttf / .otf) | AI 无法生成可用的向量字体文件 | 从 Google Fonts / DaFont 下载符合风格的现成字体 |
