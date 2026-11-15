import AVFoundation
import Combine
import Foundation

/// AVFoundation によるベル音の合成。
/// 起動時に8音ぶんの波形をメモリ上の WAV データとして生成しておき、
/// 再生時は AVAudioPlayer のインスタンスを都度作って鳴らす。同時発音も可。
///
/// 当初は AVAudioEngine のグラフ方式だったが、iOS 27 シミュレータ環境で
/// 「エラーなくバッファが描画されない」事象が続いたため、単発再生で
/// 実績のある AVAudioPlayer 方式に切り替えた。リバーブは無くなるが、
/// ベルの余韻は倍音の指数減衰で表現している。
/// セッションの有効化は専用キューで行う (メインスレッドでの setActive は
/// Hang Risk 警告の対象になるため)。
final class BellAudioEngine: NSObject, ObservableObject {
    private var noteData: [Data] = []
    private var activePlayers: [AVAudioPlayer] = []
    private var started = false
    private let queue = DispatchQueue(label: "handbell.audio")

    private let sampleRate = 44100.0
    private let partials: [(ratio: Double, gain: Double, decay: Double)] = [
        (1.0, 1.0, 2.5), (2.02, 0.5, 1.8), (2.74, 0.25, 1.0), (5.4, 0.1, 0.5),
    ]

    override init() {
        super.init()
        noteData = BellNote.all.map { makeWavData(frequency: $0.frequency) }
    }

    /// 画面表示時点での事前準備 (セッション有効化を済ませておく)。
    func startIfNeeded() {
        queue.async { [weak self] in
            self?.activateSessionIfNeeded()
        }
    }

    func play(noteIndex: Int) {
        queue.async { [weak self] in
            guard let self, self.noteData.indices.contains(noteIndex) else { return }
            guard self.activateSessionIfNeeded() else { return }
            // 再生が終わったプレイヤーを掃除してから新しいものを足す
            // (再生中のインスタンスを保持し続けないと音が途中で止まるため)
            self.activePlayers.removeAll { !$0.isPlaying }
            do {
                let player = try AVAudioPlayer(data: self.noteData[noteIndex])
                player.prepareToPlay()
                if player.play() {
                    self.activePlayers.append(player)
                } else {
                    print("AVAudioPlayer play() returned false")
                }
            } catch {
                print("AVAudioPlayer failed: \(error)")
            }
        }
    }

    @discardableResult
    private func activateSessionIfNeeded() -> Bool {
        if started { return true }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
            started = true
            return true
        } catch {
            print("AudioSession activate failed: \(error)")
            return false
        }
    }

    /// 基音 + 倍音を指数減衰させた波形を 16bit モノラル WAV データにする。
    private func makeWavData(frequency: Double) -> Data {
        let frames = Int(sampleRate * 2.5)
        var data = Data()
        data.reserveCapacity(44 + frames * 2)

        func appendUInt32(_ v: UInt32) {
            var x = v.littleEndian
            data.append(Data(bytes: &x, count: 4))
        }
        func appendUInt16(_ v: UInt16) {
            var x = v.littleEndian
            data.append(Data(bytes: &x, count: 2))
        }

        let dataSize = frames * 2
        data.append("RIFF".data(using: .ascii)!)
        appendUInt32(UInt32(36 + dataSize))
        data.append("WAVE".data(using: .ascii)!)
        data.append("fmt ".data(using: .ascii)!)
        appendUInt32(16)                    // fmt チャンクサイズ
        appendUInt16(1)                     // PCM
        appendUInt16(1)                     // モノラル
        appendUInt32(UInt32(sampleRate))    // サンプルレート
        appendUInt32(UInt32(sampleRate) * 2) // バイトレート
        appendUInt16(2)                     // ブロックアライン
        appendUInt16(16)                    // ビット深度
        data.append("data".data(using: .ascii)!)
        appendUInt32(UInt32(dataSize))

        for i in 0..<frames {
            let t = Double(i) / sampleRate
            var value = 0.0
            for p in partials {
                // pow(0.001, t/decay): t=0 で 1、t=decay で 0.001 になる指数減衰
                value += p.gain * pow(0.001, t / p.decay)
                    * sin(2.0 * Double.pi * frequency * p.ratio * t)
            }
            let clamped = max(-1.0, min(1.0, 0.35 * value))
            var sample = Int16(clamped * 32767.0).littleEndian
            data.append(Data(bytes: &sample, count: 2))
        }
        return data
    }
}
