import Foundation

/// API endpoint paths for the tarot plugin. Mirrors the backend
/// `plugins/taro/` routes under `/api/v1/`.
enum TarotEndpoints {
    static let limits = "/taro/limits"
    static let session = "/taro/session"
    static let history = "/taro/history"
    static func situation(sessionId: String) -> String {
        "/taro/session/\(sessionId)/situation"
    }
    static func followUp(sessionId: String) -> String {
        "/taro/session/\(sessionId)/follow-up"
    }
    static func followUpQuestion(sessionId: String) -> String {
        "/taro/session/\(sessionId)/follow-up-question"
    }
    static func cardExplanation(sessionId: String) -> String {
        "/taro/session/\(sessionId)/card-explanation"
    }
}
