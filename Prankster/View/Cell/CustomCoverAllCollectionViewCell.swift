//
//  CustomCoverAllCollectionViewCell.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 19/11/24.
//

import UIKit
import SDWebImage

protocol CustomCoverAllCollectionViewCellDelegate: AnyObject {
    func didTapDoneButton(with image: UIImage)
}

class CustomCoverAllCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var DoneButton: UIButton!
    weak var delegate: CustomCoverAllCollectionViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
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
        self.DoneButton.setImage(UIImage(named: "selectYesButton"), for: .normal)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    @objc private func doneButtonTapped() {
        if let image = imageView.image {
            delegate?.didTapDoneButton(with: image)
        }
    }
}

class CustomCoverSliderCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
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
    
    override var isSelected: Bool {
        didSet {
            layer.borderWidth = isSelected ? 3 : 0
            layer.borderColor = isSelected ? UIColor.white.cgColor : nil
        }
    }
}
