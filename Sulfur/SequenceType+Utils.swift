/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE', which is part of this source code package.
 */

import Foundation

public extension Sequence {

    public func cartestianProduct<S>(_ seq: S) -> [(Self.Iterator.Element, S.Iterator.Element)] where S : Sequence {
        var product: [(Self.Iterator.Element, S.Iterator.Element)] = []
        self.forEach { (s1) in
            seq.forEach { (s2) in
                product.append((s1, s2))
            }
        }
        return product
    }

    public func mapPass<T, U>(_ initialData: U, transform:  (Self.Iterator.Element, U) throws -> (T, U)) rethrows -> [T] {
        var result: [T] = []
        var data = initialData
        try self.forEach { (element) in
            let transformed = try transform(element, data)
            result.append(transformed.0)
            data = transformed.1
        }
        return result
    }
}
