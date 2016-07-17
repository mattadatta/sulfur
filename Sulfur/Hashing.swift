/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE', which is part of this source code package.
 */

import UIKit

public protocol HashablePart {

    var hashComponent: Int { get }
}

public struct HashableWrapperPart<Object: Hashable>: HashablePart {

    public var hashable: Object?

    public init(_ part: Object?) {
        self.hashable = part
    }

    public var hashComponent: Int {
        return self.hashable?.hashValue ?? 0
    }
}

extension Int: HashablePart {

    public var hashComponent: Int {
        return self
    }
}

extension Float: HashablePart {

    public var hashComponent: Int {
        return Int(unsafeBitCast(self, UInt32.self))
    }
}

extension Double: HashablePart {

    public var hashComponent: Int {
        let bitPatten = unsafeBitCast(self, UInt64.self)
        return Int(bitPatten ^ (bitPatten >> 32))
    }
}

extension CGFloat: HashablePart {

    public var hashComponent: Int {
        if CGFloat.NativeType.self == Double.self {
            return Double(self).hashComponent
        }
        return Float(self).hashComponent
    }
}

public extension CollectionType where Generator.Element == HashablePart {

    public var hashComponent: Int {
        return self.reduce(17, combine: { 37 &* $0 &+ $1.hashComponent })
    }
}
