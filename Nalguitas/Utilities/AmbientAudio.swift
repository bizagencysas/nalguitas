import AVFoundation
import AudioToolbox

public class AmbientAudio {
    public static let shared = AmbientAudio()
    private init() {}
    
    // System Sound IDs for native iOS experiences
    // 1004: Sent Message
    // 1003: Received Message
    // 1016: Tweet sent (good for checking off tasks)
    // 1033: Received payment
    // 1435: Pull to refresh
    // 1350: Apple Pay Success
    
    public func playSentMessage() {
        AudioServicesPlaySystemSound(1004)
    }
    
    public func playReceivedMessage() {
        AudioServicesPlaySystemSound(1003)
    }
    
    public func playSuccess() {
        AudioServicesPlaySystemSound(1016)
    }
    
    public func playPayment() {
        AudioServicesPlaySystemSound(1033)
    }
    
    public func playRefresh() {
        AudioServicesPlaySystemSound(1435)
    }
    
    public func playApplePaySuccess() {
        AudioServicesPlaySystemSound(1350)
    }
}
