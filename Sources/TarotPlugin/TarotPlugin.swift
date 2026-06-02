import SwiftUI
import VBWDCore

// MARK: - Plugin Entry Point (Composition Root)

/// iOS port of the `taro` plugin from `vbwd-fe-user`. Registers a "Tarot"
/// side-menu entry that opens the `/tarot` screen — tarot card reading
/// with AI-powered interpretations. Backend mirror: `plugins/taro/` on
/// `vbwd-backend`.
///
/// Same `metadata.name = "taro"` as the web client so a single backend
/// `plugins.json` controls enable/disable across both clients.
public final class TarotPlugin: Plugin, @unchecked Sendable {
    nonisolated public init() {}

    // MARK: - Metadata

    public var metadata: PluginMetadata {
        PluginMetadata(
            name: "tarot",
            version: SemanticVersion(0, 1, 0),
            description: "Tarot card reading with AI-powered interpretations.",
            author: "VBWD",
            keywords: ["tarot", "taro", "oracle", "divination"],
            dependencies: .none,
            translations: ["en": translations]
        )
    }

    // MARK: - Lifecycle

    @MainActor
    public func install(_ sdk: PlatformSDK) async throws {
        let service = DefaultTarotService(api: sdk.api)

        // Standalone screen.
        try sdk.addRoute(PluginRoute(
            path: "/tarot",
            name: "tarot",
            requiresAuth: true,
            view: { @MainActor in
                AnyView(TarotScreen(service: service))
            }
        ))

        // Side-menu entry. Order 50 places it after MeinChat (40) but
        // before Settings (which the core shell handles).
        sdk.addMenuItem(MenuItem(
            id: "tarot",
            icon: "sparkles",
            title: "Tarot",
            routePath: "/tarot",
            order: 50,
            section: "top"
        ))

        sdk.addTranslations("en", translations)
    }

    public func activate() async throws {}
    public func deactivate() async throws {}
    public func uninstall() async throws {}

    // MARK: - Translations

    private var translations: [String: String] {
        [
            "nav.tarot": "Tarot",
            "tarot.title": "Tarot Card Reading",
            "tarot.subtitle": "Get AI-powered tarot interpretations and insights",
            "tarot.dailyLimits": "Daily Limits",
            "tarot.dailyTotal": "Daily Sessions",
            "tarot.dailyRemaining": "Sessions Remaining",
            "tarot.planName": "Your Plan",
            "tarot.startNewSession": "Start a New Reading",
            "tarot.createSession": "Start Reading",
            "tarot.creatingSession": "Creating session…",
            "tarot.closeSession": "End Session",
            "tarot.dailyLimitReached": "You've reached your daily session limit. Try again tomorrow.",
        ]
    }
}
