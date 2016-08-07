/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE', which is part of this source code package.
 */

import UIKit

// MARK: - Gradient

struct Gradient {

    private enum Constants {

        static let defaultColors = [
            Stop(color: .black, percent: 0.0),
            Stop(color: .white, percent: 1.0),
        ]
    }

    struct Stop: Hashable {

        var color: UIColor
        var percent: Double

        init(color: UIColor, percent: Double) {
            self.color = color
            self.percent = max(0.0, min(1.0, percent))
        }

        var hashValue: Int {
            return Hasher()
                .adding(hashable: self.color)
                .adding(part: self.percent)
                .hashValue
        }

        static func == (lhs: Stop, rhs: Stop) -> Bool {
            return lhs.color == rhs.color && lhs.percent == rhs.percent
        }
    }

    var stops: [Stop] {
        didSet {
            if self.stops.count < 2 {
                SulfurSDK.log.warning("Number of stops must be > 1. Got \(self.stops.count)")
                self.stops = Constants.defaultColors
            }
            self.stops.sort(by: { $0.percent <= $1.percent })
        }
    }

    var colors: [UIColor] {
        get {
            return self.stops.map({ $0.color })
        }
        set {
            guard newValue.count > 1 else {
                SulfurSDK.log.warning("Number of colors must be > 1. Got \(self.stops.count)")
                self.stops = Constants.defaultColors
                return
            }

            let increment = 1.0 / Double(newValue.count - 1)
            self.stops = newValue.mapPass(0.0) { (color, percentage) in
                return (Stop(color: color, percent: percentage), percentage + increment)
            }
        }
    }

    init() {
        self.init(stops: Constants.defaultColors)
    }

    init(stops: [Stop]) {
        self.stops = stops
    }

    init(colors: [UIColor]) {
        self.stops = Constants.defaultColors
        self.colors = colors
    }

    func interpolatedColorForPercentage(_ percent: Double) -> UIColor {
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
