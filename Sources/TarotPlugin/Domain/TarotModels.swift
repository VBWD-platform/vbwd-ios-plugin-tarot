import Foundation

// MARK: - Daily limits

/// Response of `GET /taro/limits`. Mirrors `DailyLimits` in
/// `vbwd-fe-user/plugins/taro/src/stores/taro.ts`.
public struct DailyLimits: Codable, Equatable, Sendable {
    public let dailyTotal: Int
    public let dailyRemaining: Int
    public let dailyUsed: Int
    public let planName: String
    public let canCreate: Bool

    enum CodingKeys: String, CodingKey {
        case dailyTotal = "daily_total"
        case dailyRemaining = "daily_remaining"
        case dailyUsed = "daily_used"
        case planName = "plan_name"
        case canCreate = "can_create"
    }
}

public struct LimitsResponse: Codable, Sendable {
    public let success: Bool
    public let limits: DailyLimits?
}

// MARK: - Cards

public enum CardPosition: String, Codable, Sendable {
    case past = "PAST"
    case present = "PRESENT"
    case future = "FUTURE"
    case additional = "ADDITIONAL"
}

public enum CardOrientation: String, Codable, Sendable {
    case upright = "UPRIGHT"
    case reversed = "REVERSED"
}

public struct Arcana: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let number: Int?
    public let name: String
    public let suit: String?
    public let rank: String?
    /// Backend currently emits one of: `"MAJOR_ARCANA"`, `"CUPS"`,
    /// `"PENTACLES"`, `"SWORDS"`, `"WANDS"`. The TS type in vbwd-fe-user
    /// only documents `MAJOR_ARCANA` / `MINOR_ARCANA` but the wire is
    /// richer, so we keep this as a raw String for forward-compat —
    /// readers use `isMajorArcana` / `suitName`.
    public let arcanaType: String
    public let uprightMeaning: String
    public let reversedMeaning: String
    public let imageUrl: String

    public var isMajorArcana: Bool { arcanaType == "MAJOR_ARCANA" }
    /// Returns one of `"CUPS" | "PENTACLES" | "SWORDS" | "WANDS"` when
    /// the card is a minor arcana, else `nil`.
    public var suitName: String? {
        switch arcanaType {
        case "CUPS", "PENTACLES", "SWORDS", "WANDS": return arcanaType
        default: return nil
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, number, name, suit, rank
        case arcanaType = "arcana_type"
        case uprightMeaning = "upright_meaning"
        case reversedMeaning = "reversed_meaning"
        case imageUrl = "image_url"
    }
}

public struct TaroCard: Codable, Identifiable, Equatable, Sendable {
    public let cardId: String
    public let position: CardPosition
    public let orientation: CardOrientation
    public let arcanaId: String
    public let arcana: Arcana?
    public let aiInterpretation: String?
    public let interpretation: String?

    public var id: String { cardId }

    enum CodingKeys: String, CodingKey {
        case cardId = "card_id"
        case position, orientation, arcana
        case arcanaId = "arcana_id"
        case aiInterpretation = "ai_interpretation"
        case interpretation
    }
}

// MARK: - Session

public enum TaroSessionStatus: String, Codable, Sendable {
    case active = "ACTIVE"
    case expired = "EXPIRED"
    case closed = "CLOSED"
}

public struct TaroSession: Codable, Identifiable, Equatable, Sendable {
    public let sessionId: String
    public let userId: String?
    public let status: TaroSessionStatus
    public let cards: [TaroCard]
    public let createdAt: String
    public let expiresAt: String?
    public let endedAt: String?
    public let tokensConsumed: Int
    public let followUpCount: Int
    public let maxFollowUps: Int?
    public let spreadId: String?

    public var id: String { sessionId }

    enum CodingKeys: String, CodingKey {
        case status, cards
        case sessionId = "session_id"
        case userId = "user_id"
        case createdAt = "created_at"
        case expiresAt = "expires_at"
        case endedAt = "ended_at"
        case tokensConsumed = "tokens_consumed"
        case followUpCount = "follow_up_count"
        case maxFollowUps = "max_follow_ups"
        case spreadId = "spread_id"
    }
}

public struct SessionResponse: Codable, Sendable {
    public let success: Bool
    public let session: TaroSession?
    public let message: String?
}

/// Response of `POST /taro/session/<id>/situation`. The backend
/// returns the Oracle's textual interpretation, not a full session.
public struct SituationResponse: Codable, Sendable {
    public let success: Bool
    public let interpretation: String?
    public let error: String?
}
