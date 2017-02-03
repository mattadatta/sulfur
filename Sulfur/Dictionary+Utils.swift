//
// This file is subject to the terms and conditions defined in
// file 'LICENSE', which is part of this source code package.
//

import Foundation

public func += <Key, Value> (lhs: inout [Key: Value], rhs: [Key: Value]) {
    rhs.forEach { key, value in
        lhs.updateValue(value, forKey: key)
    }
}

public func + <Key, Value> (lhs: [Key: Value], rhs: [Key: Value]) -> [Key: Value] {
    var result = lhs
    result += rhs
    return result
}
