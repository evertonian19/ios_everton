import SwiftUI
import EvCore
import EvDesign

/// 로딩·실패·완료 상태에 맞춰 화면을 바꿔 주는 래퍼.
struct LoadStateView<Value, Content: View>: View {
    let state: LoadState<Value>
    let retry: () async -> Void
    @ViewBuilder let content: (Value) -> Content

    var body: some View {
        switch state {
        case .idle, .loading:
            ProgressView().tint(Theme.blue).frame(maxWidth: .infinity, minHeight: 200)
        case .failed(let message):
            VStack(spacing: 10) {
                Image(systemName: "wifi.exclamationmark").font(.title).foregroundStyle(Theme.loss)
                Text(message).font(.footnote).multilineTextAlignment(.center).foregroundStyle(Theme.textSecondary)
                Button("다시 시도") { Task { await retry() } }
                    .buttonStyle(.borderedProminent).tint(Theme.blue)
            }
            .frame(maxWidth: .infinity, minHeight: 200)
        case .loaded(let value):
            content(value)
        }
    }
}

struct SampleBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "testtube.2")
            Text("샘플 데이터입니다. API 키를 설정하면 실제 데이터가 표시됩니다.")
                .font(.caption)
        }
        .foregroundStyle(Theme.gold)
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

/// 한 줄짜리 경기 행 (일정 목록, 홈의 다음 경기 목록에서 공통 사용).
struct MatchRow: View {
    let match: Match

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 2) {
                Text(Fmt.day(match.kickoff)).font(.caption2).foregroundStyle(Theme.textSecondary)
                Text(Fmt.time(match.kickoff)).font(.caption.weight(.semibold)).foregroundStyle(Theme.textPrimary)
            }
            .frame(width: 74, alignment: .leading)

            ClubLogo(url: match.opponent().logoURL, size: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(match.opponent().name).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.textPrimary)
                Text(match.isHome() ? "홈" : "원정").font(.caption2).foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            if match.phase == .finished || match.phase == .live {
                Text(match.scoreText)
                    .font(.system(.subheadline, design: .rounded).weight(.heavy))
                    .foregroundStyle(match.phase == .live ? Theme.gold : Theme.textPrimary)
            }
            FormBadge(match.result())
        }
        .padding(.vertical, 6)
    }
}
