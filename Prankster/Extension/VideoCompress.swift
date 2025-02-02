//
//  VideoCompress.swift
//  Prankster
//
//  Created by Arpit iOS Dev. on 01/02/25.
//

import Foundation
import UIKit
import AVFoundation

// MARK: - Video Processing Manager
class VideoProcessingManager {
    static let shared = VideoProcessingManager()
    
    private init() {}
    
    func processVideo(from url: URL, completion: @escaping (Result<URL, ProcessingError>) -> Void) {
        let asset = AVAsset(url: url)
        let duration = CMTimeGetSeconds(asset.duration)
        
        if duration > 180 { // 3 minutes limit
            completion(.failure(.durationTooLong))
            return
        }
        
        // Create output URL
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let outputURL = documentsDirectory.appendingPathComponent("\(UUID().uuidString).mp4")
        
        // Setup video compression
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetMediumQuality) else {
            completion(.failure(.processingFailed))
            return
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true
        
        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                switch exportSession.status {
                case .completed:
                    completion(.success(outputURL))
                case .failed:
                    completion(.failure(.processingFailed))
                case .cancelled:
                    completion(.failure(.cancelled))
                default:
                    completion(.failure(.unknown))
                }
            }
        }
    }
}

enum ProcessingError: Error {
    case sizeTooLarge
    case durationTooLong
    case processingFailed
    case cancelled
    case unknown
    
    var message: String {
        switch self {
        case .sizeTooLarge:
            return "Video size should be less than 50MB"
        case .durationTooLong:
            return "Video duration should be less than 3 minutes"
        case .processingFailed:
            return "Failed to process video"
        case .cancelled:
            return "Video processing was cancelled"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
