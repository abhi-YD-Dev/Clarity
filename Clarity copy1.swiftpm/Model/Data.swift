

import Foundation
import SwiftData


@Model
final class Concept {
    var id: UUID = UUID()
    var title: String
    var isCustom: Bool
    
  
    @Relationship(deleteRule: .cascade)
    var topics: [Topic] = []
    
    init(title: String, isCustom: Bool = true) {
        self.title = title
        self.isCustom = isCustom
    }
}


@Model
final class Topic {
    var id: UUID = UUID()
    var title: String
    var question: String
    var quickHint: String
    var difficultyRaw: String
    
    var difficulty: Difficulty {
        Difficulty(rawValue: difficultyRaw) ?? .medium
    }
    var solutions: [SolutionMedia] = []
    var isBookmarked: Bool = false
    
    init(title: String, question: String, quickHint: String, difficulty: Difficulty, solution: [SolutionMedia] = [] ) {
        self.title = title
        self.question = question
        self.quickHint = quickHint
        self.difficultyRaw = difficulty.rawValue
        self.solutions = solution
    }
}

struct SolutionMedia: Identifiable, Codable {
    var id = UUID()
    var type: MediaType
    var textContent: String?
    var imageData: Data?
    var audioData: Data?
}

enum MediaType: String, Codable {
    case text, image, voice
}


@Model
final class Attempt {
    var id: UUID = UUID()
    var topicID: UUID
    var date: Date = Date.now
    
    // 1. User's Submitted Data
    var textAnswers: [String] = []
    var imageNames: [String] = []
    var voiceFileNames: [String] = []
 
    var confidenceLevel: Int
    var predictedScore: Int
    var aiScore: Int?
  
    var reflectionText: String
   
    @Transient
    var actualAccuracy: Int {
        // If AI graded it, use that objective score. Otherwise, use their self-predicted score.
        return aiScore ?? predictedScore
    }
    
    @Transient
    var calibrationGap: Int {
        return confidenceLevel - actualAccuracy
    }
    
    @Transient
    var zone: TestZone {
        let gap = calibrationGap
        if gap > 10 { return .overconfident }
        if gap < -10 { return .underconfident }
        return .zoneOfClarity
    }
    
    init(topicID: UUID, confidenceLevel: Int, predictedScore: Int, aiScore: Int? = nil, reflectionText: String = "", textAnswers: [String] = [], imageNames: [String] = [], voiceFileNames: [String] = []) {
        self.topicID = topicID
        self.confidenceLevel = confidenceLevel
        self.predictedScore = predictedScore
        self.aiScore = aiScore
        self.reflectionText = reflectionText
        self.textAnswers = textAnswers
        self.imageNames = imageNames
        self.voiceFileNames = voiceFileNames
    }
}
