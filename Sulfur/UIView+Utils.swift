/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE', which is part of this source code package.
 */

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

    public static func edgeInsetsBlock(_ insets: UIEdgeInsets) -> (LayoutProxy, LayoutProxy) -> Void { return { containerView, view in
        view.left == containerView.left + insets.left
        view.top == containerView.top + insets.top
        view.right == containerView.right - insets.right
        view.bottom == containerView.bottom - insets.bottom
    } }

    public static func edgeInsetsZeroBlock() -> (LayoutProxy, LayoutProxy) -> Void {
        return self.edgeInsetsBlock(.zero)
    }

    @discardableResult
    public func constrain(_ view: UIView, replace group: ConstraintGroup = ConstraintGroup(), with insets: UIEdgeInsets = .zero) -> ConstraintGroup {
        return Cartography.constrain(self, view, replace: group, block: UIView.edgeInsetsBlock(insets))
    }

    @discardableResult
    public func addAndConstrain(_ view: UIView, with insets: UIEdgeInsets = .zero) -> ConstraintGroup {
        view.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(view)
        return self.constrain(view, with: insets)
    }

    @discardableResult
    public func replaceAndConstrain(_ view: UIView, withBlock block: ((LayoutProxy, LayoutProxy) -> Void)) -> ConstraintGroup {
        let filteredConstraints = self.constraints.filter { constraint in
            return (constraint.firstItem === view || constraint.secondItem === view)
        }
        NSLayoutConstraint.deactivate(filteredConstraints)
        return Cartography.constrain(self, view, block: block)
    }

    @discardableResult
    public func replaceAndConstrainFirstView(block: ((LayoutProxy, LayoutProxy) -> Void)) -> ConstraintGroup {
        return self.replaceAndConstrain(self.subviews[0], withBlock: block)
    }

    @discardableResult
    public func replaceAndConstrainFirstView(with insets: UIEdgeInsets) -> ConstraintGroup {
        return self.replaceAndConstrainFirstView(block: UIView.edgeInsetsBlock(insets))
    }
}

public extension UIViewController {

    @discardableResult
    public func addAndConstrain(_ viewController: UIViewController, parentView: UIView? = nil, insets: UIEdgeInsets = .zero, performTransition: (_ complete: () -> Void) -> Void = { $0() }) -> ConstraintGroup {
        self.addChildViewController(viewController)
        let constraintGroup = (parentView ?? self.view).addAndConstrain(viewController.view, with: insets)
        performTransition() {
            viewController.didMove(toParentViewController: self)
        }
        return constraintGroup
    }

    public func fullyRemove(performTransition: (_ complete: () -> Void) -> Void =  { $0() }) {
        self.willMove(toParentViewController: nil)
        performTransition() {
            self.view.removeFromSuperview()
            self.removeFromParentViewController()
        }
    }
}

public extension UIViewController {

    public func edgeInsetsBlock(_ insets: UIEdgeInsets) -> (LayoutProxy, LayoutProxy) -> Void { return { superview, view in
        view.top == self.topLayoutGuideCartography + insets.top
        view.bottom == self.bottomLayoutGuideCartography - insets.bottom
        view.left == superview.left + insets.left
        view.right == superview.right - insets.right
    } }

    @discardableResult
    public func constrain(_ view1: UIView? = nil, to view2: UIView, with insets: UIEdgeInsets = .zero, replacing group: ConstraintGroup = ConstraintGroup()) -> ConstraintGroup {
        let view1 = view1 ?? self.view!
        return Cartography.constrain(view1, view2, replace: group, block: self.edgeInsetsBlock(insets))
    }
}
