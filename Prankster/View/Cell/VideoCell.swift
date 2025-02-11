//
//  VideoCell.swift
//  Prankster
//
//  Created by Arpit iOS Dev. on 01/02/25.
//

import UIKit
import SDWebImage
import AVFoundation

// MARK: - Video Playback Manager
@available(iOS 15.0, *)
class VideoPlaybackManager {
    static let shared = VideoPlaybackManager()
    private init() {}
    
    var currentlyPlayingCell: VideoAllCollectionViewCell?
    var currentlyPlayingIndexPath: IndexPath?
    
    func stopCurrentPlayback() {
        currentlyPlayingCell?.stopVideo()
        currentlyPlayingCell = nil
        currentlyPlayingIndexPath = nil
    }
}

// MARK: - Protocols
protocol VideoAllCollectionViewCellDelegate: AnyObject {
    func didTapVideoPlayback(at indexPath: IndexPath)
}

// MARK: - Collection View Cell
@available(iOS 15.0, *)
class VideoAllCollectionViewCell: UICollectionViewCell {
    
    // MARK: - IBOutlets
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var DoneButton: UIButton!
    @IBOutlet weak var imageName: UILabel!
    @IBOutlet weak var playPauseImageView: UIImageView!
    @IBOutlet weak var premiumButton: UIButton!
    @IBOutlet weak var blurImageView: UIImageView!
    
    @IBOutlet weak var tutorialViewShowView: UIView!
    @IBOutlet weak var adContainerView: UIView!
    
    // MARK: - Properties
    weak var delegate: VideoAllCollectionViewCellDelegate?
    private var coverPageData: CharacterAllData?
    private var imageViewTimer: Timer?
    var currentIndexPath: IndexPath?
    private var playerLayer: AVPlayerLayer?
    private var player: AVPlayer?
    private var isPlaying = false
    private var isVideoLoaded = false
    private var lastPausedTime: CMTime?
    
    var premiumActionButton: UIButton!
    var originalImage: UIImage?
    private var playerLooper: AVPlayerLooper?
    
    private var currentVideoURL: URL?
    
    // MARK: - Lifecycle Methods
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupPremiumActionButton()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPremiumActionButton()
    }
    
    public func setupTutorialVideo() {
           playerLayer?.removeFromSuperlayer()
           player?.pause()
           playerLayer = nil
           player = nil
           playerLooper = nil
           
           if let videoPath = Bundle.main.path(forResource: "video", ofType: "mp4") {
               print("Video path found: \(videoPath)")
               
               let videoURL = URL(fileURLWithPath: videoPath)
               let playerItem = AVPlayerItem(url: videoURL)
               
               let queuePlayer = AVQueuePlayer()
               player = queuePlayer
               player?.isMuted = true
               playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
               playerLayer = AVPlayerLayer(player: player)
               playerLayer?.videoGravity = .resizeAspectFill

               if let playerLayer = playerLayer {
                   tutorialViewShowView.layer.addSublayer(playerLayer)
                   playerLayer.frame = tutorialViewShowView.bounds
                   player?.play()
               }
           } else {
               print("Error: Video file 'cover.mp4' not found in bundle")
           }
       }
       
       // MARK: - Lifecycle Methods
       override func didMoveToWindow() {
           super.didMoveToWindow()
           if window != nil {
               player?.play()
           } else {
               player?.pause()
           }
       }
       
    
    // MARK: - Setup Methods
    private func setupPremiumActionButton() {
        premiumActionButton = UIButton(type: .custom)
        premiumActionButton.setImage(UIImage(named: "PlayButton"), for: .normal)
        premiumActionButton.translatesAutoresizingMaskIntoConstraints = false
        premiumActionButton.isHidden = true
        contentView.addSubview(premiumActionButton)
        
        NSLayoutConstraint.activate([
            premiumActionButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            premiumActionButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            premiumActionButton.widthAnchor.constraint(equalToConstant: 80),
            premiumActionButton.heightAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        imageView.layer.cornerRadius = 20
        imageView.layer.masksToBounds = false
        imageView.layer.cornerRadius = 20
        imageView.layer.masksToBounds = true
        
        // BlurImageView Setup
        blurImageView.layer.cornerRadius = 20
        blurImageView.layer.masksToBounds = true
        
        tutorialViewShowView.layer.cornerRadius = 20
        tutorialViewShowView.layer.masksToBounds = true
        
        adContainerView.layer.cornerRadius = 20
        adContainerView.layer.masksToBounds = true
        adContainerView.isHidden = true
        
        DoneButton.layer.shadowColor = UIColor.black.cgColor
        DoneButton.layer.shadowOffset = CGSize(width: 0, height: 3)
        DoneButton.layer.shadowRadius = 3.24
        DoneButton.layer.shadowOpacity = 0.3
        DoneButton.layer.masksToBounds = false
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageViewTapped))
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(tapGesture)
        
        // Adding blur effect to imageName label background
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialLight)
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
    
    func configure(with categoryAllData: CharacterAllData) {
        self.coverPageData = categoryAllData
        
        guard let fileURLString = categoryAllData.file,
              let videoURL = URL(string: fileURLString) else {
            return
        }
        
        if currentVideoURL == videoURL {
            return
        }
        
        currentVideoURL = videoURL
        
        generateThumbnail(from: videoURL) { [weak self] image in
            DispatchQueue.main.async {
                guard let self = self,
                      self.currentVideoURL == videoURL else {
                    return
                }
                self.blurImageView.image = image
                self.originalImage = image
                self.applyBackgroundBlurEffect()
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
    
    // MARK: - Configuration
    func configure(with categoryAllData: CharacterAllData, at indexPath: IndexPath) {
        self.coverPageData = categoryAllData
        self.currentIndexPath = indexPath
        
        if categoryAllData.name.lowercased() == "ads" {
            self.adContainerView.isHidden = false
            self.premiumButton.isHidden = true
            self.premiumActionButton.isHidden = true
            self.DoneButton.isHidden = true
            self.tutorialViewShowView.isHidden = true
            
            if let parentVC = self.parentViewController as? VideoPrankVC,
               let preloadedAdView = parentVC.preloadedNativeAdView {
                // Remove any existing subviews
                adContainerView.subviews.forEach { $0.removeFromSuperview() }
                
                // Add the preloaded ad view
                adContainerView.addSubview(preloadedAdView)
                preloadedAdView.translatesAutoresizingMaskIntoConstraints = false
                
                NSLayoutConstraint.activate([
                    preloadedAdView.topAnchor.constraint(equalTo: adContainerView.topAnchor),
                    preloadedAdView.leadingAnchor.constraint(equalTo: adContainerView.leadingAnchor),
                    preloadedAdView.trailingAnchor.constraint(equalTo: adContainerView.trailingAnchor),
                    preloadedAdView.bottomAnchor.constraint(equalTo: adContainerView.bottomAnchor)
                ])
            }
            
        } else {
            self.adContainerView.isHidden = true
            self.tutorialViewShowView.isHidden = true
            
            let displayName = categoryAllData.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "---" : categoryAllData.name
            self.imageName.text = " \(displayName) "
            self.imageName.sizeToFit()
            
            if categoryAllData.premium {
                self.premiumButton.isHidden = false
            } else {
                self.premiumButton.isHidden = true
            }
            
            if categoryAllData.premium && !PremiumManager.shared.isContentUnlocked(itemID: categoryAllData.itemID) {
                self.premiumActionButton.isHidden = false
                self.DoneButton.isHidden = true
            } else {
                self.premiumActionButton.isHidden = true
                self.DoneButton.isHidden = false
                self.DoneButton.setImage(UIImage(named: "selectYesButton"), for: .normal)
            }
            
            // Only setup video playback for non-premium content
            if !categoryAllData.premium || PremiumManager.shared.isContentUnlocked(itemID: categoryAllData.itemID) {
                if let videoURL = URL(string: categoryAllData.file ?? "N/A") {
                    setupVideo(with: videoURL)
                }
            }
        }
    }
    
    // MARK: - Blur Effect Methods
    func applyBlurEffect() {
        guard let image = originalImage else { return }
        
        let context = CIContext()
        guard let ciImage = CIImage(image: image) else { return }
        
        let filter = CIFilter(name: "CIGaussianBlur")!
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(20.0, forKey: kCIInputRadiusKey)
        
        guard let outputImage = filter.outputImage,
              let cgImage = context.createCGImage(outputImage, from: ciImage.extent) else { return }
        
        imageView.image = UIImage(cgImage: cgImage)
    }
    
    func applyBackgroundBlurEffect() {
        guard let image = originalImage else { return }
        
        let context = CIContext()
        guard let ciImage = CIImage(image: image) else { return }
        
        let filter = CIFilter(name: "CIGaussianBlur")!
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(30.0, forKey: kCIInputRadiusKey)
        
        guard let outputImage = filter.outputImage,
              let cgImage = context.createCGImage(outputImage, from: ciImage.extent) else { return }
        
        blurImageView.image = UIImage(cgImage: cgImage)
    }
    
    func removeBlurEffect() {
        imageView.image = originalImage
    }
    
    func setThumbnail(for videoURL: URL) {
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        let time = CMTimeMake(value: 1, timescale: 2)
        
        imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { [weak self] _, image, _, _, _ in
            if let image = image {
                DispatchQueue.main.async {
                    self?.blurImageView.image = UIImage(cgImage: image)
                    self?.originalImage = UIImage(cgImage: image)
                    self?.applyBackgroundBlurEffect()
                }
            }
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
    
    @objc private func playerDidFinishPlaying() {
        stopVideo()
        lastPausedTime = nil
        player?.seek(to: CMTime.zero)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = imageView.bounds
        playerLayer?.frame = tutorialViewShowView.bounds
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
        player?.pause()
        playerLooper = nil
    }
    
    deinit {
        player?.pause()
        player = nil
        playerLayer = nil
        playerLooper = nil
    }
}

class VideoSliderCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    private var categoryAllData: CharacterAllData?
    var premiumIconImageView: UIImageView!
    private var currentVideoURL: URL?
    
    private var originalImage: UIImage?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    private func setupUI() {
        layer.cornerRadius = 10
        layer.masksToBounds = false
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true
        
        imageView.image = UIImage(named: "videoplacholder")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = UIImage(named: "videoplacholder")
        currentVideoURL = nil
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupPremiumIconImageView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPremiumIconImageView()
    }
    
    private func setupPremiumIconImageView() {
        premiumIconImageView = UIImageView(image: UIImage(named: "PremiumIcon"))
        premiumIconImageView.translatesAutoresizingMaskIntoConstraints = false
        premiumIconImageView.isHidden = true
        contentView.addSubview(premiumIconImageView)
        
        NSLayoutConstraint.activate([
            premiumIconImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            premiumIconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            premiumIconImageView.widthAnchor.constraint(equalToConstant: 40),
            premiumIconImageView.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    func setThumbnail(for videoURL: URL) {
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        let time = CMTimeMake(value: 1, timescale: 2)
        
        imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { [weak self] _, image, _, _, _ in
            if let image = image {
                DispatchQueue.main.async {
                    self?.imageView.image = UIImage(cgImage: image)
                }
            }
        }
    }
    
    func configure(with categoryAllData: CharacterAllData) {
        self.categoryAllData = categoryAllData
        
        if categoryAllData.name.lowercased() == "ads" {
            
            if let imageURL = URL(string: categoryAllData.image) {
                imageView.sd_setImage(with: imageURL, placeholderImage: UIImage(named: "videoplacholder"))
                self.premiumIconImageView.isHidden = true
            }
            
        } else {
            
            guard let fileURLString = categoryAllData.file,
                  let videoURL = URL(string: fileURLString) else {
                
                imageView.image = UIImage(named: "videoplacholder")
                return
            }
            
            if currentVideoURL == videoURL {
                return
            }
            
            currentVideoURL = videoURL
            
            imageView.image = UIImage(named: "videoplacholder")
            
            generateThumbnail(from: videoURL) { [weak self] image in
                DispatchQueue.main.async {
                    guard let self = self,
                          self.currentVideoURL == videoURL else {
                        return
                    }
                    self.imageView.image = image
                    self.originalImage = image
                    
                    if categoryAllData.premium && !PremiumManager.shared.isContentUnlocked(itemID: categoryAllData.itemID) {
                        self.premiumIconImageView.isHidden = false
                        self.applyBlurEffect()
                    } else {
                        self.premiumIconImageView.isHidden = true
                        self.removeBlurEffect()
                    }
                }
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
    
    func applyBlurEffect() {
        guard let image = originalImage else { return }
        
        let context = CIContext()
        guard let ciImage = CIImage(image: image) else { return }
        
        let filter = CIFilter(name: "CIGaussianBlur")!
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(50.0, forKey: kCIInputRadiusKey)
        
        guard let outputImage = filter.outputImage,
              let cgImage = context.createCGImage(outputImage, from: ciImage.extent) else { return }
        
        imageView.image = UIImage(cgImage: cgImage)
    }
    
    func removeBlurEffect() {
        imageView.image = originalImage
    }
    
    override var isSelected: Bool {
        didSet {
            layer.borderWidth = isSelected ? 3 : 0
            layer.borderColor = isSelected ? #colorLiteral(red: 1, green: 0.8470588235, blue: 0, alpha: 1) : nil
        }
    }
}
