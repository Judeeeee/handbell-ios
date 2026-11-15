import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ContentView: View {
    @State private var currentIndex = 4 // 初期音は「ソ」
    @State private var ringCount = 0
    @StateObject private var shake = ShakeDetector()
    @StateObject private var audio = BellAudioEngine()
    #if canImport(UIKit)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    #endif

    private var current: BellNote { BellNote.all[currentIndex] }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                // センサー状態は背景に埋もれないよう、白カプセル地に濃い文字で出す
                HStack(spacing: 6) {
                    Circle()
                        .fill(shake.isRunning ? Color.green : Color.orange)
                        .frame(width: 9, height: 9)
                    Text(shake.isRunning ? "センサー ON" : "センサー OFF")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color(red: 0.15, green: 0.15, blue: 0.15))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.75), in: Capsule())
                .overlay(Capsule().stroke(Color.black.opacity(0.08), lineWidth: 1))
            }
            .frame(maxWidth: .infinity)

            Spacer()

            ZStack {
                if ringCount > 0 {
                    Circle()
                        .stroke(current.color, lineWidth: 3)
                        .frame(width: 180, height: 180)
                        .modifier(RippleEffect(trigger: ringCount))
                }
                BellView(color: current.color, swingTrigger: ringCount)
            }
            .frame(height: 280)
            .contentShape(Rectangle())
            .onTapGesture { play() }

            // 中央表示は大きなカナだけ (英語音名・周波数は出さない)
            Text(current.label)
                .font(.system(size: 56, weight: .heavy))
                .foregroundStyle(current.color)
                .padding(.top, 8)

            Spacer()

            Slider(
                value: Binding(
                    get: { Double(currentIndex) },
                    set: { newValue in
                        let newIndex = Int(newValue.rounded())
                        if newIndex != currentIndex {
                            currentIndex = newIndex
                            #if canImport(UIKit)
                            selectionFeedback.selectionChanged()
                            #endif
                        }
                    }),
                in: 0...7, step: 1)
                .tint(current.color)
                .frame(height: 104)
                // 両端の音は画面の端まで持っていかなくても届くよう、幅は内側に寄せる
                .padding(.horizontal, 24)

            // 音階ラベルは色ドット + カナのみ。下に英語音名は出さない
            HStack {
                ForEach(BellNote.all) { note in
                    Button {
                        currentIndex = note.id
                    } label: {
                        VStack(spacing: 4) {
                            Circle().fill(note.color).frame(width: 10, height: 10)
                            Text(note.label)
                                .font(.subheadline.weight(.bold))
                        }
                        .foregroundStyle(note.id == currentIndex ? note.color : .gray)
                        .scaleEffect(note.id == currentIndex ? 1.25 : 1.0)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            Text("スマホを振るか、ベルをタップすると鳴ります")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color(red: 0.25, green: 0.23, blue: 0.20))
                .padding(.top, 16)

            // 下に固定の余白を入れて、スライダーと音階ラベルの帯を少し上へ寄せる
            Spacer()
                .frame(height: 32)
        }
        .padding(20)
        .frame(maxWidth: 480)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 1.0, green: 0.98, blue: 0.94).ignoresSafeArea())
        .onAppear {
            // 最初のタップで音が欠けないよう、画面表示時点でエンジンを温めておく
            audio.startIfNeeded()
            shake.onShake = { play() }
            shake.start()
        }
        .onDisappear { shake.stop() }
    }

    private func play() {
        audio.play(noteIndex: currentIndex)
        ringCount += 1
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

/// 鳴った瞬間に輪が広がって消える波紋。
private struct RippleEffect: ViewModifier {
    let trigger: Int
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.7

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .opacity(opacity)
            .onChange(of: trigger) {
                scale = 0.5
                opacity = 0.7
                withAnimation(.easeOut(duration: 0.6)) {
                    scale = 1.5
                    opacity = 0
                }
            }
    }
}
