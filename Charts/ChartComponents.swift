import SwiftUI

// MARK: - Calendar Heatmap

struct CalendarHeatmap: View {
    let data: [HeatmapDay]
    var accentColor: Color = AppTheme.blushPink
    
    private let columns = Array(repeating: GridItem(.fixed(14), spacing: 3), count: 7)
    private let dayNames = ["S", "M", "T", "W", "T", "F", "S"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Day labels
            HStack(spacing: 0) {
                ForEach(dayNames, id: \.self) { name in
                    Text(name)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(AppTheme.mutedRose)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Grid
            LazyVGrid(columns: columns, spacing: 3) {
                ForEach(data.suffix(91)) { day in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(cellColor(for: day))
                        .frame(width: 14, height: 14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(day.date.isSameDay(as: Date()) ? AppTheme.deepRose : Color.clear, lineWidth: 1.5)
                        )
                        .help("\(day.date.shortDateString): \(String(format: "%.1f", day.hours))h")
                }
            }
            
            // Legend
            HStack(spacing: 6) {
                Text("Less")
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.mutedRose)
                
                ForEach([0.0, 0.25, 0.5, 0.75, 1.0], id: \.self) { intensity in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(accentColor.opacity(max(0.08, intensity)))
                        .frame(width: 12, height: 12)
                }
                
                Text("More")
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.mutedRose)
            }
        }
    }
    
    private func cellColor(for day: HeatmapDay) -> Color {
        if day.hours == 0 { return AppTheme.blushMid }
        return accentColor.opacity(max(0.15, day.intensity))
    }
}

// MARK: - Weekly Trend Line Chart

struct WeeklyTrendChart: View {
    let data: [TrendPoint]
    
    var body: some View {
        if data.isEmpty {
            Text("No data")
                .font(.system(size: 13))
                .foregroundColor(AppTheme.mutedRose)
                .frame(height: 80)
        } else {
            GeometryReader { geo in
                let max = data.map(\.value).max() ?? 1
                let points = data.enumerated().map { (i, point) in
                    CGPoint(
                        x: geo.size.width * CGFloat(i) / CGFloat(Swift.max(data.count - 1, 1)),
                        y: geo.size.height - (max > 0 ? geo.size.height * CGFloat(point.value / max) : 0)
                    )
                }
                
                ZStack {
                    // Fill area
                    if points.count > 1 {
                        Path { path in
                            path.move(to: CGPoint(x: points.first!.x, y: geo.size.height))
                            for pt in points { path.addLine(to: pt) }
                            path.addLine(to: CGPoint(x: points.last!.x, y: geo.size.height))
                            path.closeSubpath()
                        }
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.blushPink.opacity(0.3), AppTheme.blushPink.opacity(0.0)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        
                        // Line
                        Path { path in
                            path.move(to: points[0])
                            for pt in points.dropFirst() { path.addLine(to: pt) }
                        }
                        .stroke(AppTheme.blushPink, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    }
                    
                    // Data points
                    ForEach(data.indices, id: \.self) { i in
                        if i < points.count {
                            Circle()
                                .fill(AppTheme.blushPink)
                                .frame(width: 7, height: 7)
                                .position(points[i])
                        }
                    }
                    
                    // Day labels
                    ForEach(data.indices, id: \.self) { i in
                        if i < points.count {
                            Text(data[i].date.formatted(as: "E"))
                                .font(.system(size: 9))
                                .foregroundColor(AppTheme.mutedRose)
                                .position(x: points[i].x, y: geo.size.height + 14)
                        }
                    }
                }
            }
            .frame(height: 100)
            .padding(.bottom, 16)
        }
    }
}
