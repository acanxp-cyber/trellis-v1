# Trellis App Store 上架资料参考

> 版本：2026-11-11  
> 说明：这是唯一一份需要你填写/确认的上架资料表。已知信息已经预填；只需修改不同意的项，并补齐标为【必须填写】的内容。  
> **不要在本表粘贴密码、API Key、p12、描述文件私钥。**

---

## 0. 已经准备好，无需你重复提供

- [x] 私有源码仓库：`https://github.com/acanxp-cyber/trellis-v1`
- [x] 公开设计预览：`https://acanxp-cyber.github.io/trellis-preview/`
- [x] 原生 SwiftUI 工程：`Trellis.xcodeproj`
- [x] 本地持久化与 JSON 导出
- [x] Privacy Manifest，当前声明不追踪、不收集数据
- [x] 隐私/支持页计划使用：
  - 隐私政策：`https://acanxp-cyber.github.io/trellis-preview/privacy.html`
  - 使用支持：`https://acanxp-cyber.github.io/trellis-preview/support.html`
  - 营销预览：`https://acanxp-cyber.github.io/trellis-preview/`
- [x] 审核路径默认说明已经起草，见第 9 节
- [x] App Privacy 默认按“不收集数据、不追踪”准备
- [x] 不包含账号、广告、第三方分析、订阅或 CloudKit

---

## 1. 只需你确认或修改的 12 项

在“你的填写”列写 `确认`，或直接写修改后的值。

| # | 项目 | 建议预填 | 你的填写 |
| --- | --- | --- | --- |
| 1 | App 上架名称 | `Trellis` | |
| 2 | 副标题 | `记录当下，看见长期变化` | |
| 3 | Bundle ID | `com.acanxp.trellis` | |
| 4 | SKU | `trellis-ios-001` | |
| 5 | 主分类 | `效率` | |
| 6 | 次分类 | `健康健美` | |
| 7 | 价格模式 | `免费` | |
| 8 | 首发国家/地区 | `中国大陆 / 香港 / 澳门 / 台湾` | |
| 9 | 审核联系人 | `刘灿 / 13590469876 / 120720375@qq.com` | |
| 10 | 开发者名称 | `DONG XIAN DESIGN` | |
| 11 | 版权 | `© 2026 DONG XIAN DESIGN` | |
| 12 | 发布方式 | `审核通过后手动发布` | |

如果第 7 项选择“付费”或“订阅”，还需要额外填写第 5 节的付费账户资料。

---

## 2. Apple 账号与签名资料【必须填写】

### 2.1 Apple Developer

- 账号类型：`个人 / 公司`  
- Apple Developer Team ID：`【必须填写】`
- Apple Developer Program 是否有效：`是 / 否`
- App Store Connect 是否已有 Trellis App 记录：`是 / 否`
- 若已有 App 记录，Apple App ID：`【选填】`

### 2.2 你希望采用哪种签名方式

- [ ] 我已把分发证书、描述文件放入安全目录
- [ ] 复用上次上架的分发证书，由你创建新描述文件
- [ ] 我在 Mac 上用 Xcode 自动签名
- [ ] 目前没有 Mac，需要全部走 GitHub Actions 云构建

如果你的 Mac 可以使用，请填写：

- Mac 是否可用：`是 / 否`
- 已安装 Xcode 版本：`【选填】`
- 是否已有可连接 iPhone：`是 / 否`

### 2.3 安全文件放置位置

请不要把密钥粘贴到表单或聊天。把需要的文件放到：

```text
F:\claude\Today\apple-secrets\
```

需要的文件：

- `AuthKey_XXXXXXXXXX.p8`：App Store Connect API Key
- `distribution.p12`：Apple Distribution Certificate（如使用云签名）
- `profile.mobileprovision`：Trellis 对应的 App Store 描述文件（如使用云签名）

另外请单独告诉我，不写在表单正文：

- API Key ID
- Issuer ID
- p12 密码

这些会用于本机或 GitHub Actions Secrets，不会提交到仓库。

---

## 3. 商店文案

### 3.1 推广文本

建议直接使用：

> 把任务、记录与周回顾连成一条时间线，看见自己真正发生的变化。

你的确认/修改：

```text
【确认或填写】
```

### 3.2 App 描述

建议直接使用：

```text
Trellis 是一个以周回顾为核心的个人成长工具。

它不要求你维护越来越长的待办清单，而是把每天真正推进的事、随手留下的记录，以及每周一次的回顾连在一起。使用一段时间后，你可以在年轮里看到哪些日子留下了痕迹，哪些变化正在发生。

主要功能：

- 今日任务：只保留当前真正重要的事。
- 快速记录：用一句话留下一天中值得记住的片段。
- 周回顾：总结本周落地的事、发生的变化和下周三个重点。
- 年轮：从任务、记录和回顾中生成长期视图。
- 本地存储：无需账号，数据保存在设备本地。
- JSON 导出：主动导出全部数据，方便自行备份。

Trellis 不包含广告、第三方分析、社交功能或自动健康诊断。
```

你的确认/修改：

```text
【确认或填写】
```

### 3.3 关键词

建议：

```text
个人成长,效率,任务,记录,周回顾,日记,自我管理,时间管理
```

你的确认/修改：

```text
【确认或填写】
```

### 3.4 “新版本”说明

建议：

```text
首个版本：今日任务、快速记录、周回顾、年轮统计与 JSON 数据导出。
```

---

## 4. 年龄分级与内容声明

- 建议年龄分级：`4+`
- 是否包含用户生成内容公开展示：`否`
- 是否包含社交、聊天、评论：`否`
- 是否包含广告：`否`
- 是否包含医疗建议或诊断：`否`
- 是否包含第三方品牌、影视、音乐素材：`否`

确认以上内容：`【确认 / 修改】`

---

## 5. 价格、协议与地区

### 5.1 免费模式

如果第 1 节选择“免费”，本节只需确认：

- [ ] 首发免费
- [ ] 不包含 App 内购买
- [ ] 不包含订阅

### 5.2 如果选择付费下载

- 中国大陆目标价格：`¥____`
- 是否已签署 Paid Applications Agreement：`是 / 否`
- 税务信息是否已完成：`是 / 否`
- 收款账户是否已完成：`是 / 否`

### 5.3 如果选择订阅或 App 内购买

- 订阅价格：`¥____ / 月或年`
- 免费试用：`有 / 无`
- 是否已完成 StoreKit 配置：`是 / 否`
- 是否接受首版不做订阅：`是 / 否`

当前工程没有 StoreKit。若选择订阅，工程仍需增加付费墙、恢复购买、订阅条款和 StoreKit 测试。

### 5.4 首发地区

- 是否首发中国大陆：`是 / 否`
- 已取得工信部 App 备案号：`是 / 否 / 不适用`
- 若未备案，是否先发港澳台和美国区：`是 / 否`

---

## 6. 开发者与法律信息

- 开发者/公司法定名称：`DONG XIAN DESIGN`
- 隐私联系邮箱：`120720375@qq.com`
- 客服支持邮箱：`120720375@qq.com`
- 版权声明：`© 2026 DONG XIAN DESIGN`
- 是否与上次上架沿用同一主体：`是 / 否`
- 是否有公司官网：`【选填】`

确认你拥有 App 内文字、图标、截图和训练内容的权利：

`【确认 / 需要替换内容】`

---

## 7. 图标与截图

### 7.1 App 图标

必须为 1024×1024、RGB、PNG、无透明通道。

选择一种：

- [ ] 让我按现有 Trellis 视觉生成一版
- [ ] 你提供图标，文件路径：`【填写】`
- [ ] 使用上次上架的设计资源，文件路径：`【填写】`

### 7.2 App Store 截图

截图必须来自**真实可运行的 iOS 构建**，不能使用静态网页原型冒充。

选择一种：

- [ ] 等 macOS 构建成功后，由我从模拟器生成
- [ ] 由你在真机提供
- [ ] 由你提供已有的 6.9 英寸截图

如由你提供，请填写：

- 截图文件路径：`【填写】`
- 截图对应版本/Build：`【填写】`

当前建议最少准备 5 张：

1. 今天任务
2. 快速记录
3. 周回顾
4. 年轮
5. 数据主权/导出

### 7.3 App Preview 视频

- [ ] 不提交视频
- [ ] 后续补真实 iPhone 录屏

---

## 8. 隐私政策、支持页与 App Privacy

计划上线网址：

- 隐私政策：`https://acanxp-cyber.github.io/trellis-preview/privacy.html`
- 使用支持：`https://acanxp-cyber.github.io/trellis-preview/support.html`
- 营销网址：`https://acanxp-cyber.github.io/trellis-preview/`

App Privacy 计划填写：

- 是否收集数据：`否`
- 是否用于追踪：`否`
- 是否包含广告：`否`
- 是否包含第三方分析：`否`
- 是否包含账号系统：`否`
- 数据是否仅在本机：`是`
- HealthKit 个人健康信息是否写入 iCloud/CloudKit：`否`

当前版本的隐私说明：

- 任务、记录、周回顾保存在设备本地；
- 数据目录已排除 iCloud 备份；
- 用户可通过 JSON 导出主动备份；
- App 不包含远程服务器、分析 SDK、广告 SDK 或账号系统；
- 当前版本未接入 HealthKit。

确认隐私口径：`【确认 / 修改】`

---

## 9. App Review 审核备注

建议使用：

```text
No account or login is required.

Core review path:
1. Open Today. Tap + to create a task.
2. Tap the square to mark the task complete.
3. Open Records. Enter a short note and tap Save.
4. Open Review. Enter what landed this week and exactly three focus items, then complete the review.
5. Open Year to verify that task, record, and review counts update.
6. Open More and export the local JSON backup.
7. Force quit and relaunch the app to verify that local data persists.

All user data stays on the device. The app contains no account system, ads,
third-party analytics, subscription, CloudKit sync, or HealthKit integration.
```

审核联系人：

- 姓名：`刘灿`
- 电话：`13590469876`
- 邮箱：`120720375@qq.com`

确认审核信息：`【确认 / 修改】`

---

## 10. 出口合规

建议回答：

- App 是否使用非豁免加密：`否`
- 理由：仅使用 iOS 系统提供的文件和本地存储能力，不自行实现加密协议，不连接自建服务器。

确认：`【确认 / 修改】`

---

## 11. TestFlight 与真机

- 是否愿意先走一轮 TestFlight 内测：`是 / 否`
- 内测人员 Apple ID：`【选填】`
- 测试设备型号：`【选填】`
- 是否接受首次提交先手动发布：`是 / 否`

---

## 12. 最短填写版

如果不想逐项编辑，只需要把下面 15 行复制并补齐：

```text
1. App 名称：
2. 副标题：
3. Bundle ID：
4. SKU：
5. 价格：免费 / 付费 / 订阅
6. 首发地区：
7. 中国大陆备案：已备案 / 未备案 / 不发大陆
8. Apple Team ID：
9. 是否有 Mac：有 / 没有
10. 签名方式：云构建 / 本机 Xcode / 复用上次证书
11. 开发者名称：
12. 版权：
13. 审核联系人姓名/电话/邮箱：
14. 图标：让我生成 / 我提供（路径）
15. 截图：你生成 / 我提供（路径）
```

苹果密钥不要写在这 15 行里，只告诉我是否已放入 `F:\claude\Today\apple-secrets\`。
