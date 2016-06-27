/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE', which is part of this source code package.
 */

import UIKit

public func * (size: CGSize, scale: CGFloat) -> CGSize {
    return CGSize(width: size.width * scale, height: size.height * scale)
}

public func *= (size: inout CGSize, scale: CGFloat) {
    size = size * scale
}

public func / (size: CGSize, scale: CGFloat) -> CGSize {
    return CGSize(width: size.width / scale, height: size.height / scale)
}

public func /= (size: inout CGSize, scale: CGFloat) {
    size = size / scale
}

public extension CGSize {

    public init(length: CGFloat) {
        self.width = length
        self.height = length
    }

    public var toPoint: CGPoint {
        return CGPoint(x: self.width, y: self.height)
    }
}

public func + (lhs: CGVector, rhs: CGVector) -> CGVector {
    return CGVector(dx: lhs.dx + rhs.dx, dy: lhs.dy + rhs.dy)
}

public func += (lhs: inout CGVector, rhs: CGVector) {
    lhs = lhs + rhs
}

public func - (lhs: CGVector, rhs: CGVector) -> CGVector {
    return CGVector(dx: lhs.dx - rhs.dx, dy: lhs.dy - rhs.dy)
}

public func -= (lhs: inout CGVector, rhs: CGVector) {
    lhs = lhs - rhs
}

public func * (vector: CGVector, scale: CGFloat) -> CGVector {
    return CGVector(dx: vector.dx * scale, dy: vector.dy * scale)
}

public func *= (vector: inout CGVector, scale: CGFloat) {
    vector = vector * scale
}

public func / (vector: CGVector, scale: CGFloat) -> CGVector {
    return CGVector(dx: vector.dx / scale, dy: vector.dy / scale)
}

public func /= (vector: inout CGVector, scale: CGFloat) {
    vector = vector / scale
}

public func angleBetween(u: CGVector, v: CGVector) -> CGFloat {
    let dotProduct = (u.dx * v.dx) + (u.dy * v.dy)
    return acos(dotProduct / (u.length * v.length))
}

public extension CGVector {

    public var length: CGFloat {
        return sqrt(pow(self.dx, 2.0) + pow(self.dy, 2.0))
    }

    public var normalized: CGVector {
        return self / self.length
    }

    public var isFullyNormal: Bool {
        return self.dx.isNormal && self.dy.isNormal
    }

    public var toPoint: CGPoint {
        return CGPoint(x: self.dx, y: self.dy)
    }

    public func angleTo(_ vector: CGVector) -> CGFloat {
        return angleBetween(u: self, v: vector)
    }
}

public extension CGPoint {

    public func vectorTo(_ point: CGPoint) -> CGVector {
        return CGVector(dx: point.x - self.x, dy: point.y - self.y)
    }

    public var toVector: CGVector {
        return CGVector(dx: self.x, dy: self.y)
    }
}

public extension CGRect {

    public static func originForAnchor(_ anchorPoint: CGPoint, point: CGPoint, size: CGSize) -> CGPoint {
        return CGPoint(
            x: point.x - (size.width * anchorPoint.x),
            y: point.y - (size.height * anchorPoint.y))
    }

    public var center: CGPoint {
        get {
            return CGPoint(x: self.midX, y: self.midY)
        }
        mutating set(newCenter) {
            self.origin = CGRect.originForAnchor(CGPoint(x: 0.5, y: 0.5), point: newCenter, size: self.size)
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
        self.origin = CGRect.originForAnchor(CGPoint(x: 0.5, y: 0.5), point: center, size: size)
        self.size = size
    }

    public func pointAtAnchor(_ anchorPoint: CGPoint) -> CGPoint {
        return CGPoint(
            x: (anchorPoint.x * self.width) + self.origin.x,
            y: (anchorPoint.y * self.height) + self.origin.y)
    }
}

public extension CGRect {

    public func rectForTransform(_ transform: CGAffineTransform) -> CGRect {
        return self.apply(transform: transform)
    }

    public mutating func applyTransform(_ transform: CGAffineTransform) {
        self = self.rectForTransform(transform)
    }

    public func transformToRect(_ rect: CGRect, anchorPoint: CGPoint = CGPoint.zero) -> CGAffineTransform {
        let xScale = rect.width / self.width
        let yScale = rect.height / self.height
        var transform = CGAffineTransform(scaleX: xScale, y: yScale)

        let translationVector = rect.pointAtAnchor(anchorPoint).toVector - self.pointAtAnchor(anchorPoint).toVector
        transform = transform.translateBy(x: translationVector.dx, y: translationVector.dy)

        return transform
    }
}

public extension UIView {

    public func transformToRect(_ rect: CGRect) -> CGAffineTransform {
        let oldTransform = self.transform
        self.transform = CGAffineTransform()
        let newTransform = self.frame.transformToRect(rect, anchorPoint: self.layer.anchorPoint)
        self.transform = oldTransform
        return newTransform
    }

    public func applyTransformToRect(_ rect: CGRect) {
        self.transform = self.transformToRect(rect)
    }
}

public extension CGFloat {

    public var asRadians: CGFloat {
        return self * (CGFloat(M_PI) / 180.0)
    }

    public var asDegrees: CGFloat {
        return self * (180.0 / CGFloat(M_PI))
    }
}

public extension Double {

    public var asRadians: CGFloat {
        return CGFloat(self * (M_PI / 180.0))
    }

    public var asDegrees: CGFloat {
        return CGFloat(self * (180.0 / M_PI))
    }
}
