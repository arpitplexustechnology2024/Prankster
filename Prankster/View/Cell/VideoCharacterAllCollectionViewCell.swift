//
//  VideoCharacterAllCollectionViewCell.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 21/10/24.
//

import UIKit
import SDWebImage
import AVFoundation

// MARK: - Global VideoMute Manager
class GlobalVideoMuteManager {
    static let shared = GlobalVideoMuteManager()
    private init() {}
    
    var isMutedGlobally = true
    var muteStatusChangeHandlers: [() -> Void] = []
    
    func toggleGlobalMuteStatus() {
        isMutedGlobally = !isMutedGlobally
        muteStatusChangeHandlers.forEach { $0() }
    }
}

// MARK: - Video Playback Manager
class VideoPlaybackManager {
    static let shared = VideoPlaybackManager()
    private init() {}
    
    var currentlyPlayingCell: VideoCharacterAllCollectionViewCell?
    var currentlyPlayingIndexPath: IndexPath?
    
    func stopCurrentPlayback() {
        currentlyPlayingCell?.stopVideo()
        currentlyPlayingCell = nil
        currentlyPlayingIndexPath = nil
    }
}

// MARK: - Protocols
protocol VideoCharacterAllCollectionViewCellDelegate: AnyObject {
    func didTapDoneButton(for categoryAllData: CategoryAllData)
    func didTapVideoPlayback(at indexPath: IndexPath)
}

// MARK: - Collection View Cell
class VideoCharacterAllCollectionViewCell: UICollectionViewCell {
    
    // MARK: - IBOutlets
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var DoneButton: UIButton!
    @IBOutlet weak var imageName: UILabel!
    @IBOutlet weak var playPauseImageView: UIImageView!
    @IBOutlet weak var muteButton: UIButton!
    @IBOutlet weak var premiumButton: UIButton!
    
    // MARK: - Properties
    weak var delegate: VideoCharacterAllCollectionViewCellDelegate?
    private var coverPageData: CategoryAllData?
    private var imageViewTimer: Timer?
    var currentIndexPath: IndexPath?
    private var playerLayer: AVPlayerLayer?
    private var player: AVPlayer?
    private var isPlaying = false
    private var isVideoLoaded = false
    private var lastPausedTime: CMTime?
    private var isMuted = false
    private var nameBlurView: UIVisualEffectView!
    
    // MARK: - Lifecycle Methods
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
        setupGlobalMuteObserver()
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        imageView.layer.cornerRadius = 20
        imageView.layer.masksToBounds = false
        imageView.layer.cornerRadius = 20
        imageView.layer.masksToBounds = true
        
        let labelBlurEffect = UIBlurEffect(style: .light)
        nameBlurView = UIVisualEffectView(effect: labelBlurEffect)
        nameBlurView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        
        imageName.backgroundColor = .clear
        imageName.textColor = .white
        imageName.layer.masksToBounds = true
        
        contentView.insertSubview(nameBlurView, belowSubview: imageName)
        
        DoneButton.layer.shadowColor = UIColor.black.cgColor
        DoneButton.layer.shadowOffset = CGSize(width: 0, height: 3)
        DoneButton.layer.shadowRadius = 3.24
        DoneButton.layer.shadowOpacity = 0.3
        DoneButton.layer.masksToBounds = false
        
        DoneButton.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        premiumButton.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        muteButton.addTarget(self, action: #selector(muteButtonTapped), for: .touchUpInside)
        muteButton.setImage(UIImage(named: "UnmuteIcon"), for: .normal)
        muteButton.isHidden = true
        muteButton.layer.cornerRadius = muteButton.frame.height / 2
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageViewTapped))
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(tapGesture)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: - Configuration
    func configure(with coverPageData: CategoryAllData, at indexPath: IndexPath) {
        self.coverPageData = coverPageData
        self.currentIndexPath = indexPath
        let displayName = coverPageData.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "---" : coverPageData.name
        self.imageName.text = "  \(displayName)  "
        
        if coverPageData.premium && !PremiumManager.shared.isContentUnlocked(itemID: coverPageData.itemID) {
            self.premiumButton.isHidden = false
            self.DoneButton.setImage(UIImage(named: "selectYesButton"), for: .normal)
        } else {
            self.premiumButton.isHidden = true
            self.DoneButton.setImage(UIImage(named: "selectYesButton"), for: .normal)
        }
        
        if let videoURL = URL(string: coverPageData.file ?? "N/A") {
            setupVideo(with: videoURL)
        }
        player?.isMuted = GlobalVideoMuteManager.shared.isMutedGlobally
        updateMuteButtonImage()
    }
    
    private func setupVideo(with url: URL) {
        stopVideo()
        playerLayer?.removeFromSuperlayer()
        
        let player = AVPlayer(url: url)
        let playerLayer = AVPlayerLayer(player: player)
        
        playerLayer.videoGravity = .resizeAspect
        playerLayer.frame = imageView.bounds
        imageView.layer.addSublayer(playerLayer)
        
        self.player = player
        self.playerLayer = playerLayer
        
        self.isVideoLoaded = true
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerDidFinishPlaying),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: player.currentItem)
    }
    
    // MARK: - Video Control Methods
    func playVideo() {
        guard isVideoLoaded, let player = player else {
            return
        }
        player.isMuted = GlobalVideoMuteManager.shared.isMutedGlobally
        AudioPlaybackManager.shared.stopCurrentPlayback()
        
        if let pausedTime = lastPausedTime {
            player.seek(to: pausedTime)
        }
        
        player.play()
        self.playPauseImageView.isHidden = true
        isPlaying = true
        muteButton.isHidden = false
        
        VideoPlaybackManager.shared.currentlyPlayingCell = self
        VideoPlaybackManager.shared.currentlyPlayingIndexPath = currentIndexPath
    }
    
    func stopVideo() {
        let currentTime = player?.currentTime()
        
        player?.pause()
        showPauseImage()
        isPlaying = false
        imageViewTimer?.invalidate()
        muteButton.isHidden = true
        lastPausedTime = currentTime
    }
    
    private func toggleAudioPlayback() {
        if !isVideoLoaded {
            return
        }
        
        if let indexPath = currentIndexPath {
            delegate?.didTapVideoPlayback(at: indexPath)
        }
    }
    
    func showPauseImage() {
        playPauseImageView.image = UIImage(named: "PlayButton")
        playPauseImageView.isHidden = false
    }
    
    // MARK: - Action Methods
    @objc private func imageViewTapped() {
        toggleAudioPlayback()
    }
    
    @objc private func doneButtonTapped() {
        stopVideo()
        if let coverPageData = coverPageData {
            delegate?.didTapDoneButton(for: coverPageData)
        }
    }
    
    @objc private func muteButtonTapped() {
        GlobalVideoMuteManager.shared.toggleGlobalMuteStatus()
    }
    
    @objc private func playerDidFinishPlaying() {
        stopVideo()
        lastPausedTime = nil
        player?.seek(to: CMTime.zero)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = imageView.bounds
        
        let padding: CGFloat = 4
        nameBlurView.frame = imageName.frame.insetBy(dx: -padding, dy: -padding)
        nameBlurView.layer.cornerRadius = nameBlurView.frame.height / 2
        nameBlurView.layer.masksToBounds = true
    }
    
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        NotificationCenter.default.removeObserver(self)
        
        stopVideo()
        playerLayer?.removeFromSuperlayer()
        player = nil
        playerLayer = nil
        isVideoLoaded = false
        lastPausedTime = nil
        GlobalVideoMuteManager.shared.muteStatusChangeHandlers.removeAll { $0 as? () -> Void == nil }
    }
    
    private func setupGlobalMuteObserver() {
        let handler = { [weak self] in
            guard let self = self, let player = self.player else { return }
            player.isMuted = GlobalVideoMuteManager.shared.isMutedGlobally
            self.updateMuteButtonImage()
        }
        GlobalVideoMuteManager.shared.muteStatusChangeHandlers.append(handler)
    }
    
    private func updateMuteButtonImage() {
        let isMuted = GlobalVideoMuteManager.shared.isMutedGlobally
        muteButton.setImage(UIImage(named: isMuted ? "Mute" : "Unmute"), for: .normal)
    }
}

class VideoCharacterSliderCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    private var categoryAllData: CategoryAllData?
    private var currentVideoURL: URL?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    private func setupUI() {
        layer.cornerRadius = 10
        layer.masksToBounds = false
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true
        
        imageView.image = UIImage(named: "PlaceholderVideo")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = UIImage(named: "PlaceholderVideo")
        currentVideoURL = nil
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func configure(with categoryAllData: CategoryAllData) {
        self.categoryAllData = categoryAllData
        
        guard let fileURLString = categoryAllData.file,
              let videoURL = URL(string: fileURLString) else {
            
            imageView.image = UIImage(named: "PlaceholderVideo")
            return
        }
        
        if currentVideoURL == videoURL {
            return
        }
        
        currentVideoURL = videoURL
        
        imageView.image = UIImage(named: "PlaceholderVideo")
        
        generateThumbnail(from: videoURL) { [weak self] image in
            DispatchQueue.main.async {
                guard let self = self,
                      self.currentVideoURL == videoURL else {
                    return
                }
                self.imageView.image = image
            }
        }
    }
    
    private func generateThumbnail(from url: URL, completion: @escaping (UIImage?) -> Void) {
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSize(width: 200, height: 200)
        
        let time = CMTime(seconds: 1, preferredTimescale: 600)
        imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, cgImage, _, _, _ in
            if let cgImage = cgImage {
                let image = UIImage(cgImage: cgImage)
                completion(image)
            } else {
                completion(nil)
            }
        }
    }
    
    override var isSelected: Bool {
        didSet {
            layer.borderWidth = isSelected ? 3 : 0
            layer.borderColor = isSelected ? UIColor.white.cgColor : nil
        }
    }
}
