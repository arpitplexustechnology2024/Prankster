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
        
        [leftTimeLabel, rightTimeLabel].forEach { label in
            label.backgroundColor = .white
            label.layer.cornerRadius = 4
            label.layer.masksToBounds = true
        }
        
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
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let thumb = gesture.view else { return }
        
        switch gesture.state {
        case .began:
            activeThumb = thumb
            initialTouchPoint = gesture.location(in: self)
            
        case .changed:
            let location = gesture.location(in: self)
            let deltaX = location.x - initialTouchPoint.x
            
            let trackWidth = bounds.width - 30
            let proportionalChange = deltaX / trackWidth * (maximumValue - minimumValue)
            
            if thumb === leftThumb {
                var newLeftValue = leftValue + proportionalChange
                newLeftValue = max(minimumValue, min(newLeftValue, rightValue - 0.01))
                leftValue = newLeftValue
            } else {
                var newRightValue = rightValue + proportionalChange
                newRightValue = max(leftValue + 0.01, min(newRightValue, maximumValue))
                rightValue = newRightValue
            }
            
            initialTouchPoint = location
            
            onValuesChanged?(leftValue, rightValue)
            
        case .ended:
            activeThumb = nil
            
        default:
            break
        }
    }
}

class TrimmingVC: UIViewController {
    @IBOutlet weak var startTimeLabel: UILabel!
    @IBOutlet weak var engTimeLabel: UILabel!
    @IBOutlet weak var trimmingView: UIView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var imageview: UIImageView!
    
    private var audioPlayer: AVAudioPlayer?
    var audioURL: URL?
    
    private let rangeSlider = RangeSlider()
    
    weak var delegate: SaveRecordingDelegate?
    
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
            self?.updateRangeSliderTimeLabels()
        }
    }
    
    private func updateRangeSliderTimeLabels() {
        guard let player = audioPlayer else { return }
        
        let leftTime = rangeSlider.leftValue * player.duration
        let rightTime = rangeSlider.rightValue * player.duration
        
        rangeSlider.leftTimeLabel.text = formatTime(leftTime)
        rangeSlider.rightTimeLabel.text = formatTime(rightTime)
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
            
            // Set the range slider's initial values
            rangeSlider.minimumValue = 0
            rangeSlider.maximumValue = 1
            rangeSlider.leftValue = 0
            rangeSlider.rightValue = 1
            rangeSlider.audioDuration = audioPlayer!.duration
            
            // Set initial labels to full audio duration
            self.rangeSlider.leftTimeLabel.text = formatTime(0)
            startTimeLabel.text = formatTime(0)
            engTimeLabel.text = formatTime(audioPlayer!.duration)
            self.rangeSlider.rightTimeLabel.text = formatTime(audioPlayer!.duration)
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
            let startTime = rangeSlider.leftValue * player.duration
            player.currentTime = startTime
            player.play()
            playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            
            // Stop playing when reaching end time
            let endTime = rangeSlider.rightValue * player.duration
            DispatchQueue.main.asyncAfter(deadline: .now() + (endTime - startTime)) {
                player.pause()
                self.playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            }
        }
    }
    
    @IBAction func doneButtonTapped(_ sender: Any) {
        guard let player = audioPlayer, let audioURL = audioURL else { return }
        
        let startTime = rangeSlider.leftValue * player.duration
        let endTime = rangeSlider.rightValue * player.duration
        let trimmedDuration = endTime - startTime
        
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





//class TrimmingVC: UIViewController {
//    @IBOutlet weak var startTimeLabel: UILabel!
//    @IBOutlet weak var engTimeLabel: UILabel!
//    @IBOutlet weak var trimmingView: UIView!
//    @IBOutlet weak var playButton: UIButton!
//    @IBOutlet weak var doneButton: UIButton!
//    @IBOutlet weak var cancelButton: UIButton!
//    @IBOutlet weak var imageview: UIImageView!
//
//    private var audioPlayer: AVAudioPlayer?
//    var audioURL: URL?
//
//    private let rangeSlider = RangeSlider()
//
//    weak var delegate: SaveRecordingDelegate?
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupUI()
//        setupAudioPlayer()
//    }
//
//    private func setupUI() {
//        imageview.layer.cornerRadius = 10
//
//        rangeSlider.translatesAutoresizingMaskIntoConstraints = false
//        trimmingView.addSubview(rangeSlider)
//
//        NSLayoutConstraint.activate([
//            rangeSlider.topAnchor.constraint(equalTo: trimmingView.topAnchor),
//            rangeSlider.bottomAnchor.constraint(equalTo: trimmingView.bottomAnchor),
//            rangeSlider.leadingAnchor.constraint(equalTo: trimmingView.leadingAnchor),
//            rangeSlider.trailingAnchor.constraint(equalTo: trimmingView.trailingAnchor)
//        ])
//
//        rangeSlider.onValuesChanged = { [weak self] startValue, endValue in
//            guard let self = self, let player = self.audioPlayer else { return }
//
//            let startTime = startValue * player.duration
//            let endTime = endValue * player.duration
//        }
//    }
//
//    private func formatTime(_ time: TimeInterval) -> String {
//        let minutes = Int(time) / 60
//        let seconds = Int(time) % 60
//        return String(format: "%02d:%02d", minutes, seconds)
//    }
//
//    private func setupAudioPlayer() {
//        guard let url = audioURL else { return }
//
//        do {
//            audioPlayer = try AVAudioPlayer(contentsOf: url)
//
//            // Set the range slider's initial values
//            rangeSlider.minimumValue = 0
//            rangeSlider.maximumValue = 1
//            rangeSlider.leftValue = 0
//            rangeSlider.rightValue = 1
//
//            // Set labels once to full audio duration
//            let audioDuration = audioPlayer!.duration
//            startTimeLabel.text = formatTime(0) // Always 00:00
//            engTimeLabel.text = formatTime(audioDuration) // Full duration
//
//        } catch {
//            print("Error setting up audio player: \(error)")
//        }
//    }
//
//    @IBAction func playButtonTapped(_ sender: Any) {
//        guard let player = audioPlayer else { return }
//
//        if player.isPlaying {
//            player.pause()
//            playButton.setImage(UIImage(named: "Playy"), for: .normal)
//        } else {
//            let startTime = rangeSlider.leftValue * player.duration
//            player.currentTime = startTime
//            player.play()
//            playButton.setImage(UIImage(named: "Pausee"), for: .normal)
//
//            // Stop playing when reaching end time
//            let endTime = rangeSlider.rightValue * player.duration
//            DispatchQueue.main.asyncAfter(deadline: .now() + (endTime - startTime)) {
//                player.pause()
//                self.playButton.setImage(UIImage(named: "Playy"), for: .normal)
//            }
//        }
//    }
//
//    @IBAction func doneButtonTapped(_ sender: Any) {
//        guard let player = audioPlayer, let audioURL = audioURL else { return }
//
//        let startTime = rangeSlider.leftValue * player.duration
//        let endTime = rangeSlider.rightValue * player.duration
//        let trimmedDuration = endTime - startTime
//
//        if trimmedDuration <= 15.0 {
//            trimAudio { [weak self] trimmedURL in
//                guard let self = self else { return }
//                if let url = trimmedURL {
//                    DispatchQueue.main.async {
//                        self.delegate?.didSaveRecording(audioURL: url, name: url.lastPathComponent)
//                        self.dismiss(animated: true)
//                    }
//                } else {
//                    DispatchQueue.main.async {
//                        let snackbar = CustomSnackbar(message: "Failed to trim audio.", backgroundColor: .snackbar)
//                        snackbar.show(in: self.view, duration: 3.0)
//                    }
//                }
//            }
//        } else {
//            let snackbar = CustomSnackbar(message: "Trimmed audio should be max 15 seconds.", backgroundColor: .snackbar)
//            snackbar.show(in: view, duration: 3.0)
//
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//                self.dismiss(animated: true)
//            }
//        }
//    }
//
//    private func trimAudio(completion: @escaping (URL?) -> Void) {
//        let asset = AVAsset(url: audioURL!)
//        let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A)
//
//        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
//        let trimmedFileName = "trimmed_\(Date().timeIntervalSince1970).m4a"
//        let outputURL = documentsDirectory.appendingPathComponent(trimmedFileName)
//
//        try? FileManager.default.removeItem(at: outputURL)
//
//        guard let player = audioPlayer else {
//            completion(nil)
//            return
//        }
//
//        let startTime = CMTime(seconds: rangeSlider.leftValue * player.duration, preferredTimescale: 1000)
//        let endTime = CMTime(seconds: rangeSlider.rightValue * player.duration, preferredTimescale: 1000)
//        let timeRange = CMTimeRange(start: startTime, end: endTime)
//
//        exportSession?.outputURL = outputURL
//        exportSession?.outputFileType = .m4a
//        exportSession?.timeRange = timeRange
//
//        exportSession?.exportAsynchronously {
//            switch exportSession?.status {
//            case .completed:
//                completion(outputURL)
//            default:
//                completion(nil)
//            }
//        }
//    }
//
//    @IBAction func cancelButtonTapped(_ sender: Any) {
//        self.dismiss(animated: true)
//    }
//}
