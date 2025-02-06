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
            return "Image size must be upto 5MB"
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
        
        while (imageData?.count ?? 0) > bytes && compression > 0.01 {
            compression -= 0.1
            imageData = self.jpegData(compressionQuality: compression)
        }
        
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

class ImageProcessingManager {
    static let shared = ImageProcessingManager()
    private let maxSizeMB: Double = 5.0
    private let compressionQuality: CGFloat = 0.8
    
    private init() {}
    
    func processImage(_ image: UIImage, completion: @escaping (Result<UIImage, ImageProcessingError>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            // 1. પહેલા image size check કરો
            if image.sizeInMB > self.maxSizeMB {
                DispatchQueue.main.async {
                    completion(.failure(.oversizedImage))
                }
                return
            }
            
            // 2. પહેલા quality reduction થી compression કરો
            guard let compressedImage = image.jpegData(compressionQuality: self.compressionQuality)
                .flatMap(UIImage.init) else {
                DispatchQueue.main.async {
                    completion(.failure(.compressionFailed))
                }
                return
            }
            
            // 3. જો હજી પણ મોટી હોય તો resize કરો
            if compressedImage.sizeInMB > self.maxSizeMB {
                guard let resizedImage = compressedImage.compress(targetSizeKB: 500) else {
                    DispatchQueue.main.async {
                        completion(.failure(.compressionFailed))
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    completion(.success(resizedImage))
                }
            } else {
                DispatchQueue.main.async {
                    completion(.success(compressedImage))
                }
            }
        }
    }
}


