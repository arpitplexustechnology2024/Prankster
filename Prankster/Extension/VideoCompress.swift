//
//  VideoCompress.swift
//  Prankster
//
//  Created by Arpit iOS Dev. on 01/02/25.
//

import UIKit
import AVFoundation
import AVKit

// 1. પહેલા વીડિયો પ્રોસેસિંગ એરર્સ ડિફાઈન કરીએ
enum VideoProcessingError: Error {
    case oversizedVideo
    case compressionFailed
    case invalidURL
    case downloadFailed
    case processingFailed
    
    var message: String {
        switch self {
        case .oversizedVideo:
            return "Video size must be less than 15MB"
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

// 2. વીડિયો પ્રોસેસિંગ મેનેજર ક્લાસ
class VideoProcessingManager {
    static let shared = VideoProcessingManager()
    private let maxSizeMB: Double = 15.0
    private let processingQueue = DispatchQueue(label: "com.app.videoProcessing")
    
    private init() {}
    
    // વીડિયો ડાઉનલોડ કરવાનું ફંક્શન
    func downloadVideo(from url: URL, completion: @escaping (Result<URL, VideoProcessingError>) -> Void) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsPath.appendingPathComponent("downloaded_video.mp4")
        
        // જો પહેલાથી ફાઈલ એક્ઝિસ્ટ કરતી હોય તો ડિલીટ કરો
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
    
    // વીડિયો કમ્પ્રેસ કરવાનું ફંક્શન
    func compressVideo(inputURL: URL, completion: @escaping (Result<URL, VideoProcessingError>) -> Void) {
        let asset = AVAsset(url: inputURL)
        
        // ચેક કરો કે વીડિયો સાઈઝ 15MB થી વધારે તો નથીને
        let videoSize = try? inputURL.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        let videoSizeMB = Double(videoSize ?? 0) / (1024 * 1024)
        
        if videoSizeMB <= maxSizeMB {
            completion(.success(inputURL))
            return
        }
        
        // કમ્પ્રેશન સેટિંગ્સ
        let compression = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 4000000,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,  // હાઇ પ્રોફાઈલ વાપરી
                AVVideoMaxKeyFrameIntervalKey: 30,  // કી-ફ્રેમ ઈન્ટરવલ ઓછો કર્યો
                AVVideoExpectedSourceFrameRateKey: 30  // ફ્રેમરેટ ફિક્સ કર્યો
                
            ]
        ] as [String: Any]
        
        let outputURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("compressed_video.mp4")
        
        // જો પહેલાથી ફાઈલ એક્ઝિસ્ટ કરતી હોય તો ડિલીટ કરો
        try? FileManager.default.removeItem(at: outputURL)
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetMediumQuality) else {
            completion(.failure(.compressionFailed))
            return
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.videoComposition = nil
        exportSession.shouldOptimizeForNetworkUse = true
        
        // વધારાના કમ્પ્રેશન સેટિંગ્સ
        exportSession.audioTimePitchAlgorithm = .spectral
        exportSession.videoComposition = nil
        
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                completion(.success(outputURL))
            default:
                completion(.failure(.compressionFailed))
            }
        }
    }
}
