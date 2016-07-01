/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE', which is part of this source code package.
 */

import UIKit

public extension UIViewControllerContextTransitioning {

    public func fromViewController<ViewController>(reverse reverse: Bool = false) -> ViewController? {
        if reverse {
            return self.toViewController()
        }
        return self.viewControllerForKey(UITransitionContextFromViewControllerKey) as? ViewController
    }

    public func fromView<View>(reverse reverse: Bool = false) -> View? {
        if reverse {
            return self.toView()
        }
        return self.viewForKey(UITransitionContextFromViewKey) as? View
    }

    public func toViewController<ViewController>(reverse reverse: Bool = false) -> ViewController? {
        if reverse {
            return self.fromViewController()
        }
        return self.viewControllerForKey(UITransitionContextToViewControllerKey) as? ViewController
    }

    public func toView<View>(reverse reverse: Bool = false) -> View? {
        if reverse {
            return self.fromView()
        }
        return self.viewForKey(UITransitionContextToViewKey) as? View
    }
}
