/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE', which is part of this source code package.
 */

import Foundation

public extension SequenceType {

    public func cartestianProduct<S where S : SequenceType>(seq: S) -> [(Self.Generator.Element, S.Generator.Element)] {
        var product: [(Self.Generator.Element, S.Generator.Element)] = []
        self.forEach { (s1) in
            seq.forEach { (s2) in
                product.append((s1, s2))
            }
        }
        return product
    }

    public func mapPass<T, U>(initialData: U, @noescape transform: (Self.Generator.Element, U) throws -> (T, U)) rethrows -> [T] {
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
