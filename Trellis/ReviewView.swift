import SwiftUI

struct ReviewView: View {
    @Environment(AppModel.self) private var model
    @State private var wins = ""
    @State private var shift = ""
    @State private var focus = ["", "", ""]
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Group {
                if let review = model.currentWeekReview {
                    completedReview(review)
                } else {
                    reviewForm
                }
            }
            .background(Color.trellisInk.ignoresSafeArea())
            .navigationTitle("周回顾")
        }
    }

    private var reviewForm: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("先看已经发生的，再决定下一步。")
                    .font(.system(.title2, design: .serif))
                    .foregroundStyle(Color.trellisBone)

                reviewField(
                    title: "这一周，什么真正落地了？",
                    text: $wins
                )

                reviewField(
                    title: "你看见自己发生了什么变化？",
                    text: $shift,
                    required: false
                )

                VStack(alignment: .leading, spacing: 12) {
                    Text("下周只留三件重点")
                        .font(.headline)
                        .foregroundStyle(Color.trellisBone)

                    ForEach(focus.indices, id: \.self) { index in
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            Text(String(format: "%02d", index + 1))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(Color.trellisBrass)

                            TextField(
                                "重点 \(index + 1)",
                                text: $focus[index],
                                axis: .vertical
                            )
                            .lineLimit(1...3)
                            .accessibilityLabel("下周重点 \(index + 1)")
                        }
                        .padding(.vertical, 10)
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .fill(Color.white.opacity(0.08))
                                .frame(height: 1)
                        }
                    }
                }

                Button {
                    Task {
                        isSaving = true
                        await model.completeReview(
                            wins: wins,
                            shift: shift,
                            focus: focus
                        )
                        isSaving = false
                    }
                } label: {
                    Text(isSaving ? "保存中" : "完成本周回顾")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.trellisBrass)
                .disabled(
                    !WeeklyReview.isValid(wins: wins, focus: focus)
                        || isSaving
                )
            }
            .padding(22)
        }
    }

    private func reviewField(
        title: String,
        text: Binding<String>,
        required: Bool = true
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.trellisBone)

            TextField(
                required ? "必填" : "可选",
                text: text,
                axis: .vertical
            )
            .lineLimit(3...7)
            .padding(14)
            .background(Color.black.opacity(0.18))
            .overlay {
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.white.opacity(0.1))
            }
            .accessibilityLabel(title)
        }
    }

    private func completedReview(_ review: WeeklyReview) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("这一周已经入册。")
                    .font(.system(.largeTitle, design: .serif))
                    .foregroundStyle(Color.trellisBone)

                reviewBlock("落地的", body: review.wins)

                if !review.shift.isEmpty {
                    reviewBlock("变化", body: review.shift)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("下周三个重点")
                        .font(.headline)
                        .foregroundStyle(Color.trellisBrass)

                    ForEach(review.focus.indices, id: \.self) { index in
                        Text("\(index + 1). \(review.focus[index])")
                            .font(.system(.body, design: .serif))
                            .foregroundStyle(Color.trellisBone)
                    }
                }
            }
            .padding(22)
        }
    }

    private func reviewBlock(_ title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .tracking(1.2)
                .foregroundStyle(Color.trellisBrass)
            Text(body)
                .font(.system(.body, design: .serif))
                .foregroundStyle(Color.trellisBone)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .trellisCard()
    }
}

