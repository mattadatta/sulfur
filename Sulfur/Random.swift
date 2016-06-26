/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE', which is part of this source code package.
 */

import UIKit

public enum Random {

    public static func float() -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UINT32_MAX)
    }
}

public extension MutableCollection where
    Self.IndexDistance == Int,
    Self.Index == Int,
    Self.Indices == CountableRange<Int>
{

    public mutating func shuffle() {
        self.indices.dropLast().forEach { index in
            let other = Int(arc4random_uniform(UInt32(self.count - index))) + index
            guard index != other else { return }

            swap(&self[other], &self[index])
        }
    }
}

public extension Collection where
    Self.IndexDistance == Int,
    Self.Index == Int,
    Self.Indices == CountableRange<Int>
{

    public func shuffled() -> [Self.Iterator.Element] {
        var elements = Array(self)
        elements.shuffle()
        return elements
    }

    public var randomElement: Self.Iterator.Element? {
        guard self.isEmpty else { return nil }
        return self[Int(arc4random_uniform(UInt32(self.count)))]
    }
    
    public func chooseAny(_ n: Int) -> [Self.Iterator.Element] {
        return Array(self.shuffled().prefix(n))
    }
}
