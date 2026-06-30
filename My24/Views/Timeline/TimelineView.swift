import SwiftUI
import SwiftData

// MARK: - Timeline View

struct TimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedDate: Date = Date()
    @State private var allLogs: [TimeLog] = []
    @State private var categories: [Category] = []
    @State private var selectedLog: TimeLog? = nil
    @State private var showAddSheet = false
    
    private var todayLogs: [TimeLog] {
        allLogs
            .filter { $0.startDate.isSameDay(as: selectedDate) }
            .sorted { $0.startDate < $1.startDate }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DashboardHeader(subtitle: "Visual day planner")
                    .padding(.top, 4)
                
                // Date scroll
                dateScrollBar
                    .padding(.vertical, 12)
                
                Divider()
                    .background(AppTheme.blushBorder)
                
                // Timeline
                ScrollView {
                    TimelineGridView(
                        logs: todayLogs,
                        categories: categories,
                        onTap: { log in selectedLog = log }
                    )
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    Spacer(minLength: 60)
                }
                .background(AppTheme.cream)
            }
            .background(AppTheme.cream)
            .navigationBarHidden(true)
            .sheet(item: $selectedLog) { log in
                EditLogSheet(log: log)
                    .onDisappear { refreshLogs() }
            }
            .sheet(isPresented: $showAddSheet) {
                LogTimeSheet(initialMode: .manual)
                    .onDisappear { refreshLogs() }
            }
            .overlay(alignment: .bottomTrailing) {
                Button(action: { showAddSheet = true }) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.deepRose)
                            .frame(width: 56, height: 56)
                            .shadow(color: AppTheme.deepRose.opacity(0.3), radius: 10, x: 0, y: 5)
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.trailing, 24)
                .padding(.bottom, 24)
            }
        }
        .onAppear { refreshLogs() }
    }
    
    // MARK: - Date Scroll Bar
    
    private var dateScrollBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(-3..<8, id: \.self) { offset in
                    let date = Calendar.current.date(byAdding: .day, value: offset, to: Date()) ?? Date()
                    DateScrollItem(date: date, isSelected: date.isSameDay(as: selectedDate)) {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedDate = date }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func refreshLogs() {
        let logDesc = FetchDescriptor<TimeLog>(sortBy: [SortDescriptor(\.startDate)])
        let catDesc = FetchDescriptor<Category>()
        allLogs    = (try? modelContext.fetch(logDesc)) ?? []
        categories = (try? modelContext.fetch(catDesc)) ?? []
    }
}

// MARK: - Date Scroll Item

struct DateScrollItem: View {
    let date: Date
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Text(date.formatted(as: "EEE"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSelected ? .white : AppTheme.mutedRose)
                
                Text(date.formatted(as: "d"))
                    .font(.system(size: 18, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? .white : AppTheme.deepRose)
            }
            .frame(width: 48, height: 64)
            .background(isSelected ? AppTheme.deepRose : AppTheme.blushLight)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: isSelected ? AppTheme.deepRose.opacity(0.3) : .clear, radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Timeline Grid View

struct TimelineGridView: View {
    let logs: [TimeLog]
    let categories: [Category]
    var onTap: (TimeLog) -> Void
    
    private let hourHeight: CGFloat = 64
    private let startHour: Int = 6
    private let endHour: Int = 24
    
    var body: some View {
        let totalHours = endHour - startHour
        let totalHeight = CGFloat(totalHours) * hourHeight
        
        ZStack(alignment: .topLeading) {
            // Hour grid
            VStack(spacing: 0) {
                ForEach(startHour..<endHour, id: \.self) { hour in
                    HourRow(hour: hour, height: hourHeight)
                }
            }
            
            // Current time indicator
            let currentHour = Calendar.current.component(.hour, from: Date())
            let currentMin  = Calendar.current.component(.minute, from: Date())
            if currentHour >= startHour && currentHour < endHour {
                let offset = CGFloat(currentHour - startHour) * hourHeight + CGFloat(currentMin) / 60.0 * hourHeight
                HStack(spacing: 0) {
                    Circle()
                        .fill(AppTheme.deepRose)
                        .frame(width: 10, height: 10)
                        .offset(x: 44)
                    Rectangle()
                        .fill(AppTheme.deepRose)
                        .frame(height: 1.5)
                        .opacity(0.6)
                }
                .offset(y: offset - 0.75)
            }
            
            // Log blocks
            ForEach(logs) { log in
                if let block = blockGeometry(for: log, totalHeight: totalHeight) {
                    TimelineBlock(
                        log: log,
                        category: categories.first { $0.id == log.categoryID },
                        height: block.height
                    )
                    .offset(x: 56, y: block.yOffset)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onTapGesture { onTap(log) }
                }
            }
        }
        .frame(minHeight: totalHeight)
        .padding(.bottom, 40)
    }
    
    private func blockGeometry(for log: TimeLog, totalHeight: CGFloat) -> (yOffset: CGFloat, height: CGFloat)? {
        let logStart = Calendar.current.component(.hour, from: log.startDate) * 60 + Calendar.current.component(.minute, from: log.startDate)
        let logEnd   = Calendar.current.component(.hour, from: log.endDate) * 60 + Calendar.current.component(.minute, from: log.endDate)
        
        let startMinutes = logStart - startHour * 60
        guard startMinutes >= 0 else { return nil }
        
        let yOffset = CGFloat(startMinutes) / 60.0 * hourHeight
        let duration = max(CGFloat(logEnd - logStart), 15) // minimum 15 min display
        let height = duration / 60.0 * hourHeight
        
        return (yOffset, max(height, 32))
    }
}

// MARK: - Hour Row

struct HourRow: View {
    let hour: Int
    let height: CGFloat
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(hourLabel)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppTheme.textTertiary)
                .frame(width: 44, alignment: .trailing)
                .offset(y: -8)
            
            Rectangle()
                .fill(AppTheme.blushBorder.opacity(0.5))
                .frame(height: 0.5)
                .frame(maxWidth: .infinity)
        }
        .frame(height: height)
    }
    
    var hourLabel: String {
        if hour == 0 { return "12 AM" }
        if hour < 12 { return "\(hour) AM" }
        if hour == 12 { return "12 PM" }
        return "\(hour - 12) PM"
    }
}

// MARK: - Timeline Block

struct TimelineBlock: View {
    let log: TimeLog
    let category: Category?
    let height: CGFloat
    
    var body: some View {
        HStack(spacing: 8) {
            // Color bar
            RoundedRectangle(cornerRadius: 3)
                .fill(category?.color ?? AppTheme.blushPink)
                .frame(width: 4)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(category?.name ?? "Uncategorized")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.deepRose)
                    .lineLimit(1)
                
                if height > 40 {
                    Text(log.duration.formattedDuration)
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.mutedRose)
                    
                    if height > 56 && log.notes.isNotEmpty {
                        Text(log.notes)
                            .font(.system(size: 10))
                            .foregroundColor(AppTheme.textTertiary)
                            .lineLimit(1)
                    }
                }
                
                if height > 48 {
                    Text(Mood(rawValue: log.moodScore)?.emoji ?? "")
                        .font(.system(size: 12))
                }
            }
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .frame(height: max(height - 4, 28))
        .frame(maxWidth: .infinity)
        .background((category?.color ?? AppTheme.blushPink).opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke((category?.color ?? AppTheme.blushPink).opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    TimelineView()
        .modelContainer(PreviewData.container)
}
