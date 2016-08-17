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

    private var contextTokens: Set<WeakReference<ContextToken>> = []

    private var unwrappedTokens: Set<ContextToken> {
        return Set(self.contextTokens.flatMap({ $0.referent }))
    }

    private func generateToken() -> ContextToken {
        let token = ContextToken(context: self)
        self.contextTokens.insert(WeakReference(referent: token))
        return token
    }

    private func remove(_ token: ContextToken) {
        self.contextTokens = Set(self.contextTokens.filter({ $0.referent != token }))
    }

    // MARK: Services

    public enum ServiceEvent {
        case removed(tag: AnyContextServiceTag, service: AnyContextService)
        case added(tag: AnyContextServiceTag, service: AnyContextService)
    }

    private var services: [AnyContextServiceTag: AnyContextService] = [:]

    public func store
        <Tag: ContextServiceTag, Service where Service == Tag.Service>
        (service: Service?, for tag: Tag)
    {
        let tag = AnyContextServiceTag(tag: tag)
        if let existingService = self.services[tag] {
            let service = AnyContextService(service: existingService)
            service.removed(from: self)
            service.context = nil
            self.dispatch(.removed(tag: tag, service: service))
        }

        let service = AnyContextService(optionalService: service)
        self.services[tag] = service

        if let service = service {
            service.context = self
            service.added(to: self)
            self.dispatch(.added(tag: tag, service: service))
        }
    }

    public func service
        <Tag: ContextServiceTag, Service where Service == Tag.Service>
        (for tag: Tag) -> Service?
    {
        return self.services[AnyContextServiceTag(tag: tag)]?.baseService as? Service
    }

    public func serviceComponent
        <Tag: ContextServiceTag, Service where Service == Tag.Service>
        (for tag: Tag) -> Service.Component?
    {
        return self.service(for: tag)?.component
    }

    private func dispatch(_ serviceEvent: ServiceEvent) {
        self.unwrappedTokens.forEach { token in
            guard let contextServiceAware = token.contextAware as? ContextServiceAware else { return }
            contextServiceAware.contextDispatched(serviceEvent)
        }
    }

    // MARK: Wrapping

    @discardableResult
    public func wrap<Object>(_ obj: Object) -> Object {
        if let contextPreloadable = obj as? ContextPreloadable {
            contextPreloadable.contextPreload()
        }
        if let contextAwareContainer = obj as? ContextAwareContainer {
            for child in contextAwareContainer.childObjects {
                self.wrap(child)
            }
        }
        if let viewController = obj as? UIViewController {
            self.wrap(viewController.view)
        }
        self.setupContextAwareIfNecessary(obj)
        return obj
    }

    private func setupContextAwareIfNecessary(_ obj: Any) {
        guard let contextAware = obj as? ContextAware, contextAware.contextToken == nil else { return }

        let contextToken = self.generateToken()
        contextToken.contextAware = contextAware
        contextAware.contextToken = contextToken
        contextAware.contextAvailable()
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
    private weak var contextAware: ContextAware?

    private init(context: Context) {
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

private extension UIStoryboard {

    var hasContextWrapper: Bool {
        return (self as? ConfigurableStoryboard)?.delegate is StoryboardContextWrapper
    }
}

// MARK: - ContextAware

public protocol ContextAware: class {

    func contextAvailable()
}

private struct ContextAwareKeys {

    static var contextTokenKey: Void = ()
}

extension ContextAware {

    var contextToken: ContextToken? {
        get { return AssociatedUtils.retrieveValue(for: self, key: &ContextAwareKeys.contextTokenKey) }
        set { AssociatedUtils.store(for: self, key: &ContextAwareKeys.contextTokenKey, storage: .strongOrNil(object: newValue)) }
    }
}

public extension ContextAware {

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

public extension ContextAware where Self: UIViewController {

    /**
     Instantiate a view controller from the view controller's storyboard. The `UIViewController` subclass you're
     instantiating must have the same storyboard tag as its class name, such that the tag is the
     result of executing `String(Controller)`.

     - returns: The new `UIViewController` instance
     */
    public func viewControllerFromStoryboard<Controller: UIViewController>() -> Controller? {
        guard let storyboard = self.storyboard else { return nil }
        let controller = storyboard.instantiateViewController(withIdentifier: String(Controller.self)) as! Controller
        if !storyboard.hasContextWrapper {
            self.context.wrap(controller)
        }
        return controller
    }
}

// MARK: - ContextAwareContainer

public protocol ContextAwareContainer {

    var childObjects: [Any] { get }
}

extension UIViewController: ContextAwareContainer {

    public var childObjects: [Any] {
        return self.childViewControllers.map({ $0 })
    }
}

extension UIView: ContextAwareContainer {

    public var childObjects: [Any] {
        return self.subviews.map({ $0 })
    }
}

public protocol ContextPreloadable {

    func contextPreload()
}

extension UIViewController: ContextPreloadable {

    public func contextPreload() {
        guard let contextAware = self as? ContextAware, contextAware.contextToken == nil else { return }
        self.loadViewIfNeeded()
    }
}

extension UIView: ContextPreloadable {

    public func contextPreload() {
        guard let contextAware = self as? ContextAware, contextAware.contextToken == nil else { return }
        guard let inflatable = self as? UINibViewInflatable else { return }
        let view = inflatable.inflateView()
        self.addAndConstrain(view)
    }
}

// MARK: - ContextService

public protocol ContextService: class {
    associatedtype Component

    var context: Context? { get set } // Fulfilled by extension
    var component: Component { get }

    func added(to context: Context)
    func removed(from context: Context)
}

private struct ContextServiceKeys {

    static var contextKey: Void = ()
}

public extension ContextService {

    public var context: Context? {
        get { return AssociatedUtils.retrieveValue(for: self, key: &ContextServiceKeys.contextKey) }
        set { AssociatedUtils.store(for: self, key: &ContextServiceKeys.contextKey, storage: .weakOrNil(object: newValue)) }
    }
}

public final class AnyContextService: ContextService, Hashable {

    public let baseService: AnyObject
    private let _component: () -> Any
    private let _added: (to: Context) -> Void
    private let _removed: (from: Context) -> Void

    private let _setContext: (Context?) -> Void
    private let _getContext: () -> Context?

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
        self._added = { service.added(to: $0) }
        self._removed = { service.removed(from: $0) }
        self._getContext = { service.context }
        self._setContext = { service.context = $0 }
    }

    public var component: Any {
        return self._component()
    }

    public func added(to context: Context) {
        self._added(to: context)
    }

    public func removed(from context: Context) {
        self._removed(from: context)
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
        return String(Self.self)
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
    private let _serviceID: () -> String
    private let _equal: (to: AnyContextServiceTag) -> Bool
    private let _hashValue: () -> Int

    public init?<Tag: ContextServiceTag>(optionalTag tag: Tag?) {
        guard let tag = tag else { return nil }
        self.init(tag: tag)
    }

    public init<Tag: ContextServiceTag>(tag: Tag) {
        self.tag = tag
        self._serviceID = { tag.serviceID }
        self._equal = { ($0.tag as? Tag) == tag }
        self._hashValue = { tag.hashValue }
    }

    public var serviceID: String {
        return self._serviceID()
    }

    public var hashValue: Int {
        return self._hashValue()
    }

    public static func == (lhs: AnyContextServiceTag, rhs: AnyContextServiceTag) -> Bool {
        return lhs._equal(to: rhs)
    }
}

public protocol ContextServiceAware: class {

    func contextDispatched(_ serviceEvent: Context.ServiceEvent)
}
