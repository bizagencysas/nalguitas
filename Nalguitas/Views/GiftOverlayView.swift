import SwiftUI

struct GiftOverlayView: View {
    let gift: Gift
    let onDismiss: () -> Void
    
    @State private var showCharacter = false
    @State private var showMessage = false
    @State private var showSubtitle = false
    @State private var hearts: [FloatingHeart] = []
    @State private var sparkles: [FloatingSparkle] = []
    @State private var characterScale: CGFloat = 0.3
    @State private var characterRotation: Double = -5
    @State private var backgroundOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // Dark overlay background
            Color.black.opacity(backgroundOpacity * 0.4)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }
            
            // Floating hearts
            ForEach(hearts) { heart in
                Image(systemName: heart.icon)
                    .font(.system(size: heart.size))
                    .foregroundStyle(heart.color)
                    .position(heart.position)
                    .opacity(heart.opacity)
            }
            
            // Floating sparkles
            ForEach(sparkles) { sparkle in
                Image(systemName: "sparkle")
                    .font(.system(size: sparkle.size))
                    .foregroundStyle(Color(red: 0.95, green: 0.73, blue: 0.78))
                    .position(sparkle.position)
                    .opacity(sparkle.opacity)
                    .rotationEffect(.degrees(sparkle.rotation))
            }
            
            VStack(spacing: 0) {
                Spacer()
                
                // Character image
                if showCharacter {
                    AsyncImage(url: GiftCharacter.imageURL(for: gift.characterName)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 220, height: 220)
                        case .failure(_):
                            Image(systemName: "gift.fill")
                                .font(.system(size: 80))
                                .foregroundStyle(Theme.rosePrimary)
                        case .empty:
                            ProgressView()
                                .tint(Theme.rosePrimary)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .scaleEffect(characterScale)
                    .rotationEffect(.degrees(characterRotation))
                    .shadow(color: Theme.rosePrimary.opacity(0.3), radius: 20, y: 10)
                    .transition(.scale.combined(with: .opacity))
                }
                
                Spacer().frame(height: 24)
                
                // Message bubble
                if showMessage {
                    VStack(spacing: 12) {
                        Text(gift.message)
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .foregroundStyle(Color(red: 0.30, green: 0.20, blue: 0.22))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                        
                        if showSubtitle {
                            HStack(spacing: 6) {
                                Image(systemName: "heart.fill")
                                    .font(.caption2)
                                    .foregroundStyle(Theme.rosePrimary)
                                Text(gift.subtitle)
                                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                                    .foregroundStyle(Color(red: 0.55, green: 0.42, blue: 0.45))
                                Image(systemName: "heart.fill")
                                    .font(.caption2)
                                    .foregroundStyle(Theme.rosePrimary)
                            }
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(.ultraThinMaterial)
                            .shadow(color: Theme.rosePrimary.opacity(0.2), radius: 15, y: 5)
                    )
                    .padding(.horizontal, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                Spacer().frame(height: 32)
                
                // Close button
                if showMessage {
                    Button(action: dismiss) {
                        HStack(spacing: 8) {
                            Image(systemName: "heart.circle.fill")
                                .font(.title3)
                            Text("¡Gracias mi amor!")
                                .font(.system(.body, design: .rounded, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Theme.rosePrimary, Theme.roseQuartz],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: Theme.rosePrimary.opacity(0.4), radius: 10, y: 4)
                        )
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                Spacer()
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Background fade in
        withAnimation(.easeIn(duration: 0.4)) {
            backgroundOpacity = 1
        }
        
        // Start floating hearts
        startFloatingHearts()
        startFloatingSparkles()
        
        // Character entrance
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6, blendDuration: 0)) {
                showCharacter = true
                characterScale = 1.0
            }
            
            // Gentle floating animation
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                characterRotation = 5
            }
        }
        
        // Message entrance
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showMessage = true
            }
        }
        
        // Subtitle entrance
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showSubtitle = true
            }
        }
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    private func dismiss() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        withAnimation(.easeOut(duration: 0.3)) {
            backgroundOpacity = 0
            showCharacter = false
            showMessage = false
            showSubtitle = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
        
        // Mark as seen
        Task {
            try? await APIService.shared.markGiftSeen(id: gift.id)
        }
    }
    
    private func startFloatingHearts() {
        let icons = ["heart.fill", "heart.fill", "heart.circle.fill", "sparkle"]
        let colors: [Color] = [
            Theme.rosePrimary,
            Theme.roseLight,
            Color(red: 0.95, green: 0.73, blue: 0.78),
            Theme.blush,
        ]
        
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            let screenWidth = UIScreen.main.bounds.width
            let screenHeight = UIScreen.main.bounds.height
            
            let heart = FloatingHeart(
                icon: icons.randomElement()!,
                color: colors.randomElement()!,
                size: CGFloat.random(in: 12...28),
                position: CGPoint(x: CGFloat.random(in: 20...screenWidth - 20), y: screenHeight + 20),
                opacity: 1
            )
            hearts.append(heart)
            
            // Animate upward
            withAnimation(.easeOut(duration: Double.random(in: 3...5))) {
                if let index = hearts.firstIndex(where: { $0.id == heart.id }) {
                    hearts[index].position.y = -50
                    hearts[index].opacity = 0
                    hearts[index].position.x += CGFloat.random(in: -40...40)
                }
            }
            
            // Clean up old hearts
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                hearts.removeAll(where: { $0.id == heart.id })
            }
            
            if backgroundOpacity == 0 {
                timer.invalidate()
            }
        }
    }
    
    private func startFloatingSparkles() {
        Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { timer in
            let screenWidth = UIScreen.main.bounds.width
            let screenHeight = UIScreen.main.bounds.height
            
            let sparkle = FloatingSparkle(
                size: CGFloat.random(in: 8...18),
                position: CGPoint(x: CGFloat.random(in: 20...screenWidth - 20), y: CGFloat.random(in: 100...screenHeight - 200)),
                opacity: 0,
                rotation: 0
            )
            sparkles.append(sparkle)
            
            withAnimation(.easeInOut(duration: 1.5)) {
                if let index = sparkles.firstIndex(where: { $0.id == sparkle.id }) {
                    sparkles[index].opacity = 0.8
                    sparkles[index].rotation = 180
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 1)) {
                    if let index = sparkles.firstIndex(where: { $0.id == sparkle.id }) {
                        sparkles[index].opacity = 0
                    }
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                sparkles.removeAll(where: { $0.id == sparkle.id })
            }
            
            if backgroundOpacity == 0 {
                timer.invalidate()
            }
        }
    }
}

struct FloatingHeart: Identifiable {
    let id = UUID()
    let icon: String
    let color: Color
    let size: CGFloat
    var position: CGPoint
    var opacity: Double
}

struct FloatingSparkle: Identifiable {
    let id = UUID()
    let size: CGFloat
    var position: CGPoint
    var opacity: Double
    var rotation: Double
}
