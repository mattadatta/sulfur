/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE', which is part of this source code package.
 */

import UIKit

public final class GradientView: UIView {

    public typealias GradientData = (x: Double, y: Double, color: UIColor)

    override public class func layerClass() -> AnyClass {
        return CAGradientLayer.self
    }

    public var gradientLayer: CAGradientLayer {
        return self.layer as! CAGradientLayer
    }

    public var startData: GradientData = (0.5, 0.0, UIColor.white()) {
        didSet {
            self.updateGradient()
        }
    }

    public var endData: GradientData = (0.5, 1.0, UIColor.black()) {
        didSet {
            self.updateGradient()
        }
    }

    public var reverse = false {
        didSet {
            self.updateGradient()
        }
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    private func commonInit() {
        self.updateGradient()
    }

    private func updateGradient() {
        let startColor = (self.reverse ? self.endData.color : self.startData.color).cgColor
        let endColor = (self.reverse ? self.startData.color : self.endData.color).cgColor
        self.gradientLayer.colors = [startColor, endColor]
        self.gradientLayer.startPoint = CGPoint(x: self.startData.x, y: self.startData.y)
        self.gradientLayer.endPoint = CGPoint(x: self.endData.x, y: self.endData.y)
    }
}

public final class TwoPointGradientLayer: CAGradientLayer {

    public typealias GradientData = (x: Double, y: Double, color: UIColor)

    public var startData: GradientData = (0.5, 0.0, UIColor.white()) {
        didSet {
            self.updateGradient()
        }
    }

    public var endData: GradientData = (0.5, 1.0, UIColor.black()) {
        didSet {
            self.updateGradient()
        }
    }

    public var reverse = false {
        didSet {
            self.updateGradient()
        }
    }

    override public init() {
        super.init()
        self.commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    override public init(layer: AnyObject) {
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
        let startColor = (self.reverse ? self.endData.color : self.startData.color).cgColor
        let endColor = (self.reverse ? self.startData.color : self.endData.color).cgColor
        self.colors = [startColor, endColor]
        self.startPoint = CGPoint(x: self.startData.x, y: self.startData.y)
        self.endPoint = CGPoint(x: self.endData.x, y: self.endData.y)
    }
}
