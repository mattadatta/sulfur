//
// This file is subject to the terms and conditions defined in
// file 'LICENSE', which is part of this source code package.
//

import Foundation
import QuartzCore

private final class CAAnimationStoredDelegate: NSObject, CAAnimationDelegate {

    var start: (() -> Void)?
    var completion: ((Bool) -> Void)?

    func animationDidStart(_ anim: CAAnimation) {
        self.start?()
    }

    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        self.completion?(flag)
    }
}

public extension CAAnimation {

    private var storedDelegate: CAAnimationStoredDelegate? {
        return self.delegate as? CAAnimationStoredDelegate
    }

    private var isAnimationDelegate: Bool {
        return self.delegate is CAAnimationStoredDelegate
    }
    
    public var start: (() -> Void)? {
        get { return self.storedDelegate?.start }
        set {
            if !self.isAnimationDelegate {
                self.delegate = CAAnimationStoredDelegate()
            }
            self.storedDelegate?.start = newValue
        }
    }

    public var completion: ((_ finished: Bool) -> Void)? {
        get { return self.storedDelegate?.completion }
        set {
            if !self.isAnimationDelegate {
                self.delegate = CAAnimationStoredDelegate()
            }
            self.storedDelegate?.completion = newValue
        }
    }
}
