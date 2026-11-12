import SwiftUI
import UniformTypeIdentifiers

struct MoreView: View {
    @Environment(AppModel.self) private var model
    @State private var exportDocument: DataExportDocument?
    @State private var isExporting = false
    @State private var exportFailed = false

    var body: some View {
        NavigationStack {
            List {
                Section("时间线") {
                    NavigationLink {
                        ReviewView()
                    } label: {
                        Label("周回顾", systemImage: "checklist")
                    }

                    NavigationLink {
                        YearView()
                    } label: {
                        Label("年轮", systemImage: "circle.dashed")
                    }
                }

                Section("数据主权") {
                    LabeledContent("存储位置", value: "仅本机")
                    LabeledContent("健康数据", value: "不持久化、不同步")
                    LabeledContent("iCloud 备份", value: "已排除")

                    Button("导出全部数据") {
                        Task {
                            guard let data = await model.exportData() else {
                                exportFailed = true
                                return
                            }
                            exportDocument = DataExportDocument(data: data)
                            isExporting = true
                        }
                    }
                }

                Section("架构红线") {
                    Text("HealthKit 中的个人健康信息只用于本机即时展示，不写入业务数据库，不上传 CloudKit 或 iCloud。")
                    Text("训练记录、身体信号及其派生洞察同样按个人健康信息处理。")
                    Text("后续如增加跨设备同步，只能同步经过逐字段分类的非健康数据。")
                }
                .font(.callout)

                Section("当前版本") {
                    LabeledContent("原生界面", value: "SwiftUI")
                    LabeledContent("本地数据", value: "版本化 JSON")
                    LabeledContent("MVP", value: "任务、语音、健身、回顾")
                }

                Section("第三方素材") {
                    Link(
                        "动作示意：Free Exercise DB（Public Domain）",
                        destination: URL(
                            string: "https://github.com/yuhonas/free-exercise-db"
                        )!
                    )
                    Text("仅打包许可证允许商用的动作图片；Gym Visual 所有的动图未进入 App。")
                        .font(.caption)
                        .foregroundStyle(Color.trellisAsh)
                }
            }
            .navigationTitle("更多")
            .scrollContentBackground(.hidden)
            .background(Color.trellisInk.ignoresSafeArea())
            .fileExporter(
                isPresented: $isExporting,
                document: exportDocument,
                contentType: .json,
                defaultFilename: "trellis-backup"
            ) { _ in
                exportDocument = nil
            }
            .alert("导出失败", isPresented: $exportFailed) {
                Button("知道了", role: .cancel) {}
            } message: {
                Text("没有生成可分享的数据文件。请稍后重试。")
            }
        }
    }
}

