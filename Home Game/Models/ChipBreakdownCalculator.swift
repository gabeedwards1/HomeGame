import Foundation

enum ChipBreakdownCalculator {
    static func suggestedBreakdown(buyIn: Decimal, denominations: [ChipDenomination]) -> [(denomination: ChipDenomination, count: Int)] {
        guard buyIn > 0, !denominations.isEmpty else { return [] }

        let sumOfValues = denominations.reduce(Decimal.zero) { $0 + $1.value }
        guard sumOfValues > 0 else { return [] }

        var counts: [UUID: Int] = [:]
        var remaining = buyIn

        // Hand out an even count of every denomination first, so the stack looks
        // balanced across colors instead of skewing toward the largest chip.
        let baseCount = floorCount(buyIn, dividedBy: sumOfValues)
        if baseCount > 0 {
            for denomination in denominations {
                counts[denomination.id, default: 0] += baseCount
                remaining -= Decimal(baseCount) * denomination.value
            }
        }

        // Top off the remainder (less than one full "set") from the largest denomination down.
        for denomination in denominations.sorted(by: { $0.value > $1.value }) {
            guard denomination.value > 0, remaining > 0 else { continue }
            let count = floorCount(remaining, dividedBy: denomination.value)
            guard count > 0 else { continue }
            counts[denomination.id, default: 0] += count
            remaining -= Decimal(count) * denomination.value
        }

        return denominations
            .sorted { $0.value > $1.value }
            .compactMap { denomination in
                guard let count = counts[denomination.id], count > 0 else { return nil }
                return (denomination, count)
            }
    }

    /// `NSDecimalNumber.intValue` (and therefore `Int(truncating:)`) returns 0 for values with
    /// long repeating fractional digits, e.g. 20/1.90. `doubleValue` doesn't have that bug.
    private static func floorCount(_ value: Decimal, dividedBy divisor: Decimal) -> Int {
        guard divisor > 0 else { return 0 }
        return Int(((value / divisor) as NSDecimalNumber).doubleValue)
    }
}
