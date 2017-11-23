//
// This file is subject to the terms and conditions defined in
// file 'LICENSE.txt', which is part of this source code package.
//

import UIKit

// MARK: - Gradient

public struct Gradient {

    private struct Constants {

        static let defaultStops = [
            Stop(color: .black, percent: 0.0),
            Stop(color: .white, percent: 1.0),
            ]
    }

    public struct Stop: Hashable {

        public var color: UIColor
        public var percent: Double

        public init(color: UIColor, percent: Double) {
            self.color = color
            self.percent = max(0.0, min(1.0, percent))
        }

        public var hashValue: Int {
            return Hasher()
                .adding(hashable: self.color)
                .adding(part: self.percent)
                .hashValue
        }

        public static func ==(lhs: Stop, rhs: Stop) -> Bool {
            return lhs.color == rhs.color && lhs.percent == rhs.percent
        }
    }

    private var interpolated: [UIColor] = []

    public var stops: [Stop] {
        didSet {
            if self.stops.count < 2 {
                self.stops = Constants.defaultStops
            }
            self.stops.sort(by: { $0.percent <= $1.percent })
            self.invalidateInterpolationCache()
        }
    }

    private mutating func invalidateInterpolationCache() {
        self.interpolated = (0..<100).map({ index in self._interpolatedColorForPercentage(Double(index) / 100.0) })
    }

    public var colors: [UIColor] {
        get { return self.stops.map({ $0.color }) }
        set {
            guard newValue.count > 1 else {
                self.stops = Constants.defaultStops
                return
            }

            let increment = 1.0 / Double(newValue.count - 1)
            self.stops = newValue.mapPass(0.0) { color, percentage in
                return (Stop(color: color, percent: percentage), percentage + increment)
            }
        }
    }

    public init() {
        self.init(stops: Constants.defaultStops)
    }

    public init(stops: [Stop]) {
        self.stops = (stops.count > 1) ? stops : Constants.defaultStops
        self.invalidateInterpolationCache()
    }

    public init(colors: [UIColor]) {
        self.stops = []
        self.colors = colors
        self.invalidateInterpolationCache()
    }

    public init(solidColor: UIColor) {
        self.init(colors: [solidColor, solidColor])
    }

    public func interpolatedColorForPercentage(_ percent: Double) -> UIColor {
        let index = Int(max(0, min(99, percent * 100)))
        return self.interpolated[index]
    }

    private func _interpolatedColorForPercentage(_ percent: Double) -> UIColor {
        let percent = max(self.stops.first!.percent, min(self.stops.last!.percent, percent))
        var firstIndex = 0, lastIndex = 1
        while !(self.stops[firstIndex].percent <= percent &&
            self.stops[lastIndex].percent >= percent) &&
            lastIndex < self.stops.count
        {
            firstIndex = firstIndex + 1
            lastIndex = lastIndex + 1
        }

        let stop1 = self.stops[firstIndex]
        let stop2 = self.stops[lastIndex]
        let interpolatedPercent = CGFloat((percent - stop1.percent) / (stop2.percent - stop1.percent))
        let color1 = stop1.color
        let color2 = stop2.color

        let resultRed = color1.red + (interpolatedPercent * (color2.red - color1.red))
        let resultGreen = color1.green + (interpolatedPercent * (color2.green - color1.green))
        let resultBlue = color1.blue + (interpolatedPercent * (color2.blue - color1.blue))
        let resultAlpha = color1.alpha + (interpolatedPercent * (color2.alpha - color1.alpha))

        return UIColor(red: resultRed, green: resultGreen, blue: resultBlue, alpha: resultAlpha)
    }
}

public extension Gradient {

    public static func from(_ colors: UIColor...) -> Gradient {
        return Gradient(colors: colors)
    }
}

public extension Gradient {

    public static let clear = Gradient(colors: [.clear, .clear])
    public static let white = Gradient(colors: [.white, .white])
}

// MARK: - GradientView

public final class GradientView: UIView {

    override public class var layerClass: AnyClass {
        return CAGradientLayer.self
    }

    public var gradientLayer: CAGradientLayer {
        return self.layer as! CAGradientLayer
    }

    public var gradient: Gradient = Gradient() {
        didSet {
            self.gradientLayer.colors = self.gradient.colors.map({ $0.cgColor })
            self.gradientLayer.locations = self.gradient.stops.map({ NSNumber(value: $0.percent) })
        }
    }

    public var startPoint: CGPoint {
        get { return self.gradientLayer.startPoint }
        set { self.gradientLayer.startPoint = newValue }
    }

    public var endPoint: CGPoint {
        get { return self.gradientLayer.endPoint }
        set { self.gradientLayer.endPoint = newValue }
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
        self.gradient = Gradient() // Trigger didSet
    }
}
