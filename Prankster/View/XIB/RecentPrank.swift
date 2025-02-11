//
//  NoDataView.swift
//  CustomeDataAPICalling
//
//  Created by Arpit iOS Dev. on 07/06/24.
//

import Foundation
import UIKit
import Lottie

class RecentPrank: UIView {
    
    @IBOutlet weak var lottieView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var makePrank: UIButton!
    @IBOutlet weak var imageHeightConsteraints: NSLayoutConstraint!
    
    var onRetry: (() -> Void)?
    
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
        let nib = UINib(nibName: "RecentPrank", bundle: bundle)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else { return }
        view.frame = self.bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
        
        self.makePrank.layer.cornerRadius = 13
        
        adjustConstraints()
    }
    
    private func adjustConstraints() {
        let screenHeight = UIScreen.main.nativeBounds.height
        if UIDevice.current.userInterfaceIdiom == .phone {
            switch screenHeight {
            case 1136, 1334, 1920, 2208:
                imageHeightConsteraints.constant = 350
            case 2436, 1792, 2556, 2532:
                imageHeightConsteraints.constant = 369
            case 2796, 2778, 2688:
                imageHeightConsteraints.constant = 369
            default:
                imageHeightConsteraints.constant = 235
            }
        } else {
            imageHeightConsteraints.constant = 400
        }
    }
}
