//
// This file is subject to the terms and conditions defined in
// file 'LICENSE', which is part of this source code package.
//

import UIKit
import Cartography

public protocol UINibViewInflatable {

    var nibName: String { get }
    var nibBundle: Bundle? { get }
    var instantiationOwner: AnyObject? { get }
    var instantiationOptions: [NSObject : AnyObject]? { get }
}

public extension UINibViewInflatable {

    public var nibName: String {
        return String(describing: Self.self)
    }

    public var instantiationOptions: [NSObject : AnyObject]? {
        return nil
    }
}

public extension UINibViewInflatable where Self: AnyObject {

    public var nibBundle: Bundle? {
        return Bundle(for: Self.self)
    }

    public var instantiationOwner: AnyObject? {
        return self
    }
}

public extension UINibViewInflatable {

    public var viewNib: UINib {
        return UINib(nibName: self.nibName, bundle: self.nibBundle)
    }

    public func inflateView(atIndex index: Int) -> UIView {
        return self.viewNib.instantiate(withOwner: self.instantiationOwner, options: self.instantiationOptions)[index] as! UIView
    }

    public func inflateView() -> UIView {
        return self.inflateView(atIndex: 0)
    }
}

public extension UINibViewInflatable where Self: UIView {

    @discardableResult
    public func inflateAddAndConstrainView() -> (UIView, ConstraintGroup) {
        let view = self.inflateView()
        return (view, self.addAndConstrainView(view))
    }
}
