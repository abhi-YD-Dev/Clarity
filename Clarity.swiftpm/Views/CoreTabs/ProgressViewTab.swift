
import SwiftUI
import SwiftData
import Charts

struct ProgressViewTab: View {
    @Query(sort: \Attempt.date, order: .forward) private var allAttempts: [Attempt]
    @Query private var allTopics: [Topic]



    private var averageGap: Int {
        guard !allAttempts.isEmpty else { return 0 }
        return allAttempts.map { $0.calibrationGap }.reduce(0, +) / allAttempts.count
    }

    private var totalAttempts: Int { allAttempts.count }

    private var bestStreak: Int {
      
        var streak = 0, best = 0
        for attempt in allAttempts {
            if abs(attempt.calibrationGap) <= 10 { streak += 1; best = max(best, streak) }
            else { streak = 0 }
        }
        return best
    }

    private var dominantZone: TestZone {
        guard !allAttempts.isEmpty else { return .zoneOfClarity }
        let counts = allAttempts.reduce(into: [TestZone: Int]()) { $0[$1.zone, default: 0] += 1 }
        return counts.max(by: { $0.value < $1.value })?.key ?? .zoneOfClarity
    }

    private var recentAttempts: [Attempt] { Array(allAttempts.reversed()) }

    

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.04, green: 0.04, blue: 0.07).ignoresSafeArea()

       
                RadialGradient(
                    colors: [Color.cyan.opacity(0.06), .clear],
                    center: .top,
                    startRadius: 0,
                    endRadius: 400
                )
                .ignoresSafeArea()

                if allAttempts.isEmpty {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 0) {

                          
                            header
                                .padding(.horizontal, 24)
                                .padding(.top, 20)
                                .padding(.bottom, 28)

                            chartHero
                                .padding(.horizontal, 20)
                                .padding(.bottom, 28)

                       
                            statsRow
                                .padding(.horizontal, 20)
                                .padding(.bottom, 36)

                       
                            HStack {
                                Text("ATTEMPT HISTORY")
                                    .font(.system(size: 20, weight: .black))
                                    .foregroundColor(.white.opacity(0.9))
                                    .kerning(1.0)
                                Spacer()
                                Text("\(totalAttempts) total")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white.opacity(0.65))
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 16)

                   
                            LazyVStack(spacing: 12) {
                                ForEach(Array(recentAttempts.enumerated()), id: \.element.id) { index, attempt in
                                    AttemptTimelineCard(
                                        attempt: attempt,
                                        topic: allTopics.first(where: { $0.id == attempt.topicID }),
                                        isLast: index == recentAttempts.count - 1
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 120)
                        }
                    }
                }
            }
            .navigationTitle("Progress")
            .navigationBarHidden(true)
        }
    }


    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
           
            Text("Progress")
                .font(.system(size: 34, weight: .black))
                .foregroundColor(.white)
            Spacer()
            
            Text("CALIBRATION JOURNEY")
                .font(.system(size: 11, weight: .black))
                .foregroundColor(.cyan.opacity(0.7))
                .kerning(1.2)

            Text("Track how your self-awareness sharpens over time.")
                .font(.system(.subheadline, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
        }
    }


    private var chartHero: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("GAP OVER TIME")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.white.opacity(0.65))
                        .kerning(0.8)
                    Text("Closer to zero = better calibrated")
                        .font(.system(.caption, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                }
                Spacer()
                
                HStack(spacing: 10) {
                    zoneLegendDot(.green,  "Clarity")
                    zoneLegendDot(.orange, "Over")
                    zoneLegendDot(.blue,   "Under")
                }
            }
            
           
            GeometryReader { geometry in
                let chartWidth = max(geometry.size.width, CGFloat(recentAttempts.count) * 48)

                ScrollView(.horizontal, showsIndicators: false) {
                Chart {
                   
                    RectangleMark(
                        xStart: .value("Start", allAttempts.first?.date ?? .now),
                        xEnd:   .value("End",   allAttempts.last?.date  ?? .now),
                        yStart: .value("Low",  -10),
                        yEnd:   .value("High",  10)
                    )
                    .foregroundStyle(Color.green.opacity(0.06))
                    
                   
                    RuleMark(y: .value("Zero", 0))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6]))
                        .foregroundStyle(Color.green.opacity(0.5))
                    
                  
                    ForEach(allAttempts) { attempt in
                        AreaMark(
                            x: .value("Date", attempt.date),
                            y: .value("Gap",  attempt.calibrationGap)
                        )
                        .interpolationMethod(.monotone)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.cyan.opacity(0.25), Color.cyan.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                 
                    ForEach(allAttempts) { attempt in
                        LineMark(
                            x: .value("Date", attempt.date),
                            y: .value("Gap",  attempt.calibrationGap)
                        )
                        .interpolationMethod(.monotone)
                        .foregroundStyle(Color.cyan)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                    }
                   
                    ForEach(allAttempts) { attempt in
                        PointMark(
                            x: .value("Date", attempt.date),
                            y: .value("Gap",  attempt.calibrationGap)
                        )
                        .symbol {
                            chartDotSymbol(
                                isRecent: attempt.id == allAttempts.last?.id,
                                color: attempt.zone.color
                            )
                        }
                    }
                }
                
                .chartXScale(domain: .automatic(reversed: true))
                .chartYAxis {
                    AxisMarks(position: .leading, values: [-50, -25, 0, 25, 50]) {
                        AxisGridLine().foregroundStyle(Color.white.opacity(0.06))
                        AxisValueLabel()
                            .foregroundStyle(Color.white.opacity(0.3))
                            .font(.system(size: 10))
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: max(1, allAttempts.count / 6))) {
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            .foregroundStyle(Color.white.opacity(0.3))
                            .font(.system(size: 10))
                    }
                }
                .chartBackground { _ in Color.clear }
                .frame(width: chartWidth, height: 220)
            }
        }
        .frame(height: 220)
        }
        .padding(20)
        .background(
            ZStack {
                Color(red: 0.08, green: 0.08, blue: 0.13)
                RadialGradient(
                    colors: [Color.cyan.opacity(0.07), .clear],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 200
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.cyan.opacity(0.12), lineWidth: 1)
        )
    }

  
    @ViewBuilder
    private func chartDotSymbol(isRecent: Bool, color: Color) -> some View {
        ZStack {
            if isRecent {
                
                Circle()
                    .stroke(Color.white.opacity(0.95), lineWidth: 2)
                    .frame(width: 16, height: 16)
            }
            
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
        }
    }

    private func zoneLegendDot(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.white.opacity(0.65))
        }
    }

    

    private var statsRow: some View {
        HStack(spacing: 12) {
            statCard(
                value: "\(abs(averageGap))%",
                label: "AVG GAP",
                color: averageGap > 15 ? .orange : (averageGap < -15 ? .blue : .green),
                icon: "scope"
            )
            statCard(
                value: "\(totalAttempts)",
                label: "ATTEMPTS",
                color: .cyan,
                icon: "checkmark.circle"
            )
            statCard(
                value: "\(bestStreak)",
                label: "BEST STREAK",
                color: .purple,
                icon: "flame"
            )
        }
    }

    private func statCard(value: String, label: String, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 3) {
                Text(value)
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Text(label)
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(.white.opacity(0.3))
                    .kerning(0.6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            ZStack {
                Color(red: 0.08, green: 0.08, blue: 0.13)
                RadialGradient(
                    colors: [color.opacity(0.1), .clear],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 80
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }

 

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.cyan.opacity(0.06))
                    .frame(width: 100, height: 100)
                Image(systemName: "chart.xyaxis.line")
                    .font(.system(size: 38, weight: .light))
                    .foregroundColor(.white.opacity(0.2))
            }

            VStack(spacing: 8) {
                Text("No Data Yet")
                    .font(.system(.title2, weight: .bold))
                    .foregroundColor(.white)
                Text("Take a few tests to start tracking\nyour cognitive calibration over time.")
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



struct AttemptTimelineCard: View {
    let attempt: Attempt
    let topic: Topic?
    let isLast: Bool

    @State private var isExpanded = false

    private var gapColor: Color { attempt.zone.color }

    private var gapPrefix: String { attempt.calibrationGap > 0 ? "+" : "" }

    var body: some View {
        
        VStack(alignment: .leading, spacing: 0) {
            
            Button {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
                HapticManager.shared.impact(style: .light)
            } label: {
                collapsedRow
            }
            .buttonStyle(.plain)

            
            if isExpanded {
                expandedContent
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
       
        .padding(.bottom, isLast ? 0 : 8)
    }

   
    private var collapsedRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                   
                    Text(topic?.title ?? "Unknown Topic")
                        .font(.system(.subheadline, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    
                    Text(attempt.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.35))
                }

                Spacer()

               
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(gapPrefix)\(attempt.calibrationGap)%")
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundColor(gapColor)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.25))
                }
            }

            
            HStack(spacing: 8) {
                scoreChip(label: "Confidence", value: attempt.confidenceLevel, color: .cyan)
                scoreChip(label: "Score", value: attempt.actualAccuracy, color: .purple)

                Spacer()

               
                Text(attempt.zone.rawValue)
                    .font(.system(size: 9, weight: .black))
                    .kerning(0.4)
                    .foregroundColor(gapColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(gapColor.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .padding(16)
        .background(
            ZStack {
                Color(red: 0.09, green: 0.09, blue: 0.14)
                RadialGradient(
                    colors: [gapColor.opacity(0.08), .clear],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 120
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    isExpanded
                        ? gapColor.opacity(0.3)
                        : Color.white.opacity(0.07),
                    lineWidth: 1
                )
        )
    }

    private func scoreChip(label: String, value: Int, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white.opacity(0.35))
            Text("\(value)%")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundColor(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.08))
        .clipShape(Capsule())
    }

 

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 0) {

            
            Rectangle()
                .fill(gapColor.opacity(0.15))
                .frame(height: 1)
                .padding(.horizontal, 16)

            VStack(alignment: .leading, spacing: 20) {

               
                expandedSection(
                    icon: "square.and.pencil",
                    title: "YOUR ANSWER",
                    color: .cyan
                ) {
                    if !attempt.textAnswers.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(attempt.textAnswers.enumerated()), id: \.offset) { index, answer in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("\(index + 1).")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(.cyan.opacity(0.5))
                                    Text(answer)
                                        .font(.system(.subheadline, weight: .regular))
                                        .foregroundColor(.white.opacity(0.8))
                                        .lineSpacing(5)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    } else {
                        emptyFieldNote("No written answer recorded.")
                    }
                }

               
                expandedSection(
                    icon: "brain",
                    title: "REFLECTION",
                    color: .purple
                ) {
                    if !attempt.reflectionText.isEmpty {
                        Text(attempt.reflectionText)
                            .font(.system(.subheadline, weight: .regular))
                            .foregroundColor(.white.opacity(0.8))
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        emptyFieldNote("No reflection written.")
                    }
                }

               
                expandedSection(
                    icon: "scope",
                    title: "CALIBRATION BREAKDOWN",
                    color: gapColor
                ) {
                    HStack(spacing: 16) {
                        miniStat(label: "Confidence", value: "\(attempt.confidenceLevel)%", color: .cyan)
                        Text("→")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white.opacity(0.2))
                        miniStat(label: "Actual Score", value: "\(attempt.actualAccuracy)%", color: .purple)
                        Text("=")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white.opacity(0.2))
                        miniStat(
                            label: "Gap",
                            value: "\(gapPrefix)\(attempt.calibrationGap)%",
                            color: gapColor
                        )
                    }
                }
            }
            .padding(16)
        }
        .background(Color(red: 0.07, green: 0.07, blue: 0.11))
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 16,
                bottomTrailingRadius: 16,
                topTrailingRadius: 0
            )
        )
        .overlay(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 16,
                bottomTrailingRadius: 16,
                topTrailingRadius: 0
            )
            .stroke(gapColor.opacity(0.2), lineWidth: 1)
        )
    }

    private func expandedSection<Content: View>(
        icon: String,
        title: String,
        color: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(color.opacity(0.8))
                    .kerning(0.8)
            }
            content()
        }
    }

    private func emptyFieldNote(_ text: String) -> some View {
        Text(text)
            .font(Font.system(.caption, design: .monospaced, weight: .medium))
            .foregroundColor(.white.opacity(0.2))
            .italic()
    }

    private func miniStat(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white.opacity(0.3))
        }
    }
}

