/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE', which is part of this source code package.
 */

import UIKit

public enum Random {

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

    public var randomElement: Self.Generator.Element? {
        if self.isEmpty {
            return nil
        }
        return self[Random.randomNumberInclusiveMinimum(0, maximum: self.count - 1)]
    }
}

public extension UIColor {

    @warn_unused_result
    public static func randomColor(alpha alpha: CGFloat = 1.0) -> UIColor {
        return UIColor(
            red: CGFloat(Random.randomNumberInclusiveMinimum(0, maximum: 255)) / 255,
            green: CGFloat(Random.randomNumberInclusiveMinimum(0, maximum: 255)) / 255,
            blue: CGFloat(Random.randomNumberInclusiveMinimum(0, maximum: 255)) / 255,
            alpha: alpha)
    }
}
