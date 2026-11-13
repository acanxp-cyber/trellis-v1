# SOMETHING App Store Submission

## App record

- Name: `SOMETHING`
- Bundle ID: `com.acanxp.trellis`
- SKU: `trellis-ios-001`
- Primary language: Simplified Chinese
- Version: `1.1`
- Build: `12`
- Primary category: Productivity
- Secondary category: Health & Fitness
- Age rating: 4+
- Price: CNY 1

## Availability

- Mainland China: excluded for version 1
- Included: Hong Kong, Macao, Taiwan, and other selected App Store territories

## Promotional text

把语音安排、分组训练、多媒体记录与周回顾连成一条时间线。

## Description

SOMETHING 是一个以周回顾为核心的个人成长工具。

它不要求你维护越来越长的待办清单，而是把每天真正推进的事、随手留下的记录，以及每周一次的回顾连在一起。使用一段时间后，你可以在年轮里看到哪些日子留下了痕迹，哪些变化正在发生。

主要功能：

- 今日任务：只保留当前真正重要的事。
- 语音安排：一句话拆出任务、时间与提醒；说“练上肢”可直接得到分组训练建议。
- 训练：80 个训练与运动项目，覆盖徒手、器械、跑步、球类、游泳和拉伸；明确时长、组数和次数会优先保留。
- 提醒声音：默认使用 iPhone 本机的温柔台湾普通话女声，也可关闭播报或切换清晰普通话；声音在本机生成，不上传内容。
- 系统闹钟：iOS 26 使用 AlarmKit，旧系统回退本地通知；语音生成失败时自动使用系统铃声。
- 一键清零：只清除今天未完成的计划并取消对应提醒，支持 10 秒撤销。
- 多媒体记录：文字、拍照、8 个本地照片滤镜、录像、相册、本机语音、手绘、像素画和手作贴纸。
- 周回顾：总结本周落地的事、发生的变化和下周三个重点。
- 年轮：从任务、记录和回顾中生成长期视图。
- 本地存储：无需账号，数据保存在设备本地。
- JSON 导出：主动导出任务、回顾与记录文字；照片、视频、语音和涂鸦仍只保存在本机。

SOMETHING 不包含广告、第三方分析、社交功能或自动健康诊断。

## Keywords

个人成长,效率,任务,记录,周回顾,训练,徒手训练,语音,时间管理,提醒

## What’s New

- 新增温柔台湾普通话提醒声音，并可在“更多 > 提醒声音”中切换、试听或关闭。
- 提醒会直接播报时间与任务内容，例如“12点半到了，吃饭囉”。
- 旧任务标题中的“提醒我”会自动清理。
- “健身”统一改名为“训练”。
- 补充器械、跑步、球类等动作示范；没有准确公版素材的动作使用本机简化动画。
- 相机拍照后可选择 8 个本地照片滤镜。

## URLs

- Privacy: https://acanxp-cyber.github.io/trellis-preview/privacy.html
- Support: https://acanxp-cyber.github.io/trellis-preview/support.html
- Marketing: https://acanxp-cyber.github.io/trellis-preview/

## App Privacy

- Data collected: No
- Tracking: No
- Advertising: No
- Third-party analytics: No
- Accounts: No
- HealthKit/iCloud health sync: No

## Review contact

- Name: 刘灿
- Phone: 13590469876
- Email: 120720375@qq.com

## Review notes

```text
No account or login is required.

Core review path:
1. Open Today. Tap + to create two tasks and mark one complete.
2. Tap Clear Today and verify that only unfinished tasks are removed, then tap Undo to restore them.
3. Open Records from the bottom dock. Add a short note and attach a local photo or drawing.
4. Open Training and tap a workout card to preview the grouped warm-up, main work, and cool-down.
5. Open Review from More. Enter what landed this week and exactly three focus items, then complete the review.
6. Open Year to verify that task, record, and review counts update.
7. Tap the centered microphone and say "练上肢" to verify a grouped workout recommendation and an editable scheduled task.
8. Open More > Reminder Voice, preview the default Taiwanese Mandarin voice, and change the voice once.
9. Allow alarm access and schedule a task one minute ahead; verify the AlarmKit alarm on iOS 26.
10. Take a photo in Records and select one of the eight on-device filters.
11. Force quit and relaunch the app to verify that local data persists.

All user data and attached media stay on the device. Reminder speech is
synthesized locally with AVSpeechSynthesizer and exported as a short local
sound file. Photo, video, audio, and drawing files are excluded from iCloud
backup. The app contains no account system, ads, third-party analytics,
subscription, CloudKit sync, or HealthKit integration. Training content is
general exercise guidance, not diagnosis, treatment, or rehabilitation advice.
```

## Screenshots

Run the App Store Screenshots workflow after release-candidate verification;
the workflow captures the current centered voice dock and bottom navigation.

Required sequence:

- `01-today.png`
- `02-voice-capture.png`
- `03-records.png`
- `04-training.png`
- `05-review.png`
- `06-year.png`
- `07-more.png`

All are 1320 × 2868 RGB PNG files without transparency.

