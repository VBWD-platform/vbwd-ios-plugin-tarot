import Foundation
import VBWDCore

/// A single turn in the Oracle chat — user's prompt or the AI reply.
struct TarotChatMessage: Identifiable, Equatable {
    enum Role: Equatable { case user, oracle }
    let id: UUID
    let role: Role
    let content: String

    init(role: Role, content: String) {
        self.id = UUID()
        self.role = role
        self.content = content
    }
}

@MainActor
final class TarotViewModel: ObservableObject {
    @Published var limits: DailyLimits?
    @Published var currentSession: TaroSession?
    @Published var situationText: String = ""
    @Published var messages: [TarotChatMessage] = []
    @Published var isLoadingLimits = false
    @Published var isCreatingSession = false
    @Published var isSubmittingSituation = false
    @Published var errorMessage: String?

    private let service: TarotServiceProtocol

    init(service: TarotServiceProtocol) {
        self.service = service
    }

    func loadLimits() async {
        isLoadingLimits = true
        errorMessage = nil
        do {
            limits = try await service.fetchDailyLimits()
        } catch {
            errorMessage = (error as? APIError)?.message ?? error.localizedDescription
        }
        isLoadingLimits = false
    }

    func startReading() async {
        guard !isCreatingSession else { return }
        isCreatingSession = true
        errorMessage = nil
        do {
            currentSession = try await service.createSession()
            messages = []
            // Refresh limits so the "X remaining" line decrements immediately.
            limits = try? await service.fetchDailyLimits()
        } catch {
            errorMessage = (error as? APIError)?.message ?? error.localizedDescription
        }
        isCreatingSession = false
    }

    func submitSituation() async {
        guard let session = currentSession else { return }
        let trimmed = situationText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isSubmittingSituation = true
        errorMessage = nil
        messages.append(TarotChatMessage(role: .user, content: trimmed))
        situationText = ""
        do {
            let reply = try await service.submitSituation(
                sessionId: session.sessionId,
                text: trimmed,
                language: "en")
            messages.append(TarotChatMessage(role: .oracle, content: reply))
        } catch {
            errorMessage = (error as? APIError)?.message ?? error.localizedDescription
        }
        isSubmittingSituation = false
    }

    func endSession() {
        // Per requirements: closing the session clears local state. The
        // backend has its own session lifecycle — the UI just forgets.
        currentSession = nil
        situationText = ""
        messages = []
    }
}
