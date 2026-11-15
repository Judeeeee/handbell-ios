import SwiftUI

/// アイコン風ベルの本体シルエット (丸いドームから裾が広がる形)。
struct IconBellShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        func x(_ v: CGFloat) -> CGFloat { rect.minX + w * v }
        func y(_ v: CGFloat) -> CGFloat { rect.minY + h * v }
        var p = Path()
        p.move(to: CGPoint(x: x(0.37), y: y(0.045)))
        // 左のドーム〜側面
        p.addCurve(
            to: CGPoint(x: x(0.155), y: y(0.58)),
            control1: CGPoint(x: x(0.225), y: y(0.08)),
            control2: CGPoint(x: x(0.155), y: y(0.29)))
        // 左の裾の広がり
        p.addCurve(
            to: CGPoint(x: x(0.035), y: y(0.935)),
            control1: CGPoint(x: x(0.148), y: y(0.765)),
            control2: CGPoint(x: x(0.087), y: y(0.845)))
        // 底辺 (下に膨らむ弧)
        p.addQuadCurve(
            to: CGPoint(x: x(0.965), y: y(0.935)),
            control: CGPoint(x: x(0.5), y: y(1.03)))
        // 右の裾〜側面
        p.addCurve(
            to: CGPoint(x: x(0.845), y: y(0.58)),
            control1: CGPoint(x: x(0.913), y: y(0.845)),
            control2: CGPoint(x: x(0.852), y: y(0.765)))
        // 右のドーム〜天面
        p.addCurve(
            to: CGPoint(x: x(0.63), y: y(0.045)),
            control1: CGPoint(x: x(0.845), y: y(0.29)),
            control2: CGPoint(x: x(0.775), y: y(0.08)))
        // 天面
        p.addQuadCurve(
            to: CGPoint(x: x(0.37), y: y(0.045)),
            control: CGPoint(x: x(0.5), y: y(-0.01)))
        p.closeSubpath()
        return p
    }
}

/// 左側の光沢 (アイコンのツヤの線)。
struct BellHighlightLeft: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX + rect.width * 0.26, y: rect.minY + rect.height * 0.36))
        p.addQuadCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.185, y: rect.minY + rect.height * 0.78),
            control: CGPoint(x: rect.minX + rect.width * 0.185, y: rect.minY + rect.height * 0.55))
        return p
    }
}

/// 右下の光沢 (アイコンのツヤの線)。
struct BellHighlightRight: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX + rect.width * 0.60, y: rect.minY + rect.height * 0.83))
        p.addQuadCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.86, y: rect.minY + rect.height * 0.80),
            control: CGPoint(x: rect.minX + rect.width * 0.73, y: rect.minY + rect.height * 0.865))
        return p
    }
}

/// 舌 (クラッパー): 中央下から少し覗く玉。
struct ClapperShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addRoundedRect(
            in: CGRect(x: rect.midX - 3.5, y: rect.minY, width: 7, height: rect.height * 0.55),
            cornerSize: CGSize(width: 3, height: 3))
        p.addEllipse(
            in: CGRect(x: rect.midX - 7.5, y: rect.maxY - 15, width: 15, height: 15))
        return p
    }
}

/// アイコン風のベル本体。本体は音の色一色、開口部はその濃い色、舌は金色。
struct IconBellBody: View {
    let color: Color

    var body: some View {
        ZStack {
            IconBellShape()
                .fill(color)
            // 光沢
            BellHighlightLeft()
                .stroke(Color.white.opacity(0.30), style: StrokeStyle(lineWidth: 11, lineCap: .round))
            BellHighlightRight()
                .stroke(Color.white.opacity(0.22), style: StrokeStyle(lineWidth: 10, lineCap: .round))
            // 開口部 (ベルの内側): 音色を濃くした楕円
            ZStack {
                Ellipse().fill(color)
                Ellipse().fill(Color.black.opacity(0.38))
            }
            .frame(width: 200, height: 34)
            .offset(y: 76)
            // 舌: アイコンと同じ金色
            ClapperShape()
                .fill(Color(red: 0.85, green: 0.64, blue: 0.25))
                .frame(width: 20, height: 30)
                .offset(y: 82)
        }
    }
}

/// ハンドベルの絵。アイコンと同じ見た目: 丸いドーム型のベル (音の色一色) に、
/// 丸いツマミ付きの白い棒の持ち手。
/// 鳴るたびに swingTrigger が増え、ベルが左右に揺れる。
struct BellView: View {
    let color: Color
    let swingTrigger: Int
    @State private var angle: Double = 0

    private let handleFill = Color(red: 1.0, green: 0.99, blue: 0.96)
    private let handleStroke = Color(red: 0.87, green: 0.84, blue: 0.76)

    var body: some View {
        ZStack {
            // 持ち手のツマミ (丸)
            Circle()
                .fill(handleFill)
                .overlay(Circle().stroke(handleStroke, lineWidth: 2))
                .frame(width: 36, height: 36)
                .offset(y: -94)
            // 持ち手: 白い棒状
            RoundedRectangle(cornerRadius: 12)
                .fill(handleFill)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(handleStroke, lineWidth: 2))
                .frame(width: 26, height: 86)
                .offset(y: -52)
            // ベル本体
            IconBellBody(color: color)
                .frame(width: 230, height: 180)
                .offset(y: 34)
        }
        .frame(width: 230, height: 256)
        .rotationEffect(.degrees(angle), anchor: .top)
        .onChange(of: swingTrigger) {
            withAnimation(.easeOut(duration: 0.12)) { angle = -11 }
            withAnimation(.easeInOut(duration: 0.18).delay(0.12)) { angle = 9 }
            withAnimation(.easeOut(duration: 0.25).delay(0.30)) { angle = 0 }
        }
    }
}
