 
import SwiftUI
import SwiftData
import Charts



private struct TopicBar: Identifiable {
    let id: UUID
    let name: String
    let confidence: Int
    let score: Int
    var gap: Int { confidence - score }
    var isHighGap: Bool { abs(gap) > 20 }
}

private struct AttemptPoint: Identifiable {
    let id: UUID
    let date: Date
    let confidence: Int
    let score: Int
    var gap: Int { confidence - score }
}

private enum DateRange: String, CaseIterable {
    case week  = "7D"
    case month = "30D"
    case all   = "All"

    func startDate() -> Date? {
        switch self {
        case .week:  return Calendar.current.date(byAdding: .day, value: -7,  to: .now)
        case .month: return Calendar.current.date(byAdding: .day, value: -30, to: .now)
        case .all:   return nil
        }
    }
}

struct HeroInsightCard: View {
    let recentAttempts: [Attempt]
    @Query private var allTopics: [Topic]

    @State private var isExpanded:   Bool      = false
    @State private var animateBars:  Bool      = false
    @State private var glowPulse:    Bool      = false
    @State private var selectedRange: DateRange = .week
    @State private var chartMode:    ChartMode = .bars

    enum ChartMode { case bars, line }

    private var filteredAttempts: [Attempt] {
        guard let start = selectedRange.startDate() else { return recentAttempts }
        return recentAttempts.filter { $0.date >= start }
    }

    private var attemptPoints: [AttemptPoint] {
        filteredAttempts.map {
            AttemptPoint(id: $0.id, date: $0.date,
                         confidence: $0.confidenceLevel, score: $0.actualAccuracy)
        }
    }

    private var topicBars: [TopicBar] {
        var seen   = Set<UUID>()
        var result = [TopicBar]()
        for attempt in filteredAttempts {
            guard !seen.contains(attempt.topicID) else { continue }
            seen.insert(attempt.topicID)
            let name = allTopics.first(where: { $0.id == attempt.topicID })?.title ?? "Topic"
            result.append(TopicBar(id: attempt.topicID, name: name,
                                   confidence: attempt.confidenceLevel,
                                   score: attempt.actualAccuracy))
        }
        return result
    }

    private var worstTopic: TopicBar? {
        topicBars.max(by: { abs($0.gap) < abs($1.gap) })
    }

    private var avgGap: Int {
        guard !filteredAttempts.isEmpty else { return 0 }
        return filteredAttempts.map { $0.calibrationGap }.reduce(0, +) / filteredAttempts.count
    }

    private var statusColor: Color {
        if filteredAttempts.isEmpty { return .white.opacity(0.5) }
        let gap = avgGap
        if abs(gap) <= 10 { return .green }
        if gap < -10 { return .blue }
        return .orange
    }

    private var statusLabel: String {
        if recentAttempts.isEmpty  { return "Start Testing" }
        if filteredAttempts.isEmpty { return "No Data" }
        let gap = avgGap
        if abs(gap) <= 10 { return "Well Calibrated" }
        if gap < -10 { return "Underconfident" }
        return "Overconfident"
    }
    
    
    private var statusMessage: String {
        if recentAttempts.isEmpty  { return "Take your first test to unlock insights." }
        if filteredAttempts.isEmpty { return "No attempts recorded in this period." }
        let gap = avgGap
        if abs(gap) <= 10 { return "Your confidence perfectly matches your actual knowledge." }
        if gap < -10 { return "You know more than you think. Trust your memory!" }
        return "You're overestimating your recall. Time to review."
    }

    private var statusIcon: String {
        if recentAttempts.isEmpty  { return "brain" }
        if filteredAttempts.isEmpty { return "calendar.badge.exclamationmark" }
        let gap = avgGap
        if abs(gap) <= 10 { return "checkmark.circle.fill" }
        if gap < -10 { return "arrow.down.circle.fill" }
        return "arrow.up.circle.fill"
    }


    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            
            Button {
                if !recentAttempts.isEmpty {
                    toggleExpansion()
                }
            } label: {
                collapsedHeader
            }
            .buttonStyle(.plain)
            .padding(24)
            .accessibilityLabel("Calibration Insight: \(statusLabel)")
            .accessibilityHint(recentAttempts.isEmpty ? "" : "Double tap to \(isExpanded ? "collapse" : "expand") chart details")
            .accessibilityValue(statusMessage)

            if isExpanded && !recentAttempts.isEmpty {
                Divider().overlay(Color.white.opacity(0.08))

                controlsRow
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                if filteredAttempts.isEmpty {
                    emptyFilterState
                } else {
                    Group {
                        if chartMode == .bars {
                            barChartSection
                        } else {
                            lineChartSection
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                    if let worst = worstTopic, worst.isHighGap {
                        worstTopicCallout(worst)
                            .padding(.horizontal, 24)
                            .padding(.top, 12)
                    }
                }

                Spacer().frame(height: 24)
            }
        }
        .frame(maxWidth: .infinity)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(cardBorder)
        .shadow(color: statusColor.opacity(glowPulse ? 0.22 : 0.08), radius: 24, x: 0, y: 8)
        .animation(.spring(response: 0.45, dampingFraction: 0.78), value: isExpanded)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }
    
    private func toggleExpansion() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
            isExpanded.toggle()
            if isExpanded {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                        animateBars = true
                    }
                }
            } else {
                animateBars = false
            }
        }
        HapticManager.shared.impact(style: .light)
    }

    private var collapsedHeader: some View {
        HStack(alignment: .top, spacing: 16) {

            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 56, height: 56)
                Image(systemName: statusIcon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(statusColor)
                    .shadow(color: statusColor.opacity(0.6), radius: 8)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("CALIBRATION INSIGHT")
                    .font(.caption2.weight(.black))
                    .foregroundColor(.white.opacity(0.7))
                    .kerning(0.8)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(statusLabel)
                        .font(.title3.weight(.heavy))
                        .foregroundColor(statusColor)

                    if !recentAttempts.isEmpty && !filteredAttempts.isEmpty {
                        Text("(\(avgGap > 0 ? "+" : "")\(avgGap)%)")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(statusColor.opacity(0.7))
                    }
                }
                Text(statusMessage)
                    .font(.footnote.weight(.medium))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            if !recentAttempts.isEmpty {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 34, height: 34)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private var controlsRow: some View {
        HStack(spacing: 10) {

            HStack(spacing: 6) {
                ForEach(DateRange.allCases, id: \.self) { range in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedRange = range
                            animateBars = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    animateBars = true
                                }
                            }
                        }
                        HapticManager.shared.selection()
                    } label: {
                        Text(range.rawValue)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(selectedRange == range ? .black : .white.opacity(0.5))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(selectedRange == range ? Color.cyan : Color.white.opacity(0.08))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()

           
            HStack(spacing: 0) {
                chartToggleButton(icon: "chart.bar.fill",    mode: .bars)
                chartToggleButton(icon: "waveform.path.ecg", mode: .line)
            }
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private func chartToggleButton(icon: String, mode: ChartMode) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) { chartMode = mode }
            HapticManager.shared.selection()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(chartMode == mode ? .cyan : .white.opacity(0.35))
                .frame(width: 34, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(chartMode == mode ? Color.cyan.opacity(0.15) : .clear)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(mode == .bars ? "Bar chart" : "Line chart")
        .accessibilityAddTraits(chartMode == mode ? .isSelected : [])
    }


    private var emptyFilterState: some View {
        VStack(spacing: 10) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 28))
                .foregroundColor(.white.opacity(0.2))
            Text("No attempts in this period")
                .font(.system(.caption, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }


    private var barChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            legendRow

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 10) {
                    ForEach(topicBars) { bar in
                        topicBarGroup(bar: bar)
                            .frame(width: 54)
                    }
                }
                .frame(height: 120)
                .padding(.horizontal, 4)
            }
        }
    }

    private var legendRow: some View {
        HStack(spacing: 14) {
            legendDot(color: .cyan,   label: "Confidence")
            legendDot(color: .purple, label: "Score")
            Spacer()
        }
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white.opacity(0.45))
        }
    }

    private func topicBarGroup(bar: TopicBar) -> some View {
        let isWorst = bar.id == worstTopic?.id && bar.isHighGap

        return VStack(spacing: 5) {
            HStack(alignment: .bottom, spacing: 3) {
                barPill(value: bar.confidence, color: .cyan,   isHighlighted: isWorst)
                barPill(value: bar.score,      color: .purple, isHighlighted: isWorst)
            }
            Text(shortName(bar.name))
                .font(.system(size: 9, weight: isWorst ? .black : .medium))
                .foregroundColor(isWorst ? .orange : .white.opacity(0.4))
                .lineLimit(1)
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
    }

    private func barPill(value: Int, color: Color, isHighlighted: Bool) -> some View {
        let maxH: CGFloat = 90
        let targetH = animateBars ? max(5, CGFloat(value) / 100.0 * maxH) : 5

        return RoundedRectangle(cornerRadius: 5, style: .continuous)
            .fill(
                isHighlighted
                    ? LinearGradient(colors: [.orange, color], startPoint: .top, endPoint: .bottom)
                    : LinearGradient(colors: [color.opacity(0.9), color.opacity(0.45)], startPoint: .top, endPoint: .bottom)
            )
            .frame(width: 12, height: targetH)
            .overlay(
                isHighlighted
                    ? RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .stroke(Color.orange.opacity(0.45), lineWidth: 1)
                    : nil
            )
            .animation(.spring(response: 0.65, dampingFraction: 0.75), value: animateBars)
    }


    private var lineChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            legendRow

            Chart {
               
                RuleMark(y: .value("Equal", 0))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                    .foregroundStyle(Color.white.opacity(0.15))

                ForEach(attemptPoints) { point in
                    
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Confidence", point.confidence),
                        series: .value("Type", "Confidence")
                    )
                    .foregroundStyle(Color.cyan)
                    .interpolationMethod(.monotone)

                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Confidence", point.confidence)
                    )
                    .foregroundStyle(Color.cyan)
                    .symbolSize(40)

                   
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Score", point.score),
                        series: .value("Type", "Score")
                    )
                    .foregroundStyle(Color.purple)
                    .interpolationMethod(.monotone)

                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Score", point.score)
                    )
                    .foregroundStyle(Color.purple)
                    .symbolSize(40)
                }
            }
            .chartYScale(domain: 0...100)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: selectedRange == .week ? 2 : 7)) {
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                        .foregroundStyle(Color.white.opacity(0.35))
                }
            }
            .chartYAxis {
                AxisMarks(values: [0, 50, 100]) {
                    AxisGridLine().foregroundStyle(Color.white.opacity(0.06))
                    AxisValueLabel()
                        .foregroundStyle(Color.white.opacity(0.3))
                }
            }
            .frame(height: 120)
            .chartBackground { _ in Color.clear }
        }
    }


    private func worstTopicCallout(_ bar: TopicBar) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(bar.name) — highest gap")
                    .font(.system(.caption, weight: .bold))
                    .foregroundColor(.orange)
                Text("You were \(abs(bar.gap))% \(bar.gap > 0 ? "overconfident" : "underconfident") here.")
                    .font(.system(.caption2, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            Text("\(bar.gap > 0 ? "+" : "")\(bar.gap)%")
                .font(Font.system(.caption, design: .rounded, weight: .black))
                .foregroundColor(.orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.15))
                .clipShape(Capsule())
        }
        .padding(12)
        .background(Color.orange.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }


    private var cardBackground: some View {
        ZStack {
            Color(red: 0.07, green: 0.07, blue: 0.12)
            RadialGradient(
                colors: [statusColor.opacity(0.12), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 180
            )
        }
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [statusColor.opacity(0.35), Color.white.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }


    private func shortName(_ name: String) -> String {
        let words = name.split(separator: " ")
        if let first = words.first, first.count <= 8 { return String(first) }
        return String(name.prefix(7))
    }
}
