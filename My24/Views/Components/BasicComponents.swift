import SwiftUI

// MARK: - Dashboard Header

struct DashboardHeader: View {
    let subtitle: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Orchid logo placeholder (use Image("orchid_logo") when asset is added)
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("My24")
                    .font(.playfairBold(26))
                    .foregroundColor(AppTheme.deepRose)
                Text(subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(AppTheme.mutedRose)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    var action: (() -> Void)? = nil
    var actionLabel: String = "See All"
    
    var body: some View {
        HStack {
            Text(title)
                .font(.playfairBold(18))
                .foregroundColor(AppTheme.deepRose)
            Spacer()
            if let action {
                Button(actionLabel, action: action)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.mutedRose)
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Themed Card

struct ThemedCard<Content: View>: View {
    var backgroundColor: Color = AppTheme.blushLight
    var cornerRadius: CGFloat = 16
    var padding: CGFloat = 16
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        content()
            .padding(padding)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: AppTheme.deepRose.opacity(0.07), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    var action: (() -> Void)? = nil
    var actionLabel: String = "Get Started"
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(AppTheme.blushMid)
                    .frame(width: 80, height: 80)
                Image(systemName: systemImage)
                    .font(.system(size: 34))
                    .foregroundColor(AppTheme.mutedRose)
            }
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.playfairBold(20))
                    .foregroundColor(AppTheme.deepRose)
                Text(message)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(AppTheme.mutedRose)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            if let action {
                Button(actionLabel, action: action)
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let category: Category
    var isSelected: Bool = false
    var onTap: (() -> Void)? = nil
    
    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 6) {
                Image(systemName: category.iconName)
                    .font(.system(size: 12, weight: .semibold))
                Text(category.name)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(isSelected ? .white : category.color)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? category.color : category.color.opacity(0.15))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Mood Picker

struct MoodPicker: View {
    @Binding var selectedMood: Int
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(Mood.allCases, id: \.rawValue) { mood in
                Button(action: {
                    selectedMood = mood.rawValue
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }) {
                    VStack(spacing: 4) {
                        Text(mood.emoji)
                            .font(.system(size: selectedMood == mood.rawValue ? 36 : 28))
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedMood)
                        
                        if selectedMood == mood.rawValue {
                            Text(mood.label)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(mood.color)
                                .transition(.opacity.combined(with: .scale))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(selectedMood == mood.rawValue ? mood.color.opacity(0.15) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(selectedMood == mood.rawValue ? mood.color : Color.clear, lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.2), value: selectedMood)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Category Color Swatch

struct ColorSwatchPicker: View {
    @Binding var selectedHex: String
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(AppTheme.categoryPresets, id: \.self) { hex in
                let color = Color(hex: hex) ?? .gray
                Button(action: { selectedHex = hex }) {
                    Circle()
                        .fill(color)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: selectedHex == hex ? 3 : 0)
                        )
                        .overlay(
                            Circle()
                                .stroke(color.opacity(0.5), lineWidth: selectedHex == hex ? 1.5 : 0)
                                .scaleEffect(1.2)
                        )
                        .shadow(color: color.opacity(0.4), radius: selectedHex == hex ? 6 : 0)
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.2), value: selectedHex)
            }
        }
    }
}
