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
        return [self.left, self.top, self.right, self.bottom].hashComponent
    }
}

public extension UIView {

    public static func edgeInsetsBlock(insets: UIEdgeInsets) -> ((LayoutProxy, LayoutProxy) -> Void) { return { (containerView, view) in
        view.left == containerView.left + insets.left
        view.top == containerView.top + insets.top
        view.right == containerView.right - insets.right
        view.bottom == containerView.bottom - insets.bottom
    } }

    public static func edgeInsetsZeroBlock() -> ((LayoutProxy, LayoutProxy) -> Void) {
        return self.edgeInsetsBlock(UIEdgeInsetsZero)
    }

    public func constrainView(view: UIView, withInsets insets: UIEdgeInsets = UIEdgeInsetsZero) -> ConstraintGroup {
        return constrain(self, view, block: UIView.edgeInsetsBlock(insets))
    }

    public func addAndConstrainView(view: UIView, withInsets insets: UIEdgeInsets = UIEdgeInsetsZero) -> ConstraintGroup {
        view.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(view)
        return self.constrainView(view, withInsets: insets)
    }

    public func replaceAndConstrain(view view: UIView, withBlock block: ((LayoutProxy, LayoutProxy) -> Void)) -> ConstraintGroup {
        let filteredConstraints = self.constraints.filter { constraint in
            return (constraint.firstItem === view || constraint.secondItem === view)
        }
        NSLayoutConstraint.deactivateConstraints(filteredConstraints)
        return constrain(self, view, block: block)
    }

    public func replaceAndConstrainFirstView(block block: ((LayoutProxy, LayoutProxy) -> Void)) -> ConstraintGroup {
        return self.replaceAndConstrain(view: self.subviews[0], withBlock: block)
    }

    public func replaceAndConstrainFirstView(withInsets insets: UIEdgeInsets) -> ConstraintGroup {
        return self.replaceAndConstrainFirstView(block: UIView.edgeInsetsBlock(insets))
    }
}

public extension UIViewController {

    public func removeSelf() {
        self.removeSelf(transitionFn: { $0() })
    }

    public func removeSelf(@noescape transitionFn transitionFn: (completionFn: () -> Void) -> Void) {
        self.willMoveToParentViewController(nil)
        transitionFn() {
            self.view.removeFromSuperview()
            self.removeFromParentViewController()
        }
    }

    public func addAndConstrainChildViewController(viewController: UIViewController, withInsets insets: UIEdgeInsets = UIEdgeInsetsZero) -> ConstraintGroup {
        return self.addAndConstrainChildViewController(viewController, withInsets: insets, transitionFn: { $0() })
    }

    public func addAndConstrainChildViewController(viewController: UIViewController, withInsets insets: UIEdgeInsets = UIEdgeInsetsZero, @noescape transitionFn: (completionFn: () -> Void) -> Void) -> ConstraintGroup {
        self.addChildViewController(viewController)
        let constraintGroup = self.view.addAndConstrainView(viewController.view, withInsets: insets)
        transitionFn() {
            viewController.didMoveToParentViewController(self)
        }
        return constraintGroup
    }
}
