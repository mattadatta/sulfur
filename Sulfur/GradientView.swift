/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE.txt', which is part of this source code package.
 */

import UIKit

public final class GradientView: UIView {

    public typealias GradientData = (x: Double, y: Double, color: UIColor)

    override class func layerClass() -> AnyClass {
        return CAGradientLayer.self
    }

    public var gradientLayer: CAGradientLayer {
        return self.layer as! CAGradientLayer
    }

    public var startData: GradientData = (0.5, 0.0, UIColor.whiteColor()) {
        didSet {
            self.updateGradient()
        }
    }

    public var endData: GradientData = (0.5, 1.0, UIColor.blackColor()) {
        didSet {
            self.updateGradient()
        }
    }

    public var reverse = false {
        didSet {
            self.updateGradient()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    private func commonInit() {
        self.updateGradient()
    }

    private func updateGradient() {
        let startColor = (self.reverse ? self.endData.color : self.startData.color).CGColor
        let endColor = (self.reverse ? self.startData.color : self.endData.color).CGColor
        self.gradientLayer.colors = [startColor, endColor]
        self.gradientLayer.startPoint = CGPoint(x: self.startData.x, y: self.startData.y)
        self.gradientLayer.endPoint = CGPoint(x: self.endData.x, y: self.endData.y)
    }
}

final class TwoPointGradientLayer: CAGradientLayer {

    typealias GradientData = (x: Double, y: Double, color: UIColor)

    var startData: GradientData = (0.5, 0.0, UIColor.whiteColor()) {
        didSet {
            self.updateGradient()
        }
    }

    var endData: GradientData = (0.5, 1.0, UIColor.blackColor()) {
        didSet {
            self.updateGradient()
        }
    }

    var reverse = false {
        didSet {
            self.updateGradient()
        }
    }

    override init() {
        super.init()
        self.commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    override init(layer: AnyObject) {
        super.init(layer: layer)
        guard let other = layer as? TwoPointGradientLayer else {
            return
        }
        self.startData = other.startData
        self.endData = other.endData
        self.reverse = other.reverse
    }

    private func commonInit() {
        self.updateGradient()
    }

    private func updateGradient() {
        let startColor = (self.reverse ? self.endData.color : self.startData.color).CGColor
        let endColor = (self.reverse ? self.startData.color : self.endData.color).CGColor
        self.colors = [startColor, endColor]
        self.startPoint = CGPoint(x: self.startData.x, y: self.startData.y)
        self.endPoint = CGPoint(x: self.endData.x, y: self.endData.y)
    }
}
