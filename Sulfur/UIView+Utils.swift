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
        var hash = Float(self.left).hashValue
        hash = hash ^ 31 + Float(self.top).hashValue
        hash = hash ^ 31 + Float(self.right).hashValue
        hash = hash ^ 31 + Float(self.bottom).hashValue
        return hash
    }
}

public extension UIView {

    public static func edgeInsetsBlock(_ insets: UIEdgeInsets) -> (LayoutProxy, LayoutProxy) -> Void { return { (containerView, view) in
        view.left == containerView.left + insets.left
        view.top == containerView.top + insets.top
        view.right == containerView.right - insets.right
        view.bottom == containerView.bottom - insets.bottom
    } }

    public static func edgeInsetsZeroBlock() -> (LayoutProxy, LayoutProxy) -> Void {
        return self.edgeInsetsBlock(UIEdgeInsetsZero)
    }

    @discardableResult
    public func constrainView(_ view: UIView, withInsets insets: UIEdgeInsets = UIEdgeInsetsZero) -> ConstraintGroup {
        return constrain(self, view, block: UIView.edgeInsetsBlock(insets))
    }

    @discardableResult
    public func addAndConstrainView(_ view: UIView, withInsets insets: UIEdgeInsets = UIEdgeInsetsZero) -> ConstraintGroup {
        view.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(view)
        return self.constrainView(view, withInsets: insets)
    }

    @discardableResult
    public func replaceAndConstrain(view: UIView, withBlock block: ((LayoutProxy, LayoutProxy) -> Void)) -> ConstraintGroup {
        let filteredConstraints = self.constraints.filter { constraint in
            return (constraint.firstItem === view || constraint.secondItem === view)
        }
        NSLayoutConstraint.deactivate(filteredConstraints)
        return constrain(self, view, block: block)
    }

    @discardableResult
    public func replaceAndConstrainFirstView(block: ((LayoutProxy, LayoutProxy) -> Void)) -> ConstraintGroup {
        return self.replaceAndConstrain(view: self.subviews[0], withBlock: block)
    }

    @discardableResult
    public func replaceAndConstrainFirstView(withInsets insets: UIEdgeInsets) -> ConstraintGroup {
        return self.replaceAndConstrainFirstView(block: UIView.edgeInsetsBlock(insets))
    }
}

public extension UIViewController {

    public func removeSelf() {
        self.removeSelf(transitionFn: { $0() })
    }

    public func removeSelf(transitionFn: @noescape (completionFn: () -> Void) -> Void) {
        self.willMove(toParentViewController: nil)
        transitionFn() {
            self.view.removeFromSuperview()
            self.removeFromParentViewController()
        }
    }

    @discardableResult
    public func addAndConstrainChildViewController(_ viewController: UIViewController, withInsets insets: UIEdgeInsets = .zero) -> ConstraintGroup {
        return self.addAndConstrainChildViewController(viewController, withInsets: insets, transitionFn: { $0() })
    }

    @discardableResult
    public func addAndConstrainChildViewController(_ viewController: UIViewController, withInsets insets: UIEdgeInsets = .zero, transitionFn: @noescape (completionFn: () -> Void) -> Void) -> ConstraintGroup {
        self.addChildViewController(viewController)
        let constraintGroup = self.view.addAndConstrainView(viewController.view, withInsets: insets)
        transitionFn() {
            viewController.didMove(toParentViewController: self)
        }
        return constraintGroup
    }
}
