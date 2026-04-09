
import SwiftUI
import SwiftData

enum TopicSortOption: String, CaseIterable {
    case recentAdded = "Recent Added"
    case optional    = "Optional"
    case custom      = "Custom"

    var icon: String {
        switch self {
        case .recentAdded: return "clock"
        case .optional:    return "book.pages.fill"
        case .custom:      return "person.badge.plus"
        }
    }
}


struct FeaturedTopicsSection: View {
    let allTopics: [Topic]
    @Query private var allConcepts: [Concept]

    @State private var sortOption: TopicSortOption = .recentAdded
    @State private var showingQuickCreate = false

    let cardGradients: [[Color]] = [
        [Color(red: 0.2, green: 0.6, blue: 1.0), Color(red: 0.1, green: 0.4, blue: 0.9)],
        [Color(red: 0.6, green: 0.2, blue: 0.8), Color(red: 0.4, green: 0.1, blue: 0.6)],
        [Color(red: 1.0, green: 0.5, blue: 0.2), Color(red: 0.9, green: 0.3, blue: 0.1)],
        [Color(red: 0.1, green: 0.8, blue: 0.6), Color(red: 0.0, green: 0.6, blue: 0.4)]
    ]
    let cardIcons: [String] = [
        "brain.head.profile", "waveform.path.ecg", "function", "bolt.fill"
    ]


    private var customTopics: [Topic] {
        allTopics.filter { conceptFor($0)?.isCustom == true }
    }
    private var optionalTopics: [Topic] {
        allTopics.filter { conceptFor($0)?.isCustom == false }
    }

    private var displayedTopics: [Topic] {
        let pool: [Topic]
        switch sortOption {
        case .recentAdded: pool = allTopics
        case .optional:    pool = optionalTopics
        case .custom:      pool = customTopics
        }
        return Array(pool.prefix(2))
    }

    private var totalCount: Int {
        switch sortOption {
        case .recentAdded: return allTopics.count
        case .optional:    return optionalTopics.count
        case .custom:      return customTopics.count
        }
    }


    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            HStack(alignment: .center) {
                Text("Suggested Topics")
                    .font(.system(.title3, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Menu {
                    ForEach(TopicSortOption.allCases, id: \.self) { option in
                        Button {
                            withAnimation(.spring(response: 0.35)) {
                                sortOption = option
                            }
                            HapticManager.shared.selection()
                        } label: {
                            Label(option.rawValue, systemImage: option.icon)
                        }
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: sortOption.icon)
                            .font(.system(size: 11, weight: .semibold))
                        Text(sortOption.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(.white.opacity(0.65))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
                }
                .menuStyle(.borderlessButton)
            }
            .padding(.horizontal)

            if displayedTopics.isEmpty {
                emptyState
            } else {
            
                VStack(spacing: 14) {
                    ForEach(Array(displayedTopics.enumerated()), id: \.element.id) { index, topic in
                        NavigationLink(destination: TestWizardView(topic: topic)) {
                            CategoryCardView(
                                topic: topic,
                                colors: cardGradients[index % cardGradients.count],
                                bgIcon: cardIcons[index % cardIcons.count],
                                isCustom: conceptFor(topic)?.isCustom == true
                            )
                        }
                        .buttonStyle(.plain)
                        .simultaneousGesture(TapGesture().onEnded {
                            HapticManager.shared.impact(style: .light)
                        })
                    }
                }
                .padding(.horizontal, 24)
                if totalCount > 3 {
                    NavigationLink(destination: AllSuggestedTopicsView(
                        allTopics: allTopics,
                        allConcepts: allConcepts,
                        initialSort: sortOption
                    )) {
                        HStack(spacing: 6) {
                            Text("View All \(totalCount) Topics")
                                .font(.system(size: 13, weight: .semibold))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(.cyan.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color.cyan.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.cyan.opacity(0.15), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 24)
                    .simultaneousGesture(TapGesture().onEnded {
                        HapticManager.shared.impact(style: .light)
                    })
                }
            }
        }
        .sheet(isPresented: $showingQuickCreate) {
            QuickCreateFlowView()
        }
    }

   

    private var emptyState: some View {
        VStack(spacing: 10) {

            
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: sortOption == .optional ? "book.pages.fill" : "lightbulb.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.cyan)
                    .padding(.top, 1)

                if sortOption == .optional {
                    Text("No optional topics available yet.")
                        .font(.system(.subheadline, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("\(Text("Create a concept").font(.system(.subheadline, weight: .bold)).foregroundColor(.white)) or \(Text("pick a concept from the Library").font(.system(.subheadline, weight: .bold)).foregroundColor(.cyan)) to create a custom topic.")
                        .font(.system(.subheadline, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(4)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color.cyan.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.cyan.opacity(0.18), lineWidth: 1)
            )
            .padding(.horizontal, 24)

            if sortOption == .custom || sortOption == .recentAdded {
                Button {
                    showingQuickCreate = true
                    HapticManager.shared.impact(style: .medium)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Create a Topic")
                            .font(.system(.subheadline, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.cyan)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: Color.cyan.opacity(0.35), radius: 10, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
            }
        }
    }

    private var emptyTitle: String {
        switch sortOption {
        case .recentAdded: return "No Topics Yet"
        case .optional:    return "No Optional Topics"
        case .custom:      return "No Custom Topics"
        }
    }

    private var emptySubtitle: String {
        switch sortOption {
        case .recentAdded: return "Create a concept and add topics\nto start testing your knowledge."
        case .optional:    return "Optional curriculum topics will\nappear here once added."
        case .custom:      return "Tap below to create your first\nconcept and add a topic to it."
        }
    }

    private func conceptFor(_ topic: Topic) -> Concept? {
        allConcepts.first { $0.topics.contains(where: { $0.id == topic.id }) }
    }
}


struct AllSuggestedTopicsView: View {
    let allTopics: [Topic]
    let allConcepts: [Concept]
    let initialSort: TopicSortOption

    @State private var sortOption: TopicSortOption = .recentAdded

    let cardGradients: [[Color]] = [
        [Color(red: 0.2, green: 0.6, blue: 1.0), Color(red: 0.1, green: 0.4, blue: 0.9)],
        [Color(red: 0.6, green: 0.2, blue: 0.8), Color(red: 0.4, green: 0.1, blue: 0.6)],
        [Color(red: 1.0, green: 0.5, blue: 0.2), Color(red: 0.9, green: 0.3, blue: 0.1)],
        [Color(red: 0.1, green: 0.8, blue: 0.6), Color(red: 0.0, green: 0.6, blue: 0.4)]
    ]
    let cardIcons: [String] = ["brain.head.profile", "waveform.path.ecg", "function", "bolt.fill"]

    private var customTopics:   [Topic] { allTopics.filter { conceptFor($0)?.isCustom == true } }
    private var optionalTopics: [Topic] { allTopics.filter { conceptFor($0)?.isCustom == false } }

    private var displayedTopics: [Topic] {
        switch sortOption {
        case .recentAdded: return allTopics
        case .optional:    return optionalTopics
        case .custom:      return customTopics
        }
    }

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.04, blue: 0.07).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {

                    
                    HStack {
                        Text("\(displayedTopics.count) topic\(displayedTopics.count == 1 ? "" : "s")")
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(.white.opacity(0.3))
                            .kerning(0.5)
                        Spacer()
                        Menu {
                            ForEach(TopicSortOption.allCases, id: \.self) { option in
                                Button {
                                    withAnimation(.spring(response: 0.3)) { sortOption = option }
                                    HapticManager.shared.selection()
                                } label: {
                                    Label(option.rawValue, systemImage: option.icon)
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: sortOption.icon)
                                    .font(.system(size: 11, weight: .semibold))
                                Text(sortOption.rawValue)
                                    .font(.system(size: 12, weight: .semibold))
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Color.white.opacity(0.07))
                            .clipShape(Capsule())
                        }
                        .menuStyle(.borderlessButton)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                    if displayedTopics.isEmpty {
                        VStack(spacing: 14) {
                            Image(systemName: "tray")
                                .font(.system(size: 32, weight: .light))
                                .foregroundColor(.white.opacity(0.15))
                            Text("No topics in this category.")
                                .font(.system(.subheadline, weight: .medium))
                                .foregroundColor(.white.opacity(0.3))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    } else {
                        LazyVStack(spacing: 14) {
                            ForEach(Array(displayedTopics.enumerated()), id: \.element.id) { index, topic in
                                NavigationLink(destination: TestWizardView(topic: topic)) {
                                    CategoryCardView(
                                        topic: topic,
                                        colors: cardGradients[index % cardGradients.count],
                                        bgIcon: cardIcons[index % cardIcons.count],
                                        isCustom: conceptFor(topic)?.isCustom == true
                                    )
                                }
                                .buttonStyle(.plain)
                                .simultaneousGesture(TapGesture().onEnded {
                                    HapticManager.shared.impact(style: .light)
                                })
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .navigationTitle("All Topics")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { sortOption = initialSort }
    }

    private func conceptFor(_ topic: Topic) -> Concept? {
        allConcepts.first { $0.topics.contains(where: { $0.id == topic.id }) }
    }
}


struct CategoryCardView: View {
    let topic: Topic
    let colors: [Color]
    let bgIcon: String
    let isCustom: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack {
                Spacer()
                LinearGradient(colors: [.clear, .black.opacity(0.28)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 80)
            }
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: bgIcon)
                        .font(.system(size: 85, weight: .bold))
                        .foregroundColor(.white.opacity(0.12))
                        .rotationEffect(.degrees(-15))
                        .offset(x: 15, y: 25)
                }
            }
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(topic.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    Text(topic.quickHint)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.75))
                        .lineLimit(1)
                }
                Spacer()
                HStack(alignment: .center) {
                    HStack(spacing: 4) {
                        Circle().fill(topic.difficulty.color).frame(width: 5, height: 5)
                        Text(topic.difficultyRaw.capitalized)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(topic.difficulty.color)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 5) {
                        HStack(spacing: 3) {
                            Image(systemName: isCustom ? "person.badge.plus" : "book.pages.fill")
                                .font(.system(size: 7, weight: .black))
                            Text(isCustom ? "CUSTOM" : "OPTIONAL")
                                .font(.system(size: 8, weight: .black))
                                .kerning(0.5)
                        }
                        .foregroundColor(isCustom ? .purple : .cyan)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background((isCustom ? Color.purple : Color.cyan).opacity(0.18))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke((isCustom ? Color.purple : Color.cyan).opacity(0.3), lineWidth: 1))
                        
                        HStack(spacing: 4) {
                            Text("Start")
                                .font(.system(size: 12, weight: .bold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.35), lineWidth: 1))
                    }
                }
            }
            .padding(16)
        }
        .frame(height: 145) 
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: colors.first!.opacity(0.40), radius: 12, x: 0, y: 6)
    }
}
