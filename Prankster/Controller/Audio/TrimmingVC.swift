//
//  TrimmingVC.swift
//  Prankster
//
//  Created by Arpit iOS Dev. on 31/01/25.
//

import UIKit
import AVFoundation

class RangeSlider: UIView {
    private let leftThumb = UIView()
    private let rightThumb = UIView()
    private let trackView = UIView()
    private let selectedTrackView = UIView()
    
    var minimumValue: Double = 0
    var maximumValue: Double = 1
    var leftValue: Double = 0 {
        didSet {
            updateLayout()
        }
    }
    var rightValue: Double = 1 {
        didSet {
            updateLayout()
        }
    }
    
    var onValuesChanged: ((Double, Double) -> Void)?
    
    private var activeThumb: UIView?
    private var initialTouchPoint: CGPoint = .zero
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        // Track setup
        trackView.backgroundColor = .systemGray5
        addSubview(trackView)
        
        // Selected track setup
        selectedTrackView.backgroundColor = .systemBlue
        addSubview(selectedTrackView)
        
        // Thumbs setup
        [leftThumb, rightThumb].forEach { thumb in
            thumb.backgroundColor = .white
            thumb.layer.cornerRadius = 15
            thumb.layer.shadowColor = UIColor.black.cgColor
            thumb.layer.shadowOffset = CGSize(width: 0, height: 2)
            thumb.layer.shadowRadius = 3
            thumb.layer.shadowOpacity = 0.3
            addSubview(thumb)
            
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            thumb.addGestureRecognizer(panGesture)
            thumb.isUserInteractionEnabled = true
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        trackView.frame = CGRect(x: 0, y: (bounds.height - 4) / 2, width: bounds.width, height: 4)
        trackView.layer.cornerRadius = 2
        
        leftThumb.frame.size = CGSize(width: 30, height: 30)
        rightThumb.frame.size = CGSize(width: 30, height: 30)
        
        updateLayout()
    }
    
    private func updateLayout() {
        let trackWidth = bounds.width - 30
        
        let leftX = (trackWidth * CGFloat((leftValue - minimumValue) / (maximumValue - minimumValue)))
        let rightX = (trackWidth * CGFloat((rightValue - minimumValue) / (maximumValue - minimumValue)))
        
        leftThumb.center.x = leftX + 15
        leftThumb.center.y = bounds.height / 2
        
        rightThumb.center.x = rightX + 15
        rightThumb.center.y = bounds.height / 2
        
        selectedTrackView.frame = CGRect(
            x: leftThumb.center.x,
            y: trackView.frame.minY,
            width: rightThumb.center.x - leftThumb.center.x,
            height: trackView.frame.height
        )
        selectedTrackView.layer.cornerRadius = 2
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let thumb = gesture.view else { return }
        
        switch gesture.state {
        case .began:
            activeThumb = thumb
            initialTouchPoint = gesture.location(in: self)
            
        case .changed:
            let location = gesture.location(in: self)
            let deltaX = location.x - initialTouchPoint.x
            initialTouchPoint = location
            
            if thumb === leftThumb {
                var newLeftValue = leftValue + Double(deltaX / bounds.width) * (maximumValue - minimumValue)
                newLeftValue = max(minimumValue, min(newLeftValue, rightValue - 1))
                leftValue = newLeftValue
            } else {
                var newRightValue = rightValue + Double(deltaX / bounds.width) * (maximumValue - minimumValue)
                newRightValue = max(leftValue + 1, min(newRightValue, maximumValue))
                rightValue = newRightValue
            }
            
            onValuesChanged?(leftValue, rightValue)
            
        case .ended:
            activeThumb = nil
            
        default:
            break
        }
    }
}

class TrimmingVC: UIViewController {
    var audioURL: URL!
        var delegate: SaveRecordingDelegate?
        private var audioPlayer: AVAudioPlayer?
        private let rangeSlider = RangeSlider()
        private var audioDuration: Double = 0
    
    @IBOutlet weak var trimmingView: UIView!
    
    
    @IBOutlet weak var doneButton: UIButton!
    
    @IBOutlet weak var playButton: UIButton!
    
    @IBOutlet weak var cancelButton: UIButton!
    
    @IBOutlet weak var imageview: UIImageView!
    
//    init(audioURL: URL, delegate: SaveRecordingDelegate) {
//        super.init(nibName: nil, bundle: nil)
//        self.audioURL = audioURL
//        self.delegate = delegate
//    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupAudioPlayer()
    }
    
    private func setupUI() {
        
        self.imageview.layer.cornerRadius = 10
        
        // Range Slider Setup
        rangeSlider.translatesAutoresizingMaskIntoConstraints = false
        trimmingView.addSubview(rangeSlider)
        
        NSLayoutConstraint.activate([
            rangeSlider.topAnchor.constraint(equalTo: trimmingView.topAnchor),
            rangeSlider.bottomAnchor.constraint(equalTo: trimmingView.bottomAnchor),
            rangeSlider.leadingAnchor.constraint(equalTo: trimmingView.leadingAnchor),
            rangeSlider.trailingAnchor.constraint(equalTo: trimmingView.trailingAnchor),
        ])
    }
    
    private func setupAudioPlayer() {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioDuration = audioPlayer?.duration ?? 0
            rangeSlider.minimumValue = 0
            rangeSlider.maximumValue = audioDuration
            rangeSlider.leftValue = 0
            rangeSlider.rightValue = audioDuration
        } catch {
            print("Error setting up audio player: \(error)")
        }
    }
    
    @IBAction func playButtonTapped(_ sender: Any) {
    }
    
    
    @IBAction func doneButtonTapped(_ sender: Any) {
        let trimmedDuration = rangeSlider.rightValue - rangeSlider.leftValue
        
        if trimmedDuration <= 15.0 {
            // Trim and save audio
            trimAudio { [weak self] trimmedURL in
                guard let self = self else { return }
                if let url = trimmedURL {
                    // Main thread par delegate method call kariye
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
    
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    private func trimAudio(completion: @escaping (URL?) -> Void) {
        let asset = AVAsset(url: audioURL)
        let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A)
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let trimmedFileName = "trimmed_\(Date().timeIntervalSince1970).m4a"
        let outputURL = documentsDirectory.appendingPathComponent(trimmedFileName)
        
        // Delete existing file if needed
        try? FileManager.default.removeItem(at: outputURL)
        
        let startTime = CMTime(seconds: rangeSlider.leftValue, preferredTimescale: 1000)
        let endTime = CMTime(seconds: rangeSlider.rightValue, preferredTimescale: 1000)
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
}
