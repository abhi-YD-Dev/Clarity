//
//  HomeView.swift
//  Clarity
//
//  Created by Abhinav Yadav on 20/02/26.
//


import SwiftUI
import SwiftData
import Charts

struct HomeView: View {
    @Query(sort: \Attempt.date, order: .reverse) private var allAttempts: [Attempt]
    @Query private var allTopics: [Topic]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {

                        greeting
                            .padding(.horizontal)
                            .padding(.top, 10)

                        if allAttempts.isEmpty {

                         
                            FirstTimeHomeContent(allTopics: allTopics)

                        } else {

                            

                            HeroInsightCard(recentAttempts: allAttempts)
                                .padding(.horizontal)

                            JumpBackInCarousel(attempts: allAttempts, topics: allTopics)

                            if !allTopics.isEmpty {
                                FeaturedTopicsSection(allTopics: allTopics)
                            }

                            BookmarkedTopicsSection()
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
        }
    }

  
    
    private var greeting: some View {
        VStack(alignment: .leading, spacing: 4) {

            Text(allAttempts.isEmpty ? "Clarity" : "Home")
                .font(.system(.largeTitle, weight: .heavy))
                .foregroundColor(.white)
                .animation(.easeInOut(duration: 0.3), value: allAttempts.isEmpty)
        }
    }
}



struct JumpBackInCarousel: View {
    let attempts: [Attempt]
    let topics: [Topic]

    private var recentUniqueTopics: [(topic: Topic, lastScore: Int)] {
        var uniqueIDs = Set<UUID>()
        var result: [(Topic, Int)] = []
        for attempt in attempts {
            if !uniqueIDs.contains(attempt.topicID) {
                uniqueIDs.insert(attempt.topicID)
                if let matched = topics.first(where: { $0.id == attempt.topicID }) {
                    result.append((matched, attempt.actualAccuracy))
                }
            }
            if result.count == 20 { break }
        }
        return result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Jump Back In")
                    .font(.system(.title3, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(recentUniqueTopics, id: \.topic.id) { item in
                        NavigationLink(destination: TestWizardView(topic: item.topic)) {
                            RecentTopicCard(topic: item.topic, lastScore: item.lastScore)
                        }
                        .buttonStyle(.plain)
                        .simultaneousGesture(TapGesture().onEnded {
                            HapticManager.shared.impact(style: .light)
                        })
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

