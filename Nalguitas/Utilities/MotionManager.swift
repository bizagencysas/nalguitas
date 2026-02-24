import SwiftUI
import CoreMotion

public class MotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    @Published public var pitch: Double = 0.0
    @Published public var roll: Double = 0.0
    
    public init() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
                guard let data = data, let self = self else { return }
                self.pitch = data.attitude.pitch
                self.roll = data.attitude.roll
            }
        }
    }
    
    deinit {
        motionManager.stopDeviceMotionUpdates()
    }
}

public struct ParallaxMotionModifier: ViewModifier {
    @StateObject private var motion = MotionManager()
    var magnitude: Double
    
    public func body(content: Content) -> some View {
        content
            .offset(x: CGFloat(motion.roll * magnitude), y: CGFloat(motion.pitch * magnitude))
            .animation(.interactiveSpring(response: 0.15, dampingFraction: 0.8), value: motion.pitch)
            .animation(.interactiveSpring(response: 0.15, dampingFraction: 0.8), value: motion.roll)
    }
}

public extension View {
    func parallaxMotion(magnitude: Double = 25) -> some View {
        self.modifier(ParallaxMotionModifier(magnitude: magnitude))
    }
}
