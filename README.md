# 莫尔斯电码练习器 (CW Player)

一个基于 Flutter 构建的莫尔斯电码（CW）练习工具，支持 Web 平台，采用**蒸汽朋克**视觉风格，提供多种输入模式和可配置的发报参数。

## 功能特性

- **三种键控模式**：
  - **手动键**：按下即产生点信号，持续按住超过阈值自动变为划信号（实时反馈）
  - **半自动键**：点击输出点/划信号
  - **自动键**：单击产生一个信号，长按连续重复输出
- **双输入源**：鼠标（点击 + 键盘）/ 触摸屏适配
- **可自定义键位**：点信号（Dit）与划信号（Dash）支持键盘重新绑定
- **实时蜂鸣音效**：`dart:js_interop` 扩展类型调用 Web Audio API，700Hz 真实 CW 音调，硬开关无拖尾
- **参数灵活可调**：点信号时长、自动键重复间隔、手动键长按阈值、字符间隔、单词间隔、音量等
- **配置持久化**：通过 `shared_preferences` 保存用户设置
- **蒸汽朋克 UI**：黄铜/铜色调、齿轮装饰、暗色主题

## 莫尔斯码支持

| 类型 | 支持符号 |
|------|----------|
| 字母 | A–Z |
| 数字 | 0–9 |
| 标点 | `. , ? ' ! / ( ) & : ; = + - _ " $ @` |

## 项目架构

```
lib/
├── main.dart                          # 应用入口，主题配置
├── models/
│   ├── morse_codec.dart               # 莫尔斯码字典 & 枚举定义
│   └── player_config.dart             # 播放器配置数据模型
├── services/
│   ├── audio_service.dart             # dart:js_interop 封装 Web Audio API（700Hz / 硬开关）
│   └── storage_service.dart           # SharedPreferences 配置读写
├── theme/
│   └── steampunk_theme.dart           # 蒸汽朋克主题（调色板/文字样式/齿轮装饰）
├── widgets/
│   ├── cw_player.dart                 # 核心播放器（状态管理 + 输入处理）
│   ├── mode_selector.dart             # 模式选择器（键控模式 + 输入源）
│   ├── touch_buttons.dart             # 触摸按钮组（点/划）
│   ├── manual_key_button.dart         # 手动电键按钮（蒸汽朋克风格）
│   ├── key_binding_panel.dart         # 键盘绑定面板
│   ├── morse_display.dart             # 莫尔斯码输入实时显示
│   ├── decode_display.dart            # 解码文本显示区
│   └── config_dialog.dart             # 参数配置对话框
└── cw_player_improved.dart            # [旧版] 原始单文件实现（保留参考）
```

### 架构设计原则

| 原则 | 体现 |
|------|------|
| **单一职责** | 模型/服务/UI 组件各司其职，11 个模块文件 |
| **依赖注入** | `AudioService` 和 `StorageService` 由 `CWPlayer` 创建并管理生命周期 |
| **配置模型化** | `PlayerConfig` 封装所有参数，支持 `copy`/`reset` |
| **主题集中化** | `SteampunkTheme` 统一颜色、文字样式、齿轮装饰 |
| **JS 互操作** | `dart:js_interop` 扩展类型精确映射 Web Audio API，杜绝名称混淆 |
| **事件分层** | 半自动/自动用手势竞技场（按钮优先），手动键用 `_suppressPointer` 抑制 |

## 手动键新逻辑

区别于传统「抬起后判断点/划」的方式，本实现采用**实时反馈**机制：

```
按下 → 立即显示「·」并播放蜂鸣
  │
  ├─ 在阈值内松开 → 确认为点信号「·」
  │
  └─ 超过阈值 → 自动变为划信号「—」（蜂鸣持续）
       │
       └─ 松开 → 停止蜂鸣
```

## 环境要求

- Flutter SDK >= 3.12.0
- Dart SDK >= 3.12.0

## 依赖项

| 包名 | 用途 |
|------|------|
| `shared_preferences` | 本地配置持久化 |
| `morse_code_translator` | 莫尔斯码与字符互转（备用） |
| `cupertino_icons` | iOS 风格图标 |

> 注：音频通过 `dart:js_interop` 扩展类型调用 Web Audio API，无名称混淆，仅 Web 平台有效。

## 快速开始

```bash
# 安装依赖
flutter pub get

# 在 Chrome 中运行（推荐 Web 平台）
flutter run -d chrome

# 代码检查
flutter analyze
```

## 使用说明

### 键控模式

| 模式 | 鼠标 | 触摸 | 键盘 |
|------|------|------|------|
| **手动键** | 按住 = 点→持续变划 | 按住电键按钮 | 按住绑定键 |
| **半自动键** | 左键=点 / 右键=划 | 按下按钮即发 | 按下绑定键 |
| **自动键** | 左键=点 / 右键=划 / 长按连发 | 按住按钮连发 | 按住绑定键连发 |

### 技术要点

| 特性 | 实现 |
|------|------|
| 按钮优先 | 半自动/自动模式用 `GestureDetector` 手势竞技场；手动键模式加 `_suppressPointer` 抑制 |
| 触摸零延迟 | `Listener.onPointerDown` 替代 `GestureDetector.onTap`，按下即触发 |
| 键盘大小写 | `_keysMatch` 大小写不敏感比较 |
| 模式切换 | 自动清除当前电码区，避免残留符号错误解码 |

### 自定义键位

点击键位绑定面板中的「编辑」图标，按下所需键盘按键即可完成绑定。

## 构建与部署

项目提供了自动化脚本来构建带版本信息的 Web 产物，并部署到 `website` 分支。

### 构建（含版本注入）

```bash
# 自动执行 flutter build web + 注入 commit hash
./scripts/build_with_version.sh
```

构建完成后会在 `build/web/` 中生成：
- `index.html` — 注入 `<meta name="cw-version" content="<commit-hash>">`
- `version.json` — 包含 commit、构建时间等完整版本信息

### 部署到 website 分支

```bash
# 将 build/web 内容推送到远程 website 分支
./scripts/deploy_website.sh
```

使用 `git worktree` 实现，不影响当前工作分支。首次运行会自动创建 `website` 分支；后续运行会更新并强制推送。

> GitHub Pages / GitLab Pages 可配置指向 `website` 分支实现静态站点托管。

## 平台支持

| 平台 | 音频 | 交互 |
|------|------|------|
| Web (Chrome) | ✅ 完整 | ✅ 完整 |
| Android/iOS | ❌ | ✅ |
| Linux/macOS/Windows | ❌ | ✅ |

## License

MIT License
