//
//  ShareView_02.swift
//  LOL
//
//  Created by Arpit iOS Dev. on 20/08/24.
//

import UIKit
import SDWebImage

class ShareView: UIView {
    
    @IBOutlet weak var shareBackground: UIImageView!
    @IBOutlet weak var cardview: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var pasteLinkImageView: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "ShareView", bundle: bundle)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else { return }
        
        view.frame = self.bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        addSubview(view)
        loadImage()
        cardview.layer.cornerRadius = 16
        cardview.layer.masksToBounds = true
        
        imageView.layer.cornerRadius = 16
        imageView.clipsToBounds = true
        
        if let name = UserDefaults.standard.string(forKey: "Name") {
            self.textLabel.text = name
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateProfileImage(notification:)), name: Notification.Name("PrankInfoUpdated"), object: nil)
    }
    
    private func loadImage() {
        if let CoverURL = UserDefaults.standard.string(forKey: "CoverImage") {
            imageView.sd_setImage(with: URL(string: CoverURL), placeholderImage: UIImage(named: "Pranksters"))
        }
    }
    
    @objc func updateProfileImage(notification: Notification) {
        if let image = notification.object as? UIImage {
            imageView.image = image
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name("PrankInfoUpdated"), object: nil)
    }
    
    func configure(with imageURL: URL) {
        shareBackground.sd_setImage(with: imageURL, placeholderImage: UIImage(named: "PranksterBlur")) { [weak self] (image, error, cacheType, url) in
            guard let self = self else { return }
            
            if let loadedImage = image {
                self.createBlurredBackground(from: loadedImage)
            } else {
                if let placeholderImage = UIImage(named: "PranksterBlur") {
                    self.createBlurredBackground(from: placeholderImage)
                }
            }
        }
    }
    
    private func createBlurredBackground(from image: UIImage) {
        let context = CIContext(options: nil)
        guard let ciImage = CIImage(image: image),
              let blurFilter = CIFilter(name: "CIGaussianBlur") else { return }
        
        blurFilter.setValue(ciImage, forKey: kCIInputImageKey)
        blurFilter.setValue(15.0, forKey: kCIInputRadiusKey)
        
        guard let blurredImage = blurFilter.outputImage,
              let cgImage = context.createCGImage(blurredImage, from: blurredImage.extent) else { return }
        
        shareBackground.image = UIImage(cgImage: cgImage)
        shareBackground.contentMode = .scaleAspectFill
    }
    
    
}
