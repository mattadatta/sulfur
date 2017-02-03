/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE', which is part of this source code package.
 */

import UIKit
import Photos

public extension UIImage {

    public convenience init?(view: UIView) {
        let scale = UIScreen.main.scale

        UIGraphicsBeginImageContextWithOptions(view.bounds.size * Double(scale), view.isOpaque, scale)
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
        ctx.scaleBy(x: scale, y: scale)
        view.layer.render(in: ctx)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard
            let snapshotImage = image,
            let cgImage = snapshotImage.cgImage else
        { return nil }

        self.init(cgImage: cgImage)
    }

    public func scaledBy(scale: CGFloat) -> UIImage? {
        guard
            let cgImage = self.cgImage,
            let scaledCGImage = UIImage(cgImage: cgImage, scale: scale, orientation: self.imageOrientation).cgImage else
        { return nil }

        return UIImage(cgImage: scaledCGImage)
    }
}

public extension UIImage {

    public static func image(withColor color: UIColor, size: CGSize = CGSize(value: 1.0)) -> UIImage? {
        let imageRect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContext(imageRect.size)
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }

        ctx.setFillColor(color.cgColor)
        ctx.fill(imageRect)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }
}

public extension UIImage {

    public func image(byMultiplying color: UIColor) -> UIImage? {
        guard let overlayImage = UIImage.image(withColor: color, size: self.size) else { return nil }

        UIGraphicsBeginImageContextWithOptions(self.size, true, 0)
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }

        let imageRect = CGRect(origin: .zero, size: self.size)
        ctx.setFillColor(UIColor.white.cgColor)
        ctx.fill(imageRect)

        self.draw(in: imageRect, blendMode: .normal, alpha: 1.0)
        overlayImage.draw(in: imageRect, blendMode: .multiply, alpha: 1.0)

        let resultImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resultImage
    }
}

public extension UIImage {

    public func centerCropImage() -> UIImage? {
        let imageWidth = self.size.width
        let imageHeight = self.size.height
        let minDimension = min(imageWidth, imageHeight)
        let newX = (imageWidth - minDimension) / 2.0
        let newY = (imageHeight - minDimension) / 2.0
        let newRect = CGRect(x: newX, y: newY, width: minDimension, height: minDimension)

        guard let cgImage = self.cgImage?.cropping(to: newRect) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    public func circleCropImage() -> UIImage? {
        let imageSize = self.size
        let minDimension = min(imageSize.width, imageSize.height)
        let croppedImageSize = CGSize(width: minDimension, height: minDimension)

        UIGraphicsBeginImageContextWithOptions(croppedImageSize, false, 0.0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        context.beginPath()
        context.addArc(
            center: CGPoint(x: croppedImageSize.width / 2.0, y: croppedImageSize.height / 2.0),
            radius: croppedImageSize.width / 2.0,
            startAngle: 0.0,
            endAngle: CGFloat(360.0.asRadians),
            clockwise: false)
        context.closePath()
        context.clip()
        self.draw(in: CGRect(origin: .zero, size: croppedImageSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
}

public extension UIImage {

    public enum ResizeType {
        case aspectFit
        case aspectFill
    }

    public func resized(to targetSize: CGSize, type: ResizeType) -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }
        let bitmapSize = CGSize(width: cgImage.width, height: cgImage.height)
        let scaleHor = targetSize.width / bitmapSize.width
        let scaleVert = targetSize.height / bitmapSize.height
        let scale = type == .aspectFill ? max(scaleHor, scaleVert) : min(scaleHor, scaleVert)
        return self.resized(toScale: CGFloat(min(scale, 1)))
    }

    public func resized(toScale scale: CGFloat) -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }

        let size = CGSize(width: round(scale * CGFloat(cgImage.width)), height: round(scale * CGFloat(cgImage.height)))
        let alphaInfo: CGImageAlphaInfo = cgImage.isOpaque ? .noneSkipLast : .premultipliedLast

        guard let ctx = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: alphaInfo.rawValue) else { return nil }
        ctx.draw(cgImage, in: CGRect(origin: CGPoint.zero, size: size))
        guard let decompressed = ctx.makeImage() else { return nil }
        return UIImage(cgImage: decompressed, scale: self.scale, orientation: self.imageOrientation)
    }
}

public extension CGImage {

    public var isOpaque: Bool {
        let alphaInfos: Set<CGImageAlphaInfo> = [.none, .noneSkipFirst, .noneSkipLast]
        return alphaInfos.contains(self.alphaInfo)
    }
}
