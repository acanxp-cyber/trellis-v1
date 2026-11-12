import SwiftUI

private enum AppSection: Hashable {
    case today
    case fitness
    case more
}

struct RootView: View {
    @Environment(AppModel.self) private var model
    @State private var selection: AppSection = .today
    @State private var isCapturingVoice = false

    var body: some View {
        selectedContent
            .safeAreaInset(edge: .bottom, spacing: 0) {
                TrellisBottomDock(
                    selection: $selection,
                    onVoice: {
                        isCapturingVoice = true
                    }
                )
            }
            .sheet(isPresented: $isCapturingVoice) {
                VoiceTaskCaptureView()
                    .presentationDetents([.large])
            }
            .task {
                await model.bootstrap()
                let reminderTasks = model.openTasks.filter {
                    $0.reminderAt != nil
                }
                if !reminderTasks.isEmpty {
                    _ = await LocalReminderScheduler().schedule(
                        reminderTasks
                    )
                }
            }
            .tint(.trellisBrass)
            .preferredColorScheme(.dark)
            .overlay {
                if model.isLoading {
                    ProgressView("正在读取本地数据")
                        .padding(20)
                        .background(.ultraThinMaterial)
                }
            }
            .overlay(alignment: .bottom) {
                if let message = model.errorMessage {
                    errorBanner(message)
                        .padding(.bottom, 92)
                }
            }
    }

    @ViewBuilder
    private var selectedContent: some View {
        switch selection {
        case .today:
            TodayView()
        case .fitness:
            FitnessView()
        case .more:
            MoreView()
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(message)
                .font(.callout)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 8) {
                Button("重试") {
                    Task {
                        await model.bootstrap()
                    }
                }

                Button("关闭") {
                    model.clearError()
                }
            }
            .font(.caption.weight(.semibold))
        }
        .foregroundStyle(Color.trellisBone)
        .padding(14)
        .background(Color.trellisDanger)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding()
    }
}

private struct TrellisBottomDock: View {
    @Binding var selection: AppSection
    let onVoice: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            HStack(spacing: 0) {
                tab(.today, title: "今天", systemImage: "circle")
                tab(
                    .fitness,
                    title: "健身",
                    systemImage: "figure.strengthtraining.traditional"
                )
            }
            .frame(maxWidth: .infinity)

            Button(action: onVoice) {
                ZStack {
                    Circle()
                        .fill(Color.trellisBrass)
                        .frame(width: 74, height: 74)
                        .shadow(
                            color: Color.trellisBrass.opacity(0.28),
                            radius: 16,
                            y: 5
                        )

                    Image(systemName: "mic.fill")
                        .font(.system(size: 42, weight: .semibold))
                        .foregroundStyle(Color.trellisInk)
                }
                .frame(maxWidth: .infinity)
                .offset(y: -10)
            }
            .buttonStyle(.plain)
            .frame(width: 84)
            .accessibilityLabel("语音安排")
            .accessibilityIdentifier("voice-task-capture")

            HStack(spacing: 0) {
                tab(.more, title: "更多", systemImage: "ellipsis")
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 7)
        .padding(.top, 8)
        .padding(.bottom, 5)
        .background(.ultraThinMaterial)
        .background(Color.trellisInk.opacity(0.94))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)
        }
    }

    private func tab(
        _ section: AppSection,
        title: String,
        systemImage: String
    ) -> some View {
        Button {
            selection = section
        } label: {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 21, weight: .medium))
                    .frame(height: 24)

                Text(title)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(
                selection == section
                    ? Color.trellisBrass
                    : Color.trellisAsh
            )
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("tab-\(sectionIdentifier(section))")
    }

    private func sectionIdentifier(_ section: AppSection) -> String {
        switch section {
        case .today:
            return "today"
        case .fitness:
            return "fitness"
        case .more:
            return "more"
        }
    }
}
