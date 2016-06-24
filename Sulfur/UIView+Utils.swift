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
