//
//  VideoCompress.swift
//  Prankster
//
//  Created by Arpit iOS Dev. on 01/02/25.
//

import UIKit
import AVFoundation
import AVKit

enum VideoProcessingError: Error {
    case oversizedVideo
    case compressionFailed
    case invalidURL
    case downloadFailed
    case processingFailed
    
    var message: String {
        switch self {
        case .oversizedVideo:
            return "Video size must be upto 15MB"
        case .compressionFailed:
            return "Failed to compress video"
        case .invalidURL:
            return "Invalid video URL"
        case .downloadFailed:
            return "Failed to download video"
        case .processingFailed:
            return "Failed to process video"
        }
    }
}

class VideoProcessingManager {
    static let shared = VideoProcessingManager()
    private let maxSizeMB: Double = 30.0
    private let processingQueue = DispatchQueue(label: "com.app.videoProcessing")
    
    private init() {}
    
    func downloadVideo(from url: URL, completion: @escaping (Result<URL, VideoProcessingError>) -> Void) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsPath.appendingPathComponent("downloaded_video.mp4")
        
        try? FileManager.default.removeItem(at: destinationURL)
        
        let downloadTask = URLSession.shared.downloadTask(with: url) { tempURL, response, error in
            if let error = error {
                print("Download error: \(error.localizedDescription)")
                completion(.failure(.downloadFailed))
                return
            }
            
            guard let tempURL = tempURL else {
                completion(.failure(.downloadFailed))
                return
            }
            
            do {
                try FileManager.default.moveItem(at: tempURL, to: destinationURL)
                completion(.success(destinationURL))
            } catch {
                print("File move error: \(error.localizedDescription)")
                completion(.failure(.downloadFailed))
            }
        }
        
        downloadTask.resume()
    }
    
    func compressVideo(inputURL: URL, completion: @escaping (Result<URL, VideoProcessingError>) -> Void) {
        let asset = AVAsset(url: inputURL)
        
        let videoSize = try? inputURL.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        let videoSizeMB = Double(videoSize ?? 0) / (1024 * 1024)
        
        if videoSizeMB <= maxSizeMB {
            completion(.success(inputURL))
            return
        }
        
        let compression = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 2000000,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
                AVVideoMaxKeyFrameIntervalKey: 30,
                AVVideoExpectedSourceFrameRateKey: 30
            ]
        ] as [String: Any]
        
        let outputURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("compressed_video.mp4")
        
        try? FileManager.default.removeItem(at: outputURL)
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            completion(.failure(.compressionFailed))
            return
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.videoComposition = nil
        exportSession.shouldOptimizeForNetworkUse = true
        
        exportSession.audioTimePitchAlgorithm = .spectral
        
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                completion(.success(outputURL))
            default:
                print("Export failed with error: \(String(describing: exportSession.error))")
                completion(.failure(.compressionFailed))
            }
        }
    }
    
    
    func processVideo(inputURL: URL, completion: @escaping (Result<URL, VideoProcessingError>) -> Void) {
        let originalSize = try? inputURL.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        let originalSizeMB = Double(originalSize ?? 0) / (1024 * 1024)
        print("Original video size: \(String(format: "%.2f", originalSizeMB)) MB")
        
        compresssVideo(inputURL: inputURL) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let compressedURL):
                let compressedSize = try? compressedURL.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                let compressedSizeMB = Double(compressedSize ?? 0) / (1024 * 1024)
                print("Compressed video size: \(String(format: "%.2f", compressedSizeMB)) MB")
                
                if compressedSizeMB > self.maxSizeMB {
                    completion(.failure(.oversizedVideo))
                    try? FileManager.default.removeItem(at: compressedURL)
                } else {
                    completion(.success(compressedURL))
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func compresssVideo(inputURL: URL, completion: @escaping (Result<URL, VideoProcessingError>) -> Void) {
        let asset = AVAsset(url: inputURL)
        
        let compression = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 10000000,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
                AVVideoMaxKeyFrameIntervalKey: 60,
                AVVideoExpectedSourceFrameRateKey: 60,
                AVVideoMaxKeyFrameIntervalDurationKey: 1,
                AVVideoAllowFrameReorderingKey: true,
                AVVideoH264EntropyModeKey: AVVideoH264EntropyModeCABAC
            ]
        ] as [String: Any]
        
        let outputURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("compressed_video.mp4")
        
        try? FileManager.default.removeItem(at: outputURL)
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            completion(.failure(.compressionFailed))
            return
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true
        
        if let videoTrack = asset.tracks(withMediaType: .video).first {
            let composition = AVMutableVideoComposition()
            composition.renderSize = videoTrack.naturalSize
            composition.frameDuration = CMTimeMake(value: 1, timescale: 60)
            composition.renderScale = 1.0
            
            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = CMTimeRangeMake(start: .zero, duration: asset.duration)
            
            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
            instruction.layerInstructions = [layerInstruction]
        }
        
        exportSession.audioTimePitchAlgorithm = .spectral
        
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                completion(.success(outputURL))
            default:
                print("Export failed with error: \(String(describing: exportSession.error))")
                completion(.failure(.compressionFailed))
            }
        }
    }
}
