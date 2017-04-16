//
// This file is subject to the terms and conditions defined in
// file 'LICENSE', which is part of this source code package.
//

import UIKit

public protocol TwoDimensional {

    init()

    var d1: Double { get set }
    var d2: Double { get set }
}

public extension TwoDimensional {

    public init(d1: Double, d2: Double) {
        self.init()
        self.d1 = d1
        self.d2 = d2
    }

    public init(value: Double) {
        self.init(d1: value, d2: value)
    }
}

public extension TwoDimensional {

    public var point: CGPoint { return CGPoint(x: self.d1, y: self.d2) }
    public var vector: CGVector { return CGVector(dx: self.d1, dy: self.d2) }
    public var size: CGSize { return CGSize(width: self.d1, height: self.d2) }
}

public extension TwoDimensional {

    public var aspectRatio: Double { return self.d1 / self.d2 }
}

public extension TwoDimensional /* : Hashable */ {

    public var hashValue: Int {
        return Hasher()
            .adding(part: self.d1)
            .adding(part: self.d2)
            .hashValue
    }

    public static func == (lhs: TwoDimensional, rhs: TwoDimensional) -> Bool {
        return lhs.d1 == rhs.d1 && lhs.d2 == rhs.d2
    }
}

public func + <TwoD: TwoDimensional> (twoD1: TwoD, twoD2: TwoD) -> TwoD {
    return TwoD(d1: twoD1.d1 + twoD2.d1, d2: twoD1.d2 + twoD2.d2)
}

public func += <TwoD: TwoDimensional> (twoD1: inout TwoD, twoD2: TwoD) {
    twoD1 = twoD1 + twoD2
}

public func - <TwoD: TwoDimensional> (twoD1: TwoD, twoD2: TwoD) -> TwoD {
    return TwoD(d1: twoD1.d1 - twoD2.d1, d2: twoD1.d2 - twoD2.d2)
}

public func -= <TwoD: TwoDimensional> (twoD1: inout TwoD, twoD2: TwoD) {
    twoD1 = twoD1 - twoD2
}

public func * <TwoD: TwoDimensional> (twoD1: TwoD, twoD2: TwoD) -> TwoD {
    return TwoD(d1: twoD1.d1 * twoD2.d1, d2: twoD1.d2 * twoD2.d2)
}

public func *= <TwoD: TwoDimensional> (twoD1: inout TwoD, twoD2: TwoD) {
    twoD1 = twoD1 * twoD2
}

public func * <TwoD: TwoDimensional> (twoD: TwoD, scale: Double) -> TwoD {
    return TwoD(d1: twoD.d1 * scale, d2: twoD.d2 * scale)
}

public func *= <TwoD: TwoDimensional> (twoD: inout TwoD, scale: Double) {
    twoD = twoD * scale
}

public func / <TwoD: TwoDimensional> (twoD1: TwoD, twoD2: TwoD) -> TwoD {
    return TwoD(d1: twoD1.d1 / twoD2.d1, d2: twoD1.d2 / twoD2.d2)
}

public func /= <TwoD: TwoDimensional> (twoD1: inout TwoD, twoD2: TwoD) {
    twoD1 = twoD1 / twoD2
}

public func / <TwoD: TwoDimensional> (twoD: TwoD, scale: Double) -> TwoD {
    return TwoD(d1: twoD.d1 / scale, d2: twoD.d2 / scale)
}

public func /= <TwoD: TwoDimensional> (twoD: inout TwoD, scale: Double) {
    twoD = twoD / scale
}

fileprivate func angleBetween(u: CGVector, v: CGVector) -> CGFloat {
    let dotProduct = (u.dx * v.dx) + (u.dy * v.dy)
    return acos(dotProduct / (u.length * v.length))
}

public extension CGVector {

    public var length: CGFloat {
        return sqrt(pow(self.dx, 2.0) + pow(self.dy, 2.0))
    }

    public var normalized: CGVector {
        return self / self.length.double
    }

    public var isFullyNormal: Bool {
        return self.dx.isNormal && self.dy.isNormal
    }

    public var inversed: CGVector {
        return CGVector(dx: -self.dx, dy: -self.dy)
    }

    public func angleTo(_ vector: CGVector) -> CGFloat {
        return angleBetween(u: self, v: vector)
    }
}

public extension CGPoint {

    public static let one = CGPoint(x: 1, y: 1)

    public func vector(to point: CGPoint) -> CGVector {
        return CGVector(dx: point.x - self.x, dy: point.y - self.y)
    }
}

public extension CGPoint {

    public func midpoint(between point: CGPoint) -> CGPoint {
        return CGPoint(x: (self.x + point.x) / 2.0, y: (self.y + point.y) / 2.0)
    }

    public mutating func offset(dx: CGFloat = 0.0, dy: CGFloat = 0.0) {
        self.x += dx
        self.y += dy
    }

    public func offseting(dx: CGFloat = 0.0, dy: CGFloat = 0.0) -> CGPoint {
        var point = self
        point.offset(dx: dx, dy: dy)
        return point
    }

    public mutating func scale(cx: CGFloat = 1.0, cy: CGFloat = 1.0) {
        self.x *= cx
        self.y *= cy
    }

    public func scaling(cx: CGFloat = 1.0, cy: CGFloat = 1.0) -> CGPoint {
        var point = self
        point.scale(cx: cx, cy: cy)
        return point
    }
}

public extension CGSize {

    public mutating func offset(width: CGFloat = 0, height: CGFloat = 0) {
        self.width += width
        self.height += height
    }

    public func offsetting(width: CGFloat = 0, height: CGFloat = 0) -> CGSize {
        var size = self
        size.offset(width: width, height: height)
        return size
    }
}

public extension CGRect {

    public static func origin(forAnchor anchorPoint: CGPoint, point: CGPoint, size: CGSize) -> CGPoint {
        return CGPoint(
            x: point.x - (size.width * anchorPoint.x),
            y: point.y - (size.height * anchorPoint.y))
    }

    public var center: CGPoint {
        get {
            return CGPoint(x: self.midX, y: self.midY)
        }
        mutating set(newCenter) {
            self.origin = CGRect.origin(forAnchor: CGPoint(x: 0.5, y: 0.5), point: newCenter, size: self.size)
        }
    }

    public var topLeft: CGPoint {
        return CGPoint(x: self.minX, y: self.minY)
    }

    public var topCenter: CGPoint {
        return CGPoint(x: self.midX, y: self.minY)
    }

    public var topRight: CGPoint {
        return CGPoint(x: self.maxX, y: self.minY)
    }

    public var midLeft: CGPoint {
        return CGPoint(x: self.minX, y: self.midY)
    }

    public var midRight: CGPoint {
        return CGPoint(x: self.maxX, y: self.midY)
    }

    public var bottomLeft: CGPoint {
        return CGPoint(x: self.minX, y: self.maxY)
    }

    public var bottomCenter: CGPoint {
        return CGPoint(x: self.midX, y: self.maxY)
    }

    public var bottomRight: CGPoint {
        return CGPoint(x: self.maxX, y: self.maxY)
    }

    var left: CGFloat {
        return self.origin.x
    }

    var top: CGFloat {
        return self.origin.y
    }

    var right: CGFloat {
        return self.left + self.width
    }

    var bottom: CGFloat {
        return self.top + self.height
    }

    public init(center: CGPoint, size: CGSize) {
        self.origin = CGRect.origin(forAnchor: CGPoint(x: 0.5, y: 0.5), point: center, size: size)
        self.size = size
    }

    public func pointAtAnchor(_ anchorPoint: CGPoint) -> CGPoint {
        return CGPoint(
            x: (anchorPoint.x * self.width) + self.origin.x,
            y: (anchorPoint.y * self.height) + self.origin.y)
    }

    public var aspectRatio: CGFloat {
        return self.size.aspectRatio.cgFloat
    }
}

extension CGPoint: TwoDimensional, Hashable {

    public var d1: Double {
        get { return self.x.double }
        set { self.x = newValue.cgFloat }
    }

    public var d2: Double {
        get { return self.y.double }
        set { self.y = newValue.cgFloat }
    }
}

extension CGVector: TwoDimensional, Hashable {

    public var d1: Double {
        get { return self.dx.double }
        set { self.dx = newValue.cgFloat }
    }

    public var d2: Double {
        get { return self.dy.double }
        set { self.dy = newValue.cgFloat }
    }
}

extension CGSize: TwoDimensional, Hashable {

    public var d1: Double {
        get { return self.width.double }
        set { self.width = newValue.cgFloat }
    }

    public var d2: Double {
        get { return self.height.double }
        set { self.height = newValue.cgFloat }
    }
}

extension CGRect: Hashable {

    public var hashValue: Int {
        return Hasher()
            .adding(hashable: self.origin)
            .adding(hashable: self.size)
            .hashValue
    }
}

public extension CGAffineTransform {

    public init(xScale: CGFloat, yScale: CGFloat, angle: CGFloat, xTranslate: CGFloat, yTranslate: CGFloat) {
        self.a = xScale * cos(angle)
        self.b = yScale * sin(angle)
        self.c = xScale * -sin(angle)
        self.d = yScale * cos(angle)
        self.tx = xTranslate
        self.ty = yTranslate
    }

    public init(xScale: CGFloat, yScale: CGFloat) {
        self.init(xScale: xScale, yScale: yScale, angle: 0.0, xTranslate: 0.0, yTranslate: 0.0)
    }

    public init(angle: CGFloat) {
        self.init(xScale: 1.0, yScale: 1.0, angle: angle, xTranslate: 0.0, yTranslate: 0.0)
    }

    public init(xTranslate: CGFloat, yTranslate: CGFloat) {
        self.init(xScale: 1.0, yScale: 1.0, angle: 0.0, xTranslate: xTranslate, yTranslate: yTranslate)
    }

    public var xScale: CGFloat {
        get {
            return sqrt((self.a * self.a) + (self.c * self.c))
        }
        mutating set {
            self = CGAffineTransform(xScale: newValue, yScale: self.yScale, angle: self.angle, xTranslate: self.xTranslate, yTranslate: self.yTranslate)
        }
    }

    public var yScale: CGFloat {
        get {
            return sqrt((self.b * self.b) + (self.d * self.d))
        }
        mutating set {
            self = CGAffineTransform(xScale: self.xScale, yScale: newValue, angle: self.angle, xTranslate: self.xTranslate, yTranslate: self.yTranslate)
        }
    }

    public var angle: CGFloat {
        get {
            return atan2(self.b, self.a)
        }
        mutating set {
            self = CGAffineTransform(xScale: self.xScale, yScale: self.yScale, angle: newValue, xTranslate: self.xTranslate, yTranslate: self.yTranslate)
        }
    }

    public var xTranslate: CGFloat {
        get {
            return self.tx
        }
        mutating set {
            self = CGAffineTransform(xScale: self.xScale, yScale: self.yScale, angle: self.angle, xTranslate: newValue, yTranslate: self.yTranslate)
        }
    }

    public var yTranslate: CGFloat {
        get {
            return self.ty
        }
        mutating set {
            self = CGAffineTransform(xScale: self.xScale, yScale: self.yScale, angle: self.angle, xTranslate: self.xTranslate, yTranslate: newValue)
        }
    }
}

public extension CGRect {

    public mutating func inset(with insets: UIEdgeInsets) {
        self.origin.x += insets.left
        self.origin.y += insets.top
        self.size.width -= insets.width
        self.size.height -= insets.height
    }

    public func insetted(with insets: UIEdgeInsets) -> CGRect {
        var rect = self
        rect.inset(with: insets)
        return rect
    }
}

public extension CGRect {

    public func rect(for transform: CGAffineTransform) -> CGRect {
        return self.applying(transform)
    }

    public mutating func apply(_ transform: CGAffineTransform) {
        self = self.rect(for: transform)
    }

    public func transform(to rect: CGRect, anchorPoint: CGPoint = CGPoint.zero, maintainAspectRatio: Bool = false, rescale: CGFloat = 1.0) -> CGAffineTransform {
        var xScale = rect.width / self.width
        var yScale = rect.height / self.height
        if maintainAspectRatio {
            if self.aspectRatio >= rect.aspectRatio {
                yScale = xScale
            } else {
                xScale = yScale
            }
        }

        xScale *= rescale
        yScale *= rescale
        
        return self.transform(to: rect, xScale: xScale, yScale: yScale, anchorPoint: anchorPoint)
    }

    public func transform(to rect: CGRect, xScale: CGFloat, yScale: CGFloat, anchorPoint: CGPoint = CGPoint.zero) -> CGAffineTransform {
        var transform = CGAffineTransform(xScale: xScale, yScale: yScale)

        let translationVector = rect.pointAtAnchor(anchorPoint).vector - self.pointAtAnchor(anchorPoint).vector
        transform.xTranslate = translationVector.dx * xScale
        transform.yTranslate = translationVector.dy * yScale

        return transform
    }

    public func insets(to rect: CGRect) -> UIEdgeInsets {
        return UIEdgeInsets(
            top: rect.top - self.top,
            left: rect.left - self.left,
            bottom: self.bottom - rect.bottom,
            right: self.right - rect.right)
    }
}

public extension UIView {

    public func transform(to rect: CGRect) -> CGAffineTransform {
        let oldTransform = self.transform
        self.transform = .identity
        let newTransform = self.frame.transform(to: rect, anchorPoint: self.layer.anchorPoint)
        self.transform = oldTransform
        return newTransform
    }

    public func applyTransform(to rect: CGRect) {
        self.transform = self.transform(to: rect)
    }

    public func insets(for rect: CGRect) -> UIEdgeInsets {
        return self.bounds.insets(to: rect)
    }
}

public extension Double {

    public var asRadians: Double {
        return self * (.pi / 180.0)
    }

    public var asDegrees: Double {
        return self * (180.0 / .pi)
    }

    public var cgFloat: CGFloat {
        return CGFloat(self)
    }
}

public extension CGFloat {

    public var double: Double {
        return Double(self)
    }
}
