import CoreGraphics
import Foundation

enum ZonePacker {
    static let columns = 12
    static let spacing: CGFloat = 14

    static func pack(
        groups: [(AppCategory, [AppRecord])],
        width: CGFloat,
        iconSize: CGFloat,
        hideNames: Bool
    ) -> [PackedZone] {
        guard width > 0 else { return [] }

        let gap = spacing
        let colWidth = (width - CGFloat(columns - 1) * gap) / CGFloat(columns)
        let titleBand: CGFloat = 30
        let nameBand: CGFloat = hideNames ? 0 : 18
        let iconRow = iconSize + 10 + nameBand
        let verticalPad: CGFloat = 18

        var occupancy: [Int: Int] = [:]
        var placed: [PackedZone] = []
        var cursorRow = 0

        for (category, apps) in groups where !apps.isEmpty {
            let span = preferredSpan(count: apps.count)
            let position = nextFit(cols: span.cols, occupancy: &occupancy, startRow: &cursorRow)
            let zoneWidth = CGFloat(span.cols) * colWidth + CGFloat(span.cols - 1) * gap
            let iconsPerRow = max(1, Int((zoneWidth - 24) / (iconSize + 10)))
            let neededRows = max(1, Int(ceil(Double(apps.count) / Double(iconsPerRow))))
            let rowSpan = max(span.rows, neededRows)
            occupy(col: position.col, row: position.row, colSpan: span.cols, rowSpan: rowSpan, occupancy: &occupancy)

            let height = titleBand + verticalPad + CGFloat(rowSpan) * iconRow
            let x = CGFloat(position.col) * (colWidth + gap)
            placed.append(
                PackedZone(
                    category: category,
                    apps: apps,
                    col: position.col,
                    row: position.row,
                    colSpan: span.cols,
                    rowSpan: rowSpan,
                    rect: CGRect(x: x, y: 0, width: zoneWidth, height: height)
                )
            )
        }

        let rowHeights = rowHeightMap(zones: placed, iconRow: iconRow, titleBand: titleBand, verticalPad: verticalPad, gap: gap)
        return placed.map { zone in
            var copy = zone
            copy.rect.origin.y = rowHeights.offset[zone.row] ?? 0
            copy.rect.size.height = rowHeights.height[zone.row].map { $0 * CGFloat(zone.rowSpan) + gap * CGFloat(max(0, zone.rowSpan - 1)) } ?? zone.rect.height
            if zone.rowSpan > 1 {
                let end = zone.row + zone.rowSpan
                let top = rowHeights.offset[zone.row] ?? 0
                let bottom = (rowHeights.offset[end] ?? (top + copy.rect.height))
                copy.rect.size.height = max(copy.rect.height, bottom - top - gap)
            }
            return copy
        }
    }

    static func boardHeight(zones: [PackedZone]) -> CGFloat {
        zones.map(\.rect.maxY).max() ?? 0
    }

    private static func preferredSpan(count: Int) -> (cols: Int, rows: Int) {
        switch count {
        case 1...3: (3, 1)
        case 4...6: (4, 1)
        case 7...8: (6, 1)
        case 9...12: (6, 2)
        case 13...18: (8, 2)
        case 19...28: (12, 2)
        default: (12, max(2, Int(ceil(Double(count) / 12.0))))
        }
    }

    private static func nextFit(cols: Int, occupancy: inout [Int: Int], startRow: inout Int) -> (col: Int, row: Int) {
        var row = startRow
        while true {
            let used = occupancy[row, default: 0]
            if used + cols <= ZonePacker.columns {
                return (used, row)
            }
            row += 1
            startRow = row
        }
    }

    private static func occupy(col: Int, row: Int, colSpan: Int, rowSpan: Int, occupancy: inout [Int: Int]) {
        for r in row..<(row + rowSpan) {
            occupancy[r] = max(occupancy[r, default: 0], col + colSpan)
        }
    }

    private static func rowHeightMap(
        zones: [PackedZone],
        iconRow: CGFloat,
        titleBand: CGFloat,
        verticalPad: CGFloat,
        gap: CGFloat
    ) -> (offset: [Int: CGFloat], height: [Int: CGFloat]) {
        let maxRow = zones.map { $0.row + $0.rowSpan }.max() ?? 0
        var unit: [Int: CGFloat] = [:]
        for row in 0..<maxRow {
            let contributing = zones.filter { row >= $0.row && row < $0.row + $0.rowSpan }
            let tallest = contributing.map { zone -> CGFloat in
                let total = titleBand + verticalPad + CGFloat(zone.rowSpan) * iconRow
                return total / CGFloat(zone.rowSpan)
            }.max() ?? (titleBand + verticalPad + iconRow)
            unit[row] = tallest
        }
        var offset: [Int: CGFloat] = [:]
        var cursor: CGFloat = 0
        for row in 0..<maxRow {
            offset[row] = cursor
            cursor += (unit[row] ?? 0) + gap
        }
        offset[maxRow] = cursor
        return (offset, unit)
    }
}
