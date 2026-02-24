import SwiftUI

public struct ConfettiParticle: Equatable {
    var id = UUID()
    var position: CGPoint
    var scale: CGFloat
    var rotation: Double
    var xVelocity: CGFloat
    var yVelocity: CGFloat
    var color: Color
    var spinDelta: Double
    var isAlive: Bool = true
}

public class ConfettiManager: ObservableObject {
    @Published var particles: [ConfettiParticle] = []
    private var displayLink: CADisplayLink?
    
    public init() {}
    
    public func burst(at location: CGPoint? = nil) {
        let center = location ?? CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
        let colors: [Color] = [.pink, .purple, .yellow, Theme.rosePrimary, .white]
        
        var newParticles = [ConfettiParticle]()
        for _ in 0..<80 {
            let angle = Double.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 100...450)
            
            let p = ConfettiParticle(
                position: center,
                scale: CGFloat.random(in: 0.5...1.2),
                rotation: Double.random(in: 0...360),
                xVelocity: cos(angle) * speed,
                yVelocity: sin(angle) * speed - 200, // Initial upward burst
                color: colors.randomElement()!,
                spinDelta: Double.random(in: -15...15)
            )
            newParticles.append(p)
        }
        
        particles.append(contentsOf: newParticles)
        startEngine()
        
        // Auto-stop after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.particles.removeAll()
            self?.stopEngine()
        }
    }
    
    private func startEngine() {
        guard displayLink == nil else { return }
        displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    private func stopEngine() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func update() {
        let dt: CGFloat = 1.0 / 60.0
        let gravity: CGFloat = 400.0
        
        for i in particles.indices {
            var p = particles[i]
            
            // Apply gravity
            p.yVelocity += gravity * dt
            
            // Apply drag modifier
            p.xVelocity *= 0.95
            p.yVelocity *= 0.99
            
            p.position.x += p.xVelocity * dt
            p.position.y += p.yVelocity * dt
            p.rotation += p.spinDelta
            
            particles[i] = p
        }
        
        // Optional cull
        particles.removeAll(where: { $0.position.y > UIScreen.main.bounds.height + 100 })
        
        if particles.isEmpty { stopEngine() }
    }
}

public struct ConfettiView: View {
    @ObservedObject var manager: ConfettiManager
    
    public init(manager: ConfettiManager) {
        self.manager = manager
    }
    
    public var body: some View {
        ZStack {
            ForEach(manager.particles, id: \.id) { particle in
                Rectangle()
                    .fill(particle.color)
                    .frame(width: 12 * particle.scale, height: 8 * particle.scale)
                    .rotationEffect(.degrees(particle.rotation))
                    .position(particle.position)
            }
        }
        .allowsHitTesting(false)
    }
}
