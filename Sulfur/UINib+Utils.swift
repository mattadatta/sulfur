/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE.txt', which is part of this source code package.
 */

import UIKit

public protocol UINibViewInflatable: class { }

public extension UINibViewInflatable {

    @warn_unused_result
    public func inflateView() -> UIView {
        return UINib(nibName: "\(Self.self)", bundle: NSBundle(forClass: self.dynamicType)).instantiateWithOwner(self, options: nil).first as! UIView
    }
}

public extension UINibViewInflatable where Self: UIView {

    public func inflateAddAndConstrainView() -> (UIView, ConstraintGroup) {
        let view = self.inflateView()
        return (view, self.addAndConstrainView(view))
    }
}
