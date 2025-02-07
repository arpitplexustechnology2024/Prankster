//
//  SpinnerCollectionViewCell.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 30/11/24.
//

import UIKit
import SDWebImage

class SpinnerCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var shareButton: UIButton!
    
    var spinnerData: SpinnerData?
    var onPreviewTap: ((SpinnerData?) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.layer.cornerRadius = 10
        self.contentView.layer.cornerRadius = 10
        self.clipsToBounds = true
        
        self.imageView.layer.cornerRadius = 6
        self.imageView.clipsToBounds = true

        shareButton.addTarget(self, action: #selector(previewButtonTapped), for: .touchUpInside)
    }
    
    @objc private func previewButtonTapped() {
        onPreviewTap?(spinnerData)
    }
    
    func configure(with spinnerData: SpinnerData, previewAction: @escaping (SpinnerData?) -> Void) {
        self.spinnerData = spinnerData
        
        if let url = URL(string: spinnerData.coverImage) {
            imageView.sd_setImage(with: url)
        }
        self.onPreviewTap = previewAction
    }
}
