
import SwiftUI
import SwiftData

struct BookmarkedTopicsSection: View {
    @Query(filter: #Predicate<Topic> { $0.isBookmarked == true },
           sort: \Topic.title)
    private var bookmarkedTopics: [Topic]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            HStack(alignment: .center) {
                Text("Bookmarked")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Spacer()

                if !bookmarkedTopics.isEmpty {
                    NavigationLink(destination: BookmarkedTopicsView()) {
                        HStack(spacing: 4) {
                            Text("View All")
                                .font(.caption)
                                .fontWeight(.semibold)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.yellow.opacity(0.85))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.yellow.opacity(0.08))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.yellow.opacity(0.15), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .simultaneousGesture(TapGesture().onEnded {
                        HapticManager.shared.impact(style: .light)
                    })
                }
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    if bookmarkedTopics.isEmpty {
                        NavigationLink(destination: LibraryView()) {
                            BookmarkedEmptyCard()
                        }
                        .buttonStyle(.plain)
                        .simultaneousGesture(TapGesture().onEnded {
                            HapticManager.shared.impact(style: .light)
                        })
                    } else {
                        ForEach(bookmarkedTopics.prefix(10)) { topic in
                            NavigationLink(destination: TestWizardView(topic: topic)) {
                                BookmarkedTopicCard(topic: topic)
                            }
                            .buttonStyle(.plain)
                            .simultaneousGesture(TapGesture().onEnded {
                                HapticManager.shared.impact(style: .light)
                            })
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
            }
        }
    }
}


struct BookmarkedEmptyCard: View {
    var body: some View {
        VStack(alignment: .center, spacing: 10) {

            Spacer()
            ZStack {
                Circle()
                    .stroke(Color.yellow.opacity(0.2), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                    .frame(width: 44, height: 44)
                Image(systemName: "bookmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.yellow.opacity(0.45))
            }

            VStack(spacing: 4) {
                Text("No bookmarks yet")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.55))

                Text("Tap to browse\nthe Library")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.25))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }

            Spacer()
        }
        .frame(width: 155, height: 145)
        .background(
            ZStack {
                Color(red: 0.08, green: 0.08, blue: 0.12)
                LinearGradient(
                    colors: [Color.yellow.opacity(0.05), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.yellow.opacity(0.18), Color.yellow.opacity(0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}


struct BookmarkedTopicCard: View {
    let topic: Topic

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            HStack(alignment: .top) {
                ZStack {
                    Circle()
                        .fill(topic.difficulty.color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(topic.difficulty.color)
                }

                Spacer()

                Image(systemName: "bookmark.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.yellow)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            Spacer()

            VStack(alignment: .leading, spacing: 6) {
                Text(topic.title)
                    .font(.system(.subheadline, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 5) {
                    Circle()
                        .fill(topic.difficulty.color)
                        .frame(width: 5, height: 5)
                    Text(topic.difficultyRaw.capitalized)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(topic.difficulty.color)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(width: 155, height: 145)
        .background(
            ZStack {
                Color(red: 0.08, green: 0.08, blue: 0.12)
                LinearGradient(
                    colors: [Color.yellow.opacity(0.1), Color.yellow.opacity(0.02)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.yellow.opacity(0.35), Color.yellow.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.yellow.opacity(0.12), radius: 10, x: 0, y: 4)
    }
}

struct BookmarkedTopicsView: View {
    @Query(filter: #Predicate<Topic> { $0.isBookmarked == true },
           sort: \Topic.title)
    private var bookmarkedTopics: [Topic]

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.04, blue: 0.07).ignoresSafeArea()

            RadialGradient(
                colors: [Color.yellow.opacity(0.07), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 380
            )
            .ignoresSafeArea()

            if bookmarkedTopics.isEmpty {
                emptyState
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {

                    
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(bookmarkedTopics.count) SAVED TOPIC\(bookmarkedTopics.count == 1 ? "" : "S")")
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(.yellow.opacity(0.6))
                                .kerning(0.8)
                            Text("Tap any card to start a test session.")
                                .font(.system(.subheadline, weight: .medium))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                      
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(bookmarkedTopics) { topic in
                                NavigationLink(destination: TestWizardView(topic: topic)) {
                                    BookmarkedGridCard(topic: topic)
                                }
                                .buttonStyle(.plain)
                                .simultaneousGesture(TapGesture().onEnded {
                                    HapticManager.shared.impact(style: .light)
                                })
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .navigationTitle("Bookmarked")
        .navigationBarTitleDisplayMode(.large)
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.06))
                    .frame(width: 90, height: 90)
                Image(systemName: "bookmark.slash")
                    .font(.system(size: 34, weight: .light))
                    .foregroundColor(.white.opacity(0.2))
            }
            VStack(spacing: 8) {
                Text("Nothing Saved Yet")
                    .font(.system(.title3, weight: .bold))
                    .foregroundColor(.white)
                Text("Tap the bookmark icon on any topic\nin the Library to save it here.")
                    .font(.system(.subheadline, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 60)
    }
}


struct BookmarkedGridCard: View {
    let topic: Topic

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            
            HStack(alignment: .top) {
                ZStack {
                    Circle()
                        .fill(topic.difficulty.color.opacity(0.18))
                        .frame(width: 44, height: 44)
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(topic.difficulty.color)
                }

                Spacer()

            
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        topic.isBookmarked = false
                    }
                    HapticManager.shared.impact(style: .light)
                } label: {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.yellow)
                        .padding(7)
                        .background(Color.yellow.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(16)

            Spacer()

            VStack(alignment: .leading, spacing: 8) {
                Text(topic.title)
                    .font(.system(.subheadline, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 5) {
                    Circle()
                        .fill(topic.difficulty.color)
                        .frame(width: 5, height: 5)
                    Text(topic.difficultyRaw.capitalized)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(topic.difficulty.color)
                }

                HStack(spacing: 5) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 9, weight: .bold))
                    Text("Start Session")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(.white.opacity(0.35))
                .padding(.top, 2)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(height: 185)
        .background(
            ZStack {
                Color(red: 0.09, green: 0.09, blue: 0.13)
                
                RadialGradient(
                    colors: [topic.difficulty.color.opacity(0.12), .clear],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 120
                )
                LinearGradient(
                    colors: [Color.yellow.opacity(0.06), .clear],
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.yellow.opacity(0.3), topic.difficulty.color.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.yellow.opacity(0.1), radius: 10, x: 0, y: 4)
    }
}
