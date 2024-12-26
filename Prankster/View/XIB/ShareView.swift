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
    
    private var imageLoadCompletion: ((Bool) -> Void)?
    
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
        cardview.layer.cornerRadius = 16
        cardview.layer.masksToBounds = true
        
        imageView.layer.cornerRadius = 16
        imageView.clipsToBounds = true
    }
    
    func configureShareView(imageURL: URL, name: String, completion: @escaping (Bool) -> Void) {
        imageLoadCompletion = completion
        textLabel.text = name
        
        let group = DispatchGroup()
        var foregroundImageLoaded = false
        var backgroundImageLoaded = false
        
        group.enter()
        imageView.sd_setImage(with: imageURL, placeholderImage: UIImage(named: "Pranksters")) { [weak self] image, error, _, _ in
            foregroundImageLoaded = image != nil
            group.leave()
        }
        
        group.enter()
        shareBackground.sd_setImage(with: imageURL, placeholderImage: UIImage(named: "PranksterBlur")) { [weak self] image, error, _, _ in
            if let image = image {
                guard let ciImage = CIImage(image: image) else {
                    backgroundImageLoaded = false
                    group.leave()
                    return
                }
                
                let filter = CIFilter(name: "CIGaussianBlur")
                filter?.setValue(ciImage, forKey: kCIInputImageKey)
                filter?.setValue(15.0, forKey: kCIInputRadiusKey)
                
                guard let outputImage = filter?.outputImage else {
                    backgroundImageLoaded = false
                    group.leave()
                    return
                }
                
                let context = CIContext()
                if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                    let blurredImage = UIImage(cgImage: cgImage)
                    DispatchQueue.main.async {
                        self?.shareBackground.image = blurredImage
                        backgroundImageLoaded = true
                        group.leave()
                    }
                } else {
                    backgroundImageLoaded = false
                    group.leave()
                }
            } else {
                backgroundImageLoaded = false
                group.leave()
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            let success = foregroundImageLoaded && backgroundImageLoaded
            self?.imageLoadCompletion?(success)
        }
    }
}
