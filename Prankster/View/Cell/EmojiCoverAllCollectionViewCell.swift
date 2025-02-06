//
//  EmojiCoverAllCollectionViewCell.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 10/10/24.
//

// MARK: - EmojiCoverAllCollectionViewCell.swift
import UIKit
import SDWebImage
import GoogleMobileAds
import Alamofire

@available(iOS 15.0, *)
class EmojiCoverAllCollectionViewCell: UICollectionViewCell {
    
    // MARK: - IBOutlets
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var DoneButton: UIButton!
    @IBOutlet weak var imageName: UILabel!
    @IBOutlet weak var premiumButton: UIButton!
    @IBOutlet weak var blurImageView: UIImageView!
    
    // MARK: - Properties
    private var coverPageData: CoverPageData?
    var premiumActionButton: UIButton!
    var originalImage: UIImage?
    
    @IBOutlet weak var adContainerView: UIView!
    
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
        premiumActionButton.setImage(UIImage(named: "HideEye"), for: .normal)
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

    
    private func setupUI() {
        // ImageView Setup
        imageView.layer.cornerRadius = 20
        imageView.layer.masksToBounds = true
        
        adContainerView.layer.cornerRadius = 20
        adContainerView.layer.masksToBounds = true
        adContainerView.isHidden = true
        
        // BlurImageView Setup
        blurImageView.layer.cornerRadius = 20
        blurImageView.layer.masksToBounds = true
        
        // DoneButton Setup
        DoneButton.layer.shadowColor = UIColor.black.cgColor
        DoneButton.layer.shadowOffset = CGSize(width: 0, height: 3)
        DoneButton.layer.shadowRadius = 3.24
        DoneButton.layer.shadowOpacity = 0.3
        DoneButton.layer.masksToBounds = false
        
        // ImageName Label Blur Effect
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
        
        DispatchQueue.main.async {
            blurEffectView.layer.cornerRadius = blurEffectView.frame.height / 2
        }
    }
    
    // MARK: - Configuration
    func configure(with coverPageData: CoverPageData) {
        self.coverPageData = coverPageData
        
        if coverPageData.coverName.lowercased() == "ads" {
            self.adContainerView.isHidden = false
            self.premiumButton.isHidden = true
            self.premiumActionButton.isHidden = true
            self.DoneButton.isHidden = true
            
            
            if let parentVC = self.parentViewController as? CoverPrankVC,
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
            
            let displayName = coverPageData.coverName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "---" : coverPageData.coverName
            self.imageName.text = " \(displayName) "
            self.imageName.sizeToFit()
            
            if let imageURL = URL(string: coverPageData.coverURL) {
                imageView.sd_setImage(with: imageURL, placeholderImage: UIImage(named: "imageplacholder")) { [weak self] image, _, _, _ in
                    self?.originalImage = image
                    
                    self?.applyBackgroundBlurEffect()
                    
                    if coverPageData.coverPremium {
                        self?.premiumButton.isHidden = false
                    } else {
                        self?.premiumButton.isHidden = true
                    }
                    
                    if coverPageData.coverPremium && !PremiumManager.shared.isContentUnlocked(itemID: coverPageData.itemID) {
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
        }
    }
    
    private func isConnectedToInternet() -> Bool {
        let networkManager = NetworkReachabilityManager()
        return networkManager?.isReachable ?? false
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
}

class EmojiCoverSliderCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    private var coverPageData: CoverPageData?
    var premiumIconImageView: UIImageView!
    
    private var originalImage: UIImage?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
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
    
    private func setupUI() {
        layer.cornerRadius = 10
        layer.masksToBounds = false
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true
    }
    
    func configure(with coverPageData: CoverPageData) {
        self.coverPageData = coverPageData
        if let imageURL = URL(string: coverPageData.coverURL) {
            imageView.sd_setImage(with: imageURL, placeholderImage: UIImage(named: "imageplacholder")) { image, _, _, _ in
                self.originalImage = image
                
                if coverPageData.coverPremium && !PremiumManager.shared.isContentUnlocked(itemID: coverPageData.itemID) {
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


// MARK: - LoadingView.swift
class LoadingView: UIView {
    private let activityIndicator: UIActivityIndicatorView
    private let messageLabel: UILabel
    private let blurView: UIVisualEffectView
    
    override init(frame: CGRect) {
        let blurEffect = UIBlurEffect(style: .dark)
        self.blurView = UIVisualEffectView(effect: blurEffect)
        
        self.activityIndicator = UIActivityIndicatorView(style: .large)
        self.activityIndicator.color = .white
        
        self.messageLabel = UILabel()
        self.messageLabel.text = "Ad Loading..."
        self.messageLabel.textColor = .white
        self.messageLabel.textAlignment = .center
        self.messageLabel.font = .systemFont(ofSize: 16, weight: .medium)
        
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        addSubview(blurView)
        blurView.contentView.addSubview(activityIndicator)
        blurView.contentView.addSubview(messageLabel)
        
        blurView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -20),
            
            messageLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 8),
            messageLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])
        
        layer.cornerRadius = 10
        clipsToBounds = true
    }
    
    func startLoading() {
        activityIndicator.startAnimating()
        isHidden = false
    }
    
    func stopLoading() {
        activityIndicator.stopAnimating()
        isHidden = true
    }
}
