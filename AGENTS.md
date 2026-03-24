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
