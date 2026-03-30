
import SwiftUI
import SwiftData

struct FirstTimeHomeContent: View {
    let allTopics: [Topic]
    @Query private var allConcepts: [Concept]
    @Query(filter: #Predicate<Topic> { $0.isBookmarked == true }) private var bookmarkedTopics: [Topic]

    @State private var showingQuickCreate = false
    @State private var heroAppeared       = false

    private var optionalTopics: [Topic] { allTopics.filter { conceptFor($0)?.isCustom == false } }
    private var customTopics:   [Topic] { allTopics.filter { conceptFor($0)?.isCustom == true  } }
    private var demoTopics:     [Topic] { Array(optionalTopics.prefix(3)) }

    var body: some View {
       
        VStack(alignment: .leading, spacing: 32) {
            welcomeHero
            if !demoTopics.isEmpty { quickDemoSection }
            createCustomSection
            bookmarkPromptSection
        }
        .sheet(isPresented: $showingQuickCreate) { QuickCreateFlowView() }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.85).delay(0.1)) {
                heroAppeared = true
            }
        }
    }


    private var welcomeHero: some View {
        VStack(alignment: .leading, spacing: 20) {

          
            ZStack(alignment: .topLeading) {

              
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(red: 0.08, green: 0.08, blue: 0.13))

                RadialGradient(
                    colors: [Color.cyan.opacity(0.13), .clear],
                    center: .topLeading, startRadius: 0, endRadius: 180
                )
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                Image(systemName: "brain.head.profile")
                    .font(.system(size: 110, weight: .black))
                    .foregroundColor(Color.cyan.opacity(0.05))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .offset(x: 22, y: 22)
                    .clipped()

             
                VStack(alignment: .leading, spacing: 24) {

                   
                    VStack(alignment: .leading, spacing: 12) {
                        
                       
                        HStack(spacing: 7) {
                            Image(systemName: "sparkle")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.cyan)
                            Text("WELCOME TO CLARITY")
                                .font(.caption.weight(.black).width(.expanded))
                                .foregroundColor(.cyan.opacity(0.85))
                                .kerning(1.2)
                        }

                      
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Know what\nyou actually know.")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .lineSpacing(2)

                            Text("Test recall. Rate confidence. Track the gap.")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.white.opacity(0.55))
                                .lineSpacing(3)
                        }
                    }

                    
                    Rectangle()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 1)

                    
                    VStack(alignment: .leading, spacing: 14) {
                        cardValueProp(icon: "play.circle",                     color: .cyan,
                                      title: "Test Your Metacognition",
                                      text:  "Try a demo. Predict your score before the AI grades you.")
                        cardValueProp(icon: "brain",                     color: .purple,
                                      title: "Create Your Topic",
                                      text:  "Tap '+' to start building your custom subjects.")
                        cardValueProp(icon: "chart.line.uptrend.xyaxis", color: Color(red: 0.3, green: 0.9, blue: 0.6),
                                      title: "Track Your Progress",
                                      text:  "Master active recall and watch your daily streak grow.")
                    }
                }
                .padding(24)
            }
            .padding(.horizontal)
            .opacity(heroAppeared ? 1 : 0)
            .offset(y: heroAppeared ? 0 : 18)
            .animation(.spring(response: 0.65).delay(0.15), value: heroAppeared)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.cyan.opacity(0.2), Color.white.opacity(0.04)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .padding(.horizontal)
            )
        }
    }

    private func cardValueProp(icon: String, color: Color, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle().fill(color.opacity(0.14)).frame(width: 34, height: 34)
                Image(systemName: icon).font(.body.weight(.semibold)).foregroundColor(color)
            }
            .padding(.top, 1)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.white)
                Text(text)
                    .font(.footnote.weight(.medium))
                    .foregroundColor(.white.opacity(0.45))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var quickDemoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text("QUICK DEMO")
                        .font(.title3.weight(.black))
                        .foregroundColor(.white.opacity(0.9)).kerning(1.0)
                }
                Text("Pick a topic and take your first test.")
                    .font(.callout.weight(.medium)).foregroundColor(.white.opacity(0.60))
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(Array(demoTopics.enumerated()), id: \.element.id) { index, topic in
                        NavigationLink(destination: TestWizardView(topic: topic)) {
                            DemoTopicCard(topic: topic, index: index)
                        }
                        .buttonStyle(.plain)
                        .simultaneousGesture(TapGesture().onEnded { HapticManager.shared.impact(style: .medium) })
                    }
                    if optionalTopics.count > 3 {
                        NavigationLink(destination: LibraryView()) {
                            moreTailCard(label: "+\(optionalTopics.count - 3)", sub: "More in\nLibrary")
                        }.buttonStyle(.plain)
                    }
                }
                .padding(.horizontal).padding(.vertical, 8)
            }
        }
    }


    private var createCustomSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text("BUILD YOUR OWN")
                        .font(.title3.weight(.black))
                        .foregroundColor(.white.opacity(0.9)).kerning(1.0)
                }
                Text("Add topics from your own study material.")
                    .font(.callout.weight(.medium)).foregroundColor(.white.opacity(0.60))
            }
            .padding(.horizontal)

            Button {
                showingQuickCreate = true
                HapticManager.shared.impact(style: .medium)
            } label: {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(LinearGradient(
                                colors: [Color(red: 0.5, green: 0.15, blue: 0.8), Color(red: 0.3, green: 0.05, blue: 0.55)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ))
                            .frame(width: 52, height: 52)
                        Image(systemName: "plus").font(.title2.weight(.bold)).foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Create a Concept & Topic")
                            .font(.headline.weight(.bold)).foregroundColor(.white.opacity(0.9))
                        Text("Name a subject, write a question,\nadd the model answer.")
                            .font(.caption.weight(.medium)).foregroundColor(.white.opacity(0.5)).lineSpacing(2)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.subheadline.weight(.semibold)).foregroundColor(.white.opacity(0.2))
                }
                .padding(16)
                .background(ZStack {
                    Color(red: 0.09, green: 0.09, blue: 0.13)
                    LinearGradient(colors: [Color.purple.opacity(0.12), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
                })
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.purple.opacity(0.25), lineWidth: 1))
                .shadow(color: Color.purple.opacity(0.15), radius: 12, x: 0, y: 5)
            }
            .buttonStyle(.plain).padding(.horizontal)

            if !customTopics.isEmpty {
                VStack(spacing: 10) {
                    ForEach(customTopics.prefix(2)) { topic in
                        NavigationLink(destination: TestWizardView(topic: topic)) {
                            compactTopicRow(topic, color: .purple)
                        }
                        .buttonStyle(.plain)
                        .simultaneousGesture(TapGesture().onEnded { HapticManager.shared.impact(style: .light) })
                    }
                }
                .padding(.horizontal)
            }
        }
    }


    private var bookmarkPromptSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Text("SAVE TOPICS").font(.title3.weight(.black)).foregroundColor(.white.opacity(0.9)).kerning(1.0)
            }
            .padding(.horizontal)

            if bookmarkedTopics.isEmpty {
                NavigationLink(destination: LibraryView()) {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.yellow.opacity(0.08)).frame(width: 52, height: 52)
                                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(LinearGradient(colors: [Color.yellow.opacity(0.4), Color.yellow.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
                            Image(systemName: "bookmark").font(.title2.weight(.semibold)).foregroundColor(.yellow.opacity(0.7))
                        }
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Bookmark a Topic").font(.headline.weight(.bold)).foregroundColor(.white)
                            Text("Tap the bookmark icon on any topic in the Library to\nhighlight or select the topic.")
                                .font(.caption.weight(.medium)).foregroundColor(.white.opacity(0.45)).lineSpacing(2)
                        }
                        Spacer()
                        VStack(spacing: 4) {
                            Image(systemName: "books.vertical.fill").font(.caption.weight(.semibold)).foregroundColor(.cyan)
                            Text("Library").font(.system(size: 10, weight: .bold)).foregroundColor(.cyan)
                        }
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(Color.cyan.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .padding(16)
                    .background(ZStack {
                        Color(red: 0.08, green: 0.08, blue: 0.12)
                        LinearGradient(colors: [Color.yellow.opacity(0.07), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
                    })
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.yellow.opacity(0.18), lineWidth: 1))
                }
                .buttonStyle(.plain).padding(.horizontal)
                .simultaneousGesture(TapGesture().onEnded { HapticManager.shared.impact(style: .light) })
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(bookmarkedTopics.prefix(3)) { topic in
                            NavigationLink(destination: TestWizardView(topic: topic)) { BookmarkedTopicCard(topic: topic) }
                                .buttonStyle(.plain)
                        }
                        if bookmarkedTopics.count > 3 {
                            NavigationLink(destination: BookmarkedTopicsView()) {
                                moreTailCard(label: "All", sub: "View All\nBookmarks")
                            }.buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal).padding(.vertical, 8)
                }
            }
        }
    }


    private func compactTopicRow(_ topic: Topic, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(topic.difficulty.color.opacity(0.12)).frame(width: 38, height: 38)
                Image(systemName: "brain.head.profile").font(.body.weight(.semibold)).foregroundColor(topic.difficulty.color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(topic.title).font(.subheadline.weight(.bold)).foregroundColor(.white).lineLimit(1)
                Text(topic.quickHint).font(.caption.weight(.medium)).foregroundColor(.white.opacity(0.4)).lineLimit(1)
            }
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "play.fill").font(.system(size: 10, weight: .bold))
                Text("Test").font(.caption.weight(.bold))
            }
            .foregroundColor(color).padding(.horizontal, 12).padding(.vertical, 6)
            .background(color.opacity(0.1)).clipShape(Capsule())
        }
        .padding(14)
        .background(Color(red: 0.09, green: 0.09, blue: 0.13))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(color.opacity(0.15), lineWidth: 1))
    }

    private func moreTailCard(label: String, sub: String) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Circle().fill(Color.white.opacity(0.06)).frame(width: 44, height: 44)
                Text(label).font(.caption.weight(.black).width(.condensed)).foregroundColor(.white.opacity(0.5))
            }
            Text(sub).font(.caption2.weight(.semibold)).foregroundColor(.white.opacity(0.35)).multilineTextAlignment(.center)
            Image(systemName: "arrow.right").font(.caption2.weight(.bold)).foregroundColor(.white.opacity(0.25))
        }
        .frame(width: 100, height: 170)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.white.opacity(0.07), lineWidth: 1))
    }

    private func conceptFor(_ topic: Topic) -> Concept? {
        allConcepts.first { $0.topics.contains(where: { $0.id == topic.id }) }
    }
}


struct DemoTopicCard: View {
    let topic: Topic
    let index: Int

    private let gradients: [[Color]] = [
        [Color(red: 0.1, green: 0.5,  blue: 0.9),  Color(red: 0.05, green: 0.3,  blue: 0.7)],
        [Color(red: 0.05, green: 0.65, blue: 0.55), Color(red: 0.0,  green: 0.45, blue: 0.4)],
        [Color(red: 0.5,  green: 0.2,  blue: 0.85), Color(red: 0.3,  green: 0.08, blue: 0.6)]
    ]

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: gradients[index % gradients.count], startPoint: .topLeading, endPoint: .bottomTrailing)
            LinearGradient(colors: [.clear, .black.opacity(0.4)], startPoint: .center, endPoint: .bottom)
            
            
            Image(systemName: "brain.head.profile")
                .font(.system(size: 90, weight: .black)).foregroundColor(.white.opacity(0.08))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                .offset(x: 20, y: 0)
            
            VStack(alignment: .leading, spacing: 10) {
                Spacer()
                Text(topic.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    
                    .padding(.trailing, 20)
                
                HStack(spacing: 6) {
                    HStack(spacing: 4) {
                        Circle().fill(topic.difficulty.color).frame(width: 5, height: 5)
                        Text(topic.difficultyRaw.capitalized).font(.system(size: 10, weight: .bold)).foregroundColor(topic.difficulty.color)
                    }
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color.black.opacity(0.25)).clipShape(Capsule())
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text("Start").font(.system(size: 10, weight: .bold))
                        Image(systemName: "arrow.right").font(.system(size: 9, weight: .bold))
                    }
                    .foregroundColor(.white).padding(.horizontal, 9).padding(.vertical, 4)
                    .background(Color.white.opacity(0.2)).clipShape(Capsule())
                }
            }
            .padding(16)
        }
        .frame(width: 220, height: 170)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: gradients[index % gradients.count].first!.opacity(0.5), radius: 12, x: 0, y: 5)
    }
}
