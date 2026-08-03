import Foundation
import Testing
@testable import ThinkBarCore

struct AssistantResponseFormatterTests {
    @Test func preservesParagraphsCodeWhitespaceAndTrailingNewline() {
        let response = """
        First paragraph.

        Second paragraph.

        ```swift
        let value = 1
          print(value)
        ```

        Final paragraph.

        """

        let formatted =
            AssistantResponseFormatter.markdownPreservingWhitespace(response)
        let displayedText = String(formatted.characters)

        #expect(displayedText.hasPrefix(
            "First paragraph.\n\nSecond paragraph.\n\n"
        ))
        #expect(displayedText.contains(
            "let value = 1\n  print(value)\n"
        ))
        #expect(displayedText.hasSuffix("Final paragraph.\n"))
    }

    @Test func preservesInlineFormattingWhitespace() {
        let response = "Before  **important**\nAfter\n"

        let formatted =
            AssistantResponseFormatter.markdownPreservingWhitespace(response)

        #expect(String(formatted.characters) == "Before  important\nAfter\n")
    }

    @Test func keepsEntireLongMarkdownResponse() {
        let paragraphs = (1...80).map { index in
            "Paragraph \(index): ThinkBar keeps long assistant replies visible.\n"
        }
        .joined(separator: "\n")
        let code = String(repeating: "let value = 1\n", count: 40)
        let response = paragraphs
            + "```swift\n"
            + code
            + "```\n\n"
            + "Final paragraph 80.\n"

        let formatted =
            AssistantResponseFormatter.markdownPreservingWhitespace(response)
        let displayedText = String(formatted.characters)

        #expect(displayedText.hasPrefix("Paragraph 1:"))
        #expect(displayedText.contains("Paragraph 80:"))
        #expect(displayedText.contains(code))
        #expect(displayedText.hasSuffix("Final paragraph 80.\n"))
        #expect(displayedText.count >= 2_000)
    }
}
