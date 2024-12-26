//
//  NoDataView.swift
//  CustomeDataAPICalling
//
//  Created by Arpit iOS Dev. on 07/06/24.
//

import Foundation
import UIKit
import Lottie

class NoDataView: UIView {
    
    @IBOutlet weak var lottieView: LottieAnimationView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var lottieViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var labelTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var lottieViewHeightConstraint: NSLayoutConstraint!
    
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
        let nib = UINib(nibName: "NoDataView", bundle: bundle)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else { return }
        view.frame = self.bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
        
        adjustConstraints()
        setupLottieLoader()
    }
    
    private func setupLottieLoader() {
        lottieView.loopMode = .loop
        lottieView.contentMode = .scaleAspectFit
        lottieView.animation = LottieAnimation.named("Nodata")
        lottieView.play()
    }
    
    private func adjustConstraints() {
        let screenHeight = UIScreen.main.nativeBounds.height
        if UIDevice.current.userInterfaceIdiom == .phone {
            switch screenHeight {
            case 1136, 1334, 1920, 2208:
                lottieViewHeightConstraint.constant = 225
                labelTopConstraint.constant = 30
                lottieViewTopConstraint.constant = 50
            case 2436, 1792, 2556, 2532:
                lottieViewHeightConstraint.constant = 287
                labelTopConstraint.constant = 50
                lottieViewTopConstraint.constant = 70
            case 2796, 2778, 2688:
                lottieViewHeightConstraint.constant = 287
                labelTopConstraint.constant = 50
                lottieViewTopConstraint.constant = 70
            default:
                lottieViewHeightConstraint.constant = 235
                labelTopConstraint.constant = 30
                lottieViewTopConstraint.constant = 50
            }
        } else {
            lottieViewHeightConstraint.constant = 400
            labelTopConstraint.constant = 50
            lottieViewTopConstraint.constant = 200
        }
    }
}
