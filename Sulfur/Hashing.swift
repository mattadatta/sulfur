/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE', which is part of this source code package.
 */

import UIKit

// MARK: Hasher

public struct Hasher: Hashable {

    fileprivate enum State: Hashable {

        case initial
        case computed(result: Int)

        var hashValue: Int {
            switch self {
            case .initial:
                return 0
            case .computed(let hash):
                return hash
            }
        }

        static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.initial, .initial):
                return true
            case (.computed(let lhs), .computed(let rhs)):
                return lhs == rhs
            default:
                return false
            }
        }
    }

    fileprivate var state: State = .initial

    public init() {}

    fileprivate mutating func hash(value: Int) {
        switch self.state {
        case .initial:
            self.state = .computed(result: value)
        case .computed(let result):
            self.state = .computed(result: 37 &* result &+ value)
        }
    }

    public mutating func add(part: HashablePart?) {
        self.hash(value: part?.hashComponent ?? 0)
    }

    public func adding(part: HashablePart?) -> Hasher {
        var hasher = self
        hasher.add(part: part)
        return hasher
    }

    public mutating func add<C: Collection>(parts: C?) where C.Iterator.Element: HashablePart {
        if let parts = parts {
            parts.forEach { part in
                self.add(part: part)
            }
        } else {
            self.hash(value: 0)
        }
    }

    public func adding<C: Collection>(parts: C?) -> Hasher where C.Iterator.Element: HashablePart {
        var hasher = self
        hasher.add(parts: parts)
        return hasher
    }

    public mutating func add<H: Hashable>(hashable: H?) {
        self.hash(value: hashable?.hashValue ?? 0)
    }

    public func adding<H: Hashable>(hashable: H?) -> Hasher {
        var hasher = self
        hasher.add(hashable: hashable)
        return hasher
    }

    public mutating func add<H: Hashable, C: Collection>(hashables: C?) where C.Iterator.Element == H {
        if let hashables = hashables {
            hashables.forEach { hashable in
                self.add(hashable: hashable)
            }
        } else {
            self.hash(value: 0)
        }
    }

    public func adding<H: Hashable, C: Collection>(hashables: C?) -> Hasher where C.Iterator.Element == H {
        var hasher = self
        hasher.add(hashables: hashables)
        return hasher
    }

    public mutating func add<C: Collection>(anyHashables: C?) where C.Iterator.Element == AnyHashable {
        if let hashables = anyHashables {
            hashables.forEach { hashable in
                self.add(hashable: hashable)
            }
        } else {
            self.hash(value: 0)
        }
    }

    public func adding<C: Collection>(anyHashables: C?) -> Hasher where C.Iterator.Element == AnyHashable {
        var hasher = self
        hasher.add(anyHashables: anyHashables)
        return hasher
    }

    public mutating func add(object: AnyObject?) {
        if let obj = object {
            self.hash(value: ObjectIdentifier(obj).hashValue)
        } else {
            self.hash(value: 0)
        }
    }

    public func adding(object: AnyObject?) -> Hasher {
        var hasher = self
        hasher.add(object: object)
        return hasher
    }

    public mutating func add<C: Collection>(objects: C?) where C.Iterator.Element: AnyObject {
        if let objects = objects {
            objects.forEach { object in
                self.add(object: object)
            }
        } else {
            self.hash(value: 0)
        }
    }

    public func adding<C: Collection>(objects: C?) -> Hasher where C.Iterator.Element == AnyObject {
        var hasher = self
        hasher.add(objects: objects)
        return hasher
    }

    // MARK: Hashable conformance

    public var hashValue: Int {
        return self.state.hashValue
    }

    public static func == (lhs: Hasher, rhs: Hasher) -> Bool {
        return lhs.state == rhs.state
    }
}

// MARK: - HashablePart

public protocol HashablePart {

    var hashComponent: Int { get }
}

extension Float: HashablePart {

    public var hashComponent: Int {
        return Int(self.bitPattern)
    }
}

extension Double: HashablePart {

    public var hashComponent: Int {
        let bitPatten = self.bitPattern
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
