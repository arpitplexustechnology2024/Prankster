//
//  AudioCharacterAllCollectionViewCell.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 17/10/24.
//
//
//import AVFoundation
//import CoreImage
//import SDWebImage
//import UIKit
//
//// MARK: - Video Playback Manager
//@available(iOS 15.0, *)
//class AudioPlaybackManager {
//    static let shared = AudioPlaybackManager()
//    private init() {}
//    
//    var currentlyPlayingCell: AudioCharacterAllCollectionViewCell?
//    var currentlyPlayingIndexPath: IndexPath?
//    
//    func stopCurrentPlayback() {
//        currentlyPlayingCell?.stopAudio()
//        currentlyPlayingCell = nil
//        currentlyPlayingIndexPath = nil
//    }
//}
//
//// MARK: - Protocols
//protocol AudioAllCollectionViewCellDelegate: AnyObject {
//    func didTapAudioPlayback(at indexPath: IndexPath)
//    func didTapPremiumIcon(for categoryAllData: CategoryAllData)
//    func didTapDoneButton(for categoryAllData: CategoryAllData)
//}
//
//// MARK: - Collection View Cell
//@available(iOS 15.0, *)
//class AudioCharacterAllCollectionViewCell: UICollectionViewCell {
//    
//    // MARK: - IBOutlets
//    @IBOutlet weak var imageView: UIImageView!
//    @IBOutlet weak var playPauseImageView: UIImageView!
//    @IBOutlet weak var DoneButton: UIButton!
//    @IBOutlet weak var audioLabel: UILabel!
//    @IBOutlet weak var premiumButton: UIButton!
//    @IBOutlet weak var blurImageView: UIImageView!

//    @IBOutlet weak var adContainerView: UIView!
//    var originalImage: UIImage?
//    var premiumActionButton: UIButton!
//    
//    // MARK: - Properties
//    weak var delegate: AudioAllCollectionViewCellDelegate?
//    private var categoryAllData: CategoryAllData?
//    private var audioPlayer: AVAudioPlayer?
//    private var imageViewTimer: Timer?
//    private var isAudioPlaying = false
//    private var currentIndexPath: IndexPath?
//    private var audioDownloadTask: URLSessionDataTask?
//    private var isAudioLoaded = false
//    
//    // MARK: - Lifecycle Methods
//    override func awakeFromNib() {
//        super.awakeFromNib()
//        setupUI()
//    }
//    
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        setupUI()
//        setupPremiumActionButton()
//    }
//    
//    required init?(coder: NSCoder) {
//        super.init(coder: coder)
//        setupPremiumActionButton()
//    }
//    
//    // MARK: - Setup Methods
//    private func setupPremiumActionButton() {
//        premiumActionButton = UIButton(type: .custom)
//        premiumActionButton.setImage(UIImage(named: "HideEye"), for: .normal)
//        premiumActionButton.translatesAutoresizingMaskIntoConstraints = false
//        premiumActionButton.isHidden = true
//        contentView.addSubview(premiumActionButton)
//        
//        NSLayoutConstraint.activate([
//            premiumActionButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
//            premiumActionButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
//            premiumActionButton.widthAnchor.constraint(equalToConstant: 80),
//            premiumActionButton.heightAnchor.constraint(equalToConstant: 80)
//        ])
//        
//        premiumActionButton.addTarget(self, action: #selector(premiumButtonClicked), for: .touchUpInside)
//    }
//    
//    @IBAction func doneButtonClicked(_ sender: UIButton) {
//        stopAudio()
//        if let categoryAllData = categoryAllData {
//            delegate?.didTapDoneButton(for: categoryAllData)
//        }
//    }
//    
//    // MARK: - Action Methods
//    @objc private func premiumButtonClicked() {
//        guard let categoryAllData = categoryAllData else { return }
//        delegate?.didTapPremiumIcon(for: categoryAllData
//        )
//    }
//    
//    private func setupUI() {
//        imageView.layer.cornerRadius = 20
//        imageView.layer.masksToBounds = false
//        imageView.layer.cornerRadius = 20
//        imageView.layer.masksToBounds = true
//        
//        // BlurImageView Setup
//        blurImageView.layer.cornerRadius = 20
//        blurImageView.layer.masksToBounds = true
//        
//        DoneButton.layer.shadowColor = UIColor.black.cgColor
//        DoneButton.layer.shadowOffset = CGSize(width: 0, height: 3)
//        DoneButton.layer.shadowRadius = 3.24
//        DoneButton.layer.shadowOpacity = 0.3
//        DoneButton.layer.masksToBounds = false
//        
//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageViewTapped))
//        imageView.isUserInteractionEnabled = true
//        imageView.addGestureRecognizer(tapGesture)
//        
//        // Adding blur effect to imageName label background
//           let blurEffect = UIBlurEffect(style: .light)
//           let blurEffectView = UIVisualEffectView(effect: blurEffect)
//           blurEffectView.clipsToBounds = true
//           blurEffectView.translatesAutoresizingMaskIntoConstraints = false
//           contentView.insertSubview(blurEffectView, belowSubview: audioLabel)
//           
//           NSLayoutConstraint.activate([
//               blurEffectView.leadingAnchor.constraint(equalTo: audioLabel.leadingAnchor, constant: -8),
//               blurEffectView.trailingAnchor.constraint(equalTo: audioLabel.trailingAnchor, constant: 8),
//               blurEffectView.topAnchor.constraint(equalTo: audioLabel.topAnchor, constant: -4),
//               blurEffectView.bottomAnchor.constraint(equalTo: audioLabel.bottomAnchor, constant: 4)
//           ])
//        
//        // Update corner radius after layout
//        DispatchQueue.main.async {
//            blurEffectView.layer.cornerRadius = blurEffectView.frame.height / 2
//        }
//    }
//    
//    func configure(with categoryAllData: CategoryAllData, at indexPath: IndexPath) {
//        self.categoryAllData = categoryAllData
//        self.currentIndexPath = indexPath
//        
//        if categoryAllData.name.lowercased() == "ads" {
//            self.adContainerView.isHidden = false
//            self.premiumButton.isHidden = true
//            self.premiumActionButton.isHidden = true
//            self.DoneButton.isHidden = true
//            
//        } else {
//            self.adContainerView.isHidden = true
//            
//            let displayName = categoryAllData.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "---" : categoryAllData.name
//            self.audioLabel.text = "  \(displayName)  "
//            self.audioLabel.sizeToFit()
//            
//            if let imageURL = URL(string: categoryAllData.image) {
//                imageView.sd_setImage(with: imageURL, placeholderImage: UIImage(named: "PlaceholderAudio")) { [weak self] image, _, _, _ in
//                    self?.originalImage = image
//                    
//                    self?.applyBackgroundBlurEffect()
//                    
//                    if categoryAllData.premium && !PremiumManager.shared.isContentUnlocked(itemID: categoryAllData.itemID) {
//                        self?.premiumButton.isHidden = false
//                        self?.playPauseImageView.isHidden = true
//                        self?.premiumActionButton.isHidden = false
//                        self?.DoneButton.isHidden = true
//                        self?.applyBlurEffect()
//                    } else {
//                        self?.playPauseImageView.isHidden = false
//                        self?.premiumButton.isHidden = true
//                        self?.premiumActionButton.isHidden = true
//                        self?.removeBlurEffect()
//                        self?.DoneButton.isHidden = false
//                        self?.DoneButton.setImage(UIImage(named: "selectYesButton"), for: .normal)
//                    }
//                }
//            }
//            setupAudioPlayback(with: categoryAllData.file)
//        }
//    } 
//    
//    private func setupAudioPlayback(with audioURLString: String?) {
//        stopAudio()
//        isAudioLoaded = false
//        
//        guard let audioURLString = audioURLString,
//              let audioURL = URL(string: audioURLString) else { return }
//        
//        audioDownloadTask?.cancel()
//        
//        audioDownloadTask = URLSession.shared.dataTask(with: audioURL) { [weak self] data, response, error in
//            guard let self = self,
//                  let data = data,
//                  error == nil else {
//                print("Error downloading audio: \(error?.localizedDescription ?? "Unknown error")")
//                return
//            }
//            
//            DispatchQueue.main.async {
//                do {
//                    self.audioPlayer = try AVAudioPlayer(data: data)
//                    self.audioPlayer?.delegate = self
//                    self.audioPlayer?.prepareToPlay()
//                    self.isAudioLoaded = true
//                } catch {
//                    print("Error setting up audio player: \(error)")
//                }
//            }
//        }
//        
//        audioDownloadTask?.resume()
//    }
//    
//    // MARK: - Blur Effect Methods
//    func applyBlurEffect() {
//        guard let image = originalImage else { return }
//        
//        let context = CIContext()
//        guard let ciImage = CIImage(image: image) else { return }
//        
//        let filter = CIFilter(name: "CIGaussianBlur")!
//        filter.setValue(ciImage, forKey: kCIInputImageKey)
//        filter.setValue(20.0, forKey: kCIInputRadiusKey)
//        
//        guard let outputImage = filter.outputImage,
//              let cgImage = context.createCGImage(outputImage, from: ciImage.extent) else { return }
//        
//        imageView.image = UIImage(cgImage: cgImage)
//    }
//    
//    func applyBackgroundBlurEffect() {
//        guard let image = originalImage else { return }
//        
//        let context = CIContext()
//        guard let ciImage = CIImage(image: image) else { return }
//        
//        let filter = CIFilter(name: "CIGaussianBlur")!
//        filter.setValue(ciImage, forKey: kCIInputImageKey)
//        filter.setValue(30.0, forKey: kCIInputRadiusKey)
//        
//        guard let outputImage = filter.outputImage,
//              let cgImage = context.createCGImage(outputImage, from: ciImage.extent) else { return }
//        
//        blurImageView.image = UIImage(cgImage: cgImage)
//    }
//    
//    func removeBlurEffect() {
//        imageView.image = originalImage
//    }
//    
//    func playAudio() {
//        guard isAudioLoaded, let audioPlayer = audioPlayer else {
//            return
//        }
//        
//        AudioPlaybackManager.shared.stopCurrentPlayback()
//        audioPlayer.play()
//        self.playPauseImageView.isHidden = true  // Hide play button when playing
//        isAudioPlaying = true
//        AudioPlaybackManager.shared.currentlyPlayingCell = self
//        AudioPlaybackManager.shared.currentlyPlayingIndexPath = currentIndexPath
//    }
//
//    func stopAudio() {
//        audioPlayer?.stop()
//        showPauseImage()
//        isAudioPlaying = false
//        imageViewTimer?.invalidate()
//    }
//
//    private func toggleAudioPlayback() {
//        if !isAudioLoaded {
//            return
//        }
//        
//        if isAudioPlaying {
//            stopAudio()
//        } else {
//            playAudio()
//        }
//    }
//    
//    private func showPauseImage() {
//        playPauseImageView.image = UIImage(named: "PlayButton")
//        playPauseImageView.isHidden = false
//    }
//    
//    override func layoutSubviews() {
//        super.layoutSubviews()
//    }
//    
//    @objc private func imageViewTapped() {
//        toggleAudioPlayback()
//    }
//    
//    override func prepareForReuse() {
//        super.prepareForReuse()
//        stopAudio()
//        audioDownloadTask?.cancel()
//        audioDownloadTask = nil
//        audioPlayer = nil
//        isAudioLoaded = false
//    }
//}
//
//@available(iOS 15.0, *)
//extension AudioCharacterAllCollectionViewCell: AVAudioPlayerDelegate {
//    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
//        DispatchQueue.main.async { [weak self] in
//            self?.stopAudio()
//            player.currentTime = 0
//        }
//    }
//}
//
//class AudioSliderCollectionViewCell: UICollectionViewCell {
//    
//    @IBOutlet weak var imageView: UIImageView!
//    private var categoryAllData: CategoryAllData?
//    var premiumIconImageView: UIImageView!
//    
//    private var originalImage: UIImage?
//    
//    override func awakeFromNib() {
//        super.awakeFromNib()
//        setupUI()
//    }
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        setupPremiumIconImageView()
//    }
//    
//    required init?(coder: NSCoder) {
//        super.init(coder: coder)
//        setupPremiumIconImageView()
//    }
//    
//    private func setupPremiumIconImageView() {
//        premiumIconImageView = UIImageView(image: UIImage(named: "PremiumIcon"))
//        premiumIconImageView.translatesAutoresizingMaskIntoConstraints = false
//        premiumIconImageView.isHidden = true
//        contentView.addSubview(premiumIconImageView)
//        
//        NSLayoutConstraint.activate([
//            premiumIconImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
//            premiumIconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
//            premiumIconImageView.widthAnchor.constraint(equalToConstant: 40),
//            premiumIconImageView.heightAnchor.constraint(equalToConstant: 40)
//        ])
//    }
//    
//    private func setupUI() {
//        layer.cornerRadius = 10
//        layer.masksToBounds = false
//        contentView.layer.cornerRadius = 10
//        contentView.layer.masksToBounds = true
//    }
//    
//    func configure(with categoryAllData: CategoryAllData) {
//        self.categoryAllData = categoryAllData
//        if let imageURL = URL(string: categoryAllData.image) {
//            imageView.sd_setImage(with: imageURL, placeholderImage: UIImage(named: "imageplacholder")) { image, _, _, _ in
//                self.originalImage = image
//                
//                if categoryAllData.premium && !PremiumManager.shared.isContentUnlocked(itemID: categoryAllData.itemID) {
//                    self.premiumIconImageView.isHidden = false
//                    self.applyBlurEffect()
//                } else {
//                    self.premiumIconImageView.isHidden = true
//                    self.removeBlurEffect()
//                }
//            }
//        }
//    }
//    
//    func applyBlurEffect() {
//        guard let image = originalImage else { return }
//        
//        let context = CIContext()
//        guard let ciImage = CIImage(image: image) else { return }
//        
//        let filter = CIFilter(name: "CIGaussianBlur")!
//        filter.setValue(ciImage, forKey: kCIInputImageKey)
//        filter.setValue(50.0, forKey: kCIInputRadiusKey)
//        
//        guard let outputImage = filter.outputImage,
//              let cgImage = context.createCGImage(outputImage, from: ciImage.extent) else { return }
//        
//        imageView.image = UIImage(cgImage: cgImage)
//    }
//    
//    func removeBlurEffect() {
//        imageView.image = originalImage
//    }
//    
//    override var isSelected: Bool {
//        didSet {
//            layer.borderWidth = isSelected ? 3 : 0
//            layer.borderColor = isSelected ? #colorLiteral(red: 1, green: 0.8470588235, blue: 0, alpha: 1) : nil
//        }
//    }
//}
