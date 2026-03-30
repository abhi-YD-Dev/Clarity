

import SwiftUI
import SwiftData


enum LibraryFilter: String, CaseIterable {
    case all      = "All"
    case official = "Optional"
    case custom   = "Custom"

    var icon: String {
        switch self {
        case .all:      return "square.grid.2x2"
        case .official: return "book.pages"
        case .custom:   return "person.crop.circle"
        }
    }
}

struct LibraryView: View {
    @Query(sort: \Concept.title) private var allConcepts: [Concept]
    @State private var filter: LibraryFilter = .all

    private var filteredConcepts: [Concept] {
        switch filter {
        case .all:      return allConcepts
        case .official: return allConcepts.filter { !$0.isCustom }
        case .custom:   return allConcepts.filter { $0.isCustom }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {

                    filterChips
                        .padding(.horizontal)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                        .background(Color.black)
                        .zIndex(1)

                    ScrollView(showsIndicators: false) {
                        if filteredConcepts.isEmpty {
                            EmptyLibraryState(filter: filter)
                                .padding(.top, 80)
                        } else {
                            LazyVStack(spacing: 14) {
                              
                                HStack {
                                    Text("\(filteredConcepts.count) CONCEPT\(filteredConcepts.count == 1 ? "" : "S")")
                                        .font(.system(size: 11, weight: .black))
                                        .foregroundColor(.white.opacity(0.3))
                                        .kerning(0.8)
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .padding(.top, 8)

                                ForEach(filteredConcepts) { concept in
                                    NavigationLink(destination: TopicListView(concept: concept)) {
                                        ConceptFolderCard(concept: concept)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 120)
                        }
                    }
                }
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: CreateConceptView()) {
                        ZStack {
                            Circle()
                                .fill(Color.cyan.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.cyan)
                        }
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        HapticManager.shared.impact(style: .medium)
                    })
                }
            }
        }
    }


    private var filterChips: some View {
        HStack(spacing: 8) {
            ForEach(LibraryFilter.allCases, id: \.self) { option in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        filter = option
                    }
                    HapticManager.shared.selection()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: option.icon)
                            .font(.system(size: 12, weight: .semibold))
                        Text(option.rawValue)
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(filter == option ? .black : .white.opacity(0.55))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(filter == option ? Color.cyan : Color.white.opacity(0.07))
                    )
                    .overlay(
                        Capsule()
                            .stroke(filter == option ? Color.clear : Color.white.opacity(0.1), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }
}


struct ConceptFolderCard: View {
    let concept: Concept
    private var accentColor: Color  { concept.isCustom ? .purple : .cyan }
    private var gradientColors: [Color] {
        concept.isCustom
            ? [Color(red: 0.5, green: 0.1, blue: 0.7), Color(red: 0.3, green: 0.05, blue: 0.45)]
            : [Color(red: 0.0, green: 0.6, blue: 0.8), Color(red: 0.0, green: 0.35, blue: 0.6)]
    }

    var body: some View {
        HStack(spacing: 0) {

            ZStack {
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 72)

                Image(systemName: concept.isCustom ? "person.badge.plus" : "book.pages.fill")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(.white.opacity(0.15))
                    .rotationEffect(.degrees(-10))
                    .offset(x: 8, y: 6)

                Image(systemName: concept.isCustom ? "person.badge.plus" : "book.pages.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 4)
            }
            .frame(width: 72, height: 76)
            .clipShape(
             
                UnevenRoundedRectangle(
                    topLeadingRadius: 18,
                    bottomLeadingRadius: 18,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 0
                )
            )


            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(concept.title)
                        .font(.system(.headline, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        
                        HStack(spacing: 4) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 10, weight: .semibold))
                            Text("\(concept.topics.count) topic\(concept.topics.count == 1 ? "" : "s")")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(accentColor.opacity(0.9))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(accentColor.opacity(0.12))
                        .clipShape(Capsule())

                    
                        if !concept.isCustom {
                            Text("OPTIONAL")
                                .font(.system(size: 9, weight: .black))
                                .kerning(0.5)
                                .foregroundColor(.cyan)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 4)
                                .background(Color.cyan.opacity(0.12))
                                .clipShape(Capsule())
                        } else {
                            HStack(spacing: 3) {
                                Image(systemName: "person.badge.plus")
                                    .font(.system(size: 8, weight: .black))
                                Text("CUSTOM")
                                    .font(.system(size: 9, weight: .black))
                                    .kerning(0.5)
                            }
                            .foregroundColor(.purple)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(Color.purple.opacity(0.12))
                            .clipShape(Capsule())
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white.opacity(0.25))
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 76)
            .background(Color(red: 0.09, green: 0.09, blue: 0.13))
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 18,
                    topTrailingRadius: 18
                )
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: accentColor.opacity(0.2), radius: 12, x: 0, y: 5)
    }
}

struct EmptyLibraryState: View {
    let filter: LibraryFilter

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
          
                Circle()
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    .frame(width: 100, height: 100)

                Circle()
                    .fill(Color.white.opacity(0.04))
                    .frame(width: 84, height: 84)

                Image(systemName: filter == .custom ? "person.crop.circle.badge.plus" : "folder.badge.questionmark")
                    .font(.system(size: 34, weight: .medium))
                    .foregroundColor(.white.opacity(0.3))
            }

            VStack(spacing: 8) {
                Text("Nothing Here Yet")
                    .font(.system(.title3, weight: .bold))
                    .foregroundColor(.white)

                Text(filter == .custom
                     ? "Tap + to create your first custom concept folder."
                     : "No concepts match this filter.")
                    .font(.system(.subheadline, weight: .medium))
                    .foregroundColor(.white.opacity(0.45))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity)
    }
}



struct TopicListView: View {
    let concept: Concept

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {

    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(concept.topics.count) TOPIC\(concept.topics.count == 1 ? "" : "S") AVAILABLE")
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(.white.opacity(0.35))
                            .kerning(0.8)

                        Text("Select a topic to test your recall.")
                            .font(.system(.subheadline, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)

                    LazyVStack(spacing: 12) {
                        ForEach(concept.topics) { topic in
                            NavigationLink {
                                TestWizardView(topic: topic)
                            } label: {
                                TopicRowCard(topic: topic)
                            }
                            .buttonStyle(.plain)
                            .simultaneousGesture(TapGesture().onEnded {
                                HapticManager.shared.impact(style: .light)
                            })
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationTitle(concept.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(destination: CreateTopicView(concept: concept)) {
                    ZStack {
                        Circle()
                            .fill(Color.purple.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.purple)
                    }
                }
                .simultaneousGesture(TapGesture().onEnded {
                    HapticManager.shared.impact(style: .medium)
                })
            }
        }
    }
}



struct TopicRowCard: View {
    let topic: Topic
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HStack(spacing: 0) {

            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(topic.difficulty.color)
                .frame(width: 4)
                .padding(.vertical, 14)
                .padding(.leading, 14)

            HStack(spacing: 14) {

           
                ZStack {
                    Circle()
                        .fill(topic.difficulty.color.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(topic.difficulty.color)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(topic.title)
                        .font(.system(.headline, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text(topic.quickHint)
                        .font(.system(.caption, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(1)

                    Text(topic.difficultyRaw.uppercased())
                        .font(.system(size: 9, weight: .black))
                        .kerning(0.5)
                        .foregroundColor(topic.difficulty.color)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(topic.difficulty.color.opacity(0.12))
                        .clipShape(Capsule())
                }

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        topic.isBookmarked.toggle()
                        HapticManager.shared.impact(style: .light)
                    }
                } label: {
                    Image(systemName: topic.isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(topic.isBookmarked ? .yellow : .white.opacity(0.25))
                        .scaleEffect(topic.isBookmarked ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: topic.isBookmarked)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 4)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white.opacity(0.2))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
        }
        .background(
            ZStack {
                Color(red: 0.09, green: 0.09, blue: 0.13)
                if topic.isBookmarked {
                    LinearGradient(
                        colors: [Color.yellow.opacity(0.06), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    topic.isBookmarked ? Color.yellow.opacity(0.25) : Color.white.opacity(0.07),
                    lineWidth: 1
                )
        )
        .shadow(color: topic.isBookmarked ? Color.yellow.opacity(0.12) : topic.difficulty.color.opacity(0.1), radius: 8, x: 0, y: 3)
        .animation(.easeInOut(duration: 0.2), value: topic.isBookmarked)
    }
}


