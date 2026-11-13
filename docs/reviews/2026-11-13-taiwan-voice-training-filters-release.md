# 台湾提醒声音、训练媒体与照片滤镜发布审阅

日期：2026-11-13  
分支：`codex/training-media-alarm-filters`  
目标构建：SOMETHING `1.1 (12)`

## 结论

本轮代码已完成 macOS 模拟器构建、Swift 并发回归和 XCTest 验证，签名构建已成功上传，
Build 12 已进入 TestFlight 内部 `Debug` 组。以下项目仍必须在 iPhone 真机上验收，
不能由模拟器结果代替：

- iPhone `zh-TW` 系统声音与 T1 参考音的实际听感差异；
- 锁屏、后台、静音、专注模式、蓝牙耳机与来电打断时的闹钟播报；
- 提醒声音生成失败时是否真实回退为系统铃声；
- 8 个照片滤镜在不同照片和真机色域上的效果；
- 动作图片与本机简化动画在真实滚动列表中的性能。

## 已实现

### 提醒声音

- 默认声音目标：`taiwan-hsiaochen-soft.mp3` 对应的温柔台湾普通话方向。
- 正式实现使用 iPhone 本机 `zh-TW` 语音，不使用 Edge TTS，不上传提醒内容。
- “更多 > 提醒声音”支持开关、试听、声音切换、恢复默认和首次使用说明。
- 本机声音不可用时回退系统铃声，并向用户报告回退数量。
- 修改声音后会重新排程未来提醒。
- 删除或替换提醒时同步清理旧语音文件。

### 闹钟文案

- 任务标题中的“提醒我”“记得提醒我”“请提醒我”“叫我”会从显示与历史数据中清理。
- 准点播报示例：“12点半到了，吃饭囉”。
- 提前播报示例：“还有5分钟到12点半，吃饭囉”。
- 普通通知的标题显示任务内容，不再使用泛化的“日程提醒”作为标题。

### 训练

- 用户可见的“健身”统一改为“训练”。
- 80 个训练与运动项目继续保留。
- 新增 18 组 Free Exercise DB 双帧公版图片，当前共 45 组图片动作。
- 其余动作使用本机绘制的简化动作动画，不打包来源不明的 Gym Visual 媒体。
- 动作库总图片数：90 张，均为有效 JPEG。

### 照片滤镜

相机拍照后进入本地滤镜页，提供：

1. 暖阳生活
2. 清透日常
3. 柔光胶片
4. 银盐黑白
5. 旧时记忆
6. 电影青橙
7. 金色暮光
8. 清冷蓝调

滤镜使用 Core Image 在设备本机处理，结果写入本地记录目录。

### 隐私与商店材料

- Privacy Manifest 增加 UserDefaults 必需原因说明。
- 公开隐私政策与支持页已更新，明确相机、相册、麦克风、语音识别、提醒声音和训练内容。
- App Store 文案更新了台湾提醒声音、训练命名、8 个滤镜和新测试说明。
- 已生成 7 张 1320×2868 App Store 截图。

## 验证证据

- iOS Native CI（应用代码提交 `1abec51`）：
  https://github.com/acanxp-cyber/trellis-v1/actions/runs/43374616497
- App Store 截图：
  https://github.com/acanxp-cyber/trellis-v1/actions/runs/43374455688
- App Store 预检：
  https://github.com/acanxp-cyber/trellis-v1/actions/runs/43374795439
- 签名并上传 Build 12：
  https://github.com/acanxp-cyber/trellis-v1/actions/runs/43376150339
- TestFlight 内部组启用：
  https://github.com/acanxp-cyber/trellis-v1/actions/runs/43376688188

TestFlight 同步日志确认：

- `buildVersion`: `12`
- `processingState`: `VALID`
- `internalBuildState`: `IN_BETA_TESTING`
- `attached`: `true`
- `Debug` 组包含 Build 12

## 上线前剩余决策

- App Store Connect 当前应用记录名称为 `somethings`，二进制显示名称为 `SOMETHING`。
  上线前需要确认公开商店名是否仍为 `SOMETHING`，并检查名称可用性。
- 首版仍按当前清单排除中国大陆；开放中国大陆前必须先取得 App 备案号。
- Edge TTS 只用于试听，不得进入 App Store 二进制。
