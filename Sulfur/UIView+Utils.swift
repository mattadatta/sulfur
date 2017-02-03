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
    public func constrainView(_ view: UIView, replace group: ConstraintGroup = ConstraintGroup(), with insets: UIEdgeInsets = .zero) -> ConstraintGroup {
        view.translatesAutoresizingMaskIntoConstraints = false
        return constrain(self, view, replace: group, block: UIView.edgeInsetsBlock(insets))
    }

    @discardableResult
    public func addAndConstrainView(_ view: UIView, insets: UIEdgeInsets) -> ConstraintGroup {
        view.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(view)
        return self.constrainView(view, with: insets)
    }

    @discardableResult
    public func addAndConstrainView(_ view: UIView, block: (LayoutProxy, LayoutProxy) -> Void = UIView.edgeInsetsBlock(.zero)) -> ConstraintGroup {
        self.addSubview(view)
        return constrain(self, view, block: block)
    }

    @discardableResult
    public func replaceAndConstrainView(_ view: UIView, withBlock block: ((LayoutProxy, LayoutProxy) -> Void)) -> ConstraintGroup {
        let filteredConstraints = self.constraints.filter { constraint in
            return (constraint.firstItem === view || constraint.secondItem === view)
        }
        NSLayoutConstraint.deactivate(filteredConstraints)
        return constrain(self, view, block: block)
    }

    @discardableResult
    public func replaceAndConstrainFirstView(block: ((LayoutProxy, LayoutProxy) -> Void)) -> ConstraintGroup {
        return self.replaceAndConstrainView(self.subviews[0], withBlock: block)
    }

    @discardableResult
    public func replaceAndConstrainFirstView(with insets: UIEdgeInsets) -> ConstraintGroup {
        return self.replaceAndConstrainFirstView(block: UIView.edgeInsetsBlock(insets))
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

    @discardableResult
    public func addAndConstrain(_ viewController: UIViewController, parentView: UIView? = nil, insets: UIEdgeInsets = .zero, performTransition: ((_ complete: () -> Void) -> Void)? = nil) -> ConstraintGroup {
        self.addChildViewController(viewController)

        if let performTransition = performTransition {
            //viewController.beginAppearanceTransition(true, animated: true)
            let constraintGroup = (parentView ?? self.view).addAndConstrainView(viewController.view, insets: insets)
            performTransition() {
                //viewController.endAppearanceTransition()
                viewController.didMove(toParentViewController: self)
            }
            return constraintGroup
        } else {
            //viewController.beginAppearanceTransition(true, animated: false)
            let constraintGroup = (parentView ?? self.view).addAndConstrainView(viewController.view, insets: insets)
            //viewController.endAppearanceTransition()
            viewController.didMove(toParentViewController: self)
            return constraintGroup
        }
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

public extension UIViewController {

    public func edgeInsetsBlock(_ insets: UIEdgeInsets) -> (LayoutProxy, LayoutProxy) -> Void { return { superview, view in
        view.top == self.topLayoutGuideCartography + insets.top
        view.bottom == self.bottomLayoutGuideCartography - insets.bottom
        view.left == superview.left + insets.left
        view.right == superview.right - insets.right
    } }

    @discardableResult
    public func constrainView(_ view1: UIView? = nil, to view2: UIView, with insets: UIEdgeInsets = .zero, replacing group: ConstraintGroup = ConstraintGroup()) -> ConstraintGroup {
        let view1 = view1 ?? self.view!
        return constrain(view1, view2, replace: group, block: self.edgeInsetsBlock(insets))
    }
}
