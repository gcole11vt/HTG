import Foundation

struct RangeStats: Equatable {
    let max: Int
    let percentile75: Int
    let median: Int
    let count: Int

    init(max: Int = 0, percentile75: Int = 0, median: Int = 0, count: Int = 0) {
        self.max = max
        self.percentile75 = percentile75
        self.median = median
        self.count = count
    }
}
