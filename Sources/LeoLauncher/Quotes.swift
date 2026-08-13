import Foundation
import SwiftUI

struct FamousQuote: Identifiable, Sendable {
    var id: Int
    var english: String
    var chinese: String
    var author: String
}

enum QuoteMode: String, CaseIterable, Identifiable, Sendable {
    case both
    case chinese
    case english
    case off

    var id: String { rawValue }

    var title: String {
        switch self {
        case .both: "中英双语"
        case .chinese: "仅中文"
        case .english: "仅英文"
        case .off: "不展示"
        }
    }
}

enum QuotePlacement: String, CaseIterable, Identifiable, Sendable {
    case top
    case bottom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .top: "顶部 · 搜索栏下方"
        case .bottom: "底部 · 索引栏上方"
        }
    }

    var help: String {
        switch self {
        case .top: "放在搜索栏和内容之间"
        case .bottom: "放在应用列表和底部分类索引之间"
        }
    }
}

enum QuoteBook {
    static let all: [FamousQuote] = [
        FamousQuote(id: 1, english: "Stay hungry, stay foolish.", chinese: "求知若饥，虚心若愚。", author: "Steve Jobs"),
        FamousQuote(id: 2, english: "I think, therefore I am.", chinese: "我思故我在。", author: "René Descartes"),
        FamousQuote(id: 3, english: "Knowledge is power.", chinese: "知识就是力量。", author: "Francis Bacon"),
        FamousQuote(id: 4, english: "The unexamined life is not worth living.", chinese: "未经审视的人生不值得过。", author: "Socrates"),
        FamousQuote(id: 5, english: "Imagination is more important than knowledge.", chinese: "想象力比知识更重要。", author: "Albert Einstein"),
        FamousQuote(id: 6, english: "Life is like riding a bicycle. To keep your balance, you must keep moving.", chinese: "人生就像骑自行车，想保持平衡就得不断向前。", author: "Albert Einstein"),
        FamousQuote(id: 7, english: "The journey of a thousand miles begins with a single step.", chinese: "千里之行，始于足下。", author: "老子"),
        FamousQuote(id: 8, english: "Knowing others is intelligence; knowing yourself is true wisdom.", chinese: "知人者智，自知者明。", author: "老子"),
        FamousQuote(id: 9, english: "Do not do to others what you do not want done to yourself.", chinese: "己所不欲，勿施于人。", author: "孔子"),
        FamousQuote(id: 10, english: "Learning without thought is labor lost; thought without learning is perilous.", chinese: "学而不思则罔，思而不学则殆。", author: "孔子"),
        FamousQuote(id: 11, english: "The superior man is modest in his speech, but exceeds in his actions.", chinese: "君子欲讷于言而敏于行。", author: "孔子"),
        FamousQuote(id: 12, english: "Heaven is vigorous; the gentleman strives on without cease.", chinese: "天行健，君子以自强不息。", author: "《周易》"),
        FamousQuote(id: 13, english: "The road is long; I shall search high and low.", chinese: "路漫漫其修远兮，吾将上下而求索。", author: "屈原"),
        FamousQuote(id: 14, english: "A bosom friend afar brings a distant land near.", chinese: "海内存知己，天涯若比邻。", author: "王勃"),
        FamousQuote(id: 15, english: "At twenty, the will is set; at thirty, one stands firm.", chinese: "三十而立，四十不惑。", author: "孔子"),
        FamousQuote(id: 16, english: "To be yourself in a world that is constantly trying to make you something else is the greatest accomplishment.", chinese: "在一个不断要把你变成别人的世界里，做自己就是最大的成就。", author: "Ralph Waldo Emerson"),
        FamousQuote(id: 17, english: "What we fear doing most is usually what we most need to do.", chinese: "我们最害怕去做的事，往往正是最该去做的事。", author: "Tim Ferriss"),
        FamousQuote(id: 18, english: "He who has a why to live can bear almost any how.", chinese: "知道为什么而活的人，几乎能承受任何如何。", author: "Friedrich Nietzsche"),
        FamousQuote(id: 19, english: "That which does not kill us makes us stronger.", chinese: "杀不死我们的，会让我们更强大。", author: "Friedrich Nietzsche"),
        FamousQuote(id: 20, english: "Simplicity is the ultimate sophistication.", chinese: "简单是最终极的精致。", author: "Leonardo da Vinci"),
        FamousQuote(id: 21, english: "The only thing we have to fear is fear itself.", chinese: "我们唯一需要恐惧的，是恐惧本身。", author: "Franklin D. Roosevelt"),
        FamousQuote(id: 22, english: "Be the change that you wish to see in the world.", chinese: "欲变世界，先变其身。", author: "Mahatma Gandhi"),
        FamousQuote(id: 23, english: "In the middle of difficulty lies opportunity.", chinese: "困难之中，藏着机会。", author: "Albert Einstein"),
        FamousQuote(id: 24, english: "Done is better than perfect.", chinese: "完成，比完美更重要。", author: "Sheryl Sandberg"),
        FamousQuote(id: 25, english: "The best time to plant a tree was twenty years ago. The second best time is now.", chinese: "种一棵树最好的时间是二十年前，其次是现在。", author: "谚语"),
        FamousQuote(id: 26, english: "We are what we repeatedly do. Excellence, then, is not an act, but a habit.", chinese: "我们重复做什么，就会成为什么。卓越不是一次行为，而是一种习惯。", author: "Aristotle"),
        FamousQuote(id: 27, english: "The future belongs to those who believe in the beauty of their dreams.", chinese: "未来属于那些相信梦想之美的人。", author: "Eleanor Roosevelt"),
        FamousQuote(id: 28, english: "It does not matter how slowly you go as long as you do not stop.", chinese: "不怕慢，只怕站。", author: "孔子"),
        FamousQuote(id: 29, english: "A man is but the product of his thoughts. What he thinks, he becomes.", chinese: "人是思想的产物。所思即所成。", author: "Mahatma Gandhi"),
        FamousQuote(id: 30, english: "Time you enjoy wasting is not wasted time.", chinese: "享受着度过的时间，就不是浪费。", author: "Marthe Troly-Curtin"),
        FamousQuote(id: 31, english: "Do what you can, with what you have, where you are.", chinese: "就地，就手，尽力而为。", author: "Theodore Roosevelt"),
        FamousQuote(id: 32, english: "The secret of getting ahead is getting started.", chinese: "领先的秘诀，就是先开始。", author: "Mark Twain"),
        FamousQuote(id: 33, english: "Not all those who wander are lost.", chinese: "并非所有流浪的人，都迷了路。", author: "J. R. R. Tolkien"),
        FamousQuote(id: 34, english: "Fortune favors the bold.", chinese: "幸运眷顾勇者。", author: "Virgil"),
        FamousQuote(id: 35, english: "The only way to do great work is to love what you do.", chinese: "成就伟大工作的唯一途径，是热爱你所做的事。", author: "Steve Jobs"),
        FamousQuote(id: 36, english: "Yesterday is history, tomorrow is a mystery, today is a gift.", chinese: "昨天已成历史，明天仍是谜，今天才是礼物。", author: "Eleanor Roosevelt"),
        FamousQuote(id: 37, english: "Whether you think you can, or you think you can't — you're right.", chinese: "你觉得自己行，或觉得自己不行——你都是对的。", author: "Henry Ford"),
        FamousQuote(id: 38, english: "The mind is everything. What you think you become.", chinese: "心即一切。你想什么，就成为什么。", author: "Buddha"),
        FamousQuote(id: 39, english: "An inch of time is an inch of gold, but an inch of gold cannot buy an inch of time.", chinese: "一寸光阴一寸金，寸金难买寸光阴。", author: "谚语"),
        FamousQuote(id: 40, english: "When I walk in the company of two, I can always find my teacher.", chinese: "三人行，必有我师焉。", author: "孔子")
    ]
}

struct QuoteBanner: View {
    var quote: FamousQuote
    var mode: QuoteMode
    @Environment(\.overlayPalette) private var palette

    var body: some View {
        VStack(spacing: 5) {
            if mode == .english || mode == .both {
                Text("“\(quote.english)”")
                    .font(LeoFont.display(mode == .english ? 17 : 15))
                    .italic()
                    .foregroundStyle(palette.text.opacity(0.92))
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.35), radius: 6, y: 1)
            }
            if mode == .chinese || mode == .both {
                Text(quote.chinese)
                    .font(mode == .chinese ? LeoFont.display(17) : LeoFont.body(13))
                    .italic(mode == .chinese)
                    .foregroundStyle(mode == .chinese ? palette.text.opacity(0.92) : palette.mute)
                    .multilineTextAlignment(.center)
            }
            Text("— \(quote.author)")
                .font(LeoFont.mono(10))
                .foregroundStyle(Ink.copper.opacity(0.88))
                .tracking(0.6)
        }
        .frame(maxWidth: 760)
        .padding(.horizontal, 36)
        .padding(.vertical, 8)
        .allowsHitTesting(false)
        .accessibilityElement(children: .combine)
    }
}
