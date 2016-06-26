/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE', which is part of this source code package.
 */

import Foundation

// MARK: - StrongObjectReference

public struct StrongObjectReference: Hashable {

    public let object: AnyObject

    public init(_ object: AnyObject) {
        self.object = object
    }

    public var hashValue: Int {
        return unsafeAddress(of: self.object).hashValue
    }
}

public func == (lhs: StrongObjectReference, rhs: StrongObjectReference) -> Bool {
    return lhs.object === rhs.object
}

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
        guard let referent = self.referent else {
            return 0
        }
        return unsafeAddress(of: referent).hashValue
    }
}

public func == <Referent>(lhs: WeakReference<Referent>, rhs: WeakReference<Referent>) -> Bool {
    return lhs.referent === rhs.referent
}
