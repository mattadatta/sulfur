/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE', which is part of this source code package.
 */

import Foundation
import QuartzCore

/**
 Private custom CAAnimation delegate class that will act as the receiver for animation callbacks that will
 invoke the appropriate stored property closures.
 */
private class CAAnimationDelegate: NSObject {

    /// The function to invoke when the animation starts
    var start: (() -> Void)?

    /// The function to invoke when the animation completes
    var completion: ((Bool) -> Void)?

    override func animationDidStart(anim: CAAnimation) {
        self.start?()
    }

    override func animationDidStop(anim: CAAnimation, finished flag: Bool) {
        self.completion?(flag)
    }
}

public extension CAAnimation {

    /// The `CAAnimation`'s delegate as our custom delegate, if it exists and is a proper instance
    private var animationDelegate: CAAnimationDelegate? {
        return self.delegate as? CAAnimationDelegate
    }

    /// Boolean indicating whether or not the `CAAnimation`'s delegate is an instance of our private delegate
    private var isAnimationDelegate: Bool {
        return self.delegate is CAAnimationDelegate
    }

    /// The function to invoke when the animation starts
    public var start: (() -> Void)? {
        get {
            return self.animationDelegate?.start
        }
        set {
            if !self.isAnimationDelegate {
                self.delegate = CAAnimationDelegate()
            }
            self.animationDelegate?.start = newValue
        }
    }

    /// The function to invoke when the animation completes
    public var completion: ((finished: Bool) -> Void)? {
        get {
            return self.animationDelegate?.completion
        }
        set {
            if !self.isAnimationDelegate {
                self.delegate = CAAnimationDelegate()
            }
            self.animationDelegate?.completion = newValue
        }
    }
}
