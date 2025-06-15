//
//  UIImage+Resize.swift
//  MoodMatch
//
//  Created by Abid Bhatti on 14/06/25.
//

import UIKit

extension UIImage {
    /// Returns a new image resized to the specified size.
    ///
    /// The image is scaled to fill the provided dimensions, which may alter its aspect ratio.
    ///
    /// - Parameter size: The target size for the new image.
    /// - Returns: A resized image, or `nil` if the operation fails.
    func resized(to size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    /// Returns JPEG data for the image compressed at the specified quality level.
    ///
    /// - Parameter quality: Compression quality ranging from 0.0 (maximum compression) to 1.0 (least compression). Defaults to 0.8.
    /// - Returns: JPEG-encoded data if compression succeeds, or `nil` if it fails.
    func compressed(quality: CGFloat = 0.8) -> Data? {
        return self.jpegData(compressionQuality: quality)
    }
    
    /// Returns a new image resized to fit within the specified maximum width and height, preserving the original aspect ratio.
    ///
    /// The resulting image will not exceed the given dimensions in either width or height. If the image is already within the constraints, it will be returned at its current size.
    ///
    /// - Parameters:
    ///   - maxWidth: The maximum allowed width for the resized image.
    ///   - maxHeight: The maximum allowed height for the resized image.
    ///
    /// - Returns: A new UIImage resized to fit within the specified bounds, or `nil` if resizing fails.
    func resizedToFit(maxWidth: CGFloat, maxHeight: CGFloat) -> UIImage? {
        let aspectRatio = size.width / size.height
        var newWidth = maxWidth
        var newHeight = maxHeight
        
        if aspectRatio > 1 {
            // Landscape
            newHeight = newWidth / aspectRatio
            if newHeight > maxHeight {
                newHeight = maxHeight
                newWidth = newHeight * aspectRatio
            }
        } else {
            // Portrait or square
            newWidth = newHeight * aspectRatio
            if newWidth > maxWidth {
                newWidth = maxWidth
                newHeight = newWidth / aspectRatio
            }
        }
        
        return resized(to: CGSize(width: newWidth, height: newHeight))
    }
} 