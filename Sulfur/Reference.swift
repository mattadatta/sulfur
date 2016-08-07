/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE', which is part of this source code package.
 */

import Foundation

// MARK: - WeakReference

public struct WeakReference<Referent where Referent: AnyObject>: Hashable {

    public private(set) weak var referent: Referent?

    public init(referent: Referent) {
        self.referent = referent
    }

    public var isNil: Bool {
        return self.referent == nil
    }

    public var isNotNil: Bool {
        return self.referent != nil
    }

    public var hashValue: Int {
        guard let referent = self.referent else { return 0 }
        return ObjectIdentifier(referent).hashValue
    }

    public static func == <Referent>(lhs: WeakReference<Referent>, rhs: WeakReference<Referent>) -> Bool {
        switch (lhs.referent, rhs.referent) {
        case (.none, .none):
            return true
        case (.some(let lhs), .some(let rhs)):
            return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
        default:
            return false
        }
    }
}
