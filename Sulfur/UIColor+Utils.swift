//
// This file is subject to the terms and conditions defined in
// file 'LICENSE', which is part of this source code package.
//

import UIKit

public extension UIColor {

    public convenience init(hex: String) {
        // TODO: Swift 3 bug that makes me use this can gdiaf
        var characterSet = CharacterSet.whitespacesAndNewlines
        characterSet.formUnion(CharacterSet(charactersIn: "#"))

        let colorString = hex.trimmingCharacters(in: characterSet as CharacterSet).uppercased()
        let charCount = colorString.count
        if charCount == 6 {
            var rgbValue: UInt32 = 0
            Scanner(string: colorString).scanHexInt32(&rgbValue)
            self.init(
                red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
                green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
                blue: CGFloat((rgbValue & 0x0000FF) >> 0) / 255.0,
                alpha: CGFloat(1.0))
        } else if charCount == 8 {
            var argbValue: UInt32 = 0
            Scanner(string: colorString).scanHexInt32(&argbValue)
            self.init(
                red: CGFloat((argbValue & 0x00FF0000) >> 16) / 255.0,
                green: CGFloat((argbValue & 0x0000FF00) >> 8) / 255.0,
                blue: CGFloat((argbValue & 0x000000FF) >> 0) / 255.0,
                alpha: CGFloat((argbValue & 0xFF000000) >> 24) / 255.0)
        } else {
            self.init(white: 1.0, alpha: 1.0)
        }
    }

    public convenience init(rgbValue: Int) {
        self.init(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat((rgbValue & 0x0000FF) >> 0) / 255.0,
            alpha: CGFloat(1.0))
    }

    public convenience init(argbValue: UInt) {
        self.init(
            red: CGFloat((argbValue & 0x00FF0000) >> 16) / 255.0,
            green: CGFloat((argbValue & 0x0000FF00) >> 8) / 255.0,
            blue: CGFloat((argbValue & 0x000000FF) >> 0) / 255.0,
            alpha: CGFloat((argbValue & 0xFF000000) >> 24) / 255.0)
    }

    public var rgba: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        if self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return (red, green, blue, alpha)
        } else {
            return (1.0, 1.0, 1.0, 1.0)
        }
    }

    public var red: CGFloat {
        return self.rgba.red
    }

    public var green: CGFloat {
        return self.rgba.green
    }

    public var blue: CGFloat {
        return self.rgba.blue
    }

    public var alpha: CGFloat {
        return self.rgba.alpha
    }

    public var hsba: (hue: CGFloat, saturation: CGFloat, brightness: CGFloat, alpha: CGFloat) {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        if self.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            return (hue, saturation, brightness, alpha)
        } else {
            return (1.0, 1.0, 1.0, 1.0)
        }
    }

    public var hue: CGFloat {
        return self.hsba.hue
    }

    public var saturation: CGFloat {
        return self.hsba.saturation
    }

    public var brightness: CGFloat {
        return self.hsba.brightness
    }

    public func replaceHSBA(hue: CGFloat? = nil,
        saturation: CGFloat? = nil,
        brightness: CGFloat? = nil,
        alpha: CGFloat? = nil) -> UIColor
    {
        return UIColor(
            hue: hue ?? self.hue,
            saturation: saturation ?? self.saturation,
            brightness: brightness ?? self.brightness,
            alpha: alpha ?? self.alpha)
    }

    public func replaceRGBA(red: CGFloat? = nil,
        green: CGFloat? = nil,
        blue: CGFloat? = nil,
        alpha: CGFloat? = nil) -> UIColor
    {
        return UIColor(
            red: red ?? self.red,
            green: green ?? self.green,
            blue: blue ?? self.blue,
            alpha: alpha ?? self.alpha)
    }

    public func lighter() -> UIColor {
        return UIColor(
            hue: self.hue,
            saturation: self.saturation,
            brightness: min(self.brightness * 1.3, 1.0),
            alpha: self.alpha)
    }

    public func darker() -> UIColor {
        return UIColor(
            hue: self.hue,
            saturation: self.saturation,
            brightness: self.brightness * 0.75,
            alpha: self.alpha)
    }

    public static func randomizeHSBA(hue: CGFloat? = nil,
        saturation: CGFloat? = nil,
        brightness: CGFloat? = nil,
        alpha: CGFloat? = nil) -> UIColor
    {
        return UIColor(
            hue: hue ?? randomFloat(),
            saturation: saturation ?? randomFloat(),
            brightness: brightness ?? randomFloat(),
            alpha: alpha ?? randomFloat())
    }

    public static func randomizeRGBA(red: CGFloat? = nil,
        green: CGFloat? = nil,
        blue: CGFloat? = nil,
        alpha: CGFloat? = nil) -> UIColor
    {
        return UIColor(
            red: red ?? randomFloat(),
            green: green ?? randomFloat(),
            blue: blue ?? randomFloat(),
            alpha: alpha ?? randomFloat())
    }
}

public extension Sequence where Self.Iterator.Element: UIColor {

    public var asFloatArray: [CGFloat] {
        return self.flatMap({ [$0.red, $0.green, $0.blue, $0.alpha] })
    }
}

private func randomFloat() -> CGFloat {
    return CGFloat(arc4random()) / CGFloat(UINT32_MAX)
}
