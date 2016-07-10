/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE', which is part of this source code package.
 */

import UIKit
import Cartography

public protocol UINibViewInflatable: class { }

public extension UINibViewInflatable {

    public func inflateView() -> UIView {
        return UINib(nibName: String(Self.self), bundle: Bundle(for: Self.self)).instantiate(withOwner: self, options: nil).first as! UIView
    }
}

public extension UINibViewInflatable where Self: UIView {

    @discardableResult
    public func inflateAddAndConstrainView() -> (UIView, ConstraintGroup) {
        let view = self.inflateView()
        return (view, self.addAndConstrainView(view))
    }
}
