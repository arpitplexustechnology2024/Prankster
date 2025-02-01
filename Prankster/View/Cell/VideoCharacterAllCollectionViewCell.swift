//
//  VideoCharacterAllCollectionViewCell.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 21/10/24.
//

import UIKit
import SDWebImage
import AVFoundation

// MARK: - Video Playback Manager
@available(iOS 15.0, *)
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
@available(iOS 15.0, *)
class VideoCharacterAllCollectionViewCell: UICollectionViewCell {
    
    // MARK: - IBOutlets
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var DoneButton: UIButton!
    @IBOutlet weak var imageName: UILabel!
    @IBOutlet weak var playPauseImageView: UIImageView!
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
    
    // MARK: - Lifecycle Methods
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        imageView.layer.cornerRadius = 20
        imageView.layer.masksToBounds = false
        imageView.layer.cornerRadius = 20
        imageView.layer.masksToBounds = true
        
        DoneButton.layer.shadowColor = UIColor.black.cgColor
        DoneButton.layer.shadowOffset = CGSize(width: 0, height: 3)
        DoneButton.layer.shadowRadius = 3.24
        DoneButton.layer.shadowOpacity = 0.3
        DoneButton.layer.masksToBounds = false
        
        DoneButton.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        premiumButton.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageViewTapped))
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(tapGesture)
        
        // Adding blur effect to imageName label background
           let blurEffect = UIBlurEffect(style: .light)
           let blurEffectView = UIVisualEffectView(effect: blurEffect)
           blurEffectView.clipsToBounds = true
           blurEffectView.translatesAutoresizingMaskIntoConstraints = false
           contentView.insertSubview(blurEffectView, belowSubview: imageName)
           
           NSLayoutConstraint.activate([
               blurEffectView.leadingAnchor.constraint(equalTo: imageName.leadingAnchor, constant: -8),
               blurEffectView.trailingAnchor.constraint(equalTo: imageName.trailingAnchor, constant: 8),
               blurEffectView.topAnchor.constraint(equalTo: imageName.topAnchor, constant: -4),
               blurEffectView.bottomAnchor.constraint(equalTo: imageName.bottomAnchor, constant: 4)
           ])
        
        // Update corner radius after layout
        DispatchQueue.main.async {
            blurEffectView.layer.cornerRadius = blurEffectView.frame.height / 2
        }
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
        self.imageName.sizeToFit()
        
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
        AudioPlaybackManager.shared.stopCurrentPlayback()
        
        if let pausedTime = lastPausedTime {
            player.seek(to: pausedTime)
        }
        
        player.play()
        self.playPauseImageView.isHidden = true
        isPlaying = true
        
        VideoPlaybackManager.shared.currentlyPlayingCell = self
        VideoPlaybackManager.shared.currentlyPlayingIndexPath = currentIndexPath
    }
    
    func stopVideo() {
        let currentTime = player?.currentTime()
        
        player?.pause()
        showPauseImage()
        isPlaying = false
        imageViewTimer?.invalidate()
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
    
    @objc private func playerDidFinishPlaying() {
        stopVideo()
        lastPausedTime = nil
        player?.seek(to: CMTime.zero)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = imageView.bounds
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
