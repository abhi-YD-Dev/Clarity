
import Foundation
import FoundationModels

@Generable
struct AIAnalysisResult {

    @Guide(description: "Integer accuracy score from 0 to 100. Evaluate semantic correctness, not wording. 0 = completely wrong, 100 = perfect.")
    var accuracyScore: Int

    @Guide(description: "Up to 3 key concepts present in the model answer but missing or unclear in the user's answer. Keep each item under 6 words. Empty array if none missing.")
    var missingConcepts: [String]

    @Guide(description: "Up to 2 factually incorrect claims the user made. Empty array if none. Keep each item under 8 words.")
    var incorrectClaims: [String]

    @Guide(description: "One sentence of specific, encouraging, actionable feedback. Reference what the user got right BEFORE addressing the gap.")
    var constructiveFeedback: String

    @Guide(description: "Exactly one word: Excellent, Solid, Partial, Minimal, or Blank.")
    var recallSignal: String
}

struct EvaluationProfile {
    let sessionID: UUID = UUID()
    let startTime: Date

    var endTime: Date?
    var tokensGenerated: Int = 0
    var streamChunkCount: Int = 0
    var toolCallCount: Int = 0
    var fallbackTriggered: Bool = false

    var latencyMilliseconds: Double {
        guard let end = endTime else { return 0 }
        return end.timeIntervalSince(startTime) * 1000
    }

    var tokensPerSecond: Double {
        guard let end = endTime, latencyMilliseconds > 0 else { return 0 }
        return Double(tokensGenerated) / end.timeIntervalSince(startTime)
    }

    var summary: String {
        """
        ── ClarityAI Profile [\(sessionID.uuidString.prefix(8))] ──
        Latency:  \(String(format: "%.0f", latencyMilliseconds))ms
        Tokens:   \(tokensGenerated) (\(String(format: "%.1f", tokensPerSecond)) t/s)
        Chunks:   \(streamChunkCount)
        Tools:    \(toolCallCount)
        Fallback: \(fallbackTriggered ? "YES" : "no")
        """
    }
}



enum StreamingState: Equatable {
    case idle
    case preparing
    case toolCalling
    case streaming
    case complete
    case failed(String)

    static func == (lhs: StreamingState, rhs: StreamingState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.preparing, .preparing),
             (.toolCalling, .toolCalling), (.streaming, .streaming),
             (.complete, .complete):
            return true
        case (.failed(let a), .failed(let b)):
            return a == b
        default:
            return false
        }
    }
}

