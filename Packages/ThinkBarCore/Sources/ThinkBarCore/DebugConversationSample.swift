public enum DebugConversationSample {
    public static let longConversation: [ConversationRecord] = [
        turn(
            "ThinkBarを毎日使えるmacOSアプリにしたい。",
            "MVPを壊さず、小さな機能単位で改善します。"
        ),
        turn(
            "CoreはSwiftUIやAppKitを知らない設計にしたい。",
            "UI非依存のSwift Packageへロジックを集約します。"
        ),
        turn(
            "AI Providerは交換可能にして。",
            "AIProvider protocolとDependency Injectionを採用します。"
        ),
        turn(
            "まずOllamaを使い、後でOpenRouterも追加したい。",
            "ProviderConfigurationとFactoryで切り替え可能にします。"
        ),
        turn(
            "APIキーは平文保存したくない。",
            "OpenRouterのAPIキーはKeychainへ保存します。"
        ),
        turn(
            "会話履歴は再起動後も残して。",
            "ConversationStoreをv2形式で永続化します。"
        ),
        turn(
            "直近の会話だけをAIへ送りたい。",
            "ContextBuilderが直近5ターンを選択します。"
        ),
        ConversationRecord(
            user: "長期会話では重要な判断をSummaryに残したい。",
            assistant: "継続目的、設計判断、好み、制約を優先します。",
            context: ConversationContextMetadata(
                summary: """
                The user is building ThinkBar as a daily-use macOS app.
                Keep Core UI-independent, providers swappable, API keys in Keychain,
                and preserve the MVP through small tested changes.
                """,
                summaryCoveredConversationCount: 8
            )
        ),
        turn(
            "Summary生成は通常回答を遅くしないで。",
            "通常回答後にバックグラウンドで生成します。"
        ),
        turn(
            "デバッグ時に実際のContextを確認したい。",
            "メモリ内のDebug Consoleへ送信内容を記録します。"
        ),
        turn(
            "日本語と英語が混ざるContext量も知りたい。",
            "文字種を考慮した簡易Token推定を使います。"
        ),
        turn(
            "Summaryの圧縮効果を確認するには？",
            ""
        ),
    ]

    private static func turn(
        _ user: String,
        _ assistant: String
    ) -> ConversationRecord {
        ConversationRecord(user: user, assistant: assistant)
    }
}
