import SwiftUI
import EvCore
import EvDesign

/// 시즌·일정·스쿼드가 기대한 값(2026-27)과 맞는지 보여 주는 점검 화면.
struct DataCheckView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var report: DataReport?
    @State private var running = false

    var body: some View {
        NavigationStack {
            List {
                if let report {
                    Section {
                        ForEach(report.checks) { check in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: icon(check.level)).foregroundStyle(color(check.level)).font(.title3)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(check.title).font(.subheadline.weight(.semibold))
                                    Text(check.detail).font(.footnote).foregroundStyle(Theme.textSecondary)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    } footer: {
                        Text("확인 시각 \(Fmt.day(report.checkedAt)) \(Fmt.time(report.checkedAt)) · 출처 \(report.source.isEmpty ? model.services.sourceName : report.source)")
                    }
                } else {
                    HStack { ProgressView(); Text("점검 중…").padding(.leading, 8) }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("데이터 점검")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("닫기") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Task { await run() } } label: { Image(systemName: "arrow.clockwise") }.disabled(running)
                }
            }
            .task { await run() }
        }
    }

    private func run() async {
        running = true
        report = await model.services.football.diagnostics()
        running = false
    }

    private func icon(_ level: DataReport.Check.Level) -> String {
        switch level {
        case .ok: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .problem: return "xmark.octagon.fill"
        }
    }

    private func color(_ level: DataReport.Check.Level) -> Color {
        switch level {
        case .ok: return Theme.win
        case .warning: return Theme.gold
        case .problem: return Theme.loss
        }
    }
}
