

import SwiftUI

struct RecentTopicCard: View {
    let topic: Topic
    let lastScore: Int

    private var scoreColor: Color {
        lastScore >= 80 ? .green : (lastScore >= 50 ? .orange : .red)
    }

    private var cardGradient: LinearGradient {
        LinearGradient(
            colors: [
                topic.difficulty.color.opacity(0.35),
                topic.difficulty.color.opacity(0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack(alignment: .top) {
                Image(systemName: "arrow.counterclockwise.circle.fill")
                    .font(.title)
                    .foregroundColor(topic.difficulty.color)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Last Score")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))
                    Text("\(lastScore)%")
                        .font(.system(.headline, weight: .heavy))
                        .foregroundColor(scoreColor)
                }
            }

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                Text(topic.title)
                    .font(.system(.subheadline, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(topic.difficultyRaw.capitalized)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(topic.difficulty.color)
            }
        }
        .frame(width: 160, height: 140)
        .padding(16)
        .background(
            ZStack {
                
                Color(red: 0.07, green: 0.07, blue: 0.12)
    
                cardGradient
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            topic.difficulty.color.opacity(0.4),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: topic.difficulty.color.opacity(0.2), radius: 12, x: 0, y: 6)
    }
}
