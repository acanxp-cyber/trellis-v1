# Rich Records, Reset, and Adaptive Fitness Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Promote records to bottom navigation, add local multimedia records and one-tap plan reset, and make voice-driven fitness respect explicit duration, sets, reps, equipment, and activity type.

**Architecture:** Keep personal records and media local-only. Extend `AppData` with attachment/annotation metadata and add a file-backed media store separate from the JSON repository. Refactor fitness from a 50-item bodyweight catalog into a taxonomy that supports duration-based, dose-based, equipment, cardio, sport, and mobility plans.

**Tech Stack:** SwiftUI, Observation, PhotosUI, AVFoundation, PencilKit, UserNotifications, AlarmKit, XcodeGen, GitHub Actions.

**Spec:** This file records the approved chat design from 2026-11-13.

## Global Constraints

- All media stays local under Application Support and remains excluded from iCloud backup.
- Health, fitness, voice, photo, video, and drawing data never enter CloudKit.
- “清零今天” only removes today’s unfinished plans, cancels their alarms, and offers a 10-second undo.
- Recorded history, completed tasks, photos, videos, audio, drawings, and reviews are preserved.
- Explicit workout duration always wins over template duration.
- Explicit sets and reps always win over template prescriptions.
- No medical diagnosis, treatment, rehabilitation, or medication advice.

---

### Task 1: Reset Today

**Files:**
- Modify: `Trellis/AppModel.swift`
- Modify: `Trellis/TodayView.swift`
- Test: `TrellisTests/AppModelTests.swift`

**Interfaces:**
- Produce: `AppModel.clearUnfinishedTasksToday() async -> ClearPlanReceipt?`
- Produce: `AppModel.restoreClearedPlan(_ receipt: ClearPlanReceipt) async -> Bool`

- [x] Write tests proving only today’s unfinished tasks are removed and can be restored.
- [ ] Run tests and verify failure because the reset API is missing.
- [x] Implement receipt-based clearing and restoration.
- [x] Add “清零今天” toolbar action, confirmation, and 10-second undo banner.
- [ ] Run tests and commit.

### Task 2: Promote Records and Media Metadata

**Files:**
- Modify: `Trellis/RootView.swift`
- Modify: `Trellis/MoreView.swift`
- Modify: `Trellis/Models.swift`
- Create: `Trellis/RecordMediaStore.swift`
- Test: `TrellisTests/LocalAppRepositoryTests.swift`

**Interfaces:**
- Produce: `RecordAttachment` and `RecordSketch` Codable models.
- Produce: `RecordMediaStore.save(data:kind:recordID:)`, `load`, and `delete`.

- [x] Write migration test proving schema v1 records still decode.
- [x] Implement schema v2 and attachment metadata.
- [x] Add local media directory with complete file protection and backup exclusion.
- [x] Move Records into the bottom dock and remove it from More.
- [ ] Commit.

### Task 3: Camera, Video, and Voice Record Capture

**Files:**
- Modify: `Trellis/RecordsView.swift`
- Modify: `Trellis/Info.plist`
- Create: `Trellis/RecordMediaPicker.swift`
- Test: `TrellisUITests/ScreenshotUITests.swift`

**Interfaces:**
- Consume: `RecordMediaStore`
- Produce: record attachments for photo, video, and audio.

- [x] Add camera/photo/video permission strings.
- [x] Implement PhotosPicker multi-photo import and video import.
- [x] Implement local voice memo capture.
- [x] Show attachment thumbnails, playback, and deletion.
- [x] Verify no media is written to JSON payloads.
- [ ] Commit.

### Task 4: Drawing, Pixel Art, and Stickers

**Files:**
- Create: `Trellis/RecordDrawingEditor.swift`
- Create: `Trellis/PixelSketchEditor.swift`
- Create: `Trellis/StickerCatalog.swift`
- Modify: `Trellis/RecordsView.swift`

**Interfaces:**
- Produce: persisted PNG sketch attachments.
- Produce: sticker layer transforms encoded in `RecordAttachment`.

- [x] Add PencilKit drawing editor with clear/undo/save.
- [x] Add fixed-grid pixel editor with palette, eraser, undo, and export.
- [x] Add original cartoon sticker sheet with drag/scale/rotate.
- [ ] Persist flattened preview and editable metadata.
- [ ] Commit.

### Task 5: Workout Request Model

**Files:**
- Modify: `Trellis/FitnessCatalog.swift`
- Create: `Trellis/WorkoutIntent.swift`
- Test: `TrellisTests/FitnessCatalogTests.swift`

**Interfaces:**
- Produce: `WorkoutRequest` with time, activity, duration, sets, reps, equipment, and difficulty.
- Produce: `WorkoutIntentParser.parse(_:)`.

- [x] Test “上午十点，做 5 分钟拉伸” keeps 10:00 and 5 minutes.
- [x] Test “上午十点，做 80 个俯卧撑一组，共 2 组” keeps `2 x 80`.
- [x] Test equipment, running, jumping, and sport phrases.
- [x] Implement parsing and explicit-over-template precedence.
- [ ] Commit.

### Task 6: Expand Exercise Taxonomy

**Files:**
- Modify: `Trellis/FitnessCatalog.swift`
- Create: `Trellis/ExpandedActivityCatalog.swift`
- Modify: `Trellis/FitnessView.swift`

**Interfaces:**
- Produce activity categories: strength, cardio, running, jumping, cycling, sport, mobility, equipment.
- Consume: public-domain `free-exercise-db` data where accurately mapped.

- [x] Add equipment and sport definitions.
- [x] Add duration, distance, interval, and set/rep workout builders.
- [x] Add filters for equipment and activity type.
- [ ] Keep animation media limited to accurately mapped public-domain assets.
- [ ] Commit.

### Task 7: Voice Routing and Confirmation

**Files:**
- Modify: `Trellis/VoiceTaskCaptureModel.swift`
- Modify: `Trellis/VoiceTaskCaptureView.swift`
- Test: `TrellisTests/VoiceTaskParserTests.swift`

**Interfaces:**
- Produce `VoiceIntent`: task, workout, record, plan-control, or review.

- [ ] Parse and display “我理解成”.
- [ ] Route fitness phrases to `WorkoutRequest` instead of title-only tasks.
- [ ] Require confirmation before save, clear, or replacement.
- [ ] Add record and plan-control examples.
- [ ] Commit.

### Task 8: Verification and TestFlight

- [ ] Build all targets.
- [ ] Run parser/model tests.
- [ ] Archive signed build.
- [ ] Attach to internal Debug group.
- [ ] Report evidence and any on-device-only checks.
