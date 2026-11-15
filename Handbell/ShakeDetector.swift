import Combine
import CoreMotion
import Foundation

/// CoreMotion による「振る」検知 (Web版の DeviceMotionEvent の移植)。
/// ネイティブ版では Web のような許可ダイアログは不要で、
/// アプリ表示中は常時センサーを開始できるのが利点。
///
/// 注意: CoreMotion の加速度の単位は m/s² ではなく「g」。
/// 静止時は 1.0g なので、Web版の 22 m/s² は 22 / 9.81 ≒ 2.24g に換算する。
final class ShakeDetector: ObservableObject {
    @Published private(set) var isRunning = false
    var onShake: (() -> Void)?

    private let manager = CMMotionManager()
    private var lastFired = Date.distantPast
    private let thresholdG = 2.2
    private let cooldown = 0.4

    func start() {
        guard !isRunning, manager.isAccelerometerAvailable else { return }
        manager.accelerometerUpdateInterval = 1.0 / 60.0
        manager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self, let a = data?.acceleration else { return }
            let mag = sqrt(a.x * a.x + a.y * a.y + a.z * a.z)
            let now = Date()
            if mag > thresholdG && now.timeIntervalSince(lastFired) > cooldown {
                lastFired = now
                onShake?()
            }
        }
        isRunning = true
    }

    func stop() {
        manager.stopAccelerometerUpdates()
        isRunning = false
    }
}
