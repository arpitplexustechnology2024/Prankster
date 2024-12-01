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
    @IBOutlet weak var imageName: UILabel!
    @IBOutlet weak var previewButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    
    // Add a property to store the current spinner data
    var spinnerData: SpinnerData?
    
    // Create a closure to handle preview button tap
    var onPreviewTap: ((SpinnerData?) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.layer.cornerRadius = 10
        self.clipsToBounds = true
        
        self.imageView.layer.cornerRadius = 6
        self.imageView.clipsToBounds = true
        
        self.shareButton.layer.cornerRadius = shareButton.layer.frame.height / 2
        self.shareButton.clipsToBounds = true
        
        self.previewButton.layer.cornerRadius = 6
        self.previewButton.clipsToBounds = true
        
        // Add target for preview button
        previewButton.addTarget(self, action: #selector(previewButtonTapped), for: .touchUpInside)
    }
    
    @objc private func previewButtonTapped() {
        // Call the closure and pass the spinner data
        onPreviewTap?(spinnerData)
    }
    
    // Configure the cell with spinner data
    func configure(with spinnerData: SpinnerData, previewAction: @escaping (SpinnerData?) -> Void) {
        self.spinnerData = spinnerData
        
        if let url = URL(string: spinnerData.coverImage) {
            imageView.sd_setImage(with: url)
        }
        
        imageName.text = spinnerData.name
        
        // Set the preview tap handler
        self.onPreviewTap = previewAction
    }
}
