/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE', which is part of this source code package.
 */

import UIKit

public final class CancelableScrollView: UIScrollView {

    override public func touchesShouldCancel(in view: UIView) -> Bool {
        guard view is UIButton else { return super.touchesShouldCancel(in: view) }
        return true
    }
}
