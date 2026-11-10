# ADR-0001：原生 SwiftUI 与个人健康数据边界

- 状态：Accepted
- 日期：2026-11-10
- 决策人：产品与工程共同决策
- 影响范围：v1 技术路线、数据层、云同步、隐私政策、App Store 审核材料

---

## 1. 背景

项目最初同时存在两套技术路线：

1. 原生 SwiftUI + Core Data/SwiftData + HealthKit + CloudKit + WatchConnectivity + StoreKit。
2. Capacitor + WebView + Swift 插件桥接上述原生能力。

产品的主要差异化依赖 HealthKit、可靠本地通知、媒体采集、PencilKit、Apple Watch 与长期数据资产。把这些能力全部通过 WebView 桥接，既不能省掉 Swift 工作，又增加生命周期、权限、调试与安全边界。

同时，原方案计划把 HealthKit 数据同步到 CloudKit。Apple《App Review Guidelines》5.1.3(ii) 明确禁止把个人健康信息存入 iCloud，因此该方案不能上线。

---

## 2. 决策

### 2.1 技术路线

**v1 使用原生 SwiftUI，不再以 Capacitor/WebView 作为正式产品外壳。**

`app/` 目录保留为交互与视觉原型，不继续扩展原生功能。

### 2.2 健康数据红线

以下规则是不可协商的工程与审核红线：

1. HealthKit 读取的个人健康信息只用于当前设备上的即时展示或即时计算。
2. 健康数据、训练记录、身体信号及由它们生成的个人洞察，不得写入 CloudKit。
3. 上述数据不得进入普通业务持久化文件。
4. 上述数据不得进入第三方分析、广告或远程日志。
5. 上述数据不得写入用户可同步的 iCloud Documents 或普通 iCloud 备份路径。
6. 如需跨设备展示，必须在每台设备上分别取得 HealthKit 授权并从 HealthKit 重新读取，不能通过应用自己的 iCloud 数据库搬运。

代码约束：

- `HealthSnapshot` 故意不实现 `Codable`。
- `HealthSnapshot` 只能通过 `HealthSnapshotProviding` 短期提供。
- `AppRepository` 只能保存 `AppData`，不能接受健康快照。
- 未来如果增加训练记录，训练实体默认归入健康敏感数据，不得同步 CloudKit。

### 2.3 MVP 存储策略

**MVP 全部用户数据保持本机，不接 CloudKit。**

当前实现：

- 版本化 `AppData`；
- actor 串行访问；
- JSON 原子写入；
- 文件保护级别 `completeFileProtection`；
- 数据目录排除 iCloud 备份；
- 支持全量 JSON 导出；
- 解码失败时保留原文件并报错，不静默清空。

这一策略优先解决合规和“数据不能丢”，而不是提前承担云同步复杂度。

### 2.4 CloudKit 的未来使用条件

CloudKit 不是 v1 基础能力。未来允许接入时，必须先满足：

1. 建立字段级数据清单。
2. 明确标记 `health`、`fitness`、`body`、`derived-health` 字段。
3. 这些字段不得进入 CloudKit schema。
4. 增加自动测试，确保健康字段无法被编码为同步模型。
5. 隐私政策说明哪些普通数据会进入用户私有 iCloud，以及开发者不可访问。
6. 完成一次 Apple 审核口径复核。

任何“先同步全部数据，再过滤健康字段”的设计都不允许。

---

## 3. 当前 v1 范围

首版只做一条完整闭环：

```text
新建任务
  → 完成任务
  → 写一条记录
  → 完成本周回顾
  → 年轮统计更新
  → 导出全部数据
  → 重启 App 后数据仍在
```

首版范围：

- iPhone；
- SwiftUI；
- 本地持久化；
- 任务；
- 文字记录；
- 周回顾；
- 年轮统计；
- JSON 导出；
- 无账号；
- 无云同步；
- 无订阅；
- 无 HealthKit 持久化。

不在首版闭环内：

- Watch；
- CloudKit；
- StoreKit；
- Apple Music；
- PencilKit；
- 图片/语音记录；
- 自动健康洞察。

这些功能只有在前述闭环通过真机 TestFlight 后，才按独立里程碑接入。

---

## 4. 结果

### 正面结果

- HealthKit 合规边界从架构层固定，而不是靠隐私文案补救。
- v1 审核面显著缩小。
- 没有账号、云同步和订阅，首版数据模型与故障路径更简单。
- 原生 SwiftUI 为后续通知、媒体、HealthKit、Watch 和小组件保留低摩擦路径。
- 本地导出成为数据资产与灾难恢复入口。

### 代价

- 首版不能跨设备同步。
- 删除 App 会删除本地数据；当前依赖用户主动导出。
- 本地文件已排除 iCloud 备份，因此设备更换前必须导出。
- HealthKit 身体信号要等健康里程碑才能进入产品。

### 后续必须验证

- 在 macOS/Xcode 上完成首次构建与测试。
- 在真机验证文件保护、导出和强制退出后的恢复。
- 确定真实 Bundle ID 与 Team ID。
- 增加 App 图标、启动体验和正式隐私/支持 URL。

