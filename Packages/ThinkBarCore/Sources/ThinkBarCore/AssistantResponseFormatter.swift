import Foundation

public enum AssistantResponseFormatter {
    public static func markdownPreservingWhitespace(
        _ text: String
    ) -> AttributedString {
        var output = AttributedString()
        var cursor = text.startIndex

        while let openingRange = text.range(
            of: "```",
            range: cursor..<text.endIndex
        ) {
            guard let closingRange = text.range(
                of: "```",
                range: openingRange.upperBound..<text.endIndex
            ) else {
                appendProse(String(text[cursor...]), to: &output)
                return output
            }

            appendProse(
                String(text[cursor..<openingRange.lowerBound]),
                to: &output
            )
            appendCode(
                String(text[openingRange.upperBound..<closingRange.lowerBound]),
                to: &output
            )
            cursor = closingRange.upperBound
        }

        appendProse(String(text[cursor...]), to: &output)
        return output
    }

    private static func appendProse(
        _ text: String,
        to output: inout AttributedString
    ) {
        guard !text.isEmpty else { return }

        let attributed = try? AttributedString(
            markdown: text,
            options: .init(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            )
        )
        var fragment = attributed ?? AttributedString(text)
        let expectedTrailingNewlines = text.reversed().prefix(while: {
            $0 == "\n"
        }).count
        let actualTrailingNewlines = String(fragment.characters)
            .reversed()
            .prefix(while: { $0 == "\n" })
            .count
        if expectedTrailingNewlines > actualTrailingNewlines {
            fragment.append(AttributedString(String(
                repeating: "\n",
                count: expectedTrailingNewlines - actualTrailingNewlines
            )))
        }
        output.append(fragment)
    }

    private static func appendCode(
        _ fencedContent: String,
        to output: inout AttributedString
    ) {
        let code: String
        if let firstNewline = fencedContent.firstIndex(of: "\n") {
            code = String(fencedContent[fencedContent.index(after: firstNewline)...])
        } else {
            code = fencedContent
        }

        var attributed = AttributedString(code)
        attributed.inlinePresentationIntent = .code
        output.append(attributed)
    }
}
