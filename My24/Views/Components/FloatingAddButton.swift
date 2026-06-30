import SwiftUI

// MARK: - Floating Add Button

struct FloatingAddButton: View {
    @Binding var isExpanded: Bool
    var onStartTimer: () -> Void
    var onAddPast: () -> Void
    var onDuplicate: () -> Void
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 14) {
            if isExpanded {
                // Options
                VStack(alignment: .trailing, spacing: 10) {
                    FabOption(label: "Duplicate Previous", icon: "doc.on.doc.fill", color: AppTheme.lavender) {
                        onDuplicate()
                        withAnimation(.spring()) { isExpanded = false }
                    }
                    FabOption(label: "Add Past Time", icon: "clock.arrow.circlepath", color: AppTheme.goldCat) {
                        onAddPast()
                        withAnimation(.spring()) { isExpanded = false }
                    }
                    FabOption(label: "Start Timer", icon: "play.fill", color: AppTheme.sage) {
                        onStartTimer()
                        withAnimation(.spring()) { isExpanded = false }
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
            }
            
            // Main FAB
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(AppTheme.deepRose)
                        .frame(width: 58, height: 58)
                        .shadow(color: AppTheme.deepRose.opacity(0.35), radius: 12, x: 0, y: 6)
                    
                    Image(systemName: isExpanded ? "xmark" : "plus")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(isExpanded ? 45 : 0))
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isExpanded)
                }
            }
        }
        .padding(.trailing, 24)
        .padding(.bottom, 24)
    }
}

struct FabOption: View {
    let label: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.deepRose)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(AppTheme.blushLight)
                    .clipShape(Capsule())
                    .shadow(color: AppTheme.deepRose.opacity(0.08), radius: 6, x: 0, y: 3)
                
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 44, height: 44)
                        .shadow(color: color.opacity(0.3), radius: 6, x: 0, y: 3)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
