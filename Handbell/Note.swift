import SwiftUI

/// 8音階の定義 (C4 - C5)。
/// 色は KC BC-08K/MU 実物セットの並び。ベル本体は全体をその音の色一色で塗り、
/// 持ち手だけ白にする。高いド (C5) は低いドと同色 (濃い赤)。
/// ※メイン画面には英語音名・周波数を表示しない (内部データとしてだけ持つ)。
struct BellNote: Identifiable {
    let id: Int
    let kana: String
    let frequency: Double
    let color: Color

    /// 画面に出す表記。高いドだけ「ド↑」にする。
    var label: String { id == 7 ? "ド↑" : kana }

    static let all: [BellNote] = [
        BellNote(id: 0, kana: "ド",   frequency: 261.63,
                 color: Color(red: 176 / 255, green: 30 / 255,  blue: 36 / 255)),   // #b01e24
        BellNote(id: 1, kana: "レ",   frequency: 293.66,
                 color: Color(red: 233 / 255, green: 78 / 255,  blue: 27 / 255)),   // #e94e1b
        BellNote(id: 2, kana: "ミ",   frequency: 329.63,
                 color: Color(red: 242 / 255, green: 207 / 255, blue: 7 / 255)),    // #f2cf07
        BellNote(id: 3, kana: "ファ", frequency: 349.23,
                 color: Color(red: 53 / 255,  green: 168 / 255, blue: 58 / 255)),   // #35a83a
        BellNote(id: 4, kana: "ソ",   frequency: 392.00,
                 color: Color(red: 31 / 255,  green: 127 / 255, blue: 194 / 255)),  // #1f7fc2
        BellNote(id: 5, kana: "ラ",   frequency: 440.00,
                 color: Color(red: 32 / 255,  green: 53 / 255,  blue: 184 / 255)),  // #2035b8
        BellNote(id: 6, kana: "シ",   frequency: 493.88,
                 color: Color(red: 126 / 255, green: 37 / 255,  blue: 111 / 255)),  // #7e256f
        BellNote(id: 7, kana: "ド",   frequency: 523.25,
                 color: Color(red: 176 / 255, green: 30 / 255,  blue: 36 / 255)),   // #b01e24 (C4と同色)
    ]
}
