//
// This file is subject to the terms and conditions defined in
// file 'LICENSE', which is part of this source code package.
//

import UIKit

public extension UIScrollView {

    public var insettedContentOffset: CGPoint {
        get { return self.contentOffset + CGPoint(x: self.contentInset.left, y: self.contentInset.top) }
        set { self.contentOffset = newValue - CGPoint(x: self.contentInset.left, y: self.contentInset.top) }
    }

    public func setInsettedContentOffset(_ contentOffset: CGPoint, animated: Bool) {
        self.setContentOffset(contentOffset - CGPoint(x: self.contentInset.left, y: self.contentInset.top), animated: animated)
    }
}

public final class CancelableScrollView: UIScrollView {

    override public func touchesShouldCancel(in view: UIView) -> Bool {
        guard view is UIButton else { return super.touchesShouldCancel(in: view) }
        return true
    }
}
