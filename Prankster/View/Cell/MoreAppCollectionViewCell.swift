//
//  MoreAppCollectionViewCell.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 08/10/24.
//

import UIKit
import SDWebImage

class MoreAppCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var More_App_LogoImage: UIImageView!
    @IBOutlet weak var More_App_Label: UILabel!
    @IBOutlet weak var More_App_DownloadButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        layoutIfNeeded()
        
        self.contentView.layer.borderWidth = 1
        self.contentView.layer.borderColor = UIColor.moreApp.cgColor
        
        self.contentView.layer.cornerRadius = 12
        self.contentView.layer.masksToBounds = true
        
        self.More_App_LogoImage.layer.cornerRadius = 12
        self.More_App_LogoImage.clipsToBounds = true
    }
    
    func configure(with moreData: MoreData) {
        More_App_Label.text = moreData.appName
        
        if let logoURL = URL(string: moreData.logo) {
            More_App_LogoImage.sd_setImage(with: logoURL, placeholderImage: UIImage(named: "imageplacholder"))
        } else {
            More_App_LogoImage.image = UIImage(named: "imageplacholder")
        }
    }
}
