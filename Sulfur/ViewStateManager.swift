/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE.txt', which is part of this source code package.
 */

import UIKit
import UIKit.UIGestureRecognizerSubclass

// MARK: - ViewStateManager

public final class ViewStateManager {

    public typealias TouchEventCallback = (ViewStateManager, UIView, TouchEvent) -> Void

    public struct TouchEvent: OptionSet {

        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let down = TouchEvent(rawValue: 1 << 0)
        public static let downRepeat = TouchEvent(rawValue: 1 << 1)
        public static let dragInside = TouchEvent(rawValue: 1 << 2)
        public static let dragOutside = TouchEvent(rawValue: 1 << 3)
        public static let dragEnter = TouchEvent(rawValue: 1 << 4)
        public static let dragExit = TouchEvent(rawValue: 1 << 5)
        public static let upInside = TouchEvent(rawValue: 1 << 6)
        public static let upOutside = TouchEvent(rawValue: 1 << 7)
        public static let cancel = TouchEvent(rawValue: 1 << 8)
    }

    public typealias StateEventCallback = (ViewStateManager, UIView, State, State) -> Void

    public struct State: OptionSet {

        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let enabled = State(rawValue: 1 << 0)
        public static let selected = State(rawValue: 1 << 1)
        public static let highlighted = State(rawValue: 1 << 2)
    }

    public typealias GestureEventCallback = (ViewStateManager, UIView, GestureEvent) -> Void

    public enum GestureEvent {

        case tap
        case longPress

        var isTap: Bool {
            switch self {
            case .tap:
                return true
            default:
                return false
            }
        }

        var isLongPress: Bool {
            switch self {
            case .longPress:
                return true
            default:
                return false
            }
        }
    }

    public final class Token: Hashable {

        fileprivate enum Action {

            case touch(event: TouchEvent, callback: TouchEventCallback)
            case gesture(event: GestureEvent, callback: GestureEventCallback)
            case state(callback: StateEventCallback)

            var gestureEvent: GestureEvent? {
                switch self {
                case .gesture(let event, _):
                    return event
                default:
                    return nil
                }
            }
        }

        fileprivate weak var stateManager: ViewStateManager?
        fileprivate let action: Action

        fileprivate init(stateManager: ViewStateManager, touchEvent: TouchEvent, callback: @escaping TouchEventCallback) {
            self.stateManager = stateManager
            self.action = .touch(event: touchEvent, callback: callback)
        }

        fileprivate init(stateManager: ViewStateManager, gestureEvent: GestureEvent, callback: @escaping GestureEventCallback) {
            self.stateManager = stateManager
            self.action = .gesture(event: gestureEvent, callback: callback)
        }

        fileprivate init(stateManager: ViewStateManager, callback: @escaping StateEventCallback) {
            self.stateManager = stateManager
            self.action = .state(callback: callback)
        }

        deinit {
            self.unsubscribe()
        }

        public func store() {
            guard !self.isStored else { return }
            self.stateManager?.storedRegistry.insert(self)
        }

        public func removeFromStore() {
            guard self.isStored else { return }
            let _ = self.stateManager?.storedRegistry.remove(self)
        }

        public var isStored: Bool {
            return self.stateManager?.storedRegistry.contains(self) ?? false
        }

        public func unsubscribe() {
            guard self.isSubscribed else { return }
            self.stateManager?.unsubscribe(with: self)
        }

        public var isSubscribed: Bool {
            return self.stateManager?.weakRegistry.contains(WeakReference(referent: self)) ?? false
        }

        public var hashValue: Int {
            return ObjectIdentifier(self).hashValue
        }

        public static func == (lhs: Token, rhs: Token) -> Bool {
            return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
        }
    }

    fileprivate final class TouchGestureRecognizer: UIGestureRecognizer, UIGestureRecognizerDelegate {

        weak var stateManager: ViewStateManager?

        init(stateManager: ViewStateManager) {
            self.stateManager = stateManager
            super.init(target: stateManager, action: #selector(stateManager.handleGestureRecognizer(_:)))
            self.delegate = self
        }

        var isTouchInside = false
        var isTracking = false

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }

        override func canPrevent(_ preventedGestureRecognizer: UIGestureRecognizer) -> Bool {
            return false
        }

        override func canBePrevented(by preventingGestureRecognizer: UIGestureRecognizer) -> Bool {
            return false
        }

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
            super.touchesBegan(touches, with: event)
            guard let stateManager = self.stateManager, stateManager.view != nil else { return }

            self.isTouchInside = true
            self.isTracking = true
            let touchEvent: TouchEvent = touches.count > 1 ? [.down, .downRepeat] : .down
            stateManager.dispatch(touchEvent)
            stateManager.state.insert(.highlighted)
        }

        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
            super.touchesMoved(touches, with: event)
            guard let stateManager = self.stateManager, let view = stateManager.view else { return }
            guard let touch = touches.first else { return }

            let wasTouchInside = self.isTouchInside
            self.isTouchInside = view.point(inside: touch.location(in: view), with: event)

            let touchEvent: TouchEvent = {
                var touchEvent: TouchEvent = self.isTouchInside ? .dragInside : .dragOutside
                if wasTouchInside != self.isTouchInside {
                    touchEvent.insert(self.isTouchInside ? .dragEnter : .dragExit)
                }
                return touchEvent
            }()

            stateManager.dispatch(touchEvent)

            if self.isTouchInside {
                stateManager.state.insert(.highlighted)
            } else {
                stateManager.state.remove(.highlighted)
            }
        }

        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
            super.touchesEnded(touches, with: event)
            guard let stateManager = self.stateManager, let view = stateManager.view else { return }
            guard let touch = touches.first else { return }

            self.isTouchInside = view.point(inside: touch.location(in: view), with: event)
            let touchEvent: TouchEvent = self.isTouchInside ? .upInside : .upOutside
            self.isTracking = false
            self.isTouchInside = false

            stateManager.dispatch(touchEvent)
            stateManager.state.remove(.highlighted)
        }

        override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
            super.touchesCancelled(touches, with: event)
            guard let stateManager = self.stateManager, stateManager.view != nil else { return }

            self.isTracking = false
            self.isTouchInside = false
            let touchEvent: TouchEvent = .cancel
            stateManager.dispatch(touchEvent)
            stateManager.state.remove(.highlighted)
        }
    }

    fileprivate dynamic func handleGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer === self.touchGestureRecognizer {
            // Do nothing
        } else if gestureRecognizer == self.tapGestureRecognizer && gestureRecognizer.state == .ended {
            self.dispatch(.tap)
        } else if gestureRecognizer == self.longPressGestureRecognizer && gestureRecognizer.state == .began {
            self.dispatch(.longPress)
        }
    }

    public fileprivate(set) weak var view: UIView?
    fileprivate var touchGestureRecognizer: TouchGestureRecognizer!
    fileprivate var tapGestureRecognizer: UITapGestureRecognizer!
    fileprivate var longPressGestureRecognizer: UILongPressGestureRecognizer!

    public var isTracking: Bool { return self.touchGestureRecognizer.isTracking }

    public init(view: UIView) {
        self.view = view
        self.touchGestureRecognizer = TouchGestureRecognizer(stateManager: self)
        view.addGestureRecognizer(self.touchGestureRecognizer)

        self.tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleGestureRecognizer(_:)))
        self.longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleGestureRecognizer(_:)))
    }

    public var state: State = .enabled {
        didSet {
            guard self.state != oldValue else { return }
            self.dispatchStateChange(from: oldValue, to: self.state)
        }
    }

    public var configuration: ViewStateManagerConfiguration? {
        willSet { self.configuration?.didDisassociate(with: self) }
        didSet { self.configuration?.didAssociate(with: self) }
    }

    fileprivate var weakRegistry: Set<WeakReference<Token>> = [] {
        didSet {
            guard let view = self.view else { return }
            view.removeGestureRecognizer(self.tapGestureRecognizer)
            view.removeGestureRecognizer(self.longPressGestureRecognizer)
            let gestureEvents = self.weakRegistry.flatMap({ $0.referent?.action.gestureEvent })
            if !gestureEvents.filter({ $0.isTap }).isEmpty {
                view.addGestureRecognizer(self.tapGestureRecognizer)
            }
            if !gestureEvents.filter({ $0.isLongPress }).isEmpty {
                view.addGestureRecognizer(self.longPressGestureRecognizer)
            }
        }
    }
    fileprivate var storedRegistry: Set<Token> = []

    public func subscribe(to touchEvent: TouchEvent, callback: @escaping TouchEventCallback) -> Token {
        let token = Token(stateManager: self, touchEvent: touchEvent, callback: callback)
        self.weakRegistry.insert(WeakReference(referent: token))
        return token
    }

    public func subscribe(to gestureEvent: GestureEvent, callback: @escaping GestureEventCallback) -> Token {
        let token = Token(stateManager: self, gestureEvent: gestureEvent, callback: callback)
        self.weakRegistry.insert(WeakReference(referent: token))
        return token
    }

    public func subscribeToStateEvent(callback: @escaping StateEventCallback) -> Token {
        let token = Token(stateManager: self, callback: callback)
        self.weakRegistry.insert(WeakReference(referent: token))
        return token
    }

    public func unsubscribe(with token: Token) {
        self.weakRegistry.remove(WeakReference(referent: token))
        self.storedRegistry.remove(token)
        token.stateManager = nil
    }

    fileprivate func dispatch(_ touchEvent: TouchEvent) {
        guard let view = self.view else { return }
        self.weakRegistry.forEach { weakToken in
            guard let token = weakToken.referent else { return }
            switch token.action {
            case .touch(let event, let callback):
                if !event.intersection(touchEvent).isEmpty {
                    callback(self, view, touchEvent)
                }

            default:
                break
            }
        }
        self.configuration?.viewStateManager(self, didDispatch: touchEvent)
    }

    fileprivate func dispatch(_ gestureEvent: GestureEvent) {
        guard let view = self.view else { return }
        self.weakRegistry.forEach { weakToken in
            guard let token = weakToken.referent else { return }
            switch token.action {
            case .gesture(let event, let callback):
                if event == gestureEvent {
                    callback(self, view, event)
                }

            default:
                break
            }
        }
        self.configuration?.viewStateManager(self, didDispatch: gestureEvent)
    }

    fileprivate func dispatchStateChange(from fromState: State, to toState: State) {
        guard let view = self.view else { return }
        self.weakRegistry.forEach { weakToken in
            guard let token = weakToken.referent else { return }
            switch token.action {
            case .state(let callback):
                callback(self, view, fromState, toState)

            default:
                break
            }
        }
        self.configuration?.viewStateManager(self, didDispatchStateChangeFrom: fromState, to: toState)
    }
}

public extension ViewStateManager {

    fileprivate func includeState(_ newState: State, include: Bool) {
        if include {
            self.state.insert(newState)
        } else {
            self.state.remove(newState)
        }
    }

    public func toggle(_ state: State) {
        self.state.formSymmetricDifference(state)
    }

    public var isEnabled: Bool {
        get { return self.state.contains(.enabled) }
        set { self.includeState(.enabled, include: newValue) }
    }

    public var isSelected: Bool {
        get { return self.state.contains(.selected) }
        set { self.includeState(.selected, include: newValue) }
    }

    public var isHighlighted: Bool {
        get { return self.state.contains(.highlighted) }
        set { self.includeState(.highlighted, include: newValue) }
    }
}

public protocol ViewStateManagerConfiguration: class {

    var viewStateManagerFn: (() -> ViewStateManager?)? { get set }
    func didAssociate(with viewStateManager: ViewStateManager)
    func didDisassociate(with viewStateManager: ViewStateManager)

    func viewStateManager(_ viewStateManager: ViewStateManager, didDispatch touchEvent: ViewStateManager.TouchEvent)
    func viewStateManager(_ viewStateManager: ViewStateManager, didDispatch gestureEvent: ViewStateManager.GestureEvent)
    func viewStateManager(_ viewStateManager: ViewStateManager, didDispatchStateChangeFrom fromState: ViewStateManager.State, to toState: ViewStateManager.State)
}

fileprivate struct ViewStateManagerConfigurationKeys {

    static var stateManagerKey: UInt8 = 0
}

public extension ViewStateManagerConfiguration {

    public var viewStateManager: ViewStateManager? {
        return self.viewStateManagerFn?()
    }
}

private let contextual_viewStateManagerKey = "Sulfur.ViewStateManager"

public extension Contextual where Self: UIView {

    fileprivate var _stateManager: ViewStateManager? {
        get { return self.retrieveValue(forKey: contextual_viewStateManagerKey) }
        set { self.store(key: contextual_viewStateManagerKey, storage: .strongOrNil(object: newValue)) }
    }
    
    public var stateManager: ViewStateManager {
        guard let stateManager = self._stateManager else {
            let newManager = ViewStateManager(view: self)
            self._stateManager = newManager
            return newManager
        }
        return stateManager
    }
}

public extension Contextual {

    public func stateManager(for view: UIView) -> ViewStateManager {
        let key = "contextual_viewStateManagerKey/\(view.hashValue)"
        guard let stateManager: ViewStateManager = self.retrieveValue(forKey: key) else {
            let stateManager = ViewStateManager(view: view)
            self.store(key: key, storage: .strong(object: stateManager))
            return stateManager
        }
        return stateManager
    }
}
