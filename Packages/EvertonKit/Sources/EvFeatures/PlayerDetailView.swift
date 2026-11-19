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
        .navigationTitle(player.shortName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var hero: some View {
        HStack(spacing: 14) {
            PlayerPhoto(url: player.photoURL, name: player.name, size: 74)
            VStack(alignment: .leading, spacing: 5) {
                Text("\(player.number.map { "#\($0) " } ?? "")\(player.name)")
                    .font(.headline.weight(.bold)).foregroundStyle(.white)
                HStack(spacing: 6) {
                    PositionTag(player.position)
                    Text("\(player.position.title) · \(player.age.map { "\($0)세" } ?? "-")")
                        .font(.footnote).foregroundStyle(Color(hex: 0xC9D3E6))
                }
                HStack(spacing: 6) {
                    FlagImage(player.flagURL)
                    Text(player.nationality ?? "-").font(.footnote).foregroundStyle(Color(hex: 0xC9D3E6))
                }
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Theme.heroGradient, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color(hex: 0x2B4A86), lineWidth: 1))
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
                    }
                    Spacer()
                }
            }
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
            FMPanel("시즌 기록") { Text("시즌 기록이 없어요.").font(.footnote).foregroundStyle(Theme.textSecondary) }
        } else {
            FMPanel("시즌 기록") {
                VStack(spacing: 0) {
                    ForEach(rows, id: \.0) { row in
                        HStack {
                            Text(row.0).font(.footnote).foregroundStyle(Theme.textSecondary)
                            Spacer()
                            Text("\(row.1)").font(.subheadline.weight(.heavy)).foregroundStyle(Theme.textPrimary)
                            Text(perGame(row.1)).font(.caption2).foregroundStyle(Theme.textSecondary).frame(width: 64, alignment: .trailing)
                        }
                        .padding(.vertical, 6)
                        Divider().overlay(Theme.line.opacity(0.5))
                    }
                }
            }
        }
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
                Text("신상 출처: \(bioSourceText)")
                    .font(.caption2).foregroundStyle(Theme.textSecondary).padding(.top, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if !player.bioDisputed.isEmpty {
                    Text("ESPN 원본과 값이 달라 보정했습니다 (동명이인 프로필이 섞인 것으로 보임).")
                        .font(.caption2).foregroundStyle(Theme.gold).frame(maxWidth: .infinity, alignment: .leading)
                }
                Text("사진·평점·패스 지표는 데이터 출처(\(model.services.sourceName))가 제공하지 않아 표시하지 않습니다.")
                    .font(.caption2).foregroundStyle(Theme.textSecondary).padding(.top, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
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
