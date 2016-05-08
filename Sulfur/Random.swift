/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE', which is part of this source code package.
 */

import UIKit

public struct Random {

    private init() { }

    public static func randomNumberInclusiveMinimum(minimum: Int, maximum: Int) -> Int {
        if maximum < minimum {
            return 0
        }
        let range = UInt32(maximum - minimum)
        let random = Int(arc4random_uniform(range + 1))
        return random + minimum
    }
}

public extension CollectionType where Self.Index == Int {

    var randomElement: Self.Generator.Element? {
        if self.isEmpty {
            return nil
        }
        return self[Random.randomNumberInclusiveMinimum(0, maximum: self.count - 1)]
    }
}

public extension UIColor {

    @warn_unused_result
    static func randomColor() -> UIColor {
        return UIColor(
            red: CGFloat(Random.randomNumberInclusiveMinimum(0, maximum: 255)) / 255,
            green: CGFloat(Random.randomNumberInclusiveMinimum(0, maximum: 255)) / 255,
            blue: CGFloat(Random.randomNumberInclusiveMinimum(0, maximum: 255)) / 255,
            alpha: 1.0)
    }
}
