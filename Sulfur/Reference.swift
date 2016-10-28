/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE', which is part of this source code package.
 */

import Foundation

// MARK: - Reference

public protocol Reference {
    associatedtype Referent

    var referent: Referent? { get }
}

// MARK: - AnyReference

public struct AnyReference: Reference {

    public let reference: Any

    fileprivate var _referent: () -> Any?
    public var referent: Any? {
        return self._referent()
    }

    public init?<R: Reference>(optionalReference reference: R?) {
        guard let reference = reference else { return nil }
        self.init(reference: reference)
    }

    public init<R: Reference>(reference: R) {
        self.reference = reference
        self._referent = { reference.referent }
    }
}

// MARK: - StrongReference

public struct StrongReference<Referent: AnyObject>: Reference, Hashable {

    fileprivate var _referent: Referent
    public var referent: Referent? {
        return self._referent
    }

    public init?(optionalReferent referent: Referent?) {
        guard let referent = referent else { return nil }
        self.init(referent: referent)
    }

    public init(referent: Referent) {
        self._referent = referent
    }

    public var hashValue: Int {
        return ObjectIdentifier(self._referent).hashValue
    }

    public static func == <Referent>(lhs: StrongReference<Referent>, rhs: StrongReference<Referent>) -> Bool {
        return ObjectIdentifier(lhs._referent) == ObjectIdentifier(rhs._referent)
    }
}

// MARK: - WeakReference

public struct WeakReference<Referent: AnyObject>: Reference, Hashable {

    fileprivate weak var _referent: Referent?
    public var referent: Referent? {
        return self._referent
    }

    public init?(optionalReferent referent: Referent?) {
        guard let referent = referent else { return nil }
        self.init(referent: referent)
    }

    public init(referent: Referent) {
        self._referent = referent
    }

    public var isNil: Bool {
        return self._referent == nil
    }

    public var isNotNil: Bool {
        return self._referent != nil
    }

    public var hashValue: Int {
        guard let referent = self._referent else { return 0 }
        return ObjectIdentifier(referent).hashValue
    }

    public static func == <Referent>(lhs: WeakReference<Referent>, rhs: WeakReference<Referent>) -> Bool {
        switch (lhs._referent, rhs._referent) {
        case (.none, .none):
            return true
        case (.some(let lhs), .some(let rhs)):
            return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
        default:
            return false
        }
    }
}

// MARK: - ValueWrapper

public struct ValueWrapper<Value>: Reference {

    public let _value: Value
    public var referent: Value? {
        return self._value
    }

    public init?(optionalValue value: Value?) {
        guard let value = value else { return nil }
        self.init(value: value)
    }

    public init(value: Value) {
        self._value = value
    }
}

public extension ValueWrapper where Value: Hashable {

    public var hashValue: Int {
        return self._value.hashValue
    }

    public static func == <Value: Hashable>(lhs: ValueWrapper<Value>, rhs: ValueWrapper<Value>) -> Bool {
        return lhs._value == rhs._value
    }
}

// MARK: - AssociatedReference

public final class AssociatedReference<Referent>: NSObject, NSCopying {

    fileprivate var _referent: Referent
    public var referent: Referent? {
        return self._referent
    }

    public convenience init?(optionalReferent referent: Referent?) {
        guard let referent = referent else { return nil }
        self.init(referent: referent)
    }

    public init(referent: Referent) {
        self._referent = referent
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        return type(of: self).init(referent: self._referent)
    }
}

public extension AssociatedReference where Referent: NSCopying {

    public func copy(with zone: NSZone? = nil) -> Any {
        return type(of: self).init(referent: self._referent.copy(with: zone) as! Referent)
    }
}

// MARK - Utils

public struct AssociatedUtils {

    public enum Policy {

        case assign
        case retain
        case retainNonAtomic
        case copy
        case copyNonAtomic

        public var objcPolicy: objc_AssociationPolicy {
            switch self {
            case .assign:
                return .OBJC_ASSOCIATION_ASSIGN
            case .retain:
                return .OBJC_ASSOCIATION_RETAIN
            case .retainNonAtomic:
                return .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            case .copy:
                return .OBJC_ASSOCIATION_COPY
            case .copyNonAtomic:
                return .OBJC_ASSOCIATION_COPY_NONATOMIC
            }
        }
    }

    public static func store(for object: AnyObject, key: UnsafeRawPointer, value: Any?, policy: Policy = .retainNonAtomic) {
        objc_setAssociatedObject(object, key, value, policy.objcPolicy)
    }

    public static func retrieve(for object: AnyObject, key: UnsafeRawPointer) -> Any? {
        return objc_getAssociatedObject(object, key)
    }

    public static func store(for object: AnyObject, key: UnsafeRawPointer, storage: Storage?) {
        self.store(for: object, key: key, value: AssociatedReference(optionalReferent: storage?.reference), policy: .retainNonAtomic)
    }

    public static func retrieveValue<Value>(for object: AnyObject, key: UnsafeRawPointer) -> Value? {
        return (self.retrieve(for: object, key: key) as? AssociatedReference<AnyReference>)?.referent?.referent as? Value
    }
}

public enum Storage {

    case value(value: Any)
    case strong(object: AnyObject)
    case weak(object: AnyObject)

    case valueOrNil(value: Any?)
    case strongOrNil(object: AnyObject?)
    case weakOrNil(object: AnyObject?)

    public var reference: AnyReference? {
        let reference: AnyReference?
        switch self {
        case .value(let value):
            reference = AnyReference(reference: ValueWrapper(value: value))
        case .strong(let object):
            reference = AnyReference(reference: StrongReference(referent: object))
        case .weak(let object):
            reference = AnyReference(reference: WeakReference(referent: object))
        case .valueOrNil(let value):
            reference = AnyReference(optionalReference: ValueWrapper(optionalValue: value))
        case .strongOrNil(let object):
            reference = AnyReference(optionalReference: StrongReference(optionalReferent: object))
        case .weakOrNil(let object):
            reference = AnyReference(optionalReference: WeakReference(optionalReferent: object))
        }
        return reference
    }
}
