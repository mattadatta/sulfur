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

    public typealias StateEventCallback = (ViewStateManager, UIView, TouchEvent) -> Void

    public struct State: OptionSet {

        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let enabled = State(rawValue: 1 << 0)
        public static let selected = State(rawValue: 1 << 1)
        public static let highlighted = State(rawValue: 1 << 2)
    }

    public final class Token: Hashable {

        private enum Action {
            case touch(TouchEvent, TouchEventCallback)
            case state(State, StateEventCallback)
        }

        private weak var stateManager: ViewStateManager?
        public let touchEvent: TouchEvent
        public let callback: TouchEventCallback

        private init(stateManager: ViewStateManager, touchEvent: TouchEvent, callback: TouchEventCallback) {
            self.stateManager = stateManager
            self.touchEvent = touchEvent
            self.callback = callback
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

    private final class GestureRecognizer: UIGestureRecognizer, UIGestureRecognizerDelegate {

        unowned let stateManager: ViewStateManager

        init(stateManager: ViewStateManager) {
            self.stateManager = stateManager
            super.init(target: stateManager, action: #selector(stateManager.handleDefault(_:)))
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
            guard self.stateManager.view != nil else { return }

            self.isTouchInside = true
            self.isTracking = true
            let touchEvent: TouchEvent = touches.count > 1 ? [.down, .downRepeat] : .down
            self.stateManager.dispatch(touchEvent)
            self.stateManager.state.insert(.highlighted)
        }

        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
            super.touchesMoved(touches, with: event)
            guard let view = self.stateManager.view else { return }
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

            self.stateManager.dispatch(touchEvent)

            if self.isTouchInside {
                self.stateManager.state.insert(.highlighted)
            } else {
                self.stateManager.state.remove(.highlighted)
            }
        }

        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
            super.touchesEnded(touches, with: event)
            guard let view = self.stateManager.view else { return }
            guard let touch = touches.first else { return }

            self.isTouchInside = view.point(inside: touch.location(in: view), with: event)
            let touchEvent: TouchEvent = self.isTouchInside ? .upInside : .upOutside
            self.isTracking = false
            self.isTouchInside = false

            self.stateManager.dispatch(touchEvent)
            self.stateManager.state.remove(.highlighted)
        }

        override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
            super.touchesCancelled(touches, with: event)
            guard self.stateManager.view != nil else { return }

            self.isTracking = false
            self.isTouchInside = false
            let touchEvent: TouchEvent = .cancel
            self.stateManager.dispatch(touchEvent)
            self.stateManager.state.remove(.highlighted)
        }
    }

    private dynamic func handleDefault(_ gestureRecognizer: UIGestureRecognizer) { }

    public private(set) weak var view: UIView?
    private var gestureRecognizer: GestureRecognizer!

    public var isTracking: Bool { return self.gestureRecognizer.isTracking }

    public init(view: UIView) {
        self.view = view
        self.gestureRecognizer = GestureRecognizer(stateManager: self)
        view.addGestureRecognizer(self.gestureRecognizer)
    }

    public var state: State = .enabled {
        didSet {
            guard self.state != oldValue else { return }
            self.dispatchStateChange(from: oldValue, to: self.state)
        }
    }

    private var weakRegistry: Set<WeakReference<Token>> = []
    private var storedRegistry: Set<Token> = []

    public func subscribe(to touchEvent: TouchEvent, with block: TouchEventCallback) -> Token {
        let token = Token(stateManager: self, touchEvent: touchEvent, callback: block)
        self.weakRegistry.insert(WeakReference(referent: token))
        return token
    }

    public func unsubscribe(with token: Token) {
        self.weakRegistry.remove(WeakReference(referent: token))
        self.storedRegistry.remove(token)
        token.stateManager = nil
    }

    private func dispatch(_ touchEvent: TouchEvent) {
        guard let view = self.view else { return }
        self.weakRegistry.forEach { weakToken in
            guard let token = weakToken.referent else { return }
            if !token.touchEvent.intersection(touchEvent).isEmpty {
                token.callback(self, view, touchEvent)
            }
        }
    }

    private func dispatchStateChange(from fromState: State, to toState: State) {
    }
}

public protocol ViewStateManagerConfiguration: class {

    func viewStateManager(_ viewStateManager: ViewStateManager, didDispatch touchEvent: ViewStateManager.TouchEvent)
    func viewStateManager(_ viewStateManager: ViewStateManager, didDispatchStateChangeFrom fromState: ViewStateManager.State, to toState: ViewStateManager.State)
}

private struct ViewStateManagerConfigurationKeys {

    static var stateManagerKey: Void = ()
}

public extension ViewStateManagerConfiguration {

    public private(set) var viewStateManager: ViewStateManager? {
        get { return objc_getAssociatedObject(self, &ViewStateManagerConfigurationKeys.stateManagerKey) as? ViewStateManager }
        set { objc_setAssociatedObject(self, &ViewStateManagerConfigurationKeys.stateManagerKey, newValue, .OBJC_ASSOCIATION_COPY) }
    }
}

public extension UIView {

    private struct ViewStateManagerKeys {

        static var stateManagerKey: Void = ()
    }

    private var _stateManager: ViewStateManager? {
        get { return objc_getAssociatedObject(self, &ViewStateManagerKeys.stateManagerKey) as? ViewStateManager }
        set { objc_setAssociatedObject(self, &ViewStateManagerKeys.stateManagerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
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
