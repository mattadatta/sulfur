/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE.txt', which is part of this source code package.
 */

import UIKit
import RxSwift

// MARK: - Context

public final class Context {

    // MARK: Init

    public init() { }

    // MARK: ContextToken

    fileprivate var weakTokens: Set<WeakReference<ContextToken>> = []

    fileprivate var tokens: Set<ContextToken> {
        return Set(self.weakTokens.flatMap({ $0.referent }))
    }

    fileprivate func generateToken() -> ContextToken {
        let token = ContextToken(context: self)
        self.weakTokens.insert(WeakReference(referent: token))
        return token
    }

    fileprivate func remove(_ token: ContextToken) {
        self.weakTokens = Set(self.weakTokens.filter({ $0.referent != token }))
    }

    // MARK: Services

    public enum ServiceEvent {
        case removed(tag: AnyContextServiceTag, service: AnyContextService)
        case added(tag: AnyContextServiceTag, service: AnyContextService)
    }

    fileprivate var services: [AnyContextServiceTag: AnyContextService] = [:]

    public func store<Tag: ContextServiceTag, Service>(service: Service?, for tag: Tag) where Service == Tag.Service {
        let anyTag = tag as? AnyContextServiceTag ?? AnyContextServiceTag(tag: tag)
        if let service = self.services[anyTag] {
            self.remove(service: service.baseService)
            self.dispatch(.removed(tag: anyTag, service: service))
        }

        let service = AnyContextService(optionalService: service)
        self.services[anyTag] = service

        if let service = service {
            self.add(service: service.baseService)
            self.dispatch(.added(tag: anyTag, service: service))
        }
    }

    private func add(service: Any) {
        if let contextualContainer = service as? ContextualContainer {
            for child in contextualContainer.childContextuals {
                self.add(service: child)
            }
        }
        if let contextServiceNode = service as? ContextServiceNode, contextServiceNode.context == nil {
            contextServiceNode.contextFn = { [weak self] in return self }
            contextServiceNode.added(to: self)
        }
    }

    private func remove(service: Any) {
        if let contextServiceNode = service as? ContextServiceNode, contextServiceNode.context != nil {
            contextServiceNode.removed(from: self)
            contextServiceNode.contextFn = nil
        }
        if let contextualContainer = service as? ContextualContainer {
            for child in contextualContainer.childContextuals {
                self.remove(service: child)
            }
        }
    }

    public func service<Tag: ContextServiceTag, Service>(for tag: Tag) -> Service? where Service == Tag.Service {
        let anyTag = tag as? AnyContextServiceTag ?? AnyContextServiceTag(tag: tag)
        return self.services[anyTag]?.baseService as? Service
    }

    public func serviceComponent<Tag: ContextServiceTag, Service> (for tag: Tag) -> Service.Component? where Service == Tag.Service {
        return self.service(for: tag)?.component
    }

    fileprivate func dispatch(_ serviceEvent: ServiceEvent) {
        // TODO:
    }

    // MARK: Wrapping

    @discardableResult
    public func wrap<Object>(_ obj: Object) -> Object {
        if let contextPreloadable = obj as? ContextPreloadable {
            contextPreloadable.contextPreload()
        }
        if let contextualContainer = obj as? ContextualContainer {
            for child in contextualContainer.childContextuals {
                self.wrap(child)
            }
        }
        if let viewController = obj as? UIViewController {
            self.wrap(viewController.view)
        }
        self.setupContextualIfNecessary(obj)
        return obj
    }

    fileprivate func setupContextualIfNecessary(_ obj: Any) {
        guard let contextual = obj as? Contextual, contextual.contextToken == nil else { return }

        let contextToken = self.generateToken()
        contextToken.contextual = contextual
        contextual.contextToken = contextToken
        contextual.contextAvailable()
    }
}

public extension Context {

    public func newViewController<ViewController: UIViewController>() -> ViewController {
        return self.wrap(ViewController())
    }

    public func newView<View: UIView>() -> View {
        return self.wrap(View())
    }
}

// MARK: - ContextToken

public final class ContextToken: Hashable {

    public let context: Context
    fileprivate weak var contextual: Contextual?

    fileprivate init(context: Context) {
        self.context = context
    }

    deinit {
        self.context.remove(self)
    }

    // MARK: Stored References

    private var storedReferences: [String: AnyReference] = [:]

    public func store(key: String, storage: Storage?) {
        self.storedReferences[key] = storage?.reference
    }

    public func retrieveValue<Value>(forKey key: String) -> Value? {
        return self.storedReferences[key]?.referent as? Value
    }

    // MARK: Hashable conformance

    public var hashValue: Int {
        return ObjectIdentifier(self).hashValue
    }

    public static func == (lhs: ContextToken, rhs: ContextToken) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}

// MARK: - StoryboardContextWrapper

public final class StoryboardContextWrapper: NSObject, ConfigurableStoryboardDelegate {

    public let context: Context

    public init(context: Context) {
        self.context = context
    }

    public func configureViewController(_ viewController: UIViewController) {
        self.context.wrap(viewController)
    }
}

fileprivate extension UIStoryboard {

    var hasContextWrapper: Bool {
        return (self as? ConfigurableStoryboard)?.delegate is StoryboardContextWrapper
    }
}

// MARK: - Contextual

public protocol Contextual: class {

    var contextToken: ContextToken? { get set }
    func contextAvailable()
}

public extension Contextual {

    public var context: Context {
        return self.contextToken!.context
    }

    @discardableResult
    public func contextWrap<Object>(_ obj: Object) -> Object {
        return self.context.wrap(obj)
    }

    public func store(key: String, storage: Storage?) {
        self.contextToken?.store(key: key, storage: storage)
    }

    public func retrieveValue<Value>(forKey key: String) -> Value? {
        return self.contextToken?.retrieveValue(forKey: key)
    }
}

public extension Contextual where Self: UIViewController {

    public func viewControllerFromStoryboard<Controller: UIViewController>() -> Controller? {
        guard let storyboard = self.storyboard else { return nil }
        let controller = storyboard.instantiateViewController(withIdentifier: String(describing: Controller.self)) as! Controller
        if !storyboard.hasContextWrapper {
            self.contextWrap(controller)
        }
        return controller
    }
}

// MARK: - ContextualContainer

public protocol ContextualContainer {

    var childContextuals: [Any] { get }
}

extension UIViewController: ContextualContainer {

    open var childContextuals: [Any] {
        return self.childViewControllers.map({ $0 })
    }
}

extension UIView: ContextualContainer {

    open var childContextuals: [Any] {
        return self.subviews.map({ $0 })
    }
}

public protocol ContextPreloadable {

    func contextPreload()
}

extension UIViewController: ContextPreloadable {

    open func contextPreload() {
        guard let contextual = self as? Contextual, contextual.contextToken == nil else { return }
        self.loadViewIfNeeded()
    }
}

extension UIView: ContextPreloadable {

    open func contextPreload() {
        guard let contextual = self as? Contextual, contextual.contextToken == nil else { return }
        guard let inflatable = self as? UINibViewInflatable else { return }
        let view = inflatable.inflateView()
        self.addAndConstrainView(view)
    }
}

// MARK: - ContextService

public protocol ContextServiceNode: class {

    var contextFn: (() -> Context?)? { get set }

    func added(to context: Context)
    func removed(from context: Context)
}

public protocol ContextService: ContextServiceNode {
    associatedtype Component

    var component: Component { get }
}

public extension ContextServiceNode {

    public var context: Context? {
        return self.contextFn?()
    }

    public func added(to context: Context) {
    }

    public func removed(from context: Context) {
    }
}

public final class AnyContextService: ContextService, Hashable {

    public let baseService: AnyObject
    fileprivate let _component: () -> Any
    fileprivate let _addedTo: (Context) -> Void
    fileprivate let _removedFrom: (Context) -> Void

    fileprivate let _setContextFn: ((() -> Context?)?) -> Void
    fileprivate let _getContextFn: () -> (() -> Context?)?

    public var contextFn: (() -> Context?)? {
        get { return self._getContextFn() }
        set { self._setContextFn(newValue) }
    }

    public convenience init?<Service: ContextService>(optionalService service: Service?) {
        guard let service = service else { return nil }
        self.init(service: service)
    }

    public init<Service: ContextService>(service: Service) {
        self.baseService = service
        self._component = { service.component }
        self._addedTo = { service.added(to: $0) }
        self._removedFrom = { service.removed(from: $0) }
        self._getContextFn = { service.contextFn }
        self._setContextFn = { service.contextFn = $0 }
    }

    public var component: Any {
        return self._component()
    }

    public func added(to context: Context) {
        self._addedTo(context)
    }

    public func removed(from context: Context) {
        self._removedFrom(context)
    }

    public var hashValue: Int {
        return ObjectIdentifier(self.baseService).hashValue
    }

    public static func == (lhs: AnyContextService, rhs: AnyContextService) -> Bool {
        return ObjectIdentifier(lhs.baseService) == ObjectIdentifier(rhs.baseService)
    }
}

// MARK: - ContextServiceTag

public protocol ContextServiceTag: Hashable {
    associatedtype Service: ContextService

    var serviceID: String { get } // Fulfilled by extension, if desired
}

public extension ContextServiceTag {

    public var serviceID: String {
        return String(describing: Self.self)
    }
}

extension ContextServiceTag where Self: Hashable {

    public var hashValue: Int {
        return self.serviceID.hashValue
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.serviceID == rhs.serviceID
    }
}

public struct AnyContextServiceTag: ContextServiceTag, Hashable {

    public typealias Service = AnyContextService

    public let tag: Any
    fileprivate let _serviceID: () -> String
    fileprivate let _equalTo: (AnyContextServiceTag) -> Bool
    fileprivate let _hashValue: () -> Int

    public init?<Tag: ContextServiceTag>(optionalTag tag: Tag?) {
        guard let tag = tag else { return nil }
        self.init(tag: tag)
    }

    public init<Tag: ContextServiceTag>(tag: Tag) {
        self.tag = tag
        self._serviceID = { tag.serviceID }
        self._equalTo = { ($0.tag as? Tag) == tag }
        self._hashValue = { tag.hashValue }
    }
    
    public var serviceID: String {
        return self._serviceID()
    }
    
    public var hashValue: Int {
        return self._hashValue()
    }
    
    public static func == (lhs: AnyContextServiceTag, rhs: AnyContextServiceTag) -> Bool {
        return lhs._equalTo(rhs)
    }
}
