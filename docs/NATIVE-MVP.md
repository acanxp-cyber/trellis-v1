# Trellis 原生 MVP 实施说明

更新：2026-11-10

---

## 1. 当前基线

已落地：

- Git 仓库；
- `Trellis.xcodeproj`；
- XcodeGen `project.yml`；
- SwiftUI 五页结构；
- actor 本地持久化；
- 版本化数据模型；
- 原子写入与文件保护；
- 数据目录排除 iCloud 备份；
- 任务新建与完成；
- 文字记录；
- 三重点周回顾；
- 年轮统计；
- JSON 导出；
- XCTest 测试源码；
- GitHub Actions macOS 构建与测试模板；
- Privacy Manifest；
- 健康数据非持久化类型边界。

尚未验证：

- 当前 Windows 环境没有 Swift/Xcode，无法执行 iOS 编译；
- 尚未在真机运行；
- Bundle ID 仍为 `com.example.trellis`；
- Team ID、证书、描述文件未配置；
- App 图标未设计；
- HealthKit 尚未接入；
- App Store 文案和线上隐私页未完成。

---

## 2. 工程结构

```text
V1/
├── Trellis/                     iOS App 源码
│   ├── TrellisApp.swift         App 入口
│   ├── AppModel.swift           UI 状态与业务动作
│   ├── Models.swift             Codable 领域模型
│   ├── LocalAppRepository.swift actor 持久化
│   ├── HealthSnapshot.swift     健康数据红线类型
│   ├── RootView.swift           五页 Tab
│   ├── TodayView.swift          今日任务
│   ├── RecordsView.swift        文字记录
│   ├── ReviewView.swift         周回顾
│   ├── YearView.swift           年轮统计
│   ├── MoreView.swift           数据主权与导出
│   └── Resources/               隐私清单与资产
├── TrellisTests/                单元测试源码
├── Trellis.xcodeproj            可直接打开的工程
├── project.yml                  XcodeGen 源定义（含测试 target）
├── scripts/bootstrap-ios.sh     macOS 构建入口
├── app/                         旧 Web 原型，仅保留参考
└── docs/
    ├── ADR-0001-native-swiftui-health-boundary.md
    └── NATIVE-MVP.md
```

`project.yml` 是长期工程定义的 source of truth。提交后的 `.xcodeproj` 用于直接打开；在修改 target、scheme 或测试结构后，应在 macOS 执行：

```bash
brew bundle
xcodegen generate
```

依赖锁口径：

- 原生 App 当前没有第三方 Swift Package，因此没有 `Package.resolved`；
- 一旦增加远程 Swift Package，必须提交 `Package.resolved`；
- 旧 Web 原型的 npm 依赖由 `app/package-lock.json` 锁定；
- 正式产品不得依赖未锁定版本。

---

## 3. 数据边界

### 3.1 可以进入 `AppData`

- 用户手写的任务标题；
- 用户手写的普通记录；
- 周回顾文字；
- 三个下周重点；
- 时间戳与状态。

### 3.2 不得进入 `AppData`

- HealthKit 睡眠原始值；
- 心率、HRV、血氧、体重、步数；
- 训练组数、负重、RPE；
- 从上述数据计算的个人趋势与健康洞察；
- 由 HealthKit 数据生成的缓存字符串。

### 3.3 Health 数据生命周期

```text
用户授权
  → HealthKitService 读取
  → 生成瞬时 HealthSnapshot
  → View 渲染
  → Snapshot 释放
```

禁止路径：

```text
HealthSnapshot
  → JSON
  → CloudKit
  → iCloud
  → 第三方分析
```

---

## 4. 本地持久化

文件：

```text
Application Support/Trellis/app-data-v1.json
```

策略：

| 项 | 方案 |
| --- | --- |
| 并发 | Swift actor |
| 写入 | `.atomic` |
| 文件保护 | `.completeFileProtection` |
| iCloud 备份 | 目录标记 `isExcludedFromBackup` |
| 编码 | ISO 8601 日期 |
| 损坏处理 | 初始化失败并提示，不覆盖原文件 |
| 恢复 | 用户主动导出 JSON |

当前没有自动导入。下一步应增加：

1. 版本迁移器；
2. 导入前 schema 校验；
3. 导入确认与合并策略；
4. 导入失败时原数据不变测试。

---

## 5. 里程碑

### M0：当前基线

完成标准：

- Git 可提交；
- `.xcodeproj` 可打开；
- 本机数据层与 UI 源码存在；
- macOS CI 至少能到达编译阶段。

### M1：核心闭环真机通过

完成标准：

- 新建任务；
- 完成任务；
- 写记录；
- 完成周回顾；
- 强制退出并重启后状态保留；
- 导出文件可打开；
- 解码失败不丢原文件；
- 320/390/430 宽度可用；
- VoiceOver 可操作主要动作。

### M2：健康能力

完成标准：

- HealthKit entitlement；
- `NSHealthShareUsageDescription`；
- 只读授权；
- 仅读取睡眠与静息心率；
- 授权拒绝后核心闭环不受影响；
- 无任何 HealthSnapshot 落盘；
- 无 CloudKit 健康 schema；
- 真机验证锁定状态与后台行为。

### M3：原生采集

可选，按验证结果排序：

- 本地通知；
- 相机/相册；
- 语音录制与设备端转写；
- PencilKit。

每一项都必须先定义数据分类；训练、身体、语音内容默认不进 CloudKit。

### M4：非健康数据云同步

只有满足 ADR-0001 条件后才开始。

### M5：订阅

只有在周回顾、导出或年度交付物已被真实用户重复使用后再判断是否接入 StoreKit。

---

## 6. 验证命令

在 macOS：

```bash
brew bundle
./scripts/bootstrap-ios.sh
```

生成工程：

```bash
xcodegen generate
```

测试：

```bash
xcodebuild \
  -project Trellis.xcodeproj \
  -scheme Trellis \
  -destination "platform=iOS Simulator,name=iPhone 17" \
  CODE_SIGNING_ALLOWED=NO \
  test
```

实际模拟器名称以本机可用设备为准。

---

## 7. 上线前仍缺

- 首次编译与 CI 通过；
- 真机测试；
- 真实 App 名称与 Bundle ID；
- Team ID、证书、描述文件；
- App 图标与启动屏；
- 隐私政策和支持页线上地址；
- App Store 文案、截图和审核说明；
- 用户可理解的备份/恢复引导；
- 健康文案非医疗免责声明。

