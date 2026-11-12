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
                    Image(systemName: exercise.focus.systemImage)
                        .font(.system(size: compact ? 24 : 38, weight: .light))
                        .foregroundStyle(Color.trellisBrass)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(
                width: compact ? 72 : nil,
                height: compact ? 72 : 132
            )
            .background(Color.black.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .animation(.easeInOut(duration: 0.24), value: frame)

            if !compact, images.count == 2 {
                Text("动作示意 · Public Domain")
                    .font(.system(size: 9))
                    .foregroundStyle(Color.trellisAsh)
            }
        }
        .onReceive(timer) { _ in
            guard images.count == 2 else {
                return
            }
            frame = frame == 0 ? 1 : 0
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(exercise.title)动作示意")
    }
}
