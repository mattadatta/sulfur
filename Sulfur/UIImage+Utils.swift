/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE', which is part of this source code package.
 */

import UIKit

public extension UIImage {

    public func centerCropImage() -> UIImage? {
        let imageWidth = self.size.width
        let imageHeight = self.size.height
        let minDimension = min(imageWidth, imageHeight)
        let newX = (imageWidth - minDimension) / 2.0
        let newY = (imageHeight - minDimension) / 2.0
        let newRect = CGRect(x: newX, y: newY, width: minDimension, height: minDimension)

        guard let cgImage = self.cgImage?.cropping(to: newRect) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }

    public func circleCropImage() -> UIImage {
        let imageSize = self.size
        let minDimension = min(imageSize.width, imageSize.height)
        let croppedImageSize = CGSize(width: minDimension, height: minDimension)

        UIGraphicsBeginImageContextWithOptions(croppedImageSize, false, 0.0)
        let context = UIGraphicsGetCurrentContext()
        context?.beginPath()
        context?.addArc(centerX: croppedImageSize.width / 2.0,
            y: croppedImageSize.height / 2.0,
            radius: croppedImageSize.width / 2.0,
            startAngle: 0.0,
            endAngle: CGFloat(360.0.asRadians),
            clockwise: 0)
        context?.closePath()
        context?.clip()
        self.draw(in: CGRect(origin: CGPoint.zero, size: croppedImageSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage!
    }
}
