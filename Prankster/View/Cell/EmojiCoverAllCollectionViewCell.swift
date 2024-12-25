//
//  EmojiCoverAllCollectionViewCell.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 10/10/24.
//

import UIKit
import SDWebImage

protocol EmojiCoverAllCollectionViewCellDelegate: AnyObject {
    func didTapDoneButton(for coverPageData: CoverPageData)
}

class EmojiCoverAllCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var DoneButton: UIButton!
    @IBOutlet weak var imageName: UILabel!
    @IBOutlet weak var premiumButton: UIButton!
    weak var delegate: EmojiCoverAllCollectionViewCellDelegate?
    private var coverPageData: CoverPageData?
    private var nameBlurView: UIVisualEffectView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
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
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let padding: CGFloat = 4
        nameBlurView.frame = imageName.frame.insetBy(dx: -padding, dy: -padding)
        nameBlurView.layer.cornerRadius = nameBlurView.frame.height / 2
        nameBlurView.layer.masksToBounds = true
    }
    
    func configure(with coverPageData: CoverPageData) {
        self.coverPageData = coverPageData
        let displayName = coverPageData.coverName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "---" : coverPageData.coverName
        self.imageName.text = "  \(displayName)  "
        
        if let imageURL = URL(string: coverPageData.coverURL) {
            imageView.sd_setImage(with: imageURL, placeholderImage: UIImage(named: "PlaceholderImage")) { [weak self] image, _, _, _ in
                if coverPageData.coverPremium && !PremiumManager.shared.isContentUnlocked(itemID: coverPageData.itemID) {
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
}

class EmojiCoverSliderCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    private var coverPageData: CoverPageData?
    
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
    
    func configure(with coverPageData: CoverPageData) {
        self.coverPageData = coverPageData
        if let imageURL = URL(string: coverPageData.coverURL) {
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
