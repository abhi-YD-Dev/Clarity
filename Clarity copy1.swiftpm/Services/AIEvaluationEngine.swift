import Foundation
import FoundationModels
import NaturalLanguage
import Vision
import UIKit


struct ConceptExtractorTool: Tool {
    var name: String = "extract_key_concepts"
    var description: String = "Extracts core educational concepts from a model answer to build a grading rubric. Call this first before evaluating any user answer."

    @Generable
    struct Arguments {
        @Guide(description: "The complete model answer text to analyze for key concepts.")
        var modelAnswerText: String
    }

    func call(arguments: Arguments) async throws -> String {
        let text = arguments.modelAnswerText
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else {
            return "No model answer provided. Grade based on topic title and question context only."
        }

        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text
        var concepts: [String] = []
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace]

        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex,
            unit: .word,
            scheme: .lexicalClass,
            options: options
        ) { tag, range in
            if let tag = tag, tag == .noun || tag == .verb {
                let word = String(text[range])
                if word.count > 3 { concepts.append(word) }
            }
            return true
        }

        let unique = Array(Set(concepts)).prefix(8).sorted()
        return """
        GRADING RUBRIC CONCEPTS: \(unique.joined(separator: ", "))
        Use these as your checklist. Deduct points for each concept missing from the user's answer.
        """
    }
}


struct AnswerProfilerTool: Tool {
    var name: String = "profile_user_answer"
    var description: String = "Profiles the user's answer for word count, coherence, and topic keyword coverage. Call this second to calibrate your score range before grading."

    @Generable
    struct Arguments {
        @Guide(description: "The user's raw answer text to profile.")
        var userAnswerText: String

        @Guide(description: "The topic title for keyword matching.")
        var topicTitle: String
    }

    func call(arguments: Arguments) async throws -> String {
        let answer = arguments.userAnswerText
        let words = answer.split(separator: " ")
        let sentences = answer.split(separator: ".")
        let wordCount = words.count

        let topicWords = arguments.topicTitle.lowercased().split(separator: " ")
        let answerLower = answer.lowercased()
        let topicHits = topicWords.filter { answerLower.contains($0) }.count
        let topicCoverage = topicWords.isEmpty ? 0 : (topicHits * 100 / topicWords.count)
        let avgWords = sentences.isEmpty ? 0 : wordCount / max(1, sentences.count)

        let lengthSignal: String
        switch wordCount {
        case 0...4:   lengthSignal = "BLANK — score must be 0-15"
        case 5...15:  lengthSignal = "MINIMAL — cap score at 40"
        case 16...40: lengthSignal = "PARTIAL — score range 35-70"
        case 41...80: lengthSignal = "SOLID — score range 55-85"
        default:      lengthSignal = "DETAILED — score range 70-100 based on accuracy"
        }

        return """
        ANSWER PROFILE:
        Word count: \(wordCount) → \(lengthSignal)
        Sentence count: \(sentences.count), avg \(avgWords) words/sentence
        Topic keyword coverage: \(topicCoverage)%
        Coherence: \(avgWords > 3 ? "Structured" : "Fragmented")
        Enforce the score range above strictly.
        """
    }
}


struct ImageOCRTool: Tool {
    var name: String = "extract_text_from_image"
    var description: String = "Performs OCR on a base64-encoded image answer to extract text for semantic evaluation. Call this when the user submitted an image answer."

    @Generable
    struct Arguments {
        @Guide(description: "Base64-encoded JPEG image data from the user's answer.")
        var base64ImageData: String
    }

    func call(arguments: Arguments) async throws -> String {
        guard
            let data = Data(base64Encoded: arguments.base64ImageData),
            let uiImage = UIImage(data: data),
            let cgImage = uiImage.cgImage
        else {
            return "OCR failed: Could not decode image. Treat this answer as blank."
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(returning: "OCR error: \(error.localizedDescription). Treat as blank.")
                    return
                }
                let text = request.results?
                    .compactMap { ($0 as? VNRecognizedTextObservation)?.topCandidates(1).first?.string }
                    .joined(separator: " ") ?? ""

                continuation.resume(returning: text.isEmpty
                    ? "OCR returned no text. Treat this answer as blank."
                    : "EXTRACTED TEXT FROM IMAGE:\n\"\(text)\""
                )
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            do {
                try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
            } catch {
                continuation.resume(returning: "OCR handler error: \(error.localizedDescription)")
            }
        }
    }
}


actor AIEvaluationEngine {
    static let shared = AIEvaluationEngine()
    private init() {}

    func streamEvaluation(
        payload: AIEvaluationPayload,
        onStateChange:   @escaping @Sendable (StreamingState) async -> Void,
        onProfileUpdate: @escaping @Sendable (EvaluationProfile) async -> Void,
        onPartialUpdate: @escaping @Sendable (AIAnalysisResult.PartiallyGenerated) async -> Void,
        onComplete:      @escaping @Sendable (AIAnalysisResult) async -> Void,
        onError:         @escaping @Sendable (Error) async -> Void
    ) {
        Task {
            var profile = EvaluationProfile(startTime: Date())
            await onStateChange(.preparing)

            do {
                
                let modelAnswerText = payload.solutions
                    .compactMap { $0.textContent }
                    .joined(separator: "\n")

            
                var userText = payload.userAnswers
                    .filter { $0.type == .text }
                    .compactMap { $0.textContent }
                    .joined(separator: "\n")

               
                let imageAnswers = payload.userAnswers.filter { $0.type == .image }
                if !imageAnswers.isEmpty {
                    await onStateChange(.toolCalling)
                    for imageAnswer in imageAnswers {
                        guard let data = imageAnswer.imageData else { continue }
                        let ocrResult = try await ImageOCRTool().call(
                            arguments: .init(base64ImageData: data.base64EncodedString())
                        )
                        userText += "\n\(ocrResult)"
                        profile.toolCallCount += 1
                    }
                }

                let finalUserAnswer = userText.trimmingCharacters(in: .whitespacesAndNewlines)

                
                await onStateChange(.toolCalling)

                let systemInstructions = """
                You are ClarityAI, a metacognitive educational evaluator.
                Your only job is to evaluate a student's answer and return a structured result.

                PROTOCOL:
                1. Call extract_key_concepts on the model answer to build your rubric.
                2. Call profile_user_answer to get the score range constraint.
                3. Reason internally: which rubric concepts are present vs missing?
                4. Score based on semantic accuracy, not grammar or length alone.
                5. Never inflate scores. Overgrading destroys metacognitive calibration.
                6. Return a complete AIAnalysisResult. No deviations from the schema.
                """

                let session = LanguageModelSession(
                    tools: [
                        ConceptExtractorTool(),
                        AnswerProfilerTool(),
                        ImageOCRTool()
                    ],
                    instructions: systemInstructions
                )

               
                await onStateChange(.streaming)

                let promptString = buildPrompt(
                    payload: payload,
                    modelAnswer: modelAnswerText,
                    userAnswer: finalUserAnswer
                )

               
                let response = try await session.respond(generating: AIAnalysisResult.self) {
                    Prompt(promptString)
                }

                let finalResult = response.content
                profile.streamChunkCount = 1
                profile.tokensGenerated = 1

              
                profile.endTime = Date()
                await onProfileUpdate(profile)
                await onStateChange(.complete)
                await onComplete(finalResult)
                print(profile.summary)

            } catch {
                profile.endTime = Date()
                profile.fallbackTriggered = true
                await onProfileUpdate(profile)
                await onStateChange(.failed(error.localizedDescription))
                await onError(error)
            }
        }
    }


    private func buildPrompt(payload: AIEvaluationPayload, modelAnswer: String, userAnswer: String) -> String {
        let hasModel = !modelAnswer.trimmingCharacters(in: .whitespaces).isEmpty
        let hasUser  = !userAnswer.trimmingCharacters(in: .whitespaces).isEmpty

        return """
        ═══════════════════════════════════════
        CLARITY EVALUATION REQUEST
        ═══════════════════════════════════════

        TOPIC:      \(payload.title)
        QUESTION:   \(payload.question)
        HINT:       \(payload.quickHint)
        DIFFICULTY: \(String(describing: payload.difficulty))

        ── MODEL ANSWER (Ground Truth) ─────────
        \(hasModel ? modelAnswer : "No model answer stored. Evaluate from topic and question context only.")

        ── USER'S SUBMITTED ANSWER ─────────────
        \(hasUser ? userAnswer : "BLANK — the user submitted nothing.")

        ═══════════════════════════════════════
        EVALUATION STEPS (FOLLOW IN ORDER)
        ═══════════════════════════════════════

        STEP 1 → Call extract_key_concepts with the model answer above.
        STEP 2 → Call profile_user_answer with the user answer and topic title "\(payload.title)".
        STEP 3 → Internal reasoning:
                 a) Which rubric concepts appear in the user's answer?
                 b) Which are completely missing?
                 c) Are there any factually incorrect claims?
                 d) What score range does the profile constrain you to?
        STEP 4 → Apply difficulty modifier:
                 Hard topics → be 5pts more lenient.
                 Easy topics → be 5pts stricter.
        STEP 5 → Fill AIAnalysisResult:
                 • accuracyScore    — integer 0-100, within the profile-constrained range
                 • missingConcepts  — from rubric only, max 3, each under 6 words
                 • incorrectClaims  — factual errors only, empty array if none
                 • constructiveFeedback — 1 sentence: acknowledge a strength FIRST, then the gap
                 • recallSignal     — exactly one of: Excellent / Solid / Partial / Minimal / Blank
        ═══════════════════════════════════════
        """
    }

    func fallbackEvaluation(payload: AIEvaluationPayload) async -> AIAnalysisResult {
        let userText = payload.userAnswers
            .filter { $0.type == .text }
            .compactMap { $0.textContent }
            .joined(separator: " ")

        let wordCount = userText.split(separator: " ").count
        let topicHit = userText.lowercased().contains(payload.title.lowercased()) || wordCount > 30

        try? await Task.sleep(for: .seconds(1.8))

        switch wordCount {
        case 0...4:
            return AIAnalysisResult(
                accuracyScore: 10,
                missingConcepts: ["Core definition", "Key mechanism", "Supporting context"],
                incorrectClaims: [],
                constructiveFeedback: "You attempted the topic — now try explaining the core idea in 2-3 sentences from memory.",
                recallSignal: "Blank"
            )
        case 5...20:
            return AIAnalysisResult(
                accuracyScore: 32,
                missingConcepts: ["Detailed explanation", "Concrete example"],
                incorrectClaims: [],
                constructiveFeedback: "You identified the right area — expand by explaining the mechanism step by step.",
                recallSignal: "Minimal"
            )
        default:
            let score = topicHit ? Int.random(in: 63...85) : Int.random(in: 44...64)
            return AIAnalysisResult(
                accuracyScore: score,
                missingConcepts: score < 75 ? ["Precise terminology", "Edge case or exception"] : [],
                incorrectClaims: [],
                constructiveFeedback: score >= 75
                    ? "Strong recall of the fundamentals — add precise terminology to push past 85."
                    : "Good start on the concept — deepen your explanation of the underlying mechanism.",
                recallSignal: score >= 80 ? "Excellent" : (score >= 65 ? "Solid" : "Partial")
            )
        }
    }
}
