//
//  NoInternetView.swift
//  CustomeDataAPICalling
//
//  Created by Arpit iOS Dev. on 07/06/24.
//

import Foundation
import UIKit
import Lottie

class NoInternetLightView: UIView {
    
    @IBOutlet weak var lottieView: LottieAnimationView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var retryButton: UIButton!
    @IBOutlet weak var lottieViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var lottieViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var labelTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var retryButtonTopConstraint: NSLayoutConstraint!
    
    var onRetry: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    func commonInit() {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "NoInternetLightView", bundle: bundle)
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
        lottieView.animation = LottieAnimation.named("NoInternet")
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
                retryButtonTopConstraint.constant = 30
            case 2436, 1792, 2556, 2532:
                lottieViewHeightConstraint.constant = 287
                labelTopConstraint.constant = 50
                lottieViewTopConstraint.constant = 70
                retryButtonTopConstraint.constant = 60
            case 2796, 2778, 2688:
                lottieViewHeightConstraint.constant = 287
                labelTopConstraint.constant = 50
                lottieViewTopConstraint.constant = 70
                retryButtonTopConstraint.constant = 60
            default:
                lottieViewHeightConstraint.constant = 235
                labelTopConstraint.constant = 30
                lottieViewTopConstraint.constant = 50
                retryButtonTopConstraint.constant = 30
            }
        } else {
            lottieViewHeightConstraint.constant = 500
            labelTopConstraint.constant = 50
            lottieViewTopConstraint.constant = 150
        }
    }
}
