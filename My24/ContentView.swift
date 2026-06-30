import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab: Int = 0
    @State private var showingAddSheet = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tabItem {
                        Label("Dashboard", systemImage: "square.grid.2x2.fill")
                    }
                    .tag(0)
                
                LogTimeView()
                    .tabItem {
                        Label("Log Time", systemImage: "plus.circle.fill")
                    }
                    .tag(1)
                
                TimelineView()
                    .tabItem {
                        Label("Timeline", systemImage: "calendar.day.timeline.left")
                    }
                    .tag(2)
                
                InsightsView()
                    .tabItem {
                        Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
                    }
                    .tag(3)
            }
            .tint(AppTheme.deepRose)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewData.container)
}
