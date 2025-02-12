//
//  CoverBottomCell.swift
//  Prankster
//
//  Created by Arpit iOS Dev. on 11/02/25.
//

import UIKit
import SDWebImage

class CoverBottomCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var DoneButton: UIButton!
    private var coverPageData: CoverPageData?
    var premiumActionButton: UIButton!
    
    private var originalImage: UIImage?
    
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
        premiumActionButton.setImage(UIImage(named: "Premium 3"), for: .normal)
        premiumActionButton.translatesAutoresizingMaskIntoConstraints = false
        premiumActionButton.isHidden = true
        contentView.addSubview(premiumActionButton)
        
        NSLayoutConstraint.activate([
            premiumActionButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            premiumActionButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            premiumActionButton.widthAnchor.constraint(equalToConstant: 45),
            premiumActionButton.heightAnchor.constraint(equalToConstant: 45)
        ])
    }
    
    private func setupUI() {
        layer.cornerRadius = 10
        layer.masksToBounds = false
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true
        
        DoneButton.layer.shadowColor = UIColor.black.cgColor
        DoneButton.layer.shadowOffset = CGSize(width: 0, height: 3)
        DoneButton.layer.shadowRadius = 3.24
        DoneButton.layer.shadowOpacity = 0.3
        DoneButton.layer.masksToBounds = false
    }
    
    func configure(with coverPageData: CoverPageData) {
        self.coverPageData = coverPageData
        if let imageURL = URL(string: coverPageData.coverURL) {
            imageView.sd_setImage(with: imageURL, placeholderImage: UIImage(named: "imageplacholder")) { image, _, _, _ in
                self.originalImage = image
                
                if coverPageData.coverPremium && !PremiumManager.shared.isContentUnlocked(itemID: coverPageData.itemID) {
                    self.premiumActionButton.isHidden = false
                    self.DoneButton.isHidden = true
                    self.applyBlurEffect()
                } else {
                    self.premiumActionButton.isHidden = true
                    self.DoneButton.isHidden = false
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
}
