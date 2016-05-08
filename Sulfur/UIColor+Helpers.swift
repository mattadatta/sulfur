/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE.txt', which is part of this source code package.
 */

import UIKit

public extension UIColor {

    public convenience init(hex: String) {
        let characterSet = NSCharacterSet.whitespaceAndNewlineCharacterSet().mutableCopy() as! NSMutableCharacterSet
        characterSet.formUnionWithCharacterSet(NSCharacterSet(charactersInString: "#"))
        let colorString = hex.stringByTrimmingCharactersInSet(characterSet).uppercaseString
        let charCount = colorString.characters.count
        if charCount == 6 {
            var rgbValue: UInt32 = 0
            NSScanner(string: colorString).scanHexInt(&rgbValue)
            self.init(
                red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
                green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
                blue: CGFloat((rgbValue & 0x0000FF) >> 0) / 255.0,
                alpha: CGFloat(1.0))
        } else if charCount == 8 {
            var argbValue: UInt32 = 0
            NSScanner(string: colorString).scanHexInt(&argbValue)
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
}

public extension SequenceType where Self.Generator.Element: UIColor {

    public var asFloatArray: [CGFloat] {
        return self.flatMap({ [$0.red, $0.green, $0.blue, $0.alpha] })
    }
}
