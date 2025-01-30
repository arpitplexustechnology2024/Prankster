//
//  ImageCompress.swift
//  Prankster
//
//  Created by Arpit iOS Dev. on 29/01/25.
//

import UIKit

enum ImageProcessingError: Error {
    case oversizedImage
    case compressionFailed
    
    var message: String {
        switch self {
        case .oversizedImage:
            return "Image size must be less than 5MB"
        case .compressionFailed:
            return "Failed to process image"
        }
    }
}

extension UIImage {
    func compress(targetSizeKB: Int = 500) -> UIImage? {
        let bytes = targetSizeKB * 1024
        var compression: CGFloat = 1.0
        var imageData = self.jpegData(compressionQuality: compression)
        
        // First try JPEG compression
        while (imageData?.count ?? 0) > bytes && compression > 0.01 {
            compression -= 0.1
            imageData = self.jpegData(compressionQuality: compression)
        }
        
        // If JPEG compression isn't enough, resize the image
        if (imageData?.count ?? 0) > bytes {
            let ratio = CGFloat(bytes) / CGFloat(imageData?.count ?? 1)
            let size = CGSize(width: self.size.width * sqrt(ratio),
                            height: self.size.height * sqrt(ratio))
            
            UIGraphicsBeginImageContextWithOptions(size, false, 0)
            self.draw(in: CGRect(origin: .zero, size: size))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return resizedImage?.compress(targetSizeKB: targetSizeKB)
        }
        
        return imageData.flatMap(UIImage.init)
    }
    
    var sizeInMB: Double {
        guard let imageData = self.jpegData(compressionQuality: 1.0) else { return 0.0 }
        return Double(imageData.count) / (1024 * 1024)
    }
}

// Image Processing Manager
class ImageProcessingManager {
    static let shared = ImageProcessingManager()
    private let maxSizeMB: Double = 5.0
    
    private init() {}
    
    func processImage(_ image: UIImage, completion: @escaping (Result<UIImage, ImageProcessingError>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            // Check original image size first
            if image.sizeInMB > self.maxSizeMB {
                DispatchQueue.main.async {
                    completion(.failure(.oversizedImage))
                }
                return
            }
            
            // Try to compress the image
            guard let compressedImage = image.compress(targetSizeKB: 500) else {
                DispatchQueue.main.async {
                    completion(.failure(.compressionFailed))
                }
                return
            }
            
            // Verify compressed image size
            if compressedImage.sizeInMB > self.maxSizeMB {
                DispatchQueue.main.async {
                    completion(.failure(.oversizedImage))
                }
                return
            }
            
            DispatchQueue.main.async {
                completion(.success(compressedImage))
            }
        }
    }
}

