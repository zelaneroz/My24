import SwiftUI

// MARK: - Goal Progress Card

struct GoalProgressCard: View {
    let goal: Goal
    let category: Category?
    let progress: Double
    let completedHours: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                if let cat = category {
                    ZStack {
                        Circle()
                            .fill(cat.color.opacity(0.2))
                            .frame(width: 36, height: 36)
                        Image(systemName: cat.iconName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(cat.color)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.categoryName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.deepRose)
                    Text(GoalPeriod(rawValue: goal.targetPeriod)?.displayName ?? "")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.mutedRose)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(progressColor)
                    Text("\(String(format: "%.1f", completedHours)) / \(String(format: "%.0f", goal.targetHours))h")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.mutedRose)
                }
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(AppTheme.blushMid)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(progressColor)
                        .frame(width: geo.size.width * progress, height: 8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: progress)
                }
            }
            .frame(height: 8)
            
            HStack {
                Text("\(String(format: "%.1f", max(0, goal.targetHours - completedHours)))h remaining")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textTertiary)
                Spacer()
                if progress >= 1 {
                    Label("Goal met!", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppTheme.sage)
                }
            }
        }
        .themedCard()
    }
    
    var progressColor: Color {
        if progress >= 1 { return AppTheme.sage }
        if progress >= 0.7 { return AppTheme.goldCat }
        return AppTheme.blushPink
    }
}

// MARK: - Streak Card

struct StreakCard: View {
    let streak: Streak
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(AppTheme.blushMid)
                        .frame(width: 44, height: 44)
                    Image(systemName: "flame.fill")
                        .font(.system(size: 20))
                        .foregroundColor(streak.currentCount > 0 ? AppTheme.blushPink : AppTheme.textTertiary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(streak.categoryName.isEmpty ? "Daily Logging" : streak.categoryName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppTheme.deepRose)
                    Text("Streak")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.mutedRose)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(streak.currentCount)")
                            .font(.playfairBold(32))
                            .foregroundColor(AppTheme.deepRose)
                        Text("days")
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.mutedRose)
                    }
                    Text("Best: \(streak.longestCount)")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textTertiary)
                }
            }
        }
        .themedCard()
    }
}

// MARK: - Lifetime Stats Card

struct LifetimeStatCard: View {
    let label: String
    let value: String
    let icon: String
    var accent: Color = AppTheme.blushPink
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(accent)
                Spacer()
            }
            Text(value)
                .font(.playfairBold(22))
                .foregroundColor(AppTheme.deepRose)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(AppTheme.mutedRose)
        }
        .themedCard(padding: 14)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Summary Stat Card

struct SummaryStatCard: View {
    let label: String
    let value: String
    let icon: String
    var accent: Color = AppTheme.blushPink
    var isWide: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.15))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(accent)
            }
            Spacer(minLength: 0)
            Text(value)
                .font(.playfairBold(24))
                .foregroundColor(AppTheme.deepRose)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(AppTheme.mutedRose)
                .lineLimit(2)
        }
        .padding(14)
        .frame(maxWidth: isWide ? .infinity : nil, minHeight: 120)
        .background(AppTheme.blushLight)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .cardShadow()
    }
}

// MARK: - Log Entry Card (previous logs)

struct LogEntryCard: View {
    let log: TimeLog
    let category: Category?
    
    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill((category?.color ?? AppTheme.blushPink).opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: category?.iconName ?? "clock.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(category?.color ?? AppTheme.blushPink)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(category?.name ?? "Uncategorized")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.deepRose)
                
                HStack(spacing: 6) {
                    Text(log.startDate.timeString)
                    Text("→")
                    Text(log.endDate.timeString)
                }
                .font(.system(size: 12))
                .foregroundColor(AppTheme.mutedRose)
                
                if log.notes.isNotEmpty {
                    Text(log.notes)
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textTertiary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(log.duration.formattedDuration)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.deepRose)
                Text(Mood(rawValue: log.moodScore)?.emoji ?? "")
                    .font(.system(size: 16))
            }
        }
        .padding(14)
        .background(AppTheme.blushLight)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .cardShadow()
    }
}

// MARK: - Chart Card Wrapper

struct ChartCard<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.playfairBold(16))
                    .foregroundColor(AppTheme.deepRose)
                if let sub = subtitle {
                    Text(sub)
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.mutedRose)
                }
            }
            content()
        }
        .themedCard()
    }
}
