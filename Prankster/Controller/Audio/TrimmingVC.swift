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
    let leftTimeLabel = UILabel()
    let rightTimeLabel = UILabel()
    
    private var labelHideTimer: Timer?
    private var lastPanLocation: CGPoint?
    private var panStartTime: Date?
    private var panVelocityThreshold: CGFloat = 200
    
    var minimumSelectionDuration: TimeInterval = 5.0
    
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
    
    var audioDuration: TimeInterval = 0 {
        didSet {
            updateTimeLabels()
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
        [leftTimeLabel, rightTimeLabel].forEach { label in
            label.font = .systemFont(ofSize: 12)
            label.textColor = .darkGray
            label.textAlignment = .center
            label.backgroundColor = .white
            label.layer.cornerRadius = 4
            label.layer.masksToBounds = true
            label.alpha = 0
            addSubview(label)
        }
        
        trackView.backgroundColor = .lightGray
        addSubview(trackView)
        
        selectedTrackView.backgroundColor = #colorLiteral(red: 1, green: 0.8470588235, blue: 0, alpha: 1)
        addSubview(selectedTrackView)
        
        [leftThumb, rightThumb].forEach { thumb in
            thumb.backgroundColor = #colorLiteral(red: 1, green: 0.8470588235, blue: 0, alpha: 1)
            thumb.layer.borderWidth = 5
            thumb.layer.borderColor = UIColor.darkGray.cgColor
            thumb.layer.cornerRadius = 12.5
            addSubview(thumb)
            
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            thumb.addGestureRecognizer(panGesture)
            thumb.isUserInteractionEnabled = true
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        trackView.frame = CGRect(x: 0, y: (bounds.height - 4) / 2 + 20, width: bounds.width, height: 8)
        trackView.layer.cornerRadius = 4
        
        leftThumb.frame.size = CGSize(width: 25, height: 25)
        rightThumb.frame.size = CGSize(width: 25, height: 25)
        
        updateLayout()
    }
    
    private func updateLayout() {
        let trackWidth = bounds.width - 30
        
        let leftX = (trackWidth * CGFloat((leftValue - minimumValue) / (maximumValue - minimumValue)))
        let rightX = (trackWidth * CGFloat((rightValue - minimumValue) / (maximumValue - minimumValue)))
        
        leftThumb.center.x = leftX + 15
        leftThumb.center.y = bounds.height / 2 + 20
        
        rightThumb.center.x = rightX + 15
        rightThumb.center.y = bounds.height / 2 + 20
        
        selectedTrackView.frame = CGRect(
            x: leftThumb.center.x,
            y: trackView.frame.minY,
            width: rightThumb.center.x - leftThumb.center.x,
            height: trackView.frame.height
        )
        selectedTrackView.layer.cornerRadius = 4
        
        updateTimeLabels()
    }
    
    private func updateTimeLabels() {
        let leftTime = leftValue * audioDuration
        let rightTime = rightValue * audioDuration
        
        leftTimeLabel.text = formatTime(leftTime)
        rightTimeLabel.text = formatTime(rightTime)
        
        let labelWidth: CGFloat = 50
        let labelHeight: CGFloat = 25
        
        leftTimeLabel.frame = CGRect(
            x: leftThumb.center.x - labelWidth/2,
            y: 15,
            width: labelWidth,
            height: labelHeight
        )
        
        rightTimeLabel.frame = CGRect(
            x: rightThumb.center.x - labelWidth/2,
            y: 15,
            width: labelWidth,
            height: labelHeight
        )
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func showLabels() {
        labelHideTimer?.invalidate()
        
        UIView.animate(withDuration: 0.3) {
            self.leftTimeLabel.alpha = 1
            self.rightTimeLabel.alpha = 1
        }
    }
    
    private func hideLabelsAfterDelay() {
        labelHideTimer?.invalidate()
        
        labelHideTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            UIView.animate(withDuration: 0.3) {
                self?.leftTimeLabel.alpha = 0
                self?.rightTimeLabel.alpha = 0
            }
        }
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let thumb = gesture.view else { return }
        
        let location = gesture.location(in: self)
        
        switch gesture.state {
        case .began:
            activeThumb = thumb
            initialTouchPoint = location
            lastPanLocation = location
            panStartTime = Date()
            showLabels()
            
        case .changed:
            guard let lastLocation = lastPanLocation,
                  let startTime = panStartTime else { return }
            
            let velocity = abs(location.x - lastLocation.x)
            let timeDelta = CGFloat(Date().timeIntervalSince(startTime))
            let panVelocity = timeDelta > 0 ? velocity / timeDelta : 0
            
            let deltaX = location.x - initialTouchPoint.x
            let trackWidth = bounds.width - 30
            let proportionalChange = deltaX / trackWidth * (maximumValue - minimumValue)

            let currentDuration = (rightValue - leftValue) * audioDuration
            
            if thumb === leftThumb {
                var newLeftValue = leftValue + proportionalChange
                let newDuration = (rightValue - newLeftValue) * audioDuration
                
                if newDuration < minimumSelectionDuration {
                    newLeftValue = rightValue - (minimumSelectionDuration / audioDuration)
                }
                
                if newDuration > 15.0 {
                    let fifteenSecondsInValue = 15.0 / audioDuration
                    rightValue = min(newLeftValue + fifteenSecondsInValue, maximumValue)
                    leftValue = max(rightValue - fifteenSecondsInValue, minimumValue)
                } else {
                    leftValue = max(minimumValue, newLeftValue)
                }
                
            } else {
                var newRightValue = rightValue + proportionalChange
                let newDuration = (newRightValue - leftValue) * audioDuration
                
                if newDuration < minimumSelectionDuration {
                    newRightValue = leftValue + (minimumSelectionDuration / audioDuration)
                }

                if newDuration > 15.0 {
                    let fifteenSecondsInValue = 15.0 / audioDuration
                    leftValue = max(newRightValue - fifteenSecondsInValue, minimumValue)
                    rightValue = min(leftValue + fifteenSecondsInValue, maximumValue)
                } else {
                    rightValue = min(maximumValue, newRightValue)
                }
            }
            
            initialTouchPoint = location
            lastPanLocation = location
            
            if panVelocity < panVelocityThreshold {
                showLabels()
            }
            
            onValuesChanged?(leftValue, rightValue)
            
        case .ended, .cancelled:
            activeThumb = nil
            lastPanLocation = nil
            panStartTime = nil
            hideLabelsAfterDelay()
            
        default:
            break
        }
    }
}

class TrimmingVC: UIViewController {
    @IBOutlet weak var trimmingView: UIView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var imageview: UIImageView!
    
    private var audioPlayer: AVAudioPlayer?
    var audioURL: URL?
    
    private let rangeSlider = RangeSlider()
    
    weak var delegate: SaveRecordingDelegate?
    
    private var playingTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupAudioPlayer()
    }
    
    private func setupUI() {
        imageview.layer.cornerRadius = 10
        
        rangeSlider.translatesAutoresizingMaskIntoConstraints = false
        trimmingView.addSubview(rangeSlider)
        
        NSLayoutConstraint.activate([
            rangeSlider.topAnchor.constraint(equalTo: trimmingView.topAnchor),
            rangeSlider.bottomAnchor.constraint(equalTo: trimmingView.bottomAnchor),
            rangeSlider.leadingAnchor.constraint(equalTo: trimmingView.leadingAnchor),
            rangeSlider.trailingAnchor.constraint(equalTo: trimmingView.trailingAnchor)
        ])
        
        rangeSlider.onValuesChanged = { [weak self] startValue, endValue in
            guard let self = self,
                  let player = self.audioPlayer else { return }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func setupAudioPlayer() {
        guard let url = audioURL else { return }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            
            rangeSlider.minimumValue = 0
            rangeSlider.maximumValue = 1
            rangeSlider.leftValue = 0
            
            let fifteenSecondsValue = min(15.0 / audioPlayer!.duration, 1.0)
            rangeSlider.rightValue = fifteenSecondsValue
            
            rangeSlider.audioDuration = audioPlayer!.duration
            rangeSlider.minimumSelectionDuration = 3.0
            
            updateRangeSliderTimeLabels()
        } catch {
            print("Error setting up audio player: \(error)")
        }
    }
    
    private func updateRangeSliderTimeLabels() {
        guard let player = audioPlayer else { return }
        
        let leftTime = rangeSlider.leftValue * player.duration
        let rightTime = rangeSlider.rightValue * player.duration
        
        rangeSlider.leftTimeLabel.text = formatTime(leftTime)
        rangeSlider.rightTimeLabel.text = formatTime(rightTime)
    }
    
    @IBAction func playButtonTapped(_ sender: Any) {
        guard let player = audioPlayer else { return }
        
        if player.isPlaying {
            player.pause()
            playButton.setImage(UIImage(named: "Playy"), for: .normal)
            stopPlayingTimer()
        } else {
            let startTime = rangeSlider.leftValue * player.duration
            player.currentTime = startTime
            player.play()
            playButton.setImage(UIImage(named: "Pausee"), for: .normal)
            startPlayingTimer()
            
            let endTime = rangeSlider.rightValue * player.duration
            DispatchQueue.main.asyncAfter(deadline: .now() + (endTime - startTime)) { [weak self] in
                guard let self = self else { return }
                self.audioPlayer?.pause()
                self.playButton.setImage(UIImage(named: "Playy"), for: .normal)
                self.stopPlayingTimer()
            }
        }
    }
    
    private func stopPlayingTimer() {
        playingTimer?.invalidate()
        playingTimer = nil
    }
    
    private func startPlayingTimer() {
        playingTimer?.invalidate()
        playingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
        }
    }
    
    @IBAction func doneButtonTapped(_ sender: Any) {
        guard let player = audioPlayer, let audioURL = audioURL else { return }
        
        let startTime = rangeSlider.leftValue * player.duration
        let endTime = rangeSlider.rightValue * player.duration
        let trimmedDuration = endTime - startTime
        
        player.pause()
        playButton.setImage(UIImage(named: "Playy"), for: .normal)
        
        if trimmedDuration <= 16.0 {
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
            snackbar.show(in: view, duration: 3.0)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.dismiss(animated: true)
            }
        }
    }
    
    private func trimAudio(completion: @escaping (URL?) -> Void) {
        let asset = AVAsset(url: audioURL!)
        let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A)
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let trimmedFileName = "trimmed_\(Date().timeIntervalSince1970).m4a"
        let outputURL = documentsDirectory.appendingPathComponent(trimmedFileName)
        
        try? FileManager.default.removeItem(at: outputURL)
        
        guard let player = audioPlayer else {
            completion(nil)
            return
        }
        
        let startTime = CMTime(seconds: rangeSlider.leftValue * player.duration, preferredTimescale: 1000)
        let endTime = CMTime(seconds: rangeSlider.rightValue * player.duration, preferredTimescale: 1000)
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
