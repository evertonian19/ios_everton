import SwiftUI
import EvCore
import EvDesign

struct PlayerDetailView: View {
    @Environment(AppModel.self) private var model
    let player: Player

    private enum Tab: Hashable { case overview, stats, info }
    @State private var tab: Tab = .overview

    private var stats: PlayerStats? { player.stats }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                hero
                FMTabs([(Tab.overview, "개요"), (Tab.stats, "기록"), (Tab.info, "정보")], selection: $tab)
                switch tab {
                case .overview: overview
                case .stats: records
                case .info: info
                }
            }
            .padding(10)
        }
        .background(Theme.background)
        .evBrandBars()
        .navigationTitle(player.shortName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private struct HeroChip: Identifiable {
        let label: String
        let value: Int
        let icon: String?
        let highlight: Bool
        var id: String { label }
    }

    /// 히어로 아래 기록 칩. 데이터에 있는 실제 기록만 쓴다(평점 같은 가짜 점수는 만들지 않는다).
    private var heroChips: [HeroChip] {
        guard let s = stats else { return [] }
        if player.position == .goalkeeper {
            return [HeroChip(label: "출전", value: s.appearances, icon: nil, highlight: false),
                    HeroChip(label: "선방", value: s.saves, icon: "hand.raised.fill", highlight: s.saves > 0),
                    HeroChip(label: "실점", value: s.conceded, icon: nil, highlight: false)]
        }
        return [HeroChip(label: "출전", value: s.appearances, icon: nil, highlight: false),
                HeroChip(label: "골", value: s.goals, icon: "soccerball", highlight: s.goals > 0),
                HeroChip(label: "도움", value: s.assists, icon: "arrow.turn.up.right", highlight: s.assists > 0)]
    }

    private var hero: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                PlayerPhoto(url: player.photoURL, name: player.name, size: 84, ringed: true)
                VStack(alignment: .leading, spacing: 5) {
                    Text("\(player.number.map { "#\($0) " } ?? "")\(player.name)")
                        .font(.headline.weight(.bold)).foregroundStyle(.white)
                    HStack(spacing: 6) {
                        PositionTag(player.position)
                        Text("\(player.position.title) · \(player.age.map { "\($0)세" } ?? "-")")
                            .font(.footnote).foregroundStyle(Theme.onBrand2)
                    }
                    HStack(spacing: 6) {
                        FlagImage(player.flagURL)
                        Text(player.nationality ?? "-").font(.footnote).foregroundStyle(Theme.onBrand2)
                    }
                }
                Spacer(minLength: 0)
            }
            if !heroChips.isEmpty {
                HStack(spacing: 8) {
                    ForEach(heroChips) { chip in
                        StatTile(value: chip.value, label: chip.label, icon: chip.icon, highlight: chip.highlight)
                    }
                }
            }
        }
        .padding(12)
        .background(alignment: .trailing) {
            if let number = player.number {
                Text("\(number)")
                    .font(.system(size: 120, weight: .black, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.07))
                    .offset(x: 14, y: -10)
                    .accessibilityHidden(true)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .evHero()
    }

    // MARK: 개요

    @ViewBuilder
    private var overview: some View {
        let metrics = PlayerMetrics.radar(for: player, teamGames: model.teamGames)
        let strengths = PlayerMetrics.strengths(for: player, teamGames: model.teamGames)
        if !strengths.isEmpty {
            FMPanel("강점") {
                HStack(spacing: 8) {
                    ForEach(strengths, id: \.self) { item in
                        Text(item).font(.footnote.weight(.bold)).foregroundStyle(Color.black.opacity(0.85))
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(Theme.gold, in: Capsule())
                            .evShimmer()
                    }
                    Spacer()
                }
            }
            .evRise()
        }
        if metrics.isEmpty {
            FMPanel("시즌 지표") {
                Text("출전 기록이 없어 지표를 만들 수 없어요.").font(.footnote).foregroundStyle(Theme.textSecondary)
            }
        } else {
            FMPanel("시즌 지표 (출전당)") {
                VStack(spacing: 10) {
                    RadarChart(labels: metrics.map(\.label), values: metrics.map(\.value)).frame(maxWidth: 260)
                    VStack(spacing: 8) {
                        ForEach(metrics, id: \.label) { metric in
                            AttributeBar(label: metric.label, value: metric.value, detail: "\(Int((metric.value * 100).rounded()))")
                        }
                    }
                    Text("골·도움 등 실제 기록을 출전 1회당으로 환산한 값입니다. 평점이 아닙니다.")
                        .font(.caption2).foregroundStyle(Theme.textSecondary)
                }
            }
            .evRise(delay: 0.1)
        }
    }

    // MARK: 기록

    private var rows: [(String, Int)] {
        guard let s = stats else { return [] }
        if player.position == .goalkeeper {
            return [("출전", s.appearances), ("교체 투입", s.subIns), ("선방", s.saves), ("실점", s.conceded),
                    ("피유효슈팅", s.shotsFaced), ("경고", s.yellow), ("퇴장", s.red), ("파울", s.foulsCommitted)]
        }
        return [("출전", s.appearances), ("교체 투입", s.subIns), ("골", s.goals), ("도움", s.assists), ("슈팅", s.shots),
                ("유효슈팅", s.shotsOnTarget), ("파울 획득", s.foulsSuffered), ("파울", s.foulsCommitted),
                ("오프사이드", s.offsides), ("경고", s.yellow), ("퇴장", s.red), ("자책골", s.ownGoals)]
    }

    @ViewBuilder
    private var records: some View {
        if rows.isEmpty {
            FMPanel("시즌 기록") { Text("ESPN 에 이 선수의 시즌 기록이 없어요(출전 전이거나 등록 직후).").font(.footnote).foregroundStyle(Theme.textSecondary) }
        } else {
            FMPanel("시즌 기록") {
                VStack(spacing: 0) {
                    ForEach(Array(rows.enumerated()), id: \.element.0) { index, row in
                        let star = Self.starRows.contains(row.0) && row.1 > 0
                        VStack(spacing: 4) {
                            HStack(spacing: 6) {
                                if star, let icon = Self.rowIcon[row.0] {
                                    Image(systemName: icon).font(.caption.weight(.bold)).foregroundStyle(Theme.gold)
                                }
                                Text(row.0).font(.footnote).foregroundStyle(star ? Theme.textPrimary : Theme.textSecondary)
                                Spacer()
                                CountUpText(row.1).font(.subheadline.weight(.heavy))
                                    .foregroundStyle(star ? Theme.gold : Theme.textPrimary)
                                Text(perGame(row.1)).font(.caption2).foregroundStyle(Theme.textSecondary).frame(width: 64, alignment: .trailing)
                            }
                            RecordBar(fraction: barMax > 0 ? Double(row.1) / Double(barMax) : 0, tint: star ? Theme.gold : Theme.blue)
                        }
                        .padding(.vertical, 6)
                        .evRise(delay: Double(index) * 0.04)
                        Divider().overlay(Theme.line.opacity(0.5))
                    }
                    Text("출처: ESPN 시즌 누적 기록(비공식 API). 경기 이벤트와의 대조 검증은 에버턴 선수만 수행합니다.")
                        .font(.caption2).foregroundStyle(Theme.textSecondary).padding(.top, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private static let starRows: Set<String> = ["골", "도움", "선방"]
    private static let rowIcon = ["골": "soccerball", "도움": "arrow.turn.up.right", "선방": "hand.raised.fill"]

    /// 막대 길이의 기준: 출전·교체 투입을 뺀 기록 중 가장 큰 값.
    private var barMax: Int {
        rows.filter { $0.0 != "출전" && $0.0 != "교체 투입" }.map(\.1).max() ?? 0
    }

    private func perGame(_ value: Int) -> String {
        guard let apps = stats?.appearances, apps > 0 else { return "" }
        return String(format: "%.2f/경기", Double(value) / Double(apps))
    }

    // MARK: 정보

    private var info: some View {
        FMPanel("선수 정보") {
            VStack(spacing: 0) {
                infoRow("국적", player.nationality, disputed: player.bioDisputed["nationality"])
                infoRow("포지션", player.position.title)
                infoRow("나이", player.age.map { "\($0)세" })
                infoRow("생년월일", player.birthDate.map { Fmt.birthday($0) }, disputed: player.bioDisputed["birthDate"])
                infoRow("키", player.heightCM.map { "\($0) cm" }, disputed: player.bioDisputed["heightCM"])
                infoRow("몸무게", player.weightKG.map { "\($0) kg" })
                infoRow("출생지", player.birthPlace)
                infoRow("등번호", player.number.map(String.init))
                photoCreditLine
                Text("신상 출처: \(bioSourceText)")
                    .font(.caption2).foregroundStyle(Theme.textSecondary).padding(.top, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if !player.bioDisputed.isEmpty {
                    Text("ESPN 원본과 값이 달라 보정했습니다 (동명이인 프로필이 섞인 것으로 보임).")
                        .font(.caption2).foregroundStyle(Theme.gold).frame(maxWidth: .infinity, alignment: .leading)
                }
                Text("평점·패스 지표는 데이터 출처(\(model.services.sourceName))가 제공하지 않아 표시하지 않습니다.")
                    .font(.caption2).foregroundStyle(Theme.textSecondary).padding(.top, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder
    private var photoCreditLine: some View {
        if let credit = player.photoCredit, credit.author == "Premier League" {
            HStack(spacing: 4) {
                if let page = credit.pageURL { Link("Premier League 공식 사이트", destination: page) } else { Text("Premier League 공식 사이트") }
                Text("· 개인 기기 열람용 이미지입니다.")
            }
            .font(.caption2).foregroundStyle(Theme.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading).padding(.top, 8)
        } else if let credit = player.photoCredit {
            HStack(spacing: 4) {
                Text("사진: \(credit.author) · \(credit.license) ·")
                if let page = credit.pageURL { Link("Wikimedia Commons", destination: page) } else { Text("Wikimedia Commons") }
            }
            .font(.caption2).foregroundStyle(Theme.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading).padding(.top, 8)
        } else {
            Text("사진을 구하지 못해 이니셜로 표시합니다.")
                .font(.caption2).foregroundStyle(Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading).padding(.top, 8)
        }
    }

    private var bioSourceText: String {
        switch player.bioSource {
        case "override": return "수동 보정"
        case "wikidata": return "Wikidata 보정"
        default: return player.bioVerified ? "ESPN · Wikidata 교차 확인" : "ESPN 원본 (미검증)"
        }
    }

    private func infoRow(_ label: String, _ value: String?, disputed: String? = nil) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(label).font(.footnote).foregroundStyle(Theme.textSecondary)
                Spacer()
                Text(value ?? "-").font(.footnote.weight(.semibold)).foregroundStyle(Theme.textPrimary)
                if let disputed {
                    Image(systemName: "exclamationmark.circle.fill").font(.caption).foregroundStyle(Theme.gold)
                        .accessibilityLabel("ESPN 원본: \(disputed)")
                }
            }
            .padding(.vertical, 7)
            Divider().overlay(Theme.line.opacity(0.5))
        }
    }
}

/// 시즌 기록 행 밑의 가는 막대. 나타날 때 왼쪽에서 채워진다.
private struct RecordBar: View {
    let fraction: Double
    let tint: Color
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var grown = false

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.surfaceHigh)
                Capsule()
                    .fill(LinearGradient(colors: [tint.opacity(0.55), tint], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(proxy.size.width * (grown ? min(max(fraction, 0), 1) : 0), fraction > 0 ? 3 : 0))
            }
        }
        .frame(height: 3)
        .onAppear {
            if reduceMotion { grown = true } else { withAnimation(.easeOut(duration: 0.7).delay(0.15)) { grown = true } }
        }
    }
}
