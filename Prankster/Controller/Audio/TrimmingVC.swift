//
//  TrimmingVC.swift
//  Prankster
//
//  Created by Arpit iOS Dev. on 31/01/25.
//

import UIKit
import AVFoundation

class WaveformView: UIView {
    private var samples: [Float] = []
    private let waveColor: UIColor = .systemBlue
    private let waveBackgroundColor: UIColor = .systemGray6
    
    func setSamples(_ samples: [Float]) {
        self.samples = samples
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // Draw background
        context.setFillColor(waveBackgroundColor.cgColor)
        context.fill(rect)
        
        // Draw waveform
        context.setFillColor(waveColor.cgColor)
        
        let width = rect.width
        let height = rect.height
        let midY = height / 2
        let sampleCount = samples.count
        
        let scaleFactor = width / CGFloat(sampleCount)
        
        for (index, sample) in samples.enumerated() {
            let x = CGFloat(index) * scaleFactor
            let sampleHeight = CGFloat(abs(sample)) * height
            let rect = CGRect(x: x,
                            y: midY - sampleHeight/2,
                            width: scaleFactor,
                            height: sampleHeight)
            context.fill(rect)
        }
    }
}

class AudioTrimmerView: UIView {
    private let waveformView = WaveformView()
    private let leftFrame = UIView()
    private let rightFrame = UIView()
    private let frameWidth: CGFloat = 20
    private var audioURL: URL?
    
    var minimumDuration: Double = 1.0
    var maximumDuration: Double = 15.0
    
    var startTime: Double = 0
    var endTime: Double = 0
    var totalDuration: Double = 0
    
    var onTimeRangeChanged: ((Double, Double) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        // Waveform setup
        waveformView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(waveformView)
        
        // Frames setup
        [leftFrame, rightFrame].forEach { frame in
            frame.translatesAutoresizingMaskIntoConstraints = false
            frame.backgroundColor = .systemBlue.withAlphaComponent(0.3)
            frame.layer.borderWidth = 2
            frame.layer.borderColor = UIColor.systemBlue.cgColor
            
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleFramePan(_:)))
            frame.addGestureRecognizer(panGesture)
            frame.isUserInteractionEnabled = true
            
            addSubview(frame)
        }
        
        NSLayoutConstraint.activate([
            waveformView.topAnchor.constraint(equalTo: topAnchor),
            waveformView.bottomAnchor.constraint(equalTo: bottomAnchor),
            waveformView.leadingAnchor.constraint(equalTo: leadingAnchor),
            waveformView.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            leftFrame.topAnchor.constraint(equalTo: topAnchor),
            leftFrame.bottomAnchor.constraint(equalTo: bottomAnchor),
            leftFrame.widthAnchor.constraint(equalToConstant: frameWidth),
            
            rightFrame.topAnchor.constraint(equalTo: topAnchor),
            rightFrame.bottomAnchor.constraint(equalTo: bottomAnchor),
            rightFrame.widthAnchor.constraint(equalToConstant: frameWidth)
        ])
    }
    
    func setAudioURL(_ url: URL) {
        self.audioURL = url
        loadAudioWaveform()
        resetFramePositions()
    }
    
    private func loadAudioWaveform() {
        guard let audioURL = audioURL else { return }
        
        do {
            let file = try AVAudioFile(forReading: audioURL)
            let format = AVAudioFormat(standardFormatWithSampleRate: file.fileFormat.sampleRate,
                                     channels: file.fileFormat.channelCount)
            
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format!,
                                              frameCapacity: AVAudioFrameCount(file.length)) else { return }
            
            try file.read(into: buffer)
            
            // Convert buffer to samples
            var samples: [Float] = []
            let channelData = buffer.floatChannelData?[0]
            let frameLength = Int(buffer.frameLength)
            
            // Take every Nth sample to reduce data
            let downsampleFactor = max(1, frameLength / 200)
            
            for i in stride(from: 0, to: frameLength, by: downsampleFactor) {
                samples.append(channelData?[i] ?? 0)
            }
            
            totalDuration = Double(file.length) / file.fileFormat.sampleRate
            endTime = totalDuration
            
            DispatchQueue.main.async { [weak self] in
                self?.waveformView.setSamples(samples)
            }
            
        } catch {
            print("Error loading audio file: \(error)")
        }
    }
    
    private func resetFramePositions() {
        leftFrame.frame.origin.x = 0
        rightFrame.frame.origin.x = bounds.width - frameWidth
    }
    
    @objc private func handleFramePan(_ gesture: UIPanGestureRecognizer) {
        guard let frame = gesture.view else { return }
        
        let translation = gesture.translation(in: self)
        gesture.setTranslation(.zero, in: self)
        
        let isLeftFrame = frame === leftFrame
        var newX = frame.frame.origin.x + translation.x
        
        // Constrain movement
        if isLeftFrame {
            newX = max(0, min(newX, rightFrame.frame.origin.x - frameWidth))
        } else {
            newX = max(leftFrame.frame.origin.x + frameWidth, min(newX, bounds.width - frameWidth))
        }
        
        frame.frame.origin.x = newX
        
        // Calculate times
        let startRatio = leftFrame.frame.origin.x / bounds.width
        let endRatio = (rightFrame.frame.origin.x + frameWidth) / bounds.width
        
        startTime = startRatio * totalDuration
        endTime = endRatio * totalDuration
        
        onTimeRangeChanged?(startTime, endTime)
    }
}

class TrimmingVC: UIViewController {
    private let audioTrimmerView = AudioTrimmerView()
    private var audioPlayer: AVAudioPlayer?
    var audioURL: URL!
    var delegate: SaveRecordingDelegate?
    
    @IBOutlet weak var trimmingView: UIView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var imageview: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupAudioPlayer()
    }
    
    private func setupUI() {
        imageview.layer.cornerRadius = 10
        
        audioTrimmerView.translatesAutoresizingMaskIntoConstraints = false
        trimmingView.addSubview(audioTrimmerView)
        
        NSLayoutConstraint.activate([
            audioTrimmerView.topAnchor.constraint(equalTo: trimmingView.topAnchor),
            audioTrimmerView.bottomAnchor.constraint(equalTo: trimmingView.bottomAnchor),
            audioTrimmerView.leadingAnchor.constraint(equalTo: trimmingView.leadingAnchor),
            audioTrimmerView.trailingAnchor.constraint(equalTo: trimmingView.trailingAnchor)
        ])
        
        audioTrimmerView.onTimeRangeChanged = { [weak self] startTime, endTime in
            // Handle time range updates
            print("Start time: \(startTime), End time: \(endTime)")
        }
    }
    
    private func setupAudioPlayer() {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioTrimmerView.setAudioURL(audioURL)
        } catch {
            print("Error setting up audio player: \(error)")
        }
    }
    
    @IBAction func playButtonTapped(_ sender: Any) {
        guard let player = audioPlayer else { return }
        
        if player.isPlaying {
            player.pause()
            playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        } else {
            player.currentTime = audioTrimmerView.startTime
            player.play()
            playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            
            // Stop playing when reaching end time
            DispatchQueue.main.asyncAfter(deadline: .now() + (audioTrimmerView.endTime - audioTrimmerView.startTime)) {
                player.pause()
                self.playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            }
        }
    }
    
    @IBAction func doneButtonTapped(_ sender: Any) {
        let trimmedDuration = audioTrimmerView.endTime - audioTrimmerView.startTime
        
        if trimmedDuration <= 15.0 {
            trimAudio { [weak self] trimmedURL in
                guard let self = self else { return }
                if let url = trimmedURL {
                    DispatchQueue.main.async {
                        self.delegate?.didSaveRecording(audioURL: url, name: url.lastPathComponent)
                        self.dismiss(animated: true)
                    }
                } else {
                    DispatchQueue.main.async {
                        let snackbar = CustomSnackbar(message: "Failed to trim audio.", backgroundColor: .snackbar)
                        snackbar.show(in: self.view, duration: 3.0)
                    }
                }
            }
        } else {
            let snackbar = CustomSnackbar(message: "Trimmed audio should be max 15 seconds.", backgroundColor: .snackbar)
            snackbar.show(in: self.view, duration: 3.0)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.dismiss(animated: true)
            }
        }
    }
    
    private func trimAudio(completion: @escaping (URL?) -> Void) {
        let asset = AVAsset(url: audioURL)
        let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A)
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let trimmedFileName = "trimmed_\(Date().timeIntervalSince1970).m4a"
        let outputURL = documentsDirectory.appendingPathComponent(trimmedFileName)
        
        try? FileManager.default.removeItem(at: outputURL)
        
        let startTime = CMTime(seconds: audioTrimmerView.startTime, preferredTimescale: 1000)
        let endTime = CMTime(seconds: audioTrimmerView.endTime, preferredTimescale: 1000)
        let timeRange = CMTimeRange(start: startTime, end: endTime)
        
        exportSession?.outputURL = outputURL
        exportSession?.outputFileType = .m4a
        exportSession?.timeRange = timeRange
        
        exportSession?.exportAsynchronously {
            switch exportSession?.status {
            case .completed:
                completion(outputURL)
            default:
                completion(nil)
            }
        }
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        self.dismiss(animated: true)
    }
}
