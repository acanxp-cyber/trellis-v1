import Combine
import Foundation
import SwiftUI
import UIKit

@MainActor
enum ExerciseMediaCatalog {
    private static let cache = NSCache<NSString, UIImage>()

    private static let mediaIDs: [String: String] = [
        "上斜俯卧撑": "Incline_Push-Up",
        "标准俯卧撑": "Pushups",
        "宽距俯卧撑": "Push-Up_Wide",
        "钻石俯卧撑": "Push-Ups_-_Close_Triceps_Position",
        "椅式臂屈伸": "Bench_Dips",
        "反向划船": "Inverted_Row",
        "俯卧超人": "Superman",
        "徒手深蹲": "Bodyweight_Squat",
        "前向箭步蹲": "Bodyweight_Walking_Lunge",
        "分腿蹲": "Split_Squats",
        "臀桥": "Butt_Lift_Bridge",
        "单腿臀桥": "Single_Leg_Glute_Bridge",
        "提踵": "Standing_Calf_Raises",
        "死虫": "Dead_Bug",
        "前臂平板支撑": "Plank",
        "侧平板支撑": "Side_Bridge",
        "卷腹": "Crunches",
        "反向卷腹": "Reverse_Crunch",
        "自行车卷腹": "Cross-Body_Crunch",
        "登山跑": "Mountain_Climbers",
        "尺蠖爬": "Inchworm",
        "猫牛式": "Cat_Stretch",
        "世界最伟大拉伸": "Worlds_Greatest_Stretch",
        "站姿腿后侧伸展": "Standing_Hamstring_and_Calf_Stretch",
        "站姿股四头肌拉伸": "Quad_Stretch",
        "髋屈肌拉伸": "Standing_Hip_Flexors",
        "小腿靠墙拉伸": "Calf_Stretch_Hands_Against_Wall",
        "婴儿式": "Childs_Pose",
        "快走": "Walking_Treadmill",
        "慢跑": "Running_Treadmill",
        "楼梯训练": "Stairmaster",
        "椭圆机": "Elliptical_Trainer",
        "动感单车": "Bicycling_Stationary",
        "低冲击有氧": "Walking_Treadmill",
        "爬坡走": "Trail_Running_Walking",
        "哑铃深蹲": "Dumbbell_Squat",
        "哑铃卧推": "Dumbbell_Bench_Press",
        "单臂哑铃划船": "One-Arm_Dumbbell_Row",
        "哑铃肩推": "Dumbbell_Shoulder_Press",
        "杠铃深蹲": "Barbell_Squat",
        "罗马尼亚硬拉": "Romanian_Deadlift",
        "弹力带侧步": "Monster_Walk",
        "壶铃摆动": "One-Arm_Kettlebell_Swings",
        "腿举机": "Leg_Press",
        "高位下拉": "Wide-Grip_Lat_Pulldown",
        "户外骑行": "Bicycling",
        "徒步爬坡": "Trail_Running_Walking",
    ]

    static func mediaID(for exercise: FitnessExercise) -> String? {
        mediaIDs[exercise.title]
    }

    static func image(
        mediaID: String,
        frame: Int
    ) -> UIImage? {
        let key = "\(mediaID)-\(frame)" as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }
        guard let url = Bundle.main.url(
            forResource: "\(frame)",
            withExtension: "jpg",
            subdirectory: "ExerciseMedia/\(mediaID)"
        ) else {
            return nil
        }
        guard let image = UIImage(contentsOfFile: url.path) else {
            return nil
        }
        cache.setObject(image, forKey: key)
        return image
    }
}

struct ExerciseMotionView: View {
    let exercise: FitnessExercise
    var compact = false

    @State private var frame = 0

    private let timer = Timer.publish(
        every: 0.85,
        on: .main,
        in: .common
    ).autoconnect()

    private var mediaID: String? {
        ExerciseMediaCatalog.mediaID(for: exercise)
    }

    private var images: [UIImage] {
        guard let mediaID else {
            return []
        }
        return [0, 1].compactMap {
            ExerciseMediaCatalog.image(mediaID: mediaID, frame: $0)
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            Group {
                if images.count == 2 {
                    Image(uiImage: images[frame])
                        .resizable()
                        .scaledToFit()
                        .id(frame)
                        .transition(.opacity)
                } else {
                    FallbackExerciseMotion(
                        exercise: exercise,
                        compact: compact,
                        phase: frame
                    )
                }
            }
            .frame(
                width: compact ? 72 : nil,
                height: compact ? 72 : 132
            )
            .background(Color.black.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .animation(.easeInOut(duration: 0.24), value: frame)

            if !compact, !images.isEmpty {
                Text("动作示意 · Public Domain")
                    .font(.system(size: 9))
                    .foregroundStyle(Color.trellisAsh)
            } else if !compact {
                Text("简化动作示意 · 本机绘制")
                    .font(.system(size: 9))
                    .foregroundStyle(Color.trellisAsh)
            }
        }
        .onReceive(timer) { _ in
            guard images.count == 2 || images.isEmpty else {
                return
            }
            frame = frame == 0 ? 1 : 0
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(exercise.title)动作示意")
    }
}

private struct FallbackExerciseMotion: View {
    let exercise: FitnessExercise
    let compact: Bool
    let phase: Int

    private var family: ExerciseFallbackFamily {
        ExerciseFallbackFamily(exercise: exercise)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    Color.trellisBrass.opacity(0.2),
                    style: StrokeStyle(
                        lineWidth: compact ? 1 : 1.5,
                        dash: [4, 4]
                    )
                )
                .padding(compact ? 8 : 16)

            Image(systemName: family.systemImage)
                .font(
                    .system(
                        size: compact ? 24 : 38,
                        weight: .light
                    )
                )
                .foregroundStyle(Color.trellisBrass)
                .offset(
                    x: phase == 0 ? -family.travel : family.travel,
                    y: phase == 0 ? family.travel : -family.travel
                )
                .animation(
                    .easeInOut(duration: 0.7),
                    value: phase
                )

            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: compact ? 10 : 13, weight: .medium))
                .foregroundStyle(Color.trellisJade)
                .offset(
                    x: compact ? 24 : 39,
                    y: compact ? -24 : -39
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private enum ExerciseFallbackFamily {
    case push
    case lower
    case core
    case fullBody
    case mobility
    case cardio
    case equipment
    case sport

    init(exercise: FitnessExercise) {
        let title = exercise.title
        if exercise.focus == .equipment {
            self = .equipment
        } else if exercise.focus == .sport {
            self = .sport
        } else if exercise.focus == .cardio {
            self = .cardio
        } else if exercise.focus == .mobility {
            self = .mobility
        } else if [
            "俯卧撑", "臂屈伸", "划船", "超人", "肩",
        ].contains(where: { title.contains($0) }) {
            self = .push
        } else if [
            "深蹲", "箭步", "分腿", "臀桥", "提踵",
        ].contains(where: { title.contains($0) }) {
            self = .lower
        } else if [
            "平板", "卷腹", "死虫", "鸟狗", "支撑", "爬",
        ].contains(where: { title.contains($0) }) {
            self = .core
        } else {
            self = .fullBody
        }
    }

    var systemImage: String {
        switch self {
        case .push:
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

    var travel: CGFloat {
        switch self {
        case .push, .equipment:
            return 3
        case .lower, .core, .fullBody:
            return 4
        case .mobility:
            return 2
        case .cardio, .sport:
            return 5
        }
    }
}
