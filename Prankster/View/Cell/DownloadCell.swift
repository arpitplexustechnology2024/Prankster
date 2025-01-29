//
//  DownloadCell.swift
//  Prankster
//
//  Created by Arpit iOS Dev. on 27/01/25.
//

import UIKit

class DownloadImageCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    func setupCell(_ item: DownloadGIFModel) {
        imageView.image = item.image
    }
}
