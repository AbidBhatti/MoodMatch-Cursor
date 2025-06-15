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
    /// - Parameter size: The target size for the resized image.
    /// - Returns: A new UIImage scaled to the given size, or nil if resizing fails.
    func resized(to size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    /// Compresses the image into JPEG format with the specified quality.
    ///
    /// - Parameter quality: Compression quality, from 0.0 (most compressed) to 1.0 (least compressed). Defaults to 0.8.
    /// - Returns: JPEG-compressed image data, or `nil` if compression fails.
    func compressed(quality: CGFloat = 0.8) -> Data? {
        return self.jpegData(compressionQuality: quality)
    }
    
    /// Returns a new image resized to fit within the specified maximum width and height, preserving the original aspect ratio.
    ///
    /// The resulting image will not exceed the given dimensions and will not be distorted.
    ///
    /// - Parameters:
    ///   - maxWidth: The maximum allowed width for the resized image.
    ///   - maxHeight: The maximum allowed height for the resized image.
    ///
    /// - Returns: A resized UIImage that fits within the specified bounds, or `nil` if resizing fails.
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