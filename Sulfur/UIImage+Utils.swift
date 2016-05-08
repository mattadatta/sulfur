/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE.txt', which is part of this source code package.
 */

import UIKit

public extension UIImage {

    @warn_unused_result
    public func centerCropImage() -> UIImage? {
        let imageWidth = self.size.width
        let imageHeight = self.size.height
        let minDimension = min(imageWidth, imageHeight)
        let newX = (imageWidth - minDimension) / 2.0
        let newY = (imageHeight - minDimension) / 2.0
        let newRect = CGRect(x: newX, y: newY, width: minDimension, height: minDimension)

        guard let cgImage = CGImageCreateWithImageInRect(self.CGImage, newRect) else {
            return nil
        }
        return UIImage(CGImage: cgImage)
    }

    @warn_unused_result
    public func circleCropImage() -> UIImage {
        let imageSize = self.size
        let minDimension = min(imageSize.width, imageSize.height)
        let croppedImageSize = CGSize(width: minDimension, height: minDimension)

        UIGraphicsBeginImageContextWithOptions(croppedImageSize, false, 0.0)
        let context = UIGraphicsGetCurrentContext()
        CGContextBeginPath(context)
        CGContextAddArc(
            context,
            croppedImageSize.width / 2.0,
            croppedImageSize.height / 2.0,
            croppedImageSize.width / 2.0,
            0.0,
            CGFloat(360.0.asRadians),
            0)
        CGContextClosePath(context)
        CGContextClip(context)
        self.drawInRect(CGRect(origin: CGPointZero, size: croppedImageSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
}
