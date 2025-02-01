//
//  ImageCharacterAllCollectionViewCell.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 19/10/24.
//

import UIKit
import SDWebImage
import Alamofire

protocol ImageCharacterAllCollectionViewCellDelegate: AnyObject {
    func didTapPremiumIcon(for categoryAllData: CategoryAllData)
    func didTapDoneButton(for categoryAllData: CategoryAllData)
}

@available(iOS 15.0, *)
class ImageCharacterAllCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var DoneButton: UIButton!
    @IBOutlet weak var imageName: UILabel!
    @IBOutlet weak var premiumButton: UIButton!
    @IBOutlet weak var blurImageView: UIImageView!
    
    weak var delegate: ImageCharacterAllCollectionViewCellDelegate?
    private var coverPageData: CategoryAllData?
    var originalImage: UIImage?
    var premiumActionButton: UIButton!
    
    @IBOutlet weak var adContainerView: UIView!
    
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
        
        premiumActionButton.addTarget(self, action: #selector(premiumButtonClicked), for: .touchUpInside)
    }
    
    private func setupUI() {
        imageView.layer.cornerRadius = 20
        imageView.layer.masksToBounds = false
        imageView.layer.cornerRadius = 20
        imageView.layer.masksToBounds = true
        
        adContainerView.layer.cornerRadius = 20
        adContainerView.layer.masksToBounds = true
        adContainerView.isHidden = true
        
        // BlurImageView Setup
        blurImageView.layer.cornerRadius = 20
        blurImageView.layer.masksToBounds = true
        
        DoneButton.layer.shadowColor = UIColor.black.cgColor
        DoneButton.layer.shadowOffset = CGSize(width: 0, height: 3)
        DoneButton.layer.shadowRadius = 3.24
        DoneButton.layer.shadowOpacity = 0.3
        DoneButton.layer.masksToBounds = false
        
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
    
    // MARK: - Configuration
    func configure(with coverPageData: CategoryAllData) {
        self.coverPageData = coverPageData
        
        if coverPageData.name.lowercased() == "ads" {
            self.adContainerView.isHidden = false
            self.premiumButton.isHidden = true
            self.premiumActionButton.isHidden = true
            self.DoneButton.isHidden = true
            
            if let parentVC = self.parentViewController as? ImagePrankVC,
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
            
            let displayName = coverPageData.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "---" : coverPageData.name
            self.imageName.text = "  \(displayName)  "
            self.imageName.sizeToFit()
            
            if let imageURL = URL(string: coverPageData.file ?? "") {
                imageView.sd_setImage(with: imageURL, placeholderImage: UIImage(named: "imageplacholder")) { [weak self] image, _, _, _ in
                    self?.originalImage = image
                    
                    self?.applyBackgroundBlurEffect()
                    
                    if coverPageData.premium {
                        self?.premiumButton.isHidden = false
                    } else {
                        self?.premiumButton.isHidden = true
                    }
                    
                    if coverPageData.premium && !PremiumManager.shared.isContentUnlocked(itemID: coverPageData.itemID) {
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
    
    // MARK: - Action Methods
    @objc private func premiumButtonClicked() {
        guard let coverPageData = coverPageData else { return }
        delegate?.didTapPremiumIcon(for: coverPageData)
    }
    
    @IBAction func doneButtonClicked(_ sender: UIButton) {
        guard let coverPageData = coverPageData else { return }
        delegate?.didTapDoneButton(for: coverPageData)
    }
}

class ImageCharacterSliderCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    private var coverPageData: CategoryAllData?
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
    
    func configure(with coverPageData: CategoryAllData) {
        self.coverPageData = coverPageData
        if let imageURL = URL(string: coverPageData.file ?? "") {
            imageView.sd_setImage(with: imageURL, placeholderImage: UIImage(named: "imageplacholder")) { image, _, _, _ in
                self.originalImage = image
                
                if coverPageData.premium && !PremiumManager.shared.isContentUnlocked(itemID: coverPageData.itemID) {
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
