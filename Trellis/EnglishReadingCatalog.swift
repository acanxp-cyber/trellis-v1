import Foundation

struct EnglishReadingVocabulary: Codable, Equatable, Sendable {
    let word: String
    let ipa: String
    let meaning: String
}

struct EnglishReadingPassage: Codable, Equatable, Sendable, Identifiable {
    let id: String
    let title: String
    let category: String
    let english: String
    let chinese: String
    let estimatedSeconds: Int
    let vocabulary: [EnglishReadingVocabulary]
}

enum EnglishReadingCatalogError: LocalizedError {
    case missingResource
    case invalidResource(Error)

    var errorDescription: String? {
        switch self {
        case .missingResource:
            return "没有找到英语朗读内容。"
        case .invalidResource:
            return "英语朗读内容暂时无法读取。"
        }
    }
}

enum EnglishReadingCatalog {
    static func load(
        bundle: Bundle = Bundle(for: EnglishReadingBundleToken.self)
    ) throws -> [EnglishReadingPassage] {
        guard let url = bundle.url(
            forResource: "EnglishReading",
            withExtension: "json"
        ) else {
            throw EnglishReadingCatalogError.missingResource
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(
                [EnglishReadingPassage].self,
                from: data
            )
        } catch {
            throw EnglishReadingCatalogError.invalidResource(error)
        }
    }

    static func passage(id: String) -> EnglishReadingPassage? {
        try? load().first { $0.id == id }
    }
}

struct ReadingPassageDeck: Equatable, Sendable {
    private let ids: [String]
    private(set) var currentID: String?

    init(ids: [String], currentID: String? = nil) {
        self.ids = ids
        self.currentID = currentID ?? ids.first
    }

    mutating func next() {
        let alternatives = ids.filter { $0 != currentID }
        currentID = alternatives.randomElement() ?? ids.first
    }
}

private final class EnglishReadingBundleToken {}
