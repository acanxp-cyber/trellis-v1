# 发布准备状态

更新：2026-11-10  
路线：原生 SwiftUI  
结论：**Blocked；工程骨架已建立，但尚未完成 iOS 编译、真机和商店提交准备。**

详细架构红线见 [ADR-0001](docs/ADR-0001-native-swiftui-health-boundary.md)，实施顺序见 [NATIVE-MVP](docs/NATIVE-MVP.md)。

---

## 已完成

- 初始化 Git；
- 创建 `Trellis.xcodeproj`；
- 创建 XcodeGen `project.yml`；
- 实现 SwiftUI 五页结构；
- 实现本地持久化；
- 实现任务、记录、周回顾和年轮统计；
- 实现 JSON 导出；
- 实现 Privacy Manifest；
- 写明 HealthKit 数据本机边界；
- 编写 XCTest；
- 增加 macOS CI；
- 将 Capacitor 目录降级为原型。

## 阻断项

### 1. 尚未实际编译

当前机器没有 Swift/Xcode。`.xcodeproj` 已生成并通过项目结构解析，但 Swift 源码尚未做真实编译器校验。

解决：

- 在 macOS 执行 `brew bundle && ./scripts/bootstrap-ios.sh`；
- 修复编译器报错；
- 跑通 XCTest。

### 2. 尚未真机验证

需要至少一台 iPhone 验证：

- 启动；
- 本地写入；
- 强制退出恢复；
- 文件保护；
- 导出；
- 可访问性。

### 3. Bundle ID 与签名未完成

- 当前 Bundle ID：`com.example.trellis`；
- 当前无 Team ID；
- 当前无证书和描述文件。

提交前必须替换，并保证 App ID、Bundle ID、描述文件一致。

### 4. App 图标和商店资产缺失

- 无正式 AppIcon；
- 无正式启动屏视觉；
- 无 6.9 寸截图；
- 商店文案和隐私回答仍属旧原型模板。

### 5. 健康能力尚未实现

当前只有红线类型与非持久化约束。HealthKit 尚未接入。

接入前必须：

- 增加 HealthKit entitlement；
- 增加用途字符串；
- 只读授权；
- 每台设备独立读取；
- 确认无健康数据落盘；
- 确认无 CloudKit 健康字段。

### 6. 云端与订阅不应提前接入

MVP 当前无 CloudKit、无 StoreKit。先验证本地闭环，再判断是否值得增加同步和订阅。

---

## 最短上线顺序

1. macOS 首次编译；
2. 修复 Swift 6 并发和 SwiftUI 编译问题；
3. 跑 XCTest；
4. 模拟器走通核心闭环；
5. 真机走通核心闭环；
6. 定名、Bundle ID、图标和签名；
7. TestFlight；
8. 完成隐私政策、支持页和商店截图；
9. 提交审核；
10. HealthKit 作为独立里程碑，不与首次构建验证混在一起。

---

## 不能提前做的事

- 不要把 HealthKit 数据写入 `AppData`；
- 不要用 CloudKit 同步健康或训练数据；
- 不要在未验证本地闭环前接订阅；
- 不要用旧静态原型截图宣称已实现 HealthKit、通知、相机或语音；
- 不要把 `com.example.trellis` 作为正式 Bundle ID。

