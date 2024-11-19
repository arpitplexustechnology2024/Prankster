//
//  EmojiCoverAllCollectionViewCell.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 10/10/24.
//

import UIKit
import SDWebImage
import CoreImage

class EmojiCoverAllCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var DoneButton: UIButton!
    var premiumIconImageView: UIImageView!
    private var originalImage: UIImage?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        layer.cornerRadius = 10
        layer.masksToBounds = false
        contentView.layer.cornerRadius = 20
        contentView.layer.masksToBounds = true
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
    }
    
    func configure(with coverPageData: CoverPageData) {
        if let imageURL = URL(string: coverPageData.coverURL) {
            imageView.sd_setImage(with: imageURL) { [weak self] image, _, _, _ in
                guard let self = self else { return }
                self.originalImage = image
                
                if coverPageData.coverPremium {
                    self.DoneButton.setImage(UIImage(named: "PremiumButton"), for: .normal)
                } else {
                    self.DoneButton.setImage(UIImage(named: "selectButton"), for: .normal)
                }
            }
        }
    }
}
