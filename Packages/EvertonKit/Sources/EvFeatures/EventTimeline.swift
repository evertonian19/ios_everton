import SwiftUI
import EvCore
import EvDesign

/// 골·카드를 시간순으로 보여 준다. 홈 팀 이벤트는 왼쪽, 원정 팀은 오른쪽.
struct EventTimeline: View {
    let events: [MatchEvent]
    let match: Match

    var body: some View {
        VStack(spacing: 10) {
            ForEach(events) { event in
                let home = event.clubID == match.home.id
                HStack(spacing: 8) {
                    side(event, show: home, alignment: .trailing)
                    VStack(spacing: 1) {
                        Text(event.symbol).font(.body)
                        Text(event.minuteText).font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .frame(width: 46)
                    side(event, show: !home, alignment: .leading)
                }
            }
        }
    }

    @ViewBuilder
    private func side(_ event: MatchEvent, show: Bool, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 1) {
            if show {
                Text(event.player).font(.footnote.weight(.semibold)).foregroundStyle(Theme.textPrimary)
                if let assist = event.assist, !assist.isEmpty {
                    Text(assist).font(.caption2).foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : .trailing)
    }
}
