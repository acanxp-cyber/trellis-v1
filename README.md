# Trellis

App Store 展示名：`SOMETHING`  
内部项目名与 Bundle ID：`Trellis` / `com.acanxp.trellis`

原生 SwiftUI 路线的 V1 工程基线。

当前状态：**原生 MVP 已通过 macOS 模拟器构建与 XCTest，Build 12 已进入 TestFlight 内部测试；仍待真机验收系统闹钟与媒体权限。**

---

## 先看三份文件

1. [架构红线](docs/ADR-0001-native-swiftui-health-boundary.md)
2. [原生 MVP 实施说明](docs/NATIVE-MVP.md)
3. [上线前审阅报告](审阅报告.md)
4. [App Store 必填表](Trellis-App-Store-资料填写.md)
5. [App Store 上架资料参考](docs/App-Store-上架资料参考.md)

核心决策只有一条：

> HealthKit 中的个人健康信息只在本机即时使用，不持久化、不进 CloudKit、不进 iCloud。

---

## 当前已经落地

- 原生 SwiftUI；
- 任务、语音拆任务、记录、训练、周回顾、年轮和更多页；
- 本机中文语音识别与多任务时间线；
- AlarmKit / 本地通知提醒、本机语音播报和系统铃声回退；
- 温柔台湾普通话提醒声音、清晰普通话声音和关闭播报选项；
- 80 个训练与运动项目、45 组公版双帧动作图片和本机简化动画；
- 照片、视频、照片滤镜、语音记录、手绘、像素画、贴纸和英语朗读；
- 8 个 Core Image 本地照片滤镜；
- 一键清零今天未完成计划与 10 秒撤销；
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

- iPhone 真机的台湾女声听感校准；
- 锁屏、静音、专注模式、蓝牙和来电打断时的闹钟验收；
- 低电量、无系统语音、拒绝权限和存储不足等真机异常路径；
- HealthKit 读取能力；
- CloudKit 同步（当前架构红线禁止用于健康数据）；
- StoreKit 与订阅；
- 中国大陆 App 备案和大陆区发行验证。

`com.acanxp.trellis` 已配置为正式 Bundle ID。

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

