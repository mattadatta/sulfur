/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE', which is part of this source code package.
 */

import UIKit

public extension UIViewControllerContextTransitioning {

    public func fromViewController<ViewController>(reverse: Bool = false) -> ViewController? {
        guard !reverse else { return self.toViewController() }
        return self.viewController(forKey: .from) as? ViewController
    }

    public func fromView<View>(reverse: Bool = false) -> View? {
        guard !reverse else { return self.toView() }
        return self.view(forKey: .from) as? View
    }

    public func toViewController<ViewController>(reverse: Bool = false) -> ViewController? {
        guard !reverse else { return self.fromViewController() }
        return self.viewController(forKey: .to) as? ViewController
    }

    public func toView<View>(reverse: Bool = false) -> View? {
        guard !reverse else { return self.fromView() }
        return self.view(forKey: .to) as? View
    }
}
