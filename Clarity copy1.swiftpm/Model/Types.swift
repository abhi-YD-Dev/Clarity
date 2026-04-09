

import SwiftUI


enum Difficulty: String, Codable, CaseIterable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    
    var color: Color {
        switch self {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }
}

enum AnswerType: String, Codable, CaseIterable {
    case text = "Text"
    case image = "Image"
    case voice = "Voice"
}

enum TestZone: String, Codable {
    case underconfident = "Underconfident"
    case zoneOfClarity = "Zone of Clarity"
    case overconfident = "Overconfident"
    
    var color: Color {
        switch self {
        case .underconfident: return .blue
        case .zoneOfClarity: return .green
        case .overconfident: return .orange 
        }
    }
}
