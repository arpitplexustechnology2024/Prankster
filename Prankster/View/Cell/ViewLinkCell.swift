//
//  ViewLinkCollectionViewCell.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 01/12/24.
//

import UIKit

class ViewLinkCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var prankNameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        layoutIfNeeded()
        
        self.layer.cornerRadius = 12
        self.clipsToBounds = true
        
        self.contentView.layer.borderWidth = 1
        self.contentView.layer.borderColor = UIColor.moreApp.cgColor
        
        self.imageView.layer.cornerRadius = 12
        self.imageView.clipsToBounds = true
        
    }
}
