/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE', which is part of this source code package.
 */

import Foundation

// MARK: - StrongObjectReference

public struct StrongObjectReference: Hashable {

    let object: AnyObject

    init(_ object: AnyObject) {
        self.object = object
    }

    public var hashValue: Int {
        return unsafeAddressOf(self.object).hashValue
    }
}

public func == (lhs: StrongObjectReference, rhs: StrongObjectReference) -> Bool {
    return lhs.object === rhs.object
}

// MARK: - WeakReference

public struct WeakReference<Referent where Referent: AnyObject>: Hashable {

    private(set) weak var referent: Referent?

    init(referent: Referent) {
        self.referent = referent
    }

    var isNil: Bool {
        return self.referent == nil
    }

    var isNotNil: Bool {
        return self.referent != nil
    }

    public var hashValue: Int {
        guard let referent = self.referent else {
            return 0
        }
        return unsafeAddressOf(referent).hashValue
    }
}

public func == <Referent>(lhs: WeakReference<Referent>, rhs: WeakReference<Referent>) -> Bool {
    return lhs.referent === rhs.referent
}
