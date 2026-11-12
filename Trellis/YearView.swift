import SwiftUI

struct YearView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                YearRingsView(
                    progress: min(
                        Double(recordDays) / 365,
                        1
                    ),
                    days: recordDays
                )
                .frame(height: 250)
                .frame(maxWidth: .infinity)

                Text("今年留下了 \(recordDays) 天记录。")
                    .font(.system(.title3, design: .serif))
                    .foregroundStyle(Color.trellisBone)

                summaryGrid

                if !model.data.records.isEmpty {
                    Text("最近的回声")
                        .font(.headline)
                        .foregroundStyle(Color.trellisBone)

                    ForEach(model.data.records.prefix(3)) { record in
                        HStack(alignment: .top, spacing: 14) {
                            Rectangle()
                                .fill(Color.trellisBrass.opacity(0.5))
                                .frame(width: 1)

                            VStack(alignment: .leading, spacing: 6) {
                                Text(record.createdAt.formatted(
                                    .dateTime.month().day()
                                ))
                                .font(.caption)
                                .tracking(1)
                                .foregroundStyle(Color.trellisBrass)

                                Text(record.text)
                                    .font(.system(.callout, design: .serif))
                                    .foregroundStyle(Color.trellisBone)
                            }
                        }
                    }
                }
            }
            .padding(22)
        }
        .background(Color.trellisInk.ignoresSafeArea())
        .navigationTitle("年轮")
    }

    private var recordDays: Int {
        Set(
            model.data.records.map {
                Calendar.trellis.startOfDay(for: $0.createdAt)
            }
        ).count
    }

    private var summaryGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 1),
                GridItem(.flexible(), spacing: 1),
            ],
            spacing: 1
        ) {
            summaryCell("\(model.data.tasks.count)", "任务")
            summaryCell("\(model.completedTaskCount)", "完成")
            summaryCell("\(model.data.records.count)", "记录")
            summaryCell("\(model.data.reviews.count)", "回顾")
        }
        .background(Color.white.opacity(0.08))
    }

    private func summaryCell(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(value)
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(Color.trellisBone)
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.trellisAsh)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.trellisInk)
    }
}

private struct YearRingsView: View {
    let progress: Double
    let days: Int

    var body: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .trim(from: 0, to: max(progress - Double(index) * 0.16, 0))
                    .stroke(
                        index.isMultiple(of: 2)
                            ? Color.trellisBrass
                            : Color.trellisJade,
                        style: StrokeStyle(
                            lineWidth: 3,
                            lineCap: .square,
                            dash: [8, 5]
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .padding(CGFloat(index) * 24)
                    .opacity(0.9 - Double(index) * 0.14)
            }

            VStack(spacing: 5) {
                Text("\(days)")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(Color.trellisBone)
                Text("记录日")
                    .font(.caption)
                    .tracking(1.2)
                    .foregroundStyle(Color.trellisAsh)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("年轮记录进度")
        .accessibilityValue("\(Int(progress * 100))%")
    }
}

