import SwiftUI

struct FitnessRoutinePlanView: View {
    let recommendation: FitnessRoutineRecommendation
    var showsSafetyNote = true

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.title)
                        .font(.system(.title3, design: .serif))
                        .foregroundStyle(Color.trellisBone)

                    Text("\(recommendation.summary) · \(recommendation.durationMinutes) 分钟")
                        .font(.caption)
                        .foregroundStyle(Color.trellisAsh)
                }

                Spacer()

                Text("已分组")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.trellisInk)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Color.trellisJade)
                    .clipShape(Capsule())
            }

            ForEach(recommendation.blocks) { block in
                VStack(alignment: .leading, spacing: 10) {
                    Text(block.title)
                        .font(.headline)
                        .foregroundStyle(Color.trellisBrass)

                    Text(block.detail)
                        .font(.caption)
                        .foregroundStyle(Color.trellisAsh)

                    ForEach(block.items) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(item.exercise.title)
                                    .font(.callout.weight(.semibold))
                                    .foregroundStyle(Color.trellisBone)

                                Spacer()

                                Text(item.exercise.prescription)
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(Color.trellisBrass)
                            }

                            Text(item.exercise.method)
                                .font(.caption)
                                .foregroundStyle(Color.trellisAsh)
                                .fixedSize(horizontal: false, vertical: true)

                            Text("调整：\(item.exercise.adjustment)")
                                .font(.caption2)
                                .foregroundStyle(Color.trellisAsh.opacity(0.9))
                        }
                        .padding(.vertical, 7)

                        if item.id != block.items.last?.id {
                            Divider()
                                .overlay(Color.white.opacity(0.06))
                        }
                    }
                }
                .padding(14)
                .background(Color.black.opacity(0.16))
            }

            if showsSafetyNote {
                Text(recommendation.safetyNote)
                    .font(.caption2)
                    .foregroundStyle(Color.trellisAsh)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct FitnessExerciseCard: View {
    let exercise: FitnessExercise

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .firstTextBaseline) {
                Text(exercise.title)
                    .font(.system(.headline, design: .serif))
                    .foregroundStyle(Color.trellisBone)

                Spacer()

                Text(exercise.level.rawValue)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.trellisBrass)
            }

            Text("\(exercise.targets) · \(exercise.prescription)")
                .font(.caption)
                .foregroundStyle(Color.trellisJade)

            Text(exercise.method)
                .font(.callout)
                .foregroundStyle(Color.trellisBone)
                .fixedSize(horizontal: false, vertical: true)

            Text("更容易：\(exercise.adjustment)")
                .font(.caption)
                .foregroundStyle(Color.trellisAsh)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .trellisCard()
    }
}
