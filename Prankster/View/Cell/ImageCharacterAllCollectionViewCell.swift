//
//  ImageCharacterAllCollectionViewCell.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 19/10/24.
//

import UIKit
import SDWebImage

protocol ImageCharacterAllCollectionViewCellDelegate: AnyObject {
    func didTapDoneButton(for categoryAllData: CategoryAllData)
}

class ImageCharacterAllCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var DoneButton: UIButton!
    @IBOutlet weak var imageName: UILabel!
    @IBOutlet weak var premiumButton: UIButton!
    weak var delegate: ImageCharacterAllCollectionViewCellDelegate?
    private var coverPageData: CategoryAllData?
    
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
    
    func configure(with coverPageData: CategoryAllData) {
        self.coverPageData = coverPageData
        let displayName = coverPageData.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "---" : coverPageData.name
        self.imageName.text = "  \(displayName)  "
        self.imageName.sizeToFit()
        
        if let imageURL = URL(string: coverPageData.image) {
            imageView.sd_setImage(with: imageURL, placeholderImage: UIImage(named: "PlaceholderImage")) { [weak self] image, _, _, _ in
                if coverPageData.premium && !PremiumManager.shared.isContentUnlocked(itemID: coverPageData.itemID) {
                    self?.premiumButton.isHidden = false
                    self?.DoneButton.setImage(UIImage(named: "selectYesButton"), for: .normal)
                } else {
                    self?.premiumButton.isHidden = true
                    self?.DoneButton.setImage(UIImage(named: "selectYesButton"), for: .normal)
                }
            }
        }
    }
    
    @objc private func doneButtonTapped() {
        if let coverPageData = coverPageData {
            delegate?.didTapDoneButton(for: coverPageData)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
    }
}

class ImageCharacterSliderCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    private var coverPageData: CategoryAllData?
    
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
    
    func configure(with coverPageData: CategoryAllData) {
        self.coverPageData = coverPageData
        if let imageURL = URL(string: coverPageData.image) {
            imageView.sd_setImage(with: imageURL, placeholderImage: UIImage(named: "PlaceholderImage")) { image, _, _, _ in
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
