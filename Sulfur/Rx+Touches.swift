//
// This file is subject to the terms and conditions defined in
// file 'LICENSE', which is part of this source code package.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass
import RxSwift
import RxCocoa
import RxSwiftExt
import RxGesture

public final class TouchGestureRecognizer: UIGestureRecognizer, UIGestureRecognizerDelegate {

    public struct TouchEvent: OptionSet {

        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let down        = TouchEvent(rawValue: 1 << 0)
        public static let downRepeat  = TouchEvent(rawValue: 1 << 1)
        public static let dragInside  = TouchEvent(rawValue: 1 << 2)
        public static let dragOutside = TouchEvent(rawValue: 1 << 3)
        public static let dragEnter   = TouchEvent(rawValue: 1 << 4)
        public static let dragExit    = TouchEvent(rawValue: 1 << 5)
        public static let upInside    = TouchEvent(rawValue: 1 << 6)
        public static let upOutside   = TouchEvent(rawValue: 1 << 7)
        public static let cancel      = TouchEvent(rawValue: 1 << 8)

        public static let none: TouchEvent = []
        public static let all: TouchEvent = [
            .down,
            .downRepeat,
            .dragInside,
            .dragOutside,
            .dragEnter,
            .dragExit,
            .upInside,
            .upOutside,
            .cancel
        ]
    }

    public struct TouchState: OptionSet {

        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let enabled     = TouchState(rawValue: 1 << 0)
        public static let selected    = TouchState(rawValue: 1 << 1)
        public static let highlighted = TouchState(rawValue: 1 << 2)

        public static let none: TouchState = []
        public static let all: TouchState = [
            .enabled,
            .selected,
            .highlighted
        ]
    }

    private final class NopTarget {

        @objc fileprivate func nop(_ _: Any) { }
    }

    private var nop: NopTarget!

    private var touchStateVar = Variable<TouchState>(.enabled)
    private var touchEventVar = Variable<TouchEvent>([])

    public let touchStates: Observable<TouchState>
    public let touchEvents: Observable<TouchEvent>

    public private(set) var isTouchInside = false
    public private(set) var isTracking = false

    public init() {
        self.touchStates = self.touchStateVar.asObservable().distinctUntilChanged()
        self.touchEvents = self.touchEventVar.asObservable().distinctUntilChanged()
        let nop = NopTarget()
        super.init(target: nop, action: #selector(nop.nop(_:)))
        self.nop = nop

        self.delegate = self
        self.cancelsTouchesInView = true
    }

    @objc private func nop(_ r: Any) { }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        let shouldRecognizeSimultaneously = !(otherGestureRecognizer is UIPanGestureRecognizer)
        if !shouldRecognizeSimultaneously {
            self.cancelTouches([])
        }
        return shouldRecognizeSimultaneously
    }

    override public func canPrevent(_ preventedGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }

    override public func canBePrevented(by preventingGestureRecognizer: UIGestureRecognizer) -> Bool {
        return preventingGestureRecognizer is UIPanGestureRecognizer
    }

    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)

        self.isTouchInside = true
        self.isTracking = true
        let touchEvent: TouchEvent = touches.count > 1 ? [.down, .downRepeat] : .down
        self.touchEventVar.value = touchEvent
        self.touchStateVar.value.insert(.highlighted)
    }

    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        guard let view = self.view else { return }
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

        self.touchEventVar.value = touchEvent

        if self.isTouchInside {
            self.touchStateVar.value.insert(.highlighted)
        } else {
            self.touchStateVar.value.remove(.highlighted)
        }
    }

    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        guard let view = self.view else { return }
        guard let touch = touches.first else { return }

        self.isTouchInside = view.point(inside: touch.location(in: view), with: event)
        let touchEvent: TouchEvent = self.isTouchInside ? .upInside : .upOutside
        self.isTracking = false
        self.isTouchInside = false

        self.touchEventVar.value = touchEvent
        self.touchStateVar.value.remove(.highlighted)
    }

    override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        self.cancelTouches(touches, withEvent: event)
    }

    private func cancelTouches(_ touches: Set<UITouch>, withEvent event: UIEvent? = nil) {
        let touchEvent: TouchEvent = .cancel
        self.isTracking = false
        self.isTouchInside = false
        self.touchEventVar.value = touchEvent
        self.touchStateVar.value.remove(.highlighted)
    }
}

public extension Reactive where Base: UIView {

    public typealias TouchEvent = TouchGestureRecognizer.TouchEvent
    public typealias TouchState = TouchGestureRecognizer.TouchState

    public func touches(_ event: TouchEvent) -> Observable<TouchEvent> {
        let view = self.base
        let gestureRecognizer = TouchGestureRecognizer()
        view.addGestureRecognizer(gestureRecognizer)
        return gestureRecognizer
            .touchEvents
            .filter({ event == .none || !event.intersection($0).isEmpty })
            .do(onDispose: { [weak view] in
                view?.removeGestureRecognizer(gestureRecognizer)
            })
    }

    public func state(_ state: TouchState) -> Observable<TouchState> {
        let view = self.base
        let gestureRecognizer = TouchGestureRecognizer()
        view.addGestureRecognizer(gestureRecognizer)
        return gestureRecognizer
            .touchStates
            .filter({ state == .none || !state.intersection($0).isEmpty })
            .do(onDispose: { [weak view] in
                view?.removeGestureRecognizer(gestureRecognizer)
            })
    }
}
