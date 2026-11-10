import SwiftUI

struct RecordsView: View {
    @Environment(AppModel.self) private var model
    @State private var draft = ""
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    composer
                    history
                }
                .padding(22)
            }
            .background(Color.trellisInk.ignoresSafeArea())
            .navigationTitle("记录")
        }
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("这一刻留下什么？")
                .font(.system(.title3, design: .serif))
                .foregroundStyle(Color.trellisBone)

            TextField(
                "写一句就够，不必完整。",
                text: $draft,
                axis: .vertical
            )
            .lineLimit(3...7)
            .textFieldStyle(.plain)
            .padding(14)
            .background(Color.black.opacity(0.18))
            .overlay {
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.white.opacity(0.1))
            }
            .accessibilityLabel("记录内容")

            Button {
                Task {
                    isSaving = true
                    let didSave = await model.addRecord(text: draft)
                    isSaving = false
                    if didSave {
                        draft = ""
                    }
                }
            } label: {
                Text(isSaving ? "保存中" : "存为记录")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.trellisBrass)
            .disabled(
                draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || isSaving
            )
        }
        .trellisCard()
    }

    private var history: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("最近")
                    .font(.system(.headline, design: .serif))
                    .foregroundStyle(Color.trellisBone)
                Spacer()
                Text("\(model.data.records.count) 条")
                    .font(.caption)
                    .foregroundStyle(Color.trellisAsh)
            }

            if model.data.records.isEmpty {
                Text("第一条记录会出现在这里。")
                    .font(.callout)
                    .foregroundStyle(Color.trellisAsh)
                    .trellisCard()
            } else {
                ForEach(
                    model.data.records.sorted { $0.createdAt > $1.createdAt }
                ) { record in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(record.createdAt.formatted(
                            .dateTime.month().day().hour().minute()
                        ))
                        .font(.caption)
                        .tracking(0.8)
                        .foregroundStyle(Color.trellisBrass)

                        Text(record.text)
                            .font(.system(.body, design: .serif))
                            .foregroundStyle(Color.trellisBone)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .trellisCard()
                }
            }
        }
    }
}

