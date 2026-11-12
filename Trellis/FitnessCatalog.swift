import Foundation

enum FitnessFocus: String, CaseIterable, Identifiable, Sendable {
    case upper
    case lower
    case core
    case fullBody
    case mobility

    var id: String { rawValue }

    var title: String {
        switch self {
        case .upper:
            return "上肢"
        case .lower:
            return "下肢"
        case .core:
            return "核心"
        case .fullBody:
            return "全身"
        case .mobility:
            return "拉伸放松"
        }
    }

    var subtitle: String {
        switch self {
        case .upper:
            return "胸、背、肩与手臂"
        case .lower:
            return "腿、臀与髋"
        case .core:
            return "躯干稳定与腹部"
        case .fullBody:
            return "协调、心肺与全身力量"
        case .mobility:
            return "热身、活动度与恢复"
        }
    }

    var systemImage: String {
        switch self {
        case .upper:
            return "figure.strengthtraining.traditional"
        case .lower:
            return "figure.step.training"
        case .core:
            return "figure.core.training"
        case .fullBody:
            return "figure.highintensity.intervaltraining"
        case .mobility:
            return "figure.flexibility"
        }
    }
}

enum FitnessLevel: String, Sendable {
    case beginner = "入门"
    case intermediate = "进阶"
    case advanced = "挑战"
}

struct FitnessExercise: Identifiable, Hashable, Sendable {
    let title: String
    let focus: FitnessFocus
    let level: FitnessLevel
    let targets: String
    let prescription: String
    let method: String
    let adjustment: String

    var id: String { title }
}

struct FitnessRoutineItem: Identifiable, Hashable, Sendable {
    let exercise: FitnessExercise
    let cue: String

    var id: String { exercise.id }
}

struct FitnessRoutineBlock: Identifiable, Hashable, Sendable {
    let title: String
    let detail: String
    let items: [FitnessRoutineItem]

    var id: String { title }
}

struct FitnessRoutineRecommendation: Identifiable, Hashable, Sendable {
    let focus: FitnessFocus
    let title: String
    let durationMinutes: Int
    let summary: String
    let blocks: [FitnessRoutineBlock]
    let safetyNote: String

    var id: String { focus.rawValue }

    func taskDraft(
        scheduledAt: Date,
        reminderLeadMinutes: Int = 5
    ) -> VoiceTaskDraft {
        VoiceTaskDraft(
            title: "\(title) · \(durationMinutes) 分钟",
            scheduledAt: scheduledAt,
            reminderLeadMinutes: reminderLeadMinutes
        )
    }
}

enum FitnessCatalog {
    static let exercises: [FitnessExercise] = [
        FitnessExercise(title: "扶墙俯卧撑", focus: .upper, level: .beginner, targets: "胸、肩、肱三头肌", prescription: "2 组 × 10–15 次", method: "双手扶墙略宽于肩，身体保持直线，屈肘靠近墙面后推回。", adjustment: "越靠近墙越轻松。"),
        FitnessExercise(title: "上斜俯卧撑", focus: .upper, level: .beginner, targets: "胸、肩、肱三头肌", prescription: "3 组 × 8–12 次", method: "双手撑在桌沿，肩胛稳定，胸口靠近桌沿后推起。", adjustment: "降低支撑高度可提高难度。"),
        FitnessExercise(title: "跪姿俯卧撑", focus: .upper, level: .beginner, targets: "胸、肩、肱三头肌", prescription: "3 组 × 8–12 次", method: "膝盖着地，从头到膝保持直线，肘部约向后 45 度屈伸。", adjustment: "在手下垫高可降低手腕压力。"),
        FitnessExercise(title: "标准俯卧撑", focus: .upper, level: .intermediate, targets: "胸、肩、肱三头肌、核心", prescription: "3–4 组 × 6–12 次", method: "手脚撑地，身体从头到脚保持直线，胸口接近地面后推起。", adjustment: "动作变形时改为跪姿或上斜。"),
        FitnessExercise(title: "宽距俯卧撑", focus: .upper, level: .intermediate, targets: "胸、肩", prescription: "3 组 × 6–10 次", method: "双手略宽于肩，控制下降，肘部不要过度外张。", adjustment: "肩部不适时恢复标准距离。"),
        FitnessExercise(title: "钻石俯卧撑", focus: .upper, level: .advanced, targets: "肱三头肌、胸", prescription: "3 组 × 5–8 次", method: "双手在胸口下方靠近，肘部贴近身体完成屈伸。", adjustment: "先做窄距上斜俯卧撑。"),
        FitnessExercise(title: "折刀俯卧撑", focus: .upper, level: .advanced, targets: "肩、肱三头肌", prescription: "3 组 × 5–8 次", method: "臀部抬高成倒 V，头部向双手之间下降后推起。", adjustment: "手撑椅子可降低难度。"),
        FitnessExercise(title: "椅式臂屈伸", focus: .upper, level: .beginner, targets: "肱三头肌、肩", prescription: "3 组 × 8–12 次", method: "双手撑住稳定椅沿，屈肘下沉，胸口保持打开后推起。", adjustment: "屈膝、缩小下蹲幅度更轻松。"),
        FitnessExercise(title: "反向划船", focus: .upper, level: .intermediate, targets: "背、肱二头肌", prescription: "3 组 × 6–10 次", method: "握住稳固桌沿或低杆，身体后仰保持直线，将胸口拉向支撑物。", adjustment: "身体越直立越轻松。"),
        FitnessExercise(title: "俯卧超人", focus: .upper, level: .beginner, targets: "背、臀", prescription: "2–3 组 × 8–12 次", method: "俯卧同时抬起手臂与腿，保持颈部自然，不要过度反弓。", adjustment: "只抬手臂或只抬腿。"),
        FitnessExercise(title: "俯卧 Y-T-W", focus: .upper, level: .beginner, targets: "上背、肩胛稳定", prescription: "每个字母 6–8 次", method: "俯卧抬臂分别形成 Y、T、W，动作缓慢，感受肩胛移动。", adjustment: "胸前垫毛巾减少颈部压力。"),
        FitnessExercise(title: "肩碰平板支撑", focus: .upper, level: .intermediate, targets: "肩、核心", prescription: "2 组 × 每侧 8 次", method: "高位平板撑，交替用手触碰对侧肩，骨盆保持稳定。", adjustment: "膝盖着地完成。"),
        FitnessExercise(title: "徒手深蹲", focus: .lower, level: .beginner, targets: "股四头肌、臀、腿后侧", prescription: "3 组 × 10–15 次", method: "双脚与肩同宽，髋部向后下坐，膝盖朝脚尖方向。", adjustment: "扶椅或坐到椅子上再站起。"),
        FitnessExercise(title: "相扑深蹲", focus: .lower, level: .beginner, targets: "臀、大腿内侧", prescription: "3 组 × 10–12 次", method: "站距略宽、脚尖外展，髋部下沉后脚掌发力站起。", adjustment: "缩小站距降低难度。"),
        FitnessExercise(title: "反向箭步蹲", focus: .lower, level: .beginner, targets: "臀、股四头肌", prescription: "3 组 × 每侧 8–10 次", method: "一脚后撤并下沉，前脚掌与后脚掌同时发力回到站姿。", adjustment: "扶墙保持平衡。"),
        FitnessExercise(title: "前向箭步蹲", focus: .lower, level: .intermediate, targets: "臀、股四头肌", prescription: "3 组 × 每侧 6–10 次", method: "向前迈步，双膝屈曲，前膝对齐脚尖后推回。", adjustment: "缩短步幅并扶墙。"),
        FitnessExercise(title: "侧向箭步蹲", focus: .lower, level: .intermediate, targets: "臀中肌、大腿内侧", prescription: "3 组 × 每侧 6–10 次", method: "向侧面跨步，支撑腿屈髋屈膝，另一腿保持伸直。", adjustment: "支撑腿微屈即可。"),
        FitnessExercise(title: "分腿蹲", focus: .lower, level: .intermediate, targets: "臀、股四头肌", prescription: "3 组 × 每侧 8–10 次", method: "前后分腿站定，垂直下沉后前脚发力站起。", adjustment: "扶椅完成。"),
        FitnessExercise(title: "臀桥", focus: .lower, level: .beginner, targets: "臀、腿后侧", prescription: "3 组 × 12–15 次", method: "仰卧屈膝，脚掌踩地，收紧臀部抬起骨盆。", adjustment: "缩小抬起幅度。"),
        FitnessExercise(title: "单腿臀桥", focus: .lower, level: .advanced, targets: "臀、腿后侧", prescription: "2–3 组 × 每侧 6–8 次", method: "一腿支撑一腿抬起，保持骨盆水平后抬髋。", adjustment: "先做双腿臀桥。"),
        FitnessExercise(title: "提踵", focus: .lower, level: .beginner, targets: "小腿", prescription: "3 组 × 15–20 次", method: "站稳后缓慢踮脚，再控制脚跟下落。", adjustment: "扶墙保持平衡。"),
        FitnessExercise(title: "靠墙静蹲", focus: .lower, level: .beginner, targets: "股四头肌、臀", prescription: "2–3 组 × 20–40 秒", method: "背靠墙下滑至舒适半蹲，膝盖朝脚尖方向。", adjustment: "减小下蹲角度。"),
        FitnessExercise(title: "死虫", focus: .core, level: .beginner, targets: "腹部、躯干稳定", prescription: "2–3 组 × 每侧 8 次", method: "仰卧抬腿，交替伸出对侧手脚，腰背保持贴地。", adjustment: "只做腿部或只做手臂。"),
        FitnessExercise(title: "鸟狗", focus: .core, level: .beginner, targets: "核心、臀、背部", prescription: "2–3 组 × 每侧 8 次", method: "四点支撑，交替伸出对侧手脚，骨盆保持稳定。", adjustment: "先只伸手或只伸腿。"),
        FitnessExercise(title: "前臂平板支撑", focus: .core, level: .beginner, targets: "核心、肩", prescription: "2–3 组 × 20–40 秒", method: "肘部在肩下，身体从头到脚保持直线，自然呼吸。", adjustment: "膝盖着地或抬高上身。"),
        FitnessExercise(title: "侧平板支撑", focus: .core, level: .intermediate, targets: "侧腹、臀中肌", prescription: "2 组 × 每侧 15–30 秒", method: "侧卧撑起身体，保持肩、髋、脚踝成直线。", adjustment: "下侧膝盖着地。"),
        FitnessExercise(title: "中空支撑", focus: .core, level: .intermediate, targets: "腹部", prescription: "3 组 × 15–30 秒", method: "仰卧抬起肩和腿，腰部贴地，肋骨下沉。", adjustment: "屈膝并抬高上身。"),
        FitnessExercise(title: "卷腹", focus: .core, level: .beginner, targets: "腹部", prescription: "2–3 组 × 10–15 次", method: "仰卧屈膝，收下巴并卷起肩胛，避免拉头。", adjustment: "缩小动作幅度。"),
        FitnessExercise(title: "反向卷腹", focus: .core, level: .beginner, targets: "下腹", prescription: "2–3 组 × 8–12 次", method: "仰卧屈膝，用腹部把骨盆轻轻卷离地面。", adjustment: "只做骨盆后倾。"),
        FitnessExercise(title: "自行车卷腹", focus: .core, level: .intermediate, targets: "腹部、侧腹", prescription: "2 组 × 每侧 8–12 次", method: "肩胛离地，交替转体让对侧肘膝靠近。", adjustment: "放慢速度、减小转体。"),
        FitnessExercise(title: "登山跑", focus: .core, level: .intermediate, targets: "核心、心肺", prescription: "3 组 × 20–30 秒", method: "高位平板撑，交替把膝盖向胸口提起。", adjustment: "改为慢速交替提膝。"),
        FitnessExercise(title: "熊爬支撑", focus: .core, level: .intermediate, targets: "核心、肩、髋", prescription: "2–3 组 × 20–30 秒", method: "四点支撑，膝盖离地少许，保持背部平稳。", adjustment: "保持膝盖轻触地面。"),
        FitnessExercise(title: "开合跳", focus: .fullBody, level: .beginner, targets: "全身、心肺", prescription: "3 组 × 20–30 秒", method: "双脚开合跳，同时双臂上举，落地保持轻。", adjustment: "改为左右点步。"),
        FitnessExercise(title: "高抬腿", focus: .fullBody, level: .beginner, targets: "髋、核心、心肺", prescription: "3 组 × 20–30 秒", method: "原地交替抬腿至髋部高度，保持上身稳定。", adjustment: "改为慢速踏步。"),
        FitnessExercise(title: "波比跳", focus: .fullBody, level: .advanced, targets: "全身、心肺", prescription: "3 组 × 5–8 次", method: "下蹲撑地、后跳成平板、收回双脚后起身，节奏可控。", adjustment: "取消跳跃并逐步完成。"),
        FitnessExercise(title: "深蹲上举", focus: .fullBody, level: .beginner, targets: "腿、臀、肩", prescription: "3 组 × 10–12 次", method: "深蹲站起时双臂上举，保持肋骨不过度外翻。", adjustment: "只做深蹲。"),
        FitnessExercise(title: "尺蠖爬", focus: .fullBody, level: .intermediate, targets: "肩、核心、腿后侧", prescription: "2–3 组 × 6–8 次", method: "站姿俯身撑地，手向前走到平板，再走回站起。", adjustment: "缩小走手距离。"),
        FitnessExercise(title: "熊爬", focus: .fullBody, level: .intermediate, targets: "全身协调、核心", prescription: "3 组 × 15–20 秒", method: "膝盖离地少许，对侧手脚小步向前移动。", adjustment: "原地熊爬支撑。"),
        FitnessExercise(title: "蟹式触脚", focus: .fullBody, level: .advanced, targets: "后链、肩、核心", prescription: "2 组 × 每侧 6–8 次", method: "反向支撑抬髋，交替抬脚和对侧手相触。", adjustment: "只做反向支撑抬髋。"),
        FitnessExercise(title: "后撤步触地", focus: .fullBody, level: .intermediate, targets: "腿、臀、平衡", prescription: "3 组 × 每侧 8 次", method: "单腿后撤并触地，再回到站姿，保持膝盖稳定。", adjustment: "扶墙减少平衡要求。"),
        FitnessExercise(title: "交叉登山跑", focus: .fullBody, level: .intermediate, targets: "核心、肩、心肺", prescription: "3 组 × 20 秒", method: "平板撑中让膝盖向对侧肘靠近，骨盆保持稳定。", adjustment: "慢速完成。"),
        FitnessExercise(title: "原地空击", focus: .fullBody, level: .beginner, targets: "肩、核心、心肺", prescription: "3 组 × 30 秒", method: "轻步移动并交替出拳，肩膀放松、核心收紧。", adjustment: "只做轻步和单侧出拳。"),
        FitnessExercise(title: "猫牛式", focus: .mobility, level: .beginner, targets: "脊柱活动度", prescription: "8–10 次", method: "四点支撑，随呼吸交替拱背与沉背。", adjustment: "缩小活动范围。"),
        FitnessExercise(title: "胸椎旋转", focus: .mobility, level: .beginner, targets: "胸椎、肩", prescription: "每侧 6–8 次", method: "侧卧屈膝，手臂随胸廓旋转打开，骨盆保持稳定。", adjustment: "用毛巾垫头。"),
        FitnessExercise(title: "世界最伟大拉伸", focus: .mobility, level: .intermediate, targets: "髋、胸椎、腿后侧", prescription: "每侧 5 次", method: "弓步撑地后转体抬臂，再回到中间换侧。", adjustment: "取消转体，只做弓步伸展。"),
        FitnessExercise(title: "站姿腿后侧伸展", focus: .mobility, level: .beginner, targets: "腿后侧", prescription: "每侧 20–30 秒", method: "一脚脚跟点地、脚尖回勾，髋部向后坐并保持背部平直。", adjustment: "屈膝减少拉伸强度。"),
        FitnessExercise(title: "站姿股四头肌拉伸", focus: .mobility, level: .beginner, targets: "大腿前侧", prescription: "每侧 20–30 秒", method: "扶墙站稳，屈膝拉脚靠近臀部，膝盖保持并拢。", adjustment: "用毛巾辅助拉脚。"),
        FitnessExercise(title: "髋屈肌拉伸", focus: .mobility, level: .beginner, targets: "髋前侧", prescription: "每侧 20–30 秒", method: "半跪姿收紧臀部，骨盆轻轻向前移动。", adjustment: "在膝下垫软垫。"),
        FitnessExercise(title: "小腿靠墙拉伸", focus: .mobility, level: .beginner, targets: "小腿", prescription: "每侧 20–30 秒", method: "双手扶墙，一腿后撤并踩实脚跟，身体前移。", adjustment: "缩小前移幅度。"),
        FitnessExercise(title: "婴儿式", focus: .mobility, level: .beginner, targets: "背、髋、肩", prescription: "30–45 秒", method: "跪坐后身体前屈，双臂向前延伸，自然呼吸。", adjustment: "膝下或额头垫软垫。"),
    ]

    static func exercises(for focus: FitnessFocus) -> [FitnessExercise] {
        exercises.filter { $0.focus == focus }
    }

    static func exercises(for focus: FitnessFocus, level: FitnessLevel) -> [FitnessExercise] {
        exercises(for: focus).filter { $0.level == level }
    }
}

enum FitnessIntentParser {
    static func recommendation(
        from transcript: String,
        now: Date = .now
    ) -> FitnessRoutineRecommendation? {
        guard let focus = focus(in: transcript) else {
            return nil
        }
        return recommendation(for: focus, now: now)
    }

    static func recommendation(
        for focus: FitnessFocus,
        now: Date = .now
    ) -> FitnessRoutineRecommendation {
        let focusExercises = FitnessCatalog.exercises(for: focus)
        let strengthStart = min(2, max(0, focusExercises.count - 4))
        let strengthExercises = Array(
            focusExercises.dropFirst(strengthStart).prefix(4)
        )
        let mobility = FitnessCatalog.exercises(for: .mobility)
        let warmupExercises = Array(mobility.prefix(2))
        let cooldownExercises = Array(mobility.suffix(2))

        let warmup = FitnessRoutineBlock(
            title: "热身 · 3 分钟",
            detail: "先让关节进入活动范围，再开始力量部分。",
            items: warmupExercises.map {
                FitnessRoutineItem(
                    exercise: $0,
                    cue: "轻松完成，不追求拉伸痛感"
                )
            }
        )
        let strength = FitnessRoutineBlock(
            title: "主训练 · 12 分钟",
            detail: "动作之间休息 30–45 秒；保持可控节奏，每组留 2 次余力。",
            items: strengthExercises.map {
                FitnessRoutineItem(
                    exercise: $0,
                    cue: "动作稳定优先，出现疼痛立即停止"
                )
            }
        )
        let cooldown = FitnessRoutineBlock(
            title: "收尾 · 5 分钟",
            detail: "呼吸恢复平稳后再结束。",
            items: cooldownExercises.map {
                FitnessRoutineItem(
                    exercise: $0,
                    cue: "自然呼吸，不弹震"
                )
            }
        )

        return FitnessRoutineRecommendation(
            focus: focus,
            title: "\(focus.title)徒手训练",
            durationMinutes: 20,
            summary: focus.subtitle,
            blocks: [warmup, strength, cooldown],
            safetyNote: "这是一份一般健身建议，不替代医疗诊断或康复处方。若开始训练前已有伤病、疼痛或身体不适，请先咨询医生或合格教练。"
        )
    }

    static func suggestedStart(
        now: Date = .now,
        calendar: Calendar = .trellis
    ) -> Date {
        let minute = calendar.component(.minute, from: now)
        let minutesToNextQuarter = 15 - (minute % 15)
        let earliest = calendar.date(
            byAdding: .minute,
            value: minutesToNextQuarter,
            to: now
        ) ?? now.addingTimeInterval(15 * 60)
        let hour = calendar.component(.hour, from: earliest)
        if hour >= 22 {
            let tomorrow = calendar.date(
                byAdding: .day,
                value: 1,
                to: earliest
            ) ?? earliest
            return calendar.date(
                bySettingHour: 7,
                minute: 30,
                second: 0,
                of: tomorrow
            ) ?? tomorrow
        }
        return earliest
    }

    static func containsFitnessIntent(_ text: String) -> Bool {
        focus(in: text) != nil
    }

    private static func focus(in text: String) -> FitnessFocus? {
        let value = text.lowercased()

        if containsAny(value, ["拉伸", "放松", "活动度", "热身", "恢复"]) {
            return .mobility
        }
        if containsAny(value, ["核心", "腹部", "腹肌", "腰腹"]) {
            return .core
        }
        if containsAny(value, ["下肢", "下半身", "腿", "臀", "深蹲", "箭步"]) {
            return .lower
        }
        if containsAny(value, ["上肢", "上半身", "胸", "背", "肩", "手臂", "俯卧撑"]) {
            return .upper
        }
        if containsAny(value, ["全身", "体能", "心肺", "减脂", "健身", "训练", "锻炼"]) {
            return .fullBody
        }
        return nil
    }

    private static func containsAny(_ value: String, _ terms: [String]) -> Bool {
        terms.contains { value.contains($0) }
    }
}
