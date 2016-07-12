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

    private var contextTokens: Set<WeakReference<ContextToken>> = [] {
        didSet {
            self.contextTokens = Set(self.contextTokens.filter({ $0.isNotNil }))
        }
    }

    private var unwrappedTokens: Set<ContextToken> {
        return Set(self.contextTokens.flatMap({ $0.referent }))
    }

    private func generateTokenForContextAware(contextAware: ContextAware) -> ContextToken {
        let token = ContextToken(context: self)
        self.contextTokens.insert(WeakReference(referent: token))
        return token
    }

    private func removeToken(token: ContextToken) {
        self.contextTokens = Set(self.contextTokens.filter({ $0.referent != token }))
    }

    // MARK: Services

    public enum ServiceChange {
        case Removed
        case Added(Any)
    }

    private var services: [String: AnyObject] = [:]

    public func store < Tag: ContextServiceTag, Service where Service == Tag.Service >
    (service service: Service?, forTag tag: Tag)
    {
        if let existingService = self.services[tag.computedServiceId] as? Service {
            existingService.removedFrom(context: self)
            existingService.contextFn = nil
            self.dispatch(serviceChange: .Removed, forServiceId: tag.computedServiceId)
        }
        self.services[tag.computedServiceId] = service
        if let service = service {
            service.contextFn = { [weak self] in return self }
            service.addedTo(context: self)
            self.dispatch(serviceChange: .Added(service), forServiceId: tag.computedServiceId)
        }
    }

    func rawService < Tag: ContextServiceTag, Service where Service == Tag.Service > (forTag tag: Tag) -> Service? {
        return self.services[tag.computedServiceId] as? Service
    }

    public func service < Tag: ContextServiceTag, Service where Service == Tag.Service > (forTag tag: Tag) -> Service.Component? {
        return self.rawService(forTag: tag)?.component
    }

    private func dispatch(serviceChange serviceChange: ServiceChange, forServiceId serviceId: String) {
        self.unwrappedTokens.forEach { token in
            guard let contextServiceAware = token.contextAware as? ContextServiceAware else {
                return
            }
            contextServiceAware.contextDispatched(serviceChange: serviceChange, forServiceId: serviceId)
        }
    }

    // MARK: Wrapping

    public func wrap<Object>(@autoclosure objFn: () -> Object) -> Object {
        let obj = objFn()
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

    private func setupContextAwareIfNecessary(obj: Any) {
        guard let contextAware = obj as? ContextAware where contextAware.contextToken == nil else {
            return
        }

        let contextToken = self.generateTokenForContextAware(contextAware)
        contextToken.contextAware = contextAware
        contextAware.contextToken = contextToken
        contextAware.contextAvailable()
    }

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
        self.context.removeToken(self)
    }

    // MARK: Hashable conformance

    public var hashValue: Int {
        return ObjectIdentifier(self).hashValue
    }
}

public func == (lhs: ContextToken, rhs: ContextToken) -> Bool {
    return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
}

// MARK: - StoryboardContextWrapper

public final class StoryboardContextWrapper: NSObject, ConfigurableStoryboardDelegate {

    public let context: Context

    public init(context: Context) {
        self.context = context
    }

    public func configureViewController(viewController: UIViewController) {
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

    var contextToken: ContextToken? { get set }
    func contextAvailable()
}

public extension ContextAware {

    public var context: Context {
        return self.contextToken!.context
    }

    public func contextWrap<Object>(@autoclosure objFn: () -> Object) -> Object {
        return self.context.wrap(objFn)
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
        guard let storyboard = self.storyboard else {
            return nil
        }
        let controller = storyboard.instantiateViewControllerWithIdentifier(String(Controller)) as! Controller
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
        guard let contextAware = self as? ContextAware where contextAware.contextToken == nil else { return }
        self.loadViewIfNeeded()
    }
}

extension UIView: ContextPreloadable {

    public func contextPreload() {
        guard let contextAware = self as? ContextAware where contextAware.contextToken == nil else { return }
        guard let inflatable = self as? UINibViewInflatable else { return }
        let view = inflatable.inflateView()
        self.addAndConstrainView(view)
    }
}

// MARK: - ContextService

public protocol ContextServiceTag {
    associatedtype Service: ContextService
    var serviceId: String? { get }
}

public extension ContextServiceTag {

    public var computedServiceId: String {
        return self.serviceId ?? String(Self)
    }
}

public protocol ContextService: class {
    associatedtype Component

    var contextFn: (() -> Context?)? { get set }
    var component: Component { get }

    func addedTo(context context: Context)
    func removedFrom(context context: Context)
}

public extension ContextService {

    var context: Context? {
        return self.contextFn?()
    }
}

public protocol ContextServiceAware: class {

    func contextDispatched(serviceChange serviceChange: Context.ServiceChange, forServiceId serviceId: String)
}
