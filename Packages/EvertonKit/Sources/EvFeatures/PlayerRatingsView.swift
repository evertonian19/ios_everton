import SwiftUI
import EvCore
import EvDesign

/// FM 식 능력치 색: 1~5 빨강 · 6~10 노랑 · 11~15 연두 · 16~20 청록.
func fmColor(_ value: Int) -> Color {
    switch value {
    case ..<6: return Color(hex: 0xD5484B)
    case 6..<11: return Color(hex: 0xC99A0A)
    case 11..<16: return Color(hex: 0x2E9A52)
    default: return Color(hex: 0x17A99A)
    }
}

/// 선수 개요 탭의 평가 영역: 포지션 맵 · 능력치 3열 · 플레이 스타일. EA SPORTS FC 공식 평가를 쓴다.
struct PlayerRatingsSection: View {
    @Environment(AppModel.self) private var model
    let player: Player
    @State private var showRaw = false

    private var state: LoadState<PlayerRatings?> { model.ratings[player.id] ?? .idle }

    var body: some View {
        Group {
            switch state {
            case .loaded(let ratings?):
                content(ratings)
            case .loaded(nil):
                FMPanel("능력치") {
                    Text("EA SPORTS FC 평가에서 이 선수를 확실히 찾지 못해 능력치를 표시하지 않습니다(이름·생년월일이 모두 일치할 때만 연결).")
                        .font(.footnote).foregroundStyle(Theme.textSecondary)
                }
            case .failed:
                FMPanel("능력치") { Text("EA 평가를 불러오지 못했어요.").font(.footnote).foregroundStyle(Theme.textSecondary) }
            default:
                FMPanel("능력치") { ProgressView().frame(maxWidth: .infinity) }
            }
        }
        .task { await model.loadRatings(for: player) }
    }

    @ViewBuilder
    private func content(_ r: PlayerRatings) -> some View {
        FMPanel("평가 · 포지션") {
            HStack(alignment: .top, spacing: 14) {
                PositionMap(positions: r.positions).frame(width: 96, height: 134)
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(r.overall)").font(.system(size: 34, weight: .heavy, design: .rounded))
                            .foregroundStyle(fmColor(PlayerRatings.to20(r.overall)))
                        Text("EA 종합").font(.caption).foregroundStyle(Theme.textSecondary)
                    }
                    infoRow("주 포지션", r.positions.first(where: \.main)?.label ?? "-")
                    let others = r.positions.filter { !$0.main }.map(\.label)
                    if !others.isEmpty { infoRow("다른 포지션", others.joined(separator: ", ")) }
                    if let foot = r.foot { infoRow("주발", foot == "right" ? "오른발" : "왼발") }
                    if let weak = r.weakFoot { starRow("약발", weak) }
                    if let skill = r.skillMoves { starRow("개인기", skill) }
                }
                Spacer(minLength: 0)
            }
        }
        FMPanel("능력치") {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 10) {
                    ForEach(r.groups) { group in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(group.title).font(.caption2.weight(.bold)).foregroundStyle(Theme.textSecondary)
                            Divider()
                            ForEach(group.attrs) { attr in
                                AttrRow(attr: attr, top: r.top.contains(attr.key), showRaw: showRaw)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    }
                }
                Button(showRaw ? "1~20 환산값 보기" : "EA 원본(1~99) 보기") { showRaw.toggle() }
                    .font(.caption.weight(.bold)).foregroundStyle(Theme.blue)
                Text("EA SPORTS FC 공식 평가(\(r.fetchedAt.formatted(.dateTime.year().month().day())) 받음)의 원본 1~99 값을 5로 나눠 1~20으로 환산했습니다. 테두리는 이 선수의 상위 3개 능력치. EA 등록 소속: \(r.eaTeam ?? "-"). EA 평가는 게임 출시 시점·업데이트 기준이라 이번 시즌 이적·성장은 반영되지 않을 수 있습니다.")
                    .font(.caption2).foregroundStyle(Theme.textSecondary)
            }
        }
        if !r.abilities.isEmpty {
            FMPanel("플레이 스타일") {
                VStack(spacing: 7) {
                    ForEach(r.abilities) { ability in
                        VStack(alignment: .leading, spacing: 1) {
                            Text(ability.label).font(.footnote.weight(.bold)).foregroundStyle(Theme.textPrimary)
                            Text(ability.description).font(.caption2).foregroundStyle(Theme.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(Theme.surfaceHigh, in: RoundedRectangle(cornerRadius: 8))
                        .overlay(alignment: .leading) { Rectangle().fill(Theme.blue).frame(width: 3) }
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(title).font(.caption).foregroundStyle(Theme.textSecondary)
            Text(value).font(.caption.weight(.bold)).foregroundStyle(Theme.textPrimary)
        }
    }

    private func starRow(_ title: String, _ count: Int) -> some View {
        HStack(spacing: 10) {
            Text(title).font(.caption).foregroundStyle(Theme.textSecondary)
            HStack(spacing: 1) {
                ForEach(0..<5, id: \.self) { index in
                    Image(systemName: "star.fill").font(.caption2).foregroundStyle(index < count ? Theme.gold : Theme.line)
                }
            }
            .accessibilityLabel("\(count) / 5")
        }
    }
}

private struct AttrRow: View {
    let attr: PlayerRatings.Attr
    let top: Bool
    let showRaw: Bool

    var body: some View {
        let value = showRaw ? attr.raw : attr.fm
        let color = fmColor(attr.fm)
        HStack(spacing: 4) {
            Text(attr.label).font(.system(size: 11.5, weight: top ? .bold : .regular)).foregroundStyle(Theme.textPrimary).lineLimit(1)
            Spacer(minLength: 2)
            Text("\(value)")
                .font(.system(size: 11.5, weight: .heavy)).monospacedDigit()
                .foregroundStyle(attr.fm >= 16 ? Color.white : color)
                .padding(.horizontal, 4)
                .background(attr.fm >= 16 ? color : Color.clear, in: RoundedRectangle(cornerRadius: 4))
        }
        .padding(.horizontal, 3).padding(.vertical, 2)
        .background(top ? Theme.blue.opacity(0.09) : Color.clear, in: RoundedRectangle(cornerRadius: 5))
        .overlay(RoundedRectangle(cornerRadius: 5).stroke(top ? Theme.blue : Color.clear, lineWidth: 1.5))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(attr.label) \(attr.fm), EA 원본 \(attr.raw)")
    }
}

/// 작은 피치 위에 주 포지션(진한 점)과 다른 포지션(옅은 점)을 찍은 그림.
struct PositionMap: View {
    let positions: [PlayerRatings.Position]

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width, h = proxy.size.height
            ZStack {
                RoundedRectangle(cornerRadius: 3).fill(Color(hex: 0x2E8B57).opacity(0.22))
                Path { path in
                    path.addRoundedRect(in: CGRect(x: 0.5, y: 0.5, width: w - 1, height: h - 1), cornerSize: CGSize(width: 3, height: 3))
                    path.move(to: CGPoint(x: 0, y: h / 2)); path.addLine(to: CGPoint(x: w, y: h / 2))
                    path.addEllipse(in: CGRect(x: w / 2 - 11, y: h / 2 - 11, width: 22, height: 22))
                    path.addRect(CGRect(x: w * 0.3, y: 0, width: w * 0.4, height: h * 0.11))
                    path.addRect(CGRect(x: w * 0.3, y: h * 0.89, width: w * 0.4, height: h * 0.11))
                }
                .stroke(Theme.textSecondary.opacity(0.35), lineWidth: 1)
                ForEach(positions) { spot in
                    ZStack {
                        Circle().fill(spot.main ? Theme.blue : Theme.blue.opacity(0.4))
                            .overlay(Circle().stroke(spot.main ? Color.white : Theme.blue, lineWidth: 1.2))
                            .frame(width: spot.main ? 13 : 10, height: spot.main ? 13 : 10)
                        if spot.main {
                            Text(spot.code).font(.system(size: 7, weight: .heavy)).foregroundStyle(Theme.textPrimary).offset(y: -12)
                        }
                    }
                    .position(x: w * spot.x, y: h * spot.y)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("포지션 " + positions.map(\.label).joined(separator: ", "))
    }
}
