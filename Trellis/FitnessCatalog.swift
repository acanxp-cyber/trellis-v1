import Foundation

enum FitnessFocus: String, CaseIterable, Identifiable, Sendable {
    case upper
    case lower
    case core
    case fullBody
    case mobility
    case cardio
    case equipment
    case sport

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
        case .cardio:
            return "跑步有氧"
        case .equipment:
            return "器械训练"
        case .sport:
            return "运动项目"
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
        case .cardio:
            return "走路、跑步、跳绳与心肺"
        case .equipment:
            return "哑铃、杠铃、弹力带与器械"
        case .sport:
            return "球类、游泳与户外运动"
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
        case .cardio:
            return "figure.run"
        case .equipment:
            return "dumbbell.fill"
        case .sport:
            return "sportscourt.fill"
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
    var prescriptionOverride: String?

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
    let durationMinutes: Int?
    let doseSummary: String?
    let summary: String
    let blocks: [FitnessRoutineBlock]
    let safetyNote: String
    let matchedExerciseTitle: String?

    var id: String { focus.rawValue }

    var quantityLabel: String {
        if let durationMinutes {
            return "\(durationMinutes) 分钟"
        }
        if let doseSummary {
            return doseSummary
        }
        return "按组完成"
    }

    func taskDraft(
        scheduledAt: Date,
        reminderLeadMinutes: Int = 5
    ) -> VoiceTaskDraft {
        VoiceTaskDraft(
            title: "\(title)\(durationOrDoseLabel)",
            scheduledAt: scheduledAt,
            reminderLeadMinutes: reminderLeadMinutes
        )
    }

    private var durationOrDoseLabel: String {
        if let durationMinutes {
            return " · \(durationMinutes) 分钟"
        }
        if let doseSummary {
            return " · \(doseSummary)"
        }
        return ""
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
        FitnessExercise(title: "快走", focus: .cardio, level: .beginner, targets: "心肺、下肢", prescription: "10–30 分钟", method: "保持能说短句的速度，脚步轻，肩膀放松。", adjustment: "从 5–10 分钟开始。"),
        FitnessExercise(title: "慢跑", focus: .cardio, level: .beginner, targets: "心肺、下肢", prescription: "10–30 分钟", method: "用能正常对话的速度持续跑，落地保持轻。", adjustment: "跑走交替。"),
        FitnessExercise(title: "间歇跑", focus: .cardio, level: .intermediate, targets: "心肺、速度", prescription: "6 组 × 快跑 30 秒 + 慢走 60 秒", method: "快跑保持可控，恢复段完全放松。", adjustment: "改为快走 30 秒 + 慢走 90 秒。"),
        FitnessExercise(title: "跳绳", focus: .cardio, level: .intermediate, targets: "心肺、小腿、协调", prescription: "5 组 × 30–60 秒", method: "小幅度弹跳，手腕摇绳，落地轻。", adjustment: "无绳原地摆臂跳。"),
        FitnessExercise(title: "楼梯训练", focus: .cardio, level: .intermediate, targets: "腿、臀、心肺", prescription: "6–10 趟", method: "上楼稳定发力，下楼放慢并扶稳。", adjustment: "只上楼，乘电梯下楼。"),
        FitnessExercise(title: "椭圆机", focus: .cardio, level: .beginner, targets: "心肺、下肢", prescription: "10–20 分钟", method: "脚掌贴稳踏板，阻力以能保持节奏为准。", adjustment: "降低阻力。"),
        FitnessExercise(title: "动感单车", focus: .cardio, level: .beginner, targets: "心肺、腿", prescription: "10–20 分钟", method: "调好座高，保持稳定踩踏，不耸肩。", adjustment: "降低阻力和时间。"),
        FitnessExercise(title: "原地踏步", focus: .cardio, level: .beginner, targets: "心肺、下肢", prescription: "5–15 分钟", method: "交替抬脚并自然摆臂，保持呼吸顺畅。", adjustment: "减小抬脚高度。"),
        FitnessExercise(title: "低冲击有氧", focus: .cardio, level: .beginner, targets: "心肺、全身", prescription: "8–15 分钟", method: "踏步、侧点和轻摆臂组合，不跳跃。", adjustment: "只做原地踏步。"),
        FitnessExercise(title: "爬坡走", focus: .cardio, level: .intermediate, targets: "臀、腿、心肺", prescription: "8–20 分钟", method: "使用跑步机坡度或缓坡，保持上身直立。", adjustment: "降低坡度与速度。"),
        FitnessExercise(title: "哑铃深蹲", focus: .equipment, level: .beginner, targets: "腿、臀", prescription: "3 组 × 8–12 次", method: "双手持哑铃靠近身体，按深蹲动作完成。", adjustment: "徒手深蹲。"),
        FitnessExercise(title: "哑铃卧推", focus: .equipment, level: .beginner, targets: "胸、肱三头肌", prescription: "3 组 × 8–12 次", method: "仰卧稳定肩胛，哑铃下降后向上推。", adjustment: "使用更轻重量或上斜俯卧撑。"),
        FitnessExercise(title: "单臂哑铃划船", focus: .equipment, level: .beginner, targets: "背、肱二头肌", prescription: "3 组 × 每侧 8–12 次", method: "支撑稳定，肘部沿身体向后拉。", adjustment: "弹力带划船。"),
        FitnessExercise(title: "哑铃肩推", focus: .equipment, level: .intermediate, targets: "肩、肱三头肌", prescription: "3 组 × 6–10 次", method: "肋骨保持下沉，向上推举不过度反弓。", adjustment: "坐姿并减轻重量。"),
        FitnessExercise(title: "杠铃深蹲", focus: .equipment, level: .intermediate, targets: "腿、臀、核心", prescription: "3–5 组 × 5–8 次", method: "使用安全架和熟悉重量，膝盖对齐脚尖。", adjustment: "高脚杯深蹲。"),
        FitnessExercise(title: "罗马尼亚硬拉", focus: .equipment, level: .intermediate, targets: "腿后侧、臀、背", prescription: "3 组 × 6–10 次", method: "髋部后移，负重贴近腿，背部保持中立。", adjustment: "徒手髋铰链。"),
        FitnessExercise(title: "弹力带划船", focus: .equipment, level: .beginner, targets: "背、肱二头肌", prescription: "3 组 × 10–15 次", method: "固定弹力带，肩胛后收后拉向腹部。", adjustment: "缩短拉伸距离。"),
        FitnessExercise(title: "弹力带侧步", focus: .equipment, level: .beginner, targets: "臀中肌", prescription: "2–3 组 × 每侧 10 步", method: "弹力带套在膝上或踝部，小步侧移。", adjustment: "减小步幅。"),
        FitnessExercise(title: "壶铃摆动", focus: .equipment, level: .intermediate, targets: "臀、腿后侧、核心", prescription: "3 组 × 10–15 次", method: "以髋铰链驱动摆动，不用手臂硬抬。", adjustment: "徒手髋铰链。"),
        FitnessExercise(title: "坐姿胸推机", focus: .equipment, level: .beginner, targets: "胸、肱三头肌", prescription: "3 组 × 8–12 次", method: "调整座椅使把手与胸口同高，平稳推离。", adjustment: "降低重量。"),
        FitnessExercise(title: "腿举机", focus: .equipment, level: .beginner, targets: "腿、臀", prescription: "3 组 × 8–12 次", method: "腰背贴稳靠垫，膝盖朝脚尖方向屈伸。", adjustment: "缩小活动范围。"),
        FitnessExercise(title: "高位下拉", focus: .equipment, level: .beginner, targets: "背、肱二头肌", prescription: "3 组 × 8–12 次", method: "肩胛先下沉，再将把手拉向锁骨附近。", adjustment: "减轻重量。"),
        FitnessExercise(title: "篮球投篮", focus: .sport, level: .beginner, targets: "协调、肩、腿", prescription: "10–20 分钟", method: "从近距离定点投篮开始，动作连贯，落地稳定。", adjustment: "缩短距离。"),
        FitnessExercise(title: "足球带球", focus: .sport, level: .intermediate, targets: "心肺、协调、腿", prescription: "8–15 分钟", method: "小步触球，保持抬头和可控速度。", adjustment: "慢速绕桩。"),
        FitnessExercise(title: "羽毛球步法", focus: .sport, level: .intermediate, targets: "腿、心肺、协调", prescription: "6 组 × 30 秒", method: "前后左右小步移动，每次回到中心。", adjustment: "降低移动速度。"),
        FitnessExercise(title: "乒乓球对练", focus: .sport, level: .beginner, targets: "协调、心肺", prescription: "10–20 分钟", method: "先以稳定对拉和轻移动为主。", adjustment: "缩短回合时间。"),
        FitnessExercise(title: "网球挥拍", focus: .sport, level: .intermediate, targets: "肩、核心、腿", prescription: "10–20 分钟", method: "先做徒手挥拍与脚步，再进入轻对练。", adjustment: "只做空挥和步法。"),
        FitnessExercise(title: "自由泳", focus: .sport, level: .intermediate, targets: "全身、心肺", prescription: "10–20 分钟", method: "分组游，保持呼吸节奏，量力而行。", adjustment: "使用浮具或缩短距离。"),
        FitnessExercise(title: "户外骑行", focus: .sport, level: .beginner, targets: "腿、心肺", prescription: "20–40 分钟", method: "选择安全路线，保持可控速度和刹车距离。", adjustment: "室内动感单车。"),
        FitnessExercise(title: "徒步爬坡", focus: .sport, level: .beginner, targets: "腿、臀、心肺", prescription: "20–60 分钟", method: "选择熟悉路线，坡段放慢并保持补水。", adjustment: "平地快走。"),
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
        if let request = WorkoutIntentParser.parse(
            transcript,
            now: now
        ) {
            return recommendation(for: request, now: now)
        }
        if let match = FitnessExerciseMatcher.match(in: transcript) {
            return recommendation(
                for: match.exercise,
                now: now
            )
        }
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
            doseSummary: nil,
            summary: focus.subtitle,
            blocks: [warmup, strength, cooldown],
            safetyNote: "这是一份一般健身建议，不替代医疗诊断或康复处方。若开始训练前已有伤病、疼痛或身体不适，请先咨询医生或合格教练。",
            matchedExerciseTitle: nil
        )
    }

    static func recommendation(
        for matchedExercise: FitnessExercise,
        now: Date = .now
    ) -> FitnessRoutineRecommendation {
        let base = recommendation(
            for: matchedExercise.focus,
            now: now
        )
        let matchedItem = FitnessRoutineItem(
            exercise: matchedExercise,
            cue: "作为本次主动作，先保证动作稳定"
        )
        let relatedItems = base.blocks[1].items.filter {
            $0.exercise.id != matchedExercise.id
        }
        let mainBlock = FitnessRoutineBlock(
            title: "主训练 · 12 分钟",
            detail: "已围绕“\(matchedExercise.title)”安排相关动作；组间休息 30–45 秒。",
            items: [matchedItem] + relatedItems
        )

        return FitnessRoutineRecommendation(
            focus: matchedExercise.focus,
            title: "\(matchedExercise.title)相关训练",
            durationMinutes: 20,
            doseSummary: nil,
            summary: "识别为\(matchedExercise.title) · \(matchedExercise.targets)",
            blocks: [
                base.blocks[0],
                mainBlock,
                base.blocks[2],
            ],
            safetyNote: base.safetyNote,
            matchedExerciseTitle: matchedExercise.title
        )
    }

    static func recommendation(
        for request: WorkoutRequest,
        now: Date = .now
    ) -> FitnessRoutineRecommendation {
        let matchedExercise = request.matchedExerciseTitle.flatMap { title in
            FitnessCatalog.exercises.first { $0.title == title }
        }
        let base: FitnessRoutineRecommendation
        if let matchedExercise {
            base = recommendation(for: matchedExercise, now: now)
        } else {
            base = recommendation(for: request.focus, now: now)
        }

        let doseSummary: String?
        if let sets = request.sets, let reps = request.reps {
            doseSummary = "\(sets) 组 × \(reps) 次"
        } else {
            doseSummary = nil
        }

        let requestedDuration = request.durationMinutes
        let mainLimit: Int
        if doseSummary != nil {
            mainLimit = matchedExercise == nil ? 2 : 1
        } else if let requestedDuration, requestedDuration <= 5 {
            mainLimit = 2
        } else {
            mainLimit = 3
        }

        var mainItems = Array(base.blocks[1].items.prefix(mainLimit))
        if let doseSummary, !mainItems.isEmpty {
            mainItems[0].prescriptionOverride = doseSummary
        }

        let warmupMinutes: Int?
        let mainMinutes: Int?
        let cooldownMinutes: Int?
        if let requestedDuration {
            warmupMinutes = max(1, Int((Double(requestedDuration) * 0.2).rounded()))
            cooldownMinutes = max(1, Int((Double(requestedDuration) * 0.2).rounded()))
            mainMinutes = max(
                1,
                requestedDuration - warmupMinutes! - cooldownMinutes!
            )
        } else {
            warmupMinutes = nil
            mainMinutes = nil
            cooldownMinutes = nil
        }

        let warmupItemCount = requestedDuration == nil
            ? base.blocks[0].items.count
            : 1
        let cooldownItemCount = requestedDuration == nil
            ? base.blocks[2].items.count
            : 1
        let warmupBlock = FitnessRoutineBlock(
            title: warmupMinutes.map { "热身 · \($0) 分钟" } ?? "热身",
            detail: base.blocks[0].detail,
            items: Array(base.blocks[0].items.prefix(warmupItemCount))
        )
        let mainBlock = FitnessRoutineBlock(
            title: mainMinutes.map { "主训练 · \($0) 分钟" }
                ?? (doseSummary.map { "主训练 · \($0)" } ?? "主训练"),
            detail: request.matchedExerciseTitle.map {
                "主动作：\($0)，严格保留你指定的组数和次数。"
            } ?? base.blocks[1].detail,
            items: mainItems
        )
        let cooldownBlock = FitnessRoutineBlock(
            title: cooldownMinutes.map { "收尾 · \($0) 分钟" } ?? "收尾",
            detail: base.blocks[2].detail,
            items: Array(base.blocks[2].items.prefix(cooldownItemCount))
        )
        let activityTitle = request.equipment.map {
            "\($0)\(request.focus.title)训练"
        } ?? request.focus.title

        return FitnessRoutineRecommendation(
            focus: request.focus,
            title: request.matchedExerciseTitle.map {
                "\($0)相关训练"
            } ?? "\(activityTitle)安排",
            durationMinutes: doseSummary == nil
                ? (requestedDuration ?? base.durationMinutes)
                : nil,
            doseSummary: doseSummary,
            summary: [
                request.activityKind.rawValue,
                request.focus.subtitle,
            ].joined(separator: " · "),
            blocks: [warmupBlock, mainBlock, cooldownBlock],
            safetyNote: base.safetyNote,
            matchedExerciseTitle: request.matchedExerciseTitle
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
        FitnessExerciseMatcher.match(in: text) != nil
            || focus(in: text) != nil
    }

    static func focus(in text: String) -> FitnessFocus? {
        let value = text.lowercased()

        if containsAny(value, ["拉伸", "放松", "活动度", "热身", "恢复"]) {
            return .mobility
        }
        if containsAny(value, ["核心", "腹部", "腹肌", "腰腹"]) {
            return .core
        }
        if containsAny(
            value,
            ["哑铃", "杠铃", "弹力带", "壶铃", "器械", "胸推机", "腿举机", "高位下拉"]
        ) {
            return .equipment
        }
        if containsAny(
            value,
            ["篮球", "足球", "羽毛球", "乒乓球", "网球", "游泳", "骑行", "徒步"]
        ) {
            return .sport
        }
        if containsAny(
            value,
            ["跑", "快走", "慢跑", "跳绳", "有氧", "楼梯", "椭圆机", "动感单车"]
        ) {
            return .cardio
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

struct FitnessExerciseMatch: Equatable, Sendable {
    let exercise: FitnessExercise
    let matchedText: String
    let score: Double
}

enum FitnessExerciseMatcher {
    private static let aliases: [String: [String]] = [
        "标准俯卧撑": [
            "俯卧撑", "俯卧", "俯撑", "俯卧称", "伏地挺身",
            "push up", "pushup",
        ],
        "跪姿俯卧撑": ["跪姿俯卧撑", "跪姿俯撑", "knee pushup"],
        "上斜俯卧撑": ["上斜俯卧撑", "手撑高俯卧撑", "incline pushup"],
        "钻石俯卧撑": ["钻石俯卧撑", "窄距俯卧撑", "三头俯卧撑"],
        "折刀俯卧撑": ["折刀俯卧撑", "派克俯卧撑", "pike pushup"],
        "徒手深蹲": ["徒手深蹲", "深蹲", "bodyweight squat"],
        "相扑深蹲": ["相扑深蹲", "宽距深蹲", "sumo squat"],
        "反向箭步蹲": ["反向箭步蹲", "后撤箭步蹲", "后撤弓步", "reverse lunge"],
        "前向箭步蹲": ["前向箭步蹲", "前弓步", "forward lunge"],
        "侧向箭步蹲": ["侧向箭步蹲", "侧弓步", "side lunge"],
        "分腿蹲": ["分腿蹲", "split squat"],
        "臀桥": ["臀桥", "桥式", "glute bridge"],
        "单腿臀桥": ["单腿臀桥", "single leg glute bridge"],
        "提踵": ["提踵", "踮脚", "calf raise"],
        "靠墙静蹲": ["靠墙静蹲", "墙蹲", "wall sit"],
        "死虫": ["死虫", "dead bug"],
        "鸟狗": ["鸟狗", "bird dog"],
        "前臂平板支撑": ["前臂平板支撑", "平板支撑", "平板", "plank"],
        "侧平板支撑": ["侧平板支撑", "侧平板", "side plank"],
        "中空支撑": ["中空支撑", "hollow hold"],
        "卷腹": ["卷腹", "仰卧卷腹", "crunch"],
        "反向卷腹": ["反向卷腹", "reverse crunch"],
        "自行车卷腹": ["自行车卷腹", "空中自行车", "bicycle crunch"],
        "登山跑": ["登山跑", "登山者", "mountain climber"],
        "熊爬支撑": ["熊爬支撑", "bear crawl hold"],
        "开合跳": ["开合跳", "jumping jack"],
        "高抬腿": ["高抬腿", "high knees"],
        "波比跳": ["波比跳", "波比", "burpee"],
        "深蹲上举": ["深蹲上举", "squat reach"],
        "尺蠖爬": ["尺蠖爬", "inchworm"],
        "熊爬": ["熊爬", "bear crawl"],
        "蟹式触脚": ["蟹式触脚", "crab toe touch"],
        "后撤步触地": ["后撤步触地", "back step reach"],
        "交叉登山跑": ["交叉登山跑", "cross mountain climber"],
        "原地空击": ["原地空击", "空击", "shadow boxing"],
        "猫牛式": ["猫牛式", "猫牛", "cat cow"],
        "胸椎旋转": ["胸椎旋转", "thoracic rotation"],
        "世界最伟大拉伸": ["世界最伟大拉伸", "greatest stretch"],
        "站姿腿后侧伸展": ["腿后侧拉伸", "腘绳肌拉伸", "hamstring stretch"],
        "站姿股四头肌拉伸": ["股四头肌拉伸", "大腿前侧拉伸", "quad stretch"],
        "髋屈肌拉伸": ["髋屈肌拉伸", "hip flexor stretch"],
        "小腿靠墙拉伸": ["小腿拉伸", "calf stretch"],
        "婴儿式": ["婴儿式", "child pose"],
    ]

    static func match(in transcript: String) -> FitnessExerciseMatch? {
        let normalized = normalize(transcript)
        guard !normalized.isEmpty else {
            return nil
        }

        let aliasCandidates = aliases.flatMap { title, values in
            values.map { (title, $0) }
        }
        .sorted { normalize($0.1).count > normalize($1.1).count }

        for (title, alias) in aliasCandidates {
            let normalizedAlias = normalize(alias)
            guard
                normalizedAlias.count >= 2,
                normalized.contains(normalizedAlias),
                let exercise = FitnessCatalog.exercises.first(where: {
                    $0.title == title
                })
            else {
                continue
            }
            return FitnessExerciseMatch(
                exercise: exercise,
                matchedText: alias,
                score: 1
            )
        }

        var best: FitnessExerciseMatch?
        for exercise in FitnessCatalog.exercises {
            let title = normalize(exercise.title)
            let distance = editDistance(normalized, title)
            let denominator = max(normalized.count, title.count, 1)
            let score = 1 - Double(distance) / Double(denominator)
            let allowedDistance = title.count <= 3 ? 1 : 2
            guard
                normalized.contains(title)
                    || distance <= allowedDistance
            else {
                continue
            }
            if score > (best?.score ?? 0) {
                best = FitnessExerciseMatch(
                    exercise: exercise,
                    matchedText: exercise.title,
                    score: score
                )
            }
        }
        return best
    }

    private static func normalize(_ value: String) -> String {
        let fillers = [
            "我想", "我要", "帮我", "给我", "今天", "现在",
            "安排", "训练", "锻炼", "健身", "做一组", "做一下",
            "做个", "练一下", "练个", "做", "练", "组",
        ]
        var result = value.lowercased()
        for filler in fillers {
            result = result.replacingOccurrences(of: filler, with: "")
        }
        return result.filter { character in
            character.isLetter || character.isNumber
        }
    }

    private static func editDistance(_ left: String, _ right: String) -> Int {
        let lhs = Array(left)
        let rhs = Array(right)
        if lhs.isEmpty {
            return rhs.count
        }
        if rhs.isEmpty {
            return lhs.count
        }

        var previous = Array(0...rhs.count)
        for (leftIndex, leftCharacter) in lhs.enumerated() {
            var current = Array(repeating: 0, count: rhs.count + 1)
            current[0] = leftIndex + 1
            for (rightIndex, rightCharacter) in rhs.enumerated() {
                let cost = leftCharacter == rightCharacter ? 0 : 1
                current[rightIndex + 1] = min(
                    current[rightIndex] + 1,
                    previous[rightIndex + 1] + 1,
                    previous[rightIndex] + cost
                )
            }
            previous = current
        }
        return previous[rhs.count]
    }
}
