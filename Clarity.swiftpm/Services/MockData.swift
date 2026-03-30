import Foundation
import SwiftData

@MainActor
class MockData {
    
    static func insertSampleData(modelContext: ModelContext) {

        let fetchDescriptor = FetchDescriptor<Concept>()
        let existingConcepts = (try? modelContext.fetch(fetchDescriptor)) ?? []
        
        guard existingConcepts.isEmpty else { return }

        let cogSci = Concept(title: "Cognitive Science", isCustom: false)
        
        let illusionOfCompetence = Topic(
            title: "Illusion of Competence",
            question: "Why does re-reading notes make us feel like we know the material when we actually don't?",
            quickHint: "Recognition vs. Recall",
            difficulty: .medium,
            solution: [SolutionMedia(type: .text, textContent: "Re-reading triggers 'recognition memory' (fluency), making the brain feel familiar with the text. However, it does not build 'recall memory'.")]
        )
        
        let activeRecall = Topic(
            title: "Active Recall",
            question: "What is Active Recall and why is it effective?",
            quickHint: "Testing effect",
            difficulty: .easy,
            solution: [SolutionMedia(type: .text, textContent: "Active recall is stimulating memory during learning. It forces the brain to retrieve info, strengthening neural pathways.")]
        )
        
        let metacognition = Topic(
            title: "Metacognition",
            question: "Define metacognition in the context of studying.",
            quickHint: "Thinking about thinking",
            difficulty: .hard,
            solution: [SolutionMedia(type: .text, textContent: "The awareness and understanding of one's own thought processes. It helps in accurately evaluating what you truly know.")]
        )
        
        cogSci.topics = [illusionOfCompetence, activeRecall, metacognition]
        modelContext.insert(cogSci)

        let swiftUI = Concept(title: "SwiftUI ", isCustom: false)

        let viewIdentity = Topic(
            title: "Structural Identity",
            question: "How does SwiftUI decide when to redraw a view?",
            quickHint: "Implicit vs. Explicit ID",
            difficulty: .hard,
            solution: [SolutionMedia(type: .text, textContent: "SwiftUI uses Identity. Structural Identity is determined by the view's position in the code hierarchy.")]
        )

        let opaqueTypes = Topic(
            title: "some View",
            question: "What is an 'Opaque Type'?",
            quickHint: "Type hiding",
            difficulty: .medium,
            solution: [SolutionMedia(type: .text, textContent: "The 'some' keyword hides the concrete type from the caller, allowing complex nested stacks to be returned easily.")]
        )

        let modifierOrder = Topic(
            title: "Modifier Order",
            question: "Why does the order of modifiers matter?",
            quickHint: "Wrapping views",
            difficulty: .easy,
            solution: [SolutionMedia(type: .text, textContent: "Modifiers wrap views in new hidden views. Order determines which view is wrapping which, affecting layout and color.")]
        )

        let viewBuilder = Topic(
            title: "@ViewBuilder",
            question: "What is the @ViewBuilder attribute?",
            quickHint: "Result builders",
            difficulty: .medium,
            solution: [SolutionMedia(type: .text, textContent: "A parameter attribute allowing closures to provide multiple child views without explicit commas.")]
        )

        swiftUI.topics = [viewIdentity, opaqueTypes, modifierOrder, viewBuilder]
        modelContext.insert(swiftUI)

        let swiftDataConcept = Concept(title: "SwiftData Architecture", isCustom: false)

        let containerTopic = Topic(
            title: "ModelContainer",
            question: "What is the purpose of the ModelContainer?",
            quickHint: "Schema + Storage",
            difficulty: .medium,
            solution: [SolutionMedia(type: .text, textContent: "The manager of persistence. It defines the schema and bridge your code to the underlying SQLite database.")]
        )

        let contextTopic = Topic(
            title: "ModelContext",
            question: "Explain the role of the ModelContext.",
            quickHint: "Scratchpad for data",
            difficulty: .medium,
            solution: [SolutionMedia(type: .text, textContent: "A 'scratchpad' where you add, delete, or change data. Changes aren't permanent until saved.")]
        )

        let queryMacro = Topic(
            title: "@Query Macro",
            question: "How does @Query update the UI automatically?",
            quickHint: "Dynamic Fetching",
            difficulty: .easy,
            solution: [SolutionMedia(type: .text, textContent: "It sets up a subscription to the database. When data changes, it triggers a UI refresh.")]
        )

        let cloudKitSync = Topic(
            title: "CloudKit Integration",
            question: "What is required for SwiftData to sync with iCloud?",
            quickHint: "Optional properties",
            difficulty: .hard,
            solution: [SolutionMedia(type: .text, textContent: "All properties must be optional or have default values, and relationships must be optional.")]
        )

        swiftDataConcept.topics = [containerTopic, contextTopic, queryMacro, cloudKitSync]
        modelContext.insert(swiftDataConcept)

        let swiftFundamentals = Concept(title: "Swift Fundamentals", isCustom: false)

        let valueVsRef = Topic(
            title: "Value vs. Reference Types",
            question: "Difference between a Struct and a Class?",
            quickHint: "Copying vs. Sharing",
            difficulty: .medium,
            solution: [SolutionMedia(type: .text, textContent: "Structs are value types (unique copies). Classes are reference types (shared instances).")]
        )

        let optionals = Topic(
            title: "The Optional Type",
            question: "What is an Optional internally?",
            quickHint: "Enum with .none and .some",
            difficulty: .easy,
            solution: [SolutionMedia(type: .text, textContent: "An Enum with two cases: .none (nil) and .some(wrappedValue).")]
        )

        let closures = Topic(
            title: "Escaping Closures",
            question: "What does @escaping mean?",
            quickHint: "Lifetime of closure",
            difficulty: .hard,
            solution: [SolutionMedia(type: .text, textContent: "The closure can be executed after the function it was passed into has finished.")]
        )

        let protocols = Topic(
            title: "Protocols",
            question: "What is Protocol-Oriented Programming?",
            quickHint: "Behavior blueprints",
            difficulty: .medium,
            solution: [SolutionMedia(type: .text, textContent: "Defining blueprints for behavior and providing default logic via extensions.")]
        )

        swiftFundamentals.topics = [valueVsRef, optionals, closures, protocols]
        modelContext.insert(swiftFundamentals)

        let mentalModels = Concept(title: "Mental Models", isCustom: false)
        
        let dunningKruger = Topic(
            title: "Dunning-Kruger Effect",
            question: "Explain the Dunning-Kruger effect.",
            quickHint: "Overestimating ability",
            difficulty: .easy,
            solution: [SolutionMedia(type: .text, textContent: "A bias where people with limited competence overestimate their abilities.")]
        )
        
        let pareto = Topic(
            title: "Pareto Principle",
            question: "What is the Pareto Principle?",
            quickHint: "80/20 rule",
            difficulty: .medium,
            solution: [SolutionMedia(type: .text, textContent: "States that roughly 80% of consequences come from 20% of the causes.")]
        )
        
        mentalModels.topics = [dunningKruger, pareto]
        modelContext.insert(mentalModels)

        try? modelContext.save()
    }
}
