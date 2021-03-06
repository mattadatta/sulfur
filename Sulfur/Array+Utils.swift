/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE', which is part of this source code package.
 */

import Foundation

public extension Array {

    public mutating func takeLast() -> Element? {
        guard !self.isEmpty else { return nil }
        return self.removeLast()
    }

    public func ask(index: Int) -> Element? {
        guard index >= 0 && index < self.count else { return nil }
        return self[index]
    }
}
