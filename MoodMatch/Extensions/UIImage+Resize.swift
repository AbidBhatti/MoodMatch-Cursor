//
//  UIImage+Resize.swift
//  MoodMatch
//
//  Created by Abid Bhatti on 14/06/25.
//

import UIKit

extension UIImage {
    /// Resize image to specified size while maintaining aspect ratio
    func resized(to size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    /// Compress image for API transmission
    func compressed(quality: CGFloat = 0.8) -> Data? {
        return self.jpegData(compressionQuality: quality)
    }
    
    /// Resize image to fit within max dimensions while maintaining aspect ratio
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