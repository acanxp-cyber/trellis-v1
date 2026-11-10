# Trellis

原生 SwiftUI 路线的 V1 工程基线。

当前状态：**可继续开发的 MVP 源码与 Xcode 工程，尚未完成 iOS 编译和真机验证。**

---

## 先看三份文件

1. [架构红线](docs/ADR-0001-native-swiftui-health-boundary.md)
2. [原生 MVP 实施说明](docs/NATIVE-MVP.md)
3. [上线前审阅报告](审阅报告.md)

核心决策只有一条：

> HealthKit 中的个人健康信息只在本机即时使用，不持久化、不进 CloudKit、不进 iCloud。

---

## 当前已经落地

- 原生 SwiftUI；
- 任务、记录、周回顾、年轮和更多页；
- actor 本地持久化；
- 版本化 JSON；
- 原子写入；
- 文件保护；
- 数据目录排除 iCloud 备份；
- JSON 导出；
- XCTest 测试源码；
- `Trellis.xcodeproj`；
- XcodeGen `project.yml`；
- Privacy Manifest；
- macOS GitHub Actions 构建模板；
- Git 仓库。

## 当前尚未完成

- 在当前 Windows 环境执行 Swift 编译；
- macOS/Xcode 首次构建；
- 真机 TestFlight；
- 真实 Bundle ID 与 Team ID；
- App 图标；
- HealthKit；
- 相机、相册、麦克风；
- CloudKit；
- StoreKit；
- 正式隐私政策、支持页和 App Store 文案。

`com.example.trellis` 仍是占位 Bundle ID，不可提交 App Store。

---

## macOS 打开方式

直接用 Xcode 打开：

```bash
open Trellis.xcodeproj
```

如果修改了 target、scheme 或测试结构，重新生成工程：

```bash
brew bundle
xcodegen generate
```

一键检查构建：

```bash
./scripts/bootstrap-ios.sh
```

---

## 代码结构

```text
Trellis/
├── TrellisApp.swift
├── AppModel.swift
├── Models.swift
├── LocalAppRepository.swift
├── HealthSnapshot.swift
├── RootView.swift
├── TodayView.swift
├── RecordsView.swift
├── ReviewView.swift
├── YearView.swift
├── MoreView.swift
├── DataExportDocument.swift
├── Theme.swift
├── Info.plist
└── Resources/

TrellisTests/
project.yml
Trellis.xcodeproj
scripts/bootstrap-ios.sh
```

---

## 旧 Web 原型

`app/` 目录保留为视觉与信息架构原型，不再作为正式产品路线。

- 不要把 Capacitor WebView 重新接回正式 App；
- 不要继续为 `app/index.html` 添加原生插件；
- 需要核对设计时可直接打开 `app/index.html`。

旧原型中的数据全部为静态演示，不具备持久化能力。

---

## 第一条验收链路

在 iOS 模拟器或真机依次验证：

1. 新建任务；
2. 完成任务；
3. 写一条记录；
4. 完成本周回顾；
5. 查看年轮统计更新；
6. 导出 JSON；
7. 强制退出 App；
8. 重新打开，确认任务、记录、回顾仍在。

这条链路不通过，不进入 HealthKit 或 CloudKit。

