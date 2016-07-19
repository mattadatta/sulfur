/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE', which is part of this source code package.
 */

import UIKit

// MARK: Hasher

public struct Hasher: Hashable {

    private enum State: Hashable {

        case Initial
        case Computed(Int)

        var hashValue: Int {
            switch self {
            case .Initial:
                return 0
            case .Computed(let hash):
                return hash
            }
        }
    }

    private var state: State = .Initial

    public init() {
    }

    private mutating func hash(value value: Int) {
        switch self.state {
        case .Initial:
            self.state = .Computed(value)
        case .Computed(let result):
            self.state = .Computed(37 &* result &+ value)
        }
    }

    public mutating func add(part part: HashablePart?) {
        self.hash(value: part?.hashComponent ?? 0)
    }

    public func adding(part part: HashablePart?) -> Hasher {
        var hasher = self
        hasher.add(part: part)
        return hasher
    }

    public mutating func add<H: Hashable>(hashable hashable: H?) {
        self.hash(value: hashable?.hashValue ?? 0)
    }

    public func adding<H: Hashable>(hashable hashable: H?) -> Hasher {
        var hasher = self
        hasher.add(hashable: hashable)
        return hasher
    }

    public mutating func add(object object: AnyObject?) {
        if let obj = object {
            self.hash(value: ObjectIdentifier(obj).hashValue)
        } else {
            self.hash(value: 0)
        }
    }

    public func adding(object object: AnyObject?) -> Hasher {
        var hasher = self
        hasher.add(object: object)
        return hasher
    }

    public var hashValue: Int {
        return self.state.hashValue
    }
}

private func == (lhs: Hasher.State, rhs: Hasher.State) -> Bool {
    switch (lhs, rhs) {
    case (.Initial, .Initial):
        return true
    case (.Computed(let lhs), .Computed(let rhs)):
        return lhs == rhs
    default:
        return false
    }
}

public func == (lhs: Hasher, rhs: Hasher) -> Bool {
    return lhs.state == rhs.state
}

// MARK: - HashablePart

public protocol HashablePart {

    var hashComponent: Int { get }
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
        return self.native.hashComponent
    }
}

extension Int: HashablePart {

    public var hashComponent: Int {
        return self
    }
}

extension Bool: HashablePart {

    public var hashComponent: Int {
        return self ? 1 : 0
    }
}
