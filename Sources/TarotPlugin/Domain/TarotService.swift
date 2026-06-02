import Foundation
import VBWDCore

/// Protocol for tarot API operations (DIP — testable).
protocol TarotServiceProtocol: Sendable {
    func fetchDailyLimits() async throws -> DailyLimits
    func createSession() async throws -> TaroSession
    /// Returns the Oracle's textual interpretation for the user's situation.
    func submitSituation(sessionId: String, text: String, language: String) async throws -> String
}

/// Default implementation backed by `APIClient`.
final class DefaultTarotService: TarotServiceProtocol, @unchecked Sendable {
    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func fetchDailyLimits() async throws -> DailyLimits {
        let resp: LimitsResponse = try await api.get(TarotEndpoints.limits)
        guard resp.success, let limits = resp.limits else {
            throw APIError.http(status: 200, message: "Failed to load tarot limits")
        }
        return limits
    }

    private struct EmptyBody: Encodable {}

    func createSession() async throws -> TaroSession {
        let resp: SessionResponse = try await api.post(TarotEndpoints.session, body: EmptyBody())
        guard resp.success, let session = resp.session else {
            throw APIError.http(status: 200, message: resp.message ?? "Failed to create session")
        }
        return session
    }

    private struct SituationBody: Encodable {
        let situationText: String
        let language: String

        enum CodingKeys: String, CodingKey {
            case situationText = "situation_text"
            case language
        }
    }

    func submitSituation(sessionId: String, text: String, language: String) async throws -> String {
        let resp: SituationResponse = try await api.post(
            TarotEndpoints.situation(sessionId: sessionId),
            body: SituationBody(situationText: text, language: language))
        guard resp.success, let interpretation = resp.interpretation else {
            throw APIError.http(status: 200, message: resp.error ?? "Failed to submit situation")
        }
        return interpretation
    }
}
