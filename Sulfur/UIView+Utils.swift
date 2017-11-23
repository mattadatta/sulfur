//
// This file is subject to the terms and conditions defined in
// file 'LICENSE', which is part of this source code package.
//

import UIKit
import Cartography

public extension UIEdgeInsets {

    public init(size: CGFloat) {
        self.init(top: size, left: size, bottom: size, right: size)
    }

    public init(widths: CGFloat, heights: CGFloat) {
        self.init(top: heights, left: widths, bottom: heights, right: widths)
    }

    public var height: CGFloat {
        return self.top + self.bottom
    }

    public var width: CGFloat {
        return self.left + self.right
    }
}

public func + (lhs: UIEdgeInsets, rhs: UIEdgeInsets) -> UIEdgeInsets {
    return UIEdgeInsets(
        top: lhs.top + rhs.top,
        left: lhs.left + rhs.left,
        bottom: lhs.bottom + rhs.bottom,
        right: lhs.right + rhs.right)
}

extension UIEdgeInsets: Hashable {

    public var hashValue: Int {
        return Hasher()
            .adding(part: self.left)
            .adding(part: self.top)
            .adding(part: self.right)
            .adding(part: self.bottom)
            .hashValue
    }
}

public extension UIView {

    public struct SafeAreaEdge: OptionSet {

        public let rawValue: UInt16

        public init(rawValue: RawValue) {
            self.rawValue = rawValue
        }

        public static let top       = SafeAreaEdge(rawValue: 1 << 0)
        public static let bottom    = SafeAreaEdge(rawValue: 1 << 1)
        public static let leading   = SafeAreaEdge(rawValue: 1 << 2)
        public static let trailing  = SafeAreaEdge(rawValue: 1 << 3)
    }

    public static func edgeInsetsBlock(_ insets: UIEdgeInsets, safeAreaEdges: SafeAreaEdge) -> (ViewProxy, ViewProxy) -> Void { return { containerView, view in
        if safeAreaEdges.contains(.leading) {
            view.leading == containerView.safeAreaLayoutGuide.leading + insets.left
        } else {
            view.leading == containerView.leading + insets.left
        }
        if safeAreaEdges.contains(.top) {
            view.top == containerView.safeAreaLayoutGuide.top + insets.top
        } else {
            view.top == containerView.top + insets.top
        }
        if safeAreaEdges.contains(.trailing) {
            view.trailing == containerView.safeAreaLayoutGuide.trailing - insets.right
        } else {
            view.trailing == containerView.trailing - insets.right
        }
        if safeAreaEdges.contains(.bottom) {
            view.bottom == containerView.safeAreaLayoutGuide.bottom - insets.bottom
        } else {
            view.bottom == containerView.bottom - insets.bottom
        }
    } }

    public static func edgeInsetsZeroBlock(safeAreaEdges: SafeAreaEdge = []) -> (ViewProxy, ViewProxy) -> Void {
        return self.edgeInsetsBlock(.zero, safeAreaEdges: safeAreaEdges)
    }

    @discardableResult
    public func constrainView(_ view: UIView, replace group: ConstraintGroup = ConstraintGroup(), insets: UIEdgeInsets = .zero, safeAreaEdges: SafeAreaEdge = []) -> ConstraintGroup {
        return constrain(self, view, replace: group, block: UIView.edgeInsetsBlock(insets, safeAreaEdges: safeAreaEdges))
    }

    @discardableResult
    public func addAndConstrainView(_ view: UIView, insets: UIEdgeInsets = .zero, safeAreaEdges: SafeAreaEdge = []) -> ConstraintGroup {
        self.addSubview(view)
        return self.constrainView(view, insets: insets, safeAreaEdges: safeAreaEdges)
    }

    @discardableResult
    public func addAndConstrainView(_ view: UIView, block: (ViewProxy, ViewProxy) -> Void) -> ConstraintGroup {
        self.addSubview(view)
        return constrain(self, view, block: block)
    }

    @discardableResult
    public func replaceAndConstrainView(_ view: UIView, withBlock block: ((ViewProxy, ViewProxy) -> Void)) -> ConstraintGroup {
        let filteredConstraints = self.constraints.filter { constraint in
            return (constraint.firstItem === view || constraint.secondItem === view)
        }
        NSLayoutConstraint.deactivate(filteredConstraints)
        return constrain(self, view, block: block)
    }

    @discardableResult
    public func replaceAndConstrainFirstView(block: ((ViewProxy, ViewProxy) -> Void)) -> ConstraintGroup {
        return self.replaceAndConstrainView(self.subviews[0], withBlock: block)
    }

    @discardableResult
    public func replaceAndConstrainFirstView(insets: UIEdgeInsets, safeAreaEdges: SafeAreaEdge = []) -> ConstraintGroup {
        return self.replaceAndConstrainFirstView(block: UIView.edgeInsetsBlock(insets, safeAreaEdges: safeAreaEdges))
    }

    @discardableResult
    public func constrainView(width: CGFloat, height: CGFloat) -> ConstraintGroup {
        return constrain(self) { view in
            view.width == width
            view.height == height
        }
    }
}

public extension UIViewController {

    public typealias SafeAreaEdge = UIView.SafeAreaEdge

    @discardableResult
    public func addAndConstrain(
        _ viewController: UIViewController,
        parentView: UIView? = nil,
        insets: UIEdgeInsets = .zero,
        safeAreaEdges: SafeAreaEdge = [],
        performTransition: ((@escaping () -> Void) -> Void)? = nil)
        -> ConstraintGroup
    {
        self.addChildViewController(viewController)

        let parentView = parentView ?? self.view!
        parentView.addSubview(viewController.view)
        let constraintGroup = parentView.constrainView(
            viewController.view,
            insets: insets,
            safeAreaEdges: safeAreaEdges)

        if let performTransition = performTransition {
            performTransition() {
                viewController.didMove(toParentViewController: self)
            }
        } else {
            viewController.didMove(toParentViewController: self)
        }

        return constraintGroup
    }

    public func removeFullyFromParent(performTransition: ((_ complete: () -> Void) -> Void)? = nil) {
        self.willMove(toParentViewController: nil)

        if let performTransition = performTransition {
            //self.beginAppearanceTransition(false, animated: true)
            performTransition() {
                self.view.removeFromSuperview()
                //self.endAppearanceTransition()
                self.removeFromParentViewController()
            }
        } else {
            //self.beginAppearanceTransition(false, animated: false)
            self.view.removeFromSuperview()
            //self.endAppearanceTransition()
            self.removeFromParentViewController()
        }
    }
}
