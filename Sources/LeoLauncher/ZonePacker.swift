import CoreGraphics
import Foundation

enum Masonry {
    static func columnCount(for width: CGFloat) -> Int {
        switch width {
        case ..<760: 2
        case ..<1280: 3
        default: 4
        }
    }

    static func distribute(
        _ groups: [(AppCategory, [AppRecord])],
        into columnCount: Int
    ) -> [[(AppCategory, [AppRecord])]] {
        let count = max(1, columnCount)
        var columns = Array(repeating: [(AppCategory, [AppRecord])](), count: count)
        var weights = Array(repeating: 0, count: count)
        for group in groups where !group.1.isEmpty {
            let index = weights.enumerated().min(by: { $0.element < $1.element })?.offset ?? 0
            columns[index].append(group)
            weights[index] += 2 + group.1.count
        }
        return columns
    }
}
