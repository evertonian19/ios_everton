import SwiftUI
import Translation
import EvCore
import EvDesign

/// 번역 결과를 기기에 저장해 두어 같은 기사를 다시 번역하지 않는다.
enum TranslationCache {
    private static let key = "ko-translations"

    static func load() -> [String: String] {
        UserDefaults.standard.dictionary(forKey: key) as? [String: String] ?? [:]
    }

    static func save(_ value: [String: String]) {
        // 오래된 항목이 무한정 쌓이지 않도록 일정 개수만 유지한다.
        let trimmed = value.count > 400 ? Dictionary(uniqueKeysWithValues: Array(value).suffix(300)) : value
        UserDefaults.standard.set(trimmed, forKey: key)
    }
}

struct NewsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openURL) private var openURL

    @State private var translations: [String: String] = TranslationCache.load()
    @State private var config: TranslationSession.Configuration?
    @State private var showOriginal = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    Toggle("원문 보기", isOn: $showOriginal)
                        .font(.footnote).tint(Theme.blue).foregroundStyle(Theme.textSecondary)
                        .padding(.horizontal, 4)

                    LoadStateView(state: model.news, retry: { await model.loadNews() }) { items in
                        VStack(spacing: 12) {
                            ForEach(items) { item in
                                NewsCard(item: item,
                                         title: text("t:" + item.id, fallback: item.title),
                                         summary: text("s:" + item.id, fallback: item.summary))
                                    .onTapGesture { if let url = item.link { openURL(url) } }
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(Theme.background)
            .evBrandBars()
            .navigationTitle("뉴스")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable { await model.loadNews(); requestTranslation() }
            .task(id: model.news.value?.count ?? 0) { requestTranslation() }
            .translationTask(config) { session in
                await translate(with: session)
            }
        }
    }

    private func text(_ key: String, fallback: String) -> String {
        showOriginal ? fallback : (translations[key] ?? fallback)
    }

    private func requestTranslation() {
        guard model.news.value?.isEmpty == false else { return }
        if config == nil {
            config = TranslationSession.Configuration(source: Locale.Language(identifier: "en"),
                                                      target: Locale.Language(identifier: "ko"))
        } else {
            config?.invalidate()
        }
    }

    private func translate(with session: TranslationSession) async {
        guard let items = model.news.value else { return }
        var requests: [TranslationSession.Request] = []
        for item in items {
            if translations["t:" + item.id] == nil {
                requests.append(.init(sourceText: item.title, clientIdentifier: "t:" + item.id))
            }
            if !item.summary.isEmpty, translations["s:" + item.id] == nil {
                requests.append(.init(sourceText: item.summary, clientIdentifier: "s:" + item.id))
            }
        }
        guard !requests.isEmpty else { return }
        do {
            let responses = try await session.translations(from: requests)
            for response in responses {
                if let id = response.clientIdentifier { translations[id] = response.targetText }
            }
            TranslationCache.save(translations)
        } catch {
            // 언어팩이 없거나 사용자가 취소한 경우: 원문을 그대로 보여 준다.
        }
    }
}

private struct NewsCard: View {
    let item: NewsItem
    let title: String
    let summary: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let url = item.imageURL {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        Theme.surfaceHigh
                    }
                }
                .frame(height: 150)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            Text(title).font(.headline).foregroundStyle(Theme.textPrimary).multilineTextAlignment(.leading)
            if !summary.isEmpty {
                Text(summary).font(.footnote).foregroundStyle(Theme.textSecondary).lineLimit(4)
                    .multilineTextAlignment(.leading)
            }
            if let date = item.date {
                Text(Fmt.day(date)).font(.caption2).foregroundStyle(Theme.blue)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .evCard()
    }
}
