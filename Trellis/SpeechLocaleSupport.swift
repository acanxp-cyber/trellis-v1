import Foundation

enum SpeechLocaleSupport {
    static func match(
        _ requested: Locale,
        in supported: [Locale]
    ) -> Locale? {
        let requestedParts = parts(for: requested)

        return supported.first { candidate in
            let candidateParts = parts(for: candidate)
            return candidateParts.language == requestedParts.language
                && candidateParts.region == requestedParts.region
        } ?? supported.first { candidate in
            parts(for: candidate).language == requestedParts.language
        }
    }

    private static func parts(
        for locale: Locale
    ) -> (language: String, region: String?) {
        let components = locale.identifier
            .replacingOccurrences(of: "_", with: "-")
            .split(separator: "-")
            .map(String.init)
        let language = components.first?.lowercased() ?? ""
        let region = components
            .dropFirst()
            .first { component in
                component.count == 2
                    && component.uppercased() == component
            }?
            .uppercased()
        return (language, region)
    }
}
