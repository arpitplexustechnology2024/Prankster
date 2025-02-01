//
//  Audiocell.swift
//  Prankster
//
//  Created by Arpit iOS Dev. on 30/01/25.
//

import AVFoundation
import CoreImage
import SDWebImage
import UIKit

// MARK: - Video Playback Manager
@available(iOS 15.0, *)
class AudioPlaybackManager {
    static let shared = AudioPlaybackManager()
    private init() {}
    
    var currentlyPlayingCell: AudioCharacterAllCollectionViewCell?
    var currentlyPlayingIndexPath: IndexPath?
    
    func stopCurrentPlayback() {
        currentlyPlayingCell?.stopAudio()
        currentlyPlayingCell = nil
        currentlyPlayingIndexPath = nil
    }
}

// MARK: - Protocols
protocol AudioAllCollectionViewCellDelegate: AnyObject {
    func didTapPremiumIcon(for categoryAllData: CategoryAllData)
    func didTapDoneButton(for categoryAllData: CategoryAllData)
    func didTapAudioPlayback(at indexPath: IndexPath)
}

// MARK: - Collection View Cell
@available(iOS 15.0, *)
class AudioCharacterAllCollectionViewCell: UICollectionViewCell {
    
    // MARK: - IBOutlets
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var playPauseImageView: UIImageView!
    @IBOutlet weak var DoneButton: UIButton!
    @IBOutlet weak var audioLabel: UILabel!
    @IBOutlet weak var premiumButton: UIButton!
    @IBOutlet weak var blurImageView: UIImageView!
    
    @IBOutlet weak var adContainerView: UIView!
    
    // MARK: - Properties
    weak var delegate: AudioAllCollectionViewCellDelegate?
    private var categoryAllData: CategoryAllData?
    private var audioPlayer: AVAudioPlayer?
    private var imageViewTimer: Timer?
    private var isAudioPlaying = false
    private var currentIndexPath: IndexPath?
    private var audioDownloadTask: URLSessionDataTask?
    private var isAudioLoaded = false
    var premiumActionButton: UIButton!
    var originalImage: UIImage?
    
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
        
        premiumActionButton.addTarget(self, action: #selector(premiumButtonClicked), for: .touchUpInside)
    }
    
    private func setupUI() {
        imageView.layer.cornerRadius = 20
        imageView.layer.masksToBounds = false
        imageView.layer.cornerRadius = 20
        imageView.layer.masksToBounds = true
        
        // BlurImageView Setup
        blurImageView.layer.cornerRadius = 20
        blurImageView.layer.masksToBounds = true
        
        adContainerView.layer.cornerRadius = 20
        adContainerView.layer.masksToBounds = true
        adContainerView.isHidden = true
        
        DoneButton.layer.shadowColor = UIColor.black.cgColor
        DoneButton.layer.shadowOffset = CGSize(width: 0, height: 3)
        DoneButton.layer.shadowRadius = 3.24
        DoneButton.layer.shadowOpacity = 0.3
        DoneButton.layer.masksToBounds = false
        
        DoneButton.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageViewTapped))
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(tapGesture)
        
        // Adding blur effect to imageName label background
        let blurEffect = UIBlurEffect(style: .light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.clipsToBounds = true
        blurEffectView.translatesAutoresizingMaskIntoConstraints = false
        contentView.insertSubview(blurEffectView, belowSubview: audioLabel)
        
        NSLayoutConstraint.activate([
            blurEffectView.leadingAnchor.constraint(equalTo: audioLabel.leadingAnchor, constant: -8),
            blurEffectView.trailingAnchor.constraint(equalTo: audioLabel.trailingAnchor, constant: 8),
            blurEffectView.topAnchor.constraint(equalTo: audioLabel.topAnchor, constant: -4),
            blurEffectView.bottomAnchor.constraint(equalTo: audioLabel.bottomAnchor, constant: 4)
        ])
        
        // Update corner radius after layout
        DispatchQueue.main.async {
            blurEffectView.layer.cornerRadius = blurEffectView.frame.height / 2
        }
    }
    
    func configure(with categoryAllData: CategoryAllData?, customAudio: (url: URL, imageURL: String)?, at indexPath: IndexPath) {
            self.currentIndexPath = indexPath
            
            if let customAudio = customAudio {
                // Configure for custom audio
                self.audioLabel.text = "  Custom audio  "
                if let url = URL(string: customAudio.imageURL) {
                    imageView.sd_setImage(with: url, placeholderImage: UIImage(named: "audioplacholder")) { [weak self] image, _, _, _ in
                        self?.originalImage = image
                        self?.applyBackgroundBlurEffect()
                    }
                }
                setupCustomAudioPlayback(with: customAudio.url)
                self.adContainerView.isHidden = true
                self.premiumButton.isHidden = true
                self.premiumActionButton.isHidden = true
                self.DoneButton.isHidden = false
                
            } else if let categoryAllData = categoryAllData {
                // Existing API data configuration
                configure(with: categoryAllData, at: indexPath)
            }
        }
    
    func configure(with categoryAllData: CategoryAllData, at indexPath: IndexPath) {
        self.categoryAllData = categoryAllData
        self.currentIndexPath = indexPath
        
        if categoryAllData.name.lowercased() == "ads" {
            self.adContainerView.isHidden = false
            self.premiumButton.isHidden = true
            self.premiumActionButton.isHidden = true
            self.DoneButton.isHidden = true
            
            if let parentVC = self.parentViewController as? AudioPrankVC,
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
            
            let displayName = categoryAllData.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "---" : categoryAllData.name
            self.audioLabel.text = "  \(displayName)  "
            self.audioLabel.sizeToFit()
            
            if let imageURL = URL(string: categoryAllData.image) {
                imageView.sd_setImage(with: imageURL, placeholderImage: UIImage(named: "audioplacholder")) { [weak self] image, _, _, _ in
                    self?.originalImage = image
                    self?.applyBackgroundBlurEffect()
                    
                    if categoryAllData.premium {
                        self?.premiumButton.isHidden = false
                    } else {
                        self?.premiumButton.isHidden = true
                    }
                    
                    let isPremium = categoryAllData.premium && !PremiumManager.shared.isContentUnlocked(itemID: categoryAllData.itemID)
                    
                    if isPremium {
                        self?.premiumActionButton.isHidden = false
                        self?.DoneButton.isHidden = true
                        self?.applyBlurEffect()
                    } else {
                        self?.premiumActionButton.isHidden = true
                        self?.removeBlurEffect()
                        self?.DoneButton.isHidden = false
                        self?.DoneButton.setImage(UIImage(named: "selectYesButton"), for: .normal)
                    }
                }
            }
            
            // Only setup audio playback for non-premium content
            if !categoryAllData.premium || PremiumManager.shared.isContentUnlocked(itemID: categoryAllData.itemID) {
                setupAudioPlayback(with: categoryAllData.file)
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
    
    // MARK: - Action Methods
    @objc private func premiumButtonClicked() {
        guard let categoryAllData = categoryAllData else { return }
        delegate?.didTapPremiumIcon(for: categoryAllData)
    }
    
    private func setupAudioPlayback(with audioURLString: String?) {
        stopAudio()
        isAudioLoaded = false
        
        guard let audioURLString = audioURLString,
              let audioURL = URL(string: audioURLString) else { return }
        
        audioDownloadTask?.cancel()
        
        audioDownloadTask = URLSession.shared.dataTask(with: audioURL) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  error == nil else {
                print("Error downloading audio: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            DispatchQueue.main.async {
                do {
                    self.audioPlayer = try AVAudioPlayer(data: data)
                    self.audioPlayer?.delegate = self
                    self.audioPlayer?.prepareToPlay()
                    self.isAudioLoaded = true
                } catch {
                    print("Error setting up audio player: \(error)")
                }
            }
        }
        
        audioDownloadTask?.resume()
    }
    
    func setupCustomAudioPlayback(with audioURL: URL) {
            stopAudio()
            isAudioLoaded = false
            
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
                audioPlayer?.delegate = self
                audioPlayer?.prepareToPlay()
                isAudioLoaded = true
            } catch {
                print("Error setting up custom audio player: \(error)")
            }
        }
    
    func playAudio() {
        
        guard isAudioLoaded, let audioPlayer = audioPlayer else {
            return
        }
        
        AudioPlaybackManager.shared.stopCurrentPlayback()
        audioPlayer.play()
        self.playPauseImageView.isHidden = true
        isAudioPlaying = true
        AudioPlaybackManager.shared.currentlyPlayingCell = self
        AudioPlaybackManager.shared.currentlyPlayingIndexPath = currentIndexPath
    }
    
    func stopAudio() {
        audioPlayer?.stop()
        showPauseImage()
        isAudioPlaying = false
        imageViewTimer?.invalidate()
    }
    
    private func toggleAudioPlayback() {
        if !isAudioLoaded {
            return
        }
        
        guard let audioPlayer = audioPlayer,
              let indexPath = currentIndexPath else { return }
        
        delegate?.didTapAudioPlayback(at: indexPath)
    }
    
    private func showPauseImage() {
        playPauseImageView.image = UIImage(named: "PlayButton")
        playPauseImageView.isHidden = false
    }
    
    @objc private func doneButtonTapped() {
        stopAudio()
        if let categoryAllData = categoryAllData {
            delegate?.didTapDoneButton(for: categoryAllData)
        }
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    @objc private func imageViewTapped() {
        guard let categoryAllData = categoryAllData else { return }
        
        // Check if content is premium and locked
        if categoryAllData.premium && !PremiumManager.shared.isContentUnlocked(itemID: categoryAllData.itemID) {
            delegate?.didTapPremiumIcon(for: categoryAllData)
        } else {
            toggleAudioPlayback()
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        stopAudio()
        audioDownloadTask?.cancel()
        audioDownloadTask = nil
        audioPlayer = nil
        isAudioLoaded = false
    }
}

@available(iOS 15.0, *)
extension AudioCharacterAllCollectionViewCell: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.stopAudio()
            player.currentTime = 0
        }
    }
}


class AudioCharacterSliderCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    private var categoryAllData: CategoryAllData?
    var premiumIconImageView: UIImageView!
    
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
    
    func configure(with categoryAllData: CategoryAllData) {
        self.categoryAllData = categoryAllData
        if let imageURL = URL(string: categoryAllData.image) {
            imageView.sd_setImage(with: imageURL, placeholderImage: UIImage(named: "audioplacholder")) { image, _, _, _ in
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
