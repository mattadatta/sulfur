/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE.txt', which is part of this source code package.
 */

import UIKit

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
        if let contextNodeContainer = service as? ContextNodeContainer {
            for child in contextNodeContainer.childContextObjects {
                self.add(service: child)
            }
        }
        if let contextServiceNode = service as? ContextServiceNode, contextServiceNode.context == nil {
            contextServiceNode.context = self
            contextServiceNode.added(to: self)
        }
    }

    private func remove(service: Any) {
        if let contextServiceNode = service as? ContextServiceNode, contextServiceNode.context != nil {
            contextServiceNode.removed(from: self)
            contextServiceNode.context = nil
        }
        if let contextNodeContainer = service as? ContextNodeContainer {
            for child in contextNodeContainer.childContextObjects {
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
        if let contextNodeContainer = obj as? ContextNodeContainer {
            for child in contextNodeContainer.childContextObjects {
                self.wrap(child)
            }
        }
        if let viewController = obj as? UIViewController {
            self.wrap(viewController.view)
        }
        self.setupContextNodeIfNecessary(obj)
        return obj
    }

    fileprivate func setupContextNodeIfNecessary(_ obj: Any) {
        guard let contextNode = obj as? ContextNode, contextNode.contextToken == nil else { return }

        let contextToken = self.generateToken()
        contextToken.contextNode = contextNode
        contextNode.contextToken = contextToken
        contextNode.contextAvailable()
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
    fileprivate weak var contextNode: ContextNode?

    fileprivate init(context: Context) {
        self.context = context
    }

    deinit {
        self.context.remove(self)
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

// MARK: - ContextNode

public protocol ContextNode: class {

    func contextAvailable()
}

fileprivate struct ContextNodeKeys {

    static var contextTokenKey: Void = ()
}

extension ContextNode {

    var contextToken: ContextToken? {
        get { return AssociatedUtils.retrieveValue(for: self, key: &ContextNodeKeys.contextTokenKey) }
        set { AssociatedUtils.store(for: self, key: &ContextNodeKeys.contextTokenKey, storage: .strongOrNil(object: newValue)) }
    }
}

public extension ContextNode {

    public var context: Context {
        return self.contextToken!.context
    }

    public func contextWrap<Object>(_ obj: Object) -> Object {
        return self.context.wrap(obj)
    }

    public func newViewController<ViewController: UIViewController>() -> ViewController {
        return self.context.newViewController()
    }

    public func newView<View: UIView>() -> View {
        return self.context.newView()
    }
}

public extension ContextNode where Self: UIViewController {

    /**
     Instantiate a view controller from the view controller's storyboard. The `UIViewController` subclass you're
     instantiating must have the same storyboard tag as its class name, such that the tag is the
     result of executing `String(Controller)`.

     - returns: The new `UIViewController` instance
     */
    public func viewControllerFromStoryboard<Controller: UIViewController>() -> Controller? {
        guard let storyboard = self.storyboard else { return nil }
        let controller = storyboard.instantiateViewController(withIdentifier: String(describing: Controller.self)) as! Controller
        if !storyboard.hasContextWrapper {
            self.context.wrap(controller)
        }
        return controller
    }
}

// MARK: - ContextNodeContainer

public protocol ContextNodeContainer {

    var childContextObjects: [Any] { get }
}

extension UIViewController: ContextNodeContainer {

    public var childContextObjects: [Any] {
        return self.childViewControllers.map({ $0 })
    }
}

extension UIView: ContextNodeContainer {

    public var childContextObjects: [Any] {
        return self.subviews.map({ $0 })
    }
}

public protocol ContextPreloadable {

    func contextPreload()
}

extension UIViewController: ContextPreloadable {

    public func contextPreload() {
        guard let contextNode = self as? ContextNode, contextNode.contextToken == nil else { return }
        self.loadViewIfNeeded()
    }
}

extension UIView: ContextPreloadable {

    public func contextPreload() {
        guard let contextNode = self as? ContextNode, contextNode.contextToken == nil else { return }
        guard let inflatable = self as? UINibViewInflatable else { return }
        let view = inflatable.inflateView()
        self.addAndConstrain(view)
    }
}

// MARK: - ContextService

public protocol ContextServiceNode: class {

    var context: Context? { get set } // Fulfilled by extension

    func added(to context: Context)
    func removed(from context: Context)
}

public protocol ContextService: ContextServiceNode {
    associatedtype Component

    var component: Component { get }
}

fileprivate struct ContextServiceNodeKeys {

    static var contextKey: Void = ()
}

public extension ContextServiceNode {

    public var context: Context? {
        get { return AssociatedUtils.retrieveValue(for: self, key: &ContextServiceNodeKeys.contextKey) }
        set { AssociatedUtils.store(for: self, key: &ContextServiceNodeKeys.contextKey, storage: .weakOrNil(object: newValue)) }
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

    fileprivate let _setContext: (Context?) -> Void
    fileprivate let _getContext: () -> Context?

    public var context: Context? {
        get { return self._getContext() }
        set { self._setContext(newValue) }
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
        self._getContext = { service.context }
        self._setContext = { service.context = $0 }
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
