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

    private func setupContextAwareIfNecessary(obj: Any?) {
        guard let contextAware = obj as? ContextAware where contextAware.contextToken == nil else {
            return
        }

        let contextToken = self.generateTokenForContextAware(contextAware)
        contextToken.contextAware = contextAware
        contextAware.contextToken = contextToken
        contextAware.contextAvailable()
    }

    // MARK: Services

    public enum ServiceChange {
        case Removed
        case Added(Any)
    }

    private var services: [String: AnyObject] = [:]

    public func store < Identifier: ContextServiceIdentifier, Service where Service == Identifier.Service > (service service: Service?, forIdentifier identifier: Identifier) {
        if let existingService = self.services[Identifier.serviceId] as? Service {
            existingService.removedFrom(context: self)
            existingService.contextFn = nil
            self.dispatch(serviceChange: .Removed, forServiceId: Identifier.serviceId)
        }
        self.services[Identifier.serviceId] = service
        if let service = service {
            service.contextFn = { [weak self] in return self }
            service.addedTo(context: self)
            self.dispatch(serviceChange: .Added(service), forServiceId: Identifier.serviceId)
        }
    }

    public func service < Identifier: ContextServiceIdentifier, Service where Service == Identifier.Service > (forIdentifier identifier: Identifier) -> Service? {
        return self.services[Identifier.serviceId] as? Service
    }

    public func serviceItem < Identifier: ContextServiceIdentifier, Service where Service == Identifier.Service > (forIdentifier identifier: Identifier) -> Service.ServiceItem? {
        return self.service(forIdentifier: identifier)?.serviceItem
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

    public func wrap<Object>(obj: Object) -> Object {
        if let viewController = obj as? UIViewController {
            viewController.loadViewIfNeeded()
            self.setupContextAwareIfNecessary(viewController)
            self.wrap(viewController.view)
        } else {
            self.setupContextAwareIfNecessary(obj)
        }
        if let contextAwareContainer = obj as? ContextAwareContainer {
            contextAwareContainer.childObjects.forEach({ self.wrap($0) })
        }
        return obj
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
        context.wrap(viewController)
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

    var context: Context {
        return self.contextToken!.context
    }

    func contextWrap<Object>(@autoclosure objFn: (() -> Object)) -> Object {
        return self.context.wrap(objFn())
    }

    func newViewController<ViewController: UIViewController>() -> ViewController {
        let viewController = ViewController()
        self.context.wrap(viewController)
        return viewController
    }

    func newView<View: UIView>() -> View {
        let view = View()
        self.context.wrap(view)
        return view
    }
}

public extension ContextAware where Self: UIViewController {

    /**
     Instantiate a view controller from the view controller's storyboard. The `UIViewController` subclass you're
     instantiating must have the same storyboard identifier as its class name, such that the identifier is the
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

// MARK: - ContextService

public protocol ContextServiceIdentifier {
    associatedtype Service: ContextService
}

public extension ContextServiceIdentifier {

    static var serviceId: String {
        return "\(self)"
    }
}

public protocol ContextService: class {
    associatedtype ServiceItem

    var contextFn: (() -> Context?)? { get set }
    var serviceItem: ServiceItem { get }

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
