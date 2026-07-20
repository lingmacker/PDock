# PDock

PDock 是一个原生 macOS 菜单栏工具，为系统 Dock 增加窗口预览能力。指针悬停在运行中的 Previewable Application 上时，PDock 会显示包含所有 Switchable Window 的非激活 Window Preview Panel；选择 Window Preview Card 后可切换到对应窗口。

PDock 不替换系统 Dock，不修改 Dock 配置，也不接管应用启动、固定或排序行为。

## 功能

- 可配置窗口预览出现和消失时延（默认 300 ms/250 ms，范围 0–2000 ms）
- 支持最小化、隐藏、全屏、其他 Space 和其他显示器中的窗口
- 支持底部、左侧、右侧 Dock、自动隐藏和 Dock 放大
- ScreenCaptureKit 低帧率实时缩略图
- 点击卡片切换到准确的 Accessibility 窗口，悬停缩略图可关闭对应窗口
- 自适应网格、内部滚动和原比例缩略图
- 菜单栏启用/暂停、权限修复和登录启动设置
- 简体中文与英文

## 系统要求

- macOS 14 或更高版本
- Apple Silicon (`arm64`)
- 辅助功能权限
- 屏幕录制权限

## 构建

默认命令生成 ad-hoc 签名的 Debug App：

```sh
make
```

构建产物：

```text
.build/make/Build/Products/Debug/PDock.app
```

构建并启动：

```sh
make run
```

运行测试：

```sh
make test
```

清理构建产物：

```sh
make clean
```

查看全部命令：

```sh
make help
```

可以覆盖默认变量：

```sh
make build CONFIGURATION=Release DERIVED_DATA=.build/release
```

## Developer ID 构建

正式站外发布需要有效的 Developer ID Application 证书和 Apple Developer Team：

```sh
make build \
  CONFIGURATION=Release \
  CODE_SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
  DEVELOPMENT_TEAM=TEAMID
```

当前 GitHub Release 工作流生成 ad-hoc 签名且未经公证的压缩包。应用内容变化后，macOS 可能将其识别为新的代码身份，用户需要重新授予辅助功能和屏幕录制权限。

## 首次运行

1. 启动 PDock。
2. 在权限引导中授予辅助功能权限。
3. 授予屏幕录制权限。
4. 如果屏幕录制权限未立即生效，退出并重新打开 PDock。
5. 将指针悬停在系统 Dock 中正在运行且拥有窗口的应用图标上。
6. 点击 Window Preview Card 切换到目标窗口。

PDock 自身只显示菜单栏项目，不显示 Dock 图标。登录启动默认关闭，可在设置中主动开启。

## 工程结构

```text
PDock.xcodeproj
PDock/
├── App
├── DockPreview
│   ├── DockObservation
│   ├── Model
│   ├── Presentation
│   ├── ThumbnailCapture
│   └── WindowDiscovery
├── LaunchAtLogin
├── MenuBar
├── Permissions
├── Resources
├── Settings
└── SupportingFiles
PDockTests/
└── DockPreview
```

Xcode 使用普通 Group，Group 层级与磁盘目录保持一致。`DockPreviewController` 是核心 Module 的小型外部 Interface，系统 Dock、Accessibility、ScreenCaptureKit、排序和面板生命周期均封装在 Module 内。

## 隐私与安全

- 截图只在 Window Preview Panel 可见期间进行
- 缩略图仅保存在内存中，关闭面板后释放
- 不记录窗口图像、窗口标题或应用内容
- 不访问网络，不收集遥测，不上传崩溃报告
- 只使用公开 Apple API
- Developer ID 配置启用 Hardened Runtime，关闭 App Sandbox
