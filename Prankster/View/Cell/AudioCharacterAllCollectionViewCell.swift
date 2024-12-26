//
//  AudioCharacterAllCollectionViewCell.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 17/10/24.
//

import AVFoundation
import CoreImage
import SDWebImage
import UIKit

// MARK: - Video Playback Manager
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
    func didTapDoneButton(for categoryAllData: CategoryAllData)
    func didTapAudioPlayback(at indexPath: IndexPath)
}

// MARK: - Collection View Cell
class AudioCharacterAllCollectionViewCell: UICollectionViewCell {
    
    // MARK: - IBOutlets
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var playPauseImageView: UIImageView!
    @IBOutlet weak var DoneButton: UIButton!
    @IBOutlet weak var audioLabel: UILabel!
    @IBOutlet weak var premiumButton: UIButton!
    
    // MARK: - Properties
    weak var delegate: AudioAllCollectionViewCellDelegate?
    private var categoryAllData: CategoryAllData?
    private var audioPlayer: AVAudioPlayer?
    private var imageViewTimer: Timer?
    private var isAudioPlaying = false
    private var currentIndexPath: IndexPath?
    private var audioDownloadTask: URLSessionDataTask?
    private var isAudioLoaded = false
    
    // MARK: - Lifecycle Methods
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func configure(with categoryAllData: CategoryAllData, at indexPath: IndexPath) {
        self.categoryAllData = categoryAllData
        self.currentIndexPath = indexPath
        
        let displayName = categoryAllData.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "---" : categoryAllData.name
        self.audioLabel.text = "  \(displayName)  "
        self.audioLabel.sizeToFit()
        
        if let imageURL = URL(string: categoryAllData.image) {
            imageView.sd_setImage(with: imageURL, placeholderImage: UIImage(named: "PlaceholderAudio")) { [weak self] image, _, _, _ in
                if categoryAllData.premium && !PremiumManager.shared.isContentUnlocked(itemID: categoryAllData.itemID) {
                    self?.premiumButton.isHidden = false
                    self?.DoneButton.setImage(UIImage(named: "selectYesButton"), for: .normal)
                } else {
                    self?.premiumButton.isHidden = true
                    self?.DoneButton.setImage(UIImage(named: "selectYesButton"), for: .normal)
                }
            }
        }
        setupAudioPlayback(with: categoryAllData.file)
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
        toggleAudioPlayback()
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
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func configure(with categoryAllData: CategoryAllData) {
        self.categoryAllData = categoryAllData
        if let imageURL = URL(string: categoryAllData.image) {
            imageView.sd_setImage(with: imageURL, placeholderImage: UIImage(named: "PlaceholderAudio")) { image, _, _, _ in
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
